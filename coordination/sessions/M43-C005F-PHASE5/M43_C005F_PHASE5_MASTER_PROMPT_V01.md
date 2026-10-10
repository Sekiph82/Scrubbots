# M43-C005F-PHASE5 — CleaningEffectsController Saltmire Spark A/B Gate — MASTER CLAUDE PROMPT V01

Repository: `Sekiph82/Scrubbots`
Persistent owner checkout: `C:\Users\sekip\Desktop\ScrubBots`
Engine: Godot 4.7.2
Date: 2026-10-10

## Authorized scope

Execute exactly:

`SB-M43-C005F-011 — Existing CleaningEffectsController Spark comparison/augmentation gate`

This is an **A/B EVALUATION GATE**, not an instruction to force Spark into shipping gameplay.

Current owner-approved M31 CleaningEffectsController remains the production baseline.

Possible final outcomes:

1. `TECHNICAL_PASS / SPARK_CANDIDATE_FOR_OWNER_DECISION`
2. `TECHNICAL_PASS / DO_NOT_USE_SPARK_PER_CELL`
3. `CHANGES_REQUIRED`

Do not enable a permanent per-cell Spark augmentation in shipping gameplay in this task.

Root `TASKS.md` is READ-ONLY for Claude. ChatGPT is its sole writer.

---

# GATE 0 — PERSISTENT DESKTOP SYNC

Before implementation:

1. Record persistent Desktop:
   - HEAD
   - origin/main
   - ahead/behind
   - tracked dirty files
   - untracked count
   - stashes/worktrees
   - SHA-256 of owner `project.godot`
2. Run:
   `git -C "C:\Users\sekip\Desktop\ScrubBots" fetch --prune origin`
3. Non-destructively reconcile Desktop to exact latest origin/main.
4. Preserve every owner-local file.
5. Implementation may begin only at Desktop HEAD == origin/main and 0/0.
6. Never run against persistent Desktop:
   - `git checkout -- <file>`
   - `git restore <file>`
   - `git reset --hard`
   - `git clean`
   - destructive stash/pop
   - force checkout/rebase/push
7. TEMP worktree only after Gate 0.
8. Every TEMP command uses explicit absolute path:
   - `git -C "<TEMP>" ...`
   - `godot --path "<TEMP>" ...`
9. TEMP creation failure = STOP. Never fall back to editing Desktop.
10. After final push, sync Desktop to final origin/main and prove owner `project.godot` hash unchanged.

---

# READ FIRST

- root `TASKS.md`
- `scripts/gameplay/presentation/cleaning_effects_controller.gd`
- `scripts/ui/feel/feedback_adapter.gd`
- `tests/m31_cleaning_effects_evidence.gd`
- `tests/m31_scale_59_effects.gd`
- `coordination/sessions/M31-C001/CHATGPT_AUDIT_V01.md`
- `coordination/sessions/M31-C001/OWNER_F6_ACCEPTANCE_V01.md`
- `coordination/sessions/M43-C005F-PHASE4-QA-R01/CHATGPT_INDEPENDENT_REAUDIT_V01.md`

Inspect current production APIs before writing anything.

---

# OWNER-ACCEPTED BASELINE IS FROZEN

M31 is already:

`AUDITED_PASS / OWNER_F6_PASS / CLOSED`

Current production cleaning FX:

- authoritative source:
  `CompleteClearingLoop.authenticated_clear`
- presentation observer:
  `CleaningEffectsController`
- exact-cell placement:
  `(x + 0.5, y + 0.5)`
- current native cue:
  - puff
  - sparkle sprite
- normal cap:
  `MAX_ACTIVE_EFFECTS = 24`
- Reduced cap:
  `REDUCED_MAX_ACTIVE = 8`
- normal lifetime:
  `0.30 s`
- Reduced lifetime:
  `0.18 s`
- retry/reset hygiene already accepted
- 59x59 / 2x stress already accepted
- owner already accepted the existing visual result.

This task must not weaken or replace that system.

---

# NON-NEGOTIABLE PRODUCT RULE

**Shipping production remains native-only throughout this task.**

Do NOT wire Saltmire Spark permanently into:

- `CleaningEffectsController._on_authenticated_clear()`
- `request_effect()`
- `_spawn()`
- ProductionGameplayHost
- BoardPresentation

unless a later owner-approved follow-up task explicitly authorizes enablement.

This task creates a technically honest A/B comparison using the real gameplay stack.

