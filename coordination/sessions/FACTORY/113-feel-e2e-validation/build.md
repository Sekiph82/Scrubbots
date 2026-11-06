STATUS: READY

# Build: SB-M43-C005F-015 — end-to-end GameFeelFlow / Spark feel validation

## Summary
One end-to-end suite, `tests/m43_c005f_015_e2e_feel.gd`, drives the real app (main.tscn in a 1080x2160 SubViewport, throw-away saves, `boot_save_path_override`, fixed clock/day) through 5 representative shipping paths. Every path runs in 5 arms from the same seed save:
- **OFF**: plugins absent, the disabled-plugin fallback.
- **FULL**: counting spy plugins.
- **REDUCED**: spies with Reduced Effects on.
- **FAULT**: the spy Spark throws on every burst.
- **REAL**: the installed GameFeelFlow and Saltmire Spark autoloads.

The 5 paths:
- **won**: real Level 1 WON with native cleaning cues -> F010 bridge -> WON Results (WIN, reward rows, WIN video) -> Gift milestone ceremony handed off over Results -> HOME -> Home F012 MICRO.
- **gift**: 8 Gift milestone ceremonies (Gift videos) -> Gift 10 and 1000 claims -> Standard and Premium pack ceremonies with their opening videos.
- **meta**: Set Complete (set video) + Master Collection ceremonies.
- **robot**: Robot Unlock at L25 (MAJOR_UNLOCK) -> EQUIP.
- **acq**: Life Heart +1 (SMALL) + full refill (REWARD).

Real bug found and fixed: when a WON Results handed off to a ceremony (for example the Gift milestone the win reached), the ceremony's Flow video started while Scrubby's Results WIN video was still playing, so 2 decoders ran at once in every non-Reduced arm. `main._drain_results_ceremonies` now ends the Results video on its keyed still first, through the new `ResultsScreen.stop_result_video()`.

Files changed:
- `tests/m43_c005f_015_e2e_feel.gd` (new)
- `scripts/app/main.gd` (+1 line)
- `scripts/ui/results_screen.gd` (+5 lines)
- `TASKS.md` (queue line + checklist note)

Commits: 0363a368 (suite + fix), 31779d37 (docs/tasks).

## Acceptance criteria
1. [x] **Real shipping paths, FULL and REDUCED, plus the disabled-plugin fallback.** These ran through real app seams: WON Results, reward rows, Standard/Premium pack, set/master completion, Robot Unlock, Gift milestone, acquisition confirmation, gameplay completion, Home state change and cleaning comparison.
   - Every path/arm prints "path completed".
   - For the cleaning comparison, the won path asserts that the adapter got zero requests while the cells cleared (checked every 50 ticks before the terminal) and that `CleaningEffectsController` peak > 0 outside Reduced. Production cleaning stays native.
   - Feature unlock and world paths are not in the list. World stays gated as in C005F-007.
2. [x] **Both plugins only through the single adapter.**
   - In the spy arms, the real autoloads saw zero calls: no node was added under the real SaltmireSparkPool, and GFF fired no `effect_started` signals.
   - FULL spy Spark bursts equal the adapter plans with particles, for example won 8 and gift 18. GFF was never driven, because every target is a Control.
   - REAL: the number of bursts spawned by the installed Spark equals the FULL count, and all were freed.
   - The static scan finds plugin names only in `feedback_adapter.gd`, and there is one `FeedbackAdapter.new()`.
3. [x] **REDUCED does no plugin work.** In every path, REDUCED has 0 spy calls, the adapter owned no work at any sampled frame, and every REDUCED request is also a FULL request.
4. [x] **One-shot, no growth.**
   - No non-empty key is requested twice in any arm, including alongside the videos.
   - Resize to 1536x2048 and back, APPLICATION_FOCUS_OUT/IN, Home refresh and ceremony re-drain add no requests.
   - 1.5 s after the path, beyond every DURATION_CEILING_S: adapter `owned_count == 0`, 0 live Spark emitters, and subtree node count and processed tweens equal to OFF (233 nodes, 0 tweens in every arm).
