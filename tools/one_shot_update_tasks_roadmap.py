from pathlib import Path
import re

path = Path('TASKS.md')
s = path.read_text(encoding='utf-8')

if '### M23 — Batch Supply Engine' in s:
    raise SystemExit('New batch-engine roadmap already present; refusing duplicate rewrite.')
if '### M23 — Gameplay Screen Layout' not in s:
    raise SystemExit('Expected old M23 Gameplay Screen Layout anchor not found.')

# Shift every existing milestone reference M23+ forward by five in one pass.
def shift_milestone(match):
    n = int(match.group(1))
    return f'M{n + 5:02d}' if n >= 23 else match.group(0)

s = re.sub(r'\bM(\d{2})\b', shift_milestone, s)

status = '''## Project Status

- Current Milestone: M23
- Current Sprint: M23-C001 V01 — Batch Supply Engine foundation
- Current Task: M23-C001-V01
- Current Task Status: READY
- Next Task/Action: ChatGPT prepares the strict M23-C001 V01 implementation prompt and audit criteria for the owner-locked Batch Supply Engine. Claude then implements only M23, preserving the accepted M22 Railroad V1/V07 routing, ReservationState, TargetSelector, dispatcher and authenticated clearing contracts. Root `TASKS.md` remains ChatGPT-write-owned.
- Required Actor: CHATGPT
- Tracking Repository: Sekiph82/Scrubbots
- Tracking Branch: main
- Progress: 348 / 885 = 39.32% (game+ui live scope); lastCompletedTaskId M22-C001-V07. The denominator increased by 156 newly owner-defined core-gameplay tasks across M23–M27. The 224 Level Factory + Content Platform requirements remain canonical in `Sekiph82/ScrubBots-Level-Factory` and are excluded from this repository's live denominator.
- Note: M22 Railroad V1 engineering is closed for tracker purposes by the V07 implementation evidence (`4823` checks, `0` failures), the owner-locked interior-turn routing revision, and owner manual acceptance on 2026-09-17. The straight-only post-rail rule is superseded: Railroad travel remains exterior/rail-only, but after a legal ingress Scrubbots may traverse OPEN/CLEARED board corridors orthogonally with one or more 90-degree turns. The next core-gameplay program is M23–M27: Batch Supply Engine → Five-Slot Batch Engine → Batch Target Claim Engine → Auto Dispatch Scheduler → Solvability / Deadlock Engine.
'''
s = re.sub(r'## Project Status\n\n.*?\n## Tasks', status + '\n## Tasks', s, count=1, flags=re.S)

s = re.sub(
    r'\*\*Current sprint — V02:\*\*.*?\n\n(?=- \[x\] SB-M22-001)',
    '''**Railroad V1 closure — V07 + owner acceptance (2026-09-17):** the accepted production movement contract is now exact clicked-slot anchor → visible BOTTOM connector → canonical Railroad V1 exterior travel → legal rail ingress → four-neighbour orthogonal OPEN/CLEARED interior corridor with one or more 90-degree turns → assigned ACTIVE target. Non-target ACTIVE cells remain blockers; no diagonal/corner-cut/teleport/free-space shortcut and no retargeting are allowed. V07 implementation evidence recorded 4,823 checks / 0 failures and preserved the fresh Hazard Bot C08 first target `380/(0,19)`. Owner manual review confirmed the routing correction. The earlier straight-only final target approach is superseded.\n\n''',
    s,
    count=1,
    flags=re.S,
)

done_ids = ['009'] + [f'{i:03d}' for i in range(26, 36)]
for tid in done_ids:
    s = s.replace(f'- [ ] SB-M22-{tid}', f'- [x] SB-M22-{tid}')

s = s.replace(
    'SB-M22-031 Leave railroad only at exact target row/column alignment and use an orthogonal final target approach; never retarget.',
    'SB-M22-031 Leave Railroad V1 only through a legal rail ingress into OPEN/CLEARED perimeter space; permit four-neighbour orthogonal interior-corridor routing with one or more 90-degree turns; never retarget.'
)

