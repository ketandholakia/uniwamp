unit Ui.UniWamp.MainForm;

interface

uses
  Winapi.Windows,
  Winapi.Messages,
  System.Classes,
  System.Generics.Collections,
  System.SysUtils,
  System.Types,
  Vcl.Controls,
  Vcl.ExtCtrls,
  Vcl.Forms,
  Vcl.Graphics,
  Vcl.Grids,
  Vcl.Menus,
  Vcl.StdCtrls,
  Vcl.ComCtrls,
  Vcl.Clipbrd,
  Core.UniWamp.Config,
  Core.UniWamp.Paths,
  Core.UniWamp.Runtime;

type
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
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure BuildMenus;
    procedure PhpVersionMenuClick(Sender: TObject);
    procedure PhpProfileMenuClick(Sender: TObject);
    procedure LoadStateIntoUi;
    procedure SaveUiIntoState;
    procedure AppendStatus(const Text: string);
    procedure RefreshStatus;
    procedure UpdateHeaderStateColors;
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

constructor TMainForm.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  OnCreate := FormCreate;
  OnShow := FormShow;
  Caption := 'UniWamp';
 // Width := 1180;
 // Height := 760;
  Position := poScreenCenter;
  FPaths := TAppPaths.Detect;
  EnsurePortableLayout(FPaths);
  FConfig := TUniWampConfig.Create;
  FConfig.LoadOrCreate(FPaths);
  FRuntime := TUniWampRuntime.Create(FPaths, FConfig);
  FMainPhpVersionItems := TList<TMenuItem>.Create;
  FMainPhpProfileItems := TList<TMenuItem>.Create;
  FLastHttpPortChecked := -1;
  FLastHttpsPortChecked := -1;
  FLastDbPortChecked := -1;
  FLastActivityLogWriteTime := 0;
  FRuntime.SyncPhpVersions;
  FRuntime.SyncNodeVersions;
  FStatusRefreshTimer := TTimer.Create(Self);
  FStatusRefreshTimer.Interval := 4000;
  FStatusRefreshTimer.OnTimer := StatusRefreshTimer;
  FStatusRefreshTimer.Enabled := True;
end;

procedure TMainForm.FormCreate(Sender: TObject);
begin
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
  BuildMenus;
  Menu := FMainMenu;
  if HandleAllocated then
    DrawMenuBar(Handle);
  VHostGrid.DefaultDrawing := False;
  VHostGrid.OnDrawCell := VHostGridDrawCell;
  VHostGrid.OnMouseUp := VHostGridMouseUp;
  VHostGrid.ColCount := 4;
  VHostGrid.FixedRows := 1;
  VHostGrid.RowCount := 2;
  VHostGrid.Cells[0, 0] := 'Site Name';
  VHostGrid.Cells[1, 0] := 'Document Path';
  VHostGrid.Cells[2, 0] := 'URL';
  VHostGrid.Cells[3, 0] := 'Actions';
  VHostGrid.ColWidths[0] := 110;
  VHostGrid.ColWidths[1] := 260;
  VHostGrid.ColWidths[2] := 140;
  VHostGrid.ColWidths[3] := 170;
  LoadStateIntoUi;
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
  FActivityCard.Height := 63;
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
  FActivityMemo.Height := 29;
  FActivityMemo.ReadOnly := True;
  FActivityMemo.ScrollBars := ssVertical;
  FActivityMemo.WordWrap := False;
  FActivityMemo.BorderStyle := bsNone;
  FActivityMemo.Color := RGB(250, 252, 255);
  FActivityMemo.Font.Name := 'Consolas';
  FActivityMemo.Font.Size := 9;
  FActivityMemo.TabStop := False;
  FActivityMemo.Anchors := [akLeft, akTop, akRight, akBottom];
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

  MenuItem := AddItem(FMainMenu.Items, '&File');
  Item := AddItem(MenuItem, '&Save Config', SaveConfigClick);
  Item.ShortCut := ShortCut(Ord('S'), [ssCtrl]);
  Item := AddItem(MenuItem, '&Generate SSL', GenerateSslClick);
  Item.ShortCut := ShortCut(Ord('G'), [ssCtrl, ssShift]);
  AddItem(MenuItem, '-');
  FMainAutoStartItem := AddItem(MenuItem, 'Start with &Windows', AutoStartClick);
  FMainAutoStartItem.AutoCheck := True;
  FMainExitItem := AddItem(MenuItem, 'E&xit', ExitButtonClick);

  MenuItem := AddItem(FMainMenu.Items, '&Apache');
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
  FMainWindowToggleItem := AddItem(MenuItem, 'Hide Window', ToggleWindowClick);

  FTrayMenu := TPopupMenu.Create(Self);
  FTrayMenu.OnPopup := TrayMenuPopup;

  FTrayWindowToggleItem := AddItem(FTrayMenu.Items, '&Show Window', ToggleWindowClick);
  AddItem(FTrayMenu.Items, '-');
  Item := AddItem(FTrayMenu.Items, '&Home', LaunchSiteClick);
  Item.ShortCut := ShortCut(Ord('H'), [ssCtrl]);
  Item := AddItem(FTrayMenu.Items, '&Dashboard', LaunchDashboardClick);
  Item.ShortCut := ShortCut(Ord('D'), [ssCtrl]);
  AddItem(FTrayMenu.Items, '-');
  Item := AddItem(FTrayMenu.Items, '&Save Config', SaveConfigClick);
  Item.ShortCut := ShortCut(Ord('S'), [ssCtrl]);
  Item := AddItem(FTrayMenu.Items, '&Generate SSL', GenerateSslClick);
  Item.ShortCut := ShortCut(Ord('G'), [ssCtrl, ssShift]);
  FTrayAutoStartItem := AddItem(FTrayMenu.Items, 'Start with &Windows', AutoStartClick);
  FTrayAutoStartItem.AutoCheck := True;
  Item := AddItem(FTrayMenu.Items, '&Terminal', LaunchTerminalClick);
  Item.ShortCut := ShortCut(Ord('T'), [ssCtrl]);
  AddItem(FTrayMenu.Items, '-');
  FTrayStartAllItem := AddItem(FTrayMenu.Items, 'Start &All', StartButtonClick);
  FTrayStartAllItem.ShortCut := ShortCut(VK_F11, []);
  FTrayStopAllItem := AddItem(FTrayMenu.Items, 'S&top All', StopButtonClick);
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
begin
  if FConfig.ApacheRunning then
    HeaderColor := clGreen
  else
    HeaderColor := RGB(255, 140, 0);

  HeaderPanel.Color := HeaderColor;
  Label18.Color := HeaderColor;
  Label19.Color := HeaderColor;
  exitbutton.Color := RGB(255, 206, 206);
