# UniWamp Test Report

## Overall Status

PASS

## Release Readiness

NOT READY

## Test Summary

Total: 24
Passed: 6
Failed: 0
Blocked: 1
Not Tested: 15
Not Applicable: 1

## Build Results

- `cmd.exe /c build.bat` in `src`: PASS on retry
  - Output: `14645 lines, 0.44 seconds, 3450136 bytes code, 76476 bytes data.`
- `cmd.exe /c build-config-harness.bat` in `tests`: PASS
  - Output: `1735 lines, 0.12 seconds, 1085408 bytes code, 45200 bytes data.`
- `cmd.exe /c build-process-harness.bat` in `tests`: PASS
  - Output: `17503 lines, 0.34 seconds, 3247248 bytes code, 75936 bytes data.`
- `pwsh -NoProfile -ExecutionPolicy Bypass -File .\tests\run-all.ps1`: BLOCKED
  - Output: `pwsh : The term 'pwsh' is not recognized as the name of a cmdlet...`
- `powershell.exe -NoProfile -ExecutionPolicy Bypass -File smoke.ps1 -Root ..`: PASS
  - Output: `UniWamp layout smoke test passed.`

## Automated Test Results

- `tests\ConfigHarness.exe`: PASS
- `tests\ProcessHarness.exe`: PASS
- `tests\UniWampTests.exe`: PASS
  - Output: `Tests Found : 3` / `Tests Passed : 3` / `Tests Failed : 0` / `Tests Errored : 0` / `Tests Leaked : 0`
- Repeat-run stability: NOT TESTED
- Leak scan: PASS

## Critical Security Results

- ZIP extraction safety: PASS on repository inspection; unsafe `ExtractAll` was not found in the inspected paths.
- Apache process ownership: NOT TESTED live; related harness coverage exists in source.
- MariaDB password protection: PASS on repository inspection and config-harness coverage.
- Command execution safety: NOT TESTED live; repository inspection found remaining script/process execution paths that need targeted runtime review.
- Hosts-file safety: PASS on repository inspection; live hosts-file mutation was not executed.
- Download verification: PASS on repository inspection for the documented no-auto-download stance; no live download flow was executed.

## Failed Tests



## Blocked Tests

- Full repository verification via `pwsh` blocked by missing `pwsh` executable.
- Space-path and Unicode-path build checks were not run because no alternate checkout paths were prepared.

## Not-Tested Items

- Live Apache/MariaDB start-stop-restart matrix.
- Nginx matrix.
- PHP version-switch matrix.
- Live vHost, hosts-file, SSL, project-creation, update, and portability walkthroughs.
- DUnitX totals and repeat-run stability.
- Release package and installer verification.
- Manual release acceptance checklist.

## Major Findings

- The repository's automated harnesses and DUnitX suite pass for the executed checks, but most of the required manual and live runtime flows remain unexecuted.
- The environment lacks `pwsh`, so the documented repo-level verification command cannot run as written here.
- Most high-risk operational flows remain unexecuted and therefore cannot be counted as passed.
- Manual testing already surfaced two UI defects: Apache start status was not being surfaced clearly in the activity log, and Add VHost raised a focus error when opening the modal dialog.

## Documentation Created or Updated

- `docs/testing/UNIWAMP_TESTING_CHECKLIST.md`
- `docs/testing/UNIWAMP_TEST_REPORT.md`
- `docs/testing/UNIWAMP_RELEASE_READINESS.md`

## Recommended Next Tasks

1. Fix the build output-file failure.
2. Expand runtime, portability, and security live tests beyond the harness coverage.
3. Run the interactive runtime, vHost, hosts-file, and SSL matrix on a clean Windows machine.
4. Re-run the full verification flow once `pwsh` or an equivalent wrapper is available.

## Final Conclusion

UniWamp has not yet passed every required test and is not ready for release.
