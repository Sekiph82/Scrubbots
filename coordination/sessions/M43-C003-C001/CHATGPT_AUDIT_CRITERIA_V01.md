# M43-C003-C001 — CHATGPT INDEPENDENT AUDIT CRITERIA V01

Date: 2026-09-28
Auditor: ChatGPT
Implementation actor: Claude
Scope: M43-C003 / SB-M43-030..049

## Audit rule

Claude does not self-award PASS.

ChatGPT will audit the pushed GitHub state, implementation diff, tests, evidence and log against these criteria.

A technically correct implementation may still finish as:

- `AUDITED_PASS / OWNER VISUAL REVIEW REQUIRED`

because SB-M43-049 requires owner approval of Booster Acquire / 2x / insufficient-SB visual masters.

## A. Scope / governance

PASS requires:

- root `TASKS.md` not edited by Claude;
- no unauthorized M43-C004+ implementation;
- no real ad SDK/provider added;
- no ad placement IDs/frequency/cooldowns/caps hardcoded;
- no rewarded 2x product invented;
- no fifth booster;
- no canonical price changes;
- Heart regen remains 900 seconds;
- current accepted M43-C002 modal architecture reused rather than duplicated.

Any violation is blocking.

## B. Heart / Life correctness

Verify:

- one canonical Life popup surface exists;
- Home Heart + routes to it;
- zero-Heart attempt gate routes to the same surface;
- values are live from HeartService/economy authority;
- max = 5;
- 15-minute / 900-second Heart authority is preserved;
- partial-heart countdown is authoritative wall-clock countdown;
- full-state presentation does not create a second authoritative timer;
- +1 Heart = 500 SB;
- full refill = 400 × current missing Hearts;
- purchases are atomic;
- already-full and insufficient-SB paths consume nothing;
- no UI-side direct Heart mutation.

Blocking if any purchase can partially mutate, overfill, or use stale display cost.

## C. Rewarded Heart integrity

Verify a provider-neutral seam exists and production can remain unavailable until M57.

A verified-completion path must:

- commit +1 Heart through authoritative service/reward boundary;
- use stable idempotency/reward token;
- request durable save on commit;
- show success only after commit.

Must prove:

- cancel = 0 grant;
- skip = 0;
- fail = 0;
- timeout = 0;
- unverified callback = 0;
- duplicate callback = one total grant;
- background/resume cannot duplicate;
- full-at-commit fails closed;
- persisted/reloaded state cannot re-grant the same completed reward token.

Any double-grant or production fake-success is blocking.

## D. Shop handoff / pending context

Verify:

- Home SB + has an explicit canonical Shop/SB navigation intent;
- full M43-C006 Shop catalog was not prematurely invented;
- insufficient-SB from Life, Booster and 2x can route to Shop;
- pending acquisition context is detached/stable, not tied to a popup node that disappears;
- context identifies the exact product/action needed to resume/cancel safely;
- returning/cancelling has no duplicate spend/grant.

Blocking if Shop handoff loses product identity or mutates currency on its own.

## E. Booster Acquire architecture

Verify:

- one reusable data-driven production component serves all four boosters;
- no four duplicated scenes;
- existing canonical icons reused;
- names/effects/charges/prices are live data;
- prices exactly 500/350/500/750 SB;
- rewarded CTA only when allowed/available;
- no rewarded CTA added to unrelated generic M43-C002 popups.

## F. Charge-first + solver safety

For each booster:

### +1 Slot
- owned charge is used before SB;
- no popup when a legal owned charge exists;
- no capacity >6;
- no second activation in one attempt.

### Random
- existing >=3 safe-front-selection solver gate remains;
- unsafe => no charge/SB consumption.

### Selector
- only safe eligible choices;
- no empty slot / no eligible choice => consumes nothing.

### Tornado
- present color only;
- existing multi-system atomic reconciliation/rollback preserved;
- failure consumes nothing.

Across all:
- zero charge may use canonical SB acquisition;
- reward completion grants one charge/use exactly once;
- rewarded grant never bypasses legal execution;
- if immediate execution is illegal, the newly granted charge remains owned and unconsumed.

Any solver-safety bypass is blocking.

