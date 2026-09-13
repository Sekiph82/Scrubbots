# M21-C001 V03 — Claude Implementation Log

Cycle: `M21-C001` V03 — final path-safety + direct-evidence reconciliation.
Actor: Claude (implementer/test runner). Auditor: ChatGPT (independent).
Repository: `Sekiph82/Scrubbots`, branch `main`. Handoff: `AWAITING_AUDIT`.
Engine: Godot `4.7.1.stable.official.a13da4feb`.

Surgical final pass: close the single F-M21-STRICT-003 path-resolution residual and
the enumerated direct-evidence cells. F-M21-STRICT-001/002/004 accepted CLOSED and
not reopened. Runtime results are Claude E1/E2 evidence.

## 0. Safe sync + preserved owner/local work

- Synchronized starting base: local `00efae2…` fast-forwarded to `origin/main`
  `6dc77fe…` via `git rebase --autostash origin/main` (0 ahead / 3 behind; incoming
  = V02 audit + V03 prompt/criteria). Confirmed the incoming set did not touch the
  owner's locally-modified files before syncing.
- Preserved owner/local work (autostash reapplied, never dropped/reset/restored):
  `project.godot`, `scenes/debug/routing_prototype_lab.tscn`,
  `scenes/debug/scrubbot_agent_debug.tscn` (unstaged), plus untracked owner inbox
  `.import`, `docs/logs/`, `*.uid`. None staged.
- No `.hiveai` tracker recreated. GitHub-only logging.

## 1. Tracker-only V03 start commit

Updated only root `TASKS.md` Project Status to
`M21 / M21-C001 V03 / IN_PROGRESS / CLAUDE` (progress unchanged 304/719 and
304/943; `lastCompletedTaskId` M20-C001-V11).

**Tracker-only start commit (only `TASKS.md`): `af3a33b7a7c34f66e3efef1ed817cccc03968c95`.** Pushed to `origin/main` before any implementation/test edit.

## 2. Scope

F-M21-STRICT-003 residual (one path resolver) + the enumerated direct-evidence
cells only. No M19/M20 gameplay code, no `difficulty_rules.gd` /
`production_level_validator.gd` / generic M09 importer redesign, no Difficulty V1 /
Level Factory / PixelLab / M22+ UI / scoring / progression. No M21/UI checkbox
closed. Protected identities unchanged (see §8).

## 3. F-M21-STRICT-003 residual closure

Root cause (V02): `_check_aliases` used `_canon()` (bare-relative based at `res://`),
but `_preflight_destination()` used `ProjectSettings.globalize_path(raw)` with no
bare-relative→`res://` base — two path identities in one write path (AL-013).

Correction (`scripts/tools/production_art_level_builder.gd`):

| Element | Change |
| --- | --- |
| One resolver | New `_resolve_physical(p)`: normalize separators; `res://`/`user://`→globalize; bare-relative→`globalize("res://"+p)` (never CWD); absolute kept; lexical `.`/`..` simplified; case preserved for I/O. |
| Comparison identity | `_canon(p)` now = `_resolve_physical(p)` + Windows case fold — comparison only, never used as a physical I/O path. |
| Preflight | `_preflight_destination()` now resolves via `_resolve_physical()` (same contract as alias identity) for dir-at-path, parent existence and parent-type checks. |
| Planning + writes | `build()` computes `_resolve_physical()` for output/preview/metadata once and uses those resolved absolute paths for `_plan_text`/`_plan_image` and the actual writes, keeping the caller's logical strings only for metadata/errors — so a destination can never be judged as one physical location and written to another. |

The audited generic M09 importer was not modified.

## 4. Direct path-safety matrix (`_run_m21_v03_path_safety_tests`, new builder)

| Cell | Evidence |
| --- | --- |
| bare-relative output/preview/metadata resolve at the `res://` equivalent | build under `res://coordination/sessions/M21-C001/_v03_tmp` via bare-relative strings; files asserted present at the `res://` equivalent, not CWD |
| bare-relative rerun UNCHANGED | second bare-relative build reports output/preview/metadata UNCHANGED |
| bare-relative source-equivalent output alias rejected | rejected; source bytes unchanged |
| bare-relative vs `res://` destination alias | rejected |
| bare-relative vs absolute destination alias | rejected |
| dot-segment equivalent alias | rejected |
| `overwrite=true` source alias | still rejected |
| existing-different preview `overwrite=false` | rejected before output/metadata written |
| existing-different metadata `overwrite=false` | rejected before output/preview written |
| directory at metadata path (overwrite false & true) | rejected before earlier mutation |
| directory at output path (overwrite false & true) | rejected |
| non-directory parent | rejected before any write |
| bare-relative later preview missing parent | rejected before earlier output written (no partial commit) |
| owner source immutable | git blob SHA1 re-asserted equal across every path case |

Temporary test artifacts are created only under a self-made `_v03_tmp` project dir
and removed at test end; no owner/local or canonical file is modified.

## 5. Fresh real-art direct-evidence matrix (`_run_m21_v03_direct_evidence_tests`)

Fresh committed-LevelData + real production collaborators (no M20 fault seams):

