# UniWamp Config Schema

`config/uniwamp.json` stores the portable application state that UniWamp loads at startup and writes back through the desktop app.

## Top-level structure

The file is a single JSON object with these major groups:

- Core runtime settings
- Apache, PHP, MariaDB, and Node selections
- Virtual hosts
- Connection profiles
- Sync profiles
- UI and workflow preferences

## Core settings

Common fields include:

- `httpPort`
- `httpsPort`
- `databasePort`
- `hostName`
- `documentRoot`
- `selectedPhpVersion`
- `selectedNodeVersion`
- `terminalExePath`
- `phpProfile`
- `themeStyleName`
- `enableSsl`
- `startAllOnLaunch`
- `openDashboardAfterStart`
- `confirmVHostDelete`
- `apachePid`
- `mariaDbPid`
- `apacheRunning`
- `mariaDbRunning`
- `lastApacheError`
- `lastMariaDbError`
- `lastHostsSyncStatus`
- `lastMigrationMessage`
- `lastSyncUploadProfile`
- `lastSyncDownloadProfile`

## Virtual hosts

`vhosts` is an array of objects with fields such as:

- `serverName`
- `serverAliases`
- `documentRoot`
- `enableSsl`
- `sslCertFile`
- `sslKeyFile`
- `pinnedSyncUploadProfile`
- `pinnedSyncDownloadProfile`

Virtual-host document roots and certificate paths are normalized to portable application-relative paths where possible.

## Connection profiles

`connectionProfiles` is an array of remote-connection definitions.

Each item includes:

- `name`
- `protocol`
- `host`
- `port`
- `username`
- `privateKeyFile`
- `passiveMode`
- `ignoreCertErrors`

Passwords and key passphrases are not stored in this JSON file. They live in the Windows secret store under connection-profile keys.

## Sync profiles

`syncProfiles` is an array of transfer jobs.

Each item includes:

- `name`
- `connectionProfileName`
- `protocol`
- `direction`
- `host`
- `port`
- `username`
- `privateKeyFile`
- `passiveMode`
- `ignoreCertErrors`
- `defaultTestVHost`
- `preSyncCommand`
- `postSyncCommand`
- `remotePath`
- `localPath`
- `workingDirectory`
- `deleteEnabled`
- `dryRunByDefault`
- `excludes`

Sync profiles may point at a named connection profile or carry inline connection fields for compatibility with older layouts.

## Migration behavior

UniWamp normalizes and migrates older config layouts on load.

Examples:

- Relative paths are expanded against the application root.
- Older sync-profile connection fields are migrated into the dedicated connection-profile list.
- Legacy password fields are moved into the protected secret store.
- Invalid or missing ports are reset to safe defaults.

## Related docs

- [`docs/SYNC_PROFILES.md`](SYNC_PROFILES.md)
- [`docs/ARCHITECTURE.md`](ARCHITECTURE.md)
- [`docs/SECURITY_AND_OPERATIONS.md`](SECURITY_AND_OPERATIONS.md)
