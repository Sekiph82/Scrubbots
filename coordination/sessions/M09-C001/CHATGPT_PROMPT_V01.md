---
coordinationSchema: scrubbots-coordination/v3
artifactType: chatgpt-prompt
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
baselineCommit: ff441b4ee0d7d7963c3cefe90292b623ba277dba
---

# SCRUBBOTS - M09-C001 Pixel Art to Level Data Importer Core

## Objective

Build the deterministic core pipeline that converts an exact source PNG into SCRUBBOTS Level Data V1 and can reconstruct the exact RGBA8 image from the generated level data.

This cycle is tooling/core work only. No real owner artwork exists in the repository at cycle start, so all importer verification must use deterministic TEST-generated fixtures. Do not claim that M08 production-art audit or real-art ingestion has been completed.

## Canonical GitHub sources to read first

Read all of these before modifying code:

1. Project operating manual:
   https://github.com/Sekiph82/Scrubbots/blob/main/CLAUDE.md
2. Canonical task ledger:
   https://github.com/Sekiph82/Scrubbots/blob/main/tasks.md
3. H!veAI dashboard:
   https://github.com/Sekiph82/Scrubbots/blob/main/.hiveai/PROJECT_DASHBOARD.md
4. Coordination protocol:
   https://github.com/Sekiph82/Scrubbots/blob/main/coordination/README.md
5. Session index:
   https://github.com/Sekiph82/Scrubbots/blob/main/coordination/SESSION_INDEX.md
6. Audit policy:
   https://github.com/Sekiph82/Scrubbots/blob/main/coordination/AUDIT_POLICY.md
7. Audit learning index:
   https://github.com/Sekiph82/Scrubbots/blob/main/coordination/AUDIT_INDEX.md
8. Latest completed independent audit:
   https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M07-C001/CHATGPT_AUDIT_V02.md
9. This cycle's pre-published audit criteria:
   https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M09-C001/CHATGPT_AUDIT_CRITERIA_V01.md
10. This active prompt:
    https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M09-C001/CHATGPT_PROMPT_V01.md
11. Level Data V1 specification:
    https://github.com/Sekiph82/Scrubbots/blob/main/docs/03_LEVEL_DATA_SPEC.md
12. Architecture:
    https://github.com/Sekiph82/Scrubbots/blob/main/docs/02_TECH_ARCHITECTURE.md
13. Technical decisions:
    https://github.com/Sekiph82/Scrubbots/blob/main/docs/05_TECH_DECISIONS.md
14. Test strategy:
    https://github.com/Sekiph82/Scrubbots/blob/main/docs/06_TEST_STRATEGY.md
15. Gameplay/difficulty authority:
    https://github.com/Sekiph82/Scrubbots/blob/main/docs/01_GAMEPLAY_SPEC.md
16. Visual reference intake rules:
    https://github.com/Sekiph82/Scrubbots/blob/main/assets/art/references/README.md
17. Visual inventory:
    https://github.com/Sekiph82/Scrubbots/blob/main/assets/art/references/inventory.json

## Prior audit learnings to apply

Read and explicitly apply these in the implementation/test plan:

- `AL-001`: preserve explicit `preload()` discipline where project-script references require it under headless Godot.
- `AL-003`: never present headless CPU timings as rendered GPU/FPS evidence.
- `AL-004`: rectangular and maximum-size coverage must catch hidden square/fixed-size assumptions.
- `AL-005`: file existence alone is not completion evidence.
- `AL-006`: missing owner artwork cannot be fabricated or relabeled.
- `AL-008`: unknown source metadata must remain null/unverified rather than guessed.
- `AL-009`: every prompt-mandated validation command/check must be individually recorded in Claude's implementation log.

Record in the implementation log how each applicable learning changed implementation or testing.

## Locked scope and sequencing

M08 remains open and owner-asset-dependent because no candidate production artwork currently exists.

M09-C001 is allowed to proceed independently with TEST-generated PNG fixtures because importer architecture, deterministic conversion, validation, and round-trip correctness can be proven without production content.

