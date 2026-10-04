# M43-C005-C008 — PACK COMMIT TRANSACTION MATRIX V02 (import hardening)

Canonical task: SB-M43-066 · Implementer evidence only (no verdict claimed) · Status: AWAITING_AUDIT

Scope: the single V01 audit defect (absent vs present-empty C008 sections collapsed to `{}`). Everything else in
`PACK_COMMIT_TRANSACTION_MATRIX_V01.md` is retained unchanged and re-proven by the same suite (t01–t26 PASS).

Sources: **E** `scripts/economy/economy_services.gd` (`_apply_sections`), **P** `scripts/collection/card_pack_service.gd`
(`import_snapshot`), **L** `scripts/collection/pack_receipt_ledger.gd` (`import_snapshot`, `empty_snapshot`).
Suite: `tests/m43_c005_c008_pack_commit_transaction.gd`, new case **t27_absent_vs_present**; legacy cases t20, t21, t22.
"M" = source mutation (`CLAUDE_LOG_V02.md` §3).

## Contract

| Economy key | Meaning | Handling |
|---|---|---|
| `packs` absent | pre-C008 save | E skips the import; live OS-seeded RNG kept |
| `packs` present | C008 section | P strict: dictionary with exactly `{rng}`; `rng` exactly `{hi, lo}`, exact ints 0..2^32-1 |
| `pack_receipts` absent | pre-C008 save | E imports `PackReceiptLedger.empty_snapshot()` = `{version:1, receipts:[]}` → empty ledger |
| `pack_receipts` present | C008 section | L strict: dictionary with exactly `{version, receipts}`, version == 1, receipts array of valid unique receipts |

Presence is decided with `has()` in E only; P and L have no legacy branch (they always validate what they are given).

## Criteria

| Criterion | Source | Test / evidence | Result |
|---|---|---|---|
| V01 transaction architecture retained | T/A untouched in V02 | t01–t26 | PASS |
| no ceremony/model/frame change | V02 diff = E, P, L + suite + docs | `git show --stat` | done |
| root TASKS.md untouched; SB-M43-067 not started | V02 diff | — | done |
| `packs` absent accepted | E `s.has("packs")` | t27 (3), t20 | PASS · M16 |
| `pack_receipts` absent accepted | E `empty_snapshot()` | t27 (3), t20 | PASS · M18 |
| old save (both absent) loads | SaveService load path | t20, t27 (4) `source == primary` | PASS · M16, M18 |
| old save then commit + reload | AppState | t20, t27 (4) | PASS |
| present `packs: {}` rejected | P | t27 `packs_empty` (economy, direct, SaveService, load) | PASS · M17, M20 |
| present packs without `rng` rejected | P | t27 `packs_no_rng`, `packs_rng_empty`, direct `{"rng":{"hi":1}}` | PASS · M20 |
| rng wrong shape/type/domain rejected | P | t21 `rng_type`, `rng_range`, `rng_fraction`, `rng_shape`; t27 `packs_extra_key`, `packs_null` | PASS |
| canonical hi/lo accepted | P | t27 direct accept, t15 reload | PASS |
| direct CardPackService import strict | P | t27 (2): 7 malformed values rejected, RNG unchanged | PASS · M20 |
| present `pack_receipts: {}` rejected | L | t27 `ledger_empty` | PASS · M19, M21 |
| ledger missing version / receipts rejected | L | t27 `ledger_no_version`, `ledger_no_receipts` | PASS · M21 |
| wrong version/root/receipt corruption still rejected | L | t21 (25 cases), t27 `ledger_extra_key`, `ledger_null`, direct `version:2` | PASS |
| direct PackReceiptLedger import strict | L | t27 (2): 7 malformed values rejected, ledger unchanged | PASS · M21 |
| SaveService: absent candidate validates | `validate_candidate` | t27 (4) | PASS |
| SaveService: 10 present-malformed candidates fail | `validate_candidate` | t27 (4) 10/10 | PASS · M17, M19 |
| real load never takes a malformed primary as legacy | `AppState.new(path)` | t27 (4) 10/10 (`source != primary`, no receipt) | PASS |
| key-presence-aware branching in E | E | code + M16–M19 | PASS |
| rejected import restores complete prior state | E backup re-import | t27 (1): bad candidates also change wallet (+777 SB) and Collection before the bad C008 section; `_auth` (whole economy + RNG + save bytes) unchanged after each of 10 | PASS |
| direct ledger import all-or-nothing | L | t22 ledger-level, t27 (2) | PASS · M11 |
| no partial RNG/receipt/economy leak | — | t21, t22, t27 | PASS |
| absent/present collapse of `packs` via default `{}` detected | — | M16, M17 | detected |
| absent/present collapse of `pack_receipts` via default `{}` detected | — | M18, M19 | detected |