end;

procedure TMainForm.UpdateServiceButtonState;
begin
  ApacheStartButton.Enabled := not FConfig.ApacheRunning;
  ApacheStopButton.Enabled := FConfig.ApacheRunning;
  ApacheRestartButton.Enabled := FConfig.ApacheRunning;

  MariaStartButton.Enabled := not FConfig.MariaDbRunning;
  MariaStopButton.Enabled := FConfig.MariaDbRunning;
  MariaRestartButton.Enabled := FConfig.MariaDbRunning;

  if ApacheStartButton.Enabled then
  begin
    ApacheStartButton.Cursor := crHandPoint;
    ApacheStartButton.Color := RGB(224, 247, 222);
    ApacheStartButton.Font.Color := clWindowText;
  end
  else
  begin
    ApacheStartButton.Cursor := crDefault;
    ApacheStartButton.Color := RGB(235, 235, 235);
    ApacheStartButton.Font.Color := clGrayText;
  end;

  if ApacheStopButton.Enabled then
  begin
    ApacheStopButton.Cursor := crHandPoint;
    ApacheStopButton.Color := RGB(255, 224, 224);
    ApacheStopButton.Font.Color := clWindowText;
  end
  else
  begin
    ApacheStopButton.Cursor := crDefault;
    ApacheStopButton.Color := RGB(235, 235, 235);
    ApacheStopButton.Font.Color := clGrayText;
  end;

  if ApacheRestartButton.Enabled then
  begin
    ApacheRestartButton.Cursor := crHandPoint;
    ApacheRestartButton.Color := RGB(255, 242, 204);
    ApacheRestartButton.Font.Color := clWindowText;
  end
  else
  begin
    ApacheRestartButton.Cursor := crDefault;
    ApacheRestartButton.Color := RGB(235, 235, 235);
    ApacheRestartButton.Font.Color := clGrayText;
  end;

  if MariaStartButton.Enabled then
  begin
    MariaStartButton.Cursor := crHandPoint;
    MariaStartButton.Color := RGB(224, 247, 222);
    MariaStartButton.Font.Color := clWindowText;
  end
  else
  begin
    MariaStartButton.Cursor := crDefault;
    MariaStartButton.Color := RGB(235, 235, 235);
    MariaStartButton.Font.Color := clGrayText;
  end;

  if MariaStopButton.Enabled then
  begin
    MariaStopButton.Cursor := crHandPoint;
    MariaStopButton.Color := RGB(255, 224, 224);
    MariaStopButton.Font.Color := clWindowText;
  end
  else
  begin
    MariaStopButton.Cursor := crDefault;
    MariaStopButton.Color := RGB(235, 235, 235);
    MariaStopButton.Font.Color := clGrayText;
  end;

  if MariaRestartButton.Enabled then
  begin
    MariaRestartButton.Cursor := crHandPoint;
    MariaRestartButton.Color := RGB(255, 242, 204);
    MariaRestartButton.Font.Color := clWindowText;
  end
  else
  begin
    MariaRestartButton.Cursor := crDefault;
    MariaRestartButton.Color := RGB(235, 235, 235);
    MariaRestartButton.Font.Color := clGrayText;
  end;
end;

procedure TMainForm.UpdateDashboardLabels;
var
  StatusText: string;
  MariaDbSummary: string;
