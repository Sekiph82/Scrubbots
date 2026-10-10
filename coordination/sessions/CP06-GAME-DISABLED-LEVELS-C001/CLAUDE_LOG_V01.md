# CLAUDE_LOG_V01 — CP06-GAME-DISABLED-LEVELS-C001 (SB-CP06-004 / SB-CP06-010)

Date: 2026-10-10. Implementer: Claude Code. Repo `Sekiph82/Scrubbots`, branch `main`.
Verdict handed off: **`OWNER_DECISION_REQUIRED_FOR_DISABLED_FRONTIER`** (Gate A blocks).
No gameplay/runtime code changed. This log is the only file committed. Not a self-awarded PASS.

## 0. Owner override (2026-10-10 21:46 +03) — Desktop only / zero TEMP

The prompt was corrected in place (`2ca18c63`, `1dd47217`, `0cfd881c`, `b3c9bea3`) and the owner
re-issued it in chat with "STOP before creating any TEMP files or worktrees". Per updated
`CLAUDE.md` §0A, that section wins over the original step 2 (sparse TEMP worktree); noted here as required.

### Disclosure: TEMP created before the correction reached this session

I read the original prompt at `896f0966`. Before the owner chat override arrived, I had created:

| Path | Size | State | Action |
|---|---|---|---|
| `C:/Users/sekip/AppData/Local/Temp/claude/C--Users-sekip-Desktop-ScrubBots/b6966355-d22b-4cc1-8033-eeec327dab7f/scratchpad/wtCP6` (sparse detached worktree @ `896f0966`) | 656 MB | clean (`git status` empty), never imported, never edited, only read | removed with non-force `git -C <Desktop> worktree remove` (task-owned, verified clean) |
| `.../scratchpad/wtCP6.log` | 44 B | worktree-add output | deleted |
| `.../scratchpad/lf/` (read-only copies of 4 published LF docs/scripts) | 100 KB | reference only | deleted |

After the override: **zero** new TEMP files, worktrees, clones or copies were created. No Godot
process was launched at all (no import, no test run), so no `user://` / `.godot` artefacts were written either.

Not touched (not created by this task; ownership/authorisation not established):
- `.../fbe85cde-0fe6-4d11-a66b-b183f13e11c6/scratchpad/wt054` (worktree from a different Claude session, `cbb1592d`).
- Three Codex worktrees under `C:/Users/sekip/.codex/worktrees/`.
- Older scratchpad logs/probes from earlier tasks in this session (M43 Phase4/5, M55, M47), ~17 MB total, no worktrees. Left in place pending owner instruction.

Harness note: the Claude Code tool runner itself stores command output under `AppData/Local/Temp/claude/.../tasks/`; that is outside my control and not a task artefact.

## 1. Pre/post state (Desktop `C:\Users\sekip\Desktop\ScrubBots` only)

| | Before | After |
|---|---|---|
| HEAD | `72514849` → ff `896f0966` (Gate 0) → ff `b3c9bea3` (owner correction) | `b3c9bea3` + this log commit |
| ahead/behind origin/main | 0/0 after each ff | 0/0 after push |
| `project.godot` SHA-256 | `d2546c0bb7d3daccce6c803252a2bf72ddd2359ee1e61abcaa02ca2b98e63574` | unchanged |
| owner-dirty tracked | 4 (`project.godot`, `scenes/app/main.tscn`, 2× `tests/tools/owner_review/*_owner_review.tscn`) | same 4, untouched |
| untracked | 2616 | 2616 + 0 (log is committed) |
| stashes | 2 | 2 |

Only `--ff-only` merges, no reset/clean/restore/checkout/stash/force. Only this log was staged by explicit path.

## 2. Contract read (Level Factory, published GitHub `Sekiph82/ScrubBots-Level-Factory`)

