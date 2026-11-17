"""Store graphics composed from owner-approved art only (no generation).

Play icon 512x512, App Store icon 1024x1024 (opaque) and Play feature graphic 1024x500.
Run from the repo root: python store/tools/make_graphics.py
"""
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "store" / "graphics"
PLAZA = ROOT / "assets/ui/final/home/background/home_background_plaza.png"
ICON = ROOT / "assets/ui/final/branding/app_icon_ios_1024.png"
LOGO = ROOT / "assets/ui/final/branding/logo_colorful.png"
SCRUBBY = ROOT / "assets/ui/final/characters/scrubby/scrubby_master.png"


def fit(im, w, h):
    return im.resize((round(w), round(h)), Image.LANCZOS)


def icon(size):
    plaza = Image.open(PLAZA).convert("RGB")
    sky = fit(plaza.crop((0, 0, plaza.width, plaza.width)), size, size).convert("RGBA")
    logo = fit(Image.open(ICON).convert("RGBA"), size, size)
    sky.alpha_composite(logo)
    return sky.convert("RGB")   # stores want an opaque icon


def feature():
    plaza = Image.open(PLAZA).convert("RGB")
    s = 1024 / plaza.width
    plaza = fit(plaza, 1024, plaza.height * s)
    top = round(780 * s)   # the tree line and the tile floor
    bg = plaza.crop((0, top, 1024, top + 500)).convert("RGBA")
    logo = Image.open(LOGO).convert("RGBA")
    logo = fit(logo, 600, logo.height * 600 / logo.width)
    bg.alpha_composite(logo, (24, (500 - logo.height) // 2 - 10))
    bot = Image.open(SCRUBBY).convert("RGBA")
    bot = fit(bot, bot.width * 470 / bot.height, 470)
    bg.alpha_composite(bot, (1024 - bot.width - 30, 500 - bot.height - 8))
    return bg.convert("RGB")


if __name__ == "__main__":
    OUT.mkdir(parents=True, exist_ok=True)
    icon(512).save(OUT / "google_play_icon_512.png")
    icon(1024).save(OUT / "app_store_icon_1024.png")
    feature().save(OUT / "google_play_feature_graphic_1024x500.png")
    for p in sorted(OUT.glob("*.png")):
        im = Image.open(p)
        print(p.name, im.size, im.mode)
