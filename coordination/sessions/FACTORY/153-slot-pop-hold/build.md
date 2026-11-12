STATUS: READY

# Build: SB-PHONE-2026-11-12-F, a finished slot waits for its finish pop

## Summary
Owner 2026-11-12: when a slot's batch is used up, the finish pop plays (BoosterVfx pop_batch: lift + burst + stars, preset C = 1.60 s). That slot now takes no new supply pick until the pop is over. Other empty slots work as before.

How it works:
- **Hold state.** `FiveSlotBatchEngine` has a per-slot finish hold (slot index -> seconds left). A held slot is still EMPTY to the proof, completion, scheduler and `is_empty()`. Only `rightmost_empty_index()` skips it. Every supply pick goes through that query: `select_front_batch` for tap input and the Selector booster, and the real-play driver. So a fast tap cannot land in the held slot, and nothing is queued. When every empty slot is finishing, a pick gets the existing `slots_full` rejection: no spawn and supply untouched.
- **Where the hold comes from.** `GameplayScreen.refresh_slot_snapshot()` now returns the indices of the slots whose pop it just started. The host's `_refresh_slots()` holds each of those slots for `BoosterVfx.pop_duration()`, so the hold is exactly what is shown:
  - Reduced Effects or a Retry reset shows no pop, so there is no hold.
  - When the overlay has no live pop any more (Reduced Effects switched on mid-pop, or the overlay is gone), every hold is cleared on the next sync.
- **Clock.** `ProductionRuntimeController.tick()` advances the holds by the unscaled real delta, before the pause and terminal freezes. The pop keeps playing in real time through pause, terminal and 2x, so the hold can never outlast it. `reset()` (Retry / new attempt) and the +1 Slot rollback clear holds. The sixth slot behaves the same as the others.
- **Small extras.** A 0.0001 s epsilon absorbs float drift, so the hold ends on the same tick the pop leaves (96 ticks at 1/60). `terminal_context().slots_full` now uses `is_full()`, so its meaning is unchanged.
- **Real-play solver.** `RealPlayDriver` plays through the real host, so it applies the hold automatically. It also treats a running hold as not quiescent, so a held slot is not misread as "stuck".
- **ProofKernel / ProofState are not affected.** They are timeless and have no clock. A held slot is EMPTY truth there, and it frees within 1.6 s. The booster scratch slots (Random 3-step proof) also stay timeless.
- **L30 replanned.** Under the hold, the L30 `level_030_clown` plan lost in real play (LOST at frame 3549). I regenerated it with the existing tool `tools/real_play_verify.gd --levels 30 --regen`: SOLVED in 92/400 nodes, WON in 26037 frames. That rewrote only the plan's `intendedColumnClicks` and the L30 provenance record. L1..L29 still win with their current clicks.

Files:
- scripts/gameplay/slots/five_slot_batch_engine.gd
- scripts/gameplay/runtime/production_runtime_controller.gd
- scripts/gameplay/runtime/production_gameplay_host.gd
- scripts/ui/gameplay_screen.gd
- scripts/ui/feel/booster_vfx.gd (doc comment only)
- scripts/gameplay/solver/real_play_driver.gd
- tests/sb_phone_2026_11_12_f_slot_pop_hold.gd (new)
- tests/m46_performance.gd (its "free slot" waits now count pickable slots: empty and not held)
- tests/sb_m22_008_polish_013_slot_fx.gd (header comment)
- .github/workflows/android-family-first10.yml (new suite + exact 46/46 guard)
- data/levels/supply/level_030_clown_supply_v1.json
- data/levels/supply/real_play_provenance_v1.json

Commits: cee6b87d (feature + tests + CI), c99975a5 (L30 plan regeneration).

## Acceptance criteria
1. [x] **The finished slot rejects a pick during its pop and accepts one right after.** sb_phone_2026_11_12_f_slot_pop_hold `_hold_then_accept`:
   - during the pop, slot 4 is EMPTY but `rightmost_empty_index` = 3;
   - slot 4 is never offered for a pick while held;
   - the hold lasted 96 ticks = 1.600 s (pop 1.60 s) and ended on the same tick the pop left the overlay;
   - no pick was consumed while waiting;
   - the next pick lands in slot 4.
2. [x] **Another empty slot accepts a pick during the pop.** `_other_slot_usable`: the pick lands in slot 3 while slot 4 is held.
3. [x] **All empty slots finishing means no spawn.** `_all_finishing_no_spawn`:
   - five x1 batches finish together and all five slots are held;
   - a tap returns `slots_full` with supply, slots and agents unchanged;
   - after the pops nothing was queued, and the next pick lands in slot 4.
