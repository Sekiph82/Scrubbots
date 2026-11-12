STATUS: READY

# Build: SB-PHONE-2026-11-12-A popup frame fit (TR / EN)

## Summary
Branch `factory/148-popup-fit-tr`, commits `edb2ee6b` (code + tests) and `210685cf` (TASKS.md).

The shared fix is in `BasePopup.FrameBox`, which is used by every BasePopup and by Settings:
- `FRAMES` now holds two sets of numbers per frame kind, both measured from the frame PNGs:
  - `clear`: the cream interior. It is the largest cream rect, found by a flood fill from the centre (colour within 60 of the centre colour), weighting 2 px of width against 1 px of height.
  - `patch`: the 9-slice margins. Top and bottom now end below the corner art (caps, orbs, brackets) and below the interior's rounded corner.
- Values in texture px, [left, top, right, bottom]:

| Kind | clear | patch |
|---|---|---|
| small | 190,259,189,305 | 176,370,176,389 |
| medium | 142,228,140,254 | 119,315,119,340 |
| large | 144,255,144,265 | 125,264,126,273 |
| reward | 146,362,147,289 | 128,470,122,348 |
| warning | 139,372,139,320 | 119,465,120,320 |

- The Body sits inside `clear` plus 8 px of padding. The old Body inset was `patch` plus padding, and the old patch was smaller than the corner art.
- Before this change the corner caps were stretched on tall popups, and footers and rows overlapped the orbs and side bars. Corners no longer distort, and nothing reaches the chrome.
- New FrameBox methods: `body_width()` and `get_clear_rect()`.

Text fit:
- New helper `HomeStyle.fit_on_resize`: one-line text that never widens its parent. It shrinks to fit (60% floor) and only wraps if the floor is still too wide. It is never cut off.
  - Used for every BasePopup title. TEKRAR HOŞ GELDİN is now one line.
  - Also used for Profile tile caption and value ("Temizlenen Bölüm"), Profile bests labels, Achievements names, Robots name and row button, and the Ranks meter caption.
- New helper `HomeStyle.fit_row`: shrinks a row of buttons together. Settings uses it for the EMEĞİ GEÇENLER / GİZLİLİK / KAPAT row.
- Settings row buttons and BasePopup secondary buttons now have 16 px side padding, so text clears the rounded ends.

Other changes the tighter interior needed:
- **Settings:** the cards scroll in `SettingsScroll/Cards` when the screen is too short (1080x1920, pseudo-locale). The empty status line is hidden.
- **Collection set:** the < > pager moved into the footer row (< BACK >). Before, it sat on the frame's side bars. Card faces are 210x300 → 203x290.
- **Daily:** day cards 210x280 → 203x280. Three columns no longer push the Body wider than the frame.
- **Life:** the +N badge overhang now stays inside the interior (offset_right 12 → 8).
- **Shop:** LIST_H 1040 → 1020, so Shop fits the 1080x1920 safe area again.

