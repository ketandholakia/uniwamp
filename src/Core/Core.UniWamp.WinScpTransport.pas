unit Core.UniWamp.WinScpTransport;

interface

uses
  System.SysUtils,
  System.Classes,
  Core.UniWamp.SyncTransport;

type
  TWinScpTransport = class(TInterfacedObject, ISyncTransport)
  private
    FCredentials: TSyncCredentials;
    FConnected: Boolean;
    FLogHandler: TSyncLogEvent;
    function ResolveWinScpExecutable: string;
    function ResolveWorkDir: string;
    function QuoteScriptToken(const Value: string): string;
    function NormalizeRemotePath(const Value: string): string;
    function RemoteDirName(const Value: string): string;
    function RemoteFileName(const Value: string): string;
    function RemoteCombine(const Left, Right: string): string;
    function BuildOpenCommand: string;
    function RunInteractiveCommands(const Commands: TArray<string>; out OutputText, XmlLogFile: string): Boolean;
    function ExecuteScript(const Commands: TArray<string>; out OutputText, XmlLogFile: string): Boolean;
    function ContainsMissingPathText(const Text: string): Boolean;
    procedure RequireConnected;
    procedure RunCommand(const Command: string);
    function TryLoadListing(const RemotePath: string; out Entries: TRemoteEntries; out OutputText: string): Boolean;
  public
    constructor Create(const Credentials: TSyncCredentials);
    procedure Connect;
    procedure Disconnect;
    function IsConnected: Boolean;

    function ListDirectory(const RemotePath: string): TRemoteEntries;
    function RemoteDirectoryExists(const RemotePath: string): Boolean;
    procedure EnsureRemoteDirectory(const RemotePath: string);
    procedure DeleteRemoteFile(const RemotePath: string);
    procedure DeleteRemoteDirectory(const RemotePath: string; const Recursive: Boolean);
    procedure RenameRemoteFile(const SourceRemotePath, TargetRemotePath: string);

    procedure DownloadFile(const RemotePath, LocalPath: string;
      const OnProgress: TSyncTransferProgressEvent);
    procedure UploadFile(const LocalPath, RemotePath: string;
      const OnProgress: TSyncTransferProgressEvent);

    procedure SetLogHandler(const Handler: TSyncLogEvent);
  end;

implementation

uses
  System.IOUtils,
  System.DateUtils,
  System.RegularExpressions,
  System.Variants,
  Xml.XMLDoc,
  Xml.XMLIntf,
  Core.UniWamp.Paths,
  Core.UniWamp.ProcessManager;

function XmlNodeText(const Parent: IXMLNode; const ChildName: string): string;
var
  Node: IXMLNode;
begin
  Result := '';
  if not Assigned(Parent) then
    Exit;
  Node := Parent.ChildNodes.FindNode(ChildName);
  if Assigned(Node) then
    Result := VarToStr(Node.Attributes['value']);
end;

function XmlNodeAttr(const Parent: IXMLNode; const AttrName: string): string;
begin
  Result := '';
  if Assigned(Parent) and Parent.HasAttribute(AttrName) then
    Result := VarToStr(Parent.Attributes[AttrName]);
end;

function ChildNodeByName(const Parent: IXMLNode; const ChildName: string): IXMLNode;
begin
  Result := nil;
  if Assigned(Parent) then
    Result := Parent.ChildNodes.FindNode(ChildName);
end;

function TryParseWinScpTimestamp(const MonthText, DayText, TimeText, YearText: string;
  out Value: TDateTime): Boolean;
var
  MonthIndex: Integer;
  DayValue: Integer;
  YearValue: Integer;
  TimeParts: TArray<string>;
  HourValue: Integer;
  MinuteValue: Integer;
  SecondValue: Integer;
  I: Integer;
