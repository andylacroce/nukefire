# all_watch.ps1 — Aggregated view of all channel logs with source indicator

$tailLines = 100
Clear-Host

$channels = [ordered]@{
    'gossip.log'    = @{ tag = 'GOS'; color = 'DarkYellow' }
    'auction.log'   = @{ tag = 'AUC'; color = 'Magenta'    }
    'telepath.log'  = @{ tag = 'TEL'; color = 'Cyan'       }
    'broadcast.log' = @{ tag = 'YAY'; color = 'Yellow'     }
    'group.log'     = @{ tag = 'GRP'; color = 'Green'      }
}

function Get-NameColor($name) {
    $known = @('mutiny','haenym','prodigy','rancor')
    if ($known -contains $name.ToLower()) { 'Cyan' } else { 'DarkGray' }
}

function Remove-Quotes($t) {
    $t = $t.Trim()
    if ($t.StartsWith("'") -and $t.EndsWith("'")) { $t.Substring(1, $t.Length - 2) } else { $t }
}

function Write-Tag($tag, $color) {
    Write-Host '[' -ForegroundColor DarkGray -NoNewline
    Write-Host $tag -ForegroundColor $color -NoNewline
    Write-Host '] ' -ForegroundColor DarkGray -NoNewline
}

function Write-Speaker($name) {
    Write-Host '(' -ForegroundColor DarkGray -NoNewline
    Write-Host $name -ForegroundColor (Get-NameColor $name) -NoNewline
    Write-Host ') ' -ForegroundColor DarkGray -NoNewline
}

function Write-ChannelLine($file, $line) {
    $def = $channels[$file]
    $tag = $def.tag; $color = $def.color

    if ($file -eq 'gossip.log') {
        if ($line -match '^\[[\d/]+ [\d:]+\] \[([^\]]+)\] You gossip, (.+)$') {
            Write-Tag $tag $color; Write-Speaker $Matches[1].Trim("'"); Write-Host (Remove-Quotes $Matches[2]) -ForegroundColor White; return
        }
        if ($line -match '^\[[\d/]+ [\d:]+\] (.+?) gossips, (.+)$') {
            Write-Tag $tag $color; Write-Speaker $Matches[1].Trim("'"); Write-Host (Remove-Quotes $Matches[2]) -ForegroundColor White; return
        }
    } elseif ($file -eq 'auction.log') {
        if ($line -match '^\[[\d/]+ [\d:]+\] \[([^\]]+)\] You auction, (.+)$') {
            Write-Tag $tag $color; Write-Speaker $Matches[1].Trim("'"); Write-Host (Remove-Quotes $Matches[2]) -ForegroundColor White; return
        }
        if ($line -match '^\[[\d/]+ [\d:]+\] (.+?) auctions, (.+)$') {
            Write-Tag $tag $color; Write-Speaker $Matches[1].Trim("'"); Write-Host (Remove-Quotes $Matches[2]) -ForegroundColor White; return
        }
    } elseif ($file -eq 'telepath.log') {
        if ($line -match '^\[[\d/]+ [\d:]+\] \[([^\]]+)\] You telepath ([^,]+), (.+)$') {
            $from = $Matches[1].Trim().Trim("'"); $to = $Matches[2].Trim().Trim("'"); $text = Remove-Quotes $Matches[3]
            Write-Tag $tag $color
            Write-Host '(' -ForegroundColor DarkGray -NoNewline
            Write-Host $from -ForegroundColor (Get-NameColor $from) -NoNewline
            Write-Host '->' -ForegroundColor DarkGray -NoNewline
            Write-Host $to -ForegroundColor (Get-NameColor $to) -NoNewline
            Write-Host ') ' -ForegroundColor DarkGray -NoNewline
            Write-Host $text -ForegroundColor White; return
        }
        if ($line -match '^\[[\d/]+ [\d:]+\] \[([^\]]+)\] ([^,]+) telepaths to you, (.+)$') {
            $from = $Matches[2].Trim().Trim("'"); $to = $Matches[1].Trim().Trim("'"); $text = Remove-Quotes $Matches[3]
            Write-Tag $tag $color
            Write-Host '(' -ForegroundColor DarkGray -NoNewline
            Write-Host $from -ForegroundColor (Get-NameColor $from) -NoNewline
            Write-Host '->' -ForegroundColor DarkGray -NoNewline
            Write-Host $to -ForegroundColor (Get-NameColor $to) -NoNewline
            Write-Host ') ' -ForegroundColor DarkGray -NoNewline
            Write-Host $text -ForegroundColor White; return
        }
    } elseif ($file -eq 'broadcast.log') {
        if ($line -match '^\[[\d/]+ [\d:]+\] \[GLORY\] (.+)$') {
            Write-Tag $tag $color; Write-Host '[GLORY] ' -ForegroundColor Yellow -NoNewline; Write-Host $Matches[1].Trim() -ForegroundColor White; return
        }
        if ($line -match '^\[[\d/]+ [\d:]+\] \[ NEW ITEM EVENT \] (.+)$') {
            Write-Tag $tag $color; Write-Host '[ NEW ITEM ] ' -ForegroundColor Green -NoNewline; Write-Host $Matches[1].Trim() -ForegroundColor White; return
        }
        if ($line -match '^\[[\d/]+ [\d:]+\] \[ DCC SYSTEM \] (.+)$') {
            Write-Tag $tag $color; Write-Host '[ DCC ] ' -ForegroundColor Red -NoNewline; Write-Host $Matches[1].Trim() -ForegroundColor White; return
        }
        if ($line -match '^\[[\d/]+ [\d:]+\] \[FACETED WORK\] (.+)$') {
            Write-Tag $tag $color; Write-Host '[FACETED] ' -ForegroundColor Magenta -NoNewline; Write-Host $Matches[1].Trim() -ForegroundColor White; return
        }
        if ($line -match '^\[[\d/]+ [\d:]+\] Skynet\(TM\) (.+)$') {
            Write-Tag $tag $color; Write-Host 'Skynet(TM) ' -ForegroundColor DarkYellow -NoNewline; Write-Host $Matches[1].Trim() -ForegroundColor White; return
        }
    } elseif ($file -eq 'group.log') {
        if ($line -match '^\[[\d/]+ [\d:]+\] \[([^\]]+)\] You group-say, (.+)$') {
            Write-Tag $tag $color; Write-Speaker $Matches[1].Trim("'"); Write-Host (Remove-Quotes $Matches[2]) -ForegroundColor White; return
        }
        if ($line -match '^\[[\d/]+ [\d:]+\] \[Group\] (.+?) says, (.+)$') {
            Write-Tag $tag $color; Write-Speaker $Matches[1].Trim("'"); Write-Host (Remove-Quotes $Matches[2]) -ForegroundColor White; return
        }
    }
}

