program ConfigHarness;

{$APPTYPE CONSOLE}

uses
  System.Classes,
  System.IOUtils,
  System.SysUtils,
  System.JSON,
  Core.UniWamp.Config,
  Core.UniWamp.Paths;

procedure Fail(const MessageText: string);
begin
  raise Exception.Create(MessageText);
end;

procedure AssertTrue(const Condition: Boolean; const MessageText: string);
begin
  if not Condition then
    Fail(MessageText);
end;

procedure AssertEquals(const Expected, Actual, MessageText: string);
begin
  if not SameText(Expected, Actual) then
    Fail(Format('%s Expected="%s" Actual="%s"', [MessageText, Expected, Actual]));
end;

procedure AssertIntEquals(const Expected, Actual: Integer; const MessageText: string);
begin
  if Expected <> Actual then
    Fail(Format('%s Expected=%d Actual=%d', [MessageText, Expected, Actual]));
end;

procedure AssertConfigVersion(const FileName: string; const ExpectedVersion: Integer; const MessageText: string);
var
  JsonText: string;
  Root: TJSONObject;
begin
  JsonText := TFile.ReadAllText(FileName, TEncoding.UTF8);
  Root := TJSONObject.ParseJSONValue(JsonText) as TJSONObject;
  try
    AssertTrue(Assigned(Root), MessageText);
    AssertIntEquals(ExpectedVersion, Root.GetValue<Integer>('configVersion'), MessageText);
  finally
    Root.Free;
  end;
end;

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

procedure EnsureTestLayout(const Paths: TAppPaths);
begin
  EnsurePortableLayout(Paths);
end;

procedure WriteTextFile(const FileName, Content: string);
begin
  TFile.WriteAllText(FileName, Content, TEncoding.UTF8);
end;

procedure TestMalformedConfigRecovery;
var
  RootDir: string;
  Paths: TAppPaths;
  Config: TUniWampConfig;
begin
  RootDir := CreateTempRoot('invalid');
  try
    Paths := BuildPaths(RootDir);
    EnsureTestLayout(Paths);
    WriteTextFile(Paths.AppConfigFile, '{broken json');

    Config := TUniWampConfig.Create;
    try
      AssertTrue(Config.LoadOrCreate(Paths), 'Malformed config should report recovery');
      AssertTrue(TFile.Exists(Paths.AppConfigFile + '.invalid'), 'Malformed config should be backed up');
      AssertTrue(TFile.Exists(Paths.AppConfigFile), 'Malformed config should be rewritten');
      AssertTrue(Config.HttpPort = 8080, 'Recovered config should use defaults');
      AssertTrue(Config.LastMigrationMessage <> '', 'Malformed recovery should produce a status message');
    finally
      Config.Free;
    end;
  finally
    TDirectory.Delete(RootDir, True);
  end;
end;

procedure TestRelativePathMigration;
var
  RootDir: string;
  Paths: TAppPaths;
  Config: TUniWampConfig;
  JsonText: string;
  VHosts: TArray<TVHostEntry>;
begin
  RootDir := CreateTempRoot('relative');
  try
    Paths := BuildPaths(RootDir);
    EnsureTestLayout(Paths);
    JsonText :=
      '{' +
      '"httpPort":8080,' +
      '"httpsPort":8443,' +
      '"databasePort":3306,' +
      '"hostName":"localhost",' +
      '"documentRoot":"www\\site",' +
      '"selectedPhpVersion":"php85",' +
      '"selectedNodeVersion":"node",' +
      '"terminalExePath":"bin\\cmder\\cmder.exe",' +
      '"phpProfile":"development",' +
      '"enableSsl":false,' +
      '"apachePid":0,' +
      '"mariaDbPid":0,' +
      '"apacheRunning":false,' +
      '"mariaDbRunning":false,' +
      '"lastApacheError":"",' +
      '"lastMariaDbError":"",' +
      '"lastHostsSyncStatus":"",' +
      '"mariaDbRootPassword":"",' +
      '"apacheEnabledModules":[],' +
      '"phpVersions":[],' +
      '"phpEnabledExtensions":[],' +
      '"phpSettings":{},' +
      '"nodeVersions":[],' +
      '"vhosts":[{"serverName":"test.local","serverAliases":"","documentRoot":"www\\test","enableSsl":false,"sslCertFile":"ssl\\cert.pem","sslKeyFile":"ssl\\key.pem"}]' +
      '}';
    WriteTextFile(Paths.AppConfigFile, JsonText);

    Config := TUniWampConfig.Create;
    try
      AssertTrue(Config.LoadOrCreate(Paths), 'Relative path config should report migration');
      VHosts := Config.VHosts;
      AssertTrue(SameText(Config.DocumentRoot, TPath.Combine(Paths.AppRoot, 'www\site')),
        'Document root should resolve against app root');
      AssertTrue(Length(VHosts) = 1, 'Expected one vhost');
      AssertTrue(SameText(VHosts[0].DocumentRoot, TPath.Combine(Paths.AppRoot, 'www\test')),
        'VHost root should resolve against app root');
      AssertTrue(SameText(VHosts[0].SslCertFile, TPath.Combine(Paths.AppRoot, 'ssl\cert.pem')),
        'SSL cert path should resolve against app root');
      AssertTrue(SameText(VHosts[0].SslKeyFile, TPath.Combine(Paths.AppRoot, 'ssl\key.pem')),
        'SSL key path should resolve against app root');
      AssertTrue(Config.LastMigrationMessage <> '', 'Migration should produce a message');
      AssertConfigVersion(Paths.AppConfigFile, 1, 'Migrated config should persist configVersion');
    finally
      Config.Free;
    end;
  finally
    TDirectory.Delete(RootDir, True);
  end;
