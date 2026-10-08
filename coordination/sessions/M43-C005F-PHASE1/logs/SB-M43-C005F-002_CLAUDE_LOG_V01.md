# SB-M43-C005F-002 — One fail-open ScrubBots feedback adapter + intensity policy — CLAUDE_LOG_V01

- Milestone: M43-C005F-PHASE1 (child 2 of 4)
- Starting SHA: `593f0f6d4216889f52d40ab410f54b56c232e616`
- Final SHA: the Phase 1 implementation commit (see master log)
- Final child state: **COMPLETE — AWAITING AUDIT**
- Sync: see the F001 log. The work was done in a clean TEMP worktree at `origin/main`, and the owner-local checkout is preserved.

## Starting point

`scripts/ui/feel/feedback_adapter.gd` already existed from the earlier M43 master run: one instance in `main.gd`, with no call site. That adapter was written against spies only. It does **not** behave correctly against the real plugins (see the F001 findings):
- it allow-listed the non-existent `elastic` effect;
- it used combos that GFF cannot cancel and that flash;
- it relied on global `Spark.clear()` and `stop_all(null)`;
- it had no duration ceiling.

This child rebuilds it into the canonical single boundary. It remains **one** file and **one** instance; no second adapter was created.

## Files changed

- `scripts/ui/feel/feedback_adapter.gd`: rewritten.
- `scripts/app/main.gd`: adds an `_exit_tree()` that calls `feel.unbind()` (presentation teardown), plus a doc line. There is still exactly one `FeedbackAdapter.new()` and **no call site**.
- `tests/m43_c005f_phase1_foundation.gd`: new focused suite.
- `tests/m43_master_c005f_feel.gd`: legacy lane assertions updated to the canonical contract (see the F013 log).

## Adapter contract

**Ownership**
- Presentation territory: `scripts/ui/feel/`.
- Created and destroyed by the ephemeral app root (`main.gd::_ready` / `_exit_tree`).
- Never referenced by AppState, SaveService or EconomyServices; never a save field (test a01).

**Fail-open**
- Plugins are looked up by autoload name **at call time**.
- A compatibility contract is checked on every use: the expected script path, the required methods (`play`, `stop_all`, `get_effect_names` / `at`, `burst`, `clear`) and `is_node_ready()`. Anything else is treated as absent, so a missing, impostor or partially initialized plugin is a no-op.
- `play()` only records an owned dispatch and defers the actual plugin calls into the adapter's own `_dispatch`. A plugin exception therefore happens after the caller's frame and cannot reach or block navigation, terminal, commit or save. Test a04 injects a real runtime error inside a spy plugin; the caller still returns and continues, and the adapter keeps working afterwards.

**Intensity vocabulary and budgets**

| Tier | Particle ceiling | FULL particles | Duration ceiling | GFF punch intensity / duration | Spark preset |
|---|---|---|---|---|---|
| MICRO | 0 | 0 | 0.30 s | 0.08 / 0.12 s | none |
| SMALL | 4 | 4 | 0.50 s | 0.12 / 0.18 s | spark |
| REWARD | 8 | 8 | 0.70 s | 0.16 / 0.25 s | pickup |
| MAJOR_REWARD | 14 | 14 | 0.90 s | 0.20 / 0.30 s | confetti |
| WIN | 18 | 18 | 1.10 s | 0.22 / 0.35 s | confetti |
| MAJOR_UNLOCK | 24 | 24 | 1.30 s | 0.24 / 0.40 s | confetti |

- Particle counts stay inside the TASKS ranges (0, 0–4, 4–8, 8–14, 12–18, 16–24).
- Spark lifetime is capped so even the slowest particle dies inside the tier ceiling. Measured: the WIN burst's max life is 1.01 s against a 1.10 s ceiling.
- The measured `punch_scale` peak on WIN is about 1.08, and about 1.12 at the top tier.

**Allow-list and targets**
- GFF: `punch_scale` only, dispatched only to Node2D/Node3D targets because GFF 1.0.0 cannot scale Controls.
- Spark: `spark`, `pickup` and `confetti` only, to CanvasItem targets.

**One-shot keys**
- An optional event key is consumed on first request in either mode, so repeats are refused. Keyless requests are not deduplicated.

**Bounded cleanup**
- Each dispatch is owned: it keeps a weak reference to its target and to the Spark bursts it spawned, found by diffing the `SaltmireSparkPool` children.
- A SceneTree timer expires the dispatch at its tier ceiling.
- Release means freeing only the bursts it spawned and running a targeted `GameFeelFlow.stop_all(target)`, which restores the node. The stop is skipped if a newer owned dispatch still uses the same target.
- `unbind()` cancels all owned work and disconnects.
- There are no loops and no scene-long ownership. In headless runs, a frame hitch longer than the ceiling simply ends the effect early, which is still bounded.

**Test seam**
- `set_backends_for_test(gff, spark)` is a spy injection used only by tests.
- `capabilities()` is the harmless query; `dispatch_log()` and `owned_count()` provide evidence.

**No call-site rollout**
- F003–F012 are not wired.
- `tests/tools/c005f_tier_harness.gd` is an isolated diagnostic harness (rendering, not headless). It fires every tier through the adapter with the real plugins and captured `evidence/tiers_full.png` and `evidence/tiers_reduced.png`.

## Tests

`tests/m43_c005f_phase1_foundation.gd`:

| Case | What it checks |
|---|---|
| a01 | one production entry boundary; no other shipping script names either plugin; the adapter is not durable |
| a02 | vocabulary and budgets |
| a03 | **real plugins:** deferred dispatch; one 18-particle burst; max life within the ceiling; the Node2D punch peaks at 1.082 and is restored to 1 after the ceiling; a Control target gets a Spark burst only |
| a04 | plugin fault isolation (one deliberate `SCRIPT ERROR`, labelled `EXPECTED_FAULT_INJECTION` in the output) |
| a05 | one-shot keys |
| a06 | absent plugins are a no-op; bad intent or target is refused |
| a07 | `unbind()` teardown restores the target and unsubscribes |

## Blockers / deviations

- **Deviation (justified):** the earlier `GFF_ALLOWED` / FULL table (`ui_button_press`, `ui_notification`, `elastic`) was replaced because it did not work, or could not be cancelled, against the real installed plugins.
