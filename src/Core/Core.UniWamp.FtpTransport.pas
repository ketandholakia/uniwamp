unit Core.UniWamp.FtpTransport;

interface

uses
  System.SysUtils,
  System.Classes,
  System.RegularExpressions,
  IdFTP,
  IdFTPList,
  IdComponent,
  IdSSLOpenSSL,
  IdExplicitTLSClientServerBase,
  Core.UniWamp.SyncTransport;

function DefaultFtpsCaBundleFile: string;
function FtpsHostMatchesCertificateSubject(const HostName, SubjectLine: string): Boolean;
function FtpsHostMatchesCertificate(const HostName, SubjectLine, DisplayInfoText: string): Boolean;

type
  // FTP (plain) and FTPS (explicit AUTH TLS) over Indy's TIdFTP.
  // Implicit FTPS is uncommon on modern hosts and is not implemented here;
  // add it later by setting FSsl on port 990 with UseImplicitSSL if ever needed.
  TFtpTransport = class(TInterfacedObject, ISyncTransport)
  private
    FCredentials: TSyncCredentials;
    FUseTls: Boolean;
    FClient: TIdFTP;
    FSsl: TIdSSLIOHandlerSocketOpenSSL;
    FOnLog: TSyncLogEvent;
    FCurrentProgressHandler: TSyncTransferProgressEvent;
    FCurrentFileName: string;
    FCurrentIsUpload: Boolean;
    FCurrentTotalBytes: Int64;
    FPeerCertSeen: Boolean;
    FPeerSubject: string;
    FPeerIssuer: string;
    FPeerSerialNumber: string;
    FPeerNotBefore: TDateTime;
    FPeerNotAfter: TDateTime;
    FPeerVerifyError: Integer;
    FPeerHostMatched: Boolean;
    procedure Log(const Text: string);
    procedure HandleWorkBegin(ASender: TObject; AWorkMode: TWorkMode; AWorkCountMax: Int64);
    procedure HandleWork(ASender: TObject; AWorkMode: TWorkMode; AWorkCount: Int64);
    function VerifyPeer(Certificate: TIdX509; AOk: Boolean; ADepth, AError: Integer): Boolean;
    function NormalizeRemotePath(const RemotePath: string): string;
  public
    constructor Create(const Credentials: TSyncCredentials);
    destructor Destroy; override;

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
  System.StrUtils,
  System.DateUtils,
  System.IOUtils,
  IdFTPCommon,
  Core.UniWamp.Paths;

function DefaultFtpsCaBundleFile: string;
var
  Paths: TAppPaths;
begin
  Paths := TAppPaths.Detect;
  Result := TPath.Combine(Paths.RuntimeDir, TPath.Combine('certs', 'cacert.pem'));
end;

function ExtractCommonName(const SubjectLine: string): string;
var
  StartPos: Integer;
  EndPos: Integer;
begin
  Result := '';
  StartPos := Pos('CN=', UpperCase(SubjectLine));
  if StartPos = 0 then
    Exit;
  Inc(StartPos, 3);
  EndPos := StartPos;
  while (EndPos <= Length(SubjectLine)) and not CharInSet(SubjectLine[EndPos], ['/', ',']) do
    Inc(EndPos);
  Result := Trim(Copy(SubjectLine, StartPos, EndPos - StartPos));
end;

function FtpsHostMatchesCertificateSubject(const HostName, SubjectLine: string): Boolean;
begin
  Result := FtpsHostMatchesCertificate(HostName, SubjectLine, '');
end;

function FtpsHostMatchesCertificateName(const HostName, CandidateName: string): Boolean;
var
  DotPos: Integer;
begin
  Result := SameText(CandidateName, HostName);
  if Result then
    Exit;
  if (Length(CandidateName) > 2) and (Copy(CandidateName, 1, 2) = '*.') then
  begin
    DotPos := Pos('.', LowerCase(HostName));
    if DotPos > 0 then
      Result := SameText(Copy(CandidateName, 3, MaxInt), Copy(LowerCase(HostName), DotPos + 1, MaxInt));
  end;
end;

