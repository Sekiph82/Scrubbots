# M47-FAMILY-APK-TOUCH-R01 — Mobile Family QA (Supply tap / list scroll / Rewarded Ads badge) — CLAUDE_LOG_V02

- Prompt: `coordination/sessions/M47-FAMILY-APK-TOUCH-R01/CHATGPT_PROMPT_V02.md`
- Criteria: `CHATGPT_AUDIT_CRITERIA_V02.md`; owner records `OWNER_DEVICE_FEEDBACK_V01.md` / `_V02.md`
- Engine: Godot 4.7.2.stable.official.ed1daf0bf
- Starting SHA: `309096e39119aa5971e38db30fb8e642e8b3240b`
- **Fix commit (code + tests): `c2b1c3c7ae0a301cd43d95dd003f0ddf1373eed0`.** Both new builds are built from exactly this SHA. This log follows in a separate commit.
- No V01 implementation existed to reconcile: there was no V01 Claude log and no touch commits.
- Root `TASKS.md` and ChatGPT audit files were not edited.

Status: **AWAITING_CHATGPT_INDEPENDENT_AUDIT / OWNER_THREE_DEVICE_RETEST_PENDING**. Synthetic tests are not physical-device proof.

## 0. Gate 0 — owner Desktop

| Item | Value |
|---|---|
| Desktop HEAD at start | `c997ca65` |
| `origin/main` after `git -C "C:\Users\sekip\Desktop\ScrubBots" fetch --prune origin` | `309096e3` |
| Ahead / behind | 0 / 7 |
| Dirty tracked files | `project.godot`, `scenes/app/main.tscn`, `tests/tools/owner_review/premium_pack_owner_review.tscn`, `tests/tools/owner_review/standard_pack_owner_review.tscn` |
| Untracked / stashes / worktrees | 2616 / 2 / 5 (all untouched) |
| Owner `project.godot` SHA-256 | `d2546c0bb7d3daccce6c803252a2bf72ddd2359ee1e61abcaa02ca2b98e63574` |

The incoming commits were TASKS / M47-TOUCH docs only. `git merge --ff-only` → `309096e3`, **0/0**, hash unchanged. Nothing was reset, cleaned, restored or stashed.

**TEMP:**
- One bounded sparse worktree under the session scratchpad: `/*` minus `coordination/sessions/` (except `M47-FAMILY-APK-TOUCH-R01/`, plus `M42-C003/` added later so its suite can read its own evidence) and minus the 3 dev-art trees.
- Absolute `git -C` / `godot --path` paths, `MSYS_NO_PATHCONV=1`.
- One `--import`. The TEMP `project.godot` was restored with `git -C "<TEMP>" checkout -- project.godot`.
- No SDK was installed on Windows. Builds ran in GitHub Actions.

## 1. A — Supply: ONE stationary tap does nothing (root cause)

**Mechanism.** Proven from Godot 4.7.2 source and reproduced through the real input route.

`core/input/input.cpp`: with `emulate_mouse_from_touch` (project default ON, as on Android / iOS), `Input` synthesizes a `InputEventMouseButton` with `device = InputEvent.DEVICE_ID_EMULATION` and **dispatches it BEFORE the `InputEventScreenTouch` it mirrors**. The pre-fix `BatchSupplyPanel._on_front_gui_input` de-duplicated only with a 200 ms window **after** a touch. For one quick tap the sequence was:

1. Emulated mouse **press**: no touch seen yet, so it was accepted and armed a *mouse* gesture.
2. Touch **press**: a gesture was already pending, so it was ignored.
3. Emulated mouse **release**: within 200 ms of the touch, so it was dropped by the dedup.
4. Touch **release**: it did not match the pending mouse gesture, so it was ignored.

Result: **no activation**, and a gesture left pending. Only a press held for **> 200 ms** let the emulated release through. That matches the owner's report: "you have to hold it and push it toward the slots".

