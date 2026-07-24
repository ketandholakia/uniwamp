# UniWamp Repository Review

Review date: 2026-07-24

Reviewed commit: `a626114` (`Refactor sync profiles and connection manager`)

## Executive Summary

UniWamp has a credible foundation for a portable Windows development stack:
typed configuration, generated runtime files, PID ownership checks, safe ZIP
extraction, DPAPI-protected secrets, backup workflows, and dedicated VCL
management forms.

The repository is still alpha-quality and should not be released broadly yet.
The main blockers are:

1. SFTP is presented as supported but is only a runtime-error stub.
2. Connection-profile credentials are loaded using the wrong profile name.
3. A malicious or malformed remote filename can escape the local sync directory.
4. Background threads can access the main form, runtime, and config after destruction.
5. The localhost PHP dashboard allows state-changing requests without CSRF protection.
6. The current test suite compiles but does not pass.
7. There is no repository license, despite positioning the project as open source.

Overall assessment: promising architecture, but the newest sync implementation
and asynchronous UI lifecycle need another hardening pass before the alpha
release.

## Confirmed Findings

### Critical: SFTP Is Not Implemented

`src/Core/Core.UniWamp.SftpTransport.pas` explicitly says the implementation is
a stub. Every meaningful operation calls `RaiseUnavailable`.

Meanwhile, both connection and sync profile forms offer SFTP as a normal
selectable protocol:

- `src/Ui/Ui.UniWamp.ConnectionProfilesForm.pas`
- `src/Ui/Ui.UniWamp.SyncProfilesForm.pas`

Impact:

- Users can create and save apparently valid SFTP profiles.
- Connection tests fail only at runtime.
- Documentation and UI imply a capability the executable does not provide.

Recommendation:

- Implement the native SFTP transport before release.
- Until then, hide or disable SFTP and display "not available in this build."
- Add an explicit transport-capability query instead of hardcoding protocol
  names in forms.

### Critical: Connection Credentials Use the Wrong Secret Key

The connection profile form stores secrets under the connection profile name,
but `TSyncService.BuildCredentials` loads them using the sync profile name:

```pascal
Result.Password := LoadSecret(FPaths, SyncPasswordKey(Profile.Name));
Result.KeyPassphrase := LoadSecret(FPaths, SyncKeyPassphraseKey(Profile.Name));
```

If a sync profile named `Deploy Production` uses a connection profile named
`Production Server`, the service looks for credentials belonging to
`Deploy Production`, not `Production Server`.

Impact:

- Most connection-profile-backed sync operations authenticate with an empty or
  unrelated password.
- Profiles only appear to work when both names happen to match.
- Renaming either profile can silently break authentication.

Recommendation:

- Resolve the effective connection profile first.
- Load secrets using `ConnectionProfile.Name`.
- Separate key helpers into `ConnectionPasswordKey` and legacy
  `SyncPasswordKey`.
- Add migration logic for existing saved secrets.

Related issue: connection testing reads the previously stored secret rather
than the password currently typed into the editor. A user editing a password
may therefore test stale credentials.

### Critical: Remote Sync Names Can Escape the Local Root

`RemoteFileTree` accepts every remote entry name except exactly `.`, `..`, or
empty. The resulting remote-controlled relative path is combined directly with
the local path.

A hostile or malformed FTP server could return names containing separators or
traversal components such as `..\..\target.ini`. Download and delete plans
could then operate outside the selected local directory.

This affects:

- Downloads
- Local deletion with mirroring enabled
- Recursive remote traversal
- Remote-path construction for upload and deletion

Recommendation:

- Apply the same normalized relative-path validation used by safe ZIP extraction.
- Reject rooted paths, colons, empty components, `.` and `..`.
- Resolve the final local path with `ExpandFileName`.
- Verify it remains under the canonical local sync root before every write or
  delete.
