# M32-C002 — CLAUDE LOG V01 (board-resolution-independent Scrubbot apparent size, SB-M32-UI-012)

Date: 2026-09-29
Prompt: `CHATGPT_PROMPT_V01.md` · Criteria: `CHATGPT_AUDIT_CRITERIA_V01.md` · Matrix: `IMPLEMENTATION_MATRIX_V01.md`
Owner authority: `coordination/OWNER_SCRUBBOT_SIZE_AND_GAMEPLAY_TEMPO_V01.md` §1
Status: **AWAITING_CHATGPT_AUDIT** (owner visual acceptance still required)

## Sync / governance

- `main` was fast-forwarded (`--ff-only`) to the M32-C002 prompt/criteria commits with no conflict.
- Root `TASKS.md` was read and **not edited**.
- Local owner files were preserved and not committed: the `project.godot` drift, untracked assets, Godot `.import`/`.uid` files and `tests/_m55_diag_tmp.gd`.
- The change is presentation-only. Nothing else was touched:
  - ScrubbotAgent;
  - routing;
  - target selection;
  - claims;
  - clear timing;
  - BoardState;
  - BoardRenderer cell geometry;
  - hit testing;
  - railway;
  - solver;
  - tempo;
  - economy;
  - level data;
  - the production board envelope.

## Geometry formula / seam

**Reference.** The reference is the owner-accepted 32x32 / 2.4-cell look. The constants stay `BODY_SPAN_CELLS = 2.4` and `ECHO_SPAN_CELLS = 2.1`; they now mean "span at the 32x32 reference presentation".

**`BoardPresentation`** (`scripts/gameplay/board/board_presentation.gd`):

- **Default rule, run inside `configure()`:**
  - `reference_cell = max(floor(min(avail.x/32, avail.y/32)), 1)`, which is BoardRenderer's own floored rule for a 32-cell board in the same rect;
  - `compensation = reference_cell / renderer_cell`.
- **Production seam, `set_scrubbot_reference_display_cell(ref_display_cell)`:**
  - `compensation = ref_display_cell / (renderer_cell × presentation.scale.x)`, i.e. against the actual display cell;
  - non-finite or non-positive input is ignored.
- **`_presentation_generation`** is bumped by every `configure()` and every reference update.
- **Getters:** `get_scrubbot_size_compensation()`, `get_reference_cell_size()`, `get_available_size()`, `get_presentation_generation()`, and static `reference_cell_size_for()`.

**`GameplayScreen._layout_board`** (`scripts/ui/gameplay_screen.gd`):

- The existing rail-loop fit expression was extracted, unchanged, into `_board_display_cell(rr, w, h)`.
- After it scales the presentation, the screen reports `_board_display_cell(rr, 32, 32)`: the display cell a 32x32 board would get from the **same** fit in the **same** baked rail region.
- The board, agent and rail transform is unchanged, since `exact`, `cell`, `configure` and `scale` are all identical.

**Result.** Displayed body = 2.4 × reference display cell × shell scale, identical for every board resolution and aspect on a given viewport. The code has no board-size lookup; the only constant is the 32-cell owner reference.

**Why the local spans are not exactly the prompt's 1.5 / 2.85 / 4.425 / 7.5:**

- The real screen fits the board **plus its rail loop** (N + 5 cells), floors the renderer cell, and then applies a fractional presentation scale.
- The spans are therefore derived from that real geometry. For example, 20x20 gets 1.6216 cells and 59x59 gets 4.1514 cells. The displayed size is exact (delta 0.000%).
- The prompt anticipated this: "exact local spans may differ slightly".

## Visual / echo / relayout

**`ScrubbotVisual`:**

- On attach it finds the presentation seam once, at most 4 ancestors up (agent → AgentLayer → BoardPresentation).
- It computes `_base_scale = 2.4 × compensation / longest_texture_dim`.
- `animate()` compares the presentation generation (an O(1) int compare) and recomputes only when the generation changed.
- Bob, lean and squash use the compensated base.
- Without a seam (bare tests) the compensation is 1.0.
- No scene-tree scan, no texture work, and the agent position is never touched.
- New: `refresh_size()`, `get_local_body_span_cells()`, `get_size_compensation()`.

**`ScrubbotRetireEchoController`:**

- `get_size_compensation()` reads the SAME seam from the bound retire layer's parent.
- A spawn uses `2.1/longest × compensation`.
- `age()` reads the compensation once per tick, so an active echo also follows a mid-echo relayout.
- Placement, lifetime (0.28 s), shrink (0.5), cap (16) and the event source are unchanged.

## Focused suite: `tests/m32_c002_board_independent_size.gd` **PASS (86 checks, 0 failed)**

- **s0: real production GameplayScreen, fixed 1080x2160 viewport.**
  - Boards: L2 apple 32x32 (reference), L1 hazard bot 20x20, L3 palm tree 38x38, TEST 59x59, TEST 59x40 (width-limited), TEST 24x40 (height-limited).
  - Also a TEST synthetic 100x100: the same real screen reconfigured with a detached BoardState. The dispatcher refuses 100x100 and it is **not** expanded.
  - Every board measures **58.64 px (delta +0.000%)**.
  - Pre-C002 values for comparison: 20x20 86.8 px (+48%), 38x38 50.5 px (−14%), 59x59 33.9 px (−42%), 100x100 20.7 px (−65%).
