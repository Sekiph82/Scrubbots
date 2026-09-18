# M26-C001 V02 — Narrow Transaction & Coherence Remediation

Repository: `Sekiph82/Scrubbots`
Branch: `main`
Execution mode: ONE CONTINUOUS REMEDIATION PASS

Read:
1. `coordination/sessions/M26-C001/CHATGPT_AUDIT_V01.md`
2. `coordination/sessions/M26-C001/CHATGPT_AUDIT_CRITERIA_V02.md`
3. existing M26 master prompt/criteria.

Close ALL four V01 findings in one run.

Required corrections:

1. Scheduler reset during active step must be deferred/generation-safe, never silently dropped. A reset injected before spawn must make the outer step abort/rollback and produce zero robot.
2. Scheduler reset must not ignore failed M25 rollback. If any exact claim cleanup is incoherent, fail closed before M20/dispatcher teardown and before clearing scheduler ledger.
3. Authenticated-clear handling must keep owner->claim mapping until M25.finalize_clear succeeds. Match exact agent identity too. On finalize failure retain the mapping and do not wake/continue as if successful.
4. Scheduler bind must prove exact same M24/M25/M20 board/reservation/dispatcher bundle using minimal read-only coherence seams.

Preserve all accepted M26 V01 behavior:
- M25 remains claim authority;
- preclaimed dispatcher does not select/reserve;
- no target/claim/route => no robot;
- no retarget;
- one accepted assignment per step;
- BLUE8/14/12 and cross-color fairness;
- WAITING/wake;
- BLUE15 exact 15 clears;
- real Hazard Bot slot-anchor/Railroad integration;
- 59x59 sanity;
- all legacy M19/M20 behavior.

Do NOT modify root TASKS.md.
Do NOT implement M27.
Do NOT implement final M28 UI.
Zero image credits.

Push implementation first, then create:
`coordination/sessions/M26-C001/CLAUDE_LOG_V02.md`
as a separate final commit.

Return only AWAITING_AUDIT, final implementation SHA, and direct log URL.
