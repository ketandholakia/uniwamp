unit Core.UniWamp.AtomicFile;

interface

uses
  System.SysUtils;

procedure AtomicWriteTextFile(const FileName, Content: string; Encoding: TEncoding;
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
  DirectoryName: string;
  TempFileName: string;
  TempWide: string;
  TargetWide: string;
  BackupWide: string;
  BackupPtr: PChar;
  ReplaceSucceeded: Boolean;
begin
  DirectoryName := TPath.GetDirectoryName(FileName);
  if DirectoryName <> '' then
    ForceDirectories(DirectoryName);

  TempFileName := FileName + '.' + GUIDToString(TGUID.NewGuid) + '.tmp';
  WriteTextAndFlush(TempFileName, Content, Encoding);

  ReplaceSucceeded := False;
  try
    TempWide := TempFileName;
    TargetWide := FileName;
    if FileExists(FileName) then
    begin
      if BackupFileName <> '' then
        BackupWide := BackupFileName
      else
        BackupWide := '';
      if BackupWide <> '' then
        BackupPtr := PChar(BackupWide)
      else
        BackupPtr := nil;

      if not ReplaceFile(PChar(TargetWide), PChar(TempWide), BackupPtr,
        REPLACEFILE_WRITE_THROUGH, nil, nil) then
        RaiseLastOSError;
    end
    else if not MoveFileEx(PChar(TempWide), PChar(TargetWide),
      MOVEFILE_REPLACE_EXISTING or MOVEFILE_WRITE_THROUGH) then
      RaiseLastOSError;

    ReplaceSucceeded := True;
  finally
    if (not ReplaceSucceeded) and FileExists(TempFileName) then
      TFile.Delete(TempFileName);
  end;
end;

end.
