# M43-C005-C008 — CHATGPT PACK COMMIT V01 INDEPENDENT AUDIT

Date: 2026-10-04  
Canonical task: **SB-M43-066**  
Audited implementation: `19e11a6c1ecfb3f528bb0f27f4cc95a53aa3f036`  
Baseline: `e89b43ae3127dc207fee9f54700286a711224cce`  
Prompt: `CHATGPT_PROMPT_V01.md`  
Audit criteria: `CHATGPT_AUDIT_CRITERIA_V01.md`  
Result: **FAIL — TARGETED IMPORT HARDENING REMEDIATION REQUIRED**

## 1. Independent audit scope

Reviewed:
- C008 prompt and audit criteria;
- Claude V01 log;
- transaction matrix and schema artifact;
- actual implementation commit/diff;
- `PackCommitTransaction`;
- `PackReceiptLedger`;
- `CardPackService` RNG snapshot/import;
- `EconomyServices` snapshot/import integration;
- `AppState` production API;
- focused C008 suite;
- existing save/transaction architecture and accepted C006/C007 ceremony boundaries.

## 2. Scope / governance

PASS.

The Claude implementation commit changes only:
- C008 coordination/evidence artifacts;
- `scripts/app/app_state.gd`;
- `scripts/collection/card_pack_service.gd`;
- new `pack_commit_transaction.gd`;
- new `pack_receipt_ledger.gd`;
- `scripts/economy/economy_services.gd`;
- focused C008 tests.

It does **not** change:
- root `TASKS.md`;
- Standard/Premium ceremony/model/sequencer files;
- Standard/Premium shipping frame assets;
- `SaveService`;
- SB-M43-067 work.

Accepted Standard/Premium visual surfaces therefore remain outside the diff.

## 3. Canonical transaction authority

PASS.

`AppState.commit_pack(kind, tx_id)` delegates to one canonical `PackCommitTransaction.commit()`.

The coordinator correctly:
- validates tx id and kind;
- refuses reentrant commits while the ledger is busy;
- replays a previously committed same-kind receipt without draw/save;
- rejects kind collisions;
- snapshots the complete EconomyServices state;
- calls exactly one Standard/Premium low-level draw/apply path for a new presented pack;
- builds rows from real pre/post Collection truth in draw order;
- records a validated receipt;
- saves before exposing the public receipt/model;
- rolls the economy snapshot back on after-draw / after-ledger / save failure.

The public ledger read APIs hide an in-flight receipt, so the receipt recorded immediately before save cannot leak to presentation before durability succeeds.

## 4. Receipt truth

PASS.

The receipt schema contains:
- schema id;
- tx id;
- equal presentation id;
- pack kind;
- committed status;
- exact 3/5 card rows;
- canonical card id/art/name/rarity;
- strict NEW/DUPLICATE;
- copies-after.

Sequential repeated-card truth is computed from pre-pack ownership and incremented per row rather than reconstructed from only the final count.

Receipt validation delegates card truth to the already-shipping Standard/Premium model validators, including Premium card-0 Rare-or-better.

## 5. RNG persistence / rollback

PASS for the implemented normal and failure paths.

`CardPackService.snapshot()` serializes the 64-bit RNG state into exact 32-bit `hi` / `lo` halves so JSON numeric precision does not destroy the state.

Strict checks exist for:
- root dictionary;
- exact two-key RNG object;
- integer domain;
- unsigned-32 range.

The focused suite records:
- exact RNG rollback on injected transaction faults;
- exact RNG rollback on real SaveService failure paths;
- no RNG advance on replay;
- persisted RNG continuation after reload.

Production still OS-seeds fresh graphs; no fixed production seed was introduced.

## 6. Atomicity / durability

PASS except for the import-hardening defect in section 10 below.

The focused suite materially covers:
- after-draw rollback;
- after-ledger rollback;
- save-stage rollback;
- real SaveService fault points;
- no presentation before successful durable save;
- retry after rollback;
- successful receipt reload;
- same-tx replay after reload;
- Standard/Premium ceremony reopen without authority mutation;
- set + Master completion success exactly once;
- set + Master rollback on forced transaction failure.

The real-save-failure test also reloads from disk and verifies the failed receipt is absent, card counts are pre-commit and RNG is pre-commit.

## 7. Reopen / duplicate / crash windows

PASS.

The focused test proves:
- successful commit can survive without ever presenting;
- a destroyed/reloaded graph returns the same receipt/model;
- opening and closing the Standard ceremony twice from one receipt mutates nothing;
- same for Premium;
- duplicate commit callbacks while a ceremony is open and after close return replay only;
- repeated same tx does not re-save or re-draw;
- same tx after reload remains idempotent.

