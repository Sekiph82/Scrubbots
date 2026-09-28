# M43-C001A — RESULTS FOUNDATION MATRIX V01

Date: 2026-09-28
Actor: Claude (implementer). No audit verdict claimed.
Prompt: `coordination/sessions/M43-C001A/task_prompts/SB-M43-C001A_RESULTS_FOUNDATION.md`
Focused evidence: `tests/m43_c001a_results_foundation.gd` (11/11 cases, 66 ok).

## 1. Architecture (M42 shell evolved, not replaced)

```text
M30 CompletionController.terminal_reached  (exact-once latch per attempt)
  1. ProductionGameplayHost._on_terminal_reached       (connected FIRST, in build())
       _drive_economy_terminal (latched once per attempt)
         pre  = TerminalRewardReceipt.capture(progression, economy)     read-only
         WON  -> FirstClearTransaction.commit (atomic, rollback)  [unchanged grant path]
         LOST -> Heart consume + streak reset + entitlement survives [unchanged]
         save = request_save()                                    [unchanged boundary]
         post = TerminalRewardReceipt.capture(...)
         _terminal_receipt = TerminalRewardReceipt.build(status, level, pre, post, commit, save)
  2. main._bind_terminal lambda -> nav.on_gameplay_terminal(attempt, status, level)
       nav payload stays {status, level, attempt}                 [M42 unchanged]
       route_changed -> main._results_model(payload)
            = payload + receipt (host getter, deep copy) + continue (GameplayLaunchResolver)
         -> ResultsScreen.show_model(model)                       pure presentation
```

One authority per concern:

| Concern | Authority | Results role |
|---|---|---|
| Terminal WON/LOST | M30 CompletionController | none |
| Grants (SB, Bot Parts, streak, Gift feed, entitlement) | FirstClearTransaction → RewardGrantService etc. | none |
| Durable save | AppState.request_save at terminal | reads `saved` flag only |
| Receipt | host `_terminal_receipt`, built once inside the latched terminal branch | reads a deep copy |
| Route | NavigationController (unchanged) | emits intents |
| Next frontier | GameplayLaunchResolver (unchanged) | reads availability |

## 2. Receipt contract (`scripts/economy/terminal_reward_receipt.gd`, schema `scrubbots.results_receipt.v1`)

| Field | Source (committed truth) |
|---|---|
| `status`, `level` | M30 terminal status, host `progression_level` |
| attempt | nav payload (`model.attempt`); receipt cleared by Retry restore |
| `first_clear` | `FirstClearTransaction.commit().ok` |
| `already_cleared` | commit reason `not_frontier` (forward-only record_win rejected) |
| `commit_reason` / `commit_stage` | `ok` / `not_frontier` / `rolled_back` + fault stage / `lost` |
| `difficulty` | class used by the commit |
| `rewards.first_clear_sb/_bot_parts` | `FirstClearRewardService.grant_first_clear` result |
| `rewards.win_streak_sb/_bot_parts` | `WinStreakService.process_first_clear_win` result |
| `wallet_delta` | wallet post − pre |
| `reconciled` | components == wallet delta (proves no hidden/unshown grant) |
| `streak`, `hearts`, `frontier` | before/after service reads |
| `gift_meter` | cycle before/after, cycles, `newly_queued` = occurrences returned by `GiftMeterService.add_streak_sb` (now surfaced via streak result `gift_milestones`) |
| `cards_delta` | Collection owned-count post − pre (0 on current terminal path) |
| `saved` | terminal save result `ok` |
| `reveal_queue` | data-only ordered celebration contract (§4) |
| `follow_ups` | downstream handoffs from committed state diffs only (§5) |

The stored receipt is `make_read_only()`; getters (`host.get_terminal_receipt()`, `ResultsScreen.get_model()`) return deep copies.

Not persisted (deliberate): Results never grants, so losing an unshown receipt (app killed at Results) loses presentation only. Every durable fact already lives in its own service (wallet, streak, Gift queue — a queued milestone stays claimable in the Gift Bar). Persisting pending ceremonies is an owner/M43-C005 decision.

## 3. Idempotency proof matrix

