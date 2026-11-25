unit Core.UniWamp.ProcessManager;

interface

uses
  Winapi.Windows,
  Winapi.Messages,
  Winapi.PsAPI,
  System.Classes,
  System.SyncObjs,
  System.SysUtils;

type
  TProcessOutputEvent = reference to procedure(const Text: string);
  TProcessResultCallback = reference to procedure(const Success: Boolean; const Output: string);
  TProcessSessionEvent = reference to procedure(const Session: IInterface);

  TProcessStartResult = record
    Success: Boolean;
    ProcessId: Cardinal;
    ErrorMessage: string;
  end;

  IInteractiveProcessSession = interface
    ['{0C4C53D2-6A8C-4E7A-8F7B-7F2C1B5C3F64}']
    function ProcessId: Cardinal;
    function IsRunning: Boolean;
    function SendInput(const Text: string): Boolean;
    function SendLine(const Text: string): Boolean;
    function CloseInput: Boolean;
    function Terminate: Boolean;
    function WaitForExit(const TimeoutMs: Cardinal): Boolean;
    function CapturedOutput: string;
    function ExitCode: Cardinal;
    function Success: Boolean;
  end;

  TProcessManager = class
  public
    class function BuildEnvironmentWithPrependedPath(const PrependDirs: array of string): string; static;
    class function StartDetached(const ExecutablePath, Arguments, WorkingDirectory: string;
      const EnvironmentBlock: string = ''; const AssignToJob: Boolean = False): TProcessStartResult; static;
    class function StartInteractive(const ExecutablePath, Arguments, WorkingDirectory: string;
      const OnOutput: TProcessOutputEvent; out ErrorMessage: string): IInteractiveProcessSession; static;
    class function RunAndCaptureOutput(const ExecutablePath, Arguments, WorkingDirectory: string;
      out Output: string; const TimeoutMs: Cardinal = 0;
      const OnOutput: TProcessOutputEvent = nil): Boolean; static;
    class procedure RunAndCaptureOutputAsync(const ExecutablePath, Arguments, WorkingDirectory: string;
      const TimeoutMs: Cardinal; const OnComplete: TProcessResultCallback;
      const QueueThread: TThread = nil); static;
    class function StopProcess(const ProcessId: Cardinal; const ForceAfterMs: Cardinal = 4000): Boolean; static;
    class function WaitForExit(const ProcessId: Cardinal; const TimeoutMs: Cardinal): Boolean; static;
    class function IsRunning(const ProcessId: Cardinal): Boolean; static;
    class function IsProcessExecutable(const ProcessId: Cardinal; const ExpectedExePath: string): Boolean; static;
  end;

implementation

uses
  System.StrUtils,
  System.Threading,
  Core.UniWamp.TaskRunner;

type
  TManagedJob = class
  private
    FHandle: THandle;
    FLock: TCriticalSection;
  public
    constructor Create;
    destructor Destroy; override;
    function AssignProcess(const ProcessHandle: THandle): Boolean;
  end;

var
  GManagedJob: TManagedJob = nil;

function GetSharedManagedJob: TManagedJob;
begin
  if GManagedJob = nil then
    GManagedJob := TManagedJob.Create;
  Result := GManagedJob;
end;

constructor TManagedJob.Create;
var
  Info: TJobObjectExtendedLimitInformation;
begin
  inherited Create;
  FLock := TCriticalSection.Create;
  FHandle := CreateJobObject(nil, nil);
  if FHandle <> 0 then
  begin
    ZeroMemory(@Info, SizeOf(Info));
    Info.BasicLimitInformation.LimitFlags := JOB_OBJECT_LIMIT_KILL_ON_JOB_CLOSE;
    SetInformationJobObject(FHandle, JobObjectExtendedLimitInformation, @Info, SizeOf(Info));
  end;
end;

destructor TManagedJob.Destroy;
begin
  if FHandle <> 0 then
  begin
    CloseHandle(FHandle);
    FHandle := 0;
  end;
  FLock.Free;
  inherited Destroy;
end;

