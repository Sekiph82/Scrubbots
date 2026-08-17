<#
.SYNOPSIS
    Runs the SCRUBBOTS project in Godot headless mode for a quick smoke test.

.DESCRIPTION
    Locates a Godot 4.7 executable (PATH, or $env:SCRUBBOTS_GODOT) and runs
    the project headlessly, printing engine output. Useful to catch parse
    errors and main-scene load failures from the command line without
    opening the editor.
#>

$ErrorActionPreference = "Stop"
$projectRoot = Split-Path -Parent $PSScriptRoot

$godotExe = $null
foreach ($name in @("godot4", "godot")) {
    $cmd = Get-Command $name -ErrorAction SilentlyContinue
    if ($cmd) { $godotExe = $cmd.Source; break }
}
if (-not $godotExe -and $env:SCRUBBOTS_GODOT -and (Test-Path $env:SCRUBBOTS_GODOT)) {
    $godotExe = $env:SCRUBBOTS_GODOT
}

if (-not $godotExe) {
    Write-Host "No Godot 4.7 executable found." -ForegroundColor Red
    Write-Host "Install Godot 4.7, then either:" -ForegroundColor Yellow
    Write-Host "  - add it to PATH as 'godot4' (or 'godot'), or" -ForegroundColor Yellow
    Write-Host "  - set `$env:SCRUBBOTS_GODOT = 'C:\path\to\Godot_v4.7-stable_win64.exe'" -ForegroundColor Yellow
    exit 1
}

Write-Host "Using Godot: $godotExe"
Write-Host "Project: $projectRoot`n"

& $godotExe --headless --path $projectRoot
exit $LASTEXITCODE
