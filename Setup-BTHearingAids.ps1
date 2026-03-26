#Setup-BTHearingAids.ps1
#Requires -Version 5.1
<#
.SYNOPSIS
    Hearing Aid Audio Setup — user-friendly GUI wizard.
    Detects paired Bluetooth hearing aids / audio devices, generates a
    personalized enforcer script, creates a Desktop shortcut, and registers
    a Task Scheduler job to re-enforce audio output on screen unlock.

.USAGE
    powershell -ExecutionPolicy Bypass -File Setup-BTHearingAids.ps1
    powershell -ExecutionPolicy Bypass -File Setup-BTHearingAids.ps1 -CheckOnly

.VERSION HISTORY
    1.0.0   Initial release
            - GUI setup wizard with Windows Forms
            - Compatibility check with plain-language results
            - AudioDeviceCmdlets install prompt
            - Bluetooth audio device detection and selection
            - Enforcer script generation and Desktop shortcut
            - Task Scheduler unlock trigger (Event ID 4801)
            - Auto-elevation with UAC pre-warning
            - Hard stop on compatibility failure with plain-language summary
            - Already-run detection with re-run confirmation
            - System tray app with connection status and quick switch
            - Tray app registered at startup via Task Scheduler

.NOTES
    Author:      Deep Coast Engineering
    License:     CC BY-NC 4.0
    Repository:  https://github.com/deep-coast-eng/BT-Hearing-Aids-Setup
    
    Contributions welcome. See CONTRIBUTING.md for guidelines.
    For issues, visit: https://github.com/deep-coast-eng/BT-Hearing-Aids-Setup/issues
#>

param([switch]$CheckOnly)

