# M29-C001 V03 — Complete Owner Graphical Playtest Remediation

Repository: `Sekiph82/Scrubbots`
Branch: `main`
Milestone: `M29 — Mobile Touch / Production Input Integration`
Cycle: `M29-C001 V03`
Execution mode: **ONE CONTINUOUS REMEDIATION PASS**

Read first:

1. `coordination/sessions/M29-C001/CHATGPT_MANUAL_AUDIT_V03.md`
2. `coordination/sessions/M29-C001/CHATGPT_AUDIT_CRITERIA_V03.md`
3. `coordination/OWNER_BATCH_SLOT_DISPLAY_DECISION_V01.md`
4. `coordination/OWNER_FIVE_SLOT_LIVE_PRESENTATION_SYNC_DECISION_V01.md`
5. `coordination/OWNER_GAMEPLAY_SPEED_RULE_V01.md`
6. accepted M29 V01/V02 implementation/audit evidence
7. root `TASKS.md` as read-only project truth

This remediation comes directly from the owner's real graphical Godot F6 playtest.

The owner ran:

`res://scenes/debug/m29_hazard_bot_playtest.tscn`

and observed that batches enter the five-slot system and committed M26 work appears, but visible Scrubbot movement and pixel clearing do not progress. A second screenshot approximately three minutes later still showed the same in-flight committed state.

Fix **ALL currently confirmed M29 graphical/playtest defects in one pass**.

---

## 1. BoardPresentation identity bug

The current responsive relayout path repeatedly calls `BoardPresentation.configure()`, and the current implementation can create replacement `BoardRenderer` and `AgentLayer` nodes after the production runtime has already bound M20/dispatcher/runtime to earlier instances.

Fix the presentation lifecycle so:

- `BoardRenderer` is created only once per production gameplay presentation;
- `AgentLayer` is created only once;
- responsive relayout reuses those exact instances;
- relayout changes geometry/scale, not presentation-node authority identity;
- do NOT rebind M20/dispatcher on every resize;
- live agents remain parented to the same AgentLayer across relayout;
- the renderer updated by M20 is the exact renderer currently visible on screen;
- ScrubRailView ordering remains correct;
- a foreign/new BoardState must not silently replace the live presentation truth.

Required identity proof:

`presentation.get_renderer()` before relayout === same exact object after relayout.

`presentation.get_agent_layer()` before relayout === same exact object after relayout.

No duplicate renderer/layer children may exist.

---

## 2. Real graphical SceneTree runtime clock

Do not stop at headless tests that manually call `runtime.tick()`.

Add a production-style graphical/headless-compatible SceneTree smoke that:

- uses the real `ProductionGameplayHost`;
- uses the owner's actual embedded-game viewport size `683x1366`;
- leaves `ProductionRuntimeController._process(delta)` enabled;
- does NOT disable runtime processing;
- does NOT call `runtime.tick()` manually;
- activates a real front supply batch;
- observes committed work appear;
- proves at least one real `ScrubbotAgent.get_progress()` increases across subsequent SceneTree frames;
- proves the agent arrives in a bounded number of real frames;
- proves M20/M25 finalization occurs;
- proves the corresponding CURRENT visible renderer pixel becomes transparent;
- proves committed work resolves instead of remaining frozen indefinitely.

Explicitly test focus/background behavior:

- focus/system suspension may pause gameplay intentionally;
- pending gestures are cancelled;
- focus regain resumes movement if user pause is not active;
- focus regain must not leave the playtest permanently system-suspended;
- no stale click/touch is replayed.

This test must catch exactly the owner-observed failure mode where a slot remains e.g. `50 (2) ACTIVE` for minutes with no visible progress.

---

## 3. Five-slot displayed robot count

The owner has locked the player-facing slot number semantics.

Canonical main displayed count:

`display_count = M24 capacity = remaining_to_clear - committed`

The main number means **robots still physically waiting in that slot**.

Required behavior:

- fresh Blue 50 => display `50`;
- one successfully committed/dispatched Scrubbot => display `49` immediately;
- two committed/in-flight Scrubbots => display `48` immediately;
- remove the player-facing `50 (2)` style;
- after one in-flight agent authenticates its clear, the displayed waiting count remains correct because both `remaining_to_clear` and `committed` decrement together;
- if all robots have left the slot but some are still in flight, display `0` until authoritative completion frees the slot.

Do NOT change accepted M24 gameplay accounting:

- `committed` increments when work is committed;
- `remaining_to_clear` decreases only after authenticated clear;
- `capacity = remaining_to_clear - committed`;
- slot completion remains `remaining_to_clear == 0 && committed == 0`.

This is a presentation correction only.

---

## 4. Live five-slot state synchronization

The current production UI must not refresh slot snapshots only after player placement.

The five-slot strip must receive a fresh DETACHED authoritative M24 snapshot after every player-visible M24 mutation, including:

- successful batch placement;
- successful dispatch/commit;
- `ACTIVE -> WAITING`;
- `WAITING -> ACTIVE` wake;
- rollback after route/spawn failure;
- authenticated clear/finalize;
- slot completion -> EMPTY;
- reset.

