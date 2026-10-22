STATUS: READY

# Build: M08 Level Art Technical Audit

## Spec (no spec.md; from the dispatch prompt)
Audit every owner level source image (M21 hazard bot + levels 002..010, `assets/art/levels/source/**`)
with a deterministic script: filename, dimensions, alpha/VOID, colour count, anti-aliasing, interpolation,
logical grid W x H, envelope 20..59 + VOID D2 (>=200 non-VOID, >=25% W*H), exact mapping of every source
colour to palette V3 C01..C16 (or explicit rejection, never C17+). Report in
`docs/LEVEL_ART_TECHNICAL_AUDIT.md`. Never modify source art. Tick SB-M08-001..010, 013, 014; SB-M08-011..012
are standing rules; close the three queue rows. Failures become new open items (none found).

## Summary
Branch `factory/030-m08-art-audit` adds a read-only stdlib-Python audit tool and its report; all 10 images PASS.
No existing audit tool existed: `scripts/tools/level_importer.gd` is an importer (1 px = 1 cell, envelope +
ProductionLevelValidator) with no AA/grid detection, so a standalone script was the smallest fit; it reuses
the same constants (20..59, D2 200/25%, palette V3 JSON, colour envelope 3..12).

Files changed:
- `tools/audit_level_art.py` (new; PNG zlib decode, run-length-GCD grid detection, `--self-test`)
- `docs/LEVEL_ART_TECHNICAL_AUDIT.md` (new; method, table, per-image colour mapping, verdict)
- `TASKS.md` (12 ticks + one DONE queue row replacing three READY rows)

Commits: `6f970e6e` (tool + report), `25ff2253` (TASKS.md).

## Acceptance criteria
1. [x] Deterministic audit script: `python tools/audit_level_art.py` rerun produces identical output (sorted glob, no randomness); exit 0.
2. [x] Per-image filename, dimensions, alpha/VOID, colour count, AA, interpolation, logical grid: table columns in the report (output below).
3. [x] Envelope 20..59 per dimension and VOID D2: grids 20x20..38x38, all inside; no image has VOID so D2 is not triggered (verified in self-test that D2 fails a sparse VOID image).
4. [x] Exact C01..C16 mapping or rejection: every source colour exact-matched, e.g. apple `#FF4500 x296 -> C01 ... #FFF8B8 x10 -> C12`; zero REJECTED. Self-test asserts a blended `#803C00` is REJECTED and flagged as AA.
5. [x] Report `docs/LEVEL_ART_TECHNICAL_AUDIT.md` with table, mapping evidence, verdict per image.
6. [x] Source art untouched: `git diff --stat b95ed155 HEAD` lists only the three files above.
7. [x] TASKS.md: SB-M08-001..010, 013, 014 ticked with 2026-10-22 factory 030 note; queue rows replaced by one DONE row; SB-M08-011..012 already in the Not-queued standing-rules comment (line 126).
8. [x] No failures found, so no new open item added.

Script output summary:
```
audit_level_art self-test: PASS
| File | Size | VOID px | Semi-alpha px | Colours | Anti-aliasing | Block | Interpolation | Logical grid | Non-VOID cells | Verdict |
| easy/level_002_apple_32x32.png        | 32x32 | 0 | 0 | 5  | none | 1x1 | none | 32x32 | 1024 | PASS |
| easy/level_004_orange_cat_32x32.png   | 32x32 | 0 | 0 | 7  | none | 1x1 | none | 32x32 | 1024 | PASS |
| easy/level_006_chicken_32x32.png      | 32x32 | 0 | 0 | 8  | none | 1x1 | none | 32x32 | 1024 | PASS |
| easy/level_007_pigeon_32x32.png       | 32x32 | 0 | 0 | 8  | none | 1x1 | none | 32x32 | 1024 | PASS |
| easy/level_009_frog_32x32.png         | 32x32 | 0 | 0 | 7  | none | 1x1 | none | 32x32 | 1024 | PASS |
| easy/scrubbots_m21_level_001_hazard_bot_20x20.png | 20x20 | 0 | 0 | 5 | none | 1x1 | none | 20x20 | 400 | PASS |
| hard/level_005_party_toucan_33x33.png | 33x33 | 0 | 0 | 10 | none | 1x1 | none | 33x33 | 1089 | PASS |
| medium/level_003_palm_tree_38x38.png  | 38x38 | 0 | 0 | 6  | none | 1x1 | none | 38x38 | 1444 | PASS |
| medium/level_008_butterfly_32x32.png  | 32x32 | 0 | 0 | 8  | none | 1x1 | none | 32x32 | 1024 | PASS |
| very_hard/level_010_ice_cube_32x32.png| 32x32 | 0 | 0 | 10 | none | 1x1 | none | 32x32 | 1024 | PASS |
SUMMARY: 10 images, 10 PASS, 0 FAIL
```
(paths abbreviated here; the report has full paths and per-colour mappings.)

## Validation
- `python tools/audit_level_art.py --self-test`: PASS (2x upscale -> block 2x2 grid 20x20; blended pixel -> AA + REJECTED + FAIL; sparse VOID -> D2 FAIL; synthetic PNG decode round-trip).
- `python tools/audit_level_art.py`: exit 0, 10/10 PASS.
- `git diff --check b95ed155 HEAD`: clean. `git status --porcelain`: empty.
- No Godot code touched, so no Godot suite run.

## Log
### Round 1
Searched level_factory/, content_pipeline/, tools/, scripts/, docs/ for an existing art audit; only the
importer exists (no AA/grid detection). Wrote `tools/audit_level_art.py` (stdlib), ran it, assembled the
report (CRLF like neighbouring docs), ticked TASKS.md. Ceiling noted in the report: an exact
nearest-neighbour fractional upscale that keeps palette colours would read as block 1x1.
