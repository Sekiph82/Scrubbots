# M25-C001 V01 — Batch Target Claim Engine — Claude Implementation Log

Repository: `Sekiph82/Scrubbots`
Branch: `main`
Actor: Claude (implementer/test runner)
Engine: Godot `4.7.2.stable.official.ed1daf0bf` (unchanged)
Milestone: `M25 — Batch Target Claim Engine`
Execution mode: continuous (all five work packages, no intermediate handoff)
Handoff state: `AWAITING_AUDIT`

## 1. Commit identities

- **Safe-sync start `origin/main` SHA:** `ebab53b` (fast-forward `97a8f44..ebab53b`;
  incoming commits were M24-close/M25-open coordination + tracker only — none touched
  `project.godot`, `scripts/` or `tests/`). Owner-local `project.godot` + untracked
  `.import`/`.uid` sidecars preserved, left unstaged. No `reset --hard` / `clean -fd` /
  destructive restore / force push.
- **Implementation SHA (single focused commit, pushed first):**
  `65294d78037268508a5ced5d02f847919a2cfe3b`
  (`feat(M25-C001 V01): batch target claim engine (SB-M25-001..032)`).
- **Final implementation SHA:** `65294d78037268508a5ced5d02f847919a2cfe3b`.
- **This log** is a separate final documentation commit pushed afterward.

## 2. Changed / new files

Production (new, gameplay-domain only — no UI/Node, no spawn/route/solver):
- `scripts/gameplay/targeting/batch_target_claim_engine.gd` — the M25 engine.

Tests (new):
- `tests/m25_claim_model_evidence.gd`
- `tests/m25_blue_arbitration_evidence.gd`
- `tests/m25_rollback_finalize_reset_evidence.gd`
- `tests/m25_scale_evidence.gd`
- `tests/support/m25_failing_commit_batches.gd` — FiveSlotBatchEngine subclass forcing
  commit_work failure.
- `tests/support/m25_reentrant_access.gd` — access double re-entering the claim engine.

Tests (modified):
- `tests/run_tests.gd` — `_run_m25_batch_claim_tests()` (+49 checks) registered.

No existing production authority modified (BoardState, ColorCandidateIndex,
ReservationState, TargetSelector, ProductionTargetAccess, ProductionRoutingSystem,
Dispatcher, ScrubbotAgent, CompleteClearingLoop, FiveSlotBatchEngine, M23 supply, and
historical SlotSystem are all untouched). Root `TASKS.md` absent.

## 3. Architecture

`BatchTargetClaimEngine` binds one coherent bundle — BoardState, FiveSlotBatchEngine,
TargetSelector (bound to the same board + ReservationState), ReservationState (bound to
the same board) — with exact-identity coherence checks; mixed/foreign/null binds fail
closed. It keeps ONE session-scoped ledger `claim_id -> {slot, batch_id,
placement_sequence, color_id, target, coord, owner_id, status}`. ReservationState remains
the authoritative live target->owner map; the ledger only mirrors identity. The M24 work
identity committed via `commit_work(slot, claim_id)` IS the claim_id, so M24 `committed`
reflects live claims one-for-one.

**Claim transaction** (`claim_for_color`): pick the oldest placement-sequence occupied
same-color batch with capacity>0 (`oldest_capacity_slot` — a batch at capacity 0 is
filtered out, which is exactly the owner-locked spill rule); look up that slot's
caller-supplied ProductionTargetAccess; mint a monotonic reservation owner id + claim id;
`TargetSelector.select_and_reserve` (preserves bottom-most/left-most, only ACTIVE/matching/
unreserved/production-targetable); if no target → batch WAITING, no reservation/commit/
ledger; else confirm batch ACTIVE and `commit_work(slot, claim_id)`; if commit fails,
release exactly the new reservation and publish nothing; only after both reservation +
commit publish the ledger entry. `remaining_to_clear` is never touched.

**Rollback** (`rollback_claim`): M24 `rollback_work` first (committed-1, remaining
unchanged); then release exactly its reservation pair; erase the ledger entry.
**Finalize** (`finalize_clear`): requires target CLEARED and reservation no longer owned
by this claim's owner, then `resolve_clear(claim_id)` once (committed-1 AND remaining-1)
and erase. **reconsider_color** re-attempts a claim after an authoritative board change
using live production targetability. **reset** releases every M25 reservation pair +
rolls back every pre-clear M24 work id, clears the ledger, and leaves unrelated
ReservationState owners intact; it does not reset M24/M23. A single `_busy` guard
serializes the external-collaborator path (nested claim/rollback/finalize/reset fail
closed).

## 4. Exact traces

