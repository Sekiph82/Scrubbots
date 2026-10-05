# M43-C005-C009 — CLAUDE LOG V01 — First-New-Card Celebration + Duplicate Count Presentation

Date: 2026-10-05
Implementer: Claude (Opus 5.5)
Canonical task: SB-M43-067
Status: **AWAITING_AUDIT** (implementer evidence only; no verdict claimed) · OWNER VISUAL PASS required afterwards

## Inputs read

- Prompt: https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M43-C005-C009/CHATGPT_PROMPT_V01.md
- Criteria: `CHATGPT_AUDIT_CRITERIA_V01.md`; C008 `CHATGPT_AUDIT_V02.md` (SB-M43-066 PASS)
- `CLAUDE.md`, root `TASKS.md` (read only, not edited), `coordination/AUDIT_POLICY.md`
- Standard / Premium ceremony + model sources, both owner-review harnesses and their smokes, C006 / C007 suites,
  `ui_text.gd`, `card_new_glow.png` (inspected: 1024×1536 RGBA, transparent cyan/gold burst, same 2:3 aspect as
  the card, alpha 0 at the corners → technically suitable, used as is), the 135-card catalog, the C008 receipt
  truth (`is_new`, `copies_after`), the Cards Exchange protected-first-copy rule (`economy_rewards_v1.json` `protected_min_owned_copies` = 1)

## Sync

`git fetch origin main --prune` → 0 ahead / 4 behind (`bec3102` C008 V02 audit PASS, `10c967d` prompt, `5bec4d8` criteria,
`3dda957` TASKS.md). No local edits on those paths → `git merge --ff-only origin/main` to `3dda957`. Owner/local work
preserved, not staged: `M project.godot`, `M scenes/app/main.tscn`, addons, `.mcp.json`, untracked owner art /
`.import` / `.uid` files, `tests/_m55_diag_tmp.gd` (not mine).

## Pre-C009 card-state presentation (documented before changing it)

- Badge: a NEW (green) / DUPLICATE (brown) chip on the top edge of each card face (`CardView` "State").
- Count line: `You now have N` (`PACK_CARD_OWNED`, N = `copies_after`), white 22 px, under the rarity chip.
- No NEW-specific visual; `card_new_glow.png` unused.
- Standard: 3 cards in a centred row (card width min(300, (w − 88)/3), gap 24) at mid-height.
- Premium: centred 3 + 2 block, draw order 0,1,2 / 3,4, row gap 28.
- Open plan: frames 01→09, cards emerge, pack fades (0.25 s), 0.40 s hold, destinations fade in; Tap 2 routes
  NEW → Collection (upper-left), DUPLICATE → Cards Exchange (upper-right).

## 1. Changes

| File | Change |
|---|---|
| `scripts/ui/ceremony/standard_pack_ceremony.gd` | shared card-state presentation in `CardView` + one ceremony `celebration` step (Premium inherits; `premium_pack_ceremony.gd` unchanged) |
| `scripts/ui/ui_text.gd` | `PACK_CARD_OWNED` ("You now have %d") replaced by `PACK_CARD_FIRST_COPY` ("FIRST COPY") and `PACK_CARD_EXTRAS` ("EXTRAS x%d") |
| `tests/m43_c005_c009_card_state_celebration.gd` | **new** focused suite (25 cases) |
| `tests/tools/card_state_snapshot.gd` | **new** rendering-driver evidence tool |
| `tests/support/standard_pack_fixtures.gd` / `premium_pack_fixtures.gd` | new `triple` (FIRST COPY / x1 / x2), Standard + Premium `all_duplicate` |
| `tests/tools/owner_review/standard_pack_owner_review.gd` / `premium_pack_owner_review.gd` | new review keys (Standard 4 triple, 5 all duplicate; Premium 4 duplicate-heavy) |
| `tests/m43_c005_c006_owner_review_harness.gd` | ceremony pin re-pinned (`b95b9e10…` → `d44d9f1c…`, LF-normalised) with comment; keys 4 / 5 checked |
| `tests/m43_c005_c007_premium_owner_review_harness.gd` | key 4 checked |
| `tests/m43_c005_c006_standard_pack_presentation.gd`, `tests/m43_c005_c007_premium_pack_presentation.gd` | expected count line updated from "You now have N" to FIRST COPY / EXTRAS x(N−1) (one line each) |
| `M43-C005-C009/CARD_STATE_PRESENTATION_MATRIX_V01.md`, `OWNER_REVIEW_INSTRUCTIONS_V01.md`, this log, `evidence/v01/*` | evidence |