begin
  Result := False;
  Value := 0;
  MonthIndex := 0;
  for I := 1 to 12 do
    if SameText(FormatSettings.ShortMonthNames[I], MonthText) then
    begin
      MonthIndex := I;
      Break;
    end;
  if MonthIndex = 0 then
    Exit;
  if not TryStrToInt(DayText, DayValue) then
    Exit;
  if not TryStrToInt(YearText, YearValue) then
    Exit;

  TimeParts := TimeText.Split([':']);
  if Length(TimeParts) <> 3 then
    Exit;
  if not TryStrToInt(TimeParts[0], HourValue) then
    Exit;
  if not TryStrToInt(TimeParts[1], MinuteValue) then
    Exit;
  if not TryStrToInt(TimeParts[2], SecondValue) then
    Exit;
  if not TryEncodeDate(YearValue, MonthIndex, DayValue, Value) then
    Exit;
  if not TryEncodeTime(HourValue, MinuteValue, SecondValue, 0, Value) then
    Exit;
  Result := True;
end;

function TryParsePlainListing(const Text: string; out Entries: TRemoteEntries): Boolean;
var
  Lines: TStringList;
  Line: string;
  LineText: string;
  Match: TMatch;
  Count: Integer;
  NameText: string;
  ModifiedTime: TDateTime;
  ParsedAnyEntry: Boolean;
begin
  Result := False;
  ParsedAnyEntry := False;
  SetLength(Entries, 0);
  if Trim(Text) = '' then
    Exit;
  if (Pos('does not exist', LowerCase(Text)) > 0) or
    (Pos('no such file', LowerCase(Text)) > 0) or
    (Pos('cannot find', LowerCase(Text)) > 0) or
    (Pos('not found', LowerCase(Text)) > 0) then
    Exit;

  Lines := TStringList.Create;
  try
    Lines.Text := Text;
    Count := 0;
    for Line in Lines do
    begin
      LineText := Trim(Line);
      if LineText = '' then
        Continue;
      Match := TRegEx.Match(LineText,
        '^(?<perm>[d-][rwx-]{9})\s+\d+\s+\S+\s+\S+\s+(?<size>\d+)\s+(?<month>[A-Za-z]{3})\s+(?<day>\d{1,2})\s+(?<time>\d{2}:\d{2}:\d{2})\s+(?<year>\d{4})\s+(?<name>.+)$',
        [roIgnoreCase]);
      if not Match.Success then
        Continue;
      NameText := Trim(Match.Groups['name'].Value);
      if (NameText = '') or SameText(NameText, '.') or SameText(NameText, '..') then
        Continue;
      if Length(Entries) <= Count then
        SetLength(Entries, Count + 8);
      Entries[Count].Name := NameText;
      Entries[Count].IsDirectory := LowerCase(Match.Groups['perm'].Value).StartsWith('d');
      Entries[Count].Size := StrToInt64Def(Match.Groups['size'].Value, 0);
      Entries[Count].ModifiedUtc := 0;
      if TryParseWinScpTimestamp(Match.Groups['month'].Value, Match.Groups['day'].Value,
        Match.Groups['time'].Value, Match.Groups['year'].Value, ModifiedTime) then
        Entries[Count].ModifiedUtc := ModifiedTime;
      Inc(Count);
      ParsedAnyEntry := True;
    end;
    SetLength(Entries, Count);
    Result := ParsedAnyEntry or
      (Pos('session started', LowerCase(Text)) > 0) or
      (Pos('active session:', LowerCase(Text)) > 0) or
      (Pos('connecting to ', LowerCase(Text)) > 0) or
      (Pos('connected', LowerCase(Text)) > 0);
  finally
    Lines.Free;
  end;
end;

constructor TWinScpTransport.Create(const Credentials: TSyncCredentials);
begin
  inherited Create;
  FCredentials := Credentials;
  FConnected := False;
end;

procedure TWinScpTransport.Connect;
begin
  if ResolveWinScpExecutable = '' then
    raise ESyncTransportError.Create('WinSCP was not found in runtime\tools\winscp.');
  FConnected := True;
end;

procedure TWinScpTransport.Disconnect;
begin
  FConnected := False;
end;

function TWinScpTransport.IsConnected: Boolean;
begin
  Result := FConnected;
end;

procedure TWinScpTransport.SetLogHandler(const Handler: TSyncLogEvent);
begin
  FLogHandler := Handler;
end;

procedure TWinScpTransport.RequireConnected;
begin
  if not FConnected then
    Connect;
end;

function TWinScpTransport.ResolveWorkDir: string;
var
  Paths: TAppPaths;
begin
  Paths := TAppPaths.Detect;
  Result := Paths.WinScpDir;
