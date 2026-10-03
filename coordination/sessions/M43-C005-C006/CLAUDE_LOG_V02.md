# M43-C005-C006 — CLAUDE LOG V02 — Standard Card Pack Interactive Opening Remediation

Date: 2026-10-04
Implementer: Claude (Opus 5.5)
Canonical task: SB-M43-064
Status: **AWAITING_AUDIT** (E1/E2 evidence only; no verdict claimed) · owner visual gate remains open

## Inputs read

- V02 prompt: https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M43-C005-C006/CHATGPT_PROMPT_V02.md
- V02 criteria: https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M43-C005-C006/CHATGPT_AUDIT_CRITERIA_V02.md
- V01 prompt: https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M43-C005-C006/CHATGPT_PROMPT_V01.md
- V01 independent audit: https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M43-C005-C006/CHATGPT_AUDIT_V01.md (technical PASS; owner then rejected the composition)
- `STANDARD_PACK_PRODUCTION_MATRIX_V01.md`; SB-M43-063 audit https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M43-C005-C005/CHATGPT_AUDIT_V01.md
- `CLAUDE.md`, root `TASKS.md` (read only, **not edited**), `coordination/AUDIT_POLICY.md`, `coordination/README.md`
- current ceremony, `reveal_sequencer.gd`, `base_popup.gd`, `modal_stack.gd`; existing destination art `assets/ui/final/home/shortcuts/icon_shortcut_collection.png`, `icon_shortcut_cards_exchange.png`

Learnings applied: direct observability (taps are real GUI input events; every state asserted on its own property), sensitivity (7 source mutations, each must fail the suite), "file existence ≠ evidence" (rendering-driver captures of each state), headless timing ≠ visual evidence (order proven from bound-frame/route logs, visuals from the rendering run).

## Sync (first action)

- `git fetch origin` → local `main` 0 ahead / 6 behind `origin/main` (4da6967 → 5881a68: V01 audit, owner rejection, V02 prompt/criteria).
- `git merge --ff-only origin/main` — clean fast-forward; no conflicting paths.
- Owner/local work preserved and **not committed**: `M project.godot`, untracked `.mcp.json`, `addons/`, `*.import`, `*.uid`, owner level/reference files.

## 1. Changes

| File | Change |
|---|---|
| `scripts/ui/ceremony/standard_pack_ceremony.gd` | Rewritten as the owner two-tap state machine IDLE → OPENING → AWAIT_ROUTE → ROUTING → COMPLETE (details in matrix §1). Still `extends BasePopup` on the ModalStack, still one `RevealSequencer` (keys `<id>:open` / `<id>:route`, one-shot). Cream frame hidden; full-screen dark stage in the popup safe area. Pack = one `PackFrame` TextureRect re-bound 01→09. Cards are an inner `CardView` Control (canonical card image as-is + NEW/DUPLICATE badge + name + rarity chip + post-commit count) posed by two presentation properties `emerge` (pack mouth → row slot) and `route` (slot → destination). Destinations reuse the approved Home shortcut icons, upper-left/right, text-labelled. Continue removed; completion closes the popup (`"complete"`) after the 3rd arrival. |
| `scripts/ui/ui_text.gd` | `PACK_TAP_OPEN`, `PACK_TAP_COLLECT` added; now-unused `PACK_CONTINUE`, `PACK_COMMITTED_NOTE` removed. Destination labels reuse `HOME_SC_COLLECTION` / `HOME_SC_CARDS_EXCHANGE`. |
| `tests/m43_c005_c006_standard_pack_presentation.gd` | Rewritten V02 focused suite, 19 cases (V01 hash/model/catalog/rarity/NEW-DUP/guard cases kept; 12 new flow cases). Real taps via `SubViewport.push_input`. Every sampling loop capped (a regression fails, never hangs). Static guard extended with Cards Exchange identifiers. |
| `tests/tools/standard_pack_snapshot.gd` | Rewritten V02 rendering-driver evidence tool: real taps, state-predicate captures, auto-advance rejection, layout checks, evidence-only timeline. |
| `coordination/sessions/M43-C005-C006/STANDARD_PACK_PRODUCTION_MATRIX_V02.md` | V02 matrix |
| `coordination/sessions/M43-C005-C006/evidence/v02/*.png` | 21 runtime captures |

Unchanged (V01 audited): promoted frames, `standard_pack_model.gd`, `collection_card_catalog.gd` + catalog JSON, fixtures, `RevealSequencer`, BasePopup/ModalStack. V01 evidence PNGs under `evidence/` are left as V01 history.

Design decisions to flag for the owner/auditor:
- Destinations use the existing approved Home shortcut icons (no new art generated); "CARDS EXCHANGE" wording follows the existing UiText key.
- Taps during an animation are ignored (prompt: "ignore/reject extra taps"); there is no skip/fast-forward tap in V02.
- Completion closes the popup itself; callers observe `presentation_completed(id)` / `closed("complete")`.

## 2. Both interaction gates (observable)

- Gate 1: `IDLE` only advances on `tap()` from a real pointer press on the ceremony layer. Proven: v02 (150 untouched frames stay IDLE, nothing bound, no tween), v03 (real tap → OPENING, extra taps refused, one `:open` run), Reduced v12; mutation M2 (deferred auto-start) fails v01/v02/v11.
- Gate 2: `AWAIT_ROUTE` only advances on a second real tap. Proven: v06 (150 untouched frames, no route, cards at slots), v12 Reduced; mutation M3 (auto-resolve) fails v04 and more.
- Evidence tool waits 20 frames at IDLE and AWAIT_ROUTE before tapping and REJECTS any auto-advance; tool stdout records `taps=2` per full flow; shots `01_pack_idle` / `06_mixed_pre_route` / `R1` / `R3` are taken before the respective tap.

