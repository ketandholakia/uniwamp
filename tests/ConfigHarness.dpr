program ConfigHarness;

{$APPTYPE CONSOLE}

uses
  Winapi.Windows,
  System.Classes,
  System.Generics.Collections,
  System.IOUtils,
  System.SysUtils,
  System.JSON,
  Core.UniWamp.Config,
  Core.UniWamp.Interfaces,
  Core.UniWamp.Types,
  Core.UniWamp.TemplateRenderer,
  Core.UniWamp.VHostManager,
  Core.UniWamp.Paths,
  Core.UniWamp.Secrets,
  Core.UniWamp.SyncEngine,
  Core.UniWamp.SyncTransport;

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

procedure AssertContains(const Haystack, Needle, MessageText: string);
begin
  if Pos(LowerCase(Needle), LowerCase(Haystack)) = 0 then
    Fail(Format('%s Haystack="%s" Needle="%s"', [MessageText, Haystack, Needle]));
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
  Result := Default(TAppPaths);
  Result.AppRoot := Root;
  Result.BinDir := TPath.Combine(Root, 'bin');
  Result.ConfigDir := TPath.Combine(Root, 'config');
  Result.GeneratedConfigDir := TPath.Combine(Result.ConfigDir, 'generated');
  Result.TemplatesDir := TPath.Combine(Root, 'templates');
  Result.RuntimeDir := TPath.Combine(Root, 'runtime');
  Result.ToolsDir := TPath.Combine(Result.RuntimeDir, 'tools');
  Result.ComposerDir := TPath.Combine(Result.ToolsDir, 'composer');
  Result.GitDir := TPath.Combine(Result.ToolsDir, 'git');
  Result.PuttyDir := TPath.Combine(Result.ToolsDir, 'putty');
  Result.WpCliDir := TPath.Combine(Result.ToolsDir, 'wp-cli');
  Result.MailpitDir := TPath.Combine(Result.ToolsDir, 'mailpit');
  Result.RedisDir := TPath.Combine(Result.ToolsDir, 'redis');
  Result.MemcachedDir := TPath.Combine(Result.ToolsDir, 'memcached');
  Result.MkcertDir := TPath.Combine(Result.ToolsDir, 'mkcert');
  Result.MkcertExe := TPath.Combine(Result.MkcertDir, 'mkcert.exe');
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
  Result.BackupsDir := TPath.Combine(Root, 'backups');
  Result.ProjectBackupsDir := TPath.Combine(Result.BackupsDir, 'projects');
  Result.DatabaseBackupsDir := TPath.Combine(Result.BackupsDir, 'databases');
  Result.WwwDir := TPath.Combine(Root, 'www');
  Result.VHostsDir := Result.WwwDir;
  Result.SslDir := TPath.Combine(Root, 'ssl');
  Result.StateFile := TPath.Combine(Result.ConfigDir, 'state.json');
  Result.AppConfigFile := TPath.Combine(Result.ConfigDir, 'uniwamp.json');
  Result.ApacheTemplateFile := TPath.Combine(Result.TemplatesDir, 'httpd.conf.tpl');
  Result.ApacheSslTemplateFile := TPath.Combine(Result.TemplatesDir, 'httpd-ssl.conf.tpl');
  Result.ApacheVHostsTemplateFile := TPath.Combine(Result.TemplatesDir, 'httpd-vhosts.conf.tpl');
  Result.VHostIndexTemplateFile := TPath.Combine(Result.TemplatesDir, 'vhost-index.html.tpl');
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
  AssertTrue(Paths.AppRoot <> '', 'AppRoot must be initialized');
  AssertTrue(Paths.BinDir <> '', 'BinDir must be initialized');
  AssertTrue(Paths.ConfigDir <> '', 'ConfigDir must be initialized');
  AssertTrue(Paths.GeneratedConfigDir <> '', 'GeneratedConfigDir must be initialized');
  AssertTrue(Paths.TemplatesDir <> '', 'TemplatesDir must be initialized');
  AssertTrue(Paths.RuntimeDir <> '', 'RuntimeDir must be initialized');
  AssertTrue(Paths.ToolsDir <> '', 'ToolsDir must be initialized');
  AssertTrue(Paths.MkcertDir <> '', 'MkcertDir must be initialized');
  AssertTrue(Paths.ComposerDir <> '', 'ComposerDir must be initialized');
  AssertTrue(Paths.GitDir <> '', 'GitDir must be initialized');
  AssertTrue(Paths.PuttyDir <> '', 'PuttyDir must be initialized');
  AssertTrue(Paths.WpCliDir <> '', 'WpCliDir must be initialized');
  AssertTrue(Paths.MailpitDir <> '', 'MailpitDir must be initialized');
  AssertTrue(Paths.RedisDir <> '', 'RedisDir must be initialized');
  AssertTrue(Paths.MemcachedDir <> '', 'MemcachedDir must be initialized');
  AssertTrue(Paths.ApacheDir <> '', 'ApacheDir must be initialized');
  AssertTrue(Paths.ApacheBinDir <> '', 'ApacheBinDir must be initialized');
  AssertTrue(Paths.ApacheConfDir <> '', 'ApacheConfDir must be initialized');
  AssertTrue(Paths.MariaDbDir <> '', 'MariaDbDir must be initialized');
  AssertTrue(Paths.MariaDbBinDir <> '', 'MariaDbBinDir must be initialized');
  AssertTrue(Paths.PhpDir <> '', 'PhpDir must be initialized');
  AssertTrue(Paths.NodeDir <> '', 'NodeDir must be initialized');
  AssertTrue(Paths.CmderDir <> '', 'CmderDir must be initialized');
  AssertTrue(Paths.HomeDir <> '', 'HomeDir must be initialized');
  AssertTrue(Paths.AdminerDir <> '', 'AdminerDir must be initialized');
  AssertTrue(Paths.DashboardDir <> '', 'DashboardDir must be initialized');
  AssertTrue(Paths.LogsDir <> '', 'LogsDir must be initialized');
  AssertTrue(Paths.TmpDir <> '', 'TmpDir must be initialized');
  AssertTrue(Paths.UpdatesDir <> '', 'UpdatesDir must be initialized');
  AssertTrue(Paths.BackupsDir <> '', 'BackupsDir must be initialized');
  AssertTrue(Paths.ProjectBackupsDir <> '', 'ProjectBackupsDir must be initialized');
  AssertTrue(Paths.DatabaseBackupsDir <> '', 'DatabaseBackupsDir must be initialized');
  AssertTrue(Paths.WwwDir <> '', 'WwwDir must be initialized');
  AssertTrue(Paths.VHostsDir <> '', 'VHostsDir must be initialized');
  AssertTrue(Paths.SslDir <> '', 'SslDir must be initialized');
  EnsurePortableLayout(Paths);