old_slots = '''### 8.8 — Five slots `[LOCKED]`

Primary gameplay presentation: **5 slots**. Player-visible gameplay uses
five slots. Internal code may stay configurable where sensible, but the
production game currently requires exactly five visible active slots.

### 8.9 — Scrubbot behavior `[LOCKED]`'''
new_slots = '''### 8.8 — Five batch slots `[OWNER-LOCKED 2026-09-17]`

Primary gameplay presentation uses **exactly five batch slots**. They start EMPTY.
The player never chooses a destination slot. Selecting a legal supply batch automatically
places it into the **rightmost currently EMPTY slot**. Existing occupied slots never shift
or reorder. If all five slots are occupied, a supply selection is rejected atomically and
the supply column must not advance.

Duplicate colors across multiple occupied slots are legal and are part of the puzzle.
Each occupied slot owns one immutable batch identity with color, initial robot count,
remaining-to-clear count, committed/in-flight count, placement sequence and lifecycle state.

### 8.8A — Batch supply columns `[OWNER-LOCKED 2026-09-17]`

- Production supply supports 3, 4 or 5 independent FIFO columns.
- V1 gameplay validation uses **three visible rows per column**.
- Only the front/top batch in each column is selectable.
- Row 2 and Row 3 are preview-only future batches.
- Everything deeper than the preview window is hidden from the player.
- Selecting a front batch advances **only that column** by one position.
- The previous Row 2 becomes selectable, Row 3 becomes Row 2, and the next hidden batch
  enters Row 3. Other columns remain unchanged.
- Each batch is `color + positive robot_count`; its identity is stable once generated.
- Supply generation must conserve the level's logical color totals and must ultimately be
  accepted only when the Solvability Engine proves at least one legal completion sequence.

### 8.8B — Batch quota / slot lifecycle `[OWNER-LOCKED 2026-09-17]`

A batch count means the number of matching logical pixels that batch must successfully clear.
A count is **not** spent when a robot is merely spawned. It decreases only after an
authenticated arrival clears the batch's assigned target pixel. A batch with remaining quota
but no currently targetable matching pixel enters WAITING and stays in its slot. It resumes
automatically when later clearing exposes a legal matching target. A slot becomes EMPTY only
when the batch has zero remaining work and zero committed/in-flight assignments.

### 8.8C — Same-color arbitration and target claims `[OWNER-LOCKED 2026-09-17]`

Future inaccessible pixels are never pre-claimed. When a matching pixel becomes currently
targetable, same-color occupied batches compete deterministically by **oldest placement first
(FIFO)**. The oldest batch with uncommitted quota receives priority; if its remaining dispatch
capacity is exhausted, additional targets may flow to the next same-color batch.

A target claim and ReservationState reservation must be atomic. One logical pixel may belong
to at most one live assignment at a time, regardless of how many same-color batches are in
the five slots. Existing TargetSelector bottom-most/left-most ordering remains the target-order
policy among currently targetable, matching, unreserved cells.

### 8.8D — No ghost robots `[OWNER-LOCKED 2026-09-17]`

**No target, no reservation, no valid route, no robot.** A Scrubbot may be instantiated only
after a unique matching target has been selected, atomically reserved/claimed, and a legal
route to that exact target has been produced and validated. A spawned robot never wanders,
never spawns without work, never silently retargets, and never shares a target with another
robot. Route-build failure releases the provisional claim/reservation and consumes no batch
quota.

### 8.8E — Solvability and deadlock `[OWNER-LOCKED 2026-09-17]`

Generated supply is production-valid only if a deterministic solver can prove at least one
legal player-choice sequence that clears the entire level under the real five-slot, FIFO
column, targetability, claim, routing and batch-quota rules. Runtime must distinguish temporary
WAITING/STALLED states from a proven deadlock. In-flight work or any legal future action that
can open progress means the position is **not** deadlocked. A deadlock may be declared only
when no legal future action sequence can produce further authenticated clearing.

### 8.9 — Scrubbot behavior `[LOCKED]`'''
if old_slots not in s:
    raise SystemExit('Locked five-slot rule anchor not found.')
s = s.replace(old_slots, new_slots, 1)

