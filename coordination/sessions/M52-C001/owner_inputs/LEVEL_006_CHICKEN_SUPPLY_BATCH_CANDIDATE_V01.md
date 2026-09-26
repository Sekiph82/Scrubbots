# OWNER INPUT — LEVEL 006 CHICKEN SUPPLY/BATCH CANDIDATE V01

Date: 2026-09-26
Repository: Sekiph82/Scrubbots
Scope: M52-C001 / Level 006 Chicken
Status: OWNER-SPECIFIED CANDIDATE / SOLVER VERIFICATION REQUIRED

## Purpose

Use this exact supply/batch layout as the **first candidate** for Level 006 Chicken.

The candidate was constructed from the actual 32x32 Level 006 source grid with a hard maximum of 30 Scrubbots per batch.

Unlike a simple color-count split, the ordering was generated with a conservative geometry-peeling model that follows the current outside/perimeter/open-corridor reachability concept and the current bottom-most/left-most target priority within a color. Every listed batch was checked to have enough reachable work to consume its entire quota in that model.

This file does **not** claim canonical Godot solver proof yet. Claude must later verify it with the repository's real `ProofState` / `SolvabilitySolver` semantics before production admission.

## Source level

- Level: 6
- ID: `level_006_chicken`
- Difficulty: `EASY`
- Source: `assets/art/levels/source/easy/level_006_chicken_32x32.png`
- Source Git blob SHA: `ed403914d5694dca753a8adeb63041dbabbe81f1`
- Source SHA-256: `9e15e570a7b8d5a31f4cd0eb37e4f6e48e18e71f66b7c56e08510738412ff790`
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
| C08 | #2450A4 | 702 |
| C12 | #FFF8B8 | 133 |
| C14 | #515252 | 71 |
| C11 | #9C6926 | 58 |
| C03 | #FFD635 | 41 |
| C01 | #FF4500 | 12 |
| C02 | #FFA800 | 5 |
| C16 | #000000 | 2 |
| **TOTAL** |  | **1024** |

All 1024 source pixels are opaque canonical ScrubBots colors.

## Batch partition

- C08: 30 x 23, then 12
- C14: 30,30,11
- C01: 12
- C02: 5
- C12: 30,30,30,30,9, then later 4
- C11: 30,28
- C03: 30,11
- C16: 2

Total batches: **40**

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
22 C08-30
23 C08-30
24 C08-12

25 C14-30
26 C14-30
27 C14-11

28 C01-12
29 C02-5

30 C12-30
31 C12-30
32 C12-30
33 C12-30
34 C12-9

35 C11-30
36 C11-28

37 C03-30
38 C03-11

39 C12-4
40 C16-2
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
09 C14-30
10 C01-12
11 C12-30
12 C12-9
13 C03-30
14 C16-2
```

### Column 2 — 13 batches

```text
01 C08-30
02 C08-30
03 C08-30
04 C08-30
05 C08-30
06 C08-30
07 C08-30
08 C08-30
09 C14-30
10 C02-5
11 C12-30
12 C11-30
13 C03-11
```

### Column 3 — 13 batches

```text
01 C08-30
02 C08-30
03 C08-30
04 C08-30
05 C08-30
06 C08-30
07 C08-30
08 C08-12
09 C14-11
10 C12-30
11 C12-30
12 C11-28
13 C12-4
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
1
```

Total selections: **40**.

## Construction rationale

The Chicken board is dominated by C08 background.

The conservative geometry-peeling analysis produced this phase order:

1. C08 can be peeled completely from the exterior, so all 702 C08 cells are consumed first.
2. That exposes the full C14 region, so C14 clears next.
3. C01 then becomes fully reachable.
4. C02 then becomes fully reachable.
5. 129 of the 133 C12 cells can then be consumed.
6. C11 becomes fully reachable and clears.
7. C03 becomes fully reachable and clears.
8. The final 4 C12 cells are then exposed.
9. C16 finishes the board.

For each batch in the exact schedule above, the conservative reachability simulation confirmed that the batch quota can be fully consumed before advancing to the next intended selection.

No batch exceeds 30 and color conservation is exact.

Canonical Godot solver verification is still mandatory because only the real repository gameplay stack can declare the candidate production-solvable.

## Claude implementation requirements

For Level 006 only:

1. Add a deterministic supply/batch representation capable of reproducing the exact three FIFO queues above.
2. Do not regenerate or repartition these Level 006 batches before first testing this owner candidate.
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

This Level 006 plan may become production-canonical only after:
- conservation PASS;
- hidden FIFO preservation PASS;
- canonical solver `SOLVED`;
- replay PASS;
- owner/ChatGPT audit acceptance.
