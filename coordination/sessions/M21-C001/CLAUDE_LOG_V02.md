# M21-C001 V02 — Claude Implementation Log

Cycle: `M21-C001` V02 — frozen builder corrections + adversarial validation.
Actor: Claude (implementer/test runner). Auditor: ChatGPT (independent).
Repository: `Sekiph82/Scrubbots`, branch `main`. Handoff: `AWAITING_AUDIT`.
Engine: Godot `4.7.1.stable.official.a13da4feb`.

Runtime results below (root suite, smokes, boots, generators) are Claude E1/E2
runtime evidence. ChatGPT-independent GitHub/source inspection is E3.

## 0. Safe sync + preserved owner/local work

- Synchronized starting base: local `328dd83…` fast-forwarded to `origin/main`
  `fbe7fd7…` via `git rebase --autostash origin/main` (0 ahead / 12 behind; the 12
  incoming commits were the V01 audit freeze, V02 prompt/criteria, and unrelated
  Difficulty-V1 / Art-Intelligence planning docs). Verified the incoming set did
  not touch the owner's locally-modified files first.
- Preserved owner/local work (autostash reapplied, never dropped/reset/restored):
  `project.godot`, `scenes/debug/routing_prototype_lab.tscn`,
  `scenes/debug/scrubbot_agent_debug.tscn` (unstaged throughout), plus untracked
  owner inbox `.import` sidecars, `docs/logs/`, `*.uid` files. None staged.
- No `.hiveai` tracker recreated. GitHub-only logging.

## 1. Tracker-only start transition

Updated only root `TASKS.md` Project Status to
`M21 / M21-C001 V02 / IN_PROGRESS / CLAUDE` (progress unchanged 304/719 and
304/943; `lastCompletedTaskId` M20-C001-V11; note V01 audit
CHANGES_REQUIRED / FINDING_SET_FROZEN and F-M21-STRICT-001..004 OPEN).

**Tracker-only start commit (only `TASKS.md` staged): `3326d0a012ebe22c96d763690457596852fbcb7b`.** Pushed to `origin/main` before any implementation/test/evidence edit.

## 2. Scope

Frozen correction set F-M21-STRICT-001..004 only, plus the mandatory AL-035
adversarial validation. No M19/M20 gameplay code, no `difficulty_rules.gd` /
`production_level_validator.gd` redesign, no Difficulty Score / CampaignBuilder /
Level Factory / PixelLab / M22+ UI / scoring / win-lose / economy / progression.
No M21/UI checkbox closed by Claude.

## 3. F-M21-STRICT-001..004 closure table

| Finding | Correction | Direct tests |
| --- | --- | --- |
| F-001 difficulty identity can diverge | `normalize_from_level_data` now requires the explicit `difficulty` to be a non-empty string, exactly equal to `raw.difficulty`, an installed production difficulty (TEST/unknown/empty rejected) — checked before any palette/normalization work; the emitted LevelData and the validated difficulty are one identity, and production validation always runs for a successful production result. Documented as an M21 legacy compatibility gate, not Difficulty V1 design law. | `_run_m21_v02_difficulty_identity_tests`: mismatch (load-bearing on the exact error), TEST, unknown, empty; control EASY still canonical. |
| F-002 arbitrary `raw` dereferenced | New `_is_exact_level_data(raw)` (exact-script identity) guards the public entry before any field access; arbitrary Variants fail closed with a normal `NormalizeResult` error, no SCRIPT/Parse error, no write, no source mutation. Valid LevelData path unchanged. | `_run_m21_v02_malformed_raw_tests`: null, int, String, Vector2, Vector2i, unrelated RefCounted, Image, partial/wrong-script object; source blob rechecked unchanged. |
| F-003 incomplete multi-artifact preflight | New `_preflight_destination` runs for every enabled artifact BEFORE any write: rejects a directory at a final path (even `overwrite=true`), a missing parent, and a non-directory parent; existing source/dest and dest/dest alias rejection and existing-different-content conflict remain, all pre-write. `_plan_text` comparison made line-ending-insensitive so an autocrlf CRLF checkout of an LF artifact is still `UNCHANGED`. | `_run_m21_v02_destination_preflight_tests` on the NEW builder: all alias pairs, dot-segment alias, missing/non-dir parent, directory-at-path (output/preview), existing-different conflict, UNCHANGED rerun, and the load-bearing later-destination test proving the earlier output is NOT written on a later failure. |
| F-004 non-reproducible reference composite | New committed generator `tools/build_m21_reference_composite.gd` rebuilds `M21_REFERENCE_COMPOSITE.png` from the committed LevelData through the real `BoardRenderer` over BG01 (initial / top-half partial / fully cleared panels); it never reads the existing composite; deterministic (488x160, panels=3, scale=8, gap=4); second run reports UNCHANGED. Composite writing removed from the smoke so there is a single deterministic source. | Command table §5; determinism proven by two consecutive runs. |

## 4. V02 adversarial scenario / evidence table (fresh arrangements, AL-035)

