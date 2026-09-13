# M21-C001 V10 — Final Reservation/Scene Direct-Evidence Reconciliation

Repository: `https://github.com/Sekiph82/Scrubbots`
Branch: `main`
Actor: Claude (implementer/test runner)
Auditor/tracker owner: ChatGPT

This is the **final validation-only, production-immutable M21 reconciliation pass**. V09 found no production defect and materially closed the V08 scene/Button/presentation gaps, but ChatGPT's strict audit found that the V09 test knowingly used the dispatcher's assignment map as a proxy for the separate ReservationState and omitted a few exact scene assertions.

Read and obey:

- `coordination/sessions/M21-C001/CHATGPT_AUDIT_V09.md`
- `coordination/sessions/M21-C001/CHATGPT_AUDIT_CRITERIA_V10.md`

The owner manual V07 Godot gate is already PASS. Production must remain byte-identical. No owner re-test is requested on a clean V10.

## 1. Safe sync / repository law

Work only in `Sekiph82/Scrubbots` on `main`.

Before test work:

1. inspect branch/remote/status;
2. safely sync local `main` with current `origin/main` while preserving every owner/local tracked and untracked change;
3. no force push, hard reset, destructive clean/restore, stash loss or owner-file deletion;
4. preserve the owner's existing local `project.godot`, debug-scene and inbox/import work exactly;
5. do not touch any other repository.

## 2. Tracker ownership

Read root `TASKS.md` but **do not modify it**. ChatGPT is the sole writer of root `TASKS.md`.

Do not close any M21/M22/SB-UI checkbox and do not alter progress/lifecycle fields.

## 3. Required reading

Read at minimum:

- `CLAUDE.md`
- root `TASKS.md`
- `coordination/AUDIT_POLICY.md`
- `coordination/sessions/M21-C001/CHATGPT_OWNER_GATE_V07_PASS.md`
- V08 and V09 prompts/criteria/logs/audits
- `CHATGPT_AUDIT_CRITERIA_V10.md`
- the unchanged owner scene/controller, CompleteClearingLoop, ReservationState, ScrubbotDispatcher, SlotView and V09 test.

## 4. Production immutability

Do **not** modify:

- any accepted `scripts/**` file;
- any accepted `scenes/**` file;
- `project.godot`;
- root `TASKS.md`;
- owner Hazard Bot source PNG;
- M21 LevelData/preview/metadata/reference composite;
- existing V07/V08/V09 tests or owner/audit evidence.

Authorized V10 committed additions are exactly:

1. `tests/m21_v10_final_reservation_evidence.gd`
2. `coordination/sessions/M21-C001/CLAUDE_LOG_V10.md`

If the direct ReservationState inspection reveals a genuine production mismatch, **STOP `BLOCKED`** and do not patch production.

## 5. Directly observe the exact ReservationState object

The V09 test must not be copied forward with the same proxy. Obtain the actual `ReservationState` object already bound into the **real owner scene's real CompleteClearingLoop** using test-only, read-only introspection of existing fields. Do not add a new getter/hook to production.

The current production loop already owns a separate `_reservations` collaborator and the dispatcher has `is_bound_to(board, reservation_state)`. V10 may read these existing fields/methods from the test to prove it is observing the exact live object.

Required baseline proof in the test:

- obtain owner scene's exact `_loop`;
- obtain that loop's exact existing `_reservations` object;
- prove the dispatcher is bound to the same board + same ReservationState via existing `is_bound_to(...)`;
- use the ReservationState's real read-only queries such as `get_reservation_count()`, `get_owner(target)`, `get_target_for_owner(owner)` for all direct reservation evidence;
- do **not** instantiate a parallel ReservationState and call it proof.

## 6. One fresh V10 test, four exact scenarios

Create:

`tests/m21_v10_final_reservation_evidence.gd`

### A. No-work real Button

Fresh real owner scene:

- assert exactly five SlotViews;
- obtain exact live ReservationState as above;
- assert reservation count zero before the real no-work Button click;
- snapshot relevant board/candidate/dispatcher/AgentLayer truth;
- press the actual visible no-work Button;
- assert legitimate no-work result;
- assert reservation count remains exactly zero and no bidirectional mapping appears;
- assert dispatcher/AgentLayer zero and board/candidate truth unchanged.

### B. First C08 real Button

Fresh real owner scene:

