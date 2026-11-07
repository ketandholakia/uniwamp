unit Core.UniWamp.ApacheManager;

interface

uses
  System.SysUtils,
  System.Win.Registry,
  Core.UniWamp.Config,
  Core.UniWamp.Paths,
  Core.UniWamp.Types,
  Core.UniWamp.ServiceSupervisor;

type
  TApacheStringFunc = reference to function: string;
  TApacheAction = reference to procedure;

  IApacheManager = interface
    ['{DDA1B3B8-6B2E-4DD7-BEAA-4E5E6C0FD2E1}']
    function IsRunning: Boolean;
    function ProcessId: Cardinal;
    function Start: TRuntimeActionResult;
    function Stop: TRuntimeActionResult;
    function Restart: TRuntimeActionResult;
  end;

  TApacheManager = class(TInterfacedObject, IApacheManager)
  private
    FPaths: TAppPaths;
    FConfig: TUniWampConfig;
    FSelectedPhpDir: TApacheStringFunc;
    FSelectedPhpExe: TApacheStringFunc;
    FApacheModuleForSelectedPhp: TApacheStringFunc;
    FGenerateAllConfigs: TApacheAction;
    function ApacheExe: string;
    function ApacheRuntimePid: Cardinal;
    function ApacheModuleForSelectedPhp: string;
    function SelectedPhpDir: string;
    function SelectedPhpExe: string;
    procedure ApplyApacheState(const State: TServiceProcessState);
    procedure ClearApacheState;
    procedure FailApacheStart(const ErrorMessage: string);
    function HasRequiredApacheVisualCRuntime(out ErrorMessage: string): Boolean;
    function HasAppLocalApacheVisualCRuntime(out ErrorMessage: string): Boolean;
    class function ReadPeMachineType(const FileName: string; out Machine: Word): Boolean;
    function PushPhpRuntimeToPath(const PhpDir: string; out OldPath: string): Boolean;
    procedure RestorePath(const OldPath: string);
    function ValidateApachePorts(out ErrorMessage: string): Boolean;
    function ValidateApacheConfiguration(out ErrorMessage: string): Boolean;
    function WaitForApacheStartup(const ProcessId: Cardinal; out ErrorMessage: string): Boolean;
  public
    constructor Create(const Paths: TAppPaths; Config: TUniWampConfig;
      const SelectedPhpDir: TApacheStringFunc; const SelectedPhpExe: TApacheStringFunc;
      const ApacheModuleForSelectedPhp: TApacheStringFunc; const GenerateAllConfigs: TApacheAction);
    function IsRunning: Boolean;
    function ProcessId: Cardinal;
    function Start: TRuntimeActionResult;
    function Stop: TRuntimeActionResult;
    function Restart: TRuntimeActionResult;
  end;

implementation

uses
  System.Classes,
  Winapi.Windows,
  System.IOUtils,
  System.StrUtils,
  Core.UniWamp.ProcessManager,
  Core.UniWamp.VHostManager,
  Core.UniWamp.TemplateRenderer,
  Core.UniWamp.ConfigGenerator,
  Core.UniWamp.AtomicFile,
  Core.UniWamp.PortUtils,
  Core.UniWamp.Diagnostics;

constructor TApacheManager.Create(const Paths: TAppPaths; Config: TUniWampConfig;
  const SelectedPhpDir: TApacheStringFunc; const SelectedPhpExe: TApacheStringFunc;
  const ApacheModuleForSelectedPhp: TApacheStringFunc; const GenerateAllConfigs: TApacheAction);
begin
  inherited Create;
  FPaths := Paths;
  FConfig := Config;
  FSelectedPhpDir := SelectedPhpDir;
  FSelectedPhpExe := SelectedPhpExe;
  FApacheModuleForSelectedPhp := ApacheModuleForSelectedPhp;
  FGenerateAllConfigs := GenerateAllConfigs;
end;

function TApacheManager.SelectedPhpDir: string;
begin
  if Assigned(FSelectedPhpDir) then
    Result := FSelectedPhpDir()
  else
    Result := '';
end;

function TApacheManager.SelectedPhpExe: string;
begin
  if Assigned(FSelectedPhpExe) then
    Result := FSelectedPhpExe()
  else
    Result := '';
end;

function TApacheManager.ApacheModuleForSelectedPhp: string;
begin
  if Assigned(FApacheModuleForSelectedPhp) then
    Result := FApacheModuleForSelectedPhp()
  else
    Result := '';
