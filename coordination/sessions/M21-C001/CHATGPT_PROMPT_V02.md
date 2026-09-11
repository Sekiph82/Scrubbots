# M21-C001 V02 — Frozen Builder Corrections + Adversarial Validation

You are the implementer/test runner. ChatGPT is the independent auditor.

Repository: `Sekiph82/Scrubbots`
Branch: `main`
Cycle: `M21-C001`
Evidence output: `coordination/sessions/M21-C001/CLAUDE_LOG_V02.md`

## 0. First actions

Safely synchronize the local repository with `origin/main` while preserving every pre-existing owner/local tracked or untracked change. Do not use `reset --hard`, `clean -fd`, force push, or restore owner work for cleanliness.

Read, in this order:

1. root `TASKS.md`;
2. `CLAUDE.md`;
3. `coordination/AUDIT_POLICY.md`;
4. `coordination/AUDIT_INDEX.md`;
5. `coordination/sessions/M21-C001/CHATGPT_AUDIT_V01.md`;
6. `coordination/sessions/M21-C001/CHATGPT_AUDIT_CRITERIA_V02.md`;
7. `coordination/sessions/M21-C001/OWNER_DIFFICULTY_V1_SCOPE_NOTE.md`;
8. the relevant M09 importer audit learnings AL-010..017 and arbitrary-Variant learnings AL-052/053.

Treat V01 findings F-M21-STRICT-001..004 as the **frozen correction set**. Do not expand into unrelated refactoring.

### Mandatory tracker-only start transition

Before editing implementation/tests/evidence, update **only** root `TASKS.md` Project Status to the truthful active state below, commit that file alone, and push it to `origin/main`:

- Current Milestone: M21
- Current Sprint: M21-C001 V02 — frozen builder corrections + adversarial validation
- Current Task: M21-C001-V02
- Current Task Status: IN_PROGRESS
- Next Task/Action: execute `coordination/sessions/M21-C001/CHATGPT_PROMPT_V02.md` and satisfy `CHATGPT_AUDIT_CRITERIA_V02.md`, then hand back for independent audit.
- Required Actor: CLAUDE
- Progress unchanged: 304/719 main+ui and 304/943 overall
- lastCompletedTaskId remains M20-C001-V11
- Note that V01 independent audit is `CHANGES_REQUIRED / FINDING_SET_FROZEN`, F-M21-STRICT-001..004 are open, V02 is active, and no M21/UI task row is closed.

Do not stage any implementation file or owner/local work in that tracker-only start commit. Record its full SHA in `CLAUDE_LOG_V02.md`.

## 1. Scope protection

This is still M21, not the project-wide Difficulty V1 implementation.

Do NOT:

- change the owner-approved Hazard Bot source PNG;
- change M19/M20 production gameplay code;
- redesign `difficulty_rules.gd` or `production_level_validator.gd`;
- implement Challenge Score, CampaignBuilder or Level Factory generation;
- implement PixelLab/Art Intelligence production integration;
- start M22/M23/M24 UI/touch work;
- add scoring, win/lose, rewards, economy, save or progression;
- close M21/UI task checkboxes yourself.

The accepted source and protected M20 blob identities in V02 criteria are hard locks.

## 2. Correct F-M21-STRICT-001: one difficulty identity

Fix the production-art normalization boundary so it can never validate a compatibility band for one difficulty and emit LevelData with another difficulty.

Prefer the smallest coherent contract. Either:

- derive the M21 compatibility difficulty entirely from the incoming LevelData; or
- retain an explicit argument but require exact equality with `raw.difficulty` before any normalization.

In all cases:

- TEST/unknown/empty must not become successful production-art normalized output;
- successful normalized production output must pass the installed production compatibility validator;
- do not turn the temporary M21 compatibility rule into future Difficulty V1 design law.

Add isolated tests for mismatched difficulty, TEST and unknown difficulty. Construct them so unrelated palette/dimension failures cannot make them green.

## 3. Correct F-M21-STRICT-002: fail closed on arbitrary raw Variants

Before dereferencing the raw input, validate the exact/narrow LevelData contract.

Directly test at least:

- null;
- int;
- string;
- Vector2 or Vector2i;
- unrelated RefCounted/Object;
- partial/malformed object shape.

Every unsupported input must return a normal failed normalization result. It must not produce `SCRIPT ERROR`, `Parse Error`, write a file, or mutate canonical source truth.

Do not widen production duck typing merely to make malformed test doubles pass.

## 4. Correct F-M21-STRICT-003: complete deterministic destination preflight

The new `ProductionArtLevelBuilder` owns a new three-artifact write path. Bring that path up to the already-audited M09 safety level before any final writes occur.

Preflight all enabled destinations before the first final write, including:

- canonical source↔destination aliases;
- destination↔destination aliases;
- equivalent dot-segment/relative forms under the existing lexical identity policy;
- existing-different file conflicts when `overwrite=false`;
- final destination object type;
- destination parent existence and directory type;
- directory targets even when `overwrite=true`.

