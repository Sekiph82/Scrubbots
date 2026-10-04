# M43-C005-C008 — SB-M43-066 PACK COMMIT / ATOMIC PRESENTATION TRANSACTION V01

Status: **READY FOR CLAUDE**  
Date: 2026-10-04  
Repository: `Sekiph82/Scrubbots`  
Branch: `main`  
Canonical task: **SB-M43-066**  
Expected Claude log: `coordination/sessions/M43-C005-C008/CLAUDE_LOG_V01.md`

Root `TASKS.md` is **READ ONLY for Claude**. ChatGPT is the sole writer of lifecycle/progress state.

## 0. Goal

Implement the canonical transaction boundary required by:

> **SB-M43-066 — Pack contents are committed before/atomically with presentation and reopening the reveal never duplicates cards.**

The already owner-accepted Standard and Premium ceremonies are **presentation-only** and must remain so.

This task must establish one production authority that turns a requested Standard/Premium pack opening into a **durable committed receipt** first. Only that committed receipt may then be converted into the existing Standard/Premium presentation models.

The law is:

**request with stable tx id**  
→ validate/preflight  
→ snapshot exact authoritative state  
→ draw contents once  
→ apply cards/rewards once  
→ build immutable receipt from actual before/after truth  
→ persist receipt + committed state successfully  
→ only then expose presentation model  
→ any reopen/re-entry uses the same receipt and never draws/grants again.

If any commit/save stage fails:

**no presentation model is released and the full authoritative state, including pack RNG/ledger, is restored.**

Do not start SB-M43-067.

## 1. FIRST ACTION — DESKTOP/GITHUB SYNC

Before reading implementation sources or changing files:

1. Work from exactly `C:\Users\sekip\Desktop\ScrubBots`.
2. Run `git fetch origin main --prune`.
3. Compare local `main` and `origin/main`.
4. Preserve owner-local `project.godot`, `scenes/app/main.tscn`, addons, dirty files and unrelated untracked work.
5. Synchronize Desktop with latest `origin/main` **non-destructively**.
6. If synchronization cannot be completed safely, STOP and report exact conflicting paths.
7. Only then begin.

No destructive reset, clean, checkout-overwrite, owner-file deletion or force-push.

## 2. READ FIRST

Read at minimum:

- `CLAUDE.md`
- root `TASKS.md` read only
- `coordination/README.md`
- `coordination/AUDIT_POLICY.md`
- `coordination/sessions/M43-C005-C006/OWNER_VISUAL_ACCEPTANCE_V03.md`
- `coordination/sessions/M43-C005-C007/OWNER_VISUAL_ACCEPTANCE_V01.md`
- `coordination/sessions/M43-C005-C007/CHATGPT_AUDIT_V01.md`
- `scripts/collection/card_pack_service.gd`
- `scripts/collection/collection_inventory.gd`
- `scripts/collection/collection_card_catalog.gd`
- `scripts/economy/economy_services.gd`
- `scripts/economy/reward_grant_service.gd`
- `scripts/economy/first_clear_transaction.gd`
- `scripts/app/app_state.gd`
- `scripts/save/save_service.gd`
- `scripts/ui/ceremony/standard_pack_model.gd`
- `scripts/ui/ceremony/premium_pack_model.gd`
- `scripts/ui/ceremony/standard_pack_ceremony.gd`
- `scripts/ui/ceremony/premium_pack_ceremony.gd`
- relevant M39/M40/M43/M54 tests.

Before coding, document the current pack-open call graph, including the reward-resource handlers in `EconomyServices`. Do not guess which existing calls mean “earn a pack” versus “present/open a committed pack”.

## 3. OWNER-ACCEPTED CEREMONIES ARE FROZEN

SB-M43-064 and SB-M43-065 are CLOSED by owner visual acceptance.

Do not visually redesign either ceremony.

Hard preservation:
- Standard shipping 9 frame bytes unchanged.
- Premium shipping 9 frame bytes unchanged.
- Standard live two-tap behavior unchanged.
- Premium live two-tap behavior unchanged.
- Standard 3-card layout unchanged.
- Premium 3+2 layout unchanged.
- destination semantics unchanged.
- Reduced Effects semantics unchanged.

If a tiny integration API is required, it may be added only if existing ceremony focused suites + review-harness smokes prove exact behavior parity.

