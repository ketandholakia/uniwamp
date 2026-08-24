# REPO TECHNICAL CONTEXT

## 1. PROJECT OVERVIEW
- **Name:** UniWamp
- **Primary Purpose:** A portable Windows WAMP dashboard built in Delphi 12.4 that controls a local Apache, MariaDB, and PHP stack from a single VCL application. It manages virtual hosts, generates configuration files, provides a script catalog for installing PHP applications (WordPress, Laravel, etc.), and bundles developer tools (Adminer, WinSCP, Composer, WP-CLI, Node.js, Git, Cmder, Lite XL, Mailpit, Redis).
- **Target Audience/Domain:** Windows developers needing a portable, zero-install local development stack for PHP applications. Target: Windows 10/11 x64, local development only (not production).

## 2. TECH STACK & DEPENDENCIES
- **Primary Languages:** Delphi 12.4 (Object Pascal), PowerShell 5.1/7+ (build/verification scripts), PHP (dashboard at `home/dashboard/`), Inno Setup (installer scripts)
- **Key Frameworks/Libraries:**
  - VCL (Visual Component Library) - native Windows UI framework
  - madExcept (optional, Debug builds) - exception handling and crash reporting
  - System.JSON, System.Generics, System.Zip, System.Hash - Delphi RTL
  - WinAPI (ShellAPI, Windows, Messages) - process management, file operations
- **Database(s):** MariaDB 11.8.8 (bundled runtime, not a Delphi dependency). The app manages MariaDB as a child process.
- **Package Manager:** None for Delphi (manual binary management). PowerShell scripts handle verification. Inno Setup compiles installers.

## 3. ARCHITECTURE & STRUCTURE
- **Architectural Pattern:** Monolithic desktop application with service orchestration layer. VCL UI owns interaction; Core modules own configuration, runtime orchestration, process management, config generation, secrets, and port inspection. Clear ownership boundaries per `docs/ARCHITECTURE.md`.
- **Key Directories:**
  - `src/Core/` - Business logic: Config, Runtime, ProcessManager, ApacheManager, MariaDbManager, ConfigGenerator, VHostManager, TemplateRenderer, Secrets, PortUtils, ServiceSupervisor, SyncTypes, FreeFileSyncService, ScriptEngine, PackageManager, ProjectBackupService, DatabaseBackupService, HostsFileService, Interfaces, ServiceLocator, Types, Paths, Diagnostics
  - `src/Ui/` - VCL Forms: MainForm, dialogs for VHosts, PHP settings, extensions, scripts, connection/sync profiles, app settings, Apache modules, about, shutdown progress
  - `src/tests/` - DUnitX test harnesses: ConfigHarness, ProcessHarness, unit tests for ConfigGenerator, ProcessManager, MariaDbAuth, Secrets, Security, ScriptEngine, VHostManager, PhpVersionChange, PackageManager, DatabaseBackupService
  - `config/` - `uniwamp.json` (persisted state), `generated/` (Apache, PHP, MariaDB, vhost, SSL, env.bat)
  - `templates/` - Config templates: `httpd.conf.tpl`, `httpd-vhosts.conf.tpl`, `httpd-ssl.conf.tpl`, `php.ini.tpl`, `mariadb.ini.tpl`, `vhost-index.html.tpl`
  - `runtime/` - Bundled binaries: `apache/`, `mariadb/`, `php/php82-85/`, `nodejs/`, `tools/` (composer, git, putty, winscp, lite-xl, mailpit, redis, wp-cli)
  - `home/` - `dashboard/` (PHP status UI), `adminer/`
  - `www/` - Default document root for virtual hosts
  - `ssl/` - Self-signed certificate output
  - `logs/` - Apache, MariaDB, PHP, activity, sync logs
  - `installer/` - Inno Setup scripts (`.iss`), `build-installer.bat`, `GenerateDistributionManifest.ps1`, `distribution-manifest.json`
  - `scripts/` - `catalog.json` (45+ PHP app install scripts), bootstrap scripts
  - `tests/` - `run-all.ps1`, `smoke.ps1`, harness build scripts
  - `docs/` - MkDocs site (Material theme)
- **Entry Points:**
  - `src/UniWamp.dpr` - Delphi program entry, creates `TMainForm`
  - `src/build.bat` - Local Delphi build
  - `tests/run-all.ps1` - Full verification pipeline
  - `installer/build-installer.bat` - Installer build

## 4. ENVIRONMENT & CONFIGURATION
- **Required Environment Variables:** None explicitly required by code. Delphi `BDS` env var used by build scripts to locate `rsvars.bat`. Runtime binaries expected at relative paths under `runtime/`.
- **Configuration Files:**
  - `config/uniwamp.json` - Primary app state (ports, document root, PHP/Node versions, vhosts, sync/connection profiles, Apache modules, PHP extensions/settings, theme, SSL, PIDs)
  - `config/generated/` - Rendered configs: `httpd.conf`, `httpd-vhosts.conf`, `httpd-ssl.conf`, `php.ini`, `mariadb.ini`, `env.bat`
  - `installer/distribution-manifest.json` - Component manifest for installer (versions, SHA256, licenses)
  - `scripts/catalog.json` - Script catalog schema v1 (install steps: run, create_database_user, write_file, create_directory)
  - `mkdocs.yml` - Documentation site config
  - `.github/workflows/windows-build.yml` - CI (self-hosted Windows runner)

