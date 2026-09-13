# M21-C001 V07 — Exterior Routing Corridor + Slot-Only Owner Interaction

You are Claude acting as implementation/test runner for `Sekiph82/Scrubbots` on `main`.

V06 received an independent engineering PASS, but the owner then manually ran the real Godot scene and rejected final M21 closure for two directly observed runtime behaviors. This V07 is the frozen correction pass for those owner findings.

Read and obey every criterion in:

`coordination/sessions/M21-C001/CHATGPT_AUDIT_CRITERIA_V07.md`

Read first:

- `CLAUDE.md`
- root `TASKS.md`
- `coordination/AUDIT_POLICY.md`
- `coordination/AUDIT_INDEX.md`
- `coordination/sessions/M21-C001/CHATGPT_AUDIT_V06.md`
- `coordination/sessions/M21-C001/CHATGPT_OWNER_GATE_V06.md`
- `coordination/sessions/M21-C001/OWNER_PLAYTEST_FINDINGS_V07.md`
- `coordination/sessions/M21-C001/M21_V05_OWNER_PLAYTEST.md`

The owner findings are authoritative for V07.

## 1. Safe synchronization first

Safely synchronize local `main` with `origin/main` while preserving every owner/local tracked and untracked change.

Work only in `Sekiph82/Scrubbots`.

Do not reset, restore, clean, delete or overwrite owner/local work merely to obtain a clean tree.

Never force push.

Do not recreate `.hiveai` as a live tracker.

## 2. Root TASKS.md is ChatGPT-owned — do not edit it

ChatGPT has already updated the canonical root `TASKS.md` after the V06 audit/owner-gate failure and before issuing this V07 prompt.

**Do not modify root `TASKS.md` in V07.**

This applies at start, during implementation, and at handoff. Do not create a tracker-only commit. Do not change lifecycle/status/actor/progress/check boxes. The tracker will be updated by ChatGPT after the independent V07 audit and any subsequent owner gate.

Your implementation handoff state is communicated only by:

- `coordination/sessions/M21-C001/CLAUDE_LOG_V07.md`; and
- the required two-line final response.

If the local working tree contains a pre-existing owner/local modification to `TASKS.md`, preserve it untouched and do not stage it.

## 3. Frozen finding A: remove SPACE gameplay dispatch

Correct `scripts/debug/m21_real_art_vertical_slice.gd` so the owner-playable scene has exactly one player-facing dispatch path:

```text
visible SlotView click
→ SlotView.slot_activated
→ scene handler
→ CompleteClearingLoop.activate_slot
→ real dispatcher / target / route / agent / authenticated clear
```

Remove:

- the SPACE gameplay handler;
- `step_one_clear()` or equivalent hidden gameplay fallback;
- `SLOT_ORDER` if it exists only for that fallback;
- synthetic off-board origin arrays/constants used only by that fallback;
- any owner guide text telling the owner to press SPACE.

Do not replace it with another hidden gameplay keyboard shortcut.

Keep ordinary editor/debug controls that do not dispatch/clear gameplay if any exist.

`request_slot()` may remain as a narrow programmatic/test seam if it is still useful, but the real owner scene interaction must be visible-slot driven.

## 4. Frozen finding B: add the one-cell exterior production routing corridor

The current TargetSelector comparator is already correct. Do **not** fix this by bypassing targetability or changing TargetSelector ordering.

The production routing planner must gain the owner-locked exterior ring defined in `OWNER_PLAYTEST_FINDINGS_V07.md`.

For board width `W`, height `H`, planner corridor cells are exactly:

```text
top:    y = -1, x = -1 .. W
bottom: y =  H, x = -1 .. W
left:   x = -1, y =  0 .. H-1
right:  x =  W, y =  0 .. H-1
corners included
```

Each logical routing cell centre is `Vector2(cx + 0.5, cy + 0.5)`.

This is planner/routing space only. Never extend LevelData or BoardState dimensions.

### Preferred minimal architecture

Prefer a focused change inside `scripts/gameplay/routing/production_routing_system.gd`:

- extend the deterministic planning graph/search domain from board cells to `board + one-cell exterior ring`;
- classify ring nodes as exterior/open planner nodes;
- continue classifying real board nodes through the existing authoritative `ProductionAccessQuery` seam;
- keep every traversed edge subject to `is_segment_traversable()`;
- seed the search by connecting the exact slot/request origin to access-valid ring node(s);
- preserve existing inside-board CLEARED/open behavior and final ACTIVE-target arrival law;
- preserve the shared RouteValidator on every successful route;
- preserve organized/curved post-processing only when the post-processed route remains fully valid.

