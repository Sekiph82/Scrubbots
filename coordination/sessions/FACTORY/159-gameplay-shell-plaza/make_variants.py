"""Build the six plaza gameplay masters from the ONE owner image (job 159).

Only the owner's own pixels are used (no generation):
  * 5slot_4col  = owner file, byte-identical copy.
  * 6 slots     = cut-join of the slot strip + connector band + bottom rail at two slot-gap
                  midlines (one extra real slot period, centred); bubble re-composited on top.
  * 3 columns   = cut-join of the supply panel at two cell-gap midlines (one column period
                  removed, centred); the two uncovered floor strips are rebuilt row by row
                  from the floor right beside the old panel edge.
  * 5 columns   = supply panel emptied (interior rebuilt row by row from its own border
                  colour), then 15 real cell tiles (frame + top clip) at 0.84 scale laid on the
                  original row centres, 5 columns centred on the panel.
usage: python -I make_variants.py <owner.png> <out_dir>
"""
import shutil
import sys
from pathlib import Path

import numpy as np
from PIL import Image
from scipy import ndimage

SRC_W, SRC_H = 852, 1846
# Measured on the owner image (measure.py + ruler crops).
SLOT_PITCH = 99                      # 192,290,390,489,588 (interiors)
SLOT_CUT_L, SLOT_CUT_R = 379, 478    # gap midlines slot2|3 and slot3|4 (478 - 379 = 99)
SEAM_6 = 429                         # new x where the two strip halves meet
RAIL_Y0, PIPE_Y0, STRIP_Y1 = 940, 1008, 1180   # bottom rail band, pipe band, below strip
COL_PITCH = 97                       # 249,346,443,540 (interiors)
COL_CUT_L, COL_CUT_R = 433, 530      # gap midlines col2|3 and col3|4
PANEL = (229, 1184, 637, 1502)       # supply panel outer box
PANEL_Y0, PANEL_Y1 = 1180, 1515      # rows the supply edit touches (clips top .. shadow)
MARGIN_X0, MARGIN_X1 = 218, 648      # panel + its shadow margin
CELL_COLS = [(249, 325), (346, 423), (443, 520), (540, 617)]
CELL_ROWS = [(1204, 1279), (1307, 1382), (1409, 1484)]
BUBBLE = (14, 1150, 214, 1345)


def strip_mask(shape):
    """Anti-aliased rounded rect of the owner slot strip (measured 174..683 x 1064..1172, r 24)."""
    from PIL import ImageDraw
    k = 4
    m = Image.new("L", (shape[1] * k, shape[0] * k), 0)
    ImageDraw.Draw(m).rounded_rectangle((173 * k, 1063 * k, 685 * k, 1173 * k), radius=24 * k, fill=255)
    return np.asarray(m.resize((shape[1], shape[0]), Image.BOX)) / 255.0


def bubble_mask(a):
    r, g, b = a[..., 0], a[..., 1], a[..., 2]
    cream = (r > 225) & (g > 215) & (b > 195) & (r - b > 3)
    x0, y0, x1, y1 = BUBBLE
    win = np.zeros_like(cream)
    win[y0 - 4:y1 + 4, x0 - 4:x1 + 4] = True
    lab, _ = ndimage.label(cream & win)
    big = max(range(1, lab.max() + 1), key=lambda i: (lab == i).sum())
    m = ndimage.binary_closing(ndimage.binary_fill_holes(lab == big), iterations=3)
    m = ndimage.binary_erosion(ndimage.binary_opening(m, iterations=2), iterations=1)
    # soft 1 px edge so the cream outline anti-aliases onto whatever now sits behind it
    return np.clip(ndimage.gaussian_filter(m.astype(float), 0.8) * 1.6, 0.0, 1.0) * win


def best_seam(a, rows, xs, shift):
    """x in xs where column x and column x+shift differ least over `rows` (clean join)."""
    band = a[rows[0]:rows[1]]
    return min(xs, key=lambda x: np.abs(band[:, x - 2:x + 3] - band[:, x + shift - 2:x + shift + 3]).sum())


