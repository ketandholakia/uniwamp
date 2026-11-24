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
  end;

implementation

uses
  System.IOUtils,
  System.SysUtils,
  Core.UniWamp.FreeFileSyncBatchWriter,
  Core.UniWamp.SyncTypes;

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

initialization
  TDUnitX.RegisterTestFixture(TFreeFileSyncBatchWriterTests);

end.
