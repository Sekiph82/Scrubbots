# M15-C002 — CLAUDE_LOG_V02

Cycle: **M15-C002** · Prompt: `CHATGPT_PROMPT_V02.md` · Task: **M15-C002-V02**
Finding set (frozen, same): **F-M15-STRICT-004**, **F-M15-STRICT-005**
Actor: CLAUDE · Handoff: **AWAITING_AUDIT** (no self-audit verdict claimed)

## 1. Environment / sync

- Godot: **4.7.1.stable.official.a13da4feb**.
- Synced starting `origin/main` SHA: **a298af7d2e258aaebf818179d47b658ee4139dd6**
  (fast-forward from `c30b802`→…→`a298af7`; incoming M15-C002 V01 audit + V02
  prompt/criteria did not touch any locally-modified file).
- Canonical state on sync matched the prompt (currentTaskId `M15-C002-V02`,
  workflowState `CHANGES_REQUIRED`, requiredActor `CLAUDE`, progress
  `278/719 = 38.66%`) → no `HIVEAI_STATE_CONFLICT`.
- Pre-existing owner working-tree changes preserved and NOT staged:
  `project.godot`, `scenes/debug/routing_prototype_lab.tscn`,
  `scenes/debug/scrubbot_agent_debug.tscn`, plus untracked `.uid`/asset files.

### Process note (honest disclosure)

In this session the local production/test edits were written before the
`IN_PROGRESS` start-transition commit was pushed. The durable pushed ordering is
correct — the `CHANGES_REQUIRED → IN_PROGRESS` tracker commit
(**58d6777**, `a298af7..58d6777`) was pushed BEFORE any implementation/test
commit — but the strict "arm IN_PROGRESS before editing locally" ordering was
not followed to the letter. No implementation was pushed ahead of the start
transition.

## 2. V02 pre-fix sensitivity (prompt §9 / criteria 8–17)

