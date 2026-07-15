unit Core.UniWamp.Security;

interface

uses
  System.SysUtils,
  System.Zip;

function ValidateProjectName(const Value: string; out ErrorMessage: string): Boolean;
function ValidateServerName(const Value: string; out NormalizedValue, ErrorMessage: string): Boolean;
function ValidateDocumentRoot(const Value: string; out NormalizedValue, ErrorMessage: string): Boolean;
function ValidateServerAliases(const Value: string; out NormalizedValue, ErrorMessage: string): Boolean;
function ValidateUpdatePackageFileName(const Value: string; out ErrorMessage: string): Boolean;
function ValidateZipArchiveStructure(const Zip: TZipFile; out ErrorMessage: string): Boolean;
function ExtractZipSafely(const Zip: TZipFile; const TargetDir: string; out ErrorMessage: string): Boolean;

implementation

uses
  System.Classes,
  System.IOUtils,
  Core.UniWamp.Paths;

function ContainsInvalidPathChar(const Value: string; const AllowDriveColon: Boolean = False): Boolean;
var
  I: Integer;
  C: Char;
begin
  Result := False;
  for I := 1 to Length(Value) do
  begin
    C := Value[I];
    if Ord(C) < 32 then
      Exit(True);
    case C of
      '"', '<', '>', '|', '?', '*':
        Exit(True);
      ':':
        if not (AllowDriveColon and (I = 2) and CharInSet(Value[1], ['A'..'Z', 'a'..'z'])) then
          Exit(True);
    end;
  end;
end;

function IsValidProjectToken(const Value: string): Boolean;
var
  I: Integer;
begin
  Result := Value <> '';
  if not Result then
    Exit;
  for I := 1 to Length(Value) do
    if not CharInSet(Value[I], ['A'..'Z', 'a'..'z', '0'..'9', '_', '-']) then
      Exit(False);
end;

function IsValidHostLabel(const Value: string): Boolean;
var
  I: Integer;
begin
  Result := Value <> '';
  if not Result then
    Exit;
  if (Value[1] = '-') or (Value[Length(Value)] = '-') then
    Exit(False);
  for I := 1 to Length(Value) do
    if not CharInSet(Value[I], ['A'..'Z', 'a'..'z', '0'..'9', '-', '_']) then
      Exit(False);
end;

function IsValidIPv4Address(const Value: string): Boolean;
var
  Parts: TStringList;
  Part: string;
  Octet: Integer;
begin
  Result := False;
  Parts := TStringList.Create;
  try
    ExtractStrings(['.'], [], PChar(Value), Parts);
    if Parts.Count <> 4 then
      Exit;
    for Part in Parts do
    begin
      if (Part = '') or not TryStrToInt(Part, Octet) or (Octet < 0) or (Octet > 255) then
        Exit;
    end;
    Result := True;
  finally
    Parts.Free;
  end;
end;

function IsValidServerNameValue(const Value: string): Boolean;
var
  Parts: TStringList;
  Part: string;
begin
  Result := False;
  if (Value = '') or ContainsInvalidPathChar(Value) then
    Exit;
  if SameText(Value, 'localhost') then
    Exit(True);
  if IsValidIPv4Address(Value) then
    Exit(True);

  Parts := TStringList.Create;
  try
    ExtractStrings(['.'], [], PChar(Value), Parts);
    if Parts.Count = 0 then
      Exit;
    for Part in Parts do
      if not IsValidHostLabel(Part) then
        Exit;
    Result := True;
  finally
    Parts.Free;
  end;
end;

function IsSafeRelativeZipEntryName(const Value: string; out NormalizedValue, ErrorMessage: string): Boolean;
var
  Parts: TStringList;
  I: Integer;
  Part: string;
begin
  Result := False;
  ErrorMessage := '';
  NormalizedValue := Trim(StringReplace(Value, '/', PathDelim, [rfReplaceAll]));
  if NormalizedValue = '' then
  begin
    ErrorMessage := 'Zip archive contains an empty entry name.';
    Exit;
  end;
  if TPath.IsPathRooted(NormalizedValue) or (Pos(':', NormalizedValue) > 0) then
  begin
    ErrorMessage := 'Zip archive contains an absolute entry path: ' + Value;
    Exit;
  end;

  Parts := TStringList.Create;
  try
    ExtractStrings([PathDelim], [], PChar(NormalizedValue), Parts);
    if Parts.Count = 0 then
    begin
      ErrorMessage := 'Zip archive contains an empty entry name.';
      Exit;
    end;
    for I := 0 to Parts.Count - 1 do
    begin
      Part := Parts[I];
      if (Part = '') or (Part = '.') or (Part = '..') then
      begin
        ErrorMessage := 'Zip archive contains a traversal entry: ' + Value;
        Exit;
      end;
    end;
    Result := True;
  finally
    Parts.Free;
  end;
end;

function IsPathUnderRoot(const CandidatePath, RootPath: string): Boolean;
var
  Candidate: string;
  Root: string;
begin
  Candidate := ExpandFileName(CandidatePath);
  Root := IncludeTrailingPathDelimiter(ExpandFileName(RootPath));
  Result := SameText(Candidate, ExcludeTrailingPathDelimiter(Root)) or
    (Pos(LowerCase(Root), LowerCase(IncludeTrailingPathDelimiter(Candidate))) = 1);
end;

