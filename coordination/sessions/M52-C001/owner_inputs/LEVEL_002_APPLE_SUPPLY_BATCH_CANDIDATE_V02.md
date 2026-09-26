# OWNER INPUT — LEVEL 002 APPLE SUPPLY/BATCH CANDIDATE V02

Date: 2026-09-26
Repository: Sekiph82/Scrubbots
Scope: M52-C001 / Level 002 Apple
Status: OWNER-SPECIFIED CORRECTED CANDIDATE / SOLVER VERIFICATION REQUIRED
Supersedes: `LEVEL_002_APPLE_SUPPLY_BATCH_CANDIDATE_V01.md`

## Correction reason

V01 used incorrect pixel/color totals for the committed Apple PNG.

The committed source `assets/art/levels/source/easy/level_002_apple_32x32.png` was re-read exactly. The correct source contains **no C16 black pixels**. Its dark outline/stem pixels are C11 Brown.

V02 is the only valid Level 002 owner batch candidate.

## Source level

- Level: 2
- ID: `level_002_apple`
- Difficulty: `EASY`
- Source: `assets/art/levels/source/easy/level_002_apple_32x32.png`
- Source Git blob SHA: `f696d8b1e17712098e860945785d4a00c79139c0`
- Source SHA-256: `b1dd3b414738cf0557cf9baabb5d3a12208df3c3a57d3ab3184e990df1dcf580`
- Dimensions: 32x32
- Total logical cells / Scrubbots: 1024
- Baseline slot capacity: 5
- Supply columns: 3
- Visible rows per column: 3
- Hidden FIFO depth: unrestricted by visible depth
- Max robots per batch: **30**

## Correct canonical color totals

| Color | Hex | Pixels |
|---|---|---:|
| C08 | #2450A4 | 639 |
| C01 | #FF4500 | 296 |
| C11 | #9C6926 | 56 |
| C04 | #00CC78 | 23 |
| C12 | #FFF8B8 | 10 |
| **TOTAL** |  | **1024** |

Important:

- C16 = **0** and MUST NOT appear in the Level 002 supply plan.
- All 1024 source pixels are opaque canonical ScrubBots colors.

## Batch partition

This candidate uses the minimum possible number of batches under the hard `<= 30` rule:

- C08: 30 x 21, then 9
- C01: 30 x 9, then 26
- C11: 30,26
- C04: 23
- C12: 10

Total batches: **36**

## Intended global player selection sequence

```text
01 C08-30
02 C08-30
03 C08-30
04 C08-30
05 C08-30
06 C08-30
07 C08-30
08 C08-30
09 C08-30
10 C08-30
11 C08-30
12 C08-30
13 C08-30
14 C08-30
15 C08-30
16 C08-30
17 C08-30
18 C08-30
19 C08-30
20 C08-30
21 C08-30
22 C08-9

23 C01-30
24 C01-30
25 C01-30
26 C01-30
27 C01-30
28 C01-30
29 C01-30
30 C01-30
31 C01-30
32 C01-26

33 C11-30
34 C11-26
35 C04-23
36 C12-10
```

## Exact 3-column FIFO layout

The global schedule is encoded round-robin across three FIFO columns.

### Column 1 — 12 batches

```text
01 C08-30
02 C08-30
03 C08-30
04 C08-30
05 C08-30
06 C08-30
07 C08-30
08 C08-9
09 C01-30
10 C01-30
11 C01-30
12 C11-26
```

### Column 2 — 12 batches

```text
01 C08-30
02 C08-30
03 C08-30
04 C08-30
05 C08-30
06 C08-30
07 C08-30
08 C01-30
09 C01-30
10 C01-30
11 C01-26
12 C04-23
```

### Column 3 — 12 batches

```text
01 C08-30
02 C08-30
03 C08-30
04 C08-30
05 C08-30
06 C08-30
07 C08-30
08 C01-30
09 C01-30
10 C01-30
11 C11-30
12 C12-10
```

## Intended column-click sequence

```text
1,2,3,
1,2,3,
1,2,3,
1,2,3,
1,2,3,
1,2,3,
1,2,3,
1,2,3,
1,2,3,
1,2,3,
1,2,3,
1,2,3
```

Total selections: **36**.

## Construction rationale

Using the corrected committed PNG, the conservative geometry-peeling simulation fully cleared this exact schedule:

1. All 639 C08 background cells are exterior-reachable and clear first as 21 x C08-30 + C08-9.
2. The opened background exposes the full C01 apple body, which clears as 9 x C01-30 + C01-26.
3. The remaining brown outline/stem clears as C11-30 + C11-26.
4. C04-23 clears the green detail.
5. C12-10 clears the final highlight cells.

The conservative simulation ends with:
- ACTIVE cells = 0;
- exact per-color conservation;
- exact grand total = 1024;
- no batch > 30.

Canonical Godot solver verification remains mandatory. This geometry-peeling result is not a substitute for `SolvabilitySolver`.

## Claude implementation requirements

For Level 002 only:

1. Ignore/supersede V01 completely.
2. Use this V02 exact three-column FIFO layout as the first candidate.
3. Do not create any C16 batch for Level 002.
4. Map owner Cxx values to the exact LevelData local palette integer IDs.
5. Preserve exactly 3 visible rows while retaining all 12 batches in each hidden FIFO column.
6. Verify every batch is 1..30.
7. Verify exact color totals: C08=639, C01=296, C11=56, C04=23, C12=10.
8. Verify grand total = 1024.
9. Run the full V02 queue through canonical `ProofState` / `SolvabilitySolver`.
10. Replay the canonical solver trace if SOLVED.
11. Independently replay the exact intended click sequence above.
12. If solver status is not SOLVED, or exact intended replay fails, stop and report the precise blocker before changing this owner candidate.
13. Do not weaken FIFO, five-slot, targetability, Railroad, routing or clearing semantics.
14. Ensure shipping `ProductionGameplayHost` for Level 002 starts with the exact accepted V02 queues, not V01 and not a random generated candidate.

## Acceptance

Level 002 V02 may become production-canonical only after:

- exact PNG/color totals PASS;
- C16 absence PASS;
- Cxx -> local palette mapping PASS;
- conservation PASS;
- hidden FIFO preservation PASS;
- canonical solver SOLVED;
- solver trace replay PASS;
- exact owner click-sequence replay PASS;
- production runtime queue identity PASS;
- owner/ChatGPT audit acceptance.
