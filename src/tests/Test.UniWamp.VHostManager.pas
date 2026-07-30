unit Test.UniWamp.VHostManager;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TVHostManagerTests = class
  public
    [Test]
    procedure TestDeleteVHostReportsHostsSyncFailureWithoutRemovingConfig;
    [Test]
    procedure TestDeleteVHostKeepsProjectDocumentRootIntact;
    [Test]
    procedure TestGenerateSslCertificateFailsExplicitlyWhenToolchainMissing;
  end;

implementation

uses
  System.IOUtils,
  System.SysUtils,
  Core.UniWamp.Config,
  Core.UniWamp.Paths,
  Core.UniWamp.TemplateRenderer,
  Core.UniWamp.Types,
  Core.UniWamp.VHostManager;

function SetProcessEnvironmentVariable(const Name, Value: string): Boolean;
  stdcall; external 'kernel32.dll' name 'SetEnvironmentVariableW';

function CreateTempRoot(const Name: string): string;
var
  GuidText: string;
begin
  GuidText := StringReplace(GUIDToString(TGUID.NewGuid), '{', '', [rfReplaceAll]);
  GuidText := StringReplace(GuidText, '}', '', [rfReplaceAll]);
  Result := TPath.Combine(TPath.GetTempPath, 'UniWamp-' + Name + '-' + GuidText);
  TDirectory.CreateDirectory(Result);
end;

function BuildPaths(const Root: string): TAppPaths;
begin
  Result := Default(TAppPaths);
  Result.AppRoot := Root;
  Result.ConfigDir := TPath.Combine(Root, 'config');
  Result.GeneratedConfigDir := TPath.Combine(Result.ConfigDir, 'generated');
  Result.TemplatesDir := TPath.Combine(Root, 'templates');
  Result.ApacheTemplateFile := TPath.Combine(Result.TemplatesDir, 'httpd.conf.tpl');
  Result.ApacheSslTemplateFile := TPath.Combine(Result.TemplatesDir, 'httpd-ssl.conf.tpl');
  Result.ApacheVHostsTemplateFile := TPath.Combine(Result.TemplatesDir, 'httpd-vhosts.conf.tpl');
  Result.VHostIndexTemplateFile := TPath.Combine(Result.TemplatesDir, 'vhost-index.html.tpl');
  Result.MariaDbTemplateFile := TPath.Combine(Result.TemplatesDir, 'mariadb.ini.tpl');
  Result.PhpTemplateFile := TPath.Combine(Result.TemplatesDir, 'php.ini.tpl');
  Result.RuntimeDir := TPath.Combine(Root, 'runtime');
  Result.ToolsDir := TPath.Combine(Result.RuntimeDir, 'tools');
  Result.ComposerDir := TPath.Combine(Result.ToolsDir, 'composer');
  Result.GitDir := TPath.Combine(Result.ToolsDir, 'git');
  Result.PuttyDir := TPath.Combine(Result.ToolsDir, 'putty');
  Result.WpCliDir := TPath.Combine(Result.ToolsDir, 'wp-cli');
  Result.MailpitDir := TPath.Combine(Result.ToolsDir, 'mailpit');
  Result.RedisDir := TPath.Combine(Result.ToolsDir, 'redis');
  Result.MemcachedDir := TPath.Combine(Result.ToolsDir, 'memcached');
  Result.WinScpDir := TPath.Combine(Result.ToolsDir, 'winscp');
  Result.ApacheDir := TPath.Combine(Result.RuntimeDir, 'apache');
  Result.ApacheBinDir := TPath.Combine(Result.ApacheDir, 'bin');
  Result.ApacheConfDir := TPath.Combine(Result.ApacheDir, 'conf');
  Result.ApacheHttpdConfFile := TPath.Combine(Result.GeneratedConfigDir, 'httpd.conf');
  Result.ApacheSslConfFile := TPath.Combine(Result.GeneratedConfigDir, 'httpd-ssl.conf');
  Result.ApacheVHostsConfFile := TPath.Combine(Result.GeneratedConfigDir, 'httpd-vhosts.conf');
  Result.MariaDbDir := TPath.Combine(Result.RuntimeDir, 'mariadb');
  Result.MariaDbBinDir := TPath.Combine(Result.MariaDbDir, 'bin');
  Result.PhpDir := TPath.Combine(Result.RuntimeDir, 'php');
  Result.NodeDir := TPath.Combine(Result.RuntimeDir, 'nodejs');
  Result.CmderDir := TPath.Combine(Root, 'cmder');
  Result.MkcertDir := TPath.Combine(Result.ToolsDir, 'mkcert');
  Result.MkcertExe := TPath.Combine(Result.MkcertDir, 'mkcert.exe');
  Result.HomeDir := TPath.Combine(Root, 'home');
  Result.AdminerDir := TPath.Combine(Result.HomeDir, 'adminer');
  Result.DashboardDir := TPath.Combine(Result.HomeDir, 'dashboard');
  Result.LogsDir := TPath.Combine(Root, 'logs');
  Result.TmpDir := TPath.Combine(Root, 'tmp');
  Result.UpdatesDir := TPath.Combine(Result.TmpDir, 'updates');
  Result.BackupsDir := TPath.Combine(Root, 'backups');
  Result.ProjectBackupsDir := TPath.Combine(Result.BackupsDir, 'projects');
  Result.DatabaseBackupsDir := TPath.Combine(Result.BackupsDir, 'databases');
  Result.WwwDir := TPath.Combine(Root, 'www');
  Result.VHostsDir := Result.WwwDir;
  Result.SslDir := TPath.Combine(Root, 'ssl');
  EnsureDirectory(Result.ConfigDir);
  EnsureDirectory(Result.GeneratedConfigDir);
  EnsureDirectory(Result.TemplatesDir);
  EnsureDirectory(Result.RuntimeDir);
  EnsureDirectory(Result.ToolsDir);
  EnsureDirectory(Result.ComposerDir);
  EnsureDirectory(Result.GitDir);
  EnsureDirectory(Result.PuttyDir);
  EnsureDirectory(Result.WpCliDir);
  EnsureDirectory(Result.MailpitDir);
  EnsureDirectory(Result.RedisDir);
  EnsureDirectory(Result.MemcachedDir);
  EnsureDirectory(Result.WinScpDir);
  EnsureDirectory(Result.ApacheDir);
  EnsureDirectory(Result.ApacheBinDir);
  EnsureDirectory(Result.ApacheConfDir);
  EnsureDirectory(Result.MariaDbDir);
  EnsureDirectory(Result.MariaDbBinDir);
  EnsureDirectory(Result.PhpDir);
  EnsureDirectory(Result.NodeDir);
  EnsureDirectory(Result.CmderDir);
  EnsureDirectory(Result.HomeDir);
  EnsureDirectory(Result.AdminerDir);
  EnsureDirectory(Result.DashboardDir);
  EnsureDirectory(Result.LogsDir);
  EnsureDirectory(Result.TmpDir);
  EnsureDirectory(Result.UpdatesDir);
  EnsureDirectory(Result.BackupsDir);
  EnsureDirectory(Result.ProjectBackupsDir);
  EnsureDirectory(Result.DatabaseBackupsDir);
  EnsureDirectory(Result.WwwDir);
  EnsureDirectory(Result.VHostsDir);
  EnsureDirectory(Result.SslDir);
  TTemplateRenderer.EnsureDefaultTemplates(Result);
