# M46 R02 Offline Stress — CLAUDE LOG R02 V01

Prompt: `coordination/sessions/M46-PERFORMANCE-C001/CHATGPT_M46_R02_OFFLINE_STRESS_MASTER_PROMPT_V01.md`. Base `origin/main` `c45c6377`, fast-forwarded from `6da83668`. Owner files, untracked files and stashes were untouched.

**Result: M46_R02_LOCAL_PASS_WITH_CI_COST_FREEZE_AND_PHONE_GPU_GATES_OPEN**

## Cost freeze
**No GitHub Actions run, dispatch or rerun.** The job guards are verified unchanged:
- `android-family-first10.yml` lines 61 and 188 (`if: ${{ false }}`);
- `ios-ipa.yml` line 35.

No APK, IPA or R2 work. Every result is `LOCAL_PASS`: headless desktop CPU, with **no phone and no GPU**. CI is `CLOUD_CI_DEFERRED_COST_FREEZE`.

**Tool:** `C:\Users\sekip\AppData\Local\Microsoft\WinGet\Links\godot_console.exe` (Godot 4.7.2.stable), with the existing import cache.

**Command:**
```
godot_console --headless --path . -s res://tests/m46_performance.gd
```

**Final result:** **M46 performance evidence: PASS (19/19 cases, 0 fail)**, 232 s. All p01..p15 checks were kept unchanged, and the budgets were not loosened (mean ≤ 4.0 ms, p99 ≤ 16.7 ms).

**Production code changed: none** this round; R02 is test-only. The two M46 V01 production fixes and the owner-approved on-board symbols are preserved.

## §2 p16 strengthened
On the 59×59 v2 pocket level: 3,025 artwork + 456 VOID cells, 12 colours. All of these are now asserted:

- **WAITING peak:** ≥ 5 waiting slots at once, measured 5. Gated because the run is fixed-DT deterministic, and it reproduced on every run.
- **WAITING recovery:** all 92 batches that WAITED left it, and 91 were later seen ACTIVE (WAITING → ACTIVE recovery). No occupied WAITING slot remains at terminal.
- **Pure pause:** 60 paused ticks with **35 bots and 35 assignments in flight**. None of the following changed: board, slots, supply, assignments, agent positions and progress, completion state, progression, economy wallet and boosters.
- **Speed:** `GameplaySpeedAuthority.factor()` read **2.0 → 1.0 → 2.0**. That proves the authority state, not the per-frame travel delta.
- **Unchanged checks:** P1 < P2 < P3 first-clear order (1,920 < 19,120 < 19,630), slot origin below the board, CPU budget (mean 1.99 / p99 8.0 ms).

## §3 p17: sixth slot + boosters (pocket level, real host, private economy)
- **Isolation:** the host has no AppState and no save path, so the owner's profile is never touched. Its starter SB is spent down in that private wallet.
- **+1 Slot purchase:**
  - Unfunded attempt: refused (`insufficient_sb`), wallet and boosters unchanged.
  - Purchase: **SB 500 → 0, charged exactly once.** Engine and UI strip go 5 → 6.
  - Second attempt: refused (`plus_one_used`), SB kept.
  - A seventh slot is impossible: `can_grow_to_sixth()` is false, and `strip.set_capacity(7)` is false.
- **One tap:** the tap lands in **slot 6** and consumes exactly 1 supply batch (107 → 106).
- **Sixth slot in use:**
  - It is occupied in the engine and shown occupied in the UI strip on the same frame.
  - It dispatches bots and also WAITS.
  - At most 6 slots ever appear, in engine and UI.
- **Paused:** checked with 28 bots in flight.
  - A front tap is refused (`paused`).
  - Illegal-target Tornado attempts are refused (`color_not_present` / `target_required`).
  - 30 paused ticks leave gameplay and economy unchanged.
- **Owned Tornado:** colour 5, 259 ACTIVE cells → 0, its supply batches gone, charge 1 → 0, SB untouched.
- **Level outcome:** WON, 3,025 / 3,025. Frame mean 2.5–2.8 / p99 8.6–10.3 ms.
- **Terminal and retry:**
  - At terminal both boosters are refused (`terminal`) with the economy unchanged.
  - `retry()` returns a fresh attempt with 5 slots in engine and strip, and +1 Slot is legal again (once per attempt).
- **Not applicable / not covered:**
  - **Random and Selector** were not exercised in p17. Tornado was the chosen colour-based booster. Their legality and atomicity stay covered by the M39 / M43 suites, not by a 59×59 load run.

## §4 p18: winding multi-colour routes
**Fixture:** 59×59 v2 maze.
- A 1-wide, 48-cell serpentine corridor near the bottom, in three colours (C07 → C10 → C03).
- The corridor is sealed by its own maze-wall colour C13. Those batches are dealt last, at the end of Supply column 4.
- The rest of the art is wall C14.

**How it is measured:** routes are read from the real `ScrubbotAgent.get_route_points()` of every dispatched corridor bot. Turns are cardinal-direction changes; cells are counted by sampling inside the board.

