unit Core.UniWamp.HostsFileService;

interface

uses
  Winapi.Windows,
  Winapi.ShellAPI,
  System.StrUtils,
  System.SysUtils,
  System.Classes,
  System.IOUtils,
  System.Generics.Collections,

  Core.UniWamp.Paths,
  Core.UniWamp.AtomicFile,
  Core.UniWamp.Config,
  Core.UniWamp.Interfaces,
  Core.UniWamp.ProcessManager,
  Core.UniWamp.Security;

type
  THostsFileService = class(TInterfacedObject, IHostsFileService)
  private
    FPaths: TAppPaths;
    FConfig: TUniWampConfig;
  public
    function HostsFilePath: string;
    constructor Create(const Paths: TAppPaths; Config: TUniWampConfig);
    function SyncHostsFile(out ErrorMessage: string): Boolean;
    function RenderManagedHostsBlock: string;
  end;

implementation

function THostsFileService.HostsFilePath: string;
var
  SystemRoot: string;
  ConfiguredHostsFile: string;
begin
  ConfiguredHostsFile := GetEnvironmentVariable('UNIWAMP_HOSTS_FILE');
  if Trim(ConfiguredHostsFile) <> '' then
    Exit(ConfiguredHostsFile);

  SystemRoot := GetEnvironmentVariable('SystemRoot');
  if SystemRoot = '' then
    SystemRoot := 'C:\Windows';
  Result := TPath.Combine(SystemRoot, 'System32\drivers\etc\hosts');
end;

const
  ManagedHostsBeginMarker = '# BEGIN UniWamp Managed Hosts';
  ManagedHostsEndMarker = '# END UniWamp Managed Hosts';

constructor THostsFileService.Create(const Paths: TAppPaths; Config: TUniWampConfig);
begin
  inherited Create;
  FPaths := Paths;
  FConfig := Config;
end;

function TryElevatedHostsSync(const TempHostsFile: string; out ErrorMessage: string): Boolean;
var
  SEI: TShellExecuteInfo;
  ExitCode: DWORD;
  WaitRes: DWORD;
begin
  Result := False;
  ErrorMessage := '';
  ZeroMemory(@SEI, SizeOf(SEI));
  SEI.cbSize := SizeOf(SEI);
  SEI.fMask := SEE_MASK_NOCLOSEPROCESS;
  SEI.lpVerb := 'runas';
  SEI.lpFile := PChar(ParamStr(0));
  SEI.lpParameters := PChar('--sync-hosts "' + TempHostsFile + '"');
  SEI.nShow := SW_HIDE;
  if not ShellExecuteEx(@SEI) then
  begin
    ErrorMessage := SysErrorMessage(GetLastError);
    Exit;
  end;
  try
    if SEI.hProcess = 0 then
    begin
      ErrorMessage := 'Elevated hosts sync did not return a process handle.';
      Exit;
    end;
    WaitRes := WaitForSingleObject(SEI.hProcess, 30000);
    if WaitRes <> WAIT_OBJECT_0 then
    begin
      ErrorMessage := 'Elevated hosts sync timed out.';
      Exit;
    end;
    if not GetExitCodeProcess(SEI.hProcess, ExitCode) or (ExitCode <> 0) then
    begin
      ErrorMessage := Format('Elevated hosts sync failed with exit code %d.', [ExitCode]);
      Exit;
    end;
    Result := True;
  finally
    if SEI.hProcess <> 0 then
      CloseHandle(SEI.hProcess);
  end;
end;

function THostsFileService.SyncHostsFile(out ErrorMessage: string): Boolean;
var
  HostsPath: string;
  BackupPath: string;
  HostsText: string;
  StartPos: Integer;
  EndPos: Integer;
  ManagedBlock: string;
  TempHostsFile: string;
  ElevError: string;
  GuidVal: TGUID;
  function IsAccessDenied(const E: Exception): Boolean;
  begin
    Result := (E is EOSError) and (EOSError(E).ErrorCode = ERROR_ACCESS_DENIED);
  end;
