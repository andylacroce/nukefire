if (-not (Test-Path telepath.log)) { New-Item telepath.log | Out-Null }
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

function Write-Entry($from, $to, $text) {
    Write-Host '(' -ForegroundColor DarkGray -NoNewline
    Write-Host $from -ForegroundColor (Get-NameColor $from) -NoNewline
    Write-Host '->' -ForegroundColor DarkGray -NoNewline
    Write-Host $to -ForegroundColor (Get-NameColor $to) -NoNewline
    Write-Host ') ' -ForegroundColor DarkGray -NoNewline
    Write-Host $text -ForegroundColor White
    Write-Host -NoNewline "`a"
}

Get-Content telepath.log -Wait -Tail 500 | ForEach-Object {
    if      ($_ -match '^\[[\d/]+ [\d:]+\] \[(\w+)\] You telepath (\w+), (.+)$')        { Write-Entry $Matches[1] $Matches[2] $Matches[3] }
    elseif  ($_ -match '^\[[\d/]+ [\d:]+\] \[(\w+)\] (\w+) telepaths to you, (.+)$')    { Write-Entry $Matches[2] $Matches[1] $Matches[3] }
}
