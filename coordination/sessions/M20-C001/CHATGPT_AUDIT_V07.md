# M20-C001 — ChatGPT Independent Whole-Sprint Audit V07

Decision: **SOURCE_CORRECTION_ACCEPTED / WHOLE_SPRINT_VALIDATION_ONLY_V08_REQUIRED**

Audited implementation commit:
`e189ee8bd2b9be68b876cfdb18377622ed3ce832`

Start-transition commit:
`3966d0304ed818d737f5ada4abd347d971bdd3d7`

Prompt:
`coordination/sessions/M20-C001/CHATGPT_PROMPT_V07.md`

Criteria:
`coordination/sessions/M20-C001/CHATGPT_AUDIT_CRITERIA_V07.md`

Claude evidence:
`coordination/sessions/M20-C001/CLAUDE_LOG_V07.md`

Canonical tracker: repository-root `TASKS.md` only.

## Evidence level / runtime limitation

Claude reports Godot `4.7.1.stable.official.a13da4feb`, full suite **3772 / 3772 ALL PASS**, `m20_queue_free_smoke` PASS, V04/V05/V07 lifecycle smokes PASS, zero final M20 SCRIPT/Parse errors, and clean `git diff --check`.

Those runtime results remain E1/E2 because ChatGPT cannot execute Godot in the audit environment. ChatGPT independently inspected the V07 start/handoff ordering, exact changed-file set, current production source, current V07 tests, current docs, root tracker, prior M20 regression blocks and the criteria-to-evidence mapping. That is E3 source/diff/test-structure evidence.

## Governance / scope

PASS:
- start transition is a separate parent commit before the implementation/handoff commit;
- V07 production changes are limited to `complete_clearing_loop.gd` and `scrubbot_dispatcher.gd`;
- tests/docs/log/tracker changes are within authorized V07 scope;
- no SB-M20 checkbox was closed;
- tracker is `M20-C001-V07 / AWAITING_AUDIT / CHATGPT`;
- progress remains 290/719 main+ui, 290/943 overall, last completed M19-C001-V06.

## Mandatory whole-sprint Pass A — implementation/state sweep

### F-M20-STRICT-001.M — single M20 transaction owner per dispatcher

**SOURCE ACCEPTED.**

Accepted V07 behavior:
- dispatcher stores a non-owning `WeakRef` claim;
- first live consumer can claim;
- a different live consumer is rejected;
- stale GC'd consumer frees the claim without a strong cycle;
- diagnostic signal listeners do not define ownership;
- `CompleteClearingLoop.bind()` performs exact bundle validation and active-count-zero validation before claiming;
- arrival callback is connected only after successful claim;
- failed connection releases only the just-acquired exact claim;
- bundle fields are committed only after claim+connection success;
- second live loop cannot bind the same dispatcher under ordinary production paths.

No BoardState/candidate/reservation/render mutation moved into M19.

### F-M20-STRICT-001.N — explicit `agent_parent` presence

**SOURCE ACCEPTED.**

Accepted V07 behavior:
- public `agent_parent` argument is untyped so a truly-freed Node reaches the fail-closed body rather than failing at typed argument normalization;
- TYPE_NIL alone selects default dispatcher-self semantics;
- every non-NIL Variant is treated as explicit configuration;
- explicit parent is checked with `is_instance_valid` before `is Node` / queued-state access;
- captured presence truth is revalidated after bind-time coherence callbacks;
- only validated explicit Node or dispatcher self is committed into typed `_agent_parent` storage;
- post-bind attach-time liveness gate remains;
- explicit factory behavior remains unchanged.

The V07 frame smoke directly demonstrates the newly learned Godot runtime case: truly-freed explicit parent is rejected without silent self fallback or SCRIPT ERROR.

### Accepted V06 renderer law preserved

**SOURCE ACCEPTED / regression locked.** `_renderer_expected` remains the semantic presence authority. TYPE_NIL remains headless; a configured renderer that later dies cannot silently become headless. Renderer remains post-finalize presentation.

### Transaction / rollback / reset surface

