#!/usr/bin/env python3
"""M08 Level Art Technical Audit (SB-M08-001..010, 013, 014). Read-only.

Audits owner level source PNGs: dimensions, alpha/VOID, colours, anti-aliasing,
interpolation/logical grid, the CLAUDE.md section 6 envelope + ADR-030 D2 gate, and
exact mapping of every source colour to palette V3 C01..C16 (exact match or REJECTED,
never C17+). Never writes, resizes or moves source art.

Usage: python tools/audit_level_art.py [png ...]   (default: assets/art/levels/source/**/*.png)
       python tools/audit_level_art.py --self-test
Exit 1 when any image fails.
"""
import glob
import json
import math
import os
import struct
import sys
import zlib

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PALETTE = os.path.join(ROOT, "data", "palettes", "scrubbots_palette_v3.json")
SOURCE_GLOB = os.path.join(ROOT, "assets", "art", "levels", "source", "**", "*.png")
ENVELOPE_MIN, ENVELOPE_MAX = 20, 59  # CLAUDE.md section 6 / DifficultyRules
MIN_ARTWORK_CELLS, MIN_ARTWORK_FRACTION = 200, 0.25  # ADR-030 D2 / ProductionLevelValidator
COLOR_MIN, COLOR_MAX = 3, 12  # palette V3 usedColorEnvelopeV1


def decode_png(data):
    """Decode a non-interlaced 8-bit PNG to (w, h, rows of RGBA tuples)."""
    if data[:8] != b"\x89PNG\r\n\x1a\n":
        raise ValueError("not a PNG")
    pos, idat, plte, trns = 8, b"", None, None
    while pos < len(data):
        length, kind = struct.unpack(">I4s", data[pos:pos + 8])
        body = data[pos + 8:pos + 8 + length]
        pos += 12 + length
        if kind == b"IHDR":
            w, h, depth, ctype, _, _, interlace = struct.unpack(">IIBBBBB", body)
        elif kind == b"PLTE":
            plte = [tuple(body[i:i + 3]) for i in range(0, len(body), 3)]
        elif kind == b"tRNS":
            trns = body
        elif kind == b"IDAT":
            idat += body
    if depth != 8 or interlace:
        raise ValueError("unsupported PNG: bit depth %d, interlace %d" % (depth, interlace))
    channels = {0: 1, 2: 3, 3: 1, 4: 2, 6: 4}[ctype]
    raw, stride, prev, rows, i = zlib.decompress(idat), w * channels, bytearray(w * channels), [], 0
    for _ in range(h):
        ftype, line = raw[i], bytearray(raw[i + 1:i + 1 + stride])
        i += 1 + stride
        for x in range(stride):
            a = line[x - channels] if x >= channels else 0
            b, c = prev[x], prev[x - channels] if x >= channels else 0
            if ftype == 1:
                line[x] = (line[x] + a) & 255
            elif ftype == 2:
                line[x] = (line[x] + b) & 255
            elif ftype == 3:
                line[x] = (line[x] + (a + b) // 2) & 255
            elif ftype == 4:
                p = a + b - c
                pa, pb, pc = abs(p - a), abs(p - b), abs(p - c)
                line[x] = (line[x] + (a if pa <= pb and pa <= pc else b if pb <= pc else c)) & 255
        prev = line
        px = [tuple(line[x:x + channels]) for x in range(0, stride, channels)]
        if ctype == 0:
            px = [(g, g, g, 255) for (g,) in px]
        elif ctype == 4:
            px = [(g, g, g, al) for g, al in px]
        elif ctype == 2:
            px = [(r, g, b2, 255) for r, g, b2 in px]
        elif ctype == 3:
            px = [plte[k] + ((trns[k] if trns and k < len(trns) else 255),) for (k,) in px]
        rows.append(px)
    return w, h, rows


def run_gcd(lines):
    """GCD of all same-colour run lengths: the integer upscale factor along that axis."""
    g = 0
    for line in lines:
        run = 1
        for a, b in zip(line, line[1:] + [None]):
            if a == b:
                run += 1
            else:
                g, run = math.gcd(g, run), 1
    return g


def audit(name, w, h, rows, palette):
    rgb_to_id = {tuple(c["rgb"]): c["id"] for c in palette}
    opaque, partial, void = {}, 0, 0
    for row in rows:
        for p in row:
            if p[3] == 0:
                void += 1
            elif p[3] == 255:
                opaque[p[:3]] = opaque.get(p[:3], 0) + 1
            else:
                partial += 1
    off = {c for c in opaque if c not in rgb_to_id}
    # Anti-aliasing: semi-transparent pixels, or off-palette colours sitting on a colour edge.
    aa_edge = 0
    for y in range(h):
        for x in range(w):
            p = rows[y][x]
            if p[3] == 255 and p[:3] in off:
                nb = [rows[y + dy][x + dx] for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1))
                      if 0 <= x + dx < w and 0 <= y + dy < h]
                aa_edge += any(n != p for n in nb)
    bx = run_gcd(rows)
    by = run_gcd([[rows[y][x] for y in range(h)] for x in range(w)])
    gw, gh = w // bx, h // by
    nonvoid_cells = (w * h - void) // (bx * by)
    mapping = []
    for c in sorted(opaque, key=lambda c: (c not in rgb_to_id, rgb_to_id.get(c, ""), c)):
        hexc = "#%02X%02X%02X" % c
        if c in rgb_to_id:
            mapping.append((hexc, opaque[c], rgb_to_id[c]))
        else:
            near = min(palette, key=lambda p: sum((a - b) ** 2 for a, b in zip(p["rgb"], c)))
            mapping.append((hexc, opaque[c], "REJECTED (nearest %s, not mapped)" % near["id"]))
    fails = []
    if not (ENVELOPE_MIN <= gw <= ENVELOPE_MAX):
        fails.append("width %d outside %d..%d" % (gw, ENVELOPE_MIN, ENVELOPE_MAX))
    if not (ENVELOPE_MIN <= gh <= ENVELOPE_MAX):
        fails.append("height %d outside %d..%d" % (gh, ENVELOPE_MIN, ENVELOPE_MAX))
    if void and (nonvoid_cells < MIN_ARTWORK_CELLS or nonvoid_cells < MIN_ARTWORK_FRACTION * gw * gh):
        fails.append("D2: %d non-VOID cells of %d" % (nonvoid_cells, gw * gh))
    if partial:
        fails.append("%d semi-transparent pixels" % partial)
    if off:
        fails.append("%d off-palette colours" % len(off))
    if not (COLOR_MIN <= len(opaque) <= COLOR_MAX):
        fails.append("%d colours outside %d..%d" % (len(opaque), COLOR_MIN, COLOR_MAX))
    if bx != by:
        fails.append("non-square block %dx%d" % (bx, by))
    return {
        "file": name, "size": "%dx%d" % (w, h), "void": void, "partial": partial,
        "colors": len(opaque), "aa": "yes (%d edge px)" % aa_edge if (aa_edge or partial) else "none",
        "block": "%dx%d" % (bx, by), "interp": "none" if not off and not partial else "suspected",
        "grid": "%dx%d" % (gw, gh), "nonvoid": nonvoid_cells, "mapping": mapping,
        "verdict": "PASS" if not fails else "FAIL: " + "; ".join(fails),
    }


