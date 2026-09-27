# M55-C001 — CHATGPT INDEPENDENT AUDIT V01

Date: 2026-09-28
Auditor: ChatGPT controller
Repository: `Sekiph82/Scrubbots`
Audited HEAD: `8852045e5f0dffda09fba692078e05c5c8ebba67`
Prompt: `coordination/sessions/M55-C001/task_prompts/SB-M55-C001_CORE_CHAOS_HEART900.md`
Criteria: `coordination/sessions/M55-C001/audit_criteria/SB-M55-C001_CORE_CHAOS_HEART900.md`
Builder evidence:
- `coordination/sessions/M55-C001/CLAUDE_LOG_V01.md`
- `coordination/sessions/M55-C001/M55_CORE_CHAOS_MATRIX_V01.md`

## Verdict

**OWNER_REQUIRED / M55-C001 / TIMED 2X CLOCK-ROLLBACK POLICY**

Technical M55-C001 current-build rows **SB-M55-001..017 are accepted 17/17 PASS**.

One product-policy gap remains outside the already-passing row mechanics:

> If the device wall clock moves backwards after a timed 2x entitlement has expired, should the entitlement remain expired/fail closed, or should the system remain pure wall-clock and therefore allow the entitlement to appear active again until the clock catches up?

No policy was invented by the builder. This owner decision is required by the M55 audit criteria before the core cycle is fully closed.

## 1. Scope / diff audit

Compared `3beaaf1` -> `8852045`.

Changed paths are limited to:
- Heart 900-second active planning/docs reconciliation;
- M55 evidence/tests;
- the M55 save-memory-leak fix in economy/save/runtime host code.

No change to:
- root `TASKS.md` by Claude;
- Levels 1–10 art/LevelData;
- owner supply plans;
- owner click sequences;
- difficulty models/classes/targets;
- automated solution/batch-colour systems.

The implementation stayed inside the authorized current-build M55 scope. SB-M55-018..024 were not implemented.

## 2. Heart 900-second authority

PASS.

Active authorities now agree on 900 seconds / 15 minutes:
- runtime config remains `economy_rewards_v1.json hearts.regen_seconds = 900`;
- planning config now says 15 minutes;
- active UI/economy docs were reconciled;
- 30-minute paid 2x remains unchanged.

The new `tests/m55_heart_900_authority.gd` directly guards:
- max 5;
- 900-second regen;
- +1 Heart = 500 SB;
- refill = 400 SB per missing;
- planning config = 15 minutes;
- active-doc drift;
- the unrelated 15m/30m/60m 2x product table;
- Home full-state `15:00`.

Historical owner/session provenance correctly remains untouched.

## 3. F-M55-01 save-memory leak

PASS after remediation.

Independent source inspection confirms the reported mechanism is real:

- `RewardGrantService` stores callback lambdas in `_handlers`.
- `EconomyServices` registers callbacks that close over the service graph.
- `SaveService.validate_candidate()` constructs a throw-away `EconomyServices` graph for validation.
- without explicitly breaking the handler cycle, the discarded graph can remain alive.

The fix is narrowly scoped:
- `RewardGrantService.release_handlers()` clears the callback map;
- `EconomyServices.dispose()` invokes that release;
- `SaveService.validate_candidate()` disposes the scratch graph after dry-run import;
- `ProductionGameplayHost` disposes only a host-owned fallback economy and does not touch the canonical shared AppState economy.

The added sensitivity regression is well targeted:
- 60 saves;
- repeated rejected validations;
- repeated no-AppState hosts;
- canonical AppState reward handlers verified still functional.

The builder also recorded a remove-fix sensitivity run in which the regression fails and then passes again when restored. This is strong evidence that the test detects the actual defect rather than merely exercising the happy path.

## 4. Chaos rows SB-M55-001..017

Accepted based on source inspection plus the builder's direct Godot execution evidence.

Notable coverage is substantive rather than smoke-only:

- input spam and terminal idempotency;
- mid-flight retry/pause/background;
- supply/slot/color exhaustion;
- repeated real `main.tscn` navigation;
- two full First-10 laps in one process;
- steady-state memory/object/node/listener bounds;
- duplicate terminal/reward suppression;
- booster purchase/use spam;
- 900-second Heart background/relaunch behavior;
- Tornado with matching and non-matching assignments concurrently in flight;
- repeated Cards Exchange-all with exactly-once grant behavior.

Builder reports 29 regression suites, root `5323` checks, 0 `FAIL:`, 0 `SCRIPT ERROR`, and no new engine-error class. I did not independently execute Godot in this controller environment; the runtime counts are builder execution evidence, while this audit independently verified the changed source/test contracts and diff scope.

## 5. Timed 2x rollback finding

**OWNER_REQUIRED.**

Independent source inspection confirms the observation.

`SpeedEntitlementService` stores:
- `_timed_expiry` as an absolute wall-clock timestamp;
- remaining time as `max(_timed_expiry - _now(), 0)`;
- entitlement truth as `_now() < _timed_expiry`.

There is no highest-seen-time / monotonic wall-clock guard.

Therefore, after an entitlement expires, moving the system clock backwards to a time before `_timed_expiry` can make the entitlement appear active again.

No current owner rule located in this cycle defines the desired rollback semantics for timed 2x. The builder was correct not to invent one.

### Owner options

**A — Fail closed / anti-rollback**
- Timed 2x must never regain time because the device clock moved backwards.
- Implementation would persist/track a safe high-water wall-clock value and clamp backwards movement.
- Better anti-tamper semantics, but requires a defined migration/persistence rule.

**B — Pure wall-clock**
- Keep current behavior.
- Timed 2x is defined purely by system wall time, including backwards corrections.
- Simpler, but a manual/automatic rollback may temporarily revive an expired entitlement.

No option is selected by this audit.

## 6. Audit-criteria result

- Heart authority: PASS.
- Current-build chaos evidence: PASS for SB-M55-001..017.
- Regression integrity: PASS on supplied execution evidence + independent source/diff inspection.
- No First 10/difficulty/content mutation: PASS.
- Owner-policy gap: OPEN, timed 2x clock rollback.

## Final status

`OWNER_REQUIRED / M55-C001 / TIMED 2X CLOCK-ROLLBACK POLICY`

Technical work for SB-M55-001..017 is accepted. The owner ruling on timed 2x clock rollback is the only remaining gate before M55-C001 can be closed and the governed workflow advances.
