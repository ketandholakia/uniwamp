unit Core.UniWamp.ProcessManager;

interface

uses
  Winapi.Windows,
  Winapi.Messages,
  Winapi.PsAPI,
  System.Classes,
  System.SysUtils;

type
  TProcessOutputEvent = reference to procedure(const Text: string);
  TProcessResultCallback = reference to procedure(const Success: Boolean; const Output: string);

  TProcessStartResult = record
    Success: Boolean;
    ProcessId: Cardinal;
    ErrorMessage: string;
  end;

  TProcessManager = class
  public
    class function StartDetached(const ExecutablePath, Arguments, WorkingDirectory: string): TProcessStartResult; static;
    class function RunAndCaptureOutput(const ExecutablePath, Arguments, WorkingDirectory: string;
      out Output: string; const TimeoutMs: Cardinal = 0;
      const OnOutput: TProcessOutputEvent = nil): Boolean; static;
    class procedure RunAndCaptureOutputAsync(const ExecutablePath, Arguments, WorkingDirectory: string;
      const TimeoutMs: Cardinal; const OnComplete: TProcessResultCallback); static;
    class function StopProcess(const ProcessId: Cardinal; const ForceAfterMs: Cardinal = 4000): Boolean; static;
    class function WaitForExit(const ProcessId: Cardinal; const TimeoutMs: Cardinal): Boolean; static;
    class function IsRunning(const ProcessId: Cardinal): Boolean; static;
    class function IsProcessExecutable(const ProcessId: Cardinal; const ExpectedExePath: string): Boolean; static;
  end;

implementation

uses
  System.Threading,
  Core.UniWamp.TaskRunner;

class procedure TProcessManager.RunAndCaptureOutputAsync(const ExecutablePath, Arguments,
  WorkingDirectory: string; const TimeoutMs: Cardinal; const OnComplete: TProcessResultCallback);
begin
  TTaskRunner.Run(
    procedure
    var
      Output: string;
      Success: Boolean;
    begin
      Success := RunAndCaptureOutput(ExecutablePath, Arguments, WorkingDirectory, Output, TimeoutMs);
      if Assigned(OnComplete) then
      begin
        TThread.Queue(nil,
          procedure
          begin
            OnComplete(Success, Output);
          end);
      end;
    end);
end;

class function TProcessManager.StartDetached(const ExecutablePath, Arguments,
  WorkingDirectory: string): TProcessStartResult;
var
  StartupInfo: TStartupInfo;
  ProcessInfo: TProcessInformation;
  CommandLine: string;
  PWorkingDir: PChar;
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

  if WorkingDirectory = '' then
    PWorkingDir := nil
  else
    PWorkingDir := PChar(WorkingDirectory);

  if CreateProcess(nil, PChar(CommandLine), nil, nil, False, CREATE_NO_WINDOW,
    nil, PWorkingDir, StartupInfo, ProcessInfo) then
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
  WorkingDirectory: string; out Output: string; const TimeoutMs: Cardinal;
  const OnOutput: TProcessOutputEvent): Boolean;
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
  ExitCode: DWORD;
  HasExitCode: Boolean;
  WaitResult: DWORD;
  Msg: TMsg;
  PWorkingDir: PChar;
begin
  Output := '';
  Result := False;
  ReadPipe := 0;
  WritePipe := 0;
  TimedOut := False;

  if not FileExists(ExecutablePath) then
  begin
    Output := 'Executable not found: ' + ExecutablePath;
    Exit;
  end;

  ZeroMemory(@SecurityAttributes, SizeOf(SecurityAttributes));
  SecurityAttributes.nLength := SizeOf(SecurityAttributes);
  SecurityAttributes.bInheritHandle := True;
  SecurityAttributes.lpSecurityDescriptor := nil;

  if not CreatePipe(ReadPipe, WritePipe, @SecurityAttributes, 0) then
  begin
    Output := SysErrorMessage(GetLastError);
    Exit;
  end;
  try
    if not SetHandleInformation(ReadPipe, HANDLE_FLAG_INHERIT, 0) then
    begin
      Output := SysErrorMessage(GetLastError);
      Exit;
    end;

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

    if WorkingDirectory = '' then
      PWorkingDir := nil
    else
      PWorkingDir := PChar(WorkingDirectory);

    if not CreateProcess(nil, PChar(CommandLine), nil, nil, True, CREATE_NO_WINDOW,
      nil, PWorkingDir, StartupInfo, ProcessInfo) then
    begin
      Output := SysErrorMessage(GetLastError);
      Exit;
    end;

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
          if Assigned(OnOutput) then
          begin
            SetLength(Chunk, BytesRead);
            Move(Buffer[0], Chunk[0], BytesRead);
            OnOutput(TEncoding.Default.GetString(Chunk));
          end;
        end;

        if (TimeoutMs > 0) and ((GetTickCount64 - StartTick) >= TimeoutMs) then
        begin
          TimedOut := True;
          TerminateProcess(ProcessInfo.hProcess, 1);
          Output := Format('Timed out after %d ms.', [TimeoutMs]);
          Break;
        end;

        if GetCurrentThreadId = MainThreadID then
        begin
          WaitResult := MsgWaitForMultipleObjects(1, ProcessInfo.hProcess, False, 50, QS_ALLEVENTS);
          if WaitResult = WAIT_OBJECT_0 + 1 then
          begin
            while PeekMessage(Msg, 0, 0, 0, PM_REMOVE) do
            begin
              TranslateMessage(Msg);
              DispatchMessage(Msg);
            end;
          end;
        end
        else
        begin
          WaitResult := WaitForSingleObject(ProcessInfo.hProcess, 50);
        end;
      until (WaitResult = WAIT_OBJECT_0) and
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
          if TimedOut then
            Output := Output + sLineBreak + TEncoding.Default.GetString(Chunk)
          else
            Output := TEncoding.Default.GetString(Chunk);
        end;
      HasExitCode := GetExitCodeProcess(ProcessInfo.hProcess, ExitCode);
      if not TimedOut and HasExitCode and (ExitCode <> 0) then
      begin
        if Trim(Output) <> '' then
          Output := Trim(Output) + sLineBreak + Format('Process exited with code %d.', [ExitCode])
        else
          Output := Format('Process exited with code %d.', [ExitCode]);
      end;
      Result := not TimedOut and (not HasExitCode or (ExitCode = 0));
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
    Exit(False);
  try
    Result := WaitForSingleObject(Handle, TimeoutMs) = WAIT_OBJECT_0;
  finally
    CloseHandle(Handle);
  end;
