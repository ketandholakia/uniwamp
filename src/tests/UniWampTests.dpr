program UniWampTests;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  DUnitX.Loggers.Console,
  DUnitX.TestFramework,
  Test.UniWamp.ProcessManager in 'Test.UniWamp.ProcessManager.pas',
  Test.UniWamp.ConfigGenerator in 'Test.UniWamp.ConfigGenerator.pas',
  Test.UniWamp.FtpTransport in 'Test.UniWamp.FtpTransport.pas',
  Test.UniWamp.SyncEngine in 'Test.UniWamp.SyncEngine.pas',
  Test.UniWamp.Secrets in 'Test.UniWamp.Secrets.pas',
  Test.UniWamp.MariaDbAuth in 'Test.UniWamp.MariaDbAuth.pas';

var
  runner : ITestRunner;
  results : IRunResults;
  logger : ITestLogger;
begin
  try
    // Create the test runner
    runner := TDUnitX.CreateRunner;
    
    // Add the console logger
    logger := TDUnitXConsoleLogger.Create(True);
    runner.AddLogger(logger);
    
    // Run tests
    results := runner.Execute;
    if not results.AllPassed then
      System.ExitCode := EXIT_ERRORS;

  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
end.
