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
  TScriptGridRowKind = (rgHeader, rgItem);

  TScriptGridRow = record
    Kind: TScriptGridRowKind;
    ItemIndex: Integer;
    Category: string;
    ItemCount: Integer;
  end;

  TScriptManagerForm = class(TForm)
  private
    FPaths: TAppPaths;
    FCatalog: TObject;
    FGrid: TStringGrid;
    FOutputMemo: TMemo;
    FStatusLabel: TLabel;
    FSearchEdit: TEdit;
    FCategoryCombo: TComboBox;
    FCmsOnlyCheck: TCheckBox;
    FEcommerceOnlyCheck: TCheckBox;
    FClearFilterButton: TButton;
    FDetailLogoImage: TImage;
    FDetailTitleLabel: TLabel;
    FDetailCategoryLabel: TLabel;
    FDetailCategoryBadge: TPanel;
    FDetailSummaryLabel: TLabel;
    FDetailVersionBadge: TPanel;
    FDetailVersionValue: TLabel;
    FDetailMethodValue: TLabel;
    FDetailInstallButton: TButton;
    FCloseButton: TButton;
    FInstalling: Boolean;
    FInitialized: Boolean;
    FViewInitialized: Boolean;
    FHeaderClickPending: Boolean;
    FVisibleRows: TArray<TScriptGridRow>;
    FCategoryExpanded: TDictionary<string, Boolean>;
    FPendingOutputText: string;
    FPendingCompletionMessage: string;
    FPendingCompletionOutput: string;
    FPendingCompletionSuccess: Boolean;
    FProgressBar: TProgressBar;
    procedure Populate;
    procedure BindControls;
    procedure PopulateCategoryFilter;
    procedure PopulateGrid;
    procedure SyncCategoryExpansion;
    procedure SetGridHeader;
    procedure AppendOutput(const Text: string);
    procedure SyncAppendOutput;
    procedure SyncInstallFinished;
    procedure SetInstalling(const Value: Boolean);
    procedure UpdateStatusText;
    procedure UpdateSelectionDetails;
    procedure UpdateDetailLogo(const Glyph: string; BackColor, TextColor: TColor);
    procedure DrawBadge(ACanvas: TCanvas; const ARect: TRect; const Text: string;
      BackColor, BorderColor, TextColor: TColor; AlignRight: Boolean = False);
    function AskProjectName(const DefaultValue: string; out ProjectName: string): Boolean;
    function SelectedCatalogItem(out Item: TScriptCatalogItem): Boolean;
    function ItemMatchesFilters(const Item: TScriptCatalogItem): Boolean;
    function ItemMatchesQuickFilters(const Item: TScriptCatalogItem): Boolean;
    function SelectedCategory: string;
    function GetRowItemIndex(const Row: Integer): Integer;
    function GetRowKind(const Row: Integer): TScriptGridRowKind;
    function GetRowCategory(const Row: Integer): string;
    function IsCategoryExpanded(const Category: string): Boolean;
    function GetInstallMethodText(const Item: TScriptCatalogItem): string;
    function IsEcommerceCategory(const Category: string): Boolean;
    procedure ToggleCategory(const Category: string);
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
    procedure GridMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure GridClick(Sender: TObject);
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
  FCategoryExpanded := TDictionary<string, Boolean>.Create;
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
     not Assigned(FClearFilterButton) or not Assigned(FDetailInstallButton) or
     not Assigned(FCloseButton) or not Assigned(FStatusLabel) then
    Exit;
  FSearchEdit.OnChange := FilterChanged;
  FCategoryCombo.OnChange := FilterChanged;
  FCmsOnlyCheck.OnClick := QuickFilterChanged;
  FEcommerceOnlyCheck.OnClick := QuickFilterChanged;
  FClearFilterButton.OnClick := ClearFilterClick;
  FGrid.OnClick := GridClick;
  FGrid.OnDblClick := GridDblClick;
  FGrid.OnDrawCell := GridDrawCell;
  FGrid.OnMouseDown := GridMouseDown;
  FGrid.OnSelectCell := GridSelectCell;
  FDetailInstallButton.OnClick := InstallClick;
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
  if not Assigned(FDetailLogoImage) then
    FDetailLogoImage := FindComponent('FDetailLogoImage') as TImage;
  if not Assigned(FDetailTitleLabel) then
    FDetailTitleLabel := FindComponent('FDetailTitleLabel') as TLabel;
  if not Assigned(FDetailCategoryLabel) then
    FDetailCategoryLabel := FindComponent('FDetailCategoryLabel') as TLabel;
  if not Assigned(FDetailCategoryBadge) then
    FDetailCategoryBadge := FindComponent('FDetailCategoryBadge') as TPanel;
  if not Assigned(FDetailSummaryLabel) then
    FDetailSummaryLabel := FindComponent('FDetailSummaryLabel') as TLabel;
  if not Assigned(FDetailVersionBadge) then
    FDetailVersionBadge := FindComponent('FDetailVersionBadge') as TPanel;
  if not Assigned(FDetailVersionValue) then
    FDetailVersionValue := FindComponent('FDetailVersionValue') as TLabel;
  if not Assigned(FDetailMethodValue) then
    FDetailMethodValue := FindComponent('FDetailMethodValue') as TLabel;
  if not Assigned(FDetailInstallButton) then
    FDetailInstallButton := FindComponent('FDetailInstallButton') as TButton;
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
  FCategoryExpanded.Free;
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
  FGrid.Cells[3, 0] := 'Version';
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

