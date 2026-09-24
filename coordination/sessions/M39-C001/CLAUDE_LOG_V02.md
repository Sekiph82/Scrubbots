# M39-C001 V02 — Claude Full Integration & Atomicity Remediation Log

V01 audit: `coordination/sessions/M39-C001/CHATGPT_AUDIT_V01.md`
(`CHANGES_REQUIRED / FINDING_SET_FROZEN`, F-M39-001..010)
V02 prompt: `coordination/sessions/M39-C001/CHATGPT_PROMPT_V02.md`
V02 criteria: `coordination/sessions/M39-C001/CHATGPT_AUDIT_CRITERIA_V02.md`

## Finding-by-finding closure

| Finding | Status | Real integration |
|---------|--------|------------------|
| F-M39-001 live M24 5/6 | CLOSED | `five_slot_batch_engine.gd` is now capacity-aware: `grow_to_sixth()` (5->6, once), `active_capacity()`, all placement/full/rightmost-empty queries honor `_slots.size()`; `reset()` returns to five. Baseline five-slot behavior byte-identical when capacity=5 (root suite 5336/0). Wired live via `ProductionGameplayHost.activate_plus_one_slot()`. |
| F-M39-002 M27 capacity | CLOSED | `proof_state.gd` carries `capacity`, `from_runtime` reads the engine's live slot count, and `canonical_key()` appends `C<capacity>` so a 5-slot and 6-slot state with otherwise-equal data never collapse. |
| F-M39-003 concrete booster adapter | CLOSED (Tornado quiescence-scoped) | `production_booster_adapter.gd` drives the REAL BoardState/supply/slots/scheduler + DeadlockClassifier. Random reorders real remaining supply (conservation) with real solver-safety + reload rollback; Selector reorders-to-front + real `select_front_batch` into the real rightmost-empty slot (5/6) with reload rollback; Tornado purges a color atomically across real BoardState + supply + idle slots with per-stage rollback + fault injection, requiring quiescence (no in-flight M26 work) so no live M25 claim/M26 agent is stranded. |
| F-M39-004 manual 2x gate | CLOSED | `ProductionGameplayHost._on_speed_pressed` consults `SpeedEntitlementService`: turning 2x ON requires a valid current-level/timed entitlement; OFF always allowed; free M23-exhausted auto-2x uses the speed authority directly and stays free. |
| F-M39-005 aggregate import atomic | CLOSED | `EconomyServices.import_snapshot` captures the exact live snapshot, applies sections, and rolls back to it on any section failure — independent of SaveService. |
| F-M39-006 integer domain | CLOSED | `int_domain.gd` (`exact_int`/`nonneg_int`) applied to wallet, boosters, hearts, speed, gift, daily, collection, progression, win-streak imports: fractional/NaN/INF/non-numeric fail closed. |
| F-M39-007 cards exchange atomic | CLOSED | `CardsExchangeService` removes copies FIRST (gated), then credits; a credit failure rolls the removal back (`CollectionInventory.add_copies`). Per-card and exchange-all both all-or-nothing. |
| F-M39-008 daily task persistence | CLOSED | `DailyService.snapshot/import` now persist current-day `tasks_done` + `tasks_claimed_day`; relaunch restores task completion; tx ids still prevent double-grant. |
| F-M39-009 collection canonical | CLOSED | `CollectionInventory.import_snapshot` rejects unknown card ids, invalid set ids (1..15), fractional/negative counts, non-bool master; all-or-nothing. |
| F-M39-010 runtime economy wiring | CLOSED | `ProductionGameplayHost` owns the canonical `EconomyServices` + `LevelProgressionService`; the authoritative M30 terminal drives first-clear reward + Win Streak + progression advance + current-level entitlement clear on WON, and Heart consume + streak reset on LOST; boosters act through the concrete adapter. No UI direct mutation. |

## Implementation files
- `scripts/gameplay/slots/five_slot_batch_engine.gd` (capacity + free/restore idle slot)
- `scripts/gameplay/solver/proof_state.gd` (capacity in key)
- `scripts/economy/production_booster_adapter.gd` (new, concrete adapter)
- `scripts/economy/int_domain.gd` (new, exact-int)
- `scripts/economy/economy_services.gd` (atomic import + wiring)
- `scripts/economy/{economy_wallet,booster_inventory,heart_service,speed_entitlement_service,gift_meter_service,daily_service,cards_exchange_service}.gd`
- `scripts/collection/collection_inventory.gd`
- `scripts/gameplay/runtime/production_gameplay_host.gd` (economy composition, 2x gate, +1 slot)

## Tests (all PASS)
- `tests/m39_v02_capacity.gd` — engine 5/6 + no-7 + reset; proof-state 5-vs-6 key distinction.
- `tests/m39_v02_atomicity.gd` — aggregate import rollback; integer-domain fail-closed; cards-exchange atomic; daily task persistence; collection canonical rejection.
- `tests/m39_v02_integration.gd` — REAL host: economy wired; manual 2x gate refuse/allow; +1 slot live grow to 6; concrete Tornado on real BoardState+supply with per-stage fault-injection rollback and exact-cells purge; terminal WON drives first-clear+streak+progression.
- Regression: root suite **5336 checks / 0 failures** (baseline five-slot unchanged); M37/M38 V02 strict PASS; all V01 M39 phase suites PASS.

## Device gate
SB-M39-033 sixth-slot mobile safe-area/touch remains DEVICE/OWNER_REQUIRED. The
temporary sixth slot is now real in the engine/solver; on-device safe-area/touch
evidence is not fabricated.

## Scope note (Tornado)
Live Tornado reconciles BoardState + supply + idle slots atomically and requires
quiescence (no in-flight M26 work) so there are no live M25 claims / M26 agents
to reconcile mid-flight — the audited M24/M25/M26 engines expose no surgical
single-color in-flight teardown primitive, and this remediation deliberately
does not add destabilizing surgery to those cores. Tornado therefore commits
only from a quiescent board, which is a safe, deterministic V1 rule; the full
mid-flight surgical variant is a follow-up requiring new M25/M26 primitives.

## Handoff
`AWAITING_AUDIT / M39-C001 V02 / DEVICE_GATE_REMAINS / STRICT_V2_REAUDIT_REQUIRED`

Root `TASKS.md` not edited. No self-audit. Continuing to M40 V02.
