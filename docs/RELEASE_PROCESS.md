# Release Process

UniWamp keeps a `distribution-manifest.json` in `installer/` as a release-side
inventory for the bundled application binary and runtime payloads.

## Regenerate the manifest

Run the installer build script from the repository root:

```powershell
.\installer\build-installer.bat
```

The build script refreshes `installer/distribution-manifest.json` before it
calls Inno Setup.

## What the manifest records

- `name`
- `version`
- `sourceUrl`
- `license`
- `sourcePath`
- `targetPath`
- `primaryArtifact`
- `sha256`

The `sha256` value is computed from the component's primary artifact so it
changes when the release payload file changes.

## When to update it

- When a bundled runtime changes
- When the UniWamp executable version changes
- When a bundled tool is added or removed
- When a payload path changes in the installer profile

## Signing

UniWamp does not currently sign release artifacts in the build script. The
expected external release flow is:

1. Build the app and installers with `installer\build-installer.bat`.
2. Verify `installer\distribution-manifest.json` and the installer outputs.
3. Sign the generated `UniWamp-*-Setup-*.exe` installers and any standalone
   executable payloads with an Authenticode certificate.
4. Publish the signed artifacts together with the release notes and manifest.

The signing step should use the same certificate and timestamping service for
all published binaries in a release batch.
