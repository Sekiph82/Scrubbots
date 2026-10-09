# M43-C005F-PHASE3-QA-R01 — Pack Route Sampling Deflake — INDEPENDENT RE-AUDIT V01

Date: 2026-10-09
Repository: `Sekiph82/Scrubbots`
Authorized base: `08f12af9e7a5cc618baf873095df3881709909e0`
Implementation/log commit: `1cb13a244f003f7281e1acc3a0d7f01d8367e407`
Prompt: `coordination/sessions/M43-C005F-PHASE3-QA-R01/M43_C005F_PHASE3_QA_R01_PROMPT_V02.md`
Criteria: `coordination/sessions/M43-C005F-PHASE3-QA-R01/M43_C005F_PHASE3_QA_R01_AUDIT_CRITERIA_V01.md`
Builder log: `coordination/sessions/M43-C005F-PHASE3-QA-R01/M43_C005F_PHASE3_QA_R01_CLAUDE_LOG_V01.md`

## VERDICT

**PASS**

QA-R01 closes the final strict technical blocker for M43-C005F-PHASE3.

Therefore:

**M43-C005F-PHASE3 = PASS / AWAITING OWNER VISUAL ACCEPTANCE**

No further technical remediation is required.

---

## 1. Scope

PASS.

Independent compare `08f12af9..1cb13a24` is exactly one commit and changes only:

- `tests/m43_c005_c006_standard_pack_presentation.gd`
- `tests/m43_c005_c007_premium_pack_presentation.gd`
- new `tests/support/pack_route_probe.gd`
- QA-R01 builder log

No product source, assets, economy/save, Remote Content/R2, LevelData, supply, VOID, Family APK, Level Factory or root TASKS.md changed.

---

## 2. Owner Desktop safety

PASS.

Builder evidence records:

- persistent Desktop synchronized to starting `origin/main` before work;
- explicit absolute `git -C` / `godot --path` use;
- failed first TEMP creation due low disk space did NOT fall back to Desktop;
- no checkout/restore/reset/clean/stash/force against persistent Desktop;
- final Desktop HEAD == origin/main at `1cb13a24`, ahead/behind 0/0;
- persistent Desktop `project.godot` SHA-256 remained exactly
  `6a08a4779d7be957a38417e2e3c7185b75cb0f56412cdd1ddf306d9f749ac922`
  before and after.

The previous Phase 3 owner recovery gate was separately closed by owner acceptance.

---

## 3. Production freeze

PASS.

Independent diff inspection confirms no production pack path changed.

Builder SHA evidence shows identical before/after hashes for:

- StandardPackCeremony:
  `f0dd9f371a58bb8bd0d5b8d0144d7f49517ed84d151afea48f455606f33bb420`
- PremiumPackCeremony:
  `59a22cacf85e9d38179dcef8cb5c0e87693e51877c063eca9b88448d16180de1`
- RevealSequencer:
  `3c09876237c23e8c9250bf2a4869449fd86b66b6fa09b1f298cfbb500e023f20`

No route duration, timing, tween/easing, art, manifest, pack model or transaction authority changed.

---

## 4. Deterministic route observation

PASS.

The previous flaky assertion depended on observing a process frame with `0 < route < 1`.

The new TEST-ONLY `PackRouteProbe`:

1. records the shipping CardView start/slot/destination;
2. drives the production `route` setter to `0.5`;
3. inspects the resulting face geometry and visibility;
4. restores `route = 0.0`;
5. proves restoration before the real Tap-2 lifecycle starts.

The geometric predicate requires the midpoint to:

- lie on the slot -> own-destination segment;
- be strictly inside that segment;
- be closer to the own destination than the starting point;
- not be a point on the other-destination route.

This tests actual production CardView interpolation deterministically without production instrumentation.

---

## 5. Sensitivity

PASS.

The shared helper explicitly proves rejection of:

- stuck-at-slot;
- jumped-directly-to-destination;
- intermediate travel aimed at the wrong destination.

The test therefore does not simply mark the mid-route condition true by construction.

---

## 6. Real route lifecycle remains covered

PASS.

After the deterministic probe is restored to route 0, both suites still execute the real Tap-2 shipping route.

Standard v07 still proves:

- exact NEW/DUPLICATE route log;
- each card arrival exactly once;
- arrival order [0,1,2];
- canonical destination endpoints.

Premium p12 still proves:

- exact five-card route log;
- canonical endpoints;
- arrivals [0,1,2,3,4];
- serialized route behavior through arrival-event state snapshots;
- no sampled observation ever sees more than one route in flight.

The repair does not weaken the test to end-state-only coverage.

---

## 7. Stability gate

PASS.

Fresh final implementation:

- Standard presentation suite: **10/10 consecutive PASS**
- Premium presentation suite: **10/10 consecutive PASS**

Every run exited 0. No failed run was replaced by later retry evidence.

This directly closes the pre-existing Standard v07 / Premium p12 headless scheduling flake.

---

## 8. Phase 3 regression closure

PASS.

Builder final battery reports **48/48 suites PASS** with no unexplained failure, including:

- Phase 3 focused: 15/15
- Phase 2 earned-pack runtime: 22/22
- Phase 1 foundation: 23/23
- Phase 2 Results/Pack feel: 22/22
- Standard pack: 21/21
- Premium pack: 19/19
- Collection / ceremony / Daily / Gift / acquisition suites
- M39/M40/M41/M42
- R15 rewarded sequence
- CP04/CP05 Remote Content
- root `tests/run_tests.gd`: ALL PASS
- headless import
- headless boot
- `git diff --check`

Announced fault-injection script errors remain expected evidence in the relevant suites.

---

## 9. Phase 3 final technical disposition

The original Phase 3 audit found:

- F006 product code: technical PASS
- F008 product code: technical PASS
- F009 product code: technical PASS
- owner Desktop recovery: later OWNER ACCEPTED / CLOSED
- QA test flake: OPEN

QA-R01 now closes the final QA blocker.

Therefore:

- `SB-M43-C005F-006` = **TECHNICAL PASS / AWAITING OWNER VISUAL ACCEPTANCE**
- `SB-M43-C005F-008` = **TECHNICAL PASS / AWAITING OWNER VISUAL ACCEPTANCE**
- `SB-M43-C005F-009` = **TECHNICAL PASS / AWAITING OWNER VISUAL ACCEPTANCE**

**M43-C005F-PHASE3 = PASS / AWAITING OWNER VISUAL ACCEPTANCE.**

No QA-R02 is issued.
