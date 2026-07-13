program UniWamp;

uses
{$IFDEF MAD_EXCEPT}
  madExcept,
  madLinkDisAsm,
  madListHardware,
  madListProcesses,
  madListModules,
{$ENDIF}
  System.Classes,
 Vcl.Forms,
  Vcl.StdCtrls,
  Ui.UniWamp.MainForm in 'Ui\Ui.UniWamp.MainForm.pas',
  Ui.UniWamp.ShutdownProgressForm in 'Ui\Ui.UniWamp.ShutdownProgressForm.pas',
  Ui.UniWamp.PasswordDialog in 'Ui\Ui.UniWamp.PasswordDialog.pas',
  Ui.UniWamp.VHostDialog in 'Ui\Ui.UniWamp.VHostDialog.pas',
  Core.UniWamp.Config in 'Core\Core.UniWamp.Config.pas',
  Core.UniWamp.Paths in 'Core\Core.UniWamp.Paths.pas',
  Core.UniWamp.Runtime in 'Core\Core.UniWamp.Runtime.pas',
  Core.UniWamp.ProcessManager in 'Core\Core.UniWamp.ProcessManager.pas',
  Core.UniWamp.TemplateRenderer in 'Core\Core.UniWamp.TemplateRenderer.pas',
  Core.UniWamp.PortUtils in 'Core\Core.UniWamp.PortUtils.pas';

{$R *.res}
{$R UniWampAssets.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.Title := 'UniWamp';
  RegisterClass(TLabel);
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.
