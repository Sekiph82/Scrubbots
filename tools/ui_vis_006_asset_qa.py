#!/usr/bin/env python3
"""SB-UI-VIS-006 / SB-UI-031 pixel-level QA of the images the game draws (Pillow + numpy + scipy).

Audits every ACTIVE_RUNTIME / DYNAMIC_REF image of the SB-M22-027 inventory CSV and writes one
CSV row per image. Checks (UI art = PNGs under assets/ui/final/):
  fringe     semi-transparent silhouette pixels (alpha 16..224 with opaque and transparent
             pixels within 2 px; inner glass / glow bands are not edges) that are near-white
             (all >= 225) while the opaque pixels within 2 px are > 80 luma darker: white matte
             bleed (halo), the fringe that shows on the dark BG01 / UI. Dark edge pixels are
             outlines and drop shadows in this art style and vanish on dark backgrounds, so they
             are not counted. WARN when > 5% of those edge pixels and >= 50 px.
  border     share of fully opaque (alpha >= 250) pixels on each canvas edge for art that has
             transparency: art cut by the canvas (cropped). WARN > 10% on an edge while the art
             covers < 85% of the canvas (frames / panels / full-bleed art touch edges by design).
  padding    fully transparent margin outside the alpha bbox: resident MiB spent on nothing.
             WARN when the waste is >= 1 MiB at the imported size.
  glyph      text / watermark candidates: in each corner box (12% of the short side) of a canvas
             with transparency, opaque islands of 4..0.2% of the art that are > 2 px away from
             the largest island; on opaque art (short side >= 128 px), a corner whose strong-edge
             density is >= 3x the image's. CANDIDATE only (a human looks), never a FAIL.
  white_bg   all four corner pixels opaque near-white (>= 240): a generator background that was
             never removed (shows as a white box on the dark UI). WARN.
  empty      no pixel with alpha > 0: FAIL.
  res        imported size (size_limit applied) over the largest visible drawn rect in physical
             px (tests/tools/m22_026_texture_measure.gd JSON, 3 phone/tablet sizes), on the axis
             that fits: max(imp_w / drawn_w, imp_h / drawn_h); a keep-aspect draw magnifies at
             least this much, a stretch / cover draw more. < 1 FAIL (upscaled on screen), < 2
             WARN, no visible measurement = "unmeasured". Nine-patch frames stretch only their
             middle, so for them it is a lower bound of the corner sharpness, not a defect.
  import     compress/mode=0 (lossless), mipmaps/generate=false, process/fix_alpha_border=true,
             process/premult_alpha=false; FAIL otherwise. Also notes when the .import is not
             tracked in git (Godot recreates it with the same defaults on import).
  memory     resident MiB at the imported size (RGBA8, 4 bytes/px, no mipmaps; as UI-ADR-008).
Level art (assets/art/levels/) is logical pixel art drawn with nearest filtering: only the
alpha must be binary (0 = VOID / 255 = ACTIVE) and the import lossless; it is upscaled by design.
SVGs are vector (brand: imported at their declared size; addons/ = editor-only plugin icons) and
get only the import check.

Run from the repo root after `godot --headless --import` (every image has its .import):
  python -I tools/ui_vis_006_asset_qa.py [--inventory=<m22_027 csv>] [--measure=<measure.json>]
      [--csv=docs/ui_vis_006_asset_qa.csv]
Without --measure the drawn sizes are taken from the existing --csv (re-run keeps them).
Prints counts and every WARN / FAIL / CANDIDATE row. Source images are only read.
"""
import csv
import json
import subprocess
import sys
from pathlib import Path

import numpy as np
from PIL import Image
from scipy import ndimage

ROOT = Path(__file__).resolve().parent.parent
MIB = 1024.0 * 1024.0
FINAL = "assets/ui/final/"
LEVEL_ART = "assets/art/levels/"
REQUIRED_IMPORT = {"compress/mode": "0", "mipmaps/generate": "false",
                   "process/fix_alpha_border": "true", "process/premult_alpha": "false"}
FIELDS = ["path", "class", "kind", "src_w", "src_h", "alpha", "size_limit", "imp_w", "imp_h",
          "resident_mib", "drawn_w", "drawn_h", "res_ratio", "res", "import", "import_tracked",
          "fringe_px", "fringe_pct", "border_opaque_pct", "coverage_pct", "padding_waste_pct",
          "padding_waste_mib", "glyph_corners", "verdict", "notes"]


def read_import(path):
    params = {}
    try:
        text = (ROOT / (path + ".import")).read_text(encoding="utf-8")
    except OSError:
        return None
    section = ""
    for line in text.splitlines():
        if line.startswith("["):
            section = line.strip("[]")
        elif section == "params" and "=" in line:
            k, v = line.split("=", 1)
            params[k] = v
    return params


def luma(rgb):
    return rgb[..., 0] * 0.299 + rgb[..., 1] * 0.587 + rgb[..., 2] * 0.114