procedure TScriptManagerForm.SyncCategoryExpansion;
var
  Catalog: TScriptCatalog;
  I: Integer;
  Category: string;
begin
  if not Assigned(FCategoryExpanded) then
    Exit;
  Catalog := TScriptCatalog(FCatalog);
  for I := 0 to High(Catalog.Items) do
  begin
    Category := Trim(Catalog.Items[I].Category);
    if (Category <> '') and not FCategoryExpanded.ContainsKey(Category) then
      FCategoryExpanded.Add(Category, True);
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

function TScriptManagerForm.IsCategoryExpanded(const Category: string): Boolean;
begin
  Result := True;
  if not FCategoryExpanded.TryGetValue(Category, Result) then
    Result := True;
end;

function TScriptManagerForm.IsEcommerceCategory(const Category: string): Boolean;
var
  LowerCategory: string;
begin
  LowerCategory := LowerCase(Trim(Category));
  Result := ContainsText(LowerCategory, 'e-commerce') or ContainsText(LowerCategory, 'commerce');
end;

procedure TScriptManagerForm.ToggleCategory(const Category: string);
var
  Expanded: Boolean;
begin
  if not FCategoryExpanded.TryGetValue(Category, Expanded) then
    Expanded := True;
  FCategoryExpanded.AddOrSetValue(Category, not Expanded);
  PopulateGrid;
end;

