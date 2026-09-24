# Lower-layer seams touched by M39 V04

Status: IMPLEMENTED (AWAITING_AUDIT)
V03 audit: coordination/sessions/M39-C001/CHATGPT_AUDIT_V03.md (frozen F-M39-V03-001..005)
V04 prompt/criteria: coordination/sessions/M39-C001/CHATGPT_PROMPT_V04.md / CHATGPT_AUDIT_CRITERIA_V04.md

All are additive; no accepted M19/M23/M24/M25/M26 behavior changed. Regression: M23..M30 suites green (CLAUDE_LOG_V04.md).

- **M19 dispatcher**: `ScrubbotDispatcher.can_cancel_owner/cancel_owner`: exact (owner, agent) not-arrived cancel; no reservation mutation, no generation bump, no other owner touched.
- **M23 supply**: `BatchSupplyEngine.replace_live_columns`: validated live-queue replacement that preserves the Retry/reset baseline; refused while a selection transaction is open.
- **M24 slots**: `FiveSlotBatchEngine.rollback_grow_to_sixth` (EMPTY uncommitted sixth slot only) and `purge_uncommitted_slot/restore_purged_slot` (no committed/live work bound).
- **M25 claims**: `BatchTargetClaimEngine.restore_claim(rec)`: exact companion of rollback_claim; preflight ACTIVE/unreserved/same batch/capacity, reserve + commit_work, ledger re-insert; commit failure releases the reservation.
- **M26 scheduler**: `AutoDispatchScheduler.color_assignment_owners/preflight_color_cancel/detach_assignment/reattach_assignment/get_dispatcher_can_cancel/finalize_detached`.
