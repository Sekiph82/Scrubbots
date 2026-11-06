STATUS: READY

# Build: SB-M55-018..023 + SB-M55-024..025 player-experience chaos suite

## Summary
New suite `tests/m55_player_chaos.gd` drives the real app (main.tscn in a 1080x2160 SubViewport, throw-away saves via `boot_save_path_override`, injected wall clock and local day, the test-double rewarded provider) through 13 chaos cases. Every case checks exact economy ledgers (each spend or grant happens once, and presentation changes no authority truth) and that the app returns to an unlocked HOME (no popup, Settings closed, no Home modal flag, no GameplayHost). Cases that repeat a workload also apply a steady-state leak rule: lap 2 must end exactly where lap 1 ended. The rule covers nodes, orphans, tweens and 7 authority-listener counts, and requires 0 adapter-owned work, 0 live Spark emitters and 0 playing video decoders. A built-in sensitivity check proves the rule fails on +1 of each item. No product bug was found and no product code changed.

Files changed:
- `tests/m55_player_chaos.gd` (new)
- `TASKS.md`: queue rows 140-141 set to DONE, checklist SB-M55-018..025 checked, M55 header line updated.

Commits: `f2e7dd2b` (suite), `1f1c93a3` (docs/tasks).

The suite is not in CI validate because it runs for ~244 s (the job said to add it only if fast). It is local-only, like m43_c005f_015_e2e_feel. Run it with `-- <case id>` to select cases.

## Acceptance criteria
1. [x] SB-M55-018 popup/purchase/reward spam:
   - Lap 1 and lap 2 both pass: 12 same-frame opens on every APP_SHORTCUT, Events/Robots/Ranks nav, Life and SB+ give exactly one popup, and 12 close or back taps leave none. Settings gets 12 opens and 12 backs.
   - Life +1 x20 gives one Heart and one 500 SB charge. Refill x20 gives one refill.
   - Shop buy x20 gives one confirm (`["shop","shop_confirm"]`), and confirm x20 gives one Tornado and one debit.
   - Daily claim x20 gives one claim and one celebration.
   - Rewarded Ads: free slot x20 gives one grant. Watch x20 gives one provider request. Three duplicate deliveries give one grant.
   - Exchange-all x20 gives one exchange.
   - Gift ceremonies: 3 were shown one at a time. Shortcuts and nav pressed over a ceremony opened nothing. Each ceremony CTA x20 acknowledged it once, and truth was unchanged apart from meta_ui.
   - Gift claim x20 opened one standard pack. Tapping it x25 per frame committed +3 cards once with 0 pending.
   - Leak rule passes (nodes 234, orphans 0, tweens 0, listeners [2,1,2,4,3,1,2]).
2. [x] SB-M55-019 background/foreground:
   - Gameplay: bots in flight, then PAUSED froze the runtime. After resume the level reached one WON and Results. Background over Results granted nothing. Two laps, leak rule passes.
   - Results: the WIN reveal was running when the app went to background twice and was resized. The reveal completed, truth was unchanged, no one-shot feel key repeated, and at most 1 video decoder ran.
   - Rewarded video pending across 2 background cycles: one delivery gave exactly one Heart, a duplicate was ignored, and the grant is durable on relaunch.
   - Shop confirmation open across background: nothing was spent. Confirming then bought once, and the background flush persisted it. No cloud transport exists, so the local save is the sync boundary.
   - Pack sent to background twice mid-OPENING: still exactly one commit (+3 cards).
   - Robot Unlock ceremony across 2 cycles: it stayed on top, parts were debited once, and the equip applied.
3. [x] SB-M55-020 triple loss:
   - Loss 1 (terminal emitted twice): count 1, one Heart, no Need a Hand.
   - 5 Retry taps gave one Retry.
   - Pre-action back, then loss 2: count 2.
   - Results Home, re-PLAY, then a post-action Pause->Home exit: still count 2 (an exit is not a failure).
   - Loss 3: Need a Hand opened exactly once. A background cycle and a Results re-show did not reopen it.
   - Loss 4 was suppressed.
   - Hearts consumed exactly 5 (4 losses + 1 exit).
4. [x] SB-M55-021 BottomNav churn: 2 laps x 200 switches (3 taps each) across events/robots/leaderboard/settings/home, while SB, card copies and Home badges kept updating. Each switch opened exactly one destination and back closed it. Leak rule passes.
5. [x] SB-M55-022 huge inventories (SB +999,999,000, Bot Parts 9,999,999, 9,999 of each booster, all 135 cards x999):
   - No label that was fine at normal values becomes clipped or off-screen on Home or on 10 destination popups. Scrolled rows are only checked for clipping.
   - Collection churn (3 x album, 15 sets, card detail) per lap passes the leak rule. Static memory grew +1,010,108 B (bound 4 MiB). The texture monitor reads 0 in headless, so it is not evidence.
   - A lap takes ~12.4 s (bound 20 s).
   - Exchange-all on ~134,865 extras: one exchange, +18,388,150 SB exactly.
