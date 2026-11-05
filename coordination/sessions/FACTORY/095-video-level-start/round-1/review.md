# Review round 1: 095-video-level-start

Ran sb_video_005_level_intro headless: exit 0, 8/8 cases (the one engine ERROR is the intended unplayable-video case). `git diff --check`: clean.

Checked:
- Lifetime: the overlay is a child of the gameplay host. A scene change or host release frees it with the host. Its tweens are bound to the overlay, so none dangle. close() is idempotent, so touch+emulated mouse or a tap racing the video `finished` signal can't double-free. The decoder is removed and freed in close().
- Double intro: it is only added after an accepted GAMEPLAY start or retry. Retry comes from Results, when the previous intro is already gone, so there is no stacking.
- Input: MOUSE_FILTER_STOP plus accept_event in _gui_input consumes taps. Children are IGNORE, so the overlay takes everything. The test proves 0 hits underneath while it exists and 2 hits after.
- Layering: it is the host's last child, below the app ModalStack and the coachmark layer, so popups and tips stay above it. It is skipped while a coachmark is showing.
- Auto policy: level_intro_enabled is -1 auto, which is ON when path == CANONICAL_SAVE_PATH. A real device save uses that path, so real players see it. Injected test paths are OFF, which mirrors boot_ftue_override.
- Scope: presentation only. retry_from_results keeps its bool contract. No economy, save, timer or level-data change. No locked rule is violated.
- The tests assert real properties (label equals level, decoder freed, tap consumed, no coachmark overlap, retry re-shows).

Findings: none blocking.

Notes (non-blocking):
- Gameplay stays live under the scrim, but input is blocked, so nothing changes. Any future autoplay or hint timer would run during the intro.
- Reduced Effects runs a short bounce. The builder flagged this deliberately, and the job asked for it.
- The suite is not in the CI list. The builder explained why.

VERDICT: PASS

Must-fix list: none.
