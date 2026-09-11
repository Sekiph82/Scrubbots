# PROJECT-WIDE DIFFICULTY V1 MIGRATION PLAN

Status: **APPROVED DESIGN / IMPLEMENTATION ROADMAP — 2026-09-12**
Owner decision: `OWNER_DIFFICULTY_PROGRESSION_DECISION_V01.md`

This plan turns the owner-approved Difficulty / Progression / Retention V1 model into a controlled project-wide migration without destabilizing the active M21 real-art vertical slice.

## A. Migration principles

1. Design truth changes immediately.
2. M21 remains a narrow real-art integration proof and is not rewritten mid-cycle.
3. Legacy runtime difficulty validators are compatibility debt, not future design authority.
4. No scaled production campaign is generated under the obsolete class=dimension/color model.
5. Every runtime/content migration is independently testable and auditable.
6. Existing gameplay semantics, M20 clearing transaction, routing, targeting and renderer contracts remain intact unless a new owner decision explicitly changes them.
7. Root `TASKS.md` remains the live status tracker; its historical difficulty wording must be migrated in a dedicated governance-safe edit before Difficulty V1 implementation starts.

## B. Already completed in this design update

- Owner-locked Difficulty V1 decision created.
- Fixed ten-level cadence locked.
- Saturating global progression formula locked.
- Seven-axis Challenge Score V1 defined.
- Session Load separated from Challenge.
- Frustration Risk separated from Challenge.
- Recovery/retention/novelty principles locked.
- Level Factory evaluator-guided architecture defined.
- Calibration/QA strategy defined.
- Machine-readable progression config created.
- Machine-readable score-model config created.
- Machine-readable generator-acceptance config created.
- Project brief updated.
- Gameplay spec updated.
- Level Data spec updated.
- Pixel-art palette rules updated.
- Roadmap updated.
- Claude operating manual updated.

## C. Workstream DV1-00 — Governance / tracker migration

Goal: eliminate conflicting live instructions without rewriting historical audit evidence.

### DV1-00-001 Root TASKS owner-rule migration

Update root `TASKS.md` while preserving all unfinished tasks/history:

- replace §8.3 class-specific dimension bands with global 20..59 production envelope + mobile-size guidance;
- replace §8.7B class-specific color bands with global 3..12 used-color rule + Challenge Score relation;
- add exact ten-level cadence;
- add global progression formula;
- add Challenge/SessionLoad/Frustration separation;
- add new source-of-truth links;
- update M31/M32/M47/M48/LF01..LF10 task wording;
- update risk register;
- preserve M21 current status and task checkboxes;
- do not close implementation tasks merely because design docs exist.

### DV1-00-002 Historical rule preservation

Keep the old tracker/manual text as immutable historical evidence under `docs/migration/` rather than deleting history.

### DV1-00-003 Audit-policy integration

Add Difficulty V1 audit expectations:

- score assertions must observe the real metric property;
- generator-authored tests cannot alone prove calibration quality;
- campaign cadence/recovery must be tested across distant level numbers;
- model version changes require regression comparison.

## D. Workstream DV1-01 — Runtime production-legality migration

Goal: stop runtime/content validation from using dimensions/colors as difficulty identity while preserving generic LevelData.

Target files likely include:

- `scripts/data/difficulty_rules.gd`
- `scripts/data/production_level_validator.gd`
- importer production preflight callers/tests
- catalog validators when M30 exists

### DV1-01-001 Split concepts

Introduce separate concepts:

```text
ProductionBoardEnvelope
DifficultyClass / CadenceClass
ProgressionTarget
ArtworkPaletteLegality
DifficultyMetrics
```

Do not reuse one `DifficultyRules` object to answer all five questions.

### DV1-01-002 ProductionBoardEnvelope

Canonical V1:

```text
width 20..59
height 20..59
rectangular allowed
```

Optionally expose guidance buckets compact/standard/large/exceptional as metadata, never legality labels.

### DV1-01-003 Palette legality

Validate:

- C01..C16 only;
- ACTIVE opaque;
- used-only local palette;
- ascending C-ID;
- 3..12 distinct used colors;
- no BG01/CLEARED in local palette.

