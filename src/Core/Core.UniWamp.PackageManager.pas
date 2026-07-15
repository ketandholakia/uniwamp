unit Core.UniWamp.PackageManager;

interface

uses
  System.SysUtils,
  System.Classes,
  System.IOUtils,
  System.Hash,
  System.Zip,
  System.JSON,
  System.Generics.Collections,
  System.Net.HttpClient,
  System.Net.URLClient,
  Core.UniWamp.Paths,
  Core.UniWamp.Security;

type
  TPackageManager = class
  private
    FPaths: TAppPaths;
  public
    constructor Create(const Paths: TAppPaths);
    function ComputeFileSha256Hex(const FileName: string): string;
    function ValidatePackageSha256(const PackageFileName, ExpectedSha256: string; out ErrorMessage: string): Boolean;
    function ValidateUpdateManifest(const ManifestFileName: string; out PackageFileName, ExpectedSha256, PackageVersion: string; out ErrorMessage: string): Boolean;
    function WriteUpdateStagingMetadata(const StagingDir, PackageFileName, ExpectedSha256, PackageVersion: string; out MetadataFileName, ErrorMessage: string): Boolean;
    function CleanupUpdateWorkspace(const WorkspaceDir: string; out ErrorMessage: string): Boolean;
    function StageValidatedUpdatePackage(const ManifestFileName: string; out StagingDir, MetadataFileName, ErrorMessage: string): Boolean;
    function PromoteStagedUpdate(const StagingDir, TargetDir: string; out BackupDir, ErrorMessage: string;
      ForceFailureAfterBackup: Boolean = False): Boolean;
    function StageUpdateManifest(const ManifestFileName: string; out StagingDir, MetadataFileName, ErrorMessage: string): Boolean;
    function ValidateRuntimeZipArchive(const ZipFileName: string; out ErrorMessage: string): Boolean;
    function ImportRuntimeZipArchive(const ZipFileName: string; out ErrorMessage: string): Boolean;
    function ImportRuntimeZipArchiveInto(const ZipFileName, TargetDir: string; out ErrorMessage: string): Boolean;
    function PrepareUpdateStagingArea(const PackageName: string; out StagingDir: string; out ErrorMessage: string): Boolean;
    function CreateUpdateRollbackSnapshot(const StagingDir, SnapshotName: string; out SnapshotDir: string; out ErrorMessage: string): Boolean;
    function RollbackUpdateStagingArea(const SnapshotDir, RestoreDir: string; out ErrorMessage: string): Boolean;
    function DownloadFile(const Url, TargetFile: string; out ErrorMessage: string): Boolean;
  end;

implementation

constructor TPackageManager.Create(const Paths: TAppPaths);
begin
  inherited Create;
  FPaths := Paths;
end;

function TPackageManager.ComputeFileSha256Hex(const FileName: string): string;
var
  Stream: TFileStream;
begin
  Result := '';
  if not FileExists(FileName) then
    Exit;
  Stream := TFileStream.Create(FileName, fmOpenRead or fmShareDenyWrite);
  try
    Result := THashSHA2.GetHashString(Stream);
  finally
    Stream.Free;
  end;
end;

function TPackageManager.ValidatePackageSha256(const PackageFileName, ExpectedSha256: string; out ErrorMessage: string): Boolean;
var
  ActualSha256: string;
begin
  Result := False;
  ErrorMessage := '';
  if Trim(PackageFileName) = '' then
  begin
    ErrorMessage := 'Package file name is required.';
    Exit;
  end;
  if not FileExists(PackageFileName) then
  begin
    ErrorMessage := 'Package file not found: ' + PackageFileName;
    Exit;
  end;
  ActualSha256 := ComputeFileSha256Hex(PackageFileName);
  if ActualSha256 = '' then
  begin
    ErrorMessage := 'Package hash could not be calculated.';
    Exit;
  end;
  if not SameText(ActualSha256, Trim(ExpectedSha256)) then
  begin
    ErrorMessage := 'Package hash mismatch.';
    Exit;
  end;
  Result := True;
end;

function TPackageManager.ValidateUpdateManifest(const ManifestFileName: string; out PackageFileName, ExpectedSha256, PackageVersion: string; out ErrorMessage: string): Boolean;
var
  JsonValue: TJSONValue;
  JsonObject: TJSONObject;
