# M28-C002-C004 — REMEDIATION MATRIX V02

Prompt: `CHATGPT_PROMPT_V02.md` · Criteria: `CHATGPT_AUDIT_CRITERIA_V02.md` · Prior: `f85e698` (V01, AUDITED_PASS)
Status: **AWAITING_CHATGPT_AUDIT**. Owner recheck of the base colour is still required (SB-M28-C002-021 not self-closed).

## The one change

`scripts/ui/color_batch_tile.gd`, `_style()`:

| | V01 | V02 |
|---|---|---|
| Base body fill | fixed `BASE_COLOR` `#EDF2FA` (white / light grey) | `_color` — the exact batch colour, identical to the Face |
| Base bottom edge (3 px) | fixed `BASE_EDGE` light blue-grey | `_color.darkened(0.32)` — thin same-hue depth edge, same shade rule as the Face rim |
| Constants | `BASE_COLOR`, `BASE_EDGE` | both removed (unused) |

No per-colour table, no texture, no new node. Header comments updated.

## Requirement → proof (`tests/m28_c002_c004_tile_visual.gd`, new case `c17_base_body_equals_face_colour`)

| Required test (prompt) | Proof |
|---|---|
| 1 all C01..C16: face bg == base bg == canonical palette colour, exact | loop over 16 palette ids: `fb.bg_color == want`, `bb.bg_color == want`, `bb.bg_color == fb.bg_color` (`Color ==`, not approximate) |
| 2 white / light-grey base fill gone | no occupied base equals the old `(0.93,0.95,0.98)` fill; darker edge asserted to be `want.darkened(0.32)`, width 3 |
| 3 EMPTY unchanged | `set_empty()`: base + face hidden, no count (also `c06`) |
| 4 count centring exact | `c07`–`c10` unchanged and passing; `c17` production slots re-checked with `_centred` |
| 5 base geometry / height unchanged | visible base strip = `round(90×0.17)` = 15 px, face h = 75, `BASE_FRACTION == 0.17` |
| 6 shadow present | size 4, alpha 0.34, offset (0,3), black (V01 values) |
| 7 highlight present | visible, alpha 0.16 (ACTIVE 0.24) |
| 8 ACTIVE / WAITING / preview unchanged | ACTIVE glow + highlight 0.24, base still batch colour; preview shadow 2, base batch colour |
| 9 slot spawn anchors unchanged | `c12_spawn_anchor_pinned` (pre-C004 pinned values, 10 configs) PASS |
| 10 supply hitboxes / input unchanged | `c13`, `m29_input_gate_evidence` PASS |
| Production path | 6 real slots (5/6 capacity) + 15 supply tiles (front & preview): base == face == tile colour (21 tiles) |
| Mutation check | restoring the fixed white base fill makes 5 assertions FAIL (`c17` ×5); reverted |

## Untouched (byte-for-byte)

`BASE_FRACTION`, tile / face geometry, `_style` shadow / highlight / glow code, count label + `_fit_text`, `batch_slot_view.gd`, `batch_supply_panel.gd`, `five_slot_strip.gd`. Rendered layout / ink deltas in `evidence/v02/measurements.txt` are identical to the V01 measurements.
