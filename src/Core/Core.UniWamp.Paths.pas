unit Core.UniWamp.Paths;

interface

uses
  System.SysUtils;

type
  TAppPaths = record
  public
    AppRoot: string;
    BinDir: string;
    ConfigDir: string;
    GeneratedConfigDir: string;
    TemplatesDir: string;
    RuntimeDir: string;
    ToolsDir: string;
    ComposerDir: string;
    GitDir: string;
    WpCliDir: string;
    MailpitDir: string;
    RedisDir: string;
    MemcachedDir: string;
    ApacheDir: string;
    ApacheBinDir: string;
    ApacheConfDir: string;
    MariaDbDir: string;
    MariaDbBinDir: string;
    PhpDir: string;
    NodeDir: string;
    CmderDir: string;
    HomeDir: string;
    AdminerDir: string;
    DashboardDir: string;
    LogsDir: string;
    TmpDir: string;
    UpdatesDir: string;
    WwwDir: string;
    VHostsDir: string;
    SslDir: string;
    StateFile: string;
    AppConfigFile: string;
    ApacheTemplateFile: string;
    ApacheSslTemplateFile: string;
    ApacheVHostsTemplateFile: string;
    MariaDbTemplateFile: string;
    PhpTemplateFile: string;
    ApacheHttpdConfFile: string;
    ApacheSslConfFile: string;
    ApacheVHostsConfFile: string;
    MariaDbIniFile: string;
    ActivePhpIniFile: string;
    EnvBatFile: string;
    class function Detect: TAppPaths; static;
  end;

procedure EnsureDirectory(const DirectoryPath: string);
procedure EnsurePortableLayout(const Paths: TAppPaths);

implementation

uses
  System.IOUtils;

class function TAppPaths.Detect: TAppPaths;
var
  Root: string;
  Candidate: string;
  I: Integer;
begin
  Root := ExpandFileName(ExtractFilePath(ParamStr(0)));
  for I := 0 to 5 do
  begin
    Candidate := TPath.Combine(Root, 'templates');
    if TDirectory.Exists(Candidate) then
      Break;
    Root := ExpandFileName(TPath.Combine(Root, '..'));
  end;
  Result.AppRoot := Root;
  Result.BinDir := TPath.Combine(Root, 'bin');
  Result.ConfigDir := TPath.Combine(Root, 'config');
  Result.GeneratedConfigDir := TPath.Combine(Result.ConfigDir, 'generated');
  Result.TemplatesDir := TPath.Combine(Root, 'templates');
  Result.RuntimeDir := TPath.Combine(Root, 'runtime');
  Result.ToolsDir := TPath.Combine(Result.RuntimeDir, 'tools');
  Result.ComposerDir := TPath.Combine(Result.ToolsDir, 'composer');
  Result.GitDir := TPath.Combine(Result.ToolsDir, 'git');
  Result.WpCliDir := TPath.Combine(Result.ToolsDir, 'wp-cli');
  Result.MailpitDir := TPath.Combine(Result.ToolsDir, 'mailpit');
  Result.RedisDir := TPath.Combine(Result.ToolsDir, 'redis');
  Result.MemcachedDir := TPath.Combine(Result.ToolsDir, 'memcached');
  Result.ApacheDir := TPath.Combine(Result.RuntimeDir, 'apache');
  Result.ApacheBinDir := TPath.Combine(Result.ApacheDir, 'bin');
  Result.ApacheConfDir := TPath.Combine(Result.ApacheDir, 'conf');
  Result.MariaDbDir := TPath.Combine(Result.RuntimeDir, 'mariadb');
  Result.MariaDbBinDir := TPath.Combine(Result.MariaDbDir, 'bin');
  Result.PhpDir := TPath.Combine(Result.RuntimeDir, 'php');
  Result.NodeDir := TPath.Combine(Result.RuntimeDir, 'nodejs');
  Result.CmderDir := TPath.Combine(Result.BinDir, 'cmder');
  Result.HomeDir := TPath.Combine(Root, 'home');
  Result.AdminerDir := TPath.Combine(Result.HomeDir, 'adminer');
  Result.DashboardDir := TPath.Combine(Result.HomeDir, 'dashboard');
  Result.LogsDir := TPath.Combine(Root, 'logs');
  Result.TmpDir := TPath.Combine(Root, 'tmp');
  Result.UpdatesDir := TPath.Combine(Result.TmpDir, 'updates');
  Result.WwwDir := TPath.Combine(Root, 'www');
  Result.VHostsDir := Result.WwwDir;
  Result.SslDir := TPath.Combine(Root, 'ssl');
  Result.StateFile := TPath.Combine(Result.ConfigDir, 'state.json');
  Result.AppConfigFile := TPath.Combine(Result.ConfigDir, 'uniwamp.json');
  Result.ApacheTemplateFile := TPath.Combine(Result.TemplatesDir, 'httpd.conf.tpl');
  Result.ApacheSslTemplateFile := TPath.Combine(Result.TemplatesDir, 'httpd-ssl.conf.tpl');
  Result.ApacheVHostsTemplateFile := TPath.Combine(Result.TemplatesDir, 'httpd-vhosts.conf.tpl');
  Result.MariaDbTemplateFile := TPath.Combine(Result.TemplatesDir, 'mariadb.ini.tpl');
  Result.PhpTemplateFile := TPath.Combine(Result.TemplatesDir, 'php.ini.tpl');
  Result.ApacheHttpdConfFile := TPath.Combine(Result.GeneratedConfigDir, 'httpd.conf');
  Result.ApacheSslConfFile := TPath.Combine(Result.GeneratedConfigDir, 'httpd-ssl.conf');
  Result.ApacheVHostsConfFile := TPath.Combine(Result.GeneratedConfigDir, 'httpd-vhosts.conf');
  Result.MariaDbIniFile := TPath.Combine(Result.GeneratedConfigDir, 'mariadb.ini');
  Result.ActivePhpIniFile := TPath.Combine(Result.GeneratedConfigDir, 'php.ini');
  Result.EnvBatFile := TPath.Combine(Result.GeneratedConfigDir, 'env.bat');
