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
  Core.UniWamp.Types,
  Core.UniWamp.Diagnostics,
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
    FStopping: Boolean;
    FLifetimeToken: ILifetimeToken;
    FShutdownThread: TThread;
    HeaderPanel: TPanel;
    StatusPanel: TPanel;
    DetailsMemo: TMemo;
    ProgressBar: TProgressBar;
    procedure AddMessage(const Text: string);
    procedure AppendActivityLog(const Text: string);
    procedure FormShow(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure RunShutdown;
    procedure WmRunShutdown(var Message: TMessage); message WM_RUN_SHUTDOWN;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
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
  Padding.SetBounds(16, 16, 16, 16);

  HeaderPanel := TPanel.Create(Self);
  HeaderPanel.Parent := Self;
  HeaderPanel.Align := alTop;
  HeaderPanel.Height := 54;
  HeaderPanel.AlignWithMargins := True;
  HeaderPanel.Margins.Bottom := 12;
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
  ProgressBar.AlignWithMargins := True;
  ProgressBar.Margins.Bottom := 12;
  ProgressBar.Min := 0;
  ProgressBar.Max := 100;
  ProgressBar.Position := 10;

  StatusPanel := TPanel.Create(Self);
  StatusPanel.Parent := Self;
  StatusPanel.Align := alTop;
  StatusPanel.Height := 38;
  StatusPanel.AlignWithMargins := True;
  StatusPanel.Margins.Bottom := 12;
  StatusPanel.BevelOuter := bvNone;
  StatusPanel.Caption := 'Preparing shutdown...';
  StatusPanel.Alignment := taLeftJustify;
  StatusPanel.ParentBackground := False;
  StatusPanel.Color := clWhite;

  DetailsMemo := TMemo.Create(Self);
  DetailsMemo.Parent := Self;
  DetailsMemo.Align := alClient;
  DetailsMemo.AlignWithMargins := True;
  DetailsMemo.BorderStyle := bsNone;
  DetailsMemo.Color := RGB(248, 249, 250);
  DetailsMemo.ReadOnly := True;
  DetailsMemo.ScrollBars := ssVertical;
  DetailsMemo.WordWrap := True;
  FLifetimeToken := TLifetimeToken.Create;

  OnShow := FormShow;
  OnCloseQuery := FormCloseQuery;
end;

destructor TShutdownProgressForm.Destroy;
begin
  if Assigned(FLifetimeToken) then
    FLifetimeToken.Invalidate;
  if Assigned(FShutdownThread) then
  begin
    FShutdownThread.WaitFor;
    FShutdownThread.Free;
    FShutdownThread := nil;
  end;
  inherited;
end;

procedure TShutdownProgressForm.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  CanClose := not FStopping;
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
  AppendRotatedLogLine(
    TPath.Combine(FPaths.LogsDir, 'activity.log'),
    FormatDateTime('hh:nn:ss', Now) + '  ' + Text,
    500);
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
end;

procedure TShutdownProgressForm.RunShutdown;
var
  Token: ILifetimeToken;
  NeedMariaDbStop: Boolean;
  NeedApacheStop: Boolean;
begin
  FStopping := True;
  FSuccess := True;
  Token := FLifetimeToken;
  ProgressBar.Position := 15;
  AddMessage('Shutdown sequence started.');

  NeedMariaDbStop := FConfig.MariaDbRunning or TProcessManager.IsRunning(FConfig.MariaDbPid);
  NeedApacheStop := FConfig.ApacheRunning or TProcessManager.IsRunning(FConfig.ApachePid);

  FShutdownThread := TThread.CreateAnonymousThread(
    procedure
    var
      OverallSuccess: Boolean;
      MariaResult: TRuntimeActionResult;
      ApacheResult: TRuntimeActionResult;
    begin
      OverallSuccess := True;
      try
        if NeedMariaDbStop then
        begin
          TThread.Queue(nil,
            procedure
            begin
              if Token.IsAlive then
                AddMessage('Stopping MariaDB service...');
            end);
          MariaResult := FRuntime.StopMariaDb;
          OverallSuccess := OverallSuccess and MariaResult.Success;
          TThread.Queue(nil,
            procedure
            begin
              if not Token.IsAlive then Exit;
              ProgressBar.Position := 45;
              AddMessage(MariaResult.Message);
              AppendActivityLog('Shutdown cleanup: ' + MariaResult.Message);
            end);
        end
        else
          TThread.Queue(nil,
            procedure
            begin
              if not Token.IsAlive then Exit;
              ProgressBar.Position := 45;
              AddMessage('MariaDB is already stopped.');
            end);

        if NeedApacheStop then
        begin
          TThread.Queue(nil,
            procedure
            begin
              if Token.IsAlive then
                AddMessage('Stopping Apache service...');
            end);
          ApacheResult := FRuntime.StopApache;
          OverallSuccess := OverallSuccess and ApacheResult.Success;
          TThread.Queue(nil,
            procedure
            begin
              if not Token.IsAlive then Exit;
              ProgressBar.Position := 80;
              AddMessage(ApacheResult.Message);
              AddMessage('PHP runtime unloaded with Apache shutdown.');
              AppendActivityLog('Shutdown cleanup: ' + ApacheResult.Message);
            end);
        end
        else
          TThread.Queue(nil,
            procedure
            begin
              if not Token.IsAlive then Exit;
              ProgressBar.Position := 80;
              AddMessage('Apache is already stopped. PHP runtime is not active.');
            end);
      except
        on E: Exception do
        begin
          OverallSuccess := False;
          var ErrMsg := E.Message;
          TThread.Queue(nil,
            procedure
            begin
              if Token.IsAlive then
                AddMessage('Shutdown error: ' + ErrMsg);
            end);
        end;
      end;

      TThread.Queue(nil,
        procedure
        begin
          if not Token.IsAlive then Exit;
          FSuccess := OverallSuccess;
          FStopping := False;
          if FSuccess then
          begin
            AddMessage('Shutdown cleanup completed. Closing application.');
            ProgressBar.Position := ProgressBar.Max;
            ModalResult := mrOk;
          end
          else
          begin
            AddMessage('Shutdown cleanup failed. Application will remain open.');
            ProgressBar.Position := ProgressBar.Max div 2;
            ModalResult := mrCancel;
          end;
        end);
    end);
  FShutdownThread.FreeOnTerminate := False;
  FShutdownThread.Start;
end;

end.
