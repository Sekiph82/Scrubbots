# OWNER INPUT — LEVEL 003 PALM TREE SUPPLY/BATCH CANDIDATE V01

Date: 2026-09-26
Repository: Sekiph82/Scrubbots
Scope: M52-C001 / Level 003 Palm Tree
Status: OWNER-SPECIFIED CANDIDATE / SOLVER VERIFICATION REQUIRED

## Purpose

Use this exact supply/batch layout as the **first candidate** for Level 003 Palm Tree.

The candidate was constructed from the actual 38x38 Level 003 source grid with a hard maximum of 30 Scrubbots per batch.

The ordering was generated with a conservative geometry-peeling simulation:
- only currently exterior/perimeter-reachable cells are eligible;
- clearing cells can expose deeper cells;
- within a selected color, target order is bottom-most, then left-most;
- a batch is admitted only when its full quota can be consumed before the next intended selection.

This candidate was fully consumed by that conservative simulation with exact color conservation.

This file does **not** claim canonical Godot solver proof yet. Claude must later verify it with the repository's real `ProofState` / `SolvabilitySolver` semantics before production admission.

## Source level

- Level: 3
- ID: `level_003_palm_tree`
- Difficulty: `MEDIUM`
- Source: `assets/art/levels/source/medium/level_003_palm_tree_38x38.png`
- Source Git blob SHA: `096a2fef7e1f0a6dc7831715eef225022a784d78`
- Source SHA-256: `84960199759b1c3a1e130a24149c14fff9a5ee6ffb53db4ec6f138e34c6116cc`
- Dimensions: 38x38
- Total logical cells / Scrubbots: 1444
- Baseline slot capacity: 5
- Supply columns: 3
- Visible rows per column: 3
- Hidden FIFO depth: unrestricted by visible depth
- Max robots per batch: **30**

## Canonical color totals

| Color | Hex | Pixels |
|---|---|---:|
| C08 | #2450A4 | 601 |
| C04 | #00CC78 | 452 |
| C16 | #000000 | 203 |
| C05 | #00CCC0 | 88 |
| C11 | #9C6926 | 72 |
| C02 | #FFA800 | 28 |
| **TOTAL** |  | **1444** |

All 1444 source pixels are opaque canonical ScrubBots colors.

## Batch partition

This candidate uses the minimum possible number of batches under the hard `<= 30` rule:

- C08: 30 x 20, then 1
- C04: 30 x 15, then 2
- C16: 30 x 6, then 23
- C05: 30,30,28
- C11: 30,30,12
- C02: 28

Total batches: **51**

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

20 C16-30

21 C04-30
22 C04-30
23 C04-30
24 C04-30
25 C04-30
26 C04-30
27 C04-30
28 C04-30
29 C04-30
30 C04-30
31 C04-30
32 C04-30
33 C04-30
34 C04-30

35 C05-30
36 C05-30
37 C11-30

38 C08-30
39 C11-30

40 C16-30
41 C16-30
42 C16-30
43 C16-30
44 C16-30

45 C04-2
46 C02-28
47 C05-28
48 C04-30
49 C16-23
50 C11-12
51 C08-1
```

## Exact 3-column FIFO layout

The intended global schedule is encoded round-robin across the three FIFO columns.

### Column 1 — 17 batches

```text
01 C08-30
02 C08-30
03 C08-30
04 C08-30
05 C08-30
06 C08-30
07 C08-30
08 C04-30
09 C04-30
10 C04-30
11 C04-30
12 C04-30
13 C11-30
14 C16-30
15 C16-30
16 C02-28
17 C16-23
```

### Column 2 — 17 batches

```text
01 C08-30
02 C08-30
03 C08-30
04 C08-30
05 C08-30
06 C08-30
07 C16-30
08 C04-30
09 C04-30
10 C04-30
11 C04-30
12 C05-30
13 C08-30
14 C16-30
15 C16-30
16 C05-28
17 C11-12
```

### Column 3 — 17 batches

```text
01 C08-30
02 C08-30
03 C08-30
04 C08-30
05 C08-30
06 C08-30
07 C04-30
08 C04-30
09 C04-30
10 C04-30
11 C04-30
12 C05-30
13 C11-30
14 C16-30
15 C04-2
16 C04-30
17 C08-1
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
1,2,3,
1,2,3,
1,2,3,
1,2,3
```

Total selections: **51**.

## Construction rationale

The Palm Tree level has a much larger 38x38 board and two dominant regions: C08 background and C04 foliage.

The conservative geometry-peeling simulation found this exact successful sequence:

1. Nineteen C08-30 batches clear 570 reachable C08 cells.
2. C16-30 opens the internal boundary around the palm.
3. Fourteen C04-30 batches clear 420 green cells.
4. C05-30, C05-30 and C11-30 open deeper trunk/detail corridors.
5. The twentieth C08-30 and second C11-30 become fully serviceable.
6. Five further C16-30 batches open the remaining internal pockets.
7. Residual/detail closure is then:
   C04-2, C02-28, C05-28, C04-30, C16-23, C11-12, C08-1.

Every listed batch completed its entire quota in the conservative geometry-peeling simulation.

No batch exceeds 30. Per-color and grand-total conservation are exact.

Canonical Godot solver verification is still mandatory because only the real repository gameplay stack can declare the candidate production-solvable.

## Claude implementation requirements

For Level 003 only:

1. Add a deterministic supply/batch representation capable of reproducing the exact three FIFO queues above.
2. Do not regenerate or repartition these Level 003 batches before first testing this owner candidate.
3. Preserve exactly 3 visible supply rows while retaining every hidden FIFO row.
4. Solver/runtime must consume the full queues, not only visible rows.
5. Enforce:
   - every batch count > 0;
   - every batch count <= 30;
   - exact per-color conservation;
   - grand total = 1444.
6. Run the exact candidate through canonical `ProofState` / `SolvabilitySolver`.
7. If `SOLVED`, replay the trace and record status, visited states, decisions, trace hash and replay result.
8. If DEADLOCK or UNKNOWN_BOUND, report the exact blocker before altering this owner candidate.
9. Do not weaken FIFO, five-slot, targeting, Railroad, access or routing semantics.
10. Do not silently substitute a generated seed layout for this first test.

## Acceptance

This Level 003 plan may become production-canonical only after:
- conservation PASS;
- hidden FIFO preservation PASS;
- canonical solver `SOLVED`;
- replay PASS;
- owner/ChatGPT audit acceptance.
