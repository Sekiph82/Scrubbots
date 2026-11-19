# 193-tf26-feedback — SB-TF-13: owner TestFlight build 26 feedback (9 items)

Owner TestFlight feedback on build 0.1.0 (26), 2026-11-19, fetched via ASC API. Screenshots
(1179x2556 device, downscaled) in `factory/jobs/193-tf26-feedback/shots/v1..v9.jpg`, comments in
`shots/feedback.json`. Owner chose the floor colour in chat: "Koyu mor-gri ok".

Do NOT commit anything under factory/jobs/193-tf26-feedback/shots or /src (evidence only; keep any
capture PNGs you want merged at the job-folder root, small). Do not edit TASKS.md. Never boot
main.tscn against the real save.

## Items

1. **Home activity buttons too small** (v1/v8: REWARDED ADS, TASKS, event buttons left/right).
   SB-TF-03 made them 30% smaller; owner now: "Homedaki tablolar bu seferde cok kucuk olmus".
   Make them clearly bigger (about +40% vs now, i.e. roughly the pre-SB-TF-03 size), labels
   readable; keep 4-left/4-right stacking, 50% transparent backgrounds, hide/show rules. They must
   not overlap the profile card, gift bar, area title, Scrubby face or PLAY/level strip.

2/4. **Event screen pixel image half shown** (v2, v4: the left card shows the level art with the
   top ~40% dark navy, art squeezed to the bottom). Find why (aspect/crop/offset of the board
   thumbnail texture, or VOID/cleared rows) and show the whole artwork centred in the card,
   nearest-neighbour, aspect kept. Fix for every event using this card.

3/5. **Events: buttons and tutorial controls hidden under the banner ad** (v3, v5). The Home
   banner area (SB-TF-03 bottom banner) covers the bottom of every event screen: the main green
   button, the tutorial "Continue" button and the step counter (1/7) are under the ad, so the
   owner thought the tutorial has one page. Event screens and the event tutorial must lay out
   inside the area ABOVE the banner (same banner-height reservation the Home/Gameplay layout
   uses), content scrolls if needed, the primary button and tutorial Continue/counter always
   fully visible. Also v3/v5 show TWO close (X) buttons during the tutorial (tutorial X over the
   screen X, offset): only one X visible at a time.

6. **Board floor colour**: the rail-glow blue #0068D8 (SB-TF-10) is too close to palette C07
   #3690EA / C08 #2450A4, blue cells vanish. Owner: a colour outside the 16 palette colours;
   chose "koyu mor-gri" (dark purple-grey). Use #3A2E4A (or a near value) that keeps CIEDE/Lab
   distance >= 20 from every C01..C16 and from BG01 #202533, and good contrast for both C14
   #515252/C16 #000000 dark cells and light cells. Update BoardPresentation.BOARD_FLOOR, regenerate
   the gameplay shell masters exactly as SB-TF-10 did (tools/gameplay_shell_masters.py bakes the
   floor), docs (MASTER_UI_SYSTEM.md, OWNER_GAMEPLAY_345_STATIC_MASTER_SHELL_V01.md §12) and
   tests that pin the floor colour. Add a test asserting the floor's Lab distance >= 20 from all
   16 palette colours.

7. **Rewarded ads**: after one rewarded video on the Rewarded Ads screen, the next video is not
   offered until the player goes back to Home (v7 is the test ad). After a completed/closed ad,
   request/load the next ad and refresh the Rewarded Ads screen (and any watch-ad button) when
   it becomes available, without leaving the screen. Respect existing daily caps.

8. **Home bow video**: home_scrubby_bow_keyed.ogv (from flow_videos/home_scrubby_bow_magenta.mp4)
   loses the broom. Replace it with the owner's new clip
   `factory/jobs/193-tf26-feedback/src/Robot_Scrubby_bowing_c77edbed.mp4` (720x1280, 190 frames,
   magenta background that may drift) using the same per-frame sampled-background keying as the
   SB-TF-03 wave (factory/jobs/183-tf03-home-profile/make_wave.py in the Desktop checkout,
   factory/jobs/160-home-scrubby-video-key/ tools), trimmed to 185 frames, libtheora -q:v 8,
   24 fps, no audio, exact #FF00FF background, frame 0 overlays the keyed still within the
   m42_c003_scrubby_animation tolerance (adapt the assertion only to documented truth). Keep one
   brush in every frame, no magenta fringe (contact sheet in job folder root as small PNG).
   Update HOME_ASSET_MANIFEST.json approved_sha256 + provenance, ASSET_GENERATION_MANIFEST.json.

9. **Pixel art bigger in gameplay** (v6, v9): the whole gameplay screen is letterboxed — black
   bars on top and both sides — because the 1170-wide shell is scaled down to fit the height
   above the banner. Fix so gameplay fills the device width (as Home does) on tall phones
   (iPhone 1179x2556 and the required viewport matrix): no side bars; vertical leftover is
   absorbed by the background, not black bars. Then also make the artwork larger inside the
   board frame (reduce the inner margin so the art uses the board area better, keep the art
   aspect, still never larger than the frame). Keep sb_tf04 layout invariants (boosters under
   Supply etc.) — update tests to the new truth.

## Acceptance
- Each item above verified by a headless capture at 1179x2556 (and one smaller viewport from the
  matrix) saved as small PNGs at the job-folder root, plus direct test assertions where
  measurable (button rect fully above banner rect; single visible X; floor Lab distance; no
  letterbox: shell width == viewport width; event art card shows all artwork rows; rewarded ad
  re-offer without leaving the screen via the ad service fake).
- All existing CI suites that touch changed areas pass locally (list them with PASS lines in
  build.md); new suite tests/sb_tf13_feedback.gd added to the CI suite loop + guard lines in
  .github/workflows/android-family-first10.yml like sb_tf12.
- APK size growth < 2 MB.
