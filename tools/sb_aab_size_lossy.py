"""SB-AAB-SIZE-2026-11-17: lossy WebP import for the big illustrated UI art (download size).

The release AAB base module must stay under Google Play's 200 MB limit. Every PNG under
assets/ui/final/ whose source file is >= MIN_BYTES imports as Godot "Lossy" (WebP, alpha kept
lossless by libwebp) at QUALITY, except the KEEP_LOSSLESS prefixes: booster glow/ring states and
gameplay effects (alpha gradients band), branding (launcher/app icons). Pixel art (assets/art/levels/)
is outside assets/ui/final/ and stays lossless. Only the .import compress/* keys change; source PNGs
are untouched. tests/ui_vis_006_asset_qa.gd enforces the same partition.

Usage: python -I tools/sb_aab_size_lossy.py [--write]   (run after `godot --headless --import`)
"""
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
FINAL = ROOT / "assets" / "ui" / "final"
MIN_BYTES = 100 * 1024
QUALITY = "0.8"
KEEP_LOSSLESS = ("boosters/", "gameplay/effects/", "branding/")


def lossy(rel, size):
    return size >= MIN_BYTES and not rel.startswith(KEEP_LOSSLESS)


def main(argv):
    write = "--write" in argv
    changed = 0
    missing = []
    for png in sorted(FINAL.rglob("*.png")):
        rel = png.relative_to(FINAL).as_posix()
        imp = png.with_name(png.name + ".import")
        if not imp.exists():
            missing.append(rel)
            continue
        raw = imp.read_bytes()
        mode = b"1" if lossy(rel, png.stat().st_size) else b"0"
        new = re.sub(rb"(?m)^compress/mode=\d+", b"compress/mode=" + mode, raw)
        if mode == b"1":
            new = re.sub(rb"(?m)^compress/lossy_quality=[\d.]+", b"compress/lossy_quality=" + QUALITY.encode(), new)
        if new != raw:
            changed += 1
            print("%s mode=%s" % (rel, mode.decode()))
            if write:
                imp.write_bytes(new)
    print("%d .import %s; %d PNGs without .import (run godot --import first)" % (changed, "written" if write else "to change", len(missing)))
    return 1 if missing else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
