# CLAUDE_LOG_V02 — CP06-GAME-DISABLED-LEVELS-C001 (SB-CP06-004 / SB-CP06-010), owner option B

Date: 2026-10-10. Implementer: Claude Code. Prompt: `CHATGPT_PROMPT_V02.md`. Criteria: `CHATGPT_AUDIT_CRITERIA_V02.md`.
Owner decision: `OWNER_DISABLED_FRONTIER_DECISION_V02.md` ("B" — explicit non-rewarding skip).

**Handoff: `IMPLEMENTED_AWAITING_OWNER_TEST_EXECUTION_DECISION`** (= criteria `IMPLEMENTED_PENDING_VALIDATION`).
Code and tests are written and source-reviewed. **No test was executed; nothing below is a PASS.** CP06-004/010 stay OPEN.

## 0. Execution location / zero-TEMP evidence

- All work was done in `C:\Users\sekip\Desktop\ScrubBots` only.
  - No worktree, clone, scratch copy, test cache or `user://` fixture was created.
  - No Godot process was launched (no import, no test, no `--check-only`).
  - No GitHub Actions run was dispatched. Both workflows are `workflow_dispatch`-only, so a push triggers nothing.
  - No APK/IPA build, no R2/Cloudflare call, no LF repo change.
- `gh api` was used read-only to stdout to read LF `m17_release_controls.py::prepare_disable_candidate`. That function writes the **declared** spelling (`declared[item]`) into `disabled_levels`, which is why the game requires an exact match.
- Incidental transient files, disclosed for completeness:
  1. One accidental empty `python - <<'EOF'` here-doc. Git Bash 5.x passes small here-docs through a pipe, but older bash would use a short-lived file in its `/tmp`. Nothing persisted.
  2. One `sed -i` on `tests/cp04_remote_content_runtime.gd`. GNU sed writes a transient `sedXXXXXX` **inside `tests/`** (the Desktop checkout) and renames it over the file. It also stripped CRLF; I restored CRLF in place with `python -c`.
  3. The Claude Code harness keeps its own tool-output files outside the project. That is not a task artefact.
- Pre-existing TEMP disclosed in V01 was not touched or recreated. That covers other-session `wt054`, the Codex worktrees and older session scratch logs.

## 1. Pre/post Desktop state

| | Before | After |
|---|---|---|
| HEAD | `73b0cce8` → `--ff-only` → `58fd2227` (ChatGPT V02 docs) | `58fd2227` + this commit |
| ahead/behind | 0/0 after ff | 0/0 after push |
| `project.godot` SHA-256 | `d2546c0bb7d3daccce6c803252a2bf72ddd2359ee1e61abcaa02ca2b98e63574` | unchanged |
| owner-dirty tracked | 4 (`project.godot`, `scenes/app/main.tscn`, 2× `tests/tools/owner_review/*.tscn`) | same 4, not staged |
| untracked | 2616 | 2616 |
| stashes | 2 | 2 |

Only the files listed in §3 were staged, by explicit path. Storage delta is the new test (~20 KB) plus this log; no other files.

## 2. Design (anchored to existing authorities; no second ledger, no new manifest schema)

