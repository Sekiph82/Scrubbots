# OWNER INPUT — LEVEL 004 ORANGE CAT SUPPLY/BATCH CANDIDATE V01

Date: 2026-09-26
Repository: Sekiph82/Scrubbots
Scope: M52-C001 / Level 004 Orange Cat
Status: OWNER-SPECIFIED CANDIDATE / SOLVER VERIFICATION REQUIRED

## Purpose

Use this exact supply/batch layout as the **first candidate** for Level 004 Orange Cat.

The candidate was constructed from the actual 32x32 Level 004 source grid with a hard maximum of 30 Scrubbots per batch.

The ordering was generated with a conservative geometry-peeling simulation:
- only currently exterior/perimeter-reachable cells are eligible;
- clearing a cell may expose deeper cells;
- within a selected color, the simulation follows the current bottom-most, then left-most target priority;
- a batch is admitted only when its full quota can be consumed before the next intended selection.

This file does **not** claim canonical Godot solver proof yet. Claude must later verify it with the repository's real `ProofState` / `SolvabilitySolver` semantics before production admission.

## Source level

- Level: 4
- ID: `level_004_orange_cat`
- Difficulty: `EASY`
- Source: `assets/art/levels/source/easy/level_004_orange_cat_32x32.png`
- Source Git blob SHA: `47ab59b343306fdddf51a40fe94d3490d39f9a2b`
- Source SHA-256: `0b8cbc068d1d070cc5c68ee439ccb908a09cc99180f6a068ba4475339f41c926`
- Dimensions: 32x32
- Total logical cells / Scrubbots: 1024
- Baseline slot capacity: 5
- Supply columns: 3
- Visible rows per column: 3
- Hidden FIFO depth: unrestricted by visible depth
- Max robots per batch: **30**

## Canonical color totals

| Color | Hex | Pixels |
|---|---|---:|
| C08 | #2450A4 | 639 |
| C02 | #FFA800 | 167 |
| C16 | #000000 | 130 |
| C12 | #FFF8B8 | 68 |
| C11 | #9C6926 | 13 |
| C13 | #D4D7D9 | 5 |
| C04 | #00CC78 | 2 |
| **TOTAL** |  | **1024** |

All 1024 source pixels are opaque canonical ScrubBots colors.

## Batch partition

This candidate uses the minimum possible number of batches under the hard `<= 30` rule:

- C08: 30 x 21, then 9
- C02: 30 x 5, then 17
- C16: 30 x 4, then 10
- C12: 30,30,8
- C11: 13
- C13: 5
- C04: 2

Total batches: **39**

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

18 C16-30
19 C08-30
20 C16-30

21 C02-30
22 C02-30
23 C02-30
24 C08-30
25 C02-30
26 C12-30
27 C16-30
28 C08-30
29 C02-30
30 C12-30
31 C16-30
32 C08-30

33 C02-17
34 C11-13
35 C16-10
36 C08-9
37 C12-8
38 C13-5
39 C04-2
```

## Exact 3-column FIFO layout

The intended global schedule is encoded round-robin across the three FIFO columns.

### Column 1 — 13 batches

```text
01 C08-30
02 C08-30
03 C08-30
04 C08-30
05 C08-30
06 C08-30
07 C08-30
08 C02-30
09 C02-30
10 C08-30
11 C16-30
12 C11-13
13 C12-8
```

### Column 2 — 13 batches

```text
01 C08-30
02 C08-30
03 C08-30
04 C08-30
05 C08-30
06 C08-30
07 C16-30
08 C02-30
09 C12-30
10 C02-30
11 C08-30
12 C16-10
13 C13-5
```

### Column 3 — 13 batches

```text
01 C08-30
02 C08-30
03 C08-30
04 C08-30
05 C08-30
06 C16-30
07 C02-30
08 C08-30
09 C16-30
10 C12-30
11 C02-17
12 C08-9
13 C04-2
```

## Intended column-click sequence

Because the global schedule is distributed round-robin, the intended player selection sequence is:

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
1,2,3,
1,2,3
```

Total selections: **39**.

## Construction rationale

The Orange Cat board is dominated by C08 background, but the cat creates enclosed pockets that prevent a naive "all C08 first" schedule from completing.

The conservative geometry-peeling simulation found this order:

1. Seventeen C08-30 batches can clear first.
2. C16 then opens enough internal structure for another C08 batch.
3. Another C16 batch exposes the orange body.
4. C02 can then be consumed in large batches while interleaving C08/C12/C16 where required to keep corridors opening.
5. The final residual batches close the board: C02-17, C11-13, C16-10, C08-9, C12-8, C13-5 and C04-2.

Every listed batch completed its full quota in the conservative geometry-peeling simulation before the next intended selection.

No batch exceeds 30. Per-color and grand-total conservation are exact.

Canonical Godot solver verification is still mandatory because only the real repository gameplay stack can declare the candidate production-solvable.

## Claude implementation requirements

For Level 004 only:

1. Add a deterministic supply/batch representation capable of reproducing the exact three FIFO queues above.
2. Do not regenerate or repartition these Level 004 batches before first testing this owner candidate.
3. Preserve exactly 3 visible supply rows while retaining every hidden FIFO row.
4. Solver/runtime must consume the full queues, not only visible rows.
5. Enforce:
   - every batch count > 0;
   - every batch count <= 30;
   - exact per-color conservation;
   - grand total = 1024.
6. Run the exact candidate through canonical `ProofState` / `SolvabilitySolver`.
7. If `SOLVED`, replay the trace and record status, visited states, decisions, trace hash and replay result.
8. If DEADLOCK or UNKNOWN_BOUND, report the exact blocker before altering this owner candidate.
9. Do not weaken FIFO, five-slot, targeting, Railroad, access or routing semantics.
10. Do not silently substitute a generated seed layout for this first test.

## Acceptance

This Level 004 plan may become production-canonical only after:
- conservation PASS;
- hidden FIFO preservation PASS;
- canonical solver `SOLVED`;
- replay PASS;
- owner/ChatGPT audit acceptance.
