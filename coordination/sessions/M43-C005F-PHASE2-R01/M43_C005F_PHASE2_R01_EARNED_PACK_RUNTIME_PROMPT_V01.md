# M43-C005F-PHASE2-R01 — Earned Pack Production Wiring — MASTER CLAUDE PROMPT V01

Repository: `Sekiph82/Scrubbots`
Owner-local: `C:/Users/sekip/Desktop/ScrubBots`
Engine: Godot 4.7.2
Date: 2026-10-08

## Objective

Fix the owner-observed production defect:

**Earned Standard/Premium card packs are currently opened silently inside EconomyServices reward handlers and written directly to Collection. The accepted Standard/Premium pack-opening screens never appear in the real game.**

This remediation must wire earned packs into the real shipping pack-presentation path without double draw, reroll, duplicate grant or save corruption.

Read first:
- root `TASKS.md`
- `coordination/sessions/M43-C005F-PHASE2/CHATGPT_INDEPENDENT_AUDIT_V01.md`
- `coordination/sessions/M43-C005F-PHASE2/CHATGPT_AUDIT_AMENDMENT_R01.md`
- `scripts/economy/economy_services.gd`
- `scripts/economy/reward_grant_service.gd`
- `scripts/collection/card_pack_service.gd`
- `scripts/collection/pack_commit_transaction.gd`
- `scripts/collection/pack_receipt_ledger.gd`
- `scripts/app/app_state.gd`
- `scripts/app/main.gd`
- `scripts/ui/home/home_screen.gd`
- Standard/Premium ceremony sources and tests.

Root `TASKS.md` is read-only for Claude.

## Owner truth

The owner has already visually accepted:
- Results WIN feel (F003)
- Results reward-row feel (F004)

Do not change them except unavoidable compile/API adjustments, and preserve their exact visible behavior.

F005 is reopened because production never reaches the pack ceremony.

## Current production defect to remove

Today:
`RewardGrantService.grant(tx_id, rewards)`
→ `EconomyServices` handler for `standard_card_packs/premium_card_packs`
→ `CardPackService.open_standard/open_premium`
→ cards immediately enter Collection
→ claim UI refreshes
→ NO pack ceremony.

This direct silent pack-resolution path must no longer be the shipping behavior for earned packs.

## Required architecture contract

Implement a canonical **durable pending earned-pack queue** (name is implementation choice) inside the economy/save graph.

### A. Reward grant semantics

For resource keys:
- `standard_card_packs`
- `premium_card_packs`

a successful reward grant must enqueue exactly N pending earned-pack entries instead of drawing cards immediately.

Each queue entry must have a stable unique id derived from the parent canonical reward transaction id + kind + ordinal. Duplicate/reentrant reward grants must not enqueue duplicates.

The RewardGrantService handler contract may be extended so handlers can receive the parent tx id, but preserve all non-pack resources and all existing idempotency.

Current configured pack sources that MUST work:
- Gift Meter 10 / 250 / 500 Standard pack
- Gift Meter 1000 Premium pack
- Daily Login day 2 Standard
- Daily Login day 4 Standard
- Daily Login day 5 Premium

Implementation must be generic for future rewards with these resource keys.

### B. Durable save / migration

Pending earned packs must persist in the canonical EconomyServices snapshot.

Strict import validation:
- supported kinds only;
- stable non-empty unique ids;
- no negative counts / malformed rows;
- old saves with no pending-pack section migrate safely to empty;
- malformed present section fails closed according to existing save policy.

Do not alter Remote Content/R2.

### C. Canonical draw/commit

A pending pack must be drawn/applied only through the canonical pack transaction authority.

Extend/refactor `PackCommitTransaction` as needed so opening one pending queue item:
- uses that queue item's stable id as pack tx/presentation id;
- draws exactly once;
- applies cards exactly once;
- records the durable PackReceiptLedger receipt;
- durable-save succeeds before model is released;
- failure restores the exact pre-open EconomyServices snapshot;
- replay of the same id returns the same receipt/model without drawing again.

Do NOT reintroduce a second pack RNG or direct Collection mutation path.

Important restart rule:
- committing/drawing the pack does NOT permanently discard the pending presentation before the user finishes viewing it;
- if the app dies after commit but before/during ceremony, next launch must reopen the SAME committed receipt, not draw a new pack.

A queue entry may be acknowledged/removed only after its shipping ceremony completes successfully, followed by durable save.

### D. Production PackPresenter

Create one app-level presentation coordinator analogous in responsibility to CeremonyPresenter.

