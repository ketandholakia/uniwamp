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
  end;

implementation

uses
  System.IOUtils,
  System.SysUtils,
  Core.UniWamp.Config,
  Core.UniWamp.Paths,
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
  Result.RuntimeDir := TPath.Combine(Root, 'runtime');
  Result.ToolsDir := TPath.Combine(Result.RuntimeDir, 'tools');
  Result.ApacheDir := TPath.Combine(Result.RuntimeDir, 'apache');
  Result.ApacheBinDir := TPath.Combine(Result.ApacheDir, 'bin');
  Result.ApacheConfDir := TPath.Combine(Result.ApacheDir, 'conf');
  Result.SslDir := TPath.Combine(Root, 'ssl');
  EnsureDirectory(Result.ConfigDir);
  EnsureDirectory(Result.GeneratedConfigDir);
  EnsureDirectory(Result.TemplatesDir);
  EnsureDirectory(Result.RuntimeDir);
  EnsureDirectory(Result.ToolsDir);
  EnsureDirectory(Result.ApacheDir);
  EnsureDirectory(Result.ApacheBinDir);
  EnsureDirectory(Result.ApacheConfDir);
  EnsureDirectory(Result.SslDir);
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

initialization
  TDUnitX.RegisterTestFixture(TVHostManagerTests);

end.
