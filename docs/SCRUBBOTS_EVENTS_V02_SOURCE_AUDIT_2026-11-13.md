# ScrubBots Events V02 Source and Asset Audit

**Audit task:** SB-EV02-001
**Source revision:** `origin/main` / `39d65814ab7be53290692c7ab616a732f1499fdf`
**Worktree:** isolated `factory/158-events-v02-audit` worktree at the revision above; clean at job start. After Godot import inspection, current status has 696 untracked `.uid` and 485 untracked `.import` sidecars. Tracked `.import` sidecars that showed import-only line-ending churn were restored; current status has 0 tracked `.import` modifications. No generated sidecars are in this commit. No code, V1 event config, or gameplay data was changed.
**Scope:** static source/config/art inventory. No Godot visual run, screenshot, or test suite is claimed for this documentation-only audit.

## Executive findings

- V02 catalog is a specification only: schema `scrubbots.events.v02.catalog.specification`, version 2, `runtime_enabled: false`, exactly 24 unique event IDs, 24 unique declared hero paths, 24 unique declared icon paths, 3 tutorial definitions each (72 data states; UI states are not yet implemented), 3–5 active events, and expected unlock level 30 (`data/config/events_v02_catalog.json:1-31,33-1342`). The catalog also declares assets 1024×1024 (heroes) and 1170×2532 (portrait master).
- Current runtime is V1 weekly event + First-Try Cleanup. `events_v1.json` has no weekly definitions and `first_try_cleanup: null`; no V02 schedule or production payouts are active (`data/config/events_v1.json:1-9`; `scripts/economy/event_service.gd:16-27`).
- The current gameplay terminal supports first-clear, attempt/first-try and committed booster-use signals. It does not provide the V02 authoritative pixel counts, per-color cleaned counts, or a durable per-event-instance receipt identifier. Do not implement those from the speculative analytics counter.
- Existing Events entry, deep-link, join and claim paths consult the shared Events L30 feature gate. Calendar/details/tutorial are not yet V02 surfaces; the existing card is Weekly-specific (`scripts/app/main.gd:399-419,488-504`; `scripts/economy/production_action_facade.gd:260-276`; `scripts/ui/components/ui_event_card.gd:18,46`).
- All requested V02 final image outputs are absent at this revision; legacy images below are rejected references, not approved final art. The optional archive is unavailable at the specified intake locations and is expressly nonblocking.
- No payout should be enabled. V02 reward quantities, reward expiry, schedules, rival performance/tie-breaking and unresolved objective thresholds remain owner TBD or explicitly labeled implementation proposals.

## Source behavior and implementation gaps

### Event service, V1 config, progress, claims, and persistence

`EventService` loads only `res://data/config/events_v1.json`, schema `scrubbots.events.v1`; its state is weekly ID progress/claimed milestones plus one First-Try state. Weekly windows are fixed to seven days (`scripts/economy/event_service.gd:16-27,37-80`). `_phase` selects upcoming/active/ended from `start_ts` and the fixed `WEEK_S`; `list` keeps active/upcoming and ended-with-claimable entries; `view` derives milestone claimability and countdowns (`:82-118`). There is no V02 instance ID, configured duration, rotating 24-type schedule, lifecycle instance record, or cross-event state.

`claim_weekly` grants a reached milestone using transaction ID `event:<event_id>:<index>` before marking its index claimed; First-Try uses `event:first_try:<id>` (`:120-168`). These keys are not instance-scoped and the weekly policy has only forfeit/claim-after-end; V02 requires stable `instance_id`, expiry semantics and dedupe bound to instance/receipt. On terminal, loss leaves weekly progress unchanged, a win adds one to each active weekly event, and First-Try run uses the `first_try_attempt` boolean (`:170-179`). There is no catalog-metric dispatch.

The shipped V1 config says no event is scheduled and leaves First-Try null (`data/config/events_v1.json:1-9`). Event service snapshots are version 1 with `weekly`/`first_try`, validated progress and unique claim indices (`scripts/economy/event_service.gd:190-219`). Aggregate economy persists events under `events`; import applies a missing section as null/fresh and rolls back on invalid import (`scripts/economy/economy_services.gd:193-220,227-303`). A V02 schema/versioned migration and restart/import contract is still required.

The existing focused Events tests are in `tests/m43_master_c010_meta.gd:233-364,440-477`: empty state, active weekly progress, replay/loss exclusion, single-claim behavior, expiry policies, First-Try and imports. Release-gate coverage for L29/L30 is in `tests/m60_release_gates.gd:523-560`. These do not validate 24 V02 IDs, instances, pixel/color metrics, virtual teams, 72 tutorials or V02 claim receipts.

