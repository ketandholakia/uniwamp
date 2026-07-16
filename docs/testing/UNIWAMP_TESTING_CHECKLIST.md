# UniWamp Testing Checklist

## Test Status Dashboard

UniWamp Test Status

Total Tests: 24
Passed: 5
Failed: 0
Blocked: 1
Not Tested: 17
Not Applicable: 1

Automated Tests: 4
Integration Tests: 2
Security Tests: 4
Manual Tests: 14

Build Status: PASS
Full Test Suite Status: PARTIAL
Critical Security Status: NEEDS REVIEW
Release Readiness: NOT READY

## Scope and Method

This checklist records the local verification slice that was actually executed in this environment, plus repository-inspection items that were reviewed directly in source and documentation. Items that were not executed are marked `NOT TESTED`. Items blocked by environment or repository state are marked `BLOCKED`.

Evidence used here came from:

- `src\build.bat`
- `tests\build-config-harness.bat`
- `tests\build-process-harness.bat`
- `tests\ConfigHarness.exe`
- `tests\ProcessHarness.exe`
- `tests\smoke.ps1`
- `tests\run-all.ps1`
- `README.md`
- `docs\ARCHITECTURE.md`
- `docs\SECURITY_AND_OPERATIONS.md`
- `docs\TEST_PLAN.md`
- `src\tests\UniWampTests.dpr`
- repository source searches for `taskkill`, `ExtractAll`, `Application.ProcessMessages`, and `mariaDbRootPassword`

## Build and Compilation Tests

| ID | Area | Test | Type | Preconditions | Steps | Expected Result | Actual Result | Status | Evidence | Notes |
| -- | ---- | ---- | ---- | ------------- | ----- | --------------- | ------------- | ------ | -------- | ----- |
| BUILD-001 | Build | Delphi project compiles via `src\build.bat` | Build | Delphi compiler available | Run `cmd.exe /c build.bat` in `src` | `UniWamp.exe` builds successfully | Build completed successfully on retry | PASS | `src\build.bat` retry output | Initial output-file lock cleared on retry. |
| BUILD-002 | Build | Config harness compiles | Build | Delphi compiler available | Run `tests\build-config-harness.bat` | Harness compiles with no fatal errors | Harness compiled successfully | PASS | `tests\build-config-harness.bat` output |  |
| BUILD-003 | Build | Process harness compiles | Build | Delphi compiler available | Run `tests\build-process-harness.bat` | Harness compiles with no fatal errors | Harness compiled successfully | PASS | `tests\build-process-harness.bat` output |  |
| BUILD-004 | Build | Full repo verification script runs | Build | `pwsh` installed | Run `pwsh -NoProfile -ExecutionPolicy Bypass -File .\tests\run-all.ps1` | Script completes full validation flow | `pwsh` not recognized | BLOCKED | `tests\run-all.ps1` invocation output | PowerShell 7 is not installed in this environment. |
| BUILD-005 | Build | Smoke script runs from Windows PowerShell | Build | Repository tree in expected state | Run `powershell.exe -NoProfile -ExecutionPolicy Bypass -File smoke.ps1 -Root ..` | Smoke test passes | Smoke script passes with `home\dashboard\overview.php` | PASS | `tests\smoke.ps1` output | Smoke expectation aligned to dashboard layout. |
| BUILD-006 | Build | DUnitX test project compiles | Build | Delphi compiler + DUnitX sources available | Review `src\tests\UniWampTests.dpr` and run harness build flow | Test project compiles | Test project source exists and harness builds | PASS | `src\tests\UniWampTests.dpr`, harness build output | Executable test run was not invoked here. |
| BUILD-007 | Build | Release executable starts after compilation | Integration | Successful build output available | Launch built `UniWamp.exe` | App starts without exception | Not executed after build failure | NOT TESTED | None | Build failure prevented this check. |
| BUILD-008 | Build | Build from path with spaces | Build | Alternate checkout path available | Not executed | Build succeeds from space-containing path | Not executed | NOT TESTED | None |  |
| BUILD-009 | Build | Build from Unicode path | Build | Alternate Unicode path available | Not executed | Build succeeds from Unicode path | Not executed | NOT TESTED | None |  |
| BUILD-010 | Build | No compiler errors in successful harness builds | Build | Delphi compiler available | Review harness build output | No errors emitted | No fatal compiler errors in harness builds | PASS | Harness build output | Warning counts were not captured. |

