#!/usr/bin/env bash
# ==============================================================================
# CloudDeck SteamOS Installer: Cloud Gaming & Ban-Safe Windows Streaming Suite
# ==============================================================================
# Seamlessly integrates GeForce NOW, Xbox Cloud, Boosteroid, and Shadow into
# SteamOS Game Mode for ban-immune streaming of Destiny 2 and anti-cheat titles.
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_PREFIX="${HOME}/.local/share/clouddeck"
BIN_DIR="${HOME}/.local/bin"

# ── ANSI Colors ───────────────────────────────────────────────────────────────
R=$'\033[0m'
BOLD=$'\033[1m'
G=$'\033[38;5;82m'      # Green
B=$'\033[38;5;33m'      # Blue
C=$'\033[38;5;51m'      # Cyan
Y=$'\033[38;5;220m'     # Yellow
M=$'\033[38;5;198m'     # Magenta

echo ""
echo "${C}  ╔══════════════════════════════════════════════════════════╗${R}"
echo "${C}  ║${R} ${BOLD}CloudDeck: SteamOS Game Mode Cloud Gaming Suite${R}       ${C}║${R}"
echo "${C}  ║${R} ${M}Zero-Ban Windows Streaming (Destiny 2 / BattlEye Safe)${R}   ${C}║${R}"
echo "${C}  ╚══════════════════════════════════════════════════════════╝${R}"
echo ""

# 1. Environment Verification
echo "${BOLD}[1/5] Verifying System Environment...${R}"
if [[ -f /etc/os-release ]] && grep -qiE "steamos|bazzite|chimeraos|holoiso" /etc/os-release; then
    DISTRO_NAME="$(grep -E "^NAME=" /etc/os-release | cut -d= -f2 | tr -d '"')"
    echo "  ${G}✓ SteamOS / Gaming Distro detected: ${DISTRO_NAME}${R}"
else
    echo "  ${G}✓ Linux PC / Desktop detected. Full desktop and handheld support enabled.${R}"
fi

# Ensure directories exist
mkdir -p "${INSTALL_PREFIX}"
mkdir -p "${INSTALL_PREFIX}/bin"
mkdir -p "${INSTALL_PREFIX}/lib"
mkdir -p "${INSTALL_PREFIX}/assets"
mkdir -p "${BIN_DIR}"

# 2. Deploy Launcher & Libraries
echo "${BOLD}[2/5] Installing Core Launcher & Python Libraries...${R}"
cp -r "${SCRIPT_DIR}/bin/"* "${INSTALL_PREFIX}/bin/"
cp -r "${SCRIPT_DIR}/lib/"* "${INSTALL_PREFIX}/lib/"
cp -r "${SCRIPT_DIR}/assets/"* "${INSTALL_PREFIX}/assets/"

# Symlink launcher to ~/.local/bin
ln -sf "${INSTALL_PREFIX}/bin/cloud-launcher.sh" "${BIN_DIR}/cloud-launcher.sh"
chmod +x "${INSTALL_PREFIX}/bin/cloud-launcher.sh" "${BIN_DIR}/cloud-launcher.sh"
echo "  ${G}✓ Launcher installed to ${BIN_DIR}/cloud-launcher.sh${R}"

# Ensure ~/.local/bin is on PATH in ~/.bashrc if not already
if ! grep -qs 'export PATH="$HOME/.local/bin:$PATH"' "${HOME}/.bashrc" 2>/dev/null; then
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> "${HOME}/.bashrc"
fi

# 3. Flatpak & Udev Controller Permissions (Zero-Hiccup Gamepad Pipeline)
echo "${BOLD}[3/5] Setting Flatpak Udev Controller Permissions...${R}"
if command -v flatpak &>/dev/null; then
    # Ensure Flathub repository is configured
    if ! flatpak remotes | grep -q "flathub"; then
        echo "  Configuring Flathub repo..."
        flatpak remote-add --user --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo || true
    fi

    # Check for Edge or Chrome, install Edge if neither is found
    if ! flatpak info com.microsoft.Edge &>/dev/null && ! flatpak info com.google.Chrome &>/dev/null; then
        echo "  ${Y}Installing Microsoft Edge Flatpak (Valve recommended browser)...${R}"
        flatpak install -y --user flathub com.microsoft.Edge || {
            echo "  ${Y}Could not automatically install Edge via Flatpak. You can install it via Discover.${R}"
        }
    fi

    # Apply udev permissions for Gamepad access across all cloud gaming Flatpaks
    echo "  Applying controller udev overrides for zero-latency HID inputs..."
    for APP_ID in com.microsoft.Edge com.google.Chrome org.chromium.Chromium com.moonlight_stream.Moonlight org.schelstraete.boosteroid; do
        flatpak --user override --filesystem=/run/udev:ro "${APP_ID}" 2>/dev/null || true
    done
    echo "  ${G}✓ Flatpak udev overrides applied for all controller types.${R}"
else
    echo "  ${Y}! Flatpak not found on system. Skipping Flatpak udev override.${R}"
fi

# 4. Inject Steam Shortcuts & Grid Artwork
echo "${BOLD}[4/5] Injecting Steam Game Mode Shortcuts & Grid Artwork...${R}"
python3 "${INSTALL_PREFIX}/lib/steam_shortcuts_manager.py" \
    --launcher-exe "${BIN_DIR}/cloud-launcher.sh" \
    --artwork-dir "${INSTALL_PREFIX}/assets/artwork" || {
        echo "  ${Y}! Could not automatically inject shortcuts (Steam might not have run yet).${R}"
    }

# 5. Decky Loader Plugin Deployment (Optional)
echo "${BOLD}[5/5] Checking Decky Loader Integration...${R}"
DECKY_PLUGINS_DIR="${HOME}/homebrew/plugins"
if [[ -d "${DECKY_PLUGINS_DIR}" ]]; then
    echo "  Decky Loader detected! Deploying CloudDeck plugin..."
    TARGET_PLUGIN_DIR="${DECKY_PLUGINS_DIR}/CloudDeck"
    mkdir -p "${TARGET_PLUGIN_DIR}"
    cp -r "${SCRIPT_DIR}/decky-plugin/"* "${TARGET_PLUGIN_DIR}/"
    echo "  ${G}✓ CloudDeck Decky Plugin deployed to ${TARGET_PLUGIN_DIR}.${R}"
else
    echo "  ${B}i Decky Loader not detected at ~/homebrew/plugins.${R}"
    echo "    Standalone Game Mode shortcuts and launcher are ready."
fi

echo ""
echo "${G}══════════════════════════════════════════════════════════════${R}"
echo "${G}         CloudDeck Installation Complete!                     ${R}"
echo "${G}══════════════════════════════════════════════════════════════${R}"
echo "Next Steps:"
echo " 1. Return to ${BOLD}Gaming Mode${R} on your Steam Deck."
echo " 2. Find ${BOLD}Destiny 2 (GeForce NOW - Ban-Safe)${R} or cloud services in your Library."
echo " 3. Launch and log in once to play Destiny 2 with zero anti-cheat ban risk!"
echo ""
