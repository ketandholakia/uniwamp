unit Ui.UniWamp.AboutForm;

interface

uses
  System.Classes,
  System.SysUtils,
  Winapi.Windows,
  Winapi.ShellAPI,
  Vcl.Controls,
  Vcl.ExtCtrls,
  Vcl.Forms,
  Vcl.Grids,
  Vcl.Graphics,
  Vcl.StdCtrls;

type
  TAboutCreditItem = record
    Name: string;
    VersionText: string;
    LicenseText: string;
    LinkText: string;
  end;

  TAboutForm = class(TForm)
  private
    FTitleLabel: TLabel;
    FRepoLabel: TLabel;
    FHintLabel: TLabel;
    FGrid: TStringGrid;
    FCloseButton: TButton;
    procedure RepoLabelClick(Sender: TObject);
    procedure GridDblClick(Sender: TObject);
    procedure GridClick(Sender: TObject);
    procedure GridDrawCell(Sender: TObject; ACol, ARow: Integer; Rect: TRect; State: TGridDrawState);
    procedure OpenLink(const Url: string);
    procedure PopulateGrid;
    procedure ConfigureGrid;
    procedure ConfigureHeader;
  public
    constructor Create(AOwner: TComponent); override;
    class procedure Execute(AOwner: TComponent); static;
  end;

implementation

const
  ProjectRepositoryUrl = 'https://github.com/ketandholakia/uniwamp';
  AppHeaderBack = TColor($00F6F7FB);
  AppHeaderText = TColor($0022262D);
  AppHeaderHint = TColor($005B6472);
  AppHeaderLink = TColor($005B4AE6);
  GridHeaderBack = TColor($00EEF1F6);
  GridHeaderText = TColor($00333A45);
  GridRowOdd = clWhite;
  GridRowEven = TColor($00FAFBFD);
  GridRowSelected = TColor($00EAF2FF);
  GridLinkText = TColor($005B4AE6);

function BuildCreditItems: TArray<TAboutCreditItem>;
begin
  SetLength(Result, 13);

  Result[0].Name := 'Apache HTTP Server';
  Result[0].VersionText := '2.4.68';
  Result[0].LicenseText := 'Apache-2.0';
  Result[0].LinkText := 'https://httpd.apache.org/';

  Result[1].Name := 'Composer';
  Result[1].VersionText := '2.10.2';
  Result[1].LicenseText := 'MIT';
  Result[1].LinkText := 'https://getcomposer.org/';

  Result[2].Name := 'Git for Windows';
  Result[2].VersionText := '2.55.0.windows.2';
  Result[2].LicenseText := 'GPL-2.0';
  Result[2].LinkText := 'https://gitforwindows.org/';

  Result[3].Name := 'Lite XL';
  Result[3].VersionText := 'release-3.2.14-0-g8d604353a';
  Result[3].LicenseText := 'MIT';
  Result[3].LinkText := 'https://lite-xl.com/';

  Result[4].Name := 'Mailpit';
  Result[4].VersionText := '1.30.4';
  Result[4].LicenseText := 'MIT';
  Result[4].LinkText := 'https://mailpit.axllent.org/';

  Result[5].Name := 'MariaDB Server';
  Result[5].VersionText := '11.8.8.0';
  Result[5].LicenseText := 'GPL-2.0';
  Result[5].LinkText := 'https://mariadb.org/';

  Result[6].Name := 'Node.js';
  Result[6].VersionText := '22.23.1';
  Result[6].LicenseText := 'MIT';
  Result[6].LinkText := 'https://nodejs.org/';

  Result[7].Name := 'PHP 8.2';
  Result[7].VersionText := '8.2.32';
  Result[7].LicenseText := 'PHP License';
  Result[7].LinkText := 'https://www.php.net/';

  Result[8].Name := 'PHP 8.3';
  Result[8].VersionText := '8.3.32';
  Result[8].LicenseText := 'PHP License';
  Result[8].LinkText := 'https://www.php.net/';

  Result[9].Name := 'PHP 8.4';
  Result[9].VersionText := '8.4.23';
  Result[9].LicenseText := 'PHP License';
  Result[9].LinkText := 'https://www.php.net/';

  Result[10].Name := 'PHP 8.5';
  Result[10].VersionText := '8.5.8';
  Result[10].LicenseText := 'PHP License';
  Result[10].LinkText := 'https://www.php.net/';

  Result[11].Name := 'Redis';
  Result[11].VersionText := '8.8.0';
  Result[11].LicenseText := 'BSD-3-Clause';
  Result[11].LinkText := 'https://redis.io/';

  Result[12].Name := 'WP-CLI';
  Result[12].VersionText := '2.12.0';
  Result[12].LicenseText := 'MIT';
  Result[12].LinkText := 'https://wp-cli.org/';
