unit Test.UniWamp.FtpTransport;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TFtpTransportTests = class
  public
    [Test]
    procedure TestDefaultFtpsCaBundleFile_PointsToBundledPem;
    [Test]
    procedure TestFtpsHostMatchesCertificateSubject_ExactCn;
    [Test]
    procedure TestFtpsHostMatchesCertificateSubject_WildcardCn;
    [Test]
    procedure TestFtpsHostMatchesCertificateSubject_RejectsWrongHost;
  end;

implementation

uses
  System.SysUtils,
  Core.UniWamp.FtpTransport;

procedure TFtpTransportTests.TestDefaultFtpsCaBundleFile_PointsToBundledPem;
begin
  Assert.IsTrue(FileExists(DefaultFtpsCaBundleFile),
    'Bundled FTPS CA bundle should exist.');
  Assert.IsTrue(DefaultFtpsCaBundleFile.EndsWith('runtime\certs\cacert.pem', True),
    'FTPS CA bundle path should point to runtime\certs\cacert.pem.');
end;

procedure TFtpTransportTests.TestFtpsHostMatchesCertificateSubject_ExactCn;
begin
  Assert.IsTrue(FtpsHostMatchesCertificateSubject('ftp.example.test',
    '/C=US/ST=WA/L=Seattle/O=Example/CN=ftp.example.test'),
    'Exact CN should match the FTPS host.');
end;

procedure TFtpTransportTests.TestFtpsHostMatchesCertificateSubject_WildcardCn;
begin
  Assert.IsTrue(FtpsHostMatchesCertificateSubject('cdn.example.test',
    '/C=US/ST=WA/L=Seattle/O=Example/CN=*.example.test'),
    'Wildcard CN should match a single-label subdomain.');
end;

procedure TFtpTransportTests.TestFtpsHostMatchesCertificateSubject_RejectsWrongHost;
begin
  Assert.IsFalse(FtpsHostMatchesCertificateSubject('ftp.example.test',
    '/C=US/ST=WA/L=Seattle/O=Example/CN=api.example.test'),
    'Different CN should be rejected.');
  Assert.IsFalse(FtpsHostMatchesCertificateSubject('deep.cdn.example.test',
    '/C=US/ST=WA/L=Seattle/O=Example/CN=*.example.test'),
    'Wildcard CN should not match multi-label subdomains.');
end;

initialization
  TDUnitX.RegisterTestFixture(TFtpTransportTests);

end.
