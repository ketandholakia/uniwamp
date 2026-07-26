unit Core.UniWamp.SyncTransport;

interface

uses
  System.SysUtils,
  System.Classes;

type
  ESyncTransportError = class(Exception);

  TRemoteEntry = record
    Name: string;
    IsDirectory: Boolean;
    Size: Int64;
    ModifiedUtc: TDateTime; // 0 = unknown
  end;

  TRemoteEntries = TArray<TRemoteEntry>;

  // isUpload lets one handler serve both directions; return False from a
  // handler to request cancellation of the current transfer.
  TSyncTransferProgressEvent = reference to function(const FileName: string;
    const BytesTransferred, TotalBytes: Int64; const IsUpload: Boolean): Boolean;

  TSyncLogEvent = reference to procedure(const Text: string);

  TSyncCredentials = record
    Protocol: string;          // 'ftp' | 'ftps' | 'sftp'
    Host: string;
    Port: Integer;
    Username: string;
    Password: string;          // may be blank for sftp key-only auth
    PrivateKeyFile: string;    // sftp only
    KeyPassphrase: string;     // sftp only
    SshHostKeyFingerprint: string;      // sftp only
    TlsCertificateFingerprint: string;   // ftps only
    PassiveMode: Boolean;      // ftp/ftps only
    IgnoreCertErrors: Boolean; // ftps only
  end;

  // Implemented by the WinSCP-backed transport. All paths are POSIX-style ('/')
  // remote paths; callers are responsible for local <-> remote path translation.
  ISyncTransport = interface
    ['{9E1F2C3A-4B5D-4E6F-8A9B-0C1D2E3F4A5B}']
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

  TSyncTransportFactory = reference to function(const Credentials: TSyncCredentials): ISyncTransport;

function CreateSyncTransport(const Credentials: TSyncCredentials): ISyncTransport;

var
  SyncTransportFactory: TSyncTransportFactory;

implementation

uses
  Core.UniWamp.WinScpTransport;

function CreateSyncTransport(const Credentials: TSyncCredentials): ISyncTransport;
begin
  Result := TWinScpTransport.Create(Credentials);
end;

initialization
  SyncTransportFactory := CreateSyncTransport;

end.
