param(
  [string]$Root = "$(Split-Path -Parent $PSScriptRoot)"
)

$ErrorActionPreference = 'Stop'

Push-Location $Root
try {
  Push-Location (Join-Path $Root 'src')
  try {
    & cmd.exe /c build.bat
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
  }
  finally {
    Pop-Location
  }

  Push-Location (Join-Path $Root 'tests')
  try {
    & cmd.exe /c build-config-harness.bat
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

    & cmd.exe /c build-process-harness.bat
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

    & powershell.exe -NoProfile -ExecutionPolicy Bypass -File smoke.ps1 -Root $Root
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

    & .\ConfigHarness.exe
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

    & .\ProcessHarness.exe
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
  }
  finally {
    Pop-Location
  }

  Push-Location (Join-Path $Root 'installer')
  try {
    & powershell.exe -NoProfile -ExecutionPolicy Bypass -File GenerateDistributionManifest.ps1
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

    $manifest = Get-Content .\distribution-manifest.json -Raw | ConvertFrom-Json
    if ($manifest.schemaVersion -ne 1) {
      throw 'Installer manifest schemaVersion must be 1.'
    }
    if ($manifest.components.Count -lt 1) {
      throw 'Installer manifest must include bundled components.'
    }
  }
  finally {
    Pop-Location
  }

  Write-Host "UniWamp verification passed."
}
finally {
  Pop-Location
}
