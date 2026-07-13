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
- Prefer structured process APIs with explicit executable paths and argument lists.
- Do not concatenate untrusted values into `cmd.exe`, PowerShell, or shell scripts.
- Quote paths containing spaces and use an explicit working directory.
- Keep file operations inside the intended UniWamp root unless explicitly targeting the hosts file or certificate store.
- Redact passwords, tokens, and credentials from logs and diagnostics.
- Do not display stack traces or raw command lines containing secrets to normal users.

## Destructive operations

Require explicit confirmation for database reset, vhost deletion, runtime removal, configuration reset, certificate replacement, and restore. Create backups before replacement, and leave the previous valid state available after failure.

## Hosts file

Only the following managed block may be changed:

```text
# BEGIN UNIWAMP
127.0.0.1 example.test
::1 example.test
# END UNIWAMP
```

Write through a temporary file, preserve unrelated content, back up the previous file, and report administrator permission failures without overwriting application state.

## Runtime operations

- Validate Apache configuration before start/restart.
- Verify process identity using more than a saved PID.
- Prefer graceful shutdown and make force termination a visible fallback.
- Never automatically delete or recreate an existing MariaDB data directory.
- Treat generated files as disposable outputs and vendor runtime files as user-owned inputs.

## Release checklist

- Build from a clean checkout using documented prerequisites.
- Run `pwsh -NoProfile -ExecutionPolicy Bypass -File .\tests\run-all.ps1` before packaging.
- Inspect installer payload for accidental developer paths.
- Test installation and first launch as a standard user.
- Test a portable move to a path containing spaces.
- Verify localhost-only management behavior.
- Verify logs and diagnostic bundles contain no secrets.
- Record known runtime and permission limitations in release notes.
