STATUS: READY

# Build: SB-M49-029 ad / store return-transition layout (mock part)

## Summary
New headless suite `tests/m49_ad_store_return_layout.gd` runs on the real app root (`main.tscn`) with throw-away saves. It uses two TEST-ONLY provider subclasses: `OverlayAds` (extends AdProvider, which serves both rewarded and interstitial) and `OverlayStore` (extends StoreProvider). Each one simulates a platform overlay while it is up: FOCUS_OUT + PAUSED, then a landscape viewport resize plus a safe-area change, then size and insets back, then RESUMED + FOCUS_IN. The notifications are delivered the way SceneTree does it (`propagate_notification` from the root). After that the provider delivers completed, cancelled or failed.

Surfaces:
- r01 Shop store purchase
- r02 Shop restore (completed = No Ads owned; cancelled = nothing owned; failed = the store never answers)
- r03 LOST Results -> Need a Hand WATCH ("Results rewarded": the Results screen itself has no ad CTA)
- r04 Results WON -> Continue with a due interstitial (failed = no fill)
- r05 Home Rewarded Ads card (slot 2)
- r06 Home Heart + -> Life WATCH

Each surface runs at 720x1280 with the m49 notch, 1170x2532 with the notch, and 1080x2160 without a notch. The sizes, the notch and the stretch mapping come from `tests/m49_responsive_matrix.gd`. That makes 54 overlay cycles and 627 assertions.

No product layout bug was found, so no product code changed.

Files changed:
- `tests/m49_ad_store_return_layout.gd` (new)
- `.github/workflows/android-family-first10.yml`: append-only. The suite is added to the validate list, with a comment line and an exact `M49 ad/store return layout evidence: PASS (6/6 cases, 0 fail)` guard.
- `TASKS.md`: Autonomous Queue row and the SB-M49-029 entry set to PARTIAL / DONE-mock.

Commits:
- 331cb07b: suite + CI
- 20f5f75a: TASKS.md

## Acceptance criteria
1. [x] **Headless test on the real app root with throw-away saves, using a TEST-ONLY mock provider subclass that simulates focus out/in, paused/resumed, a resize while up and a safe-area change, then delivers completed / cancelled / failed.** Evidence: `tests/m49_ad_store_return_layout.gd`, with `user://m49_asr_*` saves deleted in `_cleanup`. For every cycle, the check "overlay really changed the layout while up" passes, which proves the resize and the inset change actually took effect.
2. [x] **After return, the layout equals the pre-overlay layout.** Two comparisons per cycle:
   - On return (before the result), the layout is compared with a snapshot taken right after the request. That snapshot includes the popup's own busy line.
   - After the result, once the result popups are off, the layout is compared with the snapshot taken before the request.

   The compared set: Home regions (PlayButton, 4 shortcuts, BottomNav, TopCurrencyHUD, GiftMeter, AdBannerSlot); gameplay board rect, BoardRegion, slot strip, supply panel, Pause, 4 boosters; the Results CTA; every popup frame; and the modal id list. The result is `[]` (no difference) for all 54 cycles.
3. [x] **Control rects stay inside the safe area.** "every rect inside the safe rect []" passes both on return and after the result. Results has no safe root, so it is measured against the screen, the same as m49 m08.
4. [x] **No stuck modal and no input blocker.** Checks per cycle:
   - The top popup is not busy after the result.
   - The stack returns to the pre-request depth.
   - A real platform-ordered tap on the surface popup's X closes it.
   - For the interstitial: the runtime is not paused or system-suspended, and a real tap on a supply front places that column.
5. [x] **Board region unchanged.** `game/board` and `game/board_region` are part of the equality checks in r03 (gameplay behind Results) and r04 (the next level under the interstitial).
6. [x] **Banner slot correct.** The Home AdBannerSlot visibility, `is_ad_slot_enabled()` and the provider's last `set_banner` all equal `StoreService.ads_allowed("banner")`. After a restored No Ads, the slot collapses: the banner flips to false, so the Home rects are exempt from equality in that one case. r04 also checks the provider banner.
7. [x] **Surfaces Shop purchase + restore, Results rewarded + Continue interstitial, Home rewarded card, Need a Hand / Life rewarded:** cases r01..r06, all PASS.
8. [x] **Viewport sizes from m49 including 720x1280 and 1170x2532 with a notch.** Both are covered with `RespMatrix.NOTCH` [0,132,0,96]; 1080x2160 runs without a notch.
9. [x] **Fix real layout bugs minimally:** none was found, so no product change.
10. [x] **Suite under 3 min is added to CI with an exact PASS guard, append-only.** It runs in 94-100 s locally. The workflow diff is +7/-1: one comment line, the suite name appended to the `for s in` list, and a new grep -qxF guard block after M54-CLOUD.
11. [x] **TASKS.md:** SB-M49-029 is PARTIAL / DONE-mock with the hashes. The real-device overlay check stays as a remaining note for the end-of-project phone tests.

Test-design notes (no product change):
- The Rewarded Ads slot-2 reward opens a `standard_pack` ceremony. It has no X, so the suite closes it programmatically. The pending pack then re-presents on Home after the surface popup closes, which is correct product behaviour, so the final tap check asserts that the surface popup itself is gone.
- r04 "failed" means the interstitial was not filled: `show_interstitial` returns false and the ad stays due. The overlay cycle still runs.

## Validation
Godot 4.7.2 (`Godot_v4.7.2-stable_win64_console.exe`, `--headless --path <wt>`). I ran `--import` once beforehand.

| Suite | Result | Exit | Time | SCRIPT ERROR / Parse Error | Last line |
|---|---|---|---|---|---|
| m49_ad_store_return_layout | LOCAL_PASS 6/6, 627 ok, 0 fail | 0 | 100 s | 0 | PASS |
| m57_ads_cadence | LOCAL_PASS 6/6 | 0 | 9 s | 0 | PASS |
| m57_store_products | LOCAL_PASS 9/9 | 0 | 5 s | 0 | PASS |
| m49_responsive_matrix | LOCAL_PASS 8/8 | 0 | 74 s | 0 | PASS |

- `git diff HEAD~1 HEAD --check`: clean. The workflow and TASKS.md keep their CRLF line endings.
- Cleanup: `git checkout -- .` restored `project.godot` and the re-imported `.import` files. The untracked `.import` / `.uid` files from the import were deleted one by one (no git clean). `git status --porcelain` is empty.
- Not pushed.

## Log
### Round 1
I read the ad/store/rewarded seams, the shop, Need a Hand, Life, Rewarded Ads and Continue paths, the safe-area roots and the main / runtime lifecycle notifications. Then I wrote the suite.

The first runs failed only on test-design issues, which I fixed:
- The pre-snapshot was taken before the busy line appeared.
- The gameplay insets were not applied at level start.
- The restore depth was wrong.
- Diff keys were duplicated.
- The Rewarded Ads pack ceremony has no X.

I found no product layout regression. I appended the suite to CI with the exact guard, updated TASKS.md and committed 331cb07b + 20f5f75a. Remaining work, outside this job: real AdMob / Play Billing / StoreKit overlays on a phone.
