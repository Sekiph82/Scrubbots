---
coordinationSchema: scrubbots-coordination/v3
artifactType: chatgpt-audit
cycleId: M09-C001
version: 1
createdAt: 2026-08-27T23:47:00+03:00
actor: CHATGPT
status: CHANGES_REQUIRED
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
auditedPromptVersions: [1]
auditedCommit: 49178d412276137a39da993bfafe47262dc10c97
---

# SCRUBBOTS - M09-C001 ChatGPT Independent Audit V01

## Decision

`CHANGES_REQUIRED`

The importer architecture, deterministic palette/cell mapping, Level Data V1 separation, rectangular/59x59 coverage, and reconstruction design are substantially correct. However, the current implementation does not yet satisfy the prompt's source-preservation and safe-output contract, and the PNG-only input contract is not actually enforced by the importer core.

Claude's reported `286/286` result is implementer-run evidence. ChatGPT inspected the repository diff, importer/CLI/test code, task truth, and coordination state independently, but did not execute the local Godot binary in this audit environment.

## Canonical evidence reviewed

- Repository: https://github.com/Sekiph82/Scrubbots
- Active prompt: https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M09-C001/CHATGPT_PROMPT_V01.md
- Audit criteria: https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M09-C001/CHATGPT_AUDIT_CRITERIA_V01.md
- Claude implementation log: https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M09-C001/CLAUDE_IMPLEMENTATION_LOG.md
- Importer core: https://github.com/Sekiph82/Scrubbots/blob/main/scripts/tools/level_importer.gd
- CLI: https://github.com/Sekiph82/Scrubbots/blob/main/tools/import_level.gd
- Test runner: https://github.com/Sekiph82/Scrubbots/blob/main/tests/run_tests.gd
- Task truth: https://github.com/Sekiph82/Scrubbots/blob/main/tasks.md
- Baseline: https://github.com/Sekiph82/Scrubbots/commit/ff441b4ee0d7d7963c3cefe90292b623ba277dba
- Implementation commit: https://github.com/Sekiph82/Scrubbots/commit/7acd0e65ede18f33553eedcec82fabf2125291d1
- Audited head: https://github.com/Sekiph82/Scrubbots/commit/49178d412276137a39da993bfafe47262dc10c97
- Baseline-to-head comparison: https://github.com/Sekiph82/Scrubbots/compare/ff441b4ee0d7d7963c3cefe90292b623ba277dba...49178d412276137a39da993bfafe47262dc10c97

## Independent repository checks

1. The baseline-to-head diff stays within M09 importer/tooling/tests/docs/coordination scope. No owner artwork, gameplay-session, slot, routing, agent, M10 design-gate, or M08 production-art implementation was added.
2. `scripts/tools/level_importer.gd` uses explicit `preload()` references and does not move importer responsibilities into `LevelLoader`, `BoardState`, or `BoardRenderer`.
3. Palette IDs are assigned from a row-major scan using an ordered palette plus dictionary lookup, so hash iteration does not determine palette order.
4. Cell flattening uses `y * width + x`.
5. Production difficulty checks delegate to `DifficultyRules` and `ProductionLevelValidator` rather than duplicating the locked bands.
6. Generated Level Data remains the existing V1 schema; source metadata is separate.
7. Reconstruction is generated from Level Data palette/cells, not the source image.
8. The committed test code includes non-square, rectangular production-band, 59x59 maximum, transparent/semitransparent, repeated-color, deterministic rerun, overwrite-collision, and difficulty-negative coverage.
9. No PNG artwork was committed under `assets/art/`; test images are generated at runtime.
10. The code inspection also exposed the failures below that the current tests do not exercise.

## Requirement audit

