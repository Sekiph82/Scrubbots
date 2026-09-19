# M31-C001 V01 — Cleaning Effects Master Implementation Prompt

Repository: `Sekiph82/Scrubbots`  
Branch: `main`  
Milestone: `M31 — Cleaning Effects [VISUAL REFERENCE] [PERFORMANCE]`  
Implementation actor: Claude  
Tracker authority: root `TASKS.md` is ChatGPT-write-owned. Claude MUST NOT edit it.

## 0. Start / sync contract

Before editing anything:

1. Confirm repository `Sekiph82/Scrubbots`, branch `main`.
2. Fetch and fast-forward safely to `origin/main`. No force push, no hard reset over owner work.
3. Read:
   - `CLAUDE.md`
   - root `TASKS.md` read-only
   - `coordination/sessions/M31-C001/CHATGPT_MASTER_AUDIT_CRITERIA_V01.md`
   - `coordination/OWNER_GAMEPLAY_SCREEN_COMPOSITION_V02.md`
   - `docs/MASTER_UI_SYSTEM.md`
   - `scripts/gameplay/clearing/complete_clearing_loop.gd`
   - `scripts/gameplay/board/board_presentation.gd`
   - `scripts/gameplay/board/board_renderer.gd`
   - `scripts/gameplay/runtime/production_gameplay_host.gd`
4. Inspect `git status` before work. Preserve all owner assets and current merged visual-asset work.
5. Run the existing relevant regression baseline before invasive changes when practical.
6. Do not implement M32, M33 runtime audio, Economy, Home, Results, or future milestones.

M30 is CLOSED. Do not reopen its terminal/retry architecture without a concrete regression caused by M31.

## 1. M31 purpose

Add a lightweight, readable, mobile-safe **visual cleaning effect** when one logical board cell is authoritatively cleared.

The effect is presentation only. It must make the cleaning action easier to read without becoming gameplay truth, changing target selection, changing timing policy, or creating a permanent Node per board cell.

M31 closes these canonical TASKS items:

- SB-M31-001 Use original visual references where available.
- SB-M31-002 Define cleaning event.
- SB-M31-003 Prototype lightweight effect.
- SB-M31-004 Separate from BoardState.
- SB-M31-005 Toggle effects.
- SB-M31-006 Concurrency limit.
- SB-M31-007 Pool only after profiling.
- SB-M31-008 Stress 59×59.
- SB-M31-009 Measure frame cost.
- SB-M31-010 Reduced-effects option if required.

## 2. Authoritative cleaning-event contract

Do NOT infer cleaning from:
- rendered transparency;
- robot position;
- route completion guesses;
- slot quota changes;
- animation completion;
- polling BoardState every frame.

The event source is the already-authoritative M20 signal:

`CompleteClearingLoop.authenticated_clear(owner_id, target_index, color_id, agent)`

Current contract in M20: this signal is emitted exactly once on the committed CLEARED path after BoardState/candidate/reservation/dispatcher finalization and board repaint, and never on rollback/failure/reset paths.

M31 may listen to that signal strictly as a presentation observer.

M31 must never:
- write BoardState;
- modify ColorCandidateIndex;
- create/release reservations;
- mutate M25 claims;
- mutate M24 slots;
- modify M23 supply;
- dispatch/retarget robots;
- decide WIN/LOSE;
- affect M27 solver/deadlock truth.

If the visual effect cannot be shown, gameplay must continue unchanged.

## 3. Existing visual assets first, zero generation

The visual-asset branch is now merged into main.

Existing gameplay effect assets include:

- `assets/ui/final/gameplay/effects/fx_clean_puff.png`
- `assets/ui/final/gameplay/effects/fx_clean_sparkle.png`

Treat these as the first M31 production candidates.

Also inspect:
- `assets/ui/VISUAL_ASSET_INDEX.md`
- canonical gameplay visual references under `assets/art/references/`
- `assets/ui/final/gameplay/master/scrubbots_gameplay_master.png`

Do not spend image-generation credits and do not regenerate these assets in M31.

If either texture is technically unsuitable for mobile runtime, prefer deterministic non-AI preparation/import optimization or a simple Godot-native effect. Document evidence. Do not silently replace owner/merged assets with newly generated art.

## 4. Presentation architecture

Implement one narrow reusable presentation component, suggested shape:

`scripts/gameplay/presentation/cleaning_effects_controller.gd`

or an equivalent clearly named path consistent with the current repository.

