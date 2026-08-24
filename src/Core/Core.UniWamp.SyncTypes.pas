unit Core.UniWamp.SyncTypes;

interface

uses
  System.SysUtils;

type
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

implementation

end.
