unit Core.UniWamp.VHostManager;

interface

uses
  System.SysUtils,
  System.Classes,
  System.IOUtils,
  System.Generics.Collections,
  Core.UniWamp.TemplateRenderer,
  Core.UniWamp.Types,
  Core.UniWamp.Paths,
  Core.UniWamp.Config,
  Core.UniWamp.ProcessManager,
  Core.UniWamp.ConfigGenerator,
  Core.UniWamp.HostsFileService,
  Core.UniWamp.PackageManager,
  Core.UniWamp.Interfaces,
  Core.UniWamp.Security;

type
  TVHostManager = class(TInterfacedObject, IVHostManager)
  private
    FPaths: TAppPaths;
    FConfig: TUniWampConfig;
  private
    procedure EnsureVHostStarterPage(const ServerName, DocumentRoot: string);
    function BuildManagedSslDir(const ServerName: string): string;
    function IsPathUnderRoot(const CandidatePath, RootPath: string): Boolean;
    procedure DeleteManagedSslFileIfOwned(const FileName, ManagedDir: string);
  public
    constructor Create(const Paths: TAppPaths; Config: TUniWampConfig);
    function AddVHost(const ServerName, DocumentRoot, ServerAliases: string; EnableSsl: Boolean): TRuntimeActionResult;
    function UpdateVHost(const OldServerName, NewServerName, DocumentRoot,
      ServerAliases: string; EnableSsl: Boolean): TRuntimeActionResult;
    function DeleteVHost(const ServerName: string): TRuntimeActionResult;
    function GenerateSslCertificate: TRuntimeActionResult;
    function GenerateSslCertificateFor(const CommonName, CertFile, KeyFile: string): TRuntimeActionResult;
    function RefreshVHostSslCertificate(const ServerName: string): TRuntimeActionResult;
    function EnsureDefaultSslCertificate(out ErrorMessage: string): Boolean;
  end;

implementation

function TVHostManager.BuildManagedSslDir(const ServerName: string): string;
var
  SslDirName: string;