No hidden feature flag defaulting ON.
No silent production activation.
No owner-approved M31 visual replacement.

---

# PLUGIN ARCHITECTURE RULE

Saltmire Spark may be evaluated only through the canonical:

`scripts/ui/feel/feedback_adapter.gd`

No production or evaluation code may call:

- `Spark.burst()`
- `Spark.at()`
- `Spark.clear()`

directly.

GameFeelFlow must NOT be used per cleared cell.

For B-arm evaluation, isolate Spark through FeedbackAdapter by using a test/evidence adapter setup where:

- Spark backend is active;
- GameFeelFlow backend is absent/disabled for this A/B harness;
- the target is an existing/evidence-only CanvasItem/Node2D anchor at the cleared-cell position;
- the adapter remains fail-open and bounded.

Do not expand the production adapter API unless objectively necessary.

If you believe a permanent adapter API change is required merely to run the comparison, STOP and document why before changing it. Prefer a test/evidence harness using the current adapter contract.

---

# A/B DEFINITION

## ARM A — canonical native baseline

Exactly current production M31:

- native puff;
- native sparkle sprite;
- existing lifetime/cap;
- no Saltmire Spark.

No changes.

## ARM B — native baseline + restrained Saltmire Spark accent

B must retain ALL of Arm A.

Add only a small procedural Spark accent at the same authenticated cleared-cell position.

Rules:

- event source remains authenticated clear;
- one accepted native cue may request at most one bounded Spark accent;
- a native request suppressed by M31 cap must NOT create a Spark accent;
- invalid/out-of-range request = no Spark;
- rejected/non-committed clear = no Spark;
- retry/reset = no stale Spark;
- Reduced = **zero Saltmire Spark**;
- no GFF per cell;
- no camera/flash/freeze/time-scale;
- no gameplay mutation.

Suggested B budget:

- Spark preset: `spark`
- amount: 2 or at most 4 particles per accepted cue
- lifetime must remain inside the adapter SMALL ceiling;
- one cell must never create a MAJOR/REWARD/WIN tier effect.

Start with the smallest visibly useful amount.

Do not tune upward merely to make screenshots dramatic.

---

# EVIDENCE HARNESS

Build or extend a debug/test-only A/B harness.

Preferred location:

`tests/tools/m43_c005f_phase5_cleaning_spark_ab.gd`

and, if visual scene is useful:

`scenes/debug/m43_c005f_phase5_cleaning_spark_ab.tscn`

The harness must run the REAL:

- ProductionGameplayHost
- BoardState
- CompleteClearingLoop
- CleaningEffectsController
- CleaningFxLayer
- FeedbackAdapter
- installed Saltmire Spark plugin

No fake board-only screenshot is sufficient.

The harness may add evidence-only anchors/nodes, but they must never become shipping gameplay dependencies.

---

# VISUAL A/B EVIDENCE

Produce matched captures for the same gameplay state/event sequence:

## Normal board

- A native-only at 1x
- B native + Spark at 1x
- A native-only at 2x
- B native + Spark at 2x

## Dense / stress representative

Use a real or deterministic 59x59 representative board/load:

- A at high clear density / 2x
- B at same exact clear sequence / 2x

## Reduced

- A Reduced
- B Reduced

B Reduced must be visually identical to A Reduced with respect to Saltmire Spark:
**zero procedural Spark**.

Use at least:

- 1080×2160
- 1536×2048

Prefer short matched video clips in addition to stills if the difference is hard to judge in a single frame.

Evidence must make A vs B easy to compare.

---

# PERFORMANCE / BUDGET EVIDENCE

Do not judge only by screenshots.

For A and B under the same deterministic clear sequence, record:

- committed/authenticated clear count;
- native CleaningEffectsController accepted count;
- native suppressed count;
- native peak active count;
- Spark feedback request count;
- Spark adapter accepted count;
- peak FeedbackAdapter owned count;
- peak Spark emitter count if measurable;
- peak extra Node count for B vs A;
- total/average test-loop cost;
- 59x59 1x and 2x stress cost;
- drain-to-zero time;
- post-drain orphan Node count;
- final gameplay BoardState/terminal truth.

### Hard safety rules

B fails technical eligibility if any of these occur:

- active native cues exceed 24;
- Reduced native cues exceed 8;
- Spark request count exceeds accepted native cue count;
- Spark survives retry/reset after its allowed ceiling;
- adapter-owned work fails to drain to zero;
- orphan Nodes grow;
- gameplay clear count/order/timing/terminal truth changes;
- average presentation-only cost becomes materially unsafe against the existing M31 mobile budget;
- 59x59/2x shows unbounded emitter/node growth.

Do not invent a new generous threshold to make B pass.

Compare against A and the existing M31 evidence.

---

# AUTOMATED TEST REQUIREMENTS

Create focused permanent evidence, e.g.:

`tests/m43_c005f_phase5_cleaning_spark_ab.gd`

At minimum prove:

## Authority / idempotency

1. one authenticated clear -> at most one accepted native cue;
2. B adds at most one Spark accent for that accepted cue;
3. invalid index -> zero native + zero Spark;
4. M31-cap-suppressed native cue -> zero Spark;
5. no non-authenticated/rejected event can create Spark.

## Reduced

6. Reduced -> native reduced puff remains;
7. Reduced -> zero Saltmire Spark calls/particles.

## Retry/reset

8. active native + Spark accents exist;
9. Retry/reset clears both bounded presentation systems;
10. later new attempt works normally;
11. no stale emitter/adapter ownership.

## Failure safety

12. Spark missing -> gameplay + native M31 unchanged;
13. Spark backend throws -> gameplay + native M31 unchanged;
14. adapter disabled -> gameplay + native M31 unchanged.

## Truth invariance

For identical deterministic gameplay:

15. A and B have identical:
   - authenticated clear sequence;
   - board state;
   - slots/supply;
   - terminal result;
   - progression/economy;
   - retry truth.

## Cap / load

16. 59x59 A remains within M31 cap;
17. 59x59 B remains bounded;
18. B Spark request count never exceeds accepted native cues;
19. B drains to zero;
20. no orphan growth.

## Static boundary

21. no direct Saltmire Spark production/evaluation calls outside FeedbackAdapter;
22. no GFF per-cell use;
23. no permanent shipping B-arm wiring.

---

# REGRESSION

Run and record:

- new Phase5 A/B focused suite
- `tests/m31_cleaning_effects_evidence.gd`
- `tests/m31_scale_59_effects.gd`
- relevant M29 59x59/routing/presentation
- M30 completion/retry
- Phase1 feedback adapter
- Phase4 focused
- M55 long-session
- M55 core chaos
- root `tests/run_tests.gd`
- headless import/boot
- `git diff --check`

Any first-run failure must be disclosed.

---

# TECHNICAL DECISION PACKET

Builder must not make the owner aesthetic decision.

At handoff provide one of these technical recommendations:

## A. SPARK_CANDIDATE_FOR_OWNER_DECISION

Use only if:

- B is technically bounded/fail-open;
- no gameplay truth changes;
- no meaningful performance regression;
- visual evidence shows a clearly distinguishable but restrained extra accent.

Shipping still stays A until owner explicitly accepts B.

## B. DO_NOT_USE_SPARK_PER_CELL

Use if any of these are true:

- B is barely distinguishable from A;
- B looks noisier/cluttered;
- dense/2x gameplay becomes visually muddy;
- extra particle/node cost is not justified;
- B has weaker cleanup/lifecycle behavior;
- Reduced/Retry/cap complexity is not worth it.

This is a valid PASS outcome.

Do not force plugin usage merely because the plugin is installed.

---

# SOURCE CONTROL

Likely allowed changes:

- test/evidence harness;
- debug A/B scene/script;
- focused Phase5 test;
- evidence files;
- builder log.

Production source should ideally remain unchanged.

If a tiny production-neutral test seam is genuinely required, document it explicitly and prove shipping behavior remains byte/semantically identical.

Forbidden without owner follow-up approval:

- permanent Spark call in CleaningEffectsController;
- changed M31 native art/lifetime/cap;
- changed gameplay clear timing;
- Remote Content/R2;
- LevelData/supply/VOID;
- Family APK/export;
- Level Factory;
- root TASKS.md.

Builder log:

`coordination/sessions/M43-C005F-PHASE5/M43_C005F_PHASE5_CLAUDE_LOG_V01.md`

Push normally to `main`.

After push:

- sync persistent Desktop non-destructively to final origin/main;
- prove HEAD == origin/main and 0/0;
- prove owner `project.godot` hash unchanged;
- remove only Phase5-created TEMP worktrees.

Final status:

`AWAITING_GPT_M43_C005F_PHASE5_AB_AUDIT_AND_OWNER_DECISION`
