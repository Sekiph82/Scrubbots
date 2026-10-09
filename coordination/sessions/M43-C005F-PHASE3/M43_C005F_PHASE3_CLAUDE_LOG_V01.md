# M43-C005F-PHASE3 — Meta Rewards + Acquisition Feel — CLAUDE_LOG_V01

- Prompt: `coordination/sessions/M43-C005F-PHASE3/M43_C005F_PHASE3_MASTER_PROMPT_V01.md`
- Criteria: `coordination/sessions/M43-C005F-PHASE3/M43_C005F_PHASE3_AUDIT_CRITERIA_V01.md`
- Scope: `SB-M43-C005F-006`, `SB-M43-C005F-008`, `SB-M43-C005F-009` only. F007, F010, F011, F012 and F015 were not executed.
- Engine: Godot 4.7.2.stable.official.ed1daf0bf
- Starting SHA: `4dbf1045c2f1988a08e3d76a3c7e6e40ba25bdfe` (`origin/main`)
- Final SHA: the commit that adds this log. Implementation, tests, evidence and this log are in one commit; parity is reported in the hand-off.

## 0. Gate 0 — owner Desktop sync (BEFORE implementation)

### State recorded first

Persistent checkout `C:\Users\sekip\Desktop\ScrubBots`:

| Item | Value |
|---|---|
| HEAD | `2cf742ba` |
| `origin/main` after `git fetch --prune origin` | `4dbf1045` |
| Ahead / behind | 0 / 5 |
| Dirty tracked files | `project.godot`, `scenes/app/main.tscn`, `tests/tools/owner_review/premium_pack_owner_review.tscn`, `tests/tools/owner_review/standard_pack_owner_review.tscn` |
| Untracked files | 2932, including `.mcp.json`, `addons/godot_ai` and local art / `.import` / `.uid` files |
| Stashes | `stash@{0}` autostash, `stash@{1}` "pre-batch TASKS whitespace" |
| Worktrees | three Codex worktrees |

### Reconcile

- The 5 incoming commits touched only `TASKS.md` and coordination docs. None of them overlapped a dirty file.
- `git merge --ff-only origin/main` succeeded. There was no stash, reset, clean or force.
- Result: Desktop HEAD = `4dbf1045` = `origin/main`, ahead/behind **0/0**.
- All four dirty files and all untracked owner files were retained.
- Implementation started only after this.

A clean TEMP worktree at exact `4dbf1045` was then used for build and test work.

### INCIDENT during the milestone (disclosed; repaired)

**What happened.** While trying to run a baseline flake check, a shell command did three things in sequence:
1. It ran `git worktree add <baseline> 4dbf1045` with its error output suppressed. That step failed silently.
2. The following `cd <baseline> && …` chain was therefore skipped.
3. The next `; git checkout -- project.godot` then ran in the session's working directory, which is the **owner Desktop checkout**.

This discarded the Desktop's reconciled local `project.godot` modifications. Nothing else was touched:
- the `.tscn` edits, untracked files, stashes and worktrees were intact;
- the untracked count was still 2932;
- no `--import` ran there.

**Repair.**
- I rebuilt the file exactly as reconciled on 2026-10-08:
  - from the preserved owner original `C:\Users\sekip\Desktop\ScrubBots_sync_backup_20261008\project.godot`, which is identical to the original pre-merge local file kept in `stash@{0}` (autostash);
  - three-way merged against base `593f0f6d` and current HEAD. Upstream `project.godot` is unchanged since `2cf742ba`.
- The same resolution was applied:
  - `res://` autoloads, plus `_mcp_game_helper` (godot_ai);
  - one `[editor_plugins]` section listing game_feel_flow, godot_ai and saltmire_spark;
  - the owner's removal of the default `[audio]` bus-layout line, which equals Godot's default.
- A copy of the restored file is at `ScrubBots_sync_backup_20261008\project.godot.reconciled_20261009`.

**Residual risk.** If the owner edited `project.godot` in the editor between 2026-10-08 and this incident, those later edits could not be recovered, because no copy of them existed.

**Process fix.** From now on, worktree commands use `git -C <abs>` / `godot --path <abs>` only, with no `;` after a `cd`, and worktree creation errors are not suppressed.

## 1. Architecture

There is one new presentation-only coordinator: `scripts/ui/feel/meta_reward_feel.gd`.
- It is created and bound once by `scripts/app/main.gd`.
- It observes existing committed seams and calls only `FeedbackAdapter.play(intent, target, key)`.
- It also applies a short native Control scale settle (FULL only).

