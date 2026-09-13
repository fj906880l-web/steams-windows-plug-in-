import os
import sys
import tempfile
import unittest
from pathlib import Path

# Add lib directory to path
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "lib")))
import vdf
import steam_shortcuts_manager


class TestVDF(unittest.TestCase):
    def test_roundtrip_simple_binary(self):
        sample_data = {
            "shortcuts": {
                "0": {
                    "appid": -1844674407,
                    "AppName": "Destiny 2 (GeForce NOW)",
                    "Exe": "/home/deck/.local/bin/cloud-launcher.sh",
                    "StartDir": "/home/deck",
                    "icon": "/home/deck/.local/share/icons/destiny2.png",
                    "ShortcutPath": "",
                    "LaunchOptions": "--service gfn --game destiny2",
                    "IsHidden": 0,
                    "AllowDesktopConfig": 1,
                    "AllowOverlay": 1,
                    "OpenVR": 0,
                    "Devkit": 0,
                    "DevkitGameID": "",
                    "DevkitOverrideAppId": 0,
                    "LastPlayTime": 0,
                    "FlatpakAppID": "",
                    "tags": {
                        "0": "Cloud Gaming",
                        "1": "Anti-Cheat Safe"
                    }
                }
            }
        }

        # Serialize
        serialized = vdf.binary_dumps(sample_data)
        self.assertIsInstance(serialized, bytes)
        self.assertTrue(len(serialized) > 0)

        # Deserialize
        deserialized = vdf.binary_loads(serialized)
        self.assertIn("shortcuts", deserialized)
        self.assertIn("0", deserialized["shortcuts"])
        shortcut = deserialized["shortcuts"]["0"]
        self.assertEqual(shortcut["AppName"], "Destiny 2 (GeForce NOW)")
        self.assertEqual(shortcut["Exe"], "/home/deck/.local/bin/cloud-launcher.sh")
        self.assertEqual(shortcut["LaunchOptions"], "--service gfn --game destiny2")
        self.assertEqual(shortcut["tags"]["0"], "Cloud Gaming")
        self.assertEqual(shortcut["tags"]["1"], "Anti-Cheat Safe")

    def test_appid_calculation(self):
        exe = "/usr/bin/flatpak"
        name = "Boosteroid SteamOS"
        unsigned_id = vdf.generate_steam_appid(exe, name)
        self.assertTrue(unsigned_id >= 0x80000000)

        signed_id = vdf.signed_appid(unsigned_id)
        self.assertIsInstance(signed_id, int)
        self.assertTrue(-0x80000000 <= signed_id <= 0x7FFFFFFF)

    def test_shortcuts_injection_and_idempotency(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            vdf_path = os.path.join(tmpdir, "shortcuts.vdf")
            launcher_exe = "/home/deck/.local/bin/cloud-launcher.sh"

            # 1. Initial Injection
            installed1 = steam_shortcuts_manager.inject_shortcuts(vdf_path, launcher_exe)
            self.assertTrue(os.path.isfile(vdf_path))
            self.assertEqual(len(installed1), len(steam_shortcuts_manager.ENTRIES_TO_INSTALL))

            # Verify contents
            with open(vdf_path, "rb") as f:
                data = vdf.binary_loads(f.read())
            self.assertIn("shortcuts", data)
            self.assertEqual(len(data["shortcuts"]), len(steam_shortcuts_manager.ENTRIES_TO_INSTALL))

            # Verify Destiny 2 shortcut presence
            names = [entry["AppName"] for entry in data["shortcuts"].values()]
            self.assertIn("Destiny 2 (GeForce NOW - Ban-Safe)", names)
            self.assertIn("Cloud Deck: GeForce NOW", names)

            # 2. Re-run injection (Idempotency check)
            installed2 = steam_shortcuts_manager.inject_shortcuts(vdf_path, launcher_exe)
            with open(vdf_path, "rb") as f:
                data2 = vdf.binary_loads(f.read())
            self.assertEqual(len(data2["shortcuts"]), len(steam_shortcuts_manager.ENTRIES_TO_INSTALL))

    def test_artwork_installation(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            userdata_dir = os.path.join(tmpdir, "userdata", "12345678")
            os.makedirs(os.path.join(userdata_dir, "config"), exist_ok=True)
            vdf_path = os.path.join(userdata_dir, "config", "shortcuts.vdf")
            launcher_exe = "/home/deck/.local/bin/cloud-launcher.sh"

            installed = steam_shortcuts_manager.inject_shortcuts(vdf_path, launcher_exe)
            art_src = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "assets", "artwork"))
            steam_shortcuts_manager.install_artwork(userdata_dir, installed, art_src)

            grid_dir = os.path.join(userdata_dir, "config", "grid")
            self.assertTrue(os.path.isdir(grid_dir))

            # Verify that each installed app has artwork files created
            for app_name, appid, _ in installed:
                poster = os.path.join(grid_dir, f"{appid}p.png")
                grid = os.path.join(grid_dir, f"{appid}.png")
                self.assertTrue(os.path.isfile(poster), f"Missing poster for {app_name}: {poster}")
                self.assertTrue(os.path.isfile(grid), f"Missing grid for {app_name}: {grid}")


if __name__ == "__main__":
    unittest.main()
