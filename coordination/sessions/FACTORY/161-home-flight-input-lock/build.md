STATUS: READY

# Build: 161-home-flight-input-lock (SB-HOME-FLIGHT-LOCK-2026-11-17)

## Summary
Branch `factory/161-home-flight-input-lock`, one commit `9cd7974e` (not pushed).

- Home input lock: the flight's full-rect `RewardFlightLayer` (already a child of Home, alive for exactly
  the flight) now uses `MOUSE_FILTER_STOP`, so it swallows every touch/mouse on Home until it is freed.
  `main.handle_back()` returns `"none"` while Home is up and the flight is running. The lock is released by
  the existing completion path (natural end, finish, Reduced, Home hidden). It is never created when
  there is no receipt or the plan is empty, and it is freed together with Home. A safety SceneTreeTimer
  set to the sum of all step durations + 1.0 s calls `finish()`, guarded with `is_instance_valid(_home)`.
- Owner addition (orchestrator message, same commit): each reward kind now shows its icon plus a native
  "+N" Label at the screen centre. The Label inherits the project theme font, has an outline and uses
  `UiText.num`. Then K = min(N, 5) copies fly one after another, `STAGGER_S` 0.12 s apart and `FLY_S`
  0.5 s each, to the HUD target. Arrival i sets the counter to `from + N*i/K` (integer), so the last
  arrival lands exactly on the live value. Each arrival plays the REWARD pickup feel, but only during a
  live run. Reduced Effects, finish and Home hidden land the final state at once without feel. The lock
  covers the whole longer sequence. Reward amounts and the economy are unchanged; the plan still reads
  only the committed receipt and the Home view model.
- N chosen per kind:
  - Scrub Bucks: wallet delta (= counter increase).
  - Bot Parts: counter increase (to - from; equals the delta unless the pre-win value clamps at 0).
  - Gift Meter: counter increase shown (to - from; on a cycle wrap the counter climbs from 0).
  - Win Streak: streak after - before (normally +1).
  - Collection: `cards_delta` (cards won). There is no HUD counter, only K icons and the "+N" label.
- Files: `scripts/ui/home/home_reward_flight.gd`, `scripts/app/main.gd`,
  `tests/sb_phone_2026_11_12_e_win_home.gd` (new case `input_locked_during_flight`, 9 -> 10 cases),
  `tests/m43_c005_c005_reward_reveal_sequencer.gd` (step-shape assertion updated to fade + burst),
  `.github/workflows/android-family-first10.yml` (exact guard now `PASS (10/10 cases, 0 fail)`).

## Acceptance criteria
1. [x] One input lock, a full-rect blocker, that swallows taps; Back is ignored. Evidence: "one full-rect
   blocker over Home", "taps on PLAY / shortcut / nav during the flight do nothing { PlayButton: 0,
   Shortcut_daily: 0, Nav_robots: 0 }" (real `push_input` mouse press/release at each button centre),
   "Back ignored while locked".
2. [x] Released at the end and on every failure path. Evidence: "lock released with the last count-up";
   "empty receipt: no flight, no lock"; Reduced case "no flight: final state landed at once, no input
   lock"; Home hidden mid-flight still frees the layer (reveal_sequencer r03). The safety timeout is
   implemented (steps total + 1.0 s). It has no dedicated test.
3. [x] Ceremonies keep their order. Evidence: "Gift milestone ceremony opened on Home after the flight"
   and "no ceremony while the rewards fly" both still pass.
4. [x] Normal Home entry is never locked. Evidence: "normal Home entry: no lock layer"; relaunch case
   "relaunch: Home, no reward flight".
5. [x] Tests a-d, fail-before checked and CI guard added. With the source fix reverted the new case failed
   4 checks (PLAY tap counted 1 and started gameplay; no blocker; Back not ignored). After the fix:
   PLAY works after the flight (GAMEPLAY), Shortcut_daily responds (1). Nav_robots is disabled at L2,
   so it counted 0 in both phases. The CI guard is the exact `grep -qxF 'SB-PHONE-2026-11-12-E win home
   evidence: PASS (10/10 cases, 0 fail)'`.
   Addition evidence:
   - "+N" labels: `+51` SB, `+1` parts, `+1` gift, `+1` streak. Icon counts min(N, 5) = 5/1/1/1.
   - Per-arrival SB counter [1010, 1020, 1030, 1040, 1051], final 1051.
   - SB chip lands exactly on 1051.
   - Collection plan N = cards_delta (+7).
6. [x] Affected suites pass. Exact PASS lines are below.

## Validation (LOCAL_PASS, Godot 4.7.2 headless, after one-off `--import`)
- `SB-PHONE-2026-11-12-E win home evidence: PASS (10/10 cases, 0 fail)` exit 0, 0 SCRIPT ERROR
- `M42 home evidence: PASS` exit 0
- `M42 navigation evidence: PASS` exit 0
- `M42 opening evidence: PASS` exit 0
- `M43-C002-C001 popup / modal / Pause foundation evidence: PASS (23/23 cases, 0 fail)` exit 0
- `M43-C005-C005 reward reveal sequencer evidence: PASS (12/12 cases, 0 fail)` exit 0, 0 SCRIPT ERROR
- `M43-C005F-PHASE4 terminal bridge + Home micro feel: PASS (19/19 cases, 0 fail)` exit 0. Its 3
  SCRIPT ERRORs are the suite's documented injected FaultySpark `explode` faults.
- `M43 C005F-015 e2e feel evidence: PASS (6/6 cases, 0 fail)` exit 0. All SCRIPT ERRORs are the
  documented EXPECTED_FAULT_INJECTION `explode` faults.
- `M43 C005 feature unlock ceremony evidence: PASS (9/9 cases, 0 fail)` exit 0
- `M43-C001A results foundation evidence: PASS (11/11 cases, 0 fail)` exit 0
- `M43-C005F-PHASE2-R01 earned pack runtime: PASS (22/22 cases, 0 fail)` exit 0 (4 injected `explode` only)
- `M43-C005F-PHASE2 results + pack feel: PASS (9/9 cases, 0 fail)` exit 0 (4 injected `explode` only)
- `M43 master C005 meta ceremonies evidence: PASS (33/33 cases, 0 fail)` exit 0
- `M44 CONTEXTUAL COACH: PASS (7/7 cases, 0 fail)` exit 0
- `git diff --check` on the changed files: clean.

## Log
### Round 1
- Implemented the input lock (layer `MOUSE_FILTER_STOP`, Back guard, safety timeout) and test case
  `input_locked_during_flight`. Confirmed it fails before the fix and passes after.
- Owner addition via the orchestrator: replaced fly-then-count-up with "+N" plus min(N, 5) staggered
  copies and per-arrival counter steps. Updated the reveal-sequencer suite's step-shape check to match.
  Folded everything into the single commit (amended, not pushed).
- Not edited: TASKS.md (per instruction). Flight timing changed only where the owner addition requires
  it. Home art, gameplay and economy are untouched.
- Worktree note: `--import` left the usual `.import` EOL churn and untracked `.uid`/`.import` files.
  None were staged. They were not cleaned (no `git clean`); they go away when the worktree is deleted.