procedure TScriptManagerForm.PopulateGrid;
var
  Catalog: TScriptCatalog;
  CategoryList: TStringList;
  CategoryCounts: TDictionary<string, Integer>;
  VisibleRowCount: Integer;
  I: Integer;
  J: Integer;
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

  CategoryList := TStringList.Create;
  CategoryCounts := TDictionary<string, Integer>.Create;
  try
    CategoryList.Sorted := True;
    CategoryList.Duplicates := dupIgnore;
    CategoryList.CaseSensitive := False;
    for I := 0 to High(Catalog.Items) do
      if ItemMatchesFilters(Catalog.Items[I]) then
      begin
        CategoryList.Add(Catalog.Items[I].Category);
        if CategoryCounts.ContainsKey(Catalog.Items[I].Category) then
          CategoryCounts[Catalog.Items[I].Category] := CategoryCounts[Catalog.Items[I].Category] + 1
        else
          CategoryCounts.Add(Catalog.Items[I].Category, 1);
      end;

    SetLength(FVisibleRows, 0);
    MatchCount := 0;
    for I := 0 to CategoryList.Count - 1 do
    begin
      for J := 0 to High(Catalog.Items) do
      begin
        Item := Catalog.Items[J];
        if not SameText(Item.Category, CategoryList[I]) then
          Continue;
        if not ItemMatchesFilters(Item) then
          Continue;

        if (Length(FVisibleRows) = 0) or not SameText(FVisibleRows[High(FVisibleRows)].Category, Item.Category) then
        begin
          SetLength(FVisibleRows, Length(FVisibleRows) + 1);
          FVisibleRows[High(FVisibleRows)].Kind := rgHeader;
          FVisibleRows[High(FVisibleRows)].ItemIndex := -1;
          FVisibleRows[High(FVisibleRows)].Category := Item.Category;
          if CategoryCounts.ContainsKey(Item.Category) then
            FVisibleRows[High(FVisibleRows)].ItemCount := CategoryCounts[Item.Category]
          else
            FVisibleRows[High(FVisibleRows)].ItemCount := 0;
        end;

        if not IsCategoryExpanded(Item.Category) then
          Continue;

        SetLength(FVisibleRows, Length(FVisibleRows) + 1);
        FVisibleRows[High(FVisibleRows)].Kind := rgItem;
        FVisibleRows[High(FVisibleRows)].ItemIndex := J;
        FVisibleRows[High(FVisibleRows)].Category := Item.Category;
        Inc(MatchCount);
      end;
    end;

    VisibleRowCount := Length(FVisibleRows) + 1;
    if VisibleRowCount < 2 then
      VisibleRowCount := 2;
    FGrid.RowCount := VisibleRowCount;

    for I := 1 to FGrid.RowCount - 1 do
    begin
      FGrid.Cells[0, I] := '';
      FGrid.Cells[1, I] := '';
      FGrid.Cells[2, I] := '';
      FGrid.Cells[3, I] := '';
    end;

    for I := 0 to High(FVisibleRows) do
    begin
      if FVisibleRows[I].Kind = rgHeader then
      begin
        if IsCategoryExpanded(FVisibleRows[I].Category) then
          FGrid.Cells[0, I + 1] := Format('[-] %s (%d)', [FVisibleRows[I].Category, FVisibleRows[I].ItemCount])
        else
          FGrid.Cells[0, I + 1] := Format('[+] %s (%d)', [FVisibleRows[I].Category, FVisibleRows[I].ItemCount]);
        Continue;
      end;

      Item := Catalog.Items[FVisibleRows[I].ItemIndex];
      FGrid.Cells[0, I + 1] := Item.Name;
      FGrid.Cells[1, I + 1] := Item.Category;
      FGrid.Cells[2, I + 1] := Item.Summary;
      FGrid.Cells[3, I + 1] := Item.Version;
    end;

    SelectedRow := -1;
    if SavedSelection <> '' then
    begin
      for I := 0 to High(FVisibleRows) do
      begin
        if (FVisibleRows[I].Kind = rgItem) and SameText(Catalog.Items[FVisibleRows[I].ItemIndex].Id, SavedSelection) then
        begin
          SelectedRow := I + 1;
          Break;
        end;
      end;
    end;
    if SelectedRow < 1 then
    begin
      for I := 0 to High(FVisibleRows) do
        if FVisibleRows[I].Kind = rgItem then
        begin
          SelectedRow := I + 1;
          Break;
        end;
    end;
    if SelectedRow > 0 then
      FGrid.Row := SelectedRow;

    if MatchCount = 0 then
      FStatusLabel.Caption := 'No scripts match the current filters.'
    else
      UpdateStatusText;
    UpdateSelectionDetails;
  finally
    CategoryCounts.Free;
    CategoryList.Free;
  end;
end;

procedure TScriptManagerForm.Populate;
begin
  BindControls;
  if not Assigned(FGrid) or not Assigned(FStatusLabel) then
    Exit;
  PopulateCategoryFilter;
  SyncCategoryExpansion;
  PopulateGrid;
  UpdateSelectionDetails;
end;

procedure TScriptManagerForm.FilterChanged(Sender: TObject);
begin
  if FInstalling then
    Exit;
  PopulateGrid;
end;

procedure TScriptManagerForm.QuickFilterChanged(Sender: TObject);
begin
  if FInstalling then
    Exit;
  PopulateGrid;
end;

