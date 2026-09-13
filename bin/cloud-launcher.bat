@echo off
rem CloudDeck Windows Launcher Batch Wrapper
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0cloud-launcher.ps1" %*
