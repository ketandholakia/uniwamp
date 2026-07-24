unit Ui.UniWamp.ConnectionProfilesForm;

interface

uses
  System.Classes,
  System.Generics.Collections,
  System.JSON,
  System.SysUtils,
  Vcl.Controls,
  Vcl.Dialogs,
  Vcl.ExtCtrls,
  Vcl.Forms,
  Vcl.Graphics,
  Vcl.StdCtrls,
  Core.UniWamp.Config,
  Core.UniWamp.Paths,
  Core.UniWamp.Secrets,
  Core.UniWamp.SyncTransport;

type
  TConnectionProfilesForm = class(TForm)
  private
    FPaths: TAppPaths;
    FConfig: TUniWampConfig;
    FProfiles: TList<TConnectionProfile>;
    FLoading: Boolean;
    FCurrentProfileIndex: Integer;
    FLoadedProfileName: string;
    FProfilesList: TListBox;
    FAddButton: TButton;
    FDeleteButton: TButton;
    FImportButton: TButton;
    FExportButton: TButton;
    FNameEdit: TEdit;
    FProtocolCombo: TComboBox;
    FHostEdit: TEdit;
    FPortEdit: TEdit;
    FUsernameEdit: TEdit;
    FPasswordEdit: TEdit;
    FKeyPassphraseEdit: TEdit;
    FPrivateKeyEdit: TEdit;
    FPrivateKeyBrowseButton: TButton;
    FPassiveCheck: TCheckBox;
    FIgnoreCertCheck: TCheckBox;
    FValidationLabel: TLabel;
    FTestButton: TButton;
    FSaveButton: TButton;
    FCancelButton: TButton;
    procedure LoadSettings;
    procedure LoadProfilesFromConfig;
    procedure RefreshProfileList;
    procedure LoadProfileIntoEditor(const Profile: TConnectionProfile);
    function DefaultProfile: TConnectionProfile;
    function CurrentProfileIndex: Integer;
    function CurrentSelectedProfile(out Profile: TConnectionProfile): Boolean;
    function ReadProfileFromEditor(out Profile: TConnectionProfile; out ErrorMessage: string): Boolean;
    function ValidateProfiles(out ErrorMessage: string): Boolean;
    function ProfileDisplayName(const Profile: TConnectionProfile): string;
    function ConnectionProfileToJson(const Profile: TConnectionProfile): TJSONObject;
    function TryReadConnectionProfilesFromJson(const FileName: string; out Profiles: TArray<TConnectionProfile>;
      out ErrorMessage: string): Boolean;
    function SaveCurrentEditor: Boolean;
    procedure PersistCurrentSecrets(const Profile: TConnectionProfile; const PreviousName: string;
      out ErrorMessage: string);
    procedure ClearEditor;
    procedure UpdateProtocolState;
    procedure UpdateValidationMessage;
    procedure SetStatus(const ColorValue: TColor; const TextValue: string);
    procedure ProfileSelectionChanged(Sender: TObject);
    procedure EditorChanged(Sender: TObject);
    procedure ProtocolChanged(Sender: TObject);
    procedure AddProfileClicked(Sender: TObject);
    procedure DeleteProfileClicked(Sender: TObject);
    procedure ImportProfilesClicked(Sender: TObject);
    procedure ExportProfilesClicked(Sender: TObject);
    procedure TestProfileClicked(Sender: TObject);
    procedure BrowsePrivateKeyClicked(Sender: TObject);
    procedure SaveClicked(Sender: TObject);
    procedure CancelClicked(Sender: TObject);
  public
    constructor Create(AOwner: TComponent); override;
    class function Execute(const AOwner: TComponent; const Paths: TAppPaths;
      Config: TUniWampConfig): Boolean;
    destructor Destroy; override;
  end;

implementation

uses
  System.IOUtils,
  System.UITypes;

const
  HeaderColor = TColor($005F3A1E);
  HeaderSubTextColor = TColor($00EFE7D4);
  FooterColor = TColor($00F2F2F2);