procedure TScriptManagerForm.ClearFilterClick(Sender: TObject);
begin
  if FInstalling then
    Exit;
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
      if FVisibleRows[I].Kind = rgItem then
      begin
        Inc(ItemCount);
        CategoryCount.Add(FVisibleRows[I].Category);
      end;
    end;
    if ItemCount = 0 then
      FStatusLabel.Caption := 'No scripts match the current filters.'
    else
      FStatusLabel.Caption := Format('Showing %d scripts across %d categories.', [ItemCount, CategoryCount.Count]);
  finally
    CategoryCount.Free;
  end;
end;

function TScriptManagerForm.GetRowCategory(const Row: Integer): string;
begin
  Result := '';
  if (Row > 0) and (Row <= Length(FVisibleRows)) then
    Result := FVisibleRows[Row - 1].Category;
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

procedure TScriptManagerForm.UpdateDetailLogo(const Glyph: string; BackColor, TextColor: TColor);
var
  Bitmap: TBitmap;
  DrawRect: TRect;
begin
  if not Assigned(FDetailLogoImage) then
    Exit;
  Bitmap := TBitmap.Create;
  try
    Bitmap.SetSize(118, 118);
    Bitmap.Canvas.Brush.Color := clWindow;
    Bitmap.Canvas.FillRect(Rect(0, 0, 118, 118));
    Bitmap.Canvas.Brush.Style := bsSolid;
    Bitmap.Canvas.Brush.Color := BackColor;
    Bitmap.Canvas.Pen.Color := BadgeBlueBorder;
    Bitmap.Canvas.Ellipse(6, 6, 112, 112);
    Bitmap.Canvas.Font.Name := 'Segoe UI Semibold';
    Bitmap.Canvas.Font.Size := 40;
    Bitmap.Canvas.Font.Style := [fsBold];
    Bitmap.Canvas.Font.Color := TextColor;
    Bitmap.Canvas.Brush.Style := bsClear;
    DrawRect := Rect(0, 0, 118, 118);
    DrawText(Bitmap.Canvas.Handle, PChar(Glyph), Length(Glyph), DrawRect, DT_CENTER or DT_VCENTER or DT_SINGLELINE);
    FDetailLogoImage.Picture.Assign(Bitmap);
  finally
    Bitmap.Free;
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
  HasItem: Boolean;
  CategoryLabel: string;
begin
  if not Assigned(FDetailLogoImage) or not Assigned(FDetailTitleLabel) or
     not Assigned(FDetailCategoryLabel) or not Assigned(FDetailSummaryLabel) or
     not Assigned(FDetailVersionValue) or not Assigned(FDetailMethodValue) or
     not Assigned(FDetailInstallButton) or not Assigned(FDetailCategoryBadge) or
     not Assigned(FDetailVersionBadge) then
    Exit;
  HasItem := SelectedCatalogItem(Item);
  if not HasItem then
  begin
    UpdateDetailLogo('?', BadgeBlueBack, BadgeBlueText);
    FDetailTitleLabel.Caption := 'Select a script';
    FDetailCategoryLabel.Caption := 'No item selected';
    FDetailSummaryLabel.Caption := 'Pick a row from the catalog to see details here.';
    FDetailVersionValue.Caption := '-';
    FDetailMethodValue.Caption := '-';
    FDetailInstallButton.Caption := 'Install selected';
    Exit;
  end;

  UpdateDetailLogo(UpperCase(Copy(Item.Name, 1, 1)),
    IfThen(IsEcommerceCategory(Item.Category), BadgeGrayBack, BadgeBlueBack),
    IfThen(IsEcommerceCategory(Item.Category), BadgeGrayText, BadgeBlueText));
  FDetailTitleLabel.Caption := Item.Name;
  CategoryLabel := Item.Category;
  if CategoryLabel = '' then
    CategoryLabel := 'General';
  FDetailCategoryLabel.Caption := CategoryLabel;
  if IsEcommerceCategory(CategoryLabel) then
  begin
    FDetailCategoryBadge.Color := BadgeGrayBack;
    FDetailCategoryLabel.Font.Color := BadgeGrayText;
  end
  else
  begin
    FDetailCategoryBadge.Color := BadgeBlueBack;
    FDetailCategoryLabel.Font.Color := BadgeBlueText;
  end;
  FDetailVersionBadge.Color := BadgeGrayBack;
  FDetailVersionValue.Font.Color := BadgeGrayText;
  FDetailSummaryLabel.Caption := Item.Summary;
  FDetailVersionValue.Caption := Item.Version;
  FDetailMethodValue.Caption := GetInstallMethodText(Item);
  FDetailInstallButton.Caption := 'Install ' + Item.Name;