function ValidateZipArchiveStructure(const Zip: TZipFile; out ErrorMessage: string): Boolean;
var
  I: Integer;
  NormalizedEntryName: string;
begin
  Result := False;
  ErrorMessage := '';
  if not Assigned(Zip) then
  begin
    ErrorMessage := 'Zip archive handle is not available.';
    Exit;
  end;

  for I := 0 to Zip.FileCount - 1 do
    if not IsSafeRelativeZipEntryName(Zip.FileName[I], NormalizedEntryName, ErrorMessage) then
      Exit;

  Result := True;
end;

function ValidateProjectName(const Value: string; out ErrorMessage: string): Boolean;
var
  NormalizedValue: string;
begin
  NormalizedValue := Trim(Value);
  Result := IsValidProjectToken(NormalizedValue);
  if Result then
    ErrorMessage := ''
  else
    ErrorMessage := 'Project name may only contain letters, digits, hyphens, and underscores.';
end;

function ValidateServerName(const Value: string; out NormalizedValue, ErrorMessage: string): Boolean;
begin
  NormalizedValue := Trim(Value);
  Result := IsValidServerNameValue(NormalizedValue);
  if Result then
    ErrorMessage := ''
  else
    ErrorMessage := 'Server name must be a simple local host name, localhost, or IPv4 address.';
end;

function ValidateDocumentRoot(const Value: string; out NormalizedValue, ErrorMessage: string): Boolean;
begin
  NormalizedValue := Trim(Value);
  Result := (NormalizedValue <> '') and not ContainsInvalidPathChar(NormalizedValue, True);
  if Result then
    ErrorMessage := ''
  else
    ErrorMessage := 'Document root contains invalid path characters.';
end;

function ValidateServerAliases(const Value: string; out NormalizedValue, ErrorMessage: string): Boolean;
var
  Parts: TStringList;
  I: Integer;
  Item: string;
  AliasValue: string;
begin
  ErrorMessage := '';
  NormalizedValue := '';
  AliasValue := StringReplace(StringReplace(Trim(Value), ',', ' ', [rfReplaceAll]), #9, ' ', [rfReplaceAll]);
  if AliasValue = '' then
    Exit(True);

  Parts := TStringList.Create;
  try
    Parts.StrictDelimiter := True;
    Parts.Delimiter := ' ';
    Parts.DelimitedText := AliasValue;
    for I := 0 to Parts.Count - 1 do
    begin
      Item := Trim(Parts[I]);
      if Item = '' then
        Continue;
      if not IsValidServerNameValue(Item) then
      begin
        ErrorMessage := 'Server aliases must be simple host names separated by spaces or commas.';
        Exit(False);
      end;
      if NormalizedValue <> '' then
        NormalizedValue := NormalizedValue + ' ';
      NormalizedValue := NormalizedValue + Item;
    end;
    Result := True;
  finally
    Parts.Free;
  end;
end;

function ValidateUpdatePackageFileName(const Value: string; out ErrorMessage: string): Boolean;
var
  NormalizedValue: string;
begin
  NormalizedValue := Trim(Value);
  Result := (NormalizedValue <> '') and
    SameText(ExtractFileName(NormalizedValue), NormalizedValue) and
    not TPath.IsPathRooted(NormalizedValue) and
    (Pos(PathDelim, NormalizedValue) = 0) and
    (Pos('/', NormalizedValue) = 0) and
    (Pos('\', NormalizedValue) = 0);
  if Result then
    ErrorMessage := ''
  else
    ErrorMessage := 'Update manifest packageFileName must be a plain file name.';
end;

function ExtractZipSafely(const Zip: TZipFile; const TargetDir: string; out ErrorMessage: string): Boolean;
var
  I: Integer;
  EntryName: string;
  NormalizedEntryName: string;
  TargetPath: string;
  EntryStream: TStream;
  LocalHeader: TZipHeader;
  OutputStream: TFileStream;
begin
  Result := False;
  ErrorMessage := '';
  if not Assigned(Zip) then
  begin
    ErrorMessage := 'Zip archive handle is not available.';
    Exit;
  end;
  EnsureDirectory(TargetDir);
  for I := 0 to Zip.FileCount - 1 do
  begin
    EntryName := Zip.FileName[I];
    if not IsSafeRelativeZipEntryName(EntryName, NormalizedEntryName, ErrorMessage) then
      Exit;

    TargetPath := ExpandFileName(TPath.Combine(TargetDir, NormalizedEntryName));
    if not IsPathUnderRoot(TargetPath, TargetDir) then
    begin
      ErrorMessage := 'Zip archive entry escapes the target directory: ' + EntryName;
      Exit;
    end;

    if ((Length(NormalizedEntryName) > 0) and CharInSet(NormalizedEntryName[Length(NormalizedEntryName)], ['\', '/'])) or
       (Length(EntryName) > 0) and CharInSet(EntryName[Length(EntryName)], ['\', '/']) then
    begin
      EnsureDirectory(TargetPath);
      Continue;
    end;

    EnsureDirectory(ExtractFilePath(TargetPath));
    Zip.Read(I, EntryStream, LocalHeader);
    try
      OutputStream := TFileStream.Create(TargetPath, fmCreate);
      try
        OutputStream.CopyFrom(EntryStream, 0);
      finally
        OutputStream.Free;
      end;
    finally
      EntryStream.Free;
    end;
  end;

  Result := True;
end;

end.