end;

constructor TAboutForm.Create(AOwner: TComponent);
var
  TitlePanel: TPanel;
  FooterPanel: TPanel;
begin
  inherited CreateNew(AOwner);
  BorderStyle := bsDialog;
  Position := poScreenCenter;
  Caption := 'About UniWamp';
  ClientWidth := 1040;
  ClientHeight := 640;
  BorderIcons := [biSystemMenu];
  Color := clWindow;
  Font.Name := 'Segoe UI';
  Font.Size := 9;

  TitlePanel := TPanel.Create(Self);
  TitlePanel.Parent := Self;
  TitlePanel.Align := alTop;
  TitlePanel.BevelOuter := bvNone;
  TitlePanel.Color := AppHeaderBack;
  TitlePanel.Height := 112;
  TitlePanel.Padding.Left := 16;
  TitlePanel.Padding.Top := 14;
  TitlePanel.Padding.Right := 16;
  TitlePanel.Padding.Bottom := 10;
  TitlePanel.ParentBackground := False;

  FTitleLabel := TLabel.Create(Self);
  FTitleLabel.Parent := TitlePanel;
  FTitleLabel.Left := TitlePanel.Padding.Left;
  FTitleLabel.Top := TitlePanel.Padding.Top;
  FTitleLabel.Caption := 'UniWamp third-party credits';
  FTitleLabel.Font.Size := 16;
  FTitleLabel.Font.Style := [fsBold];
  FTitleLabel.Font.Name := 'Segoe UI Semibold';
  FTitleLabel.Font.Color := AppHeaderText;

  FHintLabel := TLabel.Create(Self);
  FHintLabel.Parent := TitlePanel;
  FHintLabel.Left := TitlePanel.Padding.Left;
  FHintLabel.Top := 44;
  FHintLabel.Caption := 'Alphabetized list of bundled tools. Double-click a row to open the project site.';
  FHintLabel.Font.Color := AppHeaderHint;

  FRepoLabel := TLabel.Create(Self);
  FRepoLabel.Parent := TitlePanel;
  FRepoLabel.Left := TitlePanel.Padding.Left;
  FRepoLabel.Top := 68;
  FRepoLabel.Caption := 'GitHub repository: ' + ProjectRepositoryUrl;
  FRepoLabel.Cursor := crHandPoint;
  FRepoLabel.Font.Color := AppHeaderLink;
  FRepoLabel.Font.Style := [fsUnderline];
  FRepoLabel.OnClick := RepoLabelClick;

  FGrid := TStringGrid.Create(Self);
  FGrid.Parent := Self;
  FGrid.Align := alClient;
  FGrid.FixedCols := 0;
  FGrid.FixedRows := 1;
  FGrid.Options := (FGrid.Options + [goRowSelect, goThumbTracking]) - [goEditing];
  FGrid.DefaultRowHeight := 24;
  FGrid.DefaultDrawing := False;
  FGrid.ColCount := 4;
  FGrid.OnDblClick := GridDblClick;
  FGrid.OnClick := GridClick;
  FGrid.OnDrawCell := GridDrawCell;
  ConfigureGrid;

  FooterPanel := TPanel.Create(Self);
  FooterPanel.Parent := Self;
  FooterPanel.Align := alBottom;
  FooterPanel.BevelOuter := bvNone;
  FooterPanel.Color := clWindow;
  FooterPanel.Height := 60;
  FooterPanel.Padding.Left := 16;
  FooterPanel.Padding.Top := 10;
  FooterPanel.Padding.Right := 16;
  FooterPanel.Padding.Bottom := 12;
  FooterPanel.ParentBackground := False;

  FCloseButton := TButton.Create(Self);
  FCloseButton.Parent := FooterPanel;
  FCloseButton.Caption := 'Close';
  FCloseButton.Default := True;
  FCloseButton.ModalResult := mrClose;
  FCloseButton.Width := 96;
  FCloseButton.Height := 28;
  FCloseButton.Anchors := [akRight, akTop];
  FCloseButton.Left := 928;
  FCloseButton.Top := FooterPanel.Padding.Top;

  PopulateGrid;
