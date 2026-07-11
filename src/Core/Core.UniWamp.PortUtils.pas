unit Core.UniWamp.PortUtils;

interface

function IsTcpPortAvailable(const Port: Integer): Boolean;

implementation

uses
  Winapi.Winsock2,
  Winapi.Windows,
  System.SysUtils;

function IsTcpPortAvailable(const Port: Integer): Boolean;
var
  WsaData: TWSAData;
  Sock: TSocket;
  Addr: sockaddr_in;
begin
  Result := False;
  if WSAStartup($0202, WsaData) <> 0 then
    Exit;
  try
    Sock := socket(AF_INET, SOCK_STREAM, IPPROTO_TCP);
    if Sock = INVALID_SOCKET then
      Exit;
    try
      ZeroMemory(@Addr, SizeOf(Addr));
      Addr.sin_family := AF_INET;
      Addr.sin_addr.S_addr := INADDR_ANY;
      Addr.sin_port := htons(Port);
      Result := bind(Sock, PSockAddr(@Addr)^, SizeOf(Addr)) = 0;
    finally
      closesocket(Sock);
    end;
  finally
    WSACleanup;
  end;
end;

end.
