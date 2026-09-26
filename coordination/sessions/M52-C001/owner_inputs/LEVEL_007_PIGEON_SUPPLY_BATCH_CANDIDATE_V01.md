# OWNER INPUT — LEVEL 007 PIGEON SUPPLY/BATCH CANDIDATE V01

Date: 2026-09-26
Repository: Sekiph82/Scrubbots
Scope: M52-C001 / Level 007 Pigeon
Status: OWNER-SPECIFIED CANDIDATE / SOLVER VERIFICATION REQUIRED

## Purpose

Use this exact supply/batch layout as the **first candidate** for Level 007 Pigeon.

The candidate was constructed from the actual 32x32 Level 007 source grid with a hard maximum of 30 Scrubbots per batch. The ordering was built with a conservative geometry-peeling rule so each scheduled batch is expected to have enough currently reachable or newly exposed same-color work to finish and release its slot.

This file does **not** claim canonical solver proof yet. Claude must later verify it with the repository's real `ProofState` / `SolvabilitySolver` semantics before production admission.

## Source level

- Level: 7
- ID: `level_007_pigeon`
- Difficulty: `EASY`
- Source: `assets/art/levels/source/easy/level_007_pigeon_32x32.png`
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
| C08 | #2450A4 | 666 |
| C14 | #515252 | 126 |
| C16 | #000000 | 111 |
| C15 | #FFFFFF | 58 |
| C13 | #D4D7D9 | 43 |
| C01 | #FF4500 | 9 |
| C11 | #9C6926 | 9 |
| C10 | #FF3881 | 2 |
| **TOTAL** |  | **1024** |

All 1024 source pixels are opaque canonical ScrubBots colors.

## Batch partition

- C08: 30,30,30,30,30,30,30,30,30,30,30,30,30,30,30,30,30,30,30,30,30,30,6
- C14: 30,30,30,30,6
- C16: 30,30,30,21
- C15: 30,28
- C13: 30,13
- C01: 9
- C11: 9
- C10: 2

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
18 C08-30
19 C08-30
20 C08-30
21 C16-30
22 C14-30
23 C14-30
24 C16-30
25 C13-30
26 C15-30
27 C14-30
28 C16-30
29 C14-30
30 C08-30
31 C08-30
32 C16-21
33 C15-28
34 C13-13
35 C01-9
36 C11-9
37 C08-6
38 C14-6
39 C10-2
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
08 C14-30
09 C13-30
10 C16-30
11 C08-30
12 C13-13
13 C08-6
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
08 C14-30
09 C15-30
10 C14-30
11 C16-21
12 C01-9
13 C14-6
```

### Column 3 — 13 batches

```text
01 C08-30
02 C08-30
03 C08-30
04 C08-30
05 C08-30
06 C08-30
07 C16-30
08 C16-30
09 C14-30
10 C08-30
11 C15-28
12 C11-9
13 C10-2
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

The Pigeon board is heavily dominated by the C08 background. The intended schedule therefore removes a large exterior C08 shell first, then introduces the pigeon outline/body colors as they become exposed.

The geometry-peeling plan is:

- clear twenty initial C08-30 batches from the large externally accessible background;
- begin exposing and clearing C16/C14 outline/body structure;
- interleave C13/C15 as their regions become accessible;
- return to the final large C08 pockets;
- finish the residual C16/C15/C13 details and very small C01/C11/C10 regions;
- every batch is at most 30;
- exact per-color conservation is preserved.

This schedule was selected so each batch completes in the conservative reachability-peeling model before the next intended selection. Canonical Godot solver verification remains mandatory.

## Claude implementation requirements

For Level 007 only:

1. Add a deterministic supply/batch representation capable of reproducing the exact three FIFO queues above.
2. Do not regenerate or repartition these Level 007 batches before first testing this owner candidate.
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

This Level 007 plan may become production-canonical only after:
- conservation PASS;
- hidden FIFO preservation PASS;
- canonical solver `SOLVED`;
- replay PASS;
- owner/ChatGPT audit acceptance.
