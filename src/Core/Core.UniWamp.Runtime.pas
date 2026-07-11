unit Core.UniWamp.Runtime;

interface

uses
  System.Generics.Collections,
  System.SysUtils,
  Core.UniWamp.Config,
  Core.UniWamp.Paths;

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
    function EnsureMariaDbInitialized(out ErrorMessage: string): Boolean;
    function ResolvePortablePath(const PathValue: string): string;
    function CmderExe: string;
    function RenderManagedHostsBlock: string;
    function ApacheModuleDir: string;
    function RenderApacheModuleLines: string;
    function SelectedPhpDir: string;
    function SelectedPhpExe: string;
    function SelectedNodeDir: string;
    function RenderPhpExtensionLines: string;
    procedure GenerateApacheConfig;
    procedure GenerateMariaDbConfig;
    procedure GeneratePhpConfig;
    procedure GenerateVHostConfig;
    function SyncHostsFile(out ErrorMessage: string): Boolean;
    function RenderVHostBlocks: string;
    function ValidateApachePorts(out ErrorMessage: string): Boolean;
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
    function LaunchAdminer: TRuntimeActionResult;
    function LaunchTerminal: TRuntimeActionResult;
    function AddVHost(const ServerName, DocumentRoot: string; EnableSsl: Boolean): TRuntimeActionResult;
    function DeleteVHost(const ServerName: string): TRuntimeActionResult;
  end;

implementation

uses
  Winapi.Windows,
  Winapi.ShellAPI,
  System.Classes,
  System.IOUtils,
  System.StrUtils,
  Core.UniWamp.PortUtils,
  Core.UniWamp.ProcessManager,
  Core.UniWamp.TemplateRenderer;

const
  ManagedHostsBeginMarker = '# BEGIN UniWamp Managed Hosts';
  ManagedHostsEndMarker = '# END UniWamp Managed Hosts';

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

function TUniWampRuntime.MariaDbIsRunning: Boolean;
begin
  Result := (FConfig.MariaDbPid <> 0) and TProcessManager.IsRunning(FConfig.MariaDbPid);
end;

function TUniWampRuntime.HostsFilePath: string;
var
  SystemRoot: string;
begin
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
  Entry: TVHostEntry;
begin
  Hosts := TStringList.Create;
  try
    Hosts.Add(ManagedHostsBeginMarker);
    Hosts.Add('127.0.0.1 ' + FConfig.HostName);
    for Entry in FConfig.VHosts do
      if (Trim(Entry.ServerName) <> '') and (Hosts.IndexOf('127.0.0.1 ' + Entry.ServerName) < 0) then
        Hosts.Add('127.0.0.1 ' + Entry.ServerName);
    Hosts.Add(ManagedHostsEndMarker);
    Result := Hosts.Text;
  finally
    Hosts.Free;
  end;
end;

function TUniWampRuntime.SyncHostsFile(out ErrorMessage: string): Boolean;
var
  HostsPath: string;
  HostsText: string;
  StartPos: Integer;
  EndPos: Integer;
  ManagedBlock: string;
begin
  Result := False;
  ErrorMessage := '';
  HostsPath := HostsFilePath;
  ManagedBlock := RenderManagedHostsBlock;

  try
    if FileExists(HostsPath) then
      HostsText := TFile.ReadAllText(HostsPath, TEncoding.ASCII)
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
      if Pos('Access to the path', E.Message) > 0 then
        FConfig.LastHostsSyncStatus := 'Hosts update requires Administrator'
      else
        FConfig.LastHostsSyncStatus := 'Hosts update failed';
      ErrorMessage := 'Hosts file update failed: ' + E.Message;
    end;
  end;
end;

function TUniWampRuntime.ApacheModuleForSelectedPhp: string;
var
  Candidate: string;
begin
  Candidate := TPath.Combine(SelectedPhpDir, 'php8apache2_4.dll');
  if not FileExists(Candidate) then
    Candidate := TPath.Combine(SelectedPhpDir, 'php7apache2_4.dll');
  Result := Candidate;
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
begin
  Result := True;
  ErrorMessage := '';
  ApacheRunningNow := ApacheIsRunning or FConfig.ApacheRunning;
  if not IsTcpPortAvailable(FConfig.HttpPort) and not ApacheRunningNow then
  begin
    Result := False;
    ErrorMessage := Format('HTTP port %d is already in use.', [FConfig.HttpPort]);
    Exit;
  end;
  if FConfig.EnableSsl and not IsTcpPortAvailable(FConfig.HttpsPort) and not ApacheRunningNow then
  begin
    Result := False;
    ErrorMessage := Format('HTTPS port %d is already in use.', [FConfig.HttpsPort]);
    Exit;
  end;
end;

function TUniWampRuntime.ValidateMariaDbPorts(out ErrorMessage: string): Boolean;
var
  MariaDbRunningNow: Boolean;
