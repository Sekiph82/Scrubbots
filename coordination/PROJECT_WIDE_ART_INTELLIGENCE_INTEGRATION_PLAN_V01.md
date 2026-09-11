# Project-Wide Art Intelligence Integration Plan V01

Date: 2026-09-12
Status: planning / implementation sequencing. Does not replace active M21 scope.

Canonical design:
- `docs/13_ART_INTELLIGENCE_SEMANTIC_LEVEL_ART_PIPELINE.md`
- `data/config/art_readability_model_v1.json`
- `coordination/ART_INTELLIGENCE_NEGATIVE_CORPUS_FINDINGS_V01.md`

## Goal

Make production level generation capable of yielding recognizable, attractive, metadata-blind-readable pixel art while preserving deterministic legality, puzzle solvability, Difficulty V1 targeting, retention rules, provenance and owner review.

## Critical architecture principle

Semantic image creation and puzzle difficulty targeting are separate stages with a feedback loop. Neither stage may silently corrupt the other's contract.

## AI-00 — Governance and evidence

- [ ] AI-00-001 Record semantic-art recognizability as a production requirement.
- [ ] AI-00-002 Record the 100-candidate procedural corpus as negative regression evidence.
- [ ] AI-00-003 Define provider-neutral interfaces; no provider is gameplay/runtime truth.
- [ ] AI-00-004 Ensure all semantic generation remains offline/content-production tooling; generated levels remain declarative runtime data.
- [ ] AI-00-005 Define cost/budget telemetry per candidate batch.

## AI-01 — Semantic Subject Catalog

- [ ] AI-01-001 Define versioned subject schema.
- [ ] AI-01-002 Add category, aliases, recommended logical size, view/pose, silhouette complexity and semantic parts.
- [ ] AI-01-003 Add forbidden micro-features and minimum-stroke guidance.
- [ ] AI-01-004 Add visual/subject cooldown metadata for campaign diversity.
- [ ] AI-01-005 Build an initial owner-approved subject library.
- [ ] AI-01-006 Add validation for duplicate aliases and incompatible constraints.

## AI-02 — Semantic Art Planner

- [ ] AI-02-001 Consume campaign level number/class and recent visual history.
- [ ] AI-02-002 Choose subject category with retention/novelty policy.
- [ ] AI-02-003 Choose logical art envelope independently from player-facing difficulty class.
- [ ] AI-02-004 Produce an immutable SemanticArtRequest.
- [ ] AI-02-005 Record planner version and deterministic selection seed where applicable.

## AI-03 — Provider-neutral SemanticSource interface

- [ ] AI-03-001 Define `NATIVE_PIXEL_AI` adapter contract.
- [ ] AI-03-002 Define `CONCEPT_IMAGE_AI` adapter contract.
- [ ] AI-03-003 Define `OWNER_ART` adapter contract.
- [ ] AI-03-004 Normalize provider errors/timeouts/safety refusals without accepting fallback garbage.
- [ ] AI-03-005 Store provider/model/version/seed/request hash and source artifact hash.
- [ ] AI-03-006 Prevent secrets/API keys from entering Git or exported level content.

## AI-04 — Native logical-pixel source path

- [ ] AI-04-001 Request exact/bounded logical dimensions from capable semantic pixel provider.
- [ ] AI-04-002 Validate exact dimensions and alpha.
- [ ] AI-04-003 Detect intermediate/off-palette colors.
- [ ] AI-04-004 Quantize only through deterministic canonical palette mapper.
- [ ] AI-04-005 Preserve provider source separately from compiled production candidate.
- [ ] AI-04-006 Produce crisp nearest-neighbor review output.

## AI-05 — Pixel Compiler fallback

- [ ] AI-05-001 Implement source segmentation/alpha extraction.
- [ ] AI-05-002 Implement crop/center normalization.
- [ ] AI-05-003 Implement coverage/signed-distance-aware silhouette rasterization.
- [ ] AI-05-004 Implement semantic-region simplification.
- [ ] AI-05-005 Implement min-stroke/min-gap topology repair.
- [ ] AI-05-006 Implement safe tiny-component cleanup.
- [ ] AI-05-007 Implement canonical C01..C16 quantization.
- [ ] AI-05-008 Implement perceptual adjacency-contrast optimization.
- [ ] AI-05-009 Test that repeated compile of identical input is byte-identical.
- [ ] AI-05-010 Build golden fixtures for 20/24/28/32/36/40 logical sizes.

## AI-06 — Structural Art Analyzer

- [ ] AI-06-001 SilhouetteClarity metrics.
- [ ] AI-06-002 RegionCoherence metrics.
- [ ] AI-06-003 ColorSeparation metrics.
- [ ] AI-06-004 DetailDiscipline metrics.
- [ ] AI-06-005 NegativeSpaceQuality metrics.
- [ ] AI-06-006 SemanticPartIntegrity adapter.
- [ ] AI-06-007 Version all metric formulas and output provenance.

## AI-07 — Metadata-blind Semantic Judge

