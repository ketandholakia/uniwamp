unit Test.UniWamp.PackageManager;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TPackageManagerTests = class
  public
    [Test]
    procedure TestStageValidatedUpdatePackageRejectsHashMismatch;
    [Test]
    procedure TestStageValidatedUpdatePackageAcceptsValidPackage;
    [Test]
    procedure TestStageValidatedUpdatePackageRejectsInsecureProvenance;
    [Test]
    procedure TestPromoteStagedUpdateRestoresOriginalOnFailure;
  end;

implementation

uses
  System.Classes,
  System.IOUtils,
  System.SysUtils,
  System.JSON,
  System.Zip,
  Core.UniWamp.PackageManager,
  Core.UniWamp.Paths;

function CreateTempRoot(const Name: string): string;
var
  GuidText: string;
begin
  GuidText := StringReplace(GUIDToString(TGUID.NewGuid), '{', '', [rfReplaceAll]);
  GuidText := StringReplace(GuidText, '}', '', [rfReplaceAll]);
  Result := TPath.Combine(TPath.GetTempPath, 'UniWamp-' + Name + '-' + GuidText);
  TDirectory.CreateDirectory(Result);
end;

function BuildPaths(const Root: string): TAppPaths;
begin
  Result := Default(TAppPaths);
  Result.AppRoot := Root;
  Result.TmpDir := TPath.Combine(Root, 'tmp');
  Result.UpdatesDir := TPath.Combine(Result.TmpDir, 'updates');
  EnsureDirectory(Result.TmpDir);
  EnsureDirectory(Result.UpdatesDir);
end;

function CreateZipPackage(const ZipPath, EntryName, Content: string): string;
var
  SourceFile: string;
  Zip: TZipFile;
begin
  SourceFile := TPath.ChangeExtension(TPath.GetTempFileName, '.txt');
  TFile.WriteAllText(SourceFile, Content, TEncoding.UTF8);
  Zip := TZipFile.Create;
  try
    Zip.Open(ZipPath, zmWrite);
    Zip.Add(SourceFile, EntryName);
    Zip.Close;
  finally
    Zip.Free;
    if TFile.Exists(SourceFile) then
      TFile.Delete(SourceFile);
  end;
  Result := ZipPath;
end;

function WriteUpdateManifest(const ManifestPath, PackageFileName, ExpectedSha256, PackageVersion, SourceUrl: string): string;
var
  JsonObject: TJSONObject;
begin
  JsonObject := TJSONObject.Create;
  try
    JsonObject.AddPair('packageFileName', PackageFileName);
    JsonObject.AddPair('expectedSha256', ExpectedSha256);
    JsonObject.AddPair('packageVersion', PackageVersion);
    JsonObject.AddPair('sourceUrl', SourceUrl);
    TFile.WriteAllText(ManifestPath, JsonObject.Format, TEncoding.UTF8);
  finally
    JsonObject.Free;
  end;
  Result := ManifestPath;
end;

procedure TPackageManagerTests.TestStageValidatedUpdatePackageRejectsHashMismatch;
var
  RootDir: string;
  Paths: TAppPaths;
  Manager: TPackageManager;
  PackagePath: string;
  ManifestPath: string;
  StagingDir: string;
  MetadataFileName: string;
  ErrorMessage: string;
begin
  RootDir := CreateTempRoot('package-manager-mismatch');
  try
    Paths := BuildPaths(RootDir);
    PackagePath := TPath.Combine(RootDir, 'update.zip');
    ManifestPath := TPath.Combine(RootDir, 'update.json');
    CreateZipPackage(PackagePath, 'payload.txt', 'payload');
    WriteUpdateManifest(ManifestPath, ExtractFileName(PackagePath), StringOfChar('0', 64), '1.0.0',
      'https://example.invalid/downloads/update.zip');

    Manager := TPackageManager.Create(Paths);
    try
      Assert.IsFalse(Manager.StageValidatedUpdatePackage(ManifestPath, StagingDir, MetadataFileName, ErrorMessage),
        'A mismatched hash must block staging before extraction.');
      Assert.IsTrue(ErrorMessage.Contains('mismatch'), ErrorMessage);
      Assert.AreEqual('', StagingDir);
      Assert.AreEqual('', MetadataFileName);
      Assert.IsFalse(TDirectory.Exists(TPath.Combine(Paths.UpdatesDir, '1.0.0')),
        'No staging directory should be created on hash mismatch.');
    finally
      Manager.Free;
    end;
  finally
    if TDirectory.Exists(RootDir) then
      TDirectory.Delete(RootDir, True);
  end;
end;

procedure TPackageManagerTests.TestStageValidatedUpdatePackageAcceptsValidPackage;
var
  RootDir: string;
  Paths: TAppPaths;
  Manager: TPackageManager;
  PackagePath: string;
  ManifestPath: string;
  StagingDir: string;
  MetadataFileName: string;
  ErrorMessage: string;
  PackageSha256: string;
