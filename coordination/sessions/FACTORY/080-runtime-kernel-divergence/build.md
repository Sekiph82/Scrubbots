STATUS: READY

# Build: Real-play solver: prove and plan levels by playing the shipping runtime like a human

## Summary
The branch adds a real-play solver that drives the real `ProductionGameplayHost` the way a human plays: all five slots are filled at frame 0, and any slot that frees up is refilled on the next frame while other bots are still flying. It uses dt 1/60 as the canonical step and must also win at 1/30 and 1/120. It includes a deterministic search over supply-column orders, a verify/regen tool, a provenance file and a CI gate. Under real play, six Studio plans dead-ended. For those six (L18, L20, L22, L23, L25, L30) only `intendedColumnClicks` was regenerated. All 30 levels now WIN at all three dts. No runtime, presentation or pacing file changed, and the kernel diff is comment-only.

Branch commits: 870fbb04, 8890733c, 086852d8, fc69d221, bd3fa563 (TASKS). The remote branch was pushed for CI and then deleted.

Files changed:
- new `scripts/gameplay/solver/real_play_driver.gd`: `play_on_host`, `play_level` (a coroutine), `verify`, `search`, `rank_columns`, `plan_sha256`, `load_provenance`, `clicks_for`
- new `tools/real_play_verify.gd`
- new `tests/real_play_levels.gd`
- new `data/levels/supply/real_play_provenance_v1.json`
- `data/levels/supply/level_0{18,20,22,23,25,30}_*_supply_v1.json` (only the click arrays changed)
- `scripts/gameplay/solver/proof_kernel.gd` (header comment only)
- `tests/m52_owner_supply_plans.gd`, `tests/m55_long_session.gd`, `tests/campaign_l11_l30.gd`
- `.github/workflows/android-family-first10.yml` (+ real_play_levels, 63 total, exact 5/5 guard)
- `tools/import_release_pool_levels.py` (real-play gate via `--godot` / env `GODOT`; it is a hard error without Godot)
- `docs/10_LEVEL_FACTORY_GENERATION_SCORING_ARCHITECTURE.md` (new section 24), `AGENTS.md` (one section line), `TASKS.md` (DONE row + `READY SB-STUDIO-REAL-PLAY-GATE`)

