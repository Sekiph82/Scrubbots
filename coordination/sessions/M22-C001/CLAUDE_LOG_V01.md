# M22-C001 V01 — Production Five-Slot UI Foundation — Claude Implementation Log

Repository: `Sekiph82/Scrubbots`
Branch: `main`
Actor: Claude (implementer/test runner)
Engine: Godot `4.7.2.stable.official.ed1daf0bf` (unchanged; not installed/upgraded)
Date: 2026-09-14
Handoff state: `AWAITING_AUDIT`

ChatGPT owns audit closure and root `TASKS.md`. This log authors no audit verdict.

---

## 1. Starting / sync state

- Confirmed repository `Sekiph82/Scrubbots`, branch `main`, remote `origin =
  https://github.com/Sekiph82/Scrubbots.git`.
- Start: local `main` was **behind `origin/main` by 4** with pre-existing
  owner/local work in the tree (tracked mods to `project.godot`,
  `scenes/debug/routing_prototype_lab.tscn`,
  `scenes/debug/scrubbot_agent_debug.tscn`, plus many untracked owner `.uid` /
  `.import` sidecars and `_owner_inbox` references).
- Incoming 4 commits touched only `TASKS.md`, `CHATGPT_AUDIT_V10.md`,
  and the M22-C001 V01 prompt/audit-criteria — disjoint from all owner-local
  changes. Sync performed with a **fast-forward** (`141ce6b..baf4ba1`); no
  `reset --hard`, no `clean`, no destructive restore, no stash, no force. All
  owner-local tracked and untracked work preserved untouched.
- Synced base: `origin/main` @ `baf4ba1` (`tracker: close M21 and advance to
  M22-C001 V01`).

Root `TASKS.md` was read and **not modified**.

---

## 2. Exact changed files (this prompt)

Authored/edited by this work:

- `ASSET_GENERATION_MANIFEST.json` — surgical palette-contract migration (§10).
- `scripts/ui/color_selection_panel.gd` — **new** reusable production panel.
- `scripts/ui/gameplay_slot_demo.gd` — **new** narrow production integration harness.
- `scenes/components/ui/gameplay/slot_cell.tscn` — **new** production SlotCell scene.
- `scenes/components/ui/gameplay/color_selection_panel.tscn` — **new** panel scene.
- `scenes/demo/m22_slot_demo.tscn` — **new** demo/integration scene (not M23 screen).
- `tests/m22_responsive_smoke.gd` — **new** responsive/safe-area/spawn-anchor smoke.
- `tests/run_tests.gd` — added `_run_m22_slot_component_tests()` +
  `_run_m22_integration_active_tests()` and registered both in `_initialize()`.
- `coordination/sessions/M22-C001/CLAUDE_LOG_V01.md` — this log.

Deliberately left **unstaged** (pre-existing owner/local work, not part of this
prompt): `project.godot`, `scenes/debug/routing_prototype_lab.tscn`,
`scenes/debug/scrubbot_agent_debug.tscn`, and all untracked owner `.uid` /
`.import` / `_owner_inbox` sidecars.

Reused, **not** modified: `scripts/ui/slot_view.gd` (accepted M21 SlotView; the
production SlotCell scene attaches it as its script rather than rebuilding
working logic), `scripts/ui/ui_tokens.gd`, `scripts/ui/responsive_layout.gd`,
all accepted M21 gameplay collaborators, and the M21 debug scene/controller.

---

## 3. Production-vs-debug component boundary

The M21 debug controller (`scripts/debug/m21_real_art_vertical_slice.gd`) builds
its slot bar ad hoc via `SlotView.new()` inside developer/owner-playtest code. It
is **not** the production UI. V01 introduces reusable production **scenes**:

- `SlotCell` = reusable production scene (`slot_cell.tscn`) whose script is the
  accepted M21 `slot_view.gd` behavior (documented equivalent per prompt §8 /
  criteria M22-V01-026/028 — reuse over gratuitous rebuild).
- `ColorSelectionPanel` = reusable production scene owning exactly five SlotCells.
- `GameplaySlotDemo` = a **narrow** production integration harness that hosts the
  panel and drives the accepted M21 chain. It is explicitly **not** the M23 full
  gameplay screen and **not** a rename of the M21 debug scene.

The M21 debug scene is untouched; both the debug path and the new production path
coexist and are independently tested.

---

## 4. Component architecture / tree