constructor TConnectionProfilesForm.Create(AOwner: TComponent);
var
  HeaderPanel: TPanel;
  HeaderTitle: TLabel;
  HeaderHint: TLabel;
  BodyPanel: TPanel;
  LeftPanel: TPanel;
  LeftCard: TPanel;
  LeftFooter: TPanel;
  LeftTitle: TLabel;
  LeftHint: TLabel;
  RightPanel: TPanel;
  RightScroll: TScrollBox;
  RightInner: TPanel;
  FooterPanel: TPanel;

  function AddLabel(const Parent: TWinControl; const ALeft, ATop: Integer;
    const ACaption: string; const AWidth: Integer = 0): TLabel;
  begin
    Result := TLabel.Create(Self);
    Result.Parent := Parent;
    Result.Left := ALeft;
    Result.Top := ATop;
    Result.Caption := ACaption;
    Result.Font.Name := 'Segoe UI';
    Result.Font.Size := 11;
    Result.Font.Style := [fsBold];
    Result.ParentFont := False;
    if AWidth > 0 then
      Result.Width := AWidth;
  end;

  function AddEdit(const Parent: TWinControl; const ALeft, ATop, AWidth: Integer): TEdit;
  begin
    Result := TEdit.Create(Self);
    Result.Parent := Parent;
    Result.Left := ALeft;
    Result.Top := ATop;
    Result.Width := AWidth;
    Result.Height := 23;
    Result.Font.Name := 'Segoe UI';
  end;

  function AddCombo(const Parent: TWinControl; const ALeft, ATop, AWidth: Integer): TComboBox;
  begin
    Result := TComboBox.Create(Self);
    Result.Parent := Parent;
    Result.Left := ALeft;
    Result.Top := ATop;
    Result.Width := AWidth;
    Result.Height := 23;
    Result.Style := csDropDownList;
    Result.Font.Name := 'Segoe UI';
  end;

  function AddCheck(const Parent: TWinControl; const ALeft, ATop: Integer;
    const ACaption: string): TCheckBox;
  begin
    Result := TCheckBox.Create(Self);
    Result.Parent := Parent;
    Result.Left := ALeft;
    Result.Top := ATop;
    Result.Caption := ACaption;
    Result.Font.Name := 'Segoe UI';
  end;

  function AddButton(const Parent: TWinControl; const ALeft, ATop, AWidth, AHeight: Integer;
    const ACaption: string): TButton;
  begin
    Result := TButton.Create(Self);
    Result.Parent := Parent;
    Result.Left := ALeft;
    Result.Top := ATop;
    Result.Width := AWidth;
    Result.Height := AHeight;
    Result.Caption := ACaption;
    Result.Font.Name := 'Segoe UI';
  end;

