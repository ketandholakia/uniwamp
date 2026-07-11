unit Ui.UniWamp.PhpSettingsForm;

interface

uses
  System.Classes,
  System.SysUtils,
  Vcl.Controls,
  Vcl.ExtCtrls,
  Vcl.Forms,
  Vcl.Graphics,
  Vcl.StdCtrls,
  Core.UniWamp.Config,
  Core.UniWamp.Paths,
  Core.UniWamp.Runtime;

type
  TPhpSettingsForm = class(TForm)
  private
    FPaths: TAppPaths;
    FConfig: TUniWampConfig;
    FRuntime: TUniWampRuntime;
    FHeaderPanel: TPanel;
    FFooterPanel: TPanel;
    FSettingsList: TListBox;
    FValueLabel: TLabel;
    FValueCombo: TComboBox;
    FDescriptionTitle: TLabel;
    FDescriptionMemo: TMemo;
    FSaveButton: TButton;
    FCancelButton: TButton;
    FPendingValues: TStringList;
    procedure SettingsChanged(Sender: TObject);
    procedure ValueChanged(Sender: TObject);
    procedure SaveClicked(Sender: TObject);
    procedure CancelClicked(Sender: TObject);
    procedure LoadSettings;
    procedure LoadCurrentSetting;
    procedure ApplyValueToPending;
    procedure SaveSettings;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    class function Execute(const AOwner: TComponent; const Paths: TAppPaths;
      Config: TUniWampConfig; Runtime: TUniWampRuntime): Boolean;
  end;

implementation

uses
  System.IOUtils;

type
  TPhpSettingId = (
    psiDisplayErrors,
    psiErrorReporting,
    psiLogErrors,
    psiShortOpenTag,
    psiExposePhp,
    psiMemoryLimit,
    psiUploadMaxFilesize,
    psiPostMaxSize,
    psiMaxExecutionTime,
    psiMaxInputVars
  );

const
  SettingKeys: array[TPhpSettingId] of string = (
    'display_errors',
    'error_reporting',
    'log_errors',
    'short_open_tag',
    'expose_php',
    'memory_limit',
    'upload_max_filesize',
    'post_max_size',
    'max_execution_time',
    'max_input_vars'
  );

  SettingTitles: array[TPhpSettingId] of string = (
    'Display errors',
    'Error reporting',
    'Log errors',
    'Short open tag',
    'Expose PHP',
    'Memory limit',
    'Upload max filesize',
    'Post max size',
    'Max execution time',
    'Max input vars'
  );

  SettingDescriptions: array[TPhpSettingId] of string = (
    'Shows errors directly in the browser. Keep this enabled in development, disabled in production.',
    'Controls which PHP errors are reported. E_ALL is the recommended default.',
    'Writes runtime errors to the PHP error log.',
    'Allows legacy short PHP tags such as <? instead of <?php.',
    'Adds the PHP version header in responses.',
    'Maximum memory a script may consume.',
    'Maximum size of a single uploaded file.',
    'Maximum combined size of a POST request body.',
    'Maximum time in seconds a script is allowed to run.',
    'Maximum number of input variables accepted in a request.'
  );

function SettingAllowedValues(const SettingId: TPhpSettingId): TArray<string>;
begin
  case SettingId of
    psiDisplayErrors, psiLogErrors, psiShortOpenTag, psiExposePhp:
      begin
        SetLength(Result, 2);
        Result[0] := 'On';
        Result[1] := 'Off';
      end;
    psiErrorReporting:
      begin
        SetLength(Result, 4);
        Result[0] := 'E_ALL';
        Result[1] := 'E_ALL & ~E_DEPRECATED & ~E_STRICT';
        Result[2] := 'E_ALL & ~E_NOTICE';
        Result[3] := 'E_ALL & ~E_WARNING';
      end;
    psiMemoryLimit:
      begin
        SetLength(Result, 4);
        Result[0] := '128M';
        Result[1] := '256M';
        Result[2] := '512M';
        Result[3] := '1G';
      end;
    psiUploadMaxFilesize, psiPostMaxSize:
      begin
        SetLength(Result, 5);
        Result[0] := '8M';
        Result[1] := '16M';
        Result[2] := '32M';
        Result[3] := '64M';
        Result[4] := '128M';
      end;
    psiMaxExecutionTime:
      begin
        SetLength(Result, 4);
        Result[0] := '30';
        Result[1] := '60';
        Result[2] := '120';
        Result[3] := '300';
      end;
    psiMaxInputVars:
      begin
        SetLength(Result, 4);
        Result[0] := '1000';
        Result[1] := '3000';
        Result[2] := '5000';
        Result[3] := '10000';
      end;
  else
    Result := nil;
  end;
