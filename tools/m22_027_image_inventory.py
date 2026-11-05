#!/usr/bin/env python3
"""SB-M22-027 reference graph of every tracked image (stdlib only).

For each tracked image (git ls-files) prints one CSV row: path, sha256, bytes, class, reason
and the first referencing files. A reference is any of, in any tracked text file except the
image's own .import, this tool and its report:
  res    the res:// path
  path   the repo path (also backslash and %20 forms)
  uid    the uid:// from its .import (ext_resource by uid)
  base   the file name with extension (relative tails, slug maps that store names)
  stem   the file name without extension (slug maps, format strings that add the extension)
  pat    a code/data string literal with a format placeholder (%s, %02d, {x}) or a "_tail.png"
         fragment whose regex matches the end of the path (it needs 4+ literal folder/name
         characters: "%s_%d.png" and "%s/%s.png" name nothing)
  dir    a code/data string literal naming the image's folder (concatenated or listed at
         runtime); the bare roots res://, res://assets/ and res://assets/ui/final/ are not
         dirs, their tails are caught by base/pat
Source kinds: runtime (scripts, scenes, data, addons, assets text, project.godot),
test (tests/), tool (tools/, .github/, level_factory/, content_pipeline/), manifest
(ASSET_GENERATION_MANIFEST.json, assets/** manifest/PROVENANCE files; runtime when runtime code
names the manifest), doc (everything else). pat/dir literals come from runtime/test/tool only.

Images the Android export preset excludes (generated/, candidates/, references/, coordination/)
never ship, so for them only a code res:// or uid reference is runtime; runtime data, bare
names/stems and plain (comment) paths in code count as manifest (provenance).

Classes (first match wins):
  ACTIVE_RUNTIME     runtime path or uid reference
  DYNAMIC_REF        runtime base/stem/pat/dir reference
  PROVENANCE_MASTER  owner inbox / references, level art, plugin, masters/, coordination or
                     factory evidence, or a generated/candidate image named by a manifest,
                     tool or doc
  FUTURE_NEEDED      assets/ui/final image named by a manifest/index but not by runtime
  TEST_ONLY          referenced by tests only (any kind of reference)
  UNKNOWN            any other reference (tool or doc only): ambiguous, kept
  CONFIRMED_ORPHAN   no reference of any kind anywhere, or an undecodable PNG under assets/
                     that no code/scene/data/test file loads (still needs the runtime proof)
Run from the repo root: python tools/m22_027_image_inventory.py [--csv out.csv] [--md out.md]
(--selftest checks the PNG decode, pattern and kind rules on fixed inputs).
"""
import bisect
import fnmatch
import hashlib
import os
import re
import struct
import subprocess
import sys
import zlib

IMAGE_EXT = (".png", ".jpg", ".jpeg", ".webp", ".svg", ".bmp", ".tga", ".gif", ".exr", ".hdr",
             ".ico", ".icns", ".ktx", ".dds")
BINARY_EXT = IMAGE_EXT + (".import", ".ogv", ".ogg", ".wav", ".mp3", ".mp4", ".ttf", ".otf", ".woff",
                          ".woff2", ".zip", ".jar", ".keystore", ".pck", ".so", ".dll", ".a")
CODE_EXT = (".gd", ".tscn", ".tres", ".gdshader", ".godot", ".cfg")
EXPORT_PRESET = ".github/android/export_presets_family_first10.cfg"
REPORT_NAMES = ("m22_027_image_inventory.csv", "M22_027_IMAGE_INVENTORY.md", "m22_027_image_inventory.py")
CLASSES = ["ACTIVE_RUNTIME", "DYNAMIC_REF", "PROVENANCE_MASTER", "FUTURE_NEEDED", "TEST_ONLY",
           "UNKNOWN", "CONFIRMED_ORPHAN"]
