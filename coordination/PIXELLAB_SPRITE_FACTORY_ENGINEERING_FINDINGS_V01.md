# PixelLab Sprite Factory Engineering Findings V01

Date: 2026-09-12
Status: engineering evidence / design input
Source reviewed: `ScrubBots Sprite Factory v0.4.0` user-provided archive, including `app.py`, palette JSON, launch/build scripts, changelogs and sample manifests.
Scope: offline semantic-art production tooling only. This document does not change active M21 implementation scope.

## Executive conclusion

The reviewed tool is strong evidence that a **pixel-art-specialized semantic model can generate recognizable subject matter directly at very low logical resolutions such as 20x20**, and that a deterministic local compiler/validator can then force the output into SCRUBBOTS legal pixel constraints.

This materially strengthens the `NATIVE_PIXEL_AI` path in `docs/13_ART_INTELLIGENCE_SEMANTIC_LEVEL_ART_PIPELINE.md`.

The tool's most important architecture is not its GUI. It is this separation:

```text
semantic prompt
  -> provider-native pixel generation
  -> deterministic local palette/alpha compiler
  -> validation
  -> immutable accepted PNG
```

That split should survive into the production Level Factory, with stronger provenance, semantic QA and board composition.

## What the reviewed tool does well

### F-PXL-001 — Native low-resolution semantic generation is viable

The tool routes the primary 20x20 use case to PixelLab Pixen and requests a native 20x20 image instead of first generating a high-resolution illustration.

This matters because the owner-approved examples produced through this path are far more semantically readable than the 100-candidate geometry-only negative corpus. Low resolution itself is therefore not the root cause of unreadable content. The missing ingredient in the negative corpus was semantic generation.

**Project consequence:** Native logical-pixel generation becomes the preferred first source path when a provider/model can actually reason in pixel art at the requested resolution. Concept-image -> Pixel Compiler remains a fallback/high-control path, not the mandatory default.

### F-PXL-002 — Provider output is not trusted as palette truth

The tool attempts provider palette guidance where possible but still performs local deterministic C01..C16 locking afterward.

That is the right trust boundary:

```text
provider = semantic author
local compiler = legality authority
```

Provider palette compliance is a hint/optimization, never a production guarantee.

### F-PXL-003 — Binary alpha is normalized locally

The tool converts visible pixels to alpha 255 and pixels below a fixed threshold to alpha 0, then validates that no semi-alpha remains.

The exact threshold policy needs redesign for production, but the ownership rule is correct: final alpha legality is enforced locally and deterministically.

### F-PXL-004 — Existing outputs are revalidated before resume/skip

The v0.4 resume path does not blindly trust file existence. An existing PNG is skipped only if dimensions, canonical palette membership and alpha rules still pass.

This is a valuable idempotency rule for expensive generation:

```text
existing artifact != valid artifact
```

Level Factory should retain content-addressed validation before cache reuse.

### F-PXL-005 — Quota exhaustion is a workflow state, not mass failure

HTTP 402 stops the batch immediately and marks untouched work `PENDING` rather than incorrectly classifying every remaining request as failed.

This should become a provider-neutral state model:

```text
ACCEPTED
REJECTED
INFRA_FAILURE
QUOTA_BLOCKED
RATE_LIMITED
PENDING
```

Provider/account constraints must never be confused with art-quality rejection.

### F-PXL-006 — Sequential generation is conservative and reproducible-friendly

The tool generates one request at a time. It is not throughput-optimal, but for quota-limited semantic-art production it avoids accidental request storms and simplifies resume behavior.

Production may later use bounded concurrency, but only after explicit quota/rate-limit policy exists.

### F-PXL-007 — A strong generic prompt suffix helps semantic readability

The shared style instruction asks for an isolated complete subject, centered composition, readable silhouette, clean pixel art, transparent background, and no text/frame.

This is a useful prompt-grammar lesson. SemanticSubjectCatalog entries should compile into structured prompts that explicitly constrain silhouette, framing, micro-detail and background behavior.

