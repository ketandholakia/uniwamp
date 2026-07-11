unit Ui.UniWamp.ApacheModulesForm;

interface

uses
  System.Classes,
  System.Generics.Collections,
  System.StrUtils,
  System.SysUtils,
  Vcl.CheckLst,
  Vcl.ComCtrls,
  Vcl.Controls,
  Vcl.Dialogs,
  Vcl.ExtCtrls,
  Vcl.Forms,
  Vcl.Graphics,
  Vcl.StdCtrls;

type
  TApacheModuleInfo = record
    Name: string;
    DisplayName: string;
    Description: string;
  end;

  TUniWampApacheModulesForm = class(TForm)
  private
    FRootPanel: TPanel;
    FHeaderPanel: TPanel;
    FFooterPanel: TPanel;
    FTabControl: TPageControl;
    FModulesTab: TTabSheet;
    FSearchLabel: TLabel;
    FSearchEdit: TEdit;
    FModulesList: TCheckListBox;
    FDescriptionGroup: TGroupBox;
    FDescriptionMemo: TMemo;
    FOkButton: TButton;
    FCancelButton: TButton;
    FAllModules: TList<TApacheModuleInfo>;
    FModuleStates: TDictionary<string, Boolean>;
    procedure BuildUi;
    procedure PopulateModules;
    procedure RebuildVisibleModules;
    procedure SyncStatesFromList;
    procedure UpdateDescription;
    procedure SearchEditChange(Sender: TObject);
    procedure ModulesListClick(Sender: TObject);
    procedure ModulesListClickCheck(Sender: TObject);
    function GetEnabledModules: TArray<string>;
    procedure SetEnabledModules(const Modules: TArray<string>);
    class function NormalizeModuleName(const Value: string): string; static;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    class function Execute(AOwner: TComponent; const CurrentModules: TArray<string>; out UpdatedModules: TArray<string>): Boolean; overload; static;
    class function Execute(AOwner: TComponent; const Arg1; const Arg2): Boolean; overload; static;
    class function Execute(AOwner: TComponent; const Arg1; const Arg2; const Arg3): Boolean; overload; static;
    class function Execute(AOwner: TComponent; const AppPaths; const CurrentModules: TArray<string>; out UpdatedModules: TArray<string>): Boolean; overload; static;
    property EnabledModules: TArray<string> read GetEnabledModules write SetEnabledModules;
    property SelectedModules: TArray<string> read GetEnabledModules write SetEnabledModules;
    property Modules: TArray<string> read GetEnabledModules write SetEnabledModules;
  end;

  TUiUniWampApacheModulesForm = TUniWampApacheModulesForm;
  TFrmApacheModules = TUniWampApacheModulesForm;
  TApacheModulesForm = TUniWampApacheModulesForm;

implementation

const
  CDefaultModules: array[0..19] of TApacheModuleInfo = (
    (Name: 'mod_access_compat.so'; DisplayName: 'access_compat_module'; Description: 'Compatibility module for older access control rules.'),
    (Name: 'mod_alias.so'; DisplayName: 'alias_module'; Description: 'Maps URLs to filesystem paths.'),
    (Name: 'mod_allowmethods.so'; DisplayName: 'allowmethods_module'; Description: 'Restricts which HTTP methods are accepted.'),
    (Name: 'mod_auth_basic.so'; DisplayName: 'auth_basic_module'; Description: 'Provides basic authentication support.'),
    (Name: 'mod_authn_core.so'; DisplayName: 'authn_core_module'; Description: 'Core authentication provider support.'),
    (Name: 'mod_authn_file.so'; DisplayName: 'authn_file_module'; Description: 'File-based authentication provider.'),
    (Name: 'mod_authz_core.so'; DisplayName: 'authz_core_module'; Description: 'Core authorization provider support.'),
    (Name: 'mod_authz_host.so'; DisplayName: 'authz_host_module'; Description: 'Authorization based on host information.'),
    (Name: 'mod_authz_user.so'; DisplayName: 'authz_user_module'; Description: 'Authorization based on authenticated user.'),
    (Name: 'mod_dir.so'; DisplayName: 'dir_module'; Description: 'Directory indexing and trailing slash handling.'),
    (Name: 'mod_env.so'; DisplayName: 'env_module'; Description: 'Environment variable management.'),
    (Name: 'mod_headers.so'; DisplayName: 'headers_module'; Description: 'HTTP header manipulation.'),
    (Name: 'mod_include.so'; DisplayName: 'include_module'; Description: 'Server side includes support.'),
    (Name: 'mod_log_config.so'; DisplayName: 'log_config_module'; Description: 'Access log and custom log support.'),
    (Name: 'mod_mime.so'; DisplayName: 'mime_module'; Description: 'Content type and handler mapping.'),
    (Name: 'mod_rewrite.so'; DisplayName: 'rewrite_module'; Description: 'URL rewriting support.'),
    (Name: 'mod_setenvif.so'; DisplayName: 'setenvif_module'; Description: 'Sets environment variables based on request data.'),
    (Name: 'mod_ssl.so'; DisplayName: 'ssl_module'; Description: 'TLS/SSL support.'),
    (Name: 'mod_socache_shmcb.so'; DisplayName: 'socache_shmcb_module'; Description: 'Shared memory cache support for SSL and sessions.'),
    (Name: 'mod_unixd.so'; DisplayName: 'unixd_module'; Description: 'Unix platform integration and process handling.')
  );