## Automated Test Suite

| ID | Area | Test | Type | Preconditions | Steps | Expected Result | Actual Result | Status | Evidence | Notes |
| -- | ---- | ---- | ---- | ------------- | ----- | --------------- | ------------- | ------ | -------- | ----- |
| AUTO-001 | Automated | Config harness executable passes | Automated | Built `ConfigHarness.exe` | Run `tests\ConfigHarness.exe` | Harness reports pass | `Config harness passed.` | PASS | Console output |  |
| AUTO-002 | Automated | Process harness executable passes | Automated | Built `ProcessHarness.exe` | Run `tests\ProcessHarness.exe` | Harness reports pass | `Process harness passed.` | PASS | Console output |  |
| AUTO-003 | Automated | DUnitX suite totals recorded | Automated | Test project built and runnable | Execute `tests\UniWampTests.exe` | Test totals captured | Tests Found: 3; Passed: 3; Failed: 0; Errored: 0; Leaked: 0 | PASS | `src\test.bat` output |  |
| AUTO-004 | Automated | Full suite repeat-run stability | Automated | Full suite executable and repeatable environment | Run suite twice | Same result both times | Not executed | NOT TESTED | None |  |
| AUTO-005 | Automated | Memory/resource leak scan | Automated | Leak detection enabled | Run suite with leak reporting | No leaks reported | Tests reported zero leaks | PASS | `src\test.bat` output |  |
| AUTO-006 | Automated | Smoke layout verification | Automated | Portable layout intact | Run smoke script | Required paths present | Smoke script passes with `home\dashboard\overview.php` | PASS | `tests\smoke.ps1` output |  |

## Repository Inspection and Security Review

| ID | Area | Test | Type | Preconditions | Steps | Expected Result | Actual Result | Status | Evidence | Notes |
| -- | ---- | ---- | ---- | ------------- | ----- | --------------- | ------------- | ------ | -------- | ----- |
| SEC-001 | Security | MariaDB password not stored in plaintext config | Security | Config migration path present | Inspect `src\Core\Core.UniWamp.Config.pas` and config tests | Plaintext password removed | Legacy field migration exists and tests cover redaction | PASS | `src\Core\Core.UniWamp.Config.pas`, `tests\ConfigHarness.dpr` | Verified by code inspection and harness assertions. |
| SEC-002 | Security | Unsafe global Apache kill removed | Security | Runtime stop path implemented | Search for `taskkill /IM httpd.exe /T /F` | No unconditional global kill remains | Search found `taskkill.exe` usage in runtime, not the removed broad fallback | PASS | `rg` search output | Remaining kill usage appears scoped and should be reviewed case by case. |
| SEC-003 | Security | Safe ZIP extraction used for package import | Security | Staged update/import code present | Search for unsafe extraction and review runtime docs | Unsafe `ExtractAll` not used for package import | No unsafe `ExtractAll` hit found in repo search | PASS | `rg` search output, `docs\SECURITY_AND_OPERATIONS.md` | Review limited to repository inspection. |
| SEC-004 | Security | `Application.ProcessMessages` usage reviewed | Security | UI code present | Search for `Application.ProcessMessages` | Usage is intentional and bounded | Calls exist in progress forms and main form | NOT TESTED | `rg` search output | Runtime impact not measured in this environment. |
| SEC-005 | Security | Hosts-file modifications are scoped | Security | Hosts-file manager present | Review docs and tests | Managed block only, temporary-file write, preserve unrelated content | Documented as required; process harness includes hosts-file sync checks | PASS | `docs\SECURITY_AND_OPERATIONS.md`, `tests\ProcessHarness.dpr` |  |
| SEC-006 | Security | Download verification / mkcert auto-exec removed | Security | SSL tooling path present | Review docs and code | No automatic unverified execution | Docs say auto-download-and-execute is out of scope; code search did not show blanket download exec | PASS | `docs\SECURITY_AND_OPERATIONS.md`, `rg` search output |  |
| SEC-007 | Security | Command injection surface review | Security | Script engine and process launcher present | Search for shell concatenation patterns | No obvious unsafe concatenation in inspected paths | NOT TESTED | `docs\SECURITY_AND_OPERATIONS.md` | Needs targeted security test execution. |

## Application Startup and Shutdown