new_milestones = r'''### M23 — Batch Supply Engine `[OWNER-LOCKED CORE GAMEPLAY]`

Purpose: create the player-facing color/count supply queues that drive the real ScrubBots puzzle. This milestone owns batch data, queue/preview semantics and candidate generation, but does not own five-slot execution, target claims, robot dispatch or solvability proof.

- [ ] SB-M23-001 Define immutable `ColorBatch` value contract.
- [ ] SB-M23-002 Give every batch a stable unique `batch_id` for the lifetime of a session.
- [ ] SB-M23-003 Store canonical palette/color ID, never presentation-only color guesses.
- [ ] SB-M23-004 Store strictly positive integer `robot_count`; reject zero, negative, float, string or overflow values.
- [ ] SB-M23-005 Preserve per-color conservation: total generated batch quota for each color must equal that level's required ACTIVE logical-pixel count for that color unless a later explicit owner rule changes the economy.
- [ ] SB-M23-006 Reject supply containing palette IDs absent from the loaded level/palette contract.
- [ ] SB-M23-007 Support exactly 3, 4 or 5 independent supply columns as configuration; do not hard-code one layout into gameplay truth.
- [ ] SB-M23-008 Support configurable visible preview depth 3 or 4, with V1/Hazard Bot validation locked to exactly 3 visible rows.
- [ ] SB-M23-009 Make only the front/top batch of each column selectable.
- [ ] SB-M23-010 Make visible Row 2 and Row 3 preview-only in V1; they must reject gameplay activation.
- [ ] SB-M23-011 Keep every batch deeper than the visible preview window hidden from player-facing query/UI APIs.
- [ ] SB-M23-012 Implement each supply column as an independent FIFO queue.
- [ ] SB-M23-013 Selecting a legal front batch removes exactly that one front item from exactly that one column.
- [ ] SB-M23-014 After selection, advance that column by one: old Row 2→front, old Row 3→Row 2, next hidden→Row 3.
- [ ] SB-M23-015 Prove selecting one column does not mutate ordering/content of any other column.
- [ ] SB-M23-016 Expose read-only front-batch queries for gameplay selection.
- [ ] SB-M23-017 Expose read-only preview queries that cannot reveal hidden queue contents.
- [ ] SB-M23-018 Make supply consumption transactional so a rejected downstream slot placement cannot accidentally pop/advance the column.
- [ ] SB-M23-019 Define deterministic seedable candidate generation for reproducible tests/replays.
- [ ] SB-M23-020 Persist/report the generation seed with the session fixture/evidence.
- [ ] SB-M23-021 Partition each level color total into legal positive batch sizes without losing or inventing quota.
- [ ] SB-M23-022 Distribute generated batches across configured columns without changing per-color conservation.
- [ ] SB-M23-023 Avoid malformed queues: no null batch, duplicate `batch_id`, negative count, invalid color or impossible index.
- [ ] SB-M23-024 Define clean end-of-column behavior when fewer than the normal preview rows remain.
- [ ] SB-M23-025 Define clean end-of-supply behavior when every column is exhausted.
- [ ] SB-M23-026 Provide deterministic reset to the exact initial queue/seed state.
- [ ] SB-M23-027 Provide snapshot/query data needed later by save/replay systems without coupling to UI Nodes.
- [ ] SB-M23-028 Build Hazard Bot candidate supply fixtures from the real 20×20 level color totals.
- [ ] SB-M23-029 Validate rectangular-board and 59×59 quota/conservation behavior.
- [ ] SB-M23-030 Add invalid-input, deterministic-generation, FIFO, hidden-preview and conservation regression tests.

### M24 — Five-Slot Batch Engine `[OWNER-LOCKED CORE GAMEPLAY]`

Purpose: replace the temporary directly-colored slot interaction with the real five EMPTY batch slots. Player chooses a supply batch; the engine chooses the slot automatically.

- [ ] SB-M24-001 Preserve the production invariant of exactly five gameplay batch slots.
- [ ] SB-M24-002 Initialize all five batch slots EMPTY at level/session start.
- [ ] SB-M24-003 Define `SlotBatchState` independent of Godot presentation controls.
- [ ] SB-M24-004 Store `batch_id`, color ID, initial count, remaining-to-clear count, committed/in-flight count and placement sequence per occupied slot.
- [ ] SB-M24-005 Define explicit slot lifecycle states at minimum `EMPTY`, `ACTIVE` and `WAITING` without duplicating BoardState truth.
- [ ] SB-M24-006 On accepted supply selection, place the batch automatically into the rightmost currently EMPTY slot.
- [ ] SB-M24-007 Do not expose any production mechanic that asks the player to choose a destination slot.
- [ ] SB-M24-008 Never shift, reorder or compact already-occupied slots merely because another slot becomes empty.
- [ ] SB-M24-009 If holes exist, choose the rightmost available hole deterministically.
- [ ] SB-M24-010 If all five slots are occupied, reject the new batch atomically.
- [ ] SB-M24-011 On full-slot rejection, prove the originating supply column does not advance and the batch remains selectable.
- [ ] SB-M24-012 Allow multiple occupied slots to contain the same color simultaneously.
- [ ] SB-M24-013 Preserve stable batch identity after placement; never merge same-color batches silently.
- [ ] SB-M24-014 Enforce `0 <= committed <= remaining_to_clear <= initial_count` at all times.
- [ ] SB-M24-015 Define dispatch capacity as `remaining_to_clear - committed`.
- [ ] SB-M24-016 Do not reduce `remaining_to_clear` on player selection, claim, route calculation or spawn.
- [ ] SB-M24-017 Reduce `remaining_to_clear` only after authenticated successful clearing of one batch-owned target.
- [ ] SB-M24-018 Reduce `committed` when the corresponding live assignment resolves or is safely rolled back.
- [ ] SB-M24-019 A batch is complete only when `remaining_to_clear == 0` and `committed == 0`.
- [ ] SB-M24-020 Return the slot to EMPTY immediately and deterministically after true batch completion.
- [ ] SB-M24-021 If remaining quota exists but no matching target is currently claimable, enter WAITING without discarding the batch.
- [ ] SB-M24-022 Resume a WAITING batch automatically when later BoardState changes expose claimable matching work.
- [ ] SB-M24-023 Ensure a newly freed slot can accept the next player-selected supply batch using the same rightmost-empty rule.
- [ ] SB-M24-024 Expose read-only slot occupancy/count/state queries for presentation without leaking mutable internal state.
- [ ] SB-M24-025 Preserve exact slot/batch state across pause/resume.
- [ ] SB-M24-026 Reset clears all batch occupancy, counters, placement sequence and transient state deterministically.
- [ ] SB-M24-027 Make rapid repeated supply selections transactional; no duplicate batch insertion or double column advance.
- [ ] SB-M24-028 Add the canonical three-same-color example (`BLUE 8`, `BLUE 14`, `BLUE 12`) as a regression fixture.
- [ ] SB-M24-029 Test five-full-slot rejection followed by a completion/free-slot/new-selection cycle.
- [ ] SB-M24-030 Add headless invariant tests for every state transition and invalid slot/batch mutation.

### M25 — Batch Target Claim Engine `[OWNER-LOCKED CORE GAMEPLAY]`

Purpose: arbitrate currently targetable pixels among multiple live batches, especially duplicate colors, while preserving ReservationState and TargetSelector as the existing low-level safety authorities.

- [ ] SB-M25-001 Define a session-scoped Batch Target Claim service/ledger with narrow APIs.
- [ ] SB-M25-002 Keep existing `ReservationState` as the authoritative live target-reservation mechanism; do not create contradictory duplicate reservation truth.
- [ ] SB-M25-003 Represent each live claim with batch ID, slot ID, target index/coordinate, color and reservation/assignment identity.
- [ ] SB-M25-004 Permit claims only for currently ACTIVE, matching-color, valid, unreserved and production-targetable pixels.
- [ ] SB-M25-005 Never pre-claim a future pixel that is currently blocked/unreachable merely because it may become reachable later.
- [ ] SB-M25-006 Support multiple simultaneous occupied batches of the same color.
- [ ] SB-M25-007 Arbitrate same-color batches by oldest placement sequence first (FIFO).
- [ ] SB-M25-008 Make placement-sequence arbitration deterministic across reset/replay fixtures.
- [ ] SB-M25-009 Keep giving newly claimable work to the oldest same-color batch while it has uncommitted dispatch capacity.
- [ ] SB-M25-010 When the oldest batch has no remaining dispatch capacity, allow additional matching targets to flow to the next same-color batch.
- [ ] SB-M25-011 Keep different colors independent except for shared global ReservationState uniqueness.
- [ ] SB-M25-012 Preserve TargetSelector's bottom-most then left-most order among currently targetable matching unreserved candidates.
- [ ] SB-M25-013 Make target selection + batch ownership claim + ReservationState reservation one atomic logical transaction.
- [ ] SB-M25-014 Prove one target index can never belong to two live batches/robots at once.
- [ ] SB-M25-015 Prove one batch can never create duplicate live claims to the same target.
- [ ] SB-M25-016 Refuse claim when the batch has zero dispatch capacity.
- [ ] SB-M25-017 Increment `committed` exactly once when a claim becomes an accepted live assignment.
- [ ] SB-M25-018 Do not change `remaining_to_clear` merely because a claim exists.
- [ ] SB-M25-019 If route construction/validation fails before spawn, atomically release claim and reservation, decrement committed appropriately, consume zero batch quota and spawn no robot.
- [ ] SB-M25-020 On authenticated arrival/clear, resolve exactly the claim associated with that robot/assignment.
- [ ] SB-M25-021 Never allow a robot to clear any target other than its immutable claimed target.
- [ ] SB-M25-022 On successful authenticated clear, decrement batch remaining and committed exactly once.
- [ ] SB-M25-023 Fail closed on stale/already-cleared/invalid claim state; no duplicate clear, no quota loss and no ghost spawn.
- [ ] SB-M25-024 Release every live claim/reservation safely on reset/session teardown.
- [ ] SB-M25-025 Prevent slot completion while any claim/assignment for that batch remains committed.
- [ ] SB-M25-026 Mark a batch WAITING when it has remaining quota but no claimable matching target.
- [ ] SB-M25-027 Re-evaluate waiting colors after authoritative BoardState clear events rather than polling mutable UI state.
- [ ] SB-M25-028 Add simultaneous same-color claim race tests under rapid scheduler activity.
- [ ] SB-M25-029 Prove `BLUE 8`, `BLUE 14`, `BLUE 12` cannot target the same pixel and obey oldest-batch-first ownership when new blue pixels open.
- [ ] SB-M25-030 Prove newly opened targets are assigned at opening time, not pre-owned while inaccessible.
- [ ] SB-M25-031 Stress five occupied slots with duplicate colors on rectangular and 59×59 boards.
- [ ] SB-M25-032 Add claim/reservation leak, reset, stale-target and deterministic-order regression tests.

### M26 — Auto Dispatch Scheduler `[OWNER-LOCKED CORE GAMEPLAY]`

Purpose: turn an occupied color/count batch into autonomous Scrubbot work. The player selects batches, not individual robots and not individual target pixels.

- [ ] SB-M26-001 Define a gameplay-domain Auto Dispatch Scheduler independent of presentation/UI animation.
- [ ] SB-M26-002 Automatically attempt work for every occupied batch without requiring repeated player taps on the five slots.
- [ ] SB-M26-003 Begin scheduling a newly accepted batch immediately after transactional placement.
- [ ] SB-M26-004 Enforce the hard invariant: no currently valid target means no robot spawn.
- [ ] SB-M26-005 Enforce the hard invariant: no successful atomic reservation/claim means no robot spawn.
- [ ] SB-M26-006 Enforce the hard invariant: no valid RouteValidator-clean route to the exact claimed target means no robot spawn.
- [ ] SB-M26-007 Enforce transaction order `claim/reserve → build route → validate route → spawn exact assignment`.
- [ ] SB-M26-008 Never retarget after route/assignment acceptance; a failed assignment is rolled back rather than redirected silently.
- [ ] SB-M26-009 Spawn from the exact owning SlotCell anchor and preserve the accepted slot→BOTTOM connector + Railroad V1 route semantics.
- [ ] SB-M26-010 Spawn exactly one Scrubbot per successful assignment transaction.
- [ ] SB-M26-011 Pace sequential dispatch from a given batch/slot; do not materialize its entire count as an uncontrolled one-frame robot burst.
- [ ] SB-M26-012 Permit safe concurrent work from different occupied slots when each assignment has a unique reservation/route.
- [ ] SB-M26-013 Define deterministic scheduler fairness across different-color ACTIVE batches so one busy color cannot starve all others.
- [ ] SB-M26-014 For same-color batches, defer ownership ordering to the Batch Target Claim Engine's oldest-placement-first rule.
- [ ] SB-M26-015 Prove a `BLUE 15` batch can autonomously complete exactly 15 authenticated blue-pixel clears when the board makes them legally available.
- [ ] SB-M26-016 Track committed/in-flight capacity so a batch never dispatches more robots than its remaining quota permits.
- [ ] SB-M26-017 Decrement quota only from successful authenticated clearing callbacks, never from scheduler intent or spawn count.
- [ ] SB-M26-018 When no claimable work exists, transition to WAITING without busy-looping, phantom agents or repeated reservation churn.
- [ ] SB-M26-019 Wake/reconsider relevant WAITING colors when BoardState clearing changes reachability.
- [ ] SB-M26-020 When one new blue pixel opens and several blue batches wait, request arbitration and dispatch only the batch selected by the same-color FIFO rule.
- [ ] SB-M26-021 If the oldest same-color batch has only N dispatch-capacity units left and more than N targets open, allow only N claims to it and spill additional claims to the next batch deterministically.
- [ ] SB-M26-022 Auto-finish a batch after its final authenticated clear/assignment resolves and return the slot to EMPTY.
- [ ] SB-M26-023 Ensure freeing a slot does not reorder other occupied slots or mutate supply queues.
- [ ] SB-M26-024 Pause prevents new dispatches while preserving valid in-memory batch/claim state according to session rules.
- [ ] SB-M26-025 Resume safely restarts scheduling without duplicate claims/spawns.
- [ ] SB-M26-026 Reset/session teardown cancels in-flight scheduling, releases reservations/claims and leaves no orphan Scrubbot Nodes.
- [ ] SB-M26-027 Rapid input / simultaneous column selections cannot double-spawn, over-commit quota or duplicate target reservations.
- [ ] SB-M26-028 Validate scheduler behavior with multiple duplicate-color batches plus different-color batches concurrently.
- [ ] SB-M26-029 Run 59×59/high-agent-density performance sanity and allocation checks.
- [ ] SB-M26-030 Add a full Hazard Bot auto-dispatch integration smoke proving no ghost robots, no duplicate targets and exact quota conservation.

### M27 — Solvability / Deadlock Engine `[OWNER-LOCKED CORE GAMEPLAY]`

Purpose: prove generated supply is actually playable under the real mechanics and distinguish temporary waiting from a true no-solution state. This milestone is the final gameplay-engine closure gate before production screen/layout work.

- [ ] SB-M27-001 Define a deterministic solver operating on gameplay-domain state, not rendered UI Nodes.
- [ ] SB-M27-002 Consume the real level BoardState/access/routing semantics rather than a contradictory simplified notion of reachability.
- [ ] SB-M27-003 Model configured 3/4/5 independent FIFO supply columns.
- [ ] SB-M27-004 Model the visible-front rule: only each column's front batch is a legal player choice.
- [ ] SB-M27-005 Model preview/hidden queue ordering without allowing the solver to illegally select Row 2/Row 3/hidden batches early.
- [ ] SB-M27-006 Model automatic rightmost-empty placement into exactly five slots.
- [ ] SB-M27-007 Model full-slot rejection without consuming the selected supply front.
- [ ] SB-M27-008 Model batch remaining/committed/WAITING lifecycle exactly as the runtime engine does.
- [ ] SB-M27-009 Model same-color oldest-placement-first claim arbitration.
- [ ] SB-M27-010 Model targetability using authoritative ProductionTargetAccess/ProductionRoutingSystem semantics, including Railroad V1 legal ingress and post-rail orthogonal turns.
- [ ] SB-M27-011 Model dynamic ACTIVE→CLEARED board evolution after authenticated work.
- [ ] SB-M27-012 Model WAITING batches becoming runnable when new corridors/targets open.
- [ ] SB-M27-013 Search legal player front-batch choices rather than assuming one fixed greedy order.
- [ ] SB-M27-014 Find at least one complete sequence that clears every required logical pixel and consumes all required batch quota.
- [ ] SB-M27-015 Emit a deterministic solution trace for QA/debug evidence; never expose it to normal player UI.
- [ ] SB-M27-016 Accept a generated Batch Supply layout for production only after the solver proves at least one legal completion sequence.
- [ ] SB-M27-017 Feed unsolvable candidate layouts back to Batch Supply generation for deterministic retry/regeneration rather than shipping impossible levels.
- [ ] SB-M27-018 Preserve generation seed + solver outcome so an accepted/rejected supply can be reproduced exactly.
- [ ] SB-M27-019 Canonicalize/memoize equivalent search states to prevent needless combinatorial re-exploration.
- [ ] SB-M27-020 Add explicit search/time/state-count bounds and fail closed when proof cannot be completed within policy limits.
- [ ] SB-M27-021 Prove the real 20×20 Hazard Bot level has at least one solvable generated batch/column layout under the new five-slot rules.
- [ ] SB-M27-022 Persist the Hazard Bot solution trace as regression evidence while keeping player-hidden future batches hidden at runtime.
- [ ] SB-M27-023 Add rectangular-board solvability fixtures.
- [ ] SB-M27-024 Add 59×59 solver/performance sanity fixtures with bounded evidence appropriate to the search design.
- [ ] SB-M27-025 Define `STALLED/WAITING` separately from `DEADLOCK`.
- [ ] SB-M27-026 Never call a state deadlocked while any valid in-flight robot can still produce an authenticated clear.
- [ ] SB-M27-027 Never call a state deadlocked while an EMPTY slot plus at least one selectable front batch can lead to legal future progress.
- [ ] SB-M27-028 Never call a state deadlocked merely because current batches are waiting if already-scheduled/legal clearing can open their targets.
- [ ] SB-M27-029 Declare deadlock only when search proves there is no legal future action sequence that can produce further authenticated progress/completion.
- [ ] SB-M27-030 Add the canonical true-deadlock fixture: five occupied WAITING batches, no in-flight progress and no legal unlock sequence.
- [ ] SB-M27-031 Add false-positive guards where a newly opened same-color target correctly revives the oldest waiting batch.
- [ ] SB-M27-032 Expose deterministic deadlock reason codes/debug evidence without coupling lose-screen UI to solver internals.
- [ ] SB-M27-033 Reset/replay must reproduce identical solver classification from identical state/seed.
- [ ] SB-M27-034 Run performance/memory profiling and regression tests before declaring the core gameplay engine complete.

'''
anchor = '### M28 — Gameplay Screen Layout `[VISUAL REFERENCE]`'
if anchor not in s:
    raise SystemExit('Shifted M28 Gameplay Screen Layout anchor not found.')
