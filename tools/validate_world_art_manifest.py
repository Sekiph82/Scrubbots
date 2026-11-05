#!/usr/bin/env python3
"""World art production manifest validator (SB-M07-014). Read-only.

Checks a data/art_manifests/*.json manifest: schema, counts, level range, batching,
unique ids/filenames and the PLANNED vs SUPPLIED/APPROVED field rules. For every
entry that names a supplied file it also checks existence, sha256, PNG size/alpha
and, for level PNGs, the palette V3 / grid / alpha / VOID rules via
tools/audit_level_art.py. Video durations are not probed (no stdlib decoder).

Usage: python tools/validate_world_art_manifest.py [manifest ...]
         (default: data/art_manifests/world10_sunken_harbor_v1.json)
       python tools/validate_world_art_manifest.py --self-test
Exit 1 when any manifest fails.
"""
import copy
import hashlib
import json
import os
import re
import struct
import sys
import tempfile
import zlib

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))  # python -I drops the script dir
from audit_level_art import PALETTE, ROOT, audit, decode_png  # noqa: E402

DEFAULT = os.path.join(ROOT, "data", "art_manifests", "world10_sunken_harbor_v1.json")
SUPPORT_COUNTS = {"world_ui": 8, "decor": 8, "fx": 4, "marketing": 3}
VIDEO_COUNT = 3
PROOF_FIELDS = ("sha256", "provenance", "license", "signedOffBy")


def sha256(path):
    with open(path, "rb") as f:
        return hashlib.sha256(f.read()).hexdigest()


def check_proof(entry, label, statuses, errors):
    """PLANNED keeps proof fields null; SUPPLIED/APPROVED must fill them. Returns True if a file is claimed."""
    status = entry.get("status")
    if status not in statuses:
        errors.append("%s: status %r not in %s" % (label, status, statuses))
        return False
    if status == "PLANNED":
        filled = [k for k in PROOF_FIELDS + ("file",) if entry.get(k) is not None]
        if filled:
            errors.append("%s: PLANNED but %s set" % (label, ", ".join(filled)))
        return False
    missing = [k for k in PROOF_FIELDS if not entry.get(k)]
    if missing:
        errors.append("%s: %s without %s" % (label, status, ", ".join(missing)))
    return True


def check_file(path, entry, label, errors):
    """Existence + sha256. Returns the file bytes or None."""
    if not os.path.isfile(path):
        errors.append("%s: file missing %s" % (label, path))
        return None
    if entry.get("sha256") and sha256(path) != entry["sha256"]:
        errors.append("%s: sha256 mismatch" % label)
    with open(path, "rb") as f:
        return f.read()


