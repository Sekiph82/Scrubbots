# SB-M28-C002-C001 — CHATGPT AUDIT CRITERIA

## Authority

- `coordination/OWNER_GAMEPLAY_SCREEN_COMPOSITION_V02.md`
- `coordination/OWNER_GAMEPLAY_MASTER_VISUAL_V01.md`
- Railroad V1 owner decisions
- current economy/speed owner rules

## PASS requirements

### 1. Real production screen
Changes affect the real ProductionGameplayHost screen, not a detached mockup or flattened master screenshot.

### 2. V02 composition
- top-left profile;
- Pause + 2x top-right;
- no Heart/Settings/Goal/Moves/Time;
- no gameplay ad placeholder;
- dominant board;
- slots/supply/boosters in owner hierarchy.

### 3. Board / rail
- BoardRenderer remains authoritative presentation;
- rectangular aspect preserved;
- full four-sided Railroad V1;
- canonical clearance/width/centreline;
- no routing truth changed.

### 4. Connectors
Five permanent baseline connectors are visible and geometrically aligned with real slot-to-bottom-rail movement truth.
Sixth connector appears only with the authoritative temporary sixth slot.

### 5. Supply
Five-column production view shows 5x3 visible structure.
3/4/5 columns remain supported.
Only front batches interactive; preview rows cannot activate.

### 6. Controls/economy
Pause/2x retain authoritative runtime behavior.
Timed 2x uses live wall-clock remaining time and preserves anti-rollback.
Exactly four booster controls use live authoritative state.
No UI-direct economy mutation.

### 7. Dependency honesty
Do not fake-close canonical Pause/BoosterAcquire/2xAcquire/modal-stack rows if M43 dependencies are not yet implemented.

### 8. Responsive / input
Required portrait matrix and safe areas pass.
Board/supply/touch targets remain readable.
Board/supply input coordinate mapping remains correct.
Sixth slot readable.

### 9. Assets
Use approved committed gameplay assets only.
No approved source art regenerated/overwritten.
Flattened master is reference only, not shipping interactive UI.

### 10. Regression
Relevant gameplay/economy/save/navigation/First10/chaos/root suites pass.
No new unexplained FAIL/SCRIPT ERROR/engine-error class.
Diff hygiene clean.

## Verdict

PASS:
`AUDITED_PASS / M28-C002-C001 / GAMEPLAY V02 CORE / OWNER VISUAL REVIEW REQUIRED`

Otherwise:
`CHANGES_REQUIRED / M28-C002-C001 / <finding>`
