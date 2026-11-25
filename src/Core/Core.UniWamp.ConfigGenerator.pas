unit Core.UniWamp.ConfigGenerator;

interface

uses
  System.SysUtils,
  System.Classes,
  System.Generics.Collections,
  System.IOUtils,
  System.StrUtils,
  Core.UniWamp.Config,
  Core.UniWamp.Paths,
  Core.UniWamp.Interfaces,
  Core.UniWamp.TemplateRenderer,
  Core.UniWamp.Security,
  Core.UniWamp.AtomicFile;

type
  TConfigurationGenerator = class(TInterfacedObject, IConfigurationGenerator)
  private
    FPaths: TAppPaths;
    FConfig: TUniWampConfig;
    function RenderApacheModuleLines(const ApacheModuleDir: string): string;
    function RenderPhpExtensionLines(const SelectedPhpDir: string): string;
    function RenderVHostBlocks: string;
  public
    constructor Create(const Paths: TAppPaths; Config: TUniWampConfig);
    procedure GenerateApacheConfig(const ApacheModuleDir, PhpModule: string);
    procedure GenerateMariaDbConfig;
    procedure GeneratePhpConfig(const SelectedPhpDir: string);
    procedure GenerateVHostConfig;
    procedure GenerateEnvBat(const WorkingDir, SelectedPhpDir, SelectedNodeDir: string);
  end;

implementation

