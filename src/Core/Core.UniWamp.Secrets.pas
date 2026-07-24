unit Core.UniWamp.Secrets;

interface

uses
  Core.UniWamp.Paths;

function LoadMariaDbRootPassword(const Paths: TAppPaths): string;
function SaveMariaDbRootPassword(const Paths: TAppPaths; const Password: string; out ErrorMessage: string): Boolean;
function DeleteMariaDbRootPassword(const Paths: TAppPaths; out ErrorMessage: string): Boolean;
function HasMariaDbRootPassword(const Paths: TAppPaths): Boolean;

// Generic keyed secret store (DPAPI, per-Windows-user, bound to this app install).
// Used for sync profile passwords and SFTP private-key passphrases.
// Key examples: 'sync:MyProfile:password', 'sync:MyProfile:keypassphrase'.
function LoadSecret(const Paths: TAppPaths; const Key: string): string;
function SaveSecret(const Paths: TAppPaths; const Key, Value: string; out ErrorMessage: string): Boolean;
function DeleteSecret(const Paths: TAppPaths; const Key: string; out ErrorMessage: string): Boolean;
function HasSecret(const Paths: TAppPaths; const Key: string): Boolean;

function SyncPasswordKey(const ProfileName: string): string;
function SyncKeyPassphraseKey(const ProfileName: string): string;
procedure DeleteAllSyncSecrets(const Paths: TAppPaths; const ProfileName: string);

implementation

uses
  Winapi.Windows,
  System.Classes,
  System.Hash,
  System.IOUtils,
  System.SysUtils;

type
  TBytesArray = TArray<Byte>;
  PDataBlob = ^DATA_BLOB;

const
  CRYPTPROTECT_UI_FORBIDDEN = $1;

function CryptProtectData(pDataIn: PDataBlob; szDataDescr: PWideChar; pOptionalEntropy,
  pvReserved: Pointer; pPromptStruct: Pointer; dwFlags: DWORD; pDataOut: PDataBlob): BOOL; stdcall;
  external 'Crypt32.dll' name 'CryptProtectData';
function CryptUnprotectData(pDataIn: PDataBlob; ppszDataDescr: PPWideChar; pOptionalEntropy,
  pvReserved: Pointer; pPromptStruct: Pointer; dwFlags: DWORD; pDataOut: PDataBlob): BOOL; stdcall;
  external 'Crypt32.dll' name 'CryptUnprotectData';

function SecretDirectory: string;
var
  LocalAppData: string;
begin
  LocalAppData := GetEnvironmentVariable('LOCALAPPDATA');
  if LocalAppData = '' then
    LocalAppData := ExcludeTrailingPathDelimiter(TPath.GetTempPath) + '\UniWamp';
  Result := TPath.Combine(LocalAppData, 'UniWamp\secrets');
end;

function SecretFileName(const Paths: TAppPaths; const Key: string = ''): string;
var
  RootHash: string;
begin
  if Trim(Paths.AppRoot) = '' then
    Exit('');
  // Key = '' preserves the original hash formula (legacy MariaDB secret file).
  if Key = '' then
    RootHash := THashSHA2.GetHashString(LowerCase(ExpandFileName(Paths.AppRoot)))
  else
    RootHash := THashSHA2.GetHashString(LowerCase(ExpandFileName(Paths.AppRoot)) + '|' + LowerCase(Key));
  Result := TPath.Combine(SecretDirectory, RootHash + '.dat');
end;

function ProtectBytes(const PlainText: string; out ProtectedBytes: TBytesArray): Boolean;
var
  InBlob: DATA_BLOB;
  OutBlob: DATA_BLOB;
  Utf8Bytes: TBytesArray;
begin
  Result := False;
  ProtectedBytes := nil;
  Utf8Bytes := TEncoding.UTF8.GetBytes(PlainText);
  InBlob.cbData := Length(Utf8Bytes);
  if InBlob.cbData = 0 then
    InBlob.pbData := nil
  else
    InBlob.pbData := @Utf8Bytes[0];
  if not CryptProtectData(@InBlob, nil, nil, nil, nil, CRYPTPROTECT_UI_FORBIDDEN, @OutBlob) then
    Exit;
  try
    SetLength(ProtectedBytes, OutBlob.cbData);
    if OutBlob.cbData > 0 then
      Move(OutBlob.pbData^, ProtectedBytes[0], OutBlob.cbData);
    Result := True;
  finally
    LocalFree(HLOCAL(OutBlob.pbData));
  end;
end;

function UnprotectBytes(const ProtectedBytes: TBytesArray; out PlainText: string): Boolean;
var
  InBlob: DATA_BLOB;
  OutBlob: DATA_BLOB;
  Utf8Bytes: TBytesArray;
begin
  Result := False;
  PlainText := '';
  InBlob.cbData := Length(ProtectedBytes);
  if InBlob.cbData = 0 then
    InBlob.pbData := nil
  else
    InBlob.pbData := @ProtectedBytes[0];
  if not CryptUnprotectData(@InBlob, nil, nil, nil, nil, CRYPTPROTECT_UI_FORBIDDEN, @OutBlob) then
    Exit;
  try
    SetLength(Utf8Bytes, OutBlob.cbData);
    if OutBlob.cbData > 0 then
      Move(OutBlob.pbData^, Utf8Bytes[0], OutBlob.cbData);
    PlainText := TEncoding.UTF8.GetString(Utf8Bytes);
    Result := True;
  finally
    LocalFree(HLOCAL(OutBlob.pbData));
  end;
