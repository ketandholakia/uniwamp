unit Core.UniWamp.SyncService;

interface

uses
  System.SysUtils,
  Core.UniWamp.Config,
  Core.UniWamp.Interfaces,
  Core.UniWamp.Paths,
  Core.UniWamp.Types,
  Core.UniWamp.SyncTransport,
  Core.UniWamp.SyncEngine;

type
  TSyncService = class(TInterfacedObject, ISyncService)
  private
    FPaths: TAppPaths;
    FConfig: TUniWampConfig;
    function TryGetConnectionProfile(const ProfileName: string; out Profile: TConnectionProfile): Boolean;
    function TryGetProfile(const ProfileName: string; out Profile: TSyncProfile): Boolean;
    function TryGetVHostEntry(const ServerName: string; out Entry: TVHostEntry): Boolean;
    function ResolvePortablePath(const PathValue: string): string;
    function ApplyVHostTokens(const Value: string; const Entry: TVHostEntry): string;
    function BuildCredentials(const Profile: TSyncProfile): TSyncCredentials;
    function ResolveLocalAndWorkingDir(const Profile: TSyncProfile; const Entry: TVHostEntry;
      out LocalPath, WorkingDirectory: string; out ErrorMessage: string): Boolean;
    function ExecuteHookCommand(const CommandText, WorkingDirectory: string; out Output: string): Boolean;
    function DescribePlan(const Plan: TSyncPlan): string;
    function RunSync(const Profile: TSyncProfile; const Entry: TVHostEntry; UseDryRun: Boolean;
      out Summary: string): TRuntimeActionResult;
  public
    constructor Create(const Paths: TAppPaths; Config: TUniWampConfig);
    function BuildCommandPreview(const ProfileName: string; UseDryRun: Boolean;
      out CommandLine: string): TRuntimeActionResult;
    function ExecuteProfile(const ProfileName: string; UseDryRun: Boolean): TRuntimeActionResult;
    function BuildCommandPreviewForVHost(const ProfileName, ServerName: string; UseDryRun: Boolean;
      out CommandLine: string): TRuntimeActionResult;
    function ExecuteProfileForVHost(const ProfileName, ServerName: string; UseDryRun: Boolean): TRuntimeActionResult;
  end;

implementation

uses
  System.Classes,
  System.IOUtils,
  Core.UniWamp.ProcessManager,
  Core.UniWamp.Secrets;

constructor TSyncService.Create(const Paths: TAppPaths; Config: TUniWampConfig);
begin
  inherited Create;
  FPaths := Paths;
  FConfig := Config;
end;

function TSyncService.TryGetProfile(const ProfileName: string; out Profile: TSyncProfile): Boolean;
var
  Item: TSyncProfile;
begin
  Result := False;
  Profile := Default(TSyncProfile);
  for Item in FConfig.SyncProfiles do
    if SameText(Item.Name, ProfileName) then
    begin
      Profile := Item;
      Exit(True);
    end;
end;

function TSyncService.TryGetConnectionProfile(const ProfileName: string; out Profile: TConnectionProfile): Boolean;
var
  Item: TConnectionProfile;
begin
  Result := False;
  Profile := Default(TConnectionProfile);
  for Item in FConfig.ConnectionProfiles do
    if SameText(Item.Name, ProfileName) then
    begin
      Profile := Item;
      Exit(True);
    end;
end;

function TSyncService.TryGetVHostEntry(const ServerName: string; out Entry: TVHostEntry): Boolean;
var
  Item: TVHostEntry;
begin
  Result := False;
  Entry.ServerName := '';
  Entry.ServerAliases := '';
  Entry.DocumentRoot := '';
  Entry.EnableSsl := False;
  Entry.SslCertFile := '';
  Entry.SslKeyFile := '';
  Entry.PinnedSyncUploadProfile := '';
  Entry.PinnedSyncDownloadProfile := '';
  for Item in FConfig.VHosts do
    if SameText(Item.ServerName, ServerName) then
    begin
      Entry := Item;
      Exit(True);
    end;
