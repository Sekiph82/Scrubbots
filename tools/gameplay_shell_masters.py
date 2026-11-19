"""Build the six plaza gameplay masters from the ONE owner image (job 159 + SB-TF-04, job 184).

Only the owner's own pixels are used (no generation, no new characters):
  * clean plate  = owner image with Scrubby (+ shadow) and the bucket / Caution sign / puddle
                   lifted out (Poisson fill guided by the same floor row one tile period away),
                   the slot-strip corner the bubble used to cover mirrored from the right corner.
  * per variant, after the cut-joins below: the navy board interior lifted to
                   BoardPresentation.BOARD_FLOOR (SB-TF-10).
  * 6 slots / 3 / 5 columns = the job-159 cut-joins (5 columns as re-tuned by job 163), applied
                   to the clean plate (unchanged code).
  * then, per variant, three owner layers composited back BEHIND the slot strip and Supply panel:
      speech bubble  owner bubble, baked sentence erased, body widened to the right so it runs
                     under the Supply panel (tail kept where it was, pointing at Scrubby);
      Scrubby        x1.25 about his bottom-left foot corner, feet 54 px lower (SCRUBBY_ANCHOR);
      props          bucket + Caution sign + puddle x0.75 about the bottom-right corner, 125 px
                     higher, beside the Supply panel (PROPS_ANCHOR).
Rail, slot frames/interiors, connectors and Supply cells stay where they were.
usage: python -I tools/gameplay_shell_masters.py <owner.png> <out_dir>
(owner image: factory/jobs/159-gameplay-shell-plaza/owner_gameplay_shell_plaza_5slot_4col.png)
"""
import sys
from pathlib import Path

import numpy as np
from PIL import Image
from scipy import ndimage
from scipy.sparse import coo_matrix
from scipy.sparse.linalg import splu

SRC_W, SRC_H = 852, 1846
# Measured on the owner image (job 159 measure.py + ruler crops).
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

# SB-TF-04 (owner 2026-11-18). Old -> new anchors (gameplay_screen.gd SCRUBBY/PROPS_ANCHOR).
SCRUBBY_OLD = (14, 1325, 262, 1600)
SCRUBBY_SCALE, SCRUBBY_FOOT = 1.25, (14, 1600, 14, 1654)    # (src x, src y) -> (dst x, dst y)
PROPS_OLD = (600, 1230, 845, 1625)
PROPS_SCALE, PROPS_FOOT = 0.75, (845, 1625, 845, 1500)
BUBBLE_SEAM, BUBBLE_WIDEN = 188, 90  # straight body column right of the tail; extra width
STRIP_MIRROR = 857                   # strip is symmetric: x <-> 857 - x (192+665, 269+588)
# Board floor: BoardPresentation.BOARD_FLOOR (SB-TF-10 owner rail-glow blue); the baked navy field is lifted onto it.
BOARD_FIELD = (105, 318, 746, 946)
NAVY = np.array([0, 55, 123])
FLOOR = np.array([0, 104, 216])
# One-point floor grid (vertical grout lines meet at y FLOOR_YH; period U per px below it).
FLOOR_YH, FLOOR_U, FLOOR_GUIDE_Y0 = 1241.0, 0.304, 1500


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


def five_cols(a, s=0.95, pitch=87):
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
    # 3. Widen the emptied panel 19 px left / 21 px right: a column pitch of 87 keeps every
    #    5-column front hitbox >= 88 px on a 1080x1920 phone, and 0.95-scale cells keep the
    #    colour symbol >= 32 px on 720x1280 (job 163). The halves move out and the plain
    #    interior column at the centre fills the middle; the left edge stops at Scrubby's hand.
    wy0, wy1, wl, wr = 1176, 1515, 19, 21
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


# ------------------------------------------------------------------ SB-TF-04 edits --

def floorish(a):
    """Bare plaza paving (peach .. lavender), not items, shadows, water, bushes or panels."""
    r, g, b = (a[..., i].astype(int) for i in range(3))
    return (r > 185) & (r - g > 22) & (g > 130) & (b > 130) & (b < 225)


