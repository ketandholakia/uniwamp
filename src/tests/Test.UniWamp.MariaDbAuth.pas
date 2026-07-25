unit Test.UniWamp.MariaDbAuth;

interface

uses
  DUnitX.TestFramework,
  Core.UniWamp.Paths;

type
  [TestFixture]
  TMariaDbAuthTests = class
  private
    FPaths: TAppPaths;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure TestCreateMariaDbDefaultsExtraFile_WritesPasswordAndDeletesCleanly;
    [Test]
    procedure TestPrependDefaultsExtraFileArg_PrefixesArguments;
  end;

implementation

uses
  System.SysUtils,
  System.IOUtils,
  Core.UniWamp.MariaDbAuth;

procedure TMariaDbAuthTests.Setup;
var
  TempDir: string;
begin
  TempDir := TPath.Combine(TPath.GetTempPath, 'UniWampMariaDbAuthTests');
  if TDirectory.Exists(TempDir) then
    TDirectory.Delete(TempDir, True);
  TDirectory.CreateDirectory(TempDir);
  FPaths.AppRoot := TempDir;
  FPaths.TmpDir := TPath.Combine(TempDir, 'tmp');
end;

procedure TMariaDbAuthTests.TearDown;
begin
  if (FPaths.AppRoot <> '') and TDirectory.Exists(FPaths.AppRoot) then
    TDirectory.Delete(FPaths.AppRoot, True);
end;

procedure TMariaDbAuthTests.TestCreateMariaDbDefaultsExtraFile_WritesPasswordAndDeletesCleanly;
var
  FileName: string;
  ErrorMessage: string;
  Contents: string;
begin
  Assert.IsTrue(CreateMariaDbDefaultsExtraFile(FPaths, 'p@ss"word', FileName, ErrorMessage),
    ErrorMessage);
  Assert.IsTrue(FileExists(FileName), 'Defaults file should be created.');
  Contents := TFile.ReadAllText(FileName, TEncoding.ASCII);
  Assert.Contains(Contents, '[client]', 'Defaults file should contain a client section.');
  Assert.Contains(Contents, 'password="p@ss\"word"', 'Password should be quoted and escaped.');

  DeleteMariaDbDefaultsExtraFile(FileName);
  Assert.IsFalse(FileExists(FileName), 'Defaults file should be deleted after cleanup.');
end;

procedure TMariaDbAuthTests.TestPrependDefaultsExtraFileArg_PrefixesArguments;
var
  Arguments: string;
begin
  Arguments := PrependDefaultsExtraFileArg('C:\temp\client.cnf', '--protocol=tcp -uroot');
  Assert.Contains(Arguments, '--defaults-extra-file="C:\temp\client.cnf"',
    'Defaults file argument should be inserted.');
  Assert.Contains(Arguments, '--protocol=tcp -uroot',
    'Original arguments should be preserved.');
end;

initialization
  TDUnitX.RegisterTestFixture(TMariaDbAuthTests);

end.