Not changed: Premium ceremony, both models, RevealSequencer, frames, card art, destination icons, `card_new_glow.png`,
C008 receipt / transaction, economy / Collection / save code, root `TASKS.md`. No GameFeelFlow / Saltmire Spark.

## 2. Implementation

**Truth.** `CardView.count_text(row)` and `CardView.extra_copies(row)` read only the committed row:
NEW (`is_new`) → **FIRST COPY**; DUPLICATE → **EXTRAS xN**, `N = copies_after − 1`
(copies 2 → x1, 3 → x2, 8 → x7). Examples from the fixtures: Standard triple FIRST COPY / x1 / x2, Premium
duplicate-heavy x2 / x1 / x5 / x3 / x10. The existing NEW / DUPLICATE badges stay. No owned-total line (kept the
layout clean; EXTRAS xN is the only count line). The model validators already guarantee NEW ⇔ copies 1 and sequential
repeats, so NEW can never read "EXTRAS x0".

**NEW celebration (FULL).** One sequencer step `celebration` (0→1) on the ceremony, appended **after the accepted
pack fade** and before the hold/destinations:
`frames 01→09 → cards emerge → pack fades (unchanged) → celebration → 0.40 s hold → destinations → Tap 2`.
Step duration = 0.40 s + (k−1)·0.10 s for k NEW cards (Standard ≤ 0.6 s, Premium ≤ 0.8 s). NEW card j (model order)
pulses inside its own window [j·0.10, j·0.10 + 0.40]: card scale `1 + 0.04·sin(π t)` (back to exactly 1.0), and its
canonical glow (1.6 × face size, centred) rises to α 1 with a 1.12 swell by t = 0.35, then settles to a static
α 0.5 halo for the hold, fading out as routing starts. Glows live in one `NewGlows` layer under every card and the
destination icons, so they never cover card art, text or destinations. `CardView.celebrated(index)` fires at most
once per instance (once-guard); layout / resize never touch `celebrate`. No loops, spin, flash, shake or particles.

Design note: the first build put the celebration before the pack fade (the order listed in prompt §7). The P4 capture
showed this kept the Premium pack art (logo) behind the row-1 labels for up to 0.8 s longer than the owner-accepted
cadence, which hurt readability. The step was moved after the unchanged pack fade, so the accepted 01→09 / emergence /
pack-out timing is byte-for-byte the same and the pulse plays on the clean stage before the hold. The 7% pop from the
first build was also reduced to 4%, because concurrent Premium pulses touched the next row (evidence tool rejection).

**Reduced Effects.** No celebration step and no pulse; NEW cards show the static α 0.5 glow from the moment they fade
in; texts identical to FULL; both taps unchanged.

## 3. Validation

All `godot --headless --path . -s res://tests/<suite>.gd` (V2 with a rendering driver); exit 0 and 0 `SCRIPT ERROR`
lines in every final run.