end;

procedure EnsureDirectory(const DirectoryPath: string);
begin
  if not TDirectory.Exists(DirectoryPath) then
    TDirectory.CreateDirectory(DirectoryPath);
end;

procedure EnsurePortableLayout(const Paths: TAppPaths);
begin
  EnsureDirectory(Paths.BinDir);
  EnsureDirectory(Paths.ConfigDir);
  EnsureDirectory(Paths.GeneratedConfigDir);
  EnsureDirectory(Paths.TemplatesDir);
  EnsureDirectory(Paths.RuntimeDir);
  EnsureDirectory(Paths.ToolsDir);
  EnsureDirectory(Paths.ComposerDir);
  EnsureDirectory(Paths.GitDir);
  EnsureDirectory(Paths.WpCliDir);
  EnsureDirectory(Paths.MailpitDir);
  EnsureDirectory(Paths.RedisDir);
  EnsureDirectory(Paths.MemcachedDir);
  EnsureDirectory(Paths.ApacheDir);
  EnsureDirectory(Paths.ApacheBinDir);
  EnsureDirectory(Paths.ApacheConfDir);
  EnsureDirectory(Paths.MariaDbDir);
  EnsureDirectory(Paths.MariaDbBinDir);
  EnsureDirectory(Paths.PhpDir);
  EnsureDirectory(Paths.NodeDir);
  EnsureDirectory(Paths.CmderDir);
  EnsureDirectory(Paths.HomeDir);
  EnsureDirectory(Paths.AdminerDir);
  EnsureDirectory(Paths.DashboardDir);
  EnsureDirectory(Paths.LogsDir);
  EnsureDirectory(Paths.TmpDir);
  EnsureDirectory(Paths.UpdatesDir);
  EnsureDirectory(Paths.WwwDir);
  EnsureDirectory(Paths.VHostsDir);
  EnsureDirectory(Paths.SslDir);
end;

end.
