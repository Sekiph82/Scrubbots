# SB-M53-C001 — FIRST 10 LEVEL QA + DIFFICULTY V1 EVIDENCE

Status: READY FOR CLAUDE
Date: 2026-09-27
Repository: `Sekiph82/Scrubbots`
Branch: `main`

## Read first

1. `CLAUDE.md`
2. root `TASKS.md` READ ONLY
3. `coordination/sessions/M52-C001/FINAL_OWNER_ACCEPTANCE_V01.md`
4. `coordination/OWNER_M52_C001_FIRST_10_LEVEL_PACK_DECISION_V01.md`
5. `docs/09_DIFFICULTY_PROGRESSION_RETENTION_SYSTEM.md`
6. `coordination/OWNER_DIFFICULTY_PROGRESSION_DECISION_V01.md`
7. `data/config/level_progression_v1.json`
8. `data/config/difficulty_score_model_v1.json`
9. M27 solver/proof code and current production routing/access code
10. M52 First 10 level data, metadata, previews, owner supply plans and final evidence
11. R01/R02 runtime changes and audits

Do NOT edit root `TASKS.md`. ChatGPT owns tracker updates after audit.

## Mission

Create the first canonical, versioned **real-level QA + Difficulty V1 analysis** for production Levels 1–10.

This task must close M53 evidence honestly.

Do not:
- fabricate Challenge Score;
- relabel a level to make it fit;
- revive obsolete class=dimensions or class=color-count rules;
- implement a second incompatible routing law;
- weaken solver/routing/content validation;
- mutate owner source art or owner supply plans merely to make a metric pass.

If a level does not fit its owner-locked campaign class/target under the canonical analyzer, report the exact delta and stop that level as QA FAIL / TUNING REQUIRED.

## A. Canonical First 10 targets

Campaign class sequence is fixed:

1 EASY
2 EASY
3 MEDIUM
4 EASY
5 HARD
6 EASY
7 EASY
8 MEDIUM
9 EASY
10 VERY_HARD

Cycle 0 TargetChallenge values from the locked model:

| Level | Class | Target |
|---:|---|---:|
| 1 | EASY | 20 |
| 2 | EASY | 22 |
| 3 | MEDIUM | 40 |
| 4 | EASY | 19 |
| 5 | HARD | 58 |
| 6 | EASY | 18 |
| 7 | EASY | 21 |
| 8 | MEDIUM | 42 |
| 9 | EASY | 19 |
| 10 | VERY_HARD | 76 |

Default Challenge acceptance tolerance = target ±3.5.
A result outside ±5 must not be force-labeled.

## B. Build one canonical analysis seam

If the repository still lacks a real-level Difficulty V1 analyzer, implement one as a versioned analysis tool/library plus CLI/headless test entry.

It must consume:
- production LevelData;
- canonical production routing/access;
- canonical solver/proof state;
- exact production supply plan/generator state where the metric requires supply/slot context;
- versioned config.

It must produce a deterministic JSON record per level.

Do not make the runtime gameplay depend on this analyzer.

## C. Required Challenge vector

For every level compute and record:

`[W, C, A, U, B, R, S]`

with model version and raw supporting measurements.

### W — Workload
Use the V1 compressed workload principle from doc 09.
Record at minimum:
- active cell count;
- reference solution clear/dispatch count;
- route-distance proxy used;
- normalized W.

### C — Color Complexity
Record:
- used canonical color count;
- per-color frequency distribution;
- normalized Shannon entropy;
- count_norm;
- final C.

### A — Accessibility Scarcity
Use production accessibility/routing truth over the canonical reference solution.
Record:
- raw matching candidates;
- reachable matching candidates;
- progress-weighted samples;
- final A.

### U — Unlock Depth
Use canonical ACTIVE-blocker / CLEARED-open semantics.
Record:
- earliest reachability wave per cell or equivalent exact evidence;
- mean unlock wave;
- p95 unlock wave;
- initially locked fraction;
- normalized final U.

### B — Bottleneck Pressure
At reference decision states record:
- number of legal productive actions;
- reachable target alternatives;
- forced-state fraction;
- <=2 productive-action fraction;
- longest forced streak;
- normalized final B.

### R — Route Complexity
Consume production routing results.
Record:
- average route length;
- board-diagonal normalization;
- detour ratio;
- turn count;
- route-length variance if used;
- final R.

