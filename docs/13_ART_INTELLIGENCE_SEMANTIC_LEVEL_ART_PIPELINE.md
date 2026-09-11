# 13 — Art Intelligence & Semantic Level-Art Pipeline V1

Status: **CANONICAL DESIGN DRAFT — 2026-09-12**

Related design:
- `coordination/OWNER_DIFFICULTY_PROGRESSION_DECISION_V01.md`
- `docs/09_DIFFICULTY_PROGRESSION_RETENTION_SYSTEM.md`
- `docs/10_LEVEL_FACTORY_GENERATION_SCORING_ARCHITECTURE.md`

## 1. Why this layer exists

SCRUBBOTS needs two different things from every production level:

1. a readable, attractive pixel-art image that a player can recognize without a metadata label;
2. a solvable puzzle whose measured Challenge / Session Load / Frustration envelope fits the campaign slot.

Those are related but different optimization problems. A procedural topology generator can produce connected regions, symmetry, corridors, bottlenecks and palette-valid geometry without producing recognizable subject matter. Therefore **semantic artwork generation is a separate first-class system**.

The Level Factory must not assume that structurally valid procedural geometry is acceptable visual art.

## 2. Evidence that structural generation alone is insufficient

A 100-candidate deterministic review corpus from the earlier Pixel Art Generator was reconstructed and reviewed on 2026-09-12. It contained:

- 25 EASY, 25 MEDIUM, 25 HARD, 25 VERY_HARD;
- 35 MASK candidates;
- 25 RULES candidates;
- 40 HYBRID candidates;
- 100 / 100 machine-accepted by structural quality gates;
- 0 / 100 owner-accepted as production semantic artwork.

The failure was not primarily palette legality, determinism, connectedness, symmetry or export correctness. The failure was **metadata-blind recognizability**. Labels such as ROBOT, FISH, SPACE_SHIP, SEA_CREATURE and ORGANIC were often not recoverable from the image itself.

This negative corpus is now treated as design evidence: low-level geometry metrics are necessary QA but are not semantic-art QA.

## 3. Architectural rule: AI creates meaning, deterministic systems enforce contracts

The recommended production split is:

```text
Campaign / subject intent
        ↓
Semantic Art Planner
        ↓
Semantic Source Adapter
  ┌───────────────┬───────────────────┐
  │ Native Pixel  │ Concept / Reference│
  │ AI            │ Image AI           │
  └───────┬───────┴─────────┬─────────┘
          ↓                 ↓
      exact pixels      Pixel Compiler
          └─────────┬───────┘
                    ↓
          Canonical Pixel Candidate
                    ↓
       Art Readability Analyzer
                    ↓
      Blind Semantic Recognition
                    ↓
      Human / Owner Review Gate
                    ↓
        Puzzle Simulator + Solver
                    ↓
Difficulty / Session / Frustration
                    ↓
         Acceptance Evaluator
```

AI is the semantic source, not the legal authority. Deterministic code owns palette legality, logical dimensions, topology repair, reproducibility metadata, QA, solver truth and export.

## 4. Semantic source adapters

### 4.1 NATIVE_PIXEL_AI — preferred when capable

A provider/model that can generate genuinely low-resolution pixel art at the requested logical resolution is preferred.

Request contract includes:
- intended subject;
- pose/view;
- exact or bounded logical dimensions;
- target silhouette complexity;
- number of major semantic parts;
- forbidden micro-detail;
- background policy;
- style reference identity;
- deterministic provider seed when supported;
- candidate count.

The returned candidate is never trusted directly. It passes:
- dimension validation;
- alpha validation;
- canonical-palette quantization;
- anti-alias / intermediate-color detection;
- topology cleanup;
- semantic recognition;
- gameplay analysis.

This path is especially important because owner examples demonstrate that recognizable subjects can exist even around 20×20 logical pixels when a semantic model creates the sprite rather than a geometry-only generator.

### 4.2 CONCEPT_IMAGE_AI + PIXEL_COMPILER — fallback / high-control path

When the semantic model is better at larger images, generate a simple flat concept at higher resolution and compile it to logical pixel art.

Do **not** perform ordinary photographic resize/downscale as the final method.

The Pixel Compiler performs:

