# M29-C001 V01 — MASTER IMPLEMENTATION PROMPT

Repository: `Sekiph82/Scrubbots`
Branch: `main`
Milestone: `M29 — Mobile Touch / Production Input Integration`
Execution mode: **ONE CONTINUOUS FULL-MILESTONE PASS**
Tasks: `SB-M29-001..009`

Read first:
1. root `TASKS.md` M29 section and owner-locked §8.10C/§8.10D;
2. `coordination/OWNER_BATCH_GAMEPLAY_CORE_DECISION_V01.md`;
3. `coordination/OWNER_GAMEPLAY_SPEED_RULE_V01.md`;
4. `coordination/sessions/M28-C001/CHATGPT_AUDIT_V01.md`;
5. accepted M23–M27 final audits;
6. `coordination/sessions/M29-C001/CHATGPT_MASTER_AUDIT_CRITERIA_V01.md`;
7. all linked M29 work packages.

## Objective

Turn the accepted M28 production layout into the first **manually playable production-input path**.

At M29 closure the owner must be able to open one documented Godot playtest scene, use desktop mouse or mobile-style touch on the FRONT supply batches, observe real M23 -> M24 -> M25 -> M26 -> routing -> ScrubbotAgent -> M20 clearing, use the real 1x/2x control, and see automatic 2x activate when M23 supply is authoritatively exhausted.

M30 still owns win/lose/result flow. Do not fake a victory screen in M29.

## Authority chain

Production activation must be:

`front supply UI -> input gate/controller -> M24.select_front_batch(M23,column) -> successful transactional placement -> M26.notify_placed() -> automatic scheduler cadence -> M25 claim/reservation -> route -> agent -> M20 authenticated clear`.

Do NOT:
- let UI call M23 commit directly;
- let player choose a destination slot;
- call legacy slot activation;
- make preview rows selectable;
- invent target/route/clear logic in UI.

## Supply-front input

M28 `BatchSupplyPanel` becomes input-capable only for row 0/front.

Required:
- exactly one activation surface per visible column front;
- row 1/front is interactive;
- rows 2/3 remain presentation-only;
- exhausted column front is disabled;
- five batch slots remain read-only/non-clickable;
- production controller validates authoritative M23 column count is exactly 3/4/5 before binding; do not use UI clamping as gameplay truth.

The panel may emit a presentation signal such as:
`front_batch_activated(column_index)`
but must never retain/mutate M23/M24 engine references.

## Atomic activation

On one accepted front activation:
1. validate input/focus/pause state;
2. call real `FiveSlotBatchEngine.select_front_batch(supply_engine,column)`;
3. on rejection, preserve supply/slots exactly;
4. on success, refresh detached M23/M24 UI snapshots;
5. call `AutoDispatchScheduler.notify_placed()`;
6. allow production scheduler cadence to continue automatically;
7. only after successful placement, evaluate authoritative `BatchSupplyEngine.is_exhausted()`;
8. if exhausted, switch runtime gameplay speed to 2x.

All-five-slots-full rejection must consume nothing and must NOT trigger auto-2x.

## Mouse / touch / double-fire

Support:
- desktop mouse;
- touch;
- touch cancellation;
- focus loss;
- rapid tapping;
- multi-touch;
- application background/foreground.

A single physical touch must never produce both one touch activation and one synthesized-mouse activation.

Serialize activation transactions. A reentrant/overlapping input event must never cause:
- duplicate M23 consumption;
- double placement;
- skipped batch;
- cross-column mutation;
- overfilled M24 slots.

You may ignore/defer additional simultaneous touches while one activation transaction is committing. Safety is more important than multi-touch throughput.

## Pause reasons

Track at least:
- user pause;
- system/focus/background suspension.

Focus/background loss:
- cancels pending gestures;
- blocks new front activations;
- stops scheduler cadence;
- stops in-flight Scrubbot movement from advancing;
- preserves gameplay state.

Foreground/focus regain:
- resumes only if the user had not explicitly paused;
- never synthesizes a stale tap;
- preserves the selected 1x/2x speed.

## Production scheduler cadence