## Critical weaknesses that must NOT be copied into production

### F-PXL-101 — Random generations are not reproducible

When seed is `0`, the provider chooses randomness. The tool does not record the actual effective seed returned/used by the provider, and the CSV report does not record a request hash or provider job identity.

Therefore an accepted random sprite may be impossible to reproduce exactly.

**Required production fix:** Every source candidate must store:

- normalized request JSON/hash;
- provider ID;
- endpoint/model/version;
- requested seed;
- effective/returned seed when available;
- provider job/request ID when available;
- generation timestamp;
- raw source artifact SHA-256;
- compiled artifact SHA-256;
- compiler version;
- palette version.

If a provider cannot expose an effective random seed, the raw source artifact becomes mandatory immutable provenance.

### F-PXL-102 — Raw AI source is discarded

The reviewed tool saves only the locally locked final PNG. It does not preserve the provider-native image separately.

This prevents later diagnosis of whether a defect came from:

- semantic generation;
- alpha thresholding;
- resizing;
- palette quantization;
- local compilation.

**Required production fix:** Preserve `raw/provider/` and `compiled/candidate/` as distinct immutable artifacts.

### F-PXL-103 — PASS only means structural legality

The validator checks:

- exact size;
- no off-palette visible RGB;
- no semi-alpha.

It does not ask whether the sprite is recognizable, attractive, fragmented, over-detailed, compositionally balanced or suitable for a level.

This is the same category error exposed by the 100-candidate negative corpus.

**Required production fix:** Structural PASS must transition to `SEMANTIC_PENDING`, never directly to production acceptance. ArtReadability + blind recognition + human/owner review remain separate gates.

### F-PXL-104 — Small rectangular requests can be geometrically distorted

`generate_auto()` routes sub-32 dimensions through a square Pixen canvas in some cases, then `lock_sprite()` resizes that square output to the requested `(w,h)` with NEAREST.

For a non-square target such as 20x24 or 20x28, this can stretch/squash the subject non-uniformly.

Even the PixFlux fallback can request a 32x32 minimum and then resize to a rectangular final target.

**Required production fix:** Never use anisotropic resize as a semantic compiler step. Use one of:

1. native provider aspect ratio matching the requested logical aspect;
2. padded/letterboxed source + crop/coverage-aware rasterization;
3. provider-supported nearest aspect ratio plus explicit non-distorting Pixel Compiler;
4. reject unsupported exact-size requests and choose another provider/path.

### F-PXL-105 — Fixed alpha threshold can erase or thicken semantic features

`alpha_threshold=96` is hard-coded. This may remove faint edge pixels or retain background-removal halos depending on provider output.

**Required production fix:** Alpha compilation must be versioned and inspect topology. Candidate-specific thresholding or mask cleanup may be used, but must preserve silhouette and pass min-stroke/min-gap metrics. Raw source is retained for audit.

### F-PXL-106 — RGB nearest-color quantization is not perceptual

The tool selects the nearest canonical color using Euclidean distance in sRGB RGB space.

This is deterministic, but perceptually weak and can collapse distinct semantic parts into colors that are numerically close but visually poor.

**Required production fix:** Use a versioned perceptual mapper such as OKLab/CIE-Lab distance, then run adjacency-contrast and semantic-region preservation checks. Canonical palette legality remains C01..C16.

### F-PXL-107 — Output identity depends on prompt text filename

The filename includes slugged `id + prompt`. Small prompt edits produce a new filename even when they represent the same logical request, while collisions/truncation are possible.

**Required production fix:** Candidate identity must be content/request based, e.g. immutable `candidate_id` + request hash. Display prompt is metadata, not identity.

### F-PXL-108 — Report writes are not atomic

`generation_report.csv` is rewritten after each item directly at the final path. A process/storage interruption can leave a partially written report.

**Required production fix:** write temporary file -> fsync where practical -> atomic replace, or use an append-only event journal plus derived report.

