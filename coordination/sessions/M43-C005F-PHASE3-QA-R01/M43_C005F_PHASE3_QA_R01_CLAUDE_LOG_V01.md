# M43-C005F-PHASE3-QA-R01 — Pack Route Sampling Deflake — CLAUDE_LOG_V01

- Prompt: `coordination/sessions/M43-C005F-PHASE3-QA-R01/M43_C005F_PHASE3_QA_R01_PROMPT_V02.md`
- Criteria: `coordination/sessions/M43-C005F-PHASE3-QA-R01/M43_C005F_PHASE3_QA_R01_AUDIT_CRITERIA_V01.md`
- Engine: Godot 4.7.2.stable.official.ed1daf0bf
- Starting SHA: `08f12af9e7a5cc618baf873095df3881709909e0` (`origin/main`)
- Final SHA: the commit that adds this log. The tests and this log are in one commit; parity is reported in the hand-off.
- This is a TEST-ONLY remediation. There is no production source change.

## 0. Gate 0 — owner Desktop safety

Every git command used an explicit absolute path (`git -C "<abs>"`), and every Godot command used `--path "<abs>"`. No `cd … ; <command>` chains were used.

### Before

Persistent `C:\Users\sekip\Desktop\ScrubBots`:

| Item | Value |
|---|---|
| HEAD | `89157ecb` |
| `origin/main` after `git -C … fetch --prune origin` | `08f12af9` |
| Ahead / behind | 0 / 7 |
| Tracked dirty | `project.godot`, `scenes/app/main.tscn`, `tests/tools/owner_review/premium_pack_owner_review.tscn`, `tests/tools/owner_review/standard_pack_owner_review.tscn` |
| Untracked | 2932 |
| `project.godot` SHA-256 | `6a08a4779d7be957a38417e2e3c7185b75cb0f56412cdd1ddf306d9f749ac922` (1222 bytes, mtime 2026-10-09 13:05:18) |

### Reconcile

- The incoming 7 commits touched only `TASKS.md` and coordination docs.
- `git -C … merge --ff-only origin/main` succeeded. Result: HEAD = `08f12af9`, **0/0**.
- `project.godot` SHA-256 was unchanged after the fast-forward.
- No checkout, restore, reset, clean, stash or force was run against Desktop.

### TEMP worktree

`git -C <Desktop> worktree add --detach <scratchpad>/qawt origin/main`.

The first attempt **failed: the C: drive was full** (952 of 953 GB used; "No space left on device").
- Git rolled back the partial worktree itself, so nothing was left registered.
- I did **not** fall back to the Desktop checkout, and I deleted nothing of the owner's.
- After free space recovered (32 GB available; the space was freed outside this task), the worktree was re-created and verified: `project.godot` present, clean status, HEAD `08f12af9`.
- All implementation and tests then ran only in that TEMP worktree. Its own `project.godot` was restored after `--import` with `git -C "<TEMP>" checkout -- project.godot`, after printing the absolute target.

## 1. Defect

Standard `v07` and Premium `p12` sampled `cv.route` once per `process_frame` and required at least one frame with `0 < route < 1` for every card.
- A loaded headless scheduler can step a card from route 0 straight to 1 between two frames.
- That produced a false FAIL. It was observed about 1 in 5 runs, also on untouched baseline code (Phase 3 log §4).
- Premium `p12` also required the frame-sampled concurrency maximum `== 1`, which fails the same way: 0 cards sampled in flight.

## 2. Fix (TEST-ONLY)

### New `tests/support/pack_route_probe.gd`

A shared helper; both suites need the identical observation.

- `probe(cv)` drives the **production** `CardView.route` setter to `0.5` (ease-out `t = 0.75`, alpha 1), reads the face centre and visibility, and restores `route = 0.0`.
  - Route `< 1` never emits `arrived`, so the real routing that follows starts from exactly the same state.
  - Restoration is asserted: face centre back within 0.01 px, `route == 0`.