- Reject remote names containing `/` or `\` when returned as a single directory
  entry.

### High: Background Threads Can Outlive `TMainForm`

The main form creates many anonymous threads and queues callbacks with
`TThread.Queue(nil, ...)`.

The destructor immediately frees `FRuntime`, `FConfig`, and UI-owned resources.
There is no cancellation token, operation counter, thread join, closing flag,
or queued-event removal. Because queued callbacks are associated with `nil`,
they cannot reliably be removed by form identity.

Impact:

- Closing UniWamp during start, stop, backup, restore, vhost, or password
  operations can cause access violations.
- Worker threads access shared `FConfig` and `FRuntime` without synchronization.
- The four-second status timer may read state while workers modify it.

This is a plausible source of future access violations similar to the startup
errors already encountered.

Recommendation:

- Introduce a form-owned background-operation coordinator.
- Associate queued events with the form or a dedicated thread object.
- Set `FClosing := True` before shutdown.
- Disable new operations during closure.
- Wait for active workers before freeing runtime/config.
- Keep mutable runtime state behind a lock or confine state updates to the main
  thread.

### High: Local Dashboard Has No CSRF Protection

The Apache templates correctly bind to loopback and restrict dashboard access.
However, the PHP dashboard executes state-changing POST actions without any
nonce, session token, `Origin` validation, or `Sec-Fetch-Site` check.

Actions include:

- Starting and stopping the stack
- Restarting Apache or MariaDB
- Rewriting `uniwamp.json`
- Regenerating configuration
- Enabling PHP extensions or Apache modules

A malicious website opened in the user's browser can submit a form to
`http://127.0.0.1:8080/dashboard/services.php`. Same-origin policy prevents
reading the response, but it does not prevent a cross-origin form POST.

The PHP stop implementation also falls back to killing every matching
executable:

```text
taskkill /IM httpd.exe /T /F
```

This bypasses the safer executable-identity checks in the Delphi service
supervisor.

Recommendation:

- Best option: make the PHP dashboard read-only and leave management in the VCL
  application.
- Otherwise, generate a random dashboard token at application start and require
  it for every mutation.
- Validate `Origin` and reject cross-site requests.
- Never use image-name process termination.
- Route mutations through one localhost IPC/API owned by the Delphi runtime.

### High: Configuration Has Two Competing Control Planes

The architecture document says the PHP dashboard should not become a second
service-management implementation. It currently is one.

The PHP code independently implements:

- Config loading and saving
- Apache/PHP/MariaDB config generation
- Runtime discovery
- Process start/stop
- State refresh

This duplicates behavior already present in:

- `Core.UniWamp.Config`
- `Core.UniWamp.ConfigGenerator`
- `Core.UniWamp.Runtime`
- `Core.UniWamp.ServiceSupervisor`

The two implementations already differ in validation, process ownership, error
handling, and persistence strategy.

Recommendation:

- Designate Delphi as the only writer and process controller.
- Make the PHP dashboard consume a generated read-only status JSON file.
- If browser control is required later, expose a minimal authenticated loopback
  API from the Delphi process.

### Medium: Persistence Is Not Fully Atomic

Configuration save writes a temporary file, but replaces the live file by
deleting it and then moving the temporary file. A crash between deletion and
move leaves no primary config, although the backup may survive.

The hosts service copies a backup but then writes directly to the hosts file.
This contradicts the documented requirement to write through a temporary file.
A failed write can truncate or partially rewrite the hosts file.

The PHP dashboard is weaker again, using direct `file_put_contents`.

Recommendation:

- Centralize an `AtomicReplaceFile` helper.
- Write and flush a sibling temporary file.
- Use `ReplaceFileW` or `MoveFileEx` with replace/write-through semantics.
- Restore the backup automatically if replacement fails.
- Serialize config writes across UI, workers, and dashboard.

### Medium: VHost Certificate Deletion Is Not Contained

Vhost deletion trusts certificate paths from configuration and deletes them
directly. A manually edited or malicious config can point `sslCertFile` or
`sslKeyFile` at an unrelated file. Deleting the vhost then deletes that file.

