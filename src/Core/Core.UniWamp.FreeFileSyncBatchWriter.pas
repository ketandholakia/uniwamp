unit Core.UniWamp.FreeFileSyncBatchWriter;

interface

uses
  Winapi.Windows,
  System.SysUtils,
  System.Classes,
  System.IOUtils,
  System.Generics.Collections,
  System.NetEncoding,
  Core.UniWamp.Config,
  Core.UniWamp.SyncTypes;

type
  // Encapsulates the data needed to build an .ffs_gui file.
  TFreeFileSyncJobSpec = record
    LocalPath: string;      // Full local directory path
    RemotePath: string;     // POSIX-style remote path (e.g. /home/user/public_html)
    Credentials: TSyncCredentials;
    Password: string;       // sync password, used for GUI pass64 URLs
    Direction: string;      // 'upload' | 'download'
    SyncVariant: string;    // 'update' | 'mirror' | 'twoway'  (default: 'update')
    DeleteEnabled: Boolean;
    Excludes: TArray<string>;
    LogFilePath: string;    // Where FFS should write its log (empty = no log)
  end;

  TFreeFileSyncBatchWriter = class
  private
    class function BuildRemoteUrl(const Credentials: TSyncCredentials;
      const RemotePath, Password: string): string; static;
    class function BuildExcludeBlock(const Excludes: TArray<string>): string; static;
    class function EscapeXml(const Value: string): string; static;
    class function QuoteForXml(const Path: string): string; static;
  public
    // Writes an .ffs_gui file (opens the FreeFileSync GUI) to GuiFilePath.
    class procedure WriteGuiFile(const Spec: TFreeFileSyncJobSpec;
      const GuiFilePath: string); static;

    // Writes an .ffs_batch file (for unattended batch execution) to BatchFilePath.
    class procedure WriteBatchFile(const Spec: TFreeFileSyncJobSpec;
      const BatchFilePath: string); static;

    // Resolves the FreeFileSync executable, searching bundled location then system.
    class function ResolveFreeFileSyncExe(const FreeFileSyncDir: string): string; static;
  end;

implementation

