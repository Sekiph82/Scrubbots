# SB-M42 HOME OWNER REVISION V03 — IMPLEMENTATION PROMPT

Status: ACTIVE
Supersedes: Home master-convergence V02 for the specific owner revisions recorded in V03
Repository: `Sekiph82/Scrubbots`
Branch: `main`

## Authority

Read first:

1. `CLAUDE.md`
2. root `TASKS.md` READ ONLY
3. `coordination/OWNER_M42_HOME_VISUAL_REVISION_V03.md`
4. `coordination/sessions/M42-C001/audits/SB-M42-HOME-MASTER-CONVERGENCE_V02_CHATGPT_AUDIT_V01.md`
5. `coordination/sessions/M42-C001/SB-M42-HOME-MASTER_ACTUAL_VISUAL_GAP_REGISTER_V01.md`
6. `docs/MASTER_UI_SYSTEM.md`
7. `docs/HOME_UI_ASSET_PLAN.md`
8. `assets/ui/HOME_ASSET_MANIFEST.json`

The V03 owner decision is authoritative where it conflicts with V02 composition choices.

Do NOT edit root `TASKS.md`, owner decision files or ChatGPT audit/criteria files.

## Mission

Implement the V03 owner revisions in ONE pass, without mutating approved production PNG bytes.

Primary goals:
- stronger visible city;
- grounded Whispering Park portal;
- one-platform Scrubby composition;
- no idle face/arm overlays;
- narrower profile card with larger pop-out portrait;
- remove duplicate top Settings button;
- compact Bot Parts and Gift Meter text;
- 3+3 side cards with SHOP / PLAY / CARDS EXCHANGE lower action row;
- smaller Play CTA;
- thinner reward track with only 1 / 5 / 10 / 25 / 100;
- bottom nav flush to screen bottom;
- Home buttons disappear whenever any modal/settings surface is open.

## A. Profile / top HUD

Implement all of the following:

1. Narrow `ProfileCard` horizontally. Do NOT simply scale the whole card down.
2. Make `ProfilePortrait` substantially larger.
3. Create a pop-out portrait:
   - `ProfileAvatarFrame` behind;
   - `ProfilePortrait` in front;
   - portrait may extend above the frame;
   - no clipping of the portrait;
   - frame remains visibly readable around the lower/body portion.
4. Remove `MenuButton` / top-right Settings hamburger entirely.
5. Settings remains accessible only from bottom navigation.
6. Keep ProfileName live.
7. Keep Level as its own live badge/value.
8. Change Bot Parts presentation to only the live numeric ratio, e.g. `0/250`.
9. Do not show the literal `BOT PARTS` label beside Level or in the progress caption.

## B. Gift Meter

1. Keep HOME-051 emblem and HOME-054 crate.
2. Remove the long caption:
   `GIFT METER N/1000 · NEXT GIFT AT X`.
3. Show only `N/1000` in/over the meter.
4. Keep the actual Gift Meter state/service unchanged.
5. Do not restore Event Points or event timer semantics.

## C. City background

This is a major visual gate.

The final 1080x2160 screenshot must unmistakably look like a CITY, not a sky field.

Required:

1. HOME-002 `home_bg_city_far` visibly contributes building masses.
2. HOME-003 `home_bg_city_mid` visibly contributes building masses.
3. Buildings must be visible:
   - left of the portal;
   - right of the portal;
   - around/above the portal crown.
4. Reduce empty sky.
5. Recompose HOME-004 `home_bg_street_foreground` upward.
6. The visible street/foreground should begin immediately above the bottom-nav dock.
7. Bottom nav must be flush to screen bottom.
8. No extra city/street strip may remain below the nav.
9. City + portal + main platform + foreground must share a coherent perspective.

Do not stretch city textures into visibly broken proportions.

If the existing approved HOME-001..004 layers cannot create an acceptable city composition after reasonable placement/crop:
- if an authorized image-generation capability is available, create a replacement CANDIDATE only under `assets/ui/generated/`;
- the candidate may be a full lower-city/street image containing city architecture + street perspective;
- never overwrite `assets/ui/final/`;
- never promote it without owner approval;
- record `CITY_ASSET_CANDIDATE_OWNER_REVIEW_REQUIRED`.

## D. Whispering Park portal