BARE_ROOTS = {"res://", "res://assets/", "res://assets/ui/", "res://assets/ui/final/", "assets/",
              "assets/ui/", "assets/ui/final/"}
LITERAL = re.compile(r"\"([^\"\n]{2,300})\"|'([^'\n]{2,300})'")
PLACEHOLDER = re.compile(r"%0?\d*[sdif]|\{[^{}]*\}")
UID = re.compile(r"^uid=\"(uid://[a-z0-9]+)\"", re.M)


def tracked():
    out = subprocess.run(["git", "ls-files", "-z"], capture_output=True, check=True).stdout
    return [p for p in out.decode("utf-8").split("\0") if p]


def kind(path):
    low = path.lower()
    name = os.path.basename(low)
    # Text beside the art (manifests, PROVENANCE.md, indexes, inventories) is provenance unless
    # runtime code loads it (see main); .tres/.tscn/.gdshader under assets/ are runtime resources.
    if path == "ASSET_GENERATION_MANIFEST.json" or (path.startswith("assets/") and (
            "manifest" in name or "provenance" in name or low.endswith((".md", ".json", ".txt", ".csv")))):
        return "manifest"
    if path.startswith("tests/"):
        return "test"
    if path.startswith(("tools/", ".github/", "level_factory/", "content_pipeline/")):
        return "tool"
    if path.startswith(("scripts/", "scenes/", "data/", "addons/", "assets/")) or (
            "/" not in path and low.endswith((".godot", ".cfg", ".tres", ".tscn"))):
        return "runtime"
    return "doc"


def protected(path):
    """Location-based provenance: never an orphan candidate."""
    if path.startswith("assets/art/references/"):
        return "owner reference/inbox"
    if path.startswith("assets/art/levels/"):
        return "level art"
    if path.startswith("addons/"):
        return "plugin asset"
    if path.startswith(("coordination/", "factory/")):
        return "audit evidence"
    if "/masters/" in path or "/master/" in path and "generated" in path:
        return "master"
    return ""


def png_decodes(data):
    """False when a PNG's chunks are truncated or its IDAT stream does not inflate to the end."""
    i, z, done = 8, zlib.decompressobj(), False
    try:
        while i + 8 <= len(data):
            n, k = struct.unpack(">I4s", data[i:i + 8])
            if i + 12 + n > len(data):
                return False
            if k == b"IDAT":
                z.decompress(data[i + 8:i + 8 + n])
            elif k == b"IEND":
                done = True
                break
            i += 12 + n
        return done and z.eof
    except zlib.error:
        return False


def patterns(text):
    """(regex, literal) for placeholder / fragment literals and (dir, literal) for folder literals."""
    pats, dirs = [], []
    for m in LITERAL.finditer(text):
        lit = m.group(1) or m.group(2)
        low = lit.lower()
        has_ph = bool(PLACEHOLDER.search(lit))
        if low.endswith(IMAGE_EXT):
            tail = os.path.basename(lit)
            # Fragments "_portrait.png" / "card_%02d.png"; ".png" alone or a whole plain name is base.
            # "%s_%d.png" / "%s/%s.png" name no file by themselves: a pattern needs 4+ literal
            # folder/name characters.
            fixed = os.path.splitext(PLACEHOLDER.sub("", lit.replace("res://", "")))[0]
            specific = len(re.sub(r"[^A-Za-z0-9]", "", fixed)) >= 4
            if specific and (has_ph or (tail.startswith(("_", "-")) and len(tail) > 6)):
                rx = "".join(".*" if PLACEHOLDER.fullmatch(t) else re.escape(t)
                             for t in re.split(r"(%0?\d*[sdif]|\{[^{}]*\})", lit.replace("res://", "")))
                pats.append((re.compile(rx + "$"), lit))
        elif lit.endswith("/") and ("res://" in lit or lit.startswith("assets/")) and not has_ph:
            d = lit.replace("res://", "")
            if lit not in BARE_ROOTS and d not in BARE_ROOTS:
                dirs.append((d, lit))
        elif has_ph and ("res://" in lit or lit.startswith("assets/")):
            pre = PLACEHOLDER.split(lit)[0].replace("res://", "")
            if pre and pre not in BARE_ROOTS and "res://" + pre not in BARE_ROOTS:
                dirs.append((pre, lit))
    return pats, dirs


