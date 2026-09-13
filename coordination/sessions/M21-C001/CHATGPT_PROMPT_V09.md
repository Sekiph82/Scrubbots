# M21-C001 V09 — Final Direct-Evidence Reconciliation Prompt

Repository: `https://github.com/Sekiph82/Scrubbots`
Branch: `main`
Actor: Claude (implementer/test runner)
Auditor/tracker owner: ChatGPT

This is a **validation-only, production-immutable** reconciliation pass. V08 found no production defect, but several auditor-authored V08 criteria were not observed on the exact required real-scene/Button/presentation surface. The complete frozen finding set is in:

- `coordination/sessions/M21-C001/CHATGPT_AUDIT_V08.md`
- `coordination/sessions/M21-C001/CHATGPT_AUDIT_CRITERIA_V09.md`

The owner manual V07 Godot gate is already PASS. Do not ask the owner to repeat it unless a genuine source defect is discovered and a later production correction changes accepted behavior.

## 1. Safe sync and exact repository scope

Work only in `Sekiph82/Scrubbots` on `main`.

Before any test/code work:

1. inspect `git status`, current branch and remote;
2. safely synchronize local `main` with current `origin/main` while preserving every owner/local tracked and untracked change;
3. no force push, hard reset, destructive clean, destructive restore, stash loss or owner-file deletion;
4. never touch `Sekiph82/ScrubBots-Level-Factory`, `Sekiph82/H-veAI` or any other repository;
5. preserve the owner's local modifications and inbox/import sidecars exactly.

## 2. Tracker ownership

Read root `TASKS.md` but **do not modify it**.

ChatGPT is the sole writer of root `TASKS.md`. Do not create a tracker-only start commit and do not change lifecycle/status/progress/check boxes at handoff.

## 3. Required reading before execution

Read at minimum:

- `CLAUDE.md`
- root `TASKS.md`
- `coordination/AUDIT_POLICY.md`
- relevant audit-learning/index material referenced by the current M21 coordination docs
- `coordination/sessions/M21-C001/CHATGPT_OWNER_GATE_V07_PASS.md`
- `coordination/sessions/M21-C001/CLAUDE_LOG_V08.md`
- `coordination/sessions/M21-C001/CHATGPT_AUDIT_V08.md`
- `coordination/sessions/M21-C001/CHATGPT_AUDIT_CRITERIA_V09.md`
- the accepted V07/V08 tests and owner scene/controller needed to understand the real observation surfaces.

## 4. Production immutability is mandatory

Do **not** modify:

- any accepted `scripts/**` file;
- any accepted `scenes/**` file;
- `project.godot`;
- root `TASKS.md`;
- owner Hazard Bot source PNG;
- M21 generated LevelData/preview/metadata/reference composite;
- existing V07/V08 owner PASS/audit evidence merely to make V09 easier.

Authorized committed V09 surface is exactly:

1. `tests/m21_v09_direct_evidence_reconciliation.gd`
2. `coordination/sessions/M21-C001/CLAUDE_LOG_V09.md`

If a fresh V09 test proves the accepted production source is actually defective, **STOP `BLOCKED`**. Do not patch production in this run.

## 5. Frozen V09 purpose

Close all five frozen V08 direct-evidence gaps in one pass:

1. exact reservation zero-side-effect on a no-work **real Button** click;
2. distinct adjacent exterior-side evidence for the corner route, excluding the corner cell from double-counting;
3. one fresh real-scene first C08 transaction proving exact whole-board delta `{380}`, candidate drop and reservation lifecycle on the same transaction;
4. three rapid C08 activations through the **real visible Button path** on one fresh scene, including real SlotView active presentation while assignments remain in flight;
5. reset-in-flight through a **fresh real owner scene** after two real C08 Button presses, with exact pre/post board/candidate/reservation/dispatcher/AgentLayer truth.

Do not opportunistically add features or refactor accepted systems.

## 6. Implement one fresh auditor-facing V09 test

Create:

`tests/m21_v09_direct_evidence_reconciliation.gd`

It must be independently understandable and must use the real production collaborators. It may inspect existing debug/test-accessible fields/getters in the owner scene, but it may not add new production hooks just to test them.

### 6A. No-work real Button transaction

On a fresh owner scene:

- locate the real no-work SlotView/Button used by the current Hazard Bot fixture;
- before click snapshot the complete BoardState state vector, candidate sets, reservation count/mappings, dispatcher active count and AgentLayer ScrubbotAgent count;
- press the real Button;
- prove a legitimate no-work result;
- prove exact state equality afterward, including **zero reservation side effect**.

### 6B. Distinct-side corner proof

Using unchanged `ProductionRoutingSystem + ProductionAccessQuery`:

- create a legal adjacent-side corner-transition route;
- validate it through `RouteValidator`;
- directly identify one non-corner left-side ring point/cell and one non-corner top-side ring point/cell (or equivalent adjacent sides);
- do not allow a corner point to satisfy both assertions;
- record route order/indices so the transition is inspectable;
- prove no route/classification exceeds the one-cell ring.

### 6C. First C08 real Button exact transaction

On another fresh owner scene:

- snapshot all 400 BoardState states and the exact C08 candidate set;
- press the real C08 SlotView Button exactly once;
- capture the real assignment result before it can be overwritten;
- prove target `380/(0,19)` and exact visible spawn-anchor mapping;
- while in flight prove exact bidirectional reservation pair;
- complete through real ScrubbotAgent/authenticated M20 arrival;
- compute the whole-board changed-index set and prove it is **exactly `[380]`**;
- prove post-clear C08 candidate set = pre-set minus exactly 380;
- prove exact reservation pair is gone;
- prove dispatcher and AgentLayer cleanup.