end;

function TSyncService.ResolvePortablePath(const PathValue: string): string;
begin
  Result := Trim(StringReplace(PathValue, '/', '\', [rfReplaceAll]));
  if (Result <> '') and not TPath.IsPathRooted(Result) then
    Result := ExpandFileName(TPath.Combine(FPaths.AppRoot, Result));
end;

function TSyncService.ApplyVHostTokens(const Value: string; const Entry: TVHostEntry): string;
var
  ProjectRoot: string;
begin
  Result := Value;
  ProjectRoot := ExcludeTrailingPathDelimiter(Entry.DocumentRoot);
  if SameText(ExtractFileName(ProjectRoot), 'public') then
    ProjectRoot := ExtractFileDir(ProjectRoot);
  Result := StringReplace(Result, '{serverName}', Entry.ServerName, [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, '{documentRoot}', Entry.DocumentRoot, [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, '{projectRoot}', ProjectRoot, [rfReplaceAll, rfIgnoreCase]);
end;

function TSyncService.BuildCredentials(const Profile: TSyncProfile): TSyncCredentials;
var
  ConnectionProfile: TConnectionProfile;
begin
  if (Trim(Profile.ConnectionProfileName) <> '') and
    TryGetConnectionProfile(Profile.ConnectionProfileName, ConnectionProfile) then
  begin
    Result.Protocol := ConnectionProfile.Protocol;
    Result.Host := ConnectionProfile.Host;
    Result.Port := ConnectionProfile.Port;
    Result.Username := ConnectionProfile.Username;
    Result.PrivateKeyFile := ResolvePortablePath(ConnectionProfile.PrivateKeyFile);
    Result.PassiveMode := ConnectionProfile.PassiveMode;
    Result.IgnoreCertErrors := ConnectionProfile.IgnoreCertErrors;
  end
  else if TryGetConnectionProfile(Profile.Name, ConnectionProfile) then
  begin
    Result.Protocol := ConnectionProfile.Protocol;
    Result.Host := ConnectionProfile.Host;
    Result.Port := ConnectionProfile.Port;
    Result.Username := ConnectionProfile.Username;
    Result.PrivateKeyFile := ResolvePortablePath(ConnectionProfile.PrivateKeyFile);
    Result.PassiveMode := ConnectionProfile.PassiveMode;
    Result.IgnoreCertErrors := ConnectionProfile.IgnoreCertErrors;
  end
  else
  begin
    Result.Protocol := Profile.Protocol;
    Result.Host := Profile.Host;
    Result.Port := Profile.Port;
    Result.Username := Profile.Username;
    Result.PrivateKeyFile := ResolvePortablePath(Profile.PrivateKeyFile);
    Result.PassiveMode := Profile.PassiveMode;
    Result.IgnoreCertErrors := Profile.IgnoreCertErrors;
  end;
  Result.Password := LoadSecret(FPaths, SyncPasswordKey(Profile.Name));
  Result.KeyPassphrase := LoadSecret(FPaths, SyncKeyPassphraseKey(Profile.Name));
end;

function TSyncService.ResolveLocalAndWorkingDir(const Profile: TSyncProfile; const Entry: TVHostEntry;
  out LocalPath, WorkingDirectory: string; out ErrorMessage: string): Boolean;
var
  LocalPathValue, WorkingDirectoryValue: string;
begin
  Result := False;
  ErrorMessage := '';
  LocalPathValue := Profile.LocalPath;
  WorkingDirectoryValue := Profile.WorkingDirectory;
  if Entry.ServerName <> '' then
  begin
    LocalPathValue := ApplyVHostTokens(LocalPathValue, Entry);
    WorkingDirectoryValue := ApplyVHostTokens(WorkingDirectoryValue, Entry);
  end;

  LocalPath := ResolvePortablePath(LocalPathValue);
  if LocalPath = '' then
  begin
    ErrorMessage := 'Sync profile localPath is invalid.';
    Exit;
  end;

  if SameText(Profile.Direction, 'upload') then
  begin
    if not TDirectory.Exists(LocalPath) then
    begin
      ErrorMessage := 'Local sync source not found: ' + LocalPath;
      Exit;
    end;
  end
  else if SameText(Profile.Direction, 'download') then
  begin
    if not TDirectory.Exists(LocalPath) then
      TDirectory.CreateDirectory(LocalPath);
  end
  else
  begin
    ErrorMessage := 'Unsupported sync direction: ' + Profile.Direction;
    Exit;
  end;

  WorkingDirectory := ResolvePortablePath(WorkingDirectoryValue);
  if WorkingDirectory = '' then
    WorkingDirectory := FPaths.AppRoot;

  Result := True;
end;

function TSyncService.ExecuteHookCommand(const CommandText, WorkingDirectory: string;
  out Output: string): Boolean;
var
  ShellExe: string;
begin
  ShellExe := GetEnvironmentVariable('ComSpec');
  if Trim(ShellExe) = '' then
    ShellExe := 'cmd.exe';
  Result := TProcessManager.RunAndCaptureOutput(
    ShellExe,
    '/c ' + CommandText,
    WorkingDirectory,
    Output,
    0);
end;

function TSyncService.DescribePlan(const Plan: TSyncPlan): string;
var
  Uploads, Downloads, Deletes, Dirs: Integer;
  Item: TSyncPlanItem;
begin
  Uploads := 0; Downloads := 0; Deletes := 0; Dirs := 0;
  for Item in Plan do
    case Item.Kind of
      spiUpload: Inc(Uploads);
      spiDownload: Inc(Downloads);
      spiDeleteRemote, spiDeleteLocal: Inc(Deletes);
      spiCreateRemoteDir: Inc(Dirs);
    end;
  if Length(Plan) = 0 then
    Exit('Nothing to sync - remote and local are already in sync.');
  Result := Format('%d file(s) to upload, %d to download, %d to delete, %d remote director(y/ies) to create.',
    [Uploads, Downloads, Deletes, Dirs]);
end;

function TSyncService.RunSync(const Profile: TSyncProfile; const Entry: TVHostEntry; UseDryRun: Boolean;
  out Summary: string): TRuntimeActionResult;
var
  LocalPath, WorkingDirectory, ErrorMessage, RemotePath: string;
  Transport: ISyncTransport;
  Plan: TSyncPlan;
  ExecResult: TSyncExecutionResult;
begin
  Result.Success := False;
  Result.Message := '';
  Summary := '';

  if not ((Profile.Protocol = 'ftp') or (Profile.Protocol = 'ftps') or (Profile.Protocol = 'sftp')) then
  begin
    Result.Message := 'Unsupported sync protocol: ' + Profile.Protocol;
    Exit;
  end;
  if Trim(Profile.Host) = '' then
  begin
    Result.Message := 'Sync profile host is required.';
    Exit;
  end;
  if Trim(Profile.RemotePath) = '' then
  begin
    Result.Message := 'Sync profile remotePath is required.';
    Exit;
  end;

  if not ResolveLocalAndWorkingDir(Profile, Entry, LocalPath, WorkingDirectory, ErrorMessage) then
  begin
    Result.Message := ErrorMessage;
    Exit;
  end;

  RemotePath := Profile.RemotePath;
  if Entry.ServerName <> '' then
    RemotePath := ApplyVHostTokens(RemotePath, Entry);

  try
    Transport := CreateSyncTransport(BuildCredentials(Profile));
    Transport.Connect;
    try
      Plan := TSyncEngine.BuildPlan(Transport, LocalPath, RemotePath, Profile.Direction,
        Profile.Excludes, Profile.DeleteEnabled);
      Summary := DescribePlan(Plan);
      if UseDryRun then
      begin
        Result.Success := True;
        Result.Message := Summary;
        Exit;
      end;
      ExecResult := TSyncEngine.ExecutePlan(Transport, Plan, False, nil, nil);
      Result.Success := ExecResult.Success;
      Result.Message := ExecResult.Message;
    finally
      Transport.Disconnect;
    end;
  except
    on E: ESyncTransportError do
      Result.Message := E.Message;
    on E: Exception do
      Result.Message := 'Sync failed: ' + E.Message;
  end;
end;

function TSyncService.BuildCommandPreview(const ProfileName: string; UseDryRun: Boolean;
  out CommandLine: string): TRuntimeActionResult;
begin
  Result := BuildCommandPreviewForVHost(ProfileName, '', UseDryRun, CommandLine);
end;

function TSyncService.ExecuteProfile(const ProfileName: string; UseDryRun: Boolean): TRuntimeActionResult;
begin
  Result := ExecuteProfileForVHost(ProfileName, '', UseDryRun);
end;

function TSyncService.BuildCommandPreviewForVHost(const ProfileName, ServerName: string;
  UseDryRun: Boolean; out CommandLine: string): TRuntimeActionResult;
var
  Profile: TSyncProfile;
  Entry: TVHostEntry;
begin
  CommandLine := '';
  if not TryGetProfile(ProfileName, Profile) then
  begin
    Result.Success := False;
    Result.Message := 'Sync profile not found: ' + ProfileName;
    Exit;
  end;
  Entry.ServerName := '';
  if (ServerName <> '') and not TryGetVHostEntry(ServerName, Entry) then
  begin
    Result.Success := False;
    Result.Message := 'Project not found: ' + ServerName;
    Exit;
  end;

  // Always build the plan in dry-run mode for a preview, regardless of the
  // profile's own DryRunByDefault - previewing must never touch the remote.
  Result := RunSync(Profile, Entry, True, CommandLine);
  if Result.Success then
    Result.Message := 'Sync preview generated.';
end;

function TSyncService.ExecuteProfileForVHost(const ProfileName, ServerName: string;
  UseDryRun: Boolean): TRuntimeActionResult;
var
  Profile: TSyncProfile;
  Entry: TVHostEntry;
  Summary: string;
  HookOutput: string;
  PreCommand, PostCommand, WorkingDirectory, ErrorMessage, LocalPath: string;
begin
  if not TryGetProfile(ProfileName, Profile) then
  begin
    Result.Success := False;
    Result.Message := 'Sync profile not found: ' + ProfileName;
    Exit;
  end;
  Entry.ServerName := '';
  if (ServerName <> '') and not TryGetVHostEntry(ServerName, Entry) then
  begin
    Result.Success := False;
    Result.Message := 'Project not found: ' + ServerName;
    Exit;
  end;

  if not UseDryRun and (Entry.ServerName <> '') then
  begin
    if not ResolveLocalAndWorkingDir(Profile, Entry, LocalPath, WorkingDirectory, ErrorMessage) then
    begin
      Result.Success := False;
      Result.Message := ErrorMessage;
      Exit;
    end;
    PreCommand := ApplyVHostTokens(Profile.PreSyncCommand, Entry);
    if Trim(PreCommand) <> '' then
      if not ExecuteHookCommand(PreCommand, WorkingDirectory, HookOutput) then
      begin
        Result.Success := False;
        if Trim(HookOutput) <> '' then
          Result.Message := 'Pre-sync command failed: ' + Trim(HookOutput)
        else
          Result.Message := 'Pre-sync command failed.';
        Exit;
      end;
  end;

  Result := RunSync(Profile, Entry, UseDryRun, Summary);
  if not Result.Success then
    Exit;
  if UseDryRun then
    Exit;

  if Entry.ServerName <> '' then
  begin
    PostCommand := ApplyVHostTokens(Profile.PostSyncCommand, Entry);
    if Trim(PostCommand) <> '' then
      if not ExecuteHookCommand(PostCommand, WorkingDirectory, HookOutput) then
      begin
        Result.Success := False;
        if Trim(HookOutput) <> '' then
          Result.Message := 'Post-sync command failed: ' + Trim(HookOutput)
        else
          Result.Message := 'Post-sync command failed.';
        Exit;
      end;
  end;
end;

end.
