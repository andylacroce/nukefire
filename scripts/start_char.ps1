param([string]$tin, [int]$delay = 3)
Start-Sleep $delay
& "$PSScriptRoot\..\..\tt++.exe" -r $tin
