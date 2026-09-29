# M32-C002 — IMPLEMENTATION MATRIX V01 (board-resolution-independent Scrubbot size, SB-M32-UI-012)

Prompt: `CHATGPT_PROMPT_V01.md` · Criteria: `CHATGPT_AUDIT_CRITERIA_V01.md` · Log: `CLAUDE_LOG_V01.md`
Focused suite: `tests/m32_c002_board_independent_size.gd` **PASS (86 checks)** · Evidence: `evidence/`

## Changes (presentation only)

| File | Change |
|---|---|
| `scripts/gameplay/board/board_presentation.gd` | Adds the 32-cell reference and a default compensation, both computed in `configure()`. Adds the production seam `set_scrubbot_reference_display_cell()`, a `_presentation_generation` counter, and read-only getters. The renderer, AgentLayer and FX layer transforms are unchanged. |
| `scripts/ui/gameplay_screen.gd` | The existing fit is extracted verbatim into `_board_display_cell(rr, w, h)`. After scaling, the screen reports `_board_display_cell(rr, 32, 32)` as the reference display cell. |
| `scripts/gameplay/presentation/scrubbot_visual.gd` | Base scale = 2.4 × compensation / longest texture dimension. The seam is found once on attach; the visual recomputes on a generation change inside `animate()` (O(1)). New: `refresh_size()` and span/compensation getters. |
| `scripts/gameplay/presentation/scrubbot_retire_echo_controller.gd` | The echo uses the same seam: spawn at 2.1 × compensation, and `age()` follows a mid-echo relayout. Lifetime, shrink, cap and events are unchanged. |

## Criteria → evidence

| Crit | Proof | Result |
|---|---|---|
| A geometry-derived | Real screen: the reference is the same rail-loop fit for 32x32 in the same region, and compensation = ref / (renderer cell × scale). Default: floor(min(rect/32)) / renderer cell. There is no board-size table. A 140-presentation sweep gave 0 mismatches, and the 20x20 span varies with the rect. No pixel math enters the agent, routing or BoardState. | PASS |
| B apparent size ±3% | s0, real GameplayScreen at 1080x2160: the 20x20, 32x32, 38x38, 59x59, 59x40 and 24x40 boards and the synthetic 100x100 all measure **58.64 px, delta 0.000%**. s3, standalone at 800x820: every board measures 60.00 px, delta 0.000%. Snapshot measurements: every live body on every shot matches the expected value. | PASS |
| C 32x32 reference | Compensation is exactly 1.0 and the span exactly 2.4 on the real screen and on three standalone rects. The constants are unchanged. The M28 R01 visual suite (32x32, 2.4 / 2.1) passes. | PASS |
| D dynamic relayout | s4 on a real host (L3 38x38, 1080x2160 → 1536x2048): same agent instance; route, progress and position unchanged; the body re-sized through its own frame update, 58.64 → 55.60 px (= 2.4 × new reference); same texture object; the agent then arrives. The snapshot relayout pair shows the same agent IDs and positions. | PASS |
| E presentation-only truth | s5: a compensated visual with relayouts every 40 frames vs a bare agent: bit-identical position, progress and state; 1/1 completions; identical endpoint. M29 speed authority and tempo, M52, M55 and root all PASS. | PASS |
| F rectangular | Width-limited (59x40, 59x24, 40x24) and height-limited (24x40, 24x59) boards are all at 0.000% delta, with screenshots of 59x40 and 24x40. | PASS |
| G echo | Echo 52.50 px vs live 60.00 px (ratio 0.8750 = 2.1/2.4) on 32/20/38/59/59x24/100. Exact cell centre. Lifetime 0.28 s, shrink 0.5 and cap 16 (4/20 suppressed) are unchanged. A mid-echo relayout rescales the echo. | PASS |
| H asset / performance | Same canonical texture, shared (one object across 30 visuals, and across relayout). No per-size assets. Object count stable over 600 frames. ~38 µs/frame for 30 visuals; the first frame after a relayout takes ~83 µs. No tree scan. | PASS |
| I fresh evidence | 20/32/38/59/rectangle/100 shots on the same 1080x2160 viewport, the relayout before/after pair, pre-C002 comparisons, full-resolution board-crop montages and `m32c002_measurement_report.md`. | PASS (owner gate pending) |
| J regression / governance | 113 of 115 suites exit 0, including root 5323/5323. The only failures are the known m21_v08/v09 signatures. M29-C002 and M32-C002 pass standalone. `TASKS.md` untouched. | PASS |
| K owner gate | Owner reviews the montages and shots. | OWNER |
