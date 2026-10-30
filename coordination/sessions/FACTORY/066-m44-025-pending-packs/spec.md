# Pending-pack inventory: pre-L20 packs kept, openable at L20

> Feature: SB-M44-025 — pending-pack inventory: packs earned before L20 are kept and become openable at L20 (source: coordination/OWNER_META_PROGRESSION_DESIGN_V01.md; Collection unlocks at L20 per data/config/feature_unlocks_v1.json).

## Context
Current behaviour (traced in the worktree):
- Earned packs (Gift Bar, Daily, rewarded ads) are granted by `RewardGrantService`; the handler in `scripts/economy/economy_services.gd` (~l.118-124) ENQUEUES `{id,kind}` into the durable `economy.pending_packs` (`scripts/collection/pending_pack_queue.gd`, snapshotted in the economy save, strict import). Nothing is drawn at grant time. So packs are already queued durably and never granted twice (entry id = pack tx id; `PackCommitTransaction` replays receipts).
- The gap: nothing checks the feature gate on the drain side. `Main.request_earned_packs()` -> `_drain_earned_packs()` (`scripts/app/main.gd` ~l.410) -> `PackPresenter.drain()` (`scripts/ui/ceremony/pack_presenter.gd` ~l.64) -> `AppState.open_earned_pack(id)` (`scripts/app/app_state.gd` ~l.310) opens the front entry on Home regardless of level. A fresh profile that earns a pack before L20 therefore gets the pack ceremony and a draw before Card Packs/Collection unlock. That violates the owner design (pre-L20 packs wait for L20).
- Gate: `AppState.feature_unlocked("card_packs")` (l.209; `card_packs` = 20 in `data/config/feature_unlocks_v1.json`; grandfather rule: any non-new-FTUE profile has everything unlocked).
- Collection entry: `scripts/ui/collection/collection_screen.gd` already shows live `pending_packs` counts and an OPEN PACKS button calling `request_earned_packs`; Home shortcut `collection` is itself gated (`Main._on_home_shortcut`).

## Requirements
1. Single authoritative choke: `AppState.open_earned_pack(id)` returns `{ok:false, reason:"locked"}` (no commit, no RNG/pity/receipt/Collection change, entry stays queued) when `not feature_unlocked("card_packs")`. Draws still only happen via `PackCommitTransaction` through AppState/economy, never UI.
2. `PackPresenter.drain()` (and thus `Main._drain_earned_packs`) must not open a ceremony while locked: return false before any presenter/ceremony UI, without setting an error that blocks later drains. Either check `_app.feature_unlocked("card_packs")` at the top of `drain()` or rely on req. 1 plus an early guard; builder picks the smaller, but no ceremony UI may appear and `idle`/error state must not stick.
3. At unlock, the queued packs become openable with no new mechanism: after the campaign frontier reaches 20, the next `request_earned_packs()` (Home arrival, Collection OPEN PACKS, any committed action) drains the queue FIFO via the existing C005 ceremony. Verify `Main` already requests a drain on Home arrival after a win/route change; if not, add one `request_earned_packs()` call on the HOME route-changed path (smallest change). Do not add a new ceremony, popup or notification.
4. Queue stays the single store: no new save field, no schema bump, no conversion of packs into other currency, no new rewards. Save/load (`economy.snapshot()` / `import_snapshot`) preserves pre-L20 entries unchanged and in FIFO order.
5. Grandfathered (non-new-FTUE) profiles: behaviour unchanged (gate returns true).
6. Fail-open consistent with the existing gate (unknown/malformed config => unlocked), no new config.
7. Docs: tick SB-M44-025 in `TASKS.md` with evidence per factory convention; add one line to `AGENTS.md` only if it lists the pending-pack/pack-ceremony flow (keep the doc consistent: "drain is gated by card_packs").
8. New suite `tests/m44_pending_packs_gate.gd` (see below) added to the CI validate loop in `.github/workflows/android-family-first10.yml` (list at ~l.112-125: append `m44_pending_packs_gate`; header comment l.42 -> 59 total; add exact-summary guard beside the C011 guard: `grep -qxF 'M44 PENDING PACKS GATE: PASS (6/6 cases, 0 fail)' validate_logs/m44_pending_packs_gate.log` else `fail=1`, echoing `M44-PENDING-PACKS verdict=PASS|FAIL`).

