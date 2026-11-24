unit Test.UniWamp.Diagnostics;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TDiagnosticsTests = class
  public
    [Test]
    procedure TestRedactSensitiveTextRedactsKnownSecrets;
    [Test]
    procedure TestRedactSensitiveTextRedactsBase64SyncPassword;
    [Test]
    procedure TestChooseActivityLogClipboardTextPrefersFileText;
  end;

implementation

uses
  System.SysUtils,
  Core.UniWamp.Diagnostics;

procedure TDiagnosticsTests.TestRedactSensitiveTextRedactsKnownSecrets;
var
  Text: string;
begin
  Text := 'password=abc123 token=xyz secret=top pass=letmein';
  Text := RedactSensitiveText(Text);

  Assert.AreEqual(0, Pos('abc123', Text), Text);
  Assert.AreEqual(0, Pos('xyz', Text), Text);
  Assert.AreEqual(0, Pos('top', Text), Text);
  Assert.AreEqual(0, Pos('letmein', Text), Text);
  Assert.IsTrue(Pos('[redacted]', Text) > 0, Text);
end;

procedure TDiagnosticsTests.TestRedactSensitiveTextRedactsBase64SyncPassword;
var
  Text: string;
begin
  // FreeFileSync job URLs embed the password as |pass64=<base64>; the 'pass='
  // rule does not match that key, so it needs its own.
  Text := 'sftp://user@example.com/mnt|pass64=c2VjcmV0';
  Text := RedactSensitiveText(Text);

  Assert.AreEqual(0, Pos('c2VjcmV0', Text), Text);
  Assert.Contains(Text, 'pass64=[redacted]', Text);
end;

procedure TDiagnosticsTests.TestChooseActivityLogClipboardTextPrefersFileText;
begin
  Assert.AreEqual('log text', ChooseActivityLogClipboardText('log text', 'memo text'));
  Assert.AreEqual('memo text', ChooseActivityLogClipboardText('', 'memo text'));
  Assert.AreEqual('', ChooseActivityLogClipboardText('', ''));
end;

initialization
  TDUnitX.RegisterTestFixture(TDiagnosticsTests);

end.
