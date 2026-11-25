unit Core.UniWamp.PortUtils;

interface

type
  TPortInspection = record
    Available: Boolean;
    OwnerPid: Cardinal;
    OwnerImageName: string;
    Binding: string;
    State: string;
    function OwnerDescription: string;
  end;

function IsTcpPortAvailable(const Port: Integer): Boolean;
function InspectTcpPort(const Port: Integer): TPortInspection;
function DescribeTcpPortOwner(const Port: Integer): string;

implementation

uses
  Winapi.Winsock2,
  Winapi.Windows,
  System.SysUtils;

const
  AF_INET6_VAL = 23;
  TCP_TABLE_OWNER_PID_LISTENER = 3;
  PROCESS_QUERY_LIMITED_INFO = $1000;

type
  TMibTcpRowOwnerPid = record
    dwState: DWORD;
    dwLocalAddr: DWORD;
    dwLocalPort: DWORD;
    dwRemoteAddr: DWORD;
    dwRemotePort: DWORD;
    dwOwningPid: DWORD;
  end;
  PMibTcpRowOwnerPid = ^TMibTcpRowOwnerPid;

  TMibTcpTableOwnerPid = record
    dwNumEntries: DWORD;
    table: array[0..0] of TMibTcpRowOwnerPid;
  end;
  PMibTcpTableOwnerPid = ^TMibTcpTableOwnerPid;

  TMibTcp6RowOwnerPid = record
    ucLocalAddr: array[0..15] of Byte;
    dwLocalScopeId: DWORD;
    dwLocalPort: DWORD;
    ucRemoteAddr: array[0..15] of Byte;
    dwRemoteScopeId: DWORD;
    dwRemotePort: DWORD;
    dwState: DWORD;
    dwOwningPid: DWORD;
  end;
  PMibTcp6RowOwnerPid = ^TMibTcp6RowOwnerPid;

  TMibTcp6TableOwnerPid = record
    dwNumEntries: DWORD;
    table: array[0..0] of TMibTcp6RowOwnerPid;
  end;
  PMibTcp6TableOwnerPid = ^TMibTcp6TableOwnerPid;

function GetExtendedTcpTable(pTcpTable: Pointer; var dwSize: DWORD; bOrder: BOOL;
  ulAf: ULONG; TableClass: Integer; Reserved: ULONG): DWORD; stdcall;
  external 'iphlpapi.dll' name 'GetExtendedTcpTable';

function QueryFullProcessImageNameW(hProcess: THandle; dwFlags: DWORD;
  lpExeName: PWideChar; var lpdwSize: DWORD): BOOL; stdcall;
  external kernel32 name 'QueryFullProcessImageNameW';

function TPortInspection.OwnerDescription: string;
begin
  if OwnerPid = 0 then
    Exit('');
  if OwnerImageName <> '' then
    Exit(Format('%s (PID %d)', [OwnerImageName, OwnerPid]));
  Result := Format('PID %d', [OwnerPid]);
end;

function QueryProcessImageName(const ProcessId: Cardinal): string;
var
  HProc: THandle;
  Buffer: array[0..1023] of WideChar;
  Size: DWORD;
begin
  Result := '';
  if ProcessId = 0 then
    Exit;

  HProc := OpenProcess(PROCESS_QUERY_LIMITED_INFO, False, ProcessId);
  if HProc = 0 then
    Exit;
  try
    Size := Length(Buffer);
    if QueryFullProcessImageNameW(HProc, 0, Buffer, Size) then
      Result := ExtractFileName(Buffer);
  finally
    CloseHandle(HProc);
  end;
end;

function FormatIPv4Addr(const Addr: DWORD): string;
begin
  Result := Format('%d.%d.%d.%d', [
    Addr and $FF,
    (Addr shr 8) and $FF,
    (Addr shr 16) and $FF,
    (Addr shr 24) and $FF
  ]);
end;

function InspectTcpTableFamily(const Family: ULONG; const Port: Integer;
  out Inspection: TPortInspection): Boolean;
var
  Size: DWORD;
  Res: DWORD;
  I: DWORD;
  Table4: PMibTcpTableOwnerPid;
  Row4: PMibTcpRowOwnerPid;
  Table6: PMibTcp6TableOwnerPid;
  Row6: PMibTcp6RowOwnerPid;
  LocalPort: Word;
begin
  Result := False;
  Inspection := Default(TPortInspection);
  Size := 0;
  Res := GetExtendedTcpTable(nil, Size, False, Family, TCP_TABLE_OWNER_PID_LISTENER, 0);
  if (Res <> ERROR_INSUFFICIENT_BUFFER) and (Res <> NO_ERROR) then
    Exit;
  if Size = 0 then
    Exit;

  if Family = AF_INET then
  begin
    GetMem(Table4, Size);
    try
      if GetExtendedTcpTable(Table4, Size, False, Family, TCP_TABLE_OWNER_PID_LISTENER, 0) = NO_ERROR then
      begin
        Row4 := @Table4^.table[0];
        for I := 0 to Table4^.dwNumEntries - 1 do
        begin
          LocalPort := ntohs(Word(Row4^.dwLocalPort));
          if LocalPort = Word(Port) then
          begin
            Inspection.Available := False;
            Inspection.OwnerPid := Row4^.dwOwningPid;
            Inspection.OwnerImageName := QueryProcessImageName(Row4^.dwOwningPid);
            Inspection.Binding := Format('%s:%d', [FormatIPv4Addr(Row4^.dwLocalAddr), Port]);
            Inspection.State := 'LISTENING';
            Exit(True);
          end;
          Inc(Row4);
        end;
      end;
    finally
      FreeMem(Table4);
    end;
  end
  else
  begin
    GetMem(Table6, Size);
    try
      if GetExtendedTcpTable(Table6, Size, False, Family, TCP_TABLE_OWNER_PID_LISTENER, 0) = NO_ERROR then
      begin
        Row6 := @Table6^.table[0];
        for I := 0 to Table6^.dwNumEntries - 1 do
        begin
          LocalPort := ntohs(Word(Row6^.dwLocalPort));
          if LocalPort = Word(Port) then
          begin
            Inspection.Available := False;
            Inspection.OwnerPid := Row6^.dwOwningPid;
            Inspection.OwnerImageName := QueryProcessImageName(Row6^.dwOwningPid);
            Inspection.Binding := Format('[::]:%d', [Port]);
            Inspection.State := 'LISTENING';
            Exit(True);
          end;
          Inc(Row6);
        end;
      end;
    finally
      FreeMem(Table6);
    end;
  end;
end;

function InspectTcpPort(const Port: Integer): TPortInspection;
begin
  Result := Default(TPortInspection);
  if (Port < 1) or (Port > 65535) then
  begin
    Result.Available := False;
    Exit;
  end;

  if InspectTcpTableFamily(AF_INET, Port, Result) then
    Exit;
  if InspectTcpTableFamily(AF_INET6_VAL, Port, Result) then
    Exit;

  Result.Available := True;
end;

function DescribeTcpPortOwner(const Port: Integer): string;
begin
  Result := InspectTcpPort(Port).OwnerDescription;
end;

function IsTcpPortAvailable(const Port: Integer): Boolean;
begin
  Result := InspectTcpPort(Port).Available;
end;

end.