begin
  Result := False;
  ErrorMessage := '';
  HostsPath := HostsFilePath;
  BackupPath := HostsPath + '.bak';
  ManagedBlock := RenderManagedHostsBlock;

  try
    if FileExists(HostsPath) then
      HostsText := TFile.ReadAllText(HostsPath, TEncoding.ASCII)
    else
      HostsText := '';

    StartPos := Pos(ManagedHostsBeginMarker, HostsText);
    if StartPos > 0 then
    begin
      EndPos := PosEx(ManagedHostsEndMarker, HostsText, StartPos);
      if (EndPos > 0) and (EndPos >= StartPos) then
      begin
        EndPos := EndPos + Length(ManagedHostsEndMarker);
        while (EndPos <= Length(HostsText)) and CharInSet(HostsText[EndPos], [#13, #10]) do
          Inc(EndPos);
        Delete(HostsText, StartPos, EndPos - StartPos);
      end;
    end;

    HostsText := TrimRight(HostsText);
    if HostsText <> '' then
      HostsText := HostsText + sLineBreak + sLineBreak;
    HostsText := HostsText + ManagedBlock;
    AtomicWriteTextFile(HostsPath, HostsText, TEncoding.ASCII, BackupPath);
    FConfig.LastHostsSyncStatus := 'Hosts synced';
    Result := True;
  except
    on E: Exception do
    begin
      if IsAccessDenied(E) and (Trim(GetEnvironmentVariable('UNIWAMP_HOSTS_FILE')) = '') then
      begin
        CreateGUID(GuidVal);
        TempHostsFile := TPath.Combine(FPaths.TmpDir,
          'hosts-sync-' + GUIDToString(GuidVal).Replace('{', '').Replace('}', '') + '.tmp');
        try
          EnsureDirectory(FPaths.TmpDir);
          AtomicWriteTextFile(TempHostsFile, HostsText, TEncoding.ASCII);
          if TryElevatedHostsSync(TempHostsFile, ElevError) then
          begin
            FConfig.LastHostsSyncStatus := 'Hosts synced (elevated)';
            Result := True;
            Exit;
          end;
          FConfig.LastHostsSyncStatus := 'Hosts update requires Administrator';
          ErrorMessage := 'Hosts file update failed: ' + ElevError;
        finally
          if FileExists(TempHostsFile) then
            TFile.Delete(TempHostsFile);
        end;
        Exit;
      end;

      if IsAccessDenied(E) then
        FConfig.LastHostsSyncStatus := 'Hosts update requires Administrator'
      else
        FConfig.LastHostsSyncStatus := 'Hosts update failed';
      ErrorMessage := 'Hosts file update failed: ' + E.Message;
    end;
  end;
end;

function THostsFileService.RenderManagedHostsBlock: string;
var
  Hosts: TStringList;
  ManagedHosts: TStringList;
  Entry: TVHostEntry;
  ManagedHostEntry: string;
  ManagedHostLine: string;
begin
  Hosts := TStringList.Create;
  ManagedHosts := TStringList.Create;
  try
    for Entry in FConfig.VHosts do
      if Trim(Entry.ServerName) <> '' then
      begin
        ManagedHostLine := '127.0.0.1 ' + Trim(Entry.ServerName);
        if Trim(Entry.ServerAliases) <> '' then
          ManagedHostLine := ManagedHostLine + ' ' + Trim(Entry.ServerAliases);
        if ManagedHosts.IndexOf(ManagedHostLine) < 0 then
          ManagedHosts.Add(ManagedHostLine);
      end;
    ManagedHosts.Sort;

    Hosts.Add(ManagedHostsBeginMarker);
    Hosts.Add('127.0.0.1 ' + FConfig.HostName);
    for ManagedHostEntry in ManagedHosts do
      Hosts.Add(ManagedHostEntry);
    Hosts.Add(ManagedHostsEndMarker);
    Result := Hosts.Text;
  finally
    ManagedHosts.Free;
    Hosts.Free;
  end;
end;

end.