def fringe(rgba):
    """(halo px, % of semi-transparent edge px): matte-coloured edge pixels next to opaque art."""
    a = rgba[..., 3]
    opaque = (a == 255).astype(np.float32)
    semi = (a >= 16) & (a <= 224)
    cnt = ndimage.uniform_filter(opaque, size=5, mode="constant")
    clear = ndimage.uniform_filter((a < 16).astype(np.float32), size=5, mode="constant")
    near = semi & (cnt > 0) & (clear > 0)   # silhouette edge: between opaque art and transparency
    n = int(near.sum())
    if n == 0:
        return 0, 0.0
    rgb = rgba[..., :3].astype(np.float32)
    lum = luma(rgb)
    mean = ndimage.uniform_filter(lum * opaque, size=5, mode="constant") / np.maximum(cnt, 1e-6)
    white = (rgb >= 225).all(axis=2)
    halo = near & white & (mean < lum - 80)
    k = int(halo.sum())
    return k, 100.0 * k / n


def glyph_corners(rgba, has_transparency):
    """Corner names holding detached small opaque islands (transparent canvas) or dense edges."""
    h, w = rgba.shape[:2]
    s = max(8, int(min(w, h) * 0.12))
    boxes = {"tl": (slice(0, s), slice(0, s)), "tr": (slice(0, s), slice(w - s, w)),
             "bl": (slice(h - s, h), slice(0, s)), "br": (slice(h - s, h), slice(w - s, w))}
    hits = []
    if has_transparency:
        # Pieces within 2 px of each other (anti-aliased tips of rounded corners) are one island.
        solid = ndimage.binary_dilation(rgba[..., 3] >= 128, iterations=2)
        labels, n = ndimage.label(solid)
        if n < 2:
            return hits
        sizes = np.bincount(labels.ravel())
        sizes[0] = 0
        biggest = int(sizes.argmax())
        small = (sizes >= 4) & (sizes <= max(4, sizes.sum() * 0.002))
        small[biggest] = False
        for name, (ys, xs) in boxes.items():
            ids = np.unique(labels[ys, xs])
            if small[ids[ids > 0]].any():
                hits.append(name)
    elif min(w, h) >= 128:   # a strip / tiny icon corner is just its outline
        lum = luma(rgba[..., :3].astype(np.float32))
        edges = (np.abs(np.diff(lum, axis=1))[:-1, :] + np.abs(np.diff(lum, axis=0))[:, :-1]) > 64
        dens = max(float(edges.mean()), 1e-6)
        for name, (ys, xs) in boxes.items():
            if float(edges[ys, xs].mean()) >= 3 * dens and float(edges[ys, xs].mean()) > 0.05:
                hits.append(name)
    return hits


def drawn_sizes(measure, csv_path):
    drawn = {}
    if measure:
        data = json.loads(Path(measure).read_text(encoding="utf-8"))
        for entries in data["scenarios"].values():
            for rel, e in entries.items():
                if not e["visible"] or e["max_w"] <= 0 or e["max_h"] <= 0:
                    continue
                scale = min(e["max_w"] / e["source_w"], e["max_h"] / e["source_h"])
                if scale > drawn.get(FINAL + rel, (0, 0, 0))[2]:
                    drawn[FINAL + rel] = (int(e["max_w"]), int(e["max_h"]), scale)
    elif csv_path.exists():
        for r in csv.DictReader(csv_path.open(encoding="utf-8")):
            if r["drawn_w"]:
                drawn[r["path"]] = (int(r["drawn_w"]), int(r["drawn_h"]), 0)
    return drawn


