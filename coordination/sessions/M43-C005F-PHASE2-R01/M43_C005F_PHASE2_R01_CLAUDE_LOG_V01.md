# M43-C005F-PHASE2-R01 — Earned Pack Production Wiring — CLAUDE_LOG_V01

- Prompt: `coordination/sessions/M43-C005F-PHASE2-R01/M43_C005F_PHASE2_R01_EARNED_PACK_RUNTIME_PROMPT_V01.md`
- Criteria: `coordination/sessions/M43-C005F-PHASE2-R01/M43_C005F_PHASE2_R01_AUDIT_CRITERIA_V01.md`
- Engine: Godot 4.7.2.stable.official.ed1daf0bf
- Starting SHA: `861d6a8a7d4a572ae7a35a9b65a55677a8e071b5` (`origin/main`)
- Final SHA: the commit that adds this log (implementation and this log in one commit; parity is reported in the hand-off)

## 0. Owner-local sync truth

The owner-local checkout `C:/Users/sekip/Desktop/ScrubBots` is on `main` at `593f0f6d` and is now behind `origin/main`.

Its protected state was untouched:
- `project.godot`, `main.tscn` and the two owner-review `.tscn` files are modified;
- untracked: the pre-canonical `addons/` (including `godot_ai`), `.mcp.json`, art and `.uid`/`.import` files;
- `stash@{0}` and three Codex worktrees.

It still cannot fast-forward, because Git refuses to overwrite those untracked addon copies and the dirty `project.godot` (known since Phase 1). Nothing was reset, cleaned, stashed or moved.

All work was done in a clean TEMP worktree at exact `origin/main` `861d6a8a`. Root `TASKS.md` was not edited.

## 1. Architecture chosen

```text
RewardGrantService.grant(tx, {..., standard_card_packs: n | premium_card_packs: n})
  -> EconomyServices handler -> PendingPackQueue.enqueue(tx, kind, n)           [no draw]
       entry id = "earned:<tx>:<kind>:<ordinal>"  (stable, FIFO, durable in the economy save)
  -> facade action_committed / RewardedGrantService.resolved(ok) / quiet Home
  -> main.request_earned_packs() -> PackPresenter.drain()
       -> AppState.open_earned_pack(id) -> PackCommitTransaction.commit(economy, kind, id, save)
            new id: snapshot -> CardPackService draw ONCE (pity/RNG/Collection/set+master)
                    -> PackReceiptLedger receipt -> durable save -> model
            committed id: stored receipt replayed, ZERO draw (restart mid-ceremony)
       -> StandardPackCeremony / PremiumPackCeremony (accepted art/timing) + bind_feedback(app feel)
       -> app ModalStack.push
  -> presentation_completed -> AppState.acknowledge_earned_pack(id) (needs the receipt) -> remove + save
  -> pack_finished -> next pending pack (FIFO)
```

**PendingPackQueue** (`scripts/collection/pending_pack_queue.gd`, new)
- Data only. The snapshot is `{version: 1, entries: [{id, kind}]}`.
- Import is strict. Kinds must be `standard`/`premium`; ids must be unique, non-empty, trimmed and prefixed with `earned:`; there must be no extra keys.
- An absent section (an old save) migrates to empty. A malformed section that is present fails the whole `EconomyServices.import_snapshot`, which then rolls back to its backup.

**RewardGrantService**
- `current_tx()` exposes the parent tx id while its handlers run.
- All other resources and the existing idempotency/atomicity are unchanged.

**PackCommitTransaction**
- Unchanged, and reused as-is. It already implements draw-once, durable receipt before model, exact-snapshot rollback and replay without draw.
- The queue id is passed as its tx/presentation id.

**AppState**
- `open_earned_pack(id)`: canonical commit for a pending entry; replays when already committed.
- `acknowledge_earned_pack(id)`: refused unless the receipt is committed; removes the entry, then saves.

**PackPresenter** (`scripts/ui/ceremony/pack_presenter.gd`, new) is the one production presenter.
- It walks the queue FIFO, one ceremony at a time.
- It acknowledges only on `presentation_completed`.
- A ceremony closed any other way (stack cleared on a route change) stays pending and reopens the same receipt.
- It never grants, draws, rerolls or decides rarity.

