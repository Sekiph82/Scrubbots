# SB-M42 HOME COMPOSITION REMEDIATION — IMPLEMENTATION PROMPT V01

## Role

You are Claude Code implementing the M42 Home composition remediation for ScrubBots.

Repository: `Sekiph82/Scrubbots`
Branch: `main`

ChatGPT is the sole writer of root `TASKS.md`, owner decision files and ChatGPT audit files. Do not edit them.

## Read first

- `CLAUDE.md`
- `TASKS.md` read-only
- `docs/MASTER_UI_SYSTEM.md`
- `docs/HOME_UI_ASSET_PLAN.md`
- `assets/ui/HOME_ASSET_MANIFEST.json`
- `coordination/OWNER_M42_HOME_ART_COMPLETE_APPROVAL_V01.md`
- `coordination/sessions/M42-C001/audits/SB-M42-HOME-COMPOSED_VISUAL_AUDIT_V01.md`
- canonical owner reference: `assets/art/references/_owner_inbox/Game Screens/main screen.png`

## Context

All 49 unique generation-required Home ART files are owner-approved and SHA-256 pinned. The manifest promotion is already independently audited. Do not regenerate or modify any approved PNG.

The first real runtime screenshot exposed a composition/integration defect. Current `home_screen.gd` makes only 16 direct visual mappings (6 LAYER_ART + 10 ICON_ART) even though the manifest contains 50 approved ART entries. Many approved assets are therefore hash-valid but never actually presented.

This task is not an asset-generation task. It is a production Home composition/binding/layout remediation.

## Required outcome

The running Home screen must visually compose the already-approved assets into the intended layered Home design while preserving:
- native Godot interaction controls;
- live/localizable text and values;
- canonical Economy V1 semantics;
- responsive/safe-area behavior;
- owner-approved PNG bytes exactly unchanged.

## Mandatory fixes

### A. Build a real central-world composition

Do not keep `home_platform_main` and Scrubby as two same-center full-rect TextureRects.

Create an explicit layered central-world scene/control hierarchy with independently positionable decorative nodes for at least:

- HOME-006 `home_arch_whispering_park`
- HOME-007 `home_arch_decor`
- HOME-010 `home_platform_main`
- HOME-011 `home_platform_top`
- HOME-013 `home_prop_cleaning_bucket`
- HOME-014 `home_prop_hose`
- HOME-015 `home_prop_foam_cluster`
- HOME-016 `home_prop_puddles`
- HOME-018 `home_prop_wet_floor_sign`
- HOME-019 `home_prop_keep_clean_sign`
- HOME-020 `home_prop_cleaning_equipment`
- HOME-021 `home_prop_neon_details`
- HOME-022 `helper_bot_floor_cleaner`
- HOME-023 `helper_bot_cart`
- HOME-024 `helper_bot_alt_pose`
- HOME-026 `scrubby_home_pose`

The visual hierarchy must read correctly:
background -> distant/mid environment -> arch/banner/world -> platform/shadow plane -> helper/environment props -> Scrubby -> optional foreground details/UI.

Scrubby must visually stand on the platform. The platform may not cut through his torso/waist.

Use the owner reference as art direction for balance, scale and hierarchy. Do not flatten the reference into the shipping UI.

### B. Area title and number must be live

Implement the manifest LIVE regions:
- HOME-008 `home_area_title`
- HOME-009 `home_area_number`

Keep them as live Godot Labels, not baked into art. Use canonical/localizable UI text. If current product truth is Whispering Park / Area or Level 1, source the displayed value from current canonical state rather than hardcoding an irreversible content model.

### C. Top profile art

Integrate:
- HOME-027 `scrubby_portrait`
- HOME-034 `profile_avatar_frame`
- HOME-035 `profile_rank_badge`

Keep level, Bot Parts and any profile values live. Do not replace live progress with baked art.

### D. Gift Meter art

Integrate:
- HOME-051 `gift_meter_emblem`
- HOME-054 `gift_meter_reward_crate`

The progress bar/value/next milestone remain live native UI. Gift Meter must not become Event Points or a timer.

### E. Play CTA art

Integrate HOME-078 `play_button_frame` as the visual frame for the native PLAY/CONTINUE control.

