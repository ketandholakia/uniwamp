unit Ui.UniWamp.AppSettingsForm;

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
  Vcl.Themes,
  Core.UniWamp.Types,
  Core.UniWamp.Security,
  Core.UniWamp.Config,
  Core.UniWamp.Paths,
  Core.UniWamp.Runtime,
  Core.UniWamp.ProcessManager;

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
    FSyncPage: TTabSheet;
    FSyncListBox: TListBox;
    FSyncNameEdit: TEdit;
    FSyncBackendCombo: TComboBox;
    FSyncDirectionCombo: TComboBox;
    FSyncExecutableEdit: TEdit;
    FSyncRemoteNameEdit: TEdit;
    FSyncRemotePathEdit: TEdit;
    FSyncLocalPathEdit: TEdit;
    FSyncWorkingDirEdit: TEdit;
    FSyncPreCommandEdit: TEdit;
    FSyncPostCommandEdit: TEdit;
    FSyncVHostCombo: TComboBox;
    FSyncDeleteCheck: TCheckBox;
    FSyncDryRunCheck: TCheckBox;
    FSyncExcludesMemo: TMemo;
    FSyncTestButton: TButton;
    FSyncPreviewButton: TButton;
    FSyncTestPathButton: TButton;
    FSyncValidationLabel: TLabel;
    FSyncProfiles: TList<TSyncProfile>;
    FSyncLoading: Boolean;
  protected
    procedure Loaded; override;
  private
    procedure BuildSyncTab;
    procedure LoadSyncProfiles;
    procedure RefreshSyncProfileList;
    procedure SyncProfileSelectionChanged(Sender: TObject);
    procedure SyncEditorChanged(Sender: TObject);
    procedure AddSyncProfileClicked(Sender: TObject);
    procedure DeleteSyncProfileClicked(Sender: TObject);
    procedure ImportSyncProfilesClicked(Sender: TObject);
    procedure ExportSyncProfilesClicked(Sender: TObject);
    procedure TestSyncProfileClicked(Sender: TObject);
    procedure PreviewSyncProfileClicked(Sender: TObject);
    procedure TestSyncTargetPathClicked(Sender: TObject);
    procedure SaveCurrentSyncEditor;
    procedure LoadSyncProfileIntoEditor(const Profile: TSyncProfile);
    function CurrentSyncProfileIndex: Integer;
    function ReadSyncProfileFromEditor(out Profile: TSyncProfile; out ErrorMessage: string): Boolean;
    function ValidateSyncProfiles(out ErrorMessage: string): Boolean;
    function SyncProfileDisplayName(const Profile: TSyncProfile): string;
    procedure UpdateSyncValidationMessage;
    function ResolveSyncExecutablePath(const Profile: TSyncProfile; out ExecutablePath: string): Boolean;
    procedure PopulateSyncVHostList;
    function SelectedSyncVHost(out Entry: TVHostEntry): Boolean;
    function BuildResolvedProfile(const Profile: TSyncProfile): TSyncProfile;
    function SyncProfileToJson(const Profile: TSyncProfile): TJSONObject;
    function TryReadSyncProfilesFromJson(const FileName: string; out Profiles: TArray<TSyncProfile>;
      out ErrorMessage: string): Boolean;
    procedure SaveClicked(Sender: TObject);
    procedure CancelClicked(Sender: TObject);
    procedure PopulateComboFromList(Combo: TComboBox; const Values: array of string;
      const SelectedValue: string; const AllowNoneItem: Boolean = False);
    function ValidateSelectedPhpVersion(const Version: string; out ErrorMessage: string): Boolean;
    function ValidateSelectedNodeVersion(const Version: string; out ErrorMessage: string): Boolean;
    procedure PopulateThemeStyles;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
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
  FSyncProfiles := TList<TSyncProfile>.Create;
end;

procedure TAppSettingsForm.BuildSyncTab;
var
  PageControl: TPageControl;
  ListPanel: TPanel;
  EditorPanel: TPanel;
  FooterPanel: TPanel;
  AddButton: TButton;
  DeleteButton: TButton;
  ImportButton: TButton;
  ExportButton: TButton;
  HintLabel: TLabel;
  FieldHintLabel: TLabel;
  LabelTop: Integer;
  function AddLabel(const Parent: TWinControl; const CaptionText: string;
    LeftPos, TopPos: Integer): TLabel;
  begin
    Result := TLabel.Create(Self);
    Result.Parent := Parent;
    Result.Left := LeftPos;
    Result.Top := TopPos;
    Result.Caption := CaptionText;
    Result.Font.Height := -11;
    Result.Font.Style := [fsBold];
  end;
  function AddEdit(const Parent: TWinControl; LeftPos, TopPos, WidthValue: Integer): TEdit;
  begin
    Result := TEdit.Create(Self);
    Result.Parent := Parent;
    Result.Left := LeftPos;
    Result.Top := TopPos;
    Result.Width := WidthValue;
    Result.Height := 23;
  end;