| Criterion | Result | Independent evidence / notes |
| --- | --- | --- |
| AC-M09-001 Scope integrity | `AUDITED_PASS` | Diff is importer/tooling/tests/docs/coordination only; no real art or future gameplay systems added. |
| AC-M09-002 Exact source dimensions | `AUDITED_PASS` | Importer takes `Image.get_width()/get_height()` directly and performs no spatial transform. |
| AC-M09-003 Exact source pixels | `AUDITED_PASS` for normal PNG flow | Importer converts only pixel format to RGBA8 and scans one pixel per cell; no resize/crop/resample path exists. Runtime byte-match remains Claude-run evidence. |
| AC-M09-004 Deterministic palette | `AUDITED_PASS` | First-seen row-major ordering is explicit; dictionary is lookup-only, never iteration authority. |
| AC-M09-005 Canonical flattening | `AUDITED_PASS` | `cells[y * w + x]` and reconstruction use the canonical row-major formula. |
| AC-M09-006 Difficulty handling | `AUDITED_PASS` | Existing DifficultyRules/ProductionLevelValidator remain authority; TEST remains separate. |
| AC-M09-007 Level Data V1 compatibility | `AUDITED_PASS` by code structure; runtime validator results are Claude-run evidence | V1 fields are unchanged and generated dict is sent through LevelValidator; production levels also use ProductionLevelValidator. |
| AC-M09-008 Metadata provenance | `AUDITED_PASS` | Sidecar is separate from Level Data and contains request/source-derived facts only. |
| AC-M09-009 Deterministic output/no meaningless diff | `AUDITED_PASS` for Level JSON | Existing identical Level JSON is detected as unchanged. |
| AC-M09-010 Reconstruction | `AUDITED_PASS` by design for valid generated data; runtime byte equality is Claude-run evidence | Reconstruction uses only Level Data. Malformed-cell robustness needs correction under AC-M09-012. |
| AC-M09-011 Preview | `AUDITED_FAIL` | Preview is reconstructed correctly, but its destination is not protected against source/output/metadata path aliasing or existing-file overwrite when `overwrite=false`. |
| AC-M09-012 Failure behavior | `AUDITED_FAIL` | Source/artifact aliasing can overwrite the source or another artifact; preview/metadata ignore safe overwrite semantics; PNG-only input is not explicitly gated; malformed reconstruction with short `cells` can index out of bounds. |
| AC-M09-013 Test matrix | `AUDITED_PASS` for requested shape/color coverage | Required size/alpha/reuse coverage exists. Safety/format negatives are incomplete. |
| AC-M09-014 No committed fake art | `AUDITED_PASS` | No synthetic PNG is committed as owner/canonical art. |
| AC-M09-015 Validation traceability | `AUDITED_PASS` | Implementation log individually records the required command sequence. |
| AC-M09-016 Regression | `NOT_INDEPENDENTLY_VERIFIED` | Claude reports 286/286 and test code is present, but ChatGPT did not run the local Godot executable. |
| AC-M09-017 Task truth | `AUDITED_FAIL` | SB-M09-017 is checked as complete while unsupported-format and destructive path-collision cases remain unhandled. |

## Findings

### F-M09-001 - HIGH - Source and artifact path aliasing can destructively overwrite files

The prompt explicitly requires that the source image never be modified and that preview output never overwrite source art.

Current `run_import()` does not reject path aliasing between:

- `source_path`
- `output_path`
- `preview_path`
- `metadata_path`

Examples from the current code:

- `output_path == source_path` with `overwrite=true` reaches `_write_text()` and can replace the source PNG with JSON text.
- `preview_path == source_path` reaches `save_png()` and can replace the source file.
- `metadata_path == source_path` reaches `_write_text()` and can replace the source with metadata JSON.
- `preview_path == output_path` can overwrite the newly generated Level JSON with a PNG.
- `metadata_path == output_path` can overwrite the Level JSON with sidecar text.
- `metadata_path == preview_path` can overwrite the preview.

**Required correction:** canonicalize/normalize path identities and reject any alias among source/output/preview/metadata before any write occurs. The source path must remain immutable regardless of `overwrite=true`. Add explicit negative tests that verify failure and confirm the source bytes remain unchanged.

### F-M09-002 - HIGH - Safe overwrite policy is not applied to preview and metadata outputs

