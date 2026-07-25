# Security Policy

UniWamp is intended for local development on a single Windows machine. It should
not be exposed directly to the internet.

## Reporting a vulnerability

If you believe you have found a security issue:

- Do not open a public issue with exploit details.
- Report the problem through your normal maintainer contact path.
- Include the affected version, reproduction steps, and any logs or screenshots
  that help explain the impact.

## What counts as security-relevant

- Remote code execution
- Credential disclosure
- Path traversal or file overwrite
- Privilege escalation
- Cross-site request forgery against the local dashboard
- Unsafely handling secrets, certificates, or backups

## Expected behavior

- Secrets should stay in protected local storage.
- Generated files should be written atomically where practical.
- The dashboard should remain read-only unless a deliberate authenticated
  control path is introduced.
