param(
    [string]$Source = "C:\Users\sekip\Desktop\ScrubBots Gorselleri",
    [string]$Destination = "assets\art\references\_owner_inbox"
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path -LiteralPath $Source)) {
    throw "Owner visual reference source not found: $Source"
}

New-Item -ItemType Directory -Force -Path $Destination | Out-Null

$allowed = @('.png', '.jpg', '.jpeg', '.webp')
$files = Get-ChildItem -LiteralPath $Source -Recurse -File | Where-Object {
    $allowed -contains $_.Extension.ToLowerInvariant()
}

if ($files.Count -eq 0) {
    Write-Host "No supported image files found in $Source"
    exit 0
}

$copied = 0
$skipped = 0

foreach ($file in $files) {
    $relativePath = $file.FullName.Substring($Source.Length).TrimStart('\', '/')
    $target = Join-Path $Destination $relativePath
    $targetDir = Split-Path $target -Parent

    if (-not (Test-Path -LiteralPath $targetDir)) {
        New-Item -ItemType Directory -Force -Path $targetDir | Out-Null
    }

    if (Test-Path -LiteralPath $target) {
        $sourceHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $file.FullName).Hash
        $targetHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $target).Hash
        if ($sourceHash -eq $targetHash) {
            Write-Host "UNCHANGED: $relativePath"
            $skipped++
            continue
        }

        throw "Refusing to overwrite different existing reference file: $target"
    }

    Copy-Item -LiteralPath $file.FullName -Destination $target
    Write-Host "COPIED: $relativePath"
    $copied++
}

Write-Host "Reference intake complete. copied=$copied unchanged=$skipped"
Write-Host "Source originals were not modified or deleted."
Write-Host "Next: inventory/classify files before promoting any image to production use."