1. foreground/background segmentation or alpha extraction;
2. crop and centering normalization;
3. semantic-part / color-region simplification;
4. silhouette coverage sampling;
5. signed-distance or coverage-aware logical-grid rasterization;
6. minimum-stroke / minimum-gap repair;
7. small disconnected-component removal when semantically safe;
8. hole preservation/repair;
9. canonical C01..C16 palette mapping;
10. adjacency-contrast optimization;
11. exact logical-grid export;
12. nearest-neighbor preview generation.

The compiler's job is to preserve identity while reducing information, not merely shrink pixels.

### 4.3 OWNER_ART

Owner-supplied original artwork remains immutable source truth. It may be validated, quantized only when explicitly authorized, or rejected for a campaign slot. It must never be silently repainted to force difficulty.

## 5. Semantic Art Planner

The planner chooses a subject and art envelope before generation.

Subject metadata example:

```text
subject_id: turtle
category: animal
preferred_view: side
min_logical_size: 24x24
preferred_logical_size: 28..34
silhouette_complexity: medium
symmetry: low
major_parts:
  - shell
  - head
  - four limbs
  - tail
forbidden:
  - 1-pixel whisker-like details
  - text
  - gradients
recognition_aliases:
  - turtle
  - tortoise
```

A Semantic Subject Catalog should contain categories such as animals, robots, vehicles, food, objects, fantasy, sea life and playful cleaning-world objects.

Subject selection is retention-aware. Consecutive levels should not repeatedly use the same category, silhouette family, pose or color composition.

## 6. Art Readability Score

Art QA is separate from Challenge Score.

V1 proposal:

```text
ArtReadability =
    0.24 * SilhouetteClarity
  + 0.18 * RegionCoherence
  + 0.15 * SemanticPartIntegrity
  + 0.12 * ColorSeparation
  + 0.10 * DetailDiscipline
  + 0.08 * NegativeSpaceQuality
  + 0.13 * BlindRecognitionConfidence
```

Every component is normalized 0..100 and versioned.

### 6.1 SilhouetteClarity

Measure:
- connected foreground identity;
- contour complexity relative to resolution;
- minimum limb/stroke thickness;
- accidental spikes;
- excessive holes;
- silhouette compactness;
- edge-noise density.

The key test: if the foreground is reduced to one color, does its outline still communicate a plausible intended subject?

### 6.2 RegionCoherence

Measure:
- connected-component counts per color;
- median semantic-region size;
- isolated single pixels;
- tiny 2–3 pixel islands;
- region fragmentation;
- whether adjacent colors form stable parts rather than confetti.

### 6.3 SemanticPartIntegrity

For subjects whose part model is known, verify approximate presence/placement relationships. Example: a side-view turtle should retain a shell-like main mass plus a distinct head and limb cues. The analyzer may use vision assistance but must retain explicit metrics and confidence.

### 6.4 ColorSeparation

Canonical palette membership is not enough. Adjacent semantic parts should have enough perceptual contrast to remain readable at actual mobile size.

### 6.5 DetailDiscipline

Reject over-detailed low-resolution candidates even if technically valid. Measure edge transitions, micro-regions, thin strokes and local color volatility relative to total occupied cells.

### 6.6 NegativeSpaceQuality

Holes/gaps should help identify parts instead of shredding the subject.

### 6.7 BlindRecognitionConfidence

A vision judge receives only a nearest-neighbor enlarged candidate, with candidate ID / generator family / subject label hidden.

Expected output:

```json
{
  "top_guesses": [
    {"label":"fire truck","confidence":0.88},
    {"label":"truck","confidence":0.08},
    {"label":"bus","confidence":0.02}
  ]
}
```

Acceptance compares those guesses with the hidden intended subject and approved aliases.

The judge must not see the generation prompt or intended label before inference. This is a deliberate anti-self-confirmation measure.

## 7. Mandatory metadata-blind semantic gate

A candidate cannot become production art merely because deterministic quality checks say ACCEPT.

Required states:

```text
STRUCTURAL_ACCEPT
SEMANTIC_PENDING
SEMANTIC_REJECT
SEMANTIC_ACCEPT
OWNER_REVIEW_PENDING
OWNER_ACCEPT
```

`STRUCTURAL_ACCEPT` is never equivalent to `SEMANTIC_ACCEPT`.

