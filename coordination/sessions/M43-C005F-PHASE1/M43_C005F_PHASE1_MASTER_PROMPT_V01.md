# M43-C005F-PHASE1 — GameFeelFlow + Saltmire Spark Canonical Foundation — MASTER CLAUDE PROMPT V01

Repository: `Sekiph82/Scrubbots`
Owner-local checkout: `C:/Users/sekip/Desktop/ScrubBots`
Engine: Godot 4.7.2
Date: 2026-10-08
Status: AUTHORIZED PARALLEL MILESTONE

## Milestone objective

While Level Factory/Codex continues the independent R2 publisher work, complete the canonical **foundation layer** for GameFeelFlow + Saltmire Spark in ScrubBots without touching Remote Content / R2 work and without yet adding broad shipping visual effects to Results, gameplay, packs, Home, rewards or ceremonies.

Execute these canonical TASKS children continuously, in this order:

1. `SB-M43-C005F-001` — Canonical plugin intake / API / license gate
2. `SB-M43-C005F-002` — One fail-open ScrubBots feedback adapter + intensity policy
3. `SB-M43-C005F-013` — Canonical FULL / REDUCED effects matrix + live cancellation
4. `SB-M43-C005F-014` — Explicit DO-NOT-USE plugin boundary

Do not start F003–F012 or F015 in this milestone.

This is a foundation milestone only.

---

# 0. Governance and safe synchronization

Before implementation:

- inspect `C:/Users/sekip/Desktop/ScrubBots` branch, HEAD, `origin/main`, ahead/behind, tracked modifications, untracked files, stashes and worktrees;
- fetch latest `origin/main`;
- non-destructively synchronize the owner-local checkout as far as safely possible;
- preserve every owner-local modification and untracked file;
- absolutely no `reset --hard`, `git clean`, destructive checkout, force push, or silent stash loss;
- root `TASKS.md` is read-only for Claude;
- read current `AGENTS.md`, `CLAUDE.md`, root `TASKS.md`, this prompt and its audit criteria before coding.

Known owner-local state from recent work may include a modified `project.godot`, modified scenes, owner-review scenes, untracked `addons/`, art/import files and other owner material. Treat local files as precious.

## Safe project.godot rule

Because `project.godot` may contain owner-local modifications:

1. inspect the owner-local diff against current `origin/main`;
2. do not overwrite or normalize unrelated owner edits;
3. if canonical plugin/autoload changes would overlap owner-local edits, implement from a clean TEMP worktree based on exact current `origin/main`, while using the owner-local addon files only as read-only source material;
4. push only the minimal canonical project/plugin changes;
5. leave the owner-local dirty file untouched and document the canonical diff needed for its later non-destructive sync.

Do not use a cloud clone as a substitute for checking the owner-local checkout first.

---

# 1. Hard scope isolation

This milestone MUST NOT modify:

- `scripts/content_runtime/**`
- `data/config/remote_content_runtime_v1.json`
- `coordination/sessions/REMOTE-CONTENT-RUNTIME-V01/**`
- Level Factory / publisher / R2 code
- Rewarded Ads sequential-unlock behavior
- gameplay BoardState / solver / routing / target selection / supply authority
- economy grant/save/progression authority
- ad/IAP callback authority
- Home Scrubby frame-animation authority
- current audio/haptic authority

No R2 endpoint, manifest URL, bucket credential or publisher secret may enter this milestone.

---

# 2. SB-M43-C005F-001 — Canonical plugin intake / API / license gate

The owner has working local installations of:

- GameFeelFlow
- Saltmire Spark

Their exact local files are the source of truth.

## Required work

Inspect the actual owner-local addon folders and verify:

- exact addon folder names;
- `plugin.cfg`;
- plugin version if declared;
- autoload names and registration mechanism;
- public runtime methods actually present;
- required runtime scripts/resources;
- license / attribution files;
- whether examples/tests/demo/editor-only files are required at runtime.

Do NOT trust TASKS planning assumptions if the installed API differs.

Canonicalize only what ScrubBots actually needs into Git.

Expected policy:

- retain required runtime/editor plugin files;
- retain MIT/license/attribution material;
- exclude GameFeelFlow examples/tests if runtime-independent;
- exclude Saltmire demo material if runtime-independent;
- no GdUnit runtime dependency;
- no GameFeelFlow Pro dependency;
- no paid Saltmire Impact dependency;
- no duplicate autoload registration;
- no second copy of either addon elsewhere.

If the local plugin source/license makes shipping rights unclear, STOP that child as `BLOCKED_LICENSE_AUTHORITY` and continue only with work that does not require copying questionable files.

## Required verification

Prove:

- clean project parse/start with canonical addons present;
- expected autoload(s) exist exactly once;
- a harmless capability/query call can be made without gameplay mutation;
- project still boots if the adapter is disabled or a plugin is absent in a controlled test seam;
- no demo/test dependency leaks into shipping boot.

---

# 3. SB-M43-C005F-002 — One fail-open ScrubBots feedback adapter

Create exactly one ScrubBots-owned presentation adapter/coordinator.

Purpose: all future GameFeelFlow/Spark usage must pass through one boundary rather than scattering plugin calls throughout gameplay/economy/UI authority.

## Architecture requirements

The adapter must:

- live in presentation/app/feel territory, not durable AppState authority;
- be created/owned by ephemeral application/presentation lifecycle;
- never become a save field;
- never decide reward/gameplay success;
- never block navigation, terminal flow, reward commit or save;
- tolerate either plugin being missing, unavailable, throwing, or partially initialized;
- return/no-op safely;
- offer an explicit intensity vocabulary:
  - MICRO
  - SMALL
  - REWARD
  - MAJOR_REWARD
  - WIN
  - MAJOR_UNLOCK
