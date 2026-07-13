unit Ui.UniWamp.PasswordDialog;

interface

uses
  System.Classes,
  System.SysUtils,
  Vcl.Controls,
  Vcl.Forms,
  Vcl.Graphics,
  Vcl.StdCtrls;

type
  TPasswordDialogResult = record
    Accepted: Boolean;
    Password: string;
  end;

  TPasswordDialog = class(TForm)
  private
    FStatusLabel: TLabel;
    FPasswordEdit: TEdit;
    FConfirmEdit: TEdit;
    procedure OkButtonClick(Sender: TObject);
    procedure PasswordChanged(Sender: TObject);
  public
    constructor Create(AOwner: TComponent); override;
    class function Execute(AOwner: TComponent; const Title, Prompt: string): TPasswordDialogResult; static;
  end;

implementation

constructor TPasswordDialog.Create(AOwner: TComponent);
var
  Label1: TLabel;
  Label2: TLabel;
  OkButton: TButton;
  CancelButton: TButton;
begin
  inherited CreateNew(AOwner);
  BorderStyle := bsDialog;
  Position := poScreenCenter;
  Caption := 'Set Password';
  ClientWidth := 460;
  ClientHeight := 178;
  BorderIcons := [biSystemMenu];

  Label1 := TLabel.Create(Self);
  Label1.Parent := Self;
  Label1.Left := 16;
  Label1.Top := 16;
  Label1.Caption := 'Password';

  FPasswordEdit := TEdit.Create(Self);
  FPasswordEdit.Parent := Self;
  FPasswordEdit.Left := 16;
  FPasswordEdit.Top := 36;
  FPasswordEdit.Width := 420;
  FPasswordEdit.PasswordChar := '*';

  Label2 := TLabel.Create(Self);
  Label2.Parent := Self;
  Label2.Left := 16;
  Label2.Top := 68;
  Label2.Caption := 'Confirm password';

  FConfirmEdit := TEdit.Create(Self);
  FConfirmEdit.Parent := Self;
  FConfirmEdit.Left := 16;
  FConfirmEdit.Top := 88;
  FConfirmEdit.Width := 420;
  FConfirmEdit.PasswordChar := '*';
  FConfirmEdit.OnChange := PasswordChanged;

  FStatusLabel := TLabel.Create(Self);
  FStatusLabel.Parent := Self;
  FStatusLabel.Left := 16;
  FStatusLabel.Top := 116;
  FStatusLabel.Width := 420;
  FStatusLabel.Caption := '';
  FStatusLabel.Font.Color := clRed;

  OkButton := TButton.Create(Self);
  OkButton.Parent := Self;
  OkButton.Caption := 'OK';
  OkButton.Default := True;
  OkButton.Left := 260;
  OkButton.Top := 126;
  OkButton.Width := 80;
  OkButton.OnClick := OkButtonClick;

  CancelButton := TButton.Create(Self);
  CancelButton.Parent := Self;
  CancelButton.ModalResult := mrCancel;
  CancelButton.Caption := 'Cancel';
  CancelButton.Cancel := True;
  CancelButton.Left := 356;
  CancelButton.Top := 126;
  CancelButton.Width := 80;
end;

class function TPasswordDialog.Execute(AOwner: TComponent; const Title, Prompt: string): TPasswordDialogResult;
var
  Dialog: TPasswordDialog;
begin
  Dialog := TPasswordDialog.Create(AOwner);
  try
    Dialog.Caption := Title;
    if Prompt <> '' then
      Dialog.FStatusLabel.Caption := Prompt;
    Dialog.FPasswordEdit.SelectAll;
    Result.Accepted := Dialog.ShowModal = mrOk;
    if Result.Accepted then
      Result.Password := Dialog.FPasswordEdit.Text;
  finally
    Dialog.Free;
  end;
end;

procedure TPasswordDialog.PasswordChanged(Sender: TObject);
begin
  if (Trim(FPasswordEdit.Text) <> '') and (FPasswordEdit.Text <> FConfirmEdit.Text) then
    FStatusLabel.Caption := 'Passwords do not match'
  else
    FStatusLabel.Caption := '';
end;

procedure TPasswordDialog.OkButtonClick(Sender: TObject);
begin
  if Trim(FPasswordEdit.Text) = '' then
  begin
    FStatusLabel.Caption := 'Password is required';
    Exit;
  end;
  if FPasswordEdit.Text <> FConfirmEdit.Text then
  begin
    FStatusLabel.Caption := 'Passwords do not match';
    Exit;
  end;
  ModalResult := mrOk;
end;

end.
