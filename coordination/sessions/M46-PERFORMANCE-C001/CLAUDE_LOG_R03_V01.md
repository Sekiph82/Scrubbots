# M46 R03 — Random + Selector boosters under 59×59 load — CLAUDE LOG R03 V01

**Base and tool:**
- Base: `origin/main` `6e79d7b6`. The owner asked for this task in chat, after R02 recorded Random/Selector under load as open.
- Tool: Godot 4.7.2.stable headless (`godot_console.exe`, WinGet).
- **No GitHub Actions** run. The job guards are unchanged. Everything here is LOCAL only: desktop CPU, with no phone and no GPU.

**Result: R03_PARTIAL**
- **Functional:** every gate passes. `p20` passes standalone repeatedly, and every functional assertion of all 20 cases passed in each of 3 full-suite runs.
- **Timing:** the full-suite timing gates are **not stable on this laptop right now**. Each full run had exactly one timing failure, in a different case each time (p20 p99, then p19 FULL p99, then p18 mean / p99). Every one coincided with a fixed CPU calibration workload slowing down 2.5–9× (23 → 215 ms).
- **Cause:** the owner's open Godot editor was using about one full core (4.95 CPU-s in 5 s), plus the ChatGPT and Codex apps.
- **Not done about it:** budgets were not loosened, and the timing gates were not made load-aware. A clean full-suite timing run needs an uncontended machine.

## New p20 (tests/m46_performance.gd)

### Phase A: pocket level (sealed colours, WAITING)
Random was tried at 5 moments, each with at least 3 free slots, paid with charges only.

**Checked on every outcome:**
- A success spends exactly one charge, leaves SB untouched, and reorders the live supply with every batch / colour / count conserved.
- A `not_solver_safe` refusal mutates nothing.

**Final runs:** 5 / 5 legal, at about 55–140 ms each.

### Phase B: stripe level (every colour reachable)
- **Selector with a non-eligible batch:** refused with `not_eligible`, nothing changed.
- **Random:**
  - legal on the first try;
  - charge 1 → 0, SB untouched;
  - 103 supply batches reordered and conserved, slots untouched.
- **Selector:**
  - legal on the first try, with 92 eligible batches;
  - the chosen batch moved from supply into a slot (+1 occupied, −1 supply);
  - charge 1 → 0, SB untouched.
- **Outcome:** level WON 3,481 / 3,481. Frame mean 2.2–2.9 / p99 8.3–15.1 ms standalone.
- **Terminal:** both boosters are refused with `terminal`, and nothing changes.

### Why the first p20 runs failed (test design, now fixed)
Random's owner rule proves **3 consecutive accepted front placements on the live slot state**. My feed kept all slots topped up, so Random was never legal (53 tries, `not_solver_safe`), even on the stripe level.

The suite now stops topping up until the needed slots are free: 3 for Random, 1 for Selector. An earlier claim in my draft, that the pocket reversal is inherently unsafe, was **wrong**, and it was removed once measured.

## Production change: Selector execute is about 15× faster
- **Problem:** `BoosterService.apply_selector` used `adapter.eligible_safe_batches().has(id)`. That re-runs the solver-safety proof for **every** remaining batch just to check the one chosen.
- **Fix:**
  - New `ProductionBoosterAdapter.is_batch_eligible(id)` applies the same rule — empty slot + the batch in supply + post-placement safety via `_selector_reorder_solvable` — for that batch only.
  - It rejects non-String/StringName input up front.
  - The service uses it when the adapter has it and falls back to the old call otherwise; test fakes take the fallback.
- **Measured:** Selector execute went from **641 ms to about 44 ms** on 59×59 desktop. The same batch is chosen with the same outcome.
- **Equivalence:**
  - p20 asserts `is_batch_eligible(id) == eligible list membership` for all 92 supply ids.
  - Unknown / null / int inputs are false, and a StringName id is accepted.
  - A separate fresh-context `CLAUDE_PEER_REVIEW` (not ChatGPT) found it semantically equivalent: 0 blockers / majors. Its MINOR (no equivalence test) and its reason-check NIT were fixed.
- **Regression:** all PASS, with no script diagnostics:

| Suite | Result |
| --- | --- |
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
| m28_c002_c001_gameplay_v02 | 14/14 |
| m43_c004_c001_fail_need_a_hand | 40/40 |
| m43_c003_c001_acquisition | 34/34 |

## Findings (report-only, open)
1. **Selector legality, about 0.6 s at 59×59 desktop (up to 1.75 s under contention).**
   - `booster_legality(selector)` lists every eligible batch: 92 solver proofs. The Booster popup runs it to show its target chips.
   - On a phone this is likely a multi-second freeze.
   - Candidate fixes: lazy or incremental listing, a cap on listed targets, or a background or chunked proof. Each changes what the popup shows, so the owner should agree on the UX before it changes.
2. **Random legality / refusal proof: one 5.1 s `not_solver_safe` verdict observed** in a diagnostic run on the pocket level.
   - That run had a different funding sequence, so the board state differed. It was not reproduced in the final deterministic fixture, where all attempts were about 60 ms.
   - Cause: the DeadlockClassifier's progress search runs unbounded-in-time when nothing is in flight.
   - Bounding it (visit / time budget → `UNKNOWN_BOUND`, which already fails closed) would make Random refuse more often. That is a behaviour tradeoff in audited M27 / M39 code. Proposed as a separate follow-up, with a deterministic reproduction first.
3. **Random execute 45–113 ms and Tornado about 51 ms:** one-off player actions, recorded.
4. **Calibration line:** each case group now prints `calib` (150 production routes on a fixed dense board), so a timing failure can be attributed to machine load.

## Footprint
- Only fixed-name `user://m46_*.json` fixtures, deleted by the suite; 0 remain.
- One temporary diagnostic print was removed.
- No owner file, save or editor process was touched. The owner's running Godot editor was left alone.
