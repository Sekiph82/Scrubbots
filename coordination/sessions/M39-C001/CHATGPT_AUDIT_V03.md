# M39-C001 V03 — ChatGPT Full-Surface Re-Audit

Date: 2026-09-24
Verdict: **CHANGES_REQUIRED / M39-C001 V03 / FINDING_SET_FROZEN**

Implementation: `b1ff6c8`
Claude log: `coordination/sessions/M39-C001/CLAUDE_LOG_V03.md`

V03 fixes a large majority of the V02 frozen set. The following closure blockers remain.

## Accepted V03 repairs

Independent source review accepts the V03 fixes for:
- strict EconomyConfig typing/domain validation;
- Wallet canonical resource IDs;
- Reward/Gift/Booster/Collection/Heart/2x import hardening;
- forward-only progression gating before normal first-clear economy;
- gameplay-start arming for Retry Heart/streak semantics;
- dynamic 5/6 slot presentation/origin;
- capacity-aware ProofKernel;
- Random three-placement proof implementation;
- Selector post-placement proof;
- failing-stage rollback support;
- Daily timestamp/task-day state;
- collection claimed-state coherence.

These accepted repairs must not be regressed by V04.

## F-M39-V03-001 — Tornado still does not implement the owner-required selected-color in-flight reconciliation

The owner lock requires Tornado to cancel/reconcile the chosen color's:
- committed/in-flight assignments;
- claims;
- reservations;
- agents;
- slot/supply quota;
while preserving unrelated colors.

V03 still refuses when `_color_inflight_count(color) > 0`.

This is safer than the V02 global-quiescence rule, but it still narrows the owner-authorized behavior instead of implementing it.

Required fix:
add the smallest targeted identity-safe M25/M26/M19 cancellation/reconciliation seam and use it transactionally from Tornado.

## F-M39-V03-002 — production Daily still uses the UTC-style fallback, not real local-calendar semantics

`DailyService` now supports an injected `local_day_provider`, which is good.

However its production default remains:
`int(_clock.call() / 86400)`

and the live `EconomyServices/AppState` composition does not inject a timezone-aware local-date provider.

Therefore production still follows UTC epoch-day boundaries rather than the player's local calendar midnight.

Required fix:
wire a real local-date/ordinal provider into the production EconomyServices graph, with deterministic injected test seams. Month/year boundaries must remain consecutive.

## F-M39-V03-003 — +1 Slot rollback is still non-atomic if presentation growth fails

`activate_plus_one_slot()`:
1. spends/reserves economy;
2. grows M24 engine to six;
3. grows the strip.

If strip `set_capacity(6)` fails, code refunds economy and resets capacity authority, but explicitly has no M24 engine shrink/rollback.

The method then returns false while the engine may remain at six.

That violates the V03 exact rollback criterion.

Required fix:
preflight all fallible steps before commit, or add a safe engine rollback/shrink path so failure restores:
- economy;
- capacity authority;
- M24 engine;
- strip/origin presentation;
to the exact prior five-slot state.

## F-M39-V03-004 — progression-first ordering is not a coordinated atomic first-clear transaction

V03 correctly calls `progression.record_win()` before granting economy, which prevents stale/future farming.

But the V03 criterion required:
> any downstream failure leaves exact progression + wallet + streak + Gift Meter + Bot Part state unchanged.

Current flow mutates progression first, then calls first-clear reward, streak and speed entitlement updates with no rollback coordinator.

If a downstream grant fails after progression advances, the system can remain partially committed.

Required fix:
stage/preflight or snapshot/rollback the progression + economy first-clear transaction and add injected failure tests after each downstream step.

## F-M39-V03-005 — production runtime action seams are still missing for three boosters and economy purchase/claim boundaries

The V03 criterion requires canonical production action seams for all four boosters and manual/economy operations.

`ProductionGameplayHost` exposes `activate_plus_one_slot()`, but there are no equivalent production host/controller action methods for:
- Random;
- Selector;
- Tornado.

There is also no canonical wrapper layer coupling purchases/claims/unlocks/exchange mutations to their persistence/save boundary; comments say callers should invoke `request_save()`.

A comment/caller convention is not an authoritative action seam.

Required fix:
add narrow runtime/application action methods that own mutation + result + save-boundary request. Final UI is not required.

## Evidence caveat

Claude explicitly recorded F-M39-V02-006 as IMPLEMENTED_PARTIAL. That was correct. It cannot be marked closed by audit.

The V03 integration suite also does not fault-inject the strip-growth rollback path or downstream first-clear reward failure, so those false-positive paths remain untested.

## Remaining task surface

Still open after V03 audit:
- SB-M39-005
- SB-M39-006
- SB-M39-030
- SB-M39-033 (code + later DEVICE/OWNER safe-area/touch gate)
- SB-M39-035
- SB-M39-036
- SB-M39-037
- SB-M39-039
- SB-M39-040
- SB-M39-044
- SB-M39-052

Frozen finding set: **F-M39-V03-001..005**.

Verdict string:
`CHANGES_REQUIRED / M39-C001 V03 / F-M39-V03-001..005`
