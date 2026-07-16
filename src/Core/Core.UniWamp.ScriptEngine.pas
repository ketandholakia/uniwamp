unit Core.UniWamp.ScriptEngine;

interface

uses
  Core.UniWamp.Paths,
  Core.UniWamp.ScriptCatalog,
  System.SysUtils;

type
  TScriptOutputEvent = reference to procedure(const Text: string);

  TScriptExecutionResult = record
    Success: Boolean;
    CompletedSteps: Integer;
    Message: string;
    Output: string;
  end;

  TScriptEngine = class
  private
    FPaths: TAppPaths;
    function SelectedPhpExe: string;
    function PhpCliPrefix(const PhpExe: string): string;
    function MariaDbAdminExe: string;
    function DatabasePort: Integer;
    function MariaDbRootPassword: string;
    function CreateDatabase(const DatabaseName: string; out Output: string): Boolean;
    function ExpandTokens(const Value: string; const Item: TScriptCatalogItem;
      const ProjectName: string): string;
    function SafePath(const Value: string; const Description: string): string;
    function RunStep(const Step: TScriptStep; const Item: TScriptCatalogItem;
      const ProjectName: string; out Output: string; const OnOutput: TScriptOutputEvent = nil): Boolean;
    function CopyDirectory(const SourceDirectory, DestinationDirectory: string): Boolean;
  public
    constructor Create(const Paths: TAppPaths);
    function PhpRuntimeDescription: string;
    function Execute(const Item: TScriptCatalogItem; const ProjectName: string;
      const OnOutput: TScriptOutputEvent = nil): TScriptExecutionResult;
  end;

implementation

uses
  Core.UniWamp.ProcessManager,
  Core.UniWamp.Security,
  Core.UniWamp.Secrets,
  System.Classes,
  System.JSON,
  System.IOUtils,
  System.Net.HttpClient,
  System.Net.URLClient,
  System.Zip;

constructor TScriptEngine.Create(const Paths: TAppPaths);
begin
  inherited Create;
  FPaths := Paths;
end;

function TScriptEngine.PhpRuntimeDescription: string;
var
  ConfigFile: string;
  JsonValue: TJSONValue;
  JsonObject: TJSONObject;
  Version: string;
  PhpExe: string;
begin
  PhpExe := SelectedPhpExe;
  if PhpExe = '' then
    Exit('No PHP runtime was found under runtime\php or on PATH.');

  Version := '';
  ConfigFile := TPath.Combine(FPaths.ConfigDir, 'uniwamp.json');
  if TFile.Exists(ConfigFile) then
  begin
    JsonValue := TJSONObject.ParseJSONValue(TFile.ReadAllText(ConfigFile, TEncoding.UTF8));
    if Assigned(JsonValue) then
    try
      JsonObject := JsonValue as TJSONObject;
      if Assigned(JsonObject) then
        Version := JsonObject.GetValue<string>('selectedPhpVersion');
    finally
      JsonValue.Free;
    end;
  end;
  if Version <> '' then
    Exit(Format('PHP runtime %s (%s)', [Version, PhpExe]));
  Result := 'PHP runtime: ' + PhpExe;
end;

function TScriptEngine.SelectedPhpExe: string;
var
  ConfigFile: string;
  JsonValue: TJSONValue;
  JsonObject: TJSONObject;
  Version: string;
  Candidate: string;
  FallbackVersions: TArray<string>;
  I: Integer;
begin
  Result := '';
  FallbackVersions := TArray<string>.Create('php85', 'php84', 'php83', 'php82');
  ConfigFile := TPath.Combine(FPaths.ConfigDir, 'uniwamp.json');
  if TFile.Exists(ConfigFile) then
  begin
    JsonValue := TJSONObject.ParseJSONValue(TFile.ReadAllText(ConfigFile, TEncoding.UTF8));
    if Assigned(JsonValue) then
    try
      JsonObject := JsonValue as TJSONObject;
      if Assigned(JsonObject) then
      begin
        Version := JsonObject.GetValue<string>('selectedPhpVersion');
        if Version <> '' then
        begin
          Candidate := TPath.Combine(TPath.Combine(FPaths.PhpDir, Version), 'php.exe');
          if TFile.Exists(Candidate) then
            Exit(Candidate);
        end;
      end;
    finally
      JsonValue.Free;
    end;
  end;
  for I := Low(FallbackVersions) to High(FallbackVersions) do
  begin
    Candidate := TPath.Combine(TPath.Combine(FPaths.PhpDir, FallbackVersions[I]), 'php.exe');
    if TFile.Exists(Candidate) then
      Exit(Candidate);
  end;
end;

function TScriptEngine.PhpCliPrefix(const PhpExe: string): string;
var
  IniFile: string;
  ExtDir: string;
begin
  Result := '';
  if PhpExe = '' then
    Exit;
  IniFile := FPaths.ActivePhpIniFile;
  ExtDir := IncludeTrailingPathDelimiter(ExtractFilePath(PhpExe)) + 'ext';
  if TFile.Exists(IniFile) then
    Result := Format('-c "%s"', [IniFile])
  else if TDirectory.Exists(ExtDir) then
    Result := Format('-d extension_dir="%s" -d extension=php_openssl.dll', [ExtDir]);
