unit Ui.UniWamp.ScriptManagerForm;

interface

uses
  Winapi.Windows,
  Winapi.Messages,
  Core.UniWamp.Config,
  Core.UniWamp.Types,
  Core.UniWamp.Paths,
  Core.UniWamp.VHostManager,
  Core.UniWamp.Interfaces,
  Core.UniWamp.ServiceLocator,
  Core.UniWamp.Runtime,
  Core.UniWamp.ScriptCatalog,
  System.Classes,
  System.Generics.Collections,
  System.Math,
  System.SysUtils,
  System.Threading,
  Vcl.Controls,
  Vcl.ExtCtrls,
  Vcl.Forms,
  Vcl.Graphics,
  Vcl.Grids,
  Vcl.ComCtrls,
  Vcl.StdCtrls;

const
  WM_INIT_SCRIPT_MANAGER = WM_APP + 201;

type
  TScriptManagerForm = class(TForm)
    pnlfooter: TPanel;
    FOutputPanel: TPanel;
    FOutputHeaderPanel: TPanel;
    FOutputTitleLabel: TLabel;
    FOutputMemo: TMemo;
    FFooterPanel: TPanel;
    FInstallButton: TButton;
    FCloseButton: TButton;
    FStatusLabel: TLabel;
  private
    FPaths: TAppPaths;
    FCatalog: TObject;
    FGrid: TStringGrid;
    FSearchEdit: TEdit;
    FCategoryCombo: TComboBox;
    FCmsOnlyCheck: TCheckBox;
    FEcommerceOnlyCheck: TCheckBox;
    FClearFilterButton: TButton;
    FInstalling: Boolean;
    FInitialized: Boolean;
    FViewInitialized: Boolean;
    FVisibleRows: TArray<Integer>;
    FPendingOutputText: string;
    FPendingCompletionMessage: string;
    FPendingCompletionOutput: string;
    FPendingCompletionSuccess: Boolean;
    FKeepInstallOutput: Boolean;
    FProgressBar: TProgressBar;
    FCreateDatabaseCheck: TCheckBox;
    FInstallLogFile: string;
    procedure Populate;
    procedure BindControls;
    procedure PopulateCategoryFilter;
    procedure PopulateGrid;
    procedure SetGridHeader;
    procedure AppendOutput(const Text: string);
    procedure WriteInstallLogLine(const Text: string);
    procedure SyncAppendOutput;
    procedure SyncInstallFinished;
    procedure SetInstalling(const Value: Boolean);
    procedure UpdateStatusText;
    procedure UpdateSelectionDetails;
    procedure ShowSelectedItemDetails;
    procedure DrawBadge(ACanvas: TCanvas; const ARect: TRect; const Text: string;
      BackColor, BorderColor, TextColor: TColor; AlignRight: Boolean = False);
    function BuildItemDetailsText(const Item: TScriptCatalogItem): string;
    function AskProjectName(const DefaultValue: string; out ProjectName: string): Boolean;
    function SelectedCatalogItem(out Item: TScriptCatalogItem): Boolean;
    function ItemMatchesFilters(const Item: TScriptCatalogItem): Boolean;
    function ItemMatchesQuickFilters(const Item: TScriptCatalogItem): Boolean;
    function SelectedCategory: string;
    function GetRowItemIndex(const Row: Integer): Integer;
    function GetInstallMethodText(const Item: TScriptCatalogItem): string;
    function IsEcommerceCategory(const Category: string): Boolean;
    function ResolveProjectDocumentRoot(const ProjectPath: string; out RelativeRoot: string): string;
    procedure InstallSelectedAsync(const Item: TScriptCatalogItem; const ProjectName: string;
      Config: TUniWampConfig);
  protected
    procedure Loaded; override;
    procedure WmInitScriptManager(var Message: TMessage); message WM_INIT_SCRIPT_MANAGER;
  public
    constructor Create(AOwner: TComponent; const Paths: TAppPaths); reintroduce;
    destructor Destroy; override;
    class procedure Execute(AOwner: TComponent; const Paths: TAppPaths); static;
  published
    procedure InstallClick(Sender: TObject);
    procedure CloseClick(Sender: TObject);
    procedure GridDblClick(Sender: TObject);
    procedure GridClick(Sender: TObject);
    procedure GridMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure GridSelectCell(Sender: TObject; ACol, ARow: Integer; var CanSelect: Boolean);
    procedure GridDrawCell(Sender: TObject; ACol, ARow: Integer; Rect: TRect; State: TGridDrawState);
    procedure FilterChanged(Sender: TObject);
    procedure ClearFilterClick(Sender: TObject);
    procedure QuickFilterChanged(Sender: TObject);
  end;

implementation

{$R *.dfm}
{$HINTS OFF}

uses
  Core.UniWamp.ScriptEngine,
  Core.UniWamp.Security,
  Winapi.ShellAPI,
  System.Types,
  System.IOUtils,
  System.StrUtils,
  System.UITypes,
  Vcl.Dialogs;