begin
  if Assigned(FSyncPage) then
    Exit;
  PageControl := FindComponent('FPageControl') as TPageControl;
  if not Assigned(PageControl) then
    Exit;

  FSyncPage := TTabSheet.Create(Self);
  FSyncPage.PageControl := PageControl;
  FSyncPage.Caption := 'Sync';

  ListPanel := TPanel.Create(Self);
  ListPanel.Parent := FSyncPage;
  ListPanel.SetBounds(16, 16, 240, 388);
  ListPanel.BevelKind := bkTile;
  ListPanel.BevelOuter := bvNone;
  ListPanel.Color := clWhite;
  ListPanel.ParentBackground := False;

  AddLabel(ListPanel, 'Profiles', 18, 16);
  HintLabel := TLabel.Create(Self);
  HintLabel.Parent := ListPanel;
  HintLabel.SetBounds(18, 38, 198, 44);
  HintLabel.Caption := 'Reusable profiles for upload/download. Tokens: {documentRoot}, {projectRoot}, {serverName}.';
  HintLabel.WordWrap := True;
  HintLabel.Font.Color := clGrayText;

  FSyncListBox := TListBox.Create(Self);
  FSyncListBox.Parent := ListPanel;
  FSyncListBox.SetBounds(18, 92, 198, 188);
  FSyncListBox.OnClick := SyncProfileSelectionChanged;

  FooterPanel := TPanel.Create(Self);
  FooterPanel.Parent := ListPanel;
  FooterPanel.BevelOuter := bvNone;
  FooterPanel.Color := clWhite;
  FooterPanel.ParentBackground := False;
  FooterPanel.SetBounds(18, 292, 198, 70);

  AddButton := TButton.Create(Self);
  AddButton.Parent := FooterPanel;
  AddButton.SetBounds(0, 0, 94, 28);
  AddButton.Caption := 'Add';
  AddButton.OnClick := AddSyncProfileClicked;

  DeleteButton := TButton.Create(Self);
  DeleteButton.Parent := FooterPanel;
  DeleteButton.SetBounds(104, 0, 94, 28);
  DeleteButton.Caption := 'Delete';
  DeleteButton.OnClick := DeleteSyncProfileClicked;

  ImportButton := TButton.Create(Self);
  ImportButton.Parent := FooterPanel;
  ImportButton.SetBounds(0, 36, 94, 28);
  ImportButton.Caption := 'Import';
  ImportButton.OnClick := ImportSyncProfilesClicked;

  ExportButton := TButton.Create(Self);
  ExportButton.Parent := FooterPanel;
  ExportButton.SetBounds(104, 36, 94, 28);
  ExportButton.Caption := 'Export';
  ExportButton.OnClick := ExportSyncProfilesClicked;

  EditorPanel := TPanel.Create(Self);
  EditorPanel.Parent := FSyncPage;
  EditorPanel.SetBounds(272, 16, 560, 560);
  EditorPanel.BevelKind := bkTile;
  EditorPanel.BevelOuter := bvNone;
  EditorPanel.Color := clWhite;
  EditorPanel.ParentBackground := False;

  AddLabel(EditorPanel, 'Profile editor', 18, 16);
  FieldHintLabel := TLabel.Create(Self);
  FieldHintLabel.Parent := EditorPanel;
  FieldHintLabel.SetBounds(18, 34, 520, 28);
  FieldHintLabel.Caption := 'Use `rclone`. Set local paths relative to UniWamp or use tokens. Leave executable path empty to resolve `rclone.exe` automatically.';
  FieldHintLabel.WordWrap := True;
  FieldHintLabel.Font.Color := clGrayText;
  LabelTop := 70;
  AddLabel(EditorPanel, 'Name', 18, LabelTop);
  FSyncNameEdit := AddEdit(EditorPanel, 18, LabelTop + 20, 220);
  FSyncNameEdit.OnChange := SyncEditorChanged;
  AddLabel(EditorPanel, 'Backend', 260, LabelTop);
  FSyncBackendCombo := TComboBox.Create(Self);
  FSyncBackendCombo.Parent := EditorPanel;
  FSyncBackendCombo.SetBounds(260, LabelTop + 20, 120, 23);
  FSyncBackendCombo.Style := csDropDownList;
  FSyncBackendCombo.Items.Add('rclone');
  FSyncBackendCombo.OnChange := SyncEditorChanged;

  AddLabel(EditorPanel, 'Direction', 398, LabelTop);
  FSyncDirectionCombo := TComboBox.Create(Self);
  FSyncDirectionCombo.Parent := EditorPanel;
  FSyncDirectionCombo.SetBounds(398, LabelTop + 20, 120, 23);
  FSyncDirectionCombo.Style := csDropDownList;
  FSyncDirectionCombo.Items.Add('upload');
  FSyncDirectionCombo.Items.Add('download');
  FSyncDirectionCombo.OnChange := SyncEditorChanged;

  LabelTop := 128;
  AddLabel(EditorPanel, 'Executable path', 18, LabelTop);
  FSyncExecutableEdit := AddEdit(EditorPanel, 18, LabelTop + 20, 500);
  FSyncExecutableEdit.OnChange := SyncEditorChanged;
  LabelTop := 186;
  AddLabel(EditorPanel, 'Remote name', 18, LabelTop);
  FSyncRemoteNameEdit := AddEdit(EditorPanel, 18, LabelTop + 20, 160);
  FSyncRemoteNameEdit.OnChange := SyncEditorChanged;
  AddLabel(EditorPanel, 'Remote path', 198, LabelTop);
  FSyncRemotePathEdit := AddEdit(EditorPanel, 198, LabelTop + 20, 320);
  FSyncRemotePathEdit.OnChange := SyncEditorChanged;
  LabelTop := 244;
  AddLabel(EditorPanel, 'Test vHost', 18, LabelTop);
  FSyncVHostCombo := TComboBox.Create(Self);
  FSyncVHostCombo.Parent := EditorPanel;
  FSyncVHostCombo.SetBounds(18, LabelTop + 20, 220, 23);
  FSyncVHostCombo.Style := csDropDownList;
  FSyncVHostCombo.OnChange := SyncEditorChanged;
  AddLabel(EditorPanel, 'Local path', 260, LabelTop);
  FSyncLocalPathEdit := AddEdit(EditorPanel, 260, LabelTop + 20, 258);
  FSyncLocalPathEdit.OnChange := SyncEditorChanged;
  LabelTop := 302;
  AddLabel(EditorPanel, 'Working directory', 18, LabelTop);
  FSyncWorkingDirEdit := AddEdit(EditorPanel, 18, LabelTop + 20, 500);
  FSyncWorkingDirEdit.OnChange := SyncEditorChanged;
  LabelTop := 360;
  AddLabel(EditorPanel, 'Pre-sync command', 18, LabelTop);
  FSyncPreCommandEdit := AddEdit(EditorPanel, 18, LabelTop + 20, 500);
  FSyncPreCommandEdit.OnChange := SyncEditorChanged;
  LabelTop := 418;
  AddLabel(EditorPanel, 'Post-sync command', 18, LabelTop);
  FSyncPostCommandEdit := AddEdit(EditorPanel, 18, LabelTop + 20, 500);
  FSyncPostCommandEdit.OnChange := SyncEditorChanged;

  FSyncDeleteCheck := TCheckBox.Create(Self);
  FSyncDeleteCheck.Parent := EditorPanel;
  FSyncDeleteCheck.SetBounds(18, 476, 220, 19);
  FSyncDeleteCheck.Caption := 'Delete extra files on target';
  FSyncDeleteCheck.OnClick := SyncEditorChanged;

  FSyncDryRunCheck := TCheckBox.Create(Self);
  FSyncDryRunCheck.Parent := EditorPanel;
  FSyncDryRunCheck.SetBounds(260, 476, 180, 19);
  FSyncDryRunCheck.Caption := 'Dry run by default';
  FSyncDryRunCheck.OnClick := SyncEditorChanged;

  AddLabel(EditorPanel, 'Exclude patterns', 18, 498);
  FSyncExcludesMemo := TMemo.Create(Self);
  FSyncExcludesMemo.Parent := EditorPanel;
  FSyncExcludesMemo.ScrollBars := ssVertical;
  FSyncExcludesMemo.WordWrap := False;
  FSyncExcludesMemo.SetBounds(18, 516, 500, 32);
  FSyncExcludesMemo.OnChange := SyncEditorChanged;

  FSyncTestButton := TButton.Create(Self);
  FSyncTestButton.Parent := EditorPanel;
  FSyncTestButton.SetBounds(252, 18, 86, 26);
  FSyncTestButton.Caption := 'Test Remote';
  FSyncTestButton.OnClick := TestSyncProfileClicked;

  FSyncTestPathButton := TButton.Create(Self);
  FSyncTestPathButton.Parent := EditorPanel;
  FSyncTestPathButton.SetBounds(344, 18, 86, 26);
  FSyncTestPathButton.Caption := 'Test Path';
  FSyncTestPathButton.OnClick := TestSyncTargetPathClicked;

  FSyncPreviewButton := TButton.Create(Self);
  FSyncPreviewButton.Parent := EditorPanel;
  FSyncPreviewButton.SetBounds(436, 18, 82, 26);
  FSyncPreviewButton.Caption := 'Preview';
  FSyncPreviewButton.OnClick := PreviewSyncProfileClicked;

  FSyncValidationLabel := TLabel.Create(Self);
  FSyncValidationLabel.Parent := FSyncPage;
  FSyncValidationLabel.SetBounds(18, 580, 814, 34);
  FSyncValidationLabel.AutoSize := False;
  FSyncValidationLabel.WordWrap := True;
  FSyncValidationLabel.Font.Color := clGrayText;
  FSyncValidationLabel.Caption := 'Select or create a sync profile.';
