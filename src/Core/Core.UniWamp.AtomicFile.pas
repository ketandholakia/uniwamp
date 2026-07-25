unit Core.UniWamp.AtomicFile;

interface

uses
  System.SysUtils;

procedure AtomicWriteTextFile(const FileName, Content: string; Encoding: TEncoding;
  const BackupFileName: string = '');
procedure AtomicReplaceFile(const SourceFileName, TargetFileName: string;
  const BackupFileName: string = '');

implementation

uses
  Winapi.Windows,
  System.Classes,
  System.IOUtils;

procedure WriteTextAndFlush(const FileName, Content: string; Encoding: TEncoding);
var
  Stream: TFileStream;
  Writer: TStreamWriter;
begin
  Stream := TFileStream.Create(FileName, fmCreate or fmShareExclusive);
  try
    Writer := TStreamWriter.Create(Stream, Encoding);
    try
      Writer.Write(Content);
      Writer.Flush;
      FlushFileBuffers(Stream.Handle);
    finally
      Writer.Free;
    end;
  finally
    Stream.Free;
  end;
end;

procedure AtomicWriteTextFile(const FileName, Content: string; Encoding: TEncoding;
  const BackupFileName: string);
var
  TempFileName: string;
begin
  TempFileName := FileName + '.' + GUIDToString(TGUID.NewGuid) + '.tmp';
  WriteTextAndFlush(TempFileName, Content, Encoding);
  AtomicReplaceFile(TempFileName, FileName, BackupFileName);
end;

procedure AtomicReplaceFile(const SourceFileName, TargetFileName: string;
  const BackupFileName: string);
var
  DirectoryName: string;
  SourceWide: string;
  TargetWide: string;
  BackupWide: string;
  BackupPtr: PChar;
  ReplaceSucceeded: Boolean;
begin
  DirectoryName := TPath.GetDirectoryName(TargetFileName);
  if DirectoryName <> '' then
    ForceDirectories(DirectoryName);

  ReplaceSucceeded := False;
  try
    SourceWide := SourceFileName;
    TargetWide := TargetFileName;
    if FileExists(TargetFileName) then
    begin
      if BackupFileName <> '' then
        BackupWide := BackupFileName
      else
        BackupWide := '';
      if BackupWide <> '' then
        BackupPtr := PChar(BackupWide)
      else
        BackupPtr := nil;

      if not ReplaceFile(PChar(TargetWide), PChar(SourceWide), BackupPtr,
        REPLACEFILE_WRITE_THROUGH, nil, nil) then
        RaiseLastOSError;
    end
    else if not MoveFileEx(PChar(SourceWide), PChar(TargetWide),
      MOVEFILE_REPLACE_EXISTING or MOVEFILE_WRITE_THROUGH) then
      RaiseLastOSError;

    ReplaceSucceeded := True;
  finally
    if (not ReplaceSucceeded) and FileExists(SourceFileName) then
      TFile.Delete(SourceFileName);
  end;
end;

end.
