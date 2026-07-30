unit Core.UniWamp.Runtime;

interface

uses
  System.Generics.Collections,
  System.Hash,
  System.Zip,
  System.SysUtils,
  Core.UniWamp.Config,
  Core.UniWamp.ApacheManager,
  Core.UniWamp.MariaDbManager,
  Core.UniWamp.Types,
  Core.UniWamp.Interfaces,
  Core.UniWamp.Paths;

function ChoosePreferredTerminalExecutable(const CmderPath, WindowsTerminalPath: string): string;
function DescribeTerminalLaunchMode(const TerminalExecutable: string): string;

type

  TUniWampRuntime = class(TInterfacedObject, IRuntime)
  private
    FPaths: TAppPaths;
    FConfig: TUniWampConfig;
    FApacheManager: IApacheManager;
    FMariaDbManager: IMariaDbManager;
    function ApacheModuleForSelectedPhp: string;
    function ResolvePortablePath(const PathValue: string): string;
    function CmderExe: string;
    function WindowsTerminalExe: string;
    function BundledToolExecutable(const ToolDir, ExecutableName: string): string;
    function QuoteForCmd(const Value: string): string;
    function BuildCmdCommandLine(const ExecutablePath, Arguments: string): string;
    function ShellExecuteInWorkingDir(const Executable, Parameters, WorkingDir: string): Boolean;
    function ShellExecuteCmdInWorkingDir(const WorkingDir, CommandLine: string): Boolean;
    function PrepareWinScpLaunch(out WinScpExe, WinScpIni, ErrorMessage: string): Boolean;
    function BundledEditorExecutable: string;

    function ApacheModuleDir: string;
    function SelectedPhpDir: string;
    function SelectedPhpExe: string;
    function SelectedNodeDir: string;
    function IsCompatiblePhpVersion(const Version: string): Boolean;
    function IsCompatibleNodeVersion(const Version: string): Boolean;

    function ServiceStateLabel(const Running: Boolean): string;
  public
    constructor Create(const Paths: TAppPaths; Config: TUniWampConfig);
    destructor Destroy; override;
    function DetectPhpVersions: TArray<string>;
    procedure SyncPhpVersions;
    function DetectNodeVersions: TArray<string>;
    procedure SyncNodeVersions;
    function ApacheIsRunning: Boolean;
    function MariaDbIsRunning: Boolean;
    function ApacheProcessId: Cardinal;
    function TerminalExecutablePath: string;
    function PreferredTerminalExecutable: string;
    procedure GenerateAllConfigs;
    function StartApache: TRuntimeActionResult;
    function StopApache: TRuntimeActionResult;
    function RestartApache: TRuntimeActionResult;
    function StartMariaDb: TRuntimeActionResult;
    function StopMariaDb: TRuntimeActionResult;
    function RestartMariaDb: TRuntimeActionResult;
    function AddVHost(const ServerName, DocumentRoot, ServerAliases: string; EnableSsl: Boolean): TRuntimeActionResult;
    function DeleteVHost(const ServerName: string): TRuntimeActionResult;
    function GenerateSslCertificate: TRuntimeActionResult;
    function GenerateEnvBat(const WorkingDir: string): Boolean;
    function ComputeFileSha256Hex(const FileName: string): string;
    function ValidatePackageSha256(const PackageFileName, ExpectedSha256: string; out ErrorMessage: string): Boolean;
    function ValidateUpdateManifest(const ManifestFileName: string; out PackageFileName, ExpectedSha256, PackageVersion: string; out ErrorMessage: string): Boolean;
    function WriteUpdateStagingMetadata(const StagingDir, PackageFileName, ExpectedSha256, PackageVersion: string; out MetadataFileName, ErrorMessage: string): Boolean;
    function CleanupUpdateWorkspace(const WorkspaceDir: string; out ErrorMessage: string): Boolean;
    function StageValidatedUpdatePackage(const ManifestFileName: string; out StagingDir, MetadataFileName, ErrorMessage: string): Boolean;
    function PromoteStagedUpdate(const StagingDir, TargetDir: string; out BackupDir, ErrorMessage: string;
      ForceFailureAfterBackup: Boolean = False): Boolean;
    function ValidateRuntimeZipArchive(const ZipFileName: string; out ErrorMessage: string): Boolean;
    function ImportRuntimeZipArchive(const ZipFileName: string; out ErrorMessage: string): Boolean;
    function PrepareUpdateStagingArea(const PackageName: string; out StagingDir: string; out ErrorMessage: string): Boolean;
    function CreateUpdateRollbackSnapshot(const StagingDir, SnapshotName: string; out SnapshotDir: string; out ErrorMessage: string): Boolean;
    function RollbackUpdateStagingArea(const SnapshotDir, RestoreDir: string; out ErrorMessage: string): Boolean;

    function LaunchUrl(const Url: string): TRuntimeActionResult;
    function LaunchComposerInWorkingDir(const WorkingDir: string): TRuntimeActionResult;
    function LaunchGitInWorkingDir(const WorkingDir: string): TRuntimeActionResult;
    function LaunchNodeInWorkingDir(const WorkingDir: string): TRuntimeActionResult;
    function LaunchWpCliInWorkingDir(const WorkingDir: string): TRuntimeActionResult;
    function LaunchNpmInWorkingDir(const WorkingDir: string): TRuntimeActionResult;
    function LaunchYarnInWorkingDir(const WorkingDir: string): TRuntimeActionResult;
    function LaunchPnpmInWorkingDir(const WorkingDir: string): TRuntimeActionResult;
    function LaunchWinScp: TRuntimeActionResult;
    function LaunchWinScpInWorkingDir(const WorkingDir: string): TRuntimeActionResult;
    function LaunchMailpit: TRuntimeActionResult;
    function LaunchRedis: TRuntimeActionResult;
    function LaunchMemcached: TRuntimeActionResult;
    function LaunchEditor: TRuntimeActionResult;
    function PreferredTextEditorExecutable: string;
    function LaunchTextEditor(const FileName: string): TRuntimeActionResult;

    function LaunchAdminer: TRuntimeActionResult;
    function LaunchTerminal: TRuntimeActionResult;
    function LaunchTerminalInWorkingDir(const WorkingDir: string): TRuntimeActionResult;
    function AreWebToolsReady(out ErrorMessage: string): Boolean;


    function SetMariaDbRootPassword(const NewPassword: string): TRuntimeActionResult;
    function BuildDiagnosticReport: string;
  end;

