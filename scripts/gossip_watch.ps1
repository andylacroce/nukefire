if (-not (Test-Path gossip.log)) { New-Item gossip.log | Out-Null }
Clear-Host

function Get-NameColor($name) {
    switch ($name.ToLower()) {
        'mutiny'  { 'Red'     }
        'haenym'  { 'Cyan'    }
        'prodigy' { 'Green'   }
        'rancor'  { 'Magenta' }
        default   { 'Gray'    }
    }
}

function Write-Entry($name, $text) {
    Write-Host '(' -ForegroundColor DarkGray -NoNewline
    Write-Host $name -ForegroundColor (Get-NameColor $name) -NoNewline
    Write-Host ') ' -ForegroundColor DarkGray -NoNewline
    Write-Host $text -ForegroundColor White
    Write-Host -NoNewline "`a"
}

Get-Content gossip.log -Wait -Tail 500 | ForEach-Object {
    if      ($_ -match '^\[[\d/]+ [\d:]+\] \[(\w+)\] You gossip, (.+)$') { Write-Entry $Matches[1] $Matches[2] }
    elseif  ($_ -match '^\[[\d/]+ [\d:]+\] (\w+) gossips, (.+)$')        { Write-Entry $Matches[1] $Matches[2] }
}
