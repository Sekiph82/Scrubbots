# M43-C004-C001 — CHATGPT AUDIT CRITERIA V01

Date: 2026-10-02
Scope: SB-M43-050..062

## Terminal loss / Retry
- [ ] Terminal LOST remains exactly-once.
- [ ] Fail displays committed truth.
- [ ] Retry after LOST consumes no second Heart.
- [ ] Retry does not reset streak twice.
- [ ] Home after LOST applies no second loss.
- [ ] Zero-Heart Retry routes to Life.
- [ ] Pause -> Restart behavior is unchanged.

## Failure assistance
- [ ] progression same-level failures only.
- [ ] third failure triggers once.
- [ ] V1 4+ suppression until reset.
- [ ] win resets.
- [ ] level change resets.
- [ ] replay excluded.
- [ ] threshold/repeat config is versioned.
- [ ] UI does not own counter.

## Recommendations
- [ ] exactly two distinct recommendations.
- [ ] both meaningful for canonical next start-state.
- [ ] deterministic.
- [ ] terminal board not mutated for ranking.
- [ ] no guarantee-of-win claim.
- [ ] fail closed if two meaningful choices unavailable.

## Need a Hand owner UI lock
- [ ] exactly two booster cards.
- [ ] each zero-charge card has its own BUY <price> SB.
- [ ] each zero-charge card has its own WATCH AD.
- [ ] two zero-charge cards visibly produce 2 BUY + 2 WATCH AD controls.
- [ ] no shared BUY.
- [ ] no shared WATCH AD.
- [ ] canonical prices.
- [ ] per-card rewarded availability.
- [ ] owned-charge state preserves charge-first UX.
- [ ] top-right X exists.
- [ ] no NO THANKS button.
- [ ] Back/Escape == X.
- [ ] dismissal has zero economy/gameplay effect.

## SB acquisition
- [ ] authoritative service/facade action, not UI wallet mutation.
- [ ] validates canonical booster id.
- [ ] reads EconomyConfig price.
- [ ] enough SB => exact debit + exactly one charge.
- [ ] insufficient SB => no debit/grant.
- [ ] insufficient route preserves exact ShopHandoff context.
- [ ] commit saves exactly once.
- [ ] rapid taps do not double-buy.

## Rewarded acquisition
- [ ] each card maps to exact booster:<id>.
- [ ] verified completion grants one selected charge.
- [ ] cancel/skip/fail/timeout/unverified grant zero.
- [ ] duplicate completion grants once.
- [ ] background/resume safe.
- [ ] one card unavailable does not disable other card.
- [ ] no ad SDK/tuning introduced.

## Terminal-board safety
- [ ] Need a Hand acquisition only grants a charge.
- [ ] no booster executes against terminal board.
- [ ] retry/use returns through canonical solver-safe gameplay path.

## Visual / responsive / lifecycle
- [ ] Fail production visual uses accepted family.
- [ ] no Victory/Replay/ad CTA on Fail.
- [ ] Need a Hand matches selected art direction and accepted family.
- [ ] 5 required viewport sizes pass.
- [ ] all CTAs fit and meet touch minimum.
- [ ] Reduced Effects preserves logic.
- [ ] 20-cycle open/close has no accumulation.
- [ ] one ModalStack authority, no input leak.

## Regression / hygiene
- [ ] focused C004 suite passes.
- [ ] M30/M39/M40/M42/M43 C001-C003/M52/M55 relevant regressions pass.
- [ ] root suite passes.
- [ ] git diff --check clean.
- [ ] root TASKS.md not edited by Claude.
- [ ] no unrelated owner/local files committed.
- [ ] focused commits pushed safely to main.
- [ ] CLAUDE_LOG_V01 and OWNER_VISUAL_REVIEW_V01 exist.

PASS requires every blocking item. Final production visual closure still requires owner review after technical audit.
