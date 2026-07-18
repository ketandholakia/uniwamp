unit Core.UniWamp.BackupTypes;

interface

uses
  System.JSON,
  Core.UniWamp.Config;

type
  TBackupKind = (bkProject, bkDatabase);

  TBackupFileEntry = record
    RelativePath: string;
    Sha256: string;
  end;

  TProjectBackupManifest = record
    BackupKind: string;
    CreatedAtUtc: string;
    UniWampVersion: string;
    ServerName: string;
    ServerAliases: string;
    DocumentRoot: string;
    EnableSsl: Boolean;
    SslCertFile: string;
    SslKeyFile: string;
    ProjectArchiveFile: string;
    ProjectArchiveSha256: string;
    MetadataFileName: string;
  end;

function BackupKindName(const Value: TBackupKind): string;
function ProjectBackupManifestToJson(const Manifest: TProjectBackupManifest): TJSONObject;
function VHostEntryToJson(const Entry: TVHostEntry): TJSONObject;

implementation

function BackupKindName(const Value: TBackupKind): string;
begin
  case Value of
    bkProject:
      Result := 'project';
    bkDatabase:
      Result := 'database';
  else
    Result := 'unknown';
  end;
end;

function ProjectBackupManifestToJson(const Manifest: TProjectBackupManifest): TJSONObject;
begin
  Result := TJSONObject.Create;
  Result.AddPair('backupKind', Manifest.BackupKind);
  Result.AddPair('createdAtUtc', Manifest.CreatedAtUtc);
  Result.AddPair('uniwampVersion', Manifest.UniWampVersion);
  Result.AddPair('serverName', Manifest.ServerName);
  Result.AddPair('serverAliases', Manifest.ServerAliases);
  Result.AddPair('documentRoot', Manifest.DocumentRoot);
  Result.AddPair('enableSsl', TJSONBool.Create(Manifest.EnableSsl));
  Result.AddPair('sslCertFile', Manifest.SslCertFile);
  Result.AddPair('sslKeyFile', Manifest.SslKeyFile);
  Result.AddPair('projectArchiveFile', Manifest.ProjectArchiveFile);
  Result.AddPair('projectArchiveSha256', Manifest.ProjectArchiveSha256);
  Result.AddPair('metadataFileName', Manifest.MetadataFileName);
end;

function VHostEntryToJson(const Entry: TVHostEntry): TJSONObject;
begin
  Result := TJSONObject.Create;
  Result.AddPair('serverName', Entry.ServerName);
  Result.AddPair('serverAliases', Entry.ServerAliases);
  Result.AddPair('documentRoot', Entry.DocumentRoot);
  Result.AddPair('enableSsl', TJSONBool.Create(Entry.EnableSsl));
  Result.AddPair('sslCertFile', Entry.SslCertFile);
  Result.AddPair('sslKeyFile', Entry.SslKeyFile);
end;

end.