begin
  Result := False;
  ErrorMessage := '';
  PackageFileName := '';
  ExpectedSha256 := '';
  PackageVersion := '';
  if not FileExists(ManifestFileName) then
  begin
    ErrorMessage := 'Update manifest not found: ' + ManifestFileName;
    Exit;
  end;
  JsonValue := TJSONObject.ParseJSONValue(TFile.ReadAllText(ManifestFileName, TEncoding.UTF8));
  try
    if not (JsonValue is TJSONObject) then
    begin
      ErrorMessage := 'Update manifest must be a JSON object.';
      Exit;
    end;
    JsonObject := TJSONObject(JsonValue);
    PackageFileName := JsonObject.GetValue<string>('packageFileName', '');
    ExpectedSha256 := JsonObject.GetValue<string>('expectedSha256', '');
    PackageVersion := JsonObject.GetValue<string>('packageVersion', '');
    if Trim(PackageFileName) = '' then
    begin
      ErrorMessage := 'Update manifest is missing packageFileName.';
      Exit;
    end;
    if Trim(ExpectedSha256) = '' then
    begin
      ErrorMessage := 'Update manifest is missing expectedSha256.';
      Exit;
    end;
    if Trim(PackageVersion) = '' then
    begin
      ErrorMessage := 'Update manifest is missing packageVersion.';
      Exit;
    end;
    Result := True;
  finally
    JsonValue.Free;
  end;
end;

function TPackageManager.WriteUpdateStagingMetadata(const StagingDir, PackageFileName, ExpectedSha256, PackageVersion: string; out MetadataFileName, ErrorMessage: string): Boolean;
var
  JsonObject: TJSONObject;
begin
  Result := False;
  ErrorMessage := '';
  MetadataFileName := '';
  if not TDirectory.Exists(StagingDir) then
  begin
    ErrorMessage := 'Staging directory not found: ' + StagingDir;
    Exit;
  end;
  MetadataFileName := TPath.Combine(StagingDir, 'update-staging.json');
  JsonObject := TJSONObject.Create;
  try
    try
      JsonObject.AddPair('packageFileName', PackageFileName);
      JsonObject.AddPair('expectedSha256', ExpectedSha256);
      JsonObject.AddPair('packageVersion', PackageVersion);
      JsonObject.AddPair('stagingDir', StagingDir);
      TFile.WriteAllText(MetadataFileName, JsonObject.Format, TEncoding.UTF8);
      Result := True;
    except
      on E: Exception do
        ErrorMessage := 'Update staging metadata could not be written: ' + E.Message;
    end;
  finally
    JsonObject.Free;
  end;
end;

function TPackageManager.CleanupUpdateWorkspace(const WorkspaceDir: string; out ErrorMessage: string): Boolean;
begin
  Result := False;
  ErrorMessage := '';
  if Trim(WorkspaceDir) = '' then
  begin
    ErrorMessage := 'Workspace directory is required.';
    Exit;
  end;
  if not TDirectory.Exists(WorkspaceDir) then
  begin
    Result := True;
    Exit;
  end;
  try
    TDirectory.Delete(WorkspaceDir, True);
    Result := True;
  except
    on E: Exception do
      ErrorMessage := 'Workspace cleanup failed: ' + E.Message;
  end;
end;

function TPackageManager.StageValidatedUpdatePackage(const ManifestFileName: string; out StagingDir, MetadataFileName, ErrorMessage: string): Boolean;
var
  PackageFileName: string;
  ExpectedSha256: string;
  PackageVersion: string;
  PackagePath: string;
begin
  Result := False;
  ErrorMessage := '';
  StagingDir := '';
  MetadataFileName := '';

  if not ValidateUpdateManifest(ManifestFileName, PackageFileName, ExpectedSha256, PackageVersion, ErrorMessage) then
    Exit;

  PackagePath := TPath.Combine(ExtractFileDir(ManifestFileName), PackageFileName);
  if not ValidatePackageSha256(PackagePath, ExpectedSha256, ErrorMessage) then
    Exit;
  if not ValidateRuntimeZipArchive(PackagePath, ErrorMessage) then
    Exit;
  if not PrepareUpdateStagingArea(PackageVersion, StagingDir, ErrorMessage) then
    Exit;
  if not ImportRuntimeZipArchiveInto(PackagePath, StagingDir, ErrorMessage) then
    Exit;
  if not WriteUpdateStagingMetadata(StagingDir, PackageFileName, ExpectedSha256, PackageVersion, MetadataFileName, ErrorMessage) then
    Exit;
  Result := True;
