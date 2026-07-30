unit Test.UniWamp.ScriptEngine;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TScriptEngineTests = class
  public
    [Test]
    procedure TestFormatGeneratedAdminPasswordMessage_RedactsPassword;
  end;

implementation

uses
  System.SysUtils,
  Core.UniWamp.ScriptEngine;

procedure TScriptEngineTests.TestFormatGeneratedAdminPasswordMessage_RedactsPassword;
var
  MessageText: string;
begin
  MessageText := FormatGeneratedAdminPasswordMessage('db1', 'admin1');
  Assert.AreEqual(
    'Created database "db1" and user "admin1". Generated admin password: [redacted] (save it now).',
    MessageText);
end;

initialization
  TDUnitX.RegisterTestFixture(TScriptEngineTests);

end.