M26 already guarantees one accepted assignment per `step()`. M29 must provide the production clock/driver that calls it automatically.

Required:
- configurable deterministic base cadence;
- at 1x, one scheduler step per base cadence event;
- at 2x, cadence runs at exactly twice the temporal rate;
- never call `run_until_idle()` as a production-frame burst;
- successful placement may request/wake immediate scheduling, but the one-assignment-per-step M26 law remains intact.

## Owner-locked speed authority

V1 speeds are exactly:
- 1x;
- 2x.

Create one explicit gameplay-speed authority/controller. Do NOT use blind global `Engine.time_scale` for the whole application.

New level/full reset:
- speed = 1x.

Manual bottom-right button:
- M29 must preserve a direct toggle seam sufficient to verify the 1x/2x temporal authority in headless/debug evidence;
- this seam is **not** authorization for a permanently free shipping manual 2x;
- production manual 2x must later pass the paid entitlement gate in `OWNER_ECONOMY_REWARDS_V01.md` (current level 200 SB; 15m 300 SB; 30m 500 SB; 60m 750 SB);
- M39 owns wallet/entitlement purchase integration;
- M28 visual state must follow the actual temporal authority.

Automatic trigger:
- after a **successful** final M24 placement, if real `M23.is_exhausted()` is true, switch to 2x;
- hidden batches count;
- visible-row emptiness alone is irrelevant;
- five-slot occupancy alone is irrelevant;
- a rejected final selection cannot trigger it;
- if already 2x, no duplicate side effect;
- auto-2x is free and entitlement-independent;
- player may return to 1x; any later production manual request for paid 2x must obey the entitlement gate once M39 is integrated.

2x must accelerate:
- scheduler cadence;
- future ScrubbotAgent travel;
- currently in-flight ScrubbotAgent travel.

2x must NOT change:
- M23/M24/M25 ordering/accounting;
- TargetSelector;
- ReservationState;
- route choice/geometry;
- clear identity;
- M27 semantics.

Add only narrow timing seams to accepted M26/dispatcher/agent code when required, and regress them fully.

## Manual playtest scene

Create a dedicated manual scene, preferably:

`scenes/debug/m29_hazard_bot_playtest.tscn`

It must use the **production** GameplayScreen + production input/runtime controller, not a separate fake UI.

Fixture:
- real `data/levels/m21_level_001_hazard_bot.json`;
- real M23/M24/M25/M26/M20/routing/dispatcher stack;
- known deterministic SOLVED M23 supply candidate compatible with M27 evidence (seed 1 / 3 columns / preview depth 3, or an equivalently solver-proven deterministic candidate);
- actual laid-out SlotCell/slot-origin mapping.

Desktop manual test must work with mouse.

The log must give exact Godot instructions:
- project path;
- scene path;
- whether to use F6 or equivalent;
- what to click;
- what the owner should observe;
- known M30 limitation (no final win/lose UI yet).

Do not change the project main scene merely to make the debug playtest convenient.

## Continuous work packages

Execute without approval stops:
1. `M29_WORK_PACKAGE_01_FRONT_INPUT_AND_TRANSACTION_GATE.md`
2. `M29_WORK_PACKAGE_02_RUNTIME_CADENCE_AND_SPEED_AUTHORITY.md`
3. `M29_WORK_PACKAGE_03_PAUSE_FOCUS_MULTITOUCH_HARDENING.md`
4. `M29_WORK_PACKAGE_04_REAL_HAZARD_BOT_PLAYTEST_AND_CLOSURE.md`

## Scope prohibitions

- root `TASKS.md` is read-only for Claude;
- do not implement M30 win/lose;
- do not implement M31 effects or M32 final art;
- do not make slots destination buttons;
- do not make preview rows selectable;
- do not use global app time scale as the gameplay-speed implementation;
- zero AI image generation.

## Handoff

Push implementation commit(s) first.
Then create `coordination/sessions/M29-C001/CLAUDE_LOG_V01.md` as a separate final commit.

Map all `SB-M29-001..009` plus the owner speed rule to direct code/tests/manual evidence.

Return only:
`AWAITING_AUDIT`
final implementation SHA
direct GitHub log URL.
