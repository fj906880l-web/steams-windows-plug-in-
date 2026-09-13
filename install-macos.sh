#!/usr/bin/env bash
# ==============================================================================
# CloudDeck macOS Installer: Cloud Gaming & Remote Streaming Suite
# ==============================================================================
# Integrates GeForce NOW, Xbox Cloud, Boosteroid, Shadow, and Moonlight into
# Steam for Mac with high-resolution artwork and Metal/VideoToolbox acceleration.
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_PREFIX="${HOME}/Library/Application Support/CloudDeck"
BIN_DIR="${HOME}/.local/bin"

echo ""
echo "=== CloudDeck: macOS Steam Integration Suite ==="
echo ""

# 1. Directories
echo "[1/4] Preparing directories..."
mkdir -p "${INSTALL_PREFIX}/bin" "${INSTALL_PREFIX}/lib" "${INSTALL_PREFIX}/assets" "${BIN_DIR}"

# 2. Deploy
echo "[2/4] Deploying launcher and assets..."
cp -r "${SCRIPT_DIR}/bin/"* "${INSTALL_PREFIX}/bin/"
cp -r "${SCRIPT_DIR}/lib/"* "${INSTALL_PREFIX}/lib/"
cp -r "${SCRIPT_DIR}/assets/"* "${INSTALL_PREFIX}/assets/"

ln -sf "${INSTALL_PREFIX}/bin/cloud-launcher.sh" "${BIN_DIR}/cloud-launcher.sh"
chmod +x "${INSTALL_PREFIX}/bin/cloud-launcher.sh" "${BIN_DIR}/cloud-launcher.sh"
echo "  ✓ Launcher installed to ${BIN_DIR}/cloud-launcher.sh"

# 3. Inject Steam Shortcuts
echo "[3/4] Injecting Steam shortcuts and grid artwork..."
python3 "${INSTALL_PREFIX}/lib/steam_shortcuts_manager.py" \
    --launcher-exe "${BIN_DIR}/cloud-launcher.sh" \
    --artwork-dir "${INSTALL_PREFIX}/assets/artwork" || {
        echo "  Notice: Steam not yet launched on this Mac, or custom userdata path needed."
    }

echo ""
echo "=== CloudDeck macOS Installation Complete! ==="
echo "Restart Steam to view and launch your cloud gaming shortcuts."
echo ""
