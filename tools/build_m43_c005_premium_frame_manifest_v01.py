"""M43-C005-C007 (SB-M43-065) - promote + manifest the Premium opening frames.

The nine owner-accepted Premium candidates (C002) are diagnosed from decoded pixels with the
V03 alpha/matte validator. Every frame that is already clean is promoted byte-for-byte to
assets/ui/final/rewards/pack_opening/premium/; a dirty frame stops the promotion (alpha
remediation would be required first). Writes PREMIUM_FRAME_MANIFEST_V01.json.

Usage: python tools/build_m43_c005_premium_frame_manifest_v01.py
"""
import hashlib
import json
import shutil
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import validate_m43_c005_standard_frame_alpha_v03 as V  # noqa: E402

ROOT = Path(__file__).resolve().parents[1]
SRC = "assets/ui/candidates/m43_c005/pack_opening/premium/"
DST = "assets/ui/final/rewards/pack_opening/premium/"
C002 = ROOT / "coordination/sessions/M43-C005-C002/PACK_ASSET_MANIFEST_V01.json"
OUT = ROOT / "coordination/sessions/M43-C005-C007/PREMIUM_FRAME_MANIFEST_V01.json"
FRAMES = ["frame_01_closed.png", "frame_02_charge.png", "frame_03_pressure.png", "frame_04_first_tear.png",
          "frame_05_tear_widens.png", "frame_06_card_edge.png", "frame_07_one_card_rises.png",
          "frame_08_cards_emerge.png", "frame_09_final_reveal.png"]


def sha(rel):
    return hashlib.sha256((ROOT / rel).read_bytes()).hexdigest()


def main():
    c002 = {Path(f["relative_path"]).name: f for f in json.loads(C002.read_text())["frames"] if "/premium/" in f["relative_path"]}
    rows = []
    for n in FRAMES:
        assert sha(SRC + n) == c002[n]["sha256"], "historical candidate drifted from C002: " + n
        metrics = V.analyse(V.load(ROOT / (SRC + n)))
        if not metrics["clean"]:
            sys.exit("DIRTY %s %s - alpha remediation required before promotion" % (n, metrics["failures"]))
        rows.append((n, metrics))
    (ROOT / DST).mkdir(parents=True, exist_ok=True)
    frames = []
    for n, metrics in rows:
        shutil.copyfile(ROOT / (SRC + n), ROOT / (DST + n))
        assert sha(DST + n) == sha(SRC + n)
        frames.append({"frame": n, "beat": int(n[6:8]), "action": "promoted_byte_identical_already_clean",
                       "candidate_path": SRC + n, "final_path": DST + n, "sha256": sha(DST + n),
                       "c002_manifest_sha256": c002[n]["sha256"], "bytes": (ROOT / (DST + n)).stat().st_size,
                       "expected_card_back_count": c002[n]["expected_card_count"],
                       "card_overlays": c002[n]["card_overlays"], "metrics": metrics})
        print(n, frames[-1]["sha256"], "clean", metrics["largest_dark_component_px"], metrics["dark_wash_px"])
    OUT.write_text(json.dumps({"schema_version": 1, "task": "SB-M43-065", "cycle": "M43-C005-C007 V01",
                               "prompt": "coordination/sessions/M43-C005-C007/CHATGPT_PROMPT_V01.md",
                               "validator": "tools/validate_m43_c005_standard_frame_alpha_v03.py (decoded pixels)",
                               "remediation_required": False, "frames": frames}, indent=2) + "\n")


if __name__ == "__main__":
    main()