def item_hull(a, boxes):
    """Everything that is not bare paving inside `boxes`, holes filled, grown 4 px."""
    win = np.zeros(a.shape[:2], bool)
    for x0, y0, x1, y1 in boxes:
        win[y0:y1, x0:x1] = True
    m = win & ~floorish(a)
    m = ndimage.binary_opening(m, iterations=1)
    lab, n = ndimage.label(ndimage.binary_closing(m, iterations=4))
    sizes = ndimage.sum(np.ones_like(lab), lab, range(1, n + 1))
    keep = np.isin(lab, [i + 1 for i, s in enumerate(sizes) if s >= 40])
    return ndimage.binary_dilation(ndimage.binary_fill_holes(keep), iterations=4) & win


def floor_period(y):
    return FLOOR_U * (y - FLOOR_YH)


def poisson_fill(a, hole, src_ok):
    """Fill `hole` so its edges meet the surrounding pixels; inside, the gradients come from the
    same floor row shifted by whole grout periods (rows >= FLOOR_GUIDE_Y0 with clean paving),
    elsewhere the fill is harmonic."""
    h, w = hole.shape
    af = a.astype(float)
    guide = np.full(af.shape, np.nan)
    shift = np.zeros((h, w), int)          # which period copy guides each pixel
    ys, xs = np.nonzero(hole)
    for y, x in zip(ys, xs):
        if y < FLOOR_GUIDE_Y0:
            continue
        p = floor_period(y)
        for k in (1, -1, 2, -2, 3, -3, 4, -4, 5, -5):
            sx = int(round(x + k * p))
            if 0 <= sx < w and src_ok[y, sx]:
                guide[y, x] = af[y, sx]
                shift[y, x] = k
                break
    idx = -np.ones((h, w), int)
    idx[ys, xs] = np.arange(len(ys))
    rows, cols, vals = [], [], []
    rhs = np.zeros((len(ys), 3))
    for i, (y, x) in enumerate(zip(ys, xs)):
        rows.append(i)
        cols.append(i)
        vals.append(4.0)
        for dy, dx in ((-1, 0), (1, 0), (0, -1), (0, 1)):
            qy, qx = min(max(y + dy, 0), h - 1), min(max(x + dx, 0), w - 1)
            if hole[qy, qx]:
                rows.append(i)
                cols.append(idx[qy, qx])
                vals.append(-1.0)
            else:
                rhs[i] += af[qy, qx]
            gp, gq = guide[y, x], guide[qy, qx]
            # no gradient across the seam between two different period copies
            if shift[y, x] == shift[qy, qx] and not (np.isnan(gp).any() or np.isnan(gq).any()):
                rhs[i] += gp - gq
    lu = splu(coo_matrix((vals, (rows, cols)), shape=(len(ys), len(ys))).tocsc())
    out = af.copy()
    for c in range(3):
        out[ys, xs, c] = lu.solve(rhs[:, c])
    return out.clip(0, 255)


def brighten_board(p):
    """Lift the baked navy board field onto FLOOR (vignette and bevel kept)."""
    x0, y0, x1, y1 = BOARD_FIELD
    reg = p[y0:y1, x0:x1].astype(float)
    d = np.sqrt(((reg - np.array([1, 50, 112])) ** 2).sum(axis=2))
    wgt = np.clip(1.0 - (d - 25.0) / 25.0, 0.0, 1.0)[..., None]
    p[y0:y1, x0:x1] = (reg + wgt * (FLOOR - NAVY)).clip(0, 255)
    return p


def mirror_strip_corner(p, a):
    """The owner bubble covered the strip's bottom-left corner: take the right corner, mirrored
    (only where the bubble was, so every other strip / slot pixel stays the owner's)."""
    sm = strip_mask(a.shape) * ndimage.binary_dilation(bubble_mask(a) > 0.02, iterations=2)
    y0, y1, x0, x1 = 1140, 1180, 160, 222
    src = a[y0:y1, STRIP_MIRROR - x1 + 1:STRIP_MIRROR - x0 + 1][:, ::-1].astype(float)
    al = sm[y0:y1, x0:x1][..., None]
    p[y0:y1, x0:x1] = src * al + p[y0:y1, x0:x1] * (1 - al)
    return p


