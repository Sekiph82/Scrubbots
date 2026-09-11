# PixelLab Pixel-Art Provider Implementation Plan V01

Date: 2026-09-12
Status: planning / provider-integration roadmap
Scope: **pixel-art generation only**

Canonical design:
- `docs/14_NATIVE_PIXEL_AI_AND_BOARD_COMPOSER_ARCHITECTURE.md` (current content is Native Pixel AI Provider Architecture; historical filename retained)
- `coordination/PIXELLAB_SPRITE_FACTORY_ENGINEERING_FINDINGS_V01.md`

## Non-negotiable scope boundary

PixelLab integration is responsible only for creating and validating pixel-art candidates.

It must not implement, estimate or decide:

- puzzle solvability;
- difficulty;
- Challenge Score;
- Session Load;
- Frustration Risk;
- slot behavior;
- routing;
- gameplay topology;
- campaign ordering.

The handoff artifact is an `AcceptedPixelArtCandidate`.

## PXL-00 — Provider adapter foundation

- [ ] PXL-00-001 Define provider-neutral `NativePixelProvider` interface.
- [ ] PXL-00-002 Implement `PixelLabAdapter` behind that interface.
- [ ] PXL-00-003 Keep API token outside Git and logs.
- [ ] PXL-00-004 Normalize provider response/errors into typed results.
- [ ] PXL-00-005 Record provider/model/endpoint/version metadata.
- [ ] PXL-00-006 Add provider health/balance test without leaking secrets.

## PXL-01 — PixelArtRequest schema

- [ ] PXL-01-001 Define versioned request schema.
- [ ] PXL-01-002 Include subject ID and semantic prompt.
- [ ] PXL-01-003 Include exact logical width/height.
- [ ] PXL-01-004 Include view/pose/framing/background policy.
- [ ] PXL-01-005 Include silhouette and micro-detail guidance.
- [ ] PXL-01-006 Include requested seed and provider options.
- [ ] PXL-01-007 Compute deterministic normalized request hash.
- [ ] PXL-01-008 Explicitly reject puzzle/difficulty fields in this schema.

## PXL-02 — Prompt Compiler

- [ ] PXL-02-001 Replace one generic suffix with a versioned prompt compiler.
- [ ] PXL-02-002 Compile complete-subject and centered-composition constraints.
- [ ] PXL-02-003 Compile target logical-resolution awareness.
- [ ] PXL-02-004 Compile strong-silhouette guidance.
- [ ] PXL-02-005 Compile no-micro-detail guidance by resolution.
- [ ] PXL-02-006 Compile transparent-background policy.
- [ ] PXL-02-007 Compile no-text/no-frame/no-border policy.
- [ ] PXL-02-008 Preserve final normalized prompt in provenance.

## PXL-03 — Exact-size native generation

- [ ] PXL-03-001 Prefer Pixen/native low-resolution generation for supported small sizes.
- [ ] PXL-03-002 Prove direct 20x20 path.
- [ ] PXL-03-003 Test 24x24, 28x28, 32x32 and other supported square sizes.
- [ ] PXL-03-004 Inventory provider constraints for rectangular dimensions.
- [ ] PXL-03-005 Forbid non-uniform resize.
- [ ] PXL-03-006 Use same-aspect source, uniform scale or padding only when exact size is unsupported.
- [ ] PXL-03-007 Reject unsupported target geometry rather than distort the subject.
- [ ] PXL-03-008 Preserve raw provider dimensions.

## PXL-04 — Raw artifact preservation

- [ ] PXL-04-001 Save provider-native PNG before local modification.
- [ ] PXL-04-002 Save normalized provider response metadata without secrets.
- [ ] PXL-04-003 Record raw SHA-256.
- [ ] PXL-04-004 Record requested seed.
- [ ] PXL-04-005 Record effective seed when provider exposes it.
- [ ] PXL-04-006 Record provider job/request ID when available.
- [ ] PXL-04-007 Never overwrite raw source in-place.

## PXL-05 — Canonical Pixel Compiler

- [ ] PXL-05-001 Define compiler config/version schema.
- [ ] PXL-05-002 Implement versioned alpha compilation.
- [ ] PXL-05-003 Remove semi-alpha deterministically.
- [ ] PXL-05-004 Implement C01..C16 mapping.
- [ ] PXL-05-005 Replace simple sRGB Euclidean distance with tested perceptual color distance.
- [ ] PXL-05-006 Detect color collapse that destroys local part contrast.
- [ ] PXL-05-007 Preserve minimum important stroke/gap where possible.
- [ ] PXL-05-008 Guarantee no interpolation-created colors.
- [ ] PXL-05-009 Record compiled SHA-256.
- [ ] PXL-05-010 Prove identical raw artifact + config -> byte-identical compiled PNG.

## PXL-06 — Structural pixel-art QA

- [ ] PXL-06-001 Exact dimension validation.
- [ ] PXL-06-002 Palette membership validation.
- [ ] PXL-06-003 Binary alpha validation.
- [ ] PXL-06-004 PNG integrity validation.
- [ ] PXL-06-005 Detect excessive one-pixel fragments.
- [ ] PXL-06-006 Detect accidental frame/border/text-like structures where feasible.
- [ ] PXL-06-007 Output `STRUCTURAL_ACCEPT` only, never generic final `PASS`.

