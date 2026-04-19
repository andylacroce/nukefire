New-Item -Force auction.log | Out-Null
Clear-Host
Get-Content auction.log -Wait -Tail 20 | ForEach-Object {
    if ($_ -match '^(\[\d+/\d+ \d+:\d+\] )(You auction,\s+)(.*)$') {
        Write-Host $Matches[1] -ForegroundColor DarkGray -NoNewline
        Write-Host $Matches[2] -ForegroundColor DarkGray -NoNewline
        Write-Host $Matches[3] -ForegroundColor White
    } elseif ($_ -match '^(\[\d+/\d+ \d+:\d+\] )(.*?)(\s+auctions,\s+)(.*)$') {
        Write-Host $Matches[1] -ForegroundColor DarkGray -NoNewline
        Write-Host $Matches[2] -ForegroundColor Yellow   -NoNewline
        Write-Host $Matches[3] -ForegroundColor DarkGray -NoNewline
        Write-Host $Matches[4] -ForegroundColor White
    } else {
        Write-Host $_
    }
    Write-Host -NoNewline "`a"
}
