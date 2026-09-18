# M29-C001 V02 — ChatGPT Final Strict Audit

Date: 2026-09-19
Repository: `Sekiph82/Scrubbots`
Milestone: `M29 — Mobile Touch / Production Input Integration`
Cycle: `M29-C001 V02`
Auditor: ChatGPT
Implementation SHA: `a20ae1cec72b8c090af071962239638759498540`
Claude log SHA: `2bd9cc16049fbf631b5a0a66b0d479f2b7a7f0ed`
Prior audit: `coordination/sessions/M29-C001/CHATGPT_AUDIT_V01.md`
Criteria: `coordination/sessions/M29-C001/CHATGPT_AUDIT_CRITERIA_V02.md`

## Verdict

**AUDITED_PASS / M29 MOBILE TOUCH & PRODUCTION INPUT CLOSED**

All `SB-M29-001..009` are eligible for closure.

V02 closes the only blocking V01 defect: the production routing origin is now derived from the actual visible M28 slot top-center instead of a synthetic board-width lane.

## F-M29-V01-STRICT-001 closure

Verified production path:

`FiveSlotStrip.get_slot_anchor_global(slot)`
-> `BoardPresentation.global_to_board_local(global_anchor)`
-> `SlotOriginProvider.origin_for_slot(slot)`
-> M26 route request / Railroad connector.

The old production calculation:

`x = (slot + 0.5) * board_width / 5`
`y = board_height + 4`

has been removed from `SlotOriginProvider`.

The provider queries current presentation geometry on every call. It does not cache screen-pixel coordinates and has no synthetic fallback.

Invalid slot or missing/dead presentation/strip returns a non-finite fail-closed origin, preserving no-route/no-robot behavior.

## Responsive evidence

Dedicated V02 evidence proves all five production slot origins equal the visible top-center mapping at:
- 1080×2160;
- 1440×3200 after relayout.

The origins change after responsive relayout, proving the provider is not using stale cached screen geometry.

`ProductionGameplayHost` now fits `GameplayScreen` to the host rect and refits it on resize so the real visible slot geometry resolves correctly inside the production host.

## Railroad / route integration

The focused exact-origin evidence proves:
- route point 0 equals the exact visible slot origin;
- the route is RouteValidator-clean;
- Railroad V1/V07 remains valid;
- no diagonal/corner-cut/teleport behavior is introduced.

## Real Hazard Bot production runtime

The real M29 production runtime smoke was rerun with the exact visible origins.

Claude reports:
- 400 authenticated clears;
- final ACTIVE = 0;
- M23 supply exhausted;
- no ghost robot;
- no duplicate live target;
- auto-2x after final successful supply transfer;
- 1x and 2x preserve gameplay truth;
- deterministic solved click order remains valid.

Owner-facing complete-clear column sequence:

`1,1,1,1,1,1,1,2,2,2,2,2,2,3,3,3,3,3,3`

## Accepted M29 V01 behavior preserved

The narrow V02 diff does not rewrite:
- front-row-only supply input;
- preview-row non-interactivity;
- read-only automatic destination slots;
- real M23 -> M24 transactional placement;
- mouse support;
- touch support;
- synthesized mouse/touch dedup;
- touch cancel;
- rapid tap / multi-touch serialization;
- focus/background cancellation;
- user/system pause separation;
- automatic M26 cadence;
- explicit 1x/2x gameplay-speed authority;
- current/future Scrubbot travel scaling;
- authoritative M23-exhausted auto-2x;
- reset/new level -> 1x.

No global `Engine.time_scale` was introduced.

## Governance

V02 implementation is one narrow implementation commit.

Implementation -> log is a separate single log commit.

Root `TASKS.md` was not modified by Claude.
M30 was not implemented.
AI image-generation credits: 0.

Claude reports the full regression floor green, including:
- root suite;
- M29 input evidence;
- M29 speed evidence;
- M29 exact-origin evidence;
- M29 Hazard Bot runtime smoke;
- M28 viewport;
- M27 Hazard/59/generation;
- M26 Hazard/scale;
- M25 V03;
- M24 V02;
- M23 V03;
- M22 Railroad/connector/real-demo;
- M20 lifecycle;
- `git diff --check`.

## Closure

Close all `SB-M29-001..009`.

M29 is now the first owner-runnable production gameplay path:
- graphical Godot;
- desktop mouse or touch;
- supply-front activation;
- automatic slot placement;
- automatic robot dispatch;
- real routing/clearing;
- pause;
- manual 1x/2x;
- automatic M23-exhausted 2x.

Advance to **M30 — Win/Lose Rules [DESIGN GATE]**.

Do not implement M30 until the owner explicitly locks the win condition, lose condition and retry semantics.
