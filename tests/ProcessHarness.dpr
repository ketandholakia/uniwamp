program ProcessHarness;

{$APPTYPE CONSOLE}

uses
  System.Classes,
  System.JSON,
  System.IOUtils,
  System.Zip,
  System.SysUtils,
  System.StrUtils,
  Winapi.Windows,
  Winapi.Winsock2,
  Core.UniWamp.Config,
  Core.UniWamp.Diagnostics,
  Core.UniWamp.Paths,
  Core.UniWamp.PortUtils,
  Core.UniWamp.PackageManager,
  Core.UniWamp.TemplateRenderer,
  Core.UniWamp.Runtime,
  Core.UniWamp.ProcessManager,
  Core.UniWamp.Secrets,
  Core.UniWamp.Types,
  Ui.UniWamp.MainForm;

procedure Fail(const MessageText: string);
begin
  raise Exception.Create(MessageText);
end;

procedure AssertTrue(const Condition: Boolean; const MessageText: string);
begin
  if not Condition then
    Fail(MessageText);
end;

procedure AssertContains(const Haystack, Needle, MessageText: string);
begin
  if Pos(LowerCase(Needle), LowerCase(Haystack)) = 0 then
    Fail(Format('%s Haystack="%s" Needle="%s"', [MessageText, Haystack, Needle]));
end;

function ReserveTcpPort(const Port: Integer; out SocketHandle: TSocket): Boolean;
var
  WsaData: TWSAData;
  Addr: sockaddr_in;
begin
  Result := False;
  SocketHandle := INVALID_SOCKET;
  if WSAStartup($0202, WsaData) <> 0 then
    Exit;
  SocketHandle := socket(AF_INET, SOCK_STREAM, IPPROTO_TCP);
  if SocketHandle = INVALID_SOCKET then
    Exit;
  ZeroMemory(@Addr, SizeOf(Addr));
  Addr.sin_family := AF_INET;
  Addr.sin_addr.S_addr := INADDR_ANY;
  Addr.sin_port := htons(Port);
  if bind(SocketHandle, PSockAddr(@Addr)^, SizeOf(Addr)) <> 0 then
    Exit;
  if listen(SocketHandle, 1) <> 0 then
    Exit;
  Result := True;
end;

procedure ReleaseTcpPort(var SocketHandle: TSocket);
begin
  if SocketHandle <> INVALID_SOCKET then
  begin
    closesocket(SocketHandle);
    WSACleanup;
    SocketHandle := INVALID_SOCKET;
  end;
end;

function BuildPaths(const Root: string): TAppPaths;
begin
  Result := TAppPaths.Detect;
  Result.AppRoot := Root;
  Result.BinDir := TPath.Combine(Root, 'bin');
  Result.ConfigDir := TPath.Combine(Root, 'config');
  Result.GeneratedConfigDir := TPath.Combine(Result.ConfigDir, 'generated');
  Result.TemplatesDir := TPath.Combine(Root, 'templates');
  Result.RuntimeDir := TPath.Combine(Root, 'runtime');
  Result.ToolsDir := TPath.Combine(Result.RuntimeDir, 'tools');
  Result.ComposerDir := TPath.Combine(Result.ToolsDir, 'composer');
  Result.GitDir := TPath.Combine(Result.ToolsDir, 'git');
  Result.WpCliDir := TPath.Combine(Result.ToolsDir, 'wp-cli');
  Result.MailpitDir := TPath.Combine(Result.ToolsDir, 'mailpit');
  Result.RedisDir := TPath.Combine(Result.ToolsDir, 'redis');
  Result.MemcachedDir := TPath.Combine(Result.ToolsDir, 'memcached');
  Result.MkcertDir := TPath.Combine(Result.ToolsDir, 'mkcert');
  Result.MkcertExe := TPath.Combine(Result.MkcertDir, 'mkcert.exe');
  Result.ApacheDir := TPath.Combine(Result.RuntimeDir, 'apache');
  Result.ApacheBinDir := TPath.Combine(Result.ApacheDir, 'bin');
  Result.ApacheConfDir := TPath.Combine(Result.ApacheDir, 'conf');
  Result.MariaDbDir := TPath.Combine(Result.RuntimeDir, 'mariadb');
  Result.MariaDbBinDir := TPath.Combine(Result.MariaDbDir, 'bin');
  Result.PhpDir := TPath.Combine(Result.RuntimeDir, 'php');
  Result.NodeDir := TPath.Combine(Result.RuntimeDir, 'nodejs');
  Result.CmderDir := TPath.Combine(Result.BinDir, 'cmder');
  Result.HomeDir := TPath.Combine(Root, 'home');
  Result.AdminerDir := TPath.Combine(Result.HomeDir, 'adminer');
  Result.DashboardDir := TPath.Combine(Result.HomeDir, 'dashboard');
  Result.LogsDir := TPath.Combine(Root, 'logs');
  Result.TmpDir := TPath.Combine(Root, 'tmp');
  Result.UpdatesDir := TPath.Combine(Result.TmpDir, 'updates');
  Result.WwwDir := TPath.Combine(Root, 'www');
  Result.VHostsDir := Result.WwwDir;
  Result.SslDir := TPath.Combine(Root, 'ssl');
  Result.StateFile := TPath.Combine(Result.ConfigDir, 'state.json');
  Result.AppConfigFile := TPath.Combine(Result.ConfigDir, 'uniwamp.json');
  Result.ApacheTemplateFile := TPath.Combine(Result.TemplatesDir, 'httpd.conf.tpl');
  Result.ApacheSslTemplateFile := TPath.Combine(Result.TemplatesDir, 'httpd-ssl.conf.tpl');
  Result.ApacheVHostsTemplateFile := TPath.Combine(Result.TemplatesDir, 'httpd-vhosts.conf.tpl');
  Result.VHostIndexTemplateFile := TPath.Combine(Result.TemplatesDir, 'vhost-index.html.tpl');
  Result.MariaDbTemplateFile := TPath.Combine(Result.TemplatesDir, 'mariadb.ini.tpl');
  Result.PhpTemplateFile := TPath.Combine(Result.TemplatesDir, 'php.ini.tpl');
  Result.ApacheHttpdConfFile := TPath.Combine(Result.GeneratedConfigDir, 'httpd.conf');
  Result.ApacheSslConfFile := TPath.Combine(Result.GeneratedConfigDir, 'httpd-ssl.conf');
  Result.ApacheVHostsConfFile := TPath.Combine(Result.GeneratedConfigDir, 'httpd-vhosts.conf');
  Result.MariaDbIniFile := TPath.Combine(Result.GeneratedConfigDir, 'mariadb.ini');
  Result.ActivePhpIniFile := TPath.Combine(Result.GeneratedConfigDir, 'php.ini');
  Result.EnvBatFile := TPath.Combine(Result.GeneratedConfigDir, 'env.bat');
end;

procedure TestMissingExecutable;
var
  Output: string;
begin
  AssertTrue(not TProcessManager.RunAndCaptureOutput('Z:\does-not-exist.exe', '', '', Output),
    'Missing executable should fail');
  AssertContains(Output, 'Executable not found', 'Missing executable should report reason');
end;

procedure TestTimeout;
var
  Output: string;
  PingExe: string;
begin
  PingExe := 'C:\Windows\System32\ping.exe';
  AssertTrue(not TProcessManager.RunAndCaptureOutput(
    PingExe,
    '127.0.0.1 -n 30',
    ExtractFileDir(PingExe),
    Output,
    200),
    'Timeout should fail');
  AssertContains(Output, 'Timed out after 200 ms', 'Timeout should report reason');
end;

procedure TestNonZeroExitCode;
var
  Output: string;
  CmdExe: string;
begin
  CmdExe := 'C:\Windows\System32\cmd.exe';
  AssertTrue(not TProcessManager.RunAndCaptureOutput(
    CmdExe,
    '/c exit 7',
    ExtractFileDir(CmdExe),
    Output),
    'Non-zero exit should fail');
  AssertContains(Output, 'Process exited with code 7', 'Non-zero exit should report code');
end;

procedure TestDetachedStartMissingExecutable;
var
  ResultInfo: TProcessStartResult;
begin
  ResultInfo := TProcessManager.StartDetached('Z:\does-not-exist.exe', '', '');
  AssertTrue(not ResultInfo.Success, 'Missing detached executable should fail');
  AssertContains(ResultInfo.ErrorMessage, 'Executable not found', 'Detached start should report reason');
end;

procedure TestStopInvalidPidFails;
begin
  AssertTrue(not TProcessManager.StopProcess(999999999), 'Stopping an invalid PID should fail');
end;

procedure TestWaitInvalidPidFails;
begin
  AssertTrue(not TProcessManager.WaitForExit(999999999, 10), 'Waiting on an invalid PID should fail');
end;

procedure TestStopLiveProcessTerminatesIt;
var
  CmdExe: string;
  StartResult: TProcessStartResult;
begin
  CmdExe := 'C:\Windows\System32\cmd.exe';
  StartResult := TProcessManager.StartDetached(
    CmdExe,
    '/c "ping 127.0.0.1 -n 30 >nul"',
    ExtractFileDir(CmdExe));
  AssertTrue(StartResult.Success, 'Live process should start');
  AssertTrue(TProcessManager.IsRunning(StartResult.ProcessId), 'Live process should be running before stop');
  AssertTrue(TProcessManager.StopProcess(StartResult.ProcessId), 'Live process should stop cleanly');
  AssertTrue(not TProcessManager.IsRunning(StartResult.ProcessId), 'Live process should not be running after stop');
end;

procedure TestStaleRuntimeStateCleanup;
var
  RootDir: string;
  Paths: TAppPaths;
  Config: TUniWampConfig;
  Runtime: TUniWampRuntime;
begin
  RootDir := TPath.Combine(TPath.GetTempPath, 'UniWamp-process-stale-' + TGuid.NewGuid.ToString);
  TDirectory.CreateDirectory(RootDir);
  try
    Paths := BuildPaths(RootDir);
    EnsurePortableLayout(Paths);
    Config := TUniWampConfig.Create;
    try
      Config.SetDefaults(Paths);
      Config.ApachePid := 999999;
      Config.ApacheRunning := True;
      Config.MariaDbPid := 999998;
      Config.MariaDbRunning := True;
      Runtime := TUniWampRuntime.Create(Paths, Config);
      try
        AssertTrue(not Runtime.ApacheIsRunning, 'Stale Apache state should be cleared');
        AssertTrue(not Runtime.MariaDbIsRunning, 'Stale MariaDB state should be cleared');
        AssertTrue(Config.ApachePid = 0, 'Stale Apache pid should be cleared');
        AssertTrue(Config.MariaDbPid = 0, 'Stale MariaDB pid should be cleared');
      finally
        Runtime.Free;
      end;
    finally
      Config.Free;
    end;
  finally
    TDirectory.Delete(RootDir, True);
  end;
end;

procedure TestDuplicateStartShortCircuit;
var
  RootDir: string;
  Paths: TAppPaths;
  Config: TUniWampConfig;
  Runtime: TUniWampRuntime;
  StartResult: TProcessStartResult;
  PidFile: string;
  FakeApacheExe: string;
begin
  RootDir := TPath.Combine(TPath.GetTempPath, 'UniWamp-process-live-' + TGuid.NewGuid.ToString);
  TDirectory.CreateDirectory(RootDir);
  try
    Paths := BuildPaths(RootDir);
    EnsurePortableLayout(Paths);
    Config := TUniWampConfig.Create;
    try
      Config.SetDefaults(Paths);
      FakeApacheExe := TPath.Combine(Paths.ApacheBinDir, 'httpd.exe');
      TFile.Copy('C:\Windows\System32\cmd.exe', FakeApacheExe, True);
      StartResult := TProcessManager.StartDetached(FakeApacheExe, '/c "ping 127.0.0.1 -n 30 >nul"', Paths.ApacheBinDir);
      AssertTrue(StartResult.Success, 'Test helper process should start');
      PidFile := TPath.Combine(Paths.LogsDir, 'httpd.pid');
      TFile.WriteAllText(PidFile, StartResult.ProcessId.ToString, TEncoding.UTF8);
      Config.ApachePid := StartResult.ProcessId;
      Config.ApacheRunning := True;

      Runtime := TUniWampRuntime.Create(Paths, Config);
      try
        AssertTrue(Runtime.ApacheIsRunning, 'Live Apache state should be recognized');
        AssertTrue(Config.ApachePid = StartResult.ProcessId, 'Live Apache pid should be preserved');
        AssertTrue(Config.ApacheRunning, 'Live Apache flag should stay set');
      finally
        Runtime.Free;
      end;

      TProcessManager.StopProcess(StartResult.ProcessId);
      TFile.Delete(PidFile);
    finally
      Config.Free;
    end;
  finally
    TDirectory.Delete(RootDir, True);
  end;
end;

procedure TestMariaDbDuplicateStartShortCircuit;
var
  RootDir: string;
  Paths: TAppPaths;
  Config: TUniWampConfig;
  Runtime: TUniWampRuntime;
  StartResult: TProcessStartResult;
  PidFile: string;
  FakeMariaDbExe: string;
begin
  RootDir := TPath.Combine(TPath.GetTempPath, 'UniWamp-process-mariadb-live-' + TGuid.NewGuid.ToString);
  TDirectory.CreateDirectory(RootDir);
  try
    Paths := BuildPaths(RootDir);
    EnsurePortableLayout(Paths);
    Config := TUniWampConfig.Create;
    try
      Config.SetDefaults(Paths);
      FakeMariaDbExe := TPath.Combine(Paths.MariaDbBinDir, 'mariadbd.exe');
      TFile.Copy('C:\Windows\System32\cmd.exe', FakeMariaDbExe, True);
      StartResult := TProcessManager.StartDetached(FakeMariaDbExe, '/c "ping 127.0.0.1 -n 30 >nul"', Paths.MariaDbBinDir);
      AssertTrue(StartResult.Success, 'Test helper process should start');
      PidFile := TPath.Combine(Paths.LogsDir, 'mariadb.pid');
      TFile.WriteAllText(PidFile, StartResult.ProcessId.ToString, TEncoding.UTF8);
      Config.MariaDbPid := StartResult.ProcessId;
      Config.MariaDbRunning := True;

      Runtime := TUniWampRuntime.Create(Paths, Config);
      try
        AssertTrue(Runtime.MariaDbIsRunning, 'Live MariaDB state should be recognized');
        AssertTrue(Config.MariaDbPid = StartResult.ProcessId, 'Live MariaDB pid should be preserved');
        AssertTrue(Config.MariaDbRunning, 'Live MariaDB flag should stay set');
      finally
        Runtime.Free;
      end;

      TProcessManager.StopProcess(StartResult.ProcessId);
      TFile.Delete(PidFile);
    finally
      Config.Free;
    end;
  finally
    TDirectory.Delete(RootDir, True);
  end;
end;

procedure TestDuplicateStartReturnsAlreadyRunning;
var
  RootDir: string;
  Paths: TAppPaths;
  Config: TUniWampConfig;
  Runtime: TUniWampRuntime;
  StartResult: TProcessStartResult;
  PidFile: string;
  ResultInfo: TRuntimeActionResult;
  FakeApacheExe: string;
