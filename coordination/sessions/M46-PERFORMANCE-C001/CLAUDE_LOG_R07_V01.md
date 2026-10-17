# M46 R07 — Remaining UI booster legality without a main-thread stall — CLAUDE LOG R07 V01

**Base and scope:**
- Base: `origin/main` `5493eb1a`.
- Prompt: `CHATGPT_M46_R07_REMAINING_UI_LEGALITY_OFFLINE_PROMPT_V01.md`. Audit context: `CHATGPT_INDEPENDENT_R06_SLOT_REBUILD_AUDIT_V01.md` (G3).
- Godot 4.7.2 headless, local desktop CPU only. **No GitHub Actions** (CLOUD_CI_DEFERRED_COST_FREEZE), no phone and no GPU.

**Result: LOCAL_PASS.** Gates:
- R06 "Checking..." / HUD-hold owner F5: still **OPEN**;
- phone / GPU: **OPEN**;
- cloud CI: **DEFERRED_COST_FREEZE**.

## 1. The two remaining call sites (from the R06 log)
1. **Rewarded-grant completion** (`acquisition_flow._apply_reward_outcome`). After a verified rewarded video it called `booster_model(host, booster)` with no legality passed, which runs synchronous `host.booster_legality`.
   - It was slow when the ad resolved before the popup's own off-frame proof settled: Watch is visible while "Checking...".
   - In that case it ran a cache-miss proof of up to 400 ms on the UI thread, then executed.
2. **FTUE coach copy** (`FtueDirector.step_copy`, booster lines of the L2 `l2_boosters_a` / `l2_boosters_b` steps). It called synchronous `host.booster_legality(id)` per booster on every copy refresh (`main.refresh_coachmark`: 0.2 s tick, copy rebuilt every 2 s or on step change).

## 2. Change (reuses the R06 seam only)
**No second worker, no new proof engine, no cap change, no new text.**
- **Rewarded:** legality comes from `host.booster_legality_offframe(booster)`, which answers from the exact-state cache or starts or reuses the single R06 worker.
  - **Proven legal:** the existing execute runs at once, from the cache.
  - **`checking`, no-target booster (Random / +1 Slot):** the popup's existing R06 `auto_use` is armed and the status says "Booster saved!". When the proof settles legal, the granted charge is used exactly once; on a refusal or timeout it is kept.
  - **Selector / Tornado:** never auto-used (they need a chosen target).
  - **Cached timeout:** charge saved at once with the R06 retry text; no worker, no proof.
  - **Grant earned is kept separate from activation proven safe:** the rewarded service, receipts and ad requests are unchanged.
- **FTUE:** booster lines use `booster_legality_offframe`.
  - `checking` makes no claim either way: the "not now" suffix is omitted and no new string is added.
  - `main.gd` connects each launched host's `booster_proof_settled` to an immediate coach-copy refresh, so the proven verdict shows at once.
- **Host (peer-review fix):**
  - `_proof_closed` is set first in `_exit_tree` and reset in `_enter_tree`.
  - While closed, `needs_offframe_proof` is false and `booster_legality_offframe` returns a cheap `exiting` refusal. So the settle that fires during the exit's cancel cannot start a never-joined worker or a synchronous proof.
- **Popup (peer-review fix):** the deferred auto-use runs only if that popup is still valid, open, on top and not busy (`_auto_use`).
- **Adapter:** `offframe_budget_ms`, a test seam. The production default is `PROOF_TOTAL_MS` = 5,000; only tests lower it, to force a timeout.

## 3. Evidence — new `tests/m46_r07_ui_legality.gd`
Real app (main scene), rewarded provider test double. Each async case asserts its branch was reached (worker running, `auto_use` armed) and counts synchronous proofs (`live_proof_count`).

