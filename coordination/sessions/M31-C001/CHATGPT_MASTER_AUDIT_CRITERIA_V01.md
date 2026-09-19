# M31-C001 V01 — ChatGPT Master Audit Criteria

Milestone: `M31 — Cleaning Effects`

Authority:
- root `TASKS.md`
- `coordination/sessions/M31-C001/CHATGPT_MASTER_PROMPT_V01.md`
- `coordination/OWNER_GAMEPLAY_SCREEN_COMPOSITION_V02.md`
- `docs/MASTER_UI_SYSTEM.md`
- accepted M20-M30 gameplay contracts

## 1. Event authority

PASS only if cleaning visuals are driven by the authoritative committed-clear path, preferably `CompleteClearingLoop.authenticated_clear`.

Reject if visuals are triggered by:
- guessed robot arrival;
- rendering transparency polling;
- slot/quota inference;
- per-frame BoardState scanning.

One committed clear must request at most one normal cleaning cue. Failed/rolled-back/reset transactions must not generate one.

## 2. Gameplay separation

M31 code is presentation-only.

The effect system must not mutate:
BoardState, ColorCandidateIndex, reservations, M25 claims, M24 slots, M23 supply, routing, target selection, scheduler truth, M27 solver truth, or M30 terminal truth.

Visual failure/saturation must never block gameplay progress.

## 3. Existing assets / generation discipline

Existing merged assets are inspected first:
- `fx_clean_puff.png`
- `fx_clean_sparkle.png`

No AI image generation is permitted in this cycle unless the owner explicitly changes scope later.

Any derived optimization must preserve originals and be documented.

## 4. Geometry and identity stability

Effect position must map to the exact cleared logical cell.

BoardPresentation responsive reconfigure must not recreate/strand:
- BoardRenderer;
- AgentLayer;
- CleaningFxLayer/controller authority.

Rectangular and 59×59 boards must remain aligned.

No permanent per-cell effect nodes.

## 5. Toggle

A runtime enable/disable seam exists and is tested.

Disabled effects produce zero new visual instances while gameplay clears continue unchanged.

M31 does not implement Settings persistence.

## 6. Concurrency

An explicit finite concurrent-effect cap exists.

At saturation:
- gameplay continues;
- no unbounded visual queue;
- no active-count overflow;
- suppression behavior is deterministic and observable for tests.

## 7. Pooling is evidence-driven

PASS with either:
- no pool, plus profiling evidence showing it is unnecessary; or
- a bounded visual-only pool, plus profiling evidence showing why it was needed.

Automatic speculative pooling is not a quality win.

## 8. Reduced-effects path

If implemented, reduced mode must only change presentation cost/density.

If not needed, the log must contain measured evidence supporting that decision and explain how SB-M31-010 is satisfied.

Prefer a tested runtime seam so later M41 settings can bind it without rewriting gameplay.

## 9. Retry / stale presentation

Successful M30 Retry clears stale M31 visual state.

No old-attempt effect or delayed callback may reappear into the fresh attempt.

M30 Retry/gameplay contracts must remain unchanged.

## 10. Performance

Require real evidence at 59×59 / high clear density.

Audit:
- peak concurrent FX;
- cap enforcement;
- suppression count;
- measured benchmark/frame-update evidence available from the test environment;
- allocation/pooling decision;
- behavior at 2x/high event rate.

No invented measurements.

## 11. Owner F6 gate

Code may receive `CODE_AUDIT_PASS / OWNER_F6_REQUIRED`.

Final M31 closure requires owner confirmation from the dedicated M31 playtest scene that:
- effect is correctly located;
- effect visually reads as cleaning;
- normal density is not noisy;
- high density remains acceptable;
- toggle/reduced behavior is acceptable;
- Retry leaves no stale FX.

Do not close M31 before owner visual acceptance.

## 12. Regression floor

Must include:
- focused M31 tests;
- root suite;
- M30 completion/retry smoke;
- M29 realtime/presentation identity regressions;
- M26/M20 clear-path regression;
- existing max-scale performance sanity;
- `git diff --check`.

No drive-by fixes outside M31.

## 13. Commit isolation

Implementation first, then separate `CLAUDE_LOG_V01.md`.

Claude must not edit root `TASKS.md`.

## Verdict targets

Successful code audit before manual gate:

`CODE_AUDIT_PASS / M31-C001 V01 / OWNER_F6_REQUIRED`

After owner visual acceptance:

`AUDITED_PASS / M31 CLEANING EFFECTS CLOSED`