function FtpsHostMatchesCertificate(const HostName, SubjectLine, DisplayInfoText: string): Boolean;
var
  CommonName: string;
  Match: TMatch;
begin
  if Pos('Subject Alternative Name', DisplayInfoText) > 0 then
  begin
    for Match in TRegEx.Matches(DisplayInfoText, 'DNS:([^,\r\n]+)', [roIgnoreCase]) do
      if FtpsHostMatchesCertificateName(HostName, Trim(Match.Groups[1].Value)) then
        Exit(True);
    Exit(False);
  end;

  CommonName := ExtractCommonName(SubjectLine);
  Result := FtpsHostMatchesCertificateName(HostName, CommonName);
end;

{ TFtpTransport }

constructor TFtpTransport.Create(const Credentials: TSyncCredentials);
begin
  inherited Create;
  FCredentials := Credentials;
  FUseTls := SameText(Credentials.Protocol, 'ftps');
end;

destructor TFtpTransport.Destroy;
begin
  Disconnect;
  FClient.Free;
  FSsl.Free;
  inherited;
end;

procedure TFtpTransport.Log(const Text: string);
begin
  if Assigned(FOnLog) then
    FOnLog(Text);
end;

procedure TFtpTransport.SetLogHandler(const Handler: TSyncLogEvent);
begin
  FOnLog := Handler;
end;