begin
  Result := True;
  ErrorMessage := '';
  MariaDbRunningNow := MariaDbIsRunning or FConfig.MariaDbRunning;
  if not IsTcpPortAvailable(FConfig.DatabasePort) and not MariaDbRunningNow then
  begin
    Result := False;
    ErrorMessage := Format('Database port %d is already in use.', [FConfig.DatabasePort]);
    begin
      Exit;
    end;
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
var
  DataDir: string;
  MysqlDir: string;
  DataSubDirs: TArray<string>;
  DataFiles: TArray<string>;
  BackupDir: string;
  HelperExe: string;
  ServerExe: string;
  StartResult: TProcessStartResult;
begin
  Result := False;
  ErrorMessage := '';
  DataDir := TPath.Combine(FPaths.MariaDbDir, 'data');
  MysqlDir := TPath.Combine(DataDir, 'mysql');

  if DirectoryExists(MysqlDir) then
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

  if not DirectoryExists(DataDir) then
    ForceDirectories(DataDir);

  DataSubDirs := TDirectory.GetDirectories(DataDir);
  if Length(DataSubDirs) > 0 then
  begin
    ErrorMessage := 'MariaDB data directory contains existing folders but is not initialized. Run the MariaDB initializer manually.';
    Exit;
  end;

  DataFiles := TDirectory.GetFiles(DataDir);
  if Length(DataFiles) > 0 then
  begin
    BackupDir := TPath.Combine(TPath.GetDirectoryName(DataDir),
      'data.bak-' + FormatDateTime('yyyymmdd-hhnnss', Now));
    TDirectory.Move(DataDir, BackupDir);
    ForceDirectories(DataDir);
  end;

  ServerExe := TPath.Combine(FPaths.MariaDbBinDir, 'mysqld.exe');
  if not FileExists(ServerExe) and FileExists(MariaDbExe) then
    TFile.Copy(MariaDbExe, ServerExe, True);

  StartResult := TProcessManager.StartDetached(
    HelperExe,
    '--datadir="' + DataDir + '" --port=' + FConfig.DatabasePort.ToString + ' --default-user --verbose-bootstrap',
    FPaths.MariaDbBinDir);
  if not StartResult.Success then
  begin
    ErrorMessage := StartResult.ErrorMessage;
    Exit;
  end;

  TProcessManager.WaitForExit(StartResult.ProcessId, 120000);
  if not DirectoryExists(MysqlDir) then
  begin
    ErrorMessage := 'MariaDB initialization did not create the mysql system database.';
    Exit;
  end;

  Result := True;
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
        Block.Add('  DocumentRoot "' + Entry.DocumentRoot + '"');
        Block.Add('  SSLEngine on');
        Block.Add('  SSLCertificateFile "' + TPath.Combine(FPaths.SslDir, 'server.crt') + '"');
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
  Encoding: TEncoding;
begin
  EnsureDirectory(FPaths.GeneratedConfigDir);
  PhpDir := SelectedPhpDir;
  NodeDir := SelectedNodeDir;
  Lines := TStringList.Create;
  Encoding := TEncoding.UTF8;
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
    Lines.SaveToFile(FPaths.EnvBatFile, Encoding);
  finally
    Encoding.Free;
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
    Result.Message := ErrorMessage;
    Exit;
  end;

  if not FileExists(SelectedPhpExe) then
  begin
    Result.Message := 'Selected PHP runtime is missing: ' + SelectedPhpExe;
    Exit;
  end;

  if not FileExists(ApacheModuleForSelectedPhp) then
  begin
    Result.Message := 'Apache PHP module missing for ' + FConfig.SelectedPhpVersion;
    Exit;
  end;

  GenerateAllConfigs;
  StartResult := TProcessManager.StartDetached(
    ApacheExe,
    '-f "' + FPaths.ApacheHttpdConfFile + '"',
    FPaths.ApacheBinDir);

  Result.Success := StartResult.Success;
  if StartResult.Success then
  begin
    FConfig.ApachePid := StartResult.ProcessId;
    FConfig.ApacheRunning := True;
    FConfig.LastApacheError := '';
    Result.Message := 'Apache started.';
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

  if (RuntimePid <> 0) and not IsTcpPortAvailable(FConfig.HttpPort) then
  begin
    StartResult := TProcessManager.StartDetached(
      'taskkill.exe',
      '/PID ' + RuntimePid.ToString + ' /T /F',
      'C:\Windows\System32');
    if StartResult.Success then
      TProcessManager.WaitForExit(StartResult.ProcessId, 4000);
  end;

  if (RuntimePid <> 0) and FConfig.EnableSsl and (not IsTcpPortAvailable(FConfig.HttpsPort)) then
  begin
    StartResult := TProcessManager.StartDetached(
      'taskkill.exe',
      '/PID ' + RuntimePid.ToString + ' /T /F',
      'C:\Windows\System32');
    if StartResult.Success then
      TProcessManager.WaitForExit(StartResult.ProcessId, 4000);
  end;

  if (not IsTcpPortAvailable(FConfig.HttpPort)) or
     (FConfig.EnableSsl and (not IsTcpPortAvailable(FConfig.HttpsPort))) then
  begin
    StartResult := TProcessManager.StartDetached(
      'taskkill.exe',
      '/IM httpd.exe /T /F',
      'C:\Windows\System32');
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
    Exit;
  Sleep(500);
  Result := StartApache;