| Case | Result |
| --- | --- |
| L1 still, ad completes while checking | +1 charge, "Booster saved!", "Checking...", Use blocked, auto-use armed, **0 main-thread proofs**. Settled 266–655 ms later: charge used once, popup closed, 1 receipt, SB unchanged. Worst wait frame 0.3–1.9 ms; the settle + auto-use commit frame is 16.6–40.8 ms (report-only, the Random commit + UI). |
| Ad after the proof already settled legal | immediate use, no worker, no proof, 1 receipt |
| Ad on a cached timeout | charge saved at once, retry text, no worker, no proof, no auto-use |
| Selector rewarded while checking | charge kept, never auto-used, 19 proven chips, Use waits for a target |
| Close mid-check | worker cancelled, charge kept, nothing cached. Reopen → "Checking..." → proven → Use enabled; Use → charge used once from the cache |
| Forced timeout (`offframe_budget_ms` = 1) | charge kept, retry text, Use blocked, auto-use disarmed. Reopen on the same state = cached, no worker, no proof. After a real move the player retries: a fresh check settles |
| Scene exit mid-check | settle observed, nothing running after it, `live_proof_count` unchanged, host freed, charge kept, 1 receipt |
| L2 still (not provable) | charge kept, supply untouched, no proof, worst frame 0.6–2.6 ms. Unsafe within 2.25 s in one run, the 5 s cap in another |
| FTUE L2 | phase A Selector line starts the shared check (no claim while checking, no proof); the settle re-renders the copy: "not now" iff the proven verdict refuses (worst frame 0.5–1.2 ms) |
| FTUE stale | phase B Random check, then a move mid-check: no settle stored a Random verdict under the old state; at the next still moment the copy re-checks and shows the proven verdict |
| FTUE modal | modal open → coach hidden, no proof started |
| FTUE exit | tips active, host released mid-check: no new worker or proof on the exiting host |
| FTUE Skip Tips | accepted once; wallet / charges unchanged |

**Failing variant:** with the two call sites temporarily restored to the old synchronous calls, the test reported **FAIL (11)**, every "no main-thread proof" assertion among them. This ran on the test version before the peer-review additions. The fix was restored and verified by grep.

## 4. Regressions (local, sequential, final code)
All **PASS**, run one at a time:

| Suite | Result |
| --- | --- |
| m46_r07_ui_legality | PASS |
| m43_c003_c001_acquisition | 34/34 (incl. rewarded booster c18–c21) |
| m44_ftue | 23/23 |
| m43_c004_c001_fail_need_a_hand | 40/40 |
| m43_c005f_phase3_meta_rewards_acquisition | 15/15 (announced spy-plugin fault lines) |
| m39c_boosters | PASS |
| m39e_full_matrix | PASS |
| m39_v02_atomicity | PASS |
| m39_v02_capacity | PASS |
| m39_v02_integration | PASS |
| m39_v03_full_surface | PASS |
| m39_v03_integration | PASS |
| m39_v04_integration | PASS |
| m39_v04_tornado_inflight | PASS |
| m39_c003_random_any_booster_rewards | PASS |
| m28_c002_c003_final_gate | 22/22 |
| m28_c002_c001_gameplay_v02 | 14/14 |
| m55_core_chaos | PASS |
| m30_completion_authority | PASS |
| m46_slot_rebuild | PASS |
| run_tests | ALL PASS |
| m46 `rs budget slice` (p20 + p21 + p22) | PASS; only the subset-ledger line fails, by design |

**m46 load note:** the 59×59 HUD Random settled after about 2.97 s, with worst wait frame 6.1–7.5 ms and a settle + auto-use frame of 55–58 ms (report-only). Other projects' headless Godot processes were running on this machine at the time.

## 5. Review
A distinct `CLAUDE_PEER_REVIEW` (not ChatGPT) gave **PASS_WITH_MINORS**: no blocker, no major. Findings 1 and 3–6 are fixed; finding 2 is accepted. See `CLAUDE_PEER_REVIEW_R07_V01.md`.

## 6. Notes and open items
- **FTUE worker churn:** while the L2 booster tip shows during unpaused play, the coach may restart the worker after each move. This is bounded (one worker, 5 s cap, no main-thread cost).
- **Unchanged by owner reservation:** Need-a-Hand next-start proofs stay unbudgeted and deterministic.
- **Remaining synchronous fallbacks are accepted R05 / R06 behaviour:** `detached_copy()` null, and harness hosts without the R06 method.
- **Wording:** "Booster saved!" briefly sits next to "Checking..." before an auto-use closes the popup. Both are existing strings, so this falls under the owner F5 gate.
- **Test dependency:** the test boots `scenes/app/main.tscn`, which carries the owner's uncommitted working-copy edits; they were left untouched.
- **Open:** owner F5 for R06 (and the R07 popup states), phone / GPU, ChatGPT audit of R07, cloud CI.

## Footprint
- `user://m46r07_*` saves (and their `.bak` / `.tmp`) are deleted by the test: 0 remain.
- The failing variant and the probe lines were removed (verified by grep).
- No owner file was touched.
