# SB-M43-R15-004 — REWARDED ADS HOME ICON VISUAL REMEDIATION — CLAUDE LOG V01

Prompt: `coordination/sessions/M43-OWNER-R15/CHATGPT_PROMPT_R15_004_V01.md`
Criteria: `CHATGPT_AUDIT_CRITERIA_R15_004_V01.md`

Root `TASKS.md` was not edited. Status: implementation claim, awaiting ChatGPT audit.

## Sync

**Environment.** This ran in a Claude Code cloud container on a clean clone, not in the owner-local `C:\Users\sekip\Desktop\ScrubBots`, which this session cannot reach. No owner-local `project.godot`, `scenes/app/main.tscn`, `addons/`, `.mcp.json` or editor settings existed in this clone, and none were touched. The `.import` / `.uid` editor sidecars from the headless import are never staged.

**Sync.** I ran `git fetch origin main`. The session branch `claude/practical-darwin-ndbmxa` was 1 behind / 0 ahead and was fast-forwarded to `origin/main` = `840406b` ("Add files via upload": the owner's icon). There was no reset, clean or force.

**First attempt (before the owner upload).** The asset was unavailable: the chat attachment was a re-encoded `.webp`. I stopped without implementing anything, as the prompt requires.

## Owner asset

| Field | Value |
|---|---|
| Source | the owner's own commit `840406b` on `main` |
| Path | `assets/ui/final/home/shortcuts/icon_shortcut_rewarded_ads.png` (PNG 1254×1254, RGBA) |
| Bytes on main / final asset SHA-256 | `ce96e09aaf97db5ed171c7da15e2c8afccc46d4408a1cc64bc0521db89a96c8b` (same file, unmodified) |
| Prompt-pinned SHA-256 | `e25529bdab27e66856bc1d41eb9c7ab54c6d635dc006a6e526cdf8e5dfea378f` |

**SHA mismatch: resolved by an explicit owner decision.**
- **How I checked.** I hashed the git blob directly. There is no LFS and no `.gitattributes` conversion, so the committed bytes really are `ce96e09a…`. The file carries a `caBX` metadata chunk (embedded content credentials), so it is plausibly the same picture exported or downloaded differently from the file the prompt hashed.
- **What I did.** I stopped and asked the owner. The owner answered (2026-10-06): **"Use committed file"**, meaning the file now on `main` is the approved master.
- **How it is recorded.** HOME-122 is pinned to `ce96e09a…`, and the override is recorded in the manifest notes and here.
- **Not done.** No pixel was redrawn, regenerated, re-encoded, cropped or padded. No derived runtime asset was created; layout scales the source.

The image contains no baked text and no coin imagery. The coin check was visual only, so only an owner pass can confirm it.

## Manifest / presentation map

**`assets/ui/HOME_ASSET_MANIFEST.json`:** a pure 19-line addition of **HOME-122**, `icon_shortcut_rewarded_ads`, with:
- group `shortcuts`, kind `ART`, implementation `generated_asset`;
- `generation_required` true, provider `chatgpt_image_generation` → [`magnific`];
- status **APPROVED**, `approved_sha256` `ce96e09a…6c8b`;
- `approval_authority` = the R15-004 prompt, `source_path` = the final path;
- notes recording the owner override.

No other entry changed.

**`scripts/ui/home/home_presentation_map.gd`:** HOME-122 → `STATIC`, slot `texture`, node `ShortcutIcon_rewarded_ads`.

**Unchanged:**
- `HomeArtBinder` and `home_asset_manifest_validator.gd` are untouched; strict source-hash and packaged-runtime resolution still apply.
- The icon binds only through `HomeArtBinder.texture()` (APPROVED + hash-correct), via `set_art_binder`.
- The SHOP / COLLECTION / TASKS / DAILY icons are byte-identical; r12 asserts their pinned SHAs.

## Home composition

**Removed:** the green native CTA body (play-button style + `PlayTriangle`). PlayTriangle remains only on PLAY.

**`RewardedAdsButton` is now a `UiShortcutButton`, the same production component as the four panels:**
- the same `HomeStyle.style_light_panel` cyan/blue glass (`PANEL_ALPHA` / `PANEL_BORDER`);
- the same `ShortcutIcon_<id>` TextureRect standing on the label band and popping above the card;
- the same white text with navy outline;
- the label **REWARDED ADS** is code-rendered (`UiText` `HOME_SC_REWARDED_ADS`) on two whole-word lines, REWARDED / ADS, at 24 pt;
- the same disabled / hover / pressed language and badge seam.

**Auxiliary placement.** The card is still a child of `Shortcut_daily`, so it is never a column slot. The left / right columns remain exactly `[shop, collection]` / `[tasks, daily]`, and the closed M42 tests pass. It hangs one `PANEL_GAP` (72) below DAILY, right-aligned with DAILY's outer edge, and hides with the action layer under modals.

**Size: 164×178.**
- **Label band.** The card is narrower than the 210×156 primaries and has a taller 74 px band, because the label needs two lines. `UiShortcutButton` gained an optional per-instance `label_band` (default `LABEL_BAND` = 46, so the four primaries are unchanged), so the icon stands on the text and never over it.
- **Why 164 wide.** I measured Scrubby's pose art. His waving hand reaches x ≈ 866 on the 1080×2160 canvas and x ≈ 884 on the taller 1080×2337 canvases. The card's left edge is at x = 890.
- **Rejected sizes.** I tried a full 210-wide card first: it wrapped the label under the icon. A 186-wide card still covered fingertips.

**Not moved or resized:** SHOP / COLLECTION / TASKS / DAILY.

**Geometry** (r11; each physical size rendered at its logical canvas: 683×1366, 720×1280, 1080×1920, 1080×2160, 1170×2532, 1290×2796, 1536×2048):
- The card and the popped-out icon are inside the viewport. The touch target is ≥ 88 px (178).
- Neither overlaps PLAY, the Journey strip, Gift Meter, BottomNav, the Win Streak track, any of the four panels, the HUD or the world's helper bots.
- **Zero opaque Scrubby pose pixels** under the card or icon (sampled on a 6 px grid through the TextureRect mapping).

Card at 1080×2160 (= the owner's 683×1366 window): x 890..1054, y 942..1120; icon 160×160 at y 888.

## Files changed

| File | Change |
|---|---|
| `assets/ui/HOME_ASSET_MANIFEST.json` | + HOME-122 |
| `scripts/ui/home/home_presentation_map.gd` | + HOME-122 row |
| `scripts/ui/home/home_screen.gd` | Rewarded Ads entry rebuilt as a shortcut-family card; binder relayout; `ICON_SCALE["rewarded_ads"]` |
| `scripts/ui/components/ui_shortcut_button.gd` | optional per-instance `label_band` (default unchanged) |
| `tests/m43_r15_owner_remediation.gd` | r11 extended (icon pop-out, helper bots, Scrubby pixel check); **new r12** |
| `tests/m42_assets.gd`, `tests/m42_home.gd`, `tests/m42_home_composition.gd`, `tests/m42_home_v04.gd`, `tests/m42_home_v05.gd`, `tests/m42_home_v06.gd`, `tests/maint_home_export_asset_gate_c001.gd` | **closed-test count pins +1 for HOME-122** (see below) |
| `tests/tools/r15_004_snapshot.gd` | **new** evidence tool |
| `coordination/sessions/M43-OWNER-R15/evidence_r15_004/*.png` | 4 frames |

**Closed-test pin updates.** These are the only closed-test edits; the prompt asks for them ("update any manifest validator tests / presentation accounting required by adding HOME-122"). Each count moves by exactly the one new APPROVED, presented entry:
- 52→53 APPROVED;
- 51→52 generation targets;
- `APPROVED_BOUND` 52→53;
- STATIC 24→25;
- accounted rows 52→53, active and bound 24→25.

No assertion was removed or loosened.

Behaviour is unchanged:
- the five-slot daily authority, slot 1 / slots 2–5 rules, provider, tx ids and popup;
- Daily login, Daily Scrub Orders, Shop, Collection and Tasks;
- Home navigation.

r12 asserts the tap still emits exactly one `rewarded_ads` intent and opens the unchanged popup.

## Tests (Godot 4.7.2 headless)

**`tests/m43_r15_owner_remediation.gd` → PASS 18/18.** The new r12 asserts:
- same UiShortcutButton component, attached to DAILY, no triangle;
- the same light-glass stylebox as DAILY (not green);
- the code label "REWARDED ADS" with the same font / outline colours and size;
- HOME-122 is `APPROVED_BOUND` and presented, with the owner SHA;
- a STATIC presentation row;
- the four primary icons are byte-identical;
- a tap gives exactly one `rewarded_ads` intent and opens the REWARDED ADS popup.

The r01–r10 functional Rewarded Ads, Settings and Daily cases still pass.

**Regression** (each exit 0, 0 `SCRIPT ERROR`):

| Area | Suites |
|---|---|
| Asset / Home pins | m42_assets PASS · m42_home_composition 9/9 · maint_home_export_asset_gate_c001 11/11 |
| M42 Home / navigation | m42_home PASS · v04 18/18 · v05 13/13 · v06 13/13 · v07_safe_area 9/9 · m42_navigation PASS · m42_c002_scrubby_scale 7/7 · m42_c003_scrubby_animation 18/18 |
| M28 | m28_c002_c003_r01_remediation 24/24 |
| M43 master lanes | c009 12/12 · c010 12/12 · c011–c014 28/28 |

| Other M43 / M41 / M28 | m43_master c006 11/11 · c007 13/13 · m43_c003_c001_acquisition 34/34 (Heart / booster rewarded) · m43_c002_c001_popup_modal_pause 23/23 · m41_settings PASS · m28_c002_c002_static_shell 16/16 |

**Root `tests/run_tests.gd`:** **RESULT: ALL PASS — Total checks 5329**, 0 script errors (Linux). All of these ran on the exact tree committed in `1de7775`.

**`git diff --check`:** clean.

## Evidence

`coordination/sessions/M43-OWNER-R15/evidence_r15_004/` (real app root, `tests/tools/r15_004_snapshot.gd`, opengl3):
- `1_home_rewarded_ads_icon_683x1366.png`: live Home with all five entries (the owner comparison);
- `1_home_rewarded_ads_icon_1080x2160.png`;
- `2_rewarded_ads_popup_from_icon_683x1366.png` and `_1080x2160.png`: the popup opened by tapping the new card.

## Remaining owner gate

- **Visual acceptance at F5.** The owner should judge the Rewarded Ads card and HOME-122 icon in the live Home: the narrower auxiliary card size, the two-line label and the placement under DAILY.
- **Prompt pin.** The prompt's `e25529bd…` pin is superseded by the owner's explicit choice of the committed file (`ce96e09a…`). ChatGPT may want to record that in the tracker.

## Commits

- `1de7775`: manifest, presentation map, Home entry, UiShortcutButton seam, tests (r11 / r12 + closed-test pins), evidence tool and frames;
- this log's commit follows it on `claude/practical-darwin-ndbmxa`. This session cannot push `main`; `main` can take the branch as a plain fast-forward.

AWAITING_GPT_SB_M43_R15_004_V01_AUDIT