UI remains presentation-only.

The UI must NOT:

- run TargetSelector;
- run routing;
- infer reachability from visuals;
- mutate M24.

Use an authoritative runtime/state-change notification or an equally exact synchronization seam and push fresh detached `FiveSlotBatchEngine.snapshot()` data into the M28 screen.

---

## 5. Hazard Bot lifecycle proof

The deterministic M29 Hazard Bot first-column supply sequence is:

`Red 15`
`Yellow 1`
`Blue 50`
`Blue 50`
`Brown 3`

The accepted M27 solution trace proves:

- Red 15 => 0 immediate clear;
- Yellow 1 => 0 immediate clear;
- first Blue 50 => 50 clears;
- second Blue 50 => 50 clears;
- Brown 3 => still 0 immediate clear at that state.

Therefore:

- Red may correctly be WAITING;
- Yellow may correctly be WAITING;
- Brown must NOT remain stale ACTIVE after authoritative targetability evaluation finds no reachable brown target;
- Brown must visibly become WAITING automatically;
- this transition must not require another player batch placement;
- later, after black/open-corridor progress makes Brown reachable, authoritative wake/reconsideration must change it back to ACTIVE and the UI must update automatically.

Internal ACTIVE semantics remain eligibility, not proof that a robot is currently moving.

---

## 6. Preserve all accepted behavior

Do not broadly rewrite accepted gameplay.

Preserve:

- M23 FIFO/front-only supply semantics;
- M24 rightmost-empty placement and accounting;
- M25 target selection/reservation authority;
- M26 one-assignment-per-step / no-ghost law;
- M27 solvability/deadlock semantics;
- M29 V02 exact visible slot-origin mapping;
- mouse/touch front-only input;
- preview-row non-interactivity;
- five-slot non-clickable destination behavior;
- touch/mouse deduplication;
- rapid-tap/multi-touch serialization;
- pause/focus rules except where required to fix confirmed graphical freeze;
- 1x/2x gameplay-speed authority;
- authoritative M23-exhausted automatic 2x.

Do not use global `Engine.time_scale`.

Do not implement M30.

---

## 7. Required regression evidence

Add direct evidence for all of the following.

### Presentation identity

At `1080x2160`, `683x1366`, and through a resize transition:

- renderer identity remains exact;
- AgentLayer identity remains exact;
- exactly one BoardRenderer exists;
- exactly one AgentLayer exists;
- live moving agent survives relayout;
- same parent AgentLayer is preserved;
- route/progress truth survives relayout;
- V02 exact visible slot-origin mapping remains correct after resize.

### Real SceneTree movement

At `683x1366`:

- real front activation succeeds;
- committed work appears;
- a real agent's progress increases using SceneTree `_process(delta)`;
- no manual `runtime.tick()`;
- agent arrives;
- committed work resolves;
- visible renderer cell becomes transparent;
- focus loss/gain cannot leave gameplay frozen.

### Slot-count UI

Prove:

`50 -> 49 -> 48`

on accepted dispatch commitments.

Prove raw `50 (2)` presentation is gone.

### ACTIVE / WAITING UI

Prove:

- ACTIVE -> WAITING becomes visible without new player input;
- WAITING -> ACTIVE wake becomes visible without new player input;
- Hazard Bot early Brown3 displays WAITING when still unreachable after the two first Blue50 batches;
- rollback refreshes state/count;
- authenticated clear/finalize refreshes state/count;
- slot completion -> EMPTY refreshes automatically;
- reset refreshes automatically.

### Full Hazard Bot production smoke

Re-run full real production stack and prove:

- 400 authenticated clears;
- final ACTIVE = 0;
- no ghost robot;
- no duplicate live target;
- M23 exhausted;
- auto-2x preserved;
- exact visible slot origins preserved;
- 1x/2x gameplay truth equivalence preserved.

Run full regression floor and `git diff --check`.

---

## 8. Owner manual retest handoff

`CLAUDE_LOG_V03.md` must include exact owner instructions:

Scene:

`res://scenes/debug/m29_hazard_bot_playtest.tscn`

Run with F6.

Explain exactly:

- what to click;
- what Blue 50 should display after one and two robots dispatch;
- where the debug Scrubbot circles should visibly move;
- when pixels should become transparent;
- when Red/Yellow/Brown should display WAITING;
- how to confirm WAITING -> ACTIVE wake;
- how to verify pause;
- how to verify 1x/2x.

Include the known complete-clear owner-facing click sequence:

`1,1,1,1,1,1,1,2,2,2,2,2,2,3,3,3,3,3,3`

---

## 9. Governance

- Do not modify root `TASKS.md`.
- Do not implement M30.
- Do not implement unrelated Economy/Collection work.
- Zero AI image-generation credits.
- Push implementation commit(s) first.
- Then create `coordination/sessions/M29-C001/CLAUDE_LOG_V03.md` as a separate final commit.

Return only:

`AWAITING_AUDIT`

final implementation SHA

direct GitHub `CLAUDE_LOG_V03.md` URL