Recommendation:

- Only delete certificates under `ssl\vhosts\<validated-name>`.
- Canonicalize and verify root containment.
- Check file existence before deletion.
- Treat external custom certificate paths as user-owned and never delete them
  automatically.

### Medium: Backup Restore Is Not Transactional

Project restore creates the target directory and extracts directly into it. If
extraction or vhost creation fails, partial files remain. There is no rollback.

Manifest fields such as `projectArchiveFile`, `sslCertFile`, and `sslKeyFile`
are not constrained to plain filenames. The archive checksum is optional, so
an empty checksum disables integrity verification.

Recommendation:

- Validate all manifest filenames with a plain-filename validator.
- Require SHA-256 for supported manifest versions.
- Extract into a temporary staging directory.
- Validate the complete result.
- Atomically rename into the destination.
- Remove staging data on failure.
- Roll back the vhost/config/hosts changes if finalization fails.

### Medium: FTPS Validation Is Not Demonstrably Secure

`Core.UniWamp.FtpTransport` configures TLS 1.2 and provides a handler that
accepts every certificate when `IgnoreCertErrors` is enabled.

For normal mode, the code does not explicitly establish:

- A trusted root certificate store
- Certificate hostname matching
- Minimum/maximum protocol negotiation
- Actionable certificate diagnostics

Depending on Indy/OpenSSL defaults, this may either reject valid servers
unexpectedly or fail to provide full hostname-authenticated TLS.

Recommendation:

- Add explicit chain and hostname verification.
- Rename the checkbox to a strongly worded insecure option.
- Log certificate subject, issuer, fingerprint, and verification result without
  credentials.
- Test expired, self-signed, wrong-host, and valid public certificates.
- Allow modern TLS negotiation rather than forcing only TLS 1.2 where the
  bundled libraries support it.

### Medium: Secrets Appear in Process Command Lines

MariaDB passwords are included in command-line arguments in backup, restore,
password management, and script installation flows.

Other processes running as the same user may inspect process command lines.
Generated application and database passwords can also appear in live script
output.

Recommendation:

- Use a temporary `--defaults-extra-file` with restrictive ACLs.
- Delete it immediately after execution.
- Add systematic output redaction for generated database and admin passwords.
- Avoid retaining raw secrets in long-lived object fields.

## Architecture and Maintainability

### Strengths

- `TAppPaths` provides a clear portable root abstraction.
- Generated files are separated from templates.
- `TServiceProcessSupervisor` validates executable identity before stopping
  saved PIDs.
- ZIP extraction performs traversal and containment checks.
- DPAPI keeps MariaDB and sync secrets out of portable JSON.
- Interfaces exist for runtime, vhosts, sync, backups, hosts, and config
  generation.
- The installer uses a user-writable location and `PrivilegesRequired=lowest`.
- Runtime startup validates Apache configuration before launch.
- Update staging includes hash verification, backup, promotion, and rollback
  concepts.

### Weaknesses

The largest units are too broad:

| Unit | Approximate size | Concern |
| --- | ---: | --- |
| `Ui.UniWamp.MainForm.pas` | 5,390 lines | UI, orchestration, async lifecycle, settings, backups, sync and tool launching |
| `Core.UniWamp.Runtime.pas` | 2,124 lines | Runtime discovery, service lifecycle, updates, diagnostics, tools and database operations |
| `Ui.UniWamp.SyncProfilesForm.pas` | 1,681 lines | Form construction, validation, import/export, secrets, testing and execution |
| `Core.UniWamp.Config.pas` | 1,247 lines | Model, defaults, parsing, migrations, normalization and persistence |

Recommended boundaries:

- `TApacheRuntime`
- `TMariaDbRuntime`
- `TToolLauncher`
- `TUpdateService`
- `TConfigRepository`
- `TConfigMigrator`
- `TBackgroundOperationCoordinator`
- `TConnectionProfileRepository`
- `TSyncProfileRepository`

