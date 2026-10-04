# M43-C005-C008 — SB-M43-066 TARGETED IMPORT HARDENING REMEDIATION V02

Status: **READY FOR CLAUDE**  
Date: 2026-10-04  
Repository: `Sekiph82/Scrubbots`  
Branch: `main`  
Canonical task: **SB-M43-066**  
Expected Claude log: `coordination/sessions/M43-C005-C008/CLAUDE_LOG_V02.md`

Root `TASKS.md` is READ ONLY for Claude. ChatGPT is the sole writer of lifecycle/progress state.

## 0. Audit authority

V01 independent audit result:

`coordination/sessions/M43-C005-C008/CHATGPT_AUDIT_V01.md`

Result: **FAIL — TARGETED IMPORT HARDENING REMEDIATION REQUIRED**

Do not redesign C008. The transaction architecture, receipt schema, rollback design, RNG split, replay semantics and ceremony boundaries are retained.

The single blocking defect is:

> EconomyServices currently collapses “section absent” and “section present but empty/malformed” into the same `{}` input for both `packs` and `pack_receipts`.

Therefore malformed persisted C008 state such as:

`"packs": {}`

or:

`"pack_receipts": {}`

is accepted as if it were a legacy pre-C008 save.

This must be fixed fail-closed while preserving genuine old-save compatibility.

Do not start SB-M43-067.

## 1. FIRST ACTION — DESKTOP/GITHUB SYNC

Before work:

1. Work from `C:\Users\sekip\Desktop\ScrubBots`.
2. `git fetch origin main --prune`.
3. Compare local main / origin/main.
4. Preserve owner-local `project.godot`, `scenes/app/main.tscn`, addons, dirty/untracked work.
5. Synchronize non-destructively.
6. If unsafe, STOP and report exact conflicting paths.

## 2. READ FIRST

Read:
- `CLAUDE.md`
- root `TASKS.md` read only
- `coordination/README.md`
- `coordination/AUDIT_POLICY.md`
- `coordination/sessions/M43-C005-C008/CHATGPT_PROMPT_V01.md`
- `CHATGPT_AUDIT_CRITERIA_V01.md`
- `CHATGPT_AUDIT_V01.md`
- `CLAUDE_LOG_V01.md`
- current C008 production files and focused suite.

## 3. HARD SCOPE LOCK

Authorized production changes only where needed for strict import semantics, expected mainly:
- `scripts/economy/economy_services.gd`;
- `scripts/collection/card_pack_service.gd`;
- `scripts/collection/pack_receipt_ledger.gd`;
- focused C008 tests.

Do not modify:
- Standard/Premium ceremony/model/sequencer;
- Standard/Premium frame assets;
- pack transaction receipt semantics except import strictness;
- root `TASKS.md`;
- SB-M43-067.

## 4. REQUIRED SEMANTICS

### 4.1 Key absent = legacy compatibility

For a snapshot/save whose economy dictionary genuinely does **not** contain `packs`:
- accept as pre-C008;
- keep the live/default OS-seeded pack RNG.

For a snapshot/save whose economy dictionary genuinely does **not** contain `pack_receipts`:
- accept as pre-C008;
- resulting ledger must be empty/default for a fresh load, without corrupting an already-valid live import rollback path.

The presence decision must be made with `has()`, not by `get(key, {})` if that loses absence information.

### 4.2 Key present = strict C008 schema

If `packs` exists:
- it must be a dictionary;
- it must contain the required `rng`;
- `rng` must have exactly canonical `hi` + `lo`;
- missing rng fails;
- empty `packs: {}` fails.

If `pack_receipts` exists:
- it must be a dictionary;
- it must contain canonical `version`;
- it must contain canonical `receipts` array;
- empty `pack_receipts: {}` fails;
- missing version fails;
- missing receipts fails.

Do not treat an explicitly present empty object as a legacy save.

### 4.3 Direct service import contract

Make the direct import methods semantically unambiguous.

Preferred:
- `CardPackService.import_snapshot(present_section)` is strict when called;
- `PackReceiptLedger.import_snapshot(present_section)` is strict when called;
- EconomyServices owns legacy key-absence behavior.

If you choose another design, it must still prove present-empty fails and absent-key succeeds.

## 5. ALL-OR-NOTHING IMPORT

Preserve:
- EconomyServices full backup before import;
- any later failure restores all previously imported sections;
- direct PackReceiptLedger import remains all-or-nothing;
- failed strict packs/ledger import does not leak partial state.

Add cases where earlier economy sections differ before the bad C008 section, proving rollback restores them too.

## 6. SAVE VALIDATION

Using real `SaveService.validate_candidate` / load path prove:

PASS:
- a real old/pre-C008 candidate with both keys absent.

FAIL:
- `economy.packs = {}`;
- `economy.packs = {"rng": {}}`;
- `economy.pack_receipts = {}`;
- `economy.pack_receipts = {"version": 1}`;
- `economy.pack_receipts = {"receipts": []}`.

Also retain all V01 malformed cases.

## 7. FOCUSED TEST EXTENSION

Extend:
`tests/m43_c005_c008_pack_commit_transaction.gd`

At minimum add assertions for:

1. absent both sections -> old save loads;
2. present empty packs -> reject;
3. present packs missing rng -> reject;
4. present empty pack_receipts -> reject;
5. present pack_receipts missing version -> reject;
6. present pack_receipts missing receipts -> reject;
7. direct CardPackService strict import rejects present malformed sections;
8. direct PackReceiptLedger strict import rejects present malformed sections;
9. SaveService candidate validation rejects each;
10. EconomyServices rejected import restores prior live state exactly;
11. old-save compatibility still allows a later C008 commit + reload.

Add mutation sensitivity proving that reintroducing:
`s.get("packs", {})`
or
`s.get("pack_receipts", {})`
legacy-collapse behavior is detected.

## 8. REGRESSION

Run:
- updated C008 focused suite;
- C006 Standard suite + harness;
- C007 Premium suite + harness;
- relevant M39 suites;
- M40 save/load suites;
- M54 exactly-once;
- relevant transaction suites;
- root `tests/run_tests.gd`;
- `git diff --check`.

No unexplained errors.

## 9. EVIDENCE / LOG

Update/create:
- `PACK_COMMIT_TRANSACTION_MATRIX_V02.md`;
- `CLAUDE_LOG_V02.md`.

Record:
- exact production diff;
- absent vs present contract;
- new malformed cases;
- direct-import checks;
- SaveService checks;
- regression results;
- blockers.

Do not edit root `TASKS.md`.

## 10. HANDOFF

Return:
- final SHA;
- exact files changed;
- proof absent legacy keys still load;
- proof present-empty/missing-field sections fail;
- focused/sensitivity/regression/root results.

Finish exactly:

`AWAITING_GPT_M43_C005_C008_V02_IMPORT_HARDENING_AUDIT`