```text
CeremonyPresenter.ceremony_shown(key, kind)          ─┐
ProductionActionFacade.action_committed(action, r)    ├─> MetaRewardFeel ─> FeedbackAdapter.play(intent, target, key)
RewardedGrantService.resolved(token, product, r.ok)   │                   (+ native Tween settle on the target, FULL)
gameplay host facade action_committed (booster use)  ─┘
```

| Child | Committed seam | Intent | Target | One-shot key |
|---|---|---|---|---|
| F006 | ceremony_shown `set_complete` | REWARD | ceremony `HeroArt` | `c005f006:<ceremony key>` (e.g. `c005f006:set:1`) |
| F006 | ceremony_shown `master_complete` | MAJOR_REWARD | ceremony `HeroArt` | `c005f006:master` |
| F008 | ceremony_shown `gift_milestone` | REWARD; cycle max (1000) MAJOR_REWARD | ceremony `HeroArt` | `c005f008:<ceremony key>` (e.g. `c005f008:gift:gift_ms:c0:m10`) |
| F008 | `claim_gift` committed | REWARD | Gift Bar hero | `c005f008:gift_claim:<occurrence id>` |
| F008 | `claim_daily_login` committed | REWARD | Daily reward popup hero | `c005f008:daily_login:<local day>` |
| F008 | `claim_daily_task` committed | SMALL (spark 4, no confetti) | Tasks row `Task_<i>` | `c005f008:daily_task:<day>:<i>` |
| F008 | `claim_daily_all_tasks` committed → shipping `ceremony_scrubbox` | MAJOR_REWARD | ScrubBox hero | `c005f008:daily_all_tasks:<day>` |
| F009 | `buy_heart` / `refill_hearts` committed | SMALL / REWARD | Life heart | none (see identity) |
| F009 | `buy_booster_charge` committed (Need a Hand BUY) | SMALL | `Card_<id>` | none |
| F009 | `rewarded.resolved` ok, product `heart` / `booster:<id>` | REWARD | Life heart / NAH card / booster popup hero | `c005f009:rewarded:<token>` |
| F009 | gameplay facade booster use committed (`plus_one_slot` / `random` / `selector` / `tornado`) | SMALL | HUD `Booster_<id>` button | none |

### Identity

Ceremonies, claims and rewarded grants key on their **canonical transaction identity**:
- the ceremony event key;
- the Gift occurrence id;
- the DailyService tx ids `daily_login:<day>` / `daily_task:<day>:<i>` / `daily_all_tasks:<day>`;
- the rewarded token.

FeedbackAdapter consumes a key in FULL and REDUCED alike. That is why re-drain, reopen, resize, a stack clear followed by a re-show, and a REDUCED→FULL toggle can never replay.

Heart / charge purchases and booster use have no transaction id. Each one is a distinct spend, and the facade emits `action_committed` exactly once per real commit; refusals emit only `action_refused`. So one commit gives at most one confirmation. The tests prove a duplicate or refused attempt gives zero.

### Presentation-only identity enrichment

There are no grant changes:
- `DailyService.claim_login / claim_task / claim_all_tasks_bonus` success results now also carry the `tx` they already computed.
- The facade copies its input into `claim_daily_task` (`task_index`) and `claim_gift` (`occurrence_id`) results.

### Target resolution and placement

- Facade targets are resolved deferred by `popup_id` on the app ModalStack. The Daily reward and ScrubBox popups are pushed right after the facade returns. A missing target means no work.
- Bursts are placed at the target's rect. The request therefore waits until the freshly pushed popup's containers settle: the rect stops moving, at most 8 frames. This is the same rule as the Phase 2 Results WIN burst (`ResultsScreen._after_layout`).
- I found this from the runtime captures. Without the wait, the first capture showed the Master / ScrubBox confetti spawning at stale pre-layout positions. I fixed it and recaptured.

### Native settle (FULL only)

- REWARD: 1 → 1.05 → 1 over 0.30 s.
- MAJOR_REWARD: 1 → 1.10 → 1 over 0.45 s.
- The tween is created by the target Control (`create_tween`), so it dies with the popup. There is no orphan tween ownership.

### Reduced

- No settle.
- FeedbackAdapter maps every intent to its REDUCED row, so there is zero plugin work.
- The key is still consumed.
- Ceremony art, text and reward rows are unchanged.

### Not changed

- MetaCeremonies / CeremonyPresenter / PackPresenter.
- The Phase 2 Results and pack ceremonies.
- Set 9/9 and Master 15-set truth, all reward values, acknowledgement / save, the PendingPackQueue order, DailyService calendar / streak, the ScrubBox reward, booster legality, and RewardedGrantService.
- GFF is never forced onto a Control. It plays only on Node2D / Node3D, and all of these targets are Controls, so Spark is used through the adapter plus the native tween.
- No `ui_button_press` / `ui_notification` combos. No generic button coating.