end;

procedure WriteTextFile(const FileName, Content: string);
begin
  TFile.WriteAllText(FileName, Content, TEncoding.UTF8);
end;

type
  TMockSyncTransport = class(TInterfacedObject, ISyncTransport)
  private
    FEntries: TDictionary<string, TRemoteEntries>;
  public
    constructor Create;
    destructor Destroy; override;
    procedure AddEntries(const RemotePath: string; const Entries: TRemoteEntries);
    procedure Connect;
    procedure Disconnect;
    function IsConnected: Boolean;
    function ListDirectory(const RemotePath: string): TRemoteEntries;
    function RemoteDirectoryExists(const RemotePath: string): Boolean;
    procedure EnsureRemoteDirectory(const RemotePath: string);
    procedure DeleteRemoteFile(const RemotePath: string);
    procedure DeleteRemoteDirectory(const RemotePath: string; const Recursive: Boolean);
    procedure DownloadFile(const RemotePath, LocalPath: string; const OnProgress: TSyncTransferProgressEvent);
    procedure UploadFile(const LocalPath, RemotePath: string; const OnProgress: TSyncTransferProgressEvent);
    procedure SetLogHandler(const Handler: TSyncLogEvent);
  end;

constructor TMockSyncTransport.Create;
begin
  inherited Create;
  FEntries := TDictionary<string, TRemoteEntries>.Create;
