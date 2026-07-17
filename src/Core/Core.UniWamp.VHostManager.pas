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
  public
    constructor Create(const Paths: TAppPaths; Config: TUniWampConfig);
    function AddVHost(const ServerName, DocumentRoot, ServerAliases: string; EnableSsl: Boolean): TRuntimeActionResult;
    function DeleteVHost(const ServerName: string): TRuntimeActionResult;
    function GenerateSslCertificate: TRuntimeActionResult;
    function GenerateSslCertificateFor(const CommonName, CertFile, KeyFile: string): TRuntimeActionResult;
    function RefreshVHostSslCertificate(const ServerName: string): TRuntimeActionResult;
    function EnsureDefaultSslCertificate(out ErrorMessage: string): Boolean;
  end;

implementation

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
  SslDirName: string;
  ConfigGenerator: TConfigurationGenerator;
  HostsFileService: THostsFileService;
  NormalizedServerName: string;
  NormalizedDocumentRoot: string;
  NormalizedAliases: string;
  ErrorMessage: string;
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
    SslDirName := NormalizedServerName;
    SslDirName := StringReplace(SslDirName, ':', '_', [rfReplaceAll]);
    SslDirName := StringReplace(SslDirName, '/', '_', [rfReplaceAll]);
    SslDirName := StringReplace(SslDirName, '\', '_', [rfReplaceAll]);
    Entry.SslCertFile := TPath.Combine(FPaths.SslDir, TPath.Combine('vhosts', TPath.Combine(SslDirName, 'server.crt')));
    Entry.SslKeyFile := TPath.Combine(FPaths.SslDir, TPath.Combine('vhosts', TPath.Combine(SslDirName, 'server.key')));
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
      Result.Message := 'VHost saved: ' + NormalizedServerName
    else
      Result.Message := 'VHost saved: ' + NormalizedServerName + ' (' + HostsError + ')';
  finally
    HostsFileService.Free;
  end;
  Result.Success := True;
end;

function TVHostManager.DeleteVHost(const ServerName: string): TRuntimeActionResult;
var
  Entry: TVHostEntry;
  VHost: TVHostEntry;
  HostsError: string;
  ConfigGenerator: TConfigurationGenerator;
  HostsFileService: THostsFileService;
begin
  Entry.ServerName := '';
  Entry.ServerAliases := '';
  Entry.DocumentRoot := '';
  Entry.EnableSsl := False;
  Entry.SslCertFile := '';
  Entry.SslKeyFile := '';
  for VHost in FConfig.VHosts do
    if SameText(VHost.ServerName, ServerName) then
    begin
      Entry := VHost;
      Break;
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
    if Entry.SslCertFile <> '' then
      TFile.Delete(Entry.SslCertFile);
    if Entry.SslKeyFile <> '' then
      TFile.Delete(Entry.SslKeyFile);
  end;
  HostsFileService := THostsFileService.Create(FPaths, FConfig);
  try
    if HostsFileService.SyncHostsFile(HostsError) then
      Result.Message := 'VHost removed: ' + ServerName
    else
      Result.Message := 'VHost removed: ' + ServerName + ' (' + HostsError + ')';
  finally
    HostsFileService.Free;
  end;
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
  StartResult: TProcessStartResult;
  CertDir: string;
  MkcertOutput: string;
begin
  CertDir := TPath.GetDirectoryName(CertFile);
  if CertDir <> '' then
    EnsureDirectory(CertDir);

  if FileExists(FPaths.MkcertExe) then
  begin
    // Ensure the CA is installed in the trust store (prompts UAC on first run)
    TProcessManager.RunAndCaptureOutput(FPaths.MkcertExe, '-install', FPaths.MkcertDir, MkcertOutput, 60000);
    
    StartResult := TProcessManager.StartDetached(
      FPaths.MkcertExe,
      '-cert-file "' + CertFile + '" -key-file "' + KeyFile + '" "' + CommonName + '"',
      FPaths.MkcertDir);

    if StartResult.Success then
    begin
      TProcessManager.WaitForExit(StartResult.ProcessId, 30000);
      if FileExists(CertFile) and FileExists(KeyFile) then
      begin
        Result.Success := True;
        Result.Message := 'SSL certificate generated successfully via mkcert (locally trusted).';
        Exit;
      end;
    end;
  end;

  // 2. Fallback to OpenSSL (untrusted self-signed)
  OpenSslExe := TPath.Combine(FPaths.ApacheBinDir, 'openssl.exe');
  if not FileExists(OpenSslExe) then
  begin
    Result.Success := False;
    Result.Message := 'OpenSSL executable not found.';
    Exit;
  end;

  StartResult := TProcessManager.StartDetached(
    OpenSslExe,
    'req -x509 -nodes -days 365 -newkey rsa:2048 ' +
    '-subj "/CN=' + CommonName + '" ' +
    '-keyout "' + KeyFile + '" ' +
    '-out "' + CertFile + '"',
    FPaths.SslDir);

  Result.Success := StartResult.Success;
  if Result.Success then
  begin
    TProcessManager.WaitForExit(StartResult.ProcessId, 120000);
    if FileExists(CertFile) and FileExists(KeyFile) then
      Result.Message := 'SSL certificate generated via OpenSSL (untrusted).'
    else
    begin
      Result.Success := False;
      Result.Message := 'SSL certificate generation did not produce the expected files.';
    end;
  end
  else
    Result.Message := StartResult.ErrorMessage;
end;

function TVHostManager.RefreshVHostSslCertificate(const ServerName: string): TRuntimeActionResult;
var
  Entry: TVHostEntry;
  Found: Boolean;
  SslDirName: string;
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
  begin
    SslDirName := ServerName;
    SslDirName := StringReplace(SslDirName, ':', '_', [rfReplaceAll]);
    SslDirName := StringReplace(SslDirName, '/', '_', [rfReplaceAll]);
    SslDirName := StringReplace(SslDirName, '\', '_', [rfReplaceAll]);
    Entry.SslCertFile := TPath.Combine(FPaths.SslDir, TPath.Combine('vhosts', TPath.Combine(SslDirName, 'server.crt')));
  end;
  if Entry.SslKeyFile = '' then
  begin
    SslDirName := ServerName;
    SslDirName := StringReplace(SslDirName, ':', '_', [rfReplaceAll]);
    SslDirName := StringReplace(SslDirName, '/', '_', [rfReplaceAll]);
    SslDirName := StringReplace(SslDirName, '\', '_', [rfReplaceAll]);
    Entry.SslKeyFile := TPath.Combine(FPaths.SslDir, TPath.Combine('vhosts', TPath.Combine(SslDirName, 'server.key')));
  end;

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
