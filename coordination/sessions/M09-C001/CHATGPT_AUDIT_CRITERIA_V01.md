---
coordinationSchema: scrubbots-coordination/v3
artifactType: chatgpt-audit-criteria
cycleId: M09-C001
version: 1
createdAt: 2026-08-27T17:05:00+03:00
actor: CHATGPT
status: ISSUED
milestone: M09
taskRefs:
  - SB-M09-001
  - SB-M09-002
  - SB-M09-003
  - SB-M09-004
  - SB-M09-005
  - SB-M09-006
  - SB-M09-007
  - SB-M09-008
  - SB-M09-009
  - SB-M09-010
  - SB-M09-011
  - SB-M09-012
  - SB-M09-013
  - SB-M09-014
  - SB-M09-015
  - SB-M09-016
  - SB-M09-017
---

# SCRUBBOTS - M09-C001 ChatGPT Audit Criteria V01

These criteria define what ChatGPT will independently inspect after Claude completes M09-C001. Claude must implement/test/log only and must not create an audit file.

## Scope gate

M08 remains owner-asset-dependent and open. No real owner artwork exists in the repository at cycle start. M09-C001 may build and test importer infrastructure with deterministic TEST-generated PNG fixtures, but it must not claim that real production artwork has been audited or imported.

Batch import and batch validation (`SB-M09-018`, `SB-M09-019`) and catalog-wide duplicate-ID protection (`SB-M09-020`) are outside this cycle.

## Pass/fail criteria

| ID | Requirement | AUDITED_PASS requires | AUDITED_FAIL if |
| --- | --- | --- | --- |
| AC-M09-001 | Scope integrity | Changes stay within importer/tooling/tests/docs/coordination; M08, slots, gameplay, routing, final DIRTY preset, and real owner art remain untouched. | Scope creep or fabricated/guessed owner art appears. |
| AC-M09-002 | Exact source dimensions | Imported width/height equal source PNG pixel dimensions exactly for square and rectangular fixtures. | Any silent resize, crop, pad, square coercion, or fixed-size assumption. |
| AC-M09-003 | Exact source pixels | One source RGBA pixel maps to one logical cell with alpha preserved. | Resampling/interpolation/color correction changes source pixel values. |
| AC-M09-004 | Deterministic palette | Palette ordering is explicitly deterministic and stable across repeated runs. | Hash/map iteration or other nondeterminism changes palette order/output. |
| AC-M09-005 | Canonical flattening | Cells use row-major `index = y * width + x`. | Any alternate/ambiguous mapping or width==height assumption. |
| AC-M09-006 | Difficulty handling | Production dimensions map/validate only against locked bands; TEST mode remains non-production and can exercise small fixtures. | TEST silently becomes production, unknown difficulty is accepted, or band rules are duplicated inconsistently. |
| AC-M09-007 | Level Data V1 compatibility | Output loads through existing LevelLoader/LevelValidator and, for production-mode legal fixtures, ProductionLevelValidator. | Importer invents a conflicting LevelData schema or bypasses validators. |
| AC-M09-008 | Metadata provenance | Unknown source metadata stays null/unverified; persistent metadata, if added, does not pollute Level Data V1. | Guessed metadata is invented or Level Data V1 is silently expanded. |
| AC-M09-009 | Deterministic output/no meaningless diff | Same input/request produces byte-identical JSON text or an explicit no-change result on rerun. | Rerun changes output without semantic input change. |
| AC-M09-010 | Reconstruction | Generated Level Data reconstructs to an RGBA8 image with identical width/height and raw pixel bytes. | Round-trip differs for any tested pixel, including alpha. |
| AC-M09-011 | Preview | Preview/reconstruction output is generated from imported Level Data, not independently transformed source art. | Preview uses smoothing/resizing or bypasses generated data. |
| AC-M09-012 | Failure behavior | Missing, malformed, unsupported, invalid-dimension/difficulty, and unwritable-output cases return actionable errors without crashing. | Silent fallback, destructive overwrite, or unhandled crash. |
| AC-M09-013 | Test matrix | Includes tiny non-square TEST fixture, at least one production-band rectangle, 59x59 maximum, transparency, repeated colors, and >=3-color ordering case. | Only square/happy-path fixtures are tested. |
| AC-M09-014 | No committed fake art | TEST PNG inputs are generated deterministically at test/runtime or clearly isolated as TEST fixtures; none are labeled production/original art. | Synthetic fixture is presented as owner/canonical art. |
| AC-M09-015 | Validation traceability | Claude implementation log records every prompt-mandated command/check individually with expected, fail condition, actual result. | Aggregate green count substitutes for omitted required checks. |
| AC-M09-016 | Regression | Existing suite remains green and new importer tests are included in the actual reported total. | Existing regression fails, new tests are skipped, or count/evidence is ambiguous. |
| AC-M09-017 | Task truth | Only M09 tasks actually implemented and validated in this cycle are checked. M08 and deferred M09-018..020 stay open. | Checklist overstates completion. |

## Audit learnings that will be checked

- `AL-001`: preserve explicit preload discipline where cross-script core/tool references need it.
- `AL-003`: do not claim GPU/FPS evidence from headless timings.
- `AL-004`: rectangular and maximum-size coverage is mandatory where sizing matters.
- `AL-005`: file existence is not task completion evidence.
- `AL-006`: missing owner artwork cannot be fabricated.
- `AL-008`: unknown metadata remains null/unverified without evidence.
- `AL-009`: every required validation command is individually traceable in Claude's implementation log.

Audit index:
https://github.com/Sekiph82/Scrubbots/blob/main/coordination/AUDIT_INDEX.md

Latest completed audit baseline:
https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M07-C001/CHATGPT_AUDIT_V02.md
