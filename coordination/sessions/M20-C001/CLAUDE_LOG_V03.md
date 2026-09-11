# CLAUDE_LOG_V03 — M20-C001 Exact Dependency / Exact-State Closure

- Cycle: M20-C001
- Prompt: `coordination/sessions/M20-C001/CHATGPT_PROMPT_V03.md`
- Audit criteria: `coordination/sessions/M20-C001/CHATGPT_AUDIT_CRITERIA_V03.md`
- Freeze: `coordination/sessions/M20-C001/CHATGPT_FULL_SURFACE_REAUDIT_V03.md`
- V02 audit basis: `coordination/sessions/M20-C001/CHATGPT_AUDIT_V02.md`
- Actor: CLAUDE (implement + test only). Handoff: AWAITING_AUDIT.
- Engine: Godot `4.7.1.stable.official.a13da4feb`
- Starting `origin/main`: `8807521` (V03 prompt + criteria issued)
- Tracker start transition (IN_PROGRESS): `c6c6843`
- Result: full headless suite **3533 / 3533 PASS**, exit 0 (V02 baseline 3501).
  Dedicated deferred-free smoke passes separately.

Claude did NOT modify any `CHATGPT_*` artifact, audit verdict, SB-M20 checkbox,
`.hiveai/*`, `coordination/SESSION_INDEX.md`, or unrelated production. The ONLY
production file changed is `complete_clearing_loop.gd` (§13). Pre-existing owner
working-tree changes preserved and left unstaged.

## 0. Tracking / start-order (§0)
1. Synced `origin/main` fast-forward (`949798f..8807521`), owner work preserved.
2. Verified `CHATGPT_AUDIT_V02.md` + V03 freeze/prompt/criteria present on synced main.
3. Verified root `TASKS.md` still at M20-C001 V02 / AWAITING_AUDIT / CHATGPT.
4. Set Project Status to M20 / M20-C001 V03 / IN_PROGRESS / CLAUDE.
5. Committed + pushed the tracker-only transition (`c6c6843`) BEFORE any V03 edit.
6. Verified remote `origin/main` carried IN_PROGRESS.

## Files changed (excluding auto `.uid`)
- `scripts/gameplay/clearing/complete_clearing_loop.gd` — exact-script identity
  for ColorCandidateIndex + ReservationState (single coherence probe, category is
  the guard); exact detached reservation OWNER MAP in the pre-state snapshot;
  exact resolve postcondition (owner-map == pre − target); exact rollback verify
  (owner-map == pre-snapshot); current-arrival dedup (`_current_owner`/
  `_current_agent`).
- `tests/run_tests.gd` — reworked the V02 seam-binding tests for the exact
  boundary (`_run_m20_v02_bind_transaction_tests` now proves exact-category
  accept/reject); added a test-only `_m20_harness_bind` (V03 §4) so rollback/
  serialization sensitivity keeps running WITHOUT widening production bind; routed
  the V01/V02 seam tests through it; added 3 V03 sections (exact reservation
  snapshot/rollback, unrelated candidate truth + single-cell path, current-arrival
  dedup).
- `tests/support/m20_candidate_seam.gd` — added `unrelated_loss` mode.
- `tests/support/m20_reservation_seam.gd` — added `identity_swap` mode.
- `docs/02_TECH_ARCHITECTURE.md` — records exact-category bind + owner-map exactness.
- `TASKS.md` — Project Status lifecycle only (IN_PROGRESS → AWAITING_AUDIT).
- `coordination/sessions/M20-C001/CLAUDE_LOG_V03.md` — this log.

No `ScrubbotDispatcher` / M13 / M14 / any other upstream production change (§13).
No temporary upstream source mutation was needed — the test-only harness (§4)
covers rollback sensitivity, so no pre/post blob-hash restoration applies.

## Pre-fix sensitivity (§3), now closed
Derived from the V02 source (git `949798f`), superseded here; the V03 tests are the
executable proof of each fix:
- **Candidate coherence spoof** — under V02 the candidate was a subclass-open
  category, so a spoofing `is_bound_to` subclass could reach the probe; V03 rejects
  any candidate subclass at the exact-script gate BEFORE `is_bound_to` is ever
  called. Proven: `_run_m20_v02_bind_transaction_tests` arms the seam's
  coherence hook and asserts it is NEVER invoked (rejected at category), no signal
  bound, loop unbound.
- **Reservation identity-swap mutate-false** — V02's reservation postcondition and
  rollback verify used `get_reservation_count() == pre − 1` (count only), so a fault
  that resolves T, drops unrelated U and re-owns ownerU on V (count unchanged)
  would have been reported as ordinary `RESERVATION_ROLLBACK` with U/V identity
  wrong. V03 captures a detached owner map and verifies it exactly, so this now
  surfaces `ROLLBACK_FAILED`. Proven: `_run_m20_v03_exact_reservation_state_tests`
  identity-swap case → `ROLLBACK_FAILED`, T rolled back to ACTIVE, cleared 0.
- **Candidate unrelated-loss mutate-false** — the verified rollback restores the
  full candidate truth (single-cell sync, else `rebuild()`/`rebind()` recovery),
  so removing T and unrelated same-color U then failing still restores BOTH.
  Proven: `_run_m20_v03_unrelated_truth_tests` unrelated-loss case → both T and U
  candidates restored, `CANDIDATE_ROLLBACK`.

All pre-fix instrumentation is test-only (support subclasses driven through the
harness); no production dependency polymorphism remains at the M20 bind boundary.

## Evidence mapped to prompt sections

