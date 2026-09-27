# SB-M55-C002 — CHATGPT AUDIT CRITERIA

## Owner authority

Canonical ruling:
`coordination/OWNER_TIMED_2X_CLOCK_ROLLBACK_V01.md`

Timed 2x must fail closed against backwards wall-clock movement.

## PASS requirements

### 1. Monotonic entitlement

Absent a new purchase:
- remaining timed-2x seconds never increase;
- expired entitlement never revives;
- backwards clock movement cannot restore entitlement truth.

### 2. Persistence

Anti-rollback state survives save/relaunch/background/foreground.

### 3. Legacy migration

A legacy snapshot without the new guard:
- remains importable;
- does not lose a legitimate currently-active timed entitlement merely due to schema evolution;
- initializes the new guard at the upgrade boundary;
- is protected against subsequent rollback.

Malformed present guard values fail closed.

### 4. Purchase behavior

A real new timed purchase may extend entitlement and charges exactly once.

Canonical products remain:
- 900 s / 300 SB;
- 1800 s / 500 SB;
- 3600 s / 750 SB.

### 5. Non-effects

No change to:
- current-level 2x;
- free M23 endgame 2x;
- Heart 900-second rule;
- First 10 content/supply/difficulty;
- M43+ surfaces.

### 6. Sensitivity

The focused regression must fail when anti-rollback logic is intentionally removed/bypassed and pass when restored.

### 7. Regression integrity

Relevant M39/M40/M55 and root suites pass with:
- exit 0;
- 0 FAIL;
- 0 SCRIPT ERROR;
- no new unexplained runtime ERROR;
- clean diff hygiene.

## Verdict

PASS:
`AUDITED_PASS / M55-C002 / TIMED 2X ANTI-ROLLBACK / M55 CORE CLOSED`

Otherwise:
`CHANGES_REQUIRED / M55-C002 / <exact finding>`
