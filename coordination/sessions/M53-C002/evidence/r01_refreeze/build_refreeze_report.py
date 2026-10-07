"""SB-M53-C002-R01-001 R02 — before/after report for the serialization-only re-freeze.

usage: python3 -I build_refreeze_report.py <old_snapshot_dir> <repo_root> <out.json> [<rescore_old.json> <rescore_new.json>]
(the rescore files come from tests/tools/m53_c002_refreeze_rescore.gd: old raw + old config, new raw + new config)

<old_snapshot_dir> holds byte copies of the pre-refreeze artifacts:
  corpus_raw/, holdout_raw/, calibration_corpus_v1.json, difficulty_v2_candidate_first10.json,
  level_difficulty_analysis_v2_candidate.json, DIFFICULTY_CALIBRATION_MATRIX_V01.md
Compares them with the regenerated artifacts in <repo_root>. Standard library only.
Volatile `timing` subtrees are excluded from value comparison (as in the M53 test).
"""
import hashlib, json, math, os, sys

OLD, ROOT, OUT = sys.argv[1], sys.argv[2], sys.argv[3]
EV = "coordination/sessions/M53-C002/evidence"
PAIRS = [  # (old relative path, new relative path, kind)
    ("calibration_corpus_v1.json", f"{EV}/calibration_corpus_v1.json", "derived"),
    ("difficulty_v2_candidate_first10.json", f"{EV}/difficulty_v2_candidate_first10.json", "derived"),
    ("level_difficulty_analysis_v2_candidate.json", "data/config/level_difficulty_analysis_v2_candidate.json", "derived"),
]
for d, kind in (("corpus_raw", "raw"), ("holdout_raw", "raw")):
    for f in sorted(os.listdir(os.path.join(OLD, d))):
        PAIRS.append((f"{d}/{f}", f"{EV}/{d}/{f}", kind))
MATRIX = ("DIFFICULTY_CALIBRATION_MATRIX_V01.md", "coordination/sessions/M53-C002/DIFFICULTY_CALIBRATION_MATRIX_V01.md")

def sha(p):
    return hashlib.sha256(open(p, "rb").read()).hexdigest()

def load(p):
    return json.load(open(p, encoding="utf-8"))

def _godot_print(x, half_up):
    """Old Godot JSON float text: String::num(x, max(1, 14 - floor(log10|x|))) -> printf("%.<p>lf");
    glibc rounds the exact binary value, msvcrt-style rounds the 17-significant-digit value half-up."""
    from decimal import Decimal, ROUND_HALF_UP
    if x == 0:
        return "0.0"
    p = max(1, 14 - math.floor(math.log10(abs(x))))
    s = format(Decimal("%.16e" % x).quantize(Decimal(1).scaleb(-p), rounding=ROUND_HALF_UP), "f") if half_up else "%.*f" % (p, x)
    s = s.rstrip("0")
    return s + "0" if s.endswith(".") else s

def old_print_matches(old, new):
    """True when the old committed number is exactly what the old (lossy) writer printed for the new
    full-precision double, under either C-runtime rounding model."""
    return any(float(_godot_print(new, m)) == old for m in (False, True))

def is_num(v):
    return isinstance(v, (int, float)) and not isinstance(v, bool)

numeric = {"raw": [], "derived": []}
other = []
structure = []

def walk(path, a, b, kind, art):
    if path.endswith("/timing"):
        return
    if isinstance(a, dict) and isinstance(b, dict):
        if set(a) != set(b):
            structure.append({"artifact": art, "path": path, "onlyOld": sorted(set(a) - set(b)), "onlyNew": sorted(set(b) - set(a))})
        for k in sorted(set(a) & set(b)):
            walk(f"{path}/{k}", a[k], b[k], kind, art)
    elif isinstance(a, list) and isinstance(b, list):
        if len(a) != len(b):
            structure.append({"artifact": art, "path": path, "oldLen": len(a), "newLen": len(b)})
        for i, (x, y) in enumerate(zip(a, b)):
            walk(f"{path}[{i}]", x, y, kind, art)
    elif is_num(a) and is_num(b):
        if float(a) != float(b):
            d = abs(float(b) - float(a))
            rel = d / max(abs(float(a)), abs(float(b))) if (a or b) else 0.0
            numeric[kind].append({"artifact": art, "path": path, "old": a, "new": b, "absDelta": d, "relDelta": rel,
                                  "oldIsLossyPrintOfNew": old_print_matches(float(a), float(b))})
    elif a != b:
        other.append({"artifact": art, "path": path, "old": a, "new": b})

