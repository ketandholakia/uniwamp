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
    function BuildScriptFile(const Commands: TArray<string>; out ScriptFile, XmlLogFile: string): Boolean;
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

function TWinScpTransport.BuildScriptFile(const Commands: TArray<string>; out ScriptFile, XmlLogFile: string): Boolean;
var
  Lines: TStringList;
  GuidText: string;
  TempDir: string;
  CommandText: string;
begin
  Result := False;
  ScriptFile := '';
  XmlLogFile := '';
  TempDir := TPath.GetTempPath;
  GuidText := StringReplace(GUIDToString(TGUID.NewGuid), '{', '', [rfReplaceAll]);
  GuidText := StringReplace(GuidText, '}', '', [rfReplaceAll]);
  ScriptFile := TPath.Combine(TempDir, 'uniwamp-winscp-' + GuidText + '.txt');
  XmlLogFile := TPath.Combine(TempDir, 'uniwamp-winscp-' + GuidText + '.xml');
  Lines := TStringList.Create;
  try
    Lines.LineBreak := sLineBreak;
    Lines.Add('option batch abort');
    Lines.Add('option confirm off');
    Lines.Add(BuildOpenCommand);
    for CommandText in Commands do
      if Trim(CommandText) <> '' then
        Lines.Add(CommandText);
    Lines.Add('exit');
    Lines.SaveToFile(ScriptFile, TEncoding.UTF8);
    Result := True;
  finally
    Lines.Free;
  end;
end;

function TWinScpTransport.ExecuteScript(const Commands: TArray<string>; out OutputText, XmlLogFile: string): Boolean;
var
  ScriptFile: string;
  Args: string;
  Exe: string;
begin
  OutputText := '';
  XmlLogFile := '';
  Result := False;
  Exe := ResolveWinScpExecutable;
  if Exe = '' then
    raise ESyncTransportError.Create('WinSCP was not found in runtime\tools\winscp.');
  if not BuildScriptFile(Commands, ScriptFile, XmlLogFile) then
    raise ESyncTransportError.Create('Unable to prepare WinSCP script.');
  try
    Args := '/ini=nul /xmllog=' + QuoteScriptToken(XmlLogFile) + ' /xmlgroups /script=' + QuoteScriptToken(ScriptFile);
    Result := TProcessManager.RunAndCaptureOutput(Exe, Args, ResolveWorkDir, OutputText);
  finally
    if FileExists(ScriptFile) then
      TFile.Delete(ScriptFile);
  end;
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

  XmlDoc := LoadXMLDocument(XmlLogFile);
  try
    XmlDoc.Active := True;
    SessionNode := XmlDoc.DocumentElement;
    if not Assigned(SessionNode) then
      Exit(False);

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
      Exit(False);

    if Assigned(ChildNodeByName(LsNode, 'result')) and
      SameText(XmlNodeAttr(ChildNodeByName(LsNode, 'result'), 'success'), 'false') then
      Exit(False);

    FilesNode := ChildNodeByName(LsNode, 'files');
    if not Assigned(FilesNode) then
      Exit(True);

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
  finally
    XmlDoc := nil;
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