Do not mark M08 complete.

Do not ingest, download, generate, or invent owner SCRUBBOTS artwork.

Do not start:

- M09 batch import (`SB-M09-018`);
- M09 batch validation (`SB-M09-019`);
- catalog-wide duplicate level ID protection (`SB-M09-020`);
- M10 final DIRTY/CLEAN selection;
- M11 gameplay session;
- slots, targeting, routing, agents, effects, progression, save, or mobile export work.

## Core conversion contract

For M09-C001, source input is a PNG whose source pixels already represent logical cells one-for-one.

The importer must never:

- resize;
- resample;
- interpolate;
- blur;
- crop;
- pad;
- force square dimensions;
- force 20x20, 40x40, 50x50, or any other convenience size;
- silently reduce or reorder colors after the deterministic rule below;
- modify the source file.

One source RGBA pixel equals one logical Level Data cell.

If future owner art has a scaled logical-pixel grid, M08 must determine that first. M09-C001 must not invent scale detection or silently downsample such art.

## Importer architecture

Implement a reusable importer core separated from its command-line/developer wrapper.

Prefer a small, testable architecture such as:

- reusable GDScript importer/service under `scripts/` or another project-consistent runtime-independent location;
- thin command-line/headless entrypoint under `tools/` if useful;
- no EditorPlugin dependency unless there is a strong documented reason;
- no third-party libraries.

Inspect the repository first and choose exact paths that fit current conventions.

Keep importer code separate from gameplay runtime code.

Do not add importer responsibilities to `LevelLoader`, `BoardState`, or `BoardRenderer`.

## Source image handling

Support PNG in this cycle.

Load source image data as RGBA8 or convert once to RGBA8 without spatial/color transformation.

Preserve:

- width;
- height;
- red;
- green;
- blue;
- alpha.

Reject unsupported or unreadable inputs with actionable errors.

Do not silently accept arbitrary formats by passing them through unknown conversion behavior.

## Deterministic palette rule

Palette ordering must be deterministic and documented.

Use the first occurrence of each exact RGBA8 color during canonical row-major scan:

```text
for y = 0 .. height-1
  for x = 0 .. width-1
```

The first new color encountered receives palette ID 0, the next unseen color receives ID 1, and so on.

Use one canonical color-string representation that preserves alpha exactly and is accepted by the existing Level Data/color parsing pipeline. Prefer a stable uppercase RGBA representation such as `#RRGGBBAA` if compatible with existing code.

Do not derive palette order from dictionary/hash iteration.

## Canonical cell flattening

Cells must be emitted in the existing canonical order:

```text
index = y * width + x
```

Do not duplicate an inconsistent formula elsewhere.

Rectangular boards are first-class.

## Difficulty behavior

Use the existing `DifficultyRules` / `ProductionLevelValidator` as the authority. Do not duplicate band constants in importer code.

Production bands remain:

- EASY: width 20..29 and height 20..29
- MEDIUM: width 30..39 and height 30..39
- HARD: width 40..49 and height 40..49
- VERY_HARD: width 50..59 and height 50..59

The importer API/tool must distinguish TEST use from production use.

Requirements:

- TEST imports may use arbitrary positive dimensions for deterministic engine fixtures.
- Production imports must use a recognized production difficulty and pass `ProductionLevelValidator`.
- If an auto-difficulty convenience is implemented, it may only return a production difficulty when width and height both fall inside the same locked band. Otherwise return a clear failure, never guess.
- Unknown difficulty must fail.
- TEST must never silently pass production validation.

## Level Data V1 output

Generate only the existing Level Data V1 schema:

- `version`
- `id`
- `name`
- `difficulty`
- `width`
- `height`
- `palette`
- `cells`

Do not add source metadata fields directly into Level Data V1.

Output must pass existing structural validation.

Production-mode legal fixture output must also pass production validation.

## Source metadata

`SB-M09-011` must not mutate Level Data V1.

If persistent source metadata is useful, store it in a separate deterministic sidecar/import report rather than inventing new Level Data fields.