### UI, navigation, and L30 entry coverage

`ProfileScreens.open_events` creates the Events popup, and `refresh_events` renders `ev.list()` plus First-Try using `UiEventCard` (`scripts/ui/profile/profile_screens.gd:407-465`). `UiEventCard` hard-codes `event_weekly_hero.png` and `EVENT_WEEKLY_TITLE`, although it accepts phase/progress for the existing weekly template (`scripts/ui/components/ui_event_card.gd:1-54`). It is not event-ID-driven and has no V02 calendar, detail, tutorial, or upcoming rotation view.

Events is configured at level 30 (`data/config/feature_unlocks_v1.json:15`). `FeatureUnlocks.is_unlocked` compares campaign frontier to the config table; UI is expected to call `AppState.feature_unlocked` (`scripts/progression/feature_unlocks.gd:8-38`). Main Home entry and deep-link paths use `_entry_locked` (`scripts/app/main.gd:399-419,486-504`); Home nav/shortcut has gate helpers (`scripts/ui/home/home_screen.gd:1347-1400`); the action facade gates weekly claim, First-Try join and claim (`scripts/economy/production_action_facade.gd:260-276`). Existing L29/L30 integration tests exercise nav/deep link (`tests/m60_release_gates.gd:526-560`).

No V02 calendar/details/tutorial controls exist yet, so their lock behavior (including direct calls, imported saves and fresh saves) remains unverified. The shared gate is fail-open on malformed config/unknown IDs by current contract; preserve that general owner policy and do not duplicate level 30 in screen code.

### Authoritative gameplay metrics and receipt gaps

The production host authenticates clear events and runs its first-clear transaction at terminal (`scripts/gameplay/runtime/production_gameplay_host.gd:674-761`). It calls `PlayerRecords.on_progression_terminal(level, won, boosters_used, streak)` before feeding EventService; `PlayerRecords` derives first attempt from saved `attempts_on_level`, tracks first-try win run and resets that run on a non-qualifying attempt (`scripts/gameplay/runtime/production_gameplay_host.gd:917-928`; `scripts/economy/player_records.gd:31-59`). Booster activations increment `_attempt_boosters` at the committed action path; the terminal reports the count and analytics includes a count bucket (`production_gameplay_host.gd:143,451,606,731-761,797-810,951-957,1774`). This is the source-backed signal suitable for `win_without_booster_usage`, after a receipt/instance adapter dedupes it.

`TerminalRewardReceipt` schema is `scrubbots.results_receipt.v1`; it records terminal status, level, first-clear/already-cleared facts, economy deltas, frontier and related committed reward fields (`scripts/economy/terminal_reward_receipt.gd:26,59-106`). It does **not** currently expose a durable unique receipt ID, event instance IDs, `cleaned_active_pixels`, per-color pixel counts, or booster count as receipt fields. Host analytics computes progress from artwork cell counts (`production_gameplay_host.gd:797-810`), which is not an authoritative V02 cleaned-pixel metric. Clear callback currently receives `_color_id` but discards it for completion evaluation (`:674-680`). Board/clear history must be inspected in EV02-003 to establish an authoritative count without changing the clearing mechanic; pixel/color event progress is not currently proven.

For V02 semantics, event derivation must consume an authenticated committed terminal/result plus proven clear measurements. It must exclude losses/replays as specified, enforce first-attempt-vs-first-clear correctly, and dedupe once per instance and receipt. A stable replay-safe ID scheme is an implementation proposal pending design/tests, not an existing field.

### Reward grant and payout gate

`RewardGrantService.grant(tx_id, rewards)` validates supported handlers and remembers applied transaction IDs; snapshots persist the ledger (`scripts/economy/reward_grant_service.gd:22-26,54-123`). Aggregate economy snapshot/import includes reward service and events, with rollback on malformed component snapshots (`scripts/economy/economy_services.gd:193-303`). Existing `events_v1.json` allows only these existing economy keys: `scrub_bucks`, `bot_parts`, `standard_card_packs`, `premium_card_packs`, `random_any_booster_charges`, `selected_booster_charges` (`data/config/events_v1.json:5-8`). No new event currency is approved.

V02 catalog reward quantities and expiry are null; event schedules are null, catalog status is specification-only and tutorial reward steps set `production_claims_enabled: false` (`data/config/events_v02_catalog.json:33-1342`). Five-event simultaneous reward values must be modeled and tested before production grant enablement. Any reward amount, duration or expiry default proposed by implementation must be labeled **IMPLEMENTATION PROPOSAL / TBD, NOT OWNER-APPROVED**. Existing reward values elsewhere in `economy_rewards_v1.json` are not authorization to duplicate them as event rewards.

