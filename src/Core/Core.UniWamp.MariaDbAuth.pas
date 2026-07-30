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
function BuildMariaDbSourceFileArgs(const SqlFileName, DefaultsFileName: string): string;

implementation

uses
  System.Classes,
  System.IOUtils,
  Core.UniWamp.AtomicFile;

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
      AtomicWriteTextFile(FileName, Contents.Text, TEncoding.ASCII);
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
begin
  Result := False;
  FileName := '';
  ErrorMessage := '';
  ErrorMessage := 'Writing a root-password SQL file is disabled; use the interactive password update path.';
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

function BuildMariaDbSourceFileArgs(const SqlFileName, DefaultsFileName: string): string;
var
  NormalizedSqlFileName: string;
begin
  NormalizedSqlFileName := StringReplace(SqlFileName, '"', '\"', [rfReplaceAll]);
  Result := '--batch --raw --execute="source ' + NormalizedSqlFileName + '"';
  Result := PrependDefaultsExtraFileArg(DefaultsFileName, Result);
end;

end.
