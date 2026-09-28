# M43-C001B — RESULTS VISUAL BINDING MATRIX V01 (completed under R01)

Date: 2026-09-28
Actor: Claude (implementer). No audit verdict is claimed.
Prompts:
- `coordination/sessions/M43-C001B/task_prompts/SB-M43-C001B_WON_RESULTS_VISUAL_BINDING.md`
- `coordination/sessions/M43-C001B/remediation/SB-M43-C001B-R01_COMPLETE_INTERRUPTED_RESULTS.md`

Owner authority: `coordination/OWNER_RESULTS_VISUAL_REPLAY_V01.md`
Focused evidence: `tests/m43_c001b_won_results_visual.gd` (11/11 cases, 49 ok)
Owner review pack: `coordination/sessions/M43-C001B/OWNER_VISUAL_REVIEW_V01.md`

## 1. Architecture (unchanged authority)

```text
M30 terminal -> host latched economy commit + save -> TerminalRewardReceipt (C001A, unchanged)
  -> nav RESULTS (payload unchanged) -> main._results_model(payload)
       = payload + receipt + continue{...} + reduced_effects (NEW, read from AppState.effects)
  -> ResultsScreen.show_model(model)
       WON         -> Victory composition (C001B)
       LOST/ERROR  -> technical fallback (no Victory art; M43-C004 replaces it for LOST)
```

These are unchanged:
- `TerminalRewardReceipt`, `FirstClearTransaction`, `WinStreakService`, `GiftMeterService`;
- the host terminal path, `NavigationController` and `continue_from_results`;
- `UiText` keys;
- economy numbers;
- all assets and manifests.

Production diff:
- `scripts/ui/results_screen.gd`: the layout.
- `scripts/app/main.gd`: one added model field, the `reduced_effects` bool.

## 2. Owner-lock compliance

| Owner lock | Implementation | Test proof |
|---|---|---|
| A1-NO: no Replay | Results has exactly two buttons (Primary, Home). There are no replay signals, routes, copy keys or code. | `no_replay`: source scan of Results, app root, nav, resolver and UiText; button list; signal list |
| B1-A: robot above/overlapping frame | Scrubby `victory_scrubby_pose.png` (340 px) sits above the frame, overlapping it by 96 px, with `z_index 1`. | `won_composition_bound`: robot rect starts above the frame top and ends below it |
| B1-A: small Victory emblem in header | `victory_emblem.png` at 96 px, inside the blue `Header` ribbon next to the live title | `won_composition_bound`: emblem is a descendant of Header, 96 px, < 20 % of frame width |
| B1-A: Scrubby until equipped-robot authority | Fixed `ROBOT_ART` = Scrubby | same |
| B2-A: green/yellow Life/Help Continue | `HomeStyle.style_play_button` (green body, dark-green bevel, 112 px). The cyan `continue_button_frame.png` is not used. | `won_composition_bound` (bg == `HomeStyle.GREEN`); `art_and_manifest_governance` |
| Home secondary | Beige 88 px button, smaller body-size text | `won_composition_bound`: Home height < Continue height, not green |
| Life/Help family | Cream panel, 12 px royal-blue rim, 44 px radius, blue header ribbon, beige reward cards. All native StyleBoxes, no generated chrome. | `won_composition_bound` (frame colours) |
| B3-A: LOST not Victory | `_apply_layout(false)`: no theme, no robot/emblem texture, slot hidden, pre-C001B dark panel, rows as plain text only | `lost_no_victory_art`: no TextureRect with a texture anywhere; WON→LOST switch leaves no art behind |
| Live text | Title, Level, reward rows, note and CTA labels all come from `UiText.t()` with live values | `won_composition_bound`, `rows_match_receipt_order` |

## 3. Reward truth and sequence