begin
  RootDir := TPath.Combine(TPath.GetTempPath, 'UniWamp-process-duplicate-start-' + TGuid.NewGuid.ToString);
  TDirectory.CreateDirectory(RootDir);
  try
    Paths := BuildPaths(RootDir);
    EnsurePortableLayout(Paths);
    TDirectory.CreateDirectory(TPath.Combine(Paths.PhpDir, 'php85'));
    TDirectory.CreateDirectory(Paths.ApacheBinDir);
    TFile.WriteAllText(TPath.Combine(Paths.PhpDir, 'php85\php.exe'), '', TEncoding.ASCII);
    TFile.WriteAllText(TPath.Combine(Paths.PhpDir, 'php85\php85apache2_4.dll'), '', TEncoding.ASCII);
    TFile.WriteAllText(Paths.ApacheHttpdConfFile, 'ServerName localhost', TEncoding.UTF8);
    FakeApacheExe := TPath.Combine(Paths.ApacheBinDir, 'httpd.exe');
    TFile.Copy('C:\Windows\System32\cmd.exe', FakeApacheExe, True);
    StartResult := TProcessManager.StartDetached(FakeApacheExe, '/c "ping 127.0.0.1 -n 30 >nul"', Paths.ApacheBinDir);
    AssertTrue(StartResult.Success, 'Test helper process should start');
    PidFile := TPath.Combine(Paths.LogsDir, 'httpd.pid');
    TFile.WriteAllText(PidFile, StartResult.ProcessId.ToString, TEncoding.UTF8);

    Config := TUniWampConfig.Create;
    try
      Config.SetDefaults(Paths);
      Config.SelectedPhpVersion := 'php85';
      Config.ApachePid := StartResult.ProcessId;
      Config.ApacheRunning := True;
      Runtime := TUniWampRuntime.Create(Paths, Config);
      try
        ResultInfo := Runtime.StartApache;
        AssertTrue(ResultInfo.Success, 'Apache start should short-circuit when already running');
        AssertContains(ResultInfo.Message, 'already running', 'Apache duplicate start should report already running');
        AssertTrue(Config.ApachePid = StartResult.ProcessId, 'Apache pid should stay unchanged');
        AssertTrue(Config.ApacheRunning, 'Apache running flag should stay true');
      finally
        Runtime.Free;
      end;
    finally
      Config.Free;
    end;

    TProcessManager.StopProcess(StartResult.ProcessId);
    TFile.Delete(PidFile);
  finally
    TDirectory.Delete(RootDir, True);
  end;
end;

procedure TestMariaDbDuplicateStartReturnsAlreadyRunning;
var
  RootDir: string;
  Paths: TAppPaths;
  Config: TUniWampConfig;
  Runtime: TUniWampRuntime;
  StartResult: TProcessStartResult;
  PidFile: string;
  ResultInfo: TRuntimeActionResult;
  FakeMariaDbExe: string;
begin
  RootDir := TPath.Combine(TPath.GetTempPath, 'UniWamp-process-mariadb-duplicate-start-' + TGuid.NewGuid.ToString);
  TDirectory.CreateDirectory(RootDir);
  try
    Paths := BuildPaths(RootDir);
    EnsurePortableLayout(Paths);
    TTemplateRenderer.EnsureDefaultTemplates(Paths);
    TDirectory.CreateDirectory(Paths.MariaDbBinDir);
    TFile.WriteAllText(TPath.Combine(Paths.MariaDbBinDir, 'mariadbd.exe'), '', TEncoding.ASCII);
    TFile.WriteAllText(TPath.Combine(Paths.MariaDbBinDir, 'mariadb-install-db.exe'), '', TEncoding.ASCII);
    TFile.WriteAllText(TPath.Combine(Paths.MariaDbBinDir, 'mysqladmin.exe'), '', TEncoding.ASCII);
    TFile.WriteAllText(TPath.Combine(Paths.GeneratedConfigDir, 'mariadb.ini'), 'port=3307', TEncoding.UTF8);
    FakeMariaDbExe := TPath.Combine(Paths.MariaDbBinDir, 'mariadbd.exe');
    TFile.Copy('C:\Windows\System32\cmd.exe', FakeMariaDbExe, True);
    StartResult := TProcessManager.StartDetached(FakeMariaDbExe, '/c "ping 127.0.0.1 -n 30 >nul"', Paths.MariaDbBinDir);
    AssertTrue(StartResult.Success, 'Test helper process should start');
    PidFile := TPath.Combine(Paths.LogsDir, 'mariadb.pid');
    TFile.WriteAllText(PidFile, StartResult.ProcessId.ToString, TEncoding.UTF8);

    Config := TUniWampConfig.Create;
    try
      Config.SetDefaults(Paths);
      Config.MariaDbPid := StartResult.ProcessId;
      Config.MariaDbRunning := True;
      Runtime := TUniWampRuntime.Create(Paths, Config);
      try
        ResultInfo := Runtime.StartMariaDb;
        AssertTrue(ResultInfo.Success, 'MariaDB start should short-circuit when already running');
        AssertContains(ResultInfo.Message, 'already running', 'MariaDB duplicate start should report already running');
        AssertTrue(Config.MariaDbPid = StartResult.ProcessId, 'MariaDB pid should stay unchanged');
        AssertTrue(Config.MariaDbRunning, 'MariaDB running flag should stay true');
      finally
        Runtime.Free;
      end;
    finally
      Config.Free;
    end;

    TProcessManager.StopProcess(StartResult.ProcessId);
    TFile.Delete(PidFile);
  finally
    TDirectory.Delete(RootDir, True);
  end;
end;

procedure TestRestartFailureMessages;
var
  RootDir: string;
  Paths: TAppPaths;
  Config: TUniWampConfig;
  Runtime: TUniWampRuntime;
  ResultInfo: TRuntimeActionResult;
begin
  RootDir := TPath.Combine(TPath.GetTempPath, 'UniWamp-process-restart-' + TGuid.NewGuid.ToString);
  TDirectory.CreateDirectory(RootDir);
  try
    Paths := BuildPaths(RootDir);
    EnsurePortableLayout(Paths);
    Config := TUniWampConfig.Create;
    try
      Config.SetDefaults(Paths);
      Config.SelectedPhpVersion := 'php-missing';
      Runtime := TUniWampRuntime.Create(Paths, Config);
      try
        ResultInfo := Runtime.RestartApache;
        AssertTrue(not ResultInfo.Success, 'Apache restart should fail without runtime files');
        AssertContains(ResultInfo.Message, 'Apache restart failed during start', 'Apache restart should identify start phase');
        AssertContains(Config.LastApacheError, 'Apache restart failed during start', 'Apache restart should store the failure');

        ResultInfo := Runtime.RestartMariaDb;
        AssertTrue(not ResultInfo.Success, 'MariaDB restart should fail without runtime files');
        AssertContains(ResultInfo.Message, 'MariaDB restart failed during start', 'MariaDB restart should identify start phase');
        AssertContains(Config.LastMariaDbError, 'MariaDB restart failed during start', 'MariaDB restart should store the failure');
      finally
        Runtime.Free;
      end;
    finally
      Config.Free;
    end;
  finally
    TDirectory.Delete(RootDir, True);
  end;
end;

procedure TestMissingRuntimeDependencies;
var
  RootDir: string;
  Paths: TAppPaths;
  Config: TUniWampConfig;
  Runtime: TUniWampRuntime;
  ResultInfo: TRuntimeActionResult;
begin
  RootDir := TPath.Combine(TPath.GetTempPath, 'UniWamp-process-deps-' + TGuid.NewGuid.ToString);
  TDirectory.CreateDirectory(RootDir);
  try
    Paths := BuildPaths(RootDir);
    EnsurePortableLayout(Paths);
    Config := TUniWampConfig.Create;
    try
      Config.SetDefaults(Paths);
      Runtime := TUniWampRuntime.Create(Paths, Config);
      try
        ResultInfo := Runtime.StartApache;
        AssertTrue(not ResultInfo.Success, 'Apache should fail without runtime dependencies');
        AssertContains(ResultInfo.Message, 'Selected PHP runtime is missing', 'Apache dependency failure should be explicit');
        AssertContains(Config.LastApacheError, 'Selected PHP runtime is missing', 'Apache dependency failure should be stored');

        ResultInfo := Runtime.StartMariaDb;
        AssertTrue(not ResultInfo.Success, 'MariaDB should fail without runtime dependencies');
        AssertContains(ResultInfo.Message, 'MariaDB initializer not found', 'MariaDB dependency failure should be explicit');
        AssertContains(Config.LastMariaDbError, 'MariaDB initializer not found', 'MariaDB dependency failure should be stored');
      finally
        Runtime.Free;
      end;
    finally
      Config.Free;
    end;
  finally
    TDirectory.Delete(RootDir, True);
  end;
end;

procedure TestManagedHostsSyncUsesOverride;
var
  RootDir: string;
  Paths: TAppPaths;
  Config: TUniWampConfig;
  Runtime: TUniWampRuntime;
  HostsFile: string;
  HostsBackup: string;
  ResultInfo: TRuntimeActionResult;
  HostsText: string;
begin
  RootDir := TPath.Combine(TPath.GetTempPath, 'UniWamp-process-hosts-' + TGuid.NewGuid.ToString);
  TDirectory.CreateDirectory(RootDir);
  try
    Paths := BuildPaths(RootDir);
    EnsurePortableLayout(Paths);
    TTemplateRenderer.EnsureDefaultTemplates(Paths);
    HostsFile := TPath.Combine(RootDir, 'hosts');
    HostsBackup := HostsFile + '.bak';
    TFile.WriteAllText(HostsFile, '127.0.0.1 localhost' + sLineBreak, TEncoding.ASCII);
    SetEnvironmentVariable('UNIWAMP_HOSTS_FILE', PChar(HostsFile));
    Config := TUniWampConfig.Create;
    try
      Config.SetDefaults(Paths);
      Config.SelectedPhpVersion := '';
      Runtime := TUniWampRuntime.Create(Paths, Config);
      try
        ResultInfo := Runtime.AddVHost('example.test', TPath.Combine(RootDir, 'site'), '', False);
        AssertTrue(ResultInfo.Success, 'VHost add should succeed with hosts override');
        HostsText := TFile.ReadAllText(HostsFile, TEncoding.ASCII);
        AssertContains(HostsText, '# BEGIN UniWamp Managed Hosts', 'Managed hosts block should be written');
        AssertContains(HostsText, '127.0.0.1 example.test', 'Managed hosts block should contain the vhost');
        AssertTrue(FileExists(HostsBackup), 'Hosts backup should be created before update');
      finally
        Runtime.Free;
      end;
    finally
      Config.Free;
      SetEnvironmentVariable('UNIWAMP_HOSTS_FILE', nil);
    end;
  finally
    TDirectory.Delete(RootDir, True);
  end;
end;

procedure TestManagedHostsSyncReportsReadOnlyFailure;
var
  RootDir: string;
  Paths: TAppPaths;
  Config: TUniWampConfig;
  Runtime: TUniWampRuntime;
  HostsFile: string;
  ResultInfo: TRuntimeActionResult;
begin
  RootDir := TPath.Combine(TPath.GetTempPath, 'UniWamp-process-hosts-readonly-' + TGuid.NewGuid.ToString);
  TDirectory.CreateDirectory(RootDir);
  try
    Paths := BuildPaths(RootDir);
    EnsurePortableLayout(Paths);
    TTemplateRenderer.EnsureDefaultTemplates(Paths);
    HostsFile := TPath.Combine(RootDir, 'hosts-dir');
    TDirectory.CreateDirectory(HostsFile);
    SetEnvironmentVariable('UNIWAMP_HOSTS_FILE', PChar(HostsFile));
    Config := TUniWampConfig.Create;
    try
      Config.SetDefaults(Paths);
      Runtime := TUniWampRuntime.Create(Paths, Config);
      try
        ResultInfo := Runtime.AddVHost('readonly.test', TPath.Combine(RootDir, 'readonly-site'), '', False);
        AssertTrue(ResultInfo.Success, 'VHost add should still save the vHost when hosts sync fails');
        AssertContains(ResultInfo.Message, 'Hosts file update failed', 'Hosts sync failure should be reported');
        AssertTrue(Config.LastHostsSyncStatus = 'Hosts update failed', 'Hosts sync status should reflect failure');
      finally
        Runtime.Free;
      end;
    finally
      Config.Free;
      SetEnvironmentVariable('UNIWAMP_HOSTS_FILE', nil);
    end;
  finally
    TDirectory.Delete(RootDir, True);
  end;
end;

procedure TestDeleteVHostPreservesUnmanagedHostsEntries;
var
  RootDir: string;
  Paths: TAppPaths;
  Config: TUniWampConfig;
  Runtime: TUniWampRuntime;
  HostsFile: string;
  HostsText: string;
  ResultInfo: TRuntimeActionResult;
begin
  RootDir := TPath.Combine(TPath.GetTempPath, 'UniWamp-process-hosts-delete-' + TGuid.NewGuid.ToString);
  TDirectory.CreateDirectory(RootDir);
  try
    Paths := BuildPaths(RootDir);
    EnsurePortableLayout(Paths);
    TTemplateRenderer.EnsureDefaultTemplates(Paths);
    HostsFile := TPath.Combine(RootDir, 'hosts');
    TFile.WriteAllText(HostsFile,
      '127.0.0.1 localhost' + sLineBreak +
      '10.0.0.10 external.example' + sLineBreak,
      TEncoding.ASCII);
    SetEnvironmentVariable('UNIWAMP_HOSTS_FILE', PChar(HostsFile));
    Config := TUniWampConfig.Create;
    try
      Config.SetDefaults(Paths);
      Runtime := TUniWampRuntime.Create(Paths, Config);
      try
        ResultInfo := Runtime.AddVHost('example.test', TPath.Combine(RootDir, 'site'), '', False);
        AssertTrue(ResultInfo.Success, 'VHost add should succeed before delete');
        ResultInfo := Runtime.DeleteVHost('example.test');
        AssertTrue(ResultInfo.Success, 'VHost delete should succeed');
        HostsText := TFile.ReadAllText(HostsFile, TEncoding.ASCII);
        AssertContains(HostsText, '10.0.0.10 external.example', 'Unmanaged hosts entries should be preserved');
        AssertTrue(Pos('example.test', HostsText) = 0, 'Deleted managed host should be removed from the hosts file');
      finally
        Runtime.Free;
      end;
    finally
      Config.Free;
      SetEnvironmentVariable('UNIWAMP_HOSTS_FILE', nil);
    end;
  finally
    TDirectory.Delete(RootDir, True);
  end;
end;

procedure TestDeleteSslVHostRemovesCertificateFiles;
var
  RootDir: string;
  Paths: TAppPaths;
  Config: TUniWampConfig;
  Runtime: TUniWampRuntime;
  Entry: TVHostEntry;
  CertFile: string;
  KeyFile: string;
begin
  RootDir := TPath.Combine(TPath.GetTempPath, 'UniWamp-process-ssl-delete-' + TGuid.NewGuid.ToString);
  TDirectory.CreateDirectory(RootDir);
  try
    Paths := BuildPaths(RootDir);
    EnsurePortableLayout(Paths);
    TTemplateRenderer.EnsureDefaultTemplates(Paths);
    Config := TUniWampConfig.Create;
    try
      Config.SetDefaults(Paths);
      Entry.ServerName := 'secure.test';
      Entry.ServerAliases := '';
      Entry.DocumentRoot := TPath.Combine(RootDir, 'site');
      Entry.EnableSsl := True;
      CertFile := TPath.Combine(Paths.SslDir, TPath.Combine('vhosts', TPath.Combine('secure.test', 'server.crt')));
      KeyFile := TPath.Combine(Paths.SslDir, TPath.Combine('vhosts', TPath.Combine('secure.test', 'server.key')));
      Entry.SslCertFile := CertFile;
      Entry.SslKeyFile := KeyFile;
      Config.AddOrUpdateVHost(Entry);
      EnsureDirectory(ExtractFileDir(CertFile));
      TFile.WriteAllText(CertFile, 'cert', TEncoding.ASCII);
      TFile.WriteAllText(KeyFile, 'key', TEncoding.ASCII);

      Runtime := TUniWampRuntime.Create(Paths, Config);
      try
        AssertTrue(Runtime.DeleteVHost('secure.test').Success, 'SSL vHost delete should succeed');
        AssertTrue(not TFile.Exists(CertFile), 'SSL certificate should be removed when the vHost is deleted');
        AssertTrue(not TFile.Exists(KeyFile), 'SSL key should be removed when the vHost is deleted');
      finally
        Runtime.Free;
      end;
    finally
      Config.Free;
    end;
  finally
    TDirectory.Delete(RootDir, True);
  end;
end;

procedure TestMariaDbStartReportsPortConflict;
var
  RootDir: string;
  Paths: TAppPaths;
  Config: TUniWampConfig;
  Runtime: TUniWampRuntime;
  ResultInfo: TRuntimeActionResult;
  PortSocket: TSocket;
