"""Pixel-analysis measurement of a plaza gameplay master (job 159).

Method: dark-navy interior mask (R<40, G in 25..75, B in 60..140, B > G+25) -> connected
components (scipy.ndimage.label); components are classified by bbox/area into board,
top-bar boxes, execution slots and supply cells. Interiors are the component bboxes
(x1/y1 exclusive). Rail centrelines: midpoint of the bright-metal/blue rail band found by
scanning outwards from the board interior. Connector x: centre of the bright pipe column
between the board bottom rail and the slot strip.
usage: python -I measure.py <png> [--json]
"""
import json
import sys

import numpy as np
from PIL import Image
from scipy import ndimage


def navy_mask(a):
    r, g, b = a[..., 0].astype(int), a[..., 1].astype(int), a[..., 2].astype(int)
    return (r < 40) & (g >= 25) & (g <= 80) & (b >= 60) & (b <= 150) & (b > g + 25)


def components(mask, min_area=1500):
    lab, n = ndimage.label(mask)
    out = []
    for i, sl in enumerate(ndimage.find_objects(lab)):
        area = int((lab[sl] == i + 1).sum())
        if area < min_area:
            continue
        y, x = sl
        out.append({"x0": x.start, "y0": y.start, "x1": x.stop, "y1": y.stop, "area": area})
    return out


def dashes(a, box):
    """Bright cyan-white light dashes: (cx, cy, area) of each component in box."""
    x0, y0, x1, y1 = box
    w = a[y0:y1, x0:x1].astype(int)
    m = (w[..., 0] > 100) & (w[..., 1] > 215) & (w[..., 2] > 240)
    lab, _ = ndimage.label(m)
    out = []
    for i in range(1, lab.max() + 1):
        ar = int((lab == i).sum())
        if ar >= 15:
            cy, cx = ndimage.center_of_mass(lab == i)
            out.append((round(cx + x0, 1), round(cy + y0, 1), ar))
    return out


def dash_axis(a, box, axis, lo, hi):
    """Median centre (x if axis 1 else y) of the dashes whose centre lies in [lo, hi]."""
    v = [d[1 - axis] if axis == 0 else d[0] for d in dashes(a, box) if d[2] >= 100]
    v = [c for c in v if lo <= c <= hi]
    return float(np.median(v))


def measure(path):
    a = np.asarray(Image.open(path).convert("RGB"))
    h, w = a.shape[:2]
    comps = components(navy_mask(a))
    board = max(comps, key=lambda c: c["area"])
    top = sorted([c for c in comps if c["y1"] < 260], key=lambda c: c["x0"])
    below = [c for c in comps if c["y0"] > board["y1"] and 50 < c["x1"] - c["x0"] < 110 and 50 < c["y1"] - c["y0"] < 110]
    slot_y = min(c["y0"] for c in below)
    slots = sorted([c for c in below if c["y0"] < slot_y + 40], key=lambda c: c["x0"])
    cells = [c for c in below if c["y0"] >= slot_y + 40]
    cols = sorted({(c["x0"], c["x1"]) for c in cells})
    rows = sorted({(c["y0"], c["y1"]) for c in cells})
    # Rail centrelines: centroid of the middle light-dash row/column of each rail (the
    # double tube's centre); connector x: the glow cap of each slot pipe on the bottom rail.
    rail = {"left": dash_axis(a, (50, 360, 105, 900), 1, 70, 82),
            "right": dash_axis(a, (745, 360, 800, 900), 1, 768, 780),
            "top": dash_axis(a, (140, 265, 710, 320), 0, 287, 297),
            "bottom": dash_axis(a, (140, 945, 710, 1000), 0, 972, 982)}
    conn = sorted(cx for cx, cy, ar in dashes(a, (120, 945, 740, 1000)) if 960 <= cy <= 968 and 30 <= ar <= 80)
    return {"size": [w, h], "board": board, "top": top, "slots": slots, "cols": cols, "rows": rows,
            "rail": rail, "connector_x": conn, "n_cells": len(cells)}


if __name__ == "__main__":
    m = measure(sys.argv[1])
    print(json.dumps(m, indent=1) if "--json" in sys.argv else m)
