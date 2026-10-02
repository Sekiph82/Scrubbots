# M43-C004-C001 — CLAUDE LOG V01

Date: 2026-10-02
Prompt: `coordination/sessions/M43-C004-C001/CHATGPT_PROMPT_V01.md`
Criteria: `coordination/sessions/M43-C004-C001/CHATGPT_AUDIT_CRITERIA_V01.md`
Owner lock: `coordination/sessions/M43-C004-C001/OWNER_FAIL_RETRY_NEED_HAND_V01.md`
Scope: SB-M43-050..062
Status: **AWAITING_GPT_M43_C004_C001_AUDIT**

## Sync / governance

- **Repository:** `Sekiph82/Scrubbots`, branch `main`.
- **Starting commit:** `52ca20b`, fast-forwarded from `02f7161`.
- **Implementation commit:** `1acaf40`.
- **Evidence/log commit:** the next commit, which adds this file. Its SHA is reported in the hand-off message, because a file cannot contain its own commit id.
- **Owner/local work preserved, not committed:**
  - the pre-existing local `project.godot` modification;
  - untracked owner media, `.import` and `.uid` caches;
  - `tests/_m55_diag_tmp.gd`.
- Root `TASKS.md` was read only and **not edited**.

**Read before implementing:**
- `CLAUDE.md` and `TASKS.md`;
- `AUDIT_POLICY.md`;
- the C004 prompt, criteria and owner lock;
- `OWNER_FAILURE_RECOVERY_AND_ACQUISITION_V01.md`;
- the M43-C003 log and audit, and the M43-C002 audit.

**Applied learnings:**
- C003 NB-002: the Restart last-Heart gate is unchanged.
- C002 NB-001: no vacuous assertions; each case observes its property directly.

The Heart authority stays at 900 s. Nothing was touched there.

**Out of scope (not done):**
- no ad SDK, provider, placement ids or tuning;
- no price change and no fifth booster;
- no ad CTA on Fail;
- no shared BUY or WATCH AD, and no NO THANKS;
- no restyle of WON Results, Pause, Life, Booster Acquire or 2x;
- nothing from M43-C005 onward.

## A. Terminal loss truth (inspected before editing)

`_drive_economy_terminal(LOST)` already commits exactly once, latched by `_economy_terminal_done`:
- `hearts.consume()`;
- `streak.on_progression_loss()`, which also clears `gameplay_started`;
- `speed.on_level_completed(level, false)`;
- `request_save()`;
- the receipt.

Terminal Retry is `main.retry_from_results` → zero-Heart gate → `host.retry()` (M30). Its restore seam consumes a Heart only when `gameplay_started()`, and that is false after LOST. So no code change was needed for Retry; t01/t02 prove it, including when the first real action was taken before the loss.

Pause → Restart is unchanged; the C002 suite passes 23/23.

## Implementation

