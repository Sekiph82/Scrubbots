# M25-C002 — CHATGPT AUDIT CRITERIA V01

Date: 2026-09-29
Auditor: ChatGPT
Task: `SB-M25-033`

Expected verdict if clean:

`INVESTIGATION_AUDITED_PASS / IMPLEMENTATION_PROMPT_REQUIRED`

## A. No production mutation — BLOCKING

FAIL if the cycle changes shipping gameplay behavior.

Allowed:
- test/debug instrumentation;
- evidence;
- proposal docs.

Forbidden:
- TargetSelector behavior changes;
- access/routing policy changes;
- scheduler changes;
- claim/reservation changes;
- `TASKS.md` edit by Claude.

## B. Reproduction quality

PASS requires real ProductionGameplayHost reproduction of the dense 59x59 hotspot and comparison against historical tempo and a smaller control.

Must establish that:
- expensive path is real;
- it is in target-selection/access probing;
- underlying hotspot predates M29 retune;
- faster cadence can increase encounter frequency.

## C. Per-lane attribution

PASS requires representative per-lane measurements including:
- candidate count;
- is_targetable calls;
- route-compute calls;
- probe success/failure;
- selected candidate rank;
- board revision/origin;
- target-selection time.

Aggregate-only timing is insufficient.

## D. Existing prefilter understanding

PASS requires correct analysis of current ProductionTargetAccess `_could_reach` / reach-mask behavior and an evidence-backed explanation of why it does not bound this case.

## E. Truth-preservation

Every recommended option must preserve:
- exact bottom-most/left-most target winner;
- reservation/claim atomicity;
- WHAT/HOW separation;
- same-color FIFO arbitration;
- no ghost / rollback laws;
- strict fail-closed behavior.

FAIL for recommendations that simply choose a cheaper/different target.

## F. Option comparison

PASS requires at least three credible mitigation families, including:
- stronger exact-safe necessary-condition/frontier filter;
- exact memo/cache;
- bounded incremental deterministic continuation.

Each must discuss correctness, invalidation, complexity and expected benefit.

## G. Recommendation

PASS requires one preferred design or staged combination with:
- ownership location;
- exact invalidation rules;
- expected bound;
- files likely affected;
- regression risks;
- implementation proof obligations.

No code implementation yet.

## H. Future acceptance metric

PASS requires a subsequent implementation target that includes an algorithmic bound independent of noisy wall-clock timing, plus observed timing evidence.

## I. Governance

Historical M29 implementation remains untouched.

SB-M29-010 remains open while this blocker is investigated.

After proposal audit, ChatGPT decides whether to create an M25 remediation implementation prompt and how it affects M29 owner playtest.
