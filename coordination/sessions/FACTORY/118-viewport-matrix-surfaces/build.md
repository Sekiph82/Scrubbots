STATUS: READY

# Build: SB-M49-026..028 + SB-M49-031..032 viewport matrix for every M43/M44 surface

## Summary
Two new local suites (not in CI) extend factory 115's touch and text checks to every surface in the
player-experience asset manifest. They run on the full 8-size matrix from m49_responsive_matrix
against the real app root, using throw-away saves.
- `tests/m49_surface_matrix.gd` (extends `m49_touch_targets_text_stress.gd`, reuses its `_boot/_open/_touch_bad/_text_bad/_report`):
  - v01: inventory ledger.
  - v02: every surface on 8 sizes.
  - v06: track checks.
- `tests/m49_surface_stress.gd` (extends the matrix suite; it was split off to keep each suite under about 4 min):
  - v03: long values.
  - v04: modal stacks and back.
  - v05: scroll screens.
  - v07: compact sizes under a notch.

The suites found five real layout failures. The UI-only fixes (no gameplay or economy changes) are:
- `scripts/ui/profile/profile_screens.gd`: the Events claim/JOIN buttons go from 72 to 88 px, and the Notifications category toggles go from 70 to 88 px.
- `scripts/ui/collection/collection_screen.gd`: the Collection set card DETAILS button goes from 64 to 88 px.
- `scripts/ui/components/ui_event_card.gd`: the event title and milestone text/reward now wrap instead of widening the 880 px frame. The When/Progress pills use the existing `HomeStyle.fit_font` (PILL_MAX 600), so they stay inside the hero.
- `scripts/ui/results_screen.gd`: Results reward-row text wraps, so a long Catch-Up or bundle row no longer widens the panel off-screen.

Commits: cbbf9b31 (suites and fixes), 62c9a33e (TASKS.md).

## Acceptance criteria
1. [x] SB-M49-026, every M43/M44 surface on the full viewport matrix:
   - m49_surface_matrix v01 classifies all 42 manifest surfaces (unknown [] stale []).
   - 40 are walked on all 8 sizes ("every inventory row walked on all 8 sizes []"):
     - Home and the factory 115 popups.
     - Comeback, Rewarded Ads, Achievements, Notifications and the permission prompt.
     - Collection set, card and exchange; Robot detail.
     - SB popup and insufficient SB.
     - Generic reward/confirm/network/busy/feedback popups.
     - Daily reward and ScrubBox.
     - The 6 meta ceremonies, standard and premium pack.
     - Gameplay, Pause, 4 booster acquire popups, 2x, Level Intro, Need a Hand.
     - Results WON and LOST.
   - Each surface is checked for: frame inside the screen, touch targets >= 88 with no overlap, no clipped or off-screen text.
   - Recorded NOT_BUILT, not invented: account_cloud_sync_conflict (SB-M49-030 queue row) and friends_postlaunch (post-launch).
   - The ranks surface is walked as "leaderboard" (open_ranks). level_intro exists now, although the manifest still lists it as unimplemented.
2. [x] SB-M49-027, long prices, timers, labels and bundles: m49_surface_stress v03 at 720x1280 and 1080x2400.
   - It first records an English baseline, then repeats the walk with pseudo +40%, 9,999,999 SB / 99,999 Bot Parts, empty Hearts (refill timer), a 9,999,999 SB price with a long item label, 6-digit reward bundles, and 999 streak/level values.
   - Nothing is clipped and nothing overhangs beyond the English design. 1782 text controls were measured; 1296 of them carry the stress copy.
3. [x] SB-M49-028, modal stacks, back and scroll screens, at 720x1280, 1440x3200 and 1536x2048:
   - v04 opens 5 popup-over-popup chains: Collection > set > card, Robots > detail, Tasks > ScrubBox, Notifications > permission, Profile > Achievements.
   - At each step the top popup covers the screen, owns input and has its frame inside the screen.
   - A real `ui_cancel` (Esc) and `handle_back()` close the top popup only, in LIFO order. A further back press leaves Home in place.
   - v05: 13 surfaces (Collection, set, Shop, Events, Robots, Tasks, Daily, Gift, Achievements, Help, Profile, Ads, Exchange). Every visible ScrollContainer stays inside the screen and scrolls when its content is taller. Its first and last rows are fully reachable.