### §1 Preserve accepted V02 architecture
Serialized activation, lossless FIFO arrivals, transactional deferred reset,
BoardState→candidate→reservation→dispatcher→renderer order, authenticated M19
bridge, renderer post-commit, 1×1/second-B/five-slot/queue-free coverage, and the
M19 queue_free reset hardening are all unchanged in semantics and still green.

### §2/§9 Exact dependency trust boundary
`bind()` requires exact production script identity for candidate and reservation
(same policy as the other canonical collaborators). Tests
(`_run_m20_v02_bind_transaction_tests`): exact ColorCandidateIndex + ReservationState
accepted; candidate subclass rejected before callback; reservation subclass
rejected before callback; rejected subclass binds no arrival signal; failed bind
fully unbound; original exact bundle works end-to-end; ordinary second bind
preserves; same-size different-board exact candidate/reservation cannot commit;
non-exact board rejected. Single coherence probe (category is the guard; no
repeated-probe folklore); the `_in_bind` guard remains defence-in-depth.

### §4 Rollback sensitivity out of production polymorphism
Production bind rejects `M20CandidateSeam` / `M20ReservationSeam`. Their rollback
sensitivity runs through the test-only `_m20_harness_bind` (wires loop internals,
never calls `bind()`, never widens categories). Historical V01 rollback doubles
retained but routed through the harness too.

### §5/§6 Exact reservation snapshot / postcondition / rollback
Snapshot captures a detached sorted reserved set + owner map + count + pair. After
a successful `resolve_arrival` the owner map must equal exactly `pre − target`
(target owner −1, owner target −1, every unrelated reserved target same owner, no
new reservation). Rollback verify requires the owner map to equal the pre-snapshot
map exactly (else `ROLLBACK_FAILED`). Healthy path does NOT reset/rebuild all
reservations. Tests: `_run_m20_v03_exact_reservation_state_tests` (happy-path
owner-map exactness with an unrelated reservation preserved; identity-swap →
`ROLLBACK_FAILED`).

### §7 Candidate single-cell perf + unrelated truth
No O(board) candidate snapshot on the normal path (the owner map is O(reservations)
only). `_run_m20_v03_unrelated_truth_tests`: two same-color candidates before one
clear; clearing T removes only T and leaves same-color U; other-color bucket
unchanged; rollback of T leaves U unchanged; 59×59 normal clear changes exactly one
cell (single-cell sync, no M20 board scan).

### §8 Current-arrival dedup
`_current_owner`/`_current_agent` published while `_run_transaction` executes;
`_enqueue_arrival` drops a duplicate of the current or an already-queued
owner+agent; FIFO preserved for distinct arrivals; identity cleared after every
outcome and on reset; nothing public exposes the queue/identity. M19 bridge
unchanged. Test: `_run_m20_v03_current_arrival_dedup_tests` (duplicate of the
in-flight arrival dropped, A cleared exactly once); distinct FIFO still proven by
`_run_m20_v02_serial_arrival_tests`.

### §10 Preserve rollback/postcondition outcomes
All stable outcomes retained (BOARD_WRITE_FAILED, BOARD_POSTCONDITION_FAILED,
CANDIDATE_ROLLBACK, RESERVATION_ROLLBACK, FINALIZE_FAILED, RESET_ABORTED,
ROLLBACK_FAILED, CLEARED, PREFLIGHT_REJECTED). Ordinary rollback is reported only
when exact verification succeeds; otherwise ROLLBACK_FAILED.

### §11/§12 Direct-observability + upstream regression
Re-ran the full V01/V02 direct-observability suite (1×1, full AL-028 second-B,
five-slot identity, first-of-five preserves others, failed-preflight reset
recovery, reset during candidate/reservation transaction, nested distinct arrival
FIFO, renderer rollback opaque, queue-free smoke, one-color exhaustion,
multi-color, Easy/Medium/Hard/Very-Hard, 59×59, rectangular, rapid 25+). Every
upstream strict suite (BoardState, renderer, M11–M18, all M19 V01–V06) still green;
the only V02 test adjustments are the seam-binding tests now routed through the
harness (the seams are no longer claimed valid production collaborators).

## Validation (§14, run individually)
- `godot --version` → `4.7.1.stable.official.a13da4feb`.
- `godot --headless --path . -s res://tests/run_tests.gd` → `Total checks: 3533 /
  Failures: 0 / RESULT: ALL PASS`, exit 0.
- `godot --headless --path . -s res://tests/m20_queue_free_smoke.gd` → PASS, exit 0.
- `git diff --check` → clean (only benign LF→CRLF advisories on pre-existing
  owner-modified files).
- Changed files: see above. Only `complete_clearing_loop.gd` is production.
- Scope grep of the loop: forbidden win/scoring/session/queue/cooldown terms appear
  only in the exclusion comment.
- TASKS lifecycle: before = V02/AWAITING_AUDIT/CHATGPT; start = V03/IN_PROGRESS/
  CLAUDE (`c6c6843`); after = V03/AWAITING_AUDIT/CHATGPT.
- No temporary upstream mutation used (harness path), so no blob-hash restoration.

## Governance / handoff (§13/§15)
Modified only authorized surfaces. Did NOT mark COMPLETE/READY_FOR_NEXT_TASK or any
SB-M20 checkbox. Progress unchanged (290/719 main+ui; 290/943 overall;
lastCompletedTaskId M19-C001-V06). Tracker set to AWAITING_AUDIT / CHATGPT.
Implementation + tests + log + tracker handoff committed and pushed; remote verified.

Return: `AWAITING_AUDIT`.