end;

procedure TScriptManagerForm.AppendOutput(const Text: string);
begin
  FPendingOutputText := Text;
  TThread.Synchronize(nil, SyncAppendOutput);
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
  if Assigned(FDetailInstallButton) then
    FDetailInstallButton.Enabled := not Value;
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
  
  if Assigned(FProgressBar) then
  begin
    if not Value then
    begin
      FProgressBar.Visible := False;
      FProgressBar.Position := 0;
    end;
  end;
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

function TScriptManagerForm.GetRowKind(const Row: Integer): TScriptGridRowKind;
begin
  Result := rgHeader;
  if (Row > 0) and (Row <= Length(FVisibleRows)) then
    Result := FVisibleRows[Row - 1].Kind;
end;

function TScriptManagerForm.GetRowItemIndex(const Row: Integer): Integer;
begin
  Result := -1;
  if (Row > 0) and (Row <= Length(FVisibleRows)) and (FVisibleRows[Row - 1].Kind = rgItem) then
    Result := FVisibleRows[Row - 1].ItemIndex;
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
begin
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
      MariaResult: TRuntimeActionResult;
      ProjectPath: string;
      NeedsDatabase: Boolean;
      Step: TScriptStep;
      InstallSucceeded: Boolean;
    begin
      InstallSucceeded := False;
      FPendingCompletionMessage := '';
      FPendingCompletionOutput := '';
      FPendingCompletionSuccess := False;
      ProjectPath := TPath.Combine(FPaths.WwwDir, ProjectName);
      NeedsDatabase := False;
      for Step in Item.Steps do
        if SameText(Step.StepType, 'create_database') then
        begin
          NeedsDatabase := True;
          Break;
        end;

      Runtime := nil;
      try
        Runtime := TUniWampRuntime.Create(FPaths, Config);
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
            ExecutionResult := Engine.Execute(Item, ProjectName,
              procedure(const Text: string)
              begin
                AppendOutput(Text);
              end);
          finally
            Engine.Free;
          end;

          if ExecutionResult.Success then
          begin
            AppendOutput(ExecutionResult.Message);
            ReloadConfig := TUniWampConfig.Create;
            try
              if ReloadConfig.LoadOrCreate(FPaths) then
              begin
                VHostManager := TServiceLocator.Instance.GetService<IVHostManager>;
                VHostResult := VHostManager.AddVHost(ProjectName, ProjectPath, '', False);
                AppendOutput(VHostResult.Message);
                if not VHostResult.Success then
                begin
                  FPendingCompletionMessage := 'VHost registration failed: ' + VHostResult.Message;
                  FPendingCompletionOutput := VHostResult.Message;
                  Exit;
                end;
                ReloadConfig.Save(FPaths);
                  AppendOutput('Open the site at: ' + Format('http://%s:%d/',
                    [ProjectName, ReloadConfig.HttpPort]));
                  FPendingCompletionMessage := ExecutionResult.Message;
                  FPendingCompletionSuccess := True;
                  InstallSucceeded := True;
              end
              else
              begin
                FPendingCompletionMessage := 'Project installed, but UniWamp config could not be reloaded.';
                FPendingCompletionOutput := '';
                Exit;
              end;
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
  finally
    Engine.Free;
  end;
  if Pos('No PHP runtime was found', PhpDescription) = 1 then
  begin
    MessageDlg(PhpDescription, mtError, [mbOK], 0);
    Exit;
  end;
  Config := TUniWampConfig.Create;
  try
    if not Config.LoadOrCreate(FPaths) then
    begin
      MessageDlg('UniWamp configuration could not be loaded.', mtError, [mbOK], 0);
      Exit;
    end;
    if MessageDlg(Format('Install %s into the www folder?', [Item.Name]),
      mtConfirmation, [mbYes, mbNo], 0) <> mrYes then
      Exit;
    MessageDlg(Format('%s will run with %s and create %s.', [Item.Name, PhpDescription, ProjectPath]),
      mtInformation, [mbOK], 0);
    FOutputMemo.Clear;
    InstallSelectedAsync(Item, ProjectName, Config);
    Config := nil;
  finally
    Config.Free;
  end;