const
  GridHeaderBack = TColor($00EEF1F6);
  GridHeaderText = TColor($00333A45);
  GridRowOdd = clWhite;
  GridRowEven = TColor($00FAFBFD);
  GridRowSelected = TColor($00EAF2FF);
  GridGroupBack = TColor($00E8EDF6);
  GridGroupText = TColor($002A3442);
  BadgeBlueBack = TColor($00EAF2FF);
  BadgeBlueBorder = TColor($00C8D9FF);
  BadgeBlueText = TColor($001F5FD1);
  BadgeGrayBack = TColor($00F2F4F7);
  BadgeGrayBorder = TColor($00D9DEE7);
  BadgeGrayText = TColor($00424C5A);

constructor TScriptManagerForm.Create(AOwner: TComponent; const Paths: TAppPaths);
begin
  inherited Create(AOwner);
  FPaths := Paths;
  FCatalog := TScriptCatalog.LoadFromFile(TPath.Combine(FPaths.AppRoot, 'scripts\catalog.json'));
end;

procedure TScriptManagerForm.Loaded;
begin
  inherited Loaded;
  if FInitialized then
    Exit;
  FInitialized := True;
  BindControls;
  if not Assigned(FGrid) or not Assigned(FSearchEdit) or not Assigned(FCategoryCombo) or
     not Assigned(FCmsOnlyCheck) or not Assigned(FEcommerceOnlyCheck) or
     not Assigned(FClearFilterButton) or not Assigned(FInstallButton) or
     not Assigned(FCloseButton) or not Assigned(FStatusLabel) then
    Exit;
  FSearchEdit.OnChange := FilterChanged;
  FCategoryCombo.OnChange := FilterChanged;
  FCmsOnlyCheck.OnClick := QuickFilterChanged;
  FEcommerceOnlyCheck.OnClick := QuickFilterChanged;
  FClearFilterButton.OnClick := ClearFilterClick;
  FGrid.OnClick := GridClick;
  FGrid.OnDblClick := GridDblClick;
  FGrid.OnMouseUp := GridMouseUp;
  FGrid.OnDrawCell := GridDrawCell;
  FGrid.OnSelectCell := GridSelectCell;
  FInstallButton.OnClick := InstallClick;
  FCloseButton.OnClick := CloseClick;

  FProgressBar := TProgressBar.Create(Self);
  FProgressBar.Parent := FStatusLabel.Parent;
  FProgressBar.Align := alBottom;
  FProgressBar.Height := 4;
  FProgressBar.Min := 0;
  FProgressBar.Max := 100;
  FProgressBar.Visible := False;

  if HandleAllocated then
    PostMessage(Handle, WM_INIT_SCRIPT_MANAGER, 0, 0);
end;

procedure TScriptManagerForm.BindControls;
begin
  if not Assigned(FGrid) then
    FGrid := FindComponent('FGrid') as TStringGrid;
  if not Assigned(FOutputMemo) then
    FOutputMemo := FindComponent('FOutputMemo') as TMemo;
  if not Assigned(FStatusLabel) then
    FStatusLabel := FindComponent('FStatusLabel') as TLabel;
  if not Assigned(FSearchEdit) then
    FSearchEdit := FindComponent('FSearchEdit') as TEdit;
  if not Assigned(FCategoryCombo) then
    FCategoryCombo := FindComponent('FCategoryCombo') as TComboBox;
  if not Assigned(FCmsOnlyCheck) then
    FCmsOnlyCheck := FindComponent('FCmsOnlyCheck') as TCheckBox;
  if not Assigned(FEcommerceOnlyCheck) then
    FEcommerceOnlyCheck := FindComponent('FEcommerceOnlyCheck') as TCheckBox;
  if not Assigned(FClearFilterButton) then
    FClearFilterButton := FindComponent('FClearFilterButton') as TButton;
  if not Assigned(FCreateDatabaseCheck) then
    FCreateDatabaseCheck := FindComponent('FCreateDatabaseCheck') as TCheckBox;
  if not Assigned(FInstallButton) then
    FInstallButton := FindComponent('FInstallButton') as TButton;
  if not Assigned(FCloseButton) then
    FCloseButton := FindComponent('FCloseButton') as TButton;
end;

procedure TScriptManagerForm.WmInitScriptManager(var Message: TMessage);
begin
  if FViewInitialized then
    Exit;
  FViewInitialized := True;
  Populate;
end;

destructor TScriptManagerForm.Destroy;
begin
  FCatalog.Free;
  inherited;
end;

class procedure TScriptManagerForm.Execute(AOwner: TComponent; const Paths: TAppPaths);
var
  Form: TScriptManagerForm;
begin
  Form := TScriptManagerForm.Create(AOwner, Paths);
  try
    Form.ShowModal;
  finally
    Form.Free;
  end;
end;

procedure TScriptManagerForm.SetGridHeader;
begin
  FGrid.Cells[0, 0] := 'Name';
  FGrid.Cells[1, 0] := 'Category';
  FGrid.Cells[2, 0] := 'Summary';
  FGrid.Cells[3, 0] := 'License';
  FGrid.Cells[4, 0] := 'Version';
  FGrid.Cells[5, 0] := 'Actions';
end;

procedure TScriptManagerForm.PopulateCategoryFilter;
var
  Catalog: TScriptCatalog;
  Categories: TStringList;
  I: Integer;
  Category: string;
