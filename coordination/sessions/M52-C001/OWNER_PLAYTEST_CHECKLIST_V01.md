# M52-C001 — OWNER PLAYTEST CHECKLIST V01

Date: 2026-09-26
Gate: First 10 Level Pack manual functional acceptance
Audit prerequisite: `CHATGPT_AUDIT_V01.md` = AUDITED_PASS

## What you are testing

This is a **functional/content owner playtest**, not the final Gameplay V02 visual-layout approval.

Do judge:
- correct artwork/level order;
- real gameplay launches;
- three supply columns behave correctly;
- batches advance from hidden FIFO depth;
- clicks are accepted in the intended order;
- Scrubbots actually clear the artwork;
- each level reaches WON;
- Continue advances to the correct next level;
- Level 11 is honestly unavailable after Level 10.

Do **not** use this gate to reject unfinished final Gameplay V02 layout/popup polish. That later production convergence is tracked separately in M28-C002.

## Before starting

1. Sync `main` with `origin/main`.
2. Use Godot **4.7.2-stable**.
3. Run the actual project with **F5 / Run Project**. The real main scene is:
   `res://scenes/app/main.tscn`.
4. Let the normal opening flow reach Home.
5. Use the real Home PLAY/CONTINUE route. Do not launch a debug level scene.

### Save-state note

Canonical production save:
`user://scrubbots_save.dat`.

If your existing save is already at Level 1 or 2, use it.

If it is beyond Level 2 and you want a clean functional test:
- close the running game;
- use Godot's **Open User Data Folder** command;
- make a backup copy of `scrubbots_save.dat`;
- rename/remove the test copy;
- relaunch. A fresh save starts at Level 1.
- restore your backup after the test if desired.

Do not permanently delete a save you care about without backing it up.

## Level 1 spot-check

Level 1 is unchanged, so this is only a regression spot-check.

Confirm:
- Hazard Bot is still Level 1;
- it launches normally;
- its familiar old seed-1 supply behavior is intact;
- winning reaches Results;
- Continue opens **Level 2 Apple**, not Hazard Bot again.

If you begin the test already at Level 2, Level 1 does not need to be replayed again for this owner gate.

## How to use the owner sequences

For Levels 2–10:
- Column **1 = left**
- Column **2 = middle**
- Column **3 = right**
- click the next expected column only after the previous batch was visibly accepted;
- do not spam taps while all execution slots are occupied;
- if a click is temporarily unavailable/ignored, **do not advance your count**; wait and click that same expected column when legal.

The accepted owner sequences are deliberately simple rotations.

| Level | Artwork | Owner sequence |
|---:|---|---|
| 2 | Apple | `1,2,3` x 12 |
| 3 | Palm Tree | `1,2,3` x 17 |
| 4 | Orange Cat | `1,2,3` x 13 |
| 5 | Party Toucan | `1,2,3` x 13, then `1,2` |
| 6 | Chicken | `1,2,3` x 13, then `1` |
| 7 | Pigeon | `1,2,3` x 13 |
| 8 | Butterfly | `1,2,3` x 12, then `1` |
| 9 | Frog | `1,2,3` x 12, then `1,2` |
| 10 | Ice Cube | `1,2,3` x 13, then `1` |

## For every Level 2–10, check these seven things

Mark each level PASS only when all seven are true:

1. **Correct artwork**
   - Level matches the table above.
   - No wrong-level/Hazard Bot fallback.

2. **Supply presentation**
   - exactly three active FIFO columns for this pack;
   - three visible rows per column at the start while enough batches remain;
   - only the front row is the selectable batch;
   - deeper content continues feeding into the visible preview as fronts are consumed.

3. **Click response**
   - the intended sequence can be followed without an illegal permanent blocker;
   - a legal click advances only the clicked column.

4. **Slot/runtime behavior**
   - batches enter the execution slots normally;
   - Scrubbots dispatch and clear matching pixels;
   - no ghost/stuck robot remains forever after the board should progress.

5. **Completion**
   - artwork reaches fully cleared state;
   - result becomes **WON**;
   - no visible unfinished batch remains after completion.

6. **Transition**
   - Results/Continue opens the next numbered artwork exactly once.

7. **Stability**
   - no SCRIPT ERROR popup/crash/freeze;
   - no obvious queue corruption, duplicated batch, wrong color mapping or impossible leftover pixel.

## Quick owner record

You can reply to me in this compact form:

```text
L2 Apple: PASS / NOT PASS - note
L3 Palm Tree: PASS / NOT PASS - note
L4 Orange Cat: PASS / NOT PASS - note
L5 Party Toucan: PASS / NOT PASS - note
L6 Chicken: PASS / NOT PASS - note
L7 Pigeon: PASS / NOT PASS - note
L8 Butterfly: PASS / NOT PASS - note
L9 Frog: PASS / NOT PASS - note
L10 Ice Cube: PASS / NOT PASS - note

Level 10 -> Level 11 coming-soon gate: PASS / NOT PASS - note
Overall: PASS / NOT PASS
```

Screenshots are only needed if something looks wrong.

## After Level 10

After Ice Cube is won:

1. progression must advance to frontier **11**;
2. there must be **no** Level 10 replay disguised as Level 11;
3. there must be **no** Hazard Bot fallback;
4. return to Home if needed;
5. Home should show `CONTINUE · LEVEL 11`;
6. PLAY should be disabled because Level 11 content does not exist;
7. an honest **coming soon** message should be shown.

That final frontier check is part of this owner gate.

## PASS rule

Overall owner PASS requires:
- Levels 2–10 all pass the seven checks above;
- Level 11 missing-content behavior passes;
- no owner-observed blocker requires code/content remediation.

After your PASS, ChatGPT will record owner acceptance and move the First 10 block to M53 QA.