| File | Change |
|---|---|
| `scripts/ui/results_screen.gd` | LOST is the production Fail surface (SB-M43-050), in the same cream/royal family as WON: the existing `help_scrubby_pose.png` hero, the existing `fail_header_emblem.png`, `LEVEL FAILED`, the live level, `loss_rows(receipt)` (Hearts before → after, an ended Win Streak), "So close!", Retry primary, Home secondary. ERROR keeps the technical fallback. |
| `scripts/economy/failure_assistance_service.gd` (new) | The one non-UI counter / read model and recommender. Its config fails closed. It emits `assistance_event(kind, data)` as the M56 seam. |
| `data/config/failure_assistance_v1.json` (new) | Schema `scrubbots.failure_assistance.v1`: trigger 3, repeat 0 (once until reset), two picks, fallback order and context weights. |
| `scripts/app/app_state.gd` | Owns the one `assist` instance. It is session-scoped; see the persistence note. |
| `scripts/gameplay/runtime/production_gameplay_host.gd` | Supply creation is factored into `_make_supply()` (same code). `_record_assistance()` runs inside the latched terminal, after the economy commit and save. Also adds `next_start_prover()`, `next_start_legality()`, `terminal_context()`, `get_assistance_offer()` and `is_progression_attempt()`. |
| `scripts/economy/production_booster_adapter.gd` | `has_eligible_safe_batch()`: the same solver proof as `eligible_safe_batches()`, stopping at the first safe batch. Read-only. |
| `scripts/economy/booster_inventory.gd` / `production_action_facade.gd` | `buy_charge(id)` / `buy_booster_charge(id)`: canonical id, `EconomyConfig` price, atomic debit plus exactly +1 charge, and one save on commit. |
| `scripts/ui/popup/acquisition_flow.gd` | `open_need_a_hand(offer)`: two cards with per-card `buy:<id>` / `watch:<id>` actions; rewarded kind `charge` (saved, never executed); insufficient SB → C003 `open_insufficient` → `ShopHandoff`. |
| `scripts/ui/popup/base_popup.gd` | Opt-in `add_action(..., parent)` that places a CTA inside a card. Gating and latching are unchanged. |
| `scripts/app/main.gd` | On RESULTS LOST, opens Need a Hand when the host's offer says `show`. |
| `scripts/ui/ui_text.gd` | `FAIL_*` and `NAH_*` copy. |
| `scripts/economy/README.md`, `data/config/player_experience_plan_v1.json` | Documentation drift: the planning value `repeat_frequency_after_threshold` now points at the runtime config. |

### Counter scope / persistence

- **Progression attempt:** `progression_level == progression.current_level()`. Replay, stale or future attempts are excluded.
- **Session-scoped:** the counter is not in the save file. Per prompt §C, no save migration was invented. A cold relaunch restarts the count. This is listed as an owner decision.

### Recommendation

- **Rank.** Context signals are read from the terminal and never mutate it: `slots_full`, `dominant_color` (≥ 40%) and `supply_remaining`. They are weighted, with ties resolved by `fallback_order`: +1 Slot, Selector, Tornado, Random.
- **Prove lazily.** Each booster in rank order is proved legal on a **detached fresh start-state**: a new BoardState, the same initial supply and five empty slots, with `ProductionBoosterAdapter` and no scheduler. Proving stops at two. Fewer than two → `insufficient_meaningful`: no popup, the event is recorded, and Fail stays usable.
- **Deviation from my first draft.** I first proved all four boosters eagerly. Random's 3-step solver proof measured up to ~4.9 s headless on a 32×32 board. Lazy proving brought the measured third-failure terminal down to 175–355 ms (see Perf).
- The `supply_remaining` weight maps to Selector ("pick any safe remaining batch"), not Random, so the costly proof is not ranked first by default. This is an owner tuning point.

## Tests

### Focused suite

`godot --headless --path . -s res://tests/m43_c004_c001_fail_need_a_hand.gd` → **PASS, 40/40 cases, 0 fail.**

It runs on the real app root (`main.tscn`), catalog level 2, the canonical AppState, economy and save, and the C003 provider double. The production default is checked separately.