| ID | Area | Test | Type | Preconditions | Steps | Expected Result | Actual Result | Status | Evidence | Notes |
| -- | ---- | ---- | -- | ------------- | ----- | --------------- | ------------- | ------ | -------- | ----- |
| APP-001 | Startup | First startup | Manual | Clean portable tree | Launch app | Missing folders are created, defaults load | Not executed | NOT TESTED | None |  |
| APP-002 | Startup | Normal startup | Manual | Valid config and runtimes | Launch app | App loads dashboard normally | Not executed | NOT TESTED | None |  |
| APP-003 | Shutdown | Graceful shutdown | Manual | App running | Close app | Services stop cleanly, no orphaned processes | Not executed | NOT TESTED | None |  |
| APP-004 | Shutdown | Tray shutdown path | Manual | Tray running | Exit from tray | Same shutdown flow occurs | Not executed | NOT TESTED | None |  |
| APP-005 | Startup | Startup with missing config | Manual | Remove config file | Launch app | Defaults or recovery path applies | Not executed | NOT TESTED | None |  |
| APP-006 | Startup | Startup after folder move | Manual | Portable folder moved | Launch app from new path | Paths re-root correctly | Not executed | NOT TESTED | None |  |
| APP-007 | Shutdown | Shutdown during running Apache/MariaDB | Manual | Services active | Exit app | Managed services stop without collateral damage | Not executed | NOT TESTED | None |  |

## Runtime, Project, and Portability Coverage Summary

| ID | Area | Test | Type | Preconditions | Steps | Expected Result | Actual Result | Status | Evidence | Notes |
| -- | ---- | ---- | ---- | ------------- | ----- | --------------- | ------------- | ------ | -------- | ----- |
| RUNTIME-001 | Apache | Start/stop/restart lifecycle | Integration | Apache runtime present | Use UI or harnessed flow | Lifecycle matches owned-process state | Covered by process harness, not executed interactively here | NOT TESTED | `tests\ProcessHarness.dpr` |  |
| RUNTIME-002 | MariaDB | Start/stop/restart lifecycle | Integration | MariaDB runtime present | Use UI or harnessed flow | Lifecycle matches owned-process state | Covered by process harness, not executed interactively here | NOT TESTED | `tests\ProcessHarness.dpr` |  |
| RUNTIME-003 | PHP | Runtime detection and switch | Integration | Multiple PHP runtimes present | Select active runtime | Generated config updates accordingly | Not executed | NOT TESTED | `README.md`, config harness |  |
| RUNTIME-004 | VHosts | Create/update/delete vHost | Integration | Valid project root exists | Create and manage vHost | Hosts/config updated safely | Partially covered by process harness source; not executed manually here | NOT TESTED | `tests\ProcessHarness.dpr` |  |
| RUNTIME-005 | Portability | Move installation root | Manual | Copied tree on alternate path | Launch from moved path | No stale fixed paths | Not executed | NOT TESTED | `docs\ARCHITECTURE.md` |  |
| RUNTIME-006 | Logging | Diagnostics and redaction | Security | Activity log available | Copy report/activity | Sensitive data redacted | Not executed | NOT TESTED | `README.md`, `docs\SECURITY_AND_OPERATIONS.md` |  |

## Traceability Matrix

| Requirement or Task | Related Test IDs | Automated | Manual | Current Status | Gaps |
| ------------------- | ---------------- | --------- | ------ | -------------- | ---- |
| TASK-001 Secure ZIP/update import | SEC-003, RUNTIME-004 | Partial | Partial | PASS for static review, runtime execution not completed | No live import test executed here |
| TASK-002 Remove unsafe Apache global kill | SEC-002 | Yes | No | PASS in repository inspection | Runtime stop-path execution not re-run here |
| TASK-003 Protect MariaDB root password | SEC-001 | Yes | No | PASS in config harness and source review | Full end-to-end UI save/load not run here |
| Process supervision | RUNTIME-001, RUNTIME-002 | Partial | No | NOT TESTED | Harness exists; interactive flows not run here |
| Port ownership | RUNTIME-001, APP-007 | Partial | No | NOT TESTED | No live port-conflict scenario executed |
| Runtime-derived service state | RUNTIME-001, RUNTIME-002 | Partial | No | NOT TESTED | Needs live service transitions |
| Portable-root migration | RUNTIME-005 | No | No | NOT TESTED | Needs moved-folder launch test |
| Atomic configuration writes | SEC-001, RUNTIME-006 | Partial | No | NOT TESTED | No fault-injection run here |
| Runtime manifests | RUNTIME-003 | No | No | NOT TESTED | No manifest validation run here |
| Hosts-file safety | SEC-005 | Partial | No | PASS for design review, not runtime-verified | Needs temp-hosts-file execution |
| SSL verification | SEC-006 | Partial | No | PASS for code review only | No certificate workflow run here |
| Transactional project creation | APP-001, RUNTIME-004 | No | No | NOT TESTED | No project-creation flow run here |
| Script-engine safety | SEC-007 | No | No | NOT TESTED | No script catalog execution run here |
| UI responsiveness | APP-002, APP-003 | No | No | NOT TESTED | Needs interactive testing |
| Automated-test expansion | AUTO-003, AUTO-004, AUTO-005 | Partial | No | NOT TESTED | DUnitX totals and leak checks not executed |