## 5. BUILD, RUN & DEPLOYMENT
- **Local Setup Commands:**
  1. Install Delphi 12.4
  2. Place runtime binaries: `runtime/apache/bin/httpd.exe`, `runtime/mariadb/bin/mariadbd.exe`, `runtime/php/<version>/php.exe`, `runtime/php/<version>/php8apache2_4.dll`
  3. Optional: `bin/cmder/Cmder.exe`, `home/adminer/index.php`, `runtime/tools/putty/psftp.exe`, `runtime/nodejs/<version>/`
  4. Build: `cd src && call "<Delphi>\bin\rsvars.bat" && msbuild UniWamp.dproj /t:Build /p:Config=Release /p:Platform=Win32`
  5. Run: `src/tmpbuild/bin/UniWamp.exe` (or `out/UniWamp.exe` after manual copy)
- **Build Command:** `msbuild UniWamp.dproj /t:Build /p:Config=Release /p:Platform=Win32 /p:DCC_ExeOutput=tmpbuild\bin /p:DCC_DcuOutput=tmpbuild\dcu` (from `src/`)
- **Test Command:** `pwsh -NoProfile -ExecutionPolicy Bypass -File .\tests\run-all.ps1` (builds app, builds harnesses, runs smoke test, ConfigHarness, ProcessHarness, validates installer manifest)
- **Deployment/CI-CD:** GitHub Actions (`.github/workflows/windows-build.yml`) runs on self-hosted Windows runner executing `tests/run-all.ps1`. Installer built via `installer/build-installer.bat` producing 5 profile-specific EXEs (Php82, Php83, Php84, Php85, Full). MkDocs builds to `site/` for GitHub Pages.

## 6. INTEGRATIONS & APIS
- **External APIs Consumed:** None at runtime (fully offline). Installer manifest references upstream URLs for component metadata only. Script catalog uses GitHub (git clone), Composer (packagist), WP-CLI, npm/yarn/pnpm for project bootstrapping.
- **Exposed Endpoints:**
  - `home/dashboard/status.php` - Read-only JSON status snapshot (ports, versions, service state, paths)
  - `home/dashboard/vhosts.php` - Virtual host listing
  - Apache serves `www/` and configured vhosts on `httpPort` (default 8080) and `httpsPort` (default 8443)
  - Adminer at `http://localhost:8080/adminer/` when `home/adminer/index.php` exists
- **Authentication Method:** 
  - MariaDB root password stored DPAPI-encrypted via `Core.UniWamp.Secrets` (Windows Data Protection API)
  - FTP/FTPS/SFTP sync credentials stored in Windows secret store (DPAPI), keyed by profile name
  - No web authentication in dashboard (local-only)

## 7. DOWNSTREAM AI AGENT INSTRUCTIONS
- **Follow Delphi VCL conventions:** Use `System.Generics.Collections`, `System.SysUtils`, `System.Classes`; avoid external dependencies. New units go in `src/Core/` (logic) or `src/Ui/` (forms).
- **Respect ownership boundaries:** Config→state/serialization, Paths→portable resolution, Runtime→orchestration, ServiceSupervisor→owned process resolution, ProcessManager→execution/termination, Secrets→DPAPI storage, PortUtils→availability/conflicts, TemplateRenderer→file generation. Do not cross boundaries.
- **Portability rules:** Resolve all paths from executable root (`TAppPaths.Detect`). Keep config root-relative. Generate absolute paths only in `config/generated/`. Never hardcode drive letters.
- **Secrets handling:** Never write passwords/keys to `uniwamp.json` or any portable file. Use `Core.UniWamp.Secrets.SaveSyncSecret/LoadSyncSecret` (DPAPI) for sync credentials and MariaDB root password.
- **Testing:** Add DUnitX tests under `src/tests/` following existing patterns (`Test.UniWamp.*.pas`). Run via `tests/run-all.ps1` which builds `ConfigHarness.exe` and `ProcessHarness.exe`.
- **Configuration changes:** Update `config/uniwamp.json` schema version (`configVersion`) and implement migration in `TUniWampConfig.LoadOrCreate` if structure changes.
- **Script catalog:** New entries in `scripts/catalog.json` must follow schema v1. Use `${php}`, `${tools}`, `${www}`, `${projectName}`, `${dbHost}`, `${dbPort}`, `${dbName}`, `${dbUser}`, `${dbPassword}`, `${adminPassword}` placeholders. Test via `Help → Scripts` in UI.

---
### Repository Directory Structure (Key Paths)
```
uniwamp/
├── src/
│   ├── UniWamp.dpr, UniWamp.dproj, build.bat, test.bat
│   ├── Core/ (30+ .pas units)
│   ├── Ui/ (14+ .pas forms + .dfm)
│   ├── tests/ (10+ test units, ConfigHarness.dpr, ProcessHarness.dpr)
│   ├── assets/ (icon resources)
│   └── tmpbuild/ (build output)
├── config/
│   ├── uniwamp.json
│   └── generated/ (httpd.conf, php.ini, mariadb.ini, etc.)
├── templates/ (6 .tpl files)
├── runtime/
│   ├── apache/, mariadb/, php/php82-85/, nodejs/
│   └── tools/ (composer, git, putty, winscp, lite-xl, mailpit, redis, wp-cli)
├── home/
│   ├── dashboard/ (status.php, vhosts.php, style.css)
│   └── adminer/
├── www/ (document root)
├── ssl/, logs/, tmp/
├── installer/ (6 .iss scripts, build-installer.bat, distribution-manifest.json)
├── scripts/ (catalog.json, README.md, bootstrap scripts)
├── tests/ (run-all.ps1, smoke.ps1, harness build scripts)
├── docs/ (MkDocs site: ARCHITECTURE.md, CONFIG_SCHEMA.md, SYNC_PROFILES.md, etc.)
├── mkdocs.yml
└── .github/workflows/windows-build.yml
```