def validate(m, root, palette):
    errors = []
    statuses = m.get("statusValues", [])
    world, rules = m["world"], m["levelSlotRules"]
    first, last = world["firstLevel"], world["lastLevel"]
    if last - first + 1 != rules["count"] or rules["count"] != rules["batchSize"] * rules["batches"]:
        errors.append("level range %d..%d does not equal %d batches x %d" % (first, last, rules["batches"], rules["batchSize"]))
    levels = m["levels"]
    if [l["level"] for l in levels] != list(range(first, last + 1)):
        errors.append("levels must list %d..%d once each, in order" % (first, last))
    regex = re.compile(rules["filenameRegex"])
    gmin, gmax = rules["grid"]["minPerDimension"], rules["grid"]["maxPerDimension"]
    if gmin < 20 or gmax > 59:
        errors.append("grid %d..%d outside the production envelope 20..59" % (gmin, gmax))
    if (rules["palette"]["usedColors"]["min"], rules["palette"]["usedColors"]["max"]) != (3, 12):
        errors.append("usedColors must be 3..12 (palette V3 usedColorEnvelopeV1)")
    shas, files = {}, set()
    for l in levels:
        label = "L%d" % l["level"]
        if l["batch"] != (l["level"] - first) // rules["batchSize"] + 1:
            errors.append("%s: batch %d wrong" % (label, l["batch"]))
        if not check_proof(l, label, statuses, errors):
            continue
        rel = l.get("file") or ""
        mt = regex.match(os.path.basename(rel))
        if not mt or not rel.startswith(rules["directory"]) or int(mt.group(1)) != l["level"]:
            errors.append("%s: file %r must be %s%s for this level" % (label, rel, rules["directory"], rules["filenamePattern"]))
            continue
        if rel in files:
            errors.append("%s: duplicate file %s" % (label, rel))
        files.add(rel)
        if l["sha256"] in shas:
            errors.append("%s: same image as L%d (sha256)" % (label, shas[l["sha256"]]))
        shas[l["sha256"]] = l["level"]
        data = check_file(os.path.join(root, rel), l, label, errors)
        if data is None:
            continue
        w, h, px = decode_png(data)
        r = audit(rel, w, h, px, palette)
        if r["verdict"] != "PASS":
            errors.append("%s: %s" % (label, r["verdict"]))
        if r["grid"] != "%sx%s" % (int(mt.group(2)), int(mt.group(3))):
            errors.append("%s: logical grid %s does not match filename" % (label, r["grid"]))
    support, videos = m["supportPngs"], m["videos"]
    counts = {}
    for s in support:
        counts[s["category"]] = counts.get(s["category"], 0) + 1
    if counts != SUPPORT_COUNTS:
        errors.append("support PNG counts %s != %s" % (counts, SUPPORT_COUNTS))
    if not m.get("supportPngSizeSource"):
        errors.append("supportPngSizeSource must say who chose the support sizes")
    if len(videos) != VIDEO_COUNT or not all(v["optional"] for v in videos):
        errors.append("need %d optional videos" % VIDEO_COUNT)
    ids = [e["id"] for e in support + videos]
    names = [e["filename"] for e in support + videos]
    for kind, seq in (("id", ids), ("filename", names)):
        dup = sorted({x for x in seq if seq.count(x) > 1})
        if dup:
            errors.append("duplicate %s: %s" % (kind, ", ".join(dup)))
    for s in support:
        label = s["id"]
        w, h = s["size"]
        if not s["filename"].endswith("_%dx%d.png" % (w, h)) or not s.get("use") or not s.get("alpha") or not s.get("aspect"):
            errors.append("%s: needs a *_%dx%d.png filename, aspect, alpha and use" % (label, w, h))
        if not check_proof(s, label, statuses, errors):
            continue
        data = check_file(os.path.join(root, m["supportPngDirectory"], s["filename"]), s, label, errors)
        if data is None:
            continue
        pw, ph, px = decode_png(data)
        if (pw, ph) != (w, h):
            errors.append("%s: PNG is %dx%d, manifest says %dx%d" % (label, pw, ph, w, h))
        if s["alpha"] == "opaque" and any(p[3] != 255 for row in px for p in row):
            errors.append("%s: declared opaque but has transparent pixels" % label)
    for v in videos:
        label = v["id"]
        d = v["durationSeconds"]
        if not (0 < d["min"] <= d["max"]) or os.path.splitext(v["filename"])[1] not in (".ogv", ".mp4"):
            errors.append("%s: bad duration or extension" % label)
        if check_proof(v, label, statuses, errors):
            check_file(os.path.join(root, m["videoDirectory"], v["filename"]), v, label, errors)
    return errors


def write_png(path, rows):
    raw = b"".join(b"\x00" + b"".join(bytes(p) for p in row) for row in rows)
    chunk = lambda k, d: struct.pack(">I", len(d)) + k + d + struct.pack(">I", zlib.crc32(k + d))
    with open(path, "wb") as f:
        f.write(b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", struct.pack(">IIBBBBB", len(rows[0]), len(rows), 8, 6, 0, 0, 0)) +
                chunk(b"IDAT", zlib.compress(raw)) + chunk(b"IEND", b""))


