# M29-C001 V03 — ChatGPT Strict Audit

Date: 2026-09-19
Repository: `Sekiph82/Scrubbots`
Milestone: `M29 — Mobile Touch / Production Input Integration`
Cycle: `M29-C001 V03`
Auditor: ChatGPT
Implementation SHA: `acce76ceaec6b9565196ab3b9cc41a262d0baedc`
Claude log SHA: `6b3876aeddf98a5acb47085046c933fc69cedc76`
Prompt: `coordination/sessions/M29-C001/CHATGPT_PROMPT_V03.md`
Criteria: `coordination/sessions/M29-C001/CHATGPT_AUDIT_CRITERIA_V03.md`

## Verdict

**AUDITED_PASS / M29 MOBILE TOUCH & PRODUCTION INPUT CLOSED**

The owner completed the required graphical F6 retest after the code audit and explicitly confirmed all observed behaviors are now correct.

Owner acceptance confirms:
- visible Scrubbot movement works;
- Blue batch countdown works as robots leave the slot;
- visible pixel clearing works;
- ACTIVE / WAITING transitions are correct;
- WAITING -> ACTIVE wake works;
- Pause/resume works;
- manual 1x/2x works.

No further M29 remediation cycle is required.

## Implementation isolation

Verified implementation commit:
`acce76ceaec6b9565196ab3b9cc41a262d0baedc`

Its parent is:
`d361c08560eced85c9f6906d92694595e4251f7b`

The implementation changes exactly eight files:
- `scripts/gameplay/board/board_presentation.gd`
- `scripts/gameplay/runtime/production_gameplay_host.gd`
- `scripts/gameplay/runtime/production_runtime_controller.gd`
- `scripts/ui/batch_slot_view.gd`
- `scripts/ui/gameplay_screen.gd`
- `tests/m29_presentation_identity_evidence.gd`
- `tests/m29_realtime_movement_smoke.gd`
- `tests/m29_slot_display_sync_evidence.gd`

Implementation -> log is exactly one later commit containing only:
`coordination/sessions/M29-C001/CLAUDE_LOG_V03.md`.

Root `TASKS.md` was not modified by Claude.
M30 was not implemented.
No AI image generation was used.

## F-M29-MANUAL-001 — renderer / AgentLayer identity

**CODE CLOSED.**

Before V03, every responsive `BoardPresentation.configure()` created a new BoardRenderer and AgentLayer. Runtime/M20 remained bound to older instances.

V03 now:
- creates BoardRenderer only if the stored renderer is null/dead;
- creates AgentLayer only if the stored layer is null/dead;
- reuses the same instances on later configure/relayout;
- reconfigures the same renderer;
- rescales the same AgentLayer.

This preserves the runtime-bound presentation identities through responsive relayout.

Direct V03 evidence tests:
- exact renderer identity before/after resize;
- exact AgentLayer identity before/after resize;
- exactly one renderer child;
- exactly one AgentLayer child;
- live agent survives resize on the same parent;
- V02 visible slot-origin mapping remains exact after resize;
- authenticated clear changes the current visible renderer pixel to alpha 0.

The test transition explicitly covers 1080×2160 -> 683×1366.

## Real SceneTree runtime clock

**CODE CLOSED.**

`m29_realtime_movement_smoke.gd` uses the real `ProductionGameplayHost` at 683×1366 with `ProductionRuntimeController._process(delta)` enabled.

It does not manually call `runtime.tick()`.

The test proves:
- real front activation fills M24;
- a real ScrubbotAgent appears;
- its progress increases across later SceneTree frames;
- committed work reaches authenticated clear;
- BoardState target becomes CLEARED;
- the current visible renderer pixel becomes transparent;
- focus/system suspension freezes travel;
- focus regain resumes travel and does not leave runtime permanently suspended.

This directly targets the owner's observed "committed for minutes, no visible progress" failure.

## Five-slot displayed count

**CODE CLOSED.**

`BatchSlotView` now displays:
`remaining_to_clear - committed`

instead of raw remaining plus a parenthesized committed count.

