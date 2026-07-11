unit Ui.UniWamp.PhpExtensionsForm;

interface

uses
  System.Classes,
  System.Generics.Collections,
  System.SysUtils,
  Vcl.CheckLst,
  Vcl.Controls,
  Vcl.ExtCtrls,
  Vcl.Forms,
  Vcl.Graphics,
  Vcl.StdCtrls,
  Core.UniWamp.Config,
  Core.UniWamp.Paths,
  Core.UniWamp.Runtime;

type
  TPhpExtensionsForm = class(TForm)
  private
    FPaths: TAppPaths;
    FConfig: TUniWampConfig;
    FRuntime: TUniWampRuntime;
    FHeaderPanel: TPanel;
    FFooterPanel: TPanel;
    FVersionLabel: TLabel;
    FVersionValue: TPanel;
    FSearchLabel: TLabel;
    FSearchEdit: TEdit;
    FExtensionsLabel: TLabel;
    FExtensionsList: TCheckListBox;
    FSaveButton: TButton;
    FCancelButton: TButton;
    FHintLabel: TLabel;
    FAllExtensions: TStringList;
    FExtensionStates: TDictionary<string, Boolean>;
    procedure SearchChanged(Sender: TObject);
    procedure ExtensionClicked(Sender: TObject);
    procedure SaveClicked(Sender: TObject);
    procedure CancelClicked(Sender: TObject);
    procedure LoadExtensions;
    procedure RebuildVisibleList;
    procedure SyncVisibleStates;
    procedure SaveExtensions;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    class function Execute(const AOwner: TComponent; const Paths: TAppPaths;
      Config: TUniWampConfig; Runtime: TUniWampRuntime): Boolean;
  end;

implementation

uses
  System.IOUtils,
  Vcl.Dialogs;