function TManagedJob.AssignProcess(const ProcessHandle: THandle): Boolean;
begin
  FLock.Acquire;
  try
    Result := (FHandle <> 0) and AssignProcessToJobObject(FHandle, ProcessHandle);
  finally
    FLock.Release;
  end;
end;

type
  TInteractiveProcessSession = class(TInterfacedObject, IInteractiveProcessSession)
  private
    FProcessInfo: TProcessInformation;
    FStdoutRead: THandle;
    FStdoutWrite: THandle;
    FStdinRead: THandle;
    FStdinWrite: THandle;
    FOutputCallback: TProcessOutputEvent;
    FOutputLock: TCriticalSection;
    FCapturedOutput: string;
    FCompletedEvent: TEvent;
    FWorkerThread: TThread;
    FExitCode: Cardinal;
    FHasExitCode: Boolean;
    FRunning: Boolean;
    FStartSucceeded: Boolean;
    procedure AppendOutputChunk(const Text: string);
    procedure FinalizeProcess;
    procedure RunWorker;
  public
    constructor Create(const ExecutablePath, Arguments, WorkingDirectory: string;
      const OnOutput: TProcessOutputEvent; out ErrorMessage: string);
    destructor Destroy; override;
    function ProcessId: Cardinal;
    function IsRunning: Boolean;
    function SendInput(const Text: string): Boolean;
    function SendLine(const Text: string): Boolean;
    function CloseInput: Boolean;
    function Terminate: Boolean;
    function WaitForExit(const TimeoutMs: Cardinal): Boolean;
    function CapturedOutput: string;
    function ExitCode: Cardinal;
    function Success: Boolean;
  end;

constructor TInteractiveProcessSession.Create(const ExecutablePath, Arguments,
  WorkingDirectory: string; const OnOutput: TProcessOutputEvent; out ErrorMessage: string);
var
  StartupInfo: TStartupInfo;
  CommandLine: string;
  PWorkingDir: PChar;
  SecurityAttributes: TSecurityAttributes;
begin
  inherited Create;
  ErrorMessage := '';
  FStdoutRead := 0;
  FStdoutWrite := 0;
  FStdinRead := 0;
  FStdinWrite := 0;
  FOutputCallback := OnOutput;
  FOutputLock := TCriticalSection.Create;
  FCompletedEvent := TEvent.Create(nil, True, False, '');
  FRunning := False;
  FStartSucceeded := False;
  FExitCode := 0;
  FHasExitCode := False;

  if not FileExists(ExecutablePath) then
  begin
    ErrorMessage := 'Executable not found: ' + ExecutablePath;
    Exit;
  end;

  ZeroMemory(@SecurityAttributes, SizeOf(SecurityAttributes));
  SecurityAttributes.nLength := SizeOf(SecurityAttributes);
  SecurityAttributes.bInheritHandle := True;
  SecurityAttributes.lpSecurityDescriptor := nil;

  if not CreatePipe(FStdoutRead, FStdoutWrite, @SecurityAttributes, 0) then
  begin
    ErrorMessage := SysErrorMessage(GetLastError);
    Exit;
  end;
  if not SetHandleInformation(FStdoutRead, HANDLE_FLAG_INHERIT, 0) then
  begin
    ErrorMessage := SysErrorMessage(GetLastError);
    Exit;
  end;

  if not CreatePipe(FStdinRead, FStdinWrite, @SecurityAttributes, 0) then
  begin
    ErrorMessage := SysErrorMessage(GetLastError);
    Exit;
  end;
  if not SetHandleInformation(FStdinWrite, HANDLE_FLAG_INHERIT, 0) then
  begin
    ErrorMessage := SysErrorMessage(GetLastError);
    Exit;
  end;

  ZeroMemory(@StartupInfo, SizeOf(StartupInfo));
  StartupInfo.cb := SizeOf(StartupInfo);
  StartupInfo.dwFlags := STARTF_USESHOWWINDOW or STARTF_USESTDHANDLES;
  StartupInfo.wShowWindow := SW_HIDE;
  StartupInfo.hStdOutput := FStdoutWrite;
  StartupInfo.hStdError := FStdoutWrite;
  StartupInfo.hStdInput := FStdinRead;
  ZeroMemory(@FProcessInfo, SizeOf(FProcessInfo));

  CommandLine := '"' + ExecutablePath + '"';
  if Arguments <> '' then
    CommandLine := CommandLine + ' ' + Arguments;
  UniqueString(CommandLine);

  if WorkingDirectory = '' then
    PWorkingDir := nil
  else
    PWorkingDir := PChar(WorkingDirectory);

  if not CreateProcess(nil, PChar(CommandLine), nil, nil, True, CREATE_NO_WINDOW,
    nil, PWorkingDir, StartupInfo, FProcessInfo) then
  begin
    ErrorMessage := SysErrorMessage(GetLastError);
    Exit;
  end;

  FStartSucceeded := True;
  FRunning := True;

  CloseHandle(FStdoutWrite);
  FStdoutWrite := 0;
  CloseHandle(FStdinRead);
  FStdinRead := 0;

  FWorkerThread := TThread.CreateAnonymousThread(
    procedure
    begin
      RunWorker;
    end);
  FWorkerThread.FreeOnTerminate := False;
  FWorkerThread.Start;