end;

function TApacheManager.ApacheExe: string;
begin
  Result := TPath.Combine(FPaths.ApacheBinDir, 'httpd.exe');
end;

function TApacheManager.ApacheRuntimePid: Cardinal;
begin
  Result := TServiceProcessSupervisor.ResolveOwnedProcess(
    FConfig.ApachePid,
    ApacheExe,
    TPath.Combine(FPaths.LogsDir, 'httpd.pid')).ProcessId;
end;

function TApacheManager.IsRunning: Boolean;
var
  State: TServiceProcessState;
begin
  State := TServiceProcessSupervisor.ResolveOwnedProcess(
    FConfig.ApachePid,
    ApacheExe,
    TPath.Combine(FPaths.LogsDir, 'httpd.pid'));
  Result := State.Running;
  ApplyApacheState(State);
end;

function TApacheManager.ProcessId: Cardinal;
begin
  Result := ApacheRuntimePid;
end;

procedure TApacheManager.ApplyApacheState(const State: TServiceProcessState);
begin
  FConfig.ApachePid := State.ProcessId;
  FConfig.ApacheRunning := State.Running;
end;

procedure TApacheManager.ClearApacheState;
begin
  FConfig.ApachePid := 0;
  FConfig.ApacheRunning := False;
end;

procedure TApacheManager.FailApacheStart(const ErrorMessage: string);
begin
  ClearApacheState;
  FConfig.LastApacheError := ErrorMessage;
end;

class function TApacheManager.ReadPeMachineType(const FileName: string; out Machine: Word): Boolean;
const
  MzSignature = $5A4D;      // 'MZ'
  PeSignature = $00004550;  // 'PE'#0#0
var
  Stream: TFileStream;
  DosMagic: Word;
  PeOffset: Integer;
  Signature: Cardinal;
  MachineWord: Word;
begin
  Result := False;
  Machine := 0;
  if not FileExists(FileName) then
    Exit;
  try
    Stream := TFileStream.Create(FileName, fmOpenRead or fmShareDenyNone);
    try
      if Stream.Size < 64 then
        Exit;
      Stream.ReadBuffer(DosMagic, SizeOf(DosMagic));
      if DosMagic <> MzSignature then
        Exit;
      Stream.Position := $3C;
      Stream.ReadBuffer(PeOffset, SizeOf(PeOffset));
      if (PeOffset <= 0) or (Int64(PeOffset) + 6 > Stream.Size) then
        Exit;
      Stream.Position := PeOffset;
      Stream.ReadBuffer(Signature, SizeOf(Signature));
      if Signature <> PeSignature then
        Exit;
      Stream.ReadBuffer(MachineWord, SizeOf(MachineWord));
      Machine := MachineWord;
      Result := True;
    finally
      Stream.Free;
    end;
  except
    Machine := 0;
    Result := False;
  end;
end;

function PeMachineName(const Machine: Word): string;
begin
  case Machine of
    $014C: Result := 'x86';
    $8664: Result := 'x64';
    $AA64: Result := 'arm64';
    $01C0: Result := 'arm';
  else
    Result := Format('0x%.4x', [Machine]);
  end;
end;

function TApacheManager.HasAppLocalApacheVisualCRuntime(out ErrorMessage: string): Boolean;
const
  // VC++ 2015-2022 runtime files the shipped x64 Apache build needs. httpd.exe,
  // libhttpd.dll and every shipped Apache module import VCRUNTIME140.dll
  // directly; VCRUNTIME140_1.dll and MSVCP140.dll belong to the same runtime set
  // and are required when C++-based components (for example PHP's intl
  // extension) load inside the Apache process.
  RequiredRuntimeDlls: array[0..2] of string = (
    'vcruntime140.dll',
    'vcruntime140_1.dll',
    'msvcp140.dll'
  );
var
  I: Integer;
  DllPath: string;
  ApacheMachine: Word;
  DllMachine: Word;
