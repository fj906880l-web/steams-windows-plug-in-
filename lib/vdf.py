"""
lib/vdf.py - Standalone Binary and Text VDF parser and serializer.
Zero external dependencies, fully compatible with SteamOS python3.
"""

import struct
import binascii
from io import BytesIO


BIN_TYPE_NONE = 0x00      # Sub-dictionary
BIN_TYPE_STRING = 0x01    # Null-terminated UTF-8 string
BIN_TYPE_INT32 = 0x02     # 32-bit signed integer (little-endian)
BIN_TYPE_FLOAT32 = 0x03   # 32-bit float (little-endian)
BIN_TYPE_PTR = 0x04       # Pointer
BIN_TYPE_WSTRING = 0x05   # Wide string
BIN_TYPE_COLOR = 0x06     # Color
BIN_TYPE_UINT64 = 0x07    # 64-bit unsigned int
BIN_TYPE_END = 0x08       # End of sub-dictionary


def read_cstring(stream):
    """Read a null-terminated UTF-8 string from a binary stream."""
    chars = bytearray()
    while True:
        b = stream.read(1)
        if not b or b == b"\x00":
            break
        chars.extend(b)
    return chars.decode("utf-8", errors="replace")


def binary_loads(data):
    """Parse binary VDF data into a nested Python dict."""
    stream = BytesIO(data)
    return _parse_binary_dict(stream)


def _parse_binary_dict(stream):
    result = {}
    while True:
        type_byte = stream.read(1)
        if not type_byte or type_byte == bytes([BIN_TYPE_END]):
            break

        t = type_byte[0]
        key = read_cstring(stream)

        if t == BIN_TYPE_NONE:
            # Sub-dictionary
            val = _parse_binary_dict(stream)
            result[key] = val
        elif t == BIN_TYPE_STRING:
            val = read_cstring(stream)
            result[key] = val
        elif t == BIN_TYPE_INT32:
            buf = stream.read(4)
            if len(buf) < 4:
                break
            val = struct.unpack("<i", buf)[0]
            result[key] = val
        elif t == BIN_TYPE_FLOAT32:
            buf = stream.read(4)
            if len(buf) < 4:
                break
            val = struct.unpack("<f", buf)[0]
            result[key] = val
        elif t == BIN_TYPE_UINT64:
            buf = stream.read(8)
            if len(buf) < 8:
                break
            val = struct.unpack("<Q", buf)[0]
            result[key] = val
        else:
            # Unknown type or malformed byte; stop to prevent infinite loop
            break

    return result


def binary_dumps(data):
    """Serialize a nested Python dict into binary VDF bytes."""
    buf = bytearray()
    for key, value in data.items():
        _serialize_binary_item(buf, key, value)
    buf.append(BIN_TYPE_END)
    return bytes(buf)


def _serialize_binary_item(buf, key, value):
    key_bytes = str(key).encode("utf-8") + b"\x00"

    if isinstance(value, dict):
        buf.append(BIN_TYPE_NONE)
        buf.extend(key_bytes)
        for sub_key, sub_val in value.items():
            _serialize_binary_item(buf, sub_key, sub_val)
        buf.append(BIN_TYPE_END)
    elif isinstance(value, str):
        buf.append(BIN_TYPE_STRING)
        buf.extend(key_bytes)
        buf.extend(value.encode("utf-8") + b"\x00")
    elif isinstance(value, bool):
        buf.append(BIN_TYPE_INT32)
        buf.extend(key_bytes)
        buf.extend(struct.pack("<i", 1 if value else 0))
    elif isinstance(value, int):
        # Decide between int32 and uint64
        if -0x80000000 <= value <= 0x7FFFFFFF:
            buf.append(BIN_TYPE_INT32)
            buf.extend(key_bytes)
            buf.extend(struct.pack("<i", value))
        else:
            buf.append(BIN_TYPE_UINT64)
            buf.extend(key_bytes)
            buf.extend(struct.pack("<Q", value & 0xFFFFFFFFFFFFFFFF))
    elif isinstance(value, float):
        buf.append(BIN_TYPE_FLOAT32)
        buf.extend(key_bytes)
        buf.extend(struct.pack("<f", value))
    elif isinstance(value, (list, tuple)):
        # Represent list as sub-dictionary with stringified integer indices
        buf.append(BIN_TYPE_NONE)
        buf.extend(key_bytes)
        for idx, item in enumerate(value):
            _serialize_binary_item(buf, str(idx), item)
        buf.append(BIN_TYPE_END)
    else:
        # Fallback string
        buf.append(BIN_TYPE_STRING)
        buf.extend(key_bytes)
        buf.extend(str(value).encode("utf-8") + b"\x00")


def generate_steam_appid(exe, name):
    """
    Generate the 32-bit unsigned Steam Non-Steam Shortcut AppID.
    Calculated as (CRC32(exe + name) | 0x80000000).
    """
    key = (exe + name).encode("utf-8")
    crc = binascii.crc32(key) & 0xFFFFFFFF
    return crc | 0x80000000


def signed_appid(unsigned_appid):
    """Convert 32-bit unsigned appid to signed int32 for shortcuts.vdf."""
    return struct.unpack("<i", struct.pack("<I", unsigned_appid & 0xFFFFFFFF))[0]


def dumps_text(data, indent=0):
    """Simple KeyValues text VDF serializer for controller configs."""
    lines = []
    prefix = "\t" * indent
    for k, v in data.items():
        if isinstance(v, dict):
            lines.append(f'{prefix}"{k}"')
            lines.append(f"{prefix}{{")
            lines.append(dumps_text(v, indent + 1))
            lines.append(f"{prefix}}}")
        else:
            lines.append(f'{prefix}"{k}"\t\t"{v}"')
    return "\n".join(lines)
