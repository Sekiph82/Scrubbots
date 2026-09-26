# OWNER INPUT — LEVEL 008 BUTTERFLY SUPPLY/BATCH CANDIDATE V01

Date: 2026-09-26
Repository: Sekiph82/Scrubbots
Scope: M52-C001 / Level 008 Butterfly
Status: OWNER-SPECIFIED CANDIDATE / SOLVER VERIFICATION REQUIRED

## Purpose

Use this exact supply/batch layout as the **first candidate** for Level 008 Butterfly.

The candidate was constructed from the actual 32x32 Level 008 source grid with a hard maximum of 30 Scrubbots per batch. The ordering was generated with a conservative geometry-peeling rule: only schedule a color batch when that batch can be satisfied from currently exterior-reachable cells plus same-color cells exposed by those clears. This is intended to avoid permanently occupying the five slots with stranded work.

This file does **not** claim canonical solver proof yet. Claude must later verify it with the repository's real `ProofState` / `SolvabilitySolver` semantics before production admission.

## Source level

- Level: 8
- ID: `level_008_butterfly`
- Difficulty: `MEDIUM`
- Source: `assets/art/levels/source/medium/level_008_butterfly_32x32.png`
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
| C08 | #2450A4 | 482 |
| C16 | #000000 | 240 |
| C02 | #FFA800 | 150 |
| C01 | #FF4500 | 55 |
| C03 | #FFD635 | 47 |
| C15 | #FFFFFF | 28 |
| C14 | #515252 | 15 |
| C11 | #9C6926 | 7 |
| **TOTAL** |  | **1024** |

All 1024 source pixels are opaque canonical ScrubBots colors.

## Batch partition

- C08: 30,30,30,30,30,30,30,30,30,30,30,30,30,30,30,30,2
- C16: 30,30,30,30,30,30,30,30
- C02: 30,30,30,30,30
- C01: 30,25
- C03: 30,17
- C15: 28
- C14: 15
- C11: 7

Total batches: **37**

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
11 C16-30
12 C08-30
13 C16-30
14 C16-30
15 C08-30
16 C16-30
17 C02-30
18 C08-30
19 C02-30
20 C16-30
21 C08-30
22 C02-30
23 C16-30
24 C08-30
25 C02-30
26 C16-30
27 C01-30
28 C03-30
29 C08-30
30 C02-30
31 C16-30
32 C15-28
33 C01-25
34 C03-17
35 C14-15
36 C11-7
37 C08-2
```

## Exact 3-column FIFO layout

The intended global schedule is encoded round-robin across the three FIFO columns.

### Column 1 — 13 batches

```text
01 C08-30
02 C08-30
03 C08-30
04 C08-30
05 C16-30
06 C16-30
07 C02-30
08 C02-30
09 C02-30
10 C03-30
11 C16-30
12 C03-17
13 C08-2
```

### Column 2 — 12 batches

```text
01 C08-30
02 C08-30
03 C08-30
04 C16-30
05 C16-30
06 C02-30
07 C16-30
08 C16-30
09 C16-30
10 C08-30
11 C15-28
12 C14-15
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
08 C08-30
09 C01-30
10 C02-30
11 C01-25
12 C11-7
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
1
```

Total selections: **37**.

## Construction rationale

The Butterfly board is dominated by the C08 background, with large C16 outline/interior barriers and orange/yellow/red/white/brown detail regions.

The candidate was built from the actual pixel grid with a conservative exterior-reachability peel:

- begin by removing large immediately reachable C08 regions;
- interleave C16 as outline cells become targetable;
- introduce C02 only after enough surrounding/background cells are open;
- continue alternating C08/C16/C02 while deeper wing/body areas open;
- finish with smaller C01/C03/C15/C14/C11 detail groups;
- every planned batch is at most 30;
- per-color and grand-total conservation are exact.

The schedule was intentionally chosen so each candidate batch has enough currently reachable or same-color-chain-exposed work to consume its quota in the geometry-peeling model. Canonical Godot solver verification is still mandatory.

## Claude implementation requirements

For Level 008 only:

1. Add a deterministic supply/batch representation capable of reproducing the exact three FIFO queues above.
2. Do not regenerate or repartition these Level 008 batches before first testing this owner candidate.
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

This Level 008 plan may become production-canonical only after:
- conservation PASS;
- hidden FIFO preservation PASS;
- canonical solver `SOLVED`;
- replay PASS;
- owner/ChatGPT audit acceptance.