end;

procedure TVHostManagerTests.TestDeleteVHostReportsHostsSyncFailureWithoutRemovingConfig;
var
  RootDir: string;
  HostsPath: string;
  Paths: TAppPaths;
  Config: TUniWampConfig;
  Manager: TVHostManager;
  Entry: TVHostEntry;
  ResultInfo: TRuntimeActionResult;
  OldHostsFile: string;
begin
  RootDir := CreateTempRoot('vhost-delete');
  try
    HostsPath := TPath.Combine(RootDir, 'hosts-dir');
    TDirectory.CreateDirectory(HostsPath);
    OldHostsFile := GetEnvironmentVariable('UNIWAMP_HOSTS_FILE');
    SetProcessEnvironmentVariable('UNIWAMP_HOSTS_FILE', HostsPath);
    try
      Paths := BuildPaths(RootDir);
      Config := TUniWampConfig.Create;
      try
        Config.HostName := 'localhost';
        Entry.ServerName := 'example.local';
        Entry.ServerAliases := '';
        Entry.DocumentRoot := TPath.Combine(RootDir, 'www\example.local');
        Entry.EnableSsl := False;
        Entry.SslCertFile := '';
        Entry.SslKeyFile := '';
        Entry.PinnedSyncUploadProfile := '';
        Entry.PinnedSyncDownloadProfile := '';
        Config.AddOrUpdateVHost(Entry);

        Manager := TVHostManager.Create(Paths, Config);
        try
          ResultInfo := Manager.DeleteVHost('example.local');
          Assert.IsFalse(ResultInfo.Success, 'DeleteVHost should fail when the hosts helper fails.');
          Assert.IsTrue(ResultInfo.Message.Contains('Hosts file update failed'), ResultInfo.Message);
          Assert.AreEqual(1, Length(Config.VHosts), 'The vHost config should remain intact on failure.');
          Assert.AreEqual('example.local', Config.VHosts[0].ServerName);
        finally
          Manager.Free;
        end;
      finally
        Config.Free;
      end;
    finally
      if OldHostsFile <> '' then
        SetProcessEnvironmentVariable('UNIWAMP_HOSTS_FILE', OldHostsFile)
      else
        SetProcessEnvironmentVariable('UNIWAMP_HOSTS_FILE', '');
    end;
  finally
    if TDirectory.Exists(RootDir) then
      TDirectory.Delete(RootDir, True);
  end;
