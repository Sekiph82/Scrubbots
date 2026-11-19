"""SB-TF-12 Events art intake: copies the few raster pieces the native Events UI cannot draw
from the owner's read-only Events PNG folder into assets/ui/final/events/, downscaled.

  scenes/<event>.webp      event background, 640 px wide, lossy WebP (shown cover-scaled)
  props/<event>_<n>.webp   key props, longest side 256 px, lossy WebP with alpha
  icons/<event>.png        event icon (Home activity buttons + cards), 256 px 8-bit PNG
  kit/<piece>.webp         shared kit pieces the references show (laurel, checkered flags, sparkle
                           lines, star; named by their picture: some kit file names are swapped)
                           and the ScrubBots logo (from the repo branding logo), lossy WebP

Everything else (ribbons, pills, panels, bubbles, buttons, nodes, glow) is native Godot UI.
The source folder is only read, never written.

Run: python tools/events_art_intake.py "<Events PNG folder>"
"""
import json
import os
import sys

from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "assets", "ui", "final", "events")
SCENE_W = 640
PROP_MAX = 256
ICON = 256
QUALITY = 78
## kit/<name>.webp <- ui_kit/common/<file> (the picture, not the file name, decides the name)
KIT = {"laurel": "laurel_left", "flag_left": "checkered_flag_left", "flag_right": "checkered_flag_right",
       "sparkle_left": "sparkle_lines_left", "sparkle_right": "sparkle_lines_right", "star": "icon_close_button"}
KIT_MAX = 128
LOGO_W = 520


def props() -> dict:
    with open(os.path.join(ROOT, "data", "config", "events_v02_tutorials.json"), encoding="utf-8") as f:
        return {k: v["props"] for k, v in json.load(f)["events"].items()}


def main(src: str) -> None:
    for d in ("scenes", "props", "icons", "kit"):
        os.makedirs(os.path.join(OUT, d), exist_ok=True)
    for eid, names in sorted(props().items()):
        bg = Image.open(os.path.join(src, "ui_kit", eid, "background.png")).convert("RGB")
        bg = bg.resize((SCENE_W, round(bg.height * SCENE_W / bg.width)), Image.LANCZOS)
        bg.save(os.path.join(OUT, "scenes", eid + ".webp"), "WEBP", quality=QUALITY, method=6)
        for n in names:
            im = Image.open(os.path.join(src, "ui_kit", eid, n + ".png")).convert("RGBA")
            im = im.crop(im.getbbox())
            im.thumbnail((PROP_MAX, PROP_MAX), Image.LANCZOS)
            im.save(os.path.join(OUT, "props", "%s_%s.webp" % (eid, n)), "WEBP", quality=QUALITY, method=6)
        ic = Image.open(os.path.join(src, "icons", eid + ".png")).convert("RGBA").resize((ICON, ICON), Image.LANCZOS)
        ic.quantize(256, Image.FASTOCTREE).save(os.path.join(OUT, "icons", eid + ".png"), optimize=True)

    for name, f in KIT.items():
        im = Image.open(os.path.join(src, "ui_kit", "common", f + ".png")).convert("RGBA")
        im = im.crop(im.getbbox())
        im.thumbnail((KIT_MAX, KIT_MAX), Image.LANCZOS)
        im.save(os.path.join(OUT, "kit", name + ".webp"), "WEBP", quality=QUALITY, method=6)
    logo = Image.open(os.path.join(ROOT, "assets", "ui", "final", "branding", "logo_colorful.png")).convert("RGBA")
    logo = logo.resize((LOGO_W, round(logo.height * LOGO_W / logo.width)), Image.LANCZOS)
    logo.save(os.path.join(OUT, "kit", "logo.webp"), "WEBP", quality=QUALITY, method=6)


if __name__ == "__main__":
    main(sys.argv[1])
