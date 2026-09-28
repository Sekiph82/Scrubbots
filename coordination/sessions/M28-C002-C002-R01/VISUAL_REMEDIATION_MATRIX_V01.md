# M28-C002-C002-R01 — VISUAL REMEDIATION MATRIX V01

Date: 2026-09-28
Prompts:
- `coordination/sessions/M28-C002-C002-R01/task_prompts/SB-M28-C002-C002-R01_VISUAL_REMEDIATION.md`
- `coordination/sessions/M28-C002-C002-R01/task_prompts/SB-M28-C002-C002-R01_CONTINUE.md`

Owner authority: `coordination/OWNER_GAMEPLAY_STATIC_SHELL_VISUAL_ACCEPTANCE_V01.md`. This covers S1-A, S2-B, S3-B, S4-A, S5-A and S6-C, plus R01 items A and B.

Focused suite: `tests/m28_c002_c002_r01_visual.gd`, 10/10 cases, 0 fail.

No owner acceptance is claimed.

## 1. Requirement → implementation → test

| # | Requirement | Implementation | Proof |
|---|---|---|---|
| A1 | Live travel body goes from 1.8 to 2.4 cells, cell-relative. | `scripts/gameplay/presentation/scrubbot_visual.gd`: `BODY_SPAN_CELLS := 2.4`. Scale stays `span / texture longest side` in board-cell units. There is no pixel constant. | R01 `body_span_2_4` checks three things:<br>- the constant;<br>- every live agent spans exactly 2.4 cells (35 agents);<br>- 58.6 px on a 24.4 px cell. |
| A2 | No change to route, position, speed or completion. | This is a presentation constant only. `ScrubbotAgent`, routing, rail geometry, bob/lean/squash, the shared texture cache and the debug fallback are untouched. | R01 `route_unchanged_by_scale`: over 400 ticks, agent positions and board truth are identical with 2.4-cell and 1.8-cell bodies. |
| A3 | Retire echo stays proportional. Lifetime, event source and clear semantics are unchanged. | `scrubbot_retire_echo_controller.gd`: `ECHO_SPAN_CELLS := 2.1`. The echo/live ratio is 0.875; it was 0.889. `LIFETIME` 0.28, `SHRINK` 0.5 and the cap of 16 are unchanged, and the echo still observes `authenticated_clear`. | R01 `echo_proportional`: real authenticated clears spawned echoes with a peak of 16. All 13,310 sampled echoes span 2.1 cells at birth. Lifetime and cap are unchanged. Both M32 suites PASS. |
| B1 | Bubble shows live localized text. | `scripts/ui/ui_text.gd` adds two keys:<br>- `GP_BUBBLE_HEADLINE` = "LET'S CLEAN THIS MESS!"<br>- `GP_BUBBLE_INSTRUCTION` = "Tap a batch below to send the Scrubbots."<br>`gameplay_screen.gd` creates two autowrap Labels from `UiText`, placed directly above the bubble mask. | R01 `bubble_live_text`: the Label text equals `UiText`. The obsolete sentence is absent from the copy table. |
| B2 | Text uses the master transform, fits all six masters, and never clips. | Reference boxes in master px are headline `[34,1200,191,1252]` and instruction `[34,1256,191,1320]`, both inside the C002 `BUBBLE_TEXT` mask. Font size is (reference px × shell scale), reduced until the Label's **uncached wrapped minimum** (`get_minimum_size()`) fits the box. The Label is then pinned to the box. | R01 `bubble_live_text` at five sizes and on all six shells:<br>- the Label rect equals the transformed reference rect;<br>- the mask encloses the text;<br>- `bubble_text_fits()` holds;<br>- re-layout is idempotent;<br>- the +1 Slot switch keeps the same fonts.<br>Fonts (headline/instruction): 21/18 at 1080×2160, 18/15 at 1080×1920, 26/21 at 1290×2796, 20/17 at 1536×2048, 29/24 at 1440×3200. |
| B3 | Obsolete baked sentence stays masked. | C002 bubble mask unchanged; it draws under the labels. | R01 checks that the mask encloses the baked-sentence rect. C002 `static_shell` PASS. Visually verified in the renders. |
| C1 | S2-B: front touch target is at least 88 px at 1080×1920. | `scripts/ui/batch_supply_panel.gd`: `set_min_hit_size()`. In shell mode each front tile gets one invisible `top_level` `HitArea` Control that reuses the tile's own `_on_front_gui_input` binding. It grows by `(88 − painted)/2` per axis, **clamped to half the baked gap minus 0.5 px**. `gameplay_screen.gd` sets `UiTokens.TOUCH_MIN` and refreshes the hit areas after every grid layout. | R01 `short_phone_hitboxes`:<br>- 3-col: painted 89 × 83 px → hitbox ≥ 88 px<br>- 4-col: painted ~88 px → hitbox ≥ 88 px<br>- 5-col: painted ~82 px → hitbox ≥ 88 px<br>Each hitbox encloses its tile, and painted tiles stay on the baked cells. A press/release 1 px outside the painted tile activates that front. |
| C2 | No overlap. Previews stay non-interactive. Visuals unchanged. | The half-gap clamp makes overlap impossible by construction. Preview rows keep `MOUSE_FILTER_IGNORE` and get no hit area. `HitArea` is a childless plain `Control`, so it draws nothing. | R01: adjacent hitboxes are disjoint, none intersects a preview row, previews are IGNORE, and each HitArea is a childless top-level plain Control. |
| C3 | Slot touch geometry. | Slot views are `MOUSE_FILTER_IGNORE`. Slots have no tap input in the production input model, so nothing needed to expand. Slot law is unchanged. | C002 `static_shell` slot geometry PASS, unchanged. |
| D | S3-B: AD placeholder invisible, region reserved. | `AdRegion` uses `StyleBoxEmpty` and has no label. Its rect is still placed on `Shell.AD`. New `is_ad_placeholder_visible()` returns false. | R01 `ad_invisible_reserved`: no visible band or label. The reserved region stays at the bottom band, and the boosters stay above it. |
| E | S1-A, S4-A and S5-A preserved. | No change. | R01 `accepted_styling_preserved` covers the navy surround, the Pause glyph with live 2x text, the cyan front edge with dimmed previews, and the cyan edge on ACTIVE slots. C001 14/14 and C002 16/16 PASS. |
| F | S6-C: the V02 shell path is square-only in production. | `scripts/data/level_catalog.gd` adds `square_shell_error(w, h)`. In `load_manifest` it runs after the production validation: a failure adds an entry error and skips the entry. It also runs in `validate_all`. The generic rectangular engine, `LevelData`, the Factory and the TEST fixtures are untouched. | R01 `square_only_production`:<br>- the real catalog loads and every entry is square;<br>- a non-square entry is rejected with an explicit S6-C reason;<br>- batch revalidation passes.<br>M35 migrated (§4). |
| — | Masters byte-identical. | No file under `assets/ui/final/gameplay/master/` is touched. | R01 `masters_unchanged`. All six SHA-256s re-checked against `coordination/OWNER_GAMEPLAY_345_STATIC_MASTER_SHELL_V01.md` (§5). |
| — | No node or signal accumulation. | HitAreas are children of the front tiles and are rebuilt with them. Bubble labels are built once. | R01 `no_accumulation`: 4× (+1 Slot, retry) leaves nodes at 118 → 118 and HitAreas at 3 → 3. |