`output_path` has collision behavior, but preview and metadata writes currently call `save_png()` / `_write_text()` directly whenever their paths are supplied. Therefore an existing unrelated preview/metadata file can be overwritten even when `overwrite=false`.

**Required correction:** apply one consistent safe-artifact policy to Level JSON, preview, and metadata destinations. With `overwrite=false`, an existing different artifact must not be replaced. Identical deterministic content may be treated as unchanged/no-write. With `overwrite=true`, replacement may be allowed only for derived destinations that are proven distinct from the source and from each other.

Add tests for existing preview and metadata collisions under both overwrite modes.

### F-M09-003 - MEDIUM - PNG-only contract is not enforced

M09-C001 explicitly supports PNG only and says unsupported formats must be rejected. The importer core calls `Image.load(request.source_path)` without validating the input extension/type. The current negative test writes text to `dummy.txt`; that proves an unreadable non-image fails, but it does **not** prove that a valid non-PNG image is rejected.

Godot can load multiple image formats, so the code path is capable of accepting an otherwise valid non-PNG image instead of enforcing the cycle contract.

**Required correction:** explicitly gate supported input to `.png` (case-insensitive) in the reusable importer core, not only the CLI. Add a deterministic valid non-PNG fixture (for example a runtime-generated JPEG if supported by the available Godot build) and prove it is rejected with an actionable unsupported-format error. Keep unreadable/corrupt PNG coverage separate from unsupported-format coverage.

### F-M09-004 - MEDIUM - Reconstruction does not safely reject malformed cell-array length

`reconstruct_image(level)` iterates `width * height` and directly reads `level.cells[idx]` before checking that the cells array has the required length. A malformed LevelData object with too few cells can therefore produce an out-of-bounds runtime error rather than returning a clean failure.

The prompt explicitly requested invalid palette/cell-reference reconstruction coverage where safely testable.

**Required correction:** validate reconstruction preconditions before indexing: positive dimensions, non-empty/valid palette, exact `cells.size() == width * height`, and valid palette IDs. Return `null` (or a structured actionable result if the architecture is deliberately upgraded) without crashing. Add negative tests for short cells, out-of-range palette ID, and invalid palette string.

## Test-quality finding

The existing `286/286` suite is useful but contains a false-positive gap: the test labeled as unsupported-extension coverage uses a text file that is also unreadable as an image. It therefore cannot distinguish "unsupported format rejected" from "arbitrary unreadable file rejected." Future format-gating tests must use a valid file in a deliberately unsupported format.

Likewise, the existing overwrite test only checks the Level JSON destination. It does not exercise source/output/preview/metadata aliasing or preview/metadata collision behavior.

## Reusable audit learnings

Add to `coordination/AUDIT_INDEX.md`:

- `AL-010`: Path aliasing and source immutability. Any importer/exporter with source plus derived outputs must canonicalize path identity and reject source/destination or destination/destination aliasing before writes. An overwrite flag must never authorize source destruction.
- `AL-011`: Negative tests must isolate the claimed failure mode. A corrupt text file does not prove unsupported-image-format rejection; use a valid unsupported format when testing a format gate.
- `AL-012`: Safe overwrite policy must cover every generated artifact, not only the primary output. Preview/metadata/cache side outputs require the same collision analysis.

## Task-truth impact

- Keep SB-M09-001..016 checked for now; their core deliverables exist and the findings can be corrected without discarding them.
- Reopen `SB-M09-017` until unsupported-format rejection, path-alias safety, derived-output collision behavior, and malformed reconstruction failure behavior are implemented and validated.
- Keep SB-M09-018..020 open.
- Keep every M08 item open.

## Required follow-up

Continue the same cycle `M09-C001`.

ChatGPT will publish `CHATGPT_PROMPT_V02.md`. Claude must implement/test/log only, apply F-M09-001..004 and AL-010..012, append to the existing implementation log, update task truth/dashboard/index, push safely, return the cycle to `AWAITING_AUDIT`, and stop.

Do not begin M09-C002 until ChatGPT independently closes M09-C001.
