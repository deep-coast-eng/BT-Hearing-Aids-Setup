# Roadmap

This file tracks planned improvements and known areas for future development. Items are not guaranteed or time-bound — this is a free, open source project maintained in spare time.

Community contributions toward any of these items are welcome. See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

---

## v1.1 — Planned

**Consolidated setup wizard UI**
Currently the setup flow presents several sequential dialog boxes after the UAC prompt — compatibility results, install confirmation, device selection, and verification. A future version will consolidate these into a single multi-step wizard window with a progress bar, reducing the number of popups and making the experience feel more cohesive, particularly for non-technical users.

---

## Future Considerations

**Compiled .exe distribution**
Packaging the tool as a signed `.exe` would eliminate antivirus false positives on download and remove the need for users to interact with PowerShell execution policy. This requires a code signing certificate and will be considered once the project has demonstrated sufficient adoption to justify the cost.

**Multi-device support**
Currently the tool supports one registered hearing aid device per user. A future version could allow multiple devices to be registered with priority ordering — useful for users with both hearing aids and a backup headset.

**Uninstaller**
A dedicated uninstall script or bat file to cleanly remove all scheduled tasks, tray scripts, enforcer scripts, and shortcuts in one step.

---

## Known Limitations

- Tray icon may not appear on first run on corporate/managed machines due to AppLocker or execution policy evaluation delay. A reboot or manual launch resolves this.
- Tray icon may be blocked entirely on machines with strict execution policy restrictions. The Desktop shortcut and unlock trigger remain functional in this case.
- The unlock trigger (Event ID 4801) requires audit policy to be enabled. On some home machines this is off by default and the trigger will not fire.
- The tool supports Windows 11 24H2 and later only. Bluetooth LE Audio is not available on earlier versions.
- All bat files use `-ExecutionPolicy Bypass` to allow scripts to run. This is standard practice and does not modify system PowerShell policy, but may be flagged on corporate machines.