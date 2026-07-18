unit Core.UniWamp.DatabaseBackupService;

interface

uses
  System.SysUtils,
  Core.UniWamp.Paths,
  Core.UniWamp.Config,
  Core.UniWamp.Types,
  Core.UniWamp.Interfaces;

type
  TDatabaseBackupService = class(TInterfacedObject, IDatabaseBackupService)
  private
    FPaths: TAppPaths;
    FConfig: TUniWampConfig;
    function BuildBackupSlug(const Value: string): string;
    function GetMysqlDumpExe: string;
    function GetMysqlClientExe: string;
    function GetMysqlDumpArgs(const DumpPath: string): string;
    function GetMysqlRestoreArgs(const SqlFileName: string): string;
    function ComputeFileSha256Hex(const FileName: string): string;
    function TryReadBackupManifest(const BackupInfoFileName: string; out BackupDirectory,
      SqlFileName, ExpectedSha256: string; out ErrorMessage: string): Boolean;
  public
    constructor Create(const Paths: TAppPaths; Config: TUniWampConfig);
    function BackupAllDatabases(out BackupDirectory: string): TRuntimeActionResult;
    function RestoreDatabase(const BackupInfoFileName: string): TRuntimeActionResult;
  end;

implementation

uses
  System.Classes,
  System.DateUtils,
  System.Hash,
  System.IOUtils,
  System.StrUtils,
  System.Types,
  Core.UniWamp.ProcessManager,
  Core.UniWamp.Secrets;

constructor TDatabaseBackupService.Create(const Paths: TAppPaths; Config: TUniWampConfig);
begin
  inherited Create;
  FPaths := Paths;
  FConfig := Config;
end;

function TDatabaseBackupService.BuildBackupSlug(const Value: string): string;
var
  I: Integer;
  C: Char;
  LastWasSeparator: Boolean;
begin
  Result := '';
  LastWasSeparator := False;
  for I := 1 to Length(Value) do
  begin
    C := Value[I];
    if CharInSet(C, ['A'..'Z', 'a'..'z', '0'..'9']) then
    begin
      Result := Result + LowerCase(C);
      LastWasSeparator := False;
    end
    else if not LastWasSeparator then
    begin
      Result := Result + '-';
      LastWasSeparator := True;
    end;
  end;
  Result := Trim(Result);
  while (Result <> '') and (Result[1] = '-') do
    Delete(Result, 1, 1);
  while (Result <> '') and (Result[Length(Result)] = '-') do
    Delete(Result, Length(Result), 1);
  if Result = '' then
    Result := 'database';
end;

function TDatabaseBackupService.GetMysqlDumpExe: string;
begin
  Result := TPath.Combine(FPaths.MariaDbBinDir, 'mysqldump.exe');
  if not FileExists(Result) then
    Result := TPath.Combine(FPaths.MariaDbBinDir, 'mariadb-dump.exe');
end;

function TDatabaseBackupService.GetMysqlClientExe: string;
begin
  Result := TPath.Combine(FPaths.MariaDbBinDir, 'mysql.exe');
  if not FileExists(Result) then
    Result := TPath.Combine(FPaths.MariaDbBinDir, 'mariadb.exe');
end;

function TDatabaseBackupService.GetMysqlDumpArgs(const DumpPath: string): string;
var
  Password: string;
begin
  Result := '--protocol=tcp --host=127.0.0.1 --port=' + FConfig.DatabasePort.ToString + ' -uroot';
  Password := LoadMariaDbRootPassword(FPaths);
  if Password <> '' then
    Result := Result + ' --password="' + Password + '"';
  Result := Result + ' --all-databases --routines --events --single-transaction --quick';
  Result := Result + ' --result-file="' + DumpPath + '"';
end;

function TDatabaseBackupService.GetMysqlRestoreArgs(const SqlFileName: string): string;
var
  Password: string;
