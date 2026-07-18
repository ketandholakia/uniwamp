unit Core.UniWamp.Interfaces;

interface

uses
  System.SysUtils,
  Core.UniWamp.Types;

type
  IVHostManager = interface
    ['{F4A5E6B7-8C9D-0E1F-2A3B-4C5D6E7F8A9B}']
    function AddVHost(const ServerName, DocumentRoot, ServerAliases: string; EnableSsl: Boolean): TRuntimeActionResult;
    function DeleteVHost(const ServerName: string): TRuntimeActionResult;
    function GenerateSslCertificate: TRuntimeActionResult;
    function GenerateSslCertificateFor(const CommonName, CertFile, KeyFile: string): TRuntimeActionResult;
    function RefreshVHostSslCertificate(const ServerName: string): TRuntimeActionResult;
    function EnsureDefaultSslCertificate(out ErrorMessage: string): Boolean;
  end;

  IProjectBackupService = interface
    ['{F7B1A25C-49CB-4F54-92A7-7D5A1B8A2F11}']
    function BackupProject(const ServerName: string; out BackupDirectory: string): TRuntimeActionResult;
    function RestoreProject(const ManifestFileName, TargetServerName, TargetDocumentRoot,
      TargetServerAliases: string; TargetEnableSsl: Boolean; out RestoredServerName: string): TRuntimeActionResult;
  end;

  IDatabaseBackupService = interface
    ['{2A7C9B1B-3F0E-4D0D-9C36-9E2A6B2E4D71}']
    function BackupAllDatabases(out BackupDirectory: string): TRuntimeActionResult;
    function RestoreDatabase(const BackupInfoFileName: string): TRuntimeActionResult;
  end;

  IHostsFileService = interface
    ['{B1A2C3D4-E5F6-7A8B-9C0D-1E2F3A4B5C6D}']
    function SyncHostsFile(out ErrorMessage: string): Boolean;
    function RenderManagedHostsBlock: string;
    function HostsFilePath: string;
  end;

  IConfigurationGenerator = interface
    ['{A1B2C3D4-E5F6-7A8B-9C0D-1E2F3A4B5C6D}']
    procedure GenerateApacheConfig(const ApacheModuleDir, PhpModule: string);
    procedure GenerateMariaDbConfig;
    procedure GeneratePhpConfig(const SelectedPhpDir: string);
    procedure GenerateVHostConfig;
    procedure GenerateEnvBat(const WorkingDir, SelectedPhpDir, SelectedNodeDir: string);
  end;

  IRuntime = interface
    ['{C1D2E3F4-A5B6-7C8D-9E0F-1A2B3C4D5E6F}']
    function StartApache: TRuntimeActionResult;
    function StopApache: TRuntimeActionResult;
    function RestartApache: TRuntimeActionResult;
    function StartMariaDb: TRuntimeActionResult;
    function StopMariaDb: TRuntimeActionResult;
    function RestartMariaDb: TRuntimeActionResult;
    function BuildDiagnosticReport: string;
  end;

implementation

end.
