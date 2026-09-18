# M25-C001 V02 — STRICT REMEDIATION PROMPT

Repository: `Sekiph82/Scrubbots`
Branch: `main`
Milestone: M25 Batch Target Claim Engine
Execution mode: ONE CONTINUOUS REMEDIATION PASS

Read first:
1. `coordination/sessions/M25-C001/CHATGPT_AUDIT_V01.md`
2. `coordination/sessions/M25-C001/CHATGPT_AUDIT_CRITERIA_V02.md`
3. `coordination/sessions/M25-C001/CHATGPT_MASTER_AUDIT_CRITERIA_V01.md`
4. `coordination/OWNER_BATCH_GAMEPLAY_CORE_DECISION_V01.md`

Objective: close ALL `F-M25-V01-STRICT-001..005` in one pass. Do not split into work-package handoffs.

Required corrections:

1. Make claim/work identities stale-safe across reset. Never recycle a public claim id so a pre-reset stale handle can act on a post-reset claim.
2. Allocate ReservationState owner identities without colliding/stalling on unrelated live owners, including an unrelated owner 0 in a fresh session.
3. On post-reservation M24 commit failure, restore the selected batch's exact lifecycle prestate as well as reservation/ledger/accounting state.
4. Make `rollback_claim` transactionally safe. Never erase ledger truth or report success after a failed canonical cleanup half.
5. Make `reset` transactionally safe across multiple claims. Never silently clear ledger if a claim cannot be coherently cleaned.
6. Tighten claim access input to canonical/coherent production targetability. Reject generic method-compatible/all-true RefCounted and foreign-board ProductionTargetAccess.
7. Make M25 binding session-stable. A second coherent bind must not migrate a live engine to another bundle.
8. Preserve all accepted M25 behavior: same-color FIFO, BLUE 8/14/12, capacity spill, opening-time claim, TargetSelector order, one target/one reservation/claim, remaining unchanged on claim, authenticated finalization.
9. Preserve M24/M23/M22/M21/M20 regressions.
10. Do not implement M26 or M27. Do not modify root TASKS.md. Zero image credits.

A minimal read-only compatibility seam in accepted M24 or ProductionTargetAccess is allowed only if strictly necessary to prove exact work/access coherence. Keep any such seam tiny, non-policy-changing, explicitly justify it, and fully regress the protected subsystem.

Required adversarial proofs include:
- stale pre-reset claim id cannot mutate new post-reset claim;
- unrelated ReservationState owner 0 does not stall M25;
- WAITING -> target opens -> forced M24 commit failure -> exact WAITING prestate restored;
- rollback with reservation drift fails safely;
- rollback with M24 work drift fails safely;
- reset with one incoherent tuple does not falsely report clean success;
- generic all-true access rejected;
- foreign-board ProductionTargetAccess rejected;
- live-claim rebind attempt rejected while original bundle remains usable.

Run all criteria in `CHATGPT_AUDIT_CRITERIA_V02.md`.

Push implementation first, then `CLAUDE_LOG_V02.md` separately.

Return only AWAITING_AUDIT, final implementation SHA, and direct GitHub log URL.