end;

procedure TAboutForm.ConfigureHeader;
begin
  FGrid.Cells[0, 0] := 'Tool';
  FGrid.Cells[1, 0] := 'Version';
  FGrid.Cells[2, 0] := 'License';
  FGrid.Cells[3, 0] := 'Link';
end;

procedure TAboutForm.ConfigureGrid;
begin
  FGrid.Font.Name := 'Segoe UI';
  FGrid.Font.Size := 9;
  FGrid.FixedColor := GridHeaderBack;
  FGrid.Font.Color := clWindowText;
  FGrid.GridLineWidth := 1;
  FGrid.ColWidths[0] := 230;
  FGrid.ColWidths[1] := 120;
  FGrid.ColWidths[2] := 150;
  FGrid.ColWidths[3] := 520;
  FGrid.RowCount := 2;
  ConfigureHeader;
end;

procedure TAboutForm.GridClick(Sender: TObject);
begin
  // Keep selection behavior predictable on the credits table.
end;

procedure TAboutForm.GridDrawCell(Sender: TObject; ACol, ARow: Integer; Rect: TRect; State: TGridDrawState);
const
  HeaderBack = GridHeaderBack;
  HeaderText = GridHeaderText;
  RowEven = GridRowEven;
  RowOdd = GridRowOdd;
  RowSelected = GridRowSelected;
  LinkText = GridLinkText;
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
    Grid.Canvas.Brush.Color := HeaderBack;
    Grid.Canvas.Font.Color := HeaderText;
    Grid.Canvas.Font.Style := [fsBold];
  end
  else
  begin
    if gdSelected in State then
      Grid.Canvas.Brush.Color := RowSelected
    else if Odd(ARow) then
      Grid.Canvas.Brush.Color := RowOdd
    else
      Grid.Canvas.Brush.Color := RowEven;
    if ACol = 3 then
      Grid.Canvas.Font.Color := LinkText
    else
      Grid.Canvas.Font.Color := clWindowText;
    Grid.Canvas.Font.Style := [];
  end;

  Grid.Canvas.FillRect(Rect);

  TextRect := Rect;
  InflateRect(TextRect, -8, -2);
  Flags := DT_LEFT or DT_VCENTER or DT_SINGLELINE or DT_END_ELLIPSIS;
  if ACol = 1 then
    Flags := Flags or DT_RIGHT;
  DrawText(Grid.Canvas.Handle, PChar(CellText), Length(CellText), TextRect, Flags);
end;

procedure TAboutForm.GridDblClick(Sender: TObject);
begin
  if (FGrid.Row > 0) and (FGrid.Row < FGrid.RowCount) then
    OpenLink(FGrid.Cells[3, FGrid.Row]);
end;

procedure TAboutForm.OpenLink(const Url: string);
begin
  if Trim(Url) = '' then
    Exit;
  ShellExecute(Handle, 'open', PChar(Url), nil, nil, SW_SHOWNORMAL);
end;

procedure TAboutForm.PopulateGrid;
var
  Credits: TArray<TAboutCreditItem>;
  I: Integer;
begin
  Credits := BuildCreditItems;
  FGrid.RowCount := Length(Credits) + 1;
  ConfigureHeader;
  for I := 0 to High(Credits) do
  begin
    FGrid.Cells[0, I + 1] := Credits[I].Name;
    FGrid.Cells[1, I + 1] := Credits[I].VersionText;
    FGrid.Cells[2, I + 1] := Credits[I].LicenseText;
    FGrid.Cells[3, I + 1] := Credits[I].LinkText;
  end;
  if Length(Credits) > 0 then
    FGrid.Row := 1;
end;

procedure TAboutForm.RepoLabelClick(Sender: TObject);
begin
  OpenLink(ProjectRepositoryUrl);
end;

class procedure TAboutForm.Execute(AOwner: TComponent);
var
  Dialog: TAboutForm;
begin
  Dialog := TAboutForm.Create(AOwner);
  try
    Dialog.ShowModal;
  finally
    Dialog.Free;
  end;
end;

end.
