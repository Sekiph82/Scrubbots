# M43-C001R-C001 — CLAUDE LOG V02 (owner visual remediation)

Date: 2026-10-02
Prompt: `coordination/sessions/M43-C001R-C001/CHATGPT_PROMPT_V02.md`
Criteria: `coordination/sessions/M43-C001R-C001/CHATGPT_AUDIT_CRITERIA_V02.md`
Owner decision: `coordination/sessions/M43-C001R-C001/OWNER_VISUAL_DECISION_V02.md`
Status: **AWAITING_GPT_M43_C001R_C001_V02_AUDIT**

## Sync / governance

- **Repository:** `Sekiph82/Scrubbots`, branch `main`.
- **Starting commit:** `18dd63e`, fast-forwarded from `0395d4b`.
- **Commit:** this log is in the single V02 commit; its SHA is reported in the hand-off message.
- **Owner/local work preserved, not committed:** the pre-existing `project.godot` modification and untracked caches/media.
- Root `TASKS.md` was read only and **not edited**.

**Read before implementing:**
- `CLAUDE.md` and `TASKS.md`;
- `AUDIT_POLICY.md`;
- the C001R V01 prompt and criteria;
- `CHATGPT_AUDIT_V01.md` (TECHNICAL_PASS / owner gate);
- `OWNER_VISUAL_DECISION_V02.md`.

**Unchanged (scope locks):**
- the `ResultsMomentum` authority;
- progression, catalog and cycle truth;
- the crop algorithm and fraction;
- the CLEAN NEXT wording;
- the economy, difficulty, Heart, ad and booster systems;
- no art, rewards, tappable nodes, C005 or C005R.

## Changes

| File | Change |
|---|---|
| `scripts/ui/components/journey_strip.gd` | **Size hierarchy:** `BEAT_SCALE` sets ordinary 1.0, mini-boss **1.3**, boss **1.6**; a current ordinary node is 1.12 and never outranks a beat. **Radius:** the base radius is the largest that keeps the boss inside the strip height and keeps every node inside the width with no neighbour overlap. **Layout:** node centres are inset by the boss half-width. **Labels:** level-number font scales with node size. Orange/red edges unchanged. |
| `scripts/ui/home/home_screen.gd` | `JOURNEY_SIZE` 560×58 → **720×84**. Same anchor: a child of PLAY, directly above it, taking no layout slot. |
| `scripts/ui/results_screen.gd` | Journey strip height 56 → **76** (`JOURNEY_H`). `_momentum_shows_unavailable(level)` suppresses the older `RESULTS_NEXT_UNAVAILABLE` note **only** when the momentum Next Cleanup card already shows that same unavailable frontier. Without a card (no or malformed momentum) the note still appears. |
| `tests/m43_c001a_results_foundation.gd`, `tests/m43_c001b_won_results_visual.gd` | **Deliberate migration** for owner decision 5: the L10 assertions now expect the card's "Coming soon" (Level 11) and a hidden duplicate note. Disabled-CTA and inside-frame assertions are kept. |
| `tests/m43_c001r_c001_results_momentum.gd` | +6 V02 cases (below). |
| `tests/tools/results_momentum_snapshot.gd` | Adds the Results L5 (mini-boss complete) shot. |

## Measured geometry (headless, from the focused suite)

| Item | V01 | V02 |
|---|---|---|
| Home strip | 560×58 | **720×84** |
| Home ordinary node | 39.4 px | **47.5 px** |
| Home current node | — | 53.2 px |
| Home mini-boss | 39.4 px | **61.8 px** |
| Home boss | 48 px | **76.0 px** |
| Results strip height | 56 | **76** (width 816) |
| Results ordinary node | 38 px | **42.5 px** |

## Tests

### Focused suite

`godot --headless --path . -s res://tests/m43_c001r_c001_results_momentum.gd` → **PASS, 40/40 cases, 0 fail.** These are the 34 V01 cases plus 6 V02 cases.