```text
scenes/components/ui/gameplay/
  slot_cell.tscn                 (Button + scripts/ui/slot_view.gd)  # SlotCell
  color_selection_panel.tscn     (HBoxContainer + color_selection_panel.gd)

scenes/demo/
  m22_slot_demo.tscn             (Control + gameplay_slot_demo.gd)   # integration

M22SlotDemo (Control, full-rect)
├── ColorRect (BG01 background)
├── BoardPresentation (accepted M21 shared board/agent transform)
│    ├── BoardRenderer (single Image/ImageTexture — unchanged)
│    └── AgentLayer (Node2D, scale = cell_size) → ScrubbotAgent(s)
├── ScrubbotDispatcher (accepted M21)
└── ColorSelectionPanel (HBoxContainer, container-driven)
     ├── SlotCell(id=0) … SlotCell(id=4)   # exactly five, left-to-right
```

- Layout is container-driven (HBoxContainer, centered, `SPACE_MD`=16 separation,
  `COLOR_SELECTION_MIN_WIDTH`=620 protected min width), **not** five absolute
  screen coordinates. `BoardRenderer` remains the single-Image board renderer; no
  Control-per-cell.

---

## 5. Scalar / query binding model

- The panel consumes **scalar** state only: `bind_colors(Array[Color])`, indexed
  by slot id. It never stores a `SlotSystem` / `SlotState` / `BoardState` /
  `ReservationState` reference (criteria M22-V01-029/030). Verified: the panel
  exposes no `get_slot_system` and the cell exposes no `get_slot_state`.
- The demo builds the scalar snapshot from the **real** SlotSystem palette
  mapping: `colors[slot_id] = PaletteColors.parse(level.palette)[SlotSystem.
  get_slot_palette_id(slot_id)]` — real bound colors, not a decorative order
  (criteria M22-V01-033/034/087). Colors render exactly (tolerance 0.001).
- Presentation binding can rebuild without mutating the gameplay model; a re-bind
  rebuilds cells from a fresh scalar snapshot. LevelData palette proven immutable
  across all UI operations (M22-V01-097).
- Two independent panel instances own distinct cell nodes and independent
  active-state bookkeeping (M22-V01-096).

---

## 6. Interaction chain (adapter to accepted M21 gameplay)

```text
SlotCell (Button).pressed
  → SlotView._on_pressed → slot_activated(slot_id)
  → ColorSelectionPanel re-emits slot_activated(slot_id)
  → GameplaySlotDemo._on_slot_activated → request_slot(slot_id)
  → CompleteClearingLoop.activate_slot(slot_id, mapped_anchor_start, 6.0)
  → TargetSelector (bottom-most/left-most reachable) → ProductionRoutingSystem
  → ScrubbotDispatcher → ScrubbotAgent → authenticated arrival → M20 clear
```

- One activation emits exactly one slot id (M22-V01-039); rapid distinct presses
  preserve per-press ids `[1,4,1]` with no collapse/duplication (M22-V01-043/095).
- The panel/cell itself never selects a target, routes, dispatches, mutates the
  board, or clears. No SPACE / keyboard gameplay path exists (M22-V01-040/042).
- Direct evidence at baseline: first real C08 (slot 2) click naturally selects
  target **380 / (0,19)** (bottom-most/left-most), dispatched color id == 2 (C08).
  No-reachable-work slot (C01, slot 0, enclosed on fresh board) produces **no**
  assignment and **no** BoardState clear (board stays 400 ACTIVE).

Accepted M21 gameplay collaborators are reused verbatim (same preloaded classes);
V01 introduces no new gameplay truth.

---

## 7. Active / in-flight lifecycle evidence

Presentation-only active visual driven from real in-flight assignment truth
(owner_id → slot), reconciled by observation (never advances agents):

- three concurrent same-slot C08 assignments → slot active; `active_count = 3`;
- complete one agent → `3→2`, slot **stays** active;
- complete next → `2→1`, slot **stays** active;
- complete last → `1→0`, slot returns idle **only** at zero (M22-V01-048);
- during the above, unrelated slots (0, 4) stay idle — per-slot independence,
  not a blanket flag (M22-V01-049);
- `reset_presentation()` clears all active visuals and resets the gameplay loop
  without altering accepted M21 reset semantics (M22-V01-050).

Correct no-work behavior is present; **no** special no-work visual skin was
invented — `SB-M22-008` remains design-gated (M22-V01-051/119).

---

## 8. Spawn-anchor evidence

- Each SlotCell exposes a presentation-only **global** top-center spawn anchor
  from its actual laid-out geometry (`get_spawn_anchor_global`). Not a hard-coded
  board coordinate.