begin
  Result := False;
  ErrorMessage := '';

  // Only authoritative when the Apache binary itself is present and readable, so
  // the app-local runtime can be validated against its actual architecture. When
  // Apache is missing this returns False without an error and the caller keeps
  // the previous machine-wide behavior.
  if not FileExists(ApacheExe) then
    Exit;
  if not ReadPeMachineType(ApacheExe, ApacheMachine) then
    Exit; // Unreadable Apache binary: fall back to the machine-wide runtime check.

  for I := Low(RequiredRuntimeDlls) to High(RequiredRuntimeDlls) do
  begin
    DllPath := TPath.Combine(FPaths.ApacheBinDir, RequiredRuntimeDlls[I]);
    if not FileExists(DllPath) then
    begin
      ErrorMessage := 'App-local VC++ runtime is incomplete: ' + RequiredRuntimeDlls[I] +
        ' is missing from ' + FPaths.ApacheBinDir + '.';
      Exit;
    end;
    if not ReadPeMachineType(DllPath, DllMachine) then
    begin
      ErrorMessage := 'App-local VC++ runtime file could not be read: ' + DllPath + '.';
      Exit;
    end;
    if DllMachine <> ApacheMachine then
    begin
      ErrorMessage := Format(
        'App-local VC++ runtime architecture mismatch: %s is %s but Apache (%s) is %s.',
        [RequiredRuntimeDlls[I], PeMachineName(DllMachine), ExtractFileName(ApacheExe),
         PeMachineName(ApacheMachine)]);
      Exit;
    end;
  end;

  Result := True;
end;

function TApacheManager.HasRequiredApacheVisualCRuntime(out ErrorMessage: string): Boolean;
var
  Registry: TRegistry;
  Installed: Integer;
  SystemRoot: string;
  RuntimeDll: string;
  VersionText: string;
  AppLocalError: string;
begin
  ErrorMessage := '';
  VersionText := '';

  if SameText(Trim(GetEnvironmentVariable('UNIWAMP_FORCE_MISSING_VC_RUNTIME')), '1') then
  begin
    ErrorMessage := 'Microsoft Visual C++ Redistributable 2015-2022 (x64) is required for Apache 2.4.68 (Apache Lounge VS18). Install or repair the latest vc_redist.x64, then restart UniWamp.';
    Exit(False);
  end;

  // Portable path first: when the VC++ runtime ships beside Apache and matches
  // the Apache binary architecture, no machine-wide redistributable is required
  // and no registry lookup is performed.
  AppLocalError := '';
  if HasAppLocalApacheVisualCRuntime(AppLocalError) then
    Exit(True);

  Registry := TRegistry.Create(KEY_READ or KEY_WOW64_64KEY);
  try
    Registry.RootKey := HKEY_LOCAL_MACHINE;
    if Registry.OpenKeyReadOnly('SOFTWARE\Microsoft\VisualStudio\14.0\VC\Runtimes\x64') then
    try
      if Registry.ValueExists('Version') then
        VersionText := Trim(Registry.ReadString('Version'));
      if Registry.ValueExists('Installed') then
      begin
        Installed := Registry.ReadInteger('Installed');
        if Installed = 1 then
          Exit(True);
      end;
    finally
      Registry.CloseKey;
    end;
  finally
    Registry.Free;
  end;

  SystemRoot := GetEnvironmentVariable('SystemRoot');
  if SystemRoot <> '' then
  begin
    RuntimeDll := TPath.Combine(TPath.Combine(SystemRoot, 'System32'), 'vcruntime140.dll');
    if FileExists(RuntimeDll) then
      Exit(True);
  end;

  ErrorMessage := 'Microsoft Visual C++ Redistributable 2015-2022 (x64) is required for Apache 2.4.68 (Apache Lounge VS18). Install or repair the latest vc_redist.x64, then restart UniWamp.';
  if AppLocalError <> '' then
    ErrorMessage := ErrorMessage + ' ' + AppLocalError;
  if VersionText <> '' then
    ErrorMessage := ErrorMessage + ' Detected registry version: ' + VersionText + '.';
  Result := False;
end;

function TApacheManager.PushPhpRuntimeToPath(const PhpDir: string; out OldPath: string): Boolean;
var
  NewPath: string;
begin
  OldPath := GetEnvironmentVariable('PATH');
  Result := Trim(PhpDir) <> '';
  if not Result then
    Exit;

  NewPath := PhpDir;
  if DirectoryExists(TPath.Combine(PhpDir, 'ext')) then
    NewPath := NewPath + ';' + TPath.Combine(PhpDir, 'ext');
  if Trim(OldPath) <> '' then
    NewPath := NewPath + ';' + OldPath;
  Result := SetEnvironmentVariable('PATH', PChar(NewPath));
end;

procedure TApacheManager.RestorePath(const OldPath: string);
begin
  SetEnvironmentVariable('PATH', PChar(OldPath));
end;

