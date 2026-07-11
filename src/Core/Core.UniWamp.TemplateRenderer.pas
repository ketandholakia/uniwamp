unit Core.UniWamp.TemplateRenderer;

interface

uses
  System.Generics.Collections,
  System.SysUtils,
  Core.UniWamp.Paths;

type
  TTemplateRenderer = class
  public
    class function RenderTemplate(const TemplateText: string;
      const Values: TDictionary<string, string>): string; static;
    class procedure RenderToFile(const TemplateFile, OutputFile: string;
      const Values: TDictionary<string, string>); static;
    class procedure EnsureDefaultTemplates(const Paths: TAppPaths); static;
  end;

implementation

uses
  System.Classes,
  System.IOUtils;

class function TTemplateRenderer.RenderTemplate(const TemplateText: string;
  const Values: TDictionary<string, string>): string;
var
  Pair: TPair<string, string>;
begin
  Result := TemplateText;
  for Pair in Values do
    Result := Result.Replace('{{' + Pair.Key + '}}', Pair.Value, [rfReplaceAll, rfIgnoreCase]);
end;

class procedure TTemplateRenderer.RenderToFile(const TemplateFile, OutputFile: string;
  const Values: TDictionary<string, string>);
var
  TemplateText: string;
  OutputBytes: TBytes;
begin
  TemplateText := TFile.ReadAllText(TemplateFile, TEncoding.UTF8);
  OutputBytes := TEncoding.UTF8.GetBytes(RenderTemplate(TemplateText, Values));
  TFile.WriteAllBytes(OutputFile, OutputBytes);
end;

class procedure TTemplateRenderer.EnsureDefaultTemplates(const Paths: TAppPaths);
var
  PhpTemplateText: string;