Only record metadata that can be established from the actual request/source/repository evidence, for example:

- source repository-relative path or explicit input path;
- source width/height;
- exact palette count;
- selected/derived difficulty;
- importer schema/tool version;
- output level ID.

Do not guess original filenames, approval state, owner provenance, or candidate difficulty when not actually known.

If a sidecar is implemented, define and document its schema and make it deterministic.

## Output determinism and no meaningless diffs

The same source image plus the same import request must produce stable output.

At minimum verify:

- palette order identical;
- cells identical;
- JSON object values identical;
- serialized JSON text deterministic;
- repeated run does not create meaningless file-content changes.

If output already exists and generated content is identical, prefer a clean `UNCHANGED`/no-write result rather than rewriting solely to touch the file.

Do not add an unsafe default overwrite policy.

## Reconstruction and pixel-perfect round-trip

Implement reconstruction from generated Level Data back into an RGBA8 `Image`.

This reconstruction must use Level Data, not the original source image as a shortcut.

Verify:

- reconstructed width equals source width;
- reconstructed height equals source height;
- raw RGBA8 bytes match the source image exactly;
- transparent pixels round-trip exactly;
- palette reuse does not alter repeated colors.

`SB-M09-015` requires pixel comparison of the reconstruction against source bytes.

## Preview

Generate a preview/reconstructed PNG from Level Data as the M09 preview artifact.

Do not resize or smooth it.

The preview is derived output and must never overwrite a source file.

Test fixtures/previews must be clearly TEST-only.

## Required TEST fixture matrix

Do not commit fake owner artwork.

Prefer generating deterministic PNG fixtures at test runtime or via a deterministic test-fixture generator in a clearly TEST-only location.

The importer test matrix must include at least:

1. `3x2` non-square TEST image with at least 3 colors and one transparent pixel.
2. A rectangular production-band image such as `20x27` or `34x39` with repeated colors.
3. `59x59` maximum image.
4. A pattern where first-seen palette order is easy to assert and differs from sorted RGB order.
5. Alpha values including 0 and 255; include at least one partially transparent alpha value if Godot PNG round-trip supports it exactly.
6. Repeated colors appearing in separated positions.

No fixture may be labeled owner-approved, production artwork, or original SCRUBBOTS art.

## Required negative/error tests

Add tests for at least:

- missing input file;
- unsupported extension;
- unreadable/corrupt PNG if a deterministic safe fixture can be produced;
- invalid/empty level ID;
- invalid/empty display name;
- unknown difficulty;
- TEST rejected by production validator;
- production dimensions outside the requested band;
- auto-difficulty ambiguity/out-of-band if auto mode exists;
- output path collision/overwrite safety appropriate to the chosen API;
- reconstruction with invalid palette/cell references where safely testable through existing validators.

Errors must be actionable and must not crash the test runner.

## Automated tests

Extend the existing headless test suite rather than creating an isolated unreported test universe.

The current established pre-cycle code baseline is 227 checks from Phase M06/M07 evidence. Do not assume the count after implementation; report the actual new total.

Tests must verify behavior, not only file existence.

Where test-generated files are needed, use a temporary or clearly test-only path and clean them safely without destructive repo-wide operations.

Do not commit `.godot/`, import caches, temp outputs, or arbitrary binaries accidentally.

## Performance sanity

Measure importer core conversion/reconstruction at least on 59x59 TEST data.

No hard millisecond pass/fail threshold is required in this cycle.

Record actual CPU timings if measured, but do not present them as GPU/FPS evidence.

The scale is only 3,481 cells, so any obviously pathological repeated full-image rescanning or accidental O(N^2) palette lookup should be examined.

Prefer a dictionary/map from canonical RGBA key to palette ID while preserving first-seen ordering in the palette array.

## Documentation

Update relevant durable docs to match the actual implemented tool, especially:

- `docs/03_LEVEL_DATA_SPEC.md`
- `docs/06_TEST_STRATEGY.md`
- `docs/05_TECH_DECISIONS.md` only if a durable architecture decision warrants an ADR
- `README.md` only if a user/developer command genuinely belongs there
- `CHANGELOG.md`

