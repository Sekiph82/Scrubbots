# M42-C003 V03 - Independent Audit Criteria

Date: 2026-10-01
Task: SB-M42-035

## Source / scope
- [ ] HOME-026 unchanged and hash matches authority.
- [ ] Exact 63 owner-approved source frames only; no new generated art.
- [ ] Counts 14/15/17/17.
- [ ] Root TASKS.md not edited by Claude.

## Canvas / normalization
- [ ] One deterministic common animation canvas for all 63 promoted frames.
- [ ] One common animation-space pivot.
- [ ] One uniform scale per visual source family, no per-frame scaling.
- [ ] No crop/warp/skew/nonuniform stretch.
- [ ] Deterministic resampler documented.
- [ ] 63/63 rerun bytes identical.
- [ ] Family scale report shows reasonable HOME-026 identity continuity.

## Runtime mapping
- [ ] HOME-026 keeps accepted M42-C002 geometry.
- [ ] Animation texture dimensions may differ but common animation pivot maps exactly to HOME screen soles pivot.
- [ ] Frame swaps produce no root/layout jitter.
- [ ] HOME -> gesture -> HOME transition has no obvious size pulse/root jump.
- [ ] Art_scrubby compatibility preserved.

## Screen-space safety
At all 4 required viewports:
- [ ] no Play CTA collision;
- [ ] no top HUD/currency collision;
- [ ] no functional shortcut/panel collision;
- [ ] no required-art viewport clipping.
- [ ] decorative helper overlap is reported, not hidden by frame shrinking.
- [ ] any helper z-order/visibility adjustment is presentation-only and lifecycle-safe.

## Gesture behavior
- [ ] Wave reads as one wave.
- [ ] Bow contains no late wave contamination.
- [ ] Turn/Look is bilateral right -> center -> left -> center.
- [ ] Full Turn is a real rare 360-degree turn.
- [ ] scheduler weights 35/30/25/10.
- [ ] no immediate repeat / no stack.

## Reduced effects / lifecycle
- [ ] large gestures disabled under Reduced Effects.
- [ ] hidden Home/modal/focus-out/pause gates work.
- [ ] fresh delay on resume, no catch-up burst.
- [ ] 20x enter/leave has no timer/signal/node accumulation.
- [ ] presentation-only, no gameplay/AppState mutation.

## Tests / evidence
- [ ] focused V03 tests pass.
- [ ] complete current suite passes.
- [ ] 4 contact sheets.
- [ ] 4 true-scale transition strips.
- [ ] 4 viewport captures.
- [ ] screen-space collision report.
- [ ] helper warning report.
- [ ] Reduced Effects evidence.
- [ ] lifecycle stability report.
- [ ] final assets and manifest SHA pins match.
- [ ] main pushed cleanly.

PASS requires every blocking item above.
