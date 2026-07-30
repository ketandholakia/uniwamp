# Usage

UniWamp is designed to manage a local Apache, MariaDB, and PHP stack from one
desktop window.

## Start and stop the stack

- Use the main dashboard to start Apache and MariaDB in order.
- Use the same screen to stop or restart each service.
- The app keeps service state, port ownership, and generated configuration in
  sync with the current runtime.

## Manage configuration

Common settings live in `config\uniwamp.json` and are edited from the app:

- Host name
- Document root
- HTTP, HTTPS, and MariaDB ports
- Selected PHP version
- Selected Node.js version
- SSL toggle
- Start-on-launch behavior
- Dashboard auto-open behavior

After changing settings, save the configuration so UniWamp can regenerate the
runtime files under `config\generated\`.

## Virtual hosts

- Create, edit, and delete vHosts from the dashboard.
- Each vHost can own its own document root and SSL settings.
- The app updates the generated Apache vHost file and the managed hosts block
  for you.

## Visual reference

See the [Screenshots](screenshots.md) page for the current dashboard, connection
profile, and sync profile forms.

## Connection and sync profiles

Use the dedicated connection profile and sync profile forms to manage remote
deployments.

- Connection profiles store the remote host, transport, username, and
  credential details.
- Sync profiles store the source and destination paths, direction, filters,
  and hooks.
- Sync profiles can reuse a named connection profile when multiple jobs target
  the same remote host.
- Secrets are stored outside `config\uniwamp.json` in DPAPI-protected,
  machine-local storage under the current UniWamp installation. They are not
  exported with the portable app folder; if you move the install or copy it to
  another machine, re-enter the MariaDB root password and connection/sync
  credentials.

See [`Connection and Sync Profiles`](SYNC_PROFILES.md) for the data model.

## Backups and restore

UniWamp can back up and restore:

- Projects
- MariaDB data
- Configuration state

The restore flows are designed to be transactional so a failed restore does not
leave a half-applied project behind.

## Verification

Use the repository verification flow whenever you change behavior:

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File .\tests\run-all.ps1
```

That runs the app build, config harness, process harness, and smoke test.