- accept optional one-shot event keys and suppress duplicate presentation events;
- provide bounded cleanup/cancel behavior;
- expose a test seam/spies so automated tests can verify plugin calls without needing real particles.

## Initial budgets

Keep conservative ceilings from TASKS as policy, not reward truth:

- MICRO: 0 Spark particles
- SMALL: 0–4
- REWARD: 4–8
- MAJOR_REWARD: 8–14
- WIN: 12–18
- MAJOR_UNLOCK: 16–24

No unbounded loops.
No scene-long decorative ownership.
No plugin call may create gameplay authority.

## No shipping call-site rollout yet

Do NOT wire F003–F012 surfaces in this milestone.

It is acceptable to add one isolated diagnostic/test harness that invokes each tier through the adapter. Do not alter accepted Results/Home/gameplay presentation to demonstrate the adapter.

---

# 4. SB-M43-C005F-013 — FULL / REDUCED matrix + live cancellation

Use the existing canonical Reduced Effects authority.

Do not create a second setting.

## Required behavior

For every adapter intent/tier, define deterministic FULL vs REDUCED behavior.

REDUCED mode must:

- remove confetti and nonessential Spark by default;
- disable looping motion;
- disable element flash;
- disable any screen/camera manipulation;
- preserve static native UI/art/text/reward truth;
- be materially cheaper than FULL;
- never replay an event when toggling back to FULL.

A live Reduced Effects toggle must cancel/settle adapter-owned decorative work safely.

If a plugin does not support targeted cleanup cleanly, the adapter must own enough lifecycle information to fail closed/no-op rather than manipulating authoritative nodes.

Tests must prove:

- FULL mapping;
- REDUCED mapping;
- live FULL→REDUCED cleanup;
- REDUCED→FULL does not replay already-consumed one-shot keys;
- missing plugin remains safe in both modes.

---

# 5. SB-M43-C005F-014 — Explicit DO-NOT-USE boundary

Encode and test the architectural red lines.

GameFeelFlow and Saltmire Spark MUST NOT own or determine:

- SafeAreaRoot / safe-area math;
- NavigationController route truth;
- ModalStack/BasePopup lifecycle or pending-token authority;
- BoardState;
- candidate/reservation/TargetSelector;
- routing;
- supply/slot/solver/collision authority;
- terminal truth;
- economy/reward/save/progression/Heart/timers;
- Home Scrubby canonical frame animation;
- audio/haptics authority;
- rewarded-ad/IAP callbacks.

For V1, explicitly prohibit GameFeelFlow usage of:

- camera shake;
- screen-wide/strobing flash;
- freeze-frame;
- time scale;
- pause;
- physics/collider/velocity/rigidbody effects;
- scene destroy/spawn authority;
- looping flicker.

Saltmire Spark may never determine hit/clear/reward success.

## Enforcement

Add automated/static boundary checks where practical:

- imports/references only from approved presentation locations;
- no direct plugin calls in protected authority directories;
- plugin removal/fault injection leaves core Home/gameplay/navigation/economy paths operational;
- adapter is the only future production entry point.

---

# 6. Required tests and regressions

Create focused permanent tests for this milestone.

At minimum verify:

- canonical addon intake/autoload uniqueness;
- actual installed API names captured in a small canonical compatibility layer or adapter;
- no GdUnit/demo dependency at runtime;
- license/attribution presence;
- adapter missing-plugin no-op;
- plugin exception/failure does not escape into caller;
- intensity budgets;
- duplicate event-key suppression;
- FULL/REDUCED matrix;
- live Reduced cleanup;
- no replay on mode restore;
- static protected-directory/plugin-reference boundary;
- no Remote Content/R2 files touched.

Run at minimum:

- new M43-C005F Phase 1 focused suite;
- M41 Settings / Reduced Effects regression;
- M42 Home regression;
- M43 popup/modal regression;
- M43 Results foundation/momentum regressions;
- M43 acquisition / Need a Hand regressions;
- M31 cleaning effects regression;
- terminal/navigation regressions;
- M40 save regressions;
- root `tests/run_tests.gd`;
- headless project parse/boot;
- `git diff --check`.

If actual plugin intake changes import/startup behavior, also perform one clean TEMP checkout/import/headless boot using only tracked files.

No test may require public internet.

---

# 7. Evidence / logs

Write one child log per task:

- `coordination/sessions/M43-C005F-PHASE1/logs/SB-M43-C005F-001_CLAUDE_LOG_V01.md`
- `coordination/sessions/M43-C005F-PHASE1/logs/SB-M43-C005F-002_CLAUDE_LOG_V01.md`
- `coordination/sessions/M43-C005F-PHASE1/logs/SB-M43-C005F-013_CLAUDE_LOG_V01.md`
- `coordination/sessions/M43-C005F-PHASE1/logs/SB-M43-C005F-014_CLAUDE_LOG_V01.md`

And one master log:

`coordination/sessions/M43-C005F-PHASE1/M43_C005F_PHASE1_MASTER_CLAUDE_LOG_V01.md`

Each child log must include:

- starting SHA;
- owner-local sync evidence;
- exact files changed;
- actual plugin API/version/license findings;
- tests;
- blockers/deviations;
- final child state.

The master log must include:

- ordered child results;
- final changed-file list;
- proof Remote Content/R2 paths were untouched;
- clean-clone/headless result;
- root regression result;
- final Git `HEAD == origin/main` proof after normal push.

Claude must not edit root `TASKS.md`.

If all four children complete:

`AWAITING_GPT_M43_C005F_PHASE1_AUDIT`

If one child is genuinely blocked by missing/unclear plugin source or license, do not fabricate closure. Complete safe preceding work, record the exact gate, and end:

`BLOCKED_AWAITING_GPT_M43_C005F_PHASE1`