def item_layer(a, plate, hull):
    """Opacity (a far from the clean plate) and a soft difference weight (shadows, glints)."""
    d = np.abs(a.astype(float) - plate).max(axis=2) * hull
    alpha = np.clip((d - 30.0) / 30.0, 0.0, 1.0)
    alpha = np.maximum(alpha, ndimage.binary_fill_holes(alpha > 0.5) * 1.0)
    weight = np.clip((d - 6.0) / 10.0, 0.0, 1.0)
    return alpha, weight


def warp(arr, scale, foot, box, order):
    """Sample `arr` (H,W[,C]) for every pixel of dst `box`: src = sfoot + (dst - dfoot) / scale."""
    sx, sy, dx, dy = foot
    x0, y0, x1, y1 = box
    yy, xx = np.mgrid[y0:y1, x0:x1].astype(float)
    cy = sy + (yy + 0.5 - dy) / scale - 0.5
    cx = sx + (xx + 0.5 - dx) / scale - 0.5
    if arr.ndim == 2:
        return ndimage.map_coordinates(arr, [cy, cx], order=order, mode="constant", cval=0.0)
    return np.stack([ndimage.map_coordinates(arr[..., c], [cy, cx], order=order, mode="nearest")
                     for c in range(arr.shape[2])], axis=-1)


def moved_item(a, plate, hull, scale, foot):
    """(box, alpha, weight, rgb, diff) of an item layer moved/scaled onto its new anchor."""
    alpha, weight = item_layer(a, plate, hull)
    ys, xs = np.nonzero(hull)
    sx, sy, dx, dy = foot
    bx0 = int(np.floor(dx + (xs.min() - sx) * scale)) - 2
    bx1 = int(np.ceil(dx + (xs.max() + 1 - sx) * scale)) + 2
    by0 = int(np.floor(dy + (ys.min() - sy) * scale)) - 2
    by1 = int(np.ceil(dy + (ys.max() + 1 - sy) * scale)) + 2
    box = (max(bx0, 0), max(by0, 0), min(bx1, SRC_W), min(by1, SRC_H))
    af = a.astype(float)
    if scale < 1.0:   # pre-filter before shrinking (no aliased sparkle on the bubbles)
        af = ndimage.gaussian_filter(af, (0.45, 0.45, 0))
    rgb = warp(af, scale, foot, box, 3).clip(0, 255)
    diff = warp(af - plate, scale, foot, box, 1)
    return box, warp(alpha, scale, foot, box, 1).clip(0, 1), warp(weight, scale, foot, box, 1).clip(0, 1), rgb, diff


def put_item(out, item, behind):
    box, alpha, weight, rgb, diff = item
    x0, y0, x1, y1 = box
    base = out[y0:y1, x0:x1].astype(float)
    vis = 1.0 - behind[y0:y1, x0:x1]
    al = (alpha * vis)[..., None]
    wt = (weight * vis)[..., None]
    shaded = (base + diff * wt).clip(0, 255)
    out[y0:y1, x0:x1] = (rgb * al + shaded * (1 - al)).round().clip(0, 255).astype(np.uint8)


def bubble_hull(a):
    """Owner bubble + its soft drop shadow, never the slot strip it overlapped."""
    return ndimage.binary_dilation(bubble_mask(a) > 0.05, iterations=8) & (strip_mask(a.shape) == 0)