The current `ProductionAccessQuery` already treats outside-board/background space as open. Therefore **do not edit its production semantics unless a direct test proves a planner-only correction cannot satisfy the owner contract**. If you believe it must change, stop and document the necessity before widening scope; do not casually rewrite access truth.

Likewise prefer to leave unchanged:

- `scripts/gameplay/targeting/target_selector.gd`
- `scripts/gameplay/dispatch/scrubbot_dispatcher.gd`
- `scripts/gameplay/clearing/complete_clearing_loop.gd`
- `scripts/gameplay/routing/route_request.gd`
- `scripts/gameplay/routing/route_validator.gd`
- `scripts/gameplay/board/board_presentation.gd`
- `scripts/ui/slot_view.gd`
- `scripts/gameplay/agents/scrubbot_agent.gd`

Any unexpected need to edit one of these must be justified in the log and receives full regression scrutiny.

## 5. Start-origin connector law

The clicked SlotView's mapped board-local origin may be farther than one cell below/aside the board. Preserve that exact origin.

The route may use an access-valid connector from that exact origin into the one-cell exterior ring.

Required:

- first route point == exact clicked slot board-local origin;
- connector cannot cross ACTIVE artwork;
- once ring traversal begins, the planner does not search arbitrary exterior cells beyond the one-cell ring;
- route may travel around corners;
- route may enter a CLEARED perimeter cell when existing access permits;
- route may enter the assigned ACTIVE perimeter target only as final arrival;
- no teleport, no retarget, no board mutation by routing.

## 6. Exact real Hazard Bot correction

This is load-bearing and must be directly asserted from the real owner scene.

Fresh `m21_level_001_hazard_bot` is 20×20. Local palette id `2` is canonical C08; the whole bottom row is C08.

After the scene has laid out its real SlotViews:

1. obtain visible C08 SlotView (slot 2);
2. obtain its actual global spawn anchor;
3. map it through the real BoardPresentation into board-local origin;
4. stimulate the real Button/SlotView signal path, not SPACE;
5. require successful real dispatch;
6. require exact first target index `380`;
7. require exact first target coordinate `(0,19)`;
8. require exact target color local palette id `2` / C08;
9. inspect the real agent's detached `get_route_points()`;
10. require route point 0 == exact mapped slot origin;
11. prove route connects to/traverses the bottom exterior ring rather than crossing intervening ACTIVE bottom-row cells;
12. require final route point == centre of `(0,19)`;
13. let the real ScrubbotAgent move through the normal runtime process/advance test mechanism;
14. require authenticated M20 arrival clears exactly index `380` and no unrelated cell;
15. require reservation/candidate truth clean and AgentLayer orphan count zero after deferred cleanup.

The test must fail on the current pre-V07 routing implementation. Record that red-before/fixed-after evidence if practical and safe.

## 7. Deterministic left-to-right bottom-row evidence

Because the bottom row is all C08, prove the correction is not a one-off special case for index 380.

Using real production collaborators and reservations, prove that multiple accepted C08 assignments on the fresh board choose distinct bottom-row targets from left to right when concurrently/serially targetable:

```text
380, 381, 382, ...
```

Do not force target IDs into the dispatcher. They must emerge from:

```text
TargetSelector positional priority
+ ProductionTargetAccess
+ corrected ProductionRoutingSystem corridor
+ ReservationState
```

If a requested concurrent activation legitimately fails due to existing concurrency rules, assert zero side effects and use a serial equivalent to prove the ordering.

## 8. Four-side corridor matrix

Add direct production-routing tests that prove the ring is genuinely four-sided and generic, not a Hazard Bot/bottom-side patch.

At minimum cover:

- below-board origin → far-left bottom perimeter target via bottom ring;
- above-board origin → far-right top perimeter target via top ring;
- left-of-board origin → far-bottom left perimeter target via left ring;
- right-of-board origin → far-top right perimeter target via right ring;
- at least one route that turns an exterior corner;
- at least one rectangular board;
- 59×59 sanity where routing cost scales with dimensions;
- an enclosed interior ACTIVE target that remains untargetable;
- no diagonal/corner cutting through ACTIVE blockers.

Make at least one new test load-bearing: disabling/removing the exterior-ring expansion must make it fail.

## 9. Preserve strict architecture and safety

Re-run all relevant strict evidence, including:

- M15 TargetSelector strict-v2 re-entry/coherence/reservation/fail-closed tests;
- M16 RouteRequest/RouteValidator/no-retarget tests;
- all M17-C002 production routing and V03 hardening tests;
- all M18 agent lifecycle/movement tests;
- all M19 dispatcher strict tests/smokes;
- all M20 clearing/lifecycle/arrival authority tests/smokes;
- M21 V01–V06 tests and owner-playtest smokes;
- full root test suite.