## Acceptance criteria
1. [x] real_play_levels: `"$GODOT" --headless --path . -s res://tests/real_play_levels.gd` exits 0, last line `REAL PLAY LEVELS: PASS (5/5 cases, 0 fail)`, 0 SCRIPT ERROR / Parse Error, 716 s locally. All 30 levels print `ok: ... WON at 1/60`. fps_sensitivity covers L18, L20, L22, L23, L25 and L30 at 1/30 and 1/120, all WON (12 lines). The suite output says why it covers a subset: all 30 levels at three dts would not fit the CI per-suite timeout. The three-dt WON for every level is recorded by the tool in provenance.
2. [x] The plain run `-s res://tools/real_play_verify.gd -- --levels all` exits 0 and prints 30 `LEVEL ... 60fps WON frames=N 30fps WON 120fps WON` lines, then `REAL PLAY VERIFY: PASS (30 levels, 0 not WON)`. sha256 of every plan file and the provenance file was taken before the run and was unchanged afterwards. Two later `--regen` runs (`--levels 12`, `--levels 22,30`) also left every byte unchanged (`sha256sum -c` OK).
3. [x] `git diff main...HEAD -- data/levels` touches only the six plans plus the new provenance file. A JSON diff that drops `intendedColumnClicks` shows every other key identical, and the bytes outside the array are identical for all six (a regex splice check). The first changed click per level was L18 #17, L20 #90, L22 #12, L23 #15, L25 #14, L30 #5 (old and new lists are in the Log).
4. [x] The provenance file has 30 records (L1 with `clicks: null`, `planSha256: null`). `planSha256` is the sha256 of the plan text with CRLF normalized to LF, so it matches the git blob and CI. The `provenance` case checks it. `regenerated` is true for exactly the 6 changed plans, and each of those records carries `originalPlanSha256` and `originalIntendedColumnClicks`.
5. [x] determinism: two L22 runs gave cleared_sequence sha256 `6033cbda82264b34d2808cb9d911529eacebf78314a9eb51c61f6aad93464c97` both times (634 clears, identical frame count). The Requirement 1 investigation is in the Log.
6. [x] search_negative: `ok: old L22 clicks are NOT WON under real play: stuck after click 27/43, 273 ACTIVE left (LOST)` and `ok: search from the old clicks: SOLVED in 32 nodes (budget 400), WON at 1/30, 1/60 and 1/120 (5 canonical-only wins rejected)`.
7. [x] m55_long_session exits 0 with `M55 LONG SESSION: PASS`, 648 s locally. Both laps print "30 levels WON" and "frontier advanced to 31 (got 31)". `_quiet` and `_slot_states` were removed; the only `_quiet` match left is `_await_feel_quiet` (the feel-quiescence helper). Driving now goes through `RealPlayDriver.play_on_host`, after one layout frame.
8. [x] m52_owner_supply_plans: `M52 OWNER SUPPLY PLANS: PASS`, with 9 levels WON through the driver at 1/60. campaign_l11_l30: `CAMPAIGN L11-L30 evidence: PASS (5/5 cases, 0 fail)`. Its `win` case now checks that the plan loads fail-closed, that the clicks are legal and consume every batch, and that the Studio SOLVED + replay WIN evidence is present.
9. [x] The runtime diff stat over dispatch/runtime/targeting/routing/agents is empty. The proof_kernel.gd diff contains only `##` lines.
10. [x] Regression suites: m52_r01_parallel_runtime PASS, m52_r02_early_slot_release PASS, m46_rm006_selector_proof_integrity `PASS (5/5 groups)`. m46_rm006 prints 2 SCRIPT ERROR lines from its own fault injection (`rm006_injected`, `production_booster_adapter.gd:_faulted`). It loads only files this branch does not touch, so they predate this branch, and the suite is not in the CI list.
11. [x] `python tools/import_release_pool_levels.py --help` works and shows `--godot`. `GODOT= python tools/import_release_pool_levels.py --studio /nonexistent` exits 1 with "no Godot given ... refusing to import without it" before touching any file. I also simulated a re-import cycle: restoring main's Studio L22 plan and running `--levels 22 --regen` recreated identical plan content and identical provenance bytes (the search took 32 nodes). `git diff --check` is clean, and no `.import`, `.uid` or `project.godot` file was committed.
12. [x] Docs: the ProofKernel header paragraph ("shippable ... decided ONLY by the real-play solver"), docs/10 section 24 "Real-play verification (shippability gate)", the AGENTS.md "Real-play gate" line, and the TASKS.md DONE row with evidence plus `READY SB-STUDIO-REAL-PLAY-GATE`.
13. [x] CI run 41192324690 (validation_only, ref factory/080-runtime-kernel-divergence) succeeded: validate succeeded and export was skipped. `real_play_levels exit=0 status=PASS`, `REAL-PLAY-LEVELS verdict=PASS (5/5)`, `m55_long_session exit=0 status=PASS` (about 5 min each on CI), `campaign_l11_l30 status=PASS`. The remote branch was deleted afterwards.

## Validation
I ran `--import` and the Godot 4.7.2 console from AGENTS.md:
- real_play_levels: PASS
- m55_long_session: PASS
- m52_owner_supply_plans: PASS
- campaign_l11_l30: PASS 5/5
- m52_r01_parallel_runtime: PASS
- m52_r02_early_slot_release: PASS
- m46_rm006_selector_proof_integrity: PASS (pre-existing injected-fault SCRIPT ERROR lines, see AC10)
- real_play_verify: `--levels all --regen` PASS, then `--levels all` PASS, then idempotency reruns
- `git diff --check`: clean
- importer `--help` and the no-Godot run behave as described in AC11
- CI 41192324690: success

All of the above are LOCAL_PASS plus that one CI run.

