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
    [Test]
    procedure TestGeneratedPhpIniHasNoUtf8Bom;
    [Test]
    procedure TestGeneratedMariaDbIniIsUtf8WithoutBom;
    [Test]
    procedure TestMakePortableRelativePath;
  end;

implementation

uses
  Core.UniWamp.AtomicFile;

function HasUtf8Bom(const Bytes: TBytes): Boolean;
begin
  Result := (Length(Bytes) >= 3) and (Bytes[0] = $EF) and (Bytes[1] = $BB) and (Bytes[2] = $BF);
end;

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

procedure TConfigGeneratorTests.TestGeneratedPhpIniHasNoUtf8Bom;
var
  Bytes: TBytes;
begin
  FConfigGenerator.GeneratePhpConfig('C:\php');

  Assert.IsTrue(FileExists(FPaths.ActivePhpIniFile), 'php.ini should be generated');
  Bytes := TFile.ReadAllBytes(FPaths.ActivePhpIniFile);
  Assert.IsFalse(HasUtf8Bom(Bytes),
    'Generated php.ini must not start with a UTF-8 BOM.');
end;

procedure TConfigGeneratorTests.TestGeneratedMariaDbIniIsUtf8WithoutBom;
var
  TemplateFile: string;
  Bytes: TBytes;
  Utf8Text: string;
  Generator: TConfigurationGenerator;
begin
  TemplateFile := TPath.Combine(FPaths.TemplatesDir, 'mariadb.ini.tpl');
  TFile.WriteAllText(TemplateFile,
    'basedir={{MARIADB_DIR}}' + sLineBreak + 'tmpdir={{TMP_DIR}}', TEncoding.UTF8);
  FPaths.MariaDbTemplateFile := TemplateFile;
  FPaths.MariaDbIniFile := TPath.Combine(FPaths.GeneratedConfigDir, 'mariadb.ini');
  FPaths.MariaDbDir := TPath.Combine(FPaths.AppRoot, 'runtime', 'mariadb');

  // TConfigurationGenerator copies TAppPaths by value, so build it after the
  // MariaDB paths above have been filled in.
  Generator := TConfigurationGenerator.Create(FPaths, FConfig);
  try
    Generator.GenerateMariaDbConfig;

    Assert.IsTrue(FileExists(FPaths.MariaDbIniFile), 'mariadb.ini should be generated');
    Bytes := TFile.ReadAllBytes(FPaths.MariaDbIniFile);
    Assert.IsFalse(HasUtf8Bom(Bytes),
      'Generated mariadb.ini must not start with a UTF-8 BOM.');
  finally
    Generator.Free;
  end;

  // Non-ASCII install path characters must be written as UTF-8 instead of
  // being destroyed by an ASCII-encoded '?'.
  FPaths.MariaDbDir := TPath.Combine(FPaths.AppRoot, 'runtim' + Chr(233));
  Generator := TConfigurationGenerator.Create(FPaths, FConfig);
  try
    Generator.GenerateMariaDbConfig;
    Utf8Text := TEncoding.UTF8.GetString(TFile.ReadAllBytes(FPaths.MariaDbIniFile));
    Assert.Contains(Utf8Text, 'runtim' + Chr(233),
      'Non-ASCII install path characters must be preserved as UTF-8.');
  finally
    Generator.Free;
  end;
end;

procedure TConfigGeneratorTests.TestMakePortableRelativePath;
begin
  Assert.AreEqual('www\site',
    MakePortableRelativePath('C:\UniWamp\www\site', 'C:\UniWamp'));
  Assert.AreEqual('.',
    MakePortableRelativePath('C:\UniWamp', 'C:\UniWamp'));
  Assert.AreEqual('D:\Projects\site',
    MakePortableRelativePath('D:\Projects\site', 'C:\UniWamp'));
end;

initialization
  TDUnitX.RegisterTestFixture(TConfigGeneratorTests);

end.
