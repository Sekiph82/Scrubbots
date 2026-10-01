# MAINT-SUPPLY-COLUMNS-C001 — ScrubBots 3/4/5 Supply Columns, Preview Depth 3

Document role: CLAUDE IMPLEMENTATION PROMPT

Repository:
https://github.com/Sekiph82/Scrubbots

Owner decision:
https://github.com/Sekiph82/Scrubbots/blob/main/coordination/OWNER_SUPPLY_COLUMNS_3_4_5_PREVIEW3_V01.md

Audit criteria:
https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/MAINT-SUPPLY-COLUMNS-C001/CHATGPT_AUDIT_CRITERIA_V01.md

## Scope

Work ONLY in:
`Sekiph82/Scrubbots`.

Do NOT modify:
`Sekiph82/ScrubBots-Level-Factory`.

Do not create a second game clone/worktree/branch.

This is a narrow shipping-game compatibility task:
- support supply plans with 3, 4, or 5 columns;
- visible preview depth stays exactly 3.

Do not redesign supply gameplay.

## Mandatory local ↔ GitHub sync preflight

Before product edits:

1. Work only in the canonical local Scrubbots checkout.
2. Verify repo identity = `Sekiph82/Scrubbots`.
3. Verify branch = `main`.
4. `git fetch origin --prune`.
5. Inspect:
   - local HEAD;
   - `origin/main`;
   - `git status --short --branch`;
   - ahead/behind;
   - stashes;
   - worktrees.
6. If clean and only behind, fast-forward with `git merge --ff-only origin/main`.
7. Preserve legitimate owner/local changes non-destructively.
8. Never reset, rebase, stash, clean, force checkout, force push, or discard owner work merely to synchronize.
9. Never create a new branch or sibling Desktop clone/worktree.
10. If safe synchronization is impossible, stop before product edits.

## Current architecture facts

Do not reimplement what already works.

Current game already supports:
- `BatchSupplyEngine.MIN_COLUMNS = 3`
- `BatchSupplyEngine.MAX_COLUMNS = 5`
- `BatchSupplyPanel.MIN_COLUMNS = 3`
- `BatchSupplyPanel.MAX_COLUMNS = 5`
- `BatchSupplyPanel` renders exactly three visible rows.

Current blocker:
`SupplyPlanLoader` still hard-locks declarative plans to three columns.

Audit the rest of the runtime for any remaining fixed-three assumption that would break an actual 4/5-column shipping level, but change only what is necessary.

## Required implementation

### 1. SupplyPlanLoader

Replace fixed:
`COLUMN_COUNT := 3`

with an accepted range:
`3..5`.

Requirements:
- `columnCount` must be an exact integer;
- accepted only if 3, 4, or 5;
- `visiblePreviewDepth` must equal exactly 3;
- `columns` must be an array whose size equals declared `columnCount`;
- create the engine with the validated declared count:
  `BatchSupplyEngine.create(column_count, 3)`;
- preserve exact palette mapping;
- preserve unique batch ID validation;
- preserve positive integer robot count validation;
- preserve uncapped global robot-count decision;
- preserve positive per-plan `maxRobotsPerBatch` metadata bound;
- preserve exact per-color conservation;
- preserve exact grand-total conservation;
- preserve engine load validation.

Do not rewrite existing 3-column owner plans.

### 2. Runtime fixed-three audit

Inspect only relevant shipping paths for assumptions such as:
- literal 3-column loops;
- validators requiring exactly 3 columns;
- input routing assuming indices 0..2;
- save/replay/debug serialization assuming 3;
- tests/tools refusing 4/5.

Do NOT change code that is already column-count dynamic.

Do NOT change:
- five-slot baseline gameplay;
- targeting;
- routing;
- clearing;
- booster semantics;
- Difficulty V1 coefficients;
- supply ordering semantics.

### 3. Preview depth

Visible preview depth remains exactly:
`3`.

Do not enable preview depth 4 just because `BatchSupplyEngine` can technically support it.

Shipping supply-plan loader must reject any declarative plan whose preview depth is not 3.

### 4. Slot booster boundary

Canonical level acceptance fixtures use baseline five slots.

Do not activate or depend on +1 Slot booster.

The task is supply-column compatibility only.

## Required tests

Add/update focused tests for:

1. existing 3-column owner plan PASS;
2. valid 4-column plan PASS;
3. valid 5-column plan PASS;
4. 2-column plan rejected;
5. 6-column plan rejected;
6. preview depth 2 rejected;
7. preview depth 4 rejected;
8. preview depth 3 accepted;
9. plan column array length mismatch rejected;
10. >30 robot batch remains accepted under the already-approved uncapped contract;
11. conservation mismatch rejected for 4-column plan;
12. conservation mismatch rejected for 5-column plan;
13. real `SolvabilitySolver.solve` handles accepted 4-column fixture;
14. real `SolvabilitySolver.replay` reaches solved for that 4-column fixture;
15. real solve/replay for accepted 5-column fixture;
16. `BatchSupplyPanel` renders 3, 4 and 5 columns with exactly 3 visible rows;
17. accepted fixtures use baseline five-slot proof state, not +1 Slot.

Prefer small deterministic fixtures so the task tests the column contract, not solver performance.

## Regression gates

Run:
- focused new tests;
- relevant M23/M24/M27/M28/M29/M52 tests;
- existing owner supply plan tests;
- full game test gate;
- Godot headless/editor validation;
- `git diff --check`.

Do not modify root `TASKS.md`.
Do not create ChatGPT audit files.

## Builder log

Create before product edits:

`coordination/sessions/MAINT-SUPPLY-COLUMNS-C001/CLAUDE_LOG_V01.md`

Record:
- sync preflight;
- exact files changed;
- fixed-three assumptions found;
- which were changed and which were already dynamic;
- focused test results;
- full regression results;
- final implementation commit;
- final log commit;
- final HEAD/origin-main 0/0 proof.

Commit implementation separately from the final log publication.

Push to `main`.

Stop for independent ChatGPT audit.

## Final response

Return only:

https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/MAINT-SUPPLY-COLUMNS-C001/CLAUDE_LOG_V01.md
