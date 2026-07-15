unit Ui.UniWamp.VHostDialog;

interface

uses
  Core.UniWamp.Security,
  System.Classes,
  System.SysUtils,
  System.IOUtils,
  System.UITypes,
  Vcl.Controls,
  Vcl.Forms,
  Vcl.StdCtrls,
  Vcl.Dialogs;

type
  TVHostDialogResult = record
    Accepted: Boolean;
    ServerName: string;
    DocumentRoot: string;
    ServerAliases: string;
    EnableSsl: Boolean;
  end;

  TVHostDialog = class(TForm)
  private
    FBaseVHostDir: string;
    FServerNameEdit: TEdit;
    FDocumentRootEdit: TEdit;
    FAliasesEdit: TEdit;
    FSslCheck: TCheckBox;
    procedure ServerNameChanged(Sender: TObject);
    procedure OkClick(Sender: TObject);
  public
    constructor Create(AOwner: TComponent); override;
    class function Execute(AOwner: TComponent; const BaseVHostDir, DefaultServerName,
      DefaultDocumentRoot, DefaultAliases: string; DefaultEnableSsl: Boolean): TVHostDialogResult; static;
  end;

implementation

constructor TVHostDialog.Create(AOwner: TComponent);
var
  Label1: TLabel;
  Label2: TLabel;
  Label3: TLabel;
  OkButton: TButton;
  CancelButton: TButton;
begin
  inherited CreateNew(AOwner);
  BorderStyle := bsDialog;
  Position := poScreenCenter;
  Caption := 'Add VHost';
  ClientWidth := 560;
  ClientHeight := 228;
  BorderIcons := [biSystemMenu];

  Label1 := TLabel.Create(Self);
  Label1.Parent := Self;
  Label1.Left := 16;
  Label1.Top := 16;
  Label1.Caption := 'Server name';

  FServerNameEdit := TEdit.Create(Self);
  FServerNameEdit.Parent := Self;
  FServerNameEdit.Left := 16;
  FServerNameEdit.Top := 36;
  FServerNameEdit.Width := 520;
  FServerNameEdit.OnChange := ServerNameChanged;

  Label2 := TLabel.Create(Self);
  Label2.Parent := Self;
  Label2.Left := 16;
  Label2.Top := 68;
  Label2.Caption := 'Document root';

  FDocumentRootEdit := TEdit.Create(Self);
  FDocumentRootEdit.Parent := Self;
  FDocumentRootEdit.Left := 16;
  FDocumentRootEdit.Top := 88;
  FDocumentRootEdit.Width := 520;

  Label3 := TLabel.Create(Self);
  Label3.Parent := Self;
  Label3.Left := 16;
  Label3.Top := 120;
  Label3.Caption := 'Server aliases, separated by spaces or commas';

  FAliasesEdit := TEdit.Create(Self);
  FAliasesEdit.Parent := Self;
  FAliasesEdit.Left := 16;
  FAliasesEdit.Top := 140;
  FAliasesEdit.Width := 520;

  FSslCheck := TCheckBox.Create(Self);
  FSslCheck.Parent := Self;
  FSslCheck.Left := 16;
  FSslCheck.Top := 176;
  FSslCheck.Caption := 'Enable SSL for this vHost';

  OkButton := TButton.Create(Self);
  OkButton.Parent := Self;
  OkButton.Caption := 'OK';
  OkButton.Default := True;
  OkButton.Left := 360;
  OkButton.Top := 188;
  OkButton.Width := 80;
  OkButton.OnClick := OkClick;

  CancelButton := TButton.Create(Self);
  CancelButton.Parent := Self;
  CancelButton.ModalResult := mrCancel;
  CancelButton.Caption := 'Cancel';
  CancelButton.Cancel := True;
  CancelButton.Left := 456;
  CancelButton.Top := 188;
  CancelButton.Width := 80;
end;

procedure TVHostDialog.ServerNameChanged(Sender: TObject);
var
  NormalizedName: string;
begin
  NormalizedName := Trim(FServerNameEdit.Text);
  if NormalizedName = '' then
    Exit;
  if Trim(FDocumentRootEdit.Text) = '' then
    FDocumentRootEdit.Text := TPath.Combine(FBaseVHostDir, NormalizedName);
end;

procedure TVHostDialog.OkClick(Sender: TObject);
var
  ServerName: string;
  DocumentRoot: string;
  Aliases: string;
  ErrorMessage: string;
begin
  if not ValidateServerName(FServerNameEdit.Text, ServerName, ErrorMessage) then
  begin
    MessageDlg(ErrorMessage, mtError, [mbOK], 0);
    Exit;
  end;
  if not ValidateDocumentRoot(FDocumentRootEdit.Text, DocumentRoot, ErrorMessage) then
  begin
    MessageDlg(ErrorMessage, mtError, [mbOK], 0);
    Exit;
  end;
  if not ValidateServerAliases(FAliasesEdit.Text, Aliases, ErrorMessage) then
  begin
    MessageDlg(ErrorMessage, mtError, [mbOK], 0);
    Exit;
  end;

  FServerNameEdit.Text := ServerName;
  FDocumentRootEdit.Text := DocumentRoot;
  FAliasesEdit.Text := Aliases;
  ModalResult := mrOk;
end;

class function TVHostDialog.Execute(AOwner: TComponent; const BaseVHostDir,
  DefaultServerName, DefaultDocumentRoot, DefaultAliases: string; DefaultEnableSsl: Boolean): TVHostDialogResult;
var
  Dialog: TVHostDialog;
begin
  Dialog := TVHostDialog.Create(AOwner);
  try
    Dialog.FBaseVHostDir := BaseVHostDir;
    Dialog.FServerNameEdit.Text := DefaultServerName;
    if DefaultDocumentRoot <> '' then
      Dialog.FDocumentRootEdit.Text := DefaultDocumentRoot
    else if DefaultServerName <> '' then
      Dialog.FDocumentRootEdit.Text := TPath.Combine(BaseVHostDir, DefaultServerName);
    Dialog.FAliasesEdit.Text := DefaultAliases;
    Dialog.FSslCheck.Checked := DefaultEnableSsl;
    Dialog.FServerNameEdit.SelectAll;
    Dialog.FServerNameEdit.SetFocus;
    Result.Accepted := Dialog.ShowModal = mrOk;
    if Result.Accepted then
    begin
      Result.ServerName := Trim(Dialog.FServerNameEdit.Text);
      Result.DocumentRoot := Trim(Dialog.FDocumentRootEdit.Text);
      Result.ServerAliases := Trim(Dialog.FAliasesEdit.Text);
      Result.EnableSsl := Dialog.FSslCheck.Checked;
    end;
  finally
    Dialog.Free;
  end;
end;

end.
