# M46-RM-002 — Cross-milestone adversarial validation — CLAUDE LOG V01

**Prompts:** `CHATGPT_M46_MASTER_REMEDIATION_V01.md` → child `CHATGPT_M46_RM002_BOOSTER_WORKER_UI_ADVERSARIAL_PROMPT_V01.md`, criteria `CHATGPT_M46_RM002_BOOSTER_WORKER_UI_AUDIT_CRITERIA_V01.md`.

**Evidence level:** implementer E1/E2 only, written and run by Claude. This is not an audit verdict, and no criterion is closed here. Root `TASKS.md` was not edited.

**Source:**
- Production code is unchanged since R07 `76e4aff8` (+ slot fidelity `007cbaec`, R06 `63a0c454`). RM-001 and RM-002 change tests only.
- Every mutation below was restored byte-identical: the tracked `scripts/` diff is empty and grep finds no markers.
- Final test SHA: **`0fa6ee247fe5e5f088975c0713b0386d7c94a851`** (RM-002 suite plus the RM-001 hardening).

**Environment:**
- Godot 4.7.2 headless, one Windows desktop CPU.
- **No GitHub Actions.** Both workflow jobs keep `if: ${{ false }}` (Android validate, Android export, iOS IPA); the `.github` diff is empty.

## 1. New suite — `tests/m46_rm002_adversarial.gd`
Real production hosts (L1 via AppState, 59×59 stripes) and the real app (`main.tscn`, 1080×2160, rewarded provider double).
- **8 case groups.** The suite fails unless all 8 complete.
- Helper results are asserted by the caller, so a script error inside a helper cannot pass silently.

**Final run** (`godot_console --headless --path . -s res://tests/m46_rm002_adversarial.gd`): **`M46 RM002 ADVERSARIAL: PASS (8 case groups)`, exit 0.**

| Group | What is directly observed |
| --- | --- |
| T02 L1 | A real off-frame Random proof settles into the cache. Then exactly **one** dimension changes per trial, and the cached Random + Selector verdicts must be invalidated: board cell cleared, board restored (revision is monotonic), supply FIFO order, occupied-slot remaining, WAITING↔ACTIVE, placement sequence, 5→6 capacity. All **10/10** checks were reached. Verdicts are injected through the real `put_verdict`, so this tests **state-key completeness**; only Random also gets a real proof. |
| T02 `_next_sequence` | Not in the key, by design. Direct invariant: scratch next sequence > every live sequence, before and after +5. **Negative control:** a value at the live maximum is detected. Supporting: unbudgeted Random / Selector-list verdicts are identical (on an easy L1 state this discriminates little; the invariant carries the claim). |
| T02 59×59 | With robots moving, the cache never answers and no off-frame proof is needed (in-flight shortcut). At a still moment with an occupied, not yet dispatched slot: the same 10/10 invalidations. |
| T03 race matrix (59×59 long worker) | **immediate** cancel (join 2.69 ms); **mid-run** (task asserted still running; join 2.62 ms); **at completion**, i.e. finished but not yet polled (forced 1 ms cap, main thread blocked until the task is complete); **twice** (second cancel is a no-op, no extra settle); **Retry**; **different booster** (Random → Selector: one worker, the old one stopped silently); **same-booster reuse** (task unchanged); **injected null result** (a crashed `run_offframe`). Each leaves 0 workers and no stray verdict, and settles exactly once per real cancel. The null result is cached as the cap running out, with no restart. |
| T01 | A zero-charge SB buy pressed while "Checking..." is refused (blocked action): SB / charges / supply unchanged, `live_proof_count` unchanged. After the proof, SB buy-and-use spends the price exactly once and reorders the supply. |
| T06 abort before grant | Ad cancelled while checking: no grant, no receipt, auto-use never armed, nothing used after the proof, no main-thread proof. |
| T06 duplicate settle | A second `booster_proof_settled` in the same frame gives **exactly one execute**: the supply is reordered once (a second Random reversal would restore it), charge 1→0, one receipt, popup closed. |
| T06 late close | Proven: the auto-use **was scheduled** (verdict proven legal, flag consumed); the popup was then closed before the deferred call. The deferred auto-use does not fire, the granted charge is kept, the supply is untouched. |
| T06 FTUE moving + Home | With robots moving, the L2 coach copy uses the in-flight shortcut and starts no worker. **Route to Home mid-check:** a settle watcher (after the coach listener) shows the worker cancelled and joined, nothing restarted, no main-thread proof (the host is freed). |

