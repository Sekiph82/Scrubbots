# M43 — MASTER TARGETED REMEDIATION V03

Status: **READY FOR CLAUDE**
Date: 2026-10-06
Repository: `Sekiph82/Scrubbots`
Local checkout: `C:\Users\sekip\Desktop\ScrubBots`
Branch: `main`
Canonical tracker: root `TASKS.md` — READ ONLY for Claude

Authority:
- `coordination/sessions/M43-MASTER-V01/CHATGPT_MASTER_AUDIT_V01.md`
- previous master log `M43_MASTER_CLAUDE_LOG_V01.md`

Do **not** rerun or redesign the whole M43 milestone.

This is one targeted remediation pass for the six technical failures and four child-status corrections found by the independent audit.

## 0. FIRST ACTION

1. Work only from `C:\Users\sekip\Desktop\ScrubBots`.
2. `git fetch origin main --prune`.
3. Synchronize non-destructively with latest `origin/main`.
4. Preserve owner-local `project.godot`, `scenes/app/main.tscn`, addons, review-scene metadata, unrelated untracked files and owner candidates.
5. Never reset/clean/overwrite owner work.
6. Root `TASKS.md` remains READ ONLY.

Read:
- `CLAUDE.md`
- coordination README/AUDIT_POLICY
- `CHATGPT_MASTER_AUDIT_V01.md`
- the affected child logs
- actual current source/tests before editing.

## 1. SB-M43-155 — FIX CLOUD CONFLICT SAFETY

Current resolver incorrectly equates two saves when reward-tx sets + completed-level sets match even if other authoritative economy state differs, and it ignores `revision` / `saved_at`.

### Required behavior

A cloud copy is a WHOLE save. Never field-merge currency/rewards.

Validate both local and remote envelopes/payloads before comparison.

Required rules:

1. **Exact canonical payload equality**
   - only then may reason be `equal`.

2. **Safe ancestor/descendant**
   - one side may auto-win only when:
     - progression completed-set is a superset;
     - authoritative transaction-id history is a superset;
     - revision/timestamp ordering is coherent with that direction;
     - no contradictory authority evidence proves divergence.
   - choose the whole winning payload.

3. **Same progression/tx history but different economy**
   - must be `conflict`, not `equal`.

4. **Diverged histories**
   - `conflict`.

5. **Malformed/future remote**
   - fail closed as invalid remote.

Do not assume higher wallet/currency means newer, because legitimate spending can lower balances.

Use a deterministic canonical comparison/fingerprint for persisted authority sections where appropriate. Do not compare transient UI metadata as economy truth.

### Mandatory new tests

At minimum:
- exact payload equality -> equal;
- local strict descendant -> keep_local;
- remote strict descendant -> take_remote;
- same tx/progression but different wallet -> conflict;
- same tx/progression but different Collection -> conflict;
- same tx/progression but different robot/booster/Daily state -> conflict;
- stale/newer revision/timestamp contradictions -> conflict;
- malformed remote rejected;
- no currency/reward field merge.

Amend:
`coordination/sessions/M43-MASTER-V01/logs/SB-M43-155_CLAUDE_LOG_V01.md`
with a clearly marked remediation section and new SHA/results.

## 2. SB-M43-R12-005 + R12-007 — CLOCK-ROLLBACK-SAFE NOTIFICATION CAP

Current cap allows a second proactive message when `now_ts < last_sent`.

### Required behavior

- If current time is behind the persisted last-sent/high-water point, proactive notification must be suppressed.
- Do not reset or forgive the cap on clock rollback.
- Once time safely catches up beyond the cap window, eligibility resumes.
- Reload under rollback must preserve suppression.

Add tests:
- send at T;
- decide at T-1h -> none;
- reload at T-1h -> none;
- decide at T+23h -> none;
- decide at T+24h -> eligible;
- normal quiet-hours/category/priority behavior still passes.

Extend the R12-007 test matrix to explicitly include this case.

Amend both child logs.

## 3. SB-M43-161 / 162 / 167 — COMPLETE META AUDIO / HAPTIC FAMILY

Do not add a noisy per-screen asset zoo. Reuse existing approved SFX where reasonable.

### SB-M43-161 required family