implementation

uses
  Winapi.Windows,
  Winapi.ShellAPI,
  System.Classes,
  System.JSON,
  System.IOUtils,
  System.StrUtils,
  Core.UniWamp.PortUtils,
  Core.UniWamp.ProcessManager,
  Core.UniWamp.TemplateRenderer,
  Core.UniWamp.ConfigGenerator,
  Core.UniWamp.VHostManager,
  Core.UniWamp.ServiceLocator,
  Core.UniWamp.HostsFileService,
  Core.UniWamp.PackageManager,
  Core.UniWamp.Secrets,
  Core.UniWamp.Diagnostics;



procedure AppendTextToLogFile(const FileName, Text: string);
var
  DirectoryName: string;
begin
  if Trim(Text) = '' then
    Exit;

  DirectoryName := TPath.GetDirectoryName(FileName);
  if DirectoryName <> '' then
    EnsureDirectory(DirectoryName);

  try
    TFile.AppendAllText(
      FileName,
      FormatDateTime('hh:nn:ss', Now) + '  ' + Text + sLineBreak,
      TEncoding.UTF8);
  except
    // Ignore file lock or I/O errors to prevent crashing the caller
  end;
end;

function ChoosePreferredTerminalExecutable(const CmderPath, WindowsTerminalPath: string): string;
begin
  if FileExists(CmderPath) then
    Exit(CmderPath);
  if WindowsTerminalPath <> '' then
    Exit(WindowsTerminalPath);
  Result := 'cmd.exe';
end;

function DescribeTerminalLaunchMode(const TerminalExecutable: string): string;
begin
  if SameText(ExtractFileName(TerminalExecutable), 'wt.exe') then
    Exit('windows-terminal');
  if SameText(ExtractFileName(TerminalExecutable), 'cmd.exe') then
    Exit('cmd');
  Exit('cmder');
end;

function TUniWampRuntime.BundledToolExecutable(const ToolDir, ExecutableName: string): string;
begin
  if (ToolDir = '') or (ExecutableName = '') then
    Exit('');
  Result := TPath.Combine(ToolDir, ExecutableName);
  if not FileExists(Result) then
    Result := '';
end;

function TUniWampRuntime.QuoteForCmd(const Value: string): string;
begin
  Result := '"' + StringReplace(Value, '"', '""', [rfReplaceAll]) + '"';
end;

function TUniWampRuntime.BuildCmdCommandLine(const ExecutablePath, Arguments: string): string;
begin
  Result := QuoteForCmd(ExecutablePath);
  if Trim(Arguments) <> '' then
    Result := Result + ' ' + Arguments;
end;

function TUniWampRuntime.ShellExecuteInWorkingDir(const Executable, Parameters, WorkingDir: string): Boolean;
var
  DirectoryArg: PChar;
begin
  if Trim(WorkingDir) = '' then
    DirectoryArg := nil
  else
    DirectoryArg := PChar(WorkingDir);
  Result := ShellExecute(0, 'open', PChar(Executable), PChar(Parameters), DirectoryArg, SW_SHOWNORMAL) > 32;
end;

function TUniWampRuntime.ShellExecuteCmdInWorkingDir(const WorkingDir, CommandLine: string): Boolean;
begin
  Result := ShellExecuteInWorkingDir('cmd.exe', '/K ' + CommandLine, WorkingDir);
end;

function TUniWampRuntime.PrepareWinScpLaunch(out WinScpExe, WinScpIni, ErrorMessage: string): Boolean;
const
  WinScpIniContents =
    '[Configuration\Interface]' + sLineBreak +
    'RandomSeedFile=.\winscp.rnd' + sLineBreak +
    'DDTemporaryDirectory=.\temp\' + sLineBreak;
var
  WinScpTempDir: string;
begin
  WinScpExe := BundledToolExecutable(FPaths.WinScpDir, 'WinSCP.exe');
  if WinScpExe = '' then
  begin
    ErrorMessage := 'WinSCP was not found in runtime\tools\winscp.';
    Exit(False);
  end;

  WinScpIni := TPath.Combine(FPaths.WinScpDir, 'WinSCP.ini');
  WinScpTempDir := TPath.Combine(FPaths.WinScpDir, 'temp');
  try
    EnsureDirectory(WinScpTempDir);
    if not FileExists(WinScpIni) then
      TFile.WriteAllText(WinScpIni, WinScpIniContents, TEncoding.UTF8);
  except
    on E: Exception do
    begin
      ErrorMessage := 'Unable to prepare WinSCP portable config: ' + E.Message;
      Exit(False);
    end;
  end;

  Result := True;
end;

function TUniWampRuntime.LaunchWinScp: TRuntimeActionResult;
var
  WinScpExe: string;
  WinScpIni: string;
  ErrorMessage: string;
begin
  if not PrepareWinScpLaunch(WinScpExe, WinScpIni, ErrorMessage) then
  begin
    Result.Success := False;
    Result.Message := ErrorMessage;
    Exit;
  end;

  Result.Success := ShellExecuteInWorkingDir(
    WinScpExe,
    '/newinstance /ini=' + QuoteForCmd(WinScpIni),
    FPaths.WinScpDir);
  if Result.Success then
    Result.Message := 'WinSCP launched'
  else
    Result.Message := 'Failed to launch WinSCP';
end;

function TUniWampRuntime.LaunchWinScpInWorkingDir(const WorkingDir: string): TRuntimeActionResult;
var
  WinScpExe: string;
  WinScpIni: string;
  ErrorMessage: string;
begin
  if Trim(WorkingDir) = '' then
  begin
    Result := LaunchWinScp;
    Exit;
  end;

  if not PrepareWinScpLaunch(WinScpExe, WinScpIni, ErrorMessage) then
  begin
    Result.Success := False;
    Result.Message := ErrorMessage;
    Exit;
  end;

  Result.Success := ShellExecuteInWorkingDir(
    WinScpExe,
    '/newinstance /ini=' + QuoteForCmd(WinScpIni),
    FPaths.WinScpDir);
  if Result.Success then
    if Trim(WorkingDir) <> '' then
      Result.Message := 'WinSCP launched. Open ' + WorkingDir + ' from WinSCP manually.'
    else
      Result.Message := 'WinSCP launched'
  else
    Result.Message := 'Failed to launch WinSCP';
