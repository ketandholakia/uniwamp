unit Core.UniWamp.ProjectBackupService;

interface

uses
  System.SysUtils,
  Core.UniWamp.Paths,
  Core.UniWamp.Config,
  Core.UniWamp.BackupTypes,
  Core.UniWamp.Types,
  Core.UniWamp.Interfaces;

type
  TProjectBackupService = class(TInterfacedObject, IProjectBackupService)
  private
    FPaths: TAppPaths;
    FConfig: TUniWampConfig;
    function TryFindVHost(const ServerName: string; out Entry: TVHostEntry): Boolean;
    function IsPathUnderRoot(const CandidatePath, RootPath: string): Boolean;
    function BuildBackupSlug(const Value: string): string;
    function ComputeFileSha256Hex(const FileName: string): string;
    procedure AddDirectoryToZip(const ZipFileName, SourceDir: string);
    function ResolveRestoreDocumentRoot(const PathValue: string; out ResolvedPath, ErrorMessage: string): Boolean;
    function ReadProjectBackupManifest(const ManifestFileName: string; out Manifest: TProjectBackupManifest;
      out ErrorMessage: string): Boolean;
    procedure RestoreSslFilesIfPresent(const BackupDir: string; const ServerName, CertFileName, KeyFileName: string);
    function WriteProjectBackupManifest(const BackupDir: string; const Entry: TVHostEntry;
      const ArchiveFileName, ArchiveSha256, MetadataFileName: string): Boolean;
  public
    constructor Create(const Paths: TAppPaths; Config: TUniWampConfig);
    function BackupProject(const ServerName: string; out BackupDirectory: string): TRuntimeActionResult;
    function RestoreProject(const ManifestFileName, TargetServerName, TargetDocumentRoot,
      TargetServerAliases: string; TargetEnableSsl: Boolean; out RestoredServerName: string): TRuntimeActionResult;
  end;

implementation

uses
  System.Classes,
  System.DateUtils,
  System.Hash,
  System.IOUtils,
  System.JSON,
  System.Zip,
  Core.UniWamp.Security,
  Core.UniWamp.VHostManager;

constructor TProjectBackupService.Create(const Paths: TAppPaths; Config: TUniWampConfig);
begin
  inherited Create;
  FPaths := Paths;
  FConfig := Config;
end;

function TProjectBackupService.TryFindVHost(const ServerName: string; out Entry: TVHostEntry): Boolean;
var
  Item: TVHostEntry;
begin
  Result := False;
  Entry.ServerName := '';
  Entry.ServerAliases := '';
  Entry.DocumentRoot := '';
  Entry.EnableSsl := False;
  Entry.SslCertFile := '';
  Entry.SslKeyFile := '';
  Entry.PinnedSyncUploadProfile := '';
  Entry.PinnedSyncDownloadProfile := '';
  for Item in FConfig.VHosts do
    if SameText(Item.ServerName, ServerName) then
    begin
      Entry := Item;
      Exit(True);
    end;
end;

function TProjectBackupService.IsPathUnderRoot(const CandidatePath, RootPath: string): Boolean;
var
  Candidate: string;
  Root: string;
begin
  Candidate := ExpandFileName(CandidatePath);
  Root := IncludeTrailingPathDelimiter(ExpandFileName(RootPath));
  Result := SameText(Candidate, ExcludeTrailingPathDelimiter(Root)) or
    (Pos(LowerCase(Root), LowerCase(IncludeTrailingPathDelimiter(Candidate))) = 1);
end;

function TProjectBackupService.BuildBackupSlug(const Value: string): string;
var
  I: Integer;
  C: Char;
  LastWasSeparator: Boolean;
begin
  Result := '';
  LastWasSeparator := False;
  for I := 1 to Length(Value) do
  begin
    C := Value[I];
    if CharInSet(C, ['A'..'Z', 'a'..'z', '0'..'9']) then
    begin
      Result := Result + LowerCase(C);
      LastWasSeparator := False;
    end
    else if not LastWasSeparator then
    begin
      Result := Result + '-';
      LastWasSeparator := True;
    end;
  end;
  Result := Trim(Result);
  while (Result <> '') and (Result[1] = '-') do
    Delete(Result, 1, 1);
  while (Result <> '') and (Result[Length(Result)] = '-') do
    Delete(Result, Length(Result), 1);
  if Result = '' then
    Result := 'project';
end;

function TProjectBackupService.ComputeFileSha256Hex(const FileName: string): string;
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

procedure TProjectBackupService.AddDirectoryToZip(const ZipFileName, SourceDir: string);
var
  Zip: TZipFile;
  Files: TArray<string>;
  FileName: string;
  RelativeName: string;
