unit Core.UniWamp.SftpTransport;

interface

uses
  System.SysUtils,
  System.Classes,
  Core.UniWamp.SyncTransport;

type
  // Native SFTP transport implemented with two backends:
  // - PuTTY PSFTP for password-based authentication
  // - Windows OpenSSH sftp.exe for agent-based or unencrypted-key auth
  TSftpTransport = class(TInterfacedObject, ISyncTransport)
  private
    FCredentials: TSyncCredentials;
    FOnLog: TSyncLogEvent;
    FConnected: Boolean;
    FRemoteBaseDir: string;
    function UsePsftpBackend: Boolean;
    function Destination: string;
    function CanonicalizeRemotePath(const RemotePath: string): string;
    function ApplyRemoteBasePath(const RemotePath: string): string;
    function NormalizeRemotePath(const RemotePath: string): string;
    function QuoteBatchArgument(const Value: string): string;
    function OpenSshClientPath: string;
    function BundledPsftpPath: string;
    function PsftpClientPath: string;
    function WinScpClientPath: string;
    function SshKeyScanPath: string;
    function SshKeyGenPath: string;
    function ExtractWorkingDirectory(const Output: string): string;
    function BuildOpenSshArguments(const BatchFileName: string): string;
    function BuildWinScpOpenCommand: string;
    function ResolvePsftpHostKeyFingerprint: string;
    function RunOpenSshCommands(const Commands: array of string; out Output: string): Boolean;
    function RunPsftpCommands(const Commands: array of string; out Output: string): Boolean;
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
    procedure RenameRemoteFile(const SourceRemotePath, TargetRemotePath: string);

    procedure DownloadFile(const RemotePath, LocalPath: string;
      const OnProgress: TSyncTransferProgressEvent);
    procedure UploadFile(const LocalPath, RemotePath: string;
      const OnProgress: TSyncTransferProgressEvent);

    procedure SetLogHandler(const Handler: TSyncLogEvent);
  end;

implementation

uses
  Winapi.Windows,
  System.IOUtils,
  System.StrUtils,
  System.DateUtils,
  System.Generics.Collections,
  Core.UniWamp.ProcessManager,
  Core.UniWamp.Paths;

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

function TSftpTransport.UsePsftpBackend: Boolean;
begin
  Result := Trim(FCredentials.Password) <> '';
end;

function TSftpTransport.OpenSshClientPath: string;
const
  OpenSshPath = 'C:\Windows\System32\OpenSSH\sftp.exe';
begin
  Result := OpenSshPath;
  if not TFile.Exists(Result) then
    raise ESyncTransportError.Create('Windows OpenSSH sftp.exe was not found on this system.');
end;

function TSftpTransport.BundledPsftpPath: string;
begin
  Result := TPath.Combine(TAppPaths.Detect.PuttyDir, 'psftp.exe');
end;

function TSftpTransport.PsftpClientPath: string;
var
  Buffer: array[0..MAX_PATH * 2 - 1] of Char;
  FilePart: PChar;
  BufferSize: DWORD;
begin
  Result := BundledPsftpPath;
  if TFile.Exists(Result) then
    Exit;

  BufferSize := SearchPath(nil, 'psftp.exe', nil, Length(Buffer), Buffer, FilePart);
  if BufferSize > 0 then
  begin
    Result := Buffer;
    Exit;
  end;

  raise ESyncTransportError.Create(
    'SFTP password authentication requires PuTTY PSFTP in runtime\\tools\\putty or on PATH.');
end;

function TSftpTransport.WinScpClientPath: string;
var
  Candidate: string;
begin
  Candidate := TPath.Combine(TAppPaths.Detect.WinScpDir, 'WinSCP.com');
  if TFile.Exists(Candidate) then
    Exit(Candidate);
  Candidate := TPath.Combine(TAppPaths.Detect.WinScpDir, 'WinSCP.exe');
  if TFile.Exists(Candidate) then
    Exit(Candidate);
  raise ESyncTransportError.Create('WinSCP was not found in runtime\\tools\\winscp.');
end;

