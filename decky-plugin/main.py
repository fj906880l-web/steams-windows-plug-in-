#!/usr/bin/env python3
"""
decky-plugin/main.py - Python Backend for CloudDeck Decky Loader Plugin.
Executes service launches, network latency measurements, and shortcuts synchronization.
"""

import os
import sys
import subprocess
import time
import socket
from pathlib import Path


class Plugin:
    def __init__(self):
        self.plugin_dir = os.path.dirname(os.path.abspath(__file__))
        self.root_dir = os.path.abspath(os.path.join(self.plugin_dir, ".."))
        self.launcher_path = os.path.expanduser("~/.local/bin/cloud-launcher.sh")
        if not os.path.isfile(self.launcher_path):
            self.launcher_path = os.path.join(self.root_dir, "bin", "cloud-launcher.sh")

    async def _main(self):
        """Plugin entry point when loaded by Decky Loader."""
        pass

    async def _unload(self):
        """Plugin unload cleanup."""
        pass

    async def launch_service(self, service="gfn", game="", codec="auto", resolution="800p"):
        """Launch a cloud gaming service or specific game."""
        cmd = [self.launcher_path, "--service", service]
        if game:
            cmd.extend(["--game", game])
        if codec in ("h264", "h265"):
            cmd.extend(["--codec", codec])

        env = os.environ.copy()
        # Ensure proper Gamescope environment
        if "DISPLAY" not in env:
            env["DISPLAY"] = ":0"

        try:
            # Spawn in background so Decky UI doesn't block
            subprocess.Popen(
                cmd,
                env=env,
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
                start_new_session=True
            )
            return {"status": "ok", "service": service, "game": game}
        except Exception as e:
            return {"status": "error", "error": str(e)}

    async def ping_datacenters(self):
        """Measure round-trip network latency to cloud gaming endpoints."""
        endpoints = {
            "gfn": ("play.geforcenow.com", 443),
            "xbox": ("www.xbox.com", 443),
            "boosteroid": ("cloud.boosteroid.com", 443)
        }

        results = {}
        for key, (host, port) in endpoints.items():
            try:
                start = time.perf_counter()
                s = socket.create_connection((host, port), timeout=2.0)
                s.close()
                elapsed = (time.perf_counter() - start) * 1000.0
                results[key] = f"{int(elapsed)} ms"
            except Exception:
                results[key] = "Timeout"

        return results

    async def sync_steam_shortcuts(self):
        """Run the Steam shortcuts manager to inject/update Non-Steam games."""
        script = os.path.join(self.root_dir, "lib", "steam_shortcuts_manager.py")
        if not os.path.isfile(script):
            script = os.path.expanduser("~/.local/share/clouddeck/lib/steam_shortcuts_manager.py")

        if not os.path.isfile(script):
            return {"status": "error", "error": "steam_shortcuts_manager.py not found"}

        try:
            res = subprocess.run(
                [sys.executable, script, "--launcher-exe", self.launcher_path],
                capture_output=True,
                text=True,
                check=True
            )
            return {"status": "ok", "output": res.stdout}
        except subprocess.CalledProcessError as e:
            return {"status": "error", "error": e.stderr or str(e)}

    async def get_anticheat_info(self):
        """Return anti-cheat ban safety policy details."""
        return {
            "status": "Safe",
            "mechanism": "Certified Windows Remote Cloud Host",
            "destiny2": {
                "native_proton": "BANNABLE (Strict Bungie Policy)",
                "cloud_streaming": "100% IMMUNE (Zero Wine/Proton hooks, genuine Windows instance)"
            }
        }
