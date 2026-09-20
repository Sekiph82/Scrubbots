# ScrubBots — Canonical GitHub Task State

This root TASKS.md is the only authoritative project-status tracker consumed by H!veAI. GitHub repository metadata and the latest commit are the remaining project-truth inputs. Hidden .hiveai control-plane files are historical only and are not read for current project state.

## Project Status

- Current Milestone: M32
- Current Sprint: M32-C001 V01 — Scrubbot Final Visuals
- Current Task: M32-C001-V01
- Current Task Status: AWAITING_IMPLEMENTATION
- Next Task/Action: Claude executes `coordination/sessions/M32-C001/CHATGPT_MASTER_PROMPT_V01.md` under `coordination/sessions/M32-C001/CHATGPT_MASTER_AUDIT_CRITERIA_V01.md`. Integrate the existing owner-approved canonical Scrubby gameplay visual into the real production agent path, preserve all M18-M31 gameplay truth, add presentation-only travel/arrival/disappearance behavior, audit existing Scrubby asset provenance instead of regenerating art, prove viewport/density/performance/retry hygiene, and provide a dedicated owner F6 visual gate. Do not edit root `TASKS.md`, do not generate new AI art, and do not start M33+ runtime systems.
- Required Actor: CLAUDE
- Tracking Repository: Sekiph82/Scrubbots
- Tracking Branch: main
- Progress: 566 / 980 = 57.76% (canonical `SB-*` checklist recount after M31 closure and the 2026-09-19 tracker additions); lastCompletedTaskId M31-C001-V01. M31 is fully closed after independent code audit plus owner F6 acceptance of FX ON/OFF, BURST, AUTO-SOLVE, REDUCED ON/OFF, 1x/2x and RETRY cleanup. M33 canonical Dispatch/Cleaning/Completion SFX assets and the V1 no-movement-audio decision are already owner-approved and tracked as complete asset tasks, but M33 runtime audio integration remains future work.
- Note: `codex/visual-assets-production` was merged through PR #5 for the earlier visual batch, but the later final visual-closure batch P2-145..P2-157 now exists on that visual branch at commit `65b26242f996f210a923b4536c7083f6f2d005cc` and is not yet integrated into `main`. Do not delete the visual branch until that final batch is merged/audited. The two historical Claude branches had zero unique commits.

## Tasks
# SCRUBBOTS — MASTER TASK PLAN

> **H!veAI tracking [OWNER-LOCKED — updated 2026-09-14]:** repository-root `TASKS.md` is the one and only live project-status tracker. The top `Project Status` block controls current milestone, sprint, task, actor, next action, workflow status, and progress. Former `.hiveai` control-plane files are archived under `docs/migration/legacy-task-trackers/` and are historical evidence only. Never recreate or synchronize a competing live tracker. **ChatGPT is the sole writer of root `TASKS.md`; Claude/Codex read it but do not edit it. ChatGPT updates it after each independent audit, owner-gate decision, and before handing off the next implementation prompt.**

Permanent master execution roadmap for the SCRUBBOTS project. This file is
authoritative alongside `CLAUDE.md`. Read both at the start of every
session. ChatGPT updates this file after audit/owner-gate decisions; implementation agents do not mutate it.

Canonical local project: `C:\Users\sekip\Desktop\ScrubBots`
Canonical repository: `https://github.com/Sekiph82/Scrubbots`
Primary branch: `main`

