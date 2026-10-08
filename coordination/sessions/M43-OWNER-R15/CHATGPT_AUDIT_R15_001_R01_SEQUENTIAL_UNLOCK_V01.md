# SB-M43-R15-001-R01 — Sequential Unlock Strict Audit V01

Date: 2026-10-08
Repository: `Sekiph82/Scrubbots`
Audited implementation: `f4448d473d2c6bd62be3a83d31299eedea50b6ec`
Authorized base: `d5eead7d08aa3a05ad01e8553ef8a3a2c2a7312c`
Prompt: `coordination/sessions/M43-OWNER-R15/CHATGPT_PROMPT_R15_001_R01_SEQUENTIAL_UNLOCK_V01.md`
Criteria: `coordination/sessions/M43-OWNER-R15/CHATGPT_AUDIT_CRITERIA_R15_001_R01_SEQUENTIAL_UNLOCK_V01.md`
Builder log: `coordination/sessions/M43-OWNER-R15/SB-M43-R15-001-R01_CLAUDE_LOG_V01.md`

## VERDICT

**PASS / CLOSED — SB-M43-R15-001-R01 functional remediation.**

This closes only the owner-locked sequential-unlock functional remediation. The parent `SB-M43-R15-001` visual owner gate is not closed by this audit.

## Independent scope review

The implementation is exactly one commit ahead of the authorized base. The changed-file set is limited to:

- `scripts/economy/rewarded_daily_service.gd`
- `scripts/economy/rewarded_grant_service.gd`
- `scripts/ui/daily/rewarded_ads_screen.gd`
- `scripts/ui/ui_text.gd`
- `tests/m43_r15_001_r01_sequential_unlock.gd`
- `tests/m43_r15_owner_remediation.gd`
- the required Claude log

No root `TASKS.md`, Remote Content/R2 runtime/config/session file, Level Factory file, Home placement code, reward config, or unrelated M43 surface is changed by the implementation commit.

## Sequential authority

PASS.

Source inspection confirms:

1. `RewardedDailyService.current_slot()` derives the frontier from the canonical applied transaction ledger only.
2. A fresh day exposes Slot 1 only.
3. `is_sequence_locked()` makes every slot beyond the first ungranted slot non-actionable.
4. `RewardedDailyService.start_ad()` refuses a future slot before invoking the rewarded authority.
5. `RewardedGrantService.can_start_daily()` independently requires all prior deterministic `daily_rewarded:<day>:<slot>` transaction IDs, closing direct lower-service bypass.
6. Pending current-slot requests do not satisfy the durable prerequisite and therefore cannot expose later slots.
7. Only the existing verified-completed grant path mutates the canonical ledger; no-grant outcomes cannot advance the frontier.
8. Duplicate/late callbacks remain idempotent through the existing token closeout plus deterministic transaction identity.
9. Relaunch reconstructs position from durable grants; no second progress ledger or save section was added.
10. Forward-day reset and existing high-water rollback protection remain intact.

## Existing authority preservation

PASS.

- Exactly five reward slots remain.
- Reward bundles and `daily_rewarded:<day>:<slot>` identities are unchanged.
- Provider token remains distinct from the economy transaction ID.
- Production provider remains honestly unavailable until M57.
- Heart/booster rewarded paths remain on their existing `rewarded:<token>` authority.
- Daily login, Daily Scrub Orders, Gift Meter, Hearts, boosters and 2x are not modified.
- No Home badge was added.
- The accepted R15-004 Home CTA placement code is untouched.

The implementation also safely handles a legacy out-of-order ledger from the superseded parallel rule. Example `{1,4}` keeps Slot 4 claimed, resumes at Slot 2, then Slot 3, then Slot 5; Slot 4 is never re-granted.

## UI boundary

PASS.

The popup keeps the same five-row layout and reward visibility. Future rows are rendered as disabled `LOCKED` with a small code-rendered ordering message. No art or geometry redesign is introduced.

The permanent UI test verifies:
- five rows remain;
- future buttons are disabled;
- locked-row presses produce zero provider requests;
- after Slot 1 claim, only Slot 2 becomes actionable;
- Home CTA placement and absence of a Rewarded Ads Home badge remain unchanged.

## Test evidence

Builder-reported evidence is internally consistent with the inspected permanent tests:

- focused sequential suite: **14/14 PASS, 68 assertions, 0 fail**
- existing R15 suite updated to the owner rule: **18/18 PASS, 115 assertions**
- root suite: **5329/5329 PASS**
- M39 Daily / full matrix: PASS
- M40 save regressions: PASS
- M41 Settings: PASS
- M43 acquisition: **34/34 PASS**
- M43 Need a Hand: **40/40 PASS**
- M43 Daily/Tasks/Gift: **12/12 PASS**
- M43 meta badges: **12/12 PASS**
- M43 C011-C014: **28/28 PASS**
- M43 popup/modal: **23/23 PASS**
- M42 Home: PASS
- `git diff --check`: clean
- no unexplained script errors reported

This audit independently inspected source, changed-file scope, and permanent test logic. The audit environment did not independently execute Godot; runtime counts above are builder evidence supported by the committed test source.

## Governance

PASS.

Owner-local sync evidence records a non-destructive fast-forward to the authorized base while preserving owner-local modifications. Root `TASKS.md` remained read-only to Claude. Remote Content/R2 files were excluded and remained unchanged.

## Final disposition

**SB-M43-R15-001-R01 = PASS / CLOSED.**

The owner-locked sequential behavior is now:

`Slot 1 CLAIM -> Slot 2 WATCH AD -> verified grant -> Slot 3 -> Slot 4 -> Slot 5`.

No-grant outcomes do not advance. Future slots cannot start early.

**Parent `SB-M43-R15-001` remains OPEN only for owner visual acceptance of the Rewarded Ads surface, including the newly visible LOCKED-row presentation.**