begin
  if not Assigned(FCategoryCombo) then
    Exit;
  Catalog := TScriptCatalog(FCatalog);
  Categories := TStringList.Create;
  try
    Categories.Sorted := True;
    Categories.Duplicates := dupIgnore;
    Categories.CaseSensitive := False;
    for I := 0 to High(Catalog.Items) do
    begin
      Category := Trim(Catalog.Items[I].Category);
      if Category <> '' then
        Categories.Add(Category);
    end;
    FCategoryCombo.Items.BeginUpdate;
    try
      FCategoryCombo.Items.Clear;
      FCategoryCombo.Items.Add('All categories');
      for I := 0 to Categories.Count - 1 do
        FCategoryCombo.Items.Add(Categories[I]);
    finally
      FCategoryCombo.Items.EndUpdate;
    end;
    FCategoryCombo.ItemIndex := 0;
  finally
    Categories.Free;
  end;
end;

function TScriptManagerForm.SelectedCategory: string;
begin
  Result := '';
  if Assigned(FCategoryCombo) and (FCategoryCombo.ItemIndex > 0) then
    Result := Trim(FCategoryCombo.Items[FCategoryCombo.ItemIndex]);
end;

function TScriptManagerForm.ItemMatchesQuickFilters(const Item: TScriptCatalogItem): Boolean;
var
  CmsChecked: Boolean;
  EcommerceChecked: Boolean;
  CategoryLower: string;
begin
  CmsChecked := FCmsOnlyCheck.Checked;
  EcommerceChecked := FEcommerceOnlyCheck.Checked;
  if not CmsChecked and not EcommerceChecked then
    Exit(True);

  CategoryLower := LowerCase(Trim(Item.Category));
  Result := False;
  if CmsChecked and ContainsText(CategoryLower, 'cms') then
    Result := True;
  if EcommerceChecked and ContainsText(CategoryLower, 'e-commerce') then
    Result := True;
end;

function TScriptManagerForm.ItemMatchesFilters(const Item: TScriptCatalogItem): Boolean;
var
  FilterText: string;
begin
  Result := True;
  if not ItemMatchesQuickFilters(Item) then
    Exit(False);
  if SelectedCategory <> '' then
    Result := SameText(Item.Category, SelectedCategory);
  if not Result then
    Exit;

  FilterText := Trim(FSearchEdit.Text);
  if FilterText = '' then
    Exit(True);

  Result :=
    ContainsText(Item.Name, FilterText) or
    ContainsText(Item.Category, FilterText) or
    ContainsText(Item.Summary, FilterText) or
    ContainsText(Item.Version, FilterText) or
    ContainsText(Item.Homepage, FilterText) or
    ContainsText(Item.License, FilterText);
end;

function TScriptManagerForm.IsEcommerceCategory(const Category: string): Boolean;
var
  LowerCategory: string;
begin
  LowerCategory := LowerCase(Trim(Category));
  Result := ContainsText(LowerCategory, 'e-commerce') or ContainsText(LowerCategory, 'commerce');
end;

function TScriptManagerForm.ResolveProjectDocumentRoot(const ProjectPath: string; out RelativeRoot: string): string;
const
  CandidateRoots: array[0..4] of string = ('public', 'upload', 'webroot', 'web', 'www');
var
  Candidate: string;
begin
  Result := ProjectPath;
  RelativeRoot := '';
  for Candidate in CandidateRoots do
    if TDirectory.Exists(TPath.Combine(ProjectPath, Candidate)) then
    begin
      Result := TPath.Combine(ProjectPath, Candidate);
      RelativeRoot := Candidate;
      Exit;
    end;
end;

procedure TScriptManagerForm.PopulateGrid;
var
  Catalog: TScriptCatalog;
  I: Integer;
  Item: TScriptCatalogItem;
  SavedSelection: string;
  SelectedRow: Integer;
  MatchCount: Integer;
begin
  if not Assigned(FGrid) or not Assigned(FStatusLabel) then
    Exit;
  Catalog := TScriptCatalog(FCatalog);
  SavedSelection := '';
  if SelectedCatalogItem(Item) then
    SavedSelection := Item.Id;

  SetLength(FVisibleRows, 0);
  MatchCount := 0;
  for I := 0 to High(Catalog.Items) do
    if ItemMatchesFilters(Catalog.Items[I]) then
    begin
      SetLength(FVisibleRows, Length(FVisibleRows) + 1);
      FVisibleRows[High(FVisibleRows)] := I;
      Inc(MatchCount);
    end;

  FGrid.RowCount := Max(Length(FVisibleRows) + 1, 2);
  SetGridHeader;
  for I := 1 to FGrid.RowCount - 1 do
  begin
    FGrid.Cells[0, I] := '';
    FGrid.Cells[1, I] := '';
    FGrid.Cells[2, I] := '';
    FGrid.Cells[3, I] := '';
    FGrid.Cells[4, I] := '';
    FGrid.Cells[5, I] := '';
  end;

  for I := 0 to High(FVisibleRows) do
  begin
    Item := Catalog.Items[FVisibleRows[I]];
    FGrid.Cells[0, I + 1] := Item.Name;
    FGrid.Cells[1, I + 1] := Item.Category;
    FGrid.Cells[2, I + 1] := Item.Summary;
    FGrid.Cells[3, I + 1] := Item.License;
    FGrid.Cells[4, I + 1] := Item.Version;
    if Trim(Item.Homepage) <> '' then
      FGrid.Cells[5, I + 1] := 'Open'
    else
      FGrid.Cells[5, I + 1] := '-';
  end;

  SelectedRow := -1;
  if SavedSelection <> '' then
    for I := 0 to High(FVisibleRows) do
      if SameText(Catalog.Items[FVisibleRows[I]].Id, SavedSelection) then
      begin
        SelectedRow := I + 1;
        Break;
      end;

  if (SelectedRow < 1) and (Length(FVisibleRows) > 0) then
    SelectedRow := 1;

  if SelectedRow > 0 then
    FGrid.Row := SelectedRow;

  if MatchCount = 0 then
    FStatusLabel.Caption := 'No scripts match the current filters.'
  else
    UpdateStatusText;
  UpdateSelectionDetails;
