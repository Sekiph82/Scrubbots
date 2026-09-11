# M20-C001 — Whole-Sprint Final Validation Freeze V08

Status: **VALIDATION_ONLY_REQUIRED / PRODUCTION_IMMUTABLE / FINDING_SET_FROZEN**

Authority:
- root `TASKS.md` as sole live tracker;
- `coordination/AUDIT_POLICY.md`, including the owner-locked 2026-09-11 whole-sprint two-pass rule;
- `coordination/sessions/M20-C001/CHATGPT_AUDIT_V07.md`.

V07 production corrections are source-accepted. V08 is the final auditor-authored critical-sprint validation gate. It MUST NOT commit any `scripts/**` change.

## Locked production baseline

Accepted clearing-loop blob:
`06391839523cbc27e88a4b3ef12b730012cd45fa`

Accepted dispatcher blob:
`eee10149e4f116af6706beec832042352bf3a6dd`

All other production files remain unchanged from the V07 tree.

Temporary production sensitivity mutations are allowed only after the V08 tracker start push, one at a time, never committed, and must be restored byte-for-byte before final validation.

## Whole-sprint validation objectives

V08 must validate the entire M20 ledger, not only the V07 fixes.

### A. Single M20 transaction owner

Fresh arrangements must prove:
- first CompleteClearingLoop owns one dispatcher arrival authority;
- a benign diagnostic signal listener does not count as transaction ownership;
- second live loop on same dispatcher cannot bind;
- rejected loop creates no claim/transaction connection and cannot activate/reset canonical state;
- owning loop remains coherent and clears exactly once;
- owning-loop reset does NOT release/transfer the claim while the owner remains live;
- second loop is still rejected after owner reset;
- after owner loop is actually released/GC'd and its signal callback disappears, a fresh loop can claim once;
- no strong reference cycle keeps the old loop alive.

No production API change is authorized merely to make the test easier.

### B. `agent_parent` lifecycle

Fresh validation must cover:
- omitted/default -> dispatcher self;
- explicit null -> dispatcher self;
- scalar/wrong object -> bind false;
- healthy explicit Node -> agent attaches there;
- queued explicit Node -> bind false;
- truly-freed explicit Node before bind -> bind false, no SCRIPT ERROR, no fallback;
- explicit parent queued/freed from a bind-time coherence callback -> bind does not commit;
- healthy bind followed by explicit parent destruction before dispatch -> dispatch fails closed, current-attempt reservation removed, no orphan agent;
- existing add-child/factory/reset regressions stay green.

### C. Renderer lifecycle + criterion reconciliation

Fresh validation must cover:
- omitted and explicit null headless;
- representative scalar/container/wrong-object/wrong-Node variants;
- queued and truly-freed exact renderer before bind;
- same-loop failed-bind recovery;
- refused second bind preserves original renderer expectation;
- prove preservation with BOTH a foreign-board original renderer and a queued/dead original renderer;
- renderer foreign-board after bind -> activation fails before dispatch;
- renderer queued/dead after dispatch but before arrival -> no clear/finalize;
- raw candidate remains present on this failed preflight;
- reservation + dispatcher assignment remain held until explicit reset;
- healthy target repaint alpha 0 and unrelated pixel unchanged;
- headless success remains.

This explicitly repairs the V07 audit-spec mismatch where criterion 109 said queued/dead while the prompt allowed queued/dead OR foreign-board.

### D. Arrival-preflight desynchronization — direct M20 evidence

Build real pending-arrived assignments and inject through the M20 arrival boundary. Independently cover:
- wrong owner;
- wrong target;
- wrong color;
- wrong source agent;
- unknown owner;
- missing reservation;
- same-board target reservation replaced by DIFFERENT owner;
- ReservationState rebound to foreign board and given a foreign replacement reservation;
- ColorCandidateIndex rebound to foreign board;
- ColorCandidateIndex neutralized/unbound via `rebind(null)` before arrival;
- target externally already CLEARED;
- renderer foreign/queued/dead;
- stale replay after reset;
- duplicate current/queued completion.

For EACH failed-preflight arrangement directly prove the relevant exact invariants rather than relying on aggregate state:
- no new BoardState clear;
- cleared_count unchanged;
- real dispatcher assignment not silently finalized by M20;
- original or replacement/foreign reservation is preserved until the explicit cleanup law applies;
- raw candidate/unrelated candidate/cell truth remains as expected;
- subsequent loop.reset is pair-narrow and cannot destroy foreign/replacement reservation truth;
- no orphan agent after cleanup.

### E. Activation public boundary — per-case snapshots

Use one fresh arrangement per invalid request or reset state. Before each call take detached snapshots of:
- BoardState cell states;
- dispatcher active count + next owner id;
- exact reservation owner map/count;
- all five slot palette/availability/activity scalar fields.

Cover:
- slot -1;
- slot 5;
- non-int slot;
- unavailable slot;
- NaN/+INF/-INF x/y representative origins;
- speed NaN/+INF/-INF/0/negative;
- no target;
- enclosed matching target;
- nested activation;
- activation during arrival drain;
- reset during activation preflight;
- reset inside M19 dispatch;
- post-dispatch M20 coherence loss.

