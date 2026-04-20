# Always run in a fresh process so Add-Type never hits stale cached types.
# Detect which shell executable to use so child shells match the current runtime
# (keeps behaviour the same when running under Windows PowerShell or PowerShell 7).
$ShellExe = if ($PSVersionTable.PSEdition -eq 'Core') { 'pwsh' } else { 'powershell' }

if (-not $env:NUKEFIRE_LAUNCHED) {
    $env:NUKEFIRE_LAUNCHED = '1'
    & $ShellExe -ExecutionPolicy Bypass -File $PSCommandPath
    $env:NUKEFIRE_LAUNCHED = $null
    exit
}

Add-Type -AssemblyName System.Windows.Forms

Add-Type @"
using System;
using System.Collections.Generic;
using System.Runtime.InteropServices;
using System.Text;
public class NukeWin {
    [StructLayout(LayoutKind.Sequential)]
    public struct RECT { public int Left, Top, Right, Bottom; }

    [DllImport("user32.dll")]
    public static extern bool EnumWindows(EnumWindowsProc lpEnumFunc, IntPtr lParam);
    public delegate bool EnumWindowsProc(IntPtr hWnd, IntPtr lParam);

    [DllImport("user32.dll", CharSet = CharSet.Auto)]
    public static extern int GetClassName(IntPtr hWnd, StringBuilder lpClassName, int nMaxCount);

    [DllImport("user32.dll")]
    public static extern bool GetWindowRect(IntPtr hWnd, out RECT lpRect);

    [DllImport("user32.dll")]
    public static extern bool SetWindowPos(IntPtr hWnd, IntPtr hWndInsertAfter, int X, int Y, int cx, int cy, uint uFlags);

    [DllImport("user32.dll")]
    public static extern int GetWindowLong(IntPtr hWnd, int nIndex);

    [DllImport("user32.dll")]
    public static extern int SetWindowLong(IntPtr hWnd, int nIndex, int dwNewLong);

    [DllImport("dwmapi.dll")]
    public static extern int DwmGetWindowAttribute(IntPtr hWnd, int dwAttribute, out RECT pvAttribute, int cbAttribute);

    [DllImport("user32.dll")]
    public static extern bool SetProcessDPIAware();

    [DllImport("user32.dll")]
    public static extern bool SetForegroundWindow(IntPtr hWnd);

    public static List<IntPtr> FindWindowsByClass(string className) {
        var result = new List<IntPtr>();
        EnumWindows((hWnd, lParam) => {
            var sb = new StringBuilder(256);
            GetClassName(hWnd, sb, 256);
            if (sb.ToString() == className) result.Add(hWnd);
            return true;
        }, IntPtr.Zero);
        return result;
    }
}
"@

# Optional local machine overrides (gitignored):
# - NukeBin
# - NukeTinTinExe
# - NukeRepoRoot
# - NukeLogsPath
# - NukeCharsWidthFraction
# - NukeStartDelaySeconds
$repoRoot = Split-Path -Parent $PSCommandPath
$localMachineConfig = Join-Path $repoRoot "config\local_machine.ps1"
if (Test-Path $localMachineConfig) {
    . $localMachineConfig
}

$localCharsConfig = Join-Path $repoRoot "config\local_chars.ps1"
if (Test-Path $localCharsConfig) {
    . $localCharsConfig
}

$defaultBin = Split-Path -Parent $repoRoot

# Fraction of screen width given to the characters window (left). Remainder goes to the right panels.
$charsWidthFraction = if ($null -ne $NukeCharsWidthFraction) { [double]$NukeCharsWidthFraction } else { 5 / 9 }

[NukeWin]::SetProcessDPIAware() | Out-Null
$wa = [System.Windows.Forms.Screen]::PrimaryScreen.WorkingArea
$w1 = [int]($wa.Width * $charsWidthFraction)   # chars (left)
$w2 = $wa.Width - $w1                           # map + comms (right)
$h1 = [int]($wa.Height / 2)                     # map (top-right)
$h2 = $wa.Height - $h1                          # comms (bottom-right)

