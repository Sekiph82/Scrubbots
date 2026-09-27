# SB-M55-C001 — CHATGPT AUDIT CRITERIA

## Scope

Audit SB-M55-001..017 only plus reconciliation of active Heart interval references to the owner-locked 900-second ruling.

SB-M55-018..024 are out of scope.

## Heart authority

PASS requires:
- active runtime authority remains 900 s;
- active planning config/docs no longer claim Heart regen is 30 min/1800 s;
- historical owner files may retain old values only as superseded provenance;
- 30-minute 2x product remains unchanged;
- focused regression prevents Heart interval authority drift.

## Chaos evidence

Each applicable SB-M55-001..017 row needs direct production-path evidence.

PASS requires:
- no double spend/grant/use under input spam;
- restart/pause/background/in-flight transitions preserve ownership/reservations/claims;
- no duplicate signals or orphan-node accumulation;
- bounded memory behavior with measurable before/after evidence;
- repeated scene transitions do not accumulate authority objects/listeners;
- Heart background/foreground behavior uses 900-second wall-clock truth;
- timed 2x expiry remains independent;
- Tornado reconciliation is atomic with in-flight same-color work;
- Cards Exchange-all remains exactly-once under repeated input.

## Regression integrity

Required focused and root suites must reject false-green output:
- nonzero exit;
- FAIL;
- SCRIPT ERROR;
- new unexplained runtime ERROR.

No First 10 content/difficulty/owner-plan mutation.

## Verdict

If all current-build rows pass:
`AUDITED_PASS / M55-C001 / CORE CHAOS CLOSED`

If defects remain:
`CHANGES_REQUIRED / M55-C001 / <exact task IDs>`

If an owner decision is genuinely required:
`OWNER_REQUIRED / M55-C001 / <exact decision>`
