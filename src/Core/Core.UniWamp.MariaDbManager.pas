unit Core.UniWamp.MariaDbManager;

interface

uses
  System.SysUtils,
  Core.UniWamp.Config,
  Core.UniWamp.Paths,
  Core.UniWamp.Types,
  Core.UniWamp.ServiceSupervisor;

type
  IMariaDbManager = interface
    ['{FBAA40F6-5B8D-4E3D-8D7E-8C2F8E74F5B1}']
    function IsRunning: Boolean;
    function Start: TRuntimeActionResult;
    function Stop: TRuntimeActionResult;
    function Restart: TRuntimeActionResult;
    function SetRootPassword(const NewPassword: string): TRuntimeActionResult;
  end;

  TMariaDbManager = class(TInterfacedObject, IMariaDbManager)
  private
    FPaths: TAppPaths;
    FConfig: TUniWampConfig;
    function MariaDbExe: string;
    function MariaDbInstallDbExe: string;
    function MysqlAdminExe: string;
    function MariaDbSystemDatabaseReady(const MysqlDir: string): Boolean;
    function ValidateMariaDbPorts(out ErrorMessage: string): Boolean;
    function EnsureMariaDbInitialized(out ErrorMessage: string): Boolean;
    function WaitForMariaDbStartup(const ProcessId: Cardinal; out ErrorMessage: string): Boolean;
    procedure ApplyMariaDbState(const State: TServiceProcessState);
    procedure ClearMariaDbState;
    procedure FailMariaDbStart(const ErrorMessage: string);
  public
    constructor Create(const Paths: TAppPaths; Config: TUniWampConfig);
    function IsRunning: Boolean;
    function Start: TRuntimeActionResult;
    function Stop: TRuntimeActionResult;
    function Restart: TRuntimeActionResult;
    function SetRootPassword(const NewPassword: string): TRuntimeActionResult;
  end;

implementation

uses
  System.Classes,
  System.IOUtils,
  Winapi.Windows,
  Core.UniWamp.ProcessManager,
  Core.UniWamp.ConfigGenerator,
  Core.UniWamp.MariaDbAuth,
  Core.UniWamp.Secrets,
  Core.UniWamp.PortUtils;

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

constructor TMariaDbManager.Create(const Paths: TAppPaths; Config: TUniWampConfig);
begin
  inherited Create;
  FPaths := Paths;
  FConfig := Config;
end;

function TMariaDbManager.MariaDbExe: string;
begin
  Result := TPath.Combine(FPaths.MariaDbBinDir, 'mariadbd.exe');
end;

function TMariaDbManager.MariaDbInstallDbExe: string;
begin
  Result := TPath.Combine(FPaths.MariaDbBinDir, 'mariadb-install-db.exe');
  if not FileExists(Result) then
    Result := TPath.Combine(FPaths.MariaDbBinDir, 'mysql_install_db.exe');
end;

function TMariaDbManager.MariaDbSystemDatabaseReady(const MysqlDir: string): Boolean;
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

function TMariaDbManager.IsRunning: Boolean;
var
  State: TServiceProcessState;
begin
  State := TServiceProcessSupervisor.ResolveOwnedProcess(
    FConfig.MariaDbPid,
    MariaDbExe,
    '');
  Result := State.Running;
  ApplyMariaDbState(State);
end;

procedure TMariaDbManager.ApplyMariaDbState(const State: TServiceProcessState);
begin
  FConfig.MariaDbPid := State.ProcessId;
  FConfig.MariaDbRunning := State.Running;
end;

procedure TMariaDbManager.ClearMariaDbState;
begin
  FConfig.MariaDbPid := 0;
  FConfig.MariaDbRunning := False;
end;

procedure TMariaDbManager.FailMariaDbStart(const ErrorMessage: string);
begin
  ClearMariaDbState;
  FConfig.LastMariaDbError := ErrorMessage;
end;

function TMariaDbManager.MysqlAdminExe: string;
begin
  Result := TPath.Combine(FPaths.MariaDbBinDir, 'mysqladmin.exe');
end;

function TMariaDbManager.ValidateMariaDbPorts(out ErrorMessage: string): Boolean;
var
  MariaDbRunningNow: Boolean;
  OwnerInfo: string;