### DV1-01-004 Legacy compatibility

Keep tests proving the approved M21 asset remains valid after migration.

### DV1-01-005 Negative matrix

Reject:

- dimension 19 or 60;
- off-palette color;
- 2 or 13 distinct production colors under V1;
- semi-alpha ACTIVE source;
- unused local palette entry;
- nonascending canonical local palette;
- TEST in production.

### DV1-01-006 Independence tests

Prove:

- 24x24 artifact can carry any production class label structurally without dimension rejection;
- 38x38 EASY is legal if other production gates pass;
- board size alone cannot assign class;
- color count alone cannot assign class.

## E. Workstream DV1-02 — Progression service

Create a pure deterministic service reading `level_progression_v1.json`.

### API concepts

```text
get_cadence_slot(level_number)
get_class(level_number)
get_cycle_index(level_number)
get_progression_factor(level_number)
get_target_challenge(level_number)
get_novelty_target(level_number)
get_recovery_requirement(from_level,to_level)
```

### Required tests

- n<=0 fail closed;
- exact 1..10 sequence;
- exact repeat 11..20;
- large n deterministic/finite;
- target examples 11/111/310/311/1001/1010;
- same-slot targets increase monotonically and asymptotically;
- class ordering stays separated;
- recovery formula expectations remain true.

## F. Workstream DV1-03 — LevelMetrics schema

Versioned detached data object containing:

```text
modelVersion
W,C,A,U,B,R,S
challengeScore
sessionLoad
estimatedAttemptSeconds
frustrationRisk
solvabilityVerdict
solverDiagnostics
noveltySignature
readability fields
provenance
```

Requirements:

- immutable-by-convention/detached outputs;
- finite values only;
- clear unavailable/provisional status per metric;
- serialization deterministic;
- model version mandatory.

## G. Workstream DV1-04 — Pure Factory simulation adapter

Implement in `level_factory/`, not main runtime.

### Responsibilities

- load candidate LevelData/slot config;
- represent logical state compactly;
- expose canonical legal productive actions;
- apply one logical action deterministically;
- query completion;
- stable state hashing;
- no rendering/animation dependency.

### Canonical semantics reused

- ACTIVE/CLEARED;
- color candidates;
- reachability;
- reservations if needed by step model;
- exact five-slot rules currently implemented;
- no invented future queue/cooldown.

## H. Workstream DV1-05 — Oracle solver

### V1 requirements

- deterministic search ordering;
- memoization;
- bounded node/time budgets;
- reproducible verdict;
- SOLVED / UNSOLVABLE / INCONCLUSIVE distinction;
- solution path;
- states visited;
- dead ends;
- depth;
- branching statistics.

### Scaling strategy

Exploit monotonic ACTIVE→CLEARED structure and frontier/unlock analysis. Avoid naive copying of full 3481-cell arrays per search node when compact bitset/versioned representations are possible.

## I. Workstream DV1-06 — Metric analyzers

Implement each metric separately with golden fixtures.

### W Workload

- active cell count;
- compressed sqrt normalization;
- optional solution route-distance support.

### C Color Complexity

- distinct canonical count;
- normalized Shannon entropy;
- exact color histogram evidence.

### A Accessibility Scarcity

- raw vs reachable candidate ratio over reference states;
- early/mid weighting.

### U Unlock Depth

- earliest reachability wave per cell;
- p95/mean/initially-locked measures.

### B Bottleneck Pressure

- productive action counts;
- forced states;
- forced streak length.

### R Route Complexity

- canonical route lengths;
- detour ratios;
- turn metrics.

### S Slot/Color Pressure

- no-work slot fraction;
- single-productive-slot fraction;
- demand imbalance;
- no speculative mechanics.

### Analyzer tests

Build paired fixtures where exactly one factor changes while others remain approximately controlled.

## J. Workstream DV1-07 — Challenge Score engine

- load versioned coefficients from config;
- reject nonfinite/unknown metric input;
- calculate 0..100 score;
- expose contribution breakdown;
- store exact config/model hash;
- no hardcoded duplicate coefficients in editor/runtime/tests.

