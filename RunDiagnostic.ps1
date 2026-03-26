#Run-Diagnostic.ps1
#Requires -Version 5.1
<#
.SYNOPSIS
    Hearing Aid Audio Setup — Diagnostic Tool.
    Collects system and Bluetooth audio state information for testing
    and issue reporting. Makes no changes to the system.

.USAGE
    powershell -ExecutionPolicy Bypass -File Run-Diagnostic.ps1

.NOTES
    Author:      Deep Coast Engineering
    License:     CC BY-NC 4.0
    Repository:  https://github.com/deep-coast-eng/BT-Hearing-Aids-Setup

    This script collects only the information needed to diagnose
    Bluetooth audio setup issues. It does not collect usernames,
    hostnames, hardware serials, or any personally identifying information.
    No changes are made to the system.

.VERSION HISTORY
    1.0.0   Initial release
#>

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$TITLE      = "Hearing Aid Audio — Diagnostic"
$VERSION    = "1.0.0"
$outputPath = "$env:USERPROFILE\Desktop\HearingAidAudio-Diagnostic.txt"
$lines      = [System.Collections.Generic.List[string]]::new()

function Add-Line {
    param([string]$Text = "")
    $lines.Add($Text)
}

# ── Header ────────────────────────────────────────────────────────────────────
Add-Line "======================================================"
Add-Line " Hearing Aid Audio Setup — Diagnostic Report"
Add-Line " Tool Version: $VERSION"
Add-Line " Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
Add-Line "======================================================"
Add-Line ""

# ── Windows version ───────────────────────────────────────────────────────────
Add-Line "--- Windows ---"
try {
    $build   = [System.Environment]::OSVersion.Version.Build
    $winVer  = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion").DisplayVersion
    $edition = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion").EditionID
    Add-Line "Version:      $winVer"
    Add-Line "Build:        $build"
    Add-Line "Edition:      $edition"
    Add-Line "Win11:        $(if ($build -ge 22000) { 'Yes' } else { 'No' })"
    Add-Line "24H2+:        $(if ($build -ge 26100) { 'Yes' } else { 'No' })"
} catch {
    Add-Line "ERROR reading Windows version: $_"
}
Add-Line ""

# ── Bluetooth adapter ─────────────────────────────────────────────────────────
Add-Line "--- Bluetooth Adapter ---"
try {
    $btAdapters = Get-PnpDevice | Where-Object { $_.Class -eq "Bluetooth" -and $_.Status -eq "OK" } |
                  Select-Object -Unique FriendlyName, Status
    if ($btAdapters) {
        foreach ($a in $btAdapters) {
            Add-Line "Adapter:      $($a.FriendlyName) [$($a.Status)]"
        }
    } else {
        Add-Line "Adapter:      None found with OK status"
    }
} catch {
    Add-Line "ERROR reading Bluetooth adapters: $_"
}
Add-Line ""

# ── LE Audio toggle ───────────────────────────────────────────────────────────
Add-Line "--- LE Audio ---"
Add-Line "To verify LE Audio support, check manually:"
Add-Line "Settings → Bluetooth & devices → Devices → 'Use LE Audio when available'"
Add-Line "If that toggle is present and on, LE Audio is supported on this machine."
Add-Line ""

# ── Bluetooth service ─────────────────────────────────────────────────────────
Add-Line "--- Bluetooth Service ---"
try {
    $svc = Get-Service -Name bthserv -ErrorAction SilentlyContinue
    Add-Line "bthserv status: $(if ($svc) { $svc.Status } else { 'Not found' })"
} catch {
    Add-Line "ERROR reading Bluetooth service: $_"
}
Add-Line ""

# ── Audio playback devices ────────────────────────────────────────────────────
Add-Line "--- Audio Playback Devices ---"
try {
    $modInstalled = $null -ne (Get-Module -ListAvailable -Name AudioDeviceCmdlets)
    Add-Line "AudioDeviceCmdlets installed: $(if ($modInstalled) { 'Yes' } else { 'No' })"
    if ($modInstalled) {
        Import-Module AudioDeviceCmdlets -ErrorAction SilentlyContinue
        $devices = Get-AudioDevice -List | Where-Object { $_.Type -eq 'Playback' }
        if ($devices) {
            foreach ($d in $devices) {
                $marker = if ($d.Default) { "[DEFAULT]" } else { "         " }
                Add-Line "$marker  $($d.Name)"
            }
        } else {
            Add-Line "No playback devices found"
        }
        Add-Line ""
        Add-Line "Current default output: $((Get-AudioDevice -Playback).Name)"
    }
} catch {
    Add-Line "ERROR reading audio devices: $_"
}
Add-Line ""