begin
  RootDir := CreateTempRoot('package-manager-valid');
  try
    Paths := BuildPaths(RootDir);
    PackagePath := TPath.Combine(RootDir, 'update.zip');
    ManifestPath := TPath.Combine(RootDir, 'update.json');
    CreateZipPackage(PackagePath, 'payload.txt', 'payload');

    Manager := TPackageManager.Create(Paths);
    try
      PackageSha256 := Manager.ComputeFileSha256Hex(PackagePath);
      WriteUpdateManifest(ManifestPath, ExtractFileName(PackagePath), PackageSha256, '1.0.0',
        'https://example.invalid/downloads/update.zip');

      Assert.IsTrue(Manager.StageValidatedUpdatePackage(ManifestPath, StagingDir, MetadataFileName, ErrorMessage),
        ErrorMessage);
      Assert.IsTrue(TDirectory.Exists(StagingDir), 'Validated packages should be staged.');
        Assert.IsTrue(TFile.Exists(TPath.Combine(StagingDir, 'payload.txt')),
          'Validated packages should extract payload contents.');
        Assert.IsTrue(TFile.Exists(MetadataFileName), 'Validated packages should write staging metadata.');
        Assert.Contains(TFile.ReadAllText(MetadataFileName, TEncoding.UTF8), '"sourceUrl"',
          'Validated packages should record provenance in staging metadata.');
    finally
      Manager.Free;
    end;
  finally
    if TDirectory.Exists(RootDir) then
      TDirectory.Delete(RootDir, True);
  end;
end;

procedure TPackageManagerTests.TestStageValidatedUpdatePackageRejectsInsecureProvenance;
var
  RootDir: string;
  Paths: TAppPaths;
  Manager: TPackageManager;
  PackagePath: string;
  ManifestPath: string;
  StagingDir: string;
  MetadataFileName: string;
  ErrorMessage: string;
  PackageSha256: string;
begin
  RootDir := CreateTempRoot('package-manager-provenance');
  try
    Paths := BuildPaths(RootDir);
    PackagePath := TPath.Combine(RootDir, 'update.zip');
    ManifestPath := TPath.Combine(RootDir, 'update.json');
    CreateZipPackage(PackagePath, 'payload.txt', 'payload');

    Manager := TPackageManager.Create(Paths);
    try
      PackageSha256 := Manager.ComputeFileSha256Hex(PackagePath);
      WriteUpdateManifest(ManifestPath, ExtractFileName(PackagePath), PackageSha256, '1.0.0',
        'http://example.invalid/downloads/update.zip');

      Assert.IsFalse(Manager.StageValidatedUpdatePackage(ManifestPath, StagingDir, MetadataFileName, ErrorMessage),
        'Insecure provenance must block update staging.');
      Assert.Contains(ErrorMessage, 'HTTPS', 'Provenance failures should identify the transport requirement.');
      Assert.AreEqual('', StagingDir);
      Assert.AreEqual('', MetadataFileName);
    finally
      Manager.Free;
    end;
  finally
    if TDirectory.Exists(RootDir) then
      TDirectory.Delete(RootDir, True);
  end;
end;

procedure TPackageManagerTests.TestPromoteStagedUpdateRestoresOriginalOnFailure;
var
  RootDir: string;
  Paths: TAppPaths;
  Manager: TPackageManager;
  StagingDir: string;
  TargetDir: string;
  BackupDir: string;
  ErrorMessage: string;
begin
  RootDir := CreateTempRoot('package-manager-rollback');
  try
    Paths := BuildPaths(RootDir);
    Manager := TPackageManager.Create(Paths);
    try
      StagingDir := TPath.Combine(RootDir, 'staging');
      TargetDir := TPath.Combine(RootDir, 'target');
      TDirectory.CreateDirectory(StagingDir);
      TDirectory.CreateDirectory(TargetDir);
      TFile.WriteAllText(TPath.Combine(StagingDir, 'app.txt'), 'new version', TEncoding.UTF8);
      TFile.WriteAllText(TPath.Combine(TargetDir, 'app.txt'), 'original version', TEncoding.UTF8);

      Assert.IsFalse(Manager.PromoteStagedUpdate(StagingDir, TargetDir, BackupDir, ErrorMessage, True),
        'Injected failure should force rollback.');
      Assert.IsTrue(ErrorMessage.Contains('failed'), ErrorMessage);
      Assert.AreEqual('original version', TFile.ReadAllText(TPath.Combine(TargetDir, 'app.txt'), TEncoding.UTF8),
        'Rollback should restore the original target contents.');
      Assert.IsTrue(TDirectory.Exists(BackupDir), 'A backup copy should remain available for recovery.');
      Assert.AreEqual('new version', TFile.ReadAllText(TPath.Combine(StagingDir, 'app.txt'), TEncoding.UTF8),
        'The staging area should remain intact for retry.');
    finally
      Manager.Free;
    end;
  finally
    if TDirectory.Exists(RootDir) then
      TDirectory.Delete(RootDir, True);
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TPackageManagerTests);

end.
