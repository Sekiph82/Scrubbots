# SB-M42 HOME OWNER REVISION V03 — ChatGPT Independent Audit V01

Date: 2026-09-26
Auditor: ChatGPT
Baseline SHA: `6807521e4df580b0eff269b7d2f0313950cf86f1`
Implementation SHA: `d5f11e11a5d0903d21eca806ce2c4a1ee5df0b95`
Evidence / Claude log SHA: `30c32fc597f1f975ba65d516ad8514a4c8f03bf9`

Prompt:
`coordination/sessions/M42-C001/task_prompts/SB-M42-HOME-OWNER-REVISION_V03.md`

Owner decision:
`coordination/OWNER_M42_HOME_VISUAL_REVISION_V03.md`

Criteria:
`coordination/sessions/M42-C001/audit_criteria/SB-M42-HOME-OWNER-REVISION_V03.md`

## Verdict

**AUDITED_PASS / CODE READY FOR OWNER VISUAL REVIEW**

No code remediation is required from the independent source/diff/test audit.

SB-M42-011 and SB-M42-017 remain open because V03 explicitly requires a fresh owner runtime screenshot before final visual closure.

## 1. Commit scope and authority boundaries

GitHub comparison `6807521..d5f11e1` is one implementation commit changing exactly eight text/source/test files:

- `scripts/app/main.gd`
- `scripts/ui/home/home_presentation_map.gd`
- `scripts/ui/home/home_screen.gd`
- `scripts/ui/ui_text.gd`
- `tests/m42_home.gd`
- `tests/m42_home_composition.gd`
- `tests/m42_home_v03.gd`
- `tests/tools/home_snapshot.gd`

Independent compare result:

- PNG changes: **0**
- `assets/ui/HOME_ASSET_MANIFEST.json` changed: **no**
- root `TASKS.md` changed by Claude: **no**
- owner decision/artifact changes by Claude: **no**
- ChatGPT prompt/audit/criteria changes by Claude: **no**

The follow-up `30c32fc` adds runtime evidence PNGs plus the Claude implementation log only.

## 2. Approved image integrity

ChatGPT independently parsed the ten owner Home-art approval artifacts and compared all recorded Git blob SHAs against the complete implementation tree at `d5f11e1`.

Result:

- approval rows: **49**
- unique approved PNG IDs: **49**
- missing approved paths: **0**
- Git blob mismatches: **0**

Therefore every unique owner-approved production Home PNG remains byte-identical to its recorded owner-approved Git object.

## 3. V03 presentation accounting

ChatGPT independently compared the approved ART manifest IDs to `HomePresentationMap`.

Result:

- approved ART manifest entries: **50**
- presentation-map entries: **50**
- ID sets: **exact match**
- active STATIC: **45**
- OWNER_RETIRED: **3**
- OWNER_DISABLED: **2**

Exact inactive set:

- HOME-011 — OWNER_RETIRED
- HOME-031 — OWNER_DISABLED
- HOME-032 — OWNER_DISABLED
- HOME-078 — OWNER_RETIRED
- HOME-087 — OWNER_RETIRED

This correctly implements the V03 owner decision without falsifying historical manifest approval/hash state.

## 4. Profile / top HUD

Source and focused test independently verify:

- ProfileCard is narrower than the V02 reference while retaining height.
- ProfilePortrait is materially larger.
- ProfileAvatarFrame is created before ProfilePortrait, so the portrait draws in front.
- Portrait offsets extend it above the frame/card.
- Avatar/ancestor clipping is disabled/tested.
- Top `MenuButton` no longer exists.
- The only Settings entry is bottom-nav Settings.
- Level remains a separate live value.
- Bot Parts caption is only the live numeric ratio such as `0/250`.

## 5. Gift Meter

Verified:

- HOME-051 emblem remains presented.
- HOME-054 crate remains presented.
- Long Gift Meter / Next Gift copy is removed from the meter presentation.
- Caption uses only the live ratio through `HOME_RATIO`, e.g. `12/1,000` in the focused test.
- Canonical Gift Meter service/state remains untouched.

## 6. City / street / portal composition code

V03 source now lays out the background with uniform aspect-preserving scaling:

- HOME-002 far city rises behind/above the portal;
- HOME-003 mid city extends left/right beyond the portal;
- HOME-004 street bottom is tied to the bottom-nav top and rises above the lower action row;
- bottom navigation is tested flush to the viewport/safe-area bottom;
- no replacement city candidate was generated.

The focused city test additionally verifies:
- far/mid city have substantial visible rects;
- mid city extends at least 100 px beyond both portal sides;
- city rises behind portal crown;
- native aspect ratios are preserved;
- street foreground bottom is tied to nav top;
- pavement reaches above SHOP | PLAY | CARDS.

This satisfies the deterministic code/layout contract. Final visual quality of the city composition remains an owner screenshot decision.

## 7. Portal / one-platform composition

Verified:

- HOME-011 has no runtime node and is owner-retired.
- HOME-010 is the only active platform.
- Scrubby feet are tied directly to HOME-010 at the documented top-surface fraction.
- V03 focused test asserts HOME-011 texture is absent from runtime composition.
- AreaTitle / AreaNumber remain live/localizable and the area banner intersects/sits in the arch treatment.

