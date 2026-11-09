STATUS: READY

# Build: 141-ads-mock-cadence (SB-M57-001..011, provider-independent part)

## Summary
Branch `factory/141-ads-mock-cadence` (base origin/main f521dcd2) adds an ad seam built the same way as factory 138's store seam:
- `scripts/economy/ad_provider.gd` (new): the `AdProvider` seam. It extends the M43-C003 `RewardedAdProvider` and adds `set_banner(visible)` and `show_interstitial(placement) -> bool`, so one provider object (later AdMob, SB-M57-022) handles all three ad kinds. The base class is the shipping null provider: no SDK, no network, nothing shown.
- `scripts/economy/ad_service.gd` (new): `AdService`. It counts finished plays (`on_play_finished`). `interstitial_due()` is true when `plays - last_interstitial >= 5` and `store.ads_allowed("interstitial")` allows it. `try_interstitial()` asks the provider and remembers the play count when an ad is actually shown; an ad the provider cannot show stays due. `update_banner()` passes `store.ads_allowed("banner")` to the provider, and `allowed(kind)` is the store seam. `set_provider` hands the same object to `RewardedGrantService`. Its strict snapshot/import (economy section `ads`; a missing section means a pre-ads save with 0 plays) is persisted with the M40 save.
- `scripts/economy/economy_services.gd`: wires `ads` (constructor, snapshot, import).
- `scripts/gameplay/runtime/production_gameplay_host.gd`: the latched WON/LOST terminal calls `ads.on_play_finished()` once per attempt, before the existing terminal save. Any finished level, win or loss, counts.
- `scripts/app/main.gd`: `_between_levels_ad()` runs only at Results -> Continue and Results -> Retry, after the heart gate and before the next attempt launches. It never runs during gameplay. When an ad was shown it marks the save dirty. The existing No Ads banner callback also calls `ads.update_banner()`.
- `scripts/economy/production_action_facade.gd`: `start_rewarded` / `start_rewarded_daily` ask `ads.allowed("rewarded")` first (`ads_disallowed` otherwise). Grants are unchanged: only `RewardedGrantService.resolve` on a verified `completed` view, under `rewarded:<token>` / `daily_rewarded:<day>:<slot>`. No new rewards were invented, because the existing Heart, booster and daily-slot placements already go through this seam.
- `tests/m57_ads_cadence.gd` (new, 6 cases); CI validate list + exact 6/6 guard in `.github/workflows/android-family-first10.yml` (append-only).
- Existing tests aligned: `m43_c003_c001_acquisition`, `m43_r15_owner_remediation` and `m60_release_gates` now expect the default provider to be the null `AdProvider` (a subclass of the old base). `m43_c001a_results_foundation`'s "economy untouched" helper ignores the `ads` play counter, because a finished replay or rolled-back level is still a play and the counter is not a reward. `docs/RELEASE_GATES.{json,md}` were regenerated (`-- --write`): one evidence line changed, verdicts unchanged, SB-M60-004 still PASS.
- Docs: `AGENTS.md` "Ads" section, `docs/PRIVACY_DATA_INVENTORY.md` (new save fields: finished-play count + play count at last interstitial), `TASKS.md` (queue row SB-M57-001..011 DONE provider-independent; detail rows 001, 003..008, 010, 011 [x]; 002 and 009 PARTIAL; SB-M57-022 READY with the AdMob provider pointer).

Commits: e7caf828 (code + test), 89ed2e0e (CI + AGENTS + privacy), 3653fcff (TASKS), 11c2d54b (test alignment + release-gates evidence), 54871ca9 (TASKS hashes/evidence). Not pushed.

