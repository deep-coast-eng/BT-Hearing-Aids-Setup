# Hearing Aid Audio Setup for Windows 11

A PowerShell setup wizard that detects paired Bluetooth hearing aids (or any Bluetooth audio device), sets them as the default audio output, adds a system tray icon for status and quick switching, and automatically re-enforces audio routing each time you unlock your screen.

Built for people who use Bluetooth hearing aids with a Windows 11 laptop and need a reliable, repeatable way to route audio to their device after reconnecting.

Not sure if your equipment qualifies? See the [Compatibility Guide](docs/compatibility-guide.md).

---

## The Problem

Windows 11 supports Bluetooth LE Audio for hearing aids, but it does not reliably set them as the default audio output when they reconnect — especially when the same hearing aids are also paired to a phone or tablet. This is a known issue affecting Philips, Phonak, Oticon, and other hearing aid brands on Windows 11.

This tool solves that with a setup wizard, a system tray icon, and automatic background enforcement.

---

## Requirements

| Requirement | Details |
|---|---|
| Windows 11 24H2 or later | Build 26100+. Required for Bluetooth LE Audio support. |
| Bluetooth LE Audio hardware | Your PC's Bluetooth adapter must support LE Audio. Check Settings → Bluetooth & devices → Devices for a "Use LE Audio when available" toggle. If it is not there, your hardware may not be compatible. |
| Bluetooth LE Audio hearing aids | Your hearing aids must support Bluetooth LE Audio. Compatible brands include Philips, Oticon, ReSound, and Beltone, but not every model qualifies — check your specific device. |
| PowerShell 5.1 | Included with Windows 11. No additional install needed. |
| Internet connection | Required during first-time setup only, to install AudioDeviceCmdlets from PowerShell Gallery. |

---

## Quick Start

1. Download all files into the same folder on your computer
2. Make sure your hearing aids are connected via Bluetooth (Settings → Bluetooth & devices)
3. Turn off Bluetooth on your phone or tablet
4. Double-click **Run-Setup.bat**

The setup wizard will guide you through everything with simple dialog boxes — no command line interaction required.

---

## Not Sure If Your Computer Is Compatible?

Double-click **Check-Compatibility.bat** before running setup. It checks your system and shows a plain-language result for each requirement without installing or changing anything.

---

## What Setup Does

**During setup:**
- Asks you to turn off Bluetooth on nearby mobile devices before proceeding
- Detects whether setup has already been run and confirms before making changes
- Checks system compatibility with a plain-language result for each requirement
- If anything does not qualify, shows a clear explanation and next steps — then stops
- Offers to install the required audio control tool if it is not already present
- Detects your connected Bluetooth audio device; if more than one is found, asks you to pick
- Sets your hearing aids as the default audio and verifies it worked
- Adds a system tray icon to your taskbar (bottom-right corner)
- Registers an automatic background check that runs every time you unlock your screen
- Keeps a Desktop shortcut as a manual fallback

**The system tray icon:**
- Starts automatically when you log into Windows
- Shows connection status at a glance
- Left-click opens a small menu to check status or switch audio to your hearing aids
- Does not interrupt you or show popups unless you interact with it

**Tray icon states:**
| Icon color | Meaning |
|---|---|
| 🟢 Green | Hearing aids are connected and active as the audio output |
| 🔵 Blue | Hearing aids are connected but something else is the active output — click to switch back |
| ⚫ Grey | Hearing aids are not connected |

**The automatic unlock check:**
- Runs silently 5 seconds after you unlock your screen
- Re-enforces hearing aids as the audio output only if they were already active before you locked
- Respects manual device switches — if you chose a headset, it will not override that choice
- Does nothing if hearing aids are not connected

**The Desktop shortcut:**
- Manual override — always forces hearing aids as the audio output regardless of what is currently active
- Use this when you want to switch back to hearing aids after using another device

---

## Files Included

| File | Purpose |
|---|---|
| `Run-Setup.bat` | Double-click to run the full setup wizard |
| `Check-Compatibility.bat` | Double-click to check compatibility only — no changes made |
| `Run-Diagnostic.bat` | Double-click to run the diagnostic tool for testing and issue reporting |
| `Setup-BTAudioShortcut.ps1` | The setup script. Both setup `.bat` files run this automatically |
| `HearingAidTray.ps1` | The system tray app. Installed automatically during setup |
| `Run-Diagnostic.ps1` | The diagnostic script. Run-Diagnostic.bat runs this automatically |

---

## When to Re-Run Setup

The tray icon, Desktop shortcut, and automatic unlock check handle day-to-day use. Run **Run-Setup.bat** again if:

- You got new hearing aids
- Your hearing aids were re-paired to your computer
- A Windows update changed your audio settings and things stop working
- You were told to re-run setup by whoever set this up for you

---

## Troubleshooting

**The compatibility check says my computer does not qualify**

The check will tell you specifically what failed. Common causes:
- Windows needs to be updated — go to Settings → Windows Update and install all available updates
- No Bluetooth hardware found — this computer may not be compatible without a hardware upgrade
- Bluetooth is not running — try restarting the computer and running setup again
- Hearing aids not detected — make sure they are connected (Settings → Bluetooth & devices) and your phone Bluetooth is off

