unit Ui.UniWamp.ScriptManagerForm;

interface

uses
  Core.UniWamp.Config,
  Core.UniWamp.Runtime,
  Core.UniWamp.Paths,
  Core.UniWamp.ScriptCatalog,
  System.Classes,
  System.SysUtils,
  System.Threading,
  Vcl.Controls,
  Vcl.Forms,
  Vcl.Grids,
  Vcl.StdCtrls;

type
  TScriptManagerForm = class(TForm)
  private
    FPaths: TAppPaths;
    FCatalog: TObject;
    FGrid: TStringGrid;
    FInstallButton: TButton;
    FCloseButton: TButton;
    FStatusLabel: TLabel;
    FOutputMemo: TMemo;
    FInstalling: Boolean;
    procedure InstallClick(Sender: TObject);
    procedure CloseClick(Sender: TObject);
    procedure GridDblClick(Sender: TObject);
    procedure Populate;
    procedure AppendOutput(const Text: string);
    procedure SetInstalling(const Value: Boolean);
    function AskProjectName(const DefaultValue: string; out ProjectName: string): Boolean;
    procedure InstallSelectedAsync(const Item: TScriptCatalogItem; const ProjectName: string;
      Config: TUniWampConfig);
  public
    constructor Create(AOwner: TComponent; const Paths: TAppPaths); reintroduce;
    destructor Destroy; override;
    class procedure Execute(AOwner: TComponent; const Paths: TAppPaths); static;
  end;

implementation

uses
  Core.UniWamp.ScriptEngine,
  System.IOUtils,
  System.UITypes,
  Vcl.Dialogs;

constructor TScriptManagerForm.Create(AOwner: TComponent; const Paths: TAppPaths);
begin
  inherited CreateNew(AOwner);
  FPaths := Paths;
  Caption := 'UniWamp script manager';
  BorderStyle := bsDialog;
  Position := poScreenCenter;
  Width := 820;
  Height := 500;
  Font.Name := 'Segoe UI';
  Font.Size := 9;

  FGrid := TStringGrid.Create(Self);
  FGrid.Parent := Self;
  FGrid.Align := alClient;
  FGrid.FixedRows := 1;
  FGrid.RowCount := 2;
  FGrid.ColCount := 4;
  FGrid.Options := FGrid.Options + [goRowSelect, goThumbTracking] - [goEditing];
  FGrid.ColWidths[0] := 180;
  FGrid.ColWidths[1] := 120;
  FGrid.ColWidths[2] := 380;
  FGrid.ColWidths[3] := 110;
  FGrid.Cells[0, 0] := 'Name';
  FGrid.Cells[1, 0] := 'Category';
  FGrid.Cells[2, 0] := 'Summary';
  FGrid.Cells[3, 0] := 'Version';
  FGrid.OnDblClick := GridDblClick;

  FStatusLabel := TLabel.Create(Self);
  FStatusLabel.Parent := Self;
  FStatusLabel.Align := alBottom;
  FStatusLabel.AutoSize := False;
  FStatusLabel.Height := 30;
  FStatusLabel.Caption := 'Select a script and click Install.';
  FStatusLabel.Layout := tlCenter;

  FOutputMemo := TMemo.Create(Self);
  FOutputMemo.Parent := Self;
  FOutputMemo.Align := alBottom;
  FOutputMemo.Height := 150;
  FOutputMemo.ReadOnly := True;
  FOutputMemo.ScrollBars := ssVertical;
  FOutputMemo.WordWrap := False;
  FOutputMemo.Lines.Text := 'Install output will appear here.';

  FCloseButton := TButton.Create(Self);
  FCloseButton.Parent := Self;
  FCloseButton.Align := alBottom;
  FCloseButton.Height := 38;
  FCloseButton.Caption := 'Close';
  FCloseButton.OnClick := CloseClick;

  FInstallButton := TButton.Create(Self);
  FInstallButton.Parent := Self;
  FInstallButton.Align := alBottom;
  FInstallButton.Height := 38;
  FInstallButton.Caption := 'Install selected';
  FInstallButton.Default := True;
  FInstallButton.OnClick := InstallClick;

  FCatalog := TScriptCatalog.LoadFromFile(TPath.Combine(FPaths.AppRoot, 'scripts\catalog.json'));
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

