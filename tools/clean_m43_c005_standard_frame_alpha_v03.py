"""M43-C005-C006 V03 (SB-M43-064) - Standard pack frame alpha cleanup.

Deterministic, pixel-preserving matte removal for the owner-accepted Standard opening
frames. The accepted look is the frame seen over BLACK (the frames were generated on a
flattened black canvas). For every pixel we keep exactly that over-black colour
P = rgb * a (premultiplied) and only re-derive the alpha:

  * solid objects (pack, torn flaps, cards, shards) stay opaque: the object mask is the
    hole-filled closing of the bright region (so enclosed dark art - outlines, the robot
    visor, card navy - is protected), minus tiny islands, grown by a thin rim so the
    pack's own dark outline stays solid. Its alpha ramps in over FEATHER px so bright glow
    caught inside the mask fades smoothly into light; dark art details inside the mask
    (darker than their neighbourhood) are always kept fully opaque; the card backs of
    frames 06..09 are kept fully opaque inside their exact C002 placement silhouettes
    (manifest card_overlays + the C002 card_layer function);
  * everything else is light over black (glow, rays, sparkles, matte): its alpha is its
    own brightness max(P)/255 with a soft noise floor, and its colour is P / alpha. The
    generator cut that light with a straight line at its flattened canvas edge, so light
    fades to 0 over EDGE_FADE px approaching that edge (no straight cut remains).

Over black the result is the original image (up to the noise floor); over any other
background the black matte disappears and the glow becomes transparent light. Nothing is
redrawn, moved, recoloured or added. A frame that is already clean (no matte detected by
the validator) is copied byte-for-byte.

Usage:
  python tools/clean_m43_c005_standard_frame_alpha_v03.py <src_dir> <dst_dir> <metrics.json>
"""
import hashlib
import json
import sys
from pathlib import Path

import numpy as np
from PIL import Image
from scipy import ndimage

sys.path.insert(0, str(Path(__file__).resolve().parent))
import validate_m43_c005_standard_frame_alpha_v03 as V  # noqa: E402
from rebuild_m43_c005_card_emergence import CARD, card_layer  # noqa: E402  (C002 card placement)

MANIFEST = Path(__file__).resolve().parents[1] / "coordination/sessions/M43-C005-C002/PACK_ASSET_MANIFEST_V01.json"

FRAMES = ["frame_01_closed.png", "frame_02_charge.png", "frame_03_pressure.png",
          "frame_04_first_tear.png", "frame_05_tear_widens.png", "frame_06_card_edge.png",
          "frame_07_one_card_rises.png", "frame_08_cards_emerge.png", "frame_09_final_reveal.png"]

BRIGHT = 200          # max-channel level that seeds the solid-object mask
CLOSE_R = 3           # closing radius (px) bridging thin dark lines inside objects
MIN_ISLAND = 1500     # object components smaller than this are treated as light (sparkles)
RIM = 3               # px of dark outline kept solid around objects
FEATHER = 40.0        # px inward alpha ramp: bright glow caught by the mask fades to light
DETAIL_MAX = 120      # inside objects, pixels darker than this ...
DETAIL_DELTA = 20     # ... and this much darker than their 9x9 neighbourhood are art (outlines)
FLOOR = (6.0, 30.0)   # glow alpha noise floor: below 6 -> 0, full from 30 up
EDGE_FADE = 48.0      # px: light fades to 0 approaching the old flattened-canvas edge (no straight cut)


def disk(r):
    y, x = np.ogrid[-r:r + 1, -r:r + 1]
    return x * x + y * y <= r * r


def object_mask(m):
    seed = ndimage.binary_closing(m >= BRIGHT, structure=disk(CLOSE_R), iterations=1)
    filled = ndimage.binary_fill_holes(seed)
    lab, n = ndimage.label(filled)
    if n:
        sizes = ndimage.sum(filled, lab, index=np.arange(1, n + 1))
        keep = np.zeros(n + 1, bool)
        keep[1:] = sizes >= MIN_ISLAND
        filled = keep[lab]
    return ndimage.binary_dilation(filled, structure=disk(RIM))


