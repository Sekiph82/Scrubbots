#!/usr/bin/env python3
"""SB-M22-026 texture inventory for assets/ui/final/** (stdlib only).

Prints one CSV row per PNG: source size, alpha, resident RGBA8 MiB (at the
imported size when process/size_limit caps it, and at source size),
size_limit, the largest literal draw size found next to every runtime use of
the path ("unknown" otherwise), the UI-ADR-008 action and the runtime
referencing files, then a per-folder MiB table.
Run from the repo root: python tools/m22_026_texture_inventory.py
"""
import os
import re
import struct
import sys

FINAL = "assets/ui/final"
# Runtime sources only: tests, docs and coordination evidence are not loads.
REF_ROOTS = ["scripts", "data", "assets/ui/HOME_ASSET_MANIFEST.json"]
REF_EXT = (".gd", ".tscn", ".tres", ".json")
MIN_SIZE = re.compile(r"custom_minimum_size\s*=\s*(\w+(?:\([^()]*\))?)\s*$")
VEC2 = re.compile(r"^Vector2\(\s*([\w.]+)\s*,\s*([\w.]+)\s*\)$")
NUM_CONST = re.compile(r"^\s*const\s+(\w+)\s*(?::\s*\w+\s*)?:?=\s*([\d.]+|Vector2\([^()]*\))\s*(?:#.*)?$")
CONST_DEF = re.compile(r"^\s*const\s+(\w+)\s*:?=\s*\"[^\"]*\"")
KEY_DEF = re.compile(r"^\s*\"(\w+)\"\s*:\s*\"[^\"]*\"")
WINDOW = 4
INLINE_VEC2 = re.compile(r"Vector2\([^()]*\)")
COLOR_TYPES = {0: "gray", 2: "rgb", 3: "indexed", 4: "gray+alpha", 6: "rgba"}


def png_info(path):
    with open(path, "rb") as f:
        head = f.read(33)
        w, h, _, ctype = struct.unpack(">IIBB", head[16:26])
        alpha = ctype in (4, 6)
        if not alpha and ctype in (0, 2, 3):
            # A tRNS chunk gives gray/rgb/indexed images transparency.
            f.seek(8)
            while True:
                hdr = f.read(8)
                if len(hdr) < 8:
                    break
                n, kind = struct.unpack(">I4s", hdr)
                if kind == b"tRNS":
                    alpha = True
                    break
                if kind in (b"IDAT", b"IEND"):
                    break
                f.seek(n + 4, 1)
    return w, h, COLOR_TYPES.get(ctype, str(ctype)), alpha


def size_limit(png):
    try:
        with open(png + ".import", encoding="utf-8") as f:
            m = re.search(r"^process/size_limit=(\d+)", f.read(), re.M)
        return int(m.group(1)) if m else 0
    except OSError:
        return 0


def capped(w, h, limit):
    if limit <= 0 or max(w, h) <= limit:
        return w, h
    s = limit / max(w, h)
    return max(1, round(w * s)), max(1, round(h * s))


def ref_files():
    for root in REF_ROOTS:
        if os.path.isfile(root):
            yield root
            continue
        for d, _, files in os.walk(root):
            for f in files:
                if f.endswith(REF_EXT):
                    yield os.path.join(d, f).replace("\\", "/")


def literal(expr, consts):
    """Largest side of a literal custom_minimum_size value (number consts resolved), else 0."""
    expr = consts.get(expr, expr)
    m = VEC2.match(expr)
    if not m:
        return 0
    sides = [consts.get(v, v) for v in m.groups()]
    if not all(re.fullmatch(r"[\d.]+", v) for v in sides):
        return 0
    return max(float(v) for v in sides)


