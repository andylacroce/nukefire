. "$PSScriptRoot/broadcast_config.ps1"
if (-not (Test-Path broadcast.log)) { New-Item broadcast.log | Out-Null }
Clear-Host

Get-Content broadcast.log -Wait -Tail 500 | ForEach-Object {
    if ($_ -match '^\[[\d/]+ [\d:]+\] (.+)$') {
        Write-BroadcastContent $Matches[1]
        Write-Host -NoNewline "`a"
    }
}