| # | Expected | Failure condition | Result |
|---|---|---|---|
| 1 | LOST: Hearts −1, and the receipt matches | Any other delta | PASS (5 → 4) |
| 2 | Retry after LOST: no second Heart, no second streak reset; also when the first action happened before the loss | Hearts change on Retry | PASS (5 → 4 total) |
| 3 | Fail Home: HOME, economy snapshot unchanged | Any delta | PASS |
| 4 | 0 Hearts → Retry opens Life, with no retry and no consumption | Retry happens / no Life | PASS |
| 5 | Fail: family theme, Fail art, no Victory textures, buttons exactly [RETRY, HOME], no Replay or ad, ≥ 88 px | Other buttons / Victory art | PASS |
| 6 | Fail rows == receipt (Hearts 5→4, "Win Streak 4 ended"); re-show mutates nothing | Mismatch | PASS |
| 7–10 | Counts 1 and 2: none. Count 3: due, open once, `due`/`shown` events once. Counts 4/5/6: suppressed, with events | Any deviation | PASS |
| 11 | WON resets (service + real host WON) | Count ≠ 0 | PASS |
| 12 | A level change resets (service + real Home → new frontier launch) | Count not reset | PASS |
| 13 | A replay failure is not counted (frontier moved past the level) | Count changes | PASS |
| 14–16 | Exactly 2 distinct canonical picks; both proved on the next start-state; proofs leave the terminal board/supply/slots byte-identical; same input → same pair, including across a fresh app; context ranking is deterministic | — | PASS |
| 17 | Fail closed: service with one legal booster; the popup rejects 1, duplicate, unknown or `show:false`; real host with an unprovable start-state → no popup, reason recorded, Retry works | — | PASS |
| 18–23 | 2 cards with icon/name/benefit/owned; each zero-charge card has exactly its own BUY · price SB and WATCH AD (2 + 2); the footer is empty; action ids are exactly `buy:`/`watch:` per card and descend from their card; no "THANKS"; X is top-right; no-guarantee line | — | PASS |
| 24–25 | X, Back and Escape each close with no change to the economy snapshot, assistance state, board, route or attempt id; Back never leaks to Results → Home | Any change | PASS |
| 26–28 | Canonical prices; BUY: −price, exactly +1 charge, one `action_committed`, one ok save, persisted on reload; unknown id moves nothing; insufficient: nothing moves, and the Shop ticket carries `source=need_a_hand`, booster, price and level; Need a Hand resumes underneath | — | PASS |
| 29–31 | A verified ad grants +1 for that card only; cancel / skip / fail / timeout / unverified / missing-verified / late-after-UI-timeout grant 0; background/resume plus 4 duplicate callbacks grant 1, with the token persisted | — | PASS |
| 32 | One card's placement unavailable → that WATCH AD is visible but disabled with a note; the other card's ad is enabled and grants independently | — | PASS |
| 33 | An owned card shows OWNED ×2 / ready and no CTA; the zero card keeps both | — | PASS |
| 34 | After a BUY + ad grant on a progressed terminal board: board, supply, slots, capacity and `last_booster_request` are unchanged. Retry → fresh five slots → the saved charge is used through `request_booster` | — | PASS |
| 35 | Real clicks on Fail Retry/Home behind the popup do nothing | — | PASS |
| 36 | 6 BUY taps → 1 purchase; 5 WATCH taps → 1 request; X refused while pending | — | PASS |
| 37 | 20 real Fail → Need a Hand → X cycles: 20 opens; nodes 389 → 389; connections and timers stable | — | PASS |
| 38 | 5 sizes: Fail panel/robot/buttons inside the viewport and ≥ 88 px; Need a Hand frame inside the safe area, `text_fits`, cards inside the frame, 4 CTAs (≥ 88 px tall, no clipped text), X visible | — | PASS, all 5 |
| 39 | Reduced Effects: identical offer and rows, shown immediately | — | PASS |
| config | v1 config loads; a missing config is never due and never recommends; event sequence is exact | — | PASS |
| production provider | Both WATCH AD controls present and disabled; a press requests nothing | — | PASS |
| perf | All 10 catalog levels give a two-card offer; the third-failure terminal is < 1,500 ms headless | — | PASS (175–355 ms) |

### Full regression

Godot 4.7.2 headless, 12-way parallel, all 126 top-level `tests/*.gd`:
- **123 rc=0.**
- Root `tests/run_tests.gd`: **Total checks 5323, RESULT: ALL PASS.**
- **M30:** completion authority, manual playtest smoke, transaction-safe retry — PASS.
- **M39:** A–E, V02 atomicity/capacity/integration, V03 full-surface/integration, V04 integration, tornado in-flight — PASS.
- **M40:** save system, V02, V03, V04 — PASS.
- **M42:** home, composition, V04–V07 safe area, navigation, opening, assets, Scrubby scale/animation — rc=0.
- **M43:** C001A 11/11, C002 23/23, C003 34/34, C004 40/40 — PASS.
- **M52:** owner supply plans, R01, R02 — PASS.
- **M55:** long session, core chaos, economy release, Heart 900, C002 timed-2x anti-rollback — PASS.