end;

procedure TScriptManagerForm.Populate;
begin
  BindControls;
  if not Assigned(FGrid) or not Assigned(FStatusLabel) then
    Exit;
  PopulateCategoryFilter;
  PopulateGrid;
  UpdateSelectionDetails;
end;

procedure TScriptManagerForm.FilterChanged(Sender: TObject);
begin
  if FInstalling then
    Exit;
  FKeepInstallOutput := False;
  PopulateGrid;
end;

procedure TScriptManagerForm.QuickFilterChanged(Sender: TObject);
begin
  if FInstalling then
    Exit;
  FKeepInstallOutput := False;
  PopulateGrid;
end;

procedure TScriptManagerForm.ClearFilterClick(Sender: TObject);
begin
  if FInstalling then
    Exit;
  FKeepInstallOutput := False;
  FSearchEdit.Text := '';
  FCategoryCombo.ItemIndex := 0;
  FCmsOnlyCheck.Checked := False;
  FEcommerceOnlyCheck.Checked := False;
  PopulateGrid;
  UpdateSelectionDetails;
end;

procedure TScriptManagerForm.UpdateStatusText;
var
  ItemCount: Integer;
  CategoryCount: TStringList;
  I: Integer;
begin
  ItemCount := 0;
  CategoryCount := TStringList.Create;
  try
    CategoryCount.Sorted := True;
    CategoryCount.Duplicates := dupIgnore;
    for I := 0 to High(FVisibleRows) do
    begin
      Inc(ItemCount);
      CategoryCount.Add(TScriptCatalog(FCatalog).Items[FVisibleRows[I]].Category);
    end;
    if ItemCount = 0 then
      FStatusLabel.Caption := 'No scripts match the current filters.'
    else
      FStatusLabel.Caption := Format('Showing %d scripts across %d categories.', [ItemCount, CategoryCount.Count]);
  finally
    CategoryCount.Free;
  end;
end;

function TScriptManagerForm.GetInstallMethodText(const Item: TScriptCatalogItem): string;
var
  Step: TScriptStep;
begin
  Result := 'Custom';
  if Length(Item.Steps) = 0 then
    Exit;

  for Step in Item.Steps do
  begin
    if SameText(Step.StepType, 'download') then
      Exit('Download');
    if SameText(Step.StepType, 'extract_zip') then
      Exit('ZIP extract');
    if SameText(Step.StepType, 'copy_tree') then
      Exit('Local copy');
    if SameText(Step.StepType, 'create_database') then
      Continue;
    if Pos('wp-cli', LowerCase(Step.Executable)) > 0 then
      Exit('WP-CLI');
    if Pos('composer', LowerCase(Step.Arguments)) > 0 then
      Exit('Composer');
    if Pos('git', LowerCase(Step.Executable)) > 0 then
      Exit('Git clone');
  end;
end;

procedure TScriptManagerForm.DrawBadge(ACanvas: TCanvas; const ARect: TRect; const Text: string;
  BackColor, BorderColor, TextColor: TColor; AlignRight: Boolean);
var
  R: TRect;
  TextRect: TRect;
  Flags: Longint;
begin
  R := ARect;
  InflateRect(R, -8, -5);
  if R.Right - R.Left < 18 then
    Exit;
  if AlignRight then
    R.Left := Max(R.Left, R.Right - 98);
  ACanvas.Brush.Style := bsSolid;
  ACanvas.Brush.Color := BackColor;
  ACanvas.Pen.Color := BorderColor;
  ACanvas.RoundRect(R.Left, R.Top, R.Right, R.Bottom, 12, 12);

  TextRect := R;
  InflateRect(TextRect, -8, -2);
  ACanvas.Font.Color := TextColor;
  ACanvas.Font.Style := [fsBold];
  Flags := DT_VCENTER or DT_SINGLELINE or DT_END_ELLIPSIS;
  if AlignRight then
    Flags := Flags or DT_RIGHT
  else
    Flags := Flags or DT_CENTER;
  DrawText(ACanvas.Handle, PChar(Text), Length(Text), TextRect, Flags);
end;

procedure TScriptManagerForm.UpdateSelectionDetails;
var
  Item: TScriptCatalogItem;
