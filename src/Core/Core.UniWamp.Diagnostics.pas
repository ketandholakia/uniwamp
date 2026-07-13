unit Core.UniWamp.Diagnostics;

interface

uses
  System.SysUtils;

procedure AppendRotatedLogLine(const FileName, Text: string; const MaxLines: Integer = 500);
function RedactSensitiveText(const Text: string): string;
function ChooseActivityLogClipboardText(const LogFileText, MemoText: string): string;

implementation

uses
  System.Classes,
  System.IOUtils;

function RedactValueAfterKey(const Text, Key: string): string;
var
  StartPos: Integer;
  EndPos: Integer;
begin
  Result := Text;
  StartPos := Pos(LowerCase(Key), LowerCase(Result));
  if StartPos = 0 then
    Exit;

  StartPos := StartPos + Length(Key);
  EndPos := StartPos;
  while (EndPos <= Length(Result)) and not CharInSet(Result[EndPos], [' ', #9, #13, #10, ';', '&']) do
    Inc(EndPos);
  Delete(Result, StartPos, EndPos - StartPos);
  Insert('[redacted]', Result, StartPos);
end;

function RedactSensitiveText(const Text: string): string;
begin
  Result := Text;
  Result := RedactValueAfterKey(Result, 'password=');
  Result := RedactValueAfterKey(Result, 'pass=');
  Result := RedactValueAfterKey(Result, 'token=');
  Result := RedactValueAfterKey(Result, 'secret=');
end;

function ChooseActivityLogClipboardText(const LogFileText, MemoText: string): string;
begin
  if Trim(LogFileText) <> '' then
    Exit(LogFileText);
  if Trim(MemoText) <> '' then
    Exit(MemoText);
  Result := '';
end;

procedure TrimLogFileToRecentLines(const FileName: string; const MaxLines: Integer);
var
  Lines: TStringList;
  StartIndex: Integer;
  KeptLines: TStringList;
  I: Integer;
begin
  if (MaxLines <= 0) or not FileExists(FileName) then
    Exit;

  Lines := TStringList.Create;
  KeptLines := TStringList.Create;
  try
    Lines.Text := TFile.ReadAllText(FileName, TEncoding.UTF8);
    if Lines.Count <= MaxLines then
      Exit;
    StartIndex := Lines.Count - MaxLines;
    for I := StartIndex to Lines.Count - 1 do
      KeptLines.Add(Lines[I]);
    TFile.WriteAllText(FileName, KeptLines.Text, TEncoding.UTF8);
  finally
    KeptLines.Free;
    Lines.Free;
  end;
end;

procedure AppendRotatedLogLine(const FileName, Text: string; const MaxLines: Integer);
var
  Lines: TStringList;
  LineCount: Integer;
begin
  TFile.AppendAllText(FileName, RedactSensitiveText(Text) + sLineBreak, TEncoding.UTF8);

  if MaxLines <= 0 then
    Exit;

  Lines := TStringList.Create;
  try
    Lines.Text := TFile.ReadAllText(FileName, TEncoding.UTF8);
    LineCount := Lines.Count;
    if LineCount > MaxLines then
      TrimLogFileToRecentLines(FileName, MaxLines);
  finally
    Lines.Free;
  end;
end;

end.
