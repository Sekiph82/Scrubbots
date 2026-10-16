# M46 R04 — Booster legality in-flight shortcut — CLAUDE LOG R04 V01

**Base and scope:**
- Base: `origin/main` `38229274`, R03 left PARTIAL as the owner chose.
- Owner instruction in chat: "continue with the next M46 or other offline work".
- This cycle addresses R03 open finding 1: Selector legality cost about 0.6 s at 59×59.
- Godot 4.7.2 headless local only. **No GitHub Actions**, no phone and no GPU.

**Result: LOCAL_PASS for the change.** Full-suite timing is still not re-recorded: a busy Godot process was using about one core (5.06 CPU-s / 5 s), and R03 remains PARTIAL by owner choice.

**Correction (R05):** that process was assumed to be the owner's editor without checking its command line. It may instead have been an orphaned test process. See the R03 log correction.

## Root cause, measured
One Selector eligibility proof per remaining batch was profiled at 59×59 with 67 bots in flight. Per batch:

| Step | Time |
| --- | --- |
| `ProofState.from_runtime` (full 3,481-cell state) | 6.0 ms |
| supply candidate load | 1.3 ms |
| column snapshot | 1.0 ms |
| scratch slots | 0.27 ms |
| select | 0.08 ms |
| `DeadlockClassifier.classify` | 0.018 ms |

The classifier answers PROGRESSABLE on its first statement whenever M26 work is in flight, so it never reads the state that took 6 ms to build. For 110 batches, `eligible_safe_batches` took 927 ms.

## Change (scripts/economy/production_booster_adapter.gd)
`_is_safe_probe` returns true early when `_inflight() > 0` and `_proof_state_buildable(...)`.

- The helper mirrors every null condition of `ProofState.from_runtime`:
  - LevelData type;
  - board present;
  - slots present;
  - BatchSupplyEngine type;
  - cell count match.

  So a state that would have failed still fails. With nothing in flight, the full proof runs unchanged.
- The `_inflight()` value is read once and reused for `classify`.
- Callers: the Random 3-step proof, plus Selector `eligible_safe_batches`, `has_eligible_safe_batch` and `is_batch_eligible` (the latter from R03).
- `next_start_prover` / Need-a-Hand build their adapter with no scheduler, so in-flight is 0 there and the shortcut never fires.

## Measured (59×59 stripes, desktop, contended machine)

| | Before | After |
|---|---|---|
| `eligible_safe_batches` (110 batches, standalone probe) | 927 ms | 160 ms |
| Selector legality in p20 (92 batches) | about 580–620 ms | about 119–151 ms |
| Random legality | about 22–31 ms | about 3 ms |
| Selector execute (R03 fix) | 641 ms | about 40–53 ms |

## Evidence
`tests/m46_performance.gd` p20 now also asserts two things:
- **Verdicts match:** with 38 bots in flight, `_is_safe_probe` equals the full `ProofState.from_runtime` + `classify` verdict for all 92 batches' real post-placement scratch states.
- **Every from_runtime refusal holds with bots in flight:** null slots, a non-engine supply, and a 20×20 board under a 59×59 level are all false; the valid state is true.

**p20 standalone:** PASS, frame mean 2.27 / p99 8.2 ms. Other p20 assertions are unchanged and PASS: Random and Selector are charged once and their effects verified, plus the R03 equivalence of `is_batch_eligible`.

**Regressions:** all PASS, with no script diagnostics:

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
| m28_c002_c003_final_gate | 22/22 |
| m55_core_chaos | PASS |
| m43_c004_c001_fail_need_a_hand | 40/40 |
| m43_c003_c001_acquisition | 34/34 |

**Review:** a distinct fresh-context `CLAUDE_PEER_REVIEW` (not ChatGPT) verified exact equivalence: class identities, every null path, `classify`'s first statement, and all callers. It found 0 blockers / majors. Its MINOR (the guard test was near-tautological without null-mirroring cases) is fixed above.

## Still open
- **Quiet moments with no bots in flight:** the full proof runs per batch, about 9 ms each, so the popup list can still take about 1 s at 59×59. The R03 finding of one roughly 5.1 s Random refusal proof is also in this case.
- **Bounding the classifier** (visit / time budget → UNKNOWN_BOUND, which fails closed) would trade more refusals for speed. That is an owner-visible behaviour change and was not made.
- **Phone / GPU, ChatGPT audit, cloud CI:** all still open.

## Footprint
- The temporary diagnostic script `tests/_m46_diag_tmp.gd` was deleted.
- Fixtures are fixed-name `user://m46_*.json`, deleted by the suite.
- No owner file or editor process was touched.
