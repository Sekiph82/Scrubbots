# M40-C001 V04 — Actual App Bootstrap & Durable Lifecycle Criteria

Authority:
- CHATGPT_AUDIT_V03.md frozen F-M40-V03-001..004
- post-M39 V04 canonical action/local-day graph
- M37 V03 AUDITED_PASS
- M35 catalog authority

Do not redo accepted safe-write/schema work.

## 1. Actual project bootstrap owns AppState

The scene launched by project.godot must instantiate/own exactly one canonical AppState.

It must:
- load canonical save at startup;
- expose blocked/future-schema state to the app flow;
- make the same AppState available to gameplay/navigation;
- avoid constructing a second production economy/progression/settings graph.

The current debug labels may remain temporarily, but they cannot be the sole bootstrap behavior.

## 2. Frontier resolves canonical level content

Production gameplay creation must resolve:
`AppState.progression.current_level()`
through LevelCatalog/canonical level metadata.

Required:
- frontier 1 -> catalog level 1 content;
- no independent stale level_path;
- missing frontier content -> explicit CONTENT_MISSING/NOT_AVAILABLE;
- never run level-1 content while labelling/rewarding it as level N.

Debug explicit level overrides must remain separate/non-shipping.

## 3. App-owned durable action/save lifecycle

Bind the post-M39 V04 action facade committed-success events/results to canonical persistence.

A successful durable action must trigger AppState save/dirty handling for:
- boosters that consume charge/SB;
- Heart/2x purchases;
- Daily/Gift/Collection claims;
- Cards Exchange;
- robot unlock;
- settings changes.

Failed actions must not create a save claiming a mutation that did not commit.

## 4. App lifecycle flush

The actual app root must flush pending dirty state on supported:
- application background/pause;
- close/quit;
- equivalent mobile lifecycle boundary.

No per-frame writes.

Tests may call a narrow lifecycle flush seam directly rather than depending on OS delivery.

## 5. Local-day end-to-end persistence

Use the real production local-calendar provider from M39 V04.

Test:
- Daily claim;
- canonical save;
- relaunch through actual AppState bootstrap;
- same local day cannot regrant;
- next local day can claim;
- rollback remains blocked;
- month/year boundary works.

## 6. Direct integration tests

Must actually instantiate the real app bootstrap/composition, not only AppState by itself.

Required:
- fresh boot;
- future schema blocks;
- frontier 1 resolves catalog content;
- frontier 2 with no catalog content -> explicit content missing;
- durable action -> save -> relaunch without terminal;
- settings mutation -> relaunch;
- background/quit flush -> relaunch;
- local Daily boundary -> relaunch.

Run M33/M34 settings/haptics regressions, M35, M37, M38, M39 V04, all M40 prior suites, root suite and git diff --check.

Handoff:
`AWAITING_AUDIT / M40-C001 V04 / ACTUAL_BOOTSTRAP_REAUDIT_REQUIRED`