begin
  if not Assigned(FInstallButton) then
    Exit;
  if not SelectedCatalogItem(Item) then
  begin
    FInstallButton.Caption := 'Install selected';
    FInstallButton.Enabled := False;
    if Assigned(FCreateDatabaseCheck) then
    begin
      FCreateDatabaseCheck.Enabled := True;
      FCreateDatabaseCheck.Checked := True;
    end;
    if not FKeepInstallOutput then
      ShowSelectedItemDetails;
    Exit;
  end;

  FInstallButton.Caption := 'Install ' + Item.Name;
  FInstallButton.Enabled := not FInstalling;
  if Assigned(FCreateDatabaseCheck) then
  begin
    FCreateDatabaseCheck.Enabled := Item.RequiresDatabase;
    if not Item.RequiresDatabase then
      FCreateDatabaseCheck.Checked := False
    else if not FCreateDatabaseCheck.Enabled then
      FCreateDatabaseCheck.Checked := True;
  end;
  ShowSelectedItemDetails;
end;

function TScriptManagerForm.BuildItemDetailsText(const Item: TScriptCatalogItem): string;
var
  Lines: TStringList;
begin
  Lines := TStringList.Create;
  try
    Lines.Add(Item.Name);
    Lines.Add(StringOfChar('=', Length(Item.Name)));
    if Trim(Item.Category) <> '' then
      Lines.Add('Category: ' + Item.Category);
    if Trim(Item.Summary) <> '' then
      Lines.Add('Summary: ' + Item.Summary);
    if Trim(Item.Version) <> '' then
      Lines.Add('Package version: ' + Item.Version);
    if Trim(Item.License) <> '' then
      Lines.Add('License: ' + Item.License);
    if Trim(Item.Homepage) <> '' then
      Lines.Add('Homepage: ' + Item.Homepage);
    Lines.Add('Install method: ' + GetInstallMethodText(Item));
    if Item.RequiresDatabase then
      Lines.Add('Database: required for the full install flow')
    else
      Lines.Add('Database: not required by the catalog recipe');

    Lines.Add('');
    Lines.Add('Minimum requirements');
    Lines.Add('--------------------');
    if Trim(Item.Requirements.PhpMinVersion) <> '' then
      Lines.Add('PHP >= ' + Item.Requirements.PhpMinVersion);
    if Trim(Item.Requirements.NodeMinVersion) <> '' then
      Lines.Add('Node.js >= ' + Item.Requirements.NodeMinVersion);
    if Trim(Item.Requirements.MariaDbMinVersion) <> '' then
      Lines.Add('MariaDB >= ' + Item.Requirements.MariaDbMinVersion);
    if Trim(Item.Requirements.ApacheMinVersion) <> '' then
      Lines.Add('Apache >= ' + Item.Requirements.ApacheMinVersion);
    if Trim(Item.Requirements.Notes) <> '' then
      Lines.Add('Notes: ' + Item.Requirements.Notes);
    if (Trim(Item.Requirements.PhpMinVersion) = '') and
       (Trim(Item.Requirements.NodeMinVersion) = '') and
       (Trim(Item.Requirements.MariaDbMinVersion) = '') and
       (Trim(Item.Requirements.ApacheMinVersion) = '') and
       (Trim(Item.Requirements.Notes) = '') then
      Lines.Add('No explicit minimum requirements are declared for this script yet.');

    if Trim(Item.PostInstallNotes) <> '' then
    begin
      Lines.Add('');
      Lines.Add('Post-install notes');
      Lines.Add('------------------');
      Lines.Add(Item.PostInstallNotes);
    end;

    Result := Lines.Text;
  finally
    Lines.Free;
  end;
end;

procedure TScriptManagerForm.ShowSelectedItemDetails;
var
  Item: TScriptCatalogItem;
begin
  if FInstalling or FKeepInstallOutput or not Assigned(FOutputMemo) then
    Exit;
  if SelectedCatalogItem(Item) then
    FOutputMemo.Text := BuildItemDetailsText(Item)
  else
    FOutputMemo.Text := 'Select a script to view its minimum requirements and installation details.';
end;

procedure TScriptManagerForm.AppendOutput(const Text: string);
begin
  FPendingOutputText := Text;
  TThread.Synchronize(nil, SyncAppendOutput);
end;

procedure TScriptManagerForm.WriteInstallLogLine(const Text: string);
var
  Line: string;
begin
  if Trim(FInstallLogFile) = '' then
    Exit;
  Line := FormatDateTime('hh:nn:ss', Now) + '  ' + Text;
  TFile.AppendAllText(FInstallLogFile, Line + sLineBreak, TEncoding.UTF8);
end;

procedure TScriptManagerForm.SyncAppendOutput;
var
  ProgressStr: string;
begin
  if Assigned(FProgressBar) and (Pos('[PROGRESS]', FPendingOutputText) = 1) then
  begin
    FProgressBar.Visible := True;
    ProgressStr := Trim(Copy(FPendingOutputText, 11, MaxInt));
    FProgressBar.Position := StrToIntDef(ProgressStr, FProgressBar.Position);
    Exit;
  end;

  if Assigned(FOutputMemo) then
  begin
    FOutputMemo.Lines.Add(FPendingOutputText);
    FOutputMemo.SelStart := Length(FOutputMemo.Text);
  end;
  WriteInstallLogLine(FPendingOutputText);
end;

procedure TScriptManagerForm.SyncInstallFinished;
begin
  try
    if FPendingCompletionSuccess then
      FStatusLabel.Caption := FPendingCompletionMessage
    else
      MessageDlg(FPendingCompletionMessage + sLineBreak + FPendingCompletionOutput,
        mtError, [mbOK], 0);
  finally
    SetInstalling(False);
    UpdateStatusText;
  end;
