# M22-C001 V02 — ChatGPT Independent Strict Audit

Date: 2026-09-17
Repository: `Sekiph82/Scrubbots`
Branch: `main`
Audited implementation commit: `34d3bdf37c40f499b6a88007e0e20a75b7bae7cd`
Parent: `889039bb7d59a553861cb35a165b146d80121c81`
Owner contract: `coordination/OWNER_SCRUBBOT_RAILROAD_DECISION_V01.md`
Audit criteria: `coordination/sessions/M22-C001/CHATGPT_AUDIT_CRITERIA_V02.md`

## Verdict

**CHANGES_REQUIRED / RAILROAD_V1_PRODUCTION_SUPERSESSION_INCOMPLETE / DIRECT_EVIDENCE_GAPS_FROZEN / V03_REQUIRED**

V02 contains substantial correct work: the single-source Railroad geometry helper, procedural four-side rail view, aligned-exit planner, malformed color-binding hardening, responsive rail/slot layout, rapid-dispatch/reset coverage, documentation supersession and zero-generation policy are materially implemented. The reported root suite is green.

However, V02 cannot be accepted yet. One production-routing branch still preserves the superseded M21 adjacent-ring behavior for non-below outside starts, and the required real SlotCell connector evidence is not actually post-layout independent evidence. Additional mandatory direct-test cells are also mislabeled or weaker than the frozen V02 criteria require.

The finding set below is frozen. V03 must close all findings in one reconciliation pass. Do not create serial micro-prompts.

## 1. Independent diff / governance inspection

Comparing `889039bb...` to `34d3bdf...` yields exactly one implementation commit. Changed files are limited to the V02 railroad implementation, tests, four canonical docs and `CLAUDE_LOG_V02.md`. Root `TASKS.md` was not modified by Claude.

Accepted governance facts:

- work is on `Sekiph82/Scrubbots` / `main`;
- accepted V01 slot foundation remains present;
- TargetSelector ordering source was not rewritten for railroad geometry;
- ReservationState ownership and CompleteClearingLoop authenticated-clear authority remain separate;
- zero Magnific/image-generation credit spend is reported;
- owner M21 historical audit/log evidence was not rewritten.

## 2. Accepted V02 implementation surfaces

The following are accepted as useful V02 foundation and must not be needlessly rewritten in V03:

1. `ScrubRailGeometry` is a pure/data-oriented shared geometry source used by routing and presentation. It carries the owner constants `CLEARANCE=2.0`, `RAIL_WIDTH=1.0`, `CENTER_OFFSET=2.5`, side/corner geometry, aligned exits and deterministic side tie-break order.
2. `ScrubRailView` is procedural/native Godot presentation, draws all four rail sides/corners, owns no gameplay truth and spends zero generated-art credits.
3. The railroad branch of `ProductionRoutingSystem` evaluates legal aligned exits for the already-assigned target, never calls TargetSelector, validates the final approach against authoritative access truth, chooses shortest legal total route and deliberately skips the generic shortcut/rounding pass.
4. `ColorSelectionPanel.bind_colors()` now fails closed on malformed/undersized/non-Color snapshots rather than fabricating magenta truth.
5. The production demo maps slot activation through `CompleteClearingLoop`; five slots remain visible and rapid/reset presentation bookkeeping remains separate from gameplay truth.
6. `tests/m22_railroad_responsive_smoke.gd` provides useful real-SubViewport layout evidence for the required portrait matrix, touch target sizing, physical rail/slot separation and reset orphan cleanup.
7. The four canonical docs record Railroad V1 supersession while preserving M21 evidence as historical.

These accepted surfaces remain subject to V03 regression proof.

## 3. Frozen finding set

### F-M22-V02-STRICT-001 — production routing still contains the superseded M21 exterior ring for non-below outside starts

`ProductionRoutingSystem.compute_route()` enters Railroad V1 only when `_is_below_board_start(request, board)` is true. `_is_below_board_start()` is `start_position.y >= board.height`. Every other start falls through to the older BFS/ring planner, whose current source still constructs and seeds the exact M21 adjacent ring (`x=-1`, `x=W`, `y=-1`, `y=H`). The V02 source comments explicitly say that ring is retained for left/right/non-below debug/test injections.