### Out of this milestone

The Rewarded Ads daily track (its grants carry a daily `tx`) is not one of this milestone's acquisition surfaces and is filtered out.

## 2. Files

| File | Change |
|---|---|
| `scripts/ui/feel/meta_reward_feel.gd` | NEW — the coordinator |
| `scripts/app/main.gd` | create + bind once; `bind_gameplay(host)` at launch; `get_meta_reward_feel()` |
| `scripts/economy/production_action_facade.gd` | presentation identity on `claim_daily_task` / `claim_gift` results |
| `scripts/economy/daily_service.gd` | success results carry their existing `tx` |
| `tests/m43_c005f_phase3_meta_rewards_acquisition.gd` | NEW — focused suite (15 cases) |
| `tests/tools/c005f_phase3_capture.gd` | NEW — runtime evidence tool (not shipping) |
| `coordination/sessions/M43-C005F-PHASE3/evidence/` | 32 captures + `.gdignore` |
| this log | |

## 3. Focused suite — `tests/m43_c005f_phase3_meta_rewards_acquisition.gd`

Runs on the REAL app (`main.tscn`, 1080×2160 SubViewport), using FeedbackAdapter spy backends to count plugin work.

Result: `M43-C005F-PHASE3 meta rewards + acquisition feel: PASS (15/15 cases, 0 fail)`. The 1 `SCRIPT ERROR` is the announced a04 fault injection.

| Case | Proves |
|---|---|
| s01 | Set Complete → exactly one REWARD `c005f006:set:1` on HeroArt; pickup 8; GFF 0 on a Control; economy byte-identical. pending() / drain / Home refresh / resize / stack-clear + re-show (2 presentations) → still one. Acknowledged by its own CTA. |
| s02 | Master → exactly one MAJOR_REWARD `c005f006:master`; confetti 14 (set 8 < 14 < WIN 18); economy unchanged by feel; +2500 SB from the grant. Repeats → one. |
| s03 | Reduced → key consumed, zero plugin work, no settle (scale 1), reward rows + 9/9 readable. REDUCED → FULL + re-show → no replay. |
| d01 | Gift 10…1000 → nothing until shown; intents REWARD×4 + MAJOR_REWARD (1000); keys from ceremony keys; nothing claimed by feel. |
| d02 | Gift Bar open → no feel. CLAIM → one REWARD `c005f008:gift_claim:<occ>`. Standard pack still opens after (PackPresenter order unchanged). Duplicate claim refused → zero. Pack acknowledged, back on Gift Bar. |
| d03 | Daily open → no feel. Claim → one REWARD `c005f008:daily_login:<day>` on the reward popup. Same-day refusal → zero. Reopen → zero. Clock rollback refusal → zero. |
| d04 | 3 task claims → 3 SMALL (spark 4 each, no confetti), canonical tx keys. ScrubBox → one MAJOR_REWARD (14) on the shipping ScrubBox, +1 Random Booster Charge exactly. Second claim refused → zero. Back to Tasks → zero. |
| d05 | Home refresh ×3, reopen Daily / Gift / Tasks + back, unrelated Life popup, resize, re-drain ceremonies / packs → zero new requests, zero plugin work. |
| a01 | Heart +1 → one SMALL on the Life heart; refill → one REWARD; already full → zero; insufficient SB → zero. |
| a02 | NAH BUY committed → one SMALL on `Card_tornado`; insufficient SB → no charge, zero. |
| a03 | Rewarded failed / cancelled / unverified / timeout(abandon) → zero, no Heart. Verified → one REWARD `c005f009:rewarded:<token>`. Duplicate provider callback → `duplicate`, no grant, no feel. Rewarded booster charge → one REWARD on its NAH card. |
| a04 | Plugins missing → Heart +1 exact. Throwing plugin → Heart +1 exact, Life popup still live. |
| a05 | Real gameplay host: +1 Slot committed → one SMALL on `Booster_plus_one_slot`; illegal use (`target_required`) → zero. |
| b01 | Coordinator names no plugin; calls no grant / claim / save / navigation / provider / settings / snapshot API; its only effect call is `_feel.play(`. No production script outside FeedbackAdapter names a plugin. One production coordinator. |
| b02 | Reduced task + ScrubBox → keys consumed, zero plugin work, no settle. |

## 4. Regression

