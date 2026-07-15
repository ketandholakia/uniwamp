unit Ui.UniWamp.AppSettingsForm;

interface

uses
  System.Classes,
  System.SysUtils,
  Vcl.ComCtrls,
  Vcl.Controls,
  Vcl.ExtCtrls,
  Vcl.Forms,
  Vcl.Graphics,
  Vcl.StdCtrls,
  Core.UniWamp.Security,
  Core.UniWamp.Config,
  Core.UniWamp.Paths,
  Core.UniWamp.Runtime;

type
  TAppSettingsForm = class(TForm)
    FHostNameEdit: TEdit;
    FDocumentRootEdit: TEdit;
    FHttpPortEdit: TEdit;
    FHttpsPortEdit: TEdit;
    FDatabasePortEdit: TEdit;
    FTerminalPathEdit: TEdit;
    FEnableSslCheck: TCheckBox;
    FStartAllOnLaunchCheck: TCheckBox;
    FPhpVersionCombo: TComboBox;
    FNodeVersionCombo: TComboBox;
    FPhpProfileCombo: TComboBox;
    FSaveButton: TButton;
    FCancelButton: TButton;
  private
    FPaths: TAppPaths;
    FConfig: TUniWampConfig;
    FRuntime: TUniWampRuntime;
  protected
    procedure Loaded; override;
  private
    procedure SaveClicked(Sender: TObject);
    procedure CancelClicked(Sender: TObject);
    procedure PopulateComboFromList(Combo: TComboBox; const Values: array of string;
      const SelectedValue: string; const AllowNoneItem: Boolean = False);
  public
    constructor Create(AOwner: TComponent); override;
    procedure LoadSettings;
    class function Execute(const AOwner: TComponent; const Paths: TAppPaths;
      Config: TUniWampConfig; Runtime: TUniWampRuntime): Boolean;
  end;

implementation

{$R *.dfm}

uses
  System.UITypes,
  Vcl.Dialogs;

const
  HeaderColor = TColor($0035291F);
  HeaderTextColor = clWhite;
  HeaderSubTextColor = TColor($00D0D8DD);
  SurfaceColor = clWhite;
  FooterColor = TColor($00F2F2F2);

constructor TAppSettingsForm.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FPaths := Default(TAppPaths);
end;

procedure TAppSettingsForm.Loaded;
begin
  inherited Loaded;
  if Assigned(FSaveButton) then
    FSaveButton.OnClick := SaveClicked;
  if Assigned(FCancelButton) then
    FCancelButton.OnClick := CancelClicked;
end;

procedure TAppSettingsForm.PopulateComboFromList(Combo: TComboBox; const Values: array of string;
  const SelectedValue: string; const AllowNoneItem: Boolean);
var
  Value: string;
  SelectedIndex: Integer;
begin
  if not Assigned(Combo) then
    Exit;
  Combo.Items.BeginUpdate;
  try
    Combo.Items.Clear;
    if AllowNoneItem then
      Combo.Items.Add('(none)');
    for Value in Values do
      if Trim(Value) <> '' then
        Combo.Items.Add(Value);
  finally
    Combo.Items.EndUpdate;
  end;

  SelectedIndex := Combo.Items.IndexOf(SelectedValue);
  if AllowNoneItem and (Trim(SelectedValue) = '') then
    SelectedIndex := 0;
  if SelectedIndex < 0 then
    SelectedIndex := 0;
  Combo.ItemIndex := SelectedIndex;
end;

procedure TAppSettingsForm.LoadSettings;
begin
  if not Assigned(FConfig) then
    Exit;
  if not Assigned(FHostNameEdit) or not Assigned(FDocumentRootEdit) or
     not Assigned(FHttpPortEdit) or not Assigned(FHttpsPortEdit) or
     not Assigned(FDatabasePortEdit) or not Assigned(FTerminalPathEdit) or
     not Assigned(FEnableSslCheck) or not Assigned(FStartAllOnLaunchCheck) or
     not Assigned(FPhpVersionCombo) or
     not Assigned(FNodeVersionCombo) or not Assigned(FPhpProfileCombo) then
    Exit;
  FHostNameEdit.Text := FConfig.HostName;
  FDocumentRootEdit.Text := FConfig.DocumentRoot;
  FHttpPortEdit.Text := FConfig.HttpPort.ToString;
  FHttpsPortEdit.Text := FConfig.HttpsPort.ToString;
  FDatabasePortEdit.Text := FConfig.DatabasePort.ToString;
  FTerminalPathEdit.Text := FConfig.TerminalExePath;
  FEnableSslCheck.Checked := FConfig.EnableSsl;
  FStartAllOnLaunchCheck.Checked := FConfig.StartAllOnLaunch;

  PopulateComboFromList(FPhpVersionCombo, FConfig.PhpVersions, FConfig.SelectedPhpVersion, False);
  PopulateComboFromList(FNodeVersionCombo, FConfig.NodeVersions, FConfig.SelectedNodeVersion, True);
  PopulateComboFromList(FPhpProfileCombo, ['development', 'production'], FConfig.PhpProfile, False);