No new visual owner gate is required for C008 unless you actually change visible ceremony behavior. Prefer **zero visual changes**.

## 4. CANONICAL COMMIT AUTHORITY

Create one canonical pack-open commit coordinator/service in the existing collection/economy architecture. Choose the exact filename after inspecting conventions; do not create a competing economy graph.

It must support at least:

- Standard
- Premium

with a stable, caller-supplied **transaction id**.

Suggested semantic API (names may differ if architecture has a better convention):

`commit_standard(tx_id)`  
`commit_premium(tx_id)`  
`receipt(tx_id)` / `presentation_model(tx_id)`

### Required behavior

For a new tx id:
- validate tx id;
- snapshot all state needed for exact rollback;
- draw exactly once from canonical CardPackService;
- apply exactly once to canonical CollectionInventory;
- preserve set/master reward side effects produced by CollectionInventory;
- derive a receipt from real before/after truth;
- durably persist the committed transaction;
- only after successful persistence return a presentation-ready result.

For an already committed tx id:
- do not draw;
- do not advance RNG;
- do not add cards;
- do not grant set/master rewards;
- do not save a second economic commit unnecessarily;
- return the previously committed receipt/model deterministically.

A tx id already committed as Standard cannot be reused as Premium, and vice versa. Kind collision must fail closed without mutation.

Empty/invalid tx id fails closed without mutation.

## 5. DURABLE RECEIPT CONTRACT

The receipt must be data-only, canonical, validation-friendly and persistable.

At minimum include:

- schema/version identifier;
- stable tx id;
- stable presentation id derived from or equal to the tx id;
- kind: `standard` or `premium`;
- committed card rows in exact service draw order;
- for every row:
  - card id;
  - canonical art;
  - canonical name;
  - canonical rarity;
  - `is_new`;
  - `copies_after`;
- commit status / committed marker sufficient to distinguish a real committed receipt from a request.

The receipt must satisfy the already-shipping model validators without inventing UI truth.

### Sequential duplicate truth

If the same card is drawn multiple times inside one pack:
- rows remain in service order;
- `copies_after` increments for each occurrence;
- only the first occurrence may be NEW, and only when the pre-pack owned count was zero.

Example from zero copies:
- first repeated row: NEW, copies_after 1;
- second: DUPLICATE, copies_after 2;
- third: DUPLICATE, copies_after 3.

Do not derive all rows from only the final owned count.

### Premium truth

Premium receipt:
- exactly 5 rows;
- card 0 remains the CardPackService guaranteed Rare-or-better draw;
- no sorting/reordering.

Standard:
- exactly 3 rows.

## 6. DURABILITY / SAVE BOUNDARY

A committed receipt that is exposed for presentation must survive process/app reload.

The durable pack-transaction state must be part of the **canonical save graph**, not a UI cache, test singleton or transient popup state.

Integrate it with the existing:
- `EconomyServices.snapshot()/import_snapshot()`;
- `SaveService`;
- `AppState` canonical save boundary;

using the smallest architecture-consistent change.

### Backward compatibility

Existing valid saves that predate C008 and therefore have no pack-transaction section must still load successfully with an empty/default transaction ledger.

Malformed new pack-transaction state must fail closed under save/economy import rules. Do not silently coerce corrupt receipts.

Do not create a second save file.

Do not use `ConfigFile`, ad-hoc JSON, metadata files, or UI persistence as an alternate authority.

## 7. ATOMICITY / FULL ROLLBACK

A new pack commit is not successful unless the durable save succeeds.

Before mutating, capture enough state to restore **exactly**:
- Collection inventory;
- any wallet/reward state changed by set/master completion;
- RewardGrant applied transaction ids;
- any other EconomyServices section touched by the pack;
- pack RNG state;
- pack transaction ledger/receipt state.

On failure at any post-mutation stage:
- restore full economy state exactly;
- restore RNG exactly;
- restore transaction ledger exactly;
- do not expose presentation model;
- do not leave a partial receipt;
- do not leave newly completed set/master rewards;
- do not leave an applied reward tx id;
- do not write a successful commit marker.

Use the existing `FirstClearTransaction` snapshot/rollback philosophy rather than inventing partial compensating mutations.

### Fault injection

Provide a test-only fault seam so tests can force failure:
- after draw/apply;
- after receipt creation/ledger mutation but before save;
- on save failure.

The production path must not depend on fault injection.

## 8. RNG TRUTH

