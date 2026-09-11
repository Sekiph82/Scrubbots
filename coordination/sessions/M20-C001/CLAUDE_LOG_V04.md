# CLAUDE_LOG_V04 — M20-C001 Lifecycle / Reset Closure

- Cycle: M20-C001
- Prompt: `coordination/sessions/M20-C001/CHATGPT_PROMPT_V04.md`
- Audit criteria: `coordination/sessions/M20-C001/CHATGPT_AUDIT_CRITERIA_V04.md`
- Freeze: `coordination/sessions/M20-C001/CHATGPT_FULL_SURFACE_REAUDIT_V04.md`
- V03 audit basis: `coordination/sessions/M20-C001/CHATGPT_AUDIT_V03.md`
- Actor: CLAUDE (implement + test only). Handoff: AWAITING_AUDIT.
- Engine: Godot `4.7.1.stable.official.a13da4feb`
- Starting `origin/main`: `07237dd`. Tracker start transition (IN_PROGRESS): `ee51cdf`.
- Result: full headless suite **3563 / 3563 PASS**, exit 0 (V03 baseline 3533).
  Dedicated queue-free smoke PASS; new V04 lifecycle smoke PASS. No SCRIPT/Parse
  error from M20 code (the only ERROR lines are the pre-existing importer
  negative-path file tests).

Claude did NOT modify any `CHATGPT_*` artifact, audit verdict, SB-M20 checkbox,
`.hiveai/*`, `coordination/SESSION_INDEX.md`, or unrelated production. Production
changes are limited to `complete_clearing_loop.gd` and the `scrubbot_dispatcher.gd`
RESET path only (§10). Pre-existing owner working-tree changes preserved/unstaged.

## 0. Tracking / start-order (§0)
1. Synced `origin/main` fast-forward (`28da970..07237dd`), owner work preserved.
2. Verified `CHATGPT_AUDIT_V03.md` + V04 freeze/prompt/criteria present.
3. Verified root `TASKS.md` still at M20-C001 V03 / AWAITING_AUDIT / CHATGPT.
4. Set Project Status to M20 / M20-C001 V04 / IN_PROGRESS / CLAUDE.
5. Committed + pushed the tracker-only transition (`ee51cdf`) BEFORE any V04 edit.
6. Verified remote `origin/main` carried IN_PROGRESS.

## 2. ACTUAL V03-baseline sensitivity (run BEFORE the production correction)
A throwaway `tests/_m20_v04_baseline_TMP.gd` (test-only, deleted after capture; no
production change) was run against the unchanged V03 production. Verbatim output:

```
--- S1: dying Node dependency at/after bind ---
  S1a queued-dispatcher bind() returned: true (is_bound=true)
  S1a NOTE: if true, V03 accepted a dispatcher already queued for deletion (gap).
--- S2: reset() inside the M19 dispatch callback (stale-success window) ---
  S2 activate_slot returned success=true reason=NONE
  S2 post-return dispatcher active=0 reservations=0
  S2 NOTE: success=true here is the stale-success window (M20 reset moved, dispatch still returned SUCCESS).
--- S3: reservation drift before loop.reset() (owner-wide release collateral) ---
  S3 dispatch on board A: success=true owner=0 targetA reserved=true
  S3 rebound reservations to board B; reserve(Btarget, owner)=true ownerOfBtarget=0
  S3 after loop.reset(): B target owner=-1 (expected: preserved==0)
  S3 NOTE: if owner==-1 the V03 owner-wide release_for_owner destroyed the unrelated board-B reservation (gap).
```

Confirmed V03 gaps:
- **S1** — V03 `bind()` accepted a dispatcher already queued for deletion
  (`bind()==true`), because exact-script `get_script()` was called without a
  liveness gate. (A truly-freed dispatcher would additionally have raised a freed-
  object SCRIPT ERROR — covered post-fix by the dedicated lifecycle smoke.)
- **S2** — a `loop.reset()` injected from inside M19 dispatch left `activate_slot()`
  returning `success=true / NONE` even though the M20 reset generation had moved and
  the dispatcher/reservation were already torn down (stale-success window).