**Fix** (`scripts/ui/batch_supply_panel.gd`):
- Mouse events with `device == InputEvent.DEVICE_ID_EMULATION` are ignored. The real `ScreenTouch` press / release pair carries the gesture. `viewport.cpp` routes touch press to the control under the finger and release to the same control via `touch_focus`, so the touch path is complete on its own.
- The 200 ms window is kept for an OS-synthesized (non-emulation-device) mouse that follows a touch.
- A genuine desktop mouse, the serialized one-gesture rule, preview-row inertness and full / paused / modal / terminal rejection in `ProductionInputController` / `FiveSlotBatchEngine` are unchanged.
- No drag or hold logic was added.

Also reviewed: the only other touch-aware handler is `standard_pack_ceremony.gd::_on_input`. One finger gives it two presses (emulated mouse + touch), but its phase gate makes the second a no-op. Unchanged and outside this report.

## 2. B — Collection (and other popup lists): finger swipe sticks (root cause)

**Mechanism.**
- Godot `ScrollContainer` drag-scrolls only from the (touch-emulated) mouse press and motion that **reach it** (`scene/gui/scroll_container.cpp`, `is_touchscreen_available()` path).
- The album list was full of `MOUSE_FILTER_STOP` controls: each row `PanelContainer` and its VIEW `Button`. The pre-fix diagnostic found **33 STOP controls** inside `SetList`. They swallowed the press, so a swipe starting on a row or its button never scrolled.
- The same pattern was in Robots (42 STOP), Shop (26), Achievements (18), Gift Bar (2) and Exchange (2).

**Fix:** new `scripts/ui/components/touch_scroll.gd`, `TouchScroll.enable(scroll)`, called once at each of the 6 popup list sites (Collection `SetList` + `ExtraList`, Robots `RobotList`, Shop `ShopList`, Gift Bar `GiftList`, Achievements `AchievementList`).
- STOP descendants become `PASS`, both now and for rows added later via `child_entered_tree`. The press / motion now also reach the ScrollContainer.
- A stationary tap still presses the button: `BaseButton` never `accept_event`s mouse in `gui_input`.
- Once a drag passes the deadzone, the ScrollContainer propagates `NOTIFICATION_SCROLL_BEGIN`, and `BaseButton` cancels its press (`base_button.cpp`). **A swipe never activates VIEW / BUY.**
- `scroll_deadzone = 16` canvas px, so ordinary tap jitter remains a tap.
- Mouse wheel and desktop behaviour are unchanged.
- Card / economy behaviour is untouched. Only `mouse_filter` and the deadzone change.

## 3. C — Home Rewarded Ads red "1" (owner decision)

- `HomeBadges.compute()` now has `rewarded_ads`: `1` iff `RewardedDailyService.slot_state(current_slot())` is `ready_free` (slot 1) or `ready_ad` (slots 2..5; `slot_state` returns `ready_ad` only when `can_start_daily` / the provider is available). Otherwise `0`: claimed, pending, ad_unavailable, locked_sequence, locked_rollback, unavailable, all claimed, or blocked / no app.
- Only the single sequential frontier counts, never future slots.
- `HomeScreen._render_values` calls the existing `RewardedAdsButton.set_badge(...)`, gated on the app serving that destination.
- It is recalculated on every Home refresh: route-to-Home, modal close, the 1 s Home timer and claims. Provider changes and day rollover are therefore picked up live.
- No saved badge state, and no change to grant, save, verified-video or sequential-unlock logic.
- The owner V02 decision supersedes the older R15 "no Home badge" wording **for this indicator only**. Two existing assertions encoded the old contract and were updated:
  - `tests/m43_master_c010_meta.gd` m10: a fresh day now expects `rewarded_ads: 1`; the "all handled" path also claims today's free slot through `actions.claim_rewarded_daily_free()`.
  - `tests/m43_r15_001_r01_sequential_unlock.gd` s14: the CTA geometry checks are unchanged; the old "model has no Rewarded Ads badge" assertion is replaced by "`rewarded_ads` follows the sequential frontier and the CTA badge matches".