- `mid_ok(slot, start, own, other, mid)` is the travel predicate. All of these must hold:
  - the point is **on the slot → own-destination segment** (perpendicular ≤ 2 px);
  - it is strictly inside the segment (fraction 0.05–0.95, > 2 px from either end);
  - it is closer to its own destination than the start;
  - it is **not** on the slot → other-destination path.
- `rejects_misroutes()` is the **sensitivity proof**. The predicate must reject three synthetic mis-routes for each card's real slot and destinations:
  - stuck at the slot;
  - jumped to the destination;
  - the same eased travel aimed at the **other** destination.

### Standard `v07`

1. Before Tap 2, every card is probed. It must be visible, strictly between its slot and its OWN NEW/DUPLICATE destination, closer than the start, and restored.
2. The sensitivity check must pass for every card.
3. Then the **real** Tap 2 routing runs, and these existing truths are asserted:
   - exact route log `[[0,collection],[1,exchange],[2,collection]]`;
   - route end points equal the destination icon centres.
4. **New:** every card's own `arrived` signal fired exactly once, in draw order `[0,1,2]` (event-driven).

### Premium `p12`

1. The same probe and sensitivity checks run for all 5 cards.
2. The real Tap 2 then asserts:
   - exact route log `[[0,c],[1,x],[2,c],[3,x],[4,c]]`;
   - end points;
   - arrivals `[0,1,2,3,4]`.
3. Serialization is now proven **event-driven**: at each card's `arrived` signal, every earlier card has `route ≥ 1` and every later card has `route == 0`, so exactly one card is in flight, independent of frame sampling.
4. The frame-sampled maximum is kept as an extra guard (`≤ 1`: never two in flight).

### What I did not do

- No change to ROUTE timing, tweens, easing or sleeps.
- No production hooks or test branches in shipping code.
- No destination or arrival assertion was loosened or removed.
- Nothing is end-state-only.
- No retry loops.

## 3. Production freeze — SHA-256 before / after

| File | SHA-256 before | SHA-256 after | Identical |
|---|---|---|---|
| `scripts/ui/ceremony/standard_pack_ceremony.gd` | `f0dd9f371a58bb8bd0d5b8d0144d7f49517ed84d151afea48f455606f33bb420` | `f0dd9f371a58bb8bd0d5b8d0144d7f49517ed84d151afea48f455606f33bb420` | yes |
| `scripts/ui/ceremony/premium_pack_ceremony.gd` | `59a22cacf85e9d38179dcef8cb5c0e87693e51877c063eca9b88448d16180de1` | `59a22cacf85e9d38179dcef8cb5c0e87693e51877c063eca9b88448d16180de1` | yes |
| `scripts/ui/components/reveal_sequencer.gd` | `3c09876237c23e8c9250bf2a4869449fd86b66b6fa09b1f298cfbb500e023f20` | `3c09876237c23e8c9250bf2a4869449fd86b66b6fa09b1f298cfbb500e023f20` | yes |

## 4. Stability gate (final implementation, fresh sequence)

Ten consecutive runs each, in the TEMP worktree, with no retries:

| Suite | Run | Exit | Result |
|---|---|---|---|
| `m43_c005_c006_standard_pack_presentation` | 1 | 0 | PASS (21/21 cases, 0 fail) |
| `m43_c005_c006_standard_pack_presentation` | 2 | 0 | PASS (21/21 cases, 0 fail) |
| `m43_c005_c006_standard_pack_presentation` | 3 | 0 | PASS (21/21 cases, 0 fail) |
| `m43_c005_c006_standard_pack_presentation` | 4 | 0 | PASS (21/21 cases, 0 fail) |
| `m43_c005_c006_standard_pack_presentation` | 5 | 0 | PASS (21/21 cases, 0 fail) |
| `m43_c005_c006_standard_pack_presentation` | 6 | 0 | PASS (21/21 cases, 0 fail) |
| `m43_c005_c006_standard_pack_presentation` | 7 | 0 | PASS (21/21 cases, 0 fail) |
| `m43_c005_c006_standard_pack_presentation` | 8 | 0 | PASS (21/21 cases, 0 fail) |
| `m43_c005_c006_standard_pack_presentation` | 9 | 0 | PASS (21/21 cases, 0 fail) |
| `m43_c005_c006_standard_pack_presentation` | 10 | 0 | PASS (21/21 cases, 0 fail) |
| `m43_c005_c007_premium_pack_presentation` | 1 | 0 | PASS (19/19 cases, 0 fail) |
| `m43_c005_c007_premium_pack_presentation` | 2 | 0 | PASS (19/19 cases, 0 fail) |
| `m43_c005_c007_premium_pack_presentation` | 3 | 0 | PASS (19/19 cases, 0 fail) |
| `m43_c005_c007_premium_pack_presentation` | 4 | 0 | PASS (19/19 cases, 0 fail) |
| `m43_c005_c007_premium_pack_presentation` | 5 | 0 | PASS (19/19 cases, 0 fail) |
| `m43_c005_c007_premium_pack_presentation` | 6 | 0 | PASS (19/19 cases, 0 fail) |
| `m43_c005_c007_premium_pack_presentation` | 7 | 0 | PASS (19/19 cases, 0 fail) |
| `m43_c005_c007_premium_pack_presentation` | 8 | 0 | PASS (19/19 cases, 0 fail) |
| `m43_c005_c007_premium_pack_presentation` | 9 | 0 | PASS (19/19 cases, 0 fail) |
| `m43_c005_c007_premium_pack_presentation` | 10 | 0 | PASS (19/19 cases, 0 fail) |

**Standard: 10/10 PASS. Premium: 10/10 PASS.** Every exit code is 0. No run was retried or substituted.

## 5. Phase 3 closure regression

Clean TEMP worktree after `--import`; the same suite list as the Phase 3 log.

