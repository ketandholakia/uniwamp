program UniWamp;

uses
  Winapi.Windows,
{$IFDEF MAD_EXCEPT}
  madExcept,
  madLinkDisAsm,
  madListHardware,
  madListProcesses,
  madListModules,
{$ENDIF}
  System.Classes,
  System.SysUtils,
  System.IOUtils,
  Vcl.Forms,
  Vcl.StdCtrls,
  Ui.UniWamp.MainForm in 'Ui\Ui.UniWamp.MainForm.pas',
  Ui.UniWamp.ShutdownProgressForm in 'Ui\Ui.UniWamp.ShutdownProgressForm.pas',
  Ui.UniWamp.PasswordDialog in 'Ui\Ui.UniWamp.PasswordDialog.pas',
  Ui.UniWamp.VHostDialog in 'Ui\Ui.UniWamp.VHostDialog.pas',
  Ui.UniWamp.ScriptManagerForm in 'Ui\Ui.UniWamp.ScriptManagerForm.pas',
  Core.UniWamp.Config in 'Core\Core.UniWamp.Config.pas',
  Core.UniWamp.Paths in 'Core\Core.UniWamp.Paths.pas',
  Core.UniWamp.Runtime in 'Core\Core.UniWamp.Runtime.pas',
  Core.UniWamp.ProcessManager in 'Core\Core.UniWamp.ProcessManager.pas',
  Core.UniWamp.ConfigGenerator in 'Core\Core.UniWamp.ConfigGenerator.pas',
  Core.UniWamp.PackageManager in 'Core\Core.UniWamp.PackageManager.pas',
  Core.UniWamp.VHostManager in 'Core\Core.UniWamp.VHostManager.pas',
  Core.UniWamp.ProjectBackupService in 'Core\Core.UniWamp.ProjectBackupService.pas',
  Core.UniWamp.DatabaseBackupService in 'Core\Core.UniWamp.DatabaseBackupService.pas',
  Core.UniWamp.SyncTypes in 'Core\Core.UniWamp.SyncTypes.pas',
  Core.UniWamp.FreeFileSyncService in 'Core\Core.UniWamp.FreeFileSyncService.pas',
  Core.UniWamp.FreeFileSyncBatchWriter in 'Core\Core.UniWamp.FreeFileSyncBatchWriter.pas',
  Core.UniWamp.HostsFileService in 'Core\Core.UniWamp.HostsFileService.pas',
  Core.UniWamp.BackupTypes in 'Core\Core.UniWamp.BackupTypes.pas',
  Core.UniWamp.TemplateRenderer in 'Core\Core.UniWamp.TemplateRenderer.pas',
  Core.UniWamp.PortUtils in 'Core\Core.UniWamp.PortUtils.pas',
  Core.UniWamp.ScriptCatalog in 'Core\Core.UniWamp.ScriptCatalog.pas',
  Core.UniWamp.TaskRunner in 'Core\Core.UniWamp.TaskRunner.pas',
  Core.UniWamp.ScriptEngine in 'Core\Core.UniWamp.ScriptEngine.pas',
  Core.UniWamp.Interfaces in 'Core\Core.UniWamp.Interfaces.pas',
  Core.UniWamp.ServiceLocator in 'Core\Core.UniWamp.ServiceLocator.pas',
  Core.UniWamp.Secrets in 'Core\Core.UniWamp.Secrets.pas',
  Core.UniWamp.ServiceSupervisor in 'Core\Core.UniWamp.ServiceSupervisor.pas',
  Core.UniWamp.AtomicFile in 'Core\Core.UniWamp.AtomicFile.pas',
  Core.UniWamp.Types in 'Core\Core.UniWamp.Types.pas';

{$R *.res}
{$R UniWampAssets.res}

function TryHandleElevatedHostsSync: Boolean;
var
  TempHostsFile: string;
  SystemRoot: string;
  TargetHostsFile: string;
  Bytes: TBytes;
  Stream: TFileStream;
begin
  Result := False;
  if (ParamCount >= 2) and SameText(ParamStr(1), '--sync-hosts') then
  begin
    Result := True;
    TempHostsFile := ParamStr(2);
    SystemRoot := GetEnvironmentVariable('SystemRoot');
    if SystemRoot = '' then
      SystemRoot := 'C:\Windows';
    TargetHostsFile := TPath.Combine(SystemRoot, 'System32\drivers\etc\hosts');
    try
      if not FileExists(TempHostsFile) then
      begin
        ExitCode := 1;
        Exit;
      end;
      Bytes := TFile.ReadAllBytes(TempHostsFile);
      if FileExists(TargetHostsFile) then
        Stream := TFileStream.Create(TargetHostsFile, fmOpenReadWrite or fmShareDenyWrite)
      else
        Stream := TFileStream.Create(TargetHostsFile, fmCreate or fmShareDenyWrite);
      try
        Stream.Size := 0;
        if Length(Bytes) > 0 then
          Stream.WriteBuffer(Bytes[0], Length(Bytes));
      finally
        Stream.Free;
      end;
      ExitCode := 0;
    except
      ExitCode := 1;
    end;
  end;
end;

var
  hMutex: THandle;
begin
  if TryHandleElevatedHostsSync then
    Exit;

  hMutex := CreateMutex(nil, True, 'UniWamp_SingleInstance_Mutex');
  if (hMutex <> 0) and (GetLastError = ERROR_ALREADY_EXISTS) then
  begin
    MessageBox(0, 'Another instance of UniWamp is already running.', 'UniWamp', MB_OK or MB_ICONWARNING);
    Exit;
  end;

  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.Title := 'UniWamp';
  RegisterClass(TLabel);
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
  
  if hMutex <> 0 then
    CloseHandle(hMutex);
end.
