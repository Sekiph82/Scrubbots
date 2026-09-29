# M29-C002 — IMPLEMENTATION MATRIX V01 (gameplay tempo retune, SB-M29-010)

Prompt: `CHATGPT_PROMPT_V01.md` · Criteria: `CHATGPT_AUDIT_CRITERIA_V01.md` · Log: `CLAUDE_LOG_V01.md`
Owner authority: `coordination/OWNER_SCRUBBOT_SIZE_AND_GAMEPLAY_TEMPO_V01.md` §2
Focused suite: `tests/m29_c002_tempo_retune.gd` (sections s1..s8)
Evidence: `evidence/tempo_report.txt`, `evidence/tempo_report.json`, `evidence/real_host_trace_1x_2x.txt`

## Production seams changed

| Seam | Before | After |
|---|---|---|
| `ScrubbotAgent.DEFAULT_SPEED` | `6.0` | `9.0` (the only numeric travel baseline) |
| `ScrubbotDispatcher.DEFAULT_SPEED` | `6.0` | `ScrubbotAgent.DEFAULT_SPEED` |
| `AutoDispatchScheduler.DEFAULT_SPEED` (the speed the production host path hands every dispatched agent) | `6.0` | `ScrubbotDispatcher.DEFAULT_SPEED` |
| `CompleteClearingLoop.DEFAULT_SPEED` (legacy activate path) | `6.0` | `ScrubbotDispatcher.DEFAULT_SPEED` |
| `GameplaySpeedAuthority.DEFAULT_BASE_INTERVAL` | `0.5` | `1.0 / 3.0` (exact quotient) |
| `GameplaySpeedAuthority.FACTOR_1X / FACTOR_2X` | `1.0 / 2.0` | unchanged |
| `ProductionRuntimeController.MAX_LANES_PER_FRAME / MAX_STEPS_PER_FRAME` | `1 / 1` | unchanged (comment updated to the new cadence + 30 FPS service limit) |
| `ProductionGameplayHost.base_cadence` | `= DEFAULT_BASE_INTERVAL` | unchanged code; now resolves to 1/3 s |

No `Engine.time_scale`, no new factor, no new mode, no UI/economy/entitlement change.

## Criteria → evidence

| Criterion | Requirement | Proof (suite section / evidence) | Result |
|---|---|---|---|
| A | 1x travel base 9.0 | s1 `ScrubbotAgent.DEFAULT_SPEED == 9.0`; host-dispatched agent `speed == 9.0` | PASS |
| A | dispatcher / scheduler / loop use the same base | s1 constant equality + source regex: no numeric `DEFAULT_SPEED` outside the agent, no stale `6.0` | PASS |
| A | cadence base exactly 1/3 s | s1 `DEFAULT_BASE_INTERVAL == 1.0/3.0` (bit-exact), not 0.33; host `base_cadence == 1/3` | PASS |
| A | factors 1.0 / 2.0; 2x cadence 1/6 s | s1 `cadence_interval() == 1.0/6.0` bit-exact | PASS |
| A | no `Engine.time_scale` | s1 regex over speed/runtime/host/input sources + `Engine.time_scale == 1` | PASS |
| B | 1x 9 cells/s, 2x 18 cells/s, ratio 2 | s2 long 59x59 route (≥ 60 cells), 1.0 s at 60 FPS and 30 FPS: 9.0000 / 18.0000 / 2.00000 | PASS |
| B | 1x cadence 1/3 s, 2x 1/6 s, ratio 2 | s3 probe (1/1200 s step, 12 s): mean 0.333333 / 0.166667, ratio 2.000 | PASS |
| C | already-moving agent reacts to switch | s2 moving agent 18.0000 cells in the 2x second | PASS |
| C | future agents use new base | s2 agent spawned after switch 18.0000; after switch back 9.0000 | PASS |
| C | pause freezes; resume keeps speed | s2 1 s user pause → zero movement; resume 0.5 s → 9.0 cells at 2x | PASS |
| D | `MAX_LANES_PER_FRAME = 1` | s1 constant; s4 probe max lanes/frame = 1 in all 8 configs; s8 real host max assignments/frame = 1 | PASS |
| D | 60 FPS six lanes: no overlap, 2x serviceable | s4: service 0.100 s < 0.1667 s, period 0.1667, overlap 0 | PASS |
| D | 30 FPS six lanes: service-limited ~0.20 s allowed | s4: 30 FPS 6 lanes 2x period 0.2000 s (flagged `service_limited`), overlap 0, backlog ≤ 0.1667 | PASS |
| D | no second wave while lanes remain; bounded backlog | s3/s4 `overlap_begins == 0`, `max_accum ≤ interval`; 5 s hitch → ≤ 1 wave, ≤ 1 lane, no burst | PASS |
| D | no duplicate claim / clear | s8: `dup_dispatch = 0`, `dup_clear = 0`, cardinalities consistent in every real-host run | PASS |
| D | placement wake immediate only for placed lane | s3 real host: one lane queued per placement, the other slot waits for the 1/3 s event | PASS |
| E | identical gameplay truth 1x vs 2x | s5 tempo-normalised real-host level 2 (2x at dt/2): identical dispatch order/targets/colours, clear order, per-frame slot accounting, final board, WON, 2x duration exactly half | PASS |
| E | same frame clock | s5 60 FPS both speeds: both WON, same cleared set + final board, zero residue; 2x 106.4 s vs 1x 196.4 s | PASS |
| F | paid current-level 2x → 18 | s6 via the real acquisition popup: 18.0 | PASS |
| F | timed 2x new level / retry / relaunch → 18 | s6: 18.0 / 18.0 / 18.0 (relaunch = new AppState on the flushed save) | PASS |
| F | manual 1x during timed → 9 | s6: 9.0; the next retry re-applies timed 2x (18.0) | PASS |
| F | timed expiry → 9 unless M23 owns 2x | s6: 9.0; with M23 exhaustion 18.0 | PASS |
| F | M23 exhaustion free auto-2x → 18 | s6: 18.0, 0 SB spent | PASS |
| F | prices / durations unchanged | s6: 200 SB; {900: 300, 1800: 500, 3600: 750} | PASS |
| G | reset without timed → 1.0 / 9 / 1/3 | s7: factor 1.0, cadence 0.333333, 9.0 cells/s | PASS |
| H | 59x59 no storm / backlog / dup / correctness regression | s8 59x59 dense windows (5/6 slots, 1x/2x, 30/60 FPS) + same-harness historical tempo; M26/M27/M31/M32 59x59 suites; M55 long session | PASS, see log §Performance for the pre-existing selection-cost note |
| I | TASKS.md untouched; regression | see `CLAUDE_LOG_V01.md` §Regression | see log |
| J | docs stop claiming old baseline | agent / speed-authority / runtime-controller comments updated; no other current doc states 6/12 cells/s or 0.5/0.25 s | PASS |
| K | owner playtest | not closable by implementation | OWNER GATE |
