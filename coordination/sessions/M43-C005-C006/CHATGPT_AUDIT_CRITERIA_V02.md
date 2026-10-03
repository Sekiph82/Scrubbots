# M43-C005-C006 — CHATGPT AUDIT CRITERIA V02

Canonical task: **SB-M43-064**
Audit target: V02 Standard Pack interactive opening remediation.

## Owner sequence hard gate

- [ ] Initial shipping state shows Standard Pack alone.
- [ ] Opening does not auto-start.
- [ ] First deliberate player tap starts opening.
- [ ] Exact 01→09 order plays one current beat at a time.
- [ ] No 9-frame strip/contact sheet exists as shipping UI.
- [ ] Three committed cards emerge as continuation of final opening beats.
- [ ] Pack disappears after reveal.
- [ ] Exactly 3 card faces remain in final hold.
- [ ] Collection destination appears upper-left.
- [ ] Card Exchange destination appears upper-right.
- [ ] Destinations appear before resolve tap.
- [ ] Ceremony waits for second deliberate player tap.
- [ ] NEW cards visibly route only to Collection.
- [ ] DUPLICATE cards visibly route only to Card Exchange.
- [ ] Mixed outcomes split correctly.
- [ ] Completion occurs only after all 3 routing animations finish.

Any shipping composition showing pack + 01→09 strip + final cards together is FAIL.

## Truth / authority

- [ ] Exactly 3 precommitted results consumed.
- [ ] Card ids/order/art/name/rarity match committed truth.
- [ ] NEW/DUPLICATE matches committed truth.
- [ ] Duplicate post-commit count remains truthful.
- [ ] No reroll/open-again.
- [ ] No `open_standard()` / `open_premium()`.
- [ ] No RewardGrantService mutation.
- [ ] No CollectionInventory mutation.
- [ ] No Card Exchange mutation/conversion.
- [ ] No save/progression/navigation authority added.
- [ ] Routing is presentation-only.

## Sequencing / lifecycle

- [ ] Shared `RevealSequencer` remains sequencing authority.
- [ ] Extra Tap 1 input cannot create duplicate opening runs.
- [ ] Extra Tap 2 input cannot create duplicate routing runs.
- [ ] Completion fires once.
- [ ] Cancel/free/route clear removes timers/tweens/signals.
- [ ] Re-entry/reopen cannot duplicate callbacks/runs.
- [ ] Back/Escape cannot leave half-resolved state.

## Reduced Effects

- [ ] Same committed card truth.
- [ ] Same two interaction gates.
- [ ] Same destination meaning.
- [ ] NEW/DUPLICATE route correctly.
- [ ] Motion simplified, semantics preserved.

## Visual

- [ ] Pack-alone initial state is centered/readable.
- [ ] Opening is single animated state, not strip.
- [ ] Final three-card hold has no pack visible.
- [ ] All three cards readable before routing.
- [ ] Collection upper-left and Card Exchange upper-right do not obscure cards/safe area.
- [ ] NEW/DUPLICATE is non-color-only.
- [ ] Rarity readable.
- [ ] Duplicate count readable where applicable.
- [ ] Runtime evidence shows NEW card traveling to Collection.
- [ ] Runtime evidence shows DUPLICATE card traveling to Card Exchange.
- [ ] Required aspect ratios show no clipping/safe-area collision.

## Evidence

- [ ] `CLAUDE_LOG_V02.md` exists and cites V02 prompt + prior audit.
- [ ] `STANDARD_PACK_PRODUCTION_MATRIX_V02.md` exists.
- [ ] Real runtime captures cover pack idle, mid-open, late-open, three-card hold, destinations visible, mixed pre-route, NEW route, DUPLICATE route and completion.
- [ ] Both player-tap gates are observable.
- [ ] Evidence contact sheet is evidence only, not shipping UI.

## Tests / sensitivity

- [ ] Focused SB-M43-064 suite PASS.
- [ ] Explicit no-auto-start test PASS.
- [ ] Explicit no-auto-route test PASS.
- [ ] Mixed routing test PASS.
- [ ] Repeated-duplicate route test PASS.
- [ ] Static/source guard proves no mutation authority.
- [ ] Lifecycle/re-entry tests PASS.
- [ ] Reduced Effects semantic parity PASS.
- [ ] Wrong-destination sensitivity is detected.
- [ ] Auto-start sensitivity is detected.
- [ ] Auto-resolve sensitivity is detected.
- [ ] Stale-pack-visibility sensitivity is detected.
- [ ] SB-M43-063 regression PASS.
- [ ] Relevant M43 regressions PASS.
- [ ] Relevant M39 Collection/CardPack regressions PASS.
- [ ] Root suite PASS with no unexplained new failure.
- [ ] `git diff --check` clean.

## Scope / governance

- [ ] Claude did not edit root `TASKS.md`.
- [ ] Desktop checkout was synchronized non-destructively with latest `origin/main` before implementation.
- [ ] Owner-local work was preserved.
- [ ] SB-M43-065 not started.
- [ ] No later M43 ceremony or plugin work started.
- [ ] Claude only implemented/logged and handed back for independent ChatGPT audit.

## Closure

Even if technical audit PASSes, **SB-M43-064 remains open until OWNER VISUAL PASS of the V02 shipping ceremony**.
