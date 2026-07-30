unit Test.UniWamp.DatabaseBackupService;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TDatabaseBackupServiceTests = class
  public
    [Test]
    procedure TestRestoreDatabaseRejectsTraversalDumpFile;
  end;

implementation

uses
  System.IOUtils,
  System.SysUtils,
  Core.UniWamp.Config,
  Core.UniWamp.DatabaseBackupService,
  Core.UniWamp.Paths,
  Core.UniWamp.Types;

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
  Result.BackupsDir := TPath.Combine(Root, 'backups');
  Result.DatabaseBackupsDir := TPath.Combine(Result.BackupsDir, 'databases');
  Result.TmpDir := TPath.Combine(Root, 'tmp');
  Result.MariaDbDir := TPath.Combine(Root, 'runtime\mariadb');
  Result.MariaDbBinDir := TPath.Combine(Result.MariaDbDir, 'bin');
  EnsureDirectory(Result.BackupsDir);
  EnsureDirectory(Result.DatabaseBackupsDir);
  EnsureDirectory(Result.TmpDir);
  EnsureDirectory(Result.MariaDbBinDir);
end;

procedure TDatabaseBackupServiceTests.TestRestoreDatabaseRejectsTraversalDumpFile;
var
  RootDir: string;
  Paths: TAppPaths;
  Config: TUniWampConfig;
  Service: TDatabaseBackupService;
  BackupDir: string;
  ManifestPath: string;
  OutsideFile: string;
  ResultInfo: TRuntimeActionResult;
begin
  RootDir := CreateTempRoot('db-restore-traversal');
  try
    Paths := BuildPaths(RootDir);
    Config := TUniWampConfig.Create;
    try
      Config.MariaDbRunning := True;
      Service := TDatabaseBackupService.Create(Paths, Config);
      try
        BackupDir := TPath.Combine(RootDir, 'backup');
        TDirectory.CreateDirectory(BackupDir);
        ManifestPath := TPath.Combine(BackupDir, 'backup.txt');
        OutsideFile := TPath.Combine(RootDir, 'escape.sql');
        TFile.WriteAllText(OutsideFile, 'select 1;', TEncoding.UTF8);
        TFile.WriteAllText(ManifestPath,
          'databasePort=3306' + sLineBreak +
          'dumpFile=..\escape.sql' + sLineBreak +
          'sha256=abcd' + sLineBreak,
          TEncoding.UTF8);

        ResultInfo := Service.RestoreDatabase(ManifestPath);
        Assert.IsFalse(ResultInfo.Success, 'Traversal dumpFile entries must be rejected.');
        Assert.IsTrue(ResultInfo.Message.Contains('plain file name'), ResultInfo.Message);
      finally
        Service.Free;
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
  TDUnitX.RegisterTestFixture(TDatabaseBackupServiceTests);

end.