# ── Auto-elevate to Administrator if needed ───────────────────────────────────
if (-not $CheckOnly) {
    $isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    if (-not $isAdmin) {
        Add-Type -AssemblyName System.Windows.Forms
        [System.Windows.Forms.MessageBox]::Show(
            "Hearing Aid Audio Setup needs to make a small change to your computer to finish setting up.`n`nWindows will show a security confirmation box next. This is normal and expected - please click Yes to continue.",
            "Hearing Aid Audio Setup - One More Step",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Information
        ) | Out-Null
        $psArgs = "-ExecutionPolicy Bypass -WindowStyle Hidden -File `"$($MyInvocation.MyCommand.Path)`""
        if ($CheckOnly) { $psArgs += " -CheckOnly" }
        Start-Process powershell -ArgumentList $psArgs -Verb RunAs -WindowStyle Hidden
        exit
    }
}

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$TITLE      = "Hearing Aid Audio Setup"
$supportUrl = "https://github.com/deep-coast-eng/BT-Hearing-Aids-Setup?tab=readme-ov-file#support--accessibility"
$helpUrl    = "https://github.com/deep-coast-eng/BT-Hearing-Aids-Setup/issues"
$helpNote   = "If you are unsure what to do, please ask your IT support or a family member for help.`nFor technical support, visit: $helpUrl"

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
        "$Message`n`n$helpNote", $Title,
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
    $form.StartPosition = "CenterScreen"
    $form.FormBorderStyle = "FixedDialog"
    $form.MaximizeBox = $false
    $form.FormBorderStyle = "FixedDialog"
    $form.MaximizeBox = $false

    $pad = 20

    $label = New-Object System.Windows.Forms.Label
    $label.Text = "Compatibility Check Results"
    $label.Font = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold)
    $label.Location = New-Object System.Drawing.Point($pad, $pad)
    $label.AutoSize = $true
    $form.Controls.Add($label)

    # Build panel content first so we can measure height
    $panel = New-Object System.Windows.Forms.Panel
    $panel.AutoScroll = $true
    $panel.Location = New-Object System.Drawing.Point($pad, ($pad + 32))

    $y = 4
    foreach ($c in $Checks) {
        $icon  = if ($c.Ok) { "[OK]" } else { "[!!]" }
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

    # Cap panel height at 400, scroll if taller
    $panelHeight = [Math]::Min($y + 8, 400)
    $panel.Size = New-Object System.Drawing.Size(480, $panelHeight)
    $form.Controls.Add($panel)

    # OK button sits 16px below panel, centered, 20px from bottom
    $btnY = $pad + 32 + $panelHeight + 16
    $btn = New-Object System.Windows.Forms.Button
    $btn.Text = "OK"
    $btn.Size = New-Object System.Drawing.Size(80, 28)
    $btn.Location = New-Object System.Drawing.Point(220, $btnY)
    $btn.Add_Click({ $form.Close() })
    $form.Controls.Add($btn)
    $form.AcceptButton = $btn

    # Size form to fit content exactly with 20px bottom pad
    $formHeight = $btnY + 28 + $pad + 40  # 40 for title bar
    $form.Size = New-Object System.Drawing.Size(540, $formHeight)

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
    $label.Text = "More than one Bluetooth audio device was found.`nPlease select your hearing aids or headset from the list below:"
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

function Show-DoneForm {
    $doneForm = New-Object System.Windows.Forms.Form
    $doneForm.Text = $TITLE
    $doneForm.Size = New-Object System.Drawing.Size(480, 340)
    $doneForm.StartPosition = "CenterScreen"
    $doneForm.FormBorderStyle = "FixedDialog"
    $doneForm.MaximizeBox = $false

    $doneIcon = New-Object System.Windows.Forms.PictureBox
    $doneIcon.Image = [System.Drawing.SystemIcons]::Information.ToBitmap()
    $doneIcon.Size = New-Object System.Drawing.Size(32, 32)
    $doneIcon.Location = New-Object System.Drawing.Point(16, 16)
    $doneIcon.SizeMode = "StretchImage"
    $doneForm.Controls.Add($doneIcon)

    $doneText = New-Object System.Windows.Forms.Label
    $doneText.Text = "Setup is complete!`n`nYour hearing aids have been set as the audio output for this computer.`n`nA small icon has been added to your taskbar tray (bottom-right corner). Click it anytime to check status or switch back to your hearing aids.`n`nThe computer will also check automatically each time you unlock your screen."
    $doneText.Font = New-Object System.Drawing.Font("Segoe UI", 9)
    $doneText.Location = New-Object System.Drawing.Point(60, 16)
    $doneText.Size = New-Object System.Drawing.Size(396, 160)
    $doneText.AutoSize = $false
    $doneForm.Controls.Add($doneText)

    $divider = New-Object System.Windows.Forms.Label
    $divider.BorderStyle = "Fixed3D"
    $divider.Location = New-Object System.Drawing.Point(16, 162)
    $divider.Size = New-Object System.Drawing.Size(440, 2)
    $doneForm.Controls.Add($divider)

    $supportText = New-Object System.Windows.Forms.Label
    $supportText.Text = "If this helped you, please consider supporting this free project — created in my free time, free for all, and always will be."
    $supportText.Font = New-Object System.Drawing.Font("Segoe UI", 8)
    $supportText.ForeColor = [System.Drawing.Color]::DimGray
    $supportText.Location = New-Object System.Drawing.Point(16, 172)
    $supportText.Size = New-Object System.Drawing.Size(440, 36)
    $doneForm.Controls.Add($supportText)

    $link = New-Object System.Windows.Forms.LinkLabel
    $link.Text = "Support the developer on GitHub"
    $link.Font = New-Object System.Drawing.Font("Segoe UI", 9)
    $link.Location = New-Object System.Drawing.Point(16, 210)
    $link.Size = New-Object System.Drawing.Size(440, 20)
    $link.Add_LinkClicked({ Start-Process $supportUrl })
    $doneForm.Controls.Add($link)

    $doneBtn = New-Object System.Windows.Forms.Button
    $doneBtn.Text = "OK"
    $doneBtn.Size = New-Object System.Drawing.Size(80, 28)
    $doneBtn.Location = New-Object System.Drawing.Point(192, 238)
    $doneBtn.Add_Click({ $doneForm.Close() })
    $doneForm.Controls.Add($doneBtn)
    $doneForm.AcceptButton = $doneBtn

    $doneForm.ShowDialog() | Out-Null
}

# ── Step 1: Check if already run ──────────────────────────────────────────────
$existingShortcut = "$env:USERPROFILE\Desktop\Set Hearing Aid Audio Output.lnk"
$taskName         = "HearingAidAudioEnforcer"

if ((Test-Path $existingShortcut) -and -not $CheckOnly) {
    $rerun = Show-YesNo "Hearing Aid Audio Setup has already been run on this computer.`n`nYou may want to run it again if:`n  • You got new hearing aids`n  • Your hearing aids stopped connecting correctly after a Windows update`n  • You were told to re-run this setup by whoever set it up for you`n`nWould you like to run setup again?"
    if (-not $rerun) {
        Show-Info "No changes were made.`n`nIf sound is not coming through your hearing aids, try double-clicking the shortcut called ""Set Hearing Aid Audio Output"" on your Desktop.`n`nIf that does not help, ask your IT support or a family member to run this setup again."
        exit 0
    }
    Unregister-ScheduledTask -TaskName $taskName -Confirm:$false -ErrorAction SilentlyContinue
}

# ── Step 2: Mobile Bluetooth warning ──────────────────────────────────────────
if (-not $CheckOnly) {
    $proceed = Show-YesNo "Welcome to Hearing Aid Audio Setup.`n`nBefore we begin, please turn off Bluetooth on your phone or tablet — the one you normally use with your hearing aids.`n`nThis stops your phone from interfering during setup.`n`nHave you turned off Bluetooth on your phone or tablet?"
    if (-not $proceed) {
        Show-Info "No problem. Please turn off Bluetooth on your phone or tablet, then run this setup again.`n`nOn most phones, you can do this by swiping down from the top of the screen and tapping the Bluetooth icon to turn it off."
        exit 0
    }
}

# ── Step 3: Compatibility checks ──────────────────────────────────────────────
$checks  = [System.Collections.Generic.List[hashtable]]::new()
$allPass = $true

$build  = [System.Environment]::OSVersion.Version.Build
$winVer = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion").DisplayVersion
$win11  = $build -ge 22000
$checks.Add(@{ Label="Windows 11 required"; Ok=$win11;
    Detail="Your version: $winVer (build $build)";
    Hint="This setup requires Windows 11. Your computer may need to be upgraded. Ask your IT support or a family member for help." })
if (-not $win11) { $allPass = $false }

$leAudio = $build -ge 26100
$checks.Add(@{ Label="Windows version is up to date"; Ok=$leAudio;
    Detail="Required: Windows 11 version 24H2 or later";
    Hint="Go to Settings, then Windows Update, and install all available updates. Then run this setup again." })
if (-not $leAudio) { $allPass = $false }

$btAdapter = Get-PnpDevice | Where-Object { $_.Class -eq "Bluetooth" -and $_.Status -eq "OK" } | Select-Object -First 1
$hasBT     = $null -ne $btAdapter
$checks.Add(@{ Label="Bluetooth hardware detected"; Ok=$hasBT;
    Detail=$(if ($hasBT) { "Found: $($btAdapter.FriendlyName)" } else { "No Bluetooth hardware found." });
    Hint="This computer may not have the hardware needed to connect hearing aids wirelessly. This computer may not be compatible. Ask your IT support for help." })
if (-not $hasBT) { $allPass = $false }

$btSvc   = Get-Service -Name bthserv -ErrorAction SilentlyContinue
$btSvcOk = $btSvc -and $btSvc.Status -eq 'Running'
$checks.Add(@{ Label="Bluetooth is running correctly"; Ok=$btSvcOk;
    Detail=$(if ($btSvcOk) { "Bluetooth service: Running" } else { "Bluetooth service: not running" });
    Hint="Try restarting the computer and running this setup again. If it still fails, ask your IT support for help." })
if (-not $btSvcOk) { $allPass = $false }

$modInstalled = $null -ne (Get-Module -ListAvailable -Name AudioDeviceCmdlets)
$checks.Add(@{ Label="Audio control software installed"; Ok=$modInstalled;
    Detail=$(if ($modInstalled) { "AudioDeviceCmdlets: Found" } else { "Not yet installed - setup will offer to install it" });
    Hint="" })

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
$checks.Add(@{ Label="Hearing aids detected"; Ok=$hasBTAudio;
    Detail=$(if ($hasBTAudio) { "Found: $(($btCandidates | ForEach-Object { $_.Name }) -join ', ')" } else { "No hearing aids or Bluetooth audio device found." });
    Hint="Make sure your hearing aids are in your ears and connected. To connect them, go to Settings, then Bluetooth and devices — your hearing aids should appear in the list. Once connected, run this setup again." })
if (-not $hasBTAudio) { $allPass = $false }

Show-CheckResults -Checks $checks

# ── Step 4: Failure summary — hard stop ───────────────────────────────────────
if (-not $allPass) {
    $osOk = $win11 -and $leAudio
    $hwOk = $hasBT -and $btSvcOk

    $summary = "Here is what we found on this computer:`n`n"

    if ($win11 -and $leAudio) {
        $summary += "✔  Windows: Up to date ($winVer)`n`n"
    } elseif ($win11 -and -not $leAudio) {
        $summary += "✘  Windows: Needs to be updated (your version is $winVer)`n     Go to Settings, then Windows Update, and install all available updates.`n`n"
    } else {
        $summary += "✘  Windows: This computer is running an older version of Windows that this tool does not support.`n`n"
    }

    if ($hwOk) {
        $summary += "✔  Bluetooth hardware: OK`n`n"
    } elseif (-not $hasBT) {
        $summary += "✘  Bluetooth hardware: Not found. This computer may not have the right hardware to connect hearing aids wirelessly.`n`n"
    } else {
        $summary += "✘  Bluetooth: Found but not running correctly. Try restarting the computer and running this setup again.`n`n"
    }

    if ($hasBTAudio) {
        $summary += "✔  Hearing aids: Detected and connected`n`n"
    } else {
        $summary += "✘  Hearing aids: Not detected. Make sure they are connected before running this setup again.`n     To connect: go to Settings, then Bluetooth and devices.`n`n"
    }

    $summary += "─────────────────────────────`n"
    if (-not $osOk -and -not $hwOk) {
        $summary += "This computer is not compatible with this setup. Both the Windows version and the Bluetooth hardware would need to be upgraded."
    } elseif (-not $osOk) {
        $summary += "This computer may work once Windows is updated. Go to Settings, then Windows Update, install all updates, and try again."
    } elseif (-not $hwOk) {
        $summary += "Windows is up to date, but this computer's Bluetooth hardware may not be compatible with hearing aids."
    } else {
        $summary += "This computer is compatible. Please make sure your hearing aids are connected and try again."
    }

    Show-Error -Message $summary -Title "Hearing Aid Audio Setup — This Computer Does Not Qualify"
    exit 1
}

if ($CheckOnly) {
    Show-Info "Good news — this computer is compatible with Hearing Aid Audio Setup.`n`nRun the setup again without the compatibility check to complete installation."
    exit 0
}

# ── Step 5: Install AudioDeviceCmdlets if needed ──────────────────────────────
if (-not $modInstalled) {
    $install = Show-YesNo "This setup needs to install a small audio control tool on your computer.`n`nIt is free, safe, takes about 30 seconds, and will not affect anything else on your computer.`n`nWould you like to install it now?"
    if (-not $install) {
        Show-Error "Setup cannot continue without the audio control tool.`n`nPlease run this setup again when you are ready."
        exit 1
    }
    try {
        Install-Module -Name AudioDeviceCmdlets -Scope CurrentUser -Force -AllowClobber -ErrorAction Stop | Out-Null
        Import-Module AudioDeviceCmdlets -ErrorAction Stop
    } catch {
        Show-Error "The audio control tool could not be installed.`n`nThis is usually caused by a missing internet connection or a restriction set by your organization."
        exit 1
    }
}

# ── Step 6: Device selection ──────────────────────────────────────────────────
$selected = $null
if ($btCandidates.Count -eq 1) {
    $selected = $btCandidates[0]
} elseif ($btCandidates.Count -gt 1) {
    $selected = Show-DevicePicker -Devices $btCandidates
} else {
    Show-Error "Your hearing aids could not be found.`n`nMake sure they are connected to this computer and try again.`n`nTo connect: go to Settings, then Bluetooth and devices, and look for your hearing aids in the list."
    exit 1
}

# ── Step 7: Write enforcer script ─────────────────────────────────────────────
$safeName   = $selected.Name -replace '[\\/:*?"<>|]', '' -replace '\s+', '-'
$scriptPath = "$env:USERPROFILE\Desktop\Set-${safeName}-Output.ps1"

$enforcerContent = @"
#Requires -Version 5.1
# Auto-generated by Hearing Aid Audio Setup — v1.0.0
# Device: $($selected.Name)
#
# NOTE: This script is intentionally generated as a here-string inside
# Setup-BTAudioShortcut.ps1 rather than shipped as a standalone template.
# This keeps the repo self-contained and ensures the device name is injected
# at install time without requiring a separate configuration step.
# See HearingAidTray.ps1 for the same pattern used with the tray app.
param([switch]`$Auto)
Add-Type -AssemblyName System.Windows.Forms
Import-Module AudioDeviceCmdlets -ErrorAction Stop
`$name = "$($selected.Name)"

# If running automatically on unlock, only enforce if hearing aids were
# already the default or no other non-hearing-aid device is active
if (`$Auto) {
    `$current = (Get-AudioDevice -Playback).Name
    if (`$current -ne `$name) { exit 0 }
}

`$device = Get-AudioDevice -List | Where-Object { `$_.Type -eq 'Playback' -and `$_.Name -eq `$name }
if (`$device) {
    Set-AudioDevice -Index `$device.Index | Out-Null
    Set-AudioDevice -Index `$device.Index -CommunicationOnly | Out-Null
} else {
    # Only show popup if user manually ran the shortcut, not on auto unlock
    if (-not `$Auto) {
        [System.Windows.Forms.MessageBox]::Show(
            "Your hearing aids could not be found.`n`nMake sure they are connected to this computer via Bluetooth, then try again.`n`nTo connect: go to Settings, then Bluetooth and devices, and look for your hearing aids in the list.",
            "Hearing Aid Audio",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Warning
        ) | Out-Null
    }
}
"@

Set-Content -Path $scriptPath -Value $enforcerContent -Encoding UTF8

# ── Step 8: Verify ────────────────────────────────────────────────────────────
& powershell -ExecutionPolicy Bypass -WindowStyle Hidden -NoProfile -File $scriptPath 2>&1 | Out-Null
Start-Sleep -Seconds 2
$current = (Get-AudioDevice -Playback).Name

if ($current -ne $selected.Name) {
    Show-Error "Setup completed, but we could not confirm your hearing aids are set as the audio output.`n`nMake sure they are connected and try double-clicking the shortcut on your Desktop."
}

# ── Step 9: Configure tray app script ────────────────────────────────────────
# The tray script ships as HearingAidTray.ps1 alongside this setup file.
# We inject the device name at install time and save a configured copy
# to the same folder rather than AppData, keeping execution in a
# user-chosen trusted location and avoiding AppData-based AV flags.
$trayScriptPath = Join-Path $PSScriptRoot "HearingAidTray.ps1"
$trayConfigPath = Join-Path $PSScriptRoot "HearingAidTray-Configured.ps1"

if (Test-Path $trayScriptPath) {
    $trayContent = (Get-Content $trayScriptPath -Raw) -replace 'HEARING_AID_DEVICE_NAME', $selected.Name
    Set-Content -Path $trayConfigPath -Value $trayContent -Encoding UTF8
} else {
    # Fallback — write inline if template not found
    $trayConfigPath = Join-Path $PSScriptRoot "HearingAidTray-Configured.ps1"
    $trayContent = (Get-Content "$PSScriptRoot\HearingAidTray.ps1" -Raw -ErrorAction SilentlyContinue)
    if ($trayContent) {
        $trayContent = $trayContent -replace 'HEARING_AID_DEVICE_NAME', $selected.Name
        Set-Content -Path $trayConfigPath -Value $trayContent -Encoding UTF8
    }
}

# ── Step 10: Create Desktop shortcut (fallback) ───────────────────────────────
$shortcutPath = "$env:USERPROFILE\Desktop\Set Hearing Aid Audio Output.lnk"
$wsh = New-Object -ComObject WScript.Shell
$sc  = $wsh.CreateShortcut($shortcutPath)
$sc.TargetPath   = "powershell.exe"
$sc.Arguments    = "-ExecutionPolicy Bypass -WindowStyle Hidden -File `"$scriptPath`""
$sc.IconLocation = "mmres.dll,0"
$sc.Save()

# ── Step 11: Register Task Scheduler jobs ─────────────────────────────────────
try {
    # Unlock enforcer (existing)
    $unlockXml = @"
<?xml version="1.0" encoding="UTF-16"?>
<Task version="1.4" xmlns="http://schemas.microsoft.com/windows/2004/02/mit/task">
  <Triggers>
    <EventTrigger>
      <Enabled>true</Enabled>
      <Subscription>&lt;QueryList&gt;&lt;Query Id="0" Path="Security"&gt;&lt;Select Path="Security"&gt;*[System[EventID=4801]]&lt;/Select&gt;&lt;/Query&gt;&lt;/QueryList&gt;</Subscription>
      <Delay>PT5S</Delay>
    </EventTrigger>
  </Triggers>
  <Principals>
    <Principal id="Author">
      <UserId>$env:USERDOMAIN\$env:USERNAME</UserId>
      <LogonType>InteractiveToken</LogonType>
      <RunLevel>LeastPrivilege</RunLevel>
    </Principal>
  </Principals>
  <Settings>
    <MultipleInstancesPolicy>IgnoreNew</MultipleInstancesPolicy>
    <DisallowStartIfOnBatteries>false</DisallowStartIfOnBatteries>
    <StopIfGoingOnBatteries>false</StopIfGoingOnBatteries>
    <ExecutionTimeLimit>PT1M</ExecutionTimeLimit>
    <Priority>7</Priority>
  </Settings>
  <Actions>
    <Exec>
      <Command>powershell.exe</Command>
      <Arguments>-ExecutionPolicy Bypass -WindowStyle Hidden -File "$scriptPath" -Auto</Arguments>
    </Exec>
  </Actions>
</Task>
"@
    Register-ScheduledTask -TaskName $taskName -Xml $unlockXml -Force | Out-Null

    # Tray app startup task
    $trayTaskName = "HearingAidAudioTray"
    Unregister-ScheduledTask -TaskName $trayTaskName -Confirm:$false -ErrorAction SilentlyContinue
    $trayXml = @"
<?xml version="1.0" encoding="UTF-16"?>
<Task version="1.4" xmlns="http://schemas.microsoft.com/windows/2004/02/mit/task">
  <Triggers>
    <LogonTrigger>
      <Enabled>true</Enabled>
      <Delay>PT10S</Delay>
    </LogonTrigger>
  </Triggers>
  <Principals>
    <Principal id="Author">
      <UserId>$env:USERDOMAIN\$env:USERNAME</UserId>
      <LogonType>InteractiveToken</LogonType>
      <RunLevel>LeastPrivilege</RunLevel>
    </Principal>
  </Principals>
  <Settings>
    <MultipleInstancesPolicy>IgnoreNew</MultipleInstancesPolicy>
    <DisallowStartIfOnBatteries>false</DisallowStartIfOnBatteries>
    <StopIfGoingOnBatteries>false</StopIfGoingOnBatteries>
    <ExecutionTimeLimit>PT0S</ExecutionTimeLimit>
    <Priority>7</Priority>
  </Settings>
  <Actions>
    <Exec>
      <Command>powershell.exe</Command>
      <Arguments>-ExecutionPolicy Bypass -WindowStyle Hidden -File "$trayConfigPath"</Arguments>
    </Exec>
  </Actions>
</Task>
"@
    Register-ScheduledTask -TaskName $trayTaskName -Xml $trayXml -Force | Out-Null

    # Launch tray app immediately without waiting for reboot
    Start-Process powershell -ArgumentList "-ExecutionPolicy Bypass -WindowStyle Hidden -File `"$trayConfigPath`"" -WindowStyle Hidden

} catch {
    # Non-fatal — setup still succeeded
}

# ── Step 11: Done ─────────────────────────────────────────────────────────────
Show-DoneForm