begin
  RootDir := TPath.Combine(TPath.GetTempPath, 'UniWamp-process-mariadb-port-conflict-' + TGuid.NewGuid.ToString);
  TDirectory.CreateDirectory(RootDir);
  try
    Paths := BuildPaths(RootDir);
    EnsurePortableLayout(Paths);
    AssertTrue(ReserveTcpPort(3307, PortSocket), 'Port listener should start');
    AssertTrue(not IsTcpPortAvailable(3307), 'Database port should be occupied before starting MariaDB');

    Config := TUniWampConfig.Create;
    try
      Config.SetDefaults(Paths);
      Config.DatabasePort := 3307;
      Runtime := TUniWampRuntime.Create(Paths, Config);
      try
        ResultInfo := Runtime.StartMariaDb;
        AssertTrue(not ResultInfo.Success, 'MariaDB should fail when the database port is occupied');
        AssertContains(ResultInfo.Message, 'Database port 3307 is already in use', 'MariaDB port conflict should be reported');
        AssertTrue(Config.MariaDbPid = 0, 'MariaDB pid should remain cleared on port conflict');
        AssertTrue(not Config.MariaDbRunning, 'MariaDB running flag should remain false on port conflict');
        AssertContains(Config.LastMariaDbError, 'Database port 3307 is already in use', 'MariaDB port conflict should persist in the error state');
      finally
        Runtime.Free;
      end;
    finally
      Config.Free;
    end;

    ReleaseTcpPort(PortSocket);
  finally
    TDirectory.Delete(RootDir, True);
  end;
end;

procedure TestApacheStartReportsPortConflictOwner;
var
  RootDir: string;
  Paths: TAppPaths;
  Config: TUniWampConfig;
  Runtime: TUniWampRuntime;
  ResultInfo: TRuntimeActionResult;
  PortSocket: TSocket;
begin
  RootDir := TPath.Combine(TPath.GetTempPath, 'UniWamp-process-apache-port-conflict-' + TGuid.NewGuid.ToString);
  TDirectory.CreateDirectory(RootDir);
  PortSocket := INVALID_SOCKET;
  try
    Paths := BuildPaths(RootDir);
    EnsurePortableLayout(Paths);
    TTemplateRenderer.EnsureDefaultTemplates(Paths);
    AssertTrue(ReserveTcpPort(8080, PortSocket), 'HTTP port should be occupied for Apache conflict test');
    Config := TUniWampConfig.Create;
    try
      Config.SetDefaults(Paths);
      TDirectory.CreateDirectory(TPath.Combine(Paths.PhpDir, 'php85'));
      TFile.WriteAllText(TPath.Combine(Paths.PhpDir, 'php85\php.exe'), '', TEncoding.ASCII);
      TFile.WriteAllText(TPath.Combine(Paths.PhpDir, 'php85\php85apache2_4.dll'), '', TEncoding.ASCII);
      Config.SelectedPhpVersion := 'php85';
      Runtime := TUniWampRuntime.Create(Paths, Config);
      try
        ResultInfo := Runtime.StartApache;
        AssertTrue(not ResultInfo.Success, 'Apache should fail when the HTTP port is occupied');
        AssertContains(ResultInfo.Message, 'HTTP port 8080 is already in use', 'Apache port conflict should be reported');
        AssertContains(ResultInfo.Message, 'by ', 'Apache port conflict should include the owning process when available');
        AssertContains(Config.LastApacheError, 'HTTP port 8080 is already in use', 'Apache port conflict should persist in the error state');
      finally
        Runtime.Free;
      end;
    finally
      Config.Free;
    end;
  finally
    ReleaseTcpPort(PortSocket);
    TDirectory.Delete(RootDir, True);
  end;
end;

procedure TestGenerateAllConfigsStaysInGeneratedConfigDir;
var
  RootDir: string;
  Paths: TAppPaths;
  Config: TUniWampConfig;
  Runtime: TUniWampRuntime;
  ApacheConfigText: string;
  MariaDbConfigText: string;
  PhpConfigText: string;
begin
  RootDir := TPath.Combine(TPath.GetTempPath, 'UniWamp-process-generated-configs-' + TGuid.NewGuid.ToString);
  TDirectory.CreateDirectory(RootDir);
  try
    Paths := BuildPaths(RootDir);
    EnsurePortableLayout(Paths);
    TTemplateRenderer.EnsureDefaultTemplates(Paths);
    TDirectory.CreateDirectory(TPath.Combine(Paths.PhpDir, 'php85'));
    TFile.WriteAllText(TPath.Combine(Paths.PhpDir, 'php85\php.exe'), '', TEncoding.ASCII);
    TFile.WriteAllText(TPath.Combine(Paths.PhpDir, 'php85\php85apache2_4.dll'), '', TEncoding.ASCII);
    Config := TUniWampConfig.Create;
    try
      Config.SetDefaults(Paths);
      Config.SelectedPhpVersion := 'php85';
      Runtime := TUniWampRuntime.Create(Paths, Config);
      try
        Runtime.GenerateAllConfigs;
        AssertTrue(TFile.Exists(Paths.ApacheHttpdConfFile), 'Apache config should be generated under config\generated');
        AssertTrue(TFile.Exists(Paths.MariaDbIniFile), 'MariaDB config should be generated under config\generated');
        AssertTrue(TFile.Exists(Paths.ActivePhpIniFile), 'PHP config should be generated under config\generated');
        ApacheConfigText := TFile.ReadAllText(Paths.ApacheHttpdConfFile, TEncoding.UTF8);
        MariaDbConfigText := TFile.ReadAllText(Paths.MariaDbIniFile, TEncoding.UTF8);
        PhpConfigText := TFile.ReadAllText(Paths.ActivePhpIniFile, TEncoding.UTF8);
        AssertContains(ApacheConfigText, Paths.GeneratedConfigDir, 'Apache config should reference the generated config directory');
        AssertContains(PhpConfigText, TPath.Combine(Paths.PhpDir, 'php85'), 'PHP config should reference the selected runtime');
        AssertTrue(not TFile.Exists(TPath.Combine(Paths.ApacheDir, 'httpd.conf')), 'Vendor Apache tree should not receive generated config files');
        AssertTrue(not TFile.Exists(TPath.Combine(Paths.MariaDbDir, 'mariadb.ini')), 'Vendor MariaDB tree should not receive generated config files');
      finally
        Runtime.Free;
      end;
    finally
      Config.Free;
    end;
  finally
    TDirectory.Delete(RootDir, True);
  end;
end;

procedure TestMariaDbInitializationBacksUpDirtyDataDirectory;
var
  RootDir: string;
  Paths: TAppPaths;
  Config: TUniWampConfig;
  Runtime: TUniWampRuntime;
  DataDir: string;
  MysqlDir: string;
  ExistingBackups: TArray<string>;
  ResultInfo: TRuntimeActionResult;
  HelperExe: string;
begin
  RootDir := TPath.Combine(TPath.GetTempPath, 'UniWamp-process-mariadb-init-' + TGuid.NewGuid.ToString);
  TDirectory.CreateDirectory(RootDir);
  try
    Paths := BuildPaths(RootDir);
    EnsurePortableLayout(Paths);
    TTemplateRenderer.EnsureDefaultTemplates(Paths);
    TDirectory.CreateDirectory(Paths.MariaDbBinDir);
    HelperExe := TPath.Combine(Paths.MariaDbBinDir, 'mariadb-install-db.exe');
    TFile.Copy('C:\Windows\System32\cmd.exe', HelperExe, True);
    DataDir := TPath.Combine(Paths.MariaDbDir, 'data');
    MysqlDir := TPath.Combine(DataDir, 'mysql');
    TDirectory.CreateDirectory(DataDir);
    TDirectory.CreateDirectory(MysqlDir);
    TFile.WriteAllText(TPath.Combine(DataDir, 'stale.txt'), 'stale', TEncoding.UTF8);
    Config := TUniWampConfig.Create;
    try
      Config.SetDefaults(Paths);
      Runtime := TUniWampRuntime.Create(Paths, Config);
      try
        ResultInfo := Runtime.StartMariaDb;
        AssertTrue(not ResultInfo.Success, 'MariaDB start should fail for a dirty data directory with a fake bootstrap helper');
        ExistingBackups := TDirectory.GetDirectories(Paths.MariaDbDir, 'data.bak-*');
        AssertTrue(Length(ExistingBackups) > 0, 'Dirty MariaDB data directory should be backed up');
        AssertContains(ResultInfo.Message, 'MariaDB initialization', 'MariaDB init failure should be reported');
        AssertContains(ResultInfo.Message, 'dirty data directory was backed up', 'MariaDB init failure should mention the backup recovery');
      finally
        Runtime.Free;
      end;
    finally
      Config.Free;
    end;
  finally
    TDirectory.Delete(RootDir, True);
  end;
end;

procedure TestAddVHostNormalizesAliasesAndGeneratesConfig;
var
  RootDir: string;
  Paths: TAppPaths;
  Config: TUniWampConfig;
  Runtime: TUniWampRuntime;
  ResultInfo: TRuntimeActionResult;
  VHostConfigText: string;
  StarterPageText: string;
begin
  RootDir := TPath.Combine(TPath.GetTempPath, 'UniWamp-process-vhost-' + TGuid.NewGuid.ToString);
  TDirectory.CreateDirectory(RootDir);
  try
    Paths := BuildPaths(RootDir);
    EnsurePortableLayout(Paths);
    TTemplateRenderer.EnsureDefaultTemplates(Paths);
    Config := TUniWampConfig.Create;
    try
      Config.SetDefaults(Paths);
      Runtime := TUniWampRuntime.Create(Paths, Config);
      try
        ResultInfo := Runtime.AddVHost(
          'example.test',
          TPath.Combine(RootDir, 'site'),
          'alias1.test, alias2.test',
          False);
        AssertTrue(ResultInfo.Success, 'VHost add should succeed');
        AssertContains(ResultInfo.Message, 'VHost saved', 'VHost add should report success');
        VHostConfigText := TFile.ReadAllText(Paths.ApacheVHostsConfFile, TEncoding.UTF8);
        AssertContains(VHostConfigText, 'ServerName example.test', 'VHost config should include the server name');
        AssertContains(VHostConfigText, 'ServerAlias alias1.test alias2.test', 'VHost aliases should be normalized');
        StarterPageText := TFile.ReadAllText(TPath.Combine(RootDir, 'site\index.html'), TEncoding.UTF8);
        AssertContains(StarterPageText, 'example.test is ready', 'Starter page should mention the vHost name');
        AssertContains(StarterPageText, 'Document Root', 'Starter page should include document root label');
        AssertTrue(Length(Config.VHosts) = 1, 'VHost should be stored in the config');
        AssertTrue(SameText(Config.VHosts[0].ServerAliases, 'alias1.test alias2.test'),
          'Stored aliases should be normalized');
      finally
        Runtime.Free;
      end;
    finally
      Config.Free;
    end;
  finally
    TDirectory.Delete(RootDir, True);
  end;
end;

procedure TestAddVHostRejectsInvalidInputs;
var
  RootDir: string;
  Paths: TAppPaths;
  Config: TUniWampConfig;
  Runtime: TUniWampRuntime;
  ResultInfo: TRuntimeActionResult;
  SiteDir: string;
begin
  RootDir := TPath.Combine(TPath.GetTempPath, 'UniWamp-process-vhost-invalid-' + TGuid.NewGuid.ToString);
  TDirectory.CreateDirectory(RootDir);
  try
    Paths := BuildPaths(RootDir);
    EnsurePortableLayout(Paths);
    TTemplateRenderer.EnsureDefaultTemplates(Paths);
    Config := TUniWampConfig.Create;
    try
      Config.SetDefaults(Paths);
      Runtime := TUniWampRuntime.Create(Paths, Config);
      try
        SiteDir := TPath.Combine(RootDir, 'site');
        ResultInfo := Runtime.AddVHost('bad host name', SiteDir, 'alias1.test, alias2.test', False);
        AssertTrue(not ResultInfo.Success, 'Invalid vHost server name should be rejected');
        AssertContains(ResultInfo.Message, 'Server name must be a simple local host name', 'Invalid server name should be reported');
        AssertTrue(not TDirectory.Exists(SiteDir), 'Rejected vHost should not create the site directory');

        ResultInfo := Runtime.AddVHost('example.test', 'bad<root>', '', False);
        AssertTrue(not ResultInfo.Success, 'Invalid vHost document root should be rejected');
        AssertContains(ResultInfo.Message, 'Document root contains invalid path characters', 'Invalid document root should be reported');
      finally
        Runtime.Free;
      end;
    finally
      Config.Free;
    end;
  finally
    TDirectory.Delete(RootDir, True);
  end;
end;

procedure TestGenerateSslCertificateReportsMissingOpenSsl;
var
  RootDir: string;
  Paths: TAppPaths;
  Config: TUniWampConfig;
  Runtime: TUniWampRuntime;
  ResultInfo: TRuntimeActionResult;
begin
  RootDir := TPath.Combine(TPath.GetTempPath, 'UniWamp-process-ssl-' + TGuid.NewGuid.ToString);
  TDirectory.CreateDirectory(RootDir);
  try
    Paths := BuildPaths(RootDir);
    EnsurePortableLayout(Paths);
    Config := TUniWampConfig.Create;
    try
      Config.SetDefaults(Paths);
      Runtime := TUniWampRuntime.Create(Paths, Config);
      try
        ResultInfo := Runtime.GenerateSslCertificate;
        AssertTrue(not ResultInfo.Success, 'SSL generation should fail when OpenSSL is unavailable');
        AssertContains(ResultInfo.Message, 'OpenSSL executable not found', 'SSL failure should report the missing executable');
      finally
        Runtime.Free;
      end;
    finally
      Config.Free;
    end;
  finally
    TDirectory.Delete(RootDir, True);
  end;
end;

procedure TestApacheStartSyncsPhpVersionSelection;
var
  RootDir: string;
  Paths: TAppPaths;
  Config: TUniWampConfig;
  Runtime: TUniWampRuntime;
  ResultInfo: TRuntimeActionResult;
  ApacheExePath: string;
begin
  RootDir := TPath.Combine(TPath.GetTempPath, 'UniWamp-process-php-sync-' + TGuid.NewGuid.ToString);
  TDirectory.CreateDirectory(RootDir);
  try
    Paths := BuildPaths(RootDir);
    EnsurePortableLayout(Paths);
    TTemplateRenderer.EnsureDefaultTemplates(Paths);
    TDirectory.CreateDirectory(TPath.Combine(Paths.PhpDir, 'php83'));
    TFile.WriteAllText(TPath.Combine(Paths.PhpDir, 'php83\php.exe'), '', TEncoding.ASCII);
    TFile.WriteAllText(TPath.Combine(Paths.PhpDir, 'php83\php83apache2_4.dll'), '', TEncoding.ASCII);
    TDirectory.CreateDirectory(Paths.ApacheBinDir);
    ApacheExePath := TPath.Combine(Paths.ApacheBinDir, 'httpd.exe');
    TFile.Copy('C:\Windows\System32\robocopy.exe', ApacheExePath, True);

    Config := TUniWampConfig.Create;
    try
      Config.SetDefaults(Paths);
      Config.SelectedPhpVersion := 'php-missing';
      Runtime := TUniWampRuntime.Create(Paths, Config);
      try
        ResultInfo := Runtime.StartApache;
        AssertTrue(Config.SelectedPhpVersion = 'php83', 'Apache start should sync to the installed PHP version');
        AssertTrue(not ResultInfo.Success, 'Apache start should still fail because the Apache stub is not a real httpd binary');
        AssertTrue(Config.LastApacheError <> '', 'Apache start should set an error message');
      finally
        Runtime.Free;
      end;
    finally
      Config.Free;
    end;
  finally
    TDirectory.Delete(RootDir, True);
  end;
end;

procedure TestApacheStartReportsMissingVisualCRuntime;
var
  RootDir: string;
  Paths: TAppPaths;
  Config: TUniWampConfig;
  Runtime: TUniWampRuntime;
  ResultInfo: TRuntimeActionResult;
  PreviousOverride: string;