The global service locator is a modest improvement over direct construction but
hides dependencies and makes isolated tests harder. Prefer constructor
injection into forms/controllers where practical.

## Sync Engine Reliability

Additional concerns:

- Downloads write directly to final files, so cancellation or network failure
  can leave truncated files.
- Uploads overwrite remote files directly.
- Mirror deletion has no recycle bin, quarantine, or rollback.
- Full local and remote trees are loaded into memory before execution.
- Local tree construction opens every file stream just to obtain its size.
- Recursive remote listing has no depth, item-count, or cycle guard.
- Same-sized files with unavailable or equal timestamps are assumed identical.
- Empty remote directories are not fully represented or mirrored.

Recommended transfer model:

1. Build and validate a plan.
2. Show transfer and deletion counts.
3. Require explicit confirmation when deletion is enabled.
4. Download into `.uniwamp-part` files and atomically rename.
5. Upload to a temporary remote name and rename where supported.
6. Set destination timestamps after successful transfer.
7. Add optional hashing for high-integrity profiles.
8. Cap recursion depth and maximum planned operations.

## Testing Results

The verification result at the reviewed commit was not green:

- Main Delphi application: compiled successfully.
- Config harness: compiled successfully.
- Process harness: compiled successfully.
- Layout smoke test: passed.
- Config harness execution: failed with
  `EInOutArgumentException: Path is empty`.
- Process harness execution: failed because live Apache owned port 8080 and the
  test expected a different startup error.

The config failure is caused by stale test path construction:
`tests/ConfigHarness.dpr` does not initialize the newer backup-directory fields
before calling `EnsurePortableLayout`.

The process harness is coupled to real machine ports and currently running
services. Tests should allocate temporary free ports and never depend on
UniWamp being stopped.

There are no tests for:

- Connection-profile secret resolution
- SFTP availability behavior
- FTP/FTPS transport
- Remote path traversal
- Sync planning and deletion
- Partial transfer cleanup
- Connection-profile import/export
- Dashboard CSRF
- Main-form shutdown during active workers

Recommended test architecture:

- Introduce an in-memory `ISyncTransport` fake.
- Unit-test plans without network access.
- Add a local disposable FTP/FTPS integration fixture.
- Separate deterministic core tests from machine/runtime integration tests.
- Run tests in GitHub Actions on Windows.
- Make PowerShell 7 an explicit prerequisite or document the
  `powershell.exe` fallback.

## Installer and Distribution

The profile-based Inno Setup structure is understandable and reusable.
Installing under `{userdocs}\UniWamp` avoids normal Program Files write
restrictions.

Remaining issues:

- Runtime binaries are not tracked in Git, so reproducing release installers
  requires undocumented external payload preparation.
- There is no lockfile or manifest recording exact Apache, PHP, MariaDB, Node,
  Adminer, Cmder, and tool hashes.
- The installer hard-blocks when the VC++ runtime is missing but does not
  provide a guided trusted installation path.
- No CI currently assembles and verifies installer payloads.
- There is no signature or documented Authenticode release process.
- Uninstall/data-retention behavior should explicitly preserve `www`,
  databases, backups, certificates, and configuration unless the user opts in
  to deleting them.

Create a versioned `distribution-manifest.json` containing every bundled
component's version, source URL, SHA-256, license, and target path.

## Documentation and Open-Source Readiness

The architecture, security checklist, test plan, release checklist, and user
manual are valuable. They are more structured than most early-stage desktop
projects.

Important gaps:

- No `LICENSE` file exists. Without one, others have no legal permission to
  modify or redistribute the code.
- No `.github` directory exists.
- No contribution guide, issue templates, pull-request template, security
  policy, or CI workflow.
- README does not explain the new connection/sync profile model.
- README does not disclose that SFTP is unavailable.
- The documented `pwsh` verification command assumes PowerShell 7 without
  listing it as a prerequisite.