begin
  StatusText := Format(
    'Apache: %s PID=%d   MariaDB: %s PID=%d   HTTP: %d   PHP: %s / %s   Node: %s   Hosts: %s',
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
      Format('MariaDB: %s PID=%d', [BoolToStr(FConfig.MariaDbRunning, True), FConfig.MariaDbPid]),
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
    startbutton.Caption := 'Started'
  else
    startbutton.Caption := 'Start All';

  if startbutton.Enabled then
  begin
    startbutton.Cursor := crHandPoint;
    startbutton.Color := RGB(46, 160, 67);
    startbutton.Font.Color := clWhite;
  end
  else
  begin
    startbutton.Cursor := crDefault;
    startbutton.Color := RGB(224, 247, 222);
    startbutton.Font.Color := RGB(64, 96, 64);
  end;

  if stopbutton.Enabled then
  begin
    stopbutton.Cursor := crHandPoint;
    stopbutton.Color := RGB(204, 62, 62);
    stopbutton.Font.Color := clWhite;
  end
  else
  begin
    stopbutton.Cursor := crDefault;
    stopbutton.Color := RGB(235, 235, 235);
    stopbutton.Font.Color := clGrayText;
  end;
end;

procedure TMainForm.UpdateVHostActionState;
begin
  OpenVHostButton.Enabled := FConfig.ApacheRunning;
  if FConfig.ApacheRunning then
  begin
    OpenVHostButton.Cursor := crHandPoint;
    OpenVHostButton.Color := 16053492;
    OpenVHostButton.Font.Color := clWindowText;
  end
  else
  begin
    OpenVHostButton.Cursor := crDefault;
    OpenVHostButton.Color := RGB(235, 235, 235);
    OpenVHostButton.Font.Color := clGrayText;
  end;
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
  Grid.Canvas.Brush.Color := clWhite;
  Grid.Canvas.FillRect(CellRect);

  if ARow = 0 then
  begin
    Grid.Canvas.Brush.Color := RGB(236, 241, 247);
    Grid.Canvas.FillRect(CellRect);
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
      Grid.Canvas.Brush.Color := RGB(231, 242, 255);
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
    Grid.Canvas.Brush.Color := RGB(223, 247, 242)
  else
    Grid.Canvas.Brush.Color := RGB(235, 235, 235);
  Grid.Canvas.RoundRect(ButtonRect.Left, ButtonRect.Top, ButtonRect.Right, ButtonRect.Bottom, 8, 8);
  if OpenEnabled then
    Grid.Canvas.Font.Color := clWindowText
  else
    Grid.Canvas.Font.Color := clGrayText;
  DrawText(Grid.Canvas.Handle, PChar('Open'), -1, ButtonRect, DT_CENTER or DT_VCENTER or DT_SINGLELINE);

  Inc(ActionLeft, OpenWidth + ActionGap);
  ButtonRect := System.Types.Rect(ActionLeft, CellRect.Top + 4, ActionLeft + FolderWidth, CellRect.Bottom - 4);
  Grid.Canvas.Brush.Color := RGB(234, 242, 255);
  Grid.Canvas.RoundRect(ButtonRect.Left, ButtonRect.Top, ButtonRect.Right, ButtonRect.Bottom, 8, 8);
  Grid.Canvas.Font.Color := clWindowText;
  DrawText(Grid.Canvas.Handle, PChar('Root'), -1, ButtonRect, DT_CENTER or DT_VCENTER or DT_SINGLELINE);

  Inc(ActionLeft, FolderWidth + ActionGap);
  ButtonRect := System.Types.Rect(ActionLeft, CellRect.Top + 4, ActionLeft + DeleteWidth, CellRect.Bottom - 4);
  Grid.Canvas.Brush.Color := RGB(255, 235, 230);
  Grid.Canvas.RoundRect(ButtonRect.Left, ButtonRect.Top, ButtonRect.Right, ButtonRect.Bottom, 8, 8);
  DrawText(Grid.Canvas.Handle, PChar('Del'), -1, ButtonRect, DT_CENTER or DT_VCENTER or DT_SINGLELINE);

  Inc(ActionLeft, DeleteWidth + ActionGap);
  ButtonRect := System.Types.Rect(ActionLeft, CellRect.Top + 4, ActionLeft + SslWidth, CellRect.Bottom - 4);
  if HasVHostEntry and VHostEntry.EnableSsl then
    Grid.Canvas.Brush.Color := RGB(224, 247, 222)
  else
    Grid.Canvas.Brush.Color := RGB(235, 235, 235);
  Grid.Canvas.RoundRect(ButtonRect.Left, ButtonRect.Top, ButtonRect.Right, ButtonRect.Bottom, 8, 8);
  if HasVHostEntry and VHostEntry.EnableSsl then
    Grid.Canvas.Font.Color := clWindowText
  else
    Grid.Canvas.Font.Color := clGrayText;
  DrawText(Grid.Canvas.Handle, PChar('SSL'), -1, ButtonRect, DT_CENTER or DT_VCENTER or DT_SINGLELINE);
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