| Concern | Implementation |
|---|---|
| Manifest | `ContentManifestV1.parse`: each `disabled_levels` ID must be the **exact** declared spelling of one of the manifest's `levels[].level_id`, else `MANIFEST_DISABLED_LEVEL_NOT_DECLARED`. Existing malformed/casefold-dup → `MANIFEST_INVALID_DISABLED_LEVELS` is kept. Builtin IDs can never be declared (`BUILTIN_ID_COLLISION`), so they can never be disabled. |
| Runtime gate | `RemoteContentManager._refresh_tx`: nonempty `disabled_levels` is accepted. **Nonempty `schedules` → `UNSUPPORTED_RUNTIME_SEMANTICS` (unchanged).** Order, append-only, pack/SHA/identity, monotonic `content_version` and MANIFEST_MUTATION rules are untouched. |
| Registry | `registry_v1.json` `version` 2 = v1 + exact nonempty `disabled_levels`, written only when the set is nonempty, so a registry without disables is byte-compatible with pre-CP06 readers. `parse_registry` reads legacy v1 as an empty set. v2 requires a nonempty exact-declared unique set. Any other shape → corrupt, so no partial activation. The activation is the same single registry rename, so disabled membership commits atomically with the LKG `content_version`. |
| Accessors | `disabled_level_ids()`, `is_level_disabled(id)`, `active_provenance()`. All are empty unless the active set is verified usable, so a missing/corrupt cache, an incompatible build or an unactivated release exposes no disabled membership and **never causes a skip**. |
| Progression | `LevelProgressionService.record_skip(n, id, content_version, manifest_sha256)`. Only the exact current frontier, never a completed or already-skipped level, strict provenance, one order per level identity. Separate `_skipped` ledger. `completed_count()` is still wins only. `record_win` / `debug_set_current_level` are unchanged and unused by the skip. |
| Snapshot | v1 when the ledger is empty (unchanged shape). `scrubbots.progression.v2` adds `skipped: [{level_number, level_id, content_version, manifest_sha256}]` sorted by number. Import rule: `completed ∪ skipped == 1..current_level-1`, disjoint, exact ints, unique numbers and ids (casefold), exact record keys. Anything else fails closed with zero mutation. Legacy v1 imports with an empty ledger. |
| Save | `SaveService.VERSION` = 2 (newest readable), `LEGACY_VERSION` = 1. `collect()` writes 1 without skips and 2 with skips. Pre-CP06 builds (VERSION 1) treat a v2 file as `future_schema`: they refuse it and never overwrite it, so a skip ledger cannot be silently dropped. A v1 file carrying a v2 progression → `progression_schema_version_mismatch`. `migrate` only fills pre-v1 (version 0) saves as before; v1 saves are not rewritten. Backup/temp/rename lifecycle is unchanged. |
| Skip transaction | `AppState.reconcile_disabled_frontier()` handles a frontier that is a verified active **remote** entry whose exact ID is disabled. It snapshots → `record_skip` (bounded by the remote level count, one number at a time) → `request_save()`. **If the save fails, it imports the exact pre-skip snapshot** and returns `skip_save_failed` with nothing reported as skipped. It stops at the first frontier that is not an explicitly disabled remote entry: missing → `CONTENT_MISSING`, builtin → playable. It never touches economy, streak, Daily, achievements, Hearts, cards, robots, boosters or Results. |
| Call sites (idempotent) | `AppState._init` after `content.boot()` (cold/offline boot from the cached LKG; also crash recovery). `AppState._on_content_changed` (new activation). `main.launch_gameplay` before resolve (also retries a failed skip save). `main._bind_terminal` on WON before `nav.on_gameplay_terminal`, so Results/Continue read the post-skip frontier; the host's own economy+save terminal handler has already committed. |
| Launch guard | `GameplayLaunchResolver.resolve` returns `LEVEL_DISABLED` if the frontier entry is disabled. That happens only when a skip save failed; a disabled level is never launched. |
| Daily eligibility | `AppState.orders_context().playable_ahead` no longer counts disabled orders ahead. |
| UX | The Home status line reuses the existing label with "Level 12 unavailable. Continuing at Level 13." (`HOME_LEVEL_SKIPPED`, real numbers). It is a session-only notice, cleared on the next gameplay launch. No ceremony, reward, ad, picker or new art. Results Continue shows the true next level number. **Gap for owner review:** the notice is not shown on Results, and it is not persisted across relaunch. |
| Re-enable | v3 without the ID returns the registry to v1 shape. Already-skipped players keep their ledger and frontier: no rewind, no payout, no replay. Players who had not reached the level play it normally. |
| Cloud save (no SDK wired) | No change. Two copies differing only in the skip ledger have equal completed/tx sets but different authority, so they resolve as `conflict`, which is the safe default. |

## 3. Changed files