- **s1: standalone formula.**
  - Covers 20/32/38/59, 59x24 / 40x24 (width-limited), 24x59 / 24x40 (height-limited) and 100x100.
  - A 140-presentation sweep of (w, h, rect) matched the geometry formula every time (0 mismatches).
  - The 20x20 span varies by rect (1.5158 / 1.44 / 1.488 / 1.5), so it is not a table.
- **s2: 32x32 lock.** Compensation is exactly 1.0 and the local span exactly 2.4 on three rects. The constants are unchanged.
- **s3: measured global footprint.** All boards are within ±3% (actually exact) of 32x32.
- **s4: live relayout on a real host (L3 38x38).** The viewport went 1080x2160 → 1536x2048, then relayout.
  - The generation was bumped;
  - the same agent instance survived;
  - route, progress and position were unchanged;
  - the body re-sized through its own frame update, 58.64 → 55.60 px, which is 2.4 × the new reference;
  - the same texture object was kept;
  - the agent then arrived.
- **s5: differential.** A compensated visual under a presentation relaid out every 40 frames, compared with a bare agent (59x59 route, 18 cells/s):
  - position, progress and state were bit-identical for all frames;
  - completion count was 1/1;
  - the endpoint was identical.
- **s6: echo.** On 32/20/38/59/59x24/100:
  - echo 52.50 px vs live 60.00 px, ratio **0.8750 = 2.1/2.4**;
  - exact cell centre;
  - half-life shrink and fade unchanged;
  - a mid-echo relayout rescales to 2.1 × the new reference;
  - expiry is unchanged;
  - cap 16 and 4 suppressed out of 20.
- **s7: performance at 59x59 with 30 live visuals.**
  - One shared texture.
  - Object count stable over 600 frames.
  - Steady animate ~38 µs/frame for all 30.
  - First frame after a relayout ~83 µs.

## Owner visual evidence (`evidence/`, fresh, non-headless, `tests/tools/m32_c002_size_snapshot.gd`)

The snapshots use a real host at 2x with real dispatched bots. Four static lineup probes are also placed at identical board fractions on every board, so the size comparison is obvious. They are real ScrubbotVisual nodes in the real AgentLayer, presentation-only and never routed.

**Montages:**

- `m32c002_MONTAGE_BOARD_CROP_20_32_38_59_full_res.png`: the board crops side by side at full resolution.
- `m32c002_MONTAGE_20_32_38_59_same_viewport.png`: full screens.
- `m32c002_MONTAGE_BOARD_CROP_preC002_vs_C002_20_38_59_full_res.png` and `..._preC002_vs_C002_20_and_59.png`: before/after.

**Individual shots:**

- `m32c002_20x20_L1_hazard_bot_1080x2160.png`
- `m32c002_32x32_L2_apple_REFERENCE_1080x2160.png`
- `m32c002_38x38_L3_palm_tree_1080x2160.png`
- `m32c002_59x59_TEST_stripe_1080x2160.png`
- `m32c002_rect_59x40_TEST_width_limited_1080x2160.png`
- `m32c002_rect_24x40_TEST_height_limited_1080x2160.png`
- `m32c002_synthetic_100x100_TEST_screen_only_1080x2160.png`
- `m32c002_relayout_BEFORE_38x38_1080x2160.png` and `m32c002_relayout_AFTER_38x38_tablet_1536x2048.png`
- `pre_*.png`: the same frames rendered with the old constant 2.4-cell body.

Note: on the 20x20 and 38x38 shots, the naive harness column clicking did not reach a dispatchable colour within 600 frames, so those two show only the lineup probes. The 32/59/rectangle shots include real in-flight bots on the rail, connectors and board.

**Numbers:** `m32c002_measurement_report.md`, plus `m32c002_snapshot_measurements.json` and `m32c002_focused_report.json`.

## Regression: `evidence/regression_summary.txt`

- 115 suites, 6-way parallel: **113 exit 0**. This includes:
  - root 5323/5323 ALL PASS;
  - M32 (`m32_scrubbot_visual_evidence`, `m32_scale_59_visuals`);
  - M28 including `m28_c002_c002_r01_visual`, which checks the 2.4 span / echo 2.1 at the 32x32 reference;
  - M29 presentation;
  - M30 retry;
  - M31;
  - all M39;
  - M52;
  - M55 long session and chaos.
- Standalone: `m32_c002_board_independent_size` PASS and `m29_c002_tempo_retune` PASS.
- The only non-zero exits are m21_v08 (C/043, C/047) and m21_v09 (B), with the known signatures.
- `git diff --check` is clean apart from CRLF advisories.

## Files

- **Production:**
  - `scripts/gameplay/board/board_presentation.gd`
  - `scripts/ui/gameplay_screen.gd`
  - `scripts/gameplay/presentation/scrubbot_visual.gd`
  - `scripts/gameplay/presentation/scrubbot_retire_echo_controller.gd`
- **Tests:**
  - `tests/m32_c002_board_independent_size.gd`
  - `tests/tools/m32_c002_size_snapshot.gd`
- **Evidence:** `coordination/sessions/M32-C002/evidence/`

`AWAITING_CHATGPT_AUDIT / M32-C002 BOARD-INDEPENDENT SCRUBBOT SIZE V01`
