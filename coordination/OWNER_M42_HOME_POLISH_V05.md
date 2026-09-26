# OWNER M42 HOME POLISH V05

Date: 2026-09-26
Authority: OWNER
Scope: Home HUD polish + bottom-stack reflow after V04 visual review

V04 single-world-background architecture remains approved. This decision changes only HUD/panel styling, Scrubby hero scale and lower-stack/ad geometry. HOME-120 itself and its current world transform must remain unchanged.

## 1. World background lock

The owner likes the current World 01 background placement.

- Keep HOME-120 bytes unchanged.
- Keep the current V04 world image scale and offset unchanged at the canonical 1080x2160 viewport.
- Preserve the current V04 world transform behavior at the tested viewport matrix.
- Do not move, zoom, crop or recompose the world merely because the ad slot becomes shorter.
- When the ad slot shrinks, only the visible clipping boundary may extend farther downward.
- Scrubby remains a separate layer.

V04 measured transform baselines to preserve within normal floating-point/layout tolerance:
- 1080x2160: scale 1.0000, offset (0, 0)
- 1170x2532: scale 1.0889, offset approximately (-3, 0)
- 1290x2796: scale 1.2111, offset approximately (-9, 0)
- 1080x2400: scale 1.0329, offset approximately (-17.8, 0)
- 1440x3200: scale 1.3981, offset approximately (-35, 0)
- 1080x1920: scale 1.0000, offset approximately (0, -79)
- 1536x2048: scale 1.4118, offset approximately (5.6, -515.9)

## 2. Scrubby hero scale

Scrubby should be more dominant.

- Keep canonical feet anchor at (540,1297).
- Keep center X = 540.
- Enlarge Scrubby approximately 15% relative to V04 visible size.
- Scale upward/outward from the feet anchor, not downward.
- Do not move the background.
- Do not cover the baked WHISPERING PARK / AREA 1 sign.
- Do not materially cover baked helper bots.
- The main hero should clearly dominate the baked helper bots.

## 3. Four shortcut panels

Home remains exactly four panels:
- left: SHOP, COLLECTION
- right: TASKS, DAILY

Current V04 panel backgrounds are too transparent and almost disappear.

Desired visual treatment:
- still translucent, but clearly recognizable as panels;
- dark navy/cyan glass-like tint;
- target background alpha roughly 0.40-0.48;
- 2-3 px cyan/blue outline with visible but restrained alpha;
- subtle glow/shadow allowed;
- same size system for all four;
- retain outer margin from the screen edge.

Icons:
- SHOP remains enlarged.
- COLLECTION remains enlarged.
- TASKS keeps its current V04/V03 icon size.
- DAILY keeps its current V04/V03 icon size.

## 4. Scrub Bucks and Hearts HUD

Use the canonical master reference at:
assets/art/references/_owner_inbox/Game Screens/main screen.png

The desired visual grammar is the master currency/lives HUD, adapted to current semantics.

For both chips:
- oversized foreground icon on the left;
- dark-blue rounded pill/chassis behind the icon;
- large live value in the pill;
- separate bright-green circular '+' button attached to the right;
- icon and plus button both visually sit in front of the pill;
- all components read as one assembled mobile-game HUD widget.

Scrub Bucks:
- use approved banknote icon, never the old coin/star currency.
- show live SB balance.
- '+' emits request intent only.

Hearts:
- use approved red heart icon.
- show live N/max.
- when canonical regen timer exists, timer may appear as smaller secondary live text inside the pill.
- '+' emits request intent only.

The + buttons must not invent a price, product, transaction or charge.

## 5. Gift Meter visual rebuild

Preserve Gift Meter semantics:
- live N/1000 ratio only;
- no Event Points;
- no old event timer;
- no long NEXT GIFT caption.

Restyle the widget using the visual language of the master Gift Bar reference:
- large foreground HOME-051 emblem on the left, allowed to overhang the chassis;
- substantial dark-navy rounded outer chassis with cyan/blue edge;
- bright gold/yellow progress fill inside;
- live N/1000 centered inside the fill/bar with large white outlined text;
- large foreground HOME-054 reward crate on the right, allowed to overhang the chassis;
- claimable badge may overlap the crate when live state requires it;
- left emblem and right crate must be above the bar body in z-order.

Do NOT add the master's 2d15h timer tab unless a canonical Gift Meter timer is introduced by another system. V05 does not invent one.

## 6. Win Streak reward track visual rebuild

Preserve current semantics:
- five rewards;
- values exactly 1 / 5 / 10 / 25 / 100;
- no '+' prefixes;
- no per-step WIN labels;
- no repeated per-step SB icons;
- current/reached/future state remains readable.

Restyle toward the master reward-track reference:
- shallow dark-blue rounded rail/chassis;
- progress line through the rail, green/yellow for reached/current progression;
- large streak badge HOME-086 on the left, visually in front of the rail;
- five gift milestones HOME-090..094 sit on/above the rail and may overhang its top edge;
- gifts should read as reward objects, not thumbnails trapped in cells;
- numeric value sits below each gift, centered;
- reached = bright/full;
- current = strongest glow/accent;
- future = dimmer, but still readable.

## 7. AdBannerSlot height

Current black ad reservation is visually too tall.

At canonical 1080x2160:
- target visible AdBannerSlot height: approximately 144 px;
- this is about the owner-marked red rectangle height, not the current large empty black area;
- responsive target may scale with width but must not vertically expand to consume leftover space;
- use an explicit fixed/reserved height with sensible clamp, approximately 96..160 px;
- AdMount remains empty;
- no fake ad text/content;
- future No-Ads collapse seam remains.

Critical: the ad slot must not use EXPAND/FILL vertically in a way that grows beyond its intended banner reservation.

## 8. Bottom action-stack reflow

When AdBannerSlot becomes shorter, the freed vertical space should be used by moving the lower live UI downward.

The following should move downward together:
1. PLAY CTA
2. Win Streak reward track
3. BottomNav

Desired architecture:
- treat PLAY + WinStreakTrack + BottomNav + AdBannerSlot as a bottom-anchored stack;
- AdBannerSlot is the bottom-most fixed-height region;
- BottomNav sits directly above it;
- Win Streak track sits directly above BottomNav;
- Play sits directly above the track;
- reducing ad height therefore lowers all three upper elements by the same released amount.

Do not move the World 01 background to achieve this.
Do not move Scrubby's feet anchor to achieve this.

The baked helper bot near the Play area should therefore appear visually closer to the lowered Play CTA, which is desired.

Keep the compact coming-soon/status text attached to Play so it does not create a new layout row.

## 9. Preserve working V04 behavior

Do not regress:
- single HOME-120 world background;
- no duplicate portal/platform/helpers;
- exactly four shortcut panels;
- Daily modal hiding Home action UI;
- Settings modal hiding Home action UI;
- bottom Settings only;
- Bot Parts N/250 in-bar treatment;
- standalone native white Play triangle;
- reward values 1/5/10/25/100;
- AdBannerSlot collapse seam;
- 49 historical approved PNGs unchanged;
- HOME-120 exact approved bytes unchanged;
- no speculative world/level mapping.

## 10. Final owner gate

No implementation self-closes SB-M42-011 or SB-M42-017.
Fresh owner runtime screenshot is required after ChatGPT audit.
