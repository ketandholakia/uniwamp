# UniWamp Beta Release Checklist

- `BETA-001` passes reliably.
- `BETA-002` produces no unintended tracked build diffs.
- `BETA-003` runs in CI and passes.
- `BETA-011` prevents plaintext secret leakage.
- `BETA-012` blocks path traversal and archive escapes.
- `BETA-020` verifies package integrity before install/update.
- `BETA-021` rolls back cleanly on failed update.
- `BETA-022` reports installer failures explicitly.
- `BETA-030` keeps project delete separate from docroot removal.
- `BETA-031` correctly switches PHP versions and restarts services.
- `BETA-032` generates valid TLS certs and fails fast on errors.
- `BETA-033` makes backup/restore scoped and fail-fast.
- `BETA-040` shows accurate service state.
- `BETA-041` gives useful logs without leaking secrets.
- `BETA-042` documents supported environments and upgrade steps.
- `BETA-043` passes clean-machine install and upgrade validation.
- The installer bundles Microsoft's official VC++ 2015-2022 x64 redistributable and handles the missing-runtime case automatically.
- The beta support matrix is published in `docs/testing/BETA_SUPPORT_MATRIX.md`.

## Beta Launch Gate

- Fresh install works on a clean Windows machine.
- Upgrade from the previous beta works.
- Create, start, stop, delete, backup, and restore all work end to end.
- No plaintext secrets appear in logs or temp files.
- No orphan Apache or MariaDB processes remain after failure.
- The project board is usable with `Ready`, `In Progress`, `Verify`, and `Blocked`.

## Recommended Launch Order

1. Finish `BETA-001` to `BETA-003`.
2. Finish `BETA-011` and `BETA-012`.
3. Finish `BETA-020` to `BETA-022`.
4. Finish `BETA-030` to `BETA-033`.
5. Finish `BETA-040` to `BETA-043`.
6. Run the clean-machine validation.
7. Tag beta only if every launch gate is green.
