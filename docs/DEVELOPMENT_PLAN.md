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

- Keep the staged updater documentation aligned with the implemented manifest, staging, promotion, rollback, and cleanup flow.
- Add future remote-download handling only after the local ZIP import path remains stable and well-tested.
- Continue using the repository-level verification script as the canonical local check for app, runtime, and doc changes.

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
- Added process harness coverage for duplicate-start short-circuit behavior when MariaDB is already running.
- Verified the MariaDB start path returns an already-running result instead of launching a second service instance.
- Added process harness coverage for force-stopping a live process through `StopProcess`.
- Verified the process manager terminates a running helper process and clears the running state afterward.
- Added process harness coverage for MariaDB port-conflict reporting before startup.
- Verified the MariaDB start path reports the occupied port and leaves runtime state cleared.

## Phase 3: Runtime-specific correctness

- Handle MariaDB first-run initialization, startup timeout, safe shutdown, and damaged-data-directory reporting.
- Validate PHP runtime compatibility, CLI version, Apache module compatibility, and rollback on failed selection.
- Validate HTTP, HTTPS, and MariaDB ports and report conflicting processes where available.
- Persist startup dependency failures and restart-phase failures in the runtime error state so the UI and logs stay aligned.
- Keep generated configuration separate from vendor files.

Completed:

- Added process harness coverage for Apache start syncing to the detected PHP runtime when the selected version is missing.
- Verified the runtime updates `SelectedPhpVersion` to the installed PHP directory before continuing Apache startup validation.
- Added process harness coverage for MariaDB first-run initialization backing up a dirty data directory.
- Verified the initialization path preserves the stale data in a timestamped backup before retrying startup.

## Phase 4: Virtual hosts, hosts file, and HTTPS

- Validate domains and document roots.
- Generate vhost configuration atomically.
- Manage only a marked UniWamp hosts-file block and preserve unrelated entries.
- Back up the hosts file before changes and report administrator permission errors without losing vhost state.
- Separate certificate generation from trust installation.

Completed:

- Added process harness coverage for vHost creation generating Apache config and starter content.
- Normalized vHost aliases so comma-separated input is stored and rendered as a single canonical space-separated list.
- Added process harness coverage for hosts-file sync failure reporting when the override path is invalid.
- Verified vHost creation keeps the saved project state even when hosts sync cannot complete.
- Added process harness coverage for SSL certificate generation failure when OpenSSL is unavailable.
- Verified the certificate workflow reports the missing executable and remains separate from hosts trust handling.

## Phase 5: Diagnostics, logging, and recovery

- Add structured activity records with timestamp, component, operation, service, PID, exit code, duration, category, and message.
- Add log rotation, redaction, and a copyable diagnostic report.
- Show versions, paths, services, ports, health checks, permissions, and recent errors in the UI and copied diagnostics.
- Add configuration, vhost, certificate, and database backup/restore workflows with confirmation.

Completed:

- Added process harness coverage for log redaction preserving non-secret text around common separators.
- Verified redaction still masks sensitive keys while leaving ordinary key/value text intact.
- Added process harness coverage for diagnostic report redaction of the MariaDB root password field.
- Verified the copied diagnostic snapshot does not expose the configured MariaDB root password.
- Added process harness coverage for MariaDB root password changes requiring a running service.
- Verified the password workflow fails fast when MariaDB is stopped.
- Added process harness coverage for diagnostic report port-owner reporting on occupied ports.
- Verified the copied diagnostic snapshot includes a non-empty owner line when a port is bound.
- Added process harness coverage for activity-log clipboard selection fallback logic.
- Verified the copy workflow prefers the log file content, then the live memo, then empty output.

## Phase 6: Dashboard and workflow quality

- Add consistent status language, loading/disabled/error/empty states, and clear destructive-action labels.
- Improve responsive layout, keyboard navigation, focus states, labels, contrast, and theme persistence.
- Keep action shortcuts, tool-panel hints, and empty states aligned with the implemented UI.
- Add project search, filtering, open-folder/open-terminal actions, and project type detection.

Completed:

- Added process harness coverage for the vHost empty-state caption helper.
- Verified the empty state switches between the default and filtered messages.
- Added process harness coverage for project type detection across common framework markers.
- Verified the detector prioritizes WordPress, then Laravel, then Node, then PHP, then static roots.
- Added process harness coverage for consistent service-state labels in diagnostic reports.
- Verified the diagnostic report uses the shared running/stopped labels for Apache and MariaDB.

## Phase 7: Optional integrations and update model

Prioritize modular integrations for Composer, WP-CLI, Git, Node package managers, editor, Windows Terminal, Mailpit, Redis, and Memcached. Add local ZIP runtime import and integrity checks before considering remote downloads. A safe updater requires a separate staged updater process and rollback path.

Completed:

- Generated terminal environment scripts without a UTF-8 BOM so `cmd.exe` and Cmder can consume them reliably.
- Added process harness coverage that verifies `env.bat` begins with plain ASCII `@echo off`.
- Added process harness coverage that verifies relative terminal executable paths resolve against the app root.
- Added process harness coverage for multiline tool-panel hints on dashboard, Adminer, PHP, and terminal actions.
- Added process harness coverage for vHost action hints on add, delete, open, folder, and copy actions.
- Added process harness coverage for log action hints on open and clear operations.
- Added process harness coverage for primary action hints on save configuration and SSL generation.
- Added process harness coverage for config editor hints on php.ini, httpd.conf, and mariadb.ini actions.
- Added process harness coverage for copy action hints on diagnostic report and activity log actions.
- Added process harness coverage for the MariaDB status-bar hint wording.
- Reworked the tool-panel layout so sidebar actions are stacked and grouped by purpose.
- Refined the sidebar styling with centered labels, icon-free action buttons, and distinct section colors.
- Tightened sidebar spacing so more actions fit in the right rail with less vertical waste.
- Moved log actions into the right sidebar and expanded the activity area to use the freed bottom space.
- Extended the sidebar to the full available height and shrank the activity strip to emphasize live output.
- Reparented the tool rail into a dedicated right column so the app reads as left controls, center workspace, and sidebar.
- Removed stacked icon text overlays from the sidebar buttons so captions render as a single centered line.
- Rebalanced the three-column layout by narrowing the sidebar dock so the center workspace has more room.
- Tightened sidebar group spacing and label sizing so the third column reads cleanly in the narrower rail.
- Converted the top sidebar tool cluster into a compact two-column grid to avoid label crowding.
- Reverted the top sidebar tool cluster to a single-column stack so long captions no longer collide.
- Added process harness coverage for the vHost filter clear hint wording.
- Added process harness coverage for the vHost filter search hint wording.
- Added process harness coverage for the always-on status-bar hint wording.
- Added process harness coverage for the header subtitle hint wording.
- Added process harness coverage for the header status-card hint wording.
- Added process harness coverage for the header title hint wording.
- Added process harness coverage for the header overview hint wording.
- Added process harness coverage for the header overview region hint wording.
- Added process harness coverage for preferred text-editor selection via `EDITOR`.
- Added process harness coverage for the text-editor fallback defaulting to Notepad.
- Added process harness coverage for terminal executable fallback ordering across Cmder, Windows Terminal, and cmd.exe.
- Added a repo-root terminal shortcut in the tool panel for Git and maintenance workflows.
- Added a SHA-256 file digest helper to support future runtime archive integrity checks.
- Added ZIP archive validation coverage for the future local runtime import flow.
- Added local ZIP runtime import coverage that extracts portable payloads into the app root.
- Added a portable update staging workspace under `tmp\updates` for future staged updater work.
- Added process harness coverage for update staging workspace creation inside the portable root.
- Added rollback snapshot and restore helpers for staged update workspaces.
- Added a Composer launcher in the tool panel for repository-root maintenance workflows.
- Added a Git launcher in the tool panel for repository-root maintenance workflows.
- Added a Node launcher in the tool panel for repository-root maintenance workflows.
- Added a WP-CLI launcher in the tool panel for WordPress repository workflows.
- Added a Mailpit launcher in the tool panel for local mail-preview workflows.
- Added a Redis launcher in the tool panel for local cache/service workflows.
- Added a Memcached launcher in the tool panel for local cache/service workflows.
- Added a SHA-256 package validation helper for staged update integrity checks.
- Added an update manifest validator for staged update package metadata.
- Added staged update metadata output for package, hash, version, and workspace tracking.
- Added an npm launcher in the tool panel for Node.js repository workflows.
- Added a yarn launcher in the tool panel for Node.js repository workflows.
- Added a pnpm launcher in the tool panel for Node.js repository workflows.
- Added a generic editor launcher in the tool panel for repository maintenance workflows.
- Added update workspace cleanup support for staged updater maintenance.
- Added end-to-end staged update orchestration that validates, hashes, extracts, and records package metadata.
- Added staged update promotion support for copying verified workspaces into a target install directory.
- Added staged update promotion backups so prior targets can be restored after replacement failures.
- Updated the README and operational docs to describe the staged update flow and tool-panel launchers.
- Added a Stage Update tool-panel action for manifest-driven local update staging.

## Priority model

| Priority | Meaning | Examples |
| --- | --- | --- |
| P0 | Critical | Data loss, command injection, corrupted config, cannot start/stop |
| P1 | High | Incorrect state, broken portability, port conflicts, broken vhosts |
| P2 | Medium | Weak validation, diagnostics, accessibility, missing workflows |
| P3 | Low | Cosmetic consistency and optional integrations |

## Definition of done

Code, generated files, and user-owned files have clear ownership; focused tests cover critical behavior; manual verification covers startup, shutdown, conflicts, permissions, moving the installation, and recovery; documentation states prerequisites, commands, limitations, and known failures; and the final diff is checked for fixed-path assumptions and unrelated changes.
