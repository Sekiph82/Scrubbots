# M43-C005F-PHASE5 — CleaningEffectsController Saltmire Spark A/B Gate — INDEPENDENT AUDIT V01

Date: 2026-10-10
Repository: `Sekiph82/Scrubbots`
Authorized base: `600589cbab61857c3e9834bdd8826aa255995c65`
Implementation/evidence commit: `6279ed2f0621dd7568ea8000f910fc3522a15e9f`
Prompt: `coordination/sessions/M43-C005F-PHASE5/M43_C005F_PHASE5_MASTER_PROMPT_V01.md`
Criteria: `coordination/sessions/M43-C005F-PHASE5/M43_C005F_PHASE5_AUDIT_CRITERIA_V01.md`
Builder log: `coordination/sessions/M43-C005F-PHASE5/M43_C005F_PHASE5_CLAUDE_LOG_V01.md`

## VERDICT

**PASS / TECHNICALLY SAFE / DO_NOT_USE_SPARK_PER_CELL RECOMMENDED / AWAITING OWNER DECISION**

The A/B gate is technically successful.

Arm B is bounded, fail-open and gameplay-invariant, but the independent visual review agrees with the builder that the procedural Spark accent does not improve the owner-approved M31 cleaning feedback enough to justify shipping it per cleared cell.

Shipping must remain the existing native-only M31 implementation.

No production enablement task is authorized by this audit.

---

## 1. Scope

PASS.

Independent compare `600589cb..6279ed2f` shows one commit containing only:

- Phase 5 builder log;
- A/B evidence images;
- test-only B-arm helper;
- focused Phase 5 test;
- test/evidence rendering tool.

There are **zero changes** under:

- `scripts/`
- `scenes/`
- `data/`
- `assets/`
- `addons/`
- root `TASKS.md`.

Therefore production shipping code is byte-identical to the authorized base for this milestone.

A later unrelated commit `ea70c89c15757b5292316ec8b62e10410b195300` adds only `.github/workflows/ios-ipa.yml` for the owner's iOS IPA release workflow and is outside this Phase 5 audit scope.

---

## 2. G0 — persistent Desktop safety

PASS on builder evidence.

Builder records:

- Desktop synchronized to exact authorized `origin/main = 600589cb` before implementation;
- incoming changes did not overlap the four owner-dirty tracked files;
- no destructive checkout/restore/reset/clean/stash operation ran against persistent Desktop;
- TEMP worktree was created only after sync;
- TEMP git/Godot commands used explicit absolute paths;
- TEMP import rewrite of `project.godot` was restored only inside TEMP;
- final Desktop synchronized to implementation `origin/main = 6279ed2f`;
- owner dirty tracked files, untracked files and stashes remained;
- owner `project.godot` SHA-256 remained unchanged.

G0 passes.

---

## 3. M31 baseline protection

PASS.

Independent diff confirms the owner-approved M31 production implementation was not modified.

The audited baseline remains:

- authoritative source: `authenticated_clear`;
- native puff + native sparkle sprite;
- exact cell-center placement;
- `MAX_ACTIVE_EFFECTS = 24`;
- `REDUCED_MAX_ACTIVE = 8`;
- `NORMAL_LIFETIME = 0.30`;
- `REDUCED_LIFETIME = 0.18`;
- native retry/reset hygiene;
- native-only shipping.

This satisfies the mandatory “shipping stays Arm A” rule.

---

## 4. B-arm architecture

PASS.

The B arm exists only under:

`tests/support/cleaning_spark_ab_arm.gd`

It:

1. temporarily replaces only the existing M31 `authenticated_clear` observer connection;
2. calls the real `CleaningEffectsController.request_effect()` first;
3. requests Spark only if that native request is accepted;
4. targets the exact native cue container at the cleared-cell center;
5. routes the procedural accent through `FeedbackAdapter.play("SMALL", ...)`;
6. disables GameFeelFlow in the A/B adapter setup;
7. restores exact native Arm-A wiring on detach.

No direct production/evaluation call to:

- `Spark.burst()`
- `Spark.at()`
- `Spark.clear()`

is introduced.

No new production FeedbackAdapter API was required.

---

## 5. Authority / idempotency

PASS.

Focused evidence proves:

- one authenticated clear -> at most one native cue;
- one accepted native cue -> at most one Spark accent;
- invalid index -> zero native / zero Spark;
- native cap suppression -> zero Spark;
- non-authenticated/rejected work cannot create Spark;
- Spark requests never exceed accepted native cues.

The B arm does not observe or invent alternative gameplay events.

---

## 6. Reduced Effects

PASS.

