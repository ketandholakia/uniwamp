program ProcessHarness;

{$APPTYPE CONSOLE}

uses
  System.Classes,
  System.IOUtils,
  System.SysUtils,
  System.StrUtils,
  Winapi.Windows,
  Winapi.Winsock2,
  Core.UniWamp.Config,
  Core.UniWamp.Diagnostics,
  Core.UniWamp.Paths,
  Core.UniWamp.PortUtils,
  Core.UniWamp.TemplateRenderer,
  Core.UniWamp.Runtime,
  Core.UniWamp.ProcessManager,
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
  Result.WwwDir := TPath.Combine(Root, 'www');
  Result.VHostsDir := Result.WwwDir;
  Result.SslDir := TPath.Combine(Root, 'ssl');
  Result.StateFile := TPath.Combine(Result.ConfigDir, 'state.json');
  Result.AppConfigFile := TPath.Combine(Result.ConfigDir, 'uniwamp.json');
  Result.ApacheTemplateFile := TPath.Combine(Result.TemplatesDir, 'httpd.conf.tpl');
  Result.ApacheSslTemplateFile := TPath.Combine(Result.TemplatesDir, 'httpd-ssl.conf.tpl');
  Result.ApacheVHostsTemplateFile := TPath.Combine(Result.TemplatesDir, 'httpd-vhosts.conf.tpl');
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
  CmdExe: string;
  PidFile: string;
begin
  RootDir := TPath.Combine(TPath.GetTempPath, 'UniWamp-process-live-' + TGuid.NewGuid.ToString);
  TDirectory.CreateDirectory(RootDir);
  try
    Paths := BuildPaths(RootDir);
    EnsurePortableLayout(Paths);
    Config := TUniWampConfig.Create;
    try
      Config.SetDefaults(Paths);
      CmdExe := 'C:\Windows\System32\cmd.exe';
      StartResult := TProcessManager.StartDetached(CmdExe, '/c "ping 127.0.0.1 -n 30 >nul"', ExtractFileDir(CmdExe));
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
  CmdExe: string;
  PidFile: string;
begin
  RootDir := TPath.Combine(TPath.GetTempPath, 'UniWamp-process-mariadb-live-' + TGuid.NewGuid.ToString);
  TDirectory.CreateDirectory(RootDir);
  try
    Paths := BuildPaths(RootDir);
    EnsurePortableLayout(Paths);
    Config := TUniWampConfig.Create;
    try
      Config.SetDefaults(Paths);
      CmdExe := 'C:\Windows\System32\cmd.exe';
      StartResult := TProcessManager.StartDetached(CmdExe, '/c "ping 127.0.0.1 -n 30 >nul"', ExtractFileDir(CmdExe));
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
  CmdExe: string;
  PidFile: string;
  ResultInfo: TRuntimeActionResult;
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
    CmdExe := 'C:\Windows\System32\cmd.exe';
    StartResult := TProcessManager.StartDetached(CmdExe, '/c "ping 127.0.0.1 -n 30 >nul"', ExtractFileDir(CmdExe));
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
  CmdExe: string;
  PidFile: string;
  ResultInfo: TRuntimeActionResult;