function TSftpTransport.SshKeyScanPath: string;
const
  KeyScanPath = 'C:\Windows\System32\OpenSSH\ssh-keyscan.exe';
begin
  Result := KeyScanPath;
  if not TFile.Exists(Result) then
    raise ESyncTransportError.Create(
      'SFTP host-key discovery requires Windows OpenSSH ssh-keyscan.exe.');
end;

function TSftpTransport.SshKeyGenPath: string;
const
  KeyGenPath = 'C:\Windows\System32\OpenSSH\ssh-keygen.exe';
begin
  Result := KeyGenPath;
  if not TFile.Exists(Result) then
    raise ESyncTransportError.Create(
      'SFTP host-key discovery requires Windows OpenSSH ssh-keygen.exe.');
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
  Result := ApplyRemoteBasePath(CanonicalizeRemotePath(RemotePath));
end;

function TSftpTransport.CanonicalizeRemotePath(const RemotePath: string): string;
begin
  Result := Trim(StringReplace(RemotePath, '\', '/', [rfReplaceAll]));
  if Result = '' then
    Result := '/';
  if (Length(Result) > 1) and (Result[1] <> '/') then
    Result := '/' + Result;
end;

function TSftpTransport.ApplyRemoteBasePath(const RemotePath: string): string;
var
  BasePath: string;
  WorkPath: string;
  NextSlash: Integer;
  Mapped: Boolean;
  PublicHtmlPos: Integer;
begin
  Result := RemotePath;
  Mapped := False;
  PublicHtmlPos := Pos('/public_html/', Result);
  if PublicHtmlPos > 0 then
    Exit(Copy(Result, PublicHtmlPos + Length('/public_html/'), MaxInt));
  BasePath := Trim(StringReplace(FRemoteBaseDir, '\', '/', [rfReplaceAll]));
  if (BasePath <> '') and (BasePath <> '/') then
  begin
    if (Length(BasePath) > 1) and BasePath.EndsWith('/') then
      Delete(BasePath, Length(BasePath), 1);
    if SameText(Result, BasePath) then
      Exit('/');
    if StartsText(BasePath + '/', Result) then
    begin
      Result := '/' + Copy(Result, Length(BasePath) + 2, MaxInt);
      Mapped := True;
    end;
  end;
  if (not Mapped) and StartsText('/home/', Result) then
  begin
    WorkPath := Result;
    NextSlash := PosEx('/', WorkPath, Length('/home/') + 1);
    if NextSlash > 0 then
      Result := Copy(WorkPath, NextSlash, MaxInt);
  end;
end;

function TSftpTransport.ExtractWorkingDirectory(const Output: string): string;
var
  Lines: TStringList;
  RawLine: string;
  Line: string;
  PathText: string;
  ColonPos: Integer;
begin
  Result := '';
  Lines := TStringList.Create;
  try
    Lines.Text := StringReplace(Output, #13, '', [rfReplaceAll]);
    for RawLine in Lines do
    begin
      Line := Trim(RawLine);
      if Line = '' then
        Continue;
      if StartsText('Remote working directory is ', Line) then
        Exit(Trim(Copy(Line, Length('Remote working directory is ') + 1, MaxInt)));
      if StartsText('Remote working directory:', Line) then
      begin
        ColonPos := Pos(':', Line);
        if ColonPos > 0 then
          Exit(Trim(Copy(Line, ColonPos + 1, MaxInt)));
      end;
      if StartsText('Remote directory is ', Line) then
        Exit(Trim(Copy(Line, Length('Remote directory is ') + 1, MaxInt)));
      if StartsText('pwd', Line) and (Pos(':', Line) > 0) then
      begin
        ColonPos := Pos(':', Line);
        PathText := Trim(Copy(Line, ColonPos + 1, MaxInt));
        if PathText <> '' then
          Exit(PathText);
      end;
      Result := Line;
    end;
  finally
    Lines.Free;
  end;
end;

function TSftpTransport.QuoteBatchArgument(const Value: string): string;
begin
  Result := '"' + StringReplace(Value, '"', '\"', [rfReplaceAll]) + '"';
end;

procedure TSftpTransport.RequireSupportedAuth;
begin
  if (Trim(FCredentials.PrivateKeyFile) <> '') and not TFile.Exists(FCredentials.PrivateKeyFile) then
    raise ESyncTransportError.CreateFmt('SFTP private key not found: %s', [FCredentials.PrivateKeyFile]);

  if UsePsftpBackend then
  begin
    if Trim(FCredentials.KeyPassphrase) <> '' then
      raise ESyncTransportError.Create(
        'This SFTP build cannot unlock encrypted private keys with a stored passphrase. ' +
        'Use a password-based session, ssh-agent, or an unencrypted deployment key.');
    WinScpClientPath;
    Exit;
  end;

  if Trim(FCredentials.KeyPassphrase) <> '' then
    raise ESyncTransportError.Create(
      'This SFTP build cannot unlock encrypted private keys with a stored passphrase. ' +
      'Load the key into ssh-agent or use an unencrypted deployment key.');
  OpenSshClientPath;
end;

function TSftpTransport.BuildOpenSshArguments(const BatchFileName: string): string;
begin
  Result := '-b ' + QuoteBatchArgument(BatchFileName) + ' -oBatchMode=yes -oNumberOfPasswordPrompts=0';
  if FCredentials.Port > 0 then
    Result := Result + ' -P ' + IntToStr(FCredentials.Port);
  if Trim(FCredentials.PrivateKeyFile) <> '' then
    Result := Result + ' -i ' + QuoteBatchArgument(FCredentials.PrivateKeyFile);
  Result := Result + ' ' + QuoteBatchArgument(Destination);
end;

function TSftpTransport.BuildWinScpOpenCommand: string;
begin
  Result := Format('open sftp://%s:%d/', [FCredentials.Host, FCredentials.Port]);
  if Trim(FCredentials.Username) <> '' then
    Result := Result + ' -username=' + QuoteBatchArgument(FCredentials.Username);
  if Trim(FCredentials.Password) <> '' then
    Result := Result + ' -password=' + QuoteBatchArgument(FCredentials.Password);
  if Trim(FCredentials.PrivateKeyFile) <> '' then
    Result := Result + ' -privatekey=' + QuoteBatchArgument(FCredentials.PrivateKeyFile);
  if Trim(FCredentials.SshHostKeyFingerprint) <> '' then
    Result := Result + ' -hostkey=' + QuoteBatchArgument(FCredentials.SshHostKeyFingerprint)
  else
    Result := Result + ' -hostkey=*';
end;

function TSftpTransport.ResolvePsftpHostKeyFingerprint: string;
var
  KeyFileName: string;
  ScanOutput: string;
  FingerprintOutput: string;
  Lines: TStringList;
  Line: string;
begin
  KeyFileName := TPath.ChangeExtension(TPath.GetTempFileName, '.pub');
  try
    if not TProcessManager.RunAndCaptureOutput(
      SshKeyScanPath,
      '-p ' + IntToStr(FCredentials.Port) + ' ' + FCredentials.Host,
      TPath.GetDirectoryName(SshKeyScanPath),
      ScanOutput,
      30000) then
      raise ESyncTransportError.CreateFmt('Could not fetch SSH host key for %s:%d: %s',
        [FCredentials.Host, FCredentials.Port, Trim(ScanOutput)]);

    TFile.WriteAllText(KeyFileName, ScanOutput, TEncoding.ASCII);
    if not TProcessManager.RunAndCaptureOutput(
      SshKeyGenPath,
      '-lf ' + QuoteBatchArgument(KeyFileName) + ' -E sha256',
      TPath.GetDirectoryName(SshKeyGenPath),
      FingerprintOutput,
      30000) then
      raise ESyncTransportError.CreateFmt('Could not calculate SSH host fingerprint for %s:%d: %s',
        [FCredentials.Host, FCredentials.Port, Trim(FingerprintOutput)]);

    Lines := TStringList.Create;
    try
      Lines.Text := StringReplace(FingerprintOutput, #13, '', [rfReplaceAll]);
      for Line in Lines do
        if ContainsText(Line, '(ED25519)') and ContainsText(Line, 'SHA256:') then
          Exit(Line.Split([' '], TStringSplitOptions.ExcludeEmpty)[1]);
      for Line in Lines do
        if ContainsText(Line, '(ECDSA)') and ContainsText(Line, 'SHA256:') then
          Exit(Line.Split([' '], TStringSplitOptions.ExcludeEmpty)[1]);
      for Line in Lines do
        if ContainsText(Line, '(RSA)') and ContainsText(Line, 'SHA256:') then
          Exit(Line.Split([' '], TStringSplitOptions.ExcludeEmpty)[1]);
    finally
      Lines.Free;
    end;
  finally
    try
      TFile.Delete(KeyFileName);
    except
      // best-effort temp cleanup
    end;
  end;

  raise ESyncTransportError.CreateFmt('No usable SSH host-key fingerprint was returned for %s:%d.',
    [FCredentials.Host, FCredentials.Port]);
end;

function TSftpTransport.RunOpenSshCommands(const Commands: array of string; out Output: string): Boolean;
var
  BatchFileName: string;
  CommandText: TStringList;
  CommandTextLine: string;
begin
  BatchFileName := TPath.ChangeExtension(TPath.GetTempFileName, '.sftp');
  CommandText := TStringList.Create;
  try
    for CommandTextLine in Commands do
      CommandText.Add(CommandTextLine);
    TFile.WriteAllText(BatchFileName, CommandText.Text, TEncoding.ASCII);
    Log('sftp ' + Destination);
    Result := TProcessManager.RunAndCaptureOutput(
      OpenSshClientPath,
      BuildOpenSshArguments(BatchFileName),
      TPath.GetDirectoryName(OpenSshClientPath),
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

function TSftpTransport.RunPsftpCommands(const Commands: array of string; out Output: string): Boolean;
var
  Exe: string;
  Args: string;
  Session: IInteractiveProcessSession;
  StartError: string;
  CommandText: string;
begin
  Output := '';
  Exe := WinScpClientPath;
  Args := '/ini=nul /xmlgroups';
  Session := TProcessManager.StartInteractive(Exe, Args, TPath.GetDirectoryName(Exe), nil, StartError);
  if not Assigned(Session) then
  begin
    Output := StartError;
    Exit(False);
  end;

  try
    if not Session.SendLine('option batch abort') then
    begin
      Output := Session.CapturedOutput;
      Exit(False);
    end;
    if not Session.SendLine('option confirm off') then
    begin
      Output := Session.CapturedOutput;
      Exit(False);
    end;
    if not Session.SendLine(BuildWinScpOpenCommand) then
    begin
      Output := Session.CapturedOutput;
      Exit(False);
    end;
    for CommandText in Commands do
      if Trim(CommandText) <> '' then
        if not Session.SendLine(CommandText) then
        begin
          Output := Session.CapturedOutput;
          Exit(False);
        end;
    if not Session.SendLine('exit') then
    begin
      Output := Session.CapturedOutput;
      Exit(False);
    end;
    Session.CloseInput;
    if not Session.WaitForExit(120000) then
    begin
      Session.Terminate;
      Output := Session.CapturedOutput;
      Exit(False);
    end;
    Output := Session.CapturedOutput;
    Log('winscp ' + Destination);
    Result := True;
  finally
    Session := nil;
  end;
end;

function TSftpTransport.RunCommands(const Commands: array of string; out Output: string): Boolean;
begin
  RequireSupportedAuth;
  if UsePsftpBackend then
    Result := RunPsftpCommands(Commands, Output)
  else
    Result := RunOpenSshCommands(Commands, Output);
end;

procedure TSftpTransport.RequireConnected;
begin
  if not FConnected then
    Connect;
end;

procedure TSftpTransport.Connect;
var
  Output: string;
  BackendName: string;
begin
  if FConnected then
    Exit;
  if Trim(FCredentials.Host) = '' then
    raise ESyncTransportError.Create('SFTP host is required.');

  if not RunCommands(['pwd'], Output) then
    raise ESyncTransportError.CreateFmt('SFTP connect to %s:%d failed: %s',
      [FCredentials.Host, FCredentials.Port, Trim(Output)]);
  FRemoteBaseDir := CanonicalizeRemotePath(ExtractWorkingDirectory(Output));

  if UsePsftpBackend then
    BackendName := 'WinSCP'
  else
    BackendName := 'OpenSSH';
  FConnected := True;
  Log(Format('Connected to %s:%d (SFTP via %s).',
    [FCredentials.Host, FCredentials.Port, BackendName]));
end;

procedure TSftpTransport.Disconnect;
begin
  FConnected := False;
  FRemoteBaseDir := '';
end;

function TSftpTransport.IsConnected: Boolean;
begin
  Result := FConnected;
end;

function TSftpTransport.ParseListOutput(const Output: string): TRemoteEntries;
  function MonthIndexFromToken(const Token: string): Integer;
  const
    MonthTokens: array[1..12] of string = (
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec');
  var
    I: Integer;
  begin
    Result := 0;
    for I := Low(MonthTokens) to High(MonthTokens) do
      if SameText(Token, MonthTokens[I]) then
        Exit(I);
  end;

  function TryParseModifiedUtc(const Tokens: TArray<string>; out ModifiedUtc: TDateTime): Boolean;
  var
    MonthIndex: Integer;
    DayValue: Integer;
    YearValue: Integer;
    HourValue: Integer;
    MinuteValue: Integer;
    CurrentYear: Integer;
  begin
    Result := False;
    ModifiedUtc := 0;
    if Length(Tokens) < 8 then
      Exit;
    MonthIndex := MonthIndexFromToken(Tokens[5]);
    if MonthIndex = 0 then
      Exit;
    DayValue := StrToIntDef(Tokens[6], 0);
    if DayValue = 0 then
      Exit;
    if Pos(':', Tokens[7]) > 0 then
    begin
      CurrentYear := YearOf(Now);
      if not TryStrToInt(Copy(Tokens[7], 1, Pos(':', Tokens[7]) - 1), HourValue) then
        Exit;
      if not TryStrToInt(Copy(Tokens[7], Pos(':', Tokens[7]) + 1, MaxInt), MinuteValue) then
        Exit;
      ModifiedUtc := EncodeDateTime(CurrentYear, MonthIndex, DayValue, HourValue, MinuteValue, 0, 0);
      Result := True;
      Exit;
    end;
    if not TryStrToInt(Tokens[7], YearValue) then
      Exit;
    ModifiedUtc := EncodeDateTime(YearValue, MonthIndex, DayValue, 0, 0, 0, 0);
    Result := True;
  end;

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
  I: Integer;
begin
  Lines := TStringList.Create;
  Entries := TList<TRemoteEntry>.Create;
  try
    Lines.Text := StringReplace(Output, #13, '', [rfReplaceAll]);
    for RawLine in Lines do
    begin
      Line := Trim(RawLine);
      if Line = '' then
        Continue;
      if StartsText('sftp>', Line) or StartsText('Connected to ', Line) or
         StartsText('Using username ', Line) or StartsText('Remote working directory is ', Line) or
         StartsText('Remote directory is ', Line) or StartsText('Listing directory ', Line) then
        Continue;
      if not ((Line[1] = 'd') or (Line[1] = '-') or (Line[1] = 'l')) then
        Continue;

      Tokens := Line.Split([' '], TStringSplitOptions.ExcludeEmpty);
      if Length(Tokens) < 8 then
        Continue;

      Entry := Default(TRemoteEntry);
      Entry.IsDirectory := Line[1] = 'd';
      Entry.Size := StrToInt64Def(Tokens[4], 0);
      if not TryParseModifiedUtc(Tokens, Entry.ModifiedUtc) then
        Entry.ModifiedUtc := 0;

      YearOrTimeToken := Tokens[7];
      NameStart := 1;
      for I := 0 to 7 do
      begin
        NameStart := PosEx(Tokens[I], Line, NameStart);
        if NameStart = 0 then
          Break;
        Inc(NameStart, Length(Tokens[I]));
        while (NameStart <= Length(Line)) and (Line[NameStart] = ' ') do
          Inc(NameStart);
      end;
      if NameStart > 0 then
        NameText := Trim(Copy(Line, NameStart, MaxInt))
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
  if not RunCommands(['ls ' + QuoteBatchArgument(Path)], Output) then
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
      raise ESyncTransportError.CreateFmt('Could not create remote directory "%s": %s',
        [Building, Trim(Output)]);
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
    raise ESyncTransportError.CreateFmt('Could not delete remote file "%s": %s',
      [Path, Trim(Output)]);
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
    raise ESyncTransportError.CreateFmt('Could not remove remote directory "%s": %s',
      [Path, Trim(Output)]);
end;

procedure TSftpTransport.RenameRemoteFile(const SourceRemotePath, TargetRemotePath: string);
var
  Output: string;
begin
  RequireConnected;
  if not RunCommands(['rename ' + QuoteBatchArgument(NormalizeRemotePath(SourceRemotePath)) + ' ' +
      QuoteBatchArgument(NormalizeRemotePath(TargetRemotePath))], Output) then
    raise ESyncTransportError.CreateFmt('Could not rename remote file "%s" to "%s": %s',
      [SourceRemotePath, TargetRemotePath, Trim(Output)]);
end;

procedure TSftpTransport.DownloadFile(const RemotePath, LocalPath: string;
  const OnProgress: TSyncTransferProgressEvent);
var
  RemoteFileName: string;
  TotalBytes: Int64;
  Output: string;
  Entry: TRemoteEntry;
  ParentPath: string;
  Stream: TFileStream;
begin
  RequireConnected;
  TDirectory.CreateDirectory(ExtractFilePath(LocalPath));
  TotalBytes := 0;
  RemoteFileName := ExtractFileName(NormalizeRemotePath(RemotePath));
  ParentPath := ExtractFileDir(NormalizeRemotePath(RemotePath)).Replace('\', '/');
  if ParentPath = '' then
    ParentPath := '/';
  for Entry in ListDirectory(ParentPath) do
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
  begin
    Stream := TFileStream.Create(LocalPath, fmOpenRead or fmShareDenyNone);
    try
      OnProgress(RemotePath, Stream.Size, TotalBytes, False);
    finally
      Stream.Free;
    end;
  end;
end;

procedure TSftpTransport.UploadFile(const LocalPath, RemotePath: string;
  const OnProgress: TSyncTransferProgressEvent);
var
  TotalBytes: Int64;
  Output: string;
  ParentPath: string;
  RemoteFileName: string;
  Stream: TFileStream;
begin
  RequireConnected;
  if not TFile.Exists(LocalPath) then
    raise ESyncTransportError.CreateFmt('Local upload file not found: %s', [LocalPath]);
  ParentPath := ExtractFileDir(NormalizeRemotePath(RemotePath)).Replace('\', '/');
  RemoteFileName := ExtractFileName(NormalizeRemotePath(RemotePath));
  if ParentPath <> '' then
    EnsureRemoteDirectory(ParentPath);
  Stream := TFileStream.Create(LocalPath, fmOpenRead or fmShareDenyNone);
  try
    TotalBytes := Stream.Size;
  finally
    Stream.Free;
  end;
  if Assigned(OnProgress) and not OnProgress(RemotePath, 0, TotalBytes, True) then
    raise ESyncTransportError.Create('Upload cancelled.');
  if ParentPath <> '' then
  begin
    if not RunCommands([
      'cd ' + QuoteBatchArgument(ParentPath),
      'put ' + QuoteBatchArgument(LocalPath) + ' ' + QuoteBatchArgument(RemoteFileName)
    ], Output) then
      raise ESyncTransportError.CreateFmt('Upload failed for "%s": %s', [RemotePath, Trim(Output)]);
  end
  else if not RunCommands(['put ' + QuoteBatchArgument(LocalPath) + ' ' +
      QuoteBatchArgument(RemoteFileName)], Output) then
    raise ESyncTransportError.CreateFmt('Upload failed for "%s": %s', [RemotePath, Trim(Output)]);
  if Assigned(OnProgress) then
    OnProgress(RemotePath, TotalBytes, TotalBytes, True);
end;

end.