## 8. Set / Master exactly-once

PASS.

The suite seeds a real near-Master Collection, forces a real pack draw through CardPackService to complete set 6 + Master, and verifies:
- set reward applied;
- Master reward applied;
- wallet delta is exact;
- replay does not re-grant;
- reload + replay does not re-grant;
- later pack does not re-grant;
- after-draw / after-ledger / save fault restores card ownership, set/master claim state, RewardGrant ids and wallet.

This is consistent with preserving the M54 exactly-once authority.

## 9. Reentrancy / existing call graph

PASS.

The in-flight guard is checked before receipt replay, which is important because the receipt is recorded before save.

Nested same-tx and different-tx calls during save are refused as `in_flight`.

The M39 `standard_card_packs` / `premium_card_packs` reward handlers remain grant-and-resolve low-level behavior; C008 documents them and does not pull future pack-inventory/open-entry work forward.

The presentation bridge / ceremonies do not call raw `open_standard()` or `open_premium()`.

## 10. BLOCKING DEFECT — missing section vs present-but-empty malformed section is conflated

**FAIL.**

The prompt and criteria require both:

1. saves from before C008, where the new sections are **absent**, must load successfully;
2. persisted C008 state that is present but malformed must fail closed.

The current integration cannot distinguish those two cases.

### Pack RNG

`EconomyServices._apply_sections()` does:

`packs.import_snapshot(s.get("packs", {}))`

and `CardPackService.import_snapshot()` does:

- if root is a dictionary;
- if it does not contain `"rng"`, return true.

Therefore both of these are accepted identically:

- legacy save with **no `packs` key**;
- malformed new save containing **`"packs": {}`**.

A present C008 `packs` section without the required RNG truth should be malformed persisted state, not silently treated as pre-C008 absence.

### Receipt ledger

`EconomyServices._apply_sections()` also does:

`pack_receipts.import_snapshot(s.get("pack_receipts", {}))`

and `PackReceiptLedger.import_snapshot({})` explicitly clears to an empty ledger and returns true.

Therefore both are accepted identically:

- legacy save with **no `pack_receipts` key**;
- malformed new save containing **`"pack_receipts": {}`**.

That violates the fail-closed import requirement because an explicitly persisted C008 section can lose required `version` / `receipts` structure yet still be accepted as an empty legacy state.

### Why the current focused suite misses it

The malformed-state matrix tests many important corruptions:
- wrong ledger root type;
- wrong version;
- empty/non-string tx;
- duplicate tx;
- kind/count/card/state corruption;
- RNG wrong type/range/fraction/shape;
- wrong packs root type.

But it does **not** test:
- `"packs": {}`;
- `"pack_receipts": {}`;
- a present `packs` object with missing `rng`;
- a present `pack_receipts` object missing `version` or `receipts` as an otherwise empty object.

Because `s.get(key, {})` erases key-presence information, these corruptions pass.

## 11. Required remediation

Keep the production transaction design.

Do **not** rewrite C008.

Target only the absent-vs-present import semantics:

- at the EconomyServices boundary, distinguish **key absent** from **key present**;
- missing `packs` means legacy/pre-C008 and keeps the live OS-seeded RNG;
- present `packs` must strictly require the canonical RNG snapshot;
- missing `pack_receipts` means legacy/pre-C008 and initializes/keeps an empty ledger according to the chosen import contract;
- present `pack_receipts` must strictly require canonical `version + receipts` structure;
- explicit `{}` for either present section must fail;
- partial import must still restore the entire previous live economy state;
- SaveService validation must reject those malformed candidates;
- old pre-C008 save tests must remain PASS.

No ceremony, model, frame asset or visual change is authorized.

## 12. Validation / reported test boundary

Claude records:
- C008 focused suite: **26/26 cases, 79 assertions PASS**, repeated;
- source mutations: **15/15 caught**;
- Standard suite: 21/21;
- Premium suite: 19/19;
- Standard harness: 14/14;
- Premium harness: 11/11;
- M39/M40/M43/M54 regressions: PASS;
- root: **5,323 / 5,323 PASS**;
- `git diff --check`: clean.

Those executions were not independently rerun in the ChatGPT audit environment. I independently inspected the load-bearing production/test source and identified the missing malformed-state case above.

Because the missing case is a direct audit-criteria requirement, the otherwise strong regression result cannot close the task.

## 13. Decision

**FAIL — TARGETED V02 IMPORT HARDENING REMEDIATION REQUIRED**

SB-M43-066 remains OPEN.

No owner visual gate is needed.

Next actor: CLAUDE, using the targeted C008 V02 remediation prompt.

SB-M43-067 remains blocked.
