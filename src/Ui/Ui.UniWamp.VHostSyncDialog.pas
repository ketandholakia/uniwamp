unit Ui.UniWamp.VHostSyncDialog;

interface

uses
  Vcl.Forms,
  Vcl.StdCtrls,
  Vcl.Controls,
  Vcl.ExtCtrls,
  System.Classes,
  System.SysUtils,
  Core.UniWamp.Config;

type
  TLabelProc = reference to procedure(const CaptionText: string);
  TEditFunc = reference to function(const Value: string): TEdit;
  TVHostSyncDialog = class
  public
    class function Execute(AOwner: TComponent; const Entry: TVHostEntry;
      out UpdatedEntry: TVHostEntry): Boolean; static;
  end;

implementation

class function TVHostSyncDialog.Execute(AOwner: TComponent; const Entry: TVHostEntry;
  out UpdatedEntry: TVHostEntry): Boolean;
var
  Dialog: TForm;
  ProtocolBox, DirectionBox, VariantBox: TComboBox;
  HostEdit, PortEdit, UserEdit, KeyEdit, RemoteEdit, ExcludesEdit: TEdit;
  DeleteCheck: TCheckBox;
  OkButton, CancelButton: TButton;
  LabelTop: Integer;
  AddLabel: TLabelProc;
  AddEdit: TEditFunc;
begin
  UpdatedEntry := Entry;
  Dialog := TForm.CreateNew(AOwner);
  try
    Dialog.Caption := 'Sync Setup - ' + Entry.ServerName;
    Dialog.BorderStyle := bsDialog;
    Dialog.Position := poScreenCenter;
    Dialog.ClientWidth := 560;
    Dialog.ClientHeight := 520;

    LabelTop := 28;
    AddLabel :=
      procedure(const CaptionText: string)
      var L: TLabel;
      begin
        L := TLabel.Create(Dialog);
        L.Parent := Dialog;
        L.Caption := CaptionText;
        L.Left := 18;
        L.Top := LabelTop;
        Inc(LabelTop, 34);
      end;
    ;
    AddEdit :=
      function(const Value: string): TEdit
      begin
        Result := TEdit.Create(Dialog);
        Result.Parent := Dialog;
        Result.Left := 190;
        Result.Top := LabelTop - 28;
        Result.Width := 340;
        Result.Height := 25;
        Result.Text := Value;
      end;
    ;

    AddLabel('Protocol');
    ProtocolBox := TComboBox.Create(Dialog);
    ProtocolBox.Parent := Dialog;
    ProtocolBox.Left := 190;
    ProtocolBox.Top := LabelTop - 28;
    ProtocolBox.Width := 160;
    ProtocolBox.Style := csDropDownList;
    ProtocolBox.Items.Add('FTP');
    ProtocolBox.Items.Add('FTPS');
    ProtocolBox.Items.Add('SFTP');
    ProtocolBox.ItemIndex := ProtocolBox.Items.IndexOf(UpperCase(Entry.SyncProtocol));
    if ProtocolBox.ItemIndex < 0 then ProtocolBox.ItemIndex := 2;

    AddLabel('Remote host'); HostEdit := AddEdit(Entry.SyncHost);
    AddLabel('Port'); PortEdit := AddEdit(IntToStr(Entry.SyncPort)); PortEdit.Width := 120;
    AddLabel('Username'); UserEdit := AddEdit(Entry.SyncUsername);
    AddLabel('Private key'); KeyEdit := AddEdit(Entry.SyncPrivateKeyFile);
    AddLabel('Remote path'); RemoteEdit := AddEdit(Entry.SyncRemotePath);

    AddLabel('Direction');
    DirectionBox := TComboBox.Create(Dialog);
    DirectionBox.Parent := Dialog; DirectionBox.Left := 190; DirectionBox.Top := LabelTop - 28;
    DirectionBox.Width := 160; DirectionBox.Style := csDropDownList;
    DirectionBox.Items.Add('Upload'); DirectionBox.Items.Add('Download');
    if SameText(Entry.SyncDirection, 'download') then
      DirectionBox.ItemIndex := 1
    else
      DirectionBox.ItemIndex := 0;

    AddLabel('FreeFileSync mode');
    VariantBox := TComboBox.Create(Dialog);
    VariantBox.Parent := Dialog; VariantBox.Left := 190; VariantBox.Top := LabelTop - 28;
    VariantBox.Width := 160; VariantBox.Style := csDropDownList;
    VariantBox.Items.Add('Update'); VariantBox.Items.Add('Mirror'); VariantBox.Items.Add('Two-way');
    if SameText(Entry.SyncVariant, 'mirror') then VariantBox.ItemIndex := 1
    else if SameText(Entry.SyncVariant, 'twoway') then VariantBox.ItemIndex := 2
    else VariantBox.ItemIndex := 0;

    AddLabel('Exclude patterns'); ExcludesEdit := AddEdit(string.Join(';', Entry.SyncExcludes));
    DeleteCheck := TCheckBox.Create(Dialog);
    DeleteCheck.Parent := Dialog; DeleteCheck.Left := 190; DeleteCheck.Top := LabelTop + 4;
    DeleteCheck.Caption := 'Allow remote deletions'; DeleteCheck.Checked := Entry.SyncDeleteEnabled;

    OkButton := TButton.Create(Dialog); OkButton.Parent := Dialog; OkButton.Caption := 'Save';
    OkButton.ModalResult := mrOk; OkButton.Left := 350; OkButton.Top := 468; OkButton.Width := 90; OkButton.Height := 30;
    CancelButton := TButton.Create(Dialog); CancelButton.Parent := Dialog; CancelButton.Caption := 'Cancel';
    CancelButton.ModalResult := mrCancel; CancelButton.Left := 450; CancelButton.Top := 468; CancelButton.Width := 90; CancelButton.Height := 30;
    Dialog.ActiveControl := HostEdit;

    Result := Dialog.ShowModal = mrOk;
    if not Result then Exit;
    UpdatedEntry.SyncProtocol := LowerCase(ProtocolBox.Text);
    UpdatedEntry.SyncHost := Trim(HostEdit.Text);
    UpdatedEntry.SyncPort := StrToIntDef(Trim(PortEdit.Text), 0);
    UpdatedEntry.SyncUsername := Trim(UserEdit.Text);
    UpdatedEntry.SyncPrivateKeyFile := Trim(KeyEdit.Text);
    UpdatedEntry.SyncRemotePath := Trim(RemoteEdit.Text);
    UpdatedEntry.SyncDirection := LowerCase(DirectionBox.Text);
    UpdatedEntry.SyncVariant := LowerCase(StringReplace(VariantBox.Text, '-', '', [rfReplaceAll]));
    UpdatedEntry.SyncDeleteEnabled := DeleteCheck.Checked;
    UpdatedEntry.SyncExcludes := Trim(ExcludesEdit.Text).Split([';']);
  finally
    Dialog.Free;
  end;
end;

end.
