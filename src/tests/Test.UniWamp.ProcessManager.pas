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
  end;

implementation

uses
  System.SysUtils;

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

initialization
  TDUnitX.RegisterTestFixture(TProcessManagerTests);

end.