def card_mask(name):
    """Opaque interior of the card backs placed in `name` by the C002 compositor."""
    frames = json.loads(MANIFEST.read_text())["frames"]
    spec = next((f for f in frames if f["relative_path"].endswith("/standard/" + name)), None)
    mask = np.zeros((1536, 1024), bool)
    if spec:
        sprite = Image.open(CARD).convert("RGBA")
        for c in spec["card_overlays"]:
            layer = card_layer(sprite, c["center_x"], c["top_y"], c["rotation_degrees"])
            mask |= np.array(layer.getchannel("A")) >= 128
    return mask


def clean(rgba, cards=None):
    a = rgba[..., 3:4].astype(np.float64) / 255.0
    P = rgba[..., :3].astype(np.float64) * a            # over-black colour (accepted look)
    m = P.max(axis=2)
    lo, hi = FLOOR
    floor = np.clip((m - lo) / (hi - lo), 0.0, 1.0)
    floor = floor * floor * (3 - 2 * floor)              # smoothstep
    ys, xs = np.where(rgba[..., 3] > 0)
    yy, xx = np.mgrid[0:m.shape[0], 0:m.shape[1]]
    edge = np.minimum.reduce([xx - xs.min(), xs.max() - xx, yy - ys.min(), ys.max() - yy]).astype(np.float64)
    edge = np.clip(edge / EDGE_FADE, 0.0, 1.0)
    light = np.where(m >= hi, 1.0, floor) * edge
    glow_alpha = (m / 255.0) * light
    obj = object_mask(m)
    inside = ndimage.distance_transform_edt(obj)
    w = np.clip(inside / FEATHER, 0.0, 1.0)
    local = ndimage.uniform_filter(m, size=9)
    detail = obj & (m < DETAIL_MAX) & (m < local - DETAIL_DELTA)
    detail = ndimage.binary_dilation(detail, structure=disk(1)) & obj
    w = np.where(detail, 1.0, w)
    if cards is not None:
        w = np.where(cards, 1.0, w)
    alpha = np.clip(np.maximum(w, glow_alpha), 0.0, 1.0)
    # keep P exactly where the pixel is kept; floored glow is dimmed by the same factor
    keep = np.where(w > 0, 1.0, light)
    premul = P * keep[..., None]
    rgb = np.divide(premul, alpha[..., None], out=np.zeros_like(premul), where=alpha[..., None] > 1e-6)
    out = np.dstack([np.clip(np.round(rgb), 0, 255), np.clip(np.round(alpha * 255.0), 0, 255)]).astype(np.uint8)
    out[out[..., 3] == 0, :3] = 0
    return out, obj


def sha(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()


def main():
    src, dst, metrics_path = Path(sys.argv[1]), Path(sys.argv[2]), Path(sys.argv[3])
    dst.mkdir(parents=True, exist_ok=True)
    rows = []
    for name in FRAMES:
        before = np.array(Image.open(src / name).convert("RGBA"))
        verdict = V.analyse(before)
        if verdict["clean"]:
            (dst / name).write_bytes((src / name).read_bytes())
            action = "copied_unchanged_already_clean"
        else:
            out, _ = clean(before, card_mask(name))
            Image.fromarray(out, "RGBA").save(dst / name, optimize=True)
            action = "alpha_rederived"
        after = np.array(Image.open(dst / name).convert("RGBA"))
        rows.append({"frame": name, "action": action,
                     "sha256_before": sha(src / name), "sha256_after": sha(dst / name),
                     "before": V.analyse(before), "after": V.analyse(after),
                     "over_black_max_abs_diff": V.over_black_diff(before, after),
                     "registration": V.registration(before, after)})
        print(name, action, "clean_after=%s" % rows[-1]["after"]["clean"])
    params = {"BRIGHT": BRIGHT, "CLOSE_R": CLOSE_R, "MIN_ISLAND": MIN_ISLAND, "RIM": RIM,
              "FEATHER": FEATHER, "DETAIL_MAX": DETAIL_MAX, "DETAIL_DELTA": DETAIL_DELTA,
              "FLOOR": list(FLOOR), "EDGE_FADE": EDGE_FADE}
    metrics_path.write_text(json.dumps({"tool": Path(__file__).name, "params": params, "frames": rows}, indent=2) + "\n")


if __name__ == "__main__":
    main()