- `scripts/content_runtime/content_manifest_v1.gd` — exact declared-subset check.
- `scripts/content_runtime/remote_content_manager.gd` — disabled accepted (schedules still refused), registry v2, accessors.
- `scripts/progression/level_progression_service.gd` — skip ledger, v2 snapshot/import.
- `scripts/save/save_service.gd` — versioning described above.
- `scripts/app/app_state.gd` — `reconcile_disabled_frontier`, `skip_notice`, `orders_context`.
- `scripts/app/gameplay_launch_resolver.gd` — `LEVEL_DISABLED`.
- `scripts/app/main.gd` — two reconcile call sites, notice clear.
- `scripts/ui/home/home_screen.gd`, `scripts/ui/ui_text.gd` — notice text.
- `tests/cp04_remote_content_runtime.gd` — c24 updated. The old pre-B assertion "disabled → UNSUPPORTED" now becomes: schedules still refused with LKG retained; disabled activates v2 with the exact ID. Case renamed `c24_schedules_retain_lkg_disabled_activates` in `EXPECTED`.
- `tests/cp06_disabled_levels.gd` (new) — 16 cases:
  - p01–p05 in-memory:
    - record_skip rules;
    - import matrix with 15 negative cases;
    - save versioning / mismatch / future;
    - manifest subset: unknown / case / builtin / dup;
    - registry v1/v2 matrix.
  - i01–i11 integration:
    - 12→13 with stable 11/12/13 identity and an unchanged economy snapshot;
    - WON into a disabled level then skip;
    - two consecutive skips then CONTENT_MISSING;
    - last level disabled;
    - re-enable for a skipped player versus a fresh player;
    - cold offline boot / crash-window idempotency;
    - save-failure exact rollback, LEVEL_DISABLED, then retry;
    - builtin/unknown/case IDs rejected with LKG kept;
    - offline / tampered pack / corrupt cache never skip;
    - downgrade / mutation / schedules;
    - v2 save reload plus the old-reader guard.
- No `.uid` file was generated for the new test, because that needs Godot. The editor will create it on next open.
- `git diff --check`: clean.
- Not changed: root `TASKS.md`, ChatGPT prompt/criteria/audits, owner-dirty files, art/UI scenes, economy, LF, workflows.

## 4. Tests — executed vs NOT_RUN

**Executed locally: none.** Every Godot run writes at least `user://logs` under `%APPDATA%\Godot\app_userdata\…`, which is outside the Desktop checkout. CP04/CP05/CP06 integration cases also write `user://cp0x_*` fixture roots. Both are prohibited by the owner zero-TEMP rule, and no owner-approved runner exists yet.

| Suite | Status | Command (owner-approved environment only) |
|---|---|---|
| CP06 new | NOT_RUN | `godot --headless --path . -s res://tests/cp06_disabled_levels.gd` |
| CP04 (c24 updated) | NOT_RUN | `godot --headless --path . -s res://tests/cp04_remote_content_runtime.gd` |
| CP05 cache / R01 | NOT_RUN | `-s res://tests/cp05_remote_content_cache.gd`, `-s res://tests/cp05_r01_transaction_cleanup.gd` |
| family fixture | NOT_RUN | `-s res://tests/remote_content_family_fixture.gd` |
| M35 / M37 / M40 / M55 | NOT_RUN | the existing m35*/m37*/m40*/m55* suites |
| root | NOT_RUN | `godot --headless --path . -s res://tests/run_tests.gd` |

Old CI evidence (run `38063215568`, cp04 28/28) is a **pre-B baseline only** and proves nothing about this code.

**Residual risk:** this GDScript was never parsed by Godot. A parse error in a touched runtime file would break boot, so this commit must not ship in any APK/IPA until the suites above pass. While nothing is published, remote content is disabled in the shipped config (`manifest_url` empty), so the new skip path is inert. The save/progression changes are no-ops while the skip ledger is empty: no skips means v1 snapshot and v1 save, byte-identical to before.

Safe options for the owner:
1. Authorize one manual `workflow_dispatch` of the existing Android workflow (it already runs cp04/cp05/root) after adding `cp06_disabled_levels` to its focused-suite list.
2. Authorize a local Godot run with `user://` writes under `%APPDATA%\Godot\app_userdata` for these suites only.
3. Name another runner.

## 5. Handoff

`IMPLEMENTED_AWAITING_OWNER_TEST_EXECUTION_DECISION`. SB-CP06-004/010 OPEN. No online release, APK or IPA. ChatGPT audits and owns root `TASKS.md`.
