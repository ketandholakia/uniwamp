# UniWamp Scripts Maintenance

This document describes how to maintain the JSON-driven script catalog and reusable installer engine used by `Help -> Scripts`.

## Purpose

The script system exists to keep common CMS and project bootstrap tasks data-driven:

- Catalog entries live in `scripts/catalog.json`.
- The Delphi UI reads the catalog and shows it in a grid.
- The installer engine executes a fixed set of supported steps.
- The catalog can be extended without changing the UI structure for every new bootstrap target.

## Repository Layout

- `scripts/catalog.json` - user-facing script catalog
- `scripts/README.md` - short format reference
- `src/Core/Core.UniWamp.ScriptCatalog.pas` - JSON parser and item loader
- `src/Core/Core.UniWamp.ScriptEngine.pas` - execution engine for supported steps
- `src/Ui/Ui.UniWamp.ScriptManagerForm.pas` - dialog that lists and launches scripts

## Catalog Rules

Each catalog entry should describe one install target.

Required fields:

- `id` - stable folder-friendly identifier
- `name` - display name shown in the UI
- `category` - group label such as `CMS`, `Framework`, or `Tooling`
- `summary` - one-line description
- `homepage` - upstream project page
- `license` - license name or identifier
- `version` - bundled or recommended version
- `install` - ordered list of execution steps

Maintenance rules:

- Keep `items` alphabetically sorted by `name` in the JSON file.
- Keep `id` stable once published.
- Treat `version` as the supported or recommended package version, not a moving target.
- Add a new entry only when the upstream license and install flow are reviewed.
- Prefer small, predictable step chains over large shell scripts.

## Supported Step Types

The engine supports these step types:

- `create_directory`
- `write_file`
- `copy_tree`
- `download`
- `extract_zip`
- `run`
- `create_database`

Avoid inventing new step names unless the engine is extended at the same time.

### Step Usage

- `create_directory`: create a target folder before a later step writes into it.
- `write_file`: generate a small text file from inline content.
- `copy_tree`: copy a local folder tree from a bundled source.
- `download`: fetch a package from an upstream URL into a local file path.
- `extract_zip`: unpack a zip archive into a local directory.
- `run`: execute a local binary with arguments and a working directory.

## Path Tokens

The engine expands these tokens before execution:

- `${appRoot}`
- `${runtime}`
- `${tools}`
- `${www}`
- `${vhosts}`
- `${tmp}`
- `${itemId}`
- `${projectName}`

Token rules:

- Use `${appRoot}` as the base for all catalog-managed paths.
- Use `${itemId}` for per-script target folders.
- Use `${projectName}` when the install flow should follow the user-entered folder name.
- Keep paths portable and relative to the UniWamp install tree.
- Do not hardcode developer-only drive letters in shipped catalog entries.

## Safety Constraints

The engine intentionally limits where scripts can write:

- File and directory targets must stay inside the UniWamp root.
- External executables are still resolved through the same safety rules.
- Downloads and archives are written into allowed paths only.
- Any new step type should preserve this safety model.

When adding or reviewing a script:

- Confirm the upstream project is suitable for redistribution or bootstrap use.
- Confirm the license field matches the actual upstream license.
- Confirm the step sequence works on a clean UniWamp installation.
- Confirm the script does not depend on hidden machine state.
- Confirm the install path can be recreated from the repository payload alone.

## Adding A Script

Use this checklist when adding a new catalog entry:

1. Pick a stable `id`.
2. Add the display metadata.
3. Add the upstream `homepage`, `license`, and `version`.
4. Define the install steps using supported step types only.
5. Keep all paths rooted in UniWamp tokens.
6. Add the entry to `scripts/catalog.json`.
7. Verify the catalog still sorts alphabetically.
8. Build UniWamp and open `Help -> Scripts` to confirm the entry appears.
9. Run the install flow against a disposable test tree before shipping it.

## Updating Existing Entries

Use the following process when updating a bundled script:

- Review the upstream release notes before changing `version`.
- Update the `summary` only if the behavior changed.
- Update `license` if the upstream project changed licensing or the metadata was wrong.
- Re-check each `run` command for executable path changes.
- Re-check each download URL and archive layout.
- Test on a clean folder after every meaningful catalog change.

## Troubleshooting

If a script does not appear in the UI:

- Validate `scripts/catalog.json` syntax.
- Check that the root object contains an `items` array.
- Check that the entry has a non-empty `name`.
- Check that the file is packaged into the installer payload.

If a script fails during execution:

- Inspect the step output shown by the manager dialog.
- Confirm the target path is inside the UniWamp root.
- Confirm the executable exists and is runnable on the current machine.
- Confirm the downloaded file or archive matches the upstream project layout.

If the UI shows stale data:

- Restart the app after editing the catalog.
- Rebuild the project if the parser or engine code changed.

## Release Expectations

Before shipping a catalog update:

- Rebuild the app.
- Verify the scripts dialog opens.
- Verify the catalog entries are alphabetized.
- Verify the installer includes `scripts/catalog.json`.
- Verify the documentation still matches the supported step types.

## Notes

- The current engine is synchronous, so long-running installs will block the dialog while they run.
- The script dialog now runs installs in a background thread and streams output into the dialog.
- Composer-based bootstrap scripts intentionally resolve the package version through the catalog metadata.
- WordPress and similar entries may depend on a selected local PHP runtime being present in `runtime/php`.
- Successful installs automatically register a matching vHost in UniWamp using the chosen project name.