## 2. Touch geometry at 1080×1920

- **3-col:** 89 px wide, so there is no x growth. It grows 2.5 px above and below, giving an 89 × 88 hitbox.
- **4-col and 5-col:** painted cells are about 88 and 82 px. They grow on both axes, still inside half of each baked gap.
- **Minimum hitbox:** 88.0 px on every shell.
- **Exceptions:** none. 88 px is reachable without overlap everywhere.

## 3. Sensitivity mutations (final code)

For each mutation: apply it, run the R01 suite, then restore the file from a byte copy and confirm with `cmp`.

| Mutation | R01 result |
|---|---|
| `BODY_SPAN_CELLS` 2.4 → 1.8 | FAIL (4) |
| `ECHO_SPAN_CELLS` 2.1 → 1.6 | FAIL (3) |
| `set_min_hit_size` call removed | FAIL (5; min hitbox 83 px) |
| AD region drawn (`StyleBoxFlat`) | FAIL (1) |
| `GP_BUBBLE_INSTRUCTION` empty | FAIL (19) |
| Bubble shrink-to-fit disabled | FAIL (5) |
| Square gate always passes | FAIL (1) |
| Fit loop measures with the cached `get_combined_minimum_size()` (the defect in §4.1) | FAIL (5: "+1 Slot shell switch keeps the same bubble fonts") |

## 4. Defects found in R01 and fixed

1. **Bubble fit used a stale measurement.**
   - Raw `Font.get_multiline_string_size` omits the Label's line spacing, so the Labels outgrew their boxes by 3–6 px.
   - The first replacement used `get_combined_minimum_size()`. That value is cached until the next frame, so within the loop it did not reflect the new font size.
   - The first layout came out right only by coincidence. A second pass kept the unshrunk 25/20 px font. This happened on the +1 Slot shell switch and was visible in the six-slot render: the text was crowded but still inside the bubble.
   - **Fix:** measure with the uncached `get_minimum_size()`.
   - **Guard:** re-layout idempotence plus identical fonts after the 5→6 switch, at every size.
2. **Bubble text rendered below the bubble in the first draft.** The autowrap minimum height was computed at the pre-layout width. Fixed by pinning size and position after width and font are final.
3. **M35 `rect_easy` encoded the pre-S6-C policy.** It asserted that a 24×28 catalog entry is accepted.
   - **Migration:** the same level is rejected with exactly one error, the S6-C square-shell message. This proves it is otherwise legal to the rectangular-capable validator. The level is also not exposed to the catalog.

## 5. Master hashes (re-checked after all work)

| File | SHA-256 | vs owner doc |
|---|---|---|
| `gameplay_v02_shell_5slot_3col.png` | `4ee6712df6aedb3ee48d5cf2e2971356bd9df14363e777965c7e4691ca3121da` | MATCH |
| `gameplay_v02_shell_5slot_4col.png` | `dcf92b4fe163d0c5e6543f90943528ea064c08b31ed11d5c26c158265a9a8fac` | MATCH |
| `gameplay_v02_shell_5slot_5col.png` | `c520c5055caff58f5a9a1ff7eb7ceb98ce5873b9abf86e03b183a8442afc7636` | MATCH |
| `gameplay_v02_shell_6slot_3col.png` | `75c148266a4d0aec20a0eb5c299d00a2840e13d8cc10ae6ec60731f0823f8f06` | MATCH |
| `gameplay_v02_shell_6slot_4col.png` | `d3d01b697d14fbb8896b70594c5768dd1be7606a6519aec2aa71770a5fa38a55` | MATCH |
| `gameplay_v02_shell_6slot_5col.png` | `5ad162d288e8c8d33c5e40d0bb3caedb32939165853a602d868a4caa6428c12b` | MATCH |

`git diff HEAD -- assets/ui/final/gameplay/master` is empty.
