#!/usr/bin/env pwsh
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter()]
    [string]$RepositoryFullName = "ketandholakia/uniwamp",

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

function Get-OrCreateLabel {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Repository,

        [Parameter(Mandatory = $true)]
        [string]$Name,

        [Parameter(Mandatory = $true)]
        [string]$Color,

        [Parameter(Mandatory = $true)]
        [string]$Description
    )

    $labels = Invoke-GhJson -Arguments @('api', "repos/$Repository/labels?per_page=100")
    if ($labels) {
        $existing = $labels | Where-Object { $_.name -eq $Name } | Select-Object -First 1
        if ($existing) {
            return $existing
        }
    }

    if ($DryRun) {
        Write-Host "[dry-run] create label $Name"
        return $null
    }

    return Invoke-GhJson -Arguments @(
        'api', '--method', 'POST', "repos/$Repository/labels",
        '-f', "name=$Name",
        '-f', "color=$Color",
        '-f', "description=$Description"
    )
}

function Get-OrCreateMilestone {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Repository,

        [Parameter(Mandatory = $true)]
        [string]$Title,

        [Parameter(Mandatory = $true)]
        [string]$Description
    )

    $milestones = Invoke-GhJson -Arguments @('api', "repos/$Repository/milestones?state=all&per_page=100")
    if ($milestones) {
        $existing = $milestones | Where-Object { $_.title -eq $Title } | Select-Object -First 1
        if ($existing) {
            return $existing
        }
    }

    if ($DryRun) {
        Write-Host "[dry-run] create milestone $Title"
        return [pscustomobject]@{ number = $null; title = $Title }
    }

    return Invoke-GhJson -Arguments @(
        'api', '--method', 'POST', "repos/$Repository/milestones",
        '-f', "title=$Title",
        '-f', "description=$Description",
        '-f', 'state=open'
    )
}

function New-IssueSpec {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Title,

        [Parameter(Mandatory = $true)]
        [string[]]$Labels,

        [Parameter(Mandatory = $true)]
        [string]$Body,

        [Parameter(Mandatory = $true)]
        [string]$MilestoneTitle
    )

    [pscustomobject]@{
        Title         = $Title
        Labels        = $Labels
        Body          = $Body
        MilestoneTitle = $MilestoneTitle
    }
}

$labelSpecs = @(
    [pscustomobject]@{ Name = 'beta'; Color = '0E8A16'; Description = 'Beta release scope' },
    [pscustomobject]@{ Name = 'priority:high'; Color = 'D73A4A'; Description = 'Release-blocking or high-priority work' },
    [pscustomobject]@{ Name = 'priority:medium'; Color = 'FBCA04'; Description = 'Important but not release-blocking work' },
    [pscustomobject]@{ Name = 'kind:bug'; Color = 'B60205'; Description = 'Defect fix' },
    [pscustomobject]@{ Name = 'kind:hardening'; Color = '5319E7'; Description = 'Reliability or security hardening' },
    [pscustomobject]@{ Name = 'kind:infra'; Color = '0052CC'; Description = 'Build, CI, installer, or release infrastructure' },
    [pscustomobject]@{ Name = 'kind:docs'; Color = '0075CA'; Description = 'Documentation work' },
    [pscustomobject]@{ Name = 'kind:release'; Color = '2EA44F'; Description = 'Release freeze or verification task' },
    [pscustomobject]@{ Name = 'area:process'; Color = '0052CC'; Description = 'Process lifecycle or cleanup' },
    [pscustomobject]@{ Name = 'area:security'; Color = 'B60205'; Description = 'Secrets, trust boundaries, or security-sensitive code' },
    [pscustomobject]@{ Name = 'area:build'; Color = '6F42C1'; Description = 'Build reproducibility or packaging' },
    [pscustomobject]@{ Name = 'area:ci'; Color = '0E8A16'; Description = 'Continuous integration' },
    [pscustomobject]@{ Name = 'area:update'; Color = 'FBCA04'; Description = 'Update or promotion flow' },
    [pscustomobject]@{ Name = 'area:installer'; Color = 'D93F0B'; Description = 'Installer or elevation flow' },
    [pscustomobject]@{ Name = 'area:project'; Color = '0366D6'; Description = 'Project lifecycle actions' },
    [pscustomobject]@{ Name = 'area:php'; Color = '0052CC'; Description = 'PHP runtime selection or config' },
    [pscustomobject]@{ Name = 'area:tls'; Color = '00A3A3'; Description = 'TLS or certificate setup' },
    [pscustomobject]@{ Name = 'area:backup'; Color = 'C2E0C6'; Description = 'Backup or restore' },
    [pscustomobject]@{ Name = 'area:dashboard'; Color = '6F42C1'; Description = 'Dashboard state or diagnostics' },
    [pscustomobject]@{ Name = 'area:docs'; Color = '0075CA'; Description = 'User-facing documentation' },
    [pscustomobject]@{ Name = 'risk:secret-leak'; Color = 'B60205'; Description = 'Can expose secrets or credentials' },
    [pscustomobject]@{ Name = 'risk:orphan-process'; Color = 'D93F0B'; Description = 'Can leave background processes running' },
    [pscustomobject]@{ Name = 'risk:data-loss'; Color = 'D73A4A'; Description = 'Can delete or overwrite user data' }
)