begin
  inherited CreateNew(AOwner);
  FPaths := Default(TAppPaths);
  FConfig := nil;
  FProfiles := TList<TConnectionProfile>.Create;
  FCurrentProfileIndex := -1;
  FLoadedProfileName := '';

  Caption := 'Connection Profiles';
  ClientWidth := 980;
  ClientHeight := 650;
  Color := clWhite;
  Font.Name := 'Segoe UI';
  KeyPreview := True;
  Position := poScreenCenter;
  BorderStyle := bsSizeable;
  BorderIcons := [biSystemMenu, biMinimize];

  HeaderPanel := TPanel.Create(Self);
  HeaderPanel.Parent := Self;
  HeaderPanel.Align := alTop;
  HeaderPanel.Height := 68;
  HeaderPanel.BevelOuter := bvNone;
  HeaderPanel.Color := HeaderColor;
  HeaderPanel.ParentBackground := False;

  HeaderTitle := AddLabel(HeaderPanel, 18, 13, 'Connection Profiles', 0);
  HeaderTitle.Font.Size := 17;
  HeaderTitle.Font.Color := clWhite;
  HeaderTitle.Height := 23;

  HeaderHint := AddLabel(HeaderPanel, 18, 42,
    'Manage FTP, FTPS, and SFTP connection details. Passwords and key passphrases stay in the Windows secret store.', 760);
  HeaderHint.Font.Size := 9;
  HeaderHint.Font.Color := HeaderSubTextColor;
  HeaderHint.Font.Style := [];
  HeaderHint.Height := 14;

  BodyPanel := TPanel.Create(Self);
  BodyPanel.Parent := Self;
  BodyPanel.Align := alClient;
  BodyPanel.BevelOuter := bvNone;
  BodyPanel.Color := clWhite;
  BodyPanel.ParentBackground := False;

  LeftPanel := TPanel.Create(Self);
  LeftPanel.Parent := BodyPanel;
  LeftPanel.Align := alLeft;
  LeftPanel.Width := 260;
  LeftPanel.BevelOuter := bvNone;
  LeftPanel.Color := clWhite;
  LeftPanel.ParentBackground := False;

  LeftCard := TPanel.Create(Self);
  LeftCard.Parent := LeftPanel;
  LeftCard.Align := alClient;
  LeftCard.BevelKind := bkTile;
  LeftCard.BevelOuter := bvNone;
  LeftCard.Color := clWhite;
  LeftCard.ParentBackground := False;
  LeftCard.Padding.SetBounds(5, 5, 5, 5);

  LeftTitle := AddLabel(LeftCard, 5, 5, 'Profiles', 0);
  LeftTitle.Align := alTop;
  LeftTitle.Height := 17;
  LeftTitle.Font.Size := 11;

  LeftHint := AddLabel(LeftCard, 5, 22,
    'Select a connection profile, then edit its host, login, and transport options.', 238);
  LeftHint.Align := alTop;
  LeftHint.AutoSize := False;
  LeftHint.Height := 44;
  LeftHint.Font.Style := [];
  LeftHint.Font.Color := clGrayText;
  LeftHint.WordWrap := True;

  FProfilesList := TListBox.Create(Self);
  FProfilesList.Parent := LeftCard;
  FProfilesList.Align := alClient;
  FProfilesList.BorderStyle := bsSingle;
  FProfilesList.ItemHeight := 16;
  FProfilesList.Color := clWhite;
  FProfilesList.Font.Name := 'Segoe UI';

  LeftFooter := TPanel.Create(Self);
  LeftFooter.Parent := LeftCard;
  LeftFooter.Align := alBottom;
  LeftFooter.Height := 80;
  LeftFooter.BevelOuter := bvNone;
  LeftFooter.Color := clWhite;
  LeftFooter.ParentBackground := False;

  FAddButton := AddButton(LeftFooter, 16, 12, 98, 28, 'Add');
  FDeleteButton := AddButton(LeftFooter, 124, 12, 98, 28, 'Delete');
  FImportButton := AddButton(LeftFooter, 16, 46, 98, 28, 'Import');
  FExportButton := AddButton(LeftFooter, 124, 46, 98, 28, 'Export');

  RightPanel := TPanel.Create(Self);
  RightPanel.Parent := BodyPanel;
  RightPanel.Align := alClient;
  RightPanel.BevelOuter := bvNone;
  RightPanel.Color := clWhite;
  RightPanel.ParentBackground := False;

  RightScroll := TScrollBox.Create(Self);
  RightScroll.Parent := RightPanel;
  RightScroll.Align := alClient;
  RightScroll.BorderStyle := bsNone;
  RightScroll.Color := clWhite;
  RightScroll.VertScrollBar.Visible := True;

  RightInner := TPanel.Create(Self);
  RightInner.Parent := RightScroll;
  RightInner.Align := alTop;
  RightInner.AutoSize := False;
  RightInner.BevelOuter := bvNone;
  RightInner.Color := clWhite;
  RightInner.ParentBackground := False;
  RightInner.Width := 680;
  RightInner.Height := 520;

  AddLabel(RightInner, 18, 12, 'Profile editor', 0).Font.Style := [fsBold];
  AddLabel(RightInner, 18, 32, 'Use one profile per host or endpoint.', 420).Font.Color := clGrayText;

  AddLabel(RightInner, 18, 72, 'Identity', 0).Font.Style := [fsBold];
  AddLabel(RightInner, 18, 96, 'Name', 0);
  AddLabel(RightInner, 270, 96, 'Protocol', 0);

  FNameEdit := AddEdit(RightInner, 18, 116, 228);
  FProtocolCombo := AddCombo(RightInner, 270, 116, 140);

  AddLabel(RightInner, 18, 154, 'Connection', 0).Font.Style := [fsBold];
  AddLabel(RightInner, 18, 178, 'Host', 0);
  AddLabel(RightInner, 430, 178, 'Port', 0);
  AddLabel(RightInner, 532, 178, 'Username', 0);

  FHostEdit := AddEdit(RightInner, 18, 198, 390);
  FPortEdit := AddEdit(RightInner, 430, 198, 84);
  FUsernameEdit := AddEdit(RightInner, 532, 198, 120);

  AddLabel(RightInner, 18, 238, 'Password', 0);
  AddLabel(RightInner, 430, 238, 'Key passphrase', 0);
  FPasswordEdit := AddEdit(RightInner, 18, 258, 390);
  FPasswordEdit.PasswordChar := '*';
  FKeyPassphraseEdit := AddEdit(RightInner, 430, 258, 222);
  FKeyPassphraseEdit.PasswordChar := '*';

  AddLabel(RightInner, 18, 298, 'Private key file', 0);
  FPrivateKeyEdit := AddEdit(RightInner, 18, 318, 560);
  FPrivateKeyBrowseButton := AddButton(RightInner, 588, 316, 72, 28, 'Browse');

  FPassiveCheck := AddCheck(RightInner, 18, 358, 'Passive mode');
  FIgnoreCertCheck := AddCheck(RightInner, 160, 358, 'Ignore cert errors');

  FValidationLabel := AddLabel(RightInner, 18, 398, '', 610);
  FValidationLabel.AutoSize := False;
  FValidationLabel.Height := 24;
  FValidationLabel.Font.Color := clGrayText;
  FValidationLabel.Font.Style := [];

  FTestButton := AddButton(RightInner, 18, 436, 128, 28, 'Test connection');

  FooterPanel := TPanel.Create(Self);
  FooterPanel.Parent := Self;
  FooterPanel.Align := alBottom;
  FooterPanel.Height := 56;
  FooterPanel.BevelOuter := bvNone;
  FooterPanel.Color := FooterColor;
  FooterPanel.ParentBackground := False;

  FSaveButton := AddButton(FooterPanel, 784, 14, 84, 28, 'Save');
  FSaveButton.Default := True;
  FCancelButton := AddButton(FooterPanel, 878, 14, 84, 28, 'Cancel');
  FCancelButton.Cancel := True;

  FProtocolCombo.Items.Add('ftp');
  FProtocolCombo.Items.Add('ftps');
  FProtocolCombo.Items.Add('sftp');

  FProfilesList.OnClick := ProfileSelectionChanged;
  FNameEdit.OnChange := EditorChanged;
  FProtocolCombo.OnChange := ProtocolChanged;
  FHostEdit.OnChange := EditorChanged;
  FPortEdit.OnChange := EditorChanged;
  FUsernameEdit.OnChange := EditorChanged;
  FPasswordEdit.OnChange := EditorChanged;
  FKeyPassphraseEdit.OnChange := EditorChanged;
  FPrivateKeyEdit.OnChange := EditorChanged;
  FPrivateKeyBrowseButton.OnClick := BrowsePrivateKeyClicked;
  FPassiveCheck.OnClick := EditorChanged;
  FIgnoreCertCheck.OnClick := EditorChanged;
  FAddButton.OnClick := AddProfileClicked;
  FDeleteButton.OnClick := DeleteProfileClicked;
  FImportButton.OnClick := ImportProfilesClicked;
  FExportButton.OnClick := ExportProfilesClicked;
  FTestButton.OnClick := TestProfileClicked;
  FSaveButton.OnClick := SaveClicked;
  FCancelButton.OnClick := CancelClicked;

  UpdateProtocolState;
  ClearEditor;
