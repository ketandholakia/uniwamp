#!/usr/bin/env pwsh
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter()]
    [string]$RepositoryFullName = "ketandholakia/uniwamp",

    [Parameter()]
    [string]$ProjectTitle = "UniWamp Beta",

    [Parameter()]
    [string]$Owner = "@me",

    [Parameter()]
    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'

function Assert-GhAvailable {
    if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
        throw "GitHub CLI (`gh`) was not found on PATH."
    }
}

function Invoke-GhJson {
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$Arguments
    )

    $raw = & gh @Arguments | Out-String
    if (-not $raw.Trim()) {
        return $null
    }

    return $raw | ConvertFrom-Json
}

function New-IssueSpec {
    param(
        [Parameter(Mandatory = $true)]
        [int]$Number,

        [Parameter(Mandatory = $true)]
        [string]$Status
    )

    [pscustomobject]@{
        Number = $Number
        Status = $Status
    }
}

$issueSpecs = @(
    New-IssueSpec -Number 1 -Status 'Ready'
    New-IssueSpec -Number 2 -Status 'Ready'
    New-IssueSpec -Number 3 -Status 'Ready'
    New-IssueSpec -Number 4 -Status 'Backlog'
    New-IssueSpec -Number 5 -Status 'Backlog'
    New-IssueSpec -Number 6 -Status 'Backlog'
    New-IssueSpec -Number 7 -Status 'Backlog'
    New-IssueSpec -Number 8 -Status 'Backlog'
    New-IssueSpec -Number 9 -Status 'Backlog'
    New-IssueSpec -Number 10 -Status 'Backlog'
    New-IssueSpec -Number 11 -Status 'Backlog'
    New-IssueSpec -Number 12 -Status 'Backlog'
    New-IssueSpec -Number 13 -Status 'Backlog'
    New-IssueSpec -Number 14 -Status 'Backlog'
    New-IssueSpec -Number 15 -Status 'Backlog'
    New-IssueSpec -Number 16 -Status 'Backlog'
    New-IssueSpec -Number 17 -Status 'Backlog'
    New-IssueSpec -Number 18 -Status 'Blocked'
)

Assert-GhAvailable

if (-not $DryRun) {
    try {
        & gh auth status --show-token | Out-Null
    }
    catch {
        throw "Run `gh auth login` and `gh auth refresh -s project` before bootstrapping Projects v2."
    }
}

$project = Invoke-GhJson -Arguments @('project', 'list', '--owner', $Owner, '--format', 'json')
if ($project) {
    $existing = $project | Where-Object { $_.title -eq $ProjectTitle } | Select-Object -First 1
} else {
    $existing = $null
}

if ($existing) {
    $projectNumber = $existing.number
    $projectId = $existing.id
} else {
    if ($DryRun) {
        Write-Host "[dry-run] gh project create --owner $Owner --title `"$ProjectTitle`""
        $projectNumber = 1
        $projectId = 'dry-run-project-id'
    }
    else {
        $created = Invoke-GhJson -Arguments @('project', 'create', '--owner', $Owner, '--title', $ProjectTitle, '--format', 'json')
        $projectNumber = $created.number
        $projectId = $created.id
    }
}

if ($DryRun) {
    Write-Host "[dry-run] gh project link $projectNumber --owner $Owner -R $RepositoryFullName"
}
else {
    try {
        & gh project link $projectNumber --owner $Owner -R $RepositoryFullName | Out-Null
    }
    catch {
        if ($_.Exception.Message -notmatch 'already linked') {
            throw
        }
    }
}

$fieldSpecs = @(
    [pscustomobject]@{ Name = 'Status'; DataType = 'SINGLE_SELECT'; Options = @('Backlog', 'Ready', 'In Progress', 'Verify', 'Blocked', 'Done') },
    [pscustomobject]@{ Name = 'Priority'; DataType = 'SINGLE_SELECT'; Options = @('P0 Blocker', 'P1 High', 'P2 Medium', 'P3 Low') },
    [pscustomobject]@{ Name = 'Risk'; DataType = 'SINGLE_SELECT'; Options = @('Secret Leak', 'Orphan Process', 'Data Loss', 'None') }
)

foreach ($field in $fieldSpecs) {
    $fields = Invoke-GhJson -Arguments @('project', 'field-list', $projectNumber, '--owner', $Owner, '--format', 'json')
    $existingField = $null
    if ($fields) {
        $existingField = $fields | Where-Object { $_.name -eq $field.Name } | Select-Object -First 1
    }

    if (-not $existingField) {
        if ($DryRun) {
            Write-Host "[dry-run] gh project field-create $projectNumber --owner $Owner --name `"$($field.Name)`" --data-type $($field.DataType) --single-select-options $($field.Options -join ',')"
            continue
        }

        $args = @('project', 'field-create', $projectNumber, '--owner', $Owner, '--name', $field.Name, '--data-type', $field.DataType, '--single-select-options')
        $args += $field.Options
        & gh @args | Out-Null
    }
}

$fieldsAfterCreate = Invoke-GhJson -Arguments @('project', 'field-list', $projectNumber, '--owner', $Owner, '--format', 'json')
$statusField = $fieldsAfterCreate | Where-Object { $_.name -eq 'Status' } | Select-Object -First 1

if (-not $statusField) {
    throw "Status field could not be resolved for project $ProjectTitle."
}

$statusOptionMap = @{}
foreach ($option in $statusField.options) {
    $statusOptionMap[$option.name] = $option.id
}

foreach ($issue in $issueSpecs) {
    $issueUrl = "https://github.com/$RepositoryFullName/issues/$($issue.Number)"

    if ($DryRun) {
        Write-Host "[dry-run] gh project item-add $projectNumber --owner $Owner --url $issueUrl"
        Write-Host "[dry-run] gh project item-edit --project-id $projectId --field-id $($statusField.id) --single-select-option-id $($statusOptionMap[$issue.Status])"
        continue
    }

    $added = Invoke-GhJson -Arguments @('project', 'item-add', $projectNumber, '--owner', $Owner, '--url', $issueUrl, '--format', 'json')
    $itemId = $added.id
    if (-not $itemId) {
        throw "Could not resolve project item ID for issue #$($issue.Number)."
    }

    & gh project item-edit `
        --id $itemId `
        --project-id $projectId `
        --field-id $statusField.id `
        --single-select-option-id $statusOptionMap[$issue.Status] | Out-Null
}

Write-Host "Project ready: $ProjectTitle"
Write-Host "Manual step: open the project in GitHub and switch the view to Board layout grouped by the Status field."
