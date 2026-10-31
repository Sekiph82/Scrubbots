#!/usr/bin/env python3
"""SB-CAMPAIGN-L11-L30: import 20 Level Factory Studio release-pool levels as campaign L11..L30.

Reads the owner's Studio release pool (READ ONLY), verifies every entry file's sha256, and
writes this repo's level JSON, supply plan, metadata and preview, then appends catalog
entries 11..30. Format/metadata only: cells, palette, width, height and version are copied
verbatim; only id, name, difficulty (campaign slot class) and the plan's levelId/batchId
labels change. Re-running with the same pool rewrites identical bytes.

The Studio's own "SOLVED + replay WIN" is Studio evidence only. The shippability gate is the
in-repo real-play check (SB-CAMPAIGN-RUNTIME-KERNEL-DIVERGENCE): after writing, the importer
runs tools/real_play_verify.gd --levels <imported> --regen through Godot, which replays every
imported plan through the real runtime under the human policy and regenerates only the
intendedColumnClicks of a plan that fails (so a re-import deterministically recreates the same
plans and provenance). Godot comes from --godot or env GODOT; without it the import fails.
Exits non-zero if any imported level is unwinnable under real play.

    python tools/import_release_pool_levels.py [--studio <Studio root>] [--godot <Godot exe>]
"""
import argparse
import hashlib
import json
import os
import subprocess
import sys

from PIL import Image

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
STUDIO = "C:/Users/sekip/Desktop/Scrubbots - Pixel Art Generator/Release/ScrubBots Factory Studio"
POOL = "level_factory/output/studio-extensions/release-pool"
BUILDER = "SB-CAMPAIGN-L11-L30/release-pool-import/v1"

# (order, slug, display name, campaign class, release-pool entry file)
LEVELS = [
    (11, "duckling", "Duckling", "EASY", "candidate-owner-4b8be03dd9f14c7f9f17ca5ae8544b9ef1c1e1a9ec7cce8f-pipeline-67ee53b660f157f92af4ced9"),
    (12, "ladybug", "Ladybug", "EASY", "candidate-owner-e52e80741f9a937574ecd97b3ce93523f4c07476885e64d2-pipeline-5420f3206975c7014bf650f8"),
    (13, "goldfish", "Goldfish", "MEDIUM", "candidate-owner-72efef1425ad6891884c39bdfc04aef1ef7641bf03bbb953-pipeline-7d7c1386d48afef670d6c857"),
    (14, "goose", "Goose", "EASY", "candidate-owner-e26b81cc6cc364364e3bb1b5eefbb79b88556c49aabbb5d8-pipeline-74ffa95db6ebf8601deffee4"),
    (15, "octopus", "Octopus", "HARD", "candidate-owner-896ddd7df33ad6ffcdbcdb1edaaaece8c3d9b1f116143aeb-pipeline-234c0379f9f9e45d01c0d7d7"),
    (16, "teddy_bear", "Teddy Bear", "EASY", "candidate-owner-a8cf6769a3053bac6b224b7d00cfaca28015043ae309ec06-pipeline-a51f853dd2189f09a5270cec"),
    (17, "ninja", "Ninja", "EASY", "candidate-owner-9375e5168ad6f9de7fcf94aaa95d641e0d95006b329c1ef6-pipeline-01a5676386a08fe43eceaffa"),
    (18, "wizard", "Wizard", "MEDIUM", "candidate-owner-6907c866ca9ff627edbf2c1ab2001f96b40587644291c9a2-pipeline-c79f580b657a020138cd9875"),
    (19, "whale", "Whale", "EASY", "candidate-owner-ba551e0efaa6ed9a39c187e76cae9a727b3f042e00140826-pipeline-091740762f8c0ca86cce69d1"),
    (20, "detective", "Detective", "VERY_HARD", "candidate-owner-ef2362240f3c7350571967d62dd9eaf2aa6e3bf2ff1d1f30-pipeline-c2194b4eb78f3563278ae25d"),
    (21, "bunny", "Bunny", "EASY", "candidate-owner-ed46768409271c2327082df3f24ec579d07e58b33fe18e5a-pipeline-d8463b48bd4b4170d04625cd"),
    (22, "crab", "Crab", "EASY", "candidate-owner-36ca9b4074ba991b52c6e5b5b89ee2acce581fa009fdf6c7-pipeline-9df7671ea2e45a5b8ca3429e"),
    (23, "bumblebee", "Bumblebee", "MEDIUM", "candidate-owner-bd3e8a5ad70fdfedf3d306fac0a1c717e8ab9802f79c1a18-pipeline-ba49de24c709c5af354be2af"),
    (24, "chef", "Chef", "EASY", "candidate-owner-0351429db11137e3d9932cd903972ec4409b8b020e5751e2-pipeline-fc7e8c79c88ed3e9cfb1d259"),
    (25, "knight", "Knight", "HARD", "candidate-owner-d68e000911dd22702458edc828fa817548a28c61df38ffec-pipeline-26a43c3082b8d2eb7df05a6f"),
    (26, "sheep", "Sheep", "EASY", "candidate-owner-905e719b10b3a1972dc8e82f9585483f4f361a6bc9711541-pipeline-3341c1d49f0f8d9633b3f744"),
    (27, "black_cat", "Black Cat", "EASY", "candidate-owner-89a8f149b5e5e3aa2b28d7b93b3f57c91ebb046bd48b5b22-pipeline-aca16f227fcfb9baaf6c6a0d"),
    (28, "squirrel", "Squirrel", "MEDIUM", "candidate-owner-70956566050ab939404dee4390f2006845d29f822804315e-pipeline-6f30c6a717aacdaa9d69f4f8"),
    (29, "turtle", "Turtle", "EASY", "candidate-owner-9aa5c74f056274ccad4eb61e98dfd3df98bb70f1d4ab9642-pipeline-4e44655ed09a290d081af297"),
    (30, "clown", "Clown", "VERY_HARD", "candidate-owner-df41c344b1980aa18dcfef6ada5b6e9a7cdea8a42d40142c-pipeline-ee8096aba3e2a8be4c7b7c44"),
]