end;

function TUniWampRuntime.StartMariaDb: TRuntimeActionResult;
var
  StartResult: TProcessStartResult;
  ErrorMessage: string;
begin
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
    FConfig.MariaDbRunning := True;
    FConfig.LastMariaDbError := '';
    Result.Message := 'MariaDB started.';
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

  FConfig.MariaDbPid := 0;
  FConfig.MariaDbRunning := False;
  if Result.Success then
    Result.Message := 'MariaDB stopped.'
  else
    Result.Message := 'Failed to stop MariaDB cleanly.';
end;

function TUniWampRuntime.RestartMariaDb: TRuntimeActionResult;
begin
  StopMariaDb;
  Result := StartMariaDb;
end;

function TUniWampRuntime.GenerateSslCertificate: TRuntimeActionResult;
var
  OpenSslExe: string;
  StartResult: TProcessStartResult;
begin
  OpenSslExe := TPath.Combine(FPaths.ApacheBinDir, 'openssl.exe');
  if not FileExists(OpenSslExe) then
  begin
    Result.Success := False;
    Result.Message := 'OpenSSL executable not found: ' + OpenSslExe;
    Exit;
  end;

  StartResult := TProcessManager.StartDetached(
    OpenSslExe,
    'req -x509 -nodes -days 365 -newkey rsa:2048 ' +
    '-subj "/CN=localhost" ' +
    '-keyout "' + TPath.Combine(FPaths.SslDir, 'server.key') + '" ' +
    '-out "' + TPath.Combine(FPaths.SslDir, 'server.crt') + '"',
    FPaths.SslDir);

  Result.Success := StartResult.Success;
  if Result.Success then
    Result.Message := 'SSL certificate generation started.'
  else
    Result.Message := StartResult.ErrorMessage;
end;

function TUniWampRuntime.LaunchUrl(const Url: string): TRuntimeActionResult;
begin
  Result.Success := ShellExecute(0, 'open', PChar(Url), nil, nil, SW_SHOWNORMAL) > 32;
  if Result.Success then
    Result.Message := 'Launched ' + Url
  else
    Result.Message := 'Failed to launch ' + Url;
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
var
  ProfileText: string;
  ProfileDir: string;
  ProfileEncoding: TEncoding;
  TargetCmd: string;
  TerminalExe: string;
begin
  GenerateEnvBat;
  TerminalExe := CmderExe;

  if FileExists(TerminalExe) then
  begin
    ProfileDir := TPath.Combine(ExtractFileDir(TerminalExe), 'config\profile.d');
    EnsureDirectory(ProfileDir);
    TargetCmd := TPath.Combine(ProfileDir, 'uniwamp_env.cmd');
    ProfileText := TFile.ReadAllText(FPaths.EnvBatFile, TEncoding.UTF8);
    ProfileEncoding := TEncoding.UTF8;
    TFile.WriteAllText(TargetCmd, ProfileText, ProfileEncoding);

    Result.Success := ShellExecute(0, 'open', PChar(TerminalExe), PChar('/START "' + FConfig.DocumentRoot + '"'), nil, SW_SHOWNORMAL) > 32;
    if Result.Success then
      Result.Message := 'Launched Cmder terminal'
    else
      Result.Message := 'Failed to launch Cmder terminal';
  end
  else
  begin
    Result.Success := ShellExecute(0, 'open', 'cmd.exe', PChar('/K "' + FPaths.EnvBatFile + '"'), PChar(FConfig.DocumentRoot), SW_SHOWNORMAL) > 32;
    if Result.Success then
      Result.Message := 'Launched standard CMD terminal'
    else
      Result.Message := 'Failed to launch standard CMD terminal';
  end;
end;

function TUniWampRuntime.AddVHost(const ServerName, DocumentRoot: string;
  EnableSsl: Boolean): TRuntimeActionResult;
var
  Entry: TVHostEntry;
  HostsError: string;
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
  Entry.DocumentRoot := DocumentRoot;
  Entry.EnableSsl := EnableSsl;
  FConfig.AddOrUpdateVHost(Entry);
  GenerateVHostConfig;
  if SyncHostsFile(HostsError) then
    Result.Message := 'VHost saved: ' + ServerName
  else
    Result.Message := 'VHost saved: ' + ServerName + ' (' + HostsError + ')';
  Result.Success := True;
end;

function TUniWampRuntime.DeleteVHost(const ServerName: string): TRuntimeActionResult;
var
  HostsError: string;
begin
  FConfig.DeleteVHost(ServerName);
  GenerateVHostConfig;
  if SyncHostsFile(HostsError) then
    Result.Message := 'VHost removed: ' + ServerName
  else
    Result.Message := 'VHost removed: ' + ServerName + ' (' + HostsError + ')';
  Result.Success := True;
end;

end.