end;

procedure TAppSettingsForm.LoadSyncProfiles;
begin
  FSyncProfiles.Clear;
  FSyncProfiles.AddRange(FConfig.SyncProfiles);
  PopulateSyncVHostList;
  RefreshSyncProfileList;
  if Assigned(FSyncListBox) and (FSyncListBox.Items.Count > 0) then
  begin
    FSyncListBox.ItemIndex := 0;
    SyncProfileSelectionChanged(FSyncListBox);
  end;
end;

procedure TAppSettingsForm.PopulateSyncVHostList;
var
  Entry: TVHostEntry;
begin
  if not Assigned(FSyncVHostCombo) then
    Exit;
  FSyncVHostCombo.Items.BeginUpdate;
  try
    FSyncVHostCombo.Items.Clear;
    FSyncVHostCombo.Items.Add('(application defaults)');
    for Entry in FConfig.VHosts do
      FSyncVHostCombo.Items.Add(Entry.ServerName);
  finally
    FSyncVHostCombo.Items.EndUpdate;
  end;
end;

function TAppSettingsForm.SelectedSyncVHost(out Entry: TVHostEntry): Boolean;
var
  Item: TVHostEntry;
  SelectedName: string;
begin
  Result := False;
  Entry.ServerName := '';
  Entry.ServerAliases := '';
  Entry.DocumentRoot := '';
  Entry.EnableSsl := False;
  Entry.SslCertFile := '';
  Entry.SslKeyFile := '';
  Entry.PinnedSyncUploadProfile := '';
  Entry.PinnedSyncDownloadProfile := '';
  if not Assigned(FSyncVHostCombo) or (FSyncVHostCombo.ItemIndex <= 0) then
    Exit;
  SelectedName := Trim(FSyncVHostCombo.Items[FSyncVHostCombo.ItemIndex]);
  for Item in FConfig.VHosts do
    if SameText(Item.ServerName, SelectedName) then
    begin
      Entry := Item;
      Exit(True);
    end;