Direct evidence proves:
- fresh Blue50 -> 50;
- first committed work -> 49;
- second committed work -> 48;
- the historical `50 (2)` form is removed;
- after an authenticated clear, authoritative M24 remaining/committed accounting remains unchanged and the waiting count remains coherent.

## Live ACTIVE / WAITING / EMPTY synchronization

**CLOSED / OWNER VISUALLY CONFIRMED.**

The production runtime now invokes a presentation sync callback after each driven tick. The host pushes a fresh detached M24 snapshot into the five-slot strip.

Therefore scheduler-driven state changes no longer wait for another player click before appearing:
- commit;
- ACTIVE -> WAITING;
- WAITING -> ACTIVE wake;
- rollback;
- finalize;
- completion -> EMPTY.

Reset also explicitly refreshes the screen.

The UI remains presentation-only and does not perform targetability or routing.

The V03 live-sync evidence verifies strip state/count equals authoritative M24 every observed frame and sees WAITING -> ACTIVE and completion -> EMPTY transitions.

### Hazard Bot Brown3 note

The Claude log says the early Brown3 WAITING behavior is covered. The generic live-sync test directly proves an early non-blue WAITING state and exact UI/M24 equality, but it does not independently assert the identity `Brown3` in a dedicated one-line assertion.

Production semantics nevertheless support the intended result: M25 marks a selected oldest eligible color batch WAITING when no target exists, M26 subsequently syncs the resulting M24 snapshot, and the accepted M27 trace proves Brown3 has zero immediate clear at that point.

Because this specific behavior came from the owner's visual observation, the owner retest below is the final acceptance gate for Brown3 presentation.

## Full regression evidence

Claude reports PASS for:
- full root suite;
- M29 presentation identity;
- M29 real-time SceneTree movement;
- M29 slot display/live sync;
- M29 Hazard Bot runtime smoke;
- M29 exact slot origin;
- M29 input gate;
- M29 speed authority;
- M28 layout;
- M27 Hazard / 59 / generation;
- M26 Hazard / 59;
- M25 V03;
- M24 V02;
- M23 V03;
- M22 Railroad / connector / real demo;
- M20 lifecycle;
- `git diff --check`.

The full Hazard production smoke still reports:
- 400 authenticated clears;
- final ACTIVE = 0;
- no ghost / duplicate target;
- M23 exhausted;
- automatic 2x;
- exact visible origins;
- 1x/2x gameplay-truth equivalence.

## Non-blocking future hardening note

V03 adds `ProductionGameplayHost.reset_session()`, which currently calls `scheduler.reset()` and then proceeds with M24/M23/runtime reset without checking the scheduler reset result.

The accepted M26 scheduler reset contract can fail/defer rather than partially tear down. This helper is not currently exposed as the player's shipping retry flow, and M30 retry remains design-gated, so it does not block the present M29 graphical retest.

Before M30 binds a real Retry action to this helper, reset/retry must honor the M26 reset result and must not reset M24/M23 if scheduler teardown failed or is still pending.

## Owner graphical retest — PASS

Open:

`res://scenes/debug/m29_hazard_bot_playtest.tscn`

Press **F6**.

Use the same first-column test that originally exposed the bug.

Owner directly confirmed:

1. After placing Red15 / Yellow1 / Blue50 / Blue50 / Brown3, visible debug Scrubbot circles actually move.
2. Blue50 count drops 50 -> 49 -> 48 as robots leave the slot.
3. Pixels visibly become transparent when robots arrive.
4. Red and Yellow display WAITING while unreachable.
5. Brown3 also becomes WAITING while still unreachable after the two early Blue50 batches.
6. WAITING batches later return ACTIVE automatically when clears open a legal route.
7. Pause freezes moving robots and resume continues them.
8. 1x/2x visibly changes travel/cadence.

Known complete-clear click order:

`1,1,1,1,1,1,1,2,2,2,2,2,2,3,3,3,3,3,3`

## Final closure

Owner graphical acceptance is complete.

Close `SB-M29-001..009`.

Advance to **M30 — Win/Lose Rules [DESIGN GATE]**.

The non-blocking `reset_session()` hardening note remains mandatory before shipping Retry is bound in M30, but it does not reopen M29.