end;

function SettingDefaultValue(const SettingId: TPhpSettingId; const Profile: string): string;
begin
  case SettingId of
    psiDisplayErrors:
      if SameText(Profile, 'production') then
        Exit('Off')
      else
        Exit('On');
    psiErrorReporting:
      Exit('E_ALL');
    psiLogErrors:
      Exit('On');
    psiShortOpenTag:
      Exit('Off');
    psiExposePhp:
      Exit('Off');
    psiMemoryLimit:
      Exit('256M');
    psiUploadMaxFilesize:
      Exit('32M');
    psiPostMaxSize:
      Exit('32M');
    psiMaxExecutionTime:
      Exit('120');
    psiMaxInputVars:
      Exit('3000');
  else
    Result := '';
  end;
end;

function SettingIdFromIndex(const Index: Integer): TPhpSettingId;
begin
  Result := TPhpSettingId(Index);
end;

constructor TPhpSettingsForm.Create(AOwner: TComponent);
begin
  inherited CreateNew(AOwner);
  Position := poScreenCenter;
  BorderStyle := bsDialog;
  Caption := 'PHP Settings';
  ClientWidth := 760;
  ClientHeight := 520;
  Color := $00F7F7F7;
  Font.Name := 'Segoe UI';
  Font.Size := 9;

  FHeaderPanel := TPanel.Create(Self);
  FHeaderPanel.Parent := Self;
  FHeaderPanel.Align := alTop;
  FHeaderPanel.Height := 88;
  FHeaderPanel.BevelOuter := bvNone;
  FHeaderPanel.Color := $002D2B2A;
  FHeaderPanel.ParentBackground := False;

  with TLabel.Create(Self) do
  begin
    Parent := FHeaderPanel;
    Left := 18;
    Top := 14;
    Caption := 'PHP Settings';
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
    Caption := 'Edit PHP ini directives for the selected runtime.';
    Font.Name := 'Segoe UI';
    Font.Size := 9;
    Font.Color := $00D0D8DD;
    ParentFont := False;
  end;

  FSettingsList := TListBox.Create(Self);
  FSettingsList.Parent := Self;
  FSettingsList.Left := 18;
  FSettingsList.Top := 106;
  FSettingsList.Width := 230;
  FSettingsList.Height := 342;
  FSettingsList.BorderStyle := bsSingle;
  FSettingsList.ItemHeight := 16;
  FSettingsList.Color := clWhite;
  FSettingsList.OnClick := SettingsChanged;

  FDescriptionTitle := TLabel.Create(Self);
  FDescriptionTitle.Parent := Self;
  FDescriptionTitle.Left := 270;
  FDescriptionTitle.Top := 106;
  FDescriptionTitle.Caption := 'Description';
  FDescriptionTitle.Font.Style := [fsBold];

  FDescriptionMemo := TMemo.Create(Self);
  FDescriptionMemo.Parent := Self;
  FDescriptionMemo.Left := 270;
  FDescriptionMemo.Top := 128;
  FDescriptionMemo.Width := 462;
  FDescriptionMemo.Height := 128;
  FDescriptionMemo.ReadOnly := True;
  FDescriptionMemo.ScrollBars := ssVertical;
  FDescriptionMemo.BorderStyle := bsSingle;
  FDescriptionMemo.Color := clWhite;
  FDescriptionMemo.WordWrap := True;

  FValueLabel := TLabel.Create(Self);
  FValueLabel.Parent := Self;
  FValueLabel.Left := 270;
  FValueLabel.Top := 276;
  FValueLabel.Caption := 'Value';
  FValueLabel.Font.Style := [fsBold];

  FValueCombo := TComboBox.Create(Self);
  FValueCombo.Parent := Self;
  FValueCombo.Left := 330;
  FValueCombo.Top := 272;
  FValueCombo.Width := 230;
  FValueCombo.Style := csDropDown;
  FValueCombo.OnChange := ValueChanged;

  FFooterPanel := TPanel.Create(Self);
  FFooterPanel.Parent := Self;
  FFooterPanel.Align := alBottom;
  FFooterPanel.Height := 64;
  FFooterPanel.BevelOuter := bvNone;
  FFooterPanel.Color := $00F2F2F2;
  FFooterPanel.ParentBackground := False;

  FSaveButton := TButton.Create(Self);
  FSaveButton.Parent := FFooterPanel;
  FSaveButton.Left := 542;
  FSaveButton.Top := 16;
  FSaveButton.Width := 84;
  FSaveButton.Height := 28;
  FSaveButton.Caption := 'OK';
  FSaveButton.Default := True;
  FSaveButton.OnClick := SaveClicked;

  FCancelButton := TButton.Create(Self);
  FCancelButton.Parent := FFooterPanel;
  FCancelButton.Left := 634;
  FCancelButton.Top := 16;
  FCancelButton.Width := 84;
  FCancelButton.Height := 28;
  FCancelButton.Caption := 'Cancel';
  FCancelButton.Cancel := True;
  FCancelButton.ModalResult := mrCancel;
  FCancelButton.OnClick := CancelClicked;

  FPendingValues := TStringList.Create;
  FPendingValues.NameValueSeparator := '=';
  FPendingValues.StrictDelimiter := True;
