unit Core.UniWamp.Runtime;

interface

uses
  System.Generics.Collections,
  System.Hash,
  System.Zip,
  System.SysUtils,
  Core.UniWamp.Config,
  Core.UniWamp.Paths;

function ChoosePreferredTerminalExecutable(const CmderPath, WindowsTerminalPath: string): string;

type
  TRuntimeActionResult = record
    Success: Boolean;
    Message: string;
  end;

  TUniWampRuntime = class
  private
    FPaths: TAppPaths;
    FConfig: TUniWampConfig;
    function ApacheExe: string;
    function ApacheRuntimePid: Cardinal;
    function ApacheModuleForSelectedPhp: string;
    procedure EnsureVHostStarterPage(const ServerName, DocumentRoot: string);
    function HostsFilePath: string;
    function MariaDbExe: string;
    function MariaDbInstallDbExe: string;
    function MysqlAdminExe: string;
    function MariaDbSystemDatabaseReady(const MysqlDir: string): Boolean;
    function EnsureMariaDbInitialized(out ErrorMessage: string): Boolean;
    function WaitForMariaDbStartup(const ProcessId: Cardinal; out ErrorMessage: string): Boolean;
    function ResolvePortablePath(const PathValue: string): string;
    function CmderExe: string;
    function WindowsTerminalExe: string;
    function RenderManagedHostsBlock: string;
    function ApacheModuleDir: string;
    function RenderApacheModuleLines: string;
    function SelectedPhpDir: string;
    function SelectedPhpExe: string;
    function SelectedNodeDir: string;
    function RenderPhpExtensionLines: string;
    function EnsureDefaultSslCertificate(out ErrorMessage: string): Boolean;
    function ServiceStateLabel(const Running: Boolean): string;
    procedure GenerateApacheConfig;
    procedure GenerateMariaDbConfig;
    procedure GeneratePhpConfig;
    procedure GenerateVHostConfig;
    function SyncHostsFile(out ErrorMessage: string): Boolean;
    function RenderVHostBlocks: string;
    function ValidateApachePorts(out ErrorMessage: string): Boolean;
    function ValidateApacheConfiguration(out ErrorMessage: string): Boolean;
    function WaitForApacheStartup(const ProcessId: Cardinal; out ErrorMessage: string): Boolean;
    function ValidateMariaDbPorts(out ErrorMessage: string): Boolean;
  public
    constructor Create(const Paths: TAppPaths; Config: TUniWampConfig);
    function DetectPhpVersions: TArray<string>;
    procedure SyncPhpVersions;
    function DetectNodeVersions: TArray<string>;
    procedure SyncNodeVersions;
    function ApacheIsRunning: Boolean;
    function MariaDbIsRunning: Boolean;
    function ApacheProcessId: Cardinal;
    function TerminalExecutablePath: string;
    function PreferredTerminalExecutable: string;
    procedure GenerateEnvBat;
    procedure GenerateAllConfigs;
    function StartApache: TRuntimeActionResult;
    function StopApache: TRuntimeActionResult;
    function RestartApache: TRuntimeActionResult;
    function StartMariaDb: TRuntimeActionResult;
    function StopMariaDb: TRuntimeActionResult;
    function RestartMariaDb: TRuntimeActionResult;
    function GenerateSslCertificate: TRuntimeActionResult;
    function LaunchUrl(const Url: string): TRuntimeActionResult;
    function LaunchComposerInWorkingDir(const WorkingDir: string): TRuntimeActionResult;
    function LaunchGitInWorkingDir(const WorkingDir: string): TRuntimeActionResult;
    function LaunchNodeInWorkingDir(const WorkingDir: string): TRuntimeActionResult;
    function LaunchWpCliInWorkingDir(const WorkingDir: string): TRuntimeActionResult;
    function LaunchNpmInWorkingDir(const WorkingDir: string): TRuntimeActionResult;
    function LaunchYarnInWorkingDir(const WorkingDir: string): TRuntimeActionResult;
    function LaunchPnpmInWorkingDir(const WorkingDir: string): TRuntimeActionResult;
    function LaunchMailpit: TRuntimeActionResult;
    function LaunchRedis: TRuntimeActionResult;
    function LaunchMemcached: TRuntimeActionResult;
    function LaunchEditor: TRuntimeActionResult;
    function PreferredTextEditorExecutable: string;
    function LaunchTextEditor(const FileName: string): TRuntimeActionResult;
    function ComputeFileSha256Hex(const FileName: string): string;
    function ValidatePackageSha256(const PackageFileName, ExpectedSha256: string; out ErrorMessage: string): Boolean;
    function ValidateUpdateManifest(const ManifestFileName: string; out PackageFileName, ExpectedSha256, PackageVersion: string; out ErrorMessage: string): Boolean;
    function WriteUpdateStagingMetadata(const StagingDir, PackageFileName, ExpectedSha256, PackageVersion: string; out MetadataFileName, ErrorMessage: string): Boolean;
    function CleanupUpdateWorkspace(const WorkspaceDir: string; out ErrorMessage: string): Boolean;
    function ValidateRuntimeZipArchive(const ZipFileName: string; out ErrorMessage: string): Boolean;
    function ImportRuntimeZipArchive(const ZipFileName: string; out ErrorMessage: string): Boolean;
    function PrepareUpdateStagingArea(const PackageName: string; out StagingDir: string; out ErrorMessage: string): Boolean;
    function CreateUpdateRollbackSnapshot(const StagingDir, SnapshotName: string; out SnapshotDir: string; out ErrorMessage: string): Boolean;
    function RollbackUpdateStagingArea(const SnapshotDir, RestoreDir: string; out ErrorMessage: string): Boolean;
    function LaunchAdminer: TRuntimeActionResult;
    function LaunchTerminal: TRuntimeActionResult;
    function LaunchTerminalInWorkingDir(const WorkingDir: string): TRuntimeActionResult;
    function GenerateSslCertificateFor(const CommonName, CertFile, KeyFile: string): TRuntimeActionResult;
    function AddVHost(const ServerName, DocumentRoot, ServerAliases: string; EnableSsl: Boolean): TRuntimeActionResult;
    function RefreshVHostSslCertificate(const ServerName: string): TRuntimeActionResult;
    function DeleteVHost(const ServerName: string): TRuntimeActionResult;
    function SetMariaDbRootPassword(const NewPassword: string): TRuntimeActionResult;
    function DescribePortOwner(const Port: Integer): string;
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
  Core.UniWamp.TemplateRenderer;

const
  ManagedHostsBeginMarker = '# BEGIN UniWamp Managed Hosts';
  ManagedHostsEndMarker = '# END UniWamp Managed Hosts';

procedure AppendTextToLogFile(const FileName, Text: string);
var
  DirectoryName: string;
begin
  if Trim(Text) = '' then
    Exit;

  DirectoryName := TPath.GetDirectoryName(FileName);
  if DirectoryName <> '' then
    EnsureDirectory(DirectoryName);

  TFile.AppendAllText(
    FileName,
    FormatDateTime('hh:nn:ss', Now) + '  ' + Text + sLineBreak,
    TEncoding.UTF8);
end;

function ChoosePreferredTerminalExecutable(const CmderPath, WindowsTerminalPath: string): string;
begin
  if FileExists(CmderPath) then
    Exit(CmderPath);
  if WindowsTerminalPath <> '' then
    Exit(WindowsTerminalPath);
  Result := 'cmd.exe';
end;

constructor TUniWampRuntime.Create(const Paths: TAppPaths; Config: TUniWampConfig);
begin
  inherited Create;
  FPaths := Paths;
  FConfig := Config;
end;

function TUniWampRuntime.ApacheExe: string;
begin
  Result := TPath.Combine(FPaths.ApacheBinDir, 'httpd.exe');
end;

function TUniWampRuntime.ApacheRuntimePid: Cardinal;
var
  PidText: string;
  ParsedPid: UInt64;
begin
  Result := 0;
  if not FileExists(TPath.Combine(FPaths.LogsDir, 'httpd.pid')) then
    Exit;

  PidText := Trim(TFile.ReadAllText(TPath.Combine(FPaths.LogsDir, 'httpd.pid'), TEncoding.UTF8));
  if not TryStrToUInt64(PidText, ParsedPid) then
    Exit;
  if ParsedPid > High(Cardinal) then
    Result := 0
  else
    Result := Cardinal(ParsedPid);
end;

function TUniWampRuntime.ApacheIsRunning: Boolean;
begin
  Result := (ApacheRuntimePid <> 0) and TProcessManager.IsRunning(ApacheRuntimePid);
  if not Result and (FConfig.ApachePid <> 0) and not TProcessManager.IsRunning(FConfig.ApachePid) then
  begin
    FConfig.ApachePid := 0;
    FConfig.ApacheRunning := False;
  end;
end;

function TUniWampRuntime.ApacheProcessId: Cardinal;
begin
  Result := ApacheRuntimePid;
end;

function TUniWampRuntime.MariaDbExe: string;
begin
  Result := TPath.Combine(FPaths.MariaDbBinDir, 'mariadbd.exe');
end;

function TUniWampRuntime.MariaDbInstallDbExe: string;
begin
  Result := TPath.Combine(FPaths.MariaDbBinDir, 'mariadb-install-db.exe');
  if not FileExists(Result) then
    Result := TPath.Combine(FPaths.MariaDbBinDir, 'mysql_install_db.exe');
end;

function TUniWampRuntime.MariaDbSystemDatabaseReady(const MysqlDir: string): Boolean;
const
  RequiredSystemFiles: array[0..5] of string = (
    'db.frm',
    'db.MAD',
    'db.MAI',
    'user.frm',
    'servers.frm',
    'global_priv.frm'
  );
var
  I: Integer;
begin
  Result := DirectoryExists(MysqlDir);
  if not Result then
    Exit;

  for I := Low(RequiredSystemFiles) to High(RequiredSystemFiles) do
    if not FileExists(TPath.Combine(MysqlDir, RequiredSystemFiles[I])) then
      Exit(False);
end;

function TUniWampRuntime.MariaDbIsRunning: Boolean;
begin
  Result := (FConfig.MariaDbPid <> 0) and TProcessManager.IsRunning(FConfig.MariaDbPid);
  if not Result and (FConfig.MariaDbPid <> 0) and not TProcessManager.IsRunning(FConfig.MariaDbPid) then
  begin
    FConfig.MariaDbPid := 0;
    FConfig.MariaDbRunning := False;
  end;
end;

function TUniWampRuntime.HostsFilePath: string;
var
  SystemRoot: string;
  ConfiguredHostsFile: string;
