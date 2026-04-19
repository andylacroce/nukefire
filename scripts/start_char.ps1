param(
	[Parameter(Mandatory = $true)][string]$tin,
	[int]$delay = 3,
	[string]$ttExe = ""
)

Start-Sleep -Seconds $delay

if ([string]::IsNullOrWhiteSpace($ttExe)) {
	$ttExe = Join-Path $PSScriptRoot "..\..\tt++.exe"
}

& $ttExe -r $tin