1. Reposition/scale the portal together with the city layers.
2. Portal may not float in empty sky.
3. Portal base must visually sit on the world/street plane.
4. The main platform must sit naturally in front of/within that portal base.
5. `WHISPERING PARK` and `AREA N` remain live/localizable.
6. Make the live title treatment look integrated into the arch, not like a detached floating capsule.
7. Do not hardcode Area 1 as durable gameplay truth; preserve the existing localizable/default presentation seam if no canonical area model exists.

## E. One platform only

Owner decision:

- HOME-010 `home_platform_main` ACTIVE.
- HOME-011 `home_platform_top` RETIRED FROM ACTIVE HOME PRESENTATION.

Requirements:

1. Remove HOME-011 from the active runtime composition.
2. Preserve its file bytes/history unchanged.
3. Scrubby's feet stand directly on HOME-010.
4. No stacked/two-disc look.
5. Main platform is the single physical support under Scrubby.
6. Update presentation accounting honestly with `OWNER_RETIRED` or equivalent for HOME-011.

## F. Disable idle face / arm overlays

Owner decision:

- HOME-031 blink overlay: owner-disabled.
- HOME-032 brush-arm overlay: owner-disabled.

Requirements:

1. Remove/disable the idle timer/state switching that shows alternate face/arm art.
2. Scrubby must remain visually stable while Home is idle.
3. Preserve the PNG files unchanged.
4. Presentation accounting must mark them `OWNER_DISABLED` / `OWNER_RETIRED`, not pretend they are active.
5. Tests must wait through enough simulated idle time to prove neither overlay becomes visible.

## G. Side cards and lower action row

Change side columns to:

LEFT:
- WIN STREAK
- GIFTS
- COLLECTION

RIGHT:
- NO ADS
- DAILY
- TASKS

Move:
- SHOP -> left of Play
- CARDS EXCHANGE -> right of Play

Create one coherent lower row:

`SHOP | PLAY | CARDS EXCHANGE`

Requirements:
- Shop keeps its current disabled/future-destination semantics if it is not live yet.
- Cards Exchange keeps its current live popup behavior.
- labels remain full/live/localizable;
- cards remain >=88 px actionable when enabled;
- do not let Shop/Cards cards overlap Play.

## H. Play CTA

1. Reduce current Play button width and height.
2. Reduce PLAY font size proportionally.
3. Keep Play visually dominant, but not oversized.
4. Keep live LEVEL/CONTINUE subtitle smaller and secondary.
5. Replace the current blue-square-inside-green-button appearance with a simple native white play triangle.
6. If HOME-078 is no longer visibly used:
   - preserve its bytes/history;
   - mark it `OWNER_RETIRED` in presentation accounting;
   - do not fake its visibility merely to satisfy old tests.

## I. Win Streak reward track

Owner simplification:

1. Reduce track panel height substantially.
2. Keep the five gift objects.
3. Under gifts show ONLY:
   `1`, `5`, `10`, `25`, `100`.
4. Remove plus signs.
5. Remove per-step Scrub Bucks icons.
6. Remove per-step `WIN 1 / WIN 2 / ...` text.
7. Preserve actual current/reached/future progression state through styling if needed.
8. HOME-087 repeated per-step SB icon reuse is owner-retired from active track presentation.
9. If TrackBadge remains, size it to the thinner track.

## J. Bottom nav

1. Keep the five bottom-nav buttons.
2. Only bottom Settings remains visible.
3. Dock is flush to the bottom edge.
4. No background/street strip below.
5. HOME remains clearly selected.
6. Keep current `RANKS` wording for this pass.

## K. Modal / overlay defect

Current defect is visible in Gifts, Daily and Settings screenshots:
Home shortcut buttons remain above the new panel.

This is a functional visual-layer bug, not just styling.

Implement a deterministic modal state.

### Required modal behavior

When ANY of these is open:
- Gift Bar/Gifts popup;
- Daily popup;
- Cards Exchange popup;
- Settings panel;

the Home ACTION controls disappear and cannot receive input.

At minimum hide/disable:
- LeftShortcutColumn;
- RightShortcutColumn;
- lower SHOP/PLAY/CARDS action row;
- reward-track interactive surface if actionable;
- BottomNav.

Decorative Home background/world may remain visible/dimmed behind the modal.

Requirements:
1. modal/panel always renders above the Home decorative background;
2. no Home card/button may visually sit on top of the modal;
3. hidden Home controls receive no pointer/touch/keyboard input;
4. closing modal restores the exact previous Home action controls;
5. back closes the top modal first;
6. opening Settings through bottom nav triggers the same modal-obscured state;
7. no double-modal interactive leakage.

