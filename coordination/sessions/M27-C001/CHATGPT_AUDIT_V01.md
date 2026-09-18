# M27-C001 V01 — ChatGPT Final Strict Audit

Date: 2026-09-18
Repository: `Sekiph82/Scrubbots`
Milestone: `M27 — Solvability / Deadlock Engine`
Cycle: `M27-C001 V01`
Auditor: ChatGPT
Start SHA: `27dbf063e1430cb96e6a3355114ae2293ad0ac75`
Implementation SHA: `3e803d37fea64c99aed527d057b0fb47dd15ebfd`
Claude log commit: `2161698c271d6c4630f31582947b252cd9fb1d75`
Criteria: `coordination/sessions/M27-C001/CHATGPT_MASTER_AUDIT_CRITERIA_V01.md`

## Verdict

**AUDITED_PASS / M27 SOLVABILITY & DEADLOCK ENGINE CLOSED**

All `SB-M27-001..034` are eligible for closure.

M27 is a proof/search layer over accepted gameplay semantics, not a contradictory second gameplay engine. The implementation reconstructs isolated instances of the real M24/M25/TargetSelector/ReservationState/ColorCandidateIndex/ProductionRoutingSystem/ProductionAccessQuery/ProductionTargetAccess stack and applies legal front-batch placement and serial authenticated-equivalent clearing.

## Core semantic findings

### Production semantics reused

Verified in `proof_kernel.gd`:
- legal player actions are M23 front batches only;
- placement goes through real `FiveSlotBatchEngine.select_front_batch`;
- full-slot rejection therefore preserves M23 supply;
- claims go through real `BatchTargetClaimEngine.claim_for_color`;
- M25 therefore retains oldest-placement same-color arbitration and TargetSelector WHAT authority;
- reachability uses `ProductionTargetAccess` + `ProductionRoutingSystem` + `ProductionAccessQuery`;
- BoardState transitions use ACTIVE -> CLEARED;
- claim finalization goes through M25/M24 accounting.

No Manhattan-only or custom reachability shortcut replaces production routing.

### Deterministic canonical search

`ProofState` contains only future-relevant gameplay truth:
- board ACTIVE/CLEARED mask;
- per-column FIFO supply;
- five occupied/empty slots;
- color, remaining, lifecycle and relative placement order.

The key excludes UI Nodes, runtime instance ids and timestamps. Placement-sequence values are rank-normalized so equivalent relative order can memoize.

`SolvabilitySolver`:
- branches over all legal selectable columns;
- uses deterministic action order;
- memoizes canonical states;
- returns SOLVED only at exact canonical completion;
- returns UNKNOWN_BOUND on max-state/depth exhaustion;
- returns DEADLOCK only after reachable search is exhausted without a bound hit.

### Generation acceptance

`GenerationGate`:
- derives deterministic attempt seeds;
- regenerates through accepted M23 `BatchSupplyGenerator`;
- checks per-color conservation;
- accepts only solver-proven SOLVED;
- rejects DEADLOCK / UNKNOWN_BOUND / malformed candidates;
- records attempt/outcome/visited/trace information.

Direct evidence proves deterministic reject-then-accept behavior.

### Runtime deadlock classification

`DeadlockClassifier` keeps stable separate statuses:
- COMPLETED;
- PROGRESSABLE;
- STALLED;
- DEADLOCK;
- UNKNOWN_BOUND.

It short-circuits valid M26 in-flight work to non-deadlock, detects immediate claimable progress through the real kernel, and uses bounded future-action search before declaring DEADLOCK.

### Hazard Bot

Real `m21_level_001_hazard_bot.json` is proven SOLVED with exact level totals:
`{0:30, 1:5, 2:298, 3:11, 4:56}`.

Reported deterministic evidence:
- seed: 1;
- columns: 3;
- preview depth: 3;
- batches / decisions: 19 / 19;
- visited: 20;
- trace hash: `1618197986`;
- replay: full completion, final ACTIVE = 0.

Committed trace:
`coordination/sessions/M27-C001/evidence/hazard_bot_solution_trace.json`.

Player-facing M23 preview remains bounded while solver tooling may inspect the full internal candidate queue.

### 59x59

Dedicated evidence uses a true 59x59 LevelData:
- solvable fixture is proven within configured bounds;
- canonical state key remains approximately cell-count scale rather than rendered image/scene scale;
- deliberately bounded stress returns UNKNOWN_BOUND rather than DEADLOCK.

## Governance

Implementation commit is exactly one commit from the canonical M27 start and only adds M27 solver/evidence files plus M27 tests.

Existing M23–M26 production files were not modified by the M27 implementation.

Implementation -> log is one separate commit containing only `CLAUDE_LOG_V01.md`.

Root `TASKS.md` was not modified by Claude.
M28 UI was not implemented.
Image-generation credits: 0.

Claude reports:
- root suite: `5312 checks / 2 baseline environment-only importer failures`;
- zero new M27 failures;
- M27 Hazard Bot: PASS;
- M27 generation retry: PASS;
- M27 59x59: PASS;
- M26 Hazard Bot and scale regression: PASS;
- `git diff --check`: clean.

The two root failures are the same pre-existing dot-segment importer environment failures already reproduced outside the M27 changed surface and are not M27 regressions.

## Closure

Close every `SB-M27-001..034`.

The owner-locked M23–M27 core batch-gameplay program is now closed:

`M23 Batch Supply -> M24 Five-Slot Batch -> M25 Target Claim -> M26 Auto Dispatch -> M27 Solvability/Deadlock`.

Advance canonical project state to **M28 — Gameplay Screen Layout**.
