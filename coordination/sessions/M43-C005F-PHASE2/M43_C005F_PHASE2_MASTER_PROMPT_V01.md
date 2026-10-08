# M43-C005F-PHASE2 — Results + Pack Feel Integration — MASTER CLAUDE PROMPT V01

Repository: `Sekiph82/Scrubbots`
Owner-local checkout: `C:/Users/sekip/Desktop/ScrubBots`
Engine: Godot 4.7.2
Date: 2026-10-08
Status: AUTHORIZED PARALLEL MILESTONE

## Milestone objective

While Level Factory/Codex continues the independent VOID/R2 work, complete the first real shipping-surface rollout of the already audited GameFeel foundation.

Execute continuously, in this order:

1. `SB-M43-C005F-003` — WON Results one-shot celebration + CLEAN NEXT emphasis
2. `SB-M43-C005F-004` — Results reward-row feedback by committed reward kind
3. `SB-M43-C005F-005` — Standard/Premium pack + individual-card reveal feel

Do not start F006-F012 or F015 in this milestone.

This milestone is presentation-only. It must not alter gameplay/economy/reward/save/navigation authority.

---

# 0. Mandatory authority

Read before implementation:

- root `TASKS.md`
- `coordination/sessions/M43-C005F-PHASE1/CHATGPT_INDEPENDENT_AUDIT_V01.md`
- `coordination/sessions/M43-C005F-PHASE1/M43_C005F_PHASE1_MASTER_CLAUDE_LOG_V01.md`
- current `scripts/ui/feel/feedback_adapter.gd`
- current Results and pack ceremony production code/tests
- prior owner visual acceptance for Results and Standard/Premium pack opening

The Phase 1 audited API lock overrides all older C005F planning wording.

## Hard API truth

GameFeelFlow 1.0.0:
- canonical reachable production effect: `punch_scale` only;
- `punch_scale` is only valid for Node2D/Node3D targets;
- it does NOT animate Godot `Control` UI nodes;
- `spring_scale`, `squash_stretch`, `elastic` are not registered effects;
- `ui_button_press` / `ui_notification` are DO-NOT-USE for V1;
- no flash, camera, freeze-frame, time-scale, shake or physics effects.

Saltmire Spark 1.0.0:
- production access only through the canonical FeedbackAdapter;
- allowed presets: `spark`, `pickup`, `confetti`;
- global `Spark.clear()` is forbidden;
- adapter owns/frees only its own emitters.

Control-based UI motion must use native Godot presentation tweening or existing native animation. Do not force GFF onto Control nodes.

---

# 1. Safe sync / owner-local protection

Before coding:

- inspect branch, HEAD, origin/main, ahead/behind, tracked modifications, untracked files, stashes, worktrees;
- fetch current `origin/main`;
- preserve owner-local work exactly;
- no `reset --hard`, `git clean`, force checkout/push or destructive overwrite;
- root `TASKS.md` is read-only for Claude.

Important known state:

The owner-local checkout may still be behind current GitHub main because:
- local `project.godot` has owner-only edits;
- local addon folders predate canonical vendoring;
- `godot_ai` remains owner-local.

Do not delete or overwrite any of these.

If owner-local cannot fast-forward cleanly, create a clean TEMP worktree at exact current `origin/main` and implement there. Use owner-local only for read-only visual/runtime inspection when safe.

At final handoff, document owner-local parity truth honestly.

---

# 2. Hard scope isolation

MUST NOT modify:

- `scripts/content_runtime/**`
- `data/config/remote_content_runtime_v1.json`
- `coordination/sessions/REMOTE-CONTENT-RUNTIME-V01/**`
- Level Factory / VOID / R2 / publisher code
- economy grant amounts or transaction identities
- pack RNG or draw order
- collection ownership/copy truth
- save schema
- navigation authority
- terminal truth
- Rewarded Ads sequence
- gameplay solver/routing/supply/BoardState
- audio/haptic authority
- existing approved Results/Pack art

No endpoint or credential work.

---

# 3. SB-M43-C005F-003 — WON Results feel

## Goal

Add restrained celebratory presentation only after authoritative WON truth already exists.

Current Results surface is Control-based, so do NOT use GFF scale on Results Controls.

