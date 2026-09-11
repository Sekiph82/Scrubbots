# CLAUDE_LOG_V09 — M20-C001 Final Exact-Evidence Whole-Sprint Validation Gate

- Cycle: M20-C001
- Prompt: `coordination/sessions/M20-C001/CHATGPT_PROMPT_V09.md`
- Audit criteria: `coordination/sessions/M20-C001/CHATGPT_AUDIT_CRITERIA_V09.md`
- Freeze: `coordination/sessions/M20-C001/CHATGPT_FULL_SURFACE_REAUDIT_V09.md`
- V08 audit basis: `coordination/sessions/M20-C001/CHATGPT_AUDIT_V08.md`
- Actor: CLAUDE (validation only — no committed `scripts/**` change).
- Engine: Godot `4.7.1.stable.official.a13da4feb`
- V09 tracker start transition (IN_PROGRESS): `df9e9ad` (verified on remote).
- Accepted V07 implementation commit: `e189ee8`.

## OUTCOME
Clean. Entire V09 exact-evidence set + all six S1–S6 sensitivity checks executed;
production stayed immutable; no defect exposed. Return `AWAITING_AUDIT`.

## 0. Tracker start gate
Synced ff (`e13ffdc..ca7a5d2`), owner work preserved. Verified V08 audit + V09
freeze/prompt/criteria; tracker at V08/AWAITING_AUDIT/CHATGPT. Set V09/IN_PROGRESS/
CLAUDE and pushed the tracker-only transition `df9e9ad` BEFORE any V09 test/support/
smoke edit or sensitivity mutation; verified on remote. NO V09 test/support/smoke
edit and NO sensitivity mutation existed before that successful push.

## 1. Production immutability lock
Pre- and post-validation blobs (matched the locked expected values):
- `scripts/gameplay/clearing/complete_clearing_loop.gd` = `06391839523cbc27e88a4b3ef12b730012cd45fa`.
- `scripts/gameplay/dispatch/scrubbot_dispatcher.gd` = `eee10149e4f116af6706beec832042352bf3a6dd`.
`git diff e189ee8 -- scripts/` is EMPTY. No `scripts/**` committed.

## 2–7. Fresh V09 exact-evidence section
`_run_m20_v09_exact_evidence_tests()` in `tests/run_tests.gd` with clearly named
groups: `_v09_owner_claim`, `_v09_activation_snapshots`, `_v09_arrival_preflight`,
`_v09_ledger`, `_v09_rollback`, plus the frame smoke
`tests/m20_v09_lifecycle_smoke.gd`. All prior M19/M20 regressions remain enabled.

- §3 owner claim exact lifecycle (`_v09_owner_claim` + smoke): diagnostic listener
  connected before the first bind; first loop binds; diagnostic independent; second
  live loop rejected with no added M20 callback, cleared_count 0, activation fails,
  its reset mutates no canonical state; first loop coherent; one arrival → exactly
  one clear; owner reset while alive preserves a detached BoardState snapshot and
  does NOT release the claim (second loop still rejected); first loop usable after
  reset. Smoke (real frames): WeakRef to owner resolves null after drop (no strong
  cycle), old M20 transaction callback gone (connection count 2→1, diagnostic
  remains), fresh loop binds and adds exactly one M20 callback (→2).
- §4 activation exact snapshots (`_v09_activation_snapshots`): a full detached
  snapshot (all BoardState cell states, active count, next owner id, exact
  target→owner map, reservation count, all five `(palette,available,active)` slot
  tuples) is captured immediately before every invalid/no-work call (slot -1/5/
  non-int, unavailable, origin NaN-x/NaN-y/±INF, speed NaN/±INF/0/negative, absent
  color, enclosed) and every field is compared unchanged after. Plus nested
  activation → REENTRANT (no second reservation/owner); reset during preflight →
  RESETTING (owner id monotonic); reset inside M19 dispatch → RESETTING with
  exactly one owner consumed and deterministic cleanup; post-dispatch coherence
  loss → COHERENCE_FAILED with cleanup.