| # | Command / suite | Result |
|---|---|---|
| V1 | `m43_c005_c009_card_state_celebration` (new) | **PASS 25/25 cases, 0 fail** (peak pulse scale 1.040; glow peak 1.00 → rest 0.50) |
| V2 | `godot --path . -s res://tests/tools/card_state_snapshot.gd -- coordination/sessions/M43-C005-C009/evidence/v01` | **CLEAN, 0 REJECTED**; 31 captures + sheet, incl. mid-celebration frames, 5 viewports |
| V3 | mutation sensitivity (§4) | **12/12 detected**, sources restored |
| V4 | `m43_c005_c006_standard_pack_presentation` / `m43_c005_c006_owner_review_harness` | PASS 21/21 / 14/14 |
| V5 | `m43_c005_c007_premium_pack_presentation` / `m43_c005_c007_premium_owner_review_harness` | PASS 19/19 / 11/11 |
| V6 | `m43_c005_c008_pack_commit_transaction` | PASS 27/27 |
| V7 | `m43_c005_c005_reward_reveal_sequencer`, `m43_c005_c001_ceremony_visual_masters`, `m43_c002_c001_popup_modal_pause`, `m43_c003_c001_acquisition`, `m43_c004_c001_fail_need_a_hand` | PASS 12/12, 17/17, 23/23, 34/34, 40/40 |
| V8 | M39 `m39a_economy_core`, `m39d_daily_collection` (Collection / CardPack), `m39e_full_matrix`, `m39_v02_atomicity`, `m39_v03_full_surface` (Cards Exchange), `m39_v04_integration` | all PASS |
| V9 | `m54_collection_set_master_exactly_once` | PASS |
| V10 | root `run_tests.gd` | **5,323 checks, ALL PASS** |
| V11 | `git diff --check` | clean |

Exit-time "ObjectDB leaked / resources still in use" lines come from the AppState economy graphs of AppState-based
suites (k01 / k12 / k23 here), as in earlier cycles.

## 4. Mutation sensitivity

Each mutation was applied temporarily (production source, or a frame PNG for N12), the focused suite was run, and the
file was restored from a copy; `cmp` confirmed `standard_pack_ceremony.gd` and `frame_05_tear_widens.png` RESTORED
byte-identical.

| # | Mutation | Result | Detected by |
|---|---|---|---|
| N01 | extras = copies_after (off-by-one; copies 2 shows **x2**) | FAIL, 10 | k06, k07, k08, k11, k12 |
| N02 | NEW shows EXTRAS x0 | FAIL, 12 | k01, k03, k11, k12 |
| N03 | live-Collection count injected into CardView | FAIL, 1 | k24 static guard |
| N04 | resize/relayout retriggers the celebration | FAIL, 2 | k20 |
| N05 | Reduced gets the celebration + pulse | FAIL, 4 | k06 (scale 1.040 in Reduced) |
| N06 | Reduced plan gets the celebration step | FAIL, 2 | k06 |
| N07 | wrong glow asset (card_back.png) | FAIL, 1 | k04 |
| N08 | routing destination swapped | FAIL, 4 | k22 |
| N09 | unbounded pop (0.20) | FAIL, 1 | k05 absolute restraint ceiling 1.05 (first run passed because k05 compared against the code's own constant; fixed to an independent ceiling and re-run) |
| N10 | celebration before the cards settle | FAIL, 4 | k05 |
| N11 | once-guard removed (celebrates repeatedly) | FAIL, 8 | k05, k15, k16, k19 |
| N12 | Standard frame 05 bytes changed | FAIL, 1 | k26 |

**12/12 detected.** In-suite comparator sensitivity (k27): the text oracle rejects copies_after-as-extras and
NEW-as-x0.

## 5. Scope / blockers

- SB-M43-068 not started. Root `TASKS.md` untouched. No tracker created.
- Blockers: none. SB-M43-067 stays open for ChatGPT technical audit **and** explicit OWNER VISUAL PASS
  (`OWNER_REVIEW_INSTRUCTIONS_V01.md`).

## 6. Commit / push

See handoff response for the final SHA.

`AWAITING_GPT_M43_C005_C009_V01_CARD_STATE_AUDIT`