def report(results):
    out = ["| File | Size | VOID px | Semi-alpha px | Colours | Anti-aliasing | Block | Interpolation | Logical grid | Non-VOID cells | Verdict |",
           "| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |"]
    for r in results:
        out.append("| %s | %s | %d | %d | %d | %s | %s | %s | %s | %d | %s |" % (
            r["file"], r["size"], r["void"], r["partial"], r["colors"], r["aa"], r["block"],
            r["interp"], r["grid"], r["nonvoid"], r["verdict"]))
    out.append("")
    for r in results:
        out.append("**%s**: " % r["file"] + ", ".join("%s x%d -> %s" % m for m in r["mapping"]))
        out.append("")
    return "\n".join(out)


def self_test(palette):
    red, blk, clear = (255, 69, 0, 255), (0, 0, 0, 255), (0, 0, 0, 0)
    # 2x upscaled 20x20 checker of palette colours -> block 2, grid 20x20, PASS (3 colours needed).
    rows = [[(red, blk, (255, 255, 255, 255))[((x // 2) + (y // 2)) % 3] for x in range(40)] for y in range(40)]
    r = audit("t", 40, 40, rows, palette)
    assert (r["block"], r["grid"], r["verdict"]) == ("2x2", "20x20", "PASS"), r
    rows[5][5] = (128, 60, 0, 255)  # blended edge pixel
    r = audit("t", 40, 40, rows, palette)
    assert r["aa"].startswith("yes") and "REJECTED" in r["mapping"][-1][2] and r["verdict"].startswith("FAIL"), r
    rows = [[clear] * 20 for _ in range(20)]
    rows[0][:3] = [red, blk, red]
    assert "D2" in audit("t", 20, 20, rows, palette)["verdict"]
    raw = b"".join(b"\x00" + bytes([255, 69, 0, 255]) * 2 for _ in range(2))
    chunk = lambda k, d: struct.pack(">I", len(d)) + k + d + struct.pack(">I", zlib.crc32(k + d))
    png = b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", struct.pack(">IIBBBBB", 2, 2, 8, 6, 0, 0, 0)) + \
        chunk(b"IDAT", zlib.compress(raw)) + chunk(b"IEND", b"")
    assert decode_png(png) == (2, 2, [[red, red], [red, red]])
    print("audit_level_art self-test: PASS")


def main(argv):
    with open(PALETTE, encoding="utf-8") as f:
        palette = json.load(f)["colors"]
    assert [c["id"] for c in palette] == ["C%02d" % i for i in range(1, 17)]
    if argv[:1] == ["--self-test"]:
        return self_test(palette)
    paths = argv or sorted(glob.glob(SOURCE_GLOB, recursive=True))
    results = []
    for p in paths:
        with open(p, "rb") as f:
            w, h, rows = decode_png(f.read())
        results.append(audit(os.path.relpath(p, ROOT).replace(os.sep, "/"), w, h, rows, palette))
    print(report(results))
    failed = sum(not r["verdict"].startswith("PASS") for r in results)
    print("SUMMARY: %d images, %d PASS, %d FAIL" % (len(results), len(results) - failed, failed))
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
