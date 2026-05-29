if (-not (Test-Path broadcast.log)) { New-Item broadcast.log | Out-Null }
Clear-Host

Get-Content broadcast.log -Wait -Tail 500 | ForEach-Object {
    $line = $_
    if ($line -match '^\[[\d/]+ [\d:]+\] \[GLORY\] (.+)$') {
        $msg = $Matches[1].Trim()
        Write-Host '[GLORY] ' -ForegroundColor Yellow -NoNewline
        Write-Host $msg -ForegroundColor White
        Write-Host -NoNewline "`a"
    } elseif ($line -match '^\[[\d/]+ [\d:]+\] \[FACETED WORK\] (.+)$') {
        $msg = $Matches[1].Trim()
        Write-Host '[FACETED WORK] ' -ForegroundColor Magenta -NoNewline
        Write-Host $msg -ForegroundColor White
        Write-Host -NoNewline "`a"
    } elseif ($line -match '^\[[\d/]+ [\d:]+\] \[ NEW ITEM EVENT \] (.+)$') {
        $msg = $Matches[1].Trim()
        Write-Host '[ NEW ITEM EVENT ] ' -ForegroundColor Green -NoNewline
        Write-Host $msg -ForegroundColor White
        Write-Host -NoNewline "`a"
    } elseif ($line -match '^\[[\d/]+ [\d:]+\] \[ DCC SYSTEM \] (.+)$') {
        $msg = $Matches[1].Trim()
        Write-Host '[ DCC SYSTEM ] ' -ForegroundColor Red -NoNewline
        Write-Host $msg -ForegroundColor White
        Write-Host -NoNewline "`a"
    } elseif ($line -match '^\[[\d/]+ [\d:]+\] \[ NUKEFIRE MUDVAULT \] (.+)$') {
        $msg = $Matches[1].Trim()
        Write-Host '[ NUKEFIRE MUDVAULT ] ' -ForegroundColor Cyan -NoNewline
        Write-Host $msg -ForegroundColor White
        Write-Host -NoNewline "`a"
    } elseif ($line -match '^\[[\d/]+ [\d:]+\] Skynet\(TM\) (.+)$') {
        $msg = $Matches[1].Trim()
        Write-Host 'Skynet(TM) ' -ForegroundColor DarkYellow -NoNewline
        Write-Host $msg -ForegroundColor White
        Write-Host -NoNewline "`a"
    }
}
