# OWNER INPUT — LEVEL 002 APPLE SUPPLY/BATCH CANDIDATE V01

Date: 2026-09-26
Repository: Sekiph82/Scrubbots
Scope: M52-C001 / Level 002 Apple
Status: OWNER-SPECIFIED CANDIDATE / SOLVER VERIFICATION REQUIRED

## Purpose

Use this exact supply/batch layout as the **first candidate** for Level 002 Apple.

The candidate was constructed from the actual 32x32 Level 002 source grid with a hard maximum of 30 Scrubbots per batch.

The ordering was generated with a conservative geometry-peeling simulation:
- only currently exterior/perimeter-reachable cells are eligible;
- clearing cells can expose deeper cells;
- within a selected color, target order is bottom-most, then left-most;
- a batch is admitted only when its full quota can be consumed before the next intended selection.

This file does **not** claim canonical Godot solver proof yet. Claude must later verify it with the repository's real `ProofState` / `SolvabilitySolver` semantics before production admission.

## Source level

- Level: 2
- ID: `level_002_apple`
- Difficulty: `EASY`
- Source: `assets/art/levels/source/easy/level_002_apple_32x32.png`
- Source Git blob SHA: `f696d8b1e17712098e860945785d4a00c79139c0`
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
| C08 | #2450A4 | 683 |
| C01 | #FF4500 | 180 |
| C16 | #000000 | 82 |
| C04 | #00CC78 | 44 |
| C11 | #9C6926 | 21 |
| C12 | #FFF8B8 | 14 |
| **TOTAL** |  | **1024** |

All 1024 source pixels are opaque canonical ScrubBots colors.

## Batch partition

This candidate uses the minimum possible number of batches under the hard `<= 30` rule:

- C08: 30 x 22, then 23
- C01: 30 x 6
- C16: 30,30,22
- C04: 30,14
- C11: 21
- C12: 14

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

22 C16-30
23 C01-30
24 C01-30
25 C01-30
26 C01-30
27 C01-30
28 C01-30

29 C16-30
30 C04-30
31 C08-30

32 C08-23
33 C16-22
34 C11-21
35 C04-14
36 C12-14
```

## Exact 3-column FIFO layout

The intended global schedule is encoded round-robin across the three FIFO columns.

### Column 1 — 12 batches

```text
01 C08-30
02 C08-30
03 C08-30
04 C08-30
05 C08-30
06 C08-30
07 C08-30
08 C16-30
09 C01-30
10 C01-30
11 C08-30
12 C16-22
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
10 C16-30
11 C08-23
12 C11-21
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
10 C04-30
11 C04-14
12 C12-14
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
1,2,3
```

Total selections: **36**.

## Construction rationale

The Apple level has a very large C08 background surrounding a compact red fruit with black outline and small green/brown/yellow details.

The intended conservative peel is:

1. Clear the large C08 exterior shell first.
2. Introduce C16 when enough outline is exposed to consume a full batch.
3. Clear the large C01 apple body in six full 30 batches.
4. Continue with the remaining C16 and C04 regions as they become reachable.
5. Consume the last C08 pockets.
6. Finish with the small residual/detail groups C16-22, C11-21, C04-14 and C12-14.

No batch exceeds 30. Per-color and grand-total conservation are exact.

Canonical Godot solver verification is still mandatory because only the real repository gameplay stack can declare the candidate production-solvable.

## Claude implementation requirements

For Level 002 only:

1. Add a deterministic supply/batch representation capable of reproducing the exact three FIFO queues above.
2. Do not regenerate or repartition these Level 002 batches before first testing this owner candidate.
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

This Level 002 plan may become production-canonical only after:
- conservation PASS;
- hidden FIFO preservation PASS;
- canonical solver `SOLVED`;
- replay PASS;
- owner/ChatGPT audit acceptance.
