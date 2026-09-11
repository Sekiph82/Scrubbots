# 10 — Level Factory Generation, Solver & Scoring Architecture V1

Status: **CANONICAL DESIGN V1 — 2026-09-12**
Owner decision: `coordination/OWNER_DIFFICULTY_PROGRESSION_DECISION_V01.md`
Difficulty model: `docs/09_DIFFICULTY_PROGRESSION_RETENTION_SYSTEM.md`

## 1. Can the Level Generator actually do this?

Yes, if it is built as an **evaluator-guided search system**, not as a one-shot random generator.

The Factory does not need to magically create a perfect level in one attempt. It needs to:

1. receive a precise target envelope;
2. generate candidate content deterministically;
3. prove legality and solvability;
4. simulate/analyze the candidate;
5. compare measured metrics with the requested envelope;
6. accept, mutate or reject;
7. repeat under bounded search budgets;
8. preserve every seed/config/result for reproducibility.

This turns generation into an engineering optimization problem.

## 2. System boundaries

The nested `level_factory/` project remains separate from the mobile runtime.

Locked one-way flow:

```text
Campaign intent
    ↓
GenerationRequest
    ↓
Candidate Generator
    ↓
Candidate Level
    ↓
Legality Validator
    ↓
Canonical Puzzle Simulator / Solver
    ↓
Metrics Analyzer
    ↓
Acceptance Evaluator
   ↙  ↓  ↘
reject mutate accept
       ↓
   re-evaluate
       ↓
AcceptedCandidatePool
       ↓
CampaignBuilder
       ↓
Production Level Data / Campaign Data
       ↓
M30/M47/M48 QA + Content Pipeline
```

The mobile game never imports Factory scripts.

## 3. Core data contracts

### 3.1 GenerationRequest

Versioned, immutable-by-convention request:

```text
requestId
levelNumber (optional for free-generation pools)
cadenceSlot
requestedClass
progressionModelVersion
targetChallenge
challengeTolerance
sessionLoadMin / sessionLoadMax
frustrationRiskMax
noveltyTarget
recentSignatureSet
preferredChallengeProfiles
avoidedChallengeProfiles
productionDimensionEnvelope
artMode
seed / seedPolicy
maxCandidates
maxMutationsPerCandidate
maxWallClockBudget
```

A request contains targets, never implementation shortcuts such as "make it 50x50 because it is Very Hard".

### 3.2 CandidateRecord

Every candidate stores:

```text
candidateId
parentCandidateId
rootSeed
mutationSeed
generationRequestHash
generatorVersion
artGeneratorVersion (if applicable)
sourceArtIdentity / sourceHash
width / height
palette subset
logical cells
slot configuration
provenance
status
rejectionReasons[]
```

Candidate statuses:

```text
GENERATED
LEGALITY_REJECTED
SOLVER_UNSOLVABLE
SOLVER_INCONCLUSIVE
ANALYSIS_COMPLETE
TARGET_MISS
MUTATION_PENDING
VISUAL_REVIEW_PENDING
ACCEPTED_POOL
OWNER_APPROVED
PRODUCTION_EXPORTED
```

Never collapse `UNSOLVABLE` and `INCONCLUSIVE`.

### 3.3 LevelMetrics

Versioned result:

```text
challengeScore
W,C,A,U,B,R,S
sessionLoad
estimatedAttemptSeconds
frustrationRisk
solvabilityVerdict
referenceSolutionLength
statesVisited
deadEnds
branching statistics
unlock-wave statistics
route statistics
slot-pressure statistics
noveltySignature
recentSimilarityScore
readabilityMetrics
analysis versions
```

## 4. Three generation modes

### ART_FIRST

For owner art or generated recognizable artwork.

Flow:

```text
source artwork
→ exact canonical-palette validation/mapping
→ LevelData candidate
→ gameplay solver/metrics
→ accept/reject
```

Rules:

- owner-original art is immutable;
- if it misses target difficulty, reject it for that campaign slot or sequence it elsewhere;
- never secretly repaint owner-original art to force a score;
- generated artwork may be regenerated under a new seed/prompt/config when provenance is preserved.

Best for recognizable SCRUBBOTS images.

### PUZZLE_FIRST

Generate a valid puzzle/topology first, then apply an artwork/skin representation that preserves the puzzle contract.

This gives strongest difficulty control but has a higher risk of producing ugly/unrecognizable art. It therefore requires stronger visual QA.

### HYBRID

Preferred long-term production mode.

Generate artwork within explicit topology/complexity constraints, then evaluate it with the canonical solver. Failed candidates are regenerated or safely mutated.

The Hybrid loop can request, for example:

- compact vs standard board envelope;
- approximate color-complexity range;
- desired open-frontier profile;
- desired unlock-depth profile;
- silhouette/art category;
- palette family;

without commanding a final difficulty label by dimensions alone.

## 5. Candidate generation is multi-objective

The target is not merely `ChallengeScore = 45`.

The objective vector includes:

```text
challenge error
session-load error
frustration overflow
novelty shortfall
recent similarity
visual/readability penalties
solvability/legal penalties
```

Hard constraints are rejected, not traded away:

- invalid palette;
- invalid LevelData;
- source mutation where forbidden;
- proven unsolvable;
- broken ACTIVE/CLEARED semantics;
- duplicate production ID;
- unsupported dimensions;
- malformed five-slot contract;
- unacceptable mobile readability.

Soft objectives can be optimized.

## 6. Solver architecture

The solver must use canonical gameplay semantics, not a simplified alternate puzzle.

### 6.1 Pure simulation state

Keep simulation separate from rendering/animation.

State includes only truth required to determine legal progress, such as:

- ACTIVE/CLEARED cell state;
- reservation/assignment truth as needed by the simulated step model;
- five-slot configuration/state;
- any later owner-approved queue/cooldown mechanic;
- deterministic canonical access/reachability truth.

### 6.2 LegalMoveProvider

The solver asks one interface for legal productive actions.

The interface adapts canonical gameplay systems rather than re-inventing rules.

Conceptually:

```text
get_legal_actions(state) -> actions
apply_action(state, action) -> next_state
is_complete(state) -> bool
state_hash(state) -> stable hash
```

If gameplay semantics change, the adapter changes. Search logic does not.

### 6.3 Oracle search

Start with deterministic exact/bounded search suitable to actual state complexity:

- deterministic move ordering;
- memoized state hashes;
- transposition/visited-state table;
- dead-end detection;
- explicit node/time budget;
- solution path recording;
- bounded solution-count/entropy analysis where feasible.

Search implementation may evolve from DFS/BFS/A* style strategies after profiling. Correctness and reproducibility outrank cleverness.

### 6.4 Large-board scaling

A 59x59 board contains up to 3481 logical cells, so naive state-space search can explode.

The Factory therefore needs hierarchical reasoning:

1. exploit deterministic reachability waves;
2. group equivalent choices where proof allows;
3. cache candidate sets and access truth per state version;
4. use canonical deterministic heuristic ordering;
5. identify monotonic properties of ACTIVE→CLEARED progression;
6. use bounded/incremental analysis for metrics that do not require exhaustive search;
7. preserve `INCONCLUSIVE` rather than pretending a timeout means unsolvable.

Because cell state is monotonic ACTIVE→CLEARED, many analyses can operate on frontier/unlock structure rather than enumerate arbitrary reversible states.

## 7. Reference policies

Solvability and human-difficulty prediction are separate.

### Oracle

Purpose: prove a valid completion if possible and compute structural truth.

### Greedy-valid

Purpose: provide a simple deterministic non-oracle baseline.

Examples of legal deterministic heuristics may include nearest reachable target or maximum immediate availability gain, but the exact policy must be versioned.

### Human-like stochastic ensemble

Purpose: estimate robustness/failure/retry risk, not prove correctness.

Run many deterministic-seed simulations using bounded imperfect-choice policies. Record distribution, not a single magic result.

### Adversarial legal policies

Purpose: discover trap-prone/late-failure behavior and excessive brittleness.

## 8. Candidate acceptance loop

Pseudo-flow:

```text
for candidate_attempt in maxCandidates:
    candidate = generate(request, seed)

    legality = validate(candidate)
    if not legality.pass:
        reject(candidate)
        continue

    solve = oracle_solver(candidate, budget)
    if solve == UNSOLVABLE:
        reject(candidate)
        continue
    if solve == INCONCLUSIVE and request requires authoritative solve:
        quarantine(candidate)
        continue

    metrics = analyze(candidate, solve)
    verdict = target_evaluator(metrics, request)

    if verdict.accept:
        add_to_accepted_pool(candidate)
        continue

    if verdict.safe_mutation_possible:
        mutated = mutate(candidate, verdict, bounded_budget)
        revalidate_and_resolve(mutated)
    else:
        reject(candidate)
```

Every attempt is bounded. Search failure never spins forever.

## 9. Difficulty targeting by controlled mutation

Mutation is useful when a candidate is visually good but misses the target slightly.

Generated candidates may be mutated. Owner-original artwork may not be silently mutated.

Potential mutation families, only after each is proven to preserve canonical rules:

### Easing

