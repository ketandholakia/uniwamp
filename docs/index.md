# UniWamp Documentation

UniWamp is a portable Windows WAMP dashboard built in Delphi. This site covers
the application layout, installation steps, usage flow, sync profile model, and
security notes.

## Start here

- [Installation](installation.md)
- [Usage](usage.md)
- [Beta Support Matrix](testing/BETA_SUPPORT_MATRIX.md)
- [Screenshots](screenshots.md)
- [Architecture](ARCHITECTURE.md)
- [Connection and Sync Profiles](SYNC_PROFILES.md)
- [Security and Operations](SECURITY_AND_OPERATIONS.md)
- [Release Process](RELEASE_PROCESS.md)

## What this site covers

- The desktop app and its generated runtime files
- Apache, MariaDB, PHP, and local vHost management
- Connection profiles and sync profiles for FTP, FTPS, and SFTP
- Backup, restore, and update workflows
- Supported beta environments and upgrade expectations
- Verification and release planning
- Visual reference screenshots for the main forms

## Quick commands

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File .\tests\run-all.ps1
```

```powershell
mkdocs serve
```

```powershell
mkdocs build
```
