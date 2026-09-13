#!/usr/bin/env python3
"""
assets/generate_artwork.py - Standalone PNG artwork generator for Steam Deck grid art.
Zero third-party dependencies: uses standard library zlib and struct to produce
valid, high-contrast, beautiful PNG assets for Steam Game Mode.
"""

import os
import zlib
import struct


def make_png(width, height, get_pixel_func):
    """
    Generate valid RGBA PNG binary data.
    get_pixel_func(x, y, width, height) -> (r, g, b, a)
    """
    raw_data = bytearray()
    for y in range(height):
        raw_data.append(0)  # Filter type 0 (None)
        for x in range(width):
            r, g, b, a = get_pixel_func(x, y, width, height)
            raw_data.extend((int(r) & 0xFF, int(g) & 0xFF, int(b) & 0xFF, int(a) & 0xFF))

    compressed = zlib.compress(bytes(raw_data), level=6)

    def make_chunk(chunk_type, data):
        c_type = chunk_type.encode("ascii")
        crc = zlib.crc32(c_type + data) & 0xFFFFFFFF
        return struct.pack(">I", len(data)) + c_type + data + struct.pack(">I", crc)

    header = b"\x89PNG\r\n\x1a\n"
    ihdr_data = struct.pack(">IIBBBBB", width, height, 8, 6, 0, 0, 0)
    ihdr = make_chunk("IHDR", ihdr_data)
    idat = make_chunk("IDAT", compressed)
    iend = make_chunk("IEND", b"")

    return header + ihdr + idat + iend


def save_png(path, width, height, get_pixel_func):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    data = make_png(width, height, get_pixel_func)
    with open(path, "wb") as f:
        f.write(data)
    print(f"Generated artwork: {os.path.basename(path)} ({width}x{height})")


# Color themes
THEMES = {
    "destiny2": {
        "bg_top": (15, 23, 42),       # Dark Slate
        "bg_bot": (30, 41, 59),
        "accent": (245, 158, 11),     # Destiny Solar Amber
        "accent2": (56, 189, 248),    # Arc Blue
    },
    "gfn": {
        "bg_top": (10, 20, 12),       # Dark GeForce Green/Charcoal
        "bg_bot": (20, 35, 22),
        "accent": (118, 185, 0),      # NVIDIA Green (#76B900)
        "accent2": (255, 255, 255),
    },
    "xbox": {
        "bg_top": (12, 28, 16),       # Xbox Forest/Dark
        "bg_bot": (16, 44, 23),
        "accent": (16, 124, 65),      # Xbox Green
        "accent2": (46, 204, 113),
    },
    "boosteroid": {
        "bg_top": (15, 23, 42),
        "bg_bot": (30, 58, 138),
        "accent": (37, 99, 235),      # Boosteroid Blue
        "accent2": (147, 51, 234),
    },
    "shadow": {
        "bg_top": (18, 18, 24),
        "bg_bot": (35, 35, 48),
        "accent": (239, 68, 68),      # Shadow Red/Coral
        "accent2": (244, 114, 182),
    }
}


def make_gradient_pattern(theme_key):
    t = THEMES[theme_key]
    def pixel(x, y, w, h):
        factor_y = y / float(h)
        factor_x = x / float(w)

        # Base gradient
        r = t["bg_top"][0] + (t["bg_bot"][0] - t["bg_top"][0]) * factor_y
        g = t["bg_top"][1] + (t["bg_bot"][1] - t["bg_top"][1]) * factor_y
        b = t["bg_top"][2] + (t["bg_bot"][2] - t["bg_top"][2]) * factor_y

        # Accent glow circle in center/lower-right
        cx, cy = w * 0.75, h * 0.4
        dx = (x - cx) / float(w)
        dy = (y - cy) / float(h)
        dist = (dx * dx + dy * dy) ** 0.5

        if dist < 0.35:
            glow = (1.0 - dist / 0.35) * 0.4
            r += (t["accent"][0] - r) * glow
            g += (t["accent"][1] - g) * glow
            b += (t["accent"][2] - b) * glow

        # Border vignette
        vignette = 1.0 - 0.2 * ((factor_x - 0.5) ** 2 + (factor_y - 0.5) ** 2)
        return (min(255, r * vignette), min(255, g * vignette), min(255, b * vignette), 255)
    return pixel


def make_logo_pattern(theme_key):
    t = THEMES[theme_key]
    def pixel(x, y, w, h):
        cx, cy = w / 2.0, h / 2.0
        dx = abs(x - cx) / (w * 0.3)
        dy = abs(y - cy) / (h * 0.3)
        # Diamond / emblem shape in center
        if (dx + dy) <= 1.0:
            return (t["accent"][0], t["accent"][1], t["accent"][2], 240)
        return (0, 0, 0, 0)
    return pixel


def generate_all(out_dir):
    os.makedirs(out_dir, exist_ok=True)
    # Steam standard resolutions (downscaled slightly for fast runtime generation)
    # Poster: 300x450 (standard 600x900 aspect ratio 2:3)
    # Grid: 460x215 (standard 920x430 aspect ratio)
    # Hero: 480x155 (standard 1920x620 aspect ratio)
    # Logo: 320x180 (standard 1280x720 aspect ratio)
    for key in THEMES:
        pattern = make_gradient_pattern(key)
        logo_pat = make_logo_pattern(key)

        save_png(os.path.join(out_dir, f"{key}_p.png"), 300, 450, pattern)
        save_png(os.path.join(out_dir, f"{key}_grid.png"), 460, 215, pattern)
        save_png(os.path.join(out_dir, f"{key}_hero.png"), 480, 155, pattern)
        save_png(os.path.join(out_dir, f"{key}_logo.png"), 320, 180, logo_pat)


if __name__ == "__main__":
    script_dir = os.path.dirname(os.path.abspath(__file__))
    art_dir = os.path.join(script_dir, "artwork")
    generate_all(art_dir)