5. [x] **Fail-open.**
   - In the FAULT arm, every burst raised the labelled injected SCRIPT ERROR (31 in total, equal to the FULL bursts).
   - Each path still completed with authority truth equal to OFF, and the same adapter requests as FULL.
   - The log has no other SCRIPT ERROR or Parse Error lines.
6. [x] **Presentation causes no economy change.** In every path, all arms' economy snapshot plus progression (excluding the hearts anchor and speed clock_high_water) is byte-identical to the OFF arm.
7. [x] **At most one video decoder playing.** Measured every frame. FULL reached exactly 1 on won, gift and meta, so video and feel ran together. This check failed before the fix: won showed max 2, the ResultVideo and the ceremony HeroVideo.
8. [x] **Owner visual gate not claimed.** The TASKS queue line says "automated e2e; owner visual gate pending phone review". The checklist row stays `[ ]`, with a note that the Godot AI viewport-matrix frame inspection and the owner visual gate are not automated and are PENDING owner phone review.
9. [x] **CI only if under ~3 min.** The runtime is 293 s headless, so the suite is kept local and not added to CI validate. This is recorded in TASKS and in the suite header.

## Validation
All runs use Godot 4.7.2 (`$GODOT`, headless), after `--import` once (tracked import churn restored with `git checkout -- .`).
- `tests/m43_c005f_015_e2e_feel.gd`: **LOCAL_PASS**. "M43 C005F-015 e2e feel evidence: PASS (6/6 cases, 0 fail)", exit 0, 264 ok lines, 293 s. The only diagnostics are 31 copies of the labelled injected line, `SCRIPT ERROR: Invalid call. Nonexistent function 'explode' in base 'Nil'.`
- Regressions for the touched files (exit 0, no unexpected diagnostics, last line PASS; injected lines only in suites that document them):
  - m43_c001b_won_results_visual 11/11
  - m43_c001r_c001_results_momentum 40/40
  - m43_master_c005_meta_ceremonies 32/32
  - m43_c001a_results_foundation 11/11
  - m42_navigation PASS
  - m43_c005f_phase4_terminal_home_micro 19/19
  - m43_c005f_phase2_results_pack_feel 22/22
  - m43_master_c005f_feel 10/10
  - m43_c005f_phase6_unlock_feel 8/8
  - m43_c005f_phase3_meta_rewards_acquisition 15/15
- `sb_polish_011_character_motion` (not in CI) is flaky: its "WON: intro crouch running" check reads the scale inside a 0.15 s timer window.
  - It failed in 6 of 13 runs on the fixed code while other factory Godot processes loaded the machine.
  - Interleaved pre-fix/post-fix runs: 8/8 PASS. The 4 post-fix runs after that: 4/4 PASS.
  - The case builds a standalone ResultsScreen, which never calls the new `stop_result_video`. I left the test unchanged; the flake is not caused by this change.
- `git diff --check`: clean. The tracked tree is clean. Only untracked `.uid`, `.import` and `.translation` files generated by the import remain; the worktree is deleted after the job.

## Log
### Round 1
- Read CLAUDE.md, the C005F-015 row and its sibling C005F rows, and the phase 1-6 and master feel suites. I reused their real-app helpers: the supply-plan WON driver, Gift claim, and the ceremony and pack tap drivers.
- Wrote the 5-path x 5-arm suite, with per-frame probes for decoders and Reduced-owned work, and `node_added` probes for Spark emitters and VideoStreamPlayers.
- The first runs exposed the 2-decoder bug on the WON -> ceremony hand-off. I fixed it in main/ResultsScreen.
- Dropped two expectations that did not match the shipping rules:
  - CLEAN NEXT MICRO is correctly held by the ceremony barrier.
  - Feature unlock ceremonies are only for new profiles, so `record_win` to L25 on a test save shows none.
- The suite is kept local because it runs about 5 min.
