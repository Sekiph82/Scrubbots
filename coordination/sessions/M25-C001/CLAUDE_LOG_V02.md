# M25-C001 V02 — Claude Implementation Log

Date: 2026-09-18
Repository: `Sekiph82/Scrubbots`
Branch: `main`
Milestone: `M25 — Batch Target Claim Engine`
Cycle: `M25-C001 V02` (ONE continuous strict remediation pass)
Actor: Claude
Auditor: ChatGPT (independent)

Prompt: `coordination/sessions/M25-C001/CHATGPT_PROMPT_V02.md`
Criteria: `coordination/sessions/M25-C001/CHATGPT_AUDIT_CRITERIA_V02.md`
Prior audit: `coordination/sessions/M25-C001/CHATGPT_AUDIT_V01.md`

## Governance / sync

- Safe-sync start SHA (local HEAD before work): `7dd0061` — fast-forwarded to `origin/main` `f02a91a` (docs-only: V02 prompt/criteria/audit + tracker). No conflict; only `project.godot` (owner Godot-editor churn) and untracked owner `.uid`/`.import` artifacts were present locally and were preserved untouched.
- Root `TASKS.md` modified = **NO**.
- M26/M27 implementation = **NO**.
- Image-generation credits spent = **0**.
- Owner-local work preserved: `project.godot` and all untracked `.uid`/`.import`/reference assets left unstaged.

## Scope of change

Implementation touches exactly the M25 engine plus two minimal, read-only, non-policy seams and the M25 test surface:

- `scripts/gameplay/targeting/batch_target_claim_engine.gd` — all five findings.
- `scripts/gameplay/slots/five_slot_batch_engine.gd` — one read-only seam `is_work_coherent()`.
- `scripts/gameplay/dispatch/production_target_access.gd` — one read-only seam `is_bound_to_board()`.
- `tests/support/m25_reentrant_access.gd` — re-entry double promoted to a category-correct `ProductionTargetAccess` subclass (no weakening of the production trust boundary).
- `tests/run_tests.gd` — construct that re-entry double via the real routing bundle + exact board.
- `tests/m25_v02_strict_remediation_evidence.gd` — new dedicated adversarial evidence (all nine required proofs).

### Justification for the two seams (both read-only, non-mutating, policy-neutral)

- `FiveSlotBatchEngine.is_work_coherent(work_id)`: returns the SAME coherence `resolve_clear()`/`rollback_work()` already enforce (live work id whose recorded slot still holds the exact same occupied batch). Strictly necessary so M25 can **preflight** all-or-nothing rollback/teardown before any destructive half-mutation. Adds no target/route/robot authority. Protected M24 subsystem fully regressed.
- `ProductionTargetAccess.is_bound_to_board(board)`: reference-identity board check so the M25 claim path can reject a foreign-board access adapter without learning routing internals. Never exposes references; adds no reachability policy. Protected M19/M22 subsystems fully regressed.

## Finding → code → proof

### F-M25-V01-STRICT-001 — stale identity reuse + owner-id collision/stall

Code (`batch_target_claim_engine.gd`):
- Identity counters `_next_owner`/`_next_claim` are now **monotonic for the engine lifetime**; `reset()` no longer rewinds them, so a public claim id / owner id is never recycled — a stale pre-reset handle can never alias a post-reset claim.
- Owner minting skips any owner id already live in the shared `ReservationState` (`while _reservations.get_target_for_owner(_next_owner) != -1: _next_owner += 1`) WITHOUT stealing/releasing it, so an unrelated live owner (including owner 0 in a fresh session) cannot stall a valid claim.

Proof (`m25_v02_strict_remediation_evidence.gd::_identity_non_reuse`, `_owner_zero_no_stall`):
- post-reset claim id/owner id NOT recycled; stale id cannot roll back/finalize; claim B untouched.
- unrelated owner 0 pre-reserved → valid claim still succeeds with a different unused owner; the owner-0 reservation survives unchanged.

### F-M25-V01-STRICT-002 — failed M24 commit lifecycle rollback

Code: snapshot `prestate = get_state(slot)` BEFORE the ACTIVE confirmation; on `commit_work` failure release the exact new reservation AND restore the prestate (WAITING→WAITING, ACTIVE stays ACTIVE). No identity counter advanced, so no stale alias is minted.