end;

procedure TScriptManagerForm.GridDblClick(Sender: TObject);
begin
  if FHeaderClickPending then
  begin
    FHeaderClickPending := False;
    Exit;
  end;
  InstallClick(Sender);
end;

procedure TScriptManagerForm.GridClick(Sender: TObject);
begin
  UpdateSelectionDetails;
end;

procedure TScriptManagerForm.GridMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X,
  Y: Integer);
var
  Col: Longint;
  Row: Longint;
  Category: string;
begin
  if Button <> mbLeft then
    Exit;
  FGrid.MouseToCell(X, Y, Col, Row);
  if (Row <= 0) or (Row > Length(FVisibleRows)) then
    Exit;
  if GetRowKind(Row) <> rgHeader then
  begin
    FHeaderClickPending := False;
    Exit;
  end;
  Category := GetRowCategory(Row);
  if Category <> '' then
  begin
    FHeaderClickPending := True;
    ToggleCategory(Category);
  end;
end;

procedure TScriptManagerForm.GridDrawCell(Sender: TObject; ACol, ARow: Integer; Rect: TRect; State: TGridDrawState);
var
  Grid: TStringGrid;
  CellText: string;
  TextRect: TRect;
  Flags: Longint;
  RowKind: TScriptGridRowKind;
  BadgeBack: TColor;
  UseGrayBadge: Boolean;
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
    RowKind := GetRowKind(ARow);
    if RowKind = rgHeader then
    begin
      Grid.Canvas.Brush.Color := GridGroupBack;
      Grid.Canvas.Font.Color := GridGroupText;
      Grid.Canvas.Font.Style := [fsBold];
      if ACol = 0 then
        Grid.Canvas.Font.Color := GridGroupText;
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
  end;

  Grid.Canvas.FillRect(Rect);
  if (ARow > 0) and (GetRowKind(ARow) = rgItem) then
  begin
    if ACol = 1 then
    begin
      BadgeBack := BadgeBlueBack;
      UseGrayBadge := IsEcommerceCategory(CellText);
      if UseGrayBadge then
        BadgeBack := BadgeGrayBack;
      DrawBadge(Grid.Canvas, Rect, CellText, BadgeBack,
        IfThen(UseGrayBadge, BadgeGrayBorder, BadgeBlueBorder),
        IfThen(UseGrayBadge, BadgeGrayText, BadgeBlueText), False);
      Exit;
    end;
    if ACol = 3 then
    begin
      DrawBadge(Grid.Canvas, Rect, CellText, BadgeGrayBack, BadgeGrayBorder, BadgeGrayText, True);
      Exit;
    end;
  end;
  TextRect := Rect;
  InflateRect(TextRect, -8, -2);
  Flags := DT_LEFT or DT_VCENTER or DT_SINGLELINE or DT_END_ELLIPSIS;
  if ACol = 3 then
    Flags := Flags or DT_RIGHT;
  if (ARow > 0) and (GetRowKind(ARow) = rgHeader) and (ACol > 0) then
    CellText := '';
  DrawText(Grid.Canvas.Handle, PChar(CellText), Length(CellText), TextRect, Flags);
end;

procedure TScriptManagerForm.GridSelectCell(Sender: TObject; ACol, ARow: Integer; var CanSelect: Boolean);
begin
  CanSelect := (ARow > 0) and (GetRowKind(ARow) = rgItem);
end;

procedure TScriptManagerForm.CloseClick(Sender: TObject);
begin
  ModalResult := mrClose;
end;

initialization
  RegisterClass(TPanel);
  RegisterClass(TLabel);
  RegisterClass(TButton);
  RegisterClass(TEdit);
  RegisterClass(TComboBox);
  RegisterClass(TCheckBox);
  RegisterClass(TStringGrid);
  RegisterClass(TMemo);
  RegisterClass(TImage);

end.
