unit Ui.UniWamp.MainForm;

interface

uses
  Winapi.Windows,
  Winapi.Messages,
  System.Classes,
  System.Generics.Collections,
  System.SysUtils,
  System.Types,
  System.Math,
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
  Vcl.Dialogs,
  Vcl.Clipbrd,
  Vcl.Themes,
  Ui.UniWamp.AboutForm,
  Ui.UniWamp.AppSettingsForm,
  Ui.UniWamp.ScriptManagerForm,
  Core.UniWamp.Config,
  Core.UniWamp.Diagnostics,
  Core.UniWamp.Types,
  Core.UniWamp.Paths,
  Core.UniWamp.Security,
  Core.UniWamp.PackageManager,
  Core.UniWamp.PortUtils,
  Core.UniWamp.VHostManager,
  Core.UniWamp.ProjectBackupService,
  Core.UniWamp.DatabaseBackupService,
  Core.UniWamp.ConfigGenerator,
  Core.UniWamp.HostsFileService,
  Core.UniWamp.Interfaces,
  Core.UniWamp.ServiceLocator,
  Core.UniWamp.Runtime;

type
  TActivityMemo = class(TMemo);

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
    Panel1: TPanel;
    PhpVersionCombo: TComboBox;
    NodeVersionCombo: TComboBox;
    EnableSslCheck: TCheckBox;
    StatusBar: TStatusBar;
    exitbutton: TPanel;
    StartAllButton: TPanel;
    StopAllButton: TPanel;
    Panel2: TPanel;
    pnltools: TPanel;
    GenerateSslButton: TPanel;
    Panel6: TPanel;
    AddVHostButton: TPanel;
    OpenVHostButton: TPanel;
    OpenVHostFolderButton: TPanel;
    OpenVHostTerminalButton: TPanel;
    BackupProjectButton: TPanel;
    RestoreProjectButton: TPanel;
    CopyVHostUrlButton: TPanel;
    DeleteVHostButton: TPanel;
    ActivityLogSplitter: TSplitter;
    Panel7: TPanel;
    Panel4: TPanel;
    OpenApacheLogButton: TPanel;
    OpenMariaLogButton: TPanel;
    ClearApacheLogButton: TPanel;
    ClearMariaLogButton: TPanel;
    Label20: TPanel;
    ClearActivityLogButton: TPanel;
    SaveConfigButton: TPanel;
    LaunchTerminalButton: TPanel;
    FActivityCard: TPanel;
    FActivityLabel: TPanel;
    Label11: TPanel;
    Panel8: TPanel;
    Panel9: TPanel;
    Panel10: TPanel;
    Panel11: TPanel;
    Panel13: TPanel;
    CopyDiagnosticReportButton: TPanel;
    CopyActivityLogButton: TPanel;
    OpenHostsFileButton: TPanel;
    BackupDatabaseButton: TPanel;
    RestoreDatabaseButton: TPanel;
    ToolGroupWebLabel: TPanel;
    ToolGroupRuntimeLabel: TPanel;
    ToolGroupLogsLabel: TPanel;
    ToolGroupMaintenanceLabel: TPanel;
    OpenPhpExtensionsButton: TPanel;
    OpenPhpSettingsButton: TPanel;
    OpenApacheModulesButton: TPanel;
    Label1: TLabel;
    Label2: TLabel;
    OpenRepoTerminalButton: TPanel;
    ComposerButton: TPanel;
    GitButton: TPanel;
    NodeButton: TPanel;
    WpCliButton: TPanel;
    MailpitButton: TPanel;
    RedisButton: TPanel;
    MemcachedButton: TPanel;
    NpmButton: TPanel;
    YarnButton: TPanel;
    PnpmButton: TPanel;
    EditorButton: TPanel;
    UpdateButton: TPanel;
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
    FMainStartAllOnLaunchItem: TMenuItem;
    FTrayStartAllOnLaunchItem: TMenuItem;
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
    FStartupActionExecuted: Boolean;
    FActivityMemo: TMemo;
    FVHostEmptyLabel: TLabel;
    FVHostHeaderTitle: TLabel;
    FVHostFilterLabel: TLabel;
    FVHostFilterEdit: TEdit;
    FVHostFilterClearLabel: TLabel;
    FUpdateManifestDialog: TOpenDialog;
    FProjectBackupManifestDialog: TOpenDialog;
    FDatabaseBackupInfoDialog: TOpenDialog;
    FHeaderCards: array[0..2] of THeaderStatusCard;
    FProgressSpinner: TProgressBar;
    FIsBusy: Boolean;
    procedure ShowBusyState(const StatusText: string);
    procedure HideBusyState(const StatusText: string = '');
    procedure FormCreate(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure BuildMenus;
    procedure AboutClick(Sender: TObject);
    procedure ScriptsClick(Sender: TObject);
    function IconFileName(const IconName: string): string;
    function LoadIconGraphic(const IconName: string): TPngImage;
    function LoadTintedIconBitmap(const IconName: string; const IconColor: TColor;
      const IconSize: Integer = 24): TBitmap;
    function GetButtonTextLabel(Button: TPanel): TLabel;
    procedure SetButtonCaption(Button: TPanel; const CaptionText: string);
    procedure UpdateButtonIcons(Button: TPanel; const IconColor: TColor);
    procedure ApplyPanelIcon(Button: TPanel; const IconName: string; const IconSize: Integer = 14);
    procedure ClearPanelIcon(Button: TPanel);
    procedure ApplyMenuIcon(Item: TMenuItem; const IconName: string);
    procedure DrawIconInRect(Canvas: TCanvas; const IconName: string; const Bounds: TRect;
      const IconSize: Integer);
    procedure CreateHeaderStatusCards;
    procedure LayoutDashboard;
    procedure LayoutToolSidebar;
    procedure PhpVersionMenuClick(Sender: TObject);
    procedure PhpProfileMenuClick(Sender: TObject);
    procedure LoadStateIntoUi;
    function SaveUiIntoState: Boolean;
    procedure AppendStatus(const Text: string);
    procedure RefreshStatus;
    procedure UpdateHeaderStateColors;
    procedure UpdateHeaderStatusCards;
    procedure UpdateServiceButtonState;
    procedure UpdateDashboardLabels;
    procedure UpdatePortConflictLabels;
    procedure UpdateStackActionState;
    procedure UpdateVHostActionState;
    procedure UpdateMenuState;
    procedure UpdateVHostEmptyState;
    procedure LaunchDashboardIfHealthy;
    function IsAutoStartEnabled: Boolean;
    procedure SetAutoStartEnabled(const Enabled: Boolean);
    procedure StartAllOnLaunchClick(Sender: TObject);
    procedure StatusRefreshTimer(Sender: TObject);
    procedure AutoStartClick(Sender: TObject);
    procedure RefreshActivityLogView;
    procedure VHostFilterChanged(Sender: TObject);
    procedure VHostFilterClearClick(Sender: TObject);
    procedure VHostGridEnter(Sender: TObject);
    procedure VHostGridExit(Sender: TObject);
    function TryGetVHostEntry(const ServerName: string; out Entry: TVHostEntry): Boolean;
    procedure ToggleMainWindow;
    function VHostUrl(const ServerName: string): string;
    function SelectedVHostServerName: string;
    procedure DeleteVHostByName(const ServerName: string);
    procedure OpenVHostFolder(const ServerName: string);
    procedure OpenVHostEditor(const ServerName: string);
    procedure OpenVHostUrl(const ServerName: string);
    procedure VHostGridDrawCell(Sender: TObject; ACol, ARow: Integer; CellRect: TRect; State: TGridDrawState);
    procedure VHostGridMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure VHostGridKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
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
  procedure LaunchAdminerClick(Sender: TObject);
    procedure CopyDiagnosticReportClick(Sender: TObject);
    procedure CopyActivityLogClick(Sender: TObject);
    procedure OpenHostsFileClick(Sender: TObject);
    procedure OpenPhpExtensionsClick(Sender: TObject);
    procedure OpenPhpSettingsClick(Sender: TObject);
    procedure OpenAppSettingsClick(Sender: TObject);
    procedure OpenApacheModulesClick(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure VHostEmptyLabelClick(Sender: TObject);
    procedure VHostFilterKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure SetMariaDbRootPasswordClick(Sender: TObject);
    procedure LaunchTerminalClick(Sender: TObject);
    procedure OpenRepoTerminalClick(Sender: TObject);
    procedure LaunchComposerClick(Sender: TObject);
    procedure LaunchGitClick(Sender: TObject);
    procedure LaunchNodeClick(Sender: TObject);
    procedure LaunchWpCliClick(Sender: TObject);
    procedure LaunchMailpitClick(Sender: TObject);
    procedure LaunchRedisClick(Sender: TObject);
    procedure LaunchMemcachedClick(Sender: TObject);
    procedure LaunchNpmClick(Sender: TObject);
    procedure LaunchYarnClick(Sender: TObject);
    procedure LaunchPnpmClick(Sender: TObject);
    procedure LaunchEditorClick(Sender: TObject);
    procedure StageUpdateClick(Sender: TObject);
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
    procedure OpenVHostTerminalClick(Sender: TObject);
    procedure BackupProjectClick(Sender: TObject);
    procedure RestoreProjectClick(Sender: TObject);
    procedure BackupDatabaseClick(Sender: TObject);
    procedure RestoreDatabaseClick(Sender: TObject);
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

function BuildVHostEmptyStateCaption(const FilterText: string): string;
function DetectProjectTypeLabel(const DocumentRoot: string): string;
function BuildToolPanelHint(const ActionName, DetailText: string): string;
function BuildStatusBarHint(const ErrorMessage: string): string;
function BuildHeaderSubtitleHint: string;
function BuildHeaderCardHint(const TitleText, PrimaryText, SecondaryText: string): string;
function BuildHeaderTitleHint: string;
function BuildHeaderOverviewHint: string;
function DescribeVHostGridKeyboardAction(Key: Word; Shift: TShiftState): string;
function DescribeVHostFilterKeyAction(Key: Word; FilterText: string): string;
procedure ApplyConfiguredTheme(const StyleName: string);

var
  MainForm: TMainForm;

implementation

uses
  Winapi.ShellAPI,
  System.IOUtils,
  System.JSON,
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

function BuildVHostEmptyStateCaption(const FilterText: string): string;
begin
  if Trim(FilterText) <> '' then
    Result := 'No vHosts match the current filter.' + sLineBreak + 'Clear the filter or create a new project.'
  else
    Result := 'No projects or vHosts found.' + sLineBreak + 'Press Ctrl+F to search or Add to create your first project.';
end;

function DetectProjectTypeLabel(const DocumentRoot: string): string;
begin
  if FileExists(TPath.Combine(DocumentRoot, 'wp-config.php')) then
    Exit('WordPress');
  if FileExists(TPath.Combine(DocumentRoot, 'artisan')) then
    Exit('Laravel');
  if FileExists(TPath.Combine(DocumentRoot, 'package.json')) then
    Exit('Node');
  if FileExists(TPath.Combine(DocumentRoot, 'composer.json')) then
    Exit('PHP');
  Result := 'Static';
end;

function BuildToolPanelHint(const ActionName, DetailText: string): string;
begin
  Result := ActionName;
  if Trim(DetailText) <> '' then
    Result := Result + sLineBreak + DetailText;
end;

function BuildStatusBarHint(const ErrorMessage: string): string;
begin
  Result := 'Status summary';
  if Trim(ErrorMessage) <> '' then
    Result := Result + sLineBreak + 'Service requires attention: ' + Trim(ErrorMessage);
end;

function BuildHeaderSubtitleHint: string;
begin
  Result := 'Stack overview' + sLineBreak + 'Shows the current local development dashboard summary.';
end;

function BuildHeaderCardHint(const TitleText, PrimaryText, SecondaryText: string): string;
begin
  Result := TitleText;
  if Trim(PrimaryText) <> '' then
    Result := Result + sLineBreak + PrimaryText;
  if Trim(SecondaryText) <> '' then
    Result := Result + sLineBreak + SecondaryText;
end;

function BuildHeaderTitleHint: string;
begin
  Result := 'UniWamp' + sLineBreak + 'Portable WAMP dashboard for local development.';
end;

function BuildHeaderOverviewHint: string;
begin
  Result := 'Header overview' + sLineBreak + 'Shows Apache, PHP, and MariaDB status at a glance.';
end;

procedure ApplyConfiguredTheme(const StyleName: string);
begin
  if Trim(StyleName) = '' then
    TStyleManager.SetStyle('Windows')
  else
  begin
    try
      TStyleManager.TrySetStyle(StyleName);
    except
      TStyleManager.SetStyle('Windows');
    end;
  end;
end;

function DescribeVHostGridKeyboardAction(Key: Word; Shift: TShiftState): string;
begin
  Result := '';
  if Key = VK_RETURN then
  begin
    Result := 'open';
    Exit;
  end;
  if (Key = Ord('O')) and (ssCtrl in Shift) then
  begin
    Result := 'folder';
    Exit;
  end;
  if (Key = Ord('T')) and (ssCtrl in Shift) then
  begin
    Result := 'terminal';
    Exit;
  end;
  if (Key = Ord('C')) and (ssCtrl in Shift) and (ssShift in Shift) then
  begin
    Result := 'copy';
    Exit;
  end;
  if Key = VK_DELETE then
  begin
    Result := 'delete';
    Exit;
  end;
end;

function DescribeVHostFilterKeyAction(Key: Word; FilterText: string): string;
begin
  Result := '';
  if Key = VK_ESCAPE then
  begin
    if Trim(FilterText) <> '' then
      Result := 'clear'
    else
      Result := 'exit';
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

function ResolveIconDirectory(const RootDir: string): string;
var
  Candidate: string;
begin
  Result := '';
  Candidate := TPath.Combine(TPath.Combine(RootDir, 'src'), 'assets');
  Candidate := TPath.Combine(Candidate, 'icons');
  if TDirectory.Exists(Candidate) then
    Exit(Candidate);

  Candidate := TPath.Combine(TPath.Combine(RootDir, 'assets'), 'icons');
  if TDirectory.Exists(Candidate) then
    Exit(Candidate);
end;

function TryLoadPngFromResource(const ResourceName: string; out Png: TPngImage): Boolean;
var
  Stream: TResourceStream;
begin
  Result := False;
  Png := nil;
  if FindResource(HInstance, PChar(ResourceName), RT_RCDATA) = 0 then
    Exit;

  Stream := TResourceStream.Create(HInstance, ResourceName, RT_RCDATA);
  try
    Png := TPngImage.Create;
    Png.LoadFromStream(Stream);
    Result := True;
  except
    FreeAndNil(Png);
    Result := False;
  end;
  Stream.Free;
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
  if (FIconDir = '') or not TDirectory.Exists(FIconDir) then
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

  if TryLoadPngFromResource('ICON_' + IconName, Result) then
  begin
    FIconCache.Add(IconName, Result);
    Exit;
  end;

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
  Button.Alignment := taCenter;
  TextLabel := GetButtonTextLabel(Button);
  if Assigned(TextLabel) then
  begin
    TextLabel.Alignment := taCenter;
    TextLabel.Caption := CaptionText
  end
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
    TextLabel.Cursor := Button.Cursor;
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
  IconImage.Cursor := Button.Cursor;
  IconImage.OnClick := Button.OnClick;
  if Assigned(TextLabel) then
    TextLabel.OnClick := Button.OnClick;
  if IsDarkColor(Button.Color) then
    IconImage.Picture.Bitmap.Assign(LoadTintedIconBitmap(IconName, clWhite, IconSize))
  else
    IconImage.Picture.Bitmap.Assign(LoadTintedIconBitmap(IconName, $00333333, IconSize));
  IconImage.SendToBack;
end;

procedure TMainForm.ClearPanelIcon(Button: TPanel);
var
  I: Integer;
  Child: TControl;
begin
  if not Assigned(Button) then
    Exit;

  for I := Button.ControlCount - 1 downto 0 do
  begin
    Child := Button.Controls[I];
    if Child is TImage then
      Child.Free
    else if Child is TLabel then
      Child.Free;
  end;
  Button.Tag := 0;
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

procedure TMainForm.AboutClick(Sender: TObject);
begin
  TAboutForm.Execute(Self);
end;

procedure TMainForm.ScriptsClick(Sender: TObject);
begin
  TScriptManagerForm.Execute(Self, FPaths);
  FConfig.LoadOrCreate(FPaths);
  LoadStateIntoUi;
  RefreshStatus;
end;

constructor TMainForm.Create(AOwner: TComponent);
var
  PathsMigrated: Boolean;
begin
  inherited Create(AOwner);
  OnCreate := FormCreate;
  OnShow := FormShow;
  Caption := 'UniWamp';
//  Width := 1450;
//  Height := 1020;
  WindowState := wsMaximized;
  Constraints.MinWidth := 1200;
  Constraints.MinHeight := 800;
  Position := poScreenCenter;
  FPaths := TAppPaths.Detect;
  EnsurePortableLayout(FPaths);
  FIconDir := ResolveIconDirectory(FPaths.AppRoot);
  FIconCache := TObjectDictionary<string, TPngImage>.Create([doOwnsValues]);
  FMenuIconIndices := TDictionary<string, Integer>.Create;
  FConfig := TUniWampConfig.Create;
  FRuntime := TUniWampRuntime.Create(FPaths, FConfig);
  FUpdateManifestDialog := TOpenDialog.Create(Self);
  FUpdateManifestDialog.Filter := 'Update manifest (*.json)|*.json|All files (*.*)|*.*';
  FUpdateManifestDialog.Title := 'Select update manifest';
  FUpdateManifestDialog.Options := [ofFileMustExist, ofPathMustExist, ofEnableSizing, ofHideReadOnly];
  FProjectBackupManifestDialog := TOpenDialog.Create(Self);
  FProjectBackupManifestDialog.Filter := 'Project backup manifest (backup.json)|backup.json|JSON files (*.json)|*.json|All files (*.*)|*.*';
  FProjectBackupManifestDialog.Title := 'Select project backup manifest';
  FProjectBackupManifestDialog.Options := [ofFileMustExist, ofPathMustExist, ofEnableSizing, ofHideReadOnly];
  FDatabaseBackupInfoDialog := TOpenDialog.Create(Self);
  FDatabaseBackupInfoDialog.Filter := 'Database backup info (backup.txt)|backup.txt|Text files (*.txt)|*.txt|All files (*.*)|*.*';
  FDatabaseBackupInfoDialog.Title := 'Select database backup info';
  FDatabaseBackupInfoDialog.Options := [ofFileMustExist, ofPathMustExist, ofEnableSizing, ofHideReadOnly];
  PathsMigrated := FConfig.LoadOrCreate(FPaths);
  ApplyConfiguredTheme(FConfig.ThemeStyleName);

  TServiceLocator.Instance.RegisterService<IConfigurationGenerator>(TConfigurationGenerator.Create(FPaths, FConfig));
  TServiceLocator.Instance.RegisterService<IHostsFileService>(THostsFileService.Create(FPaths, FConfig));
  TServiceLocator.Instance.RegisterService<IVHostManager>(TVHostManager.Create(FPaths, FConfig));
  TServiceLocator.Instance.RegisterService<IProjectBackupService>(TProjectBackupService.Create(FPaths, FConfig));
  TServiceLocator.Instance.RegisterService<IDatabaseBackupService>(TDatabaseBackupService.Create(FPaths, FConfig));

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
  LayoutToolSidebar;
  FStatusRefreshTimer := TTimer.Create(Self);
  FStatusRefreshTimer.Interval := 4000;
  FStatusRefreshTimer.OnTimer := StatusRefreshTimer;
  FStatusRefreshTimer.Enabled := True;
end;

procedure TMainForm.FormCreate(Sender: TObject);
begin
  DoubleBuffered := True;
  KeyPreview := True;
  Color := AppBackgroundColor;
  OnResize := FormResize;
  OnKeyDown := FormKeyDown;
  HeaderPanel.DoubleBuffered := True;
  MainPanel.DoubleBuffered := True;
  LeftPanel.DoubleBuffered := True;
  RightPanel.DoubleBuffered := True;
  HeaderPanel.Hint := BuildHeaderOverviewHint;
  HeaderPanel.ShowHint := True;
  StatusBar.Color := RGB(248, 250, 252);
  StatusBar.Font.Color := RGB(55, 65, 81);
  HeaderPanel.Color := HeaderOfflineColor;
  Label18.Color := HeaderOfflineColor;
  Label19.Color := HeaderOfflineColor;
  Label18.Visible := true;
  Label18.Hint := BuildHeaderTitleHint;
  Label18.ShowHint := True;
  Label19.Alignment := taLeftJustify;
  Label19.Font.Color := HeaderSubTextColor;
  Label19.Caption := 'Portable WAMP dashboard for local development';
  Label19.Hint := BuildHeaderSubtitleHint;
  Label19.ShowHint := True;
  MainPanel.Color := AppBackgroundColor;
  LeftPanel.Color := AppBackgroundColor;
  RightPanel.Color := AppBackgroundColor;
  pnltools.Parent := MainPanel;
  pnltools.Align := alRight;
  pnltools.Width := 190;
  pnltools.Height := MainPanel.ClientHeight;
  pnltools.BringToFront;
  HeaderPanel.Height := 86;
  CreateHeaderStatusCards;
  FVHostEmptyLabel := TLabel.Create(Self);
  FVHostEmptyLabel.Parent := VHostCard;
  FVHostEmptyLabel.Align := alClient;
  FVHostEmptyLabel.Alignment := taCenter;
  FVHostEmptyLabel.Layout := tlCenter;
  FVHostEmptyLabel.WordWrap := True;
  FVHostEmptyLabel.Transparent := True;
  FVHostEmptyLabel.Font.Name := 'Segoe UI';
  FVHostEmptyLabel.Font.Size := 11;
  FVHostEmptyLabel.Font.Color := clGrayText;
  FVHostEmptyLabel.Font.Style := [fsBold];
  FVHostEmptyLabel.Caption := 'No projects or vHosts found.' + sLineBreak + 'Use Add to create your first project.';
  FVHostEmptyLabel.Hint := 'Click Add to create a new project or vHost. Press Ctrl+F to search existing projects.';
  FVHostEmptyLabel.ShowHint := True;
  FVHostEmptyLabel.Cursor := crHandPoint;
  FVHostEmptyLabel.OnClick := VHostEmptyLabelClick;
  FVHostEmptyLabel.Visible := False;
  FVHostHeaderTitle := TLabel.Create(Self);
  FVHostHeaderTitle.Parent := Label11;
  FVHostHeaderTitle.Left := 12;
  FVHostHeaderTitle.Top := 9;
  FVHostHeaderTitle.Caption := 'Virtual hosts';
  FVHostHeaderTitle.Font.Name := 'Segoe UI';
  FVHostHeaderTitle.Font.Size := 9;
  FVHostHeaderTitle.Font.Style := [fsBold];
  FVHostHeaderTitle.Transparent := True;
  FVHostFilterLabel := TLabel.Create(Self);
  FVHostFilterLabel.Parent := Label11;
  FVHostFilterLabel.Caption := 'Filter';
  FVHostFilterLabel.Font.Name := 'Segoe UI';
  FVHostFilterLabel.Font.Size := 9;
  FVHostFilterLabel.Font.Style := [fsBold];
  FVHostFilterLabel.Transparent := True;
  FVHostFilterEdit := TEdit.Create(Self);
  FVHostFilterEdit.Parent := Label11;
  FVHostFilterEdit.TextHint := 'Search site, path, or alias';
  FVHostFilterEdit.Hint := BuildToolPanelHint('Filter vHosts',
    'Search by site name, document root, or aliases. Press Esc to clear.');
  FVHostFilterEdit.ShowHint := True;
  FVHostFilterEdit.OnChange := VHostFilterChanged;
  FVHostFilterEdit.OnKeyDown := VHostFilterKeyDown;
  FVHostFilterClearLabel := TLabel.Create(Self);
  FVHostFilterClearLabel.Parent := Label11;
  FVHostFilterClearLabel.Caption := 'Clear';
  FVHostFilterClearLabel.Cursor := crHandPoint;
  FVHostFilterClearLabel.Font.Name := 'Segoe UI';
  FVHostFilterClearLabel.Font.Size := 9;
  FVHostFilterClearLabel.Font.Color := clBlue;
  FVHostFilterClearLabel.Font.Style := [fsUnderline];
  FVHostFilterClearLabel.Transparent := True;
  FVHostFilterClearLabel.Hint := BuildToolPanelHint('Clear the vHost filter',
    'Shows all projects and vHosts again.');
  FVHostFilterClearLabel.ShowHint := True;
  FVHostFilterClearLabel.OnClick := VHostFilterClearClick;
  Label11.Caption := '';
  Label11.Height := 34;
  Label11.Alignment := taLeftJustify;
  ToolGroupWebLabel := TPanel.Create(Self);
  ToolGroupWebLabel.Parent := pnltools;
  ToolGroupWebLabel.BevelOuter := bvNone;
  ToolGroupWebLabel.Caption := 'Web and config';
  ToolGroupWebLabel.Color := RGB(232, 236, 243);
  ToolGroupWebLabel.Font.Name := 'Segoe UI';
  ToolGroupWebLabel.Font.Size := 9;
  ToolGroupWebLabel.Font.Style := [fsBold];
  ToolGroupWebLabel.Font.Color := RGB(30, 64, 175);
  ToolGroupWebLabel.ParentBackground := False;
  ToolGroupWebLabel.ParentFont := False;
  ToolGroupWebLabel.Alignment := taLeftJustify;
  ToolGroupWebLabel.Font.Size := 8;
  ToolGroupRuntimeLabel := TPanel.Create(Self);
  ToolGroupRuntimeLabel.Parent := pnltools;
  ToolGroupRuntimeLabel.BevelOuter := bvNone;
  ToolGroupRuntimeLabel.Caption := 'Runtime tools';
  ToolGroupRuntimeLabel.Color := RGB(232, 236, 243);
  ToolGroupRuntimeLabel.Font.Name := 'Segoe UI';
  ToolGroupRuntimeLabel.Font.Size := 9;
  ToolGroupRuntimeLabel.Font.Style := [fsBold];
  ToolGroupRuntimeLabel.Font.Color := RGB(31, 95, 73);
  ToolGroupRuntimeLabel.ParentBackground := False;
  ToolGroupRuntimeLabel.ParentFont := False;
  ToolGroupRuntimeLabel.Alignment := taLeftJustify;
  ToolGroupRuntimeLabel.Font.Size := 8;
  ToolGroupLogsLabel := TPanel.Create(Self);
  ToolGroupLogsLabel.Parent := pnltools;
  ToolGroupLogsLabel.BevelOuter := bvNone;
  ToolGroupLogsLabel.Caption := 'Logs';
  ToolGroupLogsLabel.Color := RGB(232, 236, 243);
  ToolGroupLogsLabel.Font.Name := 'Segoe UI';
  ToolGroupLogsLabel.Font.Size := 9;
  ToolGroupLogsLabel.Font.Style := [fsBold];
  ToolGroupLogsLabel.Font.Color := RGB(180, 83, 9);
  ToolGroupLogsLabel.ParentBackground := False;
  ToolGroupLogsLabel.ParentFont := False;
  ToolGroupLogsLabel.Alignment := taLeftJustify;
  ToolGroupLogsLabel.Font.Size := 8;
  ToolGroupMaintenanceLabel := TPanel.Create(Self);
  ToolGroupMaintenanceLabel.Parent := pnltools;
  ToolGroupMaintenanceLabel.BevelOuter := bvNone;
  ToolGroupMaintenanceLabel.Caption := 'Maintenance';
  ToolGroupMaintenanceLabel.Color := RGB(232, 236, 243);
  ToolGroupMaintenanceLabel.Font.Name := 'Segoe UI';
  ToolGroupMaintenanceLabel.Font.Size := 9;
  ToolGroupMaintenanceLabel.Font.Style := [fsBold];
  ToolGroupMaintenanceLabel.Font.Color := RGB(107, 33, 168);
  ToolGroupMaintenanceLabel.ParentBackground := False;
  ToolGroupMaintenanceLabel.ParentFont := False;
  ToolGroupMaintenanceLabel.Alignment := taLeftJustify;
  ToolGroupMaintenanceLabel.Font.Size := 8;
  OpenApacheLogButton.Parent := pnltools;
  OpenMariaLogButton.Parent := pnltools;
  ClearApacheLogButton.Parent := pnltools;
  ClearMariaLogButton.Parent := pnltools;
  ClearActivityLogButton.Parent := pnltools;
  Panel4.Visible := False;
  ActivityLogSplitter.Align := alBottom;
  ActivityLogSplitter.Height := 6;
  ActivityLogSplitter.MinSize := 80;
  ActivityLogSplitter.Cursor := crVSplit;
  ActivityLogSplitter.Color := RGB(232, 236, 243);
  Panel7.Align := alBottom;
  Panel7.Height := 96;
  Panel7.Constraints.MinHeight := 80;
  FActivityCard.Align := alClient;
  FActivityCard.Left := 0;
  FActivityCard.Width := Panel7.ClientWidth;
  FActivityMemo := TMemo.Create(Self);
  FActivityMemo.Parent := FActivityCard;
  FActivityMemo.Align := alClient;
  FActivityMemo.AlignWithMargins := True;
  FActivityMemo.Margins.Left := 8;
  FActivityMemo.Margins.Top := 24;
  FActivityMemo.Margins.Right := 8;
  FActivityMemo.Margins.Bottom := 8;
  FActivityMemo.BorderStyle := bsNone;
  FActivityMemo.Color := clWhite;
  FActivityMemo.Font.Name := 'Segoe UI';
  FActivityMemo.Font.Size := 10;
  FActivityMemo.ReadOnly := True;
  FActivityMemo.ScrollBars := ssVertical;
  FActivityMemo.WordWrap := False;
  FActivityLabel.BringToFront;
  ApacheStartButton.OnClick := ApacheStartClick;
  ApacheStopButton.OnClick := ApacheStopClick;
  ApacheRestartButton.OnClick := ApacheRestartClick;
  MariaStartButton.OnClick := MariaDbStartClick;
  MariaStopButton.OnClick := MariaDbStopClick;
  MariaRestartButton.OnClick := MariaDbRestartClick;
  StartAllButton.OnClick := StartButtonClick;
  LaunchTerminalButton.OnClick := LaunchTerminalClick;
  LaunchTerminalButton.Hint := BuildToolPanelHint('Open the terminal in the UniWamp document root',
    'Uses Cmder when available, otherwise falls back to cmd.exe.');
  LaunchTerminalButton.ShowHint := True;
  OpenRepoTerminalButton.OnClick := OpenRepoTerminalClick;
  OpenRepoTerminalButton.Hint := BuildToolPanelHint('Open the terminal in the UniWamp repository root',
    'Launches the configured terminal in the application root for Git and maintenance tasks.');
  OpenRepoTerminalButton.ShowHint := True;
  ComposerButton := TPanel.Create(Self);
  ComposerButton.Parent := pnltools;
  ComposerButton.SetBounds(370, 41, 92, 24);
  ComposerButton.Cursor := crHandPoint;
  ComposerButton.BevelOuter := bvNone;
  ComposerButton.Caption := 'Composer';
  ComposerButton.Color := 16053492;
  ComposerButton.Font.Charset := DEFAULT_CHARSET;
  ComposerButton.Font.Color := clWindowText;
  ComposerButton.Font.Height := -11;
  ComposerButton.Font.Name := 'Segoe UI';
  ComposerButton.Font.Style := [fsBold];
  ComposerButton.ParentBackground := False;
  ComposerButton.ParentFont := False;
  ComposerButton.TabOrder := 6;
  ComposerButton.OnClick := LaunchComposerClick;
  ComposerButton.Hint := BuildToolPanelHint('Launch Composer from the UniWamp repository root',
    'Opens bundled composer.phar in the application root using the selected PHP runtime or php.exe on PATH.');
  ComposerButton.ShowHint := True;
  GitButton := TPanel.Create(Self);
  GitButton.Parent := pnltools;
  GitButton.SetBounds(472, 41, 74, 24);
  GitButton.Cursor := crHandPoint;
  GitButton.BevelOuter := bvNone;
  GitButton.Caption := 'Git';
  GitButton.Color := 16053492;
  GitButton.Font.Charset := DEFAULT_CHARSET;
  GitButton.Font.Color := clWindowText;
  GitButton.Font.Height := -11;
  GitButton.Font.Name := 'Segoe UI';
  GitButton.Font.Style := [fsBold];
  GitButton.ParentBackground := False;
  GitButton.ParentFont := False;
  GitButton.TabOrder := 7;
  GitButton.OnClick := LaunchGitClick;
  GitButton.Hint := BuildToolPanelHint('Launch Git from the UniWamp repository root',
    'Opens Git in the application root when git.exe is available on PATH.');
  GitButton.ShowHint := True;
  NodeButton := TPanel.Create(Self);
  NodeButton.Parent := pnltools;
  NodeButton.SetBounds(554, 41, 84, 24);
  NodeButton.Cursor := crHandPoint;
  NodeButton.BevelOuter := bvNone;
  NodeButton.Caption := 'Node';
  NodeButton.Color := 16053492;
  NodeButton.Font.Charset := DEFAULT_CHARSET;
  NodeButton.Font.Color := clWindowText;
  NodeButton.Font.Height := -11;
  NodeButton.Font.Name := 'Segoe UI';
  NodeButton.Font.Style := [fsBold];
  NodeButton.ParentBackground := False;
  NodeButton.ParentFont := False;
  NodeButton.TabOrder := 8;
  NodeButton.OnClick := LaunchNodeClick;
  NodeButton.Hint := BuildToolPanelHint('Launch Node from the selected runtime version',
    'Opens node.exe from the currently selected Node.js runtime in the repository root.');
  NodeButton.ShowHint := True;
  WpCliButton := TPanel.Create(Self);
  WpCliButton.Parent := pnltools;
  WpCliButton.SetBounds(644, 41, 84, 24);
  WpCliButton.Cursor := crHandPoint;
  WpCliButton.BevelOuter := bvNone;
  WpCliButton.Caption := 'WP-CLI';
  WpCliButton.Color := 16053492;
  WpCliButton.Font.Charset := DEFAULT_CHARSET;
  WpCliButton.Font.Color := clWindowText;
  WpCliButton.Font.Height := -11;
  WpCliButton.Font.Name := 'Segoe UI';
  WpCliButton.Font.Style := [fsBold];
  WpCliButton.ParentBackground := False;
  WpCliButton.ParentFont := False;
  WpCliButton.TabOrder := 9;
  WpCliButton.OnClick := LaunchWpCliClick;
  WpCliButton.Hint := BuildToolPanelHint('Launch WP-CLI from the selected document root',
    'Opens bundled wp-cli.phar in the application root using the selected PHP runtime or php.exe on PATH.');
  WpCliButton.ShowHint := True;
  MailpitButton := TPanel.Create(Self);
  MailpitButton.Parent := pnltools;
  MailpitButton.SetBounds(734, 41, 92, 24);
  MailpitButton.Cursor := crHandPoint;
  MailpitButton.BevelOuter := bvNone;
  MailpitButton.Caption := 'Mailpit';
  MailpitButton.Color := 16053492;
  MailpitButton.Font.Charset := DEFAULT_CHARSET;
  MailpitButton.Font.Color := clWindowText;
  MailpitButton.Font.Height := -11;
  MailpitButton.Font.Name := 'Segoe UI';
  MailpitButton.Font.Style := [fsBold];
  MailpitButton.ParentBackground := False;
  MailpitButton.ParentFont := False;
  MailpitButton.TabOrder := 10;
  MailpitButton.OnClick := LaunchMailpitClick;
  MailpitButton.Hint := BuildToolPanelHint('Launch Mailpit from the UniWamp application root',
    'Opens Mailpit when mailpit.exe is available on PATH.');
  MailpitButton.ShowHint := True;
  RedisButton := TPanel.Create(Self);
  RedisButton.Parent := pnltools;
  RedisButton.SetBounds(10, 73, 84, 24);
  RedisButton.Cursor := crHandPoint;
  RedisButton.BevelOuter := bvNone;
  RedisButton.Caption := 'Redis';
  RedisButton.Color := 16053492;
  RedisButton.Font.Charset := DEFAULT_CHARSET;
  RedisButton.Font.Color := clWindowText;
  RedisButton.Font.Height := -11;
  RedisButton.Font.Name := 'Segoe UI';
  RedisButton.Font.Style := [fsBold];
  RedisButton.ParentBackground := False;
  RedisButton.ParentFont := False;
  RedisButton.TabOrder := 11;
  RedisButton.OnClick := LaunchRedisClick;
  RedisButton.Hint := BuildToolPanelHint('Launch Redis from the UniWamp application root',
    'Opens redis-server.exe when available on PATH.');
  RedisButton.ShowHint := True;
  MemcachedButton := TPanel.Create(Self);
  MemcachedButton.Parent := pnltools;
  MemcachedButton.SetBounds(100, 73, 100, 24);
  MemcachedButton.Cursor := crHandPoint;
  MemcachedButton.BevelOuter := bvNone;
  MemcachedButton.Caption := 'Memcached';
  MemcachedButton.Color := 16053492;
  MemcachedButton.Font.Charset := DEFAULT_CHARSET;
  MemcachedButton.Font.Color := clWindowText;
  MemcachedButton.Font.Height := -11;
  MemcachedButton.Font.Name := 'Segoe UI';
  MemcachedButton.Font.Style := [fsBold];
  MemcachedButton.ParentBackground := False;
  MemcachedButton.ParentFont := False;
  MemcachedButton.TabOrder := 12;
  MemcachedButton.OnClick := LaunchMemcachedClick;
  MemcachedButton.Hint := BuildToolPanelHint('Launch Memcached from the UniWamp application root',
    'Opens memcached.exe when available on PATH.');
  MemcachedButton.ShowHint := True;
  NpmButton := TPanel.Create(Self);
  NpmButton.Parent := pnltools;
  NpmButton.SetBounds(206, 73, 72, 24);
  NpmButton.Cursor := crHandPoint;
  NpmButton.BevelOuter := bvNone;
  NpmButton.Caption := 'npm';
  NpmButton.Color := 16053492;
  NpmButton.Font.Charset := DEFAULT_CHARSET;
  NpmButton.Font.Color := clWindowText;
  NpmButton.Font.Height := -11;
  NpmButton.Font.Name := 'Segoe UI';
  NpmButton.Font.Style := [fsBold];
  NpmButton.ParentBackground := False;
  NpmButton.ParentFont := False;
  NpmButton.TabOrder := 13;
  NpmButton.OnClick := LaunchNpmClick;
  NpmButton.Hint := BuildToolPanelHint('Launch npm from the selected Node.js runtime',
    'Opens bundled npm.cmd from the selected Node.js runtime or npm.cmd from PATH in the UniWamp application root.');
  NpmButton.ShowHint := True;
  YarnButton := TPanel.Create(Self);
  YarnButton.Parent := pnltools;
  YarnButton.SetBounds(284, 73, 78, 24);
  YarnButton.Cursor := crHandPoint;
  YarnButton.BevelOuter := bvNone;
  YarnButton.Caption := 'yarn';
  YarnButton.Color := 16053492;
  YarnButton.Font.Charset := DEFAULT_CHARSET;
  YarnButton.Font.Color := clWindowText;
  YarnButton.Font.Height := -11;
  YarnButton.Font.Name := 'Segoe UI';
  YarnButton.Font.Style := [fsBold];
  YarnButton.ParentBackground := False;
  YarnButton.ParentFont := False;
  YarnButton.TabOrder := 14;
  YarnButton.OnClick := LaunchYarnClick;
  YarnButton.Hint := BuildToolPanelHint('Launch yarn from the selected Node.js runtime',
    'Opens bundled yarn.cmd or yarnpkg.cmd from the selected Node.js runtime, or falls back to PATH, in the UniWamp application root.');
  YarnButton.ShowHint := True;
  PnpmButton := TPanel.Create(Self);
  PnpmButton.Parent := pnltools;
  PnpmButton.SetBounds(368, 73, 82, 24);
  PnpmButton.Cursor := crHandPoint;
  PnpmButton.BevelOuter := bvNone;
  PnpmButton.Caption := 'pnpm';
  PnpmButton.Color := 16053492;
  PnpmButton.Font.Charset := DEFAULT_CHARSET;
  PnpmButton.Font.Color := clWindowText;
  PnpmButton.Font.Height := -11;
  PnpmButton.Font.Name := 'Segoe UI';
  PnpmButton.Font.Style := [fsBold];
  PnpmButton.ParentBackground := False;
  PnpmButton.ParentFont := False;
  PnpmButton.TabOrder := 15;
  PnpmButton.OnClick := LaunchPnpmClick;
  PnpmButton.Hint := BuildToolPanelHint('Launch pnpm from the selected Node.js runtime',
    'Opens bundled pnpm.cmd from the selected Node.js runtime or pnpm.cmd from PATH in the UniWamp application root.');
  PnpmButton.ShowHint := True;
  EditorButton := TPanel.Create(Self);
  EditorButton.Parent := pnltools;
  EditorButton.SetBounds(456, 73, 82, 24);
  EditorButton.Cursor := crHandPoint;
  EditorButton.BevelOuter := bvNone;
  EditorButton.Caption := 'Editor';
  EditorButton.Color := 16053492;
  EditorButton.Font.Charset := DEFAULT_CHARSET;
  EditorButton.Font.Color := clWindowText;
  EditorButton.Font.Height := -11;
  EditorButton.Font.Name := 'Segoe UI';
  EditorButton.Font.Style := [fsBold];
  EditorButton.ParentBackground := False;
  EditorButton.ParentFont := False;
  EditorButton.TabOrder := 16;
  EditorButton.OnClick := LaunchEditorClick;
  EditorButton.Hint := BuildToolPanelHint('Launch the preferred text editor',
    'Opens the repository root in bundled Lite XL, then EDITOR, then Notepad.');
  EditorButton.ShowHint := True;
  UpdateButton := TPanel.Create(Self);
  UpdateButton.Parent := pnltools;
  UpdateButton.SetBounds(546, 73, 92, 24);
  UpdateButton.Cursor := crHandPoint;
  UpdateButton.BevelOuter := bvNone;
  UpdateButton.Caption := 'Update';
  UpdateButton.Color := 16053492;
  UpdateButton.Font.Charset := DEFAULT_CHARSET;
  UpdateButton.Font.Color := clWindowText;
  UpdateButton.Font.Height := -11;
  UpdateButton.Font.Name := 'Segoe UI';
  UpdateButton.Font.Style := [fsBold];
  UpdateButton.ParentBackground := False;
  UpdateButton.ParentFont := False;
  UpdateButton.TabOrder := 17;
  UpdateButton.OnClick := StageUpdateClick;
  UpdateButton.Hint := BuildToolPanelHint('Stage an update package from a manifest',
    'Selects an update manifest, verifies the package hash, and stages the package into tmp\\updates.');
  UpdateButton.ShowHint := True;
  SaveConfigButton.OnClick := SaveConfigClick;
  SaveConfigButton.Hint := BuildToolPanelHint('Save configuration',
    'Persists the current dashboard settings to config/uniwamp.json.');
  SaveConfigButton.ShowHint := True;
  GenerateSslButton.OnClick := GenerateSslClick;
  GenerateSslButton.Hint := BuildToolPanelHint('Generate SSL',
    'Creates the default local TLS certificate and key pair.');
  GenerateSslButton.ShowHint := True;
  GenerateSslButton.TabStop := True;
  GenerateSslButton.TabOrder := 0;
  CopyDiagnosticReportButton := TPanel.Create(Self);
  CopyDiagnosticReportButton.Parent := pnltools;
  CopyDiagnosticReportButton.SetBounds(123, 41, 150, 24);
  CopyDiagnosticReportButton.Cursor := crHandPoint;
  CopyDiagnosticReportButton.BevelOuter := bvNone;
  CopyDiagnosticReportButton.Caption := 'Copy Report';
  CopyDiagnosticReportButton.Color := 16053492;
  CopyDiagnosticReportButton.Font.Assign(GenerateSslButton.Font);
  CopyDiagnosticReportButton.ParentBackground := False;
  CopyDiagnosticReportButton.ParentFont := False;
  CopyDiagnosticReportButton.TabOrder := 8;
  CopyDiagnosticReportButton.TabStop := True;
  CopyDiagnosticReportButton.Hint := BuildToolPanelHint('Copy diagnostic report',
    'Copies a portable snapshot of the current state to the clipboard.');
  CopyDiagnosticReportButton.ShowHint := True;
  CopyDiagnosticReportButton.OnClick := CopyDiagnosticReportClick;
  CopyActivityLogButton := TPanel.Create(Self);
  CopyActivityLogButton.Parent := pnltools;
  CopyActivityLogButton.SetBounds(277, 41, 150, 24);
  CopyActivityLogButton.Cursor := crHandPoint;
  CopyActivityLogButton.BevelOuter := bvNone;
  CopyActivityLogButton.Caption := 'Copy Activity';
  CopyActivityLogButton.Color := 16053492;
  CopyActivityLogButton.Font.Assign(GenerateSslButton.Font);
  CopyActivityLogButton.ParentBackground := False;
  CopyActivityLogButton.ParentFont := False;
  CopyActivityLogButton.TabOrder := 9;
  CopyActivityLogButton.TabStop := True;
  CopyActivityLogButton.Hint := BuildToolPanelHint('Copy activity log',
    'Copies the current activity log text to the clipboard.');
  CopyActivityLogButton.ShowHint := True;
  CopyActivityLogButton.OnClick := CopyActivityLogClick;
  OpenHostsFileButton := TPanel.Create(Self);
  OpenHostsFileButton.Parent := pnltools;
  OpenHostsFileButton.SetBounds(431, 41, 150, 24);
  OpenHostsFileButton.Cursor := crHandPoint;
  OpenHostsFileButton.BevelOuter := bvNone;
  OpenHostsFileButton.Caption := 'Hosts File';
  OpenHostsFileButton.Color := 16053492;
  OpenHostsFileButton.Font.Assign(GenerateSslButton.Font);
  OpenHostsFileButton.ParentBackground := False;
  OpenHostsFileButton.ParentFont := False;
  OpenHostsFileButton.TabOrder := 10;
  OpenHostsFileButton.TabStop := True;
  OpenHostsFileButton.Hint := BuildToolPanelHint('Open Windows hosts file',
    'Shows the hosts file UniWamp reads and updates in the default text editor.');
  OpenHostsFileButton.ShowHint := True;
  OpenHostsFileButton.OnClick := OpenHostsFileClick;
  BackupDatabaseButton := TPanel.Create(Self);
  BackupDatabaseButton.Parent := pnltools;
  BackupDatabaseButton.SetBounds(587, 41, 150, 24);
  BackupDatabaseButton.Cursor := crHandPoint;
  BackupDatabaseButton.BevelOuter := bvNone;
  BackupDatabaseButton.Caption := 'DB Backup';
  BackupDatabaseButton.Color := 16053492;
  BackupDatabaseButton.Font.Assign(GenerateSslButton.Font);
  BackupDatabaseButton.ParentBackground := False;
  BackupDatabaseButton.ParentFont := False;
  BackupDatabaseButton.TabOrder := 11;
  BackupDatabaseButton.TabStop := True;
  BackupDatabaseButton.Hint := BuildToolPanelHint('Backup MariaDB databases',
    'Creates a full SQL dump of all databases into the UniWamp backups folder.');
  BackupDatabaseButton.ShowHint := True;
  BackupDatabaseButton.OnClick := BackupDatabaseClick;
  RestoreDatabaseButton := TPanel.Create(Self);
  RestoreDatabaseButton.Parent := pnltools;
  RestoreDatabaseButton.SetBounds(741, 41, 150, 24);
  RestoreDatabaseButton.Cursor := crHandPoint;
  RestoreDatabaseButton.BevelOuter := bvNone;
  RestoreDatabaseButton.Caption := 'DB Restore';
  RestoreDatabaseButton.Color := 16053492;
  RestoreDatabaseButton.Font.Assign(GenerateSslButton.Font);
  RestoreDatabaseButton.ParentBackground := False;
  RestoreDatabaseButton.ParentFont := False;
  RestoreDatabaseButton.TabOrder := 12;
  RestoreDatabaseButton.TabStop := True;
  RestoreDatabaseButton.Hint := BuildToolPanelHint('Restore MariaDB databases',
    'Restores a SQL dump created by UniWamp from a backup.txt manifest.');
  RestoreDatabaseButton.ShowHint := True;
  RestoreDatabaseButton.OnClick := RestoreDatabaseClick;
  Panel8.Hint := BuildToolPanelHint('Open the local dashboard',
    'Only opens when Apache and MariaDB are both healthy.');
  Panel8.ShowHint := True;
  Panel8.OnClick := LaunchDashboardClick;
  Panel8.TabStop := True;
  Panel8.TabOrder := 1;
  Panel9.Hint := BuildToolPanelHint('Open Adminer',
    'Launches the database web UI when the Adminer entrypoint exists.');
  Panel9.ShowHint := True;
  Panel9.OnClick := LaunchAdminerClick;
  Panel9.TabStop := True;
  Panel9.TabOrder := 2;
  OpenPhpExtensionsButton.OnClick := OpenPhpExtensionsClick;
  OpenPhpExtensionsButton.Hint := BuildToolPanelHint('Open PHP Extensions',
    'Edit the active PHP extension list for the selected runtime.');
  OpenPhpExtensionsButton.ShowHint := True;
  OpenPhpExtensionsButton.TabStop := True;
  OpenPhpExtensionsButton.TabOrder := 3;
  OpenPhpSettingsButton.OnClick := OpenPhpSettingsClick;
  OpenPhpSettingsButton.Hint := BuildToolPanelHint('Open PHP Settings',
    'Edit the selected PHP profile values.');
  OpenPhpSettingsButton.ShowHint := True;
  OpenPhpSettingsButton.TabStop := True;
  OpenPhpSettingsButton.TabOrder := 4;
  OpenApacheModulesButton.OnClick := OpenApacheModulesClick;
  OpenApacheModulesButton.Hint := BuildToolPanelHint('Open Apache Modules',
    'Edit the Apache module list used by the generated config.');
  OpenApacheModulesButton.ShowHint := True;
  OpenApacheModulesButton.TabStop := True;
  OpenApacheModulesButton.TabOrder := 5;
  OpenApacheLogButton.OnClick := OpenApacheLogClick;
  OpenApacheLogButton.Hint := BuildToolPanelHint('Open Apache Log',
    'Shows the Apache error log in the default text editor.');
  OpenApacheLogButton.ShowHint := True;
  OpenApacheLogButton.TabStop := True;
  OpenApacheLogButton.TabOrder := 6;
  OpenMariaLogButton.OnClick := OpenMariaDbLogClick;
  OpenMariaLogButton.Hint := BuildToolPanelHint('Open MariaDB Log',
    'Shows the MariaDB error log in the default text editor.');
  OpenMariaLogButton.ShowHint := True;
  OpenMariaLogButton.TabStop := True;
  OpenMariaLogButton.TabOrder := 7;
  ClearApacheLogButton.OnClick := ClearApacheLogClick;
  ClearApacheLogButton.Hint := BuildToolPanelHint('Clear Apache Log',
    'Removes the current Apache error log contents.');
  ClearApacheLogButton.ShowHint := True;
  ClearApacheLogButton.TabStop := True;
  ClearApacheLogButton.TabOrder := 8;
  ClearMariaLogButton.OnClick := ClearMariaDbLogClick;
  ClearMariaLogButton.Hint := BuildToolPanelHint('Clear MariaDB Log',
    'Removes the current MariaDB error log contents.');
  ClearMariaLogButton.ShowHint := True;
  ClearMariaLogButton.TabStop := True;
  ClearMariaLogButton.TabOrder := 9;
  ClearActivityLogButton.OnClick := ClearActivityLogClick;
  ClearActivityLogButton.Hint := BuildToolPanelHint('Clear activity log',
    'Clears the in-memory activity memo and the persisted activity log file.');
  ClearActivityLogButton.ShowHint := True;
  ClearActivityLogButton.TabStop := True;
  ClearActivityLogButton.TabOrder := 10;
  Label20.OnClick := OpenActivityClick;
  Label20.Hint := BuildToolPanelHint('Open Activity Log',
    'Shows the activity log in the log file location.');
  Label20.ShowHint := True;
  Label20.TabStop := True;
  Label20.TabOrder := 11;
  AddVHostButton.OnClick := AddVHostClick;
  AddVHostButton.Hint := BuildToolPanelHint('Add a vHost',
    'Creates a new local project entry and writes the matching Apache configuration.');
  AddVHostButton.ShowHint := True;
  AddVHostButton.TabStop := True;
  AddVHostButton.TabOrder := 12;
  DeleteVHostButton.OnClick := DeleteVHostClick;
  DeleteVHostButton.Hint := BuildToolPanelHint('Delete the selected project',
    'Removes the selected project entry and its generated configuration.');
  DeleteVHostButton.ShowHint := True;
  DeleteVHostButton.TabStop := True;
  DeleteVHostButton.TabOrder := 13;
  OpenVHostButton.OnClick := OpenVHostClick;
  OpenVHostButton.Hint := BuildToolPanelHint('Open the selected project',
    'Launches the selected vHost in the browser when Apache is running.');
  OpenVHostButton.ShowHint := True;
  OpenVHostButton.TabStop := True;
  OpenVHostButton.TabOrder := 14;
  OpenVHostFolderButton.OnClick := OpenVHostFolderClick;
  OpenVHostFolderButton.Hint := BuildToolPanelHint('Open the project folder',
    'Shows the document root in File Explorer.');
  OpenVHostFolderButton.ShowHint := True;
  OpenVHostFolderButton.TabStop := True;
  OpenVHostFolderButton.TabOrder := 15;
  OpenVHostTerminalButton.OnClick := OpenVHostTerminalClick;
  OpenVHostTerminalButton.Hint := BuildToolPanelHint('Open terminal in the project folder',
    'Launches the configured terminal in the selected vHost document root.');
  OpenVHostTerminalButton.ShowHint := True;
  OpenVHostTerminalButton.TabStop := True;
  OpenVHostTerminalButton.TabOrder := 16;
  BackupProjectButton.OnClick := BackupProjectClick;
  BackupProjectButton.Hint := BuildToolPanelHint('Backup the selected project',
    'Creates a backup bundle with project files, vHost metadata, and SSL assets when present.');
  BackupProjectButton.ShowHint := True;
  BackupProjectButton.TabStop := True;
  BackupProjectButton.TabOrder := 17;
  RestoreProjectButton.OnClick := RestoreProjectClick;
  RestoreProjectButton.Hint := BuildToolPanelHint('Restore a project backup',
    'Restores project files from a backup bundle and recreates the vHost entry.');
  RestoreProjectButton.ShowHint := True;
  RestoreProjectButton.TabStop := True;
  RestoreProjectButton.TabOrder := 18;
  CopyVHostUrlButton.OnClick := CopyVHostUrlClick;
  CopyVHostUrlButton.Hint := BuildToolPanelHint('Copy the vHost URL',
    'Copies the selected local site address to the clipboard.');
  CopyVHostUrlButton.ShowHint := True;
  CopyVHostUrlButton.TabStop := True;
  CopyVHostUrlButton.TabOrder := 19;
  exitbutton.OnClick := ExitButtonClick;
  exitbutton.TabStop := True;
  exitbutton.TabOrder := 20;
  Panel11.OnClick := ExitButtonClick;
  Panel11.TabStop := True;
  Panel11.TabOrder := 21;
  EditPhpIniButton.OnClick := EditPhpIniClick;
  EditPhpIniButton.Hint := BuildToolPanelHint('Edit php.ini',
    'Opens the generated PHP configuration for the active runtime.');
  EditPhpIniButton.ShowHint := True;
  EditPhpIniButton.TabStop := True;
  EditPhpIniButton.TabOrder := 20;
  EditHttpdConfButton.OnClick := EditHttpdConfClick;
  EditHttpdConfButton.Hint := BuildToolPanelHint('Edit httpd.conf',
    'Opens the generated Apache configuration.');
  EditHttpdConfButton.ShowHint := True;
  EditHttpdConfButton.TabStop := True;
  EditHttpdConfButton.TabOrder := 21;
  EditMariaDbIniButton.OnClick := EditMariaDbIniClick;
  EditMariaDbIniButton.Hint := BuildToolPanelHint('Edit mariadb.ini',
    'Opens the generated MariaDB configuration.');
  EditMariaDbIniButton.ShowHint := True;
  EditMariaDbIniButton.TabStop := True;
  EditMariaDbIniButton.TabOrder := 22;
  StopAllButton.OnClick := StopButtonClick;
  StopAllButton.TabStop := True;
  StopAllButton.TabOrder := 23;
  StyleLinkButton(Label20, True);
  Label20.Visible := True;
  exitbutton.Color := $00FFD3D3;
  exitbutton.Font.Color := $00603030;
  ApplyPanelIcon(ApacheStartButton, 'play_arrow');
  ApplyPanelIcon(ApacheStopButton, 'stop');
  ApplyPanelIcon(ApacheRestartButton, 'restart_alt');
  ApplyPanelIcon(MariaStartButton, 'play_arrow');
  ApplyPanelIcon(MariaStopButton, 'stop');
  ApplyPanelIcon(MariaRestartButton, 'restart_alt');
  ClearPanelIcon(GenerateSslButton);
  ClearPanelIcon(LaunchTerminalButton);
  ClearPanelIcon(OpenRepoTerminalButton);
  ClearPanelIcon(ComposerButton);
  ClearPanelIcon(GitButton);
  ClearPanelIcon(NodeButton);
  ClearPanelIcon(WpCliButton);
  ClearPanelIcon(MailpitButton);
  ClearPanelIcon(RedisButton);
  ClearPanelIcon(MemcachedButton);
  ClearPanelIcon(NpmButton);
  ClearPanelIcon(YarnButton);
  ClearPanelIcon(PnpmButton);
  ClearPanelIcon(EditorButton);
  ClearPanelIcon(UpdateButton);
  ClearPanelIcon(CopyDiagnosticReportButton);
  ClearPanelIcon(CopyActivityLogButton);
  ClearPanelIcon(OpenHostsFileButton);
  ClearPanelIcon(BackupDatabaseButton);
  ClearPanelIcon(RestoreDatabaseButton);
  ClearPanelIcon(OpenPhpExtensionsButton);
  ClearPanelIcon(OpenPhpSettingsButton);
  ClearPanelIcon(OpenApacheModulesButton);
  ClearPanelIcon(SaveConfigButton);
  ApplyPanelIcon(exitbutton, 'logout');
  ApplyPanelIcon(AddVHostButton, 'add');
  ApplyPanelIcon(OpenVHostButton, 'open_in_new');
  ApplyPanelIcon(OpenVHostFolderButton, 'folder_open');
  ClearPanelIcon(OpenVHostTerminalButton);
  ApplyPanelIcon(BackupProjectButton, 'save');
  ApplyPanelIcon(RestoreProjectButton, 'restore');
  ApplyPanelIcon(CopyVHostUrlButton, 'content_copy');
  ApplyPanelIcon(DeleteVHostButton, 'delete');
  ClearPanelIcon(OpenApacheLogButton);
  ClearPanelIcon(OpenMariaLogButton);
  ClearPanelIcon(ClearApacheLogButton);
  ClearPanelIcon(ClearMariaLogButton);
  ClearPanelIcon(ClearActivityLogButton);
  ApplyPanelIcon(EditPhpIniButton, 'code');
  ApplyPanelIcon(EditHttpdConfButton, 'web');
  ApplyPanelIcon(EditMariaDbIniButton, 'database');
  SetButtonCaption(LaunchTerminalButton, 'Terminal');
  SetButtonCaption(OpenRepoTerminalButton, 'Repo Terminal');
  SetButtonCaption(ComposerButton, 'Composer');
  SetButtonCaption(GitButton, 'Git');
  SetButtonCaption(NodeButton, 'Node');
  SetButtonCaption(WpCliButton, 'WP-CLI');
  SetButtonCaption(MailpitButton, 'Mailpit');
  SetButtonCaption(RedisButton, 'Redis');
  SetButtonCaption(MemcachedButton, 'Memcached');
  SetButtonCaption(NpmButton, 'npm');
  SetButtonCaption(YarnButton, 'yarn');
  SetButtonCaption(PnpmButton, 'pnpm');
  SetButtonCaption(EditorButton, 'Editor');
  SetButtonCaption(UpdateButton, 'Update');
  SetButtonCaption(SaveConfigButton, 'Save Config');
  SetButtonCaption(GenerateSslButton, 'Generate SSL');
  SetButtonCaption(CopyDiagnosticReportButton, 'Copy Report');
  SetButtonCaption(CopyActivityLogButton, 'Copy Activity');
  SetButtonCaption(OpenHostsFileButton, 'Hosts File');
  SetButtonCaption(BackupDatabaseButton, 'DB Backup');
  SetButtonCaption(RestoreDatabaseButton, 'DB Restore');
  SetButtonCaption(OpenApacheLogButton, 'Apache Log');
  SetButtonCaption(OpenMariaLogButton, 'MariaDB Log');
  SetButtonCaption(ClearApacheLogButton, 'Clear Apache');
  SetButtonCaption(ClearMariaLogButton, 'Clear MariaDB');
  SetButtonCaption(ClearActivityLogButton, 'Clear activity');
  SetButtonCaption(OpenPhpExtensionsButton, 'PHP Extensions');
  SetButtonCaption(OpenPhpSettingsButton, 'PHP Settings');
  SetButtonCaption(OpenApacheModulesButton, 'Apache Modules');
  SetButtonCaption(AddVHostButton, 'Add');
  SetButtonCaption(OpenVHostButton, 'Open Selected');
  SetButtonCaption(OpenVHostFolderButton, 'Open Folder');
  SetButtonCaption(OpenVHostTerminalButton, 'Terminal');
  SetButtonCaption(BackupProjectButton, 'Backup Project');
  SetButtonCaption(RestoreProjectButton, 'Restore Project');
  SetButtonCaption(CopyVHostUrlButton, 'Copy URL');
  SetButtonCaption(DeleteVHostButton, 'Delete Project');
  SetButtonCaption(EditPhpIniButton, 'php.ini');
  SetButtonCaption(EditHttpdConfButton, 'httpd.conf');
  SetButtonCaption(EditMariaDbIniButton, 'mariadb.ini');
  ClearPanelIcon(GenerateSslButton);
  ClearPanelIcon(Panel8);
  ClearPanelIcon(Panel9);
  ClearPanelIcon(LaunchTerminalButton);
  ClearPanelIcon(OpenRepoTerminalButton);
  ClearPanelIcon(SaveConfigButton);
  ClearPanelIcon(CopyDiagnosticReportButton);
  ClearPanelIcon(CopyActivityLogButton);
  ClearPanelIcon(OpenHostsFileButton);
  ClearPanelIcon(BackupDatabaseButton);
  ClearPanelIcon(RestoreDatabaseButton);
  ClearPanelIcon(OpenPhpExtensionsButton);
  ClearPanelIcon(OpenPhpSettingsButton);
  ClearPanelIcon(OpenApacheModulesButton);
  ClearPanelIcon(ComposerButton);
  ClearPanelIcon(GitButton);
  ClearPanelIcon(NodeButton);
  ClearPanelIcon(WpCliButton);
  ClearPanelIcon(MailpitButton);
  ClearPanelIcon(RedisButton);
  ClearPanelIcon(MemcachedButton);
  ClearPanelIcon(NpmButton);
  ClearPanelIcon(YarnButton);
  ClearPanelIcon(PnpmButton);
  ClearPanelIcon(EditorButton);
  ClearPanelIcon(UpdateButton);
  SetButtonCaption(GenerateSslButton, 'Generate SSL');
  SetButtonCaption(Panel8, 'Web Dashboard');
  SetButtonCaption(Panel9, 'Adminer');
  SetButtonCaption(LaunchTerminalButton, 'Terminal');
  SetButtonCaption(OpenRepoTerminalButton, 'Repo Terminal');
  SetButtonCaption(SaveConfigButton, 'Save Config');
  SetButtonCaption(CopyDiagnosticReportButton, 'Copy Report');
  SetButtonCaption(CopyActivityLogButton, 'Copy Activity');
  SetButtonCaption(OpenHostsFileButton, 'Hosts File');
  SetButtonCaption(BackupDatabaseButton, 'DB Backup');
  SetButtonCaption(RestoreDatabaseButton, 'DB Restore');
  SetButtonCaption(OpenPhpExtensionsButton, 'PHP Extensions');
  SetButtonCaption(OpenPhpSettingsButton, 'PHP Settings');
  SetButtonCaption(OpenApacheModulesButton, 'Apache Modules');
  SetButtonCaption(ComposerButton, 'Composer');
  SetButtonCaption(GitButton, 'Git');
  SetButtonCaption(NodeButton, 'Node');
  SetButtonCaption(WpCliButton, 'WP-CLI');
  SetButtonCaption(MailpitButton, 'Mailpit');
  SetButtonCaption(RedisButton, 'Redis');
  SetButtonCaption(MemcachedButton, 'Memcached');
  SetButtonCaption(NpmButton, 'npm');
  SetButtonCaption(YarnButton, 'yarn');
  SetButtonCaption(PnpmButton, 'pnpm');
  SetButtonCaption(EditorButton, 'Editor');
  SetButtonCaption(UpdateButton, 'Update');
  BuildMenus;
  Menu := FMainMenu;
  if HandleAllocated then
    DrawMenuBar(Handle);
  VHostGrid.DefaultDrawing := False;
  VHostGrid.Options := VHostGrid.Options + [goRowSelect];
  VHostGrid.OnDrawCell := VHostGridDrawCell;
  VHostGrid.OnMouseUp := VHostGridMouseUp;
  VHostGrid.OnKeyDown := VHostGridKeyDown;
  VHostGrid.OnEnter := VHostGridEnter;
  VHostGrid.OnExit := VHostGridExit;
  VHostGrid.Font.Name := 'Segoe UI';
  VHostGrid.Font.Size := 9;
  VHostGrid.FixedColor := GridHeaderColor;
  VHostGrid.Color := clWhite;
  VHostGrid.TabStop := True;
  VHostGrid.TabOrder := 18;
  VHostGrid.ColCount := 5;
  VHostGrid.FixedRows := 1;
  VHostGrid.RowCount := 2;
  VHostGrid.DefaultRowHeight := 30;
  VHostGrid.Cells[0, 0] := 'Site Name';
  VHostGrid.Cells[1, 0] := 'Document Path';
  VHostGrid.Cells[2, 0] := 'Type';
  VHostGrid.Cells[3, 0] := 'URL';
  VHostGrid.Cells[4, 0] := 'Actions';
  VHostGrid.ColWidths[0] := 110;
  VHostGrid.ColWidths[1] := 262;
  VHostGrid.ColWidths[2] := 132;
  VHostGrid.ColWidths[3] := 152;
  VHostGrid.ColWidths[4] := 206;
  LoadStateIntoUi;
  LayoutDashboard;
  RefreshStatus;
  OnCloseQuery := FormCloseQuery;
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
    FHeaderCards[I].Panel.ShowHint := True;

    FHeaderCards[I].Dot := TShape.Create(Self);
    FHeaderCards[I].Dot.Parent := FHeaderCards[I].Panel;
    FHeaderCards[I].Dot.Shape := stCircle;
    FHeaderCards[I].Dot.Pen.Style := psClear;
    FHeaderCards[I].Dot.Brush.Color := RGB(180, 225, 48);
    FHeaderCards[I].Dot.Left := 15;
    FHeaderCards[I].Dot.Top := 14;
    FHeaderCards[I].Dot.Width := 10;
    FHeaderCards[I].Dot.Height := 10;

    FHeaderCards[I].Title := TLabel.Create(Self);
    FHeaderCards[I].Title.Parent := FHeaderCards[I].Panel;
    FHeaderCards[I].Title.Left := 30;
    FHeaderCards[I].Title.Top := 7;
    FHeaderCards[I].Title.Font.Name := 'Segoe UI';
    FHeaderCards[I].Title.Font.Size := 11;
    FHeaderCards[I].Title.Font.Style := [fsBold];
    FHeaderCards[I].Title.Font.Color := clWhite;
    FHeaderCards[I].Title.Transparent := True;
    FHeaderCards[I].Title.Caption := CardTitles[I];

    FHeaderCards[I].Detail1 := TLabel.Create(Self);
    FHeaderCards[I].Detail1.Parent := FHeaderCards[I].Panel;
    FHeaderCards[I].Detail1.Left := 30;
    FHeaderCards[I].Detail1.Top := 26;
    FHeaderCards[I].Detail1.Font.Name := 'Segoe UI';
    FHeaderCards[I].Detail1.Font.Size := 10;
    FHeaderCards[I].Detail1.Font.Color := HeaderTextColor;
    FHeaderCards[I].Detail1.Transparent := True;

    FHeaderCards[I].Detail2 := TLabel.Create(Self);
    FHeaderCards[I].Detail2.Parent := FHeaderCards[I].Panel;
    FHeaderCards[I].Detail2.Left := 30;
    FHeaderCards[I].Detail2.Top := 42;
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
  HeaderPanel.Height := 86;

  GridWidth := VHostGrid.ClientWidth;
  VHostGrid.ColWidths[0] := 110;
  VHostGrid.ColWidths[2] := 132;
  VHostGrid.ColWidths[3] := 152;
  VHostGrid.ColWidths[4] := 206;
  AvailableGridColumns := GridWidth - VHostGrid.ColWidths[0] - VHostGrid.ColWidths[2] - VHostGrid.ColWidths[3] - VHostGrid.ColWidths[4];
  if AvailableGridColumns < 250 then
    AvailableGridColumns := 250;
  VHostGrid.ColWidths[1] := AvailableGridColumns;
  if VHostGrid.ColWidths[1] + VHostGrid.ColWidths[0] + VHostGrid.ColWidths[2] + VHostGrid.ColWidths[3] + VHostGrid.ColWidths[4] > GridWidth then
    VHostGrid.ColWidths[1] := GridWidth - VHostGrid.ColWidths[0] - VHostGrid.ColWidths[2] - VHostGrid.ColWidths[3] - VHostGrid.ColWidths[4];
  if VHostGrid.ColWidths[1] < 1 then
    VHostGrid.ColWidths[1] := 1;

  if Assigned(Label11) then
  begin
    Label11.Height := 34;
    if Assigned(FVHostHeaderTitle) then
    begin
      FVHostHeaderTitle.Left := 12;
      FVHostHeaderTitle.Top := (Label11.Height - FVHostHeaderTitle.Height) div 2;
    end;
    if Assigned(FVHostFilterClearLabel) then
    begin
      FVHostFilterClearLabel.Top := (Label11.Height - FVHostFilterClearLabel.Height) div 2;
      FVHostFilterClearLabel.Left := Label11.Width - FVHostFilterClearLabel.Width - 12;
    end;
    if Assigned(FVHostFilterEdit) then
    begin
      FVHostFilterEdit.Top := (Label11.Height - FVHostFilterEdit.Height) div 2;
      FVHostFilterEdit.Width := Min(240, Max(180, (Label11.Width div 3)));
      if Assigned(FVHostFilterClearLabel) then
        FVHostFilterEdit.Left := FVHostFilterClearLabel.Left - FVHostFilterEdit.Width - 10
      else
        FVHostFilterEdit.Left := Label11.Width - FVHostFilterEdit.Width - 12;
    end;
    if Assigned(FVHostFilterLabel) then
    begin
      FVHostFilterLabel.Top := (Label11.Height - FVHostFilterLabel.Height) div 2;
      FVHostFilterLabel.Left := Max(FVHostHeaderTitle.Left + FVHostHeaderTitle.Width + 18,
        FVHostFilterEdit.Left - FVHostFilterLabel.Width - 8);
    end;
  end;

  CardWidth := 170;
  CardGap := 18;
  CardTop := 8;
  RightEdge := HeaderPanel.Width - 20;

  FHeaderCards[2].Panel.SetBounds(RightEdge - CardWidth, CardTop, CardWidth, 60);
  FHeaderCards[1].Panel.SetBounds(FHeaderCards[2].Panel.Left - CardGap - CardWidth, CardTop, CardWidth, 60);
  FHeaderCards[0].Panel.SetBounds(FHeaderCards[1].Panel.Left - CardGap - CardWidth, CardTop, CardWidth, 60);
  FHeaderCards[0].Panel.Visible := True;
  FHeaderCards[1].Panel.Visible := True;
  FHeaderCards[2].Panel.Visible := True;
  FHeaderCards[0].Panel.Hint := BuildHeaderCardHint(FHeaderCards[0].Title.Caption,
    FHeaderCards[0].Detail1.Caption, FHeaderCards[0].Detail2.Caption);
  FHeaderCards[1].Panel.Hint := BuildHeaderCardHint(FHeaderCards[1].Title.Caption,
    FHeaderCards[1].Detail1.Caption, FHeaderCards[1].Detail2.Caption);
  FHeaderCards[2].Panel.Hint := BuildHeaderCardHint(FHeaderCards[2].Title.Caption,
    FHeaderCards[2].Detail1.Caption, FHeaderCards[2].Detail2.Caption);
  LayoutToolSidebar;
end;

procedure TMainForm.LayoutToolSidebar;
const
  SideMargin = 8;
  RowGap = 4;
  GroupGap = 8;
  ButtonHeight = 22;
  LabelHeight = 16;
var
  ButtonWidth: Integer;
  Y: Integer;
  procedure PlaceLabel(Panel: TPanel);
  begin
    if not Assigned(Panel) then
      Exit;
    Panel.SetBounds(SideMargin, Y, ButtonWidth, LabelHeight);
    Inc(Y, LabelHeight + 2);
  end;
  procedure PlaceButton(Button: TPanel);
  begin
    if not Assigned(Button) then
      Exit;
    Button.SetBounds(SideMargin, Y, ButtonWidth, ButtonHeight);
    Inc(Y, ButtonHeight + RowGap);
  end;
begin
  if not Assigned(pnltools) then
    Exit;

  ButtonWidth := pnltools.ClientWidth - (SideMargin * 2);
  if ButtonWidth < 122 then
    ButtonWidth := 122;

  Y := 8;
  PlaceLabel(ToolGroupWebLabel);
  PlaceButton(GenerateSslButton);
  PlaceButton(Panel8);
  PlaceButton(Panel9);
  PlaceButton(LaunchTerminalButton);
  PlaceButton(OpenRepoTerminalButton);
  Inc(Y, GroupGap);
  PlaceLabel(ToolGroupRuntimeLabel);
  PlaceButton(OpenPhpSettingsButton);
  PlaceButton(OpenPhpExtensionsButton);
  PlaceButton(OpenApacheModulesButton);
  PlaceButton(ComposerButton);
  PlaceButton(GitButton);
  PlaceButton(NodeButton);
  PlaceButton(WpCliButton);
  PlaceButton(MailpitButton);
  PlaceButton(RedisButton);
  PlaceButton(MemcachedButton);
  PlaceButton(NpmButton);
  PlaceButton(YarnButton);
  PlaceButton(PnpmButton);
  PlaceButton(EditorButton);
  Inc(Y, GroupGap);
  PlaceLabel(ToolGroupLogsLabel);
  PlaceButton(OpenApacheLogButton);
  PlaceButton(OpenMariaLogButton);
  PlaceButton(ClearApacheLogButton);
  PlaceButton(ClearMariaLogButton);
  PlaceButton(ClearActivityLogButton);
  Inc(Y, GroupGap);
  PlaceLabel(ToolGroupMaintenanceLabel);
  PlaceButton(SaveConfigButton);
  PlaceButton(CopyDiagnosticReportButton);
  PlaceButton(CopyActivityLogButton);
  PlaceButton(OpenHostsFileButton);
  PlaceButton(BackupDatabaseButton);
  PlaceButton(RestoreDatabaseButton);
  PlaceButton(UpdateButton);
end;

procedure TMainForm.FormResize(Sender: TObject);
begin
  if HandleAllocated then
    LayoutDashboard;
end;

procedure TMainForm.FormShow(Sender: TObject);
begin
  if Assigned(FMainMenu) then
    Menu := FMainMenu;
  if HandleAllocated then
    DrawMenuBar(Handle);
  LayoutDashboard;
  if (not FStartupActionExecuted) and FConfig.StartAllOnLaunch then
  begin
    FStartupActionExecuted := True;
    StartButtonClick(Self);
  end
  else
    FStartupActionExecuted := True;
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
  FMainStartAllOnLaunchItem := AddItem(MenuItem, 'Start all on &Launch', StartAllOnLaunchClick);
  FMainStartAllOnLaunchItem.AutoCheck := True;
  Item := AddItem(MenuItem, 'Application &Settings', OpenAppSettingsClick);
  Item.ShortCut := ShortCut(Ord('S'), [ssCtrl, ssAlt]);
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
  Item := AddItem(MenuItem, 'Open &Folder', OpenVHostFolderClick);
  Item.ShortCut := ShortCut(Ord('R'), [ssCtrl]);
  Item := AddItem(MenuItem, 'Open &Terminal', OpenVHostTerminalClick);
  Item.ShortCut := ShortCut(Ord('T'), [ssCtrl, ssShift]);
  Item := AddItem(MenuItem, '&Backup Project', BackupProjectClick);
  Item.ShortCut := ShortCut(Ord('B'), [ssCtrl, ssShift]);
  Item := AddItem(MenuItem, '&Restore Project', RestoreProjectClick);
  Item := AddItem(MenuItem, 'Clear &Filter', VHostFilterClearClick);
  Item.ShortCut := ShortCut(Ord('F'), [ssCtrl]);
  Item := AddItem(MenuItem, '&Copy URL', CopyVHostUrlClick);
  Item.ShortCut := ShortCut(Ord('C'), [ssCtrl, ssShift]);
  AddItem(MenuItem, '-');
  Item := AddItem(MenuItem, '&Delete Project', DeleteVHostClick);
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
  Item := AddItem(MenuItem, '&Copy Diagnostic Report', CopyDiagnosticReportClick);
  Item.ShortCut := ShortCut(Ord('R'), [ssCtrl, ssShift]);
  Item := AddItem(MenuItem, 'Copy &Activity Log', CopyActivityLogClick);
  Item.ShortCut := ShortCut(Ord('A'), [ssCtrl, ssShift]);
  Item := AddItem(MenuItem, 'Apache &Log', OpenApacheLogClick);
  Item.ShortCut := ShortCut(Ord('L'), [ssCtrl]);
  Item := AddItem(MenuItem, 'MariaDB &Log', OpenMariaDbLogClick);
  Item.ShortCut := ShortCut(Ord('M'), [ssCtrl]);
  Item := AddItem(MenuItem, 'Activity &Log', OpenActivityClick);
  Item.ShortCut := ShortCut(Ord('V'), [ssCtrl, ssShift]);

  MenuItem := AddItem(FMainMenu.Items, '&Window');
  ApplyMenuIcon(MenuItem, 'view_quilt');
  FMainWindowToggleItem := AddItem(MenuItem, 'Hide Window', ToggleWindowClick);

  MenuItem := AddItem(FMainMenu.Items, '&Help');
  ApplyMenuIcon(MenuItem, 'help');
  AddItem(MenuItem, '&Scripts', ScriptsClick);
  AddItem(MenuItem, '-');
  AddItem(MenuItem, '&About UniWamp', AboutClick);

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
  FTrayStartAllOnLaunchItem := AddItem(FTrayMenu.Items, 'Start all on &Launch', StartAllOnLaunchClick);
  FTrayStartAllOnLaunchItem.AutoCheck := True;
  Item := AddItem(FTrayMenu.Items, 'Application &Settings', OpenAppSettingsClick);
  ApplyMenuIcon(Item, 'settings');
  Item := AddItem(FTrayMenu.Items, '&Generate SSL', GenerateSslClick);
  ApplyMenuIcon(Item, 'lock');
  Item.ShortCut := ShortCut(Ord('G'), [ssCtrl, ssShift]);
  Item := AddItem(FTrayMenu.Items, '&Copy Diagnostic Report', CopyDiagnosticReportClick);
  Item.ShortCut := ShortCut(Ord('R'), [ssCtrl, ssShift]);
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
  Item := AddItem(FTrayMenu.Items, 'Copy &Activity Log', CopyActivityLogClick);
  Item.ShortCut := ShortCut(Ord('V'), [ssCtrl, ssShift]);
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

  FProgressSpinner := TProgressBar.Create(Self);
  FProgressSpinner.Parent := StatusBar;
  FProgressSpinner.Style := pbstMarquee;
  FProgressSpinner.MarqueeInterval := 30;
  FProgressSpinner.Visible := False;
  FProgressSpinner.Align := alClient;
end;

destructor TMainForm.Destroy;
begin
  FMainPhpProfileItems.Free;
  FMainPhpVersionItems.Free;
  FMenuIconIndices.Free;
  FIconCache.Free;
  FUpdateManifestDialog.Free;
  FProjectBackupManifestDialog.Free;
  FDatabaseBackupInfoDialog.Free;
  FRuntime.Free;
  FConfig.Free;
  inherited;
end;

procedure TMainForm.LoadStateIntoUi;
var
  Version: string;
  Entry: TVHostEntry;
  VHosts: TArray<TVHostEntry>;
  FilterText: string;
  RowIndex: Integer;
  ProjectTypeText: string;
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

  FilterText := '';
  if Assigned(FVHostFilterEdit) then
    FilterText := Trim(LowerCase(FVHostFilterEdit.Text));
  if FilterText = '' then
    VHosts := FConfig.VHosts
  else
  begin
    SetLength(VHosts, 0);
    for Entry in FConfig.VHosts do
      if (Pos(FilterText, LowerCase(Entry.ServerName)) > 0) or
         (Pos(FilterText, LowerCase(Entry.DocumentRoot)) > 0) or
         (Pos(FilterText, LowerCase(Entry.ServerAliases)) > 0) then
      begin
        SetLength(VHosts, Length(VHosts) + 1);
        VHosts[High(VHosts)] := Entry;
      end;
  end;
  VHostGrid.RowCount := Length(VHosts) + 1;
  if VHostGrid.RowCount < 2 then
    VHostGrid.RowCount := 2;
  VHostGrid.Cells[0, 0] := 'Site Name';
  VHostGrid.Cells[1, 0] := 'Document Path';
  VHostGrid.Cells[2, 0] := 'Type';
  VHostGrid.Cells[3, 0] := 'URL';
  VHostGrid.Cells[4, 0] := 'Actions';
  VHostGrid.RowHeights[0] := 30;
  for RowIndex := 1 to VHostGrid.RowCount - 1 do
  begin
    VHostGrid.Cells[0, RowIndex] := '';
    VHostGrid.Cells[1, RowIndex] := '';
    VHostGrid.Cells[2, RowIndex] := '';
    VHostGrid.Cells[3, RowIndex] := '';
    VHostGrid.Cells[4, RowIndex] := '';
  end;
  for RowIndex := 0 to High(VHosts) do
  begin
    Entry := VHosts[RowIndex];
    VHostGrid.Cells[0, RowIndex + 1] := Entry.ServerName;
    VHostGrid.Cells[1, RowIndex + 1] := Entry.DocumentRoot;
    ProjectTypeText := DetectProjectTypeLabel(Entry.DocumentRoot);
    VHostGrid.Cells[2, RowIndex + 1] := ProjectTypeText;
    VHostGrid.Cells[3, RowIndex + 1] := VHostUrl(Entry.ServerName);
  end;
  UpdateVHostEmptyState;
end;

function TMainForm.SaveUiIntoState: Boolean;
var
  NormalizedText: string;
  ErrorMessage: string;
begin
  Result := False;
  if Trim(HostNameEdit.Text) = '' then
    NormalizedText := 'localhost'
  else if not ValidateServerName(HostNameEdit.Text, NormalizedText, ErrorMessage) then
  begin
    ShowMessage(ErrorMessage);
    Exit;
  end;
  FConfig.HostName := NormalizedText;

  if Trim(DocumentRootEdit.Text) = '' then
    NormalizedText := FPaths.WwwDir
  else if not ValidateDocumentRoot(DocumentRootEdit.Text, NormalizedText, ErrorMessage) then
  begin
    ShowMessage(ErrorMessage);
    Exit;
  end;
  FConfig.DocumentRoot := NormalizedText;
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
  Result := True;
end;

procedure TMainForm.AppendStatus(const Text: string);
var
  Line: string;
begin
  Line := FormatDateTime('hh:nn:ss', Now) + '  ' + Text;
  AppendRotatedLogLine(TPath.Combine(FPaths.LogsDir, 'activity.log'), Line, 500);
  if Assigned(FActivityMemo) then
  begin
    FActivityMemo.Lines.Add(Line);
    while FActivityMemo.Lines.Count > 200 do
      FActivityMemo.Lines.Delete(0);
    FActivityMemo.SelStart := Length(FActivityMemo.Text);
    FActivityMemo.Perform(EM_SCROLLCARET, 0, 0);
  end;
end;

procedure TMainForm.ShowBusyState(const StatusText: string);
begin
  FIsBusy := True;
  if Assigned(FProgressSpinner) then
  begin
    FProgressSpinner.Visible := True;
    FProgressSpinner.BringToFront;
  end;
  AppendStatus(StatusText);
  // Disable common action buttons
  AddVHostButton.Enabled := False;
  GenerateSslButton.Enabled := False;
  StartAllButton.Enabled := False;
  StopAllButton.Enabled := False;
  Application.ProcessMessages;
end;

procedure TMainForm.HideBusyState(const StatusText: string);
begin
  FIsBusy := False;
  if Assigned(FProgressSpinner) then
    FProgressSpinner.Visible := False;
  if StatusText <> '' then
    AppendStatus(StatusText);
  // Re-evaluate button states
  UpdateStackActionState;
  UpdateVHostActionState;
  Application.ProcessMessages;
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
  FConfig.ApacheRunning := FRuntime.ApacheIsRunning;
  FConfig.ApachePid := FRuntime.ApacheProcessId;

  FConfig.MariaDbRunning := FRuntime.MariaDbIsRunning;
  if FConfig.MariaDbRunning then
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
    OwnerInfo := DescribeTcpPortOwner(Port);
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
    OwnerInfo := DescribeTcpPortOwner(Port);
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
    OwnerInfo := DescribeTcpPortOwner(Port);
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
    FHeaderCards[0].Detail2.Caption := 'Stopped';
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
  if FConfig.MariaDbRunning then
    FHeaderCards[2].Detail1.Caption := 'Port ' + IntToStr(FConfig.DatabasePort)
  else
    FHeaderCards[2].Detail1.Caption := 'Stopped';
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
  StatusError: string;
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
  end;

  StatusError := Trim(FConfig.LastApacheError);
  if StatusError = '' then
    StatusError := Trim(FConfig.LastMariaDbError);
  StatusBar.ShowHint := True;
  StatusBar.Hint := BuildStatusBarHint(StatusError);

  StatusBar.SimpleText := StatusText;
end;

procedure TMainForm.UpdateStackActionState;
var
  AllRunning: Boolean;
  AnyRunning: Boolean;
begin
  AllRunning := FConfig.ApacheRunning and FConfig.MariaDbRunning;
  AnyRunning := FConfig.ApacheRunning or FConfig.MariaDbRunning;

  StartAllButton.Enabled := not AllRunning;
  StopAllButton.Enabled := AnyRunning;

  if AllRunning then
    SetButtonCaption(StartAllButton, 'Started')
  else
    SetButtonCaption(StartAllButton, 'Start All');

  StylePanelButton(StartAllButton, StartAllButton.Enabled, ButtonSuccessStrongColor, ButtonPositiveColor, clWhite);
  if not StartAllButton.Enabled then
    StartAllButton.Font.Color := RGB(64, 96, 64);
  StylePanelButton(StopAllButton, StopAllButton.Enabled, ButtonDangerStrongColor, ButtonNeutralColor, clWhite);
  exitbutton.Color := $00FFD3D3;
  exitbutton.Font.Color := $00603030;
  SetButtonCaption(exitbutton, 'Exit');
end;

procedure TMainForm.LaunchDashboardIfHealthy;
var
  ErrorMessage: string;
begin
  if not FConfig.OpenDashboardAfterStart then
    Exit;
  if FRuntime.AreWebToolsReady(ErrorMessage) then
    FRuntime.LaunchUrl(Format('http://127.0.0.1:%d/dashboard/', [FConfig.HttpPort]))
  else
    AppendStatus('Dashboard not opened: ' + ErrorMessage);
end;

procedure TMainForm.UpdateVHostActionState;
var
  HasSelection: Boolean;
begin
  HasSelection := SelectedVHostServerName <> '';
  AddVHostButton.Enabled := True;
  OpenVHostButton.Enabled := FConfig.ApacheRunning and HasSelection;
  OpenVHostFolderButton.Enabled := HasSelection;
  BackupProjectButton.Enabled := HasSelection;
  RestoreProjectButton.Enabled := True;
  CopyVHostUrlButton.Enabled := HasSelection;
  DeleteVHostButton.Enabled := HasSelection;
  BackupDatabaseButton.Enabled := FConfig.MariaDbRunning;
  RestoreDatabaseButton.Enabled := FConfig.MariaDbRunning;

  StylePanelButton(AddVHostButton, True, ButtonSuccessStrongColor, ButtonPositiveColor, clWhite);
  StylePanelButton(OpenVHostButton, OpenVHostButton.Enabled, ButtonAccentColor, ButtonNeutralColor);
  StylePanelButton(OpenVHostFolderButton, OpenVHostFolderButton.Enabled, ButtonNeutralColor, ButtonNeutralColor);
  StylePanelButton(BackupProjectButton, BackupProjectButton.Enabled, ButtonNeutralColor, ButtonNeutralColor);
  StylePanelButton(RestoreProjectButton, RestoreProjectButton.Enabled, ButtonNeutralColor, ButtonNeutralColor);
  StylePanelButton(CopyVHostUrlButton, CopyVHostUrlButton.Enabled, ButtonNeutralColor, ButtonNeutralColor);
  StylePanelButton(DeleteVHostButton, DeleteVHostButton.Enabled, ButtonDangerStrongColor, ButtonNeutralColor, clWhite);
  StylePanelButton(BackupDatabaseButton, BackupDatabaseButton.Enabled, ButtonSuccessStrongColor, ButtonPositiveColor, clWhite);
  StylePanelButton(RestoreDatabaseButton, RestoreDatabaseButton.Enabled, ButtonNeutralColor, ButtonNeutralColor);
  VHostGrid.Invalidate;
end;

procedure TMainForm.UpdateVHostEmptyState;
var
  HasVisibleVHosts: Boolean;
  FilterText: string;
  RowIndex: Integer;
begin
  HasVisibleVHosts := False;
  for RowIndex := 1 to VHostGrid.RowCount - 1 do
    if Trim(VHostGrid.Cells[0, RowIndex]) <> '' then
    begin
      HasVisibleVHosts := True;
      Break;
    end;
  VHostGrid.Visible := HasVisibleVHosts;
  VHostGrid.Enabled := HasVisibleVHosts;
  VHostGrid.TabStop := HasVisibleVHosts;
  if not HasVisibleVHosts then
    VHostGrid.Row := 0;
  if Assigned(FVHostEmptyLabel) then
  begin
    FilterText := '';
    if Assigned(FVHostFilterEdit) then
      FilterText := Trim(FVHostFilterEdit.Text);
    FVHostEmptyLabel.Visible := not HasVisibleVHosts;
    FVHostEmptyLabel.Caption := BuildVHostEmptyStateCaption(FilterText);
    FVHostEmptyLabel.ShowHint := not HasVisibleVHosts;
    if HasVisibleVHosts then
      FVHostEmptyLabel.Font.Color := clGrayText
    else
      FVHostEmptyLabel.Font.Color := clBlue;
    if FVHostEmptyLabel.Visible then
      FVHostEmptyLabel.BringToFront;
  end;
  if Assigned(FVHostFilterClearLabel) then
    FVHostFilterClearLabel.Visible := Assigned(FVHostFilterEdit) and (Trim(FVHostFilterEdit.Text) <> '');
end;

procedure TMainForm.VHostGridEnter(Sender: TObject);
begin
  VHostGrid.Invalidate;
end;

procedure TMainForm.VHostGridExit(Sender: TObject);
begin
  VHostGrid.Invalidate;
end;

procedure TMainForm.VHostFilterChanged(Sender: TObject);
begin
  VHostGrid.Row := 0;
  LoadStateIntoUi;
  UpdateVHostActionState;
end;

procedure TMainForm.VHostFilterClearClick(Sender: TObject);
begin
  if Assigned(FVHostFilterEdit) then
    FVHostFilterEdit.Text := '';
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
  if Assigned(FMainStartAllOnLaunchItem) then
    FMainStartAllOnLaunchItem.Checked := FConfig.StartAllOnLaunch;
  if Assigned(FTrayStartAllOnLaunchItem) then
    FTrayStartAllOnLaunchItem.Checked := FConfig.StartAllOnLaunch;

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

procedure TMainForm.StartAllOnLaunchClick(Sender: TObject);
begin
  FConfig.StartAllOnLaunch := not FConfig.StartAllOnLaunch;
  FConfig.Save(FPaths);
  UpdateMenuState;
  if FConfig.StartAllOnLaunch then
    AppendStatus('Start all on launch enabled.')
  else
    AppendStatus('Start all on launch disabled.');
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

procedure TMainForm.OpenVHostEditor(const ServerName: string);
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

  if FolderPath = '' then
    Exit;

  AppendStatus(FRuntime.LaunchTextEditor(FolderPath).Message);
end;

procedure TMainForm.DeleteVHostByName(const ServerName: string);
var
  ResultInfo: TRuntimeActionResult;
  RestartInfo: TRuntimeActionResult;
  VHostManager: IVHostManager;
  Entry: TVHostEntry;
  ConfirmText: string;
begin
  if ServerName = '' then
    Exit;
  if FConfig.ConfirmVHostDelete then
  begin
    ConfirmText := Format('Delete project "%s" and remove its generated vHost config?', [ServerName]);
    if TryGetVHostEntry(ServerName, Entry) then
      ConfirmText := ConfirmText + sLineBreak + sLineBreak +
        'Project folder: ' + Entry.DocumentRoot + sLineBreak +
        'SSL certificate/key files will also be removed if this vHost uses SSL.';
    if MessageDlg(ConfirmText, mtWarning, [mbYes, mbNo], 0) <> mrYes then
      Exit;
  end;

  VHostManager := TServiceLocator.Instance.GetService<IVHostManager>;
  ResultInfo := VHostManager.DeleteVHost(ServerName);
  AppendStatus(ResultInfo.Message);
  if ResultInfo.Success and FConfig.ApacheRunning then
  begin
    RestartInfo := FRuntime.RestartApache;
    AppendStatus('Apache reload after VHost delete: ' + RestartInfo.Message);
  end;
  if ResultInfo.Success then
    FConfig.Save(FPaths);
  RefreshStatus;
  LoadStateIntoUi;
end;

procedure TMainForm.VHostGridDrawCell(Sender: TObject; ACol, ARow: Integer; CellRect: TRect; State: TGridDrawState);
const
  ActionGap = 4;
  OpenWidth = 36;
  FolderWidth = 36;
  EditorWidth = 36;
  TerminalWidth = 36;
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
  if (ACol < 0) or (ARow < 0) or (ACol >= Grid.ColCount) or (ARow >= Grid.RowCount) then
    Exit;
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
    if not ((ACol = 4) and not FConfig.ApacheRunning) then
    begin
      Grid.Canvas.Brush.Color := GridSelectionColor;
      Grid.Canvas.FillRect(CellRect);
    end;
  end;
  if (ACol = Grid.Col) and (ARow = Grid.Row) and (Grid.Focused or (gdFocused in State)) then
  begin
    Grid.Canvas.Pen.Color := GridSelectionColor;
    Grid.Canvas.Pen.Width := 1;
    Grid.Canvas.Brush.Style := bsClear;
    Grid.Canvas.Rectangle(CellRect);
    Grid.Canvas.Brush.Style := bsSolid;
  end;

  if ACol < 4 then
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
  ButtonRect := System.Types.Rect(ActionLeft, CellRect.Top + 4, ActionLeft + EditorWidth, CellRect.Bottom - 4);
  Grid.Canvas.Brush.Color := ButtonAccentColor;
  Grid.Canvas.RoundRect(ButtonRect.Left, ButtonRect.Top, ButtonRect.Right, ButtonRect.Bottom, 8, 8);
  DrawIconInRect(Grid.Canvas, 'code', ButtonRect, 16);

  Inc(ActionLeft, EditorWidth + ActionGap);
  ButtonRect := System.Types.Rect(ActionLeft, CellRect.Top + 4, ActionLeft + TerminalWidth, CellRect.Bottom - 4);
  Grid.Canvas.Brush.Color := ButtonAccentColor;
  Grid.Canvas.RoundRect(ButtonRect.Left, ButtonRect.Top, ButtonRect.Right, ButtonRect.Bottom, 8, 8);
  DrawIconInRect(Grid.Canvas, 'terminal', ButtonRect, 16);

  Inc(ActionLeft, TerminalWidth + ActionGap);
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
  EditorWidth = 36;
  TerminalWidth = 36;
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
  EditorLeft: Integer;
  TerminalLeft: Integer;
  DeleteLeft: Integer;
  SslLeft: Integer;
  VHostEntry: TVHostEntry;
begin
  Grid := Sender as TStringGrid;
  GridCoord := Grid.MouseCoord(X, Y);
  if (GridCoord.X < 0) or (GridCoord.Y < 0) or (GridCoord.X >= Grid.ColCount) or (GridCoord.Y >= Grid.RowCount) then
    Exit;
  if (GridCoord.Y <= 0) or (GridCoord.X <> 4) then
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
  EditorLeft := FolderLeft + FolderWidth + ActionGap;
  TerminalLeft := EditorLeft + EditorWidth + ActionGap;
  DeleteLeft := TerminalLeft + TerminalWidth + ActionGap;
  SslLeft := DeleteLeft + DeleteWidth + ActionGap;
  if not TryGetVHostEntry(ServerName, VHostEntry) then
    Exit;

  if not FConfig.ApacheRunning and (RelativeX >= OpenLeft) and (RelativeX < (OpenLeft + OpenWidth)) then
    Exit;

  if (RelativeX >= OpenLeft) and (RelativeX < (OpenLeft + OpenWidth)) then
    OpenVHostUrl(ServerName)
  else if (RelativeX >= FolderLeft) and (RelativeX < (FolderLeft + FolderWidth)) then
    OpenVHostFolder(ServerName)
  else if (RelativeX >= EditorLeft) and (RelativeX < (EditorLeft + EditorWidth)) then
    OpenVHostEditor(ServerName)
  else if (RelativeX >= TerminalLeft) and (RelativeX < (TerminalLeft + TerminalWidth)) then
    OpenVHostTerminalClick(Sender)
  else if (RelativeX >= DeleteLeft) and (RelativeX < (DeleteLeft + DeleteWidth)) then
    DeleteVHostByName(ServerName)
  else if VHostEntry.EnableSsl and (RelativeX >= SslLeft) and (RelativeX < (SslLeft + SslWidth)) then
    RefreshVHostSslClick(Sender)
  else
    Exit;
end;

procedure TMainForm.VHostGridKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
var
  ActionName: string;
begin
  ActionName := DescribeVHostGridKeyboardAction(Key, Shift);
  if ActionName = '' then
    Exit;

  if ActionName = 'open' then
    OpenVHostClick(Sender)
  else if ActionName = 'folder' then
    OpenVHostFolderClick(Sender)
  else if ActionName = 'terminal' then
    OpenVHostTerminalClick(Sender)
  else if ActionName = 'copy' then
    CopyVHostUrlClick(Sender)
  else if ActionName = 'delete' then
    DeleteVHostClick(Sender);
  Key := 0;
end;

procedure TMainForm.SaveConfigClick(Sender: TObject);
begin
  if not SaveUiIntoState then
    Exit;
  FConfig.Save(FPaths);
  FRuntime.GenerateAllConfigs;
  AppendStatus('Configuration saved and generated.');
  RefreshStatus;
end;

procedure TMainForm.ApacheStartClick(Sender: TObject);
begin
  if not SaveUiIntoState then
    Exit;
  FConfig.Save(FPaths);
  ApacheStartButton.Enabled := False;
  ApacheStopButton.Enabled := False;
  ApacheRestartButton.Enabled := False;
  TThread.CreateAnonymousThread(
    procedure
    var
      ResultInfo: TRuntimeActionResult;
    begin
      ResultInfo := FRuntime.StartApache;
      TThread.Queue(nil, TThreadProcedure(
        procedure
        begin
          AppendStatus(ResultInfo.Message);
          if ResultInfo.Success then
            AppendStatus('Apache started.');
          FConfig.Save(FPaths);
          RefreshStatus;
          ApacheStartButton.Enabled := True;
          ApacheStopButton.Enabled := True;
          ApacheRestartButton.Enabled := True;
          if ResultInfo.Success and FConfig.OpenDashboardAfterStart then
            LaunchDashboardIfHealthy;
        end));
    end).Start;
end;

procedure TMainForm.ApacheStopClick(Sender: TObject);
begin
  FStatusRefreshTimer.Enabled := False;
  ApacheStartButton.Enabled := False;
  ApacheStopButton.Enabled := False;
  ApacheRestartButton.Enabled := False;
  TThread.CreateAnonymousThread(
    procedure
    var
      ResultInfo: TRuntimeActionResult;
    begin
      ResultInfo := FRuntime.StopApache;
      TThread.Queue(nil, TThreadProcedure(
        procedure
        begin
          try
            AppendStatus(ResultInfo.Message);
            FConfig.Save(FPaths);
            RefreshStatus;
          finally
            FStatusRefreshTimer.Enabled := True;
            ApacheStartButton.Enabled := True;
            ApacheStopButton.Enabled := True;
            ApacheRestartButton.Enabled := True;
          end;
        end));
    end).Start;
end;

procedure TMainForm.ApacheRestartClick(Sender: TObject);
begin
  if not SaveUiIntoState then
    Exit;
  FConfig.Save(FPaths);
  ApacheStartButton.Enabled := False;
  ApacheStopButton.Enabled := False;
  ApacheRestartButton.Enabled := False;
  TThread.CreateAnonymousThread(
    procedure
    var
      ResultInfo: TRuntimeActionResult;
    begin
      ResultInfo := FRuntime.RestartApache;
      TThread.Queue(nil, TThreadProcedure(
        procedure
        begin
          AppendStatus('Apache restart: ' + ResultInfo.Message);
          FConfig.Save(FPaths);
          RefreshStatus;
          ApacheStartButton.Enabled := True;
          ApacheStopButton.Enabled := True;
          ApacheRestartButton.Enabled := True;
        end));
    end).Start;
end;

procedure TMainForm.MariaDbStartClick(Sender: TObject);
var
  ResultInfo: TRuntimeActionResult;
begin
  if not SaveUiIntoState then
    Exit;
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
  if not SaveUiIntoState then
    Exit;
  ResultInfo := FRuntime.RestartMariaDb;
  AppendStatus('MariaDB restart: ' + ResultInfo.Message);
  FConfig.Save(FPaths);
  RefreshStatus;
end;

procedure TMainForm.StartButtonClick(Sender: TObject);
var
  MariaResult: TRuntimeActionResult;
begin
  if not SaveUiIntoState then
    Exit;
  RefreshStatus;
  FConfig.Save(FPaths);

  if not FConfig.MariaDbRunning then
  begin
    MariaResult := TStartProgressForm.ExecuteStart(Self, FRuntime, FConfig, FPaths);
    AppendStatus('Start all phase - MariaDB: ' + MariaResult.Message);
  end;

  if not FConfig.ApacheRunning then
  begin
    ShowBusyState('Starting Apache...');
    TThread.CreateAnonymousThread(
      procedure
      var
        ApacheResult: TRuntimeActionResult;
        ErrMsg: string;
      begin
        ErrMsg := '';
        try
          ApacheResult := FRuntime.StartApache;
        except
          on E: Exception do
            ErrMsg := E.Message;
        end;
        
        TThread.Queue(nil, TThreadProcedure(
          procedure
          begin
            HideBusyState();
            if ErrMsg <> '' then
              AppendStatus('Start all phase - Apache exception: ' + ErrMsg)
            else
              AppendStatus('Start all phase - Apache: ' + ApacheResult.Message);
            
            FConfig.Save(FPaths);
            RefreshStatus;
            if FConfig.OpenDashboardAfterStart then
              LaunchDashboardIfHealthy;
          end));
      end).Start;
  end
  else
  begin
    AppendStatus('All services are already running.');
    FConfig.Save(FPaths);
    RefreshStatus;
    if FConfig.OpenDashboardAfterStart then
      LaunchDashboardIfHealthy;
  end;
end;

procedure TMainForm.StopButtonClick(Sender: TObject);
begin
  FStatusRefreshTimer.Enabled := False;
  RefreshStatus;

  if (not FConfig.ApacheRunning) and (not FConfig.MariaDbRunning) then
  begin
    AppendStatus('All services are already stopped.');
    FStatusRefreshTimer.Enabled := True;
    Exit;
  end;

  ShowBusyState('Stopping all services...');
  TThread.CreateAnonymousThread(
    procedure
    var
      ApacheResult: TRuntimeActionResult;
      MariaResult: TRuntimeActionResult;
      WasApacheRunning, WasMariaDbRunning: Boolean;
      ErrMsg: string;
    begin
      WasApacheRunning := FConfig.ApacheRunning;
      WasMariaDbRunning := FConfig.MariaDbRunning;
      ErrMsg := '';
      
      try
        if WasApacheRunning then
          ApacheResult := FRuntime.StopApache;
        if WasMariaDbRunning then
          MariaResult := FRuntime.StopMariaDb;
      except
        on E: Exception do
          ErrMsg := E.Message;
      end;
        
      TThread.Queue(nil, TThreadProcedure(
        procedure
        begin
          HideBusyState();
          
          if ErrMsg <> '' then
            AppendStatus('Error during stop: ' + ErrMsg);
            
          if WasApacheRunning and (ErrMsg = '') then
            AppendStatus('Stop all phase - Apache: ' + ApacheResult.Message);
          if WasMariaDbRunning and (ErrMsg = '') then
            AppendStatus('Stop all phase - MariaDB: ' + MariaResult.Message);
            
          AppendStatus('Stop all completed.');
          FConfig.Save(FPaths);
          RefreshStatus;
          FStatusRefreshTimer.Enabled := True;
        end));
    end).Start;
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
  ErrorMessage: string;
  ResultInfo: TRuntimeActionResult;
begin
  if not FRuntime.AreWebToolsReady(ErrorMessage) then
  begin
    AppendStatus('Dashboard not opened: ' + ErrorMessage);
    Exit;
  end;
  ResultInfo := FRuntime.LaunchUrl(Format('http://127.0.0.1:%d/dashboard/', [StrToIntDef(HttpPortEdit.Text, 8080)]));
  AppendStatus(ResultInfo.Message);
end;

procedure TMainForm.LaunchAdminerClick(Sender: TObject);
var
  ErrorMessage: string;
  ResultInfo: TRuntimeActionResult;
begin
  if not FRuntime.AreWebToolsReady(ErrorMessage) then
  begin
    AppendStatus('Adminer not opened: ' + ErrorMessage);
    Exit;
  end;
  ResultInfo := FRuntime.LaunchAdminer;
  AppendStatus(ResultInfo.Message);
end;

procedure TMainForm.OpenPhpExtensionsClick(Sender: TObject);
var
  RestartInfo: TRuntimeActionResult;
begin
  if TPhpExtensionsForm.Execute(Self, FPaths, FConfig, FRuntime) then
  begin
    if FConfig.ApacheRunning then
    begin
      RestartInfo := FRuntime.RestartApache;
      AppendStatus('Apache reload after PHP extensions: ' + RestartInfo.Message);
    end;
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
var
  RestartInfo: TRuntimeActionResult;
begin
  if TPhpSettingsForm.Execute(Self, FPaths, FConfig, FRuntime) then
  begin
    if FConfig.ApacheRunning then
    begin
      RestartInfo := FRuntime.RestartApache;
      AppendStatus('Apache reload after PHP settings: ' + RestartInfo.Message);
    end;
    LoadStateIntoUi;
    RefreshStatus;
    AppendStatus('PHP settings saved.');
  end;
end;

procedure TMainForm.OpenAppSettingsClick(Sender: TObject);
begin
  if TAppSettingsForm.Execute(Self, FPaths, FConfig, FRuntime) then
  begin
    LoadStateIntoUi;
    RefreshStatus;
    AppendStatus('Application settings saved.');
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


Procedure TMainForm.PhpProfileMenuClick(Sender: TObject);
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
  if not SaveUiIntoState then
    Exit;
  FConfig.Save(FPaths);
  ResultInfo := FRuntime.LaunchTerminal;
  AppendStatus(ResultInfo.Message);
end;

procedure TMainForm.OpenRepoTerminalClick(Sender: TObject);
var
  ResultInfo: TRuntimeActionResult;
begin
  ResultInfo := FRuntime.LaunchTerminalInWorkingDir(FPaths.AppRoot);
  AppendStatus(ResultInfo.Message);
end;

procedure TMainForm.LaunchComposerClick(Sender: TObject);
var
  ResultInfo: TRuntimeActionResult;
begin
  ResultInfo := FRuntime.LaunchComposerInWorkingDir(FPaths.AppRoot);
  AppendStatus(ResultInfo.Message);
end;

procedure TMainForm.LaunchGitClick(Sender: TObject);
var
  ResultInfo: TRuntimeActionResult;
begin
  ResultInfo := FRuntime.LaunchGitInWorkingDir(FPaths.AppRoot);
  AppendStatus(ResultInfo.Message);
end;

procedure TMainForm.LaunchNodeClick(Sender: TObject);
var
  ResultInfo: TRuntimeActionResult;
begin
  ResultInfo := FRuntime.LaunchNodeInWorkingDir(FPaths.AppRoot);
  AppendStatus(ResultInfo.Message);
end;

procedure TMainForm.LaunchWpCliClick(Sender: TObject);
var
  ResultInfo: TRuntimeActionResult;
begin
  ResultInfo := FRuntime.LaunchWpCliInWorkingDir(FPaths.AppRoot);
  AppendStatus(ResultInfo.Message);
end;

procedure TMainForm.LaunchMailpitClick(Sender: TObject);
var
  ResultInfo: TRuntimeActionResult;
begin
  ResultInfo := FRuntime.LaunchMailpit;
  AppendStatus(ResultInfo.Message);
end;

procedure TMainForm.LaunchRedisClick(Sender: TObject);
var
  ResultInfo: TRuntimeActionResult;
begin
  ResultInfo := FRuntime.LaunchRedis;
  AppendStatus(ResultInfo.Message);
end;

procedure TMainForm.LaunchMemcachedClick(Sender: TObject);
var
  ResultInfo: TRuntimeActionResult;
begin
  ResultInfo := FRuntime.LaunchMemcached;
  AppendStatus(ResultInfo.Message);
end;

procedure TMainForm.LaunchNpmClick(Sender: TObject);
var
  ResultInfo: TRuntimeActionResult;
begin
  ResultInfo := FRuntime.LaunchNpmInWorkingDir(FPaths.AppRoot);
  AppendStatus(ResultInfo.Message);
end;

procedure TMainForm.LaunchYarnClick(Sender: TObject);
var
  ResultInfo: TRuntimeActionResult;
begin
  ResultInfo := FRuntime.LaunchYarnInWorkingDir(FPaths.AppRoot);
  AppendStatus(ResultInfo.Message);
end;

procedure TMainForm.LaunchPnpmClick(Sender: TObject);
var
  ResultInfo: TRuntimeActionResult;
begin
  ResultInfo := FRuntime.LaunchPnpmInWorkingDir(FPaths.AppRoot);
  AppendStatus(ResultInfo.Message);
end;

procedure TMainForm.LaunchEditorClick(Sender: TObject);
var
  ResultInfo: TRuntimeActionResult;
begin
  ResultInfo := FRuntime.LaunchEditor;
  AppendStatus(ResultInfo.Message);
end;

procedure TMainForm.StageUpdateClick(Sender: TObject);
var
  StagingDir: string;
  MetadataFileName: string;
  ResultInfo: TRuntimeActionResult;
  PackageManager: TPackageManager;
begin
  if not FUpdateManifestDialog.Execute then
    Exit;
  PackageManager := TPackageManager.Create(FPaths);
  try
    if PackageManager.StageUpdateManifest(FUpdateManifestDialog.FileName, StagingDir, MetadataFileName, ResultInfo.Message) then
    begin
      AppendStatus('Update staged to ' + StagingDir);
      AppendStatus('Staging metadata written to ' + MetadataFileName);
    end
    else
      AppendStatus(ResultInfo.Message);
  finally
    PackageManager.Free;
  end;
end;

procedure TMainForm.CopyDiagnosticReportClick(Sender: TObject);
begin
  Clipboard.AsText := FRuntime.BuildDiagnosticReport;
  AppendStatus('Diagnostic report copied to clipboard.');
end;

procedure TMainForm.CopyActivityLogClick(Sender: TObject);
var
  LogFile: string;
  LogText: string;
  MemoText: string;
begin
  LogFile := TPath.Combine(FPaths.LogsDir, 'activity.log');
  LogText := '';
  if FileExists(LogFile) then
    LogText := TFile.ReadAllText(LogFile, TEncoding.UTF8);
  MemoText := '';
  if Assigned(FActivityMemo) then
    MemoText := FActivityMemo.Text;
  Clipboard.AsText := ChooseActivityLogClipboardText(LogText, MemoText);
  AppendStatus('Activity log copied to clipboard.');
end;

procedure TMainForm.OpenHostsFileClick(Sender: TObject);
var
  HostsFileService: IHostsFileService;
  HostsPath: string;
begin
  HostsFileService := THostsFileService.Create(FPaths, FConfig);
  HostsPath := HostsFileService.HostsFilePath;
  AppendStatus(FRuntime.LaunchTextEditor(HostsPath).Message);
end;

procedure TMainForm.GenerateSslClick(Sender: TObject);
var
  ResultInfo: TRuntimeActionResult;
begin
  var VHostManager := TServiceLocator.Instance.GetService<IVHostManager>;
  ResultInfo := VHostManager.GenerateSslCertificate;
  AppendStatus(ResultInfo.Message);
end;

procedure TMainForm.OpenApacheLogClick(Sender: TObject);
begin
  AppendStatus(FRuntime.LaunchTextEditor(TPath.Combine(FPaths.LogsDir, 'apache-error.log')).Message);
end;

procedure TMainForm.OpenMariaDbLogClick(Sender: TObject);
begin
  AppendStatus(FRuntime.LaunchTextEditor(TPath.Combine(FPaths.LogsDir, 'mariadb-error.log')).Message);
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
var
  LogFile: string;
begin
  LogFile := TPath.Combine(FPaths.LogsDir, 'activity.log');
  if not FileExists(LogFile) then
  begin
    AppendStatus('Activity log is not available yet.');
    Exit;
  end;
  AppendStatus(FRuntime.LaunchTextEditor(LogFile).Message);
end;

procedure TMainForm.AddVHostClick(Sender: TObject);
var
  DialogResult: TVHostDialogResult;
begin
  if FIsBusy then Exit;

  DialogResult := TVHostDialog.Execute(Self, FPaths.VHostsDir, '', '', '', EnableSslCheck.Checked);
  if not DialogResult.Accepted then
    Exit;

  ShowBusyState('Adding Virtual Host, please wait...');

  TThread.CreateAnonymousThread(
    procedure
    var
      ResultInfo: TRuntimeActionResult;
      RestartInfo: TRuntimeActionResult;
      VHostManager: IVHostManager;
      ApacheWasRunning: Boolean;
    begin
      VHostManager := TServiceLocator.Instance.GetService<IVHostManager>;
      ApacheWasRunning := FConfig.ApacheRunning;

      ResultInfo := VHostManager.AddVHost(
        DialogResult.ServerName,
        DialogResult.DocumentRoot,
        DialogResult.ServerAliases,
        DialogResult.EnableSsl);

      if ResultInfo.Success and ApacheWasRunning then
        RestartInfo := FRuntime.RestartApache;

      TThread.Queue(nil, TThreadProcedure(
        procedure
        begin
          HideBusyState();
          AppendStatus(ResultInfo.Message);
          if ResultInfo.Success and ApacheWasRunning then
            AppendStatus('Apache reload after VHost add: ' + RestartInfo.Message);
          
          FConfig.Save(FPaths);
          RefreshStatus;
          LoadStateIntoUi;
        end));
    end).Start;
end;

procedure TMainForm.SetMariaDbRootPasswordClick(Sender: TObject);
var
  DialogResult: TPasswordDialogResult;
begin
  if FIsBusy then Exit;

  DialogResult := TPasswordDialog.Execute(Self, 'Set MariaDB Root Password', 'New password');
  if not DialogResult.Accepted then
    Exit;

  ShowBusyState('Setting MariaDB root password...');

  TThread.CreateAnonymousThread(
    procedure
    var
      ResultInfo: TRuntimeActionResult;
    begin
      ResultInfo := FRuntime.SetMariaDbRootPassword(DialogResult.Password);
      
      TThread.Queue(nil, TThreadProcedure(
        procedure
        begin
          HideBusyState();
          AppendStatus(ResultInfo.Message);
          if ResultInfo.Success then
            FConfig.Save(FPaths);
          RefreshStatus;
        end));
    end).Start;
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

procedure TMainForm.OpenVHostTerminalClick(Sender: TObject);
var
  ServerName: string;
  Entry: TVHostEntry;
  ResultInfo: TRuntimeActionResult;
begin
  ServerName := SelectedVHostServerName;
  if ServerName = '' then
    Exit;
  if not TryGetVHostEntry(ServerName, Entry) then
  begin
    AppendStatus('Selected vHost not found.');
    Exit;
  end;
  ResultInfo := FRuntime.LaunchTerminalInWorkingDir(Entry.DocumentRoot);
  AppendStatus('VHost terminal: ' + ResultInfo.Message);
end;

procedure TMainForm.BackupProjectClick(Sender: TObject);
var
  ServerName: string;
begin
  if FIsBusy then
    Exit;

  ServerName := SelectedVHostServerName;
  if ServerName = '' then
    Exit;

  ShowBusyState('Backing up project, please wait...');

  TThread.CreateAnonymousThread(
    procedure
    var
      BackupDirectory: string;
      ResultInfo: TRuntimeActionResult;
      BackupService: IProjectBackupService;
    begin
      BackupService := TServiceLocator.Instance.GetService<IProjectBackupService>;
      ResultInfo := BackupService.BackupProject(ServerName, BackupDirectory);

      TThread.Queue(nil, TThreadProcedure(
        procedure
        begin
          HideBusyState();
          AppendStatus(ResultInfo.Message);
        end));
    end).Start;
end;

procedure TMainForm.RestoreProjectClick(Sender: TObject);
var
  ManifestFileName: string;
  ManifestJsonValue: TJSONValue;
  ManifestJsonObject: TJSONObject;
  DialogResult: TVHostDialogResult;
  DefaultServerName: string;
  DefaultDocumentRoot: string;
  DefaultAliases: string;
  DefaultEnableSsl: Boolean;
begin
  if FIsBusy then
    Exit;

  if not FProjectBackupManifestDialog.Execute then
    Exit;
  ManifestFileName := FProjectBackupManifestDialog.FileName;

  ManifestJsonValue := TJSONObject.ParseJSONValue(TFile.ReadAllText(ManifestFileName, TEncoding.UTF8));
  try
    if not (ManifestJsonValue is TJSONObject) then
    begin
      AppendStatus('Project restore failed: backup manifest must be a JSON object.');
      Exit;
    end;
    ManifestJsonObject := TJSONObject(ManifestJsonValue);
    DefaultServerName := Trim(ManifestJsonObject.GetValue<string>('serverName', ''));
    DefaultDocumentRoot := Trim(ManifestJsonObject.GetValue<string>('documentRoot', ''));
    DefaultDocumentRoot := StringReplace(DefaultDocumentRoot, '/', '\', [rfReplaceAll]);
    if (DefaultDocumentRoot <> '') and not TPath.IsPathRooted(DefaultDocumentRoot) then
      DefaultDocumentRoot := TPath.Combine(FPaths.AppRoot, DefaultDocumentRoot);
    DefaultAliases := Trim(ManifestJsonObject.GetValue<string>('serverAliases', ''));
    DefaultEnableSsl := ManifestJsonObject.GetValue<Boolean>('enableSsl', False);
  finally
    ManifestJsonValue.Free;
  end;

  DialogResult := TVHostDialog.Execute(Self, FPaths.VHostsDir, DefaultServerName,
    DefaultDocumentRoot, DefaultAliases, DefaultEnableSsl);
  if not DialogResult.Accepted then
    Exit;

  ShowBusyState('Restoring project, please wait...');

  TThread.CreateAnonymousThread(
    procedure
    var
      RestoredServerName: string;
      ResultInfo: TRuntimeActionResult;
      RestartInfo: TRuntimeActionResult;
      BackupService: IProjectBackupService;
      ApacheWasRunning: Boolean;
    begin
      BackupService := TServiceLocator.Instance.GetService<IProjectBackupService>;
      ApacheWasRunning := FConfig.ApacheRunning;
      ResultInfo := BackupService.RestoreProject(
        ManifestFileName,
        DialogResult.ServerName,
        DialogResult.DocumentRoot,
        DialogResult.ServerAliases,
        DialogResult.EnableSsl,
        RestoredServerName);

      if ResultInfo.Success and ApacheWasRunning then
        RestartInfo := FRuntime.RestartApache;

      TThread.Queue(nil, TThreadProcedure(
        procedure
        begin
          HideBusyState();
          AppendStatus(ResultInfo.Message);
          if ResultInfo.Success and ApacheWasRunning then
            AppendStatus('Apache reload after project restore: ' + RestartInfo.Message);
          if ResultInfo.Success then
            FConfig.Save(FPaths);
          RefreshStatus;
          LoadStateIntoUi;
        end));
    end).Start;
end;

procedure TMainForm.BackupDatabaseClick(Sender: TObject);
begin
  if FIsBusy then
    Exit;

  ShowBusyState('Backing up databases, please wait...');

  TThread.CreateAnonymousThread(
    procedure
    var
      BackupDirectory: string;
      ResultInfo: TRuntimeActionResult;
      BackupService: IDatabaseBackupService;
    begin
      BackupService := TServiceLocator.Instance.GetService<IDatabaseBackupService>;
      ResultInfo := BackupService.BackupAllDatabases(BackupDirectory);

      TThread.Queue(nil, TThreadProcedure(
        procedure
        begin
          HideBusyState();
          AppendStatus(ResultInfo.Message);
      end));
    end).Start;
end;

procedure TMainForm.RestoreDatabaseClick(Sender: TObject);
var
  BackupInfoText: string;
  BackupLines: TArray<string>;
  BackupLine: string;
  BackupKey: string;
  BackupValue: string;
  I: Integer;
  EqualsPos: Integer;
  BackupDirectory: string;
  DumpFileName: string;
  Checksum: string;
  PreviewText: string;
begin
  if FIsBusy then
    Exit;

  if not FDatabaseBackupInfoDialog.Execute then
    Exit;

  BackupDirectory := ExtractFileDir(FDatabaseBackupInfoDialog.FileName);
  BackupInfoText := TFile.ReadAllText(FDatabaseBackupInfoDialog.FileName, TEncoding.UTF8);
  BackupLines := BackupInfoText.Split([sLineBreak], TStringSplitOptions.ExcludeEmpty);
  DumpFileName := '';
  Checksum := '';
  for I := Low(BackupLines) to High(BackupLines) do
  begin
    BackupLine := Trim(BackupLines[I]);
    if BackupLine = '' then
      Continue;
    BackupKey := '';
    BackupValue := '';
    EqualsPos := Pos('=', BackupLine);
    if EqualsPos <= 1 then
    begin
      AppendStatus('Database restore failed: invalid backup manifest line.');
      Exit;
    end;
    BackupKey := LowerCase(Trim(Copy(BackupLine, 1, EqualsPos - 1)));
    BackupValue := Trim(Copy(BackupLine, EqualsPos + 1, MaxInt));
    if BackupKey = 'dumpfile' then
      DumpFileName := BackupValue
    else if BackupKey = 'sha256' then
      Checksum := BackupValue;
  end;
  if (DumpFileName = '') or (Checksum = '') then
  begin
    AppendStatus('Database restore failed: backup manifest is incomplete.');
    Exit;
  end;

  PreviewText := 'Restore preview:' + sLineBreak +
    'Backup folder: ' + BackupDirectory + sLineBreak +
    'Manifest: ' + FDatabaseBackupInfoDialog.FileName + sLineBreak +
    'SQL dump: ' + TPath.Combine(BackupDirectory, DumpFileName) + sLineBreak +
    'SHA-256: ' + Checksum + sLineBreak + sLineBreak +
    'This will replace the current MariaDB data with the selected backup.' + sLineBreak +
    'All current databases will be overwritten. Continue?';

  if MessageDlg(PreviewText,
    mtWarning, [mbYes, mbNo], 0) <> mrYes then
    Exit;

  ShowBusyState('Restoring databases, please wait...');

  TThread.CreateAnonymousThread(
    procedure
    var
      ResultInfo: TRuntimeActionResult;
      BackupService: IDatabaseBackupService;
    begin
      BackupService := TServiceLocator.Instance.GetService<IDatabaseBackupService>;
      ResultInfo := BackupService.RestoreDatabase(FDatabaseBackupInfoDialog.FileName);

      TThread.Queue(nil, TThreadProcedure(
        procedure
        begin
          HideBusyState();
          AppendStatus(ResultInfo.Message);
          RefreshStatus;
          LoadStateIntoUi;
        end));
    end).Start;
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

  var VHostManager := TServiceLocator.Instance.GetService<IVHostManager>;
  ResultInfo := VHostManager.RefreshVHostSslCertificate(ServerName);
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

procedure TMainForm.FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if (ssCtrl in Shift) and (Key = Ord('F')) then
  begin
    Key := 0;
    if Assigned(FVHostFilterEdit) then
      FVHostFilterEdit.SetFocus;
    Exit;
  end;
  if Key = VK_ESCAPE then
  begin
    Key := 0;
    if Assigned(FVHostFilterEdit) and FVHostFilterEdit.Focused and (Trim(FVHostFilterEdit.Text) <> '') then
    begin
      FVHostFilterEdit.Clear;
      Exit;
    end;
    ExitButtonClick(Sender);
  end;
end;

procedure TMainForm.VHostEmptyLabelClick(Sender: TObject);
begin
  AddVHostClick(Sender);
end;

procedure TMainForm.VHostFilterKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if DescribeVHostFilterKeyAction(Key, FVHostFilterEdit.Text) = 'clear' then
  begin
    Key := 0;
    FVHostFilterEdit.Clear;
    Exit;
  end;
  if DescribeVHostFilterKeyAction(Key, FVHostFilterEdit.Text) = 'exit' then
  begin
    Key := 0;
    ActiveControl := nil;
  end;
end;

procedure TMainForm.EditPhpIniClick(Sender: TObject);
begin
  if FileExists(FPaths.ActivePhpIniFile) then
    AppendStatus(FRuntime.LaunchTextEditor(FPaths.ActivePhpIniFile).Message)
  else
    ShowMessage('Config file not found. Have you saved the configuration?');
end;

procedure TMainForm.EditHttpdConfClick(Sender: TObject);
begin
  if FileExists(FPaths.ApacheHttpdConfFile) then
    AppendStatus(FRuntime.LaunchTextEditor(FPaths.ApacheHttpdConfFile).Message)
  else
    ShowMessage('Config file not found. Have you saved the configuration?');
end;

procedure TMainForm.EditMariaDbIniClick(Sender: TObject);
begin
  if FileExists(FPaths.MariaDbIniFile) then
    AppendStatus(FRuntime.LaunchTextEditor(FPaths.MariaDbIniFile).Message)
  else
    ShowMessage('Config file not found. Have you saved the configuration?');
end;

procedure TMainForm.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  FStatusRefreshTimer.Enabled := False;
  if not SaveUiIntoState then
  begin
    CanClose := False;
    FStatusRefreshTimer.Enabled := True;
    Exit;
  end;
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

initialization
  RegisterClass(TActivityMemo);

end.
