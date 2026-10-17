# M46 R07 — CLAUDE_PEER_REVIEW V01

**Reviewer:** a distinct fresh-context Claude subagent, run 2026-10-17. Read-only: no edits, no Godot / test runs. It saw only the repository, the R07 prompt and the uncommitted diff on base `5493eb1a`.

**Not a ChatGPT independent audit.** It is not owner acceptance either.

**Verdict: PASS_WITH_MINORS.** No BLOCKER, no MAJOR.

## Confirmed by the reviewer
1. **Rewarded economics:**
   - `RewardedGrantService` is unchanged, so the grant commits exactly once before `_apply_reward_outcome`.
   - No SB spend, refund or new ad request.
   - `auto_use` is armed only when the reason is `checking` and the booster has no target. It is consumed once, and lives in that popup's context only.
   - On refusal, timeout, close or scene exit, the granted charge is kept.
   - A late result for a closed popup changes no UI.
   - It cannot collide with the R06 HUD-hold `auto_use`: the HUD hold applies only to owned charges, rewarded only to zero charges.
2. **FTUE:**
   - No new strings; on `checking` the suffix is simply omitted.
   - Scripted steps, Skip Tips and quiet Home are untouched.
   - The coach runs only with no modal, in gameplay and while not terminal.
   - One job at a time.
   - The `main.gd` signal connection is lifetime-safe.
3. **Neither flow keeps a main-thread full proof.** The reviewer listed the other synchronous callers that remain; all are accepted or out of scope:
   - the R05 fallback when `detached_copy()` is null;
   - `booster_model` without `leg` (no production caller);
   - harness hosts without the R06 method;
   - execute paths after a proof (cache hits);
   - Need-a-Hand (owner-reserved, unbudgeted);
   - the in-flight shortcut.
4. The `offframe_budget_ms` seam keeps the production default of 5,000 ms; only tests lower it.

## Findings and disposition
| # | Severity | Finding | Disposition |
| --- | --- | --- | --- |
| 1 | MINOR | `_exit_tree` → cancel → settle → coach refresh could start a new, never-joined worker on the exiting host | **Fixed.** `_proof_closed` is set first in `_exit_tree` (reset in `_enter_tree`); `needs_offframe_proof` is false and `booster_legality_offframe` returns a cheap `exiting` refusal while closed, so there is no worker and no synchronous proof. Tested with FTUE active and in the rewarded scene-exit case (`live_proof_count` unchanged, nothing running after the settle). |
| 2 | MINOR | The coach restarts proofs during unpaused play while the L2 tip shows | **Accepted** as the reviewer allowed: one worker at a time, the 5 s cap, no main-thread cost. Recorded in the log. |
| 3 | MINOR | The stale assertion (`_verdict_key != key0`) was not decisive | **Fixed.** The test now checks at every settle that no Random verdict was stored under the old key. |
| 4 | MINOR | Scene-exit test did not prove cancel/join; no FTUE-active variant | **Fixed.** Both exit cases assert a settle happened, nothing is running after it, and the adapter's `live_proof_count` is unchanged. |
| 5 | MINOR | Spec gaps: immediate-execute branch, rewarded on a cached timeout, Selector rewarded, no FTUE job while a modal is open | **Fixed.** Each is a new case in `tests/m46_r07_ui_legality.gd`. A terminal-state FTUE job is not reachable (`_coach_want` returns `{}` at terminal) and is not tested. |
| 6 | MINOR | The deferred R06 auto-use did not re-check its popup | **Fixed.** `_auto_use(p)` runs only if the popup is valid, open, on top and not busy. |
| N1 | NIT | "Booster saved!" shows next to "Checking..." just before the auto-use closes the popup | **Kept.** Both are existing strings, and the owner F5 gate covers wording. |
| N2 | NIT | The test instantiates `main.tscn`, which carries uncommitted owner edits | **Noted** in the log; owner files are not touched. |
