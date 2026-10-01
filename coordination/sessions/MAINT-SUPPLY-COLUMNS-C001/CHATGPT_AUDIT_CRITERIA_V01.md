# MAINT-SUPPLY-COLUMNS-C001 — ChatGPT Audit Criteria V01

Repository:
https://github.com/Sekiph82/Scrubbots

Owner decision:
`coordination/OWNER_SUPPLY_COLUMNS_3_4_5_PREVIEW3_V01.md`

## PASS rule

PASS only if the shipping game accepts and correctly runs declarative supply plans with exactly 3, 4, or 5 FIFO columns while visible preview depth remains exactly 3, without changing unrelated gameplay semantics.

## Required behavior

- accepted `columnCount`: 3, 4, 5 only;
- rejected: <3 or >5;
- `visiblePreviewDepth == 3` exactly;
- plan `columns.size()` must equal declared `columnCount`;
- `BatchSupplyEngine.create(columnCount, 3)`;
- existing 3-column plans remain valid and unchanged;
- no global robots-per-batch cap;
- exact per-color and grand-total conservation retained;
- palette mapping retained;
- FIFO retained;
- batch identity validation retained;
- baseline solver acceptance uses five slots;
- +1 Slot booster is not required or assumed for generated-level acceptance.

## Existing dynamic foundations must remain

Do not redesign:
- `BatchSupplyEngine`, already 3..5 capable;
- `BatchSupplyPanel`, already 3..5 capable and exactly 3 visible rows.

Only fix remaining fixed-three assumptions that prevent real 4/5-column shipping plans.

## Required evidence

- legacy Levels 2–10 supply plans still load;
- a valid 3-column fixture solves/replays;
- a valid 4-column fixture loads, solves and replays;
- a valid 5-column fixture loads, solves and replays;
- 2 columns rejected;
- 6 columns rejected;
- preview depth 2 rejected;
- preview depth 4 rejected;
- preview depth 3 accepted;
- >30 robots in a valid batch remains accepted;
- conservation failure rejected for 4 and 5 columns;
- UI/panel renders 3, 4 and 5 columns, always exactly 3 visible rows;
- solver sees the actual selected column count;
- no +1 Slot activation is used in acceptance fixtures.

## Regression

Run relevant:
- M23
- M24
- M27
- M28
- M29
- M52
- supply loader/solver/UI tests
- full game test gate
- Godot headless/editor gate
- git diff check

No Level Factory modifications in this task.

Claude must not edit root `TASKS.md`.
