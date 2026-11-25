unit Test.UniWamp.FreeFileSyncBatchWriter;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TFreeFileSyncBatchWriterTests = class
  private
    FOutputDir: string;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure TestGuiFileDryRunNeverEmitsPermanentDeletionPolicy;
    [Test]
    procedure TestBatchFileKeepsPermanentDeletionPolicyForRealRuns;
    [Test]
    procedure TestRemotePathIsXmlEscaped;
    [Test]
    procedure TestBuildCommandPreviewForVHostExcludesPass64;
  end;

implementation

uses
  System.IOUtils,
  System.StrUtils,
  System.SysUtils,
  Core.UniWamp.FreeFileSyncBatchWriter,
  Core.UniWamp.FreeFileSyncService,
  Core.UniWamp.Config,
  Core.UniWamp.Paths,
  Core.UniWamp.Secrets,
  Core.UniWamp.Types,
  Core.UniWamp.SyncTypes;

function CountOccurrences(const Needle, Haystack: string): Integer;
var
  P: Integer;
begin
  Result := 0;
  P := Pos(Needle, Haystack);
  while P > 0 do
  begin
    Inc(Result);
    P := PosEx(Needle, Haystack, P + Length(Needle));
  end;
end;

function BuildTestSpec: TFreeFileSyncJobSpec;
begin
  Result := Default(TFreeFileSyncJobSpec);
  Result.LocalPath := 'C:\projects\site';
  Result.RemotePath := '/home/user/site';
  Result.Credentials.Protocol := 'sftp';
  Result.Credentials.Host := 'example.com';
  Result.Credentials.Port := 22;
  Result.Credentials.Username := 'user';
  Result.Direction := 'upload';
  Result.SyncVariant := 'update';
  Result.DeleteEnabled := True;
end;

procedure TFreeFileSyncBatchWriterTests.Setup;
var
  GuidText: string;
begin
  GuidText := StringReplace(GUIDToString(TGUID.NewGuid), '{', '', [rfReplaceAll]);
  GuidText := StringReplace(GuidText, '}', '', [rfReplaceAll]);
  FOutputDir := TPath.Combine(TPath.GetTempPath,
    'UniWampFfsWriterTests-' + GuidText);
  TDirectory.CreateDirectory(FOutputDir);
end;

procedure TFreeFileSyncBatchWriterTests.TearDown;
begin
  if (FOutputDir <> '') and TDirectory.Exists(FOutputDir) then
    TDirectory.Delete(FOutputDir, True);
end;

procedure TFreeFileSyncBatchWriterTests.TestGuiFileDryRunNeverEmitsPermanentDeletionPolicy;
var
  Spec: TFreeFileSyncJobSpec;
  TargetFile: string;
  XmlText: string;
begin
  Spec := BuildTestSpec;
  Spec.DryRun := True;
  TargetFile := TPath.Combine(FOutputDir, 'preview.ffs_gui');
  TFreeFileSyncBatchWriter.WriteGuiFile(Spec, TargetFile);

  Assert.IsTrue(FileExists(TargetFile), 'GUI file should be written.');
  XmlText := TFile.ReadAllText(TargetFile);
  Assert.Contains(XmlText, '<DeletionPolicy>MoveToRecycleBin</DeletionPolicy>',
    'Dry run jobs must not permanently delete files.');
  Assert.AreEqual(0, Pos('<DeletionPolicy>Permanent</DeletionPolicy>', XmlText),
    'Dry run jobs must never emit DeletionPolicy=Permanent.');
end;

procedure TFreeFileSyncBatchWriterTests.TestBatchFileKeepsPermanentDeletionPolicyForRealRuns;
var
  Spec: TFreeFileSyncJobSpec;
  TargetFile: string;
  XmlText: string;
