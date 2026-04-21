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
        if ($line -match '^\[ Local Map \](.*)$') {
            [void]$out.AppendLine("$CYAN[ Local Map ]$RESET$DGRAY$($Matches[1])$RESET")
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

function Read-GroupStats {
    $path = "group_stats.log"
    if (-not (Test-Path $path)) { return @() }
    try {
        $stream = [System.IO.File]::Open($path, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::ReadWrite)
        $rdr = [System.IO.StreamReader]::new($stream, [System.Text.Encoding]::UTF8)
        $lines = [System.Collections.Generic.List[string]]::new()
        $l = $rdr.ReadLine()
        while ($null -ne $l) { $lines.Add($l); $l = $rdr.ReadLine() }
        $rdr.Close()
    } catch { return @() }
    $marker = -1
    for ($i = $lines.Count - 1; $i -ge 0; $i--) {
        if ($lines[$i] -eq '---') { $marker = $i; break }
    }
    if ($marker -lt 0 -or $marker -ge $lines.Count - 1) { return @() }
    $block = $lines[($marker + 1)..($lines.Count - 1)]
    # Deduplicate by name — keep last occurrence per member in case multiple sessions raced
    $seen    = @{}
    $ordered = [System.Collections.Generic.List[string]]::new()
    for ($i = $block.Count - 1; $i -ge 0; $i--) {
        $p = $block[$i] -split '\|'
        if ($p.Count -ge 2 -and -not $seen.ContainsKey($p[1])) {
            $seen[$p[1]] = $true
            $ordered.Insert(0, $block[$i])
        }
    }
    return $ordered.ToArray()
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

function Read-ExpToLevel {
    $path = "exp.log"
    if (-not (Test-Path $path)) { return @{} }
    try {
        $stream = [System.IO.File]::Open($path, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::ReadWrite)
        $rdr = [System.IO.StreamReader]::new($stream, [System.Text.Encoding]::UTF8)
        $lines = [System.Collections.Generic.List[string]]::new()
        $l = $rdr.ReadLine()
        while ($null -ne $l) { $lines.Add($l); $l = $rdr.ReadLine() }
        $rdr.Close()
    } catch { return @{} }
    $result = @{}
    for ($i = $lines.Count - 1; $i -ge 0; $i--) {
        $p = $lines[$i] -split '\|', 2
        if ($p.Count -eq 2 -and -not $result.ContainsKey($p[0])) {
            $result[$p[0]] = $p[1]
        }
    }
    return $result
}

function Get-StatAnsi($cur, $max) {
    try {
        $m = [double]$max
        if ($m -gt 0 -and [double]$cur / $m -lt 0.5) { return "$ESC[91m" }
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
        $parsed.Add(@{ lvl=$p[0]; name=$p[1]; hp=$p[2]; mhp=$p[3]; mn=$p[4]; mmn=$p[5]; mv=$p[6]; mmv=$p[7]; tnlStr=$tnlStr })
        if ($p[1].Length -gt $nameWidth) { $nameWidth = $p[1].Length }
    }
    $wHp = $wMhp = $wMn = $wMmn = $wMv = $wMmv = $wTnl = 0
    foreach ($m in $parsed) {
        if ($m.hp.Length     -gt $wHp)  { $wHp  = $m.hp.Length }
        if ($m.mhp.Length    -gt $wMhp) { $wMhp = $m.mhp.Length }
        if ($m.mn.Length     -gt $wMn)  { $wMn  = $m.mn.Length }
        if ($m.mmn.Length    -gt $wMmn) { $wMmn = $m.mmn.Length }
        if ($m.mv.Length     -gt $wMv)  { $wMv  = $m.mv.Length }
        if ($m.mmv.Length    -gt $wMmv) { $wMmv = $m.mmv.Length }
        if ($m.tnlStr.Length -gt $wTnl) { $wTnl = $m.tnlStr.Length }
    }
    $sb     = [System.Text.StringBuilder]::new()
    $maxLen = 0
    $rows   = [System.Collections.Generic.List[string]]::new()
    foreach ($m in $parsed) {
        $hpA   = Get-StatAnsi $m.hp  $m.mhp
        $mnA   = Get-StatAnsi $m.mn  $m.mmn
        $mvA   = Get-StatAnsi $m.mv  $m.mmv
        $nameA = if ((Get-NameColor $m.name) -eq 'Cyan') { "$ESC[96m" } else { "$ESC[37m" }
        $hp  = $m.hp.PadLeft($wHp);   $mhp = $m.mhp.PadLeft($wMhp)
        $mn  = $m.mn.PadLeft($wMn);   $mmn = $m.mmn.PadLeft($wMmn)
        $mv  = $m.mv.PadLeft($wMv);   $mmv = $m.mmv.PadLeft($wMmv)
        $tnlStr        = $m.tnlStr.PadRight($wTnl)
        $tnlSuffix     = if ($wTnl -gt 0) { " [$tnlStr]T" }      else { '' }
        $tnlSuffixAnsi = if ($wTnl -gt 0) { " $ESC[90m[$ESC[36m$tnlStr$ESC[90m]$ESC[36mT$RESET" } else { '' }
        $pName = $m.name.PadRight($nameWidth)
        $plain = "[$($m.lvl.PadLeft(2))] $pName : [$hp/$mhp]H [$mn/$mmn]M [$mv/$mmv]V$tnlSuffix"
        $rows.Add("$ESC[90m[$ESC[37m$($m.lvl.PadLeft(2))$ESC[90m] $nameA$pName$ESC[90m : " +
                  "$ESC[90m[$hpA$hp$ESC[90m/$mhp]$ESC[90mH " +
                  "$ESC[90m[$mnA$mn$ESC[90m/$mmn]$ESC[90mM " +
                  "$ESC[90m[$mvA$mv$ESC[90m/$mmv]$ESC[90mV$tnlSuffixAnsi$RESET")
        if ($plain.Length -gt $maxLen) { $maxLen = $plain.Length }
    }
    $termHeight = [Console]::WindowHeight
    $statsLines = 2 + $parsed.Count  # blank line + separator + N member rows
    $statsRow   = [Math]::Max(1, $termHeight - $statsLines + 1)
    [void]$sb.Append("$ESC[${statsRow};1H")
    [void]$sb.AppendLine("")
    [void]$sb.AppendLine("$ESC[90m$("=" * $maxLen)$RESET")
    for ($i = 0; $i -lt $rows.Count; $i++) {
        if ($i -lt $rows.Count - 1) { [void]$sb.AppendLine($rows[$i]) }
        else                        { [void]$sb.Append($rows[$i]) }
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
        if ($tail[$i] -match '^\[ Local Map \]') {
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

$reader       = Open-LogReader $logFile.FullName
$buffer       = [System.Collections.Generic.List[string]]::new()
$lastMapLines  = $null
$sf0 = Get-Item "group_stats.log" -ErrorAction SilentlyContinue
$lastStatsTime = if ($sf0) { $sf0.LastWriteTime } else { [DateTime]::MinValue }
# Capture states:
#   0 = idle
#   1 = header seen, waiting for legend (line starting with '@')
#   2 = legend seen, waiting for separator blank
#   3 = separator blank seen, reading graphical rows
#   4 = graphical rows seen — next blank line triggers immediate render
$captureState = 0
$lastCheck    = [DateTime]::Now
$pendingMap   = $null

Show-LastMap $reader

function Write-StatsOnly {
    Write-Host ($HIDE + (Format-ColorMap $script:lastMapLines) + (Format-GroupStats) + $SHOW) -NoNewline
}

function Test-ShouldTrimLine {
    param(
        [string]$Line
    )

    return [string]::IsNullOrWhiteSpace($Line) -or $Line -match '^[a-zA-Z]'
}

function Write-MapBuffer {
    while ($buffer.Count -gt 0) {
        $lastLine = $buffer[$buffer.Count - 1]
        if (-not (Test-ShouldTrimLine $lastLine)) {
            break
        }
        $buffer.RemoveAt($buffer.Count - 1)
    }
    if ($buffer.Count -gt 0) {
        $script:lastMapLines = $buffer.ToArray()
        Write-Host ($HIDE + (Format-ColorMap $script:lastMapLines) + (Format-GroupStats) + $SHOW) -NoNewline
    }
}

while ($true) {
    $line = $reader.ReadLine()
    if ($null -eq $line) {
        $reader.DiscardBufferedData()  # force re-read from stream on next iteration
        # Render the latest map now that we've caught up to the end of available data
        if ($null -ne $pendingMap) {
            $script:lastMapLines = $pendingMap
            $pendingMap = $null
            Write-Host ($HIDE + (Format-ColorMap $script:lastMapLines) + (Format-GroupStats) + $SHOW) -NoNewline
        }
        # Redraw when group stats change between map updates (at most once per second)
        if ($null -ne $lastMapLines -and ([DateTime]::Now - $lastStatsTime).TotalSeconds -ge 3) {
            $sf = Get-Item "group_stats.log" -ErrorAction SilentlyContinue
            if ($sf -and $sf.LastWriteTime -gt $lastStatsTime) {
                $lastStatsTime = [DateTime]::Now
                Write-StatsOnly
            }
        }
        # Re-detect new log file when a new session starts
        if (([DateTime]::Now - $lastCheck).TotalSeconds -gt 10) {
            $lastCheck = [DateTime]::Now
            $newer = Find-LatestLog
            if ($newer -and $newer.FullName -ne $logFile.FullName) {
                $reader.Close()
                $logFile      = $newer
                $reader       = Open-LogReader $logFile.FullName
                $buffer.Clear()
                $captureState = 0
                Show-LastMap $reader
            }
        }
        Start-Sleep -Milliseconds 10
        continue
    }

    switch ($captureState) {
        0 {
            if ($line -match '^\[ Local Map \]') {
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
            # In graphical rows — blank line means map drawing is done; defer render
            if ([string]::IsNullOrWhiteSpace($line)) {
                $captureState = 0
                while ($buffer.Count -gt 0 -and (Test-ShouldTrimLine $buffer[$buffer.Count - 1])) {
                    $buffer.RemoveAt($buffer.Count - 1)
                }
                if ($buffer.Count -gt 0) {
                    $pendingMap = $buffer.ToArray()
                }
            } else {
                $buffer.Add($line)
            }
        }
    }
}
