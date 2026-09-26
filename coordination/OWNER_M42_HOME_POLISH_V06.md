# OWNER M42 HOME POLISH V06

Date: 2026-09-26
Authority: OWNER
Scope: final Home polish after V05 runtime review

This decision supersedes V05 only on the items below. All other V05 behavior is preserved.

## A. Preserve / lock

Do NOT change:
- HOME-120 bytes, scale, offset, crop or world-transform logic.
- Gift Meter V05 geometry/styling/semantics.
- Win Streak V05 geometry/styling/semantics.
- Play size/style.
- BottomNav size/style.
- Profile card / profile portrait.
- SHOP/COLLECTION/TASKS/DAILY icon sizes.
- four-panel membership.
- modal behavior.
- world/background/helper-bot composition.

## B. Ad slot + lower stack

The V05 ad reservation is still too tall.

At canonical 1080x2160:
- reduce AdBannerSlot from 144 px to **100 px**.
- responsive reservation should remain explicit/non-expanding, approximately clamp **72..112 px**.
- AdMount remains empty.
- No-Ads collapse seam remains.

Because the bottom stack is bottom-anchored, the released 44 px must move:
- Play down by ~44 px,
- Win Streak track down by ~44 px,
- BottomNav down by ~44 px.

Do not move HOME-120 or Scrubby feet anchor to achieve this.

## C. Scrubby hero focus

Scrubby should become more visually dominant without changing the background.

- target total scale relative to the V04 base fit: **1.24x**.
- acceptable final range: **1.22x..1.25x**, only reduce if needed to clear the baked sign/helper bots.
- centre X remains 540.
- visible soles/feet anchor remains y=1297.
- grow upward/outward from the feet anchor.

The bright portal/background glow behind Scrubby currently competes with the hero. Do NOT add another bright glow.

Add a subtle **dark focus-separation layer** behind Scrubby but above HOME-120:
- soft feathered navy/black elliptical/radial dimmer,
- centered behind Scrubby torso,
- strongest alpha approximately 0.16..0.22,
- fades smoothly to 0 at the edge,
- does not affect Scrubby itself,
- should begin below the baked sign so the WHISPERING PARK sign remains bright/readable,
- should not noticeably darken helper bots outside the hero zone,
- no visible hard edge.
Purpose: reduce local background luminance/competition and pull visual attention back to Scrubby.

## D. Four shortcut panels

Keep icon sizes exactly as V05.

Increase only panel visibility:
- normal panel body alpha target **0.50..0.52**.
- keep 3 px cyan outline and restrained glow.
- still translucent, not opaque.
- preserve panel size, margins and positions unless collision avoidance requires existing behavior.

## E. Currency + Hearts HUD

The foreground icons are already large enough. Do not enlarge them.

### Shared pill change
- reduce pill/chassis visual height by approximately **20%** from V05.
- V05 ~84 px -> target **67..70 px** visual pill height.
- keep overall widget compact and aligned.
- keep icon size ~110 px.
- value/timer text should remain readable.

### Plus control
The owner supplied a new plus reference: a bold white '+' with dark navy outline and cyan outer glow, no green circle.

Use that visual language for both Scrub Bucks and Hearts.
- visually place the plus glyph **inside the right end of the pill**, not as a separate circle outside.
- plus art/glyph should be approximately 48..58 px.
- maintain an invisible/transparent >=88x88 hit target centered on it for touch accessibility.
- pressing still emits request intent only; no fake transaction.
- recreate the owner plus reference natively if the chat image is not available to Claude: white plus, dark navy outline, cyan glow, transparent background.

### Scrub Bucks
- keep approved banknote icon at left.
- pill displays live SB balance.
- plus glyph is inside the pill at right.

### Hearts
Owner changes both UI and canonical Heart regen timing.

This V06 decision supersedes `coordination/OWNER_ECONOMY_REWARDS_V01.md` §6 only for Heart regeneration interval/display:
- Heart regen becomes **1 Heart every 15 real-world minutes (900 seconds)** instead of 30 minutes.
- max remains 5.
- wall-clock/offline/background semantics remain unchanged.

Heart display:
- do NOT show `5/5` inside the pill.
- overlay the current heart count as a large pure-white number directly on top of the red heart icon itself, with a dark outline for readability.
- when full, show `5` on the heart icon.
- the pill body displays the regen clock.
- at full Hearts, pill displays static ready-state **15:00** and does not count down.
- immediately after a Heart is consumed from full, countdown begins from 15:00 toward 00:00 using HeartService's wall-clock state.
- while below max, display live `MM:SS` from `HeartService.seconds_to_next()`.
- when a heart regenerates and more are still missing, reset display to the next 15:00 interval and continue.
- when max is reached, return to static 15:00 ready state.
- UI must never maintain a separate authoritative timer; HeartService remains truth.
- refresh the Home timer at 1 Hz while visible, not per-frame.

Update canonical data/config and HeartService/economy tests to 900 seconds. Preserve atomic purchase/refill behavior.

## F. Gift Meter

No V06 visual or semantic changes. Lock V05 implementation.

## G. Win Streak

No V06 visual or semantic changes. Lock V05 implementation.

## H. Final validation

V06 should be a small controlled polish, not another Home redesign.

Fresh owner screenshot remains required. Do not self-close SB-M42-011/SB-M42-017.
