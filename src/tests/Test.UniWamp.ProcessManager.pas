unit Test.UniWamp.ProcessManager;

interface

uses
  DUnitX.TestFramework,
  Core.UniWamp.ProcessManager;

type
  [TestFixture]
  TProcessManagerTests = class
  public
    [Test]
    procedure TestRunAndCaptureOutput_Success;
    [Test]
    procedure TestStartDetached_Success;
    [Test]
    procedure TestStartInteractive_SendLine;
    [Test]
    procedure TestInspectTcpPort_DetectsLocalSocketOwner;
  end;

implementation

uses
  Winapi.Windows,
  Winapi.Winsock2,
  System.SysUtils,
  Core.UniWamp.PortUtils;

procedure TProcessManagerTests.TestRunAndCaptureOutput_Success;
var
  OutputStr: string;
begin
  // We expect cmd.exe to exist and output "Hello World"
  TProcessManager.RunAndCaptureOutput('C:\Windows\System32\cmd.exe', '/c echo Hello World', '', OutputStr, 5000);
  Assert.Contains(OutputStr, 'Hello World');
end;

procedure TProcessManagerTests.TestStartDetached_Success;
var
  StartResult: TProcessStartResult;
begin
  StartResult := TProcessManager.StartDetached('C:\Windows\System32\cmd.exe', '/c exit 0', '');
  Assert.IsTrue(StartResult.Success, 'StartDetached should succeed with cmd.exe');
  Assert.IsTrue(StartResult.ProcessId > 0, 'ProcessId should be greater than 0');
  
  // Wait for it to close
  TProcessManager.WaitForExit(StartResult.ProcessId, 5000);
end;

procedure TProcessManagerTests.TestStartInteractive_SendLine;
var
  Session: IInteractiveProcessSession;
  OutputStr: string;
  StartError: string;
begin
  OutputStr := '';
  Session := TProcessManager.StartInteractive(
    'C:\Windows\System32\cmd.exe',
    '/v:on /c "set /p X=Prompt: & echo !X!"',
    '',
    procedure(const Text: string)
    begin
      OutputStr := OutputStr + Text;
    end,
    StartError);

  Assert.IsTrue(Assigned(Session), StartError);
  Assert.IsTrue(Session.SendLine('hello'));
  Assert.IsTrue(Session.WaitForExit(5000), 'Interactive session should exit after input is sent.');
  OutputStr := OutputStr + Session.CapturedOutput;
  Assert.Contains(OutputStr, 'hello');
end;

procedure TProcessManagerTests.TestInspectTcpPort_DetectsLocalSocketOwner;
var
  WsaData: TWSAData;
  Sock: TSocket;
  Addr: sockaddr_in;
  AddrLen: Integer;
  BoundPort: Integer;
  Info: TPortInspection;
begin
  Assert.AreEqual(0, WSAStartup($0202, WsaData), 'WSAStartup must succeed');
  try
    Sock := socket(AF_INET, SOCK_STREAM, IPPROTO_TCP);
    Assert.AreNotEqual(INVALID_SOCKET, Sock, 'socket() must succeed');
    try
      ZeroMemory(@Addr, SizeOf(Addr));
      Addr.sin_family := AF_INET;
      Addr.sin_addr.S_addr := inet_addr('127.0.0.1');
      Addr.sin_port := 0; // ephemeral port
      Assert.AreEqual(0, bind(Sock, PSockAddr(@Addr)^, SizeOf(Addr)), 'bind() must succeed');
      Assert.AreEqual(0, listen(Sock, 1), 'listen() must succeed');

      AddrLen := SizeOf(Addr);
      Assert.AreEqual(0, getsockname(Sock, PSockAddr(@Addr)^, AddrLen), 'getsockname() must succeed');
      BoundPort := ntohs(Addr.sin_port);
      Assert.IsTrue(BoundPort > 0, 'BoundPort must be > 0');

      Info := InspectTcpPort(BoundPort);
      Assert.IsFalse(Info.Available, 'Listening port must report Available = False');
      Assert.AreEqual(GetCurrentProcessId, Info.OwnerPid, 'OwnerPid must match current process');
      Assert.IsTrue(Info.OwnerImageName <> '', 'OwnerImageName must be populated');
    finally
      closesocket(Sock);
    end;

    Info := InspectTcpPort(BoundPort);
    Assert.IsTrue(Info.Available, 'Closed port must report Available = True');
  finally
    WSACleanup;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TProcessManagerTests);

end.
