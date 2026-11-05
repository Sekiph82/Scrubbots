"""SB-M22-026 step 2: measured size_limit caps for res://assets/ui/final/ textures.

Reads the JSON of tests/tools/m22_026_texture_measure.gd (or a bare {path: max_side_px} map),
prints one row per observed texture and, with --write, sets process/size_limit in its .import.
Rule (UI-ADR-008 step 2): limit = next_pow2(max(2 * max_side_px, 512)); written only when
limit < source max side and the .import has no limit yet (0); limits set earlier (boosters
512, step-1 icons) keep their value. Textures with no measured size (unobserved or size 0)
are never touched. Stdlib only.
SB-M22-029 --coverage: instead, every PNG under assets/ui/final/ as measured (drawn size > 0),
loaded size 0 or not observed by any scenario, with its docs/m22_027_image_inventory.csv class.

Usage: python -I tools/m22_026_apply_caps.py <measure.json> [--write | --coverage]
"""
import csv
import json
import re
import struct
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
FINAL = ROOT / "assets" / "ui" / "final"
FLOOR = 512
LIMIT_RE = re.compile(rb"^process/size_limit=(\d+)", re.M)


def next_pow2(n):
    p = 1
    while p < n:
        p *= 2
    return p


def cap_for(side):
    return next_pow2(max(2 * side, FLOOR))


def png_size(path):
    with open(path, "rb") as f:
        head = f.read(24)
    return struct.unpack(">II", head[16:24])


def coverage(data):
    seen = {}
    for entries in data["scenarios"].values():
        for rel, e in entries.items():
            seen[rel] = max(seen.get(rel, 0), int(e["max_side_px"]))
    inv = ROOT / "docs" / "m22_027_image_inventory.csv"
    cls = {r["path"]: r["class"] for r in csv.DictReader(inv.open(encoding="utf-8"))}
    rows = {}
    for png in sorted(FINAL.rglob("*.png")):
        rel = png.relative_to(FINAL).as_posix()
        state = "not_observed" if rel not in seen else ("measured" if seen[rel] > 0 else "loaded_size_0")
        rows.setdefault((state, cls.get("assets/ui/final/" + rel, "NOT_IN_INVENTORY")), []).append(rel)
    for (state, c), rels in sorted(rows.items()):
        print("%-14s %-17s %4d" % (state, c, len(rels)))
    for (state, c), rels in sorted(rows.items()):
        if state != "measured":
            for rel in rels:
                print("%s	%s	%s" % (state, c, rel))
    return 0


def main(argv):
    args = [a for a in argv if not a.startswith("--")]
    write = "--write" in argv
    if len(args) != 1:
        print(__doc__)
        return 2
    data = json.loads(Path(args[0]).read_text(encoding="utf-8"))
    if "--coverage" in argv:
        return coverage(data)
    merged = data.get("merged", data)
    changed = 0
    under = 0
    print("%-70s %6s %9s %6s %6s  %s" % ("texture", "side", "source", "cur", "limit", "decision"))
    for rel in sorted(merged):
        side = int(merged[rel])
        png = FINAL / rel
        imp = png.with_name(png.name + ".import")
        if side <= 0:
            print("%-70s %6d %9s %6s %6s  skip: size 0 / unobserved" % (rel, side, "", "", ""))
            continue
        w, h = png_size(png)
        raw = imp.read_bytes()
        m = LIMIT_RE.search(raw)
        cur = int(m.group(1)) if m else 0
        limit = cap_for(side)
        if limit >= max(w, h):
            why = "keep: source <= limit"
        elif cur:
            why = "keep: existing limit %d (UI-ADR-007 / step 1)" % cur
        else:
            why = "CAP %d" % limit
            changed += 1
            if write:
                imp.write_bytes(LIMIT_RE.sub(b"process/size_limit=%d" % limit, raw, count=1))
        if cur and cur < 2 * side and cur < max(w, h):
            why += "; UNDER 2x (SB-M22-029)"
            under += 1
        print("%-70s %6d %4dx%-4d %6d %6d  %s" % (rel, side, w, h, cur, limit, why))
    print("%s %d texture(s); %d existing limit(s) under 2 x drawn side" % ("capped" if write else "would cap", changed, under))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