Recommended hierarchy:

`BoardPresentation`
- `BoardRenderer`
- `CleaningFxLayer`
- `AgentLayer`

Requirements:

1. `CleaningFxLayer` is created once and identity-stable across responsive relayouts, exactly like the M29-stabilized Renderer/AgentLayer contract.
2. It shares the same board-local origin and logical-cell scale as the renderer/AgentLayer.
3. An effect for `target_index` appears centered on that logical cell, using BoardState only for read-only index->position conversion if needed.
4. Relayout/resizing rescales the existing FX layer. It must not recreate live presentation authority or strand active agents/effects.
5. Prefer z-order so cleaning FX reads over the cleared cell while not hiding the moving Scrubbot unnecessarily.
6. No per-cell permanent FX nodes or data structures.

Expose narrow presentation accessors only as needed, for example `get_cleaning_fx_layer()` or controller methods. Do not expose mutable gameplay authority through presentation objects.

## 5. Visual behavior

Use a restrained short cleaning cue, not a screen-filling reward effect.

Prototype from the existing two textures:
- a soft cleaning puff;
- a small sparkle accent.

The visual should:
- originate at the cleared cell center;
- appear immediately on the committed clear event;
- scale/fade out quickly;
- remain readable on 20×20 through 59×59 boards;
- not obscure nearby board state;
- remain visually subordinate to board artwork and robot motion;
- avoid large camera flashes, screen shake, or reward-style explosions.

A reasonable target lifetime is roughly 0.20–0.40 seconds, but tune based on actual visual readability and performance evidence rather than treating that range as gameplay truth.

Random variation is optional. If used, keep it presentation-only and bounded. Tests must not depend on random visual values.

## 6. Toggle contract

Implement a runtime presentation toggle with default ON, for example:

`set_effects_enabled(bool)`

and a read-only query.

When disabled:
- new authenticated clears create zero cleaning FX;
- gameplay truth and clear transactions continue normally;
- active effects may either finish or be cleared immediately, but choose one deterministic behavior and test it.

This is an M31 presentation seam only. Do not implement persistent Settings UI here. M41 owns settings/persistence.

## 7. Concurrency / overload policy

Implement an explicit hard cap for simultaneously active cleaning-effect instances.

The cap is presentation protection only. It must never queue/block/delay gameplay.

Choose and document a practical default after profiling. Start in a conservative mobile-friendly range, then justify the final number with the 59×59 stress result.

When saturated:
- fail open for gameplay;
- suppress/drop excess visual effects deterministically;
- do not allocate an unbounded backlog;
- do not alter authenticated-clear processing.

Expose audit counters such as:
- current active effect count;
- peak active effect count;
- suppressed/dropped visual-effect count.

These counters are diagnostic/presentation-only.

## 8. Pooling rule

Do NOT introduce pooling merely because effects are short-lived.

First implement the simplest correct bounded version and profile it.

Only add a pool if evidence shows that allocation/free churn causes meaningful frame-time or allocation pressure under the required stress workload.

If no pool is needed, explicitly record that decision and evidence. SB-M31-007 is satisfied by proving the decision was profiling-driven, not by forcing a pool into the architecture.

If pooling is needed:
- pool only visual effect instances;
- cap pool size;
- clear/reinitialize every reused visual state;
- no gameplay references may be retained by pooled objects.

## 9. Reduced-effects mode

Provide a narrow reduced-effects presentation mode if stress/readability evidence shows it is useful. Prefer implementing the seam even if the normal path passes comfortably.

Suggested behavior:
- normal: puff + sparkle;
- reduced: one lightweight cue only, shorter lifetime and/or fewer simultaneous instances.

Expose it as presentation state, for example:

`set_reduced_effects(bool)`

Do not implement Settings persistence in M31.

Reduced mode must never change how many cells clear or when they clear.

## 10. Retry / teardown hygiene

M30 Retry must remain visually clean.

On successful Retry/reset:
- remove any stale cleaning FX from the previous attempt;
- reset M31 diagnostic active/peak counters as appropriate for a fresh attempt;
- never let a delayed visual callback mutate or repopulate the new attempt.

Do not weaken the M30 Retry gate to achieve this.

Prefer a narrow presentation clear/reset method invoked from the existing post-success restore/presentation sync seam.

A failed M30 Retry gate must not be “fixed” by M31 presentation code.

## 11. Terminal behavior

M31 does not decide terminal state.