function TApacheManager.ValidateApachePorts(out ErrorMessage: string): Boolean;
var
  ApacheRunningNow: Boolean;
  OwnerInfo: string;
begin
  Result := True;
  ErrorMessage := '';
  ApacheRunningNow := IsRunning or FConfig.ApacheRunning;
  if not IsTcpPortAvailable(FConfig.HttpPort) and not ApacheRunningNow then
  begin
    Result := False;
    OwnerInfo := DescribeTcpPortOwner(FConfig.HttpPort);
    if OwnerInfo <> '' then
      ErrorMessage := Format('HTTP port %d is already in use by %s.', [FConfig.HttpPort, OwnerInfo])
    else
      ErrorMessage := Format('HTTP port %d is already in use.', [FConfig.HttpPort]);
    Exit;
  end;
  if FConfig.EnableSsl and not IsTcpPortAvailable(FConfig.HttpsPort) and not ApacheRunningNow then
  begin
    Result := False;
    OwnerInfo := DescribeTcpPortOwner(FConfig.HttpsPort);
    if OwnerInfo <> '' then
      ErrorMessage := Format('HTTPS port %d is already in use by %s.', [FConfig.HttpsPort, OwnerInfo])
    else
      ErrorMessage := Format('HTTPS port %d is already in use.', [FConfig.HttpsPort]);
    Exit;
  end;
end;

function TApacheManager.ValidateApacheConfiguration(out ErrorMessage: string): Boolean;
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

function TApacheManager.WaitForApacheStartup(const ProcessId: Cardinal; out ErrorMessage: string): Boolean;
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

function TApacheManager.Start: TRuntimeActionResult;
var
  StartResult: TProcessStartResult;
  ErrorMessage: string;
  VHostManager: TVHostManager;
  OldPath: string;
begin
  if FConfig.ApacheRunning and not IsRunning then
  begin
    FConfig.LastApacheError := 'Stale Apache state detected; retrying start.';
    ClearApacheState;
  end;

  if IsRunning then
  begin
    FConfig.LastApacheError := '';
    Result.Success := True;
    Result.Message := 'Apache already running.';
    Exit;
  end;

  Result.Success := False;
  if not ValidateApachePorts(ErrorMessage) then
  begin
    FailApacheStart(ErrorMessage);
    Result.Message := ErrorMessage;
    Exit;
  end;

  if not FileExists(SelectedPhpExe) then
  begin
    FailApacheStart('Selected PHP runtime is missing: ' + SelectedPhpExe);
    Result.Message := 'Selected PHP runtime is missing: ' + SelectedPhpExe;
    Exit;
  end;

  if not FileExists(ApacheModuleForSelectedPhp) then
  begin
    FailApacheStart('Apache PHP module missing for current selected PHP version.');
    Result.Message := 'Apache PHP module missing for current selected PHP version.';
    Exit;
  end;

  if not HasRequiredApacheVisualCRuntime(ErrorMessage) then
  begin
    FailApacheStart(ErrorMessage);
    Result.Message := ErrorMessage;
    Exit;
  end;

  if FConfig.EnableSsl then
  begin
    VHostManager := TVHostManager.Create(FPaths, FConfig);
    try
      if not VHostManager.EnsureDefaultSslCertificate(ErrorMessage) then
      begin
        FailApacheStart(ErrorMessage);
        Result.Message := ErrorMessage;
        Exit;
      end;
    finally
      VHostManager.Free;
    end;
  end;

  if Assigned(FGenerateAllConfigs) then
    FGenerateAllConfigs();
  if not ValidateApacheConfiguration(ErrorMessage) then
  begin
    FailApacheStart(ErrorMessage);
    Result.Message := ErrorMessage;
    Exit;
  end;
  AppendTextToLogFile(TPath.Combine(FPaths.LogsDir, 'apache-error.log'), 'Starting Apache: ' + ApacheExe);
  if not PushPhpRuntimeToPath(SelectedPhpDir, OldPath) then
  begin
    FailApacheStart('Unable to prepare PHP runtime environment for Apache.');
    Result.Success := False;
    Result.Message := 'Unable to prepare PHP runtime environment for Apache.';
    Exit;
  end;
  try
    StartResult := TProcessManager.StartDetached(
      ApacheExe,
      '-f "' + FPaths.ApacheHttpdConfFile + '"',
      FPaths.ApacheBinDir);
  finally
    RestorePath(OldPath);
  end;

  Result.Success := StartResult.Success;
  if StartResult.Success then
  begin
    FConfig.ApachePid := StartResult.ProcessId;
    if WaitForApacheStartup(StartResult.ProcessId, ErrorMessage) then
    begin
      FConfig.ApacheRunning := True;
      FConfig.LastApacheError := '';
      Result.Message := 'Apache started.';
      AppendTextToLogFile(TPath.Combine(FPaths.LogsDir, 'activity.log'), 'Apache started.');
      AppendTextToLogFile(TPath.Combine(FPaths.LogsDir, 'apache-error.log'), 'Apache successfully started with PID ' + StartResult.ProcessId.ToString);
    end
    else
    begin
      FailApacheStart(ErrorMessage);
      Result.Success := False;
      Result.Message := ErrorMessage;
    end;
  end
  else
  begin
    FailApacheStart(StartResult.ErrorMessage);
    Result.Message := StartResult.ErrorMessage;
    AppendTextToLogFile(TPath.Combine(FPaths.LogsDir, 'apache-error.log'), 'Apache failed to start: ' + StartResult.ErrorMessage);
  end;
