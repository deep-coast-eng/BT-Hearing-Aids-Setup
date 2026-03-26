#HearingAidTray.ps1
#Requires -Version 5.1
<#
.SYNOPSIS
    Hearing Aid Audio — System Tray App.
    Runs at startup, monitors Bluetooth hearing aid connection status,
    and allows one-click audio output switching from the system tray.

.NOTES
    Author:      Deep Coast Engineering
    License:     CC BY-NC 4.0
    Repository:  https://github.com/deep-coast-eng/BT-Hearing-Aids-Setup
    Version:     1.0.0

    This script is generated and installed by Setup-BTAudioShortcut.ps1.
    The DeviceName parameter is injected automatically during setup.
    Do not edit the installed copy directly — re-run setup to update.

.VERSION HISTORY
    1.0.0   Initial release
            - Three-state tray icon (active/connected/disconnected)
            - Left-click menu with status and quick switch
            - 10-second poll timer for connection status updates
            - Silent — no popups unless user interacts
#>

param(
    [string]$DeviceName = "HEARING_AID_DEVICE_NAME"
)

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Import-Module AudioDeviceCmdlets -ErrorAction Stop

# ── Icons — drawn programmatically, no external files needed ─────────────────
function New-TrayIcon {
    param([string]$State) # "connected", "disconnected", "active"

    $bmp  = New-Object System.Drawing.Bitmap(16, 16)
    $g    = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $g.Clear([System.Drawing.Color]::Transparent)

    switch ($State) {
        "active" {
            # Green circle — hearing aids connected and active as audio output
            $g.FillEllipse([System.Drawing.Brushes]::LimeGreen, 1, 1, 13, 13)
            $g.DrawEllipse([System.Drawing.Pens]::DarkGreen, 1, 1, 13, 13)
        }
        "connected" {
            # Blue circle — hearing aids connected but not active audio output
            $g.FillEllipse([System.Drawing.Brushes]::DodgerBlue, 1, 1, 13, 13)
            $g.DrawEllipse([System.Drawing.Pens]::DarkBlue, 1, 1, 13, 13)
        }
        "disconnected" {
            # Grey circle — hearing aids not connected
            $g.FillEllipse([System.Drawing.Brushes]::LightGray, 1, 1, 13, 13)
            $g.DrawEllipse([System.Drawing.Pens]::Gray, 1, 1, 13, 13)
        }
    }

    $g.Dispose()
    return [System.Drawing.Icon]::FromHandle($bmp.GetHicon())
}

# ── State helpers ─────────────────────────────────────────────────────────────
function Get-HearingAidConnected {
    $device = Get-AudioDevice -List | Where-Object { $_.Type -eq 'Playback' -and $_.Name -eq $DeviceName }
    return $null -ne $device
}

function Get-HearingAidActive {
    return (Get-AudioDevice -Playback).Name -eq $DeviceName
}

function Set-HearingAidActive {
    $device = Get-AudioDevice -List | Where-Object { $_.Type -eq 'Playback' -and $_.Name -eq $DeviceName }
    if ($device) {
        Set-AudioDevice -Index $device.Index | Out-Null
        Set-AudioDevice -Index $device.Index -CommunicationOnly | Out-Null
        return $true
    }
    return $false
}

# ── Build tray ────────────────────────────────────────────────────────────────
$tray             = New-Object System.Windows.Forms.NotifyIcon
$tray.Visible     = $true
$tray.Text        = "Hearing Aid Audio"

$menu             = New-Object System.Windows.Forms.ContextMenuStrip

$itemStatus       = New-Object System.Windows.Forms.ToolStripMenuItem
$itemStatus.Text  = "Checking..."
$itemStatus.Enabled = $false
$menu.Items.Add($itemStatus) | Out-Null

$menu.Items.Add((New-Object System.Windows.Forms.ToolStripSeparator)) | Out-Null

$itemSwitch       = New-Object System.Windows.Forms.ToolStripMenuItem
$itemSwitch.Text  = "Switch to Hearing Aids"
$itemSwitch.Add_Click({
    $ok = Set-HearingAidActive
    if (-not $ok) {
        [System.Windows.Forms.MessageBox]::Show(
            "Your hearing aids could not be found.`n`nMake sure they are connected via Bluetooth (Settings → Bluetooth & devices), then try again.",
            "Hearing Aid Audio",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Warning
        ) | Out-Null
    }
    Update-TrayState
})
$menu.Items.Add($itemSwitch) | Out-Null

$menu.Items.Add((New-Object System.Windows.Forms.ToolStripSeparator)) | Out-Null

$itemExit         = New-Object System.Windows.Forms.ToolStripMenuItem
$itemExit.Text    = "Exit"
$itemExit.Add_Click({
    $tray.Visible = $false
    $tray.Dispose()
    [System.Windows.Forms.Application]::Exit()
})
$menu.Items.Add($itemExit) | Out-Null

$tray.ContextMenuStrip = $menu

# Left-click opens the menu directly
$tray.Add_MouseClick({
    param($s, $e)
    if ($e.Button -eq [System.Windows.Forms.MouseButtons]::Left) {
        Update-TrayState
        $tray.ContextMenuStrip.Show([System.Windows.Forms.Control]::MousePosition)
    }
})

# ── State update ──────────────────────────────────────────────────────────────
function Update-TrayState {
    $connected = Get-HearingAidConnected
    $active    = if ($connected) { Get-HearingAidActive } else { $false }

    if ($active) {
        $tray.Icon    = New-TrayIcon "active"
        $tray.Text    = "Hearing Aid Audio — Active"
        $itemStatus.Text   = "✔ Hearing aids are the audio output"
        $itemSwitch.Enabled = $false
        $itemSwitch.Text   = "Already active"
    } elseif ($connected) {
        $tray.Icon    = New-TrayIcon "connected"
        $tray.Text    = "Hearing Aid Audio — Connected, not active"
        $itemStatus.Text   = "◉ Hearing aids connected — not set as output"
        $itemSwitch.Enabled = $true
        $itemSwitch.Text   = "Switch to Hearing Aids"
    } else {
        $tray.Icon    = New-TrayIcon "disconnected"
        $tray.Text    = "Hearing Aid Audio — Not connected"
        $itemStatus.Text   = "○ Hearing aids not connected"
        $itemSwitch.Enabled = $false
        $itemSwitch.Text   = "Hearing aids not connected"
    }
}

# ── Poll timer — updates icon every 10 seconds ────────────────────────────────
$timer          = New-Object System.Windows.Forms.Timer
$timer.Interval = 10000
$timer.Add_Tick({ Update-TrayState })
$timer.Start()

# Initial state
Update-TrayState

# ── Run message loop ──────────────────────────────────────────────────────────
[System.Windows.Forms.Application]::Run()
