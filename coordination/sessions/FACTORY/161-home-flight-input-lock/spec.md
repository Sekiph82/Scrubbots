# 161-home-flight-input-lock (SB-HOME-FLIGHT-LOCK-2026-11-17)

Owner 2026-11-17 (chat): after a win, the Scrubby WIN video plays, then Home opens and the won rewards
fly to their Home destinations (job 152, scripts/ui/home/home_reward_flight.gd). Until the LAST reward
flight (incl. its count-up) has finished, NO button on Home may react: PLAY, shortcuts, bottom nav,
top HUD +, profile, gift meter, reward track, rewarded-ads, Android Back, everything. The player must
watch the movements.

## Acceptance
1. One input lock owned by Home for exactly the flight sequence: a full-rect blocker (or equivalent
   single gate) over Home that swallows touch/mouse; Back/ui_cancel ignored while locked. No per-button
   disabled styling flicker needed; buttons simply do not respond.
2. Lock releases when the flights + count-ups end (the existing finished signal / state), and also on
   any failure path (no flights, empty receipt, Reduced Effects instant path, node freed) so Home can
   never stay locked. Add a safety timeout = flight duration + small margin.
3. Ceremonies queued after the flights keep their current order (they start after the lock lifts).
4. Normal Home entry (no win receipt) is never locked.
5. Test: new or extended suite proving (a) taps on PLAY/nav/shortcut during flights do nothing,
   (b) they work after the flights end, (c) no-receipt Home is unlocked, (d) Reduced Effects / empty receipt
   never lock. Watch it fail before the fix. Add it to the CI list with an exact grep -qxF guard.
6. Run affected Home/win suites (sb_phone_2026_11_12_e_win_home etc.), exact PASS lines.

## Must not change
Flight visuals/timing, rewards/economy, Home art (jobs 158/159), gameplay.