Requirements:
- button remains a real Godot Button or equivalent accessible native input target;
- label remains live/localizable;
- approved PNG is decorative only;
- no bitmap-only interaction;
- press/disabled state remains visible and functional.

### F. Win Streak reward-track art

Integrate:
- HOME-086 `win_streak_reward_badge`
- HOME-087 `win_streak_reward_scrub_bucks_icon` reuse
- HOME-090..094 reward gift art

Keep reward amounts and win positions live:
+1 / +5 / +10 / +25 / +100 SB.

Do not reintroduce Stars. Reached/current/future states must remain readable.

### G. Bottom navigation icons

Integrate:
- HOME-101 Events
- HOME-102 Robots
- HOME-103 Home
- HOME-104 Leaderboard
- HOME-105 Settings

Labels remain live. HOME/SETTINGS behavior must stay exactly as currently implemented; future destinations stay disabled.

### H. Shortcut readability

The runtime screenshot visibly clips labels such as:
- WIN STREAK
- COLLECTION
- CARDS EXCHANGE

Fix the layout/component behavior so canonical full labels are readable at the 1080x2160 reference viewport and across the M42 viewport matrix.

Do not solve this by baking text into icons or silently replacing canonical labels with unexplained abbreviations.

Disabled/future shortcuts may be visually dimmed but must remain legible over the detailed background.

### I. Approved-art presentation accounting

Add a deterministic presentation-accounting seam for all 50 approved ART manifest entries.

For each approved ART slug, tests must prove one of:
1. statically presented by a Home node in the default Home composition;
2. intentionally state/animation-specific and mapped to a concrete Home node/state;
3. HOME-087 declared reuse of HOME-042.

Do not accept `HomeArtBinder.summary() == {"APPROVED_BOUND": 50}` by itself as proof of on-screen integration.

Optional idle layers HOME-031/HOME-032 may be state/animation-specific, but they must have an explicit presentation destination if retained in the production manifest.

No approved static Home asset may remain orphaned without an explicit reason.

### J. Responsive composition

Validate at least:
- 1080x2160
- 1170x2532
- 1290x2796
- 1080x2400
- 1440x3200
- 16:9 portrait/tablet cases already covered by M42

At every required viewport:
- no clipped shortcut labels;
- no decorative layer covering live controls;
- no off-screen controls;
- >=88 px touch targets;
- Scrubby/platform relationship remains coherent;
- Play CTA and bottom nav remain usable;
- profile/currency/Gift Meter remain readable;
- no dynamic text is baked into art.

## Asset immutability gate

Before implementation, record blob SHAs for all 49 unique approved PNG paths.
After implementation, verify every blob SHA is identical.

No image generation.
No PNG edit.
No recompression.
No rename/move.
No replacement.

If any approved PNG would need alteration, STOP and report the blocker instead.

## Tests

Update/add focused M42 Home tests so they verify actual presentation mappings, not just binder availability.

Required runs:

- `godot --headless --path . -s res://tests/m42_assets.gd`
- `godot --headless --path . -s res://tests/m42_home.gd`
- `godot --headless --path . -s res://tests/m42_navigation.gd`
- `godot --headless --path . -s res://tests/run_tests.gd`
- `git diff --check`

Require exit 0 and zero SCRIPT ERROR. Report the known baseline corrupt-image engine ERROR lines separately if still present.

## Evidence

Write:
`coordination/sessions/M42-C001/task_logs/SB-M42-HOME-COMPOSITION-REMEDIATION.md`

Include:
- baseline HEAD;
- implementation SHA;
- exact changed source/test files;
- pre/post approved PNG blob verification;
- presentation-accounting result for all 50 ART entries;
- viewport matrix results;
- focused/root test results;
- confirmation that `TASKS.md`, owner approval artifacts and ChatGPT audits were untouched.

Commit and push to `main`.

## Stop condition

Do not claim visual owner acceptance.

Finish with:

`AWAITING_CHATGPT_AUDIT / M42 HOME COMPOSITION REMEDIATION`

After ChatGPT audit, the owner will run the game again and supply a new runtime screenshot for final SB-M42-011 / SB-M42-017 visual review.