Current CardPackService owns/injects a RandomNumberGenerator, but the existing EconomyServices snapshot does not currently persist pack RNG.

C008 must explicitly resolve this gap for atomic pack commits.

Required:
- a failed commit restores RNG to the exact pre-transaction state;
- duplicate/reopen by the same tx id does not advance RNG;
- successful durable state has a canonical RNG continuation appropriate to the architecture;
- reload/reopen does not reroll the committed receipt.

If you persist RNG state, validate its type/domain strictly.

Do not seed production with a fixed test seed.

## 9. PRESENTATION RELEASE GATE

The transaction layer must be the only new bridge that converts committed pack truth into the existing presentation model.

A newly requested commit must return no usable presentation model until durable commit/save succeeds.

After success:
- Standard receipt converts to a model accepted by `StandardPackModel.validate()`;
- Premium receipt converts to a model accepted by `PremiumPackModel.validate()`.

Reopening/recreating the ceremony from that receipt:
- may happen repeatedly;
- never calls CardPackService again;
- never mutates Collection;
- never mutates rewards;
- never advances RNG;
- never saves another grant.

The ceremony remains presentation-only.

## 10. RELOAD / CRASH-WINDOW CONTRACT

Simulate the important crash windows.

### A. Success before presentation

1. Commit a pack successfully.
2. Do **not** open the ceremony.
3. Destroy the app/service graph.
4. Reload from canonical save.
5. Retrieve the exact same receipt/model.
6. Open the ceremony.
7. Collection counts must equal one commit only.

### B. Reopen after presentation

1. Commit successfully.
2. Run/close the ceremony.
3. Recreate ceremony from the same receipt.
4. Run/close it again.
5. No card count/reward/RNG/save mutation from either presentation.

### C. Save failure

1. Start new pack commit.
2. Draw/apply occurs.
3. Save fails.
4. Transaction returns failure and no presentation.
5. Full economy + RNG + ledger equals pre-transaction state.
6. Retry may proceed as a fresh commit.

### D. Duplicate callback / same tx id

Call commit for the same tx id repeatedly:
- before opening presentation;
- while a presentation instance is open;
- after it closes;
- after app reload.

All calls resolve to the same committed receipt with no duplicate cards.

## 11. EXISTING PACK GRANT CALL GRAPH

Audit the existing `EconomyServices` handlers for:
- `standard_card_packs`;
- `premium_card_packs`.

Do **not** casually change M39 reward semantics.

C008 is not SB-M43-098 pack-inventory/open-entry work.

If those handlers currently mean “grant and immediately resolve pack contents”, preserve their tested behavior unless the new canonical commit boundary can replace it without changing reward semantics.

However:
- do not allow a future presentation path to call raw `open_standard()` / `open_premium()` and then separately build UI;
- document the canonical C008 transaction API future presentation callers must use.

If legacy low-level `open_standard/open_premium` remain public for compatibility, clearly mark them as low-level/internal authority and prove C008's presentation bridge does not bypass the canonical transaction.

## 12. SET / MASTER SIDE EFFECT TRUTH

CollectionInventory may trigger:
- set 9/9 reward;
- Master Collection reward.

Those are part of the pack commit and therefore part of atomicity.

Tests must prove:
- on successful pack commit, any legitimately triggered set/master reward occurs once;
- duplicate tx/reopen does not trigger it again;
- forced failure after card apply rolls back both card ownership and those reward effects;
- reload preserves exactly-once behavior.

Use real CollectionInventory + RewardGrantService where practical. A narrowly-scoped deterministic test seam is allowed to force a draw needed to hit a completion boundary, but production must still use real CardPackService draw authority.

Do not weaken M54 exactly-once behavior.

## 13. RECEIPT VALIDATION / IMPORT HARDENING

Persisted receipt/ledger import must reject at minimum:
- wrong root type;
- empty/non-string tx id;
- duplicate tx ids where representation permits duplicates;
- unknown pack kind;
- wrong 3/5 row count;
- unknown card id;
- art/name/rarity mismatch;
- Premium COMMON card 0;
- invalid NEW/DUPLICATE type;
- invalid copies_after;
- incoherent repeated-card increments;
- tx/presentation id mismatch if your schema derives one from the other;
- malformed RNG state;
- a receipt marked committed but lacking required truth.

Import must be all-or-nothing.

A corrupted ledger must not partially replace live valid state.