s = s.replace(anchor, new_milestones + anchor, 1)

s = s.replace(
    '| RISK-009 | Target race assigns same pixel to multiple Scrubbots | HIGH | Reservation strict tests |',
    '| RISK-009 | Target race assigns same pixel to multiple Scrubbots/batches | HIGH | ReservationState + Batch Target Claim Engine atomic uniqueness tests |'
)
s = s.replace(
    '| RISK-013 | Target ordering appears wrong because exterior HOW cannot legally reach intended perimeter target | HIGH | Railroad V1 aligned exits + exact Hazard Bot (0,19) regression |',
    '| RISK-013 | Target ordering appears wrong because exterior/interior HOW cannot legally reach intended target | HIGH | Railroad V1 legal ingress + orthogonal interior-turn routing + exact Hazard Bot regressions |'
)
risk_anchor = '| RISK-015 | Railroad visual and routing geometry drift apart | HIGH | One canonical ScrubRail geometry source consumed by routing, connector and presentation |'
extra_risks = risk_anchor + '''
| RISK-016 | Generated batch supply is mathematically impossible to finish | CRITICAL | Solvability Engine proof before production acceptance |
| RISK-017 | Scheduler spawns a robot without unique target/reservation/valid route | CRITICAL | No-target/no-reservation/no-route/no-robot transactional invariant |
| RISK-018 | Temporary WAITING is misclassified as deadlock | HIGH | Solver-backed STALLED vs DEADLOCK classification + in-flight/future-progress guards |
| RISK-019 | Multiple same-color batches fight/starve or double-claim targets | HIGH | Oldest-placement-first same-color arbitration + atomic Batch Target Claim ledger |'''
if risk_anchor in s:
    s = s.replace(risk_anchor, extra_risks, 1)

