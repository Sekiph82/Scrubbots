# M43-C005-C008 — CLAUDE LOG V01 — Atomic Pack Commit / Presentation Transaction

Date: 2026-10-04
Implementer: Claude (Opus 5.5)
Canonical task: SB-M43-066
Status: **AWAITING_AUDIT** (implementer evidence only; no verdict claimed)

## Inputs read

- Prompt: https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M43-C005-C008/CHATGPT_PROMPT_V01.md
- Criteria: https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M43-C005-C008/CHATGPT_AUDIT_CRITERIA_V01.md
- `CLAUDE.md`, root `TASKS.md` (read only, not edited), `coordination/AUDIT_POLICY.md`,
  `coordination/OWNER_ECONOMY_REWARDS_V01.md`, `data/config/economy_rewards_v1.json`
- `economy_services.gd`, `card_pack_service.gd`, `collection_inventory.gd`, `collection_card_catalog.gd`,
  `reward_grant_service.gd`, `first_clear_transaction.gd`, `save_service.gd`, `app_state.gd`, `int_domain.gd`
- Accepted Standard / Premium ceremony + model sources and suites (C006 / C007)

## Sync

`git fetch origin main --prune` → local `main` behind `origin/main`; `git merge --ff-only origin/main` fast-forwarded to
`e89b43a` (0 ahead / 0 behind afterwards). Owner/local work preserved and never staged: `M project.godot`,
`M scenes/app/main.tscn`, `addons/`, `.mcp.json`, untracked owner art / `.import` / `.uid` files.

## 1. Changes

| File | Change |
|---|---|
| `scripts/collection/pack_commit_transaction.gd` | **new** — THE canonical pack commit authority (static `commit`, read-only `receipt` / `presentation_model`) |
| `scripts/collection/pack_receipt_ledger.gd` | **new** — durable receipt ledger: strict receipt validation (delegates card truth to the shipping Standard/Premium model validators), the only receipt → presentation-model bridge, all-or-nothing snapshot import, in-flight guard |
| `scripts/collection/card_pack_service.gd` | RNG `snapshot()` / strict `import_snapshot()` (`{rng:{hi,lo}}`, two exact-int u32 halves — JSON numbers are doubles); LOW-LEVEL AUTHORITY header note. Draw logic unchanged |
| `scripts/economy/economy_services.gd` | `pack_receipts` ledger in the graph; snapshot/import sections `packs` + `pack_receipts` (missing → live RNG / empty ledger); comment on the two pack reward handlers (code unchanged) |
| `scripts/app/app_state.gd` | `commit_pack(kind, tx_id)` (blocked-aware, saves via `request_save`), `pack_receipt(tx_id)`, `pack_presentation_model(tx_id)` |
| `tests/m43_c005_c008_pack_commit_transaction.gd` | **new** focused suite (26 cases) |
| `M43-C005-C008/PACK_COMMIT_TRANSACTION_MATRIX_V01.md`, `PACK_COMMIT_SCHEMA_V01.json`, this log | evidence |

Not changed: Standard / Premium ceremonies, models, sequencer, frames, SaveService, CollectionInventory,
RewardGrantService, FirstClearTransaction, M39 reward handler code, root `TASKS.md`.

### Canonical API

```
AppState.commit_pack("standard" | "premium", tx_id) -> {ok, replay, receipt, model}
                                                     | {ok:false, reason[, stage, restored]}
AppState.pack_receipt(tx_id) / AppState.pack_presentation_model(tx_id)   # read-only, {} when none
PackCommitTransaction.commit(economy, kind, tx_id, save: Callable, fault: Callable = Callable())
```