Proof (`_commit_failure_waiting_restore`): WAITING → target opened → forced commit failure → exact WAITING restored; remaining/committed unchanged; reservation released; no ledger entry.

### F-M25-V01-STRICT-003 — transaction-safe `rollback_claim`

Code: preflight EXACT tuple coherence read-only BEFORE any mutation — reservation pair (`get_owner`/`get_target_for_owner`) must match the claim, and `is_work_coherent(claim_id)` must hold. Any drift fails closed with ledger + both canonical halves untouched. Only after both halves are proven exact do the two mutations run (synchronous path, no interleaving).

Proof (`_rollback_reservation_drift`, `_rollback_m24_work_drift`, `_rollback_healthy_still_works`): reservation-absent, foreign-owner, and M24-work-stale drifts each fail closed with no half-cleanup; healthy rollback still exact (committed−1, remaining unchanged, exact release, ledger erased).

### F-M25-V01-STRICT-003/004 — transaction-safe `reset`

Code: two-phase — Phase 1 preflights EVERY live tuple read-only; if any is incoherent, abort with zero mutation (ledger not cleared, failure reported). Phase 2 (only when all coherent) cleans each exact tuple. Teardown order documented: M25 claim cleanup before any M24 reset. Only exact pairs released, so unrelated owners survive.

Proof (`_reset_incoherent_tuple`, `_reset_multiple_healthy`): one incoherent tuple → `reset()` returns false, ledger intact, no M24 mutation, healthy tuple + foreign owner untouched; multiple healthy claims all clean and unrelated owner survives.

### F-M25-V01-STRICT-004 — strict production access category/coherence

Code: `claim_for_color` now requires `access is ProductionTargetAccess` AND `access.is_bound_to_board(_board)`. Generic all-true RefCounted, null/missing, and foreign-board access are rejected before any reservation/M24 mutation. Re-entry coverage retained via a category-correct `ProductionTargetAccess` subclass.

Proof (`_access_category_strictness` + fixed `run_tests.gd::_m25_reentrancy`): generic all-true rejected; null/missing rejected; foreign-board rejected; no reservation/M24/ledger mutation on rejection; real coherent access accepted; nested re-entry still rejected `reentrant` through the strict boundary.

### F-M25-V01-STRICT-005 — session-stable binding

Code: `bind()` is initialization-only — once bound, any further bind (even coherent same-bundle) fails closed and preserves the exact original bundle; no rebind migrates authorities while live claims exist.

Proof (`_session_stable_binding`): second same-bundle bind rejected; foreign-bundle bind rejected while a live claim exists; original live claim remains rollback-capable against the original bundle.

## Preserved accepted M25 behavior + regressions

All accepted V01 behavior preserved (same-color FIFO, BLUE 8/14/12 distinct, capacity spill, opening-time claim, TargetSelector bottom-most→left-most, one target/one reservation/one claim, remaining unchanged on claim, authenticated finalization). Confirmed green:

- `m25_claim_model_evidence` PASS
- `m25_blue_arbitration_evidence` PASS
- `m25_scale_evidence` PASS (rectangular + 59×59)
- `m25_rollback_finalize_reset_evidence` PASS
- `m25_v02_strict_remediation_evidence` PASS (new)

M24/M23/M22/M21/M20 regression evidence green:

- `m24_v02_transaction_hardening_evidence`, `m24_supply_handoff_evidence`, `m24_blue_fixture_evidence` PASS
- `m23_v01/v02/v03` PASS
- `m22_v06_real_demo_state_evidence`, `m22_responsive_smoke` PASS
- `m21_real_art_smoke`, `m21_v10_final_reservation_evidence` PASS
- `m20_v10_lifecycle_smoke` PASS

## Validation

- `godot --version` → `4.7.2.stable.official.ed1daf0bf`
- Full `tests/run_tests.gd` → **Total checks: 5139, Failures: 0, RESULT: ALL PASS**, exit code 0.
- `git diff --check` → clean (only informational LF→CRLF notices; no whitespace errors).

## Handoff

Implementation pushed first; this log pushed as a separate final commit.

- root `TASKS.md` modified = NO
- M26/M27 implementation = NO
- image-generation credits spent = 0

AWAITING_AUDIT