Reduced preserves the existing native reduced puff.

The B arm explicitly skips procedural Spark when M31 is Reduced.

Evidence shows:

- native Reduced cap <= 8;
- Spark requests = 0;
- Spark bursts = 0;
- adapter-owned Spark work = 0.

Matched Reduced captures are visually equivalent between A and B.

---

## 7. Retry / failure safety

PASS.

Retry/reset evidence proves:

- live native cues can exist;
- live adapter-owned Spark work can exist;
- successful retry clears native cues and B-arm adapter work;
- next attempt works normally;
- no stale emitter or adapter ownership remains.

Failure cases also pass:

- Spark missing -> native M31/gameplay unchanged;
- Spark backend throws -> native M31/gameplay unchanged;
- B arm detached -> exact native behavior restored.

This satisfies fail-open presentation requirements.

---

## 8. Gameplay truth invariance

PASS.

For real Level 1 to terminal:

- A and B produce the same 400 authenticated clears;
- clear sequence including tick timing is identical;
- terminal tick count is identical;
- BoardState is identical;
- slot state is identical;
- supply state is identical;
- terminal result is identical;
- progression/economy truth is identical.

Play -> Retry -> play evidence also matches between A and B.

This is strong evidence that the procedural accent remains presentation-only.

---

## 9. 59x59 / 2x boundedness

PASS.

The 59x59 real-host evidence remains bounded.

Representative final-run numbers:

### 59x59 1x
- authenticated clears: 24
- native peak: 9
- B Spark requests: 24
- peak adapter-owned: 11
- peak emitters: 10
- drain: ~488 ms

### 59x59 2x
- authenticated clears: 81
- native peak: 18
- B Spark requests: 81
- peak adapter-owned: 26
- peak emitters: 22
- drain: ~476 ms

Native cap remains <=24.

Spark requests never exceed accepted native cues.

Adapter/emitter work drains to zero.

Post-run Node count returns to baseline and orphan count does not grow.

Measured loop-cost differences between A and B are within test noise and do not indicate a material performance regression.

Technically, B is eligible.

---

## 10. Regression

PASS.

Final recorded battery:

**20 / 20 suites PASS**

including:

- Phase 5 focused: 13/13
- M31 cleaning effects
- M31 59x59
- M29 presentation/speed/runtime/routing/input
- M30 completion/retry/manual
- Phase 1 FeedbackAdapter
- Phase 4 terminal/Home feel
- Phase 4 lifecycle
- M55 long session
- M55 core chaos
- root `tests/run_tests.gd`: ALL PASS
- headless import
- headless boot
- `git diff --check`

Disclosed first-run failures are test/harness defects and were corrected without production changes.

No remaining failing regression exists.

---

## 11. Independent visual A/B review

The audit inspected the committed matched A/B evidence directly.

### Full-frame normal gameplay

At ordinary gameplay scale, Arm A and Arm B are effectively indistinguishable most of the time.

The procedural accent does not add a clearly readable cleaning signal beyond the existing native M31 puff/sparkle.

### Zoomed 1x / 2x cue evidence

The visible B-only difference appears as a small cluster of white circular particles over/around the arriving Scrubbot and native blue cleaning cue.

At 2x evidence scale this is more obvious, but it reads primarily as:

- white discs;
- a pale smudge;
- partial visual cover over the character/native cue.

It does not read as a meaningfully richer cleaning sparkle.

### Dense / small-cell use

The evidence and measured geometry indicate the extra particles become tiny white specks at dense 59x59 scale, adding little readable information.

### Reduced

No Spark is present, as required.

---

## 12. Decision

Technical outcome:

**PASS**

Adoption recommendation:

**DO_NOT_USE_SPARK_PER_CELL**

Reason:

- Arm B is safe;
- Arm B is cheap enough;
- but Arm B adds insufficient visual value;
- where visible, it weakens clarity by laying generic white particle discs over the accepted native cleaning cue and Scrubbot;
- dense boards gain essentially no useful visual signal;
- the current M31 native effect is already owner-approved and technically simpler.

This is exactly the valid “do not force plugin usage” success case defined in the Phase 5 prompt.

Shipping should remain Arm A.

---

## 13. Owner gate

The implementation/evaluation is technically complete.

Final row status pending the owner's explicit decision:

`SB-M43-C005F-011 = TECHNICAL PASS / DO_NOT_USE_SPARK_PER_CELL RECOMMENDED / AWAITING OWNER DECISION`

If the owner accepts the recommendation, close F011 as:

`PASS / CLOSED / DO NOT USE SPARK PER-CELL`

No production code change is required for that closure.
