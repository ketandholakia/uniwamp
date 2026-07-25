unit Core.UniWamp.MariaDbAuth;

interface

uses
  System.SysUtils,
  Core.UniWamp.Paths;

function CreateMariaDbDefaultsExtraFile(const Paths: TAppPaths; const Password: string;
  out FileName, ErrorMessage: string): Boolean;
function CreateMariaDbPasswordSqlFile(const Paths: TAppPaths; const Password: string;
  out FileName, ErrorMessage: string): Boolean;
procedure DeleteMariaDbDefaultsExtraFile(const FileName: string);
function PrependDefaultsExtraFileArg(const DefaultsFileName, Arguments: string): string;

implementation

uses
  System.Classes,
  System.IOUtils;

function EscapeOptionValue(const Value: string): string;
begin
  Result := StringReplace(Value, '\', '\\', [rfReplaceAll]);
  Result := StringReplace(Result, '"', '\"', [rfReplaceAll]);
end;

function EscapeSqlLiteral(const Value: string): string;
begin
  Result := StringReplace(Value, '\', '\\', [rfReplaceAll]);
  Result := StringReplace(Result, '''', '''''', [rfReplaceAll]);
end;

function CreateMariaDbDefaultsExtraFile(const Paths: TAppPaths; const Password: string;
  out FileName, ErrorMessage: string): Boolean;
var
  GuidValue: TGuid;
  Contents: TStringList;
begin
  Result := False;
  FileName := '';
  ErrorMessage := '';
  try
    EnsureDirectory(Paths.TmpDir);
    CreateGUID(GuidValue);
    FileName := TPath.Combine(Paths.TmpDir,
      'mariadb-auth-' + GUIDToString(GuidValue).Replace('{', '').Replace('}', '') + '.cnf');
    Contents := TStringList.Create;
    try
      Contents.Add('[client]');
      Contents.Add('password="' + EscapeOptionValue(Password) + '"');
      Contents.SaveToFile(FileName, TEncoding.ASCII);
    finally
      Contents.Free;
    end;
    Result := True;
  except
    on E: Exception do
    begin
      ErrorMessage := E.Message;
      if (FileName <> '') and TFile.Exists(FileName) then
        TFile.Delete(FileName);
      FileName := '';
    end;
  end;
end;

function CreateMariaDbPasswordSqlFile(const Paths: TAppPaths; const Password: string;
  out FileName, ErrorMessage: string): Boolean;
var
  GuidValue: TGuid;
  SqlText: string;
begin
  Result := False;
  FileName := '';
  ErrorMessage := '';
  try
    EnsureDirectory(Paths.TmpDir);
    CreateGUID(GuidValue);
    FileName := TPath.Combine(Paths.TmpDir,
      'mariadb-password-' + GUIDToString(GuidValue).Replace('{', '').Replace('}', '') + '.sql');
    SqlText := 'SET PASSWORD = PASSWORD(''' + EscapeSqlLiteral(Password) + ''');' + sLineBreak;
    TFile.WriteAllText(FileName, SqlText, TEncoding.ASCII);
    Result := True;
  except
    on E: Exception do
    begin
      ErrorMessage := E.Message;
      if (FileName <> '') and TFile.Exists(FileName) then
        TFile.Delete(FileName);
      FileName := '';
    end;
  end;
end;

procedure DeleteMariaDbDefaultsExtraFile(const FileName: string);
begin
  if (Trim(FileName) <> '') and TFile.Exists(FileName) then
    TFile.Delete(FileName);
end;

function PrependDefaultsExtraFileArg(const DefaultsFileName, Arguments: string): string;
begin
  if Trim(DefaultsFileName) = '' then
    Result := Arguments
  else if Trim(Arguments) = '' then
    Result := '--defaults-extra-file="' + DefaultsFileName + '"'
  else
    Result := '--defaults-extra-file="' + DefaultsFileName + '" ' + Arguments;
end;

end.
