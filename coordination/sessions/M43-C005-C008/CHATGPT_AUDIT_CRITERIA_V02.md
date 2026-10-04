# M43-C005-C008 — CHATGPT AUDIT CRITERIA V02

Canonical task: **SB-M43-066**  
Scope: targeted absent-vs-present C008 import hardening.

## Scope

- [ ] V01 transaction architecture retained.
- [ ] no ceremony/model/frame visual changes.
- [ ] root TASKS.md untouched by Claude.
- [ ] SB-M43-067 not started.

## Legacy absence

- [ ] economy key `packs` absent is accepted as pre-C008.
- [ ] economy key `pack_receipts` absent is accepted as pre-C008.
- [ ] old save with both absent loads successfully.
- [ ] old save can subsequently commit a pack and reload correctly.

## Present packs strictness

- [ ] present `packs: {}` rejected.
- [ ] present packs without `rng` rejected.
- [ ] present rng wrong shape/type/domain rejected.
- [ ] canonical hi/lo accepted.
- [ ] direct CardPackService import is strict for a present section.

## Present ledger strictness

- [ ] present `pack_receipts: {}` rejected.
- [ ] present ledger missing version rejected.
- [ ] present ledger missing receipts rejected.
- [ ] wrong version/root/receipt corruption remains rejected.
- [ ] direct PackReceiptLedger import is strict for a present section.

## SaveService

- [ ] old candidate with keys absent validates/loads.
- [ ] candidate with empty packs fails validation.
- [ ] candidate with packs missing rng fails.
- [ ] candidate with empty pack_receipts fails.
- [ ] candidate with ledger missing version fails.
- [ ] candidate with ledger missing receipts fails.

## Atomic import

- [ ] EconomyServices uses key-presence-aware branching.
- [ ] bad present C008 section cannot be treated as legacy absence.
- [ ] rejected import restores complete previous live state.
- [ ] direct ledger import remains all-or-nothing.
- [ ] no partial RNG/receipt/economy mutation leaks.

## Sensitivity

- [ ] mutation collapsing absent/present packs via default `{}` is detected.
- [ ] mutation collapsing absent/present ledger via default `{}` is detected.

## Regression

- [ ] C008 focused suite PASS.
- [ ] C006 Standard suite PASS.
- [ ] C007 Premium suite PASS.
- [ ] both owner-review harness smokes PASS.
- [ ] M39 regressions PASS.
- [ ] M40 save/load regressions PASS.
- [ ] M54 exactly-once PASS.
- [ ] transaction regressions PASS.
- [ ] root suite PASS.
- [ ] git diff --check clean.
- [ ] no unexplained errors.

## Evidence / handoff

- [ ] PACK_COMMIT_TRANSACTION_MATRIX_V02.md exists.
- [ ] CLAUDE_LOG_V02.md exists.
- [ ] final SHA reported.
- [ ] handoff ends AWAITING_GPT_M43_C005_C008_V02_IMPORT_HARDENING_AUDIT.

## Closure

On V02 PASS, **SB-M43-066 closes technically with no owner visual gate**, provided accepted Standard/Premium visual files and behavior remain unchanged.