| Rule | Implementation | Test proof |
|---|---|---|
| Rows only from committed receipt | `ResultsScreen.reward_rows(receipt)` maps `reveal_queue` entries (5 known kinds) plus a `gift_milestone` follow-up. Anything else yields no row. | `rows_match_receipt_order`: kinds == reveal_queue + follow-up; an unknown kind produces no row |
| Locked order | first-clear SB → Win Streak SB → Bot Parts → Gift Meter → cards (if committed) → gift-ready | same (exact list asserted) |
| Approved icons | SB currency icon, Win Streak badge, Bot Parts icon, Gift Meter emblem, Standard card pack (only when cards are committed), gift box | same (per-row `resource_path`) |
| Ordered reveal = presentation only | Rows are all created at `show_model`. A Tween fades them in one by one, 0.16 s each, via `modulate:a` only. `finish_reveal()` fast-forwards. | `reveal_presentation_only`: economy snapshot and reward tx count unchanged across reveal, 5× refresh and fast-forward; earlier rows are never behind later ones |
| Continue never gated by the reveal | CTA is live throughout | same: Continue mid-reveal → exactly one transition |
| Reduced Effects | `model.reduced_effects` = `AppState.effects.is_reduced()`; no Tween runs and every row is fully visible immediately | `reduced_effects_static` |

## 4. Foundation invariants (C001A) preserved

| Invariant | Proof |
|---|---|
| Results never grants | C001A `results_never_grants_source` (66 ok); C001B reveal/refresh economy checks |
| Continue exactly once | C001A `rapid_continue_once`; C001B `continue_once_visual` (10 taps on the styled CTA → 1 intent, Level 2) and Continue mid-reveal |
| Stale / LOST Continue rejected | C001A `stale_continue_rejected` |
| Level 10 → 11 CONTENT_MISSING | C001A `level10_no_next_content`; C001B `level10_unavailable_visual` (disabled CTA, note inside frame, no mutation) |
| LOST Retry (M30) | C001B `lost_no_victory_art` (Retry on same host, attempt 2); C001A `lost_retry_regression` |
| Hidden Results releases transient nodes | C001B `hide_show_no_leak`: 20 hide/show/refresh cycles give node count 36 → 36, no added signal connections, and hiding frees rows and stops the Tween; M55 long session back to baseline |

## 5. Responsive fit (`responsive_fit`, worst case = Level 10 rich receipt: 5 rows + note)

| Viewport | Frame rect | Result |
|---|---|---|
| 1080×1920 | (100, 582) 880×1000 | frame ≥16 px inside viewport, robot on screen, every visible label inside frame, CTA/Home ≥ 88 px tall and ≥ 300 px wide |
| 1080×2160 | (100, 702) 880×1000 | same |
| 1080×2400 | (100, 822) 880×1000 | same |
| 1215×2160 (16:9 stretch-expand logical) | (167, 702) 880×1000 | same |

Project stretch is `canvas_items` + `expand` with base 1080×2160, so no portrait device gets a logical width below 1080.

## 6. Sensitivity (each mutation run against the focused suite, source restored byte-identical — verified with `cmp`)

| Mutation | Result |
|---|---|
| add a `ReplayButton` to Results | exit 1, FAIL 2 (no-replay source scan, button list) |
| LOST shows the robot slot and texture | exit 1, FAIL 3 (LOST no robot; LOST no texture; WON→LOST leftover) |
| remove the Continue latch/disable | exit 1, FAIL 1 (10 taps → 1 Continue) |
| reverse reward-row order | exit 1, FAIL 1 (row order) |
| stop clearing rows on refresh | exit 1, FAIL 1 (refresh keeps 4 rows) |
| frame width 1100 | exit 1, FAIL 3 (fit at 1080×1920 / 2160 / 2400) |

## 7. Evidence harness (R01 fix)

`tests/tools/results_snapshot.gd` drives WON levels with the same driver as `tests/m55_long_session.gd`:
- levels with an owner supply plan follow its `intendedColumnClicks`, loaded through `SupplyPlanLoader`;
- Level 1, which is generator-supplied, uses greedy fronts.

There is no solver and no new batch/colour solution. Clicks applied: Level 3 → 51 owner clicks, Level 10 → 40 owner clicks.

A shot is saved only when all of these hold:
- the Results status equals the requested one;
- the route is RESULTS;
- for WON, the completion authority reports WON **and** the board has 0 ACTIVE cells.

Otherwise it prints `REJECTED` and the run exits 1. The final run saved all 6 shots, rejected none, and exited 0.

All pre-R01 images, including the four invalid "LEVEL FAILED" ones, were deleted before rendering.

## 8. Asset / manifest governance

- Every bound file is under `assets/ui/final/` and its SHA-256 is pinned in the test (`art_and_manifest_governance`). None was modified or regenerated.
- `victory_results` stays `MASTER_REQUIRED`. The manifest schema has no non-owner "candidate" status between `MASTER_REQUIRED` and `MASTER_OWNER_APPROVED`, so it was left unchanged.