# --- Initial tail: read recent lines from all files, sort by timestamp, display ---
$history = [System.Collections.Generic.List[hashtable]]::new()
foreach ($f in $channels.Keys) {
    if (-not (Test-Path $f)) { continue }
    foreach ($line in (Get-Content $f -Tail $tailLines -ErrorAction SilentlyContinue)) {
        if ($line -match '^\[(\d{1,2}/\d{1,2} \d{2}:\d{2})\]') {
            $history.Add(@{ file = $f; line = $line; ts = $Matches[1] })
        }
    }
}
foreach ($entry in ($history | Sort-Object { $_.ts })) {
    Write-ChannelLine $entry.file $entry.line
}

# --- Live polling: collect new lines from all files, sort by timestamp, display ---
$offsets = @{}
foreach ($f in $channels.Keys) {
    $offsets[$f] = if (Test-Path $f) { (Get-Item $f).Length } else { 0L }
}

while ($true) {
    $pending = [System.Collections.Generic.List[hashtable]]::new()

    foreach ($f in $channels.Keys) {
        if (-not (Test-Path $f)) { continue }
        $size = (Get-Item $f -ErrorAction SilentlyContinue).Length
        if ($null -eq $size) { continue }
        if ($size -lt $offsets[$f]) { $offsets[$f] = 0 }   # log was rotated/truncated
        if ($size -le $offsets[$f]) { continue }

        try {
            $stream = [System.IO.File]::Open($f, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::ReadWrite)
            $stream.Seek($offsets[$f], [System.IO.SeekOrigin]::Begin) | Out-Null
            $reader = [System.IO.StreamReader]::new($stream)
            while (-not $reader.EndOfStream) {
                $line = $reader.ReadLine()
                if (-not [string]::IsNullOrWhiteSpace($line)) {
                    $ts = if ($line -match '^\[(\d{1,2}/\d{1,2} \d{2}:\d{2})\]') { $Matches[1] } else { '' }
                    $pending.Add(@{ file = $f; line = $line; ts = $ts })
                }
            }
            $reader.Dispose()
            $stream.Dispose()
        } catch {}
        $offsets[$f] = $size
    }

    foreach ($entry in ($pending | Sort-Object { $_.ts })) {
        Write-ChannelLine $entry.file $entry.line
    }

    Start-Sleep -Milliseconds 200
}
