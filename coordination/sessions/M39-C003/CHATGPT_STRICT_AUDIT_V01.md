# M39-C003 — SB-M39-054 Random-Any-Booster Reward Semantics Correction — INDEPENDENT STRICT AUDIT V01

Date: 2026-10-09
Repository: `Sekiph82/Scrubbots`
Authorized base: `5af6ed7e2b3eecc61567077c5e73345508e64f66`
Implementation/log commit: `cbb1592da13475f75eb149a0f82d82283e041db8`
Owner authority: `coordination/OWNER_RANDOM_ANY_BOOSTER_REWARD_CORRECTION_V01.md`
Prompt: `coordination/sessions/M39-C003/M39_C003_SB_M39_054_RANDOM_ANY_BOOSTER_PROMPT_V01.md`
Criteria: `coordination/sessions/M39-C003/M39_C003_SB_M39_054_AUDIT_CRITERIA_V01.md`
Builder log: `coordination/sessions/M39-C003/M39_C003_SB_M39_054_CLAUDE_LOG_V01.md`

## VERDICT

**PASS / CLOSED**

The implementation corrects the owner-reported semantic defect: a meta reward meaning “one random booster” no longer always grants the gameplay booster named RANDOM. It now deterministically selects one charge from the exact four canonical booster ids, with equal algorithmic probability, stable replay semantics, preserved save/idempotency authority, and corrected UI wording/art.

No remediation R01 is required.

---

## 1. Diff / scope

PASS.

Independent compare `5af6ed7e..cbb1592d` is exactly one implementation commit.

The diff changes:
- Economy config/resource naming and validation;
- reward-handler wiring;
- a new pure random-any-booster picker;
- Daily / Rewarded Daily references;
- Gift/Daily presentation labels and neutral art binding;
- focused + updated tests;
- evidence/log files.

No changes exist under:
- Remote Content/R2 runtime;
- LevelData;
- supply;
- VOID;
- Family APK/export;
- Level Factory;
- CardPackService / pack RNG / pack ceremony production;
- M43 Phase4 implementation;
- root `TASKS.md`.

This matches the authorized scope.

---

## 2. Owner Desktop safety

PASS on builder evidence.

Builder records:
- persistent Desktop started 10 commits behind and was non-destructively fast-forwarded to exact `origin/main`;
- no incoming commit overlapped the four owner-dirty tracked files;
- no checkout/restore/reset/clean/destructive stash action ran against persistent Desktop;
- implementation/tests/import ran in an explicit TEMP worktree;
- final Desktop was fast-forwarded to implementation `main`;
- final Desktop HEAD == origin/main, ahead/behind 0/0;
- owner `project.godot` SHA-256 remained unchanged:
  `d2546c0bb7d3daccce6c803252a2bf72ddd2359ee1e61abcaa02ca2b98e63574`.

G0 passes.

---

## 3. Canonical semantic distinction

PASS.

New canonical reward resource:

`random_any_booster_charges`

The old ambiguous resource:

`random_booster_charges`

is retained only as a runtime legacy alias.

Independent source review confirms the old production mapping:

`random_booster_charges -> BoosterInventory.RANDOM`

is removed.

Both canonical and legacy handlers now call the same random-any selection behavior.

Canonical economy config explicitly refuses the old key in Gift/Daily bundles and refuses the old all-tasks field name.

Therefore shipping config cannot silently regress to RANDOM-only semantics.

---

## 4. Exact four-booster pool

PASS.

Picker authority is:

`BoosterInventory.BOOSTERS`

Current exact pool:
- `plus_one_slot`
- `random`
- `selector`
- `tornado`

No fifth booster is created.

Focused suite reports all four reachable over deterministic transaction samples and no unknown id.

---

## 5. Equal deterministic selection

PASS.

`RandomBoosterRewardPicker` is pure/stateless.

For each reward unit it derives:

`SHA-256("<tx_id>|random_any_booster|<ordinal>")`

and reads bytes 0..3 as an unsigned 32-bit value, then:

`value % BoosterInventory.BOOSTERS.size()`

With the locked pool size of 4, 2^32 is exactly divisible by 4, so all four indices have equal algorithmic probability.

The picker:
- consumes no gameplay RNG;
- consumes no card-pack RNG;
- consumes no level-generation RNG;
- consumes no solver RNG;
- adds no persisted RNG state;
- produces the same result for the same tx + ordinal across retry/relaunch.

Focused evidence also pins a known-answer SHA path and verifies an independent hex conversion agrees.

---

## 6. Idempotency / replay

PASS.

The existing `RewardGrantService` applied-transaction ledger remains the single grant idempotency authority.

Independent review confirms:
- first grant applies selected charge(s);
- duplicate tx exits before any handler reruns;
- duplicate tx therefore cannot reroll;
- if state is reconstructed and the same tx must be derived again, the picker returns the same booster;
- BoosterInventory save shape remains unchanged.

