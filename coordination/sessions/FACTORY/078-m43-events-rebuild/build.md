STATUS: READY

# Build: Events screen rebuild to master v01 (SB-M43-130-REBUILD)

## Summary
The Events popup is now built from one reusable component, `UiEventCard` (`scripts/ui/components/ui_event_card.gd`, a static `build(view, claim)` with no scene file). `refresh_events` calls it once for every view in `ev.list()`. `view["phase"]` picks the state:

- **active**: a blue card with the gold title `EVENT_WEEKLY_TITLE`, then the `Hero` art. Two native navy pills sit over the art: `WhenPill` (clock icon + `When` = `EVENT_ENDS_IN` + dhm) and `ProgressPill` (`Progress` = `EVENT_PROGRESS`). Below come `Milestone_<i>` cream rows and a light-blue `Rule` strip (info icon + `EVENT_RULE`).
- **ended**: the same layout, with `When` = `EVENT_ENDED`. Claimable rows still claim; rows that were never reached show the lock pill.
- **upcoming**: a collapsed grey card with the title and the same hero texture tinted grey (`self_modulate`, so not a true desaturation). It shows only the `When` = `EVENT_STARTS_IN` pill: no rows, no Progress, no rule.

Each milestone row shows:
- **Left:** the reward icon. A single known key maps to a bundle from `assets/ui/final/rewards/`; several keys or an unknown key show `gift_box`.
- **Middle:** `Text` = new `EVENT_MILESTONE_LEVEL_ONE` ("1 level") when the target is 1, otherwise new `EVENT_MILESTONE_LEVELS` ("N levels") and `Reward` = `UiText.reward_text`.
- **Right, from the real flags:**
  - claimed: a green `Done` pill with a check and `State` = `ACH_DONE` (COMPLETED)
  - claimable: the existing stash-reused claim button `ev:<id>:<i>` (CLAIM, 190x72)
  - active and not reached: a blue `Progress_<i>` ProgressBar (value = min(progress, target), max = target) with a "p/target" caption
  - otherwise: a `Locked` grey pill with `icon_lock`

The old combined `EVENT_MILESTONE` key was removed; nothing else used it.

Popup layout:
- The list is the `EventList` VBox inside a new `EventScroll` ScrollContainer with `TouchScroll`. Its height is 1180 px when there are cards and 160 px for the empty state.
- Empty/unavailable keeps the same `Empty` label and logic, now inside a centred cream `EmptyCard`.
- Parked (stashed) claim buttons are blocked until a row reuses them.
- The FirstTry card is unchanged: it was already the cream `_card` family, and its names and aids are kept.
- CLOSE only. PLAY is deliberately omitted, because no existing launch action can be reached from this popup.
- `_dhm` moved into the component; profile_screens no longer uses it.

Hero art:
- Cropped from the master with box (142,406,724,617). That is between the "Ends in" pill and the progress pill, so no master text or pill is baked in.
- Raw crop: `assets/ui/generated/events/event_weekly_hero_raw.png`. Promoted at its native 582x211 to `assets/ui/final/events/event_weekly_hero.png`. Both have `.import` files.
- The `ASSET_GENERATION_MANIFEST.json` entry `event_weekly_hero` is labelled "approved by Claude under owner-delegated authority 2026-10-31, not owner visual review".

`tests/tools/meta_snapshot.gd` now captures `3_events_empty` and `4_events_test_config` at all 5 sizes. The test-only config has:
- one active event with milestones 1/2/5: milestone 0 claimed, 1 claimable, 2 in progress at 2/5
- one upcoming event `evidence_next` starting in 2 days

Both events are valid under `_valid_weekly` (distinct ids). The shipped `data/config/events_v1.json` was not touched; it still schedules no event.

Files changed:
- scripts/ui/components/ui_event_card.gd (new)
- scripts/ui/profile/profile_screens.gd
- scripts/ui/ui_text.gd
- tests/m43_master_c010_meta.gd
- tests/tools/meta_snapshot.gd
- ASSET_GENERATION_MANIFEST.json
- assets/ui/final/events/event_weekly_hero.png(+.import)
- assets/ui/generated/events/event_weekly_hero_raw.png(+.import)
- TASKS.md

Commits: edb198e9 (code, assets, tests), 765683c1 (TASKS.md), 5ad4b110 (round 2: singular "1 level").

