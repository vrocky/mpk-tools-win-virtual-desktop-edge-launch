Add-Type -AssemblyName System.Drawing

$edgeExe     = "${env:ProgramFiles(x86)}\Microsoft\Edge\Application\msedge.exe"
$launcherPs1 = "C:\Scripts\EdgeProfiles\Launch-Edge.ps1"
$iconPath    = "C:\Scripts\EdgeProfiles\edge_desktop.ico"
$desktopPath = [Environment]::GetFolderPath("Desktop")
$shortcut    = "$desktopPath\Edge (Virtual Desktop).lnk"
$adminShortcut = "$desktopPath\Edge (Virtual Desktop) (Admin).lnk"

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

	$lnk.TargetPath       = "powershell.exe"
	$lnk.Arguments        = "-ExecutionPolicy Bypass -WindowStyle Hidden -File `"$launcherPs1`""
	$lnk.WorkingDirectory = "C:\Scripts\EdgeProfiles"
	$lnk.IconLocation     = "$iconPath,0"
	$lnk.Description      = $Description
	$lnk.Save()

	if ($RunAsAdmin) {
		Set-ShortcutRunAsAdmin -Path $Path
	}

	Write-Host "Shortcut   : $Path" -ForegroundColor Green
}

# ── Extract Edge icon and save as .ico ────────────────────────────────────────
$srcIcon = [System.Drawing.Icon]::ExtractAssociatedIcon($edgeExe)

# Rebuild at 256x256 for a crisp shortcut icon
$bmp = New-Object System.Drawing.Bitmap 256, 256
$g   = [System.Drawing.Graphics]::FromImage($bmp)
$g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$g.DrawImage($srcIcon.ToBitmap(), 0, 0, 256, 256)
$g.Dispose()

$resized = [System.Drawing.Icon]::FromHandle($bmp.GetHicon())
$fs = [System.IO.File]::OpenWrite($iconPath)
$resized.Save($fs)
$fs.Close()
$bmp.Dispose()

Write-Host "Icon saved : $iconPath" -ForegroundColor Green

# ── Create desktop shortcuts (.lnk) ──────────────────────────────────────────
New-LauncherShortcut -Path $shortcut -Description "Open Edge for the current virtual desktop"
New-LauncherShortcut -Path $adminShortcut -Description "Open Edge for the current virtual desktop as administrator" -RunAsAdmin