class function TFreeFileSyncBatchWriter.EscapeXml(const Value: string): string;
begin
  Result := Value;
  Result := StringReplace(Result, '&',  '&' + 'amp;',  [rfReplaceAll]);
  Result := StringReplace(Result, '<',  '&' + 'lt;',   [rfReplaceAll]);
  Result := StringReplace(Result, '>',  '&' + 'gt;',   [rfReplaceAll]);
  Result := StringReplace(Result, '"',  '&' + 'quot;', [rfReplaceAll]);
  Result := StringReplace(Result, '''', '&' + 'apos;', [rfReplaceAll]);
end;

class function TFreeFileSyncBatchWriter.QuoteForXml(const Path: string): string;
begin
  Result := EscapeXml(Path);
end;

class function TFreeFileSyncBatchWriter.BuildRemoteUrl(const Credentials: TSyncCredentials;
  const RemotePath, Password: string): string;
var
  Protocol: string;
  UserPart: string;
  HostPart: string;
  PathPart: string;
  PasswordPart: string;
begin
  Protocol := LowerCase(Trim(Credentials.Protocol));
  if (Protocol <> 'ftp') and (Protocol <> 'ftps') and (Protocol <> 'sftp') then
    Protocol := 'ftp';

  if Protocol = 'ftps' then
    Protocol := 'ftp';

  UserPart := '';
  if Trim(Credentials.Username) <> '' then
    UserPart := EscapeXml(Credentials.Username) + '@';

  HostPart := EscapeXml(Trim(Credentials.Host));
  if Credentials.Port > 0 then
    HostPart := HostPart + ':' + IntToStr(Credentials.Port);

  PathPart := Trim(StringReplace(RemotePath, '\', '/', [rfReplaceAll]));
  if (PathPart <> '') and not PathPart.StartsWith('/') then
    PathPart := '/' + PathPart;

  PasswordPart := '';
  if Trim(Password) <> '' then
    PasswordPart := '|pass64=' + TNetEncoding.Base64.Encode(Trim(Password));

  Result := Protocol + '://' + UserPart + HostPart + PathPart + PasswordPart;
end;

class function TFreeFileSyncBatchWriter.BuildExcludeBlock(
  const Excludes: TArray<string>): string;
var
  SB: TStringBuilder;
  Pattern: string;
  First: Boolean;
begin
  if Length(Excludes) = 0 then
  begin
    Result := '';
    Exit;
  end;
  SB := TStringBuilder.Create;
  try
    First := True;
    for Pattern in Excludes do
    begin
      if Trim(Pattern) = '' then
        Continue;
      if not First then
        SB.Append(#10);
      SB.Append('            <Item>' + EscapeXml(StringReplace(Trim(Pattern), '/', '\', [rfReplaceAll])) + '</Item>');
      First := False;
    end;
    Result := SB.ToString;
  finally
    SB.Free;
  end;
end;

class procedure TFreeFileSyncBatchWriter.WriteGuiFile(
  const Spec: TFreeFileSyncJobSpec; const GuiFilePath: string);
var
  SB: TStringBuilder;
  LeftPath: string;
  RightPath: string;
  ExcludeBlock: string;
  RemoteUrl: string;
  VariantStr: string;
begin
  RemoteUrl := BuildRemoteUrl(Spec.Credentials, Spec.RemotePath, Spec.Password);
  ExcludeBlock := BuildExcludeBlock(Spec.Excludes);

  if SameText(Spec.Direction, 'download') then
  begin
    LeftPath  := RemoteUrl;
    RightPath := QuoteForXml(Spec.LocalPath);
  end
  else
  begin
    LeftPath  := QuoteForXml(Spec.LocalPath);
    RightPath := RemoteUrl;
  end;

  VariantStr := LowerCase(Trim(Spec.SyncVariant));
  if VariantStr = 'mirror' then
    VariantStr := 'Mirror'
  else if VariantStr = 'twoway' then
    VariantStr := 'TwoWay'
  else
    VariantStr := 'Update';

  SB := TStringBuilder.Create;
  try
    SB.AppendLine('<?xml version="1.0" encoding="UTF-8"?>');
    SB.AppendLine('<FreeFileSync XmlType="GUI" XmlFormat="23">');
    SB.AppendLine('    <Notes/>');
    SB.AppendLine('    <Compare>');
    SB.AppendLine('        <Variant>TimeAndSize</Variant>');
    SB.AppendLine('        <Symlinks>Exclude</Symlinks>');
    SB.AppendLine('        <IgnoreTimeShift/>');
    SB.AppendLine('    </Compare>');
    SB.AppendLine('    <Synchronize>');
    SB.AppendLine('        <Changes>');
    if VariantStr = 'Mirror' then
    begin
      SB.AppendLine('            <Left Create="right" Update="right" Delete="right"/>');
      SB.AppendLine('            <Right Create="none" Update="none" Delete="none"/>');
    end
    else if VariantStr = 'TwoWay' then
    begin
      SB.AppendLine('            <Left Create="right" Update="right" Delete="right"/>');
      SB.AppendLine('            <Right Create="left" Update="left" Delete="left"/>');
    end
    else
    begin
      if Spec.DeleteEnabled then
        SB.AppendLine('            <Left Create="right" Update="right" Delete="right"/>')
      else
        SB.AppendLine('            <Left Create="right" Update="right" Delete="none"/>');
      SB.AppendLine('            <Right Create="none" Update="none" Delete="none"/>');
    end;
    SB.AppendLine('        </Changes>');
    SB.AppendLine('        <DeletionPolicy>Permanent</DeletionPolicy>');
    SB.AppendLine('        <VersioningFolder Style="Replace"/>');
    SB.AppendLine('    </Synchronize>');
    SB.AppendLine('    <Filter>');
    SB.AppendLine('        <Include>');
    SB.AppendLine('            <Item>*</Item>');
    SB.AppendLine('        </Include>');
    if ExcludeBlock <> '' then
    begin
      SB.AppendLine('        <Exclude>');
      SB.AppendLine(ExcludeBlock);
      SB.AppendLine('        </Exclude>');
    end
    else
      SB.AppendLine('        <Exclude/>');
    SB.AppendLine('        <SizeMin Unit="None">0</SizeMin>');
    SB.AppendLine('        <SizeMax Unit="None">0</SizeMax>');
    SB.AppendLine('        <TimeSpan Type="None">0</TimeSpan>');
    SB.AppendLine('    </Filter>');
    SB.AppendLine('    <FolderPairs>');
    SB.AppendLine('        <Pair>');
    SB.AppendLine('            <Left>' + LeftPath + '</Left>');
    SB.AppendLine('            <Right>' + RightPath + '</Right>');
    SB.AppendLine('        </Pair>');
    SB.AppendLine('    </FolderPairs>');
    SB.AppendLine('    <Errors Ignore="false" Retry="0" Delay="5"/>');
    SB.AppendLine('    <PostSyncCommand Condition="Completion"/>');
    SB.AppendLine('    <LogFolder/>');
    SB.AppendLine('    <EmailNotification Condition="Always"/>');
    SB.AppendLine('    <GridViewType>Action</GridViewType>');
    SB.AppendLine('</FreeFileSync>');

    TDirectory.CreateDirectory(ExtractFileDir(GuiFilePath));
    TFile.WriteAllText(GuiFilePath, SB.ToString, TEncoding.UTF8);
  finally
    SB.Free;
  end;
end;

class procedure TFreeFileSyncBatchWriter.WriteBatchFile(
  const Spec: TFreeFileSyncJobSpec; const BatchFilePath: string);
var
  SB: TStringBuilder;
  LeftPath: string;
  RightPath: string;
  ExcludeBlock: string;
  RemoteUrl: string;
  VariantStr: string;
begin
  RemoteUrl := BuildRemoteUrl(Spec.Credentials, Spec.RemotePath, Spec.Password);
  ExcludeBlock := BuildExcludeBlock(Spec.Excludes);

  if SameText(Spec.Direction, 'download') then
  begin
    LeftPath  := RemoteUrl;
    RightPath := QuoteForXml(Spec.LocalPath);
  end
  else
  begin
    LeftPath  := QuoteForXml(Spec.LocalPath);
    RightPath := RemoteUrl;
  end;

  VariantStr := LowerCase(Trim(Spec.SyncVariant));
  if VariantStr = 'mirror' then
    VariantStr := 'Mirror'
  else if VariantStr = 'twoway' then
    VariantStr := 'TwoWay'
  else
    VariantStr := 'Update';

  SB := TStringBuilder.Create;
  try
    SB.AppendLine('<?xml version="1.0" encoding="UTF-8"?>');
    SB.AppendLine('<FreeFileSync XmlType="Batch" XmlFormat="23">');
    SB.AppendLine('    <Notes/>');
    SB.AppendLine('    <Compare>');
    SB.AppendLine('        <Variant>TimeAndSize</Variant>');
    SB.AppendLine('        <Symlinks>Exclude</Symlinks>');
    SB.AppendLine('        <IgnoreTimeShift/>');
    SB.AppendLine('    </Compare>');
    SB.AppendLine('    <Synchronize>');
    SB.AppendLine('        <Changes>');
    if VariantStr = 'Mirror' then
    begin
      SB.AppendLine('            <Left Create="right" Update="right" Delete="right"/>');
      SB.AppendLine('            <Right Create="none" Update="none" Delete="none"/>');
    end
    else if VariantStr = 'TwoWay' then
    begin
      SB.AppendLine('            <Left Create="right" Update="right" Delete="right"/>');
      SB.AppendLine('            <Right Create="left" Update="left" Delete="left"/>');
    end
    else
    begin
      if Spec.DeleteEnabled then
        SB.AppendLine('            <Left Create="right" Update="right" Delete="right"/>')
      else
        SB.AppendLine('            <Left Create="right" Update="right" Delete="none"/>');
      SB.AppendLine('            <Right Create="none" Update="none" Delete="none"/>');
    end;
    SB.AppendLine('        </Changes>');
    SB.AppendLine('        <DeletionPolicy>Permanent</DeletionPolicy>');
    SB.AppendLine('        <VersioningFolder Style="Replace"/>');
    SB.AppendLine('    </Synchronize>');
    SB.AppendLine('    <Filter>');
    SB.AppendLine('        <Include>');
    SB.AppendLine('            <Item>*</Item>');
    SB.AppendLine('        </Include>');
    if ExcludeBlock <> '' then
    begin
      SB.AppendLine('        <Exclude>');
      SB.AppendLine(ExcludeBlock);
      SB.AppendLine('        </Exclude>');
    end
    else
      SB.AppendLine('        <Exclude/>');
    SB.AppendLine('        <SizeMin Unit="None">0</SizeMin>');
    SB.AppendLine('        <SizeMax Unit="None">0</SizeMax>');
    SB.AppendLine('        <TimeSpan Type="None">0</TimeSpan>');
    SB.AppendLine('    </Filter>');
    SB.AppendLine('    <FolderPairs>');
    SB.AppendLine('        <Pair>');
    SB.AppendLine('            <Left>' + LeftPath + '</Left>');
    SB.AppendLine('            <Right>' + RightPath + '</Right>');
    SB.AppendLine('        </Pair>');
    SB.AppendLine('    </FolderPairs>');
    SB.AppendLine('    <Errors Ignore="false" Retry="0" Delay="5"/>');
    if Spec.LogFilePath <> '' then
    begin
      SB.AppendLine('    <LogFolder>' + QuoteForXml(Spec.LogFilePath) + '</LogFolder>');
    end
    else
    begin
      SB.AppendLine('    <LogFolder/>');
    end;
    SB.AppendLine('    <PostSyncCommand Condition="Completion"/>');
    SB.AppendLine('    <EmailNotification Condition="Always"/>');
    SB.AppendLine('</FreeFileSync>');

    TDirectory.CreateDirectory(ExtractFileDir(BatchFilePath));
    TFile.WriteAllText(BatchFilePath, SB.ToString, TEncoding.UTF8);
  finally
    SB.Free;
  end;
end;

class function TFreeFileSyncBatchWriter.ResolveFreeFileSyncExe(
  const FreeFileSyncDir: string): string;
const
  SystemPaths: array[0..2] of string = (
    'C:\Program Files\FreeFileSync\FreeFileSync.exe',
    'C:\Program Files (x86)\FreeFileSync\FreeFileSync.exe',
    'FreeFileSync.exe'
  );
var
  Candidate: string;
  Buffer: array[0..MAX_PATH] of Char;
  BufferSize: DWORD;
  FilePart: PChar;
begin
  if FreeFileSyncDir <> '' then
  begin
    Candidate := TPath.Combine(FreeFileSyncDir, 'FreeFileSync.exe');
    if FileExists(Candidate) then
    begin
      Result := Candidate;
      Exit;
    end;
  end;

  for Candidate in SystemPaths do
  begin
    if Pos('\', Candidate) > 0 then
    begin
      if FileExists(Candidate) then
      begin
        Result := Candidate;
        Exit;
      end;
    end
    else
    begin
      FilePart := nil;
      BufferSize := SearchPath(nil, PChar(Candidate), nil, Length(Buffer), Buffer, FilePart);
      if BufferSize > 0 then
      begin
        Result := Buffer;
        Exit;
      end;
    end;
  end;

  Result := '';
end;

end.