begin
  ConfiguredHostsFile := GetEnvironmentVariable('UNIWAMP_HOSTS_FILE');
  if Trim(ConfiguredHostsFile) <> '' then
    Exit(ConfiguredHostsFile);

  SystemRoot := GetEnvironmentVariable('SystemRoot');
  if SystemRoot = '' then
    SystemRoot := 'C:\Windows';
  Result := TPath.Combine(SystemRoot, 'System32\drivers\etc\hosts');
end;

procedure TUniWampRuntime.EnsureVHostStarterPage(const ServerName, DocumentRoot: string);
var
  IndexFile: string;
  Html: TStringList;
begin
  IndexFile := TPath.Combine(DocumentRoot, 'index.html');
  if FileExists(IndexFile) then
    Exit;

  Html := TStringList.Create;
  try
    Html.Add('<!DOCTYPE html>');
    Html.Add('<html lang="en">');
    Html.Add('<head>');
    Html.Add('  <meta charset="utf-8">');
    Html.Add('  <meta name="viewport" content="width=device-width, initial-scale=1">');
    Html.Add('  <title>' + ServerName + '</title>');
    Html.Add('  <style>');
    Html.Add('    :root {');
    Html.Add('      --ink: #132238;');
    Html.Add('      --muted: #5b6b7c;');
    Html.Add('      --line: #d7e0ea;');
    Html.Add('      --card: #ffffff;');
    Html.Add('      --accent: #0f7b6c;');
    Html.Add('      --accent-soft: #dff7f2;');
    Html.Add('      --bg: linear-gradient(135deg, #edf6ff 0%, #f5fbf7 100%);');
    Html.Add('    }');
    Html.Add('    * { box-sizing: border-box; }');
    Html.Add('    body {');
    Html.Add('      margin: 0;');
    Html.Add('      min-height: 100vh;');
    Html.Add('      font-family: "Segoe UI", Arial, sans-serif;');
    Html.Add('      background: var(--bg);');
    Html.Add('      color: var(--ink);');
    Html.Add('    }');
    Html.Add('    main {');
    Html.Add('      width: min(760px, calc(100vw - 32px));');
    Html.Add('      margin: 10vh auto;');
    Html.Add('      padding: 36px;');
    Html.Add('      border-radius: 18px;');
    Html.Add('      background: var(--card);');
    Html.Add('      border: 1px solid var(--line);');
    Html.Add('      box-shadow: 0 20px 50px rgba(18, 38, 63, 0.10);');
    Html.Add('    }');
    Html.Add('    .tag {');
    Html.Add('      display: inline-block;');
    Html.Add('      margin-bottom: 14px;');
    Html.Add('      padding: 6px 10px;');
    Html.Add('      border-radius: 999px;');
    Html.Add('      background: var(--accent-soft);');
    Html.Add('      color: var(--accent);');
    Html.Add('      font-size: 12px;');
    Html.Add('      font-weight: 700;');
    Html.Add('      letter-spacing: 0.08em;');
    Html.Add('      text-transform: uppercase;');
    Html.Add('    }');
    Html.Add('    h1 { margin: 0 0 12px; font-size: 38px; line-height: 1.1; }');
    Html.Add('    p { margin: 0 0 12px; color: var(--muted); line-height: 1.65; }');
    Html.Add('    .meta { margin-top: 24px; display: grid; gap: 12px; }');
    Html.Add('    .row { padding: 14px 16px; border: 1px solid var(--line); border-radius: 12px; background: #fbfdff; }');
    Html.Add('    .label { display: block; margin-bottom: 6px; font-size: 12px; font-weight: 700; color: var(--muted); text-transform: uppercase; letter-spacing: 0.06em; }');
    Html.Add('    code { font-family: Consolas, "Courier New", monospace; font-size: 14px; }');
    Html.Add('  </style>');
    Html.Add('</head>');
    Html.Add('<body>');
    Html.Add('  <main>');
    Html.Add('    <span class="tag">UniWamp Virtual Host</span>');
    Html.Add('    <h1>' + ServerName + ' is ready</h1>');
    Html.Add('    <p>This starter page was generated automatically when the virtual host was created.</p>');
    Html.Add('    <p>Replace <code>index.html</code> with your app entry point when you are ready.</p>');
    Html.Add('    <section class="meta">');
    Html.Add('      <div class="row">');
    Html.Add('        <span class="label">Document Root</span>');
    Html.Add('        <code>' + DocumentRoot + '</code>');
    Html.Add('      </div>');
    Html.Add('      <div class="row">');
    Html.Add('        <span class="label">Expected URL</span>');
    Html.Add('        <code>http://' + ServerName + ':' + FConfig.HttpPort.ToString + '/</code>');
    Html.Add('      </div>');
    Html.Add('    </section>');
    Html.Add('  </main>');
    Html.Add('</body>');
    Html.Add('</html>');
    Html.SaveToFile(IndexFile, TEncoding.UTF8);
  finally
    Html.Free;
  end;
end;

function TUniWampRuntime.MysqlAdminExe: string;
begin
  Result := TPath.Combine(FPaths.MariaDbBinDir, 'mysqladmin.exe');
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

function TUniWampRuntime.ComputeFileSha256Hex(const FileName: string): string;
var
  Stream: TFileStream;
begin
  Result := '';
  if not FileExists(FileName) then
    Exit;
  Stream := TFileStream.Create(FileName, fmOpenRead or fmShareDenyWrite);
  try
    Result := THashSHA2.GetHashString(Stream);
  finally
    Stream.Free;
  end;
end;

function TUniWampRuntime.ValidatePackageSha256(const PackageFileName, ExpectedSha256: string; out ErrorMessage: string): Boolean;
var
  ActualSha256: string;
begin
  Result := False;
  ErrorMessage := '';
  if Trim(PackageFileName) = '' then
  begin
    ErrorMessage := 'Package file name is required.';
    Exit;
  end;
  if not FileExists(PackageFileName) then
  begin
    ErrorMessage := 'Package file not found: ' + PackageFileName;
    Exit;
  end;
  ActualSha256 := ComputeFileSha256Hex(PackageFileName);
  if ActualSha256 = '' then
  begin
    ErrorMessage := 'Package hash could not be calculated.';
    Exit;
  end;
  if not SameText(ActualSha256, Trim(ExpectedSha256)) then
  begin
    ErrorMessage := 'Package hash mismatch.';
    Exit;
  end;
  Result := True;
end;

function TUniWampRuntime.ValidateRuntimeZipArchive(const ZipFileName: string; out ErrorMessage: string): Boolean;
var
  Zip: TZipFile;
begin
  Result := False;
  ErrorMessage := '';
  if not FileExists(ZipFileName) then
  begin
    ErrorMessage := 'Runtime archive not found: ' + ZipFileName;
    Exit;
  end;
  if not SameText(TPath.GetExtension(ZipFileName), '.zip') then
  begin
    ErrorMessage := 'Runtime archive must be a ZIP file.';
    Exit;
  end;

  Zip := TZipFile.Create;
  try
    try
      Zip.Open(ZipFileName, zmRead);
      if Zip.FileCount = 0 then
      begin
        ErrorMessage := 'Runtime archive is empty.';
        Exit;
      end;
      Result := True;
    except
      on E: Exception do
        ErrorMessage := 'Runtime archive validation failed: ' + E.Message;
    end;
  finally
    Zip.Free;
  end;
end;

function TUniWampRuntime.ValidateUpdateManifest(const ManifestFileName: string; out PackageFileName, ExpectedSha256, PackageVersion: string; out ErrorMessage: string): Boolean;
var
  JsonValue: TJSONValue;
  JsonObject: TJSONObject;
begin
  Result := False;
  ErrorMessage := '';
  PackageFileName := '';
  ExpectedSha256 := '';
  PackageVersion := '';
  if not FileExists(ManifestFileName) then
  begin
    ErrorMessage := 'Update manifest not found: ' + ManifestFileName;
    Exit;
  end;
  JsonValue := TJSONObject.ParseJSONValue(TFile.ReadAllText(ManifestFileName, TEncoding.UTF8));
  try
    if not (JsonValue is TJSONObject) then
    begin
      ErrorMessage := 'Update manifest must be a JSON object.';
      Exit;
    end;
    JsonObject := TJSONObject(JsonValue);
    PackageFileName := JsonObject.GetValue<string>('packageFileName', '');
    ExpectedSha256 := JsonObject.GetValue<string>('expectedSha256', '');
    PackageVersion := JsonObject.GetValue<string>('packageVersion', '');
    if Trim(PackageFileName) = '' then
    begin
      ErrorMessage := 'Update manifest is missing packageFileName.';
      Exit;
    end;
    if Trim(ExpectedSha256) = '' then
    begin
      ErrorMessage := 'Update manifest is missing expectedSha256.';
      Exit;
    end;
    if Trim(PackageVersion) = '' then
    begin
      ErrorMessage := 'Update manifest is missing packageVersion.';
      Exit;
    end;
    Result := True;
  finally
    JsonValue.Free;
  end;
end;

function TUniWampRuntime.WriteUpdateStagingMetadata(const StagingDir, PackageFileName, ExpectedSha256, PackageVersion: string; out MetadataFileName, ErrorMessage: string): Boolean;
var
  JsonObject: TJSONObject;
begin
  Result := False;
  ErrorMessage := '';
  MetadataFileName := '';
  if not TDirectory.Exists(StagingDir) then
  begin
    ErrorMessage := 'Staging directory not found: ' + StagingDir;
    Exit;
  end;
  MetadataFileName := TPath.Combine(StagingDir, 'update-staging.json');
  JsonObject := TJSONObject.Create;
  try
    try
      JsonObject.AddPair('packageFileName', PackageFileName);
      JsonObject.AddPair('expectedSha256', ExpectedSha256);
      JsonObject.AddPair('packageVersion', PackageVersion);
      JsonObject.AddPair('stagingDir', StagingDir);
      TFile.WriteAllText(MetadataFileName, JsonObject.Format, TEncoding.UTF8);
      Result := True;
    except
      on E: Exception do
        ErrorMessage := 'Update staging metadata could not be written: ' + E.Message;
    end;
  finally
    JsonObject.Free;
  end;
end;

function TUniWampRuntime.CleanupUpdateWorkspace(const WorkspaceDir: string; out ErrorMessage: string): Boolean;
begin
  Result := False;
  ErrorMessage := '';
  if Trim(WorkspaceDir) = '' then
  begin
    ErrorMessage := 'Workspace directory is required.';
    Exit;
  end;
  if not TDirectory.Exists(WorkspaceDir) then
  begin
    Result := True;
    Exit;
  end;
  try
    TDirectory.Delete(WorkspaceDir, True);
    Result := True;
  except
    on E: Exception do
      ErrorMessage := 'Workspace cleanup failed: ' + E.Message;
  end;
end;

function TUniWampRuntime.ImportRuntimeZipArchive(const ZipFileName: string; out ErrorMessage: string): Boolean;
var
  Zip: TZipFile;