constructor TUniWampApacheModulesForm.Create(AOwner: TComponent);
begin
  inherited CreateNew(AOwner);
  Caption := 'Apache Config';
  BorderStyle := bsDialog;
  Position := poScreenCenter;
  ClientWidth := 720;
  ClientHeight := 520;
  Font.Name := 'Segoe UI';
  Font.Size := 9;
  BorderIcons := [biSystemMenu];

  FAllModules := TList<TApacheModuleInfo>.Create;
  FModuleStates := TDictionary<string, Boolean>.Create;

  BuildUi;
  PopulateModules;
  RebuildVisibleModules;
end;

destructor TUniWampApacheModulesForm.Destroy;
begin
  FModuleStates.Free;
  FAllModules.Free;
  inherited Destroy;
end;

procedure TUniWampApacheModulesForm.BuildUi;
begin
  FRootPanel := TPanel.Create(Self);
  FRootPanel.Parent := Self;
  FRootPanel.Align := alClient;
  FRootPanel.BevelOuter := bvNone;
  FRootPanel.Caption := '';
  FRootPanel.Color := clWindow;
  FRootPanel.Padding.Left := 12;
  FRootPanel.Padding.Top := 12;
  FRootPanel.Padding.Right := 12;
  FRootPanel.Padding.Bottom := 12;

  FHeaderPanel := TPanel.Create(Self);
  FHeaderPanel.Parent := FRootPanel;
  FHeaderPanel.Align := alTop;
  FHeaderPanel.BevelOuter := bvNone;
  FHeaderPanel.Caption := '';
  FHeaderPanel.Height := 48;
  FHeaderPanel.Color := clWindow;

  FTabControl := TPageControl.Create(Self);
  FTabControl.Parent := FRootPanel;
  FTabControl.Align := alClient;

  FModulesTab := TTabSheet.Create(Self);
  FModulesTab.PageControl := FTabControl;
  FModulesTab.Caption := 'Modules';

  FSearchLabel := TLabel.Create(Self);
  FSearchLabel.Parent := FModulesTab;
  FSearchLabel.Left := 12;
  FSearchLabel.Top := 14;
  FSearchLabel.Caption := 'Search';

  FSearchEdit := TEdit.Create(Self);
  FSearchEdit.Parent := FModulesTab;
  FSearchEdit.Left := 66;
  FSearchEdit.Top := 10;
  FSearchEdit.Width := 250;
  FSearchEdit.OnChange := SearchEditChange;

  FModulesList := TCheckListBox.Create(Self);
  FModulesList.Parent := FModulesTab;
  FModulesList.Left := 12;
  FModulesList.Top := 42;
  FModulesList.Width := 250;
  FModulesList.Height := 360;
  FModulesList.OnClick := ModulesListClick;
  FModulesList.OnClickCheck := ModulesListClickCheck;
  FModulesList.ItemHeight := 18;

  FDescriptionGroup := TGroupBox.Create(Self);
  FDescriptionGroup.Parent := FModulesTab;
  FDescriptionGroup.Caption := 'Description';
  FDescriptionGroup.Left := 280;
  FDescriptionGroup.Top := 42;
  FDescriptionGroup.Width := 412;
  FDescriptionGroup.Height := 360;

  FDescriptionMemo := TMemo.Create(Self);
  FDescriptionMemo.Parent := FDescriptionGroup;
  FDescriptionMemo.Align := alClient;
  FDescriptionMemo.BorderStyle := bsNone;
  FDescriptionMemo.ReadOnly := True;
  FDescriptionMemo.ScrollBars := ssVertical;
  FDescriptionMemo.WordWrap := True;
  FDescriptionMemo.Color := clWindow;

  FFooterPanel := TPanel.Create(Self);
  FFooterPanel.Parent := FRootPanel;
  FFooterPanel.Align := alBottom;
  FFooterPanel.BevelOuter := bvNone;
  FFooterPanel.Caption := '';
  FFooterPanel.Height := 48;
  FFooterPanel.Color := clWindow;

  FCancelButton := TButton.Create(Self);
  FCancelButton.Parent := FFooterPanel;
  FCancelButton.Caption := 'Cancel';
  FCancelButton.Width := 96;
  FCancelButton.Height := 28;
  FCancelButton.Left := ClientWidth - 12 - FCancelButton.Width;
  FCancelButton.Top := 10;
  FCancelButton.Anchors := [akRight, akBottom];
  FCancelButton.ModalResult := mrCancel;

  FOkButton := TButton.Create(Self);
  FOkButton.Parent := FFooterPanel;
  FOkButton.Caption := 'OK';
  FOkButton.Width := 96;
  FOkButton.Height := 28;
  FOkButton.Left := FCancelButton.Left - 12 - FOkButton.Width;
  FOkButton.Top := 10;
  FOkButton.Anchors := [akRight, akBottom];
  FOkButton.ModalResult := mrOk;
