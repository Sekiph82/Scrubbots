# Review round 1 (single reviewer, strict economy lock)

Tests (Godot 4.7.2 headless, after --import): m56 PASS 21/21, m39_v02_atomicity PASS, m54_regression_pack_022_027 PASS 12/12, m58 PASS 7/7. git diff --check clean. The worktree import churn (.import files) was left untouched; project.godot restored.

## Economy verification
- EconomyWallet.credit/debit: the `tag` arg defaults to "", so existing callers are unchanged. The emit comes after the balance mutation and only when amount > 0. Return values, rejection paths (negative, unknown resource, insufficient) and ordering are unchanged. Snapshot format is unchanged (signal not serialized). import_snapshot sets _balances directly and emits nothing, so rollbacks (pack commit, boot, ack) emit no events.
- RewardGrantService.granted(tx_id) is emitted after _applied is recorded, at the end of the successful path only. Return value is unchanged.
- Handlers in AppState are GDScript signal callbacks that only call analytics.track (write-only, consent-gated); they cannot alter wallet state or abort the wallet call.
- ProductionActionFacade.unlock_robot only adds a `robot_id` key to the result dict. Existing callers/tests read ok/reason/remaining_parts and are unaffected (m39_v04, m40_v04, m54 pass).
- _zero_heart_gate has 3 callers, all updated; the 2nd arg is required, no stale caller.
- Privacy: params are int/bool/enum or buckets. Ad product ids use the product name with ":" replaced; the token is never passed. Consent default OFF, NullSink, no network. Privacy inventory and the taxonomy doc list every new event; the m58 guard is green. CI guard 21/21 matches the printed summary.

## Findings (must-fix)
None.

## Notes (non-blocking)
- Events fire when the wallet / grant happens, not when the surrounding save commits. If a save fails and the caller rolls back via import_snapshot (pack commit "save" stage, boot/ack save failure), an economy_source / collection_set_complete event already emitted would be emitted again on the retry (analytics overcount on save-failure only; no gameplay or balance effect). Acceptable for coarse KPIs; worth one doc line in ANALYTICS_TAXONOMY_V1.md.
- robot_unlock event relies on action_committed (ok only), fine.

VERDICT: PASS
