# M43-C005-C008 — PACK COMMIT TRANSACTION MATRIX V01

Canonical task: SB-M43-066 · Implementer evidence only (no verdict claimed) · Status: AWAITING_AUDIT

Suite: `tests/m43_c005_c008_pack_commit_transaction.gd` (case ids `tNN_*` below; "M" = source mutation in
`CLAUDE_LOG_V01.md` §4). Sources: **T** `scripts/collection/pack_commit_transaction.gd`, **L**
`scripts/collection/pack_receipt_ledger.gd`, **P** `scripts/collection/card_pack_service.gd`, **E**
`scripts/economy/economy_services.gd`, **A** `scripts/app/app_state.gd`.

Result column: PASS = asserted by the final focused run (26/26 cases, 0 fail); M-ids = the mutation that the
suite detected.

## Governance

| Criterion | Source / evidence | Result |
|---|---|---|
| Desktop synced non-destructively | log §Sync (ff-only) | done |
| owner-local files preserved | log §Sync; not staged | done |
| root TASKS.md untouched | `git diff --stat` in log | done |
| SB-M43-067 not started | file list | done |
| no parallel tracker | file list | done |

## Accepted visual preservation

| Criterion | Source / evidence | Result |
|---|---|---|
| Standard / Premium 9 frame bytes unchanged | no `assets/` path in the commit | done |
| Standard / Premium live ceremony behaviour unchanged | no ceremony/model/sequencer source in the commit | done |
| Standard / Premium focused + harness PASS | log §3 V3–V6 | PASS |
| no new owner visual gate needed | nothing visible changed | — |

## Canonical transaction authority

| Criterion | Source | Test | Result |
|---|---|---|---|
| one canonical commit authority | T `commit()`; A `commit_pack()` | t01, t02, t25 (single draw site) | PASS |
| stable caller tx id required | T tx check | t06 | PASS |
| Standard + Premium | T / L `KINDS` | t01, t02 | PASS |
| empty/invalid tx fails closed, zero mutation | T | t06 (`""`, `" tx"`, `"tx "`, `42`, `null`, bad kind) | PASS |
| same tx same kind -> same receipt | T replay branch | t08 (10x), t15, t16/t17 | PASS · M15 |
| same tx other kind fails closed | T `kind_collision` | t07 (both directions) | PASS · M07 |
| reentrant same tx cannot draw twice | T `is_busy()` first; L in-flight | t10, t23 | PASS · M06 |
| no UI/popup owns grant authority | ceremonies/models untouched | t25 static | PASS · M12 |

## Receipt truth

| Criterion | Source | Test | Result |
|---|---|---|---|
| schema / tx / presentation id / kind / status | L `validate_receipt` | t03 | PASS |
| Standard 3 rows / Premium 5 rows | T `_receipt` size check; L | t01, t02, t21 | PASS |
| service draw order preserved | T rows iterate `drawn` | t01, t02 (independent RNG prediction), t26 | PASS · M08 |
| canonical id/art/name/rarity | `CollectionCardCatalog.entry` + `collection.card_rarity` | t03, t21 | PASS |
| strict NEW/DUPLICATE, truthful copies_after | T running counts from pre snapshot, cross-checked with live counts | t04, t05, t26 | PASS · M09 |
| repeated rows increment sequentially | T running counts | t05 (NEW 1, DUP 2; next pack DUP 3) | PASS · M09 |
| Premium card0 Rare+ | `PremiumPackModel.validate` via L | t02, t21, t26 | PASS · M10 |
| maps directly to shipping validators | L `presentation_model` | t09 (validators + ceremonies accept) | PASS |
| data only, cannot grant | L has no service reference | t25 static | PASS |

## Commit-before-presentation gate

| Criterion | Source | Test | Result |
|---|---|---|---|
| draws/applies before release; save before model | T order | t10 (probe inside save sees nothing) | PASS · M05 |
| failed save -> no usable model | T failure return | t10, t11–t14 | PASS · M02 |
| presentation / reopen never call CardPackService | ceremonies unchanged | t16/t17 (`rng` unchanged), t25 | PASS · M12 |
| reopen never mutates Collection/rewards/RNG/save | — | t16/t17 (2 full cycles, `_auth` incl. save bytes) | PASS |

## Atomic rollback

| Criterion | Source | Test | Result |
|---|---|---|---|
| full pre snapshot | T `economy.snapshot()` before draw | t11–t14, t19 | PASS · M13 |
| after-draw / after-ledger / save faults roll back | T fault seam + `import_snapshot(pre)` | t11, t12, t13, t14 (SaveService temp_write / temp_validate / backup_rotate / primary_replace) | PASS · M01 |
| Collection, wallet, applied ids, set/master, RNG, ledger exact | E snapshot covers all incl. `packs` + `pack_receipts` | `_auth` equality in t11–t14, t19 | PASS · M01, M03 |
| no partial receipt / no commit marker | L in-flight cleared; snapshot re-import | t11–t14 retry as fresh commit; t14 reload has no receipt | PASS · M14 |

