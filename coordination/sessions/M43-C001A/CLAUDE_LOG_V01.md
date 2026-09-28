# M43-C001A — CLAUDE LOG V01 — Results foundation + visual-master readiness

Date: 2026-09-28
Actor: Claude (implementer). No audit verdict is claimed.
Prompt: `coordination/sessions/M43-C001A/task_prompts/SB-M43-C001A_RESULTS_FOUNDATION.md`
Criteria: `coordination/sessions/M43-C001A/audit_criteria/SB-M43-C001A_RESULTS_FOUNDATION.md`
Base: fast-forwarded to `origin/main` `5aeeb81`.
Root `TASKS.md` was read only and not edited.

Evidence files:
- `coordination/sessions/M43-C001A/RESULTS_FOUNDATION_MATRIX_V01.md` — architecture, receipt contract, idempotency matrix, sensitivity, reveal/follow-up contracts, per-row status.
- `coordination/sessions/M43-C001A/RESULTS_VISUAL_MASTER_READINESS_V01.md` — asset inventory, missing components/decisions, Replay owner decision, approval checklist.

## Result

The existing M42 Results shell now presents a read-only committed-truth receipt. Nothing was rebuilt as a second authority:
- the gameplay host still commits economy and save at the M30 terminal before navigation enters Results;
- the receipt is built inside that same latched terminal branch, from authoritative before/after service reads plus the committed service results;
- Results never grants.

Continue is exactly-once, attempt-bound, WON-only and safe when there is no next content. LOST Retry is untouched.

Replay was not implemented; the owner decision it needs is written down. The visual master was not approved, and no asset was generated or changed.

## Git / owner work

- `main` was fast-forwarded `023a0fc` → `5aeeb81`; there were no conflicts.
- Pre-existing owner/local items were left untouched and not committed:
  - the `project.godot` modification;
  - untracked `.import`/`.uid` files and level-source PNGs;
  - `_owner_inbox` imports;
  - the other agent's untracked `tests/_m55_diag_tmp.gd`.

## Implementation

| File | Change |
|---|---|
| `scripts/economy/terminal_reward_receipt.gd` (new) | `capture()` is a read-only service probe. `build()` produces the receipt (schema `scrubbots.results_receipt.v1`), including the `reconciled` wallet check, the data-only `reveal_queue` and the committed-diff `follow_ups`. The stored receipt is `make_read_only()`. |
| `scripts/economy/first_clear_transaction.gd` | The success result now also returns `difficulty`, `first_clear` and `streak`, i.e. the committed service results. Commit order, rollback and grants are unchanged. |
| `scripts/economy/win_streak_service.gd` | The result adds `gift_milestones`: the occurrences the Gift feed newly queued. The feed call itself is unchanged. |
| `scripts/gameplay/runtime/production_gameplay_host.gd` | `_drive_economy_terminal` now does four things: <br>1. captures `pre`; <br>2. runs the unchanged WON/LOST commit; <br>3. uses `request_save()` (same boundary as `_flush_durable_save`, but the result is kept); <br>4. builds `_terminal_receipt` only when the terminal latch was taken in this call. <br>Also adds `get_terminal_receipt()` (deep copy). The Retry restore clears the receipt. |
| `scripts/app/main.gd` | `_results_model(payload)` = nav payload + host receipt + `continue {available, reason, next_level}` from `GameplayLaunchResolver`. <br>`continue_from_results(attempt := -1)` now rejects: <br>- `stale_results`: attempt ≠ the shown attempt; <br>- `not_won`: a latent direct-call path that used to launch from LOST Results. <br>If there is no next content, or the launch fails without a transition, it re-shows the same committed model. The nav payload is unchanged. |
| `scripts/ui/results_screen.gd` | `show_model()`, with `show_result()` kept as an M42-compatible wrapper. <br>Reward lines render from `reveal_queue` order, all shown at once, which is the Reduced-Effects-safe path. <br>Notes for already-cleared and next-level-unavailable. <br>The Continue latch is signal `continue_requested(attempt)`. <br>Reward-line nodes are freed when Results is hidden. <br>New getters: `get_model()`, `get_reward_lines_node()`, `get_note_label()`. |
| `scripts/ui/ui_text.gd` | 8 `RESULTS_*` keys; values are live arguments. |