**Earlier same-day run of the first suite version** (before the peer-review hardening): PASS 8/8 in the sequential regression batch (§4).

## 2. Negative controls — T07 / RM002-09
Temporary production-source mutations, marked `RM002MUT-*`. Each was restored, and the tracked diff and grep were re-checked.

| # | Mutation | Target test | Result (fails for that invariant) |
| --- | --- | --- | --- |
| a | `cached_verdict` ignores the state-key comparison | m46_rm002 | both T02 state-key assertions FAIL (L1 and 59×59). **Re-run on the final suite:** FAIL again. |
| b | WAITING restoration dropped in `_scratch_slots_from_live` | m46_slot_rebuild | `scratch rebuild == live slots` FAIL at 5 and 6 slots |
| c | deferred auto-use without the open / top / not-busy check | m46_rm002 | `late close …` FAIL. **Re-run on the final suite:** FAIL again. |
| d | double earned grant (an extra `add_charges` in `_apply_reward_outcome`) | m46_r07 | **FAIL (11)**: every charge / receipt assertion on the rewarded path |
| e | main-thread legality restored in rewarded completion **and** FTUE `step_copy` | m46_r07 (final version) | **FAIL (14)**: every "no main-thread proof" assertion in both flows, including the FTUE exit case |

**Not run as a mutation: "take a charge on proof_timeout".** The economic seam is `booster_service` reserve-after-proof, already exercised by p21's forced-timeout SB and charge paths. The rewarded-timeout path is covered by m46_r07, where mutation (d) shows those charge assertions are live.

