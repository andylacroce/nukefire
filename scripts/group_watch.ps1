if (-not (Test-Path group.log)) { New-Item group.log | Out-Null }
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

function Write-Entry($name, $text) {
    Write-Host '(' -ForegroundColor DarkGray -NoNewline
    Write-Host $name -ForegroundColor (Get-NameColor $name) -NoNewline
    Write-Host ') ' -ForegroundColor DarkGray -NoNewline
    Write-Host $text -ForegroundColor White
    Write-Host -NoNewline "`a"
}

Get-Content group.log -Wait -Tail 500 | ForEach-Object {
    $line = $_
    if ($line -match '^\[[\d/]+ [\d:]+\] \[([^\]]+)\] You group-say, (.+)$') {
        $name = $Matches[1].Trim().Trim("'")
        $text = $Matches[2].Trim()
        if ($text.StartsWith("'") -and $text.EndsWith("'")) { $text = $text.Substring(1, $text.Length - 2) }
        Write-Entry $name $text
    } elseif ($line -match '^\[[\d/]+ [\d:]+\] \[Group\] (.+?) says, (.+)$') {
        $name = $Matches[1].Trim().Trim("'")
        $text = $Matches[2].Trim()
        if ($text.StartsWith("'") -and $text.EndsWith("'")) { $text = $text.Substring(1, $text.Length - 2) }
        Write-Entry $name $text
    }
}
