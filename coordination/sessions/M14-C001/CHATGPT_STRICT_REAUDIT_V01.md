# M14-C001 — Strict Re-Audit V01

Decision: **AUDITED_PASS**

This is a second-pass audit performed explicitly under the repository's canonical audit policy:

- `coordination/AUDIT_POLICY.md`
- `coordination/AUDIT_INDEX.md`
- `coordination/README.md`

It supplements, and does not erase, the original:
`coordination/sessions/M14-C001/CHATGPT_AUDIT_V01.md`

## Evidence classification

### E0 — claims only
Not accepted as proof by themselves:
- Claude's statement that M14 is complete.
- File existence alone.
- The aggregate claim `1098/1098 ALL PASS` by itself.
- Performance prose by itself.

### E1/E2 — Claude implementer evidence
Verified present in the matching `CLAUDE_LOG_V01.md`:
- exact Godot version;
- exact full-suite command;
- 1098/1098 result;
- implementation base SHA;
- implementation commit;
- changed-file list;
- task-by-task test mapping;
- 59×59 reservation timing evidence;
- scope/non-scope declarations;
- push/handoff state.

This is strong reproducible implementer evidence, but not independent proof by itself.

### E3 — ChatGPT independent evidence
Independently inspected:
- exact V01 prompt;
- exact V01 audit criteria;
- exact matching Claude V01 log;
- implementation diff `c01fbc6... -> b6b2408...`;
- new `reservation_state.gd`;
- unchanged `BoardState.CellState`;
- unchanged `ColorCandidateIndex` source;
- M14 test implementations in `tests/run_tests.gd`;
- ADR-022;
- technical architecture/gameplay documentation;
- changed-file scope;
- canonical task ledger after closure;
- canonical progress recomputed from unique SB IDs.

The local audit environment does **not** contain a Godot executable, so the
Godot 4.7.1 suite was **not independently rerun by ChatGPT** in this strict
re-audit. This is explicitly recorded per AUDIT_POLICY. Instead, the exact test
code and failure observability were independently inspected/cross-checked.

### E4 — owner approval
No E4 gate is required by M14. M14 is architecture/runtime bookkeeping, not a
human-controlled visual/product decision gate.

---

## Relevant AUDIT_INDEX learnings applied

### AL-005 — task completion
Applied. No M14 checkbox is accepted merely because a file exists. Each closure
is mapped to implementation + direct test/ADR evidence.

### AL-009 — aggregate green count is insufficient
Applied. `1098/1098` is not used as sole proof. Individual M14 test bodies were
inspected.

### AL-011 — negative-test specificity
Applied. Negative cases directly isolate:
- invalid index;
- CLEARED target;
- invalid owner;
- duplicate target;
- same-owner duplicate;
- same-owner second target;
- wrong-owner release;
- wrong-owner arrival;
- repeated arrival.

No unrelated earlier failure condition makes those checks pass.

### AL-018 — direct observability
Applied. The M14 tests call ReservationState directly and observe the exact
reservation state/result being claimed, rather than using proxy UI/session
state.

### AL-020 — mutable-state leakage
Applied. The detached reserved-index test mutates the returned
`PackedInt32Array` and verifies internal reservation truth remains unchanged.

### AL-026 — owner-work preservation
Applied. Claude log records pre-existing `project.godot` and untracked owner
assets as preserved/not staged; implementation diff confirms they were not
included.

### AL-028 — candidate != final target
Applied. M14 preserves ColorCandidateIndex as raw candidate truth only.
Reservation exclusions are caller-supplied; M14 does not claim reachability or
implement final target selection.

---

# Requirement-level strict findings

## Architecture

**PASS — separate ownership layer.**
`ReservationState` is a dedicated RefCounted module with two mirrored maps:
target→owner and owner→target.

**PASS — no RESERVED cell state.**
Independent source inspection confirms BoardState still contains exactly:
`ACTIVE=0`, `CLEARED=1`.

**PASS — ADR-022.**
The ADR explicitly defines reservation as ephemeral assignment metadata, not
artwork/access state.

**PASS — owner token semantics.**
`owner_id >= 0` is documented as a future assignment token and not color,
slot or cell identity.

## Reserve/release semantics

**PASS — synchronous check-and-set.**
`reserve()` performs bound/owner/index/ACTIVE/conflict validation and both
dictionary writes in one synchronous call. There is no `await`,
`call_deferred`, signal round-trip or asynchronous gap.

**PASS — target uniqueness.**
`_target_to_owner.has(target_index)` rejects both same-owner and other-owner
duplicate target claims.

**PASS — owner uniqueness.**
`_owner_to_target.has(owner_id)` prevents one owner from holding two targets.