begin
  Result := True;
  ErrorMessage := '';
  MariaDbRunningNow := IsRunning or FConfig.MariaDbRunning;
  if not IsTcpPortAvailable(FConfig.DatabasePort) and not MariaDbRunningNow then
  begin
    Result := False;
    OwnerInfo := DescribeTcpPortOwner(FConfig.DatabasePort);
    if OwnerInfo <> '' then
      ErrorMessage := Format('Database port %d is already in use by %s.', [FConfig.DatabasePort, OwnerInfo])
    else
      ErrorMessage := Format('Database port %d is already in use.', [FConfig.DatabasePort]);
    Exit;
  end;
end;

function TMariaDbManager.EnsureMariaDbInitialized(out ErrorMessage: string): Boolean;
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
  HadDirtyDataDir: Boolean;
begin
  Result := False;
  ErrorMessage := '';
  HadDirtyDataDir := False;
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
      HadDirtyDataDir := True;
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
    if HadDirtyDataDir then
      ErrorMessage := ErrorMessage + ' The dirty data directory was backed up before retrying initialization.';
    AppendTextToLogFile(TPath.Combine(FPaths.LogsDir, 'mariadb-error.log'),
      'MariaDB init output:' + sLineBreak + ErrorMessage);
    Exit;
  end;

  AppendTextToLogFile(TPath.Combine(FPaths.LogsDir, 'mariadb-error.log'),
    'MariaDB init output:' + sLineBreak + Trim(BootstrapOutput));
  if not MariaDbSystemDatabaseReady(MysqlDir) then
  begin
    ErrorMessage := 'MariaDB initialization did not create the mysql system database.';
    if HadDirtyDataDir then
      ErrorMessage := ErrorMessage + ' The dirty data directory was backed up before retrying initialization.';
    Exit;
  end;

  Result := True;
end;

function TMariaDbManager.WaitForMariaDbStartup(const ProcessId: Cardinal; out ErrorMessage: string): Boolean;
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

function TMariaDbManager.Start: TRuntimeActionResult;
var
  StartResult: TProcessStartResult;
  ErrorMessage: string;
begin
  if FConfig.MariaDbRunning and not IsRunning then
  begin
    FConfig.LastMariaDbError := 'Stale MariaDB state detected; retrying start.';
    ClearMariaDbState;
  end;

  if IsRunning then
  begin
    FConfig.LastMariaDbError := '';
    Result.Success := True;
    Result.Message := 'MariaDB already running.';
    Exit;
  end;

  Result.Success := False;
  if not ValidateMariaDbPorts(ErrorMessage) then
  begin
    FailMariaDbStart(ErrorMessage);
    Result.Message := ErrorMessage;
    Exit;
  end;

  if not EnsureMariaDbInitialized(ErrorMessage) then
  begin
    FailMariaDbStart(ErrorMessage);
    Result.Message := ErrorMessage;
    Exit;
  end;

  with TConfigurationGenerator.Create(FPaths, FConfig) do
  try
    GenerateMariaDbConfig;
  finally
    Free;
  end;
  AppendTextToLogFile(TPath.Combine(FPaths.LogsDir, 'mariadb-error.log'), 'Starting MariaDB: ' + MariaDbExe);
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
      AppendTextToLogFile(TPath.Combine(FPaths.LogsDir, 'mariadb-error.log'), 'MariaDB successfully started with PID ' + StartResult.ProcessId.ToString);
    end
    else
    begin
      FailMariaDbStart(ErrorMessage);
      Result.Success := False;
      Result.Message := ErrorMessage;
    end;
  end
  else
  begin
    FailMariaDbStart(StartResult.ErrorMessage);
    Result.Message := StartResult.ErrorMessage;
    AppendTextToLogFile(TPath.Combine(FPaths.LogsDir, 'mariadb-error.log'), 'MariaDB failed to start: ' + StartResult.ErrorMessage);
  end;
end;

function TMariaDbManager.Stop: TRuntimeActionResult;
var
  StartResult: TProcessStartResult;
  State: TServiceProcessState;