## RNG

| Criterion | Source | Test | Result |
|---|---|---|---|
| failed commit restores exact RNG | P `snapshot/import_snapshot` (hi/lo u32) | t11–t14, t19 | PASS · M03 |
| duplicate tx / reopen does not advance | T replay branch | t08, t16/t17 | PASS |
| continuation persisted | E `packs` section | t15 (`_rng.state` equal after reload) | PASS · M03 |
| no fixed production seed | A passes `null` rng (OS-seeded); old saves keep live RNG | t25 static + two fresh graphs differ | PASS |
| malformed RNG fails closed | P strict exact-int u32 domain, exact shape | t21 `rng_*`, `packs_root` | PASS |

## Durability / save

| Criterion | Source | Test | Result |
|---|---|---|---|
| ledger in canonical save graph, no second file | E `pack_receipts` section via SaveService | t15, t20 | PASS · M04 |
| survives reload, exact receipt, no duplicate | — | t15 (data + JSON byte equality), t16/t17 crash window A | PASS · M04 |
| pre-C008 save loads, empty ledger | E `s.get(..., {})`, L `{}` | t20 | PASS |
| malformed state rejects; all-or-nothing; live kept | L / E backup re-import | t21 (25 corruptions), t22 (economy + ledger-level) | PASS · M11 |
| SaveService future-schema not weakened | SaveService untouched | M40 suites (log §3) | PASS |

## Duplicate / reopen matrix

| Case | Test | Result |
|---|---|---|
| before presentation | t08 | PASS |
| while presentation open | t16/t17 (commit during AWAIT_ROUTE) | PASS |
| after close | t16/t17 | PASS |
| after reload | t15, t18 | PASS |
| Standard / Premium open-close-reopen, no mutation | t16 / t17 | PASS |
| same content/order every time | t08, t15, t16/t17 | PASS |

## Set / Master side effects

| Criterion | Test | Result |
|---|---|---|
| pack completing set 6 + Master applies real rewards once | t18 (wallet delta == set 6 + master SB) | PASS |
| duplicate tx / reload / later pack never re-grant | t18 | PASS |
| failure rolls set + master back (3 stages) | t19 | PASS · M01 |
| M54 exactly-once suite | log §3 | PASS |

## Existing pack call graph

| Criterion | Evidence | Result |
|---|---|---|
| `standard_card_packs` / `premium_card_packs` handlers audited | log §2 | documented |
| M39 semantics unchanged | handlers byte-unchanged except a comment; M39 suites PASS | PASS |
| SB-M43-098 not pulled forward | no inventory/open-entry code | done |
| one documented API for presentation callers | A `commit_pack`, T header, P LOW-LEVEL note | done |
| raw open not used by presentation bridge | t25 | PASS · M12 |

## Receipt / import hardening (t21 corruption ids)

wrong root `ledger_root`, `packs_root` · bad version `ledger_version` · empty/non-string tx `empty_tx`, `nonstring_tx` ·
duplicate tx `duplicate_tx` · unknown kind `unknown_kind` · wrong count `wrong_count`, `premium_as_3` · unknown card
`unknown_card` · art/name/rarity `art_mismatch`, `name_mismatch`, `rarity_mismatch` · Premium COMMON card0
`premium_card0_common` · NEW type `is_new_type` · copies `copies_invalid` · incoherent repeats `copies_incoherent` ·
tx/presentation `presentation_mismatch` · committed but lacking truth `status_missing`, `schema_wrong`, `cards_missing` ·
RNG `rng_type`, `rng_range`, `rng_fraction`, `rng_shape`. All 25 rejected, live state unchanged after each; SaveService
`validate_candidate` rejects a corrupt receipt; t22 no partial import. **PASS · M10, M11**

## Fault / sensitivity

| Required sensitivity | In-suite | Source mutation |
|---|---|---|
| duplicate application | t26 | M15, M07 |
| presentation before save | t10 | M05 |
| RNG not rolled back | t26 (RNG-only change detected) | M03 |
| dropped receipt on reload | t15 | M04 |
| changed card order | t26 | M08 |
| stale / fabricated copies_after | t26 | M09 |
| Premium COMMON card0 | t21, t26 | M10 |
| partial ledger import | t22 | M11 |
| ceremony raw-open call | t25 | M12 |
