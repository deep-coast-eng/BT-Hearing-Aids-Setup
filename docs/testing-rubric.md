# Testing Rubric — Hearing Aid Audio Setup

This document is for qualified testers helping validate the tool before broader release. Complete as many sections as your hardware allows and report results via the [Issues page](https://github.com/deep-coast-eng/BT-Hearing-Aids-Setup/issues).

---

## Automated Diagnostic

Before working through the manual checklist, run the diagnostic tool to automatically collect your system information. This saves time and ensures nothing is missed.

**To run it:**

1. Download `Run-Diagnostic.bat` from the repository into the same folder as the other files
2. Double-click **Run-Diagnostic.bat**
3. A report will appear on screen and be saved to your Desktop as `HearingAidAudio-Diagnostic.txt`
4. Attach the `.txt` file to your GitHub issue alongside your manual test results

**What it collects:**

- Windows version and build
- Bluetooth adapter name and status
- LE Audio support check (manual step — instructions provided in report)
- Bluetooth service status
- All audio playback devices and current default output
- Whether setup scripts and shortcuts are present
- Whether Task Scheduler jobs are registered
- Note on unlock event log audit policy requirement

**What it does not collect:**

- Usernames, hostnames, or hardware serial numbers
- Any personally identifying information

The diagnostic makes no changes to your system.

---

## Testing Checklist (Google Sheets)

A spreadsheet version of this rubric is available for testers who prefer to work in a shareable format.

**File:** `docs/testing-checklist.csv`

**To use it:**

1. Download `testing-checklist.csv` from the repository
2. Go to [Google Sheets](https://sheets.google.com/) and open a new spreadsheet
3. Go to File → Import, choose the CSV file, and select **Replace spreadsheet**
4. Fill in the Pass / Fail and Notes columns as you test
5. Share the completed sheet via the link in your GitHub issue report

---

## Tester Information

Please include this with your results:

|Field|Your Entry|
|---|---|
|Windows version and build||
|Laptop make and model||
|Bluetooth adapter (if known)||
|Hearing aid brand and model||
|Domain-joined or personal machine||
|Antivirus software in use||

---

## Section 1 — Compatibility Check

Run `Check-Compatibility.bat` before running setup.

|Test|Expected Result|Pass / Fail / Notes|
|---|---|---|
|Run on a qualifying machine|All checks show ✔ and confirmation message appears||
|Run on Windows 10 or older|Windows version shows ✘ with plain-language explanation||
|Run on Windows 11 pre-24H2|Version check shows ✘ with update instructions||
|Run with hearing aids disconnected|Hearing aids check shows ✘ with connection instructions||
|Run with phone Bluetooth on and aids connected to phone|Hearing aids check shows ✘||
|No changes made after check-only run|Confirm no shortcuts or tasks were created||

---

## Section 2 — Setup Wizard

Run `Run-Setup.bat` on a qualifying machine with hearing aids connected.

|Test|Expected Result|Pass / Fail / Notes|
|---|---|---|
|Mobile Bluetooth warning appears on first run|Dialog appears before any checks run||
|Answering No to mobile Bluetooth prompt|Setup exits cleanly with instructions||
|Compatibility results window appears|All checks show ✔ on qualifying hardware||
|AudioDeviceCmdlets not installed — install prompt appears|Prompt describes tool as free and safe||
|AudioDeviceCmdlets not installed — user declines|Setup exits cleanly with explanation||
|Single hearing aid device detected|Setup proceeds without device picker||
|Multiple Bluetooth audio devices detected|Device picker appears and correct device is selectable||
|Setup completes successfully|Done popup appears with tray icon note and support link||
|Support link in done popup is clickable|Opens correct GitHub page in browser||
|Desktop shortcut created|Shortcut appears on Desktop with audio icon||
|Enforcer script created|Script present at expected Desktop path||
|Tray icon appears after setup|Icon visible in system tray||
|UAC pre-warning appears before elevation prompt|Plain-language dialog appears before Windows UAC||

---

## Section 3 — Already-Run Detection

Run `Run-Setup.bat` a second time on the same machine.

|Test|Expected Result|Pass / Fail / Notes|
|---|---|---|
|Already-run prompt appears on second run|Dialog lists reasons to re-run in plain language||
|User selects No|Exits with message pointing to Desktop shortcut||
|User selects Yes|Setup runs again cleanly and old task is replaced||

---

## Section 4 — Tray Icon

With setup complete and hearing aids connected.

|Test|Expected Result|Pass / Fail / Notes|
|---|---|---|
|Green icon when hearing aids are active output|Green icon visible in tray||
|Blue icon when connected but not active|Switch to another device — icon turns blue within 10 seconds||
|Grey icon when hearing aids disconnected|Turn off hearing aids — icon turns grey within 10 seconds||
|Left-click opens menu|Menu appears with status and switch option||
|Status text matches icon state|Green = active / blue = not active / grey = not connected||
|Switch to Hearing Aids succeeds|Audio switches and icon turns green||
|Switch to Hearing Aids — aids not connected|Warning popup appears with connection instructions||
|Switch option disabled when already active or not connected|Menu item greyed out in both cases||
|Exit option closes tray app|Icon disappears from tray||
|Tray icon restarts after reboot|Icon present after full restart without re-running setup||
|Tray icon present after sleep/wake|Icon still visible and functional after laptop sleep||

---

## Section 5 — Unlock Trigger

|Test|Expected Result|Pass / Fail / Notes|
|---|---|---|
|Hearing aids active — lock and unlock|Hearing aids remain or are re-enforced within 5 seconds||
|Manually switch device — lock and unlock|Unlock trigger does NOT switch back to hearing aids||
|Lock with aids disconnected — reconnect before unlock|No unexpected switches on unlock||

---

## Section 6 — Edge Cases

|Test|Expected Result|Pass / Fail / Notes|
|---|---|---|
|Corporate machine with PSGallery restricted|Error message mentions organization restriction||
|No internet connection during install|Failure message is plain-language||
|Walk out of Bluetooth range mid-session|Tray icon updates to grey within 10 seconds||
|Return to Bluetooth range|Tray icon updates when hearing aids reconnect||
|Windows update installed — run shortcut after reboot|Shortcut still works and device name resolves||
|Setup run after re-pairing hearing aids|New enforcer script generated with correct device name||

---

## Section 7 — Accessibility Review

|Test|Expected Result|Pass / Fail / Notes|
|---|---|---|
|All prompts use plain language with no technical jargon|No unexplained terms in any dialog||
|Every failure message has a next step or help reference|No dead ends in any error state||
|Tray icon states are immediately understandable|Green/blue/grey meaning is intuitive without explanation||
|Setup completable without reading documentation|Wizard is self-explanatory from start to finish||

---

## Reporting Results

Please open an issue on GitHub and include:

- Your completed tester information table
- Pass/Fail/Notes for each test you completed
- The `HearingAidAudio-Diagnostic.txt` file from your Desktop
- Any unexpected behavior not covered by the rubric
- Your overall assessment of whether the tool is ready for broader release

Thank you for helping make this tool better for everyone who needs it.