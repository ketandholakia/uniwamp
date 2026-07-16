unit Core.UniWamp.ServiceSupervisor;

interface

uses
  System.SysUtils;

type
  TServiceProcessState = record
    Running: Boolean;
    ProcessId: Cardinal;
    Source: string;
  end;

  TServiceProcessSupervisor = class
  public
    class function ResolveOwnedProcess(const StoredProcessId: Cardinal; const ExpectedExePath,
      PidFileName: string): TServiceProcessState; static;
    class function StopOwnedProcess(const State: TServiceProcessState;
      const ForceAfterMs: Cardinal = 4000): Boolean; static;
  end;

implementation

uses
  System.Classes,
  System.IOUtils,
  Core.UniWamp.ProcessManager;

class function TServiceProcessSupervisor.ResolveOwnedProcess(
  const StoredProcessId: Cardinal; const ExpectedExePath, PidFileName: string): TServiceProcessState;
var
  PidText: string;
  ParsedPid: UInt64;
  FilePid: Cardinal;
begin
  Result.Running := False;
  Result.ProcessId := 0;
  Result.Source := '';

  if (StoredProcessId <> 0) and
     TProcessManager.IsRunning(StoredProcessId) and
     TProcessManager.IsProcessExecutable(StoredProcessId, ExpectedExePath) then
  begin
    Result.Running := True;
    Result.ProcessId := StoredProcessId;
    Result.Source := 'stored';
    Exit;
  end;

  if (PidFileName = '') or not FileExists(PidFileName) then
    Exit;

  try
    PidText := Trim(TFile.ReadAllText(PidFileName, TEncoding.UTF8));
  except
    Exit;
  end;

  if not TryStrToUInt64(PidText, ParsedPid) then
    Exit;
  if ParsedPid > High(Cardinal) then
    Exit;

  FilePid := Cardinal(ParsedPid);
  if TProcessManager.IsRunning(FilePid) and
     TProcessManager.IsProcessExecutable(FilePid, ExpectedExePath) then
  begin
    Result.Running := True;
    Result.ProcessId := FilePid;
    Result.Source := 'pid-file';
  end;
end;

class function TServiceProcessSupervisor.StopOwnedProcess(
  const State: TServiceProcessState; const ForceAfterMs: Cardinal): Boolean;
begin
  if not State.Running or (State.ProcessId = 0) then
    Exit(True);
  Result := TProcessManager.StopProcess(State.ProcessId, ForceAfterMs);
end;

end.
