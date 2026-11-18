VERDICT: PASS

## Suite results (worktree, headless, sequential)
- sb_tf04_gameplay_layout: PASS (7/7 cases, 0 fail)
- m28_c002_c002_static_shell: PASS (16/16)
- m28_c002_c002_r01_visual: PASS (10/10)
- m28_gameplay_layout_smoke: 253 checks, 0 failures
- board_bg01_backdrop: PASS (4/4)
- m49_responsive_matrix: PASS (8/8)
- m49_touch_targets_text_stress: PASS (5/5)
- m50_accessibility_audit: PASS (11/11)
- m42_home_v04: 18/18, 0 failures
- sb_tf03_home_profile: PASS (11/11)
- m43_c001a_results_foundation: FAIL (11/11 cases, 1 fail: "Home flies every committed reward"). Not caused by this job. The branch is based on 0c1fb64a. Main commit 5fbd4785 ("align results-flight and Settings-cards expectations with SB-TF-03") fixes this test's expectation and is not on the branch.
- m58_privacy_consent: FAIL (7/7 cases, 1 fail: "cards unchanged, Reduced Effects in place"). Same cause: 5fbd4785 touches tests/m58_privacy_consent.gd. The expected-card list there predates SB-TF-03, and the job did not touch Settings.
- git diff --check: clean. No .import, .uid, project.godot or viewport_metrics files are in the two commits.

## Verified
- The SHA256 table in gameplay_shell_geometry.gd matches sha256sum of all six committed masters.
- Banner wiring:
  - The production_gameplay_host.gd build path sets the flag from economy.ads.allowed("banner"), and main.gd updates it live through the same closure that updates Home. get_screen() exists, and the host is null/valid-guarded.
  - The banner is anchored PRESET_BOTTOM_WIDE with offset_top = -height. Collapsing hides it and get_ad_region_rect() returns height 0.
  - Shell.AD and the old AdRegion are gone.
- Home helper move:
  - HomeStyle.ad_banner() and ad_slot_height() are line-for-line the previous Home construction. HomeScreen aliases the constants and still calls _reg on AdMount.
  - The clamp is identical, and Home suites m42_home_v04 and sb_tf03_home_profile pass.
- Board floor: BOARD_FLOOR_TONE is a single selector, there are 4 tones, BG01 is kept, and BoardBackground uses the selected tone.
- Evidence PNGs, all viewed:
  - Scrubby is bigger and sits left of the boosters. The bucket and sign are smaller beside Supply, and with 5 columns they just touch the panel (allowed).
  - The bubble runs behind the slots and Supply. Both lines ("LET'S CLEAN THIS MESS!" and the sub-line) are fully uncovered, and the tail points at Scrubby.
  - The boosters are higher and bigger, ordered plus_one_slot, random, selector, tornado (rightmost). The banner is at the bottom, the board is dominant, and the 6-slot shells show 6 usable slots.
  - The side-by-side capture is 2160x1272 with 4 labelled panels. The tones are visibly brighter, though modestly so, as build.md notes.
- The CI guard line and validate-list entry are added and consistent with 7/7.
- Region byte-identity (rail, slots, Supply) rests on the test's per-region hashes, which pass. I did not re-hash the pixels independently.

## Findings
None blocking.

## Notes
- The branch needs a rebase or merge onto main so it picks up 5fbd4785. The two failures above are base-related and should clear then. Re-run m43_c001a_results_foundation and m58_privacy_consent after merging.
- Floor tones are only about 2.8x BG01 luminance because of the 1.3:1 contrast rule against C14/C08. The owner picks from the capture, and the job is not blocked on that choice.
- The booster row is not centred (x 332..840). It is the intended layout.