A temporary probe (`tests/m15_c002_v02_prefix_probe.gd`, since deleted) ran the
seven remaining classes against the **V01 source at commit
`5a2ed2765a1d2d77578223f88e2b456d2709d985`** (copied to a temp res:// path) using
the new injection hooks on the M15 doubles. Exact pre-fix outcomes:

| # | Class | Pre-fix outcome (V01) |
|---|-------|-----------------------|
| 1 | nested bind from INITIAL candidate `is_bound_to` callback | nested bind returned **true**; selector moved OFF bundle A |
| 2 | nested bind from INITIAL reservation `is_bound_to` callback | nested bind returned **true**; selector moved OFF bundle A |
| 3 | recursive `select_and_reserve()` from targetability callback | nested returned real target **0**; reservation count **2** (extra reservation) |
| 4 | `is_reserved()==true` + candidate drift | `is_reserved` called **2×** — proceeded to query the next candidate under drift |
| 5 | `reserve()` stores exact pair then returns int `1` | exact pair **leaked** (count **1**) — no rollback |
| 6 | exact pair stored + malformed `get_owner()` | exact pair **leaked** (count **1**) — rollback blocked by the failing query |
| 7 | same-owner side effect + `false` targetability, later free candidate | queried later candidate idx1 = **true** — escaped the no-later-query law |

Verdict: **M15-C002 V02 DEFECT CONFIRMED** on all seven remaining classes.
These are the exact gaps named in `CHATGPT_AUDIT_V01.md`
(F-M15-STRICT-005.A/.B/.C/.D/.E/.F/.G, F-M15-STRICT-004.A). Correction was applied
only after these outcomes were recorded.

Post-fix, the same seven all pass (see §4 permanent coverage): nested bind
returns false / selector stays on A; recursion returns -1 / no extra reservation;
is_reserved-true drift stops after one call; reserve-after-store and
malformed-get_owner both roll back the exact pair (count → unrelated-only);
same-owner side effect stops with no later query.

## 3. Frozen minimal correction (production)

Only `scripts/gameplay/targeting/target_selector.gd` changed.

- **§1 / 005.A — guard armed before first callback.** `select_and_reserve()`
  now returns `-1` immediately if `_in_selection` is already true, then arms
  `_in_selection = true` BEFORE the initial `_op_coherent()` (which invokes the
  candidate/reservation `is_bound_to()` callbacks). The initial coherence probe
  moved into `_select_core`, so the single deterministic exit path clears the
  guard on every return, including initial-coherence failure (no stuck-busy).
- **§2 / 005.B — recursive selection blocked.** The top-of-function
  `_in_selection` check rejects any nested `select_and_reserve()` injected from a
  targetability/candidate/reservation callback.
- **§3 / 005.G — bind-in-progress guard.** Added `_in_bind`. `bind()` returns
  false when `_in_selection or _in_bind`, arms `_in_bind` before the coherence
  callbacks (extracted into `_bind_validate_and_commit`), and clears it on every
  exit. A callback-triggered nested bind cannot commit ahead of / over the outer
  bind; ordinary failed-bind neutralization outside re-entry is unchanged.
- **§4 / 005.C — coherence after `is_reserved`.** The operation-coherence
  re-check now runs immediately after `is_reserved()` for BOTH true and false,
  before branching, so a drift + `reserved==true` stops before the next candidate.
- **§5 / 004.A/005.D — malformed reserve after mutation.** A non-bool `reserve()`
  return now triggers an exact-pair `release(idx, owner_id)` before returning
  `-1` — the malformed return is never taken as proof nothing was stored.
- **§6 / 005.E — rollback independent of ownership query.** `_rollback_own()`
  now calls the canonical exact-pair `release(idx, owner_id)` directly and no
  longer gates on `get_owner()`; canonical `ReservationState.release()` removes
  the entry only when idx is owned by exactly owner_id, so it never erases another
  owner's reservation or a different target, and a malformed ownership query can
  no longer block rollback.
- **§7 / 005.F — owner recheck after targetability.** After the targetability
  callback + coherence check, the selector validates `get_target_for_owner(owner_id)`
  as TYPE_INT and returns `-1` (preserving the external reservation, querying no
  later candidate) whenever the owner has been assigned — regardless of whether
  the verdict was true, false, or non-bool.

All V01 hardening (§8) preserved: real-BoardState bind category, RefCounted dep
categories, actual-bool coherence/targetability gates, dynamic-return validation,
non-int candidate-entry guard, immutable operation snapshot, post-reserve exact
ownership proof, rebind detection, contention semantics, deterministic order,
no routing / no board or candidate mutation / no full-board scan, and the
`is_bound_to(board, reservation_state)` identity seam.

## 4. Adversarial coverage added (validation-first)

`tests/run_tests.gd` → `_run_target_selector_strict_v04_tests()` (registered
after the V01 `_run_target_selector_strict_v03_tests` block). New injection hooks
on the narrow M15 doubles make the audit's direct-observability gaps testable:
- `tests/support/m15_reservation_double.gd` — `on_is_bound_to`, `on_owner_query`,
  `on_reserved_snapshot`, `on_is_reserved` hooks; `target_for_owner_force_after_reserve`
  (malformed proof only after reserve).
- `tests/support/candidate_index_double.gd` — `on_is_bound_to`, `on_get_candidates`.
- `tests/support/m15_variant_access.gd` — `on_query` side-effect hook.

Coverage: initial-coherence nested bind (candidate + reservation) returns false /
bundle preserved / B empty / later clean select works; initial-coherence failure
clears guard; recursive select from targetability / candidate-query / owner-query
callbacks → -1, no extra reservation, later recovery; bind-in-progress nested bind
→ false / commit-once; coherence after `is_reserved==true` (one call, stops);
direct drift on candidate-query / reserved-snapshot / owner-query → -1 before next
phase; malformed-reserve-after-store exact-pair rollback with unrelated
reservation preserved; malformed `get_owner` / malformed `get_target_for_owner`
proof both remove the exact pair; other-owner-at-target preserved; same-owner side
effect with false and non-bool verdicts → -1 / no later query / external kept;
malformed owner query after targetability fails closed.

## 5. Validation results

- Full root suite: `godot --headless --path . -s res://tests/run_tests.gd`
  → **Total checks: 2984 · Failures: 0 · RESULT: ALL PASS**
  (V01 baseline 2941/0; +43 new V02 checks).
- Zero SCRIPT/Parse errors.
- `git diff --check`: clean (only benign LF→CRLF notices).
- Pre-existing renderer-test resource-leak WARNINGs unchanged and unrelated.

## 6. Scope / governance

- Production changed: `scripts/gameplay/targeting/target_selector.gd` only.
- Tests/support changed: `tests/run_tests.gd`,
  `tests/support/candidate_index_double.gd`,
  `tests/support/m15_reservation_double.gd`,
  `tests/support/m15_variant_access.gd`.
- Not touched: BoardState, ColorCandidateIndex, ReservationState, M19 dispatcher,
  routing, ScrubbotAgent production; root `tasks.md` checkboxes;
  `coordination/AUDIT_INDEX.md`; any `CHATGPT_*` artifact; legacy H!veAI trackers;
  `.hiveai/PROJECT.json`/`.hiveai/RULES.md`.
- No self-audit verdict; audit disposition is ChatGPT-owned.

## 7. Commits / events

- Start transition: **58d6777** (`CHANGES_REQUIRED -> IN_PROGRESS`), pushed
  `a298af7..58d6777`, event id `61b7d65b-ba7b-4665-8966-6564ad536b9c`.
- Implementation + AWAITING_AUDIT handoff: pushed after this log; see
  `.hiveai/EVENTS.jsonl` `IN_PROGRESS -> AWAITING_AUDIT` row
  (`2be49e9a-456a-42bc-a3b3-4585e97b7b37`). Per the non-self-referential final-SHA
  rule, no extra commit is made solely to embed this log's own commit SHA.

Handoff state: **AWAITING_AUDIT** (requiredActor CHATGPT).
