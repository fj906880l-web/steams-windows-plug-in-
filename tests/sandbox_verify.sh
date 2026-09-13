#!/usr/bin/env bash
# ==============================================================================
# tests/sandbox_verify.sh - End-to-End Sandbox Verification Harness
# ==============================================================================
# Validates the complete CloudDeck installation, shortcut injection, artwork
# deployment, and launcher execution in an isolated sandbox environment.
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

SANDBOX_DIR="$(mktemp -d /tmp/clouddeck_sandbox_XXXXXX)"
cleanup() {
    echo "Cleaning up sandbox at ${SANDBOX_DIR}..."
    rm -rf "${SANDBOX_DIR}"
}
trap cleanup EXIT

echo "=== CloudDeck Sandbox Verification Harness ==="
echo "Sandbox Directory: ${SANDBOX_DIR}"

# 1. Setup Isolated Mock Environment
MOCK_HOME="${SANDBOX_DIR}/mock_home"
mkdir -p "${MOCK_HOME}/.local/bin"
mkdir -p "${MOCK_HOME}/.local/share/Steam/userdata/12345678/config"
mkdir -p "${MOCK_HOME}/homebrew/plugins"

# Mock Steam shortcuts.vdf (initially empty)
touch "${MOCK_HOME}/.local/share/Steam/userdata/12345678/config/shortcuts.vdf"

echo "[1/4] Mock Steam & Decky Environment Initialized."

# 2. Execute install.sh within Sandbox
echo "[2/4] Executing install.sh in sandbox..."
HOME="${MOCK_HOME}" bash "${REPO_ROOT}/install.sh" > "${SANDBOX_DIR}/install.log" 2>&1 || {
    echo "ERROR: install.sh failed! Log output:"
    cat "${SANDBOX_DIR}/install.log"
    exit 1
}
echo "  ✓ install.sh executed cleanly."

# 3. Verify Artifacts & Filesystem Deployments
echo "[3/4] Verifying Deployed Artifacts..."

# Verify launcher binary
if [[ ! -x "${MOCK_HOME}/.local/bin/cloud-launcher.sh" ]]; then
    echo "ERROR: Launcher binary missing or not executable at ~/.local/bin/cloud-launcher.sh"
    exit 1
fi
echo "  ✓ ~/.local/bin/cloud-launcher.sh verified."

# Verify Decky plugin deployment
if [[ ! -f "${MOCK_HOME}/homebrew/plugins/CloudDeck/plugin.json" ]]; then
    echo "ERROR: Decky plugin missing at ~/homebrew/plugins/CloudDeck/plugin.json"
    exit 1
fi
echo "  ✓ Decky Loader plugin deployed successfully."

# Verify shortcuts.vdf via Python test script
python3 - <<EOF
import os
import sys
sys.path.insert(0, "${REPO_ROOT}/lib")
import vdf

vdf_path = "${MOCK_HOME}/.local/share/Steam/userdata/12345678/config/shortcuts.vdf"
assert os.path.isfile(vdf_path), f"File missing: {vdf_path}"
assert os.path.getsize(vdf_path) > 0, "VDF file is empty"

with open(vdf_path, "rb") as f:
    data = vdf.binary_loads(f.read())

shortcuts = data.get("shortcuts", {})
assert len(shortcuts) >= 5, f"Expected >= 5 shortcuts, found {len(shortcuts)}"

names = [entry.get("AppName") for entry in shortcuts.values()]
print(f"  ✓ Found {len(shortcuts)} shortcuts in VDF:")
for n in names:
    print(f"    - {n}")

assert "Destiny 2 (GeForce NOW - Ban-Safe)" in names, "Destiny 2 GFN missing"
assert "Destiny 2 (Xbox Cloud - Ban-Safe)" in names, "Destiny 2 Xbox missing"
assert "Cloud Deck: GeForce NOW" in names, "GeForce NOW portal missing"
assert "Cloud Deck: Xbox Cloud Gaming" in names, "Xbox Cloud portal missing"
assert "Cloud Deck: Boosteroid" in names, "Boosteroid portal missing"

# Check Grid Artwork
grid_dir = "${MOCK_HOME}/.local/share/Steam/userdata/12345678/config/grid"
assert os.path.isdir(grid_dir), f"Grid dir missing: {grid_dir}"

for entry in shortcuts.values():
    appid_unsigned = entry["appid"] & 0xFFFFFFFF
    if appid_unsigned < 0x80000000:
        appid_unsigned |= 0x80000000
    poster = os.path.join(grid_dir, f"{appid_unsigned}p.png")
    grid = os.path.join(grid_dir, f"{appid_unsigned}.png")
    assert os.path.isfile(poster), f"Missing poster artwork: {poster}"
    assert os.path.isfile(grid), f"Missing grid artwork: {grid}"

print("  ✓ All Steam grid posters and landscape artwork verified.")
EOF

# 4. Verify Launcher Execution in Sandbox
echo "[4/4] Verifying Launcher CLI Execution in Sandbox..."
LAUNCHER="${MOCK_HOME}/.local/bin/cloud-launcher.sh"

# Test GFN Destiny 2
GFN_CMD="$("${LAUNCHER}" --dry-run --service gfn --game destiny2)"
if [[ "${GFN_CMD}" != *"https://play.geforcenow.com/mall/#/deep-link?game-id=100412811"* ]]; then
    echo "ERROR: GFN Destiny 2 dry-run command invalid: ${GFN_CMD}"
    exit 1
fi
echo "  ✓ GFN Destiny 2 deep-link verified."

# Test Xbox Destiny 2
XBOX_CMD="$("${LAUNCHER}" --dry-run --service xbox --game destiny2)"
if [[ "${XBOX_CMD}" != *"https://www.xbox.com/play/games/destiny-2/BPK99T289069"* ]]; then
    echo "ERROR: Xbox Destiny 2 dry-run command invalid: ${XBOX_CMD}"
    exit 1
fi
echo "  ✓ Xbox Destiny 2 deep-link verified."

# Test Anti-Cheat check
AC_CHECK="$("${LAUNCHER}" --check-anticheat)"
if [[ "${AC_CHECK}" != *"100% IMMUNE"* ]]; then
    echo "ERROR: Anti-cheat verification failed: ${AC_CHECK}"
    exit 1
fi
echo "  ✓ Anti-cheat ban safety validator verified."

echo ""
echo "=== SANDBOX VERIFICATION COMPLETED SUCCESSFULLY ==="
echo "All components function as expected in an isolated sandbox."