end;

destructor TConnectionProfilesForm.Destroy;
begin
  FProfiles.Free;
  inherited Destroy;
end;

function TConnectionProfilesForm.DefaultProfile: TConnectionProfile;
begin
  Result := Default(TConnectionProfile);
  Result.Protocol := 'sftp';
  Result.Port := 22;
  Result.PassiveMode := True;
end;

procedure TConnectionProfilesForm.LoadProfilesFromConfig;
begin
  if not Assigned(FConfig) then
    Exit;
  FProfiles.Clear;
  FProfiles.AddRange(FConfig.ConnectionProfiles);
end;

function TConnectionProfilesForm.ProfileDisplayName(const Profile: TConnectionProfile): string;
begin
  Result := Trim(Profile.Name);
  if Result = '' then
    Result := '(unnamed)';
end;

procedure TConnectionProfilesForm.RefreshProfileList;
var
  Profile: TConnectionProfile;
begin
  if not Assigned(FProfilesList) then
    Exit;
  FProfilesList.Items.BeginUpdate;
  try
    FProfilesList.Items.Clear;
    for Profile in FProfiles do
      FProfilesList.Items.Add(ProfileDisplayName(Profile));
  finally
    FProfilesList.Items.EndUpdate;
  end;
end;

function TConnectionProfilesForm.CurrentProfileIndex: Integer;
begin
  Result := -1;
  if Assigned(FProfilesList) then
    Result := FProfilesList.ItemIndex;
end;

function TConnectionProfilesForm.CurrentSelectedProfile(out Profile: TConnectionProfile): Boolean;
var
  Index: Integer;
begin
  Result := False;
  Profile := Default(TConnectionProfile);
  Index := CurrentProfileIndex;
  if (Index < 0) or (Index >= FProfiles.Count) then
    Exit;
  Profile := FProfiles[Index];
  Result := True;
end;

function TConnectionProfilesForm.ReadProfileFromEditor(out Profile: TConnectionProfile;
  out ErrorMessage: string): Boolean;
var
  Protocol: string;
begin
  Result := False;
  ErrorMessage := '';
  Profile := Default(TConnectionProfile);
  Profile.Name := Trim(FNameEdit.Text);
  if Profile.Name = '' then
  begin
    ErrorMessage := 'Profile name is required.';
    Exit;
  end;
  if FProtocolCombo.ItemIndex >= 0 then
    Protocol := LowerCase(Trim(FProtocolCombo.Items[FProtocolCombo.ItemIndex]))
  else
    Protocol := 'sftp';
  if not ((Protocol = 'ftp') or (Protocol = 'ftps') or (Protocol = 'sftp')) then
  begin
    ErrorMessage := 'Protocol must be ftp, ftps, or sftp.';
    Exit;
  end;
  Profile.Protocol := Protocol;
  Profile.Host := Trim(FHostEdit.Text);
  if Profile.Host = '' then
  begin
    ErrorMessage := 'Host is required.';
    Exit;
  end;
  if Trim(FPortEdit.Text) = '' then
  begin
    if SameText(Protocol, 'sftp') then
      Profile.Port := 22
    else
      Profile.Port := 21;
  end
  else if not TryStrToInt(Trim(FPortEdit.Text), Profile.Port) or (Profile.Port < 1) or (Profile.Port > 65535) then
  begin
    ErrorMessage := 'Port must be a number between 1 and 65535.';
    Exit;
  end;
  Profile.Username := Trim(FUsernameEdit.Text);
  Profile.PrivateKeyFile := Trim(FPrivateKeyEdit.Text);
  Profile.PassiveMode := FPassiveCheck.Checked;
  Profile.IgnoreCertErrors := FIgnoreCertCheck.Checked;
  Result := True;
