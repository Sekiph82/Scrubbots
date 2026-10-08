# M43-C005F-PHASE2-R01 — Earned Pack Production Wiring — STRICT AUDIT CRITERIA V01

## Verdict gate

PASS requires real shipping reward → pending earned pack → canonical commit/receipt → real ModalStack ceremony → durable acknowledgement.

Harness-only success is FAIL.

## 1. Reward semantics
- standard/premium reward handlers no longer silently draw into Collection.
- reward grant enqueues exact N stable pending entries.
- duplicate parent tx cannot enqueue duplicates.
- all non-pack resources unchanged.

## 2. Save
- pending queue persisted and strict.
- old absent section -> safe empty migration.
- malformed present section fails closed.
- no secret/test-only state needed.

## 3. Pack transaction
- one pending item -> exactly one draw.
- canonical RNG/pity/Collection only.
- exact 3 Standard / 5 Premium.
- Premium Rare+ guarantee intact.
- durable receipt before presentation model.
- save failure restores pre-open snapshot.
- same tx replay = same receipt, zero draw.
- restart mid-presentation cannot reroll.

## 4. Presenter
- one production PackPresenter/coordinator.
- real ModalStack.
- real Standard/Premium ceremony.
- binds canonical FeedbackAdapter.
- FIFO.
- ack only after presentation_completed.
- pending receipt reopens after restart.
- no gameplay interruption / modal overlap.

## 5. Current production sources
- Gift 10 Standard.
- Gift 250 Standard + exact other rewards.
- Gift 500 Standard + exact other rewards.
- Gift 1000 Premium + guaranteed-new/fallback exact.
- Daily day 2 Standard.
- Daily day 4 Standard.
- Daily day 5 Premium.
- generic future pack reward path.

## 6. F005
- shipping route actually reaches F005 feel.
- no direct plugin calls.
- Reduced zero plugin work.
- no flash/GFF Control use/global Spark.clear.
- current sparkle may remain subtle; visibility tuning is separate owner decision.

## 7. Regression
- F003/F004 accepted Results behavior unchanged.
- Phase1/Phase2 feel suites PASS.
- pack C006/C007/C008/C009 PASS.
- M39/M40/M41 PASS.
- Gift/Daily/Home/modal/navigation PASS.
- set/master/pity PASS.
- root ALL PASS.
- headless import/boot clean.
- git diff --check clean.
- no unexplained errors.

## 8. Runtime evidence
Mandatory REAL production captures:
- Gift claim before;
- claim committed;
- Standard or Premium pack screen opened automatically;
- cards revealed;
- post-completion Collection/card counts.
At least one Standard and one Premium route.

Final state:
- `PASS / AWAITING_OWNER_RUNTIME_ACCEPTANCE`, or
- `CHANGES_REQUIRED`.