Unchanged:
- Economy V1 numbers;
- Heart and 2x rules;
- First 10 content, supply and difficulty;
- nav routes and payload;
- the Retry transaction;
- `TASKS.md`;
- all assets and manifests.

## Fix found by regression

In the first full run, `m55_long_session` reported: "back at HOME the tree Node count returns exactly to baseline (169 -> 173)".

- **Cause:** the hidden Results kept 4 reward-line Labels.
- **Fix:** `ResultsScreen._notification(NOTIFICATION_VISIBILITY_CHANGED)` frees the lines when hidden.
- **After the fix:** the suite passes with 39 ok, the same count as C002.

## Tests

**New: `tests/m43_c001a_results_foundation.gd`** — exit 0, 66 ok, case ledger 11/11. It runs on the real `main.tscn`, AppState, host terminal and ResultsScreen.

| Case | Proves |
|---|---|
| receipt_matches_commit | Real Level 1 drain. <br>- The receipt equals the committed components, the wallet delta, streak 0→1, frontier 1→2, Gift 0→1 and saved. <br>- The reveal order is first_clear_sb, win_streak_sb, bot_parts, gift_meter. <br>- There are no follow-ups. <br>- The model binds the receipt and next frontier 2. <br>- 4 lines are shown at once. <br>- Getters return detached copies. |
| already_cleared_and_rollback | Non-frontier WON through the real host gives `already_cleared` and 0 reveals, with economy/progression untouched and the note shown. <br>A fault-injected streak stage gives `rolled_back`/`streak` and 0 grants. |
| duplicate_terminal_open_refresh | 5× terminal signal, 5× host handler, 5× `show_model` and 5× route handler cause no change to the receipt, economy, progression or reward tx count, and no extra save or transition. |
| rapid_continue_once | 10 same-frame taps give 1 intent. 5 late direct calls are refused. <br>Result: 1 transition, 1 host, attempt 2, and the launched level equals `receipt.frontier.after`; 0 economy change. |
| stale_continue_rejected | An attempt-1 Continue during attempt-2 Results is refused, then attempt 2 is accepted once. LOST Results return `not_won`. |
| level10_no_next_content | L10 first clear. The model shows `CONTENT_MISSING`/11. <br>Continue is disabled with the note shown. Taps are no-ops and a direct call returns `no_next_content`. <br>There is no mutation or transition, the host is kept, and HOME works. |
| gift_milestone_handoff | Gift progress seeded at 9; the win takes it to 10. <br>- There is one `gift_milestone` follow-up, and the reveal lists `milestones [10]`. <br>- The milestone is queued unclaimed; the wallet is reconciled. <br>- A refresh does not claim it. The canonical Gift Bar claim grants exactly once. |
| follow_ups_authoritative_only | No state change gives no follow-ups. A real robot unlock gives `robot_unlock` only. <br>There is no feature/world emitter, and the receipt is read-only. |
| lost_retry_regression | The LOST receipt shows −1 Heart and streak 0, with no reveal. <br>RETRY runs on the same host with attempt 2, the receipt is cleared and no second Heart is taken; the board is ACTIVE and PLAYING. |
| m42_contract_preserved | The nav payload is still exactly `{status, level, attempt}`. Legacy `show_result` works, and ERROR shows HOME only. |
| results_never_grants_source | 0 grant/commit API references in `results_screen.gd`, `main.gd` and `terminal_reward_receipt.gd`. |

Sensitivity: 4 guard mutations, each re-run and then restored; the table is in matrix §3. Every one fails the suite: 2 / 1 / 2 / 3 FAIL lines.

## Regression (Godot 4.7.2.stable.official.ed1daf0bf, headless, 12-way parallel, final code)

