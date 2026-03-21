#Requires -Version 5.1
<#
.SYNOPSIS
    Hearing Aid Audio Setup — user-friendly GUI wizard.
    Detects paired Bluetooth hearing aids / audio devices, generates a
    personalized enforcer script, and creates a Desktop shortcut.

.USAGE
    powershell -ExecutionPolicy Bypass -File Setup-BTAudioShortcut.ps1
    powershell -ExecutionPolicy Bypass -File Setup-BTAudioShortcut.ps1 -CheckOnly
#>

param([switch]$CheckOnly)

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$TITLE = "Hearing Aid Audio Setup"

# ── GUI Helpers ───────────────────────────────────────────────────────────────

function Show-Info {
    param([string]$Message, [string]$Title = $TITLE)
    [System.Windows.Forms.MessageBox]::Show(
        $Message, $Title,
        [System.Windows.Forms.MessageBoxButtons]::OK,
        [System.Windows.Forms.MessageBoxIcon]::Information
    ) | Out-Null
}

function Show-Error {
    param([string]$Message, [string]$Title = $TITLE)
    [System.Windows.Forms.MessageBox]::Show(
        $Message, $Title,
        [System.Windows.Forms.MessageBoxButtons]::OK,
        [System.Windows.Forms.MessageBoxIcon]::Warning
    ) | Out-Null
}

function Show-YesNo {
    param([string]$Message, [string]$Title = $TITLE)
    $result = [System.Windows.Forms.MessageBox]::Show(
        $Message, $Title,
        [System.Windows.Forms.MessageBoxButtons]::YesNo,
        [System.Windows.Forms.MessageBoxIcon]::Question
    )
    return $result -eq [System.Windows.Forms.DialogResult]::Yes
}

function Show-CheckResults {
    param([System.Collections.Generic.List[hashtable]]$Checks)

    $form = New-Object System.Windows.Forms.Form
    $form.Text = $TITLE
    $form.Size = New-Object System.Drawing.Size(520, 420)
    $form.StartPosition = "CenterScreen"
    $form.FormBorderStyle = "FixedDialog"
    $form.MaximizeBox = $false

    $label = New-Object System.Windows.Forms.Label
    $label.Text = "Compatibility Check Results"
    $label.Font = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold)
    $label.Location = New-Object System.Drawing.Point(16, 12)
    $label.Size = New-Object System.Drawing.Size(480, 24)
    $form.Controls.Add($label)

    $panel = New-Object System.Windows.Forms.Panel
    $panel.Location = New-Object System.Drawing.Point(16, 44)
    $panel.Size = New-Object System.Drawing.Size(476, 300)
    $panel.AutoScroll = $true
    $form.Controls.Add($panel)

    $y = 4
    foreach ($c in $Checks) {
        $icon = if ($c.Ok) { "✔" } else { "✘" }
        $color = if ($c.Ok) { [System.Drawing.Color]::DarkGreen } else { [System.Drawing.Color]::Crimson }

        $row = New-Object System.Windows.Forms.Label
        $row.Text = "$icon  $($c.Label)"
        $row.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
        $row.ForeColor = $color
        $row.Location = New-Object System.Drawing.Point(4, $y)
        $row.Size = New-Object System.Drawing.Size(460, 20)
        $panel.Controls.Add($row)
        $y += 22

        if ($c.Detail) {
            $det = New-Object System.Windows.Forms.Label
            $det.Text = "     $($c.Detail)"
            $det.Font = New-Object System.Drawing.Font("Segoe UI", 8)
            $det.ForeColor = [System.Drawing.Color]::DimGray
            $det.Location = New-Object System.Drawing.Point(4, $y)
            $det.Size = New-Object System.Drawing.Size(460, 18)
            $panel.Controls.Add($det)
            $y += 20
        }

        if (-not $c.Ok -and $c.Hint) {
            $hint = New-Object System.Windows.Forms.Label
            $hint.Text = "     What to do: $($c.Hint)"
            $hint.Font = New-Object System.Drawing.Font("Segoe UI", 8)
            $hint.ForeColor = [System.Drawing.Color]::DarkOrange
            $hint.Location = New-Object System.Drawing.Point(4, $y)
            $hint.Size = New-Object System.Drawing.Size(460, 36)
            $hint.AutoSize = $false
            $panel.Controls.Add($hint)
            $y += 40
        }
        $y += 4
    }

    $btn = New-Object System.Windows.Forms.Button
    $btn.Text = "OK"
    $btn.Size = New-Object System.Drawing.Size(80, 28)
    $btn.Location = New-Object System.Drawing.Point(216, 352)
    $btn.Add_Click({ $form.Close() })
    $form.Controls.Add($btn)
    $form.AcceptButton = $btn

    $form.ShowDialog() | Out-Null
}