- 400 cells ACTIVE; exact fresh candidate counts C01=30, C03=5, C08=298, C11=11, C16=56.
- Blocked non-C08 (C11) activation returns exactly `NO_REACHABLE_TARGET`; BoardState,
  all five candidate buckets, reservation count, dispatcher active count and loop
  cleared count all proven exactly unchanged.
- Fresh C08 dispatch via real selector/access/routing/dispatcher/agent: target C08 +
  ACTIVE, exact reservation target↔owner, dispatcher owns the assignment, agent
  MOVING — all before arrival.
- Authenticated arrival: cleared_count +1 exactly; target CLEARED; candidate bucket
  no longer contains the target; reservation target→owner AND owner→target released;
  dispatcher no longer owns the owner and active count decremented by one; renderer
  alpha 0 for that cell — all observed on the actual returned target/owner.
- Continued real clears until an initially-blocked non-C08 color became reachable and
  cleared through the real path (no forced target, no fake candidate, no seam).

## 6. Required commands and actual results

| # | Command | Result |
| --- | --- | --- |
| 1 | `godot --version` | `4.7.1.stable.official.a13da4feb` |
| 2 | `godot --headless --path . -s res://tests/run_tests.gd` | **4534 checks, 0 failures, ALL PASS** (V02 baseline 4475 + 59 V03) |
| 3 | `tests/m21_real_art_smoke.gd` (fresh process) | PASS — 400 clears, 5 colors, exact clean final state; headless CPU diagnostic only (AL-003) |
| 4 | M20 queue-free + V04/V05/V07/V08/V09/V10 lifecycle smokes | all PASS |
| 5 | headless boot `scenes/debug/m21_real_art_vertical_slice.tscn --quit-after 5` | boots, 0 SCRIPT/Parse errors |
| 6 | `tools/build_m21_level.gd` rerun | LEVEL/PREVIEW/METADATA all UNCHANGED |
| 7 | `tools/build_m21_reference_composite.gd` x2 | run 1 UNCHANGED, run 2 UNCHANGED (488x160) |
| 8 | owner source blob + SHA-256 recheck | blob `b565743…`, sha256 `ede1e02…` — unchanged |
| 9 | M20 loop/dispatcher blob recheck | loop `06391839…`, dispatcher `eee10149…` — unchanged |
| 10 | scan required outputs for `SCRIPT ERROR` / `Parse Error` | 0 |
| 11 | `git diff --check` | clean (only benign owner/local + LF-authored artifact line-ending advisories) |

Root-suite at-exit leak warnings are pre-existing baseline behavior (identical with
M21 disabled); V03 adds none.

## 7. Sensitivity / load-bearing (prompt §7)

- **Bare-relative success:** files are asserted at the `res://` equivalent; if
  `_preflight_destination` lost the `res://` base again, the bare-relative build would
  resolve/parent-check against the CWD and fail (parent not found), failing the test.
- **Equivalent-path aliases:** alias comparison and preflight now share
  `_resolve_physical`; if the two identities diverged, the bare-relative vs
  `res://`/absolute alias tests would stop rejecting and fail.
- **Preview/metadata conflict:** each asserts the earlier artifact(s) absent; any
  earlier mutation before the later failure would fail those assertions.
- **Metadata-directory:** arranged so that without final-object-type preflight the
  earlier output would be written before the later directory failure; the test asserts
  the output is absent.
- **Fresh candidate counts:** read from real committed LevelData/BoardState via the
  real ColorCandidateIndex, not hardcoded fakes.
- **First-arrival cleanup:** observed on the actual returned `target_index`/`owner_id`,
  not only end-of-level aggregates.

## 8. Exact changed files + locked-identity rechecks

Modified:
- `scripts/tools/production_art_level_builder.gd` (single `_resolve_physical` resolver; `_canon` built on it; `_preflight_destination` + planning/writes routed through resolved physical paths)
- `tests/run_tests.gd` (V03 test registration + `_run_m21_v03_path_safety_tests`, `_run_m21_v03_direct_evidence_tests`)
- `TASKS.md` (tracker-only start `af3a33b`, then AWAITING_AUDIT handoff)

Added:
- `coordination/sessions/M21-C001/CLAUDE_LOG_V03.md` (this file)

No M19/M20 production script, `difficulty_rules.gd`, `production_level_validator.gd`,
generic `level_importer.gd`, owner source PNG, level JSON/preview/metadata, or
reference composite changed by V03. `.uid` sidecars not committed. Owner local work
never staged.

Rechecks after all work:
- owner source blob `b565743ba52699899007882b750b7c8e7cdd00f9`, SHA-256 `ede1e02a9096c4c7ba040b91ed7db2d2c2af3b2e20d5c8774068c8d08ad59899` — unchanged;
- `CompleteClearingLoop` blob `06391839523cbc27e88a4b3ef12b730012cd45fa` — unchanged;
- `ScrubbotDispatcher` blob `eee10149e4f116af6706beec832042352bf3a6dd` — unchanged.

## 9. Handoff

Claude closed no `SB-M21-*` / `SB-UI-014..016` checkbox and authored no audit
verdict/file. Root `TASKS.md` set to `M21 / M21-C001 V03 / AWAITING_AUDIT / CHATGPT`;
progress unchanged 304/719 and 304/943; `lastCompletedTaskId` M20-C001-V11. All
authorized work pushed to `origin/main` without force. Handoff: **AWAITING_AUDIT**.