## Acceptance criteria
GODOT=C:/Users/sekip/AppData/Local/Microsoft/WinGet/Packages/GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe/Godot_v4.7.2-stable_win64_console.exe ; W=C:/Users/sekip/AppData/Local/ScrubBotsFactoryWT/066-m44-025-pending-packs

New suite `tests/m44_pending_packs_gate.gd` (follows `tests/m44_unlock_gate.gd` pattern: EXPECTED_CASES list, temp save override, never boots main.tscn against the real save; uses `record_win` to advance the frontier). Run: `"$GODOT" --headless --path $W -s res://tests/m44_pending_packs_gate.gd`; last line must be exactly `M44 PENDING PACKS GATE: PASS (6/6 cases, 0 fail)`. Cases, each a direct assertion:
1. `queue_below_unlock` — fresh profile, frontier walked via record_win to L1, L10, L19: grant standard+premium packs through the real reward path (e.g. Gift Bar / reward service); `pending_packs.size()` equals granted count, FIFO ids stable, `collection` owned-card count and `pack_receipts` unchanged, RNG/pity snapshot unchanged.
2. `no_open_below_unlock` — at L19 `open_earned_pack(front_id)` returns `{ok:false, reason:"locked"}`; `PackPresenter.drain()` returns false, no ceremony/modal opened, queue size unchanged, no receipt written.
3. `persist` — save then load into a fresh AppState (temp path): queue entries identical (ids, kinds, order) and still locked below L20.
4. `open_at_unlock` — record_win to frontier 20: `feature_unlocked("card_packs")` true; Collection screen shows the live standard/premium counts (`COLLECTION_PACKS` label); `open_earned_pack` + ceremony drain opens each pack exactly once in FIFO order, cards land in Collection, queue empties, receipts exist.
5. `exactly_once` — repeat `open_earned_pack` on an already committed id replays the receipt (no second draw: Collection counts/RNG unchanged); `acknowledge_earned_pack` then removes it; second drain is a no-op; reload after ack shows empty queue.
6. `grandfather` — established (non-new-FTUE) profile with frontier < 20: gate true, packs open immediately exactly as before (one pack opens and acknowledges normally).

Regression, each must keep its existing PASS line (run the same command shape with the suite name):
7. `m43_master_c007_collection`, `m43_master_c005_meta_ceremonies`, `m44_unlock_gate`, `m44_ftue`, `m40_save_system`, plus `m43_c005f_phase2_r01_earned_pack_runtime`, `m43_c005f_phase3_meta_rewards_acquisition` and `m54_collection_set_master_exactly_once` (all touch earned-pack flow; any that assume packs open on a fresh sub-L20 profile must be fixed by making their fixture grandfathered/L20, never by weakening the gate).
8. `git diff --check` clean; CI workflow YAML valid and the validate list has 59 suites with the new exact guard (`grep -c` on the list or visual diff). GitHub CI (validation_only run) is the arbiter for perf timings and the full 59-suite aggregate=PASS.

## Out of scope
- New reward types, pack contents, rarity/draw rules, conversion of packs to SB/other currency.
- New save fields, schema/version bumps, migrations.
- New popups, "packs waiting" notifications, badges, or copy beyond existing strings.
- Changing unlock levels, the grandfather rule, or the Gift Bar rewards.
- Gating the *grant* (enqueue) — grants must keep queuing.

## Assumptions
- No pack draw happens at grant time today, so only the open/drain side needs gating (smallest change; verified in economy_services.gd and app_state.gd).
- Gate key is `card_packs` (same level 20 as `collection`) per the unlock table.
- Locked-drain is a silent no-op (no UI); queued counts become visible via the existing Collection screen once Collection unlocks.
- The unlock ceremony for Collection (`unlock:collection`) may show first; the pack drain waits behind existing ceremony/modal guards in `_drain_earned_packs`, no ordering change needed.
