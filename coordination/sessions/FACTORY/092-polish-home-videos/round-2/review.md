VERDICT: PASS

Commit b288419f fixes the round-1 finding. Reviewed by reading the diff only; suites were not re-run, as instructed.

- In `start_gesture`, the failed-play branch now sets `_wait = _next_interval()` after `_end_gesture()`. `_end_gesture` does not touch `_wait`, so the value sticks. `_wait` is decremented at line 229, so the next attempt is a full video hold away, not the next frame.
- A `_failed` counter is added and exposed in `get_state()`.
- The failure test now asserts `2 <= failed <= 7` over 30 s, besides the still being kept and nothing being counted. That bounds attempts, and a per-frame retry (about 1800) would fail it.

Note: the bound rests on `VIDEO_HOLD_MIN`/`VIDEO_HOLD_MAX` being roughly 5-6 s, as the test message says. I did not check those constants.
