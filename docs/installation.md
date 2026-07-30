# Installation

This guide covers a local source checkout. UniWamp is a portable Windows
application, so the repository folder is the installation root.

## Prerequisites

- Windows 10 or Windows 11 x64 for the current beta target
- Delphi 12.4 or a compatible RAD Studio version with `dcc32.exe` available on
  `PATH`
- Apache, MariaDB, and PHP binaries placed into the expected `runtime\`
  folders
- Optional: Node.js, Cmder, and other bundled developer tools when you want the
  extended launchers to work

See the [beta support matrix](testing/BETA_SUPPORT_MATRIX.md) for the current
validated desktop targets, runtime expectations, and known beta limits.

## Clone the repository

```powershell
git clone https://github.com/ketandholakia/uniwamp.git
cd uniwamp
```

## Prepare the runtime layout

UniWamp expects a portable directory structure under the repository root. The
main application creates missing folders on first launch, but the runtime
executables themselves must be provided.

Required files include:

- `runtime/apache/bin/httpd.exe`
- `runtime/mariadb/bin/mariadbd.exe`
- `runtime/mariadb/bin/mysqladmin.exe`
- `runtime/php/<version>/php.exe`
- `runtime/php/<version>/php8apache2_4.dll` or a compatible Apache PHP module

## Build the desktop app

From a Delphi command prompt:

```bat
cd src
call "<Delphi>\bin\rsvars.bat"
msbuild UniWamp.dproj /t:Build /p:Config=Release /p:Platform=Win32
```

The repo also includes build scripts and verification helpers under `src\`,
`installer\`, and `tests\`.

## Build the installers

From the repository root:

```bat
cd installer
build-installer.bat
```

That script rebuilds the application, refreshes the release manifest, and
compiles the profile-specific Inno Setup packages.

## First launch

1. Start `UniWamp.exe`.
2. Let the app create or load `config\uniwamp.json`.
3. Confirm the selected PHP version and document root are valid.
4. Use the main dashboard to start Apache and MariaDB.

If you want to validate the full repo after a fresh checkout or an upgrade, run:

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File .\tests\run-all.ps1
```

If `pwsh` is not installed, use `powershell.exe` to run the individual helper
scripts from `tests\` and `installer\`.

## Upgrade behavior

- UniWamp upgrades are in-place and keep the portable repository layout
  intact.
- `config\`, `logs\`, `ssl\`, `tmp\`, and generated configuration files stay
  inside the UniWamp folder across upgrades.
- Always rerun `tests\run-all.ps1` after an upgrade to confirm the stack still
  starts, stops, and reports state correctly.

## Optional package-specific setup

- Place Adminer at `home\adminer\index.php`.
- Put a terminal launcher at `bin\cmder\Cmder.exe` or update
  `terminalExePath`.
- Add Node.js runtimes under `runtime\nodejs\` if you use the bundled Node
  launchers.