begin
  RootDir := TPath.Combine(TPath.GetTempPath, 'UniWamp-process-apache-vc-runtime-' + TGuid.NewGuid.ToString);
  TDirectory.CreateDirectory(RootDir);
  try
    Paths := BuildPaths(RootDir);
    EnsurePortableLayout(Paths);
    TTemplateRenderer.EnsureDefaultTemplates(Paths);
    TDirectory.CreateDirectory(TPath.Combine(Paths.PhpDir, 'php83'));
    TFile.WriteAllText(TPath.Combine(Paths.PhpDir, 'php83\php.exe'), '', TEncoding.ASCII);
    TFile.WriteAllText(TPath.Combine(Paths.PhpDir, 'php83\php83apache2_4.dll'), '', TEncoding.ASCII);
    TDirectory.CreateDirectory(Paths.ApacheBinDir);
    TFile.Copy('C:\Windows\System32\robocopy.exe', TPath.Combine(Paths.ApacheBinDir, 'httpd.exe'), True);

    Config := TUniWampConfig.Create;
    try
      Config.SetDefaults(Paths);
      Runtime := TUniWampRuntime.Create(Paths, Config);
      try
        PreviousOverride := GetEnvironmentVariable('UNIWAMP_FORCE_MISSING_VC_RUNTIME');
        SetEnvironmentVariable('UNIWAMP_FORCE_MISSING_VC_RUNTIME', '1');
        try
          ResultInfo := Runtime.StartApache;
        finally
          if PreviousOverride = '' then
            SetEnvironmentVariable('UNIWAMP_FORCE_MISSING_VC_RUNTIME', nil)
          else
            SetEnvironmentVariable('UNIWAMP_FORCE_MISSING_VC_RUNTIME', PChar(PreviousOverride));
        end;
        AssertTrue(not ResultInfo.Success, 'Apache start should fail when the VC++ runtime prerequisite is missing');
        AssertContains(ResultInfo.Message, 'vc_redist.x64', 'Apache start should report the required Visual C++ redistributable');
        AssertContains(Config.LastApacheError, 'Apache Lounge VS18', 'Apache failure state should preserve the VC++ runtime guidance');
      finally
        Runtime.Free;
      end;
    finally
      Config.Free;
    end;
  finally
    TDirectory.Delete(RootDir, True);
  end;
end;

procedure TestSyncPhpVersionsPrefersCompatibleRuntime;
var
  RootDir: string;
  Paths: TAppPaths;
  Config: TUniWampConfig;
  Runtime: TUniWampRuntime;
begin
  RootDir := TPath.Combine(TPath.GetTempPath, 'UniWamp-process-php-sync-compatible-' + TGuid.NewGuid.ToString);
  TDirectory.CreateDirectory(RootDir);
  try
    Paths := BuildPaths(RootDir);
    EnsurePortableLayout(Paths);
    TDirectory.CreateDirectory(TPath.Combine(Paths.PhpDir, 'php81'));
    TDirectory.CreateDirectory(TPath.Combine(Paths.PhpDir, 'php83'));
    TFile.WriteAllText(TPath.Combine(Paths.PhpDir, 'php81\php.exe'), '', TEncoding.ASCII);
    TFile.WriteAllText(TPath.Combine(Paths.PhpDir, 'php83\php.exe'), '', TEncoding.ASCII);
    TFile.WriteAllText(TPath.Combine(Paths.PhpDir, 'php83\php83apache2_4.dll'), '', TEncoding.ASCII);

    Config := TUniWampConfig.Create;
    try
      Config.SetDefaults(Paths);
      Config.SelectedPhpVersion := 'php81';
      Runtime := TUniWampRuntime.Create(Paths, Config);
      try
        Runtime.SyncPhpVersions;
        AssertTrue(Config.SelectedPhpVersion = 'php83', 'PHP sync should prefer a version with an Apache module');
        AssertTrue(Length(Config.PhpVersions) = 2, 'PHP sync should still capture detected versions');
      finally
        Runtime.Free;
      end;
    finally
      Config.Free;
    end;
  finally
    TDirectory.Delete(RootDir, True);
  end;
end;

procedure TestSyncNodeVersionsPrefersExecutableRuntime;
var
  RootDir: string;
  Paths: TAppPaths;
  Config: TUniWampConfig;
  Runtime: TUniWampRuntime;
begin
  RootDir := TPath.Combine(TPath.GetTempPath, 'UniWamp-process-node-sync-compatible-' + TGuid.NewGuid.ToString);
  TDirectory.CreateDirectory(RootDir);
  try
    Paths := BuildPaths(RootDir);
    EnsurePortableLayout(Paths);
    TDirectory.CreateDirectory(TPath.Combine(Paths.NodeDir, 'node-a'));
    TDirectory.CreateDirectory(TPath.Combine(Paths.NodeDir, 'node-b'));
    TFile.WriteAllText(TPath.Combine(Paths.NodeDir, 'node-a\node.exe'), '', TEncoding.ASCII);

    Config := TUniWampConfig.Create;
    try
      Config.SetDefaults(Paths);
      Config.SelectedNodeVersion := 'node-b';
      Runtime := TUniWampRuntime.Create(Paths, Config);
      try
        Runtime.SyncNodeVersions;
        AssertTrue(Config.SelectedNodeVersion = 'node-a', 'Node sync should prefer a runtime with node.exe');
        AssertTrue(Length(Config.NodeVersions) = 2, 'Node sync should still capture detected versions');
      finally
        Runtime.Free;
      end;
    finally
      Config.Free;
    end;
  finally
    TDirectory.Delete(RootDir, True);
  end;
end;

procedure TestStopPathsAreIdempotentWhenAlreadyStopped;
var
  RootDir: string;
  Paths: TAppPaths;
  Config: TUniWampConfig;
  Runtime: TUniWampRuntime;
  ResultInfo: TRuntimeActionResult;
begin
  RootDir := TPath.Combine(TPath.GetTempPath, 'UniWamp-process-stop-idempotent-' + TGuid.NewGuid.ToString);
  TDirectory.CreateDirectory(RootDir);
  try
    Paths := BuildPaths(RootDir);
    EnsurePortableLayout(Paths);
    Config := TUniWampConfig.Create;
    try
      Config.SetDefaults(Paths);
      Config.ApachePid := 0;
      Config.ApacheRunning := False;
      Config.MariaDbPid := 0;
      Config.MariaDbRunning := False;
      Runtime := TUniWampRuntime.Create(Paths, Config);
      try
        ResultInfo := Runtime.StopApache;
        AssertTrue(ResultInfo.Success, 'Stopping Apache when already stopped should succeed');
        AssertContains(ResultInfo.Message, 'Apache stopped', 'Apache stop should report success when already stopped');
        AssertTrue(Config.ApachePid = 0, 'Apache pid should stay cleared');
        AssertTrue(not Config.ApacheRunning, 'Apache running flag should stay false');

        ResultInfo := Runtime.StopMariaDb;
        AssertTrue(ResultInfo.Success, 'Stopping MariaDB when already stopped should succeed');
        AssertContains(ResultInfo.Message, 'MariaDB stopped', 'MariaDB stop should report success when already stopped');
        AssertTrue(Config.MariaDbPid = 0, 'MariaDB pid should stay cleared');
        AssertTrue(not Config.MariaDbRunning, 'MariaDB running flag should stay false');
      finally
        Runtime.Free;
      end;
    finally
      Config.Free;
    end;
  finally
    TDirectory.Delete(RootDir, True);
  end;
end;

procedure TestStopApacheDoesNotKillUnrelatedHttpdProcesses;
var
  RootDir: string;
  Paths: TAppPaths;
  Config: TUniWampConfig;
  Runtime: TUniWampRuntime;
  ResultInfo: TRuntimeActionResult;
  StartResult: TProcessStartResult;
  PortSocket: TSocket;
  FakeApacheDir: string;
  FakeApacheExe: string;
begin
  RootDir := TPath.Combine(TPath.GetTempPath, 'UniWamp-process-stop-unrelated-httpd-' + TGuid.NewGuid.ToString);
  TDirectory.CreateDirectory(RootDir);
  PortSocket := INVALID_SOCKET;
  try
    Paths := BuildPaths(RootDir);
    EnsurePortableLayout(Paths);
    AssertTrue(ReserveTcpPort(8080, PortSocket), 'The HTTP port should be occupied for the unrelated httpd test');
    FakeApacheDir := TPath.Combine(RootDir, 'foreign-apache');
    TDirectory.CreateDirectory(FakeApacheDir);
    FakeApacheExe := TPath.Combine(FakeApacheDir, 'httpd.exe');
    TFile.Copy('C:\Windows\System32\cmd.exe', FakeApacheExe, True);
    StartResult := TProcessManager.StartDetached(FakeApacheExe, '/c "ping 127.0.0.1 -n 30 >nul"', FakeApacheDir);
    AssertTrue(StartResult.Success, 'The unrelated httpd.exe helper should start');

    Config := TUniWampConfig.Create;
    try
      Config.SetDefaults(Paths);
      Config.ApacheRunning := True;
      Config.ApachePid := 0;
      Runtime := TUniWampRuntime.Create(Paths, Config);
      try
        ResultInfo := Runtime.StopApache;
        AssertTrue(ResultInfo.Success, 'StopApache should be idempotent when UniWamp does not own the service');
        AssertContains(ResultInfo.Message, 'Apache stopped', 'StopApache should report the no-op stop result');
        AssertTrue(TProcessManager.IsRunning(StartResult.ProcessId), 'StopApache should not kill an unrelated httpd.exe process');
      finally
        Runtime.Free;
      end;
    finally
      Config.Free;
    end;

    TProcessManager.StopProcess(StartResult.ProcessId);
  finally
    ReleaseTcpPort(PortSocket);
    if TProcessManager.IsRunning(StartResult.ProcessId) then
      TProcessManager.StopProcess(StartResult.ProcessId);
    TDirectory.Delete(RootDir, True);
  end;
end;

procedure TestApacheStartStopsOnConfigValidationFailure;
var
  RootDir: string;
  Paths: TAppPaths;
  Config: TUniWampConfig;
  Runtime: TUniWampRuntime;
  ResultInfo: TRuntimeActionResult;
  ApacheExePath: string;
  PhpExePath: string;
  PhpModulePath: string;
  ConfText: string;
begin
  RootDir := TPath.Combine(TPath.GetTempPath, 'UniWamp-process-apache-validate-' + TGuid.NewGuid.ToString);
  TDirectory.CreateDirectory(RootDir);
  try
    Paths := BuildPaths(RootDir);
    EnsurePortableLayout(Paths);
    TDirectory.CreateDirectory(Paths.ApacheBinDir);
    TDirectory.CreateDirectory(Paths.ApacheConfDir);
    TDirectory.CreateDirectory(TPath.Combine(Paths.PhpDir, 'php85'));
    TDirectory.CreateDirectory(Paths.ApacheDir);
    ApacheExePath := TPath.Combine(Paths.ApacheBinDir, 'httpd.exe');
    PhpExePath := TPath.Combine(Paths.PhpDir, 'php85\php.exe');
    PhpModulePath := TPath.Combine(Paths.PhpDir, 'php85\php85apache2_4.dll');
    AssertTrue(FileExists('C:\Windows\System32\robocopy.exe'), 'Robocopy executable should be available for validation test');
    TFile.Copy('C:\Windows\System32\robocopy.exe', ApacheExePath, True);
    TFile.Copy('C:\Windows\System32\robocopy.exe', PhpExePath, True);
    TFile.WriteAllText(PhpModulePath, '', TEncoding.ASCII);
    ConfText := 'This is not valid Apache configuration text.';
    TFile.WriteAllText(Paths.ApacheHttpdConfFile, ConfText, TEncoding.UTF8);

    Config := TUniWampConfig.Create;
    try
      Config.SetDefaults(Paths);
      Runtime := TUniWampRuntime.Create(Paths, Config);
      try
        ResultInfo := Runtime.StartApache;
        AssertTrue(not ResultInfo.Success, 'Apache start should fail when config validation fails');
        AssertContains(ResultInfo.Message, 'Process exited with code', 'Apache validation failure should surface process output');
        AssertTrue(Config.ApachePid = 0, 'Apache pid should remain cleared on validation failure');
        AssertTrue(not Config.ApacheRunning, 'Apache running flag should remain false on validation failure');
        AssertContains(Config.LastApacheError, 'Process exited with code', 'Apache validation failure should persist in the error state');
      finally
        Runtime.Free;
      end;
    finally
      Config.Free;
    end;
  finally
    TDirectory.Delete(RootDir, True);
  end;
end;

procedure TestRotatedLogAppendsAndTrims;
var
  RootDir: string;
  LogFile: string;
  Lines: TStringList;
  I: Integer;
begin
  RootDir := TPath.Combine(TPath.GetTempPath, 'UniWamp-process-log-' + TGuid.NewGuid.ToString);
  TDirectory.CreateDirectory(RootDir);
  try
    LogFile := TPath.Combine(RootDir, 'activity.log');
    Lines := TStringList.Create;
    try
      for I := 1 to 505 do
        Lines.Add(Format('line-%d', [I]));
      TFile.WriteAllText(LogFile, Lines.Text, TEncoding.UTF8);
    finally
      Lines.Free;
    end;

    AppendRotatedLogLine(LogFile, 'line-506', 500);

    Lines := TStringList.Create;
    try
      Lines.Text := TFile.ReadAllText(LogFile, TEncoding.UTF8);
      AssertTrue(Lines.Count = 500, 'Rotated log should keep only the requested number of lines');
      AssertContains(Lines[0], 'line-7', 'Rotated log should keep the most recent lines');
      AssertContains(Lines[Lines.Count - 1], 'line-506', 'Rotated log should include the new line');
    finally
      Lines.Free;
    end;
  finally
    TDirectory.Delete(RootDir, True);
  end;
end;

procedure TestLogRedactionMasksSecrets;
var
  RootDir: string;
  LogFile: string;
  LogText: string;
begin
  RootDir := TPath.Combine(TPath.GetTempPath, 'UniWamp-process-redact-' + TGuid.NewGuid.ToString);
  TDirectory.CreateDirectory(RootDir);
  try
    LogFile := TPath.Combine(RootDir, 'activity.log');
    AppendRotatedLogLine(LogFile, 'auth password=supersecret token=abc123 secret=top pass=letmein', 500);
    LogText := TFile.ReadAllText(LogFile, TEncoding.UTF8);
    AssertContains(LogText, 'password=[redacted]', 'Password should be redacted');
    AssertContains(LogText, 'token=[redacted]', 'Token should be redacted');
    AssertContains(LogText, 'secret=[redacted]', 'Secret should be redacted');
    AssertContains(LogText, 'pass=[redacted]', 'Pass should be redacted');
    AssertTrue(Pos('supersecret', LogText) = 0, 'Secret value should not remain in log text');
  finally
    TDirectory.Delete(RootDir, True);
  end;
end;

procedure TestLogRedactionLeavesNonSecretsIntact;
var
  SampleText: string;
  RedactedText: string;
begin
  SampleText := 'keep=passwordless keep2=tokenized password=abc;token=xyz&secret=top pass=low';
  RedactedText := RedactSensitiveText(SampleText);
  AssertContains(RedactedText, 'keep=passwordless', 'Non-secret text should be preserved');
  AssertContains(RedactedText, 'keep2=tokenized', 'Non-secret text should be preserved');
  AssertContains(RedactedText, 'password=[redacted]', 'Password should still be redacted');
  AssertContains(RedactedText, 'token=[redacted]', 'Token should still be redacted');
  AssertContains(RedactedText, 'secret=[redacted]', 'Secret should still be redacted');
  AssertContains(RedactedText, 'pass=[redacted]', 'Pass should still be redacted');
end;

procedure TestDiagnosticReportIncludesState;
var
  RootDir: string;
  Paths: TAppPaths;
  Config: TUniWampConfig;
  Runtime: TUniWampRuntime;
  ReportText: string;
