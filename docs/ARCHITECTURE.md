# UniWamp Architecture

## Purpose

UniWamp is a portable Windows development stack manager. The Delphi VCL application owns configuration, runtime discovery, process lifecycle, generated configuration, virtual-host state, and desktop actions. Apache serves the local PHP dashboard and user projects.

## Current implementation baseline

| Area | Current implementation |
| --- | --- |
| Desktop application | Delphi 12.4 VCL application in `src/` |
| Entry point | `src/UniWamp.dpr`, creates `TMainForm` |
| UI | `Ui.UniWamp.MainForm` plus progress and settings dialogs |
| Configuration | JSON model in `Core.UniWamp.Config`, persisted at `config/uniwamp.json` |
| Portable paths | `Core.UniWamp.Paths`, rooted at the executable/application directory |
| Runtime orchestration | `Core.UniWamp.Runtime` |
| Diagnostics | `Core.UniWamp.Diagnostics` for log rotation, redaction, and copyable snapshots |
| Process execution | `Core.UniWamp.ProcessManager` |
| Port checks | `Core.UniWamp.PortUtils` and runtime-level diagnostics |
| Configuration generation | `Core.UniWamp.TemplateRenderer` and files in `templates/` |
| Web dashboard | PHP pages/assets in `home/dashboard/`, served by Apache |
| Adminer | `home/adminer/index.php` |
| Installer | Inno Setup scripts in `installer/` |
| Validation | `tests/smoke.ps1`; Delphi build script in `src/build.bat` |

## Runtime flow

1. `TAppPaths.Detect` resolves the UniWamp root and required folders.
2. Configuration is loaded or created with defaults.
3. Runtime discovery synchronizes available PHP and Node.js folders.
4. Templates generate Apache, SSL, PHP, MariaDB, vhost, and terminal environment files.
5. Port checks and executable checks run before service startup.
6. `TProcessManager` starts or stops Apache and MariaDB.
7. The UI refreshes service state, logs, port ownership, virtual hosts, and action availability.

## Ownership boundaries

- UI owns user interaction, layout, dialogs, status presentation, and action dispatch.
- `Config` owns typed application state, defaults, serialization, and future migrations.
- `Paths` owns root-relative folder resolution and portable layout creation.
- `Runtime` owns service-specific orchestration and generated configuration.
- `ProcessManager` owns process execution, output capture, exit status, and termination.
- `PortUtils` owns port availability and future port-owner inspection.
- `TemplateRenderer` owns rendering UniWamp templates into generated files.

The PHP dashboard is a local presentation layer. It should not become a second service-management implementation without a deliberate localhost API boundary.

## Portability rules

- Resolve paths from the executable/application root.
- Keep persistent configuration root-relative where practical.
- Generate absolute paths only in runtime-owned generated files.
- Quote executable paths and working directories.
- Never retain a developer drive letter in shipped defaults.
- Keep generated files separate from templates and user-owned runtime files.

## Target boundaries

The next architectural increment should introduce small interfaces around process execution, file operations, port inspection, and hosts-file updates. These seams enable tests without introducing a large dependency-injection framework or rewriting the VCL application.