end;

function TScriptEngine.MariaDbAdminExe: string;
begin
  Result := TPath.Combine(FPaths.MariaDbBinDir, 'mysqladmin.exe');
  if not TFile.Exists(Result) then
    Result := TPath.Combine(FPaths.MariaDbBinDir, 'mariadb-admin.exe');
end;

function TScriptEngine.DatabasePort: Integer;
var
  ConfigFile: string;
  JsonValue: TJSONValue;
  JsonObject: TJSONObject;
begin
  Result := 3307;
  ConfigFile := TPath.Combine(FPaths.ConfigDir, 'uniwamp.json');
  if not TFile.Exists(ConfigFile) then
    Exit;
  JsonValue := TJSONObject.ParseJSONValue(TFile.ReadAllText(ConfigFile, TEncoding.UTF8));
  if not Assigned(JsonValue) then
    Exit;
  try
    JsonObject := JsonValue as TJSONObject;
    if Assigned(JsonObject) then
      Result := JsonObject.GetValue<Integer>('databasePort');
  finally
    JsonValue.Free;
  end;
end;

function TScriptEngine.MariaDbRootPassword: string;
begin
  Result := LoadMariaDbRootPassword(FPaths);
end;

function TScriptEngine.CreateDatabase(const DatabaseName: string; out Output: string): Boolean;
var
  ClientExe: string;
  Arguments: string;
begin
  Output := '';
  ClientExe := MariaDbAdminExe;
  if not TFile.Exists(ClientExe) then
  begin
    Output := 'MariaDB admin tool not found: ' + ClientExe;
    Exit(False);
  end;
  Arguments := '--protocol=tcp --host=127.0.0.1 --port=' + IntToStr(DatabasePort) + ' -uroot';
  if MariaDbRootPassword <> '' then
    Arguments := Arguments + ' --password="' + MariaDbRootPassword + '"';
  Arguments := Arguments + ' create "' + DatabaseName + '"';
  Result := TProcessManager.RunAndCaptureOutput(ClientExe, Arguments, FPaths.MariaDbBinDir, Output, 600000);
end;

function TScriptEngine.ExpandTokens(const Value: string;
  const Item: TScriptCatalogItem; const ProjectName: string): string;