begin
  RootDir := TPath.Combine(TPath.GetTempPath, 'UniWamp-process-report-' + TGuid.NewGuid.ToString);
  TDirectory.CreateDirectory(RootDir);
  try
    Paths := BuildPaths(RootDir);
    EnsurePortableLayout(Paths);
    TTemplateRenderer.EnsureDefaultTemplates(Paths);
    Config := TUniWampConfig.Create;
    try
      Config.SetDefaults(Paths);
      Config.HostName := 'report.local';
      Config.DocumentRoot := TPath.Combine(RootDir, 'www');
      Config.SelectedPhpVersion := 'php85';
      Config.SelectedNodeVersion := 'node-v22';
      Config.ApacheRunning := True;
      Config.ApachePid := 1234;
      Config.MariaDbRunning := False;
      Config.MariaDbPid := 0;
      Runtime := TUniWampRuntime.Create(Paths, Config);
      try
        ReportText := Runtime.BuildDiagnosticReport;
        AssertContains(ReportText, 'UniWamp Diagnostic Report', 'Report heading should be present');
        AssertContains(ReportText, 'report.local', 'Report should include host name');
        AssertContains(ReportText, Config.DocumentRoot, 'Report should include document root');
        AssertContains(ReportText, 'php85', 'Report should include selected PHP version');
        AssertContains(ReportText, 'node-v22', 'Report should include selected node version');
        AssertContains(ReportText, 'Apache: running', 'Report should include Apache state');
        AssertContains(ReportText, 'MariaDB: stopped', 'Report should include MariaDB state');
        AssertContains(ReportText, Paths.AppRoot, 'Report should include app root');
      finally
        Runtime.Free;
      end;
    finally
      Config.Free;
    end;
  finally
    TDirectory.Delete(RootDir, True);
  end;
end;

procedure TestDiagnosticReportOmitsSensitiveValues;
var
  RootDir: string;
  Paths: TAppPaths;
  Config: TUniWampConfig;
  Runtime: TUniWampRuntime;
  ReportText: string;
  ErrorMessage: string;
begin
  RootDir := TPath.Combine(TPath.GetTempPath, 'UniWamp-process-report-redact-' + TGuid.NewGuid.ToString);
  TDirectory.CreateDirectory(RootDir);
  try
    Paths := BuildPaths(RootDir);
    EnsurePortableLayout(Paths);
    Config := TUniWampConfig.Create;
    try
      Config.SetDefaults(Paths);
      AssertTrue(SaveMariaDbRootPassword(Paths, 'supersecret', ErrorMessage), ErrorMessage);
      Runtime := TUniWampRuntime.Create(Paths, Config);
      try
        ReportText := Runtime.BuildDiagnosticReport;
        AssertTrue(Pos('supersecret', ReportText) = 0, 'Diagnostic report should not expose the MariaDB root password');
        AssertContains(ReportText, 'MariaDB root password: [redacted]', 'Diagnostic report should redact the MariaDB root password');
      finally
        Runtime.Free;
      end;
    finally
      DeleteMariaDbRootPassword(Paths, ErrorMessage);
      Config.Free;
    end;
  finally
    TDirectory.Delete(RootDir, True);
  end;
end;

procedure TestDiagnosticReportIncludesPortOwnersForOccupiedPorts;
var
  RootDir: string;
  Paths: TAppPaths;
  Config: TUniWampConfig;
  Runtime: TUniWampRuntime;
  ReportText: string;
  PortSocket: TSocket;
  Lines: TStringList;
  I: Integer;
  PortOwnerLine: string;
begin
  RootDir := TPath.Combine(TPath.GetTempPath, 'UniWamp-process-report-ports-' + TGuid.NewGuid.ToString);
  TDirectory.CreateDirectory(RootDir);
  try
    Paths := BuildPaths(RootDir);
    EnsurePortableLayout(Paths);
    AssertTrue(ReserveTcpPort(3307, PortSocket), 'Database port should be reserved for diagnostics');
    Config := TUniWampConfig.Create;
    try
      Config.SetDefaults(Paths);
      Config.DatabasePort := 3307;
      Runtime := TUniWampRuntime.Create(Paths, Config);
      try
        ReportText := Runtime.BuildDiagnosticReport;
        AssertContains(ReportText, 'MariaDB port owner:', 'Diagnostic report should include the port owner label');
        Lines := TStringList.Create;
        try
          Lines.Text := ReportText;
          PortOwnerLine := '';
          for I := 0 to Lines.Count - 1 do
            if StartsText('MariaDB port owner: ', Lines[I]) then
            begin
              PortOwnerLine := Lines[I];
              Break;
            end;
          AssertTrue(PortOwnerLine <> '', 'Diagnostic report should include a MariaDB port owner line');
          AssertTrue(Trim(Copy(PortOwnerLine, Length('MariaDB port owner: ') + 1, MaxInt)) <> '',
            'MariaDB port owner should not be empty when the port is occupied');
        finally
          Lines.Free;
        end;
      finally
        Runtime.Free;
      end;
    finally
      Config.Free;
    end;
    ReleaseTcpPort(PortSocket);
  finally
    TDirectory.Delete(RootDir, True);
  end;
end;

procedure TestDiagnosticReportReflectsHostsFileOverride;
var
  RootDir: string;
  Paths: TAppPaths;
  Config: TUniWampConfig;
  Runtime: TUniWampRuntime;
  ReportText: string;
  HostsFile: string;
begin
  RootDir := TPath.Combine(TPath.GetTempPath, 'UniWamp-process-report-hosts-' + TGuid.NewGuid.ToString);
  TDirectory.CreateDirectory(RootDir);
  try
    Paths := BuildPaths(RootDir);
    EnsurePortableLayout(Paths);
    HostsFile := TPath.Combine(RootDir, 'hosts');
    SetEnvironmentVariable('UNIWAMP_HOSTS_FILE', PChar(HostsFile));
    Config := TUniWampConfig.Create;
    try
      Config.SetDefaults(Paths);
      Runtime := TUniWampRuntime.Create(Paths, Config);
      try
        ReportText := Runtime.BuildDiagnosticReport;
        AssertContains(ReportText, HostsFile, 'Diagnostic report should reflect the overridden hosts file path');
      finally
        Runtime.Free;
      end;
    finally
      Config.Free;
      SetEnvironmentVariable('UNIWAMP_HOSTS_FILE', nil);
    end;
  finally
    TDirectory.Delete(RootDir, True);
  end;
end;

procedure TestActivityLogClipboardSelectionPrefersLogFileThenMemo;
begin
  AssertTrue(ChooseActivityLogClipboardText('log line 1', 'memo line 1') = 'log line 1',
    'Log file text should win when present');
  AssertTrue(ChooseActivityLogClipboardText('', 'memo line 1') = 'memo line 1',
    'Memo text should be used when the log file is empty');
  AssertTrue(ChooseActivityLogClipboardText('   ', 'memo line 1') = 'memo line 1',
    'Whitespace-only log file text should fall back to the memo');
  AssertTrue(ChooseActivityLogClipboardText('', '') = '',
    'Empty inputs should return an empty clipboard payload');
end;

procedure TestVHostEmptyStateCaptionReflectsFilter;
begin
  AssertContains(BuildVHostEmptyStateCaption(''), 'No projects or vHosts found.',
    'Empty state should show the default message');
  AssertContains(BuildVHostEmptyStateCaption(''), 'Press Ctrl+F to search or Add to create your first project.',
    'Empty state should point to search and add actions');
  AssertContains(BuildVHostEmptyStateCaption('api'), 'No vHosts match the current filter.',
    'Filtered empty state should mention the active filter');
  AssertContains(BuildVHostEmptyStateCaption('api'), 'Clear the filter or create a new project.',
    'Filtered empty state should instruct the user to clear the filter');
end;

procedure TestProjectTypeDetectionPrefersKnownFrameworkMarkers;
var
  RootDir: string;
begin
  RootDir := TPath.Combine(TPath.GetTempPath, 'UniWamp-process-project-type-' + TGuid.NewGuid.ToString);
  TDirectory.CreateDirectory(RootDir);
  try
    AssertTrue(DetectProjectTypeLabel(RootDir) = 'Static', 'Empty project roots should default to Static');
    TFile.WriteAllText(TPath.Combine(RootDir, 'composer.json'), '{}', TEncoding.UTF8);
    AssertTrue(DetectProjectTypeLabel(RootDir) = 'PHP', 'composer.json should classify as PHP');
    TFile.WriteAllText(TPath.Combine(RootDir, 'package.json'), '{}', TEncoding.UTF8);
    AssertTrue(DetectProjectTypeLabel(RootDir) = 'Node', 'package.json should classify as Node');
    TFile.WriteAllText(TPath.Combine(RootDir, 'artisan'), '', TEncoding.UTF8);
    AssertTrue(DetectProjectTypeLabel(RootDir) = 'Laravel', 'artisan should classify as Laravel');
    TFile.WriteAllText(TPath.Combine(RootDir, 'wp-config.php'), '<?php', TEncoding.UTF8);
    AssertTrue(DetectProjectTypeLabel(RootDir) = 'WordPress', 'wp-config.php should take priority as WordPress');
  finally
    TDirectory.Delete(RootDir, True);
  end;
end;

procedure TestToolPanelHintHelperBuildsMultilineHints;
begin
  AssertTrue(
    BuildToolPanelHint('Open Adminer', 'Launches the database web UI when the Adminer entrypoint exists.') =
      'Open Adminer' + sLineBreak + 'Launches the database web UI when the Adminer entrypoint exists.',
    'Tool panel hints should combine a short title and detail text');
  AssertTrue(
    BuildToolPanelHint('Copy Report', '') = 'Copy Report',
    'Empty detail text should not add an extra line');
end;

procedure TestVHostToolPanelHintTextStaysActionFocused;
begin
  AssertTrue(
    BuildToolPanelHint('Delete the selected vHost', 'Removes the selected project entry and its generated configuration.') =
      'Delete the selected vHost' + sLineBreak + 'Removes the selected project entry and its generated configuration.',
    'VHost delete hint should stay concise and action-focused');
  AssertTrue(
    BuildToolPanelHint('Copy the vHost URL', 'Copies the selected local site address to the clipboard.') =
      'Copy the vHost URL' + sLineBreak + 'Copies the selected local site address to the clipboard.',
    'VHost copy hint should describe the clipboard action');
end;

procedure TestVHostGridKeyboardActionHelperMapsCommonShortcuts;
begin
  AssertTrue(DescribeVHostGridKeyboardAction(VK_RETURN, []) = 'open',
    'Enter should open the selected vHost');
  AssertTrue(DescribeVHostGridKeyboardAction(Ord('O'), [ssCtrl]) = 'folder',
    'Ctrl+O should open the project folder');
  AssertTrue(DescribeVHostGridKeyboardAction(Ord('T'), [ssCtrl]) = 'terminal',
    'Ctrl+T should open the project terminal');
  AssertTrue(DescribeVHostGridKeyboardAction(Ord('C'), [ssCtrl, ssShift]) = 'copy',
    'Ctrl+Shift+C should copy the vHost URL');
  AssertTrue(DescribeVHostGridKeyboardAction(VK_DELETE, []) = 'delete',
    'Delete should remove the selected vHost');
  AssertTrue(DescribeVHostGridKeyboardAction(Ord('X'), []) = '',
    'Unmapped keys should not trigger a grid action');
end;

procedure TestLogToolPanelHintsDescribeTheUnderlyingAction;
begin
  AssertTrue(
    BuildToolPanelHint('Open Apache Log', 'Shows the Apache error log in the default text editor.') =
      'Open Apache Log' + sLineBreak + 'Shows the Apache error log in the default text editor.',
    'Apache log hint should describe the open action');
  AssertTrue(
    BuildToolPanelHint('Clear activity log', 'Clears the in-memory activity memo and the persisted activity log file.') =
      'Clear activity log' + sLineBreak + 'Clears the in-memory activity memo and the persisted activity log file.',
    'Activity log hint should describe the clear action');
end;

procedure TestPrimaryActionHintsCoverSaveAndSslActions;
begin
  AssertTrue(
    BuildToolPanelHint('Save configuration', 'Persists the current dashboard settings to config/uniwamp.json.') =
      'Save configuration' + sLineBreak + 'Persists the current dashboard settings to config/uniwamp.json.',
    'Save hint should explain the persistence target');
  AssertTrue(
    BuildToolPanelHint('Generate SSL', 'Creates the default local TLS certificate and key pair.') =
      'Generate SSL' + sLineBreak + 'Creates the default local TLS certificate and key pair.',
    'SSL hint should explain the generated certificate pair');
end;

procedure TestConfigEditorHintsDescribeGeneratedConfigTargets;
begin
  AssertTrue(
    BuildToolPanelHint('Edit php.ini', 'Opens the generated PHP configuration for the active runtime.') =
      'Edit php.ini' + sLineBreak + 'Opens the generated PHP configuration for the active runtime.',
    'PHP config hint should describe the generated target');
  AssertTrue(
    BuildToolPanelHint('Edit httpd.conf', 'Opens the generated Apache configuration.') =
      'Edit httpd.conf' + sLineBreak + 'Opens the generated Apache configuration.',
    'Apache config hint should describe the generated target');
  AssertTrue(
    BuildToolPanelHint('Edit mariadb.ini', 'Opens the generated MariaDB configuration.') =
      'Edit mariadb.ini' + sLineBreak + 'Opens the generated MariaDB configuration.',
    'MariaDB config hint should describe the generated target');
end;

procedure TestCopyActionHintsUseConsistentClipboardLanguage;
begin
  AssertTrue(
    BuildToolPanelHint('Copy diagnostic report', 'Copies a portable snapshot of the current state to the clipboard.') =
      'Copy diagnostic report' + sLineBreak + 'Copies a portable snapshot of the current state to the clipboard.',
    'Diagnostic copy hint should describe the clipboard snapshot');
  AssertTrue(
    BuildToolPanelHint('Copy activity log', 'Copies the current activity log text to the clipboard.') =
      'Copy activity log' + sLineBreak + 'Copies the current activity log text to the clipboard.',
    'Activity copy hint should describe the clipboard text');
end;

procedure TestStatusBarHintExplainsMariaDbAttention;
begin
  AssertTrue(
    BuildStatusBarHint('MariaDB stopped unexpectedly') =
      'Status summary' + sLineBreak + 'Service requires attention: MariaDB stopped unexpectedly',
    'Status bar hint should explain when MariaDB needs attention');
  AssertTrue(
    BuildStatusBarHint('Apache failed to start') =
      'Status summary' + sLineBreak + 'Service requires attention: Apache failed to start',
    'Status bar hint should apply to Apache errors too');
  AssertTrue(
    BuildStatusBarHint('') = 'Status summary',
    'Status bar hint should stay short when there is no error');
  AssertTrue(
    BuildStatusBarHint(' ') = 'Status summary',
    'Whitespace-only errors should not add an extra line');
end;

procedure TestHeaderSubtitleHintDescribesTheStackOverview;
begin
  AssertTrue(
    BuildHeaderSubtitleHint =
      'Stack overview' + sLineBreak + 'Shows the current local development dashboard summary.',
    'Header subtitle hint should describe the dashboard overview');
end;

procedure TestHeaderCardHintSummarizesStatusAndPorts;
begin
  AssertTrue(
    BuildHeaderCardHint('Apache', 'HTTP 8080', 'HTTPS 8443') =
      'Apache' + sLineBreak + 'HTTP 8080' + sLineBreak + 'HTTPS 8443',
    'Apache header card hint should include both port lines');
  AssertTrue(
    BuildHeaderCardHint('PHP', 'php85', 'node-v22.23.1-win-x64') =
      'PHP' + sLineBreak + 'php85' + sLineBreak + 'node-v22.23.1-win-x64',
    'PHP header card hint should include the runtime lines');
end;

procedure TestHeaderTitleHintStaysOnBrand;
begin
  AssertTrue(
    BuildHeaderTitleHint =
      'UniWamp' + sLineBreak + 'Portable WAMP dashboard for local development.',
    'Header title hint should stay on brand');
end;

procedure TestApacheTemplateExposesDirectoryIndexForDashboardAndAdminer;
var
  RootDir: string;
  Paths: TAppPaths;
  Config: TUniWampConfig;
  Runtime: TUniWampRuntime;
  HttpdText: string;
begin
  RootDir := TPath.Combine(TPath.GetTempPath, 'UniWamp-process-template-' + TGuid.NewGuid.ToString);
  TDirectory.CreateDirectory(RootDir);
  try
    Paths := BuildPaths(RootDir);
    EnsurePortableLayout(Paths);
    Config := TUniWampConfig.Create;
    try
      Runtime := TUniWampRuntime.Create(Paths, Config);
      try
        Runtime.GenerateAllConfigs;
        HttpdText := TFile.ReadAllText(Paths.ApacheHttpdConfFile, TEncoding.UTF8);
        AssertContains(HttpdText, 'DirectoryIndex index.php index.html',
          'Generated Apache config should declare an index for dashboard and Adminer aliases');
      finally
        Runtime.Free;
      end;
    finally
      Config.Free;
    end;
  finally
    TDirectory.Delete(RootDir, True);
  end;
