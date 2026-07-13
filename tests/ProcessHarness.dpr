program ProcessHarness;

{$APPTYPE CONSOLE}

uses
  System.Classes,
  System.IOUtils,
  System.SysUtils,
  Winapi.Windows,
  Core.UniWamp.Config,
  Core.UniWamp.Diagnostics,
  Core.UniWamp.Paths,
  Core.UniWamp.TemplateRenderer,
  Core.UniWamp.Runtime,
  Core.UniWamp.ProcessManager;

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

begin
  try
    TestMissingExecutable;
    TestTimeout;
    TestNonZeroExitCode;
    TestDetachedStartMissingExecutable;
    TestStopInvalidPidFails;
    TestWaitInvalidPidFails;
    TestStaleRuntimeStateCleanup;
    TestDuplicateStartShortCircuit;
    TestMariaDbDuplicateStartShortCircuit;
    TestRestartFailureMessages;
    TestMissingRuntimeDependencies;
    TestApacheStartStopsOnConfigValidationFailure;
    TestManagedHostsSyncUsesOverride;
    TestRotatedLogAppendsAndTrims;
    TestLogRedactionMasksSecrets;
    TestDiagnosticReportIncludesState;
    Writeln('Process harness passed.');
  except
    on E: Exception do
    begin
      Writeln(E.ClassName + ': ' + E.Message);
      Halt(1);
    end;
  end;
end.