**My hearing aids connect but do not appear during setup**

Your phone may still be connected to them. Turn off Bluetooth on your phone, wait a few seconds, and run setup again.

**The tray icon is grey but my hearing aids are connected**

Windows may not have registered the audio endpoint yet. Wait a few seconds and click the tray icon again. If it stays grey, go to Settings → Bluetooth & devices and confirm your hearing aids show as connected there.

**The tray icon is blue — hearing aids connected but not active**

Click the tray icon and select Switch to Hearing Aids. If that does not work, double-click the Desktop shortcut as a fallback.

**The unlock check is not switching back to my hearing aids**

This is by design — the unlock check only re-enforces hearing aids if they were already the active output before you locked. If you manually switched to another device, use the tray icon or Desktop shortcut to switch back.

**The tray icon is not showing on a work or managed computer**

Some organizations restrict scripts from running out of the AppData folder using AppLocker or similar policies. This is a known limitation on managed machines and does not affect the Desktop shortcut or the unlock trigger. The shortcut remains fully functional as a manual fallback.

**The tray icon is not showing in the taskbar**

It may be hidden in the overflow area. Click the up arrow (^) in the bottom-right corner of your taskbar to see hidden tray icons. If it is not there, try restarting your computer — the tray app starts automatically at login.

**The shortcut runs but audio still comes through the speakers**

Check that your hearing aids appear as connected under Settings → Bluetooth & devices, then try the tray icon or Desktop shortcut again.

**The audio control tool could not be installed**

This is usually caused by no internet connection or a restriction set by your organization. Check your connection and try again, or ask your IT support for help.

**The "Use LE Audio when available" toggle is missing from Bluetooth settings**

Your Bluetooth hardware does not support LE Audio. Your hearing aids will not work as a Windows audio device without a compatible adapter or driver update. Contact your PC manufacturer or IT support.

**I am not sure what to do**

Ask your IT support or a family member for help. For technical support, visit the [Issues page](https://github.com/deep-coast-eng/BT-Hearing-Aids-Setup/issues).

---

## Windows Security Warning

Windows may flag these files when downloaded from the internet. This is a standard warning for all PowerShell scripts and is not specific to this tool. The source code is fully visible in this repository for review.

All scripts run from the folder you downloaded them to — nothing is installed to system directories or AppData. The tray app runs from the same folder as the rest of the files.

The setup script requests administrator permission once to register scheduled tasks. This is the only time elevated rights are needed. A plain-language explanation appears before the Windows security prompt.

All bat files use `-ExecutionPolicy Bypass` to allow the scripts to run without modifying your system's PowerShell policy. This is standard practice for distributed PowerShell tools and does not change any system settings.

SHA256 hashes for each release are listed on the [Releases page](https://github.com/deep-coast-eng/BT-Hearing-Aids-Setup/releases) so you can verify your download has not been modified.

If your antivirus blocks the download, download the raw files directly from GitHub using the **Raw** button on each file page.

---

## Dependencies

- [AudioDeviceCmdlets](https://github.com/frgnca/AudioDeviceCmdlets) — MIT licensed, installed automatically during setup

---

## Tested On

- Framework Laptop 16 (AMD Ryzen AI 370)
- Windows 11 24H2
- Philips hearing aids (Bluetooth LE Audio, dual device)

Other hardware that meets the requirements above should work. If you test on additional hardware, feel free to open an issue or PR to expand this list.

---

## Contributing

Contributions are welcome. See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines on reporting issues, suggesting improvements, and submitting pull requests.

If you would like to help test the tool before broader release, see the [Testing Rubric](docs/testing-rubric.md).

For planned improvements and known limitations, see the [Roadmap](ROADMAP.md).

---

## Support & Accessibility
I built this tool to solve a specific gap in Windows 11 Bluetooth LE support for hearing aid users - I use this tool personally, and want to share it with others. If this saved you time or improved your experience, feel free to drop a tip.

**Privacy-First Donations (Crypto):**
* **XRP (preferred):** `rwnYLUsoBQX3ECa1A5bSKLdbPoHKnqf63J` (use memo below - this is required for sending XRP on Conibase)
  * XRP Destination Tag/Memo:** `3960821948` (Required for Coinbase!)
* **BTC:** `37g1HBnGs8W37WDGsNDWYTAKyupjFZCPgi`
* **ETH/ERC-20:** `0xB123ffDd271f86f9d8eD8037Ba9b47Ed68526675`
* **SOL:** `HUQfdk4V6QMyu58Sd9XbHX9L3mY8gPs71VwCbnybPvZU`

*No pressure—stars and feedback are just as appreciated!*

---

## License

[CC BY-NC 4.0](https://creativecommons.org/licenses/by-nc/4.0/) — Free for personal and non-commercial use with attribution to Deep Coast Engineering.

For commercial licensing, contact: https://github.com/DeepCoastEngineering

---

*Made by [Deep Coast Engineering](https://github.com/DeepCoastEngineering)*