end;

constructor TUniWampRuntime.Create(const Paths: TAppPaths; Config: TUniWampConfig);
begin
  inherited Create;
  FPaths := Paths;
  FConfig := Config;
  FApacheManager := TApacheManager.Create(
    FPaths,
    FConfig,
    function: string
    begin
      Result := SelectedPhpDir;
    end,
    function: string
    begin
      Result := SelectedPhpExe;
    end,
    function: string
    begin
      Result := ApacheModuleForSelectedPhp;
    end,
    procedure
    begin
      GenerateAllConfigs;
    end);
  FMariaDbManager := TMariaDbManager.Create(FPaths, FConfig);
end;

destructor TUniWampRuntime.Destroy;
begin
  FApacheManager := nil;
  FMariaDbManager := nil;
  inherited Destroy;
end;

function TUniWampRuntime.ApacheIsRunning: Boolean;
begin
  Result := FApacheManager.IsRunning;
end;

function TUniWampRuntime.ApacheProcessId: Cardinal;
begin
  Result := FApacheManager.ProcessId;
end;

function TUniWampRuntime.MariaDbIsRunning: Boolean;
begin
  Result := FMariaDbManager.IsRunning;
end;

function TUniWampRuntime.ResolvePortablePath(const PathValue: string): string;
begin
  if PathValue = '' then
    Exit('');
  if TPath.IsPathRooted(PathValue) then
    Exit(PathValue);
  Result := TPath.Combine(FPaths.AppRoot, PathValue);
end;

function TUniWampRuntime.CmderExe: string;
var
  ConfiguredPath: string;
begin
  ConfiguredPath := ResolvePortablePath(FConfig.TerminalExePath);
  if ConfiguredPath <> '' then
  begin
    Result := ConfiguredPath;
    Exit;
  end;
  Result := TPath.Combine(FPaths.CmderDir, 'Cmder.exe');
end;

function TUniWampRuntime.WindowsTerminalExe: string;
var
  Buffer: array[0..MAX_PATH] of Char;
  BufferSize: DWORD;
  FilePart: PChar;
begin
  Result := '';
  FilePart := nil;
  BufferSize := SearchPath(nil, 'wt.exe', nil, Length(Buffer), Buffer, FilePart);
  if BufferSize > 0 then
    Result := Buffer;
end;























function TUniWampRuntime.LaunchComposerInWorkingDir(const WorkingDir: string): TRuntimeActionResult;
var
  ComposerExe: string;
  ComposerPhar: string;
  PhpExe: string;
  Buffer: array[0..MAX_PATH] of Char;
  BufferSize: DWORD;
  FilePart: PChar;
begin
  ComposerExe := BundledToolExecutable(FPaths.ComposerDir, 'composer.exe');
  if ComposerExe = '' then
  begin
    FilePart := nil;
    BufferSize := SearchPath(nil, 'composer.exe', nil, Length(Buffer), Buffer, FilePart);
    if BufferSize > 0 then
      ComposerExe := Buffer;
  end;
  if ComposerExe <> '' then
  begin
    Result.Success := ShellExecuteCmdInWorkingDir(WorkingDir, BuildCmdCommandLine(ComposerExe, ''));
    if Result.Success then
      Result.Message := 'Composer launched'
    else
      Result.Message := 'Failed to launch Composer';
    Exit;
  end;

  ComposerPhar := TPath.Combine(FPaths.ComposerDir, 'composer.phar');
  if not FileExists(ComposerPhar) then
  begin
    Result.Success := False;
    Result.Message := 'Composer was not found in runtime\tools\composer or on PATH.';
    Exit;
  end;

  PhpExe := SelectedPhpExe;
  if not FileExists(PhpExe) then
  begin
    FilePart := nil;
    BufferSize := SearchPath(nil, 'php.exe', nil, Length(Buffer), Buffer, FilePart);
    if BufferSize > 0 then
      PhpExe := Buffer;
  end;
  if PhpExe = '' then
  begin
    Result.Success := False;
    Result.Message := 'Composer was found at runtime\tools\composer\composer.phar, but php.exe was not found in the selected PHP runtime or on PATH.';
    Exit;
  end;

  Result.Success := ShellExecuteCmdInWorkingDir(WorkingDir,
    BuildCmdCommandLine(PhpExe, QuoteForCmd(ComposerPhar)));
  if Result.Success then
    Result.Message := 'Composer launched'
  else
    Result.Message := 'Failed to launch Composer';
end;

function TUniWampRuntime.LaunchGitInWorkingDir(const WorkingDir: string): TRuntimeActionResult;
var
  GitExe: string;
  Buffer: array[0..MAX_PATH] of Char;
  BufferSize: DWORD;
  FilePart: PChar;
begin
  GitExe := BundledToolExecutable(FPaths.GitDir, 'git.exe');
  if GitExe = '' then
    GitExe := BundledToolExecutable(TPath.Combine(FPaths.GitDir, 'cmd'), 'git.exe');
  if GitExe = '' then
    GitExe := BundledToolExecutable(TPath.Combine(FPaths.GitDir, 'bin'), 'git.exe');
  if GitExe = '' then
  begin
    FilePart := nil;
    BufferSize := SearchPath(nil, 'git.exe', nil, Length(Buffer), Buffer, FilePart);
    if BufferSize > 0 then
      GitExe := Buffer;
  end;
  if GitExe = '' then
  begin
    Result.Success := False;
    Result.Message := 'Git was not found in runtime\tools\git or on PATH.';
    Exit;
  end;
  Result.Success := ShellExecuteCmdInWorkingDir(WorkingDir, BuildCmdCommandLine(GitExe, 'status'));
  if Result.Success then
    Result.Message := 'Git launched'
  else
    Result.Message := 'Failed to launch Git';
end;

function TUniWampRuntime.LaunchNodeInWorkingDir(const WorkingDir: string): TRuntimeActionResult;
var
  NodeExe: string;
begin
  NodeExe := TPath.Combine(SelectedNodeDir, 'node.exe');
  if not FileExists(NodeExe) then
  begin
    Result.Success := False;
    Result.Message := 'Node executable not found for ' + FConfig.SelectedNodeVersion + '.';
    Exit;
  end;
  Result.Success := ShellExecuteInWorkingDir(NodeExe, '', WorkingDir);
  if Result.Success then
    Result.Message := 'Node launched'
  else
    Result.Message := 'Failed to launch Node';