begin
  Result := False;
  ErrorMessage := '';
  if not ValidateRuntimeZipArchive(ZipFileName, ErrorMessage) then
    Exit;

  Zip := TZipFile.Create;
  try
    try
      Zip.Open(ZipFileName, zmRead);
      Zip.ExtractAll(FPaths.AppRoot);
      Result := True;
    except
      on E: Exception do
        ErrorMessage := 'Runtime archive import failed: ' + E.Message;
    end;
  finally
    Zip.Free;
  end;
end;

function TUniWampRuntime.LaunchComposerInWorkingDir(const WorkingDir: string): TRuntimeActionResult;
var
  ComposerExe: string;
  Buffer: array[0..MAX_PATH] of Char;
  BufferSize: DWORD;
  FilePart: PChar;
begin
  ComposerExe := '';
  FilePart := nil;
  BufferSize := SearchPath(nil, 'composer.exe', nil, Length(Buffer), Buffer, FilePart);
  if BufferSize > 0 then
    ComposerExe := Buffer;
  if ComposerExe = '' then
  begin
    Result.Success := False;
    Result.Message := 'Composer was not found on PATH.';
    Exit;
  end;
  Result.Success := ShellExecute(0, 'open', 'cmd.exe', PChar('/K "' + ComposerExe + '"'), PChar(WorkingDir), SW_SHOWNORMAL) > 32;
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
  GitExe := '';
  FilePart := nil;
  BufferSize := SearchPath(nil, 'git.exe', nil, Length(Buffer), Buffer, FilePart);
  if BufferSize > 0 then
    GitExe := Buffer;
  if GitExe = '' then
  begin
    Result.Success := False;
    Result.Message := 'Git was not found on PATH.';
    Exit;
  end;
  Result.Success := ShellExecute(0, 'open', 'cmd.exe', PChar('/K "' + GitExe + '" status'), PChar(WorkingDir), SW_SHOWNORMAL) > 32;
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
  Result.Success := ShellExecute(0, 'open', PChar(NodeExe), nil, PChar(WorkingDir), SW_SHOWNORMAL) > 32;
  if Result.Success then
    Result.Message := 'Node launched'
  else
    Result.Message := 'Failed to launch Node';
end;

function TUniWampRuntime.LaunchWpCliInWorkingDir(const WorkingDir: string): TRuntimeActionResult;
var
  WpExe: string;
  Buffer: array[0..MAX_PATH] of Char;
  BufferSize: DWORD;
  FilePart: PChar;
begin
  WpExe := '';
  FilePart := nil;
  BufferSize := SearchPath(nil, 'wp.exe', nil, Length(Buffer), Buffer, FilePart);
  if BufferSize > 0 then
    WpExe := Buffer;
  if WpExe = '' then
  begin
    Result.Success := False;
    Result.Message := 'WP-CLI was not found on PATH.';
    Exit;
  end;
  Result.Success := ShellExecute(0, 'open', 'cmd.exe', PChar('/K "' + WpExe + '" --info'), PChar(WorkingDir), SW_SHOWNORMAL) > 32;
  if Result.Success then
    Result.Message := 'WP-CLI launched'
  else
    Result.Message := 'Failed to launch WP-CLI';
end;

function TUniWampRuntime.LaunchNpmInWorkingDir(const WorkingDir: string): TRuntimeActionResult;
var
  NpmExe: string;
  Buffer: array[0..MAX_PATH] of Char;
  BufferSize: DWORD;
  FilePart: PChar;
begin
  NpmExe := '';
  FilePart := nil;
  BufferSize := SearchPath(nil, 'npm.cmd', nil, Length(Buffer), Buffer, FilePart);
  if BufferSize > 0 then
    NpmExe := Buffer;
  if NpmExe = '' then
  begin
    Result.Success := False;
    Result.Message := 'npm was not found on PATH.';
    Exit;
  end;
  Result.Success := ShellExecute(0, 'open', 'cmd.exe', PChar('/K "' + NpmExe + '"'), PChar(WorkingDir), SW_SHOWNORMAL) > 32;
  if Result.Success then
    Result.Message := 'npm launched'
  else
    Result.Message := 'Failed to launch npm';
end;

function TUniWampRuntime.LaunchYarnInWorkingDir(const WorkingDir: string): TRuntimeActionResult;
var
  YarnExe: string;
  Buffer: array[0..MAX_PATH] of Char;
  BufferSize: DWORD;
  FilePart: PChar;
begin
  YarnExe := '';
  FilePart := nil;
  BufferSize := SearchPath(nil, 'yarn.cmd', nil, Length(Buffer), Buffer, FilePart);
  if BufferSize > 0 then
    YarnExe := Buffer;
  if YarnExe = '' then
  begin
    Result.Success := False;
    Result.Message := 'yarn was not found on PATH.';
    Exit;
  end;
  Result.Success := ShellExecute(0, 'open', 'cmd.exe', PChar('/K "' + YarnExe + '"'), PChar(WorkingDir), SW_SHOWNORMAL) > 32;
  if Result.Success then
    Result.Message := 'yarn launched'
  else
    Result.Message := 'Failed to launch yarn';
end;

function TUniWampRuntime.LaunchPnpmInWorkingDir(const WorkingDir: string): TRuntimeActionResult;
var
  PnpmExe: string;
  Buffer: array[0..MAX_PATH] of Char;
  BufferSize: DWORD;
  FilePart: PChar;
begin
  PnpmExe := '';
  FilePart := nil;
  BufferSize := SearchPath(nil, 'pnpm.cmd', nil, Length(Buffer), Buffer, FilePart);
  if BufferSize > 0 then
    PnpmExe := Buffer;
  if PnpmExe = '' then
  begin
    Result.Success := False;
    Result.Message := 'pnpm was not found on PATH.';
    Exit;
  end;
  Result.Success := ShellExecute(0, 'open', 'cmd.exe', PChar('/K "' + PnpmExe + '"'), PChar(WorkingDir), SW_SHOWNORMAL) > 32;
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
  MailpitExe := '';
  FilePart := nil;
  BufferSize := SearchPath(nil, 'mailpit.exe', nil, Length(Buffer), Buffer, FilePart);
  if BufferSize > 0 then
    MailpitExe := Buffer;
  if MailpitExe = '' then
  begin
    Result.Success := False;
    Result.Message := 'Mailpit was not found on PATH.';
    Exit;
  end;
  Result.Success := ShellExecute(0, 'open', PChar(MailpitExe), nil, PChar(FPaths.AppRoot), SW_SHOWNORMAL) > 32;
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
  RedisExe := '';
  FilePart := nil;
  BufferSize := SearchPath(nil, 'redis-server.exe', nil, Length(Buffer), Buffer, FilePart);
  if BufferSize > 0 then
    RedisExe := Buffer;
  if RedisExe = '' then
  begin
    Result.Success := False;
    Result.Message := 'Redis was not found on PATH.';
    Exit;
  end;
  Result.Success := ShellExecute(0, 'open', PChar(RedisExe), nil, PChar(FPaths.AppRoot), SW_SHOWNORMAL) > 32;
  if Result.Success then
    Result.Message := 'Redis launched'
  else
    Result.Message := 'Failed to launch Redis';
end;

function TUniWampRuntime.LaunchMemcached: TRuntimeActionResult;
var
  MemcachedExe: string;
  Buffer: array[0..MAX_PATH] of Char;
  BufferSize: DWORD;
  FilePart: PChar;
begin
  MemcachedExe := '';
  FilePart := nil;
  BufferSize := SearchPath(nil, 'memcached.exe', nil, Length(Buffer), Buffer, FilePart);
  if BufferSize > 0 then
    MemcachedExe := Buffer;
  if MemcachedExe = '' then
  begin
    Result.Success := False;
    Result.Message := 'Memcached was not found on PATH.';
    Exit;
  end;
  Result.Success := ShellExecute(0, 'open', PChar(MemcachedExe), nil, PChar(FPaths.AppRoot), SW_SHOWNORMAL) > 32;
  if Result.Success then
    Result.Message := 'Memcached launched'
  else
    Result.Message := 'Failed to launch Memcached';
end;

function TUniWampRuntime.LaunchEditor: TRuntimeActionResult;
begin
  Result := LaunchTextEditor(FPaths.AppRoot);
end;

function TUniWampRuntime.PrepareUpdateStagingArea(const PackageName: string; out StagingDir: string; out ErrorMessage: string): Boolean;
var
  CleanName: string;