constructor TPhpExtensionsForm.Create(AOwner: TComponent);
begin
  inherited CreateNew(AOwner);
  Position := poScreenCenter;
  BorderStyle := bsDialog;
  Caption := 'PHP Extension Manager';
  ClientWidth := 720;
  ClientHeight := 520;
  Color := $00F7F7F7;
  Font.Name := 'Segoe UI';
  Font.Size := 9;
  KeyPreview := True;

  FHeaderPanel := TPanel.Create(Self);
  FHeaderPanel.Parent := Self;
  FHeaderPanel.Align := alTop;
  FHeaderPanel.Height := 92;
  FHeaderPanel.BevelOuter := bvNone;
  FHeaderPanel.Color := $0035291F;
  FHeaderPanel.ParentBackground := False;

  with TLabel.Create(Self) do
  begin
    Parent := FHeaderPanel;
    Left := 18;
    Top := 14;
    Caption := 'PHP Extension Manager';
    Font.Name := 'Segoe UI';
    Font.Size := 15;
    Font.Style := [fsBold];
    Font.Color := clWhite;
    ParentFont := False;
  end;

  with TLabel.Create(Self) do
  begin
    Parent := FHeaderPanel;
    Left := 18;
    Top := 44;
    Caption := 'Enable or disable bundled DLL extensions for the selected PHP runtime.';
    Font.Name := 'Segoe UI';
    Font.Size := 9;
    Font.Color := $00D0D8DD;
    ParentFont := False;
  end;

  FVersionLabel := TLabel.Create(Self);
  FVersionLabel.Parent := Self;
  FVersionLabel.Left := 18;
  FVersionLabel.Top := 110;
  FVersionLabel.Caption := 'PHP version';
  FVersionLabel.Font.Style := [fsBold];

  FVersionValue := TPanel.Create(Self);
  FVersionValue.Parent := Self;
  FVersionValue.Left := 110;
  FVersionValue.Top := 104;
  FVersionValue.Width := 160;
  FVersionValue.Height := 26;
  FVersionValue.BevelOuter := bvNone;
  FVersionValue.Color := clWhite;
  FVersionValue.Caption := '';
  FVersionValue.Font.Style := [fsBold];
  FVersionValue.ParentBackground := False;
  FVersionValue.ParentFont := False;
  FVersionValue.Alignment := taCenter;

  FHintLabel := TLabel.Create(Self);
  FHintLabel.Parent := Self;
  FHintLabel.Left := 286;
  FHintLabel.Top := 111;
  FHintLabel.Caption := 'Uses the selected PHP version from the main window';
  FHintLabel.Font.Color := clGrayText;

  FSearchLabel := TLabel.Create(Self);
  FSearchLabel.Parent := Self;
  FSearchLabel.Left := 18;
  FSearchLabel.Top := 146;
  FSearchLabel.Caption := 'Search';
  FSearchLabel.Font.Style := [fsBold];

  FSearchEdit := TEdit.Create(Self);
  FSearchEdit.Parent := Self;
  FSearchEdit.Left := 70;
  FSearchEdit.Top := 142;
  FSearchEdit.Width := 240;
  FSearchEdit.Height := 24;
  FSearchEdit.TextHint := 'Type to filter extensions';
  FSearchEdit.OnChange := SearchChanged;

  FExtensionsLabel := TLabel.Create(Self);
  FExtensionsLabel.Parent := Self;
  FExtensionsLabel.Left := 18;
  FExtensionsLabel.Top := 178;
  FExtensionsLabel.Caption := 'Available extensions';
  FExtensionsLabel.Font.Style := [fsBold];

  FExtensionsList := TCheckListBox.Create(Self);
  FExtensionsList.Parent := Self;
  FExtensionsList.Left := 18;
  FExtensionsList.Top := 200;
  FExtensionsList.Width := 680;
  FExtensionsList.Height := 276;
  FExtensionsList.Anchors := [akLeft, akTop, akRight, akBottom];
  FExtensionsList.BorderStyle := bsSingle;
  FExtensionsList.ItemHeight := 16;
  FExtensionsList.Color := clWhite;
  FExtensionsList.TabStop := True;
  FExtensionsList.OnClickCheck := ExtensionClicked;

  FFooterPanel := TPanel.Create(Self);
  FFooterPanel.Parent := Self;
  FFooterPanel.Align := alBottom;
  FFooterPanel.Height := 64;
  FFooterPanel.BevelOuter := bvNone;
  FFooterPanel.Color := $00F2F2F2;
  FFooterPanel.ParentBackground := False;

  FSaveButton := TButton.Create(Self);
  FSaveButton.Parent := FFooterPanel;
  FSaveButton.Left := 520;
  FSaveButton.Top := 16;
  FSaveButton.Width := 84;
  FSaveButton.Height := 28;
  FSaveButton.Caption := 'Save';
  FSaveButton.Default := True;
  FSaveButton.OnClick := SaveClicked;

  FCancelButton := TButton.Create(Self);
  FCancelButton.Parent := FFooterPanel;
  FCancelButton.Left := 612;
  FCancelButton.Top := 16;
  FCancelButton.Width := 84;
  FCancelButton.Height := 28;
  FCancelButton.Caption := 'Cancel';
  FCancelButton.Cancel := True;
  FCancelButton.ModalResult := mrCancel;
  FCancelButton.OnClick := CancelClicked;

  FAllExtensions := TStringList.Create;
  FExtensionStates := TDictionary<string, Boolean>.Create;
end;

destructor TPhpExtensionsForm.Destroy;
begin
  FExtensionStates.Free;
  FAllExtensions.Free;
  inherited;
end;

class function TPhpExtensionsForm.Execute(const AOwner: TComponent;
  const Paths: TAppPaths; Config: TUniWampConfig; Runtime: TUniWampRuntime): Boolean;
var
  Form: TPhpExtensionsForm;
begin
  Form := TPhpExtensionsForm.Create(AOwner);
  try
      Form.FPaths := Paths;
      Form.FConfig := Config;
      Form.FRuntime := Runtime;
      Form.FVersionValue.Caption := Config.SelectedPhpVersion;
      Form.LoadExtensions;
      Result := Form.ShowModal = mrOk;
    finally
      Form.Free;
    end;
end;

procedure TPhpExtensionsForm.LoadExtensions;
var
  ExtDir: string;
  FileName: string;
  ExtensionName: string;