end;

destructor TInteractiveProcessSession.Destroy;
begin
  Terminate;
  CloseInput;
  if Assigned(FWorkerThread) then
  begin
    FWorkerThread.WaitFor;
    FWorkerThread.Free;
  end;
  if FCompletedEvent <> nil then
    FCompletedEvent.Free;
  if FOutputLock <> nil then
    FOutputLock.Free;
  if FStdoutRead <> 0 then
    CloseHandle(FStdoutRead);
  if FStdoutWrite <> 0 then
    CloseHandle(FStdoutWrite);
  if FStdinRead <> 0 then
    CloseHandle(FStdinRead);
  if FStdinWrite <> 0 then
    CloseHandle(FStdinWrite);
  if FStartSucceeded then
  begin
    if FProcessInfo.hThread <> 0 then
      CloseHandle(FProcessInfo.hThread);
    if FProcessInfo.hProcess <> 0 then
      CloseHandle(FProcessInfo.hProcess);
  end;
  inherited;
end;

procedure TInteractiveProcessSession.AppendOutputChunk(const Text: string);
begin
  if Text = '' then
    Exit;
  FOutputLock.Acquire;
  try
    FCapturedOutput := FCapturedOutput + Text;
  finally
    FOutputLock.Release;
  end;
  if Assigned(FOutputCallback) then
    FOutputCallback(Text);
end;

procedure TInteractiveProcessSession.FinalizeProcess;
begin
  FRunning := False;
  if FCompletedEvent <> nil then
    FCompletedEvent.SetEvent;
end;

procedure TInteractiveProcessSession.RunWorker;
var
  Buffer: array[0..4095] of Byte;
  BytesRead: DWORD;
  BytesAvailable: DWORD;
  Chunk: TBytes;
  WaitResult: DWORD;
  ExitCode: DWORD;
begin
  try
    repeat
      while PeekNamedPipe(FStdoutRead, nil, 0, nil, @BytesAvailable, nil) and (BytesAvailable > 0) do
      begin
        if BytesAvailable > SizeOf(Buffer) then
          BytesAvailable := SizeOf(Buffer);
        if not ReadFile(FStdoutRead, Buffer, BytesAvailable, BytesRead, nil) or (BytesRead = 0) then
          Break;
        SetLength(Chunk, BytesRead);
        Move(Buffer[0], Chunk[0], BytesRead);
        AppendOutputChunk(TEncoding.Default.GetString(Chunk));
      end;

      WaitResult := WaitForSingleObject(FProcessInfo.hProcess, 50);
    until (WaitResult = WAIT_OBJECT_0) and
      (not PeekNamedPipe(FStdoutRead, nil, 0, nil, @BytesAvailable, nil) or (BytesAvailable = 0));

    while PeekNamedPipe(FStdoutRead, nil, 0, nil, @BytesAvailable, nil) and (BytesAvailable > 0) do
    begin
      if BytesAvailable > SizeOf(Buffer) then
        BytesAvailable := SizeOf(Buffer);
      if not ReadFile(FStdoutRead, Buffer, BytesAvailable, BytesRead, nil) or (BytesRead = 0) then
        Break;
      SetLength(Chunk, BytesRead);
      Move(Buffer[0], Chunk[0], BytesRead);
      AppendOutputChunk(TEncoding.Default.GetString(Chunk));
    end;

    FHasExitCode := GetExitCodeProcess(FProcessInfo.hProcess, ExitCode);
    if FHasExitCode then
      FExitCode := ExitCode;
    if FHasExitCode and (FExitCode <> 0) then
    begin
      if Trim(FCapturedOutput) <> '' then
        AppendOutputChunk(sLineBreak);
      AppendOutputChunk(Format('Process exited with code %d.', [FExitCode]));
    end;
  finally
    FinalizeProcess;
  end;
