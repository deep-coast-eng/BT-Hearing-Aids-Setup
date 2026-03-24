@echo off
powershell -ExecutionPolicy Bypass -Command "Start-Process powershell -ArgumentList '-ExecutionPolicy Bypass -WindowStyle Hidden -File ""%~dp0Setup-BTHearingAids.ps1""' -WindowStyle Hidden"
