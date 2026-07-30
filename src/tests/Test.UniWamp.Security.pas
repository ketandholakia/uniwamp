unit Test.UniWamp.Security;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TSecurityTests = class
  public
    [Test]
    procedure TestExtractZipSafelyRejectsTraversalEntry;
    [Test]
    procedure TestValidateZipArchiveStructureRejectsTraversalEntry;
  end;

implementation

uses
  System.Classes,
  System.IOUtils,
  System.SysUtils,
  System.Zip,
  Core.UniWamp.Security;

function CreateTempRoot(const Name: string): string;
var
  GuidText: string;
begin
  GuidText := StringReplace(GUIDToString(TGUID.NewGuid), '{', '', [rfReplaceAll]);
  GuidText := StringReplace(GuidText, '}', '', [rfReplaceAll]);
  Result := TPath.Combine(TPath.GetTempPath, 'UniWamp-' + Name + '-' + GuidText);
  TDirectory.CreateDirectory(Result);
end;

procedure WriteZipEntry(const ZipPath, ArchivePath, Content: string);
var
  TempFile: string;
  Zip: TZipFile;
begin
  TempFile := TPath.ChangeExtension(TPath.GetTempFileName, '.txt');
  TFile.WriteAllText(TempFile, Content, TEncoding.UTF8);
  Zip := TZipFile.Create;
  try
    Zip.Open(ZipPath, zmWrite);
    Zip.Add(TempFile, ArchivePath);
    Zip.Close;
  finally
    Zip.Free;
    if TFile.Exists(TempFile) then
      TFile.Delete(TempFile);
  end;
end;

procedure TSecurityTests.TestExtractZipSafelyRejectsTraversalEntry;
var
  RootDir: string;
  TargetDir: string;
  ZipPath: string;
  Zip: TZipFile;
  ErrorMessage: string;
  OutsideFile: string;
begin
  RootDir := CreateTempRoot('security-extract');
  try
    TargetDir := TPath.Combine(RootDir, 'target');
    ZipPath := TPath.Combine(RootDir, 'malicious.zip');
    OutsideFile := TPath.Combine(RootDir, 'escape.txt');

    WriteZipEntry(ZipPath, '..\escape.txt', 'boom');

    Zip := TZipFile.Create;
    try
      Zip.Open(ZipPath, zmRead);
      Assert.IsFalse(ExtractZipSafely(Zip, TargetDir, ErrorMessage), 'Traversal archive should be rejected.');
      Assert.IsTrue(ErrorMessage.Contains('traversal'), ErrorMessage);
    finally
      Zip.Free;
    end;

    Assert.IsFalse(TFile.Exists(OutsideFile), 'Traversal entry must not escape the extraction root.');
    Assert.IsTrue(TDirectory.Exists(TargetDir), 'The extraction target may be created before validation fails.');
    Assert.AreEqual(0, Length(TDirectory.GetFiles(TargetDir, '*', TSearchOption.soAllDirectories)),
      'Rejected archives should not write any files.');
  finally
    if TDirectory.Exists(RootDir) then
      TDirectory.Delete(RootDir, True);
  end;
end;

procedure TSecurityTests.TestValidateZipArchiveStructureRejectsTraversalEntry;
var
  RootDir: string;
  ZipPath: string;
  Zip: TZipFile;
  ErrorMessage: string;
begin
  RootDir := CreateTempRoot('security-validate');
  try
    ZipPath := TPath.Combine(RootDir, 'malicious.zip');
    WriteZipEntry(ZipPath, '..\escape.txt', 'boom');

    Zip := TZipFile.Create;
    try
      Zip.Open(ZipPath, zmRead);
      Assert.IsFalse(ValidateZipArchiveStructure(Zip, ErrorMessage), 'Traversal archive should be rejected.');
      Assert.IsTrue(ErrorMessage.Contains('traversal'), ErrorMessage);
    finally
      Zip.Free;
    end;
  finally
    if TDirectory.Exists(RootDir) then
      TDirectory.Delete(RootDir, True);
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TSecurityTests);

end.
