# Simple linter for Nukefire .tin files
# Usage: powershell -ExecutionPolicy Bypass -File .\scripts\check_tin_headers.ps1

$root = Split-Path -Parent $MyInvocation.MyCommand.Definition
$pattern = "*.tin"

$files = Get-ChildItem -Path $root -Recurse -Include $pattern | Where-Object { $_.FullName -notmatch "\\.git\\" }
$warnings = @()

foreach ($f in $files) {
    $content = Get-Content $f.FullName -ErrorAction SilentlyContinue
    if (-not $content) { continue }

    $first10 = $content | Select-Object -First 10 -Join "`n"
    $hasTopHeader = $first10 -match "^#nop\s+=+"
    $hasSections = ($content -match "#nop\s+-{2,}") -or ($content -match "#nop\s+------------------")

    if (-not $hasTopHeader) {
        $warnings += "MISSING TOP HEADER: $($f.FullName)"
    }
    if (-not $hasSections) {
        $warnings += "MISSING SECTION SEPARATOR: $($f.FullName)"
    }
}

if ($warnings.Count -gt 0) {
    Write-Host "Lint found issues in .tin files:" -ForegroundColor Yellow
    foreach ($w in $warnings) { Write-Host " - $w" }
    exit 1
} else {
    Write-Host "All .tin files have headers and sections." -ForegroundColor Green
    exit 0
}