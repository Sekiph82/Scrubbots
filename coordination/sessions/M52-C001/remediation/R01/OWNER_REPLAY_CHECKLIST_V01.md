# M52-C001-R01 — OWNER REPLAY CHECKLIST V01

Date: 2026-09-27
Prerequisite: `CHATGPT_AUDIT_V01.md` = AUDITED_PASS
Gate: owner interactive runtime acceptance

## Phase A — Level 2 feel gate first

You are already at Level 2 Apple. Do not reset the save unless needed.

Run the real project with F5.

### A1. Five-lane same-color behavior

At the start of Apple, place the first five batches using:

`1,2,3,1,2`

where:
- 1 = left column
- 2 = middle
- 3 = right

These first five owner-plan batches are the same C08/BLUE family used by the R01 acceptance fixture.

Check the **behavior**, not an exact screenshot number, because the live scheduler begins working while you are still clicking.

PASS if:
- Scrubbys begin leaving from multiple occupied slots;
- later BLUE slots do **not** wait for the oldest BLUE batch to finish;
- within a very short moment all five occupied lanes can have work in flight;
- the result visually feels concurrent/simultaneous to you.

Engineering detail: the five claims are intentionally budgeted across approximately five rendered frames instead of one heavy CPU frame. If that stagger is visibly annoying, mark NOT PASS.

### A2. Slot counter timing

Watch one or more slot counts closely.

PASS if:
- the number drops when a Scrubby leaves/dispatches from that batch;
- it does not wait until that Scrubby reaches and cleans its target pixel;
- counters do not jump backward or double-decrement during ordinary play.

### A3. 2x button

At 1x with no current manual entitlement:

1. press 2x;
2. a plain functional purchase popup should open;
3. verify it contains:
   - This level — 200 SB
   - 15 minutes — 300 SB
   - 30 minutes — 500 SB
   - 60 minutes — 750 SB
   - Cancel

First press Cancel:
- no SB should be spent;
- speed remains 1x.

Then open it again and buy **This level — 200 SB** if you are comfortable spending 200 SB in this debug save.

PASS if:
- 200 SB is deducted once;
- popup closes;
- button becomes 2x;
- Scrubby travel/dispatch is visibly faster.

Then:
- press 2x again -> 1x;
- press again -> 2x without another purchase popup.

That proves the current-level entitlement is active.

If you do not want to alter this save, back up `user://scrubbots_save.dat` before purchasing.

### A4. Stutter

Play Apple normally for at least the complete owner sequence:

`1,2,3` x 12

Judge the exact issue you reported before R01.

PASS if:
- the previous short freezes/hitches are gone to your eye;
- there is no obvious new freeze when several lanes dispatch together;
- input still feels responsive.

A tiny animation variation is not a failure. A perceptible gameplay freeze/stall is.

### A5. Apple completion

Apple must still:
- clear fully;
- reach WON;
- Continue to Level 3 Palm Tree.

If any A1–A5 item fails, stop here and send the failure. Do not spend time replaying Levels 3–10 yet.

## Phase B — Levels 3–10

Only after Level 2 passes.

Use the same owner sequences:

| Level | Artwork | Sequence |
|---:|---|---|
| 3 | Palm Tree | `1,2,3` x 17 |
| 4 | Orange Cat | `1,2,3` x 13 |
| 5 | Party Toucan | `1,2,3` x 13, then `1,2` |
| 6 | Chicken | `1,2,3` x 13, then `1` |
| 7 | Pigeon | `1,2,3` x 13 |
| 8 | Butterfly | `1,2,3` x 12, then `1` |
| 9 | Frog | `1,2,3` x 12, then `1,2` |
| 10 | Ice Cube | `1,2,3` x 13, then `1` |

For each:
- correct artwork;
- no wrong-level fallback;
- queue advances correctly;
- parallel lanes feel healthy;
- no visible freezes;
- board reaches WON;
- Continue opens the next level exactly once.

## Phase C — frontier 11

After Level 10:
- progression reaches 11;
- Home shows `CONTINUE · LEVEL 11`;
- PLAY is disabled;
- honest coming-soon state;
- no Level 10 replay;
- no Hazard Bot fallback.

## Reply format

```text
R01 Level 2 parallel lanes: PASS / NOT PASS - note
R01 Level 2 counter timing: PASS / NOT PASS - note
R01 Level 2 2x popup: PASS / NOT PASS - note
R01 Level 2 2x speed feel: PASS / NOT PASS - note
R01 Level 2 stutter: PASS / NOT PASS - note
L2 Apple completion: PASS / NOT PASS - note

L3 Palm Tree: PASS / NOT PASS - note
L4 Orange Cat: PASS / NOT PASS - note
L5 Party Toucan: PASS / NOT PASS - note
L6 Chicken: PASS / NOT PASS - note
L7 Pigeon: PASS / NOT PASS - note
L8 Butterfly: PASS / NOT PASS - note
L9 Frog: PASS / NOT PASS - note
L10 Ice Cube: PASS / NOT PASS - note

Level 10 -> Level 11: PASS / NOT PASS - note
Overall: PASS / NOT PASS
```
