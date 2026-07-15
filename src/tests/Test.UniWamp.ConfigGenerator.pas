unit Test.UniWamp.ConfigGenerator;

interface

uses
  System.SysUtils,
  System.IOUtils,
  DUnitX.TestFramework,
  Core.UniWamp.Paths,
  Core.UniWamp.Config,
  Core.UniWamp.ConfigGenerator;

type
  [TestFixture]
  TConfigGeneratorTests = class
  private
    FPaths: TAppPaths;
    FConfig: TUniWampConfig;
    FConfigGenerator: TConfigurationGenerator;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure TestGeneratePhpConfig;
  end;

implementation

procedure TConfigGeneratorTests.Setup;
var
  TempDir: string;
begin
  TempDir := TPath.Combine(TPath.GetTempPath, 'UniWampTest');
  if not TDirectory.Exists(TempDir) then
    TDirectory.CreateDirectory(TempDir);

  FPaths.AppRoot := TempDir;
  FPaths.GeneratedConfigDir := TPath.Combine(TempDir, 'generated');
  FPaths.TemplatesDir := TPath.Combine(TempDir, 'templates');
  FPaths.TmpDir := TPath.Combine(TempDir, 'tmp');
  FPaths.LogsDir := TPath.Combine(TempDir, 'logs');
  FPaths.PhpTemplateFile := TPath.Combine(FPaths.TemplatesDir, 'php.ini.tpl');
  FPaths.ActivePhpIniFile := TPath.Combine(FPaths.GeneratedConfigDir, 'php.ini');

  if not TDirectory.Exists(FPaths.TemplatesDir) then
    TDirectory.CreateDirectory(FPaths.TemplatesDir);
  if not TDirectory.Exists(FPaths.GeneratedConfigDir) then
    TDirectory.CreateDirectory(FPaths.GeneratedConfigDir);

  // Write a basic template
  TFile.WriteAllText(FPaths.PhpTemplateFile, 'display_errors={{DISPLAY_ERRORS}}' + sLineBreak + 'extension_dir="{{PHP_EXT_DIR}}"');

  FConfig := TUniWampConfig.Create;
  FConfig.PhpProfile := 'development';

  FConfigGenerator := TConfigurationGenerator.Create(FPaths, FConfig);
end;

procedure TConfigGeneratorTests.TearDown;
begin
  FConfigGenerator.Free;
  FConfig.Free;
  if TDirectory.Exists(FPaths.AppRoot) then
    TDirectory.Delete(FPaths.AppRoot, True);
end;

procedure TConfigGeneratorTests.TestGeneratePhpConfig;
var
  ResultText: string;
begin
  FConfigGenerator.GeneratePhpConfig('C:\php');

  Assert.IsTrue(FileExists(FPaths.ActivePhpIniFile), 'php.ini should be generated');

  ResultText := TFile.ReadAllText(FPaths.ActivePhpIniFile);
  Assert.Contains(ResultText, 'display_errors=On', 'development profile should display errors');
  Assert.Contains(ResultText, 'extension_dir="C:\php\ext"', 'extension dir should be set correctly');
end;

initialization
  TDUnitX.RegisterTestFixture(TConfigGeneratorTests);

end.
