STATUS: READY

# Build: 192-events-art-ui (SB-TF-12): 24 native Events screens, coach-mark tutorials, Events PNG art

## Summary
Branch `factory/192-events-art-ui` (worktree `C:/Users/sekip/AppData/Local/Packages/Claude_pzs8sxrjxfjjc/LocalCache/Local/ScrubBotsFactoryWT/192-events-art-ui`). It has 6 commits on top of f9af68e8:
- Round 1:
  - b7c45704: art intake and the tutorial steps data file.
  - c2215377: the native UI.
  - e2f62634: tests, CI and docs.
- Round 2:
  - be9fa84c: kit pieces and reference-sampled colours.
  - 501e1bed: the look rework and the bubble placement fix.
  - 5e2bc89a: the kit star on the progress rail.

All 24 events now have a native Godot event screen with per-event coach-mark tutorials over the real details screen.

What is drawn natively:
- Glossy panels in each event's own reference-sampled colour, with bright gold rims.
- A title ribbon with curled, notched ends, a glossy band and a big bold outlined title.
- Pills, buttons (a big glossy green button with a play arrow), the progress rail and nodes, the gold focus glow, and every text in TR and EN.

What stays raster:
- The event scene, the event icon and key props.
- 7 tiny shared kit pieces: logo, laurel, checkered flags, sparkle lines, star.
- The approved roster robots and the existing real reward icons. No gems, crystals or coins were copied.

