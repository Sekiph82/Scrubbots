"""SB-M22-028 - build the Collection card thumbnails.

One lossless PNG per catalog card: the whole 1024x1536 source card scaled to 440x660 (Lanczos,
same 2:3 aspect, no crop, no atlas). 660 px is ~2x the largest set-grid draw (300 logical px ->
325 px at 1170x2532). Source art is only read. Output mirrors the source tree:
assets/ui/final/collection/cards/set_NN/card_NN.png -> assets/ui/final/collection/card_thumbs/set_NN/card_NN.png

Run: python tools/m22_028_card_thumbnails.py [--check]
--check: exit 1 if a thumbnail is missing, has the wrong size or differs from a fresh build.
"""
import io
import sys
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
SRC = ROOT / "assets/ui/final/collection/cards"
DST = ROOT / "assets/ui/final/collection/card_thumbs"
SIZE = (440, 660)


def build(src: Path) -> bytes:
    with Image.open(src) as im:
        thumb = im.convert("RGBA").resize(SIZE, Image.LANCZOS)
    buf = io.BytesIO()
    thumb.save(buf, "PNG", optimize=True)
    return buf.getvalue()


def main() -> int:
    check = "--check" in sys.argv
    srcs = sorted(SRC.glob("set_*/card_*.png"))
    bad = []
    for src in srcs:
        dst = DST / src.relative_to(SRC)
        data = build(src)
        if check:
            if not dst.exists() or dst.read_bytes() != data:
                bad.append(str(dst.relative_to(ROOT)))
            continue
        dst.parent.mkdir(parents=True, exist_ok=True)
        dst.write_bytes(data)
    print("%d cards, %s" % (len(srcs), ("%d stale: %s" % (len(bad), bad[:5])) if bad else ("ok" if check else "written")))
    return 1 if bad or len(srcs) != 135 else 0


if __name__ == "__main__":
    sys.exit(main())