| Required # | Assertion | Result |
|---|---|---|
| 1 | Home strip ≥ +20% wider and ≥ +30% taller than V01; ordinary node ≥ 1.15 × V01 (45.3 px); still a child of PLAY and above it | PASS (720×84, 47.5 px) |
| 2 | Results strip height ≥ 56 and ordinary node ≥ 38 px | PASS (76, 42.5 px) |
| 3 | Mini-boss ≥ 1.25 × ordinary (complete and future), on Home and Results | PASS |
| 4 | Boss ≥ 1.15 × mini-boss on Home and Results; frontier 10 boss > mini > ordinary; current < mini | PASS |
| — | Every node inside its strip (with the rim) and no neighbour overlap, on Home f6, Home f10 and Results L9 | PASS |
| 5 | `MINI_EDGE` / `BOSS_EDGE` equal the accepted orange/red; mini < boss scale | PASS |
| 6–8 | L10: exactly one visible "coming soon" label, which is `NextFacts` in the card; the note is hidden and empty | PASS |
| 9 | CLEAN NEXT disabled (label unchanged); Home usable; `continue.reason == CONTENT_MISSING` | PASS |
| — | Scoped suppression: with the momentum removed, the original unavailable note returns | PASS |
| 10 | Available-next L4 copy unchanged: no note, "HARD · 10 colours", CLEAN NEXT live | PASS |
| 11 | Crop fraction / non-disclosure (V01 t03–t06, including the per-frame probe and its sensitivity check) | PASS |
| 12 | Five-viewport Home no-collision (V01 t33 at the new strip size) | PASS |
| 13 | Results panel and CTAs in viewport, momentum inside the panel (t33) | PASS |
| 14 | Reduced Effects parity (t32) | PASS |
| 15 | Lifecycle, 20 cycles: nodes 414 → 414 (t34) | PASS |

### Regression

Godot 4.7.2 headless, 12-way parallel, 127 top-level `tests/*.gd`. **124 exited with rc=0.**

- Root `tests/run_tests.gd`: **Total checks 5323, RESULT: ALL PASS.**
- **M42:** home, navigation, opening, assets — PASS.
  - composition 9/9, V04 18/18, V05 13/13, V06 13/13, V07 safe area 9/9;
  - Scrubby scale 7/7, animation 18/18.
- **M43:** C001A 11/11, C001B 11/11, C001R 40/40 — PASS.
- All other M30/M35–M40/M43-C002–C004/M52/M55 suites — rc=0.

**Non-zero exits, attributed:**
- `m21_v08_corridor_validation` (C/043, C/047) and `m21_v09_direct_evidence_reconciliation` (B): the same historical routing baseline as the V01, C003 and C004 logs. No routing was touched.
- `m32_c002_board_independent_size`: one timing assertion failed under 12-way parallel load ("first frame after relayout 2351.0 us (bounded)").
  - It is a pure CPU-timing bound on the gameplay Scrubbot visuals, which this cycle does not touch.
  - Re-run alone twice: **PASS 86/86 both times** (254 µs and 403 µs).
  - It passed in both V01 and C004 parallel runs, so this is load-induced noise, not a regression.

**Other checks:**
- `SCRIPT ERROR` appears only in the m20 lifecycle smoke logs (baseline).
- `git diff --check` is clean.

## Evidence

`evidence_v02/` holds 22 PNGs from `tests/tools/results_momentum_snapshot.gd` (rendering driver; real app; real WON), and none was rejected. The V01 `evidence/` set is kept for comparison. The full index and the owner questions are in `OWNER_VISUAL_REVIEW_V02.md`.

## Reproduce

```bash
godot --headless --path . -s res://tests/m43_c001r_c001_results_momentum.gd
```

```bash
godot --path . -s res://tests/tools/results_momentum_snapshot.gd -- coordination/sessions/M43-C001R-C001/evidence_v02
```

`AWAITING_GPT_M43_C001R_C001_V02_AUDIT`
