# M46 R02 — CLAUDE_PEER_REVIEW_R02 V01

**Type:** `CLAUDE_PEER_REVIEW`. The reviewer was a new, distinct, fresh-context Claude subagent (`feature-dev:code-reviewer`), separate from the historical V01 review, which covered p01–p15 only. It was read-only: it read the production source the tests call, ran nothing and did not use Actions. This is **NOT** a `CHATGPT_INDEPENDENT_AUDIT`.

**Scope:** `tests/m46_performance.gd` R02 changes:
- p16 strengthening;
- new p17 (sixth slot + boosters);
- new p18 (winding routes);
- new p19 (SB-M46-015 effect budget).

**Verdict received:** APPROVE_WITH_FIXES. No BLOCKER and one MAJOR. All findings were addressed or recorded as described below.

| # | Sev | Finding | Action |
|---|-----|---------|--------|
| M1 | MAJOR | p19 never exercised GameFeelFlow: every target on the Results path is a Control, and the adapter sends punch_scale only to Node2D/Node3D. | **Fixed.** p19 now drives the real GFF backend through the same adapter on a Node2D target. Peak scale deviation is 0.175, and scale returns to exactly 1 after expiry, `cancel_all` and a live REDUCED toggle. The log states that the production Results path is Spark-only by design. |
| m1 | MINOR | p17 "paused" check was vacuous (`execute_booster` has no pause gate; no ticks ran). | **Fixed.** A real paused front tap is refused (`paused`), illegal-target boosters are refused, and 30 paused ticks run with bots in flight before comparing gameplay and economy. |
| m2 | MINOR | "one tap = one batch" was proven only by occupancy. | **Fixed.** Now asserts tap slot == 5 (the sixth) and supply batches −1 exactly. |
| m3 | MINOR | "no 7th" was checked on the engine only. | **Fixed.** `strip.set_capacity(7)` returns false, and engine and UI view counts are tracked every frame. |
| m4 | MINOR | Tornado ms / burst were measured but not gated. | **Recorded as report-only.** About 51 ms is a one-off, logged as a finding (index rebuild + board repaint + colour purge). |
| m5 | MINOR | p16 pause could be vacuous; "left WAITING" was implied by WON. | **Fixed.** Asserts there were bots and assignments in flight at the pause (35 / 35), and counts WAITING → ACTIVE recoveries separately (91 of 92). |
| m6 | MINOR | p19 "never per cell" was tautological. | **Fixed.** Relabelled "structural" and backed by a source scan of the clear / native FX / renderer / retire-echo scripts, alongside the clears-without-Results-event check. |
| m7 | MINOR | The replay window was too short. | **Fixed.** A fully revealed terminal is re-shown with a 1.8 s real-time window. |
| m8 | MINOR | `retry()` was not checked. | **Fixed.** Its result is asserted. |
| m9 | MINOR | Show cost was excluded from frame stats; emitters were not bounded; "self-free" wording. | **Fixed.** The show is inside its frame (this exposed a ~290 ms one-off on the first Results show, now recorded). Emitters ≤ dispatches. Reworded to "expired". |
| m10 | MINOR | The drift baseline was asymmetric; objects were wall-clock-sensitive. | **Fixed.** Settled, symmetric Results-subtree node baseline (28 → 28), zero Spark emitters (target canvas + pool), zero owned. Process Object delta is report-only (bots in flight / retried supply). |
| m11 | MINOR | p18 mean ~3.2–3.4 ms against 4.0 is thin headroom. | **Recorded:** 4 runs, 3.19 / 3.21 standalone and 3.41 / 3.55 in the full suite. Budget not loosened. |
| — | NIT | p18 direction rounding edge, the `dup` check, the private `_SparkEmitter` coupling, static restore on crash paths. | Accepted as noted; no change. |

**Issue found after the review in the full-suite run:** p16 / p17 compared the full `EconomyServices.snapshot()` across real frames. Heart and timed-2x fields are computed from wall-clock seconds, so a second boundary inside a pause can change them legitimately.

**Fix:** pause and refusal checks now compare `wallet` + `boosters` only, the economy state gameplay and booster actions can move.

**Final local run:** 19/19 PASS.
