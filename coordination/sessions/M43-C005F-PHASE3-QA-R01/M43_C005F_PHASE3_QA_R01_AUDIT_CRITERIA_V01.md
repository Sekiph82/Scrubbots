# M43-C005F-PHASE3-QA-R01 — Pack Route Sampling Deflake — STRICT AUDIT CRITERIA V01

Date: 2026-10-09
Repository: `Sekiph82/Scrubbots`

## PASS gate

PASS requires a TEST-ONLY deterministic repair of Standard v07 and Premium p12.

## 1. Owner Desktop safety

- persistent Desktop was current origin/main before work;
- owner-local files preserved;
- persistent Desktop project.godot pre/post identity unchanged;
- no checkout/restore/reset/clean against persistent Desktop;
- TEMP worktree created successfully before implementation;
- all TEMP commands use explicit absolute path;
- final persistent Desktop HEAD == origin/main, 0/0.

Any owner Desktop mutation = FAIL.

## 2. Production freeze

Byte-identical before/after:
- standard_pack_ceremony.gd
- premium_pack_ceremony.gd
- reveal_sequencer.gd

No pack timing/art/model/economy/receipt production change.

Any production ceremony/timing change = FAIL.

## 3. Deterministic observation

Standard v07 and Premium p12 must no longer depend on catching a process frame where 0 < route < 1.

The replacement must still prove:
- a strictly intermediate visible travel state;
- movement toward each card's OWN canonical destination;
- NEW/DUPLICATE routing truth;
- wrong-target sensitivity.

End-state-only weakening = FAIL.

## 4. Real route lifecycle preserved

Both suites still assert:
- exact route log;
- one route per card;
- serialized routing;
- exact arrival order;
- completion behavior;
- destination truth.

## 5. Stability

Fresh final implementation:
- Standard suite: 10 consecutive runs, 10/10 PASS.
- Premium suite: 10 consecutive runs, 10/10 PASS.

A failed run invalidates that 10-run sequence.

## 6. Phase 3 regression closure

Final required Phase 3 battery PASS, including:
- Phase 3 focused suite
- Phase 1
- Phase 2
- earned pack R01/R02
- relevant M39/M41/M43/R15
- Standard pack
- Premium pack
- root ALL PASS
- headless boot/import
- git diff --check

No unexplained failure.

## 7. Scope

Allowed:
- Standard presentation test
- Premium presentation test
- optional test-only helper
- QA log

Forbidden:
- TASKS.md by Claude
- production scripts
- assets
- Remote Content/R2
- LevelData/supply/VOID
- Family APK
- Level Factory

Final verdict:
- PASS, or
- CHANGES_REQUIRED.
