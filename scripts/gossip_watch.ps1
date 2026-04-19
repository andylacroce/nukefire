if (-not (Test-Path gossip.log)) { New-Item gossip.log | Out-Null }
Clear-Host
$tailLines = 500
Get-Content gossip.log -Wait -Tail $tailLines | ForEach-Object {
    if ($_ -match '^(\[\d+/\d+ \d+:\d+\] )(You gossip,\s+)(.*)$') {
        Write-Host $Matches[1] -ForegroundColor DarkGray -NoNewline
        Write-Host $Matches[2] -ForegroundColor DarkGray -NoNewline
        Write-Host $Matches[3] -ForegroundColor White
    } elseif ($_ -match '^(\[\d+/\d+ \d+:\d+\] )(.*?)(\s+gossips,\s+)(.*)$') {
        Write-Host $Matches[1] -ForegroundColor DarkGray -NoNewline
        Write-Host $Matches[2] -ForegroundColor Cyan     -NoNewline
        Write-Host $Matches[3] -ForegroundColor DarkGray -NoNewline
        Write-Host $Matches[4] -ForegroundColor White
    } else {
        Write-Host $_
    }
    Write-Host -NoNewline "`a"
}