- M17 / CP06 master prompt: game-side disable/schedule runtime is `EXTERNAL_GAME_RUNTIME_PENDING` (SB-CP06-004/010).
- SB-CP02-006 `disabled_levels`: manifest metadata only. "Do not implement Godot skip behavior; M17/M15 own runtime handling."
- `m17_release_controls.py::prepare_disable_candidate`: publisher-side subset check (each disabled ID, casefolded, must be a declared level); successor manifest keeps pack bytes and level entries and only adds the ID to `disabled_levels`.
- Nowhere in LF or in the game owner decisions is there a rule for what the player experiences when the disabled level is their **current frontier**.

## 3. Current game behaviour (the reproduction)

Source at `b3c9bea3` (identical to CI source `c2b1c3c7` for `scripts/content_runtime`, `scripts/progression`,
`scripts/app`, `tests/cp04_remote_content_runtime.gd` and `tests/support/scrubpack_fixture.gd`, checked with `git diff --stat c2b1c3c7 HEAD`, which was empty):

1. `content_manifest_v1.gd:125` checks `disabled_levels` syntax only: valid `level_id` and no casefold duplicates. It does **not** check that each ID is a subset of the declared levels.
2. `remote_content_manager.gd:311-313`: any successor manifest with a nonempty `disabled_levels` (or `schedules`) is rejected **whole** with `UNSUPPORTED_RUNTIME_SEMANTICS`, and the LKG registry stays active.
3. As a result, the disabled level (e.g. remote Level 12) **stays playable** from the old LKG. Any other change in that same release, including appended levels, is also rejected.
4. Existing synthetic test `tests/cp04_remote_content_runtime.gd::_c24` (`c24_disabled_schedules_retain_lkg`) asserts exactly this using `scrubpack_fixture.gd` + FakeTransport: v1 is activated, the v2 successor with `disabled_levels:["fam_l011"]` is rejected `UNSUPPORTED_RUNTIME_SEMANTICS`, `content_version` stays 1 and 1 remote level is retained.
5. Evidence that it executes: GitHub Actions run `38063215568` (source `c2b1c3c7`), step "Focused suites": `cp04_remote_content_runtime exit=0 ... PASS (28/28 cases, 0 fail)`, plus `run_tests exit=0 RESULT: ALL PASS`.

I did **not** re-run it locally. The CP04/CP05 suites write their fixture roots under `user://cp04_*` / `user://cp05r01_*`, which on Windows is `%APPDATA%\Godot\app_userdata\...`, outside the Desktop checkout. Running them would break the zero-TEMP rule (prompt: "If a test requires filesystem test artifacts outside this one project folder, do not run that test"). Because Gate A blocks, no new runtime test was needed.

## 4. Gate A — why a disabled frontier cannot be skipped under existing authority

Take a player whose `current_level == 12`, where 12 is remote `fam_l012`, which is disabled in N+1.

| Possible skip mechanism | Conflict with existing owner-locked authority |
|---|---|
| Advance the frontier via `record_win(12)` | Fake WON. It would trigger win streak, rewards and first-clear. Forbidden by the prompt. |
| Advance `_current_level` without a win | `level_progression_service.gd:127-137` (M37 V03, F-M37-V02-002) requires the completed set to be **exactly contiguous 1..current_level-1**, or the import fails closed. A skipped 12 makes every later save fail to load. Fixing that needs a new save schema / second ledger. Forbidden without the owner. |
| Drop 12 from `CompositeLevelCatalog` | `composite_level_catalog.gd:34` assigns `order = max_order + 1 + index`, so 13 would become "Level 12". That is the forbidden "Level N plays N+1" remap, and it breaks the canonical identity of 13 and of every saved frontier above it. |
| Use `debug_set_current_level` | Non-shipping test seam (`level_progression_service.gd:37`). Forbidden. |
| Let the player choose another level | Owner M37: forward-only, no Level Select. |

Disabled levels **behind** the frontier have no player-visible effect today (no replay, no level select). Disabled levels **ahead of** the frontier only matter once reached. So the whole question collapses to the frontier case, and no existing owner rule covers it.

**Result: `OWNER_DECISION_REQUIRED_FOR_DISABLED_FRONTIER`.** Per prompt step 4/5, nothing was implemented. `record_win()`, the save schema, the catalog, the resolver and the manifest manager are unchanged.