Suggested architecture:
- `HomeScreen.set_modal_active(bool)` or equivalent;
- HomePopup open/closed drives it internally;
- app root settings open/close calls the same Home modal state;
- modal z-index may also be raised, but z-index alone is insufficient because owner explicitly wants Home buttons to disappear.

## L. Presentation accounting revision

V02 assumption “every approved art must be visibly active” is superseded by owner V03 retirements.

The presentation model must support explicit modes such as:
- `STATIC`
- `REUSE`
- `OWNER_RETIRED`
- `OWNER_DISABLED`

At minimum retired/disabled:
- HOME-011
- HOME-031
- HOME-032
- HOME-087
- HOME-078 if native triangle replaces it

Do not modify approved PNG bytes.

Do not change manifest approval history unless the existing schema has an explicit supported retirement field. If not, keep manifest hashes intact and express retirement in the presentation-accounting layer/tests.

## M. Snapshot / visual loop

Use the existing Home snapshot harness.

Required snapshots:
- 1080x2160
- 1290x2796
- 1080x1920
- 1536x2048

Also capture modal evidence at 1080x2160:
- Gifts open
- Daily open
- Cards Exchange open
- Settings open

Store under:
`coordination/sessions/M42-C001/runtime_evidence/home_v03/`

If vision is available:
- visually inspect at least the 1080x2160 Home;
- explicitly verify visible city, portal grounding, one platform, no idle overlay, Shop/Play/Cards row, thin reward track, nav flush-bottom;
- visually inspect at least one modal screenshot and verify Home action buttons are absent.

If vision is unavailable, say so and do not claim visual pass.

## N. Tests

Add/update focused tests for:

1. profile card width contract;
2. portrait larger than V02 and in front of frame;
3. portrait overflow not clipped;
4. no top MenuButton;
5. only bottom Settings entry;
6. Bot Parts caption exactly numeric ratio only;
7. Gift Meter caption exactly numeric ratio only;
8. city layers have non-zero visible rects and occupy intended region around portal;
9. street foreground upper boundary tied to nav top region;
10. nav flush to bottom;
11. HOME-011 owner-retired and not visible;
12. Scrubby feet on HOME-010;
13. HOME-031/032 never show during idle simulation;
14. 3+3 side-card membership;
15. Shop and Cards Exchange are children of lower action row;
16. Play smaller than V02 threshold;
17. native white triangle present;
18. HOME-078 retirement accounted if unused;
19. reward values exactly 1/5/10/25/100;
20. no per-step plus sign;
21. no per-step SB icons;
22. no per-step WIN copy;
23. HOME-087 retired from active reward presentation;
24. Gifts modal hides Home action controls;
25. Daily modal hides Home action controls;
26. Cards Exchange modal hides Home action controls;
27. Settings panel hides Home action controls;
28. modal close/back restores Home controls;
29. no hidden Home control receives input while modal active;
30. responsive viewport matrix still passes >=88 px touch targets.

Required runs:
- `godot --headless --path . -s res://tests/m42_assets.gd`
- `godot --headless --path . -s res://tests/m42_home.gd`
- `godot --headless --path . -s res://tests/m42_home_composition.gd`
- add a V03-focused test if cleaner than overloading existing tests
- `godot --headless --path . -s res://tests/m42_navigation.gd`
- `godot --headless --path . -s res://tests/run_tests.gd`
- `git diff --check`

Require exit 0 and zero SCRIPT ERROR.

## O. Approved asset integrity

Before implementation record the current Git blob SHAs of all owner-approved production PNGs.

After implementation prove:
- no approved PNG bytes changed;
- no approved image silently overwritten;
- any generated city candidate is under generated/ only.

## P. Log / handoff

Create:
`coordination/sessions/M42-C001/task_logs/SB-M42-HOME-OWNER-REVISION-V03.md`

Include:
- baseline SHA;
- changed files;
- presentation-mode counts;
- retired/disabled asset IDs;
- city/background implementation result;
- whether a city candidate was required;
- modal-state architecture;
- snapshot evidence paths;
- focused/root test results;
- approved blob integrity proof;
- final implementation SHA.

Do NOT claim owner visual acceptance.

Finish with:

`AWAITING_CHATGPT_AUDIT / M42 HOME OWNER REVISION V03`
