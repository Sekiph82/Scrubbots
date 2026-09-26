# OWNER INPUT — LEVEL 005 PARTY TOUCAN SUPPLY/BATCH CANDIDATE V01

Date: 2026-09-26
Repository: Sekiph82/Scrubbots
Scope: M52-C001 / Level 005 Party Toucan
Status: OWNER-SPECIFIED CANDIDATE / SOLVER VERIFICATION REQUIRED

## Purpose

Use this exact supply/batch layout as the **first candidate** for Level 005 Party Toucan.

The candidate was constructed from the actual 33x33 Level 005 source grid with a hard maximum of 30 Scrubbots per batch.

Unlike a simple color-count split, the ordering was generated with a conservative geometry-peeling simulation:
- only currently exterior/perimeter-reachable cells are eligible;
- clearing a cell may open deeper cells;
- within a selected color, the simulation follows the current bottom-most, then left-most target priority;
- a batch is admitted to this candidate only when its full quota can be consumed before moving to the next intended selection.

This file does **not** claim canonical Godot solver proof yet. Claude must later verify it with the repository's real `ProofState` / `SolvabilitySolver` semantics before production admission.

## Source level

- Level: 5
- ID: `level_005_party_toucan`
- Difficulty: `HARD`
- Source: `assets/art/levels/source/hard/level_005_party_toucan_33x33.png`
- Source Git blob SHA: `db6654ddfe764e8eeefd03df1243c602e54bf4e8`
- Source SHA-256: `c95c0fd4021bb90eacd78dbc2279809f26fe0ed435cca260881ee6961eb9874f`
- Dimensions: 33x33
- Total logical cells / Scrubbots: 1089
- Baseline slot capacity: 5
- Supply columns: 3
- Visible rows per column: 3
- Hidden FIFO depth: unrestricted by visible depth
- Max robots per batch: **30**

## Canonical color totals

| Color | Hex | Pixels |
|---|---|---:|
| C08 | #2450A4 | 611 |
| C16 | #000000 | 177 |
| C03 | #FFD635 | 106 |
| C14 | #515252 | 78 |
| C11 | #9C6926 | 52 |
| C02 | #FFA800 | 26 |
| C10 | #FF3881 | 15 |
| C06 | #51E9F4 | 9 |
| C07 | #3690EA | 8 |
| C01 | #FF4500 | 7 |
| **TOTAL** |  | **1089** |

All 1089 source pixels are opaque canonical ScrubBots colors.

## Batch partition

- C08: 30 x 20, then 11
- C16: 30 x 5, then 27
- C03: 30 x 3, then 16
- C14: 30,30,18
- C11: 30,22
- C02: 26
- C10: 15
- C06: 9
- C07: 8
- C01: 7

Total batches: **41**

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
12 C16-30
13 C08-30
14 C08-30
15 C16-30
16 C08-30
17 C08-30
18 C16-30
19 C08-30
20 C08-30
21 C08-30
22 C08-30
23 C16-30
24 C14-30
25 C16-30
26 C08-30
27 C14-30
28 C03-30
29 C03-30
30 C11-30
31 C16-27
32 C03-30
33 C02-26
34 C11-22
35 C03-16
36 C14-18
37 C08-11
38 C10-15
39 C06-9
40 C07-8
41 C01-7
```

## Exact 3-column FIFO layout

The intended global schedule is encoded round-robin across the three FIFO columns.

### Column 1 — 14 batches

```text
01 C08-30
02 C08-30
03 C08-30
04 C08-30
05 C08-30
06 C08-30
07 C08-30
08 C08-30
09 C16-30
10 C03-30
11 C16-27
12 C11-22
13 C08-11
14 C07-8
```

### Column 2 — 14 batches

```text
01 C08-30
02 C08-30
03 C08-30
04 C08-30
05 C08-30
06 C08-30
07 C08-30
08 C16-30
09 C08-30
10 C03-30
11 C03-30
12 C03-16
13 C10-15
14 C01-7
```

### Column 3 — 13 batches

```text
01 C08-30
02 C08-30
03 C08-30
04 C16-30
05 C16-30
06 C16-30
07 C08-30
08 C14-30
09 C14-30
10 C11-30
11 C02-26
12 C14-18
13 C06-9
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
1,2,3,
1,2
```

Total selections: **41**.

## Construction rationale

The Party Toucan board starts with a very large C08 exterior/background region but contains a denser internal mix than the earlier EASY levels.

The conservative geometry-peeling simulation produced this successful intended schedule:

1. Peel eleven initial C08-30 batches from the large reachable exterior.
2. Introduce C16-30 once enough black outline cells are exposed.
3. Alternate additional C08 and C16 batches as the outline opens.
4. Introduce C14 only after its reachable quota can fully consume a 30 batch.
5. Continue opening the interior with C08/C16/C14.
6. Clear the large C03 and C11 regions as they become fully serviceable by the selected quotas.
7. Finish with the exact residual batches C16-27, C02-26, C11-22, C03-16, C14-18, C08-11, C10-15, C06-9, C07-8 and C01-7.

Every listed batch completed its full quota in the conservative geometry-peeling simulation. No batch exceeds 30. Per-color and grand-total conservation are exact.

Canonical Godot solver verification is still mandatory because only the real repository gameplay stack can declare the candidate production-solvable.

## Claude implementation requirements

For Level 005 only:

1. Add a deterministic supply/batch representation capable of reproducing the exact three FIFO queues above.
2. Do not regenerate or repartition these Level 005 batches before first testing this owner candidate.
3. Preserve exactly 3 visible supply rows while retaining every hidden FIFO row.
4. Solver/runtime must consume the full queues, not only visible rows.
5. Enforce:
   - every batch count > 0;
   - every batch count <= 30;
   - exact per-color conservation;
   - grand total = 1089.
6. Run the exact candidate through canonical `ProofState` / `SolvabilitySolver`.
7. If `SOLVED`, replay the trace and record status, visited states, decisions, trace hash and replay result.
8. If DEADLOCK or UNKNOWN_BOUND, report the exact blocker before altering this owner candidate.
9. Do not weaken FIFO, five-slot, targeting, Railroad, access or routing semantics.
10. Do not silently substitute a generated seed layout for this first test.

## Acceptance

This Level 005 plan may become production-canonical only after:
- conservation PASS;
- hidden FIFO preservation PASS;
- canonical solver `SOLVED`;
- replay PASS;
- owner/ChatGPT audit acceptance.
