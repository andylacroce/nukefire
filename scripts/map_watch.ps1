[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Clear-Host

$ESC   = [char]27
$RESET = "$ESC[0m"
$CLEAR = "$ESC[2J$ESC[H"   # erase screen + home cursor — faster and atomic vs Clear-Host

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

function Find-LatestLog {
    Get-ChildItem "nukefire_Mutiny_*.log" -ErrorAction SilentlyContinue |
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
        Write-Host (Format-ColorMap $tail[$mapStart..$end]) -NoNewline
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

$reader    = Open-LogReader $logFile.FullName
$buffer    = [System.Collections.Generic.List[string]]::new()
# Capture states:
#   0 = idle
#   1 = header seen, waiting for legend (line starting with '@')
#   2 = legend seen, waiting for separator blank
#   3 = separator blank seen, reading graphical rows
#   4 = graphical rows seen — next blank line triggers immediate render
$captureState = 0
$lastCheck    = [DateTime]::Now

Show-LastMap $reader

function Render-Buffer {
    while ($buffer.Count -gt 0 -and ([string]::IsNullOrWhiteSpace($buffer[$buffer.Count - 1]) -or $buffer[$buffer.Count - 1] -match '^[a-zA-Z]')) {
        $buffer.RemoveAt($buffer.Count - 1)
    }
    if ($buffer.Count -gt 0) {
        Write-Host (Format-ColorMap $buffer) -NoNewline
    }
}

while ($true) {
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
            # In graphical rows — blank line means map drawing is done; render immediately
            if ([string]::IsNullOrWhiteSpace($line)) {
                $captureState = 0
                Render-Buffer
            } else {
                $buffer.Add($line)
            }
        }
    }
}