end;

function TConnectionProfilesForm.ValidateProfiles(out ErrorMessage: string): Boolean;
var
  Seen: TList<string>;
  Profile: TConnectionProfile;
begin
  Result := False;
  ErrorMessage := '';
  Seen := TList<string>.Create;
  try
    for Profile in FProfiles do
    begin
      if Trim(Profile.Name) = '' then
      begin
        ErrorMessage := 'Connection profile names cannot be blank.';
        Exit;
      end;
      if Seen.Contains(UpperCase(Profile.Name)) then
      begin
        ErrorMessage := 'Duplicate connection profile name: ' + Profile.Name;
        Exit;
      end;
      Seen.Add(UpperCase(Profile.Name));
    end;
    Result := True;
  finally
    Seen.Free;
  end;
end;

function TConnectionProfilesForm.ConnectionProfileToJson(const Profile: TConnectionProfile): TJSONObject;
begin
  Result := TJSONObject.Create;
  Result.AddPair('name', Profile.Name);
  Result.AddPair('protocol', Profile.Protocol);
  Result.AddPair('host', Profile.Host);
  Result.AddPair('port', TJSONNumber.Create(Profile.Port));
  Result.AddPair('username', Profile.Username);
  Result.AddPair('privateKeyFile', Profile.PrivateKeyFile);
  Result.AddPair('passiveMode', TJSONBool.Create(Profile.PassiveMode));
  Result.AddPair('ignoreCertErrors', TJSONBool.Create(Profile.IgnoreCertErrors));
end;

function TConnectionProfilesForm.TryReadConnectionProfilesFromJson(const FileName: string;
  out Profiles: TArray<TConnectionProfile>; out ErrorMessage: string): Boolean;
var
  Root: TJSONObject;
  ArrayValue: TJSONArray;
  Obj: TJSONObject;
  Profile: TConnectionProfile;
  List: TList<TConnectionProfile>;
  I: Integer;
begin
  Result := False;
  ErrorMessage := '';
  SetLength(Profiles, 0);
  Root := TJSONObject.ParseJSONValue(TFile.ReadAllText(FileName, TEncoding.UTF8)) as TJSONObject;
  if not Assigned(Root) then
  begin
    ErrorMessage := 'Invalid JSON file.';
    Exit;
  end;
  try
    ArrayValue := Root.GetValue<TJSONArray>('connectionProfiles');
    if not Assigned(ArrayValue) then
      ArrayValue := Root.GetValue<TJSONArray>('profiles');
    if not Assigned(ArrayValue) then
    begin
      ErrorMessage := 'No connectionProfiles array found.';
      Exit;
    end;

    List := TList<TConnectionProfile>.Create;
    try
      for I := 0 to ArrayValue.Count - 1 do
      begin
        Obj := ArrayValue.Items[I] as TJSONObject;
        if not Assigned(Obj) then
          Continue;
        Profile := DefaultProfile;
        Profile.Name := Obj.GetValue<string>('name', '');
        Profile.Protocol := Obj.GetValue<string>('protocol', 'sftp');
        Profile.Host := Obj.GetValue<string>('host', '');
        Profile.Port := Obj.GetValue<Integer>('port', 0);
        Profile.Username := Obj.GetValue<string>('username', '');
        Profile.PrivateKeyFile := Obj.GetValue<string>('privateKeyFile', '');
        Profile.PassiveMode := Obj.GetValue<Boolean>('passiveMode', True);
        Profile.IgnoreCertErrors := Obj.GetValue<Boolean>('ignoreCertErrors', False);
        if Profile.Name <> '' then
          List.Add(Profile);
      end;
      Profiles := List.ToArray;
      Result := True;
    finally
      List.Free;
    end;
  finally
    Root.Free;
  end;
end;

procedure TConnectionProfilesForm.LoadProfileIntoEditor(const Profile: TConnectionProfile);
var
  Effective: TConnectionProfile;