end;

procedure TUniWampApacheModulesForm.PopulateModules;
var
  ModuleInfo: TApacheModuleInfo;
begin
  FAllModules.Clear;
  for ModuleInfo in CDefaultModules do
    FAllModules.Add(ModuleInfo);
end;

procedure TUniWampApacheModulesForm.RebuildVisibleModules;
var
  FilterText: string;
  ModuleInfo: TApacheModuleInfo;
  Index: Integer;
  IsEnabled: Boolean;
begin
  FModulesList.Items.BeginUpdate;
  try
    FModulesList.Items.Clear;
    FilterText := AnsiLowerCase(Trim(FSearchEdit.Text));
    for Index := 0 to FAllModules.Count - 1 do
    begin
      ModuleInfo := FAllModules[Index];
      if (FilterText = '') or ContainsText(ModuleInfo.Name, FilterText) or ContainsText(ModuleInfo.DisplayName, FilterText) then
      begin
        FModulesList.Items.AddObject(ModuleInfo.DisplayName, TObject(NativeInt(Index)));
        IsEnabled := False;
        if not FModuleStates.TryGetValue(ModuleInfo.Name, IsEnabled) then
          FModuleStates.TryGetValue(NormalizeModuleName(ModuleInfo.Name), IsEnabled);
        if not IsEnabled then
          FModuleStates.TryGetValue(NormalizeModuleName(ModuleInfo.DisplayName), IsEnabled);
        FModulesList.Checked[FModulesList.Items.Count - 1] := IsEnabled;
      end;
    end;
  finally
    FModulesList.Items.EndUpdate;
  end;

  UpdateDescription;
end;

procedure TUniWampApacheModulesForm.SyncStatesFromList;
var
  VisibleIndex: Integer;
  ModuleIndex: Integer;
  ModuleInfo: TApacheModuleInfo;
begin
  for VisibleIndex := 0 to FModulesList.Items.Count - 1 do
  begin
    ModuleIndex := NativeInt(FModulesList.Items.Objects[VisibleIndex]);
    if (ModuleIndex >= 0) and (ModuleIndex < FAllModules.Count) then
    begin
      ModuleInfo := FAllModules[ModuleIndex];
      FModuleStates.AddOrSetValue(ModuleInfo.Name, FModulesList.Checked[VisibleIndex]);
      FModuleStates.AddOrSetValue(NormalizeModuleName(ModuleInfo.Name), FModulesList.Checked[VisibleIndex]);
      FModuleStates.AddOrSetValue(NormalizeModuleName(ModuleInfo.DisplayName), FModulesList.Checked[VisibleIndex]);
    end;
  end;