| Suite | Exit | Result |
|---|---|---|
| `m43_c005f_phase3_meta_rewards_acquisition` | 0 | PASS (15/15 cases, 0 fail) (serr 1 = announced fault injection) |
| `m43_c005f_phase2_r01_earned_pack_runtime` | 0 | PASS (22/22 cases, 0 fail) (serr 3 = announced fault injection) |
| `m43_c005f_phase1_foundation` | 0 | PASS (23/23 cases, 0 fail) (serr 1 = announced fault injection) |
| `m43_c005f_phase2_results_pack_feel` | 0 | PASS (22/22 cases, 0 fail) (serr 6 = announced fault injection) |
| `m43_master_c005f_feel` | 0 | PASS (10/10 cases, 0 fail) |
| `m43_c001a_results_foundation` | 0 | PASS (11/11 cases, 0 fail) |
| `m43_c001b_won_results_visual` | 0 | PASS (11/11 cases, 0 fail) |
| `m43_c001r_c001_results_momentum` | 0 | PASS (40/40 cases, 0 fail) |
| `m43_c005_c006_standard_pack_presentation` | 0 | PASS (21/21 cases, 0 fail) |
| `m43_c005_c007_premium_pack_presentation` | 0 | PASS (19/19 cases, 0 fail) |
| `m43_c005_c006_owner_review_harness` | 0 | PASS (14/14 cases, 0 fail) |
| `m43_c005_c007_premium_owner_review_harness` | 0 | PASS (11/11 cases, 0 fail) |
| `m43_c005_c008_pack_commit_transaction` | 0 | PASS (27/27 cases, 0 fail) |
| `m43_c005_c009_card_state_celebration` | 0 | PASS (25/25 cases, 0 fail) |
| `m43_master_c005_meta_ceremonies` | 0 | PASS (32/32 cases, 0 fail) |
| `m43_master_c005r_gift_micro_progress` | 0 | PASS (8/8 cases, 0 fail) |
| `m43_master_c007_collection` | 0 | PASS (13/13 cases, 0 fail) |
| `m43_master_c007r_pity` | 0 | PASS (9/9 cases, 0 fail) |
| `m54_collection_set_master_exactly_once` | 0 | PASS |
| `m43_master_c009_daily` | 0 | PASS (12/12 cases, 0 fail) |
| `m43_master_c010_meta` | 0 | PASS (12/12 cases, 0 fail) |
| `m43_master_c011_c014` | 0 | PASS (28/28 cases, 0 fail) |
| `m39_v02_atomicity` | 0 | PASS |
| `m39_v03_full_surface` | 0 | PASS |
| `m39_v04_integration` | 0 | PASS |
| `m39a_economy_core` | 0 | PASS |
| `m39d_daily_collection` | 0 | PASS |
| `m39e_full_matrix` | 0 | PASS |
| `m40_save_system` | 0 | PASS |
| `m40_v02_safety` | 0 | PASS |
| `m40_v03_canonical` | 0 | PASS |
| `m40_v04_bootstrap` | 0 | PASS |
| `m41_settings` | 0 | PASS |
| `m42_home` | 0 | PASS |
| `m42_navigation` | 0 | PASS |
| `m43_c002_c001_popup_modal_pause` | 0 | PASS (23/23 cases, 0 fail) |
| `m43_c003_c001_acquisition` | 0 | PASS (34/34 cases, 0 fail) |
| `m43_c004_c001_fail_need_a_hand` | 0 | PASS (40/40 cases, 0 fail) |
| `m30_completion_authority` | 0 | PASS |
| `m30_manual_playtest_smoke` | 0 | PASS |
| `m43_r15_owner_remediation` | 0 | PASS (18/18 cases, 0 fail) |
| `m43_r15_001_r01_sequential_unlock` | 0 | PASS (14/14 cases, 0 fail) |
| `m55_economy_release_regression` | 0 | PASS |
| `m43_master_c006_shop` | 0 | PASS (11/11 cases, 0 fail) |
| `m43_master_c008_robots` | 0 | PASS (10/10 cases, 0 fail) |
| `cp04_remote_content_runtime` | 0 | PASS (28/28 cases, 0 fail) |
| `cp05_remote_content_cache` | 0 | PASS (15/15 cases, 0 fail) |
| `run_tests (root tests/run_tests.gd)` | 0 | RESULT: ALL PASS |
| headless import (TEMP) | 0 | clean |
| headless boot (`--quit-after 120`) | 0 | clean; only the engine exit notice `29 resources still in use at exit` (same as every baseline) |
| `git diff --check` | 0 | clean |

**48/48 suites PASS, with no failing or unexplained suite.** This includes Standard and Premium, which previously flaked.

## 6. Scope

Changed files:
- `tests/m43_c005_c006_standard_pack_presentation.gd`
- `tests/m43_c005_c007_premium_pack_presentation.gd`
- `tests/support/pack_route_probe.gd` (new, test-only)
- this log

The diff contains nothing under:
- `scripts/` (including `scripts/ui/ceremony/**` and `scripts/ui/components/reveal_sequencer.gd`);
- `assets/`, economy/save, Remote Content/R2, LevelData/supply/VOID, Family APK, Level Factory;
- `TASKS.md`.

## 7. Final Desktop sync (after push)

After this commit is pushed, the Desktop checkout is fast-forwarded with `git -C "C:\Users\sekip\Desktop\ScrubBots" fetch --prune origin` + `merge --ff-only origin/main`.
- Owner `project.godot` is never touched.
- Its SHA-256 is re-verified against the pre-task value.

The resulting HEAD, `origin/main`, 0/0 and hash check are reported in the hand-off response. A commit cannot contain the result of its own post-push sync.

## 8. Status

AWAITING_GPT_M43_C005F_PHASE3_QA_R01_REAUDIT
