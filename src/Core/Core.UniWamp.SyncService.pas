unit Core.UniWamp.SyncService;

interface

uses
  System.SysUtils,
  Core.UniWamp.Config,
  Core.UniWamp.Interfaces,
  Core.UniWamp.Paths,
  Core.UniWamp.Types;

type
  TSyncService = class(TInterfacedObject, ISyncService)
  private
    FPaths: TAppPaths;
    FConfig: TUniWampConfig;
    function TryGetProfile(const ProfileName: string; out Profile: TSyncProfile): Boolean;
    function TryGetVHostEntry(const ServerName: string; out Entry: TVHostEntry): Boolean;
    function ResolvePortablePath(const PathValue: string): string;
    function ApplyVHostTokens(const Value: string; const Entry: TVHostEntry): string;
    function ResolveExecutablePath(const Profile: TSyncProfile; out ExecutablePath: string): Boolean;
    function BuildRemoteSpec(const Profile: TSyncProfile): string;
    function BuildArguments(const Profile: TSyncProfile; UseDryRun: Boolean;
      out ExecutablePath, Arguments, WorkingDirectory: string): TRuntimeActionResult; overload;
    function BuildArguments(const Profile: TSyncProfile; const Entry: TVHostEntry; UseDryRun: Boolean;
      out ExecutablePath, Arguments, WorkingDirectory: string): TRuntimeActionResult; overload;
    function ExecuteHookCommand(const CommandText, WorkingDirectory: string; out Output: string): Boolean;
    function QuoteArgument(const Value: string): string;
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
  Core.UniWamp.ProcessManager;

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
  FillChar(Profile, SizeOf(Profile), 0);
  for Item in FConfig.SyncProfiles do
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

function TSyncService.ResolveExecutablePath(const Profile: TSyncProfile; out ExecutablePath: string): Boolean;
var
  SearchPathValue: string;
begin
  ExecutablePath := ResolvePortablePath(Profile.ExecutablePath);
  if ExecutablePath <> '' then
    Exit(FileExists(ExecutablePath));

  if SameText(Profile.Backend, 'rclone') then
  begin
    ExecutablePath := TPath.Combine(FPaths.ToolsDir, 'rclone\rclone.exe');
    if FileExists(ExecutablePath) then
      Exit(True);

    ExecutablePath := TPath.Combine(FPaths.BinDir, 'rclone\rclone.exe');
    if FileExists(ExecutablePath) then
      Exit(True);

    SearchPathValue := GetEnvironmentVariable('PATH');
    ExecutablePath := FileSearch('rclone.exe', SearchPathValue);
    if ExecutablePath <> '' then
      Exit(True);
  end;

  ExecutablePath := '';
  Result := False;
end;

function TSyncService.BuildRemoteSpec(const Profile: TSyncProfile): string;
begin
  Result := Trim(Profile.RemoteName) + ':' + Trim(Profile.RemotePath);
end;

function TSyncService.QuoteArgument(const Value: string): string;
begin
  Result := '"' + StringReplace(Value, '"', '\"', [rfReplaceAll]) + '"';
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

function TSyncService.BuildArguments(const Profile: TSyncProfile; UseDryRun: Boolean;
  out ExecutablePath, Arguments, WorkingDirectory: string): TRuntimeActionResult;
var
  EmptyEntry: TVHostEntry;
begin
  EmptyEntry.ServerName := '';
  EmptyEntry.ServerAliases := '';
  EmptyEntry.DocumentRoot := '';
  EmptyEntry.EnableSsl := False;
  EmptyEntry.SslCertFile := '';
  EmptyEntry.SslKeyFile := '';
  EmptyEntry.PinnedSyncUploadProfile := '';
  EmptyEntry.PinnedSyncDownloadProfile := '';
  Result := BuildArguments(Profile, EmptyEntry, UseDryRun, ExecutablePath, Arguments, WorkingDirectory);
end;

function TSyncService.BuildArguments(const Profile: TSyncProfile; const Entry: TVHostEntry; UseDryRun: Boolean;
  out ExecutablePath, Arguments, WorkingDirectory: string): TRuntimeActionResult;
var
  Operation: string;
  SourcePath: string;
  DestinationPath: string;
  RemoteSpec: string;
  Builder: TStringBuilder;
  ExcludePattern: string;
  ResolvedLocalPath: string;
  LocalPathValue: string;
  WorkingDirectoryValue: string;
