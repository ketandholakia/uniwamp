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
  Vcl.Themes,
  Core.UniWamp.Types,
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
    FOpenDashboardAfterStartCheck: TCheckBox;
    FConfirmVHostDeleteCheck: TCheckBox;
    FPhpVersionCombo: TComboBox;
    FNodeVersionCombo: TComboBox;
    FPhpProfileCombo: TComboBox;
    FThemeStyleCombo: TComboBox;
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
    function ValidateSelectedPhpVersion(const Version: string; out ErrorMessage: string): Boolean;
    function ValidateSelectedNodeVersion(const Version: string; out ErrorMessage: string): Boolean;
    procedure PopulateThemeStyles;
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
  System.IOUtils,
  Vcl.Dialogs;

const
  HeaderColor = TColor($005F3A1E);
  HeaderTextColor = clWhite;
  HeaderSubTextColor = TColor($00EFE7D4);
  SurfaceColor = clWhite;
  FooterColor = TColor($00F2F2F2);

constructor TAppSettingsForm.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FPaths := Default(TAppPaths);
end;

procedure TAppSettingsForm.Loaded;
var
  PageControl: TPageControl;
  GeneralPage: TTabSheet;
begin
  inherited Loaded;
  PageControl := FindComponent('FPageControl') as TPageControl;
  GeneralPage := FindComponent('FGeneralTab') as TTabSheet;
  if Assigned(PageControl) and Assigned(GeneralPage) then
    PageControl.ActivePage := GeneralPage;
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

function TAppSettingsForm.ValidateSelectedPhpVersion(const Version: string; out ErrorMessage: string): Boolean;
var
  PhpDir: string;
  PhpExe: string;
  ModuleCandidates: TArray<string>;
begin
  Result := False;
  ErrorMessage := '';
  if Trim(Version) = '' then
  begin
    ErrorMessage := 'Select a PHP runtime version before saving settings.';
    Exit;
  end;

  PhpDir := TPath.Combine(FPaths.PhpDir, Version);
  if not TDirectory.Exists(PhpDir) then
  begin
    ErrorMessage := 'Selected PHP runtime was not found: ' + PhpDir;
    Exit;
  end;

  PhpExe := TPath.Combine(PhpDir, 'php.exe');
  if not FileExists(PhpExe) then
  begin
    ErrorMessage := 'Selected PHP runtime is missing php.exe: ' + PhpExe;
    Exit;
  end;

  ModuleCandidates := TDirectory.GetFiles(PhpDir, 'php*apache2_4.dll');
  if Length(ModuleCandidates) = 0 then
  begin
    ErrorMessage := 'Selected PHP runtime is missing the Apache module for ' + Version + '.';
    Exit;
  end;

  Result := True;
end;

function TAppSettingsForm.ValidateSelectedNodeVersion(const Version: string; out ErrorMessage: string): Boolean;
var
  NodeDir: string;
  NodeExe: string;
begin
  Result := False;
  ErrorMessage := '';
  if Trim(Version) = '' then
    Exit(True);

  NodeDir := TPath.Combine(FPaths.NodeDir, Version);
  if not TDirectory.Exists(NodeDir) then
  begin
    ErrorMessage := 'Selected Node.js runtime was not found: ' + NodeDir;
    Exit;
  end;

  NodeExe := TPath.Combine(NodeDir, 'node.exe');
  if not FileExists(NodeExe) then
  begin
    ErrorMessage := 'Selected Node.js runtime is missing node.exe: ' + NodeExe;
    Exit;
  end;

  Result := True;
end;

procedure TAppSettingsForm.LoadSettings;
begin
  if not Assigned(FConfig) then
    Exit;
  if not Assigned(FHostNameEdit) or not Assigned(FDocumentRootEdit) or
     not Assigned(FHttpPortEdit) or not Assigned(FHttpsPortEdit) or
     not Assigned(FDatabasePortEdit) or not Assigned(FTerminalPathEdit) or
     not Assigned(FEnableSslCheck) or not Assigned(FStartAllOnLaunchCheck) or
     not Assigned(FOpenDashboardAfterStartCheck) or not Assigned(FConfirmVHostDeleteCheck) or
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
  FOpenDashboardAfterStartCheck.Checked := FConfig.OpenDashboardAfterStart;
  FConfirmVHostDeleteCheck.Checked := FConfig.ConfirmVHostDelete;

  PopulateComboFromList(FPhpVersionCombo, FConfig.PhpVersions, FConfig.SelectedPhpVersion, False);
  PopulateComboFromList(FNodeVersionCombo, FConfig.NodeVersions, FConfig.SelectedNodeVersion, True);
  PopulateComboFromList(FPhpProfileCombo, ['development', 'production'], FConfig.PhpProfile, False);
  PopulateThemeStyles;
  if Assigned(FThemeStyleCombo) then
  begin
    if Trim(FConfig.ThemeStyleName) <> '' then
      FThemeStyleCombo.ItemIndex := FThemeStyleCombo.Items.IndexOf(FConfig.ThemeStyleName)
    else
      FThemeStyleCombo.ItemIndex := FThemeStyleCombo.Items.IndexOf(TStyleManager.ActiveStyle.Name);
    if FThemeStyleCombo.ItemIndex < 0 then
      FThemeStyleCombo.ItemIndex := 0;
  end;