end;

function TWinScpTransport.ResolveWinScpExecutable: string;
var
  Paths: TAppPaths;
begin
  Paths := TAppPaths.Detect;
  Result := TPath.Combine(Paths.WinScpDir, 'WinSCP.com');
  if not FileExists(Result) then
    Result := TPath.Combine(Paths.WinScpDir, 'WinSCP.exe');
  if not FileExists(Result) then
    Result := '';
end;

function TWinScpTransport.QuoteScriptToken(const Value: string): string;
begin
  Result := '"' + StringReplace(Value, '"', '""', [rfReplaceAll]) + '"';
end;

function TWinScpTransport.NormalizeRemotePath(const Value: string): string;
begin
  Result := Trim(StringReplace(Value, '\', '/', [rfReplaceAll]));
  if Result = '' then
    Exit('/');
  while (Length(Result) > 1) and Result.EndsWith('/') do
    Delete(Result, Length(Result), 1);
  if Result = '' then
    Result := '/';
end;

function TWinScpTransport.RemoteDirName(const Value: string): string;
var
  PathText: string;
  Index: Integer;
begin
  PathText := NormalizeRemotePath(Value);
  Index := PathText.LastIndexOf('/');
  if Index <= 0 then
    Exit('/');
  Result := Copy(PathText, 1, Index);
  if Result = '' then
    Result := '/';
end;

function TWinScpTransport.RemoteFileName(const Value: string): string;
var
  PathText: string;
  Index: Integer;
begin
  PathText := NormalizeRemotePath(Value);
  Index := PathText.LastIndexOf('/');
  if Index < 0 then
    Exit(PathText);
  Result := Copy(PathText, Index + 2, MaxInt);
end;

function TWinScpTransport.RemoteCombine(const Left, Right: string): string;
var
  Base: string;
  Tail: string;
begin
  Base := NormalizeRemotePath(Left);
  Tail := Trim(StringReplace(Right, '\', '/', [rfReplaceAll]));
  while Tail.StartsWith('/') do
    Delete(Tail, 1, 1);
  if Base = '/' then
    Result := '/' + Tail
  else if Tail = '' then
    Result := Base
  else
    Result := Base + '/' + Tail;
end;

function TWinScpTransport.BuildOpenCommand: string;
var
  Protocol: string;
begin
  Protocol := LowerCase(Trim(FCredentials.Protocol));
  if (Protocol <> 'ftp') and (Protocol <> 'ftps') and (Protocol <> 'sftp') then
    raise ESyncTransportError.CreateFmt('Unsupported sync protocol: %s', [FCredentials.Protocol]);

  Result := Format('open %s://%s:%d/',
    [Protocol, FCredentials.Host, FCredentials.Port]);

  if Trim(FCredentials.Username) <> '' then
    Result := Result + ' -username=' + QuoteScriptToken(FCredentials.Username);
  if Trim(FCredentials.Password) <> '' then
    Result := Result + ' -password=' + QuoteScriptToken(FCredentials.Password);

  if Protocol = 'ftp' then
  begin
    if FCredentials.PassiveMode then
      Result := Result + ' -passive=on'
    else
      Result := Result + ' -passive=off';
  end
  else if Protocol = 'ftps' then
  begin
    Result := Result + ' -explicit';
    if Trim(FCredentials.TlsCertificateFingerprint) <> '' then
      Result := Result + ' -certificate=' + QuoteScriptToken(FCredentials.TlsCertificateFingerprint)
    else if FCredentials.IgnoreCertErrors then
      Result := Result + ' -certificate=*';
  end
  else if Protocol = 'sftp' then
  begin
    if Trim(FCredentials.PrivateKeyFile) <> '' then
      Result := Result + ' -privatekey=' + QuoteScriptToken(FCredentials.PrivateKeyFile);
    if Trim(FCredentials.KeyPassphrase) <> '' then
      Result := Result + ' -passphrase=' + QuoteScriptToken(FCredentials.KeyPassphrase);
    if Trim(FCredentials.SshHostKeyFingerprint) <> '' then
      Result := Result + ' -hostkey=' + QuoteScriptToken(FCredentials.SshHostKeyFingerprint)
    else
      Result := Result + ' -hostkey=*';
  end;
end;

function TWinScpTransport.RunInteractiveCommands(const Commands: TArray<string>; out OutputText, XmlLogFile: string): Boolean;
var
  Exe: string;
  Args: string;
  Session: IInteractiveProcessSession;
  StartError: string;
  CommandText: string;
begin
  OutputText := '';
  XmlLogFile := '';
  Result := False;
  Exe := ResolveWinScpExecutable;
  if Exe = '' then
    raise ESyncTransportError.Create('WinSCP was not found in runtime\tools\winscp.');

  XmlLogFile := TPath.Combine(TPath.GetTempPath,
    'uniwamp-winscp-' + StringReplace(GUIDToString(TGUID.NewGuid), '{', '', [rfReplaceAll]).Replace('}', '') + '.xml');
  Args := '/ini=nul /xmllog=' + QuoteScriptToken(XmlLogFile) + ' /xmlgroups';

  Session := TProcessManager.StartInteractive(Exe, Args, ResolveWorkDir, nil, StartError);
  if not Assigned(Session) then
  begin
    OutputText := StartError;
    Exit(False);
  end;

  try
    if not Session.SendLine('option batch abort') then
    begin
      OutputText := Session.CapturedOutput;
      Exit(False);
    end;
    if not Session.SendLine('option confirm off') then
    begin
      OutputText := Session.CapturedOutput;
      Exit(False);
    end;
    if not Session.SendLine(BuildOpenCommand) then
    begin
      OutputText := Session.CapturedOutput;
      Exit(False);
    end;
    for CommandText in Commands do
      if Trim(CommandText) <> '' then
        if not Session.SendLine(CommandText) then
        begin
          OutputText := Session.CapturedOutput;
          Exit(False);
        end;
    if not Session.SendLine('exit') then
    begin
      OutputText := Session.CapturedOutput;
      Exit(False);
    end;
    Session.CloseInput;
    if not Session.WaitForExit(120000) then
    begin
      Session.Terminate;
      OutputText := Session.CapturedOutput;
      Exit(False);
    end;
    OutputText := Session.CapturedOutput;
    Result := True;
  finally
    Session := nil;
  end;
end;

function TWinScpTransport.ExecuteScript(const Commands: TArray<string>; out OutputText, XmlLogFile: string): Boolean;
begin
  Result := RunInteractiveCommands(Commands, OutputText, XmlLogFile);
end;

function TWinScpTransport.ContainsMissingPathText(const Text: string): Boolean;
begin
  Result :=
    (Pos('does not exist', LowerCase(Text)) > 0) or
    (Pos('no such file', LowerCase(Text)) > 0) or
    (Pos('cannot find', LowerCase(Text)) > 0) or
    (Pos('not found', LowerCase(Text)) > 0);
end;

function TWinScpTransport.TryLoadListing(const RemotePath: string; out Entries: TRemoteEntries; out OutputText: string): Boolean;
var
  XmlLogFile: string;
  Commands: TArray<string>;
  XmlDoc: IXMLDocument;
  SessionNode: IXMLNode;
  Child: IXMLNode;
  LsNode: IXMLNode;
  FilesNode: IXMLNode;
  FileNode: IXMLNode;
  Count: Integer;
  NameText: string;
  TypeText: string;
  SizeText: string;
  TimeText: string;
  ModifiedTime: TDateTime;
begin
  SetLength(Entries, 0);
  Commands := TArray<string>.Create('ls ' + QuoteScriptToken(NormalizeRemotePath(RemotePath)));
  Result := ExecuteScript(Commands, OutputText, XmlLogFile);
  if not Result then
    Exit;

  try
    try
      XmlDoc := LoadXMLDocument(XmlLogFile);
      try
        XmlDoc.Active := True;
        SessionNode := XmlDoc.DocumentElement;
        if not Assigned(SessionNode) then
        begin
          Result := TryParsePlainListing(OutputText, Entries);
          Exit;
        end;

        LsNode := nil;
        for var I := 0 to SessionNode.ChildNodes.Count - 1 do
        begin
          Child := SessionNode.ChildNodes[I];
          if SameText(Child.NodeName, 'ls') then
          begin
            LsNode := Child;
            Break;
          end;
        end;
        if not Assigned(LsNode) then
        begin
          Result := TryParsePlainListing(OutputText, Entries);
          Exit;
        end;

        if Assigned(ChildNodeByName(LsNode, 'result')) and
          SameText(XmlNodeAttr(ChildNodeByName(LsNode, 'result'), 'success'), 'false') then
        begin
          Result := False;
          Exit;
        end;

        FilesNode := ChildNodeByName(LsNode, 'files');
        if not Assigned(FilesNode) then
        begin
          Result := TryParsePlainListing(OutputText, Entries);
          Exit;
        end;

        Count := 0;
        for var J := 0 to FilesNode.ChildNodes.Count - 1 do
        begin
          FileNode := FilesNode.ChildNodes[J];
          if not SameText(FileNode.NodeName, 'file') then
            Continue;
          NameText := XmlNodeText(FileNode, 'filename');
          if (NameText = '') or SameText(NameText, '.') or SameText(NameText, '..') then
            Continue;
          if Length(Entries) <= Count then
            SetLength(Entries, Count + 8);
          TypeText := LowerCase(Trim(XmlNodeText(FileNode, 'type')));
          SizeText := Trim(XmlNodeText(FileNode, 'size'));
          TimeText := Trim(XmlNodeText(FileNode, 'modification'));
          Entries[Count].Name := NameText;
          Entries[Count].IsDirectory := TypeText = 'd';
          Entries[Count].Size := StrToInt64Def(SizeText, 0);
          Entries[Count].ModifiedUtc := 0;
          if (TimeText <> '') and TryISO8601ToDate(TimeText, ModifiedTime, True) then
            Entries[Count].ModifiedUtc := ModifiedTime;
          Inc(Count);
        end;
        SetLength(Entries, Count);
        Result := True;
      finally
        XmlDoc := nil;
      end;
    except
      on E: Exception do
        Result := TryParsePlainListing(OutputText, Entries);
    end;
  finally
    if FileExists(XmlLogFile) then
      TFile.Delete(XmlLogFile);
  end;
end;

procedure TWinScpTransport.RunCommand(const Command: string);
var
  OutputText: string;
  XmlLogFile: string;
begin
  if not ExecuteScript(TArray<string>.Create(Command), OutputText, XmlLogFile) then
  begin
    if Trim(OutputText) <> '' then
      raise ESyncTransportError.Create(Trim(OutputText));
    raise ESyncTransportError.Create('WinSCP command failed.');
  end;
end;

function TWinScpTransport.ListDirectory(const RemotePath: string): TRemoteEntries;
var
  OutputText: string;
begin
  RequireConnected;
  if not TryLoadListing(RemotePath, Result, OutputText) then
  begin
    if ContainsMissingPathText(OutputText) then
      SetLength(Result, 0)
    else if Trim(OutputText) <> '' then
      raise ESyncTransportError.Create(Trim(OutputText))
    else
      raise ESyncTransportError.CreateFmt('Failed to list remote directory "%s".', [RemotePath]);
  end;
end;

function TWinScpTransport.RemoteDirectoryExists(const RemotePath: string): Boolean;
var
  Entries: TRemoteEntries;
  OutputText: string;
begin
  RequireConnected;
  Result := TryLoadListing(RemotePath, Entries, OutputText);
  if not Result and not ContainsMissingPathText(OutputText) and (Trim(OutputText) <> '') then
    raise ESyncTransportError.Create(Trim(OutputText));
end;

procedure TWinScpTransport.EnsureRemoteDirectory(const RemotePath: string);
var
  ParentPath: string;
begin
  RequireConnected;
  if (Trim(RemotePath) = '') or SameText(NormalizeRemotePath(RemotePath), '/') then
    Exit;
  if RemoteDirectoryExists(RemotePath) then
    Exit;
  ParentPath := RemoteDirName(RemotePath);
  if (ParentPath <> '') and not RemoteDirectoryExists(ParentPath) then
    EnsureRemoteDirectory(ParentPath);
  RunCommand('mkdir ' + QuoteScriptToken(NormalizeRemotePath(RemotePath)));
end;

procedure TWinScpTransport.DeleteRemoteFile(const RemotePath: string);
begin
  RequireConnected;
  RunCommand('rm ' + QuoteScriptToken(NormalizeRemotePath(RemotePath)));
end;

procedure TWinScpTransport.DeleteRemoteDirectory(const RemotePath: string; const Recursive: Boolean);
var
  Entries: TRemoteEntries;
  Entry: TRemoteEntry;
  ChildPath: string;
begin
  RequireConnected;
  if (Trim(RemotePath) = '') or SameText(NormalizeRemotePath(RemotePath), '/') then
    raise ESyncTransportError.Create('Refusing to delete the remote root directory.');

  if not Recursive then
  begin
    RunCommand('rmdir ' + QuoteScriptToken(NormalizeRemotePath(RemotePath)));
    Exit;
  end;

  Entries := ListDirectory(RemotePath);
  for Entry in Entries do
  begin
    ChildPath := RemoteCombine(RemotePath, Entry.Name);
    if Entry.IsDirectory then
      DeleteRemoteDirectory(ChildPath, True)
    else
      DeleteRemoteFile(ChildPath);
  end;
  RunCommand('rmdir ' + QuoteScriptToken(NormalizeRemotePath(RemotePath)));
end;

procedure TWinScpTransport.RenameRemoteFile(const SourceRemotePath, TargetRemotePath: string);
var
  TargetDir: string;
  TargetName: string;
  DestDirToken: string;
begin
  RequireConnected;
  TargetDir := RemoteDirName(TargetRemotePath);
  TargetName := RemoteFileName(TargetRemotePath);
  if NormalizeRemotePath(TargetDir) = '/' then
    DestDirToken := QuoteScriptToken('/')
  else
    DestDirToken := QuoteScriptToken(NormalizeRemotePath(TargetDir) + '/');
  RunCommand(Format('mv %s %s %s',
    [QuoteScriptToken(NormalizeRemotePath(SourceRemotePath)),
     DestDirToken,
     QuoteScriptToken(TargetName)]));
end;

procedure TWinScpTransport.DownloadFile(const RemotePath, LocalPath: string;
  const OnProgress: TSyncTransferProgressEvent);
var
  RemoteDir: string;
  RemoteName: string;
  OutputText: string;
  XmlLogFile: string;
begin
  RequireConnected;
  RemoteDir := RemoteDirName(RemotePath);
  RemoteName := RemoteFileName(RemotePath);
  if Trim(RemoteName) = '' then
    raise ESyncTransportError.CreateFmt('Invalid remote file path: %s', [RemotePath]);

  if not ExecuteScript(
    TArray<string>.Create(
      'cd ' + QuoteScriptToken(NormalizeRemotePath(RemoteDir)),
      'get ' + QuoteScriptToken(RemoteName) + ' ' + QuoteScriptToken(LocalPath)
    ),
    OutputText, XmlLogFile) then
  begin
    if Trim(OutputText) <> '' then
      raise ESyncTransportError.Create(Trim(OutputText));
    raise ESyncTransportError.CreateFmt('Failed to download "%s".', [RemotePath]);
  end;
end;

procedure TWinScpTransport.UploadFile(const LocalPath, RemotePath: string;
  const OnProgress: TSyncTransferProgressEvent);
var
  RemoteDir: string;
  RemoteName: string;
  OutputText: string;
  XmlLogFile: string;
begin
  RequireConnected;
  if not FileExists(LocalPath) then
    raise ESyncTransportError.CreateFmt('Local file not found: %s', [LocalPath]);

  RemoteDir := RemoteDirName(RemotePath);
  RemoteName := RemoteFileName(RemotePath);
  if Trim(RemoteName) = '' then
    RemoteName := ExtractFileName(LocalPath);
  EnsureRemoteDirectory(RemoteDir);

  if not ExecuteScript(
    TArray<string>.Create(
      'cd ' + QuoteScriptToken(NormalizeRemotePath(RemoteDir)),
      'put ' + QuoteScriptToken(LocalPath) + ' ' + QuoteScriptToken(RemoteName)
    ),
    OutputText, XmlLogFile) then
  begin
    if Trim(OutputText) <> '' then
      raise ESyncTransportError.Create(Trim(OutputText));
    raise ESyncTransportError.CreateFmt('Failed to upload "%s".', [LocalPath]);
  end;
end;

end.