## 24-event catalog compliance inventory

The following rows preserve every catalog ID, metric, owner condition and participant count without merging or renaming event types. Every row has exactly three tutorial definitions in the catalog; every catalog `hero_path`/`icon_path` is unique and ID-matched (`data/config/events_v02_catalog.json`, row citations below). Catalog duration is explicitly a proposed value with `IMPLEMENTATION_PROPOSAL_NOT_OWNER_APPROVED`; it is not an approved schedule. Null schedule/reward fields remain TBD.

| # | Stable ID | Metric | Owner condition / rule | Participants | Duration status | Catalog evidence |
|---:|---|---|---|---|---|
| 1 | `scrub_sprint` | `first_clear_new_level` | 15 new levels | 4 virtual + player (5) | **PROPOSAL/TBD** 48h | `data/config/events_v02_catalog.json:33-87` |
| 2 | `first_brush_race` | `first_attempt_new_level_win` | 3 or 5 per instance | 4 virtual + player (5) | **PROPOSAL/TBD** 48h | `data/config/events_v02_catalog.json:88-142` |
| 3 | `scrubbots_royale` | `first_attempt_new_level_win` | 5 rounds; per-round thresholds **TBD** | 99 virtual (100 total) | **PROPOSAL/TBD** 72h | `data/config/events_v02_catalog.json:143-197` |
| 4 | `golden_brush_championship` | `first_clear_new_level` | 8-player bracket / 3 elimination rounds | 7 virtual (8 total) | **PROPOSAL/TBD** 72h | `data/config/events_v02_catalog.json:198-252` |
| 5 | `weekly_scrub_league` | `cleaned_active_pixels_on_new_levels` | Weekly ranking / 20 entries | 19 virtual (20 total) | **PROPOSAL/TBD** 168h | `data/config/events_v02_catalog.json:253-307` |
| 6 | `weekly_cleanup_challenge` | `first_clear_new_level` | 3 / 7 / 12 / 20 milestones | Solo | **PROPOSAL/TBD** 168h | `data/config/events_v02_catalog.json:308-362` |
| 7 | `perfect_first_clean` | `first_attempt_new_level_win` | 3 / 5 / 10 milestones | Solo | **PROPOSAL/TBD** 72h | `data/config/events_v02_catalog.json:363-417` |
| 8 | `sparkling_streak` | `consecutive_qualifying_wins` | 3 / 5 / 7 / 10 checkpoints; loss rollback is event-only | Solo | **PROPOSAL/TBD** 72h | `data/config/events_v02_catalog.json:418-472` |
| 9 | `stain_busters` | `cleaned_active_pixels` | Target **TBD after balancing** | Solo | **PROPOSAL/TBD** 72h | `data/config/events_v02_catalog.json:473-527` |
| 10 | `pure_scrub_challenge` | `win_without_booster_usage` | 3 / 5 / 10 | Solo | **PROPOSAL/TBD** 72h | `data/config/events_v02_catalog.json:528-582` |
| 11 | `scrub_squad_tournament` | `virtual_team_qualifying_level_wins` | Team size 10; win threshold **TBD** | 10-person virtual team | **PROPOSAL/TBD** 72h | `data/config/events_v02_catalog.json:583-637` |
| 12 | `clean_team_treasure` | `virtual_team_cleaning_points` | Team size 10; milestones **TBD** | 10-person virtual team | **PROPOSAL/TBD** 72h | `data/config/events_v02_catalog.json:638-692` |
| 13 | `scrub_relay` | `virtual_team_sequential_clears` | Team size 5; stage thresholds **TBD** | 5-person virtual team | **PROPOSAL/TBD** 48h | `data/config/events_v02_catalog.json:693-747` |
| 14 | `mega_stain_cleanup` | `virtual_team_cleaned_active_pixels` | Team size 20; target **TBD** (50,000 is example only) | 20-person virtual team | **PROPOSAL/TBD** 72h | `data/config/events_v02_catalog.json:748-802` |
| 15 | `scrubbys_cleanup_workshop` | `first_clear_new_level` | Milestones **TBD**; SB/booster reward category | Solo | **PROPOSAL/TBD** 168h | `data/config/events_v02_catalog.json:803-857` |
| 16 | `robot_parts_recovery` | `first_clear_new_level` | Milestones **TBD**; Robot Parts | Solo | **PROPOSAL/TBD** 72h | `data/config/events_v02_catalog.json:858-912` |
| 17 | `lost_card_rescue` | `first_clear_new_level` | Milestones **TBD**; Card Pack | Solo | **PROPOSAL/TBD** 72h | `data/config/events_v02_catalog.json:913-967` |
| 18 | `seasonal_scrub_festival` | `seasonal_qualifying_level_progress` | Seasonal thresholds/config **TBD** | Solo | **PROPOSAL/TBD** 168h | `data/config/events_v02_catalog.json:968-1022` |
| 19 | `master_cleaner_quest` | `qualified_cross_event_objectives` | Required objectives/dedupe **TBD** | Solo | **PROPOSAL/TBD** 168h | `data/config/events_v02_catalog.json:1023-1077` |
| 20 | `scrub_season_pass` | `first_clear_new_level` | Free track only; thresholds **TBD** | Solo | **PROPOSAL/TBD** 672h | `data/config/events_v02_catalog.json:1078-1132` |
| 21 | `color_scrub_rush` | `cleaned_pixels_by_color` | Target colors and thresholds **TBD** | Solo | **PROPOSAL/TBD** 48h | `data/config/events_v02_catalog.json:1133-1187` |
| 22 | `scrubbys_rescue_mission` | `first_clear_new_level` | Story milestone thresholds **TBD** | Solo | **PROPOSAL/TBD** 72h | `data/config/events_v02_catalog.json:1188-1242` |
| 23 | `world_cleanup_cup` | `first_clear_new_level_cleanup_score` | 20 virtual rivals; scoring weights **TBD** | Player + 20 virtual (21 entries) | **PROPOSAL/TBD** 168h | `data/config/events_v02_catalog.json:1243-1297` |
| 24 | `mystery_scrubbox_hunt` | `first_clear_new_level` | Chest thresholds **TBD** | Solo | **PROPOSAL/TBD** 72h | `data/config/events_v02_catalog.json:1298-1342` |