end;

function TInteractiveProcessSession.ProcessId: Cardinal;
begin
  Result := 0;
  if FStartSucceeded then
    Result := FProcessInfo.dwProcessId;
end;

function TInteractiveProcessSession.IsRunning: Boolean;
begin
  Result := FRunning;
end;

function TInteractiveProcessSession.SendInput(const Text: string): Boolean;
var
  Data: TBytes;
  Written: DWORD;
begin
  Result := False;
  if FStdinWrite = 0 then
    Exit;
  Data := TEncoding.Default.GetBytes(Text);
  if Length(Data) = 0 then
    Exit(True);
  FOutputLock.Acquire;
  try
    Result := WriteFile(FStdinWrite, Data[0], Length(Data), Written, nil) and (Written = DWORD(Length(Data)));
  finally
    FOutputLock.Release;
  end;
end;

function TInteractiveProcessSession.SendLine(const Text: string): Boolean;
begin
  Result := SendInput(Text + sLineBreak);
end;

function TInteractiveProcessSession.CloseInput: Boolean;
begin
  Result := True;
  if FStdinWrite <> 0 then
  begin
    FOutputLock.Acquire;
    try
      if FStdinWrite <> 0 then
      begin
        Result := CloseHandle(FStdinWrite);
        FStdinWrite := 0;
      end;
    finally
      FOutputLock.Release;
    end;
  end;
end;

function TInteractiveProcessSession.Terminate: Boolean;
begin
  Result := True;
  if FStartSucceeded and FRunning then
    Result := TerminateProcess(FProcessInfo.hProcess, 1);
end;

function TInteractiveProcessSession.WaitForExit(const TimeoutMs: Cardinal): Boolean;
var
  WaitResult: TWaitResult;
begin
  if not FStartSucceeded then
    Exit(True);
  if TimeoutMs = 0 then
    WaitResult := FCompletedEvent.WaitFor(INFINITE)
  else
    WaitResult := FCompletedEvent.WaitFor(TimeoutMs);
  Result := WaitResult = wrSignaled;
end;

function TInteractiveProcessSession.CapturedOutput: string;
begin
  FOutputLock.Acquire;
  try
    Result := FCapturedOutput;
  finally
    FOutputLock.Release;
  end;
end;

function TInteractiveProcessSession.ExitCode: Cardinal;
begin
  Result := FExitCode;
end;

function TInteractiveProcessSession.Success: Boolean;
begin
  Result := FHasExitCode and (FExitCode = 0);
end;

class procedure TProcessManager.RunAndCaptureOutputAsync(const ExecutablePath, Arguments,
  WorkingDirectory: string; const TimeoutMs: Cardinal; const OnComplete: TProcessResultCallback;
  const QueueThread: TThread);
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
        if Assigned(QueueThread) then
          TThread.Queue(QueueThread,
            procedure
            begin
              OnComplete(Success, Output);
            end)
        else
          OnComplete(Success, Output);
      end;
    end,
    nil,
    nil,
    QueueThread);
end;

function CompareEnvVarsCaseInsensitive(List: TStringList; Index1, Index2: Integer): Integer;
begin
  Result := CompareText(List[Index1], List[Index2]);
end;