- [ ] AI-07-001 Produce nearest-neighbor judge image without labels/IDs.
- [ ] AI-07-002 Define vision-judge provider interface independent of source generator.
- [ ] AI-07-003 Never expose intended subject/prompt before first-pass recognition.
- [ ] AI-07-004 Collect top-N guesses + confidence.
- [ ] AI-07-005 Compare against subject aliases only after inference.
- [ ] AI-07-006 Add anti-leak tests ensuring filenames/metadata cannot reveal target.
- [ ] AI-07-007 Distinguish judge unavailable from semantic PASS.
- [ ] AI-07-008 Support a second independent judge or human adjudication for borderline cases.

## AI-08 — ArtReadability evaluator

- [ ] AI-08-001 Implement `art_readability_model_v1.json` parser.
- [ ] AI-08-002 Compute weighted score from versioned metrics.
- [ ] AI-08-003 Enforce blind-recognition floor independently of weighted total.
- [ ] AI-08-004 Emit actionable failure codes.
- [ ] AI-08-005 No semantic acceptance from structural metrics alone.

## AI-09 — Negative and positive calibration corpora

- [ ] AI-09-001 Materialize representative legally usable negative fixtures from the rejected M10 corpus or derived equivalents.
- [ ] AI-09-002 Ensure known semantic failures stay rejected across coefficient changes.
- [ ] AI-09-003 Build positive corpus from owner-approved semantic sprites/levels.
- [ ] AI-09-004 Require positive examples to pass at actual mobile presentation size.
- [ ] AI-09-005 Track false-positive and false-negative rates by ArtReadability model version.

## AI-10 — Human review console

- [ ] AI-10-001 Show candidates without intended subject labels for first-pass review.
- [ ] AI-10-002 Reveal intended subject only after owner/human guess/decision.
- [ ] AI-10-003 Show enlarged pixel view and target-gameplay-size view side by side.
- [ ] AI-10-004 Record ACCEPT/REJECT plus reason codes.
- [ ] AI-10-005 Never promote source/generated raw candidate automatically.

## AI-11 — Puzzle integration

- [ ] AI-11-001 Convert semantic artwork to canonical LevelData candidate without changing identity.
- [ ] AI-11-002 Run canonical simulator/solver.
- [ ] AI-11-003 Run Challenge / Session Load / Frustration analysis.
- [ ] AI-11-004 If target miss, prefer resequencing/regeneration over destructive artwork mutation.
- [ ] AI-11-005 Define only safe semantic-preserving mutation classes.
- [ ] AI-11-006 Re-run ArtReadability after every art-affecting mutation.

## AI-12 — Multi-objective candidate search

- [ ] AI-12-001 Generate bounded semantic candidate batches (initially 8–24).
- [ ] AI-12-002 Rank using semantic + puzzle + retention objective vector.
- [ ] AI-12-003 Bound provider cost, candidate count, mutation count and wall-clock time.
- [ ] AI-12-004 Preserve every rejection reason and lineage.
- [ ] AI-12-005 Distinguish no-good-candidate from infrastructure failure.

## AI-13 — Campaign visual retention

- [ ] AI-13-001 Add recent subject/category history to CampaignBuilder.
- [ ] AI-13-002 Add silhouette-family cooldown.
- [ ] AI-13-003 Add dominant-palette/composition similarity control.
- [ ] AI-13-004 Do not introduce high visual novelty and maximum puzzle frustration simultaneously by default.
- [ ] AI-13-005 Recovery levels may emphasize playful visual novelty while keeping puzzle pressure low.

## AI-14 — Production QA integration

- [ ] AI-14-001 Add semantic-art gate to M47 content scale-up.
- [ ] AI-14-002 Add ArtReadability and blind-recognition evidence to M48 Level QA.
- [ ] AI-14-003 Add semantic negative/positive regression to M49.
- [ ] AI-14-004 Add mobile-size art readability to M42/M44 real-device/responsive QA.
- [ ] AI-14-005 Add generator/provider provenance to LevelCatalog metadata or adjacent production metadata without polluting gameplay semantics.

## AI-15 — Cost/reliability strategy

- [ ] AI-15-001 Measure semantic provider acceptance rate, cost per accepted candidate and latency.
- [ ] AI-15-002 Cache by normalized request hash where provider terms/architecture permit.
- [ ] AI-15-003 Avoid paying for puzzle analysis on obvious semantic failures by ordering cheap art gates first.
- [ ] AI-15-004 Permit multiple source providers behind the same contract only when explicitly configured.
- [ ] AI-15-005 Never lower semantic acceptance thresholds merely because provider cost is high.

## Dependency ordering

Recommended sequence:

```text
Semantic Subject Catalog
→ SemanticSource interface
→ Native Pixel adapter
→ Pixel Compiler fallback
→ Structural Art Analyzer
→ blind Semantic Judge
→ ArtReadability evaluator
→ negative/positive calibration
→ review console
→ solver/difficulty integration
→ multi-objective search
→ CampaignBuilder visual retention
→ bulk production QA
```

## M21 scope protection

M21-C001 remains the first owner-approved Hazard Bot real-art vertical slice. It must not be expanded into implementing this entire Art Intelligence program. M21 gives us a positive engineering fixture. Art Intelligence becomes the production-scale level-authoring path after the current vertical-slice evidence is secured.
