if (-not (Test-Path telepath.log)) { New-Item telepath.log | Out-Null }
Clear-Host

function Get-NameColor($name) {
    switch ($name.ToLower()) {
        'mutiny'  { 'Cyan'    }
        'haenym'  { 'Cyan'    }
        'prodigy' { 'Cyan'    }
        'rancor'  { 'Cyan'    }
        default   { 'DarkGray' }
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
    $line = $_
    if ($line -match '^\[[\d/]+ [\d:]+\] \[([^\]]+)\] You telepath ([^,]+), (.+)$') {
        $from = $Matches[1].Trim().Trim("'")
        $to   = $Matches[2].Trim().Trim("'")
        $text = $Matches[3].Trim()
        if ($text.StartsWith("'") -and $text.EndsWith("'")) { $text = $text.Substring(1, $text.Length - 2) }
        Write-Entry $from $to $text
    } elseif ($line -match '^\[[\d/]+ [\d:]+\] \[([^\]]+)\] ([^,]+) telepaths to you, (.+)$') {
        $from = $Matches[2].Trim().Trim("'")
        $to   = $Matches[1].Trim().Trim("'")
        $text = $Matches[3].Trim()
        if ($text.StartsWith("'") -and $text.EndsWith("'")) { $text = $text.Substring(1, $text.Length - 2) }
        Write-Entry $from $to $text
    }
}
