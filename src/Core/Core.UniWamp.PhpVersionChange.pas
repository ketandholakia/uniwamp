unit Core.UniWamp.PhpVersionChange;

interface

uses
  System.SysUtils,
  Core.UniWamp.Config,
  Core.UniWamp.Paths,
  Core.UniWamp.Types;

type
  TPhpVersionChangeSaveProc = reference to procedure;
  TPhpVersionChangeGenerateProc = reference to procedure;
  TPhpVersionChangeRestartFunc = reference to function: TRuntimeActionResult;
  TPhpVersionChangeIsRunningFunc = reference to function: Boolean;

function CommitPhpVersionChange(var Config: TUniWampConfig; const Paths: TAppPaths;
  const OldPhpVersion, NewPhpVersion: string; const SaveConfig: TPhpVersionChangeSaveProc;
  const GenerateAllConfigs: TPhpVersionChangeGenerateProc; const RestartApache: TPhpVersionChangeRestartFunc;
  const ApacheIsRunning: TPhpVersionChangeIsRunningFunc; out ErrorMessage: string): Boolean;

implementation

function CommitPhpVersionChange(var Config: TUniWampConfig; const Paths: TAppPaths;
  const OldPhpVersion, NewPhpVersion: string; const SaveConfig: TPhpVersionChangeSaveProc;
  const GenerateAllConfigs: TPhpVersionChangeGenerateProc; const RestartApache: TPhpVersionChangeRestartFunc;
  const ApacheIsRunning: TPhpVersionChangeIsRunningFunc; out ErrorMessage: string): Boolean;
var
  RestartInfo: TRuntimeActionResult;
  RestoreError: string;
begin
  Result := False;
  ErrorMessage := '';
  try
    Config.SelectedPhpVersion := NewPhpVersion;
    SaveConfig();
    GenerateAllConfigs();

    if ApacheIsRunning() and not SameText(OldPhpVersion, NewPhpVersion) then
    begin
      RestartInfo := RestartApache();
      if not RestartInfo.Success then
      begin
        Config.SelectedPhpVersion := OldPhpVersion;
        try
          SaveConfig();
          GenerateAllConfigs();
        except
          on E: Exception do
          begin
            RestoreError := E.Message;
            if RestoreError <> '' then
              RestartInfo.Message := RestartInfo.Message + ' Rollback save failed: ' + RestoreError;
          end;
        end;
        ErrorMessage := 'Apache restart failed: ' + RestartInfo.Message;
        Exit(False);
      end;
    end;

    Result := True;
  except
    on E: Exception do
    begin
      ErrorMessage := E.Message;
      Result := False;
    end;
  end;
end;

end.