Use:
- existing/native Godot tween for Control emphasis;
- canonical FeedbackAdapter WIN intent for bounded Spark confetti;
- GFF only if a genuinely compatible Node2D/Node3D presentation target already exists and using it is clearly superior. Do not create fake Node2D wrappers just to justify GFF.

## Trigger contract

The celebration may run only for status `WON`.

One-shot key must bind at least:
- terminal attempt identity;
- WON status.

Repeated:
- `show_model()`;
- viewport resize;
- route refresh;
- ceremony barrier hold/release;
- Continue re-arm

must NOT replay the same WIN celebration.

LOST / ERROR / non-WON gets no WIN celebration.

## Visual contract

Keep owner-approved Results composition.

Allowed:
- one restrained native scale/settle on Victory emblem and/or robot presentation;
- bounded WIN Spark confetti through FeedbackAdapter;
- one subtle native emphasis on CLEAN NEXT after the existing ceremony/momentum barrier allows it.

Forbidden:
- flash;
- screen-wide effect;
- camera shake;
- freeze frame;
- time scale;
- layout movement that changes hierarchy;
- blocking Continue/Home;
- any change to reward rows or navigation truth.

Reduced Effects:
- no Spark;
- no celebratory bounce;
- static approved Results;
- CLEAN NEXT remains readable/actionable immediately when its existing barrier allows.

---

# 4. SB-M43-C005F-004 — Results reward-row feel

## Goal

Add small feedback only when an already-created committed reward row becomes visible in the existing reveal sequence.

Do not change:
- `receipt.reveal_queue`;
- row order;
- row amount/copy;
- reveal truth;
- Continue/Home availability;
- Reduced immediate-row behavior.

## Presentation rules

Results reward rows are Controls.

Therefore:
- native Godot tween may provide a tiny bounded reveal settle;
- FeedbackAdapter REWARD intent may provide Spark `pickup` at the row;
- do NOT call GFF `punch_scale` on the Control;
- do NOT use GFF UI combos.

Each eligible row gets at most one feedback event.

Event key must derive from immutable Results presentation identity, for example:
- attempt;
- reward row index;
- reward kind.

Repeated Results refresh/reopen cannot replay it.

Particle work must serialize or remain bounded so a large reward list cannot create a particle pile-up.

Reduced:
- current immediate row visibility stays authoritative;
- zero plugin work;
- no sequential animation requirement;
- no hidden or delayed amount text.

---

# 5. SB-M43-C005F-005 — Standard/Premium pack + card reveal feel

## Existing owner locks to preserve

Standard:
- pack alone first;
- Tap 1 begins frames 01→09;
- final beat: exactly 3 already-committed cards emerge;
- pack disappears;
- only 3 cards remain awaiting next interaction;
- Collection/Card Exchange destinations appear only after reveal.

Premium:
- exact 5 already-committed cards;
- Rare-or-better guarantee truth remains exactly as committed;
- current 3+2 hold layout preserved.

Both:
- no reroll;
- no grant from presentation;
- no Collection mutation from presentation;
- duplicate/new truth from committed model only;
- existing owner-approved frames/art remain unchanged.

## Feel integration

Pack/card UI is Control-based. Do not use GFF Control punches.

Use only:
- existing native ceremony animation;
- existing native NEW-card pulse/glow;
- optional additional restrained native tween if it clearly improves the reveal without replacing accepted timing;
- FeedbackAdapter REWARD/MAJOR_REWARD Spark accent at specific committed reveal beats.

Suggested intensity:
- ordinary card settle: no Spark or SMALL only;
- NEW card: REWARD pickup/spark;
- Rare-or-better reveal: REWARD;
- Premium final group / particularly meaningful reveal: at most MAJOR_REWARD, never WIN/MAJOR_UNLOCK.

Do not particle-spam all five Premium cards simultaneously.

Rare/Epic/Legendary must NOT use flash.

Spark is decorative only. Rarity/new/duplicate truth remains visible in text/art.

## Idempotency

Feedback event keys must derive from the already-committed pack presentation identity + card index/reveal beat.

Reopen/resume/repeated callbacks:
- never reroll;
- never re-grant;
- never replay a consumed feel event.

Reduced:
- preserve current reduced pack grammar;
- no Spark;
- existing static glow/new/duplicate truth remains;
- no flash/bounce.

---

# 6. Integration architecture

Do not let Results or Pack code access `GameFeelFlow` or `Spark` directly.

