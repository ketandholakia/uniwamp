unit Ui.UniWamp.MainForm;

interface

uses
  Winapi.Windows,
  Winapi.Messages,
  System.Classes,
  System.Generics.Collections,
  System.SysUtils,
  System.Types,
  Vcl.Imaging.pngimage,
  Vcl.Controls,
  Vcl.ExtCtrls,
  Vcl.Forms,
  Vcl.Graphics,
  Vcl.Grids,
  Vcl.ImgList,
  Vcl.Menus,
  Vcl.StdCtrls,
  Vcl.ComCtrls,
  Vcl.Clipbrd,
  Core.UniWamp.Config,
  Core.UniWamp.Paths,
  Core.UniWamp.Runtime;

type
  THeaderStatusCard = record
    Panel: TPanel;
    Dot: TShape;
    Title: TLabel;
    Detail1: TLabel;
    Detail2: TLabel;
  end;

  TServiceMenuSet = record
    StartItem: TMenuItem;
    StopItem: TMenuItem;
    RestartItem: TMenuItem;
  end;

  TMainForm = class(TForm)
    Label18: TPanel;
    Label19: TPanel;
    Panel5: TPanel;
    GroupBox1: TGroupBox;
    ApacheStartButton: TPanel;
    ApacheStopButton: TPanel;
    ApacheRestartButton: TPanel;
    Label7: TPanel;
    HttpPortEdit: TEdit;
    Label8: TPanel;
    HttpsPortEdit: TEdit;
    GroupBox2: TGroupBox;
    MariaStartButton: TPanel;
    MariaStopButton: TPanel;
    MariaRestartButton: TPanel;
    Label9: TPanel;
    DbPortEdit: TEdit;
    Panel3: TPanel;
    Label3: TPanel;
    HostNameEdit: TEdit;
    Label5: TPanel;
    PhpProfileCombo: TComboBox;
    Label10: TPanel;
    DocumentRootEdit: TEdit;
    Panel4: TPanel;
    OpenApacheLogButton: TPanel;
    OpenMariaLogButton: TPanel;
    ClearApacheLogButton: TPanel;
    ClearMariaLogButton: TPanel;
    ClearActivityLogButton: TPanel;
    LaunchSiteButton: TPanel;
    LaunchDashboardButton: TPanel;
    Panel1: TPanel;
    Label4: TPanel;
    PhpVersionCombo: TComboBox;
    LabelNode: TPanel;
    NodeVersionCombo: TComboBox;
    EnableSslCheck: TCheckBox;
    Label20: TPanel;
    StatusBar: TStatusBar;
    SaveConfigButton: TPanel;
    exitbutton: TPanel;
    GenerateSslButton: TPanel;
    LaunchTerminalButton: TPanel;
    startbutton: TPanel;
    stopbutton: TPanel;
  published
    HeaderPanel: TPanel;
    MainPanel: TPanel;
    LeftPanel: TPanel;
    RightPanel: TPanel;
    BottomPanel: TPanel;
    ServerCard: TPanel;
    ActionsCard: TPanel;
    VHostCard: TPanel;
    VHostGrid: TStringGrid;
    AddVHostButton: TPanel;
    DeleteVHostButton: TPanel;
    OpenVHostButton: TPanel;
    OpenVHostFolderButton: TPanel;
    CopyVHostUrlButton: TPanel;
    EditPhpIniButton: TPanel;
    EditHttpdConfButton: TPanel;
    EditMariaDbIniButton: TPanel;
  private
    FPaths: TAppPaths;
    FConfig: TUniWampConfig;
    FRuntime: TUniWampRuntime;
    FMainMenu: TMainMenu;
    FTrayMenu: TPopupMenu;
    FTrayIcon: TTrayIcon;
    FMainApacheMenu: TServiceMenuSet;
    FMainPhpMenu: TMenuItem;
  FMainMariaMenu: TServiceMenuSet;
  FTrayApacheMenu: TServiceMenuSet;
  FTrayMariaMenu: TServiceMenuSet;
    FMainPhpVersionItems: TList<TMenuItem>;
    FMainPhpProfileItems: TList<TMenuItem>;
    FMainWindowToggleItem: TMenuItem;
    FTrayWindowToggleItem: TMenuItem;
    FMainStartAllItem: TMenuItem;
    FMainStopAllItem: TMenuItem;
    FTrayStartAllItem: TMenuItem;
    FTrayStopAllItem: TMenuItem;
    FMainExitItem: TMenuItem;
    FTrayExitItem: TMenuItem;
    FMainAutoStartItem: TMenuItem;
    FTrayAutoStartItem: TMenuItem;
    FStatusRefreshTimer: TTimer;
    FIconDir: string;
    FIconCache: TObjectDictionary<string, TPngImage>;
    FMenuImages: TImageList;
    FMenuIconIndices: TDictionary<string, Integer>;
    FHttpPortOwnerLabel: TLabel;
    FHttpsPortOwnerLabel: TLabel;
    FDbPortOwnerLabel: TLabel;
    FLastHttpPortChecked: Integer;
    FLastHttpsPortChecked: Integer;
    FLastDbPortChecked: Integer;
    FLastActivityLogWriteTime: TDateTime;
    FStatusRefreshBusy: Boolean;
    FActivityCard: TPanel;
    FActivityLabel: TPanel;
    FActivityMemo: TMemo;
    FHeaderLogo: TImage;
    FHeaderCards: array[0..2] of THeaderStatusCard;
    procedure FormCreate(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure BuildMenus;
    function IconFileName(const IconName: string): string;
    function LoadIconGraphic(const IconName: string): TPngImage;
    function LoadTintedIconBitmap(const IconName: string; const IconColor: TColor;
      const IconSize: Integer = 24): TBitmap;
    function GetButtonTextLabel(Button: TPanel): TLabel;
    procedure SetButtonCaption(Button: TPanel; const CaptionText: string);
    procedure UpdateButtonIcons(Button: TPanel; const IconColor: TColor);
    procedure ApplyPanelIcon(Button: TPanel; const IconName: string; const IconSize: Integer = 14);
    procedure ApplyMenuIcon(Item: TMenuItem; const IconName: string);
    procedure DrawIconInRect(Canvas: TCanvas; const IconName: string; const Bounds: TRect;
      const IconSize: Integer);
    procedure CreateHeaderStatusCards;
    procedure LayoutDashboard;
    procedure PhpVersionMenuClick(Sender: TObject);
    procedure PhpProfileMenuClick(Sender: TObject);
    procedure LoadStateIntoUi;
    procedure SaveUiIntoState;
    procedure AppendStatus(const Text: string);
    procedure RefreshStatus;
    procedure UpdateHeaderStateColors;
    procedure UpdateHeaderStatusCards;
    procedure CreateHeaderLogo;
    procedure UpdateServiceButtonState;
    procedure UpdateDashboardLabels;
    procedure UpdatePortConflictLabels;
    procedure UpdateStackActionState;
    procedure UpdateVHostActionState;
    procedure UpdateMenuState;
    function IsAutoStartEnabled: Boolean;
    procedure SetAutoStartEnabled(const Enabled: Boolean);
    procedure StatusRefreshTimer(Sender: TObject);
    procedure AutoStartClick(Sender: TObject);
    procedure CreatePortConflictLabels;
    procedure CreateActivityLogPanel;
    procedure RefreshActivityLogView;
    function TryGetVHostEntry(const ServerName: string; out Entry: TVHostEntry): Boolean;
    procedure ToggleMainWindow;
    function VHostUrl(const ServerName: string): string;
    function SelectedVHostServerName: string;
    procedure DeleteVHostByName(const ServerName: string);
    procedure OpenVHostFolder(const ServerName: string);
    procedure OpenVHostUrl(const ServerName: string);
    procedure VHostGridDrawCell(Sender: TObject; ACol, ARow: Integer; CellRect: TRect; State: TGridDrawState);
    procedure VHostGridMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure ApacheStartClick(Sender: TObject);
    procedure ApacheStopClick(Sender: TObject);
    procedure ApacheRestartClick(Sender: TObject);
    procedure MariaDbStartClick(Sender: TObject);
    procedure MariaDbStopClick(Sender: TObject);
    procedure MariaDbRestartClick(Sender: TObject);
    procedure StartButtonClick(Sender: TObject);
    procedure StopButtonClick(Sender: TObject);
  procedure SaveConfigClick(Sender: TObject);
  procedure LaunchSiteClick(Sender: TObject);
  procedure LaunchDashboardClick(Sender: TObject);
  procedure OpenPhpExtensionsClick(Sender: TObject);
    procedure OpenPhpSettingsClick(Sender: TObject);
    procedure OpenApacheModulesClick(Sender: TObject);
    procedure SetMariaDbRootPasswordClick(Sender: TObject);
    procedure LaunchTerminalClick(Sender: TObject);
    procedure GenerateSslClick(Sender: TObject);
    procedure OpenApacheLogClick(Sender: TObject);
    procedure OpenMariaDbLogClick(Sender: TObject);
    procedure ClearApacheLogClick(Sender: TObject);
    procedure ClearMariaDbLogClick(Sender: TObject);
    procedure ClearActivityLogClick(Sender: TObject);
    procedure OpenActivityClick(Sender: TObject);
    procedure AddVHostClick(Sender: TObject);
    procedure DeleteVHostClick(Sender: TObject);
    procedure OpenVHostClick(Sender: TObject);
    procedure OpenVHostFolderClick(Sender: TObject);
    procedure CopyVHostUrlClick(Sender: TObject);
    procedure RefreshVHostSslClick(Sender: TObject);
    procedure ExitButtonClick(Sender: TObject);
    procedure EditPhpIniClick(Sender: TObject);
    procedure EditHttpdConfClick(Sender: TObject);
    procedure EditMariaDbIniClick(Sender: TObject);
    procedure ClearLogFile(const FileName, DisplayName: string);
    procedure ToggleWindowClick(Sender: TObject);
    procedure TrayIconClick(Sender: TObject);
    procedure TrayMenuPopup(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  end;

var
  MainForm: TMainForm;

implementation

uses
  Winapi.ShellAPI,
  System.IOUtils,
  Vcl.Dialogs,
  System.Win.Registry,
  Core.UniWamp.ProcessManager,
  Ui.UniWamp.ApacheModulesForm,
  Ui.UniWamp.PhpExtensionsForm,
  Ui.UniWamp.PhpSettingsForm,
  Ui.UniWamp.PasswordDialog,
  Ui.UniWamp.StartProgressForm,
  Ui.UniWamp.VHostDialog,
  Ui.UniWamp.ShutdownProgressForm;

{$R *.dfm}

const
  AppBackgroundColor = $00FAF7F4;
  HeaderOnlineColor = $006E760F;
  HeaderOfflineColor = $005F3A1E;
  HeaderTextColor = clWhite;
  HeaderSubTextColor = $00EFE7D4;
  ButtonNeutralColor = $00F7F5F3;
  ButtonMutedTextColor = clGrayText;
  ButtonPositiveColor = $00EBF8E7;
  ButtonNegativeColor = $00E8E8FD;
  ButtonWarningColor = $00CCF2FF;
  ButtonAccentColor = $00FFF2EA;
  ButtonDangerStrongColor = $003E3ED6;
  ButtonSuccessStrongColor = $0043A02E;
  GridHeaderColor = $00F7F2ED;
  GridStripeColor = $00FEFCFA;
  GridSelectionColor = $00FFF3E9;
  PanelIconSize = 13;
  PanelIconLeft = 9;
  MenuIconSize = 14;
  HeaderLogoWidth = 236;
  HeaderLogoHeight = 34;

function IsDarkColor(const AColor: TColor): Boolean; forward;

procedure StylePanelButton(Button: TPanel; const Enabled: Boolean; const ActiveColor: TColor;
  const DisabledColor: TColor; const ActiveTextColor: TColor = clWindowText);
var
  TextLabel: TLabel;
  IconColor: TColor;
begin
  if (Button.Tag <> 0) and TObject(Button.Tag).InheritsFrom(TLabel) then
    TextLabel := TLabel(Button.Tag)
  else
    TextLabel := nil;

  if Enabled then
  begin
    Button.Cursor := crHandPoint;
    Button.Color := ActiveColor;
    Button.Font.Color := ActiveTextColor;
    if Assigned(TextLabel) then
      TextLabel.Font.Color := ActiveTextColor;
    if IsDarkColor(ActiveColor) then
      IconColor := clWhite
    else
      IconColor := $00333333;
  end
  else
  begin
    Button.Cursor := crDefault;
    Button.Color := DisabledColor;
    Button.Font.Color := ButtonMutedTextColor;
    if Assigned(TextLabel) then
      TextLabel.Font.Color := ButtonMutedTextColor;
    if IsDarkColor(DisabledColor) then
      IconColor := clWhite
    else
      IconColor := $00333333;
  end;

  if Assigned(Button.Owner) and (Button.Owner is TMainForm) then
    TMainForm(Button.Owner).UpdateButtonIcons(Button, IconColor);
end;

procedure StyleLinkButton(Button: TPanel; const Enabled: Boolean);
var
  TextLabel: TLabel;
begin
  if (Button.Tag <> 0) and TObject(Button.Tag).InheritsFrom(TLabel) then
    TextLabel := TLabel(Button.Tag)
  else
    TextLabel := nil;

  if Enabled then
  begin
    Button.Cursor := crHandPoint;
    Button.Color := clWhite;
    Button.Font.Color := $B0003A;
    if Assigned(TextLabel) then
      TextLabel.Font.Color := $B0003A;
  end
  else
  begin
    Button.Cursor := crDefault;
    Button.Color := clWhite;
    Button.Font.Color := ButtonMutedTextColor;
    if Assigned(TextLabel) then
      TextLabel.Font.Color := ButtonMutedTextColor;
  end;
end;

function IsDarkColor(const AColor: TColor): Boolean;
var
  RgbColor: TColorRef;
  RedValue: Integer;
  GreenValue: Integer;
  BlueValue: Integer;
begin
  RgbColor := ColorToRGB(AColor);
  RedValue := GetRValue(RgbColor);
  GreenValue := GetGValue(RgbColor);
  BlueValue := GetBValue(RgbColor);
  Result := ((RedValue * 299) + (GreenValue * 587) + (BlueValue * 114)) < (128 * 1000);
end;

procedure TintBitmap(Bitmap: TBitmap; const IconColor: TColor);
var
  Y: Integer;
  X: Integer;
  Line: PRGBQuad;
  RgbColor: TColorRef;
begin
  if Bitmap.PixelFormat <> pf32bit then
    Bitmap.PixelFormat := pf32bit;
  Bitmap.AlphaFormat := afDefined;
  RgbColor := ColorToRGB(IconColor);
  for Y := 0 to Bitmap.Height - 1 do
  begin
    Line := Bitmap.ScanLine[Y];
    for X := 0 to Bitmap.Width - 1 do
    begin
      if Line.rgbReserved <> 0 then
      begin
        Line.rgbBlue := GetBValue(RgbColor);
        Line.rgbGreen := GetGValue(RgbColor);
        Line.rgbRed := GetRValue(RgbColor);
      end;
      Inc(Line);
    end;
  end;
end;

function FindHeaderLogoFile(const RootDir: string): string;
var
  Candidate: string;
begin
  Result := '';
  Candidate := TPath.Combine(TPath.Combine(RootDir, 'src'), 'assets');
  Candidate := TPath.Combine(Candidate, 'uniwampheader.png');
  if FileExists(Candidate) then
    Exit(Candidate);

  Candidate := TPath.Combine(TPath.Combine(RootDir, 'assets'), 'uniwampheader.png');
  if FileExists(Candidate) then
    Exit(Candidate);
end;

function NormalizeMaterialIconName(const IconName: string): string;
begin
  if SameText(IconName, 'restart') then
    Result := 'restart_alt'
  else if SameText(IconName, 'build') then
    Result := 'settings'
  else if SameText(IconName, 'view_quilt') then
    Result := 'settings'
  else if SameText(IconName, 'logout') then
    Result := 'cancel'
  else if SameText(IconName, 'help_outline') then
    Result := 'warning'
  else if SameText(IconName, 'info') then
    Result := 'warning'
  else if SameText(IconName, 'database') then
    Result := 'database'
  else
    Result := IconName;
end;

function TMainForm.IconFileName(const IconName: string): string;
var
  NormalizedName: string;
  Candidate: string;
  Files: TArray<string>;
  FileName: string;
begin
  Result := '';
  if FIconDir = '' then
    Exit;

  NormalizedName := NormalizeMaterialIconName(IconName);
  Candidate := TPath.Combine(FIconDir, NormalizedName + '.png');
  if FileExists(Candidate) then
    Exit(Candidate);

  Candidate := TPath.Combine(FIconDir, NormalizedName + '_24dp_1F1F1F_FILL1_wght500_GRAD0_opsz24.png');
  if FileExists(Candidate) then
    Exit(Candidate);

  Files := TDirectory.GetFiles(FIconDir, NormalizedName + '*.png');
  for FileName in Files do
    if Pos('(1)', ExtractFileName(FileName)) = 0 then
      Exit(FileName);
  if Length(Files) > 0 then
    Result := Files[0];
end;

function TMainForm.LoadIconGraphic(const IconName: string): TPngImage;
var
  FileName: string;
begin
  Result := nil;
  if not Assigned(FIconCache) then
    Exit;

  if FIconCache.TryGetValue(IconName, Result) then
    Exit;

  FileName := IconFileName(IconName);
  if FileName = '' then
    Exit;

  Result := TPngImage.Create;
  Result.LoadFromFile(FileName);
  FIconCache.Add(IconName, Result);
end;

function TMainForm.LoadTintedIconBitmap(const IconName: string; const IconColor: TColor;
  const IconSize: Integer): TBitmap;
var
  Png: TPngImage;
begin
  Result := TBitmap.Create;
  Result.SetSize(IconSize, IconSize);
  Png := LoadIconGraphic(IconName);
  if Assigned(Png) then
    Png.AssignTo(Result);
  Result.PixelFormat := pf32bit;
  TintBitmap(Result, IconColor);
end;

procedure TMainForm.UpdateButtonIcons(Button: TPanel; const IconColor: TColor);
var
  Index: Integer;
  ImageControl: TImage;
  IconBitmap: TBitmap;
begin
  for Index := 0 to Button.ControlCount - 1 do
    if Button.Controls[Index] is TImage then
    begin
      ImageControl := TImage(Button.Controls[Index]);
      if ImageControl.Hint <> '' then
      begin
        IconBitmap := LoadTintedIconBitmap(ImageControl.Hint, IconColor, ImageControl.Width);
        try
          ImageControl.Picture.Bitmap.Assign(IconBitmap);
        finally
          IconBitmap.Free;
        end;
      end;
    end;
end;

function TMainForm.GetButtonTextLabel(Button: TPanel): TLabel;
begin
  if (Button.Tag <> 0) and TObject(Button.Tag).InheritsFrom(TLabel) then
    Result := TLabel(Button.Tag)
  else
    Result := nil;
end;

procedure TMainForm.SetButtonCaption(Button: TPanel; const CaptionText: string);
var
  TextLabel: TLabel;
begin
  TextLabel := GetButtonTextLabel(Button);
  if Assigned(TextLabel) then
    TextLabel.Caption := CaptionText
  else
    Button.Caption := CaptionText;
end;

procedure TMainForm.ApplyPanelIcon(Button: TPanel; const IconName: string; const IconSize: Integer);
var
  IconImage: TImage;
  TextLabel: TLabel;
  Png: TPngImage;
begin
  Png := LoadIconGraphic(IconName);
  if not Assigned(Png) then
    Exit;

  if Button.Tag = 0 then
  begin
    TextLabel := TLabel.Create(Button);
    TextLabel.Parent := Button;
    TextLabel.AutoSize := False;
    TextLabel.Transparent := True;
    TextLabel.Left := IconSize + 10;
    TextLabel.Top := 0;
    TextLabel.Width := Button.Width - TextLabel.Left - 8;
    TextLabel.Height := Button.Height;
    TextLabel.Font.Assign(Button.Font);
    TextLabel.Caption := Button.Caption;
    TextLabel.Alignment := taLeftJustify;
    TextLabel.Layout := tlCenter;
    TextLabel.WordWrap := False;
    TextLabel.Tag := 0;
    Button.Tag := NativeInt(TextLabel);
  end
  else
  begin
    TextLabel := GetButtonTextLabel(Button);
    if Assigned(TextLabel) then
    begin
      TextLabel.Left := IconSize + 14;
      TextLabel.Width := Button.Width - TextLabel.Left - 8;
      TextLabel.Height := Button.Height;
    end;
  end;

  Button.Caption := '';
  IconImage := TImage.Create(Button);
  IconImage.Parent := Button;
  IconImage.SetBounds(PanelIconLeft, (Button.Height - IconSize) div 2, IconSize, IconSize);
  IconImage.Stretch := True;
  IconImage.Proportional := True;
  IconImage.Center := True;
  IconImage.Transparent := True;
  IconImage.Hint := IconName;
  IconImage.ShowHint := False;
  if IsDarkColor(Button.Color) then
    IconImage.Picture.Bitmap.Assign(LoadTintedIconBitmap(IconName, clWhite, IconSize))
  else
    IconImage.Picture.Bitmap.Assign(LoadTintedIconBitmap(IconName, $00333333, IconSize));
  IconImage.SendToBack;
end;

procedure TMainForm.ApplyMenuIcon(Item: TMenuItem; const IconName: string);
begin
  Item.Bitmap.Assign(LoadTintedIconBitmap(IconName, $00333333, MenuIconSize));
  Item.ImageIndex := -1;
end;

procedure TMainForm.DrawIconInRect(Canvas: TCanvas; const IconName: string; const Bounds: TRect;
  const IconSize: Integer);
var
  Png: TPngImage;
  DrawRect: TRect;
  LeftPos: Integer;
  TopPos: Integer;
begin
  Png := LoadIconGraphic(IconName);
  if not Assigned(Png) then
    Exit;

  LeftPos := Bounds.Left + ((Bounds.Width - IconSize) div 2);
  TopPos := Bounds.Top + ((Bounds.Height - IconSize) div 2);
  DrawRect := Rect(LeftPos, TopPos, LeftPos + IconSize, TopPos + IconSize);
  Canvas.StretchDraw(DrawRect, Png);
end;

constructor TMainForm.Create(AOwner: TComponent);
var
  PathsMigrated: Boolean;
begin
  inherited Create(AOwner);
  OnCreate := FormCreate;
  OnShow := FormShow;
  Caption := 'UniWamp';
  Width := 1450;
  Height := 1020;
  Constraints.MinWidth := 1200;
  Constraints.MinHeight := 800;
  Position := poScreenCenter;
  FPaths := TAppPaths.Detect;
  EnsurePortableLayout(FPaths);
  FIconDir := TPath.Combine(TPath.Combine(FPaths.AppRoot, 'src'), 'assets');
  FIconDir := TPath.Combine(FIconDir, 'icons');
  if not TDirectory.Exists(FIconDir) then
  begin
    FIconDir := TPath.Combine(FPaths.AppRoot, 'assets');
    FIconDir := TPath.Combine(FIconDir, 'icons');
  end;
  FIconCache := TObjectDictionary<string, TPngImage>.Create([doOwnsValues]);
  FMenuIconIndices := TDictionary<string, Integer>.Create;
  FConfig := TUniWampConfig.Create;
  FRuntime := TUniWampRuntime.Create(FPaths, FConfig);
  PathsMigrated := FConfig.LoadOrCreate(FPaths);
  FMainPhpVersionItems := TList<TMenuItem>.Create;
  FMainPhpProfileItems := TList<TMenuItem>.Create;
  FLastHttpPortChecked := -1;
  FLastHttpsPortChecked := -1;
  FLastDbPortChecked := -1;
  FLastActivityLogWriteTime := 0;
  FRuntime.SyncPhpVersions;
  FRuntime.SyncNodeVersions;
  if PathsMigrated then
  begin
    FConfig.Save(FPaths);
    FRuntime.GenerateAllConfigs;
  end;
  if FConfig.LastMigrationMessage <> '' then
    AppendStatus(FConfig.LastMigrationMessage);
  FStatusRefreshTimer := TTimer.Create(Self);
  FStatusRefreshTimer.Interval := 4000;
  FStatusRefreshTimer.OnTimer := StatusRefreshTimer;
  FStatusRefreshTimer.Enabled := True;
end;

procedure TMainForm.FormCreate(Sender: TObject);
begin
  DoubleBuffered := True;
  Color := AppBackgroundColor;
  OnResize := FormResize;
  HeaderPanel.DoubleBuffered := True;
  MainPanel.DoubleBuffered := True;
  LeftPanel.DoubleBuffered := True;
  RightPanel.DoubleBuffered := True;
  StatusBar.Color := RGB(248, 250, 252);
  StatusBar.Font.Color := RGB(55, 65, 81);
  HeaderPanel.Color := HeaderOfflineColor;
  Label18.Color := HeaderOfflineColor;
  Label19.Color := HeaderOfflineColor;
  Label18.Visible := False;
  Label19.Width := 460;
  Label19.Left := 18;
  Label19.Top := 28;
  Label19.Alignment := taLeftJustify;
  Label19.Font.Color := HeaderSubTextColor;
  Label19.Caption := 'Portable WAMP dashboard for local development';
  MainPanel.Color := AppBackgroundColor;
  LeftPanel.Color := AppBackgroundColor;
  RightPanel.Color := AppBackgroundColor;
  HeaderPanel.Height := 102;
  CreateHeaderLogo;
  CreateHeaderStatusCards;
  CreatePortConflictLabels;
  CreateActivityLogPanel;
  ApacheStartButton.OnClick := ApacheStartClick;
  ApacheStopButton.OnClick := ApacheStopClick;
  ApacheRestartButton.OnClick := ApacheRestartClick;
  MariaStartButton.OnClick := MariaDbStartClick;
  MariaStopButton.OnClick := MariaDbStopClick;
  MariaRestartButton.OnClick := MariaDbRestartClick;
  startbutton.OnClick := StartButtonClick;
  LaunchTerminalButton.OnClick := LaunchTerminalClick;
  SaveConfigButton.OnClick := SaveConfigClick;
  GenerateSslButton.OnClick := GenerateSslClick;
  OpenApacheLogButton.OnClick := OpenApacheLogClick;
  OpenMariaLogButton.OnClick := OpenMariaDbLogClick;
  ClearApacheLogButton.OnClick := ClearApacheLogClick;
  ClearMariaLogButton.OnClick := ClearMariaDbLogClick;
  ClearActivityLogButton.OnClick := ClearActivityLogClick;
  LaunchSiteButton.OnClick := LaunchSiteClick;
  LaunchDashboardButton.OnClick := LaunchDashboardClick;
  AddVHostButton.OnClick := AddVHostClick;
  DeleteVHostButton.OnClick := DeleteVHostClick;
  OpenVHostButton.OnClick := OpenVHostClick;
  OpenVHostFolderButton.OnClick := OpenVHostFolderClick;
  CopyVHostUrlButton.OnClick := CopyVHostUrlClick;
  exitbutton.OnClick := ExitButtonClick;
  EditPhpIniButton.OnClick := EditPhpIniClick;
  EditHttpdConfButton.OnClick := EditHttpdConfClick;
  EditMariaDbIniButton.OnClick := EditMariaDbIniClick;
  stopbutton.OnClick := StopButtonClick;
  StyleLinkButton(ClearApacheLogButton, True);
  StyleLinkButton(ClearMariaLogButton, True);
  StyleLinkButton(ClearActivityLogButton, True);
  StyleLinkButton(Label20, True);
  exitbutton.Color := $00FFD3D3;
  exitbutton.Font.Color := $00603030;
  ApplyPanelIcon(ApacheStartButton, 'play_arrow');
  ApplyPanelIcon(ApacheStopButton, 'stop');
  ApplyPanelIcon(ApacheRestartButton, 'restart_alt');
  ApplyPanelIcon(MariaStartButton, 'play_arrow');
  ApplyPanelIcon(MariaStopButton, 'stop');
  ApplyPanelIcon(MariaRestartButton, 'restart_alt');
  ApplyPanelIcon(GenerateSslButton, 'lock');
  ApplyPanelIcon(LaunchSiteButton, 'open_in_new');
  ApplyPanelIcon(LaunchDashboardButton, 'language');
  ApplyPanelIcon(LaunchTerminalButton, 'terminal');
  ApplyPanelIcon(SaveConfigButton, 'save');
  ApplyPanelIcon(exitbutton, 'logout');
  ApplyPanelIcon(AddVHostButton, 'add');
  ApplyPanelIcon(OpenVHostButton, 'open_in_new');
  ApplyPanelIcon(OpenVHostFolderButton, 'folder_open');
  ApplyPanelIcon(CopyVHostUrlButton, 'content_copy');
  ApplyPanelIcon(DeleteVHostButton, 'delete');
  ApplyPanelIcon(OpenApacheLogButton, 'terminal');
  ApplyPanelIcon(OpenMariaLogButton, 'database');
  ApplyPanelIcon(ClearApacheLogButton, 'delete_sweep');
  ApplyPanelIcon(ClearMariaLogButton, 'delete_sweep');
  ApplyPanelIcon(ClearActivityLogButton, 'delete_sweep');
  ApplyPanelIcon(EditPhpIniButton, 'code');
  ApplyPanelIcon(EditHttpdConfButton, 'web');
  ApplyPanelIcon(EditMariaDbIniButton, 'database');
  SetButtonCaption(LaunchSiteButton, 'Home');
  SetButtonCaption(LaunchDashboardButton, 'Dashboard');
  SetButtonCaption(LaunchTerminalButton, 'Terminal');
  SetButtonCaption(SaveConfigButton, 'Save Config');
  SetButtonCaption(GenerateSslButton, 'Generate SSL');
  SetButtonCaption(OpenApacheLogButton, 'Apache Log');
  SetButtonCaption(OpenMariaLogButton, 'MariaDB Log');
  SetButtonCaption(ClearApacheLogButton, 'Clear Apache');
  SetButtonCaption(ClearMariaLogButton, 'Clear MariaDB');
  SetButtonCaption(ClearActivityLogButton, 'Clear activity');
  SetButtonCaption(AddVHostButton, 'Add');
  SetButtonCaption(OpenVHostButton, 'Open Selected');
  SetButtonCaption(OpenVHostFolderButton, 'Open Root');
  SetButtonCaption(CopyVHostUrlButton, 'Copy URL');
  SetButtonCaption(DeleteVHostButton, 'Delete Selected');
  SetButtonCaption(EditPhpIniButton, 'php.ini');
  SetButtonCaption(EditHttpdConfButton, 'httpd.conf');
  SetButtonCaption(EditMariaDbIniButton, 'mariadb.ini');
  BuildMenus;
  Menu := FMainMenu;
  if HandleAllocated then
    DrawMenuBar(Handle);
  VHostGrid.DefaultDrawing := False;
  VHostGrid.OnDrawCell := VHostGridDrawCell;
  VHostGrid.OnMouseUp := VHostGridMouseUp;
  VHostGrid.Font.Name := 'Segoe UI';
  VHostGrid.Font.Size := 9;
  VHostGrid.FixedColor := GridHeaderColor;
  VHostGrid.Color := clWhite;
  VHostGrid.ColCount := 4;
  VHostGrid.FixedRows := 1;
  VHostGrid.RowCount := 2;
  VHostGrid.DefaultRowHeight := 30;
  VHostGrid.Cells[0, 0] := 'Site Name';
  VHostGrid.Cells[1, 0] := 'Document Path';
  VHostGrid.Cells[2, 0] := 'URL';
  VHostGrid.Cells[3, 0] := 'Actions';
  VHostGrid.ColWidths[0] := 110;
  VHostGrid.ColWidths[1] := 262;
  VHostGrid.ColWidths[2] := 152;
  VHostGrid.ColWidths[3] := 170;
  LoadStateIntoUi;
  LayoutDashboard;
  RefreshStatus;
  OnCloseQuery := FormCloseQuery;
end;

procedure TMainForm.CreateActivityLogPanel;
begin
  FActivityCard := TPanel.Create(Self);
  FActivityCard.Parent := RightPanel;
  FActivityCard.Left := 6;
  FActivityCard.Top := 435;
  FActivityCard.Width := 743;
  FActivityCard.Height := 76;
  FActivityCard.BevelKind := bkTile;
  FActivityCard.BevelOuter := bvNone;
  FActivityCard.Color := clWhite;
  FActivityCard.ParentBackground := False;
  FActivityCard.Anchors := [akLeft, akTop, akRight];

  FActivityLabel := TPanel.Create(Self);
  FActivityLabel.Parent := FActivityCard;
  FActivityLabel.Left := 10;
  FActivityLabel.Top := 7;
  FActivityLabel.Width := 108;
  FActivityLabel.Height := 15;
  FActivityLabel.BevelOuter := bvNone;
  FActivityLabel.Caption := 'Activity log';
  FActivityLabel.Color := clWhite;
  FActivityLabel.Font.Style := [fsBold];
  FActivityLabel.ParentBackground := False;
  FActivityLabel.ParentFont := False;

  FActivityMemo := TMemo.Create(Self);
  FActivityMemo.Parent := FActivityCard;
  FActivityMemo.Left := 10;
  FActivityMemo.Top := 26;
  FActivityMemo.Width := 721;
  FActivityMemo.Height := 40;
  FActivityMemo.ReadOnly := True;
  FActivityMemo.ScrollBars := ssVertical;
  FActivityMemo.WordWrap := False;
  FActivityMemo.BorderStyle := bsSingle;
  FActivityMemo.Color := $FBFDFF;
  FActivityMemo.Font.Name := 'Consolas';
  FActivityMemo.Font.Size := 9;
  FActivityMemo.TabStop := False;
  FActivityMemo.Anchors := [akLeft, akTop, akRight, akBottom];
end;

procedure TMainForm.CreateHeaderLogo;
var
  LogoFile: string;
begin
  FHeaderLogo := TImage.Create(Self);
  FHeaderLogo.Parent := HeaderPanel;
  FHeaderLogo.Left := 14;
  FHeaderLogo.Top := 8;
  FHeaderLogo.Width := HeaderLogoWidth;
  FHeaderLogo.Height := HeaderLogoHeight;
  FHeaderLogo.Stretch := True;
  FHeaderLogo.Proportional := True;
  FHeaderLogo.Center := False;
  FHeaderLogo.Transparent := True;
  FHeaderLogo.Anchors := [akLeft, akTop];

  LogoFile := FindHeaderLogoFile(FPaths.AppRoot);
  if LogoFile <> '' then
    FHeaderLogo.Picture.LoadFromFile(LogoFile);
end;

procedure TMainForm.CreateHeaderStatusCards;
const
  CardTitles: array[0..2] of string = ('Apache', 'PHP', 'MariaDB');
var
  I: Integer;
begin
  for I := Low(FHeaderCards) to High(FHeaderCards) do
  begin
    FHeaderCards[I].Panel := TPanel.Create(Self);
    FHeaderCards[I].Panel.Parent := HeaderPanel;
    FHeaderCards[I].Panel.BevelOuter := bvNone;
    FHeaderCards[I].Panel.Color := HeaderOfflineColor;
    FHeaderCards[I].Panel.ParentBackground := False;
    FHeaderCards[I].Panel.DoubleBuffered := True;
    FHeaderCards[I].Panel.Anchors := [akTop, akRight];

    FHeaderCards[I].Dot := TShape.Create(Self);
    FHeaderCards[I].Dot.Parent := FHeaderCards[I].Panel;
    FHeaderCards[I].Dot.Shape := stCircle;
    FHeaderCards[I].Dot.Pen.Style := psClear;
    FHeaderCards[I].Dot.Brush.Color := RGB(180, 225, 48);
    FHeaderCards[I].Dot.Left := 15;
    FHeaderCards[I].Dot.Top := 16;
    FHeaderCards[I].Dot.Width := 10;
    FHeaderCards[I].Dot.Height := 10;

    FHeaderCards[I].Title := TLabel.Create(Self);
    FHeaderCards[I].Title.Parent := FHeaderCards[I].Panel;
    FHeaderCards[I].Title.Left := 30;
    FHeaderCards[I].Title.Top := 10;
    FHeaderCards[I].Title.Font.Name := 'Segoe UI';
    FHeaderCards[I].Title.Font.Size := 11;
    FHeaderCards[I].Title.Font.Style := [fsBold];
    FHeaderCards[I].Title.Font.Color := clWhite;
    FHeaderCards[I].Title.Transparent := True;
    FHeaderCards[I].Title.Caption := CardTitles[I];

    FHeaderCards[I].Detail1 := TLabel.Create(Self);
    FHeaderCards[I].Detail1.Parent := FHeaderCards[I].Panel;
    FHeaderCards[I].Detail1.Left := 30;
    FHeaderCards[I].Detail1.Top := 31;
    FHeaderCards[I].Detail1.Font.Name := 'Segoe UI';
    FHeaderCards[I].Detail1.Font.Size := 10;
    FHeaderCards[I].Detail1.Font.Color := HeaderTextColor;
    FHeaderCards[I].Detail1.Transparent := True;

    FHeaderCards[I].Detail2 := TLabel.Create(Self);
    FHeaderCards[I].Detail2.Parent := FHeaderCards[I].Panel;
    FHeaderCards[I].Detail2.Left := 30;
    FHeaderCards[I].Detail2.Top := 49;
    FHeaderCards[I].Detail2.Font.Name := 'Segoe UI';
    FHeaderCards[I].Detail2.Font.Size := 10;
    FHeaderCards[I].Detail2.Font.Color := HeaderTextColor;
    FHeaderCards[I].Detail2.Transparent := True;
  end;
end;

procedure TMainForm.LayoutDashboard;
var
  CardWidth: Integer;
  CardGap: Integer;
  CardTop: Integer;
  RightEdge: Integer;
  GridWidth: Integer;
  AvailableGridColumns: Integer;
begin
  HeaderPanel.Height := 102;
  if Assigned(FHeaderLogo) then
  begin
    FHeaderLogo.Left := 14;
    FHeaderLogo.Top := 8;
    FHeaderLogo.Width := HeaderLogoWidth;
    FHeaderLogo.Height := HeaderLogoHeight;
  end;
  Label19.Left := 20;
  Label19.Top := 50;

  LeftPanel.Width := 355;
  ActionsCard.Left := 10;
  ActionsCard.Top := 11;
  ActionsCard.Width := LeftPanel.Width - 20;
  ActionsCard.Height := LeftPanel.Height - 22;

  GroupBox1.Left := 12;
  GroupBox1.Width := ActionsCard.Width - 24;
  GroupBox2.Left := 12;
  GroupBox2.Width := ActionsCard.Width - 24;
  Panel1.Left := 12;
  Panel1.Width := ActionsCard.Width - 24;
  Panel3.Left := 12;
  Panel3.Width := ActionsCard.Width - 24;
  VHostCard.SetBounds(6, 11, RightPanel.Width - 14, 446);
  Panel4.Visible := False;
  FActivityCard.SetBounds(6, VHostCard.Top + VHostCard.Height + 12, RightPanel.Width - 14, 156);
  Panel5.SetBounds(6, FActivityCard.Top + FActivityCard.Height + 12, RightPanel.Width - 14, 64);
  VHostGrid.Width := VHostCard.Width - 32;
  FActivityMemo.Width := FActivityCard.Width - 22;

  GridWidth := VHostGrid.ClientWidth;
  VHostGrid.ColWidths[0] := 110;
  VHostGrid.ColWidths[2] := 160;
  VHostGrid.ColWidths[3] := 160;
  AvailableGridColumns := GridWidth - VHostGrid.ColWidths[0] - VHostGrid.ColWidths[2] - VHostGrid.ColWidths[3];
  if AvailableGridColumns < 250 then
    AvailableGridColumns := 250;
  VHostGrid.ColWidths[1] := AvailableGridColumns;
  if VHostGrid.ColWidths[1] + VHostGrid.ColWidths[0] + VHostGrid.ColWidths[2] + VHostGrid.ColWidths[3] > GridWidth then
    VHostGrid.ColWidths[1] := GridWidth - VHostGrid.ColWidths[0] - VHostGrid.ColWidths[2] - VHostGrid.ColWidths[3];
  if VHostGrid.ColWidths[1] < 1 then
    VHostGrid.ColWidths[1] := 1;

  startbutton.Left := 12;
  startbutton.Width := 120;
  stopbutton.Left := startbutton.Left + startbutton.Width + 10;
  stopbutton.Width := 120;
  exitbutton.Width := 120;
  exitbutton.Left := Panel5.Width - exitbutton.Width - 12;

  CardWidth := 170;
  CardGap := 18;
  CardTop := 18;
  RightEdge := HeaderPanel.Width - 20;

  FHeaderCards[2].Panel.SetBounds(RightEdge - CardWidth, CardTop, CardWidth, 66);
  FHeaderCards[1].Panel.SetBounds(FHeaderCards[2].Panel.Left - CardGap - CardWidth, CardTop, CardWidth, 66);
  FHeaderCards[0].Panel.SetBounds(FHeaderCards[1].Panel.Left - CardGap - CardWidth, CardTop, CardWidth, 66);
  FHeaderCards[0].Panel.Visible := True;
  FHeaderCards[1].Panel.Visible := True;
  FHeaderCards[2].Panel.Visible := True;
end;

procedure TMainForm.FormResize(Sender: TObject);
begin
  if HandleAllocated then
    LayoutDashboard;
end;

procedure TMainForm.CreatePortConflictLabels;
begin
  FHttpPortOwnerLabel := TLabel.Create(Self);
  FHttpPortOwnerLabel.Parent := GroupBox1;
  FHttpPortOwnerLabel.Left := 11;
  FHttpPortOwnerLabel.Top := 76;
  FHttpPortOwnerLabel.Width := 112;
  FHttpPortOwnerLabel.Height := 11;
  FHttpPortOwnerLabel.AutoSize := False;
  FHttpPortOwnerLabel.Font.Size := 8;
  FHttpPortOwnerLabel.Font.Color := clGrayText;
  FHttpPortOwnerLabel.ShowHint := True;

  FHttpsPortOwnerLabel := TLabel.Create(Self);
  FHttpsPortOwnerLabel.Parent := GroupBox1;
  FHttpsPortOwnerLabel.Left := 141;
  FHttpsPortOwnerLabel.Top := 76;
  FHttpsPortOwnerLabel.Width := 102;
  FHttpsPortOwnerLabel.Height := 11;
  FHttpsPortOwnerLabel.AutoSize := False;
  FHttpsPortOwnerLabel.Font.Size := 8;
  FHttpsPortOwnerLabel.Font.Color := clGrayText;
  FHttpsPortOwnerLabel.ShowHint := True;

  FDbPortOwnerLabel := TLabel.Create(Self);
  FDbPortOwnerLabel.Parent := GroupBox2;
  FDbPortOwnerLabel.Left := 9;
  FDbPortOwnerLabel.Top := 75;
  FDbPortOwnerLabel.Width := 228;
  FDbPortOwnerLabel.Height := 11;
  FDbPortOwnerLabel.AutoSize := False;
  FDbPortOwnerLabel.Font.Size := 8;
  FDbPortOwnerLabel.Font.Color := clGrayText;
  FDbPortOwnerLabel.ShowHint := True;
end;

procedure TMainForm.FormShow(Sender: TObject);
begin
  if Assigned(FMainMenu) then
    Menu := FMainMenu;
  if HandleAllocated then
    DrawMenuBar(Handle);
end;

procedure TMainForm.BuildMenus;
var
  MenuItem: TMenuItem;
  Item: TMenuItem;
  PhpVersionItem: TMenuItem;
  PhpProfileItem: TMenuItem;
  VersionName: string;
  ProfileName: string;
  function AddItem(const Parent: TMenuItem; const Caption: string; Handler: TNotifyEvent = nil): TMenuItem;
  begin
    Result := TMenuItem.Create(Self);
    Result.Caption := Caption;
    Result.OnClick := Handler;
    if Assigned(Parent) then
      Parent.Add(Result);
  end;
begin
  FMainMenu := TMainMenu.Create(Self);
  Menu := FMainMenu;
  FMenuImages := TImageList.Create(Self);
  FMenuImages.Width := MenuIconSize;
  FMenuImages.Height := MenuIconSize;
  FMenuImages.ColorDepth := cd32Bit;
  FMenuImages.Masked := False;
  FMainMenu.Images := FMenuImages;

  MenuItem := AddItem(FMainMenu.Items, '&File');
  ApplyMenuIcon(MenuItem, 'folder');
  Item := AddItem(MenuItem, '&Save Config', SaveConfigClick);
  Item.ShortCut := ShortCut(Ord('S'), [ssCtrl]);
  Item := AddItem(MenuItem, '&Generate SSL', GenerateSslClick);
  Item.ShortCut := ShortCut(Ord('G'), [ssCtrl, ssShift]);
  AddItem(MenuItem, '-');
  FMainAutoStartItem := AddItem(MenuItem, 'Start with &Windows', AutoStartClick);
  FMainAutoStartItem.AutoCheck := True;
  FMainExitItem := AddItem(MenuItem, 'E&xit', ExitButtonClick);

  MenuItem := AddItem(FMainMenu.Items, '&Apache');
  ApplyMenuIcon(MenuItem, 'dns');
  FMainApacheMenu.StartItem := AddItem(MenuItem, 'Apache &Start', ApacheStartClick);
  FMainApacheMenu.StartItem.ShortCut := ShortCut(VK_F5, []);
  FMainApacheMenu.StopItem := AddItem(MenuItem, 'Apache S&top', ApacheStopClick);
  FMainApacheMenu.StopItem.ShortCut := ShortCut(VK_F6, []);
  FMainApacheMenu.RestartItem := AddItem(MenuItem, 'Apache &Restart', ApacheRestartClick);
  FMainApacheMenu.RestartItem.ShortCut := ShortCut(VK_F7, []);
  AddItem(MenuItem, '-');
  Item := AddItem(MenuItem, '&Generate SSL', GenerateSslClick);
  Item.ShortCut := ShortCut(Ord('G'), [ssCtrl, ssShift]);
  Item := AddItem(MenuItem, '&Edit httpd.conf', EditHttpdConfClick);
  Item.ShortCut := ShortCut(Ord('H'), [ssCtrl, ssShift]);
  Item := AddItem(MenuItem, 'Apache &Modules', OpenApacheModulesClick);
  Item.ShortCut := ShortCut(Ord('A'), [ssCtrl, ssShift]);
  Item := AddItem(MenuItem, 'Apache &Log', OpenApacheLogClick);
  Item.ShortCut := ShortCut(Ord('L'), [ssCtrl]);
  Item := AddItem(MenuItem, 'Clear Apache L&og', ClearApacheLogClick);
  Item.ShortCut := ShortCut(Ord('K'), [ssCtrl, ssShift]);
  AddItem(MenuItem, '-');
  FMainStartAllItem := AddItem(MenuItem, 'Start &All', StartButtonClick);
  FMainStartAllItem.ShortCut := ShortCut(VK_F11, []);
  FMainStopAllItem := AddItem(MenuItem, 'S&top All', StopButtonClick);
  FMainStopAllItem.ShortCut := ShortCut(VK_F12, []);

  FMainPhpMenu := AddItem(FMainMenu.Items, '&PHP');
  ApplyMenuIcon(FMainPhpMenu, 'code');
  Item := AddItem(FMainPhpMenu, '&Version');
  FMainPhpVersionItems.Clear;
  for VersionName in FConfig.PhpVersions do
  begin
    PhpVersionItem := AddItem(Item, VersionName, PhpVersionMenuClick);
    PhpVersionItem.RadioItem := True;
    PhpVersionItem.AutoCheck := True;
    PhpVersionItem.GroupIndex := 1;
    PhpVersionItem.Tag := FMainPhpVersionItems.Count;
    FMainPhpVersionItems.Add(PhpVersionItem);
  end;
  Item := AddItem(FMainPhpMenu, '&Profile');
  FMainPhpProfileItems.Clear;
  for ProfileName in ['development', 'production'] do
  begin
    PhpProfileItem := AddItem(Item, ProfileName, PhpProfileMenuClick);
    PhpProfileItem.RadioItem := True;
    PhpProfileItem.AutoCheck := True;
    PhpProfileItem.GroupIndex := 2;
    PhpProfileItem.Tag := FMainPhpProfileItems.Count;
    FMainPhpProfileItems.Add(PhpProfileItem);
  end;
  AddItem(FMainPhpMenu, '-');
  Item := AddItem(FMainPhpMenu, 'Open &php.ini', EditPhpIniClick);
  Item.ShortCut := ShortCut(Ord('P'), [ssCtrl, ssShift]);
  Item := AddItem(FMainPhpMenu, 'Open PHP &Extensions', OpenPhpExtensionsClick);
  Item.ShortCut := ShortCut(Ord('E'), [ssCtrl, ssShift]);
  Item := AddItem(FMainPhpMenu, 'Open PHP &Settings', OpenPhpSettingsClick);
  Item.ShortCut := ShortCut(Ord('Y'), [ssCtrl, ssShift]);
  Item := AddItem(FMainPhpMenu, '&Save Config', SaveConfigClick);
  Item.ShortCut := ShortCut(Ord('S'), [ssCtrl]);

  MenuItem := AddItem(FMainMenu.Items, '&MariaDB');
  ApplyMenuIcon(MenuItem, 'database');
  FMainMariaMenu.StartItem := AddItem(MenuItem, 'MariaDB S&tart', MariaDbStartClick);
  FMainMariaMenu.StartItem.ShortCut := ShortCut(VK_F8, []);
  FMainMariaMenu.StopItem := AddItem(MenuItem, 'MariaDB St&op', MariaDbStopClick);
  FMainMariaMenu.StopItem.ShortCut := ShortCut(VK_F9, []);
  FMainMariaMenu.RestartItem := AddItem(MenuItem, 'MariaDB Re&start', MariaDbRestartClick);
  FMainMariaMenu.RestartItem.ShortCut := ShortCut(VK_F10, []);
  AddItem(MenuItem, '-');
  Item := AddItem(MenuItem, 'Set &Root Password', SetMariaDbRootPasswordClick);
  Item.ShortCut := ShortCut(Ord('R'), [ssCtrl, ssShift]);
  Item := AddItem(MenuItem, '&Edit mariadb.ini', EditMariaDbIniClick);
  Item.ShortCut := ShortCut(Ord('M'), [ssCtrl, ssShift]);
  Item := AddItem(MenuItem, 'MariaDB &Log', OpenMariaDbLogClick);
  Item.ShortCut := ShortCut(Ord('L'), [ssCtrl, ssShift]);
  Item := AddItem(MenuItem, 'Clear MariaDB L&og', ClearMariaDbLogClick);
  Item.ShortCut := ShortCut(Ord('K'), [ssCtrl]);

  MenuItem := AddItem(FMainMenu.Items, '&VHosts');
  ApplyMenuIcon(MenuItem, 'language');
  Item := AddItem(MenuItem, '&Add VHost', AddVHostClick);
  Item.ShortCut := ShortCut(Ord('N'), [ssCtrl]);
  Item := AddItem(MenuItem, '&Open Selected', OpenVHostClick);
  Item.ShortCut := ShortCut(Ord('O'), [ssCtrl]);
  Item := AddItem(MenuItem, 'Open &Root', OpenVHostFolderClick);
  Item.ShortCut := ShortCut(Ord('R'), [ssCtrl]);
  Item := AddItem(MenuItem, '&Copy URL', CopyVHostUrlClick);
  Item.ShortCut := ShortCut(Ord('C'), [ssCtrl, ssShift]);
  AddItem(MenuItem, '-');
  Item := AddItem(MenuItem, '&Delete Selected', DeleteVHostClick);
  Item.ShortCut := ShortCut(VK_DELETE, []);

  MenuItem := AddItem(FMainMenu.Items, '&Tools');
  ApplyMenuIcon(MenuItem, 'build');
  Item := AddItem(MenuItem, '&Home', LaunchSiteClick);
  Item.ShortCut := ShortCut(Ord('H'), [ssCtrl]);
  Item := AddItem(MenuItem, '&Dashboard', LaunchDashboardClick);
  Item.ShortCut := ShortCut(Ord('D'), [ssCtrl]);
  AddItem(MenuItem, '-');
  Item := AddItem(MenuItem, '&Terminal', LaunchTerminalClick);
  Item.ShortCut := ShortCut(Ord('T'), [ssCtrl]);
  Item := AddItem(MenuItem, 'Apache &Log', OpenApacheLogClick);
  Item.ShortCut := ShortCut(Ord('L'), [ssCtrl]);
  Item := AddItem(MenuItem, 'MariaDB &Log', OpenMariaDbLogClick);
  Item.ShortCut := ShortCut(Ord('M'), [ssCtrl]);
  Item := AddItem(MenuItem, 'Activity &Log', OpenActivityClick);
  Item.ShortCut := ShortCut(Ord('A'), [ssCtrl]);

  MenuItem := AddItem(FMainMenu.Items, '&Window');
  ApplyMenuIcon(MenuItem, 'view_quilt');
  FMainWindowToggleItem := AddItem(MenuItem, 'Hide Window', ToggleWindowClick);

  FTrayMenu := TPopupMenu.Create(Self);
  FTrayMenu.OnPopup := TrayMenuPopup;
  FTrayMenu.Images := FMenuImages;

  FTrayWindowToggleItem := AddItem(FTrayMenu.Items, '&Show Window', ToggleWindowClick);
  ApplyMenuIcon(FTrayWindowToggleItem, 'view_quilt');
  AddItem(FTrayMenu.Items, '-');
  Item := AddItem(FTrayMenu.Items, '&Home', LaunchSiteClick);
  Item.ShortCut := ShortCut(Ord('H'), [ssCtrl]);
  Item := AddItem(FTrayMenu.Items, '&Dashboard', LaunchDashboardClick);
  Item.ShortCut := ShortCut(Ord('D'), [ssCtrl]);
  AddItem(FTrayMenu.Items, '-');
  Item := AddItem(FTrayMenu.Items, '&Save Config', SaveConfigClick);
  ApplyMenuIcon(Item, 'save');
  Item.ShortCut := ShortCut(Ord('S'), [ssCtrl]);
  Item := AddItem(FTrayMenu.Items, '&Generate SSL', GenerateSslClick);
  ApplyMenuIcon(Item, 'lock');
  Item.ShortCut := ShortCut(Ord('G'), [ssCtrl, ssShift]);
  FTrayAutoStartItem := AddItem(FTrayMenu.Items, 'Start with &Windows', AutoStartClick);
  FTrayAutoStartItem.AutoCheck := True;
  Item := AddItem(FTrayMenu.Items, '&Terminal', LaunchTerminalClick);
  Item.ShortCut := ShortCut(Ord('T'), [ssCtrl]);
  AddItem(FTrayMenu.Items, '-');
  FTrayStartAllItem := AddItem(FTrayMenu.Items, 'Start &All', StartButtonClick);
  ApplyMenuIcon(FTrayStartAllItem, 'play_arrow');
  FTrayStartAllItem.ShortCut := ShortCut(VK_F11, []);
  FTrayStopAllItem := AddItem(FTrayMenu.Items, 'S&top All', StopButtonClick);
  ApplyMenuIcon(FTrayStopAllItem, 'stop');
  FTrayStopAllItem.ShortCut := ShortCut(VK_F12, []);
  AddItem(FTrayMenu.Items, '-');
  FTrayApacheMenu.StartItem := AddItem(FTrayMenu.Items, 'Apache S&tart', ApacheStartClick);
  FTrayApacheMenu.StartItem.ShortCut := ShortCut(VK_F5, []);
  FTrayApacheMenu.StopItem := AddItem(FTrayMenu.Items, 'Apache S&top', ApacheStopClick);
  FTrayApacheMenu.StopItem.ShortCut := ShortCut(VK_F6, []);
  FTrayApacheMenu.RestartItem := AddItem(FTrayMenu.Items, 'Apache &Restart', ApacheRestartClick);
  FTrayApacheMenu.RestartItem.ShortCut := ShortCut(VK_F7, []);
  AddItem(FTrayMenu.Items, '-');
  FTrayMariaMenu.StartItem := AddItem(FTrayMenu.Items, 'MariaDB S&tart', MariaDbStartClick);
  FTrayMariaMenu.StartItem.ShortCut := ShortCut(VK_F8, []);
  FTrayMariaMenu.StopItem := AddItem(FTrayMenu.Items, 'MariaDB St&op', MariaDbStopClick);
  FTrayMariaMenu.StopItem.ShortCut := ShortCut(VK_F9, []);
  FTrayMariaMenu.RestartItem := AddItem(FTrayMenu.Items, 'MariaDB Re&start', MariaDbRestartClick);
  FTrayMariaMenu.RestartItem.ShortCut := ShortCut(VK_F10, []);
  AddItem(FTrayMenu.Items, '-');
  Item := AddItem(FTrayMenu.Items, 'Set &Root Password', SetMariaDbRootPasswordClick);
  Item.ShortCut := ShortCut(Ord('R'), [ssCtrl, ssShift]);
  AddItem(FTrayMenu.Items, '-');
  FTrayExitItem := AddItem(FTrayMenu.Items, 'E&xit', ExitButtonClick);
  Menu := FMainMenu;

  FTrayIcon := TTrayIcon.Create(Self);
  FTrayIcon.Icon.Assign(Application.Icon);
  FTrayIcon.Hint := 'UniWamp';
  FTrayIcon.Visible := True;
  FTrayIcon.PopupMenu := FTrayMenu;
  FTrayIcon.OnClick := TrayIconClick;
  UpdateMenuState;
end;

destructor TMainForm.Destroy;
begin
  FMainPhpProfileItems.Free;
  FMainPhpVersionItems.Free;
  FMenuIconIndices.Free;
  FIconCache.Free;
  FRuntime.Free;
  FConfig.Free;
  inherited;
end;

procedure TMainForm.LoadStateIntoUi;
var
  Version: string;
  Entry: TVHostEntry;
  VHosts: TArray<TVHostEntry>;
  RowIndex: Integer;
begin
  HostNameEdit.Text := FConfig.HostName;
  HttpPortEdit.Text := FConfig.HttpPort.ToString;
  HttpsPortEdit.Text := FConfig.HttpsPort.ToString;
  DbPortEdit.Text := FConfig.DatabasePort.ToString;
  DocumentRootEdit.Text := FConfig.DocumentRoot;
  EnableSslCheck.Checked := FConfig.EnableSsl;

  PhpVersionCombo.Items.Clear;
  for Version in FConfig.PhpVersions do
    PhpVersionCombo.Items.Add(Version);
  PhpVersionCombo.ItemIndex := PhpVersionCombo.Items.IndexOf(FConfig.SelectedPhpVersion);
  if PhpVersionCombo.ItemIndex < 0 then
    PhpVersionCombo.ItemIndex := 0;

  NodeVersionCombo.Items.Clear;
  for Version in FConfig.NodeVersions do
    NodeVersionCombo.Items.Add(Version);
  NodeVersionCombo.ItemIndex := NodeVersionCombo.Items.IndexOf(FConfig.SelectedNodeVersion);
  if NodeVersionCombo.ItemIndex < 0 then
    NodeVersionCombo.ItemIndex := 0;

  PhpProfileCombo.ItemIndex := PhpProfileCombo.Items.IndexOf(FConfig.PhpProfile);
  if PhpProfileCombo.ItemIndex < 0 then
    PhpProfileCombo.ItemIndex := 0;

  VHosts := FConfig.VHosts;
  VHostGrid.RowCount := Length(VHosts) + 1;
  if VHostGrid.RowCount < 2 then
    VHostGrid.RowCount := 2;
  VHostGrid.Cells[0, 0] := 'Site Name';
  VHostGrid.Cells[1, 0] := 'Document Path';
  VHostGrid.Cells[2, 0] := 'URL';
  VHostGrid.Cells[3, 0] := 'Actions';
  VHostGrid.RowHeights[0] := 30;
  for RowIndex := 1 to VHostGrid.RowCount - 1 do
  begin
    VHostGrid.Cells[0, RowIndex] := '';
    VHostGrid.Cells[1, RowIndex] := '';
    VHostGrid.Cells[2, RowIndex] := '';
    VHostGrid.Cells[3, RowIndex] := '';
  end;
  for RowIndex := 0 to High(VHosts) do
  begin
    Entry := VHosts[RowIndex];
    VHostGrid.Cells[0, RowIndex + 1] := Entry.ServerName;
    VHostGrid.Cells[1, RowIndex + 1] := Entry.DocumentRoot;
    VHostGrid.Cells[2, RowIndex + 1] := VHostUrl(Entry.ServerName);
  end;
end;

procedure TMainForm.SaveUiIntoState;
begin
  FConfig.HostName := Trim(HostNameEdit.Text);
  FConfig.DocumentRoot := Trim(DocumentRootEdit.Text);
  FConfig.EnableSsl := EnableSslCheck.Checked;
  if not TryStrToInt(Trim(HttpPortEdit.Text), FConfig.HttpPort) then
    FConfig.HttpPort := 8080;
  if not TryStrToInt(Trim(HttpsPortEdit.Text), FConfig.HttpsPort) then
    FConfig.HttpsPort := 8443;
  if not TryStrToInt(Trim(DbPortEdit.Text), FConfig.DatabasePort) then
    FConfig.DatabasePort := 3307;
  if PhpVersionCombo.ItemIndex >= 0 then
    FConfig.SelectedPhpVersion := PhpVersionCombo.Items[PhpVersionCombo.ItemIndex];
  if NodeVersionCombo.ItemIndex >= 0 then
    FConfig.SelectedNodeVersion := NodeVersionCombo.Items[NodeVersionCombo.ItemIndex];
  if PhpProfileCombo.ItemIndex >= 0 then
    FConfig.PhpProfile := PhpProfileCombo.Items[PhpProfileCombo.ItemIndex];
end;

procedure TMainForm.AppendStatus(const Text: string);
var
  Line: string;
begin
  Line := FormatDateTime('hh:nn:ss', Now) + '  ' + Text;
  TFile.AppendAllText(TPath.Combine(FPaths.LogsDir, 'activity.log'), Line + sLineBreak, TEncoding.UTF8);
  if Assigned(FActivityMemo) then
  begin
    FActivityMemo.Lines.Add(Line);
    while FActivityMemo.Lines.Count > 200 do
      FActivityMemo.Lines.Delete(0);
    FActivityMemo.SelStart := Length(FActivityMemo.Text);
    FActivityMemo.Perform(EM_SCROLLCARET, 0, 0);
  end;
end;

procedure TMainForm.RefreshActivityLogView;
var
  LogFile: string;
  Lines: TStringList;
  StartIndex: Integer;
  I: Integer;
  CurrentWriteTime: TDateTime;
begin
  if not Assigned(FActivityMemo) then
    Exit;

  LogFile := TPath.Combine(FPaths.LogsDir, 'activity.log');
  if not FileExists(LogFile) then
  begin
    if FActivityMemo.Lines.Count > 0 then
      FActivityMemo.Clear;
    FLastActivityLogWriteTime := 0;
    Exit;
  end;

  CurrentWriteTime := TFile.GetLastWriteTime(LogFile);
  if (CurrentWriteTime = FLastActivityLogWriteTime) and (FActivityMemo.Lines.Count > 0) then
    Exit;
  FLastActivityLogWriteTime := CurrentWriteTime;

  Lines := TStringList.Create;
  try
    Lines.Text := TFile.ReadAllText(LogFile, TEncoding.UTF8);
    StartIndex := 0;
    if Lines.Count > 200 then
      StartIndex := Lines.Count - 200;
    FActivityMemo.Lines.BeginUpdate;
    try
      FActivityMemo.Clear;
      for I := StartIndex to Lines.Count - 1 do
        if Trim(Lines[I]) <> '' then
          FActivityMemo.Lines.Add(Lines[I]);
    finally
      FActivityMemo.Lines.EndUpdate;
    end;
    if FActivityMemo.Lines.Count > 0 then
    begin
      FActivityMemo.SelStart := Length(FActivityMemo.Text);
      FActivityMemo.Perform(EM_SCROLLCARET, 0, 0);
    end;
  finally
    Lines.Free;
  end;
end;

procedure TMainForm.RefreshStatus;
var
  ApacheRunningBefore: Boolean;
  ApachePidBefore: Cardinal;
  MariaDbRunningBefore: Boolean;
  MariaDbPidBefore: Cardinal;
  MariaDbInitialized: Boolean;
begin
  if FStatusRefreshBusy then
    Exit;
  FStatusRefreshBusy := True;
  FStatusRefreshTimer.Enabled := False;
  try
  ApacheRunningBefore := FConfig.ApacheRunning;
  ApachePidBefore := FConfig.ApachePid;
  MariaDbRunningBefore := FConfig.MariaDbRunning;
  MariaDbPidBefore := FConfig.MariaDbPid;
  MariaDbInitialized := TDirectory.Exists(TPath.Combine(TPath.Combine(FPaths.MariaDbDir, 'data'), 'mysql'));
  FConfig.ApacheRunning := FRuntime.ApacheIsRunning or
    ((FConfig.ApachePid <> 0) and TProcessManager.IsRunning(FConfig.ApachePid));
  if FConfig.ApacheRunning then
    FConfig.ApachePid := FRuntime.ApacheProcessId
  else
    FConfig.ApachePid := 0;

  FConfig.MariaDbRunning := FRuntime.MariaDbIsRunning or
    ((FConfig.MariaDbPid <> 0) and TProcessManager.IsRunning(FConfig.MariaDbPid));
  if not FConfig.MariaDbRunning then
    FConfig.MariaDbPid := 0;
  if FConfig.MariaDbRunning then
    FConfig.LastMariaDbError := '';
  if MariaDbInitialized and (Pos('init', LowerCase(FConfig.LastMariaDbError)) > 0) then
    FConfig.LastMariaDbError := '';

  UpdateHeaderStateColors;
  UpdateServiceButtonState;
  UpdateDashboardLabels;
  UpdateStackActionState;
  UpdateVHostActionState;
  UpdateMenuState;
  UpdatePortConflictLabels;
  RefreshActivityLogView;

  if (ApacheRunningBefore <> FConfig.ApacheRunning) or
     (ApachePidBefore <> FConfig.ApachePid) or
     (MariaDbRunningBefore <> FConfig.MariaDbRunning) or
     (MariaDbPidBefore <> FConfig.MariaDbPid) then
    FConfig.Save(FPaths);
  finally
    FStatusRefreshTimer.Enabled := True;
    FStatusRefreshBusy := False;
  end;
end;

procedure TMainForm.UpdatePortConflictLabels;
var
  Port: Integer;
  OwnerInfo: string;
  CaptionText: string;
begin
  if not Assigned(FHttpPortOwnerLabel) then
    Exit;

  Port := StrToIntDef(Trim(HttpPortEdit.Text), FConfig.HttpPort);
  if (Port <> FLastHttpPortChecked) or (FHttpPortOwnerLabel.Caption = '') then
  begin
    OwnerInfo := FRuntime.DescribePortOwner(Port);
    if OwnerInfo = '' then
    begin
      CaptionText := Format('HTTP %d: available', [Port]);
      FHttpPortOwnerLabel.Font.Color := RGB(0, 128, 0);
    end
    else
    begin
      CaptionText := Format('HTTP %d: %s', [Port, OwnerInfo]);
      FHttpPortOwnerLabel.Font.Color := clRed;
    end;
    FHttpPortOwnerLabel.Caption := CaptionText;
    FHttpPortOwnerLabel.Hint := CaptionText;
    FLastHttpPortChecked := Port;
  end;

  Port := StrToIntDef(Trim(HttpsPortEdit.Text), FConfig.HttpsPort);
  if (Port <> FLastHttpsPortChecked) or (FHttpsPortOwnerLabel.Caption = '') then
  begin
    OwnerInfo := FRuntime.DescribePortOwner(Port);
    if OwnerInfo = '' then
    begin
      CaptionText := Format('HTTPS %d: available', [Port]);
      FHttpsPortOwnerLabel.Font.Color := RGB(0, 128, 0);
    end
    else
    begin
      CaptionText := Format('HTTPS %d: %s', [Port, OwnerInfo]);
      FHttpsPortOwnerLabel.Font.Color := clRed;
    end;
    FHttpsPortOwnerLabel.Caption := CaptionText;
    FHttpsPortOwnerLabel.Hint := CaptionText;
    FLastHttpsPortChecked := Port;
  end;

  Port := StrToIntDef(Trim(DbPortEdit.Text), FConfig.DatabasePort);
  if (Port <> FLastDbPortChecked) or (FDbPortOwnerLabel.Caption = '') then
  begin
    OwnerInfo := FRuntime.DescribePortOwner(Port);
    if OwnerInfo = '' then
    begin
      CaptionText := Format('DB %d: available', [Port]);
      FDbPortOwnerLabel.Font.Color := RGB(0, 128, 0);
    end
    else
    begin
      CaptionText := Format('DB %d: %s', [Port, OwnerInfo]);
      FDbPortOwnerLabel.Font.Color := clRed;
    end;
    FDbPortOwnerLabel.Caption := CaptionText;
    FDbPortOwnerLabel.Hint := CaptionText;
    FLastDbPortChecked := Port;
  end;
end;

procedure TMainForm.UpdateHeaderStateColors;
var
  HeaderColor: TColor;
  I: Integer;
begin
  if FConfig.ApacheRunning or FConfig.MariaDbRunning then
    HeaderColor := HeaderOnlineColor
  else
    HeaderColor := HeaderOfflineColor;

  HeaderPanel.Color := HeaderColor;
  Label18.Color := HeaderColor;
  Label19.Color := HeaderColor;
  Label18.Font.Color := HeaderTextColor;
  Label19.Font.Color := HeaderSubTextColor;
  Label19.Caption := 'Portable WAMP dashboard for local development';
  exitbutton.Color := RGB(255, 206, 206);
  for I := Low(FHeaderCards) to High(FHeaderCards) do
  begin
    FHeaderCards[I].Panel.Color := HeaderColor;
    FHeaderCards[I].Title.Font.Color := HeaderTextColor;
    FHeaderCards[I].Detail1.Font.Color := HeaderSubTextColor;
    FHeaderCards[I].Detail2.Font.Color := HeaderSubTextColor;
  end;
  UpdateHeaderStatusCards;
end;

procedure TMainForm.UpdateHeaderStatusCards;
var
  ApacheText: string;
  PhpText: string;
  MariaText: string;
begin
  if FConfig.ApacheRunning then
  begin
    FHeaderCards[0].Dot.Brush.Color := RGB(180, 225, 48);
    ApacheText := 'HTTP ' + IntToStr(FConfig.HttpPort);
    FHeaderCards[0].Detail2.Caption := 'HTTPS ' + IntToStr(FConfig.HttpsPort);
  end
  else
  begin
    FHeaderCards[0].Dot.Brush.Color := RGB(189, 197, 209);
    ApacheText := 'HTTP ' + IntToStr(FConfig.HttpPort);
    FHeaderCards[0].Detail2.Caption := 'HTTPS ' + IntToStr(FConfig.HttpsPort);
  end;
  FHeaderCards[0].Detail1.Caption := ApacheText;

  FHeaderCards[1].Dot.Brush.Color := RGB(180, 225, 48);
  FHeaderCards[1].Detail1.Caption := FConfig.SelectedPhpVersion;
  if Trim(FConfig.SelectedNodeVersion) <> '' then
    PhpText := FConfig.SelectedNodeVersion
  else
    PhpText := 'node not selected';
  FHeaderCards[1].Detail2.Caption := PhpText;

  if FConfig.MariaDbRunning then
    FHeaderCards[2].Dot.Brush.Color := RGB(180, 225, 48)
  else
    FHeaderCards[2].Dot.Brush.Color := RGB(189, 197, 209);
  FHeaderCards[2].Detail1.Caption := 'Port ' + IntToStr(FConfig.DatabasePort);
  if FConfig.MariaDbRunning then
    MariaText := 'Running'
  else
    MariaText := 'Stopped';
  FHeaderCards[2].Detail2.Caption := MariaText;
end;

procedure TMainForm.UpdateServiceButtonState;
begin
  ApacheStartButton.Enabled := not FConfig.ApacheRunning;
  ApacheStopButton.Enabled := FConfig.ApacheRunning;
  ApacheRestartButton.Enabled := FConfig.ApacheRunning;

  MariaStartButton.Enabled := not FConfig.MariaDbRunning;
  MariaStopButton.Enabled := FConfig.MariaDbRunning;
  MariaRestartButton.Enabled := FConfig.MariaDbRunning;

  StylePanelButton(ApacheStartButton, ApacheStartButton.Enabled, ButtonPositiveColor, ButtonNeutralColor);
  StylePanelButton(ApacheStopButton, ApacheStopButton.Enabled, ButtonNegativeColor, ButtonNeutralColor);
  StylePanelButton(ApacheRestartButton, ApacheRestartButton.Enabled, ButtonWarningColor, ButtonNeutralColor);
  StylePanelButton(MariaStartButton, MariaStartButton.Enabled, ButtonPositiveColor, ButtonNeutralColor);
  StylePanelButton(MariaStopButton, MariaStopButton.Enabled, ButtonNegativeColor, ButtonNeutralColor);
  StylePanelButton(MariaRestartButton, MariaRestartButton.Enabled, ButtonWarningColor, ButtonNeutralColor);
end;

procedure TMainForm.UpdateDashboardLabels;
var
  StatusText: string;
  MariaDbSummary: string;
begin
  StatusText := Format(
    'Apache %s PID %d | MariaDB %s PID %d | HTTP %d | PHP %s / %s | Node %s | Hosts %s',
    [
      BoolToStr(FConfig.ApacheRunning, True),
      FConfig.ApachePid,
      BoolToStr(FConfig.MariaDbRunning, True),
      FConfig.MariaDbPid,
      FConfig.HttpPort,
      FConfig.SelectedPhpVersion,
      FConfig.PhpProfile,
      FConfig.SelectedNodeVersion,
      FConfig.LastHostsSyncStatus
    ]);

  if (not FConfig.MariaDbRunning) and (Trim(FConfig.LastMariaDbError) <> '') then
  begin
    MariaDbSummary := 'MariaDB: stopped';
    if Pos('not initialized', LowerCase(FConfig.LastMariaDbError)) > 0 then
      MariaDbSummary := 'MariaDB: stopped (init required)'
    else if Pos('initialization', LowerCase(FConfig.LastMariaDbError)) > 0 then
      MariaDbSummary := 'MariaDB: stopped (init failed)'
    else
      MariaDbSummary := 'MariaDB: stopped (error)';
    StatusText := StringReplace(StatusText,
      Format('MariaDB %s PID %d', [BoolToStr(FConfig.MariaDbRunning, True), FConfig.MariaDbPid]),
      MariaDbSummary,
      []);
    StatusBar.ShowHint := True;
    StatusBar.Hint := FConfig.LastMariaDbError;
  end
  else
  begin
    StatusBar.ShowHint := False;
    StatusBar.Hint := '';
  end;

  StatusBar.SimpleText := StatusText;
end;

procedure TMainForm.UpdateStackActionState;
var
  AllRunning: Boolean;
  AnyRunning: Boolean;
begin
  AllRunning := FConfig.ApacheRunning and FConfig.MariaDbRunning;
  AnyRunning := FConfig.ApacheRunning or FConfig.MariaDbRunning;

  startbutton.Enabled := not AllRunning;
  stopbutton.Enabled := AnyRunning;

  if AllRunning then
    SetButtonCaption(startbutton, 'Started')
  else
    SetButtonCaption(startbutton, 'Start All');

  StylePanelButton(startbutton, startbutton.Enabled, ButtonSuccessStrongColor, ButtonPositiveColor, clWhite);
  if not startbutton.Enabled then
    startbutton.Font.Color := RGB(64, 96, 64);
  StylePanelButton(stopbutton, stopbutton.Enabled, ButtonDangerStrongColor, ButtonNeutralColor, clWhite);
  exitbutton.Color := $00FFD3D3;
  exitbutton.Font.Color := $00603030;
  SetButtonCaption(exitbutton, 'Exit');
end;

procedure TMainForm.UpdateVHostActionState;
var
  HasSelection: Boolean;
begin
  HasSelection := SelectedVHostServerName <> '';
  AddVHostButton.Enabled := True;
  OpenVHostButton.Enabled := FConfig.ApacheRunning and HasSelection;
  OpenVHostFolderButton.Enabled := HasSelection;
  CopyVHostUrlButton.Enabled := HasSelection;
  DeleteVHostButton.Enabled := HasSelection;

  StylePanelButton(AddVHostButton, True, ButtonSuccessStrongColor, ButtonPositiveColor, clWhite);
  StylePanelButton(OpenVHostButton, OpenVHostButton.Enabled, ButtonAccentColor, ButtonNeutralColor);
  StylePanelButton(OpenVHostFolderButton, OpenVHostFolderButton.Enabled, ButtonNeutralColor, ButtonNeutralColor);
  StylePanelButton(CopyVHostUrlButton, CopyVHostUrlButton.Enabled, ButtonNeutralColor, ButtonNeutralColor);
  StylePanelButton(DeleteVHostButton, DeleteVHostButton.Enabled, ButtonDangerStrongColor, ButtonNeutralColor, clWhite);
  VHostGrid.Invalidate;
end;

procedure TMainForm.UpdateMenuState;
var
  MenuItem: TMenuItem;
  AutoStartEnabled: Boolean;
begin
  AutoStartEnabled := IsAutoStartEnabled;

  if Assigned(FMainWindowToggleItem) then
    if Visible and (WindowState <> wsMinimized) then
      FMainWindowToggleItem.Caption := 'Hide Window'
    else
      FMainWindowToggleItem.Caption := 'Show Window';

  if Assigned(FTrayWindowToggleItem) then
    if Visible and (WindowState <> wsMinimized) then
      FTrayWindowToggleItem.Caption := 'Hide Window'
    else
      FTrayWindowToggleItem.Caption := 'Show Window';

  if Assigned(FMainExitItem) then
    FMainExitItem.Enabled := True;
  if Assigned(FTrayExitItem) then
    FTrayExitItem.Enabled := True;

  if Assigned(FMainStartAllItem) then
  begin
    FMainStartAllItem.Enabled := not (FConfig.ApacheRunning and FConfig.MariaDbRunning);
    if FConfig.ApacheRunning and FConfig.MariaDbRunning then
      FMainStartAllItem.Caption := 'All Services - Running'
    else
      FMainStartAllItem.Caption := 'Start All';
  end;
  if Assigned(FMainStopAllItem) then
    FMainStopAllItem.Enabled := FConfig.ApacheRunning or FConfig.MariaDbRunning;
  if Assigned(FTrayStartAllItem) then
  begin
    FTrayStartAllItem.Enabled := not (FConfig.ApacheRunning and FConfig.MariaDbRunning);
    if FConfig.ApacheRunning and FConfig.MariaDbRunning then
      FTrayStartAllItem.Caption := 'All Services - Running'
    else
      FTrayStartAllItem.Caption := 'Start All';
  end;
  if Assigned(FTrayStopAllItem) then
    FTrayStopAllItem.Enabled := FConfig.ApacheRunning or FConfig.MariaDbRunning;

  if Assigned(FMainApacheMenu.StartItem) then
    FMainApacheMenu.StartItem.Enabled := not FConfig.ApacheRunning;
  if Assigned(FMainApacheMenu.StopItem) then
    FMainApacheMenu.StopItem.Enabled := FConfig.ApacheRunning;
  if Assigned(FMainApacheMenu.RestartItem) then
    FMainApacheMenu.RestartItem.Enabled := FConfig.ApacheRunning;

  if Assigned(FMainMariaMenu.StartItem) then
    FMainMariaMenu.StartItem.Enabled := not FConfig.MariaDbRunning;
  if Assigned(FMainMariaMenu.StopItem) then
    FMainMariaMenu.StopItem.Enabled := FConfig.MariaDbRunning;
  if Assigned(FMainMariaMenu.RestartItem) then
    FMainMariaMenu.RestartItem.Enabled := FConfig.MariaDbRunning;

  if Assigned(FTrayApacheMenu.StartItem) then
    FTrayApacheMenu.StartItem.Enabled := not FConfig.ApacheRunning;
  if Assigned(FTrayApacheMenu.StopItem) then
    FTrayApacheMenu.StopItem.Enabled := FConfig.ApacheRunning;
  if Assigned(FTrayApacheMenu.RestartItem) then
    FTrayApacheMenu.RestartItem.Enabled := FConfig.ApacheRunning;

  if Assigned(FTrayMariaMenu.StartItem) then
    FTrayMariaMenu.StartItem.Enabled := not FConfig.MariaDbRunning;
  if Assigned(FTrayMariaMenu.StopItem) then
    FTrayMariaMenu.StopItem.Enabled := FConfig.MariaDbRunning;
  if Assigned(FTrayMariaMenu.RestartItem) then
    FTrayMariaMenu.RestartItem.Enabled := FConfig.MariaDbRunning;

  if Assigned(FMainAutoStartItem) then
    FMainAutoStartItem.Checked := AutoStartEnabled;
  if Assigned(FTrayAutoStartItem) then
    FTrayAutoStartItem.Checked := AutoStartEnabled;

  if Assigned(FMainPhpMenu) then
  begin
    for MenuItem in FMainPhpVersionItems do
      MenuItem.Checked := SameText(MenuItem.Caption, FConfig.SelectedPhpVersion);
    for MenuItem in FMainPhpProfileItems do
      MenuItem.Checked := SameText(MenuItem.Caption, FConfig.PhpProfile);
  end;
end;

function TMainForm.IsAutoStartEnabled: Boolean;
var
  Registry: TRegistry;
begin
  Result := False;
  Registry := TRegistry.Create;
  try
    Registry.RootKey := HKEY_CURRENT_USER;
    if Registry.OpenKeyReadOnly('Software\Microsoft\Windows\CurrentVersion\Run') then
    try
      Result := Registry.ValueExists('UniWamp');
    finally
      Registry.CloseKey;
    end;
  finally
    Registry.Free;
  end;
end;

procedure TMainForm.SetAutoStartEnabled(const Enabled: Boolean);
var
  Registry: TRegistry;
  CommandLine: string;
begin
  Registry := TRegistry.Create;
  try
    Registry.RootKey := HKEY_CURRENT_USER;
    if Registry.OpenKey('Software\Microsoft\Windows\CurrentVersion\Run', True) then
    try
      if Enabled then
      begin
        CommandLine := '"' + Application.ExeName + '"';
        Registry.WriteString('UniWamp', CommandLine);
      end
      else if Registry.ValueExists('UniWamp') then
        Registry.DeleteValue('UniWamp');
    finally
      Registry.CloseKey;
    end;
  finally
    Registry.Free;
  end;
  UpdateMenuState;
end;

procedure TMainForm.AutoStartClick(Sender: TObject);
begin
  SetAutoStartEnabled(not IsAutoStartEnabled);
end;

procedure TMainForm.ToggleMainWindow;
begin
  if Visible and (WindowState <> wsMinimized) then
    Hide
  else
  begin
    Show;
    WindowState := wsNormal;
    BringToFront;
    SetForegroundWindow(Handle);
  end;
  UpdateMenuState;
end;

procedure TMainForm.StatusRefreshTimer(Sender: TObject);
begin
  if FStatusRefreshBusy then
    Exit;
  RefreshStatus;
end;

procedure TMainForm.ToggleWindowClick(Sender: TObject);
begin
  ToggleMainWindow;
end;

procedure TMainForm.TrayIconClick(Sender: TObject);
begin
  ToggleMainWindow;
end;

procedure TMainForm.TrayMenuPopup(Sender: TObject);
begin
  RefreshStatus;
  UpdateMenuState;
end;

function TMainForm.VHostUrl(const ServerName: string): string;
begin
  Result := Format('http://%s:%d/', [ServerName, StrToIntDef(HttpPortEdit.Text, FConfig.HttpPort)]);
end;

function TMainForm.SelectedVHostServerName: string;
begin
  Result := '';
  if (VHostGrid.Row > 0) and (VHostGrid.Row < VHostGrid.RowCount) then
    Result := Trim(VHostGrid.Cells[0, VHostGrid.Row]);
end;

function TMainForm.TryGetVHostEntry(const ServerName: string; out Entry: TVHostEntry): Boolean;
var
  Item: TVHostEntry;
begin
  Result := False;
  Entry.ServerName := '';
  Entry.ServerAliases := '';
  Entry.DocumentRoot := '';
  Entry.EnableSsl := False;
  Entry.SslCertFile := '';
  Entry.SslKeyFile := '';
  for Item in FConfig.VHosts do
    if SameText(Item.ServerName, ServerName) then
    begin
      Entry := Item;
      Exit(True);
    end;
end;

procedure TMainForm.OpenVHostUrl(const ServerName: string);
var
  ResultInfo: TRuntimeActionResult;
begin
  if ServerName = '' then
    Exit;
  RefreshStatus;
  if not FConfig.ApacheRunning then
  begin
    AppendStatus('Cannot open vHost URL because Apache is not running.');
    Exit;
  end;
  ResultInfo := FRuntime.LaunchUrl(VHostUrl(ServerName));
  AppendStatus(ResultInfo.Message);
end;

procedure TMainForm.OpenVHostFolder(const ServerName: string);
var
  RowIndex: Integer;
  FolderPath: string;
begin
  FolderPath := '';
  for RowIndex := 1 to VHostGrid.RowCount - 1 do
    if SameText(VHostGrid.Cells[0, RowIndex], ServerName) then
    begin
      FolderPath := VHostGrid.Cells[1, RowIndex];
      Break;
    end;

  if FolderPath <> '' then
    ShellExecute(0, 'open', PChar(FolderPath), nil, nil, SW_SHOWNORMAL);
end;

procedure TMainForm.DeleteVHostByName(const ServerName: string);
var
  ResultInfo: TRuntimeActionResult;
  RestartInfo: TRuntimeActionResult;
begin
  if ServerName = '' then
    Exit;
  ResultInfo := FRuntime.DeleteVHost(ServerName);
  AppendStatus(ResultInfo.Message);
  if ResultInfo.Success and FConfig.ApacheRunning then
  begin
    RestartInfo := FRuntime.RestartApache;
    AppendStatus('Apache reload after VHost delete: ' + RestartInfo.Message);
  end;
  FConfig.Save(FPaths);
  RefreshStatus;
  LoadStateIntoUi;
end;

procedure TMainForm.VHostGridDrawCell(Sender: TObject; ACol, ARow: Integer; CellRect: TRect; State: TGridDrawState);
const
  ActionGap = 4;
  OpenWidth = 36;
  FolderWidth = 36;
  DeleteWidth = 36;
  SslWidth = 36;
var
  Grid: TStringGrid;
  CellText: string;
  ButtonRect: TRect;
  ActionLeft: Integer;
  OpenEnabled: Boolean;
  VHostEntry: TVHostEntry;
  HasVHostEntry: Boolean;
begin
  Grid := Sender as TStringGrid;
  if ARow = 0 then
    Grid.Canvas.Brush.Color := GridHeaderColor
  else if Odd(ARow) then
    Grid.Canvas.Brush.Color := GridStripeColor
  else
    Grid.Canvas.Brush.Color := clWhite;
  Grid.Canvas.FillRect(CellRect);

  if ARow = 0 then
  begin
    Grid.Canvas.Font.Style := [fsBold];
    Grid.Canvas.Font.Color := clWindowText;
    DrawText(Grid.Canvas.Handle, PChar(Grid.Cells[ACol, ARow]), -1, CellRect,
      DT_CENTER or DT_VCENTER or DT_SINGLELINE or DT_END_ELLIPSIS);
    Exit;
  end;

  if gdSelected in State then
  begin
    if not ((ACol = 3) and not FConfig.ApacheRunning) then
    begin
      Grid.Canvas.Brush.Color := GridSelectionColor;
      Grid.Canvas.FillRect(CellRect);
    end;
  end;

  if ACol < 3 then
  begin
    Grid.Canvas.Font.Style := [];
    Grid.Canvas.Font.Color := clWindowText;
    CellText := Grid.Cells[ACol, ARow];
    InflateRect(CellRect, -6, -3);
    DrawText(Grid.Canvas.Handle, PChar(CellText), -1, CellRect,
      DT_LEFT or DT_VCENTER or DT_SINGLELINE or DT_END_ELLIPSIS);
    Exit;
  end;

  Grid.Canvas.Font.Style := [fsBold];
  ActionLeft := CellRect.Left + 6;
  OpenEnabled := FConfig.ApacheRunning;
  HasVHostEntry := TryGetVHostEntry(Trim(Grid.Cells[0, ARow]), VHostEntry);

  ButtonRect := System.Types.Rect(ActionLeft, CellRect.Top + 4, ActionLeft + OpenWidth, CellRect.Bottom - 4);
  if OpenEnabled then
    Grid.Canvas.Brush.Color := ButtonAccentColor
  else
    Grid.Canvas.Brush.Color := ButtonNeutralColor;
  Grid.Canvas.RoundRect(ButtonRect.Left, ButtonRect.Top, ButtonRect.Right, ButtonRect.Bottom, 8, 8);
  DrawIconInRect(Grid.Canvas, 'open_in_new', ButtonRect, 16);

  Inc(ActionLeft, OpenWidth + ActionGap);
  ButtonRect := System.Types.Rect(ActionLeft, CellRect.Top + 4, ActionLeft + FolderWidth, CellRect.Bottom - 4);
  Grid.Canvas.Brush.Color := ButtonAccentColor;
  Grid.Canvas.RoundRect(ButtonRect.Left, ButtonRect.Top, ButtonRect.Right, ButtonRect.Bottom, 8, 8);
  DrawIconInRect(Grid.Canvas, 'folder_open', ButtonRect, 16);

  Inc(ActionLeft, FolderWidth + ActionGap);
  ButtonRect := System.Types.Rect(ActionLeft, CellRect.Top + 4, ActionLeft + DeleteWidth, CellRect.Bottom - 4);
  Grid.Canvas.Brush.Color := ButtonNegativeColor;
  Grid.Canvas.RoundRect(ButtonRect.Left, ButtonRect.Top, ButtonRect.Right, ButtonRect.Bottom, 8, 8);
  DrawIconInRect(Grid.Canvas, 'delete', ButtonRect, 16);

  Inc(ActionLeft, DeleteWidth + ActionGap);
  ButtonRect := System.Types.Rect(ActionLeft, CellRect.Top + 4, ActionLeft + SslWidth, CellRect.Bottom - 4);
  if HasVHostEntry and VHostEntry.EnableSsl then
    Grid.Canvas.Brush.Color := ButtonPositiveColor
  else
    Grid.Canvas.Brush.Color := ButtonNeutralColor;
  Grid.Canvas.RoundRect(ButtonRect.Left, ButtonRect.Top, ButtonRect.Right, ButtonRect.Bottom, 8, 8);
  if HasVHostEntry and VHostEntry.EnableSsl then
    DrawIconInRect(Grid.Canvas, 'lock', ButtonRect, 16)
  else
    DrawIconInRect(Grid.Canvas, 'lock_open', ButtonRect, 16);
end;

procedure TMainForm.VHostGridMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
const
  ActionGap = 4;
  OpenWidth = 36;
  FolderWidth = 36;
  DeleteWidth = 36;
  SslWidth = 36;
var
  Grid: TStringGrid;
  GridCoord: TGridCoord;
  CellRect: TRect;
  RelativeX: Integer;
  ServerName: string;
  OpenLeft: Integer;
  FolderLeft: Integer;
  DeleteLeft: Integer;
  SslLeft: Integer;
  VHostEntry: TVHostEntry;
begin
  Grid := Sender as TStringGrid;
  GridCoord := Grid.MouseCoord(X, Y);
  if (GridCoord.Y <= 0) or (GridCoord.X <> 3) then
    Exit;

  Grid.Row := GridCoord.Y;
  UpdateVHostActionState;
  ServerName := Trim(Grid.Cells[0, GridCoord.Y]);
  if ServerName = '' then
    Exit;

  CellRect := Grid.CellRect(GridCoord.X, GridCoord.Y);
  RelativeX := X - CellRect.Left;
  OpenLeft := 6;
  FolderLeft := OpenLeft + OpenWidth + ActionGap;
  DeleteLeft := FolderLeft + FolderWidth + ActionGap;
  SslLeft := DeleteLeft + DeleteWidth + ActionGap;
  if not TryGetVHostEntry(ServerName, VHostEntry) then
    Exit;

  if not FConfig.ApacheRunning and (RelativeX >= OpenLeft) and (RelativeX < (OpenLeft + OpenWidth)) then
    Exit;

  if (RelativeX >= OpenLeft) and (RelativeX < (OpenLeft + OpenWidth)) then
    OpenVHostUrl(ServerName)
  else if (RelativeX >= FolderLeft) and (RelativeX < (FolderLeft + FolderWidth)) then
    OpenVHostFolder(ServerName)
  else if (RelativeX >= DeleteLeft) and (RelativeX < (DeleteLeft + DeleteWidth)) then
    DeleteVHostByName(ServerName)
  else if VHostEntry.EnableSsl and (RelativeX >= SslLeft) and (RelativeX < (SslLeft + SslWidth)) then
    RefreshVHostSslClick(Sender)
  else
    Exit;
end;

procedure TMainForm.SaveConfigClick(Sender: TObject);
begin
  SaveUiIntoState;
  FRuntime.GenerateAllConfigs;
  FConfig.Save(FPaths);
  AppendStatus('Configuration saved and generated.');
  RefreshStatus;
end;

procedure TMainForm.ApacheStartClick(Sender: TObject);
var
  ResultInfo: TRuntimeActionResult;
begin
  SaveUiIntoState;
  ResultInfo := FRuntime.StartApache;
  AppendStatus(ResultInfo.Message);
  FConfig.Save(FPaths);
  RefreshStatus;
  if ResultInfo.Success then
    FRuntime.LaunchUrl(Format('http://127.0.0.1:%d/dashboard/', [FConfig.HttpPort]));
end;

procedure TMainForm.ApacheStopClick(Sender: TObject);
var
  ResultInfo: TRuntimeActionResult;
begin
  FStatusRefreshTimer.Enabled := False;
  try
  ResultInfo := FRuntime.StopApache;
  AppendStatus(ResultInfo.Message);
  FConfig.Save(FPaths);
  RefreshStatus;
  finally
    FStatusRefreshTimer.Enabled := True;
  end;
end;

procedure TMainForm.ApacheRestartClick(Sender: TObject);
var
  ResultInfo: TRuntimeActionResult;
begin
  SaveUiIntoState;
  ResultInfo := FRuntime.RestartApache;
  AppendStatus(ResultInfo.Message);
  FConfig.Save(FPaths);
  RefreshStatus;
end;

procedure TMainForm.MariaDbStartClick(Sender: TObject);
var
  ResultInfo: TRuntimeActionResult;
begin
  SaveUiIntoState;
  ResultInfo := TStartProgressForm.ExecuteStart(Self, FRuntime, FConfig, FPaths);
  AppendStatus(ResultInfo.Message);
  FConfig.Save(FPaths);
  RefreshStatus;
end;

procedure TMainForm.MariaDbStopClick(Sender: TObject);
var
  ResultInfo: TRuntimeActionResult;
begin
  FStatusRefreshTimer.Enabled := False;
  try
  ResultInfo := FRuntime.StopMariaDb;
  AppendStatus(ResultInfo.Message);
  FConfig.Save(FPaths);
  RefreshStatus;
  finally
    FStatusRefreshTimer.Enabled := True;
  end;
end;

procedure TMainForm.MariaDbRestartClick(Sender: TObject);
var
  ResultInfo: TRuntimeActionResult;
begin
  SaveUiIntoState;
  ResultInfo := FRuntime.RestartMariaDb;
  AppendStatus(ResultInfo.Message);
  FConfig.Save(FPaths);
  RefreshStatus;
end;

procedure TMainForm.StartButtonClick(Sender: TObject);
var
  MariaResult: TRuntimeActionResult;
  ApacheResult: TRuntimeActionResult;
  AttemptedAnything: Boolean;
  StartedAnything: Boolean;
begin
  SaveUiIntoState;
  RefreshStatus;
  FConfig.Save(FPaths);

  AttemptedAnything := False;
  StartedAnything := False;

  if not FConfig.MariaDbRunning then
  begin
    AttemptedAnything := True;
    MariaResult := TStartProgressForm.ExecuteStart(Self, FRuntime, FConfig, FPaths);
    AppendStatus('Start all - MariaDB: ' + MariaResult.Message);
    StartedAnything := StartedAnything or MariaResult.Success;
  end;

  if not FConfig.ApacheRunning then
  begin
    AttemptedAnything := True;
    ApacheResult := FRuntime.StartApache;
    AppendStatus('Start all - Apache: ' + ApacheResult.Message);
    StartedAnything := StartedAnything or ApacheResult.Success;
    if ApacheResult.Success then
      FRuntime.LaunchUrl(Format('http://127.0.0.1:%d/dashboard/', [FConfig.HttpPort]));
  end;

  if not AttemptedAnything then
    AppendStatus('All services are already running.');
  if AttemptedAnything and not StartedAnything then
    AppendStatus('Start all completed with errors.');

  FConfig.Save(FPaths);
  RefreshStatus;
end;

procedure TMainForm.StopButtonClick(Sender: TObject);
var
  ApacheResult: TRuntimeActionResult;
  MariaResult: TRuntimeActionResult;
  StoppedAnything: Boolean;
begin
  FStatusRefreshTimer.Enabled := False;
  try
  RefreshStatus;
  StoppedAnything := False;

  if FConfig.ApacheRunning then
  begin
    ApacheResult := FRuntime.StopApache;
    AppendStatus('Stop all - Apache: ' + ApacheResult.Message);
    StoppedAnything := True;
  end;

  if FConfig.MariaDbRunning then
  begin
    MariaResult := FRuntime.StopMariaDb;
    AppendStatus('Stop all - MariaDB: ' + MariaResult.Message);
    StoppedAnything := True;
  end;

  if not StoppedAnything then
    AppendStatus('All services are already stopped.');

  FConfig.Save(FPaths);
  RefreshStatus;
  finally
    FStatusRefreshTimer.Enabled := True;
  end;
end;

procedure TMainForm.LaunchSiteClick(Sender: TObject);
var
  ResultInfo: TRuntimeActionResult;
begin
  ResultInfo := FRuntime.LaunchUrl(Format('http://127.0.0.1:%d/', [StrToIntDef(HttpPortEdit.Text, 8080)]));
  AppendStatus(ResultInfo.Message);
end;

procedure TMainForm.LaunchDashboardClick(Sender: TObject);
var
  ResultInfo: TRuntimeActionResult;
begin
  ResultInfo := FRuntime.LaunchUrl(Format('http://127.0.0.1:%d/dashboard/', [StrToIntDef(HttpPortEdit.Text, 8080)]));
  AppendStatus(ResultInfo.Message);
end;

procedure TMainForm.OpenPhpExtensionsClick(Sender: TObject);
begin
  if TPhpExtensionsForm.Execute(Self, FPaths, FConfig, FRuntime) then
  begin
    LoadStateIntoUi;
    RefreshStatus;
    AppendStatus('PHP extensions saved.');
  end;
end;

procedure TMainForm.OpenApacheModulesClick(Sender: TObject);
begin
  if TApacheModulesForm.Execute(Self, FPaths, FConfig, FRuntime) then
  begin
    LoadStateIntoUi;
    RefreshStatus;
    AppendStatus('Apache modules saved.');
  end;
end;

procedure TMainForm.OpenPhpSettingsClick(Sender: TObject);
begin
  if TPhpSettingsForm.Execute(Self, FPaths, FConfig, FRuntime) then
  begin
    LoadStateIntoUi;
    RefreshStatus;
    AppendStatus('PHP settings saved.');
  end;
end;

procedure TMainForm.PhpVersionMenuClick(Sender: TObject);
var
  MenuItem: TMenuItem;
begin
  if not (Sender is TMenuItem) then
    Exit;
  MenuItem := TMenuItem(Sender);
  if (MenuItem.Tag < 0) or (MenuItem.Tag >= PhpVersionCombo.Items.Count) then
    Exit;
  PhpVersionCombo.ItemIndex := MenuItem.Tag;
  SaveConfigClick(Sender);
end;

procedure TMainForm.PhpProfileMenuClick(Sender: TObject);
var
  MenuItem: TMenuItem;
begin
  if not (Sender is TMenuItem) then
    Exit;
  MenuItem := TMenuItem(Sender);
  if (MenuItem.Tag < 0) or (MenuItem.Tag >= PhpProfileCombo.Items.Count) then
    Exit;
  PhpProfileCombo.ItemIndex := MenuItem.Tag;
  SaveConfigClick(Sender);
end;

procedure TMainForm.LaunchTerminalClick(Sender: TObject);
var
  ResultInfo: TRuntimeActionResult;
begin
  SaveUiIntoState;
  FConfig.Save(FPaths);
  ResultInfo := FRuntime.LaunchTerminal;
  AppendStatus(ResultInfo.Message);
end;

procedure TMainForm.GenerateSslClick(Sender: TObject);
var
  ResultInfo: TRuntimeActionResult;
begin
  ResultInfo := FRuntime.GenerateSslCertificate;
  AppendStatus(ResultInfo.Message);
end;

procedure TMainForm.OpenApacheLogClick(Sender: TObject);
begin
  ShellExecute(0, 'open', 'notepad.exe', PChar(TPath.Combine(FPaths.LogsDir, 'apache-error.log')), nil, SW_SHOWNORMAL);
end;

procedure TMainForm.OpenMariaDbLogClick(Sender: TObject);
begin
  ShellExecute(0, 'open', 'notepad.exe', PChar(TPath.Combine(FPaths.LogsDir, 'mariadb-error.log')), nil, SW_SHOWNORMAL);
end;

procedure TMainForm.ClearLogFile(const FileName, DisplayName: string);
begin
  TFile.WriteAllText(FileName, '', TEncoding.UTF8);
  AppendStatus('Cleared ' + DisplayName + '.');
end;

procedure TMainForm.ClearApacheLogClick(Sender: TObject);
begin
  ClearLogFile(TPath.Combine(FPaths.LogsDir, 'apache-error.log'), 'Apache error log');
end;

procedure TMainForm.ClearMariaDbLogClick(Sender: TObject);
begin
  ClearLogFile(TPath.Combine(FPaths.LogsDir, 'mariadb-error.log'), 'MariaDB error log');
end;

procedure TMainForm.ClearActivityLogClick(Sender: TObject);
begin
  ClearLogFile(TPath.Combine(FPaths.LogsDir, 'activity.log'), 'activity log');
end;

procedure TMainForm.OpenActivityClick(Sender: TObject);
begin
  ShellExecute(0, 'open', 'notepad.exe', PChar(TPath.Combine(FPaths.LogsDir, 'activity.log')), nil, SW_SHOWNORMAL);
end;

procedure TMainForm.AddVHostClick(Sender: TObject);
var
  DialogResult: TVHostDialogResult;
  ResultInfo: TRuntimeActionResult;
  RestartInfo: TRuntimeActionResult;
begin
  DialogResult := TVHostDialog.Execute(Self, FPaths.VHostsDir, '', '', '', EnableSslCheck.Checked);
  if not DialogResult.Accepted then
    Exit;
  ResultInfo := FRuntime.AddVHost(DialogResult.ServerName, DialogResult.DocumentRoot,
    DialogResult.ServerAliases, DialogResult.EnableSsl);
  AppendStatus(ResultInfo.Message);
  if ResultInfo.Success and FConfig.ApacheRunning then
  begin
    RestartInfo := FRuntime.RestartApache;
    AppendStatus('Apache reload after VHost add: ' + RestartInfo.Message);
  end;
  FConfig.Save(FPaths);
  RefreshStatus;
  LoadStateIntoUi;
end;

procedure TMainForm.SetMariaDbRootPasswordClick(Sender: TObject);
var
  DialogResult: TPasswordDialogResult;
  ResultInfo: TRuntimeActionResult;
begin
  DialogResult := TPasswordDialog.Execute(Self, 'Set MariaDB Root Password', 'New password');
  if not DialogResult.Accepted then
    Exit;

  ResultInfo := FRuntime.SetMariaDbRootPassword(DialogResult.Password);
  AppendStatus(ResultInfo.Message);
  if ResultInfo.Success then
    FConfig.Save(FPaths);
  RefreshStatus;
end;

procedure TMainForm.DeleteVHostClick(Sender: TObject);
begin
  DeleteVHostByName(SelectedVHostServerName);
end;

procedure TMainForm.OpenVHostClick(Sender: TObject);
begin
  OpenVHostUrl(SelectedVHostServerName);
end;

procedure TMainForm.OpenVHostFolderClick(Sender: TObject);
begin
  OpenVHostFolder(SelectedVHostServerName);
end;

procedure TMainForm.CopyVHostUrlClick(Sender: TObject);
var
  ServerName: string;
begin
  ServerName := SelectedVHostServerName;
  if ServerName = '' then
    Exit;
  Clipboard.AsText := VHostUrl(ServerName);
  AppendStatus('Copied vHost URL: ' + VHostUrl(ServerName));
end;

procedure TMainForm.RefreshVHostSslClick(Sender: TObject);
var
  ServerName: string;
  ResultInfo: TRuntimeActionResult;
  RestartInfo: TRuntimeActionResult;
begin
  ServerName := SelectedVHostServerName;
  if ServerName = '' then
    Exit;

  ResultInfo := FRuntime.RefreshVHostSslCertificate(ServerName);
  AppendStatus(ResultInfo.Message);
  if ResultInfo.Success and FConfig.ApacheRunning then
  begin
    RestartInfo := FRuntime.RestartApache;
    AppendStatus('Apache reload after VHost SSL refresh: ' + RestartInfo.Message);
  end;
  if ResultInfo.Success then
    FConfig.Save(FPaths);
  RefreshStatus;
  LoadStateIntoUi;
end;

procedure TMainForm.ExitButtonClick(Sender: TObject);
begin
  Close;
end;

procedure TMainForm.EditPhpIniClick(Sender: TObject);
begin
  if FileExists(FPaths.ActivePhpIniFile) then
    ShellExecute(0, 'open', 'notepad.exe', PChar(FPaths.ActivePhpIniFile), nil, SW_SHOWNORMAL)
  else
    ShowMessage('Config file not found. Have you saved the configuration?');
end;

procedure TMainForm.EditHttpdConfClick(Sender: TObject);
begin
  if FileExists(FPaths.ApacheHttpdConfFile) then
    ShellExecute(0, 'open', 'notepad.exe', PChar(FPaths.ApacheHttpdConfFile), nil, SW_SHOWNORMAL)
  else
    ShowMessage('Config file not found. Have you saved the configuration?');
end;

procedure TMainForm.EditMariaDbIniClick(Sender: TObject);
begin
  if FileExists(FPaths.MariaDbIniFile) then
    ShellExecute(0, 'open', 'notepad.exe', PChar(FPaths.MariaDbIniFile), nil, SW_SHOWNORMAL)
  else
    ShowMessage('Config file not found. Have you saved the configuration?');
end;

procedure TMainForm.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  FStatusRefreshTimer.Enabled := False;
  SaveUiIntoState;
  try
    CanClose := TShutdownProgressForm.ExecuteShutdown(Self, FRuntime, FConfig, FPaths);
    RefreshStatus;
    FConfig.Save(FPaths);
    if not CanClose then
      ShowMessage('Unable to stop all services cleanly. The application will remain open.');
  finally
    FStatusRefreshTimer.Enabled := True;
  end;
end;

end.