### F-PXL-109 — Retry policy is endpoint-specific and incomplete

The tool has one useful targeted retry: PixFlux HTTP 500 with forced palette retries once without palette guidance. But it lacks a general provider-neutral strategy for 429/529/transient 5xx/network timeout/backoff/Retry-After.

**Required production fix:** Normalize errors into retry classes with bounded exponential backoff + jitter; never retry semantic/validation 4xx blindly; preserve attempt history.

### F-PXL-110 — Version/provenance labels drift

The reviewed package is v0.4.0 / README v0.4.0.2, while `APP_NAME` and PyInstaller spec still identify v0.2.

This is harmless for a personal prototype but unacceptable for production candidate provenance.

**Required production fix:** one machine-readable application/compiler version source used by UI, report, build metadata and artifact provenance.

## The most important SCRUBBOTS-specific design lesson: sprite source != level board

The tool correctly requests transparent isolated sprites. That is ideal for semantic generation and recognition, but SCRUBBOTS gameplay LevelData starts with every logical artwork cell ACTIVE/opaque.

Therefore production needs a distinct **Board Composer** stage:

```text
transparent semantic sprite source
        -> preserve immutable source
        -> choose board envelope/background composition
        -> place sprite without distortion
        -> create fully opaque canonical logical board
        -> run ArtReadability again at board scale
        -> run puzzle solver/difficulty analysis
```

Do not simply flatten every transparent pixel to one arbitrary fill color as the universal production method. That is acceptable for an engineering fixture such as the M21 Hazard Bot, but bulk content should be composition-aware because the background/fill regions materially affect Challenge, Session Load, color distribution and visual quality.

Possible Board Composer policies:

- flat canonical backdrop for deliberately icon-like levels;
- simple semantic background bands/shapes;
- complementary negative-space composition;
- puzzle-aware but semantic-preserving background topology;
- explicit border/margin policies.

The original transparent sprite remains the semantic source artifact; the opaque board is a derived gameplay artifact.

## Provider-neutral PixelLab lesson

PixelLab is useful empirical evidence and a strong candidate provider, but it must remain behind `SemanticSourceProvider`.

Current PixelLab documentation checked on 2026-09-12 still exposes native pixel-art image generation, seeds, transparent backgrounds, style/palette guidance and dedicated pixel-art tooling. The production architecture must nevertheless avoid making PixelLab account availability, free-tier quotas or endpoint quirks part of gameplay truth.

Recommended adapter boundary:

```text
SemanticArtRequest
  -> PixelLabAdapter / future provider adapter
  -> RawSemanticArtifact
  -> CanonicalPixelCompiler
  -> SemanticCandidate
```

## Recommended production-state machine

```text
PLANNED
REQUESTED
PROVIDER_RUNNING
RAW_RECEIVED
COMPILE_FAILED | COMPILED
STRUCTURAL_REJECT | STRUCTURAL_ACCEPT
SEMANTIC_REJECT | SEMANTIC_ACCEPT
OWNER_REVIEW_PENDING
OWNER_ACCEPT
BOARD_COMPOSED
PUZZLE_REJECT | PUZZLE_ACCEPT
CAMPAIGN_POOL
PRODUCTION_EXPORTED
```

Infrastructure states (`QUOTA_BLOCKED`, `RATE_LIMITED`, `TRANSIENT_FAILURE`) are orthogonal and never count as semantic rejection.

## Positive evidence status

The reviewed tool is now treated as **positive engineering evidence** for native-low-resolution AI art generation and deterministic legality compilation.

The earlier 100-candidate procedural corpus remains **negative semantic evidence** for geometry-only generation.

Together they imply the production split:

```text
AI / semantic pixel model -> meaning
Deterministic compiler     -> legal pixels
Art Intelligence           -> readable identity
Puzzle Intelligence        -> solvability/difficulty
Campaign Intelligence      -> retention/sequencing
```