## 8. Idle overlay removal

Verified:

- HOME-031 and HOME-032 have no runtime presentation nodes.
- Their old STATE modes are removed.
- The old idle-state switching API is absent.
- V03 focused test simulates 240 frames plus 12 timer ticks and confirms neither texture ever appears.
- Historical approved files remain unchanged.

## 9. 3+3 side cards and lower action row

Verified exact child order:

Left:
- WIN STREAK
- GIFTS
- COLLECTION

Right:
- NO ADS
- DAILY
- TASKS

Lower action row:
- SHOP
- PLAY
- CARDS EXCHANGE

Focused tests verify:
- no overlap;
- SHOP remains future-disabled;
- Cards Exchange remains live;
- labels remain full;
- action cards remain >=88 px.

## 10. Play CTA

Verified:

- V03 Play minimum size = **470×150**, down from V02 700×196.
- font size reduced from V02 104 to 76.
- subtitle remains live and secondary.
- native `PlayTriangle` draws a white polygon and is not a TextureRect.
- HOME-078 is not loaded/presented and is marked OWNER_RETIRED.

## 11. Reward track

Verified:

- five approved gift objects remain;
- step labels render exactly `1 / 5 / 10 / 25 / 100`;
- no `+` copy;
- no per-step WIN copy;
- no per-step SB icon;
- HOME-087 is owner-retired;
- current/reached/future states are still differentiated through color/alpha;
- track height is explicitly tested materially below the V02 reference;
- badge fits within the thinner track.

## 12. Modal / overlay defect

This was independently source-audited and is covered by real input tests.

Implementation:

- `HomeScreen.set_modal_active(source, active)` tracks external modal sources.
- visible Home popups also contribute to modal state.
- while modal state is active, these regions are hidden:
  - LeftShortcutColumn
  - RightShortcutColumn
  - ActionRow
  - WinStreakRewardTrack
  - BottomNav
- Home popups are moved to the top child position and use `z_index = 2`.
- app-root Settings open/close drives the same Home modal state through `_home.set_modal_active("settings", open)`.

Focused tests cover:

- Gifts popup;
- Daily popup;
- Cards Exchange popup;
- Settings panel;
- all Home action controls hidden while open;
- no visible Home BaseButton behind a popup;
- actual pushed mouse clicks on hidden Gifts/Cards/Settings targets produce no Home intent;
- second popup closes/hides the first;
- close/back restores exact prior visibility and geometry;
- Settings back closes Settings first;
- Home-popup back closes the popup first.

This closes the V03 modal-layering defect at code/test level.

## 13. Responsive validation

`m42_home_v03.gd` validates seven viewport sizes:

- 1080×2160
- 1170×2532
- 1290×2796
- 1080×2400
- 1440×3200
- 1080×1920
- 1536×2048

Each is tested with both zero insets and synthetic top/bottom insets.

Assertions include:
- all BaseButtons >=88 px;
- all buttons inside safe area;
- lower row has no overlap;
- Scrubby feet remain on platform;
- bottom nav remains at safe-area bottom.

## 14. Runtime evidence

Repository evidence exists for:

- final 1080×2160
- final 1290×2796
- final 1080×1920
- final 1536×2048
- two 1080×2160 visual-iteration captures
- Gifts modal
- Daily modal
- Cards Exchange modal
- Settings modal

Claude records three visual iteration rounds and explicitly notes two residual observations:
- some sky remains on the tallest phone;
- HOME-003 contains painted sky between its towers.

The GitHub connector used for this independent audit can verify these binary evidence files and their commit identities but does not decode repository PNG bytes into vision input. Therefore this audit does not substitute for the required owner runtime screenshot review.

## 15. Regression evidence

Claude's log records, on implementation tree `d5f11e1`:

- `m42_assets`: 4/4 PASS
- `m42_home`: 19/19 PASS
- `m42_home_composition`: 9/9 PASS
- `m42_home_v03`: 14/14 PASS
- `m42_navigation`: 12/12 PASS
- `m42_opening`: 8/8 PASS
- root: 5322 checks ALL PASS
- exit code 0 for all
- zero SCRIPT ERROR
- same eight documented intentional corrupt-image engine ERROR lines
- `git diff --check`: clean

The focused tests are substantive and map directly to the V03 owner requirements rather than merely asserting implementation constants.

## Gate impact

- SB-M42-011: **CODE_AUDIT_PASS / OWNER_VISUAL_REVIEW_REQUIRED**
- SB-M42-017: **CODE_AUDIT_PASS / OWNER_VISUAL_REVIEW_REQUIRED**
- SB-M42-014, 016, 018 remain closed.
- SB-M42-032 remains Android real-device owner gate.
- SB-M42-033 remains iOS-later device gate.

## Final

**AUDITED_PASS / CODE READY FOR OWNER VISUAL REVIEW**

Next action: owner pulls current `main`, runs the game, and supplies a fresh normal Home screenshot plus, ideally, one popup screenshot to confirm the V03 city/portal/profile/lower-row/modal result visually.
