unit Core.UniWamp.SftpTransport;

interface

uses
  System.SysUtils,
  System.Classes,
  Core.UniWamp.SyncTransport;

type
  // SFTP support originally used TGPuttyLib, which is not available in this
  // build environment. The transport remains as a stub so the project compiles
  // cleanly and can surface a precise runtime error if SFTP is selected.
  TSftpTransport = class(TInterfacedObject, ISyncTransport)
  private
    FCredentials: TSyncCredentials;
    FOnLog: TSyncLogEvent;
    procedure Log(const Text: string);
    procedure RaiseUnavailable;
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

constructor TSftpTransport.Create(const Credentials: TSyncCredentials);
begin
  inherited Create;
  FCredentials := Credentials;
end;

procedure TSftpTransport.Log(const Text: string);
begin
  if Assigned(FOnLog) then
    FOnLog(Text);
end;

procedure TSftpTransport.RaiseUnavailable;
begin
  raise ESyncTransportError.Create(
    'SFTP transport is not available in this build because TGPuttyLib is not installed.');
end;

procedure TSftpTransport.SetLogHandler(const Handler: TSyncLogEvent);
begin
  FOnLog := Handler;
end;

procedure TSftpTransport.Connect;
begin
  Log(Format('SFTP requested for %s:%d, but the transport is unavailable.',
    [FCredentials.Host, FCredentials.Port]));
  RaiseUnavailable;
end;

procedure TSftpTransport.Disconnect;
begin
end;

function TSftpTransport.IsConnected: Boolean;
begin
  Result := False;
end;

function TSftpTransport.ListDirectory(const RemotePath: string): TRemoteEntries;
begin
  RaiseUnavailable;
  Result := nil;
end;

function TSftpTransport.RemoteDirectoryExists(const RemotePath: string): Boolean;
begin
  RaiseUnavailable;
  Result := False;
end;

procedure TSftpTransport.EnsureRemoteDirectory(const RemotePath: string);
begin
  RaiseUnavailable;
end;

procedure TSftpTransport.DeleteRemoteFile(const RemotePath: string);
begin
  RaiseUnavailable;
end;

procedure TSftpTransport.DeleteRemoteDirectory(const RemotePath: string; const Recursive: Boolean);
begin
  RaiseUnavailable;
end;

procedure TSftpTransport.DownloadFile(const RemotePath, LocalPath: string;
  const OnProgress: TSyncTransferProgressEvent);
begin
  RaiseUnavailable;
end;

procedure TSftpTransport.UploadFile(const LocalPath, RemotePath: string;
  const OnProgress: TSyncTransferProgressEvent);
begin
  RaiseUnavailable;
end;

end.