begin
  SslDirName := ServerName;
  SslDirName := StringReplace(SslDirName, ':', '_', [rfReplaceAll]);
  SslDirName := StringReplace(SslDirName, '/', '_', [rfReplaceAll]);
  SslDirName := StringReplace(SslDirName, '\', '_', [rfReplaceAll]);
  Result := TPath.Combine(FPaths.SslDir, TPath.Combine('vhosts', SslDirName));
end;

function TVHostManager.IsPathUnderRoot(const CandidatePath, RootPath: string): Boolean;
var
  Candidate: string;
  Root: string;
begin
  Candidate := ExpandFileName(CandidatePath);
  Root := IncludeTrailingPathDelimiter(ExpandFileName(RootPath));
  Result := SameText(Candidate, ExcludeTrailingPathDelimiter(Root)) or
    (Pos(LowerCase(Root), LowerCase(IncludeTrailingPathDelimiter(Candidate))) = 1);
end;

procedure TVHostManager.DeleteManagedSslFileIfOwned(const FileName, ManagedDir: string);
var
  CanonicalFileName: string;
begin
  if Trim(FileName) = '' then
    Exit;
  CanonicalFileName := ExpandFileName(FileName);
  if not FileExists(CanonicalFileName) then
    Exit;
  if not IsPathUnderRoot(CanonicalFileName, ManagedDir) then
    Exit;
  TFile.Delete(CanonicalFileName);
end;

procedure TVHostManager.EnsureVHostStarterPage(const ServerName, DocumentRoot: string);
var
  IndexFile: string;
  Values: TDictionary<string, string>;
begin
  IndexFile := TPath.Combine(DocumentRoot, 'index.html');
  if FileExists(IndexFile) then
    Exit;

  Values := TDictionary<string, string>.Create;
  try
    Values.Add('ServerName', ServerName);
    Values.Add('SERVER_NAME', ServerName);
    Values.Add('DocumentRoot', DocumentRoot);
    Values.Add('DOCUMENT_ROOT', DocumentRoot);
    Values.Add('HTTP_PORT', FConfig.HttpPort.ToString);
    Values.Add('Timestamp', FormatDateTime('yyyy-mm-dd hh:nn:ss', Now));
    TTemplateRenderer.RenderToFile(TPath.Combine(FPaths.TemplatesDir, 'vhost-index.html.tpl'), IndexFile, Values);
  finally
    Values.Free;
  end;
end;

constructor TVHostManager.Create(const Paths: TAppPaths; Config: TUniWampConfig);
begin
  inherited Create;
  FPaths := Paths;
  FConfig := Config;
end;

function TVHostManager.AddVHost(const ServerName, DocumentRoot, ServerAliases: string;
  EnableSsl: Boolean): TRuntimeActionResult;
var
  Entry: TVHostEntry;
  HostsError: string;
  ConfigGenerator: TConfigurationGenerator;
  HostsFileService: THostsFileService;
  NormalizedServerName: string;
  NormalizedDocumentRoot: string;
  NormalizedAliases: string;
  ErrorMessage: string;
  ManagedSslDir: string;
begin
  if not ValidateServerName(ServerName, NormalizedServerName, ErrorMessage) then
  begin
    Result.Success := False;
    Result.Message := ErrorMessage;
    Exit;
  end;

  if not ValidateDocumentRoot(DocumentRoot, NormalizedDocumentRoot, ErrorMessage) then
  begin
    Result.Success := False;
    Result.Message := ErrorMessage;
    Exit;
  end;

  if not ValidateServerAliases(ServerAliases, NormalizedAliases, ErrorMessage) then
  begin
    Result.Success := False;
    Result.Message := ErrorMessage;
    Exit;
  end;

  EnsureDirectory(NormalizedDocumentRoot);
  EnsureVHostStarterPage(NormalizedServerName, NormalizedDocumentRoot);
  Entry.ServerName := NormalizedServerName;
  Entry.ServerAliases := NormalizedAliases;
  Entry.DocumentRoot := NormalizedDocumentRoot;
  Entry.EnableSsl := EnableSsl;
  Entry.SslCertFile := '';
  Entry.SslKeyFile := '';
  if EnableSsl then
  begin
    ManagedSslDir := BuildManagedSslDir(NormalizedServerName);
    Entry.SslCertFile := TPath.Combine(ManagedSslDir, 'server.crt');
    Entry.SslKeyFile := TPath.Combine(ManagedSslDir, 'server.key');
    Result := GenerateSslCertificateFor(NormalizedServerName, Entry.SslCertFile, Entry.SslKeyFile);
    if not Result.Success then
      Exit;
  end;
  FConfig.AddOrUpdateVHost(Entry);
  ConfigGenerator := TConfigurationGenerator.Create(FPaths, FConfig);
  try
    ConfigGenerator.GenerateVHostConfig;
  finally
    ConfigGenerator.Free;
  end;
  HostsFileService := THostsFileService.Create(FPaths, FConfig);
  try
    if HostsFileService.SyncHostsFile(HostsError) then
    begin
      Result.Success := True;
      Result.Message := 'VHost saved: ' + NormalizedServerName;
      Exit;
    end;
  finally
    HostsFileService.Free;
  end;

  FConfig.DeleteVHost(NormalizedServerName);
  ConfigGenerator := TConfigurationGenerator.Create(FPaths, FConfig);
  try
    ConfigGenerator.GenerateVHostConfig;
  finally
    ConfigGenerator.Free;
  end;
  if EnableSsl then
  begin
    ManagedSslDir := BuildManagedSslDir(NormalizedServerName);
    DeleteManagedSslFileIfOwned(Entry.SslCertFile, ManagedSslDir);
    DeleteManagedSslFileIfOwned(Entry.SslKeyFile, ManagedSslDir);
    if TDirectory.Exists(ManagedSslDir) and TDirectory.IsEmpty(ManagedSslDir) then
      TDirectory.Delete(ManagedSslDir);
  end;
  Result.Success := False;
  Result.Message := 'VHost save failed: ' + HostsError;
end;

function TVHostManager.UpdateVHost(const OldServerName, NewServerName, DocumentRoot,
  ServerAliases: string; EnableSsl: Boolean): TRuntimeActionResult;
var
  OldEntry: TVHostEntry;
  NewEntry: TVHostEntry;
  Found: Boolean;
  VHost: TVHostEntry;
  NormalizedNewServerName: string;
  NormalizedDocumentRoot: string;
  NormalizedAliases: string;
  ErrorMessage: string;
  OldManagedSslDir: string;
  NewManagedSslDir: string;
  HostsError: string;
  ConfigGenerator: TConfigurationGenerator;
  HostsFileService: THostsFileService;
  ServerNameChanged: Boolean;
  SslWasEnabled: Boolean;
begin
  // Validate new fields
  if not ValidateServerName(NewServerName, NormalizedNewServerName, ErrorMessage) then
  begin
    Result.Success := False;
    Result.Message := ErrorMessage;
    Exit;
  end;

  if not ValidateDocumentRoot(DocumentRoot, NormalizedDocumentRoot, ErrorMessage) then
  begin
    Result.Success := False;
    Result.Message := ErrorMessage;
    Exit;
  end;

  if not ValidateServerAliases(ServerAliases, NormalizedAliases, ErrorMessage) then
  begin
    Result.Success := False;
    Result.Message := ErrorMessage;
    Exit;
  end;

  // Find the old entry
  Found := False;
  OldEntry := Default(TVHostEntry);
  for VHost in FConfig.VHosts do
    if SameText(VHost.ServerName, OldServerName) then
    begin
      OldEntry := VHost;
      Found := True;
      Break;
    end;

  if not Found then
  begin
    Result.Success := False;
    Result.Message := 'VHost not found: ' + OldServerName;
    Exit;
  end;

  ServerNameChanged := not SameText(OldServerName, NormalizedNewServerName);
  SslWasEnabled := OldEntry.EnableSsl;

  // Guard: new name must not already exist (unless it is the same entry)
  if ServerNameChanged then
    for VHost in FConfig.VHosts do
      if SameText(VHost.ServerName, NormalizedNewServerName) then
      begin
        Result.Success := False;
        Result.Message := 'A vHost with the server name "' + NormalizedNewServerName + '" already exists.';
        Exit;
      end;

  EnsureDirectory(NormalizedDocumentRoot);

  // Build new entry - preserve pinned sync profiles from old entry
  NewEntry := Default(TVHostEntry);
  NewEntry.ServerName := NormalizedNewServerName;
  NewEntry.ServerAliases := NormalizedAliases;
  NewEntry.DocumentRoot := NormalizedDocumentRoot;
  NewEntry.EnableSsl := EnableSsl;
  NewEntry.PinnedSyncUploadProfile := OldEntry.PinnedSyncUploadProfile;
  NewEntry.PinnedSyncDownloadProfile := OldEntry.PinnedSyncDownloadProfile;

  OldManagedSslDir := BuildManagedSslDir(OldServerName);
  NewManagedSslDir := BuildManagedSslDir(NormalizedNewServerName);

  if EnableSsl then
  begin
    NewEntry.SslCertFile := TPath.Combine(NewManagedSslDir, 'server.crt');
    NewEntry.SslKeyFile := TPath.Combine(NewManagedSslDir, 'server.key');
    // Re-generate cert if SSL is being enabled, or if the server name changed
    if not SslWasEnabled or ServerNameChanged or
       not FileExists(NewEntry.SslCertFile) or not FileExists(NewEntry.SslKeyFile) then
    begin
      Result := GenerateSslCertificateFor(NormalizedNewServerName, NewEntry.SslCertFile, NewEntry.SslKeyFile);
      if not Result.Success then
        Exit;
    end
    else
    begin
      // Keep existing cert paths if SSL stays on and name did not change
      NewEntry.SslCertFile := OldEntry.SslCertFile;
      NewEntry.SslKeyFile := OldEntry.SslKeyFile;
    end;
  end;

  // Remove old entry, insert new
  FConfig.DeleteVHost(OldServerName);
  FConfig.AddOrUpdateVHost(NewEntry);

  ConfigGenerator := TConfigurationGenerator.Create(FPaths, FConfig);
  try
    ConfigGenerator.GenerateVHostConfig;
  finally
    ConfigGenerator.Free;
  end;

  HostsFileService := THostsFileService.Create(FPaths, FConfig);
  try
    if not HostsFileService.SyncHostsFile(HostsError) then
    begin
      // Roll back config change
      FConfig.DeleteVHost(NormalizedNewServerName);
      FConfig.AddOrUpdateVHost(OldEntry);
      ConfigGenerator := TConfigurationGenerator.Create(FPaths, FConfig);
      try
        ConfigGenerator.GenerateVHostConfig;
      finally
        ConfigGenerator.Free;
      end;
      Result.Success := False;
      Result.Message := 'VHost update failed (hosts file): ' + HostsError;
      Exit;
    end;
  finally
    HostsFileService.Free;
  end;

  // Clean up old SSL cert files if SSL was disabled or server name changed
  if SslWasEnabled and (not EnableSsl or ServerNameChanged) then
  begin
    DeleteManagedSslFileIfOwned(OldEntry.SslCertFile, OldManagedSslDir);
    DeleteManagedSslFileIfOwned(OldEntry.SslKeyFile, OldManagedSslDir);
    if TDirectory.Exists(OldManagedSslDir) and TDirectory.IsEmpty(OldManagedSslDir) then
      TDirectory.Delete(OldManagedSslDir);
  end;

  Result.Success := True;
  Result.Message := 'VHost updated: ' + NormalizedNewServerName;
end;
function TVHostManager.DeleteVHost(const ServerName: string): TRuntimeActionResult;
var
  Entry: TVHostEntry;
  VHost: TVHostEntry;
  HostsError: string;
  PendingConfig: TUniWampConfig;
  ConfigGenerator: TConfigurationGenerator;
  HostsFileService: THostsFileService;
  ManagedSslDir: string;
begin
  Entry.ServerName := '';
  Entry.ServerAliases := '';
  Entry.DocumentRoot := '';
  Entry.EnableSsl := False;
  Entry.SslCertFile := '';
  Entry.SslKeyFile := '';
  Entry.PinnedSyncUploadProfile := '';
  Entry.PinnedSyncDownloadProfile := '';
  for VHost in FConfig.VHosts do
    if SameText(VHost.ServerName, ServerName) then
    begin
      Entry := VHost;
      Break;
    end;

  PendingConfig := TUniWampConfig.Create;
  try
    PendingConfig.HostName := FConfig.HostName;
    PendingConfig.ReplaceVHosts(FConfig.VHosts);
    PendingConfig.DeleteVHost(ServerName);
    HostsFileService := THostsFileService.Create(FPaths, PendingConfig);
    try
      if not HostsFileService.SyncHostsFile(HostsError) then
      begin
        Result.Success := False;
        Result.Message := 'VHost remove failed: ' + HostsError;
        Exit;
      end;
    finally
      HostsFileService.Free;
    end;
  finally
    PendingConfig.Free;
  end;

  FConfig.DeleteVHost(ServerName);
  ConfigGenerator := TConfigurationGenerator.Create(FPaths, FConfig);
  try
    ConfigGenerator.GenerateVHostConfig;
  finally
    ConfigGenerator.Free;
  end;
  if Entry.EnableSsl then
  begin
    ManagedSslDir := BuildManagedSslDir(ServerName);
    DeleteManagedSslFileIfOwned(Entry.SslCertFile, ManagedSslDir);
    DeleteManagedSslFileIfOwned(Entry.SslKeyFile, ManagedSslDir);
    if TDirectory.Exists(ManagedSslDir) and not TDirectory.IsEmpty(ManagedSslDir) then
      ;
    if TDirectory.Exists(ManagedSslDir) and TDirectory.IsEmpty(ManagedSslDir) then
      TDirectory.Delete(ManagedSslDir);
  end;
  Result.Message := 'VHost removed: ' + ServerName;
  Result.Success := True;
end;

function TVHostManager.GenerateSslCertificate: TRuntimeActionResult;
begin
  Result := GenerateSslCertificateFor(FConfig.HostName,
    TPath.Combine(FPaths.SslDir, 'server.crt'),
    TPath.Combine(FPaths.SslDir, 'server.key'));
end;

function TVHostManager.GenerateSslCertificateFor(const CommonName, CertFile,
  KeyFile: string): TRuntimeActionResult;
var
  OpenSslExe: string;
  CommandOutput: string;
  OpenSslSucceeded: Boolean;
  CertDir: string;
  MkcertOutput: string;
  MkcertInstallOutput: string;
  MkcertError: string;
  OpenSslError: string;
  procedure RemovePartialFiles;
  begin
    if FileExists(CertFile) then
      TFile.Delete(CertFile);
    if FileExists(KeyFile) then
      TFile.Delete(KeyFile);
  end;
begin
  Result.Success := False;
  Result.Message := '';
  MkcertError := '';
  OpenSslError := '';
  CertDir := TPath.GetDirectoryName(CertFile);
  if CertDir <> '' then
    EnsureDirectory(CertDir);

  if FileExists(FPaths.MkcertExe) then
  begin
    // Ensure the CA is installed in the trust store (prompts UAC on first run)
    TProcessManager.RunAndCaptureOutput(FPaths.MkcertExe, '-install', FPaths.MkcertDir, MkcertInstallOutput, 60000);
    if TProcessManager.RunAndCaptureOutput(
      FPaths.MkcertExe,
      '-cert-file "' + CertFile + '" -key-file "' + KeyFile + '" "' + CommonName + '"',
      FPaths.MkcertDir,
      MkcertOutput,
      30000) and FileExists(CertFile) and FileExists(KeyFile) then
    begin
      Result.Success := True;
      Result.Message := 'SSL certificate generated successfully via mkcert (locally trusted).';
      Exit;
    end;
    MkcertError := Trim(MkcertInstallOutput);
    if Trim(MkcertOutput) <> '' then
    begin
      if MkcertError <> '' then
        MkcertError := MkcertError + sLineBreak;
      MkcertError := MkcertError + Trim(MkcertOutput);
    end;
    if MkcertError = '' then
      MkcertError := 'mkcert certificate generation failed.';
    RemovePartialFiles;
  end;

  // 2. Fallback to OpenSSL (untrusted self-signed)
  OpenSslExe := TPath.Combine(FPaths.ApacheBinDir, 'openssl.exe');
  if not FileExists(OpenSslExe) then
  begin
    if MkcertError <> '' then
      Result.Message := 'SSL certificate generation failed: ' + MkcertError + sLineBreak +
        'OpenSSL executable not found.'
    else
      Result.Message := 'OpenSSL executable not found.';
    Exit;
  end;

  OpenSslSucceeded := TProcessManager.RunAndCaptureOutput(
    OpenSslExe,
    'req -x509 -nodes -days 365 -newkey rsa:2048 ' +
    '-subj "/CN=' + CommonName + '" ' +
    '-keyout "' + KeyFile + '" ' +
    '-out "' + CertFile + '"',
    FPaths.SslDir,
    CommandOutput,
    120000);
  if OpenSslSucceeded and FileExists(CertFile) and FileExists(KeyFile) then
  begin
    Result.Success := True;
    Result.Message := 'SSL certificate generated via OpenSSL (untrusted).';
  end
  else
  begin
    OpenSslError := Trim(CommandOutput);
    if OpenSslError = '' then
      OpenSslError := 'OpenSSL certificate generation failed.';
    RemovePartialFiles;
    if MkcertError <> '' then
      Result.Message := 'SSL certificate generation failed: ' + MkcertError + sLineBreak +
        OpenSslError
    else
      Result.Message := OpenSslError;
  end;
end;

function TVHostManager.RefreshVHostSslCertificate(const ServerName: string): TRuntimeActionResult;
var
  Entry: TVHostEntry;
  Found: Boolean;
  ConfigGenerator: TConfigurationGenerator;
begin
  Result.Success := False;
  Result.Message := '';
  Found := False;
  for Entry in FConfig.VHosts do
    if SameText(Entry.ServerName, ServerName) then
    begin
      Found := True;
      Break;
    end;

  if not Found then
  begin
    Result.Message := 'VHost not found: ' + ServerName;
    Exit;
  end;

  if not Entry.EnableSsl then
  begin
    Result.Message := 'SSL is not enabled for this vHost.';
    Exit;
  end;

  if Entry.SslCertFile = '' then
    Entry.SslCertFile := TPath.Combine(BuildManagedSslDir(ServerName), 'server.crt');
  if Entry.SslKeyFile = '' then
    Entry.SslKeyFile := TPath.Combine(BuildManagedSslDir(ServerName), 'server.key');

  Result := GenerateSslCertificateFor(Entry.ServerName, Entry.SslCertFile, Entry.SslKeyFile);
  if not Result.Success then
    Exit;

  FConfig.AddOrUpdateVHost(Entry);
  ConfigGenerator := TConfigurationGenerator.Create(FPaths, FConfig);
  try
    ConfigGenerator.GenerateVHostConfig;
  finally
    ConfigGenerator.Free;
  end;
  Result.Message := 'SSL certificate refreshed for ' + ServerName;
end;

function TVHostManager.EnsureDefaultSslCertificate(out ErrorMessage: string): Boolean;
var
  CertFile: string;
  KeyFile: string;
  ResultInfo: TRuntimeActionResult;
begin
  Result := True;
  ErrorMessage := '';

  CertFile := TPath.Combine(FPaths.SslDir, 'server.crt');
  KeyFile := TPath.Combine(FPaths.SslDir, 'server.key');
  if FileExists(CertFile) and FileExists(KeyFile) then
    Exit;

  ResultInfo := GenerateSslCertificateFor(FConfig.HostName, CertFile, KeyFile);
  Result := ResultInfo.Success;
  if not Result then
    ErrorMessage := ResultInfo.Message;
end;

end.