Only the canonical `FeedbackAdapter` may access plugins.

Use presentation-layer dependency injection from app/presenter seams.

Preferred rule:
- ResultsScreen receives an optional feedback adapter reference through a small presentation-only bind/setter;
- pack ceremony/presenter receives the same optional adapter through its presentation construction/bind path;
- missing adapter = exact current native presentation, no error.

Do not place adapter references in AppState, EconomyServices, pack models or save data.

Do not create a second feedback adapter.

---

# 7. Required tests

Permanent focused Phase 2 tests must prove at minimum:

## F003
- WON fires one WIN event only;
- repeated same-attempt show_model does not replay;
- new attempt may play once;
- LOST/ERROR does not play;
- Continue/Home remain live;
- ceremony barrier behavior unchanged;
- Reduced = zero plugin calls;
- plugin missing/throwing cannot block Results.

## F004
- committed row order/text/amount unchanged;
- one event per eligible row;
- same row does not replay on refresh;
- Reduced immediate reveal unchanged;
- no economy/service/grant call from feedback;
- bounded event count.

## F005
- Standard exact 3 cards and Premium exact 5 unchanged;
- draw order unchanged;
- Premium guarantee semantics unchanged;
- owner frame sequence unchanged;
- pack disappearance / destination timing unchanged;
- NEW/DUPLICATE/copy truth unchanged;
- feel event once per committed reveal identity;
- reopen/resume cannot reroll/grant/replay;
- Reduced has zero plugin work and same truth;
- no direct plugin access in ceremony files.

## Global
- Phase 1 static boundary still PASS;
- no direct plugin reference outside adapter;
- no prohibited GFF effect reachable;
- no global Spark.clear;
- plugin-absent fallback preserves Results + pack flow.

---

# 8. Regression battery

Run at minimum:

- `tests/m43_c005f_phase1_foundation.gd`
- new Phase 2 focused suite
- Results foundation
- WON Results visual
- Results momentum
- Pack Standard ceremony tests
- Premium pack tests
- card-state celebration tests
- pack atomicity/idempotency tests
- M39 pack/economy regressions
- M40 save regressions
- M41 Reduced Effects
- popup/modal regressions
- navigation/terminal regressions
- root `tests/run_tests.gd`
- headless import/boot
- `git diff --check`

No unexplained SCRIPT ERROR.

---

# 9. Runtime evidence

Produce real runtime evidence for owner review.

At minimum:

Results WON:
- FULL
- REDUCED

Standard pack:
- FULL final reveal/hold
- REDUCED final reveal/hold

Premium pack:
- FULL final reveal/hold
- REDUCED final reveal/hold

Capture at the canonical project viewport and at least one alternate phone/tablet aspect if the harness supports it without changing production geometry.

Evidence must come from real shipping nodes/models, not a fake decorative mock.

The visual owner gate remains open after Claude implementation. Claude cannot self-approve visuals.

---

# 10. Logs

Write child logs:

- `coordination/sessions/M43-C005F-PHASE2/logs/SB-M43-C005F-003_CLAUDE_LOG_V01.md`
- `coordination/sessions/M43-C005F-PHASE2/logs/SB-M43-C005F-004_CLAUDE_LOG_V01.md`
- `coordination/sessions/M43-C005F-PHASE2/logs/SB-M43-C005F-005_CLAUDE_LOG_V01.md`

Master log:

`coordination/sessions/M43-C005F-PHASE2/M43_C005F_PHASE2_MASTER_CLAUDE_LOG_V01.md`

Each child log:
- start/final SHA;
- exact files changed;
- authority seam used;
- event-key/idempotency contract;
- FULL/REDUCED behavior;
- tests;
- runtime evidence;
- blockers/deviations.

Master log:
- ordered child outcomes;
- implementation commit(s);
- final changed-file list;
- explicit no-R2/no-LF proof;
- root regression;
- Phase1 regression;
- visual evidence index;
- final Git parity;
- truthful owner-local sync state.

Do not edit root `TASKS.md`.

If technical implementation is complete:

`AWAITING_GPT_M43_C005F_PHASE2_AUDIT_AND_OWNER_VISUAL_REVIEW`

If a genuine authority/art/runtime blocker exists, stop only the affected child, continue safe independent children, and end with the exact blocker.
