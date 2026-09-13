#!/usr/bin/env python3
"""
lib/steam_shortcuts_manager.py - Steam shortcuts.vdf and grid artwork manager.
Automates injecting CloudDeck streaming services and direct Destiny 2 launchers
into SteamOS Game Mode.
"""

import os
import sys
import glob
import shutil
import argparse
from pathlib import Path

# Add current dir so vdf can be imported
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import vdf


STEAM_ROOT_CANDIDATES = [
    os.path.expanduser("~/.local/share/Steam"),
    os.path.expanduser("~/.steam/steam"),
    os.path.expanduser("~/.var/app/com.valvesoftware.Steam/data/Steam"),
]


DEFAULT_LAUNCHER_PATH = os.path.expanduser("~/.local/bin/cloud-launcher.sh")


ENTRIES_TO_INSTALL = [
    {
        "name": "Cloud Deck: GeForce NOW",
        "options": "--service gfn",
        "art_key": "gfn",
        "tags": ["Cloud Gaming", "GeForce NOW"]
    },
    {
        "name": "Destiny 2 (GeForce NOW - Ban-Safe)",
        "options": "--service gfn --game destiny2",
        "art_key": "destiny2",
        "tags": ["Cloud Gaming", "Destiny 2", "Anti-Cheat Safe"]
    },
    {
        "name": "Cloud Deck: Xbox Cloud Gaming",
        "options": "--service xbox",
        "art_key": "xbox",
        "tags": ["Cloud Gaming", "Xbox Cloud"]
    },
    {
        "name": "Destiny 2 (Xbox Cloud - Ban-Safe)",
        "options": "--service xbox --game destiny2",
        "art_key": "destiny2",
        "tags": ["Cloud Gaming", "Destiny 2", "Anti-Cheat Safe"]
    },
    {
        "name": "Cloud Deck: Boosteroid",
        "options": "--service boosteroid",
        "art_key": "boosteroid",
        "tags": ["Cloud Gaming", "Boosteroid"]
    },
    {
        "name": "Destiny 2 (Boosteroid - Ban-Safe)",
        "options": "--service boosteroid --game destiny2",
        "art_key": "destiny2",
        "tags": ["Cloud Gaming", "Destiny 2", "Anti-Cheat Safe"]
    },
    {
        "name": "Cloud Deck: Shadow PC",
        "options": "--service shadow",
        "art_key": "shadow",
        "tags": ["Cloud Desktop", "Shadow PC"]
    }
]


def find_steam_userdata_dirs(custom_steam_root=None):
    """Find all active Steam userdata directories."""
    roots = [custom_steam_root] if custom_steam_root else STEAM_ROOT_CANDIDATES
    found = []
    for r in roots:
        if not r or not os.path.isdir(r):
            continue
        pattern = os.path.join(r, "userdata", "*")
        for udir in glob.glob(pattern):
            if os.path.isdir(udir) and os.path.basename(udir).isdigit():
                found.append(udir)
    return found


def ensure_shortcuts_vdf(userdata_dir):
    """Return path to shortcuts.vdf, creating directory if necessary."""
    config_dir = os.path.join(userdata_dir, "config")
    os.makedirs(config_dir, exist_ok=True)
    return os.path.join(config_dir, "shortcuts.vdf")


def inject_shortcuts(vdf_path, launcher_exe=None, selected_keys=None):
    """
    Parse shortcuts.vdf, merge CloudDeck entries, and write back.
    Idempotent: updates existing entries with matching AppName.
    """
    exe_path = launcher_exe or DEFAULT_LAUNCHER_PATH
    start_dir = str(Path(exe_path).parent)

    data = {"shortcuts": {}}
    if os.path.isfile(vdf_path) and os.path.getsize(vdf_path) > 0:
        try:
            with open(vdf_path, "rb") as f:
                content = f.read()
                if content:
                    parsed = vdf.binary_loads(content)
                    if isinstance(parsed, dict) and "shortcuts" in parsed:
                        data = parsed
        except Exception as e:
            print(f"[WARN] Failed to parse existing {vdf_path}: {e}. Creating fresh backup.")
            shutil.copy2(vdf_path, vdf_path + ".bak")

    shortcuts_map = data.get("shortcuts", {})
    if not isinstance(shortcuts_map, dict):
        shortcuts_map = {}

    # Index existing by AppName
    existing_by_name = {}
    for idx_key, entry in shortcuts_map.items():
        if isinstance(entry, dict) and "AppName" in entry:
            existing_by_name[entry["AppName"]] = (idx_key, entry)

    # Next index
    existing_indices = [int(k) for k in shortcuts_map.keys() if k.isdigit()]
    next_idx = max(existing_indices) + 1 if existing_indices else 0

    installed_entries = []

    for item in ENTRIES_TO_INSTALL:
        if selected_keys and item["art_key"] not in selected_keys and item["name"] not in selected_keys:
            continue

        app_name = item["name"]
        unsigned_appid = vdf.generate_steam_appid(exe_path, app_name)
        signed_id = vdf.signed_appid(unsigned_appid)

        entry_data = {
            "appid": signed_id,
            "AppName": app_name,
            "Exe": f'"{exe_path}"',
            "StartDir": f'"{start_dir}"',
            "icon": "",
            "ShortcutPath": "",
            "LaunchOptions": item["options"],
            "IsHidden": 0,
            "AllowDesktopConfig": 1,
            "AllowOverlay": 1,
            "OpenVR": 0,
            "Devkit": 0,
            "DevkitGameID": "",
            "DevkitOverrideAppId": 0,
            "LastPlayTime": 0,
            "FlatpakAppID": "",
            "tags": {str(i): tag for i, tag in enumerate(item["tags"])}
        }

        if app_name in existing_by_name:
            idx_str = existing_by_name[app_name][0]
            shortcuts_map[idx_str].update(entry_data)
        else:
            idx_str = str(next_idx)
            shortcuts_map[idx_str] = entry_data
            next_idx += 1

        installed_entries.append((app_name, unsigned_appid, item["art_key"]))

    data["shortcuts"] = shortcuts_map

    # Write binary VDF
    with open(vdf_path, "wb") as f:
        f.write(vdf.binary_dumps(data))

    return installed_entries