end;

procedure TestApacheTemplateExposesPhpHandlerMapping;
var
  RootDir: string;
  Paths: TAppPaths;
  Config: TUniWampConfig;
  Runtime: TUniWampRuntime;
  HttpdText: string;
begin
  RootDir := TPath.Combine(TPath.GetTempPath, 'UniWamp-process-php-handler-' + TGuid.NewGuid.ToString);
  TDirectory.CreateDirectory(RootDir);
  try
    Paths := BuildPaths(RootDir);
    EnsurePortableLayout(Paths);
    Config := TUniWampConfig.Create;
    try
      Runtime := TUniWampRuntime.Create(Paths, Config);
      try
        Runtime.GenerateAllConfigs;
        HttpdText := TFile.ReadAllText(Paths.ApacheHttpdConfFile, TEncoding.UTF8);
        AssertContains(HttpdText, 'AddType application/x-httpd-php .php',
          'Generated Apache config should map PHP files to the PHP handler');
      finally
        Runtime.Free;
      end;
    finally
      Config.Free;
    end;
  finally
    TDirectory.Delete(RootDir, True);
  end;
end;

procedure TestHeaderOverviewHintDescribesTheDashboardSummary;
begin
  AssertTrue(
    BuildHeaderOverviewHint =
      'Header overview' + sLineBreak + 'Shows Apache, PHP, and MariaDB status at a glance.',
    'Header overview hint should describe the stack status area');
end;

procedure TestHeaderPanelHintDescribesTheOverviewRegion;
begin
  AssertTrue(
    BuildHeaderOverviewHint <> '',
    'Header overview hint should not be empty');
end;

procedure TestPreferredTextEditorExecutablePrefersEnvironmentOverride;
var
  OldEditor: string;
  Runtime: TUniWampRuntime;
  RootDir: string;
  Paths: TAppPaths;
  Config: TUniWampConfig;
begin
  OldEditor := GetEnvironmentVariable('EDITOR');
  SetEnvironmentVariable('EDITOR', 'C:\Tools\Code\Code.exe');
  RootDir := TPath.Combine(TPath.GetTempPath, 'UniWamp-process-editor-' + TGuid.NewGuid.ToString);
  TDirectory.CreateDirectory(RootDir);
  try
    Paths := BuildPaths(RootDir);
    EnsurePortableLayout(Paths);
    Config := TUniWampConfig.Create;
    try
      Runtime := TUniWampRuntime.Create(Paths, Config);
      try
        AssertTrue(SameText(Runtime.PreferredTextEditorExecutable, 'C:\Tools\Code\Code.exe'),
          'EDITOR should take precedence over the Notepad fallback');
      finally
        Runtime.Free;
      end;
    finally
      Config.Free;
    end;
  finally
    SetEnvironmentVariable('EDITOR', PChar(OldEditor));
    TDirectory.Delete(RootDir, True);
  end;
end;

procedure TestPreferredTerminalExecutableChoosesCmderThenWtThenCmd;
var
  RootDir: string;
  CmderPath: string;
  WindowsTerminalPath: string;
begin
  RootDir := TPath.Combine(TPath.GetTempPath, 'UniWamp-process-terminal-choice-' + TGuid.NewGuid.ToString);
  TDirectory.CreateDirectory(RootDir);
  try
    CmderPath := TPath.Combine(RootDir, 'Cmder.exe');
    WindowsTerminalPath := TPath.Combine(RootDir, 'wt.exe');
    TFile.WriteAllText(CmderPath, '', TEncoding.ASCII);
    TFile.WriteAllText(WindowsTerminalPath, '', TEncoding.ASCII);
    AssertTrue(
      ChoosePreferredTerminalExecutable(CmderPath, '') = CmderPath,
      'Cmder should win when present');
    AssertTrue(
      ChoosePreferredTerminalExecutable(TPath.Combine(RootDir, 'missing-Cmder.exe'), WindowsTerminalPath) =
        WindowsTerminalPath,
      'Windows Terminal should win when Cmder is missing');
    AssertTrue(
      ChoosePreferredTerminalExecutable(TPath.Combine(RootDir, 'missing-Cmder.exe'), '') = 'cmd.exe',
      'cmd.exe should be the final fallback');
  finally
    TDirectory.Delete(RootDir, True);
  end;
end;

procedure TestDescribeTerminalLaunchModeMapsExecutableNames;
begin
  AssertTrue(DescribeTerminalLaunchMode('C:\Tools\wt.exe') = 'windows-terminal',
    'wt.exe should map to the Windows Terminal launch mode');
  AssertTrue(DescribeTerminalLaunchMode('C:\Windows\System32\cmd.exe') = 'cmd',
    'cmd.exe should map to the CMD launch mode');
  AssertTrue(DescribeTerminalLaunchMode('C:\Tools\cmder\Cmder.exe') = 'cmder',
    'Cmder should map to the Cmder launch mode');
end;

procedure TestSha256HelperReturnsTheExpectedDigest;
var
  RootDir: string;
  Paths: TAppPaths;
  Config: TUniWampConfig;
  Runtime: TUniWampRuntime;
  SampleFile: string;
begin
  RootDir := TPath.Combine(TPath.GetTempPath, 'UniWamp-process-sha256-' + TGuid.NewGuid.ToString);
  TDirectory.CreateDirectory(RootDir);
  try
    Paths := BuildPaths(RootDir);
    EnsurePortableLayout(Paths);
    Config := TUniWampConfig.Create;
    try
      Runtime := TUniWampRuntime.Create(Paths, Config);
      try
        SampleFile := TPath.Combine(RootDir, 'sample.txt');
        TFile.WriteAllText(SampleFile, 'abc', TEncoding.ASCII);
        AssertTrue(SameText(Runtime.ComputeFileSha256Hex(SampleFile),
          'BA7816BF8F01CFEA414140DE5DAE2223B00361A396177A9CB410FF61F20015AD'),
          'SHA-256 helper should match the known digest for abc');
      finally
        Runtime.Free;
      end;
    finally
      Config.Free;
    end;
  finally
    TDirectory.Delete(RootDir, True);
  end;
end;

procedure TestValidatePackageSha256ChecksTheExpectedDigest;
var
  RootDir: string;
  Paths: TAppPaths;
  Config: TUniWampConfig;
  Runtime: TUniWampRuntime;
  SampleFile: string;
  ErrorMessage: string;
begin
  RootDir := TPath.Combine(TPath.GetTempPath, 'UniWamp-process-package-hash-' + TGuid.NewGuid.ToString);
  TDirectory.CreateDirectory(RootDir);
  try
    Paths := BuildPaths(RootDir);
    EnsurePortableLayout(Paths);
    Config := TUniWampConfig.Create;
    try
      Runtime := TUniWampRuntime.Create(Paths, Config);
      try
        SampleFile := TPath.Combine(RootDir, 'package.zip');
        TFile.WriteAllText(SampleFile, 'abc', TEncoding.ASCII);
        AssertTrue(Runtime.ValidatePackageSha256(SampleFile,
          'BA7816BF8F01CFEA414140DE5DAE2223B00361A396177A9CB410FF61F20015AD', ErrorMessage),
          ErrorMessage);
      finally
        Runtime.Free;
      end;
    finally
      Config.Free;
    end;
  finally
    TDirectory.Delete(RootDir, True);
  end;
end;

procedure TestValidatePackageSha256RejectsMismatchedDigest;
var
  RootDir: string;
  Paths: TAppPaths;
  Config: TUniWampConfig;
  Runtime: TUniWampRuntime;
  SampleFile: string;
  ErrorMessage: string;
begin
  RootDir := TPath.Combine(TPath.GetTempPath, 'UniWamp-process-package-hash-mismatch-' + TGuid.NewGuid.ToString);
  TDirectory.CreateDirectory(RootDir);
  try
    Paths := BuildPaths(RootDir);
    EnsurePortableLayout(Paths);
    Config := TUniWampConfig.Create;
    try
      Runtime := TUniWampRuntime.Create(Paths, Config);
      try
        SampleFile := TPath.Combine(RootDir, 'package.zip');
        TFile.WriteAllText(SampleFile, 'abc', TEncoding.ASCII);
        AssertTrue(not Runtime.ValidatePackageSha256(SampleFile, '0000000000000000000000000000000000000000000000000000000000000000', ErrorMessage),
          'Mismatched hashes should be rejected');
        AssertContains(ErrorMessage, 'hash mismatch', 'Mismatched hashes should report a hash mismatch');
      finally
        Runtime.Free;
      end;
    finally
      Config.Free;
    end;
  finally
    TDirectory.Delete(RootDir, True);
  end;
end;

procedure TestValidateUpdateManifestReadsTheExpectedFields;
var
  RootDir: string;
  Paths: TAppPaths;
  Config: TUniWampConfig;
  Runtime: TUniWampRuntime;
  ManifestPath: string;
  PackageFileName: string;
  ExpectedSha256: string;
  PackageVersion: string;
  ErrorMessage: string;
begin
  RootDir := TPath.Combine(TPath.GetTempPath, 'UniWamp-process-manifest-' + TGuid.NewGuid.ToString);
  TDirectory.CreateDirectory(RootDir);
  try
    Paths := BuildPaths(RootDir);
    EnsurePortableLayout(Paths);
    Config := TUniWampConfig.Create;
    try
      Runtime := TUniWampRuntime.Create(Paths, Config);
      try
        ManifestPath := TPath.Combine(RootDir, 'update.json');
        TFile.WriteAllText(ManifestPath,
          '{"packageFileName":"runtime.zip","expectedSha256":"abc","packageVersion":"1.0.0"}',
          TEncoding.UTF8);
        AssertTrue(Runtime.ValidateUpdateManifest(ManifestPath, PackageFileName, ExpectedSha256, PackageVersion, ErrorMessage), ErrorMessage);
        AssertTrue(PackageFileName = 'runtime.zip', 'Manifest should expose the package file name');
        AssertTrue(ExpectedSha256 = 'abc', 'Manifest should expose the expected hash');
        AssertTrue(PackageVersion = '1.0.0', 'Manifest should expose the package version');
      finally
        Runtime.Free;
      end;
    finally
      Config.Free;
    end;
  finally
    TDirectory.Delete(RootDir, True);
  end;
end;

procedure TestValidateUpdateManifestRejectsPathTraversalPackageNames;
var
  RootDir: string;
  Paths: TAppPaths;
  PackageManager: TPackageManager;
  ManifestPath: string;
  PackageFileName: string;
  ExpectedSha256: string;
  PackageVersion: string;
  ErrorMessage: string;
begin
  RootDir := TPath.Combine(TPath.GetTempPath, 'UniWamp-process-manifest-invalid-' + TGuid.NewGuid.ToString);
  TDirectory.CreateDirectory(RootDir);
  try
    Paths := BuildPaths(RootDir);
    EnsurePortableLayout(Paths);
    PackageManager := TPackageManager.Create(Paths);
    try
      ManifestPath := TPath.Combine(RootDir, 'update.json');
      TFile.WriteAllText(ManifestPath,
        '{"packageFileName":"..\\runtime.zip","expectedSha256":"abc","packageVersion":"1.0.0"}',
        TEncoding.UTF8);
      AssertTrue(not PackageManager.ValidateUpdateManifest(ManifestPath, PackageFileName, ExpectedSha256, PackageVersion, ErrorMessage),
        'Manifest should reject traversal package names');
      AssertContains(ErrorMessage, 'plain file name', 'Traversal package names should be rejected explicitly');
    finally
      PackageManager.Free;
    end;
  finally
    TDirectory.Delete(RootDir, True);
  end;
end;

procedure TestWriteUpdateStagingMetadataCreatesTheExpectedJson;
var
  RootDir: string;
  Paths: TAppPaths;
  Config: TUniWampConfig;
  Runtime: TUniWampRuntime;
  StagingDir: string;
  MetadataFileName: string;
  ErrorMessage: string;
  JsonValue: TJSONValue;
  JsonObject: TJSONObject;
begin
  RootDir := TPath.Combine(TPath.GetTempPath, 'UniWamp-process-staging-metadata-' + TGuid.NewGuid.ToString);
  TDirectory.CreateDirectory(RootDir);
  try
    Paths := BuildPaths(RootDir);
    EnsurePortableLayout(Paths);
    Config := TUniWampConfig.Create;
    try
      Runtime := TUniWampRuntime.Create(Paths, Config);
      try
        StagingDir := TPath.Combine(Paths.UpdatesDir, 'UniWamp-1.0.0');
        TDirectory.CreateDirectory(StagingDir);
        AssertTrue(Runtime.WriteUpdateStagingMetadata(StagingDir, 'runtime.zip', 'abc', '1.0.0', MetadataFileName, ErrorMessage), ErrorMessage);
        AssertTrue(TFile.Exists(MetadataFileName), 'Staging metadata should be written');
        JsonValue := TJSONObject.ParseJSONValue(TFile.ReadAllText(MetadataFileName, TEncoding.UTF8));
        try
          AssertTrue(JsonValue is TJSONObject, 'Staging metadata should be valid JSON');
          JsonObject := TJSONObject(JsonValue);
          AssertTrue(JsonObject.GetValue<string>('packageFileName', '') = 'runtime.zip', 'Metadata should include the package file');
          AssertTrue(JsonObject.GetValue<string>('expectedSha256', '') = 'abc', 'Metadata should include the package hash');
          AssertTrue(JsonObject.GetValue<string>('packageVersion', '') = '1.0.0', 'Metadata should include the package version');
        finally
          JsonValue.Free;
        end;
      finally
        Runtime.Free;
      end;
    finally
      Config.Free;
    end;
  finally
    TDirectory.Delete(RootDir, True);
  end;
end;

procedure TestCleanupUpdateWorkspaceRemovesExistingDirectory;
var
  RootDir: string;
  Paths: TAppPaths;
  Config: TUniWampConfig;
  Runtime: TUniWampRuntime;
  WorkspaceDir: string;
  ErrorMessage: string;
begin
  RootDir := TPath.Combine(TPath.GetTempPath, 'UniWamp-process-workspace-cleanup-' + TGuid.NewGuid.ToString);
  TDirectory.CreateDirectory(RootDir);
  try
    Paths := BuildPaths(RootDir);
    EnsurePortableLayout(Paths);
    Config := TUniWampConfig.Create;
    try
      Runtime := TUniWampRuntime.Create(Paths, Config);
      try
        WorkspaceDir := TPath.Combine(Paths.UpdatesDir, 'staging');
        TDirectory.CreateDirectory(WorkspaceDir);
        TFile.WriteAllText(TPath.Combine(WorkspaceDir, 'marker.txt'), 'marker', TEncoding.ASCII);
        AssertTrue(Runtime.CleanupUpdateWorkspace(WorkspaceDir, ErrorMessage), ErrorMessage);
        AssertTrue(not TDirectory.Exists(WorkspaceDir), 'Workspace cleanup should remove the directory');
      finally
        Runtime.Free;
      end;
    finally
      Config.Free;
    end;
  finally
    TDirectory.Delete(RootDir, True);
  end;
end;

procedure TestCleanupUpdateWorkspaceAcceptsMissingDirectory;
var
  RootDir: string;
  Paths: TAppPaths;
  Config: TUniWampConfig;
  Runtime: TUniWampRuntime;
  WorkspaceDir: string;
  ErrorMessage: string;
begin
  RootDir := TPath.Combine(TPath.GetTempPath, 'UniWamp-process-workspace-cleanup-missing-' + TGuid.NewGuid.ToString);
  TDirectory.CreateDirectory(RootDir);
  try
    Paths := BuildPaths(RootDir);
    EnsurePortableLayout(Paths);
    Config := TUniWampConfig.Create;
    try
      Runtime := TUniWampRuntime.Create(Paths, Config);
      try
        WorkspaceDir := TPath.Combine(Paths.UpdatesDir, 'missing-cleanup');
        AssertTrue(Runtime.CleanupUpdateWorkspace(WorkspaceDir, ErrorMessage), ErrorMessage);
        AssertTrue(not TDirectory.Exists(WorkspaceDir), 'Missing workspace cleanup should remain a no-op');
      finally
        Runtime.Free;
      end;
    finally
      Config.Free;
    end;
  finally
    TDirectory.Delete(RootDir, True);
  end;
