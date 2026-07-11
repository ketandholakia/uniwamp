program UniWamp;

uses
  Vcl.Forms,
  Ui.UniWamp.MainForm in 'Ui\Ui.UniWamp.MainForm.pas',
  Ui.UniWamp.ShutdownProgressForm in 'Ui\Ui.UniWamp.ShutdownProgressForm.pas',
  Core.UniWamp.Config in 'Core\Core.UniWamp.Config.pas',
  Core.UniWamp.Paths in 'Core\Core.UniWamp.Paths.pas',
  Core.UniWamp.Runtime in 'Core\Core.UniWamp.Runtime.pas',
  Core.UniWamp.ProcessManager in 'Core\Core.UniWamp.ProcessManager.pas',
  Core.UniWamp.TemplateRenderer in 'Core\Core.UniWamp.TemplateRenderer.pas',
  Core.UniWamp.PortUtils in 'Core\Core.UniWamp.PortUtils.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.Title := 'UniWamp';
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.