def selftest():
    def png(idat, iend=True):
        chunk = lambda k, d: struct.pack(">I", len(d)) + k + d + bytes(4)
        ihdr = struct.pack(">IIBBBBB", 1, 1, 8, 6, 0, 0, 0)
        return bytes.fromhex("89504e470d0a1a0a") + chunk(b"IHDR", ihdr) + idat + (chunk(b"IEND", b"") if iend else b"")
    raw = zlib.compress(bytes(5))
    good = png(struct.pack(">I", len(raw)) + b"IDAT" + raw + bytes(4))
    assert png_decodes(good)
    assert not png_decodes(good[:-20])                                   # truncated chunk
    assert not png_decodes(png(struct.pack(">I", 4) + b"IDAT" + bytes.fromhex("789cffff") + bytes(4)))
    assert not png_decodes(png(struct.pack(">I", len(raw)) + b"IDAT" + raw + bytes(4), iend=False))
    pats, dirs = patterns('a = "%s_%d.png" b = "%s/%s.png" c = "rewards/%s.png" d = "_portrait.png"'
                          ' e = "res://assets/ui/final/" f = "res://assets/ui/final/robots/"'
                          ' g = "res://assets/ui/final/collection/cards/set_%02d/card_%02d.png"')
    lits = [lit for _, lit in pats]
    assert lits == ["rewards/%s.png", "_portrait.png", "res://assets/ui/final/collection/cards/set_%02d/card_%02d.png"], lits
    assert pats[0][0].search("assets/ui/final/rewards/heart.png")
    assert not pats[0][0].search("assets/ui/final/shop/heart.png")
    assert pats[2][0].search("assets/ui/final/collection/cards/set_03/card_07.png")
    assert [d for d, _ in dirs] == ["assets/ui/final/robots/"], dirs
    assert kind("assets/ui/HOME_ASSET_MANIFEST.json") == "manifest" and kind("scripts/a.gd") == "runtime"
    assert kind("assets/ui/VISUAL_ASSET_INDEX.md") == "manifest" and kind("tests/a.gd") == "test"
    assert protected("coordination/x/e.png") and protected("assets/art/levels/a.png")
    assert not protected("assets/ui/final/a.png")
    print("selftest PASS")