def sha256(path):
    with open(path, "rb") as f:
        return hashlib.sha256(f.read()).hexdigest()


def studio_path(studio, p):
    return p if os.path.isabs(p) else os.path.join(studio, p)


def write_json(rel, data, sort_keys):
    # Repo style: tab indent, trailing newline, LF in the index (core.autocrlf handles CRLF).
    with open(os.path.join(REPO, rel), "w", encoding="utf-8", newline="\n") as f:
        f.write(json.dumps(data, indent="\t", sort_keys=sort_keys, ensure_ascii=False) + "\n")


def import_level(studio, cids, order, slug, name, klass, entry_name):
    entry_file = os.path.join(studio, POOL, entry_name + "-ready.json")
    with open(entry_file, encoding="utf-8") as f:
        entry = json.load(f)
    cand = entry["candidate"]
    lineage = cand["source_lineage"]
    assert entry["schema"] == "scrubbots-release-pool-entry/v1", entry_name
    assert entry["candidate_id"].startswith("candidate-owner-"), entry_name
    assert lineage["derivation"] == "EXACT_LOGICAL_OWNER_UPLOAD_TO_CANONICAL_CANDIDATE", entry_name
    acc = entry["pipeline"]["primary"]["acceptance"]
    # Studio evidence only (its own ProofKernel-timing solver + replay); shippability is the
    # real-play gate run after the import (tools/real_play_verify.gd).
    assert acc["solver_status"] == "SOLVED" and acc["replay"] == "WIN", entry_name
    files = {}
    for role in ("level", "supply_plan", "artwork"):
        p = studio_path(studio, entry["files"][role]["path"])
        assert sha256(p) == entry["files"][role]["sha256"], "%s %s sha256 mismatch" % (entry_name, role)
        files[role] = p
    with open(files["level"], encoding="utf-8") as f:
        src = json.load(f)
    with open(files["supply_plan"], encoding="utf-8") as f:
        plan = json.load(f)

    level_id = "level_%03d_%s" % (order, slug)
    level_rel = "data/levels/%s.json" % level_id
    plan_rel = "data/levels/supply/%s_supply_v1.json" % level_id
    meta_rel = "data/levels/metadata/%s.metadata.json" % level_id
    preview_rel = "assets/art/levels/previews/%s.png" % level_id

    level = {"cells": src["cells"], "difficulty": klass, "height": src["height"], "id": level_id,
             "name": name, "palette": src["palette"], "version": src["version"], "width": src["width"]}
    write_json(level_rel, level, True)

    old_id = plan["levelId"]
    plan["levelId"] = level_id
    prefix = "L%03d" % order
    for col in plan["columns"]:
        for b in col:
            assert b["batchId"].startswith(old_id + "-"), b["batchId"]
            b["batchId"] = prefix + b["batchId"][len(old_id):]
    write_json(plan_rel, plan, False)

    # Preview reconstructed from the final cells; VOID (-1) is transparent. Must equal the artwork.
    w, h = src["width"], src["height"]
    rgba = []
    for c in src["cells"]:
        if c == -1:
            rgba.append((0, 0, 0, 0))
        else:
            hx = src["palette"][c]
            rgba.append(tuple(int(hx[i:i + 2], 16) for i in (1, 3, 5, 7)))
    img = Image.new("RGBA", (w, h))
    img.putdata(rgba)
    px = Image.open(files["artwork"]).convert("RGBA").load()
    art = [px[x, y] if px[x, y][3] else (0, 0, 0, 0) for y in range(h) for x in range(w)]
    assert art == rgba, "%s: cells do not reproduce the artwork" % entry_name
    img.save(os.path.join(REPO, preview_rel), optimize=True)

    counts, first_seen = {}, []
    for c in src["cells"]:
        if c == -1:
            continue
        cid = cids[src["palette"][c][:7].upper()]
        if cid not in counts:
            first_seen.append(cid)
        counts[cid] = counts.get(cid, 0) + 1
    voids = src["cells"].count(-1)
    md = {
        "builderVersion": BUILDER,
        "cellCount": w * h,
        "cellReferenceCounts": counts,
        "difficulty": klass,
        "firstSeenColorOrder": first_seen,
        "height": h,
        "normalizedColorOrder": [cids[p[:7].upper()] for p in src["palette"]],
        "outputPath": "res://" + level_rel,
        "paletteAuthority": "res://data/palettes/scrubbots_palette_v3.json",
        "previewPath": "res://" + preview_rel,
        "sourcePath": os.path.relpath(files["artwork"], studio).replace("\\", "/"),
        "sourceSha256": entry["files"]["artwork"]["sha256"],
        "usedColorCount": len(src["palette"]),
        "width": w,
        "releasePool": {
            "entryFile": POOL + "/" + entry_name + "-ready.json",
            "entryDigest": entry["entry_digest"],
            "candidateId": entry["candidate_id"],
            "pipelineRunId": entry["pipeline_run_id"],
            "derivation": lineage["derivation"],
            "ownerSourceSha256": lineage["source_sha256"],
            "artworkSha256": entry["files"]["artwork"]["sha256"],
            "levelSha256": entry["files"]["level"]["sha256"],
            "supplyPlanSha256": entry["files"]["supply_plan"]["sha256"],
            "poolDifficultyClass": entry["difficulty_class"],
            "challengeScore": entry["challenge_score"],
            "sessionLoad": entry["session_load"],
            # Studio pipeline winnability evidence (its own solver + replay; not re-run here).
            "studioSolverStatus": acc["solver_status"],
            "studioReplay": acc["replay"],
        },
    }
    if voids:
        md["artworkCellCount"] = w * h - voids
        md["voidCellCount"] = voids
    write_json(meta_rel, md, True)
    return {"id": level_id, "order": order, "level_path": "res://" + level_rel,
            "metadata_path": "res://" + meta_rel, "preview_path": "res://" + preview_rel,
            "supply_plan_path": "res://" + plan_rel}