## 4. Focused GUI-route evidence: `tests/m47_touch_r01_mobile_ux.gd`

Input routes:
- **Root-viewport cases** use `Input.parse_input_event()` with the project default `emulate_mouse_from_touch = true`, so **the engine itself** creates the emulated mouse in its real order.
- **Sized `SubViewport` cases** push the same engine order with `Viewport.push_input()` (emulated mouse with `DEVICE_ID_EMULATION`, then `ScreenTouch`).
- **Touch-scroll cases** set `Input.emulate_touch_from_mouse = true`, because headless Godot derives `DisplayServer.is_touchscreen_available()` from it (`display_server.cpp`). It is restored afterwards.

### Before (unfixed code at `309096e3`): FAIL, 18 failed checks, 14/14 cases run

| Area | Before |
|---|---|
| s01 single tap | `activations []`, occupied 0, gesture left pending |
| s02 rapid taps / s03 multitouch | 0 placements |
| s05 desktop click / long hold | **work** (1 each), which explains the owner's "hold" observation |
| s07 sizes | phone 1080×2160 3 cols / 5 slots: **0/3**; Flip-like 1080×2640 4 / 5 + insets: **0/4**; iPhone-like 1170×2532 5 / 5 + notch: **0/5**; iPad-like 1536×2048 3 / 6: **0/3**; Android tablet 1600×2560 5 / 6: **0/5**; phone 1080×2400 4 / 6: **0/4** |
| c01 album | 33 STOP controls; swipe up from VIEW **0 → 0 px**; from row title **0 → 0 px**; cannot reach Master; swipe down 0; reopen / wheel case FAIL |
| c05 other lists | RobotList 42 STOP, swipe 0 px; ShopList 26 STOP, swipe 0 px; ExtraList 2 STOP (swipe 349 px) |
| r01 / r02 badge | never shown: fresh slot 1 `ready_free` shows `{visible: false}`; `HomeBadges` has no key |

### After (`c2b1c3c7`): PASS, 14/14 cases, 0 fail, 0 SCRIPT ERROR