No new material source defect found in the full re-read of:
- activation serialization + post-dispatch generation/coherence barrier;
- authenticated arrival preflight;
- BoardState -> candidate -> reservation -> dispatcher finalize -> renderer ordering;
- exact reservation owner-map postcondition/rollback proof;
- current-arrival dedup + distinct FIFO;
- deferred reset;
- pair-narrow dispatcher reset;
- AL-028 live BoardState access behavior;
- no normal BoardState full scan in the clearing loop.

### Sibling-failure search

Checked as required by the 2026-09-11 policy:
- renderer configured-vs-dead: V06 model remains intact;
- `agent_parent` configured-vs-dead: V07 correction closes the sibling;
- explicit agent factory configured-vs-invalidated: existing `_explicit_factory` law remains;
- owner-wide cleanup siblings: pair-narrow reset remains;
- cached route null-vs-present sibling: M19 final law remains;
- exact dependency category gates: M20 production bind remains exact-script for canonical collaborators.

No additional production correction is frozen from these sibling checks.

### Interaction sweep

Reviewed:
- claim + reset;
- claim + second loop;
- reset + dependency drift;
- lifecycle death + renderer;
- lifecycle death + agent parent;
- rollback + unrelated state;
- duplicate/current arrival + reset;
- completion + stale identity;
- presentation loss + canonical state;
- 59x59 / rectangular + synchronization.

No material V07 source defect found under ordinary authorized production paths.

## Mandatory whole-sprint Pass B — evidence/test/policy sweep

V07 materially improves coverage, but final closure still requires one auditor-authored validation-only pass. The following are the complete known evidence/spec gaps to close together in V08.

### G-V07-01 — arrival-preflight matrix is not yet direct-complete

The fresh V07 desync block directly covers wrong owner/target/color/source, unknown owner and missing reservation. However prompt/criteria also require M20-level direct arrangements for:
- same-board target reservation replaced by a different owner;
- ReservationState rebound to a foreign board with a foreign replacement reservation that must survive cleanup;
- ColorCandidateIndex rebound to a foreign board before arrival;
- candidate neutralized/unbound before arrival where safely reproducible;
- direct unrelated candidate/reservation preservation on those failed preflights.

Prior M19 pair-narrow and M20 rollback tests cover adjacent mechanisms, but they are not a substitute for the requested M20 arrival-preflight arrangements.

### G-V07-02 — forged-arrival reservation preservation needs direct observation

The V07 wrong-identity loop directly proves BoardState unchanged, cleared_count zero and real dispatcher assignment retained. It does not directly assert the real reservation remains held for each forged identity variant. V08 must do so.

### G-V07-03 — renderer queued-before-arrival candidate preservation

V07 directly proves BoardState ACTIVE, cleared_count unchanged, reservation held and dispatcher assignment held. It does not directly assert the raw candidate remains present, although source behavior implies it because preflight exits before mutation. V08 must observe it directly.

### G-V07-04 — activation rejection must use per-case detached snapshots

V07 covers the full requested invalid argument set, but several assertions are aggregate across a group. V08 must snapshot before EACH rejected activation and prove, per case:
- active count unchanged;
- reservation owner-map/count unchanged;
- BoardState unchanged;
- slot palette/availability/activity unchanged;
- owner counter unchanged where applicable.

This prevents an early/late invalid case from hiding mutation by a neighboring case.

### G-V07-05 — bind-time explicit-parent death deserves direct callback evidence

Source revalidation after coherence callbacks is correct. V08 should directly inject a bind-time coherence callback that queues/frees the explicit parent and prove bind does not commit. Also prove a healthy bind followed by true parent destruction before dispatch fails cleanly with reservation cleanup/no orphan.

### G-V07-06 — claim/reset/GC interaction deserves fresh validation

V07 proves first owner, second-loop rejection, first-loop usability and claim reuse after first-loop release. V08 must additionally prove:
- reset of the owning loop does not accidentally release/transfer the M20 claim;
- second loop remains rejected after owner reset while owner loop remains live;
- after owner loop is actually released/GC'd and signal connection disappears, a fresh loop can claim exactly once;
- one authenticated arrival produces one M20 clear/count increment.