s = s.replace('ROUTING + SCRUBBOT RAILROAD V1             ACTIVE (M22 V02)', 'ROUTING + SCRUBBOT RAILROAD V1             DONE (M22 V07 + OWNER ACCEPTANCE)')
old_cp = '''REAL SCRUBBOTS ART VERTICAL SLICE             DONE (M21)
↓
PRODUCTION UI / TOUCH                         ACTIVE (M22+)
↓
WIN / PROGRESSION / SAVE'''
new_cp = '''REAL SCRUBBOTS ART VERTICAL SLICE             DONE (M21)
↓
BATCH SUPPLY ENGINE                           NEXT (M23)
↓
FIVE-SLOT BATCH ENGINE                        M24
↓
BATCH TARGET CLAIM ENGINE                     M25
↓
AUTO DISPATCH SCHEDULER                       M26
↓
SOLVABILITY / DEADLOCK ENGINE                 M27
↓
PRODUCTION UI / TOUCH                         M28+
↓
WIN / PROGRESSION / SAVE'''
s = s.replace(old_cp, new_cp, 1)

s = s.replace('+ EXIT ONLY AT TARGET ROW/COLUMN ALIGNMENT\n+ ORTHOGONAL FINAL TARGET APPROACH', '+ LEGAL RAIL INGRESS INTO OPEN/CLEARED PERIMETER SPACE\n+ ORTHOGONAL INTERIOR-CORRIDOR ROUTING WITH 90-DEGREE TURNS')
s = s.replace('+ FIVE FUNCTIONAL VISIBLE COLOR SLOTS', '+ FIVE EMPTY BATCH SLOTS\n+ 3/4/5 FIFO BATCH-SUPPLY COLUMNS\n+ V1 THREE VISIBLE ROWS; FRONT ROW ONLY SELECTABLE\n+ AUTOMATIC RIGHTMOST-EMPTY SLOT PLACEMENT\n+ COLOR/COUNT BATCH QUOTAS WITH WAITING/RESUME\n+ SAME-COLOR OLDEST-BATCH-FIRST TARGET CLAIM ARBITRATION')
s = s.replace('+ NO-REACHABLE-TARGET-NO-SPAWN', '+ NO TARGET / NO RESERVATION / NO VALID ROUTE = NO ROBOT\n+ SOLVABILITY-PROVED SUPPLY + RUNTIME DEADLOCK CLASSIFICATION')