Add direct tests against the **new builder**, not only historical LevelImporter tests.

Most importantly, create a deterministic later-destination failure arrangement, such as a missing/non-directory parent or directory target for preview/metadata, and prove that the earlier Level JSON/preview final paths remain unchanged or absent. The builder must reject the operation before any known-bad partial final commit.

Do not over-engineer a distributed transaction or claim immunity from unforeseeable hardware failure. Close deterministic filesystem failures knowable during preflight.

## 5. Correct F-M21-STRICT-004: reproducible M21 reference composite

Add the smallest committed debug/test generator or equivalent durable repository command path that recreates:

`coordination/sessions/M21-C001/M21_REFERENCE_COMPOSITE.png`

from authoritative committed M21 LevelData / renderer state.

Requirements:

- do not use the existing composite itself as source truth;
- deterministic initial → partial clear → fully cleared panels over BG01;
- no production UI implementation;
- second run yields/reports unchanged output;
- document the exact command and result in `CLAUDE_LOG_V02.md`;
- label it explicitly as headless evidence, not mobile screenshot/FPS proof.

## 6. Mandatory auditor-authored adversarial validation stage

V02 is also the AL-035 second-stage validation pass. Add fresh V02 arrangements rather than merely rerunning the V01 assertions.

### 6.1 Failed real activation must have exact zero gameplay side effects

Build a fresh authoritative real-art production bundle. Before one blocked non-C08 slot activation, snapshot at least:

- all BoardState cell states;
- the affected and another candidate bucket, or all five buckets;
- reservation truth/count;
- dispatcher active/owner truth as applicable;
- `CompleteClearingLoop.get_cleared_count()`;
- relevant renderer cell truth where useful.

Call the real M21 activation path. Require exactly `NO_REACHABLE_TARGET` and prove the snapshot remains exact. A nearby aggregate zero is not enough if it could hide mutation-and-rollback.

### 6.2 Fresh success progression

On fresh state, dispatch C08 through real selector/access/routing/dispatcher/agent, prove reservation + MOVING before arrival, then authenticated arrival clears exactly once. Continue until a color that was blocked in the fresh state becomes reachable and succeeds through the production path. No forced target or M20 fault seam.

### 6.3 Full-level fresh smoke

Run `tests/m21_real_art_smoke.gd` again as its own fresh runtime. Preserve its finite guard and exact final assertions: 400 clears, 400 CLEARED, 0 ACTIVE, all five colors encountered, zero candidates/reservations/dispatcher-active/orphan agents, renderer alpha 0 everywhere.

## 7. Sensitivity / load-bearing proof

The new V02 negatives must be specific:

- mismatch test must pass all unrelated requirements and fail only because difficulty identities disagree;
- malformed-raw test must reach the contract guard before any dereference;
- later-destination test must be arranged so it would actually create a partial write if the new all-destination preflight were removed.

Explain this sensitivity in `CLAUDE_LOG_V02.md`.

## 8. Required regression runs

Run and record exact results for:

1. `godot --version`;
2. full root suite `godot --headless --path . -s res://tests/run_tests.gd`;
3. `tests/m21_real_art_smoke.gd`;
4. the currently required M20 queue-free and V04/V05/V07/V08/V09/V10 lifecycle smokes;
5. headless boot/parse of `scenes/debug/m21_real_art_vertical_slice.tscn`;
6. reproducible M21 reference-composite generation twice, proving the second run unchanged;
7. M21 LevelData builder rerun, proving canonical output/preview/metadata unchanged;
8. final owner source blob/SHA-256 recheck;
9. final M20 loop/dispatcher blob recheck;
10. literal output scans for `SCRIPT ERROR` and `Parse Error`;
11. `git diff --check`.

Record headless elapsed time only as a headless diagnostic. Do not infer mobile FPS/GPU performance.

## 9. Log and handoff

Create `coordination/sessions/M21-C001/CLAUDE_LOG_V02.md` containing:

- synchronized starting commit;
- all preserved owner/local work relevant to safe sync;
- tracker-only start commit full SHA;
- exact changed files;
- F-M21-STRICT-001..004 closure table;
- V02 adversarial scenario/evidence table;
- every required command and actual result;
- any failure encountered and how it was fixed;
- exact source/M20 blob rechecks;
- explicit statement that no M21/UI checkbox was closed by Claude.

At the end, update only the prompt-authorized lifecycle fields in root `TASKS.md` to:

- Current Milestone: M21
- Current Sprint: M21-C001 V02 — frozen builder corrections + adversarial validation
- Current Task: M21-C001-V02
- Current Task Status: AWAITING_AUDIT
- Required Actor: CHATGPT
- Progress unchanged: 304/719 and 304/943
- lastCompletedTaskId remains M20-C001-V11

Push all authorized work safely to `origin/main` without force.

Then respond with exactly two lines:

`AWAITING_AUDIT`

and the direct GitHub blob URL for:

`coordination/sessions/M21-C001/CLAUDE_LOG_V02.md`