end;

procedure TAppSettingsForm.RefreshSyncProfileList;
var
  Profile: TSyncProfile;
begin
  if not Assigned(FSyncListBox) then
    Exit;
  FSyncListBox.Items.BeginUpdate;
  try
    FSyncListBox.Items.Clear;
    for Profile in FSyncProfiles do
      FSyncListBox.Items.Add(SyncProfileDisplayName(Profile));
  finally
    FSyncListBox.Items.EndUpdate;
  end;
end;

function TAppSettingsForm.CurrentSyncProfileIndex: Integer;
begin
  Result := -1;
  if Assigned(FSyncListBox) then
    Result := FSyncListBox.ItemIndex;
end;

procedure TAppSettingsForm.LoadSyncProfileIntoEditor(const Profile: TSyncProfile);
var
  ExcludePattern: string;
begin
  FSyncLoading := True;
  try
    FSyncNameEdit.Text := Profile.Name;
    FSyncBackendCombo.ItemIndex := FSyncBackendCombo.Items.IndexOf(Profile.Backend);
    if FSyncBackendCombo.ItemIndex < 0 then
      FSyncBackendCombo.ItemIndex := 0;
    FSyncDirectionCombo.ItemIndex := FSyncDirectionCombo.Items.IndexOf(Profile.Direction);
    if FSyncDirectionCombo.ItemIndex < 0 then
      FSyncDirectionCombo.ItemIndex := 0;
    FSyncExecutableEdit.Text := Profile.ExecutablePath;
    FSyncRemoteNameEdit.Text := Profile.RemoteName;
    FSyncRemotePathEdit.Text := Profile.RemotePath;
    if Assigned(FSyncVHostCombo) and (FSyncVHostCombo.Items.Count > 0) then
    begin
      if Trim(Profile.DefaultTestVHost) <> '' then
        FSyncVHostCombo.ItemIndex := FSyncVHostCombo.Items.IndexOf(Profile.DefaultTestVHost)
      else
        FSyncVHostCombo.ItemIndex := 0;
      if FSyncVHostCombo.ItemIndex < 0 then
        FSyncVHostCombo.ItemIndex := 0;
    end;
    FSyncLocalPathEdit.Text := Profile.LocalPath;
    FSyncWorkingDirEdit.Text := Profile.WorkingDirectory;
    FSyncPreCommandEdit.Text := Profile.PreSyncCommand;
    FSyncPostCommandEdit.Text := Profile.PostSyncCommand;
    FSyncDeleteCheck.Checked := Profile.DeleteEnabled;
    FSyncDryRunCheck.Checked := Profile.DryRunByDefault;
    FSyncExcludesMemo.Lines.BeginUpdate;
    try
      FSyncExcludesMemo.Clear;
      for ExcludePattern in Profile.Excludes do
        FSyncExcludesMemo.Lines.Add(ExcludePattern);
    finally
      FSyncExcludesMemo.Lines.EndUpdate;
    end;
  finally
    FSyncLoading := False;
  end;
  UpdateSyncValidationMessage;
end;

function TAppSettingsForm.ReadSyncProfileFromEditor(out Profile: TSyncProfile;
  out ErrorMessage: string): Boolean;
var
  I: Integer;
