STATUS: READY

# Build: SB-M36-011 Frustration Risk inputs proposal (light path)

Spec (light path): write docs/DIFFICULTY_FRUSTRATION_RISK_PROPOSAL_V1.md. It lists the Frustration Risk definition and weights (docs/09/10/11, score model v1/v2), which inputs exist and which are missing, and a deterministic, telemetry-free way to produce each missing input: a simulated-human policy run by the existing simulator, plus a Session Load budget. It also gives the policy, parameters, seeds, outputs, runtime on 10 levels and acceptance tests. Recommend one approach, file it as the next free SB-M36 ID with a queue row, and tick SB-M36-011. No data/config/script changes, no invented scalar, and only the doc and TASKS.md change.

## Summary
The branch adds the proposal doc and updates TASKS.md. The doc recommends option C: HUMAN_BR, a bounded-rational policy (perception error mu, softmax tau, slip epsilon, Hick-Hyman latency) run as 3 PRIOR_UNCALIBRATED profiles x 32 PCG32 seeds through the real ProofKernel, with LOST = proven DEADLOCK. It pairs this with a per-slot Session Load budget of 22/26/36/40/48 and session_overrun = clamp((SL-budget)/budget,0,1). The implementation is filed as SB-M36-015.

Files changed:
- docs/DIFFICULTY_FRUSTRATION_RISK_PROPOSAL_V1.md (new)
- TASKS.md (SB-M36-011 ticked, queue row DONE, SB-M36-015 entry and READY row added)

Commits: 03506dde (doc), e554f941 (tasks).

## Acceptance criteria
1. [x] Definition and weights listed from docs/09/10/11 and score model v1+v2: doc section 1 (F formula 0.35/0.30/0.20/0.15, Session Load formula and anchors, docs/11 sections 7-8 relative ceilings).
2. [x] Existing vs missing inputs: doc section 2. choiceOpacity SUPPORTED_PROXY; retryRisk and sessionOverrun UNSUPPORTED; lateFailure DIAGNOSTIC_ONLY from one STRESS run (quoted from level_difficulty_analyzer_v2.gd `frustration()`). Also covers fail/retry, dead-end and no-target waits, near-miss, Hearts consumed and session length.
3. [x] Deterministic production without telemetry, with policy, parameters, seeds, outputs, runtime and tests: doc sections 4.1-4.7 and 5. Runtime is about 5.6 h single-process for 10 levels, derived from playtest_v2.json summed measureMs 1469842 ms over 7 policies.
4. [x] Session Load budget proposed, with its effect on the shipped 10 computed from playtest_v2.json: L4/L6/L9 overrun 0.138/0.146/0.139, others 0 (doc 4.4).
5. [x] CLAUDE.md 11.4 and 11.5 respected: F stays a separate axis. The profiles are an offline fixed population with no per-player use and no save or telemetry reads (doc 4.2, 6).
6. [x] One approach recommended and filed: doc section 7. SB-M36-015 is the next free ID (grep for "M36-01[5-9]" found no match before the edit), with its queue row READY.
7. [x] SB-M36-011 ticked with evidence and its queue row set to DONE.
8. [x] No data/config/script change, no invented scalar: `git diff --name-only main...HEAD` lists only TASKS.md and the doc. F is computed only in the future job, with the existing v2 weights, and stays null if any input is missing.
9. [x] `git diff --check main...HEAD` exit 0. CRLF line endings are kept (TASKS.md written as bytes; the doc uses CRLF like its sibling proposal docs).

## Validation
- `git diff --check main...HEAD`: clean (exit 0).
- `git status --porcelain`: empty.
- Doc/analysis only, so no Godot suites apply (no script, scene or config touched).

## Log
### Round 1
Read docs/09 sections 6-7, docs/10 section 7, docs/11 sections 5-8, both score models, both analysis configs, the v2 analyzer policy code, CompletionEvaluator (LOST = DEADLOCK), the Hearts rules and playtest_v2.json. Wrote the proposal, committed it, then updated TASKS.md with the commit SHA. Review evidence is CLAUDE_SELF_REVIEW only; peer review is pending.