end;

function TUniWampRuntime.LaunchWpCliInWorkingDir(const WorkingDir: string): TRuntimeActionResult;
var
  WpExe: string;
  WpPhar: string;
  PhpExe: string;
  Buffer: array[0..MAX_PATH] of Char;
  BufferSize: DWORD;
  FilePart: PChar;
begin
  WpExe := BundledToolExecutable(FPaths.WpCliDir, 'wp.exe');
  if WpExe = '' then
  begin
    FilePart := nil;
    BufferSize := SearchPath(nil, 'wp.exe', nil, Length(Buffer), Buffer, FilePart);
    if BufferSize > 0 then
      WpExe := Buffer;
  end;
  if WpExe <> '' then
  begin
    Result.Success := ShellExecuteCmdInWorkingDir(WorkingDir, BuildCmdCommandLine(WpExe, '--info'));
    if Result.Success then
      Result.Message := 'WP-CLI launched'
    else
      Result.Message := 'Failed to launch WP-CLI';
    Exit;
  end;

  WpPhar := TPath.Combine(FPaths.WpCliDir, 'wp-cli.phar');
  if not FileExists(WpPhar) then
  begin
    Result.Success := False;
    Result.Message := 'WP-CLI was not found in runtime\tools\wp-cli or on PATH.';
    Exit;
  end;

  PhpExe := SelectedPhpExe;
  if not FileExists(PhpExe) then
  begin
    FilePart := nil;
    BufferSize := SearchPath(nil, 'php.exe', nil, Length(Buffer), Buffer, FilePart);
    if BufferSize > 0 then
      PhpExe := Buffer;
  end;
  if PhpExe = '' then
  begin
    Result.Success := False;
    Result.Message := 'WP-CLI was found at runtime\tools\wp-cli\wp-cli.phar, but php.exe was not found in the selected PHP runtime or on PATH.';
    Exit;
  end;

  Result.Success := ShellExecuteCmdInWorkingDir(WorkingDir,
    BuildCmdCommandLine(PhpExe, QuoteForCmd(WpPhar) + ' --info'));
  if Result.Success then
    Result.Message := 'WP-CLI launched'
  else
    Result.Message := 'Failed to launch WP-CLI';
end;

function TUniWampRuntime.LaunchNpmInWorkingDir(const WorkingDir: string): TRuntimeActionResult;
var
  NpmExe: string;
  SelectedNpmExe: string;
  Buffer: array[0..MAX_PATH] of Char;
  BufferSize: DWORD;
  FilePart: PChar;
begin
  NpmExe := TPath.Combine(SelectedNodeDir, 'npm.cmd');
  if not FileExists(NpmExe) then
  begin
    SelectedNpmExe := TPath.Combine(SelectedNodeDir, 'node_modules\npm\bin\npm.cmd');
    if FileExists(SelectedNpmExe) then
      NpmExe := SelectedNpmExe
    else
      NpmExe := '';
  end;
  if NpmExe = '' then
  begin
    FilePart := nil;
    BufferSize := SearchPath(nil, 'npm.cmd', nil, Length(Buffer), Buffer, FilePart);
    if BufferSize > 0 then
      NpmExe := Buffer;
  end;
  if NpmExe = '' then
  begin
    Result.Success := False;
    Result.Message := 'npm was not found in the selected Node.js runtime or on PATH.';
    Exit;
  end;
  Result.Success := ShellExecuteCmdInWorkingDir(WorkingDir, BuildCmdCommandLine(NpmExe, ''));
  if Result.Success then
    Result.Message := 'npm launched'
  else
    Result.Message := 'Failed to launch npm';
end;

function TUniWampRuntime.LaunchYarnInWorkingDir(const WorkingDir: string): TRuntimeActionResult;
var
  YarnExe: string;
  SelectedYarnExe: string;
  Buffer: array[0..MAX_PATH] of Char;
  BufferSize: DWORD;
  FilePart: PChar;
begin
  YarnExe := TPath.Combine(SelectedNodeDir, 'yarn.cmd');
  if not FileExists(YarnExe) then
  begin
    SelectedYarnExe := TPath.Combine(SelectedNodeDir, 'node_modules\corepack\shims\yarn.cmd');
    if FileExists(SelectedYarnExe) then
      YarnExe := SelectedYarnExe
    else
      YarnExe := '';
  end;
  if YarnExe = '' then
  begin
    SelectedYarnExe := TPath.Combine(SelectedNodeDir, 'node_modules\corepack\shims\yarnpkg.cmd');
    if FileExists(SelectedYarnExe) then
      YarnExe := SelectedYarnExe;
  end;
  if YarnExe = '' then
  begin
    FilePart := nil;
    BufferSize := SearchPath(nil, 'yarn.cmd', nil, Length(Buffer), Buffer, FilePart);
    if BufferSize > 0 then
      YarnExe := Buffer;
  end;
  if YarnExe = '' then
  begin
    Result.Success := False;
    Result.Message := 'yarn was not found in the selected Node.js runtime or on PATH.';
    Exit;
  end;
  Result.Success := ShellExecuteCmdInWorkingDir(WorkingDir, BuildCmdCommandLine(YarnExe, ''));
  if Result.Success then
    Result.Message := 'yarn launched'
  else
    Result.Message := 'Failed to launch yarn';
end;

function TUniWampRuntime.LaunchPnpmInWorkingDir(const WorkingDir: string): TRuntimeActionResult;
var
  PnpmExe: string;
  SelectedPnpmExe: string;
  Buffer: array[0..MAX_PATH] of Char;
  BufferSize: DWORD;
  FilePart: PChar;
begin
  PnpmExe := TPath.Combine(SelectedNodeDir, 'pnpm.cmd');
  if not FileExists(PnpmExe) then
  begin
    SelectedPnpmExe := TPath.Combine(SelectedNodeDir, 'node_modules\corepack\shims\pnpm.cmd');
    if FileExists(SelectedPnpmExe) then
      PnpmExe := SelectedPnpmExe
    else
      PnpmExe := '';
  end;
  if PnpmExe = '' then
  begin
    PnpmExe := '';
    FilePart := nil;
    BufferSize := SearchPath(nil, 'pnpm.cmd', nil, Length(Buffer), Buffer, FilePart);
    if BufferSize > 0 then
      PnpmExe := Buffer;
  end;
  if PnpmExe = '' then
  begin
    Result.Success := False;
    Result.Message := 'pnpm was not found in the selected Node.js runtime or on PATH.';
    Exit;
  end;
  Result.Success := ShellExecuteCmdInWorkingDir(WorkingDir, BuildCmdCommandLine(PnpmExe, ''));
  if Result.Success then
    Result.Message := 'pnpm launched'
  else
    Result.Message := 'Failed to launch pnpm';