procedure TScriptManagerForm.Populate;
var
  Catalog: TScriptCatalog;
  I: Integer;
begin
  Catalog := TScriptCatalog(FCatalog);
  FGrid.RowCount := Length(Catalog.Items) + 1;
  for I := 0 to Length(Catalog.Items) - 1 do
  begin
    FGrid.Cells[0, I + 1] := Catalog.Items[I].Name;
    FGrid.Cells[1, I + 1] := Catalog.Items[I].Category;
    FGrid.Cells[2, I + 1] := Catalog.Items[I].Summary;
    FGrid.Cells[3, I + 1] := Catalog.Items[I].Version;
  end;
end;

procedure TScriptManagerForm.AppendOutput(const Text: string);
begin
  TThread.Queue(nil,
    procedure
    begin
      if Assigned(FOutputMemo) then
      begin
        FOutputMemo.Lines.Add(Text);
        FOutputMemo.SelStart := Length(FOutputMemo.Text);
      end;
    end);
end;

procedure TScriptManagerForm.SetInstalling(const Value: Boolean);
begin
  FInstalling := Value;
  FInstallButton.Enabled := not Value;
  FGrid.Enabled := not Value;
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
      VHostResult: TRuntimeActionResult;
      MariaResult: TRuntimeActionResult;
      ProjectPath: string;
      NeedsDatabase: Boolean;
      Step: TScriptStep;
    begin
      ProjectPath := TPath.Combine(FPaths.WwwDir, ProjectName);
      NeedsDatabase := False;
      for Step in Item.Steps do
        if SameText(Step.StepType, 'create_database') then
        begin
          NeedsDatabase := True;
          Break;
        end;

      Runtime := nil;
      Engine := nil;
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

        finally
          Runtime.Free;
        end;
      finally
        Config.Free;
      end;

      TThread.Queue(nil,
        procedure
        begin
          try
            if ExecutionResult.Success then
            begin
              AppendOutput(ExecutionResult.Message);
              Config := TUniWampConfig.Create;
              try
                if Config.LoadOrCreate(FPaths) then
                begin
                  Runtime := TUniWampRuntime.Create(FPaths, Config);
                  try
                    VHostResult := Runtime.AddVHost(ProjectName, ProjectPath, '', False);
                    AppendOutput(VHostResult.Message);
                    if not VHostResult.Success then
                    begin
                      MessageDlg('VHost registration failed: ' + VHostResult.Message,
                        mtError, [mbOK], 0);
                      Exit;
                    end;
                    Config.Save(FPaths);
                    AppendOutput('Open the site at: ' + Format('http://%s:%d/',
                      [ProjectName, Config.HttpPort]));
                  finally
                    Runtime.Free;
                  end;
                end
                else
                begin
                  MessageDlg('Project installed, but UniWamp config could not be reloaded.',
                    mtError, [mbOK], 0);
                  Exit;
                end;
              finally
                Config.Free;
              end;
              FStatusLabel.Caption := ExecutionResult.Message;
            end
            else
            begin
              AppendOutput(ExecutionResult.Message);
              if Trim(ExecutionResult.Output) <> '' then
                AppendOutput(ExecutionResult.Output);
              MessageDlg(ExecutionResult.Message + sLineBreak + ExecutionResult.Output,
                mtError, [mbOK], 0);
            end;
          finally
            SetInstalling(False);
          end;
        end);
    end).Start;
end;

procedure TScriptManagerForm.InstallClick(Sender: TObject);
var
  Catalog: TScriptCatalog;
  Item: TScriptCatalogItem;
  ProjectName: string;
  ProjectPath: string;
  PhpDescription: string;
  Engine: TScriptEngine;
  Config: TUniWampConfig;
begin
  if FInstalling then
    Exit;
  if FGrid.Row < 1 then
    Exit;
  Catalog := TScriptCatalog(FCatalog);
  if not Catalog.FindById(Catalog.Items[FGrid.Row - 1].Id, Item) then
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
  InstallClick(Sender);
end;

procedure TScriptManagerForm.CloseClick(Sender: TObject);
begin
  ModalResult := mrClose;
end;

end.