begin
  Result := False;
  ErrorMessage := '';
  Profile.Name := Trim(FSyncNameEdit.Text);
  if Profile.Name = '' then
  begin
    ErrorMessage := 'Sync profile name is required.';
    Exit;
  end;
  if FSyncBackendCombo.ItemIndex >= 0 then
    Profile.Backend := FSyncBackendCombo.Items[FSyncBackendCombo.ItemIndex]
  else
    Profile.Backend := 'rclone';
  if FSyncDirectionCombo.ItemIndex >= 0 then
    Profile.Direction := FSyncDirectionCombo.Items[FSyncDirectionCombo.ItemIndex]
  else
    Profile.Direction := 'upload';
  Profile.ExecutablePath := Trim(FSyncExecutableEdit.Text);
  if Assigned(FSyncVHostCombo) and (FSyncVHostCombo.ItemIndex > 0) then
    Profile.DefaultTestVHost := Trim(FSyncVHostCombo.Items[FSyncVHostCombo.ItemIndex])
  else
    Profile.DefaultTestVHost := '';
  Profile.RemoteName := Trim(FSyncRemoteNameEdit.Text);
  Profile.RemotePath := Trim(FSyncRemotePathEdit.Text);
  Profile.LocalPath := Trim(FSyncLocalPathEdit.Text);
  Profile.WorkingDirectory := Trim(FSyncWorkingDirEdit.Text);
  Profile.PreSyncCommand := Trim(FSyncPreCommandEdit.Text);
  Profile.PostSyncCommand := Trim(FSyncPostCommandEdit.Text);
  Profile.DeleteEnabled := FSyncDeleteCheck.Checked;
  Profile.DryRunByDefault := FSyncDryRunCheck.Checked;
  Profile.Excludes := FSyncExcludesMemo.Lines.ToStringArray;
  if not SameText(Profile.Backend, 'rclone') then
  begin
    ErrorMessage := 'Sync backend must be rclone.';
    Exit;
  end;
  if not SameText(Profile.Direction, 'upload') and not SameText(Profile.Direction, 'download') then
  begin
    ErrorMessage := 'Sync direction must be upload or download.';
    Exit;
  end;
  if Profile.RemoteName = '' then
  begin
    ErrorMessage := 'Sync profile remote name is required.';
    Exit;
  end;
  if Profile.RemotePath = '' then
  begin
    ErrorMessage := 'Sync profile remote path is required.';
    Exit;
  end;
  if Profile.LocalPath = '' then
  begin
    ErrorMessage := 'Sync profile local path is required.';
    Exit;
  end;
  if Pos(':', Profile.RemoteName) > 0 then
  begin
    ErrorMessage := 'Remote name must not contain a colon. Use only the rclone remote name.';
    Exit;
  end;
  if (Pos('{projectRoot}', LowerCase(Profile.LocalPath)) > 0) and
    (Pos('{documentroot}', LowerCase(Profile.LocalPath)) > 0) then
  begin
    ErrorMessage := 'Use either {projectRoot} or {documentRoot} in local path, not both.';
    Exit;
  end;
  for I := Low(Profile.Excludes) to High(Profile.Excludes) do
    Profile.Excludes[I] := Trim(Profile.Excludes[I]);
  Result := True;
end;

function TAppSettingsForm.SyncProfileDisplayName(const Profile: TSyncProfile): string;
begin
  Result := Trim(Profile.Name);
  if Result = '' then
    Result := '(unnamed)';
end;

function TAppSettingsForm.ResolveSyncExecutablePath(const Profile: TSyncProfile;
  out ExecutablePath: string): Boolean;
var
  SearchPathValue: string;