end;

procedure TAppSettingsForm.SaveClicked(Sender: TObject);
var
  HttpPort: Integer;
  HttpsPort: Integer;
  DatabasePort: Integer;
  NormalizedText: string;
  ErrorMessage: string;
begin
  if not TryStrToInt(Trim(FHttpPortEdit.Text), HttpPort) then
  begin
    MessageDlg('HTTP port must be a valid number.', mtError, [mbOK], 0);
    Exit;
  end;
  if not TryStrToInt(Trim(FHttpsPortEdit.Text), HttpsPort) then
  begin
    MessageDlg('HTTPS port must be a valid number.', mtError, [mbOK], 0);
    Exit;
  end;
  if not TryStrToInt(Trim(FDatabasePortEdit.Text), DatabasePort) then
  begin
    MessageDlg('Database port must be a valid number.', mtError, [mbOK], 0);
    Exit;
  end;

  if Trim(FHostNameEdit.Text) = '' then
    NormalizedText := 'localhost'
  else if not ValidateServerName(FHostNameEdit.Text, NormalizedText, ErrorMessage) then
  begin
    MessageDlg(ErrorMessage, mtError, [mbOK], 0);
    Exit;
  end;
  FConfig.HostName := NormalizedText;

  if Trim(FDocumentRootEdit.Text) = '' then
    NormalizedText := FPaths.WwwDir
  else if not ValidateDocumentRoot(FDocumentRootEdit.Text, NormalizedText, ErrorMessage) then
  begin
    MessageDlg(ErrorMessage, mtError, [mbOK], 0);
    Exit;
  end;
  FConfig.DocumentRoot := NormalizedText;

  FConfig.HttpPort := HttpPort;
  FConfig.HttpsPort := HttpsPort;
  FConfig.DatabasePort := DatabasePort;
  FConfig.TerminalExePath := Trim(FTerminalPathEdit.Text);
  if FConfig.TerminalExePath = '' then
    FConfig.TerminalExePath := 'bin\cmder\Cmder.exe';
  FConfig.EnableSsl := FEnableSslCheck.Checked;
  FConfig.StartAllOnLaunch := FStartAllOnLaunchCheck.Checked;

  if FPhpVersionCombo.ItemIndex >= 0 then
    FConfig.SelectedPhpVersion := FPhpVersionCombo.Items[FPhpVersionCombo.ItemIndex];
  if FNodeVersionCombo.ItemIndex >= 0 then
  begin
    if SameText(FNodeVersionCombo.Items[FNodeVersionCombo.ItemIndex], '(none)') then
      FConfig.SelectedNodeVersion := ''
    else
      FConfig.SelectedNodeVersion := FNodeVersionCombo.Items[FNodeVersionCombo.ItemIndex];
  end;
  if FPhpProfileCombo.ItemIndex >= 0 then
    FConfig.PhpProfile := FPhpProfileCombo.Items[FPhpProfileCombo.ItemIndex];

  FConfig.Save(FPaths);
  if Assigned(FRuntime) then
    FRuntime.GenerateAllConfigs;
  ModalResult := mrOk;
end;

procedure TAppSettingsForm.CancelClicked(Sender: TObject);
begin
  ModalResult := mrCancel;
end;

class function TAppSettingsForm.Execute(const AOwner: TComponent; const Paths: TAppPaths;
  Config: TUniWampConfig; Runtime: TUniWampRuntime): Boolean;
var
  Form: TAppSettingsForm;
begin
  Form := TAppSettingsForm.Create(AOwner);
  try
    Form.FPaths := Paths;
    Form.FConfig := Config;
    Form.FRuntime := Runtime;
    Form.LoadSettings;
    Result := Form.ShowModal = mrOk;
  finally
    Form.Free;
  end;
end;

initialization
  RegisterClass(TPanel);
  RegisterClass(TPageControl);
  RegisterClass(TTabSheet);
  RegisterClass(TLabel);
  RegisterClass(TEdit);
  RegisterClass(TCheckBox);
  RegisterClass(TComboBox);
  RegisterClass(TButton);

end.
