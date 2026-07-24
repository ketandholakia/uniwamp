unit Core.UniWamp.SftpTransport;

interface

uses
  System.SysUtils,
  System.Classes,
  Core.UniWamp.SyncTransport;

type
  // Native SFTP transport implemented by driving the Windows OpenSSH client.
  // This build supports agent-based auth and unencrypted private keys. Password
  // auth and encrypted-key passphrases are rejected because the bundled client
  // cannot accept them safely in non-interactive batch mode.
  TSftpTransport = class(TInterfacedObject, ISyncTransport)
  private
    FCredentials: TSyncCredentials;
    FOnLog: TSyncLogEvent;
    FConnected: Boolean;
    function ClientPath: string;
    function Destination: string;
    function NormalizeRemotePath(const RemotePath: string): string;
    function QuoteBatchArgument(const Value: string): string;
    function BuildArguments(const BatchFileName: string): string;
    function RunCommands(const Commands: array of string; out Output: string): Boolean;
    procedure RequireSupportedAuth;
    procedure RequireConnected;
    procedure Log(const Text: string);
    function ParseListOutput(const Output: string): TRemoteEntries;
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

    procedure DownloadFile(const RemotePath, LocalPath: string;
      const OnProgress: TSyncTransferProgressEvent);
    procedure UploadFile(const LocalPath, RemotePath: string;
      const OnProgress: TSyncTransferProgressEvent);

    procedure SetLogHandler(const Handler: TSyncLogEvent);
  end;

implementation

uses
  System.IOUtils,
  System.StrUtils,
  System.Generics.Collections,
  Core.UniWamp.ProcessManager;

constructor TSftpTransport.Create(const Credentials: TSyncCredentials);
begin
  inherited Create;
  FCredentials := Credentials;
  FConnected := False;
end;

procedure TSftpTransport.Log(const Text: string);
begin
  if Assigned(FOnLog) then
    FOnLog(Text);
end;

procedure TSftpTransport.SetLogHandler(const Handler: TSyncLogEvent);
begin
  FOnLog := Handler;
end;

function TSftpTransport.ClientPath: string;
const
  OpenSshPath = 'C:\Windows\System32\OpenSSH\sftp.exe';
begin
  Result := OpenSshPath;
  if not TFile.Exists(Result) then
    raise ESyncTransportError.Create('Windows OpenSSH sftp.exe was not found on this system.');
end;

function TSftpTransport.Destination: string;
begin
  if Trim(FCredentials.Username) <> '' then
    Result := FCredentials.Username + '@' + FCredentials.Host
  else
    Result := FCredentials.Host;
end;

