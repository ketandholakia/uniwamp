# UniWamp User Manual

This manual explains how to set up and use UniWamp after the binaries are in place.

## 1. First Run

When UniWamp starts for the first time, it creates or loads state from `config/uniwamp.json` and prepares the portable folder structure.

Before using the app, make sure you have placed the required binaries into the expected runtime folders:

- `runtime/apache/bin/httpd.exe`
- `runtime/mariadb/bin/mariadbd.exe`
- `runtime/mariadb/bin/mysqladmin.exe`
- `runtime/php/<version>/php.exe`
- `runtime/php/<version>/php8apache2_4.dll` or a compatible Apache PHP module

If you want the terminal button to open Cmder, place:

- `bin/cmder/Cmder.exe`

If you prefer a different location, set `terminalExePath` in `config/uniwamp.json`.

### Default values

The repository includes a `config/uniwamp.json` with default values. Notable defaults are:

- **HTTP port:** 8080
- **HTTPS port:** 8443
- **Database port:** 3309
- **Default document root:** D:\\ketan\\github\\uniservernxt\\uniwamp\\www
- **Selected PHP version:** php85
- **Selected Node version:** node-v22.23.1-win-x64
- **Terminal executable (terminalExePath):** bin\\cmder\\Cmder.exe

## 2. Main Window

The main window is split into two areas:

- Left side: server settings, port settings, service controls, logs, and terminal launch
- Right side: virtual host list and site actions

The web dashboard is separate from the public web root and is served from:

- `home/dashboard/`

The default site at `/` is now a simple landing page that links to the dashboard and Adminer.

At the bottom, the status bar shows:

- Apache running state and PID
- MariaDB running state and PID
- HTTP port
- selected PHP profile
- selected Node version
- host sync status

## 3. Editing Server Settings

Use the fields in the left side of the window to set:

- Host name
- Document root
- HTTP port
- HTTPS port
- Database port
- PHP version
- Node version
- PHP profile
- SSL enabled or disabled

Click `Save` to write the settings and regenerate the config files.

## 4. Starting And Stopping Services

Use the buttons in the Apache and MariaDB sections to manage services:

- `Start`
- `Stop`
- `Restart`

What happens behind the scenes:

- Apache config is regenerated before Apache starts
- MariaDB config is regenerated before MariaDB starts
- The app checks for obvious port conflicts before startup

If Apache starts successfully, UniWamp opens the local site in your browser.

## 5. PHP And Node Selection

UniWamp discovers subfolders under:

- `runtime/php/`
- `runtime/nodejs/`

Each folder name becomes a selectable version in the UI.

Notes:

- The selected PHP version is used to generate Apache config
- The selected Node version is added to the generated `env.bat` for terminal sessions
- If a selected version folder is missing, UniWamp falls back to the first detected one

## 6. PHP Extensions

Use the PHP extensions section in the dashboard to toggle the modules that are written into `config/generated/php.ini`.

Notes:

- The list is built from the `ext` folder inside the selected PHP runtime
- `php_opcache.dll` is written as a `zend_extension`
- After saving changes, restart Apache so the new PHP settings are loaded

## 7. Virtual Hosts

The virtual host table shows:

- Site name
- Document root
- URL
- Row actions

To add a new virtual host:

1. Click `Add`
2. Enter the server name
3. Enter the document root
4. Optionally enable SSL for that host

To open or manage an existing host:

- Click `Open` to launch the site in a browser
- Click `Root` to open the document folder
- Click `Del` to remove the host

After adding or deleting a host, UniWamp regenerates the vhost config and, if Apache is running, reloads Apache.

## 8. Local Site, Adminer, And Terminal

Use the action buttons near the bottom of the window:

- `Open Site` opens the local root site
- `Open Adminer` opens Adminer if `home/adminer/index.php` exists
- `Terminal` launches the configured terminal executable

Web dashboard navigation:

- Open the dashboard at `/dashboard/`
- Use the left sidebar groups to jump between Stack sections and Tools

Main window shortcuts:

- `Home` opens the local site at `/`
- `Dashboard` opens the TailAdmin control dashboard at `/dashboard/`

Terminal behavior:

- Default path is `bin\\cmder\\Cmder.exe`
- UniWamp generates `config/generated/env.bat` before launch
- The batch file exports `PHP_HOME`, `PHP_BIN`, `NODE_HOME`, `NODE_BIN`, `UNIWAMP_ROOT`, `UNIWAMP_DOCROOT`, and `UNIWAMP_MARIADB_BIN`
- The batch file sets a green-on-black color scheme and shows the selected PHP version, Node version, working path, and MariaDB bin path
- If Cmder is found, UniWamp copies the environment batch file into Cmder's profile area
- If Cmder is not found, the app falls back to standard Windows Command Prompt

## 9. Logs

UniWamp writes activity into:

- `logs/activity.log`

Service logs are available here:

- `logs/apache-error.log`
- `logs/mariadb-error.log`

You can open them directly from the UI.

## 10. SSL

If SSL is enabled, UniWamp can generate a self-signed certificate using OpenSSL when the binary is available.

Expected OpenSSL path:

- `runtime/apache/bin/openssl.exe`

The generated certificate files are written to `ssl/`.

## 11. Shutdown

When you close UniWamp, it tries to stop MariaDB and Apache cleanly.

If a service does not stop cleanly, UniWamp leaves the app open and shows a warning.

## 12. Common Problems

### Apache will not start

Check:

- `runtime/apache/bin/httpd.exe` exists
- the selected PHP folder exists
- the HTTP port is free
- the Apache error log in `logs/apache-error.log`

### MariaDB will not start

Check:

- `runtime/mariadb/bin/mariadbd.exe` exists
- `runtime/mariadb/bin/mysqladmin.exe` exists
- the database port is free
- the MariaDB error log in `logs/mariadb-error.log`

### Terminal button falls back to CMD

Check:

- `bin/cmder/Cmder.exe` exists
- `terminalExePath` in `config/uniwamp.json` points to the correct file

### VHost does not open

Check:

- the document root exists
- the host name is correct
- Apache is running
- the vhost was saved before trying to open it

## 13. File Locations Summary

- App config: `config/uniwamp.json`
- Generated config: `config/generated/`
- Logs: `logs/`
- SSL output: `ssl/`
- Default web root: `www/`
- Adminer: `home/adminer/`
- Cmder: `bin/cmder/Cmder.exe`