end;

function TPackageManager.PromoteStagedUpdate(const StagingDir, TargetDir: string; out BackupDir, ErrorMessage: string;
  ForceFailureAfterBackup: Boolean): Boolean;
begin
  Result := False;
  ErrorMessage := '';
  BackupDir := '';
  if not TDirectory.Exists(StagingDir) then
  begin
    ErrorMessage := 'Staging directory not found: ' + StagingDir;
    Exit;
  end;
  if Trim(TargetDir) = '' then
  begin
    ErrorMessage := 'Target directory is required.';
    Exit;
  end;
  try
    if TDirectory.Exists(TargetDir) then
    begin
      BackupDir := TPath.Combine(FPaths.UpdatesDir, 'backup\' + FormatDateTime('yyyymmddhhnnsszzz', Now));
      TDirectory.CreateDirectory(TPath.GetDirectoryName(BackupDir));
      TDirectory.Copy(TargetDir, BackupDir);
      TDirectory.Delete(TargetDir, True);
    end;
    if ForceFailureAfterBackup then
      raise Exception.Create('Injected promotion failure for rollback testing');
    if TDirectory.Exists(TargetDir) then
      TDirectory.Delete(TargetDir, True);
    TDirectory.CreateDirectory(TPath.GetDirectoryName(TargetDir));
    TDirectory.Copy(StagingDir, TargetDir);
    Result := True;
  except
    on E: Exception do
    begin
      if (BackupDir <> '') and TDirectory.Exists(BackupDir) then
      begin
        try
          if TDirectory.Exists(TargetDir) then
            TDirectory.Delete(TargetDir, True);
          TDirectory.Copy(BackupDir, TargetDir);
        except
          // Leave the original backup in place if restore fails.
        end;
      end;
      ErrorMessage := 'Staged update promotion failed: ' + E.Message;
    end;
  end;
end;

function TPackageManager.StageUpdateManifest(const ManifestFileName: string; out StagingDir, MetadataFileName, ErrorMessage: string): Boolean;
begin
  Result := StageValidatedUpdatePackage(ManifestFileName, StagingDir, MetadataFileName, ErrorMessage);
end;

function TPackageManager.ValidateRuntimeZipArchive(const ZipFileName: string; out ErrorMessage: string): Boolean;
var
  Zip: TZipFile;
begin
  Result := False;
  ErrorMessage := '';
  if not FileExists(ZipFileName) then
  begin
    ErrorMessage := 'Runtime archive not found: ' + ZipFileName;
    Exit;
  end;
  if not SameText(TPath.GetExtension(ZipFileName), '.zip') then
  begin
    ErrorMessage := 'Runtime archive must be a ZIP file.';
    Exit;
  end;

  Zip := TZipFile.Create;
  try
    try
      Zip.Open(ZipFileName, zmRead);
      if Zip.FileCount = 0 then
      begin
        ErrorMessage := 'Runtime archive is empty.';
        Exit;
      end;
      Result := True;
    except
      on E: Exception do
        ErrorMessage := 'Runtime archive validation failed: ' + E.Message;
    end;
  finally
    Zip.Free;
  end;
end;

function TPackageManager.ImportRuntimeZipArchive(const ZipFileName: string; out ErrorMessage: string): Boolean;
begin
  Result := ImportRuntimeZipArchiveInto(ZipFileName, FPaths.AppRoot, ErrorMessage);
end;

function TPackageManager.ImportRuntimeZipArchiveInto(const ZipFileName, TargetDir: string; out ErrorMessage: string): Boolean;
var
  Zip: TZipFile;
begin
  Result := False;
  ErrorMessage := '';
  if not ValidateRuntimeZipArchive(ZipFileName, ErrorMessage) then
    Exit;

  Zip := TZipFile.Create;
  try
    try
      Zip.Open(ZipFileName, zmRead);
      Zip.ExtractAll(TargetDir);
      Result := True;
    except
      on E: Exception do
        ErrorMessage := 'Runtime archive import failed: ' + E.Message;
    end;
  finally
    Zip.Free;
  end;
end;

function TPackageManager.PrepareUpdateStagingArea(const PackageName: string; out StagingDir: string; out ErrorMessage: string): Boolean;
var
  CleanName: string;
begin
  Result := False;
  ErrorMessage := '';
  StagingDir := '';
  CleanName := Trim(PackageName);
  if CleanName = '' then
  begin
    ErrorMessage := 'Update package name is required.';
    Exit;
  end;
  CleanName := StringReplace(CleanName, '\', '_', [rfReplaceAll]);
  CleanName := StringReplace(CleanName, '/', '_', [rfReplaceAll]);
  CleanName := StringReplace(CleanName, ':', '_', [rfReplaceAll]);
  StagingDir := TPath.Combine(FPaths.UpdatesDir, CleanName);
  try
    EnsureDirectory(StagingDir);
    Result := True;
  except
    on E: Exception do
      ErrorMessage := 'Update staging area could not be prepared: ' + E.Message;
  end;
end;

function TPackageManager.CreateUpdateRollbackSnapshot(const StagingDir, SnapshotName: string; out SnapshotDir: string; out ErrorMessage: string): Boolean;
var
  CleanName: string;
begin
  Result := False;
  ErrorMessage := '';
  SnapshotDir := '';
  if not TDirectory.Exists(StagingDir) then
  begin
    ErrorMessage := 'Staging directory not found: ' + StagingDir;
    Exit;
  end;
  CleanName := Trim(SnapshotName);
  if CleanName = '' then
  begin
    ErrorMessage := 'Snapshot name is required.';
    Exit;
  end;
  CleanName := StringReplace(CleanName, '\', '_', [rfReplaceAll]);
  CleanName := StringReplace(CleanName, '/', '_', [rfReplaceAll]);
  CleanName := StringReplace(CleanName, ':', '_', [rfReplaceAll]);
  SnapshotDir := TPath.Combine(FPaths.UpdatesDir, 'rollback\' + CleanName);
  try
    if TDirectory.Exists(SnapshotDir) then
      TDirectory.Delete(SnapshotDir, True);
    TDirectory.CreateDirectory(TPath.GetDirectoryName(SnapshotDir));
    TDirectory.Copy(StagingDir, SnapshotDir);
    Result := True;
  except
    on E: Exception do
      ErrorMessage := 'Rollback snapshot could not be created: ' + E.Message;
  end;
end;

function TPackageManager.RollbackUpdateStagingArea(const SnapshotDir, RestoreDir: string; out ErrorMessage: string): Boolean;
begin
  Result := False;
  ErrorMessage := '';
  if not TDirectory.Exists(SnapshotDir) then
  begin
    ErrorMessage := 'Rollback snapshot not found: ' + SnapshotDir;
    Exit;
  end;
  try
    if TDirectory.Exists(RestoreDir) then
      TDirectory.Delete(RestoreDir, True);
    TDirectory.CreateDirectory(TPath.GetDirectoryName(RestoreDir));
    TDirectory.Copy(SnapshotDir, RestoreDir);
    Result := True;
  except
    on E: Exception do
      ErrorMessage := 'Rollback restore failed: ' + E.Message;
  end;
end;

function TPackageManager.DownloadFile(const Url, TargetFile: string; out ErrorMessage: string): Boolean;
var
  Client: THTTPClient;
  Stream: TFileStream;
  Response: IHTTPResponse;
begin
  Result := False;
  ErrorMessage := '';
  Client := THTTPClient.Create;
  try
    try
      EnsureDirectory(TPath.GetDirectoryName(TargetFile));
      Stream := TFileStream.Create(TargetFile, fmCreate or fmShareDenyWrite);
      try
        Response := Client.Get(Url, Stream);
        if Response.StatusCode = 200 then
          Result := True
        else
          ErrorMessage := Format('HTTP Error %d: %s', [Response.StatusCode, Response.StatusText]);
      finally
        Stream.Free;
      end;
      if not Result and FileExists(TargetFile) then
        TFile.Delete(TargetFile);
    except
      on E: Exception do
      begin
        ErrorMessage := 'Download failed: ' + E.Message;
        if FileExists(TargetFile) then
          TFile.Delete(TargetFile);
      end;
    end;
  finally
    Client.Free;
  end;
end;

end.