- §5 arrival-preflight exact invariants (`_v09_arrival_preflight` + smoke): for
  wrong owner/target/color/agent and unknown owner (fresh each, with an unrelated
  sentinel cell+reservation) — PREFLIGHT_REJECTED, BoardState snapshot unchanged,
  cleared_count unchanged, reservation intact BOTH directions, dispatcher pending,
  raw target candidate present, sentinel reservation unchanged. Plus missing
  reservation; same-board `T→O2` (replacement survives the failed preflight AND the
  later pair-narrow reset); ReservationState rebind(foreign)+foreign replacement
  (survives before and after reset); ColorCandidateIndex rebind(foreign) and
  rebind(null) (reservation+assignment held, cleared 0); target externally CLEARED;
  configured renderer rebound foreign after assignment before arrival; renderer
  queued before arrival; truly-freed renderer before arrival (smoke); stale replay
  after reset; duplicate current owner+agent dropped; duplicate already-queued
  owner+agent as its own test; distinct nested FIFO.
- §6 exact SB-M20-001..014 ledger (`_v09_ledger`): 001 full synchronized tuple;
  002 no-target + enclosed with full-snapshot equality; 003 → queue-free smoke;
  004 1×1 + exhaustion; 005 one-color exact exhaustion; 006 multi-color with an
  unrelated other-color bucket proven unchanged; 007 five in-flight unique owners/
  targets, exact BOTH-direction pairs, first arrival removes only its pair and
  preserves the other four both directions, all finalize (active 0, reservations 0);
  008–013 Easy/Medium/Hard/Very-Hard/59×59/rectangular with exactly-one-cell-changed
  single-cell proof (no GPU/FPS claim); 014 AL-028 (B proven NOT targetable while
  ACTIVE A blocks it, first activation clears A, second real activation selects B,
  exact B reservation both directions before arrival, B clears, slot tuples
  unchanged) + rapid ≥25 + reset-with-multiple preserving BoardState and raw
  candidate truth.
- §7 exact rollback/reset/contention (`_v09_rollback`): candidate/reservation
  mutate-before-false → exact tuple/map restored; candidate & reservation
  true-without-postcondition → rollback; unrelated same-color candidate loss → both
  restored; healthy clear preserves a different-color bucket; identity swap →
  ROLLBACK_FAILED; missing-current-pair reset keeps unrelated and fabricates none;
  pair-narrow reset releases the pair and preserves unrelated; foreign-board and
  same-board owner replacement survive reset; reset during candidate/reservation
  phase → RESET_ABORTED with target ACTIVE; duplicate current + already-queued
  dropped; distinct nested FIFO; post-dispatch generation barrier → RESETTING;
  reset re-entry safe; owner ids monotonic.

## 8. Six load-bearing sensitivity mutations (all executed, restored, not committed)
Each applied alone, its named V09 test observed failing for the intended reason,
then restored exactly (blob re-verified) before the next.
- S1 consumer-claim bypass (`_claim_m20_arrival_consumer` → true): FAIL
  "V09.3: second different live loop bind fails". Restored disp `eee10149…`.
- S2 agent_parent equality (`agent_parent != null`): FAIL (V08 smoke)
  "bind rejects truly-freed explicit parent". Restored disp `eee10149…`.
- S3 renderer equality (`renderer != null`): FAIL (V09 smoke)
  "truly-freed configured renderer -> arrival clears nothing" (+"reservation+
  assignment held until reset"). Restored loop `06391839…`.
- S4 post-dispatch generation barrier removed: FAIL "V09.4: reset inside M19
  dispatch -> RESETTING (got NONE)". Restored loop `06391839…`.
- S5 owner-map proof → count-only (`_owner_map_equals` returns size ==): FAIL
  "V09.7: identity swap cannot pass exact owner-map proof -> ROLLBACK_FAILED (got
  RESERVATION_ROLLBACK)". Restored loop `06391839…`.
- S6 pair-narrow reset → owner-wide `release_for_owner`: FAIL "V09.7: same-board
  owner replacement V<->O survives reset (got -1)" (+ foreign/pair-narrow cases).
  Restored disp `eee10149…`.

## 9. Documentation / scope
V08 current architecture documentation is accepted; no docs edited in V09 (no new
documentation defect found). Committed files this cycle: `tests/run_tests.gd`,
`tests/m20_v09_lifecycle_smoke.gd` (new), `TASKS.md`, this log. No `scripts/**`
change; no `tests/support/**` change (the existing V08 support double was reused).

