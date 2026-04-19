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
            $mapEnd   = -1  # reset so we capture only the first blank line after this map
        } elseif ($mapStart -ge 0 -and $mapEnd -eq -1 -and [string]::IsNullOrWhiteSpace($tail[$i])) {
            $mapEnd = $i
        }
    }
    if ($mapStart -ge 0 -and $mapEnd -gt $mapStart) {
        Write-Host (Format-ColorMap $tail[$mapStart..($mapEnd - 1)]) -NoNewline
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
$capturing = $false
$lastCheck = [DateTime]::Now

Show-LastMap $reader

while ($true) {
    $line = $reader.ReadLine()
    if ($null -eq $line) {
        # Re-detect new log file when a new session starts
        if (([DateTime]::Now - $lastCheck).TotalSeconds -gt 10) {
            $lastCheck = [DateTime]::Now
            $newer = Find-LatestLog
            if ($newer -and $newer.FullName -ne $logFile.FullName) {
                $reader.Close()
                $logFile   = $newer
                $reader    = Open-LogReader $logFile.FullName
                $buffer.Clear()
                $capturing = $false
                Show-LastMap $reader
            }
        }
        Start-Sleep -Milliseconds 50
        continue
    }

    if ($line -match '^\[ Local Map \]') {
        $buffer.Clear()
        $capturing = $true
        $buffer.Add($line)
    } elseif ($capturing -and [string]::IsNullOrWhiteSpace($line)) {
        $capturing = $false
        Write-Host (Format-ColorMap $buffer) -NoNewline
    } elseif ($capturing) {
        $buffer.Add($line)
    }
}