### 6D. Rapid x3 through real visible C08 Button

On another fresh owner scene:

- press the actual C08 Button three times before driving the first accepted agent to arrival;
- store each resulting assignment object/result immediately after each press;
- under current accepted behavior all three should succeed naturally with targets `380,381,382` and unique owner IDs;
- prove exact bidirectional reservation mappings and no duplicate target;
- prove the actual C08 SlotView presentation/model is active while any of the three assignments remains in flight;
- finish only the first and prove active remains;
- finish only the second and prove active remains;
- finish the third and prove the slot returns to its accepted non-active/idle state after cleanup;
- prove final whole-board delta is exactly `{380,381,382}`, each changed only ACTIVE→CLEARED;
- prove candidate set loses exactly those three;
- prove all reservations, dispatcher assignments and AgentLayer agents clean up.

If current production legitimately refuses one of the three activations, do not weaken production. Follow the V09 criteria/V08-075 fallback: prove zero side effects for the refusal and complete the ordering evidence serially. If behavior contradicts the accepted owner/test contract rather than being a legitimate refusal, stop `BLOCKED`.

### 6E. Reset in flight through real scene

On another fresh owner scene:

- press the real C08 Button twice without completing either agent;
- store both assignment results;
- before reset snapshot complete BoardState state vector, exact C08 candidate set, exact bidirectional reservation pairs, dispatcher active truth and AgentLayer agent identities/count;
- invoke the canonical bound `CompleteClearingLoop.reset()` used by the real scene;
- prove dispatcher zero, reservations zero, old pairs absent;
- prove complete BoardState state vector is identical to pre-reset;
- prove in-flight targets remain ACTIVE;
- prove candidate set is exactly restored/coherent;
- wait deferred frames and prove zero orphan ScrubbotAgent children;
- then press the real C08 Button again and prove it naturally selects `380/(0,19)`.

## 7. Locked production blobs

After all test work, recheck and log all ten exact blob identities from `CHATGPT_AUDIT_CRITERIA_V09.md`.

If any locked blob differs, stop and investigate. Do not normalize/rewrite production.

## 8. Required validation commands

Run and record exact observed results, including exit status where practical:

1. `godot --version`
2. `godot --headless --path . -s res://tests/m21_v09_direct_evidence_reconciliation.gd`
3. unchanged `tests/m21_v08_corridor_validation.gd`
4. unchanged `tests/m21_v07_corridor_smoke.gd`
5. unchanged `tests/m21_v06_tall_layout_smoke.gd`
6. unchanged `tests/m21_v05_playtest_smoke.gd`
7. unchanged `tests/m21_real_art_smoke.gd`
8. full root `tests/run_tests.gd`, recording exact check count and zero failures
9. all required M20 queue-free/lifecycle regression smokes referenced by the current M21/V08 evidence contract
10. owner scene headless boot with zero SCRIPT/Parse errors
11. `tools/build_m21_level.gd` rerun, requiring LEVEL/PREVIEW/METADATA UNCHANGED
12. `tools/build_m21_reference_composite.gd`, requiring UNCHANGED
13. scan output for `SCRIPT ERROR` / `Parse Error`
14. `git diff --check`

Do not install, upgrade or downgrade Godot in V09. Report the actual installed version truthfully.

## 9. Evidence quality rules

The test must fail for the intended reason if any required invariant is removed. Avoid tautological assertions such as `distance >= 0` or checking a value against the getter that generated the same value without an independent observation.

For the frozen gaps, use exact equality where the criterion asks exact state:

- exact changed-index sets;
- exact candidate-set deltas;
- exact reservation pairs;
- exact active/orphan counts;
- exact target order;
- exact BoardState snapshot equality on reset/no-work cases.

Do not substitute an aggregate count for an exact mapping where the criterion asks identity.

## 10. Commit/diff discipline

Before commit:

- inspect `git status` and `git diff`;
- ensure root `TASKS.md` is not in the diff;
- ensure no accepted production/source/scene/project/artifact file is in the diff;
- ensure the only intended V09 committed additions are the V09 test and V09 log;
- preserve owner/local changes unstaged.

Commit with a focused V09 validation message and push safely to `origin/main` without force.

## 11. `CLAUDE_LOG_V09.md`

Create:

`coordination/sessions/M21-C001/CLAUDE_LOG_V09.md`

It must include:

- exact starting/sync state;
- exact changed files;
- all ten locked blob identities;
- direct evidence for each frozen gap G-V08-01..05;
- actual route points/cells used for the distinct-side corner proof;
- no-work exact pre/post reservation evidence;
- first-clear exact board delta/candidate/reservation evidence;
- rapid real-Button x3 target/owner/reservation/slot-active sequence;
- reset exact pre/post snapshots or concise deterministic hashes plus exact critical identities/counts;
- exact command results and full root check count;
- engine version;
- statement that production and root `TASKS.md` remained byte-identical.

Do not write an audit verdict. That belongs to ChatGPT.

## 12. Handoff

When all V09 criteria pass and authorized work is pushed to canonical `main`, your final response must be exactly two lines:

`AWAITING_AUDIT`

`https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M21-C001/CLAUDE_LOG_V09.md`

If a genuine production defect appears, return `BLOCKED` instead and do not patch production.