## Acceptance criteria
1. [x] Ad provider seam with a null/mock default, no SDK and no network: `ad_provider.gd` base class does nothing. m57 a01: default = null `AdProvider`, the same object `RewardedGrantService` uses; with 5 plays the ad is due but nothing is shown, and no rewarded video is offered. m60 SB-M60-004 `no_provider` PASS.
2. [x] Plays 1-4 give no interstitial, play 5 does, and win and loss both count. m57 a02 (unit): shown at plays [5, 10, 15]; when there is no fill the ad stays due and the next transition shows it. m57 a03 (real app root, real terminals LOST/WON/LOST/WON/LOST): plays 1..5 counted, no interstitial after plays 1-4, nothing during gameplay or at the 5th terminal, exactly one at Results -> Retry after play 5, none at play 6 -> Continue.
3. [x] Every decision asks `StoreService.ads_allowed(kind)`: m57 a05 swaps in a store that denies everything, and rewarded, interstitial due and try all return false. m57 a03: the facade `start_rewarded` / `start_rewarded_daily` return `ads_disallowed` under that store.
4. [x] No Ads blocks the banner and interstitial but not rewarded. m57 a04: banner `[true]` before No Ads, then `false` after the entitlement; 10 plays give no interstitial; a rewarded video still starts, and its completion grants +1 Tornado charge.
5. [x] Rewarded grants only on a completed view, never on cancel or fail. m57 a05: cancelled / skipped / failed / timeout / completed-but-unverified give no charge and no ledger entry; a verified completion gives +1 Selector under `rewarded:<token>`; a duplicate callback grants nothing. m57 a03: app facade cancel -> no charge, complete -> +1 (RewardedGrantService).
6. [x] Counter persisted. m57 a06: snapshot section `{plays: 7, last_interstitial: 7}` survives a JSON round trip; a pre-ads save imports with 0; malformed sections (negative, last > plays, fractional, missing key) fail closed with state unchanged; on the real app, a LOST gives 1 play, and after a reboot on the same save it is still 1.
7. [x] Interstitial wired at the level-finished -> next transition and invisible with the null provider: `main.gd` `_between_levels_ad()` in `_continue_from_results` / `retry_from_results`. All existing Results / navigation suites pass (below).
8. [x] Economy is not mutated from UI: the play count changes only in the host terminal commit, and grants happen only in `RewardedGrantService`. `main.gd` only asks AdService.
9. [x] CI: `m57_ads_cadence` appended to the validate list with the exact guard `M57 ads cadence evidence: PASS (6/6 cases, 0 fail)`.
10. [x] `docs/PRIVACY_DATA_INVENTORY.md` updated for the new save fields.

## Validation
Godot 4.7.2 console exe (`--headless --path <wt> --import` once; throw-away `user://` saves, all deleted by the suites). LOCAL_PASS via `python tools/run_suites.py` (CI PASS/FAIL rule: exit 0, no SCRIPT ERROR / Parse Error, last line PASS, exact guard):
- m57_ads_cadence PASS (6/6), m57_store_products PASS (9/9), m43_master_c006_shop PASS (15/15), m43_c003_c001_acquisition PASS (34/34), m43_r15_owner_remediation PASS (18/18), m43_r15_001_r01_sequential_unlock PASS (14/14), m43_c001a_results_foundation PASS (11/11), m42_navigation PASS, m43_ranks_weekly PASS (7/7), m56_analytics_taxonomy PASS (27/27), m60_release_gates PASS (6/6, verdicts unchanged); aggregate=PASS (11/11).
- Direct runs: m40_save_system, m40_v02_safety, m40_v03_canonical, m40_v04_bootstrap, m39_v03_integration, m39_v04_integration, m43_146_notification_permission (8/8), m28_c002_c003_r01_remediation (24/24) all PASS (exit 0, no diagnostics).
- m43_c001r_c001_results_momentum (not in CI) FAIL with 6 fails ("L30 coming soon" / NextCleanup outside panel). This is pre-existing: the same 6 fails reproduce with the four changed scripts checked out at base f521dcd2. It is unrelated to ads.
- `git diff --check` clean on all changed files. After the runs: `git checkout -- .` plus removal of untracked import artifacts (.uid / .import / .translation); `git status --porcelain` is empty.
- The suites print the usual "ObjectDB instances leaked / resources still in use" exit warnings (non-disposed throw-away EconomyServices graphs, same as m57_store_products). These are not SCRIPT ERRORs.
- No CI run and no phone build.

## Log
### Round 1
Built AdProvider + AdService over the factory 138 store seam. Wired the play count into the host terminal commit, the interstitial into the Results -> Continue / Retry transition, the banner into the existing No Ads callback, and the rewarded `ads_allowed` check into the facade. Added m57_ads_cadence (6 cases) and the CI guard. The first regression run found 4 suites asserting old expectations (default provider script == RewardedAdProvider; economy snapshot identical after a replayed / rolled-back terminal). I aligned them to the new truth and regenerated the RELEASE_GATES evidence text, and the rerun is all PASS. Notes / ceilings:
- Fire-and-forget interstitial: the next attempt launches right after `show_interstitial`. A full-screen AdMob activity pauses the app, but a real provider that needs a "closed" callback before launching is SB-M57-022 work.
- Interval 5 is a constant in AdService (owner value). Versioned per-placement tuning (SB-M57-009) stays open.
- Results -> Home does not show an interstitial; the ad stays due until the next Continue / Retry.
