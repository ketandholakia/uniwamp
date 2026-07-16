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
| Service supervision | `Core.UniWamp.ServiceSupervisor` for owned-process resolution and stop behavior |
| Diagnostics | `Core.UniWamp.Diagnostics` for log rotation, redaction, and copyable snapshots |
| Process execution | `Core.UniWamp.ProcessManager` |
| Local secrets | `Core.UniWamp.Secrets` for protected machine-local MariaDB root password storage |
| Port checks | `Core.UniWamp.PortUtils` for availability and owner-aware conflict inspection |
| Configuration generation | `Core.UniWamp.TemplateRenderer` and files in `templates/` |
| Staged updater | Manifest validation, SHA-256 verification, workspace staging, promotion, rollback backup, and cleanup in `Core.UniWamp.Runtime` |
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
6. `TServiceProcessSupervisor` resolves owned Apache and MariaDB processes from stored state and PID files.
7. `TProcessManager` starts or stops Apache and MariaDB.
8. The UI refreshes service state, logs, port ownership, virtual hosts, and action availability from runtime-derived state.
9. Staged update packages are validated by manifest and hash, extracted safely into a workspace, promoted with backup support, and cleaned up after use.

## Ownership boundaries

- UI owns user interaction, layout, dialogs, status presentation, and action dispatch.
- `Config` owns typed application state, defaults, serialization, and future migrations.
- `Paths` owns root-relative folder resolution and portable layout creation.
- `Runtime` owns service-specific orchestration and generated configuration.
- `ServiceSupervisor` owns owned-process resolution and stop behavior for managed services.
- `ProcessManager` owns process execution, output capture, exit status, and termination.
- `Secrets` owns machine-local protected secret persistence that must not be written back into portable config.
- `PortUtils` owns port availability and owner-aware port conflict inspection.
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