**Non-zero exits:**
- `m21_v08_corridor_validation` (FAIL 2) and `m21_v09_direct_evidence_reconciliation` (FAIL 1): the same historical pre-Railroad-V1 baseline recorded in the C003 log. No routing was touched.
- `m43_c001b_won_results_visual`: **deliberate migration.** The C001B LOST case asserted the pre-C004 technical fallback (no robot, no emblem, `theme == null`, no texture of any kind), and its art-governance check knew only the WON art. It was migrated to the C004 truth:
  - Fail robot, not Victory;
  - fail emblem;
  - loss rows only, with no reveal;
  - no **Victory** texture;
  - the three newly bound approved files registered in its SHA-256 governance list. Their hashes match the committed files; none of them was modified.

  The WON assertions are unchanged. Re-run: **PASS, 11/11, 0 fail.**

**Other checks:**
- `SCRIPT ERROR` appears only in the m20 lifecycle smoke logs (baseline assertion names).
- `git diff --check` is clean.

### Sensitivity notes

- **t02:** if terminal LOST stopped clearing `gameplay_started`, or Retry consumed a Heart, the "Hearts changed exactly once total" assertion fails. The case takes a real first action before LOST.
- **t15 / t34:** these compare the full board cell-state vector, the supply `debug_snapshot` and the slots snapshot. Any mutation of the terminal board fails them.
- **t22:** asserts that every action button descends from the card named by its id and that the footer has no buttons. A shared CTA fails it.

## Evidence

`evidence/` holds 20 PNGs rendered by `tests/tools/fail_need_a_hand_snapshot.gd` (a rendering driver, not headless). The tool rejects any shot whose popups fail `text_fits()` or whose Fail panel or robot leaves the viewport; none was rejected.

They cover:
- Fail: reference, short phone, 1170, tablet;
- third-failure Need a Hand with 2 BUY + 2 WATCH AD, plus short, 1170, 1290 and tablet sizes;
- one card's rewarded unavailable; production provider unavailable; loading;
- insufficient SB; Shop handoff;
- owned charge; after BUY;
- Fail after X;
- zero-Heart Retry → Life;
- Reduced Effects for Fail and Need a Hand.

`evidence/LIFECYCLE_REPORT_V01.md` holds the lifecycle and perf numbers. `FAILURE_ASSISTANCE_MATRIX_V01.md` holds the ownership, rule and test map. `OWNER_VISUAL_REVIEW_V01.md` holds the owner pack.

## Deviations / owner decisions

These are listed in `OWNER_VISUAL_REVIEW_V01.md` §2:
1. No sad pose exists, so Fail uses the approved help Scrubby pose. No art was generated.
2. The Fail loss-row copy.
3. The recommendation fallback order and context weights (Random is the costliest proof).
4. WATCH AD is shown disabled while no video is available, which is the production state until M57.
5. The counter is session-scoped, not saved.
6. Differences from the `need a hand.png` reference: the family X, gold BUY plus green WATCH AD, and no clapper icon.

## Reproduce

```bash
godot --headless --path . -s res://tests/m43_c004_c001_fail_need_a_hand.gd
```

```bash
godot --headless --path . -s res://tests/m43_c001b_won_results_visual.gd
```

```bash
godot --headless --path . -s res://tests/run_tests.gd
```

```bash
godot --path . -s res://tests/tools/fail_need_a_hand_snapshot.gd -- coordination/sessions/M43-C004-C001/evidence
```

`AWAITING_GPT_M43_C004_C001_AUDIT`
