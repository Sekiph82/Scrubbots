# M44 D2 — CLAUDE_PEER_REVIEW V02 (final, post-fix, with real CI)

**Label: `CLAUDE_PEER_REVIEW`** (autonomous V02). Not a `CHATGPT_INDEPENDENT_AUDIT`.

- Reviewer: a NEW fresh-context Claude subagent, distinct from the V01 reviewer. Read-only; no Godot; CI read in memory via `gh api`.
- Reviewed: final D2 source at the tested SHA `912a69db`. The reviewer verified that `git diff 0218a862 912a69db` touches only CLAUDE.md / TASKS.md / coordination docs.
- The findings below are condensed from the reviewer's report; builder notes are marked **[builder]**.

## Verdict (reviewer): PASS_WITH_CONCERNS
The final source meets the owner D2 contract, D1–D4 are fixed, D5 is accepted, and CI is green with t22 / t23 actually executed. The remaining items are LOW / INFO.

## Previous defects (V01)
| # | Status | Evidence (reviewer) |
|---|---|---|
| D1 HIGH | FIXED | `_later_raw()` parses the raw JSON and `_later_cfg()` = `FtueConfig.validate(raw)`. The bad case asserts reason `whats_new`. Log: "simulated later-build config passes the strict reader". |
| D2 MED | FIXED | `_snoozed` is session-only; the due list filters it; a failed ack restores the ledger and snoozes. `p.closed` is connected before the push, so the snooze is set before `modal_changed(false)`, and the drain is deferred: no loop. Log: "snoozed for this session only (no re-open loop); due again for a new session". |
| D3 LOW | FIXED | `whats_new_keys` removed. |
| D4 LOW | FIXED | `use_config` refuses a cfg that is not `ok`; only tests call it. |
| D5 INFO | ACCEPTED | Pre-D2 "new" saves have no baseline; no M44 APK ever shipped. |

## Per-item (reviewer)
1. Owner rules: PASS.
   - Nothing shows during L1–L3, and Skip Tips does not unlock it; only `settle()` closes the window after genuine L3.
   - The baseline is inside the bootstrap rollback transaction.
   - Established profiles are unchanged; no economy mutation (t22 / t23 `_econ_core`); no phantom feature.
2. Failed-ack path: PASS.
   - No loop, and the snooze is never persisted.
3. Regression: PASS.
   - t01–t21 and all 35 suites PASS.
4. Remaining issues:
   - LOW: stale comment at `main.gd:600`. **[builder]** Reworded in the M49 change set (validated by the next CI run).
   - LOW: the t23 onboarding / relaunch checks only asserted "top popup is not the feature ceremony". **[builder]** Strengthened to also assert `whats_new_due().is_empty()` (validated by the next CI run).
   - INFO: a snooze lasts the rest of the session (by design).
   - INFO: `settle()` closes in memory before its save result (pre-existing, self-healing on the next boot).

## CI evidence (reviewer, run [38742572367](https://github.com/Sekiph82/Scrubbots/actions/runs/38742572367))
- head `912a69db599d717894c18032e40503ee4ef4b6c8`; validate = success, export = skipped.
- Artifact 37 files, logs only (no .apk / .pck / .ipa / .aab).
- `mode=validation_only`, `import script_diag=0`, 35/35 suites PASS, `CP06 PASS (16/16)`, `M44 PASS (23/23)`, `M45 PASS (8/8)`, `aggregate=PASS`.
- `m44_ftue.log`: 173 ok lines, 0 FAIL; t22 15 ok, t23 5 ok.

## NOT_RUN
- On-device / owner visual check of the ceremony after L3 (M44-018 / 020).
- Persistent save failure on a real device.
- A real later build with a new What's New entry (simulated only).

## Disposition
`SB-M44-D2-001`: implemented, CI 23/23 green on the tested SHA, and the final Claude peer review is PASS_WITH_CONCERNS (LOW items addressed). Eligible for technical closure by the tracker owner. Owner visual gates unchanged.