- The demo maps it into board-local route space through the accepted
  `BoardPresentation.global_to_board_local` (AgentLayer inverse) transform.
- Baseline proof (real SubViewport layout, after frames):
  `slot=2 anchor_global=(392.0, 880.0) → mapped_local=(9.222222, 21.11111)`;
  the real ScrubbotAgent `spawn_origin == mapped` (dist < 0.001) and the route's
  first point `== mapped` (dist < 0.001); target = 380. Anchors follow layout —
  the responsive matrix confirms per-cell anchors track re-layout (no stale
  cached pre-layout coordinate).

---

## 9. Responsive matrix — measured post-layout geometry

Real Control layout established in a SubViewport at each size, awaited two layout
frames, then measured. Every case: five cells, no overlap, deterministic
left-to-right, each cell ≥ 88×88 reference px, all inside safe bounds, each spawn
anchor attached to top-center of its own cell.

| Viewport      | cells | cell size | cell0 pos        | cell4 pos        | overlap | touch≥88 | in-bounds |
|---------------|-------|-----------|------------------|------------------|---------|----------|-----------|
| 1080×2160     | 5     | 120×120   | (208, 1970)*     | (752, 1970)*     | none    | yes      | yes       |
| 1170×2532     | 5     | 120×120   | —                | —                | none    | yes      | yes       |
| 1290×2796     | 5     | 120×120   | (313, 2606)      | (857, 2606)      | none    | yes      | yes       |
| 1080×2400     | 5     | 120×120   | (208, 2210)      | (752, 2210)      | none    | yes      | yes       |
| 1440×3200     | 5     | 120×120   | (388, 3010)      | (932, 3010)      | none    | yes      | yes       |
| 1080×1920 (16:9)| 5   | 120×120   | (208, 1730)      | (752, 1730)      | none    | yes      | yes       |
| 1536×2048 (tablet)| 5 | 120×120   | (436, 1858)      | (980, 1858)      | none    | yes      | yes       |

Separation constant = 16 (`SPACE_MD`) in every case.
*(1080×2160 / 1170×2532 rows PASS in the smoke; positions follow the same
container centering as the other rows.)*

**Non-zero safe-area inset harness** (1080×2160, insets L=48 T=96 R=48 B=120):
inner safe rect `(48, 96) size (984, 1944)`; all five cells enclosed
(cell0 `(208,1008) 120×120`, cell4 `(752,1008) 120×120`). No BoardRenderer
aspect distortion introduced by the slot component layout.

Not a tautological self-comparison: geometry is read from real laid-out Control
rects produced by the actual viewport, not compared against a constant rectangle.

---

## 10. Manifest migration (before → after)

Surgical edit of `pixel_art_palette_contract` in `ASSET_GENERATION_MANIFEST.json`.
All unrelated entries (assets, statuses, provider policy, native-Godot list,
references) preserved.

Before:
- `version: 1`
- `source: data/palettes/scrubbots_palette_v1.json`
- `allowedColorIds: C01..C15`
- `difficultyDistinctUsedColorBands: { EASY [3,5], MEDIUM [6,7], HARD [8,9],
  VERY_HARD [10,12] }` (stale class-law)
- `aiPixelArtRule: … C01..C15 …`

After:
- `version: 2`
- `source: data/palettes/scrubbots_palette_v2.json`
- `allowedColorIds: C01..C16` (C16 added)
- removed `difficultyDistinctUsedColorBands`; added
  `productionUsedColorEnvelope: [3, 12]`,
  `difficultyClassDerivedFromColorCount: false`, and a `difficultyColorNote`
  recording that difficulty class is **not** derived from color count and that
  the old class-specific bands are superseded (Difficulty V1, 2026-09-12).
- `aiPixelArtRule: … C01..C16 …`

Preserved unchanged: `generator_policy` (Magnific-only, Higgsfield disallowed),
all asset `status` values (no fake owner-approval/generation), native-Godot
components list, canonical references. Manifest validated as JSON after edit
(Python `json.load` OK).

---

## 11. Magnific / AI generation

**Magnific credits spent = 0.** No Magnific or any other image-generation
provider was called. No booster/Scrubby/slot-frame/color-tile/decorative asset
was generated. Slot frames and color tiles are native Godot Controls
(`ColorRect` swatch inside a `Button`), per Master UI System and manifest.

---

## 12. Owner reference paths audited (read-only; bytes/names preserved)

- Canonical gameplay art-direction reference (manifest-selected):
  `assets/art/references/_owner_inbox/Game Screens/deneme 3 OK.png`
  (present, 2,196,252 bytes, untouched).
