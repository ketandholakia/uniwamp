# UniWamp Script Catalog Reference

This folder contains the portable catalog used by `Help -> Scripts`.

For maintenance guidance, see [`docs/SCRIPTS_MAINTENANCE.md`](../docs/SCRIPTS_MAINTENANCE.md).

`catalog.json` is the data file that drives the script manager. Entries are sorted alphabetically by `name` when loaded.

Each item uses these fields:

- `id` - stable folder-friendly identifier
- `name`, `category`, `summary` - display metadata
- `homepage`, `license`, `version` - attribution and package information
- `requirements` - optional minimum environment requirements shown in the UI and enforced by pre-install checks
- `install` - ordered execution steps

`requirements` supports these optional fields:

- `phpMinVersion`
- `nodeMinVersion`
- `mariaDbMinVersion`
- `apacheMinVersion`
- `notes`

Supported step types:

- `create_directory` - creates `destination`
- `write_file` - writes `content` to `destination`
- `copy_tree` - recursively copies `source` to `destination`
- `download` - downloads `url` to `destination`
- `extract_zip` - extracts `source` into `destination`
- `run` - runs `executable` with `arguments` in `workingDirectory`
- `create_database` - creates a MariaDB database named by `destination`

Supported path tokens are `${appRoot}`, `${runtime}`, `${tools}`, `${www}`, `${vhosts}`, `${tmp}`, and `${itemId}`. Paths are restricted to the UniWamp application root by the installer engine.
Script installs also receive `${projectName}`, which is the user-supplied target folder name chosen before execution.

Do not use unpinned package versions for production deployments without reviewing the upstream project release and license first. The sample catalog uses Composer's recommended versions so entries remain useful, while exposing the policy in the catalog metadata.