Do not delete/disable/weaken prior strict tests to obtain green.

Where an old assertion encodes a route/target result legitimately superseded by the new owner corridor, update that assertion narrowly and explain why in the log. Preserve its original safety purpose.

## 10. Protected blobs

After V07, directly verify these remain unchanged unless this prompt explicitly authorizes the file:

Hard locks:

- owner Hazard Bot PNG blob: `b565743ba52699899007882b750b7c8e7cdd00f9`
- M20 clearing loop: `06391839523cbc27e88a4b3ef12b730012cd45fa`
- dispatcher: `eee10149e4f116af6706beec832042352bf3a6dd`
- TargetSelector: `bb1e48a2a82f6ca4e8962f2a24de60e815c1a945`
- BoardPresentation: `2093df48d367903d332a910dfb3369154831a9ed`
- SlotView: `480dffc0ee135150bd3dd2258f002264273ead10`
- ScrubbotAgent: `48b43b1c8ee1709741fc6ad9c9b1ef436f4d6370`
- ProductionAccessQuery: `7ba9d13556abb0e3a0a6d281449438330a25386d` unless a documented unavoidable blocker is found and scope is stopped/reconciled before editing.

Expected authorized production changes:

- `scripts/gameplay/routing/production_routing_system.gd` (current pre-V07 blob `0900e9554d0e64dcfbb28667e1ce1062eadba73f`)
- `scripts/debug/m21_real_art_vertical_slice.gd` (current pre-V07 blob `66050fe5ec95498a43c6d4abccf62c4d82744d39`)

Plus focused tests, owner guide and V07 log. Root `TASKS.md` is not an authorized Claude change.

## 11. Current owner guide

Create:

`coordination/sessions/M21-C001/M21_V07_OWNER_PLAYTEST.md`

Do not delete V05 historical guide.

The V07 guide must tell the owner:

- F6 the same owner scene;
- do **not** use SPACE because SPACE dispatch no longer exists;
- click C08 on a fresh board;
- first target must visibly be the far-left bottom cell `(0,19)`;
- marker should leave the clicked C08 slot, connect down/up as necessary to the bottom exterior ring, travel left outside the art, then enter `(0,19)`;
- subsequent C08 clears should progress along the bottom row left-to-right while those cells are targetable/unreserved;
- try other colors only once they become legitimately reachable;
- report any tunnelling through ACTIVE artwork, wrong origin, wrong first target, stuck slot highlight, orphan marker, or hidden keyboard dispatch.

## 12. Validation commands and evidence

Run and log at minimum:

1. full root suite;
2. dedicated V07 corridor tests;
3. focused production-routing tests;
4. V05 owner-playtest smoke;
5. V06 genuine 1080×2400 smoke;
6. M21 full real-art 400-clear smoke;
7. all M20 lifecycle/queue-free smokes;
8. owner scene headless boot with zero parse/script errors;
9. any 59×59 focused corridor/performance sanity command.

Record exact commands, exit codes, test counts and relevant concrete tuples.

Required concrete V07 tuple includes at least:

- viewport/layout used;
- slot id and palette id;
- visible slot global anchor;
- mapped board-local origin;
- target index/coordinate;
- complete detached route-point list for first C08 dispatch;
- which route points/segments constitute the exterior ring travel;
- target global centre;
- final cell state;
- reservation count/owner cleanup;
- AgentLayer child count after cleanup.

## 13. Log and handoff

Create:

`coordination/sessions/M21-C001/CLAUDE_LOG_V07.md`

The log must include:

- synchronized starting HEAD;
- explicit confirmation that root `TASKS.md` was read but not modified;
- exact root cause as reproduced before correction;
- exact changed files;
- implementation design of the one-cell ring;
- test red/green evidence where available;
- exact Hazard Bot `(0,19)/380` evidence;
- four-side/rectangular/59×59 evidence;
- full regression results;
- protected blob rechecks;
- any failed attempt and correction;
- statement that owner manual PASS still remains pending independent ChatGPT audit.

Do not edit root `TASKS.md` at handoff. ChatGPT will update lifecycle/progress/closure state after independent audit.

Push all authorized work safely to `origin/main`.

Final response must be exactly:

```text
AWAITING_AUDIT
https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M21-C001/CLAUDE_LOG_V07.md
```

If implementation reveals that the corridor cannot be achieved without changing a hard-locked contract outside this frozen scope, stop rather than improvising and return exactly:

```text
BLOCKED
https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M21-C001/CLAUDE_LOG_V07.md
```
