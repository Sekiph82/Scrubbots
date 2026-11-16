VERDICT: PASS

Checks: git diff --check clean. sb_gift_meter_48h: "SB-GIFT-METER-48H evidence: PASS (7/7 cases, 0 fail)". sb_polish_002_gift_meter: PASS (11/11). m39a_economy_core: PASS. m39_v03_full_surface: PASS.

1. Expiry only zeroes _cycle_progress and window; the queue is untouched, so queued or claimable rewards are never deleted. Occurrence ids are unique, so there is no double grant.
2. Cycle index = completed + expired, which strictly increases, so new ids cannot collide with old ones. For old saves (no cycles_expired key) the index equals cycles_completed, so the ids are unchanged. Legacy milestone 50 in the queue is still importable. An old save with progress > 0 gets its window from the first load. Coherence is total = cc*MAX + expired_progress + cp.
3. Rollback (now < start) never expires, and window_seconds_left is clamped to 48 h. Clock-forward expiry only costs the player partial progress.
4. The UI only reads window_seconds_left() through the view model and renders a label. It does not mutate the economy.
5. The CI guard uses grep -qxF with the exact 7/7 line, and the suite is added to the list.
6. The milestone values are unchanged. The only config change is cycle_window_hours plus the schema bump to 4.

Notes (non-blocking): window_seconds_left() and cycle_progress() can mutate state through lazy expiry. This is deliberate and is documented in the file header. The import errors for missing png loaders in the headless runs are only from the missing --import and are unrelated to this change.