end;

destructor TMockSyncTransport.Destroy;
begin
  FEntries.Free;
  inherited Destroy;
end;

procedure TMockSyncTransport.AddEntries(const RemotePath: string; const Entries: TRemoteEntries);
begin
  FEntries.AddOrSetValue(RemotePath, Entries);
end;

procedure TMockSyncTransport.Connect;
begin
end;

procedure TMockSyncTransport.Disconnect;
begin
end;

function TMockSyncTransport.IsConnected: Boolean;
begin
  Result := True;
end;

function TMockSyncTransport.ListDirectory(const RemotePath: string): TRemoteEntries;
begin
  if not FEntries.TryGetValue(RemotePath, Result) then
    SetLength(Result, 0);
end;

function TMockSyncTransport.RemoteDirectoryExists(const RemotePath: string): Boolean;
begin
  Result := FEntries.ContainsKey(RemotePath);
end;

procedure TMockSyncTransport.EnsureRemoteDirectory(const RemotePath: string);
begin
end;

procedure TMockSyncTransport.DeleteRemoteFile(const RemotePath: string);
begin
end;

procedure TMockSyncTransport.DeleteRemoteDirectory(const RemotePath: string; const Recursive: Boolean);
begin
end;

procedure TMockSyncTransport.DownloadFile(const RemotePath, LocalPath: string; const OnProgress: TSyncTransferProgressEvent);
begin
end;

procedure TMockSyncTransport.UploadFile(const LocalPath, RemotePath: string; const OnProgress: TSyncTransferProgressEvent);
begin
end;

procedure TMockSyncTransport.SetLogHandler(const Handler: TSyncLogEvent);
begin
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
      '"themeStyleName":"Windows",' +
      '"enableSsl":false,' +
      '"apachePid":0,' +
      '"mariaDbPid":0,' +
      '"apacheRunning":false,' +
      '"mariaDbRunning":false,' +
      '"lastApacheError":"",' +
      '"lastMariaDbError":"",' +
      '"lastHostsSyncStatus":"",' +
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

procedure TestAtomicSaveCreatesDirectoryAndFile;
var
  RootDir: string;
  Paths: TAppPaths;
  Config: TUniWampConfig;
begin
  RootDir := CreateTempRoot('save-failure');
  try
    Paths := BuildPaths(RootDir);
    EnsureTestLayout(Paths);
    Config := TUniWampConfig.Create;
    try
      Config.SetDefaults(Paths);
      Config.ThemeStyleName := 'Windows';
      Paths.ConfigDir := TPath.Combine(RootDir, 'missing-config-dir');
      Paths.AppConfigFile := TPath.Combine(Paths.ConfigDir, 'uniwamp.json');
      Config.Save(Paths);
      AssertTrue(TDirectory.Exists(Paths.ConfigDir), 'Save should create the missing config directory');
      AssertTrue(TFile.Exists(Paths.AppConfigFile), 'Save should create the config file');
      AssertTrue(not TFile.Exists(Paths.AppConfigFile + '.tmp'), 'Save should not leave a temp file behind');
      AssertTrue(Config.ThemeStyleName = 'Windows', 'Saved config object should preserve the theme style');
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
      '"themeStyleName":"Windows",' +
      '"enableSsl":false,' +
      '"apachePid":0,' +
      '"mariaDbPid":0,' +
      '"apacheRunning":false,' +
      '"mariaDbRunning":false,' +
      '"lastApacheError":"",' +
      '"lastMariaDbError":"",' +
      '"lastHostsSyncStatus":"",' +
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
      AssertTrue(Pos('"themeStyleName":"Windows"', SavedText) > 0, 'Current config should preserve the theme style');
    finally
      Config.Free;
    end;
  finally
    TDirectory.Delete(RootDir, True);
  end;