begin
  Zip := TZipFile.Create;
  try
    Zip.Open(ZipFileName, zmWrite);
    Files := TDirectory.GetFiles(SourceDir, '*', TSearchOption.soAllDirectories);
    for FileName in Files do
    begin
      RelativeName := FileName.Substring(Length(IncludeTrailingPathDelimiter(SourceDir)));
      Zip.Add(FileName, RelativeName);
    end;
  finally
    Zip.Free;
  end;
end;

function TProjectBackupService.WriteProjectBackupManifest(const BackupDir: string; const Entry: TVHostEntry;
  const ArchiveFileName, ArchiveSha256, MetadataFileName: string): Boolean;
var
  Manifest: TProjectBackupManifest;
  RootRelativeDocumentRoot: string;
  ManifestJson: TJSONObject;
  VHostJson: TJSONObject;
begin
  RootRelativeDocumentRoot := Entry.DocumentRoot;
  if IsPathUnderRoot(Entry.DocumentRoot, FPaths.AppRoot) then
    RootRelativeDocumentRoot := ExtractRelativePath(IncludeTrailingPathDelimiter(FPaths.AppRoot), Entry.DocumentRoot);

  Manifest.BackupKind := BackupKindName(bkProject);
  Manifest.CreatedAtUtc := FormatDateTime('yyyy-mm-dd"T"hh:nn:ss"Z"', TTimeZone.Local.ToUniversalTime(Now));
  Manifest.UniWampVersion := '1';
  Manifest.ServerName := Entry.ServerName;
  Manifest.ServerAliases := Entry.ServerAliases;
  Manifest.DocumentRoot := RootRelativeDocumentRoot;
  Manifest.EnableSsl := Entry.EnableSsl;
  Manifest.SslCertFile := ExtractFileName(Entry.SslCertFile);
  Manifest.SslKeyFile := ExtractFileName(Entry.SslKeyFile);
  Manifest.ProjectArchiveFile := ArchiveFileName;
  Manifest.ProjectArchiveSha256 := ArchiveSha256;
  Manifest.MetadataFileName := MetadataFileName;

  ManifestJson := ProjectBackupManifestToJson(Manifest);
  try
    VHostJson := VHostEntryToJson(Entry);
    ManifestJson.AddPair('vhost', VHostJson);
    TFile.WriteAllText(TPath.Combine(BackupDir, MetadataFileName), ManifestJson.Format, TEncoding.UTF8);
    Exit(True);
  finally
    ManifestJson.Free;
  end;
end;

function TProjectBackupService.ResolveRestoreDocumentRoot(const PathValue: string; out ResolvedPath,
  ErrorMessage: string): Boolean;
var
  NormalizedPath: string;
