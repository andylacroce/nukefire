if (-not (Test-Path broadcast.log)) { New-Item broadcast.log | Out-Null }
Clear-Host

Get-Content broadcast.log -Wait -Tail 500 | ForEach-Object {
    $line = $_
    if ($line -match '^\[[\d/]+ [\d:]+\] \(Skynet\) (.+)$') {
        $msg = $Matches[1].Trim()
        Write-Host '(Skynet) ' -ForegroundColor Cyan -NoNewline
        Write-Host $msg -ForegroundColor White
        Write-Host -NoNewline "`a"
    } elseif ($line -match '^\[[\d/]+ [\d:]+\] \[GLORY\] (.+)$') {
        $msg = $Matches[1].Trim()
        Write-Host '[GLORY] ' -ForegroundColor Yellow -NoNewline
        Write-Host $msg -ForegroundColor White
        Write-Host -NoNewline "`a"
    }
}
