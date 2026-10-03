import json
import subprocess
from collections import Counter
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[4]
CYCLE = ROOT / "coordination/sessions/M43-C005-C003"
EVIDENCE = CYCLE / "evidence"
inventory = json.loads((CYCLE/"COLLECTION_CARD_GENERATION_INVENTORY_V01.json").read_text(encoding="utf-8"))
old_doc = json.loads((CYCLE/"OLD_CANONICAL_CARD_SHA256_V01.json").read_text(encoding="utf-8"))
manifest_doc = json.loads((CYCLE/"COLLECTION_CARD_GENERATION_MANIFEST_V01.json").read_text(encoding="utf-8"))
runs = [json.loads(s) for s in (CYCLE/"CARD_GENERATION_RUN_V01.jsonl").read_text(encoding="utf-8").splitlines() if s.strip()]
cards = sorted(inventory["cards"], key=lambda x: x["global_sequence"])
rows = manifest_doc["cards"]
old_by_path = {x["path"]:x["sha256"] for x in old_doc["cards"]}
run_by_seq = {x["global_sequence"]:x for x in runs}
manifest_by_seq = {x["global_sequence"]:x for x in rows}
checks = []
errors = []

def check(label, condition, detail=""):
    checks.append((label, bool(condition), detail))
    if not condition:
        errors.append(f"FAIL {label}: {detail}")

expected_paths = {f"assets/ui/final/collection/cards/set_{s:02d}/card_{i:02d}.png" for s in range(1,16) for i in range(1,10)}
actual_paths = {x["canonical_card_file_path"] for x in cards}
check("15 sets / 9 cards / 135 inventory rows", len(cards)==135 and len({x["set_number"] for x in cards})==15 and all(sum(c["set_number"]==s for c in cards)==9 for s in range(1,16)), f"rows={len(cards)} sets={len({x['set_number'] for x in cards})}")
check("canonical path mapping is exactly the 15x9 tree", actual_paths==expected_paths and set(old_by_path)==expected_paths, f"inventory_paths={len(actual_paths)} old_sha_paths={len(old_by_path)}")
check("135 generation records and manifest rows", len(runs)==135 and len(rows)==135 and len(run_by_seq)==135 and len(manifest_by_seq)==135, f"runs={len(runs)} manifest={len(rows)}")
check("manifest origin is individually_generated", manifest_doc.get("final_asset_origin")=="individually_generated" and all(x.get("final_asset_origin")=="individually_generated" for x in rows), "")
check("135 unique generated illustrations and output paths", len({x.get("generated_illustration_sha256") for x in runs})==135 and len({x.get("tool_output_path",x.get("generated_tool_output_path")) for x in runs})==135, "")
check("no multi-card/crop source path used", all(not any(t in str(x.get("tool_output_path",x.get("generated_tool_output_path",""))).lower() for t in ("sheet","collage","sprite","crop")) for x in runs), "")
check("manifest card metadata matches inventory", all(manifest_by_seq.get(c["global_sequence"],{}).get("name")==c["exact_displayed_card_name"] and manifest_by_seq.get(c["global_sequence"],{}).get("rarity")==c["exact_rarity"] and manifest_by_seq.get(c["global_sequence"],{}).get("star_count")==c["star_count_shown_by_source"] for c in cards), "names, rarities, and stars")
check("all old and new hashes differ", all(x["old_production_sha256"]!=x["new_production_sha256"] for x in rows), "")
check("all cards are marked generated", len(cards)==135 and all(x.get("generation_status")=="GENERATED" and x.get("output_sha256") for x in cards), "")

bad_format=[]; bad_alpha=[]; empty=[]; hash_mismatch=[]
for c in cards:
    path=ROOT/c["canonical_card_file_path"]
    seq=c["global_sequence"]
    try:
        with Image.open(path) as im:
            im.load()
            if im.format!="PNG" or im.mode!="RGBA" or im.size!=(1024,1536): bad_format.append(seq)
            alpha=im.getchannel("A")
            if any(alpha.getpixel(p)!=0 for p in ((0,0),(1023,0),(0,1535),(1023,1535))): bad_alpha.append(seq)
            if not alpha.getbbox(): empty.append(seq)
    except Exception:
        bad_format.append(seq)
    run=run_by_seq.get(seq,{})
    man=manifest_by_seq.get(seq,{})
    expected=c.get("output_sha256")
    actual=run.get("new_production_sha256")
    if not path.exists() or not expected or actual!=expected or man.get("new_production_sha256")!=expected: hash_mismatch.append(seq)
check("all outputs are 1024x1536 RGBA PNG", not bad_format, str(bad_format[:10]))
check("all card corners are transparent", not bad_alpha, str(bad_alpha[:10]))
check("no empty images", not empty, str(empty[:10]))
check("inventory, manifest, run log and files hash-match", not hash_mismatch, str(hash_mismatch[:10]))

profiles=[]
for s in range(1,16):
    counts=Counter(x["exact_rarity"] for x in cards if x["set_number"]==s)
    expected={"COMMON":4,"RARE":2,"EPIC":2,"LEGENDARY":1} if s<15 else {"RARE":3,"EPIC":3,"LEGENDARY":3}
    if dict(counts)!=expected: profiles.append((s,dict(counts)))
check("rarity profile per set", not profiles, str(profiles))

tree_pngs={p.relative_to(ROOT).as_posix() for p in (ROOT/"assets/ui/final/collection/cards").rglob("*.png")}
check("exactly 135 canonical card PNG files", tree_pngs==expected_paths and len(tree_pngs)==135, f"pngs={len(tree_pngs)} extras={sorted(tree_pngs-expected_paths)[:5]}")
evidence_sheets=list(EVIDENCE.glob("set_*_contact_sheet.jpg"))
zoom_samples=list((EVIDENCE/"random_zoom_qa_samples").glob("*.png"))
template_examples=list((EVIDENCE/"four_rarity_template_examples").glob("*_template_example.png"))
check("15 set sheets, 1 master, 4 template examples, 15 zoom samples", len(evidence_sheets)==15 and (EVIDENCE/"master_135_contact_sheet.jpg").exists() and len(template_examples)==4 and len(zoom_samples)==15, f"sets={len(evidence_sheets)} templates={len(template_examples)} zooms={len(zoom_samples)}")

# Every changed path must be a canonical card or session evidence. This also proves
# pack-opening assets, economy/config and runtime code stayed outside the diff.
git_names=subprocess.run(["git","diff","--name-only","HEAD"],cwd=ROOT,text=True,capture_output=True,check=True).stdout.splitlines()
allowed=set(expected_paths)|{p.relative_to(ROOT).as_posix() for p in (ROOT/"coordination/sessions/M43-C005-C003").rglob("*") if p.is_file()}
outside=[x for x in git_names if x.replace("\\","/") not in allowed]
check("scope contains only canonical card assets and task evidence", not outside, str(outside[:20]))
check("root TASKS is untouched", "TASKS.md" not in git_names and "TASKS.md" not in [x.replace("\\","/") for x in git_names], "")

result={"validator":"M43-C005-C003 collection card asset validator","passed":not errors,"checks":[{"name":n,"passed":ok,"detail":d} for n,ok,d in checks],"errors":errors}
out=CYCLE/"evidence/COLLECTION_CARD_VALIDATION_V01.json"
out.write_text(json.dumps(result,indent=2)+"\n",encoding="utf-8")
print(json.dumps(result,indent=2))
raise SystemExit(0 if not errors else 1)
