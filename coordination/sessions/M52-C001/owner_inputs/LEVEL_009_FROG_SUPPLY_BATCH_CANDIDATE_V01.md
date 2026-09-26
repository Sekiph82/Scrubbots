# OWNER INPUT — LEVEL 009 FROG SUPPLY/BATCH CANDIDATE V01

Date: 2026-09-26
Repository: Sekiph82/Scrubbots
Scope: M52-C001 / Level 009 Frog
Status: OWNER-SPECIFIED CANDIDATE / SOLVER VERIFICATION REQUIRED

## Purpose

Use this exact supply/batch layout as the **first candidate** for Level 009 Frog.

The candidate was constructed from the real 32x32 Level 009 source grid with a hard maximum of 30 Scrubbots per batch. The intended order deliberately peels currently reachable colors so batches can complete and free their slot before the schedule advances.

This file does **not** claim canonical solver proof yet. Claude must later verify it with the repository's real `ProofState` / `SolvabilitySolver` semantics before production admission.

## Source level

- Level: 9
- ID: `level_009_frog`
- Difficulty: `EASY`
- Source: `assets/art/levels/source/easy/level_009_frog_32x32.png`
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
| C08 | #2450A4 | 497 |
| C07 | #3690EA | 318 |
| C16 | #000000 | 140 |
| C12 | #FFF8B8 | 40 |
| C06 | #51E9F4 | 15 |
| C13 | #D4D7D9 | 12 |
| C15 | #FFFFFF | 2 |
| **TOTAL** |  | **1024** |

All 1024 source pixels are opaque canonical ScrubBots colors.

## Batch partition

- C08: 30,30,30,30,30,30,30,30,30,30,30,30,30,30,30,30,17
- C07: 30,30,30,30,30,30,30,30,30,30,18
- C16: 30,30,30,30,20
- C12: 30,10
- C06: 15
- C13: 12
- C15: 2

Total batches: **38**

## Intended global player selection sequence

```text
01 C08-30
02 C08-30
03 C08-30
04 C08-30
05 C08-30
06 C08-30
07 C08-30

08 C07-30
09 C07-30
10 C07-30
11 C07-30
12 C07-30
13 C07-30
14 C07-30
15 C07-30
16 C07-30

17 C08-30
18 C08-30
19 C08-30

20 C07-30

21 C08-30
22 C08-30
23 C08-30
24 C08-30
25 C08-30
26 C08-30

27 C16-30
28 C16-30
29 C16-30
30 C12-30
31 C16-30
32 C16-20
33 C07-18
34 C08-17
35 C06-15
36 C13-12
37 C12-10
38 C15-2
```

## Exact 3-column FIFO layout

The intended global schedule is encoded round-robin across the three FIFO columns.

### Column 1 — 13 batches

```text
01 C08-30
02 C08-30
03 C08-30
04 C07-30
05 C07-30
06 C07-30
07 C08-30
08 C08-30
09 C08-30
10 C16-30
11 C16-30
12 C08-17
13 C12-10
```

### Column 2 — 13 batches

```text
01 C08-30
02 C08-30
03 C07-30
04 C07-30
05 C07-30
06 C08-30
07 C07-30
08 C08-30
09 C08-30
10 C16-30
11 C16-20
12 C06-15
13 C15-2
```

### Column 3 — 12 batches

```text
01 C08-30
02 C08-30
03 C07-30
04 C07-30
05 C07-30
06 C08-30
07 C08-30
08 C08-30
09 C16-30
10 C12-30
11 C07-18
12 C13-12
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
1,2
```

Total selections: **38**.

## Construction rationale

The schedule is intentionally not a simple color-count partition alone.

It was built from the actual Level 009 cell geometry using a reachability-peeling pass:
- begin with externally reachable C08 background;
- expose and clear the large C07 frog-body region;
- return to newly exposed C08 pockets;
- then clear deeper outline/detail colors C16/C12/C06/C13/C15;
- every planned batch is at most 30;
- per-color and grand-total conservation are exact.

The construction goal is that a selected batch has enough currently/further-exposed legal same-color work to finish rather than permanently occupying one of the five slots.

Canonical solver verification is still mandatory because only the repository gameplay stack is authoritative.

## Claude implementation requirements

For Level 009 only:

1. Add a deterministic supply/batch representation capable of reproducing the exact three FIFO queues above.
2. Do not regenerate or repartition these Level 009 batches before first testing this owner candidate.
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

This Level 009 plan may become production-canonical only after:
- conservation PASS;
- hidden FIFO preservation PASS;
- canonical solver `SOLVED`;
- replay PASS;
- owner/ChatGPT audit acceptance.
