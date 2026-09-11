# PixelLab Sprite Factory Engineering Findings V01

Date: 2026-09-12
Status: engineering evidence / design input
Source reviewed: user-provided `ScrubBots Sprite Factory v0.4.0` archive, including `app.py`, palette JSON, launch/build scripts, changelogs and sample manifests.
Scope: **PixelLab is evaluated only as an offline pixel-art generation provider. Puzzle construction, solvability, difficulty scoring, session load, campaign sequencing and gameplay logic are explicitly out of scope.**

## Owner scope correction

The owner clarified that PixelLab must be used only for **pixel-art creation**. It is not a puzzle generator and it must not be assigned responsibility for solvability, Challenge Score, Session Load, Frustration Risk, routing, slot pressure or campaign placement.

The provider boundary is therefore:

```text
semantic pixel-art request
    -> PixelLab adapter
    -> raw pixel-art candidate
    -> deterministic local pixel compiler
    -> structural + semantic art QA
    -> accepted semantic pixel-art asset
    -> STOP: PixelLab scope ends here
```

Any later conversion of accepted art into gameplay level data belongs to separate SCRUBBOTS systems and is not part of the PixelLab integration.

## Executive conclusion

The reviewed tool is strong evidence that a **pixel-art-specialized semantic model can generate recognizable subject matter directly at very low logical resolutions such as 20x20**, and that deterministic local processing can then force the output into SCRUBBOTS pixel-art constraints.

The most valuable architecture is:

```text
semantic prompt
  -> provider-native pixel generation
  -> deterministic local palette/alpha compiler
  -> pixel-art validation
  -> immutable accepted pixel-art candidate
```

This is the complete PixelLab responsibility boundary.

## What the reviewed tool does well

### F-PXL-001 — Native low-resolution semantic generation is viable

The tool routes the primary 20x20 use case to PixelLab Pixen and requests a native 20x20 image instead of first generating a high-resolution illustration.

The owner-approved examples produced through this path are much more semantically readable than the earlier geometry-only procedural corpus. Low resolution itself is therefore not the root cause of unreadable art. Semantic generation is the missing ingredient.

**Consequence:** prefer native logical-pixel generation when the provider/model can genuinely create recognizable pixel art at the requested resolution. High-resolution concept -> Pixel Compiler is fallback/high-control tooling, not the mandatory default.

### F-PXL-002 — Provider output is not trusted as palette truth

The tool attempts provider palette guidance where possible but still performs local deterministic C01..C16 locking afterward.

Correct trust boundary:

```text
PixelLab = semantic pixel-art author
local compiler = pixel legality authority
```

Provider palette compliance is guidance, never a production guarantee.

### F-PXL-003 — Binary alpha is normalized locally

The tool converts visible pixels to alpha 255 and pixels below a fixed threshold to alpha 0, then validates that no semi-alpha remains.

The exact threshold policy should become versioned, but the ownership rule is sound: final alpha legality is enforced locally and deterministically.

### F-PXL-004 — Existing outputs are revalidated before resume/skip

The resume path does not trust file existence alone. An existing PNG is skipped only if dimensions, canonical palette membership and alpha rules still pass.

Useful idempotency rule:

```text
existing artifact != valid artifact
```

The art generator should retain validation before cache reuse.

### F-PXL-005 — Quota exhaustion is workflow state, not art failure

HTTP 402 stops the batch and marks untouched work `PENDING` instead of misclassifying it as failed art.