function TSftpTransport.NormalizeRemotePath(const RemotePath: string): string;
begin
  Result := Trim(StringReplace(RemotePath, '\', '/', [rfReplaceAll]));
  if Result = '' then
    Result := '/';
  if (Length(Result) > 1) and (Result[1] <> '/') then
    Result := '/' + Result;
end;

function TSftpTransport.QuoteBatchArgument(const Value: string): string;
begin
  Result := '"' + StringReplace(Value, '"', '\"', [rfReplaceAll]) + '"';
end;

procedure TSftpTransport.RequireSupportedAuth;
begin
  if Trim(FCredentials.Password) <> '' then
    raise ESyncTransportError.Create(
      'This SFTP build uses Windows OpenSSH batch mode and does not support password authentication. ' +
      'Use an SSH key or ssh-agent.');
  if Trim(FCredentials.KeyPassphrase) <> '' then
    raise ESyncTransportError.Create(
      'This SFTP build cannot unlock encrypted private keys with a stored passphrase. ' +
      'Load the key into ssh-agent or use an unencrypted deployment key.');
  if (Trim(FCredentials.PrivateKeyFile) <> '') and not TFile.Exists(FCredentials.PrivateKeyFile) then
    raise ESyncTransportError.CreateFmt('SFTP private key not found: %s', [FCredentials.PrivateKeyFile]);
end;

function TSftpTransport.BuildArguments(const BatchFileName: string): string;
begin
  Result := '-b ' + QuoteBatchArgument(BatchFileName) + ' -oBatchMode=yes -oNumberOfPasswordPrompts=0';
  if FCredentials.Port > 0 then
    Result := Result + ' -P ' + IntToStr(FCredentials.Port);
  if Trim(FCredentials.PrivateKeyFile) <> '' then
    Result := Result + ' -i ' + QuoteBatchArgument(FCredentials.PrivateKeyFile);
  Result := Result + ' ' + QuoteBatchArgument(Destination);
end;

function TSftpTransport.RunCommands(const Commands: array of string; out Output: string): Boolean;
var
  BatchFileName: string;
  CommandText: TStringList;
  CommandTextLine: string;
begin
  RequireSupportedAuth;
  BatchFileName := TPath.ChangeExtension(TPath.GetTempFileName, '.sftp');
  CommandText := TStringList.Create;
  try
    CommandText.LineBreak := sLineBreak;
    CommandText.StrictDelimiter := False;
    for CommandTextLine in Commands do
      CommandText.Add(CommandTextLine);
    TFile.WriteAllText(BatchFileName, CommandText.Text, TEncoding.ASCII);
    Log('sftp ' + Destination);
    Result := TProcessManager.RunAndCaptureOutput(
      ClientPath,
      BuildArguments(BatchFileName),
      TPath.GetDirectoryName(ClientPath),
      Output,
      120000);
  finally
    CommandText.Free;
    try
      TFile.Delete(BatchFileName);
    except
      // best-effort temp cleanup
    end;
  end;
end;

procedure TSftpTransport.RequireConnected;
begin
  if not FConnected then
    Connect;
end;

procedure TSftpTransport.Connect;
var
  Output: string;
begin
  if FConnected then
    Exit;
  if Trim(FCredentials.Host) = '' then
    raise ESyncTransportError.Create('SFTP host is required.');

  if not RunCommands(['pwd'], Output) then
    raise ESyncTransportError.CreateFmt('SFTP connect to %s:%d failed: %s',
      [FCredentials.Host, FCredentials.Port, Trim(Output)]);

  FConnected := True;
  Log(Format('Connected to %s:%d (SFTP via OpenSSH).',
    [FCredentials.Host, FCredentials.Port]));
end;

procedure TSftpTransport.Disconnect;
begin
  FConnected := False;
end;

function TSftpTransport.IsConnected: Boolean;
begin
  Result := FConnected;
end;

function TSftpTransport.ParseListOutput(const Output: string): TRemoteEntries;
var
  Lines: TStringList;
  Entries: TList<TRemoteEntry>;
  RawLine: string;
  Line: string;
  Tokens: TArray<string>;
  Entry: TRemoteEntry;
  NameText: string;
  NameStart: Integer;
  YearOrTimeToken: string;
begin
  Lines := TStringList.Create;
  Entries := TList<TRemoteEntry>.Create;
  try
    Lines.Text := StringReplace(Output, #13, '', [rfReplaceAll]);
    for RawLine in Lines do
    begin
      Line := Trim(RawLine);
      if (Line = '') or StartsText('sftp>', Line) or StartsText('Connected to ', Line) then
        Continue;
      if not ((Line[1] = 'd') or (Line[1] = '-') or (Line[1] = 'l')) then
        Continue;

      Tokens := Line.Split([' '], TStringSplitOptions.ExcludeEmpty);
      if Length(Tokens) < 8 then
        Continue;

      Entry := Default(TRemoteEntry);
      Entry.IsDirectory := Line[1] = 'd';
      Entry.Size := StrToInt64Def(Tokens[4], 0);
      Entry.ModifiedUtc := 0;

      YearOrTimeToken := Tokens[7];
      NameStart := Pos(YearOrTimeToken, Line);
      if NameStart > 0 then
        NameText := Trim(Copy(Line, NameStart + Length(YearOrTimeToken), MaxInt))
      else
        NameText := Tokens[High(Tokens)];
      if Pos(' -> ', NameText) > 0 then
        NameText := Trim(Copy(NameText, 1, Pos(' -> ', NameText) - 1));
      Entry.Name := NameText;
      if Entry.Name <> '' then
        Entries.Add(Entry);
    end;
    Result := Entries.ToArray;
  finally
    Entries.Free;
    Lines.Free;
  end;
end;

function TSftpTransport.ListDirectory(const RemotePath: string): TRemoteEntries;
var
  Path: string;
  Output: string;
begin
  RequireConnected;
  Path := NormalizeRemotePath(RemotePath);
  if not RunCommands(['ls -ln ' + QuoteBatchArgument(Path)], Output) then
    raise ESyncTransportError.CreateFmt('SFTP LIST failed for "%s": %s', [Path, Trim(Output)]);
  Result := ParseListOutput(Output);
end;

function TSftpTransport.RemoteDirectoryExists(const RemotePath: string): Boolean;
var
  Path: string;
  Output: string;
begin
  RequireConnected;
  Path := NormalizeRemotePath(RemotePath);
  Result := RunCommands(['cd ' + QuoteBatchArgument(Path), 'pwd'], Output);
end;

procedure TSftpTransport.EnsureRemoteDirectory(const RemotePath: string);
var
  Segments: TArray<string>;
  Segment: string;
  Building: string;
  Output: string;
begin
  RequireConnected;
  Segments := NormalizeRemotePath(RemotePath).Split(['/'], TStringSplitOptions.ExcludeEmpty);
  Building := '';
  for Segment in Segments do
  begin
    Building := Building + '/' + Segment;
    if RemoteDirectoryExists(Building) then
      Continue;
    if not RunCommands(['mkdir ' + QuoteBatchArgument(Building)], Output) then
      raise ESyncTransportError.CreateFmt('Could not create remote directory "%s": %s', [Building, Trim(Output)]);
  end;
end;

procedure TSftpTransport.DeleteRemoteFile(const RemotePath: string);
var
  Path: string;
  Output: string;
begin
  RequireConnected;
  Path := NormalizeRemotePath(RemotePath);
  if not RunCommands(['rm ' + QuoteBatchArgument(Path)], Output) then
    raise ESyncTransportError.CreateFmt('Could not delete remote file "%s": %s', [Path, Trim(Output)]);
end;

procedure TSftpTransport.DeleteRemoteDirectory(const RemotePath: string; const Recursive: Boolean);
var
  Path: string;
  Output: string;
  Entry: TRemoteEntry;
  Entries: TRemoteEntries;
begin
  RequireConnected;
  Path := NormalizeRemotePath(RemotePath);
  if Recursive then
  begin
    Entries := ListDirectory(Path);
    for Entry in Entries do
    begin
      if (Entry.Name = '.') or (Entry.Name = '..') or (Entry.Name = '') then
        Continue;
      if Entry.IsDirectory then
        DeleteRemoteDirectory(Path + '/' + Entry.Name, True)
      else
        DeleteRemoteFile(Path + '/' + Entry.Name);
    end;
  end;

  if not RunCommands(['rmdir ' + QuoteBatchArgument(Path)], Output) then
    raise ESyncTransportError.CreateFmt('Could not remove remote directory "%s": %s', [Path, Trim(Output)]);
end;

procedure TSftpTransport.DownloadFile(const RemotePath, LocalPath: string;
  const OnProgress: TSyncTransferProgressEvent);
var
  RemoteFileName: string;
  TotalBytes: Int64;
  Output: string;
  Entry: TRemoteEntry;
begin
  RequireConnected;
  TDirectory.CreateDirectory(ExtractFilePath(LocalPath));
  TotalBytes := 0;
  RemoteFileName := ExtractFileName(NormalizeRemotePath(RemotePath));
  for Entry in ListDirectory(ExtractFileDir(NormalizeRemotePath(RemotePath)).Replace('\', '/')) do
    if SameText(Entry.Name, RemoteFileName) then
    begin
      TotalBytes := Entry.Size;
      Break;
    end;

  if Assigned(OnProgress) and not OnProgress(RemotePath, 0, TotalBytes, False) then
    raise ESyncTransportError.Create('Download cancelled.');
  if not RunCommands(['get ' + QuoteBatchArgument(NormalizeRemotePath(RemotePath)) + ' ' +
      QuoteBatchArgument(LocalPath)], Output) then
    raise ESyncTransportError.CreateFmt('Download failed for "%s": %s', [RemotePath, Trim(Output)]);
  if Assigned(OnProgress) then
    OnProgress(RemotePath, TFile.GetSize(LocalPath), TotalBytes, False);
end;

procedure TSftpTransport.UploadFile(const LocalPath, RemotePath: string;
  const OnProgress: TSyncTransferProgressEvent);
var
  TotalBytes: Int64;
  Output: string;
begin
  RequireConnected;
  if not TFile.Exists(LocalPath) then
    raise ESyncTransportError.CreateFmt('Local upload file not found: %s', [LocalPath]);
  EnsureRemoteDirectory(ExtractFileDir(NormalizeRemotePath(RemotePath)).Replace('\', '/'));
  TotalBytes := TFile.GetSize(LocalPath);
  if Assigned(OnProgress) and not OnProgress(RemotePath, 0, TotalBytes, True) then
    raise ESyncTransportError.Create('Upload cancelled.');
  if not RunCommands(['put ' + QuoteBatchArgument(LocalPath) + ' ' +
      QuoteBatchArgument(NormalizeRemotePath(RemotePath))], Output) then
    raise ESyncTransportError.CreateFmt('Upload failed for "%s": %s', [RemotePath, Trim(Output)]);
  if Assigned(OnProgress) then
    OnProgress(RemotePath, TotalBytes, TotalBytes, True);
end;

end.