## PXL-07 — Semantic pixel-art QA

- [ ] PXL-07-001 Measure silhouette readability.
- [ ] PXL-07-002 Measure detail discipline for logical resolution.
- [ ] PXL-07-003 Measure color separation.
- [ ] PXL-07-004 Measure fragmentation/region coherence.
- [ ] PXL-07-005 Support metadata-blind vision recognition.
- [ ] PXL-07-006 Compare recognition only after judge inference.
- [ ] PXL-07-007 Add actual-display-size preview check.
- [ ] PXL-07-008 Output `SEMANTIC_ACCEPT` or `SEMANTIC_REJECT`.

## PXL-08 — Owner review workflow

- [ ] PXL-08-001 Show enlarged nearest-neighbor view.
- [ ] PXL-08-002 Show actual-size view.
- [ ] PXL-08-003 First-pass review hides intended subject label where useful.
- [ ] PXL-08-004 Record ACCEPT/REJECT and reason.
- [ ] PXL-08-005 Do not auto-promote an AI candidate merely because QA passes.
- [ ] PXL-08-006 Preserve rejected candidates for calibration when storage policy permits.

## PXL-09 — Batch/resume/quota reliability

- [ ] PXL-09-001 Retain sequential default mode initially.
- [ ] PXL-09-002 Add bounded concurrency only after rate-limit validation.
- [ ] PXL-09-003 Existing artifacts are reused only after validation.
- [ ] PXL-09-004 HTTP/account quota exhaustion -> `QUOTA_BLOCKED` and stop.
- [ ] PXL-09-005 Untouched work remains `PENDING`.
- [ ] PXL-09-006 Handle 429/Retry-After.
- [ ] PXL-09-007 Handle bounded retry for transient 5xx/network timeouts.
- [ ] PXL-09-008 Do not retry invalid-auth/request errors blindly.
- [ ] PXL-09-009 Preserve all attempt history.
- [ ] PXL-09-010 Make reports crash-safe/atomic.

## PXL-10 — Candidate storage and provenance

- [ ] PXL-10-001 Define immutable `candidate_id` independent of filename.
- [ ] PXL-10-002 Store request hash.
- [ ] PXL-10-003 Store raw and compiled hashes.
- [ ] PXL-10-004 Store prompt-template/compiler/palette versions.
- [ ] PXL-10-005 Store provider usage/cost metadata where available.
- [ ] PXL-10-006 Generate human-friendly filename only as presentation metadata.
- [ ] PXL-10-007 Provide machine-readable `provenance.json` per candidate.

## PXL-11 — Positive corpus and regression suite

- [ ] PXL-11-001 Materialize the owner-approved 20x20 examples as positive references where legally/operationally appropriate.
- [ ] PXL-11-002 Include the M21 Hazard Bot source lineage as one positive engineering case.
- [ ] PXL-11-003 Test compiler does not destroy recognizable silhouettes.
- [ ] PXL-11-004 Test repeated compile determinism.
- [ ] PXL-11-005 Test no anisotropic distortion on rectangular requests.
- [ ] PXL-11-006 Test quota/resume state transitions.
- [ ] PXL-11-007 Test corrupt cache regeneration.
- [ ] PXL-11-008 Track semantic accept rate by provider/model/compiler version.

## PXL-12 — Cost/quality experimentation

- [ ] PXL-12-001 Compare Pixen/native generation at 20/24/28/32 logical sizes.
- [ ] PXL-12-002 Compare candidate count vs owner acceptance rate.
- [ ] PXL-12-003 Compare seed strategies.
- [ ] PXL-12-004 Compare prompt-template variants.
- [ ] PXL-12-005 Compare palette guidance on/off while local compiler remains authority.
- [ ] PXL-12-006 Measure provider cost or generation allowance per accepted pixel-art asset.
- [ ] PXL-12-007 Never lower art-quality thresholds solely to save quota.

## PXL-13 — Export contract

The provider subsystem exports only:

```text
AcceptedPixelArtCandidate {
  candidate_id
  subject_id
  raw_png
  compiled_png
  dimensions
  palette/alpha QA
  semantic QA
  owner_review_status
  request/provenance metadata
  hashes
}
```

It exports no puzzle/difficulty/campaign fields.

## PXL-14 — Definition of done

PixelLab/native-provider V1 is complete only when:

- recognizable low-resolution art can be generated reliably;
- exact-size generation and rectangular behavior are proven;
- raw source is preserved;
- local compilation is deterministic;
- canonical palette/alpha rules are enforced;
- semantic readability is tested;
- owner review is supported;
- quota/resume/retry behavior is robust;
- full provenance exists;
- secrets are protected;
- the subsystem terminates at accepted pixel art and contains zero puzzle/solver/difficulty responsibility.

## Dependency sequence

```text
Provider interface
-> PixelArtRequest
-> Prompt Compiler
-> native exact-size generation
-> raw preservation
-> Canonical Pixel Compiler
-> structural QA
-> semantic QA
-> owner review
-> reliable batch/resume
-> provenance/cache
-> regression/cost calibration
-> AcceptedPixelArtCandidate export
```

## M21 protection

This plan does not expand active M21-C001. The existing owner-approved Hazard Bot remains the M21 real-art engineering fixture. PixelLab provider engineering is a separate future implementation stream.
