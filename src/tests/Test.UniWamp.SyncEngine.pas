unit Test.UniWamp.SyncEngine;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TSyncEngineTests = class
  public
    [Test]
    procedure TestDownloadReplacesExistingFileAtomically;
    [Test]
    procedure TestFailedDownloadLeavesExistingFileUntouched;
  end;

implementation

uses
  System.SysUtils,
  System.Classes,
  System.IOUtils,
  Core.UniWamp.SyncEngine,
  Core.UniWamp.SyncTransport;

type
  TDownloadBehavior = (dbSuccess, dbFailAfterWrite);

  TSyncTransportStub = class(TInterfacedObject, ISyncTransport)
  public
    Behavior: TDownloadBehavior;
    DownloadRemotePath: string;
    DownloadLocalPath: string;
    procedure Connect;
    procedure Disconnect;
    function IsConnected: Boolean;
    function ListDirectory(const RemotePath: string): TRemoteEntries;
    function RemoteDirectoryExists(const RemotePath: string): Boolean;
    procedure EnsureRemoteDirectory(const RemotePath: string);
    procedure DeleteRemoteFile(const RemotePath: string);
    procedure DeleteRemoteDirectory(const RemotePath: string; const Recursive: Boolean);
    procedure DownloadFile(const RemotePath, LocalPath: string;
      const OnProgress: TSyncTransferProgressEvent);
    procedure UploadFile(const LocalPath, RemotePath: string;
      const OnProgress: TSyncTransferProgressEvent);
    procedure SetLogHandler(const Handler: TSyncLogEvent);
  end;

procedure TSyncTransportStub.Connect;
begin
end;

procedure TSyncTransportStub.DeleteRemoteDirectory(const RemotePath: string;
  const Recursive: Boolean);
begin
  raise ESyncTransportError.Create('Unexpected call');
end;

procedure TSyncTransportStub.DeleteRemoteFile(const RemotePath: string);
begin
  raise ESyncTransportError.Create('Unexpected call');
end;

procedure TSyncTransportStub.Disconnect;
begin
end;

procedure TSyncTransportStub.DownloadFile(const RemotePath, LocalPath: string;
  const OnProgress: TSyncTransferProgressEvent);
begin
  DownloadRemotePath := RemotePath;
  DownloadLocalPath := LocalPath;
  TFile.WriteAllText(LocalPath, 'downloaded', TEncoding.UTF8);
  if Behavior = dbFailAfterWrite then
    raise ESyncTransportError.Create('Simulated transfer failure');
end;

procedure TSyncTransportStub.EnsureRemoteDirectory(const RemotePath: string);
begin
  raise ESyncTransportError.Create('Unexpected call');
end;

function TSyncTransportStub.IsConnected: Boolean;
begin
  Result := True;
end;

function TSyncTransportStub.ListDirectory(const RemotePath: string): TRemoteEntries;
begin
  SetLength(Result, 0);
end;

function TSyncTransportStub.RemoteDirectoryExists(const RemotePath: string): Boolean;
begin
  Result := False;
end;

procedure TSyncTransportStub.SetLogHandler(const Handler: TSyncLogEvent);
begin
end;

procedure TSyncTransportStub.UploadFile(const LocalPath, RemotePath: string;
  const OnProgress: TSyncTransferProgressEvent);
begin
  raise ESyncTransportError.Create('Unexpected call');
end;

procedure TSyncEngineTests.TestDownloadReplacesExistingFileAtomically;
var
  TempDir: string;
  TargetFile: string;
  Plan: TSyncPlan;
  Stub: TSyncTransportStub;
  Transport: ISyncTransport;
  Result: TSyncExecutionResult;
  Files: TArray<string>;
  DownloadRemotePath: string;
  DownloadLocalPath: string;
