@echo off
rem CloudDeck Windows Installer Wrapper
echo Launching CloudDeck Windows Installer...
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0install.ps1"
pause