## Acceptance criteria
1. [x] `m43_master_c010_meta`: exit 0, 0 SCRIPT ERROR/Parse Error/FAIL. Last line: `M43 master C010 meta evidence: PASS (12/12 cases, 0 fail)`.
   - New `_m05` line:
     - `ok: SB-M43-130: empty / unavailable shown as the Empty card, no Event_* card`
   - New `_m06` lines:
     - `ok: SB-M43-130: claimable Milestone_0 shows the CLAIM button (ev:wk1:0, >= 72 px)`
     - `... active card phase meta == active`
     - `... claimed Milestone_0 -> COMPLETED pill, no claim button`
     - `... unreached Milestone_1 -> Progress_1 2.0/5.0`
     - `... When / Progress pills show the live UiText strings`
     - `... milestone row splits level target and real reward text`
     - `... hero art texture loaded`
     - `... CLOSE >= 88 px tall (88)`
     - `... CLOSE pops Events`
   - State matrix (inside `_m06`):
     - `... matrix: upcoming collapsed (no Milestone_* / Progress), When = EVENT_STARTS_IN`
     - `... matrix: ended When = EVENT_ENDED, claimable row still claims, unreached row locked`
     - `... matrix: active When = EVENT_ENDS_IN, unreached row has a bar`
     - `... matrix: reward icon mapping (single key -> bundle, multi-key -> gift box)`
     - `... matrix: target 1 -> '1 level' (singular), target 5 -> '5 levels'` (round 2)
   - `_m07`/`_m08` needed no change; the existing `ev:wk1:0` tap through the stash still works.
2. [x] `m43_master_c011_c014`: `PASS (28/28 cases, 0 fail)`. `m47_touch_r01_mobile_ux`: `PASS (14/14 cases, 0 fail)`. Its `Event` matches are only `InputEvent*`, and it does not inspect the events list, so it was not changed.
3. [x] `m22_026_texture_budget`: `M22-026 TEXTURE BUDGET: PASS`. The budget was not changed.
4. [x] `ui_event_card.gd` exists, and `grep -n UiEventCard scripts/ui/profile/profile_screens.gd` shows the preload plus `UiEventCard.build(v, claim)` in `refresh_events`. The `phase` handling (active/upcoming/ended `match`, `upcoming` early return, `phase == "active"` bar) is in the component. The state matrix passes (criterion 1).
5. [x] The grep for `Spring Garden|Big Gift|Gift\b` over the two files has one hit: the pre-existing Comeback doc comment at profile_screens.gd:541 ("Hearts, Daily, Gift, Tasks, Events"). It is not event-card text and has no illustrative master text. `git diff main..HEAD -- data/config/events_v1.json` is empty.
6. [x] `meta_snapshot.gd` was run with the rendering driver (no `--headless`). It printed `META_EVIDENCE CLEAN (0 rejected)`, exit 0. The 23 PNGs are in `factory/jobs/078-m43-events-rebuild/evidence/`, including `3_events_empty_*` and `4_events_test_config_*` at 1080x1920, 1080x2160, 1170x2532, 1290x2796 and 1536x2048.
   - The 1080x1920 configured capture shows: the title EVENTS + X; the blue hero card with the gold WEEKLY CLEANING EVENT title; the fountain art with "Ends in 6d 22h 0m" (clock icon, top-right) and "Levels cleared this week: 2" (bottom); three rows (SB bundle "1 level / SB x50" COMPLETED, card pack "2 levels / Card Pack x1" CLAIM, bot parts "5 levels / Bot Parts x1" with a blue bar and 2/5); the info strip with the rule; the grey collapsed upcoming card with "Starts in 2d 0h 0m"; the start of the First-Try card (the list scrolls); and CLOSE.
   - The empty capture shows a centred cream card, "No event right now. Check back soon!", and CLOSE.
   - I compared the captures with the master by eye; the master's text values are illustrative. Differences:
     - no leaf decorations by the title, and no PLAY button (deliberate)
     - the stopwatch is the existing blue `icon_clock`, not the master's gold one
     - the upcoming card uses the real weekly title and the greyed weekly hero, not "Spring Garden" with its caption pill
     - the countdown uses the existing `TIME_DHM` format ("6d 22h 0m", not "3d 14h")
     - the progress value is not yellow
     - the hero art is a crop, so the robot's sprout is cut at the top edge
     - the reward icons are the existing bundles, not the master's gift boxes
     - the check badge is the existing blue `icon_check`
     - the lock pill only appears for ended events, so the configured capture does not show it (the matrix test covers it)

     Structure, order and palette match.
