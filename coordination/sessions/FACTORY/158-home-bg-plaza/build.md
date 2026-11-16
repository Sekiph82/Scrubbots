STATUS: READY

# Build: 158-home-bg-plaza (SB-HOME-BG-2026-11-16)

## Summary
Home now shows the owner's calm plaza image (HOME-124, 941x1672) as WorldBackground. "WHISPERING PARK / AREA n" is native text in the sky band. The SB-POLISH-009 still/video set has the old background baked into its frames, so it is no longer bound; Scrubby uses the frame-set fallback and stands on the tile floor. Commit `8c87cb8b` on `factory/158-home-bg-plaza` (not pushed).

Files changed:
- `assets/ui/final/home/background/home_background_plaza.png` (new, byte-copy of the owner image, sha256 0aa7463b...cde3) + its `.import`
- `assets/ui/HOME_ASSET_MANIFEST.json`: new HOME-124 APPROVED entry. HOME-121 and HOME-123 notes record the retirement. The files stay byte-identical; `video_sets` are unchanged (still pinned and valid).
- `data/config/home_worlds_v1.json`: world_01 is now `home_background_plaza` with canvas 941x1672. `baked_title` is dropped and `baked_sign_rect` is renamed to `area_label_rect` (same rect). Feet anchor (470,1240) is unchanged and sits on the tile floor.
- `scripts/ui/home/home_world_catalog.gd`: `area_label_rect`
- `scripts/ui/home/home_presentation_map.gd`: HOME-121 and HOME-123 are OWNER_RETIRED with no node; HOME-124 is STATIC on WorldBackground.
- `scripts/ui/home/home_screen.gd`: `set_video(..., {})` (no video set) and the `HERO_VIDEO_SET` const removed.
  - New `HomeAreaLabel` Control in Layer_characters, holding two Labels: HomeAreaTitle (white) and HomeAreaNumber (SUBTITLE gold). Both use the HomeStyle navy outline (12) and the theme shadow.
  - Text comes from HOME_AREA_TITLE and HOME_AREA_NUMBER. The number comes from `WorldService.world_for_level(current level)`.
  - `_layout_area_label` places the label from the area_label_rect top (never above Gift Meter bottom + 8) down to Scrubby's visible head - 8. Horizontally it sits between the shortcut columns.
  - Both fonts shrink together to fit the height, then each shrinks to fit the width (`HomeStyle.fit_font`). The label hides only when the fonts would go below 60%. That happens only on the non-required 16:9 and tablet extras with a 132 px notch.
- `scripts/ui/ceremony/standard_pack_ceremony.gd`: HOME_BG now points to the plaza file.
- Tests now pinned to the new truth: `m28_c002_c003_r01_remediation`, `m42_home`, `m42_home_v04` (plus new label/TR/matrix/retirement assertions), `m42_home_v05`, `m42_home_v06`, `m42_c002_scrubby_scale`, `m42_c003_scrubby_animation`, `m43_master_c011_c014`, `maint_home_export_asset_gate_c001`, `m22_026_texture_budget`.
  - In `m42_home_v05` and `m42_home_v06`, the world-transform x offset was re-baselined by -scale/2 for the 941 px width.
  - `m42_c003_scrubby_animation` video cases now inject the pinned set, so the video seam stays covered.
- Tools: `tests/tools/home_snapshot.gd` takes a new `tr` argument; `tests/tools/m22_026_texture_measure.gd` no longer reads `baked_title`.

Not changed: `data/config/worlds_v1.json` `fallback_art` still points to HOME-120 (`world_01_whispering_park_1080x2160.png`). That is World Transition ceremony art, not the old Home background path, so it is outside this spec.

## Acceptance criteria
1. [x] The new file is a byte-copy: the sha256 matches the owner image (0aa7463b...cde3). The old `home_background.png` is unchanged; `m42_home_v04` asserts its sha 9d5db295... and that Home never draws it (`m28` H2).
2. [x] Manifest HOME-124 is APPROVED (sha, 941x1672) and bound to WorldBackground. HOME-121 is retired like HOME-120. The catalog points to the new slug at 941x1672, `baked_*` is dropped/renamed, and the feet are on the floor (see captures). `m42_home_v04`: "manifest HOME-124 APPROVED...", "HOME-124 accounted STATIC on WorldBackground".
3. [x] The video set is no longer bound: `m42_home_v04` checks "HOME-121 + the HOME-123 video still retired; no video set bound, frame-set Scrubby shown over HOME-124". Scrubby is visible on the tile floor in the captures.
4. [x] Native area label, EN "WHISPERING PARK / AREA 1" and TR "FISILTILI PARK / BÖLGE 1" (`m42_home_v04` asserts both). In the `m42_home_v04` responsive matrix (7 sizes x 2 inset sets), the label is shown on every required viewport and stays clear of TopCurrencyHUD, ProfileCard, GiftMeter, PlayButton, the four shortcuts and Scrubby. Each line is one line wide and fits its width.
5. [x] `standard_pack_ceremony.gd` HOME_BG now points to the plaza file; `m43_c005_c006_standard_pack_presentation` PASS.
6. [x] Tests are updated, not deleted. No CI case counts changed (only assertions were added), so no CI guard edits were needed.
7. [x] GPU captures at 1080x2340. They use the `tests/tools/home_snapshot.gd` harness with a temp-save AppState, not main.tscn. No intro video or animation runs in that path; nothing covers Home.
   - `factory/jobs/158-home-bg-plaza/capture_home_en_1080x2340.png`
   - `factory/jobs/158-home-bg-plaza/capture_home_tr_1080x2340.png`

## Validation
Godot 4.7.2 headless, all LOCAL_PASS. Every run exited 0 with no SCRIPT ERROR or Parse Error. Last line of each:
- `m42_home_v04: 18/18 cases, 0 failures`
- `M42 home evidence: PASS` (m42_home)
- `maint_home_export_asset_gate_c001: 11/11 cases, 0 failures`
- `M28-C002-C003-R01 five-finding remediation: PASS (24/24 cases, 0 fail)`
- `M43 master C011-C014 evidence: PASS (29/29 cases, 0 fail)` (matches the CI exact guard)
- `M22-026 TEXTURE BUDGET: PASS`
- `m42_c003_scrubby_animation: 25/25 cases, 0 failures`
- `m42_c002_scrubby_scale: 7/7 cases, 0 failures`
- `m42_home_v05: 13/13 cases, 0 failures`
- `m42_home_v06: 13/13 cases, 0 failures`
- `M43 owner R15 evidence: PASS (18/18 cases, 0 fail)`
- `M43-C005-C006 V02 standard pack interactive opening evidence: PASS (28/28 cases, 0 fail)`

`git diff --cached --check` is clean. A one-off `--import` was run in the worktree; its project.godot change and the unrelated .import/.uid/.translation churn were restored or deleted after the commit. `git status --porcelain` is empty. TASKS.md was not edited (per the job instruction).

## Log
### Round 1
- Implemented the background swap, the retirement of the baked-background video set, the native area label (height and width fit, hidden only when there is no sky gap) and the ceremony path switch.
- Updated the pinned tests. Added area-label assertions (EN/TR text, outline/layer, matrix clearance and fit) and live no-video assertions to `m42_home_v04`.
- Captured EN and TR Home.