end;

procedure TestStageValidatedUpdatePackageBuildsTheWorkspace;
var
  RootDir: string;
  Paths: TAppPaths;
  Config: TUniWampConfig;
  Runtime: TUniWampRuntime;
  ManifestPath: string;
  PackagePath: string;
  StagingDir: string;
  MetadataFileName: string;
  ErrorMessage: string;
  Zip: TZipFile;
  JsonValue: TJSONValue;
  JsonObject: TJSONObject;
begin
  RootDir := TPath.Combine(TPath.GetTempPath, 'UniWamp-process-stage-update-' + TGuid.NewGuid.ToString);
  TDirectory.CreateDirectory(RootDir);
  try
    Paths := BuildPaths(RootDir);
    EnsurePortableLayout(Paths);
    Config := TUniWampConfig.Create;
    try
      Runtime := TUniWampRuntime.Create(Paths, Config);
      try
        PackagePath := TPath.Combine(RootDir, 'runtime.zip');
        Zip := TZipFile.Create;
        try
          Zip.Open(PackagePath, zmWrite);
          Zip.Add(TPath.GetTempFileName, 'payload.txt');
          Zip.Close;
        finally
          Zip.Free;
        end;
        ManifestPath := TPath.Combine(RootDir, 'update.json');
        TFile.WriteAllText(ManifestPath,
          '{"packageFileName":"runtime.zip","expectedSha256":"' + Runtime.ComputeFileSha256Hex(PackagePath) + '","packageVersion":"1.0.0"}',
          TEncoding.UTF8);
        AssertTrue(Runtime.StageValidatedUpdatePackage(ManifestPath, StagingDir, MetadataFileName, ErrorMessage), ErrorMessage);
        AssertTrue(TDirectory.Exists(StagingDir), 'Staging directory should be created');
        AssertTrue(TFile.Exists(TPath.Combine(StagingDir, 'payload.txt')), 'Payload should be extracted into the staging directory');
        AssertTrue(TFile.Exists(MetadataFileName), 'Staging metadata should be written');
        JsonValue := TJSONObject.ParseJSONValue(TFile.ReadAllText(MetadataFileName, TEncoding.UTF8));
        try
          AssertTrue(JsonValue is TJSONObject, 'Staging metadata should be valid JSON');
          JsonObject := TJSONObject(JsonValue);
          AssertTrue(JsonObject.GetValue<string>('packageVersion', '') = '1.0.0', 'Metadata should include the package version');
        finally
          JsonValue.Free;
        end;
      finally
        Runtime.Free;
      end;
    finally
      Config.Free;
    end;
  finally
    TDirectory.Delete(RootDir, True);
  end;
end;

procedure TestPromoteStagedUpdateCopiesWorkspaceIntoTarget;
var
  RootDir: string;
  Paths: TAppPaths;
  Config: TUniWampConfig;
  Runtime: TUniWampRuntime;
  StagingDir: string;
  TargetDir: string;
  BackupDir: string;
  ErrorMessage: string;
begin
  RootDir := TPath.Combine(TPath.GetTempPath, 'UniWamp-process-promote-update-' + TGuid.NewGuid.ToString);
  TDirectory.CreateDirectory(RootDir);
  try
    Paths := BuildPaths(RootDir);
    EnsurePortableLayout(Paths);
    Config := TUniWampConfig.Create;
    try
      Runtime := TUniWampRuntime.Create(Paths, Config);
      try
        StagingDir := TPath.Combine(Paths.UpdatesDir, 'staging');
        TDirectory.CreateDirectory(StagingDir);
        TFile.WriteAllText(TPath.Combine(StagingDir, 'payload.txt'), 'payload', TEncoding.ASCII);
        TargetDir := TPath.Combine(RootDir, 'promoted');
        TDirectory.CreateDirectory(TargetDir);
        TFile.WriteAllText(TPath.Combine(TargetDir, 'old.txt'), 'old', TEncoding.ASCII);
        AssertTrue(Runtime.PromoteStagedUpdate(StagingDir, TargetDir, BackupDir, ErrorMessage), ErrorMessage);
        AssertTrue(BackupDir <> '', 'Promotion should report a backup directory when replacing an existing target');
        AssertTrue(TDirectory.Exists(BackupDir), 'Promotion should preserve the previous target tree as a backup');
        AssertTrue(TFile.Exists(TPath.Combine(TargetDir, 'payload.txt')),
          'Promoted update should copy the staged payload into the target');
        AssertTrue(not TFile.Exists(TPath.Combine(TargetDir, 'old.txt')),
          'Promoted update should replace the previous target tree');
      finally
        Runtime.Free;
      end;
    finally
      Config.Free;
    end;
  finally
    TDirectory.Delete(RootDir, True);
  end;
end;

procedure TestPromoteStagedUpdateRestoresTargetWhenReplacementFails;
var
  RootDir: string;
  Paths: TAppPaths;
  Config: TUniWampConfig;
  Runtime: TUniWampRuntime;
  StagingDir: string;
  TargetDir: string;
  BackupDir: string;
  ErrorMessage: string;
begin
  RootDir := TPath.Combine(TPath.GetTempPath, 'UniWamp-process-promote-rollback-' + TGuid.NewGuid.ToString);
  TDirectory.CreateDirectory(RootDir);
  try
    Paths := BuildPaths(RootDir);
    EnsurePortableLayout(Paths);
    Config := TUniWampConfig.Create;
    try
      Runtime := TUniWampRuntime.Create(Paths, Config);
      try
        StagingDir := TPath.Combine(Paths.UpdatesDir, 'staging');
        TDirectory.CreateDirectory(StagingDir);
        TFile.WriteAllText(TPath.Combine(StagingDir, 'payload.txt'), 'payload', TEncoding.ASCII);
        TargetDir := TPath.Combine(RootDir, 'promoted');
        TDirectory.CreateDirectory(TargetDir);
        TFile.WriteAllText(TPath.Combine(TargetDir, 'locked.txt'), 'locked', TEncoding.ASCII);
        AssertTrue(not Runtime.PromoteStagedUpdate(StagingDir, TargetDir, BackupDir, ErrorMessage, True),
          'Promotion should fail when failure is injected after backup');
        AssertTrue(BackupDir <> '', 'Promotion should still create a backup before failing');
        AssertTrue(TDirectory.Exists(TargetDir), 'Failed promotion should restore the target tree');
        AssertTrue(TFile.Exists(TPath.Combine(TargetDir, 'locked.txt')),
          'Failed promotion should restore the original target contents');
        AssertTrue(not TFile.Exists(TPath.Combine(TargetDir, 'payload.txt')),
          'Failed promotion should not leave the staged payload in the target tree');
      finally
        Runtime.Free;
      end;
    finally
      Config.Free;
    end;
  finally
    TDirectory.Delete(RootDir, True);
  end;
end;

procedure TestRuntimeZipValidationAcceptsNonEmptyZipArchives;
var
  RootDir: string;
  Paths: TAppPaths;
  Config: TUniWampConfig;
  Runtime: TUniWampRuntime;
  ZipPath: string;
  PayloadPath: string;
  ErrorMessage: string;
  Zip: TZipFile;
begin
  RootDir := TPath.Combine(TPath.GetTempPath, 'UniWamp-process-zip-' + TGuid.NewGuid.ToString);
  TDirectory.CreateDirectory(RootDir);
  try
    Paths := BuildPaths(RootDir);
    EnsurePortableLayout(Paths);
    Config := TUniWampConfig.Create;
    try
      Runtime := TUniWampRuntime.Create(Paths, Config);
      try
        PayloadPath := TPath.Combine(RootDir, 'payload.txt');
        TFile.WriteAllText(PayloadPath, 'payload', TEncoding.ASCII);
        ZipPath := TPath.Combine(RootDir, 'runtime.zip');
        Zip := TZipFile.Create;
        try
          Zip.Open(ZipPath, zmWrite);
          Zip.Add(PayloadPath, 'payload.txt');
          Zip.Close;
        finally
          Zip.Free;
        end;
        AssertTrue(Runtime.ValidateRuntimeZipArchive(ZipPath, ErrorMessage), ErrorMessage);
      finally
        Runtime.Free;
      end;
    finally
      Config.Free;
    end;
  finally
    TDirectory.Delete(RootDir, True);
  end;
end;

procedure TestRuntimeZipValidationRejectsEmptyZipArchives;
var
  RootDir: string;
  Paths: TAppPaths;
  Config: TUniWampConfig;
  Runtime: TUniWampRuntime;
  ZipPath: string;
  ErrorMessage: string;
begin
  RootDir := TPath.Combine(TPath.GetTempPath, 'UniWamp-process-zip-empty-' + TGuid.NewGuid.ToString);
  TDirectory.CreateDirectory(RootDir);
  try
    Paths := BuildPaths(RootDir);
    EnsurePortableLayout(Paths);
    Config := TUniWampConfig.Create;
    try
      Runtime := TUniWampRuntime.Create(Paths, Config);
      try
        ZipPath := TPath.Combine(RootDir, 'runtime.zip');
        TFile.WriteAllBytes(ZipPath, nil);
        AssertTrue(not Runtime.ValidateRuntimeZipArchive(ZipPath, ErrorMessage),
          'Empty ZIP archives should be rejected');
        AssertContains(ErrorMessage, 'validation failed', 'Empty ZIP archives should report a validation failure');
      finally
        Runtime.Free;
      end;
    finally
      Config.Free;
    end;
  finally
    TDirectory.Delete(RootDir, True);
  end;
end;

procedure TestRuntimeZipImportExtractsArchiveContents;
var
  RootDir: string;
  Paths: TAppPaths;
  Config: TUniWampConfig;
  Runtime: TUniWampRuntime;
  ZipPath: string;
  PayloadPath: string;
  ExtractedPath: string;
  ErrorMessage: string;
  Zip: TZipFile;
begin
  RootDir := TPath.Combine(TPath.GetTempPath, 'UniWamp-process-zip-import-' + TGuid.NewGuid.ToString);
  TDirectory.CreateDirectory(RootDir);
  try
    Paths := BuildPaths(RootDir);
    EnsurePortableLayout(Paths);
    Config := TUniWampConfig.Create;
    try
      Runtime := TUniWampRuntime.Create(Paths, Config);
      try
        PayloadPath := TPath.Combine(RootDir, 'payload.txt');
        TFile.WriteAllText(PayloadPath, 'payload', TEncoding.ASCII);
        ZipPath := TPath.Combine(RootDir, 'runtime.zip');
        Zip := TZipFile.Create;
        try
          Zip.Open(ZipPath, zmWrite);
          Zip.Add(PayloadPath, 'payload.txt');
          Zip.Close;
        finally
          Zip.Free;
        end;
        AssertTrue(Runtime.ImportRuntimeZipArchive(ZipPath, ErrorMessage), ErrorMessage);
        ExtractedPath := TPath.Combine(RootDir, 'payload.txt');
        AssertTrue(TFile.Exists(ExtractedPath), 'Imported archive should extract payload.txt into the app root');
      finally
        Runtime.Free;
      end;
    finally
      Config.Free;
    end;
  finally
    TDirectory.Delete(RootDir, True);
  end;
end;

procedure TestRuntimeZipImportRejectsTraversalEntries;
var
  RootDir: string;
  Paths: TAppPaths;
  PackageManager: TPackageManager;
  ZipPath: string;
  PayloadPath: string;
  ErrorMessage: string;
  Zip: TZipFile;
begin
  RootDir := TPath.Combine(TPath.GetTempPath, 'UniWamp-process-zip-traversal-' + TGuid.NewGuid.ToString);
  TDirectory.CreateDirectory(RootDir);
  try
    Paths := BuildPaths(RootDir);
    EnsurePortableLayout(Paths);
    PackageManager := TPackageManager.Create(Paths);
    try
      PayloadPath := TPath.Combine(RootDir, 'payload.txt');
      TFile.WriteAllText(PayloadPath, 'payload', TEncoding.ASCII);
      ZipPath := TPath.Combine(RootDir, 'runtime.zip');
      Zip := TZipFile.Create;
      try
        Zip.Open(ZipPath, zmWrite);
        Zip.Add(PayloadPath, '..\payload.txt');
        Zip.Close;
      finally
        Zip.Free;
      end;
      AssertTrue(not PackageManager.ImportRuntimeZipArchiveInto(ZipPath, Paths.AppRoot, ErrorMessage),
        'ZIP import should reject traversal entries');
      AssertContains(ErrorMessage, 'traversal entry', 'ZIP traversal should report the rejection reason');
    finally
      PackageManager.Free;
    end;
  finally
    TDirectory.Delete(RootDir, True);
  end;
end;

procedure TestUpdateStagingAreaCreatesPortableWorkspace;
var
  RootDir: string;
  Paths: TAppPaths;
  Config: TUniWampConfig;
  Runtime: TUniWampRuntime;
  StagingDir: string;
  ErrorMessage: string;
begin
  RootDir := TPath.Combine(TPath.GetTempPath, 'UniWamp-process-staging-' + TGuid.NewGuid.ToString);
  TDirectory.CreateDirectory(RootDir);
  try
    Paths := BuildPaths(RootDir);
    EnsurePortableLayout(Paths);
    Config := TUniWampConfig.Create;
    try
      Runtime := TUniWampRuntime.Create(Paths, Config);
      try
        AssertTrue(Runtime.PrepareUpdateStagingArea('UniWamp-1.0.0.zip', StagingDir, ErrorMessage), ErrorMessage);
        AssertTrue(TDirectory.Exists(StagingDir), 'Update staging area should be created under tmp\updates');
        AssertTrue(StartsText(Paths.UpdatesDir, StagingDir),
          'Staging area should stay inside the portable updates directory');
      finally
        Runtime.Free;
      end;
    finally
      Config.Free;
    end;
  finally
    TDirectory.Delete(RootDir, True);
  end;
end;

procedure TestPrepareUpdateStagingAreaRejectsEmptyPackageName;
var
  RootDir: string;
  Paths: TAppPaths;
  Config: TUniWampConfig;
  Runtime: TUniWampRuntime;
  StagingDir: string;
  ErrorMessage: string;
begin
  RootDir := TPath.Combine(TPath.GetTempPath, 'UniWamp-process-staging-empty-' + TGuid.NewGuid.ToString);
  TDirectory.CreateDirectory(RootDir);
  try
    Paths := BuildPaths(RootDir);
    EnsurePortableLayout(Paths);
    Config := TUniWampConfig.Create;
    try
      Runtime := TUniWampRuntime.Create(Paths, Config);
      try
        AssertTrue(not Runtime.PrepareUpdateStagingArea('', StagingDir, ErrorMessage),
          'Empty package names should be rejected');
        AssertContains(ErrorMessage, 'Update package name is required', 'Empty package names should report the reason');
      finally
        Runtime.Free;
      end;
    finally
      Config.Free;
    end;
  finally
    TDirectory.Delete(RootDir, True);
  end;
end;

procedure TestRollbackUpdateStagingAreaRestoresRollbackSnapshot;
var
  RootDir: string;
  Paths: TAppPaths;
  Config: TUniWampConfig;
  Runtime: TUniWampRuntime;
  StagingDir: string;
  SnapshotDir: string;
  FilePath: string;
  ErrorMessage: string;
begin
  RootDir := TPath.Combine(TPath.GetTempPath, 'UniWamp-process-rollback-' + TGuid.NewGuid.ToString);
  TDirectory.CreateDirectory(RootDir);
  try
    Paths := BuildPaths(RootDir);
    EnsurePortableLayout(Paths);
    Config := TUniWampConfig.Create;
    try
      Runtime := TUniWampRuntime.Create(Paths, Config);
      try
        StagingDir := TPath.Combine(Paths.UpdatesDir, 'UniWamp-1.0.0.zip');
        TDirectory.CreateDirectory(StagingDir);
        FilePath := TPath.Combine(StagingDir, 'payload.txt');
        TFile.WriteAllText(FilePath, 'payload', TEncoding.ASCII);
        AssertTrue(Runtime.CreateUpdateRollbackSnapshot(StagingDir, 'UniWamp-1.0.0', SnapshotDir, ErrorMessage), ErrorMessage);
        TDirectory.Delete(StagingDir, True);
        AssertTrue(Runtime.RollbackUpdateStagingArea(SnapshotDir, StagingDir, ErrorMessage), ErrorMessage);
        AssertTrue(TFile.Exists(TPath.Combine(StagingDir, 'payload.txt')),
          'Rollback restore should bring back the staged payload');
      finally
        Runtime.Free;
      end;
    finally
      Config.Free;
    end;
  finally
    TDirectory.Delete(RootDir, True);
  end;