begin
  ExecutablePath := Trim(StringReplace(Profile.ExecutablePath, '/', '\', [rfReplaceAll]));
  if (ExecutablePath <> '') and not TPath.IsPathRooted(ExecutablePath) then
    ExecutablePath := ExpandFileName(TPath.Combine(FPaths.AppRoot, ExecutablePath));
  if (ExecutablePath <> '') and FileExists(ExecutablePath) then
    Exit(True);

  ExecutablePath := TPath.Combine(FPaths.ToolsDir, 'rclone\rclone.exe');
  if FileExists(ExecutablePath) then
    Exit(True);

  ExecutablePath := TPath.Combine(FPaths.BinDir, 'rclone\rclone.exe');
  if FileExists(ExecutablePath) then
    Exit(True);

  SearchPathValue := GetEnvironmentVariable('PATH');
  ExecutablePath := FileSearch('rclone.exe', SearchPathValue);
  Result := ExecutablePath <> '';
end;

function TAppSettingsForm.BuildResolvedProfile(const Profile: TSyncProfile): TSyncProfile;
var
  Entry: TVHostEntry;
  ServerName: string;
  DocumentRoot: string;
  ProjectRoot: string;
begin
  Result := Profile;
  Result.ExecutablePath := Trim(StringReplace(Result.ExecutablePath, '/', '\', [rfReplaceAll]));
  if SelectedSyncVHost(Entry) then
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

  Result.LocalPath := StringReplace(Result.LocalPath, '{documentRoot}', DocumentRoot,
    [rfReplaceAll, rfIgnoreCase]);
  Result.LocalPath := StringReplace(Result.LocalPath, '{projectRoot}', ProjectRoot,
    [rfReplaceAll, rfIgnoreCase]);
  Result.LocalPath := StringReplace(Result.LocalPath, '{serverName}', ServerName,
    [rfReplaceAll, rfIgnoreCase]);
  Result.WorkingDirectory := StringReplace(Result.WorkingDirectory, '{documentRoot}', DocumentRoot,
    [rfReplaceAll, rfIgnoreCase]);
  Result.WorkingDirectory := StringReplace(Result.WorkingDirectory, '{projectRoot}', ProjectRoot,
    [rfReplaceAll, rfIgnoreCase]);
  Result.WorkingDirectory := StringReplace(Result.WorkingDirectory, '{serverName}', ServerName,
    [rfReplaceAll, rfIgnoreCase]);
end;

function TAppSettingsForm.SyncProfileToJson(const Profile: TSyncProfile): TJSONObject;
var
  ExcludesArray: TJSONArray;
  ExcludePattern: string;
begin
  Result := TJSONObject.Create;
  Result.AddPair('name', Profile.Name);
  Result.AddPair('backend', Profile.Backend);
  Result.AddPair('direction', Profile.Direction);
  Result.AddPair('executablePath', Profile.ExecutablePath);
  Result.AddPair('defaultTestVHost', Profile.DefaultTestVHost);
  Result.AddPair('preSyncCommand', Profile.PreSyncCommand);
  Result.AddPair('postSyncCommand', Profile.PostSyncCommand);
  Result.AddPair('remoteName', Profile.RemoteName);
  Result.AddPair('remotePath', Profile.RemotePath);
  Result.AddPair('localPath', Profile.LocalPath);
  Result.AddPair('workingDirectory', Profile.WorkingDirectory);
  Result.AddPair('deleteEnabled', TJSONBool.Create(Profile.DeleteEnabled));
  Result.AddPair('dryRunByDefault', TJSONBool.Create(Profile.DryRunByDefault));
  ExcludesArray := TJSONArray.Create;
  for ExcludePattern in Profile.Excludes do
    ExcludesArray.Add(ExcludePattern);
  Result.AddPair('excludes', ExcludesArray);
end;

function TAppSettingsForm.TryReadSyncProfilesFromJson(const FileName: string;
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
        Profile.Name := ItemObject.GetValue<string>('name', '');
        Profile.Backend := ItemObject.GetValue<string>('backend', 'rclone');
        Profile.Direction := ItemObject.GetValue<string>('direction', 'upload');
        Profile.ExecutablePath := ItemObject.GetValue<string>('executablePath', '');
        Profile.DefaultTestVHost := ItemObject.GetValue<string>('defaultTestVHost', '');
        Profile.PreSyncCommand := ItemObject.GetValue<string>('preSyncCommand', '');
        Profile.PostSyncCommand := ItemObject.GetValue<string>('postSyncCommand', '');
        Profile.RemoteName := ItemObject.GetValue<string>('remoteName', '');
        Profile.RemotePath := ItemObject.GetValue<string>('remotePath', '');
        Profile.LocalPath := ItemObject.GetValue<string>('localPath', '');
        Profile.WorkingDirectory := ItemObject.GetValue<string>('workingDirectory', '');
        Profile.DeleteEnabled := ItemObject.GetValue<Boolean>('deleteEnabled', False);
        Profile.DryRunByDefault := ItemObject.GetValue<Boolean>('dryRunByDefault', True);
        SetLength(Profile.Excludes, 0);
        if Assigned(ItemObject.GetValue<TJSONArray>('excludes')) then
        begin
          SetLength(Profile.Excludes, ItemObject.GetValue<TJSONArray>('excludes').Count);
          for J := 0 to ItemObject.GetValue<TJSONArray>('excludes').Count - 1 do
            Profile.Excludes[J] := ItemObject.GetValue<TJSONArray>('excludes').Items[J].Value;
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

function TAppSettingsForm.ValidateSyncProfiles(out ErrorMessage: string): Boolean;
var
  I: Integer;
  J: Integer;
begin
  Result := False;
  ErrorMessage := '';
  for I := 0 to FSyncProfiles.Count - 1 do
  begin
    for J := I + 1 to FSyncProfiles.Count - 1 do
      if SameText(FSyncProfiles[I].Name, FSyncProfiles[J].Name) then
      begin
        ErrorMessage := 'Sync profile names must be unique. Duplicate: ' +
          SyncProfileDisplayName(FSyncProfiles[I]);
        Exit;
      end;
  end;
  Result := True;
end;

procedure TAppSettingsForm.UpdateSyncValidationMessage;
var
  Profile: TSyncProfile;
  ErrorMessage: string;
begin
  if not Assigned(FSyncValidationLabel) then
    Exit;
  if FSyncLoading then
    Exit;
  if CurrentSyncProfileIndex < 0 then
  begin
    FSyncValidationLabel.Font.Color := clGrayText;
    FSyncValidationLabel.Caption := 'Select or create a sync profile.';
    Exit;
  end;
  if not ReadSyncProfileFromEditor(Profile, ErrorMessage) then
  begin
    FSyncValidationLabel.Font.Color := clRed;
    FSyncValidationLabel.Caption := ErrorMessage;
    Exit;
  end;
  FSyncValidationLabel.Font.Color := TColor($002E7D32);
  FSyncValidationLabel.Caption :=
    'Profile is valid. Preview and tests use the selected test vHost when one is chosen.';
end;

procedure TAppSettingsForm.SaveCurrentSyncEditor;
var
  Index: Integer;
  Profile: TSyncProfile;
  ErrorMessage: string;
begin
  if FSyncLoading then
    Exit;
  Index := CurrentSyncProfileIndex;
  if Index < 0 then
    Exit;
  if not ReadSyncProfileFromEditor(Profile, ErrorMessage) then
  begin
    MessageDlg(ErrorMessage, mtError, [mbOK], 0);
    Exit;
  end;
  FSyncProfiles[Index] := Profile;
  RefreshSyncProfileList;
  FSyncListBox.ItemIndex := Index;
  UpdateSyncValidationMessage;
end;

procedure TAppSettingsForm.SyncProfileSelectionChanged(Sender: TObject);
var
  Index: Integer;
begin
  if FSyncLoading then
    Exit;
  Index := CurrentSyncProfileIndex;
  if (Index < 0) or (Index >= FSyncProfiles.Count) then
  begin
    UpdateSyncValidationMessage;
    Exit;
  end;
  LoadSyncProfileIntoEditor(FSyncProfiles[Index]);
end;

procedure TAppSettingsForm.SyncEditorChanged(Sender: TObject);
begin
  if FSyncLoading then
    Exit;
  UpdateSyncValidationMessage;
end;

procedure TAppSettingsForm.AddSyncProfileClicked(Sender: TObject);
var
  Profile: TSyncProfile;
begin
  SaveCurrentSyncEditor;
  Profile.Name := 'new-profile';
  Profile.Backend := 'rclone';
  Profile.Direction := 'upload';
  Profile.ExecutablePath := '';
  Profile.RemoteName := '';
  Profile.RemotePath := '';
  Profile.LocalPath := '{documentRoot}';
  Profile.WorkingDirectory := '{projectRoot}';
  Profile.DefaultTestVHost := '';
  Profile.PreSyncCommand := '';
  Profile.PostSyncCommand := '';
  Profile.DeleteEnabled := False;
  Profile.DryRunByDefault := True;
  SetLength(Profile.Excludes, 0);
  FSyncProfiles.Add(Profile);
  RefreshSyncProfileList;
  FSyncListBox.ItemIndex := FSyncProfiles.Count - 1;
  LoadSyncProfileIntoEditor(Profile);
  FSyncNameEdit.SetFocus;
  FSyncNameEdit.SelectAll;
end;

procedure TAppSettingsForm.DeleteSyncProfileClicked(Sender: TObject);
var
  Index: Integer;
begin
  Index := CurrentSyncProfileIndex;
  if Index < 0 then
    Exit;
  FSyncProfiles.Delete(Index);
  RefreshSyncProfileList;
  if FSyncProfiles.Count > 0 then
  begin
    if Index >= FSyncProfiles.Count then
      Index := FSyncProfiles.Count - 1;
    FSyncListBox.ItemIndex := Index;
    LoadSyncProfileIntoEditor(FSyncProfiles[Index]);
  end
  else
  begin
    FSyncLoading := True;
    try
    FSyncNameEdit.Clear;
    FSyncExecutableEdit.Clear;
    FSyncRemoteNameEdit.Clear;
    FSyncRemotePathEdit.Clear;
    FSyncLocalPathEdit.Clear;
    FSyncWorkingDirEdit.Clear;
    FSyncPreCommandEdit.Clear;
    FSyncPostCommandEdit.Clear;
    FSyncExcludesMemo.Clear;
    FSyncDeleteCheck.Checked := False;
    FSyncDryRunCheck.Checked := True;
    finally
      FSyncLoading := False;
    end;
  end;
  UpdateSyncValidationMessage;
end;

procedure TAppSettingsForm.ImportSyncProfilesClicked(Sender: TObject);
var
  Dialog: TOpenDialog;
  ImportedProfiles: TArray<TSyncProfile>;
  ErrorMessage: string;
begin
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
    FSyncProfiles.Clear;
    FSyncProfiles.AddRange(ImportedProfiles);
    RefreshSyncProfileList;
    if Assigned(FSyncListBox) and (FSyncListBox.Items.Count > 0) then
    begin
      FSyncListBox.ItemIndex := 0;
      SyncProfileSelectionChanged(FSyncListBox);
    end
    else
      UpdateSyncValidationMessage;
  finally
    Dialog.Free;
  end;
end;

procedure TAppSettingsForm.ExportSyncProfilesClicked(Sender: TObject);
var
  Dialog: TSaveDialog;
  Root: TJSONObject;
  JsonArray: TJSONArray;
  Profile: TSyncProfile;
begin
  SaveCurrentSyncEditor;
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
      for Profile in FSyncProfiles do
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

procedure TAppSettingsForm.TestSyncProfileClicked(Sender: TObject);
var
  Profile: TSyncProfile;
  ResolvedProfile: TSyncProfile;
  ErrorMessage: string;
  ExecutablePath: string;
  Output: string;
  ResultOk: Boolean;
  Arguments: string;
begin
  if not ReadSyncProfileFromEditor(Profile, ErrorMessage) then
  begin
    UpdateSyncValidationMessage;
    MessageDlg(ErrorMessage, mtError, [mbOK], 0);
    Exit;
  end;
  if not ResolveSyncExecutablePath(Profile, ExecutablePath) then
  begin
    ErrorMessage := 'rclone executable not found. Set executable path or install rclone.';
    FSyncValidationLabel.Font.Color := clRed;
    FSyncValidationLabel.Caption := ErrorMessage;
    MessageDlg(ErrorMessage, mtError, [mbOK], 0);
    Exit;
  end;

  ResolvedProfile := BuildResolvedProfile(Profile);
  Arguments := 'lsd "' + ResolvedProfile.RemoteName + ':" --max-depth 1';
  Screen.Cursor := crHourGlass;
  try
    ResultOk := TProcessManager.RunAndCaptureOutput(ExecutablePath, Arguments, FPaths.AppRoot,
      Output, 120000);
  finally
    Screen.Cursor := crDefault;
  end;

  if ResultOk then
  begin
    FSyncValidationLabel.Font.Color := TColor($002E7D32);
    FSyncValidationLabel.Caption := 'Remote test succeeded for "' + ResolvedProfile.RemoteName +
      '". Remote path is not modified.';
    MessageDlg('Remote test succeeded for "' + ResolvedProfile.RemoteName + '".', mtInformation, [mbOK], 0);
  end
  else
  begin
    if Trim(Output) = '' then
      Output := 'Remote test failed.';
    FSyncValidationLabel.Font.Color := clRed;
    FSyncValidationLabel.Caption := Output;
    MessageDlg(Output, mtError, [mbOK], 0);
  end;
end;

procedure TAppSettingsForm.TestSyncTargetPathClicked(Sender: TObject);
var
  Profile: TSyncProfile;
  ResolvedProfile: TSyncProfile;
  ErrorMessage: string;
  ExecutablePath: string;
  Output: string;
  ResultOk: Boolean;
  Arguments: string;
begin
  if not ReadSyncProfileFromEditor(Profile, ErrorMessage) then
  begin
    UpdateSyncValidationMessage;
    MessageDlg(ErrorMessage, mtError, [mbOK], 0);
    Exit;
  end;
  if not ResolveSyncExecutablePath(Profile, ExecutablePath) then
  begin
    ErrorMessage := 'rclone executable not found. Set executable path or install rclone.';
    FSyncValidationLabel.Font.Color := clRed;
    FSyncValidationLabel.Caption := ErrorMessage;
    MessageDlg(ErrorMessage, mtError, [mbOK], 0);
    Exit;
  end;

  ResolvedProfile := BuildResolvedProfile(Profile);
  Arguments := 'lsd "' + ResolvedProfile.RemoteName + ':' + ResolvedProfile.RemotePath +
    '" --max-depth 1';
  Screen.Cursor := crHourGlass;
  try
    ResultOk := TProcessManager.RunAndCaptureOutput(ExecutablePath, Arguments, FPaths.AppRoot,
      Output, 120000);
  finally
    Screen.Cursor := crDefault;
  end;

  if ResultOk then
  begin
    FSyncValidationLabel.Font.Color := TColor($002E7D32);
    FSyncValidationLabel.Caption := 'Target path test succeeded for "' +
      ResolvedProfile.RemoteName + ':' + ResolvedProfile.RemotePath + '".';
    MessageDlg('Target path test succeeded for "' + ResolvedProfile.RemoteName + ':' +
      ResolvedProfile.RemotePath + '".', mtInformation, [mbOK], 0);
  end
  else
  begin
    if Trim(Output) = '' then
      Output := 'Target path test failed.';
    FSyncValidationLabel.Font.Color := clRed;
    FSyncValidationLabel.Caption := Output;
    MessageDlg(Output, mtError, [mbOK], 0);
  end;
end;

procedure TAppSettingsForm.PreviewSyncProfileClicked(Sender: TObject);
var
  Profile: TSyncProfile;
  ResolvedProfile: TSyncProfile;
  ErrorMessage: string;
  CommandText: string;
begin
  if not ReadSyncProfileFromEditor(Profile, ErrorMessage) then
  begin
    UpdateSyncValidationMessage;
    MessageDlg(ErrorMessage, mtError, [mbOK], 0);
    Exit;
  end;

  ResolvedProfile := BuildResolvedProfile(Profile);
  CommandText := 'rclone ';
  if ResolvedProfile.DeleteEnabled then
    CommandText := CommandText + 'sync '
  else
    CommandText := CommandText + 'copy ';

  if SameText(ResolvedProfile.Direction, 'upload') then
    CommandText := CommandText + '"' + ResolvedProfile.LocalPath + '" "' +
      ResolvedProfile.RemoteName + ':' + ResolvedProfile.RemotePath + '"'
  else
    CommandText := CommandText + '"' + ResolvedProfile.RemoteName + ':' +
      ResolvedProfile.RemotePath + '" "' + ResolvedProfile.LocalPath + '"';

  if ResolvedProfile.DryRunByDefault then
    CommandText := CommandText + ' --dry-run';
  if Trim(ResolvedProfile.WorkingDirectory) <> '' then
    CommandText := CommandText + sLineBreak + 'Working directory: ' + ResolvedProfile.WorkingDirectory;
  if Length(ResolvedProfile.Excludes) > 0 then
    CommandText := CommandText + sLineBreak + 'Excludes: ' + String.Join(', ', ResolvedProfile.Excludes);

  FSyncValidationLabel.Font.Color := clGrayText;
  FSyncValidationLabel.Caption := 'Preview generated for "' + SyncProfileDisplayName(Profile) + '".';
  MessageDlg(CommandText, mtInformation, [mbOK], 0);
end;

procedure TAppSettingsForm.Loaded;
begin
  inherited Loaded;
  BuildSyncTab;
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
  LoadSyncProfiles;
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
  SaveCurrentSyncEditor;
  if not ValidateSyncProfiles(ErrorMessage) then
  begin
    MessageDlg(ErrorMessage, mtError, [mbOK], 0);
    Exit;
  end;
  FConfig.ReplaceSyncProfiles(FSyncProfiles.ToArray);
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

destructor TAppSettingsForm.Destroy;
begin
  FSyncProfiles.Free;
  inherited Destroy;
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