- reduce locally severe bottlenecks;
- lower unlock depth;
- simplify color distribution;
- reduce route detour burden;
- reduce board workload while preserving recognizability;
- adjust generated slot/color distribution.

### Hardening

- increase meaningful unlock depth;
- create stronger but fair bottlenecks;
- increase color entropy/slot pressure within production limits;
- increase route complexity without routing pathology;
- increase challenge-axis diversity.

Every mutation:

1. creates a new candidate lineage node;
2. records exact mutation operation/seed;
3. runs full legality checks;
4. re-solves;
5. re-analyzes;
6. may still be rejected.

No score may be edited directly.

## 10. Score-directed search

For a request target `T`, define challenge error:

`E_D = abs(D - T)`

Other normalized penalties:

```text
E_L = session load outside requested band
E_F = frustration above max
E_N = novelty below target
E_S = similarity above max
E_V = visual/readability penalty
```

A candidate-ranking objective may use:

`Fitness = E_D + a*E_L + b*E_F + c*E_N + d*E_S + e*E_V`

Hard-constraint failure remains infinite/reject rather than a finite penalty.

Weights are Factory-search parameters, separate from the player-facing Challenge Score weights.

## 11. Artwork generation strategy

The puzzle generator should not be asked to create every pixel artistically by itself unless the chosen art engine is capable of strict logical-pixel output.

Recommended production pipeline:

```text
CampaignBuilder requests target envelope
→ Art Candidate Generator creates multiple canonical-palette pixel artworks
→ Exact source validator
→ LevelData conversion
→ Puzzle solver/evaluator
→ target-fit rejection/regeneration
→ owner/design visual review where required
→ accepted pool
```

The art generator receives constraints, not the final truth:

- allowed logical dimensions;
- C01..C16 only;
- desired approximate color-count/entropy region;
- silhouette category;
- readability floor;
- requested challenge-profile hints;
- no antialiasing/semi-alpha;
- deterministic/replayable generation where provider supports it.

The gameplay evaluator decides whether the resulting artwork creates an acceptable puzzle.

## 12. Mobile readability gate

Logical source resolution and physical display size are separate.

`BoardRenderer` scales the logical image to available space with nearest filtering. Therefore a 20x20 source does not render as 20 physical pixels.

However high logical dimensions reduce physical cell size. Factory QA must estimate minimum cell display size on the supported viewport matrix.

Rules:

- do not reject a compact board for being compact;
- do not assume 59x59 is readable merely because renderer supports it;
- 49..59 content requires explicit phone-size readability evidence;
- bot/FX visuals must remain legible independently of logical cell count.

## 13. Challenge-profile diversity

Scalar targeting alone produces boring campaigns. Every accepted candidate gets a dominant-profile classification derived from `[W,C,A,U,B,R,S]`.

CampaignBuilder constraints should include:

- avoid same dominant profile more than two consecutive levels;
- avoid repeated high-W levels;
- do not place high-B/high-F levels back-to-back;
- use recovery levels with low B/U even if their artwork is visually rich;
- rotate route-, color-, frontier- and workload-led challenges.

## 14. Novelty signature

Suggested signature fields:

```text
artCategory
silhouetteHash / compact perceptual signature
dimensions
aspectBucket
paletteSet
paletteHistogram
challengeVector
dominantProfile
unlockWaveHistogram
frontierCurveSignature
routeMetricBucket
slotPressureBucket
generatorFamily
```

Similarity should combine multiple fields. One identical dimension or one repeated color is not enough to reject a candidate.

## 15. CampaignBuilder architecture

CampaignBuilder receives an accepted candidate pool and produces an ordered campaign.

For each level number `n`:

1. derive fixed cadence class;
2. compute `TargetChallenge(n)`;
3. derive slot-specific novelty/load/frustration budgets;
4. filter accepted candidates by hard eligibility;
5. rank by challenge error;
6. apply recent-similarity penalties;
7. apply challenge-vector diversity;
8. validate recovery constraints against previous chosen levels;
9. choose deterministically from the best admissible candidates;
10. record campaign-build provenance.

CampaignBuilder never changes the chosen level's cell data.

If no candidate satisfies a slot, the system requests more generation. It must not mislabel a bad-fit candidate just to fill a hole.

## 16. Pool strategy

Do not generate exactly one level per requested slot.

Maintain pools/buckets by broad challenge ranges and profiles. For campaign assembly, larger pools give the sequencer freedom to optimize variety.

Example production request:

```text
Need 100 accepted candidates
not 100 generation attempts
```

The Factory reports:

```text
generated
legality rejected
unsolvable
inconclusive
target misses
visual rejected
accepted pool
owner approved
exported
```

## 17. Bounded compute strategy