$milestoneSpecs = @(
    [pscustomobject]@{ Title = 'Beta 0 - Stabilization'; Description = 'Baseline reliability, build determinism, and process lifecycle fixes' },
    [pscustomobject]@{ Title = 'Beta 1 - Security & Safety'; Description = 'Secrets, path validation, and destructive-operation hardening' },
    [pscustomobject]@{ Title = 'Beta 2 - Update & Install Hardening'; Description = 'Package trust, atomic update, and installer reliability' },
    [pscustomobject]@{ Title = 'Beta 3 - Core Workflow Reliability'; Description = 'Project, PHP, TLS, and backup/restore reliability' },
    [pscustomobject]@{ Title = 'Beta RC - Release Hardening'; Description = 'Dashboard accuracy, diagnostics, docs, and regression freeze' }
)

$issues = @(
    New-IssueSpec -Title "BETA-001: Stabilize interactive process lifecycle" -MilestoneTitle "Beta 0 - Stabilization" -Labels @("beta", "priority:high", "kind:bug", "area:process", "risk:orphan-process") -Body @'
### Goal
Stabilize the interactive process lifecycle so start/stop sequences do not fail with invalid-handle errors or leave a worker process behind.

### Scope
- Fix ownership and shutdown of the interactive worker thread.
- Remove race conditions around `StartInteractive` and line sending.
- Keep failure reporting explicit to the caller.

### Acceptance criteria
- [ ] `TestStartInteractive_SendLine` passes reliably.
- [ ] Repeated start/stop cycles succeed in manual smoke testing.
- [ ] No orphan worker process remains after failure or shutdown.

### Depends on
- None
'@
    New-IssueSpec -Title "BETA-002: Make builds deterministic" -MilestoneTitle "Beta 0 - Stabilization" -Labels @("beta", "priority:medium", "kind:infra", "area:build") -Body @'
### Goal
Make builds deterministic so the same commit does not produce tracked file churn or environment-dependent output.

### Scope
- Stop timestamped or generated artifacts from landing as tracked diffs.
- Make generated files either reproducible or ignored by design.
- Keep build output stable across clean rebuilds.

### Acceptance criteria
- [ ] Two builds from the same commit do not create unintended tracked changes.
- [ ] A clean build succeeds from a fresh checkout.
- [ ] Build output is not dependent on local machine state.

### Depends on
- None
'@
    New-IssueSpec -Title "BETA-003: Add CI parity for the local test suite" -MilestoneTitle "Beta 0 - Stabilization" -Labels @("beta", "priority:high", "kind:infra", "area:ci") -Body @'
### Goal
Run the same meaningful test coverage in CI that we rely on locally.

### Scope
- Add unit, config, process, and smoke test execution to CI.
- Fail the pipeline on any test regression.
- Keep the CI command close to the local verification command.

### Acceptance criteria
- [ ] CI runs the core test suite on every change.
- [ ] A failing test blocks merge.
- [ ] Local and CI verification follow the same target behavior.

### Depends on
- BETA-002
'@
    New-IssueSpec -Title "BETA-010: Harden process ownership and cleanup" -MilestoneTitle "Beta 1 - Security & Safety" -Labels @("beta", "priority:high", "kind:hardening", "area:process", "risk:orphan-process") -Body @'
### Goal
Make process ownership and cleanup reliable so failed launches and shutdowns do not leave orphaned Apache or MariaDB processes behind.

### Scope
- Track the real child process ownership more robustly.
- Avoid PID-reuse mistakes when stopping processes.
- Clean up failed starts, shutdowns, and partial launches safely.

### Acceptance criteria
- [ ] Failed start or stop operations do not leave orphan processes behind.
- [ ] Cleanup only affects processes owned by the app.
- [ ] Manual start/stop smoke tests complete without stale process state.

### Depends on
- BETA-001
'@
    New-IssueSpec -Title "BETA-011: Remove plaintext secrets from temp scripts and logs" -MilestoneTitle "Beta 1 - Security & Safety" -Labels @("beta", "priority:high", "kind:hardening", "area:security", "risk:secret-leak") -Body @'
### Goal
Prevent credentials from being written in plaintext to temp scripts, logs, or command lines.

### Scope
- Stop embedding passwords directly into temporary helper scripts.
- Redact sensitive values from logs and error output.
- Delete transient credential artifacts after use.

### Acceptance criteria
- [ ] Generated helper files do not contain plaintext credentials.
- [ ] Logs do not expose secrets.
- [ ] Temporary secret-bearing files are removed after successful use.

### Depends on
- None
'@
    New-IssueSpec -Title "BETA-012: Enforce path containment and archive validation" -MilestoneTitle "Beta 1 - Security & Safety" -Labels @("beta", "priority:high", "kind:hardening", "area:security", "risk:data-loss") -Body @'
### Goal
Block path traversal and malicious archive content from escaping the intended extraction or restore root.

### Scope
- Reject `..` segments, absolute paths, and reserved-name escapes.
- Reject symlink and junction-based escapes.
- Validate archive entries before any write occurs.

### Acceptance criteria
- [ ] Malicious archives cannot write outside the target root.
- [ ] Invalid entries are rejected before extraction or restore.
- [ ] Collision and oversized-entry cases fail safely.

### Depends on
- None
'@
    New-IssueSpec -Title "BETA-013: Define secret export and portability behavior" -MilestoneTitle "Beta 1 - Security & Safety" -Labels @("beta", "priority:medium", "kind:hardening", "area:security", "risk:secret-leak") -Body @'
### Goal
Make secret storage behavior explicit when the app is moved or exported.

### Scope
- Decide whether secrets are portable or intentionally machine-bound.
- If export is supported, require explicit encrypted export/import.
- If export is not supported, fail with a clear migration message.

### Acceptance criteria
- [ ] Moving the app directory does not silently break secret lookup without explanation.
- [ ] Secret export/import behavior is documented and explicit.
- [ ] The user gets a clear recovery path when portability is unsupported.

### Depends on
- BETA-011
'@
    New-IssueSpec -Title "BETA-020: Verify package integrity and provenance" -MilestoneTitle "Beta 2 - Update & Install Hardening" -Labels @("beta", "priority:high", "kind:hardening", "area:update", "area:installer") -Body @'
### Goal
Verify update and install packages before extraction or promotion.

### Scope
- Validate manifest hashes before unpacking.
- Require trusted provenance for packages used by the updater.
- Stop install/update flows on any integrity mismatch.

### Acceptance criteria
- [ ] Hash or signature mismatch blocks installation.
- [ ] Verification happens before extraction or promotion.
- [ ] The result of verification is visible in logs or status output.

### Depends on
- BETA-002
- BETA-003
'@
    New-IssueSpec -Title "BETA-021: Make update promotion atomic with rollback" -MilestoneTitle "Beta 2 - Update & Install Hardening" -Labels @("beta", "priority:high", "kind:hardening", "area:update", "risk:data-loss") -Body @'
### Goal
Make updates promote atomically so a failed update never leaves the app half-updated.

### Scope
- Stage updates in an isolated location.
- Verify the staged result before switching over.
- Keep the previous working version available for rollback.

### Acceptance criteria
- [ ] Failed updates preserve the previous working version.
- [ ] Partial updates do not leave the app unusable.
- [ ] Recovery from a failed update is deterministic and documented.

### Depends on
- BETA-020
'@
    New-IssueSpec -Title "BETA-022: Make installer and admin-helper failures explicit" -MilestoneTitle "Beta 2 - Update & Install Hardening" -Labels @("beta", "priority:high", "kind:bug", "area:installer") -Body @'
### Goal
Surface elevation, filesystem, ACL, and registration failures clearly instead of reporting partial success.

### Scope
- Propagate the actual cause of installer/helper failure.
- Avoid success flags on partial completion.
- Keep installer state consistent after any failure.

### Acceptance criteria
- [ ] A failed installer action returns a clear error.
- [ ] The UI does not report success unless the action completed fully.
- [ ] Partial installation state is either cleaned up or clearly recoverable.

### Depends on
- BETA-020
'@
    New-IssueSpec -Title "BETA-030: Separate project delete from vhost and docroot removal" -MilestoneTitle "Beta 3 - Core Workflow Reliability" -Labels @("beta", "priority:high", "kind:bug", "area:project", "risk:data-loss") -Body @'
### Goal
Separate project deletion from document-root removal so data loss is explicit and intentional.

### Scope
- Split project delete, vhost delete, and docroot delete into distinct actions.
- Require explicit confirmation for destructive filesystem removal.
- Align UI wording with actual behavior.

### Acceptance criteria
- [ ] Deleting a project does not silently remove the docroot.
- [ ] Docroot removal requires explicit confirmation.
- [ ] The UI action labels match the real effect.

### Depends on
- BETA-012
'@
    New-IssueSpec -Title "BETA-031: Fix PHP version switching and restart behavior" -MilestoneTitle "Beta 3 - Core Workflow Reliability" -Labels @("beta", "priority:high", "kind:bug", "area:php") -Body @'
### Goal
Make PHP version switching actually take effect in the running stack.

### Scope
- Update the active PHP configuration when the user selects a version.
- Restart the required services after the switch.
- Refresh the dashboard so it reflects the active version.

### Acceptance criteria
- [ ] The selected PHP version is the active version after restart.
- [ ] Switching versions updates the running stack without manual repair.
- [ ] The dashboard reflects the real active PHP version.

### Depends on
- BETA-010
'@
    New-IssueSpec -Title "BETA-032: Harden TLS certificate generation and validation" -MilestoneTitle "Beta 3 - Core Workflow Reliability" -Labels @("beta", "priority:high", "kind:hardening", "area:tls") -Body @'
### Goal
Make TLS certificate setup reliable and fail fast when prerequisites or generation steps are missing.

### Scope
- Verify `mkcert` or OpenSSL success instead of assuming it.
- Ensure generated certs include the required SANs.
- Block completion on any cert-generation failure.

### Acceptance criteria
- [ ] TLS setup does not report success on partial failure.
- [ ] Generated certs are valid for the local hostnames used by the app.
- [ ] Missing prerequisites produce a clear failure message.

### Depends on
- BETA-012
'@
    New-IssueSpec -Title "BETA-033: Make backup and restore scoped and fail-fast" -MilestoneTitle "Beta 3 - Core Workflow Reliability" -Labels @("beta", "priority:high", "kind:bug", "area:backup", "risk:data-loss") -Body @'
### Goal
Make backup and restore operations safe, scoped, and easy to verify.

### Scope
- Return non-zero or explicit failure on backup errors.
- Restrict restore to the intended project or data set.
- Verify the operation result after import or restore.

### Acceptance criteria
- [ ] Failed backups are reported as failures.
- [ ] Restores cannot escape the intended scope.
- [ ] Successful restore is validated after completion.

### Depends on
- BETA-012
'@
    New-IssueSpec -Title "BETA-040: Improve dashboard service-state accuracy" -MilestoneTitle "Beta RC - Release Hardening" -Labels @("beta", "priority:medium", "kind:bug", "area:dashboard") -Body @'
### Goal
Make the dashboard reflect the real service and process state instead of stale or inferred state.

### Scope
- Recheck process identity instead of trusting cached PID state.
- Handle PID reuse and stale status correctly.
- Refresh after start, stop, failure, and restart transitions.

### Acceptance criteria
- [ ] Dashboard status matches reality after start/stop/failure.
- [ ] Stale healthy state is not shown after failure.
- [ ] Status updates are consistent after restarts.

### Depends on
- BETA-001
- BETA-010
- BETA-031
'@
    New-IssueSpec -Title "BETA-041: Improve diagnostics, logs, and supportability" -MilestoneTitle "Beta RC - Release Hardening" -Labels @("beta", "priority:medium", "kind:hardening", "area:security", "area:dashboard", "risk:secret-leak") -Body @'
### Goal
Make failures diagnosable without exposing secrets or requiring source-level debugging.

### Scope
- Add structured, operation-scoped error reporting.
- Redact secrets from logs and user-facing messages.
- Keep logs concise enough to support troubleshooting.

### Acceptance criteria
- [ ] A failed workflow can be diagnosed from logs alone.
- [ ] Sensitive values are redacted in logs and error surfaces.
- [ ] Error messages point to the actual failing operation.

### Depends on
- BETA-011
- BETA-022
'@
    New-IssueSpec -Title "BETA-042: Publish beta docs and supported-environment matrix" -MilestoneTitle "Beta RC - Release Hardening" -Labels @("beta", "priority:medium", "kind:docs", "area:docs") -Body @'
### Goal
Document exactly what the beta supports so installation and upgrades are predictable.

### Scope
- Document supported Windows versions and prerequisites.
- Document ports, recovery steps, and upgrade behavior.
- Document known beta limits and unsupported scenarios.

### Acceptance criteria
- [ ] Docs match the actual beta behavior.
- [ ] Fresh install and upgrade steps are documented.
- [ ] Supported environment and dependency versions are listed clearly.

### Depends on
- BETA-033
- BETA-040
'@
    New-IssueSpec -Title "BETA-043: Run clean-machine upgrade and regression freeze" -MilestoneTitle "Beta RC - Release Hardening" -Labels @("beta", "priority:high", "kind:release", "area:ci", "area:update") -Body @'
### Goal
Use a clean-machine validation pass to decide whether the beta is release-ready.

### Scope
- Run fresh install and upgrade tests on a clean VM.
- Fix only release-blocking issues during this phase.
- Freeze new feature work until beta criteria are met.

### Acceptance criteria
- [ ] Fresh install passes on a clean machine.
- [ ] Upgrade from the previous beta passes.
- [ ] Only non-blocking issues remain before tagging the beta.

### Depends on
- BETA-003
- BETA-021
- BETA-022
- BETA-030
- BETA-031
- BETA-032
- BETA-033
- BETA-040
- BETA-041
- BETA-042
'@
)