## 3. Validation (Godot 4.7.2.stable)

| # | Command | Expected / failure condition | Actual |
|---|---|---|---|
| V1 | `godot --headless --path . -s res://tests/m43_c005_c006_standard_pack_presentation.gd` | 19/19, 0 fail | **PASS 19/19, 0 fail** |
| V2 | source mutations of `standard_pack_ceremony.gd` (temporary; backup restored; `diff -q` RESTORED after each batch) | each must fail V1 | M1 wrong destination (NEW↔DUP swapped) → 4 FAIL (v07, v08, c13); M2 auto-start (`opened.connect(tap, CONNECT_DEFERRED)`) → 7 FAIL (v01, v02, v11); M3 auto-resolve (`tap.call_deferred()` on AWAIT) → FAIL (v04 + downstream); M4 stale pack (no fade-out, stage kept visible) → 2 FAIL (v04); M5 frames 03/04 swapped → 2 FAIL (c01, v03); M6 Reduced plays 01..08 → 1 FAIL (v12); M7 Tap 1 not one-shot → 45 FAIL (v03 …). **All 7 detected.** |
| V3 | `godot --path . -s res://tests/tools/standard_pack_snapshot.gd -- coordination/sessions/M43-C005-C006/evidence/v02` (rendering driver) | all states reached, 0 REJECTED (auto-advance, safe area, text width, card/destination overlap, pack visible with destinations) | **0 REJECTED**, 21 PNGs; mixed flow `frames [1..9]`, routes `[[0,collection],[1,exchange],[2,collection]]`, arrivals `[0,1,2]`, closed `complete`, taps 2; Reduced `frames [9]`, same routes, taps 2 |
| V4 | `-s res://tests/m43_c005_c005_reward_reveal_sequencer.gd` | PASS | **12/12** |
| V5 | M43 `c001a`, `c001b`, `c001r_c001`, `c002_c001`, `c003_c001`, `c004_c001`, `c005_c001` | PASS each | **11/11, 11/11, 40/40, 23/23, 34/34, 40/40, 17/17** |
| V6 | M39/M54 Collection/CardPack/economy: `m39a_economy_core`, `m39d_daily_collection`, `m39e_full_matrix`, `m39_v02_atomicity`, `m39_v03_full_surface`, `m54_collection_set_master_exactly_once` | PASS each | **all PASS**, 0 script errors |
| V7 | root `-s res://tests/run_tests.gd` | ALL PASS | **5,323 checks, ALL PASS**, 0 script errors |
| V8 | `git diff --check` | clean | **clean** |

Warnings: no `SCRIPT ERROR` in final runs. Focused-suite exit line `19 resources still in use` = the one AppState built in v09 (economy-service RefCounted graph; same pre-existing pattern as every AppState-using suite).

Failures found and fixed during the cycle:
1. Evidence: "CARDS EXCHANGE" label ran to the screen edge at 1080 wide; the layout check measured the rect, not the text → destination box 220 px, label = box width, font 24, and the tool now rejects text wider than its label.
2. Evidence tool read the popup after the ModalStack freed it → completion captured from the `closed` signal.
3. Tests: v07 read card views after free; v11 tween baseline stale → fixed (targets captured before Tap 2; local baseline).
4. Mutation M2 as first written (`opened.connect(tap)`) was inert — `opened` fires before the popup becomes top, so `tap()` refused it; re-run as a deferred auto-start, which the suite catches.
5. Mutation M7 initially hung the suite in an uncapped `while OPENING` loop (killed after ~20 min, source restored) → all sampling loops capped at 900 frames; M7 re-run fails cleanly with 45 FAIL.

## 4. Visual self-check (not an approval)

Inspected `01`, `03`, `05`, `07`, `V_destinations_1536x2048`, timeline: pack alone and centred at idle; single animated beat; cards rise from the pack mouth on frame 09; pack absent in the hold; Collection upper-left / Cards Exchange upper-right with text labels; NEW card mid-flight to Collection, DUPLICATE to Cards Exchange; no clipping at the five viewports. Frames 05/07/09 keep their accepted near-black ground; on the 0.92 black scrim it is barely distinguishable.

## 5. Scope / blockers / assumptions

- Not started: SB-M43-065 Premium, SB-M43-066 commit wiring (nothing opens this ceremony in the game yet), SB-M43-067, Card Exchange / Collection mutation, plugin work. Root `TASKS.md` untouched; no audit file created.
- Assumption: reusing the Home shortcut Collection / Cards Exchange icons as destination indicators is acceptable (no dedicated destination art exists; none generated).
- Assumption: the "CARDS EXCHANGE" label follows the existing UiText key (prompt text says "Card Exchange").
- Caller supplies `reduced` (AppState binding comes with SB-M43-066).
- Blockers: none. SB-M43-064 stays open pending owner visual PASS of V02.

## 6. Commit / push

See handoff response for the final SHA.

`AWAITING_GPT_M43_C005_C006_V02_STANDARD_PACK_REMEDIATION_AUDIT`
