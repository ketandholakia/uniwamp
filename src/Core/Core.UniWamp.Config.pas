unit Core.UniWamp.Config;

interface

uses
  System.Generics.Collections,
  System.SysUtils,
  Core.UniWamp.Paths;

type
  TVHostEntry = record
    ServerName: string;
    ServerAliases: string;
    DocumentRoot: string;
    EnableSsl: Boolean;
    SslCertFile: string;
    SslKeyFile: string;
    PinnedSyncUploadProfile: string;
    PinnedSyncDownloadProfile: string;
  end;

  TPhpRuntime = record
    Name: string;
    Directory: string;
  end;

  TSyncProfile = record
    Name: string;
    Backend: string;
    Direction: string;
    ExecutablePath: string;
    DefaultTestVHost: string;
    PreSyncCommand: string;
    PostSyncCommand: string;
    RemoteName: string;
    RemotePath: string;
    LocalPath: string;
    WorkingDirectory: string;
    DeleteEnabled: Boolean;
    DryRunByDefault: Boolean;
    Excludes: TArray<string>;
  end;

  TUniWampConfig = class
  private
    FVHosts: TList<TVHostEntry>;
    FApacheModules: TList<string>;
    FPhpVersions: TList<string>;
    FPhpExtensions: TList<string>;
    FPhpSettings: TDictionary<string, string>;
    FNodeVersions: TList<string>;
    FSyncProfiles: TList<TSyncProfile>;
  public
    HttpPort: Integer;
    HttpsPort: Integer;
    DatabasePort: Integer;
    HostName: string;
    DocumentRoot: string;
    SelectedPhpVersion: string;
    SelectedNodeVersion: string;
    TerminalExePath: string;
    PhpProfile: string;
    ThemeStyleName: string;
    EnableSsl: Boolean;
    StartAllOnLaunch: Boolean;
    OpenDashboardAfterStart: Boolean;
    ConfirmVHostDelete: Boolean;
    ApachePid: Cardinal;
    MariaDbPid: Cardinal;
    ApacheRunning: Boolean;
    MariaDbRunning: Boolean;
    MariaDbRootPassword: string;
    LastApacheError: string;
    LastMariaDbError: string;
    LastHostsSyncStatus: string;
    LastMigrationMessage: string;
    LastSyncUploadProfile: string;
    LastSyncDownloadProfile: string;
    constructor Create;
    destructor Destroy; override;
    function LoadOrCreate(const Paths: TAppPaths): Boolean;
    procedure Save(const Paths: TAppPaths);
    procedure SetDefaults(const Paths: TAppPaths);
    procedure ReplaceApacheModules(const Modules: TArray<string>);
    function ApacheModules: TArray<string>;
    procedure ReplacePhpVersions(const Versions: TArray<string>);
    function PhpVersions: TArray<string>;
    procedure ReplacePhpExtensions(const Extensions: TArray<string>);
    function PhpExtensions: TArray<string>;
    function PhpSettingValue(const Name, DefaultValue: string): string;
    procedure SetPhpSettingValue(const Name, Value: string);
    procedure ReplaceNodeVersions(const Versions: TArray<string>);
    function NodeVersions: TArray<string>;
    function SyncProfiles: TArray<TSyncProfile>;
    procedure ReplaceSyncProfiles(const Items: TArray<TSyncProfile>);
    procedure AddOrUpdateSyncProfile(const Item: TSyncProfile);
    procedure DeleteSyncProfile(const Name: string);
    function VHosts: TArray<TVHostEntry>;
    procedure ReplaceVHosts(const Items: TArray<TVHostEntry>);
    procedure AddOrUpdateVHost(const Item: TVHostEntry);
    procedure DeleteVHost(const ServerName: string);
  end;

implementation

uses
  System.Classes,
  System.IOUtils,
  System.StrUtils,
  System.JSON,
  Core.UniWamp.Secrets;