7. [x] `assets/ui/final/events/event_weekly_hero.png` and `.import` exist, and the raw crop and its `.import` are under `assets/ui/generated/events/`. `grep -n event_weekly_hero ASSET_GENERATION_MANIFEST.json` finds the entry at line 314, with the source, crop_box, paths and delegated-authority label.
8. [x] `git diff --cached --check` was clean before both commits. `"$GODOT" --headless --path <worktree> --quit` printed no parse/script errors; the only output is the usual "resources still in use at exit".
9. [x] `grep -n SB-M43-130-REBUILD TASKS.md`:
   - line 65 now reads `- DONE SB-M43-130-REBUILD — ... (factory 078, edb198e9) ...`, with LOCAL_PASS evidence, "CLAUDE_PEER_REVIEW pending in factory" and the delegated visual label. It also notes that PLAY is omitted and that no event is scheduled.
   - the SB-M43-130 entry (line 1218) gained a DONE note.
10. [x] `grep -rln "open_events|refresh_events|Event_|EventList|EVENT_MILESTONE" tests` returns `m43_master_c010_meta.gd`, `tools/meta_snapshot.gd` and `tools/m22_026_texture_measure.gd`. All three were run:
    - `m43_master_c010_meta` passed (criterion 1).
    - `meta_snapshot` printed CLEAN (criterion 6).
    - `m22_026_texture_measure.gd -- --out=<scratch>` (headless) exited 0 with no SCRIPT ERROR/Parse Error.

## Validation
Round 2 re-ran only `m43_master_c010_meta` (PASS 12/12, 0 fail) and `m43_master_c011_c014` (PASS 28/28), plus `meta_snapshot` (rendering): META_EVIDENCE CLEAN (0 rejected).

Round 1 runs:
All runs used Godot 4.7.2 (`$GODOT` from the prompt) in the worktree:
- `--headless -s res://tests/m43_master_c010_meta.gd`: LOCAL_PASS (12/12, 0 fail)
- `--headless -s res://tests/m43_master_c011_c014.gd`: LOCAL_PASS (28/28)
- `--headless -s res://tests/m47_touch_r01_mobile_ux.gd`: LOCAL_PASS (14/14)
- `--headless -s res://tests/m22_026_texture_budget.gd`: LOCAL_PASS
- `--headless -s res://tests/tools/m22_026_texture_measure.gd -- --out=<scratch>`: exit 0, no script errors
- `-s res://tests/tools/meta_snapshot.gd -- <job>/evidence` (rendering): META_EVIDENCE CLEAN (0 rejected)
- `--headless --import`: imported the new hero PNGs
- `--headless --quit`: no parse/script errors
- `git diff --cached --check`: clean

The pre-existing and editor `.import`, `.uid` and `project.godot` churn was left uncommitted, as instructed; this includes `ui_event_card.gd.uid`, matching the other component `.uid` files, which are untracked. AGENTS.md and docs/ do not describe the old Events layout (grep for EventList/EVENT_MILESTONE/open_events/refresh_events found nothing), so neither was changed.

## Log
### Round 1
- Cropped and promoted the weekly hero from the master and added the manifest entry.
- Wrote `UiEventCard`: three phases, milestone row states, reward icon map and rule strip.
- Rewired `open_events`/`refresh_events` to use it inside a TouchScroll `EventScroll`. The claim buttons still go through `_button(p, stash, ...)` via a callable, and stashed buttons are blocked.
- Made the empty state a centred cream card.
- Replaced `EVENT_MILESTONE` with `EVENT_MILESTONE_LEVELS`.
- Extended `_m05` and `_m06` and added the state matrix.
- Changed `meta_snapshot.gd` so Events is captured at all 5 sizes, with an active event and an upcoming event.
- Over two capture passes, centred the empty card after the first pass showed it pinned to the top.
- Ran the named suites and updated TASKS.md.

### Round 2
Review findings:
- review-code #1 and review-rules #1: a target-1 milestone read "1 levels". Fixed: `_row` now picks a new `EVENT_MILESTONE_LEVEL_ONE` ("1 level") when the target is 1, following the TASK_WIN_ONE/TASK_WIN_N pattern. In the state matrix, the first milestone's target is now 1, and a new assertion checks "1 level" and "5 levels". Committed as 5ad4b110.
- review-code note on the 1180 px scroll min-height: re-captured all sizes. `META_EVIDENCE CLEAN (0 rejected)` means `_shot` found the frame inside the viewport and every label fitting, at all 5 sizes. In 4_events_test_config_1080x1920 (shortest relative to its width, together with 1536x2048, which I checked in round 1), CLOSE sits inside the frame at y~1560-1640 of 1920. The list scrolls (the First-Try card is cut off at the bottom of the list); nothing overflows the frame. I left the height unchanged.
- review-code note on `_dhm` being private but used by tests: left as is (optional note; it mirrors the old profile_screens helper name).
- review-tests: PASS, no findings.
- Re-ran m43_master_c010_meta (12/12) and m43_master_c011_c014 (28/28), and re-captured evidence. The 1080x1920 configured PNG now shows "1 level".