end;

destructor TPhpSettingsForm.Destroy;
begin
  FPendingValues.Free;
  inherited;
end;

class function TPhpSettingsForm.Execute(const AOwner: TComponent;
  const Paths: TAppPaths; Config: TUniWampConfig; Runtime: TUniWampRuntime): Boolean;
var
  Form: TPhpSettingsForm;
begin
  Form := TPhpSettingsForm.Create(AOwner);
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

procedure TPhpSettingsForm.LoadSettings;
var
  SettingId: TPhpSettingId;
begin
  FPendingValues.Clear;
  FSettingsList.Items.BeginUpdate;
  try
    FSettingsList.Clear;
    for SettingId := Low(TPhpSettingId) to High(TPhpSettingId) do
    begin
      FSettingsList.Items.Add(SettingTitles[SettingId]);
      FPendingValues.Values[SettingKeys[SettingId]] :=
        FConfig.PhpSettingValue(SettingKeys[SettingId], SettingDefaultValue(SettingId, FConfig.PhpProfile));
    end;
  finally
    FSettingsList.Items.EndUpdate;
  end;

  if FSettingsList.Items.Count > 0 then
    FSettingsList.ItemIndex := 0;
  LoadCurrentSetting;
end;

procedure TPhpSettingsForm.LoadCurrentSetting;
var
  SettingId: TPhpSettingId;
  Values: TArray<string>;
  I: Integer;
  CurrentValue: string;
begin
  if FSettingsList.ItemIndex < 0 then
    Exit;

  SettingId := SettingIdFromIndex(FSettingsList.ItemIndex);
  FDescriptionMemo.Lines.Text := SettingDescriptions[SettingId];

  FValueCombo.Items.BeginUpdate;
  try
    FValueCombo.Clear;
    Values := SettingAllowedValues(SettingId);
    for I := 0 to High(Values) do
      FValueCombo.Items.Add(Values[I]);
  finally
    FValueCombo.Items.EndUpdate;
  end;

  CurrentValue := FPendingValues.Values[SettingKeys[SettingId]];
  FValueCombo.Text := CurrentValue;
end;

procedure TPhpSettingsForm.ApplyValueToPending;
var
  SettingId: TPhpSettingId;
begin
  if FSettingsList.ItemIndex < 0 then
    Exit;
  SettingId := SettingIdFromIndex(FSettingsList.ItemIndex);
  FPendingValues.Values[SettingKeys[SettingId]] := Trim(FValueCombo.Text);
end;

procedure TPhpSettingsForm.SettingsChanged(Sender: TObject);
begin
  ApplyValueToPending;
  LoadCurrentSetting;
end;

procedure TPhpSettingsForm.ValueChanged(Sender: TObject);
begin
  ApplyValueToPending;
end;

procedure TPhpSettingsForm.SaveSettings;
var
  SettingId: TPhpSettingId;
  DefaultValue: string;
begin
  ApplyValueToPending;
  for SettingId := Low(TPhpSettingId) to High(TPhpSettingId) do
  begin
    DefaultValue := SettingDefaultValue(SettingId, FConfig.PhpProfile);
    FConfig.SetPhpSettingValue(SettingKeys[SettingId], FPendingValues.Values[SettingKeys[SettingId]]);
    if FPendingValues.Values[SettingKeys[SettingId]] = '' then
      FConfig.SetPhpSettingValue(SettingKeys[SettingId], DefaultValue);
  end;
  FConfig.Save(FPaths);
  FRuntime.GenerateAllConfigs;
end;

procedure TPhpSettingsForm.SaveClicked(Sender: TObject);
begin
  SaveSettings;
  ModalResult := mrOk;
end;

procedure TPhpSettingsForm.CancelClicked(Sender: TObject);
begin
  ModalResult := mrCancel;
end;

end.