end;

procedure TestInvalidPortsAndDefaults;
var
  RootDir: string;
  Paths: TAppPaths;
  Config: TUniWampConfig;
begin
  RootDir := CreateTempRoot('ports');
  try
    Paths := BuildPaths(RootDir);
    EnsureTestLayout(Paths);
    WriteTextFile(Paths.AppConfigFile,
      '{"httpPort":0,"httpsPort":8080,"databasePort":8080,"hostName":"","documentRoot":"","apacheEnabledModules":[],"phpVersions":[],"phpEnabledExtensions":[],"phpSettings":{},"nodeVersions":[],"vhosts":[]}');

    Config := TUniWampConfig.Create;
    try
      AssertTrue(Config.LoadOrCreate(Paths), 'Invalid ports should trigger migration');
      AssertIntEquals(8080, Config.HttpPort, 'HTTP port should fall back to default');
      AssertIntEquals(8443, Config.HttpsPort, 'HTTPS port should be corrected');
      AssertIntEquals(3307, Config.DatabasePort, 'Database port should be corrected');
      AssertEquals('localhost', Config.HostName, 'Empty hostname should default to localhost');
      AssertEquals(Paths.WwwDir, Config.DocumentRoot, 'Empty document root should default to www');
      AssertConfigVersion(Paths.AppConfigFile, 1, 'Saved config should persist configVersion');
    finally
      Config.Free;
    end;
  finally
    TDirectory.Delete(RootDir, True);
  end;
end;

procedure TestAtomicSaveFailure;
var
  RootDir: string;
  Paths: TAppPaths;
  Config: TUniWampConfig;
  SaveFailed: Boolean;
begin
  RootDir := CreateTempRoot('save-failure');
  try
    Paths := BuildPaths(RootDir);
    EnsureTestLayout(Paths);
    Config := TUniWampConfig.Create;
    try
      Config.SetDefaults(Paths);
      Paths.ConfigDir := TPath.Combine(RootDir, 'missing-config-dir');
      Paths.AppConfigFile := TPath.Combine(Paths.ConfigDir, 'uniwamp.json');
      SaveFailed := False;
      try
        Config.Save(Paths);
      except
        on E: Exception do
          SaveFailed := True;
      end;
      AssertTrue(SaveFailed, 'Save should fail when the target directory does not exist');
      AssertTrue(not TFile.Exists(Paths.AppConfigFile), 'Save failure should not create the target file');
      AssertTrue(not TFile.Exists(Paths.AppConfigFile + '.tmp'), 'Save failure should not leave a temp file behind');
      AssertTrue(not TFile.Exists(Paths.AppConfigFile + '.bak'), 'Save failure should not leave a backup file behind');
    finally
      Config.Free;
    end;
  finally
    TDirectory.Delete(RootDir, True);
  end;
end;

procedure TestCurrentConfigDoesNotMigrate;
var
  RootDir: string;
  Paths: TAppPaths;
  Config: TUniWampConfig;
  JsonText: string;
  SavedText: string;