# ── Installed scripts and shortcuts ──────────────────────────────────────────
Add-Line "--- Setup Artifacts ---"
$shortcuts = Get-ChildItem "$env:USERPROFILE\Desktop\*.lnk" -ErrorAction SilentlyContinue |
             Where-Object { $_.Name -match "Hearing Aid" }
Add-Line "Desktop shortcut:     $(if ($shortcuts) { $shortcuts.Name -join ', ' } else { 'Not found' })"

$enforcers = Get-ChildItem "$env:USERPROFILE\Desktop\Set-*-Output.ps1" -ErrorAction SilentlyContinue
Add-Line "Enforcer script:      $(if ($enforcers) { $enforcers.Name -join ', ' } else { 'Not found' })"

$trayScript = Join-Path $PSScriptRoot "HearingAidTray-Configured.ps1"
Add-Line "Tray script:          $(if (Test-Path $trayScript) { 'Found' } else { 'Not found' })"
Add-Line ""

# ── Scheduled tasks ───────────────────────────────────────────────────────────
Add-Line "--- Scheduled Tasks ---"
try {
    $enforceTask = Get-ScheduledTask -TaskName "HearingAidAudioEnforcer" -ErrorAction SilentlyContinue
    Add-Line "Unlock enforcer task: $(if ($enforceTask) { $enforceTask.State } else { 'Not registered' })"

    $trayTask = Get-ScheduledTask -TaskName "HearingAidAudioTray" -ErrorAction SilentlyContinue
    Add-Line "Tray startup task:    $(if ($trayTask) { $trayTask.State } else { 'Not registered' })"
} catch {
    Add-Line "ERROR reading scheduled tasks: $_"
}
Add-Line ""

# ── Unlock event log check ────────────────────────────────────────────────────
Add-Line "--- Unlock Event Log (Event ID 4801) ---"
Add-Line "Note: Event ID 4801 requires audit policy to be enabled."
Add-Line "On most home machines this is off by default."
Add-Line "If the unlock trigger is not working, check:"
Add-Line "Local Security Policy → Local Policies → Audit Policy → Audit logon events → Success"
Add-Line ""

# ── Footer ────────────────────────────────────────────────────────────────────
Add-Line "======================================================"
Add-Line " End of diagnostic report"
Add-Line " Please attach this file to your GitHub issue at:"
Add-Line " https://github.com/deep-coast-eng/BT-Hearing-Aids-Setup/issues"
Add-Line "======================================================"

# ── Save to Desktop ───────────────────────────────────────────────────────────
$report = $lines -join "`r`n"
Set-Content -Path $outputPath -Value $report -Encoding UTF8

# ── Show popup ────────────────────────────────────────────────────────────────
$form = New-Object System.Windows.Forms.Form
$form.Text = $TITLE
$form.Size = New-Object System.Drawing.Size(580, 500)
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = "FixedDialog"
$form.MaximizeBox = $false

$label = New-Object System.Windows.Forms.Label
$label.Text = "Diagnostic complete. A copy has been saved to your Desktop as:`nHearingAidAudio-Diagnostic.txt"
$label.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$label.Location = New-Object System.Drawing.Point(16, 12)
$label.Size = New-Object System.Drawing.Size(540, 36)
$form.Controls.Add($label)

$box = New-Object System.Windows.Forms.TextBox
$box.Multiline = $true
$box.ScrollBars = "Vertical"
$box.ReadOnly = $true
$box.Font = New-Object System.Drawing.Font("Consolas", 8)
$box.Location = New-Object System.Drawing.Point(16, 54)
$box.Size = New-Object System.Drawing.Size(540, 360)
$box.Text = $report
$form.Controls.Add($box)

$btnCopy = New-Object System.Windows.Forms.Button
$btnCopy.Text = "Copy to Clipboard"
$btnCopy.Size = New-Object System.Drawing.Size(140, 28)
$btnCopy.Location = New-Object System.Drawing.Point(16, 424)
$btnCopy.Add_Click({ [System.Windows.Forms.Clipboard]::SetText($report) })
$form.Controls.Add($btnCopy)

$btnClose = New-Object System.Windows.Forms.Button
$btnClose.Text = "Close"
$btnClose.Size = New-Object System.Drawing.Size(80, 28)
$btnClose.Location = New-Object System.Drawing.Point(476, 424)
$btnClose.Add_Click({ $form.Close() })
$form.Controls.Add($btnClose)
$form.AcceptButton = $btnClose

$form.ShowDialog() | Out-Null