It must:
- use the real app `ModalStack`;
- inspect the durable pending earned-pack queue in FIFO order;
- if the queue item already has a committed receipt, replay that receipt model without draw;
- otherwise call the canonical AppState/PackCommitTransaction commit for that queue item;
- instantiate the accepted Standard or Premium shipping ceremony;
- bind the app's single canonical FeedbackAdapter;
- push it on ModalStack;
- on `presentation_completed`, durably acknowledge/remove that queue item, then show the next pending pack;
- never grant, reroll or decide rarity itself.

No test-only harness may be the production route.

### E. Real trigger wiring

After successful durable actions that may award packs, production must request/drain the PackPresenter.

At minimum:
- Gift Bar claim
- Daily Login claim

Prefer a generic `ProductionActionFacade.action_committed` observer that checks the queue rather than hard-coding reward values in UI.

Also drain pending packs:
- after app boot reaches a safe Home presentation state;
- after returning Home when no higher-priority modal/ceremony owns the stack.

Do not interrupt active gameplay with a pending pack.

If a Gift milestone meta ceremony and a pack opening are both pending, preserve deterministic presentation ordering. Document and test the chosen order. Recommended: current committed Gift milestone/claim confirmation first, then pack opening, then later meta ceremonies; but use existing app ceremony/barrier authority and do not invent overlapping modals.

### F. F005 feel integration

The Phase 2 feel behavior now must be exercised through the REAL production presenter:
- Standard/Premium accepted animation;
- existing NEW/DUPLICATE truth;
- F005 Spark accents through FeedbackAdapter;
- Reduced = zero plugin work;
- no direct GFF/Spark access outside adapter.

Pack sparkle tuning is NOT the blocker in this R01. First make the shipping pack screen exist. Keep current restrained sparkle unless owner later requests visual tuning.

## Hard invariants

- No silent earned-pack direct draw in RewardGrantService handlers.
- No duplicate pack draw.
- No duplicate Collection card mutation.
- No reroll on reopen/restart.
- Premium card 0 Rare-or-better guarantee preserved.
- Pity semantics preserved and advances exactly once per actually opened earned pack.
- Set/Master completion truth and rewards preserved.
- Reward grant atomicity/idempotency preserved.
- Gift/Daily other reward resources unchanged.
- Save/load rollback behavior preserved.
- No direct plugin calls outside FeedbackAdapter.
- No Remote Content/R2/LF/VOID changes.
- No `TASKS.md` edit by Claude.

## Required runtime scenarios

1. Fresh save → reach Gift 10 → CLAIM → Standard pack screen MUST open → Tap 1 01..09 → 3 cards → Tap 2 route → close → Collection reflects exactly those 3 cards.
2. Gift 250 same behavior while SB +100 and Bot Parts +2 remain exact.
3. Gift 1000 → Premium pack screen opens with exactly 5 cards and Rare+ guarantee, while guaranteed-new/fallback semantics remain exact.
4. Daily day 2 / day 4 → Standard pack screen.
5. Daily day 5 → Premium pack screen.
6. App kill/restart after reward claim but before pack opening → same pending pack appears.
7. App kill/restart after pack commit but before ceremony completion → same receipt appears, no reroll.
8. Multiple queued packs → serialize one at a time.
9. Reduced Effects → same truth, reduced ceremony, no plugin particles.
10. Plugins missing/throwing → pack ceremony still completes natively.
11. No pack reward → no pack popup.

## Required tests

Add permanent tests for:
- pending queue schema/import/migration/idempotency;
- reward grant enqueues instead of drawing;
- collection unchanged until pack commit;
- canonical commit consumes/draws one pending pack exactly once;
- receipt replay after restart;
- presentation ack/removal only after completed ceremony;
- Gift 10/250/500/1000 and Daily 2/4/5 production integration;
- multiple queue FIFO;
- Premium guarantee;
- pity exactly once;
- set/master completion;
- save failure rollback;
- duplicate claim/action callback;
- ModalStack ordering/no overlap;
- Phase 1 + Phase 2 feel regressions;
- root suite;
- headless import/boot;
- git diff --check.

## Owner-local sync

Owner-local checkout is known to have protected dirty/untracked plugin/project files and may not fast-forward. Inspect first. Never reset/clean/stash destructively. Use a clean TEMP worktree at exact origin/main if needed.

## Logs

Write:
- `coordination/sessions/M43-C005F-PHASE2-R01/M43_C005F_PHASE2_R01_CLAUDE_LOG_V01.md`

Include:
- exact starting/final SHA;
- architecture chosen;
- old silent path removed proof;
- reward-source matrix;
- save/restart evidence;
- runtime screenshots of real Gift claim → Standard/Premium ceremony;
- regression table;
- forbidden-path proof;
- owner-local sync truth.

End:
`AWAITING_GPT_M43_C005F_PHASE2_R01_AUDIT_AND_OWNER_RUNTIME_REVIEW`