begin
  Effective := Profile;
  if Trim(Effective.Name) = '' then
    Effective := DefaultProfile;
  FLoading := True;
  try
    FNameEdit.Text := Effective.Name;
    FProtocolCombo.ItemIndex := FProtocolCombo.Items.IndexOf(Effective.Protocol);
    if FProtocolCombo.ItemIndex < 0 then
      FProtocolCombo.ItemIndex := 2;
    FHostEdit.Text := Effective.Host;
    if Effective.Port > 0 then
      FPortEdit.Text := Effective.Port.ToString
    else
      FPortEdit.Clear;
    FUsernameEdit.Text := Effective.Username;
    FPasswordEdit.Text := LoadSecret(FPaths, SyncPasswordKey(Effective.Name));
    FKeyPassphraseEdit.Text := LoadSecret(FPaths, SyncKeyPassphraseKey(Effective.Name));
    FPrivateKeyEdit.Text := Effective.PrivateKeyFile;
    FPassiveCheck.Checked := Effective.PassiveMode;
    FIgnoreCertCheck.Checked := Effective.IgnoreCertErrors;
    FLoadedProfileName := Effective.Name;
  finally
    FLoading := False;
  end;
  UpdateProtocolState;
  UpdateValidationMessage;
end;

procedure TConnectionProfilesForm.ClearEditor;
begin
  FLoading := True;
  try
    FNameEdit.Clear;
    FProtocolCombo.ItemIndex := 2;
    FHostEdit.Clear;
    FPortEdit.Clear;
    FUsernameEdit.Clear;
    FPasswordEdit.Clear;
    FKeyPassphraseEdit.Clear;
    FPrivateKeyEdit.Clear;
    FPassiveCheck.Checked := True;
    FIgnoreCertCheck.Checked := False;
    FLoadedProfileName := '';
  finally
    FLoading := False;
  end;
  UpdateProtocolState;
  UpdateValidationMessage;
end;

procedure TConnectionProfilesForm.UpdateProtocolState;
var
  Protocol: string;
begin
  if FProtocolCombo.ItemIndex >= 0 then
    Protocol := LowerCase(Trim(FProtocolCombo.Items[FProtocolCombo.ItemIndex]))
  else
    Protocol := 'sftp';
  FPassiveCheck.Enabled := not SameText(Protocol, 'sftp');
  FIgnoreCertCheck.Enabled := SameText(Protocol, 'ftps');
  FPrivateKeyEdit.Enabled := SameText(Protocol, 'sftp');
  FPrivateKeyBrowseButton.Enabled := SameText(Protocol, 'sftp');
  FKeyPassphraseEdit.Enabled := SameText(Protocol, 'sftp');
end;

procedure TConnectionProfilesForm.UpdateValidationMessage;
var
  Profile: TConnectionProfile;
  ErrorMessage: string;
begin
  if FLoading then
    Exit;
  if not ReadProfileFromEditor(Profile, ErrorMessage) then
  begin
    SetStatus(clRed, ErrorMessage);
    Exit;
  end;
  if SameText(Profile.Protocol, 'sftp') and (Trim(FPasswordEdit.Text) <> '') then
  begin
    SetStatus(clRed, 'SFTP password auth is not supported in this build. Use an SSH key or ssh-agent.');
    Exit;
  end;
  if SameText(Profile.Protocol, 'sftp') and (Trim(FKeyPassphraseEdit.Text) <> '') then
  begin
    SetStatus(clRed, 'SFTP key passphrases are not supported in this build. Load the key into ssh-agent first.');
    Exit;
  end;
  SetStatus(TColor($002E7D32), 'Profile is valid.');
end;

procedure TConnectionProfilesForm.SetStatus(const ColorValue: TColor; const TextValue: string);
begin
  if Assigned(FValidationLabel) then
  begin
    FValidationLabel.Font.Color := ColorValue;
    FValidationLabel.Caption := TextValue;
  end;
end;

procedure TConnectionProfilesForm.ProfileSelectionChanged(Sender: TObject);
var
  Profile: TConnectionProfile;
begin
  if not SaveCurrentEditor then
    Exit;
  if CurrentSelectedProfile(Profile) then
    LoadProfileIntoEditor(Profile)
  else
    ClearEditor;
end;

procedure TConnectionProfilesForm.EditorChanged(Sender: TObject);
begin
  if FLoading then
    Exit;
  UpdateValidationMessage;
end;

procedure TConnectionProfilesForm.ProtocolChanged(Sender: TObject);
begin
  if FLoading then
    Exit;
  UpdateProtocolState;
  UpdateValidationMessage;
end;

procedure TConnectionProfilesForm.AddProfileClicked(Sender: TObject);
var
  Profile: TConnectionProfile;
begin
  if not SaveCurrentEditor then
    Exit;
  Profile := DefaultProfile;
  Profile.Name := Format('connection-%d', [FProfiles.Count + 1]);
  FProfiles.Add(Profile);
  RefreshProfileList;
  FProfilesList.ItemIndex := FProfiles.Count - 1;
  LoadProfileIntoEditor(Profile);
end;

procedure TConnectionProfilesForm.DeleteProfileClicked(Sender: TObject);
var
  Index: Integer;