Generation must remain operationally usable.

Every request has:

- max candidate attempts;
- max mutation attempts;
- per-solve node budget;
- per-solve time budget;
- batch wall-clock budget;
- resumable checkpoint.

A failed batch is resumable and must preserve already accepted candidates.

## 18. Determinism & provenance

Required reproducibility tuple:

```text
generatorVersion
scoreModelVersion
solverVersion
progressionModelVersion
request config hash
root seed
candidate seed
mutation lineage
source art hash
```

Same deterministic generator version + request + seed must reproduce the same candidate data.

When a third-party visual model cannot guarantee byte-level deterministic output, store the actual returned source artifact hash and provider-generation metadata; reproducibility then means exact provenance and immutable source preservation, not pretending the provider is deterministic.

## 19. Factory editor

Human-in-the-loop Godot editor should expose:

- level number / cadence slot;
- target class and challenge score;
- challenge tolerance;
- session/frustration budgets;
- generation mode;
- dimensions guidance, never difficulty-imposed dimensions;
- seed/reproduce;
- generate N candidates;
- solve/analyze;
- seven-axis radar/table;
- unlock/frontier visualization;
- route overlays;
- rejection reasons;
- recent similarity;
- owner approval state;
- export.

Manual editing always invalidates prior solver/metrics and requires revalidation.

## 20. Testing strategy

### Property tests

- same seed/config reproducible;
- challenge score always 0..100;
- Session Load always 0..100;
- no accepted candidate violates hard legality;
- mutation always changes candidate ID/lineage;
- owner-original source hashes never change;
- campaign cadence exactly repeats every 10;
- target EASY at cycle 31 > target EASY at cycle 1;
- next-cycle EASY remains far below prior VERY_HARD;
- campaign builder never mutates level data.

### Golden fixtures

Create small deterministic fixtures that isolate each metric:

- same cells, different color entropy;
- same colors, different accessibility;
- same frontier, different unlock depth;
- same challenge, different workload;
- same challenge, different route detour;
- forced bottleneck vs broad-choice board.

### Adversarial tests

- unsolvable enclosed states;
- solver timeout/inconclusive;
- malformed metric outputs;
- NaN/INF metric input;
- repeated near-duplicate candidates;
- batch with no admissible candidate for slot;
- 59x59 performance ceiling;
- very small/large rectangular board;
- generated art with one off-palette pixel;
- semi-transparent pixel;
- stale analysis after manual edit.

## 21. Migration from current LF tasks

Existing LF00..LF10 remain useful, but their semantics change:

- LF01 dimension selection becomes a content/session-load choice, not difficulty-band selection.
- LF02 generation targets the full request envelope.
- LF03 solver becomes canonical Difficulty V1 measurement infrastructure.
- LF04 implements the seven-axis model + Session Load + Frustration Risk + novelty signature.
- LF05 validates new production legality instead of old dimension/color class bands.
- LF06 editor exposes target envelope and vector analysis.
- LF07 mutation targets score/load/risk/novelty jointly.
- LF08 batch production reports accepted counts and campaign-fit pools, not merely counts by old dimension class.
- LF09 telemetry calibration stays experimental/owner-gated.
- LF10 CampaignBuilder now has an owner-approved progression rhythm and is no longer waiting for M32 design invention; implementation still follows dependency/audit sequencing.

## 22. Implementation order

Recommended dependency order:

```text
A. Versioned progression/config contracts
B. Difficulty metric data model
C. Canonical pure simulation adapter
D. Oracle solver + diagnostics
E. W/C/A/U/B/R/S analyzers
F. Session Load
G. Human-policy ensemble + provisional Frustration Risk
H. Candidate acceptance evaluator
I. Deterministic generator primitives
J. Safe mutation engine
K. Novelty/signature system
L. Accepted candidate pool
M. CampaignBuilder
N. Factory editor
O. Batch production
P. Internal playtest calibration
Q. optional later telemetry calibration
```

Do not begin advanced evolutionary generation before A–O work reliably.

## 23. Definition of Factory success

The Level Factory is ready for scaled production only when it can demonstrate, with deterministic evidence:

- generate multiple legal candidates for a requested target;
- prove/reason about solvability without conflating timeout with failure;
- measure all enabled metrics;
- reject target misses;
- safely mutate generated candidates toward a target;
- preserve owner-original art;
- produce candidates with different challenge vectors at similar scalar scores;
- sequence the exact ten-level cadence;
- make a level-311 EASY harder than level-11 EASY while maintaining boss/recovery contrast;
- enforce Session Load / Frustration / novelty constraints;
- reproduce every accepted candidate from provenance;
- export only declarative production data through existing content QA gates.