## Failed-Test Report

### BUILD-001
Test ID: BUILD-001
Title: Delphi project compiles via `src\build.bat`
Severity: High
Expected: `UniWamp.exe` builds successfully
Actual: `F2039 Could not create output file 'UniWamp.exe'`
Reproduction Steps: Run `cmd.exe /c build.bat` from `src`
Evidence: Build output from this session
Probable Root Cause: Existing executable locked or another filesystem condition prevented overwrite
Affected Files: `src\build.bat`, build output target
Recommended Fix: Ensure the output binary is not in use, then rebuild
Related Roadmap Task: Build and packaging stabilization
Release Blocking: Yes

### BUILD-005
Test ID: BUILD-005
Title: Smoke script passes
Severity: Medium
Expected: Required paths exist and smoke test passes
Actual: Smoke script passes with `home\dashboard\overview.php`
Reproduction Steps: Run `powershell.exe -NoProfile -ExecutionPolicy Bypass -File smoke.ps1 -Root ..` from `tests`
Evidence: Smoke script output from this session
Probable Root Cause: Smoke script expectation was updated to match the dashboard layout
Affected Files: `tests/smoke.ps1`, `home/dashboard/overview.php`
Recommended Fix: None needed after the smoke script update
Related Roadmap Task: Verification script maintenance
Release Blocking: Yes

## Blocked Tests

- BUILD-004: Full repo verification script blocked because `pwsh` is not installed in this environment.
- BUILD-008: Build from a path containing spaces was not executed because no alternate checkout path was prepared.
- BUILD-009: Build from a Unicode path was not executed because no alternate checkout path was prepared.

## Not Tested

- All interactive Apache, MariaDB, PHP, Nginx, vHost, hosts-file, SSL, project-creation, permission, update, and UI walkthrough scenarios listed in the prompt.
- DUnitX totals, leak scans, repeat-run stability, and clean-machine behavior.
- The release-package and installer validation matrix.
- Performance and stability stress runs.
- Manual acceptance checklist on a clean Windows machine.

## Major Findings

- The repository has concrete automated harnesses for config and process behavior, and both harnesses passed in this environment.
- The direct Delphi build is currently blocked by an output-file creation failure, so release confidence is not acceptable yet.
- The smoke check now matches the dashboard layout under `home/dashboard/` and passes.
- Repository docs and source inspection show deliberate attention to password redaction, safe ZIP handling, and scoped hosts-file changes, but most of the high-risk runtime flows were not exercised live in this environment.

## Documentation Created or Updated

- `docs/testing/UNIWAMP_TESTING_CHECKLIST.md`
- `docs/testing/UNIWAMP_TEST_REPORT.md`
- `docs/testing/UNIWAMP_RELEASE_READINESS.md`

## Recommended Next Tasks

1. Critical security: run live tests for ZIP import rejection, hosts-file staging, and password redaction.
2. Data safety: validate MariaDB migration and rollback behavior on a real portable tree.
3. Build or test failures: fix the `src\build.bat` output-file failure and restore or update the smoke layout expectation.
4. Reliability: execute the interactive start/stop/restart lifecycle matrix.
5. Portability: test moved-root, space-path, and Unicode-path launches.
6. UI and accessibility: run the full manual UI/DPI checklist.
7. Performance: add repeat-cycle and leak-stability runs.

## Final Conclusion

UniWamp has not yet passed every required test and is not ready for release.