This violates the locked V02 supersession boundary:

- the owner decision states that the exact adjacent one-cell ring is superseded for future production behavior;
- V02 prompt §5 defines an **outside-start Railroad V1 route law**;
- the prompt permits a narrow compatible path for **inside-board debug/test starts**, not an obsolete production exterior ring for top/left/right outside starts;
- M22-V02-069 requires an outside-start Scrubbot, once joined, to remain on Railroad geometry until a legal aligned exit.

V03 must remove the obsolete adjacent-ring path from current production exterior routing. Do not preserve it merely to keep old low-level injection tests green. Historical M21 V07-V10 files remain untouched as historical evidence.

Required V03 behavior:

- owner-facing real slot starts remain exact-anchor → BOTTOM connector → Railroad V1;
- any current production **outside** start must never use the old `-1/W/H` adjacent ring. It may be handled by a Railroad-compatible/fail-closed policy appropriate to the existing contract, but must not silently fall back to M21 ring geometry;
- only a narrowly documented **inside-board** debug/test compatibility path may retain non-rail interior planning if still required;
- current regression tests that depended on production left/right/top adjacent-ring injection must be migrated or isolated as historical/test-only evidence rather than forcing obsolete geometry back into production.

Affected acceptance cells include M22-V02-069..075, 090, 103..108 and the owner supersession contract.

### F-M22-V02-STRICT-002 — the claimed real SlotCell connector evidence is pre-layout/circular and does not prove the exact laid-out anchor contract

`SlotView.get_spawn_anchor_global()` correctly defines the production origin as the actual laid-out button top-center and explicitly requires completed layout. `GameplaySlotDemo.spawn_start_for()` correctly queries that anchor dynamically and maps it through `BoardPresentation.global_to_board_local()`.

But `_run_m22_railroad_integration_tests()` instantiates/builds the demo and immediately emits the C08 Button without awaiting a layout frame. Its key start assertion compares route point 0 against `r2.agent.spawn_origin`. Both values originate from the same dispatch input, so that is not independent evidence that the input equals the real laid-out SlotCell anchor.

The V02 log exposes the consequence: it records the supposedly real C08 slot-2 route as starting at `(0.0, 24.0)`. The responsive smoke, after real layout, places the five 120 px slot cells left-to-right across the screen. On the baseline layout, slot 2's real top-center cannot map to board-local `x=0.0`; the zero x is characteristic of dispatch occurring before the HBox has laid out the child. Therefore the logged route is not valid proof of M22-V02-061/066/067/076/141.

V03 must add independent post-layout evidence using a real `SubViewport` (or equivalent real layout frame) before Button activation. It must directly compare:

- each of the five actual `SlotCell` top-center global anchors;
- each anchor mapped independently through `BoardPresentation.global_to_board_local()`;
- the corresponding real agent route point 0;
- the canonical `bottom_entry(mapped_start.x)` at route point 1;
- five distinct start identities mapped one-to-one to slot IDs;
- at least two viewport/layout cases proving the mapping is recalculated from current geometry and no stale cached anchor survives responsive re-layout.

The C08 real Button test must still naturally choose `380/(0,19)` and then prove actual-anchor → connector → rail → aligned exit → target.

Affected cells: M22-V02-061..068, 076..077, 096..098, 115..126, 131, 141..144.

### F-M22-V02-EVIDENCE-001 — mandatory Railroad route evidence cells are mislabeled or weaker than the frozen criteria

The V02 root tests contain valuable route coverage, but several required direct cells are not actually proven as written:

1. **M22-V02-133** requires a **far-right/top target** that requires real corner/side travel and aligned exit. The only assertion carrying label `M22-V02-133` uses a left-edge interior target `(0,5)` and proves fallback to LEFT. That is useful for 086/134, but it is not the required far-right/top case.
2. **M22-V02-135** requires proof that rail segments never occupy forbidden exterior clearance free-space except the slot connector and final aligned approach. `_rail_axis_aligned()` proves only that segments are orthogonal. An orthogonal segment can still be off the canonical rail, so the required confinement proof is incomplete.
3. The tie-break fixture uses `19×19` and the rectangular routing fixture uses `30×12`, both outside the locked production 20..59-per-dimension envelope. Generic geometry may support test dimensions, but production Railroad acceptance must include equivalent routing/tie-break evidence inside the supported envelope.