begin
  Result.Success := True;
  AppendTextToLogFile(TPath.Combine(FPaths.LogsDir, 'mariadb-error.log'), 'Initiating MariaDB shutdown...');
  State := TServiceProcessSupervisor.ResolveOwnedProcess(
    FConfig.MariaDbPid,
    MariaDbExe,
    '');
  if not State.Running then
  begin
    ClearMariaDbState;
    Result.Message := 'MariaDB stopped.';
    AppendTextToLogFile(TPath.Combine(FPaths.LogsDir, 'mariadb-error.log'), Result.Message);
    Exit;
  end;
  if FileExists(MysqlAdminExe) then
  begin
    StartResult := TProcessManager.StartDetached(
      MysqlAdminExe,
      '--port=' + FConfig.DatabasePort.ToString + ' shutdown',
      FPaths.MariaDbBinDir);
    if StartResult.Success then
      TProcessManager.WaitForExit(StartResult.ProcessId, 4000);
  end;

  Result.Success := TServiceProcessSupervisor.StopOwnedProcess(State);
  if not TProcessManager.IsRunning(State.ProcessId) then
    ClearMariaDbState;
  if Result.Success then
    Result.Message := 'MariaDB stopped.'
  else
    Result.Message := 'Failed to stop MariaDB cleanly.';
  AppendTextToLogFile(TPath.Combine(FPaths.LogsDir, 'mariadb-error.log'), Result.Message);
end;

function TMariaDbManager.Restart: TRuntimeActionResult;
begin
  Result := Stop;
  if not Result.Success then
  begin
    Result.Message := 'MariaDB restart failed during stop: ' + Result.Message;
    FConfig.LastMariaDbError := Result.Message;
    Exit;
  end;
  Result := Start;
  if not Result.Success then
  begin
    Result.Message := 'MariaDB restart failed during start: ' + Result.Message;
    FConfig.LastMariaDbError := Result.Message;
  end;
end;

function TMariaDbManager.SetRootPassword(const NewPassword: string): TRuntimeActionResult;
var
  MysqlClientExePath: string;
  Arguments: string;
  Output: string;
  LowerOutput: string;
  CurrentPassword: string;
  SecretError: string;
  DefaultsFileName: string;
  PasswordSqlFileName: string;
  AuthError: string;
begin
  if Trim(NewPassword) = '' then
  begin
    Result.Success := False;
    Result.Message := 'MariaDB root password cannot be empty.';
    Exit;
  end;

  if not IsRunning then
  begin
    Result.Success := False;
    Result.Message := 'MariaDB must be running before setting the root password.';
    Exit;
  end;

  MysqlClientExePath := MariaDbExe;
  if not FileExists(MysqlClientExePath) then
  begin
    Result.Success := False;
    Result.Message := 'mysql client executable not found: ' + MysqlClientExePath;
    Exit;
  end;

  CurrentPassword := LoadMariaDbRootPassword(FPaths);
  DefaultsFileName := '';
  PasswordSqlFileName := '';
  if CurrentPassword <> '' then
  begin
    if not CreateMariaDbDefaultsExtraFile(FPaths, CurrentPassword, DefaultsFileName, AuthError) then
    begin
      Result.Success := False;
      Result.Message := 'MariaDB auth setup failed: ' + AuthError;
      Exit;
    end;
  end;
  if not CreateMariaDbPasswordSqlFile(FPaths, NewPassword, PasswordSqlFileName, AuthError) then
  begin
    DeleteMariaDbDefaultsExtraFile(DefaultsFileName);
    Result.Success := False;
    Result.Message := 'MariaDB password file setup failed: ' + AuthError;
    Exit;
  end;

  try
    Arguments := '--port=' + FConfig.DatabasePort.ToString + ' --user=root ';
    if DefaultsFileName <> '' then
      Arguments := PrependDefaultsExtraFileArg(DefaultsFileName, Arguments);
    Arguments := '/c ""' + MysqlClientExePath + '" ' + Arguments +
      '--batch --raw < "' + PasswordSqlFileName + '""';
    if not TProcessManager.RunAndCaptureOutput('cmd.exe', Arguments, FPaths.MariaDbBinDir, Output) then
    begin
      Result.Success := False;
      if Trim(Output) <> '' then
        Result.Message := Trim(Output)
      else
        Result.Message := 'Failed to start mysql client.';
      Exit;
    end;
  finally
    DeleteMariaDbDefaultsExtraFile(DefaultsFileName);
    if PasswordSqlFileName <> '' then
      DeleteMariaDbDefaultsExtraFile(PasswordSqlFileName);
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

  if not SaveMariaDbRootPassword(FPaths, NewPassword, SecretError) then
  begin
    Result.Success := False;
    Result.Message := SecretError;
    Exit;
  end;
  FConfig.MariaDbRootPassword := NewPassword;
  FConfig.LastMariaDbError := '';
  Result.Success := True;
  Result.Message := 'MariaDB root password updated.';
end;

end.