function NormalizePortablePath(const PathValue: string): string;
begin
  Result := StringReplace(PathValue, '/', '\', [rfReplaceAll]);
end;

function ResolveConfiguredPath(const PathValue, AppRoot: string): string;
begin
  Result := NormalizePortablePath(PathValue);
  if (Result <> '') and not TPath.IsPathRooted(Result) then
    Result := TPath.Combine(AppRoot, Result);
end;

function IsValidTcpPort(const Port: Integer): Boolean;
begin
  Result := (Port >= 1) and (Port <= 65535);
end;

function ReplacePathPrefix(const PathValue, OldPrefix, NewPrefix: string): string;
var
  PathText: string;
  OldText: string;
  NewText: string;
  TailText: string;
begin
  Result := PathValue;
  if (PathValue = '') or (OldPrefix = '') or (NewPrefix = '') then
    Exit;

  PathText := IncludeTrailingPathDelimiter(NormalizePortablePath(PathValue));
  OldText := IncludeTrailingPathDelimiter(NormalizePortablePath(OldPrefix));
  if not SameText(Copy(PathText, 1, Length(OldText)), OldText) then
    Exit;

  NewText := ExcludeTrailingPathDelimiter(NormalizePortablePath(NewPrefix));
  TailText := Copy(PathText, Length(OldText) + 1, MaxInt);
  Result := NewText;
  if TailText <> '' then
    Result := TPath.Combine(Result, TailText);
  Result := ExcludeTrailingPathDelimiter(Result);
end;

function TryExtractLegacyRoot(const PathValue, AnchorName: string; out LegacyRoot: string): Boolean;
var
  PathText: string;
  LowerPathText: string;
  AnchorToken: string;
  AnchorPos: Integer;
begin
  Result := False;
  LegacyRoot := '';
  if (PathValue = '') or not TPath.IsPathRooted(PathValue) then
    Exit;

  PathText := ExcludeTrailingPathDelimiter(NormalizePortablePath(PathValue));
  if SameText(ExtractFileName(PathText), AnchorName) then
  begin
    LegacyRoot := ExtractFileDir(PathText);
    Exit(LegacyRoot <> '');
  end;

  LowerPathText := LowerCase(PathText);
  AnchorToken := '\' + LowerCase(AnchorName) + '\';
  AnchorPos := Pos(AnchorToken, LowerPathText);
  if AnchorPos <= 0 then
    Exit;

  LegacyRoot := Copy(PathText, 1, AnchorPos - 1);
  Result := LegacyRoot <> '';
end;

function ReadStringOrDefault(const Json: TJSONObject; const Name, DefaultValue: string): string;
var
  Value: TJSONValue;
begin
  Value := Json.GetValue(Name);
  if Assigned(Value) then
    Result := Value.Value
  else
    Result := DefaultValue;
end;

function ReadIntegerOrDefault(const Json: TJSONObject; const Name: string; DefaultValue: Integer): Integer;
var
  Value: TJSONValue;
begin
  Value := Json.GetValue(Name);
  if Assigned(Value) and TryStrToInt(Value.Value, Result) then
    Exit;
  Result := DefaultValue;
end;

function ReadBooleanOrDefault(const Json: TJSONObject; const Name: string; DefaultValue: Boolean): Boolean;
var
  Value: TJSONValue;
begin
  Value := Json.GetValue(Name);
  if Assigned(Value) and SameText(Value.Value, 'true') then
    Exit(True);
  if Assigned(Value) and SameText(Value.Value, 'false') then
    Exit(False);
  Result := DefaultValue;
end;

function ReadConfigVersionOrDefault(const Json: TJSONObject; DefaultValue: Integer): Integer;
begin
  Result := ReadIntegerOrDefault(Json, 'configVersion', DefaultValue);
end;

function ReadObjectOrNil(const Json: TJSONObject; const Name: string): TJSONObject;
var
  Value: TJSONValue;
begin
  Result := nil;
  Value := Json.GetValue(Name);
  if Value is TJSONObject then
    Result := TJSONObject(Value);
end;

function ReadArrayOrNil(const Json: TJSONObject; const Name: string): TJSONArray;
var
  Value: TJSONValue;
begin
  Result := nil;
  Value := Json.GetValue(Name);
  if Value is TJSONArray then
    Result := TJSONArray(Value);
end;

function NormalizeSyncProfile(const Profile: TSyncProfile): TSyncProfile;
var
  I: Integer;
  NormalizedExcludes: TList<string>;
  Value: string;
begin
  Result := Profile;
  Result.Name := Trim(Profile.Name);
  Result.Backend := LowerCase(Trim(Profile.Backend));
  Result.Direction := LowerCase(Trim(Profile.Direction));
  Result.ExecutablePath := Trim(Profile.ExecutablePath);
  Result.DefaultTestVHost := Trim(Profile.DefaultTestVHost);
  Result.PreSyncCommand := Trim(Profile.PreSyncCommand);
  Result.PostSyncCommand := Trim(Profile.PostSyncCommand);
  Result.RemoteName := Trim(Profile.RemoteName);
  Result.RemotePath := Trim(Profile.RemotePath);
  Result.LocalPath := Trim(Profile.LocalPath);
  Result.WorkingDirectory := Trim(Profile.WorkingDirectory);

  NormalizedExcludes := TList<string>.Create;
  try
    for I := Low(Profile.Excludes) to High(Profile.Excludes) do
    begin
      Value := Trim(Profile.Excludes[I]);
      if Value <> '' then
        NormalizedExcludes.Add(Value);
    end;
    Result.Excludes := NormalizedExcludes.ToArray;
  finally
    NormalizedExcludes.Free;
  end;
end;

constructor TUniWampConfig.Create;
begin
  inherited Create;
  FVHosts := TList<TVHostEntry>.Create;
  FApacheModules := TList<string>.Create;
  FPhpVersions := TList<string>.Create;
  FPhpExtensions := TList<string>.Create;
  FPhpSettings := TDictionary<string, string>.Create;
  FNodeVersions := TList<string>.Create;
  FSyncProfiles := TList<TSyncProfile>.Create;
end;

destructor TUniWampConfig.Destroy;
begin
  FSyncProfiles.Free;
  FNodeVersions.Free;
  FPhpSettings.Free;
  FPhpExtensions.Free;
  FPhpVersions.Free;
  FApacheModules.Free;
  FVHosts.Free;
  inherited;
end;

procedure TUniWampConfig.SetDefaults(const Paths: TAppPaths);
const
  DefaultApacheModules: array[0..18] of string = (
    'mod_access_compat.so',
    'mod_alias.so',
    'mod_auth_basic.so',
    'mod_authn_core.so',
    'mod_authn_file.so',
    'mod_authz_core.so',
    'mod_authz_host.so',
    'mod_authz_user.so',
    'mod_dir.so',
    'mod_env.so',
    'mod_headers.so',
    'mod_include.so',
    'mod_log_config.so',
    'mod_mime.so',
    'mod_rewrite.so',
    'mod_setenvif.so',
    'mod_ssl.so',
    'mod_socache_shmcb.so',
    'mod_unixd.so'
  );
  DefaultPhpExtensions: array[0..14] of string = (
    'php_bz2.dll',
    'php_curl.dll',
    'php_exif.dll',
    'php_fileinfo.dll',
    'php_gd.dll',
    'php_gettext.dll',
    'php_intl.dll',
    'php_mbstring.dll',
    'php_mysqli.dll',
    'php_opcache.dll',
    'php_openssl.dll',
    'php_pdo_mysql.dll',
    'php_pdo_sqlite.dll',
    'php_sqlite3.dll',
    'php_zip.dll'
  );
var
  Item: string;
  procedure SetPhpSettingDefault(const Name, Value: string);
  begin
    FPhpSettings.AddOrSetValue(Name, Value);
  end;
begin
  HttpPort := 8080;
  HttpsPort := 8443;
  DatabasePort := 3307;
  HostName := 'localhost';
  DocumentRoot := Paths.WwwDir;
  SelectedPhpVersion := 'php83';
  SelectedNodeVersion := '';
  PhpProfile := 'development';
  EnableSsl := False;
  StartAllOnLaunch := False;
  OpenDashboardAfterStart := True;
  ConfirmVHostDelete := True;
  TerminalExePath := 'bin\cmder\Cmder.exe';
  ApachePid := 0;
  MariaDbPid := 0;
  ApacheRunning := False;
  MariaDbRunning := False;
  LastApacheError := '';
  LastMariaDbError := '';
  LastHostsSyncStatus := 'Hosts status unknown';
  LastMigrationMessage := '';
  LastSyncUploadProfile := '';
  LastSyncDownloadProfile := '';
  MariaDbRootPassword := '';
  ThemeStyleName := '';
  FVHosts.Clear;
  FSyncProfiles.Clear;
  FApacheModules.Clear;
  for Item in DefaultApacheModules do
    FApacheModules.Add(Item);
  FPhpVersions.Clear;
  FPhpVersions.Add('php83');
  FPhpVersions.Add('php84');
  FPhpExtensions.Clear;
  for Item in DefaultPhpExtensions do
    FPhpExtensions.Add(Item);

  FPhpSettings.Clear;
  SetPhpSettingDefault('display_errors', 'On');
  SetPhpSettingDefault('error_reporting', 'E_ALL');
  SetPhpSettingDefault('log_errors', 'On');
  SetPhpSettingDefault('short_open_tag', 'Off');
  SetPhpSettingDefault('expose_php', 'Off');
  SetPhpSettingDefault('memory_limit', '256M');
  SetPhpSettingDefault('upload_max_filesize', '32M');
  SetPhpSettingDefault('post_max_size', '32M');
  SetPhpSettingDefault('max_execution_time', '120');
  SetPhpSettingDefault('max_input_vars', '3000');
end;

function TUniWampConfig.LoadOrCreate(const Paths: TAppPaths): Boolean;
const
  CurrentConfigVersion = 1;
var
  JsonText: string;
  Root: TJSONObject;
  PhpArray: TJSONArray;
  PhpExtensionsArray: TJSONArray;
  PhpSettingsObject: TJSONObject;
  VHostArray: TJSONArray;
  SyncProfilesArray: TJSONArray;
  ExcludesArray: TJSONArray;
  I: Integer;
  J: Integer;
  Entry: TVHostEntry;
  SyncProfile: TSyncProfile;
  Obj: TJSONObject;
  OldAppRoot: string;
  LegacyRootFound: Boolean;
  Migrated: Boolean;
  MigratedCount: Integer;
  OriginalValue: string;
  UpdatedValue: string;
  InvalidConfigFile: string;
  SecretError: string;
  LegacyPasswordValue: TJSONValue;
begin
  LastMigrationMessage := '';
  SetDefaults(Paths);
  if not FileExists(Paths.AppConfigFile) then
  begin
    Save(Paths);
    Result := True;
    Exit;
  end;

  InvalidConfigFile := Paths.AppConfigFile + '.invalid';
  try
    JsonText := TFile.ReadAllText(Paths.AppConfigFile, TEncoding.UTF8);
    Root := TJSONObject.ParseJSONValue(JsonText) as TJSONObject;
  except
    on E: Exception do
    begin
      TFile.Copy(Paths.AppConfigFile, InvalidConfigFile, True);
      LastMigrationMessage := Format(
        'Configuration was unreadable and has been backed up to %s: %s',
        [InvalidConfigFile, E.Message]);
      Save(Paths);
      Result := True;
      Exit;
    end;
  end;
  if not Assigned(Root) then
  begin
    TFile.Copy(Paths.AppConfigFile, InvalidConfigFile, True);
    LastMigrationMessage := Format(
      'Configuration was invalid JSON and has been backed up to %s.',
      [InvalidConfigFile]);
    Save(Paths);
    Result := True;
    Exit;
  end;
  try
    HttpPort := ReadIntegerOrDefault(Root, 'httpPort', HttpPort);
    HttpsPort := ReadIntegerOrDefault(Root, 'httpsPort', HttpsPort);
    DatabasePort := ReadIntegerOrDefault(Root, 'databasePort', DatabasePort);
    HostName := ReadStringOrDefault(Root, 'hostName', HostName);
    DocumentRoot := ReadStringOrDefault(Root, 'documentRoot', DocumentRoot);
    SelectedPhpVersion := ReadStringOrDefault(Root, 'selectedPhpVersion', SelectedPhpVersion);
    SelectedNodeVersion := ReadStringOrDefault(Root, 'selectedNodeVersion', SelectedNodeVersion);
    TerminalExePath := ReadStringOrDefault(Root, 'terminalExePath', TerminalExePath);
    PhpProfile := ReadStringOrDefault(Root, 'phpProfile', PhpProfile);
    ThemeStyleName := ReadStringOrDefault(Root, 'themeStyleName', ThemeStyleName);
    EnableSsl := ReadBooleanOrDefault(Root, 'enableSsl', EnableSsl);
    StartAllOnLaunch := ReadBooleanOrDefault(Root, 'startAllOnLaunch', StartAllOnLaunch);
    OpenDashboardAfterStart := ReadBooleanOrDefault(Root, 'openDashboardAfterStart', OpenDashboardAfterStart);
    ConfirmVHostDelete := ReadBooleanOrDefault(Root, 'confirmVHostDelete', ConfirmVHostDelete);
    ApachePid := ReadIntegerOrDefault(Root, 'apachePid', ApachePid);
    MariaDbPid := ReadIntegerOrDefault(Root, 'mariaDbPid', MariaDbPid);
    ApacheRunning := ReadBooleanOrDefault(Root, 'apacheRunning', ApacheRunning);
    MariaDbRunning := ReadBooleanOrDefault(Root, 'mariaDbRunning', MariaDbRunning);
    LastApacheError := ReadStringOrDefault(Root, 'lastApacheError', '');
    LastMariaDbError := ReadStringOrDefault(Root, 'lastMariaDbError', '');
    LastHostsSyncStatus := ReadStringOrDefault(Root, 'lastHostsSyncStatus', LastHostsSyncStatus);
    LastSyncUploadProfile := ReadStringOrDefault(Root, 'lastSyncUploadProfile', '');
    LastSyncDownloadProfile := ReadStringOrDefault(Root, 'lastSyncDownloadProfile', '');
    MariaDbRootPassword := ReadStringOrDefault(Root, 'mariaDbRootPassword', MariaDbRootPassword);
    LegacyPasswordValue := Root.GetValue('mariaDbRootPassword');

  var ApacheModulesArray := ReadArrayOrNil(Root, 'apacheEnabledModules');
    if Assigned(ApacheModulesArray) then
    begin
      FApacheModules.Clear;
      for I := 0 to ApacheModulesArray.Count - 1 do
        if ApacheModulesArray.Items[I].Value <> '' then
          FApacheModules.Add(ApacheModulesArray.Items[I].Value);
    end;

    FPhpVersions.Clear;
    PhpArray := ReadArrayOrNil(Root, 'phpVersions');
    if Assigned(PhpArray) then
      for I := 0 to PhpArray.Count - 1 do
        FPhpVersions.Add(PhpArray.Items[I].Value);

    PhpExtensionsArray := ReadArrayOrNil(Root, 'phpEnabledExtensions');
    if Assigned(PhpExtensionsArray) then
    begin
      FPhpExtensions.Clear;
      for I := 0 to PhpExtensionsArray.Count - 1 do
        if PhpExtensionsArray.Items[I].Value <> '' then
          FPhpExtensions.Add(PhpExtensionsArray.Items[I].Value);
    end;

    PhpSettingsObject := ReadObjectOrNil(Root, 'phpSettings');
    if Assigned(PhpSettingsObject) then
    begin
      for I := 0 to PhpSettingsObject.Count - 1 do
        FPhpSettings.AddOrSetValue(PhpSettingsObject.Pairs[I].JsonString.Value, PhpSettingsObject.Pairs[I].JsonValue.Value);
    end;

    FVHosts.Clear;
    VHostArray := Root.GetValue<TJSONArray>('vhosts');
    if Assigned(VHostArray) then
      for I := 0 to VHostArray.Count - 1 do
      begin
        Obj := VHostArray.Items[I] as TJSONObject;
        if not Assigned(Obj) then
          Continue;
        Entry.ServerName := ReadStringOrDefault(Obj, 'serverName', '');
        Entry.ServerAliases := ReadStringOrDefault(Obj, 'serverAliases', '');
        Entry.DocumentRoot := ReadStringOrDefault(Obj, 'documentRoot', '');
        Entry.EnableSsl := ReadBooleanOrDefault(Obj, 'enableSsl', False);
        Entry.SslCertFile := ReadStringOrDefault(Obj, 'sslCertFile', '');
        Entry.SslKeyFile := ReadStringOrDefault(Obj, 'sslKeyFile', '');
        Entry.PinnedSyncUploadProfile := ReadStringOrDefault(Obj, 'pinnedSyncUploadProfile', '');
        Entry.PinnedSyncDownloadProfile := ReadStringOrDefault(Obj, 'pinnedSyncDownloadProfile', '');
        if Entry.ServerName <> '' then
          FVHosts.Add(Entry);
      end;

    FSyncProfiles.Clear;
    SyncProfilesArray := ReadArrayOrNil(Root, 'syncProfiles');
    if Assigned(SyncProfilesArray) then
      for I := 0 to SyncProfilesArray.Count - 1 do
      begin
        Obj := SyncProfilesArray.Items[I] as TJSONObject;
        if not Assigned(Obj) then
          Continue;
        SyncProfile.Name := ReadStringOrDefault(Obj, 'name', '');
        SyncProfile.Backend := ReadStringOrDefault(Obj, 'backend', 'rclone');
        SyncProfile.Direction := ReadStringOrDefault(Obj, 'direction', 'upload');
        SyncProfile.ExecutablePath := ReadStringOrDefault(Obj, 'executablePath', '');
        SyncProfile.DefaultTestVHost := ReadStringOrDefault(Obj, 'defaultTestVHost', '');
        SyncProfile.PreSyncCommand := ReadStringOrDefault(Obj, 'preSyncCommand', '');
        SyncProfile.PostSyncCommand := ReadStringOrDefault(Obj, 'postSyncCommand', '');
        SyncProfile.RemoteName := ReadStringOrDefault(Obj, 'remoteName', '');
        SyncProfile.RemotePath := ReadStringOrDefault(Obj, 'remotePath', '');
        SyncProfile.LocalPath := ReadStringOrDefault(Obj, 'localPath', '');
        SyncProfile.WorkingDirectory := ReadStringOrDefault(Obj, 'workingDirectory', '');
        SyncProfile.DeleteEnabled := ReadBooleanOrDefault(Obj, 'deleteEnabled', False);
        SyncProfile.DryRunByDefault := ReadBooleanOrDefault(Obj, 'dryRunByDefault', True);
        SetLength(SyncProfile.Excludes, 0);
        ExcludesArray := ReadArrayOrNil(Obj, 'excludes');
        if Assigned(ExcludesArray) then
        begin
          SetLength(SyncProfile.Excludes, ExcludesArray.Count);
          for J := 0 to ExcludesArray.Count - 1 do
            SyncProfile.Excludes[J] := ExcludesArray.Items[J].Value;
        end;
        SyncProfile := NormalizeSyncProfile(SyncProfile);
        if SyncProfile.Name <> '' then
          FSyncProfiles.Add(SyncProfile);
      end;

    Migrated := False;
    MigratedCount := 0;

    if ReadConfigVersionOrDefault(Root, 0) <> CurrentConfigVersion then
    begin
      Inc(MigratedCount);
      Migrated := True;
    end;
    if Assigned(LegacyPasswordValue) then
    begin
      Inc(MigratedCount);
      Migrated := True;
    end;

    if not IsValidTcpPort(HttpPort) then
    begin
      HttpPort := 8080;
      Inc(MigratedCount);
      Migrated := True;
    end;
    if not IsValidTcpPort(HttpsPort) or (HttpsPort = HttpPort) then
    begin
      HttpsPort := 8443;
      if HttpsPort = HttpPort then
        HttpsPort := 8444;
      Inc(MigratedCount);
      Migrated := True;
    end;
    if not IsValidTcpPort(DatabasePort) or (DatabasePort = HttpPort) or
      (DatabasePort = HttpsPort) then
    begin
      DatabasePort := 3307;
      if (DatabasePort = HttpPort) or (DatabasePort = HttpsPort) then
        DatabasePort := 3308;
      Inc(MigratedCount);
      Migrated := True;
    end;
    if Trim(HostName) = '' then
    begin
      HostName := 'localhost';
      Inc(MigratedCount);
      Migrated := True;
    end;
    if Trim(DocumentRoot) = '' then
    begin
      DocumentRoot := Paths.WwwDir;
      Inc(MigratedCount);
      Migrated := True;
    end;

    if (DocumentRoot <> '') and not TPath.IsPathRooted(DocumentRoot) then
    begin
      DocumentRoot := ResolveConfiguredPath(DocumentRoot, Paths.AppRoot);
      Inc(MigratedCount);
      Migrated := True;
    end;

    for I := 0 to FVHosts.Count - 1 do
    begin
      Entry := FVHosts[I];
      if (Entry.DocumentRoot <> '') and not TPath.IsPathRooted(Entry.DocumentRoot) then
      begin
        Entry.DocumentRoot := ResolveConfiguredPath(Entry.DocumentRoot, Paths.AppRoot);
        Inc(MigratedCount);
        Migrated := True;
      end;
      if (Entry.SslCertFile <> '') and not TPath.IsPathRooted(Entry.SslCertFile) then
      begin
        Entry.SslCertFile := ResolveConfiguredPath(Entry.SslCertFile, Paths.AppRoot);
        Inc(MigratedCount);
        Migrated := True;
      end;
      if (Entry.SslKeyFile <> '') and not TPath.IsPathRooted(Entry.SslKeyFile) then
      begin
        Entry.SslKeyFile := ResolveConfiguredPath(Entry.SslKeyFile, Paths.AppRoot);
        Inc(MigratedCount);
        Migrated := True;
      end;
      FVHosts[I] := Entry;
    end;

    for I := 0 to FSyncProfiles.Count - 1 do
    begin
      SyncProfile := FSyncProfiles[I];
      if (SyncProfile.LocalPath <> '') and not TPath.IsPathRooted(SyncProfile.LocalPath) then
      begin
        SyncProfile.LocalPath := ResolveConfiguredPath(SyncProfile.LocalPath, Paths.AppRoot);
        Inc(MigratedCount);
        Migrated := True;
      end;
      if (SyncProfile.WorkingDirectory <> '') and not TPath.IsPathRooted(SyncProfile.WorkingDirectory) then
      begin
        SyncProfile.WorkingDirectory := ResolveConfiguredPath(SyncProfile.WorkingDirectory, Paths.AppRoot);
        Inc(MigratedCount);
        Migrated := True;
      end;
      if (SyncProfile.ExecutablePath <> '') and not TPath.IsPathRooted(SyncProfile.ExecutablePath) and
        (Pos('\', SyncProfile.ExecutablePath) > 0) then
      begin
        SyncProfile.ExecutablePath := ResolveConfiguredPath(SyncProfile.ExecutablePath, Paths.AppRoot);
        Inc(MigratedCount);
        Migrated := True;
      end;
      FSyncProfiles[I] := NormalizeSyncProfile(SyncProfile);
    end;

    OldAppRoot := '';
    LegacyRootFound := False;
    if TryExtractLegacyRoot(DocumentRoot, 'www', OldAppRoot) and
      not SameText(ExcludeTrailingPathDelimiter(NormalizePortablePath(OldAppRoot)),
        ExcludeTrailingPathDelimiter(NormalizePortablePath(Paths.AppRoot))) then
      LegacyRootFound := True
    else if TryExtractLegacyRoot(TerminalExePath, 'bin', OldAppRoot) and
      not SameText(ExcludeTrailingPathDelimiter(NormalizePortablePath(OldAppRoot)),
        ExcludeTrailingPathDelimiter(NormalizePortablePath(Paths.AppRoot))) then
      LegacyRootFound := True
    else
    begin
      for I := 0 to FVHosts.Count - 1 do
      begin
        Entry := FVHosts[I];
        if TryExtractLegacyRoot(Entry.DocumentRoot, 'www', OldAppRoot) or
           TryExtractLegacyRoot(Entry.SslCertFile, 'ssl', OldAppRoot) or
           TryExtractLegacyRoot(Entry.SslKeyFile, 'ssl', OldAppRoot) then
        begin
          LegacyRootFound := True;
          Break;
        end;
        OldAppRoot := '';
      end;
    end;

    if LegacyRootFound and (OldAppRoot <> '') and
      not SameText(ExcludeTrailingPathDelimiter(NormalizePortablePath(OldAppRoot)),
        ExcludeTrailingPathDelimiter(NormalizePortablePath(Paths.AppRoot))) then
    begin

      OriginalValue := DocumentRoot;
      UpdatedValue := ReplacePathPrefix(DocumentRoot, OldAppRoot, Paths.AppRoot);
      if not SameText(NormalizePortablePath(OriginalValue), NormalizePortablePath(UpdatedValue)) then
      begin
        DocumentRoot := UpdatedValue;
        Inc(MigratedCount);
        Migrated := True;
      end;

      for I := 0 to FVHosts.Count - 1 do
      begin
        Entry := FVHosts[I];
        OriginalValue := Entry.DocumentRoot;
        UpdatedValue := ReplacePathPrefix(Entry.DocumentRoot, OldAppRoot, Paths.AppRoot);
        if not SameText(NormalizePortablePath(OriginalValue), NormalizePortablePath(UpdatedValue)) then
        begin
          Entry.DocumentRoot := UpdatedValue;
          Inc(MigratedCount);
          Migrated := True;
        end;

        OriginalValue := Entry.SslCertFile;
        UpdatedValue := ReplacePathPrefix(Entry.SslCertFile, OldAppRoot, Paths.AppRoot);
        if not SameText(NormalizePortablePath(OriginalValue), NormalizePortablePath(UpdatedValue)) then
        begin
          Entry.SslCertFile := UpdatedValue;
          Inc(MigratedCount);
          Migrated := True;
        end;

        OriginalValue := Entry.SslKeyFile;
        UpdatedValue := ReplacePathPrefix(Entry.SslKeyFile, OldAppRoot, Paths.AppRoot);
        if not SameText(NormalizePortablePath(OriginalValue), NormalizePortablePath(UpdatedValue)) then
        begin
          Entry.SslKeyFile := UpdatedValue;
          Inc(MigratedCount);
          Migrated := True;
        end;
        FVHosts[I] := Entry;
      end;

      OriginalValue := TerminalExePath;
      UpdatedValue := ReplacePathPrefix(TerminalExePath, OldAppRoot, Paths.AppRoot);
      if not SameText(NormalizePortablePath(OriginalValue), NormalizePortablePath(UpdatedValue)) then
      begin
        TerminalExePath := UpdatedValue;
        Inc(MigratedCount);
        Migrated := True;
      end;

      for I := 0 to FSyncProfiles.Count - 1 do
      begin
        SyncProfile := FSyncProfiles[I];

        OriginalValue := SyncProfile.LocalPath;
        UpdatedValue := ReplacePathPrefix(SyncProfile.LocalPath, OldAppRoot, Paths.AppRoot);
        if not SameText(NormalizePortablePath(OriginalValue), NormalizePortablePath(UpdatedValue)) then
        begin
          SyncProfile.LocalPath := UpdatedValue;
          Inc(MigratedCount);
          Migrated := True;
        end;

        OriginalValue := SyncProfile.WorkingDirectory;
        UpdatedValue := ReplacePathPrefix(SyncProfile.WorkingDirectory, OldAppRoot, Paths.AppRoot);
        if not SameText(NormalizePortablePath(OriginalValue), NormalizePortablePath(UpdatedValue)) then
        begin
          SyncProfile.WorkingDirectory := UpdatedValue;
          Inc(MigratedCount);
          Migrated := True;
        end;

        OriginalValue := SyncProfile.ExecutablePath;
        UpdatedValue := ReplacePathPrefix(SyncProfile.ExecutablePath, OldAppRoot, Paths.AppRoot);
        if not SameText(NormalizePortablePath(OriginalValue), NormalizePortablePath(UpdatedValue)) then
        begin
          SyncProfile.ExecutablePath := UpdatedValue;
          Inc(MigratedCount);
          Migrated := True;
        end;

        FSyncProfiles[I] := NormalizeSyncProfile(SyncProfile);
      end;

      if Migrated then
        LastMigrationMessage := Format(
          'Migrated %d path(s) from %s to %s.',
          [MigratedCount, OldAppRoot, Paths.AppRoot]);
    end;

    if Migrated then
    begin
      if LastMigrationMessage = '' then
        LastMigrationMessage := Format(
          'Configuration was updated for the current UniWamp installation at %s.',
          [Paths.AppRoot]);
      Save(Paths);
    end;
    if Assigned(LegacyPasswordValue) and (MariaDbRootPassword <> '') then
    begin
      if SaveMariaDbRootPassword(Paths, MariaDbRootPassword, SecretError) then
      begin
        MariaDbRootPassword := '';
        LastMigrationMessage := 'Migrated MariaDB root password into protected local storage.';
        Save(Paths);
      end;
    end;
    if MariaDbRootPassword = '' then
      MariaDbRootPassword := LoadMariaDbRootPassword(Paths);
    Result := Migrated;
  finally
    Root.Free;
  end;
end;

procedure TUniWampConfig.Save(const Paths: TAppPaths);
var
  Root: TJSONObject;
  PhpArray: TJSONArray;
  PhpExtensionsArray: TJSONArray;
  PhpSettingsObject: TJSONObject;
  VHostArray: TJSONArray;
  SyncProfilesArray: TJSONArray;
  ExcludesArray: TJSONArray;
  Item: string;
  ExcludePattern: string;
  Entry: TVHostEntry;
  SyncProfile: TSyncProfile;
  Obj: TJSONObject;
  JsonText: string;
  TempFile: string;
  BackupFile: string;
begin
  Root := TJSONObject.Create;
  try
    Root.AddPair('httpPort', TJSONNumber.Create(HttpPort));
    Root.AddPair('httpsPort', TJSONNumber.Create(HttpsPort));
    Root.AddPair('databasePort', TJSONNumber.Create(DatabasePort));
    Root.AddPair('hostName', HostName);
    Root.AddPair('configVersion', TJSONNumber.Create(1));
    Root.AddPair('documentRoot', DocumentRoot);
    Root.AddPair('selectedPhpVersion', SelectedPhpVersion);
    Root.AddPair('selectedNodeVersion', SelectedNodeVersion);
    Root.AddPair('terminalExePath', TerminalExePath);
    Root.AddPair('phpProfile', PhpProfile);
    Root.AddPair('themeStyleName', ThemeStyleName);
    Root.AddPair('enableSsl', TJSONBool.Create(EnableSsl));
    Root.AddPair('startAllOnLaunch', TJSONBool.Create(StartAllOnLaunch));
    Root.AddPair('openDashboardAfterStart', TJSONBool.Create(OpenDashboardAfterStart));
    Root.AddPair('confirmVHostDelete', TJSONBool.Create(ConfirmVHostDelete));
    Root.AddPair('apachePid', TJSONNumber.Create(ApachePid));
    Root.AddPair('mariaDbPid', TJSONNumber.Create(MariaDbPid));
    Root.AddPair('apacheRunning', TJSONBool.Create(ApacheRunning));
    Root.AddPair('mariaDbRunning', TJSONBool.Create(MariaDbRunning));
    Root.AddPair('lastApacheError', LastApacheError);
    Root.AddPair('lastMariaDbError', LastMariaDbError);
    Root.AddPair('lastHostsSyncStatus', LastHostsSyncStatus);
    Root.AddPair('lastSyncUploadProfile', LastSyncUploadProfile);
    Root.AddPair('lastSyncDownloadProfile', LastSyncDownloadProfile);

  var ApacheModulesArray := TJSONArray.Create;
    for Item in FApacheModules do
      ApacheModulesArray.Add(Item);
    Root.AddPair('apacheEnabledModules', ApacheModulesArray);

    PhpArray := TJSONArray.Create;
    for Item in FPhpVersions do
      PhpArray.Add(Item);
    Root.AddPair('phpVersions', PhpArray);

    PhpExtensionsArray := TJSONArray.Create;
    for Item in FPhpExtensions do
      PhpExtensionsArray.Add(Item);
    Root.AddPair('phpEnabledExtensions', PhpExtensionsArray);

    PhpSettingsObject := TJSONObject.Create;
    for Item in FPhpSettings.Keys do
      PhpSettingsObject.AddPair(Item, FPhpSettings.Items[Item]);
    Root.AddPair('phpSettings', PhpSettingsObject);

    VHostArray := TJSONArray.Create;
    for Entry in FVHosts do
    begin
      Obj := TJSONObject.Create;
      Obj.AddPair('serverName', Entry.ServerName);
      Obj.AddPair('serverAliases', Entry.ServerAliases);
      Obj.AddPair('documentRoot', Entry.DocumentRoot);
      Obj.AddPair('enableSsl', TJSONBool.Create(Entry.EnableSsl));
      Obj.AddPair('sslCertFile', Entry.SslCertFile);
      Obj.AddPair('sslKeyFile', Entry.SslKeyFile);
      Obj.AddPair('pinnedSyncUploadProfile', Entry.PinnedSyncUploadProfile);
      Obj.AddPair('pinnedSyncDownloadProfile', Entry.PinnedSyncDownloadProfile);
      VHostArray.Add(Obj);
    end;
    Root.AddPair('vhosts', VHostArray);

    SyncProfilesArray := TJSONArray.Create;
    for SyncProfile in FSyncProfiles do
    begin
      Obj := TJSONObject.Create;
      Obj.AddPair('name', SyncProfile.Name);
      Obj.AddPair('backend', SyncProfile.Backend);
      Obj.AddPair('direction', SyncProfile.Direction);
      Obj.AddPair('executablePath', SyncProfile.ExecutablePath);
      Obj.AddPair('defaultTestVHost', SyncProfile.DefaultTestVHost);
      Obj.AddPair('preSyncCommand', SyncProfile.PreSyncCommand);
      Obj.AddPair('postSyncCommand', SyncProfile.PostSyncCommand);
      Obj.AddPair('remoteName', SyncProfile.RemoteName);
      Obj.AddPair('remotePath', SyncProfile.RemotePath);
      Obj.AddPair('localPath', SyncProfile.LocalPath);
      Obj.AddPair('workingDirectory', SyncProfile.WorkingDirectory);
      Obj.AddPair('deleteEnabled', TJSONBool.Create(SyncProfile.DeleteEnabled));
      Obj.AddPair('dryRunByDefault', TJSONBool.Create(SyncProfile.DryRunByDefault));
      ExcludesArray := TJSONArray.Create;
      for ExcludePattern in SyncProfile.Excludes do
        ExcludesArray.Add(ExcludePattern);
      Obj.AddPair('excludes', ExcludesArray);
      SyncProfilesArray.Add(Obj);
    end;
    Root.AddPair('syncProfiles', SyncProfilesArray);

    JsonText := Root.Format(2);
    TempFile := Paths.AppConfigFile + '.tmp';
    BackupFile := Paths.AppConfigFile + '.bak';
    TFile.WriteAllText(TempFile, JsonText, TEncoding.UTF8);
    if FileExists(Paths.AppConfigFile) then
    begin
      TFile.Copy(Paths.AppConfigFile, BackupFile, True);
      TFile.Delete(Paths.AppConfigFile);
      TFile.Move(TempFile, Paths.AppConfigFile);
    end
    else
      TFile.Move(TempFile, Paths.AppConfigFile);
  finally
    Root.Free;
  end;
end;

procedure TUniWampConfig.ReplacePhpVersions(const Versions: TArray<string>);
var
  Item: string;
begin
  FPhpVersions.Clear;
  for Item in Versions do
    if (Trim(Item) <> '') and (FPhpVersions.IndexOf(Item) < 0) then
      FPhpVersions.Add(Item);
end;

procedure TUniWampConfig.ReplaceApacheModules(const Modules: TArray<string>);
var
  Item: string;
begin
  FApacheModules.Clear;
  for Item in Modules do
    if (Trim(Item) <> '') and (FApacheModules.IndexOf(Item) < 0) then
      FApacheModules.Add(Item);
end;

function TUniWampConfig.ApacheModules: TArray<string>;
begin
  Result := FApacheModules.ToArray;
end;

function TUniWampConfig.PhpVersions: TArray<string>;
begin
  Result := FPhpVersions.ToArray;
end;

procedure TUniWampConfig.ReplacePhpExtensions(const Extensions: TArray<string>);
var
  Item: string;
begin
  FPhpExtensions.Clear;
  for Item in Extensions do
    if (Trim(Item) <> '') and (FPhpExtensions.IndexOf(Item) < 0) then
      FPhpExtensions.Add(Item);
end;

function TUniWampConfig.PhpExtensions: TArray<string>;
begin
  Result := FPhpExtensions.ToArray;
end;

function TUniWampConfig.PhpSettingValue(const Name, DefaultValue: string): string;
begin
  if not FPhpSettings.TryGetValue(Name, Result) then
    Result := DefaultValue;
end;

procedure TUniWampConfig.SetPhpSettingValue(const Name, Value: string);
begin
  if Trim(Name) = '' then
    Exit;
  FPhpSettings.AddOrSetValue(Name, Value);
end;

procedure TUniWampConfig.ReplaceNodeVersions(const Versions: TArray<string>);
begin
  FNodeVersions.Clear;
  FNodeVersions.AddRange(Versions);
end;

function TUniWampConfig.NodeVersions: TArray<string>;
begin
  Result := FNodeVersions.ToArray;
end;

function TUniWampConfig.SyncProfiles: TArray<TSyncProfile>;
begin
  Result := FSyncProfiles.ToArray;
end;

procedure TUniWampConfig.ReplaceSyncProfiles(const Items: TArray<TSyncProfile>);
var
  I: Integer;
  Profile: TSyncProfile;
begin
  FSyncProfiles.Clear;
  for I := Low(Items) to High(Items) do
  begin
    Profile := NormalizeSyncProfile(Items[I]);
    if Profile.Name <> '' then
      FSyncProfiles.Add(Profile);
  end;
end;

procedure TUniWampConfig.AddOrUpdateSyncProfile(const Item: TSyncProfile);
var
  I: Integer;
  Profile: TSyncProfile;
begin
  Profile := NormalizeSyncProfile(Item);
  if Profile.Name = '' then
    Exit;
  for I := 0 to FSyncProfiles.Count - 1 do
    if SameText(FSyncProfiles[I].Name, Profile.Name) then
    begin
      FSyncProfiles[I] := Profile;
      Exit;
    end;
  FSyncProfiles.Add(Profile);
end;

procedure TUniWampConfig.DeleteSyncProfile(const Name: string);
var
  I: Integer;
begin
  for I := FSyncProfiles.Count - 1 downto 0 do
    if SameText(FSyncProfiles[I].Name, Name) then
      FSyncProfiles.Delete(I);
end;

function TUniWampConfig.VHosts: TArray<TVHostEntry>;
begin
  Result := FVHosts.ToArray;
end;

procedure TUniWampConfig.ReplaceVHosts(const Items: TArray<TVHostEntry>);
var
  Entry: TVHostEntry;
begin
  FVHosts.Clear;
  for Entry in Items do
    FVHosts.Add(Entry);
end;

procedure TUniWampConfig.AddOrUpdateVHost(const Item: TVHostEntry);
var
  I: Integer;
begin
  for I := 0 to FVHosts.Count - 1 do
    if SameText(FVHosts[I].ServerName, Item.ServerName) then
    begin
      FVHosts[I] := Item;
      Exit;
    end;
  FVHosts.Add(Item);
end;

procedure TUniWampConfig.DeleteVHost(const ServerName: string);
var
  I: Integer;
begin
  for I := FVHosts.Count - 1 downto 0 do
    if SameText(FVHosts[I].ServerName, ServerName) then
      FVHosts.Delete(I);
end;

end.
