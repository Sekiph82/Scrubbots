VERDICT: PASS

Checks: sb_phone_2026_11_12_e_win_home.gd -> "SB-PHONE-2026-11-12-E win home evidence: PASS (10/10 cases, 0 fail)".

1. Lock lifetime: layer is freed in _on_completed -> _clear, reached by natural end, finish() (also from the safety timer, total duration + 1 s, key-guarded), and Reduced / empty steps (finish() inside play, layer cleared at once). Empty plan returns before any layer is made. Layer is a child of Home, so it is freed with Home. Back is gated on is_reward_flight_running (tween-based), so it is released when the tween ends.
2. Back returns "none" only when route is HOME and the flight runs (main.gd).
3. Counter: from + n*arrived/k in integers, last arrival = from+n exactly; label uses UiText.num; test asserts per-arrival trace and final chip.
4. No economy mutation: only receipt and view model are read; amounts are unchanged (n = to - from or cards_delta).
5. CI guard is exact 10/10 (grep -qxF, comment updated).

Notes (non-blocking): if Home is hidden but still in the tree, the layer persists until the tween or timer ends (bounded). Plan with to==from and n==0 gives 1 copy and "+0" (not reachable from the plan filters).