end;

procedure TestUnknownThemeStylePersistsWithoutMigration;
var
  RootDir: string;
  Paths: TAppPaths;
  Config: TUniWampConfig;
  JsonText: string;
  SavedText: string;
begin
  RootDir := CreateTempRoot('theme-style');
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
      '"themeStyleName":"MissingStyle",' +
      '"enableSsl":false,' +
      '"apachePid":0,' +
      '"mariaDbPid":0,' +
      '"apacheRunning":false,' +
      '"mariaDbRunning":false,' +
      '"lastApacheError":"",' +
      '"lastMariaDbError":"",' +
      '"lastHostsSyncStatus":"",' +
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
      AssertTrue(not Config.LoadOrCreate(Paths), 'Unknown theme styles should not trigger migration');
      AssertEquals('MissingStyle', Config.ThemeStyleName, 'Unknown theme style should still round-trip through config');
      SavedText := TFile.ReadAllText(Paths.AppConfigFile, TEncoding.UTF8);
      AssertTrue(Pos('"themeStyleName":"MissingStyle"', SavedText) > 0, 'Unknown theme style should remain in the saved config');
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

procedure TestLegacyMariaDbPasswordMigratesToProtectedStorage;
var
  RootDir: string;
  Paths: TAppPaths;
  Config: TUniWampConfig;
  JsonText: string;
  SavedText: string;
  ErrorMessage: string;
begin
  RootDir := CreateTempRoot('legacy-secret');
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
      '"mariaDbRootPassword":"legacy-secret",' +
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
      AssertTrue(Config.LoadOrCreate(Paths), 'Legacy MariaDB password should trigger migration');
      AssertEquals('legacy-secret', LoadMariaDbRootPassword(Paths), 'Legacy password should be moved into protected storage');
      SavedText := TFile.ReadAllText(Paths.AppConfigFile, TEncoding.UTF8);
      AssertTrue(Pos('mariaDbRootPassword', SavedText) = 0, 'Migrated config should not persist the MariaDB password field');
    finally
      Config.Free;
    end;
  finally
    DeleteMariaDbRootPassword(Paths, ErrorMessage);
    TDirectory.Delete(RootDir, True);
  end;
end;

procedure TestConnectionSecretsMigrateFromLegacySyncKeys;
var
  RootDir: string;
  Paths: TAppPaths;
  ErrorMessage: string;
begin
  RootDir := CreateTempRoot('connection-secret-migration');
  try
    Paths := BuildPaths(RootDir);
    EnsureTestLayout(Paths);
    AssertTrue(SaveSecret(Paths, SyncPasswordKey('prod-sftp'), 'legacy-pass', ErrorMessage),
      'Legacy sync password should save');
    AssertTrue(SaveSecret(Paths, SyncKeyPassphraseKey('prod-sftp'), 'legacy-key-pass', ErrorMessage),
      'Legacy sync key passphrase should save');

    AssertEquals('legacy-pass', LoadConnectionPassword(Paths, 'prod-sftp'),
      'Connection password should migrate from the legacy sync key');
    AssertEquals('legacy-key-pass', LoadConnectionKeyPassphrase(Paths, 'prod-sftp'),
      'Connection key passphrase should migrate from the legacy sync key');
    AssertTrue(not HasSecret(Paths, SyncPasswordKey('prod-sftp')),
      'Legacy sync password should be deleted after migration');
    AssertTrue(not HasSecret(Paths, SyncKeyPassphraseKey('prod-sftp')),
      'Legacy sync key passphrase should be deleted after migration');
  finally
    DeleteAllConnectionSecrets(Paths, 'prod-sftp');
    TDirectory.Delete(RootDir, True);
  end;
end;

procedure TestSyncEngineRejectsUnsafeRemoteEntries;
var
  RootDir: string;
  LocalRoot: string;
  Transport: ISyncTransport;
  RootEntries: TRemoteEntries;
