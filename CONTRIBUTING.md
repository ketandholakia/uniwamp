# Contributing to UniWamp

UniWamp is an alpha-stage Windows desktop application. Contributions are welcome
when they improve correctness, safety, packaging, or maintainability.

## Setup

- Use Windows.
- Install Delphi 12.4 or a compatible RAD Studio version with `dcc32.exe` on
  `PATH`.
- Work from the repository root.
- Run `tests\run-all.ps1` before opening a pull request.

## What to change

- Keep edits small and focused.
- Prefer changes in `src\Core\` and `src\Ui\` over generated files.
- Update docs when a user-visible behavior changes.
- Add or adjust tests when you change validation, file handling, sync behavior,
  or process lifecycle code.

## What not to commit

- Generated configuration under `config\generated\`
- Temporary files under `tmp\`
- Build outputs under `out\`, `build-check\`, or `src\tmpbuild\`
- Local runtime binaries that are not meant to be versioned

## Pull requests

- Describe the problem and the fix.
- Mention the verification you ran.
- Call out any behavior that changes on disk, in secrets storage, or in the
  dashboard.
- If the change affects a file format, include a migration note.

## Tests

- Run the full verification flow:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File tests\run-all.ps1
```

- If a change is platform-specific, say so clearly in the PR description.
