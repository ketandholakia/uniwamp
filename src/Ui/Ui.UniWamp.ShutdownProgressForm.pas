unit Ui.UniWamp.ShutdownProgressForm;

interface

uses
  Winapi.Windows,
  Winapi.Messages,
  System.Classes,
  System.SysUtils,
  Vcl.ComCtrls,
  Vcl.Controls,
  Vcl.ExtCtrls,
  Vcl.Forms,
  Vcl.Graphics,
  Vcl.StdCtrls,
  Core.UniWamp.Config,
  Core.UniWamp.Paths,
  Core.UniWamp.Runtime;

const
  WM_RUN_SHUTDOWN = WM_APP + 100;

type
  TShutdownProgressForm = class(TForm)
  private
    FRuntime: TUniWampRuntime;
    FConfig: TUniWampConfig;
    FPaths: TAppPaths;
    FExecuted: Boolean;
    FSuccess: Boolean;
    HeaderPanel: TPanel;
    StatusPanel: TPanel;
    DetailsMemo: TMemo;
    ProgressBar: TProgressBar;
    procedure AddMessage(const Text: string);
    procedure AppendActivityLog(const Text: string);
    procedure FormShow(Sender: TObject);
    procedure RunShutdown;
    procedure WmRunShutdown(var Message: TMessage); message WM_RUN_SHUTDOWN;
  public
    constructor Create(AOwner: TComponent); override;
    class function ExecuteShutdown(AOwner: TComponent; Runtime: TUniWampRuntime;
      Config: TUniWampConfig; const Paths: TAppPaths): Boolean; static;
  end;

implementation

uses
  System.IOUtils,
  Core.UniWamp.ProcessManager;

constructor TShutdownProgressForm.Create(AOwner: TComponent);
begin
  inherited CreateNew(AOwner);
  BorderIcons := [];
  BorderStyle := bsDialog;
  Caption := 'Shutting Down UniWamp';
  ClientHeight := 320;
  ClientWidth := 560;
  Color := clWhite;
  Position := poScreenCenter;

  HeaderPanel := TPanel.Create(Self);
  HeaderPanel.Parent := Self;
  HeaderPanel.Align := alTop;
  HeaderPanel.Height := 54;
  HeaderPanel.BevelOuter := bvNone;
  HeaderPanel.Color := RGB(44, 62, 80);
  HeaderPanel.Font.Color := clWhite;
  HeaderPanel.Font.Style := [fsBold];
  HeaderPanel.Caption := '  Stopping services and cleaning up runtime state';
  HeaderPanel.ParentBackground := False;

  ProgressBar := TProgressBar.Create(Self);
  ProgressBar.Parent := Self;
  ProgressBar.Align := alTop;
  ProgressBar.Height := 18;
  ProgressBar.Min := 0;
  ProgressBar.Max := 100;
  ProgressBar.Position := 10;

  StatusPanel := TPanel.Create(Self);
  StatusPanel.Parent := Self;
  StatusPanel.Align := alTop;
  StatusPanel.Height := 38;
  StatusPanel.BevelOuter := bvNone;
  StatusPanel.Caption := 'Preparing shutdown...';
  StatusPanel.Alignment := taLeftJustify;
  StatusPanel.ParentBackground := False;
  StatusPanel.Color := clWhite;

  DetailsMemo := TMemo.Create(Self);
  DetailsMemo.Parent := Self;
  DetailsMemo.Align := alClient;
  DetailsMemo.BorderStyle := bsNone;
  DetailsMemo.Color := RGB(248, 249, 250);
  DetailsMemo.ReadOnly := True;
  DetailsMemo.ScrollBars := ssVertical;
  DetailsMemo.WordWrap := True;

  OnShow := FormShow;
end;

class function TShutdownProgressForm.ExecuteShutdown(AOwner: TComponent;
  Runtime: TUniWampRuntime; Config: TUniWampConfig; const Paths: TAppPaths): Boolean;
var
  Dialog: TShutdownProgressForm;
begin
  Dialog := TShutdownProgressForm.Create(AOwner);
  try
    Dialog.FRuntime := Runtime;
    Dialog.FConfig := Config;
    Dialog.FPaths := Paths;
    Dialog.ShowModal;
    Result := Dialog.FSuccess;
  finally
    Dialog.Free;
  end;
end;

procedure TShutdownProgressForm.AddMessage(const Text: string);
begin
  StatusPanel.Caption := '  ' + Text;
  DetailsMemo.Lines.Add(FormatDateTime('hh:nn:ss', Now) + '  ' + Text);
  DetailsMemo.SelStart := Length(DetailsMemo.Text);
  DetailsMemo.Perform(EM_SCROLLCARET, 0, 0);
  Update;
  Application.ProcessMessages;
end;

procedure TShutdownProgressForm.AppendActivityLog(const Text: string);
begin
  TFile.AppendAllText(
    TPath.Combine(FPaths.LogsDir, 'activity.log'),
    FormatDateTime('hh:nn:ss', Now) + '  ' + Text + sLineBreak,
    TEncoding.UTF8);
end;

procedure TShutdownProgressForm.FormShow(Sender: TObject);
begin
  if FExecuted then
    Exit;

  FExecuted := True;
  PostMessage(Handle, WM_RUN_SHUTDOWN, 0, 0);
end;

procedure TShutdownProgressForm.WmRunShutdown(var Message: TMessage);
begin
  RunShutdown;
  if FSuccess then
    ModalResult := mrOk
  else
    ModalResult := mrCancel;
end;

procedure TShutdownProgressForm.RunShutdown;
var
  ResultInfo: TRuntimeActionResult;
begin
  FSuccess := True;
  ProgressBar.Position := 15;
  AddMessage('Shutdown sequence started.');

  if FConfig.MariaDbRunning or TProcessManager.IsRunning(FConfig.MariaDbPid) then
  begin
    AddMessage('Stopping MariaDB service...');
    ResultInfo := FRuntime.StopMariaDb;
    ProgressBar.Position := 45;
    AddMessage(ResultInfo.Message);
    AppendActivityLog('Shutdown cleanup: ' + ResultInfo.Message);
    FSuccess := FSuccess and ResultInfo.Success;
  end
  else
  begin
    ProgressBar.Position := 45;
    AddMessage('MariaDB is already stopped.');
  end;

  if FConfig.ApacheRunning or TProcessManager.IsRunning(FConfig.ApachePid) then
  begin
    AddMessage('Stopping Apache service...');
    ResultInfo := FRuntime.StopApache;
    ProgressBar.Position := 80;
    AddMessage(ResultInfo.Message);
    AddMessage('PHP runtime unloaded with Apache shutdown.');
    AppendActivityLog('Shutdown cleanup: ' + ResultInfo.Message);
    FSuccess := FSuccess and ResultInfo.Success;
  end
  else
  begin
    ProgressBar.Position := 80;
    AddMessage('Apache is already stopped. PHP runtime is not active.');
  end;

  if FSuccess then
  begin
    AddMessage('Shutdown cleanup completed. Closing application.');
    ProgressBar.Position := ProgressBar.Max;
  end
  else
  begin
    AddMessage('Shutdown cleanup failed. Application will remain open.');
    ProgressBar.Position := ProgressBar.Max div 2;
  end;
end;

end.