## 14. CONCURRENCY / REENTRANCY

Godot is single-threaded here, but duplicate signals/callbacks can occur.

Protect against:
- two calls with the same tx id in the same frame;
- callback re-entry during save;
- repeated route/open requests.

One tx id can produce at most one committed content set.

If the coordinator is already committing tx X, a reentrant X must not initiate a second draw.

Different tx ids may execute sequentially through the canonical authority.

No async/background promise is needed.

## 15. TEST SUITE

Create a focused suite, e.g.:

`tests/m43_c005_c008_pack_commit_transaction.gd`

Cover at minimum:

1. Standard new commit = exactly 3 rows.
2. Premium new commit = exactly 5 rows, card0 Rare+.
3. receipt/model order equals actual CardPackService service order.
4. canonical art/name/rarity.
5. correct NEW/DUPLICATE + copies_after.
6. repeated card rows increment sequentially.
7. empty tx rejected with zero mutation/RNG change.
8. kind collision rejected with zero mutation.
9. first successful commit mutates Collection exactly once.
10. same tx repeated 10x returns same receipt, no further mutation.
11. same tx does not advance RNG after first commit.
12. Standard model validator accepts receipt model.
13. Premium model validator accepts receipt model.
14. no presentation released before successful save.
15. forced after-draw failure rolls back.
16. forced after-ledger failure rolls back.
17. save failure rolls back.
18. rollback restores wallet/reward/set/master state.
19. rollback restores exact RNG state.
20. rollback removes partial ledger.
21. successful commit survives real SaveService reload.
22. reload receipt byte/data equality.
23. reload + duplicate tx gives same receipt, no card duplication.
24. ceremony open/close/reopen from same Standard receipt changes no authority.
25. ceremony open/close/reopen from same Premium receipt changes no authority.
26. presentation reopening does not save/regrant.
27. set-completion triggered by a successful pack grants exactly once.
28. same set completion rolls back on forced failure.
29. master-completion edge remains exactly once if exercised.
30. old save without C008 section loads with empty ledger.
31. malformed C008 ledger fails closed.
32. failed import leaves prior live state unchanged.
33. reentrant same-tx sensitivity cannot draw twice.
34. two different tx ids commit sequentially and independently.

### Sensitivity

Deliberately prove the suite catches:
- duplicate application of same tx;
- presentation before save success;
- RNG not restored on failure;
- dropped receipt on reload;
- changed card order;
- stale/fabricated copies_after;
- Premium card0 COMMON;
- partial ledger import;
- ceremony path calling raw open again.

## 16. REGRESSION

Run at minimum:

- new C008 focused suite;
- Standard Pack C006 focused suite;
- Premium Pack C007 focused suite;
- Standard owner-review harness smoke;
- Premium owner-review harness smoke;
- M39 collection/card-pack suites;
- M40 save/load suites;
- M54 collection set/master exactly-once suite;
- relevant RewardGrant / FirstClear transaction suites;
- relevant M43 ceremony/modal suites;
- root `tests/run_tests.gd`;
- `git diff --check`.

No unexplained script/runtime errors.

## 17. EVIDENCE / COORDINATION

Create:

- `coordination/sessions/M43-C005-C008/PACK_COMMIT_TRANSACTION_MATRIX_V01.md`
- `coordination/sessions/M43-C005-C008/PACK_COMMIT_SCHEMA_V01.json` or a similarly precise machine-readable schema/example artifact;
- `coordination/sessions/M43-C005-C008/CLAUDE_LOG_V01.md`

The matrix must map every audit criterion to:
- production source;
- focused test case;
- evidence/result.

Do not create a second roadmap/tracker.

Do not edit root `TASKS.md`.

## 18. HANDOFF

Return:
- final SHA;
- exact production files changed;
- chosen canonical transaction API;
- receipt schema summary;
- save/snapshot integration summary;
- RNG rollback/persistence proof;
- duplicate/reopen/reload proof;
- fault-injection results;
- set/master rollback/exactly-once proof;
- focused/regression/root results;
- blockers.

If technical PASS is achieved, C008 is primarily a non-visual transaction task and may close by independent ChatGPT audit without another owner visual gate, provided accepted Standard/Premium visuals remain unchanged.

Do not start SB-M43-067.

Finish exactly:

`AWAITING_GPT_M43_C005_C008_V01_PACK_COMMIT_AUDIT`
