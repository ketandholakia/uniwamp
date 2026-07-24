unit Ui.UniWamp.SyncProfilesForm;

interface

uses
  System.Classes,
  System.Generics.Collections,
  System.JSON,
  System.SysUtils,
  Vcl.ComCtrls,
  Vcl.Controls,
  Vcl.ExtCtrls,
  Vcl.Forms,
  Vcl.Graphics,
  Vcl.StdCtrls,
  Core.UniWamp.Config,
  Core.UniWamp.Paths,
  Core.UniWamp.Runtime,
  Core.UniWamp.Secrets,
  Core.UniWamp.SyncEngine,
  Core.UniWamp.SyncTransport;

type
  TSyncProfilesForm = class(TForm)
  private
    FPaths: TAppPaths;
    FConfig: TUniWampConfig;
    FRuntime: TUniWampRuntime;
    FProfiles: TList<TSyncProfile>;
    FLoading: Boolean;
    FCurrentProfileIndex: Integer;
    FLoadedProfileName: string;
    FProfilesList: TListBox;
    FAddButton: TButton;
    FDeleteButton: TButton;
    FImportButton: TButton;
    FExportButton: TButton;
    FNameEdit: TEdit;
    FConnectionProfileCombo: TComboBox;
    FProtocolCombo: TComboBox;
    FDirectionCombo: TComboBox;
    FHostEdit: TEdit;
    FPortEdit: TEdit;
    FUsernameEdit: TEdit;
    FPasswordEdit: TEdit;
    FKeyPassphraseEdit: TEdit;
    FPrivateKeyEdit: TEdit;
    FPrivateKeyBrowseButton: TButton;
    FPassiveCheck: TCheckBox;
    FIgnoreCertCheck: TCheckBox;
    FVHostCombo: TComboBox;
    FRemotePathEdit: TEdit;
    FLocalPathEdit: TEdit;
    FWorkingDirEdit: TEdit;
    FPreCommandEdit: TEdit;
    FPostCommandEdit: TEdit;
    FDeleteCheck: TCheckBox;
    FDryRunCheck: TCheckBox;
    FExcludesMemo: TMemo;
    FValidationLabel: TLabel;
    FTestButton: TButton;
    FTestPathButton: TButton;
    FPreviewButton: TButton;
    FSaveButton: TButton;
    FCancelButton: TButton;
    procedure LoadSettings;
    procedure LoadProfilesFromConfig;
    procedure PopulateConnectionProfileList;
    procedure PopulateVHostList;
    procedure RefreshProfileList;
    procedure LoadProfileIntoEditor(const Profile: TSyncProfile);
    function DefaultProfile: TSyncProfile;
    function CurrentProfileIndex: Integer;
    function CurrentSelectedSyncProfile(out Profile: TSyncProfile): Boolean;
    function ReadProfileFromEditor(out Profile: TSyncProfile; out ErrorMessage: string): Boolean;
    function ValidateProfiles(out ErrorMessage: string): Boolean;
    function ProfileDisplayName(const Profile: TSyncProfile): string;
    function TryGetSelectedVHost(out Entry: TVHostEntry): Boolean;
    procedure GetSyncContext(out ServerName, DocumentRoot, ProjectRoot: string);
    function ApplyVHostTokens(const Value, ServerName, DocumentRoot, ProjectRoot: string): string;
    function ResolvePortablePath(const PathValue: string): string;
    function BuildResolvedProfile(const Profile: TSyncProfile): TSyncProfile;
    function ResolveExecutionPaths(const Profile: TSyncProfile; out LocalPath, WorkingDirectory,
      RemotePath, ErrorMessage: string): Boolean;
    function BuildCredentialsFromEditor(const Profile: TSyncProfile): TSyncCredentials;
    function DescribePlan(const Plan: TSyncPlan): string;
    function SyncProfileToJson(const Profile: TSyncProfile): TJSONObject;
    function TryReadSyncProfilesFromJson(const FileName: string; out Profiles: TArray<TSyncProfile>;
      out ErrorMessage: string): Boolean;
    function SaveCurrentEditor: Boolean;
    procedure PersistCurrentSecrets(const Profile: TSyncProfile; const PreviousName: string;
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
    procedure TestTargetPathClicked(Sender: TObject);
    procedure PreviewProfileClicked(Sender: TObject);
    procedure BrowsePrivateKeyClicked(Sender: TObject);
    procedure SaveClicked(Sender: TObject);
    procedure CancelClicked(Sender: TObject);
  public
    constructor Create(AOwner: TComponent); override;
    class function Execute(const AOwner: TComponent; const Paths: TAppPaths;
      Config: TUniWampConfig; Runtime: TUniWampRuntime): Boolean;
    destructor Destroy; override;
  end;

implementation

uses
  System.IOUtils,
  System.UITypes,
  Vcl.Dialogs;

const
  HeaderColor = TColor($005F3A1E);
  HeaderTextColor = clWhite;
  HeaderSubTextColor = TColor($00EFE7D4);
  SurfaceColor = clWhite;
  FooterColor = TColor($00F2F2F2);

constructor TSyncProfilesForm.Create(AOwner: TComponent);
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

  procedure PopulateProtocolAndDirection;
  begin
    FProtocolCombo.Items.BeginUpdate;
    try
      FProtocolCombo.Items.Clear;
      FProtocolCombo.Items.Add('ftp');
      FProtocolCombo.Items.Add('ftps');
      FProtocolCombo.Items.Add('sftp');
      FProtocolCombo.ItemIndex := 2;
    finally
      FProtocolCombo.Items.EndUpdate;
    end;

    FDirectionCombo.Items.BeginUpdate;
    try
      FDirectionCombo.Items.Clear;
      FDirectionCombo.Items.Add('upload');
      FDirectionCombo.Items.Add('download');
      FDirectionCombo.ItemIndex := 0;
    finally
      FDirectionCombo.Items.EndUpdate;
    end;
  end;

begin
  inherited CreateNew(AOwner);
  FPaths := Default(TAppPaths);
  FConfig := nil;
  FRuntime := nil;
  FProfiles := TList<TSyncProfile>.Create;
  FCurrentProfileIndex := -1;
  FLoadedProfileName := '';

  Caption := 'Sync Profiles';
  ClientWidth := 1160;
  ClientHeight := 760;
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

  HeaderTitle := AddLabel(HeaderPanel, 18, 13, 'Sync Profiles', 0);
  HeaderTitle.Font.Size := 17;
  HeaderTitle.Font.Color := HeaderTextColor;
  HeaderTitle.Font.Style := [fsBold];
  HeaderTitle.ParentFont := False;

  HeaderHint := AddLabel(HeaderPanel, 18, 42,
    'Manage FTP, FTPS, and SFTP profiles for the native sync engine. SFTP in this build uses OpenSSH with ssh-agent or an unencrypted key. Connection profiles are managed separately.', 0);
  HeaderHint.Font.Size := 10;
  HeaderHint.Font.Color := HeaderSubTextColor;
  HeaderHint.Font.Style := [];
  HeaderHint.ParentFont := False;

  BodyPanel := TPanel.Create(Self);
  BodyPanel.Parent := Self;
  BodyPanel.Align := alClient;
  BodyPanel.BevelOuter := bvNone;
  BodyPanel.Color := clWhite;
  BodyPanel.ParentBackground := False;

  LeftPanel := TPanel.Create(Self);
  LeftPanel.Parent := BodyPanel;
  LeftPanel.Align := alLeft;
  LeftPanel.Width := 300;
  LeftPanel.BevelOuter := bvNone;
  LeftPanel.Color := clWhite;
  LeftPanel.ParentBackground := False;

  LeftCard := TPanel.Create(Self);
  LeftCard.Parent := LeftPanel;
  LeftCard.Align := alClient;
  LeftCard.BevelKind := bkTile;
  LeftCard.BevelOuter := bvNone;
  LeftCard.Color := SurfaceColor;
  LeftCard.ParentBackground := False;
  LeftCard.Padding.Left := 5;
  LeftCard.Padding.Top := 5;
  LeftCard.Padding.Right := 5;
  LeftCard.Padding.Bottom := 5;

  LeftTitle := AddLabel(LeftCard, 5, 5, 'Profiles', 0);
  LeftTitle.Align := alTop;
  LeftTitle.Font.Style := [fsBold];
  LeftTitle.ParentFont := False;

  LeftHint := TLabel.Create(Self);
  LeftHint.Parent := LeftCard;
  LeftHint.Align := alTop;
  LeftHint.Caption := 'Pick a profile, then edit connection details and paths.';
  LeftHint.WordWrap := True;
  LeftHint.AutoSize := False;
  LeftHint.Height := 44;
  LeftHint.Font.Name := 'Segoe UI';
  LeftHint.Font.Size := 12;
  LeftHint.Font.Color := clGrayText;
  LeftHint.ParentFont := False;

  LeftFooter := TPanel.Create(Self);
  LeftFooter.Parent := LeftCard;
  LeftFooter.Align := alBottom;
  LeftFooter.Height := 104;
  LeftFooter.BevelOuter := bvNone;
  LeftFooter.Color := SurfaceColor;
  LeftFooter.ParentBackground := False;

  FAddButton := AddButton(LeftFooter, 12, 12, 112, 28, 'Add');
  FDeleteButton := AddButton(LeftFooter, 132, 12, 112, 28, 'Delete');
  FImportButton := AddButton(LeftFooter, 12, 52, 112, 28, 'Import');
  FExportButton := AddButton(LeftFooter, 132, 52, 112, 28, 'Export');

  FProfilesList := TListBox.Create(Self);
  FProfilesList.Parent := LeftCard;
  FProfilesList.Align := alClient;
  FProfilesList.BorderStyle := bsSingle;
  FProfilesList.ItemHeight := 16;
  FProfilesList.Color := clWhite;
  FProfilesList.Font.Name := 'Segoe UI';

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
  RightInner.Width := 820;
  RightInner.Height := 860;

  AddLabel(RightInner, 18, 12, 'Profile editor', 0).Font.Style := [fsBold];
  AddLabel(RightInner, 18, 32,
    'Sync profiles reference connection profiles managed in the dedicated Connection Profiles window.', 520)
    .Font.Color := clGrayText;

  AddLabel(RightInner, 18, 74, 'Identity', 0).Font.Style := [fsBold];
  AddLabel(RightInner, 18, 98, 'Name', 0);
  AddLabel(RightInner, 270, 98, 'Connection profile', 0);
  AddLabel(RightInner, 540, 98, 'Protocol', 0);
  AddLabel(RightInner, 700, 98, 'Direction', 0);

  FNameEdit := AddEdit(RightInner, 18, 118, 232);
  FConnectionProfileCombo := AddCombo(RightInner, 270, 118, 252);
  FProtocolCombo := AddCombo(RightInner, 540, 118, 140);
  FDirectionCombo := AddCombo(RightInner, 700, 118, 102);

  AddLabel(RightInner, 18, 156, 'Connection', 0).Font.Style := [fsBold];
  AddLabel(RightInner, 18, 180, 'Host', 0);
  AddLabel(RightInner, 430, 180, 'Port', 0);
  AddLabel(RightInner, 532, 180, 'Username', 0);

  FHostEdit := AddEdit(RightInner, 18, 200, 390);
  FPortEdit := AddEdit(RightInner, 430, 200, 84);
  FUsernameEdit := AddEdit(RightInner, 532, 200, 252);

  AddLabel(RightInner, 18, 240, 'Password', 0);
  AddLabel(RightInner, 430, 240, 'Key passphrase', 0);

  FPasswordEdit := AddEdit(RightInner, 18, 260, 390);
  FPasswordEdit.PasswordChar := '*';
  FKeyPassphraseEdit := AddEdit(RightInner, 430, 260, 354);
  FKeyPassphraseEdit.PasswordChar := '*';

  AddLabel(RightInner, 18, 300, 'Private key file', 0);
  FPrivateKeyEdit := AddEdit(RightInner, 18, 320, 600);
  FPrivateKeyBrowseButton := AddButton(RightInner, 628, 318, 80, 28, 'Browse');

  FPassiveCheck := AddCheck(RightInner, 18, 360, 'Passive mode');
  FIgnoreCertCheck := AddCheck(RightInner, 160, 360, 'Ignore cert errors');

  AddLabel(RightInner, 18, 404, 'Context and paths', 0).Font.Style := [fsBold];
  AddLabel(RightInner, 18, 428, 'Test vHost', 0);
  AddLabel(RightInner, 318, 428, 'Remote path', 0);
  AddLabel(RightInner, 18, 488, 'Local path', 0);
  AddLabel(RightInner, 430, 488, 'Working directory', 0);

  FVHostCombo := AddCombo(RightInner, 18, 448, 280);
  FRemotePathEdit := AddEdit(RightInner, 318, 448, 390);
  FLocalPathEdit := AddEdit(RightInner, 18, 508, 390);
  FWorkingDirEdit := AddEdit(RightInner, 430, 508, 278);

  AddLabel(RightInner, 18, 548, 'Hooks and safety', 0).Font.Style := [fsBold];
  AddLabel(RightInner, 18, 572, 'Pre-sync command', 0);
  AddLabel(RightInner, 430, 572, 'Post-sync command', 0);

  FPreCommandEdit := AddEdit(RightInner, 18, 592, 390);
  FPostCommandEdit := AddEdit(RightInner, 430, 592, 278);

  FDeleteCheck := AddCheck(RightInner, 18, 636, 'Delete extra files on target');
  FDryRunCheck := AddCheck(RightInner, 272, 636, 'Dry run by default');

  AddLabel(RightInner, 18, 674, 'Exclude patterns', 0);
  FExcludesMemo := TMemo.Create(Self);
  FExcludesMemo.Parent := RightInner;
  FExcludesMemo.Left := 18;
  FExcludesMemo.Top := 694;
  FExcludesMemo.Width := 690;
  FExcludesMemo.Height := 92;
  FExcludesMemo.ScrollBars := ssVertical;
  FExcludesMemo.WordWrap := False;
  FExcludesMemo.Font.Name := 'Segoe UI';

  FValidationLabel := AddLabel(RightInner, 18, 796, '', 690);
  FValidationLabel.AutoSize := False;
  FValidationLabel.Height := 24;
  FValidationLabel.Font.Color := clGrayText;
  FValidationLabel.Font.Style := [];

  FTestButton := AddButton(RightInner, 18, 830, 128, 28, 'Test connection');
  FTestPathButton := AddButton(RightInner, 156, 830, 128, 28, 'Test path');
  FPreviewButton := AddButton(RightInner, 294, 830, 128, 28, 'Preview');

  FooterPanel := TPanel.Create(Self);
  FooterPanel.Parent := Self;
  FooterPanel.Align := alBottom;
  FooterPanel.Height := 56;
  FooterPanel.BevelOuter := bvNone;
  FooterPanel.Color := FooterColor;
  FooterPanel.ParentBackground := False;

  FSaveButton := AddButton(FooterPanel, 948, 14, 84, 28, 'Save');
  FSaveButton.Default := True;
  FCancelButton := AddButton(FooterPanel, 1042, 14, 84, 28, 'Cancel');
  FCancelButton.Cancel := True;

  PopulateProtocolAndDirection;

  FProfilesList.OnClick := ProfileSelectionChanged;
  FNameEdit.OnChange := EditorChanged;
  FConnectionProfileCombo.OnChange := EditorChanged;
  FProtocolCombo.OnChange := ProtocolChanged;
  FDirectionCombo.OnChange := EditorChanged;
  FHostEdit.OnChange := EditorChanged;
  FPortEdit.OnChange := EditorChanged;
  FUsernameEdit.OnChange := EditorChanged;
  FPasswordEdit.OnChange := EditorChanged;
  FKeyPassphraseEdit.OnChange := EditorChanged;
  FPrivateKeyEdit.OnChange := EditorChanged;
  FPrivateKeyBrowseButton.OnClick := BrowsePrivateKeyClicked;
  FPassiveCheck.OnClick := EditorChanged;
  FIgnoreCertCheck.OnClick := EditorChanged;
  FVHostCombo.OnChange := EditorChanged;
  FRemotePathEdit.OnChange := EditorChanged;
  FLocalPathEdit.OnChange := EditorChanged;
  FWorkingDirEdit.OnChange := EditorChanged;
  FPreCommandEdit.OnChange := EditorChanged;
  FPostCommandEdit.OnChange := EditorChanged;
  FDeleteCheck.OnClick := EditorChanged;
  FDryRunCheck.OnClick := EditorChanged;
  FExcludesMemo.OnChange := EditorChanged;
  FAddButton.OnClick := AddProfileClicked;
  FDeleteButton.OnClick := DeleteProfileClicked;
  FImportButton.OnClick := ImportProfilesClicked;
  FExportButton.OnClick := ExportProfilesClicked;
  FTestButton.OnClick := TestProfileClicked;
  FTestPathButton.OnClick := TestTargetPathClicked;
  FPreviewButton.OnClick := PreviewProfileClicked;
  FSaveButton.OnClick := SaveClicked;
  FCancelButton.OnClick := CancelClicked;

  UpdateProtocolState;
  ClearEditor;
end;

destructor TSyncProfilesForm.Destroy;
begin
  FProfiles.Free;
  inherited Destroy;
end;

function TSyncProfilesForm.DefaultProfile: TSyncProfile;
begin
  Result := Default(TSyncProfile);
  Result.Protocol := 'sftp';
  Result.Direction := 'upload';
  Result.Port := 22;
  Result.PassiveMode := True;
  Result.IgnoreCertErrors := False;
  Result.DryRunByDefault := True;
end;

procedure TSyncProfilesForm.LoadProfilesFromConfig;
begin
  if not Assigned(FConfig) then
    Exit;
  FProfiles.Clear;
  FProfiles.AddRange(FConfig.SyncProfiles);
end;

procedure TSyncProfilesForm.PopulateConnectionProfileList;
var
  Profile: TConnectionProfile;
begin
  if not Assigned(FConnectionProfileCombo) then
    Exit;
  FConnectionProfileCombo.Items.BeginUpdate;
  try
    FConnectionProfileCombo.Items.Clear;
    FConnectionProfileCombo.Items.Add('(none)');
    if Assigned(FConfig) then
      for Profile in FConfig.ConnectionProfiles do
        FConnectionProfileCombo.Items.Add(Profile.Name);
  finally
    FConnectionProfileCombo.Items.EndUpdate;
  end;
end;

procedure TSyncProfilesForm.PopulateVHostList;
var
  Entry: TVHostEntry;
begin
  if not Assigned(FVHostCombo) then
    Exit;
  FVHostCombo.Items.BeginUpdate;
  try
    FVHostCombo.Items.Clear;
    FVHostCombo.Items.Add('(application defaults)');
  if Assigned(FConfig) then
      for Entry in FConfig.VHosts do
        FVHostCombo.Items.Add(Entry.ServerName);
  finally
    FVHostCombo.Items.EndUpdate;
  end;
end;

function TSyncProfilesForm.ProfileDisplayName(const Profile: TSyncProfile): string;
begin
  Result := Trim(Profile.Name);
  if Result = '' then
    Result := '(unnamed)';
end;

procedure TSyncProfilesForm.RefreshProfileList;
var
  Profile: TSyncProfile;
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

function TSyncProfilesForm.CurrentProfileIndex: Integer;
begin
  Result := -1;
  if Assigned(FProfilesList) then
    Result := FProfilesList.ItemIndex;
end;

function TSyncProfilesForm.CurrentSelectedSyncProfile(out Profile: TSyncProfile): Boolean;
var
  Index: Integer;
begin
  Result := False;
  Profile := Default(TSyncProfile);
  Index := CurrentProfileIndex;
  if (Index < 0) or (Index >= FProfiles.Count) then
    Exit;
  Profile := FProfiles[Index];
  Result := True;
end;

function TSyncProfilesForm.ReadProfileFromEditor(out Profile: TSyncProfile;
  out ErrorMessage: string): Boolean;
var
  I: Integer;
  Excludes: TList<string>;
  Value: string;
begin
  Result := False;
  ErrorMessage := '';
  Profile := Default(TSyncProfile);

  Profile.Name := Trim(FNameEdit.Text);
  if Profile.Name = '' then
  begin
    ErrorMessage := 'Sync profile name is required.';
    Exit;
  end;

  if FProtocolCombo.ItemIndex >= 0 then
    Profile.Protocol := LowerCase(Trim(FProtocolCombo.Items[FProtocolCombo.ItemIndex]))
  else
    Profile.Protocol := 'sftp';
  if not ((Profile.Protocol = 'ftp') or (Profile.Protocol = 'ftps') or (Profile.Protocol = 'sftp')) then
  begin
    ErrorMessage := 'Sync protocol must be ftp, ftps, or sftp.';
    Exit;
  end;

  if FDirectionCombo.ItemIndex >= 0 then
    Profile.Direction := LowerCase(Trim(FDirectionCombo.Items[FDirectionCombo.ItemIndex]))
  else
    Profile.Direction := 'upload';
  if not ((Profile.Direction = 'upload') or (Profile.Direction = 'download')) then
  begin
    ErrorMessage := 'Sync direction must be upload or download.';
    Exit;
  end;

  if Assigned(FConnectionProfileCombo) and (FConnectionProfileCombo.ItemIndex > 0) then
    Profile.ConnectionProfileName := Trim(FConnectionProfileCombo.Items[FConnectionProfileCombo.ItemIndex])
  else
    Profile.ConnectionProfileName := '';

  Profile.Host := Trim(FHostEdit.Text);
  if Profile.Host = '' then
  begin
    ErrorMessage := 'Sync profile host is required.';
    Exit;
  end;

  if Trim(FPortEdit.Text) = '' then
  begin
    if Profile.Protocol = 'sftp' then
      Profile.Port := 22
    else
      Profile.Port := 21;
  end
  else if not TryStrToInt(Trim(FPortEdit.Text), Profile.Port) or (Profile.Port < 1) or (Profile.Port > 65535) then
  begin
    ErrorMessage := 'Sync profile port must be a valid TCP port.';
    Exit;
  end;

  Profile.Username := Trim(FUsernameEdit.Text);
  Profile.PrivateKeyFile := Trim(FPrivateKeyEdit.Text);
  Profile.PassiveMode := FPassiveCheck.Checked;
  Profile.IgnoreCertErrors := FIgnoreCertCheck.Checked;

  if Assigned(FVHostCombo) and (FVHostCombo.ItemIndex > 0) then
    Profile.DefaultTestVHost := Trim(FVHostCombo.Items[FVHostCombo.ItemIndex])
  else
    Profile.DefaultTestVHost := '';

  Profile.PreSyncCommand := Trim(FPreCommandEdit.Text);
  Profile.PostSyncCommand := Trim(FPostCommandEdit.Text);
  Profile.RemotePath := Trim(FRemotePathEdit.Text);
  if Profile.RemotePath = '' then
  begin
    ErrorMessage := 'Sync profile remote path is required.';
    Exit;
  end;

  Profile.LocalPath := Trim(FLocalPathEdit.Text);
  if Profile.LocalPath = '' then
  begin
    ErrorMessage := 'Sync profile local path is required.';
    Exit;
  end;

  Profile.WorkingDirectory := Trim(FWorkingDirEdit.Text);
  Profile.DeleteEnabled := FDeleteCheck.Checked;
  Profile.DryRunByDefault := FDryRunCheck.Checked;

  Excludes := TList<string>.Create;
  try
    for I := 0 to FExcludesMemo.Lines.Count - 1 do
    begin
      Value := Trim(FExcludesMemo.Lines[I]);
      if Value <> '' then
        Excludes.Add(Value);
    end;
    Profile.Excludes := Excludes.ToArray;
  finally
    Excludes.Free;
  end;

  Result := True;
end;

function TSyncProfilesForm.ValidateProfiles(out ErrorMessage: string): Boolean;
var
  I: Integer;
  J: Integer;
begin
  Result := False;
  ErrorMessage := '';
  for I := 0 to FProfiles.Count - 1 do
  begin
    if Trim(FProfiles[I].Name) = '' then
    begin
      ErrorMessage := 'Sync profile names cannot be blank.';
      Exit;
    end;
    for J := I + 1 to FProfiles.Count - 1 do
      if SameText(FProfiles[I].Name, FProfiles[J].Name) then
      begin
        ErrorMessage := 'Sync profile names must be unique. Duplicate: ' + ProfileDisplayName(FProfiles[I]);
        Exit;
      end;
  end;
  Result := True;
end;

function TSyncProfilesForm.TryGetSelectedVHost(out Entry: TVHostEntry): Boolean;
var
  Item: TVHostEntry;
  SelectedName: string;
begin
  Result := False;
  Entry := Default(TVHostEntry);
  if not Assigned(FVHostCombo) or (FVHostCombo.ItemIndex <= 0) or not Assigned(FConfig) then
    Exit;
  SelectedName := Trim(FVHostCombo.Items[FVHostCombo.ItemIndex]);
  for Item in FConfig.VHosts do
    if SameText(Item.ServerName, SelectedName) then
    begin
      Entry := Item;
      Exit(True);
    end;
end;

procedure TSyncProfilesForm.GetSyncContext(out ServerName, DocumentRoot, ProjectRoot: string);
var
  Entry: TVHostEntry;
begin
  if TryGetSelectedVHost(Entry) then
  begin
    ServerName := Entry.ServerName;
    DocumentRoot := Entry.DocumentRoot;
    ProjectRoot := ExcludeTrailingPathDelimiter(Entry.DocumentRoot);
    if SameText(ExtractFileName(ProjectRoot), 'public') then
      ProjectRoot := ExtractFileDir(ProjectRoot);
  end
  else
  begin
    ServerName := FConfig.HostName;
    DocumentRoot := FConfig.DocumentRoot;
    ProjectRoot := FPaths.WwwDir;
  end;
end;

function TSyncProfilesForm.ApplyVHostTokens(const Value, ServerName, DocumentRoot,
  ProjectRoot: string): string;
begin
  Result := StringReplace(Value, '{serverName}', ServerName, [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, '{documentRoot}', DocumentRoot, [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, '{projectRoot}', ProjectRoot, [rfReplaceAll, rfIgnoreCase]);
end;

function TSyncProfilesForm.ResolvePortablePath(const PathValue: string): string;
begin
  Result := Trim(StringReplace(PathValue, '/', '\', [rfReplaceAll]));
  if (Result <> '') and not TPath.IsPathRooted(Result) then
    Result := ExpandFileName(TPath.Combine(FPaths.AppRoot, Result));
end;

function TSyncProfilesForm.BuildResolvedProfile(const Profile: TSyncProfile): TSyncProfile;
var
  ServerName: string;
  DocumentRoot: string;
  ProjectRoot: string;
begin
  Result := Profile;
  GetSyncContext(ServerName, DocumentRoot, ProjectRoot);
  Result.LocalPath := ApplyVHostTokens(Result.LocalPath, ServerName, DocumentRoot, ProjectRoot);
  Result.WorkingDirectory := ApplyVHostTokens(Result.WorkingDirectory, ServerName, DocumentRoot, ProjectRoot);
  Result.RemotePath := ApplyVHostTokens(Result.RemotePath, ServerName, DocumentRoot, ProjectRoot);
  Result.PrivateKeyFile := ResolvePortablePath(Result.PrivateKeyFile);
end;

function TSyncProfilesForm.ResolveExecutionPaths(const Profile: TSyncProfile; out LocalPath,
  WorkingDirectory, RemotePath, ErrorMessage: string): Boolean;
var
  ResolvedProfile: TSyncProfile;
begin
  Result := False;
  ErrorMessage := '';

  ResolvedProfile := BuildResolvedProfile(Profile);
  LocalPath := ResolvePortablePath(ResolvedProfile.LocalPath);
  if LocalPath = '' then
  begin
    ErrorMessage := 'Sync profile local path is invalid.';
    Exit;
  end;

  if SameText(Profile.Direction, 'upload') then
  begin
    if not TDirectory.Exists(LocalPath) then
    begin
      ErrorMessage := 'Local sync source not found: ' + LocalPath;
      Exit;
    end;
  end
  else if SameText(Profile.Direction, 'download') then
  begin
    if not TDirectory.Exists(LocalPath) then
      TDirectory.CreateDirectory(LocalPath);
  end
  else
  begin
    ErrorMessage := 'Unsupported sync direction: ' + Profile.Direction;
    Exit;
  end;

  WorkingDirectory := ResolvePortablePath(ResolvedProfile.WorkingDirectory);
  if WorkingDirectory = '' then
    WorkingDirectory := FPaths.AppRoot;

  RemotePath := Trim(ResolvedProfile.RemotePath);
  if RemotePath = '' then
  begin
    ErrorMessage := 'Sync profile remote path is invalid.';
    Exit;
  end;

  Result := True;
end;

function TSyncProfilesForm.BuildCredentialsFromEditor(const Profile: TSyncProfile): TSyncCredentials;
var
  ConnectionProfile: TConnectionProfile;
  Found: Boolean;
begin
  Found := False;
  if Assigned(FConfig) and (Trim(Profile.ConnectionProfileName) <> '') then
    for ConnectionProfile in FConfig.ConnectionProfiles do
      if SameText(ConnectionProfile.Name, Profile.ConnectionProfileName) then
      begin
        Result.Protocol := ConnectionProfile.Protocol;
        Result.Host := ConnectionProfile.Host;
        Result.Port := ConnectionProfile.Port;
        Result.Username := ConnectionProfile.Username;
        Result.PrivateKeyFile := ResolvePortablePath(ConnectionProfile.PrivateKeyFile);
        Result.PassiveMode := ConnectionProfile.PassiveMode;
        Result.IgnoreCertErrors := ConnectionProfile.IgnoreCertErrors;
        Found := True;
        Break;
      end;

  if not Found then
  begin
    Result.Protocol := Profile.Protocol;
    Result.Host := Profile.Host;
    Result.Port := Profile.Port;
    Result.Username := Profile.Username;
    Result.PrivateKeyFile := ResolvePortablePath(Profile.PrivateKeyFile);
    Result.PassiveMode := Profile.PassiveMode;
    Result.IgnoreCertErrors := Profile.IgnoreCertErrors;
  end;

  Result.Password := Trim(FPasswordEdit.Text);
  Result.KeyPassphrase := Trim(FKeyPassphraseEdit.Text);
end;

function TSyncProfilesForm.DescribePlan(const Plan: TSyncPlan): string;
var
  Uploads: Integer;
  Downloads: Integer;
  Deletes: Integer;
  Dirs: Integer;
  Item: TSyncPlanItem;
begin
  Uploads := 0;
  Downloads := 0;
  Deletes := 0;
  Dirs := 0;
  for Item in Plan do
    case Item.Kind of
      spiUpload: Inc(Uploads);
      spiDownload: Inc(Downloads);
      spiDeleteRemote, spiDeleteLocal: Inc(Deletes);
      spiCreateRemoteDir: Inc(Dirs);
    end;
  if Length(Plan) = 0 then
    Exit('Nothing to sync - remote and local are already in sync.');
  Result := Format('%d file(s) to upload, %d to download, %d to delete, %d remote director(y/ies) to create.',
    [Uploads, Downloads, Deletes, Dirs]);
end;

function TSyncProfilesForm.SyncProfileToJson(const Profile: TSyncProfile): TJSONObject;
var
  ExcludesArray: TJSONArray;
  ExcludeValue: string;
begin
  Result := TJSONObject.Create;
  Result.AddPair('name', Profile.Name);
  Result.AddPair('connectionProfileName', Profile.ConnectionProfileName);
  Result.AddPair('protocol', Profile.Protocol);
  Result.AddPair('direction', Profile.Direction);
  Result.AddPair('host', Profile.Host);
  Result.AddPair('port', TJSONNumber.Create(Profile.Port));
  Result.AddPair('username', Profile.Username);
  Result.AddPair('privateKeyFile', Profile.PrivateKeyFile);
  Result.AddPair('passiveMode', TJSONBool.Create(Profile.PassiveMode));
  Result.AddPair('ignoreCertErrors', TJSONBool.Create(Profile.IgnoreCertErrors));
  Result.AddPair('defaultTestVHost', Profile.DefaultTestVHost);
  Result.AddPair('preSyncCommand', Profile.PreSyncCommand);
  Result.AddPair('postSyncCommand', Profile.PostSyncCommand);
  Result.AddPair('remotePath', Profile.RemotePath);
  Result.AddPair('localPath', Profile.LocalPath);
  Result.AddPair('workingDirectory', Profile.WorkingDirectory);
  Result.AddPair('deleteEnabled', TJSONBool.Create(Profile.DeleteEnabled));
  Result.AddPair('dryRunByDefault', TJSONBool.Create(Profile.DryRunByDefault));
  ExcludesArray := TJSONArray.Create;
  for ExcludeValue in Profile.Excludes do
    ExcludesArray.Add(ExcludeValue);
  Result.AddPair('excludes', ExcludesArray);
end;

function TSyncProfilesForm.TryReadSyncProfilesFromJson(const FileName: string;
  out Profiles: TArray<TSyncProfile>; out ErrorMessage: string): Boolean;
var
  JsonValue: TJSONValue;
  JsonObject: TJSONObject;
  JsonArray: TJSONArray;
  ItemObject: TJSONObject;
  I: Integer;
  J: Integer;
  Profile: TSyncProfile;
  ProfileList: TList<TSyncProfile>;
  ExcludesArray: TJSONArray;
begin
  Result := False;
  ErrorMessage := '';
  SetLength(Profiles, 0);
  if not FileExists(FileName) then
  begin
    ErrorMessage := 'Import file not found: ' + FileName;
    Exit;
  end;

  JsonValue := TJSONObject.ParseJSONValue(TFile.ReadAllText(FileName, TEncoding.UTF8));
  try
    if JsonValue is TJSONArray then
      JsonArray := TJSONArray(JsonValue)
    else if JsonValue is TJSONObject then
    begin
      JsonObject := TJSONObject(JsonValue);
      JsonArray := JsonObject.GetValue<TJSONArray>('syncProfiles');
    end
    else
      JsonArray := nil;

    if not Assigned(JsonArray) then
    begin
      ErrorMessage := 'Import file must contain a syncProfiles array.';
      Exit;
    end;

    ProfileList := TList<TSyncProfile>.Create;
    try
      for I := 0 to JsonArray.Count - 1 do
      begin
        if not (JsonArray.Items[I] is TJSONObject) then
          Continue;
        ItemObject := TJSONObject(JsonArray.Items[I]);
        Profile := Default(TSyncProfile);
        Profile.Name := ItemObject.GetValue<string>('name', '');
        Profile.ConnectionProfileName := ItemObject.GetValue<string>('connectionProfileName',
          ItemObject.GetValue<string>('connectionProfile', ''));
        Profile.Protocol := LowerCase(Trim(ItemObject.GetValue<string>('protocol',
          ItemObject.GetValue<string>('backend', 'sftp'))));
        if not ((Profile.Protocol = 'ftp') or (Profile.Protocol = 'ftps') or (Profile.Protocol = 'sftp')) then
          Profile.Protocol := 'sftp';
        Profile.Direction := LowerCase(Trim(ItemObject.GetValue<string>('direction', 'upload')));
        Profile.Host := ItemObject.GetValue<string>('host', '');
        Profile.Port := ItemObject.GetValue<Integer>('port', 0);
        if Profile.Port <= 0 then
        begin
          if SameText(Profile.Protocol, 'sftp') then
            Profile.Port := 22
          else
            Profile.Port := 21;
        end;
        Profile.Username := ItemObject.GetValue<string>('username', '');
        Profile.PrivateKeyFile := ItemObject.GetValue<string>('privateKeyFile', '');
        Profile.PassiveMode := ItemObject.GetValue<Boolean>('passiveMode', True);
        Profile.IgnoreCertErrors := ItemObject.GetValue<Boolean>('ignoreCertErrors', False);
        Profile.DefaultTestVHost := ItemObject.GetValue<string>('defaultTestVHost', '');
        Profile.PreSyncCommand := ItemObject.GetValue<string>('preSyncCommand', '');
        Profile.PostSyncCommand := ItemObject.GetValue<string>('postSyncCommand', '');
        Profile.RemotePath := ItemObject.GetValue<string>('remotePath', '');
        Profile.LocalPath := ItemObject.GetValue<string>('localPath', '');
        Profile.WorkingDirectory := ItemObject.GetValue<string>('workingDirectory', '');
        Profile.DeleteEnabled := ItemObject.GetValue<Boolean>('deleteEnabled', False);
        Profile.DryRunByDefault := ItemObject.GetValue<Boolean>('dryRunByDefault', True);
        SetLength(Profile.Excludes, 0);
        ExcludesArray := ItemObject.GetValue<TJSONArray>('excludes');
        if Assigned(ExcludesArray) then
        begin
          SetLength(Profile.Excludes, ExcludesArray.Count);
          for J := 0 to ExcludesArray.Count - 1 do
            Profile.Excludes[J] := ExcludesArray.Items[J].Value;
        end;
        ProfileList.Add(Profile);
      end;
      Profiles := ProfileList.ToArray;
    finally
      ProfileList.Free;
    end;
  finally
    JsonValue.Free;
  end;
  Result := True;
end;

procedure TSyncProfilesForm.SetStatus(const ColorValue: TColor; const TextValue: string);
begin
  if not Assigned(FValidationLabel) then
    Exit;
  FValidationLabel.Font.Color := ColorValue;
  FValidationLabel.Caption := TextValue;
end;

procedure TSyncProfilesForm.UpdateProtocolState;
var
  Protocol: string;
begin
  if not Assigned(FProtocolCombo) then
    Exit;
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

procedure TSyncProfilesForm.UpdateValidationMessage;
var
  Profile: TSyncProfile;
  Credentials: TSyncCredentials;
  ErrorMessage: string;
begin
  if FLoading then
    Exit;
  if CurrentProfileIndex < 0 then
  begin
    SetStatus(clGrayText, 'Select or create a sync profile.');
    Exit;
  end;
  if not ReadProfileFromEditor(Profile, ErrorMessage) then
  begin
    SetStatus(clRed, ErrorMessage);
    Exit;
  end;
  Credentials := BuildCredentialsFromEditor(Profile);
  if SameText(Credentials.Protocol, 'sftp') and (Trim(Credentials.Password) <> '') then
  begin
    SetStatus(clRed, 'SFTP password auth is not supported in this build. Store an SSH key in the connection profile instead.');
    Exit;
  end;
  if SameText(Credentials.Protocol, 'sftp') and (Trim(Credentials.KeyPassphrase) <> '') then
  begin
    SetStatus(clRed, 'SFTP key passphrases are not supported in this build. Load the key into ssh-agent first.');
    Exit;
  end;
  SetStatus(TColor($002E7D32), 'Profile is valid. Preview and tests use the selected test vHost when one is chosen.');
end;

procedure TSyncProfilesForm.ClearEditor;
begin
  LoadProfileIntoEditor(DefaultProfile);
  FLoadedProfileName := '';
  FCurrentProfileIndex := -1;
  if Assigned(FProfilesList) then
    FProfilesList.ItemIndex := -1;
  UpdateValidationMessage;
end;

procedure TSyncProfilesForm.LoadProfileIntoEditor(const Profile: TSyncProfile);
var
  ExcludeValue: string;
  Effective: TSyncProfile;
begin
  Effective := Profile;
  if Trim(Effective.Protocol) = '' then
    Effective.Protocol := 'sftp';
  if not ((Effective.Protocol = 'ftp') or (Effective.Protocol = 'ftps') or (Effective.Protocol = 'sftp')) then
    Effective.Protocol := 'sftp';
  if Trim(Effective.Direction) = '' then
    Effective.Direction := 'upload';
  if not ((Effective.Direction = 'upload') or (Effective.Direction = 'download')) then
    Effective.Direction := 'upload';
  if Effective.Port <= 0 then
  begin
    if SameText(Effective.Protocol, 'sftp') then
      Effective.Port := 22
    else
      Effective.Port := 21;
  end;

  FLoading := True;
  try
    FNameEdit.Text := Effective.Name;
    if Assigned(FConnectionProfileCombo) and (FConnectionProfileCombo.Items.Count > 0) then
    begin
      if Trim(Effective.ConnectionProfileName) <> '' then
        FConnectionProfileCombo.ItemIndex := FConnectionProfileCombo.Items.IndexOf(Effective.ConnectionProfileName)
      else if (Trim(Effective.Name) <> '') and (FConnectionProfileCombo.Items.IndexOf(Effective.Name) > 0) then
        FConnectionProfileCombo.ItemIndex := FConnectionProfileCombo.Items.IndexOf(Effective.Name)
      else
        FConnectionProfileCombo.ItemIndex := 0;
      if FConnectionProfileCombo.ItemIndex < 0 then
        FConnectionProfileCombo.ItemIndex := 0;
    end;
    FProtocolCombo.ItemIndex := FProtocolCombo.Items.IndexOf(Effective.Protocol);
    if FProtocolCombo.ItemIndex < 0 then
      FProtocolCombo.ItemIndex := 2;
    FDirectionCombo.ItemIndex := FDirectionCombo.Items.IndexOf(Effective.Direction);
    if FDirectionCombo.ItemIndex < 0 then
      FDirectionCombo.ItemIndex := 0;
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
    if Assigned(FVHostCombo) and (FVHostCombo.Items.Count > 0) then
    begin
      if Trim(Effective.DefaultTestVHost) <> '' then
        FVHostCombo.ItemIndex := FVHostCombo.Items.IndexOf(Effective.DefaultTestVHost)
      else
        FVHostCombo.ItemIndex := 0;
      if FVHostCombo.ItemIndex < 0 then
        FVHostCombo.ItemIndex := 0;
    end;
    FRemotePathEdit.Text := Effective.RemotePath;
    FLocalPathEdit.Text := Effective.LocalPath;
    FWorkingDirEdit.Text := Effective.WorkingDirectory;
    FPreCommandEdit.Text := Effective.PreSyncCommand;
    FPostCommandEdit.Text := Effective.PostSyncCommand;
    FDeleteCheck.Checked := Effective.DeleteEnabled;
    FDryRunCheck.Checked := Effective.DryRunByDefault;
    FExcludesMemo.Lines.BeginUpdate;
    try
      FExcludesMemo.Clear;
      for ExcludeValue in Effective.Excludes do
        FExcludesMemo.Lines.Add(ExcludeValue);
    finally
      FExcludesMemo.Lines.EndUpdate;
    end;
  finally
    FLoading := False;
  end;
  FLoadedProfileName := Effective.Name;
  UpdateProtocolState;
  UpdateValidationMessage;
end;

function TSyncProfilesForm.SaveCurrentEditor: Boolean;
var
  Index: Integer;
  Profile: TSyncProfile;
  ErrorMessage: string;
begin
  Result := True;
  if FLoading then
    Exit;
  Index := CurrentProfileIndex;
  if Index < 0 then
    Exit;
  if not ReadProfileFromEditor(Profile, ErrorMessage) then
  begin
    Result := False;
    MessageDlg(ErrorMessage, mtError, [mbOK], 0);
    Exit;
  end;
  FProfiles[Index] := Profile;
  RefreshProfileList;
  FProfilesList.ItemIndex := Index;
  FCurrentProfileIndex := Index;
  UpdateValidationMessage;
end;

procedure TSyncProfilesForm.PersistCurrentSecrets(const Profile: TSyncProfile; const PreviousName: string;
  out ErrorMessage: string);
begin
  ErrorMessage := '';
  if not SaveSecret(FPaths, SyncPasswordKey(Profile.Name), Trim(FPasswordEdit.Text), ErrorMessage) then
    Exit;
  if not SaveSecret(FPaths, SyncKeyPassphraseKey(Profile.Name), Trim(FKeyPassphraseEdit.Text), ErrorMessage) then
    Exit;
  if (Trim(PreviousName) <> '') and (not SameText(Trim(PreviousName), Trim(Profile.Name))) then
    DeleteAllSyncSecrets(FPaths, PreviousName);
end;

procedure TSyncProfilesForm.ProfileSelectionChanged(Sender: TObject);
var
  Index: Integer;
begin
  if FLoading then
    Exit;
  if not SaveCurrentEditor then
  begin
    if (FCurrentProfileIndex >= 0) and Assigned(FProfilesList) then
      FProfilesList.ItemIndex := FCurrentProfileIndex;
    Exit;
  end;
  Index := CurrentProfileIndex;
  if (Index < 0) or (Index >= FProfiles.Count) then
    Exit;
  FCurrentProfileIndex := Index;
  LoadProfileIntoEditor(FProfiles[Index]);
end;

procedure TSyncProfilesForm.EditorChanged(Sender: TObject);
begin
  if FLoading then
    Exit;
  UpdateValidationMessage;
end;

procedure TSyncProfilesForm.ProtocolChanged(Sender: TObject);
begin
  if FLoading then
    Exit;
  UpdateProtocolState;
  UpdateValidationMessage;
end;

procedure TSyncProfilesForm.AddProfileClicked(Sender: TObject);
var
  Profile: TSyncProfile;
  BaseName: string;
  Counter: Integer;
  Existing: Boolean;
  ExistingProfile: TSyncProfile;
begin
  if not SaveCurrentEditor then
    Exit;

  BaseName := 'sync-profile';
  Counter := 1;
  repeat
    Profile := DefaultProfile;
    Profile.Name := BaseName + '-' + Counter.ToString;
    Existing := False;
    for ExistingProfile in FProfiles do
      if SameText(ExistingProfile.Name, Profile.Name) then
      begin
        Existing := True;
        Break;
      end;
    if not Existing then
      Break;
    Inc(Counter);
  until False;

  FProfiles.Add(Profile);
  RefreshProfileList;
  FProfilesList.ItemIndex := FProfiles.Count - 1;
  FCurrentProfileIndex := FProfiles.Count - 1;
  LoadProfileIntoEditor(Profile);
  FNameEdit.SetFocus;
  FNameEdit.SelectAll;
end;

procedure TSyncProfilesForm.DeleteProfileClicked(Sender: TObject);
var
  Index: Integer;
  ProfileName: string;
begin
  Index := CurrentProfileIndex;
  if Index < 0 then
    Exit;
  if MessageDlg('Delete the selected sync profile?', mtConfirmation, [mbYes, mbNo], 0) <> mrYes then
    Exit;

  ProfileName := FProfiles[Index].Name;
  DeleteAllSyncSecrets(FPaths, ProfileName);
  FProfiles.Delete(Index);
  RefreshProfileList;
  if FProfiles.Count > 0 then
  begin
    if Index >= FProfiles.Count then
      Index := FProfiles.Count - 1;
    FProfilesList.ItemIndex := Index;
    FCurrentProfileIndex := Index;
    LoadProfileIntoEditor(FProfiles[Index]);
  end
  else
  begin
    ClearEditor;
    FCurrentProfileIndex := -1;
  end;
  UpdateValidationMessage;
end;

procedure TSyncProfilesForm.ImportProfilesClicked(Sender: TObject);
var
  Dialog: TOpenDialog;
  ImportedProfiles: TArray<TSyncProfile>;
  ErrorMessage: string;
begin
  if not SaveCurrentEditor then
    Exit;
  Dialog := TOpenDialog.Create(Self);
  try
    Dialog.Filter := 'JSON files (*.json)|*.json|All files (*.*)|*.*';
    Dialog.Title := 'Import sync profiles';
    Dialog.Options := [ofFileMustExist, ofPathMustExist, ofEnableSizing, ofHideReadOnly];
    if not Dialog.Execute then
      Exit;
    if not TryReadSyncProfilesFromJson(Dialog.FileName, ImportedProfiles, ErrorMessage) then
    begin
      MessageDlg(ErrorMessage, mtError, [mbOK], 0);
      Exit;
    end;
    FProfiles.Clear;
    FProfiles.AddRange(ImportedProfiles);
    RefreshProfileList;
    if Assigned(FProfilesList) and (FProfilesList.Items.Count > 0) then
    begin
      FProfilesList.ItemIndex := 0;
      FCurrentProfileIndex := 0;
      LoadProfileIntoEditor(FProfiles[0]);
    end
    else
      ClearEditor;
  finally
    Dialog.Free;
  end;
end;

procedure TSyncProfilesForm.ExportProfilesClicked(Sender: TObject);
var
  Dialog: TSaveDialog;
  Root: TJSONObject;
  JsonArray: TJSONArray;
  Profile: TSyncProfile;
begin
  if not SaveCurrentEditor then
    Exit;
  Dialog := TSaveDialog.Create(Self);
  try
    Dialog.Filter := 'JSON files (*.json)|*.json|All files (*.*)|*.*';
    Dialog.Title := 'Export sync profiles';
    Dialog.DefaultExt := 'json';
    Dialog.FileName := 'sync-profiles.json';
    Dialog.Options := [ofOverwritePrompt, ofPathMustExist, ofEnableSizing];
    if not Dialog.Execute then
      Exit;

    Root := TJSONObject.Create;
    try
      Root.AddPair('format', 'uniwamp-sync-profiles');
      Root.AddPair('version', TJSONNumber.Create(1));
      JsonArray := TJSONArray.Create;
      for Profile in FProfiles do
        JsonArray.AddElement(SyncProfileToJson(Profile));
      Root.AddPair('syncProfiles', JsonArray);
      TFile.WriteAllText(Dialog.FileName, Root.Format(2), TEncoding.UTF8);
    finally
      Root.Free;
    end;
  finally
    Dialog.Free;
  end;
end;

procedure TSyncProfilesForm.TestProfileClicked(Sender: TObject);
var
  Profile: TSyncProfile;
  ResolvedProfile: TSyncProfile;
  Credentials: TSyncCredentials;
  Transport: ISyncTransport;
  ErrorMessage: string;
  Output: string;
  ResultOk: Boolean;
  TestPath: string;
begin
  if not ReadProfileFromEditor(Profile, ErrorMessage) then
  begin
    UpdateValidationMessage;
    MessageDlg(ErrorMessage, mtError, [mbOK], 0);
    Exit;
  end;

  ResolvedProfile := BuildResolvedProfile(Profile);
  Credentials := BuildCredentialsFromEditor(Profile);
  TestPath := '/';

  Screen.Cursor := crHourGlass;
  try
    try
      Transport := CreateSyncTransport(Credentials);
      try
        Transport.Connect;
        ResultOk := Transport.RemoteDirectoryExists(TestPath);
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
        Output := 'Sync failed: ' + E.Message;
        SetStatus(clRed, Output);
        MessageDlg(Output, mtError, [mbOK], 0);
        Exit;
      end;
    end;
  finally
    Screen.Cursor := crDefault;
  end;

  if ResultOk then
  begin
    SetStatus(TColor($002E7D32), 'Connection test succeeded for ' + ResolvedProfile.Host + '.');
    MessageDlg('Connection test succeeded for ' + ResolvedProfile.Host + '.', mtInformation, [mbOK], 0);
  end
  else
  begin
    Output := 'Connection test failed.';
    SetStatus(clRed, Output);
    MessageDlg(Output, mtError, [mbOK], 0);
  end;
end;

procedure TSyncProfilesForm.TestTargetPathClicked(Sender: TObject);
var
  Profile: TSyncProfile;
  ResolvedProfile: TSyncProfile;
  Credentials: TSyncCredentials;
  Transport: ISyncTransport;
  LocalPath: string;
  WorkingDirectory: string;
  RemotePath: string;
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

  if not ResolveExecutionPaths(Profile, LocalPath, WorkingDirectory, RemotePath, ErrorMessage) then
  begin
    SetStatus(clRed, ErrorMessage);
    MessageDlg(ErrorMessage, mtError, [mbOK], 0);
    Exit;
  end;

  ResolvedProfile := BuildResolvedProfile(Profile);
  Credentials := BuildCredentialsFromEditor(Profile);

  Screen.Cursor := crHourGlass;
  try
    try
      Transport := CreateSyncTransport(Credentials);
      try
        Transport.Connect;
        ResultOk := Transport.RemoteDirectoryExists(RemotePath);
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
        Output := 'Sync failed: ' + E.Message;
        SetStatus(clRed, Output);
        MessageDlg(Output, mtError, [mbOK], 0);
        Exit;
      end;
    end;
  finally
    Screen.Cursor := crDefault;
  end;

  if ResultOk then
  begin
    SetStatus(TColor($002E7D32), 'Target path test succeeded for "' + RemotePath + '".');
    MessageDlg('Target path test succeeded for "' + RemotePath + '".', mtInformation, [mbOK], 0);
  end
  else
  begin
    Output := 'Target path test failed.';
    SetStatus(clRed, Output);
    MessageDlg(Output, mtError, [mbOK], 0);
  end;
end;

procedure TSyncProfilesForm.PreviewProfileClicked(Sender: TObject);
var
  Profile: TSyncProfile;
  Credentials: TSyncCredentials;
  Transport: ISyncTransport;
  LocalPath: string;
  WorkingDirectory: string;
  RemotePath: string;
  ErrorMessage: string;
  Plan: TSyncPlan;
  CommandText: string;
begin
  if not ReadProfileFromEditor(Profile, ErrorMessage) then
  begin
    UpdateValidationMessage;
    MessageDlg(ErrorMessage, mtError, [mbOK], 0);
    Exit;
  end;

  if not ResolveExecutionPaths(Profile, LocalPath, WorkingDirectory, RemotePath, ErrorMessage) then
  begin
    SetStatus(clRed, ErrorMessage);
    MessageDlg(ErrorMessage, mtError, [mbOK], 0);
    Exit;
  end;

  Credentials := BuildCredentialsFromEditor(Profile);
  Screen.Cursor := crHourGlass;
  try
    try
      Transport := CreateSyncTransport(Credentials);
      try
        Transport.Connect;
        Plan := TSyncEngine.BuildPlan(Transport, LocalPath, RemotePath, Profile.Direction,
          Profile.Excludes, Profile.DeleteEnabled);
        CommandText := DescribePlan(Plan);
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
        CommandText := 'Sync failed: ' + E.Message;
        SetStatus(clRed, CommandText);
        MessageDlg(CommandText, mtError, [mbOK], 0);
        Exit;
      end;
    end;
  finally
    Screen.Cursor := crDefault;
  end;

  SetStatus(clGrayText, 'Preview generated for "' + ProfileDisplayName(Profile) + '".');
  MessageDlg(CommandText, mtInformation, [mbOK], 0);
end;

procedure TSyncProfilesForm.BrowsePrivateKeyClicked(Sender: TObject);
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

procedure TSyncProfilesForm.SaveClicked(Sender: TObject);
var
  Profile: TSyncProfile;
  ErrorMessage: string;
  SecretError: string;
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

  PersistCurrentSecrets(Profile, FLoadedProfileName, SecretError);
  if SecretError <> '' then
  begin
    MessageDlg(SecretError, mtError, [mbOK], 0);
    Exit;
  end;

  FConfig.ReplaceSyncProfiles(FProfiles.ToArray);
  FConfig.Save(FPaths);

  ModalResult := mrOk;
end;

procedure TSyncProfilesForm.CancelClicked(Sender: TObject);
begin
  ModalResult := mrCancel;
end;

procedure TSyncProfilesForm.LoadSettings;
begin
  if not Assigned(FConfig) then
    Exit;
  PopulateConnectionProfileList;
  LoadProfilesFromConfig;
  PopulateVHostList;
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

class function TSyncProfilesForm.Execute(const AOwner: TComponent; const Paths: TAppPaths;
  Config: TUniWampConfig; Runtime: TUniWampRuntime): Boolean;
var
  Form: TSyncProfilesForm;
begin
  Form := TSyncProfilesForm.Create(AOwner);
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

end.