begin
  Index := CurrentProfileIndex;
  if (Index < 0) or (Index >= FProfiles.Count) then
    Exit;
  if MessageDlg('Delete selected connection profile?', mtConfirmation, [mbYes, mbNo], 0) <> mrYes then
    Exit;
  DeleteAllSyncSecrets(FPaths, FProfiles[Index].Name);
  FProfiles.Delete(Index);
  RefreshProfileList;
  if FProfiles.Count > 0 then
  begin
    if Index >= FProfiles.Count then
      Index := FProfiles.Count - 1;
    FProfilesList.ItemIndex := Index;
    LoadProfileIntoEditor(FProfiles[Index]);
  end
  else
    ClearEditor;
end;

procedure TConnectionProfilesForm.ImportProfilesClicked(Sender: TObject);
var
  Dialog: TOpenDialog;
  ImportedProfiles: TArray<TConnectionProfile>;
  ErrorMessage: string;
  Profile: TConnectionProfile;
begin
  if not SaveCurrentEditor then
    Exit;
  Dialog := TOpenDialog.Create(Self);
  try
    Dialog.Filter := 'JSON files (*.json)|*.json|All files (*.*)|*.*';
    Dialog.Title := 'Import connection profiles';
    if not Dialog.Execute then
      Exit;
    if not TryReadConnectionProfilesFromJson(Dialog.FileName, ImportedProfiles, ErrorMessage) then
    begin
      MessageDlg(ErrorMessage, mtError, [mbOK], 0);
      Exit;
    end;
    for Profile in ImportedProfiles do
      FProfiles.Add(Profile);
    RefreshProfileList;
    if FProfiles.Count > 0 then
      FProfilesList.ItemIndex := 0;
    if CurrentSelectedProfile(Profile) then
      LoadProfileIntoEditor(Profile);
  finally
    Dialog.Free;
  end;
end;

procedure TConnectionProfilesForm.ExportProfilesClicked(Sender: TObject);
var
  Dialog: TSaveDialog;
  Root: TJSONObject;
  JsonArray: TJSONArray;
  Profile: TConnectionProfile;
begin
  if not SaveCurrentEditor then
    Exit;
  Dialog := TSaveDialog.Create(Self);
  try
    Dialog.Filter := 'JSON files (*.json)|*.json|All files (*.*)|*.*';
    Dialog.Title := 'Export connection profiles';
    Dialog.DefaultExt := 'json';
    Dialog.FileName := 'connection-profiles.json';
    Dialog.Options := [ofOverwritePrompt, ofPathMustExist, ofEnableSizing];
    if not Dialog.Execute then
      Exit;
    Root := TJSONObject.Create;
    try
      Root.AddPair('format', 'uniwamp-connection-profiles');
      Root.AddPair('version', TJSONNumber.Create(1));
      JsonArray := TJSONArray.Create;
      for Profile in FProfiles do
        JsonArray.AddElement(ConnectionProfileToJson(Profile));
      Root.AddPair('connectionProfiles', JsonArray);
      TFile.WriteAllText(Dialog.FileName, Root.Format(2), TEncoding.UTF8);
    finally
      Root.Free;
    end;
  finally
    Dialog.Free;
  end;
end;

procedure TConnectionProfilesForm.TestProfileClicked(Sender: TObject);
var
  Profile: TConnectionProfile;
  Credentials: TSyncCredentials;
  Transport: ISyncTransport;
  ErrorMessage: string;
  Output: string;
  ResultOk: Boolean;
begin
  if not ReadProfileFromEditor(Profile, ErrorMessage) then
  begin
    UpdateValidationMessage;
    MessageDlg(ErrorMessage, mtError, [mbOK], 0);
    Exit;
  end;
  Credentials.Protocol := Profile.Protocol;
  Credentials.Host := Profile.Host;
  Credentials.Port := Profile.Port;
  Credentials.Username := Profile.Username;
  Credentials.Password := Trim(FPasswordEdit.Text);
  Credentials.PrivateKeyFile := Profile.PrivateKeyFile;
  Credentials.KeyPassphrase := Trim(FKeyPassphraseEdit.Text);
  Credentials.PassiveMode := Profile.PassiveMode;
  Credentials.IgnoreCertErrors := Profile.IgnoreCertErrors;

  try
    Transport := CreateSyncTransport(Credentials);
    try
      Transport.Connect;
      ResultOk := Transport.RemoteDirectoryExists('/');
    finally
      Transport.Disconnect;
    end;
  except
    on E: ESyncTransportError do
    begin
      SetStatus(clRed, E.Message);
      MessageDlg(E.Message, mtError, [mbOK], 0);
      Exit;
    end;
    on E: Exception do
    begin
      Output := 'Connection test failed: ' + E.Message;
      SetStatus(clRed, Output);
      MessageDlg(Output, mtError, [mbOK], 0);
      Exit;
    end;
  end;

  if ResultOk then
  begin
    SetStatus(TColor($002E7D32), 'Connection test succeeded for ' + Profile.Host + '.');
    MessageDlg('Connection test succeeded for ' + Profile.Host + '.', mtInformation, [mbOK], 0);
  end;
end;

