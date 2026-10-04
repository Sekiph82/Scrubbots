"""M43-C005-C006 V03 - build STANDARD_FRAME_ALPHA_MANIFEST_V03.json from the cleanup metrics.

Asserts provenance before writing: historical candidate == C002 manifest sha (before), V03
candidate == shipping final == cleanup sha (after) for every frame.

Usage: python tools/build_m43_c005_standard_frame_manifest_v03.py
"""
import hashlib
import json
import os
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
HIST = "assets/ui/candidates/m43_c005/pack_opening/standard/"
CAND = "assets/ui/candidates/m43_c005/pack_opening/standard_v03_alpha_clean/"
FINAL = "assets/ui/final/rewards/pack_opening/standard/"
METRICS = ROOT / "coordination/sessions/M43-C005-C006/evidence/v03/cleanup_metrics_v03.json"
C002 = ROOT / "coordination/sessions/M43-C005-C002/PACK_ASSET_MANIFEST_V01.json"
OUT = ROOT / "coordination/sessions/M43-C005-C006/STANDARD_FRAME_ALPHA_MANIFEST_V03.json"


def sha(rel):
    return hashlib.sha256((ROOT / rel).read_bytes()).hexdigest()


def main():
    m = json.loads(METRICS.read_text())
    c002 = {Path(f["relative_path"]).name: f["sha256"] for f in json.loads(C002.read_text())["frames"] if "/standard/" in f["relative_path"]}
    frames = []
    for r in m["frames"]:
        n = r["frame"]
        assert sha(HIST + n) == c002[n] == r["sha256_before"], n
        assert sha(CAND + n) == sha(FINAL + n) == r["sha256_after"], n
        frames.append({"frame": n, "beat": int(n[6:8]), "action": r["action"],
                       "historical_path": HIST + n, "sha256_before": r["sha256_before"], "c002_manifest_sha256": c002[n],
                       "v03_candidate_path": CAND + n, "final_path": FINAL + n, "sha256_after": r["sha256_after"],
                       "bytes_after": os.path.getsize(ROOT / (FINAL + n)), "candidate_final_byte_identical": True,
                       "metrics_before": r["before"], "metrics_after": r["after"],
                       "over_black_abs_diff": r["over_black_max_abs_diff"], "registration": r["registration"]})
    out = {"schema_version": 1, "task": "SB-M43-064", "cycle": "M43-C005-C006 V03",
           "prompt": "coordination/sessions/M43-C005-C006/CHATGPT_PROMPT_V03.md",
           "method": "tools/clean_m43_c005_standard_frame_alpha_v03.py: keep each pixel's over-black colour, re-derive alpha "
                     "(solid objects opaque via bright-region closing + hole fill, dark-detail guard and exact C002 card "
                     "silhouettes; everything else = light with alpha = brightness, soft noise floor, faded to 0 near the old "
                     "flattened-canvas edge). Frames already clean are copied byte-for-byte.",
           "params": m["params"],
           "validator": "tools/validate_m43_c005_standard_frame_alpha_v03.py (rendered pixels: border band, largest dark "
                        "component, dark wash, bbox side fill, straight edge cut)",
           "frames": frames}
    OUT.write_text(json.dumps(out, indent=2) + "\n")
    for f in frames:
        print(f["beat"], f["action"], f["sha256_before"][:12], "->", f["sha256_after"][:12])


if __name__ == "__main__":
    main()