4. [x] SB-M49-031, tracks across the matrix, from m49_surface_matrix v06 on all 8 sizes:
   - Results WON shows the 10-node journey in one row (no overlap, nodes >= 24 px), plus Next Cleanup and the Catch-Up row, all inside the screen. CLEAN NEXT and HOME are >= 88.
   - Events shows the Weekly active and upcoming cards and the First-Try card, with JOIN >= 88. This uses an injected config, because the live events_v1.json schedules no events yet.
   - Tasks shows the ScrubBox row and OPEN button; the ScrubBox ceremony is walked too.
   - Welcome Back, from a real 49 h return through a relaunch, shows the Catch-Up row with 3 pips inside the screen.
   - Under a notch the same checks pass in v07.
5. [x] SB-M49-032, compact degradation: m49_surface_stress v07 on the COMPACT sizes 720x1280, 1080x1920 and 1536x2048, with a synthetic notch:
   - The Home and Results journeys stay one row of 10 information-only nodes: the strip ignores the mouse, takes no focus and has no children, so it is never a level-select grid. They sit inside the safe rect and never overlap PLAY.
   - The Events track scrolls (v-scroll max > height) down to its last milestone.
   - Events, Comeback, Tasks, ScrubBox and Results stay inside the safe rect, and touch and text checks pass.
6. [ ] Owner phone visual sign-off: still pending. The TASKS rows say so.

## Validation
Godot 4.7.2 console, headless, worktree, run serially:
- tests/m49_surface_matrix.gd: exit 0, `M49 surface matrix evidence: PASS (3/3 cases, 0 fail)`, 218 s, 458 ok. LOCAL_PASS.
- tests/m49_surface_stress.gd: exit 0, `M49 surface stress evidence: PASS (4/4 cases, 0 fail)`, 179 s, 310 ok. LOCAL_PASS.
- Regression suites, all exit 0, all with 0 SCRIPT ERROR / Parse Error:
  - m49_touch_targets_text_stress PASS 4/4 (158 s)
  - m49_responsive_matrix PASS 8/8 (280 s)
  - m43_master_c010_meta PASS 12/12
  - m43_master_c011_c014 PASS 29/29
  - m43_master_c007_collection PASS 19/19
  - m43_c001a_results_foundation PASS 11/11
  - m43_c001b_won_results_visual PASS 11/11
  - m43_c001r_c001_results_momentum PASS 40/40
- `git diff --cached --check` was clean.
- project.godot and the tracked .import churn from `--import` were restored. No user:// m49 saves are left.
- No CI run and no phone build, as the brief asked.

The worktree still holds about 1190 untracked import artifacts (.uid, .import, docs/*.translation) from the one-time `--import`. My `git clean` in the worktree was denied by permissions. None of these files are committed, and they disappear when the worktree is deleted.

## Log
### Round 1
- Wrote the matrix suite by reusing factory 115's helpers through script inheritance.
- The first run found these failures:
  - Events claim button at 84 px.
  - Notifications toggles at 70 px.
  - Collection DETAILS at 64 px (it showed up once a card was owned).
  - Under long copy, the Events card title and milestone text, and the Results reward rows, widened their 880 px frames off-screen.
  - Event pills overflowed the hero.
- I fixed each one minimally, as listed above.
- Test-side fixes:
  - Booster and Need a Hand popups are now measured after they lay out.
  - Card Detail is opened with an owned card.
  - Results is measured after the 0.4 s CLEAN NEXT emphasis bump, because the transient scale had read as overhang.
- Split v03, v04, v05 and v07 into m49_surface_stress.gd to keep both suites under about 4 min.
