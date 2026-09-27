# M52-C001-R02 — Dispatch-Exhausted Early Slot Release — Claude Log V01

Status: **AWAITING_CHATGPT_AUDIT**
Prompt: `coordination/sessions/M52-C001/remediation/R02/SB-M52-C001-R02_EARLY_SLOT_RELEASE.md`
Owner authority: `coordination/OWNER_SLOT_RELEASE_ON_DISPATCH_EXHAUSTION_V01.md`, `coordination/sessions/M52-C001/remediation/R01/OWNER_REPLAY_RESULT_V01.md`

## SHAs

- Baseline HEAD: `01046ef680ce11e9933dee2749b8cd00a5ae8429`
- Implementation: `59336f1c93bfac4021ff5d007625379193e04f4d` (rebased on owner docs `cab4f0e`)
- Log: the commit adding this file (resulting `main` HEAD, reported in the hand-off)

## Slot lifecycle — before / after (`evidence/{baseline,after}_slot_lifecycle.json`)

Real production host, TEST stripe fixture, 60 Hz. Batch A = C01 x1 placed, its only Scrubby dispatches at frame 0 and clears at frame 688; right after A's departure the probe places Batch B (C01 x1).

| | A's physical slot while A flies | Frames showing a stale occupied "0" tile | B placed right after A's departure | A's slot after A clears |
|---|---|---|---|---|
| Baseline (`01046ef`) | occupied, displays 0 for 688 frames (11.5 s) | 688 | went to slot 3 (slot 4 still held by A) | EMPTY (A freed only at clear) |
| R02 | **EMPTY at the dispatch frame** | **0** | **slot 4 — the same physical slot** | **B, unchanged: ACTIVE, remaining 1, committed 0** |

## Draining ledger architecture (M24 `FiveSlotBatchEngine`)