begin
  Result.Success := False;
  Result.Message := '';
  Arguments := '';
  WorkingDirectory := '';
  ExecutablePath := '';

  if not SameText(Profile.Backend, 'rclone') then
  begin
    Result.Message := 'Unsupported sync backend: ' + Profile.Backend;
    Exit;
  end;

  if not ResolveExecutablePath(Profile, ExecutablePath) then
  begin
    Result.Message := 'rclone executable not found. Configure executablePath or install rclone.';
    Exit;
  end;

  if Trim(Profile.Name) = '' then
  begin
    Result.Message := 'Sync profile name is required.';
    Exit;
  end;
  if Trim(Profile.RemoteName) = '' then
  begin
    Result.Message := 'Sync profile remoteName is required.';
    Exit;
  end;
  if Trim(Profile.RemotePath) = '' then
  begin
    Result.Message := 'Sync profile remotePath is required.';
    Exit;
  end;
  if Trim(Profile.LocalPath) = '' then
  begin
    Result.Message := 'Sync profile localPath is required.';
    Exit;
  end;

  LocalPathValue := Profile.LocalPath;
  WorkingDirectoryValue := Profile.WorkingDirectory;
  if Entry.ServerName <> '' then
  begin
    LocalPathValue := ApplyVHostTokens(LocalPathValue, Entry);
    WorkingDirectoryValue := ApplyVHostTokens(WorkingDirectoryValue, Entry);
  end;

  ResolvedLocalPath := ResolvePortablePath(LocalPathValue);
  if ResolvedLocalPath = '' then
  begin
    Result.Message := 'Sync profile localPath is invalid.';
    Exit;
  end;

  if SameText(Profile.Direction, 'upload') then
  begin
    if not TDirectory.Exists(ResolvedLocalPath) and not TFile.Exists(ResolvedLocalPath) then
    begin
      Result.Message := 'Local sync source not found: ' + ResolvedLocalPath;
      Exit;
    end;
  end
  else if SameText(Profile.Direction, 'download') then
  begin
    if not TDirectory.Exists(ResolvedLocalPath) then
      TDirectory.CreateDirectory(ResolvedLocalPath);
  end
  else
  begin
    Result.Message := 'Unsupported sync direction: ' + Profile.Direction;
    Exit;
  end;

  RemoteSpec := BuildRemoteSpec(Profile);
  if Profile.DeleteEnabled then
    Operation := 'sync'
  else
    Operation := 'copy';

  if SameText(Profile.Direction, 'upload') then
  begin
    SourcePath := ResolvedLocalPath;
    DestinationPath := RemoteSpec;
  end
  else
  begin
    SourcePath := RemoteSpec;
    DestinationPath := ResolvedLocalPath;
  end;

  WorkingDirectory := ResolvePortablePath(WorkingDirectoryValue);
  if WorkingDirectory = '' then
    WorkingDirectory := FPaths.AppRoot;
  if not TDirectory.Exists(WorkingDirectory) then
  begin
    Result.Message := 'Sync workingDirectory not found: ' + WorkingDirectory;
    Exit;
  end;

  Builder := TStringBuilder.Create;
  try
    Builder.Append(Operation);
    Builder.Append(' ');
    Builder.Append(QuoteArgument(SourcePath));
    Builder.Append(' ');
    Builder.Append(QuoteArgument(DestinationPath));
    Builder.Append(' --progress');
    if UseDryRun then
      Builder.Append(' --dry-run');
    for ExcludePattern in Profile.Excludes do
    begin
      Builder.Append(' --exclude ');
      Builder.Append(QuoteArgument(ExcludePattern));
    end;
    Arguments := Builder.ToString;
  finally
    Builder.Free;
  end;

  Result.Success := True;
  Result.Message := 'Sync command prepared.';
end;

function TSyncService.BuildCommandPreview(const ProfileName: string; UseDryRun: Boolean;
  out CommandLine: string): TRuntimeActionResult;
var
  Profile: TSyncProfile;
  ExecutablePath: string;
  Arguments: string;
  WorkingDirectory: string;
begin
  CommandLine := '';
  if not TryGetProfile(ProfileName, Profile) then
  begin
    Result.Success := False;
    Result.Message := 'Sync profile not found: ' + ProfileName;
    Exit;
  end;

  Result := BuildArguments(Profile, UseDryRun, ExecutablePath, Arguments, WorkingDirectory);
  if not Result.Success then
    Exit;

  CommandLine := QuoteArgument(ExecutablePath) + ' ' + Arguments;
  Result.Message := 'Sync command preview generated.';
