# M43-C003-C001 — LIFE / BOOSTER / 2X ACQUISITION SURFACES

Status: READY FOR CLAUDE
Date: 2026-09-28
Repository: `Sekiph82/Scrubbots`
Branch: `main`

## Mission

Implement the production acquisition surfaces required by M43-C003:

- canonical Life / Hearts popup;
- Home Heart + and zero-Heart attempt-gate routing into that same Life popup;
- +1 Heart and full-refill SB purchases;
- rewarded +1 Heart flow;
- reusable data-driven Booster Acquire popup for all four canonical boosters;
- charge-first booster behavior with SB/rewarded acquisition only at zero charge;
- canonical 2x Acquire popup;
- Scrub Bucks + / insufficient-SB Shop handoff with return context;
- transaction safety, idempotency, background/resume safety and visual evidence.

This cycle covers root TASKS rows **SB-M43-030 through SB-M43-049**.

Do **not** edit root `TASKS.md`. ChatGPT owns tracker state.

## Read first

1. `CLAUDE.md`
2. root `TASKS.md` READ ONLY
3. `coordination/AUDIT_POLICY.md`
4. `coordination/sessions/M43-C002-C001/CHATGPT_AUDIT_V01.md`
5. `coordination/sessions/M43-C002-C001/OWNER_POPUP_PAUSE_GATE_V01.md`
6. `coordination/OWNER_FAILURE_RECOVERY_AND_ACQUISITION_V01.md`
7. `coordination/OWNER_ECONOMY_REWARDS_V01.md`
8. `coordination/OWNER_HEART_REGEN_INTERVAL_V01.md`
9. `coordination/OWNER_TIMED_2X_CLOCK_ROLLBACK_V01.md`
10. `docs/17_LIVEOPS_ANALYTICS_NOTIFICATIONS_MONETIZATION.md`
11. `data/config/economy_rewards_v1.json`
12. current M42 Home V06/V07 implementation and tests
13. current M28 Gameplay V02 / ProductionGameplayHost input path
14. M39/M40 economy/save authorities
15. M55 timed-2x anti-rollback authority
16. existing `scripts/ui/speed_acquisition_popup.gd`
17. `assets/ui/VISUAL_ASSET_INDEX.md`
18. Life visual authority: `assets/art/references/_owner_inbox/Additionals/life screens.png`

## Owner-locked corrections / precedence

### Hearts
The newest Heart ruling wins:

- max Hearts = **5**
- passive regen = **900 real-world seconds / 15 minutes**
- +1 Heart = **500 SB**
- full refill = **400 SB per missing Heart**
- when full, Home/Life may show canonical static **15:00 ready state**
- wall-clock/background/offline behavior remains authoritative
- do not reintroduce the superseded 30-minute Heart interval from older documents

### Rewarded ads
Approved V1 rewarded products in this cycle:

- **+1 Heart**
- **one charge/use for each of the four canonical boosters**

Do **not** add rewarded-video CTAs to Pause, Restart, Leave, generic Reward, Error, Loading, or generic Insufficient-SB popup surfaces.

Do **not** add rewarded 2x in this cycle.

Real ad provider/placement IDs, frequency, cooldown, cap, regional policy and No-Ads interaction are **M57 provider/tuning work** and must not be hardcoded here.

## Architecture lock

Reuse the owner-approved M43-C002 popup/modal foundation.

Do not create a second popup manager, second modal stack or parallel economy authority.

All UI is presentation/intent only. Durable truth remains in existing Economy V1 services and the production action/save boundary.

Where the current economy layer lacks a safe rewarded-grant seam, add the smallest authoritative service/facade extension needed so:

- the UI never directly increments Hearts or booster charges;
- each rewarded grant uses a stable transaction/reward token;
- duplicate callback/retry/relaunch cannot double-grant;
- completion is committed before success is shown;
- cancel/skip/fail/timeout gives nothing.

Prefer extending the existing RewardGrantService / EconomyServices / ProductionActionFacade architecture over inventing a second reward ledger.