begin
  Result := '--protocol=tcp --host=127.0.0.1 --port=' + FConfig.DatabasePort.ToString + ' -uroot';
  Password := LoadMariaDbRootPassword(FPaths);
  if Password <> '' then
    Result := Result + ' --password="' + Password + '"';
  Result := Result + ' --batch --raw --execute="source ' + StringReplace(SqlFileName, '"', '\"', [rfReplaceAll]) + '"';
end;

function TDatabaseBackupService.ComputeFileSha256Hex(const FileName: string): string;
var
  Stream: TFileStream;
begin
  Result := '';
  if not FileExists(FileName) then
    Exit;
  Stream := TFileStream.Create(FileName, fmOpenRead or fmShareDenyWrite);
  try
    Result := THashSHA2.GetHashString(Stream);
  finally
    Stream.Free;
  end;
end;

function TDatabaseBackupService.TryReadBackupManifest(const BackupInfoFileName: string;
  out BackupDirectory, SqlFileName, ExpectedSha256: string; out ErrorMessage: string): Boolean;
var
  InfoText: string;
  Lines: TStringDynArray;
  I: Integer;
  Line: string;
  Key: string;
  Value: string;
  EqualsPos: Integer;
begin
  Result := False;
  BackupDirectory := '';
  SqlFileName := '';
  ExpectedSha256 := '';
  ErrorMessage := '';

  if not FileExists(BackupInfoFileName) then
  begin
    ErrorMessage := 'Backup info file not found: ' + BackupInfoFileName;
    Exit;
  end;
  if not SameText(ExtractFileName(BackupInfoFileName), 'backup.txt') then
  begin
    ErrorMessage := 'Select the backup.txt file from a database backup folder.';
    Exit;
  end;

  BackupDirectory := ExtractFileDir(BackupInfoFileName);
  InfoText := TFile.ReadAllText(BackupInfoFileName, TEncoding.UTF8);
  Lines := InfoText.Split([sLineBreak], TStringSplitOptions.ExcludeEmpty);
  for I := Low(Lines) to High(Lines) do
  begin
    Line := Trim(Lines[I]);
    if Line = '' then
      Continue;
    EqualsPos := Pos('=', Line);
    if EqualsPos <= 1 then
    begin
      ErrorMessage := 'Invalid backup manifest line: ' + Line;
      Exit;
    end;
    Key := LowerCase(Trim(Copy(Line, 1, EqualsPos - 1)));
    Value := Trim(Copy(Line, EqualsPos + 1, MaxInt));
    if Key = 'dumpfile' then
      SqlFileName := Value
    else if Key = 'sha256' then
      ExpectedSha256 := Value
    else if Key <> 'databaseport' then
    begin
      ErrorMessage := 'Unexpected backup manifest key: ' + Key;
      Exit;
    end;
  end;

  if SqlFileName = '' then
  begin
    ErrorMessage := 'The backup info file is missing dumpFile=.';
    Exit;
  end;
  if ExpectedSha256 = '' then
  begin
    ErrorMessage := 'The backup info file is missing sha256=.';
    Exit;
  end;

  Result := True;
end;

function TDatabaseBackupService.BackupAllDatabases(out BackupDirectory: string): TRuntimeActionResult;
var
  DumpExe: string;
  BackupName: string;
  BackupFileName: string;
  DumpPath: string;
  Output: string;
  StartResult: TProcessStartResult;
  SqlArgs: string;
