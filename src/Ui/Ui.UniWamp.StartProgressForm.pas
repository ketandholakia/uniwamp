unit Ui.UniWamp.StartProgressForm;

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
  System.UITypes,
  Core.UniWamp.Config,
  Core.UniWamp.Diagnostics,
  Core.UniWamp.Types,
  Core.UniWamp.Paths,
  Core.UniWamp.Runtime;

const
  WM_RUN_STARTUP = WM_APP + 101;

type
  TStartProgressForm = class(TForm)
  private
    FRuntime: TUniWampRuntime;
    FConfig: TUniWampConfig;
    FPaths: TAppPaths;
    FExecuted: Boolean;
    FStarting: Boolean;
    FResultInfo: TRuntimeActionResult;
    HeaderPanel: TPanel;
    StatusPanel: TPanel;
    DetailsMemo: TMemo;
    ProgressBar: TProgressBar;
    procedure AddMessage(const Text: string);
    procedure AppendActivityLog(const Text: string);
    procedure AppendMariaDbFailureDetails;
    procedure SyncCheckingMariaDbFiles;
    procedure SyncStartingMariaDb;
    procedure SyncStartupFinished;
    procedure SyncStartupFailed;
    procedure FormShow(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure RunStartup;
    procedure WmRunStartup(var Message: TMessage); message WM_RUN_STARTUP;
  public
    constructor Create(AOwner: TComponent); override;
    class function ExecuteStart(AOwner: TComponent; Runtime: TUniWampRuntime;
      Config: TUniWampConfig; const Paths: TAppPaths): TRuntimeActionResult; static;
  end;

implementation

uses
  System.IOUtils,
  System.Threading,
  Vcl.Dialogs,
  Core.UniWamp.ProcessManager;

constructor TStartProgressForm.Create(AOwner: TComponent);
begin
  inherited CreateNew(AOwner);
  BorderIcons := [];
  BorderStyle := bsDialog;
  Caption := 'Starting MariaDB';
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
  HeaderPanel.Caption := '  Starting MariaDB and initializing runtime state';
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
  StatusPanel.Caption := 'Preparing MariaDB startup...';
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
  OnCloseQuery := FormCloseQuery;
end;

class function TStartProgressForm.ExecuteStart(AOwner: TComponent;
  Runtime: TUniWampRuntime; Config: TUniWampConfig; const Paths: TAppPaths): TRuntimeActionResult;
var
  Dialog: TStartProgressForm;
begin
  Dialog := TStartProgressForm.Create(AOwner);
  try
    Dialog.FRuntime := Runtime;
    Dialog.FConfig := Config;
    Dialog.FPaths := Paths;
    Dialog.ShowModal;
    Result := Dialog.FResultInfo;
  finally
    Dialog.Free;
  end;
end;

procedure TStartProgressForm.AddMessage(const Text: string);
begin
  StatusPanel.Caption := '  ' + Text;
  DetailsMemo.Lines.Add(FormatDateTime('hh:nn:ss', Now) + '  ' + Text);
  DetailsMemo.SelStart := Length(DetailsMemo.Text);
  DetailsMemo.Perform(EM_SCROLLCARET, 0, 0);
  Update;
  Application.ProcessMessages;
end;

procedure TStartProgressForm.AppendActivityLog(const Text: string);
begin
  AppendRotatedLogLine(
    TPath.Combine(FPaths.LogsDir, 'activity.log'),
    FormatDateTime('hh:nn:ss', Now) + '  ' + Text,
    500);
end;

procedure TStartProgressForm.AppendMariaDbFailureDetails;
var
  LogFile: string;
  Lines: TStringList;
  StartIndex: Integer;
  I: Integer;
begin
  LogFile := TPath.Combine(FPaths.LogsDir, 'mariadb-error.log');
  if not FileExists(LogFile) then
    Exit;

  Lines := TStringList.Create;
  try
    Lines.Text := TFile.ReadAllText(LogFile, TEncoding.UTF8);
    if Lines.Count = 0 then
      Exit;

    StartIndex := 0;
    if Lines.Count > 12 then
      StartIndex := Lines.Count - 12;

    AddMessage('MariaDB error log:');
    for I := StartIndex to Lines.Count - 1 do
      if Trim(Lines[I]) <> '' then
        AddMessage('  ' + Lines[I]);
  finally
    Lines.Free;
  end;
end;

procedure TStartProgressForm.SyncCheckingMariaDbFiles;
begin
  AddMessage('Checking MariaDB runtime files...');
end;

procedure TStartProgressForm.SyncStartingMariaDb;
begin
  AddMessage('Starting MariaDB service...');
end;

procedure TStartProgressForm.SyncStartupFinished;
begin
  ProgressBar.Position := 85;
  AddMessage(FResultInfo.Message);
  AppendActivityLog('Startup: ' + FResultInfo.Message);
  FStarting := False;
  if FResultInfo.Success then
  begin
    AddMessage('MariaDB startup completed.');
    ProgressBar.Position := ProgressBar.Max;
    ModalResult := mrOk;
  end
  else
  begin
    AddMessage('MariaDB startup failed.');
    AppendMariaDbFailureDetails;
    ProgressBar.Position := ProgressBar.Max div 2;
    ModalResult := mrCancel;
  end;
end;

procedure TStartProgressForm.SyncStartupFailed;
begin
  AddMessage('MariaDB startup failed.');
  AddMessage(FResultInfo.Message);
  AppendMariaDbFailureDetails;
  AppendActivityLog('Startup: ' + FResultInfo.Message);
  ProgressBar.Position := ProgressBar.Max div 2;
  FStarting := False;
  ModalResult := mrCancel;
end;

procedure TStartProgressForm.FormShow(Sender: TObject);
begin
  if FExecuted then
    Exit;

  FExecuted := True;
  PostMessage(Handle, WM_RUN_STARTUP, 0, 0);
end;

procedure TStartProgressForm.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  CanClose := not FStarting;
  if not CanClose then
    MessageDlg('Please wait for MariaDB startup to finish before closing this window.',
      mtInformation, [mbOK], 0);
end;

procedure TStartProgressForm.WmRunStartup(var Message: TMessage);
begin
  RunStartup;
end;

procedure TStartProgressForm.RunStartup;
var
  StartupThread: TThread;
begin
  FStarting := True;
  FResultInfo.Success := False;
  FResultInfo.Message := 'MariaDB startup failed.';
  ProgressBar.Position := 15;
  AddMessage('MariaDB startup sequence started.');

  StartupThread := TThread.CreateAnonymousThread(
    procedure
    var
      ResultInfo: TRuntimeActionResult;
    begin
      try
        TThread.Synchronize(nil, SyncCheckingMariaDbFiles);
        TThread.Synchronize(nil, SyncStartingMariaDb);
        ResultInfo := FRuntime.StartMariaDb;
        FResultInfo := ResultInfo;
        TThread.Synchronize(nil, SyncStartupFinished);
      except
        on E: Exception do
        begin
          FResultInfo.Success := False;
          FResultInfo.Message := E.Message;
          TThread.Synchronize(nil, SyncStartupFailed);
        end;
      end;
    end);
  StartupThread.FreeOnTerminate := True;
  StartupThread.Start;
end;

end.