**PASS — ownership-safe release.**
`_release_owned()` verifies exact target owner before erasing either map.

**PASS — reset/rebind.**
Both mirrored maps are cleared. Rebind clears old-board state before binding the
new board.

**PASS — arrival resolution.**
`resolve_arrival()` removes reservation metadata through the ownership-safe
release path and does not call BoardState mutation.

## Negative-test false-positive review

The test bodies were inspected, not merely their names.

- invalid index tests fail specifically at index validation;
- CLEARED test explicitly changes target 4 to CLEARED first;
- invalid owner test uses a valid ACTIVE target with owner -1;
- duplicate-target test starts from a known successful existing reservation;
- same-owner-second-target test uses a different unreserved ACTIVE target;
- wrong-owner release checks the reservation is still present afterward;
- wrong-owner arrival checks the reservation is still present afterward;
- second arrival is attempted after a known successful first resolution.

These are materially isolated negative tests. No obvious false-positive path was
found.

## Candidate-index integration

**PASS — direct seam observed.**
With reserved indices supplied, reserved cells disappear from raw color
candidates. Without exclusions, those same cells remain present. This directly
proves ColorCandidateIndex itself does not own reservation state.

**PASS — release visibility.**
After release, the ACTIVE candidate appears again when the updated exclusion set
is passed.

## Encapsulation

**PASS — no mutable reservation container leak.**
`get_reserved_indices()` constructs a new sorted PackedInt32Array.
The test mutates the returned snapshot and then verifies internal indices/count
are unchanged.

Other query methods return scalars.

## Concurrency/atomicity interpretation

**PASS under the M14-defined execution model.**

The "concurrency" regression is not a multithreaded race. It performs 50
competing synchronous reserve calls against the same target and verifies exactly
one succeeds.

This is appropriate to the prompt's explicitly locked current model:
Godot gameplay is main-thread/synchronous and M14 atomicity means uninterrupted
check-and-set within one call.

This audit does **not** claim thread safety.

## Performance

**PASS for the required architecture claim.**
Static source inspection confirms normal:
- `reserve`
- `is_reserved`
- `get_owner`
- `get_target_for_owner`
- `release`

do not iterate the board. They use O(1)-average dictionary operations plus
single-index BoardState validation.

The Claude timing result on 59×59 is E2 implementer evidence only and was not
independently rerun. No GPU/FPS claim is made.

`get_reserved_indices()` sorts reservation keys, so that query is not O(1);
the prompt did not require it to be O(1), only normal lookup/reserve/release.

## Scope

**PASS.**
The actual implementation diff contains only:
- CLAUDE.md wording cleanup;
- Claude V01 log;
- gameplay/architecture docs;
- ADR-022;
- new ReservationState;
- M14 tests.

No TargetSelector, routing, agent, dispatcher, renderer, palette, production
level, H!veAI, SESSION_INDEX or Claude-side tasks.md modification appears in
the implementation commit.

---

# Strict-audit findings discovered outside M14 implementation

## Finding SRA-M14-001 — stale audit-memory palette rule

`AUDIT_INDEX.md` AL-031 still describes C01..C15 / palette v1 as current,
while the owner later explicitly expanded the canonical palette to C01..C16
with palette v2.

This is **not an M14 implementation failure** because:
- M14 did not change palette behavior;
- the active M14 prompt explicitly locked C01..C16;
- current code/governance uses palette v2.

But the reusable audit memory must be corrected/superseded so future audits do
not apply stale palette law.

## Finding SRA-M14-002 — independent executable rerun unavailable

The strict audit environment had no Godot binary, so `1098/1098` was not
independently executed by ChatGPT.

Per AUDIT_POLICY this limitation is disclosed rather than hidden. Independent
E3 evidence here is source/diff/test-quality cross-checking.

This does not force CHANGES_REQUIRED because the policy requires independent
rerun/cross-check **where accessible**, not an impossible rerun in every audit.

---

# Progress independently recomputed

Using unique canonical SB task IDs from current `tasks.md`:

- Overall: **224 / 943 = 23.75%**
- Remaining: **719**
- Main game + SB-UI: **224 / 719 = 31.15%**
- Level Factory: **0 / 112 = 0%**
- Content Pipeline: **0 / 112 = 0%**

The previously reported progress is correct.

---

# Final strict verdict

**AUDITED_PASS**

The second-pass strict audit found no M14 defect requiring a V02 correction
prompt.

The task closures remain justified:
- SB-M02-017
- SB-M14-001..009

M15 remains NOT_STARTED.

The stale AL-031 audit-memory rule is a repository-governance follow-up and is
being corrected by ChatGPT as part of this strict audit maintenance.