4. [x] **Reduced Effects.**
   - With Reduced Effects on, there is no pop and no hold, and the same slot takes the pick at once.
   - Switching Reduced Effects on mid-pop releases the hold on the next tick.
5. [x] **The hold cannot get stuck.**
   - User pause: the hold runs out while the pop plays. Pause still blocks picks by itself, and after unpausing the slot takes the pick.
   - Terminal stop: the hold still runs out.
   - `reset()` clears all holds.
   - Invalid slots and 0 s pops make no hold.
   - Pop or overlay removed early: covered by the Reduced-on-mid-pop case (`clear_pops`), using the same `pop_count() == 0` release path.
6. [x] **+1 Slot.**
   - The sixth slot (index 5) is held after its batch.
   - A pick during the pop goes to slot 4.
   - After the pop, slot 5 takes picks again.
   - `rollback_grow_to_sixth` drops its hold.
7. [x] **The real-play solver models the same hold.** It runs through the real host, plus the quiescence fix. real_play_levels PASS (4/4): all 30 levels WON at 1/60 after the L30 regen. real_play_file_cli PASS (6/6).
8. [x] **New suite in CI with an exact guard.** It runs in about 10 s headless. Guard: `SB-PHONE-2026-11-12-F SLOT POP HOLD: PASS (46/46 cases, 0 fail)`.

## Validation
All results are LOCAL_PASS on Godot 4.7.2 headless, in the worktree after a one-off `--import`.
- `python tools/run_suites.py` (the full CI list, 93 suites, run after the final code change): aggregate=PASS (93/93). Selected lines:
  - sb_phone_2026_11_12_f_slot_pop_hold PASS (46/46)
  - real_play_levels PASS (4/4)
  - real_play_file_cli PASS (6/6)
  - m46_performance PASS (22/22)
  - m55_long_session PASS
  - sb_m22_008_polish_013_slot_fx PASS
  - sb_polish_003_booster_vfx PASS
  - campaign_l11_l30 PASS (5/5)
- Content validator (`tools/validate_content.gd`): CONTENT_VALIDATION PASS (30 entries, 0 problems).
- Suites outside the CI list that touch slots, input, real-play or boosters: all exit 0 with a PASS last line.
  - m24_blue_fixture_evidence, m24_five_full_refill_evidence, m24_slot_state_evidence, m24_supply_handoff_evidence, m24_v02_transaction_hardening_evidence
  - m29_input_gate_evidence, m29_slot_display_sync_evidence, m29_exact_slot_origin_evidence
  - m52_r02_early_slot_release, m52_r01_parallel_runtime, m52_owner_supply_plans
  - m46_slot_rebuild, m46_r07_ui_legality, m46_rm006_selector_proof_integrity (5/5 groups)
  - m39_v02_capacity, m39_v02_integration, m39_v03_integration, m39_v04_integration, m39_v04_tornado_inflight
  - m30_completion_authority, m30_transaction_safe_retry
  - m55_core_chaos, m55_player_chaos
  - Two of these print SCRIPT ERROR lines, and both are deliberate fault injections that the tests label themselves: m46_rm006 (`rm006_injected` faults) and m55_player_chaos (`EXPECTED_FAULT_INJECTION` 'explode').
- Baseline check (feature stashed, origin/main code): real_play_levels PASS 4/4 and m46_performance PASS 22/22. The failures listed in the Log below were caused by this change and are fixed.
- `git diff --cached --check` was clean. The tracked tree is clean. Import-generated untracked `.import` / `.uid` files are left alone.

## Log
### Round 0
- Implemented the finish hold: engine state, host wiring from the pops the screen starts, runtime clock, and real-play quiescence.
- First full CI run: 90/93.
  - real_play_levels: L30 LOST under its plan.
  - m55_long_session: L30 LOST.
  - m46_performance: Random kept failing `not_solver_safe` while robots moved. Cause: I had first copied the holds into the booster scratch slots, which made the timeless 3-step proof see held slots as full.
- Fixes:
  - Removed the scratch copy, so booster proofs stay timeless like ProofKernel.
  - Regenerated the L30 clicks with the existing real-play regen tool.
  - Made the m46 free-slot waits count pickable slots. One "moving" Selector sample had correctly been not_eligible because all three free slots were finishing.
- Second full CI run: 93/93.
- Notes for review:
  - Players with Reduced Effects on get no hold, so they can refill slightly faster than the solver's default-effects timing. That is the "never hold longer than what is shown" rule.
  - The `framesAtCanonical` values of L1..L29 in the provenance file are from before the hold. They were only rewritten for regenerated levels; real_play_levels checks only status and plan sha.
  - TASKS.md was not edited, per the job prompt.
