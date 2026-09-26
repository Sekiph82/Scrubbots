# SB-M42 HOME POLISH V06 — IMPLEMENTATION PROMPT

Status: ACTIVE
Repository: `Sekiph82/Scrubbots`
Branch: `main`

## Read first

1. `CLAUDE.md`
2. root `TASKS.md` READ ONLY
3. `coordination/OWNER_M42_HOME_POLISH_V06.md`
4. `coordination/OWNER_M42_HOME_POLISH_V05.md`
5. `coordination/sessions/M42-C001/audits/SB-M42-HOME-POLISH_V05_CHATGPT_AUDIT_V01.md`
6. `coordination/OWNER_ECONOMY_REWARDS_V01.md`
7. `scripts/economy/heart_service.gd`
8. `data/config/economy_rewards_v1.json`
9. `scripts/ui/home/home_screen.gd`

Do NOT edit root TASKS.md, owner files or ChatGPT audit/criteria files.

## Mission

Implement the final V06 Home polish with a deliberately narrow scope.

### 1. Preserve locked V05 areas

Do NOT change:
- HOME-120 bytes/manifest/world transform.
- Gift Meter styling/geometry/semantics.
- Win Streak styling/geometry/semantics.
- Play size/style.
- BottomNav size/style.
- Profile card/portrait.
- shortcut icon sizes.
- modal behavior.

### 2. Ad slot + bottom stack

At 1080x2160:
- AdBannerSlot target = **100 px**.
- responsive clamp approximately **72..112 px**.
- no vertical EXPAND/FILL.
- AdMount stays empty.
- No-Ads collapse seam stays.

BottomActionStack remains bottom anchored:
PLAY -> WinStreakTrack -> BottomNav -> AdBannerSlot.

Compared with V05 canonical geometry, reducing 144 -> 100 must move:
- Play downward by ~44 px;
- track downward by ~44 px;
- nav downward by ~44 px.

HOME-120 transform must remain pixel-identical to V05/V04 values.

### 3. Scrubby scale + focus separation

Target total hero scale relative to V04 base fit = **1.24x**.
Allowed range = **1.22..1.25** only if collision clearance requires adjustment.

Keep:
- center X = 540
- soles Y = 1297

Scale about soles, upward/outward.

Add `HeroFocusShade` behind Scrubby and above WorldBackground:
- soft feathered dark navy/black elliptical/radial dimmer;
- no bright glow;
- peak alpha 0.16..0.22;
- smooth fade to zero;
- positioned below baked sign;
- should mainly darken the bright portal/world immediately behind Scrubby;
- must not noticeably darken helper bots outside the hero zone;
- no hard visible edge.

Prefer a native Godot shader / GradientTexture2D / custom-draw solution. Do not add a new raster asset unless technically necessary.

### 4. Shortcut panels

Keep exact V05 panel geometry and icon sizes.

Change only normal body visibility:
- body alpha **0.50..0.52**
- 3 px cyan outline unchanged
- restrained glow unchanged

TASKS and DAILY icon sizes MUST NOT change.

### 5. Currency / Heart pill geometry

Keep current foreground icon size (~110 px).

Reduce visible pill height about 20%:
- V05 ~84 px
- V06 target **67..70 px**

Do not shrink touch accessibility.

#### Plus design

Replace the V05 green circular plus with the owner-reference style:
- bold white plus
- dark navy outline
- cyan outer glow
- transparent background
- NO green circle

Visually place the plus **inside the pill at the right end**.

Target visible glyph:
- ~48..58 px
- centered vertically inside pill

Maintain a transparent/invisible >=88×88 hit target centered on the glyph.
Click behavior remains intent-only:
- SB: `scrub_bucks_purchase_requested`
- Hearts: `hearts_purchase_requested`
No transaction is invented.

If the owner-supplied chat attachment itself is not available to Claude, recreate this exact visual grammar natively. Do not block on missing chat-image bytes.

### 6. Scrub Bucks

- approved banknote icon unchanged.
- balance remains live inside thinner pill.
- plus glyph inside the right end of pill.
- no coin/star regression.

### 7. Hearts UI + canonical regen rule change

