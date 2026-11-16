# 162-gift-meter-48h (SB-GIFT-METER-48H-2026-11-17)

Owner 2026-11-17 (chat, new economy decision amending OWNER_ECONOMY_REWARDS_V01 §4.2): "gift meter neden hic
sifirlanmiyor. onun bir suresi olmali. en fazla 2 gunde bir sifirdan baslamali."

## Rule (defaults chosen by the orchestrator, documented as owner 2026-11-17 amendment)
- A Gift Meter cycle lasts at most 48 hours. The window starts when the cycle starts (first progress after
  a reset/new cycle, or at migration time for an existing save with progress > 0).
- When the window expires, the meter resets to 0/1 and a new cycle begins (window starts again at the next
  progress). Partial progress toward the next milestone is lost.
- Milestones already crossed and queued in Gift Bar stay claimable (never lost).
- Reaching 1000 inside the window completes the cycle as today (rollover overflow kept) and starts a new
  48 h window.
- Time source: the same clock/anti-rollback approach the economy already uses for Hearts/Daily (read how
  Daily/Hearts handle device time; reuse it). A clock moved backwards never extends or shortens unfairly;
  follow the existing pattern.
- Expiry is applied by the economy service (M39 boundary) on load and on any read/progress; UI never mutates
  economy.

## UI
- The Home Gift Meter shows the remaining time of the current window when progress > 0 (e.g. "1g 23s" /
  "1d 23h", under 1 h "45dk"/"45m"), localized EN/TR via UiText, small, inside the existing meter area, not
  overlapping the bar numbers or the gift icon. Hidden at 0 progress (no window running).
- Version/config: add the window to data/config/economy_rewards_v1.json gift_meter (e.g. "cycle_window_hours": 48)
  with a schema bump + save migration per repo rules; update coordination/OWNER_ECONOMY_REWARDS_V01.md §4.2
  with the dated owner amendment.

## Tests
New suite: expiry at 48 h resets progress; queued milestones kept; 1000 within window rolls over + new
window; no window at 0; migration of an existing save; clock rollback behaviour; UI countdown text EN/TR.
Watch it fail before the fix. Add to CI list with exact grep -qxF guard. Run affected economy/gift meter
suites (m39*, sb_polish_002_gift_meter, m43_master_c005r_gift_micro_progress, ...), exact PASS lines.

## Must not change
Milestone values/rewards, progress source (Win Streak SB only), other economy.
