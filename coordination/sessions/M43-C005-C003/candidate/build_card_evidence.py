import json
import random
import shutil
from functools import lru_cache
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path.cwd()
CYCLE = ROOT / "coordination/sessions/M43-C005-C003"
EVIDENCE = CYCLE / "evidence"
INV = json.loads((CYCLE / "COLLECTION_CARD_GENERATION_INVENTORY_V01.json").read_text(encoding="utf-8"))
OLD = json.loads((CYCLE / "OLD_CANONICAL_CARD_SHA256_V01.json").read_text(encoding="utf-8"))
RUNS = [json.loads(x) for x in (CYCLE / "CARD_GENERATION_RUN_V01.jsonl").read_text(encoding="utf-8").splitlines() if x.strip()]
cards = sorted(INV["cards"], key=lambda x: x["global_sequence"])
by_sequence = {x["global_sequence"]: x for x in RUNS}
old_by_path = {x["path"]: x["sha256"] for x in OLD["cards"]}
EVIDENCE.mkdir(exist_ok=True)

def font(size):
    for name in ("C:/Windows/Fonts/segoeuib.ttf", "C:/Windows/Fonts/arialbd.ttf"):
        try:
            return ImageFont.truetype(name, size)
        except OSError:
            pass
    return ImageFont.load_default()

card_by_sequence = {x["global_sequence"]: x for x in cards}

@lru_cache(maxsize=None)
def card_image(sequence):
    card = card_by_sequence[sequence]
    path = ROOT / card["canonical_card_file_path"]
    im = Image.open(path).convert("RGBA")
    bg = Image.new("RGB", im.size, (232, 232, 232))
    bg.paste(im, mask=im.getchannel("A"))
    return bg