**main.gd wiring**
- `request_earned_packs()` is called after each `ProductionActionFacade.action_committed` (Gift / Daily / any facade grant) and after each verified `RewardedGrantService.resolved` (Rewarded Ads slots).
- It is also called from the quiet-Home chain (boot to Home and return to Home) and after each finished pack.
- Packs are drained only on HOME, with Settings closed, and never over another pack or meta ceremony.
- It waits out a claim-confirmation popup (`ceremony_*`, e.g. Daily's reward celebration) and any busy popup, then stacks over the destination that earned the pack (Gift Bar / Daily / Rewarded Ads).
- Gameplay and Results are never interrupted.

**Presentation order** (deterministic, tested)
1. The claim's own confirmation (Daily celebration) is shown first.
2. Then earned packs, FIFO, one at a time.
3. Then any meta ceremony (set/master/robot/gift milestone) still pending. It keeps its existing rule: it shows when the stack is empty on Home.

On the quiet-Home chain the order is: pending meta ceremonies, then packs, then the comeback summary.

**ModalStack** (pre-existing layering defect found by the runtime evidence)
- A lower popup's hero art (BasePopup `_hero.z_index = 1`) drew **over** any popup stacked above it, so the Gift Bar gift box covered the pack ceremony.
- Fix: `_sync()` gives each stacked popup a relative z band `depth * 4`. Each popup's internal order is unchanged, and popup/modal regressions pass.

**F005**
- The production ceremony is bound to `main.feel`, the single FeedbackAdapter, so the accepted Phase 2 card accents now really run in the shipping route (R01 g01 asserts the binding).
- Reduced Effects means a reduced ceremony and zero plugin work (R01 g08).
- There is no plugin access outside the adapter, and the sparkle was not retuned.

## 2. Proof the old silent path is removed

- Both `standard_card_packs` and `premium_card_packs` handlers in `EconomyServices._register_handlers()` now call `pending_packs.enqueue(reward.current_tx(), ...)`. Neither calls `packs.open_*` any more.
- `grep "open_standard()|open_premium()" scripts/` finds the only production caller, `pack_commit_transaction.gd`, plus their definitions in `card_pack_service.gd`. This is asserted statically by R01 g13.
- A grant leaves Collection, pack RNG and pity unchanged (R01 q02).

## 3. Reward-source matrix (config `data/config/economy_rewards_v1.json`)

| Source | Pack | Other rewards (verified exact) | Proof |
|---|---|---|---|
| Gift 10 | Standard ×1 | Bot Parts +1 | R01 g01, evidence 01_* |
| Gift 250 | Standard ×1 | SB +100, Bot Parts +2 | R01 g02 |
| Gift 500 | Standard ×1 | SB +250, Bot Parts +2, selected booster +1 | R01 g02 |
| Gift 1000 | Premium ×1 | Bot Parts +4, SB +500, selected boosters +2, guaranteed NEW card (or 500 SB fallback) | R01 g03, evidence 02_* |
| Daily day 2 | Standard ×1 | none | R01 g04 |
| Daily day 4 | Standard ×1 | SB +250 | R01 g04 |
| Daily day 5 | Premium ×1 | SB +300, selected booster +1 | R01 g04 |
| Rewarded Ads slot 2 / 4 / 5 | Standard / Standard / Premium | per `rewarded_daily_v1.json` | R15 r10 (slot 2 pack ceremony over Rewarded Ads) |
| Comeback / Events (`approved_reward_types`) | generic | n/a | same generic handler (R01 q02) |
| Gift 50 / Daily 1, 3 (no pack) | none (no popup) | unchanged | R01 g10, g04 |

**Gift 1000 note:** the guaranteed NEW card is still applied immediately by its own handler at claim (exact semantics, including the 500 SB fallback). The Premium pack draws later at ceremony open. In evidence `02_*`, Collection went 3 → 9: 1 guaranteed card plus the 5 revealed cards.

## 4. Save / restart evidence

| Case | What it shows |
|---|---|
| q01 | queue schema, strict import, absent-section migration, malformed section fails closed and the economy state is restored |
| q05 | save failure during open restores the exact pre-open snapshot (Collection / RNG / pity / ledger / queue); the entry stays pending; a later open succeeds |
| q06 / g05 | relaunch after the claim but before opening: the same pending pack opens on Home (first commit) |
| q06 / g06 | relaunch after commit, before the ceremony finished: identical receipt cards replayed (`replay=true`); Collection unchanged; no reroll |
| q03 | a second open of the same id replays the receipt with zero draw; acknowledgement is refused before commit and accepted after it (removed + saved) |
| q04 | Premium has exactly 5 cards with card 0 Rare-or-better; Standard has exactly 3; replay does not advance pity |
| g07 | FIFO `standard:0, standard:1, premium:0`; never two pack ceremonies at once |
| g11 | duplicate claim refused; a spurious `action_committed` opens no second ceremony |
| g12 | pending pack during GAMEPLAY / RESULTS: no popup; on HOME (after any meta ceremony) it opens |
| g09 | plugins missing or throwing (deliberate, labelled faults): the ceremony completes natively and is acknowledged |

## 5. Runtime evidence (REAL production; `evidence/`)

These come from the real app root (`main.tscn`, 1080×2160 SubViewport), with real plugins, real Gift Meter progress and real Gift Bar CLAIM buttons:

| Step | Standard (Gift 10) | Premium (Gift 1000) |
|---|---|---|
| Gift Bar before claim | `01_gift10_a_gift_bar_before_claim.png` | `02_gift1000_a_gift_bar_before_claim.png` |
| Claim committed: pack screen opens automatically | `01_gift10_b_pack_screen_opened_automatically.png` | `02_gift1000_b_pack_screen_opened_automatically.png` |
| Cards revealed (hold + destinations) | `01_gift10_c_cards_revealed.png` | `02_gift1000_c_cards_revealed.png` |
| After completion, back on Gift Bar | `01_gift10_d_after_completion_back_on_gift_bar.png` | `02_gift1000_d_...png` |
| Collection after both | `03_collection_after_both_packs.png` (9 / 135 cards) | |

Printed counts:
- Gift 10: owned 0 → 3, pending 1 → 0.
- Gift 1000: owned 3 → 9, pending 1 → 0.
- Final: 2 receipts, 0 pending.

**Observation (out of scope, pre-existing):** the Gift 1000 row text shows the raw key `REWARD_guaranteed_new_fallback_sb x500` (missing UiText entry). It was not touched here.

## 6. Exact files changed

- **New:** `scripts/collection/pending_pack_queue.gd`, `scripts/ui/ceremony/pack_presenter.gd`
- **Modified:**
  - `scripts/economy/economy_services.gd`: handlers enqueue; `pending_packs` snapshot / import.
  - `scripts/economy/reward_grant_service.gd`: `current_tx()`.
  - `scripts/app/app_state.gd`: `open_earned_pack` / `acknowledge_earned_pack`.
  - `scripts/app/main.gd`: PackPresenter, `request_earned_packs`, quiet-Home order.
  - `scripts/ui/popup/modal_stack.gd`: z band.
  - `scripts/collection/card_pack_service.gd`: doc only (caller contract).
- **Tests:**
  - New: `tests/m43_c005f_phase2_r01_earned_pack_runtime.gd` (19 cases).
  - `tests/m43_r15_owner_remediation.gd`: r10 now completes the slot-2 Standard pack ceremony that opens over Rewarded Ads.
  - `tests/m55_economy_release_regression.gd`: the pack handler check now expects one queued pack instead of a silent draw.
- **Evidence tool:** `tests/tools/c005f_r01_earned_pack_capture.gd`; `coordination/sessions/M43-C005F-PHASE2-R01/evidence/*.png`
- **This log.**

F003 and F004 (Results feel) source is unchanged.

## 7. Forbidden-path proof

The staged diff (`git diff --cached --name-only`) contains **0** of these paths:
- `scripts/content_runtime/`, `remote_content_runtime_v1.json`, `REMOTE-CONTENT-RUNTIME-V01`;
- `level_factory/` (LF / VOID / R2 / publisher), `TASKS.md`;
- `scripts/gameplay/`;
- the accepted F003/F004 Results source `scripts/ui/results_screen.gd`;
- the Phase 1/2 audited `feedback_adapter.gd`;
- the accepted Standard / Premium ceremony sources.

No endpoint, credential or Remote Content work was done.

## 8. Regression table

Results from the TEMP worktree at `861d6a8a` plus this change, canonical plugins present. Every run exited 0 with 0 FAIL.

| Suite | Result |
|---|---|
| **New R01** `m43_c005f_phase2_r01_earned_pack_runtime` | **PASS 19/19** |
| Phase 1 foundation / Phase 2 Results + pack feel / legacy C005F lane | PASS 23/23, 22/22, 10/10 |
| Results foundation / WON visual / momentum (F003 / F004 accepted behaviour) | PASS 11/11, 11/11, 40/40 |
| Pack C006 Standard / C007 Premium / owner-review harnesses / C008 commit / C009 card state | PASS 21/21, 19/19, 14/14, 11/11, 27/27, 25/25 |
| Meta ceremonies / Gift micro-progress / Collection / pity / M54 set + master exactly-once | PASS 32/32, 8/8, 13/13, 9/9, PASS |
| Daily / Tasks / Gift C009, meta C010, C011-C014, Shop C006, Robots C008 | PASS 12/12, 12/12, 28/28, 11/11, 10/10 |
| M39 (v02 atomicity, v03, v04, A, D, E) | PASS ×6 |
| M40 save (4 suites) | PASS ×4 |
| M41 Settings / Reduced Effects | PASS |
| Home `m42_home`, navigation `m42_navigation` | PASS, PASS |
| Popup / modal `m43_c002_c001` (with the ModalStack z band) | PASS 23/23 |
| Acquisition / Need a Hand | PASS 34/34, 40/40 |
| Terminal `m30_completion_authority`, `m30_manual_playtest_smoke` | PASS, PASS |
| R15 owner remediation (updated r10) / R15-001-R01 | PASS 18/18, 14/14 |
| M55 economy release (updated pack-handler check) | PASS |
| Root `tests/run_tests.gd` | **5329 / 5329 ALL PASS**, 0 script errors |
| Headless import + boot (`--quit-after 600`) | exit 0, 0 script/parse errors |
| `git diff --check` | clean |

**SCRIPT ERROR accounting:**
- R01 suite: 3 deliberate, labelled faults (g09 throwing plugin).
- Phase 2 suite: 5 deliberate faults (w07 / p06).
- Phase 1 suite: 1 deliberate fault.
- Every line is `'explode' on null` from a test spy. There are no other script errors in any run.

AWAITING_GPT_M43_C005F_PHASE2_R01_AUDIT_AND_OWNER_RUNTIME_REVIEW