6. [x] SB-M55-023 timer expiry with screens open:
   - Life popup: +899 s shows 00:01. +1 s regenerates exactly one Heart and the popup shows 4. A 1 h rollback changes nothing.
   - Timed 2x mid-level: expires on the HUD tick and drops to 1x. A 5000 s rollback keeps it expired.
   - Shop open across expiry: the next purchase starts a fresh 900 s.
   - Daily open across midnight: the stale view stays CLAIMED and grants nothing. Reopened, the new day claims once. A day rollback leaves nothing claimable.
   - Weekly event (fixture config, forfeit) expires with Events open: the stale claim x10 grants nothing and the screen refreshes to empty.
   - 49 h absence with the Shop open: the comeback summary waits behind the Shop and shows once after it closes. A second resume shows nothing.
7. [x] SB-M55-024 flapping:
   - The build has no network-status seam. Shop, Events, Ranks and cloud save are local-authority (CloudSave has no transport). This is documented in the suite header.
   - The two network-capable seams were flapped with Shop, Events, Ranks, Rewarded Ads and Life open (150 refreshes). The remote content transport flipped between offline (offline_using_cache) and online with a rejected manifest (failed_using_cache). Nothing was installed and the builtin launch truth stayed identical.
   - The rewarded provider flipped between available and unavailable: grants matched exactly the completed+verified deliveries (2 of 2).
   - Truth was unchanged for each non-Life surface, and the persisted save equals the live state.
8. [x] SB-M55-025 plugin chaos/leak, 2 laps with the real plugins:
   - Mid-WIN on Results: Spark autoload removed from the tree, Reduced Effects toggled 10x, background, then Spark re-added. Truth unchanged.
   - Gift ceremonies with a throwing Spark (labelled EXPECTED_FAULT_INJECTION) that then becomes absent: they completed and truth was unchanged.
   - 10 PLAY/back route churns with resize.
   - No one-shot key was requested twice. Leak rule passes and the Spark autoload is restored.

## Validation
- `$GODOT --headless --path . --import` once in the worktree. The tracked `.import` churn it caused was restored with `git checkout -- .`. project.godot was not modified.
- `$GODOT --headless --path . -s res://tests/m55_player_chaos.gd`: exit 0, last line `M55 PLAYER CHAOS (244504 ms): PASS`, 123 ok lines, 0 FAIL. The only SCRIPT ERROR lines are 3 labelled injected `SCRIPT ERROR: Invalid call. Nonexistent function 'explode' in base 'Nil'.` lines (the same fault arm m43_c005f_015 uses). Non-injected diagnostics: 0. Result: LOCAL_PASS.
- `git diff --check`: clean.
- No product file was touched, so no other suite needed re-running. Existing m55 suites are unaffected because the new file is standalone.
- Untracked import artifacts (`*.import`, `*.uid`, `*.translation` written by `--import`) remain in the worktree. The permission system denied deleting them. They are all untracked generated files; tracked state is clean. Removing the worktree clears them.

## Log
### Round 1
- Read CLAUDE.md, AGENTS.md, the TASKS rows, m55_core_chaos, m55_long_session, m43_c005f_015 (FAULT arm), m43_c004 (loss helpers), main.gd, ModalStack/BasePopup, AcquisitionFlow, ShopScreen, Daily/Profile/Collection screens, FeedbackAdapter, RemoteContentManager, RewardedGrantService.
- Wrote the suite and iterated on test-side issues:
  - L1 drive must follow the real-play driver.
  - First-clear pays once per level.
  - Earned packs present on the quiet Home and are drained.
  - Scrolled rows are excluded from the off-screen check.
  - RemoteContentManager needs a valid game_version in tests.
  - The Life popup reads provider availability on its own 1 s redraw.
  - The Gift milestones differ per lap.
- Added a leak-rule sensitivity check.
- Findings, none of them product bugs:
  - (a) A Daily popup left open across local midnight keeps showing CLAIMED until it is reopened. This is stale but safe: no grant and no double claim.
  - (b) There is no network-status seam to flap. Only the remote content transport and the rewarded provider are network-capable.
- Not added to CI: 244 s runtime.