Files changed:
- `scripts/ui/popup/base_popup.gd`
- `scripts/ui/home/home_style.gd`
- `scripts/ui/settings_panel.gd`
- `scripts/ui/profile/profile_screens.gd`
- `scripts/ui/robots/robots_screen.gd`
- `scripts/ui/collection/collection_screen.gd`
- `scripts/ui/daily/daily_screens.gd`
- `scripts/ui/popup/acquisition_flow.gd`
- `scripts/ui/shop/shop_screen.gd`
- new `tests/m49_popup_frame_fit.gd`
- updated tests: `m43_master_c007_collection`, `m51_localization_readiness`, `m58_privacy_consent`, `m59_credits`
- `TASKS.md` (only the task's row)

## Acceptance criteria
1. [x] **Footer buttons, version line and content clear the corner orbs and side edges for every frame kind, using values measured from the PNGs.**
   - The values come from a flood fill plus row-profile measurement of each PNG (script kept in the session scratchpad).
   - `tests/m49_popup_frame_fit.gd` case f01 checks every frame kind: the clear-rect perimeter is all cream (0 px off), and the stretched band holds no corner art (0 rows off).
   - Cases f02 and f03 cover 86 framed surfaces per locale at 720x1520 and 1080x2400. In EN that is 2836 controls and in TR 2814. For every control:
     - the Body is no wider than its slot;
     - the control's rect is inside the clear interior;
     - all 4 corners sample cream through the live 9-slice mapping.
   - Result: 0 findings in EN and TR.
2. [x] **Settings bottom row fits in TR and EN.** `fit_row` and the padded ends handle it; TR now fits.
   - Captures: `tr_720x1520_settings.jpg` and `en_*_settings.jpg`.
   - The text check in m49_popup_frame_fit (text width + max(content margin, radius/2) per side ≤ button width) passes.
3. [x] **Profile "Temizlenen Bölüm" fits its tile.** Shrink-to-fit; capture `tr_720x1520_profile.jpg`; text check passes.
4. [x] **Welcome Back title on one line in both languages.**
   - The title is one line with shrink-to-fit; capture `tr_720x1520_comeback.jpg`.
   - The test asserts `line_count == 1` for every popup title.
5. [x] **Other BasePopups checked through the same shared change.** All of these are walked by the test:
   - Life, Gift, Tasks, Events, Daily and Daily reward, Robots and robot detail, card detail, cards exchange, Collection and Collection set, Shop, Rewarded Ads, Achievements, Notifications, Profile, Ranks, Help, Settings, Pause
   - acquisition, booster and speed popups
   - generic reward / confirm / network error / busy / feedback popups
   - ceremonies, Need a Hand
6. [x] **Proof captures.** 64 windowed GPU captures (TR and EN × 720x1520 and 1080x2400 × 16 surfaces) in the job folder; list below.
7. [x] **CI-listed suites with exact case-count guards.** No case count changed, so `.github/workflows/android-family-first10.yml` is unchanged.

## Validation
All runs are LOCAL_PASS on Windows with Godot 4.7.2 headless. Each one exited 0, printed 0 `SCRIPT ERROR` / `Parse Error`, and its last line said PASS. There is no CI run and no phone build.

New suite:
- m49_popup_frame_fit: PASS (3/3 cases), about 4.5 min. Not added to the CI list; like m49_surface_matrix, it is long-running.

Directly affected CI-listed suites (final code):

| Suite | Cases |
|---|---|
| m41_settings | PASS |
| m59_credits | 3/3 |
| m58_privacy_consent | 7/7 |
| m51_localization_readiness | 8/8 |
| m43_master_c007_collection | 19/19 |
| m43_master_c008_robots | 10/10 |
| m43_master_c006_shop | 15/15 |
| m43_master_c009_daily | 12/12 |
| m43_master_c010_meta | 12/12 |
| m43_master_c011_c014 | 29/29 |
| m43_c003_c001_acquisition | 34/34 |
| m43_r15_owner_remediation | 18/18 |
| m49_responsive_matrix | 8/8 |
| m49_ad_store_return_layout | 6/6 |
| m50_accessibility_audit | 11/11 |
| m47_touch_r01_mobile_ux | 14/14 |
| sb_polish_004_006_ui_batch | 10/10 |
| m43_master_c005_meta_ceremonies | 33/33 |
| m43_c005_c072_feature_unlock_ceremony | 9/9 |
| m43_c005_c074_c077_celebrations | 6/6 |
| m44_meta_verify_achievements_gift | 4/4 |
| m44_meta_l1_unlock_ftue | 6/6 |
| m44_robot_assembly_stages | 4/4 |
| m54_collection_set_master_exactly_once | PASS |
| m54_cloud_save_seam | 7/7 |
| m43_personal_ranks | 8/8 |
| m43_ranks_weekly | 7/7 |
| m42_home | PASS |

Non-CI suites:

| Suite | Cases |
|---|---|
| m43_c002_c001_popup_modal_pause | 23/23 |
| m49_surface_matrix | 3/3 |
| m49_surface_stress | 4/4 |
| m49_touch_targets_text_stress | 5/5 |
| m22_028_collection_card_lru | PASS |

Two caveats:
- The last helper change (wrap past the 60% floor) came after some of the suites above had already passed. These were re-run after it: m49_popup_frame_fit, both m49 stress suites, the robots and ranks suites, and c010. The wrap only engages when shrinking fails, which no real-locale text in m49_popup_frame_fit does.
- `git diff --cached --check` was clean.

Captures (windowed GPU) are in `factory/jobs/148-popup-fit-tr/captures/`. The set is `{en,tr}_{720x1520,1080x2400}_<surface>.jpg` for these 16 surfaces:
- comeback, shop, settings, achievements
- collection, collection_set, cards_exchange
- robots, robot_detail
- profile, rewarded_ads, daily, life, gift_bar, tasks, events

Some captures show a faint second frame behind the popup. That is the previous popup's close animation caught by the capture, not a layout issue.

Worktree note: the Godot import created untracked `.uid` / `.import` / `.translation` files (1234) in the job worktree. Tracked files were restored. The permission system denied deleting the untracked files, so `git status` is not empty. Only generated files remain, nothing to commit; they go away when the worktree is removed.

## Log
### Round 1
Built as above. Where the fix came from:
- I measured the frames and found that the old `patch` values (used both as the 9-slice margins and as the Body inset) ended inside the corner caps. That caused both the stretched caps and the overlap.
- The tighter interior then exposed content whose minimum width was wider than the frame: Achievements, Profile, Robots, Daily, Collection set. It also exposed vertical overflow at 1080x1920: Settings and Shop. Each got a fix through the shared shrink-to-fit helpers, scrolling, or smaller fixed sizes, as listed in the Summary.
- Updated four existing tests to the new structure:
  - Settings cards now live under SettingsScroll/Cards.
  - The Collection pager now flanks BACK.
  - m59 checks the frame against its own viewport; the 1920 check is covered by m41.
