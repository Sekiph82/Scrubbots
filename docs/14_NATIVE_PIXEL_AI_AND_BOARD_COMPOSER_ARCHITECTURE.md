# 14 — Native Pixel AI & Board Composer Architecture V1

Status: **CANONICAL DESIGN DRAFT — 2026-09-12**

Evidence:
- `coordination/PIXELLAB_SPRITE_FACTORY_ENGINEERING_FINDINGS_V01.md`
- `coordination/ART_INTELLIGENCE_NEGATIVE_CORPUS_FINDINGS_V01.md`

Related:
- `docs/13_ART_INTELLIGENCE_SEMANTIC_LEVEL_ART_PIPELINE.md`
- `docs/10_LEVEL_FACTORY_GENERATION_SCORING_ARCHITECTURE.md`

## 1. Design correction

SCRUBBOTS should prefer **native low-resolution semantic pixel generation** when a provider can generate recognizable pixel art directly at the requested logical scale.

High-resolution concept -> Pixel Compiler remains a fallback/high-control path, not a mandatory first stage.

The reviewed Sprite Factory proves the useful pattern:

```text
semantic prompt
 -> native pixel-art model
 -> raw transparent sprite
 -> deterministic canonical compiler
 -> semantic QA
```

## 2. Provider-neutral source contract

Every provider adapter receives a `SemanticArtRequest` and returns a `RawSemanticArtifact`.

Required request fields:

```text
request_id
subject_id
subject_prompt
logical_width / logical_height or bounded envelope
view / direction
background_policy
silhouette guidance
micro-detail policy
style_reference_ids
palette_guidance_version
requested_seed
provider_options
```

Required raw-artifact provenance:

```text
provider_id
endpoint/model/version
provider_job_id if available
requested_seed
effective_seed if available
normalized_request_hash
raw_artifact_sha256
created_at
provider_usage/cost metadata
```

If exact reproduction cannot be guaranteed, the raw artifact itself is immutable required evidence.

## 3. Native exact-size path

Preferred order:

1. ask provider for the requested logical aspect ratio and size directly;
2. preserve the raw response unchanged;
3. compile alpha and canonical palette locally;
4. reject unsupported dimensions instead of stretching the image;
5. run semantic QA.

**Forbidden:** generating a square source and anisotropically resizing it to a rectangular logical target.

## 4. Canonical Pixel Compiler

The compiler owns production legality, not semantic meaning.

Responsibilities:

- exact logical dimensions;
- no interpolation in direct native path;
- versioned alpha-mask compilation;
- C01..C16 mapping;
- perceptual palette distance rather than naive sRGB-only distance;
- semantic-region adjacency contrast checks;
- min-stroke/min-gap preservation;
- tiny-component diagnostics/repair when semantically safe;
- deterministic byte-identical output for identical raw input + compiler config;
- compiled artifact SHA-256.

The compiler must never overwrite the provider-native source artifact.

## 5. Semantic sprite and gameplay board are different artifacts

AI semantic generation should usually create an **isolated transparent subject** because this maximizes recognizability and allows clean semantic review.

SCRUBBOTS LevelData, however, requires a fully opaque ACTIVE logical board at level start.

Therefore add an explicit `BoardComposer`:

```text
RawSemanticArtifact
 -> Canonical transparent sprite
 -> ArtReadability / blind semantic acceptance
 -> BoardComposer
 -> opaque canonical board candidate
 -> board-scale ArtReadability
 -> puzzle solver/difficulty analysis
```

Never silently reinterpret transparent background pixels as gameplay CLEARED cells.

## 6. BoardComposer responsibilities

Input:

```text
canonical transparent sprite
requested board envelope
campaign visual-retention context
canonical palette
composition policy
```

Output:

```text
fully opaque canonical board
placement transform (translation only unless an explicitly safe uniform scale step exists)
background-region metadata
composition provenance
```

Rules:

- no non-uniform stretching;
- subject remains recognizable at actual gameplay size;
- preserve source aspect ratio;
- subject scale/position has explicit bounds;
- background may not create excessive monochrome workload by accident;
- background topology enters puzzle metrics normally;
- composed board is re-evaluated by Art Intelligence and Puzzle Intelligence.

## 7. Composition policy families

Initial policies may include:

### ICON_FLAT

Simple canonical background behind a strong icon-like subject. Good for compact early/recovery content.

### SOFT_GEOMETRIC

A few broad canonical-color regions that frame the subject without becoming visual confetti.

### SEMANTIC_CONTEXT

Minimal contextual shapes related to the subject, e.g. simple water/sky bands for a boat, while remaining low-detail and puzzle-safe.

### PUZZLE_AWARE_BACKGROUND

Background topology is selected from safe templates to help target Challenge / Session Load, but it may not obscure or deform the subject.

Every policy is versioned and regression-tested.

## 8. Candidate identity and cache

Do not identify artifacts by prompt-derived filenames.

Use:

```text
candidate_id
normalized_request_hash
raw_sha256
compiler_config_hash
compiled_sha256
board_composer_config_hash
board_sha256
```

A cached artifact is reused only after current validation succeeds.

## 9. Error/state model

Semantic/art-quality failures are distinct from provider infrastructure failures.

```text
PENDING
PROVIDER_RUNNING
QUOTA_BLOCKED
RATE_LIMITED
TRANSIENT_FAILURE
RAW_RECEIVED
COMPILE_REJECT
STRUCTURAL_ACCEPT
SEMANTIC_REJECT
SEMANTIC_ACCEPT
BOARD_COMPOSED
PUZZLE_REJECT
CAMPAIGN_ACCEPT
```

`QUOTA_BLOCKED` must never become `SEMANTIC_REJECT`.

## 10. Retry/budget behavior

Provider adapters implement bounded retry policy:

- honor Retry-After where supplied;
- bounded exponential backoff + jitter for transient 429/529/5xx/network failures;
- no blind retry for authentication, quota or semantic request validation errors;
- stop the batch when account quota is exhausted;
- preserve pending work without charging it as failure;
- record every attempt.

## 11. Positive/negative evidence pair

Two datasets now guide architecture:

1. **negative:** geometry-only 100-candidate corpus that is structurally clean but semantically unreadable;
2. **positive:** native 20x20 semantic PixelLab-generated sprite examples that remain recognizable after deterministic C01..C16 compilation.

The production system must preserve the strengths of both:

- deterministic structural rigor from the procedural toolchain;
- semantic subject intelligence from the native pixel-art model.

Neither replaces the other.