Recommended provider-state vocabulary:

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
OWNER_REVIEW_PENDING
OWNER_ACCEPT
```

Provider/account constraints must never be confused with art-quality rejection.

### F-PXL-006 — Sequential generation is conservative

One-request-at-a-time generation avoids quota storms and simplifies resume behavior. Bounded concurrency may be added later, but only with explicit rate-limit and quota policy.

### F-PXL-007 — Prompt suffix is a strong reusable art constraint

The shared suffix asks for an isolated complete subject, centered composition, readable silhouette, clean pixel art, transparent background and no text/frame.

This should evolve into a structured `PixelArtRequest` prompt compiler rather than free-form prompt concatenation.

## Critical weaknesses that must NOT be copied into production

### F-PXL-101 — Random generations are not reproducible enough

When seed is `0`, provider randomness is used, but the current report does not preserve enough provenance to reproduce or trace an accepted image reliably.

Required art-candidate provenance:

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

If an effective seed cannot be recovered, immutable raw artifact retention becomes mandatory.

### F-PXL-102 — Raw AI source is discarded

The tool saves only the locally locked PNG. Production tooling must preserve two separate artifacts:

```text
raw/provider/<candidate>
compiled/pixel_art/<candidate>
```

This allows diagnosis of whether a defect came from generation, alpha compilation, resizing or palette mapping.

### F-PXL-103 — Current PASS means only pixel-structure legality

The validator checks exact size, no off-palette visible RGB and no semi-alpha. It does not prove that the image is recognizable or attractive.

Therefore current `PASS` should map conceptually to `STRUCTURAL_ACCEPT`, followed by separate semantic-art checks.

### F-PXL-104 — Small rectangular requests can distort the subject

For some sub-32 rectangular targets, `generate_auto()` may request a square Pixen canvas and `lock_sprite()` then resize that square to `(w,h)` using NEAREST. This is non-uniform scaling and can squash/stretch semantic identity.

Production pixel-art rule: **no anisotropic resize**.

Use one of:

1. provider-native matching aspect ratio;
2. transparent padding/letterboxing plus crop-safe compilation;
3. uniform scaling only;
4. reject unsupported exact-size requests.

### F-PXL-105 — Fixed alpha threshold can damage features

`alpha_threshold=96` is hard-coded. Alpha compilation should be versioned and tested for silhouette preservation, edge halos, minimum stroke and minimum gap.

### F-PXL-106 — RGB nearest-color mapping is deterministic but not perceptual

Euclidean sRGB distance can collapse visually meaningful parts. Production should use a versioned perceptual mapper such as OKLab/CIE-Lab and then verify local contrast/readability.

### F-PXL-107 — Filename is not candidate identity

Slugged `id + prompt` is convenient for a desktop prototype but should not be canonical identity. Use immutable candidate ID + request hash, with human prompt stored as metadata.

### F-PXL-108 — Report writes should be crash-safe

The CSV is rewritten directly after each item. Production art tooling should use atomic temp-write/replace or an append-only event journal with derived reports.

### F-PXL-109 — Retry policy should be provider-neutral

The targeted PixFlux retry is useful, but production needs normalized handling for 429, transient 5xx, network timeout and `Retry-After`, with bounded backoff and preserved attempt history.

### F-PXL-110 — Application version/provenance drift must be eliminated

Package/readme/app labels differ. Production art provenance needs a single machine-readable version source used by UI, reports, builds and candidate metadata.

## Strict PixelLab output contract

PixelLab integration may output only an **art candidate package**:

```text
candidate_id
subject_id / intended subject
prompt/request metadata
provider/model/version
seed/provenance
raw PNG
compiled PNG
logical width/height
palette/alpha validation
semantic/readability QA
hashes
status
```

It must not output or decide:

```text
LevelData difficulty
solvability
puzzle topology
Challenge Score
Session Load
Frustration Risk
slot behavior
routing
campaign level number
campaign acceptance
```

Those fields belong to other systems.

## Positive evidence status

The reviewed Sprite Factory is positive engineering evidence for:

- native low-resolution semantic pixel-art generation;
- deterministic local palette/alpha compilation;
- resumable quota-aware batches;
- prompt-grammar constraints;
- provider output validation.

The earlier 100-candidate procedural corpus remains negative evidence for geometry-only semantic generation.

The PixelLab lesson is intentionally narrow:

```text
PixelLab -> create recognizable pixel art
Local art compiler -> make those pixels legal and reproducible
Art QA -> decide whether the pixel art is visually acceptable
STOP
```
