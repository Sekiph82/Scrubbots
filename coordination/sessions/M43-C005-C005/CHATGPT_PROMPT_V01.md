# M43-C005-C005 — REUSABLE PRODUCTION REWARD-REVEAL SEQUENCING

Status: **READY FOR CLAUDE**  
Date: 2026-10-04  
Repository: `Sekiph82/Scrubbots`  
Branch: `main`  
Canonical task: **SB-M43-063**  
Root `TASKS.md`: **READ ONLY — ChatGPT owns it.**

## 0. Goal

Implement the reusable **production presentation sequencer** that M43-C005 ceremonies will use for short ordered reward/reveal beats.

This task is **SB-M43-063 only**.

Do not implement Standard/Premium pack opening, set/master completion, Robot Unlock, feature/world unlock, Gift/Daily ceremony content, or GameFeelFlow/Saltmire Spark yet.

The key safety law:

> Presentation may reveal, delay, skip or fast-forward only after authoritative reward/progression state is already committed. A presentation callback can never be the authority that grants, claims, opens, unlocks, equips, saves or advances gameplay truth.

## 1. Sync / read first

Work from:
`C:\Users\sekip\Desktop\ScrubBots`

Synchronize `main` with `origin/main` non-destructively. Preserve owner-local `project.godot`, addons and all unrelated untracked work.

Read:
- `CLAUDE.md`
- root `TASKS.md` read only
- `coordination/AUDIT_POLICY.md`
- `coordination/sessions/M43-C005-C004/CHATGPT_AUDIT_V01.md`
- `scripts/ui/results_screen.gd`
- `scripts/ui/popup/base_popup.gd`
- `scripts/ui/popup/modal_stack.gd`
- `scripts/app/main.gd`
- current M43 Results tests and M43-C005 preview harness/tests

Architecture facts to preserve:
- Results receives a **committed terminal receipt** and never grants from the screen.
- Results currently has a presentation-only ordered row reveal plus `finish_reveal()`.
- Results `set_ceremony_barrier()` already exists for future M43-C005 mandatory follow-ups.
- BasePopup/ModalStack are presentation/input lifecycle authorities only.
- C005 preview harness is evidence, not shipping authority.

## 2. Implement one reusable sequencer

Create one reusable production component under an appropriate `scripts/ui/` presentation path.

The exact class/API may follow current architecture, but it must support at minimum:

1. deterministic ordered steps;
2. short per-step duration/delay;
3. start exactly once for a presentation instance/key;
4. explicit **fast-forward / finish** to the exact final visual state;
5. explicit **cancel/cleanup** for route change, hidden screen or freed popup;
6. Reduced Effects mode that lands immediately on the same final information/state;
7. completion signal/callback that fires at most once;
8. safe no-op behavior for empty sequences;
9. restart/new-key behavior without stale tween/callback leakage;
10. zero economy/progression/save authority.

The sequencer must not know about Scrub Bucks, packs, cards, robots, Gift Meter, progression, save data, ads or IAP. It sequences presentation steps only.

Do not scatter a second sequencer into each future ceremony.

## 3. First real shipping consumer: ResultsScreen

Refactor the existing WON reward-row/momentum reveal in `scripts/ui/results_screen.gd` to use the reusable sequencer.

Preserve current approved Results behavior:
- receipt order is unchanged;
- all rows already exist from committed receipt truth before animation begins;
- row timing stays visually equivalent to the current `REVEAL_STEP_S = 0.16` family unless a tiny implementation-equivalent adjustment is required;
- momentum still follows committed reward rows using its existing configured reveal delay;
- Reduced Effects shows final state immediately;
- `finish_reveal()` remains available/compatible and fast-forwards presentation only;
- Continue/Home behavior and Results ceremony barrier semantics do not change;
- repeated `show_model()`, resize, visibility changes or route churn cannot duplicate grants, callbacks or nodes.

Do not make a first Continue tap become a new hidden “skip” action. The approved Results navigation semantics remain unchanged. The reusable fast-forward API exists for current/future callers without hijacking the existing CTA.

## 4. Future-ceremony seam

Prove the reusable component can support the next C005 tasks without implementing them.

Add a focused test/harness case using dummy presentation controls/steps that demonstrates:
- 3-step and 5-step sequences;
- immediate fast-forward from step 0/middle/final;
- Reduced Effects;
- cancel/restart with a new presentation key;
- no duplicate completion;
- cleanup leaves no running tween/timer/node accumulation.

Do not bind real Standard/Premium pack assets yet. That is SB-M43-064/065.

## 5. Authority / idempotency tests

Add focused tests proving:

- starting/restarting/finishing/canceling the sequencer cannot call `RewardGrantService`, CardPackService, CollectionInventory, RobotUnlockService, GiftMeterService, save, navigation or gameplay mutation;
- same presentation key cannot replay a one-shot start/completion incorrectly;
- a genuinely new presentation key can run;
- fast-forward changes only presentation state and does not alter the committed receipt/economy snapshot;
- repeated Results `show_model()` with the same committed model preserves exact reward text/order and no economy state changes;
- hiding/freeing Results kills active presentation work;
- Reduced Effects final visual information equals FULL final information.

Use sensitivity checks where practical so the new assertions are not vacuous.

## 6. No plugin feel yet

**Do not integrate GameFeelFlow or Saltmire Spark in this task.**

M43-C005F is separately planned. SB-M43-063 builds the native authoritative presentation sequencing seam that those optional plugins may later decorate through the fail-open adapter.

## 7. Regression

Run at minimum:
- new focused SB-M43-063 suite;
- current M43-C001A/B/R Results suites;
- M43-C002/C003/C004/C005 relevant suites;
- relevant M39 reward/economy idempotency tests;
- root `tests/run_tests.gd`;
- `git diff --check`.

No unexplained new warnings/errors.

## 8. Evidence / log

Create:
- `coordination/sessions/M43-C005-C005/CLAUDE_LOG_V01.md`
- concise architecture/test matrix proving the sequencer is presentation-only and reusable.

If visual behavior in Results changes materially, produce before/after evidence and stop for owner review. If the refactor is visually equivalent, no new owner visual gate is required for SB-M43-063.

Do not edit root `TASKS.md`.

## 9. Publish / return

Commit and push authorized changes to `origin/main`.

Return:
- final SHA;
- sequencer path/API summary;
- Results integration summary;
- focused + regression results;
- evidence/log URL;
- any blocker.

Finish exactly:

`AWAITING_GPT_M43_C005_C005_REWARD_REVEAL_SEQUENCER_AUDIT`