BLUE 8/14/12 (real M23->M24 + real routing), `m25_blue_arbitration_evidence.gd`:
```
placement seq: BLUE_8(slot4)=1 BLUE_14(slot3)=2 BLUE_12(slot2)=3
  claim 0 -> slot 4 batch BLUE_8 target 6 coord (0, 2) owner 0
  claim 1 -> slot 4 batch BLUE_8 target 7 coord (1, 2) owner 1
  claim 2 -> slot 4 batch BLUE_8 target 8 coord (2, 2) owner 2   (bottom-most then left-most)
  capacity-spill claim slots: [4, 4, 3]   (OLD cap2 exhausted -> spills to NEW slot3)
  pre-opening claim: { ok: false, error: no_target, slot: 4, waiting: true }   (blocked blue NOT pre-owned)
  post-opening claim: { ok: true, claim_id: M25C1, slot: 4, batch_id: B8, target: 4, owner_id: 0 }   (claimed at opening, oldest batch)
```

Scale, `m25_scale_evidence.gd`:
```
rect(40x12): cells=480 attempts=12 accepted=12 reservations=12 live=12 time=16ms
square(59x59): cells=3481 attempts=12 accepted=12 reservations=12 live=12 time=38ms
```
Both: oldest slot 4 claimed all (FIFO), reservations == live claims == accepted (unique),
reset released all claims/reservations and rolled back M24 committed.

Rollback / finalize (`m25_rollback_finalize_reset_evidence.gd`): claim -> committed 1;
rollback -> committed 0, remaining unchanged, reservation released, double rollback fails
closed; finalize before clear fails (ACTIVE+reserved); after authoritative clear
(resolve_arrival + set CLEARED) finalize -> remaining AND committed each -1; double/random
finalize fail closed; reset with 3 live claims -> 0 claims, unrelated owner 555555 on cell
15 survives, no leak.

## 5. SB-M25-001..032 evidence mapping

| Task | Implementation | Direct evidence | Result |
|------|----------------|-----------------|--------|
| SB-M25-001 session-scoped claim service/ledger | `batch_target_claim_engine.gd` (`_claims`, narrow API) | run_tests `_m25_bind_and_model`; claim-model evidence | PASS |
| SB-M25-002 ReservationState remains authority | engine reuses ReservationState; ledger mirrors only | run_tests uniq checks; claim-model "owner==claim owner" | PASS |
| SB-M25-003 claim record fields | ledger record (batch/slot/target/coord/color/owner/claim_id) | `get_claim`/`claim_snapshot`; claim-model evidence | PASS |
| SB-M25-004 eligible-only claims | `claim_for_color` via TargetSelector eligibility | run_tests arb; BLUE evidence | PASS |
| SB-M25-005 no pre-claim of blocked pixel | WAITING path (no reservation/commit) | BLUE evidence C pre-opening; run_tests waiting | PASS |
| SB-M25-006 multiple same-color batches | duplicate colors supported | BLUE evidence; run_tests | PASS |
| SB-M25-007 oldest placement first | `oldest_capacity_slot` | BLUE claims all slot4; run_tests arb | PASS |
| SB-M25-008 deterministic arbitration | monotonic ids, deterministic order | run_tests `_m25_deterministic_replay` | PASS |
| SB-M25-009 oldest keeps work while capacity | capacity>0 filter + oldest | BLUE claims 0-2 slot4; run_tests | PASS |
| SB-M25-010 spill at capacity 0 | capacity-0 batch filtered out | BLUE spill [4,4,3]; run_tests spill | PASS |
| SB-M25-011 colors independent | color filter in arbitration | run_tests (RED no batch) | PASS |
| SB-M25-012 TargetSelector order preserved | delegates to `select_and_reserve` | BLUE targets 6,7,8; claim-model target 12 | PASS |
| SB-M25-013 atomic transaction | select+reserve+ledger+commit_work tuple | run_tests atomic; claim-model | PASS |
| SB-M25-014 one target one claim | reservation uniqueness + ledger | run_tests uniq; `is_target_claimed` | PASS |
| SB-M25-015 no duplicate claim to same target | ReservationState excludes reserved | run_tests uniq; scale unique | PASS |
| SB-M25-016 refuse claim at zero capacity | `oldest_capacity_slot` capacity>0 | run_tests spill; capacity checks | PASS |
| SB-M25-017 committed +1 per accepted claim | `commit_work(slot, claim_id)` | run_tests acct; claim-model committed==1 | PASS |
| SB-M25-018 claim does not change remaining | never decremented on claim | run_tests "remaining unchanged"; claim-model | PASS |
| SB-M25-019 pre-spawn rollback seam | `rollback_claim` | run_tests rollback; rollback evidence | PASS |
| SB-M25-020 finalize resolves exact claim | `finalize_clear` -> `resolve_clear(claim_id)` | run_tests finalize; rollback evidence | PASS |
| SB-M25-021 no retarget to other target | claim target immutable in ledger; finalize by engine record | run_tests finalize wrong/stale fail | PASS |
| SB-M25-022 clear decrements remaining+committed once | `resolve_clear` via M24 | run_tests "remaining AND committed each -1" | PASS |
| SB-M25-023 fail closed on stale/double/invalid | `finalize_clear` guards | run_tests double/random finalize | PASS |
| SB-M25-024 reset releases all claims/reservations | `reset` | run_tests reset; rollback/scale evidence | PASS |
| SB-M25-025 no completion while committed | live claim => committed>0 | run_tests `_m25` guard check | PASS |
| SB-M25-026 WAITING on no claimable target | WAITING via `set_claimable_work_available(false)` | run_tests waiting; BLUE C | PASS |
| SB-M25-027 reevaluate after board change | `reconsider_color` (production targetability) | run_tests open; BLUE C post-opening | PASS |
| SB-M25-028 same-color race determinism | monotonic serialization | run_tests determinism; scale unique | PASS |
| SB-M25-029 BLUE 8/14/12 no shared pixel + oldest-first | BLUE fixture | `m25_blue_arbitration_evidence` | PASS |
| SB-M25-030 newly opened target assigned at opening | WAITING then reconsider | BLUE C pre/post opening | PASS |
| SB-M25-031 rectangular + 59x59 five slots duplicate colors | scale fixture | `m25_scale_evidence` (40x12, 59x59) | PASS |
| SB-M25-032 leak/reset/stale/deterministic regression | run_tests matrix | `_run_m25_batch_claim_tests` + evidence | PASS |

