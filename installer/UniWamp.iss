#define MyAppName "UniWamp"
#define MyAppExeName "UniWamp.exe"
#define MyAppVersion GetFileVersion("..\src\tmpbuild\bin\UniWamp.exe")

[Setup]
AppId={{B1E4A0B5-4D8E-4D2A-8D1B-9D7D2A77F3C1}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppVerName={#MyAppName} {#MyAppVersion}
AppPublisher=UniWamp
DefaultDirName={userdocs}\UniWamp
DefaultGroupName=UniWamp
DisableProgramGroupPage=no
DisableDirPage=no
AllowNoIcons=yes
PrivilegesRequired=lowest
OutputDir=Output
OutputBaseFilename=UniWamp-Setup-{#MyAppVersion}
SetupIconFile=..\src\UniWamp_Icon.ico
UninstallDisplayIcon={app}\{#MyAppExeName}
Compression=lzma2/ultra64
SolidCompression=yes
WizardStyle=modern
ArchitecturesAllowed=x86compatible x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
CloseApplications=no
DisableStartupPrompt=yes
UsePreviousAppDir=yes
UsePreviousGroup=yes
VersionInfoVersion={#MyAppVersion}
VersionInfoDescription=UniWamp portable WAMP dashboard

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Dirs]
Name: "{app}\config"
Name: "{app}\config\generated"
Name: "{app}\logs"
Name: "{app}\ssl"
Name: "{app}\tmp"
Name: "{app}\vhosts"

[Files]
Source: "..\src\tmpbuild\bin\{#MyAppExeName}"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\src\UniWamp_Icon.ico"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\runtime\*"; DestDir: "{app}\runtime"; Flags: recursesubdirs createallsubdirs ignoreversion
Source: "..\templates\*"; DestDir: "{app}\templates"; Flags: recursesubdirs createallsubdirs ignoreversion
Source: "..\home\*"; DestDir: "{app}\home"; Flags: recursesubdirs createallsubdirs ignoreversion
Source: "..\www\*"; DestDir: "{app}\www"; Flags: recursesubdirs createallsubdirs ignoreversion
Source: "..\bin\cmder\*"; DestDir: "{app}\bin\cmder"; Flags: recursesubdirs createallsubdirs ignoreversion

[Icons]
Name: "{group}\UniWamp"; Filename: "{app}\{#MyAppExeName}"
Name: "{autodesktop}\UniWamp"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Tasks]
Name: "desktopicon"; Description: "Create a &desktop icon"; GroupDescription: "Additional icons:"

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "&Launch UniWamp"; Flags: nowait postinstall skipifsilent