end;

procedure TVHostManagerTests.TestDeleteVHostKeepsProjectDocumentRootIntact;
var
  RootDir: string;
  HostsFile: string;
  Paths: TAppPaths;
  Config: TUniWampConfig;
  Manager: TVHostManager;
  Entry: TVHostEntry;
  ResultInfo: TRuntimeActionResult;
  OldHostsFile: string;
  DocumentRoot: string;
begin
  RootDir := CreateTempRoot('vhost-delete-success');
  try
    HostsFile := TPath.Combine(RootDir, 'hosts.txt');
    OldHostsFile := GetEnvironmentVariable('UNIWAMP_HOSTS_FILE');
    SetProcessEnvironmentVariable('UNIWAMP_HOSTS_FILE', HostsFile);
    try
      Paths := BuildPaths(RootDir);
      Config := TUniWampConfig.Create;
      try
        Config.HostName := 'localhost';
        DocumentRoot := TPath.Combine(RootDir, 'www\example.local');
        TDirectory.CreateDirectory(DocumentRoot);
        TFile.WriteAllText(TPath.Combine(DocumentRoot, 'index.html'), 'hello', TEncoding.UTF8);

        Entry.ServerName := 'example.local';
        Entry.ServerAliases := '';
        Entry.DocumentRoot := DocumentRoot;
        Entry.EnableSsl := False;
        Entry.SslCertFile := '';
        Entry.SslKeyFile := '';
        Entry.PinnedSyncUploadProfile := '';
        Entry.PinnedSyncDownloadProfile := '';
        Config.AddOrUpdateVHost(Entry);

        Manager := TVHostManager.Create(Paths, Config);
        try
          ResultInfo := Manager.DeleteVHost('example.local');
          Assert.IsTrue(ResultInfo.Success, ResultInfo.Message);
          Assert.AreEqual(0, Length(Config.VHosts), 'The vHost entry should be removed from config.');
          Assert.IsTrue(TDirectory.Exists(DocumentRoot), 'Deleting a vHost must not remove the project folder.');
          Assert.IsTrue(TFile.Exists(TPath.Combine(DocumentRoot, 'index.html')),
            'Deleting a vHost must not remove project files.');
        finally
          Manager.Free;
        end;
      finally
        Config.Free;
      end;
    finally
      if OldHostsFile <> '' then
        SetProcessEnvironmentVariable('UNIWAMP_HOSTS_FILE', OldHostsFile)
      else
        SetProcessEnvironmentVariable('UNIWAMP_HOSTS_FILE', '');
    end;
  finally
    if TDirectory.Exists(RootDir) then
      TDirectory.Delete(RootDir, True);
  end;
end;

procedure TVHostManagerTests.TestGenerateSslCertificateFailsExplicitlyWhenToolchainMissing;
var
  RootDir: string;
  Paths: TAppPaths;
  Config: TUniWampConfig;
  Manager: TVHostManager;
  ResultInfo: TRuntimeActionResult;
  CertFile: string;
  KeyFile: string;
begin
  RootDir := CreateTempRoot('ssl-generate-missing-tools');
  try
    Paths := BuildPaths(RootDir);
    Config := TUniWampConfig.Create;
    try
      Config.HostName := 'localhost';
      Manager := TVHostManager.Create(Paths, Config);
      try
        CertFile := TPath.Combine(Paths.SslDir, 'server.crt');
        KeyFile := TPath.Combine(Paths.SslDir, 'server.key');
        ResultInfo := Manager.GenerateSslCertificateFor('localhost', CertFile, KeyFile);
        Assert.IsFalse(ResultInfo.Success, 'Certificate generation should fail when both toolchains are missing.');
        Assert.IsTrue(ResultInfo.Message.Contains('OpenSSL executable not found'), ResultInfo.Message);
        Assert.IsFalse(TFile.Exists(CertFile), 'No certificate file should be created on failure.');
        Assert.IsFalse(TFile.Exists(KeyFile), 'No key file should be created on failure.');
      finally
        Manager.Free;
      end;
    finally
      Config.Free;
    end;
  finally
    if TDirectory.Exists(RootDir) then
      TDirectory.Delete(RootDir, True);
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TVHostManagerTests);

end.