Document:

- exact-pixel/no-resize contract;
- deterministic first-seen palette rule;
- TEST vs production behavior;
- reconstruction/round-trip guarantee;
- source metadata sidecar behavior if implemented;
- batch import explicitly deferred to M09-C002.

Do not rewrite unrelated gameplay design.

## tasks.md truth

Only mark M09 tasks complete when implementation plus validation evidence exists.

This cycle targets `SB-M09-001` through `SB-M09-017`.

Do not mark:

- `SB-M09-018` batch import;
- `SB-M09-019` batch validation;
- `SB-M09-020` catalog-wide duplicate level ID protection.

Do not mark any M08 task complete because no candidate production artwork exists.

If one of `SB-M09-001..017` is intentionally deferred due to a real technical reason, leave it open and record why instead of forcing completion.

## Logging and coordination

Continue/create local phase log:

`C:\Users\sekip\Desktop\SCRUBBOTS_PHASE_M09_LOG.md`

This stays local-only and must never be committed.

Create and maintain the cycle's append-only Claude implementation log:

https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M09-C001/CLAUDE_IMPLEMENTATION_LOG.md

Expected repository path:

`coordination/sessions/M09-C001/CLAUDE_IMPLEMENTATION_LOG.md`

Claude must not create any audit or self-audit file.

Before ending a material session, update:

- https://github.com/Sekiph82/Scrubbots/blob/main/coordination/SESSION_INDEX.md
- https://github.com/Sekiph82/Scrubbots/blob/main/.hiveai/PROJECT_DASHBOARD.md

Set the cycle to `AWAITING_AUDIT` only after implementation/tests/logging are complete enough for ChatGPT review.

## Mandatory final validation sequence

Run and individually record each item in `CLAUDE_IMPLEMENTATION_LOG.md` with expected outcome, explicit fail condition, actual result, and `CLAUDE_TEST_PASS` / `CLAUDE_TEST_FAIL` / `NOT_RUN` / `BLOCKED` classification.

1. `godot --version`
2. `powershell -File tools\verify_project.ps1`
3. `godot --headless --path . --quit-after 5`
4. `godot --headless --path . -s res://tests/run_tests.gd`
5. Run the importer through its actual developer/CLI entrypoint on at least:
   - 3x2 TEST fixture;
   - one rectangular production-band generated fixture;
   - 59x59 generated fixture.
6. Re-run the same import request twice and compare deterministic Level Data output/no-change behavior.
7. Reconstruct at least the 3x2, rectangular, and 59x59 outputs and compare raw RGBA8 bytes with source fixture bytes.
8. Verify produced Level Data through existing loader/structural validator; verify legal production-mode fixture through production validator.
9. Verify no real SCRUBBOTS artwork was added and M08 remains open.
10. `git diff --check`
11. `git status --short` before commit.
12. Inspect `git diff` before commit.
13. Commit focused changes.
14. Push safely to `origin/main` without force.
15. Record final commit URL, push result, and final `git status --short` in the implementation log; if a tiny log backfill commit is required for the just-created commit SHA, keep it focused and record both commits.

## Git safety

Never use destructive Git operations on unknown owner work.

Before changes:

- inspect `git status`;
- fetch/sync safely;
- preserve local owner work;
- do not reset/clean unrecognized files.

Before commit:

- inspect diff carefully;
- ensure no local Desktop phase log is staged;
- ensure no `.godot/`, caches, build artifacts, arbitrary images, secrets, or unrelated files are staged.

Never force-push.

## Expected Claude final response

Keep the chat response short and include only:

- `Cycle: M09-C001`
- cycle state
- implementation commit(s) and push status
- implementation log GitHub URL
- actual regression test count
- exact-pixel round-trip summary
- deterministic rerun summary
- M09 tasks completed vs deferred
- blockers
- `READY FOR CHATGPT AUDIT` when appropriate

Then stop.

Do not start M09-C002, M08 production-art audit, M10 visual approval, or M11 gameplay session.
