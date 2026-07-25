unit Test.UniWamp.Secrets;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TSecretsTests = class
  public
    [Test]
    procedure TestConnectionPasswordUsesConnectionProfileKey;
    [Test]
    procedure TestDeleteAllConnectionSecretsRemovesLegacyAndCurrentKeys;
  end;

implementation

uses
  System.IOUtils,
  System.SysUtils,
  Core.UniWamp.Paths,
  Core.UniWamp.Secrets;

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
end;

procedure TSecretsTests.TestConnectionPasswordUsesConnectionProfileKey;
var
  RootDir: string;
  Paths: TAppPaths;
  ErrorMessage: string;
begin
  RootDir := CreateTempRoot('secrets-connection');
  try
    Paths := BuildPaths(RootDir);

    Assert.IsTrue(SaveConnectionPassword(Paths, 'Production FTP', 'new-password', ErrorMessage), ErrorMessage);
    Assert.AreEqual('new-password', LoadConnectionPassword(Paths, 'Production FTP'),
      'Connection passwords should be read from the connection-profile key.');
    Assert.IsFalse(HasSecret(Paths, SyncPasswordKey('Production FTP')),
      'Saving a connection password should remove the legacy sync password key.');
  finally
    DeleteAllConnectionSecrets(Paths, 'Production FTP');
    TDirectory.Delete(RootDir, True);
  end;
end;

procedure TSecretsTests.TestDeleteAllConnectionSecretsRemovesLegacyAndCurrentKeys;
var
  RootDir: string;
  Paths: TAppPaths;
  ErrorMessage: string;
begin
  RootDir := CreateTempRoot('secrets-cleanup');
  try
    Paths := BuildPaths(RootDir);

    Assert.IsTrue(SaveSecret(Paths, SyncPasswordKey('Production FTP'), 'legacy-password', ErrorMessage), ErrorMessage);
    Assert.IsTrue(SaveConnectionPassword(Paths, 'Production FTP', 'current-password', ErrorMessage), ErrorMessage);
    Assert.IsTrue(SaveSecret(Paths, SyncKeyPassphraseKey('Production FTP'), 'legacy-passphrase', ErrorMessage), ErrorMessage);
    Assert.IsTrue(SaveConnectionKeyPassphrase(Paths, 'Production FTP', 'current-passphrase', ErrorMessage), ErrorMessage);

    DeleteAllConnectionSecrets(Paths, 'Production FTP');

    Assert.IsFalse(HasSecret(Paths, ConnectionPasswordKey('Production FTP')),
      'Current connection password should be removed.');
    Assert.IsFalse(HasSecret(Paths, ConnectionKeyPassphraseKey('Production FTP')),
      'Current connection key passphrase should be removed.');
    Assert.IsFalse(HasSecret(Paths, SyncPasswordKey('Production FTP')),
      'Legacy sync password should be removed.');
    Assert.IsFalse(HasSecret(Paths, SyncKeyPassphraseKey('Production FTP')),
      'Legacy sync key passphrase should be removed.');
  finally
    DeleteAllConnectionSecrets(Paths, 'Production FTP');
    TDirectory.Delete(RootDir, True);
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TSecretsTests);

end.
