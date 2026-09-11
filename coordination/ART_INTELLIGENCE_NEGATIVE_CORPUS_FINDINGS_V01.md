# Art Intelligence Negative Corpus Findings V01

Date: 2026-09-12
Role: design evidence for SCRUBBOTS Level Factory / Art Intelligence.

## Source review pack

The owner supplied the M10 review pack from the earlier `Scrubbots - Pixel Art Generator` experiment. The ZIP contained an offline HTML review index plus embedded logical-grid manifests/metrics. The 100 candidate images were reconstructed exactly from their logical grids and canonical palette for review.

This document does not import those rejected images into SCRUBBOTS production. It records the design findings only.

## Corpus summary

- Review candidates: 100
- EASY: 25
- MEDIUM: 25
- HARD: 25
- VERY_HARD: 25
- MASK: 35
- RULES: 25
- HYBRID: 40
- Machine structural-quality accepted: 100 / 100
- Owner production semantic-art accepted: 0 / 100
- Earlier generation run: 122 attempts, 100 machine accepted, 22 retry-exhausted

Representative generator families included ROBOT, FISH, SPACE_SHIP, SEA_CREATURE, FACE_EMBLEM, CORAL, ORGANIC, CENTRAL_SUBJECT, DENSE_FULL_BOARD, SPARSE_NEGATIVE_SPACE, MULTI_ISLAND and symmetry/hybrid recipes.

## Primary finding

**Structural correctness did not predict semantic recognizability.**

The system could make images that were:
- deterministic;
- canonical-palette legal;
- connected;
- symmetric;
- low in isolated/tiny cells;
- non-checkerboard;
- diverse by mask/layout metrics;

while still failing the product question:

> If the metadata label is hidden, can a player identify what the picture depicts?

For the reviewed production standard, the answer was not reliably yes for any of the 100.

## Failure families observed

### F-ART-NEG-001 — label/shape semantic mismatch

Family labels such as ROBOT, FISH and SPACE_SHIP often produced generic ornaments, blobs, bottles, badges, containers or abstract symmetric icons rather than a reliably identifiable instance of the named subject.

### F-ART-NEG-002 — geometry-first construction lacks object grammar

The procedural system knew concepts such as symmetry, central mass, islands, lines and regions but did not possess the semantic part grammar of a subject.

A fish requires a meaningful body/head/tail/fin relationship. A robot requires a readable head/body/limb or face/device structure. Those relationships cannot be replaced by generic symmetric geometry.

### F-ART-NEG-003 — color regions were decorative rather than semantic

Color placement often partitioned geometry without corresponding to meaningful visual parts. Additional colors therefore increased visual entropy without increasing recognizability.

### F-ART-NEG-004 — symmetry was over-valued

Many candidates had strong symmetry and clean connectedness but still read as emblems or ornaments. Symmetry is useful evidence, not semantic identity.

### F-ART-NEG-005 — resolution growth did not create semantic detail

Moving from EASY-sized to HARD/VERY_HARD-sized boards mostly provided more cells for the same abstract construction vocabulary. Higher resolution alone did not solve missing subject semantics.

### F-ART-NEG-006 — machine quality gate was solving the wrong problem

The old quality policy was effective at rejecting obvious low-level pathologies such as isolated cells, tiny regions, extreme checkerboards and certain slab patterns. It did not test metadata-blind subject recognition.

The 100/100 structural ACCEPT versus 0/100 owner semantic ACCEPT gap is the clearest evidence of this false-positive class.

### F-ART-NEG-007 — procedural families remain useful, but in a different role

MASK/RULES/HYBRID/WFC infrastructure should be retained for geometry constraints, cleanup, mutation, topology, technical fixtures, diversity and puzzle support. It should not remain the primary author of semantic subject identity.

## Positive implication from SCRUBBOTS owner examples

The issue is not that 20–30 logical pixels are inherently too small. Owner-reviewed AI-generated low-resolution sprite examples, including the M21 Hazard Bot candidate, demonstrate that recognizable semantic pixel art can exist at very small logical resolutions when subject meaning is created by a semantic image model.

Therefore the architecture should change the **source of semantic meaning**, not merely increase board dimensions.

## Required architectural response

1. Add Semantic Art Planner.
2. Add provider-neutral semantic AI source adapters.
3. Prefer native low-resolution pixel generation when the provider can deliver it reliably.
4. Add high-resolution concept → Pixel Compiler fallback.
5. Introduce ArtReadability Score independent of Challenge Score.
6. Add metadata-blind vision recognition.
7. Add human/owner visual promotion gate.
8. Preserve negative-corpus regression evidence.
9. Keep procedural generators as deterministic support systems.
10. Never mutate semantic identity merely to hit a puzzle-difficulty target.

Canonical detailed design:
`docs/13_ART_INTELLIGENCE_SEMANTIC_LEVEL_ART_PIPELINE.md`

Machine-readable initial scoring model:
`data/config/art_readability_model_v1.json`