end;

function TUniWampRuntime.LaunchMailpit: TRuntimeActionResult;
var
  MailpitExe: string;
  Buffer: array[0..MAX_PATH] of Char;
  BufferSize: DWORD;
  FilePart: PChar;
begin
  MailpitExe := BundledToolExecutable(FPaths.MailpitDir, 'mailpit.exe');
  if MailpitExe = '' then
  begin
    FilePart := nil;
    BufferSize := SearchPath(nil, 'mailpit.exe', nil, Length(Buffer), Buffer, FilePart);
    if BufferSize > 0 then
      MailpitExe := Buffer;
  end;
  if MailpitExe = '' then
  begin
    Result.Success := False;
    Result.Message := 'Mailpit was not found in runtime\tools\mailpit or on PATH.';
    Exit;
  end;
  Result.Success := ShellExecuteInWorkingDir(MailpitExe, '', FPaths.AppRoot);
  if Result.Success then
    Result.Message := 'Mailpit launched'
  else
    Result.Message := 'Failed to launch Mailpit';
end;

function TUniWampRuntime.LaunchRedis: TRuntimeActionResult;
var
  RedisExe: string;
  Buffer: array[0..MAX_PATH] of Char;
  BufferSize: DWORD;
  FilePart: PChar;
begin
  RedisExe := BundledToolExecutable(FPaths.RedisDir, 'redis-server.exe');
  if RedisExe = '' then
  begin
    FilePart := nil;
    BufferSize := SearchPath(nil, 'redis-server.exe', nil, Length(Buffer), Buffer, FilePart);
    if BufferSize > 0 then
      RedisExe := Buffer;
  end;
  if RedisExe = '' then
  begin
    Result.Success := False;
    Result.Message := 'Redis was not found in runtime\tools\redis or on PATH.';
    Exit;
  end;
  Result.Success := ShellExecuteInWorkingDir(RedisExe, '', FPaths.AppRoot);
  if Result.Success then
    Result.Message := 'Redis launched'
  else
    Result.Message := 'Failed to launch Redis';
end;

function TUniWampRuntime.LaunchMemcached: TRuntimeActionResult;
const
  MemcachedCandidates: array[0..2] of string = ('memcached.exe', 'memcached-avx.exe', 'memcached-tls.exe');
var
  MemcachedExe: string;
  Buffer: array[0..MAX_PATH] of Char;
  BufferSize: DWORD;
  FilePart: PChar;
  Candidate: string;
begin
  MemcachedExe := '';
  for Candidate in MemcachedCandidates do
  begin
    MemcachedExe := BundledToolExecutable(FPaths.MemcachedDir, Candidate);
    if MemcachedExe <> '' then
      Break;
  end;
  if MemcachedExe = '' then
  begin
    FilePart := nil;
    BufferSize := SearchPath(nil, 'memcached.exe', nil, Length(Buffer), Buffer, FilePart);
    if BufferSize > 0 then
      MemcachedExe := Buffer;
  end;
  if MemcachedExe = '' then
  begin
    Result.Success := False;
    Result.Message := 'Memcached was not found in runtime\tools\memcached or on PATH.';
    Exit;
  end;
  Result.Success := ShellExecuteInWorkingDir(MemcachedExe, '', FPaths.AppRoot);
  if Result.Success then
    Result.Message := 'Memcached launched'
  else
    Result.Message := 'Failed to launch Memcached';
end;

function TUniWampRuntime.LaunchEditor: TRuntimeActionResult;
begin
  Result := LaunchTextEditor(FPaths.AppRoot);
end;







function TUniWampRuntime.TerminalExecutablePath: string;
begin
  Result := CmderExe;
end;

function TUniWampRuntime.PreferredTerminalExecutable: string;
begin
  Result := ChoosePreferredTerminalExecutable(TerminalExecutablePath, WindowsTerminalExe);
end;

function TUniWampRuntime.ApacheModuleDir: string;
begin
  Result := TPath.Combine(FPaths.ApacheDir, 'modules');
end;



function TUniWampRuntime.SelectedPhpDir: string;
begin
  Result := TPath.Combine(FPaths.PhpDir, FConfig.SelectedPhpVersion);
end;

function TUniWampRuntime.SelectedPhpExe: string;
begin
  Result := TPath.Combine(SelectedPhpDir, 'php.exe');
end;

function TUniWampRuntime.SelectedNodeDir: string;
begin
  Result := TPath.Combine(FPaths.NodeDir, FConfig.SelectedNodeVersion);
end;







function TUniWampRuntime.ApacheModuleForSelectedPhp: string;
var
  Candidates: TArray<string>;
begin
  Candidates := TDirectory.GetFiles(SelectedPhpDir, 'php*apache2_4.dll');
  if Length(Candidates) > 0 then
    Exit(Candidates[0]);

  Result := TPath.Combine(SelectedPhpDir, 'php8apache2_4.dll');
  if not FileExists(Result) then
    Result := TPath.Combine(SelectedPhpDir, 'php7apache2_4.dll');
end;

function TUniWampRuntime.IsCompatiblePhpVersion(const Version: string): Boolean;
var
  PhpDir: string;
begin
  Result := False;
  if Trim(Version) = '' then
    Exit;
  PhpDir := TPath.Combine(FPaths.PhpDir, Version);
  if not TDirectory.Exists(PhpDir) then
    Exit;
  if not FileExists(TPath.Combine(PhpDir, 'php.exe')) then
    Exit;
  Result := Length(TDirectory.GetFiles(PhpDir, 'php*apache2_4.dll')) > 0;
end;

function TUniWampRuntime.IsCompatibleNodeVersion(const Version: string): Boolean;
var
  NodeDir: string;
begin
  Result := False;
  if Trim(Version) = '' then
    Exit;
  NodeDir := TPath.Combine(FPaths.NodeDir, Version);
  if not TDirectory.Exists(NodeDir) then
    Exit;
  Result := FileExists(TPath.Combine(NodeDir, 'node.exe'));
end;