function Show-DevicePicker {
    param([array]$Devices)

    $form = New-Object System.Windows.Forms.Form
    $form.Text = $TITLE
    $form.Size = New-Object System.Drawing.Size(460, 240)
    $form.StartPosition = "CenterScreen"
    $form.FormBorderStyle = "FixedDialog"
    $form.MaximizeBox = $false

    $label = New-Object System.Windows.Forms.Label
    $label.Text = "More than one Bluetooth audio device was found.`nPlease select your hearing aids or headset:"
    $label.Font = New-Object System.Drawing.Font("Segoe UI", 9)
    $label.Location = New-Object System.Drawing.Point(16, 16)
    $label.Size = New-Object System.Drawing.Size(420, 40)
    $form.Controls.Add($label)

    $list = New-Object System.Windows.Forms.ListBox
    $list.Font = New-Object System.Drawing.Font("Segoe UI", 9)
    $list.Location = New-Object System.Drawing.Point(16, 64)
    $list.Size = New-Object System.Drawing.Size(420, 100)
    foreach ($d in $Devices) { $list.Items.Add($d.Name) | Out-Null }
    $list.SelectedIndex = 0
    $form.Controls.Add($list)

    $btn = New-Object System.Windows.Forms.Button
    $btn.Text = "Select"
    $btn.Size = New-Object System.Drawing.Size(80, 28)
    $btn.Location = New-Object System.Drawing.Point(180, 174)
    $btn.Add_Click({ $form.DialogResult = [System.Windows.Forms.DialogResult]::OK; $form.Close() })
    $form.Controls.Add($btn)
    $form.AcceptButton = $btn

    $form.ShowDialog() | Out-Null
    return $Devices[$list.SelectedIndex]
}

# ── Step 1: Mobile Bluetooth warning ─────────────────────────────────────────
$proceed = Show-YesNo @"
Welcome to Hearing Aid Audio Setup.

Before we begin, please turn off Bluetooth on your phone or any other mobile device that your hearing aids connect to.

This prevents your phone from interfering with the setup.

Have you turned off Bluetooth on your mobile devices?
"@

if (-not $proceed) {
    Show-Info "Please turn off Bluetooth on your mobile devices, then run this setup again."
    exit 0
}

# ── Step 2: Compatibility checks ──────────────────────────────────────────────
$checks = [System.Collections.Generic.List[hashtable]]::new()
$allPass = $true

# Windows 11
$build = [System.Environment]::OSVersion.Version.Build
$winVer = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion").DisplayVersion
$win11 = $build -ge 22000
$checks.Add(@{ Label="Windows 11 required"; Ok=$win11; Detail="Your version: $winVer (build $build)";
    Hint="This setup requires Windows 11. Please contact your IT support to upgrade." })
if (-not $win11) { $allPass = $false }

# 24H2
$leAudio = $build -ge 26100
$checks.Add(@{ Label="Windows 11 24H2 or later"; Ok=$leAudio; Detail="Required for Bluetooth hearing aid support (build 26100+)";
    Hint="Go to Settings > Windows Update and install all available updates, then run this setup again." })
if (-not $leAudio) { $allPass = $false }

# BT adapter
$btAdapter = Get-PnpDevice | Where-Object { $_.Class -eq "Bluetooth" -and $_.Status -eq "OK" } | Select-Object -First 1
$hasBT = $null -ne $btAdapter
$checks.Add(@{ Label="Bluetooth hardware detected"; Ok=$hasBT;
    Detail=$(if ($hasBT) { "Found: $($btAdapter.FriendlyName)" } else { "No Bluetooth adapter found." });
    Hint="Your computer may not have Bluetooth hardware, or the driver may need to be reinstalled. This device may not be compatible." })
if (-not $hasBT) { $allPass = $false }

# BT service
$btSvc = Get-Service -Name bthserv -ErrorAction SilentlyContinue
$btSvcOk = $btSvc -and $btSvc.Status -eq 'Running'
$checks.Add(@{ Label="Bluetooth service is running"; Ok=$btSvcOk;
    Detail=$(if ($btSvcOk) { "Bluetooth Support Service: Running" } else { "Bluetooth Support Service: $($btSvc.Status)" });
    Hint="Press the Windows key, search for 'Services', find 'Bluetooth Support Service', right-click it, and choose Start." })
if (-not $btSvcOk) { $allPass = $false }

# AudioDeviceCmdlets
$modInstalled = $null -ne (Get-Module -ListAvailable -Name AudioDeviceCmdlets)
$checks.Add(@{ Label="Audio control software installed"; Ok=$modInstalled;
    Detail=$(if ($modInstalled) { "AudioDeviceCmdlets: Found" } else { "AudioDeviceCmdlets: Not installed (setup will offer to install it)" });
    Hint="" })

