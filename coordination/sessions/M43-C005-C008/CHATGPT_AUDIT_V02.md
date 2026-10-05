# M43-C005-C008 — CHATGPT PACK COMMIT V02 INDEPENDENT AUDIT

Date: 2026-10-05  
Canonical task: **SB-M43-066**  
Audited implementation: `8b3af91614310240f63ad93fc38fc1d05854ae46`  
Baseline: `7920250c2837ba94c0b1fa363291a1ccac619973`  
Prompt: `CHATGPT_PROMPT_V02.md`  
Audit criteria: `CHATGPT_AUDIT_CRITERIA_V02.md`  
Result: **TECHNICAL_AUDIT_PASS / SB-M43-066 CLOSED**

## 1. Independent audit scope

Reviewed:
- V02 remediation prompt and audit criteria;
- V02 Claude log and transaction matrix;
- actual implementation commit/diff;
- `EconomyServices._apply_sections()`;
- `CardPackService.import_snapshot()`;
- `PackReceiptLedger.import_snapshot()`;
- focused C008 suite including new `t27_absent_vs_present`;
- retained V01 transaction architecture and V01 independent audit.

V02 is correctly targeted. The only production changes are the three import surfaces identified by V01. Transaction commit/replay/receipt behavior is not redesigned.

## 2. Scope / visual preservation

PASS.

The V02 implementation commit changes:
- `scripts/economy/economy_services.gd`;
- `scripts/collection/card_pack_service.gd`;
- `scripts/collection/pack_receipt_ledger.gd`;
- the focused C008 test;
- C008 V02 log/matrix.

It does not change:
- Standard/Premium ceremony code;
- Standard/Premium models;
- RevealSequencer;
- Standard/Premium shipping frame assets;
- AppState transaction API;
- PackCommitTransaction;
- receipt schema;
- SaveService;
- root TASKS;
- SB-M43-067.

No owner visual gate is required for this remediation.

## 3. Legacy-key absence contract

PASS.

`EconomyServices._apply_sections()` now preserves key presence information.

For `packs`:
- if the key is absent, `CardPackService.import_snapshot()` is not called;
- therefore a pre-C008 save keeps the fresh graph's live OS-seeded RNG.

For `pack_receipts`:
- if the key is absent, EconomyServices supplies the canonical `PackReceiptLedger.empty_snapshot()`;
- the resulting ledger is cleanly empty for a legacy load.

This is materially different from V01's `s.get(key, {})` behavior and matches the required old-save compatibility contract.

## 4. Present `packs` strictness

PASS.

`CardPackService.import_snapshot()` now requires:
- root dictionary;
- exactly one key;
- required key `rng`;
- `rng` dictionary with exactly `hi` and `lo`;
- exact integer values;
- each half in unsigned 32-bit range.

Therefore:
- `packs: {}` fails;
- missing `rng` fails;
- extra root key fails;
- malformed rng shape/type/domain fails.

The import does not mutate the live RNG until all structural/domain checks have passed.

## 5. Present `pack_receipts` strictness

PASS.

`PackReceiptLedger.import_snapshot()` now requires:
- root dictionary;
- exactly two keys;
- required `version`;
- required `receipts`;
- exact current version;
- receipts array;
- each receipt fully validated;
- no duplicate tx id.

The old direct `{}` = empty-ledger compatibility branch is removed.

Therefore:
- `pack_receipts: {}` fails;
- missing version fails;
- missing receipts fails;
- extra key fails;
- wrong version/root/receipt corruption still fails.

Import remains all-or-nothing because validated receipts are accumulated into temporary structures and only assigned after the complete input succeeds.

## 6. EconomyServices rollback semantics

PASS.

The pre-existing full EconomyServices import transaction remains intact:
- capture live `backup = snapshot()`;
- attempt sections in order;
- on any failure, call `_apply_sections(backup)`.

The new C008 strict sections are late in the import order, so a malformed pack/ledger section may be encountered after wallet/Collection/etc. have already accepted changed values. The backup path restores those earlier mutations.

The new t27 deliberately alters earlier wallet and Collection state before injecting the bad C008 section and requires the entire prior authority snapshot to remain unchanged. This directly tests the failure mode that matters rather than only checking the pack subsection.

## 7. SaveService validation / real load path

PASS.

Because SaveService validates by dry-running EconomyServices import on a scratch graph, the stricter C008 import contract automatically hardens save candidate validation.

The focused suite now proves:
- real legacy candidate with both C008 keys absent validates;
- legacy primary loads as primary;
- legacy load can subsequently commit a Premium pack and reload its receipt;
- present empty/partial `packs` variants fail candidate validation;
- present empty/partial `pack_receipts` variants fail;
- real AppState load never accepts those malformed primaries as valid legacy state.

This closes the exact V01 audit gap.

## 8. Focused test quality

PASS.

New `t27_absent_vs_present` directly covers:
- 10 present-malformed economy section variants;
- full EconomyServices rollback after earlier-section mutation;
- strict direct CardPackService import;
- strict direct PackReceiptLedger import;
- canonical direct imports still accepted;
- both keys absent legacy import;
- SaveService candidate validation;
- real load-path rejection;
- old-save load -> new C008 commit -> reload.

The original V01 cases t01–t26 remain in the suite, preserving coverage for:
- atomic commit;
- durable receipt;
- RNG rollback/persistence;
- no presentation before save;
- duplicate/reopen/reload idempotency;
- set/master exactly-once;
- reentrancy;
- receipt hardening.

## 9. Sensitivity

PASS by recorded evidence and source inspection.

Claude records 21/21 deliberate mutations detected:
- V01's 15 transaction sensitivities re-run;
- six V02 absent/present-collapse sensitivities.

The new mutation set specifically includes:
- restoring `s.get("packs", {})`;
- treating present-empty packs as absent;
- restoring `s.get("pack_receipts", {})`;
- treating present-empty ledger as absent;
- reintroducing lenient pack import;
- reintroducing lenient ledger import.

These are load-bearing for the remediation and are not cosmetic mutation checks.

## 10. Regression boundary

Claude records:
- C008 focused: **27/27 PASS**;
- mutations: **21/21 detected**;
- Standard presentation / harness: **21/21 / 14/14 PASS**;
- Premium presentation / harness: **19/19 / 11/11 PASS**;
- relevant M43: PASS;
- M39: PASS;
- M40 save/load: PASS;
- M54 exactly-once: PASS;
- root: **5,323 / 5,323 PASS**;
- `git diff --check`: clean;
- no final production script errors.

These commands were not independently rerun by ChatGPT in this environment. I independently inspected the exact source changes, focused test logic, mutation target classes and commit boundary. No material criteria gap remains.

## 11. V01 finding reconciliation

The V01 blocking defect was:

> missing legacy sections and explicitly present empty/malformed sections were conflated through default `{}` values.

V02 removes that conflation at the correct architectural boundary:
- EconomyServices decides absence;
- CardPackService strictly validates a present pack section;
- PackReceiptLedger strictly validates a present ledger section.

The defect is closed without weakening backward compatibility.

## 12. Decision

**TECHNICAL_AUDIT_PASS**

**SB-M43-066 is CLOSED.**

No owner visual gate is required because accepted Standard/Premium visual code and assets were unchanged.

The M43-C005 frontier advances to:

**SB-M43-067 — Implement first-new-card celebration and clear duplicate-count presentation.**