def main(argv):
    if "--selftest" in argv:
        selftest()
        return 0
    csv_out = md_out = None
    for i, a in enumerate(argv):
        if a == "--csv":
            csv_out = argv[i + 1]
        if a == "--md":
            md_out = argv[i + 1]
    files = tracked()
    with open(EXPORT_PRESET, encoding="utf-8") as f:
        m = re.search(r'^exclude_filter="([^"]*)"', f.read(), re.M)
    excluded = [g.strip() for g in m.group(1).split(",") if g.strip()]
    tracked_set = set(files)
    images = sorted(p for p in files if p.lower().endswith(IMAGE_EXT))
    corpus = {}  # path -> (kind, text)
    for p in files:
        if p.lower().endswith(BINARY_EXT) or os.path.basename(p) in REPORT_NAMES or not os.path.isfile(p):
            continue
        with open(p, "rb") as f:
            raw = f.read()
        if b"\0" in raw[:8192]:
            continue
        corpus[p] = (kind(p), raw.decode("utf-8", errors="replace"))
    # A manifest that runtime code reads (HOME_ASSET_MANIFEST.json via home_art_binder) is runtime data.
    runtime_text = "\0".join(t for k, t in corpus.values() if k == "runtime")
    for p, (k, t) in list(corpus.items()):
        if k == "manifest" and "res://" + p in runtime_text:
            corpus[p] = ("runtime", t)
    lits = {}  # kind -> (pats, dirs) with source file; only code builds paths
    for p, (k, t) in corpus.items():
        if k not in ("runtime", "test", "tool"):
            continue
        ps, ds = patterns(t)
        lits.setdefault(k, ([], []))
        lits[k][0].extend((rx, lit, p) for rx, lit in ps)
        lits[k][1].extend((d, lit, p) for d, lit in ds)
    joined = {}  # kind -> ("\0"-joined text, start offsets, file names)
    for p, (k, t) in corpus.items():
        big, starts, names = joined.setdefault(k, ([], [], []))
        starts.append(starts[-1] + len(big[-1]) + 1 if starts else 0)
        big.append(t)
        names.append(p)
    joined = {k: ("\0".join(b), s, n) for k, (b, s, n) in joined.items()}

    rows = []
    for img in images:
        with open(img, "rb") as f:
            data = f.read()
        sha = hashlib.sha256(data).hexdigest()
        imp = img + ".import"
        uid = ""
        if os.path.isfile(imp):
            with open(imp, encoding="utf-8", errors="replace") as f:
                m = UID.search(f.read())
            uid = m.group(1) if m else ""
        base = os.path.basename(img)
        stem = os.path.splitext(base)[0]
        needles = [("res", "res://" + img), ("path", img), ("path", img.replace("/", "\\")), ("path", img.replace(" ", "%20")),
                   ("base", base), ("stem", stem)]
        if uid:
            needles.insert(0, ("uid", uid))
        hits = {}  # kind -> list of "how:file"
        for k, (big, starts, names) in joined.items():
            for how, n in needles:
                at = big.find(n)
                while at >= 0:
                    p = names[bisect.bisect_right(starts, at) - 1]
                    if p != img:
                        hits.setdefault(k, []).append("%s:%s" % (how, p))
                        break
                    at = big.find(n, at + 1)
        for k, (ps, ds) in lits.items():
            for rx, lit, p in ps:
                if rx.search(img):
                    hits.setdefault(k, []).append("pat(%s):%s" % (lit, p))
            for d, lit, p in ds:
                if img.startswith(d):
                    hits.setdefault(k, []).append("dir(%s):%s" % (lit, p))
        if any(fnmatch.fnmatch(img, g) for g in excluded):
            # Not in the shipped pack: runtime data naming it (HOME manifest source fields) is
            # provenance, a bare name/stem in code is the shipped final twin and a plain path in
            # code is a comment; only a code res:// or uid load would count (a shipping bug).
            data_hits = [h for h in hits.get("runtime", []) if not (
                h.startswith(("res:", "uid:")) and h.rsplit(":", 1)[-1].endswith(CODE_EXT))]
            if data_hits:
                hits["manifest"] = data_hits + hits.get("manifest", [])
                hits["runtime"] = [h for h in hits["runtime"] if h not in data_hits]
                if not hits["runtime"]:
                    del hits["runtime"]
        rt = hits.get("runtime", [])
        prot = protected(img)
        code_load = [h for h in rt + hits.get("test", []) if h.rsplit(":", 1)[-1].endswith(CODE_EXT)]
        broken = (not prot and img.lower().endswith(".png") and img.startswith("assets/")
                  and not code_load and not png_decodes(data))
        is_cand = img.startswith(("assets/ui/generated/", "assets/ui/candidates/"))
        if broken:
            # Godot cannot import it (ERR_FILE_CORRUPT), so nothing can display it; doc/CI notes
            # about the broken file are not uses.
            cls, why = "CONFIRMED_ORPHAN", "undecodable PNG, no code/scene/data/test load"
        elif any(h.startswith(("res:", "path:", "uid:")) for h in rt):
            cls, why = "ACTIVE_RUNTIME", "runtime path/uid reference"
        elif rt:
            cls, why = "DYNAMIC_REF", "runtime name/pattern/folder reference"
        elif prot:
            cls, why = "PROVENANCE_MASTER", prot
        elif is_cand and (hits.get("manifest") or hits.get("tool") or hits.get("doc")):
            cls, why = "PROVENANCE_MASTER", "generated/candidate named by manifest/tool/doc"
        elif img.startswith("assets/ui/final/") and hits.get("manifest"):
            cls, why = "FUTURE_NEEDED", "final art named by an asset manifest/index, no runtime load"
        elif hits.get("test") and set(hits) == {"test"}:
            cls, why = "TEST_ONLY", "tests only"
        elif hits:
            cls, why = "UNKNOWN", "referenced outside runtime (%s)" % "/".join(sorted(hits))
        else:
            cls, why = "CONFIRMED_ORPHAN", "no path/uid/name/stem/pattern/folder reference anywhere"
        imports = [x for x in (img + ".import", img + ".uid") if x in tracked_set]
        refs = [h for k in ("runtime", "manifest", "test", "tool", "doc") for h in hits.get(k, [])]
        rows.append((img, sha, len(data), cls, why, imports, refs, bool(hits)))

    lines = ["path,sha256,bytes,class,reason,tracked_meta,refs"]
    for img, sha, n, cls, why, imports, refs, _ in rows:
        lines.append('"%s",%s,%d,%s,"%s","%s","%s"' % (img, sha, n, cls, why, ";".join(imports),
                                                     " ; ".join(refs[:4]).replace('"', "'")))
    text = "\n".join(lines) + "\n"
    if csv_out:
        with open(csv_out, "w", encoding="utf-8", newline="\n") as f:
            f.write(text)
    counts = {c: [0, 0] for c in CLASSES}
    for r in rows:
        counts[r[3]][0] += 1
        counts[r[3]][1] += r[2]
    summary = ["| class | images | bytes |", "|---|---:|---:|"]
    summary += ["| %s | %d | %d |" % (c, counts[c][0], counts[c][1]) for c in CLASSES]
    summary.append("| **total** | %d | %d |" % (len(rows), sum(r[2] for r in rows)))
    unique = len({r[1] for r in rows})
    summary.append("")
    summary.append("Tracked images: %d (%d distinct SHA256)." % (len(rows), unique))
    tops = {}
    for r in rows:
        top = "/".join(r[0].split("/")[:3]) if r[0].startswith("assets/") else r[0].split("/")[0]
        tops.setdefault(top, {c: 0 for c in CLASSES})[r[3]] += 1
    summary += ["", "| folder | " + " | ".join(CLASSES) + " |", "|---|" + "---:|" * len(CLASSES)]
    summary += ["| %s | %s |" % (t, " | ".join(str(tops[t][c]) for c in CLASSES)) for t in sorted(tops)]
    bare = [r for r in rows if not r[7]]
    summary.append("")
    summary.append("Kept with no individual reference (location-protected: audit evidence, owner "
                   "references, level art, plugin, masters): %d images, %d bytes." % (
                       len([r for r in bare if r[3] != "CONFIRMED_ORPHAN"]),
                       sum(r[2] for r in bare if r[3] != "CONFIRMED_ORPHAN")))
    orphans = [r for r in rows if r[3] == "CONFIRMED_ORPHAN"]
    summary.append("")
    summary.append("CONFIRMED_ORPHAN candidates (%d):" % len(orphans))
    summary += ["- %s (%d bytes, sha256 %s; meta: %s)" % (r[0], r[2], r[1], ";".join(r[5]) or "-")
                for r in orphans]
    if md_out:
        with open(md_out, "w", encoding="utf-8", newline="\n") as f:
            f.write("\n".join(summary) + "\n")
    if not csv_out:
        sys.stdout.write(text)
    print("\n".join(summary))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
