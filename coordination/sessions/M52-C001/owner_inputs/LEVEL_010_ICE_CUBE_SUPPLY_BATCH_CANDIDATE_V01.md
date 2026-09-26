# OWNER INPUT — LEVEL 010 ICE CUBE SUPPLY/BATCH CANDIDATE V01

Date: 2026-09-26
Repository: Sekiph82/Scrubbots
Scope: M52-C001 / Level 010 Ice Cube
Status: OWNER-SPECIFIED CANDIDATE / SOLVER VERIFICATION REQUIRED

## Purpose

Use this exact supply/batch layout as the **first candidate** for Level 010 Ice Cube.

Claude must implement this candidate in the Level 010 batch/color/supply section and validate it with the repository's canonical gameplay solver before production admission.

This file does **not** claim that the schedule is already solver-proven.

If the canonical solver does not return `SOLVED`, do not silently mark it valid. Report the failing step/status and keep Level 010 blocked unless the owner explicitly approves a revised schedule.

## Source level

- Level: 10
- ID: `level_010_ice_cube`
- Difficulty: `VERY_HARD`
- Source: `assets/art/levels/source/very_hard/level_010_ice_cube_32x32.png`
- Dimensions: 32x32
- Total logical cells / Scrubbots: 1024
- Baseline slot capacity: 5
- Supply columns: 3
- Visible rows per column: 3
- Hidden FIFO depth: unrestricted by visible depth
- Max robots per batch: **30**

## Canonical color totals

| Color | Pixels |
|---|---:|
| C13 | 270 |
| C08 | 259 |
| C16 | 216 |
| C05 | 93 |
| C14 | 78 |
| C15 | 70 |
| C06 | 16 |
| C03 | 14 |
| C02 | 6 |
| C07 | 2 |
| **TOTAL** | **1024** |

## Batch partition

- C13: 30,30,30,30,30,30,30,30,30
- C08: 30,30,30,30,30,30,30,30,19
- C16: 30,30,30,30,30,30,30,6
- C05: 30,30,30,3
- C14: 30,30,18
- C15: 30,30,10
- C06: 16
- C03: 14
- C02: 6
- C07: 2

Total batches: **40**

## Intended global player selection sequence

The intended solution attempt uses the following front-batch selection order.

```text
01 C08-30
02 C08-30
03 C08-30
04 C08-30
05 C08-30
06 C08-30
07 C08-30
08 C16-30
09 C14-30
10 C16-30
11 C13-30
12 C13-30
13 C16-30
14 C08-30
15 C13-30
16 C13-30
17 C16-30
18 C05-30
19 C14-30
20 C16-30
21 C13-30
22 C13-30
23 C13-30
24 C13-30
25 C13-30
26 C05-30
27 C15-30
28 C15-30
29 C16-30
30 C05-30
31 C16-30
32 C08-19
33 C14-18
34 C06-16
35 C03-14
36 C15-10
37 C02-6
38 C16-6
39 C05-3
40 C07-2
```

## Exact 3-column FIFO layout

The global sequence above is encoded round-robin across the three FIFO columns.

### Column 1 — 14 batches

```text
01 C08-30
02 C08-30
03 C08-30
04 C16-30
05 C16-30
06 C13-30
07 C14-30
08 C13-30
09 C13-30
10 C15-30
11 C16-30
12 C06-16
13 C02-6
14 C07-2
```

### Column 2 — 13 batches

```text
01 C08-30
02 C08-30
03 C16-30
04 C13-30
05 C08-30
06 C16-30
07 C16-30
08 C13-30
09 C05-30
10 C16-30
11 C08-19
12 C03-14
13 C16-6
```

### Column 3 — 13 batches

```text
01 C08-30
02 C08-30
03 C14-30
04 C13-30
05 C13-30
06 C05-30
07 C13-30
08 C13-30
09 C15-30
10 C05-30
11 C14-18
12 C15-10
13 C05-3
```

## Intended column-click sequence

Given the FIFO layout above, the intended player selection order is:

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

That is 40 selections total.

## Claude implementation requirements

For Level 010 only:

1. Add a deterministic supply/batch representation capable of reproducing the exact three FIFO queues above.
2. Do not regenerate or repartition these Level 010 batches before first testing this owner candidate.
3. Keep the player-facing visible supply depth at 3 rows while preserving all hidden FIFO rows.
4. Ensure the runtime/solver consumes the complete hidden queues.
5. Preserve exact color conservation:
   - every batch count > 0;
   - every batch count <= 30;
   - per-color batch totals equal the LevelData color totals exactly;
   - grand total = 1024.
6. Run the exact candidate through the canonical `ProofState` / `SolvabilitySolver` gameplay semantics.
7. Also replay the emitted solution trace if the solver returns `SOLVED`.
8. Record:
   - solver status;
   - visited states;
   - decisions;
   - trace hash;
   - replay result;
   - first divergence/deadlock point if not solved.
9. Do not weaken routing, targetability, slot, FIFO, or five-slot semantics to make this schedule pass.
10. If this exact candidate fails, stop and report the evidence before changing the owner-specified batch/color layout.

## Acceptance

This Level 010 supply plan may become production-canonical only after:

- exact conservation PASS;
- full hidden FIFO preservation PASS;
- canonical solver `SOLVED`;
- solution replay PASS;
- owner/ChatGPT audit acceptance.