Assert-GhAvailable

$tempRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("uniwamp-beta-bootstrap-" + [guid]::NewGuid().ToString("N"))
New-Item -ItemType Directory -Path $tempRoot | Out-Null

try {
    foreach ($label in $labelSpecs) {
        [void](Get-OrCreateLabel -Repository $RepositoryFullName -Name $label.Name -Color $label.Color -Description $label.Description)
    }

    $milestoneMap = @{}
    foreach ($milestone in $milestoneSpecs) {
        $created = Get-OrCreateMilestone -Repository $RepositoryFullName -Title $milestone.Title -Description $milestone.Description
        $milestoneMap[$milestone.Title] = $created.number
    }

    foreach ($issue in $issues) {
        $safeName = ($issue.Title -replace '[^A-Za-z0-9]+', '-').Trim('-')
        $bodyPath = Join-Path $tempRoot ($safeName + ".md")
        Set-Content -LiteralPath $bodyPath -Value $issue.Body -Encoding utf8

        if ($DryRun) {
            Write-Host "[dry-run] gh issue create --repo $RepositoryFullName --title `"$($issue.Title)`" --milestone `"$($issue.MilestoneTitle)`""
            continue
        }

        if ($PSCmdlet.ShouldProcess($RepositoryFullName, "Create issue '$($issue.Title)'")) {
            $args = @(
                'issue', 'create',
                '--repo', $RepositoryFullName,
                '--title', $issue.Title,
                '--body-file', $bodyPath
            )

            foreach ($labelName in $issue.Labels) {
                $args += @('--label', $labelName)
            }
            $args += @('--milestone', $issue.MilestoneTitle)

            & gh @args
        }
    }
}
finally {
    if (Test-Path -LiteralPath $tempRoot) {
        Remove-Item -LiteralPath $tempRoot -Recurse -Force
    }
}