Properties:

- increasing one positive metric with others fixed cannot lower score;
- score bounded;
- weights sum 1 within tolerance;
- config mutation under same version rejected by QA policy.

## K. Workstream DV1-08 — Session Load model

Initial proxy:

```text
50% action count
30% cumulative canonical route time
20% decision count
```

Implement separately from challenge.

Tests must prove:

- same Challenge can have different Session Load;
- more cells can increase load without automatically reclassifying challenge;
- estimated seconds clearly marked PROXY before calibration.

## L. Workstream DV1-09 — Human-policy ensemble / Frustration V1

Start only after oracle/legal simulation is stable.

Policies:

- greedy valid;
- bounded stochastic human-like;
- adversarial legal.

Outputs:

- simulated pass rate;
- failure progress distribution;
- retry-risk proxy;
- late-failure rate.

Frustration V1:

```text
35% retry risk
30% session overrun
20% late failure
15% choice opacity
```

Must remain explicitly provisional until calibrated.

## M. Workstream DV1-10 — Novelty / similarity engine

Signature fields:

- art category/silhouette hash;
- dimensions/aspect bucket;
- palette set/histogram;
- challenge vector;
- unlock/frontier histogram;
- route metric bucket;
- slot pressure bucket;
- generator family.

Implement multi-signal similarity rather than a single image hash.

Recent window initial size: 20 levels.

## N. Workstream DV1-11 — Candidate Acceptance Evaluator

Input:

```text
GenerationRequest
CandidateRecord
LevelMetrics
recent campaign context
```

Output:

```text
ACCEPT
REJECT
MUTATE
QUARANTINE_INCONCLUSIVE
```

With explicit reason codes.

Hard reject rules from `level_generator_acceptance_v1.json` are non-negotiable.

## O. Workstream DV1-12 — Generator upgrades

### Request-aware generation

Generate against:

- target challenge;
- challenge profile preference;
- Session Load band;
- Frustration ceiling;
- novelty target;
- recent signatures;
- art mode;
- global dimension envelope.

### Modes

ART_FIRST, PUZZLE_FIRST, HYBRID.

### Bounded search

- max candidates;
- max mutations;
- solve budget;
- batch budget;
- resumable checkpoints.

## P. Workstream DV1-13 — Safe mutation engine

Generated candidates only unless owner explicitly authorizes editing source art.

Mutation categories must target measured deficits, e.g. reduce B/U or increase C/R, then fully re-solve/re-score.

Every mutation has lineage/provenance.

## Q. Workstream DV1-14 — CampaignBuilder

For each level n:

1. derive cadence class;
2. calculate target challenge;
3. derive novelty/load/frustration budgets;
4. filter accepted pool;
5. rank target fit;
6. apply similarity penalties;
7. apply vector-diversity constraints;
8. check actual recovery against prior selected level;
9. select deterministically;
10. record campaign build provenance.

If no valid candidate exists, request more generation rather than mislabeling.

### Campaign regression

Mandatory points:

```text
1..20
91..120
291..320
991..1020
```

Explicitly assert 310 boss → 311 recovery.

## R. Workstream DV1-15 — Factory editor

Expose:

- level number;
- cadence class/slot;
- target/actual challenge;
- W/C/A/U/B/R/S;
- Session Load;
- Frustration;
- unlock/frontier visualization;
- solver diagnostics;
- novelty/similarity;
- seed/reproduce;
- rejection reasons;
- mutation lineage;
- owner/source lock status;
- export approval.

## S. Workstream DV1-16 — Main-game catalog / campaign metadata

M30 integration stores or references:

- campaign order;
- class;
- challenge metrics/version;
- Session Load;
- Frustration;
- novelty signature;
- content/source hashes;
- generator/solver versions.

Core LevelData V1 remains stable; analysis belongs in catalog/sidecar metadata.

## T. Workstream DV1-17 — Production scale-up

M47 becomes accepted-pool production.

Batch request counts are **accepted** counts, not raw attempts.

Reports include rejection reasons/rates and target-fit distributions.

