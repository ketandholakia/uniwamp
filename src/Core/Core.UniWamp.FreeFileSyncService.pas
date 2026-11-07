unit Core.UniWamp.FreeFileSyncService;

{
  FreeFileSync-backed implementation of ISyncService.

  Generates an .ffs_gui file from a connection profile + sync profile so the
  user can open it in the FreeFileSync GUI for visual review and manual sync.
}

interface

uses
  System.SysUtils,
  Core.UniWamp.Config,
  Core.UniWamp.Interfaces,
  Core.UniWamp.Paths,
  Core.UniWamp.Types,
  Core.UniWamp.SyncTypes,
  Core.UniWamp.FreeFileSyncBatchWriter;

type
  TFreeFileSyncService = class(TInterfacedObject, ISyncService)
  private
    FPaths: TAppPaths;
    FConfig: TUniWampConfig;
    function TryGetConnectionProfile(const ProfileName: string; out Profile: TConnectionProfile): Boolean;
    function TryGetProfile(const ProfileName: string; out Profile: TSyncProfile): Boolean;
    function TryGetVHostEntry(const ServerName: string; out Entry: TVHostEntry): Boolean;
    function ResolvePortablePath(const PathValue: string): string;
    function ApplyVHostTokens(const Value: string; const Entry: TVHostEntry): string;
    function BuildCredentials(const Profile: TSyncProfile): TSyncCredentials;
    function ResolveLocalPath(const Profile: TSyncProfile; const Entry: TVHostEntry;
      out LocalPath: string; out ErrorMessage: string): Boolean;
    function ResolveFreeFileSyncExe(out ErrorMessage: string): string;
    function BuildJobSpec(const Profile: TSyncProfile; const Entry: TVHostEntry): TFreeFileSyncJobSpec;
  public
    constructor Create(const Paths: TAppPaths; Config: TUniWampConfig);
    function BuildCommandPreview(const ProfileName: string; UseDryRun: Boolean;
      out CommandLine: string): TRuntimeActionResult;
    function BuildCommandPreviewForVHost(const ProfileName, ServerName: string; UseDryRun: Boolean;
      out CommandLine: string): TRuntimeActionResult;
    function ExecuteProfileForVHost(const ProfileName, ServerName: string; UseDryRun: Boolean): TRuntimeActionResult;
    function ExecuteVHostSync(const ServerName, DirectionName: string; UseDryRun: Boolean): TRuntimeActionResult;
  end;

implementation

uses
  Winapi.Windows,
  Winapi.ShellAPI,
  System.Classes,
  System.IOUtils,
  Core.UniWamp.Secrets,
  Core.UniWamp.ProcessManager;

{ TFreeFileSyncService }

constructor TFreeFileSyncService.Create(const Paths: TAppPaths; Config: TUniWampConfig);
begin
  inherited Create;
  FPaths := Paths;
  FConfig := Config;
end;

function TFreeFileSyncService.TryGetProfile(const ProfileName: string; out Profile: TSyncProfile): Boolean;
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

function TFreeFileSyncService.TryGetConnectionProfile(const ProfileName: string;
  out Profile: TConnectionProfile): Boolean;
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

function TFreeFileSyncService.TryGetVHostEntry(const ServerName: string; out Entry: TVHostEntry): Boolean;
var
  Item: TVHostEntry;
begin
  Result := False;
  Entry := Default(TVHostEntry);
  for Item in FConfig.VHosts do
    if SameText(Item.ServerName, ServerName) then
    begin
      Entry := Item;
      Exit(True);
    end;
end;