begin
  TempDir := TPath.Combine(TPath.GetTempPath, 'UniWampSyncEngineTest');
  if TDirectory.Exists(TempDir) then
    TDirectory.Delete(TempDir, True);
  TDirectory.CreateDirectory(TempDir);

  try
    TargetFile := TPath.Combine(TempDir, 'nested\download.txt');
    TDirectory.CreateDirectory(ExtractFilePath(TargetFile));
    TFile.WriteAllText(TargetFile, 'original', TEncoding.UTF8);

    SetLength(Plan, 1);
    Plan[0].Kind := spiDownload;
    Plan[0].RelativePath := 'nested/download.txt';
    Plan[0].LocalPath := TargetFile;
    Plan[0].RemotePath := '/remote/nested/download.txt';
    Plan[0].Size := 10;

    Stub := TSyncTransportStub.Create;
    try
      Stub.Behavior := dbSuccess;
      Transport := Stub;
      Result := TSyncEngine.ExecutePlan(Transport, Plan, False, nil, nil);
      DownloadRemotePath := Stub.DownloadRemotePath;
      DownloadLocalPath := Stub.DownloadLocalPath;
    finally
      Transport := nil;
    end;

    Assert.IsTrue(Result.Success, Result.Message);
    Assert.AreEqual('downloaded', TFile.ReadAllText(TargetFile, TEncoding.UTF8));
    Assert.AreEqual('/remote/nested/download.txt', DownloadRemotePath);
    Assert.AreNotEqual(TargetFile, DownloadLocalPath);
    Assert.IsTrue(DownloadLocalPath.EndsWith('.part', True),
      'Downloads should stage to a temporary sibling file.');

    Files := TDirectory.GetFiles(TempDir, '*', TSearchOption.soAllDirectories);
    Assert.AreEqual(1, Length(Files), 'Only the final file should remain after a successful download.');
    Assert.AreEqual(TargetFile, Files[0]);
  finally
    if TDirectory.Exists(TempDir) then
      TDirectory.Delete(TempDir, True);
  end;
end;

procedure TSyncEngineTests.TestFailedDownloadLeavesExistingFileUntouched;
var
  TempDir: string;
  TargetFile: string;
  Plan: TSyncPlan;
  Stub: TSyncTransportStub;
  Transport: ISyncTransport;
  Result: TSyncExecutionResult;
  Files: TArray<string>;
begin
  TempDir := TPath.Combine(TPath.GetTempPath, 'UniWampSyncEngineTest');
  if TDirectory.Exists(TempDir) then
    TDirectory.Delete(TempDir, True);
  TDirectory.CreateDirectory(TempDir);

  try
    TargetFile := TPath.Combine(TempDir, 'nested\download.txt');
    TDirectory.CreateDirectory(ExtractFilePath(TargetFile));
    TFile.WriteAllText(TargetFile, 'original', TEncoding.UTF8);

    SetLength(Plan, 1);
    Plan[0].Kind := spiDownload;
    Plan[0].RelativePath := 'nested/download.txt';
    Plan[0].LocalPath := TargetFile;
    Plan[0].RemotePath := '/remote/nested/download.txt';
    Plan[0].Size := 10;

    Stub := TSyncTransportStub.Create;
    try
      Stub.Behavior := dbFailAfterWrite;
      Transport := Stub;
      Result := TSyncEngine.ExecutePlan(Transport, Plan, False, nil, nil);
    finally
      Transport := nil;
    end;

    Assert.IsFalse(Result.Success, 'The simulated failure should be reported.');
    Assert.AreEqual('original', TFile.ReadAllText(TargetFile, TEncoding.UTF8));

    Files := TDirectory.GetFiles(TempDir, '*', TSearchOption.soAllDirectories);
    Assert.AreEqual(1, Length(Files), 'A failed download should not leave temporary files behind.');
    Assert.AreEqual(TargetFile, Files[0]);
  finally
    if TDirectory.Exists(TempDir) then
      TDirectory.Delete(TempDir, True);
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TSyncEngineTests);

end.