class function TProcessManager.BuildEnvironmentWithPrependedPath(const PrependDirs: array of string): string;
var
  EnvPtr: PChar;
  P: PChar;
  Lines: TStringList;
  I: Integer;
  NewPath: string;
  ExistingPath: string;
  Entry: string;
  FoundPath: Boolean;
begin
  NewPath := '';
  for Entry in PrependDirs do
    if (Trim(Entry) <> '') and DirectoryExists(Entry) then
      NewPath := NewPath + Entry + ';';

  ExistingPath := GetEnvironmentVariable('PATH');
  if Trim(ExistingPath) <> '' then
    NewPath := NewPath + ExistingPath
  else if NewPath.EndsWith(';') then
    Delete(NewPath, Length(NewPath), 1);

  Lines := TStringList.Create;
  EnvPtr := GetEnvironmentStrings;
  try
    FoundPath := False;
    if EnvPtr <> nil then
    begin
      P := EnvPtr;
      while P^ <> #0 do
      begin
        Entry := P;
        if StartsText('PATH=', Entry) then
        begin
          Lines.Add('PATH=' + NewPath);
          FoundPath := True;
        end
        else if Entry <> '' then
          Lines.Add(Entry);
        Inc(P, Length(Entry) + 1);
      end;
    end;
    if not FoundPath then
      Lines.Add('PATH=' + NewPath);

    Lines.CustomSort(CompareEnvVarsCaseInsensitive);
    Result := '';
    for I := 0 to Lines.Count - 1 do
      Result := Result + Lines[I] + #0;
    Result := Result + #0;
  finally
    if EnvPtr <> nil then
      FreeEnvironmentStrings(EnvPtr);
    Lines.Free;
  end;
end;

class function TProcessManager.StartDetached(const ExecutablePath, Arguments,
  WorkingDirectory: string; const EnvironmentBlock: string;
  const AssignToJob: Boolean): TProcessStartResult;
var
  StartupInfo: TStartupInfo;
  ProcessInfo: TProcessInformation;
  CommandLine: string;
  PWorkingDir: PChar;
  PEnv: Pointer;
  CreationFlags: DWORD;
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

  CreationFlags := CREATE_NO_WINDOW;
  if AssignToJob then
    CreationFlags := CreationFlags or CREATE_SUSPENDED or CREATE_NEW_PROCESS_GROUP;
  if EnvironmentBlock <> '' then
  begin
    CreationFlags := CreationFlags or CREATE_UNICODE_ENVIRONMENT;
    PEnv := PChar(EnvironmentBlock);
  end
  else
    PEnv := nil;

  if CreateProcess(nil, PChar(CommandLine), nil, nil, False, CreationFlags,
    PEnv, PWorkingDir, StartupInfo, ProcessInfo) then
  begin
    if AssignToJob then
    begin
      GetSharedManagedJob.AssignProcess(ProcessInfo.hProcess);
      ResumeThread(ProcessInfo.hThread);
    end;
    Result.Success := True;
    Result.ProcessId := ProcessInfo.dwProcessId;
    CloseHandle(ProcessInfo.hThread);
    CloseHandle(ProcessInfo.hProcess);
  end
  else
    Result.ErrorMessage := SysErrorMessage(GetLastError);
end;

class function TProcessManager.StartInteractive(const ExecutablePath, Arguments,
  WorkingDirectory: string; const OnOutput: TProcessOutputEvent;
  out ErrorMessage: string): IInteractiveProcessSession;
var
  Session: TInteractiveProcessSession;
begin
  Result := nil;
  Session := TInteractiveProcessSession.Create(ExecutablePath, Arguments, WorkingDirectory,
    OnOutput, ErrorMessage);
  try
    if Session.FStartSucceeded then
      Result := Session
    else
      Session.Free;
  except
    Session.Free;
    raise;
  end;
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

    // 2. Wait for process to exit gracefully if a window received WM_CLOSE
    if EnumParams.WindowFound then
    begin
      WaitRes := WaitForSingleObject(Handle, ForceAfterMs);
      if WaitRes = WAIT_OBJECT_0 then
        Exit(True);
    end;

    // 3. Force termination if still running
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

initialization

finalization
  FreeAndNil(GManagedJob);

end.