## G. Rewarded booster integrity

Must prove for each generic path, with at least representative coverage plus data-driven validation for all four:

- verified complete => exactly one grant;
- cancel/skip/fail/timeout => zero;
- duplicate complete => once;
- background/resume => once;
- persisted reward transaction prevents relaunch double-grant;
- no provider-specific logic is embedded in popup UI.

## H. 2x acquisition

Verify canonical offers exactly:

- current level 200 SB;
- 15m 300 SB;
- 30m 500 SB;
- 60m 750 SB.

Verify:

- existing plain speed popup is converged into the canonical M43-C002 modal/popup family or otherwise no parallel modal authority remains;
- active current-level/timed entitlement allows free 1x/2x switching;
- already-entitled switch cannot debit again;
- current-level entitlement survives retries and ends on successful completion;
- timed extension uses SpeedEntitlementService;
- M55 anti-rollback remains intact;
- free M23 supply-exhausted auto-2x never opens purchase UI or mutates paid entitlement;
- no rewarded-ad 2x CTA.

Any double charge or anti-rollback regression is blocking.

## I. Transaction / rapid-tap / lifecycle safety

Across Heart/Booster/2x:

- one pending transaction/action at a time per acquisition surface;
- rapid taps cannot double spend/grant;
- failure restores usable state;
- Back/Escape follows M43-C002 top-modal rules;
- background/focus loss does not replay callbacks;
- close/reopen does not replay committed action;
- no signal/timer/node accumulation over repeated cycles;
- committed state is saved through the accepted boundary.

## J. Input isolation

While acquisition popup/modal is open:

- Home/gameplay background receives no input;
- board/supply/boosters/2x behind top modal receive no tap;
- top modal alone owns action;
- closing top modal has no click-through.

Regression against M43-C002 is blocking.

## K. Visual / responsive technical gate

Technical audit verifies, not owner-approves:

- Life visual uses selected Life reference as authority;
- Booster/2x/insufficient-SB use the accepted popup family;
- no unnecessary new standalone art;
- dynamic counts/prices/timers remain live Godot UI;
- no clipping/overlap at 1080×2160, 1170×2532, 1290×2796, 1080×1920, 1536×2048;
- touch targets remain compliant;
- short-phone and tablet evidence exist.

If technical layout is broken, audit fails before owner review.

If technically sound, visual rows requiring taste/approval remain OWNER gate.

## L. Required evidence / documentation

Must exist:

- `ACQUISITION_MATRIX_V01.md`
- `OWNER_ACQUISITION_REVIEW_V01.md`
- `CLAUDE_LOG_V01.md`
- fresh evidence directory with the prompt-required Life/Booster/2x/Shop-handoff states.

Log must include:

- starting and final commit SHA;
- files changed;
- exact architecture/seams added;
- test commands/results;
- any deviations/blockers;
- confirmation that root TASKS.md was not edited.

## M. Regression gate

Audit expects evidence for relevant:

- M28 Gameplay V02 / R01;
- M29 input;
- M30 retry/completion;
- M39 economy;
- M40 save;
- M42 Home;
- M43-C002;
- M52 supply/2x;
- M55 economy + timed anti-rollback;
- root suite;
- `git diff --check`.

Historical M21 corridor findings may be accepted only if identical to documented baseline and unrelated.

## N. Audit outcome mapping

### AUDITED_PASS / OWNER VISUAL REVIEW REQUIRED
Use when:

- SB-M43-030..048 are technically satisfied;
- SB-M43-049 candidate visual evidence is complete and technically valid;
- owner has not yet approved visual masters.

### AUDITED_PASS / M43-C003 CLOSED
Only after:

- technical audit passes;
- owner approves the required Life/Booster/2x/insufficient-SB visual family;
- ChatGPT updates root TASKS.md.

### FAIL / REMEDIATION REQUIRED
Use for any blocking defect, especially:

- double spend/grant;
- UI-owned economy truth;
- solver-safety bypass;
- rewarded callback granting on non-completion;
- ad SDK/provider creep;
- 2x re-charge while entitled;
- timed anti-rollback regression;
- duplicate modal authority;
- Heart interval regression to 30m;
- tracker edited by implementation actor.