### S — Slot / Color Pressure
Use only canonical five-slot / current supply mechanics.
Record:
- no-work-slot fraction;
- single-productive-slot fraction;
- color-demand imbalance;
- final S.

## D. Challenge scalar

Compute exactly:

`D = 100 * (0.10W + 0.15C + 0.20A + 0.20U + 0.15B + 0.10R + 0.10S)`

Record:
- D;
- TargetChallenge;
- signed delta;
- absolute delta;
- acceptance-window status.

No hidden hand-tuning inside the analyzer.

## E. Session Load

Produce the first versioned per-level Session Load evidence using the V1 design:

- actions_norm;
- route_time_norm;
- decision_count_norm;
- estimated attempt-duration proxy;
- `SessionLoad = 100 * (0.50 actions_norm + 0.30 route_time_norm + 0.20 decision_count_norm)`.

If normalization anchors are not yet owner-locked in config:
- choose explicit documented provisional Stage-A reference anchors;
- version them;
- do not pretend they are calibrated player truth;
- report sensitivity/limitations.

## F. Frustration Risk

Do not fake a human clear-rate model.

If no trustworthy human-like simulator exists:
- implement only the exact/proxy components that can be supported;
- label Frustration Risk **PROVISIONAL_STAGE_A**;
- explicitly identify unsupported component(s), especially simulated-human-policy clear rate;
- do not infer a fake first-attempt clear probability from solver success.

Use owner playtest evidence only as qualitative supporting evidence, not as a fabricated numeric human population estimate.

## G. Per-level M53 QA

For every Level 1–10 verify and record:

- legal dimensions/envelope;
- correct owner-locked class token;
- exact canonical C01..C16 palette;
- used-color count 3..12;
- exact cell count;
- no invalid palette IDs;
- recognizable ACTIVE source reconstruction;
- no unintended interpolation;
- correct CLEARED transparency/render behavior;
- canonical solvability;
- no routing/access pathology;
- performance sanity;
- correct preview;
- unique stable ID;
- correct catalog order;
- exact source/metadata provenance;
- exact owner supply-plan provenance for Levels 2–10;
- Level 1 historical generator path unchanged.

## H. Recovery cadence checks

Using actual analyzed D values, check:

- L4 < L3 with intended strong drop;
- L6 < L5 with intended strongest mid-cycle recovery;
- L9 < L8;
- L10 remains the cycle boss;
- report actual gaps versus the design guard intentions.

Do not substitute target gaps for actual analyzed gaps.

## I. Novelty / profile evidence

For each level produce:
- dominant challenge profile;
- novelty signature fields currently measurable;
- nearest prior-level similarity within the First 10.

Do not invent art-category labels if no canonical category exists. Mark missing taxonomy honestly.

## J. Outputs

Create:

`coordination/sessions/M53-C001/evidence/first10_level_qa_v1.json`

`coordination/sessions/M53-C001/evidence/first10_difficulty_v1.json`

`coordination/sessions/M53-C001/FIRST10_M53_MATRIX_V01.md`

`coordination/sessions/M53-C001/CLAUDE_LOG_V01.md`

The matrix must show at minimum:

Level / ID / Class / Target D / Actual D / Delta / W C A U B R S / Session Load / Frustration status / Solver / Runtime provenance / M53 QA verdict.

## K. Tests

Add focused tests for:
- analyzer determinism;
- formula exactness;
- bounds [0,1] for W..S;
- stable model/config version;
- production routing/access reuse;
- no source mutation;
- target computation;
- acceptance-window classification;
- First 10 evidence schema;
- all M53 static QA gates.

Then run:
- focused M53 suite;
- M52 owner-plan suite;
- R01/R02 suites;
- relevant M27/M29/M30/M36 difficulty/progression tests;
- root test suite;
- `git diff --check`.

## L. Stop conditions

Do not silently remediate a level if:
- Actual D is outside acceptable target fit;
- Session Load is obviously outside its intended slot budget;
- a routing/QA pathology appears;
- analyzer evidence cannot support a required metric honestly.

Instead mark that level `TUNING_REQUIRED` with exact evidence.

## Deliverable / handoff

Commit and push all implementation/evidence/log work to main.

Finish with:

`AWAITING_CHATGPT_AUDIT / M53-C001 FIRST 10 LEVEL QA + DIFFICULTY V1`

Do not edit TASKS.md.
