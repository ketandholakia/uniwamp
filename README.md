# UniWamp

UniWamp is a portable Windows WAMP dashboard built in Delphi 12.4. It controls a local Apache, MariaDB, and PHP stack from a single VCL app and keeps its runtime state inside the UniWamp folder.

## What It Does

- Starts, stops, and restarts Apache
- Starts, stops, and restarts MariaDB
- Detects bundled PHP versions and lets you select the active one
- Manages enabled PHP extensions for the active PHP runtime
- Generates Apache, PHP, and MariaDB config files from UniWamp templates
- Manages local virtual hosts
- Launches the local site, Adminer, logs, terminals, and local developer tools
- Optionally generates a self-signed SSL certificate
- Checks for basic port conflicts before startup

## Repository Layout

- `src/` - Delphi source code
- `runtime/` - bundled runtime folders for Apache, MariaDB, PHP, and optional Node.js
- `config/` - app state and generated configuration output
- `templates/` - UniWamp-owned config templates
- `www/` - default web root and vhost content
- `home/` - local app tools such as Adminer
- `ssl/` - local certificate output
- `logs/` - activity and service logs
- `tmp/` - temporary files
- `tests/` - smoke test script
- `src/assets/` - embedded PNG icon and header sources used to build the UI resource bundle

## Requirements

- Windows
- Delphi 12.4 to build the VCL app
- Apache, MariaDB, and PHP binaries placed into the expected runtime folders
- UI icon PNGs are embedded into the EXE at build time from `src/assets`

## Defaults

The app ships with sensible defaults stored in `config/uniwamp.json`. Current defaults in the repository are:

- **HTTP port:** 8080
- **HTTPS port:** 8443
- **MariaDB port:** 3309
- **Default document root:** `www`
- **Selected PHP version:** php85
- **Selected Node version:** node-v22.23.1-win-x64
- **Terminal executable (terminalExePath):** bin\\cmder\\Cmder.exe

## Runtime Files To Provide

Place your own binaries into these locations:

- `runtime/apache/bin/httpd.exe`
- `runtime/mariadb/bin/mariadbd.exe`
- `runtime/mariadb/bin/mysqladmin.exe`
- `runtime/php/<version>/php.exe`
- `runtime/php/<version>/php8apache2_4.dll` or a compatible Apache PHP module

Optional:

- `runtime/apache/bin/openssl.exe`
- `runtime/nodejs/<version>/...`
- `bin/cmder/Cmder.exe`

Adminer should be placed at:

- `home/adminer/index.php`

## Terminal Launcher

UniWamp launches a terminal using `terminalExePath` from `config/uniwamp.json`.

Default value:

- `bin\\cmder\\Cmder.exe`

If you want a different Cmder location, update `terminalExePath` to the full path or a path relative to the UniWamp root.

The main Tools menu and tool panel also expose:

- `Open Site` to launch the local root site
- `Open Adminer` to launch Adminer when `home/adminer/index.php` exists
- `Terminal` to launch the configured terminal executable
- `Repo Terminal` to open a terminal at the UniWamp root for Git and maintenance work
- `Composer`, `Git`, `Node`, `WP-CLI`, `npm`, `yarn`, `pnpm`, `Mailpit`, `Redis`, `Memcached`, and `Editor` launchers when the corresponding executables are available on PATH
- `Update` to stage a manifest-driven package into `tmp\updates`
- The second tool row keeps the repository-oriented launchers and update action grouped together for faster maintenance work
- `Copy Report` to copy a diagnostic snapshot with paths, versions, ports, service state, and recent errors
- `Copy Activity` to copy the current activity log to the clipboard
- `Esc` to close the main window through the normal shutdown flow

## Configuration

Primary app state is stored in:

- `config/uniwamp.json`

Common settings include:

- HTTP port
- HTTPS port
- MariaDB port
- host name
- document root
- active PHP version
- active Node.js version
- SSL toggle
- virtual hosts
- terminal executable path

Generated config files are written to:

- `config/generated/httpd.conf`
- `config/generated/httpd-ssl.conf`
- `config/generated/httpd-vhosts.conf`
- `config/generated/php.ini`
- `config/generated/mariadb.ini`
- `config/generated/env.bat`

The generated Cmder environment file exports:

- `UNIWAMP_ROOT`
- `UNIWAMP_DOCROOT`
- `UNIWAMP_MARIADB_BIN`
- `PHP_HOME`
- `PHP_BIN`
- `NODE_HOME` when a Node version is selected
- `NODE_BIN` when a Node version is selected

It switches Cmder to a green-on-black color scheme and shows the selected PHP version, Node version, working path, and MariaDB bin path when Cmder opens.

## Build

Open `src/UniWamp.dpr` in Delphi 12.4 and build the Win32 or Win64 VCL target.

## Verification

Run the full local verification flow from the repository root:

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File .\tests\run-all.ps1
```

This builds the app, builds the config harness, runs the smoke test, and runs the config assertions.
It also builds and runs the process harness for process-manager and lifecycle checks.
The process harness now also covers terminal/editor fallback ordering, runtime archive integrity checks, staged update validation, rollback, promotion, promotion rollback recovery, and workspace cleanup helpers.

## Installer

The repo includes profile-specific Inno Setup scripts:

- `installer/UniWamp.Php82.iss`
- `installer/UniWamp.Php83.iss`
- `installer/UniWamp.Php84.iss`
- `installer/UniWamp.Php85.iss`
- `installer/UniWamp.Full.iss`

To build the installer on a machine with Delphi and Inno Setup installed:

1. Build the app so `src\tmpbuild\bin\UniWamp.exe` exists.
2. Run `installer\build-installer.bat`.

The build script generates five installer files:

- `UniWamp-Php82-Setup-<version>.exe`
- `UniWamp-Php83-Setup-<version>.exe`
- `UniWamp-Php84-Setup-<version>.exe`
- `UniWamp-Php85-Setup-<version>.exe`
- `UniWamp-Full-Setup-<version>.exe`

Profile scope:

- Php82: Apache, MariaDB, and PHP 82
- Php83: Apache, MariaDB, and PHP 83
- Php84: Apache, MariaDB, and PHP 84
- Php85: Apache, MariaDB, and PHP 85
- Full: Apache, MariaDB, PHP 82/83/84/85, and a preseeded `runtime/mariadb/data` folder

Each profile-specific script includes the same shared payload rules from `installer/UniWamp.Common.issinc`.

The installer packages the portable app tree into a user-writable install folder and creates the runtime directories UniWamp needs on first launch.

## Update Model

UniWamp now includes a local staged update flow for future package management work:

1. Validate an update manifest that names the package, version, and expected SHA-256.
2. Verify the package hash before extraction.
3. Extract into a portable workspace under `tmp\updates`.
4. Write staging metadata alongside the extracted package.
5. Promote the staged workspace into the target folder with a backup of the previous target tree.
6. Clean up the workspace when the update is complete or cancelled.

Remote downloads are intentionally not part of the current flow.

## Notes

- UniWamp does not install Windows services.
- The app keeps its config and generated files inside the repository folder.
- Apache, MariaDB, and PHP are expected to be portable binaries, not system-wide installs.
- No files are copied from `uniserver-master`.

## Development documentation

- [Architecture](docs/ARCHITECTURE.md)
- [Development plan](docs/DEVELOPMENT_PLAN.md)
- [Test and verification plan](docs/TEST_PLAN.md)
- [Security and operations checklist](docs/SECURITY_AND_OPERATIONS.md)