| Threat | Guard | Test assertion |
|---|---|---|
| Duplicate terminal signal (5×) + direct `_on_terminal_reached` (5×) | host `_economy_terminal_done` latch; receipt built only inside latched branch; nav terminal latch | receipt identical; economy/progression/reward tx count unchanged; 0 extra saves; 0 extra transitions |
| Repeated Results open/refresh (5× `show_model`, 5× route handler) | `_results_model` / `show_model` are pure reads | same as above; lines not duplicated |
| Rapid Continue (10 same-frame taps) | ResultsScreen Continue latch (first tap disables); nav leaves RESULTS on first launch | 1 intent, 1 transition, 1 host, attempt+1, 0 economy change |
| Late direct `continue_from_results()` (5×) | nav != RESULTS → `not_results` | 0 accepted |
| Stale Continue (attempt 1 intent while attempt 2 Results shown) | `continue_from_results(attempt)` must match shown attempt → `stale_results` | refused; no transition/host change; attempt-2 Continue then accepted once |
| Continue on LOST Results | status must be WON → `not_won` (was a latent path: a direct call used to launch) | refused |
| Level 10 → frontier 11 `CONTENT_MISSING` | Continue disabled + note; `no_next_content` re-shows the same model | 0 intents on taps; no mutation; host kept; HOME works |
| Continue launch failure (build error) | same committed model re-shown from ResultsScreen with re-resolved availability (re-arms Continue) | code path only (no production fault seam for host build) |
| Hidden Results keeping per-receipt nodes (M55 steady-state Home node count) | reward-line Labels freed on hide | `m55_long_session` Home node count back to baseline (found 169→173 before fix) |
| Results code calling grant APIs | source scan of `results_screen.gd`, `main.gd`, `terminal_reward_receipt.gd` | 0 hits for `.grant(`, `grant_first_clear`, `process_first_clear_win`, `FirstClearTransaction`, `.claim(`, `add_streak_sb`, `.credit(`, `.debit(`, `record_win` |

Sensitivity (each guard mutated, suite re-run, source restored byte-for-byte):

| Mutation | Result |
|---|---|
| remove stale-attempt check in `continue_from_results` | FAIL (2): stale refused / current accepted once |
| remove ResultsScreen Continue latch + disable | FAIL (1): 10 taps → 1 intent (nav alone still kept 1 transition — defence in depth) |
| receipt treats every WON as committed | FAIL (2): already-cleared / rolled-back truth |
| remove host terminal latch | FAIL (3): receipt overwritten, extra saves, line duplication |

## 4. Ordered celebration contract (SB-M43-010, data only)

`reveal_queue` order (only committed non-zero entries; `seq` 0..n-1):

1. `first_clear_sb` {amount}
2. `win_streak_sb` {amount, streak}
3. `bot_parts` {amount = first-clear + streak-milestone parts}
4. `gift_meter` {from, to, cycle_max, milestones[]}
5. `collection_cards` {amount} — only if cards were committed (never on today's terminal path)

Presentation never delays or owns the grant (grant + save completed before Results exists). The current technical shell renders every entry at once, which is the Reduced Effects path. Final timing/animation remains owner-gated (see readiness file).

## 5. Follow-up handoffs (SB-M43-012/013)

| Kind | Emitted when | Current terminal path |
|---|---|---|
| `gift_milestone` {occurrence_id, milestone, cycle, claim_surface: gift_bar} | occurrence newly returned by the Gift feed AND newly present in the persisted Gift queue | yes when streak SB crosses 10/50/250/500/1000 (test: 9 → 10) |
| `robot_unlock` | `RobotUnlockService.unlocked_count` increased | never (unlock is a player Bot-Part purchase, not a terminal grant) |
| `collection_set_complete` | completed set count increased | never (terminal grants no cards) |
| `master_collection_complete` | master claimed flipped | never |
| feature / world unlock | — | never emitted: no feature-unlock or world registry authority exists |

Results does not claim the Gift milestone; the canonical Gift Bar claim still grants exactly once (tested).

## 6. Task row status (implementer view; audit decides)

| Row | This cycle |
|---|---|
| SB-M43-001 Result model | receipt + Results model implemented/tested |
| SB-M43-002 Completion UI | technical shell only; final UI owner-gated |
| SB-M43-003 Streak presentation | data contract (`win_streak_sb` + streak) bound; styling gated |
| SB-M43-004 committed reward binding | bound to committed results; no Results grant |
| SB-M43-005 / 014 Continue | exact frontier, exactly once, stale/LOST/no-content safe |
| SB-M43-006 / 011 Replay | NOT implemented — owner gate (readiness §5) |
| SB-M43-007 / 008 No double reward / rapid tap | proven (§3) |
| SB-M43-009 Visual master | readiness spec only; NOT approved |
| SB-M43-010 Ordered celebration | data order contract only; choreography gated |
| SB-M43-012 Gift milestone handoff | receipt + follow-up; claim stays Gift Bar |
| SB-M43-013 downstream ceremonies | contract; only committed diffs; C005 ceremonies not built |