When final cell clearing leads to WON:
- the final cleaning cue may complete naturally if the presentation remains alive;
- no duplicate completion visual/result is introduced here.

On LOST:
- no synthetic cleaning effect is emitted merely because the level became terminal.

## 12. 1x / 2x

M31 must remain valid at both 1x and 2x.

Do not change `Engine.time_scale`.

The cleaning effect is presentation only. It may use short real presentation lifetimes; the required performance/concurrency tests must include the higher event-density behavior seen at 2x.

Do not couple M31 to Economy V1 speed entitlement logic.

## 13. Tests / evidence

Add focused tests. At minimum prove:

### Event correctness
- one committed `authenticated_clear` -> one requested visual cue when enabled and below cap;
- no visual cue from rejected/rollback/reset paths;
- repeated clears do not mutate gameplay truth.

### Geometry
- target index maps to the correct board-local cell center;
- rectangular boards remain correct;
- responsive relayout does not recreate the Renderer, AgentLayer, or CleaningFxLayer;
- 20×20 and 59×59 geometry remains aligned.

### Toggle
- disabled => zero new FX;
- re-enabled => later committed clears may show FX;
- toggling never changes board/supply/slot/claim/reservation truth.

### Concurrency
- active FX never exceed the configured cap;
- overflow is suppressed visually without blocking clear events;
- no unbounded queue.

### Retry
- successful Retry clears old visual effects;
- no stale visual effect returns after Retry;
- existing M30 fresh-attempt behavior stays green.

### Stress / performance
Run a 59×59/high-clear-density stress scenario that exercises bursts substantially beyond the concurrency cap.

Record:
- max active instances;
- dropped/suppressed visual count;
- approximate frame/update cost or benchmark timing using the repository's existing performance conventions;
- whether pooling was required;
- normal vs reduced mode result if reduced mode is implemented.

Do not invent FPS measurements that were not actually measured.

## 14. Regression floor

Run at least:

- new M31 focused tests;
- root `res://tests/run_tests.gd`;
- M30 manual/headless completion smoke;
- M29 realtime movement and presentation identity/sync evidence;
- M26 integration relevant to clear cadence;
- M20 clearing lifecycle;
- BoardRenderer/BoardPresentation relevant smoke;
- 59×59 scale/performance tests already present;
- `git diff --check`.

Any new failure caused by M31 is blocking.

Pre-existing unrelated historical failures may be documented only if reproduced on the pre-M31 baseline. Do not repair unrelated milestones inside M31.

## 15. Owner F6 scene

Create a dedicated manual visual scene, suggested:

`res://scenes/debug/m31_cleaning_fx_playtest.tscn`

It should make owner review fast, with debug-only controls such as:
- AUTO-SOLVE / run normal play;
- FX ON/OFF;
- REDUCED ON/OFF;
- optional controlled BURST/STRESS button if useful.

Owner should be able to verify:
- effect appears at the actually cleaned pixel;
- it reads as cleaning rather than reward/confetti;
- it is not visually noisy at normal play;
- high density does not turn the board into a flashing cloud;
- toggle works;
- Retry leaves no stale FX;
- 1x and 2x remain visually acceptable.

Debug controls must not leak into release-facing UI.

M31 cannot receive final owner visual closure until this F6 gate is explicitly accepted.

## 16. Scope boundaries

Do NOT:
- edit root `TASKS.md`;
- generate new AI art;
- implement M32 Scrubbot final visuals;
- wire M33 audio;
- implement M34 haptics;
- implement Economy/boosters;
- redesign gameplay layout;
- alter M20-M30 gameplay rules to make the effect easier;
- add one permanent Node per board cell;
- add a global time-scale hack;
- reopen accepted M30 behavior without a concrete regression.

## 17. Delivery / commit protocol

Implementation commit(s) first.

Then create a separate final log:

`coordination/sessions/M31-C001/CLAUDE_LOG_V01.md`

The log must include:
- exact implementation SHA(s);
- files changed;
- event source and why it is authoritative;
- asset paths actually used;
- concurrency cap and overload behavior;
- whether pooling was used, with profiling evidence;
- toggle/reduced-mode behavior;
- retry cleanup behavior;
- 59×59 stress evidence;
- test commands/results;
- known limitations;
- confirmation that `TASKS.md` was not edited.

Push safely to `main`.

Return only:

`AWAITING_AUDIT`  
final implementation SHA  
direct GitHub URL to `CLAUDE_LOG_V01.md`

Do not self-close M31.
