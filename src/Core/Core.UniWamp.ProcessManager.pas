unit Core.UniWamp.ProcessManager;

interface

uses
  Winapi.Windows,
  System.Classes,
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
    class function RunAndCaptureOutput(const ExecutablePath, Arguments, WorkingDirectory: string;
      out Output: string; const TimeoutMs: Cardinal = 0): Boolean; static;
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

class function TProcessManager.RunAndCaptureOutput(const ExecutablePath, Arguments,
  WorkingDirectory: string; out Output: string; const TimeoutMs: Cardinal): Boolean;
var
  StartupInfo: TStartupInfo;
  ProcessInfo: TProcessInformation;
  CommandLine: string;
  ReadPipe: THandle;
  WritePipe: THandle;
  SecurityAttributes: TSecurityAttributes;
  Buffer: array[0..4095] of Byte;
  BytesRead: DWORD;
  BytesAvailable: DWORD;
  Chunk: TBytes;
  Captured: TBytesStream;
  StartTick: UInt64;
  TimedOut: Boolean;
begin
  Output := '';
  Result := False;
  ReadPipe := 0;
  WritePipe := 0;
  TimedOut := False;

  if not FileExists(ExecutablePath) then
    Exit;

  ZeroMemory(@SecurityAttributes, SizeOf(SecurityAttributes));
  SecurityAttributes.nLength := SizeOf(SecurityAttributes);
  SecurityAttributes.bInheritHandle := True;
  SecurityAttributes.lpSecurityDescriptor := nil;

  if not CreatePipe(ReadPipe, WritePipe, @SecurityAttributes, 0) then
    Exit;
  try
    if not SetHandleInformation(ReadPipe, HANDLE_FLAG_INHERIT, 0) then
      Exit;

    ZeroMemory(@StartupInfo, SizeOf(StartupInfo));
    StartupInfo.cb := SizeOf(StartupInfo);
    StartupInfo.dwFlags := STARTF_USESHOWWINDOW or STARTF_USESTDHANDLES;
    StartupInfo.wShowWindow := SW_HIDE;
    StartupInfo.hStdOutput := WritePipe;
    StartupInfo.hStdError := WritePipe;
    StartupInfo.hStdInput := GetStdHandle(STD_INPUT_HANDLE);
    ZeroMemory(@ProcessInfo, SizeOf(ProcessInfo));

    CommandLine := '"' + ExecutablePath + '"';
    if Arguments <> '' then
      CommandLine := CommandLine + ' ' + Arguments;
    UniqueString(CommandLine);

    if not CreateProcess(nil, PChar(CommandLine), nil, nil, True, CREATE_NO_WINDOW,
      nil, PChar(WorkingDirectory), StartupInfo, ProcessInfo) then
      Exit;

    CloseHandle(WritePipe);
    WritePipe := 0;

    Captured := TBytesStream.Create;
    try
      StartTick := GetTickCount64;
      repeat
        while PeekNamedPipe(ReadPipe, nil, 0, nil, @BytesAvailable, nil) and (BytesAvailable > 0) do
        begin
          if BytesAvailable > SizeOf(Buffer) then
            BytesAvailable := SizeOf(Buffer);
          if not ReadFile(ReadPipe, Buffer, BytesAvailable, BytesRead, nil) or (BytesRead = 0) then
            Break;
          Captured.WriteBuffer(Buffer, BytesRead);
        end;

        if (TimeoutMs > 0) and ((GetTickCount64 - StartTick) >= TimeoutMs) then
        begin
          TimedOut := True;
          TerminateProcess(ProcessInfo.hProcess, 1);
          Break;
        end;
      until (WaitForSingleObject(ProcessInfo.hProcess, 50) = WAIT_OBJECT_0) and
        (not PeekNamedPipe(ReadPipe, nil, 0, nil, @BytesAvailable, nil) or (BytesAvailable = 0));

      while PeekNamedPipe(ReadPipe, nil, 0, nil, @BytesAvailable, nil) and (BytesAvailable > 0) do
      begin
        if BytesAvailable > SizeOf(Buffer) then
          BytesAvailable := SizeOf(Buffer);
        if not ReadFile(ReadPipe, Buffer, BytesAvailable, BytesRead, nil) or (BytesRead = 0) then
          Break;
        Captured.WriteBuffer(Buffer, BytesRead);
      end;

      if Captured.Size > 0 then
      begin
        SetLength(Chunk, Captured.Size);
        Captured.Position := 0;
        Captured.ReadBuffer(Chunk[0], Length(Chunk));
        Output := TEncoding.Default.GetString(Chunk);
      end;
      Result := not TimedOut;
    finally
      Captured.Free;
      CloseHandle(ProcessInfo.hProcess);
      CloseHandle(ProcessInfo.hThread);
    end;
  finally
    if WritePipe <> 0 then
      CloseHandle(WritePipe);
    CloseHandle(ReadPipe);
  end;
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
