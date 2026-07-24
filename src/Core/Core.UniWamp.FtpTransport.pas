unit Core.UniWamp.FtpTransport;

interface

uses
  System.SysUtils,
  System.Classes,
  IdFTP,
  IdFTPList,
  IdComponent,
  IdSSLOpenSSL,
  IdExplicitTLSClientServerBase,
  Core.UniWamp.SyncTransport;

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
  IdFTPCommon;

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

  if FUseTls then
  begin
    FSsl := TIdSSLIOHandlerSocketOpenSSL.Create(nil);
    FSsl.SSLOptions.Method := sslvTLSv1_2;
    FSsl.SSLOptions.Mode := sslmClient;
    if FCredentials.IgnoreCertErrors then
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
begin
  Result := True;
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
