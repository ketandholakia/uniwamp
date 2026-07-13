# UniWamp Test and Verification Plan

## Commands

Run from the repository root:

```powershell
pwsh -NoProfile -File .\tests\smoke.ps1
```

To run the full repo verification flow:

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File .\tests\run-all.ps1
```

Build the Delphi application with Delphi 12.4 from a Delphi command prompt. Replace the placeholder with the local Delphi installation path:

```bat
cd src
call "<Delphi>\bin\rsvars.bat"
dcc32 UniWamp.dpr
```

The exact Delphi installation path is environment-specific and must not be committed to a project script. Installer validation uses the documented Inno Setup workflow after the application output exists.

## Quick Release Check

1. Run `pwsh -NoProfile -ExecutionPolicy Bypass -File .\tests\run-all.ps1`.
2. Review the output for missing runtimes, recovery messages, or process-manager failures.
3. Verify a portable copy still starts from another path.
4. Rebuild the installer only after the verification flow passes.

## Test layers

### Static checks

- Search for absolute drive-letter paths in source, templates, JSON, and installer scripts.
- Search for shell command construction from user-controlled values.
- Check generated configuration is not used as a substitute for source templates.
- Review filesystem, process, hosts-file, certificate, and database operations.

### Unit tests

Add a Delphi test project or small test harness for pure/core logic. Prioritize portable path normalization and root containment, configuration defaults/validation/migration/atomic persistence, port validation, runtime/version parsing, domain and vhost validation, template rendering, hosts-file preservation, and secret redaction.

Current priority coverage:

- Malformed `config/uniwamp.json` should back up the original file, restore defaults, and write a valid replacement.
- Partially valid config should preserve usable fields and only migrate fields that actually need changes.
- Legacy absolute paths and moved-root scenarios should normalize to the current portable root.
- `LoadOrCreate` should return a migrated state only when the configuration was created, repaired, or rewritten.
- Atomic save behavior should be exercised with a small harness that can simulate write failures without touching real user data.
- Process-manager behavior should be exercised with a small harness that checks missing executables, timeouts, non-zero exits, stale PID cleanup, duplicate-start short-circuits, and restart failure labeling.

### Process tests

Use mocked process and filesystem seams. Do not start or stop the user's real services in automated tests. Cover stale PIDs, PID reuse, timeout, non-zero exit code, output capture, graceful shutdown, and duplicate operations.

### Smoke tests

The smoke test must verify a portable layout without requiring a fixed drive letter. Installer-profile tests should use a matrix for supported PHP profiles and report missing optional runtimes explicitly.

## Manual acceptance matrix

| Scenario | Expected result |
| --- | --- |
| First launch | Defaults load, folders are created, and missing runtimes are reported clearly |
| Start all | MariaDB and Apache start in dependency order; dashboard opens only when health checks pass |
| Stop all | Graceful shutdown completes; no managed child process remains |
| Restart | State remains accurate through the transition |
| Bad Apache configuration | `httpd -t` fails and Apache is not started |
| MariaDB first initialization | Data directory is initialized only when empty and never overwritten |
| PHP switch | Selected runtime is validated and generated config is regenerated |
| Occupied port | Conflict identifies the port and owner where possible |
| Vhost create/delete | Config and managed hosts entries update without touching unrelated entries |
| Hosts permission failure | State is retained and user receives an administrator-action message |
| HTTPS | Certificate/configuration errors are actionable; trust installation is explicit |
| Logs | Activity and runtime logs are viewable, bounded, and redacted where required |
| Move installation | A copied folder on another path starts without stale development-machine paths |

## Validation reporting

For each run record the date, Windows/Delphi/Inno Setup versions, exact command, result, duration, first actionable error, root cause, files involved, and whether the failure is environment-related or a product defect.