| Case | Result |
|---|---|
| s01 | one stationary tap → **exactly 1** `activation_result(ok)` and placement into the rightmost empty slot (4); no pending gesture |
| s02 | 3 rapid one-frame taps → 3 placements, total 4 |
| s03 | two fingers on two fronts → exactly 1 placement |
| s04 | taps on preview rows 1 / 2 → 0 |
| s05 | desktop mouse (device 0) → 1; stationary 40-frame hold → 1 |
| s06 | all slots full → one **rejected** activation (`slots_full`), slots + supply snapshots byte-identical; modal-blocked → 0 |
| s07 | **every** front, one tap = one placement: 1080×2160 3/5 **3/3**; 1080×2640 4/5 + insets **4/4**; 1170×2532 5/5 + notch insets **5/5**; 1536×2048 3/**6** **3/3**; 1600×2560 5/**6** **5/5**; 1080×2400 4/**6** **4/4** |
| c01 | album 0 STOP controls; finger swipe up starting **on VIEW** 0 → 422 px; on row title 422 → 877 px |
| c02 | repeated swipes reach the end; all 15 sets pass and the **Master row is fully visible**; swipe down scrolls back up; ~8.5 ms / frame during the swipes (headless) |
| c03 | a swipe that starts on VIEW opens nothing; a stationary tap on VIEW opens `collection_set` |
| c04 | 3× open → finger swipe → mouse wheel → close: every open scrolls by finger and by wheel |
| c05 | ExtraList 358 px, RobotList 341 px, ShopList 394 px; all 0 STOP. GiftList / AchievementList have no overflow in this fixture state (room 0), and 0 STOP. |
| r01 | fresh slot 1 → badge **"1"**; claimed + no provider → hidden; provider available → `ready_ad` → "1" with only ONE ready slot among the five; provider unavailable → hidden; ad pending → hidden; verified grant → next slot "1"; all five claimed → hidden; next local day → "1"; clock rollback → hidden |
| r02 | relaunch on the same save → recomputed (hidden without provider, "1" with provider); `HomeBadges.compute(null)` → 0 |

**Viewports:** in a sized SubViewport the app's stretch keeps the 1080-wide canvas; positions are pushed in canvas coordinates. Headless root viewport: 2160×2160 canvas, window transform 0.0296.

## 5. Regression (TEMP, final code)

**Final run: 71 / 71 suites PASS**, plus headless boot (`--quit-after 120`, exit 0) and `git diff --check` clean. The suites:
- `m47_touch_r01_mobile_ux` (new);
- all `m28_*` (7) and all `m29_*` (8) (supply / slot / input-gate / responsive layout);
- all `m39_*` (13);
- all `m42_*` (11, incl. home composition and V04–V07 safe area);
- `m43_c002_c001`, `m43_c003_c001`, `m43_c004_c001`;
- Phases 1–5;
- `m43_master_c005*`, `c006` shop, `c007` / `c007r` collection, `c008` robots, `c009` daily, `c010` meta, `c011_c014`;
- `m43_r15_owner_remediation`, `m43_r15_001_r01`;
- `m55_long_session`, `m55_core_chaos`, `m55_economy_release_regression`;
- `cp04`, `cp05` (+ `cp05_r01_transaction_cleanup`), `m35_level_catalog`, `m40_save_system`;
- root `run_tests` (`RESULT: ALL PASS`).

M49 (Responsive UI) has no dedicated suite in the repo; its viewport / safe-area coverage is the M42 composition / V07 safe-area and M28 layout suites above, plus s07. No M55 test was changed.

**First full run, disclosed (4 FAILs before the final run):**
1. `m43_master_c010_meta` and `m43_r15_001_r01`: the superseded no-badge assertions (§3). Updated to the owner decision.
2. `m43_master_c008_robots` static guard reported "BoardState / solver".
   - **Cause:** this Windows worktree uses `core.autocrlf=true`. My edit script rewrote `robots_screen.gd` (and other edited files) with LF, while the guard splits on a newline literal that is CRLF in its own checkout. The doc-comment lines then were not recognized as comments.
   - **Fix:** restored CRLF in the working tree. Git stores LF either way, so the committed content is unaffected and CI (LF) was never affected.
3. `m42_c003_scrubby_animation` reads `coordination/sessions/M42-C003/evidence_v03/…`, which my sparse worktree had excluded. It passed 18/18 once that folder was added. Environment only.

The four were then rerun individually, and the **entire battery was rerun** (71/71) as the final record.

## 6. New builds (GitHub Actions, source `c2b1c3c7`)

### Android Family APK: run https://github.com/Sekiph82/Scrubbots/actions/runs/38063215568 (success)

| Item | Value |
|---|---|
| Artifact | `ScrubBots-Family-First10-Android-Debug.apk`, id `11674660273`: https://github.com/Sekiph82/Scrubbots/actions/runs/38063215568/artifacts/11674660273 (zip-wrapped, 507,861,761 B, zip `sha256:049ebbcb0fb836293185ec90f1a69ebbbcabaeffd304f8bd793c22088a6140e3`, expires 2026-11-09) |
| APK SHA-256 | `36f0be58d6c1ea2a74b476cac12466d3db907d7975594976a2adb2e136ea55da` (513,563,824 B) |
| Inspection PCK | 483,058,656 B, SHA-256 `22a0ebdd4b5397e025446dd68311b9a76263815f67b01d1faef6e154a131737f` |
| Signature | `apksigner`: **Verifies**, v2 + v3, 1 signer (CI-generated debug key) |
| Package | `com.sekiph82.scrubbots.familydev`, **versionCode 3**, `0.1.3-family-first10-dev`; `arm64-v8a`; `screenOrientation=1`; `debuggable=true` |
| Export hygiene | all 9 owner-excluded trees **absent**; `PCK_SCAN … files=1982 forbidden=0 required=664 missing=0 main_scene=true verdict=PASS`; `APK_SCAN forbidden_total=0` (1,982 `assets/` entries; +2 files and +1 required path vs the first APK = the new `touch_scroll.gd`) |
| CI validate job | 13/13 PASS (Levels 1–10 catalog / progression, M55 long session, Home→Play→Results, save, offline CP04 / CP05, release regression, root `run_tests`) |

**Install note:** each workflow run signs with a new CI-generated debug certificate. Installing this APK over the first Family build requires **uninstalling the old app first**, and that **deletes the device's local save / progress**.

### iOS IPA: run https://github.com/Sekiph82/Scrubbots/actions/runs/38063217668 (success)

| Item | Value |
|---|---|
| Workflow | existing owner `ios-ipa.yml`, unchanged |
| Result | Godot iOS export + `xcodebuild` **`** BUILD SUCCEEDED **`** |
| Artifact | `Scrubbots-ipa`, id `11674890339`: https://github.com/Sekiph82/Scrubbots/actions/runs/38063217668/artifacts/11674890339 (zip-wrapped, 506,384,753 B, zip `sha256:9adb0a0541df0fc596512d7deacce1a820081dbf450623c93bd5a583eecc733d`, expires 2027-01-08) |
| Signing | **UNSIGNED by design** of that workflow (`CODE_SIGNING_ALLOWED=NO`). It is signed by the owner's xtool / Apple ID at install time. |
| Not computed | the inner `.ipa` SHA-256 (the workflow doesn't print it, and I did not download the ~500 MB artifact locally) |
| Not run | the owner iOS workflow has no packaged-path scan. Its preset `exclude_filter` lists the same 9 trees; the Android scan above is the hygiene proof for the shared export filter. |

The first iPhone IPA the owner tested is historical and **not** proof of this fix.

## 7. Scope

Changed files (fix commit `c2b1c3c7`):
- `scripts/ui/batch_supply_panel.gd` (A)
- `scripts/ui/components/touch_scroll.gd` (new, B)
- `scripts/ui/collection/collection_screen.gd`, `scripts/ui/daily/daily_screens.gd`, `scripts/ui/profile/profile_screens.gd`, `scripts/ui/robots/robots_screen.gd`, `scripts/ui/shop/shop_screen.gd` (one preload + one `TouchScroll.enable(scroll)` line each, B)
- `scripts/ui/home/home_badges.gd`, `scripts/ui/home/home_screen.gd` (C)
- `tests/m47_touch_r01_mobile_ux.gd` (new), `tests/m43_master_c010_meta.gd`, `tests/m43_r15_001_r01_sequential_unlock.gd` (superseded assertions, §3)

**Not touched:** gameplay / economy / reward authority, slots / supply engines, `ProductionInputController`, assets, `project.godot`, R2 / Remote Content, LevelData, the M47 / iOS workflows, Level Factory, M55 tests.

## 8. What remains for the owner (physical devices)

Install the **new** APK (uninstall the old one first; that loses local progress) on the Samsung Flip and the Samsung tablet, and the **new** IPA on the iPhone via xtool. Then check:
1. one tap on a front Supply batch → it lands in the rightmost empty slot, with no hold or drag;
2. Collection album: swipe up / down smoothly, including from a VIEW button; a tap on VIEW still opens the set;
3. Home Rewarded Ads shows a red "1" while today's next reward is claimable, and hides after claiming when no ad is available.

Final state: `AWAITING_CHATGPT_INDEPENDENT_AUDIT / OWNER_THREE_DEVICE_RETEST_PENDING`