def six_slots(a):
    """One more real slot period: new(x) = src(x+49) left of SEAM_6, src(x-50) right of it."""
    out = a.copy()
    w = a.shape[1]
    xs = np.arange(w)
    m = np.where(xs < SEAM_6, xs + (SLOT_CUT_R - SEAM_6), xs - (SEAM_6 - SLOT_CUT_L))
    m = np.clip(m, 0, w - 1)
    # Bottom rail: hard joins at the cleanest rail columns between the corner hubs.
    lc = best_seam(a, (RAIL_Y0, PIPE_Y0), range(142, 172), SLOT_CUT_R - SEAM_6)
    rc = best_seam(a, (RAIL_Y0, PIPE_Y0), range(700, 716), -(SEAM_6 - SLOT_CUT_L))
    out[RAIL_Y0:PIPE_Y0, lc:rc] = a[RAIL_Y0:PIPE_Y0][:, m[lc:rc]]
    # Pipe band + strip rows: sky feathered in over 10 px at the joins, strip shape always moved.
    alpha = np.zeros(w)
    alpha[lc:rc] = 1.0
    ramp = np.linspace(0.0, 1.0, 12)[1:-1]
    alpha[lc - 5:lc + 5] = ramp
    alpha[rc - 5:rc + 5] = ramp[::-1]
    smask = strip_mask(a.shape)
    band = a[PIPE_Y0:STRIP_Y1].astype(float)
    moved = band[:, m]
    al = np.maximum(alpha[None, :], smask[PIPE_Y0:STRIP_Y1][:, m])
    out[PIPE_Y0:STRIP_Y1] = (moved * al[..., None] + band * (1 - al[..., None])).round().astype(np.uint8)
    return out, (lc, rc)


def three_cols(a):
    """Remove one real column period (col 3) and close the panel symmetrically."""
    out = a.copy()
    y0, y1 = PANEL_Y0, PANEL_Y1
    sl, sr = COL_PITCH // 2, COL_PITCH - COL_PITCH // 2      # 48 right, 49 left
    left = a[y0:y1, MARGIN_X0:COL_CUT_L]
    right = a[y0:y1, COL_CUT_R:MARGIN_X1]
    nl0 = MARGIN_X0 + sl
    out[y0:y1, nl0:nl0 + left.shape[1]] = left
    out[y0:y1, nl0 + left.shape[1]:nl0 + left.shape[1] + right.shape[1]] = right
    # Uncovered floor: every row is interpolated between the floor just outside the gap and
    # the moved panel's own shadow margin, then lightly smoothed down the rows (no streaks).
    out = out.astype(float)
    for g0, g1 in ((MARGIN_X0, nl0), (MARGIN_X1 - sr, MARGIN_X1)):
        # median over a few columns, then down the rows: drops the stray soap bubbles
        lv = ndimage.median_filter(np.median(out[y0:y1, g0 - 4:g0], axis=1), size=(11, 1))
        rv = ndimage.median_filter(np.median(out[y0:y1, g1:g1 + 10], axis=1), size=(11, 1))
        t = np.linspace(0.0, 1.0, g1 - g0 + 2)[None, 1:-1, None]
        fill = lv[:, None, :] * (1 - t) + rv[:, None, :] * t
        out[y0:y1, g0:g1] = ndimage.gaussian_filter1d(fill, 1.2, axis=0)
    return out.round().astype(np.uint8)


def metal_mask(t):
    """Grey metal of a cell's top clip (low saturation, not the blue panel / navy shadow)."""
    t = t.astype(int)
    return ((t[..., 2] - t[..., 0]) < 28) & ((t.max(axis=2) - t.min(axis=2)) < 50)