begin
  Spec := BuildTestSpec;
  Spec.DryRun := False;
  TargetFile := TPath.Combine(FOutputDir, 'sync.ffs_batch');
  TFreeFileSyncBatchWriter.WriteBatchFile(Spec, TargetFile);

  Assert.IsTrue(FileExists(TargetFile), 'Batch file should be written.');
  XmlText := TFile.ReadAllText(TargetFile);
  Assert.Contains(XmlText, '<DeletionPolicy>Permanent</DeletionPolicy>',
    'Real runs keep the existing permanent deletion policy.');
end;

procedure TFreeFileSyncBatchWriterTests.TestRemotePathIsXmlEscaped;
var
  Spec: TFreeFileSyncJobSpec;
  TargetFile: string;
  XmlText: string;
begin
  Spec := BuildTestSpec;
  Spec.RemotePath := '/home/</Right><PostSyncCommand>calc.exe</PostSyncCommand>';
  TargetFile := TPath.Combine(FOutputDir, 'injection.ffs_batch');
  TFreeFileSyncBatchWriter.WriteBatchFile(Spec, TargetFile);

  XmlText := TFile.ReadAllText(TargetFile);
  Assert.AreEqual(0, Pos('</Right><PostSyncCommand>', XmlText),
    'Remote path must not inject raw XML elements.');
  Assert.Contains(XmlText, '&lt;/Right&gt;&lt;PostSyncCommand&gt;',
    'Remote path must be XML-escaped.');
  Assert.AreEqual(1, CountOccurrences('<Pair>', XmlText),
    'Injected markup must not create additional folder pairs.');
end;

procedure TFreeFileSyncBatchWriterTests.TestBuildCommandPreviewForVHostExcludesPass64;
var
  Paths: TAppPaths;
  Config: TUniWampConfig;
  Service: TFreeFileSyncService;
  Profile: TSyncProfile;
  CommandLine: string;
  Res: TRuntimeActionResult;
  SecretErr: string;
  GuiFile: string;
  XmlText: string;
begin
  Paths := TAppPaths.Detect;
  Paths.AppRoot := FOutputDir;
  Paths.TmpDir := TPath.Combine(FOutputDir, 'tmp');
  Paths.FreeFileSyncDir := TPath.Combine(FOutputDir, 'ffs');
  TDirectory.CreateDirectory(Paths.TmpDir);
  TDirectory.CreateDirectory(Paths.FreeFileSyncDir);
  TFile.WriteAllText(TPath.Combine(Paths.FreeFileSyncDir, 'FreeFileSync.exe'), '');
  TDirectory.CreateDirectory(TPath.Combine(FOutputDir, 'site'));

  Config := TUniWampConfig.Create;
  Service := TFreeFileSyncService.Create(Paths, Config);
  try
    Profile := Default(TSyncProfile);
    Profile.Name := 'preview_secret_test';
    Profile.Protocol := 'sftp';
    Profile.Direction := 'upload';
    Profile.Host := 'example.com';
    Profile.Port := 22;
    Profile.Username := 'tester';
    Profile.RemotePath := '/var/www';
    Profile.LocalPath := TPath.Combine(FOutputDir, 'site');
    Config.AddOrUpdateSyncProfile(Profile);
    SaveConnectionPassword(Paths, Profile.Name, 'SuperSecret123!', SecretErr);
    try
      Res := Service.BuildCommandPreviewForVHost(Profile.Name, '', True, CommandLine);
      Assert.IsTrue(Res.Success, Res.Message);
      GuiFile := TPath.Combine(Paths.TmpDir, 'ffs\preview_secret_test.ffs_gui');
      Assert.IsTrue(FileExists(GuiFile), 'Preview .ffs_gui should exist');
      XmlText := TFile.ReadAllText(GuiFile, TEncoding.UTF8);
      Assert.AreEqual(0, Pos('pass64=', XmlText), 'Preview .ffs_gui must never contain pass64');
    finally
      DeleteAllConnectionSecrets(Paths, Profile.Name);
    end;
  finally
    Service.Free;
    Config.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TFreeFileSyncBatchWriterTests);

end.
