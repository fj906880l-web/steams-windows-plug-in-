#!/usr/bin/env bash
# Test suite for CloudDeck launcher
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
LAUNCHER="${PROJECT_ROOT}/bin/cloud-launcher.sh"

echo "=== Running CloudDeck Launcher Tests ==="

# Test 1: Help flag
echo "Test 1: Help flag"
"${LAUNCHER}" --help > /dev/null
echo "✓ Passed"

# Test 2: Anti-cheat check
echo "Test 2: Anti-cheat check"
AC_OUT="$("${LAUNCHER}" --check-anticheat)"
if [[ "${AC_OUT}" != *"BattlEye Anti-Cheat"* ]] || [[ "${AC_OUT}" != *"100% IMMUNE"* ]]; then
    echo "✗ Failed: Anti-cheat check output missing expected keywords"
    exit 1
fi
echo "✓ Passed"

# Test 3: Dry run GFN Destiny 2
echo "Test 3: Dry run GFN Destiny 2"
GFN_OUT="$("${LAUNCHER}" --dry-run --service gfn --game destiny2)"
if [[ "${GFN_OUT}" != *"https://play.geforcenow.com/mall/#/deep-link?game-id=100412811"* ]]; then
    echo "✗ Failed: GFN Destiny 2 URL mismatch"
    exit 1
fi
if [[ "${GFN_OUT}" != *"kiosk"* ]]; then
    echo "✗ Failed: Kiosk flag missing"
    exit 1
fi
echo "✓ Passed"

# Test 4: Dry run Xbox Cloud
echo "Test 4: Dry run Xbox Cloud"
XBOX_OUT="$("${LAUNCHER}" --dry-run --service xbox --game destiny2)"
if [[ "${XBOX_OUT}" != *"https://www.xbox.com/play/games/destiny-2/BPK99T289069"* ]]; then
    echo "✗ Failed: Xbox Destiny 2 URL mismatch"
    exit 1
fi
echo "✓ Passed"

# Test 5: Dry run Boosteroid
echo "Test 5: Dry run Boosteroid"
BOOST_OUT="$("${LAUNCHER}" --dry-run --service boosteroid --game destiny2)"
if [[ "${BOOST_OUT}" != *"https://cloud.boosteroid.com/application/518"* ]]; then
    echo "✗ Failed: Boosteroid Destiny 2 URL mismatch"
    exit 1
fi
echo "✓ Passed"

# Test 6: Custom Windows game launch (Any game)
echo "Test 6: Custom Windows game launch (Any game)"
CUSTOM_OUT="$("${LAUNCHER}" --dry-run --service gfn --game "Cyberpunk 2077")"
if [[ "${CUSTOM_OUT}" != *"search?query=Cyberpunk%202077"* ]]; then
    echo "✗ Failed: Custom game URL encoding mismatch"
    exit 1
fi
echo "✓ Passed"

# Test 7: Custom resolution and zero-stutter flags
echo "Test 7: Custom resolution and zero-stutter flags"
RES_OUT="$("${LAUNCHER}" --dry-run --service gfn --resolution 2560x1440)"
if [[ "${RES_OUT}" != *"--window-size=2560,1440"* ]] || [[ "${RES_OUT}" != *"--disable-background-timer-throttling"* ]]; then
    echo "✗ Failed: Custom resolution or anti-stutter flags missing"
    exit 1
fi
echo "✓ Passed"

# Test 8: Moonlight Game Streaming
echo "Test 8: Moonlight Game Streaming"
MOON_OUT="$("${LAUNCHER}" --dry-run --service moonlight --game "Elden Ring")"
if [[ "${MOON_OUT}" != *"moonlight://launch?app=Elden%20Ring"* ]]; then
    echo "✗ Failed: Moonlight app stream URL mismatch"
    exit 1
fi
echo "✓ Passed"

echo "=== All Launcher Tests Passed Successfully ==="

