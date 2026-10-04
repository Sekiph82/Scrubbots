"""M43-C005-C006 V03 (SB-M43-064) - rendered-pixel alpha / matte validator.

Examines decoded RGBA pixels (never manifest claims). A frame is CLEAN only if:
  * 1024x1536 RGBA;
  * the canvas border band and corners are fully transparent;
  * no large dark visible component (alpha >= 16, colour max-channel < 40) exists - a black
    matte or a dark veil is one huge component; the pack's own dark art (outlines, visor)
    is split into small pieces by the bright art around it;
  * no semi-transparent dark wash (16 <= alpha <= 230 with dark colour) beyond a small budget;
  * no straight rectangular boundary: the visible region (alpha >= 8) never fills most of
    a side of its own bounding box (a matte rectangle fills ~100 % of all four sides);
  * no straight cut: along each side of the alpha bbox no run longer than MAX_EDGE_RUN px
    has alpha >= EDGE_CUT_A (light chopped by a straight canvas edge).

Usage:
  python tools/validate_m43_c005_standard_frame_alpha_v03.py <dir> [<dir> ...]
  python tools/validate_m43_c005_standard_frame_alpha_v03.py --sensitivity <clean_dir> <dirty_dir>
Exit 1 when any expectation fails.
"""
import json
import sys
from pathlib import Path

import numpy as np
from PIL import Image
from scipy import ndimage

SIZE = (1024, 1536)
VIS_A = 16            # alpha that visibly tints a background
DARK = 40             # colour max-channel below which a visible pixel reads as dark/black
MAX_DARK_COMPONENT = 25000
MAX_DARK_WASH = 8000
BORDER = 24           # canvas border band that must be fully transparent
MAX_SIDE_FILL = 0.55  # fraction of a bbox side covered by visible pixels
EDGE_CUT_A = 24       # alpha that reads as a visible straight cut on a light background
MAX_EDGE_RUN = 64     # px


def analyse(rgba):
    rgba = np.asarray(rgba)
    h, w = rgba.shape[:2]
    A = rgba[..., 3].astype(np.int32)
    c = rgba[..., :3].astype(np.int32).max(axis=2)
    fails = []
    if (w, h) != SIZE or rgba.shape[2] != 4:
        fails.append("size_or_mode")
    vis = A >= 8
    ys, xs = np.where(vis)
    bbox = [int(xs.min()), int(ys.min()), int(xs.max()), int(ys.max())] if xs.size else None
    border = np.zeros_like(vis)
    border[:BORDER, :] = border[-BORDER:, :] = True
    border[:, :BORDER] = border[:, -BORDER:] = True
    border_nonzero = int((A[border] > 0).sum())
    if border_nonzero:
        fails.append("border_not_transparent")
    dark = (A >= VIS_A) & (c < DARK)
    lab, n = ndimage.label(dark, structure=np.ones((3, 3)))
    sizes = ndimage.sum(dark, lab, index=np.arange(1, n + 1)) if n else np.array([0])
    largest = int(sizes.max()) if n else 0
    if largest > MAX_DARK_COMPONENT:
        fails.append("large_dark_component")
    wash = int(((A >= VIS_A) & (A <= 230) & (c < DARK)).sum())
    if wash > MAX_DARK_WASH:
        fails.append("dark_wash")
    side_fill = {}
    if bbox:
        x0, y0, x1, y1 = bbox
        side_fill = {"top": float(vis[y0, x0:x1 + 1].mean()), "bottom": float(vis[y1, x0:x1 + 1].mean()),
                     "left": float(vis[y0:y1 + 1, x0].mean()), "right": float(vis[y0:y1 + 1, x1].mean())}
        if max(side_fill.values()) > MAX_SIDE_FILL:
            fails.append("rectangular_boundary")
        lines = {"top": A[y0, x0:x1 + 1], "bottom": A[y1, x0:x1 + 1], "left": A[y0:y1 + 1, x0], "right": A[y0:y1 + 1, x1]}
        edge_runs = {k: _longest_run(v >= EDGE_CUT_A) for k, v in lines.items()}
        if max(edge_runs.values()) > MAX_EDGE_RUN:
            fails.append("straight_edge_cut")
    else:
        edge_runs = {}
    return {
        "size": [w, h], "mode": "RGBA" if rgba.shape[2] == 4 else "?",
        "alpha_bbox": bbox,
        "transparent_px": int((A == 0).sum()), "opaque_px": int((A == 255).sum()),
        "semi_px": int(((A > 0) & (A < 255)).sum()),
        "dark_visible_px": int(dark.sum()), "dark_components": int(n),
        "largest_dark_component_px": largest, "dark_wash_px": wash,
        "border_nonzero_px": border_nonzero,
        "corner_alpha": [int(A[0, 0]), int(A[0, -1]), int(A[-1, 0]), int(A[-1, -1])],
        "bbox_side_fill": {k: round(v, 3) for k, v in side_fill.items()},
        "bbox_edge_cut_run_px": edge_runs,
        "failures": fails, "clean": not fails,
    }