## Canonical robot sources and reference-image status

The owner-approved roster `data/config/robot_roster_v1.json` identifies these ten master PNGs via each robot record assets.master field. Hashes below were computed from checked-out PNG bytes with SHA-256. `.import` sidecars are excluded from the canonical identity list.

| Robot | Canonical repository PNG | SHA-256 |
|---|---|---|
| Scrubby | `assets/ui/final/characters/scrubby/scrubby_master.png` | `199ffe78e5371406f85bb27e4929274f2a908821d6292734cb5ee824f093a030` |
| Moppy | `assets/ui/final/characters/robots/moppy/moppy_master.png` | `4b6f154cb62b5d357885e2a7bec92e28516b9a8013df60c3313beb563ed904ff` |
| Bubbles | `assets/ui/final/characters/robots/bubbles/bubbles_master.png` | `439fa4089a08bd1c85610e8ab78265705cdd03d9c0d4a2f0b29c16e95ada0f24` |
| Spark | `assets/ui/final/characters/robots/spark/spark_master.png` | `bb3bd4cf93259bc5e542acdf2a5b2c33d809602a54da2b77ef0b828c6bc3a36c` |
| Squeegee | `assets/ui/final/characters/robots/squeegee/squeegee_master.png` | `8424bd817cf7f8a06721140e483d6e996e43895d7e6936b2754d9cb5f5ec87f7` |
| Dusty | `assets/ui/final/characters/robots/dusty/dusty_master.png` | `1c83bd3700fc7e24b102a31201d8913e7508eb23440c39e5da37a281e58c7f68` |
| Rinse | `assets/ui/final/characters/robots/rinse/rinse_master.png` | `c3509ec63c76a806cad07fd7a036b68ec9781060762761b396e1d44c991128ae` |
| Polly | `assets/ui/final/characters/robots/polly/polly_master.png` | `187e5ccbb4ac915d84e1da95281b7f4536c26ab93447c9289cb0c2ffd9909431` |
| Clippy | `assets/ui/final/characters/robots/clippy/clippy_master.png` | `e2e6a65edec10375978d679339d021ca80aa235c00e690f9dce16446d6f6509f` |
| Atlas | `assets/ui/final/characters/robots/atlas/atlas_master.png` | `dc07b561cd977cbd0f043cf97d718ca9fd79736712fd49fd14b3966a225d6d41` |

The visual intake explicitly marks the two event masters as legacy / owner-rejected robot anatomy, not final. Hashes from this checkout:

| Reference path | Status | SHA-256 |
|---|---|---|
| `assets/ui/generated/masters/scrubbots_events_master_v01.png` | Legacy design reference; rejected anatomy; not final | `2a5377963e7221bbf4bacd76e49243e5eb969c95c1894248c231d49d7883bdd3` |
| `assets/ui/final/events/event_weekly_hero.png` | Legacy Weekly reference; rejected anatomy; not final | `1d99b565704c8cdc44c5e04700d923408dea8cae9b5e2850213afbdc4de3677a` |
| `assets/ui/final/characters/scrubby/scrubby_master.png` | Canonical Scrubby identity master (included above) | `199ffe78e5371406f85bb27e4929274f2a908821d6292734cb5ee824f093a030` |

Optional archive `scrubbots_events_master_references.zip`: not present at `_incoming/scrubbots_events_master_references.zip` in the worktree or `C:\Users\sekip\Desktop\ScrubBots\_incoming\scrubbots_events_master_references.zip` at audit time. Per intake/owner plan it is optional and nonblocking; no substitute was downloaded or fabricated.

## V02 output inventory

Paths below are the catalog/intake-defined production destinations. Existence was checked in this checkout; no V02 outputs are present. Legacy Weekly art is not counted as an output.

- Heroes (0/24 present; each target 1024×1024): `assets/ui/final/events/heroes/<id>.png` for every table ID above.
- Event icons (0/24 present; unique file per ID): `assets/ui/final/events/icons/<id>.png` for every table ID above.
- Shared backgrounds/decorations (0/7 present): under `assets/ui/final/events/backgrounds/` and `assets/ui/final/events/decorations/`. Intake defines 3 racing themes, 2 cooperative backgrounds and 2 reward-track decorations, but does **not** assign seven exact filenames; filename assignment is **TBD** and must not be invented as owner-approved. Both directories are currently absent.
- Portrait master (0/1 present; target 1170×2532): `assets/ui/generated/masters/scrubbots_events_master_v02.png`.

No dimensions or hashes are applicable to absent files. No visual asset was accepted or claimed complete in this audit.

## Proposed dependency order for SB-EV02-002..014

This is an execution dependency recommendation, not a change to owner-approved event rules. Any unspecified balancing/scheduling defaults stay labeled **PROPOSAL/TBD**. Keep payout disabled until EV02-007's five-active-event economy model and its tests pass.

1. **EV02-002** — versioned 24-event instance/config/rotation model, 3–5 active, lifetimes and upcoming/ended continuity. Depends on audit. Leave unresolved schedule/fairness specifics explicit.
2. **EV02-003** — authoritative terminal receipt/metric adapter, first-clear/first-attempt/booster/streak facts, proven pixel/color count, per-instance dedupe and migration. Must precede event metric progress.
3. **EV02-004** — L30 gates for all V02 entry surfaces, fresh/legacy/imported saves, and L29/L30 proofs. Can proceed against 002/008/009 UI seams; never duplicate level values.
4. **EV02-005** — deterministic, clearly virtual rival/team model and roster presentation, using approved robot portraits; no real-player claims or pay acceleration.
5. **EV02-006** — implement event-specific eligibility and progress using 002 config + 003 receipts, including event-only streak rollback and exact milestone semantics.
6. **EV02-007** — economy simulation with up to five concurrent events, versioned existing-key reward proposals, receipt-bound idempotent claims and expiry policy tests. No production grants until validated and peer-reviewed.
7. **EV02-008** — native responsive event list/cards/details/calendar, dynamic event IDs/art, localization, safe areas, reduced motion and lazy texture loading; requires config/service shapes from 002/006.
8. **EV02-009** — reusable three-screen tutorial with all 72 data states, actual gameplay board visual, gated details and reward flow; requires 008 plus 006/007 contracts.
9. **EV02-010** — independently compose/inspect 24 hero PNGs from canonical robots, each 1024×1024; per-file anatomy/spelling QA.
10. **EV02-011** — 24 unique icons + 7 background/decor files, individually validated; settle shared filenames as implementation path naming, not new mechanics.
11. **EV02-012** — create new 1170×2532 portrait master from approved robots/native layout; compare to actual app and reject legacy anatomy.
12. **EV02-013** — bind V02 IDs to actual artwork with missing-art fallback and 3–5 visible texture budget; verify portrait 720×1520 and 1170×2532 in EN/TR.
13. **EV02-014** — integrated policy/metrics/schedule/reward/import/lock/tutorial regression, required actual Godot captures, peer review and remote verification. Only after proofs may an explicitly authorized runtime activation step be considered; this audit does not enable it.

**Screenshot/test boundary:** source review confirms the test seams above, but this task did not run Godot, capture the Events screen, or run automated tests. Required portrait screenshot/animation/touch QA is outstanding for later implementation/integration tasks.