## Log
### Round 1
Investigation (Requirement 1, throwaway probes not committed):
- (a) Determinism. Same level, same clicks and same dt in separate processes gave identical cleared-sequence hashes and frame counts (for example L2 at 1/60: 3192374106 twice). framesAtCanonical was identical across the three full tool runs. The runtime tick path has no rng or wall clock.
- (c) Layout, which turned out to be the important finding. A bare host played before its first layout frame (the m52 and earlier-probe pattern) uses SlotOriginProvider fallback origins (40,0),(49,0),...,(76,0). The laid-out app root uses (5.53,41.01),(10.84,41.01),(16.15,41.01),(21.44,41.01),(26.75,41.01). With the old L22 clicks this changes the result: the unlaid bare host is stuck after 12 clicks (4795 frames) while the app root is stuck after 27 (6892 frames). A bare host set to full-rect anchors with one frame awaited gets exactly the app root's origins at viewports 1080x2160, 720x1600 (visible 1080x2400) and 1200x1600 (visible 1620x2160). Board-local origins are therefore viewport-independent once laid out. The driver and tests now wait one layout frame and call `reset_runtime()` before the first click. m55 needed one `await process_frame` before Level 1: without it L1 was LOST after 7 clicks.
- (b) FPS. With laid-out hosts and the original plans: L18 stuck after 17 clicks at all three dts (2957 / 5933 / 11826 frames). L20 stuck after 90 at all three. L22 stuck after 12 at 1/30 but after 27 at 1/60 and 1/120, so FPS changes the failure point. L23 stuck after 15, L25 after 15, L30 after 10 (all three dts each). Every other level is WON at all three. For all 30 levels the cleared-cell sequence hash differs between dts, so claim order is FPS-dependent while most outcomes are not. With the unlaid-host origins, L20 was 63/56/56 and L25 15/15/11 across the dts. L1's first-front policy wins at all three dts once laid out (19 clicks, 3503 frames at 1/60), so L1 keeps `clicks: null`.

Search. Plain chronological DFS with full prefix replays was too slow: L1 and L30 used up 400 and 200 nodes with no win. I replaced it with rollout nodes (one replay per node continues past the forced prefix: the plan column while on the plan prefix, then a read-only exposure ranking `rank_columns`). Nodes are taken in limited-discrepancy order, fewest deviations first and the decision nearest the failure first. Measured nodes: L18 3, L20 2, L22 32, L23 2, L25 43, L30 166 (budget `NODE_BUDGET = 400`). Every result is robust at all three dts, so no `robust: false` record and no owner question were needed. A canonical-only win is accepted only after it also wins at 1/30 and 1/120; L22 rejected 5 canonical-only wins along the way.

Regenerated plans (old -> new):
- L18 (first diverged at click 17): old [1,1,1,1,1,2,3,1,3,4,4,4,3,1,1,4,2,2,4,4,3,3,3,3,3,3,2,2,2,2,2,2,2,2,2,2,4,4,4,4] -> new [1,1,1,1,1,2,3,1,3,4,4,4,3,1,1,4,4,4,3,3,3,3,3,3,4,4,4,4,2,2,2,2,2,2,2,2,2,2,2,2]
- L20 (first diverged at click 90): clicks 1-89 unchanged. Old tail from click 82: 1,1,1,1,1,1,1,3,3,3,3,1,1,1,3,... New tail: 1,1,1,1,1,1,1,3,1,1,1,3,3,3,3,... (the remaining clicks are column 3)
- L22 (first diverged at click 12): old [1,1,1,1,1,2,2,2,2,2,2,2,2,2,2,3,3,3,4,4,4,4,4,4,5,5,3,3,5,5,3,3,3,3,3,5,5,5,5,5,5,5,5] -> new [1,1,1,1,1,2,2,2,2,2,2,4,3,3,3,3,3,3,3,3,3,3,4,4,4,4,4,2,2,2,2,5,5,5,5,5,5,5,5,5,5,5,5]
- L23 (first diverged at click 15): old [1x9,2x10,4,4,4,4,3x9,4x5] -> new [1x9,2,2,2,2,2,4x9,2,2,2,2,2,3x9]
- L25 (first diverged at click 14): old [1,1,1,1,1,1,3,3,2,2,3,3,3,1,2,2,2,2,2,1,1,3,3,3,1,1,1,2,2,2,2,2,3,3,3,3,3,3,3,3] -> new [1,1,1,1,1,1,3,3,2,2,3,3,3,2,2,2,2,2,3,1,2,2,2,2,2,1,3,3,1,1,1,3,3,1,3,3,3,3,3,3]
- L30 (first diverged at click 5): 120 clicks, new list starts 1,1,1,1,2,1,1,3,3,3,3,3,... Both full lists are in the provenance record `originalIntendedColumnClicks` / `clicks`.

Deviations and notes:
- `play_level`, `verify` and `search` are coroutines (`await`), because the host needs one layout frame before play.
- The fps_sensitivity subset is the regenerated levels plus L18 and L20, as the spec allows.
- The provenance records carry an extra `order` field, and dts are stored as strings ("1/60").
- The importer's real-play subprocess was not run against the Studio, as AC11 asked (static check only).
- No `.import`, `.uid` or `project.godot` file was committed; the worktree's import artifacts were left on disk, as instructed.