end;

procedure TestCreateUpdateRollbackSnapshotRejectsMissingStagingDir;
var
  RootDir: string;
  Paths: TAppPaths;
  Config: TUniWampConfig;
  Runtime: TUniWampRuntime;
  SnapshotDir: string;
  ErrorMessage: string;
begin
  RootDir := TPath.Combine(TPath.GetTempPath, 'UniWamp-process-rollback-missing-' + TGuid.NewGuid.ToString);
  TDirectory.CreateDirectory(RootDir);
  try
    Paths := BuildPaths(RootDir);
    EnsurePortableLayout(Paths);
    Config := TUniWampConfig.Create;
    try
      Runtime := TUniWampRuntime.Create(Paths, Config);
      try
        AssertTrue(not Runtime.CreateUpdateRollbackSnapshot(TPath.Combine(Paths.UpdatesDir, 'missing'), 'UniWamp-1.0.0', SnapshotDir, ErrorMessage),
          'Missing staging directories should be rejected');
        AssertContains(ErrorMessage, 'Staging directory not found', 'Missing staging directories should report the reason');
      finally
        Runtime.Free;
      end;
    finally
      Config.Free;
    end;
  finally
    TDirectory.Delete(RootDir, True);
  end;
end;

procedure TestCreateUpdateRollbackSnapshotRejectsEmptySnapshotName;
var
  RootDir: string;
  Paths: TAppPaths;
  Config: TUniWampConfig;
  Runtime: TUniWampRuntime;
  StagingDir: string;
  SnapshotDir: string;
  ErrorMessage: string;
begin
  RootDir := TPath.Combine(TPath.GetTempPath, 'UniWamp-process-rollback-empty-name-' + TGuid.NewGuid.ToString);
  TDirectory.CreateDirectory(RootDir);
  try
    Paths := BuildPaths(RootDir);
    EnsurePortableLayout(Paths);
    Config := TUniWampConfig.Create;
    try
      Runtime := TUniWampRuntime.Create(Paths, Config);
      try
        StagingDir := TPath.Combine(Paths.UpdatesDir, 'staging');
        TDirectory.CreateDirectory(StagingDir);
        AssertTrue(not Runtime.CreateUpdateRollbackSnapshot(StagingDir, '', SnapshotDir, ErrorMessage),
          'Empty snapshot names should be rejected');
        AssertContains(ErrorMessage, 'Snapshot name is required', 'Empty snapshot names should report the reason');
      finally
        Runtime.Free;
      end;
    finally
      Config.Free;
    end;
  finally
    TDirectory.Delete(RootDir, True);
  end;
end;

procedure TestVHostFilterHintMakesTheClearActionExplicit;
begin
  AssertTrue(
    BuildToolPanelHint('Clear the vHost filter', 'Shows all projects and vHosts again.') =
      'Clear the vHost filter' + sLineBreak + 'Shows all projects and vHosts again.',
    'Filter clear hint should explain the reset action');
end;

procedure TestVHostFilterSearchHintDescribesSearchFields;
begin
  AssertTrue(
    BuildToolPanelHint('Filter vHosts', 'Search by site name, document root, or aliases. Press Esc to clear.') =
      'Filter vHosts' + sLineBreak + 'Search by site name, document root, or aliases. Press Esc to clear.',
    'Filter search hint should describe the searchable fields');
end;

procedure TestVHostFilterKeyActionHelperDistinguishesClearAndExit;
begin
  AssertTrue(DescribeVHostFilterKeyAction(VK_ESCAPE, 'api') = 'clear',
    'Escape should clear a non-empty vHost filter');
  AssertTrue(DescribeVHostFilterKeyAction(VK_ESCAPE, '') = 'exit',
    'Escape should exit the filter when it is already empty');
  AssertTrue(DescribeVHostFilterKeyAction(VK_RETURN, 'api') = '',
    'Non-Escape keys should not map to filter actions');
end;

procedure TestDiagnosticReportUsesConsistentServiceStateLabels;
var
  RootDir: string;
  Paths: TAppPaths;
  Config: TUniWampConfig;
  Runtime: TUniWampRuntime;
  Report: string;
begin
  RootDir := TPath.Combine(TPath.GetTempPath, 'UniWamp-process-service-state-' + TGuid.NewGuid.ToString);
  TDirectory.CreateDirectory(RootDir);
  try
    Paths := BuildPaths(RootDir);
    EnsurePortableLayout(Paths);
    Config := TUniWampConfig.Create;
    try
      Config.ApacheRunning := True;
      Config.MariaDbRunning := False;
      Runtime := TUniWampRuntime.Create(Paths, Config);
      try
        Report := Runtime.BuildDiagnosticReport;
        AssertContains(Report, 'Apache: running', 'Running services should be reported with the running label');
        AssertContains(Report, 'MariaDB: stopped', 'Stopped services should be reported with the stopped label');
      finally
        Runtime.Free;
      end;
    finally
      Config.Free;
    end;
  finally
    TDirectory.Delete(RootDir, True);
  end;
end;

procedure TestGeneratedEnvBatDoesNotStartWithUtf8Bom;
var
  RootDir: string;
  Paths: TAppPaths;
  Config: TUniWampConfig;
  Runtime: TUniWampRuntime;
  Content: TBytes;
begin
  RootDir := TPath.Combine(TPath.GetTempPath, 'UniWamp-process-env-bat-' + TGuid.NewGuid.ToString);
  TDirectory.CreateDirectory(RootDir);
  try
    Paths := BuildPaths(RootDir);
    EnsurePortableLayout(Paths);
    Config := TUniWampConfig.Create;
    try
      Runtime := TUniWampRuntime.Create(Paths, Config);
      try
        Runtime.GenerateEnvBat(Paths.AppRoot);
        Content := TFile.ReadAllBytes(Paths.EnvBatFile);
        AssertTrue((Length(Content) >= 8) and
          (Content[0] = Ord('@')) and
          (Content[1] = Ord('e')) and
          (Content[2] = Ord('c')) and
          (Content[3] = Ord('h')) and
          (Content[4] = Ord('o')) and
          (Content[5] = Ord(' ')) and
          (Content[6] = Ord('o')) and
          (Content[7] = Ord('f')),
          'Generated env.bat should begin with plain ASCII text, not a BOM');
      finally
        Runtime.Free;
      end;
    finally
      Config.Free;
    end;
  finally
    TDirectory.Delete(RootDir, True);
  end;
end;

procedure TestTerminalExecutablePathResolvesRelativeConfigValues;
var
  RootDir: string;
  Paths: TAppPaths;
  Config: TUniWampConfig;
  Runtime: TUniWampRuntime;
  ExpectedPath: string;
begin
  RootDir := TPath.Combine(TPath.GetTempPath, 'UniWamp-process-terminal-path-' + TGuid.NewGuid.ToString);
  TDirectory.CreateDirectory(RootDir);
  try
    Paths := BuildPaths(RootDir);
    EnsurePortableLayout(Paths);
    Config := TUniWampConfig.Create;
    try
      Config.TerminalExePath := 'bin\cmder\custom\Cmder.exe';
      Runtime := TUniWampRuntime.Create(Paths, Config);
      try
        ExpectedPath := TPath.Combine(Paths.AppRoot, 'bin\cmder\custom\Cmder.exe');
        AssertTrue(SameText(Runtime.TerminalExecutablePath, ExpectedPath),
          'Relative terminal executable paths should resolve against the app root');
      finally
        Runtime.Free;
      end;
    finally
      Config.Free;
    end;
  finally
    TDirectory.Delete(RootDir, True);
  end;
end;

procedure TestWebToolsRequireHealthyApacheMariaDbAndPhp;
var
  RootDir: string;
  Paths: TAppPaths;
  Config: TUniWampConfig;
  Runtime: TUniWampRuntime;
  ErrorMessage: string;
begin
  RootDir := TPath.Combine(TPath.GetTempPath, 'UniWamp-process-web-tools-' + TGuid.NewGuid.ToString);
  TDirectory.CreateDirectory(RootDir);
  try
    Paths := BuildPaths(RootDir);
    EnsurePortableLayout(Paths);
    TDirectory.CreateDirectory(TPath.Combine(Paths.PhpDir, 'php85'));
    Config := TUniWampConfig.Create;
    try
      Config.SetDefaults(Paths);
      Config.SelectedPhpVersion := 'php85';
      Config.ApacheRunning := True;
      Config.MariaDbRunning := True;
      Runtime := TUniWampRuntime.Create(Paths, Config);
      try
        AssertTrue(not Runtime.AreWebToolsReady(ErrorMessage), 'Missing PHP runtime should block web tools');
        AssertContains(ErrorMessage, 'PHP', 'Missing PHP runtime should be reported');
        Config.ApacheRunning := False;
        AssertTrue(not Runtime.AreWebToolsReady(ErrorMessage), 'Apache must be running for web tools');
        AssertContains(ErrorMessage, 'Apache', 'Missing Apache should be reported');
      finally
        Runtime.Free;
      end;
    finally
      Config.Free;
    end;
  finally
    TDirectory.Delete(RootDir, True);
  end;
end;

procedure TestMariaDbRootPasswordRequiresRunningService;
var
  RootDir: string;
  Paths: TAppPaths;
  Config: TUniWampConfig;
  Runtime: TUniWampRuntime;
  ResultInfo: TRuntimeActionResult;
begin
  RootDir := TPath.Combine(TPath.GetTempPath, 'UniWamp-process-mariadb-password-' + TGuid.NewGuid.ToString);
  TDirectory.CreateDirectory(RootDir);
  try
    Paths := BuildPaths(RootDir);
    EnsurePortableLayout(Paths);
    Config := TUniWampConfig.Create;
    try
      Config.SetDefaults(Paths);
      Config.MariaDbRunning := False;
      Config.MariaDbPid := 0;
      Runtime := TUniWampRuntime.Create(Paths, Config);
      try
        ResultInfo := Runtime.SetMariaDbRootPassword('secret123');
        AssertTrue(not ResultInfo.Success, 'MariaDB root password should require a running service');
        AssertContains(ResultInfo.Message, 'MariaDB must be running before setting the root password', 'Password change should report the running-service requirement');
      finally
        Runtime.Free;
      end;
    finally
      Config.Free;
    end;
  finally
    TDirectory.Delete(RootDir, True);
  end;
end;

begin
  try
    TestMissingExecutable;
    TestTimeout;
    TestNonZeroExitCode;
    TestDetachedStartMissingExecutable;
    TestStopInvalidPidFails;
    TestWaitInvalidPidFails;
    TestStopLiveProcessTerminatesIt;
    TestStaleRuntimeStateCleanup;
    TestDuplicateStartShortCircuit;
    TestMariaDbDuplicateStartShortCircuit;
    TestDuplicateStartReturnsAlreadyRunning;
    TestMariaDbDuplicateStartReturnsAlreadyRunning;
    TestRestartFailureMessages;
    TestMissingRuntimeDependencies;
    TestMariaDbStartReportsPortConflict;
    TestApacheStartReportsPortConflictOwner;
  TestGenerateAllConfigsStaysInGeneratedConfigDir;
  TestMariaDbInitializationBacksUpDirtyDataDirectory;
  TestAddVHostNormalizesAliasesAndGeneratesConfig;
    TestManagedHostsSyncReportsReadOnlyFailure;
    TestDeleteVHostPreservesUnmanagedHostsEntries;
    TestDeleteSslVHostRemovesCertificateFiles;
    TestGenerateSslCertificateReportsMissingOpenSsl;
    TestApacheStartSyncsPhpVersionSelection;
    TestApacheStartReportsMissingVisualCRuntime;
    TestSyncPhpVersionsPrefersCompatibleRuntime;
    TestSyncNodeVersionsPrefersExecutableRuntime;
    TestStopPathsAreIdempotentWhenAlreadyStopped;
    TestStopApacheDoesNotKillUnrelatedHttpdProcesses;
    TestApacheStartStopsOnConfigValidationFailure;
    TestManagedHostsSyncUsesOverride;
    TestRotatedLogAppendsAndTrims;
    TestLogRedactionMasksSecrets;
    TestLogRedactionLeavesNonSecretsIntact;
    TestDiagnosticReportIncludesState;
    TestDiagnosticReportOmitsSensitiveValues;
    TestDiagnosticReportIncludesPortOwnersForOccupiedPorts;
    TestDiagnosticReportReflectsHostsFileOverride;
    TestActivityLogClipboardSelectionPrefersLogFileThenMemo;
  TestVHostEmptyStateCaptionReflectsFilter;
  TestProjectTypeDetectionPrefersKnownFrameworkMarkers;
  TestToolPanelHintHelperBuildsMultilineHints;
  TestVHostToolPanelHintTextStaysActionFocused;
  TestVHostGridKeyboardActionHelperMapsCommonShortcuts;
  TestLogToolPanelHintsDescribeTheUnderlyingAction;
  TestPrimaryActionHintsCoverSaveAndSslActions;
  TestConfigEditorHintsDescribeGeneratedConfigTargets;
  TestCopyActionHintsUseConsistentClipboardLanguage;
  TestStatusBarHintExplainsMariaDbAttention;
  TestPreferredTerminalExecutableChoosesCmderThenWtThenCmd;
  TestDescribeTerminalLaunchModeMapsExecutableNames;
  TestVHostFilterHintMakesTheClearActionExplicit;
  TestVHostFilterSearchHintDescribesSearchFields;
  TestVHostFilterKeyActionHelperDistinguishesClearAndExit;
  TestHeaderSubtitleHintDescribesTheStackOverview;
  TestHeaderCardHintSummarizesStatusAndPorts;
  TestHeaderTitleHintStaysOnBrand;
  TestApacheTemplateExposesDirectoryIndexForDashboardAndAdminer;
  TestApacheTemplateExposesPhpHandlerMapping;
    TestHeaderOverviewHintDescribesTheDashboardSummary;
    TestHeaderPanelHintDescribesTheOverviewRegion;
    TestAddVHostRejectsInvalidInputs;
    TestDiagnosticReportUsesConsistentServiceStateLabels;
  TestGeneratedEnvBatDoesNotStartWithUtf8Bom;
  TestTerminalExecutablePathResolvesRelativeConfigValues;
  TestWebToolsRequireHealthyApacheMariaDbAndPhp;
  TestSha256HelperReturnsTheExpectedDigest;
  TestValidatePackageSha256ChecksTheExpectedDigest;
  TestValidatePackageSha256RejectsMismatchedDigest;
  TestValidateUpdateManifestReadsTheExpectedFields;
  TestValidateUpdateManifestRejectsPathTraversalPackageNames;
  TestWriteUpdateStagingMetadataCreatesTheExpectedJson;
  TestCleanupUpdateWorkspaceRemovesExistingDirectory;
  TestCleanupUpdateWorkspaceAcceptsMissingDirectory;
  TestStageValidatedUpdatePackageBuildsTheWorkspace;
  TestPrepareUpdateStagingAreaRejectsEmptyPackageName;
  TestPromoteStagedUpdateCopiesWorkspaceIntoTarget;
  TestPromoteStagedUpdateRestoresTargetWhenReplacementFails;
  TestRuntimeZipValidationAcceptsNonEmptyZipArchives;
  TestRuntimeZipValidationRejectsEmptyZipArchives;
  TestRuntimeZipImportExtractsArchiveContents;
  TestRuntimeZipImportRejectsTraversalEntries;
  TestUpdateStagingAreaCreatesPortableWorkspace;
  TestRollbackUpdateStagingAreaRestoresRollbackSnapshot;
  TestCreateUpdateRollbackSnapshotRejectsMissingStagingDir;
  TestCreateUpdateRollbackSnapshotRejectsEmptySnapshotName;
  TestMariaDbRootPasswordRequiresRunningService;
  Writeln('Process harness passed.');
  except
    on E: Exception do
    begin
      Writeln(E.ClassName + ': ' + E.Message);
      Halt(1);
    end;
  end;
end.