- Gameplay play-screen reference showing the five-slot/color-selection area:
  `assets/art/references/_owner_inbox/Game Screens/oyun oynama ekrani.png`.
- Supporting art direction (read-only): `Game Screens/main screen.png`,
  `Game Screens/level ekran acilisi.png`, `Level Sheets/*.jpeg`.
- `docs/MASTER_UI_SYSTEM.md` confirmed as the UI architecture source of truth;
  the component targets `scenes/components/ui/gameplay/slot_cell.tscn` and
  `color_selection_panel.tscn` come directly from its §7 component library.

No reference bytes or names were altered. No flattened screenshot was promoted
to interactive production UI.

---

## 13. Exact test / regression commands and results

Engine: `godot --version` → `4.7.2.stable.official.ed1daf0bf` (unchanged).

| # | Command | Result |
|---|---------|--------|
| 1 | `godot --version` | 4.7.2.stable.official.ed1daf0bf |
| 2 | `-s tests/run_tests.gd` (full root suite) | **Total checks: 4649, Failures: 0, RESULT: ALL PASS, exit 0** |
| 3 | `-s tests/m22_responsive_smoke.gd` | PASS, exit 0 (matrix + 16:9 + tablet + non-zero safe-area + baseline anchor mapping) |
| 4 | `-s tests/m21_v10_final_reservation_evidence.gd` | PASS, exit 0 |
| 5 | `-s tests/m21_v09_direct_evidence_reconciliation.gd` | PASS, exit 0 |
| 6 | `-s tests/m21_v08_corridor_validation.gd` | PASS, exit 0 |
| 7 | `-s tests/m21_v07_corridor_smoke.gd` | PASS, exit 0 |
| 8 | `-s tests/m21_v06_tall_layout_smoke.gd` | PASS, exit 0 |
| 9 | `-s tests/m21_v05_playtest_smoke.gd` | PASS, exit 0 |
| 10 | `-s tests/m21_real_art_smoke.gd` (full 400-clear) | PASS, exit 0 |
| 11 | M20 `queue_free`, `v04/v05/v07/v08/v09/v10_lifecycle_smoke` | all PASS, exit 0 |
| 12 | full root `run_tests.gd` check count | **4649 checks, 0 failures, exit 0** |
| 13 | headless boot of M22 demo/component harness | zero SCRIPT/Parse errors (demo scene loads + builds under the responsive smoke and the integration suite section) |
| 14 | JSON parse of `ASSET_GENERATION_MANIFEST.json` | valid |
| 15 | `git diff --check` | clean |

The full suite's exit is 0 / ALL PASS. (Godot prints benign teardown warnings —
leaked CanvasItem RID / ObjectDB instances / resources-in-use "at exit" — as
before this change; they are shutdown noise, not test failures, and exit code is
0.)

New M22 checks added to the root suite:
`_run_m22_slot_component_tests` (five cells, stable ids, real palette binding,
touch size, one-click-one-id, rapid presses, no reference leakage, active/reset,
two-instance independence) and `_run_m22_integration_active_tests` (no-work,
C08→380/(0,19), active 3→2→1→0, cross-slot independence, reset, LevelData
immutability).

---

## 14. M21 locked gameplay non-regression

Accepted M21 identities are unchanged and proven still-standing:

- first real C08 click naturally selects target **380 / (0,19)** (M22 integration
  test + baseline smoke) — bottom-most/left-most reachable priority intact;
- one-cell four-side exterior routing corridor: M21 V07/V08 smokes PASS;
- exact ReservationState lifecycle + M20 clearing authority: M21 V09/V10 and M20
  lifecycle smokes PASS;
- full 400-cell real-art clear: `m21_real_art_smoke` PASS;
- no accepted M21 TargetSelector/routing/dispatcher/clearing/agent/board/
  ReservationState source was modified — the demo reuses those classes verbatim.
  No M21 gameplay regression was encountered, so no `BLOCKED`.

---

## 15. Deferred / design-gated

- `SB-M22-008` no-work final visual skin: **not** implemented (design-gated).
  Correct no-work behavior (no bot, no side effect) is present.
- `SB-M22-015..019` booster/decorative generation: **not** touched; statuses
  remain truthful; zero generation.
- Full M23 gameplay-screen composition: out of scope (M23 owns it).

---

## 16. Tracker statement

Root `TASKS.md` was **not modified**. ChatGPT owns tracker updates and audit
closure. No audit verdict/file was authored by Claude.