s = re.sub(
    r'PROMPT 13  Production Slot UI \+ Railroad \+ Gameplay Layout \+ Touch Controls \[M22 ACTIVE\]\nPROMPT 14.*?PROMPT 21  Release Candidate Preparation',
    '''PROMPT 13  Production Slot UI + Railroad V1                      [DONE — M22 V07 + owner acceptance]
PROMPT 14  Batch Supply Engine                                      [NEXT — M23]
PROMPT 15  Five-Slot Batch Engine                                   [M24]
PROMPT 16  Batch Target Claim Engine                                [M25]
PROMPT 17  Auto Dispatch Scheduler                                  [M26]
PROMPT 18  Solvability / Deadlock Engine                            [M27]
PROMPT 19  Gameplay Screen Layout + Mobile Touch                    [M28–M29]
PROMPT 20  Win/Lose Completion Rules + Results Flow
PROMPT 21  Scrubbot Final Art + Cleaning Effects + Audio/Haptics
PROMPT 22  Level Catalog + Difficulty V1 Content Rules
PROMPT 23  Progression + Win Streak + Save System
PROMPT 24  Home + Settings + Tutorial + Navigation
PROMPT 25  Android Device Performance + Full 59×59 Stress Tests
PROMPT 26  Production Content Scale-Up + Regression + Chaos QA
PROMPT 27  Release Candidate Preparation''',
    s,
    count=1,
    flags=re.S,
)