Changed files:
- `tools/events_art_intake.py` (new). It only reads `C:\Users\sekip\Desktop\ScrubBots Events PNG\` and writes:
  - `scenes/` (24 × 640 px lossy WebP)
  - `props/` (47, ≤256 px lossy WebP)
  - `icons/` (24 × 256 px 8-bit PNG, replacing the old icons)
  - `kit/` (6 kit pieces ≤128 px plus `logo.webp` at 520 px)

  Two things to know about it:
  - The kit pieces are named by what they depict, because several file names in ui_kit/common are swapped. For example, `icon_close_button.png` is actually a star and `laurel_right.png` is the team icon.
  - The logo is a downscaled copy of the repo's `branding/logo_colorful.png`, which is 2172 px and 1.3 MB.
- `data/config/events_v02_tutorials.json` (new). Per event it holds:
  - the 172 steps from all 24 steps.json files, with `source` removed
  - TR/EN titles from event_titles.json
  - `accent` (the ribbon colour)
  - `panel` (the dominant panel fill sampled from that event's reference tutorial_01..03)
  - the props list
- `scripts/ui/events/events_v02_ui.gd`:
  - Events-page cards follow the master layout.
  - Full-screen details:
    - Top: logo, ribbon (with checkered flags for race and royale), a timer pill between sparkle lines, and a goal banner.
    - Stage: the real level Board at 430 px (about 45% of the width) next to a large host robot with a prop.
    - Sections: Team (rows plus a size badge, and one short CPU line), Standings (top 5, Royale stage boxes, bracket round boxes), Map, Progress rail (done nodes, the star on the current node, open nodes, the last reward icon), and reward chips.
    - The big green JOIN button.
    - Section headers are glossy tabs between laurels.
  - The long rule text (full CPU note, your team share, opponent total, gain) moved to the (i) Event rules popup. That popup's HOW IT WORKS button replays the walkthrough.
- `scripts/ui/events/event_tutorial.gd`: coach marks for every step.
  - The screen dims with a hole over the target, which is scrolled to the middle.
  - A gold focus frame pulses, except under Reduced Effects.
  - The speech bubble sits above or below the target with its tail pointing at it. It slides to the nearest free spot so it never covers the focused target or any section header or title text.
  - The big glossy green button carries the localized button text; the last step is Start/Başla, which joins a joinable event and closes.
  - An `n / N` step pill sits between sparkle lines, and X skips.
- `scripts/ui/ui_text.gd` and `ui_text_tr.gd`: `EV2_NAME_*` now matches event_titles.json. Added the section keys, `EV2_SIZE_BADGE`, `EV2_TEAMMATES`, `EV2_JOINED_SHORT`, `EV2_CPU_SHORT`, `EV2_OPPONENT` and `EV2_RULES`.
- Tests and CI:
  - new `tests/sb_tf12_events_art_ui.gd` and `tests/tools/sb_tf12_events_capture.gd`
  - updated `tests/ev02_events_ui.gd`, `tests/sb_tf03_home_profile.gd`, `tests/m50_accessibility_audit.gd`, `docs/ACCESSIBILITY.md`
  - `.github/workflows/android-family-first10.yml` runs `sb_tf12_events_art_ui` with the exact guard `SB-TF-12 events art/tutorial evidence: PASS (5/5 cases, 0 fail)`; the ev02 suites are kept.

Unchanged: the Level 30 unlock, all economy and payout logic, the hero PNGs, TASKS.md, project.godot and main.tscn.

### Added Events art (MiB, final)
| category | files | repo source | imported (ships) |
|---|---|---|---|
| scenes | 24 webp | 1.49 | 1.38 |
| props | 47 webp | 0.59 | 0.57 |
| kit (logo, laurel, 2 flags, 2 sparkle lines, star) | 7 webp | 0.05 | 0.05 |
| icons (replaced; the old set was about 1.3 MiB) | 24 png | 0.52 | 0.75 |
| **total** | | **2.65** | **2.75** |

This is under the ~4 MiB cap; suite t02 measures it as 2.65 MiB against a 4 MiB budget. No storyboard PNG, raw kit PNG or baked text is shipped.

## Acceptance criteria
1. [x] **Asset intake:** downscaled, lossy, only pieces that are used, and the MiB reported in the table above. Suite t02 checks:
   - every scene (640 px), icon (256 px), prop, sampled colour and the 7 kit pieces exist
   - scenes, props and kit import lossy
   - the 2.65 MiB budget
   - no storyboard PNG ships
2. [x] **Native per-event screens, no baked text:** sb_tf12 t03 runs 24/24 details screens in EN and 24/24 in TR. Each has every texture present, the native title equal to the data title, and every coach section visible. ev02 u04 covers all 24 details (JOIN, CPU line, reward steps) plus one real claim.
3. [x] **Tutorials from steps.json, data in the repo, first open plus replay:**
   - sb_tf12 t04: 172/172 steps in EN and 172/172 in TR. Each focuses a visible on-screen target, with the frame on its real rect.
   - Bubble, button and `n / N` texts come from the data.
   - New in round 2: the bubble rect intersects neither the focused rect nor any on-screen section header or ribbon title label (`_bubble_clear`), checked on all 344 steps.
   - ev02 u03: first visit, all steps, Start, back to details, and no repeat on the second visit.
   - ev02 u05: coach over the real details, X skip, and Reduced Effects (no pulse, meter jumps).
   - sb_tf12 t05: (i) opens the rules popup with the full goal text, and HOW IT WORKS replays the walkthrough over the details.
4. [x] **Home event buttons use the Events PNG icons:** sb_tf03 t07 asserts the active-event button icon is `events/icons/<id>.png` at 256 px.
5. [x] **Robots, effects, lazy loading:** no robots are drawn into the art (roster PNGs only). Level 30 gate: ev02 u01. Reduced Effects: ev02 u05 and the m50 ledger. Lazy textures: sb_tf12 t05.
6. [x] **Evidence:** final set in `C:/Users/sekip/Desktop/ScrubBots/factory/jobs/192-events-art-ui/evidence/round2_final/`. All captures are 1170x2532 from the real app on throwaway saves.
   - `side_by_side/`: 47 images, each 2340x2532, reference `tutorial_XX.png` on the left and the native TR render on the right. They cover every step of clean_team_treasure, scrub_sprint, golden_brush_championship, master_cleaner_quest, color_scrub_rush and scrubbots_royale.
   - `screens/`: EN and TR details plus every step for those 6 events, and the Events page in EN and TR.
   - `contact_sheet_step1_ref_vs_native_24.png`: step 1 of all 24 events, reference next to native.
   - `contact_sheet_details_24_tr.png`: all 24 details screens.

   Older sets: `evidence/` holds round 1 and `evidence/round2/` an intermediate render. Nothing was deleted.

   Fidelity, honestly: each event now has its own palette, scene, ribbon, laurels and flags, logo, glossy panels and green button in the storyboards' composition. They are still not pixel-identical. The references contain painted extras (illustrated bracket and stage diagrams, painted reward icons, extra robots) that are approximated natively or replaced by real reward icons.

## Validation (LOCAL_PASS, Godot 4.7.2 headless, final code; every run exited 0 with no SCRIPT ERROR or Parse Error)
- `sb_tf12_events_art_ui`: PASS (5/5, 0 fail).
- `ev02_events_ui`: PASS (6/6).
- `sb_tf03_home_profile`: PASS (11/11).
- `sb_tf07_ad_placements`: PASS (14/14).
- `m50_accessibility_audit`: PASS (11/11).
- `ev02_events_v02` (10/10) and `m60_release_gates` (6/6) passed on round 2 code, before the final one-line star-node commit.
- Capture tool, windowed: TR with all events and steps produced 197 shots; EN with 6 events produced 72 shots. No errors.
- `git diff --cached --check` was clean for each commit.

## Notes for the orchestrator
- I did not edit TASKS.md and did not push.
- I restored the Godot import churn (project.godot and about 620 tracked `.import` files) file by file, so no tracked file is modified.
- About 720 untracked Godot-generated files (`*.uid`, missing `*.import`, `docs/*.translation`) are still in the worktree, because the order was not to delete anything. Removing the worktree clears them.

## Log
### Round 1
- Setup, intake, data file, native UI and tutorials, tests, CI and evidence.
- Paused BLOCKED once on a denied `rm -rf` of a scratch folder. After that I used a new folder for every capture run and deleted nothing.

### Round 2 (orchestrator visual review: REWORK)
1. **Generic dark look.** I sampled each event's panel colour from its reference tutorial_01..03 into the data file, using the dominant saturated fill below the title. The ribbon uses the per-event accent colour. Added the Glossy panel class (gloss band, deeper lower band, 6 px bright gold rim) and glossy header tabs. The title ribbon was redrawn with curled ends (tails behind the band, a fold under it, notched tips) and an 84 px bold yellow title with a thick outline.
2. **Logo and kit pieces.** The logo comes from `branding/logo_colorful.png`, downscaled to `events/kit/logo.webp` (26 KB). Laurels flank section headers, checkered flags flank race and royale titles, sparkle lines flank the timer and step pills, and the star marks the current rail node. All 7 kit pieces together are 0.05 MiB.
3. **Composition.** The stage is now a 430 px board (about 45% of the width) next to a large host robot in the upper half. Text lines are fewer and larger (30 px rows, 26 px info), standings show the top 5, and the CPU note is one short line. The long rules moved to the (i) Event rules popup, which also replays the tutorial. The big glossy green button now has a gloss band and a play arrow, with the step pill and sparkle lines under it.
4. **Bubble covering the next header.** I rewrote the bubble placement. It now tries below and above the target and slides to the nearest spot that covers neither the focused rect nor any on-screen header or title label, with the tail pointing at the target. It re-places itself whenever the bubble's size changes. sb_tf12 t04 asserts this for all 344 steps. In clean_team_treasure step 3 the bubble now sits above the team panel, and "Etkinlik İlerlemesi" is visible.
5. **No gems.** Rewards still show only the real reward icons.