def self_test(palette):
    with open(DEFAULT, encoding="utf-8") as f:
        base = json.load(f)
    assert validate(base, ROOT, palette) == [], "committed manifest must pass"
    cols = [(255, 69, 0, 255), (0, 0, 0, 255), (255, 255, 255, 255)]  # C01, C16, C15
    good = [[cols[(x + y) % 3] for x in range(20)] for y in range(20)]
    with tempfile.TemporaryDirectory() as tmp:
        d = os.path.join(tmp, base["levelSlotRules"]["directory"])
        os.makedirs(d)
        rel = base["levelSlotRules"]["directory"] + "level_1351_anchor_20x20.png"
        write_png(os.path.join(tmp, rel), good)
        supplied = {"status": "SUPPLIED", "file": rel, "subject": "anchor", "sha256": sha256(os.path.join(tmp, rel)),
                    "provenance": "self-test", "license": "self-test", "signedOffBy": "self-test"}

        def run(edit):
            m = copy.deepcopy(base)
            m["levels"][0].update(supplied)
            edit(m)
            return validate(m, tmp, palette)

        assert run(lambda m: None) == [], run(lambda m: None)
        rel2 = rel.replace("1351", "1352")
        write_png(os.path.join(tmp, rel2), good)  # same pixels as L1351
        cases = {
            "count": (lambda m: m["levels"].pop(), "once each"),
            "batch": (lambda m: m["levels"][15].update(batch=1), "batch 1 wrong"),
            "range": (lambda m: m["world"].update(lastLevel=1499), "level range"),
            "envelope": (lambda m: m["levelSlotRules"]["grid"].update(maxPerDimension=60), "envelope"),
            "colours": (lambda m: m["levelSlotRules"]["palette"]["usedColors"].update(max=16), "usedColors"),
            "support count": (lambda m: m["supportPngs"].pop(), "support PNG counts"),
            "video count": (lambda m: m["videos"].pop(), "optional videos"),
            "size source": (lambda m: m.pop("supportPngSizeSource"), "supportPngSizeSource"),
            "dup filename": (lambda m: m["supportPngs"][1].update(filename=m["supportPngs"][0]["filename"]), "duplicate filename"),
            "planned with sha": (lambda m: m["levels"][1].update(sha256="ab"), "PLANNED but sha256"),
            "status": (lambda m: m["levels"][1].update(status="DONE"), "not in"),
            "no license": (lambda m: m["levels"][0].update(license=None), "without license"),
            "wrong level in name": (lambda m: m["levels"][0].update(file=rel2), "must be"),
            "sha mismatch": (lambda m: m["levels"][0].update(sha256="0" * 64), "sha256 mismatch"),
            "duplicate image": (lambda m: m["levels"][1].update(supplied, file=rel2), "same image as L1351"),
            "video missing": (lambda m: m["videos"][0].update(supplied), "file missing"),
        }
        for name, (edit, want) in cases.items():
            errs = run(edit)
            assert any(want in e for e in errs), (name, errs)
        bad = copy.deepcopy(good)
        bad[3][3] = (255, 69, 0, 128)  # semi-transparent pixel
        bad[4][4] = (128, 60, 0, 255)  # off-palette (blended) pixel
        write_png(os.path.join(tmp, rel), bad)
        supplied["sha256"] = sha256(os.path.join(tmp, rel))
        errs = run(lambda m: None)
        assert any("semi-transparent" in e and "off-palette" in e for e in errs), errs
        write_png(os.path.join(tmp, rel), [row[:19] for row in good])  # 19 wide: outside envelope, name says 20
        supplied["sha256"] = sha256(os.path.join(tmp, rel))
        errs = run(lambda m: None)
        assert any("width 19" in e for e in errs) and any("does not match filename" in e for e in errs), errs
        sup = base["supportPngs"][0]  # ui_background, opaque 940x1672
        os.makedirs(os.path.join(tmp, base["supportPngDirectory"]))
        spath = os.path.join(tmp, base["supportPngDirectory"], sup["filename"])
        write_png(spath, [[(0, 0, 0, 0)] * 4] * 2)
        errs = run(lambda m: m["supportPngs"][0].update(supplied, sha256=sha256(spath)))
        assert any("PNG is 4x2" in e for e in errs) and any("declared opaque" in e for e in errs), errs
    print("validate_world_art_manifest self-test: PASS (%d failing cases + valid PNG)" % (len(cases) + 3))


def main(argv):
    with open(PALETTE, encoding="utf-8") as f:
        palette = json.load(f)["colors"]
    if argv[:1] == ["--self-test"]:
        return self_test(palette)
    failed = 0
    for p in argv or [DEFAULT]:
        with open(p, encoding="utf-8") as f:
            errors = validate(json.load(f), ROOT, palette)
        for e in errors:
            print("FAIL %s: %s" % (os.path.basename(p), e))
        print("%s: %s" % (os.path.relpath(p, ROOT).replace(os.sep, "/"), "PASS" if not errors else "FAIL (%d)" % len(errors)))
        failed += bool(errors)
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
