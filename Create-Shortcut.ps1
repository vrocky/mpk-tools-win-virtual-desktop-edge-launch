$edgeExe     = "${env:ProgramFiles(x86)}\Microsoft\Edge\Application\msedge.exe"
$scriptDir   = Split-Path -Parent $MyInvocation.MyCommand.Path
$launcherPs1 = Join-Path $scriptDir "Launch-Edge.ps1"
$iconPath    = Join-Path $scriptDir "edge_desktop.ico"
$desktopPath = [Environment]::GetFolderPath("Desktop")
$shortcut    = "$desktopPath\Edge (Virtual Desktop).lnk"
$adminShortcut = "$desktopPath\Edge (Virtual Desktop) (Admin).lnk"

if (-not (Test-Path $launcherPs1)) {
	throw "Launcher script not found: $launcherPs1"
}

function Get-ShortcutIconLocation {
	if (Test-Path $edgeExe) {
		return "$edgeExe,0"
	}

	if (Test-Path $iconPath) {
		return "$iconPath,0"
	}

	Write-Warning "Edge icon source not found. Shortcut will use the default PowerShell icon."
	return $null
}

function Set-ShortcutRunAsAdmin {
	param(
		[Parameter(Mandatory = $true)]
		[string]$Path
	)

	$bytes = [System.IO.File]::ReadAllBytes($Path)
	$bytes[0x15] = $bytes[0x15] -bor 0x20
	[System.IO.File]::WriteAllBytes($Path, $bytes)
}

function New-LauncherShortcut {
	param(
		[Parameter(Mandatory = $true)]
		[string]$Path,
		[Parameter(Mandatory = $true)]
		[string]$Description,
		[switch]$RunAsAdmin
	)

	$wsh = New-Object -ComObject WScript.Shell
	$lnk = $wsh.CreateShortcut($Path)
	$iconLocation = Get-ShortcutIconLocation

	$lnk.TargetPath       = "powershell.exe"
	$lnk.Arguments        = "-ExecutionPolicy Bypass -WindowStyle Hidden -File `"$launcherPs1`""
	$lnk.WorkingDirectory = $scriptDir
	if ($iconLocation) {
		$lnk.IconLocation = $iconLocation
	}
	$lnk.Description      = $Description
	$lnk.Save()

	if ($RunAsAdmin) {
		Set-ShortcutRunAsAdmin -Path $Path
	}

	Write-Host "Shortcut   : $Path" -ForegroundColor Green
}

# ── Create desktop shortcuts (.lnk) ──────────────────────────────────────────
New-LauncherShortcut -Path $shortcut -Description "Open Edge for the current virtual desktop"
New-LauncherShortcut -Path $adminShortcut -Description "Open Edge for the current virtual desktop as administrator" -RunAsAdmin