## 5. Proposed minimal owner policies (pick one)

### Option A — HOLD at the frontier (recommended: smallest, reversible, no save change)

- The manifest manager accepts a nonempty `disabled_levels` only when it is a subset of the declared **remote** level IDs: exact identity, no builtin IDs, no duplicates. Any other set is rejected `MANIFEST_INVALID_DISABLED_LEVELS` and the LKG is kept.
- The effective disabled set is stored atomically in the same registry transaction as the LKG `content_version`. It survives offline/cold boot. The pack files, SHA, order and IDs of every level stay byte-identical.
- `CompositeLevelCatalog` keeps the disabled entry at its order (no renumbering) and flags it `disabled`.
- `GameplayLaunchResolver` returns a new non-rewarding reason, `LEVEL_DISABLED`, for that order. It does not mutate the save, call `record_win` or grant anything.
- Home shows the frontier as temporarily unavailable. **Owner must approve the player-facing copy/UI** (e.g. "Level 12 is getting a tune-up — check back soon").
- Re-enable: successor N+2 omits the ID and the level is playable again at the same number. The frontier never moved, so no history is lost.
- Impacts:
  - A player on that frontier is blocked until re-enable or until a later release changes it.
  - Daily Scrub Orders "playable from frontier" counting must treat disabled levels as unplayable.
  - No change to M37/M40 save, rewards, win streak or Collection.
  - Builtin 1–10 are unaffected (builtin IDs are never disableable).

### Option B — explicit non-rewarding SKIP (requires a save-schema decision)

- New explicit transition, for example `advance_past_disabled_frontier(level, content_version)`. It advances `current_level`, writes no completion, grants no SB/Heart/Gift/robot/card, and applies no win-streak change. **The owner must decide whether the streak is preserved or reset.**
- It requires a versioned save-schema migration: a `skipped` set, plus the M37 import rule becoming `completed ∪ skipped == 1..cur-1`, with a migration and fail-closed tests.
- "Level 12" is shown as skipped; Level 13 keeps its number.
- **Owner must decide re-enable after skip:** with no level select, a re-enabled 12 is unreachable forever unless a replay/catch-up rule is added.
- Impacts: M37/M40 save and import, cloud/backup compatibility, any reward/unlock keyed to level counts, analytics, Daily Orders, and new audit surface.

### Option C — LF-side in-place replacement (requires an LF/owner rule)

The publisher ships a fixed replacement at the same order. Today the game rejects this as a sequence/identity change (`REMOTE_SEQUENCE_NOT_APPEND_ONLY` / identity checks). It would need an owner rule on level-identity replacement, so it is noted only for completeness.

### Interim operational note for LF / publisher (no game change)

Until CP06 lands, the game rejects the **entire** manifest when `disabled_levels` is nonempty. A disable published together with new appended levels therefore also blocks those levels. Publish disables separately, or not at all, until CP06 is implemented.

## 6. Changed files / checks

- Changed: `coordination/sessions/CP06-GAME-DISABLED-LEVELS-C001/CLAUDE_LOG_V01.md` (new). Nothing else.
- Not touched: root `TASKS.md`, ChatGPT prompt/criteria/audits, game source, tests, UI/art, LF repo, R2 (zero Cloudflare calls), APK/IPA (no build triggered).
- M55 `c997ca65` was not repeated.
- `git diff --check` on the staged log: clean (see commit).
- No focused suites were run, because Gate A blocked and zero-TEMP forbids `user://` fixture roots. If the owner picks Option A, the implementation prompt needs an owner-approved way to run the CP04/CP05-style suites. They inherently write `user://` fixture roots (AppData), which the zero-TEMP rule currently forbids. Two possibilities: approve `user://` for test roots, or redirect them under a permanent ignored project path.

## 7. Handoff

`OWNER_DECISION_REQUIRED_FOR_DISABLED_FRONTIER`. SB-CP06-004/010 are **not** closed. ChatGPT performs the independent audit and updates root `TASKS.md`.