end;

type
  TEnumParams = record
    ProcessId: DWORD;
    WindowFound: Boolean;
  end;
  PEnumParams = ^TEnumParams;

function EnumWindowsProc(Wnd: HWND; LParam: LPARAM): BOOL; stdcall;
var
  WndProcessId: DWORD;
  Params: PEnumParams;
begin
  Params := PEnumParams(LParam);
  GetWindowThreadProcessId(Wnd, @WndProcessId);
  if WndProcessId = Params^.ProcessId then
  begin
    PostMessage(Wnd, WM_CLOSE, 0, 0);
    Params^.WindowFound := True;
  end;
  Result := True; // Continue enumeration
end;

class function TProcessManager.StopProcess(const ProcessId: Cardinal;
  const ForceAfterMs: Cardinal): Boolean;
var
  Handle: THandle;
  EnumParams: TEnumParams;
  WaitRes: DWORD;
begin
  Result := True;
  if ProcessId = 0 then
    Exit;

  Handle := OpenProcess(PROCESS_TERMINATE or SYNCHRONIZE or PROCESS_QUERY_INFORMATION,
    False, ProcessId);
  if Handle = 0 then
    Exit(False);
  try
    if WaitForSingleObject(Handle, 0) = WAIT_OBJECT_0 then
      Exit(True);

    // 1. Attempt graceful shutdown via WM_CLOSE
    EnumParams.ProcessId := ProcessId;
    EnumParams.WindowFound := False;
    EnumWindows(@EnumWindowsProc, LPARAM(@EnumParams));

    // 2. If it's a console app and no window was found, attempt AttachConsole
    if not EnumParams.WindowFound then
    begin
      if AttachConsole(ProcessId) then
      begin
        SetConsoleCtrlHandler(nil, True); // Ignore Ctrl+C for ourselves temporarily
        GenerateConsoleCtrlEvent(CTRL_C_EVENT, 0);
        Sleep(50); // Give it a moment to dispatch
        FreeConsole;
        SetConsoleCtrlHandler(nil, False); // Restore
      end;
    end;

    // 3. Wait for process to exit gracefully
    WaitRes := WaitForSingleObject(Handle, ForceAfterMs);
    if WaitRes = WAIT_OBJECT_0 then
      Exit(True);

    // 4. Force termination if still running
    Result := TerminateProcess(Handle, 0);
    if Result then
      Result := WaitForSingleObject(Handle, 2000) = WAIT_OBJECT_0;
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

class function TProcessManager.IsProcessExecutable(const ProcessId: Cardinal;
  const ExpectedExePath: string): Boolean;
var
  Handle: THandle;
  Buffer: array[0..MAX_PATH * 2 - 1] of Char;
  Size: DWORD;
  ExeName: string;
begin
  Result := False;
  if ProcessId = 0 then
    Exit;
    
  Handle := OpenProcess(PROCESS_QUERY_INFORMATION or PROCESS_VM_READ, False, ProcessId);
  if Handle = 0 then
  begin
    Handle := OpenProcess($1000 {PROCESS_QUERY_LIMITED_INFORMATION}, False, ProcessId);
    if Handle = 0 then Exit;
  end;
  try
    Size := Length(Buffer);
    if GetModuleFileNameExW(Handle, 0, Buffer, Size) > 0 then
    begin
      ExeName := Buffer;
      Result := SameText(ExeName, ExpectedExePath);
    end;
  finally
    CloseHandle(Handle);
  end;
end;

end.