s = re.sub(
    r'## NEXT IMMEDIATE MILESTONE\n\n.*?\n---\n\n## MIGRATED LEVEL FACTORY / CONTENT PLATFORM PROGRAM — REFERENCE ONLY',
    '''## NEXT IMMEDIATE MILESTONE

**M23-C001 V01 — Batch Supply Engine.** The next implementation cycle builds the real color/count supply queues before any production-screen-layout work. V1 must support owner-locked FIFO columns, three visible rows for the Hazard Bot validation path, front-row-only selection, hidden future batches, deterministic/conserved candidate generation and transactional handoff to the future Five-Slot Batch Engine. It must not weaken or rewrite the accepted M22 Railroad V1/V07 routing, TargetSelector, ReservationState, dispatcher or authenticated-clearing contracts.

M23 is followed strictly by M24 Five-Slot Batch Engine, M25 Batch Target Claim Engine, M26 Auto Dispatch Scheduler and M27 Solvability / Deadlock Engine. The previous Gameplay Screen Layout milestone has moved to M28; production UI work must not jump ahead of these five core-gameplay milestones.

---

## MIGRATED LEVEL FACTORY / CONTENT PLATFORM PROGRAM — REFERENCE ONLY''',
    s,
    count=1,
    flags=re.S,
)