def audit(path, cls, drawn, tracked):
    r = {"path": path, "class": cls, "notes": []}
    kind = ("level_art" if path.startswith(LEVEL_ART) else "ui_final" if path.startswith(FINAL)
            else "editor_svg" if path.startswith("addons/") else "brand_svg" if path.endswith(".svg")
            else "other")
    r["kind"] = kind
    fails, warns = [], []
    imp = read_import(path)
    r["import_tracked"] = "yes" if path + ".import" in tracked else "no"
    if imp is None:
        r["import"] = "missing"
        fails.append("no .import (run godot --import)")
    else:
        bad = [k for k, v in REQUIRED_IMPORT.items() if k in imp and imp[k] != v]
        if path.endswith(".svg"):
            bad = [k for k in bad if k.startswith("compress") or k.startswith("mipmaps")]
        r["import"] = "ok" if not bad else "bad:" + ";".join("%s=%s" % (k, imp[k]) for k in bad)
        if bad:
            fails.append("import " + r["import"])
    if path.endswith(".svg"):
        r["verdict"] = "FAIL" if fails else "PASS"
        r["notes"] = "; ".join(fails + ["vector, pixel checks n/a"] + (["editor-only plugin icon"] if kind == "editor_svg" else []))
        return r
    im = Image.open(ROOT / path)
    w, h = im.size
    rgba = np.asarray(im.convert("RGBA"))
    a = rgba[..., 3]
    has_t = bool((a < 255).any())
    limit = int(imp.get("process/size_limit", "0")) if imp else 0
    s = limit / max(w, h) if 0 < limit < max(w, h) else 1.0
    iw, ih = max(1, round(w * s)), max(1, round(h * s))
    resident = iw * ih * 4 / MIB
    r.update(src_w=w, src_h=h, alpha="yes" if has_t else "no", size_limit=limit, imp_w=iw, imp_h=ih,
             resident_mib="%.2f" % resident)
    if not (a > 0).any():
        fails.append("fully transparent")
    if kind == "level_art":
        if ((a > 0) & (a < 255)).any():
            fails.append("level art alpha not binary 0/255")
        r["res"] = "pixel art (nearest)"
    else:
        if path in drawn:
            dw, dh = drawn[path][:2]
            ratio = max(iw / dw, ih / dh)
            r["drawn_w"], r["drawn_h"] = dw, dh
            r["res_ratio"] = "%.2f" % ratio
            r["res"] = "FAIL" if ratio < 1 else "WARN" if ratio < 2 else "ok"
            if ratio < 1:
                fails.append("under-res %.2fx (%dx%d drawn %dx%d)" % (ratio, iw, ih, dw, dh))
            elif ratio < 2:
                warns.append("under 2x (%.2fx: %dx%d drawn %dx%d)" % (ratio, iw, ih, dw, dh))
        else:
            r["res"] = "unmeasured"
        if has_t:
            k, pct = fringe(rgba)
            r["fringe_px"], r["fringe_pct"] = k, "%.1f" % pct
            if pct > 5 and k >= 50:
                warns.append("matte halo %d px (%.1f%% of edge px)" % (k, pct))
            solid = a >= 250
            edge = max(solid[0].mean(), solid[-1].mean(), solid[:, 0].mean(), solid[:, -1].mean())
            cover = float((a > 8).mean())
            r["border_opaque_pct"], r["coverage_pct"] = "%.1f" % (100 * edge), "%.1f" % (100 * cover)
            if edge > 0.10 and cover < 0.85:
                warns.append("opaque art on canvas edge (%.0f%%): cropped?" % (100 * edge))
            ys, xs = np.nonzero(a > 0)
            if len(ys):
                waste = 1 - ((ys.max() - ys.min() + 1) * (xs.max() - xs.min() + 1)) / (w * h)
                r["padding_waste_pct"], r["padding_waste_mib"] = "%.1f" % (100 * waste), "%.2f" % (waste * resident)
                if waste * resident >= 1.0:
                    warns.append("transparent padding %.0f%% = %.2f MiB" % (100 * waste, waste * resident))
        corners = rgba[[0, 0, -1, -1], [0, -1, 0, -1]]
        if (corners[:, 3] == 255).all() and (corners[:, :3] >= 240).all():
            warns.append("opaque white background corners")
        g = glyph_corners(rgba, has_t)
        r["glyph_corners"] = " ".join(g)
        if g:
            r["notes"].append("text/watermark CANDIDATE " + ",".join(g))
    if imp is not None and r["import_tracked"] == "no":
        r["notes"].append(".import untracked (Godot defaults)")
    r["verdict"] = "FAIL" if fails else "WARN" if warns else "PASS"
    r["notes"] = "; ".join(fails + warns + r["notes"])
    return r


def main(argv):
    opts = dict(a[2:].split("=", 1) for a in argv if a.startswith("--") and "=" in a)
    inv = ROOT / opts.get("inventory", "docs/m22_027_image_inventory.csv")
    out = ROOT / opts.get("csv", "docs/ui_vis_006_asset_qa.csv")
    drawn = drawn_sizes(opts.get("measure"), out)
    tracked = set(subprocess.check_output(["git", "ls-files", "*.import"], cwd=ROOT, text=True).split())
    rows = [audit(r["path"], r["class"], drawn, tracked)
            for r in csv.DictReader(inv.open(encoding="utf-8"))
            if r["class"] in ("ACTIVE_RUNTIME", "DYNAMIC_REF")]
    with out.open("w", encoding="utf-8", newline="") as f:
        wr = csv.DictWriter(f, FIELDS, lineterminator="\n")
        wr.writeheader()
        wr.writerows(rows)
    counts = {}
    for r in rows:
        counts[r["verdict"]] = counts.get(r["verdict"], 0) + 1
    print("%d images: %s; resident %.2f MiB" % (len(rows), counts, sum(float(r.get("resident_mib") or 0) for r in rows)))
    for r in rows:
        if r["verdict"] != "PASS" or r.get("glyph_corners"):
            print("%s\t%s\t%s" % (r["verdict"], r["path"], r["notes"]))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
