# ==============================================================================
# CloudDeck Windows Automated Installer
# ==============================================================================
# Integrates CloudDeck, GeForce NOW, Xbox Cloud, Boosteroid, Shadow, and
# Moonlight into Steam on Windows with high-resolution grid artwork.
# ==============================================================================

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$InstallDir = "$env:LOCALAPPDATA\CloudDeck"
$BinDir = "$InstallDir\bin"

Write-Host ""
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host " CloudDeck: Universal Windows & Steam Integration Suite   " -ForegroundColor Green
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host ""

# 1. Directory Structure
Write-Host "[1/4] Preparing directories..." -ForegroundColor Yellow
New-Item -ItemType Directory -Force -Path $InstallDir | Out-Null
New-Item -ItemType Directory -Force -Path $BinDir | Out-Null
New-Item -ItemType Directory -Force -Path "$InstallDir\assets" | Out-Null
New-Item -ItemType Directory -Force -Path "$InstallDir\lib" | Out-Null

# 2. Deploy Files
Write-Host "[2/4] Deploying launcher and assets..." -ForegroundColor Yellow
Copy-Item -Recurse -Force "$ScriptDir\bin\*" "$BinDir\"
Copy-Item -Recurse -Force "$ScriptDir\assets\*" "$InstallDir\assets\"
Copy-Item -Recurse -Force "$ScriptDir\lib\*" "$InstallDir\lib\"
Write-Host "  Deployed launcher to $BinDir\cloud-launcher.bat" -ForegroundColor Green

# 3. Inject Steam Shortcuts
Write-Host "[3/4] Injecting Steam shortcuts and grid artwork..." -ForegroundColor Yellow
$PythonCmd = Get-Command python, python3 -ErrorAction SilentlyContinue | Select-Object -First 1

if ($PythonCmd) {
    & $PythonCmd.Source "$InstallDir\lib\steam_shortcuts_manager.py" `
        --launcher-exe "$BinDir\cloud-launcher.bat" `
        --artwork-dir "$InstallDir\assets\artwork"
    Write-Host "  Successfully injected Steam shortcuts and artwork!" -ForegroundColor Green
} else {
    Write-Host "  Notice: Python not detected on PATH. Shortcuts can also be run directly from $BinDir." -ForegroundColor Yellow
}

# 4. Finish
Write-Host ""
Write-Host "==========================================================" -ForegroundColor Green
Write-Host " CloudDeck Windows Installation Completed!                " -ForegroundColor Green
Write-Host "==========================================================" -ForegroundColor Green
Write-Host "Restart Steam to see your new cloud gaming shortcuts!"
Write-Host ""
