param(
  [string]$Root = "$(Split-Path -Parent $PSScriptRoot)"
)

$required = @(
  "src\UniWamp.dpr",
  "config",
  "logs",
  "tmp",
  "ssl",
  "home\dashboard\overview.php",
  "home\adminer\index.php",
  "runtime\apache",
  "runtime\mariadb",
  "runtime\php\php83",
  "runtime\php\php84",
  "templates"
)

$missing = @()
foreach ($item in $required) {
  $full = Join-Path $Root $item
  if (-not (Test-Path $full)) {
    $missing += $item
  }
}

if ($missing.Count -gt 0) {
  Write-Error ("Missing required paths:`n" + ($missing -join "`n"))
  exit 1
}

Write-Host "UniWamp layout smoke test passed."
