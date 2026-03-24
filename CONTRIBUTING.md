# Contributing to Hearing Aid Audio Setup

Thank you for helping improve this tool. It was built for people who need it to just work — contributions that improve reliability, accessibility, and plain-language communication are especially welcome.

---

## Reporting an Issue

If something is not working, please [open an issue](https://github.com/deep-coast-eng/BT-Hearing-Aids-Setup/issues) and include the following:

- **Windows version** — go to Settings → System → About and copy the Version and OS Build fields
- **Hearing aid brand and model** — found on the hearing aid packaging or your audiologist's paperwork
- **What happened** — describe what you did and what the script showed or did not show
- **What you expected to happen**
- **Any error messages** — copy the exact text if possible

The more detail you include, the faster the issue can be diagnosed.

---

## Suggesting an Improvement

Open an issue and describe what you would like to see changed and why. No coding required to suggest an improvement — plain-language descriptions are welcome.

---

## Testing

If you would like to help validate the tool before broader release, see the [Testing Rubric](https://claude.ai/chat/docs/testing-rubric.md). It covers compatibility checks, setup wizard behavior, tray icon states, the unlock trigger, edge cases, and an accessibility review section suitable for non-technical testers.

---

## Submitting a Pull Request

If you would like to contribute code:

1. Fork the repository
2. Create a branch named for your change (e.g. `fix-tray-icon-state` or `add-french-language`)
3. Make your changes
4. Test on at least one real machine with a connected Bluetooth audio device
5. Submit a pull request with a short description of what changed and why

**A few things to keep in mind:**

- This tool is used by non-technical people. Plain language in all user-facing text is a priority — avoid technical terms in popups, prompts, and error messages
- All user interaction should remain in GUI dialogs (Windows Forms). No console output for end users
- The numbered step comments in `Setup-BTHearingAids.ps1` are intentional — they help non-developer contributors follow the flow. Please maintain them for new steps
- Test compatibility check failures as well as successes — the failure paths matter as much as the happy path for this audience
- If you add a new dependency, it must be free, installable without admin rights, and sourced from PowerShell Gallery or a similarly trusted source

---

## Tested Hardware

If you test this on hardware not listed in the README, please open an issue or PR to add it to the Tested On section. Include:

- Laptop make and model
- Windows version and build
- Hearing aid brand and model
- Whether it worked, and any notes

---

## License

By contributing, you agree that your contributions will be licensed under the same [CC BY-NC 4.0](https://creativecommons.org/licenses/by-nc/4.0/) license as the rest of the project.