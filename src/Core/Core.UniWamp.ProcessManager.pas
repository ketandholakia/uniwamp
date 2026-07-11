unit Core.UniWamp.ProcessManager;

interface

uses
  Winapi.Windows,
  System.SysUtils;

type
  TProcessStartResult = record
    Success: Boolean;
    ProcessId: Cardinal;
    ErrorMessage: string;
  end;

  TProcessManager = class
  public
    class function StartDetached(const ExecutablePath, Arguments, WorkingDirectory: string): TProcessStartResult; static;
    class function StopProcess(const ProcessId: Cardinal; const ForceAfterMs: Cardinal = 4000): Boolean; static;
    class function WaitForExit(const ProcessId: Cardinal; const TimeoutMs: Cardinal): Boolean; static;
    class function IsRunning(const ProcessId: Cardinal): Boolean; static;
  end;

implementation

class function TProcessManager.StartDetached(const ExecutablePath, Arguments,
  WorkingDirectory: string): TProcessStartResult;
var
  StartupInfo: TStartupInfo;
  ProcessInfo: TProcessInformation;
  CommandLine: string;
begin
  Result.Success := False;
  Result.ProcessId := 0;
  Result.ErrorMessage := '';

  if not FileExists(ExecutablePath) then
  begin
    Result.ErrorMessage := 'Executable not found: ' + ExecutablePath;
    Exit;
  end;

  ZeroMemory(@StartupInfo, SizeOf(StartupInfo));
  StartupInfo.cb := SizeOf(StartupInfo);
  StartupInfo.dwFlags := STARTF_USESHOWWINDOW;
  StartupInfo.wShowWindow := SW_HIDE;
  ZeroMemory(@ProcessInfo, SizeOf(ProcessInfo));

  CommandLine := '"' + ExecutablePath + '"';
  if Arguments <> '' then
    CommandLine := CommandLine + ' ' + Arguments;
  UniqueString(CommandLine);

  if CreateProcess(nil, PChar(CommandLine), nil, nil, False, CREATE_NO_WINDOW,
    nil, PChar(WorkingDirectory), StartupInfo, ProcessInfo) then
  begin
    Result.Success := True;
    Result.ProcessId := ProcessInfo.dwProcessId;
    CloseHandle(ProcessInfo.hThread);
    CloseHandle(ProcessInfo.hProcess);
  end
  else
    Result.ErrorMessage := SysErrorMessage(GetLastError);
end;

class function TProcessManager.WaitForExit(const ProcessId: Cardinal;
  const TimeoutMs: Cardinal): Boolean;
var
  Handle: THandle;
begin
  Result := True;
  if ProcessId = 0 then
    Exit;
  Handle := OpenProcess(SYNCHRONIZE, False, ProcessId);
  if Handle = 0 then
    Exit(True);
  try
    Result := WaitForSingleObject(Handle, TimeoutMs) = WAIT_OBJECT_0;
  finally
    CloseHandle(Handle);
  end;
end;

class function TProcessManager.StopProcess(const ProcessId: Cardinal;
  const ForceAfterMs: Cardinal): Boolean;
var
  Handle: THandle;
begin
  Result := True;
  if ProcessId = 0 then
    Exit;

  Handle := OpenProcess(PROCESS_TERMINATE or SYNCHRONIZE or PROCESS_QUERY_INFORMATION,
    False, ProcessId);
  if Handle = 0 then
    Exit(True);
  try
    if WaitForSingleObject(Handle, 0) = WAIT_OBJECT_0 then
      Exit(True);
    Result := TerminateProcess(Handle, 0);
    if Result then
      Result := WaitForSingleObject(Handle, ForceAfterMs) = WAIT_OBJECT_0;
  finally
    CloseHandle(Handle);
  end;
end;

class function TProcessManager.IsRunning(const ProcessId: Cardinal): Boolean;
var
  Handle: THandle;
  ExitCode: Cardinal;
begin
  Result := False;
  if ProcessId = 0 then
    Exit;
  Handle := OpenProcess(PROCESS_QUERY_INFORMATION, False, ProcessId);
  if Handle = 0 then
    Exit;
  try
    if GetExitCodeProcess(Handle, ExitCode) then
      Result := ExitCode = STILL_ACTIVE;
  finally
    CloseHandle(Handle);
  end;
end;

end.
