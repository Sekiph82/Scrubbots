# M52-C001-R02 — OWNER SPOT CHECK V01

Date: 2026-09-27
Prerequisite: R02 independent audit = AUDITED_PASS
Scope: one final slot-lifecycle check only.

## You do NOT need to replay Levels 2–10 again

You already owner-passed:
- parallel same-color lanes;
- departure-time countdown;
- 2x purchase and speed behavior;
- stutter;
- Levels 2–10;
- progression through the pack.

R02 changed only the final zero-count physical-slot lifecycle plus the internal accounting needed to make that safe.

## Test

Run the real project with F5 and enter any current production level.

Watch one occupied batch as it approaches its last waiting Scrubby.

### PASS condition A — zero means EMPTY immediately

When the final waiting Scrubby leaves the slot:

- the batch count reaches zero;
- the physical slot tile must become **EMPTY immediately**;
- it must become EMPTY while that last Scrubby is still visibly travelling toward its target;
- do not wait for the target pixel to be cleaned.

There should be no visible `0 ACTIVE` / `0 WAITING` occupied tile lingering while the robot travels.

### PASS condition B — immediate reuse

While that old final Scrubby is still travelling:

1. click a legal next supply-front batch;
2. if the just-released slot is the current rightmost EMPTY slot, the new batch should enter it immediately;
3. the old Scrubby may continue travelling and clean its old target;
4. the new replacement batch must remain unchanged by that old clear.

You are checking the feel:
`last Scrubby leaves → slot disappears/empties → next batch can use it immediately`.

## Reply

Send only:

```text
R02 zero-count slot disappears immediately: PASS / NOT PASS - note
R02 released slot reusable before old Scrubby clears: PASS / NOT PASS - note
R02 old Scrubby does not disturb replacement batch: PASS / NOT PASS - note
Overall: PASS / NOT PASS
```

Screenshots/video are only needed if something looks wrong.
