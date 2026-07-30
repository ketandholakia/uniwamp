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
    [Test]
    procedure TestValidateZipArchiveStructureRejectsDuplicateEntry;
    [Test]
    procedure TestValidateZipArchiveStructureRejectsOversizedEntry;
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

procedure PatchBytesInFile(const FileName, OldText, NewText: string);
var
  Bytes: TBytes;
  OldBytes: TBytes;
  NewBytes: TBytes;
  I: Integer;
  Match: Boolean;
begin
  if Length(OldText) <> Length(NewText) then
    raise Exception.Create('Patch text must be the same length.');
  Bytes := TFile.ReadAllBytes(FileName);
  OldBytes := TEncoding.ASCII.GetBytes(OldText);
  NewBytes := TEncoding.ASCII.GetBytes(NewText);
  for I := 0 to Length(Bytes) - Length(OldBytes) do
  begin
    Match := True;
    for var J := 0 to High(OldBytes) do
      if Bytes[I + J] <> OldBytes[J] then
      begin
        Match := False;
        Break;
      end;
    if Match then
      for var J := 0 to High(NewBytes) do
        Bytes[I + J] := NewBytes[J];
  end;
  TFile.WriteAllBytes(FileName, Bytes);
end;

procedure PatchZipCentralDirectoryUncompressedSize(const FileName: string; const NewSize: Cardinal);
var
  Bytes: TBytes;
  I: Integer;
begin
  Bytes := TFile.ReadAllBytes(FileName);
  for I := 0 to Length(Bytes) - 4 do
  begin
    if (Bytes[I] = $50) and (Bytes[I + 1] = $4B) and (Bytes[I + 2] = $01) and (Bytes[I + 3] = $02) then
    begin
      PCardinal(@Bytes[I + 24])^ := NewSize;
      TFile.WriteAllBytes(FileName, Bytes);
      Exit;
    end;
  end;
  raise Exception.Create('Central directory header not found.');
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

procedure TSecurityTests.TestValidateZipArchiveStructureRejectsDuplicateEntry;
var
  RootDir: string;
  ZipPath: string;
  Zip: TZipFile;
  ErrorMessage: string;
  FileA: string;
  FileB: string;
begin
  RootDir := CreateTempRoot('security-duplicate');
  try
    ZipPath := TPath.Combine(RootDir, 'duplicate.zip');
    FileA := TPath.Combine(RootDir, 'payload-a.txt');
    FileB := TPath.Combine(RootDir, 'payload-b.txt');
    TFile.WriteAllText(FileA, 'alpha', TEncoding.UTF8);
    TFile.WriteAllText(FileB, 'beta', TEncoding.UTF8);
    Zip := TZipFile.Create;
    try
      Zip.Open(ZipPath, zmWrite);
      Zip.Add(FileA, 'payload-a.txt');
      Zip.Add(FileB, 'payload-b.txt');
      Zip.Close;
    finally
      Zip.Free;
    end;

    PatchBytesInFile(ZipPath, 'payload-b.txt', 'payload-a.txt');

    Zip := TZipFile.Create;
    try
      Zip.Open(ZipPath, zmRead);
      Assert.IsFalse(ValidateZipArchiveStructure(Zip, ErrorMessage), 'Duplicate archive entry should be rejected.');
      Assert.IsTrue(ErrorMessage.Contains('duplicate'), ErrorMessage);
    finally
      Zip.Free;
    end;
  finally
    if TDirectory.Exists(RootDir) then
      TDirectory.Delete(RootDir, True);
  end;
end;

procedure TSecurityTests.TestValidateZipArchiveStructureRejectsOversizedEntry;
var
  RootDir: string;
  ZipPath: string;
  Zip: TZipFile;
  ErrorMessage: string;
  FileA: string;
begin
  RootDir := CreateTempRoot('security-oversized');
  try
    ZipPath := TPath.Combine(RootDir, 'oversized.zip');
    FileA := TPath.Combine(RootDir, 'payload.txt');
    TFile.WriteAllText(FileA, 'alpha', TEncoding.UTF8);
    Zip := TZipFile.Create;
    try
      Zip.Open(ZipPath, zmWrite);
      Zip.Add(FileA, 'payload.txt');
      Zip.Close;
    finally
      Zip.Free;
    end;

    PatchZipCentralDirectoryUncompressedSize(ZipPath, 1024 * 1024 * 257);

    Zip := TZipFile.Create;
    try
      Zip.Open(ZipPath, zmRead);
      Assert.IsFalse(ValidateZipArchiveStructure(Zip, ErrorMessage), 'Oversized archive entry should be rejected.');
      Assert.IsTrue(ErrorMessage.Contains('too large'), ErrorMessage);
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