artifacts = []
for o, n, kind in PAIRS + [(MATRIX[0], MATRIX[1], "doc")]:
    po, pn = os.path.join(OLD, o), os.path.join(ROOT, n)
    artifacts.append({"path": n, "oldSha256": sha(po), "newSha256": sha(pn), "bytesChanged": sha(po) != sha(pn)})
    if kind != "doc":
        walk("", load(po), load(pn), kind, n)

def stats(rows):
    return {"changedLeaves": len(rows), "maxAbsDelta": max([r["absDelta"] for r in rows], default=0.0),
            "maxRelDelta": max([r["relDelta"] for r in rows], default=0.0),
            "allOldAreLossyPrintsOfNew": all(r["oldIsLossyPrintOfNew"] for r in rows),
            "notExplainedByOldPrint": sum(1 for r in rows if not r["oldIsLossyPrintOfNew"])}

oc, nc = load(os.path.join(OLD, PAIRS[0][0])), load(os.path.join(ROOT, PAIRS[0][1]))
oh, nh = load(os.path.join(OLD, PAIRS[1][0])), load(os.path.join(ROOT, PAIRS[1][1]))

def corpus_decisions(c):
    return {"ordinalPairs": [[p["harder"], p["easier"], p["axis"], p["axisPass"], p["dPass"], p["pass"]] for p in c["ordinalPairs"]],
            "familyChecks": {k: v["pass"] for k, v in c["familyChecks"].items()},
            "robustness": {f["id"]: f["robustness"]["pass"] for f in c["fixtures"]},
            "allFixturesWithinTolerance": c["policyRobustness"]["allFixturesWithinTolerance"],
            "calibrationPass": c["calibrationPass"], "firstTenRead": c["firstTenRead"],
            "solvability": {f["id"]: f["solvability"]["status"] for f in c["fixtures"]},
            "profiles": {f["id"]: [f["profile"]["dominant"], f["profile"]["runnerUp"]] for f in c["fixtures"]}}

def holdout_decisions(h):
    return {"verdicts": {l["id"]: l["verdict"] for l in h["levels"]},
            "acceptanceWindow": {l["id"]: l["v2Candidate"]["acceptanceWindow"] for l in h["levels"]},
            "classRole": {l["id"]: [l["class"], l["role"]] for l in h["levels"]},
            "robustness": {l["id"]: l["robustness"]["pass"] for l in h["levels"]},
            "profiles": {l["id"]: [l["v2Candidate"]["profile"]["dominant"], l["v2Candidate"]["profile"]["runnerUp"]] for l in h["levels"]},
            "summary": h["summary"],
            "recoveryGuards": [[g["fromLevel"], g["toLevel"], g["lowerThanPeak"], g["pass"]] for g in h["recovery"]["guards"]],
            "l10Boss": {k: h["recovery"]["boss"][k] for k in ("level", "isCycleMaximum", "rankByActualD", "actualOrderDescending")}}

def rounded(c, h):
    out = {}
    for f in c["fixtures"]:
        out[f["id"]] = {"challengeScore_2dp": f"{f['challengeScore']:.2f}", "sessionLoad_1dp": f"{f['sessionLoad']:.1f}"}
    for l in h["levels"]:
        v = l["v2Candidate"]
        out[l["id"]] = {"challengeScore_2dp": f"{v['challengeScore']:.2f}", "signedDelta_2dp": f"{v['signedDelta']:+.2f}",
                        "sessionLoad_1dp": f"{v['sessionLoad']:.1f}"}
    return out

dec_old = {"corpus": corpus_decisions(oc), "holdout": holdout_decisions(oh)}
dec_new = {"corpus": corpus_decisions(nc), "holdout": holdout_decisions(nh)}
r_old, r_new = rounded(oc, oh), rounded(nc, nh)

om = open(os.path.join(OLD, MATRIX[0]), encoding="utf-8").read().splitlines()
nm = open(os.path.join(ROOT, MATRIX[1]), encoding="utf-8").read().splitlines()
mdiff = [{"line": i + 1, "old": a, "new": b} for i, (a, b) in enumerate(zip(om, nm)) if a != b]
matrix_only_sha = len(om) == len(nm) and all("sha256" in d["old"] and "sha256" in d["new"] for d in mdiff)

ident = {f["id"]: [f["levelSha256"], f["supplySha256"]] for f in oc["fixtures"]}
ident_new = {f["id"]: [f["levelSha256"], f["supplySha256"]] for f in nc["fixtures"]}
hold_ident = {l["id"]: l["levelSha256"] for l in oh["levels"]}
hold_ident_new = {l["id"]: l["levelSha256"] for l in nh["levels"]}
sha_paths = [o for o in other if o["path"].endswith("frozenConfigSha256")]
non_sha_other = [o for o in other if not o["path"].endswith("frozenConfigSha256")]