end;

function TApacheManager.Stop: TRuntimeActionResult;
var
  StartResult: TProcessStartResult;
  State: TServiceProcessState;
  SystemRoot: string;
begin
  Result.Success := True;
  AppendTextToLogFile(TPath.Combine(FPaths.LogsDir, 'apache-error.log'), 'Initiating Apache shutdown...');
  State := TServiceProcessSupervisor.ResolveOwnedProcess(
    FConfig.ApachePid,
    ApacheExe,
    TPath.Combine(FPaths.LogsDir, 'httpd.pid'));
  if not State.Running then
  begin
    ClearApacheState;
    Result.Message := 'Apache stopped.';
    AppendTextToLogFile(TPath.Combine(FPaths.LogsDir, 'apache-error.log'), Result.Message);
    Exit;
  end;
  if FileExists(ApacheExe) then
  begin
    StartResult := TProcessManager.StartDetached(
      ApacheExe,
      '-k stop -f "' + FPaths.ApacheHttpdConfFile + '"',
      FPaths.ApacheBinDir);
    if StartResult.Success then
      TProcessManager.WaitForExit(StartResult.ProcessId, 4000);
  end;

  Result.Success := TServiceProcessSupervisor.StopOwnedProcess(State) and Result.Success;

  if (State.ProcessId <> 0) and not IsTcpPortAvailable(FConfig.HttpPort) then
  begin
    SystemRoot := TPath.Combine(GetEnvironmentVariable('SystemRoot'), 'System32');
    StartResult := TProcessManager.StartDetached(
      TPath.Combine(SystemRoot, 'taskkill.exe'),
      '/PID ' + State.ProcessId.ToString + ' /T /F',
      SystemRoot);
    if StartResult.Success then
      TProcessManager.WaitForExit(StartResult.ProcessId, 4000);
  end;

  if (State.ProcessId <> 0) and FConfig.EnableSsl and (not IsTcpPortAvailable(FConfig.HttpsPort)) then
  begin
    SystemRoot := TPath.Combine(GetEnvironmentVariable('SystemRoot'), 'System32');
    StartResult := TProcessManager.StartDetached(
      TPath.Combine(SystemRoot, 'taskkill.exe'),
      '/PID ' + State.ProcessId.ToString + ' /T /F',
      SystemRoot);
    if StartResult.Success then
      TProcessManager.WaitForExit(StartResult.ProcessId, 4000);
  end;

  Sleep(1000);

  ClearApacheState;
  Result.Success := Result.Success and IsTcpPortAvailable(FConfig.HttpPort) and
    ((not FConfig.EnableSsl) or IsTcpPortAvailable(FConfig.HttpsPort));
  if Result.Success then
    Result.Message := 'Apache stopped.'
  else
    Result.Message := 'Failed to stop Apache cleanly.';
  AppendTextToLogFile(TPath.Combine(FPaths.LogsDir, 'apache-error.log'), Result.Message);
end;

function TApacheManager.Restart: TRuntimeActionResult;
begin
  Result := Stop;
  if not Result.Success then
  begin
    Result.Message := 'Apache restart failed during stop: ' + Result.Message;
    FConfig.LastApacheError := Result.Message;
    Exit;
  end;
  Sleep(500);
  Result := Start;
  if not Result.Success then
  begin
    Result.Message := 'Apache restart failed during start: ' + Result.Message;
    FConfig.LastApacheError := Result.Message;
  end;
end;

end.