$BIN   = if ($NukeBin) { $NukeBin } else { $defaultBin }
$NUKE  = if ($NukeRepoRoot) { $NukeRepoRoot } else { $repoRoot }
$LOGS  = if ($NukeLogsPath) { $NukeLogsPath } else { Join-Path $NUKE "logs" }
$CHARS = Join-Path $NUKE "scripts\start_char.ps1"
$TTExe = if ($NukeTinTinExe) { $NukeTinTinExe } else { Join-Path $BIN "tt++.exe" }
$startDelaySeconds = if ($null -ne $NukeStartDelaySeconds) { [int]$NukeStartDelaySeconds } else { 3 }

$mapWatchScript      = Join-Path $NUKE "scripts\map_watch.ps1"
$gossipWatchScript   = Join-Path $NUKE "scripts\gossip_watch.ps1"
$telepathWatchScript = Join-Path $NUKE "scripts\telepath_watch.ps1"
$auctionWatchScript  = Join-Path $NUKE "scripts\auction_watch.ps1"
$groupWatchScript    = Join-Path $NUKE "scripts\group_watch.ps1"

if (-not (Test-Path $TTExe)) {
    throw "TinTin executable not found at '$TTExe'. Set NukeTinTinExe in config/local_machine.ps1."
}

if (-not (Test-Path $CHARS)) {
    throw "Character launch script not found at '$CHARS'."
}

if (-not (Test-Path $LOGS)) {
    New-Item -ItemType Directory -Path $LOGS -Force | Out-Null
}

$wtClass = "CASCADIA_HOSTING_WINDOW_CLASS"
function Get-WtWindows { [NukeWin]::FindWindowsByClass($wtClass) }

function Select-FirstTab($hwnd) {
    [NukeWin]::SetForegroundWindow($hwnd) | Out-Null
    Start-Sleep -Milliseconds 300
    [System.Windows.Forms.SendKeys]::SendWait("^%1")  # Ctrl+Alt+1 — focus first tab
}

# Un-maximize and reposition without calling ShowWindow.
# ShowWindow sends WM_SHOWWINDOW which triggers WT's own cascade/restore logic.
# SetWindowLong + SWP_FRAMECHANGED sends only WM_NCCALCSIZE, which WT ignores for layout purposes.
function Set-Position($hwnd, $x, $y, $w, $h) {
    $GWL_STYLE   = -16
    $WS_MAXIMIZE = 0x01000000
    $style = [NukeWin]::GetWindowLong($hwnd, $GWL_STYLE)
    if ($style -band $WS_MAXIMIZE) {
        [NukeWin]::SetWindowLong($hwnd, $GWL_STYLE, ($style -band (-bnot $WS_MAXIMIZE))) | Out-Null
        # Notify window of style change (WM_NCCALCSIZE only — does not trigger WT restore)
        [NukeWin]::SetWindowPos($hwnd, [IntPtr]::Zero, 0, 0, 0, 0, 0x27) | Out-Null  # NOMOVE|NOSIZE|NOZORDER|FRAMECHANGED
    }
    [NukeWin]::SetWindowPos($hwnd, [IntPtr]::Zero, $x, $y, $w, $h, 0x0040) | Out-Null  # SWP_SHOWWINDOW
}

# --- Window 1: characters ---
$before = Get-WtWindows

if (-not $NukeCharacters) {
    $NukeCharacters = @(
        @{ Name = "Mutiny";  Tin = "char\mutiny.tin";  Color = "#7A4040" }
        @{ Name = "Haenym";  Tin = "char\haenym.tin";  Color = "#3D5E7A" }
        @{ Name = "Prodigy"; Tin = "char\prodigy.tin"; Color = "#3D6B50" }
        @{ Name = "Rancor";  Tin = "char\rancor.tin";  Color = "#5C3F7A" }
    )
}