# BT audio device visible
$btCandidates = @()
if ($modInstalled) {
    Import-Module AudioDeviceCmdlets -ErrorAction SilentlyContinue
    $btCandidates = @(Get-AudioDevice -List | Where-Object {
        $_.Type -eq 'Playback' -and
        $_.Name -notmatch 'Realtek|AMD|Intel|NVIDIA|HD Audio|HDMI|DisplayPort|USB Audio Device|LG |Samsung Display' -and
        $_.ID -match '^\{0\.0\.0\.'
    })
}
$hasBTAudio = $btCandidates.Count -gt 0
$checks.Add(@{ Label="Bluetooth audio device detected"; Ok=$hasBTAudio;
    Detail=$(if ($hasBTAudio) { "Found: $(($btCandidates | ForEach-Object { $_.Name }) -join ', ')" } else { "No Bluetooth audio device visible yet." });
    Hint="Make sure your hearing aids or headset are powered on and connected to this computer via Bluetooth, then run this setup again." })
if (-not $hasBTAudio) { $allPass = $false }

Show-CheckResults -Checks $checks

if ($CheckOnly -or (-not $allPass -and -not $modInstalled -and $hasBTAudio)) {
    if (-not $allPass) {
        Show-Error "One or more checks did not pass. Please follow the steps shown and run this setup again."
    }
    exit $(if ($allPass) { 0 } else { 1 })
}

if (-not $allPass) {
    $cont = Show-YesNo "Some checks did not pass. Do you want to try continuing anyway?"
    if (-not $cont) { exit 1 }
}

# ── Step 3: Install AudioDeviceCmdlets if needed ──────────────────────────────
if (-not $modInstalled) {
    $install = Show-YesNo "This setup needs to install a small audio control tool (AudioDeviceCmdlets) on your computer.`n`nIt is free, safe, and takes about 30 seconds.`n`nWould you like to install it now?"
    if (-not $install) {
        Show-Error "Setup cannot continue without the audio control tool. Please run this setup again when you are ready."
        exit 1
    }
    try {
        Install-Module -Name AudioDeviceCmdlets -Scope CurrentUser -Force -AllowClobber -ErrorAction Stop
        Import-Module AudioDeviceCmdlets -ErrorAction Stop
    } catch {
        Show-Error "The audio control tool could not be installed.`n`nPlease check your internet connection and try again, or contact your IT support."
        exit 1
    }
}

# ── Step 4: Device selection ──────────────────────────────────────────────────
$selected = $null
if ($btCandidates.Count -eq 1) {
    $selected = $btCandidates[0]
} elseif ($btCandidates.Count -gt 1) {
    $selected = Show-DevicePicker -Devices $btCandidates
} else {
    Show-Error "No Bluetooth audio device was found.`n`nPlease make sure your hearing aids are connected to this computer and try again."
    exit 1
}

# ── Step 5: Write enforcer script ─────────────────────────────────────────────
$safeName   = $selected.Name -replace '[\\/:*?"<>|]', '' -replace '\s+', '-'
$scriptPath = "$env:USERPROFILE\Desktop\Set-${safeName}-Output.ps1"

$enforcerContent = @"
#Requires -Version 5.1
# Auto-generated by Hearing Aid Audio Setup
# Device: $($selected.Name)
Import-Module AudioDeviceCmdlets -ErrorAction Stop
`$name = "$($selected.Name)"
`$device = Get-AudioDevice -List | Where-Object { `$_.Type -eq 'Playback' -and `$_.Name -eq `$name }
if (`$device) {
    Set-AudioDevice -Index `$device.Index | Out-Null
    Set-AudioDevice -Index `$device.Index -CommunicationOnly | Out-Null
} else {
    Add-Type -AssemblyName System.Windows.Forms
    [System.Windows.Forms.MessageBox]::Show("Your hearing aids were not found.`n`nMake sure they are connected to this computer and try again.", "Hearing Aid Audio", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning) | Out-Null
}
"@

Set-Content -Path $scriptPath -Value $enforcerContent -Encoding UTF8

# ── Step 6: Verify ────────────────────────────────────────────────────────────
& powershell -ExecutionPolicy Bypass -WindowStyle Hidden -File $scriptPath
Start-Sleep -Seconds 2
$current = (Get-AudioDevice -Playback).Name

if ($current -ne $selected.Name) {
    Show-Error "Setup completed, but we could not confirm your hearing aids are set as the audio output.`n`nMake sure they are connected and try clicking the shortcut on your Desktop."
}

# ── Step 7: Create shortcut ───────────────────────────────────────────────────
$shortcutLabel = "Set Hearing Aid Audio Output"
$shortcutPath  = "$env:USERPROFILE\Desktop\$shortcutLabel.lnk"
$wsh = New-Object -ComObject WScript.Shell
$sc  = $wsh.CreateShortcut($shortcutPath)
$sc.TargetPath   = "powershell.exe"
$sc.Arguments    = "-ExecutionPolicy Bypass -WindowStyle Hidden -File `"$scriptPath`""
$sc.IconLocation = "mmcndmgr.dll,39"
$sc.Save()

# ── Step 8: Done ──────────────────────────────────────────────────────────────
Show-Info @"
Setup is complete!

Your hearing aids have been set as the audio output for this computer.

A shortcut called "Set Hearing Aid Audio Output" has been placed on your Desktop.

Whenever your hearing aids reconnect and sound is not coming through them, just double-click that shortcut.
"@