required_headings = [
    '### M23 — Batch Supply Engine',
    '### M24 — Five-Slot Batch Engine',
    '### M25 — Batch Target Claim Engine',
    '### M26 — Auto Dispatch Scheduler',
    '### M27 — Solvability / Deadlock Engine',
    '### M28 — Gameplay Screen Layout',
    '### M29 — Mobile Touch',
    '### M60 — Release',
]
for h in required_headings:
    if h not in s:
        raise SystemExit(f'Missing expected heading after rewrite: {h}')

if '### M23 — Gameplay Screen Layout' in s:
    raise SystemExit('Old M23 heading still present.')

headings = re.findall(r'^### (M\d{2}) — ', s, flags=re.M)
dupes = sorted({x for x in headings if headings.count(x) > 1})
if dupes:
    raise SystemExit(f'Duplicate milestone headings: {dupes}')

expected_new = {'M23': 30, 'M24': 30, 'M25': 32, 'M26': 30, 'M27': 34}
for m, count in expected_new.items():
    found = len(re.findall(rf'SB-{m}-\d{{3}}', s))
    if found != count:
        raise SystemExit(f'{m} task count mismatch: expected {count}, found {found}')

for tid in done_ids:
    if f'- [x] SB-M22-{tid}' not in s:
        raise SystemExit(f'M22 completion did not stick: {tid}')

path.write_text(s, encoding='utf-8', newline='\n')
print('TASKS.md roadmap rewrite complete.')
print('New tasks: 156; tracker progress: 348/885 = 39.32%.')