def install_artwork(userdata_dir, installed_entries, artwork_src_dir=None):
    """
    Install grid artwork into userdata/<id>/config/grid/ for each shortcut.
    Steam recognizes:
    - {appid}p.png (vertical poster / capsule 600x900)
    - {appid}.png (horizontal capsule / grid 920x430)
    - {appid}_hero.png (hero banner 1920x620)
    - {appid}_logo.png (logo 1280x720)
    """
    grid_dir = os.path.join(userdata_dir, "config", "grid")
    os.makedirs(grid_dir, exist_ok=True)

    if not artwork_src_dir or not os.path.isdir(artwork_src_dir):
        # Fallback to local assets/artwork
        artwork_src_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "assets", "artwork"))

    if not os.path.isdir(artwork_src_dir):
        return

    for app_name, unsigned_appid, art_key in installed_entries:
        appid_str = str(unsigned_appid)

        # Mapping of suffix to expected artwork source file
        art_targets = [
            (f"{appid_str}p.png", f"{art_key}_p.png"),
            (f"{appid_str}.png", f"{art_key}_grid.png"),
            (f"{appid_str}_hero.png", f"{art_key}_hero.png"),
            (f"{appid_str}_logo.png", f"{art_key}_logo.png"),
        ]

        for dest_name, src_name in art_targets:
            src_file = os.path.join(artwork_src_dir, src_name)
            dest_file = os.path.join(grid_dir, dest_name)
            if os.path.isfile(src_file):
                shutil.copy2(src_file, dest_file)


def install_controller_configs(steam_root, installed_entries, configs_src_dir=None):
    """
    Install default Steam Deck Neptune controller configuration templates
    into Steam's controller cache.
    """
    if not configs_src_dir:
        configs_src_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "assets", "controller_configs"))

    neptune_config = os.path.join(configs_src_dir, "clouddeck_controller_config.vdf")
    if not os.path.isfile(neptune_config):
        return

    ctrl_dir_base = os.path.join(steam_root, "steamapps", "common", "Steam Controller Configs")
    if not os.path.isdir(ctrl_dir_base):
        return

    # Find user configs
    for udir in glob.glob(os.path.join(ctrl_dir_base, "*", "config")):
        for app_name, _, _ in installed_entries:
            app_folder = os.path.join(udir, app_name.lower())
            os.makedirs(app_folder, exist_ok=True)
            target = os.path.join(app_folder, "configset_controller_neptune.vdf")
            shutil.copy2(neptune_config, target)


def main():
    parser = argparse.ArgumentParser(description="CloudDeck Steam Shortcuts & Artwork Manager")
    parser.add_argument("--steam-root", help="Custom Steam root directory")
    parser.add_argument("--vdf-path", help="Direct path to shortcuts.vdf")
    parser.add_argument("--launcher-exe", help="Path to cloud-launcher.sh executable")
    parser.add_argument("--artwork-dir", help="Path to artwork source directory")
    parser.add_argument("--destiny-only", action="store_true", help="Install only Destiny 2 entries")

    args = parser.parse_args()

    selected_keys = ["destiny2"] if args.destiny_only else None

    if args.vdf_path:
        vdf_file = args.vdf_path
        installed = inject_shortcuts(vdf_file, args.launcher_exe, selected_keys)
        print(f"[OK] Injected {len(installed)} shortcuts into {vdf_file}")
        sys.exit(0)

    userdata_dirs = find_steam_userdata_dirs(args.steam_root)
    if not userdata_dirs:
        print("[INFO] No active Steam userdata directories found. Is Steam installed?", file=sys.stderr)
        sys.exit(0)

    for udir in userdata_dirs:
        vdf_file = ensure_shortcuts_vdf(udir)
        installed = inject_shortcuts(vdf_file, args.launcher_exe, selected_keys)
        install_artwork(udir, installed, args.artwork_dir)
        print(f"[OK] Injected {len(installed)} CloudDeck shortcuts into {vdf_file}")


if __name__ == "__main__":
    main()
