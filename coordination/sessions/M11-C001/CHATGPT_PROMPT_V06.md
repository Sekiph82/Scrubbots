# M11-C001 — Strict V05 Evidence Hardening V06

Status: **ISSUED — VALIDATION-ONLY CLOSURE PASS**

This continues the same frozen M11 finding set. It does not add a new production
finding.

Read:
- coordination/AUDIT_POLICY.md
- coordination/AUDIT_INDEX.md
- coordination/VERSIONED_LOG_POLICY.md
- coordination/sessions/M11-C001/CHATGPT_FULL_SURFACE_REAUDIT_V02.md
- coordination/sessions/M11-C001/CHATGPT_PROMPT_V05.md
- coordination/sessions/M11-C001/CHATGPT_AUDIT_CRITERIA_V05.md
- coordination/sessions/M11-C001/CLAUDE_LOG_V05.md
- coordination/sessions/M11-C001/CHATGPT_AUDIT_V05.md
- this prompt + V06 criteria

Expected Claude evidence:
`coordination/sessions/M11-C001/CLAUDE_LOG_V06.md`

## Objective

Harden the V05 adversarial tests so every remaining material M11 behavior is
directly observable and sensitivity-safe under Strict Audit Standard v2.

The V05 production implementation is currently source-accepted.

**Do not modify production gameplay/session code unless a strengthened V06 test
first exposes a real defect.** If that happens, record the exact failing test,
the observed defect and the minimal frozen-scope fix in CLAUDE_LOG_V06.

Do not implement M12+ features.

## 1. Post-reset LevelData source truth

Strengthen M11 detached-source tests.

Required sequence:
1. load a valid rectangular level;
2. save every original LevelData field:
   - version
   - id
   - display_name
   - difficulty
   - width
   - height
   - palette
   - cells
3. obtain a snapshot;
4. hostile-mutate scalars, replace packed arrays and mutate packed arrays in-place;
5. reset;
6. verify fresh BoardState dimensions and color IDs match the ORIGINAL;
7. **after reset**, call get_level_data() again;
8. verify every field and both packed arrays still exactly match the ORIGINAL.

Strengthen the failed replacement case:
- compare every LevelData field before/after the failed replacement;
- BoardState object identity/state must remain unchanged.

## 2. Counting real renderer spy

Extend or replace the V05 real BoardRenderer spy so it directly records:
- configure_calls;
- last_board;
- last_palette;
- last_size.

It must remain a genuine BoardRenderer subclass and call super.configure().

Do not use a partial fake for positive-path sensitivity checks.

## 3. Malformed renderer replacement sensitivity

Required:
1. load valid level;
2. bind the counting real renderer with valid size;
3. record configure_calls;
4. attempt int/String/Vector2/RefCounted/partial-fake replacements;
5. every attempt returns false;
6. partial fake configure_calls remains zero;
7. reset the session;
8. ORIGINAL valid renderer configure_calls increments exactly once from the
   pre-reset count, proving the prior valid binding survived;
9. bind null;
10. reset again;
11. original renderer configure_calls does NOT increment, proving explicit
    unbind actually removed it.

## 4. Invalid renderer-size direct observability

Do not use is_inside_tree() as evidence that configure was not called.

Using a counting real renderer, directly prove configure_calls does not change
for invalid size.

Cover both axes, including:
- Vector2(NAN, positive)
- Vector2(positive, NAN)
- +INF in x and y
- -INF in x and y
- zero x with positive y
- positive x with zero y
- negative x with positive y
- positive x with negative y

Then prove preservation:
1. bind original real renderer with valid size A;
2. record its configure count and last_size;
3. attempt to bind another real renderer with invalid size;
4. replacement returns false;
5. replacement renderer configure_calls remains zero;
6. reset;
7. original renderer configure_calls increments;
8. original renderer last_size remains size A.

## 5. Freed renderer lifecycle reuse

Retain V05 freed-renderer reset and replacement-load cases.

Add:
- after a stale renderer has been encountered/dropped, bind a fresh real counting
  renderer;
- reset or load as appropriate;
- prove the fresh renderer is configured and the session remains READY.

No call may be attempted on the freed instance.

## 6. Palette isolation across initial configure, rebind and reset

Required:
1. load valid level and save original source palette;
2. bind real spy A;
3. mutate spy A's retained last_palette in-place;
4. verify session source palette remains original;
5. bind real spy B (renderer rebind);
6. verify session source palette remains original;
7. mutate spy B's retained last_palette in-place;
8. reset;
9. verify session source palette remains original;
10. verify spy B was reconfigured and receives a fresh original-valued palette.

No LevelData object may be handed to renderer.

## 7. Regression

Preserve the complete V05/M11 regression matrix:
- lifecycle transitions;
- reset states;
- explicit completion only;
- no auto-completion;
- valid renderer tracks current/new BoardState;
- rectangular board;
- 59x59;
- independent sessions;
- no M12+ responsibility leakage;
- no win/lose/timer/move-limit invention.

## Governance

Do NOT modify:
- tasks.md
- .hiveai/*
- coordination/SESSION_INDEX.md
- coordination/AUDIT_INDEX.md
- coordination/STRICT_FOUNDATION_REPAIR_QUEUE_V01.md
- coordination/STRICT_UPSTREAM_REPAIR_SEQUENCE_V01.md
- any CHATGPT_* file

Run and record individually:
- godot --version
- full headless suite
- git diff --check

Write:
`coordination/sessions/M11-C001/CLAUDE_LOG_V06.md`

Commit/push safely.

Return exactly:
`AWAITING_AUDIT`

Then STOP.
