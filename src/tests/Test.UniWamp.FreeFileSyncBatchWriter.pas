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
  end;

implementation

uses
  System.IOUtils,
  System.StrUtils,
  System.SysUtils,
  Core.UniWamp.FreeFileSyncBatchWriter,
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

initialization
  TDUnitX.RegisterTestFixture(TFreeFileSyncBatchWriterTests);

end.
