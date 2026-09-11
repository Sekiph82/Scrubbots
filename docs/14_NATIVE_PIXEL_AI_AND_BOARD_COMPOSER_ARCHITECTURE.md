# 14 — Native Pixel AI Provider Architecture V1

Status: **CANONICAL DESIGN DRAFT — 2026-09-12**

> Historical filename note: this file was initially created with `BOARD_COMPOSER` in the filename. Owner correction on 2026-09-12 narrowed the provider scope. The current content is authoritative: **PixelLab/native Pixel AI is an art-generation subsystem only.** Board composition, puzzle construction, solver/difficulty analysis and campaign sequencing are separate systems and are not implemented by this provider layer.

Evidence:
- `coordination/PIXELLAB_SPRITE_FACTORY_ENGINEERING_FINDINGS_V01.md`
- `coordination/ART_INTELLIGENCE_NEGATIVE_CORPUS_FINDINGS_V01.md`

Related:
- `docs/13_ART_INTELLIGENCE_SEMANTIC_LEVEL_ART_PIPELINE.md`

## 1. Purpose

Generate recognizable SCRUBBOTS-compatible pixel-art candidates using a pixel-art-specialized AI provider, then compile and validate those images locally.

The subsystem ends when an art candidate is accepted visually and structurally.

It does **not** know or decide:

- puzzle solvability;
- puzzle topology;
- Challenge Score;
- Session Load;
- Frustration Risk;
- slots/routing;
- campaign sequence;
- level-number placement.

## 2. Preferred path: native low-resolution semantic pixel generation

When a provider can create recognizable pixel art directly at the requested logical resolution, use that path first.

```text
PixelArtRequest
    ↓
PixelLabAdapter / other NativePixelProvider
    ↓
RawPixelArtArtifact
    ↓
CanonicalPixelCompiler
    ↓
StructuralArtQA
    ↓
SemanticArtQA
    ↓
AcceptedPixelArtCandidate
    ↓
STOP: provider/art-generation scope complete
```

A later SCRUBBOTS content pipeline may consume the accepted art, but that is a separate contract.

## 3. PixelArtRequest contract

Required fields:

```text
request_id
candidate_batch_id
subject_id
subject_prompt
logical_width
logical_height
view / direction
background_policy
silhouette_guidance
micro_detail_policy
style_reference_ids
palette_guidance_version
requested_seed
provider_options
prompt_template_version
```

The request must express **visual intent**, not puzzle intent.

Forbidden request concepts include:

```text
make this HARD
make this solvable
increase unlock depth
increase bottleneck pressure
fit level 310
```

Those are not image-provider concerns.

## 4. RawPixelArtArtifact contract

Preserve the provider-native response unchanged.

Required provenance:

```text
candidate_id
provider_id
endpoint/model/version
provider_job_id if available
requested_seed
effective_seed if available
normalized_request_hash
raw_artifact_sha256
created_at
provider usage/cost metadata
raw width/height
```

If exact generation cannot be reproduced from seed, the raw artifact is mandatory immutable evidence.

## 5. Native exact-size rule

Preferred order:

1. request the exact logical width/height when supported;
2. otherwise request a source with the same aspect ratio;
3. preserve raw response;
4. never anisotropically stretch a square source into a rectangular target;
5. use uniform scaling/padding/crop-safe compilation only when explicitly supported by the compiler;
6. reject unsupported geometry rather than silently distort identity.

## 6. Canonical Pixel Compiler

The compiler owns pixel legality, not subject meaning.

Responsibilities:

- exact final logical dimensions;
- binary alpha policy;
- C01..C16 palette mapping;
- no unintended interpolation;
- perceptual palette mapping rather than naive RGB-only distance;
- local contrast checks;
- minimum-stroke/minimum-gap preservation;
- tiny-component diagnostics/repair only when identity is preserved;
- deterministic byte-identical output for identical raw artifact + compiler config;
- compiler version and compiled SHA-256.