The 100-candidate negative corpus demonstrates why this separation is mandatory.

## 8. Multi-candidate generation instead of one-shot generation

For each requested campaign slot, request a bounded candidate batch, for example 8–24 semantic candidates depending on cost.

Then rank by:

```text
semantic recognizability
art readability
challenge target error
session-load target error
frustration risk
novelty
recent-level similarity
visual diversity
```

The system should expect rejection. A production generator is successful when it efficiently finds acceptable candidates, not when every raw generation survives.

## 9. Difficulty must not destroy artwork

The puzzle system measures artwork after semantic generation.

If a beautiful turtle measures Challenge 28 but the requested slot is HARD 63, do not carve random pockets or confetti into the turtle until it becomes HARD.

Allowed responses:
1. keep it for a more suitable campaign slot;
2. regenerate another semantic candidate under a different structural envelope;
3. apply only safe mutations proven not to harm recognizability;
4. reject it for this slot.

Owner-original artwork is never automatically mutated.

## 10. Safe semantic-preserving mutation classes

Possible safe mutation families, each re-running Art QA and solver QA:

- palette remapping among canonical colors while preserving perceptual contrast;
- broad semantic-region boundary adjustment by one logical cell;
- thicker/thinner major parts within subject constraints;
- controlled background-region restructuring;
- rotation/mirroring only when semantically legal;
- relocation of small non-identity details;
- color-region subdivision/merge when identity is preserved.

Unsafe by default:
- arbitrary random noise;
- random holes;
- random single-pixel islands;
- topology edits that remove defining parts;
- random color scattering to increase color count;
- silhouette shredding for difficulty.

## 11. Mobile-size readability contract

Review must happen at two scales:

1. enlarged nearest-neighbor inspection for pixel correctness;
2. actual target gameplay display size for human readability.

A sprite that looks attractive at 800% zoom but collapses on a phone is not accepted.

The preferred production art envelope should emphasize roughly 24–40 logical cells per axis for most content, while 20–23 remains available for deliberately simple silhouettes and engineering fixtures. Larger boards are not automatically better art and carry Session Load/readability costs.

## 12. Why the old procedural families still matter

MASK / RULES / HYBRID / WFC infrastructure should not be thrown away.

Repurpose it for:
- silhouette constraints;
- region cleanup;
- background topology;
- puzzle topology suggestions;
- palette-region propagation;
- semantic-preserving mutation;
- negative examples;
- diversity constraints;
- fallback technical fixtures;
- solver/QA stress generation.

It stops being the primary author of subject meaning.

## 13. Production acceptance order

A candidate must pass in this order:

```text
A. Source/provenance valid
B. Logical dimension/format legal
C. Canonical palette/alpha legal
D. Structural art QA
E. Blind semantic recognition
F. ArtReadability threshold
G. Human/owner visual gate where required
H. Canonical puzzle solvability
I. Challenge target window
J. Session Load window
K. Frustration cap
L. Novelty/recent-similarity gates
M. Mobile presentation/readability
N. Production export + immutable provenance
```

Visual identity is tested before expensive puzzle targeting where practical, so obvious visual failures are discarded early.

## 14. Negative-corpus regression

The rejected 100-candidate M10 corpus should be represented as a regression corpus when legally/operationally available to the Level Factory.

The semantic QA system should prove that the known rejected samples do **not** receive production semantic acceptance merely because they have high symmetry, connectedness or clean palette statistics.

At minimum, derived metric snapshots and representative non-sensitive fixtures should be retained so future coefficient changes cannot recreate the old false-positive behavior.

## 15. Success criteria for Art Intelligence V1

Before bulk content generation:

- semantic candidate source adapter implemented behind a provider-neutral interface;
- exact low-res/native-pixel path supported;
- Pixel Compiler fallback implemented;
- blind-recognition gate implemented;
- ArtReadability metrics versioned;
- known negative corpus rejected by semantic gate;
- positive owner-approved examples accepted;
- provider failure never bypasses semantic QA;
- reproducibility/provenance recorded;
- owner can review candidates without metadata labels;
- accepted artwork remains recognizable at actual gameplay scale;
- solver/difficulty systems consume artwork without being allowed to destroy semantic identity.