The production family must have actual shipping seams for:
- button confirm;
- button/back;
- popup open;
- popup close;
- committed reward reveal;
- pack reveal;
- robot unlock;
- error/warning.

Do not make purchase/ad failure sound like success.

Use one compact coordinator and avoid double-firing with existing feedback systems.

### SB-M43-162 haptics

Define and bind distinct semantic moments for:
- success;
- warning;
- pack Rare-or-better reveal;
- unlock.

Respect:
- Haptics OFF;
- Reduced Effects;
- live settings changes.

Fix current ceremony-kind mapping. Real emitted kinds include:
- `set_complete`
- `master_complete`
- `robot_unlock`
- `gift_milestone`

Do not test against invented short aliases.

Pack Rare integration must use the committed Standard/Premium presentation truth. It may fire once for the first Rare-or-better reveal or another deterministic bounded rule, but must not reroll/reorder/alter pack contents.

### SB-M43-167 fatigue

Replace the standalone “20 reward moments” proof with real representative UI loops:
- repeated popup open/close;
- repeated back/confirm;
- repeated claim attempts;
- pack reveal;
- robot/meta unlock.

Prove:
- no stacked voices;
- no duplicate haptics from refresh/reopen;
- rate limits do not suppress a genuinely different later action forever;
- no orphan audio/haptic work after popup close/route change;
- Reduced Effects + Haptics OFF remain quiet where required.

Update all three child logs.

## 4. CHILD-STATUS CORRECTIONS — NO FABRICATED AUTHORITY

These are log/master-status corrections, not permission to invent values.

### SB-M43-R10-004

Change from READY to:

`BLOCKED_AWAITING_AUTHORITY`

Reason:
- shipping `first_try_cleanup` is null;
- fixed/visible reward is not owner-authorized.

Keep the reusable mechanism/tests.
Do not invent the reward.

### SB-M43-151

Change from READY to:

`DEFERRED_DEPENDENCY`

Full child completion depends on SB-M43-146 platform notification authority for real disabled-permission testing.

Keep current policy tests and additionally add a policy-level timezone test:
- same UTC timestamp;
- different injected local hour/timezone context;
- quiet-hours outcome changes correctly without corrupting 24h cap.

### SB-M43-165

Change from READY to:

`DEFERRED_DEPENDENCY`

Reason:
- cloud and RANKS UI/retry surfaces do not yet exist due SB-M43-153 / SB-M43-131 authority gaps.

Do not fake retry screens.

### SB-M43-166

Change from READY to:

`DEFERRED_DEPENDENCY`

Reason:
- no-rankings-result empty state requires the RANKS destination/policy.

Do not fabricate ranking data.

Update the four child logs and the final master status table accordingly.

## 5. DO NOT TOUCH ACCEPTED / UNRELATED WORK

Do not redesign:
- C005 ceremonies;
- Shop;
- Collection;
- Robots;
- Tasks/Daily/Gift;
- Profile/Achievements/Events;
- World framework;
- C008 pack commit;
- Standard/Premium pack visuals;
- prior owner-approved pack/card state surfaces.

Do not canonicalize plugins in this pass.
Do not decide M44/M56/M57/M58/world/ranks/provider/owner gates.

## 6. TEST / REGRESSION

Run at minimum:

- updated C011–C014 master suite;
- cloud conflict focused cases;
- notification rollback cases;
- meta feedback family/fatigue cases;
- relevant C005 pack presentation suites if pack reveal hook changes;
- Standard/Premium owner-review harness smoke if pack ceremony source changes;
- M39/M40 save/economy regressions;
- M43 master affected lanes;
- root `tests/run_tests.gd`;
- `git diff --check`.

No unexplained runtime/script errors.

## 7. FINAL REMEDIATION HANDOFF

Create:

`coordination/sessions/M43-MASTER-V01/M43_MASTER_REMEDIATION_CLAUDE_LOG_V03.md`

Report:
- baseline/final SHA;
- exact production files changed;
- SB-M43-155 conflict matrix;
- notification rollback proof;
- complete audio/haptic mapping table;
- pack Rare + unlock mapping proof;
- fatigue loop results;
- four corrected child statuses;
- focused/regression/root results.

Do not edit root TASKS.md.

Finish exactly:

`AWAITING_GPT_M43_MASTER_REMEDIATION_V03_AUDIT`