### G-V07-07 — V07 criterion 109 is stricter than its own prompt

This is an **AUDIT SPECIFICATION DEFECT**, not a Claude implementation defect.

V07 prompt allowed second-bind preservation to be demonstrated by making the original renderer "queued/dead **or foreign-board**". V07 criterion 109 says queued/dead specifically. Claude used the prompt-authorized foreign-board proof. V08 will remove the contradiction and directly include both foreign-board and queued/dead preservation.

### G-V07-08 — current architecture documentation still contains an older stale paragraph

`docs/02_TECH_ARCHITECTURE.md` correctly received the V07 concurrency correction, but its later current-text section "What is explicitly NOT built yet" still says reservation/TargetSelector/Routing/Scrubbot Agent are future milestones and says the M10 transparency owner QA is still pending. That conflicts with current repository truth and completed M14-M19/M10 state.

V08 may make a documentation-only correction while keeping gameplay production immutable. Historical prompts/audits remain untouched.

## Task-by-task M20 ledger disposition

| Task | Current audit status before V08 | Basis |
| --- | --- | --- |
| SB-M20-001 complete sequence | PROVISIONALLY PROVEN | real healthy V07 tuple + source audit |
| SB-M20-002 no target means no bot | PROVISIONALLY PROVEN | no-target + enclosed target direct tests |
| SB-M20-003 no return | PROVISIONALLY PROVEN | queue_free smoke + source finalization |
| SB-M20-004 one-cell | PROVISIONALLY PROVEN | true 1x1 direct test |
| SB-M20-005 one-color | PROVISIONALLY PROVEN | V07 ledger + prior scenario |
| SB-M20-006 multi-color | PROVISIONALLY PROVEN | V07 ledger |
| SB-M20-007 five-slot | PROVISIONALLY PROVEN | five unique owner/target/pair evidence |
| SB-M20-008 Easy | PROVISIONALLY PROVEN | fresh production-spine representative |
| SB-M20-009 Medium | PROVISIONALLY PROVEN | fresh production-spine representative |
| SB-M20-010 Hard | PROVISIONALLY PROVEN | fresh production-spine representative |
| SB-M20-011 Very Hard | PROVISIONALLY PROVEN | fresh production-spine representative |
| SB-M20-012 59x59 | PROVISIONALLY PROVEN | max-board path + source complexity review |
| SB-M20-013 rectangular | PROVISIONALLY PROVEN | 53x59 direct path |
| SB-M20-014 state desync | GAP PENDING V08 | direct matrix gaps G-V07-01..06 |

No task closes in V07 because production changed and independent runtime E3 is unavailable.

## Criteria-to-evidence reconciliation

Material V07 criteria were classified during audit as:
- `SOURCE_PROOF`: production category/lifecycle/ordering/complexity invariants;
- `DIRECT_TEST`: bind/renderer/desync/activation/task-ledger behavior;
- `SENSITIVITY`: S1 consumer claim, S2 agent_parent presence, S3 renderer presence;
- `LOG/GOVERNANCE`: tracker/order/scope/hash/full-suite evidence.

Known direct-test shortfalls are exactly G-V07-01..06 above. Criterion 109 mismatch is G-V07-07. No aggregate green count is used to silently mark those PASS.

## V07 production blob lock for V08

Accepted V07 clearing-loop blob:
`06391839523cbc27e88a4b3ef12b730012cd45fa`

Accepted V07 dispatcher blob:
`eee10149e4f116af6706beec832042352bf3a6dd`

V08 must be validation-only for `scripts/**`; temporary sensitivity mutations are allowed only after the tracker start push, must never be committed, and must restore exactly to these accepted blobs before final validation.

## Verdict

**SOURCE_CORRECTION_ACCEPTED / WHOLE_SPRINT_VALIDATION_ONLY_V08_REQUIRED**

If V08 passes with production immutable and closes G-V07-01..08 plus fresh auditor-authored coverage of SB-M20-001..014, ChatGPT may final-close M20.