Do not bulk-create 100+ shipping levels until solver/metrics/campaign QA passes.

## U. Workstream DV1-18 — M48 QA upgrade

Every production level:

- legal 20..59 dimensions;
- canonical palette;
- 3..12 used colors;
- exact source/reconstruction where applicable;
- solvable;
- no routing pathology;
- target challenge fit;
- vector stored;
- Session Load pass;
- Frustration pass;
- novelty/similarity pass;
- mobile readability pass;
- performance pass;
- provenance complete.

Every campaign window:

- cadence correct;
- recovery correct;
- vector variety adequate;
- no repeated high-workload streak;
- no near-duplicate structural+visual run.

## V. Workstream DV1-19 — Internal calibration

Create structured playtest dataset and compare predicted metrics to:

- perceived difficulty;
- completion;
- attempts;
- duration;
- fairness;
- engagement;
- boredom;
- readability.

Model promotion requires versioned regression and independent audit.

## W. Workstream DV1-20 — Optional telemetry calibration

Blocked on future explicit owner analytics/privacy approval.

If later opened, aggregate outcomes may recalibrate V2+.

V1 does not authorize individualized hidden dynamic difficulty.

## X. Main-game milestone remapping

### M21

Unchanged narrow vertical slice.

### M22–M24

UI/touch must handle board size independently from difficulty label.

### M30

Catalog metadata upgrade.

### M31

Primary main-game Difficulty V1 integration.

### M32

CampaignBuilder/progression integration; cadence design is no longer unresolved.

### M40

Difficulty diagnostics overlay.

### M41/M42

Performance/readability matrix decoupled from class.

### M47

Factory accepted-pool production.

### M48

Difficulty/retention QA.

### M49/M50

Regression/long campaign/chaos.

### M51

Optional analytics remains owner-gated.

## Y. Risk register additions

### DV1-R001 — metric gaming

Generator learns to hit scalar score while producing repetitive levels.
Mitigation: challenge-vector diversity + novelty + human QA.

### DV1-R002 — solver explosion

Large monotonic boards create excessive search.
Mitigation: frontier/wave analysis, compact state, memoization, bounded budgets, INCONCLUSIVE truth.

### DV1-R003 — long means hard

Workload dominates perceived difficulty.
Mitigation: compressed W + separate Session Load.

### DV1-R004 — frustration mistaken for challenge

Late failures/high retries inflate perceived hardness.
Mitigation: separate Frustration Risk and caps.

### DV1-R005 — overfitting internal testers

Model fits a tiny skilled group.
Mitigation: diverse structured playtests and later owner-approved aggregate calibration.

### DV1-R006 — repetition despite target fit

Many mathematically valid levels feel identical.
Mitigation: signature similarity + challenge-profile rotation.

### DV1-R007 — old rule drift

Legacy dimension/color band assumptions reappear.
Mitigation: owner decision precedence, repo search, migration tests.

### DV1-R008 — impossible late campaign

Linear difficulty growth never stops.
Mitigation: saturating progression curve.

### DV1-R009 — boss churn

Every 10th level becomes a wall.
Mitigation: clear-rate/frustration targets and guaranteed next-level recovery.

### DV1-R010 — unreadable large boards

Technical renderer support is mistaken for good phone presentation.
Mitigation: exceptional-size readability gate.

## Z. Completion definition for Difficulty V1 program

Difficulty V1 is production-ready only when:

- live governance no longer relies on obsolete class dimension/color bands;
- runtime production legality uses global envelope/palette rules;
- progression service is deterministic/tested;
- Factory solver is authoritative enough for production acceptance;
- all seven metrics are implemented or explicitly version-disabled with redistributed weights (never silently missing);
- Challenge/SessionLoad/Frustration models are separate and versioned;
- generator can produce multiple target-fit candidates;
- campaign builder reproduces exact ten-level cadence;
- level 311 EASY is harder than level 11 EASY;
- recovery after peaks is proven on actual selected level metrics;
- variety/similarity checks work;
- M47 batch scale-up uses accepted pools;
- M48 QA rejects bad-fit content;
- internal calibration supports the model;
- independent strict audit passes.