Each rejection must preserve the applicable snapshot exactly, except owner-id consumption where an already-proven downstream M19 transaction legitimately reached its owner allocation before reset/coherence loss. In those cases assert the documented monotonic/no-reuse behavior explicitly.

### F. Fresh auditor-authored SB-M20-001..014 ledger

Add a new V08 section that does NOT merely call the V07 aggregate functions.

Freshly prove:
- SB-M20-001 one complete real-production sequence with synchronized post-arrival tuple;
- SB-M20-002 no target and enclosed target -> no bot;
- SB-M20-003 finalized bot is queued then truly gone after SceneTree frame(s), no orphan/no return;
- SB-M20-004 actual 1x1;
- SB-M20-005 one-color repeated clear to exhaustion;
- SB-M20-006 multi-color correct slot/color behavior;
- SB-M20-007 five successful in-flight assignments, five unique owners, five distinct targets, five exact pairs, resolving one preserves four, all five eventually resolve;
- SB-M20-008 Easy representative;
- SB-M20-009 Medium representative;
- SB-M20-010 Hard representative;
- SB-M20-011 Very Hard representative;
- SB-M20-012 59x59 maximum;
- SB-M20-013 rectangular 53x59 or another valid rectangular production board;
- SB-M20-014 fresh direct desync/reset/duplicate/rollback matrix.

Also freshly prove:
- AL-028: B unreachable behind ACTIVE A; clear A; second REAL activate_slot selects/routes B; B clears;
- rapid >=25 sequential clear cycles;
- reset with multiple in-flight agents;
- no slot palette/availability/activity mutation by M20;
- no normal-clear BoardState full scan introduced.

### G. Rollback / reset / contention high-risk regression

Fresh or independently rearranged validation must hit:
- candidate mutate-before-false;
- reservation mutate-before-false;
- candidate true-without-postcondition;
- reservation true-without-postcondition;
- unrelated same-color candidate loss;
- unrelated reservation identity swap;
- exact owner-map rollback proof / ROLLBACK_FAILED behavior;
- reset during candidate phase;
- reset during reservation phase;
- duplicate current arrival;
- distinct nested arrival FIFO;
- pair-narrow reset original pair + unrelated reservation;
- foreign-board replacement reservation preservation;
- same-board owner replacement preservation;
- post-dispatch generation barrier.

Exact production dependency category gates remain read-only and MUST NOT be widened.

### H. Sensitivity / load-bearing validation

Execute after V08 start push, restore after each:

S1 — consumer claim bypass:
- temporarily force dispatcher M20 claim to permit different consumers;
- fresh same-dispatcher second-loop test MUST fail for intended reason.

S2 — `agent_parent` presence regression:
- temporarily derive explicit-parent presence from equality/null rather than Variant presence;
- truly-freed explicit-parent frame test MUST fail for intended reason.

S3 — renderer presence regression:
- temporarily derive configured renderer presence from current equality/null;
- truly-freed configured-renderer test MUST fail for intended reason.

S4 — post-dispatch reset barrier regression:
- temporarily remove/reorder the M20 post-dispatch generation/reset barrier so stale raw success could escape;
- reset-inside-dispatch test MUST fail for intended reason.

S5 — exact reservation rollback regression:
- temporarily weaken exact owner-map proof to count-only or otherwise bypass the exact identity check;
- identity-swap adversary MUST fail for intended reason.

S6 — pair-narrow reset regression:
- temporarily restore owner-wide active-entry cleanup behavior;
- foreign/same-board replacement preservation test MUST fail for intended reason.

No sensitivity mutation may be committed. Final accepted production blobs must exactly match the V07 lock.

## Documentation-only reconciliation allowed in V08

Production remains immutable, but current docs may be corrected.

In `docs/02_TECH_ARCHITECTURE.md`, fix the current (non-historical) stale "What is explicitly NOT built yet" paragraph that still describes M14-M19 systems as future and M10 owner QA as pending. It must reflect current repository truth without inventing future M21+ behavior.

Do not rewrite historical audit/prompt evidence.

## Final validation commands/evidence

Record separately:
- `godot --version`;
- full root suite;
- `m20_queue_free_smoke.gd`;
- `m20_v04_lifecycle_smoke.gd`;
- `m20_v05_lifecycle_smoke.gd`;
- `m20_v07_lifecycle_smoke.gd`;
- any new V08 frame-aware smoke;
- zero final SCRIPT ERROR / Parse Error;
- `git diff --check`;
- exact changed files;
- exact pre/post production blobs;
- proof that final committed `scripts/**` diff vs V07 is empty;
- tracker final state.

## Closure disposition

If V08 passes with no production defect exposed, production blobs exact, all known gaps closed, and the whole SB-M20 ledger green, ChatGPT may issue `AUDITED_PASS / STRICT_V2_FINAL_CLOSURE` and close SB-M20-001..014.

If any V08 validation exposes a production defect, STOP without fixing it and return `BLOCKED / V08_VALIDATION_EXPOSED_PRODUCTION_DEFECT`. Do not perform an unrequested V09 production correction.