def main():
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--studio", default=STUDIO)
    ap.add_argument("--godot", default=os.environ.get("GODOT", ""),
                    help="Godot 4.7.2 console executable for the real-play gate (default: env GODOT)")
    args = ap.parse_args()
    if not args.godot:
        sys.exit("import_release_pool_levels: no Godot given (--godot or env GODOT); the real-play gate "
                 "tools/real_play_verify.gd must run on the imported levels, refusing to import without it")
    with open(os.path.join(REPO, "data/palettes/scrubbots_palette_v3.json"), encoding="utf-8") as f:
        cids = {c["hex"].upper(): c["id"] for c in json.load(f)["colors"]}
    cat_rel = "data/levels/catalog/production_catalog_v1.json"
    with open(os.path.join(REPO, cat_rel), encoding="utf-8") as f:
        cat = json.load(f)
    entries = [e for e in cat["entries"] if e["order"] < LEVELS[0][0]]
    for row in LEVELS:
        entries.append(import_level(args.studio, cids, *row))
        print("imported", entries[-1]["id"])
    cat["entries"] = entries
    write_json(cat_rel, cat, False)
    orders = ",".join(str(row[0]) for row in LEVELS)
    gate = subprocess.run([args.godot, "--headless", "--path", REPO, "-s", "res://tools/real_play_verify.gd",
                           "--", "--levels", orders, "--regen"])
    if gate.returncode != 0:
        sys.exit("import_release_pool_levels: real-play gate failed (exit %d); see the LEVEL/UNWINNABLE lines above"
                 % gate.returncode)


if __name__ == "__main__":
    main()
