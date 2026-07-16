# Security and Operations Checklist

## Trust boundaries

- UniWamp manages local executables and user-selected folders.
- Apache serves both the management dashboard and project content.
- The hosts file and certificate trust store are operating-system resources.
- MariaDB data is user data and must be protected from destructive operations.

## Required controls

- Bind any management API to localhost by default.
- Validate service identifiers against an allowlist.
- Validate ports as integers in the valid TCP range and reject duplicates.
- Validate domains, document roots, runtime names, and executable paths before use.
- Reject project names, vHost names, aliases, and update package names that contain shell or config metacharacters.
- Prefer structured process APIs with explicit executable paths and argument lists.
- Do not concatenate untrusted values into `cmd.exe`, PowerShell, or shell scripts.
- Quote paths containing spaces and use an explicit working directory.
- Keep file operations inside the intended UniWamp root unless explicitly targeting the hosts file or certificate store.
- Redact passwords, tokens, and credentials from logs and diagnostics.
- Do not display stack traces or raw command lines containing secrets to normal users.

## Destructive operations

Require explicit confirmation for database reset, vhost deletion, runtime removal, configuration reset, certificate replacement, and restore. Create backups before replacement, and leave the previous valid state available after failure.

For staged updates, validate the manifest and package hash before extraction, reject manifest package names that are not plain file names, promote only a verified workspace, and keep the previous target tree available in a backup directory until the replacement is confirmed.
Manifest authenticity is out of scope unless a trusted distribution channel signs or otherwise authenticates the manifest before UniWamp reads it.
Runtime ZIP extraction must reject traversal entries and extract only through the safe extractor.

## Hosts file

Only the following managed block may be changed:

```text
# BEGIN UniWamp Managed Hosts
127.0.0.1 example.test
::1 example.test
# END UniWamp Managed Hosts
```

Write through a temporary file, preserve unrelated content, back up the previous file, and report administrator permission failures without overwriting application state.
Hosts and Apache vHost content must be validated before they are written; do not rely on quote escaping alone.

## Runtime operations

- Validate Apache configuration before start/restart.
- Verify process identity using more than a saved PID.
- Prefer graceful shutdown and make force termination a visible fallback.
- Never automatically delete or recreate an existing MariaDB data directory.
- Treat generated files as disposable outputs and vendor runtime files as user-owned inputs.
- External developer-tool launchers should remain PATH-based, local-only, and explicit about missing executables rather than attempting downloads.
- Do not auto-download and execute `mkcert` or other tooling during certificate generation without a separate authenticated distribution path.
- Keep MariaDB root passwords out of portable config and store them only in protected machine-local storage.

## Release checklist

- Build from a clean checkout using documented prerequisites.
- Run `pwsh -NoProfile -ExecutionPolicy Bypass -File .\tests\run-all.ps1` before packaging.
- Inspect installer payload for accidental developer paths.
- Test installation and first launch as a standard user.
- Test a portable move to a path containing spaces.
- Verify localhost-only management behavior.
- Verify logs and diagnostic bundles contain no secrets.
- Verify `Copy Report` and `Copy Activity` only expose local, redacted diagnostics.
- Record known runtime and permission limitations in release notes.
