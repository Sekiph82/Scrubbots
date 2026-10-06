# SB-M43-R15-004 — OWNER F5 PLACEMENT FOLLOW-UP — CLAUDE LOG V01

Trigger: owner F5 review of the merged R15-004 Home (screenshot at 683×1366, 2026-10-06), annotated in the owner's words: **"collection'ın altına al ama genişliği Collection ve Shop ile aynı olsun"** ("put it under Collection, but make its width the same as Collection and Shop"). A red arrow pointed from the card under DAILY to the space under COLLECTION.

No new ChatGPT prompt exists for this change; it is applied as the newest explicit owner instruction (CLAUDE.md §19 precedence 1). Root `TASKS.md` was not edited. Status: implementation claim, awaiting ChatGPT audit / owner F5.

## Sync

- Session branch `claude/practical-darwin-ndbmxa` was 0 ahead / 2 behind `origin/main` (`b402cb6`: ChatGPT R15-004 audit + TASKS update). It was fast-forwarded; no reset, clean or force.
- Cloud container, not the owner-local checkout. No `project.godot`, `scenes/app/main.tscn`, `addons/` or owner metadata was touched. `.import` / `.uid` sidecars from the headless import are never staged.

## Change

Only `RewardedAdsButton` placement and size in `scripts/ui/home/home_screen.gd`:

| | Before (R15-004 V01) | After |
|---|---|---|
| Parent | child of `Shortcut_daily` (right column) | child of `Shortcut_collection` (left column) |
| Placement | right-aligned, one `PANEL_GAP` (72) below DAILY | full COLLECTION width, one `PANEL_GAP` (72) below COLLECTION |
| Size | 164×178, two-line label, 74 px band | **210×156 = `PANEL_SIZE`**, exactly SHOP / COLLECTION |
| Label | REWARDED / ADS, 24 pt, word wrap | REWARDED ADS on one line, 24 pt, `AUTOWRAP_OFF`, standard `LABEL_BAND` (46) |
| Icon box | (160, 164) | `V03_ICON_BOX` (206, 164) × `ICON_SCALE["rewarded_ads"]` 1.0 |

At 210 px the label measures 188 px at 24 pt, so it fits one line inside the panel's content margins; the card no longer needs a taller band, and is the same panel as its neighbours.

**Unchanged:** it is still not a column slot — the columns remain exactly `[shop, collection]` / `[tasks, daily]`; the HOME-122 owner icon (byte-identical, `ce96e09a…`), manifest, presentation map, binder; light-glass style, font/outline colours, disabled / badge seam; the tap intent `rewarded_ads` and the popup; every Rewarded Ads / Daily / Settings rule. SHOP / COLLECTION / TASKS / DAILY are not moved or resized.

`UiShortcutButton.label_band` (the R15-004 per-instance seam) is kept; it now carries its default for every caller.

## Tests (Godot 4.7.2 headless)

`tests/m43_r15_owner_remediation.gd` → **PASS 18/18**, 0 `SCRIPT ERROR`. Updated assertions:
- r10 / r12: the card is attached under COLLECTION.
- r11 (every viewport: 683×1366, 720×1280, 1080×1920, 1080×2160, 1170×2532, 1290×2796, 1536×2048):
  - card + icon inside the viewport, ≥ 88 px, no overlap with PLAY / Journey strip / Gift Meter / BottomNav / Win Streak track / HUD / any of the four panels / helper bots (icon now checked against every panel, COLLECTION included);
  - **new:** card size == COLLECTION size == SHOP size, same x as COLLECTION, below COLLECTION;
  - zero opaque Scrubby pose pixels under card or icon.
- r12 **new:** one-line label in the standard band fits the panel width.

Card at 1080×2160 (= owner 683×1366): x 26..236, y 942..1098 (COLLECTION: y 714..870).

Regression (each exit 0, 0 `SCRIPT ERROR`, on the committed tree): m42_assets PASS · m42_home_composition 9/9 · maint_home_export_asset_gate_c001 11/11 · m42_home PASS · m42_home_v04 18/18 · v05 13/13 · v06 13/13 · v07_safe_area 9/9 · m42_navigation PASS · m42_c002_scrubby_scale 7/7 · m42_c003_scrubby_animation 18/18 · m28_c002_c003_r01_remediation 24/24 · m43_master_c009_daily 12/12 · c006_shop 11/11 · c007_collection 13/13 · m43_c002_c001_popup_modal_pause 23/23 · m41_settings PASS.

Root `tests/run_tests.gd`: **RESULT: ALL PASS — Total checks 5329**, 0 script errors (Linux). No closed-test pin needed changing.

`git diff --check`: clean.

## Evidence

`coordination/sessions/M43-OWNER-R15/evidence_r15_004_v02/` (real app root, `tests/tools/r15_004_snapshot.gd`, opengl3): Home at 683×1366 and 1080×2160, and the popup opened from the card. The V01 frames in `evidence_r15_004/` are kept as history.

## Remaining owner gate

Owner F5 visual acceptance of the new placement.

AWAITING_GPT_SB_M43_R15_004_OWNER_F5_PLACEMENT_V01_AUDIT