Final battery (after the layout-settle fix), clean worktree after `--import`. A first full battery before that fix had the same result (47/48 + the same C007 p12 flake).

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
| `m43_c005_c007_premium_pack_presentation` | 1 | FAIL (19/19 cases, 1 fail) **— pre-existing flake, see note** |
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
| headless boot (`--quit-after 120`) | 0 | clean; only the engine exit notice `29 resources still in use at exit` (same as every prior baseline) |
| `git diff --check` | 0 | clean |

**C007 flake disclosure.** `m43_c005_c007_premium_pack_presentation` p12 (`every card observed travelling toward its own destination`) is a frame-sampled mid-route observation in the standalone Premium ceremony test. It failed in both full batteries.

| Run set | Code | Result |
|---|---|---|
| Isolated reruns, Phase 3 tree | Phase 3 | 2/3 PASS, then 4/5 PASS |
| Untouched baseline `4dbf1045` (run in the Desktop checkout during the §0 incident; the test loads neither `main.tscn` nor owner-review scenes) | baseline | **4/5 PASS**, same p12 failure |

The flake rate is the same with and without Phase 3. Phase 3 changes no pack / ceremony / Results code. This is the same class as the C006 v07 flake disclosed in R02. The flake is not relabelled as clean: the first-run FAIL is recorded above.

## 5. Runtime evidence (real shipping surfaces, real plugins)

Tool: `godot --path . -s res://tests/tools/c005f_phase3_capture.gd` (needs a rendering driver).
- It boots the real `main.tscn` at **1080×2160** and **1536×2048**, FULL and REDUCED.
- Every moment comes through its shipping seam:
  - real `collection.add_card` → CeremonyPresenter;
  - real Gift Meter progress;
  - real Tasks / Life popup buttons.
- FULL: the frame is taken ~0.1 s after the coordinator's actual feel request (mid-burst). REDUCED: the static final state is shown.
- 32 JPEGs (quality 0.88, native resolution, 15 MB) are stored under `coordination/sessions/M43-C005F-PHASE3/evidence/`. A `.gdignore` keeps them out of the Godot import.

| # | Moment | Captured feel request |
|---|---|---|
| 01 | Set Complete | `[F006, REWARD, c005f006:set:1, HeroArt]` |
| 02 | Master Collection | `[F006, MAJOR_REWARD, c005f006:master, HeroArt]` |
| 03 | Gift milestone 10 | `[F008, REWARD, c005f008:gift:gift_ms:c0:m10, HeroArt]` |
| 04 | Gift milestone 1000 (cycle max) | `[F008, MAJOR_REWARD, c005f008:gift:gift_ms:c0:m1000, HeroArt]` |
| 05 | Task claim | `[F008, SMALL, c005f008:daily_task:<day>:0, Task_0]` |
| 06 | Earned ScrubBox | `[F008, MAJOR_REWARD, c005f008:daily_all_tasks:<day>, Hero]` |
| 07 | Heart +1 success | `[F009, SMALL, "", Heart]` |
| 08 | Heart insufficient SB (failure) | `last=insufficient_sb`, feel requests 1 → 1 (no success feel) |

Files are named `<W>x<H>_<full|reduced>_<nn>_<moment>_<burst|static>.jpg`, plus `_08_heart_insufficient_no_success_feel.jpg`.

Inspected by me:
- After the layout-settle fix, the Master confetti and the ScrubBox burst sit on the hero.
- The Set pickup is a restrained accent on the emblem, by design: REWARD < MAJOR_REWARD.
- REDUCED frames show no particles and identical art / text / rows.

Intensity and visibility are the owner's visual call. Owner acceptance is NOT assumed.

## 6. Scope exclusion proof

Changed paths are exactly the files in §2.

Untouched:
- RemoteContentManager / `scripts/content_runtime/**` / `data/config/remote_content_runtime_v1.json`;
- R2 URLs, content schemas, LevelData, supply, VOID, the Family APK / export flow and the Level Factory repository;
- root `TASKS.md`;
- `scripts/ui/feel/feedback_adapter.gd`;
- MetaCeremonies, CeremonyPresenter, PackPresenter, the pack ceremonies and ResultsScreen.

CP04 / CP05 Remote Content suites PASS with no semantic test change.

## 7. Final Desktop sync (after push)

After this commit is pushed, the persistent Desktop checkout is fast-forwarded non-destructively (`git -C C:/Users/sekip/Desktop/ScrubBots merge --ff-only origin/main`). No reset, clean, force or stash is used, and all owner-local files are kept.

The resulting Desktop HEAD, `origin/main`, ahead/behind (required 0/0) and the retained owner-local changes are reported in the hand-off response. A commit cannot contain the result of its own post-push sync.

## 8. Status

AWAITING_GPT_M43_C005F_PHASE3_STRICT_AUDIT_AND_OWNER_VISUAL_REVIEW