- press actual visible C08 Button once;
- naturally obtain target `380/(0,19)` and exact owner ID;
- while in flight assert directly on the **actual ReservationState**:
  - `get_owner(380) == owner_id`;
  - `get_target_for_owner(owner_id) == 380`;
  - reservation count == 1;
- complete real agent through normal authenticated arrival;
- directly assert both mappings absent and count == 0 afterward;
- retain accepted V09 board/candidate/dispatcher/AgentLayer cleanup checks.

### C. Rapid real Button x3

Fresh real owner scene:

- press actual C08 Button three times before first completion;
- naturally get exact target order `380,381,382` and unique owners;
- assert actual ReservationState count == 3;
- assert all three exact target→owner and owner→target pairs;
- assert AgentLayer contains exactly 3 real ScrubbotAgent children and actual C08 SlotView is active;
- complete only first: reservation count 2, first pair absent, other two pairs intact, AgentLayer exactly 2, slot active;
- complete only second: reservation count 1, second pair absent, third intact, AgentLayer exactly 1, slot active;
- complete final: reservation count 0, all pairs absent, AgentLayer 0 after deferred cleanup, slot idle;
- retain V09 exact board/candidate delta checks.

### D. Reset in flight

Fresh real owner scene:

- press actual C08 Button twice without completion;
- directly assert targets are exactly `380,381` and unique;
- capture both owner IDs and exact two agent instance identities;
- assert AgentLayer contains exactly those two agents;
- assert actual ReservationState count == 2 and both exact bidirectional pairs exist;
- capture full BoardState and C08 candidate truth;
- invoke the canonical reset through the real scene/bound loop;
- assert actual ReservationState count == 0 and all old bidirectional mappings absent;
- assert dispatcher zero;
- assert BoardState unchanged and targets remain ACTIVE;
- assert C08 candidates unchanged/coherent;
- after deferred cleanup assert neither captured agent identity remains and AgentLayer count is zero;
- press actual C08 Button again and naturally get `380/(0,19)`.

## 7. Locked blobs

After V10, recheck and log all ten exact locked blob identities from `CHATGPT_AUDIT_CRITERIA_V10.md`. Any mismatch means investigate/stop; do not normalize production.

## 8. Required commands

Run and record exact observed results:

1. `godot --version`
2. `godot --headless --path . -s res://tests/m21_v10_final_reservation_evidence.gd`
3. unchanged V09 test
4. unchanged V08 test
5. unchanged V07/V06/V05 M21 smokes
6. unchanged M21 400-cell real-art smoke
7. full root `tests/run_tests.gd` with exact check count and zero failures
8. required M20 queue-free/lifecycle smokes
9. owner scene headless boot, zero SCRIPT/Parse errors
10. `tools/build_m21_level.gd` rerun: LEVEL/PREVIEW/METADATA UNCHANGED
11. `tools/build_m21_reference_composite.gd`: UNCHANGED
12. scan for SCRIPT/Parse errors
13. `git diff --check`

Do not install/upgrade/downgrade Godot. Report the actual installed version.

## 9. Diff discipline

Before commit, verify the V10 implementation diff contains **only**:

- `tests/m21_v10_final_reservation_evidence.gd`
- `coordination/sessions/M21-C001/CLAUDE_LOG_V10.md`

Root `TASKS.md`, production source/scenes/project/artifacts and existing V07/V08/V09 tests must be absent from the diff.

## 10. CLAUDE_LOG_V10.md

Log:

- starting/sync state;
- exact two changed files;
- actual ReservationState object identity/coherence proof;
- no-work exact reservation count/mapping before/after;
- first C08 exact reservation pair/count lifecycle;
- rapid-x3 exact three-pair/count and AgentLayer `3→2→1→0` lifecycle;
- reset exact targets `380,381`, owner IDs, captured agent identities, reservation pair/count pre/post and cleanup;
- all ten locked blobs;
- exact commands/results and root check count;
- engine version;
- production/TASKS immutability statement.

Do not write an audit verdict.

## 11. Handoff

If every V10 criterion passes and authorized work is safely pushed to canonical `main`, respond exactly:

`AWAITING_AUDIT`

`https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M21-C001/CLAUDE_LOG_V10.md`

If direct evidence reveals a genuine production defect, return `BLOCKED` and do not patch production.

A clean independent ChatGPT V10 audit closes M21. **No V11 is created reflexively.**
