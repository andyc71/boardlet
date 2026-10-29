#!/usr/bin/env python3
"""Add one unique PNG to a simulator's local Files provider; never replace files."""
import argparse
import json
from pathlib import Path
import struct
import subprocess
from urllib.parse import unquote, urlparse
import uuid
import zlib

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("device", type=uuid.UUID, help="Existing simulator UUID")
args = parser.parse_args()
inventory = subprocess.check_output(["xcrun", "simctl", "listapps", str(args.device)])
converted = subprocess.run(
    ["plutil", "-convert", "json", "-o", "-", "-"],
    input=inventory, capture_output=True, check=True,
)
apps = json.loads(converted.stdout)
container = apps["com.apple.DocumentsApp"]["GroupContainers"]["group.com.apple.FileProvider.LocalStorage"]
folder = Path(unquote(urlparse(container).path)) / "File Provider Storage"
if not folder.is_dir():
    raise SystemExit("Open Files on this simulator once to initialize local storage.")

def chunk(kind, payload):
    return struct.pack(">I", len(payload)) + kind + payload + struct.pack(">I", zlib.crc32(kind + payload))

pixels = b"".join(
    b"\0" + b"".join(bytes((20, 180, 210) if x < 32 else (110, 40, 180)) for x in range(64))
    for _ in range(64)
)
png = b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", struct.pack(">IIBBBBB", 64, 64, 8, 2, 0, 0, 0))
png += chunk(b"IDAT", zlib.compress(pixels)) + chunk(b"IEND", b"")
name = "BoardScanner-Artwork-" + str(uuid.uuid4()) + ".png"
with (folder / name).open("xb") as output:
    output.write(png)
print(name)
