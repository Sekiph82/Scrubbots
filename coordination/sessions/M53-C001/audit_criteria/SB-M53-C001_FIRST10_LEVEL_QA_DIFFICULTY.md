# SB-M53-C001 — CHATGPT AUDIT CRITERIA

## Verdict purpose

Audit the First 10 production levels against M53 static QA and the canonical Difficulty V1 model.

PASS requires honest, reproducible evidence. A level with an out-of-window actual Challenge score is not converted to PASS by class relabeling.

## 1. Analyzer authority

- one versioned deterministic analyzer;
- production LevelData/routing/access/solver semantics reused;
- no duplicate incompatible routing model;
- no runtime gameplay dependency on analyzer;
- no owner art/plan mutation.

## 2. Challenge vector

For every Level 1–10:
- W,C,A,U,B,R,S all exist;
- each lies in [0,1];
- raw supporting measurements are recorded;
- metric-model version recorded;
- deterministic rerun matches.

## 3. Scalar formula

For every level:
`D = 100*(.10W+.15C+.20A+.20U+.15B+.10R+.10S)`

Target and delta are correct for campaign slot.

Acceptance-window classification is mechanical and honest.

## 4. Session Load

Session Load uses documented versioned Stage-A normalization.

Any provisional anchors are explicitly labeled and reproducible.

No human-time claim is made beyond the documented proxy.

## 5. Frustration Risk

No fake human clear-rate.

If human-like policy is absent/untrusted, result must be labeled provisional and unsupported components identified.

Solver success cannot be used as a human first-attempt clear probability.

## 6. Static M53 QA

Every Level 1–10 has evidence for:
- legal dimension/envelope;
- class token;
- palette / used-color envelope;
- cell count;
- source reconstruction;
- interpolation/transparency;
- solvability;
- routing/access sanity;
- performance;
- preview;
- unique ID/catalog/provenance.

## 7. Recovery cadence

Audit actual D, not target D.

Report L3→4, L5→6, L8→9 and local L10 boss relationship honestly.

If actual values invert intended recovery, flag TUNING_REQUIRED.

## 8. First 10 protected behavior

- owner supply plans unchanged;
- Level 1 unchanged;
- R01 parallel dispatch still passes;
- R02 early release still passes;
- production runtime remains 9/9 WON for Levels 2–10;
- frontier 11 remains CONTENT_MISSING.

## 9. Regression

Focused M53 tests pass.
Relevant difficulty/progression tests pass.
M52/R01/R02 pass.
Root suite pass.
No new SCRIPT ERROR/unexplained engine errors.
Diff clean.

## Verdict

If all ten satisfy M53 gates:
`AUDITED_PASS / M53-C001 / FIRST10 QA PASS / READY FOR M54`

If analyzer is valid but one or more levels miss required QA/difficulty fit:
`TUNING_REQUIRED / M53-C001 / <LEVEL IDS>`

If analyzer/evidence itself is invalid:
`CHANGES_REQUIRED / M53-C001`
