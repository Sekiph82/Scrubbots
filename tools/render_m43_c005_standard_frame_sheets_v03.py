"""M43-C005-C006 V03 - audit-only 3x3 compositing sheets of Standard frames 01..09.

Composites every frame over checkerboard / white / 50 % gray / black, labels 01..09 OUTSIDE
the image area (evidence only, never shipping UI).

Usage: python tools/render_m43_c005_standard_frame_sheets_v03.py <frame_dir> <out_dir> <prefix>
"""
import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

CELL = (340, 510)   # 1024x1536 scaled by 1/3 (keeps 2:3)
LABEL_H = 44
PAD = 16
BACKGROUNDS = {"checkerboard": None, "white": (255, 255, 255, 255), "gray": (128, 128, 128, 255), "black": (0, 0, 0, 255)}


def checker(size, sq=32):
    img = Image.new("RGBA", size, (255, 255, 255, 255))
    d = ImageDraw.Draw(img)
    for y in range(0, size[1], sq):
        for x in range(0, size[0], sq):
            if (x // sq + y // sq) % 2:
                d.rectangle([x, y, x + sq - 1, y + sq - 1], fill=(204, 204, 204, 255))
    return img


def main():
    src, out, prefix = Path(sys.argv[1]), Path(sys.argv[2]), sys.argv[3]
    out.mkdir(parents=True, exist_ok=True)
    frames = sorted(src.glob("frame_0*.png"))
    assert len(frames) == 9, frames
    font = ImageFont.load_default(size=30)
    for bg_name, bg in BACKGROUNDS.items():
        W = 3 * CELL[0] + 4 * PAD
        H = 3 * (CELL[1] + LABEL_H) + 4 * PAD
        sheet = Image.new("RGBA", (W, H), (255, 0, 255, 255))   # magenta gutter = outside the images
        draw = ImageDraw.Draw(sheet)
        for i, p in enumerate(frames):
            im = Image.open(p).convert("RGBA")
            base = checker(im.size) if bg is None else Image.new("RGBA", im.size, bg)
            base.alpha_composite(im)
            x = PAD + (i % 3) * (CELL[0] + PAD)
            y = PAD + (i // 3) * (CELL[1] + LABEL_H + PAD)
            draw.rectangle([x, y, x + CELL[0] - 1, y + LABEL_H - 1], fill=(20, 20, 20, 255))
            draw.text((x + 10, y + 6), "%02d  %s" % (i + 1, p.stem.split("_", 2)[2]), fill=(255, 255, 255, 255), font=font)
            sheet.paste(base.resize(CELL, Image.LANCZOS), (x, y + LABEL_H))
        path = out / ("%s_%s_01_09.png" % (prefix, bg_name))
        sheet.convert("RGB").save(path, optimize=True)
        print("SHEET", path)


if __name__ == "__main__":
    main()