end;

procedure TScriptManagerForm.SetInstalling(const Value: Boolean);
begin
  FInstalling := Value;
  if Assigned(FInstallButton) then
    FInstallButton.Enabled := not Value;
  if Assigned(FGrid) then
    FGrid.Enabled := not Value;
  if Assigned(FSearchEdit) then
    FSearchEdit.Enabled := not Value;
  if Assigned(FCategoryCombo) then
    FCategoryCombo.Enabled := not Value;
  if Assigned(FCmsOnlyCheck) then
    FCmsOnlyCheck.Enabled := not Value;
  if Assigned(FEcommerceOnlyCheck) then
    FEcommerceOnlyCheck.Enabled := not Value;
  if Assigned(FClearFilterButton) then
    FClearFilterButton.Enabled := not Value;
  if Assigned(FCreateDatabaseCheck) then
    FCreateDatabaseCheck.Enabled := not Value;

  if Assigned(FProgressBar) then
  begin
    if not Value then
    begin
      FProgressBar.Visible := False;
      FProgressBar.Position := 0;
    end;
  end;

  if not Value then
    UpdateSelectionDetails;
end;

function TScriptManagerForm.AskProjectName(const DefaultValue: string; out ProjectName: string): Boolean;
var
  Value: string;
begin
  Value := DefaultValue;
  Result := InputQuery('Project name', 'Enter the project folder name:', Value);
  if Result then
    ProjectName := Trim(Value);
end;

function TScriptManagerForm.GetRowItemIndex(const Row: Integer): Integer;
begin
  Result := -1;
  if (Row > 0) and (Row <= Length(FVisibleRows)) then
    Result := FVisibleRows[Row - 1];
end;

function TScriptManagerForm.SelectedCatalogItem(out Item: TScriptCatalogItem): Boolean;
var
  Catalog: TScriptCatalog;
  ItemIndex: Integer;
begin
  Result := False;
  Catalog := TScriptCatalog(FCatalog);
  ItemIndex := GetRowItemIndex(FGrid.Row);
  if ItemIndex < 0 then
    Exit;
  if (ItemIndex >= 0) and (ItemIndex <= High(Catalog.Items)) then
  begin
    Item := Catalog.Items[ItemIndex];
    Result := True;
  end;
end;

procedure TScriptManagerForm.InstallSelectedAsync(const Item: TScriptCatalogItem; const ProjectName: string;
  Config: TUniWampConfig);
var
  CreateDatabase: Boolean;