begin
  if not FileExists(Paths.ApacheTemplateFile) then
    TFile.WriteAllText(Paths.ApacheTemplateFile,
      'ServerRoot "{{APACHE_DIR}}"' + sLineBreak +
      'PidFile "{{LOGS_DIR}}\httpd.pid"' + sLineBreak +
      'Listen {{HTTP_PORT}}' + sLineBreak +
      'ServerName {{HOST_NAME}}:{{HTTP_PORT}}' + sLineBreak +
      'DocumentRoot "{{DOCUMENT_ROOT}}"' + sLineBreak +
      '<Directory "{{DOCUMENT_ROOT}}">' + sLineBreak +
      '  AllowOverride All' + sLineBreak +
      '  Require all granted' + sLineBreak +
      '</Directory>' + sLineBreak +
      'Alias /dashboard "{{DASHBOARD_DIR}}"' + sLineBreak +
      '<Directory "{{DASHBOARD_DIR}}">' + sLineBreak +
      '  AllowOverride All' + sLineBreak +
      '  Require all granted' + sLineBreak +
      '</Directory>' + sLineBreak +
      'Alias /adminer "{{ADMINER_DIR}}"' + sLineBreak +
      '<Directory "{{ADMINER_DIR}}">' + sLineBreak +
      '  AllowOverride All' + sLineBreak +
      '  Require all granted' + sLineBreak +
      '</Directory>' + sLineBreak +
      '{{APACHE_MODULE_LINES}}' + sLineBreak +
      'LoadModule php_module "{{PHP_MODULE}}"' + sLineBreak +
      'PHPIniDir "{{GENERATED_DIR}}"' + sLineBreak +
      'ErrorLog "{{LOGS_DIR}}\apache-error.log"' + sLineBreak +
      'CustomLog "{{LOGS_DIR}}\apache-access.log" common' + sLineBreak +
      'IncludeOptional "{{GENERATED_DIR}}\httpd-vhosts.conf"' + sLineBreak +
      '{{SSL_INCLUDE}}', TEncoding.UTF8);

  if FileExists(Paths.ApacheTemplateFile) and
     (Pos('{{APACHE_MODULE_LINES}}', TFile.ReadAllText(Paths.ApacheTemplateFile, TEncoding.UTF8)) = 0) then
    TFile.WriteAllText(Paths.ApacheTemplateFile,
      'ServerRoot "{{APACHE_DIR}}"' + sLineBreak +
      'PidFile "{{LOGS_DIR}}\httpd.pid"' + sLineBreak +
      'Listen {{HTTP_PORT}}' + sLineBreak +
      'ServerName {{HOST_NAME}}:{{HTTP_PORT}}' + sLineBreak +
      'DocumentRoot "{{DOCUMENT_ROOT}}"' + sLineBreak +
      '<Directory "{{DOCUMENT_ROOT}}">' + sLineBreak +
      '  AllowOverride All' + sLineBreak +
      '  Require all granted' + sLineBreak +
      '</Directory>' + sLineBreak +
      'Alias /dashboard "{{DASHBOARD_DIR}}"' + sLineBreak +
      '<Directory "{{DASHBOARD_DIR}}">' + sLineBreak +
      '  AllowOverride All' + sLineBreak +
      '  Require all granted' + sLineBreak +
      '</Directory>' + sLineBreak +
      'Alias /adminer "{{ADMINER_DIR}}"' + sLineBreak +
      '<Directory "{{ADMINER_DIR}}">' + sLineBreak +
      '  AllowOverride All' + sLineBreak +
      '  Require all granted' + sLineBreak +
      '</Directory>' + sLineBreak +
      '{{APACHE_MODULE_LINES}}' + sLineBreak +
      'LoadModule php_module "{{PHP_MODULE}}"' + sLineBreak +
      'PHPIniDir "{{GENERATED_DIR}}"' + sLineBreak +
      'ErrorLog "{{LOGS_DIR}}\apache-error.log"' + sLineBreak +
      'CustomLog "{{LOGS_DIR}}\apache-access.log" common' + sLineBreak +
      'IncludeOptional "{{GENERATED_DIR}}\httpd-vhosts.conf"' + sLineBreak +
      '{{SSL_INCLUDE}}', TEncoding.UTF8);

  if not FileExists(Paths.ApacheSslTemplateFile) then
    TFile.WriteAllText(Paths.ApacheSslTemplateFile,
      'Listen {{HTTPS_PORT}}' + sLineBreak +
      '<VirtualHost _default_:{{HTTPS_PORT}}>' + sLineBreak +
      '  DocumentRoot "{{DOCUMENT_ROOT}}"' + sLineBreak +
      '  ServerName {{HOST_NAME}}:{{HTTPS_PORT}}' + sLineBreak +
      '  SSLEngine on' + sLineBreak +
      '  SSLCertificateFile "{{SSL_CERT_FILE}}"' + sLineBreak +
      '  SSLCertificateKeyFile "{{SSL_KEY_FILE}}"' + sLineBreak +
      '  ErrorLog "{{LOGS_DIR}}\apache-ssl-error.log"' + sLineBreak +
      '  CustomLog "{{LOGS_DIR}}\apache-ssl-access.log" common' + sLineBreak +
      '</VirtualHost>', TEncoding.UTF8);

  if not FileExists(Paths.ApacheVHostsTemplateFile) then
    TFile.WriteAllText(Paths.ApacheVHostsTemplateFile,
      '# Managed by UniWamp' + sLineBreak +
      '{{VHOSTS}}', TEncoding.UTF8);

  if not FileExists(Paths.MariaDbTemplateFile) then
    TFile.WriteAllText(Paths.MariaDbTemplateFile,
      '[mysqld]' + sLineBreak +
      'port={{DB_PORT}}' + sLineBreak +
      'basedir={{MARIADB_DIR}}' + sLineBreak +
      'datadir={{MARIADB_DATA_DIR}}' + sLineBreak +
      'socket={{TMP_DIR}}/mariadb.sock' + sLineBreak +
      'pid-file={{LOGS_DIR}}/mariadb.pid' + sLineBreak +
      'log-error={{LOGS_DIR}}/mariadb-error.log' + sLineBreak +
      'tmpdir={{TMP_DIR}}', TEncoding.UTF8);

  if FileExists(Paths.PhpTemplateFile) then
    PhpTemplateText := TFile.ReadAllText(Paths.PhpTemplateFile, TEncoding.UTF8)
  else
    PhpTemplateText := '';

  if (PhpTemplateText = '') or
     (Pos('{{PHP_EXTENSION_LINES}}', PhpTemplateText) = 0) or
     (Pos('{{ERROR_REPORTING}}', PhpTemplateText) = 0) then
    TFile.WriteAllText(Paths.PhpTemplateFile,
      '[PHP]' + sLineBreak +
      'display_errors={{DISPLAY_ERRORS}}' + sLineBreak +
      'error_reporting={{ERROR_REPORTING}}' + sLineBreak +
      'log_errors={{LOG_ERRORS}}' + sLineBreak +
      'short_open_tag={{SHORT_OPEN_TAG}}' + sLineBreak +
      'expose_php={{EXPOSE_PHP}}' + sLineBreak +
      'memory_limit={{MEMORY_LIMIT}}' + sLineBreak +
      'upload_max_filesize={{UPLOAD_MAX_FILESIZE}}' + sLineBreak +
      'post_max_size={{POST_MAX_SIZE}}' + sLineBreak +
      'max_execution_time={{MAX_EXECUTION_TIME}}' + sLineBreak +
      'max_input_vars={{MAX_INPUT_VARS}}' + sLineBreak +
      'extension_dir="{{PHP_EXT_DIR}}"' + sLineBreak +
      '{{PHP_EXTENSION_LINES}}' + sLineBreak +
      'upload_tmp_dir="{{TMP_DIR}}"' + sLineBreak +
      'sys_temp_dir="{{TMP_DIR}}"' + sLineBreak +
      'error_log="{{LOGS_DIR}}\php-error.log"', TEncoding.UTF8);
end;

end.
