<#
.SYNOPSIS
    Copies the canonical AGENTS_MASTER.md, plus the CI check that protects it
    (.github/workflows/governance-copy.yml), into every project listed in projects.txt.

.DESCRIPTION
    Each copy gets a first-line header with the governance commit and the SHA-256 of the
    body, so CI can detect hand edits (in the project) and drift (in this repository).
    The script only writes files: review, commit and push each project yourself.

.PARAMETER ProjectsRoot
    Folder that contains the project checkouts. Default: the parent folder of this repository.

.PARAMETER Check
    Report only; exit code 1 if any copy is missing, edited by hand or out of date.

.EXAMPLE
    .\sync-governance.ps1
    .\sync-governance.ps1 -Check
    .\sync-governance.ps1 -ProjectsRoot C:\Users\me\Documents\GitHub
#>
[CmdletBinding()]
param(
    [string]$ProjectsRoot,
    [switch]$Check
)

$ErrorActionPreference = "Stop"
if (-not $ProjectsRoot) { $ProjectsRoot = Split-Path $PSScriptRoot -Parent }
$Utf8NoBom = New-Object System.Text.UTF8Encoding($false)
$HashPattern = 'body-sha256:([0-9a-f]{64})'

function Get-Sha256Hex([string]$Text) {
    $sha = [System.Security.Cryptography.SHA256]::Create()
    try {
        $bytes = $sha.ComputeHash($Utf8NoBom.GetBytes($Text))
        return -join ($bytes | ForEach-Object { $_.ToString("x2") })
    }
    finally { $sha.Dispose() }
}

function Read-Normalized([string]$Path) {
    return [System.IO.File]::ReadAllText($Path, $Utf8NoBom).Replace("`r", "")
}

$master = Read-Normalized (Join-Path $PSScriptRoot "AGENTS_MASTER.md")
$masterHash = Get-Sha256Hex $master
$workflow = Read-Normalized (Join-Path $PSScriptRoot "project-check.yml")
$projects = Get-Content (Join-Path $PSScriptRoot "projects.txt") | Where-Object { $_.Trim() -ne "" }

if (-not $Check) {
    $dirty = git -C $PSScriptRoot status --porcelain -- AGENTS_MASTER.md
    if ($dirty) { throw "AGENTS_MASTER.md has uncommitted changes in governance: commit it first." }
}
$commit = (git -C $PSScriptRoot rev-parse --short HEAD).Trim()
$header = "<!-- GENERATED FROM pierluigiavvanzo-creator/governance-AGENTS_MASTER.md@$commit | body-sha256:$masterHash | DO NOT EDIT HERE: edit AGENTS_MASTER.md in pierluigiavvanzo-creator/governance-AGENTS_MASTER.md and run sync-governance.ps1 -->"

$problems = 0
foreach ($name in $projects) {
    $projectDir = Join-Path $ProjectsRoot $name.Trim()
    $target = Join-Path $projectDir "AGENTS_MASTER.md"
    if (-not (Test-Path $projectDir)) {
        Write-Warning "${name}: folder not found ($projectDir)"
        $problems++
        continue
    }

    if ($Check) {
        if (-not (Test-Path $target)) { Write-Host "MISSING  $name"; $problems++; continue }
        $copy = Read-Normalized $target
        $newline = $copy.IndexOf("`n")
        $first = if ($newline -ge 0) { $copy.Substring(0, $newline) } else { $copy }
        $body = if ($newline -ge 0) { $copy.Substring($newline + 1) } else { "" }
        $declared = if ($first -match $HashPattern) { $Matches[1] } else { $null }
        if (-not $declared) { Write-Host "NO-HEADER $name"; $problems++ }
        elseif ((Get-Sha256Hex $body) -ne $declared) { Write-Host "EDITED   $name (body changed by hand)"; $problems++ }
        elseif ($declared -ne $masterHash) { Write-Host "OUTDATED $name"; $problems++ }
        else { Write-Host "OK       $name" }
        continue
    }

    [System.IO.File]::WriteAllText($target, "$header`n$master", $Utf8NoBom)
    $workflowDir = Join-Path $projectDir ".github\workflows"
    New-Item -ItemType Directory -Force $workflowDir | Out-Null
    [System.IO.File]::WriteAllText((Join-Path $workflowDir "governance-copy.yml"), $workflow, $Utf8NoBom)
    Write-Host "SYNCED   $name"
}

if ($Check) {
    if ($problems -gt 0) { Write-Host "$problems problem(s). Run .\sync-governance.ps1 to fix."; exit 1 }
    Write-Host "All copies match governance@$commit."
}
else {
    Write-Host "Done. In each project: review 'git diff AGENTS_MASTER.md', then commit and push."
}