invariants = {
    "fixtureLevelAndSupplyShaIdentical": ident == ident_new,
    "holdoutLevelShaIdentical": hold_ident == hold_ident_new,
    "corpusManifestShaIdentical": oc["corpusManifestSha256"] == nc["corpusManifestSha256"],
    "noStructuralChange": not structure,
    "onlyNonNumericChangeIsFrozenConfigSha": not non_sha_other,
    "corpusDecisionsIdentical": dec_old["corpus"] == dec_new["corpus"],
    "holdoutDecisionsIdentical": dec_old["holdout"] == dec_new["holdout"],
    "roundedScoresIdentical": r_old == r_new,
    "matrixIdenticalExceptFrozenShaLines": matrix_only_sha,
    "rawDeltasOnlyRecoveredPrintPrecision": all(r["oldIsLossyPrintOfNew"] for r in numeric["raw"]),
}
attribution = None
if len(sys.argv) > 5:
    ro, rn = load(sys.argv[4]), load(sys.argv[5])
    old_ev = {"corpus": {f["id"]: f for f in oc["fixtures"]}, "holdout": {l["id"]: l["v2Candidate"] for l in oh["levels"]}}
    new_ev = {"corpus": {f["id"]: f for f in nc["fixtures"]}, "holdout": {l["id"]: l["v2Candidate"] for l in nh["levels"]}}
    checked = old_ok = new_ok = 0
    misses = []
    for part in ("corpus", "holdout"):
        for lid, vals in ro[part].items():
            for key, v in vals.items():
                pairs = [(key, v, rn[part][lid][key], old_ev[part][lid][key], new_ev[part][lid][key])]
                if isinstance(v, dict):
                    pairs = [(f"{key}.{k}", v[k], rn[part][lid][key][k], old_ev[part][lid][key][k], new_ev[part][lid][key][k]) for k in v]
                for name, r_old, r_new, e_old, e_new in pairs:
                    checked += 1
                    a = old_print_matches(float(e_old), float(r_old))
                    b = float(r_new) == float(e_new)
                    old_ok += a
                    new_ok += b
                    if not (a and b):
                        misses.append({"part": part, "id": lid, "field": name, "rescoreOld": r_old, "evidenceOld": e_old,
                                       "rescoreNew": r_new, "evidenceNew": e_new})
    attribution = {"checkedDerivedValues": checked,
                   "oldRawOldConfigReproducesOldEvidence": old_ok, "newRawNewConfigReproducesNewEvidenceExactly": new_ok,
                   "misses": misses}
    invariants["derivedDeltasAttributableToRawPrecisionOnly"] = not misses

report = {
    "schema": "scrubbots.m53.c002_r01.refreeze_report.v1",
    "event": "SERIALIZATION_ONLY_PLATFORM_INDEPENDENT_REFREEZE",
    "frozenConfigSha256": {"old": oc["frozenConfigSha256"], "new": nc["frozenConfigSha256"]},
    "corpusManifestSha256": {"old": oc["corpusManifestSha256"], "new": nc["corpusManifestSha256"]},
    "artifacts": artifacts,
    "fixtureIdentity": {k: {"old": ident[k], "new": ident_new.get(k)} for k in ident},
    "holdoutLevelIdentity": {k: {"old": hold_ident[k], "new": hold_ident_new.get(k)} for k in hold_ident},
    "numericDeltas": {"raw": stats(numeric["raw"]), "derived": stats(numeric["derived"]),
                      "leaves": numeric["raw"] + numeric["derived"]},
    "structuralChanges": structure,
    "nonNumericChanges": {"frozenConfigShaFields": len(sha_paths), "other": non_sha_other},
    "decisions": {"old": dec_old, "new": dec_new},
    "roundedScores": {"old": r_old, "new": r_new},
    "matrixLineDiffs": mdiff,
    "derivedAttribution": attribution,
    "invariants": invariants,
    "allInvariantsHold": all(invariants.values()),
}
json.dump(report, open(OUT, "w"), indent="\t", sort_keys=True)
open(OUT, "a").write("\n")
print(json.dumps({"invariants": invariants, "raw": report["numericDeltas"]["raw"], "derived": report["numericDeltas"]["derived"],
                  "frozenConfigSha256": report["frozenConfigSha256"], "matrixLineDiffs": len(mdiff)}, indent=1))