## 10. Final validation
- Final blobs: loop `06391839523cbc27e88a4b3ef12b730012cd45fa`, dispatcher
  `eee10149e4f116af6706beec832042352bf3a6dd` (match locked V07 values).
- `git diff e189ee8 -- scripts/` EMPTY.
- `godot --version` → `4.7.1.stable.official.a13da4feb`.
- Full root suite → `Total checks: 4192 / Failures: 0 / RESULT: ALL PASS`, exit 0.
- `tests/m20_queue_free_smoke.gd` PASS; `tests/m20_v04_lifecycle_smoke.gd` PASS;
  `tests/m20_v05_lifecycle_smoke.gd` PASS; `tests/m20_v07_lifecycle_smoke.gd` PASS;
  `tests/m20_v08_lifecycle_smoke.gd` PASS; `tests/m20_v09_lifecycle_smoke.gd` PASS.
- Zero final M20 `SCRIPT ERROR` / `Parse Error` (the only ERROR lines are the
  pre-existing importer negative-path file tests).
- `git diff --check` clean (benign LF→CRLF advisories only).
- Changed files: `tests/run_tests.gd`, `tests/m20_v09_lifecycle_smoke.gd`,
  `TASKS.md`, `coordination/sessions/M20-C001/CLAUDE_LOG_V09.md`. No `scripts/**`.
- Scope grep: no win/lose/scoring/session-complete/M21/slot-queue/cooldown/
  consumption behavior introduced.

## 11. V09 evidence table

| Row | Named test function / smoke | Direct assertions | Actual result | Sensitivity mapping |
|---|---|---|---|---|
| G-V08-01 owner claim | `_v09_owner_claim` + `tests/m20_v09_lifecycle_smoke.gd` | first binds; diagnostic independent; second loop rejected/unbound/no callback/clear 0; second reset no-op; first coherent + 1 clear; owner reset holds claim + snapshot; GC releases claim, old callback gone, fresh loop adds exactly one callback, no strong-cycle leak | PASS | S1 (claim bypass → "second different live loop bind fails") |
| G-V08-02 activation snapshots | `_v09_activation_snapshots` | full detached snapshot (cells/active/next-owner/res-map/res-count/5 slot tuples) compared per invalid+no-work case; REENTRANT; reset-preflight RESETTING; reset-in-dispatch RESETTING (one owner consumed); coherence-loss COHERENCE_FAILED | PASS | S4 (barrier → "reset inside M19 dispatch -> RESETTING") |
| G-V08-03 arrival preflight | `_v09_arrival_preflight` + smoke | identity 5-tuple PREFLIGHT_REJECTED with reservation both directions + candidate + sentinel intact; missing/T→O2/foreign/candidate-drift/CLEARED/renderer-death/stale/dup-current/dup-queued/FIFO | PASS | S6 (owner-wide → "same-board owner replacement survives reset"), S3 (renderer) |
| G-V08-04 task ledger | `_v09_ledger` + `tests/m20_queue_free_smoke.gd` | SB-M20-001..014 exact (synchronized tuple, exhaustion, multi-color bucket, five-pairs both directions, dims single-cell, AL-028 B-unreachable→cleared, rapid, reset-multiple) | PASS | — |
| G-V08-05 rollback/reset | `_v09_rollback` | mutate-before-false exact restore; true-without-postcondition; unrelated-loss restore; identity-swap ROLLBACK_FAILED; pair-narrow/foreign/same-board; reset phases; dup/FIFO; barrier; re-entry; monotonic | PASS | S5 (count-only → identity-swap fails), S6 (foreign/same-board), S4 (barrier) |
| G-V08-06 traceability | S1–S6 sensitivity mutations | each mutation fails its named V09 test for the intended reason, restored byte-for-byte (blob re-verified), none committed | PASS | S1–S6 all confirmed load-bearing |

## 12. Handoff
Did NOT close any SB-M20 checkbox or mark COMPLETE/READY_FOR_NEXT_TASK. Progress
unchanged (290/719; 290/943; lastCompletedTaskId M19-C001-V06). Tracker set to
M20-C001-V09 / AWAITING_AUDIT / CHATGPT. Validation tests/smoke/log/tracker committed
and pushed; remote verified; production blobs remain the exact locked V07 values.

Return: `AWAITING_AUDIT`.