## A. Canonical Life popup

Implement one canonical Life popup in the approved popup family, using the selected Life reference for art direction while keeping all text/counts/timers/prices live in Godot.

It must show:

- current Hearts / max Hearts;
- live real next-Heart countdown when below max;
- canonical full-state presentation at 5/5, including static 15:00 ready state where the accepted Home language expects it;
- current SB balance;
- +1 Heart offer: **500 SB**;
- full refill offer: **400 SB × missing Hearts**, dynamically computed;
- rewarded-video +1 Heart CTA only when rewarded placement is available and policy allows it;
- deterministic unavailable/disabled state when rewarded placement is unavailable.

Do not bake dynamic values into art.

### Life entry points

The SAME Life surface must open from:

1. Home Heart `+`;
2. zero-Heart attempt gate.

No second inconsistent “out of lives” dialog.

Closing Life without buying/watching has no economy/gameplay side effect.

## B. Heart SB transactions

Use the real production action/economy authority.

### +1 Heart
- costs 500 SB;
- must fail closed if already full or insufficient SB;
- one user action => at most one debit and one Heart grant;
- success updates live UI from authoritative state.

### Full refill
- cost = 400 SB × current missing Hearts;
- computed from authoritative live state at commit time, not stale display state;
- atomic;
- insufficient funds => no partial refill/no debit;
- at full Hearts => disabled or deterministic “already full” state.

If an SB purchase fails because balance is insufficient, use the M43-C002 insufficient-SB/Shop handoff and preserve the pending Life acquisition context.

## C. Rewarded Heart

Implement a provider-neutral rewarded acquisition seam.

Production default may be “unavailable” until M57 connects a real provider.

Required behavior:

- UI asks the seam whether the Heart rewarded placement is currently available/allowed;
- starting the rewarded flow locks duplicate taps;
- only a verified completed reward callback may commit +1 Heart;
- cancel/skip/provider failure/timeout/unverified callback grants nothing;
- duplicate completion callback grants exactly once;
- background/foreground during an unresolved reward cannot duplicate the grant;
- if Heart became full before commit, fail closed without inventing >5 Hearts;
- durable save boundary occurs on committed grant;
- success UI appears only after authoritative commit.

Do not simulate successful ads in production merely because no provider exists. Test doubles may simulate provider outcomes.

## D. Scrub Bucks + / Shop handoff

Home Scrub Bucks `+` must invoke the canonical Shop/SB acquisition route.

Do not implement the full M43-C006 Shop catalog in this cycle.

If a Shop destination/shell already exists, route to it. If it does not, implement only the minimal navigation/return-context contract needed for M43-C003 so that:

- the intent is explicit and testable;
- pending acquisition context is detached from the popup instance;
- later Shop implementation can fulfill/cancel and return safely;
- no fake SB pack purchase is invented.

The same handoff mechanism is used after insufficient-SB from Life/Booster/2x.

## E. Reusable BoosterAcquirePopup

Implement exactly **one** reusable data-driven Booster Acquire popup/equivalent production component.

Do not build four copy/pasted scenes.

It receives booster definition data and displays:

- canonical booster icon;
- booster name;
- concise effect explanation;
- owned charges;
- live canonical SB price;
- SB acquire/use CTA;
- rewarded acquire/use CTA only when provider policy says that booster placement is available;
- unavailable/safety state when the booster cannot legally execute.

Canonical boosters/prices:

- +1 Slot = **500 SB**
- Random = **350 SB**
- Selector = **500 SB**
- Tornado = **750 SB**

Use existing production icons in `assets/ui/final/boosters/`.

## F. Charge-first gameplay rule

Before opening Booster Acquire:

- if the selected booster has >=1 owned charge and is legally executable, use the existing charge-first canonical gameplay path;
- do not open purchase UI unnecessarily;
- do not charge SB when a charge exists.

With zero charge:

- open Booster Acquire;
- SB path purchases/commits exactly one legal use under the existing BoosterService/BoosterInventory transaction rules;
- rewarded path grants exactly one charge/use after verified completion, then proceeds only through the canonical legal-execution path.

Do not bypass solver safety.

### Booster safety invariants

+1 Slot:
- cannot stack beyond 6;
- max once per attempt.

Random:
- must satisfy existing solver-safe >=3 front-selection rule;
- unsafe result consumes nothing.

Selector:
- only safe eligible batches;
- requires capacity;
- no legal choice => consumes nothing.

Tornado:
- selected color must be present;
- authoritative multi-system transaction/rollback stays intact.

For a rewarded booster grant, if legal execution is not currently possible after the reward has been granted, **do not consume the newly granted charge**. Preserve it for a later legal use.

## G. Canonical 2x Acquire popup

Replace/converge the current plain `scripts/ui/speed_acquisition_popup.gd` presentation into the M43-C002 canonical popup family rather than leaving a parallel visual/modal architecture.

Offer exactly:

- current level = **200 SB**
- 15 minutes = **300 SB**
- 30 minutes = **500 SB**
- 60 minutes = **750 SB**

Show:

- current SB balance;
- current entitlement state;
- timed remaining time when active;
- level entitlement state when active;
- live offers/prices;
- deterministic purchase status/error.

### 2x rules

- active timed/current-level entitlement allows free manual 1x/2x switching;
- pressing 2x while already entitled must not charge again;
- current-level entitlement survives retries on that same level and clears only on successful completion;
- timed entitlement uses absolute wall clock and the accepted M55 anti-rollback high-water behavior;
- a new timed purchase may extend the expiry through the authoritative service;
- free M23 supply-exhausted automatic 2x never opens purchase UI, never spends SB, never grants/extends entitlement;
- **no rewarded-ad 2x product in this cycle.**

Insufficient SB uses the canonical Shop handoff and preserves which 2x offer was pending.

## H. Modal / input behavior

All acquisition surfaces must use the accepted ModalStack/BasePopup behavior.

While open:

- only top modal owns input;
- background Home/gameplay cannot receive taps;
- rapid CTA taps cannot double-spend/grant;
- Back/Escape closes top dismissible modal first;
- unresolved external rewarded action may enter a busy/non-dismissible state according to M43-C002 rules;
- close/reopen/focus loss cannot replay a committed action.

## I. Responsive visual requirements

Validate fresh evidence at minimum on:

- 1080×2160
- 1170×2532
- 1290×2796
- 1080×1920 short phone
- 1536×2048 portrait tablet

Life uses the selected owner Life reference as art-direction authority.

Booster Acquire and 2x Acquire require fresh candidate visual masters/evidence in the already-approved popup family. Do not generate net-new standalone illustration art when existing production assets are sufficient.

Keep normal labels, balance, counts, timers and prices as live Godot UI.

## J. Required focused tests

Add focused tests covering at least:

1. Home Heart + opens canonical Life popup.
2. zero-Heart attempt gate opens the same Life popup.
3. Life reads live Hearts/max/countdown from HeartService.
4. 5/5 Life/full state uses correct no-regen/static-ready presentation.
5. +1 Heart 500 SB atomic success.
6. +1 Heart insufficient SB: no debit/no Heart; Shop handoff context preserved.
7. full refill dynamic cost 400 × missing and atomic success.
8. full refill insufficient SB: no partial mutation.
9. rewarded Heart completed verified callback grants exactly +1.
10. rewarded Heart cancel/skip/fail/timeout grants 0.
11. duplicate rewarded Heart callback grants once.
12. background/resume unresolved Heart reward does not duplicate.
13. Home SB + emits/routes canonical Shop intent with return context.
14. one BoosterAcquire component serves all four boosters.
15. correct icon/name/charge/price data for all four.
16. owned charge path does not open purchase UI and consumes charge-first only on legal commit.
17. zero-charge SB path uses canonical price and is atomic.
18. rewarded booster success grants exactly one charge/use.
19. rewarded booster cancel/fail/duplicate callbacks: 0 / once.
20. rewarded booster never bypasses solver/legal-execution checks.
21. rewarded charge remains owned when immediate legal execution is impossible.
22. insufficient-SB booster route preserves pending booster/context.
23. 2x popup exposes exactly four canonical paid products.
24. already-entitled 1x/2x switching never recharges.
25. current-level 2x survives retry and clears on successful completion.
26. timed purchase/extension uses existing anti-rollback authority.
27. insufficient-SB 2x route preserves exact pending offer.
28. free M23 automatic 2x never opens acquisition or mutates paid entitlement.
29. rapid taps cannot double-spend or double-grant across Life/Booster/2x.
30. modal input isolation remains intact.
31. repeated open/close cycles do not accumulate nodes/signals/timers.
32. save/reload preserves committed rewarded transaction idempotency.