begin
  FAllExtensions.Clear;
  FExtensionStates.Clear;
  for ExtensionName in FConfig.PhpExtensions do
    FExtensionStates.AddOrSetValue(ExtensionName, True);

  ExtDir := TPath.Combine(TPath.Combine(FPaths.PhpDir, FConfig.SelectedPhpVersion), 'ext');
  if TDirectory.Exists(ExtDir) then
  begin
    for FileName in TDirectory.GetFiles(ExtDir, 'php_*.dll', TSearchOption.soTopDirectoryOnly) do
    begin
      ExtensionName := TPath.GetFileName(FileName);
      if SameText(ExtensionName, 'php_dl_test.dll') or SameText(ExtensionName, 'php_zend_test.dll') then
        Continue;
      if FAllExtensions.IndexOf(ExtensionName) < 0 then
        FAllExtensions.Add(ExtensionName);
      if not FExtensionStates.ContainsKey(ExtensionName) then
        FExtensionStates.Add(ExtensionName, False);
    end;
  end;

  RebuildVisibleList;
end;

procedure TPhpExtensionsForm.RebuildVisibleList;
var
  FilterText: string;
  I: Integer;
  ExtensionName: string;
  Checked: Boolean;
begin
  FilterText := LowerCase(Trim(FSearchEdit.Text));
  FExtensionsList.Items.BeginUpdate;
  try
    FExtensionsList.Clear;
    if FAllExtensions.Count = 0 then
    begin
      FExtensionsList.Enabled := False;
      FExtensionsList.Items.Add('No extension directory found for ' + FConfig.SelectedPhpVersion);
      Exit;
    end;

    FExtensionsList.Enabled := True;
    for I := 0 to FAllExtensions.Count - 1 do
    begin
      ExtensionName := FAllExtensions[I];
      if (FilterText <> '') and (Pos(FilterText, LowerCase(ExtensionName)) = 0) then
        Continue;
      FExtensionsList.Items.Add(ExtensionName);
      Checked := False;
      FExtensionStates.TryGetValue(ExtensionName, Checked);
      FExtensionsList.Checked[FExtensionsList.Items.Count - 1] := Checked;
    end;
  finally
    FExtensionsList.Items.EndUpdate;
  end;
end;

procedure TPhpExtensionsForm.SyncVisibleStates;
var
  I: Integer;
begin
  for I := 0 to FExtensionsList.Items.Count - 1 do
    if not SameText(FExtensionsList.Items[I], 'No extension directory found for ' + FConfig.SelectedPhpVersion) then
      FExtensionStates.AddOrSetValue(FExtensionsList.Items[I], FExtensionsList.Checked[I]);
end;

procedure TPhpExtensionsForm.SearchChanged(Sender: TObject);
begin
  SyncVisibleStates;
  RebuildVisibleList;
end;

procedure TPhpExtensionsForm.ExtensionClicked(Sender: TObject);
begin
  SyncVisibleStates;
end;

procedure TPhpExtensionsForm.SaveExtensions;
var
  SelectedExtensions: TArray<string>;
  I: Integer;
  Count: Integer;
  VersionName: string;
  Checked: Boolean;
begin
  Count := 0;
  SyncVisibleStates;
  SetLength(SelectedExtensions, FAllExtensions.Count);
  for I := 0 to FAllExtensions.Count - 1 do
  begin
    VersionName := FAllExtensions[I];
    Checked := False;
    if FExtensionStates.TryGetValue(VersionName, Checked) and Checked then
    begin
      SelectedExtensions[Count] := VersionName;
      Inc(Count);
    end;
  end;
  SetLength(SelectedExtensions, Count);
  FConfig.ReplacePhpExtensions(SelectedExtensions);
  FConfig.Save(FPaths);
  FRuntime.GenerateAllConfigs;
end;

procedure TPhpExtensionsForm.SaveClicked(Sender: TObject);
begin
  SaveExtensions;
  ModalResult := mrOk;
end;

procedure TPhpExtensionsForm.CancelClicked(Sender: TObject);
begin
  ModalResult := mrCancel;
end;

end.
