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
  end;

  TPhpRuntime = record
    Name: string;
    Directory: string;
  end;

  TUniWampConfig = class
  private
    FVHosts: TList<TVHostEntry>;
    FApacheModules: TList<string>;
    FPhpVersions: TList<string>;
    FPhpExtensions: TList<string>;
    FPhpSettings: TDictionary<string, string>;
    FNodeVersions: TList<string>;
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
    EnableSsl: Boolean;
    ApachePid: Cardinal;
    MariaDbPid: Cardinal;
    ApacheRunning: Boolean;
    MariaDbRunning: Boolean;
    MariaDbRootPassword: string;
    LastApacheError: string;
    LastMariaDbError: string;
    LastHostsSyncStatus: string;
    LastMigrationMessage: string;
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
    function VHosts: TArray<TVHostEntry>;
    procedure ReplaceVHosts(const Items: TArray<TVHostEntry>);
    procedure AddOrUpdateVHost(const Item: TVHostEntry);
    procedure DeleteVHost(const ServerName: string);
  end;

implementation

uses
  System.Classes,
  System.IOUtils,
  System.JSON;

function NormalizePortablePath(const PathValue: string): string;
begin
  Result := StringReplace(PathValue, '/', '\', [rfReplaceAll]);
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

constructor TUniWampConfig.Create;
begin
  inherited Create;
  FVHosts := TList<TVHostEntry>.Create;
  FApacheModules := TList<string>.Create;
  FPhpVersions := TList<string>.Create;
  FPhpExtensions := TList<string>.Create;
  FPhpSettings := TDictionary<string, string>.Create;
  FNodeVersions := TList<string>.Create;
end;

destructor TUniWampConfig.Destroy;
begin
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
  EnableSsl := True;
  TerminalExePath := 'bin\cmder\Cmder.exe';
  ApachePid := 0;
  MariaDbPid := 0;
  ApacheRunning := False;
  MariaDbRunning := False;
  LastApacheError := '';
  LastMariaDbError := '';
  LastHostsSyncStatus := 'Hosts status unknown';
  LastMigrationMessage := '';
  MariaDbRootPassword := '';
  FVHosts.Clear;
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
var
  JsonText: string;
  Root: TJSONObject;
  PhpArray: TJSONArray;
  PhpExtensionsArray: TJSONArray;
  PhpSettingsObject: TJSONObject;
  VHostArray: TJSONArray;
  I: Integer;
  Entry: TVHostEntry;
  Obj: TJSONObject;
  OldAppRoot: string;
  LegacyRootFound: Boolean;
  Migrated: Boolean;
  MigratedCount: Integer;
  OriginalValue: string;
  UpdatedValue: string;
begin
  Result := False;
  LastMigrationMessage := '';
  SetDefaults(Paths);
  if not FileExists(Paths.AppConfigFile) then
  begin
    Save(Paths);
    Result := True;
    Exit;
  end;

  JsonText := TFile.ReadAllText(Paths.AppConfigFile, TEncoding.UTF8);
  Root := TJSONObject.ParseJSONValue(JsonText) as TJSONObject;
  if not Assigned(Root) then
    Exit;
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
    EnableSsl := ReadBooleanOrDefault(Root, 'enableSsl', EnableSsl);
    ApachePid := ReadIntegerOrDefault(Root, 'apachePid', ApachePid);
    MariaDbPid := ReadIntegerOrDefault(Root, 'mariaDbPid', MariaDbPid);
    ApacheRunning := ReadBooleanOrDefault(Root, 'apacheRunning', ApacheRunning);
    MariaDbRunning := ReadBooleanOrDefault(Root, 'mariaDbRunning', MariaDbRunning);
    LastApacheError := ReadStringOrDefault(Root, 'lastApacheError', '');
    LastMariaDbError := ReadStringOrDefault(Root, 'lastMariaDbError', '');
    LastHostsSyncStatus := ReadStringOrDefault(Root, 'lastHostsSyncStatus', LastHostsSyncStatus);
    MariaDbRootPassword := ReadStringOrDefault(Root, 'mariaDbRootPassword', MariaDbRootPassword);

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
        if Entry.ServerName <> '' then
          FVHosts.Add(Entry);
      end;

    Migrated := False;
    MigratedCount := 0;
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

      if Migrated then
        LastMigrationMessage := Format(
          'Migrated %d path(s) from %s to %s.',
          [MigratedCount, OldAppRoot, Paths.AppRoot]);
    end;

    if Migrated then
    begin
      Save(Paths);
      Result := True;
    end;
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
  Item: string;
  Entry: TVHostEntry;
  Obj: TJSONObject;
begin
  Root := TJSONObject.Create;
  try
    Root.AddPair('httpPort', TJSONNumber.Create(HttpPort));
    Root.AddPair('httpsPort', TJSONNumber.Create(HttpsPort));
    Root.AddPair('databasePort', TJSONNumber.Create(DatabasePort));
    Root.AddPair('hostName', HostName);
    Root.AddPair('documentRoot', DocumentRoot);
    Root.AddPair('selectedPhpVersion', SelectedPhpVersion);
    Root.AddPair('selectedNodeVersion', SelectedNodeVersion);
    Root.AddPair('terminalExePath', TerminalExePath);
    Root.AddPair('phpProfile', PhpProfile);
    Root.AddPair('enableSsl', TJSONBool.Create(EnableSsl));
    Root.AddPair('apachePid', TJSONNumber.Create(ApachePid));
    Root.AddPair('mariaDbPid', TJSONNumber.Create(MariaDbPid));
    Root.AddPair('apacheRunning', TJSONBool.Create(ApacheRunning));
    Root.AddPair('mariaDbRunning', TJSONBool.Create(MariaDbRunning));
    Root.AddPair('lastApacheError', LastApacheError);
    Root.AddPair('lastMariaDbError', LastMariaDbError);
    Root.AddPair('lastHostsSyncStatus', LastHostsSyncStatus);
    Root.AddPair('mariaDbRootPassword', MariaDbRootPassword);

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
      VHostArray.Add(Obj);
    end;
    Root.AddPair('vhosts', VHostArray);

    TFile.WriteAllText(Paths.AppConfigFile, Root.Format(2), TEncoding.UTF8);
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