begin
  RootDir := CreateTempRoot('current');
  try
    Paths := BuildPaths(RootDir);
    EnsureTestLayout(Paths);
    JsonText :=
      '{' +
      '"configVersion":1,' +
      '"httpPort":8080,' +
      '"httpsPort":8443,' +
      '"databasePort":3307,' +
      '"hostName":"localhost",' +
      '"documentRoot":"' + StringReplace(Paths.WwwDir, '\', '\\', [rfReplaceAll]) + '",' +
      '"selectedPhpVersion":"php85",' +
      '"selectedNodeVersion":"node-v22",' +
      '"terminalExePath":"bin\\cmder\\cmder.exe",' +
      '"phpProfile":"development",' +
      '"enableSsl":false,' +
      '"apachePid":0,' +
      '"mariaDbPid":0,' +
      '"apacheRunning":false,' +
      '"mariaDbRunning":false,' +
      '"lastApacheError":"",' +
      '"lastMariaDbError":"",' +
      '"lastHostsSyncStatus":"",' +
      '"mariaDbRootPassword":"",' +
      '"apacheEnabledModules":[],' +
      '"phpVersions":["php85"],' +
      '"phpEnabledExtensions":[],' +
      '"phpSettings":{},' +
      '"nodeVersions":["node-v22"],' +
      '"vhosts":[]' +
      '}';
    WriteTextFile(Paths.AppConfigFile, JsonText);

    Config := TUniWampConfig.Create;
    try
      AssertTrue(not Config.LoadOrCreate(Paths), 'Current config should not report migration');
      AssertTrue(Config.LastMigrationMessage = '', 'Current config should not set a migration message');
      SavedText := TFile.ReadAllText(Paths.AppConfigFile, TEncoding.UTF8);
      AssertTrue(Pos('"configVersion":1', SavedText) > 0, 'Current config should remain versioned');
      AssertTrue(Pos('"httpPort":8080', SavedText) > 0, 'Current config should preserve the HTTP port');
    finally
      Config.Free;
    end;
  finally
    TDirectory.Delete(RootDir, True);
  end;
end;

procedure TestPartiallyValidConfigMigratesOnlyInvalidValues;
var
  RootDir: string;
  Paths: TAppPaths;
  Config: TUniWampConfig;
  JsonText: string;
begin
  RootDir := CreateTempRoot('partial');
  try
    Paths := BuildPaths(RootDir);
    EnsureTestLayout(Paths);
    JsonText :=
      '{' +
      '"configVersion":1,' +
      '"httpPort":8080,' +
      '"httpsPort":8443,' +
      '"databasePort":3306,' +
      '"hostName":"",' +
      '"documentRoot":"",' +
      '"selectedPhpVersion":"php85",' +
      '"selectedNodeVersion":"node-v22",' +
      '"terminalExePath":"bin\\cmder\\cmder.exe",' +
      '"phpProfile":"development",' +
      '"enableSsl":false,' +
      '"apachePid":0,' +
      '"mariaDbPid":0,' +
      '"apacheRunning":false,' +
      '"mariaDbRunning":false,' +
      '"lastApacheError":"",' +
      '"lastMariaDbError":"",' +
      '"lastHostsSyncStatus":"",' +
      '"mariaDbRootPassword":"",' +
      '"apacheEnabledModules":[],' +
      '"phpVersions":[],' +
      '"phpEnabledExtensions":[],' +
      '"phpSettings":{},' +
      '"nodeVersions":[],' +
      '"vhosts":[' +
      '{"serverName":"partial.local","serverAliases":"","documentRoot":"www\\partial","enableSsl":false,"sslCertFile":"ssl\\cert.pem","sslKeyFile":"ssl\\key.pem"}' +
      ']'+
      '}';
    WriteTextFile(Paths.AppConfigFile, JsonText);

    Config := TUniWampConfig.Create;
    try
      AssertTrue(Config.LoadOrCreate(Paths), 'Partially valid config should report migration');
      AssertEquals('localhost', Config.HostName, 'Empty hostname should fall back to localhost');
      AssertEquals(Paths.WwwDir, Config.DocumentRoot, 'Empty document root should fall back to www');
      AssertTrue(SameText(Config.TerminalExePath, 'bin\cmder\cmder.exe'),
        'Portable terminal path should remain relative');
      AssertTrue(SameText(Config.VHosts[0].DocumentRoot, TPath.Combine(Paths.AppRoot, 'www\partial')),
        'Relative vHost document root should resolve to the app root');
      AssertTrue(SameText(Config.VHosts[0].SslCertFile, TPath.Combine(Paths.AppRoot, 'ssl\cert.pem')),
        'Relative vHost SSL cert should resolve to the app root');
      AssertTrue(SameText(Config.VHosts[0].SslKeyFile, TPath.Combine(Paths.AppRoot, 'ssl\key.pem')),
        'Relative vHost SSL key should resolve to the app root');
      AssertTrue(Config.LastMigrationMessage <> '', 'Partially valid config should produce a migration message');
    finally
      Config.Free;
    end;
  finally
    TDirectory.Delete(RootDir, True);
  end;
end;

begin
  try
    TestMalformedConfigRecovery;
    TestCurrentConfigDoesNotMigrate;
    TestRelativePathMigration;
    TestInvalidPortsAndDefaults;
    TestPartiallyValidConfigMigratesOnlyInvalidValues;
    TestAtomicSaveFailure;
    Writeln('Config harness passed.');
  except
    on E: Exception do
    begin
      Writeln(E.ClassName + ': ' + E.Message);
      Halt(1);
    end;
  end;
end.
