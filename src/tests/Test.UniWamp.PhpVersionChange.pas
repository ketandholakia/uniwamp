unit Test.UniWamp.PhpVersionChange;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TPhpVersionChangeTests = class
  public
    [Test]
    procedure TestCommitPhpVersionChangeKeepsNewVersionWhenRestartSucceeds;
    [Test]
    procedure TestCommitPhpVersionChangeRollsBackWhenRestartFails;
  end;

implementation

uses
  System.SysUtils,
  Core.UniWamp.Config,
  Core.UniWamp.Paths,
  Core.UniWamp.PhpVersionChange,
  Core.UniWamp.Types;

procedure TPhpVersionChangeTests.TestCommitPhpVersionChangeKeepsNewVersionWhenRestartSucceeds;
var
  Config: TUniWampConfig;
  Paths: TAppPaths;
  SaveCount: Integer;
  GenerateCount: Integer;
  RestartCount: Integer;
  ErrorMessage: string;
  ResultValue: Boolean;
begin
  Config := TUniWampConfig.Create;
  try
    Paths := Default(TAppPaths);
    Config.SelectedPhpVersion := 'php83';
    SaveCount := 0;
    GenerateCount := 0;
    RestartCount := 0;

    ResultValue := CommitPhpVersionChange(Config, Paths, 'php83', 'php84',
      procedure
      begin
        Inc(SaveCount);
      end,
      procedure
      begin
        Inc(GenerateCount);
      end,
      function: TRuntimeActionResult
      begin
        Inc(RestartCount);
        Result.Success := True;
        Result.Message := 'Apache restarted.';
      end,
      function: Boolean
      begin
        Result := True;
      end,
      ErrorMessage);

    Assert.IsTrue(ResultValue, ErrorMessage);
    Assert.AreEqual('', ErrorMessage);
    Assert.AreEqual('php84', Config.SelectedPhpVersion);
    Assert.AreEqual(1, SaveCount);
    Assert.AreEqual(1, GenerateCount);
    Assert.AreEqual(1, RestartCount);
  finally
    Config.Free;
  end;
end;

procedure TPhpVersionChangeTests.TestCommitPhpVersionChangeRollsBackWhenRestartFails;
var
  Config: TUniWampConfig;
  Paths: TAppPaths;
  SaveCount: Integer;
  GenerateCount: Integer;
  RestartCount: Integer;
  ErrorMessage: string;
  ResultValue: Boolean;
begin
  Config := TUniWampConfig.Create;
  try
    Paths := Default(TAppPaths);
    Config.SelectedPhpVersion := 'php83';
    SaveCount := 0;
    GenerateCount := 0;
    RestartCount := 0;

    ResultValue := CommitPhpVersionChange(Config, Paths, 'php83', 'php84',
      procedure
      begin
        Inc(SaveCount);
      end,
      procedure
      begin
        Inc(GenerateCount);
      end,
      function: TRuntimeActionResult
      begin
        Inc(RestartCount);
        Result.Success := False;
        Result.Message := 'Apache restart failed during start: invalid module';
      end,
      function: Boolean
      begin
        Result := True;
      end,
      ErrorMessage);

    Assert.IsFalse(ResultValue, 'The helper should fail when Apache restart fails.');
    Assert.IsTrue(ErrorMessage.Contains('Apache restart failed'), ErrorMessage);
    Assert.AreEqual('php83', Config.SelectedPhpVersion, 'The old PHP version should be restored.');
    Assert.AreEqual(2, SaveCount, 'The helper should save once for the change and once for the rollback.');
    Assert.AreEqual(2, GenerateCount, 'Configs should be regenerated for both the attempted change and rollback.');
    Assert.AreEqual(1, RestartCount);
  finally
    Config.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TPhpVersionChangeTests);

end.