## 6. Validation commands / results / exits

Run from `C:\Users\sekip\Desktop\ScrubBots`.

| # | Command | Result | Exit |
|---|---------|--------|------|
| 1 | `godot --version` | `4.7.2.stable.official.ed1daf0bf` | 0 |
| 2 | `godot --headless --path . -s res://tests/run_tests.gd` | **Total checks: 5139, Failures: 0, RESULT: ALL PASS** | 0 |
| 3 | `... res://tests/m25_claim_model_evidence.gd` | PASS | 0 |
| 4 | `... res://tests/m25_blue_arbitration_evidence.gd` | PASS | 0 |
| 5 | `... res://tests/m25_rollback_finalize_reset_evidence.gd` | PASS | 0 |
| 6 | `... res://tests/m25_scale_evidence.gd` | PASS | 0 |
| 7 | `... res://tests/m24_v02_transaction_hardening_evidence.gd` | PASS | 0 |
| 8 | `... res://tests/m24_slot_state_evidence.gd` | PASS | 0 |
| 9 | `... res://tests/m24_supply_handoff_evidence.gd` | PASS | 0 |
| 10 | `... res://tests/m24_blue_fixture_evidence.gd` | PASS | 0 |
| 11 | `... res://tests/m24_five_full_refill_evidence.gd` | PASS | 0 |
| 12 | `... res://tests/m23_v03_transaction_identity_evidence.gd` | PASS | 0 |
| 13 | `... res://tests/m23_v02_hardening_evidence.gd` | PASS | 0 |
| 14 | `... res://tests/m23_v01_batch_supply_evidence.gd` | PASS | 0 |
| 15 | `... res://tests/m22_v06_real_demo_state_evidence.gd` | PASS | 0 |
| 16 | `... res://tests/m22_v05_final_state_evidence.gd` | PASS | 0 |
| 17 | `... res://tests/m22_v04_final_evidence.gd` | PASS | 0 |
| 18 | `... res://tests/m22_v03_connector_evidence.gd` | PASS | 0 |
| 19 | `... res://tests/m21_real_art_smoke.gd` | PASS (full 400-cell clear) | 0 |
| 20 | `... res://tests/m21_v10_final_reservation_evidence.gd` | PASS | 0 |
| 21 | `... res://tests/m20_queue_free_smoke.gd` | PASS | 0 |
| 22 | `... res://tests/m20_v10_lifecycle_smoke.gd` | PASS | 0 |
| 23 | `git diff --check` | clean (only informational LF→CRLF notices) | 0 |

M22 V07 interior-turn coverage runs inside the root suite (`_run_m22_v07_interior_turn_tests`).
Root-suite check count moved 5090 → 5139 (+49 M25 assertions).

## 7. Statements

- `root TASKS.md modified = NO`.
- `M26/M27 implementation = NO` (no automatic scheduler, no Scrubbot spawn/route handoff,
  no dispatch pacing loop, no solver/deadlock search). M25 provides only accounting seams
  (`rollback_claim`, `finalize_clear`, `reconsider_color`) for future M26 to drive.
- `image-generation credits spent = 0`.
- No protected authority modified; all M24/M23/M22/M21/M20 regressions green.
- No audit verdict authored. `AWAITING_AUDIT`.
