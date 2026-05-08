[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$ESC   = [char]27
Write-Host "$ESC[?1049h" -NoNewline  # switch to alternate screen buffer — no scrollback history
Clear-Host
$RESET  = "$ESC[0m"
$CLEAR  = "$ESC[2J$ESC[H"   # erase screen + home cursor
$HIDE   = "$ESC[?25l"       # hide cursor during redraws to prevent flicker
$SHOW   = "$ESC[?25h"       # restore cursor

$COLOR = @{
    '@'     = "$ESC[93m"   # bright yellow  – you
    '■'     = "$ESC[96m"   # bright cyan    – room
    '*'     = "$ESC[92m"   # bright green   – gps
    'X'     = "$ESC[91m"   # bright red     – dest
    '!'     = "$ESC[91m"   # bright red     – locked
    '='     = "$ESC[33m"   # dark yellow    – closed
    ':'     = "$ESC[33m"   # dark yellow    – closed
    '/'     = "$ESC[33m"   # dark yellow    – closed
    '|'     = "$ESC[90m"   # dark gray      – link
    '-'     = "$ESC[90m"   # dark gray      – link / gps-line
    '^'     = "$ESC[90m"   # dark gray      – no-link-back
    'v'     = "$ESC[90m"   # dark gray      – no-link-back
    '<'     = "$ESC[90m"   # dark gray      – no-link-back
    '>'     = "$ESC[90m"   # dark gray      – no-link-back
}
$GRAY   = "$ESC[37m"
$CYAN   = "$ESC[96m"
$DGRAY  = "$ESC[90m"
$DCYAN  = "$ESC[36m"

function Format-MapLine($line) {
    $sb = [System.Text.StringBuilder]::new()
    foreach ($ch in $line.ToCharArray()) {
        $c = $COLOR["$ch"]
        if ($c) { [void]$sb.Append("$c$ch$RESET") }
        else    { [void]$sb.Append("$GRAY$ch$RESET") }
    }
    return $sb.ToString()
}

function Format-ColorMap($lines) {
    $out = [System.Text.StringBuilder]::new()
    [void]$out.Append($CLEAR)
    foreach ($line in $lines) {
        if ($line -match '^\[ BIGMAP \](.*)$') {
            [void]$out.AppendLine("$CYAN[ BIGMAP ]$RESET$DGRAY$($Matches[1])$RESET")
        } elseif ($line -match '^Route:') {
            [void]$out.AppendLine("$DGRAY$line$RESET")
        } elseif ($line -match '<--\s*(Up|Down) Here\s*-->') {
            [void]$out.AppendLine("$DCYAN$line$RESET")
        } else {
            [void]$out.AppendLine((Format-MapLine $line))
        }
    }
    return $out.ToString()
}

function Get-NameColor($name) {
    switch ($name.ToLower()) {
        'mutiny'  { 'Cyan' }
        'haenym'  { 'Cyan' }
        'prodigy' { 'Cyan' }
        'rancor'  { 'Cyan' }
        default   { 'DarkGray' }
    }
}

function New-LogCache {
    param([string]$Path)

    return @{
        Path     = $Path
        Position = 0L
        Length   = 0L
        Exists   = $false
    }
}

$script:charCaches    = @{}   # charName -> { Path, Position, Length, Exists, pE }
$script:expCache      = New-LogCache "exp.log"
$script:groupLines    = [System.Collections.Generic.List[string]]::new()
$script:enemyLines    = [System.Collections.Generic.List[string]]::new()
$script:pendingRedraw = $false
$script:expMap        = @{}
$script:remortMap     = @{}   # charName (lowercase) -> class_remorts string

function Update-LogCache {
    param(
        [hashtable]$Cache,
        [scriptblock]$OnLine
    )

    $path = $Cache.Path
    $fi = Get-Item $path -ErrorAction SilentlyContinue
    if (-not $fi) {
        $Cache.Exists   = $false
        $Cache.Position = 0L
        $Cache.Length   = 0L
        return
    }

    $len = [long]$fi.Length
    if (-not $Cache.Exists -or $len -lt $Cache.Length) {
        $Cache.Position = 0L
    }

    if ($len -le $Cache.Position) {
        $Cache.Exists = $true
        $Cache.Length = $len
        return
    }

    try {
        $stream = [System.IO.File]::Open($path, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::ReadWrite)
        $stream.Seek($Cache.Position, [System.IO.SeekOrigin]::Begin) | Out-Null
        $rdr = [System.IO.StreamReader]::new($stream, [System.Text.Encoding]::UTF8)
        $line = $rdr.ReadLine()
        while ($null -ne $line) {
            & $OnLine $line
            $line = $rdr.ReadLine()
        }
        $Cache.Position = $stream.Position
        $Cache.Length   = $len
        $Cache.Exists   = $true
        $rdr.Close()
    } catch {
        return
    }
}

function Update-AllCharCaches {
    # Each stats_<Name>.log is written by exactly one TinTin++ process — no concurrent writes.
    $files = Get-ChildItem "stats_*.log" -ErrorAction SilentlyContinue
    if (-not $files) { return }
    foreach ($f in $files) {
        $charName = $f.BaseName -replace '^stats_', ''
        if (-not $script:charCaches.ContainsKey($charName)) {
            $script:charCaches[$charName] = @{ Path=$f.FullName; Position=0L; Length=0L; Exists=$false; pE=$false }
        }
        $cs  = $script:charCaches[$charName]
        $fi  = Get-Item $cs.Path -ErrorAction SilentlyContinue
        if (-not $fi) { $cs.Exists=$false; $cs.Position=0L; $cs.Length=0L; continue }
        $len = [long]$fi.Length
        if (-not $cs.Exists -or $len -lt $cs.Length) { $cs.Position = 0L }
        if ($len -le $cs.Position) { $cs.Exists=$true; $cs.Length=$len; continue }
        try {
            $stream = [System.IO.File]::Open($cs.Path, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::ReadWrite)
            $stream.Seek($cs.Position, [System.IO.SeekOrigin]::Begin) | Out-Null
            $rdr  = [System.IO.StreamReader]::new($stream, [System.Text.Encoding]::UTF8)
            $line = $rdr.ReadLine()
            while ($null -ne $line) {
                if ($line -eq '+++') {
                    $script:pendingRedraw = $true
                } elseif ($line -eq '---') {
                    $script:groupLines.Clear()
                    $cs.pE = $false
                } elseif ($line -eq '~~~') {
                    $cs.pE = $true
                    $script:enemyLines.Clear()
                } elseif (-not [string]::IsNullOrWhiteSpace($line)) {
                    if ($cs.pE) { $script:enemyLines.Add($line) }
                    else        { $script:groupLines.Add($line) }
                }
                $line = $rdr.ReadLine()
            }
            $cs.Position = $stream.Position; $cs.Length = $len; $cs.Exists = $true
            $rdr.Close()
        } catch { }
    }
}

function Read-GroupStats {
    Update-AllCharCaches
    if ($script:groupLines.Count -eq 0) { return @() }

    $seen    = @{}
    $ordered = [System.Collections.Generic.List[string]]::new()
    for ($i = $script:groupLines.Count - 1; $i -ge 0; $i--) {
        $p = $script:groupLines[$i] -split '\|'
        if ($p.Count -ge 2 -and -not $seen.ContainsKey($p[1])) {
            $seen[$p[1]] = $true
            $ordered.Insert(0, $script:groupLines[$i])
        }
    }
    return $ordered.ToArray()
}

function Read-EnemyStats {
    $result = [System.Collections.Generic.List[string]]::new()
    foreach ($line in $script:enemyLines) {
        $p = $line -split '\|'
        if ($p.Count -lt 5) { continue }
        $result.Add("$($p[1])|$($p[2])|$($p[3])|$($p[4])")
    }
    return $result.ToArray()
}

function Format-Tnl($tnl) {
    try {
        if ($tnl -match 'Ready to Remort') { return 'Remort' }
        # Strip optional label e.g. "EXP to Remort: 153,681,730"
        $val = if ($tnl -match ':\s*([\d,]+)\s*$') { $Matches[1] } else { $tnl }
        $n = [double]($val -replace ',', '')
        if ($n -ge 1e9) { return "{0:0.0}b" -f ($n / 1e9) }
        if ($n -ge 1e6) { return "{0:0}m"   -f ($n / 1e6) }
        if ($n -ge 1e3) { return "{0:0}k"   -f ($n / 1e3) }
        return "$n"
    } catch { return $tnl }
}

function Update-ExpCache {
    Update-LogCache -Cache $script:expCache -OnLine {
        param([string]$line)

        $p = $line -split '\|', 2
        if ($p.Count -eq 2) {
            $script:expMap[$p[0]] = $p[1]
        }
    }
}

function Read-ExpToLevel {
    Update-ExpCache
    return $script:expMap
}

function Update-RemortCaches {
    $files = Get-ChildItem "remorts_*.log" -ErrorAction SilentlyContinue
    if (-not $files) { return }
    foreach ($f in $files) {
        $charName = ($f.BaseName -replace '^remorts_', '').ToLower()
        $last = Get-Content $f.FullName -Tail 1 -ErrorAction SilentlyContinue
        if ($last) { $script:remortMap[$charName] = $last }
    }
}

function Get-CharRemorts($name) {
    $raw = $script:remortMap[$name.ToLower()]
    if (-not $raw) { return '' }
    $parts = [System.Collections.Generic.List[string]]::new()
    foreach ($pair in @('GYP', 'WLF', 'HEA', 'HRT')) {
        if ($raw -match "$pair`:(\d+)" -and [int]$Matches[1] -gt 0) {
            $parts.Add("$pair`:$($Matches[1])")
        }
    }
    return $parts -join ' '
}

function Get-StatAnsi($cur, $max) {
    try {
        $m = [double]$max
        if ($m -gt 0 -and [double]$cur / $m -lt 0.8) { return "$ESC[91m" }
    } catch {}
    return "$ESC[37m"
}

function Format-GroupStats {
    $entries = Read-GroupStats
    if ($entries.Count -eq 0) { return '' }
    $expMap    = Read-ExpToLevel
    $parsed    = [System.Collections.Generic.List[hashtable]]::new()
    $nameWidth = 0
    foreach ($entry in $entries) {
        if ([string]::IsNullOrWhiteSpace($entry)) { continue }
        $p = $entry -split '\|'
        if ($p.Count -lt 8) { continue }
        $raw    = if ($expMap.ContainsKey($p[1])) { $expMap[$p[1]] } else { '' }
        $tnlStr = if ($raw) { Format-Tnl $raw } else { '' }
        $here   = if ($p.Count -ge 9) { $p[8] } else { '1' }
        $parsed.Add(@{ lvl=$p[0]; name=$p[1]; hp=$p[2]; mhp=$p[3]; mn=$p[4]; mmn=$p[5]; mv=$p[6]; mmv=$p[7]; tnlStr=$tnlStr; here=$here })
        if ($p[1].Length -gt $nameWidth) { $nameWidth = $p[1].Length }
    }
    $wTnl = 0
    foreach ($m in $parsed) {
        if ($m.tnlStr.Length -gt $wTnl) { $wTnl = $m.tnlStr.Length }
        $m.hpPct = try { [int]([double]$m.hp / [double]$m.mhp * 100) } catch { 0 }
        $m.mnPct = try { [int]([double]$m.mn / [double]$m.mmn * 100) } catch { 0 }
        $m.mvPct = try { [int]([double]$m.mv / [double]$m.mmv * 100) } catch { 0 }
    }
    $sb     = [System.Text.StringBuilder]::new()
    $maxLen = 0
    $rows   = [System.Collections.Generic.List[string]]::new()
    foreach ($m in $parsed) {
        $hpA   = Get-StatAnsi $m.hp  $m.mhp
        $mnA   = Get-StatAnsi $m.mn  $m.mmn
        $mvA   = Get-StatAnsi $m.mv  $m.mmv
        $nameA = if ($m.here -ne '1') { "$ESC[91m" } elseif ((Get-NameColor $m.name) -eq 'Cyan') { "$ESC[96m" } else { "$ESC[37m" }
        $hpS   = "$($m.hpPct)%".PadLeft(4)
        $mnS   = "$($m.mnPct)%".PadLeft(4)
        $mvS   = "$($m.mvPct)%".PadLeft(4)
        $tnlStr        = $m.tnlStr.PadRight($wTnl)
        $tnlSuffix     = if ($wTnl -gt 0) { " [$tnlStr]T" }      else { '' }
        $tnlSuffixAnsi = if ($wTnl -gt 0) { " $ESC[90m[$ESC[36m$tnlStr$ESC[90m]$ESC[36mT$RESET" } else { '' }
        $remorts       = Get-CharRemorts $m.name
        $remortSuffix     = if ($remorts) { "  $remorts" }     else { '' }
        $remortSuffixAnsi = if ($remorts) { "  $ESC[90m$($remorts -replace '(\d+)', "$ESC[37m`$1$ESC[90m")$RESET" } else { '' }
        $pName = $m.name.PadRight($nameWidth)
        $plain = "[$($m.lvl.PadLeft(2))] $pName : [$hpS]H [$mnS]M [$mvS]V$tnlSuffix$remortSuffix"
        $rows.Add("$ESC[90m[$ESC[37m$($m.lvl.PadLeft(2))$ESC[90m] $nameA$pName$ESC[90m : " +
                  "$ESC[90m[$hpA$hpS$ESC[90m]$ESC[90mH " +
                  "$ESC[90m[$mnA$mnS$ESC[90m]$ESC[90mM " +
                  "$ESC[90m[$mvA$mvS$ESC[90m]$ESC[90mV$tnlSuffixAnsi$remortSuffixAnsi$RESET")
        if ($plain.Length -gt $maxLen) { $maxLen = $plain.Length }
    }

    # Build enemy rows — Read-EnemyStats output: level|name|hp|mhp|reporters
    $enemyEntries = Read-EnemyStats
    $enemyParsed  = [System.Collections.Generic.List[hashtable]]::new()
    $enemyNameW   = 0
    foreach ($entry in $enemyEntries) {
        if ([string]::IsNullOrWhiteSpace($entry)) { continue }
        $p = $entry -split '\|'
        if ($p.Count -lt 4) { continue }
        $enemyParsed.Add(@{ lvl=$p[0]; name=$p[1]; hp=$p[2]; mhp=$p[3] })
        if ($p[1].Length -gt $enemyNameW) { $enemyNameW = $p[1].Length }
    }
    $eWHp = $eWMhp = 0
    foreach ($e in $enemyParsed) {
        if ($e.hp.Length  -gt $eWHp)  { $eWHp  = $e.hp.Length }
        if ($e.mhp.Length -gt $eWMhp) { $eWMhp = $e.mhp.Length }
    }
    $enemyRows = [System.Collections.Generic.List[string]]::new()
    foreach ($e in $enemyParsed) {
        $hpA          = Get-StatAnsi $e.hp $e.mhp
        $hp           = $e.hp.PadLeft($eWHp);  $mhp = $e.mhp.PadLeft($eWMhp)
        $pName        = $e.name.PadRight($enemyNameW)
        $pct          = try { [int]([double]$e.hp / [double]$e.mhp * 100) } catch { 0 }
        $pctStr       = "$pct%"
        $plain        = "[$($e.lvl.PadLeft(2))] $pName : [$hp/$mhp]H $pctStr"
        $enemyRows.Add("$ESC[90m[$ESC[91m$($e.lvl.PadLeft(2))$ESC[90m] $ESC[91m$pName$ESC[90m : " +
                       "$ESC[90m[$hpA$hp$ESC[90m/$mhp]$ESC[90mH $hpA$pctStr$RESET")
        if ($plain.Length -gt $maxLen) { $maxLen = $plain.Length }
    }

    # Enemies above, group members below so members stay bottom-aligned
    $allRows   = [System.Collections.Generic.List[string]]::new()
    if ($enemyRows.Count -gt 0) {
        $allRows.AddRange($enemyRows)
        $allRows.Add("$ESC[90m$("-" * $maxLen)$RESET")
    }
    $allRows.AddRange($rows)

    $termHeight = [Console]::WindowHeight
    $statsLines = 2 + $allRows.Count  # blank line + separator + all data rows
    $statsRow   = [Math]::Max(1, $termHeight - $statsLines + 1)
    [void]$sb.Append("$ESC[${statsRow};1H")
    [void]$sb.AppendLine("")
    [void]$sb.AppendLine("$ESC[90m$("=" * $maxLen)$RESET")
    for ($i = 0; $i -lt $allRows.Count; $i++) {
        if ($i -lt $allRows.Count - 1) { [void]$sb.AppendLine($allRows[$i]) }
        else                           { [void]$sb.Append($allRows[$i]) }
    }
    return $sb.ToString()
}

function Find-LatestLog {
    Get-ChildItem "nukefire_*.log" -ErrorAction SilentlyContinue |
        Sort-Object LastWriteTime -Descending |
        Select-Object -First 1
}

function Open-LogReader($path) {
    $stream = [System.IO.File]::Open($path, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::ReadWrite)
    $reader = New-Object System.IO.StreamReader($stream, [System.Text.Encoding]::UTF8)
    if ($stream.Length -gt 51200) {
        $stream.Seek(-51200, [System.IO.SeekOrigin]::End) | Out-Null
        $reader.ReadLine() | Out-Null  # discard partial line after seek
    }
    return $reader
}


function Show-LastMap($reader) {
    $tail = [System.Collections.Generic.List[string]]::new()
    $line = $reader.ReadLine()
    while ($null -ne $line) { $tail.Add($line); $line = $reader.ReadLine() }

    $mapStart = -1; $mapEnd = -1
    for ($i = 0; $i -lt $tail.Count; $i++) {
        if ($tail[$i] -match '^\[ BIGMAP \]') {
            $mapStart = $i
            $mapEnd   = -1
        } elseif ($mapStart -ge 0 -and $mapEnd -eq -1 -and $tail[$i] -match '^< \d+H') {
            $mapEnd = $i
        }
    }
    if ($mapStart -ge 0 -and $mapEnd -gt $mapStart) {
        # Trim trailing blank lines and game-text lines (start with a letter) before the prompt
        $end = $mapEnd - 1
        while ($end -gt $mapStart -and ([string]::IsNullOrWhiteSpace($tail[$end]) -or $tail[$end] -match '^[a-zA-Z]')) { $end-- }
        $script:lastMapLines = $tail[$mapStart..$end]
        Write-Host ($HIDE + (Format-ColorMap $script:lastMapLines) + (Format-GroupStats) + $SHOW) -NoNewline
    }
}

function Show-MapAndStats {
    if ($null -eq $script:lastMapLines) { return }
    Write-Host ($HIDE + (Format-ColorMap $script:lastMapLines) + (Format-GroupStats) + $SHOW) -NoNewline
}

function Publish-MapBuffer {
    while ($buffer.Count -gt 0) {
        $lastLine = $buffer[$buffer.Count - 1]
        if (-not (Test-ShouldTrimLine $lastLine)) {
            break
        }
        $buffer.RemoveAt($buffer.Count - 1)
    }

    if ($buffer.Count -gt 0) {
        $script:lastMapLines = $buffer.ToArray()
        Show-MapAndStats
    }
}

# Wait for log file
$logFile = $null
while (-not $logFile) {
    $logFile = Find-LatestLog
    if (-not $logFile) {
        Write-Host "Waiting for session log..." -ForegroundColor DarkGray
        Start-Sleep -Seconds 2
        Clear-Host
    }
}

$reader        = Open-LogReader $logFile.FullName
$buffer        = [System.Collections.Generic.List[string]]::new()
$pendingBlanks = [System.Collections.Generic.List[string]]::new()
# Capture states:
#   0 = idle
#   1 = header seen, waiting for legend (line starting with '@')
#   2 = legend seen, waiting for separator blank
#   3 = separator blank seen, waiting for first graphical row
#   4 = in graphical rows — blank deferred to state 5
#   5 = saw a blank mid-map — waiting to see if more map rows follow
$captureState  = 0
$lastCheck     = [DateTime]::Now
$lastStatsPoll = [DateTime]::MinValue

Update-AllCharCaches
Update-ExpCache
Update-RemortCaches
$script:pendingRedraw = $false   # don't double-render on startup

Show-LastMap $reader

function Write-StatsOnly {
    Show-MapAndStats
}

$script:lastRemortPoll = [DateTime]::MinValue

function Invoke-RefreshStats {
    if (([DateTime]::Now - $script:lastStatsPoll).TotalMilliseconds -lt 250) { return }
    $script:lastStatsPoll = [DateTime]::Now

    # Drain new bytes from all char files; render only after +++ marks a complete snapshot.
    Update-AllCharCaches
    # Remorts change rarely (only after sc); poll every 5 seconds.
    if (([DateTime]::Now - $script:lastRemortPoll).TotalSeconds -ge 5) {
        $script:lastRemortPoll = [DateTime]::Now
        Update-RemortCaches
    }
    if ($script:pendingRedraw) {
        $script:pendingRedraw = $false
        Write-StatsOnly
    }
}

function Test-ShouldTrimLine {
    param(
        [string]$Line
    )

    return [string]::IsNullOrWhiteSpace($Line) -or $Line -match '^[a-zA-Z]'
}

function Write-MapBuffer {
    Publish-MapBuffer
}

while ($true) {
    Invoke-RefreshStats

    $line = $reader.ReadLine()
    if ($null -eq $line) {
        $reader.DiscardBufferedData()  # force re-read from stream on next iteration
        # Re-detect new log file when a new session starts
        if (([DateTime]::Now - $lastCheck).TotalSeconds -gt 10) {
            $lastCheck = [DateTime]::Now
            $newer = Find-LatestLog
            if ($newer -and $newer.FullName -ne $logFile.FullName) {
                $reader.Close()
                $logFile      = $newer
                $reader       = Open-LogReader $logFile.FullName
                $buffer.Clear()
                $pendingBlanks.Clear()
                $captureState = 0
                Show-LastMap $reader
            }
        }
        Start-Sleep -Milliseconds 10
        continue
    }

    switch ($captureState) {
        0 {
            if ($line -match '^\[ BIGMAP \]') {
                $buffer.Clear()
                $buffer.Add($line)
                $captureState = 1
            }
        }
        1 {
            # Waiting for legend line (starts with '@')
            $buffer.Add($line)
            if ($line -match '^@') { $captureState = 2 }
        }
        2 {
            # Waiting for separator blank between legend and graphical rows
            $buffer.Add($line)
            if ([string]::IsNullOrWhiteSpace($line)) { $captureState = 3 }
        }
        3 {
            # Waiting for first real graphical row; skip Up/Down Here markers and blank lines
            $buffer.Add($line)
            if (-not [string]::IsNullOrWhiteSpace($line) -and $line -notmatch '<--\s*(Up|Down) Here\s*-->') {
                $captureState = 4
            }
        }
        4 {
            # In graphical rows. Blank lines may be internal row spacing, so defer them.
            if ($line -match '^<\s*\d+H') {
                $captureState = 0
                Publish-MapBuffer
            } elseif ([string]::IsNullOrWhiteSpace($line)) {
                $pendingBlanks.Clear()
                $pendingBlanks.Add($line)
                $captureState = 5
            } else {
                $buffer.Add($line)
            }
        }
        5 {
            # Deferred blank — decide if it's internal spacing or end of map.
            if ([string]::IsNullOrWhiteSpace($line)) {
                # Additional blank — keep accumulating.
                $pendingBlanks.Add($line)
            } elseif ($line -match '^<\s*\d+H' -or $line -match '[a-zA-Z]{2,}') {
                # Prompt or non-map text — map ended before the blank(s); publish and reset.
                $captureState = 0
                Publish-MapBuffer
            } else {
                # Another map row — the blank(s) were internal spacing; flush and continue.
                foreach ($b in $pendingBlanks) { $buffer.Add($b) }
                $buffer.Add($line)
                $captureState = 4
            }
        }
    }
}