IMPORTANT: V06 is a new owner decision and supersedes the old 30-minute Heart regen rule.

Update canonical config:
- `hearts.regen_seconds`: **1800 -> 900**

Preserve:
- max = 5
- wall-clock authoritative timing
- offline/background/app-closed time counts
- purchase/refill semantics and prices unless unrelated tests reveal a genuine regression

Display rules:
- NEVER show `N/5` inside the pill.
- overlay current Heart count directly on the red heart icon itself.
- number is pure white, bold, strongly outlined dark navy for readability.
- e.g. at full: white `5` centered over heart icon.

Pill content is timer only:
- full hearts: display static **15:00** ready state; do not tick.
- immediately after losing/consuming one Heart from full: begin live countdown using HeartService state.
- below max: show `MM:SS` from `HeartService.seconds_to_next()`.
- at each regenerated heart, if still below max, next 15-minute interval continues correctly.
- at max, return to static `15:00`.

UI must not own authoritative timer state.
Use HeartService only.
Update Home at 1 Hz while visible, not per frame.

Update HeartService/economy focused tests so 900-second behavior is proven:
- full starts 5;
- consume => 4 and seconds_to_next near 900;
- +899 sec no regen;
- +1 sec => one Heart;
- multiple missing Hearts regenerate every 900 sec;
- offline/wall-clock semantics unchanged;
- rollback resistance unchanged;
- purchase/refill behavior unchanged.

### 8. Regression locks

V06 tests must prove Gift Meter and Win Streak V05 geometry did NOT change.

Also prove:
- HOME-120 blob/hash unchanged;
- world transform unchanged across the full V05 matrix;
- Scrubby feet/center unchanged while scale increases;
- HeroFocusShade is behind Scrubby and above world;
- shade alpha is within range and does not overlap baked sign/helper-bot exclusion regions materially;
- panel alpha changed only as authorized;
- TASKS/DAILY icon sizes unchanged;
- pill height 67..70;
- plus glyph visually inside pill, hit target >=88;
- no economy mutation from plus buttons;
- Heart count appears on heart icon;
- pill shows timer, not N/5;
- full state shows 15:00;
- countdown uses HeartService and 900-second truth;
- ad canonical height ~100 and stack moves down ~44 vs V05;
- Gift Meter unchanged;
- Win Streak unchanged;
- Daily/Settings modal regression still passes;
- touch targets >=88;
- no approved PNG bytes changed.

## Required test runs

Run:
- `tests/m39b_hearts_speed.gd`
- `tests/m42_assets.gd`
- `tests/m42_home.gd`
- `tests/m42_home_composition.gd`
- `tests/m42_home_v04.gd`
- `tests/m42_home_v05.gd`
- add `tests/m42_home_v06.gd`
- `tests/m42_navigation.gd`
- `tests/m42_opening.gd`
- root `tests/run_tests.gd`
- `git diff --check`

All exit 0 with zero SCRIPT ERROR.

## Runtime evidence

Capture:
- 1080x2160
- 1290x2796
- 1080x1920
- 1536x2048
- heart full state
- heart immediately after one consume
- Daily modal
- Settings modal
- ad slot collapsed

Store under:
`coordination/sessions/M42-C001/runtime_evidence/home_v06/`

If vision is available, inspect:
- Scrubby focus improved without a new bright halo;
- shortcut panels are slightly more visible;
- thinner SB/Heart pills;
- plus glyphs are inside pills;
- Heart icon carries the white count;
- pill reads 15:00/countdown;
- ad area visibly shorter;
- Play/track/nav moved down;
- Gift Meter and Win Streak look unchanged from V05.

## Log

Create:
`coordination/sessions/M42-C001/task_logs/SB-M42-HOME-POLISH-V06.md`

Include exact:
- baseline/final SHA
- changed files
- final hero scale
- HeroFocusShade geometry/alpha
- panel alpha
- pill dimensions
- plus glyph/hit-target dimensions
- Heart regen config before/after
- Heart timer evidence
- V05 vs V06 lower-stack Y positions
- test results
- asset integrity proof

Do NOT claim owner visual acceptance.

Finish:
`AWAITING_CHATGPT_AUDIT / M42 HOME POLISH V06`