function SanitizeConfigValue(const Value: string): string;
begin
  Result := StringReplace(Value, #13, '', [rfReplaceAll]);
  Result := StringReplace(Result, #10, '', [rfReplaceAll]);
  Result := Trim(Result);
end;

constructor TConfigurationGenerator.Create(const Paths: TAppPaths; Config: TUniWampConfig);
begin
  inherited Create;
  FPaths := Paths;
  FConfig := Config;
end;

function TConfigurationGenerator.RenderApacheModuleLines(const ApacheModuleDir: string): string;
var
  Lines: TStringList;
  ModuleFileName: string;
  ModuleSymbol: string;
  ModulePath: string;
begin
  Lines := TStringList.Create;
  try
    for ModuleFileName in FConfig.ApacheModules do
    begin
      ModulePath := TPath.Combine(ApacheModuleDir, SanitizeConfigValue(ModuleFileName));
      if not FileExists(ModulePath) then
        Continue;
      ModuleSymbol := TPath.GetFileNameWithoutExtension(ModuleFileName);
      if StartsText('mod_', ModuleSymbol) then
        Delete(ModuleSymbol, 1, 4);
      Lines.Add('LoadModule ' + SanitizeConfigValue(ModuleSymbol) + '_module "' + SanitizeConfigValue(ModulePath) + '"');
    end;
    Result := TrimRight(Lines.Text);
  finally
    Lines.Free;
  end;
end;

function TConfigurationGenerator.RenderPhpExtensionLines(const SelectedPhpDir: string): string;
var
  Block: TStringList;
  Item: string;
  ExtensionName: string;
  ExtensionPath: string;
  ExtensionDir: string;
begin
  Block := TStringList.Create;
  try
    ExtensionDir := TPath.Combine(SelectedPhpDir, 'ext');
    for Item in FConfig.PhpExtensions do
    begin
      ExtensionName := SanitizeConfigValue(Item);
      if ExtensionName = '' then
        Continue;

      ExtensionPath := TPath.Combine(ExtensionDir, ExtensionName);
      if not FileExists(ExtensionPath) then
        Continue;

      if SameText(ExtensionName, 'php_opcache.dll') or
         SameText(ExtensionName, 'php_xdebug.dll') or
         SameText(ExtensionName, 'xdebug.dll') then
        Block.Add('zend_extension=' + ExtensionName)
      else
        Block.Add('extension=' + ExtensionName);
    end;
    Result := Block.Text;
  finally
    Block.Free;
  end;
end;

function TConfigurationGenerator.RenderVHostBlocks: string;
var
  Entry: TVHostEntry;
  Block: TStringList;
  NormalizedHostName: string;
  NormalizedDocumentRoot: string;
  NormalizedAliases: string;
  ErrorMessage: string;
begin
  Block := TStringList.Create;
  try
    if not ValidateServerName(FConfig.HostName, NormalizedHostName, ErrorMessage) then
      NormalizedHostName := 'localhost';
    if not ValidateDocumentRoot(FConfig.DocumentRoot, NormalizedDocumentRoot, ErrorMessage) then
      NormalizedDocumentRoot := FPaths.WwwDir;
    Block.Add('<VirtualHost *:' + FConfig.HttpPort.ToString + '>');
    Block.Add('  ServerName ' + NormalizedHostName);
    Block.Add('  ServerAlias 127.0.0.1 localhost');
    Block.Add('  DocumentRoot "' + NormalizedDocumentRoot + '"');
    Block.Add('  <Directory "' + NormalizedDocumentRoot + '">');
    Block.Add('    AllowOverride All');
    Block.Add('    DirectoryIndex index.php index.html');
    Block.Add('    Require all granted');
    Block.Add('  </Directory>');
    Block.Add('</VirtualHost>');
    Block.Add('');

    for Entry in FConfig.VHosts do
    begin
      if not ValidateServerName(Entry.ServerName, NormalizedHostName, ErrorMessage) then
        Continue;
      if not ValidateDocumentRoot(Entry.DocumentRoot, NormalizedDocumentRoot, ErrorMessage) then
        Continue;
      if not ValidateServerAliases(Entry.ServerAliases, NormalizedAliases, ErrorMessage) then
        Continue;
      Block.Add('<VirtualHost *:' + FConfig.HttpPort.ToString + '>');
      Block.Add('  ServerName ' + NormalizedHostName);
      if Trim(NormalizedAliases) <> '' then
        Block.Add('  ServerAlias ' + NormalizedAliases);
      Block.Add('  DocumentRoot "' + NormalizedDocumentRoot + '"');
      Block.Add('  <Directory "' + NormalizedDocumentRoot + '">');
      Block.Add('    AllowOverride All');
      Block.Add('    DirectoryIndex index.php index.html');
      Block.Add('    Require all granted');
      Block.Add('  </Directory>');
      Block.Add('</VirtualHost>');
      Block.Add('');

      if FConfig.EnableSsl and Entry.EnableSsl then
      begin
        Block.Add('<VirtualHost *:' + FConfig.HttpsPort.ToString + '>');
        Block.Add('  ServerName ' + NormalizedHostName);
        if Trim(NormalizedAliases) <> '' then
          Block.Add('  ServerAlias ' + NormalizedAliases);
        Block.Add('  DocumentRoot "' + NormalizedDocumentRoot + '"');
        Block.Add('  <Directory "' + NormalizedDocumentRoot + '">');
        Block.Add('    AllowOverride All');
        Block.Add('    DirectoryIndex index.php index.html');
        Block.Add('    Require all granted');
        Block.Add('  </Directory>');
        Block.Add('  SSLEngine on');
        if (Entry.SslCertFile <> '') and FileExists(Entry.SslCertFile) then
          Block.Add('  SSLCertificateFile "' + Entry.SslCertFile + '"')
        else
          Block.Add('  SSLCertificateFile "' + TPath.Combine(FPaths.SslDir, 'server.crt') + '"');
        if (Entry.SslKeyFile <> '') and FileExists(Entry.SslKeyFile) then
          Block.Add('  SSLCertificateKeyFile "' + Entry.SslKeyFile + '"')
        else
          Block.Add('  SSLCertificateKeyFile "' + TPath.Combine(FPaths.SslDir, 'server.key') + '"');
        Block.Add('</VirtualHost>');
        Block.Add('');
      end;
    end;
    Result := Block.Text;
  finally
    Block.Free;
  end;
end;

procedure TConfigurationGenerator.GenerateApacheConfig(const ApacheModuleDir, PhpModule: string);
var
  Values: TDictionary<string, string>;
  PhpModuleName: string;
begin
  // PHP 7 uses php7_module, PHP 8+ uses php_module
  if FConfig.SelectedPhpVersion.StartsWith('php7') then
    PhpModuleName := 'php7_module'
  else
    PhpModuleName := 'php_module';

  Values := TDictionary<string, string>.Create;
  try
    Values.Add('APACHE_DIR', SanitizeConfigValue(FPaths.ApacheDir));
    Values.Add('HTTP_PORT', FConfig.HttpPort.ToString);
    Values.Add('HOST_NAME', SanitizeConfigValue(FConfig.HostName));
    Values.Add('DOCUMENT_ROOT', SanitizeConfigValue(FConfig.DocumentRoot));
    Values.Add('DASHBOARD_DIR', SanitizeConfigValue(FPaths.DashboardDir));
    Values.Add('ADMINER_DIR', SanitizeConfigValue(FPaths.AdminerDir));
    Values.Add('APACHE_MODULE_LINES', RenderApacheModuleLines(ApacheModuleDir));
    Values.Add('PHP_MODULE', SanitizeConfigValue(PhpModule));
    Values.Add('PHP_MODULE_NAME', SanitizeConfigValue(PhpModuleName));
    Values.Add('GENERATED_DIR', SanitizeConfigValue(FPaths.GeneratedConfigDir));
    Values.Add('LOGS_DIR', SanitizeConfigValue(FPaths.LogsDir));
    if FConfig.EnableSsl then
      Values.Add('SSL_INCLUDE', 'IncludeOptional "' + SanitizeConfigValue(FPaths.ApacheSslConfFile) + '"')
    else
      Values.Add('SSL_INCLUDE', '');
    TTemplateRenderer.RenderToFile(FPaths.ApacheTemplateFile, FPaths.ApacheHttpdConfFile, Values);

    if FConfig.EnableSsl then
    begin
      Values.Clear;
      Values.Add('HTTPS_PORT', FConfig.HttpsPort.ToString);
      Values.Add('DOCUMENT_ROOT', SanitizeConfigValue(FConfig.DocumentRoot));
      Values.Add('HOST_NAME', SanitizeConfigValue(FConfig.HostName));
      Values.Add('SSL_CERT_FILE', SanitizeConfigValue(TPath.Combine(FPaths.SslDir, 'server.crt')));
      Values.Add('SSL_KEY_FILE', SanitizeConfigValue(TPath.Combine(FPaths.SslDir, 'server.key')));
      Values.Add('LOGS_DIR', SanitizeConfigValue(FPaths.LogsDir));
      TTemplateRenderer.RenderToFile(FPaths.ApacheSslTemplateFile, FPaths.ApacheSslConfFile, Values);
    end;
  finally
    Values.Free;
  end;
end;

procedure TConfigurationGenerator.GenerateMariaDbConfig;
var
  Values: TDictionary<string, string>;
  MariaDbDir: string;
  MariaDbDataDir: string;
  TmpDir: string;
  LogsDir: string;
  TemplateText: string;
  RenderedText: string;
begin
  EnsureDirectory(TPath.Combine(FPaths.MariaDbDir, 'data'));
  MariaDbDir := StringReplace(FPaths.MariaDbDir, '\', '/', [rfReplaceAll]);
  MariaDbDataDir := StringReplace(TPath.Combine(FPaths.MariaDbDir, 'data'), '\', '/', [rfReplaceAll]);
  TmpDir := StringReplace(FPaths.TmpDir, '\', '/', [rfReplaceAll]);
  LogsDir := StringReplace(FPaths.LogsDir, '\', '/', [rfReplaceAll]);
  Values := TDictionary<string, string>.Create;
  try
    Values.Add('DB_PORT', FConfig.DatabasePort.ToString);
    Values.Add('MARIADB_DIR', MariaDbDir);
    Values.Add('MARIADB_DATA_DIR', MariaDbDataDir);
    Values.Add('TMP_DIR', TmpDir);
    Values.Add('LOGS_DIR', LogsDir);
    TemplateText := TFile.ReadAllText(FPaths.MariaDbTemplateFile, TEncoding.UTF8);
    RenderedText := TTemplateRenderer.RenderTemplate(TemplateText, Values);
    AtomicWriteTextFile(FPaths.MariaDbIniFile, RenderedText, UTF8NoBom);
  finally
    Values.Free;
  end;
end;

procedure TConfigurationGenerator.GeneratePhpConfig(const SelectedPhpDir: string);
var
  Values: TDictionary<string, string>;
  DefaultDisplayErrors: string;
begin
  EnsureDirectory(TPath.Combine(FPaths.TmpDir, 'sessions'));
  Values := TDictionary<string, string>.Create;
  try
    if SameText(FConfig.PhpProfile, 'production') then
      DefaultDisplayErrors := 'Off'
    else
      DefaultDisplayErrors := 'On';
    Values.Add('DISPLAY_ERRORS', SanitizeConfigValue(FConfig.PhpSettingValue('display_errors', DefaultDisplayErrors)));
    Values.Add('ERROR_REPORTING', SanitizeConfigValue(FConfig.PhpSettingValue('error_reporting', 'E_ALL')));
    Values.Add('LOG_ERRORS', SanitizeConfigValue(FConfig.PhpSettingValue('log_errors', 'On')));
    Values.Add('SHORT_OPEN_TAG', SanitizeConfigValue(FConfig.PhpSettingValue('short_open_tag', 'Off')));
    Values.Add('EXPOSE_PHP', SanitizeConfigValue(FConfig.PhpSettingValue('expose_php', 'Off')));
    Values.Add('MEMORY_LIMIT', SanitizeConfigValue(FConfig.PhpSettingValue('memory_limit', '256M')));
    Values.Add('UPLOAD_MAX_FILESIZE', SanitizeConfigValue(FConfig.PhpSettingValue('upload_max_filesize', '32M')));
    Values.Add('POST_MAX_SIZE', SanitizeConfigValue(FConfig.PhpSettingValue('post_max_size', '32M')));
    Values.Add('MAX_EXECUTION_TIME', SanitizeConfigValue(FConfig.PhpSettingValue('max_execution_time', '120')));
    Values.Add('MAX_INPUT_VARS', SanitizeConfigValue(FConfig.PhpSettingValue('max_input_vars', '3000')));
    Values.Add('PHP_EXT_DIR', SanitizeConfigValue(TPath.Combine(SelectedPhpDir, 'ext')));
    Values.Add('PHP_EXTENSION_LINES', RenderPhpExtensionLines(SelectedPhpDir));
    Values.Add('TMP_DIR', SanitizeConfigValue(FPaths.TmpDir));
    Values.Add('LOGS_DIR', SanitizeConfigValue(FPaths.LogsDir));
    TTemplateRenderer.RenderToFile(FPaths.PhpTemplateFile, FPaths.ActivePhpIniFile, Values);
  finally
    Values.Free;
  end;
end;

procedure TConfigurationGenerator.GenerateVHostConfig;
var
  Values: TDictionary<string, string>;
begin
  Values := TDictionary<string, string>.Create;
  try
    Values.Add('VHOSTS', RenderVHostBlocks);
    TTemplateRenderer.RenderToFile(FPaths.ApacheVHostsTemplateFile, FPaths.ApacheVHostsConfFile, Values);
  finally
    Values.Free;
  end;
end;

procedure TConfigurationGenerator.GenerateEnvBat(const WorkingDir, SelectedPhpDir, SelectedNodeDir: string);
var
  Lines: TStringList;
  ResolvedWorkingDir: string;
begin
  EnsureDirectory(FPaths.GeneratedConfigDir);
  ResolvedWorkingDir := Trim(WorkingDir);
  if ResolvedWorkingDir = '' then
    ResolvedWorkingDir := FConfig.DocumentRoot;
  Lines := TStringList.Create;
  try
    Lines.Add('@echo off');
    Lines.Add('title UniWamp Cmder');
    Lines.Add('color 0A');
    Lines.Add('set "UNIWAMP_ROOT=' + FPaths.AppRoot + '"');
    Lines.Add('set "UNIWAMP_DOCROOT=' + ResolvedWorkingDir + '"');
    Lines.Add('set "UNIWAMP_MARIADB_BIN=' + FPaths.MariaDbBinDir + '"');
    Lines.Add('set "UNIWAMP_PHP_VERSION=' + FConfig.SelectedPhpVersion + '"');
    Lines.Add('set "PHPRC=' + FPaths.GeneratedConfigDir + '"');
    Lines.Add('set "UNIWAMP_NODE_VERSION=' + FConfig.SelectedNodeVersion + '"');
    if FConfig.SelectedPhpVersion <> '' then
    begin
      Lines.Add('set "PHP_HOME=' + SelectedPhpDir + '"');
      Lines.Add('set "PHP_BIN=' + SelectedPhpDir + '"');
      Lines.Add('set "PATH=' + SelectedPhpDir + ';%PATH%"');
    end;
    if FConfig.SelectedNodeVersion <> '' then
    begin
      Lines.Add('set "NODE_HOME=' + SelectedNodeDir + '"');
      Lines.Add('set "NODE_BIN=' + SelectedNodeDir + '"');
      Lines.Add('set "PATH=' + SelectedNodeDir + ';%PATH%"');
    end;
    Lines.Add('set "COMPOSER_HOME=' + FPaths.ComposerDir + '"');
    Lines.Add('set "PATH=' + FPaths.ComposerDir + ';%PATH%"');
    Lines.Add('set "GIT_HOME=' + FPaths.GitDir + '"');
    Lines.Add('set "PATH=' + TPath.Combine(FPaths.GitDir, 'cmd') + ';%PATH%"');
    Lines.Add('set "PATH=' + FPaths.MariaDbBinDir + ';%PATH%"');
    Lines.Add('echo  PHP: %UNIWAMP_PHP_VERSION%  -  %PHP_HOME%');
    Lines.Add('if "%UNIWAMP_NODE_VERSION%"=="" (');
      Lines.Add('  echo  Node: not selected');
    Lines.Add(') else (');
      Lines.Add('  echo  Node: %UNIWAMP_NODE_VERSION%  -  %NODE_HOME%');
    Lines.Add(')');
    Lines.Add('echo  Composer: %COMPOSER_HOME%');
    Lines.Add('echo  Git: %GIT_HOME%');
    Lines.Add('echo  Working path: %UNIWAMP_DOCROOT%');
    Lines.Add('echo  MariaDB bin: %UNIWAMP_MARIADB_BIN%');
    Lines.Add('echo.');
    Lines.Add('cd /d "' + ResolvedWorkingDir + '"');
    Lines.SaveToFile(FPaths.EnvBatFile, UTF8NoBom);
  finally
    Lines.Free;
  end;
end;

end.
