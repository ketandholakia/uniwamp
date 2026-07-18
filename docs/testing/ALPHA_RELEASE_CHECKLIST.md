# UniWamp Alpha Release Checklist

Target tag: `v0.1.0-alpha`

Current status: NOT READY

This checklist defines the minimum bar for an alpha release. It is intentionally smaller than a stable-release checklist, but every blocker below should be closed before tagging.

## Legend

- `[x]` Done
- `[ ]` Not done
- `[?]` Unknown or needs recheck

## Release Gate

- `[x]` Clean Delphi build produces `UniWamp.exe`.
- `[x]` Build blocker from `UNIWAMP_RELEASE_READINESS.md` is resolved: `F2039 Could not create output file 'UniWamp.exe'`.
- `[ ]` Worktree is clean except for intentional release files.
- `[ ]` Version/tag name is chosen and documented as `v0.1.0-alpha`.
- `[ ]` Release notes list alpha scope, known limitations, and required runtimes.

## Packaging

- `[ ]` Portable folder or installer launches outside the development workspace.
- `[ ]` Package contains the expected `config`, `templates`, `home`, `runtime`, `www`, `logs`, `tmp`, and `ssl` folders.
- `[ ]` Required third-party runtime binaries are either bundled or clearly documented as prerequisites.
- `[ ]` First launch on a clean Windows machine creates or validates generated config files.
- `[ ]` App starts without requiring machine-specific paths from the developer workspace.

## Core Runtime Flows

- `[ ]` Apache starts, stops, and restarts from the main UI.
- `[ ]` MariaDB starts, stops, and restarts from the main UI.
- `[ ]` PHP runtime selection updates generated Apache/PHP config correctly.
- `[ ]` Port conflict handling is verified for HTTP, HTTPS, and MariaDB ports.
- `[ ]` Activity log records service start and stop outcomes clearly.
- `[?]` Apache start logging rechecked after the explicit status append fix.

## Virtual Hosts and SSL

- `[ ]` Create a vHost from the UI.
- `[ ]` Delete a vHost from the UI.
- `[ ]` Generated `httpd-vhosts.conf` matches the vHost list.
- `[ ]` Hosts-file staging or update is scoped to UniWamp-owned entries.
- `[ ]` Self-signed SSL generation works for one local host.
- `[?]` Manual vHost creation rechecked after the dialog focus fix.

## Script Manager

- `[ ]` Script manager opens without DFM class-registration errors.
- `[ ]` Catalog grid, search, category filter, and quick filters are usable at default size.
- `[ ]` Splitter resizing keeps both catalog and output panels usable.
- `[ ]` Terminal-style installation output is readable during long-running installs.
- `[ ]` Install flow works for one Composer-based script.
- `[ ]` Install flow works for one Git clone script.
- `[ ]` Install flow works for one script that creates a database and user.
- `[ ]` Failed install reports the command output clearly.
- `[ ]` Failed install does not corrupt app config or vHost config.

## Data Safety

- `[ ]` Config save/load survives app restart.
- `[ ]` Invalid config values are rejected or repaired predictably.
- `[ ]` Project creation rollback is tested after a failed script step.
- `[ ]` Database creation failure does not leave misleading success state.
- `[ ]` ZIP extraction rejects path traversal entries.
- `[ ]` Passwords and secrets are redacted from copied diagnostics where applicable.

## Portability

- `[ ]` App works when moved to a different folder.
- `[ ]` App works from a path containing spaces.
- `[ ]` App works from a Unicode path.
- `[ ]` Relative runtime paths resolve correctly from the UniWamp root.
- `[ ]` Tool launchers do not depend on the developer machine PATH unless documented.

## Automated and Manual Tests

- `[x]` Config/process harnesses were reported passing in the current testing docs.
- `[x]` Smoke check was reported passing against `home/dashboard/`.
- `[ ]` Repo-level verification flow can run on the release machine.
- `[ ]` Required manual runtime scenarios are executed.
- `[ ]` Clean-machine manual acceptance checklist is executed.
- `[ ]` Repeat start/stop stability run is executed.
- `[ ]` Basic memory/leak or long-run stability pass is executed.

## Documentation

- `[x]` README explains the project purpose and repository layout.
- `[ ]` README clearly labels the project as alpha.
- `[ ]` README lists known alpha limitations.
- `[ ]` README includes exact build instructions used for the release.
- `[ ]` README includes exact packaging or installer instructions.
- `[ ]` Release notes include tested Windows and Delphi versions.
- `[ ]` Release notes include runtime versions used for validation.

## Current Blockers

- Clean Delphi build is not proven.
- Clean-machine package validation is not done.
- Most interactive runtime, vHost, SSL, script-install, and portability checks are not done.
- Release docs still say `NOT READY`.
- Current worktree contains local/generated changes that should be reviewed before tagging.

## Alpha-Ready Definition

UniWamp can be tagged `v0.1.0-alpha` when:

- The build is reproducible on the release machine.
- The app launches from a packaged folder on a clean Windows machine.
- Apache, MariaDB, PHP switching, vHost creation, and at least three script installs have been verified.
- Data-loss and config-corruption risks have been exercised for the main workflows.
- Documentation clearly sets alpha expectations and lists known limitations.
