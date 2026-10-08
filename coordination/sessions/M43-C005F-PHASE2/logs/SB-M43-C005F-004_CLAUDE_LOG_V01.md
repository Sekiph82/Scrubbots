# SB-M43-C005F-004 — Results reward-row feedback by committed reward kind — CLAUDE_LOG_V01

- Milestone: M43-C005F-PHASE2 (child 2 of 3)
- Start SHA: `a6842fd274665a871d9921052768d3dd9a67e0e3`
- Final SHA: the Phase 2 implementation commit (see master log)
- Child state: **TECHNICALLY COMPLETE — AWAITING GPT AUDIT + OWNER VISUAL REVIEW**

## Exact files changed

- `scripts/ui/results_screen.gd`:
  - `_on_reveal_step` hooks the existing `RevealSequencer.step_started`;
  - `_row_key`, `_consume_rows_static`, `ROW_FEEL_MAX = 6`, `ROW_SETTLE = 0.04`.
- `scripts/ui/feel/feedback_adapter.gd`: the shared placement change (see the F003 log).
- Tests: `tests/m43_c005f_phase2_results_pack_feel.gd` (r01–r05).

## Authority seam

The existing ordered row reveal is reused unchanged. `reward_rows(receipt)`, `receipt.reveal_queue`, the row order, amounts, text, the RevealSequencer steps, Continue/Home and Reduced immediate rows are all untouched. The feel hook only listens to `step_started` of the current reveal key.

## Event-key / idempotency contract

- One event per committed row, keyed `<identity>:row<index>:<kind>` (for example `results:WON:a1:L10:row2:bot_parts`). It fires when that row's reveal step starts, i.e. when the row becomes visible.
- The momentum step and rows beyond `ROW_FEEL_MAX` (6) get none, so a long list is bounded (r04: 9 rows → 6 events).
- A re-show rebuilds rows and replays the native fade under a new presentation key, but the feel keys are consumed, so there is no replay (r02).
- REDUCED shows every row immediately and consumes the row keys statically (zero plugin work). A later FULL re-show of the same terminal can therefore never play them (w06).

## FULL / REDUCED behaviour

- **FULL:**
  - adapter REWARD (8-particle `pickup`, ≤0.7 s) at the row centre;
  - a tiny native settle, scale 0.96 → 1.0 over the row's own 0.16 s fade (pivot centre, ends at exactly 1);
  - no GFF on Controls.
- **REDUCED:** rows are visible in the same call with no sequence, no plugin call and no motion. The amount text is never hidden or delayed.

## Tests

| Case | What it checks |
|---|---|
| r01 | row texts and kinds identical to the adapter-less native Results; committed order `first_clear_sb, win_streak_sb, bot_parts, gift_meter, gift_milestone`; one REWARD per row with exact keys in reveal order; pickup at each row centre; rows end at scale 1 and alpha 1 |
| r02 | full re-show: still 5 row events |
| r03 | Reduced: rows immediate, 5 keys consumed, zero plugin calls, nothing owned |
| r04 | 9 committed rows → 6 events, owned work bounded |
| r05 | static: the feel functions contain no `grant(`, `request_save`, `economy`, `.commit(`, `claim`, nav, `go(`, barrier write, latch write or `.disabled =` |

Result: **PASS**.

## Runtime evidence

`evidence/results_won_full_*_celebration.png` (small cyan pickups at the revealed rows) and the REDUCED captures.

## Blockers / deviations

**Owner-tuning item:** Spark's `pickup` preset (light cyan) has low contrast on the cream rows, so it reads as a subtle sparkle. The preset is a Phase 1 audited mapping (REWARD → pickup) and was not changed here. The owner visual review may ask for a different preset or colour in a follow-up.
