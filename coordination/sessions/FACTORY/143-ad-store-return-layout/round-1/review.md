# Review round 1: 143-ad-store-return-layout (SB-M49-029 mock part)

## Reproduced runs (worktree, throw-away saves, after --import)
- m49_ad_store_return_layout: exit 0, 627 ok lines, 0 FAIL / SCRIPT ERROR. Last evidence line: `M49 ad/store return layout evidence: PASS (6/6 cases, 0 fail)`.
- m57_ads_cadence: exit 0, `M57 ads cadence evidence: PASS (6/6 cases, 0 fail)`.
- m60_release_gates: exit 0, `M60 release gates evidence: PASS (6/6 cases, 0 fail)`. Its table prints `FAIL SB-M60-006` and BLOCKED OWNER-* rows. That is the suite's own gate table; the verdict and the exit code are PASS and this branch does not touch it.

## 1. Does the test prove the spec? Yes.
- It runs on the real main.tscn in a sized SubViewport.
- The overlay is real in effect: FOCUS_OUT and PAUSED, a landscape resize plus an inset change, then everything restored, then RESUMED and FOCUS_IN. Each cycle asserts that the layout did change while the overlay was up. The overlay therefore cannot be a no-op.
- Rect equality is direct: Home regions, board, slots, supply, pause, boosters, Results CTA, every popup frame and the modal id list. It is checked on return and again after the result.
- The safe-rect containment check is separate.
- Busy and blocker checks:
  - the top popup is not busy after the result;
  - the stack depth is back to the pre-request depth;
  - a real emulated tap on the X closes the popup;
  - in r04 a real tap on a supply front places the column, and the runtime is not suspended.
- Grants are asserted on completed only.
- Mutations I ran, each reverted:
  - Skip the resize restore (`_sub.size = _lv`). FAIL at once: layout on return differs (Home HUD, banner and shop frame all moved) and the rects fall outside the safe rect.
  - The provider never delivers the result, so the popup stays busy. FAIL: top popup not busy, layout after the result differs, and the tap does not close the popup.

## 2. The two loosened checks: narrow and justified
- Banner exemption (`skip_banner`):
  - It applies only when `banner_changed` is true, which is only the r02 completed case, where the restore sets No Ads.
  - It skips only keys starting with `home/` and the `banner` key. Modal rects, the modal ids and everything else are still compared.
  - The banner state is asserted separately by `_banner_ok`. That checks the slot visibility, `is_ad_slot_enabled`, the provider's last `set_banner` and `ads_allowed("banner")`.
  - Minor: Home regions are therefore not compared in that one case, even though only AdBannerSlot legitimately changes. This is optional to tighten (see Notes).
- Programmatic close of the pack ceremony:
  - `standard_pack_ceremony.gd` calls `set_close_enabled(false)`. The header documents "Back is consumed ... never dismissible, so nothing is left half-resolved".
  - The exit is the tap flow: tap to open, skip stages, then COLLECT or a tap, which ends in `close("complete")`.
  - A ceremony with no X is the owner-locked design, not a stuck-modal bug. The test only uses `close()` on popups whose close button is not visible, and says so in the assertion text.
  - The ceremony's own tap flow is out of scope here and covered by other suites. The surface popup underneath is still closed with a real tap and that is asserted.

## 3. Test-only providers
`OverlayAds` and `OverlayStore` are inner classes in `tests/m49_ad_store_return_layout.gd` only. A grep over the repo finds them nowhere else. No product file changed (diff: the test, the workflow and TASKS.md).

## 4. CI append
- The workflow diff is +7/-1, append-only.
- It adds one comment line, the suite name at the end of the `for s in` list, and a new guard block after M54-CLOUD using `grep -qxF 'M49 ad/store return layout evidence: PASS (6/6 cases, 0 fail)'`.
- The string matches the suite's exact output. About 100 s of runtime is acceptable.

## 5. TASKS honesty
- The Autonomous Queue row and the SB-M49-029 entry are PARTIAL / DONE-mock.
- They state LOCAL_PASS only, no CI run, no phone build, and that real AdMob / Play Billing / StoreKit overlays on a device remain. The checkbox stays `[ ]`. Honest.
- The cited hash 331cb07b is the suite commit. The TASKS commit is 20f5f75a. Fine.

## Notes (non-blocking)
- `_diff` precedence: `skip_banner and A or skip_banner and B` works as intended. Add parentheses for readability.
- Tightening idea: with `banner_changed`, skip only `home/AdBannerSlot` and `banner`. Home siblings might shift when the banner collapses, so verify before adopting.
- The build.md validation table cites m57_store_products and m49_responsive_matrix. I did not re-run them because they were not in the requested list. The branch changes no product code, so they are unaffected.
- Cleanup done: `git checkout -- .` and the untracked import `.import` / `.uid` files removed.

No must-fix items.

VERDICT: PASS