Order for a new tx id: tx/kind validation → in-flight guard → replay / kind-collision check → `economy.snapshot()`
(entire EconomyServices graph incl. wallet, RewardGrant applied ids, Collection + set/master claims, pack RNG, ledger)
→ ONE `open_standard()` / `open_premium()` (Collection apply + set/master rewards happen inside, as today) → receipt
from the pre-commit counts in service draw order, cross-checked against live post-apply counts → ledger record →
canonical save → release `{receipt, model}`. Any failure → `economy.import_snapshot(pre)`, in-flight cleared,
`{ok:false, reason:"rolled_back", stage, restored}`, no model. Reasons: `tx_id`, `kind`, `in_flight`,
`kind_collision`, `no_save`, `app_blocked`, `rolled_back` (stages `after_draw`, `receipt`, `ledger`, `after_ledger`,
`save`). `fault` is the test-only seam; production passes none.

Reentrancy: `is_busy()` is checked before the replay lookup, and the ledger's public reads hide the in-flight tx, so a
callback inside the save can neither draw again nor obtain the recorded-but-unsaved receipt.

## 2. Existing pack grant call graph (audited, unchanged)

- `CardPackService.open_standard()` / `open_premium()` callers: **only** the EconomyServices reward handlers
  `standard_card_packs` and `premium_card_packs` (loop n times, draw + apply immediately, no presentation, no receipt),
  reached through `RewardGrantService.grant()` for bundles that contain those keys (gift-meter milestones, daily
  rewards, tasks as configured in `economy_rewards_v1.json`) — and now `PackCommitTransaction.commit()`.
- `grant_guaranteed_new()` caller: the `guaranteed_new_cards` handler (500 SB fallback). Unchanged.
- These M39 grant-and-resolve semantics are kept byte-identical (only a comment added). The future pack inventory /
  open-entry (SB-M43-098) is not started. Every PRESENTED opening must call `AppState.commit_pack`; the raw opens are
  marked low-level in `card_pack_service.gd` and t25 proves the ceremonies/models/ledger bridge never call the service.

## 3. Validation

All `godot --headless --path . -s res://tests/<suite>.gd`; exit 0 and 0 `SCRIPT ERROR` lines in every final run.

| # | Suite | Result |
|---|---|---|
| V1 | `m43_c005_c008_pack_commit_transaction` (new) | **PASS 26/26 cases, 79 assertions, 0 fail** (×3 final runs) |
| V2 | mutation sensitivity (§4) | **15/15 detected**, sources restored |
| V3 | `m43_c005_c006_standard_pack_presentation` | PASS 21/21 |
| V4 | `m43_c005_c007_premium_pack_presentation` | PASS 19/19 |
| V5 | `m43_c005_c006_owner_review_harness` (Standard) | PASS 14/14 |
| V6 | `m43_c005_c007_premium_owner_review_harness` | PASS 11/11 |
| V7 | `m43_c005_c005_reward_reveal_sequencer`, `m43_c005_c001_ceremony_visual_masters` | PASS 12/12, 17/17 |
| V8 | M43 `c002_c001_popup_modal_pause`, `c003_c001_acquisition`, `c004_c001_fail_need_a_hand`, `c001a`, `c001b`, `c001r_c001` | PASS 23/23, 34/34, 40/40, 11/11, 11/11, 40/40 |
| V9 | M39 `m39a`–`m39e`, `m39_v02_atomicity/capacity/integration`, `m39_v03_full_surface/integration`, `m39_v04_integration/tornado_inflight` (CardPack / Collection / RewardGrant / FirstClear transaction coverage) | all PASS |
| V10 | M40 `m40_save_system`, `m40_v02_safety`, `m40_v03_canonical`, `m40_v04_bootstrap` | all PASS |
| V11 | `m54_collection_set_master_exactly_once` | PASS |
| V12 | root `run_tests.gd` | **5,323 checks, ALL PASS** |
| V13 | `git diff --check` | clean |

Exit-time "ObjectDB instances leaked / resources still in use" lines are the AppState economy graphs (reward-handler
lambda cycles, M55-C001 note) created by AppState-based suites; present before C008 too.

Proof highlights:
- **RNG**: failed commits leave `packs._rng.state` == pre (t11–t14, t19 via `_auth`); replay ×10 and two full ceremony
  cycles leave it unchanged (t08, t16/t17); reload continues from the persisted state (t15); malformed RNG rejected
  (t21); production graphs OS-seeded (t25).
