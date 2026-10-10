# M43-C005F-PHASE4-QA-R01 — Long-Session Baseline Hygiene + MetaRewardFeel Await Safety — INDEPENDENT RE-AUDIT V01

Date: 2026-10-10
Repository: `Sekiph82/Scrubbots`
Authorized base: `35a7b6f63d2f954e600d302d5d563e3222b3b5f6`
Implementation/log commit: `8018d3d7706e0c627b2a7f8ed34450eb2b838641`
Prompt: `coordination/sessions/M43-C005F-PHASE4-QA-R01/M43_C005F_PHASE4_QA_R01_PROMPT_V01.md`
Criteria: `coordination/sessions/M43-C005F-PHASE4-QA-R01/M43_C005F_PHASE4_QA_R01_AUDIT_CRITERIA_V01.md`
Builder log: `coordination/sessions/M43-C005F-PHASE4-QA-R01/M43_C005F_PHASE4_QA_R01_CLAUDE_LOG_V01.md`

## VERDICT

**PASS / CLOSED**

QA-R01 closes the final strict blocker for M43-C005F-PHASE4.

Therefore:

- `SB-M43-C005F-010` = **PASS / CLOSED**
- `SB-M43-C005F-012` = **PASS / CLOSED**
- **M43-C005F-PHASE4 = PASS / CLOSED**

No QA-R02 is required.

---

## 1. Diff / scope

PASS.

Independent compare `35a7b6f6..8018d3d7` is exactly one implementation commit.

Changed files are limited to:

- `tests/m55_long_session.gd`
- `scripts/ui/feel/meta_reward_feel.gd`
- new `tests/m43_c005f_phase4_qa_r01_feel_lifecycle.gd`
- QA-R01 builder log

No Phase 4 F010/F012 shipping behavior file changed.

No semantic diff under:

- Remote Content/R2;
- LevelData;
- supply;
- VOID;
- Family APK/export;
- Level Factory;
- economy/reward values;
- Results layout;
- Home layout;
- pack/Gift/Daily reward authority;
- root `TASKS.md`.

Scope passes.

---

## 2. G0 — persistent Desktop safety

PASS on builder evidence.

The builder records:

- Desktop started at `f44bb280`, behind current main by documentation/audit commits only;
- incoming commits did not overlap owner-dirty files;
- Desktop was non-destructively fast-forwarded to exact starting `origin/main = 35a7b6f6`;
- no destructive checkout/restore/reset/clean/stash operation ran against persistent Desktop;
- implementation/import/tests ran only in an explicit TEMP worktree with absolute paths;
- TEMP `project.godot` restore was scoped only to TEMP;
- final Desktop synchronized to implementation main `8018d3d7`, ahead/behind 0/0;
- owner tracked/untracked files and stashes remained untouched;
- persistent Desktop `project.godot` hash remained unchanged.

G0 passes.

---

## 3. M55 warm-up model correction

PASS.

The original M55 model compared:

- an empty Home that had never played real content;
- against Home after ten real production wins, with a legitimate Gift-10 ceremony/presentation state materialized.

The builder independently identified all 34 persistent first-lap extra Nodes as the open canonical Gift-10 milestone popup. This is not a leak.

The corrected test does NOT waive leak detection.

### Preserved strict behavior

Transition churn still enforces:

- post-warm-up exact Node count stability;
- orphan non-growth;
- Object drift <= 64;
- static-memory drift <= 4 MiB;
- listener stability;
- no surviving GameplayHost.

Lap 1 still runs all real Levels 1..10 and still verifies:

- 10/10 WON;
- progression advance;
- exact clear/reward behavior;
- exactly-once Results route;
- duplicate terminal/reward protections;
- no GameplayHost at Home;
- orphan/listener/root-child integrity;
- save/reload exactness.

The only change is that first-use Node/Object/static-memory growth is recorded as WARM-UP evidence instead of being incorrectly compared to never-used Home.

### Strict steady-state gate

Lap 2 replays the same ten-level workload and is checked against lap-1 end with the unchanged limits:

- Nodes: exact equality;
- orphans: no growth;
- Objects: absolute drift <= 64;
- static memory: growth <= 4 MiB;
- GameplayHost = 0;
- root-child count equal;
- effects/route/settings listeners equal.

This is a valid steady-state leak gate.

---

## 4. M55 sensitivity

PASS.

New case `014_steady_state_sensitivity` proves the strict rule fails independently for:

- nodes +1;
- nodes -1;
- orphans +1;
- objects +65;
- objects -65;
- static memory +4 MiB +1;
- GameplayHost +1;
- route listener +1.

It also proves the rule accepts exactly the current configured bounds:

- +64 Objects;
- +4 MiB static memory.