begin
  Result := False;
  ErrorMessage := '';
  StagingDir := '';
  CleanName := Trim(PackageName);
  if CleanName = '' then
  begin
    ErrorMessage := 'Update package name is required.';
    Exit;
  end;
  CleanName := StringReplace(CleanName, '\', '_', [rfReplaceAll]);
  CleanName := StringReplace(CleanName, '/', '_', [rfReplaceAll]);
  CleanName := StringReplace(CleanName, ':', '_', [rfReplaceAll]);
  StagingDir := TPath.Combine(FPaths.UpdatesDir, CleanName);
  try
    EnsureDirectory(StagingDir);
    Result := True;
  except
    on E: Exception do
      ErrorMessage := 'Update staging area could not be prepared: ' + E.Message;
  end;
end;

function TUniWampRuntime.CreateUpdateRollbackSnapshot(const StagingDir, SnapshotName: string; out SnapshotDir: string; out ErrorMessage: string): Boolean;
var
  CleanName: string;
begin
  Result := False;
  ErrorMessage := '';
  SnapshotDir := '';
  if not TDirectory.Exists(StagingDir) then
  begin
    ErrorMessage := 'Staging directory not found: ' + StagingDir;
    Exit;
  end;
  CleanName := Trim(SnapshotName);
  if CleanName = '' then
  begin
    ErrorMessage := 'Snapshot name is required.';
    Exit;
  end;
  CleanName := StringReplace(CleanName, '\', '_', [rfReplaceAll]);
  CleanName := StringReplace(CleanName, '/', '_', [rfReplaceAll]);
  CleanName := StringReplace(CleanName, ':', '_', [rfReplaceAll]);
  SnapshotDir := TPath.Combine(FPaths.UpdatesDir, 'rollback\' + CleanName);
  try
    if TDirectory.Exists(SnapshotDir) then
      TDirectory.Delete(SnapshotDir, True);
    TDirectory.CreateDirectory(TPath.GetDirectoryName(SnapshotDir));
    TDirectory.Copy(StagingDir, SnapshotDir);
    Result := True;
  except
    on E: Exception do
      ErrorMessage := 'Rollback snapshot could not be created: ' + E.Message;
  end;
end;

function TUniWampRuntime.RollbackUpdateStagingArea(const SnapshotDir, RestoreDir: string; out ErrorMessage: string): Boolean;
begin
  Result := False;
  ErrorMessage := '';
  if not TDirectory.Exists(SnapshotDir) then
  begin
    ErrorMessage := 'Rollback snapshot not found: ' + SnapshotDir;
    Exit;
  end;
  try
    if TDirectory.Exists(RestoreDir) then
      TDirectory.Delete(RestoreDir, True);
    TDirectory.CreateDirectory(TPath.GetDirectoryName(RestoreDir));
    TDirectory.Copy(SnapshotDir, RestoreDir);
    Result := True;
  except
    on E: Exception do
      ErrorMessage := 'Rollback restore failed: ' + E.Message;
  end;
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

function TUniWampRuntime.RenderApacheModuleLines: string;
var
  Lines: TStringList;
  ModuleFileName: string;
  ModuleSymbol: string;
  ModulePath: string;
begin
  Lines := TStringList.Create;
  try
    for ModuleFileName in FConfig.ApacheModules do
    begin
      ModulePath := TPath.Combine(ApacheModuleDir, ModuleFileName);
      if not FileExists(ModulePath) then
        Continue;
      ModuleSymbol := TPath.GetFileNameWithoutExtension(ModuleFileName);
      if StartsText('mod_', ModuleSymbol) then
        Delete(ModuleSymbol, 1, 4);
      Lines.Add('LoadModule ' + ModuleSymbol + '_module "' + ModulePath + '"');
    end;
    Result := TrimRight(Lines.Text);
  finally
    Lines.Free;
  end;
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

function TUniWampRuntime.RenderPhpExtensionLines: string;
var
  Block: TStringList;
  Item: string;
  ExtensionName: string;
  ExtensionPath: string;
begin
  Block := TStringList.Create;
  try
    for Item in FConfig.PhpExtensions do
    begin
      ExtensionName := Trim(Item);
      if ExtensionName = '' then
        Continue;

      ExtensionPath := TPath.Combine(SelectedPhpDir, ExtensionName);
      if not FileExists(ExtensionPath) then
        Continue;

      if SameText(ExtensionName, 'php_opcache.dll') then
        Block.Add('zend_extension=' + ExtensionName)
      else
        Block.Add('extension=' + ExtensionName);
    end;
    Result := Block.Text;
  finally
    Block.Free;
  end;
end;

function TUniWampRuntime.RenderManagedHostsBlock: string;
var
  Hosts: TStringList;
  ManagedHosts: TStringList;
  Entry: TVHostEntry;
  ManagedHostEntry: string;
  ManagedHostLine: string;
begin
  Hosts := TStringList.Create;
  ManagedHosts := TStringList.Create;
  try
    for Entry in FConfig.VHosts do
      if Trim(Entry.ServerName) <> '' then
      begin
        ManagedHostLine := '127.0.0.1 ' + Trim(Entry.ServerName);
        if ManagedHosts.IndexOf(ManagedHostLine) < 0 then
          ManagedHosts.Add(ManagedHostLine);
      end;
    ManagedHosts.Sort;

    Hosts.Add(ManagedHostsBeginMarker);
    Hosts.Add('127.0.0.1 ' + FConfig.HostName);
    for ManagedHostEntry in ManagedHosts do
      Hosts.Add(ManagedHostEntry);
    Hosts.Add(ManagedHostsEndMarker);
    Result := Hosts.Text;
  finally
    ManagedHosts.Free;
    Hosts.Free;
  end;
end;

function TUniWampRuntime.SyncHostsFile(out ErrorMessage: string): Boolean;
var
  HostsPath: string;
  BackupPath: string;
  HostsText: string;
  StartPos: Integer;
  EndPos: Integer;
  ManagedBlock: string;
  function IsAccessDenied(const E: Exception): Boolean;
  begin
    Result := (E is EOSError) and (EOSError(E).ErrorCode = ERROR_ACCESS_DENIED);
  end;
begin
  Result := False;
  ErrorMessage := '';
  HostsPath := HostsFilePath;
  BackupPath := HostsPath + '.bak';
  ManagedBlock := RenderManagedHostsBlock;

  try
    if FileExists(HostsPath) then
    begin
      TFile.Copy(HostsPath, BackupPath, True);
      HostsText := TFile.ReadAllText(HostsPath, TEncoding.ASCII)
    end
    else
      HostsText := '';

    StartPos := Pos(ManagedHostsBeginMarker, HostsText);
    if StartPos > 0 then
    begin
      EndPos := PosEx(ManagedHostsEndMarker, HostsText, StartPos);
      if (EndPos > 0) and (EndPos >= StartPos) then
      begin
        EndPos := EndPos + Length(ManagedHostsEndMarker);
        while (EndPos <= Length(HostsText)) and CharInSet(HostsText[EndPos], [#13, #10]) do
          Inc(EndPos);
        Delete(HostsText, StartPos, EndPos - StartPos);
      end;
    end;

    HostsText := TrimRight(HostsText);
    if HostsText <> '' then
      HostsText := HostsText + sLineBreak + sLineBreak;
    HostsText := HostsText + ManagedBlock;
    TFile.WriteAllText(HostsPath, HostsText, TEncoding.ASCII);
    FConfig.LastHostsSyncStatus := 'Hosts synced';
    Result := True;
  except
    on E: Exception do
    begin
      if IsAccessDenied(E) then
        FConfig.LastHostsSyncStatus := 'Hosts update requires Administrator'
      else
        FConfig.LastHostsSyncStatus := 'Hosts update failed';
      ErrorMessage := 'Hosts file update failed: ' + E.Message;
    end;
  end;
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

function TUniWampRuntime.EnsureDefaultSslCertificate(out ErrorMessage: string): Boolean;
var
  CertFile: string;
  KeyFile: string;
  ResultInfo: TRuntimeActionResult;
begin
  Result := True;
  ErrorMessage := '';

  CertFile := TPath.Combine(FPaths.SslDir, 'server.crt');
  KeyFile := TPath.Combine(FPaths.SslDir, 'server.key');
  if FileExists(CertFile) and FileExists(KeyFile) then
    Exit;

  ResultInfo := GenerateSslCertificateFor(FConfig.HostName, CertFile, KeyFile);
  Result := ResultInfo.Success;
  if not Result then
    ErrorMessage := ResultInfo.Message;
end;

function TUniWampRuntime.DescribePortOwner(const Port: Integer): string;
var
  SystemRoot: string;
  NetstatOutput: string;
  HelperError: string;
  Lines: TStringList;
  Tokens: TStringList;
  Line: string;
  PidText: string;
  OwnerPid: Cardinal;
  TasklistOutput: string;
  CsvLines: TStringList;
  CsvFields: TStringList;
  ImageName: string;
begin
  Result := '';
  ImageName := '';
  SystemRoot := GetEnvironmentVariable('SystemRoot');
  if SystemRoot = '' then
    SystemRoot := 'C:\Windows';
  SystemRoot := TPath.Combine(SystemRoot, 'System32');

  if not TProcessManager.RunAndCaptureOutput(
    TPath.Combine(SystemRoot, 'netstat.exe'),
    '-ano -p tcp',
    SystemRoot,
    NetstatOutput) then
  begin
    HelperError := Trim(NetstatOutput);
    if HelperError <> '' then
      Result := 'port scan unavailable: ' + HelperError;
    Exit;
  end;

  Lines := TStringList.Create;
  Tokens := TStringList.Create;
  CsvLines := TStringList.Create;
  CsvFields := TStringList.Create;
  try
    Lines.Text := NetstatOutput;
    for Line in Lines do
    begin
      if Pos(':' + Port.ToString, Line) = 0 then
        Continue;
      if Pos('LISTENING', UpperCase(Line)) = 0 then
        Continue;

      Tokens.Clear;
      ExtractStrings([' ', #9], [], PChar(Trim(Line)), Tokens);
      if Tokens.Count = 0 then
        Continue;

      PidText := Tokens[Tokens.Count - 1];
      if not TryStrToUInt(PidText, OwnerPid) then
        Continue;
      if OwnerPid = 0 then
        Continue;

      if TProcessManager.RunAndCaptureOutput(
        TPath.Combine(SystemRoot, 'tasklist.exe'),
        Format('/FI "PID eq %d" /FO CSV /NH', [OwnerPid]),
        SystemRoot,
        TasklistOutput) then
      begin
        CsvLines.Text := Trim(TasklistOutput);
        if CsvLines.Count > 0 then
        begin
          CsvFields.StrictDelimiter := True;
          CsvFields.Delimiter := ',';
          CsvFields.QuoteChar := '"';
          CsvFields.DelimitedText := CsvLines[0];
          if CsvFields.Count > 0 then
            ImageName := CsvFields[0];
        end;
      end;
      if (ImageName = '') and (Trim(TasklistOutput) <> '') then
        ImageName := 'tasklist unavailable: ' + Trim(TasklistOutput);

      if ImageName <> '' then
        Result := Format('%s (PID %d)', [ImageName, OwnerPid])
      else
        Result := Format('PID %d', [OwnerPid]);
      Exit;
    end;
  finally
    CsvFields.Free;
    CsvLines.Free;
    Tokens.Free;
    Lines.Free;
  end;
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
    HttpOwner := DescribePortOwner(FConfig.HttpPort);
    HttpsOwner := DescribePortOwner(FConfig.HttpsPort);
    DbOwner := DescribePortOwner(FConfig.DatabasePort);

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
    if FConfig.MariaDbRootPassword <> '' then
      Lines.Add('MariaDB root password: [redacted]')
    else
      Lines.Add('MariaDB root password: (not set)');
    Lines.Add('Apache config: ' + FPaths.ApacheHttpdConfFile);
    Lines.Add('Apache SSL config: ' + FPaths.ApacheSslConfFile);
    Lines.Add('Apache vhosts config: ' + FPaths.ApacheVHostsConfFile);
    Lines.Add('MariaDB config: ' + FPaths.MariaDbIniFile);
    Lines.Add('PHP config: ' + FPaths.ActivePhpIniFile);
    Lines.Add('Hosts file: ' + HostsFilePath);
    Result := Lines.Text;
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
begin
  Versions := DetectPhpVersions;
  if Length(Versions) > 0 then
  begin
    FConfig.ReplacePhpVersions(Versions);
    if IndexText(FConfig.SelectedPhpVersion, Versions) < 0 then
      FConfig.SelectedPhpVersion := Versions[0];
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
begin
  Versions := DetectNodeVersions;
  if Length(Versions) > 0 then
  begin
    FConfig.ReplaceNodeVersions(Versions);
    if IndexText(FConfig.SelectedNodeVersion, Versions) < 0 then
      FConfig.SelectedNodeVersion := Versions[0];
  end;
end;

function TUniWampRuntime.ValidateApachePorts(out ErrorMessage: string): Boolean;
var
  ApacheRunningNow: Boolean;
  OwnerInfo: string;
begin
  Result := True;
  ErrorMessage := '';
  ApacheRunningNow := ApacheIsRunning or FConfig.ApacheRunning;
  if not IsTcpPortAvailable(FConfig.HttpPort) and not ApacheRunningNow then
  begin
    Result := False;
    OwnerInfo := DescribePortOwner(FConfig.HttpPort);
    if OwnerInfo <> '' then
      ErrorMessage := Format('HTTP port %d is already in use by %s.', [FConfig.HttpPort, OwnerInfo])
    else
      ErrorMessage := Format('HTTP port %d is already in use.', [FConfig.HttpPort]);
    Exit;
  end;
  if FConfig.EnableSsl and not IsTcpPortAvailable(FConfig.HttpsPort) and not ApacheRunningNow then
  begin
    Result := False;
    OwnerInfo := DescribePortOwner(FConfig.HttpsPort);
    if OwnerInfo <> '' then
      ErrorMessage := Format('HTTPS port %d is already in use by %s.', [FConfig.HttpsPort, OwnerInfo])
    else
      ErrorMessage := Format('HTTPS port %d is already in use.', [FConfig.HttpsPort]);
    Exit;
  end;
end;

function TUniWampRuntime.ValidateApacheConfiguration(out ErrorMessage: string): Boolean;
var
  Output: string;
begin
  Result := False;
  ErrorMessage := '';
  if not FileExists(ApacheExe) then
  begin
    ErrorMessage := 'Apache executable not found: ' + ApacheExe;
    Exit;
  end;

  if TProcessManager.RunAndCaptureOutput(
    ApacheExe,
    '-t -f "' + FPaths.ApacheHttpdConfFile + '"',
    FPaths.ApacheBinDir,
    Output) then
  begin
    Result := True;
    Exit;
  end;

  Output := Trim(Output);
  if Output <> '' then
    ErrorMessage := Output
  else
    ErrorMessage := 'Apache configuration validation failed.';
end;

function TUniWampRuntime.WaitForApacheStartup(const ProcessId: Cardinal; out ErrorMessage: string): Boolean;
const
  StartupTimeoutMs = 30000;
  PollIntervalMs = 250;
var
  StartTick: UInt64;
begin
  Result := False;
  ErrorMessage := '';
  StartTick := GetTickCount64;
  repeat
    if not TProcessManager.IsRunning(ProcessId) then
    begin
      ErrorMessage := 'Apache exited before it finished starting.';
      Exit;
    end;
    if not IsTcpPortAvailable(FConfig.HttpPort) and
      ((not FConfig.EnableSsl) or (not IsTcpPortAvailable(FConfig.HttpsPort))) then
    begin
      Result := True;
      Exit;
    end;
    Sleep(PollIntervalMs);
  until (GetTickCount64 - StartTick) >= StartupTimeoutMs;

  if FConfig.EnableSsl then
    ErrorMessage := Format(
      'Apache did not start listening on ports %d and %d within %d seconds.',
      [FConfig.HttpPort, FConfig.HttpsPort, StartupTimeoutMs div 1000])
  else
    ErrorMessage := Format(
      'Apache did not start listening on port %d within %d seconds.',
      [FConfig.HttpPort, StartupTimeoutMs div 1000]);
end;

function TUniWampRuntime.ValidateMariaDbPorts(out ErrorMessage: string): Boolean;
var
  MariaDbRunningNow: Boolean;
  OwnerInfo: string;
begin
  Result := True;
  ErrorMessage := '';
  MariaDbRunningNow := MariaDbIsRunning or FConfig.MariaDbRunning;
  if not IsTcpPortAvailable(FConfig.DatabasePort) and not MariaDbRunningNow then
  begin
    Result := False;
    OwnerInfo := DescribePortOwner(FConfig.DatabasePort);
    if OwnerInfo <> '' then
      ErrorMessage := Format('Database port %d is already in use by %s.', [FConfig.DatabasePort, OwnerInfo])
    else
      ErrorMessage := Format('Database port %d is already in use.', [FConfig.DatabasePort]);
    Exit;
  end;
end;

procedure TUniWampRuntime.GenerateApacheConfig;
var
  Values: TDictionary<string, string>;
begin
  Values := TDictionary<string, string>.Create;
  try
    Values.Add('APACHE_DIR', FPaths.ApacheDir);
    Values.Add('HTTP_PORT', FConfig.HttpPort.ToString);
    Values.Add('HOST_NAME', FConfig.HostName);
    Values.Add('DOCUMENT_ROOT', FConfig.DocumentRoot);
    Values.Add('DASHBOARD_DIR', FPaths.DashboardDir);
    Values.Add('ADMINER_DIR', FPaths.AdminerDir);
    Values.Add('APACHE_MODULE_LINES', RenderApacheModuleLines);
    Values.Add('PHP_MODULE', ApacheModuleForSelectedPhp);
    Values.Add('GENERATED_DIR', FPaths.GeneratedConfigDir);
    Values.Add('LOGS_DIR', FPaths.LogsDir);
    if FConfig.EnableSsl then
      Values.Add('SSL_INCLUDE', 'IncludeOptional "' + FPaths.ApacheSslConfFile + '"')
    else
      Values.Add('SSL_INCLUDE', '');
    TTemplateRenderer.RenderToFile(FPaths.ApacheTemplateFile, FPaths.ApacheHttpdConfFile, Values);

    if FConfig.EnableSsl then
    begin
      Values.Clear;
      Values.Add('HTTPS_PORT', FConfig.HttpsPort.ToString);
      Values.Add('DOCUMENT_ROOT', FConfig.DocumentRoot);
      Values.Add('HOST_NAME', FConfig.HostName);
      Values.Add('SSL_CERT_FILE', TPath.Combine(FPaths.SslDir, 'server.crt'));
      Values.Add('SSL_KEY_FILE', TPath.Combine(FPaths.SslDir, 'server.key'));
      Values.Add('LOGS_DIR', FPaths.LogsDir);
      TTemplateRenderer.RenderToFile(FPaths.ApacheSslTemplateFile, FPaths.ApacheSslConfFile, Values);
    end;
  finally
    Values.Free;
  end;
end;

procedure TUniWampRuntime.GenerateMariaDbConfig;
var
  Values: TDictionary<string, string>;
  MariaDbDir: string;
  MariaDbDataDir: string;
  TmpDir: string;
  LogsDir: string;
begin
  EnsureDirectory(TPath.Combine(FPaths.MariaDbDir, 'data'));
  MariaDbDir := StringReplace(FPaths.MariaDbDir, '\', '/', [rfReplaceAll]);
  MariaDbDataDir := StringReplace(TPath.Combine(FPaths.MariaDbDir, 'data'), '\', '/', [rfReplaceAll]);
  TmpDir := StringReplace(FPaths.TmpDir, '\', '/', [rfReplaceAll]);
  LogsDir := StringReplace(FPaths.LogsDir, '\', '/', [rfReplaceAll]);
  Values := TDictionary<string, string>.Create;
  try
    Values.Add('DB_PORT', FConfig.DatabasePort.ToString);
    Values.Add('MARIADB_DIR', MariaDbDir);
    Values.Add('MARIADB_DATA_DIR', MariaDbDataDir);
    Values.Add('TMP_DIR', TmpDir);
    Values.Add('LOGS_DIR', LogsDir);
    TTemplateRenderer.RenderToFile(FPaths.MariaDbTemplateFile, FPaths.MariaDbIniFile, Values);
  finally
    Values.Free;
  end;
end;

function TUniWampRuntime.EnsureMariaDbInitialized(out ErrorMessage: string): Boolean;
const
  MariaDbInitTimeoutMs = 60000;
var
  DataDir: string;
  MysqlDir: string;
  DataSubDirs: TArray<string>;
  DataFiles: TArray<string>;
  BackupDir: string;
  HelperExe: string;
  ServerExe: string;
  BootstrapOutput: string;
  BootstrapCommand: string;
begin
  Result := False;
  ErrorMessage := '';
  DataDir := TPath.Combine(FPaths.MariaDbDir, 'data');
  MysqlDir := TPath.Combine(DataDir, 'mysql');

  if MariaDbSystemDatabaseReady(MysqlDir) then
  begin
    Result := True;
    Exit;
  end;

  HelperExe := MariaDbInstallDbExe;
  if not FileExists(HelperExe) then
  begin
    ErrorMessage := 'MariaDB initializer not found: ' + HelperExe;
    Exit;
  end;

  if DirectoryExists(DataDir) then
  begin
    DataSubDirs := TDirectory.GetDirectories(DataDir);
    DataFiles := TDirectory.GetFiles(DataDir);
    if (Length(DataSubDirs) > 0) or (Length(DataFiles) > 0) or DirectoryExists(MysqlDir) then
    begin
      BackupDir := TPath.Combine(TPath.GetDirectoryName(DataDir),
        'data.bak-' + FormatDateTime('yyyymmdd-hhnnss', Now));
      AppendTextToLogFile(TPath.Combine(FPaths.LogsDir, 'mariadb-error.log'),
        'MariaDB data directory is not clean. Moving "' + DataDir + '" to "' + BackupDir + '".');
      try
        TDirectory.Move(DataDir, BackupDir);
      except
        on E: Exception do
        begin
          ErrorMessage := 'MariaDB data directory could not be backed up: ' + E.Message;
          Exit;
        end;
      end;
    end;
    ForceDirectories(DataDir);
  end
  else
    ForceDirectories(DataDir);

  if not DirectoryExists(DataDir) then
  begin
    ErrorMessage := 'MariaDB data directory could not be created.';
    Exit;
  end;

  ServerExe := TPath.Combine(FPaths.MariaDbBinDir, 'mysqld.exe');
  if not FileExists(ServerExe) and FileExists(MariaDbExe) then
    TFile.Copy(MariaDbExe, ServerExe, True);

  BootstrapCommand := '--datadir="' + DataDir + '" --port=' + FConfig.DatabasePort.ToString +
    ' --default-user --verbose-bootstrap';
  AppendTextToLogFile(TPath.Combine(FPaths.LogsDir, 'mariadb-error.log'),
    'MariaDB init command: "' + HelperExe + '" ' + BootstrapCommand);

  if not TProcessManager.RunAndCaptureOutput(
    HelperExe,
    BootstrapCommand,
    FPaths.MariaDbBinDir,
    BootstrapOutput,
    MariaDbInitTimeoutMs) then
  begin
    ErrorMessage := Trim(BootstrapOutput);
    if ErrorMessage = '' then
      ErrorMessage := 'MariaDB initialization timed out while creating the system database.';
    AppendTextToLogFile(TPath.Combine(FPaths.LogsDir, 'mariadb-error.log'),
      'MariaDB init output:' + sLineBreak + ErrorMessage);
    Exit;
  end;

  AppendTextToLogFile(TPath.Combine(FPaths.LogsDir, 'mariadb-error.log'),
    'MariaDB init output:' + sLineBreak + Trim(BootstrapOutput));
  if not MariaDbSystemDatabaseReady(MysqlDir) then
  begin
    ErrorMessage := 'MariaDB initialization did not create the mysql system database.';
    Exit;
  end;

  Result := True;
end;

function TUniWampRuntime.WaitForMariaDbStartup(const ProcessId: Cardinal; out ErrorMessage: string): Boolean;
const
  StartupTimeoutMs = 30000;
  PollIntervalMs = 250;
var
  StartTick: UInt64;
begin
  Result := False;
  ErrorMessage := '';
  StartTick := GetTickCount64;
  repeat
    if not TProcessManager.IsRunning(ProcessId) then
    begin
      ErrorMessage := 'MariaDB exited before it finished starting.';
      Exit;
    end;
    if not IsTcpPortAvailable(FConfig.DatabasePort) then
    begin
      Result := True;
      Exit;
    end;
    Sleep(PollIntervalMs);
  until (GetTickCount64 - StartTick) >= StartupTimeoutMs;

  ErrorMessage := Format(
    'MariaDB did not start listening on port %d within %d seconds.',
    [FConfig.DatabasePort, StartupTimeoutMs div 1000]);
end;

procedure TUniWampRuntime.GeneratePhpConfig;
var
  Values: TDictionary<string, string>;
  DefaultDisplayErrors: string;
begin
  Values := TDictionary<string, string>.Create;
  try
    if SameText(FConfig.PhpProfile, 'production') then
      DefaultDisplayErrors := 'Off'
    else
      DefaultDisplayErrors := 'On';
    Values.Add('DISPLAY_ERRORS', FConfig.PhpSettingValue('display_errors', DefaultDisplayErrors));
    Values.Add('ERROR_REPORTING', FConfig.PhpSettingValue('error_reporting', 'E_ALL'));
    Values.Add('LOG_ERRORS', FConfig.PhpSettingValue('log_errors', 'On'));
    Values.Add('SHORT_OPEN_TAG', FConfig.PhpSettingValue('short_open_tag', 'Off'));
    Values.Add('EXPOSE_PHP', FConfig.PhpSettingValue('expose_php', 'Off'));
    Values.Add('MEMORY_LIMIT', FConfig.PhpSettingValue('memory_limit', '256M'));
    Values.Add('UPLOAD_MAX_FILESIZE', FConfig.PhpSettingValue('upload_max_filesize', '32M'));
    Values.Add('POST_MAX_SIZE', FConfig.PhpSettingValue('post_max_size', '32M'));
    Values.Add('MAX_EXECUTION_TIME', FConfig.PhpSettingValue('max_execution_time', '120'));
    Values.Add('MAX_INPUT_VARS', FConfig.PhpSettingValue('max_input_vars', '3000'));
    Values.Add('PHP_EXT_DIR', TPath.Combine(SelectedPhpDir, 'ext'));
    Values.Add('PHP_EXTENSION_LINES', RenderPhpExtensionLines);
    Values.Add('TMP_DIR', FPaths.TmpDir);
    Values.Add('LOGS_DIR', FPaths.LogsDir);
    TTemplateRenderer.RenderToFile(FPaths.PhpTemplateFile, FPaths.ActivePhpIniFile, Values);
  finally
    Values.Free;
  end;
end;

function TUniWampRuntime.RenderVHostBlocks: string;
var
  Entry: TVHostEntry;
  Block: TStringList;
begin
  Block := TStringList.Create;
  try
    Block.Add('<VirtualHost *:' + FConfig.HttpPort.ToString + '>');
    Block.Add('  ServerName ' + FConfig.HostName);
    Block.Add('  ServerAlias 127.0.0.1 localhost');
    Block.Add('  DocumentRoot "' + FConfig.DocumentRoot + '"');
    Block.Add('  <Directory "' + FConfig.DocumentRoot + '">');
    Block.Add('    AllowOverride All');
    Block.Add('    Require all granted');
    Block.Add('  </Directory>');
    Block.Add('</VirtualHost>');
    Block.Add('');

    for Entry in FConfig.VHosts do
    begin
      Block.Add('<VirtualHost *:' + FConfig.HttpPort.ToString + '>');
      Block.Add('  ServerName ' + Entry.ServerName);
      if Trim(Entry.ServerAliases) <> '' then
        Block.Add('  ServerAlias ' + Trim(Entry.ServerAliases));
      Block.Add('  DocumentRoot "' + Entry.DocumentRoot + '"');
      Block.Add('  <Directory "' + Entry.DocumentRoot + '">');
      Block.Add('    AllowOverride All');
      Block.Add('    Require all granted');
      Block.Add('  </Directory>');
      Block.Add('</VirtualHost>');
      Block.Add('');

      if FConfig.EnableSsl and Entry.EnableSsl then
      begin
        Block.Add('<VirtualHost *:' + FConfig.HttpsPort.ToString + '>');
        Block.Add('  ServerName ' + Entry.ServerName);
        if Trim(Entry.ServerAliases) <> '' then
          Block.Add('  ServerAlias ' + Trim(Entry.ServerAliases));
        Block.Add('  DocumentRoot "' + Entry.DocumentRoot + '"');
        Block.Add('  SSLEngine on');
        if (Entry.SslCertFile <> '') and FileExists(Entry.SslCertFile) then
          Block.Add('  SSLCertificateFile "' + Entry.SslCertFile + '"')
        else
          Block.Add('  SSLCertificateFile "' + TPath.Combine(FPaths.SslDir, 'server.crt') + '"');
        if (Entry.SslKeyFile <> '') and FileExists(Entry.SslKeyFile) then
          Block.Add('  SSLCertificateKeyFile "' + Entry.SslKeyFile + '"')
        else
          Block.Add('  SSLCertificateKeyFile "' + TPath.Combine(FPaths.SslDir, 'server.key') + '"');
        Block.Add('</VirtualHost>');
        Block.Add('');
      end;
    end;
    Result := Block.Text;
  finally
    Block.Free;
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

procedure TUniWampRuntime.GenerateVHostConfig;
var
  Values: TDictionary<string, string>;
begin
  Values := TDictionary<string, string>.Create;
  try
    Values.Add('VHOSTS', RenderVHostBlocks);
    TTemplateRenderer.RenderToFile(FPaths.ApacheVHostsTemplateFile, FPaths.ApacheVHostsConfFile, Values);
  finally
    Values.Free;
  end;
end;

procedure TUniWampRuntime.GenerateEnvBat;
var
  Lines: TStringList;
  PhpDir: string;
  NodeDir: string;
begin
  EnsureDirectory(FPaths.GeneratedConfigDir);
  PhpDir := SelectedPhpDir;
  NodeDir := SelectedNodeDir;
  Lines := TStringList.Create;
  try
    Lines.Add('@echo off');
    Lines.Add('title UniWamp Cmder');
    Lines.Add('color 0A');
    Lines.Add('set "UNIWAMP_ROOT=' + FPaths.AppRoot + '"');
    Lines.Add('set "UNIWAMP_DOCROOT=' + FConfig.DocumentRoot + '"');
    Lines.Add('set "UNIWAMP_MARIADB_BIN=' + FPaths.MariaDbBinDir + '"');
    Lines.Add('set "UNIWAMP_PHP_VERSION=' + FConfig.SelectedPhpVersion + '"');
    Lines.Add('set "UNIWAMP_NODE_VERSION=' + FConfig.SelectedNodeVersion + '"');
    if FConfig.SelectedPhpVersion <> '' then
    begin
      Lines.Add('set "PHP_HOME=' + PhpDir + '"');
      Lines.Add('set "PHP_BIN=' + PhpDir + '"');
      Lines.Add('set "PATH=' + PhpDir + ';%PATH%"');
    end;
    if FConfig.SelectedNodeVersion <> '' then
  begin
    Lines.Add('set "NODE_HOME=' + NodeDir + '"');
    Lines.Add('set "NODE_BIN=' + NodeDir + '"');
    Lines.Add('set "PATH=' + NodeDir + ';%PATH%"');
  end;
    Lines.Add('set "PATH=' + FPaths.MariaDbBinDir + ';%PATH%"');
    Lines.Add('echo  PHP: %UNIWAMP_PHP_VERSION%  -  %PHP_HOME%');
    Lines.Add('if "%UNIWAMP_NODE_VERSION%"=="" (');
      Lines.Add('  echo  Node: not selected');
    Lines.Add(') else (');
      Lines.Add('  echo  Node: %UNIWAMP_NODE_VERSION%  -  %NODE_HOME%');
    Lines.Add(')');
    Lines.Add('echo  Working path: %UNIWAMP_DOCROOT%');
    Lines.Add('echo  MariaDB bin: %UNIWAMP_MARIADB_BIN%');
    Lines.Add('echo.');
    Lines.Add('cd /d "' + FConfig.DocumentRoot + '"');
    Lines.SaveToFile(FPaths.EnvBatFile, TEncoding.ASCII);
  finally
    Lines.Free;
  end;
end;

procedure TUniWampRuntime.GenerateAllConfigs;
var
  HostsError: string;
begin
  TTemplateRenderer.EnsureDefaultTemplates(FPaths);
  GeneratePhpConfig;
  GenerateVHostConfig;
  GenerateApacheConfig;
  GenerateMariaDbConfig;
  SyncHostsFile(HostsError);
end;

function TUniWampRuntime.StartApache: TRuntimeActionResult;
var
  StartResult: TProcessStartResult;
  ErrorMessage: string;
begin
  if FConfig.ApacheRunning and not ApacheIsRunning then
  begin
    FConfig.LastApacheError := 'Stale Apache state detected; retrying start.';
    FConfig.ApachePid := 0;
    FConfig.ApacheRunning := False;
  end;

  if ApacheIsRunning then
  begin
    FConfig.ApacheRunning := True;
    Result.Success := True;
    Result.Message := 'Apache already running.';
    Exit;
  end;

  SyncPhpVersions;
  Result.Success := False;
  if not ValidateApachePorts(ErrorMessage) then
  begin
    FConfig.LastApacheError := ErrorMessage;
    Result.Message := ErrorMessage;
    Exit;
  end;

  if not FileExists(SelectedPhpExe) then
  begin
    FConfig.LastApacheError := 'Selected PHP runtime is missing: ' + SelectedPhpExe;
    Result.Message := 'Selected PHP runtime is missing: ' + SelectedPhpExe;
    Exit;
  end;

  if not FileExists(ApacheModuleForSelectedPhp) then
  begin
    FConfig.LastApacheError := 'Apache PHP module missing for ' + FConfig.SelectedPhpVersion;
    Result.Message := 'Apache PHP module missing for ' + FConfig.SelectedPhpVersion;
    Exit;
  end;

  if FConfig.EnableSsl then
  begin
    if not EnsureDefaultSslCertificate(ErrorMessage) then
    begin
      FConfig.LastApacheError := ErrorMessage;
      Result.Message := ErrorMessage;
      Exit;
    end;
  end;

  GenerateAllConfigs;
  if not ValidateApacheConfiguration(ErrorMessage) then
  begin
    FConfig.ApacheRunning := False;
    FConfig.LastApacheError := ErrorMessage;
    Result.Message := ErrorMessage;
    Exit;
  end;
  StartResult := TProcessManager.StartDetached(
    ApacheExe,
    '-f "' + FPaths.ApacheHttpdConfFile + '"',
    FPaths.ApacheBinDir);

  Result.Success := StartResult.Success;
  if StartResult.Success then
  begin
    FConfig.ApachePid := StartResult.ProcessId;
    if WaitForApacheStartup(StartResult.ProcessId, ErrorMessage) then
    begin
      FConfig.ApacheRunning := True;
      FConfig.LastApacheError := '';
      Result.Message := 'Apache started.';
    end
    else
    begin
      FConfig.ApachePid := 0;
      FConfig.ApacheRunning := False;
      FConfig.LastApacheError := ErrorMessage;
      Result.Success := False;
      Result.Message := ErrorMessage;
    end;
  end
  else
  begin
    FConfig.ApacheRunning := False;
    FConfig.LastApacheError := StartResult.ErrorMessage;
    Result.Message := StartResult.ErrorMessage;
  end;
end;

function TUniWampRuntime.StopApache: TRuntimeActionResult;
var
  StartResult: TProcessStartResult;
  RuntimePid: Cardinal;
  SystemRoot: string;
begin
  Result.Success := True;
  RuntimePid := ApacheRuntimePid;
  if FileExists(ApacheExe) then
  begin
    StartResult := TProcessManager.StartDetached(
      ApacheExe,
      '-k stop -f "' + FPaths.ApacheHttpdConfFile + '"',
      FPaths.ApacheBinDir);
    if StartResult.Success then
      TProcessManager.WaitForExit(StartResult.ProcessId, 4000);
  end;

  if (RuntimePid <> 0) and TProcessManager.IsRunning(RuntimePid) then
    Result.Success := TProcessManager.StopProcess(RuntimePid);

  if TProcessManager.IsRunning(FConfig.ApachePid) then
    Result.Success := TProcessManager.StopProcess(FConfig.ApachePid) and Result.Success;
  if (FConfig.ApachePid <> 0) and not TProcessManager.IsRunning(FConfig.ApachePid) then
    FConfig.ApachePid := 0;

  if (RuntimePid <> 0) and not IsTcpPortAvailable(FConfig.HttpPort) then
  begin
    SystemRoot := TPath.Combine(GetEnvironmentVariable('SystemRoot'), 'System32');
    StartResult := TProcessManager.StartDetached(
      TPath.Combine(SystemRoot, 'taskkill.exe'),
      '/PID ' + RuntimePid.ToString + ' /T /F',
      SystemRoot);
    if StartResult.Success then
      TProcessManager.WaitForExit(StartResult.ProcessId, 4000);
  end;

  if (RuntimePid <> 0) and FConfig.EnableSsl and (not IsTcpPortAvailable(FConfig.HttpsPort)) then
  begin
    SystemRoot := TPath.Combine(GetEnvironmentVariable('SystemRoot'), 'System32');
    StartResult := TProcessManager.StartDetached(
      TPath.Combine(SystemRoot, 'taskkill.exe'),
      '/PID ' + RuntimePid.ToString + ' /T /F',
      SystemRoot);
    if StartResult.Success then
      TProcessManager.WaitForExit(StartResult.ProcessId, 4000);
  end;

  if (not IsTcpPortAvailable(FConfig.HttpPort)) or
     (FConfig.EnableSsl and (not IsTcpPortAvailable(FConfig.HttpsPort))) then
  begin
    SystemRoot := TPath.Combine(GetEnvironmentVariable('SystemRoot'), 'System32');
    StartResult := TProcessManager.StartDetached(
      TPath.Combine(SystemRoot, 'taskkill.exe'),
      '/IM httpd.exe /T /F',
      SystemRoot);
    if StartResult.Success then
      TProcessManager.WaitForExit(StartResult.ProcessId, 4000);
  end;

  Sleep(1000);

  FConfig.ApachePid := 0;
  FConfig.ApacheRunning := False;
  Result.Success := Result.Success and IsTcpPortAvailable(FConfig.HttpPort) and
    ((not FConfig.EnableSsl) or IsTcpPortAvailable(FConfig.HttpsPort));
  if Result.Success then
    Result.Message := 'Apache stopped.'
  else
    Result.Message := 'Failed to stop Apache cleanly.';
end;

function TUniWampRuntime.RestartApache: TRuntimeActionResult;
begin
  Result := StopApache;
  if not Result.Success then
  begin
    Result.Message := 'Apache restart failed during stop: ' + Result.Message;
    FConfig.LastApacheError := Result.Message;
    Exit;
  end;
  Sleep(500);
  Result := StartApache;
  if not Result.Success then
  begin
    Result.Message := 'Apache restart failed during start: ' + Result.Message;
    FConfig.LastApacheError := Result.Message;
  end;
end;

function TUniWampRuntime.StartMariaDb: TRuntimeActionResult;
var
  StartResult: TProcessStartResult;
  ErrorMessage: string;
begin
  if FConfig.MariaDbRunning and not MariaDbIsRunning then
  begin
    FConfig.LastMariaDbError := 'Stale MariaDB state detected; retrying start.';
    FConfig.MariaDbPid := 0;
    FConfig.MariaDbRunning := False;
  end;

  if MariaDbIsRunning then
  begin
    FConfig.MariaDbRunning := True;
    Result.Success := True;
    Result.Message := 'MariaDB already running.';
    Exit;
  end;

  Result.Success := False;
  if not ValidateMariaDbPorts(ErrorMessage) then
  begin
    FConfig.LastMariaDbError := ErrorMessage;
    Result.Message := ErrorMessage;
    Exit;
  end;

  if not EnsureMariaDbInitialized(ErrorMessage) then
  begin
    FConfig.MariaDbRunning := False;
    FConfig.LastMariaDbError := ErrorMessage;
    Result.Message := ErrorMessage;
    Exit;
  end;

  GenerateMariaDbConfig;
  StartResult := TProcessManager.StartDetached(
    MariaDbExe,
    '--defaults-file="' + FPaths.MariaDbIniFile + '" --console',
    FPaths.MariaDbBinDir);

  Result.Success := StartResult.Success;
  if StartResult.Success then
  begin
    FConfig.MariaDbPid := StartResult.ProcessId;
    if WaitForMariaDbStartup(StartResult.ProcessId, ErrorMessage) then
    begin
      FConfig.MariaDbRunning := True;
      FConfig.LastMariaDbError := '';
      Result.Message := 'MariaDB started.';
    end
    else
    begin
      FConfig.MariaDbPid := 0;
      FConfig.MariaDbRunning := False;
      FConfig.LastMariaDbError := ErrorMessage;
      Result.Success := False;
      Result.Message := ErrorMessage;
    end;
  end
  else
  begin
    FConfig.MariaDbRunning := False;
    FConfig.LastMariaDbError := StartResult.ErrorMessage;
    Result.Message := StartResult.ErrorMessage;
  end;
end;

function TUniWampRuntime.StopMariaDb: TRuntimeActionResult;
var
  StartResult: TProcessStartResult;
begin
  Result.Success := True;
  if FileExists(MysqlAdminExe) then
  begin
    StartResult := TProcessManager.StartDetached(
      MysqlAdminExe,
      '--port=' + FConfig.DatabasePort.ToString + ' shutdown',
      FPaths.MariaDbBinDir);
    if StartResult.Success then
      TProcessManager.WaitForExit(StartResult.ProcessId, 4000);
  end;

  if TProcessManager.IsRunning(FConfig.MariaDbPid) then
    Result.Success := TProcessManager.StopProcess(FConfig.MariaDbPid);
  if (FConfig.MariaDbPid <> 0) and not TProcessManager.IsRunning(FConfig.MariaDbPid) then
    FConfig.MariaDbPid := 0;

  FConfig.MariaDbRunning := False;
  if Result.Success then
    Result.Message := 'MariaDB stopped.'
  else
    Result.Message := 'Failed to stop MariaDB cleanly.';
end;

function TUniWampRuntime.RestartMariaDb: TRuntimeActionResult;
begin
  Result := StopMariaDb;
  if not Result.Success then
  begin
    Result.Message := 'MariaDB restart failed during stop: ' + Result.Message;
    FConfig.LastMariaDbError := Result.Message;
    Exit;
  end;
  Result := StartMariaDb;
  if not Result.Success then
  begin
    Result.Message := 'MariaDB restart failed during start: ' + Result.Message;
    FConfig.LastMariaDbError := Result.Message;
  end;
end;

function TUniWampRuntime.GenerateSslCertificate: TRuntimeActionResult;
begin
  Result := GenerateSslCertificateFor(FConfig.HostName,
    TPath.Combine(FPaths.SslDir, 'server.crt'),
    TPath.Combine(FPaths.SslDir, 'server.key'));
end;

function TUniWampRuntime.GenerateSslCertificateFor(const CommonName, CertFile,
  KeyFile: string): TRuntimeActionResult;
var
  OpenSslExe: string;
  StartResult: TProcessStartResult;
  CertDir: string;
begin
  OpenSslExe := TPath.Combine(FPaths.ApacheBinDir, 'openssl.exe');
  if not FileExists(OpenSslExe) then
  begin
    Result.Success := False;
    Result.Message := 'OpenSSL executable not found: ' + OpenSslExe;
    Exit;
  end;

  CertDir := TPath.GetDirectoryName(CertFile);
  if CertDir <> '' then
    EnsureDirectory(CertDir);

  StartResult := TProcessManager.StartDetached(
    OpenSslExe,
    'req -x509 -nodes -days 365 -newkey rsa:2048 ' +
    '-subj "/CN=' + CommonName + '" ' +
    '-keyout "' + KeyFile + '" ' +
    '-out "' + CertFile + '"',
    FPaths.SslDir);

  Result.Success := StartResult.Success;
  if Result.Success then
  begin
    TProcessManager.WaitForExit(StartResult.ProcessId, 120000);
    if FileExists(CertFile) and FileExists(KeyFile) then
      Result.Message := 'SSL certificate generated.'
    else
    begin
      Result.Success := False;
      Result.Message := 'SSL certificate generation did not produce the expected files.';
    end;
  end
  else
    Result.Message := StartResult.ErrorMessage;
end;

function TUniWampRuntime.SetMariaDbRootPassword(const NewPassword: string): TRuntimeActionResult;
var
  MysqlAdminExePath: string;
  Arguments: string;
  Output: string;
  LowerOutput: string;
begin
  if Trim(NewPassword) = '' then
  begin
    Result.Success := False;
    Result.Message := 'MariaDB root password cannot be empty.';
    Exit;
  end;

  if not MariaDbIsRunning then
  begin
    Result.Success := False;
    Result.Message := 'MariaDB must be running before setting the root password.';
    Exit;
  end;

  MysqlAdminExePath := MysqlAdminExe;
  if not FileExists(MysqlAdminExePath) then
  begin
    Result.Success := False;
    Result.Message := 'mysqladmin executable not found: ' + MysqlAdminExePath;
    Exit;
  end;

  Arguments := '--port=' + FConfig.DatabasePort.ToString + ' --user=root ';
  if FConfig.MariaDbRootPassword <> '' then
    Arguments := Arguments + '--password="' + FConfig.MariaDbRootPassword + '" ';
  Arguments := Arguments + 'password "' + NewPassword + '"';

  if not TProcessManager.RunAndCaptureOutput(MysqlAdminExePath, Arguments, FPaths.MariaDbBinDir, Output) then
  begin
    Result.Success := False;
    if Trim(Output) <> '' then
      Result.Message := Trim(Output)
    else
      Result.Message := 'Failed to start mysqladmin.';
    Exit;
  end;

  LowerOutput := LowerCase(Output);
  if (Pos('error', LowerOutput) > 0) or (Pos('access denied', LowerOutput) > 0) then
  begin
    Result.Success := False;
    FConfig.LastMariaDbError := Trim(Output);
    if Trim(Output) <> '' then
      Result.Message := Trim(Output)
    else
      Result.Message := 'MariaDB root password could not be updated.';
    Exit;
  end;

  FConfig.MariaDbRootPassword := NewPassword;
  FConfig.LastMariaDbError := '';
  Result.Success := True;
  Result.Message := 'MariaDB root password updated.';
end;

function TUniWampRuntime.LaunchUrl(const Url: string): TRuntimeActionResult;
begin
  Result.Success := ShellExecute(0, 'open', PChar(Url), nil, nil, SW_SHOWNORMAL) > 32;
  if Result.Success then
    Result.Message := 'Launched ' + Url
  else
    Result.Message := 'Failed to launch ' + Url;
end;

function TUniWampRuntime.PreferredTextEditorExecutable: string;
begin
  Result := ResolvePortablePath(GetEnvironmentVariable('EDITOR'));
  if Result = '' then
    Result := 'notepad.exe';
end;

function TUniWampRuntime.LaunchTextEditor(const FileName: string): TRuntimeActionResult;
var
  EditorExe: string;
begin
  EditorExe := PreferredTextEditorExecutable;
  Result.Success := ShellExecute(0, 'open', PChar(EditorExe), PChar('"' + FileName + '"'), nil, SW_SHOWNORMAL) > 32;
  if Result.Success then
    Result.Message := 'Launched ' + EditorExe
  else
    Result.Message := 'Failed to launch ' + EditorExe;
end;

function TUniWampRuntime.LaunchAdminer: TRuntimeActionResult;
begin
  if FileExists(TPath.Combine(FPaths.AdminerDir, 'index.php')) then
    Result := LaunchUrl(Format('http://%s:%d/adminer/index.php', [FConfig.HostName, FConfig.HttpPort]))
  else
  begin
    Result.Success := False;
    Result.Message := 'Adminer entrypoint not found in home\adminer\index.php';
  end;
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
  GenerateEnvBat;
  TerminalExe := PreferredTerminalExecutable;

  if FileExists(TerminalExe) then
  begin
    ProfileDir := TPath.Combine(ExtractFileDir(TerminalExe), 'config\profile.d');
    EnsureDirectory(ProfileDir);
    TargetCmd := TPath.Combine(ProfileDir, 'uniwamp_env.cmd');
    ProfileText := TFile.ReadAllText(FPaths.EnvBatFile, TEncoding.UTF8);
    TFile.WriteAllText(TargetCmd, ProfileText, TEncoding.ASCII);

    Result.Success := ShellExecute(0, 'open', PChar(TerminalExe), PChar('/START "' + WorkingDir + '"'), nil, SW_SHOWNORMAL) > 32;
    if Result.Success then
      Result.Message := 'Launched Cmder terminal'
    else
      Result.Message := 'Failed to launch Cmder terminal';
  end
  else if SameText(ExtractFileName(TerminalExe), 'wt.exe') then
  begin
    Result.Success := ShellExecute(0, 'open', PChar(TerminalExe), PChar('-d "' + WorkingDir + '"'), nil, SW_SHOWNORMAL) > 32;
    if Result.Success then
      Result.Message := 'Launched Windows Terminal'
    else
      Result.Message := 'Failed to launch Windows Terminal';
  end
  else
  begin
    Result.Success := ShellExecute(0, 'open', 'cmd.exe', PChar('/K "' + FPaths.EnvBatFile + '"'), PChar(WorkingDir), SW_SHOWNORMAL) > 32;
    if Result.Success then
      Result.Message := 'Launched standard CMD terminal'
    else
      Result.Message := 'Failed to launch standard CMD terminal';
  end;
end;

function TUniWampRuntime.AddVHost(const ServerName, DocumentRoot, ServerAliases: string;
  EnableSsl: Boolean): TRuntimeActionResult;
var
  Entry: TVHostEntry;
  HostsError: string;
  SslDirName: string;
begin
  if (Trim(ServerName) = '') or (Trim(DocumentRoot) = '') then
  begin
    Result.Success := False;
    Result.Message := 'Server name and document root are required.';
    Exit;
  end;

  EnsureDirectory(DocumentRoot);
  EnsureVHostStarterPage(ServerName, DocumentRoot);
  Entry.ServerName := ServerName;
  Entry.ServerAliases := NormalizeServerAliases(ServerAliases);
  Entry.DocumentRoot := DocumentRoot;
  Entry.EnableSsl := EnableSsl;
  Entry.SslCertFile := '';
  Entry.SslKeyFile := '';
  if EnableSsl then
  begin
    SslDirName := ServerName;
    SslDirName := StringReplace(SslDirName, ':', '_', [rfReplaceAll]);
    SslDirName := StringReplace(SslDirName, '/', '_', [rfReplaceAll]);
    SslDirName := StringReplace(SslDirName, '\', '_', [rfReplaceAll]);
    Entry.SslCertFile := TPath.Combine(FPaths.SslDir, TPath.Combine('vhosts', TPath.Combine(SslDirName, 'server.crt')));
    Entry.SslKeyFile := TPath.Combine(FPaths.SslDir, TPath.Combine('vhosts', TPath.Combine(SslDirName, 'server.key')));
    Result := GenerateSslCertificateFor(ServerName, Entry.SslCertFile, Entry.SslKeyFile);
    if not Result.Success then
      Exit;
  end;
  FConfig.AddOrUpdateVHost(Entry);
  GenerateVHostConfig;
  if SyncHostsFile(HostsError) then
    Result.Message := 'VHost saved: ' + ServerName
  else
    Result.Message := 'VHost saved: ' + ServerName + ' (' + HostsError + ')';
  Result.Success := True;
end;

function TUniWampRuntime.RefreshVHostSslCertificate(const ServerName: string): TRuntimeActionResult;
var
  Entry: TVHostEntry;
  Found: Boolean;
  SslDirName: string;
begin
  Result.Success := False;
  Result.Message := '';
  Found := False;
  for Entry in FConfig.VHosts do
    if SameText(Entry.ServerName, ServerName) then
    begin
      Found := True;
      Break;
    end;

  if not Found then
  begin
    Result.Message := 'VHost not found: ' + ServerName;
    Exit;
  end;

  if not Entry.EnableSsl then
  begin
    Result.Message := 'SSL is not enabled for this vHost.';
    Exit;
  end;

  if Entry.SslCertFile = '' then
  begin
    SslDirName := ServerName;
    SslDirName := StringReplace(SslDirName, ':', '_', [rfReplaceAll]);
    SslDirName := StringReplace(SslDirName, '/', '_', [rfReplaceAll]);
    SslDirName := StringReplace(SslDirName, '\', '_', [rfReplaceAll]);
    Entry.SslCertFile := TPath.Combine(FPaths.SslDir, TPath.Combine('vhosts', TPath.Combine(SslDirName, 'server.crt')));
  end;
  if Entry.SslKeyFile = '' then
  begin
    SslDirName := ServerName;
    SslDirName := StringReplace(SslDirName, ':', '_', [rfReplaceAll]);
    SslDirName := StringReplace(SslDirName, '/', '_', [rfReplaceAll]);
    SslDirName := StringReplace(SslDirName, '\', '_', [rfReplaceAll]);
    Entry.SslKeyFile := TPath.Combine(FPaths.SslDir, TPath.Combine('vhosts', TPath.Combine(SslDirName, 'server.key')));
  end;

  Result := GenerateSslCertificateFor(Entry.ServerName, Entry.SslCertFile, Entry.SslKeyFile);
  if not Result.Success then
    Exit;

  FConfig.AddOrUpdateVHost(Entry);
  GenerateVHostConfig;
  Result.Message := 'SSL certificate refreshed for ' + ServerName;
end;

function TUniWampRuntime.DeleteVHost(const ServerName: string): TRuntimeActionResult;
var
  Entry: TVHostEntry;
  VHost: TVHostEntry;
  HostsError: string;
begin
  Entry.ServerName := '';
  Entry.ServerAliases := '';
  Entry.DocumentRoot := '';
  Entry.EnableSsl := False;
  Entry.SslCertFile := '';
  Entry.SslKeyFile := '';
  for VHost in FConfig.VHosts do
    if SameText(VHost.ServerName, ServerName) then
    begin
      Entry := VHost;
      Break;
    end;

  FConfig.DeleteVHost(ServerName);
  GenerateVHostConfig;
  if Entry.EnableSsl then
  begin
    if Entry.SslCertFile <> '' then
      TFile.Delete(Entry.SslCertFile);
    if Entry.SslKeyFile <> '' then
      TFile.Delete(Entry.SslKeyFile);
  end;
  if SyncHostsFile(HostsError) then
    Result.Message := 'VHost removed: ' + ServerName
  else
    Result.Message := 'VHost removed: ' + ServerName + ' (' + HostsError + ')';
  Result.Success := True;
end;

function TUniWampRuntime.ServiceStateLabel(const Running: Boolean): string;
begin
  if Running then
    Result := 'running'
  else
    Result := 'stopped';
end;

end.