| Scenario | Evidence |
| --- | --- |
| Blocked non-C08 activation has EXACT zero gameplay side effects | `_run_m21_v02_adversarial_tests`: fresh real bundle; snapshot of all 400 cell states, all five candidate buckets, reservation count, dispatcher active count, and loop cleared count BEFORE a C01 activation; activation returns exactly `NO_REACHABLE_TARGET`; every snapshot element proven exactly unchanged. |
| Fresh real success progression | Same fresh bundle: C08 dispatch through real selector/access/routing/dispatcher/agent, reservation + MOVING before arrival, authenticated arrival clears exactly once; then continued real C08 clears until an initially-blocked non-C08 color becomes reachable (ACTIVE before, CLEARED after) via the production path, no forced target, no M20 fault seam. |
| Full 400-cell fresh smoke | `tests/m21_real_art_smoke.gd` rerun as its own process: 400 loop clears, 400 CLEARED, 0 ACTIVE, all five colors, 0 candidates/reservations/dispatcher-active, 0 orphan agents after frames, all 400 renderer pixels alpha 0, BG01 not a LevelData palette color; finite deadlock guard retained. |

## 5. Required commands and actual results

| # | Command | Result |
| --- | --- | --- |
| 1 | `godot --version` | `4.7.1.stable.official.a13da4feb` |
| 2 | `godot --headless --path . -s res://tests/run_tests.gd` | **4475 checks, 0 failures, ALL PASS** (V01 baseline 4407 + 68 V02) |
| 3 | `godot --headless --path . -s res://tests/m21_real_art_smoke.gd` | PASS (400 clears, 5 colors); elapsed_cpu ~47.8 s — headless CPU diagnostic only, NOT a mobile FPS/GPU claim (AL-003) |
| 4 | M20 queue-free + V04/V05/V07/V08/V09/V10 lifecycle smokes | all PASS |
| 5 | headless boot `res://scenes/debug/m21_real_art_vertical_slice.tscn --quit-after 5` | boots, 0 SCRIPT/Parse errors |
| 6 | `res://tools/build_m21_reference_composite.gd` x2 | run 1 WRITTEN/UNCHANGED, run 2 UNCHANGED (488x160, panels=initial|partial|final) |
| 7 | `res://tools/build_m21_level.gd` rerun | LEVEL/PREVIEW/METADATA all UNCHANGED (deterministic) |
| 8 | source blob + SHA-256 recheck | blob `b565743…`, sha256 `ede1e02…` — unchanged |
| 9 | M20 loop/dispatcher blob recheck | loop `06391839…`, dispatcher `eee10149…` — unchanged |
| 10 | scan for `SCRIPT ERROR` / `Parse Error` | 0 across root suite, smokes, debug boot |
| 11 | `git diff --check` | clean (only benign LF→CRLF advisories on owner `project.godot` and the LF-authored M21 text artifacts under autocrlf; no content diff) |

Root-suite at-exit leak warnings (1 CanvasItem RID / 60 ObjectDB / 9 resources)
are pre-existing baseline behavior (identical with M21 disabled at 4294); V02 adds
none.

## 6. Sensitivity / load-bearing proof (prompt §7)

- **Mismatch (F-001):** the mismatch fixture is the real, fully-valid EASY source;
  only the explicit `difficulty` argument disagrees. The test asserts the exact
  error `must equal raw.difficulty`, so removing the equality guard changes the
  outcome/reason and fails the test for the intended reason.
- **Malformed-raw (F-002):** each invalid input asserts the exact contract-guard
  error `exact LevelData instance`. Removing the guard would dereference `raw` and
  raise a runtime error instead of that message, failing the test.
- **Later-destination (F-003):** the missing-preview-parent and directory-preview
  arrangements assert the earlier output file is NOT created. Removing the
  all-destination preflight would let the output JSON be written before the later
  failure, creating the partial commit the test forbids — the test fails.

## 7. Exact changed files (authorized V02 work)

Modified:
- `scripts/tools/production_art_level_builder.gd` (F-001 difficulty identity, F-002 Variant guard, F-003 destination preflight + line-ending-insensitive unchanged detection)
- `tests/run_tests.gd` (V02 test registration + `_run_m21_v02_*` functions)
- `tests/m21_real_art_smoke.gd` (composite generation removed; gameplay assertions unchanged)
- `coordination/sessions/M21-C001/M21_REFERENCE_COMPOSITE.png` (regenerated by the new deterministic generator)
- `TASKS.md` (tracker-only start `3326d0a`, then AWAITING_AUDIT handoff)

Added:
- `tools/build_m21_reference_composite.gd` (F-004 reproducible composite generator)
- `coordination/sessions/M21-C001/CLAUDE_LOG_V02.md` (this file)

No M19/M20 production script changed. `scripts/tools/level_importer.gd`,
`difficulty_rules.gd`, `production_level_validator.gd` unchanged. Owner source PNG
unchanged. `.uid` sidecars not committed. Owner pre-existing local work never
staged.

## 8. Locked-identity rechecks (after all work)

- Owner source: blob `b565743ba52699899007882b750b7c8e7cdd00f9`, SHA-256
  `ede1e02a9096c4c7ba040b91ed7db2d2c2af3b2e20d5c8774068c8d08ad59899` — unchanged.
- M20 `CompleteClearingLoop` blob `06391839523cbc27e88a4b3ef12b730012cd45fa` — unchanged.
- M20 `ScrubbotDispatcher` blob `eee10149e4f116af6706beec832042352bf3a6dd` — unchanged.

## 9. Handoff

No `SB-M21-*` or `SB-UI-014..016` checkbox closed by Claude. No audit file/verdict
authored. Root `TASKS.md` set to `M21 / M21-C001 V02 / AWAITING_AUDIT / CHATGPT`;
progress unchanged 304/719 and 304/943; `lastCompletedTaskId` M20-C001-V11. All
authorized work pushed to `origin/main` without force. Handoff: **AWAITING_AUDIT**.