end;

function LoadMariaDbRootPassword(const Paths: TAppPaths): string;
var
  FileName: string;
  ProtectedBytes: TBytesArray;
begin
  Result := '';
  FileName := SecretFileName(Paths);
  if (FileName = '') or not FileExists(FileName) then
    Exit;
  try
    ProtectedBytes := TFile.ReadAllBytes(FileName);
    if not UnprotectBytes(ProtectedBytes, Result) then
      Result := '';
  except
    Result := '';
  end;
end;

function SaveMariaDbRootPassword(const Paths: TAppPaths; const Password: string; out ErrorMessage: string): Boolean;
var
  FileName: string;
  ProtectedBytes: TBytesArray;
begin
  Result := False;
  ErrorMessage := '';
  if Password = '' then
    Exit(DeleteMariaDbRootPassword(Paths, ErrorMessage));
  if not ProtectBytes(Password, ProtectedBytes) then
  begin
    ErrorMessage := 'MariaDB secret could not be protected.';
    Exit;
  end;
  FileName := SecretFileName(Paths);
  if FileName = '' then
  begin
    ErrorMessage := 'MariaDB secret file path is unavailable.';
    Exit;
  end;
  try
    EnsureDirectory(SecretDirectory);
    TFile.WriteAllBytes(FileName, ProtectedBytes);
    Result := True;
  except
    on E: Exception do
      ErrorMessage := 'MariaDB secret could not be written: ' + E.Message;
  end;
end;

function DeleteMariaDbRootPassword(const Paths: TAppPaths; out ErrorMessage: string): Boolean;
var
  FileName: string;
begin
  Result := True;
  ErrorMessage := '';
  FileName := SecretFileName(Paths);
  if (FileName = '') or not FileExists(FileName) then
    Exit;
  try
    TFile.Delete(FileName);
  except
    on E: Exception do
    begin
      Result := False;
      ErrorMessage := 'MariaDB secret could not be deleted: ' + E.Message;
    end;
  end;
end;

function HasMariaDbRootPassword(const Paths: TAppPaths): Boolean;
begin
  Result := LoadMariaDbRootPassword(Paths) <> '';
end;

function LoadSecret(const Paths: TAppPaths; const Key: string): string;
var
  FileName: string;
  ProtectedBytes: TBytesArray;
begin
  Result := '';
  FileName := SecretFileName(Paths, Key);
  if (FileName = '') or not FileExists(FileName) then
    Exit;
  try
    ProtectedBytes := TFile.ReadAllBytes(FileName);
    if not UnprotectBytes(ProtectedBytes, Result) then
      Result := '';
  except
    Result := '';
  end;
end;

function SaveSecret(const Paths: TAppPaths; const Key, Value: string; out ErrorMessage: string): Boolean;
var
  FileName: string;
  ProtectedBytes: TBytesArray;
begin
  Result := False;
  ErrorMessage := '';
  if Value = '' then
    Exit(DeleteSecret(Paths, Key, ErrorMessage));
  if not ProtectBytes(Value, ProtectedBytes) then
  begin
    ErrorMessage := 'Secret could not be protected.';
    Exit;
  end;
  FileName := SecretFileName(Paths, Key);
  if FileName = '' then
  begin
    ErrorMessage := 'Secret file path is unavailable.';
    Exit;
  end;
  try
    EnsureDirectory(SecretDirectory);
    TFile.WriteAllBytes(FileName, ProtectedBytes);
    Result := True;
  except
    on E: Exception do
      ErrorMessage := 'Secret could not be written: ' + E.Message;
  end;
end;

function DeleteSecret(const Paths: TAppPaths; const Key: string; out ErrorMessage: string): Boolean;
var
  FileName: string;
begin
  Result := True;
  ErrorMessage := '';
  FileName := SecretFileName(Paths, Key);
  if (FileName = '') or not FileExists(FileName) then
    Exit;
  try
    TFile.Delete(FileName);
  except
    on E: Exception do
    begin
      Result := False;
      ErrorMessage := 'Secret could not be deleted: ' + E.Message;
    end;
  end;
end;

function HasSecret(const Paths: TAppPaths; const Key: string): Boolean;
begin
  Result := LoadSecret(Paths, Key) <> '';
end;

function SyncPasswordKey(const ProfileName: string): string;
begin
  Result := 'sync:' + LowerCase(Trim(ProfileName)) + ':password';
end;

function SyncKeyPassphraseKey(const ProfileName: string): string;
begin
  Result := 'sync:' + LowerCase(Trim(ProfileName)) + ':keypassphrase';
end;

procedure DeleteAllSyncSecrets(const Paths: TAppPaths; const ProfileName: string);
var
  ErrorMessage: string;
begin
  DeleteSecret(Paths, SyncPasswordKey(ProfileName), ErrorMessage);
  DeleteSecret(Paths, SyncKeyPassphraseKey(ProfileName), ErrorMessage);
end;

end.
