# UniWamp

UniWamp is a portable Windows WAMP dashboard built in Delphi 12.4. It controls a local Apache, MariaDB, and PHP stack from a single VCL app and keeps its runtime state inside the UniWamp folder.

## What It Does

- Starts, stops, and restarts Apache
- Starts, stops, and restarts MariaDB
- Detects bundled PHP versions and lets you select the active one
- Manages enabled PHP extensions for the active PHP runtime
- Generates Apache, PHP, and MariaDB config files from UniWamp templates
- Manages local virtual hosts
- Launches the local site, Adminer, logs, and a terminal
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

## Requirements

- Windows
- Delphi 12.4 to build the VCL app
- Apache, MariaDB, and PHP binaries placed into the expected runtime folders

## Defaults

The app ships with sensible defaults stored in `config/uniwamp.json`. Current defaults in the repository are:

- **HTTP port:** 8080
- **HTTPS port:** 8443
- **MariaDB port:** 3309
- **Default document root:** 
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

## Installer

The repo includes an Inno Setup script at `installer/UniWamp.iss`.

To build the installer on a machine with Delphi and Inno Setup installed:

1. Build the app so `src\tmpbuild\bin\UniWamp.exe` exists.
2. Run `installer\build-installer.bat`.

The installer packages the portable app tree into a user-writable install folder and creates the runtime directories UniWamp needs on first launch.

## Notes

- UniWamp does not install Windows services.
- The app keeps its config and generated files inside the repository folder.
- Apache, MariaDB, and PHP are expected to be portable binaries, not system-wide installs.
- No files are copied from `uniserver-master`.
