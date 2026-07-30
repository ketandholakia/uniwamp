param(
  [string]$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path,
  [string]$OutputPath = (Join-Path $PSScriptRoot 'distribution-manifest.json')
)

$ErrorActionPreference = 'Stop'

function Get-Sha256Hash {
  param([Parameter(Mandatory = $true)][string]$Path)

  if (Test-Path -LiteralPath $Path -PathType Leaf) {
    return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToLowerInvariant()
  }

  if (-not (Test-Path -LiteralPath $Path -PathType Container)) {
    throw "Component path not found: $Path"
  }

  $root = Get-FullPath $Path
  if (-not $root.EndsWith([System.IO.Path]::DirectorySeparatorChar)) {
    $root += [System.IO.Path]::DirectorySeparatorChar
  }

  $lines = New-Object System.Collections.Generic.List[string]
  $files = Get-ChildItem -LiteralPath $Path -File -Recurse | Sort-Object FullName
  foreach ($file in $files) {
    $relative = $file.FullName.Substring($root.Length).Replace([System.IO.Path]::DirectorySeparatorChar, '/')
    $fileHash = (Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash.ToLowerInvariant()
    $lines.Add("$relative`t$fileHash")
  }

  $text = $lines -join "`n"
  $sha = [System.Security.Cryptography.SHA256]::Create()
  try {
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($text)
    $digest = $sha.ComputeHash($bytes)
    return ([System.BitConverter]::ToString($digest) -replace '-', '').ToLowerInvariant()
  }
  finally {
    $sha.Dispose()
  }
}

function New-ComponentEntry {
  param(
    [Parameter(Mandatory = $true)][string]$Name,
    [Parameter(Mandatory = $true)][string]$Version,
    [Parameter(Mandatory = $true)][string]$SourceUrl,
    [Parameter(Mandatory = $true)][string]$License,
    [Parameter(Mandatory = $true)][string]$SourcePath,
    [Parameter(Mandatory = $true)][string]$TargetPath,
    [string]$PrimaryArtifact = '',
    [bool]$Required = $true
  )

  $resolvedSourcePath = Join-Path $RepoRoot $SourcePath
  if (-not (Test-Path -LiteralPath $resolvedSourcePath)) {
    if ($Required) {
      throw "Component source path does not exist: $SourcePath"
    }

    return $null
  }

  if ($PrimaryArtifact -eq '') {
    $primaryArtifact = $SourcePath
  }
  else {
    $primaryArtifact = $PrimaryArtifact
  }

  $resolvedArtifactPath = Join-Path $RepoRoot $primaryArtifact
  if (-not (Test-Path -LiteralPath $resolvedArtifactPath -PathType Leaf)) {
    throw "Component primary artifact does not exist: $primaryArtifact"
  }

  [pscustomobject]@{
    name = $Name
    version = $Version
    sourceUrl = $SourceUrl
    license = $License
    sourcePath = $SourcePath
    targetPath = $TargetPath
    primaryArtifact = $primaryArtifact
    sha256 = (Get-Sha256Hash -Path $resolvedArtifactPath)
  }
}

$components = @(
  New-ComponentEntry -Name 'UniWamp' -Version 'v0.2.0-alpha' -SourceUrl 'https://github.com/ketandholakia/uniwamp' -License 'MIT' -SourcePath 'src\tmpbuild\bin\UniWamp.exe' -TargetPath '{app}\UniWamp.exe'
  New-ComponentEntry -Name 'Apache HTTP Server' -Version '2.4.68' -SourceUrl 'https://httpd.apache.org/download.cgi' -License 'Apache-2.0' -SourcePath 'runtime\apache' -TargetPath '{app}\runtime\apache' -PrimaryArtifact 'runtime\apache\bin\httpd.exe'
  New-ComponentEntry -Name 'MariaDB Server' -Version '11.8.8.0' -SourceUrl 'https://mariadb.org/download/' -License 'GPL-2.0-only' -SourcePath 'runtime\mariadb' -TargetPath '{app}\runtime\mariadb' -PrimaryArtifact 'runtime\mariadb\bin\mariadbd.exe'
  New-ComponentEntry -Name 'PHP 8.2' -Version '8.2.32' -SourceUrl 'https://www.php.net/downloads.php' -License 'PHP License' -SourcePath 'runtime\php\php82' -TargetPath '{app}\runtime\php\php82' -PrimaryArtifact 'runtime\php\php82\php.exe'
  New-ComponentEntry -Name 'PHP 8.3' -Version '8.3.32' -SourceUrl 'https://www.php.net/downloads.php' -License 'PHP License' -SourcePath 'runtime\php\php83' -TargetPath '{app}\runtime\php\php83' -PrimaryArtifact 'runtime\php\php83\php.exe'
  New-ComponentEntry -Name 'PHP 8.4' -Version '8.4.23' -SourceUrl 'https://www.php.net/downloads.php' -License 'PHP License' -SourcePath 'runtime\php\php84' -TargetPath '{app}\runtime\php\php84' -PrimaryArtifact 'runtime\php\php84\php.exe'
  New-ComponentEntry -Name 'PHP 8.5' -Version '8.5.8' -SourceUrl 'https://www.php.net/downloads.php' -License 'PHP License' -SourcePath 'runtime\php\php85' -TargetPath '{app}\runtime\php\php85' -PrimaryArtifact 'runtime\php\php85\php.exe'
  New-ComponentEntry -Name 'Node.js' -Version '22.23.1' -SourceUrl 'https://nodejs.org/en/download' -License 'MIT' -SourcePath 'runtime\nodejs\node-v22.23.1-win-x64' -TargetPath '{app}\runtime\nodejs\node-v22.23.1-win-x64' -PrimaryArtifact 'runtime\nodejs\node-v22.23.1-win-x64\node.exe'
  New-ComponentEntry -Name 'Composer' -Version '2.10.2' -SourceUrl 'https://getcomposer.org/download/' -License 'MIT' -SourcePath 'runtime\tools\composer' -TargetPath '{app}\runtime\tools\composer' -PrimaryArtifact 'runtime\tools\composer\composer.phar'
  New-ComponentEntry -Name 'Git for Windows' -Version '2.55.0.windows.2' -SourceUrl 'https://gitforwindows.org/' -License 'GPL-2.0-only' -SourcePath 'runtime\tools\git' -TargetPath '{app}\runtime\tools\git' -PrimaryArtifact 'runtime\tools\git\cmd\git.exe'
  New-ComponentEntry -Name 'PuTTY' -Version '0.84' -SourceUrl 'https://www.chiark.greenend.org.uk/~sgtatham/putty/latest.html' -License 'MIT' -SourcePath 'runtime\tools\putty' -TargetPath '{app}\runtime\tools\putty' -PrimaryArtifact 'runtime\tools\putty\psftp.exe'
  New-ComponentEntry -Name 'Lite XL' -Version 'release-3.2.14-0-g8d604353a' -SourceUrl 'https://lite-xl.com/' -License 'MIT' -SourcePath 'runtime\tools\lite-xl' -TargetPath '{app}\runtime\tools\lite-xl' -PrimaryArtifact 'runtime\tools\lite-xl\lite-xl.exe'
  New-ComponentEntry -Name 'Mailpit' -Version '1.30.4' -SourceUrl 'https://mailpit.axllent.org/' -License 'MIT' -SourcePath 'runtime\tools\mailpit' -TargetPath '{app}\runtime\tools\mailpit' -PrimaryArtifact 'runtime\tools\mailpit\mailpit.exe'
  New-ComponentEntry -Name 'Redis' -Version '8.8.0' -SourceUrl 'https://redis.io/download/' -License 'BSD-3-Clause' -SourcePath 'runtime\tools\redis' -TargetPath '{app}\runtime\tools\redis' -PrimaryArtifact 'runtime\tools\redis\redis-server.exe'
  New-ComponentEntry -Name 'WP-CLI' -Version '2.12.0' -SourceUrl 'https://wp-cli.org/' -License 'MIT' -SourcePath 'runtime\tools\wp-cli' -TargetPath '{app}\runtime\tools\wp-cli' -PrimaryArtifact 'runtime\tools\wp-cli\wp-cli.phar'
  New-ComponentEntry -Name 'WinSCP' -Version '6.5.6' -SourceUrl 'https://winscp.net/' -License 'GPL-3.0-or-later' -SourcePath 'runtime\tools\winscp' -TargetPath '{app}\runtime\tools\winscp' -PrimaryArtifact 'runtime\tools\winscp\WinSCP.exe'
  New-ComponentEntry -Name 'Adminer' -Version '5.4.2' -SourceUrl 'https://www.adminer.org/' -License 'Apache-2.0 or GPL-2.0-only' -SourcePath 'home\adminer' -TargetPath '{app}\home\adminer' -PrimaryArtifact 'home\adminer\index.php'
  New-ComponentEntry -Name 'Cmder' -Version '1.3.25.328' -SourceUrl 'https://cmder.app/' -License 'MIT' -SourcePath 'bin\cmder' -TargetPath '{app}\bin\cmder' -PrimaryArtifact 'bin\cmder\Cmder.exe' -Required $false
) | Where-Object { $_ -ne $null }

$manifest = [ordered]@{
  schemaVersion = 1
  repository = 'https://github.com/ketandholakia/uniwamp'
  releaseVersion = 'v0.2.0-alpha'
  app = [ordered]@{
    name = 'UniWamp'
    version = '0.2.0.0'
    displayVersion = 'v0.2.0-alpha'
    sourcePath = 'src\tmpbuild\bin\UniWamp.exe'
    targetPath = '{app}\UniWamp.exe'
    sha256 = (Get-Sha256Hash -Path (Join-Path $RepoRoot 'src\tmpbuild\bin\UniWamp.exe'))
  }
  components = $components
}

$json = $manifest | ConvertTo-Json -Depth 6
Set-Content -LiteralPath $OutputPath -Value $json -Encoding UTF8