begin
  Result.Success := False;
  Result.Message := '';
  BackupDirectory := '';

  DumpExe := GetMysqlDumpExe;
  if not FileExists(DumpExe) then
  begin
    Result.Message := 'mysqldump executable not found: ' + DumpExe;
    Exit;
  end;
  if not FConfig.MariaDbRunning then
  begin
    Result.Message := 'MariaDB must be running before creating a database backup.';
    Exit;
  end;

  BackupName := FormatDateTime('yyyymmdd-hhnnss', Now) + '-' + BuildBackupSlug(FConfig.HostName);
  BackupDirectory := TPath.Combine(FPaths.DatabaseBackupsDir, BackupName);
  EnsureDirectory(BackupDirectory);

  BackupFileName := 'databases.sql';
  DumpPath := TPath.Combine(BackupDirectory, BackupFileName);
  SqlArgs := GetMysqlDumpArgs(DumpPath);

  StartResult := TProcessManager.StartDetached(DumpExe, SqlArgs, FPaths.MariaDbBinDir);
  if not StartResult.Success then
  begin
    Result.Message := 'Database backup could not start: ' + StartResult.ErrorMessage;
    Exit;
  end;

  if not TProcessManager.WaitForExit(StartResult.ProcessId, 600000) then
  begin
    Result.Message := 'Database backup timed out.';
    Exit;
  end;
  if not FileExists(DumpPath) then
  begin
    Result.Message := 'Database backup did not produce a dump file.';
    Exit;
  end;

  Output := ComputeFileSha256Hex(DumpPath);
  TFile.WriteAllText(TPath.Combine(BackupDirectory, 'backup.txt'),
    'databasePort=' + FConfig.DatabasePort.ToString + sLineBreak +
    'dumpFile=' + BackupFileName + sLineBreak +
    'sha256=' + Output + sLineBreak, TEncoding.UTF8);

  Result.Success := True;
  Result.Message := 'Database backup created: ' + BackupDirectory;
end;

function TDatabaseBackupService.RestoreDatabase(const BackupInfoFileName: string): TRuntimeActionResult;
var
  BackupDirectory: string;
  SqlFileName: string;
  ClientExe: string;
  ClientArgs: string;
  Output: string;
  ExpectedSha256: string;
  ActualSha256: string;
  SqlFile: string;
  ParseError: string;
begin
  Result.Success := False;
  Result.Message := '';

  if not FConfig.MariaDbRunning then
  begin
    Result.Message := 'MariaDB must be running before restoring a database backup.';
    Exit;
  end;

  if not TryReadBackupManifest(BackupInfoFileName, BackupDirectory, SqlFileName, ExpectedSha256, ParseError) then
  begin
    Result.Message := ParseError;
    Exit;
  end;

  if not TPath.IsPathRooted(BackupDirectory) then
  begin
    Result.Message := 'Backup folder path is invalid.';
    Exit;
  end;

  SqlFile := TPath.Combine(BackupDirectory, SqlFileName);
  if not FileExists(SqlFile) then
  begin
    Result.Message := 'Database dump file not found: ' + SqlFile;
    Exit;
  end;

  if ExpectedSha256 <> '' then
  begin
    ActualSha256 := ComputeFileSha256Hex(SqlFile);
    if not SameText(ActualSha256, ExpectedSha256) then
    begin
      Result.Message := 'Database dump checksum does not match.';
      Exit;
    end;
  end;

  ClientExe := GetMysqlClientExe;
  if not FileExists(ClientExe) then
  begin
    Result.Message := 'mysql executable not found: ' + ClientExe;
    Exit;
  end;

  ClientArgs := GetMysqlRestoreArgs(SqlFile);
  if not TProcessManager.RunAndCaptureOutput(ClientExe, ClientArgs, FPaths.MariaDbBinDir, Output, 1200000) then
  begin
    if Trim(Output) <> '' then
      Result.Message := Trim(Output)
    else
      Result.Message := 'Database restore failed to start.';
    Exit;
  end;

  if Trim(Output) <> '' then
  begin
    if (Pos('error', LowerCase(Output)) > 0) or (Pos('access denied', LowerCase(Output)) > 0) then
    begin
      Result.Message := Trim(Output);
      Exit;
    end;
  end;

  Result.Success := True;
  Result.Message := 'Database restore completed from: ' + BackupInfoFileName;
end;

end.