begin
  RootDir := CreateTempRoot('sync-engine-safety');
  try
    LocalRoot := TPath.Combine(RootDir, 'www');
    TDirectory.CreateDirectory(LocalRoot);
    Transport := TMockSyncTransport.Create as ISyncTransport;
    try
      SetLength(RootEntries, 1);
      RootEntries[0].Name := '..\outside.txt';
      RootEntries[0].IsDirectory := False;
      RootEntries[0].Size := 1;
      RootEntries[0].ModifiedUtc := 0;
      TMockSyncTransport(Transport).AddEntries('/remote', RootEntries);
      try
        TSyncEngine.BuildPlan(Transport, LocalRoot, '/remote', 'download', [], False);
        Fail('Sync engine should reject unsafe remote entries.');
      except
        on E: ESyncTransportError do
          AssertContains(E.Message, 'unsafe entry name', 'Sync engine should report the unsafe remote entry');
      end;
    finally
      Transport := nil;
    end;
  finally
    TDirectory.Delete(RootDir, True);
  end;
end;

procedure TestProjectRestoreRollsBackWhenHostsSyncFails;
var
  RootDir: string;
  Paths: TAppPaths;
  Config: TUniWampConfig;
  Manager: IVHostManager;
  ResultInfo: TRuntimeActionResult;
  OldHostsFile: string;
  InvalidHostsPath: string;
begin
  RootDir := CreateTempRoot('vhost-rollback');
  try
    Paths := BuildPaths(RootDir);
    EnsureTestLayout(Paths);
    TTemplateRenderer.EnsureDefaultTemplates(Paths);
    InvalidHostsPath := TPath.Combine(RootDir, 'hosts-blocked');
    TDirectory.CreateDirectory(InvalidHostsPath);
    OldHostsFile := GetEnvironmentVariable('UNIWAMP_HOSTS_FILE');
    SetEnvironmentVariable('UNIWAMP_HOSTS_FILE', PChar(InvalidHostsPath));
    Config := TUniWampConfig.Create;
    try
      AssertTrue(Config.LoadOrCreate(Paths), 'Test config should load');
      Manager := TVHostManager.Create(Paths, Config);
      ResultInfo := Manager.AddVHost('restore-rollback.local', TPath.Combine(Paths.WwwDir, 'restore-rollback'),
        '', False);
      AssertTrue(not ResultInfo.Success, 'VHost save should fail when hosts sync fails');
      AssertContains(ResultInfo.Message, 'VHost save failed', 'Failure should be reported as a rollback');
      AssertIntEquals(0, Length(Config.VHosts), 'Config should roll back the failed vHost');
      AssertTrue(Pos('restore-rollback.local', TFile.ReadAllText(Paths.ApacheVHostsConfFile, TEncoding.UTF8)) = 0,
        'Generated vHost config should not keep the rolled-back vHost');
    finally
      Config.Free;
      SetEnvironmentVariable('UNIWAMP_HOSTS_FILE', PChar(OldHostsFile));
    end;
  finally
    TDirectory.Delete(RootDir, True);
  end;
end;

begin
  try
    TestMalformedConfigRecovery;
    TestCurrentConfigDoesNotMigrate;
    TestUnknownThemeStylePersistsWithoutMigration;
    TestRelativePathMigration;
    TestInvalidPortsAndDefaults;
    TestPartiallyValidConfigMigratesOnlyInvalidValues;
    TestLegacyMariaDbPasswordMigratesToProtectedStorage;
    TestConnectionSecretsMigrateFromLegacySyncKeys;
    TestSyncEngineRejectsUnsafeRemoteEntries;
    TestProjectRestoreRollsBackWhenHostsSyncFails;
    TestAtomicSaveCreatesDirectoryAndFile;
    Writeln('Config harness passed.');
  except
    on E: Exception do
    begin
      Writeln(E.ClassName + ': ' + E.Message);
      Halt(1);
    end;
  end;
end.