begin
  CreateDatabase := (not Assigned(FCreateDatabaseCheck)) or FCreateDatabaseCheck.Checked;
  TDirectory.CreateDirectory(FPaths.LogsDir);
  FInstallLogFile := TPath.Combine(FPaths.LogsDir,
    Format('install-%s-%s.log', [ProjectName, FormatDateTime('yyyymmdd-hhnnss', Now)]));
  TFile.WriteAllText(FInstallLogFile, '', TEncoding.UTF8);
  FKeepInstallOutput := True;
  SetInstalling(True);
  AppendOutput('Starting install for ' + Item.Name + ' into ' + TPath.Combine(FPaths.WwwDir, ProjectName));
  TThread.CreateAnonymousThread(
    procedure
    var
      Engine: TScriptEngine;
      ExecutionResult: TScriptExecutionResult;
      Runtime: TUniWampRuntime;
      ReloadConfig: TUniWampConfig;
      VHostManager: IVHostManager;
      VHostResult: TRuntimeActionResult;
      VHostEntry: TVHostEntry;
      MariaResult: TRuntimeActionResult;
      ProjectPath: string;
      NeedsDatabase: Boolean;
      Step: TScriptStep;
      InstallSucceeded: Boolean;
      VHostDocumentRoot: string;
      RelativeDocumentRoot: string;
      ApacheWasRunning: Boolean;
      RestartInfo: TRuntimeActionResult;
    begin
      InstallSucceeded := False;
      FPendingCompletionMessage := '';
      FPendingCompletionOutput := '';
      FPendingCompletionSuccess := False;
      ProjectPath := TPath.Combine(FPaths.WwwDir, ProjectName);
      { Only start/require MariaDB if the checkbox is on AND the recipe actually has a
        DB-creation step. Unchecking it skips that step (and everything downstream that
        depends on it) inside Engine.Execute, so there's nothing here that needs MariaDB. }
      NeedsDatabase := False;
      if CreateDatabase then
        for Step in Item.Steps do
          if SameText(Step.StepType, 'create_database') or SameText(Step.StepType, 'create_database_user') then
          begin
            NeedsDatabase := True;
            Break;
          end;

      Runtime := nil;
      try
        Runtime := TUniWampRuntime.Create(FPaths, Config);
        ApacheWasRunning := Runtime.ApacheIsRunning;
        try
          if NeedsDatabase and not Config.MariaDbRunning then
          begin
            AppendOutput('Starting MariaDB for database creation...');
            MariaResult := Runtime.StartMariaDb;
            AppendOutput(MariaResult.Message);
            if not MariaResult.Success then
              raise Exception.Create(MariaResult.Message);
          end;

          Engine := TScriptEngine.Create(FPaths);
          try
            AppendOutput('PHP runtime: ' + Engine.PhpRuntimeDescription);
            if not CreateDatabase then
              AppendOutput('Database creation is disabled for this install — steps that need one will be skipped.');
            ExecutionResult := Engine.Execute(Item, ProjectName,
              procedure(const Text: string)
              begin
                AppendOutput(Text);
              end, CreateDatabase);
          finally
            Engine.Free;
          end;

          if ExecutionResult.Success then
          begin
            AppendOutput(ExecutionResult.Message);
              ReloadConfig := TUniWampConfig.Create;
              try
                ReloadConfig.LoadOrCreate(FPaths);
                VHostManager := TServiceLocator.Instance.GetService<IVHostManager>;
              VHostDocumentRoot := ResolveProjectDocumentRoot(ProjectPath, RelativeDocumentRoot);
              VHostResult := VHostManager.AddVHost(ProjectName, VHostDocumentRoot, '', False);
              AppendOutput(VHostResult.Message);
              if not VHostResult.Success then
              begin
                FPendingCompletionMessage := 'VHost registration failed: ' + VHostResult.Message;
                FPendingCompletionOutput := VHostResult.Message;
                Exit;
              end;
              VHostEntry.ServerName := ProjectName;
              VHostEntry.ServerAliases := '';
              VHostEntry.DocumentRoot := VHostDocumentRoot;
              VHostEntry.EnableSsl := False;
              VHostEntry.SslCertFile := '';
              VHostEntry.SslKeyFile := '';
              ReloadConfig.AddOrUpdateVHost(VHostEntry);
              ReloadConfig.Save(FPaths);
              if ApacheWasRunning then
              begin
                AppendOutput('Restarting Apache to load the new virtual host...');
                RestartInfo := Runtime.RestartApache;
                AppendOutput(RestartInfo.Message);
                if not RestartInfo.Success then
                begin
                  FPendingCompletionMessage := 'Apache restart failed: ' + RestartInfo.Message;
                  FPendingCompletionOutput := RestartInfo.Message;
                  Exit;
                end;
              end;
              AppendOutput('Open the site at: ' + Format('http://%s:%d/',
                [ProjectName, ReloadConfig.HttpPort]));
              if RelativeDocumentRoot <> '' then
                AppendOutput('Document root set to /' + RelativeDocumentRoot + ' for this framework.');
              if CreateDatabase and (Trim(Item.AdminPath) <> '') then
                AppendOutput('Admin login: ' + Format('http://%s:%d%s',
                  [ProjectName, ReloadConfig.HttpPort, Item.AdminPath]));
              if CreateDatabase and (Trim(Item.PostInstallNotes) <> '') then
                AppendOutput(Item.PostInstallNotes);
              FPendingCompletionMessage := ExecutionResult.Message;
              FPendingCompletionSuccess := True;
              InstallSucceeded := True;
            finally
              ReloadConfig.Free;
            end;
          end
          else
          begin
            AppendOutput(ExecutionResult.Message);
            if Trim(ExecutionResult.Output) <> '' then
              AppendOutput(ExecutionResult.Output);
            FPendingCompletionSuccess := False;
            FPendingCompletionMessage := ExecutionResult.Message;
            FPendingCompletionOutput := ExecutionResult.Output;
          end;
        finally
          Runtime.Free;
        end;
      finally
        Config.Free;
      end;

      if InstallSucceeded then
        FPendingCompletionOutput := '';
      TThread.Synchronize(nil, SyncInstallFinished);
    end).Start;
end;

procedure TScriptManagerForm.InstallClick(Sender: TObject);
var
  Item: TScriptCatalogItem;
  ProjectName: string;
  ProjectPath: string;
  PhpDescription: string;
  ErrorMessage: string;
  Engine: TScriptEngine;
  Config: TUniWampConfig;
  CreateDatabase: Boolean;
  InstallMessage: string;
  Preflight: TScriptPreflightResult;
begin
  if FInstalling then
    Exit;
  if not SelectedCatalogItem(Item) then
    Exit;
  ProjectName := Item.Id;
  if not AskProjectName(ProjectName, ProjectName) then
    Exit;
  if ProjectName = '' then
  begin
    MessageDlg('Project name cannot be empty.', mtError, [mbOK], 0);
    Exit;
  end;
  if ProjectName <> ExtractFileName(ProjectName) then
  begin
    MessageDlg('Project name must be a simple folder name, not a path.', mtError, [mbOK], 0);
    Exit;
  end;
  if not ValidateProjectName(ProjectName, ErrorMessage) then
  begin
    MessageDlg(ErrorMessage, mtError, [mbOK], 0);
    Exit;
  end;
  ProjectPath := TPath.Combine(FPaths.WwwDir, ProjectName);
  if TDirectory.Exists(ProjectPath) or TFile.Exists(ProjectPath) then
  begin
    MessageDlg(Format('The project folder already exists: %s', [ProjectPath]),
      mtError, [mbOK], 0);
    Exit;
  end;
  Engine := TScriptEngine.Create(FPaths);
  try
    PhpDescription := Engine.PhpRuntimeDescription;
    Preflight := Engine.ValidateRequirements(Item,
      (not Assigned(FCreateDatabaseCheck)) or FCreateDatabaseCheck.Checked);
  finally
    Engine.Free;
  end;
  if Pos('No PHP runtime was found', PhpDescription) = 1 then
  begin
    MessageDlg(PhpDescription, mtError, [mbOK], 0);
    Exit;
  end;
  if not Preflight.Success then
  begin
    MessageDlg('Pre-install check failed.' + sLineBreak + sLineBreak +
      Preflight.ErrorMessage + sLineBreak + sLineBreak +
      'Detected environment:' + sLineBreak + Preflight.Summary,
      mtError, [mbOK], 0);
    Exit;
  end;
  Config := TUniWampConfig.Create;
  try
    Config.LoadOrCreate(FPaths);
    CreateDatabase := (not Assigned(FCreateDatabaseCheck)) or FCreateDatabaseCheck.Checked;
    if MessageDlg(Format('Install %s into the www folder?', [Item.Name]),
      mtConfirmation, [mbYes, mbNo], 0) <> mrYes then
      Exit;
    InstallMessage := Format('%s will run with %s and install into %s.',
      [Item.Name, PhpDescription, ProjectPath]);
    if Trim(Preflight.Summary) <> '' then
      InstallMessage := InstallMessage + sLineBreak + sLineBreak +
        'Pre-install check passed:' + sLineBreak + Preflight.Summary;
    if Item.RequiresDatabase then
    begin
      if CreateDatabase then
        InstallMessage := InstallMessage + sLineBreak + 'Database creation is enabled for this install.'
      else
        InstallMessage := InstallMessage + sLineBreak + 'Database creation is disabled; database-dependent steps will be skipped.';
    end;
    MessageDlg(InstallMessage, mtInformation, [mbOK], 0);
    FOutputMemo.Clear;
    InstallSelectedAsync(Item, ProjectName, Config);
    Config := nil;
  finally
    Config.Free;
  end;
end;

procedure TScriptManagerForm.GridDblClick(Sender: TObject);
begin
  FKeepInstallOutput := False;
  InstallClick(Sender);
end;

procedure TScriptManagerForm.GridClick(Sender: TObject);
begin
  FKeepInstallOutput := False;
  UpdateSelectionDetails;
end;

procedure TScriptManagerForm.GridMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  Col: Longint;
  Row: Longint;
  Item: TScriptCatalogItem;
begin
  if Button <> mbLeft then
    Exit;
  FGrid.MouseToCell(X, Y, Col, Row);
  if (Col <> 5) or (Row <= 0) then
    Exit;
  if not SelectedCatalogItem(Item) then
    Exit;
  if Trim(Item.Homepage) = '' then
    Exit;
  ShellExecute(Handle, 'open', PChar(Item.Homepage), nil, nil, SW_SHOWNORMAL);
end;

procedure TScriptManagerForm.GridDrawCell(Sender: TObject; ACol, ARow: Integer; Rect: TRect; State: TGridDrawState);
var
  Grid: TStringGrid;
  CellText: string;
  TextRect: TRect;
  Flags: Longint;
begin
  Grid := Sender as TStringGrid;
  CellText := Grid.Cells[ACol, ARow];

  if ARow = 0 then
  begin
    Grid.Canvas.Brush.Color := GridHeaderBack;
    Grid.Canvas.Font.Color := GridHeaderText;
    Grid.Canvas.Font.Style := [fsBold];
  end
  else
  begin
    if gdSelected in State then
      Grid.Canvas.Brush.Color := GridRowSelected
    else if Odd(ARow) then
      Grid.Canvas.Brush.Color := GridRowOdd
    else
      Grid.Canvas.Brush.Color := GridRowEven;
    Grid.Canvas.Font.Color := clWindowText;
    Grid.Canvas.Font.Style := [];
  end;

  Grid.Canvas.FillRect(Rect);
  if ARow > 0 then
  begin
    if ACol = 4 then
    begin
      DrawBadge(Grid.Canvas, Rect, CellText, BadgeGrayBack, BadgeGrayBorder, BadgeGrayText, True);
      Exit;
    end;
    if ACol = 5 then
    begin
      if CellText = 'Open' then
        DrawBadge(Grid.Canvas, Rect, CellText, BadgeBlueBack, BadgeBlueBorder, BadgeBlueText, False);
      Exit;
    end;
  end;
  TextRect := Rect;
  InflateRect(TextRect, -8, -2);
  Flags := DT_LEFT or DT_VCENTER or DT_SINGLELINE or DT_END_ELLIPSIS;
  if ACol in [4, 5] then
    Flags := Flags or DT_RIGHT;
  DrawText(Grid.Canvas.Handle, PChar(CellText), Length(CellText), TextRect, Flags);
end;

procedure TScriptManagerForm.GridSelectCell(Sender: TObject; ACol, ARow: Integer; var CanSelect: Boolean);
begin
  CanSelect := ARow > 0;
end;

procedure TScriptManagerForm.CloseClick(Sender: TObject);
begin
  ModalResult := mrClose;
end;

initialization
  RegisterClass(TPanel);
  RegisterClass(TSplitter);
  RegisterClass(TLabel);
  RegisterClass(TButton);
  RegisterClass(TEdit);
  RegisterClass(TComboBox);
  RegisterClass(TCheckBox);
  RegisterClass(TStringGrid);
  RegisterClass(TMemo);
  RegisterClass(TImage);

end.
