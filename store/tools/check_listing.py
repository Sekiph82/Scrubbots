"""Check every store/listing/*.md block against its store character limit.

A field is a `## Name (limit)` heading followed by one fenced block. For "Play 500 / App Store
4000" the smallest limit applies. Also checks the screenshot and graphic sizes.
Run from the repo root: python store/tools/check_listing.py   (exit 1 on any failure)
"""
import re
import sys
from pathlib import Path

from PIL import Image

STORE = Path(__file__).resolve().parents[1]
FIELD = re.compile(r"^## (.+?) \(([^)]*)\)\n```\n(.*?)\n```", re.M | re.S)
SHOTS = {"google_play": (1080, 2160), "app_store_6.9in": (1290, 2796), "app_store_6.5in": (1242, 2688)}
GRAPHICS = {"google_play_icon_512.png": (512, 512), "app_store_icon_1024.png": (1024, 1024),
            "google_play_feature_graphic_1024x500.png": (1024, 500)}

bad = 0
for md in sorted((STORE / "listing").glob("*.md")):
    fields = FIELD.findall(md.read_text(encoding="utf-8"))
    for name, limit, text in fields:
        cap = min(int(n) for n in re.findall(r"\d+", limit))
        ok = 0 < len(text) <= cap
        if name.endswith("keywords") and (" ," in text or ", " in text):
            ok = False   # App Store keywords: commas without spaces
        bad += not ok
        print(f"{'OK  ' if ok else 'FAIL'} {md.name} {name}: {len(text)}/{cap}")
    if len(fields) != 7:
        bad += 1
        print(f"FAIL {md.name}: {len(fields)} fields, expected 7")

for folder, size in SHOTS.items():
    for lang in ("en", "tr"):
        shots = sorted((STORE / "screenshots" / folder / lang).glob("*.png"))
        sizes_ok = all(Image.open(p).size == size and Image.open(p).mode == "RGB" for p in shots)
        ok = 4 <= len(shots) <= 8 and sizes_ok
        bad += not ok
        print(f"{'OK  ' if ok else 'FAIL'} screenshots {folder}/{lang}: {len(shots)} x {size}")

for name, size in GRAPHICS.items():
    im = Image.open(STORE / "graphics" / name)
    ok = im.size == size and im.mode == "RGB"
    bad += not ok
    print(f"{'OK  ' if ok else 'FAIL'} graphic {name}: {im.size} {im.mode}")

print("STORE LISTING CHECK: %s" % ("PASS" if bad == 0 else f"FAIL ({bad})"))
sys.exit(1 if bad else 0)