- Some security documentation describes controls, such as temporary hosts-file
  replacement, that the implementation does not yet provide.

Recommended files:

- `LICENSE`
- `CONTRIBUTING.md`
- `SECURITY.md`
- `CHANGELOG.md`
- `docs/SYNC_PROFILES.md`
- `docs/CONFIG_SCHEMA.md`
- `docs/RELEASE_PROCESS.md`
- `.github/workflows/windows-build.yml`
- `.github/ISSUE_TEMPLATE/bug_report.yml`

## Market Position

| Product | Current advantage | UniWamp position |
| --- | --- | --- |
| XAMPP | Mature, cross-platform, simple Apache/MariaDB/PHP bundle. See [Apache Friends](https://www.apachefriends.org/about.html). | UniWamp can provide a more modern Windows-native dashboard, stronger vhost workflow, backups, and multi-runtime tooling. |
| Laragon | Portable, lightweight, automatic virtual hosts, automatic SSL, quick-app workflows, and broad language support. See [Laragon documentation](https://laragon.org/docs) and [Pretty URLs](https://laragon.org/docs/pretty-urls). | This is UniWamp's strongest direct competitor. UniWamp needs comparable reliability, auto-vhosts, SSL polish, and package management. |
| WampServer | Mature Apache/PHP/MySQL/MariaDB version and add-on ecosystem. See [WampServer](https://www.wampserver.com/en/php-addons/). | UniWamp's cleaner portable directory model and modern VCL dashboard can differentiate it, but runtime add-ons are currently less mature. |
| Bearsampp | Portable, modular, version switching, extensive binary/tool catalog, and active component updates. See [Bearsampp](https://bearsampp.com/) and its [module catalog](https://bearsampp.com/module). | UniWamp is currently smaller and easier to understand, but needs a signed, hash-verified component catalog to compete. |
| Modern container environments | Reproducible per-project environments and team consistency. | UniWamp is faster and simpler for Windows-local PHP work, but cannot match container isolation or cross-platform reproducibility. |

Best positioning:

> A lightweight, Windows-native, portable PHP development workspace with
> explicit configuration, project backups, secure connection profiles, and a
> transparent Delphi codebase.

Avoid competing only on "another WAMP bundle." The stronger differentiation is
project lifecycle management: vhosts, backups, diagnostics, sync, runtime
switching, and predictable portable state.

## Prioritized Action Plan

### Must Fix Before Alpha

1. Fix connection-profile secret lookup and migration.
2. Hide SFTP or implement it completely.
3. Validate all remote sync entry paths and enforce local-root containment.
4. Add background-operation shutdown coordination.
5. Add CSRF protection or make the PHP dashboard read-only.
6. Remove PHP-side process termination by executable name.
7. Repair `ConfigHarness` path initialization.
8. Isolate process tests from live ports and services.
9. Add sync engine and connection-profile tests.
10. Add a repository license.

### Should Do Before Wider Testing

1. Centralize atomic file replacement.
2. Make project restore transactional.
3. Contain certificate deletion to managed SSL directories.
4. Implement explicit FTPS certificate and hostname verification.
5. Move MariaDB credentials out of process command lines.
6. Split `MainForm` and `Runtime` into smaller controllers/services.
7. Remove the duplicate PHP configuration generator.
8. Add a versioned configuration migration pipeline.
9. Add component manifests and SHA-256 verification for release payloads.
10. Add Windows CI.

### Nice to Have

1. Automatic `.test` vhost discovery.
2. Per-project PHP version selection.
3. Read-only JSON status endpoint for the dashboard.
4. Transfer resume and atomic upload support.
5. Backup retention policies.
6. Mailpit/Redis/Memcached lifecycle supervision.
7. Signed update manifests and signed installers.
8. Exportable redacted diagnostic bundles.
9. Accessibility and keyboard-navigation review.
10. Plugin API for runtime and project templates.