The compiler must never overwrite the raw provider artifact.

## 7. Transparent sprite policy

Transparent isolated subjects are valid and often preferred **art-generation outputs** because they make silhouettes and semantics easier to judge.

This art subsystem does not decide how transparent pixels later become gameplay content. It simply records them accurately.

Output may therefore be:

```text
transparent semantic sprite
```

without making any claim that transparency means `CLEARED`, background, or playable board state.

Those semantics belong downstream.

## 8. Structural art validation

`STRUCTURAL_ACCEPT` may check:

- final logical size;
- allowed palette colors;
- binary alpha;
- no unintended interpolation;
- no corrupt PNG;
- no forbidden text/frame where requested;
- basic fragmentation/min-stroke diagnostics.

`STRUCTURAL_ACCEPT` is not final art acceptance.

## 9. Semantic art validation

After structural validation, evaluate:

- recognizable subject;
- silhouette readability;
- major-part integrity;
- visual balance;
- detail discipline;
- color separation;
- actual-size readability;
- optional blind vision recognition;
- owner/human review when required.

Possible states:

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

No puzzle-related state exists in this provider subsystem.

## 10. Prompt compiler

Do not depend on unstructured free-form prompts alone.

A `PixelArtPromptCompiler` should combine:

```text
subject phrase
view/pose
complete-subject requirement
centering/framing
silhouette requirement
logical-size awareness
micro-detail restrictions
transparent-background request
no text / no frame / no border
style references if any
```

Example:

```text
cute compact cleaning robot with hazard stripes,
three-quarter front view,
single isolated complete subject fully visible,
strong readable silhouette at 20x20 logical pixels,
large major features, no tiny decorative details,
clean pixel art, transparent background,
no text, no lettering, no border, no frame
```

## 11. Batch generation

Retain the strongest ideas from the reviewed desktop tool:

- sequential or bounded-concurrency requests;
- explicit quota stop;
- untouched remainder stays `PENDING`;
- resume from missing/invalid candidates;
- revalidate cache before reuse;
- do not confuse provider failure with art rejection;
- preserve per-attempt history.

## 12. Candidate identity and storage

Use immutable IDs/hashes, not prompt-derived filenames as truth.

Recommended layout conceptually:

```text
art_candidates/
  <candidate_id>/
    request.json
    provider_response.json
    raw.png
    compiled.png
    qa.json
    provenance.json
```

Recommended identity fields:

```text
candidate_id
request_hash
raw_sha256
compiler_config_hash
compiled_sha256
```

## 13. Provider-neutral adapter

PixelLab is a strong provider candidate and positive engineering evidence, but the interface stays generic:

```text
NativePixelProvider
    ├── PixelLabAdapter
    └── FutureProviderAdapter
```

Provider changes must not alter candidate data contracts or local art QA.

## 14. Explicit downstream boundary

An `AcceptedPixelArtCandidate` may later be consumed by another SCRUBBOTS system.

That downstream system may decide to:

- place it in a larger composition;
- convert it into LevelData;
- analyze gameplay;
- reject/resequence it;
- use it as a UI/game asset.

None of those operations belong to PixelLab or the Native Pixel AI provider layer.

The integration contract is simply:

```text
PixelLab/native AI work ends at accepted pixel art.
```

## 15. Success criteria

Before calling the PixelLab/native-provider subsystem production-ready:

- exact-size 20x20 generation works without forced high-resolution detour;
- supported rectangular generation never distorts aspect ratio;
- raw provider artifact is retained;
- deterministic local compilation exists;
- C01..C16 and alpha checks are versioned;
- perceptual color mapping is tested;
- prompt compiler is versioned;
- semantic recognizability gate exists;
- owner review workflow exists;
- quota/resume behavior is crash-safe;
- candidate provenance is complete;
- secrets never enter Git/artifact metadata;
- no puzzle, solver or difficulty responsibility leaks into the provider subsystem.
