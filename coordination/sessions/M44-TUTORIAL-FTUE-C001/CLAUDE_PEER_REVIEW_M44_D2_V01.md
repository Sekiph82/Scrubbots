# M44 D2 (future What's New after L3) — CLAUDE_PEER_REVIEW V01

**Label: `CLAUDE_PEER_REVIEW`** (autonomous mode, `CLAUDE.md §0B`). Not a `CHATGPT_INDEPENDENT_AUDIT`.

- Reviewer: a fresh-context Claude subagent, read-only, static tracing only (no Godot, no CI for this change), 2026-10-15.
- Reviewed: feat commit `b049dc90` (`086a350e` is log-only, confirmed).
- Contract checked: `OWNER_D2_WHATS_NEW_AND_DISK_DIAG_DECISION_V01.md`.
- Findings are condensed from the reviewer's report; builder dispositions are marked **[builder]**.

## Verdict (reviewer): CHANGES_REQUIRED
Product logic matches the owner contract, but one test assertion would fail CI and there was a soft-lock risk.

| # | Item | Result |
|---|---|---|
| 1 | Nothing during L1–L3; Skip Tips does not unlock; only `closed` (genuine L3) does | PASS |
| 2 | Bootstrap baseline inside the rollback transaction, same key format, nothing granted | PASS |
| 3 | Later version once; durable ack; no re-open loop; no relaunch duplicate | CONCERN (D2) |
| 4 | Established / migrated profiles unchanged; old saves never reclassified | PASS |
| 5 | No economy mutation; no phantom features | PASS |
| 6 | GDScript risks: preload cycles, static call, native-name clashes, lambdas | PASS |
| 7 | `_t22` / `_t23` correctness | FAIL (D1) |
| 8 | Workflow guard 23/23 and EXPECTED_CASES = 23 | PASS |

## Defects and dispositions
- **D1 HIGH.**
  - Finding: `_t22` called `FtueConfig.validate()` on the NORMALIZED output of `load_config()`, so the "valid" assertion would fail (`schema`) and the version-0 rejection passed vacuously.
  - **[builder]** Fixed: `_later_raw()` builds from the raw JSON file and `_later_cfg()` = `FtueConfig.validate(raw)`. The bad case now asserts rejection with reason `whats_new` (the version-0 entry).
- **D2 MEDIUM.**
  - Finding: with persistent save failure, closing the non-dismissible ceremony emits `modal_changed(false)` → `request_home_ceremonies()` → the still-due entry re-opens in a loop (Home soft-lock).
  - **[builder]** Fixed: `FtueDirector._snoozed` (session-only, never persisted). A failed ack snoozes the key for this session; it is due again on the next launch. t22 now asserts both.
- **D3 LOW.**
  - Finding: unused `whats_new_keys()`.
  - **[builder]** Removed.
- **D4 LOW.**
  - Finding: `use_config()` did not validate.
  - **[builder]** Now returns false unless the cfg passed `FtueConfig.validate` (`ok`). Asserted in t22.
- **D5 INFO.**
  - Finding: profiles bootstrapped "new" by the pre-D2 M44 build `8a132edb` have no baseline and would see Help & Tips after L3.
  - **[builder]** Accepted and documented. No M44 build ever shipped (all exports skipped, no APK), so only dev / test saves are affected.

## NOT_RUN
- No CI run for the D2 change yet: `AWAITING_OWNER_CI_BUDGET`. The fixes above are static-traced only. A follow-up reviewer pass on the fix commit was not performed.
