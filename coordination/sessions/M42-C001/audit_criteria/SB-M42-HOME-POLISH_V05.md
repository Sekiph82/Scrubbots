# SB-M42 HOME POLISH V05 — CHATGPT AUDIT CRITERIA

Verdict may pass only if the V05 owner decision is independently verified.

## 1. World lock
- HOME-120 bytes/hash/path unchanged.
- 1080x2160 world scale remains 1.0 and offset remains (0,0).
- V04 transform baseline remains within tolerance across required viewports.
- shrinking AdBannerSlot does not shift/zoom HOME-120.
- only the visible clip boundary may extend downward.

## 2. Scrubby hero
- center X remains 540.
- feet remain y=1297.
- visible character scale is about 15% larger than V04, or the maximum documented factor that still clears sign/helper bots.
- enlargement happens upward/outward from feet anchor.
- baked sign not covered.
- baked helper bots not materially covered.

## 3. Four panels
- exactly SHOP/COLLECTION left, TASKS/DAILY right.
- panel body is clearly visible but translucent.
- target alpha approximately 0.40–0.48.
- visible 2–3 px outline.
- current outer margin preserved.
- SHOP/COLLECTION remain enlarged.
- TASKS/DAILY retain exact V04/V03 icon size.

## 4. Scrub Bucks / Hearts
- both use oversized foreground icon + dark pill + live value + green circular plus.
- approved SB/Heart icons remain.
- no coin/star regression.
- heart live count remains canonical; regen timer only if canonical and below max.
- plus buttons >=88 px, visually circular, and emit intent only.
- no economy mutation from plus signals.

## 5. Gift Meter
- N/1000 only.
- no long caption, Event Points or fake timer.
- HOME-051 and HOME-054 are visibly larger foreground endcaps.
- dark navy chassis + gold/yellow progress fill exists.
- ratio is centered inside the bar/fill with strong readable styling.
- claimable badge remains live if applicable.
- no fake 2d15h tab.

## 6. Win Streak
- shallow dark-blue rail.
- left HOME-086 badge is foreground/overhanging.
- five gift milestones are larger and may overhang rail top.
- values exactly 1/5/10/25/100.
- no + / WIN labels / per-step SB icons.
- current/reached/future state remains readable.
- HOME-087 remains retired.

## 7. Ad slot
- canonical 1080x2160 visible reservation is approximately 144 px.
- responsive clamp is reasonable, around 96..160 px.
- slot does not vertically expand to consume leftover space.
- AdMount remains empty.
- collapse seam remains.

## 8. Bottom stack reflow
- explicit order is Play -> WinStreakTrack -> BottomNav -> AdBannerSlot.
- stack is bottom anchored.
- reducing ad height moves BottomNav downward.
- WinStreakTrack moves downward with it.
- Play moves downward with it.
- released space is not redistributed into arbitrary gaps.
- HOME-120 transform does not move.
- Scrubby feet anchor does not move.
- compact status remains attached to Play.

## 9. Modal regression
- Daily hides Home action stack and HUD plus buttons.
- Settings hides Home action stack and HUD plus buttons.
- hidden controls receive no input.
- close/back restores exact state.

## 10. Asset integrity
- no historical approved PNG changed.
- HOME-120 exact bytes unchanged.
- no new image generation required or introduced.

## 11. Responsive / tests
- required viewport matrix passes.
- touch targets >=88 px.
- required focused suites exit 0.
- root suite exits 0.
- zero SCRIPT ERROR.
- no new hidden FAIL.
- git diff --check clean.
- TASKS.md, owner files, ChatGPT audit/criteria files untouched by Claude.

## Verdicts
- AUDITED_PASS / CODE READY FOR OWNER VISUAL REVIEW
- CHANGES_REQUIRED

SB-M42-011 and SB-M42-017 remain open until owner runtime screenshot approval.