## 3. Criterion ledger
| Criterion | Status | Evidence / gap |
| --- | --- | --- |
| RM002-01 59×59 legal + illegal boosters, 5/6, open / close / retry, conservation, wallet isolation | **PARTIAL** | p17 (+1 refused / bought once / 7th refused / Tornado owned / terminal refusals / retry → 5), p20 (Random / Selector legal + not-eligible refusal, conservation, isolated economy), p21, p22. **Gaps:** no illegal Tornado / +1 popup open / close at 59×59; no single per-booster ledger table across all four. |
| RM002-02 safe iff current DeadlockClassifier eligibility; 92-id equivalence; malformed / null; error vs timeout | **PARTIAL + AUDITOR DECISION** | p20 (92-id equivalence, in-flight shortcut exactness, null-mirroring); p22 / m46_slot_rebuild (detached copy == live, malformed slot null). **Error vs timeout is not distinguished:** a worker that ends without a result is recorded as the cap running out (fail closed), and so is the T03 null-result row. This is deliberate R06/R07 production behaviour, flagged for ChatGPT. **Not tested:** `detached_copy() == null` → R05 400 ms fallback (F07). |
| RM002-03 every proof-relevant mutation invalidates the cache | **PASS (scoped)** | T02 (10/10 on L1 and 59×59), mutation (a); `_next_sequence` exclusion backed by the invariant + negative control; real-worker stale settle in p22 and m46_r07. |
| RM002-04 one worker, no spurious restart, bounded cancel on close / retry / exit, crash / null | **PASS (scoped)** | T03 (8 rows) + p22 cancel + m46_r07 exit / FTUE exit + route-to-Home. Join ≤ about 5 ms here (p22 5.0–5.2 ms). **Gaps:** a Retry / cancel with a popup *listening* is covered only via the m46_r07 close / reopen flows; replay / next level not tested. |
| RM002-05 400 ms / 5 s, no spend, cached timeout, retry after a move, partial Selector shows only proven chips | **PARTIAL** | p21 (forced timeout, SB + charge paths, no spend, rotation), m46_r07 (timeout cached, reopen, retry after a move), p22 (59×59 Selector partial at the 5 s cap). **Gap:** "only proven chips" is not asserted chip-by-chip at UI level (p22 counts chips; `_selector_legality` builds chips only from proven ids by construction). |
| RM002-06 grant once, consumed once on a positive proof, all lifecycle variants, no target auto-use | **PASS (scoped)** | m46_r07 (13 cases) + T06 abort / duplicate settle / late close + mutation (d). Service-level duplicate provider callbacks are covered by `m43_c003` c19 (3 completions → 1 charge). |
| RM002-07 FTUE A + B without main-thread legality, neutral copy, settle update, Skip Tips / modal / exit / route | **PASS (scoped)**, with **FINDING R2-F1** | m46_r07 FTUE cases + T06 moving / Home + mutation (e). **Terminal:** not reachable with the coach (`_coach_want` returns `{}` at terminal); not tested. |
| RM002-08 scratch fidelity, malformed refuses, `free_slot_if_idle` | **PASS** | m46_slot_rebuild (5/6, remaining, WAITING, sequence, malformed, free-slot) + mutation (b). |
| RM002-09 direct negative controls | **PASS** (a–e run, restored); "charge on timeout" NOT_RUN as a separate mutation | §2 |
| RM002-10 owner-dirty `main.tscn` parity | **`main.tscn` PARITY ESTABLISHED / `project.godot` OWNER_LOCAL_SCENE_REPRODUCIBILITY_OPEN** | Read-only `git diff`: `main.tscn` is an editor re-save only (`load_steps` dropped, uid on the script ext_resource, `unique_id` per node, `key = value` spacing). Same 2 nodes, same script, same property values. `project.godot` differs at runtime: **extra autoload `_mcp_game_helper`** (godot_ai runtime helper; it prints "registered mcp capture" in every run), `godot_ai` editor plugin enabled, `[audio] default_bus_layout` removed, GameFeelFlow autoload by uid. Every local run includes the extra autoload, so byte-level runtime parity with GitHub `main` is **not** proven. Owner files untouched. |
| RM002-11 CPU / worker / UX costs attributed separately | **PARTIAL**, with **FINDING R2-F1** | Worker wait frames, popup build, settle + auto-use commit, cancel / join are reported separately (p22, m46_r07, T03). **Not separately measured:** first Results cold load (p19 reports FULL / REDUCED frame stats only). |
| RM002-12 executed paths counted; no script error or incomplete coroutine as success | **PASS** | Group counter (8/8 required); helper results asserted; per-row branch preconditions (running / not completed) in T03. |
| RM002-13 Need-a-Hand untouched, O1/O2/O3 unchanged, cost freeze | **PASS** | No production diff; `next_start_prover` untouched; caps 400 ms / 5 s unchanged; workflow guards unchanged. |
| RM002-14 Claude log only, AWAITING_AUDIT | **PASS** | This log; no `TASKS.md` edit, no audit file. |

**Spec items without new tests (honest NOT_RUN):**
- **T05:**
  - pocket / winding v2 with all four boosters;
  - a LOSE terminal with boosters;
  - timer / cap exhaustion;
  - rollback after a partial mutation at 59×59.

  Existing coverage: p17 / p20 / p21 at 59×59, and the M39 fault-injection suites (`m39_v02_atomicity`, `m39c`, `m39_v04_*`) for rollback.
- **T04:** null supply / classifier input and the `detached_copy() == null` fallback path were not added.