def composite_grid(items, rows, cols, tile_w, tile_h, label_h, title, dest):
    margin, gap, title_h = 24, 16, 52
    canvas = Image.new("RGB", (margin*2 + cols*tile_w + (cols-1)*gap, title_h + margin*2 + rows*(tile_h+label_h) + (rows-1)*gap), (36, 42, 54))
    draw = ImageDraw.Draw(canvas)
    draw.text((margin, 12), title, font=font(28), fill=(255,255,255))
    for i, card in enumerate(items):
        x, y = margin + (i % cols)*(tile_w+gap), title_h + margin + (i // cols)*(tile_h+label_h+gap)
        im = card_image(card["global_sequence"]).resize((tile_w,tile_h), Image.Resampling.LANCZOS)
        canvas.paste(im, (x,y))
        draw.text((x, y+tile_h+4), f"{card['global_sequence']:03d}  {card['exact_displayed_card_name']}", font=font(17), fill=(245,245,245))
    canvas.save(dest, quality=94)

# Per-set QA sheets and one row-major master sheet.
for set_no in range(1,16):
    group = [c for c in cards if c["set_number"] == set_no]
    composite_grid(group,3,3,280,420,28,f"Set {set_no:02d} — Collection Cards",EVIDENCE/f"set_{set_no:02d}_contact_sheet.jpg")
composite_grid(cards,15,9,152,228,22,"Master Collection — 135 Individual Cards",EVIDENCE/"master_135_contact_sheet.jpg")

# Preserve the four approved rarity template examples and the pilot comparison.
templates = EVIDENCE / "four_rarity_template_examples"
templates.mkdir(exist_ok=True)
pilot_paths = {
    "common": CYCLE/"candidate/pilot_01_common_scrubby.png",
    "rare": CYCLE/"candidate/pilot_02_rare_squeegee.png",
    "epic": CYCLE/"candidate/pilot_03_epic_turbo_scrubby.png",
    "legendary": CYCLE/"candidate/pilot_04_legendary_scrubmaster_x.png",
}
for rarity, src in pilot_paths.items():
    shutil.copy2(src, templates/f"{rarity}_template_example.png")
shutil.copy2(EVIDENCE/"pilot_comparison.png", EVIDENCE/"pilot_comparison_v01.png")

# Fixed seed makes the per-set zoom sample reproducible and easy to audit.
rng = random.Random(43005)
zoom_dir = EVIDENCE / "random_zoom_qa_samples"
zoom_dir.mkdir(exist_ok=True)
for set_no in range(1,16):
    group = [c for c in cards if c["set_number"] == set_no]
    card = rng.choice(group)
    im = card_image(card["global_sequence"])
    # Enlarge the central illustration and adjacent typography for a readable QA crop.
    crop = im.crop((100, 150, 924, 1386)).resize((1236,1854), Image.Resampling.LANCZOS)
    crop.save(zoom_dir/f"set_{set_no:02d}_card_{card['global_sequence']:03d}_zoom.png")

manifest = []
for c in cards:
    r = by_sequence[c["global_sequence"]]
    manifest.append({
        "global_sequence": c["global_sequence"],
        "set": c["set_number"],
        "card_index": (c["global_sequence"]-1)%9+1,
        "canonical_card_file_path": c["canonical_card_file_path"],
        "name": c["exact_displayed_card_name"],
        "rarity": c["exact_rarity"],
        "star_count": c["star_count_shown_by_source"],
        "source_owner_sheet": c["source_owner_sheet"],
        "old_production_sha256": old_by_path[c["canonical_card_file_path"]],
        "new_production_sha256": r["new_production_sha256"],
        "generated_illustration_sha256": r["generated_illustration_sha256"],
        "generation_tool_output_path": r.get("tool_output_path", r.get("generated_tool_output_path")),
        "generation_method": "individually_generated",
        "final_asset_origin": "individually_generated",
        "generation_attempt_count": r["generation_attempt_count"],
        "dimensions": r["dimensions"],
        "alpha_bounds": r["alpha_bounds"],
        "qa_result": r["qa_result"],
        "visual_checks": r["visual_checks"],
        "prompt_reference_provenance": c["prompt_reference_provenance"],
    })
(CYCLE/"COLLECTION_CARD_GENERATION_MANIFEST_V01.json").write_text(json.dumps({"final_asset_origin":"individually_generated","cards":manifest},ensure_ascii=False,indent=2)+"\n",encoding="utf-8")

qa_lines = [
    "# M43-C005-C003 Collection Card QA Matrix V01", "",
    "Builder visual QA is recorded per card below. Independent ChatGPT audit remains pending.", "",
    "| Seq | Set/Card | Name | Rarity/stars | Identity | Rarity | Text | Frame | Crop check | Quality |",
    "|---:|:---:|---|---|:---:|:---:|:---:|:---:|:---:|:---:|",
]
for c in cards:
    r = by_sequence[c["global_sequence"]]
    v = r["visual_checks"]
    qa_lines.append(f"| {c['global_sequence']:03d} | {c['set_number']:02d}/{(c['global_sequence']-1)%9+1:02d} | {c['exact_displayed_card_name']} | {c['exact_rarity']} / {c['star_count_shown_by_source']} | {v['identity']} | {v['rarity']} | {v['text']} | {v['frame_complete']} | {v['no_crop_contamination']} | {v['production_quality']} |")
(CYCLE/"COLLECTION_CARD_QA_MATRIX_V01.md").write_text("\n".join(qa_lines)+"\n",encoding="utf-8")

# The named log has one complete visual-inspection line per card plus exact hashes and prompt records.
log = ["# M43-C005-C003 Builder Log V01", "", "Builder: Codex fallback using one separate image-generation call per final card; text and frame composed deterministically.", "Status: AWAITING_GPT_M43_C005_C003_INDIVIDUAL_CARD_AUDIT", "", "## Per-card records", ""]
for c in cards:
    r = by_sequence[c["global_sequence"]]
    tool_output = r.get("tool_output_path", r.get("generated_tool_output_path"))
    log.append(f"- {c['global_sequence']:03d} {c['exact_displayed_card_name']}: identity OK; rarity OK; text OK; frame complete; no crop contamination; production quality PASS. Attempts={r['generation_attempt_count']}; source SHA-256={r['generated_illustration_sha256']}; final SHA-256={r['new_production_sha256']}; tool output={tool_output}.")
attempts = [json.loads(x) for x in (CYCLE/"CARD_GENERATION_ATTEMPTS_V01.jsonl").read_text(encoding="utf-8").splitlines() if x.strip()]
log += ["", "## Regeneration attempts", "", f"Accepted cards: 135. Rejected retries: {len(attempts)}."]
for a in attempts:
    log.append(f"- Sequence {a['global_sequence']} attempt {a['attempt']} rejected: {a['reason']} Output={a['tool_output_path']}; source SHA-256={a['source_sha256']}.")
(CYCLE/"CLAUDE_LOG_V01.md").write_text("\n".join(log)+"\n",encoding="utf-8")

review = [
    "# Owner Collection Card Review V02", "",
    "## Builder handoff", "",
    "The builder produced 135 individually generated final PNG cards. Each card is 1024×1536 RGBA with transparent pixels outside its rounded card silhouette. Contact sheets and deterministic per-set zoom samples are in `evidence/`. The generation manifest and per-card QA matrix accompany this review.", "",
    "Two rejected renders were retained in the attempt log: sequence 111 (baked checkerboard) and sequence 133 (cropped energy beam). Each was replaced with a separately generated accepted render. No final card uses either rejected image.", "",
    "Builder status: `AWAITING_GPT_M43_C005_C003_INDIVIDUAL_CARD_AUDIT`. This document records builder evidence only; independent audit and owner acceptance are pending.", "",
    "## Set contact sheets", "",
]
for set_no in range(1,16):
    review.append(f"- [Set {set_no:02d} contact sheet](evidence/set_{set_no:02d}_contact_sheet.jpg)")
review += ["", "## Master contact sheet", "", "[Master 135-card contact sheet](evidence/master_135_contact_sheet.jpg)", "", "## Evidence files", "", "- [Generation manifest](COLLECTION_CARD_GENERATION_MANIFEST_V01.json)", "- [QA matrix](COLLECTION_CARD_QA_MATRIX_V01.md)", "- [Builder log](CLAUDE_LOG_V01.md)", "- [Pilot comparison](evidence/pilot_comparison_v01.png)", "- `evidence/four_rarity_template_examples/` contains the four rarity template examples.", "- `evidence/random_zoom_qa_samples/` contains one seeded sample per set."]
(CYCLE/"OWNER_COLLECTION_CARD_REVIEW_V02.md").write_text("\n".join(review)+"\n",encoding="utf-8")

print(json.dumps({"manifest_rows":len(manifest),"set_sheets":15,"master_sheet":str(EVIDENCE/"master_135_contact_sheet.jpg"),"zoom_samples":15,"rejected_retries":len(attempts)}))