begin
  RootDir := TPath.Combine(TPath.GetTempPath, 'UniWamp-process-mariadb-duplicate-start-' + TGuid.NewGuid.ToString);
  TDirectory.CreateDirectory(RootDir);
  try
    Paths := BuildPaths(RootDir);
    EnsurePortableLayout(Paths);
    TDirectory.CreateDirectory(Paths.MariaDbBinDir);
    TFile.WriteAllText(TPath.Combine(Paths.MariaDbBinDir, 'mariadbd.exe'), '', TEncoding.ASCII);
    TFile.WriteAllText(TPath.Combine(Paths.MariaDbBinDir, 'mariadb-install-db.exe'), '', TEncoding.ASCII);
    TFile.WriteAllText(TPath.Combine(Paths.MariaDbBinDir, 'mysqladmin.exe'), '', TEncoding.ASCII);
    TFile.WriteAllText(TPath.Combine(Paths.GeneratedConfigDir, 'mariadb.ini'), 'port=3307', TEncoding.UTF8);
    CmdExe := 'C:\Windows\System32\cmd.exe';
    StartResult := TProcessManager.StartDetached(CmdExe, '/c "ping 127.0.0.1 -n 30 >nul"', ExtractFileDir(CmdExe));
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
begin
  RootDir := TPath.Combine(TPath.GetTempPath, 'UniWamp-process-report-redact-' + TGuid.NewGuid.ToString);
  TDirectory.CreateDirectory(RootDir);
  try
    Paths := BuildPaths(RootDir);
    EnsurePortableLayout(Paths);
    Config := TUniWampConfig.Create;
    try
      Config.SetDefaults(Paths);
      Config.MariaDbRootPassword := 'supersecret';
      Runtime := TUniWampRuntime.Create(Paths, Config);
      try
        ReportText := Runtime.BuildDiagnosticReport;
        AssertTrue(Pos('supersecret', ReportText) = 0, 'Diagnostic report should not expose the MariaDB root password');
        AssertContains(ReportText, 'MariaDB root password: [redacted]', 'Diagnostic report should redact the MariaDB root password');
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
      'Status summary' + sLineBreak + 'MariaDB requires attention: MariaDB stopped unexpectedly',
    'Status bar hint should explain when MariaDB needs attention');
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

procedure TestHeaderOverviewHintDescribesTheDashboardSummary;
begin
  AssertTrue(
    BuildHeaderOverviewHint =
      'Header overview' + sLineBreak + 'Shows Apache, PHP, and MariaDB status at a glance.',
    'Header overview hint should describe the stack status area');
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
    BuildToolPanelHint('Filter vHosts', 'Search by site name, document root, or aliases.') =
      'Filter vHosts' + sLineBreak + 'Search by site name, document root, or aliases.',
    'Filter search hint should describe the searchable fields');
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
        Runtime.GenerateEnvBat;
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
    TestMariaDbInitializationBacksUpDirtyDataDirectory;
    TestAddVHostNormalizesAliasesAndGeneratesConfig;
    TestManagedHostsSyncReportsReadOnlyFailure;
    TestGenerateSslCertificateReportsMissingOpenSsl;
    TestApacheStartSyncsPhpVersionSelection;
    TestStopPathsAreIdempotentWhenAlreadyStopped;
    TestApacheStartStopsOnConfigValidationFailure;
    TestManagedHostsSyncUsesOverride;
    TestRotatedLogAppendsAndTrims;
    TestLogRedactionMasksSecrets;
    TestLogRedactionLeavesNonSecretsIntact;
    TestDiagnosticReportIncludesState;
    TestDiagnosticReportOmitsSensitiveValues;
    TestDiagnosticReportIncludesPortOwnersForOccupiedPorts;
  TestActivityLogClipboardSelectionPrefersLogFileThenMemo;
  TestVHostEmptyStateCaptionReflectsFilter;
  TestProjectTypeDetectionPrefersKnownFrameworkMarkers;
  TestToolPanelHintHelperBuildsMultilineHints;
  TestVHostToolPanelHintTextStaysActionFocused;
  TestLogToolPanelHintsDescribeTheUnderlyingAction;
  TestPrimaryActionHintsCoverSaveAndSslActions;
  TestConfigEditorHintsDescribeGeneratedConfigTargets;
  TestCopyActionHintsUseConsistentClipboardLanguage;
  TestStatusBarHintExplainsMariaDbAttention;
  TestVHostFilterHintMakesTheClearActionExplicit;
  TestVHostFilterSearchHintDescribesSearchFields;
  TestHeaderSubtitleHintDescribesTheStackOverview;
  TestHeaderCardHintSummarizesStatusAndPorts;
  TestHeaderTitleHintStaysOnBrand;
  TestHeaderOverviewHintDescribesTheDashboardSummary;
  TestDiagnosticReportUsesConsistentServiceStateLabels;
  TestGeneratedEnvBatDoesNotStartWithUtf8Bom;
  TestTerminalExecutablePathResolvesRelativeConfigValues;
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