- **Duplicate / reopen / reload**: same tx before presentation, while the ceremony is open, after close and after
  reload all return the identical receipt with `replay:true` and zero authority change incl. save bytes (t08, t15,
  t16/t17, t18). Crash window A: commit → drop graph → reload → same model, Collection holds exactly one commit → present
  twice (t16/t17).
- **Faults**: `after_draw`, `after_ledger`, `save` seam and real SaveService `temp_write` / `temp_validate` /
  `backup_rotate` / `primary_replace` failures each roll back Collection, wallet, applied ids, set/master, RNG and
  ledger exactly; no model; reload shows no receipt; retry is a fresh commit (t11–t14). (`primary_replace` leaves the
  previous primary in `.bak` per M40 design — the reload loads that pre-commit state.)
- **Set / Master**: near-master profile built through real `add_card` (14/15 sets); a forced pack drawing `s6_c8`
  completes set 6 + Master, wallet +set-6 SB + master SB once; replay, reload + replay and a later pack never re-grant
  (t18); each fault stage restores card, both rewards, applied ids and wallet (t19).

## 4. Mutation sensitivity

Each mutation was applied temporarily to production source (single-occurrence replace), the focused suite run, and the
file restored from a copy; `cmp` against pre-run references confirmed all five touched files RESTORED byte-identical.

| # | Mutation | Suite result | Detecting assertions (examples) |
|---|---|---|---|
| M01 | rollback removed (`restored = true`, no re-import) | FAIL, 13 | t10 failed save, t11/t12/t13 `_auth == pre`, retry |
| M02 | save failure treated as success | FAIL, 5 | t10, t14 temp_write/temp_validate/backup_rotate (`collection, packs, pack_receipts, rng` differ) |
| M03 | RNG import is a no-op (not restored / not persisted) | FAIL, 15 | t11–t14 rng diff, t15 continuation |
| M04 | `pack_receipts` dropped from the snapshot (receipt lost on reload) | FAIL, 9 | t15 receipt/model/byte equality, t16 crash window A |
| M05 | ledger reveals the in-flight receipt (presentation before save) | FAIL, 1 | t10 probe inside save |
| M06 | in-flight guard removed | FAIL, 2 | t10, t23 re-entrant draw |
| M07 | kind collision falls through to replay | FAIL, 2 | t07 both directions |
| M08 | rows reversed (order changed) | FAIL, 10 | t01/t02 service order, t04, t05 |
| M09 | copies_after from final owned count | FAIL (t05 aborted) | t05 sequential repeat rows |
| M10 | Premium validator skipped (card0 COMMON) | FAIL, 3 | t21 `premium_card0_common`, t26 |
| M11 | ledger import mutates live dict (partial import) | FAIL, 4 | t22, t10/t12/t13 retry |
| M12 | raw `open_standard()` call injected into the ceremony | FAIL, 1 | t25 static guard |
| M13 | pre snapshot taken after the draw | FAIL, 30 | t01…, t07, t11–t14 |
| M14 | in-flight not cleared on failure | FAIL, 3 | t11/t12/t13 retry |
| M15 | replay branch removed (same tx draws again) | FAIL, 4 | t07, t08 10x replay, t15–t17 |

**15/15 detected.** In-suite comparator sensitivity (t25/t26): duplicate application, RNG-only change, reordered
rows, fabricated copies_after, Premium COMMON card 0 and an injected raw open are each flagged.

## 5. Scope / blockers

- SB-M43-067 not started. Root `TASKS.md` untouched. No tracker created. No visual change → no owner visual gate.
- Known limit (ponytail note in the ledger): one receipt per presented pack is kept forever; compact if save size
  ever matters.
- Blockers: none.

## 6. Commit / push

See handoff response for the final SHA.

`AWAITING_GPT_M43_C005_C008_V01_PACK_COMMIT_AUDIT`