function TFtpTransport.NormalizeRemotePath(const RemotePath: string): string;
begin
  Result := StringReplace(RemotePath, '\', '/', [rfReplaceAll]);
  if Result = '' then
    Result := '/';
  if (Length(Result) > 1) and (Result[1] <> '/') then
    Result := '/' + Result;
end;

procedure TFtpTransport.Connect;
begin
  if Assigned(FClient) and FClient.Connected then
    Exit;

  FreeAndNil(FClient);
  FreeAndNil(FSsl);

  FClient := TIdFTP.Create(nil);
  FClient.Host := FCredentials.Host;
  if FCredentials.Port > 0 then
    FClient.Port := FCredentials.Port
  else
    FClient.Port := 21;
  FClient.Username := FCredentials.Username;
  FClient.Password := FCredentials.Password;
  FClient.Passive := FCredentials.PassiveMode;
  FClient.ConnectTimeout := 15000;
  FClient.ReadTimeout := 30000;

  FClient.OnWorkBegin := HandleWorkBegin;
  FClient.OnWork := HandleWork;
  FPeerCertSeen := False;
  FPeerSubject := '';
  FPeerIssuer := '';
  FPeerSerialNumber := '';
  FPeerNotBefore := 0;
  FPeerNotAfter := 0;
  FPeerVerifyError := 0;
  FPeerHostMatched := False;

  if FUseTls then
  begin
    FSsl := TIdSSLIOHandlerSocketOpenSSL.Create(nil);
    FSsl.SSLOptions.Method := sslvSSLv23;
    FSsl.SSLOptions.Mode := sslmClient;
    FSsl.SSLOptions.VerifyMode := [sslvrfPeer];
    FSsl.SSLOptions.VerifyDepth := 4;
    if not FCredentials.IgnoreCertErrors then
    begin
      FSsl.SSLOptions.RootCertFile := DefaultFtpsCaBundleFile;
      if not FileExists(FSsl.SSLOptions.RootCertFile) then
        raise ESyncTransportError.Create('FTPS CA bundle not found: ' + FSsl.SSLOptions.RootCertFile);
    end;
    FSsl.OnVerifyPeer := VerifyPeer;
    FClient.IOHandler := FSsl;
    FClient.UseTLS := utUseExplicitTLS;
  end;

  try
    FClient.Connect;
  except
    on E: Exception do
      raise ESyncTransportError.CreateFmt('FTP connect to %s:%d failed: %s',
        [FCredentials.Host, FClient.Port, E.Message]);
  end;
  if FUseTls then
  begin
    if not FPeerCertSeen then
      raise ESyncTransportError.Create('FTPS server did not present a certificate.');
    Log(Format('FTPS certificate subject: %s', [FPeerSubject]));
    Log(Format('FTPS certificate issuer: %s', [FPeerIssuer]));
    Log(Format('FTPS certificate serial: %s', [FPeerSerialNumber]));
    Log(Format('FTPS certificate validity: %s to %s',
      [DateTimeToStr(FPeerNotBefore), DateTimeToStr(FPeerNotAfter)]));
    if FCredentials.IgnoreCertErrors then
      Log('FTPS certificate verification result: insecure override enabled.')
    else
      Log('FTPS certificate verification result: verified.');
  end;
  Log(Format('Connected to %s:%d (%s).', [FCredentials.Host, FClient.Port,
    IfThen(FUseTls, 'FTPS', 'FTP')]));
end;

procedure TFtpTransport.Disconnect;
begin
  if Assigned(FClient) and FClient.Connected then
    try
      FClient.Disconnect;
    except
      // best-effort on teardown
    end;
end;

function TFtpTransport.IsConnected: Boolean;
begin
  Result := Assigned(FClient) and FClient.Connected;
end;

procedure TFtpTransport.HandleWorkBegin(ASender: TObject; AWorkMode: TWorkMode; AWorkCountMax: Int64);
begin
  FCurrentTotalBytes := AWorkCountMax;
end;

procedure TFtpTransport.HandleWork(ASender: TObject; AWorkMode: TWorkMode; AWorkCount: Int64);
begin
  if Assigned(FCurrentProgressHandler) then
    if not FCurrentProgressHandler(FCurrentFileName, AWorkCount, FCurrentTotalBytes, FCurrentIsUpload) then
      FClient.Disconnect(False); // signals cancellation; caller sees the resulting exception
end;

function TFtpTransport.VerifyPeer(Certificate: TIdX509; AOk: Boolean; ADepth, AError: Integer): Boolean;
var
  HostMatched: Boolean;
  ErrorDetail: string;
begin
  Result := AOk;
  if ADepth = 0 then
  begin
    FPeerCertSeen := Assigned(Certificate);
    if Assigned(Certificate) then
    begin
      FPeerSubject := Certificate.Subject.OneLine;
      FPeerIssuer := Certificate.Issuer.OneLine;
      FPeerSerialNumber := Certificate.SerialNumber;
      FPeerNotBefore := Certificate.NotBefore;
      FPeerNotAfter := Certificate.NotAfter;
      HostMatched := FtpsHostMatchesCertificate(FCredentials.Host, FPeerSubject,
        Certificate.DisplayInfo.Text);
      FPeerHostMatched := HostMatched;
      if not HostMatched then
        Result := False;
    end;
    FPeerVerifyError := AError;
  end;

  if FCredentials.IgnoreCertErrors then
  begin
    if (ADepth = 0) and (not AOk or not FPeerHostMatched) then
    begin
      ErrorDetail := '';
      if not AOk then
        ErrorDetail := 'peer verification error ' + IntToStr(AError);
      if not FPeerHostMatched then
      begin
        if ErrorDetail <> '' then
          ErrorDetail := ErrorDetail + '; ';
        ErrorDetail := ErrorDetail + 'hostname mismatch for ' + FCredentials.Host;
      end;
      Log('FTPS certificate warning: ' + ErrorDetail + '.');
    end;
    Exit(True);
  end;

  if (ADepth = 0) and not FPeerHostMatched then
    Log('FTPS certificate hostname mismatch for ' + FCredentials.Host + '.');
end;

function TFtpTransport.ListDirectory(const RemotePath: string): TRemoteEntries;
var
  Path: string;
  I: Integer;
  Item: TIdFTPListItem;
begin
  Path := NormalizeRemotePath(RemotePath);
  try
    FClient.List(Path, False);
  except
    on E: Exception do
      raise ESyncTransportError.CreateFmt('FTP LIST failed for "%s": %s', [Path, E.Message]);
  end;

  SetLength(Result, FClient.DirectoryListing.Count);
  for I := 0 to FClient.DirectoryListing.Count - 1 do
  begin
    Item := FClient.DirectoryListing.Items[I];
    Result[I].Name := Item.FileName;
    Result[I].IsDirectory := Item.ItemType = ditDirectory;
    Result[I].Size := Item.Size;
    Result[I].ModifiedUtc := Item.ModifiedDate;
  end;
end;

function TFtpTransport.RemoteDirectoryExists(const RemotePath: string): Boolean;
var
  Current: string;
begin
  Current := FClient.RetrieveCurrentDir;
  try
    FClient.ChangeDir(NormalizeRemotePath(RemotePath));
    Result := True;
  except
    Result := False;
  end;
  try
    FClient.ChangeDir(Current);
  except
    // ignore - best effort restore
  end;
end;

procedure TFtpTransport.EnsureRemoteDirectory(const RemotePath: string);
var
  Segments: TArray<string>;
  Segment: string;
  Building: string;
begin
  Segments := NormalizeRemotePath(RemotePath).Split(['/'], TStringSplitOptions.ExcludeEmpty);
  Building := '';
  for Segment in Segments do
  begin
    Building := Building + '/' + Segment;
    if not RemoteDirectoryExists(Building) then
      try
        FClient.MakeDir(Building);
      except
        on E: Exception do
          raise ESyncTransportError.CreateFmt('Could not create remote directory "%s": %s', [Building, E.Message]);
      end;
  end;
end;

procedure TFtpTransport.DeleteRemoteFile(const RemotePath: string);
begin
  try
    FClient.Delete(NormalizeRemotePath(RemotePath));
  except
    on E: Exception do
      raise ESyncTransportError.CreateFmt('Could not delete remote file "%s": %s', [RemotePath, E.Message]);
  end;
end;

procedure TFtpTransport.DeleteRemoteDirectory(const RemotePath: string; const Recursive: Boolean);
var
  Entries: TRemoteEntries;
  Entry: TRemoteEntry;
  Path: string;
begin
  Path := NormalizeRemotePath(RemotePath);
  if Recursive then
  begin
    Entries := ListDirectory(Path);
    for Entry in Entries do
    begin
      if (Entry.Name = '.') or (Entry.Name = '..') then
        Continue;
      if Entry.IsDirectory then
        DeleteRemoteDirectory(Path + '/' + Entry.Name, True)
      else
        DeleteRemoteFile(Path + '/' + Entry.Name);
    end;
  end;
  try
    FClient.RemoveDir(Path);
  except
    on E: Exception do
      raise ESyncTransportError.CreateFmt('Could not remove remote directory "%s": %s', [Path, E.Message]);
  end;
end;

procedure TFtpTransport.RenameRemoteFile(const SourceRemotePath, TargetRemotePath: string);
begin
  try
    FClient.Rename(NormalizeRemotePath(SourceRemotePath), NormalizeRemotePath(TargetRemotePath));
  except
    on E: Exception do
      raise ESyncTransportError.CreateFmt('Could not rename remote file "%s" to "%s": %s',
        [SourceRemotePath, TargetRemotePath, E.Message]);
  end;
end;

procedure TFtpTransport.DownloadFile(const RemotePath, LocalPath: string;
  const OnProgress: TSyncTransferProgressEvent);
begin
  FCurrentProgressHandler := OnProgress;
  FCurrentFileName := RemotePath;
  FCurrentIsUpload := False;
  FCurrentTotalBytes := 0;
  try
    FClient.Get(NormalizeRemotePath(RemotePath), LocalPath, True);
  except
    on E: Exception do
      raise ESyncTransportError.CreateFmt('Download failed for "%s": %s', [RemotePath, E.Message]);
  end;
  FCurrentProgressHandler := nil;
end;

procedure TFtpTransport.UploadFile(const LocalPath, RemotePath: string;
  const OnProgress: TSyncTransferProgressEvent);
begin
  FCurrentProgressHandler := OnProgress;
  FCurrentFileName := RemotePath;
  FCurrentIsUpload := True;
  FCurrentTotalBytes := 0;
  try
    FClient.Put(LocalPath, NormalizeRemotePath(RemotePath), False);
  except
    on E: Exception do
      raise ESyncTransportError.CreateFmt('Upload failed for "%s": %s', [RemotePath, E.Message]);
  end;
  FCurrentProgressHandler := nil;
end;

end.
