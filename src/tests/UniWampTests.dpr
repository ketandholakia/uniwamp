program UniWampTests;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  DUnitX.Loggers.Console,
  DUnitX.TestFramework,
  Test.UniWamp.ProcessManager in 'Test.UniWamp.ProcessManager.pas',
  Test.UniWamp.ConfigGenerator in 'Test.UniWamp.ConfigGenerator.pas';

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