No hard-coded current runtime counts such as 254 or 58 are used as acceptance facts.

No thresholds were increased.

---

## 5. Quiescent sampling

PASS.

The revised M55 end-of-lap sample waits for:

`FeedbackAdapter.owned_count() == 0`

with a bounded 5-second timeout, then asserts quiescence before memory sampling.

This correctly excludes a still-live bounded presentation emitter from a leak sample without suppressing a real leak:

- normal Spark/feel emitters must leave adapter ownership before sampling;
- a leaked adapter-owned emitter would fail the quiescence assertion or remain visible to the post-quiescent object/node checks.

This specifically resolved the one-node timing flake encountered during QA without weakening steady-state leak rules.

---

## 6. M55 stability

PASS.

Final corrected `m55_long_session.gd` was run three consecutive times after the final quiescence change:

- Run 1: PASS
- Run 2: PASS
- Run 3: PASS

All three runs report identical steady-state deltas:

- Nodes: +0
- orphans: +0
- Objects: +58
- static memory: +462,764 B

All remain inside the unchanged strict bounds.

No failed run was replaced by later success evidence; the builder explicitly restarted the 3-run sequence after the quiescence correction, as required.

---

## 7. MetaRewardFeel await lifecycle

PASS.

Original defect:

`MetaRewardFeel._play()`

was an instance coroutine that awaited `tree.process_frame`. If the app root destroyed the coordinator in the same frame emission after the coroutine had already re-queued its resume, Godot could resume the method on a dead RefCounted and emit:

`Resumed function '_play()' after await, but class instance is gone`.

### Correction

The settle loop is now:

`static func _settle_then_request(owner: WeakRef, ...)`

It:

- owns no MetaRewardFeel instance;
- preserves the same maximum `SETTLE_FRAMES = 8`;
- checks target validity after every await;
- reaches the coordinator only via `owner.get_ref()`;
- requests feedback only if the coordinator still exists.

The live path preserves the original:

- trigger seams;
- intents;
- one-shot keys;
- target;
- layout-settle behavior;
- FeedbackAdapter call;
- FULL native settle;
- Reduced behavior.

No autoload/helper node/persistent listener was introduced.

---

## 8. Lifecycle regression

PASS.

New permanent suite:

`tests/m43_c005f_phase4_qa_r01_feel_lifecycle.gd`

covers:

1. app root / MetaRewardFeel freed while settle coroutine is suspended;
2. popup target closes mid-settle while coordinator lives;
3. live target preserves exact shipping F008 REWARD behavior;
4. static guard proves awaits in MetaRewardFeel occur only in a static function reached through weakref.

The suite reports:

**4/4 PASS**

The exact warning was reproduced on old code during investigation and is absent after the fix.

Final external log scan reports:

- exact await-after-free warning: **0 occurrences**
- any `class instance is gone`: **0 occurrences**

---

## 9. Phase 4 product freeze

PASS.

QA-R01 does not modify:

- F010 nav-first terminal bridge;
- WON-only SMALL bridge;
- LOST no-celebration behavior;
- F012 tracked snapshot fields;
- MICRO-only Home behavior;
- 6% pulse;
- max two serialized events;
- Home no-Spark rule;
- Reduced behavior.

Focused Phase 4 suite remains:

**19/19 PASS**

Therefore QA-R01 repairs QA/lifecycle debt without redesigning the owner-facing Phase 4 product behavior.

---

## 10. Final regression

PASS.

Final battery reports:

**64 / 64 suites PASS**

including:

- Phase 4 QA lifecycle: 4/4
- Phase 4 focused: 19/19
- Phase 3: 15/15
- Phase 2 earned pack: 22/22
- Phase 1: 23/23
- Standard/Premium pack presentation
- M30
- M39
- M40
- M41
- M42
- M43
- M54
- M55 long session
- M55 economy release
- M55 core chaos
- M55 Heart 900
- M55 timed-2x anti-rollback
- CP04/CP05
- root `tests/run_tests.gd`: ALL PASS
- headless import
- headless boot
- `git diff --check`

No failing suite remains.

Announced fault-injection SCRIPT ERROR lines remain confined to their intentional test cases.

---

## 11. Final disposition

QA-R01 = **PASS / CLOSED**

`SB-M43-C005F-010` = **PASS / CLOSED**

`SB-M43-C005F-012` = **PASS / CLOSED**

**M43-C005F-PHASE4 = PASS / CLOSED**

No owner visual gate is required here because:

- F010 remains deliberately subordinate to the already-approved Results presentation;
- F012 does not alter Home layout or hierarchy and is MICRO-only;
- final cross-program owner feel validation remains covered by `SB-M43-C005F-015`.

No QA-R02 is issued.
