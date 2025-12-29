<#
Runs the same lint checks locally as CI. Exits non-zero when any check fails.
Usage: powershell -ExecutionPolicy Bypass -File .\scripts\run_ci_linters.ps1
#>

$ErrorActionPreference = 'Stop'

Write-Host "Running markdown linter (npx markdownlint-cli README.md CONTRIBUTING.md)..." -ForegroundColor Cyan
$mdExit = 0
try {
    npx markdownlint-cli README.md CONTRIBUTING.md
} catch {
    $mdExit = 1
}

Write-Host "Running Tintin headers linter (scripts/check_tin_headers.ps1)..." -ForegroundColor Cyan
$tinExit = 0
try {
    powershell -NoProfile -NonInteractive -ExecutionPolicy Bypass -File .\scripts\check_tin_headers.ps1
} catch {
    $tinExit = 1
}

if ($mdExit -ne 0 -or $tinExit -ne 0) {
    Write-Host "One or more linters failed." -ForegroundColor Red
    exit 1
}

Write-Host "All linters passed." -ForegroundColor Green
exit 0