end;

procedure TUniWampApacheModulesForm.UpdateDescription;
var
  ModuleName: string;
  ModuleInfo: TApacheModuleInfo;
  Index: Integer;
begin
  ModuleName := '';
  if (FModulesList.ItemIndex >= 0) and (FModulesList.ItemIndex < FModulesList.Items.Count) then
    ModuleName := FModulesList.Items[FModulesList.ItemIndex];

  if ModuleName = '' then
  begin
    FDescriptionMemo.Text := 'Select a module to view its description.';
    Exit;
  end;

  for Index := 0 to FAllModules.Count - 1 do
  begin
    ModuleInfo := FAllModules[Index];
    if SameText(ModuleInfo.DisplayName, ModuleName) then
    begin
      FDescriptionMemo.Text := ModuleInfo.Description;
      Exit;
    end;
  end;

  FDescriptionMemo.Text := 'No description available.';
end;

procedure TUniWampApacheModulesForm.SearchEditChange(Sender: TObject);
begin
  RebuildVisibleModules;
end;

procedure TUniWampApacheModulesForm.ModulesListClick(Sender: TObject);
begin
  UpdateDescription;
end;

procedure TUniWampApacheModulesForm.ModulesListClickCheck(Sender: TObject);
begin
  SyncStatesFromList;
  UpdateDescription;
end;

function TUniWampApacheModulesForm.GetEnabledModules: TArray<string>;
var
  Pair: TPair<string, Boolean>;
  Count: Integer;
begin
  Count := 0;
  SetLength(Result, FModuleStates.Count);
  for Pair in FModuleStates do
  begin
    if Pair.Value then
    begin
      Result[Count] := Pair.Key;
      Inc(Count);
    end;
  end;
  SetLength(Result, Count);
end;

procedure TUniWampApacheModulesForm.SetEnabledModules(const Modules: TArray<string>);
var
  ModuleName: string;
begin
  FModuleStates.Clear;
  for ModuleName in Modules do
  begin
    FModuleStates.AddOrSetValue(ModuleName, True);
    FModuleStates.AddOrSetValue(NormalizeModuleName(ModuleName), True);
  end;
  RebuildVisibleModules;
end;

class function TUniWampApacheModulesForm.Execute(AOwner: TComponent; const CurrentModules: TArray<string>; out UpdatedModules: TArray<string>): Boolean;
var
  Form: TUniWampApacheModulesForm;
begin
  Form := TUniWampApacheModulesForm.Create(AOwner);
  try
    Form.SetEnabledModules(CurrentModules);
    Result := Form.ShowModal = mrOk;
    if Result then
      UpdatedModules := Form.GetEnabledModules
    else
      UpdatedModules := CurrentModules;
  finally
    Form.Free;
  end;
end;

class function TUniWampApacheModulesForm.Execute(AOwner: TComponent; const Arg1; const Arg2): Boolean;
begin
  Result := False;
end;

class function TUniWampApacheModulesForm.Execute(AOwner: TComponent; const Arg1; const Arg2; const Arg3): Boolean;
begin
  Result := False;
end;

class function TUniWampApacheModulesForm.Execute(AOwner: TComponent; const AppPaths; const CurrentModules: TArray<string>; out UpdatedModules: TArray<string>): Boolean;
begin
  Result := Execute(AOwner, CurrentModules, UpdatedModules);
end;

class function TUniWampApacheModulesForm.NormalizeModuleName(const Value: string): string;
var
  S: string;
begin
  S := AnsiLowerCase(Trim(Value));
  S := StringReplace(S, 'mod_', '', [rfReplaceAll]);
  S := StringReplace(S, '.so', '', [rfReplaceAll]);
  S := StringReplace(S, '_module', '', [rfReplaceAll]);
  S := StringReplace(S, '-', '_', [rfReplaceAll]);
  S := StringReplace(S, ' ', '', [rfReplaceAll]);
  Result := S;
end;

end.