- `_live_work[work_id] = {slot, batch_id, departed}`. `commit_work` creates units with `departed=false`.
- `confirm_departed(work_id)` (called by M26 **only after** `dispatch_preclaimed` succeeded for that exact work identity, i.e. a real agent exists): marks the unit departed; if the owning batch still occupies its slot, has launch capacity `remaining − committed == 0`, `committed > 0` and **every** live unit of that batch is departed, it atomically moves the **same SlotBatchState object** (exact counters) into `_draining[batch_id] = {state, slot}` and sets the physical slot EMPTY. Returns `{ok, retired, slot, batch_id}`. Never at raw `commit_work` time; a claim that is rolled back before a successful spawn never retires (tested).
- `_owner_state(rec)`: a record is owned by the batch physically in `rec.slot` **only if that batch id matches**, otherwise by `_draining[rec.batch_id]`, otherwise nothing. Slot index is provenance only.
- `resolve_clear`, `rollback_work`, `is_work_bound_to` resolve through `_owner_state`: they accept the exact original batch (physical or draining) and reject a replacement batch in the old slot. A completed draining batch (remaining 0 ∧ committed 0) leaves the ledger; a completed physical batch frees its slot. `_free_slot` / `purge_uncommitted_slot` now drop/check live work by **batch id**, never by slot index (so a replacement batch's lifecycle can't erase a draining batch's work and vice versa).
- Queries: `draining_count()`, `is_draining(batch_id)`, `draining_snapshot()`. Transaction seams: `mark_departed`, `recommit_draining_work(batch_id, work_id)`, `purge_draining_color(color)` / `restore_draining(records)`. `reset()` clears the ledger. Duplicate-batch-id placement defense includes draining ids.
- M25 `restore_claim`: restores onto the exact batch — physical (commit + departed) or draining (`recommit_draining_work`) — never onto a replacement batch in the old slot.
- M26: after dispatch success → `confirm_departed`; on retirement the slot's per-slot WAITING marker is dropped. Wave lanes are pinned `{slot, batch_id}`; `step_lane` skips a lane whose slot no longer holds that batch (a refilled slot joins a future wave only). A player placement now queues **one lane for the newly placed batch only** (`queue_lane`) instead of priming an immediate wave for every slot — with early release placements are frequent and the old immediate-wave prime would have bypassed the 1x/2x cadence for all other slots.
- Completion: `is_quiescent` also requires `draining_count() == 0` → no early WON with the last visible slot released (tested). Cardinality law unchanged (assignments == agents == claims == reservations == live work); physical occupancy is no longer tied to in-flight batches.
- UI: the slot view renders EMPTY in the same runtime tick that dispatched the final Scrubby (lane → confirm → state sync), verified on the live `BatchSlotView`.

## Anti-cross-talk reuse evidence (`tests/m52_r02_early_slot_release.gd`, 65 ok / 0 FAIL)

- **x1 acceptance**: A's only Scrubby dispatched → retired; BEFORE A clears the slot is EMPTY, A still owns 1 assignment/agent/claim/reservation/work, board ACTIVE unchanged, `rightmost_empty_index()` = that slot; B placed into the SAME slot with its own id and fresh counters; A arrives → exactly one cell cleared, A leaves the ledger; B's snapshot byte-identical before/after, still in that slot; zero identities alias B.
- **Multi-agent (x3)**: A stays physical for waves 1–2, retires on the 3rd departure with 3 in flight (draining remaining 3 / committed 3); same-color B (x5) reuses the slot; all 3 A arrivals resolve A only; B untouched.
- **Five slots**: five x1 lanes dispatch in one wave → all five slots EMPTY, five draining; five replacement batches placed while the old five fly; afterwards every replacement unchanged, cardinalities zero.
- **Stale lane**: a lane pinned to batch X never dispatches from a replacement placed in the same slot mid-wave.
- **Rollback before spawn**: claim commits capacity to 0 without dispatch → slot stays occupied; rollback restores capacity 1; `confirm_departed` fails closed for unknown ids.
- UI EMPTY same cycle; pause/focus freeze draining agents and preserve the ledger; no early WON; R01 five-BLUE x30 unchanged (no release while Scrubbys still wait).

## Rollback / Retry / Tornado

- **Retry** with a draining batch + in-flight replacement: zero assignments/agents/claims/reservations/work, draining ledger empty, slots empty, capacity 5, full board.
- **Tornado** (C01 with a draining C01 x1 and a same-slot C01 x4 replacement in flight + unrelated C02): commit purges the draining batch (`purge_draining_color`, after its claims were rolled back), leaves no C01 work, C02 untouched, cardinalities coherent. Faults injected at `tornado_slots`, `tornado_supply`, `tornado_finalize` each restore the **exact** pre-state: physical slots, draining ledger, all five cardinalities, board. (Rollback order restores the draining record before claims are re-attached via `recommit_draining_work`.) No stranded schedulable capacity survives a committed Tornado.
- **+1 Slot**: six x1 lanes retire in one wave, a released slot is reusable, Retry returns to five slots with an empty ledger.
- Callers audited: `rollback_work` (M25 rollback_claim/reset), M25 `restore_claim`, M26 reset/detach/reattach, Retry coordinator (M26 reset → M24 reset clears ledger), Tornado stages, Random/Selector (operate on physical slots at quiescence; unaffected).

## Solver consistency

No kernel behavior change. `ProofKernel` never confirms departures, so its batches free their slot on completion — which, in the wave kernel, happens before the next placement: at every quiescent decision point (where the solver branches) the kernel state equals the runtime state. Early runtime release adds no capacity and never releases an undispatched unit; it only lets the player place during travel. LOST soundness is unchanged (classifier runs only at quiescence, where the draining ledger is empty). Documented in the kernel header. Production admission still requires the owner click sequences to reach WON through the real runtime (below).

Honest note: because a released slot can be refilled while its batch still drains, a *greedy* player that places the moment any slot frees can fill the lanes with enclosed batches and legitimately deadlock (proven LOST by M27 — never a false outcome). The historical Hazard harnesses in `m29_hazard_bot_runtime_smoke` and `m33_audio_runtime` use a fixed greedy order that was proven only under completion-time reuse; at 2x it reached a genuine LOST under R02, so those harnesses now place once no released batch is draining (their assertions are unchanged). `m26_scale_59_sanity` now asserts the retired batch's `committed == BATCH` in the draining ledger instead of on the (released) physical slot.

## First 10

- Proof/replay (`tools/verify_m52_supply_candidate.gd`, evidence refreshed): Levels 2–10 all SOLVED with identical trace hashes to R01 (4098941249, 3808086370, 2842640196, 3056207161, 3310440768, 2191893116, 2524445735, 3800836965, 1480752256), solver replay PASS, owner-click replay PASS (only `elapsedMs` lines changed).
- Production runtime (`tests/m52_owner_supply_plans.gd`, 255 ok): exact owner queues, 3 visible rows, 9/9 WON with 0 ACTIVE / supply exhausted / slots empty; Level 1 supply == M23 seed-1 candidate (unchanged); frontier 11 CONTENT_MISSING; production catalog 1..10 unchanged.
- Level 2 perf (idle, i7-1260P, headless 60 Hz, `evidence/after_perf_level2_{1x,2x}.json`): WON; worst frame 18.6 ms (1x) / 18.6 ms (2x); 1 frame > 16.7 ms each, 0 > 33 ms; sim time 283 s at 1x (R01: 331 s) thanks to earlier slot reuse.

## Regression totals

- Full sweep (`godot --headless --path . -s res://tests/<suite>.gd`, 76 suites: all `m23_*`…`m42_*`, `m52_owner_supply_plans`, `m52_r01_parallel_runtime`, `m52_r02_early_slot_release`, `palette_v3_leveldata_contract`): all exit 0, 0 SCRIPT ERROR, 0 FAIL (after the harness updates above; `m52_r02` 65 ok, `m52_r01` 79 ok, `m52_owner_supply_plans` 255 ok, `m33_audio_runtime` 114 ok).
- Root `tests/run_tests.gd`: exit 0, **5323 checks, RESULT: ALL PASS**, 0 SCRIPT ERROR; 9 engine `ERROR:` lines, sorted-content hash `34c0bb32` — identical to baseline.
- `git diff --cached --check`: clean.
- Headless runs again rewrote `project.godot` (key reorder + dropped audio bus line); restored, not committed.

## Git status

`main` == `origin/main` after push; only pre-existing untracked owner/editor files remain. `TASKS.md`, owner decisions, audit/criteria files, source PNGs, owner plans, Level 1 content untouched.

`AWAITING_CHATGPT_AUDIT / M52-C001-R02 EARLY SLOT RELEASE`
