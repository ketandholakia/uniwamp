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
  System.Classes,
  System.SysUtils,
  System.StrUtils,
  Core.UniWamp.ProcessManager;

function TPortInspection.OwnerDescription: string;
begin
  if OwnerPid = 0 then
    Exit('');
  if OwnerImageName <> '' then
    Exit(Format('%s (PID %d)', [OwnerImageName, OwnerPid]));
  Result := Format('PID %d', [OwnerPid]);
end;

function System32Directory: string;
begin
  Result := GetEnvironmentVariable('SystemRoot');
  if Result = '' then
    Result := 'C:\Windows';
  Result := IncludeTrailingPathDelimiter(Result) + 'System32';
end;

function QueryProcessImageName(const ProcessId: Cardinal): string;
var
  TasklistOutput: string;
  CsvLines: TStringList;
  CsvFields: TStringList;
begin
  Result := '';
  if ProcessId = 0 then
    Exit;

  if not TProcessManager.RunAndCaptureOutput(
    IncludeTrailingPathDelimiter(System32Directory) + 'tasklist.exe',
    Format('/FI "PID eq %d" /FO CSV /NH', [ProcessId]),
    System32Directory,
    TasklistOutput) then
    Exit;

  CsvLines := TStringList.Create;
  CsvFields := TStringList.Create;
  try
    CsvLines.Text := Trim(TasklistOutput);
    if CsvLines.Count = 0 then
      Exit;
    CsvFields.StrictDelimiter := True;
    CsvFields.Delimiter := ',';
    CsvFields.QuoteChar := '"';
    CsvFields.DelimitedText := CsvLines[0];
    if CsvFields.Count > 0 then
      Result := CsvFields[0];
  finally
    CsvFields.Free;
    CsvLines.Free;
  end;
end;

function InspectTcpPort(const Port: Integer): TPortInspection;
var
  WsaData: TWSAData;
  Sock: TSocket;
  Addr: sockaddr_in;
  NetstatOutput: string;
  Lines: TStringList;
  Tokens: TStringList;
  Line: string;
  LocalBinding: string;
  ParsedPid: Cardinal;
begin
  Result.Available := False;
  Result.OwnerPid := 0;
  Result.OwnerImageName := '';
  Result.Binding := '';
  Result.State := '';

  if not TProcessManager.RunAndCaptureOutput(
    IncludeTrailingPathDelimiter(System32Directory) + 'netstat.exe',
    '-ano -p tcp',
    System32Directory,
    NetstatOutput) then
    Exit;

  Lines := TStringList.Create;
  Tokens := TStringList.Create;
  try
    Lines.Text := NetstatOutput;
    for Line in Lines do
    begin
      Tokens.Clear;
      ExtractStrings([' ', #9], [], PChar(Trim(Line)), Tokens);
      if Tokens.Count < 5 then
        Continue;

      LocalBinding := Tokens[1];
      if not EndsText(':' + Port.ToString, LocalBinding) then
        Continue;

      if not SameText(Tokens[3], 'LISTENING') then
        Continue;

      if not TryStrToUInt(Tokens[4], ParsedPid) then
        Continue;

      Result.Available := False;
      Result.OwnerPid := ParsedPid;
      Result.Binding := LocalBinding;
      Result.State := Tokens[3];
      Result.OwnerImageName := QueryProcessImageName(ParsedPid);
      Exit;
    end;
  finally
    Tokens.Free;
    Lines.Free;
  end;

  if WSAStartup($0202, WsaData) <> 0 then
    Exit;
  try
    Sock := socket(AF_INET, SOCK_STREAM, IPPROTO_TCP);
    if Sock <> INVALID_SOCKET then
    try
      ZeroMemory(@Addr, SizeOf(Addr));
      Addr.sin_family := AF_INET;
      Addr.sin_addr.S_addr := inet_addr(PAnsiChar(AnsiString('127.0.0.1')));
      Addr.sin_port := htons(Port);
      if bind(Sock, PSockAddr(@Addr)^, SizeOf(Addr)) = 0 then
      begin
        Result.Available := True;
        Exit;
      end;
    finally
      closesocket(Sock);
    end;
  finally
    WSACleanup;
  end;
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