def draw_side(lines, idx, consts):
    """Largest literal size near every use of the path on line idx; 0 when any use has none.

    A use is the path line itself, or a line naming the const / dict key it is bound to.
    Sizes: custom_minimum_size within WINDOW lines, or a Vector2 literal on the use line
    (helpers like set_hero(path, Vector2(w, h), ...)).
    """
    m = CONST_DEF.match(lines[idx]) or KEY_DEF.match(lines[idx])
    uses = [idx]
    if m:
        name = m.group(1)
        pat = re.compile(r"\b%s\b" % re.escape(name)) if CONST_DEF.match(lines[idx]) else re.compile(r"[\"']%s[\"']" % re.escape(name))
        uses = [i for i, l in enumerate(lines) if i != idx and pat.search(l)]
    best = 0
    for i in uses:
        side = max([0] + [literal(v, consts) for v in INLINE_VEC2.findall(lines[i])])
        for l in lines[max(0, i - WINDOW): i + WINDOW + 1]:
            for expr in MIN_SIZE.findall(l):
                side = max(side, literal(expr, consts))
        if not side:
            return 0
        best = max(best, side)
    return best


def action(w, h, limit, draw, refs):
    """UI-ADR-008 rule: cap small UI art at the next power of two >= 4x its draw side (min 256)."""
    if limit:
        return "size_limit=%d" % limit
    if not refs:
        return "untouched: no literal runtime reference"
    if not draw:
        return "untouched: draw size unknown"
    if draw >= 540:
        return "untouched: draw >= 540 px"
    if max(w, h) < 4 * draw:
        return "untouched: source < 4x draw"
    cap = 256
    while cap < 4 * draw:
        cap *= 2
    if cap >= max(w, h):
        return "untouched: cap %d >= source" % cap
    return "CANDIDATE size_limit=%d" % cap


def main():
    texts = {}
    for p in ref_files():
        with open(p, encoding="utf-8", errors="replace") as f:
            texts[p] = f.read().splitlines()
    consts = {p: {m.group(1): m.group(2) for m in map(NUM_CONST.match, lines) if m} for p, lines in texts.items()}
    pngs = sorted(os.path.join(d, f).replace("\\", "/")
                  for d, _, fs in os.walk(FINAL) for f in fs if f.endswith(".png"))
    folders = {}
    print("path,width,height,color_type,alpha,source_mib,size_limit,loaded_mib,draw_px,action,refs")
    for p in pngs:
        w, h, ctype, alpha = png_info(p)
        limit = size_limit(p)
        lw, lh = capped(w, h, limit)
        src_mib = w * h * 4 / 1048576
        mib = lw * lh * 4 / 1048576
        refs, sides = [], []
        for f, lines in texts.items():
            hits = [i for i, l in enumerate(lines) if p in l]
            if hits:
                refs.append(f)
                sides += [draw_side(lines, i, consts[f]) for i in hits]
        # Known only when every reference has a literal size; one unknown use makes it unknown.
        draw = max(sides) if sides and all(sides) else 0
        draw_txt = "%g" % draw if draw else "unknown"
        print("%s,%d,%d,%s,%s,%.2f,%d,%.2f,%s,%s,%s" % (p, w, h, ctype, "yes" if alpha else "no",
              src_mib, limit, mib, draw_txt, action(w, h, limit, draw, refs), ";".join(refs) or "-"))
        folder = p.split("/")[3]
        row = folders.setdefault(folder, [0, 0.0, 0.0])
        row[0] += 1
        row[1] += src_mib
        row[2] += mib
    print()
    print("| folder | PNGs | source MiB | loaded MiB |")
    print("|---|---:|---:|---:|")
    tot = [0, 0.0, 0.0]
    for k in sorted(folders):
        n, s, a = folders[k]
        tot = [tot[0] + n, tot[1] + s, tot[2] + a]
        print("| %s | %d | %.1f | %.1f |" % (k, n, s, a))
    print("| **total** | %d | %.1f | %.1f |" % tuple(tot))
    return 0


if __name__ == "__main__":
    sys.exit(main())
