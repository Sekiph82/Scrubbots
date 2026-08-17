<#
.SYNOPSIS
    Static + (if possible) live verification of the SCRUBBOTS Godot project.

.DESCRIPTION
    Checks that project.godot and the main scene exist, then tries to locate
    a Godot 4.7 executable to run an import/parse pass in headless mode.
    Never hardcodes a machine-specific Godot path unless found and reported.
#>

$ErrorActionPreference = "Stop"
$projectRoot = Split-Path -Parent $PSScriptRoot
$exitCode = 0

function Write-Check($ok, $message) {
    if ($ok) {
        Write-Host "[OK]   $message" -ForegroundColor Green
    } else {
        Write-Host "[FAIL] $message" -ForegroundColor Red
        $script:exitCode = 1
    }
}

Write-Host "SCRUBBOTS project verification" -ForegroundColor Cyan
Write-Host "Project root: $projectRoot`n"

# 1. project.godot exists
$projectFile = Join-Path $projectRoot "project.godot"
Write-Check (Test-Path $projectFile) "project.godot exists"

# 2. main scene referenced in project.godot exists
if (Test-Path $projectFile) {
    $content = Get-Content $projectFile -Raw
    if ($content -match 'run/main_scene="res://([^"]+)"') {
        $mainSceneRel = $Matches[1]
        $mainScenePath = Join-Path $projectRoot $mainSceneRel
        Write-Check (Test-Path $mainScenePath) "main scene ($mainSceneRel) exists"
    } else {
        Write-Check $false "run/main_scene not set in project.godot"
    }
}

# 3. main script referenced by the scene exists
$mainScript = Join-Path $projectRoot "scripts\app\main.gd"
Write-Check (Test-Path $mainScript) "scripts\app\main.gd exists"

# 4. attempt to locate a Godot 4.7 executable
$godotExe = $null
$candidates = @("godot4", "godot")
foreach ($name in $candidates) {
    $cmd = Get-Command $name -ErrorAction SilentlyContinue
    if ($cmd) { $godotExe = $cmd.Source; break }
}

if (-not $godotExe) {
    Write-Host "[INFO] No Godot executable found in PATH (checked: $($candidates -join ', '))." -ForegroundColor Yellow
    Write-Host "       Static checks only. To enable live checks: install Godot 4.7," -ForegroundColor Yellow
    Write-Host "       then either add it to PATH as 'godot4' or set `$env:SCRUBBOTS_GODOT` to its full path." -ForegroundColor Yellow
    if ($env:SCRUBBOTS_GODOT -and (Test-Path $env:SCRUBBOTS_GODOT)) {
        $godotExe = $env:SCRUBBOTS_GODOT
        Write-Host "[INFO] Using `$env:SCRUBBOTS_GODOT = $godotExe" -ForegroundColor Yellow
    }
}

if ($godotExe) {
    Write-Host "`nFound Godot executable: $godotExe"
    Write-Host "Running headless import/quit pass..."
    & $godotExe --headless --path $projectRoot --quit 2>&1 | Tee-Object -Variable godotOutput | Out-Host
    $hadError = ($godotOutput -join "`n") -match "(?i)error|failed to load"
    Write-Check (-not $hadError) "headless Godot run produced no error/failed-to-load output"
} else {
    Write-Host "`n[SKIP] Live Godot headless check skipped (no executable found)." -ForegroundColor Yellow
}

Write-Host "`nDone. Exit code: $exitCode"
exit $exitCode
