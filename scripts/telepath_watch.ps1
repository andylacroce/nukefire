New-Item -Force telepath.log | Out-Null
Clear-Host
Get-Content telepath.log -Wait -Tail 20 | ForEach-Object {
    if ($_ -match '^(\[\d+/\d+ \d+:\d+\] )(\[\w+\] )(You telepath )(.*?)(,\s+)(.*)$') {
        Write-Host $Matches[1] -ForegroundColor DarkGray -NoNewline
        Write-Host $Matches[2] -ForegroundColor Green    -NoNewline
        Write-Host $Matches[3] -ForegroundColor DarkGray -NoNewline
        Write-Host $Matches[4] -ForegroundColor Yellow   -NoNewline
        Write-Host $Matches[5] -ForegroundColor DarkGray -NoNewline
        Write-Host $Matches[6] -ForegroundColor White
    } elseif ($_ -match '^(\[\d+/\d+ \d+:\d+\] )(\[\w+\] )(.*?)( telepaths to you,\s+)(.*)$') {
        Write-Host $Matches[1] -ForegroundColor DarkGray -NoNewline
        Write-Host $Matches[2] -ForegroundColor Green    -NoNewline
        Write-Host $Matches[3] -ForegroundColor Cyan     -NoNewline
        Write-Host $Matches[4] -ForegroundColor DarkGray -NoNewline
        Write-Host $Matches[5] -ForegroundColor White
    } else {
        Write-Host $_
    }
    Write-Host -NoNewline "`a"
}
