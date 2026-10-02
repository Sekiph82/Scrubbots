# M43-C004-C001 — Lifecycle / Performance Report V01

Source: `tests/m43_c004_c001_fail_need_a_hand.gd`, run headless under Godot 4.7.2 during the full 12-way parallel regression. The result was **PASS, 40/40 cases**.

## Modal / lifecycle

| Check | Result |
|---|---|
| 20 Fail → Need a Hand → X cycles (the counter's `repeat_every = 1` test seam makes every failure due, so the real terminal path opens the popup each time) | Need a Hand opened 20 times out of 20 |
| Live nodes under the app root, cycle 1 vs cycle 20 | 389 → 389 |
| `rewarded.resolved` and `ModalStack.modal_changed` connections, and the Timer count | Unchanged |
| Clicks on Fail Retry / Home behind Need a Hand | No effect: route RESULTS, same attempt, economy unchanged |
| 6 BUY taps in one frame | 1 purchase |
| 5 WATCH AD taps | 1 provider request |
| X while a video is pending | Refused (the C003 busy safety) |
| Reduced Effects | Same counter, offer, popup and Fail rows (rows shown immediately) |

## Third-failure terminal cost

These are headless CPU timings, **not** device or GPU frame evidence.

The terminal time covers everything that happens synchronously inside the terminal signal:

- economy commit and save;
- assistance decision, including the next-start solver proofs;
- Results route;
- Need a Hand build.

| Level | Board | Terminal | Picks | All-four proofs (diagnostic) |
|---|---|---|---|---|
| 1 | 20x20 | 355 ms | tornado, selector | 910 ms |
| 2 | 32x32 | 240 ms | tornado, selector | 5262 ms |
| 3 | 38x38 | 239 ms | tornado, selector | 266 ms |
| 4 | 32x32 | 251 ms | tornado, selector | 367 ms |
| 5 | 33x33 | 224 ms | tornado, selector | 1093 ms |
| 6 | 32x32 | 238 ms | tornado, selector | 3537 ms |
| 7 | 32x32 | 338 ms | tornado, selector | 1450 ms |
| 8 | 32x32 | 243 ms | tornado, selector | 1331 ms |
| 9 | 32x32 | 208 ms | tornado, selector | 1858 ms |
| 10 | 32x32 | 175 ms | selector, plus_one_slot | 700 ms |

- The "All-four proofs" column is dominated by Random's canonical 3-step solver proof. The recommender proves boosters lazily in ranked order and stops at two, so Random is proved only when the ranking reaches it.
- The test emits the terminal on a near-start board, so these picks reflect start-like context signals. A real deadlock board changes the context signals: for example, full slots promote +1 Slot.