def five_cols(a, s=0.80, pitch=87):
    """Empty the panel, then lay 5 x 3 real (scaled) cell tiles on the original row centres."""
    out = a.copy().astype(float)
    px0, py0, px1, py1 = PANEL
    # 1. Clip tops above the panel rim (rows 1176..1191): each old clip is erased by
    #    interpolating every row between the pixels just left/right of it.
    ty0, ty1 = 1176, 1192
    for c0, c1 in CELL_COLS:
        cx = (c0 + c1) // 2
        l, r = cx - 31, cx + 31
        t = np.linspace(0.0, 1.0, r - l + 1)[None, 1:-1, None]
        out[ty0:ty1, l + 1:r] = a[ty0:ty1, l:l + 1] * (1 - t) + a[ty0:ty1, r:r + 1] * t
    # 2. Panel interior: every row takes the panel's own colour from the three cell-gap
    #    columns (no clip/cell there), so interior shading and the bottom rim continue.
    y0, y1, ix0, ix1 = ty1, 1494, 244, 624
    gaps = np.concatenate([a[y0:y1, g - 4:g + 5] for g in (335, 433, 530)], axis=1)
    out[y0:y1, ix0:ix1] = np.median(gaps, axis=1)[:, None, :]
    # 3. Widen the emptied panel 18 px left / 17 px right (a column pitch of 87 keeps every
    #    5-column front hitbox >= 88 px on a 1080x1920 phone): the halves move out and the
    #    plain interior column at the centre fills the middle.
    wy0, wy1, wl, wr = 1176, 1515, 18, 17
    src = out.copy()
    out[wy0:wy1, px0 - wl:433 - wl] = src[wy0:wy1, px0:433]
    out[wy0:wy1, 433 + wr:px1 + wr] = src[wy0:wy1, 433:px1]
    out[wy0:wy1, 433 - wl:433 + wr] = src[wy0:wy1, 433:434]
    px0, px1 = px0 - wl, px1 + wr
    cx_mid = (px0 + px1) / 2.0
    src_cols = [0, 1, 2, 2, 3]
    cells = []
    for ry0, ry1 in CELL_ROWS:
        for c in range(5):
            sx0, sx1 = CELL_COLS[src_cols[c]]
            box = (sx0 - 8, ry0 - 26, sx1 + 8, ry1 + 8)        # frame + clip + panel margin
            st = a[box[1]:box[3], box[0]:box[2]]
            # alpha: feathered rectangle for the framed cell (its margin is plain panel blue);
            # the clip rows above the frame keep only the clip's own metal.
            al = np.ones(st.shape[:2])
            clip_rows = 19
            mm = metal_mask(st[:clip_rows])
            mm[:3] = False                                       # previous row's frame rim
            mx = np.abs(np.arange(st.shape[1]) - ((sx0 + sx1) / 2.0 - box[0])) > 25
            mm[:, mx] = False                                    # clip is 50 px wide, centred
            lab, _ = ndimage.label(mm)
            big = np.bincount(lab.ravel())[1:].argmax() + 1      # the clip itself, no stray bits
            cm = ndimage.binary_dilation(ndimage.binary_fill_holes(lab == big), iterations=1)
            al[:clip_rows] = ndimage.gaussian_filter(cm.astype(float), 0.6).clip(0, 1)
            f = 5
            ramp = np.linspace(0.0, 1.0, f + 2)[1:-1]
            al[-f:] *= ramp[::-1][:, None]
            al[:, :f] *= ramp[None, :]
            al[:, -f:] *= ramp[::-1][None, :]
            tw, th = round(st.shape[1] * s), round(st.shape[0] * s)
            tile = np.asarray(Image.fromarray(st).resize((tw, th), Image.LANCZOS)).astype(float)
            alr = np.asarray(Image.fromarray((al * 255).astype(np.uint8)).resize((tw, th), Image.BILINEAR)) / 255.0
            cx = cx_mid + (c - 2) * pitch
            cy = (ry0 + ry1) / 2.0
            ox = int(round(cx - ((sx0 + sx1) / 2.0 - box[0]) * s))
            oy = int(round(cy - ((ry0 + ry1) / 2.0 - box[1]) * s))
            reg = out[oy:oy + th, ox:ox + tw]
            out[oy:oy + th, ox:ox + tw] = tile * alr[..., None] + reg * (1 - alr[..., None])
            cells.append((ox, oy, tw, th))
    return out.round().astype(np.uint8), cells


def recomposite_bubble(out, a):
    al = bubble_mask(a)[..., None]
    return (a * al + out * (1 - al)).round().astype(np.uint8)


def main(src_path, out_dir):
    out_dir = Path(out_dir)
    out_dir.mkdir(parents=True, exist_ok=True)
    a = np.asarray(Image.open(src_path).convert("RGB"))
    assert a.shape[:2] == (SRC_H, SRC_W), a.shape
    shutil.copyfile(src_path, out_dir / "gameplay_v03_plaza_shell_5slot_4col.png")
    six, seams = six_slots(a)
    print("6-slot rail joins at x =", seams)
    supply = {"3col": three_cols, "4col": None, "5col": lambda x: five_cols(x)[0]}
    for slots, base in (("5slot", a), ("6slot", six)):
        for cols, fn in supply.items():
            if slots == "5slot" and cols == "4col":
                continue
            o = base if fn is None else fn(base)
            if slots == "6slot" or cols == "5col":
                o = recomposite_bubble(o.copy(), a)
            Image.fromarray(o).save(out_dir / f"gameplay_v03_plaza_shell_{slots}_{cols}.png", optimize=True)
            print("wrote", slots, cols)


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2])