## 4. Regression batch (sequential, final production code)
Run on HEAD `2aafce17` + the first version of the RM-002 suite; production is identical to the final SHA. CPU load 8% at start, 7% at end.

**All exit 0, PASS:**

| Suite | Result |
| --- | --- |
| m46_rm002_adversarial | 8/8 |
| m46_r07_ui_legality | PASS |
| m46_slot_rebuild | PASS |
| m39c_boosters | PASS |
| m39e_full_matrix | PASS |
| m39_v02_atomicity | PASS |
| m39_v02_capacity | PASS |
| m39_v02_integration | PASS |
| m39_v03_full_surface | PASS |
| m39_v03_integration | PASS |
| m39_v04_integration | PASS |
| m39_v04_tornado_inflight | PASS |
| m39_c003_random_any_booster_rewards | PASS |
| m43_c003_c001_acquisition | 34/34 |
| m43_c004_c001_fail_need_a_hand | 40/40 |
| m43_c005f_phase3_meta_rewards_acquisition | 15/15 (its SCRIPT ERROR lines are the suite's announced spy-plugin fault) |
| m44_ftue | 23/23 |
| m28_c002_c003_final_gate | 22/22 |
| m28_c002_c001_gameplay_v02 | 14/14 |
| m55_core_chaos | PASS |
| m30_completion_authority | PASS |
| m25_c003_exact_prefilter | PASS |
| run_tests | ALL PASS |

**Final full m46 suite on `0fa6ee24`:**
- Command: `godot_console --headless --path . -s res://tests/m46_performance.gd`
- **`PASS (22/22 cases, 0 fail)`, exit 0.**
- 487 s, started 2026-10-17 19:16 +03:00.
- CPU load 5% at start, 6% at end; 4 → 2 other-project Godot processes running.
- See the RM-001 addendum for the values.

## 5. Findings for ChatGPT (no production edits made — stop rule)
- **R2-F1 [PERFORMANCE, pre-existing, not an R07 regression]:** the FTUE L2 coach copy costs **23.3–28.0 ms on the main thread** when robots are moving.
  - It recomputes every `COACH_COPY_REFRESH_MS` = 2000 while the booster tip is visible, so it is a recurring desktop frame over 16.7 ms.
  - **Cause:** in-flight Selector legality (`eligible_safe_batches`) still builds one scratch supply + slot engine per remaining batch before the in-flight shortcut answers (R04 measured about 120–150 ms for a 59×59 popup list).
  - Before R07 the FTUE copy made the same synchronous call (and up to 400 ms when still).
  - Not patched here, per the master.
- **R2-F2 [CRITERION MISMATCH]:** worker error and timeout are treated alike (fail closed, cached as `proof_timeout` for that state). RM002-02 asks for them to be distinguished. **Auditor decision.**
- **R2-F3 [REPRODUCIBILITY]:** the owner-local `project.godot` adds a runtime autoload (`_mcp_game_helper`) and drops the audio bus layout. Every local Godot run in this cycle includes them (RM002-10 OPEN).
- **No source-level economic or solver defect** was reproduced by any adversarial case or mutation.

## 6. Fresh-context `CLAUDE_PEER_REVIEW` (read-only, not ChatGPT) — findings and disposition
| Finding | Disposition |
| --- | --- |
| MAJOR: a helper script error could silently skip assertions | **Fixed:** `_t02_dimensions` returns results asserted by the caller (10 keys); `_free_and_equivalence` returns a bool asserted by the caller. |
| MAJOR: the route-to-Home check could never fail | **Fixed:** settle watcher before `nav.go`; asserts settled, nothing running after, `live_proof_count` unchanged. |
| MAJOR: the `_next_sequence` equivalence cannot discriminate on L1 | **Fixed in substance:** direct invariant + negative control added; equivalence kept as supporting only. |
| MAJOR: the FTUE copy cost is a recurring hitch, so it is not a PASS | **Accepted:** recorded as R2-F1; RM002-07 / RM002-11 carry the finding. |
| MAJOR: error vs timeout criterion mismatch | **Accepted:** R2-F2, auditor decision. |
| MINOR: late close did not prove scheduling; duplicate settle did not prove a single execute; T01 had no `live_proof_count`; `twice` / `same_booster_reuse` / `mid_run` lacked preconditions; assertion text over-claimed | **All fixed** (see §1). |
| MINOR: different-booster recovery not tested; T02 mostly key completeness | **Documented** (§3, RM002-03 / RM002-04). |
| RM-001 MINORs: duplicate-reservation check structural; per-clear detection floor; warm-up uncapped; `project.godot` provenance | **Fixed / documented:** `reserved == agents` (duplicates are structural, claim removed); detection floor (about 4.1 Objects/frame) stated in the test and logs; warm-up capped at 4,800; idle host window raised to 600 frames; provenance disclosed (R2-F3, RM-001 addendum). |
| NITs (comment drift, `_still` after `_tap`, watch press visibility) | **Fixed** (comments updated) or **noted**. |

## 7. JOINT HANDOFF (master): frozen findings F01–F08 → RM logs
**Final pinned SHA for this remediation:** `0fa6ee247fe5e5f088975c0713b0386d7c94a851`.
- Production code is identical to R07 `76e4aff8`; only tests and logs changed.
- Full m46 suite 22/22, exit 0.
- RM-002 suite 8/8, exit 0.
- Regression batch all PASS (§4).

| Finding | Reconciled where | State after this cycle |
| --- | --- | --- |
| F01 no pre-implementation per-task criteria | ChatGPT's retrospective criteria; RM logs map every criterion | Governance history; nothing for Claude to backfill. |
| F02 M46-011 net-only / M46-014 ≥ 15 | RM-001 §1–2 + addendum | Transient Object-creation probe with calibration and controls; density floor 90 from the deterministic peak 114, with a control. **Limitations:** Objects only; per-clear detection floor about 4.1 Objects/frame. |
| F03 no full p01–p22 on the final code | RM-001 §3 + addendum | Two complete 22/22 runs, exit 0 (`884c2348`, final `0fa6ee24`), each with contention disclosed. |
| F04 no adversarial validation; owner-dirty `main.tscn` | RM-002 §1–3; RM002-10 | Adversarial suite + mutations a–e. `main.tscn` parity established. **`project.godot` reproducibility OPEN** (R2-F3). |
| F05 owner / device gates | — | **OPEN:** R06 / R07 F5 visuals (incl. "Booster saved!" next to "Checking..."), phone / GPU / heat, cloud CI frozen. Need-a-Hand is unbudgeted by owner reservation. |
| F06 Claude `TASKS.md` writes | this cycle | No `TASKS.md` edit in RM-001 / RM-002; tracker left to ChatGPT. |
| F07 5 s partial Selector / 400 ms fallback | RM002-05 / RM002-02 | Partial list covered (p22); the `detached_copy() == null` fallback is **NOT_RUN**. |
| F08 test-quality gaps | RM-002 §1–2 | Late callback after close, exit + coach refresh, duplicate settle, payment / receipt mutation (d), and the final-tree mutation run (e) are all done. |

**New findings for the auditor:** R2-F1 (FTUE copy 23–28 ms recurring while robots move), R2-F2 (error vs timeout), R2-F3 (owner `project.godot` runtime autoload).
- None is patched: stop rule.
- No new source economic or solver defect was reproduced.

**Output: `AWAITING_CHATGPT_FULL_M46_REAUDIT`.**

## Footprint
- No temporary scripts remain.
- `user://m46rm002_*` saves and fixtures (and their `.bak` / `.tmp`) are deleted by the suite.
- Background output files were deleted by exact path.
- No owner file was touched; no other agent's process was touched.

**Status: AWAITING_AUDIT** (child RM-002).