begin
  Result := False;
  ErrorMessage := '';
  ResolvedPath := '';
  NormalizedPath := Trim(StringReplace(PathValue, '/', '\', [rfReplaceAll]));
  if NormalizedPath = '' then
  begin
    ErrorMessage := 'Project backup is missing documentRoot.';
    Exit;
  end;
  if TPath.IsPathRooted(NormalizedPath) then
    ResolvedPath := ExpandFileName(NormalizedPath)
  else
    ResolvedPath := ExpandFileName(TPath.Combine(FPaths.AppRoot, NormalizedPath));

  if not IsPathUnderRoot(ResolvedPath, FPaths.AppRoot) then
  begin
    ErrorMessage := 'Project restore target must stay inside the UniWamp application folder.';
    Exit;
  end;
  Result := True;
end;

function TProjectBackupService.ReadProjectBackupManifest(const ManifestFileName: string;
  out Manifest: TProjectBackupManifest; out ErrorMessage: string): Boolean;
var
  JsonValue: TJSONValue;
  JsonObject: TJSONObject;
  DocumentRoot: string;
begin
  Result := False;
  ErrorMessage := '';
  Manifest.BackupKind := '';
  Manifest.CreatedAtUtc := '';
  Manifest.UniWampVersion := '';
  Manifest.ServerName := '';
  Manifest.ServerAliases := '';
  Manifest.DocumentRoot := '';
  Manifest.EnableSsl := False;
  Manifest.SslCertFile := '';
  Manifest.SslKeyFile := '';
  Manifest.ProjectArchiveFile := '';
  Manifest.ProjectArchiveSha256 := '';
  Manifest.MetadataFileName := '';

  if not FileExists(ManifestFileName) then
  begin
    ErrorMessage := 'Project backup manifest not found: ' + ManifestFileName;
    Exit;
  end;

  JsonValue := TJSONObject.ParseJSONValue(TFile.ReadAllText(ManifestFileName, TEncoding.UTF8));
  try
    if not (JsonValue is TJSONObject) then
    begin
      ErrorMessage := 'Project backup manifest must be a JSON object.';
      Exit;
    end;
    JsonObject := TJSONObject(JsonValue);
    Manifest.BackupKind := JsonObject.GetValue<string>('backupKind', '');
    Manifest.CreatedAtUtc := JsonObject.GetValue<string>('createdAtUtc', '');
    Manifest.UniWampVersion := JsonObject.GetValue<string>('uniwampVersion', '');
    Manifest.ServerName := JsonObject.GetValue<string>('serverName', '');
    Manifest.ServerAliases := JsonObject.GetValue<string>('serverAliases', '');
    Manifest.DocumentRoot := JsonObject.GetValue<string>('documentRoot', '');
    Manifest.EnableSsl := JsonObject.GetValue<Boolean>('enableSsl', False);
    Manifest.SslCertFile := JsonObject.GetValue<string>('sslCertFile', '');
    Manifest.SslKeyFile := JsonObject.GetValue<string>('sslKeyFile', '');
    Manifest.ProjectArchiveFile := JsonObject.GetValue<string>('projectArchiveFile', '');
    Manifest.ProjectArchiveSha256 := JsonObject.GetValue<string>('projectArchiveSha256', '');
    Manifest.MetadataFileName := JsonObject.GetValue<string>('metadataFileName', '');

    if not SameText(Manifest.BackupKind, BackupKindName(bkProject)) then
    begin
      ErrorMessage := 'Backup manifest is not a project backup.';
      Exit;
    end;
    if Trim(Manifest.ServerName) = '' then
    begin
      ErrorMessage := 'Project backup manifest is missing serverName.';
      Exit;
    end;
    if not ValidateServerName(Manifest.ServerName, Manifest.ServerName, ErrorMessage) then
      Exit;
    if not ValidateServerAliases(Manifest.ServerAliases, Manifest.ServerAliases, ErrorMessage) then
      Exit;
    DocumentRoot := '';
    if not ResolveRestoreDocumentRoot(Manifest.DocumentRoot, DocumentRoot, ErrorMessage) then
      Exit;
    Manifest.DocumentRoot := DocumentRoot;
    if Trim(Manifest.ProjectArchiveFile) = '' then
    begin
      ErrorMessage := 'Project backup manifest is missing projectArchiveFile.';
      Exit;
    end;
    Result := True;
  finally
    JsonValue.Free;
  end;
end;

procedure TProjectBackupService.RestoreSslFilesIfPresent(const BackupDir: string; const ServerName,
  CertFileName, KeyFileName: string);
var
  Entry: TVHostEntry;
  SourcePath: string;
begin
  if not TryFindVHost(ServerName, Entry) then
    Exit;
  if (CertFileName <> '') and (Entry.SslCertFile <> '') then
  begin
    SourcePath := TPath.Combine(BackupDir, CertFileName);
    if FileExists(SourcePath) then
      TFile.Copy(SourcePath, Entry.SslCertFile, True);
  end;
  if (KeyFileName <> '') and (Entry.SslKeyFile <> '') then
  begin
    SourcePath := TPath.Combine(BackupDir, KeyFileName);
    if FileExists(SourcePath) then
      TFile.Copy(SourcePath, Entry.SslKeyFile, True);
  end;
end;

function TProjectBackupService.BackupProject(const ServerName: string; out BackupDirectory: string): TRuntimeActionResult;
var
  Entry: TVHostEntry;
  BackupName: string;
  ArchiveFileName: string;
  ArchivePath: string;
  ArchiveSha256: string;
  MetadataFileName: string;
  SourceCertPath: string;
  SourceKeyPath: string;
begin
  Result.Success := False;
  Result.Message := '';
  BackupDirectory := '';

  if not TryFindVHost(ServerName, Entry) then
  begin
    Result.Message := 'Project not found: ' + ServerName;
    Exit;
  end;

  if not TDirectory.Exists(Entry.DocumentRoot) then
  begin
    Result.Message := 'Project folder not found: ' + Entry.DocumentRoot;
    Exit;
  end;

  if not IsPathUnderRoot(Entry.DocumentRoot, FPaths.AppRoot) then
  begin
    Result.Message := 'Project backup only supports document roots inside the UniWamp application folder.';
    Exit;
  end;

  BackupName := FormatDateTime('yyyymmdd-hhnnss', Now) + '-' + BuildBackupSlug(Entry.ServerName);
  BackupDirectory := TPath.Combine(FPaths.ProjectBackupsDir, BackupName);
  EnsureDirectory(BackupDirectory);

  ArchiveFileName := 'project-files.zip';
  ArchivePath := TPath.Combine(BackupDirectory, ArchiveFileName);
  MetadataFileName := 'backup.json';

  try
    AddDirectoryToZip(ArchivePath, Entry.DocumentRoot);
    ArchiveSha256 := ComputeFileSha256Hex(ArchivePath);

    if Entry.EnableSsl then
    begin
      SourceCertPath := Entry.SslCertFile;
      SourceKeyPath := Entry.SslKeyFile;
      if FileExists(SourceCertPath) then
        TFile.Copy(SourceCertPath, TPath.Combine(BackupDirectory, ExtractFileName(SourceCertPath)), True);
      if FileExists(SourceKeyPath) then
        TFile.Copy(SourceKeyPath, TPath.Combine(BackupDirectory, ExtractFileName(SourceKeyPath)), True);
    end;

    if not WriteProjectBackupManifest(BackupDirectory, Entry, ArchiveFileName, ArchiveSha256, MetadataFileName) then
    begin
      Result.Message := 'Project backup manifest could not be written.';
      Exit;
    end;
  except
    on E: Exception do
    begin
      Result.Message := 'Project backup failed: ' + E.Message;
      Exit;
    end;
  end;

  Result.Success := True;
  Result.Message := 'Project backup created: ' + BackupDirectory;
end;

function TProjectBackupService.RestoreProject(const ManifestFileName, TargetServerName,
  TargetDocumentRoot, TargetServerAliases: string; TargetEnableSsl: Boolean;
  out RestoredServerName: string): TRuntimeActionResult;
var
  Manifest: TProjectBackupManifest;
  ErrorMessage: string;
  BackupDir: string;
  ArchivePath: string;
  ArchiveSha256: string;
  Zip: TZipFile;
  VHostManager: IVHostManager;
  ExistingEntry: TVHostEntry;
  NormalizedServerName: string;
  NormalizedDocumentRoot: string;
  NormalizedServerAliases: string;
begin
  Result.Success := False;
  Result.Message := '';
  RestoredServerName := '';

  if not ReadProjectBackupManifest(ManifestFileName, Manifest, ErrorMessage) then
  begin
    Result.Message := ErrorMessage;
    Exit;
  end;

  BackupDir := ExtractFileDir(ManifestFileName);
  ArchivePath := TPath.Combine(BackupDir, Manifest.ProjectArchiveFile);
  if not FileExists(ArchivePath) then
  begin
    Result.Message := 'Project archive not found: ' + ArchivePath;
    Exit;
  end;

  ArchiveSha256 := ComputeFileSha256Hex(ArchivePath);
  if (Trim(Manifest.ProjectArchiveSha256) <> '') and not SameText(ArchiveSha256, Manifest.ProjectArchiveSha256) then
  begin
    Result.Message := 'Project archive checksum mismatch.';
    Exit;
  end;

  if not ValidateServerName(TargetServerName, NormalizedServerName, ErrorMessage) then
  begin
    Result.Message := ErrorMessage;
    Exit;
  end;
  if not ValidateDocumentRoot(TargetDocumentRoot, NormalizedDocumentRoot, ErrorMessage) then
  begin
    Result.Message := ErrorMessage;
    Exit;
  end;
  if not ValidateServerAliases(TargetServerAliases, NormalizedServerAliases, ErrorMessage) then
  begin
    Result.Message := ErrorMessage;
    Exit;
  end;

  if TryFindVHost(NormalizedServerName, ExistingEntry) then
  begin
    Result.Message := 'A project with this server name already exists: ' + NormalizedServerName;
    Exit;
  end;

  if not IsPathUnderRoot(NormalizedDocumentRoot, FPaths.AppRoot) then
  begin
    Result.Message := 'Project restore target must stay inside the UniWamp application folder.';
    Exit;
  end;

  if TDirectory.Exists(NormalizedDocumentRoot) then
  begin
    Result.Message := 'Restore target already exists: ' + NormalizedDocumentRoot;
    Exit;
  end;

  EnsureDirectory(NormalizedDocumentRoot);
  Zip := TZipFile.Create;
  try
    Zip.Open(ArchivePath, zmRead);
    if not ValidateZipArchiveStructure(Zip, ErrorMessage) then
    begin
      Result.Message := ErrorMessage;
      Exit;
    end;
    if not ExtractZipSafely(Zip, NormalizedDocumentRoot, ErrorMessage) then
    begin
      Result.Message := ErrorMessage;
      Exit;
    end;
  finally
    Zip.Free;
  end;

  VHostManager := TVHostManager.Create(FPaths, FConfig);
  Result := VHostManager.AddVHost(NormalizedServerName, NormalizedDocumentRoot, NormalizedServerAliases, TargetEnableSsl);
  if not Result.Success then
    Exit;

  if TargetEnableSsl then
    RestoreSslFilesIfPresent(BackupDir, NormalizedServerName, Manifest.SslCertFile, Manifest.SslKeyFile);

  RestoredServerName := NormalizedServerName;
  Result.Message := 'Project restored: ' + NormalizedServerName;
end;

end.
