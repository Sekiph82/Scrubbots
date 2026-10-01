# MAINT-SUPPLY-UNCAPPED-C001 — Remove Global Batch Robot Cap

Repository:
https://github.com/Sekiph82/Scrubbots

Owner decision:
https://github.com/Sekiph82/Scrubbots/blob/main/coordination/OWNER_UNCAPPED_BATCH_ROBOT_COUNT_DECISION_V01.md

## Mandatory local ↔ GitHub main sync preflight

Before product work:
1. operate only in the canonical local Scrubbots repository;
2. verify repo identity and branch `main`;
3. `git fetch origin --prune`;
4. inspect HEAD/origin-main divergence, dirty state, stashes and worktrees;
5. fast-forward if clean/behind;
6. preserve legitimate local work non-destructively if present;
7. never reset, rebase, clean, force-push, discard owner work, or create a new branch/worktree unless owner-authorized;
8. begin implementation only after safe main synchronization.

## Scope

Implement only the owner-approved uncapped batch-count correction.

Primary file:
`scripts/gameplay/supply/supply_plan_loader.gd`

Related tests/docs only as required.

## Required behavior

- Remove the hard global `MAX_ROBOTS_PER_BATCH = 30` acceptance ceiling.
- Every batch `robots` value must still be an exact positive integer.
- Preserve three columns and visible preview depth 3.
- Preserve canonical Cxx -> local-palette mapping.
- Preserve unique non-empty batch IDs.
- Preserve exact per-color conservation and grand-total conservation.
- Preserve `BatchSupplyEngine.load_candidate` validation.
- Existing owner supply plans must continue to load byte-for-byte unchanged.

### v1 plan compatibility

Keep `scrubbots.level_supply_plan.v1` backward compatible.

The existing `maxRobotsPerBatch` field may be retained as per-plan declarative metadata:
- must be a positive integer;
- every batch robots value must be <= the plan-declared value;
- no fixed game-wide upper bound;
- preferably fail closed if the declared value is lower than the actual largest batch;
- do not require rewriting existing plans.

## Bridge compatibility

The new Level Factory primary supply bridge must not require a removed `SupplyPlanLoader.MAX_ROBOTS_PER_BATCH` constant.

If game-side tests/tools reference that constant, update them to the uncapped contract rather than introducing a replacement global ceiling.

## Required tests

At minimum:
- existing Levels 2-10 supply plans still load;
- batch 0 rejected;
- negative rejected;
- fractional rejected;
- malformed rejected;
- conservation failures rejected;
- a valid conserved supply plan containing batch 31 loads;
- a valid conserved supply plan containing a substantially larger positive batch also loads;
- solver/replay for an uncapped valid fixture remains SOLVED/WIN;
- full `tests/m52_owner_supply_plans.gd` updated so it no longer asserts max <=30;
- relevant M23/M24/M27/M52 regressions green;
- full repository gates.

Do not redesign supply gameplay.

## Final report

Record exact changed files, test commands/results, and final main SHA.
Return the GitHub log/evidence link only.