**Results:**
- **All 48 corridor cells** were reached by real dispatched routes.
- **Winding:** the deepest-colour route turned **7 times through 41 board cells** (step 38). Turns grow with depth (step 8: 1, step 30: 5, step 47: 7).
- **Path integrity:** every route crossed only cleared corridor cells besides its own target. The maze walls were intact for every corridor dispatch.
- **Reservations and outcome:** no shared target among in-flight assignments; WON.
- **Probe:** route_dijkstra max 0.8–1.1 ms; target_selection mean about 2.5 ms.

**Frame mean, 4 runs:** 3.19 / 3.21 standalone, 3.41 / 3.55 in the full suite. p99 11.1–12.1 ms. That is **11–20% headroom** against the 4.0 ms budget, which was not loosened. These are the costliest frames in the suite: one-at-a-time corridor trips plus wall clearing.

**Two fixture iterations,** documented honestly:
- Walls in the same colour as the surrounding art were eroded before the corridor finished.
- A maze at the top made every corridor step about 450 frames, because of the rail trip.

The final fixture keeps a dedicated wall colour that is dealt last, with the maze at the bottom.

## §5 SB-M46-015 effect budget (p19)
**Setup:**
- The real `FeedbackAdapter` is bound to an `EffectsSettingsService`.
- The **installed GameFeelFlow 1.0.0 and Saltmire Spark 1.0.0 autoloads are live** (`capabilities()`).
- The real `ResultsScreen` WON path (WIN + REWARD rows + MICRO) runs during a dense 59×59 run at 2×.
- The WON receipt is legitimate, built by `FirstClearTransaction` + `TerminalRewardReceipt` on the host's private economy.

**FULL vs REDUCED:**

| | FULL | REDUCED |
|---|---|---|
| owned dispatches (peak) | 8–10 | 0 |
| Spark burst emitters (peak, target canvas + pool) | 6–9 (≤ dispatches) | 0 |
| expiry of all owned work | about 650–700 ms | n/a |
| native board cleaning FX | 24 / cap 24 | 8 / cap 8 |
| CPU frame mean / p99 | 3.1 / 8.1–8.4 ms | 2.1 / 8.6–9.1 ms |

**Other checks, all asserted:**
- **GameFeelFlow:** the Results path only passes Control targets, and GFF 1.0.0 `punch_scale` drives Node2D / Node3D only, so on that path the adapter never sends GFF work. The real GFF backend was exercised through the same adapter on a Node2D: peak scale deviation 0.175, and scale restored to **exactly 1** after expiry, `cancel_all`, and a live REDUCED toggle.
- **Never per cell, structurally:** a source scan confirms the clear loop, native FX, renderer and retire-echo never reference the plugin gateway or autoloads. Clears with no Results event produce 0 plugin events, and there are about 7 events per Results show.
- **No replay:** a fully revealed, celebrated terminal re-shown over a 1.8 s window replays nothing.
- **Teardown:** a live FULL → REDUCED toggle cancels owned work. A level retry (ok), `cancel_all` and `unbind` leave 0 owned and remove the settings subscription.
- **No leftovers:** the settled Results subtree goes 28 → 28 nodes, with 0 Spark emitters and 0 owned work. Process Object delta (+11 to +54) is report-only, because it includes bots in flight and retried supply.

**Owner rule respected:** Spark / GFF are never applied per cleared pixel. Native board FX are separate and capped.

**Not proven here:** the GameFeelFlow punch reaching the screen on a real production Node2D target. No production feel call targets a Node2D on these paths. Mobile GPU particle cost is also not measured.

## Findings recorded (report-only, not gated)
- **First Results show, about 290 ms one-off:** cold asset load. It appears now that the show cost is counted in its frame.
- **Tornado execute, about 51 ms one-off:** candidate index rebuild + board repaint + colour purge on 59×59. The next 120 frames peak at about 27 ms.
- **Isolated frame max outliers,** e.g. 416 ms once in p17, with p99 and mean intact. Likely OS preemption on a shared laptop.
- **Selection and reachability-mask costs:** target_selection peaks of about 8–24 ms and full `access_mask_build` (about 2–4 ms each, 2,000+ per 59×59 level) remain the first candidates to profile on a real phone. No algorithm change was made without phone evidence.

## Open gates
- **Phone and GPU performance:** real FPS, render and particle cost (M47).
- **Cloud CI:** deferred by the owner cost freeze.
- **Booster coverage under 59×59 load:** Random and Selector were not run.
- **ChatGPT independent audit** of R02.

## Peer review
`coordination/sessions/M46-PERFORMANCE-C001/CLAUDE_PEER_REVIEW_R02_V01.md` records a new, fresh-context `CLAUDE_PEER_REVIEW`, not ChatGPT. It returned APPROVE_WITH_FIXES. The MAJOR (GFF not exercised) and all minors were addressed, and one post-review clock-sensitivity issue was fixed.

## Local footprint
- The only intermediate files were fixed-name `user://m46_*.json` fixtures. They are deleted by the suite, and 0 remain.
- No harness background output files this round. No owner save was touched.