- **S3** — after the ReservationState was rebound to board B and re-used the same
  owner token, `loop.reset()` (via the dispatcher's owner-wide `release_for_owner`)
  destroyed the unrelated board-B reservation (`owner -1`).

## Files changed (excluding auto `.uid`)
- `scripts/gameplay/clearing/complete_clearing_loop.gd` — Node-lifetime gate at
  bind (`_is_live_exact_node`) and in `_probe` (`_is_live_node`); reset-law
  guard (`_is_valid_node` before `dispatcher.reset()`); post-dispatch transaction
  bracket in `_activate_core`; header comment fixed to state all-exact categories.
- `scripts/gameplay/dispatch/scrubbot_dispatcher.gd` — RESET path only:
  pair-narrow, board-safe reservation cleanup (exact `(target, owner)` release
  guarded by `is_bound_to(_board)` + both pair directions), replacing owner-wide
  `release_for_owner`. Agent disconnect/cancel/queue-free + `_active` cleanup and
  monotonic owner counter unchanged.
- `tests/run_tests.gd` — V04 sections (Node lifetime, post-dispatch bracket,
  pair-narrow dispatcher reset A–E + monotonicity) + `_m20_full_reset_access`.
- `tests/support/m20_reset_select_access.gd` — NEW ProductionTargetAccess subclass
  with a one-shot dispatch-time hook (M19-callback adversary).
- `tests/m20_v04_lifecycle_smoke.gd` — NEW frame-aware smoke (truly-freed Node).
- `docs/02_TECH_ARCHITECTURE.md` — records the V04 lifecycle/bracket/pair-narrow seam.
- `TASKS.md` — Project Status lifecycle only (IN_PROGRESS → AWAITING_AUDIT).
- `coordination/sessions/M20-C001/CLAUDE_LOG_V04.md` — this log.

## Evidence mapped to prompt sections

### §3 Node lifetime boundary (F-M20-STRICT-001.K)
Bind-time: dispatcher/renderer proven non-null + `is_instance_valid` + NOT
`is_queued_for_deletion` BEFORE `get_script()` (`_is_live_exact_node`); RefCounted
deps keep plain exact-script. `_probe`/`is_coherent` prove dispatcher + optional
renderer live (`_is_live_node`) before their coherence calls. `reset()` calls the
dispatcher only when `_is_valid_node` (queued-but-callable still cleans up;
destroyed is skipped). Stale bind comment corrected to state exact categories with
test-only fault seams. Tests: `_run_m20_v04_node_lifetime_tests` (queued dispatcher/
renderer rejected at bind, no signal; post-bind queued dispatcher → incoherent,
activation closed, reset safe) + `tests/m20_v04_lifecycle_smoke.gd` (truly-freed
dispatcher rejected at bind, and post-bind destroyed dispatcher → incoherent,
activation closed, reset safe — all with zero SCRIPT ERROR).

### §4 Post-dispatch transaction bracket (F-M20-STRICT-002.K)
`_activate_core` now captures `dispatcher.dispatch()`, then: (1) if
`_reset_requested`/generation moved → RESETTING; (2) else re-check live coherence,
and if lost → `reset()` (deterministic cleanup) + COHERENCE_FAILED; (3) only if both
pass return the captured result. Tests `_run_m20_v04_post_dispatch_bracket_tests`:
reset injected from M19 dispatch → RESETTING (not stale SUCCESS), no live
assignment, reservation cleaned, owner id not rewound, later activation recovers;
renderer freed from M19 dispatch → COHERENCE_FAILED, no live assignment/reservation.

### §5 Pair-narrow board-safe dispatcher reset (F-M20-STRICT-006.K)
Per active `(O, T)`: require `reservations.is_bound_to(_board)` ACTUAL bool true,
`get_target_for_owner(O)==T`, `get_owner(T)==O`, then `release(T, O)`; else skip.
Agent cleanup + `_active` clear always run; owner counter stays monotonic. Tests
`_run_m19_v04_pair_narrow_reset_tests` cases A–E: A releases T only; B foreign-board
reservation preserved; C same-index foreign-board preserved; D O-owns-V(!=T)
preserved; E missing reservation not re-invented — in B–E the dispatcher still
clears its agent; plus a monotonic-owner-id check.

### §1/§6/§7/§8 preserved
All accepted V03 behaviour retained; reset/arrival semantics, exact reservation/
candidate truth (owner-map, identity-swap → ROLLBACK_FAILED, unrelated-loss
restore), current-arrival dedup, and the full direct-observability matrix re-run
green. No normal-path full-board rebuild/snapshot added.

### §9 Upstream regression lock
Full root suite green including BoardState, renderer, M11–M18, all M19 V01–V06 and
M20 V01–V03; the pair-narrow change is additive M19 reset hardening (existing M19
reset tests unaffected: in the healthy case pair-narrow releases exactly the same
`(T,O)`).

## Validation (§11, run individually)
- `godot --version` → `4.7.1.stable.official.a13da4feb`.
- V03-baseline S1/S2/S3 → recorded above.
- `godot --headless --path . -s res://tests/run_tests.gd` → `Total checks: 3563 /
  Failures: 0 / RESULT: ALL PASS`, exit 0; zero M20 SCRIPT/Parse error.
- `godot --headless --path . -s res://tests/m20_queue_free_smoke.gd` → PASS, exit 0.
- `godot --headless --path . -s res://tests/m20_v04_lifecycle_smoke.gd` → PASS, exit 0.
- `git diff --check` → clean (only benign LF→CRLF advisories).
- Changed files: see above (production = clearing loop + dispatcher reset path only).
- Scope grep of the loop: forbidden win/scoring/session/queue/cooldown terms only in
  the exclusion comment.
- TASKS lifecycle: before = V03/AWAITING_AUDIT/CHATGPT; start = V04/IN_PROGRESS/
  CLAUDE (`ee51cdf`); after = V04/AWAITING_AUDIT/CHATGPT.

## Governance / handoff (§10/§12)
Modified only authorized surfaces. Did NOT mark COMPLETE/READY_FOR_NEXT_TASK or any
SB-M20 checkbox. Progress unchanged (290/719; 290/943; lastCompletedTaskId
M19-C001-V06). Tracker set to AWAITING_AUDIT / CHATGPT. Noted: a clean V04 is still
not final M20 closure (production changed); ChatGPT will issue an auditor-authored
V05 validation-only gate after a clean V04 source audit. Implementation + tests +
log + tracker handoff committed and pushed; remote verified.

Return: `AWAITING_AUDIT`.