def new_bubble(a, plate, hull):
    """Owner bubble layer, baked sentence erased, body (and shadow) widened right of the tail."""
    alpha, weight = item_layer(a, plate, hull)
    alpha = np.maximum(alpha, bubble_mask(a))   # the plate under the old strip corner is cream too
    rgb = a.astype(float).copy()
    diff = rgb - plate
    x0, y0, x1, y1 = BUBBLE
    body = ndimage.binary_erosion(bubble_mask(a) > 0.99, iterations=5)
    ink = ndimage.binary_dilation(body & (rgb.mean(axis=2) < 242), iterations=2)
    # cream of every body row from its unlettered pixels, rows without any taken from neighbours
    cream = np.full((SRC_H, 3), np.nan)
    for y in range(y0, y1):
        clean = body[y] & ~ink[y]
        if clean.sum() >= 8:
            cream[y] = np.median(rgb[y, clean], axis=0)
    rows = [y for y in range(y0, y1) if body[y].any()]
    known = [y for y in rows if not np.isnan(cream[y, 0])]
    for c in range(3):
        cream[rows, c] = ndimage.gaussian_filter1d(np.interp(rows, known, cream[known, c]), 2.0)
    for y in rows:
        rgb[y, body[y]] = cream[y]
    s, n = BUBBLE_SEAM, BUBBLE_WIDEN
    box = (0, y0 - 14, x1 + n + 14, y1 + 14)
    out = []
    for arr in (alpha, weight, rgb, diff):
        wide = arr.copy()
        wide[:, s + n:] = arr[:, s:SRC_W - n]
        wide[:, s:s + n] = arr[:, s:s + 1]
        out.append(wide[box[1]:box[3], box[0]:box[2]])
    return (box, *out)


def foreground_mask(shape):
    """Owner slot strip + Supply panel (with its clip tops): drawn in front of the three items."""
    from PIL import ImageDraw
    k = 4
    m = Image.new("L", (shape[1] * k, shape[0] * k), 0)
    ImageDraw.Draw(m).rounded_rectangle((PANEL[0] * k, PANEL[1] * k, PANEL[2] * k, PANEL[3] * k), radius=22 * k, fill=255)
    pm = np.asarray(m.resize((shape[1], shape[0]), Image.BOX)) / 255.0
    return np.maximum(strip_mask(shape), pm)


def clean_plate(a):
    bubble = bubble_hull(a)
    scrubby = item_hull(a, [(0, 1320, 224, 1625), (0, 1508, 280, 1625)]) & ~bubble
    props = item_hull(a, [(650, 1234, SRC_W, 1640), (595, 1505, SRC_W, 1640)])
    hull = bubble | scrubby | props
    p = poisson_fill(a, hull, floorish(a) & ~ndimage.binary_dilation(hull, iterations=6))
    p = mirror_strip_corner(p, a)
    return p, bubble, scrubby, props


def main(src_path, out_dir):
    out_dir = Path(out_dir)
    out_dir.mkdir(parents=True, exist_ok=True)
    a = np.asarray(Image.open(src_path).convert("RGB"))
    assert a.shape[:2] == (SRC_H, SRC_W), a.shape
    plate, bubble_h, scrubby_hull, props_hull = clean_plate(a)
    plate8 = plate.round().astype(np.uint8)
    bubble = new_bubble(a, plate, bubble_h)
    scrubby = moved_item(a, plate, scrubby_hull, SCRUBBY_SCALE, SCRUBBY_FOOT)
    props = moved_item(a, plate, props_hull, PROPS_SCALE, PROPS_FOOT)
    fg = (foreground_mask(a.shape) * 255).astype(np.uint8)
    fg3 = np.repeat(fg[..., None], 3, axis=2)
    six, seams = six_slots(plate8)
    six_fg = six_slots(fg3)[0]
    print("6-slot rail joins at x =", seams)
    supply = {"3col": three_cols, "4col": None, "5col": lambda x: five_cols(x)[0]}
    for slots, base, base_fg in (("5slot", plate8, fg3), ("6slot", six, six_fg)):
        for cols, fn in supply.items():
            o = base if fn is None else fn(base)
            f = base_fg if fn is None else fn(base_fg)
            # After the cut-joins, so the 6-slot seam search never sees the lifted field (SB-TF-10).
            o = brighten_board(o.astype(float)).round().astype(np.uint8)
            behind = ndimage.gaussian_filter((f[..., 0] > 127).astype(float), 0.6)
            o = o.copy()
            put_item(o, scrubby, behind)   # the bubble overlaps the tip of his leaf
            put_item(o, bubble, behind)
            put_item(o, props, behind)
            Image.fromarray(o).save(out_dir / f"gameplay_v03_plaza_shell_{slots}_{cols}.png", optimize=True)
            print("wrote", slots, cols)


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2])
