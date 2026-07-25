# Connection and Sync Profiles

UniWamp separates remote access into two layers:

- Connection profiles describe how to reach a remote host.
- Sync profiles describe what to transfer, in which direction, and with which filters.

This split keeps credentials reusable across multiple sync jobs and lets one connection profile back several sync profiles.

## Connection profiles

Connection profiles store transport details:

- Name
- Protocol: `ftp`, `ftps`, or `sftp`
- Host and port
- Username
- Password
- Private key file
- Private key passphrase
- Passive mode for FTP and FTPS
- Certificate-error override for FTPS

Passwords and passphrases are stored in the Windows secret store, not in `config/uniwamp.json`.

## Sync profiles

Sync profiles define the transfer job:

- Name
- Optional linked connection profile
- Direction: upload or download
- Local path
- Remote path
- Working directory for hooks
- Pre-sync and post-sync commands
- Delete mode for mirror-style cleanup
- Dry-run default
- Exclude patterns

A sync profile can either:

- Use its own inline connection fields, or
- Reference a named connection profile

## Typical flow

1. Create one or more connection profiles for the remote hosts you use.
2. Create a sync profile that points at the correct local folder and remote path.
3. Pick the connection profile if you want to reuse shared credentials.
4. Use dry run first if deletion is enabled.
5. Run the transfer from the Sync Profiles form or from a pinned vHost action.

## Notes

- FTP and FTPS use password credentials.
- SFTP can use a password, an unencrypted private key, or a private key passphrase where supported by the transport.
- Sync profiles are meant for repeated jobs, not one-off ad hoc transfers.
- The app validates local sync paths so downloads and uploads stay inside the chosen root.