begin
  Result := Value;
  Result := StringReplace(Result, '${appRoot}', FPaths.AppRoot, [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, '${runtime}', FPaths.RuntimeDir, [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, '${tools}', FPaths.ToolsDir, [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, '${www}', FPaths.WwwDir, [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, '${vhosts}', FPaths.VHostsDir, [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, '${tmp}', FPaths.TmpDir, [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, '${itemId}', Item.Id, [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, '${projectName}', ProjectName, [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, '${php}', SelectedPhpExe, [rfReplaceAll, rfIgnoreCase]);
end;

function TScriptEngine.SafePath(const Value, Description: string): string;
var
  RootPath: string;
  CandidatePath: string;
begin
  CandidatePath := ExpandFileName(Value);
  RootPath := IncludeTrailingPathDelimiter(ExpandFileName(FPaths.AppRoot));
  if (not SameText(CandidatePath, ExcludeTrailingPathDelimiter(RootPath))) and
     (Pos(LowerCase(RootPath), LowerCase(IncludeTrailingPathDelimiter(CandidatePath))) <> 1) then
    raise EArgumentException.CreateFmt('%s is outside the UniWamp root: %s',
      [Description, CandidatePath]);
  Result := CandidatePath;
end;

function TScriptEngine.CopyDirectory(const SourceDirectory,
  DestinationDirectory: string): Boolean;
var
  Directory: string;
  FileName: string;
begin
  Result := False;
  if not TDirectory.Exists(SourceDirectory) then
    Exit;
  EnsureDirectory(DestinationDirectory);
  for FileName in TDirectory.GetFiles(SourceDirectory) do
    TFile.Copy(FileName, TPath.Combine(DestinationDirectory, ExtractFileName(FileName)), True);
  for Directory in TDirectory.GetDirectories(SourceDirectory) do
    if not CopyDirectory(Directory,
      TPath.Combine(DestinationDirectory, ExtractFileName(ExcludeTrailingPathDelimiter(Directory)))) then
      Exit;
  Result := True;
end;

type
  TDownloadProgressHandler = class
    FOnOutput: TScriptOutputEvent;
    procedure ReceiveData(const Sender: TObject; AContentLength, AReadCount: Int64; var AAbort: Boolean);
  end;

procedure TDownloadProgressHandler.ReceiveData(const Sender: TObject; AContentLength, AReadCount: Int64; var AAbort: Boolean);
var
  Percent: Integer;
begin
  if Assigned(FOnOutput) and (AContentLength > 0) then
  begin
    Percent := Trunc((AReadCount / AContentLength) * 100);
    FOnOutput(Format('[PROGRESS] %d', [Percent]));
  end;
end;

function TScriptEngine.RunStep(const Step: TScriptStep;
  const Item: TScriptCatalogItem; const ProjectName: string; out Output: string; const OnOutput: TScriptOutputEvent): Boolean;
var
  SourcePath: string;
  DestinationPath: string;
  ExecutablePath: string;
  WorkingDirectory: string;
  Arguments: string;
  Client: THTTPClient;
  FileStream: TFileStream;
  ZipFile: TZipFile;
  ProgressHandler: TDownloadProgressHandler;
begin
  Output := '';
  Result := False;
  if Step.StepType = 'create_directory' then
  begin
    EnsureDirectory(SafePath(ExpandTokens(Step.Destination, Item, ProjectName), 'Directory'));
    Exit(True);
  end;
  if Step.StepType = 'write_file' then
  begin
    DestinationPath := SafePath(ExpandTokens(Step.Destination, Item, ProjectName), 'File');
    EnsureDirectory(ExtractFilePath(DestinationPath));
    TFile.WriteAllText(DestinationPath, ExpandTokens(Step.Content, Item, ProjectName), TEncoding.UTF8);
    Exit(True);
  end;
  if Step.StepType = 'copy_tree' then
  begin
    SourcePath := SafePath(ExpandTokens(Step.Source, Item, ProjectName), 'Source');
    DestinationPath := SafePath(ExpandTokens(Step.Destination, Item, ProjectName), 'Destination');
    Exit(CopyDirectory(SourcePath, DestinationPath));
  end;
  if Step.StepType = 'download' then
  begin
    DestinationPath := SafePath(ExpandTokens(Step.Destination, Item, ProjectName), 'Download destination');
    EnsureDirectory(ExtractFilePath(DestinationPath));
    Client := THTTPClient.Create;
    try
      ProgressHandler := TDownloadProgressHandler.Create;
      try
        ProgressHandler.FOnOutput := OnOutput;
        Client.OnReceiveData := ProgressHandler.ReceiveData;
        FileStream := TFileStream.Create(DestinationPath, fmCreate);
        try
          Client.Get(ExpandTokens(Step.Url, Item, ProjectName), FileStream);
        finally
          FileStream.Free;
        end;
      finally
        ProgressHandler.Free;
      end;
    finally
      Client.Free;
    end;
    Exit(True);
  end;
  if Step.StepType = 'extract_zip' then
  begin
    SourcePath := SafePath(ExpandTokens(Step.Source, Item, ProjectName), 'Archive');
    DestinationPath := SafePath(ExpandTokens(Step.Destination, Item, ProjectName), 'Extraction destination');
    EnsureDirectory(DestinationPath);
    ZipFile := TZipFile.Create;
    try
      ZipFile.Open(SourcePath, zmRead);
      if not ExtractZipSafely(ZipFile, DestinationPath, Output) then
        Exit(False);
    finally
      ZipFile.Free;
    end;
    Exit(True);
  end;
  if Step.StepType = 'run' then
  begin
    ExecutablePath := SafePath(ExpandTokens(Step.Executable, Item, ProjectName), 'Executable');
    WorkingDirectory := SafePath(ExpandTokens(Step.WorkingDirectory, Item, ProjectName), 'Working directory');
    Arguments := ExpandTokens(Step.Arguments, Item, ProjectName);
    if SameText(ExtractFileName(ExecutablePath), 'php.exe') then
      Arguments := Trim(PhpCliPrefix(ExecutablePath) + ' ' + Arguments);
    Exit(TProcessManager.RunAndCaptureOutput(ExecutablePath,
      Arguments, WorkingDirectory, Output, Step.TimeoutMs));
  end;
  if Step.StepType = 'create_database' then
  begin
    Output := '';
    if not CreateDatabase(ExpandTokens(Step.Destination, Item, ProjectName), Output) then
      Exit(False);
    Exit(True);
  end;
  Output := 'Unknown script step type: ' + Step.StepType;
end;

function TScriptEngine.Execute(const Item: TScriptCatalogItem; const ProjectName: string;
  const OnOutput: TScriptOutputEvent): TScriptExecutionResult;
var
  I: Integer;
  StepOutput: string;
begin
  Result.Success := False;
  Result.CompletedSteps := 0;
  Result.Message := '';
  Result.Output := '';
  try
    for I := Low(Item.Steps) to High(Item.Steps) do
    begin
      if not RunStep(Item.Steps[I], Item, ProjectName, StepOutput, OnOutput) then
      begin
        Result.Message := Format('Step %d failed.', [I + 1]);
        Result.Output := StepOutput;
        Exit;
      end;
      Inc(Result.CompletedSteps);
      if Assigned(OnOutput) and (Trim(StepOutput) <> '') then
        OnOutput(StepOutput);
      if StepOutput <> '' then
        Result.Output := Result.Output + StepOutput + sLineBreak;
    end;
    Result.Success := True;
    Result.Message := Format('%s completed successfully.', [Item.Name]);
  except
    on E: Exception do
    begin
      Result.Message := E.Message;
      Result.Output := StepOutput;
    end;
  end;
end;

end.