$charsArgs = ""
foreach ($char in $NukeCharacters) {
    $charTin = Join-Path $NUKE $char.Tin
    $tab = "new-tab --title $($char.Name) --tabColor `"$($char.Color)`" -d `"$BIN`" $ShellExe -NoExit -File `"$CHARS`" -tin `"$charTin`" -ttExe `"$TTExe`" -delay $startDelaySeconds"
    if ($charsArgs) { $charsArgs += " ; $tab" } else { $charsArgs = $tab }
}
Start-Process wt -ArgumentList $charsArgs
Start-Sleep -Milliseconds 2500

$after1   = Get-WtWindows
$charsWnd = $after1 | Where-Object { $before -notcontains $_ } | Select-Object -First 1
if (-not $charsWnd) { Write-Warning "Could not find characters window."; exit }

# Measure shadow via DWM — reliable once the window has been visible for a few seconds.
# DwmGetWindowAttribute returns the actual visible rect; GetWindowRect returns the full rect
# including the invisible resize border. The difference is the shadow inset on each side.
$wr  = New-Object NukeWin+RECT
$vis = New-Object NukeWin+RECT
[NukeWin]::GetWindowRect($charsWnd, [ref]$wr)  | Out-Null
[NukeWin]::DwmGetWindowAttribute($charsWnd, 9, [ref]$vis, 16) | Out-Null
$sl = $vis.Left   - $wr.Left
$st = $vis.Top    - $wr.Top
$sr = $wr.Right   - $vis.Right
$sb = $wr.Bottom  - $vis.Bottom

# Position chars window immediately — must happen before TinTin's #split fires (~5s after connect).
Set-Position $charsWnd ($wa.X - $sl) ($wa.Y - $st) ($w1 + $sl + $sr) ($wa.Height + $st + $sb)
Select-FirstTab $charsWnd

# --- Window 2: map (top-right) ---
$mapArgs = "-w new new-tab --title Map --tabColor `"#1E3A4A`" -d `"$LOGS`" $ShellExe -NoExit -File `"$mapWatchScript`""
Start-Process wt -ArgumentList $mapArgs
Start-Sleep -Milliseconds 2500

$after2  = Get-WtWindows
$mapWnd  = $after2 | Where-Object { $after1 -notcontains $_ } | Select-Object -First 1
if (-not $mapWnd) { Write-Warning "Could not find map window."; exit }

Set-Position $mapWnd ($wa.X + $w1 - $sl) ($wa.Y - $st) ($w2 + $sl + $sr) ($h1 + $st + $sb)

# --- Window 3: comms (bottom-right) ---
$commsArgs = (
    "-w new new-tab --title Gossip   --tabColor `"#6B5C2E`" -d `"$LOGS`" $ShellExe -NoExit -File `"$gossipWatchScript`""   +
    " ; new-tab --title Telepath --tabColor `"#2E6666`" -d `"$LOGS`" $ShellExe -NoExit -File `"$telepathWatchScript`""  +
    " ; new-tab --title Auction  --tabColor `"#7A5230`" -d `"$LOGS`" $ShellExe -NoExit -File `"$auctionWatchScript`""   +
    " ; new-tab --title Group    --tabColor `"#2E4A2E`" -d `"$LOGS`" $ShellExe -NoExit -File `"$groupWatchScript`""
)
Start-Process wt -ArgumentList $commsArgs
Start-Sleep -Milliseconds 2500

$after3   = Get-WtWindows
$commsWnd = $after3 | Where-Object { $after2 -notcontains $_ } | Select-Object -First 1
if (-not $commsWnd) { Write-Warning "Could not find comms window."; exit }

Set-Position $commsWnd ($wa.X + $w1 - $sl) ($wa.Y + $h1 - $st) ($w2 + $sl + $sr) ($h2 + $st + $sb)
Select-FirstTab $commsWnd

# Leave focus on the chars window for immediate data entry.
[NukeWin]::SetForegroundWindow($charsWnd) | Out-Null
