program RegTest;
{$APPTYPE CONSOLE}
uses
  Winapi.Windows, System.SysUtils, System.Win.Registry;
var
  Registry: TRegistry;
  CurrentCmd: string;
begin
  Registry := TRegistry.Create(KEY_ALL_ACCESS);
  try
    Registry.RootKey := HKEY_CURRENT_USER;
    if Registry.OpenKey('Software\Microsoft\Windows\CurrentVersion\Run', False) then
    begin
      Writeln('Opened key');
      if Registry.ValueExists('UniWamp') then
      begin
        CurrentCmd := Registry.ReadString('UniWamp');
        Writeln('Current: ', CurrentCmd);
        Registry.WriteString('UniWamp', 'FixedPath');
        Writeln('Wrote FixedPath');
      end else
        Writeln('Value missing');
    end else
      Writeln('Could not open key');
  except
    on E: Exception do
      Writeln('Error: ', E.Message);
  end;
  Registry.Free;
end.