V03 must add direct segment-domain assertions, not just axis-alignment assertions. For every successful Railroad test route, classify connector, rail travel and final approach explicitly. Every rail-travel segment must lie on a canonical TOP/BOTTOM/LEFT/RIGHT centreline, and side changes must occur only at exact canonical corners.

Add a true far-right/top production-envelope case and move the tie-break/rectangular routing proof to valid 20..59 dimensions while preserving the intended safety semantics.

Affected cells: M22-V02-044..045, 069..075, 090, 122..123, 133..140.

### F-M22-V02-EVIDENCE-002 — V02 handoff log does not contain the exact ending commit identity required by the prompt

`CLAUDE_LOG_V02.md` records the starting commit, but the ending commit section says only that the implementation commit's parent is `889039b` and that the hash is recorded after push. The committed log contains no `34d3bdf...` identity.

The V02 prompt explicitly required exact starting/ending commit identities. V03 must record both exact starting and ending commit identities in `CLAUDE_LOG_V03.md` after the implementation commit is known. If the log itself is included in the same commit and therefore cannot know that commit hash without amendment, use a clean two-step evidence commit or another non-circular Git procedure. Never claim a hash is recorded when it is not.

## 4. Runtime evidence assessment

Claude reports:

- Godot `4.7.2.stable.official.ed1daf0bf`;
- root suite `4769` checks / `0` failures / exit 0;
- M22 Railroad responsive smoke PASS;
- V01 responsive smoke PASS;
- M21 real-art full 400-cell clear PASS;
- M21 V10 and required M20 lifecycle smokes PASS;
- `git diff --check` clean;
- M21 V08/V09 standalone scripts each retain one exact adjacent-ring assertion and fail only on that superseded historical geometry.

These runtime claims are useful implementer evidence and are consistent with much of the committed source. ChatGPT cannot execute the user's local Godot binary from this audit environment. A green aggregate suite does not override the source-level contract mismatch in F-001 or the direct-evidence gaps in F-002/E-001.

The historical V08/V09 failures do not by themselves block V02 because those exact assertions encode superseded M21 geometry. They must remain historical and must not be rewritten to pretend Railroad V1 existed in M21.

## 5. Task / owner-gate decision

Do **not** close `SB-M22-009` or `SB-M22-026..034` yet. Do **not** open `SB-M22-035` owner F6 visual/game-feel acceptance yet.

Progress and `lastCompletedTaskId` remain at the accepted M22 V01 frontier until V03 independently closes the frozen finding set.

No owner manual re-test is required for V03 unless V03 passes engineering audit and ChatGPT explicitly opens the F6 owner gate.

## 6. V03 closure law

V03 is a narrow production-correction + direct-evidence reconciliation pass.

It must:

- close F-M22-V02-STRICT-001, F-M22-V02-STRICT-002, F-M22-V02-EVIDENCE-001 and F-M22-V02-EVIDENCE-002 in one pass;
- preserve accepted V01 slot architecture and accepted V02 single-source geometry/presentation where not implicated;
- keep TargetSelector WHAT-policy unchanged;
- keep ReservationState and authenticated clearing authority unchanged;
- keep root `TASKS.md` read-only for Claude;
- keep historical M21 audit/log/test evidence intact;
- spend zero Magnific/image-generation credits;
- run the full root suite and all dedicated V03/Railroad/responsive/real-art/lifecycle regressions;
- create and push `coordination/sessions/M22-C001/CLAUDE_LOG_V03.md` with exact evidence;
- return for a new independent ChatGPT audit.

If V03 closes the frozen findings, ChatGPT may then close eligible Railroad task rows and open the separate owner F6 visual/game-feel gate. No M23 work is authorized by V03.