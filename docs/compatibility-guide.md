# Does My Equipment Work With This?

Before using this tool, you need two things to be true:

1. Your **hearing aids** support Bluetooth LE Audio
2. Your **Windows 11 laptop or desktop** supports Bluetooth LE Audio

Both have to match. Having one without the other won't work.

---

## Checking Your Hearing Aids

Bluetooth has been in hearing aids for years, but there are different versions of it — and not all of them work with Windows.

The version you need is called **Bluetooth LE Audio**. It is a newer standard that hearing aid manufacturers started building into devices in early 2024. Older hearing aids that connect to iPhones or Android phones often use a different standard (called MFi or ASHA) that Windows does not support, even if the box says "Bluetooth."

**What to look for:**

- Check your hearing aid's packaging or manual for the phrase **"Bluetooth LE Audio"**
- If you are not sure, call your audiologist or the manufacturer and ask: _"Do my hearing aids support Bluetooth LE Audio for direct streaming to a Windows PC?"_
- Brands that have confirmed LE Audio models include Philips, ReSound, Beltone, and Oticon — but not every model from these brands qualifies, so check your specific model

**Helpful resource:** [HearingTracker](https://www.hearingtracker.com/) is an independent website that reviews hearing aids and covers compatibility in plain language. It is a good starting point if you are researching a new device or are unsure about your current one.

---

## Checking Your Computer

Not every Windows 11 computer supports Bluetooth LE Audio either. Support depends on the specific Bluetooth hardware inside your machine, and Windows PCs with LE Audio support largely started appearing in 2024.

**The quickest way to check:**

1. Click the **Start menu** and open **Settings**
2. Go to **Bluetooth & devices**, then click **Devices**
3. Scroll down and look for a setting called **"Use LE Audio when available"**

If you see that setting, your computer is compatible. If you do not see it, your computer does not currently support Bluetooth LE Audio and this tool will not be able to help without a hardware upgrade.

**Official Microsoft guides:**

- [Check if your Windows 11 PC supports Bluetooth LE Audio](https://support.microsoft.com/en-us/windows/check-if-a-windows-11-device-supports-bluetooth-low-energy-audio-2b79c085-0353-4467-8306-ebb2657a91de) — step-by-step instructions to find out if your computer qualifies
    
- [Using hearing devices with your Windows 11 PC](https://support.microsoft.com/en-us/windows/using-hearing-devices-with-your-windows-11-pc-fcb566e7-13c3-491a-ad5b-8219b098d647) — Microsoft's official guide for pairing and connecting hearing aids to Windows
    

---

## Quick Reference

||What you need|How to check|
|---|---|---|
|**Hearing aids**|Bluetooth LE Audio support|Look for "LE Audio" in the specs or ask your audiologist|
|**Windows PC**|Windows 11 24H2 or later + LE Audio hardware|Look for "Use LE Audio when available" in Bluetooth settings|

---

## Still Not Sure?

Run the setup tool with the compatibility check flag and it will tell you exactly what your computer supports before making any changes:

```powershell
powershell -ExecutionPolicy Bypass -File Setup-BTHearingAids.ps1 -CheckOnly
```

This is safe to run — it checks your system and shows results without installing or changing anything.