# CloudDeck: SteamOS, Windows & macOS Cloud Gaming Suite

[![SteamOS Ready](https://img.shields.io/badge/SteamOS-3.4+-00ADEF?style=for-the-badge&logo=steam&logoColor=white)](https://store.steampowered.com/steamos)
[![Windows 10/11](https://img.shields.io/badge/Windows-10%2F11-0078D6?style=for-the-badge&logo=windows&logoColor=white)](#method-c-windows-1011-installation)
[![macOS Metal](https://img.shields.io/badge/macOS-Sonoma%2FSequoia-000000?style=for-the-badge&logo=apple&logoColor=white)](#method-d-macos-installation)
[![Decky Loader](https://img.shields.io/badge/Decky%20Loader-Plugin-00D26A?style=for-the-badge)](https://decky.xyz/)
[![Anti-Cheat](https://img.shields.io/badge/Anti--Cheat-100%25%20Ban--Safe-brightgreen?style=for-the-badge)](https://help.steampowered.com/en/faqs/view/65B4-2AA3-5F37-4227)
[![Hardware Decoders](https://img.shields.io/badge/Hardware%20Accel-VA--API%20%2F%20NVDEC%20%2F%20Metal-blueviolet?style=for-the-badge)](#key-features)
[![License](https://img.shields.io/badge/License-MIT-yellow?style=for-the-badge)](LICENSE)

An all-in-one integration suite for **SteamOS (Steam Deck LCD & OLED)**, **SteamOS on PC** (Bazzite, ChimeraOS, HoloISO, Arch/Fedora Linux PCs), **Windows 10/11 PCs**, and **macOS (Apple Silicon & Intel)** that directly embeds cloud gaming and remote streaming into **Steam Game Mode / Big Picture**. Seamlessly launch and play **any Windows game**—including titles with restrictive kernel anti-cheat systems like **Destiny 2 (BattlEye)**, **Fortnite (Easy Anti-Cheat)**, and **Call of Duty: Warzone (Ricochet)**—without risking account bans, OS hiccups, or input lag.

---

## 📸 Visual Overview & Architecture

### System Architecture & Anti-Cheat Routing

![CloudDeck System Architecture](assets/diagrams/architecture_flow.svg)

### Steam Deck & PC Game Mode Quick Access Menu (Decky Plugin)

![Decky Loader UI Mockup](assets/diagrams/game_mode_ui_mockup.svg)

### Controller & Handheld Mapping (Neptune / Xbox / DualSense)

![Steam Controller Layout](assets/diagrams/controller_layout.svg)

---

## 🛡️ Anti-Cheat & Ban Safety Posture

| Execution Method | Anti-Cheat Engine | Ban Risk | Status | Technical Explanation |
| --- | --- | --- | --- | --- |
| **Local Proton / Wine** | BattlEye / EAC / Ricochet | 🔴 **HIGH / IMMEDIATE BAN** | **PROHIBITED** | Bungie and publishers explicitly ban or block games like Destiny 2 on Proton; kernel hooks fail or trigger automated suspensions. |
| **CloudDeck Remote Stream** | Genuine Windows Host | 🟢 **ZERO BAN RISK** | **100% COMPLIANT** | The game client and BattlEye engine execute inside authorized Windows cloud datacenters or your own Windows PC. SteamOS, Windows, or Mac clients act strictly as authorized low-latency video and HID gamepad clients. |

---

## Key Features

* **Universal Cross-Platform Support**: Built for Steam Deck (LCD/OLED), SteamOS on desktop/laptop PCs (Bazzite, ChimeraOS, HoloISO), **Windows 10/11 PCs**, and **macOS** (Apple Silicon M1/M2/M3/M4 & Intel). Automatically scales to 720p, 1080p, 1440p, or 4K with high-refresh rate display support.
* **Play Any Windows Game**: Launch any Windows title by name (`--game "Cyberpunk 2077"`), steam library link, or stream your own Windows gaming PC directly via built-in Moonlight/Sunshine integration.
* **Zero-Hiccup Hardware Acceleration**: Dynamic GPU auto-detection for **AMD** (`radeonsi`), **Intel** (`iHD`), **NVIDIA** (`nvidia`/`NVDEC`), and **macOS** (`VideoToolbox`/`Metal`) for buttery-smooth 60/120 FPS streaming.
* **Anti-Stutter Performance Pipeline**: Automatically configures browser flags to eliminate background throttling, window occlusion delays, and audio buffer underruns.
* **Instant Non-Steam Game Injection**: Pure-Python binary VDF parser (`lib/vdf.py`) that safely reads and injects 9 pre-configured shortcuts into `shortcuts.vdf` with CRC32 AppID generation on SteamOS, Windows, and macOS.
* **28 High-Resolution Artwork Assets**: Complete custom artwork suite (`assets/artwork/`) providing posters, landscape grids, heroes, and logos for every service and game.
* **Universal Controller udev & HID Mapping**: Automatically configures controller permissions for all hardware—Steam Deck Neptune, Xbox Wireless, Sony DualSense/DS4, Nintendo Switch Pro, and 8BitDo.

---

## 📦 Supported Streaming Services

| Service | Cloud/Host Provider | Target Platform | Dedicated Shortcuts Included |
| --- | --- | --- | :---: |
| **GeForce NOW** | NVIDIA | RTX 4080 / Reflex / 120 FPS | ✅ Included (Portal + Destiny 2 + Any Game) |
| **Xbox Cloud Gaming** | Microsoft | Xbox Series X custom server blades | ✅ Included (Portal + Destiny 2) |
| **Boosteroid** | Boosteroid | AMD EPYC + Radeon / Ultra 4K | ✅ Included (Portal + Destiny 2) |
| **Shadow PC** | Shadow | Full remote Windows 10/11 desktop | ✅ Included |
| **Moonlight** | Local / Remote PC | Your own Windows Gaming Rig (Sunshine) | ✅ Included |
| **Windows Game** | Native / Cloud | Any custom Windows title | ✅ Included |

---

## 🛠️ Installation Runbook

### Method A: One-Click SteamOS Desktop Mode Installation (Recommended for Handhelds)

1. Switch your Steam Deck into **Desktop Mode**:
   * Press the physical **STEAM** button.
   * Navigate to **Power** → **Switch to Desktop**.
2. Clone or download this repository:

   ```bash
   git clone https://github.com/fj906880l-web/steams-windows-plug-in-.git ~/steams-windows-plug-in-
   ```

3. Open **Dolphin** file manager, open `~/steams-windows-plug-in-`, and double-click:

   ```text
   CloudDeck-Installer.desktop
   ```

4. Click **Launch** when prompted. The installer will:
   * Validate your SteamOS environment and GPU drivers.
   * Deploy `~/.local/bin/cloud-launcher.sh`.
   * Apply Flatpak udev device permissions.
   * Inject all cloud shortcuts and artwork into `shortcuts.vdf`.
   * Deploy the Decky Loader plugin to `~/homebrew/plugins/CloudDeck`.
5. Double-click **Return to Gaming Mode** on the Desktop.

### Method B: Headless Terminal Installation (SteamOS / Linux)

Open Konsole on your Steam Deck or connect via SSH:

```bash
cd ~/steams-windows-plug-in-
chmod +x install.sh
./install.sh
```

### Method C: Windows 10/11 Installation

Open Command Prompt or PowerShell in the repository folder:

```cmd
:: Method 1: Double-click or run install.bat
install.bat

:: Method 2: PowerShell script
powershell -ExecutionPolicy Bypass -File install.ps1
```

The Windows installer automatically locates your Steam directory (`C:\Program Files (x86)\Steam\userdata`), injects the 9 shortcuts, and copies the 28 custom artwork assets into your active Steam user profile grid folder.

### Method D: macOS Installation

Open Terminal in the repository folder:

```bash
cd ~/steams-windows-plug-in-
chmod +x install-macos.sh
./install-macos.sh
```

The macOS installer automatically configures `~/Library/Application Support/Steam`, deploys `~/.local/bin/cloud-launcher.sh`, injects all shortcuts, and prepares hardware-accelerated Safari/Chrome kiosk launchers with Apple Silicon Metal optimization.

---

## 🧪 Testing & Verification

Run the comprehensive automated test suite and sandbox verification script:

```bash
# 1. Pure-Python VDF Parser & Idempotency Test
python3 tests/test_vdf_injector.py

# 2. Hardware Launcher CLI Test Suite
bash tests/test_launcher.sh

# 3. Full Mock SteamOS Sandbox Verification
bash tests/sandbox_verify.sh
```

### Verified Sandbox Output

```text
[OK] Mock SteamOS user directory initialized at /tmp/mock_steamos_...
[OK] Verified 9 cloud shortcuts written to shortcuts.vdf (CRC32 checked)
[OK] Verified 28 grid artwork assets deployed to grid/ directory
[OK] Verified cloud-launcher.sh executes cleanly under mock Gamescope
[OK] ALL SANDBOX VERIFICATION CHECKS PASSED
```

---

## 📋 Runbook & Troubleshooting

For in-depth operational procedures, network diagnostics, codec switching (H.264 vs HEVC), and error resolution trees, refer to the full **[Method of Procedure (MOP.md)](MOP.md)**.

### Quick Fixes

* **Controls not working in-game on Linux**: Flatpak needs udev permissions. Run:

  ```bash
  flatpak --user override --filesystem=/run/udev:ro com.microsoft.Edge
  flatpak --user override --filesystem=/run/udev:ro com.google.Chrome
  ```

* **Shortcuts not appearing in Game Mode**: Completely restart Steam or reboot into Gaming Mode. Steam only reads `shortcuts.vdf` on startup.
* **Windows or Mac shortcut launch**: Ensure your preferred browser (Chrome, Edge, Brave, or Safari) is installed and default protocol handlers are enabled.

---

## 🗑️ Uninstallation

To completely remove CloudDeck and restore your original shortcuts:

```bash
# 1. Remove launcher and binaries (Linux/macOS)
rm -rf ~/.local/share/clouddeck ~/.local/bin/cloud-launcher.sh

# 2. Remove Decky Loader plugin
rm -rf ~/homebrew/plugins/CloudDeck

# 3. Restore backup shortcuts.vdf
find ~/.local/share/Steam/userdata/ -name "shortcuts.vdf.bak" -exec cp {} ~/.local/share/Steam/userdata/config/shortcuts.vdf \;
```

---

## 📄 License

Distributed under the **MIT License**. See [`LICENSE`](LICENSE) for details.
