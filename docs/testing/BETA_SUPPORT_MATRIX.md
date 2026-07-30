# Beta Support Matrix

This page describes the supported environment for the current UniWamp beta line.
It is the practical compatibility target for the beta release work tracked in
`BETA_RELEASE_CHECKLIST.md`.

## Supported desktop targets

| Platform | Status | Notes |
| --- | --- | --- |
| Windows 11 x64 | Validated | This is the environment currently used for local beta validation. |
| Windows 10 x64 | Targeted | Portable desktop installs and the bundled runtime layout are expected to work here as well. |

## Build and verification prerequisites

| Tool | Required | Notes |
| --- | --- | --- |
| Delphi 12.4 | Yes | Required to build the VCL application. |
| Windows PowerShell 5.1 or PowerShell 7 (`pwsh`) | Yes | Used by the repository verification flow and helper scripts. |
| Git | Yes | Required for source checkout and release workflow. |

## Runtime prerequisites

Provide these portable binaries in the UniWamp tree unless you are using a package profile that bundles them:

- `runtime/apache/bin/httpd.exe`
- `runtime/mariadb/bin/mariadbd.exe`
- `runtime/mariadb/bin/mysqladmin.exe`
- `runtime/php/<version>/php.exe`
- `runtime/php/<version>/php8apache2_4.dll` or a compatible Apache PHP module

Optional but supported when present:

- `runtime/apache/bin/openssl.exe`
- `runtime/nodejs/<version>/...`
- `bin/cmder/Cmder.exe`
- `home/adminer/index.php`

## Defaults and ports

UniWamp uses these defaults unless you change them in `config\uniwamp.json`:

| Setting | Default |
| --- | --- |
| HTTP port | 8080 |
| HTTPS port | 8443 |
| MariaDB port | 3309 |
| Default document root | `www` |
| Selected PHP version | `php85` |

## Upgrade behavior

- Upgrades are in-place and keep the portable repository layout intact.
- The app keeps `config\`, `logs\`, `ssl\`, `tmp\`, and generated config state inside the UniWamp folder.
- `tests\run-all.ps1` is the verification gate after a fresh install or upgrade.
- Manifest-driven package validation and atomic update promotion are required before a staged update is applied.

## Known beta limits

- UniWamp is a local desktop tool and does not install Windows services.
- Unattended SFTP sync does not support encrypted private-key passphrases.
- Runtime folders are expected to be portable binaries, not system-wide installs.
- The beta is not validated on Windows 7, Windows 8, or Windows 8.1.
- The beta does not target ARM64 installs.

