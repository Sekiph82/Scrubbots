# M49 Responsive UI — CLAUDE_LOG_V01 (autonomous V02)

Plan: `CLAUDE_M49_MASTER_PLAN_V01.md` · 2026-10-15 · Builder: Claude Code.
**Status: `IMPLEMENTED_7_OF_8_CASES_CI_PASS / M06_TEST_FIXTURE_FIX_PENDING_CI / CI_BUDGET_1_PLUS_1_USED`.** Not peer-reviewed yet; not independently audited.

## What was built
- `tests/m49_responsive_matrix.gd`: one permanent cross-surface suite (8 cases, exact ledger) on the REAL `main.tscn` app root and the production `GameplayScreen`.
  - Sized SubViewports mapped from 8 physical devices to the stretch canvas (1080×2160 reference, `canvas_items` / `expand`).
  - Synthetic notch insets 0 / 132 / 0 / 96.
  - Measurement only; **no production code changed**.
- Existing workflow: + `m49_responsive_matrix` (36 suites) with exact guard `M49 responsive matrix evidence: PASS (8/8 cases, 0 fail)`.

## CI (existing workflow, `validation_only`; budget 1 planned + 1 remedial, both used)
| Run | SHA | validate | export | Result |
|---|---|---|---|---|
| [38744551437](https://github.com/Sekiph82/Scrubbots/actions/runs/38744551437) | `ae1913d3` | failure | skipped | **35/36 PASS** (incl. M44 23/23 with the D2 V02 LOW fixes, CP06 16/16, M45 8/8). m49: **m01–m05, m07, m08 PASS**; m06 aspect exact on all 6 boards but "inside BoardRegion" FAILED. |
| [38746625415](https://github.com/Sekiph82/Scrubbots/actions/runs/38746625415) | `51e4e904` | failure | skipped | Same 35/36. m06 diagnostic proved a **TEST FIXTURE** defect, not a product layout defect: `board [0,0 24x40] region [0,0 0x0]` — the standalone screen was never sized (the SubViewport size was set before `add_child`, so full-rect anchors kept it 0×0 and cells were 1 px). |

Both runs: artifact logs only, no apk / pck / ipa; `import script_diag=0`.

## Fix (committed after the budget; NOT yet CI-validated)
- `tests/m49_responsive_matrix.gd` m06: `screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)` after `add_child`. m28's smoke avoids the issue by resizing the viewport after adding the screen.
- No dedicated rerun (the budget is spent). It will be exercised by the NEXT planned milestone run, which runs the whole matrix anyway; that result will be reported against M49 m06 explicitly.

## Per-row disposition (evidence = run 38746625415 m49 log unless stated)
| Rows | Status |
|---|---|
| 001–006, 014–019 (aspect classes, required phones, notch) | m01 + m02 + m03 PASS |
| 007, 008, 023 (five slots, board visible, Pause / 2x / rails / slots / supply / boosters usable) | m03 PASS (incl. notch) |
| 010 (touch mapping) | m04 PASS: a real platform-ordered tap at each front centre placed exactly that column on 720×1280, 1080×2160 and 1440×3200 devices |
| 011–013 (reference viewport, SafeAreaRoot, tokens) | already implemented (`project.godot`, `safe_area_root.gd`, `ui_tokens.gd`); exercised by m02 / m03 / m07 |
| 020 (minimum touch target) | Home buttons + boosters ≥ 88 px PASS. Supply front hit areas: measured inside / non-overlapping, but not held to 88 px (the shell art sets their size) — recorded, not claimed. |
| 021, 028 (popups in the safe area, modal stack) | m07 PASS: Tasks / Daily / Gift / Shop / Collection / Robots / Events / Profile / Help under a notch on 720×1280, 1440×3200, 1536×2048. Scroll behaviour: existing M47 suite. |
| 025 (sixth slot) | m05 PASS on all 8 devices (6-slot shell, six views inside, no overlap) |
| 026, 031, 032 (M43 / M44 surfaces, journey) | m08 PASS (Results WON CTA ≥ 88 px, journey inside); full surface inventory not exhausted — partial |
| 009 (rectangular boards) | aspect exact (24×40, 40×24, 59×59); containment: fixture fixed, CI pending |
| 022, 027 (localization expansion / long labels) | OPEN — needs a pseudo-locale strategy |
| 029 (rewarded / store return) | DEPENDENCY_GATED (no production ad provider) |
| 030 (deep links / cloud conflict) | deep links PASS (m07); cloud-conflict screens not implemented — gated |
| 024 (automated evidence) | this suite |

## Process notes
- One shell command chained two 590 s CI watches and exceeded the tool's 600 s limit. The harness moved it to the background (task-owned output file under the session temp folder); it was deleted after completion. The completed reviewer transcript files were also deleted.
- Tracker: local `TASKS.md` writes are denied by the client permission check. ChatGPT please record M49 as above (do not close 009 until m06 passes in CI).

## Resume pointer
Next planned milestone run will include the m06 fix. Then a fresh `CLAUDE_PEER_REVIEW` of M49. Next milestone candidate: M50 Accessibility.

## Addendum — m06 fix exercised + peer review
- The M50 planned run [38748970964](https://github.com/Sekiph82/Scrubbots/actions/runs/38748970964) on `bf333df4` (descendant of the fixture fix `b530f8ba`; NOT a dedicated M49 rerun) gave **M49 verdict=PASS (8/8)**, 37/37 suites, export skipped.
  - m06: all 6 boards (24×40, 40×24, 59×59 on two devices) were drawn inside the rail and BoardRegion, e.g. `board [190,295 833x833] rail [160,255 894x913] in_rail=true in_region=true`.
- `CLAUDE_PEER_REVIEW_M49_V01.md`: PASS_WITH_CONCERNS for m01–m05 / m07 / m08; CHANGES_REQUIRED for the m06 assertions.
  - Test-only fixes applied after the review (drawn-rect measurement, hard containment, deep-link return check, journey visibility diag). They are NOT yet CI-validated; the next planned run exercises them.
- Row 020 narrowed: Home PLAY / panels and boosters ≥ 88 px are asserted; nav-tab and Pause / 2x sizes are not.
- Rows 031 / 032: PARTIAL (journey visibility is not asserted).
- Tracker request (ChatGPT):
  - M49: 001–008, 010–019, 021, 023–025, 028 technically evidenced;
  - 009 evidenced (run 38748970964) — final re-check pending with the strengthened m06;
  - 020 / 026 / 030 / 031 / 032 PARTIAL;
  - 022 / 027 / 029 OPEN or gated.