end;

procedure TAppSettingsForm.PopulateThemeStyles;
var
  StyleName: string;
begin
  if not Assigned(FThemeStyleCombo) then
    Exit;
  FThemeStyleCombo.Items.BeginUpdate;
  try
    FThemeStyleCombo.Items.Clear;
    FThemeStyleCombo.Items.Add('Windows');
    for StyleName in TStyleManager.StyleNames do
      if SameText(StyleName, 'Windows') = False then
        FThemeStyleCombo.Items.Add(StyleName);
  finally
    FThemeStyleCombo.Items.EndUpdate;
  end;
end;

procedure TAppSettingsForm.SaveClicked(Sender: TObject);
var
  HttpPort: Integer;
  HttpsPort: Integer;
  DatabasePort: Integer;
  NormalizedText: string;
  ErrorMessage: string;
  SelectedPhpVersion: string;
  SelectedNodeVersion: string;
  SelectedPhpProfile: string;
  SelectedThemeStyle: string;
  OldPhpVersion: string;
  RestartInfo: TRuntimeActionResult;
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
  FConfig.OpenDashboardAfterStart := FOpenDashboardAfterStartCheck.Checked;
  FConfig.ConfirmVHostDelete := FConfirmVHostDeleteCheck.Checked;

  SelectedPhpVersion := FConfig.SelectedPhpVersion;
  if FPhpVersionCombo.ItemIndex >= 0 then
    SelectedPhpVersion := FPhpVersionCombo.Items[FPhpVersionCombo.ItemIndex];
  if not ValidateSelectedPhpVersion(SelectedPhpVersion, ErrorMessage) then
  begin
    MessageDlg(ErrorMessage, mtError, [mbOK], 0);
    Exit;
  end;

  SelectedNodeVersion := FConfig.SelectedNodeVersion;
  if FNodeVersionCombo.ItemIndex >= 0 then
  begin
    if SameText(FNodeVersionCombo.Items[FNodeVersionCombo.ItemIndex], '(none)') then
      SelectedNodeVersion := ''
    else
      SelectedNodeVersion := FNodeVersionCombo.Items[FNodeVersionCombo.ItemIndex];
  end;
  if not ValidateSelectedNodeVersion(SelectedNodeVersion, ErrorMessage) then
  begin
    MessageDlg(ErrorMessage, mtError, [mbOK], 0);
    Exit;
  end;

  SelectedPhpProfile := FConfig.PhpProfile;
  if FPhpProfileCombo.ItemIndex >= 0 then
    SelectedPhpProfile := FPhpProfileCombo.Items[FPhpProfileCombo.ItemIndex];
  SelectedThemeStyle := FConfig.ThemeStyleName;
  if Assigned(FThemeStyleCombo) and (FThemeStyleCombo.ItemIndex >= 0) then
    SelectedThemeStyle := FThemeStyleCombo.Items[FThemeStyleCombo.ItemIndex];

  OldPhpVersion := FConfig.SelectedPhpVersion;
  FConfig.SelectedPhpVersion := SelectedPhpVersion;
  FConfig.SelectedNodeVersion := SelectedNodeVersion;
  FConfig.PhpProfile := SelectedPhpProfile;
  FConfig.ThemeStyleName := SelectedThemeStyle;
  if Trim(SelectedThemeStyle) = '' then
    TStyleManager.SetStyle('Windows')
  else
    TStyleManager.TrySetStyle(SelectedThemeStyle);

  FConfig.Save(FPaths);
  if Assigned(FRuntime) then
  begin
    FRuntime.GenerateAllConfigs;
    if FRuntime.ApacheIsRunning and not SameText(OldPhpVersion, FConfig.SelectedPhpVersion) then
    begin
      RestartInfo := FRuntime.RestartApache;
      if not RestartInfo.Success then
      begin
        MessageDlg('Settings saved, but Apache restart failed: ' + RestartInfo.Message,
          mtWarning, [mbOK], 0);
        Exit;
      end;
    end;
  end;
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
  RegisterClass(TListBox);
  RegisterClass(TMemo);

end.