function TUniWampRuntime.BuildDiagnosticReport: string;
var
  Lines: TStringList;
  HttpOwner: string;
  HttpsOwner: string;
  DbOwner: string;
begin
  Lines := TStringList.Create;
  try
    HttpOwner := DescribeTcpPortOwner(FConfig.HttpPort);
    HttpsOwner := DescribeTcpPortOwner(FConfig.HttpsPort);
    DbOwner := DescribeTcpPortOwner(FConfig.DatabasePort);

    Lines.Add('UniWamp Diagnostic Report');
    Lines.Add('Generated: ' + FormatDateTime('yyyy-mm-dd hh:nn:ss', Now));
    Lines.Add('App root: ' + FPaths.AppRoot);
    Lines.Add('Config dir: ' + FPaths.ConfigDir);
    Lines.Add('Runtime dir: ' + FPaths.RuntimeDir);
    Lines.Add('Logs dir: ' + FPaths.LogsDir);
    Lines.Add('Document root: ' + FConfig.DocumentRoot);
    Lines.Add('Host name: ' + FConfig.HostName);
    Lines.Add('PHP version: ' + FConfig.SelectedPhpVersion);
    Lines.Add('PHP profile: ' + FConfig.PhpProfile);
    Lines.Add('Node version: ' + FConfig.SelectedNodeVersion);
    Lines.Add('Apache: ' + ServiceStateLabel(FConfig.ApacheRunning) + ' pid=' + IntToStr(FConfig.ApachePid) + ' port=' + IntToStr(FConfig.HttpPort));
    Lines.Add('Apache port owner: ' + HttpOwner);
    Lines.Add('Apache SSL port owner: ' + HttpsOwner);
    Lines.Add('MariaDB: ' + ServiceStateLabel(FConfig.MariaDbRunning) + ' pid=' + IntToStr(FConfig.MariaDbPid) + ' port=' + IntToStr(FConfig.DatabasePort));
    Lines.Add('MariaDB port owner: ' + DbOwner);
    Lines.Add('VHosts: ' + IntToStr(Length(FConfig.VHosts)));
    Lines.Add('Last hosts sync: ' + FConfig.LastHostsSyncStatus);
    Lines.Add('Last Apache error: ' + FConfig.LastApacheError);
    Lines.Add('Last MariaDB error: ' + FConfig.LastMariaDbError);
    if HasMariaDbRootPassword(FPaths) then
      Lines.Add('MariaDB root password: [redacted]')
    else
      Lines.Add('MariaDB root password: (not set)');
    Lines.Add('Apache config: ' + FPaths.ApacheHttpdConfFile);
    Lines.Add('Apache SSL config: ' + FPaths.ApacheSslConfFile);
    Lines.Add('Apache vhosts config: ' + FPaths.ApacheVHostsConfFile);
    Lines.Add('MariaDB config: ' + FPaths.MariaDbIniFile);
    Lines.Add('PHP config: ' + FPaths.ActivePhpIniFile);
    var HostsFileService := THostsFileService.Create(FPaths, FConfig);
    try
      Lines.Add('Hosts file: ' + HostsFileService.HostsFilePath);
    finally
      HostsFileService.Free;
    end;
    Result := RedactSensitiveText(Lines.Text);
  finally
    Lines.Free;
  end;
end;

function TUniWampRuntime.DetectPhpVersions: TArray<string>;
var
  Dirs: TArray<string>;
  Item: string;
  Values: TList<string>;
begin
  Values := TList<string>.Create;
  try
    if TDirectory.Exists(FPaths.PhpDir) then
    begin
      Dirs := TDirectory.GetDirectories(FPaths.PhpDir);
      for Item in Dirs do
        Values.Add(ExtractFileName(Item));
    end;
    Result := Values.ToArray;
  finally
    Values.Free;
  end;
end;

procedure TUniWampRuntime.SyncPhpVersions;
var
  Versions: TArray<string>;
  Candidate: string;
begin
  Versions := DetectPhpVersions;
  if Length(Versions) > 0 then
  begin
    FConfig.ReplacePhpVersions(Versions);
    if IsCompatiblePhpVersion(FConfig.SelectedPhpVersion) then
      Exit;
    for Candidate in Versions do
      if IsCompatiblePhpVersion(Candidate) then
      begin
        FConfig.SelectedPhpVersion := Candidate;
        Exit;
      end;
  end;
end;

function TUniWampRuntime.DetectNodeVersions: TArray<string>;
var
  Dirs: TArray<string>;
  Item: string;
  Values: TList<string>;
begin
  Values := TList<string>.Create;
  try
    if TDirectory.Exists(FPaths.NodeDir) then
    begin
      Dirs := TDirectory.GetDirectories(FPaths.NodeDir);
      for Item in Dirs do
        Values.Add(ExtractFileName(Item));
    end;
    Result := Values.ToArray;
  finally
    Values.Free;
  end;
end;

procedure TUniWampRuntime.SyncNodeVersions;
var
  Versions: TArray<string>;
  Candidate: string;
begin
  Versions := DetectNodeVersions;
  if Length(Versions) > 0 then
  begin
    FConfig.ReplaceNodeVersions(Versions);
    if IsCompatibleNodeVersion(FConfig.SelectedNodeVersion) then
      Exit;
    for Candidate in Versions do
      if IsCompatibleNodeVersion(Candidate) then
      begin
        FConfig.SelectedNodeVersion := Candidate;
        Exit;
      end;
  end;
end;

function NormalizeServerAliases(const Aliases: string): string;
var
  Parts: TStringList;
  Item: string;
  NormalizedItem: string;