Verified at time of writing (end of Phase M06):
- HEAD commit at phase start: `89c7d43` ("feat: enforce Scrubbots
  difficulty board ranges") — see `docs/05_TECH_DECISIONS.md` and
  CHANGELOG for the Phase M06 commit that follows it.
- Working tree: clean, `main` up to date with `origin/main`
- Godot: **4.7.2-stable** is the current owner-confirmed development version. The historical M00 4.7.1 installation evidence below is preserved as history; exact current build hash should be refreshed from local `godot --version` during the next local validation pass.
- Headless test suite (`tests/run_tests.gd`): **774/774 checks PASS**, exit
  code 0 (grown through M09/M11/M12/M13 and the META-C004 ACTIVE/CLEARED
  renderer migration; recomputed from the suite summary, not hardcoded)
- Official production difficulty bands (Easy/Medium/Hard/Very_Hard,
  20..59, max 59×59 = 3,481 cells) implemented and enforced via
  `DifficultyRules` + `ProductionLevelValidator`, kept separate from the
  generic dimension-agnostic `LevelValidator`/`BoardState` core.
- `BoardRenderer` implemented (single Image/ImageTexture, zero per-cell
  Nodes at any board size — ADR-011) with the owner-locked ACTIVE/CLEARED
  model (ADR-019): ACTIVE = source palette color/opaque, CLEARED =
  transparent (background shows through). **Owner manual QA of the
  transparent model is complete** (SB-M10-005..011 owner-approved on 2026-09-06).

## Status tags

```text
[x]  = completed AND validated (evidence exists: ran, passed, inspected)
[ ]  = incomplete / not validated
```

A task is never `[x]` merely because code exists somewhere. It must have
been run/validated. Additional tags used throughout:

```text
[LOCKED]            — owner-specified rule, do not silently change
[DESIGN GATE]       — unresolved, owner must decide, do not invent
[TECH DECISION]     — architecture choice, see docs/05_TECH_DECISIONS.md
[PERFORMANCE]       — has a performance-sanity dimension
[CONTENT]           — real art/level content work
[VISUAL REFERENCE]  — depends on owner-supplied visual assets
[QA]                — verification/testing work
[DEFERRED]          — intentionally postponed, not blocked
```

---

## GLOBAL DEFINITION OF DONE

A milestone is complete only when **all** relevant conditions below are
satisfied. If a required validation could not run, the milestone is **not**
complete — record why instead of marking `[x]`.

- Implementation exists.
- Code parses in the actual installed Godot version (currently **4.7.2-stable**).
- Headless tests pass where applicable.
- Invalid input is tested, not just the happy path.
- Regression tests (everything previously passing) remain passing.
- No fatal Godot errors in headless/editor output.
- Warnings are understood or fixed, not ignored.
- Relevant performance sanity tests are executed and results recorded.
- The 59×59 (3,481-cell) maximum production workload is considered wherever
  cost scales with board size.
- Documentation reflects the actual implementation, not an aspirational one.
- `TASKS.md` is updated by ChatGPT after independent audit/owner-gate review to reflect true status.
- `git diff` is reviewed before commit.
- No cache/build junk (`.godot/`, import cache, build output) is committed.
- A focused, understandable commit exists.
- Push to `origin/main` succeeds when possible (never force-pushed).
- The current phase's Desktop log (see "PHASE LOG WORKFLOW" below) is
  updated to reflect the work.

---

## PERMANENT CLAUDE SESSION WORKFLOW

Every future numbered implementation prompt must:

1. Read `CLAUDE.md`.
2. Read `TASKS.md` (this file) without modifying it.
3. Read relevant `docs/` files for the system being touched.
4. Inspect `git status` / branch / remote.
5. Confirm which milestone is actually current (don't assume from memory).
6. Preserve owner files and artwork — never delete/regenerate without cause.
7. Work only on the requested scope — no drive-by rewrites.
8. Reuse existing systems (`LevelData`, `BoardState`, etc.) where appropriate
   — do not rebuild working systems for stylistic reasons.
9. Run current regression tests before major modification when practical.
10. Implement the requested milestone.
11. Add/update tests.
12. Run headless validation (`godot --headless --path . -s res://tests/run_tests.gd`).
13. Fix regressions.
14. Run relevant performance sanity tests.
15. Update authorized subsystem docs/evidence only.
16. **Do not edit root `TASKS.md`; ChatGPT owns tracker changes after audit/owner-gate review.**
17. Review `git diff` and ensure `TASKS.md` is absent from the implementation diff.
18. Commit (focused, descriptive message).
19. Push safely (`git push origin main`, never force).
20. Never force-push.
21. Write/update the matching GitHub `CLAUDE_LOG_VNN.md` and hand back `AWAITING_AUDIT`; ChatGPT then audits and updates `TASKS.md`.

---

## PHASE LOG WORKFLOW (supersedes the old per-prompt handoff-log convention)

**One development phase = one continuous Desktop log file**, not one log
per prompt. A "phase" is a milestone-level unit of work (e.g. `M03`, `M04`)
that may span multiple Claude prompts/sessions.

- Naming: `C:\Users\sekip\Desktop\SCRUBBOTS_PHASE_MXX_LOG.md` (e.g.
  `SCRUBBOTS_PHASE_M03_LOG.md`). `MXX` matches the `TASKS.md` milestone ID
  the work belongs to.
- **Create the log file at the START of the phase's first prompt**, before
  any inspection or code changes — not at the end.
- If the log file already exists for the current phase, **read it and keep
  updating the same file** — never create a second log for the same phase
  (no `_RETRY`, no `_B`, no `PROMPT_03B` variants). Every prompt working on
  the same phase reuses the same file.
- Update it after every meaningful checkpoint: environment/repo inspection,
  baseline tests, architecture decisions, each implementation step,
  fixtures added, test-suite changes, each significant failure/debugging
  discovery, final tests, before commit, after commit, after push. The log
  must let another agent resume work correctly even if the session stops
  unexpectedly mid-phase.
- Keep the chronological journal/history in the log even after issues are
  fixed — do not erase past failures once resolved.
- When the phase is genuinely complete, set `PHASE STATUS: COMPLETE` and
  fill in the Final Phase Summary section — without deleting the earlier
  chronological content.
- Only start a **new** log file when moving to a genuinely new phase (e.g.
  `M03` complete, `M04` begins).
- The phase log is **never committed** to the Scrubbots Git repository — it
  lives only on the Desktop.

Prompts 01 and 02 predate this convention and used one-log-per-prompt
(`SCRUBBOTS_PROMPT_01_LOG.md`, `SCRUBBOTS_PROMPT_02_LOG.md`) — those are
historical and not retroactively merged. `SCRUBBOTS_MASTER_TASKS_LOG.md`
(the master-plan prompt) also predates this convention. Starting with
Phase M03, use the phase-log format above.

---

## LOCKED GAME RULES

These rules override older documentation where a conflict exists. They are
not open for silent reinterpretation.

### 8.1 — Mobile-first `[LOCKED]`

SCRUBBOTS is mobile-first. Primary orientation: **portrait**. Current
provisional virtual design resolution: **1080×1920** (see ADR-002 in
`docs/05_TECH_DECISIONS.md`). Gameplay code must remain independent of
physical phone resolution — this is a display setting, not gameplay logic.

### 8.2 — Variable-size logical board `[LOCKED]`

The board engine remains **variable-size**. It must never become a fixed
40×40, 50×50, 1600-cell, 2500-cell, or 3481-cell engine. Board dimensions
come from level data. Generic code uses `width`, `height`, `width * height`
— never a hard-coded cell count. See ADR-008.

### 8.3 — Official difficulty / board size bands `[LOCKED HISTORICAL RUNTIME COMPATIBILITY]`

The legacy production validator currently retains these dimension bands while Difficulty V1 migration is still open. They are not current player-facing difficulty truth; see `coordination/OWNER_DIFFICULTY_PROGRESSION_DECISION_V01.md` and `CLAUDE.md`.

| Difficulty | Width range | Height range | Min cells | Max cells |
|---|---|---|---|---|
| EASY | 20–29 | 20–29 | 20×20 = 400 | 29×29 = 841 |
| MEDIUM | 30–39 | 30–39 | 30×30 = 900 | 39×39 = 1521 |
| HARD | 40–49 | 40–49 | 40×40 = 1600 | 49×49 = 2401 |
| VERY_HARD | 50–59 | 50–59 | 50×50 = 2500 | 59×59 = **3481** |

Examples of legacy-validator-valid boards: Easy `20×27`, Medium `34×39`, Hard `48×41`, Very Hard `53×59`.

**Current required production-capable maximum: 59×59 = 3,481 logical cells.**

### 8.4 — Rectangular boards `[LOCKED]`

Boards do **not** have to be square. Width and height are validated
independently. Never assume `width == height` in generic systems.

### 8.5 — Current maximum required workload `[LOCKED]`

`59×59 = 3,481` cells. All systems whose cost scales with board size must
eventually be tested against this workload: LevelData validation,
BoardState, BoardRenderer, color candidate index, reachability/access,
target selection, routing-related board queries, clearing updates, save/load
of level state if used, and production content validation.

### 8.6 — Test/dev fixtures vs. production levels `[LOCKED TECHNICAL RULE]`

The existing `test_3x2.json` fixture (6 cells) is valuable because it
proves the board engine is genuinely generic — it is **not** a production
level and must never be treated as one. Development fixtures may use a
`TEST` difficulty/context. `TEST` must never become a production difficulty
exposed to players, and the future production `LevelCatalog` must reject
accidental `TEST` fixtures (see M03, M35).

### 8.7 — Logical pixels `[LOCKED]`

One logical artwork square = one logical pixel = one board cell. Logical
cells are game data, never physical display pixels, and are never
represented as thousands of heavyweight Godot Nodes (see ADR-004, ADR-008).

### 8.7A — Global 16-color pixel-art palette `[LOCKED OWNER DECISION]`

Canonical machine-readable palette:
`data/palettes/scrubbots_palette_v2.json`

Canonical human-readable rule:
`docs/08_PIXEL_ART_PALETTE_RULES.md`

Production logical artwork cells may use **only C01..C16**. No other logical
pixel color is legal without an explicit owner rule change and palette version
change. CLEARED alpha-0 transparency, gameplay background and
presentation-only grid/border overlays are not logical artwork colors and do
not add palette IDs.

### 8.7B — Production used-color envelope `[OWNER-LOCKED DIFFICULTY V1]`

Production artwork may use **3–12** distinct canonical C01..C16 colors. The older class-specific `3–5 / 6–7 / 8–9 / 10–12` mapping is historical and superseded as difficulty-class legality; color count/distribution are Difficulty V1 score inputs instead.

### 8.8 — Five batch slots `[OWNER-LOCKED 2026-09-17]`

Primary gameplay presentation uses **exactly five batch slots**. They start EMPTY.
The player never chooses a destination slot. Selecting a legal supply batch automatically
places it into the **rightmost currently EMPTY slot**. Existing occupied slots never shift
or reorder. If all five slots are occupied, a supply selection is rejected atomically and
the supply column must not advance.

Duplicate colors across multiple occupied slots are legal and are part of the puzzle.
Each occupied slot owns one immutable batch identity with color, initial robot count,
remaining-to-clear count, committed/in-flight count, placement sequence and lifecycle state.

### 8.8A — Batch supply columns `[OWNER-LOCKED 2026-09-17]`

- Production supply supports 3, 4 or 5 independent FIFO columns.
- V1 gameplay validation uses **three visible rows per column**.
- Only the front/top batch in each column is selectable.
- Row 2 and Row 3 are preview-only future batches.
- Everything deeper than the preview window is hidden from the player.
- Selecting a front batch advances **only that column** by one position.
- The previous Row 2 becomes selectable, Row 3 becomes Row 2, and the next hidden batch
  enters Row 3. Other columns remain unchanged.
- Each batch is `color + positive robot_count`; its identity is stable once generated.
- Supply generation must conserve the level's logical color totals and must ultimately be
  accepted only when the Solvability Engine proves at least one legal completion sequence.

### 8.8B — Batch quota / slot lifecycle `[OWNER-LOCKED 2026-09-17]`

A batch count means the number of matching logical pixels that batch must successfully clear.
A count is **not** spent when a robot is merely spawned. It decreases only after an
authenticated arrival clears the batch's assigned target pixel. A batch with remaining quota
but no currently targetable matching pixel enters WAITING and stays in its slot. It resumes
automatically when later clearing exposes a legal matching target. A slot becomes EMPTY only
when the batch has zero remaining work and zero committed/in-flight assignments.

### 8.8C — Same-color arbitration and target claims `[OWNER-LOCKED 2026-09-17]`

Future inaccessible pixels are never pre-claimed. When a matching pixel becomes currently
targetable, same-color occupied batches compete deterministically by **oldest placement first
(FIFO)**. The oldest batch with uncommitted quota receives priority; if its remaining dispatch
capacity is exhausted, additional targets may flow to the next same-color batch.

A target claim and ReservationState reservation must be atomic. One logical pixel may belong
to at most one live assignment at a time, regardless of how many same-color batches are in
the five slots. Existing TargetSelector bottom-most/left-most ordering remains the target-order
policy among currently targetable, matching, unreserved cells.

### 8.8D — No ghost robots `[OWNER-LOCKED 2026-09-17]`

**No target, no reservation, no valid route, no robot.** A Scrubbot may be instantiated only
after a unique matching target has been selected, atomically reserved/claimed, and a legal
route to that exact target has been produced and validated. A spawned robot never wanders,
never spawns without work, never silently retargets, and never shares a target with another
robot. Route-build failure releases the provisional claim/reservation and consumes no batch
quota.

### 8.8E — Solvability and deadlock `[OWNER-LOCKED 2026-09-17]`

Generated supply is production-valid only if a deterministic solver can prove at least one
legal player-choice sequence that clears the entire level under the real five-slot, FIFO
column, targetability, claim, routing and batch-quota rules. Runtime must distinguish temporary
WAITING/STALLED states from a proven deadlock. In-flight work or any legal future action that
can open progress means the position is **not** deadlocked. A deadlock may be declared only
when no legal future action sequence can produce further authenticated clearing.

### 8.9 — Scrubbot behavior `[LOCKED]`

- Scrubbots leave slots one at a time.
- A Scrubbot does not leave unless a reachable/targetable matching target
  exists (a blocked/unreachable matching-color ACTIVE cell is not enough).
- A Scrubbot has a valid, reachable target *before* being dispatched.
- It visually moves from slot to target.
- On arrival the target logical pixel becomes CLEARED (transparent; the
  gameplay background shows through).
- It then disappears/finishes.
- It does not collect or carry pixel color.
- It does not return to the slot; no return route is needed.

Scrubbot movement across the picture is one of the most important pieces
of the game's visual identity.

### 8.10 — TargetSelector vs. RoutingSystem `[LOCKED ARCHITECTURE]`

`TargetSelector` answers **WHAT** valid cell should be assigned.
`RoutingSystem` answers **HOW** the Scrubbot travels there visually. Never
combine them. `BoardRenderer` never chooses targets. `ScrubbotAgent` never
searches the board and picks its own arbitrary target. The routing
implementation must remain replaceable (see ADR-005).

### 8.10A — Target selection positional priority `[LOCKED OWNER DECISION — 2026-09-13]`

For a requested slot/color, TargetSelector keeps the canonical eligibility
rules: the candidate must be a valid board index, ACTIVE, matching the requested
color, unreserved, and currently targetable/reachable according to authoritative
access truth. **Among candidates that can otherwise proceed under that contract,
selection priority is bottom-most first (largest board-local `y`), then left-most
within that row (smallest board-local `x`).** A blocked/unreachable lower or
leftward raw candidate never wins merely because of position; the selector
continues to the next candidate in deterministic bottom-to-top / left-to-right
priority. This is a WHAT-policy in TargetSelector only. Routing still decides HOW
to travel to the already-selected target and must not retarget based on geometry.

### 8.10B — Scrubbot Railroad V1 `[OWNER-LOCKED CURRENT — 2026-09-17]`

The exact adjacent one-cell exterior ring proven in M21 V07–V10 remains historical evidence only. `coordination/OWNER_SCRUBBOT_RAILROAD_DECISION_V01.md` remains authoritative for canonical Railroad V1 geometry, while `coordination/OWNER_SCRUBBOT_RAILROAD_INTERIOR_PATH_DECISION_V01.md` supersedes only the old straight-only post-rail target approach.

Railroad V1 uses one consistent robotic cleaning rail around every level. Geometry is derived from board `W×H`: artwork-to-rail inner-edge clearance `2.0` logical cells, rail width `1.0` logical cell, therefore rail centreline `2.5` logical cells outside each board boundary. Scrubbots start from the exact owning SlotCell anchor, visibly connect to the BOTTOM rail, and remain on canonical rail sides/corners during all exterior travel.

A Scrubbot may leave Railroad V1 only through a legal orthogonal ingress into OPEN/CLEARED perimeter gameplay space. Rail departure does **not** have to be aligned with the final target row/column. After ingress, the route may traverse OPEN/CLEARED board cells by four-neighbour orthogonal movement with one or more 90-degree turns. Non-target ACTIVE cells remain hard blockers; the assigned ACTIVE target is enterable only as the final endpoint. No diagonal, corner-cut, teleport, free-space exterior shortcut, non-target ACTIVE tunnelling or retargeting is legal.

For an already-assigned target, routing evaluates legal ingress/interior-path combinations and chooses the shortest legal total route including slot connector, rail travel, ingress, interior path and final arrival. Equal-distance side priority remains `BOTTOM → LEFT → RIGHT → TOP`; same-side ties must be deterministic. TargetSelector §8.10A remains WHAT-only and RoutingSystem remains HOW-only.

Railroad V1 is routing/presentation infrastructure only: it is not LevelData, BoardState, C01..C16 artwork, difficulty truth, batch-supply truth or reservation ownership. Collision/lane/congestion rules remain design-gated unless later owner decisions explicitly lock them.

### 8.10C — Supply-front-only owner gameplay activation `[OWNER-LOCKED CURRENT — 2026-09-17]`

The production player interaction is **selectable front batch click/tap**, not direct slot activation. Normal gameplay has five automatic destination/Scrubbot-origin slots; Economy V1 +1 Slot may expand authoritative capacity to exactly six for the current attempt. Slots are not player-selectable placement controls.

The player may normally activate only the current front/top batch of a supply column. A successful selection transaction sends that batch to the rightmost currently EMPTY slot. If every slot in the current authoritative capacity (5 normally, 6 with +1 Slot active) is occupied, the selection is rejected and the supply column does not advance. Economy V1 Selector is the single owner-authorized exception to normal front-only selection and must use its own atomic/solver-safe transaction. Once a batch occupies a slot, Auto Dispatch later spawns Scrubbots automatically from that exact SlotCell anchor only after the target-claim/reservation/valid-route transaction succeeds.

The historical M21/M22 direct color-slot click path remains valid evidence for those earlier vertical-slice and Railroad tests, but it is superseded as the production core-loop interaction. Do not retain or add hidden keyboard dispatch shortcuts such as SPACE. Presentation input must feed the real Batch Supply → Five-Slot Batch → Claim → Auto Dispatch → Routing → ScrubbotAgent → authenticated clear chain.

### 8.10D — Gameplay speed / automatic endgame acceleration `[OWNER-LOCKED CURRENT — 2026-09-18]`

Production gameplay V1 supports exactly **1x** and **2x** temporal speed. A new level/full reset starts at 1x. Shipping manual 2x is no longer always free: Economy V1 requires a valid current-level entitlement (200 SB) or timed entitlement (15m/300 SB, 30m/500 SB, 60m/750 SB). Timed entitlement uses real wall-clock expiry and continues in gameplay, menus, pause, background and while the app is closed.

The game automatically switches to **2x for free** immediately after authoritative **M23 supply exhaustion**: every 3/4/5 FIFO column has zero remaining batches, including all formerly hidden batches, because the final front-batch transaction has been successfully accepted and committed into M24. The trigger is not full-slot occupancy and is not visible-row emptiness while hidden batches remain. A rejected final transfer does not trigger auto-2x.

2x accelerates time-based gameplay execution/presentation only. It must not change M23 FIFO order, M24 placement/accounting, M25 target/claim arbitration, TargetSelector priority, ReservationState ownership, Railroad/routing geometry, M26 no-ghost semantics, authenticated clears or M27 solver/deadlock meaning. GameplaySpeedAuthority owns factor only; Economy V1 SpeedEntitlementService owns paid manual permission/expiry. Canonical decisions: `coordination/OWNER_GAMEPLAY_SPEED_RULE_V01.md` and `coordination/OWNER_ECONOMY_REWARDS_V01.md`.

### 8.10E — Five-slot displayed batch count `[OWNER-LOCKED CURRENT — 2026-09-19]`

The large/main number shown on an occupied production batch slot means **robots still waiting in that slot**, not raw unresolved quota. Canonical display truth is:

`display_count = M24 capacity = remaining_to_clear - committed`

Example: a newly placed Blue 50 displays 50; after one successful robot commit/dispatch it displays 49 immediately; with two in-flight it displays 48. Authenticated arrival later decrements both `remaining_to_clear` and `committed`, so the visible waiting count does not jump back. The current historical presentation `50 (2)` is superseded.

This is presentation only. M24 authoritative accounting remains unchanged: `remaining_to_clear` decreases only after authenticated clear; `committed` tracks in-flight work; completion still requires remaining=0 and committed=0.

ACTIVE/WAITING internal lifecycle semantics are also unchanged. ACTIVE means eligible/not currently marked unavailable; it does not guarantee a robot is presently moving. WAITING means no currently claimable reachable target for that batch/color, and the batch must be automatically reconsidered after relevant board changes. Canonical decision: `coordination/OWNER_BATCH_SLOT_DISPLAY_DECISION_V01.md`.

### 8.10F — Live five-slot presentation synchronization `[OWNER-LOCKED CURRENT — 2026-09-19]`

The production five-slot strip must reflect **current authoritative M24 state**, not merely the snapshot captured after the last player batch placement.

Fresh detached slot snapshots must be pushed after player-visible M24 mutations including dispatch commit, ACTIVE->WAITING, WAITING->ACTIVE wake, rollback, authenticated-clear finalization, slot completion->EMPTY and reset. UI remains presentation-only and must not run target selection/routing to guess lifecycle state.

Hazard Bot reference: after the first two Blue50 batches have cleared the initial 100 reachable blue cells, the early Brown3 batch still has no immediately reachable brown target in the accepted M27 solution trace. Its player-facing slot state must therefore be WAITING until later black/open-corridor progress wakes it. A stale ACTIVE badge after that point is a presentation-sync defect. Canonical decision: `coordination/OWNER_FIVE_SLOT_LIVE_PRESENTATION_SYNC_DECISION_V01.md`.

### 8.11 — Win streak `[LOCKED — Economy V1]`

```text
1 consecutive progression win   -> +1 SB
2 consecutive progression wins  -> +5 SB
3 consecutive progression wins  -> +10 SB
4 consecutive progression wins  -> +25 SB
5+ consecutive progression wins -> +100 SB per win
```

Never reinterpret `1, 5, 10, 25` as win-count thresholds. Only this streak-bonus SB advances Gift Meter. Every multiple-of-5 active streak also grants +1 Bot Part. Progression loss or restart after gameplay begins resets streak; replay cannot advance it.

### 8.12 — Economy & Rewards V1 `[OWNER-LOCKED 2026-09-18]`

Canonical decision: `coordination/OWNER_ECONOMY_REWARDS_V01.md`. Machine tuning: `data/config/economy_rewards_v1.json`.

- Scrub Bucks are the only general spendable soft currency.
- Stars, Star Exchange and Event Points are removed. Star Exchange becomes Cards Exchange.
- Hearts: max 5, +1 every 30 real-world minutes.
- Bot Parts: robot-unlock-only resource; every post-Scrubby robot costs 250.
- Gift Meter progress comes ONLY from Win Streak SB and has 10/50/250/500/1000 milestones with rollover.
- Exactly four boosters exist: +1 Slot 500 SB, Random 350 SB, Selector 500 SB, Tornado 750 SB.
- Daily has 3 tasks, consecutive-login count and a repeating 5-day reward cycle; Daily and Gift Bar can grant booster charges.
- Duplicate Collection cards exchange to SB; protected first copies cannot be exchanged.
- Real-money monetization remains a separate M57 gate.

### ADR-009 — Explicit preload() convention `[LOCKED UNTIL EXPLICITLY REVISITED]`

Prompt 02 found bare `class_name` cross-script references unreliable in a
headless environment with no prior editor-built global class cache. The
working solution: `const LevelData = preload("res://scripts/data/level_data.gd")`
instead of relying on global class-name resolution. Future scripts in the
data/gameplay/test core should follow this convention unless a future task
deliberately revisits ADR-009 and proves an alternative equally reliable
via headless tests. Do not casually convert back to bare `class_name` for
stylistic reasons.

### Production gameplay background `[LOCKED]`

- BG01 **Midnight Slate** = `#202533` / RGB(32,37,51).
- CLEARED alpha-0 cells reveal BG01 underneath.
- BG01 is not part of C01..C16 and is never a logical LevelData cell
  color, and never counts toward difficulty distinct-color totals.
- Debug-only transparency backgrounds may differ for visibility.

---

## VISUAL REFERENCE SYSTEM

SCRUBBOTS has (per the owner) prior artwork and visual concepts. The
project must use them rather than defaulting to generic programmer art —
but **only artwork that physically exists in this project or is supplied
during a task counts as available**. A visual discussed in a prior chat is
not automatically a local file.

**Verified at time of writing**: owner references and the approved M21 Hazard Bot are now present in-repo; historical “all empty” statements elsewhere are superseded by current inventory/coordination evidence.

### 9.1 — Visual reference priority `[LOCKED]`

**Priority 1 — Owner-approved original SCRUBBOTS artwork.** Canonical
visual reference: character concepts, gameplay concepts, five-slot layouts,
pixel-art level artwork, themed level artwork, original UI ideas, effects
concepts, screen compositions. If original approved artwork conflicts with a
generic placeholder, the original artwork wins.

**Priority 2 — Owner-supplied SCRUBBOTS reference images.** May guide
composition, proportions, pixel-art density, UI positioning, Scrubbot size,
slot size, board presentation, visual hierarchy.

**Priority 3 — External game references.** Inspiration/reference only —
movement density, clarity, pacing, spatial readability, touch ergonomics,
pixel construction methodology. Must never be copied.

### 9.2 — Colony Flow reference limit `[LOCKED]`

May be referenced only for the broad feeling of many tiny agents moving
across a play area and the abstract idea of perimeter travel. SCRUBBOTS intentionally differs in characters, rail visual language, artwork, UI, composition and exact movement implementation:

```text
Correct SCRUBBOTS flow:
  selectable supply-front batch -> automatic rightmost-empty slot -> unique claim/reservation -> valid route -> exact slot connector -> Scrubbot Railroad -> legal OPEN/CLEARED ingress -> orthogonal interior corridor -> clean -> disappear

NOT:
  travel to resource -> collect resource -> carry resource back -> return home
```

Never copy Colony Flow's characters, art, level composition, UI, icons, exact rail/frame appearance, animations, routing visuals, or source code.

### 9.3 — Pixel art reference rule `[LOCKED]`

Previously supplied game screenshots may be used only as reference for
*pixel construction method*, where explicitly approved — never for
characters, compositions, object placement, or level art. External-reference
colors must never redefine the SCRUBBOTS palette. The exact production palette
is owner-locked in §8.7A / `data/palettes/scrubbots_palette_v2.json`.
The goal is understanding how a readable image is built from a limited
logical grid. SCRUBBOTS level artwork remains original.

### 9.4 — Existing SCRUBBOTS level art `[LOCKED]`

Existing original SCRUBBOTS level artwork is intended to become real playable
content once owner-approved source files are supplied/recorded. Never regenerate
such pieces from memory and present the result as “the original.” The M21 Hazard
Bot source is the first owner-approved production-art fixture and must remain
byte-identical unless the owner explicitly replaces it.

### 9.5 — Reference file availability `[LOCKED]`

Claude only has access to artwork physically present in the project or
supplied during the current task. If an expected visual does not exist
locally: `STATUS = AWAITING OWNER ASSET`. Do not fabricate it, do not mark
its audit complete, do not claim a pixel-accurate comparison was performed
against something that doesn't exist locally.

### 9.6 — Recommended visual directory structure

```text
assets/
└── art/
    ├── references/
    │   ├── gameplay/
    │   ├── ui/
    │   ├── scrubbots/
    │   ├── pixel_method/
    │   └── external_inspiration/
    ├── characters/
    │   └── scrubbots/
    ├── levels/
    │   ├── source/
    │   │   ├── easy/
    │   │   ├── medium/
    │   │   ├── hard/
    │   │   └── very_hard/
    │   └── previews/
    ├── ui/
    └── effects/
```

---

## VISUAL PRODUCTION / MASTER UI WORKFLOW [LOCKED OWNER DECISION]

1. Visual production is an integral part of the **main SCRUBBOTS mobile game project and roadmap**. It must not be split into a Level Factory/Content Pipeline-style sidecar or treated as an unrelated final art pass.
2. ChatGPT image generation is the owner-preferred primary illustration-generation workflow for UI/character visual production. Magnific MCP remains an approved fallback/alternate. PixelLab/native pixel AI work is separately scoped to semantic pixel-art generation and does not own puzzle logic.
3. AI image generation is a **development-time tool only**. The shipping game must never require generation APIs, credentials, or credits at runtime. Owner-approved generated outputs become ordinary versioned Godot assets.
4. Existing owner-created SCRUBBOTS artwork is the first visual authority. Import/copy and classify owner references before generating replacements or variants. Never overwrite or delete the owner's originals.
5. AI-generated full-screen mockups are art-direction/reference material, not shippable UI. Production screens must be composed from responsive Godot Controls/Containers plus approved illustration assets.
6. Prefer native Godot UI for panels, buttons/interaction containers, progress bars, slots, color tiles, currency counters, text, popup bodies, dim layers and responsive layout. Use generation for art that genuinely benefits from illustration generation: characters, character poses/portraits, boosters, rewards, difficulty emblems, decorative props, collection/event art and similar branded artwork.
7. Raw generation candidates and owner-approved production assets are different lifecycle states. Never silently regenerate, replace or overwrite an approved production asset.
8. Every milestone that requires new visual assets owns its own visual-generation/review/import tasks. Do not postpone all visual production to one disconnected end-of-project art phase.
9. `docs/MASTER_UI_SYSTEM.md` is the canonical responsive UI architecture contract. `ASSET_GENERATION_MANIFEST.json` is the machine-readable provider-agnostic generation queue/provenance contract; `assets/ui/HOME_ASSET_MANIFEST.json` is the Home-screen preproduction inventory.
10. `BoardRenderer` remains the existing single-`Image`/`ImageTexture` data-oriented renderer. The Master UI system must not replace logical board rendering with one UI node per cell.
11. Visual milestone completion requires actual owner-approved assets where required, correct Godot import/binding, responsive validation and regression evidence. A generated image existing on disk is not by itself completion.
12. Railroad V1 structural geometry is native/data-driven and shared by routing/presentation; V02 does not require generated railroad art. Future visual skinning may not change railroad gameplay geometry.

Home preproduction note (owner decision 2026-09-18): `assets/ui/HOME_ASSET_MANIFEST.json` is preproduction inventory/scaffolding only. Creating the inventory and folders does not close M42 or authorize jumping ahead of M23–M27 core-gameplay sequencing.

### Visual production order

1. **Reference intake and canonical visual selection first.** Import owner references copy-only into the repository reference inbox, inventory/classify them, and select canonical Scrubby/gameplay/home/popup references before broad generation.
2. **Core gameplay engineering continues without waiting for decorative art.** Target selection, routing, dispatcher/agent behavior, cleaning rules and other gameplay-critical work must not be blocked by decorative asset production when programmer art is sufficient.
3. **First real-art vertical slice.** Validate gameplay with owner-approved real level/pixel artwork before treating production visuals as proven. AI image generation must not invent canonical puzzle truth or replace the level-data/puzzle-validation pipeline.
4. **Production gameplay UI asset generation begins when the relevant gameplay UI milestones open.** Generate only assets required by that milestone, review them, promote approved variants, then bind them to reusable Godot components.
5. **Final Scrubbot visual production happens in the existing Scrubbot visual milestone**, using the canonical Scrubby reference and approved visual language.
6. **Home, Results, Tutorial, Collection, Shop, Events and later screens generate their own required assets inside their existing milestones.** They do not wait for a separate global art project.
7. Final visual polish is a consolidation/QA pass over already-integrated milestone-owned art, not the first time production art is introduced.

---

## VISUAL ASSET PRODUCTION STATUS [CONTENT]

Canonical discovery index for Claude/Godot UI integration:
`assets/ui/VISUAL_ASSET_INDEX.md`

- [x] SB-UI-VIS-001 Phase 1 core visual production completed: 306 / 306 canonical targets produced and published.
- [x] SB-UI-VIS-002 Phase 2 main visual batch P2-001..P2-144 completed and published, including branding/system assets, reusable UI kit, booster states, canonical 10-robot presentation families, and system-state icons.
- [x] SB-UI-VIS-003 Collection extraction completed: all 15 sets × 9 cards = 135 individual canonical card PNGs exist under `assets/ui/final/collection/cards/set_01..set_15/`.
- [ ] SB-UI-VIS-004 Integrate/audit the final visual-closure batch P2-145..P2-157 from `codex/visual-assets-production` into `main`. Source commit: `65b26242f996f210a923b4536c7083f6f2d005cc`. This batch contains 9 robot-perk icons, 3 Collection state assets, and the canonical 10-robot Cleaning Crew group art.
- [ ] SB-UI-VIS-005 After P2-145..P2-157 integration, refresh/verify the `main` copy of `assets/ui/VISUAL_ASSET_INDEX.md` so Claude sees the final 157 / 157 Phase 2 targets and complete production paths.
- [ ] SB-UI-VIS-006 Before UI milestone closure, perform owner/Claude pixel-level QA of production assets actually used on-screen: alpha edges, text/watermark absence, mobile readability, identity consistency, compression/import settings. Path existence alone is not visual acceptance.

Static AI visual generation is considered closed after SB-UI-VIS-004/005 unless a new owner-approved feature creates a specific new requirement. Do not generate speculative World Map, XP, Star-currency, leaderboard, event, or monetization art.

---

## DESIGN GATES

Unresolved. Do not silently invent final decisions for these:

railroad collision/congestion/lane-separation presentation; optional railroad glow/trail polish beyond the locked V1 structure; timer; move limits; blockers; hints; analytics; achievements; leaderboard; social features; cloud save; tutorial wording; audio direction.

**Resolved owner decisions:** M30 WIN/LOSE/Retry semantics are locked in `coordination/OWNER_WIN_LOSE_RETRY_DECISION_V01.md`. Economy V1, Hearts, boosters, currency and related soft-economy rules are separately locked in `coordination/OWNER_ECONOMY_REWARDS_V01.md`; real-money monetization remains M57-gated.

**Not design gates**: the global C01..C16 palette, Difficulty V1 progression/challenge architecture, target positional priority, current Railroad V1 geometry/travel/interior-ingress law, five EMPTY batch slots, rightmost-empty automatic placement, 3/4/5 FIFO supply columns, front-row-only selection, same-color oldest-batch-first arbitration, no-ghost-robot transaction law, and solver-backed supply/deadlock contracts are owner-locked.

---

## MASTER MILESTONES

### M00 — Foundation & Environment

Verified complete via repo inspection + this session's re-run of
`tools/verify_project.ps1` and `godot --version`.

- [x] SB-M00-001 Canonical project directory created.
- [x] SB-M00-002 Git repository connected (`origin` = canonical remote).
- [x] SB-M00-003 `main` branch configured and tracked.
- [x] SB-M00-004 Godot project created (`project.godot` valid).
- [x] SB-M00-005 Directory architecture created.
- [x] SB-M00-006 `.gitignore` created.
- [x] SB-M00-007 `CLAUDE.md` created.
- [x] SB-M00-008 Initial documentation created (`docs/00`–`06`).
- [x] SB-M00-009 Bootstrap scene created (`scenes/app/main.tscn`).
- [x] SB-M00-010 Verification helpers created (`tools/*.ps1`).
- [x] SB-M00-011 Godot 4.7.1-stable installed (winget, `GodotEngine.GodotEngine`).
- [x] SB-M00-012 Godot CLI path verified (`godot --version` → `4.7.1.stable.official.a13da4feb`).

Historical M00 version note: the two completed rows above record the version used when M00 was closed. The current project development version is Godot **4.7.2-stable**; do not reinterpret those historical checkboxes as the current runtime/toolchain declaration.
- [x] SB-M00-013 Headless bootstrap test succeeds (`--headless --path . --quit`, no errors).
- [x] SB-M00-014 Main scene parses (confirmed via headless boot).
- [x] SB-M00-015 Existing GDScript parses (confirmed via headless test run).
- [x] SB-M00-016 Bootstrap committed/pushed (`58caeab`, on `origin/main`).

### M01 — Variable-Size Level Data Core

Complete from Prompt 02. Re-verified this session (files exist, test suite
passes).

- [x] SB-M01-001 Level Data V1 implemented (`scripts/data/level_data.gd`).
- [x] SB-M01-002 Width stored in level data.
- [x] SB-M01-003 Height stored in level data.
- [x] SB-M01-004 Cell count derived (`get_cell_count() = width * height`, never stored).
- [x] SB-M01-005 Palette stored separately (array of hex strings, id = index).
- [x] SB-M01-006 Cell palette IDs compact (`PackedInt32Array`, not per-cell strings).
- [x] SB-M01-007 JSON loader implemented (`level_loader.gd`).
- [x] SB-M01-008 Validator implemented (`level_validator.gd`).
- [x] SB-M01-009 Malformed JSON handled (tested, rejected cleanly).
- [x] SB-M01-010 Unsupported version rejected (tested).
- [x] SB-M01-011 Invalid dimensions rejected (width/height ≤ 0, tested).
- [x] SB-M01-012 Wrong cell count rejected (tested).
- [x] SB-M01-013 Invalid palette ID rejected (tested).
- [x] SB-M01-014 Generic dimension support proven (3×2 fixture).
- [x] SB-M01-015 40×40 loads (1,600 cells, tested).
- [x] SB-M01-016 50×50 loads (2,500 cells, tested).
- [x] SB-M01-017 3×2 loads as generic test fixture (tested).
- [x] SB-M01-018 Explicit preload convention documented (ADR-009).

### M02 — BoardState Core

Complete from Prompt 02, re-verified.

- [x] SB-M02-001 BoardState exists (`scripts/gameplay/board/board_state.gd`).
- [x] SB-M02-002 Runtime state separate from LevelData (BoardState built via `from_level_data`, never mutates source).
- [x] SB-M02-003 Source color data copied safely (`_color_ids = level.cells.duplicate()`).
- [x] SB-M02-004 ACTIVE state implemented (`CellState.ACTIVE = 0`; fresh board all-ACTIVE).
- [x] SB-M02-005 CLEARED state implemented (`CellState.CLEARED = 1`).
- [x] SB-M02-006 Coordinate validation exists (`is_valid_coordinate`).
- [x] SB-M02-007 Index validation exists (`is_valid_index`).
- [x] SB-M02-008 Coordinate→index exists (`get_cell_index`).
- [x] SB-M02-009 Index→coordinate exists (`get_cell_position`).
- [x] SB-M02-010 Cell color lookup exists (`get_color_id`).
- [x] SB-M02-011 Cell state lookup exists (`get_cell_state`).
- [x] SB-M02-012 State mutation exists (`set_cell_state`).
- [x] SB-M02-013 State counting exists (`count_cells_by_state`).
- [x] SB-M02-014 Instance independence tested (two BoardStates from same LevelData don't share state).
- [x] SB-M02-015 LevelData immutability behavior tested.
- [x] SB-M02-016 No one-Node-per-cell architecture exists (flat `PackedInt32Array`/`PackedByteArray`).
- [x] SB-M02-017 Add RESERVED only when reservation architecture is designed (see M14). — resolved by ADR-022: reservation is a separate assignment layer; BoardState remains ACTIVE/CLEARED only.

### M03 — Official Difficulty Bands + 59×59 Envelope

Historical runtime-validator milestone. Difficulty V1 later superseded class=dimension as player-facing truth, but the completed compatibility implementation remains audited evidence until separately migrated.

**Documentation**
- [x] SB-M03-001 Search docs for old claim that 40×40 is "standard."
- [x] SB-M03-002 Search docs for claim 50×50 is the Very Hard requirement without a range.
- [x] SB-M03-003 Search for `2500` used as a maximum.
- [x] SB-M03-004 Update `CLAUDE.md`.
- [x] SB-M03-005 Update project brief.
- [x] SB-M03-006 Update gameplay specification.
- [x] SB-M03-007 Update technical architecture.
- [x] SB-M03-008 Update Level Data spec.
- [x] SB-M03-009 Update roadmap.
- [x] SB-M03-010 Update test strategy.
- [x] SB-M03-011 Add/amend ADR for official difficulty dimension bands (ADR-010).

**Production difficulty representation**
- [x] SB-M03-012 Define canonical legacy runtime production difficulty IDs (`DifficultyRules`).
- [x] SB-M03-013 EASY = dimensions 20..29.
- [x] SB-M03-014 MEDIUM = dimensions 30..39.
- [x] SB-M03-015 HARD = dimensions 40..49.
- [x] SB-M03-016 VERY_HARD = dimensions 50..59.
- [x] SB-M03-017 Keep TEST/dev fixture concept separate.
- [x] SB-M03-018 Production validator rejects TEST.

**Validation**
- [x] SB-M03-019 Add production difficulty/dimension validation.
- [x] SB-M03-020 Accept Easy rectangular boards.
- [x] SB-M03-021 Accept Medium rectangular boards.
- [x] SB-M03-022 Accept Hard rectangular boards.
- [x] SB-M03-023 Accept Very Hard rectangular boards.
- [x] SB-M03-024 Reject cross-band Easy dimensions.
- [x] SB-M03-025 Reject cross-band Medium dimensions.
- [x] SB-M03-026 Reject cross-band Hard dimensions.
- [x] SB-M03-027 Reject cross-band Very Hard dimensions.
- [x] SB-M03-028 Produce explicit errors.

### M04 — Expanded Board Fixtures & Test Matrix

Do not replace existing Prompt 02 fixtures — add to them.

- [x] SB-M04-001 3×2 generic non-square fixture exists.
- [x] SB-M04-002 20×20. — [x] SB-M04-003 29×29. — [x] SB-M04-004 20×27.
- [x] SB-M04-005 30×30. — [x] SB-M04-006 39×39. — [x] SB-M04-007 34×39.
- [x] SB-M04-008 40×40 generic fixture exists.
- [x] SB-M04-009 49×49. — [x] SB-M04-010 48×41.
- [x] SB-M04-011 50×50 generic fixture exists.
- [x] SB-M04-012 59×59. — [x] SB-M04-013 53×59.
- [x] SB-M04-014 Easy 20×30 fails legacy production validation.
- [x] SB-M04-015 Medium 39×40 fails.
- [x] SB-M04-016 Hard 49×50 fails.
- [x] SB-M04-017 Very Hard 49×59 fails.
- [x] SB-M04-018 59×59 loads successfully.
- [x] SB-M04-019 `cell_count == 3481`.
- [x] SB-M04-020 Coordinate/index tests pass at 59×59.
- [x] SB-M04-021 State mutation tests pass at 59×59.
- [x] SB-M04-022 Performance sanity benchmark runs at 3,481 cells.
- [x] SB-M04-023 Record results without arbitrary strict timing threshold.

### M05 — Test Harness Maturity

- [x] SB-M05-001 Headless test script exists.
- [x] SB-M05-002 Test process returns failure exit code.
- [x] SB-M05-003 Current tests print PASS/failure information.
- [x] SB-M05-004 No third-party test framework required.
- [x] SB-M05-005 Current baseline checks pass.
- [ ] SB-M05-006 Organize test sections as suite grows.
- [ ] SB-M05-007 Separate performance benchmark output from assertions.
- [ ] SB-M05-008 Add one-command PowerShell full-test wrapper if useful.
- [ ] SB-M05-009 Add regression test conventions to docs.
- [ ] SB-M05-010 Ensure future milestone completion requires regression pass.

### M06 — Board Renderer

- [x] SB-M06-001 Define BoardRenderer responsibility.
- [x] SB-M06-002 Keep BoardRenderer separate from BoardState.
- [x] SB-M06-003 Evaluate efficient Godot rendering options.
- [x] SB-M06-004 Choose Image/ImageTexture technique.
- [x] SB-M06-005 Record technique in ADR.
- [x] SB-M06-006 Render arbitrary width/height.
- [x] SB-M06-007 Support rectangular board aspect ratio.
- [x] SB-M06-008 Preserve logical pixel boundaries.
- [x] SB-M06-009 Disable unwanted texture filtering.
- [x] SB-M06-010 Render palette colors correctly.
- [x] SB-M06-011 Render 20×20. — [x] SB-M06-012 Render 29×29.
- [x] SB-M06-013 Render 39×39. — [x] SB-M06-014 Render 49×49.
- [x] SB-M06-015 Render 50×50. — [x] SB-M06-016 Render 59×59.
- [x] SB-M06-017 Render representative rectangular boards.
- [x] SB-M06-018 Expose logical-cell center coordinate.
- [x] SB-M06-019 Support efficient individual-cell update.
- [x] SB-M06-020 Support full reset.
- [x] SB-M06-021 Benchmark 3,481-cell display.
- [x] SB-M06-022 Confirm no 3,481-cell Node tree exists.

### M07 — Visual Reference Library `[VISUAL REFERENCE]`

- [x] SB-M07-001 Establish reference directory structure.
- [x] SB-M07-002 Create visual-reference README/guide.
- [x] SB-M07-003 Separate original SCRUBBOTS art from external inspiration.
- [x] SB-M07-004 Define canonical asset naming.
- [x] SB-M07-005 Define asset type metadata.
- [x] SB-M07-006 Define owner-approved status.
- [x] SB-M07-007 Preserve source file originals.
- [x] SB-M07-008 Inventory Scrubbot character visuals supplied by owner.
- [x] SB-M07-009 Inventory gameplay-screen references supplied by owner.
- [x] SB-M07-010 Inventory five-slot visual references.
- [ ] SB-M07-011 Inventory level images beyond current M21 source as they are supplied/approved.
- [ ] SB-M07-012 Inventory underwater level artwork if supplied.
- [ ] SB-M07-013 Inventory other original theme artwork.
- [x] SB-M07-014 Inventory pixel-construction reference screenshots.
- [x] SB-M07-015 Inventory external movement references separately.
- [x] SB-M07-016 Flag unavailable assets as `AWAITING OWNER ASSET`.
- [x] SB-M07-017 Never regenerate missing references and label them originals.

**Master UI / generated visual reference tasks (from UI_TASKS_APPENDIX migration)**
- [x] SB-UI-001 Treat `docs/MASTER_UI_SYSTEM.md` as the UI architecture source of truth.
- [x] SB-UI-002 Treat `ASSET_GENERATION_MANIFEST.json` as the machine-readable generation/provenance queue.
- [x] SB-UI-003 Keep approved provider decisions scoped by asset type and newest owner decisions.
- [x] SB-UI-004 Do not add unapproved generation providers as project runtime dependencies.
- [x] SB-UI-005 Import owner visual references copy-only.
- [x] SB-UI-006 Preserve originals/copies byte-for-byte and inventory before promotion.
- [x] SB-UI-007 Classify owner references.
- [ ] SB-UI-008 Select and record canonical Scrubby master reference before final Scrubby production generation.
- [x] SB-UI-009 Select canonical gameplay-screen art-direction reference.
- [x] SB-UI-010 Select canonical Home-screen art-direction reference.
- [x] SB-UI-011 Select canonical popup/level-intro references.
- [x] SB-UI-012 Identify conflicting/outdated references and retain as non-canonical history.
- [ ] SB-UI-013 Validate manifest reference paths/IDs after canonical references are selected.

### M08 — Level Art Technical Audit `[CONTENT] [VISUAL REFERENCE]`

Per candidate production pixel-art level:

- [ ] SB-M08-001 Record filename. — [ ] SB-M08-002 Record original dimensions.
- [ ] SB-M08-003 Record alpha/transparency. — [ ] SB-M08-004 Count colors.
- [ ] SB-M08-005 Detect anti-aliasing. — [ ] SB-M08-006 Detect interpolation.
- [ ] SB-M08-007 Determine logical-pixel grid.
- [ ] SB-M08-008 Determine legal production envelope/context.
- [ ] SB-M08-009 Confirm width in legal engine envelope.
- [ ] SB-M08-010 Confirm height in legal engine envelope.
- [ ] SB-M08-011 Preserve original. — [ ] SB-M08-012 Never silently resize.
- [ ] SB-M08-013 Explicitly map/reject source colors against locked C01..C16; never invent C17+; record deterministic mapping/rejection evidence.
- [ ] SB-M08-014 Produce audit report.

### M09 — Pixel Art → Level Data Pipeline `[CONTENT]`

- [x] SB-M09-001 Create importer tool.
- [x] SB-M09-002 Read source pixels exactly.
- [x] SB-M09-003 Determine width. — [x] SB-M09-004 Determine height.
- [x] SB-M09-005 Determine/validate legacy compatibility difficulty where required.
- [x] SB-M09-006 Extract unique palette.
- [x] SB-M09-007 Produce stable palette ordering.
- [x] SB-M09-008 Convert pixels to palette IDs.
- [x] SB-M09-009 Flatten using canonical row-major mapping.
- [x] SB-M09-010 Produce Level Data V1.
- [x] SB-M09-011 Store source-asset metadata where useful.
- [x] SB-M09-012 Deterministic output.
- [x] SB-M09-013 Re-running importer produces no meaningless diff.
- [x] SB-M09-014 Reconstruct image from generated data.
- [x] SB-M09-015 Pixel-compare reconstruction.
- [x] SB-M09-016 Generate preview.
- [x] SB-M09-017 Reject unsupported/broken art with useful reason.
- [x] SB-M09-018 Batch import.
- [x] SB-M09-019 Batch validation.
- [x] SB-M09-020 Duplicate level ID protection.

**M09 palette-lock note:** M09's completed exact-source-pixel importer remains valid historical/generic tooling evidence, but production acceptance additionally obeys current canonical palette/art/difficulty systems. Historical completion is not rewritten.

### M10 — ACTIVE/CLEARED Board Visual Model `[OWNER DECISION LOCKED]`

- [x] SB-M10-001 ACTIVE appearance locked to original source palette color, opaque.
- [x] SB-M10-002 CLEARED appearance locked to alpha 0/background visible.
- [x] SB-M10-003 Define artwork-clearing relationship.
- [x] SB-M10-004 Implement visual mapping.
- [x] SB-M10-005 Owner-confirm clearing readability.
- [x] SB-M10-006 Owner-confirm ACTIVE artwork recognition.
- [x] SB-M10-007 Owner test Easy density. — [x] SB-M10-008 Owner test Medium density.
- [x] SB-M10-009 Owner test Hard density. — [x] SB-M10-010 Owner test Very Hard density.
- [x] SB-M10-011 Owner test 59×59 transparent-model readability.
- [x] SB-M10-012 Development debug tool migrated/proven.

### M11 — Gameplay Session Core

- [x] SB-M11-001 Define session states.
- [x] SB-M11-002 Initialize level. — [x] SB-M11-003 Load LevelData.
- [x] SB-M11-004 Create BoardState. — [x] SB-M11-005 Connect renderer.
- [x] SB-M11-006 Define ready state. — [x] SB-M11-007 Define active state.
- [x] SB-M11-008 Define pause. — [x] SB-M11-009 Define reset.
- [x] SB-M11-010 Define completion transition.
- [x] SB-M11-011 Keep UI separate from gameplay truth.
- [x] SB-M11-012 Headless lifecycle tests.

### M12 — Five-Slot Logic

- [x] SB-M12-001 Create SlotState. — [x] SB-M12-002 Create SlotSystem.
- [x] SB-M12-003 Configure five gameplay slots.
- [x] SB-M12-004 Slot identity. — [x] SB-M12-005 Slot palette/color.
- [x] SB-M12-006 Slot availability. — [x] SB-M12-007 Slot activity state.
- [x] SB-M12-008 Keep model separate from UI. — [x] SB-M12-009 Query API.
- [x] SB-M12-010 Five-slot tests. — [x] SB-M12-011 Invalid slot tests.

Remaining slot mechanics are `[DESIGN GATE]` except where newer owner decisions explicitly lock behavior.

### M13 — Color Candidate Index `[PERFORMANCE]`

- [x] SB-M13-001 Define color candidate.
- [x] SB-M13-002 Group/query by color.
- [x] SB-M13-003 Implement efficient index/cache if measured useful.
- [x] SB-M13-004 Synchronize with BoardState.
- [x] SB-M13-005 Remove CLEARED cells from the index. — [x] SB-M13-006 Handle caller exclusions/reservations seam.
- [x] SB-M13-007 No-candidate query. — [x] SB-M13-008 Exhausted-color test.
- [x] SB-M13-009 Last-candidate test. — [x] SB-M13-010 3,481-cell benchmark.

### M14 — Reservation State

- [x] SB-M14-001 Define reservation ownership.
- [x] SB-M14-002 Decide RESERVED placement.
- [x] SB-M14-003 Record decision.
- [x] SB-M14-004 Reserve target atomically.
- [x] SB-M14-005 Prevent double reservation.
- [x] SB-M14-006 Release on dispatch failure. — [x] SB-M14-007 Release on reset.
- [x] SB-M14-008 Resolve arrival. — [x] SB-M14-009 Concurrency tests.

### M15 — TargetSelector

M15 strict closure remains accepted. V04 later superseded only its target ordering policy while preserving strict safety contracts.

- [x] SB-M15-001 Create TargetSelector.
- [x] SB-M15-002 Keep BoardState access narrow.
- [x] SB-M15-003 Deterministic strategy. **Current production ordering is owner rule §8.10A: bottom-most then left-most among targetable candidates.**
- [x] SB-M15-004 Match Scrubbot color.
- [x] SB-M15-005 Never target CLEARED. — [x] SB-M15-006 Never target invalid or blocked/unreachable ACTIVE cells.
- [x] SB-M15-007 Respect reservations.
- [x] SB-M15-008 Return no-target cleanly.
- [x] SB-M15-009 No route generation inside selector.
- [x] SB-M15-010 Determinism tests.
- [x] SB-M15-011 Simultaneous assignment tests.
- [x] SB-M15-012 3,481-cell benchmark.

### M16 — RoutingSystem Interface

- [x] SB-M16-001 Define RoutingSystem contract.
- [x] SB-M16-002 Define route input. — [x] SB-M16-003 Define route output.
- [x] SB-M16-004 Define coordinate space.
- [x] SB-M16-005 Slot origin. — [x] SB-M16-006 Cell destination.
- [x] SB-M16-007 Keep independent from TargetSelector.
- [x] SB-M16-008 Swappable implementations.
- [x] SB-M16-009 Debug route visualization.
- [x] SB-M16-010 Route validity checks.
- [x] SB-M16-011 Failure behavior/no silent retarget.

### M17 — Routing Prototype Lab / Production Routing

M17-C002 V03 strict full-surface audit remains accepted as the pre-V07 production-routing baseline. V07 added the adjacent one-cell exterior ring and remains valid historical M21 evidence. The 2026-09-14 owner decision in `OWNER_SCRUBBOT_RAILROAD_DECISION_V01.md` supersedes that exact exterior geometry for future production once M22 V02 passes audit; the M17 safety contracts remain mandatory.

- [x] SB-M17-001 Direct route baseline.
- [x] SB-M17-002 Grid-aware route prototype.
- [x] SB-M17-003 Organized polyline/curved prototype.
- [x] SB-M17-004 Compare visual clarity. — [x] SB-M17-005 Compare path crossings.
- [x] SB-M17-006 Compare congestion. — [x] SB-M17-007 Compare CPU cost.
- [x] SB-M17-008 Compare route distance. — [x] SB-M17-009 Compare determinism.
- [x] SB-M17-010 Owner-selected organized/curved production movement language.
- [x] SB-M17-011 Test 5 bots. — [x] SB-M17-012 Test 10 bots. — [x] SB-M17-013 Test 25 bots.
- [x] SB-M17-014 Stress-test higher density.
- [x] SB-M17-015 Test 59×59. — [x] SB-M17-016 Test rectangular board.

**Historical V07 amendment:** the one-cell exterior ring proved exterior reachability and is preserved as audit history. **Current owner target:** Railroad V1 must preserve route validation, no-retarget, ACTIVE-blocker/CLEARED-open semantics, rectangular support and 59×59 behavior while replacing the exact adjacent-ring movement geometry.

### M18 — Scrubbot Agent

- [x] SB-M18-001 Lightweight agent core.
- [x] SB-M18-002 Assigned color. — [x] SB-M18-003 Assigned target.
- [x] SB-M18-004 Assigned route. — [x] SB-M18-005 Spawn origin.
- [x] SB-M18-006 Route movement. — [x] SB-M18-007 Arrival detection.
- [x] SB-M18-008 Completion event. — [x] SB-M18-009 Despawn.
- [x] SB-M18-010 No return-to-slot. — [x] SB-M18-011 No resource carrying.
- [x] SB-M18-012 Reset cancellation. — [x] SB-M18-013 No orphan nodes.
- [x] SB-M18-014 Performance stress test.
- [x] SB-M18-015 Pool only if profiling justifies it.

### M19 — Scrubbot Dispatcher

**Strict-v2 final closure:** M19-C001 V06 `AUDITED_PASS / STRICT_V2_FINAL_CLOSURE`.

- [x] SB-M19-001 Receive slot request.
- [x] SB-M19-002 Check reachable work before spawn.
- [x] SB-M19-003 Ask TargetSelector.
- [x] SB-M19-004 Refuse spawn without reachable target.
- [x] SB-M19-005 Reserve target.
- [x] SB-M19-006 Spawn exactly one bot per dispatch.
- [x] SB-M19-007 Enforce one-by-one flow.
- [x] SB-M19-008 Prevent duplicate assignments.
- [x] SB-M19-009 Handle dispatch failure.
- [x] SB-M19-010 Handle rapid input.
- [x] SB-M19-011 Concurrent slot tests. — [x] SB-M19-012 Reset during dispatch.

### M20 — Complete Clearing Vertical Slice

- [x] SB-M20-001 Wire complete sequence.
- [x] SB-M20-002 No target means no bot. — [x] SB-M20-003 No return behavior.
- [x] SB-M20-004 One-cell test. — [x] SB-M20-005 One-color test.
- [x] SB-M20-006 Multi-color test. — [x] SB-M20-007 Five-slot test.
- [x] SB-M20-008 Easy board test. — [x] SB-M20-009 Medium board test.
- [x] SB-M20-010 Hard board test. — [x] SB-M20-011 Very Hard board test.
- [x] SB-M20-012 59×59 stress test. — [x] SB-M20-013 Rectangular board test.
- [x] SB-M20-014 State-desynchronization check.

### M21 — First Real-Art Vertical Slice `[CONTENT] [VISUAL REFERENCE]`

**Strict-v2 final closure:** M21-C001 V10 `AUDITED_PASS / STRICT_V2_FINAL_CLOSURE` (`coordination/sessions/M21-C001/CHATGPT_AUDIT_V10.md`). Owner manual V07 Godot gate PASS remains part of the closure basis. V08–V10 were production-immutable validation passes.

The owner-approved real Hazard Bot source is:
`assets/art/levels/source/easy/scrubbots_m21_level_001_hazard_bot_20x20.png`.

Locked runtime outcomes carried forward:
- visible slot-click-only gameplay activation; no SPACE/hidden keyboard dispatch;
- historical-at-M21-close adjacent one-logical-cell exterior routing ring on all four sides, now superseded as future production geometry by Railroad V1 while its safety evidence remains valid;
- TargetSelector bottom-most then left-most among currently targetable matching cells;
- fresh Hazard Bot C08 first target index `380`, coordinate `(0,19)`;
- real clicked-slot spawn anchor -> routing -> authenticated arrival -> ACTIVE→CLEARED transparency;
- exact ReservationState/dispatcher/agent lifecycle under rapid input and reset;
- full 400-cell real-art clear across all five colors;
- reference composite and generated LevelData/preview/metadata reproducible/unchanged.

- [x] SB-M21-001 Ingest original source artwork.
- [x] SB-M21-002 Audit source dimensions.
- [x] SB-M21-003 Determine legal compatibility context.
- [x] SB-M21-004 Generate level data.
- [x] SB-M21-005 Reconstruct and compare.
- [x] SB-M21-006 Render in gameplay.
- [x] SB-M21-007 Populate and visibly present exactly five functional slots bound to the real SlotSystem.
- [x] SB-M21-008 Dispatch a visibly moving real ScrubbotAgent from the clicked visible slot through board-aligned presentation and exterior corridor.
- [x] SB-M21-009 Clear actual artwork pixels (ACTIVE→CLEARED; transparent background reveal).
- [x] SB-M21-010 Run full level.
- [x] SB-M21-011 Profile performance.
- [x] SB-M21-012 Capture reference gameplay output.

**First real-art vertical slice additions**
- [x] SB-UI-014 Run at least one gameplay vertical slice using owner-approved real pixel/level artwork.
- [x] SB-UI-015 Prove logical renderer/ACTIVE-CLEARED treatment/responsive presentation remain data-driven.
- [x] SB-UI-016 Record visual gaps requiring later illustration generation.

### M22 — Production Slot UI `[VISUAL REFERENCE]`

**V01 audit:** `AUDITED_PASS / PRODUCTION_SLOT_FOUNDATION_ACCEPTED` (`coordination/sessions/M22-C001/CHATGPT_AUDIT_V01.md`). V01 created the reusable native-Godot production SlotCell/ColorSelectionPanel foundation, corrected the active manifest palette/difficulty contract, validated real reference authority, touch size, responsive/safe-area behavior, active-state lifecycle and real slot-click integration while spending zero Magnific credits.

**Railroad V1 closure — V07 + owner acceptance (2026-09-17):** the accepted production movement contract is now exact clicked-slot anchor → visible BOTTOM connector → canonical Railroad V1 exterior travel → legal rail ingress → four-neighbour orthogonal OPEN/CLEARED interior corridor with one or more 90-degree turns → assigned ACTIVE target. Non-target ACTIVE cells remain blockers; no diagonal/corner-cut/teleport/free-space shortcut and no retargeting are allowed. V07 implementation evidence recorded 4,823 checks / 0 failures and preserved the fresh Hazard Bot C08 first target `380/(0,19)`. Owner manual review confirmed the routing correction. The earlier straight-only final target approach is superseded.

- [x] SB-M22-001 Audit slot references. — [x] SB-M22-002 Create SlotView.
- [x] SB-M22-003 Five-slot layout. — [x] SB-M22-004 Bind SlotState through safe scalar/query presentation binding.
- [x] SB-M22-005 Color presentation. — [x] SB-M22-006 Touch target.
- [x] SB-M22-007 Active state. — [ ] SB-M22-008 No-work state if approved.
- [x] SB-M22-009 Scrubbot spawn point / final slot→rail connector geometry.
- [x] SB-M22-010 Aspect-ratio tests. — [x] SB-M22-011 Safe-area tests.
- [x] SB-M22-012 Rapid-tap tests.
- [x] SB-M22-013 Confirm canonical gameplay UI references before final asset generation.
- [x] SB-M22-014 Validate M22 manifest entries before spending generation credits.
- [ ] SB-M22-015 Generate the four owner-locked gameplay booster assets (+1 Slot, Random, Selector, Tornado) when Economy V1 implementation scope opens.
- [ ] SB-M22-016 Generate only milestone-required decorative assets.
- [ ] SB-M22-017 Keep raw candidates separate from production-final assets/provenance.
- [ ] SB-M22-018 Require owner selection/approval before production promotion.
- [ ] SB-M22-019 Never silently regenerate/overwrite approved production art.
- [x] SB-M22-020 Build slot visuals as reusable Godot components.
- [ ] SB-M22-021 Keep quantities/text/state badges live in Godot.
- [ ] SB-M22-022 Implement reusable BoosterButton states for CHARGE_AVAILABLE / PURCHASABLE_SB / SELECTED / UNAVAILABLE / LOCKED when Economy V1 booster scope opens.
- [ ] SB-M22-023 Bind approved booster/decorative art to reusable components.
- [x] SB-M22-024 Preserve five visible slots at required responsive sizes.
- [ ] SB-M22-025 Validate import/transparency/filtering/mobile memory before visual closure.

**Railroad V1 additions [OWNER-LOCKED 2026-09-14]**
- [x] SB-M22-026 Implement one canonical/single-source ScrubRail geometry contract from board W/H.
- [x] SB-M22-027 Implement reusable four-side robotic cleaning railroad presentation with rounded corners and restrained cyan/electric accents.
- [x] SB-M22-028 Enforce 2.0 logical-cell artwork clearance, 1.0 rail width and 2.5-cell rail centerline offset across variable board sizes.
- [x] SB-M22-029 Connect each real clicked SlotCell visibly to the BOTTOM rail from its exact laid-out spawn anchor.
- [x] SB-M22-030 Constrain exterior Scrubbot travel to railroad sides/corners; prohibit free-space diagonal/early-exit shortcuts.
- [x] SB-M22-031 Leave Railroad V1 only through a legal rail ingress into OPEN/CLEARED perimeter space; permit four-neighbour orthogonal interior-corridor routing with one or more 90-degree turns; never retarget.
- [x] SB-M22-032 Use one consistent Railroad V1 visual language across all levels; no per-level themed rail in V1.
- [x] SB-M22-033 Validate Railroad V1 on rectangular boards, 59×59 and the required responsive viewport matrix.
- [x] SB-M22-034 Preserve rapid-dispatch reservations/active visuals and reset cleanup while multiple Scrubbots are on connector/rail travel.
- [x] SB-M22-035 Owner F6 visual/game-feel acceptance of the production Railroad V1 demo after strict audit.

### M23 — Batch Supply Engine `[OWNER-LOCKED CORE GAMEPLAY]`

Purpose: create the player-facing color/count supply queues that drive the real ScrubBots puzzle. This milestone owns batch data, queue/preview semantics and candidate generation, but does not own five-slot execution, target claims, robot dispatch or solvability proof.

- [x] SB-M23-001 Define immutable `ColorBatch` value contract.
- [x] SB-M23-002 Give every batch a stable unique `batch_id` for the lifetime of a session.
- [x] SB-M23-003 Store canonical palette/color ID, never presentation-only color guesses.
- [x] SB-M23-004 Store strictly positive integer `robot_count`; reject zero, negative, float, string or overflow values.
- [x] SB-M23-005 Preserve per-color conservation: total generated batch quota for each color must equal that level's required ACTIVE logical-pixel count for that color unless a later explicit owner rule changes the economy.
- [x] SB-M23-006 Reject supply containing palette IDs absent from the loaded level/palette contract.
- [x] SB-M23-007 Support exactly 3, 4 or 5 independent supply columns as configuration; do not hard-code one layout into gameplay truth.
- [x] SB-M23-008 Support configurable visible preview depth 3 or 4, with V1/Hazard Bot validation locked to exactly 3 visible rows.
- [x] SB-M23-009 Make only the front/top batch of each column selectable.
- [x] SB-M23-010 Make visible Row 2 and Row 3 preview-only in V1; they must reject gameplay activation.
- [x] SB-M23-011 Keep every batch deeper than the visible preview window hidden from player-facing query/UI APIs.
- [x] SB-M23-012 Implement each supply column as an independent FIFO queue.
- [x] SB-M23-013 Selecting a legal front batch removes exactly that one front item from exactly that one column.
- [x] SB-M23-014 After selection, advance that column by one: old Row 2→front, old Row 3→Row 2, next hidden→Row 3.
- [x] SB-M23-015 Prove selecting one column does not mutate ordering/content of any other column.
- [x] SB-M23-016 Expose read-only front-batch queries for gameplay selection.
- [x] SB-M23-017 Expose read-only preview queries that cannot reveal hidden queue contents.
- [x] SB-M23-018 Make supply consumption transactional so a rejected downstream slot placement cannot accidentally pop/advance the column.
- [x] SB-M23-019 Define deterministic seedable candidate generation for reproducible tests/replays.
- [x] SB-M23-020 Persist/report the generation seed with the session fixture/evidence.
- [x] SB-M23-021 Partition each level color total into legal positive batch sizes without losing or inventing quota.
- [x] SB-M23-022 Distribute generated batches across configured columns without changing per-color conservation.
- [x] SB-M23-023 Avoid malformed queues: no null batch, duplicate `batch_id`, negative count, invalid color or impossible index.
- [x] SB-M23-024 Define clean end-of-column behavior when fewer than the normal preview rows remain.
- [x] SB-M23-025 Define clean end-of-supply behavior when every column is exhausted.
- [x] SB-M23-026 Provide deterministic reset to the exact initial queue/seed state.
- [x] SB-M23-027 Provide snapshot/query data needed later by save/replay systems without coupling to UI Nodes.
- [x] SB-M23-028 Build Hazard Bot candidate supply fixtures from the real 20×20 level color totals.
- [x] SB-M23-029 Validate rectangular-board and 59×59 quota/conservation behavior.
- [x] SB-M23-030 Add invalid-input, deterministic-generation, FIFO, hidden-preview and conservation regression tests.

### M24 — Five-Slot Batch Engine `[OWNER-LOCKED CORE GAMEPLAY]`

Purpose: replace the temporary directly-colored slot interaction with the real five EMPTY baseline batch slots. Player chooses a supply batch; the engine chooses the slot automatically.

**Economy V1 amendment:** the accepted M24 implementation remains the five-slot baseline. M39 must add an explicit runtime-capacity extension 5→6 for the +1 Slot booster without falsifying historical M24 audit evidence.

- [x] SB-M24-001 Preserve the production invariant of exactly five gameplay batch slots.
- [x] SB-M24-002 Initialize all five batch slots EMPTY at level/session start.
- [x] SB-M24-003 Define `SlotBatchState` independent of Godot presentation controls.
- [x] SB-M24-004 Store `batch_id`, color ID, initial count, remaining-to-clear count, committed/in-flight count and placement sequence per occupied slot.
- [x] SB-M24-005 Define explicit slot lifecycle states at minimum `EMPTY`, `ACTIVE` and `WAITING` without duplicating BoardState truth.
- [x] SB-M24-006 On accepted supply selection, place the batch automatically into the rightmost currently EMPTY slot.
- [x] SB-M24-007 Do not expose any production mechanic that asks the player to choose a destination slot.
- [x] SB-M24-008 Never shift, reorder or compact already-occupied slots merely because another slot becomes empty.
- [x] SB-M24-009 If holes exist, choose the rightmost available hole deterministically.
- [x] SB-M24-010 If all five slots are occupied, reject the new batch atomically.
- [x] SB-M24-011 On full-slot rejection, prove the originating supply column does not advance and the batch remains selectable.
- [x] SB-M24-012 Allow multiple occupied slots to contain the same color simultaneously.
- [x] SB-M24-013 Preserve stable batch identity after placement; never merge same-color batches silently.
- [x] SB-M24-014 Enforce `0 <= committed <= remaining_to_clear <= initial_count` at all times.
- [x] SB-M24-015 Define dispatch capacity as `remaining_to_clear - committed`.
- [x] SB-M24-016 Do not reduce `remaining_to_clear` on player selection, claim, route calculation or spawn.
- [x] SB-M24-017 Reduce `remaining_to_clear` only after authenticated successful clearing of one batch-owned target.
- [x] SB-M24-018 Reduce `committed` when the corresponding live assignment resolves or is safely rolled back.
- [x] SB-M24-019 A batch is complete only when `remaining_to_clear == 0` and `committed == 0`.
- [x] SB-M24-020 Return the slot to EMPTY immediately and deterministically after true batch completion.
- [x] SB-M24-021 If remaining quota exists but no matching target is currently claimable, enter WAITING without discarding the batch.
- [x] SB-M24-022 Resume a WAITING batch automatically when later BoardState changes expose claimable matching work.
- [x] SB-M24-023 Ensure a newly freed slot can accept the next player-selected supply batch using the same rightmost-empty rule.
- [x] SB-M24-024 Expose read-only slot occupancy/count/state queries for presentation without leaking mutable internal state.
- [x] SB-M24-025 Preserve exact slot/batch state across pause/resume.
- [x] SB-M24-026 Reset clears all batch occupancy, counters, placement sequence and transient state deterministically.
- [x] SB-M24-027 Make rapid repeated supply selections transactional; no duplicate batch insertion or double column advance.
- [x] SB-M24-028 Add the canonical three-same-color example (`BLUE 8`, `BLUE 14`, `BLUE 12`) as a regression fixture.
- [x] SB-M24-029 Test five-full-slot rejection followed by a completion/free-slot/new-selection cycle.
- [x] SB-M24-030 Add headless invariant tests for every state transition and invalid slot/batch mutation.

### M25 — Batch Target Claim Engine `[OWNER-LOCKED CORE GAMEPLAY]`

Purpose: arbitrate currently targetable pixels among multiple live batches, especially duplicate colors, while preserving ReservationState and TargetSelector as the existing low-level safety authorities.

- [x] SB-M25-001 Define a session-scoped Batch Target Claim service/ledger with narrow APIs.
- [x] SB-M25-002 Keep existing `ReservationState` as the authoritative live target-reservation mechanism; do not create contradictory duplicate reservation truth.
- [x] SB-M25-003 Represent each live claim with batch ID, slot ID, target index/coordinate, color and reservation/assignment identity.
- [x] SB-M25-004 Permit claims only for currently ACTIVE, matching-color, valid, unreserved and production-targetable pixels.
- [x] SB-M25-005 Never pre-claim a future pixel that is currently blocked/unreachable merely because it may become reachable later.
- [x] SB-M25-006 Support multiple simultaneous occupied batches of the same color.
- [x] SB-M25-007 Arbitrate same-color batches by oldest placement sequence first (FIFO).
- [x] SB-M25-008 Make placement-sequence arbitration deterministic across reset/replay fixtures.
- [x] SB-M25-009 Keep giving newly claimable work to the oldest same-color batch while it has uncommitted dispatch capacity.
- [x] SB-M25-010 When the oldest batch has no remaining dispatch capacity, allow additional matching targets to flow to the next same-color batch.
- [x] SB-M25-011 Keep different colors independent except for shared global ReservationState uniqueness.
- [x] SB-M25-012 Preserve TargetSelector's bottom-most then left-most order among currently targetable matching unreserved candidates.
- [x] SB-M25-013 Make target selection + batch ownership claim + ReservationState reservation one atomic logical transaction.
- [x] SB-M25-014 Prove one target index can never belong to two live batches/robots at once.
- [x] SB-M25-015 Prove one batch can never create duplicate live claims to the same target.
- [x] SB-M25-016 Refuse claim when the batch has zero dispatch capacity.
- [x] SB-M25-017 Increment `committed` exactly once when a claim becomes an accepted live assignment.
- [x] SB-M25-018 Do not change `remaining_to_clear` merely because a claim exists.
- [x] SB-M25-019 If route construction/validation fails before spawn, atomically release claim and reservation, decrement committed appropriately, consume zero batch quota and spawn no robot.
- [x] SB-M25-020 On authenticated arrival/clear, resolve exactly the claim associated with that robot/assignment.
- [x] SB-M25-021 Never allow a robot to clear any target other than its immutable claimed target.
- [x] SB-M25-022 On successful authenticated clear, decrement batch remaining and committed exactly once.
- [x] SB-M25-023 Fail closed on stale/already-cleared/invalid claim state; no duplicate clear, no quota loss and no ghost spawn.
- [x] SB-M25-024 Release every live claim/reservation safely on reset/session teardown.
- [x] SB-M25-025 Prevent slot completion while any claim/assignment for that batch remains committed.
- [x] SB-M25-026 Mark a batch WAITING when it has remaining quota but no claimable matching target.
- [x] SB-M25-027 Re-evaluate waiting colors after authoritative BoardState clear events rather than polling mutable UI state.
- [x] SB-M25-028 Add simultaneous same-color claim race tests under rapid scheduler activity.
- [x] SB-M25-029 Prove `BLUE 8`, `BLUE 14`, `BLUE 12` cannot target the same pixel and obey oldest-batch-first ownership when new blue pixels open.
- [x] SB-M25-030 Prove newly opened targets are assigned at opening time, not pre-owned while inaccessible.
- [x] SB-M25-031 Stress five occupied slots with duplicate colors on rectangular and 59×59 boards.
- [x] SB-M25-032 Add claim/reservation leak, reset, stale-target and deterministic-order regression tests.

### M26 — Auto Dispatch Scheduler `[OWNER-LOCKED CORE GAMEPLAY]`

Purpose: turn an occupied color/count batch into autonomous Scrubbot work. The player selects batches, not individual robots and not individual target pixels.

- [x] SB-M26-001 Define a gameplay-domain Auto Dispatch Scheduler independent of presentation/UI animation.
- [x] SB-M26-002 Automatically attempt work for every occupied batch without requiring repeated player taps on the five slots.
- [x] SB-M26-003 Begin scheduling a newly accepted batch immediately after transactional placement.
- [x] SB-M26-004 Enforce the hard invariant: no currently valid target means no robot spawn.
- [x] SB-M26-005 Enforce the hard invariant: no successful atomic reservation/claim means no robot spawn.
- [x] SB-M26-006 Enforce the hard invariant: no valid RouteValidator-clean route to the exact claimed target means no robot spawn.
- [x] SB-M26-007 Enforce transaction order `claim/reserve → build route → validate route → spawn exact assignment`.
- [x] SB-M26-008 Never retarget after route/assignment acceptance; a failed assignment is rolled back rather than redirected silently.
- [x] SB-M26-009 Spawn from the exact owning SlotCell anchor and preserve the accepted slot→BOTTOM connector + Railroad V1 route semantics.
- [x] SB-M26-010 Spawn exactly one Scrubbot per successful assignment transaction.
- [x] SB-M26-011 Pace sequential dispatch from a given batch/slot; do not materialize its entire count as an uncontrolled one-frame robot burst.
- [x] SB-M26-012 Permit safe concurrent work from different occupied slots when each assignment has a unique reservation/route.
- [x] SB-M26-013 Define deterministic scheduler fairness across different-color ACTIVE batches so one busy color cannot starve all others.
- [x] SB-M26-014 For same-color batches, defer ownership ordering to the Batch Target Claim Engine's oldest-placement-first rule.
- [x] SB-M26-015 Prove a `BLUE 15` batch can autonomously complete exactly 15 authenticated blue-pixel clears when the board makes them legally available.
- [x] SB-M26-016 Track committed/in-flight capacity so a batch never dispatches more robots than its remaining quota permits.
- [x] SB-M26-017 Decrement quota only from successful authenticated clearing callbacks, never from scheduler intent or spawn count.
- [x] SB-M26-018 When no claimable work exists, transition to WAITING without busy-looping, phantom agents or repeated reservation churn.
- [x] SB-M26-019 Wake/reconsider relevant WAITING colors when BoardState clearing changes reachability.
- [x] SB-M26-020 When one new blue pixel opens and several blue batches wait, request arbitration and dispatch only the batch selected by the same-color FIFO rule.
- [x] SB-M26-021 If the oldest same-color batch has only N dispatch-capacity units left and more than N targets open, allow only N claims to it and spill additional claims to the next batch deterministically.
- [x] SB-M26-022 Auto-finish a batch after its final authenticated clear/assignment resolves and return the slot to EMPTY.
- [x] SB-M26-023 Ensure freeing a slot does not reorder other occupied slots or mutate supply queues.
- [x] SB-M26-024 Pause prevents new dispatches while preserving valid in-memory batch/claim state according to session rules.
- [x] SB-M26-025 Resume safely restarts scheduling without duplicate claims/spawns.
- [x] SB-M26-026 Reset/session teardown cancels in-flight scheduling, releases reservations/claims and leaves no orphan Scrubbot Nodes.
- [x] SB-M26-027 Rapid input / simultaneous column selections cannot double-spawn, over-commit quota or duplicate target reservations.
- [x] SB-M26-028 Validate scheduler behavior with multiple duplicate-color batches plus different-color batches concurrently.
- [x] SB-M26-029 Run 59×59/high-agent-density performance sanity and allocation checks.
- [x] SB-M26-030 Add a full Hazard Bot auto-dispatch integration smoke proving no ghost robots, no duplicate targets and exact quota conservation.

### M27 — Solvability / Deadlock Engine `[OWNER-LOCKED CORE GAMEPLAY]`

Purpose: prove generated supply is actually playable under the real baseline mechanics and distinguish temporary waiting from a true no-solution state. This milestone is the final gameplay-engine closure gate before production screen/layout work.

**Economy V1 amendment:** accepted M27 evidence proves the five-slot baseline. M39 must extend solver state/fixtures for temporary six-slot capacity and for Random/Selector/Tornado transactions; do not retroactively claim the completed baseline already proves those booster states.

- [x] SB-M27-001 Define a deterministic solver operating on gameplay-domain state, not rendered UI Nodes.
- [x] SB-M27-002 Consume the real level BoardState/access/routing semantics rather than a contradictory simplified notion of reachability.
- [x] SB-M27-003 Model configured 3/4/5 independent FIFO supply columns.
- [x] SB-M27-004 Model the visible-front rule: only each column's front batch is a legal player choice.
- [x] SB-M27-005 Model preview/hidden queue ordering without allowing the solver to illegally select Row 2/Row 3/hidden batches early.
- [x] SB-M27-006 Model automatic rightmost-empty placement into exactly five slots.
- [x] SB-M27-007 Model full-slot rejection without consuming the selected supply front.
- [x] SB-M27-008 Model batch remaining/committed/WAITING lifecycle exactly as the runtime engine does.
- [x] SB-M27-009 Model same-color oldest-placement-first claim arbitration.
- [x] SB-M27-010 Model targetability using authoritative ProductionTargetAccess/ProductionRoutingSystem semantics, including Railroad V1 legal ingress and post-rail orthogonal turns.
- [x] SB-M27-011 Model dynamic ACTIVE→CLEARED board evolution after authenticated work.
- [x] SB-M27-012 Model WAITING batches becoming runnable when new corridors/targets open.
- [x] SB-M27-013 Search legal player front-batch choices rather than assuming one fixed greedy order.
- [x] SB-M27-014 Find at least one complete sequence that clears every required logical pixel and consumes all required batch quota.
- [x] SB-M27-015 Emit a deterministic solution trace for QA/debug evidence; never expose it to normal player UI.
- [x] SB-M27-016 Accept a generated Batch Supply layout for production only after the solver proves at least one legal completion sequence.
- [x] SB-M27-017 Feed unsolvable candidate layouts back to Batch Supply generation for deterministic retry/regeneration rather than shipping impossible levels.
- [x] SB-M27-018 Preserve generation seed + solver outcome so an accepted/rejected supply can be reproduced exactly.
- [x] SB-M27-019 Canonicalize/memoize equivalent search states to prevent needless combinatorial re-exploration.
- [x] SB-M27-020 Add explicit search/time/state-count bounds and fail closed when proof cannot be completed within policy limits.
- [x] SB-M27-021 Prove the real 20×20 Hazard Bot level has at least one solvable generated batch/column layout under the new five-slot rules.
- [x] SB-M27-022 Persist the Hazard Bot solution trace as regression evidence while keeping player-hidden future batches hidden at runtime.
- [x] SB-M27-023 Add rectangular-board solvability fixtures.
- [x] SB-M27-024 Add 59×59 solver/performance sanity fixtures with bounded evidence appropriate to the search design.
- [x] SB-M27-025 Define `STALLED/WAITING` separately from `DEADLOCK`.
- [x] SB-M27-026 Never call a state deadlocked while any valid in-flight robot can still produce an authenticated clear.
- [x] SB-M27-027 Never call a state deadlocked while an EMPTY slot plus at least one selectable front batch can lead to legal future progress.
- [x] SB-M27-028 Never call a state deadlocked merely because current batches are waiting if already-scheduled/legal clearing can open their targets.
- [x] SB-M27-029 Declare deadlock only when search proves there is no legal future action sequence that can produce further authenticated progress/completion.
- [x] SB-M27-030 Add the canonical true-deadlock fixture: five occupied WAITING batches, no in-flight progress and no legal unlock sequence.
- [x] SB-M27-031 Add false-positive guards where a newly opened same-color target correctly revives the oldest waiting batch.
- [x] SB-M27-032 Expose deterministic deadlock reason codes/debug evidence without coupling lose-screen UI to solver internals.
- [x] SB-M27-033 Reset/replay must reproduce identical solver classification from identical state/seed.
- [x] SB-M27-034 Run performance/memory profiling and regression tests before declaring the core gameplay engine complete.

### M28 — Gameplay Screen Layout `[VISUAL REFERENCE]`

- [x] SB-M28-001 Audit original gameplay reference images.
- [x] SB-M28-002 Board region. — [x] SB-M28-003 Five-slot region.
- [x] SB-M28-004 HUD region. — [x] SB-M28-005 Safe areas.
- [x] SB-M28-006 Easy dimensions. — [x] SB-M28-007 Medium dimensions.
- [x] SB-M28-008 Hard dimensions. — [x] SB-M28-009 Very Hard dimensions.
- [x] SB-M28-010 Rectangular boards. — [x] SB-M28-011 59×59.
- [x] SB-M28-012 Narrow phone. — [x] SB-M28-013 Tall phone.
- [x] SB-M28-014 Tablet portrait. — [x] SB-M28-015 Input coordinate accuracy.
- [x] SB-M28-016 Use `docs/MASTER_UI_SYSTEM.md` as canonical gameplay layout contract.
- [x] SB-M28-017 Remove Goal/Moves panel from approved production gameplay composition.
- [x] SB-M28-018 Make board dominant gameplay-screen region.
- [x] SB-M28-019 Keep color-selection panel protected/usable.
- [x] SB-M28-020 Place Scrubby low at left of color-selection region.
- [x] SB-M28-021 Place speech bubble above Scrubby.
- [x] SB-M28-022 Preserve right-side cleaning props as lower-priority decoration.
- [x] SB-M28-023 Put four booster controls in compact horizontal row above bottom/ad row.
- [x] SB-M28-024 Historical M28 baseline completed. Superseded placement: Gameplay Composition V02 moves Pause + 2x side by side to top-right; current playtest/reference has no ad banner and no Settings.
- [x] SB-M28-025 Do not restore removed Level/lock rail.
- [x] SB-M28-026 Bind owner-approved illustrations while keeping screen responsive/native.
- [x] SB-M28-027 Prove BoardRenderer coordinate mapping after responsive scaling.
- [x] SB-M28-028 Capture viewport validation evidence.

**Gameplay Composition V02 owner amendment [2026-09-19]:** `coordination/OWNER_GAMEPLAY_SCREEN_COMPOSITION_V02.md` is now canonical for gameplay layout. Preserve the owner-supplied baseline screen, integrate full Railroad V1 around the board, show five permanent slot-to-bottom-rail connectors, retain the five-slot + Batch Supply panel, place Pause + 2x side by side top-right, remove gameplay Settings/Heart HUD, and omit the ad banner from the current owner playtest/reference mockup. This is a presentation amendment; accepted historical M28/M29 evidence remains historical and later responsive/polish work must converge to V02.

### M29 — Mobile Touch

- [x] SB-M29-001 Touch selectable supply-front batch activation; five batch slots themselves are not player-selectable placement controls.
- [x] SB-M29-002 Desktop mouse development support.
- [x] SB-M29-003 Prevent mouse/touch double-fire.
- [x] SB-M29-004 Touch cancel. — [x] SB-M29-005 Focus loss.
- [x] SB-M29-006 Rapid tapping. — [x] SB-M29-007 Multi-touch.
- [x] SB-M29-008 Pause during touch. — [x] SB-M29-009 Background/foreground.

**Owner-locked speed integration for M29/runtime:** M29 proves the explicit 1x/2x temporal authority and may keep a direct debug/headless toggle seam. That seam is not authorization for free shipping manual 2x. M39 must gate production manual 2x through the paid entitlement service in `coordination/OWNER_ECONOMY_REWARDS_V01.md`. Authoritative M23-exhausted automatic 2x remains free. Do not infer exhaustion from UI rows or slot occupancy.

### M30 — Win/Lose Rules `[OWNER-LOCKED 2026-09-19] [CLOSED]`

- [x] SB-M30-001 Document win condition. — [x] SB-M30-002 Document lose condition.
- [x] SB-M30-003 Completion evaluator. — [x] SB-M30-004 Emit completion once.
- [x] SB-M30-005 Stop inappropriate new dispatch.
- [x] SB-M30-006 Resolve in-flight bots. — [x] SB-M30-007 Retry.
- [x] SB-M30-008 Completion regression tests.

### M31 — Cleaning Effects `[VISUAL REFERENCE] [PERFORMANCE] [CLOSED 2026-09-20]`

- [x] SB-M31-001 Use original visual references where available.
- [x] SB-M31-002 Define cleaning event.
- [x] SB-M31-003 Prototype lightweight effect.
- [x] SB-M31-004 Separate from BoardState.
- [x] SB-M31-005 Toggle effects. — [x] SB-M31-006 Concurrency limit.
- [x] SB-M31-007 Pool only after profiling. — [x] SB-M31-008 Stress 59×59.
- [x] SB-M31-009 Measure frame cost.
- [x] SB-M31-010 Reduced-effects option if required.

Closure evidence: `coordination/sessions/M31-C001/CHATGPT_AUDIT_V01.md` + `coordination/sessions/M31-C001/OWNER_F6_ACCEPTANCE_V01.md`. Final verdict: `AUDITED_PASS / M31-C001 CLOSED`.

### M32 — Scrubbot Final Visuals `[VISUAL REFERENCE]`

Active cycle: `M32-C001 V01`. Use the existing owner-approved canonical Scrubby asset family; do not regenerate approved Scrubby art. Implementation/audit authority: `coordination/sessions/M32-C001/CHATGPT_MASTER_PROMPT_V01.md` + `coordination/sessions/M32-C001/CHATGPT_MASTER_AUDIT_CRITERIA_V01.md`.

- [ ] SB-M32-001 Audit original Scrubbot art.
- [ ] SB-M32-002 Select owner-approved canonical design.
- [ ] SB-M32-003 Preserve original source.
- [ ] SB-M32-004 Configure crisp import.
- [ ] SB-M32-005 Visual component. — [ ] SB-M32-006 Travel animation.
- [ ] SB-M32-007 Arrival animation. — [ ] SB-M32-008 Disappearance.
- [ ] SB-M32-009 Direction/orientation if approved.
- [ ] SB-M32-010 Density performance test.
- [ ] SB-M32-UI-001 Use owner-approved canonical Scrubby reference for character generation.
- [ ] SB-M32-UI-002 Validate pose/state manifest entries before generation.
- [ ] SB-M32-UI-003 Generate only poses required by implemented behavior.
- [ ] SB-M32-UI-004 Generate required portrait/profile variants.
- [ ] SB-M32-UI-005 Generate emotion/state variants only when implemented flow needs them.
- [ ] SB-M32-UI-006 Preserve raw candidates/provenance separately.
- [ ] SB-M32-UI-007 Require owner visual approval before promotion.
- [ ] SB-M32-UI-008 Lock approved character assets against silent overwrite.
- [ ] SB-M32-UI-009 Configure Godot import settings.
- [ ] SB-M32-UI-010 Integrate approved art without coupling animation to TargetSelector logic.
- [ ] SB-M32-UI-011 Validate readability/scale on phone viewport matrix.

### M33 — Audio `[DESIGN GATE]`

- [ ] SB-M33-001 Audio buses. — [ ] SB-M33-002 Master volume.
- [ ] SB-M33-003 Music volume. — [ ] SB-M33-004 SFX volume.
- [x] SB-M33-005 Dispatch SFX. Owner-approved canonical asset: `assets/audio/sfx/dispatch.wav`.
- [x] SB-M33-006 Cleaning SFX. Owner-approved canonical asset: `assets/audio/sfx/cleaning.wav`.
- [x] SB-M33-007 Completion SFX. Owner-approved canonical asset: `assets/audio/sfx/completion.wav`.
- [x] SB-M33-008 Movement audio only if pleasant at high density. Owner decision: no movement audio in V1.
- [ ] SB-M33-009 Concurrency management. — [ ] SB-M33-010 Persist settings.

### M34 — Haptics

- [ ] SB-M34-001 Platform API research.
- [ ] SB-M34-002 Cleaning haptic if approved. — [ ] SB-M34-003 Completion haptic.
- [ ] SB-M34-004 Toggle. — [ ] SB-M34-005 Prevent vibration spam.
- [ ] SB-M34-006 Real-device test.

### M35 — Level Catalog

- [ ] SB-M35-001 Production LevelCatalog.
- [ ] SB-M35-002 Stable IDs. — [ ] SB-M35-003 Stable ordering.
- [ ] SB-M35-004 Difficulty. — [ ] SB-M35-005 Dimensions.
- [ ] SB-M35-006 Preview. — [ ] SB-M35-007 Duplicate detection.
- [ ] SB-M35-008 Missing-file detection.
- [ ] SB-M35-009 Production/test separation.
- [ ] SB-M35-010 Reject TEST fixture in production catalog.
- [ ] SB-M35-011 Batch validation.

### M36 — Difficulty System

**Difficulty V1 owner decision now governs future work.** Board dimensions remain an engine/content envelope and Session Load input, not the definition of EASY/MEDIUM/HARD/VERY_HARD.

- [ ] SB-M36-001 Migrate legacy runtime class=dimension configuration to Difficulty V1 without breaking board envelope validation.
- [ ] SB-M36-002 Validate production catalog against current Difficulty V1 + compatibility requirements.
- [ ] SB-M36-003 Implement/version Challenge components and owner-approved additional factors.
- [ ] SB-M36-004 Create Difficulty V1 matrix/calibration fixtures.
- [ ] SB-M36-005 Playtest difficulty.
- [ ] SB-M36-006 Prove board size alone cannot determine difficulty class.

### M37 — Level Progression

- [ ] SB-M37-001 Implement owner-locked repeating 10-level class cadence.
- [ ] SB-M37-002 Current level.
- [ ] SB-M37-003 Completion tracking. — [ ] SB-M37-004 Replay.
- [ ] SB-M37-005 Implement progression target curve/micro modifiers from Difficulty V1.
- [ ] SB-M37-006 Level select if approved.
- [ ] SB-M37-007 Service implementation. — [ ] SB-M37-008 Tests.

### M38 — Win Streak `[OWNER-LOCKED ECONOMY V1]`

- [ ] SB-M38-001 Streak state. — [ ] SB-M38-002 Increment only on valid first-clear progression wins.
- [ ] SB-M38-003 Reset on progression loss and restart-after-gameplay; pre-action exit does not reset.
- [ ] SB-M38-004 Grant exact SB mapping through RewardGrantService.
- [ ] SB-M38-005 Test 1→1 SB. — [ ] SB-M38-006 Test 2→5 SB.
- [ ] SB-M38-007 Test 3→10 SB. — [ ] SB-M38-008 Test 4→25 SB.
- [ ] SB-M38-009 Test 5→100 SB. — [ ] SB-M38-010 Test 6+→100 SB.
- [ ] SB-M38-011 No duplicate grant. — [ ] SB-M38-012 Persistence.
- [ ] SB-M38-013 Emit only streak-bonus SB amount to GiftMeterService; base/Daily/exchange SB never feeds it.
- [ ] SB-M38-014 Grant +1 Bot Part exactly at active streak multiples of 5.
- [ ] SB-M38-015 Replay does not advance streak, Gift Meter or streak Bot Parts.
- [ ] SB-M38-016 Add reset/replay/idempotency integration tests.

### M39 — Economy & Rewards V1 `[OWNER-LOCKED]`

Canonical decision: `coordination/OWNER_ECONOMY_REWARDS_V01.md`.
Machine tuning: `data/config/economy_rewards_v1.json`.

- [ ] SB-M39-001 Load/version/validate Economy V1 tuning config and fail closed on malformed values.
- [ ] SB-M39-002 Implement `scripts/economy/economy_wallet.gd` as authoritative Scrub Bucks balance.
- [ ] SB-M39-003 Implement atomic SB grant/spend with stable transaction IDs and insufficient-funds failure.
- [ ] SB-M39-004 Initialize new players at 1000 SB without double-initialization.
- [ ] SB-M39-005 Grant first-clear SB by difficulty: EASY 50 / MEDIUM 75 / HARD 100 / VERY_HARD 150.
- [ ] SB-M39-006 Grant +1 Bot Part per first-clear progression level and prohibit replay farming.
- [ ] SB-M39-007 Implement `reward_grant_service.gd` idempotent reward bundles and duplicate-callback protection.
- [ ] SB-M39-008 Implement `gift_meter_service.gd`; ONLY Win Streak SB may advance it.
- [ ] SB-M39-009 Implement Gift Meter thresholds 10/50/250/500/1000 and exactly-once milestone crossing.
- [ ] SB-M39-010 Support one reward crossing multiple thresholds plus 1000-cycle rollover/overflow.
- [ ] SB-M39-011 Queue Gift Bar milestone rewards instead of silently auto-consuming them.
- [ ] SB-M39-012 Implement exact Gift rewards from Economy V1, totaling 10 Bot Parts per complete 0→1000 cycle.
- [ ] SB-M39-013 Implement 1000 guaranteed-new-card rule with 500 SB fallback when no eligible missing card exists.
- [ ] SB-M39-014 Prove base level/Daily/Tasks/Gift/Cards Exchange SB cannot recursively advance Gift Meter.
- [ ] SB-M39-015 Implement `robot_unlock_service.gd`: Scrubby initially unlocked; every later robot costs 250 Bot Parts; preserve overflow.
- [ ] SB-M39-016 Grant owner-locked per-set SB/Bot Parts rewards on first 9/9 completion and wire next-robot notification/read model.
- [ ] SB-M39-017 Add pacing simulation/evidence targeting approximately one robot unlock per 150 progression levels for average engaged play.
- [ ] SB-M39-018 Enforce robot perks as meta/economy convenience only; never alter solver/BoardState/TargetSelector/routing legality.
- [ ] SB-M39-019 Implement `heart_service.gd`: max 5, one Heart per 1800 real-world seconds, offline/menu/background regen.
- [ ] SB-M39-020 Consume one Heart on progression loss or restart-after-gameplay; pre-action exit consumes none.
- [ ] SB-M39-021 Implement +1 Heart = 500 SB and full refill = 400 SB per missing Heart.
- [ ] SB-M39-022 Implement `speed_entitlement_service.gd` separate from GameplaySpeedAuthority.
- [ ] SB-M39-023 Implement current-level 2x entitlement = 200 SB, surviving retries of same level until completion.
- [ ] SB-M39-024 Implement timed 2x products 15m/300 SB, 30m/500 SB, 60m/750 SB.
- [ ] SB-M39-025 Timed 2x uses absolute wall-clock expiry and continues in gameplay, Home/menus, pause, background and closed-app time.
- [ ] SB-M39-026 Allow timed purchases to extend expiry deterministically; never use gameplay delta/Engine.time_scale for entitlement time.
- [ ] SB-M39-027 Gate shipping manual 2x requests behind a valid level/timed entitlement or purchase flow.
- [ ] SB-M39-028 Preserve free entitlement-independent authoritative M23-exhausted automatic 2x.
- [ ] SB-M39-029 Implement `booster_inventory.gd` with exactly four charge counters and charge-before-SB consumption.
- [ ] SB-M39-030 +1 Slot booster: 500 SB, max once/attempt, authoritative slot capacity 5→6 only for current attempt.
- [ ] SB-M39-031 Extend M24 placement/full-slot queries from fixed five to authoritative capacity 5/6 without breaking five-slot baseline tests.
- [ ] SB-M39-032 Extend M27 solver/deadlock state/canonicalization/fixtures to capacity 5/6.
- [ ] SB-M39-033 Add sixth-slot presentation/layout support and mobile safe-area evidence; no 7+ slot state.
- [ ] SB-M39-034 Random booster: 350 SB, reorder only remaining unselected M23 batches without changing identities/counts/conservation.
- [ ] SB-M39-035 Random commit requires solver proof of at least three consecutive legal non-deadlocking front selections; failed search consumes nothing.
- [ ] SB-M39-036 Selector booster: 500 SB; present solver-safe eligible remaining batches/colors only.
- [ ] SB-M39-037 Selector performs one atomic arbitrary-remaining extraction + standard rightmost-EMPTY placement; full capacity/unsafe choice consumes nothing.
- [ ] SB-M39-038 Tornado booster: 750 SB; choose exactly one present color.
- [ ] SB-M39-039 Tornado atomically clears all remaining ACTIVE cells of chosen color and reconciles M23 supply, M24 slots, M25 claims/reservations, M26 in-flight agents/quotas and M27 state.
- [ ] SB-M39-040 Prove Tornado rollback/failure consumes no charge/SB and leaves no ghost batch/agent/double-clear.
- [ ] SB-M39-041 Implement `daily_service.gd`: visible consecutive-login count plus repeating 5-day reward cycle.
- [ ] SB-M39-042 Daily login rewards: D1 100 SB; D2 Standard Pack; D3 random booster; D4 250 SB + Standard Pack; D5 300 SB + selected booster + Premium Pack.
- [ ] SB-M39-043 Daily has exactly three tasks with 75/100/125 SB individual rewards and one random booster for completing all three.
- [ ] SB-M39-044 Missing a local calendar day resets login streak/cycle; clock rollback can never create duplicate claims.
- [ ] SB-M39-045 Implement `collection_inventory.gd` for 15 sets × 9 cards, protected first copy and completion state.
- [ ] SB-M39-046 Standard Pack = 3 eligible draws; Premium Pack = 5 eligible draws with >=1 Rare-or-better; duplicates allowed.
- [ ] SB-M39-047 Implement exact per-set 9/9 rewards from Economy V1: S1 350/5, S2 400/5, S3 450/6, S4 500/7, S5 550/7, S6 600/8, S7 700/9, S8 750/9, S9 800/10, S10 900/10, S11 1000/11, S12 1100/12, S13 1250/13, S14 1500/15, S15 2500/20 (SB/Bot Parts), each exactly once.
- [ ] SB-M39-047A Grant Master Collection exactly once when all 15 sets first reach 9/9: +2500 SB +20 Bot Parts, additional to Set 15.
- [ ] SB-M39-047B Prove total 15-set completion milestones = 13,350 SB +147 Bot Parts; including Master Collection = 15,850 SB +167 Bot Parts.
- [ ] SB-M39-047C Persist per-set completion-grant transaction IDs and Master Collection transaction ID so sync/relaunch cannot double-grant.
- [ ] SB-M39-048 Implement `cards_exchange_service.gd`; only copies above protected first copy are exchangeable.
- [ ] SB-M39-049 Exchange values: Common 25 / Rare 75 / Epic 200 / Legendary 500 SB.
- [ ] SB-M39-050 Implement per-card and EXCHANGE ALL EXTRAS atomic exchange; never reduce collected owned count below 1.
- [ ] SB-M39-051 Prove Stars, Star Exchange, Event Points and profile-XP economic state do not exist in production save/runtime APIs.
- [ ] SB-M39-052 Add full Economy V1 headless regression matrix for grants/spends/rollover/offline clocks/boosters/exchange/idempotency.

### M40 — Save System

- [ ] SB-M40-001 Versioned schema. — [ ] SB-M40-002 Settings.
- [ ] SB-M40-003 Progression. — [ ] SB-M40-004 Win streak.
- [ ] SB-M40-005 Persist Economy V1 wallet, Hearts/regen anchor, Bot Parts/robots, cards, booster charges, Gift Meter, Daily and 2x entitlements.
- [ ] SB-M40-006 Safe write strategy.
- [ ] SB-M40-007 Missing-save behavior. — [ ] SB-M40-008 Corruption recovery.
- [ ] SB-M40-009 Migration strategy.
- [ ] SB-M40-010 Round-trip tests. — [ ] SB-M40-011 Corrupt-file tests.
- [ ] SB-M40-012 Migrate old saves with missing Economy V1 fields to safe defaults; never invent Star/Event balances.
- [ ] SB-M40-013 Persist wall-clock timestamps/expiry defensively against duplicate reward/refill claims.

### M41 — Settings

- [ ] SB-M41-001 Master volume. — [ ] SB-M41-002 Music. — [ ] SB-M41-003 SFX.
- [ ] SB-M41-004 Haptics. — [ ] SB-M41-005 Reduced effects.
- [ ] SB-M41-006 Persistence. — [ ] SB-M41-007 Settings UI.
- [ ] SB-M41-008 Relaunch tests.

### M42 — Home / Navigation

- [ ] SB-M42-001 Navigation architecture. — [ ] SB-M42-002 Home.
- [ ] SB-M42-003 Play/Continue. — [ ] SB-M42-004 Settings.
- [ ] SB-M42-005 Level select if approved.
- [ ] SB-M42-006 Gameplay transition. — [ ] SB-M42-007 Results transition.
- [ ] SB-M42-008 Prevent duplicate transitions. — [ ] SB-M42-009 Back navigation.
- [ ] SB-M42-010 Build Home as responsive Godot containers/components.
- [ ] SB-M42-011 Recreate owner-approved Home art direction with canonical regions.
- [ ] SB-M42-012 Keep shortcut columns responsive around central area.
- [ ] SB-M42-013 Validate Home-specific manifest entries in `assets/ui/HOME_ASSET_MANIFEST.json` before generation.
- [ ] SB-M42-014 Generate only Home-specific required illustrative assets using approved provider order (ChatGPT primary, Magnific fallback).
- [ ] SB-M42-015 Keep dynamic values/timers/counts/labels live in Godot UI.
- [ ] SB-M42-016 Require owner approval before production promotion.
- [ ] SB-M42-017 Bind approved art and validate viewport matrix.
- [ ] SB-M42-018 Replace coin HUD semantics with Scrub Bucks banknote icon + live SB amount.
- [ ] SB-M42-019 Replace profile XP bar with live Bot Parts next-robot progress (normally N/250).
- [ ] SB-M42-020 Replace top event bar/timer with Gift Meter progress/next milestone; no Event Points/timer.
- [ ] SB-M42-021 Bind Gift Bar to queued Gift Meter milestone claims and live claimable count.
- [ ] SB-M42-022 Replace Star Exchange shortcut with Cards Exchange and duplicate-card count/state.
- [ ] SB-M42-023 Render lower road as Win Streak SB reward track 1/5/10/25/100; no Star balance.
- [ ] SB-M42-024 Implement Daily consecutive-login count / 5-day cycle / booster reward presentation.
- [ ] SB-M42-025 Keep all SB prices, Bot Parts values, Gift Meter values and Daily states live/localizable.

**Opening cinematic / boot flow [OWNER ASSET — 2026-09-19]**

- [ ] SB-M42-026 Opening cinematic source: preserve the owner-supplied 15-second source video at `assets/brand/opening/final_15_seconds_opening_video.mp4` (local source currently intended from `C:\Users\sekip\Desktop\ScrubBots\assets\brand\final 15 seconds opening video.mp4`).
- [ ] SB-M42-027 Preserve the MP4 as source/reference, but create a Godot-runtime Ogg Theora + Vorbis version at `assets/brand/opening/scrubbots_opening_720p30.ogv`; do not rely on H.264/MP4 playback in core Godot.
- [ ] SB-M42-028 Implement a dedicated opening-video scene using `VideoStreamPlayer`, with aspect-ratio-safe presentation for the portrait app and no image distortion.
- [ ] SB-M42-029 On successful video completion, transition exactly once into the normal Home/bootstrap flow; failure to decode/play must fail safely into Home rather than blocking startup.
- [ ] SB-M42-030 Decide and implement skip behavior `[DESIGN GATE]`: recommended V1 is tap/Skip to bypass the cinematic without affecting save/game state.
- [ ] SB-M42-031 Decide playback frequency `[DESIGN GATE]`: recommended V1 is once per cold app launch, not on every internal scene transition/retry.
- [ ] SB-M42-032 Validate opening cinematic on Android real device for smooth 720p/30 playback, audio sync, startup latency, orientation, background/foreground behavior and memory cleanup.
- [ ] SB-M42-033 Validate iOS readiness later with the same boot-flow fallback and aspect rules.

### M43 — Results Screen

- [ ] SB-M43-001 Result model. — [ ] SB-M43-002 Completion UI.
- [ ] SB-M43-003 Streak. — [ ] SB-M43-004 Show/apply first-clear difficulty SB + streak SB + Bot Part/Collection rewards through RewardGrantService.
- [ ] SB-M43-005 Continue. — [ ] SB-M43-006 Replay if approved.
- [ ] SB-M43-007 No double reward. — [ ] SB-M43-008 Rapid-tap protection.

**Shared later-screen visual production rules**
- [ ] SB-UI-017 Implement reusable `BasePopup` composition.
- [ ] SB-UI-018 Keep popup text/rewards/quantities/buttons/state dynamic in Godot.
- [ ] SB-UI-019 For each later screen milestone, identify/generate/approve/bind required illustration assets inside that milestone.
- [ ] SB-UI-020 Do not pre-generate speculative asset libraries for unknown future states.
- [ ] SB-UI-021 Treat final visual polish as consolidation/QA, not first production-art implementation.

### M44 — Tutorial `[DESIGN GATE]`

Teach five-slot interaction, color matching, Scrubbot flow, no-work behavior if needed. Keep tutorial logic separate from core gameplay.

### M45 — Debug Tooling

- [ ] SB-M45-001 Debug overlay. — [ ] SB-M45-002 Level ID.
- [ ] SB-M45-003 Difficulty. — [ ] SB-M45-004 Dimensions.
- [ ] SB-M45-005 Cell count. — [ ] SB-M45-006 ACTIVE count. — [ ] SB-M45-007 CLEARED count.
- [ ] SB-M45-008 Reserved count if implemented. — [ ] SB-M45-009 Active bots.
- [ ] SB-M45-010 FPS. — [ ] SB-M45-011 Frame time.
- [ ] SB-M45-012 Target markers. — [ ] SB-M45-013 Route visualization.
- [ ] SB-M45-014 Cell grid. — [ ] SB-M45-015 Effect toggle.
- [ ] SB-M45-016 Instant reset. — [ ] SB-M45-017 Level switcher.
- [ ] SB-M45-018 Disable release-facing debug UI.

### M46 — Performance `[PERFORMANCE]`

Maximum board target: 59×59 = 3,481.

- [ ] SB-M46-001 Level parsing. — [ ] SB-M46-002 BoardState. — [ ] SB-M46-003 Renderer.
- [ ] SB-M46-004 Color candidate index + reachability/access. — [ ] SB-M46-005 TargetSelector. — [ ] SB-M46-006 Routing.
- [ ] SB-M46-007 Scrubbot agents. — [ ] SB-M46-008 Effects.
- [ ] SB-M46-009 Memory baseline. — [ ] SB-M46-010 59×59 memory.
- [ ] SB-M46-011 Per-frame allocation detection.
- [ ] SB-M46-012 Repeated restart. — [ ] SB-M46-013 Long session.
- [ ] SB-M46-014 High agent density.

### M47 — Android Device Testing

- [ ] SB-M47-001 Android export setup. — [ ] SB-M47-002 Development APK.
- [ ] SB-M47-003 Real device install. — [ ] SB-M47-004 Touch.
- [ ] SB-M47-005 Portrait. — [ ] SB-M47-006 Safe areas.
- [ ] SB-M47-007 Easy performance. — [ ] SB-M47-008 Medium performance.
- [ ] SB-M47-009 Hard performance. — [ ] SB-M47-010 Very Hard/59×59 performance.
- [ ] SB-M47-011 High bot density. — [ ] SB-M47-012 Background/foreground.
- [ ] SB-M47-013 Heat/battery extended test.
- [ ] SB-M47-014 Record device/results.

### M48 — iOS Readiness

- [ ] SB-M48-001 Avoid Android-only gameplay architecture.
- [ ] SB-M48-002 Document Apple toolchain requirement.
- [ ] SB-M48-003 Prepare iOS configuration when hardware exists.
- [ ] SB-M48-004 Real-device iOS testing later.

### M49 — Responsive UI

- [ ] SB-M49-001 16:9 portrait. — [ ] SB-M49-002 19.5:9. — [ ] SB-M49-003 20:9.
- [ ] SB-M49-004 Tall phone. — [ ] SB-M49-005 Tablet. — [ ] SB-M49-006 Notch/cutout.
- [ ] SB-M49-007 Five slots stay usable. — [ ] SB-M49-008 Board stays visible.
- [ ] SB-M49-009 Rectangular boards remain correctly scaled.
- [ ] SB-M49-010 Touch mapping remains accurate.
- [ ] SB-M49-011 Adopt 1080×2160 reference design viewport and stretch policy.
- [ ] SB-M49-012 Implement reusable SafeAreaRoot.
- [ ] SB-M49-013 Implement centralized UI tokens.
- [ ] SB-M49-014 Implement COMPACT/NORMAL/TALL classification.
- [ ] SB-M49-015 Validate 1080×2160.
- [ ] SB-M49-016 Validate 1170×2532.
- [ ] SB-M49-017 Validate 1290×2796.
- [ ] SB-M49-018 Validate 1080×2400.
- [ ] SB-M49-019 Validate 1440×3200.
- [ ] SB-M49-020 Validate minimum touch target.
- [ ] SB-M49-021 Confirm popups fit safe area.
- [ ] SB-M49-022 Confirm text containers survive localization expansion.
- [ ] SB-M49-023 Confirm top-right Pause + 2x controls, five fixed connector rails, slots, Batch Supply and booster row remain usable on compact devices.
- [ ] SB-M49-024 Add automated/manual responsive validation evidence.
- [ ] SB-M49-025 Validate temporary sixth-slot (+1 booster) layout/touch/readability across the full viewport matrix.

### M50 — Accessibility

- [ ] SB-M50-001 Review color-only information.
- [ ] SB-M50-002 Alternative visual slot cues if necessary.
- [ ] SB-M50-003 Color vision tests. — [ ] SB-M50-004 Contrast.
- [ ] SB-M50-005 Reduced effects. — [ ] SB-M50-006 Touch sizes.
- [ ] SB-M50-007 Text readability.
- [ ] SB-M50-008 Do not encode important state solely in decorative art.
- [ ] SB-M50-009 Keep labels/counts live and contrast-independent from illustration.
- [ ] SB-M50-010 Ensure generated icon families distinguishable at mobile size.
- [ ] SB-M50-011 Ensure essential gameplay understandable without decoration.

### M51 — Localization Readiness

- [ ] SB-M51-001 Avoid hard-coded user text.
- [ ] SB-M51-002 Translation-key convention.
- [ ] SB-M51-003 Longer-string layouts. — [ ] SB-M51-004 Pseudo-localization.
- [ ] SB-M51-005 Actual languages decided later. `[DESIGN GATE]`

### M52 — Production Content Scale-Up `[CONTENT]`

- [ ] SB-M52-001 Import first Easy art. — [ ] SB-M52-002 Import first Medium art.
- [ ] SB-M52-003 Import first Hard art. — [ ] SB-M52-004 Import first Very Hard art.
- [ ] SB-M52-005 Validate rectangular production art.
- [ ] SB-M52-006 Batch convert. — [ ] SB-M52-007 Batch validate.
- [ ] SB-M52-008 Generate previews. — [ ] SB-M52-009 Populate catalog.
- [ ] SB-M52-010 Verify every source image preserved.
- [ ] SB-M52-011 Verify generated level reproduces source.

### M53 — Level QA `[QA]`

Every production level:
- [ ] SB-M53-001 Legal dimensions/envelope. — [ ] SB-M53-002 Correct Difficulty V1 metadata/score context.
- [ ] SB-M53-003 Valid locked C01..C16 palette and current 3–12 used-color envelope; old class-specific color bands are not difficulty truth.
- [ ] SB-M53-004 Correct cell count.
- [ ] SB-M53-005 No invalid palette IDs. — [ ] SB-M53-006 Recognizable ACTIVE source artwork.
- [ ] SB-M53-007 No unintended interpolation. — [ ] SB-M53-008 Correct CLEARED transparency.
- [ ] SB-M53-009 Solvable under canonical routing/access semantics, including Railroad V1 where applicable.
- [ ] SB-M53-010 No routing pathology; fully enclosed matching ACTIVE target remains untargetable until a legal Railroad ingress plus OPEN/CLEARED orthogonal interior path exists.
- [ ] SB-M53-011 Good performance. — [ ] SB-M53-012 Correct preview.
- [ ] SB-M53-013 Unique ID.

### M54 — Regression Suite `[QA]`

- [ ] SB-M54-001 Difficulty/progression tests. — [ ] SB-M54-002 Level parser tests.
- [ ] SB-M54-003 BoardState tests. — [ ] SB-M54-004 Renderer tests.
- [ ] SB-M54-005 Slot tests. — [ ] SB-M54-006 Color-candidate/reachability tests.
- [ ] SB-M54-007 Reservation tests. — [ ] SB-M54-008 TargetSelector tests.
- [ ] SB-M54-009 Routing tests including Railroad V1 geometry, connectors, legal ingresses and post-rail orthogonal interior turns. — [ ] SB-M54-010 Dispatcher tests.
- [ ] SB-M54-011 Completion tests. — [ ] SB-M54-012 Save tests.
- [ ] SB-M54-013 Reward tests. — [ ] SB-M54-014 Content validation tests.
- [ ] SB-M54-015 59×59 regression test.
- [ ] SB-M54-016 Economy Wallet/Gift Meter/Daily/Cards Exchange/Collection-completion idempotency regression.
- [ ] SB-M54-016A Test every set-specific 9/9 reward plus all-15 Master Collection +2500 SB/+20 Bot Parts exactly-once grant.
- [ ] SB-M54-017 Heart 30-minute offline/background/menu regen and clock-rollback regression.
- [ ] SB-M54-018 2x level/timed entitlement wall-clock expiry + free M23-exhausted auto-2x regression.
- [ ] SB-M54-019 +1 Slot 5/6-capacity runtime + solver regression.
- [ ] SB-M54-020 Random/Selector solver-safety and no-consume-on-failure regression.
- [ ] SB-M54-021 Tornado cross-engine conservation/rollback/no-ghost regression.

### M55 — Chaos / Long-Run QA `[QA]`

- [ ] SB-M55-001 Spam all five slots.
- [ ] SB-M55-002 Restart while bots travel. — [ ] SB-M55-003 Pause while bots travel.
- [ ] SB-M55-004 Background while bots travel.
- [ ] SB-M55-005 Complete with bots in flight.
- [ ] SB-M55-006 Exhaust color. — [ ] SB-M55-007 Exhaust slot work.
- [ ] SB-M55-008 Repeated scene transitions.
- [ ] SB-M55-009 Long high-load session.
- [ ] SB-M55-010 Memory growth monitoring.
- [ ] SB-M55-011 Duplicate signal monitoring.
- [ ] SB-M55-012 Orphan Node monitoring.
- [ ] SB-M55-013 Duplicate reward monitoring.
- [ ] SB-M55-014 Spam booster use/purchase/charge buttons; prove no double spend/use.
- [ ] SB-M55-015 Background/foreground across Heart regen and timed 2x expiry.
- [ ] SB-M55-016 Tornado while matching-color agents are in flight; prove atomic reconciliation.
- [ ] SB-M55-017 Cards Exchange-all under repeated taps; prove protected first copies and no duplicate SB grant.

### M56 — Analytics `[DESIGN GATE]`

No analytics SDK without owner approval.

### M57 — Real-Money Monetization `[DESIGN GATE]`

Economy V1 soft-currency/Hearts/booster/2x rules are already owner-locked and are NOT this gate.
Do NOT automatically add real-money IAP, paid SB packs, rewarded ads, subscriptions, paid random packs or any additional energy currency. Owner decides real-money business model separately.

### M58 — Privacy & Compliance

Once external services exist:
- [ ] SB-M58-001 Third-party inventory. — [ ] SB-M58-002 Data inventory.
- [ ] SB-M58-003 Remove unnecessary collection.
- [ ] SB-M58-004 Privacy disclosures. — [ ] SB-M58-005 Store declarations.
- [ ] SB-M58-006 Age-rating review.
- [ ] SB-M58-007 Child-directed considerations if applicable.

### M59 — Build Pipeline

- [ ] SB-M59-001 Debug export. — [ ] SB-M59-002 Release export.
- [ ] SB-M59-003 Output directories. — [ ] SB-M59-004 Versioning.
- [ ] SB-M59-005 Build numbers. — [ ] SB-M59-006 Run tests before release build.
- [ ] SB-M59-007 Run content validator. — [ ] SB-M59-008 Generate Android build.
- [ ] SB-M59-009 Verify clean clone can build.

### M60 — Release

Application ID, icon, splash, portrait config, signing, release settings,
debug removal, store screenshots, final QA, tagged source commit, release
artifact validation. **Never commit signing secrets.**

---

## GENERATED ASSET LIFECYCLE / DEFINITION OF DONE

- [ ] SB-UI-022 Use image generation primarily for branded illustrative assets where it adds value.
- [ ] SB-UI-023 Prefer native Godot controls/styles for interactive/dynamic UI.
- [ ] SB-UI-024 Every generated asset has traceable manifest/provenance.
- [ ] SB-UI-025 Raw generation output is never automatically production-final.
- [ ] SB-UI-026 Owner approval required before production promotion for identity/major art.
- [ ] SB-UI-027 Approved assets must be imported/configured/bound before implementation task closes.
- [ ] SB-UI-028 Never silently regenerate/overwrite approved asset.
- [ ] SB-UI-029 Do not bake dynamic text/quantities/timers/prices/state into generated images.
- [ ] SB-UI-030 Keep single-Image/ImageTexture BoardRenderer; no per-cell UI nodes.
- [ ] SB-UI-031 Validate transparency/edges/resolution/filtering/compression/memory/readability.
- [ ] SB-UI-032 Use generation credits consciously; generate by milestone need.

---

## RISK REGISTER

| ID | Risk | Severity | Mitigation |
|---|---|---|---|
| RISK-001 | Routing works technically but looks boring/confusing | CRITICAL | Owner-locked Railroad V1 + replaceable RoutingSystem + owner F6 review |
| RISK-002 | Large number of Scrubbots causes frame drops | HIGH | 59×59 density stress tests and profiling |
| RISK-003 | Legacy difficulty assumptions survive as current truth | HIGH | Difficulty V1 migration + config/doc/regression checks |
| RISK-004 | Production difficulty metadata becomes inconsistent | HIGH | Versioned Difficulty V1 evaluator/calibration |
| RISK-005 | Generic small test fixtures break after production validation | MEDIUM/HIGH | TEST fixture path/context separate from production |
| RISK-006 | Existing artwork gets silently resized/altered | HIGH | Source preservation + explicit compiler/importer + round-trip comparison |
| RISK-007 | AI agent invents missing references | HIGH | Canonical reference library/manifest |
| RISK-008 | External reference game copied too closely | HIGH | Original SCRUBBOTS rail/art/UI language; external references conceptual only |
| RISK-009 | Target race assigns same pixel to multiple Scrubbots/batches | HIGH | ReservationState + Batch Target Claim Engine atomic uniqueness tests |
| RISK-010 | Renderer creates thousands of Nodes | HIGH | Batched renderer requirement |
| RISK-011 | Desktop testing hides mobile performance issues | HIGH | Real Android profiling |
| RISK-012 | Future agent breaks explicit preload/headless compatibility | MEDIUM/HIGH | ADR-009 + regression tests |
| RISK-013 | Target ordering appears wrong because exterior/interior HOW cannot legally reach intended target | HIGH | Railroad V1 legal ingress + orthogonal interior-turn routing + exact Hazard Bot regressions |
| RISK-014 | Hidden/debug input diverges from production supply-front selection and automatic slot placement | HIGH | Front-batch-only player activation; rightmost-empty auto-placement; no hidden keyboard dispatch |
| RISK-015 | Railroad visual and routing geometry drift apart | HIGH | One canonical ScrubRail geometry source consumed by routing, connector and presentation |
| RISK-016 | Generated batch supply is mathematically impossible to finish | CRITICAL | Solvability Engine proof before production acceptance |
| RISK-017 | Scheduler spawns a robot without unique target/reservation/valid route | CRITICAL | No-target/no-reservation/no-route/no-robot transactional invariant |
| RISK-018 | Temporary WAITING is misclassified as deadlock | HIGH | Solver-backed STALLED vs DEADLOCK classification + in-flight/future-progress guards |
| RISK-019 | Multiple same-color batches fight/starve or double-claim targets | HIGH | Oldest-placement-first same-color arbitration + atomic Batch Target Claim ledger |

---

## CRITICAL PATH

```text
FOUNDATION                         DONE
↓
VARIABLE LEVEL DATA                DONE
↓
BOARDSTATE                         DONE
↓
HEADLESS CORE TESTS                DONE
↓
ENGINE/CONTENT ENVELOPE
↓
BOARD RENDERER
↓
VISUAL REFERENCE INGESTION
↓
PIXEL ART IMPORT / SEMANTIC ART PIPELINES
↓
GAMEPLAY SESSION
↓
FIVE SLOTS
↓
COLOR CANDIDATES + REACHABILITY
↓
RESERVATION
↓
TARGETSELECTOR
↓
ROUTING + SCRUBBOT RAILROAD V1             DONE (M22 V07 + OWNER ACCEPTANCE)
↓
SCRUBBOT AGENT
↓
DISPATCHER
↓
COMPLETE CLEANING LOOP
↓
REAL SCRUBBOTS ART VERTICAL SLICE             DONE (M21)
↓
BATCH SUPPLY ENGINE                           NEXT (M23)
↓
FIVE-SLOT BATCH ENGINE                        M24
↓
BATCH TARGET CLAIM ENGINE                     M25
↓
AUTO DISPATCH SCHEDULER                       M26
↓
SOLVABILITY / DEADLOCK ENGINE                 M27
↓
PRODUCTION UI / TOUCH                         M28+
↓
WIN / PROGRESSION / SAVE
↓
MOBILE PERFORMANCE
↓
CONTENT SCALE-UP
↓
RELEASE QA
```

---

## FIRST TRUE PLAYABLE TARGET

M21 achieved the first real gameplay proof using the then-current adjacent exterior ring. The current productionization target now adds the owner-approved Railroad V1 movement language without changing M21's WHAT/reservation/clear invariants:

```text
ONE REAL OWNER-APPROVED SCRUBBOTS LEVEL IMAGE
+ FIVE EMPTY BATCH SLOTS
+ 3/4/5 FIFO BATCH-SUPPLY COLUMNS
+ V1 THREE VISIBLE ROWS; FRONT ROW ONLY SELECTABLE
+ AUTOMATIC RIGHTMOST-EMPTY SLOT PLACEMENT
+ COLOR/COUNT BATCH QUOTAS WITH WAITING/RESUME
+ SAME-COLOR OLDEST-BATCH-FIRST TARGET CLAIM ARBITRATION
+ FRONT-BATCH CLICK/TAP OWNER GAMEPLAY ACTIVATION; FIVE SLOTS AUTO-FILL
+ CORRECT COLOR CANDIDATES + REACHABLE TARGET SELECTION
+ BOTTOM-MOST / LEFT-MOST PRIORITY AMONG CURRENTLY TARGETABLE MATCHING CELLS
+ SCRUBBOT RAILROAD V1 AROUND ALL FOUR SIDES
+ 2-CELL ARTWORK CLEARANCE + 1-CELL RAIL WIDTH
+ VISIBLE SLOT -> BOTTOM-RAIL CONNECTOR
+ RAIL-ONLY EXTERIOR TRAVEL
+ LEGAL RAIL INGRESS INTO OPEN/CLEARED PERIMETER SPACE
+ ORTHOGONAL INTERIOR-CORRIDOR ROUTING WITH 90-DEGREE TURNS
+ NO TARGET / NO RESERVATION / NO VALID ROUTE = NO ROBOT
+ SOLVABILITY-PROVED SUPPLY + RUNTIME DEADLOCK CLASSIFICATION
+ VALID TARGET RESERVATION
+ PIXELS BEING CLEANED TO TRANSPARENCY
+ SCRUBBOTS DISAPPEARING AFTER CLEANING
+ A COMPLETE PLAYABLE LEVEL
```

---

## RECOMMENDED PROMPT SEQUENCE

Guidance, not a hard contract. Split any prompt if scope becomes too large.
Never combine two risky architecture systems merely to save prompt count.

```text
PROMPT 01  Project Foundation                                    [DONE]
PROMPT 02  Godot Installation + Variable LevelData + BoardState
           + Headless Tests                                      [DONE]
PROMPT 03  Official Difficulty Bands + TEST vs Production        [HISTORICAL COMPAT DONE]
PROMPT 04  BoardRenderer + Variable Aspect Board Rendering       [DONE]
PROMPT 05  Visual Reference Library                              [DONE/ONGOING ASSETS]
PROMPT 06  Pixel-Art Importer + Round Trip Validation            [DONE]
PROMPT 07  Gameplay Session Core + Five-Slot Data Model          [DONE]
PROMPT 08  Color Candidates + Reservation + TargetSelector       [DONE]
PROMPT 09  RoutingSystem + Production Routing                    [DONE; exterior geometry superseded by M22 Railroad V1]
PROMPT 10  ScrubbotAgent + Dispatcher                            [DONE]
PROMPT 11  Complete Clearing Vertical Slice                      [DONE]
PROMPT 12  First Real SCRUBBOTS Artwork Playable Level           [DONE — M21 V10]
PROMPT 13  Production Slot UI + Railroad V1                      [DONE — M22 V07 + owner acceptance]
PROMPT 14  Batch Supply Engine                                      [NEXT — M23]
PROMPT 15  Five-Slot Batch Engine                                   [M24]
PROMPT 16  Batch Target Claim Engine                                [M25]
PROMPT 17  Auto Dispatch Scheduler                                  [M26]
PROMPT 18  Solvability / Deadlock Engine                            [M27]
PROMPT 19  Gameplay Screen Layout + Mobile Touch                    [M28–M29]
PROMPT 20  Win/Lose Completion Rules + Results Flow
PROMPT 21  Scrubbot Final Art + Cleaning Effects + Audio/Haptics
PROMPT 22  Level Catalog + Difficulty V1 Content Rules
PROMPT 23  Progression + Win Streak + Save System
PROMPT 24  Home + Settings + Tutorial + Navigation
PROMPT 25  Android Device Performance + Full 59×59 Stress Tests
PROMPT 26  Production Content Scale-Up + Regression + Chaos QA
PROMPT 27  Release Candidate Preparation
```

---

## NEXT IMMEDIATE MILESTONE

**M23-C001 V01 — Batch Supply Engine.** The next implementation cycle builds the real color/count supply queues before any production-screen-layout work. V1 must support owner-locked FIFO columns, three visible rows for the Hazard Bot validation path, front-row-only selection, hidden future batches, deterministic/conserved candidate generation and transactional handoff to the future Five-Slot Batch Engine. It must not weaken or rewrite the accepted M22 Railroad V1/V07 routing, TargetSelector, ReservationState, dispatcher or authenticated-clearing contracts.

M23 is followed strictly by M24 Five-Slot Batch Engine, M25 Batch Target Claim Engine, M26 Auto Dispatch Scheduler and M27 Solvability / Deadlock Engine. The previous Gameplay Screen Layout milestone has moved to M28; production UI work must not jump ahead of these five core-gameplay milestones.

---

## MIGRATED LEVEL FACTORY / CONTENT PLATFORM PROGRAM — REFERENCE ONLY

As of 2026-09-14, the 224 Level Factory + Content Platform source requirements are no longer live checklist tasks in this game repository. Their canonical live tracker is:

`Sekiph82/ScrubBots-Level-Factory/TASKS.md`

The migration preserves every source requirement ID and historical meaning while preventing H!veAI from counting the same sidecar work in two repositories.

Canonical families:

- Level Factory: `SB-LF00-001..SB-LF10-008` — 112 source requirements.
- Content Pipeline: `SB-CP00-001..SB-CP09-010` — 112 source requirements.
- Canonical cross-repository mapping: `Sekiph82/ScrubBots-Level-Factory/docs/migration/LF_CP_REQUIREMENT_MAPPING_V01.md`.
- Canonical unification decision: `Sekiph82/ScrubBots-Level-Factory/docs/migration/LEVEL_FACTORY_CONTENT_PLATFORM_UNIFICATION_V01.md`.

Runtime implementation boundary remains explicit. The following requirements are tracked programmatically in the Factory repository but their implementation and audit evidence belong in this game repository when those milestones activate:

- `SB-CP04-001..014` — Godot remote content runtime.
- `SB-CP05-001..012` — offline cache / last-known-good recovery.
- `SB-CP06-004` — disabled-level runtime behavior.
- `SB-CP06-010` — single-level disable runtime test.

These ranges are references here, not live checklist rows. They must not be recreated as a duplicate game-side denominator. When runtime implementation opens, the concrete main-game implementation cycle is tracked in this repository and its accepted audit evidence is mirrored back to the canonical Factory requirement.

Existing game-owned catalog/content QA milestones such as M35, M52 and M53 remain unchanged and continue to gate what the shipping game accepts.

Migration note: removing the 224 duplicate sidecar checklist rows changes the game tracker denominator from 953 to 729 without changing the numerator. This is task-ownership normalization, not newly completed gameplay work.