def _longest_run(mask):
    best = cur = 0
    for v in mask:
        cur = cur + 1 if v else 0
        best = max(best, cur)
    return int(best)


def over_black(rgba):
    a = np.asarray(rgba).astype(np.float64)
    return a[..., :3] * a[..., 3:4] / 255.0


def over_black_diff(before, after):
    d = np.abs(over_black(before) - over_black(after))
    return {"max": round(float(d.max()), 2), "p999": round(float(np.percentile(d, 99.9)), 2),
            "mean": round(float(d.mean()), 4)}


def registration(before, after):
    """Bright-art (over-black max-channel >= 150) bbox + centroid before vs after."""
    out = {}
    for k, img in (("before", before), ("after", after)):
        m = over_black(img).max(axis=2) >= 150
        ys, xs = np.where(m)
        out[k] = {"bbox": [int(xs.min()), int(ys.min()), int(xs.max()), int(ys.max())],
                  "centroid": [round(float(xs.mean()), 2), round(float(ys.mean()), 2)]}
    out["centroid_shift_px"] = round(float(np.hypot(out["before"]["centroid"][0] - out["after"]["centroid"][0],
                                                     out["before"]["centroid"][1] - out["after"]["centroid"][1])), 3)
    out["bbox_equal"] = out["before"]["bbox"] == out["after"]["bbox"]
    return out


def load(path):
    return np.array(Image.open(path).convert("RGBA"))


def sensitivity(clean_dir, dirty_dir):
    """Expected: every clean frame passes; dirty 05/07/09 (+06/08 wash) fail; injected black /
    semi-transparent dark rectangles fail."""
    results = []
    ok = True
    for p in sorted(Path(clean_dir).glob("frame_*.png")):
        img = load(p)
        r = analyse(img)
        results.append({"case": "clean " + p.name, "expect_clean": True, "clean": r["clean"], "failures": r["failures"]})
        opaque = img.copy()
        opaque[200:1300, 150:870] = [0, 0, 0, 255]
        opaque[300:1100, 300:720] = img[300:1100, 300:720]   # art on top of a black box
        r1 = analyse(opaque)
        results.append({"case": "inserted opaque black rectangle " + p.name, "expect_clean": False, "clean": r1["clean"], "failures": r1["failures"]})
        semi = img.copy()
        box = semi[100:1450, 100:924].astype(np.float64)
        a = box[..., 3:4] / 255.0
        wa = 0.45
        out_a = a + wa * (1 - a)
        box[..., :3] = np.divide(box[..., :3] * a + 8.0 * wa * (1 - a), out_a, out=np.zeros_like(box[..., :3]), where=out_a > 0)
        box[..., 3:4] = out_a * 255.0
        semi[100:1450, 100:924] = np.round(box).astype(np.uint8)
        r2 = analyse(semi)
        results.append({"case": "inserted semi-transparent dark rectangle " + p.name, "expect_clean": False, "clean": r2["clean"], "failures": r2["failures"]})
    for p in sorted(Path(dirty_dir).glob("frame_0[5-9]*.png")):
        r = analyse(load(p))
        results.append({"case": "historical " + p.name, "expect_clean": False, "clean": r["clean"], "failures": r["failures"]})
    for r in results:
        good = r["clean"] == r["expect_clean"]
        ok = ok and good
        print(("ok  " if good else "FAIL") + " %-70s clean=%s %s" % (r["case"], r["clean"], r["failures"]))
    return ok, results


def main():
    if sys.argv[1] == "--sensitivity":
        ok, results = sensitivity(sys.argv[2], sys.argv[3])
        if len(sys.argv) > 4:
            Path(sys.argv[4]).write_text(json.dumps(results, indent=2) + "\n")
        print("SENSITIVITY", "PASS" if ok else "FAIL")
        sys.exit(0 if ok else 1)
    ok = True
    for d in sys.argv[1:]:
        for p in sorted(Path(d).glob("frame_*.png")):
            r = analyse(load(p))
            ok = ok and r["clean"]
            print("%-5s %s largest_dark=%d wash=%d side_fill=%s border=%d %s" % (
                "CLEAN" if r["clean"] else "DIRTY", p, r["largest_dark_component_px"], r["dark_wash_px"],
                r["bbox_side_fill"], r["border_nonzero_px"], r["failures"]))
    sys.exit(0 if ok else 1)


if __name__ == "__main__":
    main()