function TFreeFileSyncService.ResolvePortablePath(const PathValue: string): string;
begin
  Result := Trim(StringReplace(PathValue, '/', '\', [rfReplaceAll]));
  if (Result <> '') and not TPath.IsPathRooted(Result) then
    Result := ExpandFileName(TPath.Combine(FPaths.AppRoot, Result));
end;

function TFreeFileSyncService.ApplyVHostTokens(const Value: string; const Entry: TVHostEntry): string;
var
  ProjectRoot: string;
begin
  Result := Value;
  ProjectRoot := ExcludeTrailingPathDelimiter(Entry.DocumentRoot);
  if SameText(ExtractFileName(ProjectRoot), 'public') then
    ProjectRoot := ExtractFileDir(ProjectRoot);
  Result := StringReplace(Result, '{serverName}',   Entry.ServerName,   [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, '{documentRoot}', Entry.DocumentRoot, [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, '{projectRoot}',  ProjectRoot,        [rfReplaceAll, rfIgnoreCase]);
end;

function TFreeFileSyncService.BuildCredentials(const Profile: TSyncProfile): TSyncCredentials;
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
    Result.SshHostKeyFingerprint := ConnectionProfile.SshHostKeyFingerprint;
    Result.TlsCertificateFingerprint := ConnectionProfile.TlsCertificateFingerprint;
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
    Result.SshHostKeyFingerprint := ConnectionProfile.SshHostKeyFingerprint;
    Result.TlsCertificateFingerprint := ConnectionProfile.TlsCertificateFingerprint;
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
    Result.SshHostKeyFingerprint := Profile.SshHostKeyFingerprint;
    Result.TlsCertificateFingerprint := Profile.TlsCertificateFingerprint;
    Result.PassiveMode := Profile.PassiveMode;
    Result.IgnoreCertErrors := Profile.IgnoreCertErrors;
  end;
  // FreeFileSync manages its own credential storage; passwords are not
  // written into the .ffs_gui XML to avoid plaintext on disk.
  Result.Password := '';
  Result.KeyPassphrase := '';
end;

function TFreeFileSyncService.ResolveLocalPath(const Profile: TSyncProfile;
  const Entry: TVHostEntry; out LocalPath: string; out ErrorMessage: string): Boolean;
var
  LocalPathValue: string;
begin
  Result := False;
  ErrorMessage := '';
  LocalPathValue := Profile.LocalPath;
  if Entry.ServerName <> '' then
    LocalPathValue := ApplyVHostTokens(LocalPathValue, Entry);
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
  Result := True;
end;

function TFreeFileSyncService.ResolveFreeFileSyncExe(out ErrorMessage: string): string;
begin
  Result := TFreeFileSyncBatchWriter.ResolveFreeFileSyncExe(FPaths.FreeFileSyncDir);
  if Result = '' then
    ErrorMessage := 'FreeFileSync was not found. Install FreeFileSync and place ' +
      'FreeFileSync.exe in runtime\tools\freefilesync\, or ensure it is installed ' +
      'in ''C:\Program Files\FreeFileSync\''.';
end;

function TFreeFileSyncService.BuildJobSpec(const Profile: TSyncProfile;
  const Entry: TVHostEntry): TFreeFileSyncJobSpec;
var
  RemotePath: string;
begin
  Result.Credentials := BuildCredentials(Profile);
  if Trim(Profile.ConnectionProfileName) <> '' then
  begin
    Result.Password := LoadConnectionPassword(FPaths, Profile.ConnectionProfileName);
    Result.Credentials.KeyPassphrase := LoadConnectionKeyPassphrase(FPaths, Profile.ConnectionProfileName);
  end
  else
  begin
    Result.Password := LoadConnectionPassword(FPaths, Profile.Name);
    Result.Credentials.KeyPassphrase := LoadConnectionKeyPassphrase(FPaths, Profile.Name);
  end;
  RemotePath := Profile.RemotePath;
  if Entry.ServerName <> '' then
    RemotePath := ApplyVHostTokens(RemotePath, Entry);
  Result.RemotePath := Trim(RemotePath);
  Result.LocalPath := '';  // filled by caller after ResolveLocalPath
  Result.Direction := Profile.Direction;
  Result.SyncVariant := Profile.SyncVariant;
  Result.DeleteEnabled := Profile.DeleteEnabled;
  Result.Excludes := Profile.Excludes;
  Result.LogFilePath := '';
end;

{ ISyncService implementation }

function TFreeFileSyncService.BuildCommandPreview(const ProfileName: string; UseDryRun: Boolean;
  out CommandLine: string): TRuntimeActionResult;
begin
  Result := BuildCommandPreviewForVHost(ProfileName, '', UseDryRun, CommandLine);
end;

function TFreeFileSyncService.BuildCommandPreviewForVHost(const ProfileName, ServerName: string;
  UseDryRun: Boolean; out CommandLine: string): TRuntimeActionResult;
var
  Profile: TSyncProfile;
  Entry: TVHostEntry;
  FreeFileSyncExe: string;
  FfeErrorMessage: string;
  LocalPath: string;
  PathErrorMessage: string;
  GuiFilePath: string;
  Spec: TFreeFileSyncJobSpec;
begin
  CommandLine := '';
  if not TryGetProfile(ProfileName, Profile) then
  begin
    Result.Success := False;
    Result.Message := 'Sync profile not found: ' + ProfileName;
    Exit;
  end;
  Entry := Default(TVHostEntry);
  if (ServerName <> '') and not TryGetVHostEntry(ServerName, Entry) then
  begin
    Result.Success := False;
    Result.Message := 'Project not found: ' + ServerName;
    Exit;
  end;

  FreeFileSyncExe := ResolveFreeFileSyncExe(FfeErrorMessage);
  if FreeFileSyncExe = '' then
  begin
    Result.Success := False;
    Result.Message := FfeErrorMessage;
    Exit;
  end;

  if not ResolveLocalPath(Profile, Entry, LocalPath, PathErrorMessage) then
  begin
    Result.Success := False;
    Result.Message := PathErrorMessage;
    Exit;
  end;

  // Generate an .ffs_gui file so the user can open it in FreeFileSync GUI
  // and visually review the comparison before syncing.
  GuiFilePath := TPath.Combine(FPaths.TmpDir,
    TPath.Combine('ffs', LowerCase(Trim(Profile.Name)) + '.ffs_gui'));

  Spec := BuildJobSpec(Profile, Entry);
  Spec.LocalPath := LocalPath;

  try
    TFreeFileSyncBatchWriter.WriteGuiFile(Spec, GuiFilePath);
  except
    on E: Exception do
    begin
      Result.Success := False;
      Result.Message := 'Failed to write FreeFileSync GUI file: ' + E.Message;
      Exit;
    end;
  end;

  CommandLine := '"' + FreeFileSyncExe + '" "' + GuiFilePath + '"';
  Result.Success := True;
  Result.Message := 'FreeFileSync preview file generated. Open it in FreeFileSync to compare.';
end;

function TFreeFileSyncService.ExecuteProfileForVHost(const ProfileName, ServerName: string; UseDryRun: Boolean): TRuntimeActionResult;
var
  Profile: TSyncProfile;
  Entry: TVHostEntry;
  FreeFileSyncExe: string;
  FfeErrorMessage: string;
  LocalPath: string;
  PathErrorMessage: string;
  BatchFilePath: string;
  Spec: TFreeFileSyncJobSpec;
  LogFilePath: string;
begin
  if not TryGetProfile(ProfileName, Profile) then
  begin
    Result.Success := False;
    Result.Message := 'Sync profile not found: ' + ProfileName;
    Exit;
  end;
  Entry := Default(TVHostEntry);
  if (ServerName <> '') and not TryGetVHostEntry(ServerName, Entry) then
  begin
    Result.Success := False;
    Result.Message := 'Project not found: ' + ServerName;
    Exit;
  end;

  FreeFileSyncExe := ResolveFreeFileSyncExe(FfeErrorMessage);
  if FreeFileSyncExe = '' then
  begin
    Result.Success := False;
    Result.Message := FfeErrorMessage;
    Exit;
  end;

  if not ResolveLocalPath(Profile, Entry, LocalPath, PathErrorMessage) then
  begin
    Result.Success := False;
    Result.Message := PathErrorMessage;
    Exit;
  end;

  // Generate an .ffs_batch file for unattended execution
  BatchFilePath := TPath.Combine(FPaths.TmpDir,
    TPath.Combine('ffs', LowerCase(Trim(Profile.Name)) + '.ffs_batch'));
  LogFilePath := TPath.Combine(FPaths.LogsDir, 'sync-' + LowerCase(Trim(Profile.Name)) + '.log');

  Spec := BuildJobSpec(Profile, Entry);
  Spec.LocalPath := LocalPath;
  Spec.LogFilePath := LogFilePath;

  try
    TFreeFileSyncBatchWriter.WriteBatchFile(Spec, BatchFilePath);
  except
    on E: Exception do
    begin
      Result.Success := False;
      Result.Message := 'Failed to write FreeFileSync batch file: ' + E.Message;
      Exit;
    end;
  end;

  // Execute FreeFileSync in batch mode and wait for its actual result.
  // This prevents the UI from reporting success while the remote transfer is
  // still running or has already failed.
  var Output: string;
  Result.Success := TProcessManager.RunAndCaptureOutput(
    FreeFileSyncExe,
    '"' + BatchFilePath + '"',
    ExtractFileDir(BatchFilePath),
    Output,
    0);

  if Result.Success then
  begin
    Result.Message := 'Sync completed. Log: ' + LogFilePath;
  end
  else
  begin
    Result.Message := 'FreeFileSync reported a synchronization failure. Log: ' + LogFilePath;
  end;
end;

function TFreeFileSyncService.ExecuteVHostSync(const ServerName, DirectionName: string;
  UseDryRun: Boolean): TRuntimeActionResult;
var
  Entry: TVHostEntry;
  Profile: TSyncProfile;
  TemporaryName: string;
begin
  if not TryGetVHostEntry(ServerName, Entry) then
  begin
    Result.Success := False;
    Result.Message := 'Project not found: ' + ServerName;
    Exit;
  end;
  if Trim(Entry.SyncHost) = '' then
  begin
    Result.Success := False;
    Result.Message := 'Sync is not configured for vHost: ' + ServerName;
    Exit;
  end;
  if not SameText(DirectionName, 'upload') and not SameText(DirectionName, 'download') then
  begin
    Result.Success := False;
    Result.Message := 'Unsupported sync direction: ' + DirectionName;
    Exit;
  end;

  Profile := Default(TSyncProfile);
  TemporaryName := '__vhost_sync_' + LowerCase(ServerName);
  Profile.Name := TemporaryName;
  Profile.Protocol := Entry.SyncProtocol;
  Profile.Direction := LowerCase(DirectionName);
  Profile.Host := Entry.SyncHost;
  Profile.Port := Entry.SyncPort;
  Profile.Username := Entry.SyncUsername;
  Profile.PrivateKeyFile := Entry.SyncPrivateKeyFile;
  Profile.RemotePath := Entry.SyncRemotePath;
  Profile.LocalPath := Entry.DocumentRoot;
  Profile.DeleteEnabled := Entry.SyncDeleteEnabled;
  Profile.SyncTool := 'freefilesync';
  Profile.SyncVariant := Entry.SyncVariant;
  Profile.DryRunByDefault := UseDryRun;
  Profile.Excludes := Entry.SyncExcludes;
  FConfig.AddOrUpdateSyncProfile(Profile);
  try
    Result := ExecuteProfileForVHost(TemporaryName, ServerName, UseDryRun);
  finally
    FConfig.DeleteSyncProfile(TemporaryName);
  end;
end;

end.
