# UniWamp Development Plan

## Objective

Make UniWamp a reliable, portable Windows development stack manager while preserving the current Delphi VCL application, generated-runtime approach, installer profiles, and existing configuration where reasonable.

## Delivery principles

- Inspect and validate before changing behavior.
- Resolve P0 data-loss, command-execution, startup, shutdown, and configuration-corruption risks first.
- Keep each change focused and testable.
- Do not silently delete databases, projects, certificates, hosts entries, or configuration.
- Keep management interfaces bound to localhost.
- Prefer local ZIP import over automatic downloads for the first runtime-management release.

## Release checklist

Use this as the short day-to-day release path:

1. Build and verify with `pwsh -NoProfile -ExecutionPolicy Bypass -File .\tests\run-all.ps1`.
2. Confirm `config/uniwamp.json` is portable, valid, and free of developer-specific paths.
3. Review installer payload and generated files for fixed-path assumptions.
4. Test a portable move to a different folder or drive letter.
5. Record any missing runtimes, permission issues, or recovery actions in the release notes.

## Phase 0: Baseline and release safety

Deliverables:

- Architecture baseline and current-risk register.
- Reproducible Delphi build command without a user-specific path.
- Single-command repo verification flow for build, smoke, and config harness checks.
- Smoke test that reflects the supported installer profiles.
- Clean sample configuration with no developer machine paths.
- Build and packaging instructions verified on a clean Windows machine.

Exit criteria: the app builds with Delphi 12.4 using documented prerequisites, `tests/run-all.ps1` passes against a portable copy on a different drive or folder, and unavailable tools or runtimes are recorded.

## Phase 1: Configuration and portability hardening

- Add a configuration version and validate JSON types, ranges, required values, runtime selections, domains, and paths.
- Save through a temporary file and replace operation.
- Preserve a backup of the last valid configuration.
- Add migration handling for legacy absolute paths and root-relative paths.
- Reject paths outside the UniWamp root where the operation is expected to be portable.

Tests: invalid JSON, missing fields, unknown properties, migration, atomic write failure, spaces, Unicode, and moved-root scenarios.

Current next step:

- Add focused coverage for malformed, partially valid, and legacy `config/uniwamp.json` cases so recovery and migration behavior stay stable.
- Verify `LoadOrCreate` only marks the config as migrated when data actually changes.
- Add a small portable config test harness before moving on to process and service lifecycle work.
- Keep the repository-level verification script as the canonical local check for app and config changes.

Completed:

- Added focused config harness coverage for malformed, partially valid, and already-current `config/uniwamp.json` cases.
- Verified `LoadOrCreate` only reports migration when data actually changes.
- Kept the repository-level verification script green after the config coverage update.

## Phase 2: Process and service lifecycle reliability

- Centralize structured process execution with executable, working directory, arguments, timeout, exit code, output, and child-process handling.
- Verify services using executable path, command line, PID ownership, port ownership, and health checks.
- Make start/stop/restart transitions explicit and idempotent.
- Use graceful shutdown before force termination.
- Prevent duplicate start requests and expose actionable startup errors.
- Validate Apache configuration with `httpd.exe -t` before starting or restarting.

Tests: stale PID, PID reuse, duplicate start, timeout, failed executable, graceful stop, forced stop, and restart races with mocked processes.

Completed:

- Added process harness coverage for Apache start blocking when configuration validation fails.
- Verified the start path reports the real validation failure output and does not leave Apache state marked as running.
- Added process harness coverage for idempotent stop behavior when Apache and MariaDB are already stopped.
- Verified stop paths still clear service state and report success in the no-op case.
- Added process harness coverage for duplicate-start short-circuit behavior when Apache is already running.
- Verified the Apache start path returns an already-running result instead of launching a second service instance.

## Phase 3: Runtime-specific correctness

- Handle MariaDB first-run initialization, startup timeout, safe shutdown, and damaged-data-directory reporting.
- Validate PHP runtime compatibility, CLI version, Apache module compatibility, and rollback on failed selection.
- Validate HTTP, HTTPS, and MariaDB ports and report conflicting processes where available.
- Persist startup dependency failures and restart-phase failures in the runtime error state so the UI and logs stay aligned.
- Keep generated configuration separate from vendor files.

## Phase 4: Virtual hosts, hosts file, and HTTPS

- Validate domains and document roots.
- Generate vhost configuration atomically.
- Manage only a marked UniWamp hosts-file block and preserve unrelated entries.
- Back up the hosts file before changes and report administrator permission errors without losing vhost state.
- Separate certificate generation from trust installation.

## Phase 5: Diagnostics, logging, and recovery

- Add structured activity records with timestamp, component, operation, service, PID, exit code, duration, category, and message.
- Add log rotation, redaction, and a copyable diagnostic report.
- Show versions, paths, services, ports, health checks, permissions, and recent errors in the UI and copied diagnostics.
- Add configuration, vhost, certificate, and database backup/restore workflows with confirmation.

## Phase 6: Dashboard and workflow quality

- Add consistent status language, loading/disabled/error/empty states, and clear destructive-action labels.
- Improve responsive layout, keyboard navigation, focus states, labels, contrast, and theme persistence.
- Keep action shortcuts, tool-panel hints, and empty states aligned with the implemented UI.
- Add project search, filtering, open-folder/open-terminal actions, and project type detection.

## Phase 7: Optional integrations and update model

Prioritize modular integrations for Composer, WP-CLI, Git, Node package managers, editor, Windows Terminal, Mailpit, Redis, and Memcached. Add local ZIP runtime import and integrity checks before considering remote downloads. A safe updater requires a separate staged updater process and rollback path.

## Priority model

| Priority | Meaning | Examples |
| --- | --- | --- |
| P0 | Critical | Data loss, command injection, corrupted config, cannot start/stop |
| P1 | High | Incorrect state, broken portability, port conflicts, broken vhosts |
| P2 | Medium | Weak validation, diagnostics, accessibility, missing workflows |
| P3 | Low | Cosmetic consistency and optional integrations |

## Definition of done

Code, generated files, and user-owned files have clear ownership; focused tests cover critical behavior; manual verification covers startup, shutdown, conflicts, permissions, moving the installation, and recovery; documentation states prerequisites, commands, limitations, and known failures; and the final diff is checked for fixed-path assumptions and unrelated changes.
