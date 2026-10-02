# M43-C001R-C001 — CHATGPT AUDIT CRITERIA V01

Date: 2026-10-02
Scope: SB-M43-R01-001..008

## Canonical next-content truth
- [ ] Next Cleanup resolves through canonical progression + production catalog.
- [ ] No alternate campaign sequence/state is created.
- [ ] Available teaser uses the exact real catalog preview.
- [ ] Difficulty/class is canonical.
- [ ] Any color/palette count shown is canonical, not guessed.
- [ ] Missing content is honest and fail-closed.
- [ ] Production Level 10 correctly treats absent Level 11 as unavailable.

## Teaser disclosure
- [ ] Versioned config exists and validates fail-closed.
- [ ] V1 visible fraction is 0.20 and constrained to 0.15..0.25.
- [ ] Crop is deterministic by stable level identity.
- [ ] Crop stays within texture bounds.
- [ ] Normal presentation never exposes full next preview.
- [ ] Reduced Effects never exposes full next preview.
- [ ] Missing preview cannot fall back to another level image.
- [ ] No generated/fabricated teaser art.

## 10-Level Cleaning Journey
- [ ] Exactly 10 nodes.
- [ ] Cycle math is canonical and deterministic.
- [ ] Slot 5 has mini-boss presentation.
- [ ] Slot 10 has cycle-boss presentation.
- [ ] Nodes are informational/non-tappable.
- [ ] No Level Select/skip/unlock behavior.
- [ ] Home uses current frontier semantics.
- [ ] Results uses just-completed-level semantics.
- [ ] Results L9 -> 9/10 and next L10.
- [ ] Results L10 -> 10/10.
- [ ] Home frontier 11 -> new cycle slot 1.
- [ ] Journey derives from progression and has no second persisted counter.
- [ ] Save/reload continuity follows progression snapshot.

## Momentum corridor
- [ ] Reward/economy commits remain before UI.
- [ ] Accepted C001B reward row truth/order is preserved.
- [ ] Journey/progress summary follows committed rewards.
- [ ] Next Cleanup follows required barrier state.
- [ ] Primary CTA is CLEAN NEXT when content exists.
- [ ] Home remains secondary.
- [ ] Missing content disables CLEAN NEXT.
- [ ] No fake reward/urgency/near-miss messaging.
- [ ] Reduced Effects shows final info immediately without changing logic.

## Future ceremony barrier
- [ ] No M43-C005 ceremony implementation is introduced.
- [ ] Narrow barrier seam exists.
- [ ] Active barrier holds teaser/CLEAN NEXT.
- [ ] Releasing barrier reveals same already-resolved truth.
- [ ] Barrier mutates no reward/progression/economy.
- [ ] SB-M43-013 remains open/out of scope.

## CLEAN NEXT navigation safety
- [ ] Uses canonical existing Results Continue route.
- [ ] Exactly-once/double-tap protection remains.
- [ ] Stale Results attempt protection remains.
- [ ] Heart zero gate remains.
- [ ] Missing content cannot launch.
- [ ] No duplicate grant.

## Home integration
- [ ] Uses same journey read authority as Results.
- [ ] Existing Win Streak track is not repurposed.
- [ ] No World Diorama/new destination.
- [ ] Journey nodes have no input actions.
- [ ] Accepted Home composition is only minimally extended.
- [ ] No Play/BottomNav/Gift/Ad-slot collision across viewport matrix.

## Economy/difficulty non-interference
- [ ] No reward changes.
- [ ] No Gift Meter changes.
- [ ] No Heart changes.
- [ ] No Win Streak changes.
- [ ] No booster/ad changes.
- [ ] No cadence/difficulty changes.
- [ ] No personalized dynamic difficulty.
- [ ] No new journey reward.

## Tests / evidence
- [ ] Focused C001R suite directly tests all required properties.
- [ ] Teaser full-preview non-disclosure assertion is sensitive/non-vacuous.
- [ ] Journey 9->10->next1 boundary is tested.
- [ ] Save/relaunch continuity is tested.
- [ ] Ceremony barrier hold/release is tested.
- [ ] Responsive evidence covers 1080x1920, 1080x2160, 1170x2532, 1290x2796, 1536x2048.
- [ ] Reduced Effects evidence exists.
- [ ] Lifecycle repeated show/hide/refresh does not accumulate.
- [ ] Owner review pack exists and does not self-approve.

## Regression / governance
- [ ] M35 catalog relevant tests pass.
- [ ] M36/M37 progression relevant tests pass.
- [ ] M40 pass.
- [ ] M42 Home/navigation relevant tests pass.
- [ ] M43-C001A pass.
- [ ] M43-C001B pass.
- [ ] M43-C004 pass.
- [ ] root suite passes.
- [ ] git diff --check clean.
- [ ] Claude did not edit root TASKS.md.
- [ ] no unrelated owner/local files committed.
- [ ] focused commits pushed safely to main.
- [ ] CLAUDE_LOG_V01.md exists.

Technical PASS still requires OWNER visual acceptance before SB-M43-R01-001..008 close.
