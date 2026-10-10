# M47-FAMILY-APK-TOUCH-R01 — ChatGPT Strict Audit Criteria V01
Date: 2026-10-10; repository `Sekiph82/Scrubbots`.
Status: AUTHORIZED / AWAITING_CLAUDE_IMPLEMENTATION. ChatGPT only may assign audit verdicts.

## 0. Owner requirement
One normal, **stationary** finger tap on an eligible front Supply batch immediately commits exactly **one** batch into the canonical **rightmost empty** execution slot. **NO swipe/drag/hold/destination tap** is required; original owner symptom says drag *appears* necessary, not that drag is desired.

## 1. Input correctness and proof
- Exact source and pre-fix real-scene reproducer identify whether the flaw was event delivery, press-release ownership, overlays/hit order, synthesized mouse dedup, geometry/scaling/safe area or transaction rejects.
- Test touch press and release on the **same visible cell center without motion** through the production scene and actual GUI input path, not only `activate_front()` direct calls. Must PASS after fix and FAIL before fix, without removing asserts.
- 3/4/5 supply columns × 5/6 slots; several Android-like portrait aspect ratios + safe insets; visual front hit alignment and no front-to-preview or adjacent overlap; center and reasonably inset edge taps.
- Repeated taps, mouse emulation, true touch events, multi-touch/touch indexes and jitter each generate **no missing or duplicate** transfer.
- Preview rows, gaps, empty/exhausted front, full slots, paused/modal/terminal conditions never consume or bypass production gates. Rightmost-empty slot target, FIFO, count, scheduler wake and UI snapshot remain correct.
- Desktop mouse remains functional. No drag requirement, huge gesture tolerance, synthetic success without an actual transfer or unapproved static-master change.
- Explicit diagnostic distinguishing `no gui_input` versus `activation_result(ok=false,error)`; do not assume unverified root cause.

## 2. Preservation
- `CLAUDE.md`, root `TASKS.md`, previous owner decisions read; TEMP worktree, Desktop safe sync before/after at 0/0, owner dirty/untracked/stashes/hashes preserved. No forced destructive Git, no unneeded massive local installs.
- Only narrowly related shipping input/UI source + tests + log may change. `TASKS.md`, prior audit files, gameplay rules, R2/remote content, economy/ads, Level Factory, M55 thresholds and accepted owner art unchanged.

## 3. Full regression / Android evidence
- Godot 4.7.2 parse/import, focused old/new input tests, M28/M29/M39/M40/M42/M43 relevant tests, `tests/run_tests.gd` ALL PASS, `git diff --check`; failures disclosed, no unacknowledged errors.
- Real rebuilt Android APK artifact in GitHub Actions, exact source SHA, run ID, signed package/arm64/portrait, artifact SHA256 and sizes, PCK/APK **0 forbidden packaged paths**, runtime-reference check PASS; only original offline scope, no R2 writer secret.
- Distinguish tested Android runtime from desktop/synthetic input simulation. No false claim of physical phone acceptance.
- Preserve older M47-001/002 build technical pass as historical, but **M47-004 BLOCKED** until owner confirms touch on revised real-device build.

## 4. Verdict and next gate
- `TOUCH_FIX_TECHNICAL_PASS / OWNER_DEVICE_RETEST_PENDING` only after independent source, tests, CI and artifact inspection.
- `CHANGES_REQUIRED` if tap still unreliable, any front-only/transaction rule relaxed, regression fails, artifact is invalid or input hit region is visually mismatched.
- **Owner device PASS** only after explicit owner confirmation that ordinary no-motion taps on the installed new APK easily transfer full batches. Do not silently close the gate from CI.