For amount >1:
- ordinals 0..n-1 are selected independently;
- repeats are allowed;
- exactly n total charges are granted.

No second selection ledger was introduced.

---

## 7. Gift Meter 50

PASS.

Shipping config now contains:

`bot_parts: 1`
`random_any_booster_charges: 1`

Focused suite proves across multiple Gift cycles:
- +1 Bot Part remains unchanged;
- exactly one canonical booster charge is added;
- second claim is refused;
- both RANDOM and non-RANDOM selections occur;
- the reward is not always RANDOM.

This directly closes the owner-reported Gift Meter defect.

---

## 8. Daily D3 / 3-of-3 Tasks / ScrubBox

PASS.

Daily Login Day 3 now grants:

`random_any_booster_charges: 1`

Daily all-three-tasks config now uses:

`all_tasks_random_any_booster_charges: 1`

and `DailyService.claim_all_tasks_bonus()` grants the canonical random-any resource under its stable daily tx.

Focused tests prove:
- D3 exactly one charge;
- same-day duplicate +0;
- ScrubBox exactly one charge;
- duplicate ScrubBox claim +0;
- different stable daily tx ids can select different canonical boosters.

Rewarded Ads slot 3, intentionally seeded from Daily D3, also uses the corrected canonical key and passes the Rewarded Ads regression suites.

---

## 9. Booster-of-Choice protection

PASS.

Unchanged:
- Gift 500: `selected_booster_charges`;
- Gift 1000: `selected_booster_charges`;
- Daily D5: `selected_booster_charges`.

Focused tests prove those rewards still increase `pending_selected` and do not auto-pick a booster.

The owner-approved Booster of Your Choice art/wording remains unchanged.

---

## 10. Named gameplay RANDOM booster protection

PASS.

The actual gameplay booster remains:
- id: `random`;
- canonical member of `BoosterInventory.BOOSTERS`;
- price: 350 SB;
- existing `min_solver_safe_moves = 3`;
- existing gameplay behavior untouched;
- still individually purchasable/usable.

This audit therefore confirms the semantic split:

- **RANDOM** = named gameplay booster
- **Mystery Booster** = one random member of all four booster types

---

## 11. Presentation

PASS.

Gift ceremony:
- canonical row uses `random_any_booster_charges`;
- text is `Mystery Booster`;
- neutral existing `gift_box.png` is used;
- actual gameplay RANDOM booster icon is not used as the generic reward icon.

Daily / reward text:
- `Mystery Booster x1`.

ScrubBox:
- neutral gift art;
- no `boosters/random.png` binding.

No new art was generated.

The implementation includes real presentation evidence for Gift 50 and ScrubBox. No additional owner redesign gate is required because existing neutral art is reused and the change is semantic clarity rather than layout redesign.

---

## 12. Config / persistence safety

PASS.

Economy schema version stays unchanged because the structural config schema is not versioned by individual reward-key vocabulary.

Validation remains fail-closed and adds a targeted prohibition on the legacy ambiguous key in canonical economy config.

Older BoosterInventory save state remains compatible:
- same four booster charge counters;
- same `_pending_selected` metadata;
- no new persisted section;
- no migration required.

---

## 13. Regression

PASS.

Builder reports final:
- focused M39-C003: PASS, 87 checks;
- all requested M39 suites: PASS;
- M40 save suites: PASS;
- M41 Settings: PASS;
- M42 Home/Daily/navigation: PASS;
- M43 Gift/Daily/Tasks/acquisition/feel suites: PASS;
- Rewarded Ads functional + sequential suites: PASS;
- Remote Content CP04/CP05: PASS;
- M55 release regression: PASS;
- root `tests/run_tests.gd`: ALL PASS;
- headless import: clean;
- headless boot: exit 0;
- `git diff --check`: clean.

Final battery: **54/54 suites PASS**.

The focused suite's first run had two test-only JSON float-vs-int equality mistakes. The implementation was not changed to mask a product defect; the test assertions were corrected and the failure was disclosed. No existing regression suite failed on its first final run.

---

## 14. Known edge

NON-BLOCKING.

Because both canonical and legacy resource handlers intentionally remain available, a manually constructed non-canonical reward dictionary containing BOTH keys in the same tx would invoke both resources and derive the same ordinal mapping for each resource.

Shipping canonical config forbids the legacy key, so no current shipping reward surface can produce this combination.

This does not violate the owner ruling or strict acceptance criteria and is not grounds for remediation.

---

## 15. Final disposition

`SB-M39-054` = **PASS / CLOSED**

Owner-reported defect is resolved:

> a “random booster” reward now means one deterministic random selection from all four canonical boosters, not “always grant the gameplay booster named RANDOM”.

No M39-C003-R01 is issued.

The already-prepared `M43-C005F-PHASE4` lane may proceed after normal Gate 0 Desktop sync.