begin
  Parts := TStringList.Create;
  try
    Parts.StrictDelimiter := True;
    Parts.Delimiter := ' ';
    Parts.DelimitedText := StringReplace(StringReplace(Trim(Aliases), ',', ' ', [rfReplaceAll]), #9, ' ', [rfReplaceAll]);
    Result := '';
    for Item in Parts do
    begin
      NormalizedItem := Trim(Item);
      if NormalizedItem = '' then
        Continue;
      if Result <> '' then
        Result := Result + ' ';
      Result := Result + NormalizedItem;
    end;
  finally
    Parts.Free;
  end;
end;





procedure TUniWampRuntime.GenerateAllConfigs;
var
  HostsError: string;
  Generator: TConfigurationGenerator;
  HostsFileService: THostsFileService;
begin
  TTemplateRenderer.EnsureDefaultTemplates(FPaths);
  Generator := TConfigurationGenerator.Create(FPaths, FConfig);
  try
    Generator.GeneratePhpConfig(SelectedPhpDir);
    Generator.GenerateVHostConfig;
    Generator.GenerateApacheConfig(ApacheModuleDir, ApacheModuleForSelectedPhp);
    Generator.GenerateMariaDbConfig;
  finally
    Generator.Free;
  end;

  HostsFileService := THostsFileService.Create(FPaths, FConfig);
  try
    HostsFileService.SyncHostsFile(HostsError);
  finally
    HostsFileService.Free;
  end;
end;

function TUniWampRuntime.GenerateEnvBat(const WorkingDir: string): Boolean;
begin
  with TConfigurationGenerator.Create(FPaths, FConfig) do
  try
    GenerateEnvBat(WorkingDir, SelectedPhpDir, SelectedNodeDir);
    Result := True;
  finally
    Free;
  end;
end;

function TUniWampRuntime.AddVHost(const ServerName, DocumentRoot, ServerAliases: string;
  EnableSsl: Boolean): TRuntimeActionResult;
begin
  with TVHostManager.Create(FPaths, FConfig) do
  try
    Result := AddVHost(ServerName, DocumentRoot, ServerAliases, EnableSsl);
  finally
    Free;
  end;
end;

function TUniWampRuntime.DeleteVHost(const ServerName: string): TRuntimeActionResult;
begin
  with TVHostManager.Create(FPaths, FConfig) do
  try
    Result := DeleteVHost(ServerName);
  finally
    Free;
  end;
end;

function TUniWampRuntime.GenerateSslCertificate: TRuntimeActionResult;
begin
  with TVHostManager.Create(FPaths, FConfig) do
  try
    Result := GenerateSslCertificate;
  finally
    Free;
  end;
end;

function TUniWampRuntime.ComputeFileSha256Hex(const FileName: string): string;
begin
  with TPackageManager.Create(FPaths) do
  try
    Result := ComputeFileSha256Hex(FileName);
  finally
    Free;
  end;
end;

function TUniWampRuntime.ValidatePackageSha256(const PackageFileName, ExpectedSha256: string;
  out ErrorMessage: string): Boolean;
begin
  with TPackageManager.Create(FPaths) do
  try
    Result := ValidatePackageSha256(PackageFileName, ExpectedSha256, ErrorMessage);
  finally
    Free;
  end;
end;

function TUniWampRuntime.ValidateUpdateManifest(const ManifestFileName: string;
  out PackageFileName, ExpectedSha256, PackageVersion: string; out ErrorMessage: string): Boolean;
begin
  with TPackageManager.Create(FPaths) do
  try
    Result := ValidateUpdateManifest(ManifestFileName, PackageFileName, ExpectedSha256, PackageVersion, ErrorMessage);
  finally
    Free;
  end;
end;

function TUniWampRuntime.WriteUpdateStagingMetadata(const StagingDir, PackageFileName,
  ExpectedSha256, PackageVersion: string; out MetadataFileName, ErrorMessage: string): Boolean;
begin
  with TPackageManager.Create(FPaths) do
  try
    Result := WriteUpdateStagingMetadata(StagingDir, PackageFileName, ExpectedSha256, PackageVersion, MetadataFileName, ErrorMessage);
  finally
    Free;
  end;
end;

function TUniWampRuntime.CleanupUpdateWorkspace(const WorkspaceDir: string; out ErrorMessage: string): Boolean;
begin
  with TPackageManager.Create(FPaths) do
  try
    Result := CleanupUpdateWorkspace(WorkspaceDir, ErrorMessage);
  finally
    Free;
  end;
end;

function TUniWampRuntime.StageValidatedUpdatePackage(const ManifestFileName: string;
  out StagingDir, MetadataFileName, ErrorMessage: string): Boolean;
begin
  with TPackageManager.Create(FPaths) do
  try
    Result := StageValidatedUpdatePackage(ManifestFileName, StagingDir, MetadataFileName, ErrorMessage);
  finally
    Free;
  end;
end;

function TUniWampRuntime.PromoteStagedUpdate(const StagingDir, TargetDir: string;
  out BackupDir, ErrorMessage: string; ForceFailureAfterBackup: Boolean): Boolean;
begin
  with TPackageManager.Create(FPaths) do
  try
    Result := PromoteStagedUpdate(StagingDir, TargetDir, BackupDir, ErrorMessage, ForceFailureAfterBackup);
  finally
    Free;
  end;
end;

function TUniWampRuntime.ValidateRuntimeZipArchive(const ZipFileName: string;
  out ErrorMessage: string): Boolean;
begin
  with TPackageManager.Create(FPaths) do
  try
    Result := ValidateRuntimeZipArchive(ZipFileName, ErrorMessage);
  finally
    Free;
  end;
end;

function TUniWampRuntime.ImportRuntimeZipArchive(const ZipFileName: string; out ErrorMessage: string): Boolean;
begin
  with TPackageManager.Create(FPaths) do
  try
    Result := ImportRuntimeZipArchive(ZipFileName, ErrorMessage);
  finally
    Free;
  end;
end;

function TUniWampRuntime.PrepareUpdateStagingArea(const PackageName: string; out StagingDir: string;
  out ErrorMessage: string): Boolean;
begin
  with TPackageManager.Create(FPaths) do
  try
    Result := PrepareUpdateStagingArea(PackageName, StagingDir, ErrorMessage);
  finally
    Free;
  end;
end;

function TUniWampRuntime.CreateUpdateRollbackSnapshot(const StagingDir, SnapshotName: string;
  out SnapshotDir: string; out ErrorMessage: string): Boolean;
begin
  with TPackageManager.Create(FPaths) do
  try
    Result := CreateUpdateRollbackSnapshot(StagingDir, SnapshotName, SnapshotDir, ErrorMessage);
  finally
    Free;
  end;
end;

function TUniWampRuntime.RollbackUpdateStagingArea(const SnapshotDir, RestoreDir: string;
  out ErrorMessage: string): Boolean;
begin
  with TPackageManager.Create(FPaths) do
  try
    Result := RollbackUpdateStagingArea(SnapshotDir, RestoreDir, ErrorMessage);
  finally
    Free;
  end;
end;

function TUniWampRuntime.StartApache: TRuntimeActionResult;
begin
  SyncPhpVersions;
  Result := FApacheManager.Start;
end;

function TUniWampRuntime.StopApache: TRuntimeActionResult;
begin
  Result := FApacheManager.Stop;
end;

function TUniWampRuntime.RestartApache: TRuntimeActionResult;
begin
  Result := FApacheManager.Restart;
end;

function TUniWampRuntime.StartMariaDb: TRuntimeActionResult;
begin
  Result := FMariaDbManager.Start;
end;

function TUniWampRuntime.StopMariaDb: TRuntimeActionResult;
begin
  Result := FMariaDbManager.Stop;
end;

function TUniWampRuntime.RestartMariaDb: TRuntimeActionResult;
begin
  Result := FMariaDbManager.Restart;
end;





function TUniWampRuntime.SetMariaDbRootPassword(const NewPassword: string): TRuntimeActionResult;
begin
  Result := FMariaDbManager.SetRootPassword(NewPassword);
end;

function TUniWampRuntime.LaunchUrl(const Url: string): TRuntimeActionResult;
begin
  Result.Success := ShellExecuteInWorkingDir(Url, '', '');
  if Result.Success then
    Result.Message := 'Launched ' + Url
  else
    Result.Message := 'Failed to launch ' + Url;
end;

function TUniWampRuntime.PreferredTextEditorExecutable: string;
begin
  Result := BundledEditorExecutable;
  if Result = '' then
    Result := ResolvePortablePath(GetEnvironmentVariable('EDITOR'));
  if Result = '' then
    Result := 'notepad.exe';
end;

function TUniWampRuntime.LaunchTextEditor(const FileName: string): TRuntimeActionResult;
var
  EditorExe: string;
begin
  EditorExe := PreferredTextEditorExecutable;
  Result.Success := ShellExecuteInWorkingDir(EditorExe, QuoteForCmd(FileName), '');
  if Result.Success then
    Result.Message := 'Launched ' + EditorExe
  else
    Result.Message := 'Failed to launch ' + EditorExe;
end;

function TUniWampRuntime.BundledEditorExecutable: string;
begin
  Result := TPath.Combine(FPaths.AppRoot, 'runtime\tools\lite-xl\lite-xl.exe');
  if not FileExists(Result) then
    Result := '';
end;

function TUniWampRuntime.LaunchAdminer: TRuntimeActionResult;
var
  AdminerUrl: string;
begin
  if not AreWebToolsReady(Result.Message) then
  begin
    Result.Success := False;
    Exit;
  end;
  if FileExists(TPath.Combine(FPaths.AdminerDir, 'index.php')) then
  begin
    AdminerUrl := Format('http://%s:%d/adminer/index.php?server=127.0.0.1:%d&username=root',
      [FConfig.HostName, FConfig.HttpPort, FConfig.DatabasePort]);
    Result := LaunchUrl(AdminerUrl);
  end
  else
  begin
    Result.Success := False;
    Result.Message := 'Adminer entrypoint not found in home\adminer\index.php';
  end;
end;

function TUniWampRuntime.AreWebToolsReady(out ErrorMessage: string): Boolean;
begin
  Result := False;
  ErrorMessage := '';
  if not FConfig.ApacheRunning then
  begin
    ErrorMessage := 'Web tools require Apache to be running.';
    Exit;
  end;
  if not FConfig.MariaDbRunning then
  begin
    ErrorMessage := 'Web tools require MariaDB to be running.';
    Exit;
  end;
  if Trim(FConfig.SelectedPhpVersion) = '' then
  begin
    ErrorMessage := 'Web tools require a selected PHP runtime.';
    Exit;
  end;
  if not FileExists(SelectedPhpExe) then
  begin
    ErrorMessage := 'Web tools require the selected PHP runtime to exist: ' + SelectedPhpExe;
    Exit;
  end;
  if not FileExists(ApacheModuleForSelectedPhp) then
  begin
    ErrorMessage := 'Web tools require the Apache PHP module for ' + FConfig.SelectedPhpVersion;
    Exit;
  end;
  Result := True;
end;

function TUniWampRuntime.LaunchTerminal: TRuntimeActionResult;
begin
  Result := LaunchTerminalInWorkingDir(FConfig.DocumentRoot);
end;

function TUniWampRuntime.LaunchTerminalInWorkingDir(const WorkingDir: string): TRuntimeActionResult;
var
  ProfileText: string;
  ProfileDir: string;
  TargetCmd: string;
  TerminalExe: string;
begin
  var Generator := TConfigurationGenerator.Create(FPaths, FConfig);
  try
    Generator.GenerateEnvBat(WorkingDir, SelectedPhpDir, SelectedNodeDir);
  finally
    Generator.Free;
  end;
  TerminalExe := PreferredTerminalExecutable;

  if FileExists(TerminalExe) then
  begin
    ProfileDir := TPath.Combine(ExtractFileDir(TerminalExe), 'config\profile.d');
    EnsureDirectory(ProfileDir);
    TargetCmd := TPath.Combine(ProfileDir, 'uniwamp_env.cmd');
    ProfileText := TFile.ReadAllText(FPaths.EnvBatFile, TEncoding.UTF8);
    TFile.WriteAllText(TargetCmd, ProfileText, TEncoding.ASCII);

    Result.Success := ShellExecuteInWorkingDir(TerminalExe, '/START ' + QuoteForCmd(WorkingDir), '');
    if Result.Success then
      Result.Message := 'Launched Cmder terminal'
      else
      Result.Message := 'Failed to launch Cmder terminal';
  end
  else if DescribeTerminalLaunchMode(TerminalExe) = 'windows-terminal' then
  begin
    Result.Success := ShellExecuteInWorkingDir(TerminalExe, '-d ' + QuoteForCmd(WorkingDir), '');
    if Result.Success then
      Result.Message := 'Launched Windows Terminal'
    else
      Result.Message := 'Failed to launch Windows Terminal';
  end
  else
  begin
    Result.Success := ShellExecuteCmdInWorkingDir(WorkingDir, QuoteForCmd(FPaths.EnvBatFile));
    if Result.Success then
      Result.Message := 'Launched standard CMD terminal'
    else
      Result.Message := 'Failed to launch standard CMD terminal';
  end;
end;







function TUniWampRuntime.ServiceStateLabel(const Running: Boolean): string;
begin
  if Running then
    Result := 'running'
  else
    Result := 'stopped';
end;

end.