Run relevant existing suites:

- M28 Gameplay V02 / R01
- M29 input
- M30 retry/completion
- M39 economy
- M40 save
- M42 Home
- M43-C002 popup/modal
- M52 supply/2x
- M55 economy + timed 2x anti-rollback
- root suite
- `git diff --check`

Historical M21 corridor findings may remain only if unchanged and clearly documented.

## K. Evidence and owner review

Create fresh evidence under:

`coordination/sessions/M43-C003-C001/evidence/`

At minimum capture:

- Life popup at partial Hearts;
- Life full 5/5;
- Life insufficient-SB state;
- Life rewarded available;
- Life rewarded unavailable;
- Booster Acquire for +1 Slot;
- Booster Acquire for Random;
- Booster Acquire for Selector;
- Booster Acquire for Tornado;
- booster insufficient-SB/Shop handoff;
- booster rewarded available/unavailable;
- 2x Acquire no entitlement;
- 2x Acquire with active timed entitlement;
- 2x insufficient-SB/Shop handoff;
- short phone;
- tablet.

Create an owner review pack focused on:

- Life fidelity to selected Life reference;
- Booster Acquire hierarchy;
- rewarded WATCH / GET placement;
- 2x offer hierarchy;
- insufficient-SB -> Shop handoff clarity;
- text density/readability;
- popup family consistency.

Do not self-approve the visual gate.

## L. Required outputs

Create:

- `coordination/sessions/M43-C003-C001/ACQUISITION_MATRIX_V01.md`
- `coordination/sessions/M43-C003-C001/OWNER_ACQUISITION_REVIEW_V01.md`
- `coordination/sessions/M43-C003-C001/CLAUDE_LOG_V01.md`
- evidence under `coordination/sessions/M43-C003-C001/evidence/`

The matching ChatGPT audit criteria already exists beside this prompt and must be read before implementation.

## Scope locks

Do not:

- edit root `TASKS.md`;
- implement a real ad SDK/provider;
- hardcode ad placement IDs/frequency/cooldowns/caps;
- invent rewarded 2x;
- implement the full M43-C006 Shop catalog;
- implement M43-C004 Need a Hand / third-failure logic;
- add a fifth booster;
- change canonical prices;
- change Heart regen away from 900 seconds;
- bypass ProductionActionFacade/economy/save authority with UI-side mutations;
- weaken Random/Selector/Tornado solver safety;
- change accepted M43-C002 Pause/modal visuals;
- restyle accepted Results or Gameplay V02 static shell;
- generate unnecessary standalone art.

## Git / finish

Start from current `origin/main`.

Preserve owner/local work. Never use destructive reset/clean/force push.

Commit and push all authorized work.

Return:

1. final commit SHA;
2. focused + regression test summary;
3. direct GitHub link to `CLAUDE_LOG_V01.md`;
4. direct GitHub link to `OWNER_ACQUISITION_REVIEW_V01.md`;
5. any real blockers/owner decisions needed.

Finish exactly with:

`AWAITING_CHATGPT_AUDIT / M43-C003-C001 LIFE BOOSTER 2X ACQUISITION`
