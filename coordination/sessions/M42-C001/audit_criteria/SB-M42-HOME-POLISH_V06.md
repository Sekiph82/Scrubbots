# SB-M42 HOME POLISH V06 — CHATGPT AUDIT CRITERIA

Verdict may pass only if V06 is independently verified.

## World / locked V05
- HOME-120 exact bytes/hash unchanged.
- world transform remains identical to V05/V04 full matrix.
- Gift Meter unchanged from V05.
- Win Streak unchanged from V05.
- Play size/style unchanged.
- BottomNav size/style unchanged.
- Profile card/portrait unchanged.
- four shortcut icon sizes unchanged except no authorized size changes at all in V06.

## Ad / stack
- canonical 1080x2160 ad height ~100 px.
- responsive reservation approx 72..112.
- no vertical expand.
- Play, track, nav move down by ~44 px vs V05.
- HOME-120 does not move.

## Scrubby focus
- final total hero scale is 1.22..1.25x V04, target 1.24.
- center X 540 and soles Y 1297 unchanged.
- no sign/helper-bot collision.
- dark focus layer is behind Scrubby and above HOME-120.
- no bright/glowing halo is added.
- shade peak alpha 0.16..0.22 with feathered edge.
- baked sign/helper bots are not materially dimmed.

## Panels
- exact four panels remain.
- body alpha 0.50..0.52.
- outline remains 3 px.
- TASKS and DAILY size unchanged.
- SHOP/COLLECTION size unchanged from V05.

## Currency / Hearts pills
- icon sizes remain ~110 px.
- visible pill height is 67..70 px.
- plus visual is white + dark navy outline + cyan glow, no green circle.
- plus visual is inside right end of pill.
- interactive hit target >=88×88.
- intent-only behavior, no economy mutation.

## Hearts
- canonical config regen_seconds = 900.
- max remains 5.
- HeartService remains wall-clock/offline authoritative.
- no N/5 text inside pill.
- current count is overlaid as white number on heart icon.
- full state displays static 15:00 in pill.
- consuming a Heart starts live 15-minute countdown immediately.
- below max, MM:SS comes from HeartService.seconds_to_next().
- next interval works correctly for multiple missing Hearts.
- max state returns to static 15:00.
- UI refresh cadence is ~1 Hz, not per-frame authoritative timer state.
- rollback resistance and purchases/refills remain correct.

## Modal / regression / integrity
- Daily/Settings modal behavior preserved.
- all touch targets >=88.
- no approved PNG changed.
- manifest unchanged unless only an explicitly required non-art data update is justified.
- TASKS.md / owner / ChatGPT files untouched by Claude.
- all required suites exit 0.
- zero SCRIPT ERROR.
- git diff --check clean.

## Verdict
- AUDITED_PASS / CODE READY FOR OWNER VISUAL REVIEW
- CHANGES_REQUIRED