end;

function TSyncService.ExecuteProfile(const ProfileName: string; UseDryRun: Boolean): TRuntimeActionResult;
var
  Profile: TSyncProfile;
  ExecutablePath: string;
  Arguments: string;
  WorkingDirectory: string;
  Output: string;
begin
  if not TryGetProfile(ProfileName, Profile) then
  begin
    Result.Success := False;
    Result.Message := 'Sync profile not found: ' + ProfileName;
    Exit;
  end;

  Result := BuildArguments(Profile, UseDryRun, ExecutablePath, Arguments, WorkingDirectory);
  if not Result.Success then
    Exit;

  if not TProcessManager.RunAndCaptureOutput(ExecutablePath, Arguments, WorkingDirectory, Output, 0) then
  begin
    if Trim(Output) <> '' then
      Result.Message := Trim(Output)
    else
      Result.Message := 'Sync process failed.';
    Exit;
  end;

  Result.Success := True;
  if Trim(Output) <> '' then
    Result.Message := Trim(Output)
  else
    Result.Message := 'Sync completed.';
end;

function TSyncService.BuildCommandPreviewForVHost(const ProfileName, ServerName: string;
  UseDryRun: Boolean; out CommandLine: string): TRuntimeActionResult;
var
  Profile: TSyncProfile;
  Entry: TVHostEntry;
  ExecutablePath: string;
  Arguments: string;
  WorkingDirectory: string;
begin
  CommandLine := '';
  if not TryGetProfile(ProfileName, Profile) then
  begin
    Result.Success := False;
    Result.Message := 'Sync profile not found: ' + ProfileName;
    Exit;
  end;
  if not TryGetVHostEntry(ServerName, Entry) then
  begin
    Result.Success := False;
    Result.Message := 'Project not found: ' + ServerName;
    Exit;
  end;

  Result := BuildArguments(Profile, Entry, UseDryRun, ExecutablePath, Arguments, WorkingDirectory);
  if not Result.Success then
    Exit;

  CommandLine := QuoteArgument(ExecutablePath) + ' ' + Arguments;
  Result.Message := 'Sync command preview generated.';
end;

function TSyncService.ExecuteProfileForVHost(const ProfileName, ServerName: string;
  UseDryRun: Boolean): TRuntimeActionResult;
var
  Profile: TSyncProfile;
  Entry: TVHostEntry;
  ExecutablePath: string;
  Arguments: string;
  WorkingDirectory: string;
  Output: string;
  HookOutput: string;
  PreCommand: string;
  PostCommand: string;
begin
  if not TryGetProfile(ProfileName, Profile) then
  begin
    Result.Success := False;
    Result.Message := 'Sync profile not found: ' + ProfileName;
    Exit;
  end;
  if not TryGetVHostEntry(ServerName, Entry) then
  begin
    Result.Success := False;
    Result.Message := 'Project not found: ' + ServerName;
    Exit;
  end;

  Result := BuildArguments(Profile, Entry, UseDryRun, ExecutablePath, Arguments, WorkingDirectory);
  if not Result.Success then
    Exit;

  PreCommand := ApplyVHostTokens(Profile.PreSyncCommand, Entry);
  PostCommand := ApplyVHostTokens(Profile.PostSyncCommand, Entry);

  if Trim(PreCommand) <> '' then
    if not ExecuteHookCommand(PreCommand, WorkingDirectory, HookOutput) then
    begin
      if Trim(HookOutput) <> '' then
        Result.Message := 'Pre-sync command failed: ' + Trim(HookOutput)
      else
        Result.Message := 'Pre-sync command failed.';
      Exit;
    end;

  if not TProcessManager.RunAndCaptureOutput(ExecutablePath, Arguments, WorkingDirectory, Output, 0) then
  begin
    if Trim(Output) <> '' then
      Result.Message := Trim(Output)
    else
      Result.Message := 'Sync process failed.';
    Exit;
  end;

  if Trim(PostCommand) <> '' then
    if not ExecuteHookCommand(PostCommand, WorkingDirectory, HookOutput) then
    begin
      if Trim(HookOutput) <> '' then
        Result.Message := 'Post-sync command failed: ' + Trim(HookOutput)
      else
        Result.Message := 'Post-sync command failed.';
      Exit;
    end;

  Result.Success := True;
  if Trim(Output) <> '' then
    Result.Message := Trim(Output)
  else
    Result.Message := 'Sync completed.';
end;

end.