| Suite group | Result |
|---|---|
| `m43_c001a_results_foundation` (new) | exit 0, 66 ok |
| M30: `m30_completion_authority` / `m30_manual_playtest_smoke` / `m30_transaction_safe_retry` | exit 0, 52 / 49 / 76 ok |
| M37: `m37_level_progression` / `_v02_strict` / `_v03_forward_only` | exit 0, 40 / 30 / 29 ok |
| M38: `m38_win_streak` / `m38_v02_strict` | exit 0, 49 / 43 ok |
| M39: `m39a` / `b` / `c` / `d` / `e` | exit 0, 38 / 32 / 45 / 34 / 21 ok |
| M39: `v02_atomicity` / `_capacity` / `_integration` | exit 0, 21 / 19 / 34 ok |
| M39: `v03_full_surface` / `_integration` | exit 0, 37 / 18 ok |
| M39: `v04_integration` / `_tornado_inflight` | exit 0, 150 / 132 ok |
| M40: `m40_save_system` / `_v02_safety` / `_v03_canonical` / `_v04_bootstrap` | exit 0, 38 / 34 / 21 / 58 ok |
| M41: `m41_settings` | exit 0, 138 ok |
| M42: `m42_navigation` / `m42_home` / `m42_opening` / `m42_assets` | exit 0, 82 / 224 / 70 / 40 ok |
| M42: `m42_home_composition` / `_v04` / `_v05` / `_v06` / `_v07_safe_area` | exit 0, 23 / 99 / 88 / 94 / 47 ok |
| M52: `m52_r01_parallel_runtime` / `m52_r02_early_slot_release` | exit 0, 79 / 65 ok |
| M52: `m52_owner_supply_plans` | exit 0, 255 ok (9/9 WON) |
| M53: `m53_first10_difficulty` / `m53_c002_difficulty_calibration` | exit 0, 315 / 214 ok |
| M54: `m54_collection_set_master_exactly_once` | exit 0, 192 ok |
| M55: `m55_core_chaos` / `m55_long_session` / `m55_c002_timed_2x_anti_rollback` | exit 0, 129 / 39 / 53 ok |
| M55: `m55_heart_900_authority` / `m55_economy_release_regression` | exit 0, 19 / 11 ok |
| root `tests/run_tests.gd` | exit 0, **5323 checks, RESULT: ALL PASS** |
| `git diff --check` | clean |

Totals: 0 `FAIL:` lines and 0 `SCRIPT ERROR`. The engine `ERROR:` classes are identical to the C002 baseline:
- "N resources still in use at exit";
- M52's intentional malformed-JSON fixture;
- the root suite's intentional corrupt/missing-image fixtures.

No new class appeared.

`m30_transaction_safe_retry` prints `REBUILD-FAIL:` inside its `ok:` lines. These are passing assertion labels, not failures (exit 0).

## Owner gates left open

- **Replay (SB-M43-006/011):** the six decisions are listed in readiness §5. No Replay button, launch path or economy rule was added.
- **Visual master (SB-M43-009):** `victory_results` stays `MASTER_REQUIRED`. The missing Life/Help-family chrome, CTA and crest choices, pose rule and choreography are listed in readiness §4/§6.
- **Ordered celebration (SB-M43-010):** only the data order is fixed. Timing and animation are owner-gated.

## Changed files

- `scripts/economy/terminal_reward_receipt.gd` (new)
- `scripts/economy/first_clear_transaction.gd`
- `scripts/economy/win_streak_service.gd`
- `scripts/gameplay/runtime/production_gameplay_host.gd`
- `scripts/app/main.gd`
- `scripts/ui/results_screen.gd`
- `scripts/ui/ui_text.gd`
- `tests/m43_c001a_results_foundation.gd` (new)
- `coordination/sessions/M43-C001A/RESULTS_FOUNDATION_MATRIX_V01.md` (new)
- `coordination/sessions/M43-C001A/RESULTS_VISUAL_MASTER_READINESS_V01.md` (new)
- `coordination/sessions/M43-C001A/CLAUDE_LOG_V01.md` (this file)

## Reproduce

```bash
godot --headless --path . -s res://tests/m43_c001a_results_foundation.gd
```

`AWAITING_CHATGPT_AUDIT / M43-C001A RESULTS FOUNDATION`