procedure TConnectionProfilesForm.BrowsePrivateKeyClicked(Sender: TObject);
var
  Dialog: TOpenDialog;
begin
  Dialog := TOpenDialog.Create(Self);
  try
    Dialog.Filter := 'Key files (*.key;*.pem)|*.key;*.pem|All files (*.*)|*.*';
    Dialog.Title := 'Select private key file';
    Dialog.InitialDir := FPaths.AppRoot;
    if Dialog.Execute then
      FPrivateKeyEdit.Text := Dialog.FileName;
  finally
    Dialog.Free;
  end;
end;

procedure TConnectionProfilesForm.PersistCurrentSecrets(const Profile: TConnectionProfile;
  const PreviousName: string; out ErrorMessage: string);
begin
  ErrorMessage := '';
  if (PreviousName <> '') and not SameText(PreviousName, Profile.Name) then
    DeleteAllSyncSecrets(FPaths, PreviousName);
  if not SaveSecret(FPaths, SyncPasswordKey(Profile.Name), Trim(FPasswordEdit.Text), ErrorMessage) then
    Exit;
  if not SaveSecret(FPaths, SyncKeyPassphraseKey(Profile.Name), Trim(FKeyPassphraseEdit.Text), ErrorMessage) then
    Exit;
end;

function TConnectionProfilesForm.SaveCurrentEditor: Boolean;
var
  Profile: TConnectionProfile;
  ErrorMessage: string;
  ExistingProfile: TConnectionProfile;
  Index: Integer;
begin
  Result := False;
  if not Assigned(FProfiles) then
    Exit(True);
  if not ReadProfileFromEditor(Profile, ErrorMessage) then
  begin
    if ErrorMessage <> '' then
      SetStatus(clRed, ErrorMessage);
    Exit;
  end;
  if not ValidateProfiles(ErrorMessage) then
  begin
    SetStatus(clRed, ErrorMessage);
    Exit;
  end;
  Index := CurrentProfileIndex;
  if (Index >= 0) and (Index < FProfiles.Count) then
  begin
    ExistingProfile := FProfiles[Index];
    if SameText(ExistingProfile.Name, Profile.Name) then
      FProfiles[Index] := Profile
    else
    begin
      PersistCurrentSecrets(Profile, ExistingProfile.Name, ErrorMessage);
      if ErrorMessage <> '' then
      begin
        SetStatus(clRed, ErrorMessage);
        Exit;
      end;
      FProfiles[Index] := Profile;
      FLoadedProfileName := Profile.Name;
    end;
  end
  else
    FProfiles.Add(Profile);
  if Index < 0 then
    FCurrentProfileIndex := FProfiles.Count - 1;
  RefreshProfileList;
  if FCurrentProfileIndex >= 0 then
    FProfilesList.ItemIndex := FCurrentProfileIndex;
  Result := True;
end;

procedure TConnectionProfilesForm.SaveClicked(Sender: TObject);
var
  Profile: TConnectionProfile;
  ErrorMessage: string;
begin
  if not Assigned(FConfig) then
    Exit;
  if not SaveCurrentEditor then
    Exit;
  if not ReadProfileFromEditor(Profile, ErrorMessage) then
  begin
    MessageDlg(ErrorMessage, mtError, [mbOK], 0);
    Exit;
  end;
  if not ValidateProfiles(ErrorMessage) then
  begin
    MessageDlg(ErrorMessage, mtError, [mbOK], 0);
    Exit;
  end;
  PersistCurrentSecrets(Profile, FLoadedProfileName, ErrorMessage);
  if ErrorMessage <> '' then
  begin
    MessageDlg(ErrorMessage, mtError, [mbOK], 0);
    Exit;
  end;
  FConfig.ReplaceConnectionProfiles(FProfiles.ToArray);
  FConfig.Save(FPaths);
  ModalResult := mrOk;
end;

procedure TConnectionProfilesForm.CancelClicked(Sender: TObject);
begin
  ModalResult := mrCancel;
end;

procedure TConnectionProfilesForm.LoadSettings;
begin
  if not Assigned(FConfig) then
    Exit;
  LoadProfilesFromConfig;
  RefreshProfileList;
  if FProfiles.Count > 0 then
  begin
    FProfilesList.ItemIndex := 0;
    FCurrentProfileIndex := 0;
    LoadProfileIntoEditor(FProfiles[0]);
  end
  else
    ClearEditor;
end;

class function TConnectionProfilesForm.Execute(const AOwner: TComponent; const Paths: TAppPaths;
  Config: TUniWampConfig): Boolean;
var
  Form: TConnectionProfilesForm;
begin
  Form := TConnectionProfilesForm.Create(AOwner);
  try
    Form.FPaths := Paths;
    Form.FConfig := Config;
    Form.LoadSettings;
    Result := Form.ShowModal = mrOk;
  finally
    Form.Free;
  end;
end;

end.
