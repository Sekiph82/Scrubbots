# M28-C002-C003 — CHATGPT INDEPENDENT AUDIT CRITERIA V01

Date: 2026-09-28
Auditor: ChatGPT
Implementation actor: Claude
Scope: M28-C002 final convergence / SB-M28-C002-012, 013, 019, 020 prerequisites

## Audit outcome rule

Claude cannot self-close M28-C002.

ChatGPT audits the real pushed state. Final owner visual/playtest acceptance is still required for SB-M28-C002-020.

Expected technical outcome if clean:

`AUDITED_PASS / OWNER FINAL GAMEPLAY V02 PLAYTEST REQUIRED`

## A. Governance / scope

PASS requires:

- root `TASKS.md` untouched by Claude;
- validation-first behavior;
- no unnecessary Gameplay V02 redesign;
- no change to owner-approved M43 popup decisions;
- no economy/booster/2x tuning drift;
- no solver/routing drift;
- no unrelated meta implementation.

Any unauthorized redesign or gameplay-rule change is blocking.

## B. SB-M28-C002-012 — Booster routing

PASS requires direct proof that the **visible Gameplay V02 booster control** with zero charge:

- opens the correct canonical M43-C003 Booster Acquire popup;
- does not silently fail;
- does not spend SB on open;
- keeps shared ModalStack input isolation;
- preserves charge-first rules;
- keeps Selector/Tornado target picker owner decision;
- uses solver-safe authoritative execution;
- cancel/close mutates nothing.

At least +1 Slot and Selector/Tornado must be demonstrated.

## C. SB-M28-C002-013 — 2x routing

PASS requires direct proof that the **visible Gameplay V02 2x control** while unentitled:

- opens canonical `speed_acquire`;
- does not grant free manual 2x;
- does not debit on open;
- shows exactly 200/300/500/750 SB offers;
- commits purchase through existing authority;
- permits free switching after entitlement;
- displays authoritative timed countdown;
- does not interfere with free M23 auto-2x.

## D. Popup/input integration

PASS requires:

- only top modal owns input;
- board/supply/booster/2x behind it cannot act;
- Pause still functions through the same ModalStack;
- no click-through after close;
- sixth-slot state remains intact under popup;
- repeated cycles do not accumulate nodes/signals/timers.

Any background action while a modal is open is blocking.

## E. Visual evidence completeness

Fresh evidence must visibly cover:

- fresh level;
- active cleaning;
- five occupied slots;
- sixth slot;
- Booster Acquire;
- Selector/Tornado picker;
- Pause;
- 2x Acquire;
- timed 2x;
- short phone;
- tall phone;
- tablet;
- popup-inclusive responsive composition.

Screenshots must be from real runtime state, not external composites.

## F. Motion evidence

Audit accepts either:

1. genuine short gameplay video/capture, or
2. honest frame-sequence/contact-sheet evidence plus an explicit remaining OWNER interactive motion playtest gate.

It is a FAIL only if Claude falsely claims video evidence or omits motion/playtest handling entirely.

## G. Responsive / touch

Required matrix:

- 1080×2160
- 1170×2532
- 1290×2796
- 1080×2400
- 1440×3200
- 1080×1920
- 1536×2048

At minimum base gameplay, Booster Acquire, Pause, 2x Acquire and sixth-slot composition must stay safe and readable.

No critical clipping/overlap or undersized primary touch target.

## H. Regression gate

Audit expects submitted evidence for:

- M28 C002 C001
- M28 C002 C002 static shell
- M28 C002 C002 R01
- M28 layout smoke
- M29
- M30
- M39
- M40
- M43-C002
- M43-C003
- M52
- M55
- root suite
- `git diff --check`

Historical M21 findings are acceptable only if identical to established baseline.

## I. Documentation

Must exist:

- `GAMEPLAY_V02_FINAL_MATRIX_V01.md`
- `OWNER_GAMEPLAY_V02_FINAL_REVIEW_V01.md`
- `CLAUDE_LOG_V01.md`
- fresh evidence directory.

Review checklist must not self-approve owner items.

## J. Closure mapping

### Technical PASS
If all technical criteria pass:

- ChatGPT may close SB-M28-C002-012;
- ChatGPT may close SB-M28-C002-013;
- ChatGPT may close SB-M28-C002-019 once evidence is complete;
- SB-M28-C002-020 stays open as OWNER_REQUIRED until owner visual/playtest acceptance.

### Final M28-C002 close
Only after:
- independent ChatGPT technical audit PASS;
- owner accepts final Gameplay V02 visual/playtest gate;
- ChatGPT updates root `TASKS.md`.

### Remediation required
Blocking examples:

- booster tap still silently fails;
- purchase occurs merely by opening popup;
- 2x can become free when unentitled;
- modal leaks gameplay input;
- popup corrupts sixth-slot state;
- timed 2x authority regresses;
- accepted static shell changes unexpectedly;
- missing final evidence;
- false video claim.
