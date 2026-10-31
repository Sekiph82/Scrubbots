# ScrubBots — Canonical GitHub Task State

This root TASKS.md is the **only** authoritative project-status tracker and the **only project-status file consumed by the H!veAI parser**. GitHub repository metadata and the latest commit are the remaining project-truth inputs. No parallel session index, roadmap, audit index, dashboard, hidden control-plane tracker, or equivalent status mirror is permitted.

Completed items and older status history: docs/migration/legacy-task-trackers/TASKS_ARCHIVE_2026-10-22.md (1092 done items as of 2026-10-22).

## Autonomous Queue
<!-- Maintained by the factory loop (CLAUDE.md §0D). One row per item: `- READY|OWNER|DONE <TASK-ID> — <one line>`. First READY row is next. -->
- DONE REFRESH-QUEUE — queue rebuilt 2026-10-22 from all open `- [ ]` items; §0D gates applied (visual/F5/phone/ChatGPT/Actions are not blockers)
- DONE SB-M50-BOARD-001 — closed 2026-10-22: CI run 39785950814 success (head 21c97572, M50S 10/10), fix c22c79e6; owner F5 2026-10-16, §0D.1/§0D.4
- DONE SB-M50-002 — closed 2026-10-22: CI run 39785950814 success (head 21c97572, M50S 10/10, m50_color_symbols s05/s06 assert Supply+Slot shapes); board part e8a7e75b, owner F5 2026-10-16, §0D.2/§0D.4
- DONE SB-UI-VIS-004 — verify-close 2026-10-22: 65b26242 ancestor of main, 14 PNGs present unchanged, indexed + roster-bound
- DONE SB-DEV-GODOT-001 — verify-close 2026-10-22: real main.tscn boots to Home and plays L1 to WON in Godot 4.7.2 on f7f23060 (m42_navigation, m42_opening, m42_home, m44_ftue LOCAL_PASS)
- DONE FACTORY-039 — main CI validation_only 39928015709 PASS (job 039)
- DONE SB-M50-OPTIN-001 — color-assist symbols opt-in (default OFF, save migration, floor(ppc*0.4) glyphs); merged 2026-10-22 (factory job 017, 2d0b83b1)
- DONE SB-M46-003..015 — verify-close 019 (technical PASS V04; physical gate given §0D.1; no on-device measurement)
- DONE FACTORY-002 — dashboard + owner-answer flow (job 002)
- DONE FACTORY-007 — light path + cheaper models (job 007)
- DONE FACTORY-009 — TASKS.md archive/slim (job 009)
- DONE FACTORY-010 — CLAUDE.md slim (job 010)
- DONE FACTORY-020 — m46_performance added to CI, run 39828088266 green (job 020)
- DONE SB-M44-020 — verify-close 2026-10-22 (job 021): fresh-save funnel suites LOCAL_PASS, owner playtest gate §0D.1; friction filed as SB-M44-031
- DONE SB-M43-R15-001 — verify-close: R01 sequential unlock PASS (f4448d47); owner visual acceptance given (§0D.1); record and tick
- DONE SB-UI-017..018 — verified 2026-10-22 (factory 023, CI 39828088266); SB-UI-019 moved to standing rules
- DONE SB-UI-VIS-005 — verified 2026-10-22 (factory 024): index already 157/157, all rows+paths on disk
- DONE SB-M43-R15-002..003 — verify-close 2026-10-22 (factory 025): code 24828bb, 6 suites LOCAL_PASS, owner visual §0D.1
- DONE SB-M39-033 — verify-close 2026-10-22 (factory 026), LOCAL_PASS + factory peer review: m39_v02_capacity PASS (cannot grow past 6, never 7+), m28_c002_c002_static_shell PASS 16-of-16, m49_responsive_matrix PASS 8-of-8 (m05_sixth_slot_matrix, m07 synthetic NOTCH), m50_color_symbols PASS 10-of-10; MAX := 6, no 7+ state. CLAUDE.md §0D.1 grants the real-phone sign-off; safe-area coverage is the synthetic-inset matrix, no real-phone capture claimed.
- DONE SB-M05-006..010 — factory 027 (2a870231): tools/run_suites.py one-command CI-rule runner + docs/TESTING_CONVENTIONS.md; LOCAL_PASS 3-suite subset aggregate=PASS (3/3), run_tests PASS, selftest PASS
- DONE SB-M07-011,013 — docs/LEVEL_ART_INVENTORY.md (factory 028); SB-M07-012 moved to standing rules (conditional: if supplied)
- DONE SB-M08-001..010,013..014 — factory 030 (6f970e6e): docs/LEVEL_ART_TECHNICAL_AUDIT.md + tools/audit_level_art.py; 10/10 images PASS (1:1 grid, no AA/interpolation/VOID, all colours exact C01..C16); SB-M08-011..012 moved to standing rules
- DONE SB-M22-015 — verify-close 2026-10-22 (factory 032); SB-M22-008 moved to standing rules (conditional: if owner approves a no-work state)
- DONE SB-M22-025 — booster texture slice validated (job 034); rest in SB-M22-026
- DONE SB-M36-005 — simulated difficulty playtest of the 10 catalog levels (factory 044, b81aa5e3): docs/DIFFICULTY_PLAYTEST_2026-10.md; findings SB-M36-009..011
- DONE SB-M36-009 — lane calibration proposal delivered (factory 045, 3538e9c3): docs/DIFFICULTY_LANE_CALIBRATION_PROPOSAL_V1.md; recommends B (score model v2 via M53-C003 path); adoption is a separate decision; owner chose B 2026-10-26 (built as SB-M36-012)
- DONE SB-M36-012 — difficulty score model v2 adoption: v2 = frozen M53-C002 candidate definitions + corpus anchors, locked weights, v1 untouched; active for new analysis; Spearman vs owner +0.64 (v1 +0.27), cadence partial (HARD < MEDIUM mean), recovery guards 0/3 (factory 046, d4a1b328..2394713f, LOCAL_PASS: tests/m36_difficulty_v2.gd 'M36 difficulty V2 evidence: PASS (38/38 cases, 0 fail)', m36_difficulty_v1 PASS, m53_first10_difficulty PASS, m53_c002_difficulty_calibration PASS; fresh run coordination/sessions/FACTORY/046-difficulty-model-v2/playtest_v2.json (10/10 SOLVED, modelVersion 2); doc docs/DIFFICULTY_MODEL_V2_CALIBRATION.md)
- DONE SB-M36-010 — recovery/sequencing proposal delivered (factory 047, 8b237736): docs/DIFFICULTY_RECOVERY_SEQUENCING_PROPOSAL_V1.md; under v2 all 3 guards fail (2 scale, 8->9 content inversion), exact-cadence reorder capped at 1/3 (1440 orders searched); recommends C+B, owner pre-approved 2026-10-26; work filed as SB-M36-013 (guard rescale) + SB-M36-014
- DONE SB-M36-011 — Frustration Risk inputs proposal delivered (factory 048, 03506dde): docs/DIFFICULTY_FRUSTRATION_RISK_PROPOSAL_V1.md; recommends C (HUMAN_BR simulated-human population 3 profiles x 32 seeds through ProofKernel + per-slot Session Load budget 22/26/36/40/48), owner pre-approved 2026-10-26; work filed as SB-M36-015
- DONE SB-M36-013 — lane anchor calibration (factory 050, 27a66955 rule+corpus before measurement, 05129032 evidence): 24-fixture anchor corpus, rule outcome RESCALE -> data/config/level_progression_v2.json (medians EASY 13.81 / MEDIUM 30.90 / HARD 43.83 / VERY_HARD 49.64, s 0.640, guards 9.6/12.8/9.6/22.4, ceiling 59.70); v1 byte-identical; LOCAL_PASS tests/m36_anchor_calibration.gd PASS (126 cases, 0 fail); doc docs/DIFFICULTY_LANE_ANCHOR_CALIBRATION.md; reader follow-up SB-M36-016
- DONE SB-M36-014 — recovery component checks (factory 052, 9d1f9cb2): DifficultyPlaytest.recovery_component_checks -> recovery.componentChecks (additive, no anomalies) for 3->4/5->6/8->9; docs/10 s13 recovery-slot constraints; LOCAL_PASS tests/m36_recovery_component_checks.gd PASS (26 cases); shipped L1..L10 (informational) v2: 3->4 and 5->6 pass, 8->9 fails A/B/BU
- DONE SB-M36-015 — Frustration Risk inputs build (factory 053, 66d8e163): data/config/frustration_analysis_v1.json + scripts/difficulty/frustration_analyzer_v1.gd (HUMAN_BR 3 PRIOR_UNCALIBRATED profiles, slot budget PROXY, F PROVISIONAL_SIMULATED_HUMAN, v2 weights read only), default-off run_policy chooser hook, difficulty_playtest.gd --frustration/--runs; LOCAL_PASS tests/m36_frustration_v1.gd PASS (62 cases, 365 s); six configs byte-identical; findings: corpus pairs tie at retryRisk 0, L1 monotonicity miss at 2 runs; full 10-level run not done (optional)
- DONE SB-M36-017 — Frustration discrimination findings (factory 067, 30a0171e): difficulty_playtest.gd --frustration --fixtures id[,id...] (opt-in, HUMAN_BR only, default outputs untouched); 32 runs/profile on 5 HARD + 5 VERY_HARD anchors + L1 (sanity); docs/DIFFICULTY_FRUSTRATION_DISCRIMINATION_FINDINGS_V1.md: every anchor 32/32 all profiles (ordering holds only as ties), all anchor retryRisk pairs tie at 0, only L1 (0.912) non-tied, L1 C 3/32 > S 2/32 miss; retryRisk/lateFailure do not discriminate HARD/VH anchors; no tuning; LOCAL_PASS m36_frustration_fixtures PASS (11), m36_frustration_v1 PASS (62)
- DONE SB-M36-016 — progression v2 reader (factory 051, c1f4eb55: DifficultyProgressionV1 accepts schema v1+v2 (V2_CONFIG_PATH, V2_SCHEMA, model_version(), challenge_tolerance()); LevelDifficultyAnalyzerV2(config, progression_path); tools/difficulty_playtest.gd --progression v1|v2 (v2 needs --model v2, writes coordination/sessions/FACTORY/046-difficulty-model-v2/playtest_v2_progression_v2.json: guards 9.6/12.8/9.6, tolerance 2.2/1.3/3.2 also applied to acceptanceWindow via LevelDifficultyAnalyzerV1.classify_window(delta, tol), anomalies=12, L1..L10 informational only); defaults stay v1, default --model v1/v2 outputs equal before/after except solver wall-clock ms; LOCAL_PASS tests/m36_progression_v2_reader.gd 'M36 progression v2 reader: PASS (55 cases, 0 fail)', m36_anchor_calibration PASS (126), m36_difficulty_v2 PASS (38/38), m36_difficulty_v1 PASS, m37_level_progression PASS, m53_first10_difficulty PASS)
- DONE SB-M44-005..006 — contextual first WAITING / win / loss coachmarks (factory 054, 23583381): ctx_waiting, ctx_result_won, ctx_result_lost one-shot for new profiles, scheduled l3_waiting/l3_hearts dropped; LOCAL_PASS m44_contextual_coach 7/7 + six regression suites
- DONE SB-M44-013,018 — NEW badge on newly unlocked Home entries until first visit (meta_ui feature_visited:<id>, persisted) + coachmark visual language in docs/16 §1.5 (factory 055, b07ca99e); LOCAL_PASS m44_new_badge 6/6 + regression suites
- DONE SB-M34-006 — haptics real-device test: OWNER_ACCEPTED 2026-10-31T00:44 (factory/answers.md "all is ok"); no device capture was made, the A10 was not reachable by adb afterwards, and the A10 still runs the pre-VIBRATE build until the next save-preserving reinstall; factory 075. Earlier: haptics real-device test on an Android debug build (factory 072: APK had no VIBRATE permission, preset fixed with permissions/vibrate=true; fixed APK run 41127683939 declares VIBRATE; ON/OFF device run pending: A10 not connected; family APKs now signed with one stable debug key from GitHub Secrets (64ac9084, runs 41129466216 + 41129478628 same cert), phone needs one save-preserving reinstall onto it; docs/M34_HAPTICS_DEVICE_VALIDATION.md)
- OWNER SB-M42-032 — opening cinematic on real Android device (720p/30, sync, latency, memory) (waits for the Galaxy A10 to be plugged in)
- OWNER SB-M47-005..010 — Android device: portrait, safe areas, Easy/Medium/Hard/Very Hard 59x59 performance (waits for the Galaxy A10 to be plugged in)
- OWNER SB-M47-011..015 — Android device: bot density, background/foreground, heat/battery, record results, FULL/REDUCED plugin stress (waits for the Galaxy A10 to be plugged in)
- DONE SB-M43-068..072 — ceremonies (factory 057, 0aa42895): 068-071 verify-close (m43_master_c005_meta_ceremonies 32/32); 072 feature unlock ceremony unlock:<id> for new profiles at table levels (Daily/Shop/Tasks/Collection; others skipped until art); LOCAL_PASS m43_c005_c072_feature_unlock_ceremony 9/9 + 48 CI suites
- DONE SB-M43-074,075,077 — celebrations verify-close (factory 058; no SB-M43-076 exists): LOCAL_PASS m43_c005_c074_c077_celebrations 6/6 + 49 CI suites
- DONE SB-M43-R05-001..002 — Gift Meter micro-progress ticks verify-close (factory 059; code 671615be): LOCAL_PASS m43_master_c005r_gift_micro_progress 8/8, added to CI (52 suites, 4077ce5b)
- DONE SB-M43-013 — Results ceremony hand-off verify-close (factory 059; code 46e50fd1): LOCAL_PASS m43_master_c005_meta_ceremonies 32/32 (e27/e28), added to CI (52 suites, 4077ce5b)
- DONE SB-M43-C005F-007 — robot + feature unlock MAJOR_UNLOCK feel (factory 059, a292c390): LOCAL_PASS m43_c005f_phase6_unlock_feel 8/8 + 52 CI suites; world part gated, not implemented
- DONE SB-M43-090..101 — Collection verify-close + pack entry (factory 061; 098 built abb42509): LOCAL_PASS m43_master_c007_collection 17/17 + m54_collection_set_master_exactly_once, added to CI (55 suites, 74b85bab)
- DONE SB-M43-R07-001..006 — pity threshold 3 + First Collection Sprint threshold 1 shipped (factory 069, 3068dc55, e9f0eeed): Set 1 p50 L38 at 4 levels/day, sim tools/sim_pack_pity.gd 200 seeds; LOCAL_PASS m43_master_c007r_pity 11/11 (CI validate, 60)
- DONE SB-M43-102..111 — Robots destination verify-close (factory 063): tests/m43_master_c008_robots.gd 10/10 added to CI validate (56)
- DONE SB-M43-112..121 — Tasks/Daily/Gift Bar verify-close (factory 064): m43_master_c009_daily 12/12 with exact CI guard
- DONE SB-M43-R09-001..005,123,124,126,128,129,R10-001..007,144,145,147..149,151,R12-002,R12-004,R12-006,163,164 — verify-close (factory 065, ab035410): LOCAL_PASS m43_master_c009_daily 12/12, m43_master_c010_meta 12/12, m43_master_c011_c014 28/28; c010 + c011 added to CI validate (58)
- DONE SB-M43-122 — RANKS = personal rank ladder (owner 2026-10-31; factory 074, 7f208789): LOCAL_PASS m43_personal_ranks 8/8 (added to CI validate, 62) + c010 12/12, m44_unlock_gate 6/6
- DONE SB-M43-125 — Profile visual master: master approved by Claude under owner-delegated authority 2026-10-31 (not owner visual review); assets/ui/generated/masters/scrubbots_profile_master_v01.png; factory 075 (bcefca76)
- DONE SB-M43-127 — Achievements visual master: master approved by Claude under owner-delegated authority 2026-10-31 (not owner visual review); assets/ui/generated/masters/scrubbots_achievements_master_v01.png; factory 075 (bcefca76)
- DONE SB-M43-130 — Events visual master + reusable event card/detail family: master approved by Claude under owner-delegated authority 2026-10-31 (not owner visual review); assets/ui/generated/masters/scrubbots_events_master_v01.png; factory 075 (bcefca76)
- DONE SB-M43-125-REBUILD — Profile rebuilt to master v01 (factory 076, 8d8e73bb): native hero card (portrait, level badge, Home HUD Bot Parts bar), 2x3 stat tiles, Personal Bests Current/Best table; LOCAL_PASS m43_master_c010_meta 12/12, m43_personal_ranks 8/8, m22_026_texture_budget PASS, meta_snapshot META_EVIDENCE CLEAN; CLAUDE_PEER_REVIEW pending in factory; visual match judged by Claude under owner-delegated authority 2026-10-31
- DONE SB-M43-127-REBUILD — Achievements rebuilt to master v01 (factory 077, c3af8b23): AchSummary banner (trophy, n / 8 completed, bar), 8 cards with round badge + name + description + COMPLETED pill or bar + n/m, BACK + CLOSE; ACH_<ID> split into name + _DESC; crown icon cropped from the master (manifest provenance); LOCAL_PASS m43_master_c010_meta 12/12, m47_touch_r01_mobile_ux 14/14, m22_026_texture_budget PASS, m46_rm003_ftue_coach_performance PASS, meta_snapshot META_EVIDENCE CLEAN at 5 sizes; CLAUDE_PEER_REVIEW pending in factory; visual match judged by Claude under owner-delegated authority 2026-10-31, not owner visual review
- DONE SB-M43-130-REBUILD — Events rebuilt to master v01 (factory 078, edb198e9): reusable UiEventCard (scripts/ui/components/ui_event_card.gd) for every weekly view: active/ended hero (title, Ends-in or Event-ended pill, Levels-cleared pill), Milestone_<i> rows (reward icon, N levels + real reward text, COMPLETED pill / CLAIM / Progress_<i> bar / lock), info Rule strip; upcoming = collapsed greyed hero with Starts-in pill; touch-scrollable EventScroll; empty/unavailable as a centred cream card; hero cropped from the master (manifest provenance). PLAY deliberately omitted (no existing launch action from this popup); shipped events_v1.json still schedules no event, so production shows the empty state; LOCAL_PASS m43_master_c010_meta 12/12, m43_master_c011_c014 28/28, m47_touch_r01_mobile_ux 14/14, m22_026_texture_budget PASS, meta_snapshot META_EVIDENCE CLEAN at 5 sizes; CLAUDE_PEER_REVIEW pending in factory; visual match judged by Claude under owner-delegated authority 2026-10-31, not owner visual review
- DONE SB-CAMPAIGN-L11-L30-FIX — factory 079 (ea71d9c5): m43_c001b end-of-content case moved to Level 30, LOCAL_PASS 11/11 ("Level 30: Victory layout, Continue disabled, readable coming-soon card"); m55 root cause is NOT the test: plan clicks replayed through the real runtime diverge from the ProofKernel (different target picks), and m55 now drives plans to full quiescence + reports rejected clicks; m55 stays red (L18 LOST at plan click 17/40 in the app root) -> follow-up SB-CAMPAIGN-RUNTIME-KERNEL-DIVERGENCE; CI validation_only 41150908377 validate = failure (m55_long_session as diagnosed; m44_new_badge stale "L40: RANKS unserved" check since 7f208789 SB-M43-122); round 2: m44_new_badge L40 now asserts served RANKS shows NEW and Nav_leaderboard press marks feature_visited:ranks + hides it, LOCAL_PASS 6/6 (no new CI run)
- READY SB-CAMPAIGN-RUNTIME-KERNEL-DIVERGENCE — L22 unwinnable via intended clicks in the real runtime (all layouts); L18/L20 layout/pacing-dependent; likely kernel _origin_for_slot vs runtime SlotOriginProvider. Evidence: runtime picks other targets than the kernel (L22 after click 3: runtime clears (29,27), kernel (7,27)); likely cause kernel lane origin (slot+0.5)*w/cap below the board vs runtime SlotOriginProvider laid-out slot anchors. Real-runtime replays (factory 079): bare host, full quiescence -> L22 LOST at click 28/43 (5 slots WAITING, kernel quiesce of that runtime state also stuck); m52-style pacing -> L20 LOST at click 72/120 and L22 at 26/43; app root (m55) -> L18 LOST at 17/40. Fix game/content (align kernel origins/tie-breaks with runtime, or re-prove plans on the runtime) until m55 passes 30/30; also tighten m52 _play_clicks quiet check (it can click between dispatch waves)
- DONE SB-M43-134 — Event reward badge asserted 0/1/0 on HomeBadges + NavBadge_events (factory 070, 9377dc15; LOCAL_PASS c010 12/12)
- DONE SB-M43-143 — comeback Gift/Tasks/Events lines asserted present/absent, no grant (factory 070, 9377dc15; LOCAL_PASS c011 28/28)
- READY SB-M43-146 — contextual OS notification permission prompt (needs platform plugin)
- READY SB-M43-150 — comeback/notification-permission illustration
- READY SB-M43-R12-001 — Catch-Up track has no shipped reward steps (owner values needed)
- DONE SB-M43-R12-003 — catch-up expiry boundary + reinstall (fresh / restored) asserted (factory 070, 9377dc15; LOCAL_PASS c011 28/28)
- OWNER SB-M43-165 — retry popup asserted on all 4 surfaces (factory 070); needs live store IAP / ad provider (M57) / cloud provider (SB-M43-153) / Ranks
- OWNER SB-M43-166 — tasks/duplicates/gifts/events empty states asserted (factory 070); no-rankings needs Ranks live
- READY SB-M43-168 — final cross-screen sound/haptic feel acceptance
- READY SB-M43-169 — manifest misses 19 ui_surface_registry ids (home, results, settings, ...) and the Rewarded Ads surface
- READY SB-M43-170 — M43 closure gate (surfaces MASTER_REQUIRED, Ranks/Level Intro not live)
- READY SB-M43-C005F-015 — end-to-end GameFeelFlow/Spark feel validation across representative paths (no single suite yet)
- READY SB-UI-VIS-006 — pixel-level QA of production assets used on-screen: alpha edges, no text/watermark, readability, import settings
- READY SB-UI-031 — validate transparency/edges/resolution/filtering/compression/memory/readability of bound generated assets
- READY SB-M49-020..022 — prove all touch targets >= 88 px (nav, Pause/2x, supply); localization-expansion text container stress
- READY SB-M49-026..028 — full viewport matrix for every M43/M44 surface; long labels/prices; modal stacks and scroll screens
- READY SB-M49-031..032 — matrix check of Next Cleanup, journey, ScrubBox, Weekly/First-Try, Catch-Up; compact degradation
- READY SB-M50-004..007 — contrast coverage for remaining screens, Reduced Effects, touch sizes, text readability
- READY SB-M50-010..011 — icon families distinguishable at mobile size; essential gameplay understandable without decoration
- READY SB-M50-012..017 — M43/M44 text scale/focus/non-color cues, Reduced Effects ceremonies, accessible ad path, a11y labels
- READY SB-M50-018 — GameFeelFlow/Spark motion/flash accessibility audit, FULL vs REDUCED (after M50-005/012/013/017)
- READY SB-M51-001..003 — remove remaining hard-coded user text; prove longer-string layouts incl. Shop scroll/overflow
- READY SB-M51-006..009 — localize every M43/M44 surface, platform-localized prices, pluralization, full pseudo-localization pass
- READY SB-M56-001..006 — analytics taxonomy (versioned, privacy-minimized): session, level funnel, retention, assistance, booster events
- READY SB-M56-007..010 — analytics: economy, collection/robots, navigation, ads/store events (provider mocked)
- READY SB-M56-012..016 — notification analytics, dashboard metrics, no-gameplay-effect rule, consent gating, schema tests
- READY SB-M56-017..020 — measure Next Cleanup, 10-level journey, Collection pity/new-card rate, Daily Scrub Orders
- READY SB-M56-021..023 — measure Weekly/First-Try, Comeback Catch-Up and notification outcomes
- READY SB-M54-022..027 — regressions: Results/fail/Need a Hand, spend/grant idempotency, ad callbacks (mocked), Shop, packs, robots
- READY SB-M54-028..030 — regressions: Tasks/Daily/Gift/badges, BottomNav/modal stack, feature-unlock/FTUE once-only
- READY SB-M54-033..036 — regressions: Next Cleanup/journey, Collection pity, Daily/Event retention, Comeback/notifications
- READY SB-M54-037..038 — presentation-plugin one-shot/fail-open regression and GFF/Spark runtime visual regression pack
- READY SB-M55-018..023 — chaos: popup spam, background during flows, triple loss, BottomNav churn, huge inventories, timer expiry
- READY SB-M55-024..025 — chaos: offline/online flapping; presentation-plugin chaos/leak test
- READY SB-M58-001..006 — third-party and data inventory, remove unnecessary collection, privacy disclosures, store declarations, age rating
- READY SB-M58-007..012 — child-directed review, analytics/ad consent, notification privacy, account data policy, display-name privacy
- READY SB-M58-013..014 — receipt/transaction retention policy; localization/accessibility check of consent/privacy screens
- READY SB-M57-022 — sandbox purchases/rewarded ads on real Android (later iOS) with AdMob + Play Billing/StoreKit (owner 2026-10-22)
- READY SB-M59-001..005 — debug/release export, output directories, versioning, build numbers
- READY SB-M59-006..010 — tests + content validator before release, Android build, clean-clone build, addon release hygiene
- READY SB-M59-011 — final repo hygiene Phase 1 delete-nothing dry run, only after feature freeze and M59-001..010
- READY SB-M60-001..006 — release gates: no dead routes, bound surfaces, fresh-save FTUE, provider/disabled Shop, Events/Ranks policy, gates
- READY SB-M51-005 — launch languages English and Turkish (owner 2026-10-22)
- READY SB-M43-131..133 — RANKS (owner 2026-10-22): all-time = highest campaign level; weekly = levels completed, reset Monday 00:00 UTC; nothing bought with money/boosters counts
- READY SB-M56-011 — Events/Ranks analytics for the RANKS policy decided 2026-10-22 (all-time + weekly tables)
- READY SB-M43-153..160 — cloud save (owner 2026-10-22): Android Google Play Games Saved Games, iOS Game Center + iCloud; no own server/separate login; M43-158 restore via Play Billing/StoreKit
- READY SB-M49-030 — account/cloud-conflict responsive screen for the 2026-10-22 provider decision (Google Play Games / Game Center + iCloud)
- READY SB-M54-031 — cloud/account regression for the 2026-10-22 provider decision (Google Play Games Saved Games / Game Center + iCloud)
- READY SB-M57-012 — SB packs (owner 2026-10-22): $0.99→100 $4.99→550 $9.99→1200 $19.99→2600 $49.99→7000, IDs scrubbucks_<n>; retune after M56; Play Billing/StoreKit; live publish = owner
- READY SB-M57-001..011 — ads (owner 2026-10-22): AdMob; bottom banner in ad band, never over board; interstitial every 5 plays between levels; opt-in rewarded; any finished level counts as a play
- READY SB-M57-014..016 — purchase/receipt/restore (owner 2026-10-22): Google Play Billing (Android) + Apple StoreKit (iOS); live store release = owner (§0D.5)
- READY SB-M43-084 — Shop real-money cards/prices/restore via Google Play Billing + StoreKit (owner 2026-10-22); live store release = owner
- READY SB-M49-029 — ad/store return-transition layout check for AdMob + Play Billing/StoreKit (owner 2026-10-22)
- READY SB-M57-013 — No Ads (owner 2026-10-22): one-time $4.99, removes bottom banner + every-5-plays interstitials; rewarded videos stay
- READY SB-M43-081 — Shop No Ads entry for the 2026-10-22 No Ads product ($4.99 one-time; rewarded videos stay)
- READY SB-M43-136..141 — worlds (owner 2026-10-22): 20 named worlds x 150 levels = 3000, full table on SB-M43-136; a world ends at its last level, next starts after (owner chat)
- READY SB-M43-073 — world unlock ceremony for the 2026-10-22 owner world table (20 worlds x 150 levels)
- READY SB-M54-032 — world regression for the 2026-10-22 owner world table (20 worlds x 150 levels, 1-3000)
- READY SB-M61-001..007 — Friends (owner 2026-10-22): post-launch; list from Play Games / Game Center; no chat; 1 Heart gift per friend per day; no challenges in V1
- DONE SB-M44-010 — owner unlock table landed as data/config/feature_unlocks_v1.json + AppState.feature_unlocked (factory 042, bd5e3de9; m44_unlock_gate LOCAL_PASS)
- READY SB-M44-022..023 — Collection onboarding and retention unlocks per the 2026-10-22 owner table (Collection 20, Tasks 12, Events 30)
- READY SB-M43-R09-006 — ScrubBox surprise bonus slot: owner said yes (2026-10-22); enable only after the M56 economy simulation
- DONE SB-M44-025 — closed 2026-10-30: open/drain gated on card_packs (9f335a86), m44_pending_packs_gate 6/6 LOCAL_PASS, CI validate 59 (factory 066)
- DONE SB-COL-NAV-001 — Collection set NEW-count badge + set detail prev/next (owner 2026-10-30): red unseen-card count per album set row, < / > set pager with 15<->1 wrap (658906a1); m43_master_c007_collection 19/19 LOCAL_PASS, CI guard 19/19 (factory 068)
- READY SB-M44-026 — Featured Card schedule for 135 cards + guaranteed Scrubby L20 and unowned Set 01 card at L30/L40 (OWNER_META_PROGRESSION_DESIGN_V01)
- READY SB-M44-027 — robot 5-stage assembly visual at 50/100/150/200/250 Bot Parts; Robots unlock L25 (OWNER_META_PROGRESSION_DESIGN_V01)
- READY SB-M44-028 — achievements 8 -> 32, stats from L1, Achievements screen unlock L35 (OWNER_META_PROGRESSION_DESIGN_V01)
- READY SB-M44-029 — cosmetic achievement rewards (badges/frames), no economy rewards (OWNER_META_PROGRESSION_DESIGN_V01)
- READY SB-M44-030 — verify Gift Bar visible from first Home with unchanged 10/50/250/500/1000 rewards; regression test (OWNER_META_PROGRESSION_DESIGN_V01)
- DONE SB-M44-031 part 1 — unlock gate + Home/booster locking + grandfather + coachmark skip (factory 042, bd5e3de9+ea0cc0ad; m44_unlock_gate 6/6, m44_ftue 23/23 LOCAL_PASS)
- READY SB-M44-031 part 2 — per-booster lessons at 6/11/16/21, Daily/Tasks coachmarks after L4/L12, defer starter grant + 100 SB welcome task to their unlocks
- READY SB-M22-026 — steps 1-4 done (jobs 037/038/040/043: runtime measure tool, 90 measured caps, Home 207 -> 106 MiB, card arts 810 -> 400 MiB, library 2260 -> 2103 MiB); remaining = VRAM compression (needs owner visual sign-off on before/after captures) + atlasing
- DONE SB-UI-008..013 — owner 2026-10-23: canonical Scrubby master = assets/ui/final/characters/scrubby/scrubby_master.png; manifests updated, 013 validated (factory 041)
- DONE SB-M22-023 — owner 2026-10-23: no booster coachmark; shared tutorial_pointer.png kept, booster_tutorial_pointer.png retired from runtime (PNG kept) (factory 041)
- DONE SB-CAMPAIGN-L11-L30 — 20 Release Pool levels added as campaign L11–L30 (owner 2026-10-30; factory 071, 88f7348b + a3ba53ef): owner-art candidate-owner-* entries, sha256-verified, cells/palette copied verbatim, Studio SOLVED + replay WIN recorded per level (not re-run); LOCAL_PASS campaign_l11_l30 5/5 (ProofKernel intended-click WIN all 20), m35, m37, cp04, cp05, cp06 16/16, remote_content_family_fixture, m40_v04, m42_home, m43_c001a + 48 other CI suites; m55 driver fixed on main in 06fbfbad (plan clicks in proof-kernel serial order, counts non-VOID cells); CI/test re-validation of the release-pool levels skipped by owner decision 2026-10-30 (no pass claimed); m52_owner_supply_plans not re-run
<!-- Not queued (standing rules, no job of their own): SB-M07-012 (conditional: if supplied), SB-M52-005 (conditional: when rectangular production art is supplied), SB-M08-011..012, SB-M22-008 (conditional: if owner approves a no-work state), SB-M22-016..019, SB-M22-021, SB-UI-019..030, SB-UI-032, SB-M43-135, SB-M43-142, SB-M43-152, SB-M48-001, SB-M50-008..009, SB-M57-017..021, SB-M61-008 -->

## Questions for Şekip
<!-- One line per question the loop truly cannot decide (CLAUDE.md §0D.5). Empty = nothing needed. -->

## Project Status

- Factory loop: CI validation_only run 39928015709 on e2f674b7 = PASS (44 suites); covers jobs 017/035/038.
- **NEWEST OWNER DECISION [2026-10-22]: `CLAUDE.md` §0D.** All owner visual sign-offs GIVEN; GitHub Actions cost freeze LIFTED (public repo, free standard runners); worktrees/clones allowed with mandatory cleanup; factory loop + this file's Autonomous Queue drive the work; peer review closes tasks.

- Current Milestone: **M46 TECHNICAL_SCOPE_AUDITED_PASS after WHOLE-MILESTONE CHATGPT REAUDIT V04**. RM005 first-progress solver/cached catalog and RM006 bounded Selector/diagnostic/+1 improvements source+auditor-authored adversarial validation accepted at final tested source b36d48fa; Claude Linux Godot4.7.2 22/22 exit0 (224s), 45/45 affected suites E1/E2, NOT ChatGPT-executed runtime. Main non-force FF integrated branch at 76eac5ad. **M46 release/device gates remain OPEN**: physical phone GPU/thermal, R06 Checking/HUD Random and R07 Booster saved F5 visual, owner-local Windows project runtime parity, release-template Logger diagnostics; GitHub Actions cost freeze. Audit: coordination/sessions/M46-PERFORMANCE-C001/CHATGPT_M46_WHOLE_MILESTONE_INDEPENDENT_REAUDIT_V04.md.
- Current Sprint: **M46 correction series R02–R07 and RM001–RM006 completed within source/adversarial technical scope**, no new remediation prompt justified by frozen V3 findings; remaining OWNER_REQUIRED / NOT_VERIFIED_RELEASE / DEVICE gates tracked here only. Independent audit coordination/sessions/M46-PERFORMANCE-C001/CHATGPT_M46_WHOLE_MILESTONE_INDEPENDENT_REAUDIT_V04.md. Claude must not alter TASKS.
- Current Task: **M46 owner/device validation gates**, not a new coding milestone: owner F5 visually inspect "Checking...", HUD Random checking hold and "Booster saved!" coexistence; bounded original-Windows project parity verification and native phone CPU/GPU/thermal when available; release-export script error provenance NOT_VERIFIED_ENGINE_LIMITATION. Cold first Results image decode choice defaults to current A (keep ~one-off ~200ms) pending an explicit owner preference; no preload or image recompress authorized.
- Current Task Status: M46_SOURCE_PLUS_AUDITOR_AUTHORED_ADVERSARIAL_TECHNICAL_AUDITED_PASS / MAIN_FF_76eac5ad / TESTED_SOURCE_b36d48fa / CLAUDE_E2_LINUX_HEADLESS_M46_22OF22_EXIT0_224S / FOCUSED_45OF45_PASS / RM005_129_STATE_ORACLE_EQUAL_AND_5_MUTANTS / RM006_ALL118_5S_CAP_LINUX_AND_7_MUTANTS_PLUS_MASKED_GUARD / CHATGPT_INDEPENDENT_TWO_PASS_SOURCE_AUDIT_V04 / NO_CHATGPT_GODOT_E3_RUN / COLD_RESULTS_OWNER_CHOICE_A_UNCHANGED / RM006_RELEASE_LOGGER_NOT_VERIFIED / M46_003_008_015_F5_GPU_OWNER_GATES_OPEN / WINDOWS_PROJECT_RUNTIME_PARITY_OPEN / NO_GITHUB_ACTIONS_ABSOLUTE_COST_FREEZE / CLAUDE_TASKS_EDIT_FORBIDDEN.
- **LATEST USER INSTRUCTION [2026-10-15, L7 Godot screenshot after previous M50 feature]:** `**ABSOLUTE OWNER COST FREEZE [2026-10-15]:** GitHub Actions 2,000 free minutes EXHAUSTED and owner reports USD 76 billed. NO Actions in any repo, no validation_only, no reruns, no paid runners or reenable. Both ScrubBots Android and iOS workflow jobs now have unconditional-false guards, not to be removed until fresh explicit owner authorization. Local bounded Godot 4.7.2 tests only; cloud-required gates deferred, never PASS by guess.`
- [x] **SB-M50-BOARD-001 — Per-active-cell board colour symbols, INCLUDING 59x59. [OWNER MANDATORY 2026-10-15; CLAUDE_AUTONOMOUS_REVIEW: DONE_CI_PASS_2026-10-22 (was IMPLEMENTED_LOCAL_TESTED_CLOUD_CI_DEFERRED_COST_FREEZE_OWNER_VISUAL_PENDING)]** Single shader pass (per-cell canonical C-ID map + shared 16-glyph atlas from the same `color_symbols.gd` shapes), no per-cell nodes, CLEARED/VOID transparent; Settings `COLOR SYMBOLS` (default ON, persisted `settings.effects.color_symbols`) switches board + Supply/Slots + booster chips; press-and-hold board magnifier (>= 28 px/cell, real L7 64.8 px/cell). LOCAL_PASS only (Godot 4.7.2): new `tests/m50_board_symbols.gd` 8/8 headless + 8/8 windowed real-GPU readback, plus the 43-suite CI list run locally all PASS; ZERO GitHub Actions. Log `coordination/sessions/M50-BOARD-COLOR-ASSIST-C001/CLAUDE_LOG_V01.md`; `CLAUDE_PEER_REVIEW` (not ChatGPT) `coordination/sessions/M50-BOARD-COLOR-ASSIST-C001/CLAUDE_PEER_REVIEW_V01.md` (0 blocker/major). **OWNER F5 VISUAL APPROVAL [2026-10-16]:** owner in chat: "Board symbols and the magnifier look good in F5." (board glyph style + loupe accepted). Still OPEN: phone performance (unmeasured), ChatGPT independent audit, cloud CI (deferred, cost freeze). Reuse current 16 canonical identities from `color_symbols.gd`, overlay symbol within each coloured/ACTIVE board cell (not supply/slots/legend only). Preserve exact cleared-alpha, art, routes, agents, safe area; performant single/batched renderer, 59x59 zoom/readable inspector, offline-only tests, F5 visual approval. Claude prompt `coordination/sessions/M50-BOARD-COLOR-ASSIST-C001/CHATGPT_CLAUDE_MASTER_PROMPT_V01.md`; no CI budget and no runner spends. Owner reviewed actual Level 7 pigeon board, rejects non-symbolized board as inaccessible. **CLOSED 2026-10-22 (factory 011/015):** Android `validation_only` run 39785950814 (https://github.com/Sekiph82/Scrubbots/actions/runs/39785950814), head 21c97572, success, validate=success, export skipped, aggregate=PASS incl. `M50S verdict=PASS (10/10)`; earlier run 39782553609 failed only on flaky m50_color_symbols s10, fixed test-only in c22c79e6. Owner F5 approval 2026-10-16, phone gate given by CLAUDE.md §0D.1, ChatGPT audit not required (§0D.4); the stale open items above (phone, audit, CI) are superseded. **Superseded in part by SB-M50-OPTIN-001: default OFF, opt-in.**
- [x] **SB-M50-OPTIN-001 — Color-assist symbols opt-in (default OFF), save migration, smaller glyphs. [OWNER 2026-10-22; factory job 017]** Owner in chat 2026-10-22: "renk körleri için yaptığımız düzenleme sürekli gözükünce çok çirkin bir görüntü oluşuyor piksel art üzerinde. settings kısmına bir düğme koymalıyız ki herkese aynı şekilde gözükmesin. renk körleri için o düğme aktif edildiğinde piksel art görselinin pikselleri üzerinde o işaretler çıksın. piksel art üzerinde her pikselin üzerinde yer alan görsel işaretler çok büyük. bir kişinin görebileceği en küçük boyutta olmalı. tüm görseli bozmuş. piksel art görselini bozmamalı." Spec `factory/jobs/017-color-assist-optin/spec.md`: Settings `COLOR SYMBOLS` default OFF for board + Supply/Slots + booster chips (pure pixel art when OFF); save marker `settings.effects.color_symbols_optin: true` (no VERSION bump) migrates every pre-marker save to OFF once, non-bool marker rejects with `effects_malformed`; board glyph side floor(ppc * 0.4) whole screen px (owner rework 2026-10-22: "13'ten 8'e düşmüş ya, bence şu anki boyutun yarısı olsun ama aşağıya yuvarlanmış haliyle. mesela 13 için 6 olsun"; was span 0.8), ink 0.85 / halo 0.35, new `min_glyph_px` 5.0 hides the glyph under 5 px (cells < 12.5 px; magnifier is the inspect path); hint names color-blind players. Code 2bfc7e92 + 7bf9a47e. LOCAL_PASS (Godot 4.7.2): m50_board_symbols 8/8 headless + 8/8 windowed GPU readback, m41_settings, m50_color_symbols 10/10, m50_accessibility_audit 4/4, m46_performance and the 43-suite CI list; no Actions run. **CLOSED 2026-10-22:** merged in factory job 017 (commit 2d0b83b1 on main); round-2 reviews PASS; LOCAL_PASS m50_board_symbols 8/8 windowed+headless, m41_settings, m50_color_symbols 10/10, m50_accessibility_audit 4/4, m46_performance 22/22; owner pre-approved visual in chat; CI: run 39928015709 PASS (2026-10-23).
- **CLAUDE_AUTONOMOUS_REVIEW UPDATE [2026-10-15] — SB-DEV-GODOT-001 = READY_FOR_OWNER_F5_CHECK.** **LATEST CHATGPT INDEPENDENT SCOPED AUDIT:** `coordination/sessions/DEV-GODOT-LOCAL-PLAY-C001/CHATGPT_INDEPENDENT_AUDIT_V01.md`; technical evidence review only, no F5/device sign-off.
  - Log: `coordination/sessions/DEV-GODOT-LOCAL-PLAY-C001/CLAUDE_LOG_V01.md`. Review: `coordination/sessions/M50-ACCESSIBILITY-C001/CLAUDE_PEER_REVIEW_M50_DECISIONS_V01.md` (`CLAUDE_PEER_REVIEW`, 2 rounds; NOT a ChatGPT audit).
  - Local Godot 4.7.2 IS installed (winget); earlier "no local Godot" notes were wrong.
  - Owner Editor F5 = NOT_RUN by Claude. A real-GPU windowed run of production `main.tscn` (throw-away save) reached Home → PLAY → L1 gameplay.
  - **SB-M50-002 symbols** = IMPLEMENTED:
    - 16 C-ID shapes, watermark behind the count;
    - Supply front + preview, 5/6 slots, Tornado / Selector chips;
    - no board-cell symbols (recorded constraint).
  - **SB-M50-004 navy PLAY label** = IMPLEMENTED: 7.35 / 9.04 / 5.31 : 1.
  - **SB-M51-001 HUD price** = FIXED (UiText key + `UiText.num`).
  - CI:
    - [38788244223](https://github.com/Sekiph82/Scrubbots/actions/runs/38788244223), `4cbaa556`: 42/42.
    - [38790518157](https://github.com/Sekiph82/Scrubbots/actions/runs/38790518157), `43d7e2a2`: 43/43.
    - Both validate success, export skipped, no APK / IPA.
    - Round-2 shape swap `a9ebe920`: local 10/10 only, rides the next planned run.
  - **Owner visual sign-off for symbol art + navy PLAY label = OPEN.** M44-018 / 020 remain OPEN.
  - Next autonomous milestone: **M46 Performance**.
- Next Task/Action: **NO NEW CLAUDE M46 REMEDIATION MASTER REQUIRED**. Source/adversarial technical audit coordination/sessions/M46-PERFORMANCE-C001/CHATGPT_M46_WHOLE_MILESTONE_INDEPENDENT_REAUDIT_V04.md fully reconciles SB-M46-001..015 and R02–R07/RM001–006, with scoped technical rows closed below; owner-only remaining (1) F5 real display "Checking..." / HUD Random hold / "Booster saved!" overlay; (2) phone/device native GPU+thermal/portrait and Windows owner-local project parity (current Linux cloud numbers not equivalent); (3) optional Results cold first image A keep (~200ms one-off), B preload ~12.6–25MiB RAM, C recompress art (requires owner) with A default UNCHANGED; (4) arbitrary release template worker error reporting NOT_VERIFIED_ENGINE_LIMITATION. Keep 400ms/5s, unbudgeted Need-a-Hand, source visual assets and all owner saves intact. GitHub Actions/validation_only/rerun/build APK/IPA remain ABSOLUTELY PROHIBITED by owner cost freeze; no hidden disk cleanup/worktrees. Only ChatGPT writes TASKS; next source milestone requires its own complete child+criteria/master process.
- Required Actor: **CLAUDE CODE** implements offline and preserves owner files; **CHATGPT** audits source/tracker; owner only signs off visual design and alone can reauthorize GitHub Actions. Never ask routine coding approvals or invent paid validation.
- **OWNER RESOLVED BOTH M50 DESIGN DECISIONS [2026-10-15]:** YES, add durable distinguishing per-color symbols to color-coded gameplay Supply/Slot tiles and related meaningful cues; green hero PLAY button stays GREEN, its PLAY label becomes DARK NAVY. Concept/color decision AUTHORIZED for Claude to code and verify under **same existing** `coordination/autonomy/SCRUBBOTS_CLAUDE_GODOT_LOCAL_PLAYABLE_SYNC_V01.md` (prompt updated in-place). No second prompt. M50-002/004 implementation NOT YET VERIFIED, symbol appearance requires later owner visual acceptance; keep checklist rows unchecked until code+CI/visual evidence exists. No owner approval required to begin prototype/implementation. **SUBSEQUENT SOURCE/CI UPDATE:** implemented after this authorization; see Claude review at top and ChatGPT independent audit `coordination/sessions/DEV-GODOT-LOCAL-PLAY-C001/CHATGPT_INDEPENDENT_AUDIT_V01.md`. Final symbol appearance remains owner-gated.
- **2026-10-15 NEW CHATGPT CROSS-AUDIT (M44-D2/M49/M50/M51):** `coordination/sessions/M49-RESPONSIVE-UI-C001/CHATGPT_CROSS_M44_M49_M50_M51_INDEPENDENT_AUDIT_V01.md`. GitHub run 38753823564 final `validate=success`, `export=skipped`, 38/38; M44 23/23, M49 8/8, M50 4/4, M51 4/4. Scoped technical row updates below; owner-device, UI, glyph/contrast, whole-surface stress and shipping remain gated. Older failure runs are recorded in audit rather than erased.
- [x] **SB-DEV-GODOT-001 — Owner Godot Editor latest-build playability / safe local synchronization (2026-10-15).** Claude task: `coordination/autonomy/SCRUBBOTS_CLAUDE_GODOT_LOCAL_PLAYABLE_SYNC_V01.md`. Sync the ONE Desktop checkout with `origin/main` non-destructively; respect owner-modified `project.godot` and `scenes/app/main.tscn`, preserve stashes/untracked state; aim for opening/running current production Home and real level in Godot 4.7.x via F5. Record actual Editor launch result or NOT_RUN. Repeat safe local update at player-facing milestone handoffs. **CLAUDE SOURCE+LOCAL-WINDOW RUN REPORTED / 43-SUITE CLOUD CI SCOPED PASS; READY_FOR_OWNER_F5_CHECK, actual Editor F5 NOT_RUN. Latest shape swap cloud CI pending.** Independent ChatGPT audit: `coordination/sessions/DEV-GODOT-LOCAL-PLAY-C001/CHATGPT_INDEPENDENT_AUDIT_V01.md`. Checkmark OPEN until owner F5 visual acceptance. **VERIFY-CLOSE 2026-10-22 (factory verify-close, job 014-dev-godot-001):** on source f7f23060, Godot 4.7.2.stable.official.ed1daf0bf, throw-away user:// saves via `Main.boot_save_path_override` (owner save untouched): `--headless -s res://tests/m42_navigation.gd` PASS 12/12 (real `main.tscn` root at HOME, Play -> GameplayHost, level 1 played to WON -> Results CLEAN NEXT, retry/back/no-orphan), `m42_opening.gd` PASS (opening -> Home, fail-safe -> Home), `m42_home.gd` PASS, `m44_ftue.gd` PASS 23/23; 0 SCRIPT ERROR/Parse Error. Windowed (display, OpenGL Compatibility, Iris Xe) rerun of m42_navigation reached real WON; its only fails are headless-only asserts (with a display the auto policy plays the opening before Home, as F5 does). Owner F5 acceptance per CLAUDE.md §0D.1. LOCAL_PASS.
- Parallel Family APK audit [2026-10-10]: **SB-M47-001 / SB-M47-002 — OFFLINE FIRST-TEN ANDROID DEBUG EXPORT = FIRST10_APK_TECHNICAL_PASS / CLOSED FOR LIMITED SLICE; SB-M47-003 REAL DEVICE INSTALL PENDING AT 2026-10-10 AUDIT; LATER OWNER-REPORTED BOOT PASS.** Independent audit: `coordination/sessions/M47-FAMILY-APK-C001/M47_FAMILY_APK_C001_CHATGPT_INDEPENDENT_AUDIT_V01.md`. Genuine signed APK from GitHub Actions run `38040561355`, built source `857d9033`, artifact `11666135912` (expires 2026-11-09), APK SHA-256 `496509477f38841879ea36e87a0ad5a5ac75f4615f70abc8fb96af288839c75d`, size 513,559,541 bytes; scan of actual PCK/APK reports 0 forbidden paths among nine owner-excluded trees, 663/663 runtime-referenced paths available. This is **strictly offline**, built-in Levels 1–10 only, no INTERNET permission or R2 manifest, no publisher secret. Device touch/portrait/save/performance and online Level 11–50 updating remain unverified. Per-run debug signing cert changes; uninstall old test build to install newer (may remove device saves). No repo cleanup authorized.
- Owner Android Family device feedback [2026-10-10]: **SB-M47-003 OWNER-REPORTED INSTALL + BOOT PASS; SB-M47-004 REAL-DEVICE TOUCH FAIL ON FIRST BUILDS; V02 CODE TECHNICAL PASS / OWNER RECHECK PENDING.** Wife installed/opened first-ten Android APK, but a single stationary tap on front Supply color batch does NOT easily move batch to the five-slot execution strip; owner reports "tutup 5li slota dogru ittirmen lazim sanki" (appears to require dragging toward slots). This is a symptom, NOT authorization to implement drag. One touch-down+up on a valid front must transfer exactly one whole FIFO batch to rightmost EMPTY slot via production controller, no swipe/hold/destination tap; 3/4/5 columns and 5/6 slot layouts, proper touch geometry, no duplicated synthesized-mouse event; preview rows unclickable and full/pause/modal/terminal reject atomically. Owner record: `coordination/sessions/M47-FAMILY-APK-TOUCH-R01/OWNER_DEVICE_FEEDBACK_V01.md`. Claude prompt: `coordination/sessions/M47-FAMILY-APK-TOUCH-R01/CHATGPT_PROMPT_V01.md`; audit criteria: `coordination/sessions/M47-FAMILY-APK-TOUCH-R01/CHATGPT_AUDIT_CRITERIA_V01.md`. New signed offline APK + physical Android owner retest required; **M47 technical export PASS does not imply playable touch PASS**. HISTORICAL V01 priority superseded by later V02 audited code fix; owner physical tap retest pending. R2 critical path stays open and independent.
- Older status bullets and all completed items: `docs/migration/legacy-task-trackers/TASKS_ARCHIVE_2026-10-22.md`.

## Tasks
# SCRUBBOTS — MASTER TASK PLAN

> **H!veAI tracking [OWNER-LOCKED — updated 2026-09-27]:** repository-root `TASKS.md` is the one and only live project-status tracker and H!veAI parser input. The top `Project Status` block controls current milestone, sprint, task, actor, next action, workflow status, and progress. **Do not recreate `coordination/SESSION_INDEX.md`, `coordination/AUDIT_INDEX.md`, `docs/04_ROADMAP.md`, `.hiveai/PROJECT_DASHBOARD.md`, or any equivalent parallel tracker/status mirror.** Audit/prompt/log files may exist only as cycle evidence, never as project-state authorities. **ChatGPT is the sole writer of root `TASKS.md`; Claude/Codex read it but do not edit it. ChatGPT updates it after each independent audit, owner-gate decision, and before handing off the next implementation prompt.**

Permanent master execution roadmap for the SCRUBBOTS project. This file is
authoritative alongside `CLAUDE.md`. Read both at the start of every
session. ChatGPT updates this file after audit/owner-gate decisions; implementation agents do not mutate it.

Canonical local project: `C:\Users\sekip\Desktop\ScrubBots`
Canonical repository: `https://github.com/Sekiph82/Scrubbots`
Primary branch: `main`

Verified at time of writing (end of Phase M06):
- HEAD commit at phase start: `89c7d43` ("feat: enforce Scrubbots
  difficulty board ranges") — see `docs/05_TECH_DECISIONS.md` and
  CHANGELOG for the Phase M06 commit that follows it.
- Working tree: clean, `main` up to date with `origin/main`
- Godot: **4.7.2-stable** is the current owner-confirmed development version. The historical M00 4.7.1 installation evidence below is preserved as history; exact current build hash should be refreshed from local `godot --version` during the next local validation pass.
- Headless test suite (`tests/run_tests.gd`): **774/774 checks PASS**, exit
  code 0 (grown through M09/M11/M12/M13 and the META-C004 ACTIVE/CLEARED
  renderer migration; recomputed from the suite summary, not hardcoded)
- Official production difficulty bands (Easy/Medium/Hard/Very_Hard,
  20..59, max 59×59 = 3,481 cells) implemented and enforced via
  `DifficultyRules` + `ProductionLevelValidator`, kept separate from the
  generic dimension-agnostic `LevelValidator`/`BoardState` core.
- `BoardRenderer` implemented (single Image/ImageTexture, zero per-cell
  Nodes at any board size — ADR-011) with the owner-locked ACTIVE/CLEARED
  model (ADR-019): ACTIVE = source palette color/opaque, CLEARED =
  transparent (background shows through). **Owner manual QA of the
  transparent model is complete** (SB-M10-005..011 owner-approved on 2026-09-06).

## Status tags

```text
[x]  = completed AND validated (evidence exists: ran, passed, inspected)
[ ]  = incomplete / not validated
```

A task is never `[x]` merely because code exists somewhere. It must have
been run/validated. Additional tags used throughout:

```text
[LOCKED]            — owner-specified rule, do not silently change
[DESIGN GATE]       — unresolved, owner must decide, do not invent
[TECH DECISION]     — architecture choice, see docs/05_TECH_DECISIONS.md
[PERFORMANCE]       — has a performance-sanity dimension
[CONTENT]           — real art/level content work
[VISUAL REFERENCE]  — depends on owner-supplied visual assets
[QA]                — verification/testing work
[DEFERRED]          — intentionally postponed, not blocked
```

---

## GLOBAL DEFINITION OF DONE

A milestone is complete only when **all** relevant conditions below are
satisfied. If a required validation could not run, the milestone is **not**
complete — record why instead of marking `[x]`.

- Implementation exists.
- Code parses in the actual installed Godot version (currently **4.7.2-stable**).
- Headless tests pass where applicable.
- Invalid input is tested, not just the happy path.
- Regression tests (everything previously passing) remain passing.
- No fatal Godot errors in headless/editor output.
- Warnings are understood or fixed, not ignored.
- Relevant performance sanity tests are executed and results recorded.
- Any task that integrates **GameFeelFlow** or **Saltmire Spark** must also pass an actual Godot runtime visual check through the project's Godot AI workflow; headless/unit/static inspection alone cannot close a visual-effect task. Runtime evidence must exercise both FULL and Reduced Effects behavior and a plugin-unavailable/fail-open path where practical.
- Third-party presentation addons remain optional presentation dependencies only: their absence/failure must never block terminal completion, reward commits, saves, navigation or gameplay authority; exact addon version/API, license notice, autoload availability and clean-clone parse/export must be verified before the related task closes.
- The 59×59 (3,481-cell) maximum production workload is considered wherever
  cost scales with board size.
- Documentation reflects the actual implementation, not an aspirational one.
- `TASKS.md` is updated by ChatGPT after independent audit/owner-gate review to reflect true status.
- `git diff` is reviewed before commit.
- No cache/build junk (`.godot/`, import cache, build output) is committed.
- A focused, understandable commit exists.
- Push to `origin/main` succeeds when possible (never force-pushed).
- The current phase's Desktop log (see "PHASE LOG WORKFLOW" below) is
  updated to reflect the work.

---

## PERMANENT CLAUDE SESSION WORKFLOW

Every future numbered implementation prompt must:

1. Read `CLAUDE.md`.
2. Read `TASKS.md` (this file) without modifying it.
3. Read relevant `docs/` files for the system being touched.
4. Inspect `git status` / branch / remote.
5. Confirm which milestone is actually current (don't assume from memory).
6. Preserve owner files and artwork — never delete/regenerate without cause.
7. Work only on the requested scope — no drive-by rewrites.
8. Reuse existing systems (`LevelData`, `BoardState`, etc.) where appropriate
   — do not rebuild working systems for stylistic reasons.
9. Run current regression tests before major modification when practical.
10. Implement the requested milestone.
11. Add/update tests.
12. Run headless validation (`godot --headless --path . -s res://tests/run_tests.gd`).
13. Fix regressions.
14. Run relevant performance sanity tests.
15. Update authorized subsystem docs/evidence only.
16. **Do not edit root `TASKS.md`; ChatGPT owns tracker changes after audit/owner-gate review.**
17. Review `git diff` and ensure `TASKS.md` is absent from the implementation diff.
18. Commit (focused, descriptive message).
19. Push safely (`git push origin main`, never force).
20. Never force-push.
21. Write/update the matching GitHub `CLAUDE_LOG_VNN.md` and hand back `AWAITING_AUDIT`; ChatGPT then audits and updates `TASKS.md`.

---

## PHASE LOG WORKFLOW (supersedes the old per-prompt handoff-log convention)

**One development phase = one continuous Desktop log file**, not one log
per prompt. A "phase" is a milestone-level unit of work (e.g. `M03`, `M04`)
that may span multiple Claude prompts/sessions.

- Naming: `C:\Users\sekip\Desktop\SCRUBBOTS_PHASE_MXX_LOG.md` (e.g.
  `SCRUBBOTS_PHASE_M03_LOG.md`). `MXX` matches the `TASKS.md` milestone ID
  the work belongs to.
- **Create the log file at the START of the phase's first prompt**, before
  any inspection or code changes — not at the end.
- If the log file already exists for the current phase, **read it and keep
  updating the same file** — never create a second log for the same phase
  (no `_RETRY`, no `_B`, no `PROMPT_03B` variants). Every prompt working on
  the same phase reuses the same file.
- Update it after every meaningful checkpoint: environment/repo inspection,
  baseline tests, architecture decisions, each implementation step,
  fixtures added, test-suite changes, each significant failure/debugging
  discovery, final tests, before commit, after commit, after push. The log
  must let another agent resume work correctly even if the session stops
  unexpectedly mid-phase.
- Keep the chronological journal/history in the log even after issues are
  fixed — do not erase past failures once resolved.
- When the phase is genuinely complete, set `PHASE STATUS: COMPLETE` and
  fill in the Final Phase Summary section — without deleting the earlier
  chronological content.
- Only start a **new** log file when moving to a genuinely new phase (e.g.
  `M03` complete, `M04` begins).
- The phase log is **never committed** to the Scrubbots Git repository — it
  lives only on the Desktop.

Prompts 01 and 02 predate this convention and used one-log-per-prompt
(`SCRUBBOTS_PROMPT_01_LOG.md`, `SCRUBBOTS_PROMPT_02_LOG.md`) — those are
historical and not retroactively merged. `SCRUBBOTS_MASTER_TASKS_LOG.md`
(the master-plan prompt) also predates this convention. Starting with
Phase M03, use the phase-log format above.

---

## LOCKED GAME RULES

These rules override older documentation where a conflict exists. They are
not open for silent reinterpretation.

### 8.1 — Mobile-first `[LOCKED]`

SCRUBBOTS is mobile-first. Primary orientation: **portrait**. Current
provisional virtual design resolution: **1080×1920** (see ADR-002 in
`docs/05_TECH_DECISIONS.md`). Gameplay code must remain independent of
physical phone resolution — this is a display setting, not gameplay logic.

### 8.2 — Variable-size logical board `[LOCKED]`

The board engine remains **variable-size**. It must never become a fixed
40×40, 50×50, 1600-cell, 2500-cell, or 3481-cell engine. Board dimensions
come from level data. Generic code uses `width`, `height`, `width * height`
— never a hard-coded cell count. See ADR-008.

### 8.3 — Official difficulty / board size bands `[LOCKED HISTORICAL RUNTIME COMPATIBILITY]`

The legacy production validator currently retains these dimension bands while Difficulty V1 migration is still open. They are not current player-facing difficulty truth; see `coordination/OWNER_DIFFICULTY_PROGRESSION_DECISION_V01.md` and `CLAUDE.md`.

| Difficulty | Width range | Height range | Min cells | Max cells |
|---|---|---|---|---|
| EASY | 20–29 | 20–29 | 20×20 = 400 | 29×29 = 841 |
| MEDIUM | 30–39 | 30–39 | 30×30 = 900 | 39×39 = 1521 |
| HARD | 40–49 | 40–49 | 40×40 = 1600 | 49×49 = 2401 |
| VERY_HARD | 50–59 | 50–59 | 50×50 = 2500 | 59×59 = **3481** |

Examples of legacy-validator-valid boards: Easy `20×27`, Medium `34×39`, Hard `48×41`, Very Hard `53×59`.

**Current required production-capable maximum: 59×59 = 3,481 logical cells.**

### 8.4 — Rectangular boards `[LOCKED]`

Boards do **not** have to be square. Width and height are validated
independently. Never assume `width == height` in generic systems.

### 8.5 — Current maximum required workload `[LOCKED]`

`59×59 = 3,481` cells. All systems whose cost scales with board size must
eventually be tested against this workload: LevelData validation,
BoardState, BoardRenderer, color candidate index, reachability/access,
target selection, routing-related board queries, clearing updates, save/load
of level state if used, and production content validation.

### 8.6 — Test/dev fixtures vs. production levels `[LOCKED TECHNICAL RULE]`

The existing `test_3x2.json` fixture (6 cells) is valuable because it
proves the board engine is genuinely generic — it is **not** a production
level and must never be treated as one. Development fixtures may use a
`TEST` difficulty/context. `TEST` must never become a production difficulty
exposed to players, and the future production `LevelCatalog` must reject
accidental `TEST` fixtures (see M03, M35).

### 8.7 — Logical pixels `[LOCKED]`

One logical artwork square = one logical pixel = one board cell. Logical
cells are game data, never physical display pixels, and are never
represented as thousands of heavyweight Godot Nodes (see ADR-004, ADR-008).

### 8.7A — Global 16-color pixel-art palette `[LOCKED OWNER DECISION]`

Canonical machine-readable palette:
`data/palettes/scrubbots_palette_v3.json`

Palette authority version and Level Data schema version are independent. Void-free Level Data stays V1 (`version: 1`); palette v3 does not authorize Level Data V2. Level Data version 2 exists only for VOID cells (ADR-030, owner 2026-10-08).

Canonical human-readable rule:
`docs/08_PIXEL_ART_PALETTE_RULES.md`

Production logical artwork cells may use **only C01..C16**. No other logical
pixel color is legal without an explicit owner rule change and palette version
change. CLEARED alpha-0 transparency, gameplay background and
presentation-only grid/border overlays are not logical artwork colors and do
not add palette IDs.

### 8.7B — Production used-color envelope `[OWNER-LOCKED DIFFICULTY V1]`

Production artwork may use **3–12** distinct canonical C01..C16 colors. The older class-specific `3–5 / 6–7 / 8–9 / 10–12` mapping is historical and superseded as difficulty-class legality; color count/distribution are Difficulty V1 score inputs instead.

### 8.8 — Five batch slots `[OWNER-LOCKED 2026-09-17]`

Primary gameplay presentation uses **exactly five batch slots**. They start EMPTY.
The player never chooses a destination slot. Selecting a legal supply batch automatically
places it into the **rightmost currently EMPTY slot**. Existing occupied slots never shift
or reorder. If all five slots are occupied, a supply selection is rejected atomically and
the supply column must not advance.

Duplicate colors across multiple occupied slots are legal and are part of the puzzle.
Each occupied slot owns one immutable batch identity with color, initial robot count,
remaining-to-clear count, committed/in-flight count, placement sequence and lifecycle state.

### 8.8A — Batch supply columns `[OWNER-LOCKED 2026-09-17]`

- Production supply supports 3, 4 or 5 independent FIFO columns.
- V1 gameplay validation uses **three visible rows per column**.
- Only the front/top batch in each column is selectable.
- Row 2 and Row 3 are preview-only future batches.
- Everything deeper than the preview window is hidden from the player.
- Selecting a front batch advances **only that column** by one position.
- The previous Row 2 becomes selectable, Row 3 becomes Row 2, and the next hidden batch
  enters Row 3. Other columns remain unchanged.
- Each batch is `color + positive robot_count`; its identity is stable once generated.
- Supply generation must conserve the level's logical color totals and must ultimately be
  accepted only when the Solvability Engine proves at least one legal completion sequence.

### 8.8B — Batch quota / slot lifecycle `[OWNER-LOCKED 2026-09-17]`

A batch count means the number of matching logical pixels that batch must successfully clear.
A count is **not** spent when a robot is merely spawned. It decreases only after an
authenticated arrival clears the batch's assigned target pixel. A batch with remaining quota
but no currently targetable matching pixel enters WAITING and stays in its slot. It resumes
automatically when later clearing exposes a legal matching target. A slot becomes EMPTY only
when the batch has zero remaining work and zero committed/in-flight assignments.

### 8.8C — Same-color arbitration and target claims `[OWNER-LOCKED 2026-09-17]`

Future inaccessible pixels are never pre-claimed. When a matching pixel becomes currently
targetable, same-color occupied batches compete deterministically by **oldest placement first
(FIFO)**. The oldest batch with uncommitted quota receives priority; if its remaining dispatch
capacity is exhausted, additional targets may flow to the next same-color batch.

A target claim and ReservationState reservation must be atomic. One logical pixel may belong
to at most one live assignment at a time, regardless of how many same-color batches are in
the five slots. Existing TargetSelector bottom-most/left-most ordering remains the target-order
policy among currently targetable, matching, unreserved cells.

### 8.8D — No ghost robots `[OWNER-LOCKED 2026-09-17]`

**No target, no reservation, no valid route, no robot.** A Scrubbot may be instantiated only
after a unique matching target has been selected, atomically reserved/claimed, and a legal
route to that exact target has been produced and validated. A spawned robot never wanders,
never spawns without work, never silently retargets, and never shares a target with another
robot. Route-build failure releases the provisional claim/reservation and consumes no batch
quota.

### 8.8E — Solvability and deadlock `[OWNER-LOCKED 2026-09-17]`

Generated supply is production-valid only if a deterministic solver can prove at least one
legal player-choice sequence that clears the entire level under the real five-slot, FIFO
column, targetability, claim, routing and batch-quota rules. Runtime must distinguish temporary
WAITING/STALLED states from a proven deadlock. In-flight work or any legal future action that
can open progress means the position is **not** deadlocked. A deadlock may be declared only
when no legal future action sequence can produce further authenticated clearing.

### 8.9 — Scrubbot behavior `[LOCKED]`

- Scrubbots leave slots one at a time.
- A Scrubbot does not leave unless a reachable/targetable matching target
  exists (a blocked/unreachable matching-color ACTIVE cell is not enough).
- A Scrubbot has a valid, reachable target *before* being dispatched.
- It visually moves from slot to target.
- On arrival the target logical pixel becomes CLEARED (transparent; the
  gameplay background shows through).
- It then disappears/finishes.
- It does not collect or carry pixel color.
- It does not return to the slot; no return route is needed.

Scrubbot movement across the picture is one of the most important pieces
of the game's visual identity.

### 8.10 — TargetSelector vs. RoutingSystem `[LOCKED ARCHITECTURE]`

`TargetSelector` answers **WHAT** valid cell should be assigned.
`RoutingSystem` answers **HOW** the Scrubbot travels there visually. Never
combine them. `BoardRenderer` never chooses targets. `ScrubbotAgent` never
searches the board and picks its own arbitrary target. The routing
implementation must remain replaceable (see ADR-005).

### 8.10A — Target selection positional priority `[LOCKED OWNER DECISION — 2026-09-13]`

For a requested slot/color, TargetSelector keeps the canonical eligibility
rules: the candidate must be a valid board index, ACTIVE, matching the requested
color, unreserved, and currently targetable/reachable according to authoritative
access truth. **Among candidates that can otherwise proceed under that contract,
selection priority is bottom-most first (largest board-local `y`), then left-most
within that row (smallest board-local `x`).** A blocked/unreachable lower or
leftward raw candidate never wins merely because of position; the selector
continues to the next candidate in deterministic bottom-to-top / left-to-right
priority. This is a WHAT-policy in TargetSelector only. Routing still decides HOW
to travel to the already-selected target and must not retarget based on geometry.

### 8.10B — Scrubbot Railroad V1 `[OWNER-LOCKED CURRENT — 2026-09-17]`

The exact adjacent one-cell exterior ring proven in M21 V07–V10 remains historical evidence only. `coordination/OWNER_SCRUBBOT_RAILROAD_DECISION_V01.md` remains authoritative for canonical Railroad V1 geometry, while `coordination/OWNER_SCRUBBOT_RAILROAD_INTERIOR_PATH_DECISION_V01.md` supersedes only the old straight-only post-rail target approach.

Railroad V1 uses one consistent robotic cleaning rail around every level. Geometry is derived from board `W×H`: artwork-to-rail inner-edge clearance `2.0` logical cells, rail width `1.0` logical cell, therefore rail centreline `2.5` logical cells outside each board boundary. Scrubbots start from the exact owning SlotCell anchor, visibly connect to the BOTTOM rail, and remain on canonical rail sides/corners during all exterior travel.

A Scrubbot may leave Railroad V1 only through a legal orthogonal ingress into OPEN/CLEARED perimeter gameplay space. Rail departure does **not** have to be aligned with the final target row/column. After ingress, the route may traverse OPEN/CLEARED board cells by four-neighbour orthogonal movement with one or more 90-degree turns. Non-target ACTIVE cells remain hard blockers; the assigned ACTIVE target is enterable only as the final endpoint. No diagonal, corner-cut, teleport, free-space exterior shortcut, non-target ACTIVE tunnelling or retargeting is legal.

For an already-assigned target, routing evaluates legal ingress/interior-path combinations and chooses the shortest legal total route including slot connector, rail travel, ingress, interior path and final arrival. Equal-distance side priority remains `BOTTOM → LEFT → RIGHT → TOP`; same-side ties must be deterministic. TargetSelector §8.10A remains WHAT-only and RoutingSystem remains HOW-only.

Railroad V1 is routing/presentation infrastructure only: it is not LevelData, BoardState, C01..C16 artwork, difficulty truth, batch-supply truth or reservation ownership. Collision/lane/congestion rules remain design-gated unless later owner decisions explicitly lock them.

### 8.10C — Supply-front-only owner gameplay activation `[OWNER-LOCKED CURRENT — 2026-09-17]`

The production player interaction is **selectable front batch click/tap**, not direct slot activation. Normal gameplay has five automatic destination/Scrubbot-origin slots; Economy V1 +1 Slot may expand authoritative capacity to exactly six for the current attempt. Slots are not player-selectable placement controls.

The player may normally activate only the current front/top batch of a supply column. A successful selection transaction sends that batch to the rightmost currently EMPTY slot. If every slot in the current authoritative capacity (5 normally, 6 with +1 Slot active) is occupied, the selection is rejected and the supply column does not advance. Economy V1 Selector is the single owner-authorized exception to normal front-only selection and must use its own atomic/solver-safe transaction. Once a batch occupies a slot, Auto Dispatch later spawns Scrubbots automatically from that exact SlotCell anchor only after the target-claim/reservation/valid-route transaction succeeds.

The historical M21/M22 direct color-slot click path remains valid evidence for those earlier vertical-slice and Railroad tests, but it is superseded as the production core-loop interaction. Do not retain or add hidden keyboard dispatch shortcuts such as SPACE. Presentation input must feed the real Batch Supply → Five-Slot Batch → Claim → Auto Dispatch → Routing → ScrubbotAgent → authenticated clear chain.

### 8.10D — Gameplay speed / automatic endgame acceleration `[OWNER-LOCKED CURRENT — 2026-09-18]`

Production gameplay V1 supports exactly **1x** and **2x** temporal speed. A new level/full reset starts at 1x. Shipping manual 2x is no longer always free: Economy V1 requires a valid current-level entitlement (200 SB) or timed entitlement (15m/300 SB, 30m/500 SB, 60m/750 SB). Timed entitlement uses real wall-clock expiry and continues in gameplay, menus, pause, background and while the app is closed.

The game automatically switches to **2x for free** immediately after authoritative **M23 supply exhaustion**: every 3/4/5 FIFO column has zero remaining batches, including all formerly hidden batches, because the final front-batch transaction has been successfully accepted and committed into M24. The trigger is not full-slot occupancy and is not visible-row emptiness while hidden batches remain. A rejected final transfer does not trigger auto-2x.

2x accelerates time-based gameplay execution/presentation only. It must not change M23 FIFO order, M24 placement/accounting, M25 target/claim arbitration, TargetSelector priority, ReservationState ownership, Railroad/routing geometry, M26 no-ghost semantics, authenticated clears or M27 solver/deadlock meaning. GameplaySpeedAuthority owns factor only; Economy V1 SpeedEntitlementService owns paid manual permission/expiry. Canonical decisions: `coordination/OWNER_GAMEPLAY_SPEED_RULE_V01.md` and `coordination/OWNER_ECONOMY_REWARDS_V01.md`.

### 8.10E — Five-slot displayed batch count `[OWNER-LOCKED CURRENT — 2026-09-19]`

The large/main number shown on an occupied production batch slot means **robots still waiting in that slot**, not raw unresolved quota. Canonical display truth is:

`display_count = M24 capacity = remaining_to_clear - committed`

Example: a newly placed Blue 50 displays 50; after one successful robot commit/dispatch it displays 49 immediately; with two in-flight it displays 48. Authenticated arrival later decrements both `remaining_to_clear` and `committed`, so the visible waiting count does not jump back. The current historical presentation `50 (2)` is superseded.

This is presentation only. M24 authoritative accounting remains unchanged: `remaining_to_clear` decreases only after authenticated clear; `committed` tracks in-flight work; completion still requires remaining=0 and committed=0.

ACTIVE/WAITING internal lifecycle semantics are also unchanged. ACTIVE means eligible/not currently marked unavailable; it does not guarantee a robot is presently moving. WAITING means no currently claimable reachable target for that batch/color, and the batch must be automatically reconsidered after relevant board changes. Canonical decision: `coordination/OWNER_BATCH_SLOT_DISPLAY_DECISION_V01.md`.

### 8.10F — Live five-slot presentation synchronization `[OWNER-LOCKED CURRENT — 2026-09-19]`

The production five-slot strip must reflect **current authoritative M24 state**, not merely the snapshot captured after the last player batch placement.

Fresh detached slot snapshots must be pushed after player-visible M24 mutations including dispatch commit, ACTIVE->WAITING, WAITING->ACTIVE wake, rollback, authenticated-clear finalization, slot completion->EMPTY and reset. UI remains presentation-only and must not run target selection/routing to guess lifecycle state.

Hazard Bot reference: after the first two Blue50 batches have cleared the initial 100 reachable blue cells, the early Brown3 batch still has no immediately reachable brown target in the accepted M27 solution trace. Its player-facing slot state must therefore be WAITING until later black/open-corridor progress wakes it. A stale ACTIVE badge after that point is a presentation-sync defect. Canonical decision: `coordination/OWNER_FIVE_SLOT_LIVE_PRESENTATION_SYNC_DECISION_V01.md`.

### 8.11 — Win streak `[LOCKED — Economy V1]`

```text
1 consecutive progression win   -> +1 SB
2 consecutive progression wins  -> +5 SB
3 consecutive progression wins  -> +10 SB
4 consecutive progression wins  -> +25 SB
5+ consecutive progression wins -> +100 SB per win
```

Never reinterpret `1, 5, 10, 25` as win-count thresholds. Only this streak-bonus SB advances Gift Meter. Every multiple-of-5 active streak also grants +1 Bot Part. Progression loss or restart after gameplay begins resets streak; replay cannot advance it.

### 8.12 — Economy & Rewards V1 `[OWNER-LOCKED 2026-09-18]`

Canonical decision: `coordination/OWNER_ECONOMY_REWARDS_V01.md`. Machine tuning: `data/config/economy_rewards_v1.json`.

- Scrub Bucks are the only general spendable soft currency.
- Stars, Star Exchange and Event Points are removed. Star Exchange becomes Cards Exchange.
- Hearts: max 5, +1 every **15 real-world minutes / 900 seconds** [OWNER-LOCKED 2026-09-27].
- Bot Parts: robot-unlock-only resource; every post-Scrubby robot costs 250.
- Gift Meter progress comes ONLY from Win Streak SB and has 10/50/250/500/1000 milestones with rollover.
- Exactly four boosters exist: +1 Slot 500 SB, Random 350 SB, Selector 500 SB, Tornado 750 SB.
- Daily has 3 tasks, consecutive-login count and a repeating 5-day reward cycle; Daily and Gift Bar can grant booster charges.
- Duplicate Collection cards exchange to SB; protected first copies cannot be exchanged.
- Real-money monetization remains a separate M57 gate.

### ADR-009 — Explicit preload() convention `[LOCKED UNTIL EXPLICITLY REVISITED]`

Prompt 02 found bare `class_name` cross-script references unreliable in a
headless environment with no prior editor-built global class cache. The
working solution: `const LevelData = preload("res://scripts/data/level_data.gd")`
instead of relying on global class-name resolution. Future scripts in the
data/gameplay/test core should follow this convention unless a future task
deliberately revisits ADR-009 and proves an alternative equally reliable
via headless tests. Do not casually convert back to bare `class_name` for
stylistic reasons.

### Production gameplay background `[LOCKED]`

- BG01 **Midnight Slate** = `#202533` / RGB(32,37,51).
- CLEARED alpha-0 cells reveal BG01 underneath.
- BG01 is not part of C01..C16 and is never a logical LevelData cell
  color, and never counts toward difficulty distinct-color totals.
- Debug-only transparency backgrounds may differ for visibility.

---

## VISUAL REFERENCE SYSTEM

SCRUBBOTS has (per the owner) prior artwork and visual concepts. The
project must use them rather than defaulting to generic programmer art —
but **only artwork that physically exists in this project or is supplied
during a task counts as available**. A visual discussed in a prior chat is
not automatically a local file.

**Verified at time of writing**: owner references and the approved M21 Hazard Bot are now present in-repo; historical “all empty” statements elsewhere are superseded by current inventory/coordination evidence.

### 9.1 — Visual reference priority `[LOCKED]`

**Priority 1 — Owner-approved original SCRUBBOTS artwork.** Canonical
visual reference: character concepts, gameplay concepts, five-slot layouts,
pixel-art level artwork, themed level artwork, original UI ideas, effects
concepts, screen compositions. If original approved artwork conflicts with a
generic placeholder, the original artwork wins.

**Priority 2 — Owner-supplied SCRUBBOTS reference images.** May guide
composition, proportions, pixel-art density, UI positioning, Scrubbot size,
slot size, board presentation, visual hierarchy.

**Priority 3 — External game references.** Inspiration/reference only —
movement density, clarity, pacing, spatial readability, touch ergonomics,
pixel construction methodology. Must never be copied.

### 9.2 — Colony Flow reference limit `[LOCKED]`

May be referenced only for the broad feeling of many tiny agents moving
across a play area and the abstract idea of perimeter travel. SCRUBBOTS intentionally differs in characters, rail visual language, artwork, UI, composition and exact movement implementation:

```text
Correct SCRUBBOTS flow:
  selectable supply-front batch -> automatic rightmost-empty slot -> unique claim/reservation -> valid route -> exact slot connector -> Scrubbot Railroad -> legal OPEN/CLEARED ingress -> orthogonal interior corridor -> clean -> disappear

NOT:
  travel to resource -> collect resource -> carry resource back -> return home
```

Never copy Colony Flow's characters, art, level composition, UI, icons, exact rail/frame appearance, animations, routing visuals, or source code.

### 9.3 — Pixel art reference rule `[LOCKED]`

Previously supplied game screenshots may be used only as reference for
*pixel construction method*, where explicitly approved — never for
characters, compositions, object placement, or level art. External-reference
colors must never redefine the SCRUBBOTS palette. The exact production palette
is owner-locked in §8.7A / `data/palettes/scrubbots_palette_v2.json`.
The goal is understanding how a readable image is built from a limited
logical grid. SCRUBBOTS level artwork remains original.

### 9.4 — Existing SCRUBBOTS level art `[LOCKED]`

Existing original SCRUBBOTS level artwork is intended to become real playable
content once owner-approved source files are supplied/recorded. Never regenerate
such pieces from memory and present the result as “the original.” The M21 Hazard
Bot source is the first owner-approved production-art fixture and must remain
byte-identical unless the owner explicitly replaces it.

### 9.5 — Reference file availability `[LOCKED]`

Claude only has access to artwork physically present in the project or
supplied during the current task. If an expected visual does not exist
locally: `STATUS = AWAITING OWNER ASSET`. Do not fabricate it, do not mark
its audit complete, do not claim a pixel-accurate comparison was performed
against something that doesn't exist locally.

### 9.6 — Recommended visual directory structure

```text
assets/
└── art/
    ├── references/
    │   ├── gameplay/
    │   ├── ui/
    │   ├── scrubbots/
    │   ├── pixel_method/
    │   └── external_inspiration/
    ├── characters/
    │   └── scrubbots/
    ├── levels/
    │   ├── source/
    │   │   ├── easy/
    │   │   ├── medium/
    │   │   ├── hard/
    │   │   └── very_hard/
    │   └── previews/
    ├── ui/
    └── effects/
```

---

## VISUAL PRODUCTION / MASTER UI WORKFLOW [LOCKED OWNER DECISION]

1. Visual production is an integral part of the **main SCRUBBOTS mobile game project and roadmap**. It must not be split into a Level Factory/Content Pipeline-style sidecar or treated as an unrelated final art pass.
2. ChatGPT image generation is the owner-preferred primary illustration-generation workflow for UI/character visual production. Magnific MCP remains an approved fallback/alternate. PixelLab/native pixel AI work is separately scoped to semantic pixel-art generation and does not own puzzle logic.
3. AI image generation is a **development-time tool only**. The shipping game must never require generation APIs, credentials, or credits at runtime. Owner-approved generated outputs become ordinary versioned Godot assets.
4. Existing owner-created SCRUBBOTS artwork is the first visual authority. Import/copy and classify owner references before generating replacements or variants. Never overwrite or delete the owner's originals.
5. AI-generated full-screen mockups are art-direction/reference material, not shippable UI. Production screens must be composed from responsive Godot Controls/Containers plus approved illustration assets.
6. Prefer native Godot UI for panels, buttons/interaction containers, progress bars, slots, color tiles, currency counters, text, popup bodies, dim layers and responsive layout. Use generation for art that genuinely benefits from illustration generation: characters, character poses/portraits, boosters, rewards, difficulty emblems, decorative props, collection/event art and similar branded artwork.
7. Raw generation candidates and owner-approved production assets are different lifecycle states. Never silently regenerate, replace or overwrite an approved production asset.
8. Every milestone that requires new visual assets owns its own visual-generation/review/import tasks. Do not postpone all visual production to one disconnected end-of-project art phase.
9. `docs/MASTER_UI_SYSTEM.md` is the canonical responsive UI architecture contract. `ASSET_GENERATION_MANIFEST.json` is the machine-readable provider-agnostic generation queue/provenance contract; `assets/ui/HOME_ASSET_MANIFEST.json` is the Home-screen preproduction inventory.
10. `BoardRenderer` remains the existing single-`Image`/`ImageTexture` data-oriented renderer. The Master UI system must not replace logical board rendering with one UI node per cell.
11. Visual milestone completion requires actual owner-approved assets where required, correct Godot import/binding, responsive validation and regression evidence. A generated image existing on disk is not by itself completion.
12. Railroad V1 structural geometry is native/data-driven and shared by routing/presentation; V02 does not require generated railroad art. Future visual skinning may not change railroad gameplay geometry.

Home preproduction note (owner decision 2026-09-18): `assets/ui/HOME_ASSET_MANIFEST.json` is preproduction inventory/scaffolding only. Creating the inventory and folders does not close M42 or authorize jumping ahead of M23–M27 core-gameplay sequencing.

### Visual production order

1. **Reference intake and canonical visual selection first.** Import owner references copy-only into the repository reference inbox, inventory/classify them, and select canonical Scrubby/gameplay/home/popup references before broad generation.
2. **Core gameplay engineering continues without waiting for decorative art.** Target selection, routing, dispatcher/agent behavior, cleaning rules and other gameplay-critical work must not be blocked by decorative asset production when programmer art is sufficient.
3. **First real-art vertical slice.** Validate gameplay with owner-approved real level/pixel artwork before treating production visuals as proven. AI image generation must not invent canonical puzzle truth or replace the level-data/puzzle-validation pipeline.
4. **Production gameplay UI asset generation begins when the relevant gameplay UI milestones open.** Generate only assets required by that milestone, review them, promote approved variants, then bind them to reusable Godot components.
5. **Final Scrubbot visual production happens in the existing Scrubbot visual milestone**, using the canonical Scrubby reference and approved visual language.
6. **Home, Results, Tutorial, Collection, Shop, Events and later screens generate their own required assets inside their existing milestones.** They do not wait for a separate global art project.
7. Final visual polish is a consolidation/QA pass over already-integrated milestone-owned art, not the first time production art is introduced.

---

## VISUAL ASSET PRODUCTION STATUS [CONTENT]

Canonical discovery index for Claude/Godot UI integration:
`assets/ui/VISUAL_ASSET_INDEX.md`

- [x] SB-UI-VIS-004 Integrate/audit the final visual-closure batch P2-145..P2-157 from `codex/visual-assets-production` into `main`. Source commit: `65b26242f996f210a923b4536c7083f6f2d005cc`. This batch contains 9 robot-perk icons, 3 Collection state assets, and the canonical 10-robot Cleaning Crew group art. DONE 2026-10-22 (factory verify-close): 65b26242 is ancestor of main; all 14 PNGs (9 perks, 3 Collection states, cleaning_crew_group) present on HEAD with identical blob hashes; indexed in assets/ui/VISUAL_ASSET_INDEX.md (P2-145..P2-157); perk icons bound in data/config/robot_roster_v1.json.
- [x] SB-UI-VIS-005 After P2-145..P2-157 integration, refresh/verify the `main` copy of `assets/ui/VISUAL_ASSET_INDEX.md` so Claude sees the final 157 / 157 Phase 2 targets and complete production paths. Verified 2026-10-22 (factory 024): script found rows P2-001..P2-157 all present, 0 duplicates, 0 missing files on disk; index summary already states 157 / 157; no index edit needed.
- [ ] SB-UI-VIS-006 Before UI milestone closure, perform owner/Claude pixel-level QA of production assets actually used on-screen: alpha edges, text/watermark absence, mobile readability, identity consistency, compression/import settings. Path existence alone is not visual acceptance.

Static AI visual generation is considered closed after SB-UI-VIS-004/005 unless a new owner-approved feature creates a specific new requirement. Do not generate speculative World Map, XP, Star-currency, leaderboard, event, or monetization art.

---

## DESIGN GATES

Unresolved. Do not silently invent final decisions for these:

railroad collision/congestion/lane-separation presentation; optional railroad glow/trail polish beyond the locked V1 structure; timer; move limits; blockers; hints; analytics; achievements; leaderboard; social features; cloud save; tutorial wording; audio direction.

**Resolved owner decisions:** M30 WIN/LOSE/Retry semantics are locked in `coordination/OWNER_WIN_LOSE_RETRY_DECISION_V01.md`. Economy V1, Hearts, boosters, currency and related soft-economy rules are separately locked in `coordination/OWNER_ECONOMY_REWARDS_V01.md`; real-money monetization remains M57-gated.

**Not design gates**: the global C01..C16 palette, Difficulty V1 progression/challenge architecture, target positional priority, current Railroad V1 geometry/travel/interior-ingress law, five EMPTY batch slots, rightmost-empty automatic placement, 3/4/5 FIFO supply columns, front-row-only selection, same-color oldest-batch-first arbitration, no-ghost-robot transaction law, and solver-backed supply/deadlock contracts are owner-locked.

---

## MASTER MILESTONES

### M00 — Foundation & Environment

Verified complete via repo inspection + this session's re-run of
`tools/verify_project.ps1` and `godot --version`.

Historical M00 version note: the two completed rows above record the version used when M00 was closed. The current project development version is Godot **4.7.2-stable**; do not reinterpret those historical checkboxes as the current runtime/toolchain declaration.

### M01 — Variable-Size Level Data Core

Complete from Prompt 02. Re-verified this session (files exist, test suite
passes).

### M02 — BoardState Core

Complete from Prompt 02, re-verified.

### M03 — Official Difficulty Bands + 59×59 Envelope

Historical runtime-validator milestone. Difficulty V1 later superseded class=dimension as player-facing truth, but the completed compatibility implementation remains audited evidence until separately migrated.

**Documentation**

**Production difficulty representation**

**Validation**

### M04 — Expanded Board Fixtures & Test Matrix

Do not replace existing Prompt 02 fixtures — add to them.

### M05 — Test Harness Maturity

- [x] SB-M05-006 Organize test sections as suite grows. Done 2026-10-22 (factory 027, 2a870231): convention in docs/TESTING_CONVENTIONS.md (named sections, flat tests/; existing suites not restructured). LOCAL_PASS run_suites.py m50_accessibility_audit m51_localization_readiness m45_debug_tooling aggregate=PASS (3/3), run_tests PASS, --selftest PASS.
- [x] SB-M05-007 Separate performance benchmark output from assertions. Done 2026-10-22 (factory 027, 2a870231): convention: PERF-prefixed diagnostics, no ms thresholds (docs/TESTING_CONVENTIONS.md; existing suites unchanged). LOCAL_PASS run_suites.py m50_accessibility_audit m51_localization_readiness m45_debug_tooling aggregate=PASS (3/3), run_tests PASS, --selftest PASS.
- [x] SB-M05-008 Add one-command PowerShell full-test wrapper if useful. Done 2026-10-22 (factory 027, 2a870231): tools/run_suites.py (Python stdlib, reads the CI workflow suite list + exact-summary guards). LOCAL_PASS run_suites.py m50_accessibility_audit m51_localization_readiness m45_debug_tooling aggregate=PASS (3/3), run_tests PASS, --selftest PASS.
- [x] SB-M05-009 Add regression test conventions to docs. Done 2026-10-22 (factory 027, 2a870231): docs/TESTING_CONVENTIONS.md. LOCAL_PASS run_suites.py m50_accessibility_audit m51_localization_readiness m45_debug_tooling aggregate=PASS (3/3), run_tests PASS, --selftest PASS.
- [x] SB-M05-010 Ensure future milestone completion requires regression pass. Done 2026-10-22 (factory 027, 2a870231): regression gate in docs/TESTING_CONVENTIONS.md (full run_suites.py aggregate PASS or CI validate green at closing SHA). LOCAL_PASS run_suites.py m50_accessibility_audit m51_localization_readiness m45_debug_tooling aggregate=PASS (3/3), run_tests PASS, --selftest PASS.

### M07 — Visual Reference Library `[VISUAL REFERENCE]`

- [x] SB-M07-011 Inventory level images beyond current M21 source as they are supplied/approved. (docs/LEVEL_ART_INVENTORY.md, factory 028; future supplies covered by standing rule)
- [ ] SB-M07-012 Inventory underwater level artwork if supplied. (conditional: if supplied; none as of 2026-10-22)
- [x] SB-M07-013 Inventory other original theme artwork. (docs/LEVEL_ART_INVENTORY.md + references/inventory.json, factory 028)

**Master UI / generated visual reference tasks (from UI_TASKS_APPENDIX migration)**
- [x] SB-UI-008 Select and record canonical Scrubby master reference before final Scrubby production generation. (factory 041 2026-10-23: owner chose assets/ui/final/characters/scrubby/scrubby_master.png as canonical master; Game Screens/main screen.png = Home composition ref, Collection Cards/meet the scrubbots.jpeg = supplementary; recorded in ASSET_GENERATION_MANIFEST.json, inventory.json, README.)
- [x] SB-UI-013 Validate manifest reference paths/IDs after canonical references are selected. (factory 041 2026-10-23: LOCAL_PASS stdlib check, see factory/jobs/041-apply-owner-answers/build.md)

### M08 — Level Art Technical Audit `[CONTENT] [VISUAL REFERENCE]`

Per candidate production pixel-art level:

- [x] SB-M08-001 Record filename. — 2026-10-22 (factory 030, 6f970e6e): docs/LEVEL_ART_TECHNICAL_AUDIT.md, tools/audit_level_art.py 10/10 PASS
- [x] SB-M08-002 Record original dimensions. — 2026-10-22 (factory 030, 6f970e6e): docs/LEVEL_ART_TECHNICAL_AUDIT.md, tools/audit_level_art.py 10/10 PASS
- [x] SB-M08-003 Record alpha/transparency. — 2026-10-22 (factory 030, 6f970e6e): docs/LEVEL_ART_TECHNICAL_AUDIT.md, tools/audit_level_art.py 10/10 PASS
- [x] SB-M08-004 Count colors. — 2026-10-22 (factory 030, 6f970e6e): docs/LEVEL_ART_TECHNICAL_AUDIT.md, tools/audit_level_art.py 10/10 PASS
- [x] SB-M08-005 Detect anti-aliasing. — 2026-10-22 (factory 030, 6f970e6e): docs/LEVEL_ART_TECHNICAL_AUDIT.md, tools/audit_level_art.py 10/10 PASS
- [x] SB-M08-006 Detect interpolation. — 2026-10-22 (factory 030, 6f970e6e): docs/LEVEL_ART_TECHNICAL_AUDIT.md, tools/audit_level_art.py 10/10 PASS
- [x] SB-M08-007 Determine logical-pixel grid. — 2026-10-22 (factory 030, 6f970e6e): docs/LEVEL_ART_TECHNICAL_AUDIT.md, tools/audit_level_art.py 10/10 PASS
- [x] SB-M08-008 Determine legal production envelope/context. — 2026-10-22 (factory 030, 6f970e6e): docs/LEVEL_ART_TECHNICAL_AUDIT.md, tools/audit_level_art.py 10/10 PASS
- [x] SB-M08-009 Confirm width in legal engine envelope. — 2026-10-22 (factory 030, 6f970e6e): docs/LEVEL_ART_TECHNICAL_AUDIT.md, tools/audit_level_art.py 10/10 PASS
- [x] SB-M08-010 Confirm height in legal engine envelope. — 2026-10-22 (factory 030, 6f970e6e): docs/LEVEL_ART_TECHNICAL_AUDIT.md, tools/audit_level_art.py 10/10 PASS
- [ ] SB-M08-011 Preserve original.
- [ ] SB-M08-012 Never silently resize.
- [x] SB-M08-013 Explicitly map/reject source colors against locked C01..C16; never invent C17+; record deterministic mapping/rejection evidence. — 2026-10-22 (factory 030, 6f970e6e): docs/LEVEL_ART_TECHNICAL_AUDIT.md, tools/audit_level_art.py 10/10 PASS
- [x] SB-M08-014 Produce audit report. — 2026-10-22 (factory 030, 6f970e6e): docs/LEVEL_ART_TECHNICAL_AUDIT.md, tools/audit_level_art.py 10/10 PASS

### M09 — Pixel Art → Level Data Pipeline `[CONTENT]`

**M09 palette-lock note:** M09's completed exact-source-pixel importer remains valid historical/generic tooling evidence, but production acceptance additionally obeys current canonical palette/art/difficulty systems. Historical completion is not rewritten.

### M12 — Five-Slot Logic

Remaining slot mechanics are `[DESIGN GATE]` except where newer owner decisions explicitly lock behavior.

### M15 — TargetSelector

M15 strict closure remains accepted. V04 later superseded only its target ordering policy while preserving strict safety contracts.

### M17 — Routing Prototype Lab / Production Routing

M17-C002 V03 strict full-surface audit remains accepted as the pre-V07 production-routing baseline. V07 added the adjacent one-cell exterior ring and remains valid historical M21 evidence. The 2026-09-14 owner decision in `OWNER_SCRUBBOT_RAILROAD_DECISION_V01.md` supersedes that exact exterior geometry for future production once M22 V02 passes audit; the M17 safety contracts remain mandatory.

**Historical V07 amendment:** the one-cell exterior ring proved exterior reachability and is preserved as audit history. **Current owner target:** Railroad V1 must preserve route validation, no-retarget, ACTIVE-blocker/CLEARED-open semantics, rectangular support and 59×59 behavior while replacing the exact adjacent-ring movement geometry.

### M19 — Scrubbot Dispatcher

**Strict-v2 final closure:** M19-C001 V06 `AUDITED_PASS / STRICT_V2_FINAL_CLOSURE`.

### M21 — First Real-Art Vertical Slice `[CONTENT] [VISUAL REFERENCE]`

**Strict-v2 final closure:** M21-C001 V10 `AUDITED_PASS / STRICT_V2_FINAL_CLOSURE` (`coordination/sessions/M21-C001/CHATGPT_AUDIT_V10.md`). Owner manual V07 Godot gate PASS remains part of the closure basis. V08–V10 were production-immutable validation passes.

The owner-approved real Hazard Bot source is:
`assets/art/levels/source/easy/scrubbots_m21_level_001_hazard_bot_20x20.png`.

Locked runtime outcomes carried forward:
- visible slot-click-only gameplay activation; no SPACE/hidden keyboard dispatch;
- historical-at-M21-close adjacent one-logical-cell exterior routing ring on all four sides, now superseded as future production geometry by Railroad V1 while its safety evidence remains valid;
- TargetSelector bottom-most then left-most among currently targetable matching cells;
- fresh Hazard Bot C08 first target index `380`, coordinate `(0,19)`;
- real clicked-slot spawn anchor -> routing -> authenticated arrival -> ACTIVE→CLEARED transparency;
- exact ReservationState/dispatcher/agent lifecycle under rapid input and reset;
- full 400-cell real-art clear across all five colors;
- reference composite and generated LevelData/preview/metadata reproducible/unchanged.

**First real-art vertical slice additions**

### M22 — Production Slot UI `[VISUAL REFERENCE]`

**V01 audit:** `AUDITED_PASS / PRODUCTION_SLOT_FOUNDATION_ACCEPTED` (`coordination/sessions/M22-C001/CHATGPT_AUDIT_V01.md`). V01 created the reusable native-Godot production SlotCell/ColorSelectionPanel foundation, corrected the active manifest palette/difficulty contract, validated real reference authority, touch size, responsive/safe-area behavior, active-state lifecycle and real slot-click integration while spending zero Magnific credits.

**Railroad V1 closure — V07 + owner acceptance (2026-09-17):** the accepted production movement contract is now exact clicked-slot anchor → visible BOTTOM connector → canonical Railroad V1 exterior travel → legal rail ingress → four-neighbour orthogonal OPEN/CLEARED interior corridor with one or more 90-degree turns → assigned ACTIVE target. Non-target ACTIVE cells remain blockers; no diagonal/corner-cut/teleport/free-space shortcut and no retargeting are allowed. V07 implementation evidence recorded 4,823 checks / 0 failures and preserved the fresh Hazard Bot C08 first target `380/(0,19)`. Owner manual review confirmed the routing correction. The earlier straight-only final target approach is superseded.

- [ ] SB-M22-008 No-work state if approved. (2026-10-22 factory 032: no owner approval/spec exists; left open, conditional.)
- [x] SB-M22-015 Generate the four owner-locked gameplay booster assets (+1 Slot, Random, Selector, Tornado) when Economy V1 implementation scope opens. Verify-closed 2026-10-22 (factory 032): assets/ui/final/boosters/{extra_slot,random,selector,tornado}.png promoted (VISUAL_ASSET_INDEX.md, ASSET_GENERATION_MANIFEST.json), bound in scripts/ui/gameplay_screen.gd + popup/acquisition_flow.gd, .import mipmaps off, CI run 39828088266 success; owner visual §0D.1. No art modified.
- [ ] SB-M22-016 Generate only milestone-required decorative assets.
- [ ] SB-M22-017 Keep raw candidates separate from production-final assets/provenance.
- [ ] SB-M22-018 Require owner selection/approval before production promotion.
- [ ] SB-M22-019 Never silently regenerate/overwrite approved production art.
- [ ] SB-M22-021 Keep quantities/text/state badges live in Godot.
- [x] SB-M22-022 Implement reusable BoosterButton states for CHARGE_AVAILABLE / PURCHASABLE_SB / SELECTED / UNAVAILABLE / LOCKED when Economy V1 booster scope opens. **[VERIFY-CLOSE 2026-10-22, factory 033: already on main in `scripts/ui/gameplay_screen.gd` (`_make_booster` + `set_booster_states`/`_apply_booster_visual`; states available/purchasable/unavailable/selected/locked, ring+overlay+badge+price children). Local Godot 4.7.2 LOCAL_PASS: m28_c002_c001_gameplay_v02 PASS 14/14, m39c_boosters PASS, m43_c003_c001_acquisition PASS 34/34. Note: LOCKED is implemented (disabled + overlay) but never produced - no unlock authority wired; unlock gating (6/11/16/21 per SB-M44-010) is SB-M44-031 scope, not done here. Component lives inside gameplay_screen, not a standalone class.]**
- [x] SB-M22-023 Bind approved booster/decorative art to reusable components. **[PARTIAL 2026-10-22, factory 033: bound = 4 booster icons + `states/booster_selected_ring` + `states/booster_unavailable_overlay`. NOT bound (no reference in scripts/scenes/data/tests): `booster_free_badge_frame`, `booster_reward_glow`, `booster_activated_burst`, `booster_tutorial_pointer`.]** **[PARTIAL 2026-10-22, factory 035, 5b796999: bound `booster_free_badge_frame` (BadgeFrame under the owned-charge count, visible == Badge), `booster_reward_glow` (RewardGlow 0.5 s fade on an observed charge increase in set_booster_states, not on first population), `booster_activated_burst` (ActivatedBurst 0.5 s fade via play_booster_activated from execute_booster on ok). LOCAL_PASS: m22_023_booster_state_art (new), m22_025_booster_texture_budget, m28_c002_c001_gameplay_v02, m39c_boosters, m39_c003_random_any_booster_rewards, m43_c003_c001_acquisition, m50_color_symbols, m44_ftue, m49_responsive_matrix, m50_accessibility_audit. Remaining: `booster_tutorial_pointer` NOT bound, needs owner/feature (booster-specific coachmark): the FTUE coachmark already binds gameplay/tutorial/tutorial_pointer.png for every step and no booster-only coach hook exists.]** CI: run 39928015709 PASS (2026-10-23, validation_only on e2f674b7, 44 suites incl. M50S 10/10, M46 22/22; covers factory 035/038); item status unchanged. **[DONE 2026-10-23, factory 041: owner decision - no booster-specific coachmark; the shared gameplay/tutorial/tutorial_pointer.png stays; booster_tutorial_pointer.png retired from active runtime requirements, PNG preserved. 3 states bound in job 035.]**
- [x] SB-M22-025 Validate import/transparency/filtering/mobile memory before visual closure. **[FINDINGS 2026-10-22, factory 033, stdlib check: assets/ui/final/boosters 10 PNG all RGBA (alpha OK), all have .import; est RGBA8 texture memory 59.99 MiB (each 1254x1254 = 6.0 MiB; the booster row draws ~touch-size ~100px). All 560 final-art PNGs: compress/mode=0 (lossless, uncompressed on GPU), mipmaps off, est 2947.67 MiB total; 7 PNGs without alpha. Per-node filtering not set to anything but default. NOT closed: needs downscaled/VRAM-compressed (or mipmapped) booster textures and a gameplay-screen mobile memory budget; remaining work = downscale/reimport boosters + decide memory budget.] [BOOSTER SLICE DONE 2026-10-22, factory 034, e37daeb4: all 10 boosters/** .import set process/size_limit=512 (lossless, mipmaps off, source PNGs untouched); est resident RGBA8 59.99 MiB -> 9.43 MiB (-84%); budget 12 MiB in docs/07 UI-ADR-007; tests/m22_025_booster_texture_budget.gd LOCAL_PASS (fails if a limit is reverted); m28_c002_c001, m39c, m43_c003_c001, m50_color_symbols, m46_performance LOCAL_PASS. NOT closed: other final art -> SB-M22-026.]** **[TICKED 2026-10-22: booster scope validated (job 034), remaining art tracked by SB-M22-026 (factory 036).]**
- [ ] SB-M22-026 Budget the remaining ~550 final-art PNGs (est 2.9 GiB resident if all loaded at source size): per-screen memory budgets, size_limit and/or VRAM compression per folder, review the 7 PNGs without alpha. (Split from SB-M22-025, factory 034.) **[STEP 1 2026-10-23, factory 037, d92b2eb5, LOCAL_PASS: tools/m22_026_texture_inventory.py (560 PNGs, 2947.7 MiB at source); size_limit 256 on icon_clock/daily_streak_flame/daily_task_check and 1024 on daily_login_calendar/heart_large (draw side known, 4x rule), library 2897.1 -> 2875.2 MiB (-0.76%, not meaningful); tests/m22_026_texture_budget.gd PASS: Home 207.07/228, Gameplay 50.72/56, Results 65.99/73, Shop/Collection 69.99/77 MiB, fails when a cap is reverted; UI-ADR-008 lists untouched files and the 7 no-alpha PNGs. Still open: 353 unknown-draw + 181 without a literal reference, VRAM compression, atlasing, lazy loading.]** **[STEP 2 2026-10-23, factory 038, 0c2e1be2, LOCAL_PASS: tests/tools/m22_026_texture_measure.gd measures on-screen px of every final-art texture on real main.tscn (throw-away saves, real save byte-identical) for Home (all gesture frames), Gameplay 5/6-slot, Results won/failed, Shop, Collection, Robots, Heart popup at 1080x2400 and 1536x2048 (18 scenarios, 144 textures); tools/m22_026_apply_caps.py sets size_limit=next_pow2(max(2x side,512)) only below source and only where no limit existed: 45 capped (37 at 512, 8 at 1024), min limit/side 2.06, PNGs unchanged, layout re-measured identical. Per-screen resident RGBA8 before -> after: Home 207.07 -> 106.02 (budget 117), Gameplay 62.72 -> 62.72 (budget 69; list +2 runtime 3-col shells, step-1 list 50.72 unchanged), Results 65.99 -> 28.41 (budget 32), Shop/Collection 94.00 -> 36.98 (budget 41; list +4 popup frames/reward glow/parts icon, step-1 list 69.99 -> 20.70); m22_026_texture_budget PASS, FAIL+exit 1 with one cap reverted; m42_home, m28_c002_c001 14/14, m43_c001a 11/11, m49 8/8, m50 10/10, m22_025, m28_c002_c002_r01_visual, m42_home_v07_safe_area, m42_home_composition, m43 shop/collection/robots PASS; UI-ADR-008 step 2. Still open: 416 unobserved PNGs, VRAM compression, atlasing, lazy card art (13 viewed cards = 78 MiB).]** **[STEP 3 2026-10-23, factory 040, ee87dd65 + 4386d4ea, LOCAL_PASS: all 135 collection card arts (1024x1536) import with process/size_limit=1080 (2 x measured 540 px; next_pow2 would be 2048 > source), PNGs unchanged; all 135 resident RGBA8 810.0 -> 400.45 MiB; CollectionScreen static _tex_cache replaced by a per-visit cache owned by the album popup (freed when the album closes, no cross-visit retention), a card leaves the ResourceLoader cache once that cache and its TextureRect are freed; re-measure: card sides unchanged (540 phone / 512 tablet), Collection scenario whole-tree 166.87 -> 127.43 MiB, other scenarios unchanged; m22_026_texture_budget PASS incl. card cap/alpha/440 MiB budget/no-cache checks (FAIL with the static cache restored); m43_master_c007_collection keeps its 150 ms warm set-detail budget via the album cache (warm 77-80 ms, 3 runs) 13/13, m43_c007r_pity 9/9, m22_025, m49 8/8, m50 10/10, m47_touch_r01 14/14 PASS; UI-ADR-008 step 3. Still open: VRAM compression, atlasing.]** **[STEP 4 2026-10-23, factory 043, 5ac6d6a2 + 57e852a5, LOCAL_PASS: tests/tools/m22_026_texture_measure.gd +17 scenarios (Daily/Tasks/ScrubBox/Gift Bar, Rewarded Ads, Profile/Achievements/Events/Comeback/Notifications, Help, Settings, Robots detail x9, every meta ceremony incl. robot unlock x10 and world_01, Standard + Premium pack frames 1-9, Need a Hand, Insufficient, 4 booster popups, Results reward/robot-pose variants, Shop confirm/feedback, every FTUE coachmark; RANKS and opening video recorded as skipped) at 1080x2400 + 1536x2048, throw-away saves, real save sha256 unchanged: DONE (52 scenarios, 219 textures); 75 of the 416 unobserved PNGs now observed (+3 tutorial textures no longer size 0); merged with step 2 by max (all 144 keys kept, >=); apply_caps --write: 45 capped (16 at 512, 29 at 1024: robot masters, help/victory poses, perks, pack icons, unlock burst, tutorial pointer), min limit/side 2.25, dry run after: would cap 0; PNGs unchanged, only size_limit lines (45 newly tracked .import files); library RGBA8 2260.4 -> 2102.9 MiB; new budgets Daily/Tasks 28.20/32, Profile 19.00/21, Ceremonies 306.78 -> 214.91/230, Robots detail 66.01 -> 36.94/41, Popups 16.17/18, Results variants 136.43 -> 75.42/83, Coachmarks 18.00 -> 12.96/15 MiB; Results list 28.41 -> 23.08 (budget 32 kept); re-measure after re-import: sides equal except 1-2 px rounding; m22_026_texture_budget, m22_025, m43_master_c007/c008/c009/c010, m44_unlock_gate, m39d, m43 ceremony/pack/results/shop/need-a-hand suites, m44_ftue, m41_settings, m46_rm003, m49 PASS; UI-ADR-008 step 4 lists the 341 still unobserved by reason. Found and fixed: step 2 caps master_collection_emblem (320 px) and gift_meter_reward_crate (300 px) were under 2x on the Master / 1000-milestone ceremonies; raised 512 -> 1024 (orchestrator decision; Home 109.02/117, Shop/Collection 39.98/41 MiB; budget, meta-ceremony, ceremony-visual, c007, c009, m42_home PASS). Still open: VRAM compression, atlasing.]** CI: run 39928015709 PASS (2026-10-23, validation_only on e2f674b7, 44 suites incl. M50S 10/10, M46 22/22; covers factory 035/038); item status unchanged.

**Railroad V1 additions [OWNER-LOCKED 2026-09-14]**

### M23 — Batch Supply Engine `[OWNER-LOCKED CORE GAMEPLAY]`

Purpose: create the player-facing color/count supply queues that drive the real ScrubBots puzzle. This milestone owns batch data, queue/preview semantics and candidate generation, but does not own five-slot execution, target claims, robot dispatch or solvability proof.

### M24 — Five-Slot Batch Engine `[OWNER-LOCKED CORE GAMEPLAY]`

Purpose: replace the temporary directly-colored slot interaction with the real five EMPTY baseline batch slots. Player chooses a supply batch; the engine chooses the slot automatically.

**Economy V1 amendment:** the accepted M24 implementation remains the five-slot baseline. M39 must add an explicit runtime-capacity extension 5→6 for the +1 Slot booster without falsifying historical M24 audit evidence.

### M25 — Batch Target Claim Engine `[OWNER-LOCKED CORE GAMEPLAY]`

Purpose: arbitrate currently targetable pixels among multiple live batches, especially duplicate colors, while preserving ReservationState and TargetSelector as the existing low-level safety authorities.

### M26 — Auto Dispatch Scheduler `[OWNER-LOCKED CORE GAMEPLAY]`

Purpose: turn an occupied color/count batch into autonomous Scrubbot work. The player selects batches, not individual robots and not individual target pixels.

### M27 — Solvability / Deadlock Engine `[OWNER-LOCKED CORE GAMEPLAY]`

Purpose: prove generated supply is actually playable under the real baseline mechanics and distinguish temporary waiting from a true no-solution state. This milestone is the final gameplay-engine closure gate before production screen/layout work.

**Economy V1 amendment:** accepted M27 evidence proves the five-slot baseline. M39 must extend solver state/fixtures for temporary six-slot capacity and for Random/Selector/Tornado transactions; do not retroactively claim the completed baseline already proves those booster states.

### M28 — Gameplay Screen Layout `[VISUAL REFERENCE]`

**Gameplay Composition V02 owner amendment [2026-09-19]:** `coordination/OWNER_GAMEPLAY_SCREEN_COMPOSITION_V02.md` is now canonical for gameplay layout. Preserve the owner-supplied baseline screen, integrate full Railroad V1 around the board, show five permanent slot-to-bottom-rail connectors, retain the five-slot + Batch Supply panel, place Pause + 2x side by side top-right, remove gameplay Settings/Heart HUD, and omit the ad banner from the current owner playtest/reference mockup. This is a presentation amendment; accepted historical M28/M29 evidence remains historical and later responsive/polish work must converge to V02.

#### M28-C002 - Gameplay Screen V02 Production Convergence [PLANNED / REQUIRED BEFORE FINAL META-UI INTEGRATION]

**M28-C002-C002/R01 static-shell status:** technical PASS and FINAL OWNER VISUAL PASS. Six-master matrix (5/6 slots × 3/4/5 supply columns), 2.4-cell mini Scrubbots, live bubble copy, responsive/touch choices and S1-S6 are owner-accepted. Row 016 is closed. Rows 012-015/018(part)/019/020 remain dependency/final-gate work.

**M28-C002-C003-R01 V02 closure:** independent `AUDITED_PASS` followed by OWNER FINAL REPLAY PASS. Audit: `coordination/sessions/M28-C002-C003-R01/CHATGPT_AUDIT_V02.md`. Owner gate: `coordination/sessions/M28-C002-C003/OWNER_GAMEPLAY_V02_FINAL_GATE_V01.md`. SB-M28-C002-020 is closed.

Purpose: turn the owner-approved Gameplay Composition V02 and gameplay master visual into the actual shipping gameplay screen. Historical M28 closure remains historical; this sprint closes the later V02 delta without falsifying earlier evidence.

#### M28-C002-C004 - Color / Batch Tile Visual Polish [AUDITED_PASS / OWNER FINAL VISUAL RECHECK]

This is intentionally NOT part of the active `M28-C002-C003-R01 V02` remediation. Owner visual authority: `coordination/OWNER_M28_COLOR_BATCH_TILE_VISUAL_V01.md`.

### M29 — Mobile Touch

**Owner-locked speed integration for M29/runtime:** M29 proves the explicit 1x/2x temporal authority and may keep a direct debug/headless toggle seam. That seam is not authorization for free shipping manual 2x. M39 must gate production manual 2x through the paid entitlement service in `coordination/OWNER_ECONOMY_REWARDS_V01.md`. Authoritative M23-exhausted automatic 2x remains free. Do not infer exhaustion from UI rows or slot occupancy.

### M31 — Cleaning Effects `[VISUAL REFERENCE] [PERFORMANCE] [CLOSED 2026-09-20]`

Closure evidence: `coordination/sessions/M31-C001/CHATGPT_AUDIT_V01.md` + `coordination/sessions/M31-C001/OWNER_F6_ACCEPTANCE_V01.md`. Final verdict: `AUDITED_PASS / M31-C001 CLOSED`.

### M32 — Scrubbot Final Visuals `[VISUAL REFERENCE] [CLOSED 2026-09-20]`

Closure evidence: `coordination/sessions/M32-C001/CHATGPT_AUDIT_V03.md` + `coordination/sessions/M32-C001/OWNER_F6_ACCEPTANCE_V01.md`. Final verdict: `AUDITED_PASS / M32-C001 CLOSED`.

### M33 — Audio `[OWNER-LOCKED AUDIO SELECTION V02 2026-09-24]`

**FINAL STATUS: `AUDITED_PASS / OWNER_F6_PASS / M33 AUDIO CLOSED`.**

Owner accepted the integrated Pixel Polish Parade gameplay loop in `res://scenes/debug/m33_audio_playtest.tscn`: no audible loop seam, comfortable music-vs-cleaning balance, cleaning remains readable, Music/SFX/Master isolation is correct, Retry/2x/cleaning do not restart music, and repeated listening is not fatiguing.

Final owner acceptance:
`coordination/OWNER_M33_FINAL_AUDIO_ACCEPTANCE_V01.md`

Owner audio law remains: no dispatch SFX; cleaning uses bounded `dispatch.wav`; completion is WON-only; no movement audio. `ScrubBots Workshop` remains separately owner-approved for a future Workshop screen.

### M34 — Haptics

V02 independent code audit: `CODE_AUDIT_PASS`. SB-M34-001..005 closed. SB-M34-006 remains `DEVICE/OWNER_REQUIRED` for real handset haptic feel.

Pre-authored batch bundle: `coordination/sessions/M34-C001/CHATGPT_PROMPT_V01.md` + `CHATGPT_AUDIT_CRITERIA_V01.md`. Per-task logs required under `task_logs/`. Owner/device gate does not stop the batch.

- [x] SB-M34-006 Real-device test. **[DONE: OWNER_ACCEPTED 2026-10-31T00:44 (factory/answers.md "all is ok"); no device capture was made, the A10 was not reachable by adb afterwards, and the A10 still runs the pre-VIBRATE build until the next save-preserving reinstall; factory 075.]** (factory 072: run 41116404350 APK declared no uses-permission, so Input.vibrate_handheld was dropped on Android; preset now sets permissions/vibrate=true; device ON/OFF capture still to do)

### M35 — Level Catalog

V02 independent audit: `AUDITED_PASS / M35 LEVEL CATALOG CLOSED`. All M35 tasks closed.

Pre-authored batch bundle: `coordination/sessions/M35-C001/CHATGPT_PROMPT_V01.md` + `CHATGPT_AUDIT_CRITERIA_V01.md`. Per-task logs required under `task_logs/`.

### M36 — Difficulty System

V02 independent code audit: `CODE_AUDIT_PASS`. SB-M36-001..006 closed (SB-M36-005 simulated playtest, factory 044; human calibration follow-ups SB-M36-009..011).

Pre-authored batch bundle: `coordination/sessions/M36-C001/CHATGPT_PROMPT_V01.md` + `CHATGPT_AUDIT_CRITERIA_V01.md`. Per-task logs required under `task_logs/`. Human playtest gate does not stop the batch.

**Difficulty V1 owner decision now governs future work.** Board dimensions remain an engine/content envelope and Session Load input, not the definition of EASY/MEDIUM/HARD/VERY_HARD.

- [x] SB-M36-005 Playtest difficulty. **[DONE 2026-10-23, factory 044, b81aa5e3, LOCAL_PASS: tools/difficulty_playtest.gd fresh solver + oracle replay of the 10 catalog levels, all SOLVED, 0 route failures; report docs/DIFFICULTY_PLAYTEST_2026-10.md, JSON coordination/sessions/FACTORY/044-m36-005-difficulty-playtest/playtest_v1.json; m53_first10_difficulty + m36_difficulty_v1 PASS. Simulated only (owner playtest gate given, CLAUDE.md 0D.1). Findings filed as SB-M36-009..011.]**
- [x] SB-M36-009 Difficulty V1 lane calibration proposal: all 10 shipped levels miss the 11.2 lane target outside the hard limit +/-5 except L5 (SOFT, -4.8); EASY slots sit at D 45.0..50.9 vs targets 18..22, L10 VERY_HARD at 51.5 vs 76, so measured D spans only 45.0..54.3 (docs/DIFFICULTY_PLAYTEST_2026-10.md, factory 044). Investigate whether the cause is the Stage-A anchors (data/config/level_difficulty_analysis_v1.json), the V1 component normalizations or the content, and write a proposal (candidate anchor set or new score-model version + re-analysis of the 10 levels per docs/11 section 13). Do not change coefficients, anchors or the model version under v1 (CLAUDE.md 11.3); any change ships only as a new model version; no level data edits here. **[DONE 2026-10-23, factory 045, 3538e9c3: proposal delivered in docs/DIFFICULTY_LANE_CALIBRATION_PROPOSAL_V1.md. Cause is the model, not levels 2..10: V1 U is pure board geometry (U 0.410 on every 32x32), A/B saturate (A 0.61..0.78, B 0.44..0.64 via 3 front columns vs lowChoiceThreshold 2), A/B/S rank-invert vs class; only C tracks the cadence (rho +0.72). Worked recompute: V1-only re-normalization makes order worse (rho vs target -0.15), M53-C002 V2 candidate best owner agreement (rho +0.64). Options A content / B score model v2 / C window; recommends B. Docs only, no config/data/script change; any model-v2 adoption or content change is a separate decision. Owner chose B 2026-10-26 -> SB-M36-012.]**
- [x] SB-M36-010 Difficulty V1 recovery/sequencing proposal for the shipped First 10: recovery guards 3->4 (drop 4.8 < 15), 5->6 (drop 2.3 < 20) and 8->9 (drop -3.4 < 15, inverted) fail on actual D, L10 boss ranks 3rd of 10, and L5->L6->L7 are consecutive levels above the pack median on both D and Session Load (marginal: 0.02 Session Load above median) (docs/DIFFICULTY_PLAYTEST_2026-10.md, factory 044). Propose catalog re-sequencing or replacement candidates that satisfy the guards with measured D; any catalog/level change is a separate owner-visible job. Do not change coefficients, guards or the model version under v1 (CLAUDE.md 11.3). **[DONE 2026-10-26, factory 047, 8b237736: proposal docs/DIFFICULTY_RECOVERY_SEQUENCING_PROPOSAL_V1.md on v2 data (playtest_v2.json). v2 guards: 3->4 drop 13.98 < 15, 5->6 5.80 < 20, 8->9 -8.45 < 15 (inverted on A/B/U/R/S); boss now rank 1, no LONG_HIGH_FRICTION pair under v2. Exhaustive reorder search: exact cadence 1440 orders, max 1/3 guards (analytic cap: 5->6 max drop 7.3). Recommendation C+B: keep shipped order, rescale guards with lanes in SB-M36-013, component recovery checks as SB-M36-014. Owner pre-approved the factory findings 2026-10-26 (chat: "eğer benim verdiğim puanları kural olarak alıyorsa almasın. kendi bulduklarını ben okeyliyorum şimdiden."); owner ratings not used as a criterion. No config/level change.]**
- [x] SB-M36-011 Frustration Risk scalar is unsupported for every shipped level (PROVISIONAL_STAGE_A, scalar null; retryRisk, sessionOverrun and lateFailure = 85% of the V1 weight have no supporting simulation or owner budget; only the choiceOpacity proxy exists) (docs/DIFFICULTY_PLAYTEST_2026-10.md, factory 044). Design the missing inputs: a documented simulated-human policy for retry/late-failure populations and a proposed per-slot Session Load budget (docs/11 sections 7-8) for owner decision. Do not invent a scalar or change the frustrationRisk weights/model version under v1 (CLAUDE.md 11.3). **[DONE 2026-10-26, factory 048, 03506dde: proposal docs/DIFFICULTY_FRUSTRATION_RISK_PROPOSAL_V1.md. Inputs today: choiceOpacity SUPPORTED_PROXY only; retryRisk/sessionOverrun UNSUPPORTED, lateFailure one STRESS run (diagnostic). Recommends C: HUMAN_BR bounded-rational policy (perception mu, softmax tau, slip epsilon, Hick-Hyman latency; 3 PRIOR_UNCALIBRATED profiles x 32 PCG32 seeds) replayed through the real ProofKernel, LOST = proven DEADLOCK; per-slot Session Load budget 22/26/36/40/48 (PROXY), session_overrun = clamp((SL-budget)/budget,0,1); shipped L4/L6/L9 overrun ~0.14. Runtime estimate ~5.6 h single-process for 10 levels (from v2 measureMs 1469.8 s / 7 policies). Owner pre-approved the factory findings 2026-10-26; owner ratings not a criterion. No config/script/level change; implementation filed as SB-M36-015.]**
- [x] SB-M36-012 Difficulty score model v2 adoption (owner decision B 2026-10-26, resumes M53-C003 from the frozen M53-C002 candidate): data/config/difficulty_score_model_v2.json (+ level_difficulty_analysis_v2.json, scripts/difficulty/level_difficulty_analyzer_v2.gd), tools/difficulty_playtest.gd --model v1|v2 (default v2). **[DONE-on-merge 2026-10-26, factory 046, d4a1b328..2394713f, LOCAL_PASS: tests/m36_difficulty_v2.gd 'M36 difficulty V2 evidence: PASS (38/38 cases, 0 fail)', m36_difficulty_v1 PASS, m53_first10_difficulty PASS, m53_c002_difficulty_calibration PASS; fresh run coordination/sessions/FACTORY/046-difficulty-model-v2/playtest_v2.json (10/10 SOLVED, modelVersion 2); doc docs/DIFFICULTY_MODEL_V2_CALIBRATION.md. v2 D = candidate D on all 10 levels; no change beyond the candidate was justified by the diagnosis or corpus; v1, candidate and level_progression_v1.json byte-identical. Honest shortfall: rank correlation equal to candidate, HARD L5 below MEDIUM mean, all three recovery guards fail, L5/L10 outside the hard limit (filed SB-M36-013).]**
- [x] SB-M36-013 Progression v2 lane rescale (Option C2 of docs/DIFFICULTY_LANE_CALIBRATION_PROPOSAL_V1.md): a versioned data/config/level_progression_v2.json placing the lanes on the measured v2 D scale. Owner decision 2026-10-26: the owner pre-approved the factory recommendation (chat: "eğer benim verdiğim puanları kural olarak alıyorsa almasın. kendi bulduklarını ben okeyliyorum şimdiden."); the factory recommends the versioned level_progression_v2.json rescale over keeping 20/40/58/76 as a model limitation, because no v2 level or corpus fixture reaches 58/76 (max 46.7 / 36.5), so lane acceptance would stay diagnostic forever. Also rescale recoveryGuards by the v1 minimum/target-drop ratio (docs/DIFFICULTY_RECOVERY_SEQUENCING_PROPOSAL_V1.md section 5). level_progression_v1.json stays byte-identical. Evidence: docs/DIFFICULTY_MODEL_V2_CALIBRATION.md section 5 (L5 29.4 vs 58, L10 46.7 vs 76). **[DONE 2026-10-26, factory 050 (redone; the job-049 fit to shipped levels was rejected): anchor corpus of 20 lane fixtures + 4 EXTREME probes designed from the component rules (tests/fixtures/difficulty_anchors/, tools/build_difficulty_anchors.gd), decision rule and corpus committed before any measurement (27a66955), measured with the unchanged v2 analyzer (tools/measure_difficulty_anchors.gd, coordination/sessions/FACTORY/050-m36-013-anchor-calibration/anchors_v2.json, 24/24 SOLVED, 05129032). Outcome RESCALE: medians EASY 13.81, MEDIUM 30.90, HARD 43.83, VERY_HARD 49.64 (monotonic; no lane within 5.0 of 20/40/58/76), s 0.640 -> data/config/level_progression_v2.json lanes 13.8+9.0 / 30.9+8.3 / 43.8+8.3 / 49.6+7.7, guards 9.6/12.8/9.6/22.4, tolerance 2.2/1.3/3.2; ceiling probe 59.70 >= VERY_HARD cap 57.3. LOCAL_PASS: tests/m36_anchor_calibration.gd 'M36 anchor calibration: PASS (126 cases, 0 fail)', m36_difficulty_v2 PASS (38/38), m36_difficulty_v1 PASS, m37_level_progression PASS, m53_first10_difficulty PASS. v1 progression and v2 model/analysis configs byte-identical. Doc docs/DIFFICULTY_LANE_ANCHOR_CALIBRATION.md. Finding: DifficultyProgressionV1 rejects the v2 schema, reader filed as SB-M36-016.]**
- [x] SB-M36-014 Recovery component checks on actual v2 vectors (docs/DIFFICULTY_RECOVERY_SEQUENCING_PROPOSAL_V1.md section 6 step 3, owner pre-approved 2026-10-26): per peak->recovery pair report recovery A <= peak A, recovery B <= peak B, not (B and U both >=), and recovery Session Load < peak, next to the scalar guards in tools/difficulty_playtest.gd recovery output; record them as CampaignBuilder recovery-slot constraints in docs/10 section 13. No config/coefficient change. **[DONE 2026-10-26, factory 052, 9d1f9cb2: `recovery.componentChecks` per recoveryGuards pair (aNotAbovePeak, bNotAbovePeak, notAboveOnBothBAndU strict, sessionLoadBelowPeak strict, pass); no anomaly entries, stdout and anomaly counts unchanged (v2 11, v2+progression v2 12, v1 15); committed playtest_v1/v2/v2_progression_v2.json gain only the block. LOCAL_PASS: m36_recovery_component_checks PASS (26 cases), m36_progression_v2_reader, m36_anchor_calibration, m36_difficulty_v2, m36_difficulty_v1, m37_level_progression, m53_first10_difficulty PASS. Shipped L1..L10 informational: v2 model (both progressions) 3->4 pass, 5->6 pass, 8->9 fails A (0.141->0.408), B (0.033->0.152) and B+U; v1 model 5->6 and 8->9 fail A/B. data/config byte-identical; nothing tuned.]**
- [x] SB-M36-015 Frustration Risk inputs build (docs/DIFFICULTY_FRUSTRATION_RISK_PROPOSAL_V1.md section 4, owner pre-approved 2026-10-26): new data/config/frustration_analysis_v1.json (HUMAN_BR profiles/seeds/runs, per-slot Session Load budget, overrun rule) and scripts/difficulty/frustration_analyzer_v1.gd reusing the v2 run_policy/decision state; tools/difficulty_playtest.gd --frustration/--runs (opt-in); report retryRisk, lateFailure, sessionOverrun, choiceOpacity and F (weights read from difficulty_score_model_v2.json) as PROVISIONAL_SIMULATED_HUMAN plus near-miss/dead-placement/no-target-wait/Hearts-per-clear/attempt-seconds diagnostics; tests/m36_frustration_v1.gd per section 5; full 10-level run with wall time. Existing score/analysis/progression configs byte-identical; no gameplay change; offline only, no per-player use (CLAUDE.md 11.5). **[DONE 2026-10-26, factory 053, 66d8e163: data/config/frustration_analysis_v1.json (schema scrubbots-frustration-analysis/v1; NOVICE/CASUAL/SKILLED priors of proposal 4.2, runsPerProfile 32, seed formula, thresholds 0.70 strict / 0.90, decisionBound 2000, Hearts 5, 6 cells/s, slot budget 26/26/36/22/40/22/26/36/22/48 PROXY); scripts/difficulty/frustration_analyzer_v1.gd (HUMAN_BR through LevelDifficultyAnalyzerV2.run_policy via a new default-off optional chooser Callable; clearRate + Wilson 95%, retryRisk, lateFailure + LOST count, nearMiss, dead placements, no-target waits, Hearts/attempts per clear, pOutOfHearts, attemptSecondsProxy, sessionOverrun, choiceOpacity, F with v2 weights 0.35/0.30/0.20/0.15, null naming the missing input; sorted-key JSON); tools/difficulty_playtest.gd --frustration [--runs N] (needs --model v2, writes frustration_v1.json/.md beside playtest_v2.json; without the flag unchanged by code inspection). LOCAL_PASS: tests/m36_frustration_v1.gd 'M36_FRUSTRATION_V1 PASS (62 cases, 0 fail)' in 365 s (corpus compact_hard_20/flow_stripes3_20/bottleneck_low_24/bottleneck_high_24 + L1, 2 runs/profile); degenerate HUMAN_BR == ACCESS on L1 + 3 fixtures; m36_recovery_component_checks, m36_progression_v2_reader, m36_anchor_calibration, m36_difficulty_v2, m36_difficulty_v1, m37_level_progression, m53_first10_difficulty, m53_c002_difficulty_calibration PASS; six score/analysis/progression configs byte-identical to main. Findings (reported, not tuned): no corpus fixture lost an attempt, so both declared discrimination pairs hold only as ties (retryRisk 0 = 0); L1 at 2 runs/profile cleared NOVICE 0/2, CASUAL 1/2, SKILLED 0/2 (monotonicity miss). A HUMAN_BR attempt costs ~5-11 s on 20x20/24x24; the optional full 10-level --frustration run was not done.]**
- [x] SB-M36-017 Frustration discrimination follow-up (factory 053 findings: corpus pairs tie at retryRisk 0, L1 monotonicity miss at 2 runs, full 10-level run not done; --frustration --runs 1 executed by reviewer-tests: exit 0, F 0.15..44.7 over L1..L10). Measure HUMAN_BR on harder anchor fixtures and L1 at 32 runs/profile; record ordering and discrimination as findings; do not tune profiles; keep playtest_v2.json unchanged unless intentionally regenerated. L1..L10 informational only. **[DONE 2026-10-30, factory 067, 30a0171e: opt-in tools/difficulty_playtest.gd -- --frustration --fixtures id[,id...] [--runs N] (anchor fixtures slot by lane, catalog ids slot by order; Session Load/choiceOpacity from v2.score() of the sha-bound committed raw; writes coordination/sessions/FACTORY/067-m36-017-frustration-discrimination/frustration_<id>_r<N>.json; no playtest_v2.json/frustration_v1 write). 32 runs/profile on hard_maze8_24, hard_rings10h_26, hard_rings8h_24, hard_rings9q_split_24, hard_tiles9_split_24, vh_maze10_24, vh_rings10h_r1_split_24, vh_rings11h_straddle_24, vh_rings12h_split_24, vh_rings12q_split_26 and L1 (11 parallel processes, 41 min wall; anchor runs 26-41 min each under contention, runs not reduced). Findings (docs/DIFFICULTY_FRUSTRATION_DISCRIMINATION_FINDINGS_V1.md, not tuned): every anchor cleared 32/32 for NOVICE/CASUAL/SKILLED, so N<=C<=S holds only as ties and all 45 anchor retryRisk pairs tie at 0 (anchor F = 15 x choiceOpacity, 0.3..3.4); only non-tied pairs are L1 0.912 vs each anchor; L1 3/32, 3/32, 2/32 (CASUAL>SKILLED miss, inside Wilson overlap, losses supply-driven). Next step proposed: deadlock-capable supplies and a versioned skill-sensitive input. Profiles PRIOR_UNCALIBRATED; configs and committed playtest outputs byte-unchanged. LOCAL_PASS: tests/m36_frustration_fixtures.gd 'M36_FRUSTRATION_FIXTURES PASS (11 cases, 0 fail)', tests/m36_frustration_v1.gd 'M36_FRUSTRATION_V1 PASS (62 cases, 0 fail)'.]**
- [x] SB-M36-016 Progression v2 reader (finding of SB-M36-013, docs/DIFFICULTY_LANE_ANCHOR_CALIBRATION.md section 5): DifficultyProgressionV1 checks schema scrubbots-level-progression/v1, so data/config/level_progression_v2.json is not loadable by any tool. Add a versioned reader (or schema-version support without changing v1 behaviour) and route LevelDifficultyAnalyzerV2 target lookup and tools/difficulty_playtest.gd recovery guards to v2; level_progression_v1.json and its reader output byte-identical. **[DONE 2026-10-26, factory 051, c1f4eb55: DifficultyProgressionV1 accepts schema v1+v2 (V2_CONFIG_PATH, V2_SCHEMA, model_version(), challenge_tolerance()); LevelDifficultyAnalyzerV2(config, progression_path); tools/difficulty_playtest.gd --progression v1|v2 (v2 needs --model v2, writes coordination/sessions/FACTORY/046-difficulty-model-v2/playtest_v2_progression_v2.json: guards 9.6/12.8/9.6, tolerance 2.2/1.3/3.2 also applied to acceptanceWindow via LevelDifficultyAnalyzerV1.classify_window(delta, tol), anomalies=12, L1..L10 informational only); defaults stay v1, default --model v1/v2 outputs equal before/after except solver wall-clock ms; LOCAL_PASS tests/m36_progression_v2_reader.gd 'M36 progression v2 reader: PASS (55 cases, 0 fail)', m36_anchor_calibration PASS (126), m36_difficulty_v2 PASS (38/38), m36_difficulty_v1 PASS, m37_level_progression PASS, m53_first10_difficulty PASS.]**

### M37 — Level Progression

V03 independent audit: `AUDITED_PASS / M37 LEVEL PROGRESSION CLOSED`. Forward-only progression and contiguous persisted history accepted; owner decision remains no shipping Level Select, debug seam only.

V03 remediation authority: `coordination/sessions/M37-C001/CHATGPT_PROMPT_V03.md` + `CHATGPT_AUDIT_CRITERIA_V03.md`. Frozen F-M37-V02-001..002. Owner lock remains: forward-only progression, no shipping Level Select; debug seam only.

V02 remediation authority: `coordination/sessions/M37-C001/CHATGPT_PROMPT_V02.md` + `CHATGPT_AUDIT_CRITERIA_V02.md`. Owner decision is locked in `coordination/OWNER_M37_LEVEL_SELECT_DECISION_V01.md`: no shipping Level Select in V1; forward-only progression, debug/test seam only. Per-task V02 logs required under `task_logs_v02/`.

### M38 — Win Streak `[OWNER-LOCKED ECONOMY V1]`

V03 independent final audit: `AUDITED_PASS / M38 WIN STREAK CLOSED / STRICT EVIDENCE REPAIRED`. SB-M38-016 is reclosed. The reward-failure strict case now runs through a true RewardGrantService subclass, and the suite fails if any named sub-test aborts.

Prior V02 final closure is temporarily suspended by `coordination/sessions/M38-C001/CHATGPT_FULL_SURFACE_REAUDIT_V02.md`: the reward-failure strict sub-test aborted on a typed fake yet the suite printed PASS. Only SB-M38-016 is reopened. V03 prompt/criteria repair evidence only; production changes are forbidden unless the repaired test exposes a real defect.

V02 strict independent audit: `AUDITED_PASS / M38 WIN STREAK CLOSED`. All M38 tasks closed.

Pre-authored batch bundle: `coordination/sessions/M38-C001/CHATGPT_PROMPT_V01.md` + `CHATGPT_AUDIT_CRITERIA_V01.md`. Per-task logs required under `task_logs/`. Durable central persistence is finalized by M40.

### M39 — Economy & Rewards V1 `[OWNER-LOCKED]`

V04 final independent audit: `AUDITED_PASS / M39 ECONOMY CODE CLOSED / SB-M39-033 DEVICE_OWNER_REQUIRED`. The repaired M38 strict regression closes SB-M39-052. All M39 code tasks are audited; only real-phone sixth-slot safe-area/touch/readability evidence remains.

V04 independent audit: `CODE_AUDIT_PASS / REGRESSION_GATE_OPEN / DEVICE_OWNER_GATE_OPEN`. F-M39-V03-001..005 are source/direct-test accepted. SB-M39-052 waits for repaired M38 strict regression; SB-M39-033 remains real-device safe-area/touch/readability.

V04 remediation authority: `coordination/sessions/M39-C001/CHATGPT_PROMPT_V04.md` + `CHATGPT_AUDIT_CRITERIA_V04.md`. Frozen F-M39-V03-001..005. Remaining code work is targeted Tornado cancellation, production local-day wiring, exact +1 rollback, atomic first-clear transaction and canonical action seams. SB-M39-033 also retains the later device safe-area/touch gate.

V03 remediation authority: `coordination/sessions/M39-C001/CHATGPT_PROMPT_V03.md` + `CHATGPT_AUDIT_CRITERIA_V03.md`. Frozen F-M39-V02-001..016. Proven unrelated M39 tasks are closed individually; SB-M39-033 also retains a later real-device safe-area/touch gate after code remediation.

Pre-authored batch bundle: `coordination/sessions/M39-C001/CHATGPT_PROMPT_V01.md` + `CHATGPT_AUDIT_CRITERIA_V01.md`. All 55 task IDs require separate GitHub task logs; M39 remains subject to later strict full-surface ChatGPT audit.

Canonical decision: `coordination/OWNER_ECONOMY_REWARDS_V01.md`.
Machine tuning: `data/config/economy_rewards_v1.json`.

- [x] SB-M39-033 Add sixth-slot presentation/layout support and mobile safe-area evidence; no 7+ slot state. verify-close 2026-10-22 (factory 026), LOCAL_PASS + factory peer review: m39_v02_capacity PASS (cannot grow past 6, never 7+), m28_c002_c002_static_shell PASS 16-of-16, m49_responsive_matrix PASS 8-of-8 (m05_sixth_slot_matrix, m07 synthetic NOTCH), m50_color_symbols PASS 10-of-10; MAX := 6, no 7+ state. CLAUDE.md §0D.1 grants the real-phone sign-off; safe-area coverage is the synthetic-inset matrix, no real-phone capture claimed.

### M40 — Save System

V04 final independent audit: `AUDITED_PASS / M40 SAVE SYSTEM CLOSED`. The repaired M38 strict regression and rerun of M40 V04 bootstrap/root suite close the final external gate.

V04 independent audit: `CODE_AUDIT_PASS / M38 STRICT REGRESSION REQUIRED`. All M40 task rows are code/evidence-proven; final milestone `AUDITED_PASS` waits for M38 V03 repaired strict regression plus rerun of M40 V04 bootstrap/root suite.

V04 remediation authority: `coordination/sessions/M40-C001/CHATGPT_PROMPT_V04.md` + `CHATGPT_AUDIT_CRITERIA_V04.md`. Frozen F-M40-V03-001..004. Remaining work is actual app bootstrap, frontier-to-catalog content resolution, app-owned durable action/save boundaries and local-day end-to-end persistence.

V03 remediation authority: `coordination/sessions/M40-C001/CHATGPT_PROMPT_V03.md` + `CHATGPT_AUDIT_CRITERIA_V03.md`. Frozen F-M40-V02-001..009. SB-M40-004/006/007 are independently accepted; remaining rows await V03/dependency closure.

Pre-authored batch bundle: `coordination/sessions/M40-C001/CHATGPT_PROMPT_V01.md` + `CHATGPT_AUDIT_CRITERIA_V01.md`. All 13 task IDs require separate GitHub task logs; M40 is the batch endpoint and remains subject to later strict full-surface ChatGPT audit.

### M41 — Settings `[CLOSED 2026-09-25]`

Final status: **`AUDITED_PASS / OWNER_F6_PASS / M41 SETTINGS CLOSED`**.

M41-C001 closed Master/Music/SFX/Haptics/Persistence/UI/Relaunch with independent code audit plus owner 9/9 manual acceptance.

M41-C002 closed the final row, `SB-M41-005 Reduced Effects`, with independent code audit plus owner 5/5 manual acceptance. The setting is canonical/persistent, strict-validated, live-bound to the accepted M31 reduced cleaning presentation, gameplay-invariant and owner-accepted.

Evidence:
- `coordination/sessions/M41-C001/CHATGPT_AUDIT_V01.md`
- `coordination/OWNER_M41_SETTINGS_ACCEPTANCE_V01.md`
- `coordination/sessions/M41-C002/CHATGPT_AUDIT_V01.md`
- `coordination/OWNER_M41_C002_REDUCED_EFFECTS_ACCEPTANCE_V01.md`

### M42 — Home / Navigation

M42-C001 V01 independent batch audit:
`coordination/sessions/M42-C001/CHATGPT_BATCH_AUDIT_V01.md`

Batch result: **25 AUDITED_PASS / 8 CODE_AUDIT_PASS WITH EXTERNAL GATES / 0 CHANGES_REQUIRED**.

Individual audit files:
`coordination/sessions/M42-C001/audits/SB-M42-001_CHATGPT_AUDIT_V01.md` .. `SB-M42-033_CHATGPT_AUDIT_V01.md`.

Post-audit owner decision closed SB-M42-030 as mandatory NO SKIP. The Home then went through owner-approved asset promotion, V02 master convergence and V03 visual/modal remediation. After V03 runtime review, the owner changed the Home architecture again: World 01 will use one complete baked 1080x2160 world background while Scrubby remains a separate runtime hero, and Home shortcuts are reduced to four. Current closure state is **31 closed / 2 open rows**. Final Home V07 visuals are owner-accepted; only 032/033 external device gates remain.

Opening policy: `coordination/OWNER_M42_OPENING_CINEMATIC_POLICY_DECISION_V02.md`
SB-M42-030 audit closure: `coordination/sessions/M42-C001/audits/SB-M42-030_CHATGPT_AUDIT_V02.md`.
Home art complete approval: `coordination/OWNER_M42_HOME_ART_COMPLETE_APPROVAL_V01.md`
Home art promotion audit: `coordination/sessions/M42-C001/audits/SB-M42-HOME-ART-PROMOTION_CHATGPT_AUDIT_V01.md`.
Home master convergence V02 audit: `coordination/sessions/M42-C001/audits/SB-M42-HOME-MASTER-CONVERGENCE_V02_CHATGPT_AUDIT_V01.md`.
Home owner visual revision V03: `coordination/OWNER_M42_HOME_VISUAL_REVISION_V03.md`
V03 implementation prompt: `coordination/sessions/M42-C001/task_prompts/SB-M42-HOME-OWNER-REVISION_V03.md`.
V03 independent audit: `coordination/sessions/M42-C001/audits/SB-M42-HOME-OWNER-REVISION_V03_CHATGPT_AUDIT_V01.md`.
Home rebuild V04 owner decision: `coordination/OWNER_M42_HOME_REBUILD_V04_SINGLE_WORLD_BACKGROUND.md`
V04 implementation prompt: `coordination/sessions/M42-C001/task_prompts/SB-M42-HOME-REBUILD_V04.md`.

**Owner runtime validation [2026-09-27 / OWNER_RUNTIME_PASS / VISUAL_POLISH_OPEN]:**
`coordination/OWNER_ECONOMY_PROGRESSION_RUNTIME_VALIDATION_V01.md`.
During the First 10 owner replay, 2x purchase + correct SB debit, live Scrub Bucks balance, Gift Meter, Bot Parts/next-robot progress and Home progression bars were manually confirmed to update correctly. Treat these mechanics/data bindings as working runtime truth; later tasks remain responsible for improving their visual quality and reward/presentation polish without rewriting the validated backend unnecessarily.

**Opening cinematic / boot flow [OWNER ASSET — 2026-09-19]**

- [ ] SB-M42-032 Validate opening cinematic on Android real device for smooth 720p/30 playback, audio sync, startup latency, orientation, background/foreground behavior and memory cleanup. `[CODE_AUDIT_PASS / DEVICE_OWNER_REQUIRED]`
- [x] SB-M42-033 Validate iOS readiness later with the same boot-flow fallback and aspect rules. `[CODE_AUDIT_PASS / STATIC_READINESS_DONE 2026-10-31: docs/OPENING_CINEMATIC_DEVICE_VALIDATION.md "iOS readiness" updated; IPA pack scan + headless boot in ios-ipa.yml runs 41114924279, 41080595559, 41070827156; physical iPhone cinematic playback not verified; factory 073]`

### M43 - Results / Player Experience / Meta UI Surface Program [PLANNED / REQUIRED]

**Owner completeness rule:** every player-facing button, HUD `+`, Home shortcut, bottom-navigation destination, gameplay purchase/acquisition action, fail/win state, reward event and feature unlock must terminate in a real implemented screen/popup or an explicitly disabled state. No shipping dead buttons, placeholder pages, invisible economic transactions or "coming later" holes are allowed for V1-required surfaces.

**Canonical visual references already selected:**
- Life popup: `assets/art/references/_owner_inbox/Additionals/life screens.png`
- Need a Hand popup: `assets/art/references/_owner_inbox/Additionals/need a hand.png`
- Level intro popup: `assets/art/references/_owner_inbox/Game Screens/level ekran acilisi.png`
- Gameplay master: `assets/ui/final/gameplay/master/scrubbots_gameplay_master.png`
- Home master/World 01 authority remains M42 V07 + owner decisions.

**Visual production rule for every surface below:** create/identify a visual master or canonical reference, inventory required illustration assets, generate only the needed component art, obtain owner visual approval, build the production screen in responsive Godot UI with live text/data, run independent audit, then run owner playtest/visual acceptance. A screen is not complete merely because a service exists.

#### M43-C001 - Results Screen

**C001B status: FINAL OWNER PASS.** Technical audit PASS at `4d198e9`; owner visual acceptance recorded in `coordination/sessions/M43-C001B/FINAL_OWNER_VISUAL_ACCEPTANCE_V01.md`. `victory_results` is `MASTER_OWNER_APPROVED`. Only SB-M43-013 remains open because downstream ceremonies belong to M43-C005.

- [x] SB-M43-013 If the win unlocks a robot, collection set, Master Collection, feature or world, hand off to the corresponding ceremony in M43-C005 after the core Results reward commit succeeds. **[DONE verify-close 2026-10-27, factory 059, code 46e50fd1 (main.gd RESULTS_CEREMONY_BARRIER, CeremonyPresenter.drain("results")), no production change; world has no event (gated); LOCAL_PASS tests/m43_master_c005_meta_ceremonies.gd "M43 master C005 meta ceremonies evidence: PASS (32/32 cases, 0 fail)" (e27 Results hand-off, e28 no event no hold) + all 52 CI validate suites PASS locally via tools/run_suites.py aggregate=PASS (52/52) on 4077ce5b; suite added to the CI validate list with an exact-summary guard (4077ce5b).**]

#### M43-C001R - Results Momentum / Next-Level Curiosity / 10-Level Cleaning Journey [OWNER APPROVED 2026-09-30]

These tasks extend the already owner-approved Results surface without changing its reward authority. The goal is a strong "one more level" continuation loop built from truthful next-content information, not fake scarcity, near-miss messaging or hidden reward manipulation.

#### M43-C005 - Reward, Pack, Collection, Robot, Feature and World Ceremonies

- [x] SB-M43-068 Implement Collection set 9/9 completion ceremony with the exact per-set SB/Bot Part reward. **[DONE verify-close 2026-10-26, factory 057, no code change; LOCAL_PASS tests/m43_master_c005_meta_ceremonies.gd "M43 master C005 meta ceremonies evidence: PASS (32/32 cases, 0 fail)": e03-e08 (set 9/9 truth, reward rows == config row == SB granted, ack once / reload, Reduced same truth)]**
- [x] SB-M43-069 Implement Master Collection completion ceremony for +2500 SB +20 Bot Parts exactly once. **[DONE verify-close 2026-10-26, factory 057, no code change; LOCAL_PASS tests/m43_master_c005_meta_ceremonies.gd "M43 master C005 meta ceremonies evidence: PASS (32/32 cases, 0 fail)": e11-e14 (Master +2500 SB +20 Bot Parts, exactly once, after set events, legacy baseline, Reduced)]**
- [x] SB-M43-070 Implement Robot Unlock ceremony with canonical robot art, name, personality/perk summary and remaining Bot Parts carryover. **[DONE verify-close 2026-10-26, factory 057, no code change; LOCAL_PASS tests/m43_master_c005_meta_ceremonies.gd "M43 master C005 meta ceremonies evidence: PASS (32/32 cases, 0 fail)": e15-e16, e19-e22 (canonical RobotRoster art / name / role / perk, Bot Parts left, unknown robot never shown, Reduced)]**
- [x] SB-M43-071 Robot unlock ceremony allows selecting/equipping the unlocked robot or continuing with the current robot. **[DONE verify-close 2026-10-26, factory 057, no code change; LOCAL_PASS tests/m43_master_c005_meta_ceremonies.gd "M43 master C005 meta ceremonies evidence: PASS (32/32 cases, 0 fail)": e17 EQUIP persists via ProductionActionFacade.equip_robot, e18 KEEP CURRENT changes nothing]**
- [x] SB-M43-072 Implement feature-unlock ceremony/coachmark used when a new meta system becomes available through M44 feature-unlock pacing. **[DONE 2026-10-26, factory 057, 0aa42895; LOCAL_PASS tests/m43_c005_c072_feature_unlock_ceremony.gd "M43 C005 feature unlock ceremony evidence: PASS (9/9 cases, 0 fail)" + all 48 CI validate suites PASS locally (m44_ftue 23/23, m44_contextual_coach 7/7, m44_new_badge 6/6, m44_unlock_gate 6/6, m46_performance 22/22, ...) and m43_master_c005_meta_ceremonies 32/32, c008_robots 10/10, c011_c014 28/28, c005f_phase3 15/15, phase4_qa_r01 4/4: CeremonyPresenter.feature_events() derives one "NEW FEATURE!" ceremony (MetaCeremonies.feature_unlock, key unlock:<id>, UiText FEATURE_<ID>_NAME/BODY) per owner-table feature with level > 1 once AppState.feature_unlocked(id), NEW FTUE profiles only, ascending level after gift/set/Master/robot, via the existing Results barrier / Home drain; save failure on ack rolls back + snoozes for the session. Presentable: daily, shop, tasks, collection (existing shortcut icons). Skipped, follow-up art needed: card_packs, robots, events, achievements, ranks, plus_one_slot/random/selector/tornado (boosters with SB-M44-031 part 2). m44_ftue t23 / m44_contextual_coach _play adjusted for the new L4 Daily ceremony. Docs docs/16 1.4a.]**
- [ ] SB-M43-073 Implement World unlock/transition ceremony once world-range rules are owner-defined; never invent ranges in UI.
- [x] SB-M43-074 Implement Gift Meter milestone celebration for 10/50/250/500/1000 with exact queued reward truth. **[DONE verify-close 2026-10-26, factory 058, no production code change; LOCAL_PASS tests/m43_c005_c074_c077_celebrations.gd "M43 C005 gift/daily/tasks celebrations evidence: PASS (6/6 cases, 0 fail)" + all 49 CI validate suites PASS locally via tools/run_suites.py; existing m43_master_c005_meta_ceremonies e23-e28 / c009_daily t05 / c005f_phase3 d01-d04 unchanged: c01 FULL==Reduced labels and rows == config bundle for all five milestones, c02 presenting under Reduced grants nothing / exactly once]**
- [x] SB-M43-075 Implement Daily cycle reward celebration and 3/3 Tasks booster-completion celebration. **[DONE verify-close 2026-10-26, factory 058, no production code change (DailyScreens.open_daily_reward / open_scrubbox already shipped as claim popups); LOCAL_PASS tests/m43_c005_c074_c077_celebrations.gd "M43 C005 gift/daily/tasks celebrations evidence: PASS (6/6 cases, 0 fail)" + all 49 CI validate suites PASS locally via tools/run_suites.py; existing m43_master_c005_meta_ceremonies e23-e28 / c009_daily t05 / c005f_phase3 d01-d04 unchanged: c03 D1..D5 popup == config login_rewards == granted, Day 5 cycle-done copy, opening grants nothing; c04 ScrubBox == config all_tasks charges, once, none on failed claim]**
- [x] SB-M43-077 Meta reward ceremonies respect Reduced Effects and can collapse to concise accessible presentation without changing grants. **[DONE verify-close 2026-10-26, factory 058, no production code change; LOCAL_PASS tests/m43_c005_c074_c077_celebrations.gd "M43 C005 gift/daily/tasks celebrations evidence: PASS (6/6 cases, 0 fail)" + all 49 CI validate suites PASS locally via tools/run_suites.py; existing m43_master_c005_meta_ceremonies e23-e28 / c009_daily t05 / c005f_phase3 d01-d04 unchanged: c05 Daily/ScrubBox identical labels and grants FULL vs Reduced, no motion nodes; c06 no stacking, no seen-key from Daily/ScrubBox. Note: SB-M43-076 does not exist in TASKS.md (numbering skips 076), left untouched]**

##### M43-C005R - Gift Meter Micro-Progress Feedback [OWNER APPROVED 2026-09-30]

- [x] SB-M43-R05-001 Add purely presentational micro-progress/tick feedback between canonical Gift Meter milestones 10/50/250/500/1000 so long gaps visibly advance; micro-ticks mint no reward, create no new economic threshold and cannot be claimed. **[DONE verify-close 2026-10-27, factory 059, code 671615be (gift_progress_model.gd, gift_tick_overlay.gd), no production change; LOCAL_PASS tests/m43_master_c005r_gift_micro_progress.gd "M43 master C005R gift micro-progress evidence: PASS (8/8 cases, 0 fail)" + all 52 CI validate suites PASS locally via tools/run_suites.py aggregate=PASS (52/52) on 4077ce5b; suite added to the CI validate list with an exact-summary guard (4077ce5b).**]
- [x] SB-M43-R05-002 Use one GiftMeterService-derived normalized progress model across Home/Results/Gift Bar; milestone crossing keeps the existing authoritative reward bundle and celebration while intermediate animation remains skippable/Reduced-Effects-safe. **[DONE verify-close 2026-10-27, factory 059, code 671615be (one GiftProgressModel consumed by home_screen / results_screen / daily_screens), no production change; LOCAL_PASS tests/m43_master_c005r_gift_micro_progress.gd "M43 master C005R gift micro-progress evidence: PASS (8/8 cases, 0 fail)" + all 52 CI validate suites PASS locally via tools/run_suites.py aggregate=PASS (52/52) on 4077ce5b; suite added to the CI validate list with an exact-summary guard (4077ce5b).**]

##### M43-C005F - Game Feel Presentation Layer — GameFeelFlow + Saltmire Spark [PLANNED; DOES NOT INTERRUP CURRENT C005 ASSET/OWNER GATES]

**Audited API lock [M43-C005F-PHASE1 PASS/CLOSED 2026-10-08]:** canonical Git now vendors **GameFeelFlow 1.0.0** and **Saltmire Spark 1.0.0**, both MIT, with one ScrubBots-owned `scripts/ui/feel/feedback_adapter.gd` production boundary. Actual GFF 1.0.0 exposes `play()`, `play_combo()`, `stop()/stop_all()`, `get_effect_names()` and `get_combo_names()`, but **does not register `spring_scale`, `squash_stretch` or `elastic`**. Its scale target operates on Node2D/Node3D, **not Control UI nodes**. The installed `ui_button_press` / `ui_notification` combos contain flash and sit outside the targeted cancelable effect stack, so they are **DO NOT USE for V1**. Spark exposes `burst()`, `at()` and global `clear()`; global `Spark.clear()` is forbidden because the canonical adapter owns/freezes only its own emitters. Canonical reachable surface is GFF `punch_scale` on compatible Node2D/Node3D targets plus Spark `spark`/`pickup`/`confetti`, always through the adapter. **This audited lock supersedes any older F003-F012 row wording that asks for unsupported GFF scale effects, GFF UI combos, GFF Control-node punches, or global Spark clearing. Control-based UI must retain native Godot tween/static presentation and may add only adapter-owned Spark where the specific future row permits it.** Audit: `coordination/sessions/M43-C005F-PHASE1/CHATGPT_INDEPENDENT_AUDIT_V01.md`.

Effect-intensity vocabulary for this program: **MICRO → SMALL → REWARD → MAJOR_REWARD → WIN → MAJOR_UNLOCK**. It is a presentation budget/hierarchy only, never gameplay/economy importance truth. Initial FULL-mode particle ceilings are deliberately conservative and must be profiled before owner acceptance: MICRO 0 Spark particles; SMALL 0–4; REWARD 4–8; MAJOR_REWARD 8–14; WIN 12–18; MAJOR_UNLOCK 16–24. Reduced Effects uses static/native truth first, removes screen/camera effects entirely, disables looping motion, and either removes Spark or caps it to a tiny nonessential burst only where accessibility review approves.

- [x] **SB-M43-C005F-007 — Robot / feature / world unlock feel, with MAJOR_UNLOCK ceiling.** Purpose: give genuinely major unlocks stronger but coherent presentation. **Seam:** M43-C005 Robot Unlock, feature-unlock coachmark and world-transition ceremony surfaces built on BasePopup/ModalStack; World remains gated by owner-defined ranges. **Plugin:** GameFeelFlow spring/punch on hero/emblem and one non-strobing element flash; Spark capped confetti/sparkle at MAJOR_UNLOCK. **Native/existing remains:** `RobotUnlockService`, equip/keep-current choice, M44 feature-unlock authority, NavigationController/world registry/transition logic, approved robot/world art. **Reduced Effects:** static hero/emblem + readable unlock copy; no confetti/flash/loop/spin. **Idempotency:** keyed to authoritative unlock id; refresh/equip choice/world navigation cannot retrigger the unlock ceremony. **Mobile/perf:** one major-unlock particle group at a time, short lifetime, no camera manipulation. **Automated:** unlock/equip/world truth unchanged and effect duplicates refused. **Godot AI:** Robot FULL/REDUCED mandatory; feature/world once those surfaces exist. **Regression/gate:** M43-070..073 and M54-027/030/032; independent audit + owner visual gate. **[DONE robot + feature 2026-10-27, factory 059, a292c390: MetaRewardFeel maps CeremonyPresenter robot_unlock / feature_unlock -> FeedbackAdapter MAJOR_UNLOCK on the ceremony HeroArt, key c005f007:<ceremony key> (robot:<id> / unlock:<id>), FULL = adapter confetti 24 + native settle peak 1.12 / 0.5 s, REDUCED = zero plugin work; no flash element added (adapter has none), no camera; World part gated, not implemented (world_unlock has no intent). LOCAL_PASS tests/m43_c005f_phase6_unlock_feel.gd "M43 C005F phase6 unlock feel evidence: PASS (8/8 cases, 0 fail)" + m43_master_c005f_feel 10/10 + m43_c005f_phase3 15/15 + all 52 CI validate suites PASS locally via tools/run_suites.py aggregate=PASS (52/52) on 4077ce5b; suite added to the CI validate list with an exact-summary guard (4077ce5b).**] Review: CLAUDE_PEER_REVIEW PASS (factory 059 round 1: rules + code/tests) in factory 059; no independent audit / owner visual claimed.
- [ ] **SB-M43-C005F-015 — End-to-end feel validation + owner visual gate.** Purpose: close the plugin program only after runtime evidence proves coherent hierarchy, safety and restraint. **Seam:** representative real shipping paths: WON Results, reward rows, Standard/Premium pack, set/master completion, Robot Unlock, Gift milestone, acquisition confirmation, gameplay completion, Home state change and cleaning comparison. **Plugin:** both through the single adapter only. **Native/existing remains:** all authoritative/native presentation systems listed above. **Reduced Effects:** every representative path captured in FULL + REDUCED; plugin-disabled fallback also exercised. **Idempotency:** repeated Results model refresh, popup reopen, resize, background/foreground and duplicate callbacks produce no extra one-shot celebration. **Mobile/perf:** use approved budgets and no orphan emitters/tweens after scene change. **Automated:** focused suite + root regression + call-count/fault-injection checks. **Godot AI:** mandatory real-runtime visual validation at 1080×1920, 1080×2160, 1290×2796 and 1536×2048 where applicable, plus gameplay at production load; inspect actual frames, not metadata-only. **Regression/gate:** independent ChatGPT audit and owner final visual acceptance required before any plugin feel work is marked complete.

#### M43-C006 - Shop / Store / Currency Destination

- [x] SB-M43-078 Implement a real Shop destination opened by the Home SHOP shortcut and Scrub Bucks `+`. DONE factory 060 verify-close: LOCAL_PASS m43_master_c006_shop 15/15 (4 assertion cases added), added to CI validate (53 suites, exact 15/15 guard); built in 79544a75 from existing assets + native Controls (visual master given by CLAUDE.md 0D.1, no new art). CLAUDE_PEER_REVIEW PASS (factory 060 round 1: rules + tests).
- [x] SB-M43-079 Produce/owner-approve a Shop visual master before final production binding. DONE factory 060 verify-close: LOCAL_PASS m43_master_c006_shop 15/15 (4 assertion cases added), added to CI validate (53 suites, exact 15/15 guard); built in 79544a75 from existing assets + native Controls (visual master given by CLAUDE.md 0D.1, no new art). CLAUDE_PEER_REVIEW PASS (factory 060 round 1: rules + tests).
- [x] SB-M43-080 Shop V1 surface groups Hearts, boosters, 2x products and later real-money/SB acquisition without inventing a second premium currency. DONE factory 060 verify-close: LOCAL_PASS m43_master_c006_shop 15/15 (4 assertion cases added), added to CI validate (53 suites, exact 15/15 guard); built in 79544a75 from existing assets + native Controls (visual master given by CLAUDE.md 0D.1, no new art). CLAUDE_PEER_REVIEW PASS (factory 060 round 1: rules + tests).
- [ ] SB-M43-081 No Ads entry belongs to Shop, not Home, and remains gated by M57 product definition.
- [x] SB-M43-082 Shop shows live wallet/Heart/booster/entitlement state and never displays baked prices or stale quantities. DONE factory 060 verify-close: LOCAL_PASS m43_master_c006_shop 15/15 (4 assertion cases added), added to CI validate (53 suites, exact 15/15 guard); built in 79544a75 from existing assets + native Controls (visual master given by CLAUDE.md 0D.1, no new art). CLAUDE_PEER_REVIEW PASS (factory 060 round 1: rules + tests).
- [x] SB-M43-083 Soft-currency purchases route through existing authoritative services; UI never mutates balances directly. DONE factory 060 verify-close: LOCAL_PASS m43_master_c006_shop 15/15 (4 assertion cases added), added to CI validate (53 suites, exact 15/15 guard); built in 79544a75 from existing assets + native Controls (visual master given by CLAUDE.md 0D.1, no new art). CLAUDE_PEER_REVIEW PASS (factory 060 round 1: rules + tests).
- [ ] SB-M43-084 Real-money product cards, localized cash prices, restore purchases and receipt state are bound only after M57 authorizes products/provider.
- [x] SB-M43-085 Implement purchase confirmation where platform policy/product risk requires it and clear pending state on failure/cancel. DONE factory 060 verify-close: LOCAL_PASS m43_master_c006_shop 15/15 (4 assertion cases added), added to CI validate (53 suites, exact 15/15 guard); built in 79544a75 from existing assets + native Controls (visual master given by CLAUDE.md 0D.1, no new art). CLAUDE_PEER_REVIEW PASS (factory 060 round 1: rules + tests).
- [x] SB-M43-086 Preserve exact return context when Shop was opened because a player lacked SB for a booster/Heart/2x action. DONE factory 060 verify-close: LOCAL_PASS m43_master_c006_shop 15/15 (4 assertion cases added), added to CI validate (53 suites, exact 15/15 guard); built in 79544a75 from existing assets + native Controls (visual master given by CLAUDE.md 0D.1, no new art). CLAUDE_PEER_REVIEW PASS (factory 060 round 1: rules + tests).
- [x] SB-M43-087 Implement sold/unavailable/offline/loading/error states without dead buttons. DONE factory 060 verify-close: LOCAL_PASS m43_master_c006_shop 15/15 (4 assertion cases added), added to CI validate (53 suites, exact 15/15 guard); built in 79544a75 from existing assets + native Controls (visual master given by CLAUDE.md 0D.1, no new art). CLAUDE_PEER_REVIEW PASS (factory 060 round 1: rules + tests).
- [x] SB-M43-088 Test rapid taps, insufficient SB, provider cancel/failure, restore, background/resume and idempotent fulfillment. DONE factory 060 verify-close: LOCAL_PASS m43_master_c006_shop 15/15 (4 assertion cases added), added to CI validate (53 suites, exact 15/15 guard); built in 79544a75 from existing assets + native Controls (visual master given by CLAUDE.md 0D.1, no new art). Provider cancel/failure/restore sub-items moved to SB-M43-084 (no provider until M57). CLAUDE_PEER_REVIEW PASS (factory 060 round 1: rules + tests).
- [x] SB-M43-089 Shop visual/audio feedback must not imitate guaranteed rewards for uncompleted purchases. DONE factory 060 verify-close: LOCAL_PASS m43_master_c006_shop 15/15 (4 assertion cases added), added to CI validate (53 suites, exact 15/15 guard); built in 79544a75 from existing assets + native Controls (visual master given by CLAUDE.md 0D.1, no new art). CLAUDE_PEER_REVIEW PASS (factory 060 round 1: rules + tests).

#### M43-C007 - Collection / Cards Exchange Destination

- [x] SB-M43-090 Implement Collection main screen for all 15 canonical sets x 9 cards = 135 cards. DONE factory 061 verify-close. LOCAL_PASS m43_master_c007_collection 17/17 (k14..k17 added) + m54_collection_set_master_exactly_once PASS, both added to CI validate (55 suites, exact guards, 74b85bab). CLAUDE_PEER_REVIEW PASS (factory 061 round 1: rules + code/tests).
- [x] SB-M43-091 Produce/owner-approve Collection album visual master using existing canonical card art. DONE factory 061 verify-close: existing promoted assets under assets/ui/final/collection/ + canonical card art, no new art, CLAUDE.md 0D.1 owner visual sign-off given. LOCAL_PASS m43_master_c007_collection 17/17 (k14..k17 added) + m54_collection_set_master_exactly_once PASS, both added to CI validate (55 suites, exact guards, 74b85bab). CLAUDE_PEER_REVIEW PASS (factory 061 round 1: rules + code/tests).
- [x] SB-M43-092 Show set progress N/9, completed state and exact set-completion reward without hiding rarity burden. DONE factory 061 verify-close (k02, k15). LOCAL_PASS m43_master_c007_collection 17/17 (k14..k17 added) + m54_collection_set_master_exactly_once PASS, both added to CI validate (55 suites, exact guards, 74b85bab). CLAUDE_PEER_REVIEW PASS (factory 061 round 1: rules + code/tests).
- [x] SB-M43-093 Implement set detail page with 9 card slots, rarity, owned/new/duplicate state and protected first-copy semantics. DONE factory 061 verify-close (k03, k09). LOCAL_PASS m43_master_c007_collection 17/17 (k14..k17 added) + m54_collection_set_master_exactly_once PASS, both added to CI validate (55 suites, exact guards, 74b85bab). CLAUDE_PEER_REVIEW PASS (factory 061 round 1: rules + code/tests).
- [x] SB-M43-094 Implement card detail popup with full art, name/rarity, owned count and exchangeable extra count. DONE factory 061 verify-close (k04). LOCAL_PASS m43_master_c007_collection 17/17 (k14..k17 added) + m54_collection_set_master_exactly_once PASS, both added to CI validate (55 suites, exact guards, 74b85bab). CLAUDE_PEER_REVIEW PASS (factory 061 round 1: rules + code/tests).
- [x] SB-M43-095 Cards Exchange is a Collection-owned flow, not a Home shortcut. DONE factory 061 verify-close (k12). LOCAL_PASS m43_master_c007_collection 17/17 (k14..k17 added) + m54_collection_set_master_exactly_once PASS, both added to CI validate (55 suites, exact guards, 74b85bab). CLAUDE_PEER_REVIEW PASS (factory 061 round 1: rules + code/tests).
- [x] SB-M43-096 Implement per-card duplicate exchange and EXCHANGE ALL EXTRAS with atomic confirmation and protected-copy floor of 1. DONE factory 061 verify-close (k04, k05, k07, k17). LOCAL_PASS m43_master_c007_collection 17/17 (k14..k17 added) + m54_collection_set_master_exactly_once PASS, both added to CI validate (55 suites, exact guards, 74b85bab). CLAUDE_PEER_REVIEW PASS (factory 061 round 1: rules + code/tests).
- [x] SB-M43-097 Show live exchange SB values Common 25 / Rare 75 / Epic 200 / Legendary 500. DONE factory 061 verify-close (k08). LOCAL_PASS m43_master_c007_collection 17/17 (k14..k17 added) + m54_collection_set_master_exactly_once PASS, both added to CI validate (55 suites, exact guards, 74b85bab). CLAUDE_PEER_REVIEW PASS (factory 061 round 1: rules + code/tests).
- [x] SB-M43-098 Add Standard/Premium pack inventory/open entry and route opening to M43-C005. DONE factory 061 built in abb42509: Collection-owned pack row shows live economy.pending_packs Standard/Premium counts, OPEN PACKS (blocked when empty) calls Main.request_earned_packs -> M43-C005 ceremony; UI never draws/grants/touches the queue (k14). LOCAL_PASS m43_master_c007_collection 17/17 (k14..k17 added) + m54_collection_set_master_exactly_once PASS, both added to CI validate (55 suites, exact guards, 74b85bab). CLAUDE_PEER_REVIEW PASS (factory 061 round 1: rules + code/tests).
- [x] SB-M43-099 Completed-set and Master Collection reward history/status must be visible enough to prevent confusion without enabling duplicate grants. DONE factory 061 verify-close: set rows + Master row show CLAIMED / on completion, reopen grants nothing (k02, k15). LOCAL_PASS m43_master_c007_collection 17/17 (k14..k17 added) + m54_collection_set_master_exactly_once PASS, both added to CI validate (55 suites, exact guards, 74b85bab). CLAUDE_PEER_REVIEW PASS (factory 061 round 1: rules + code/tests).
- [x] SB-M43-100 Collection supports locked/future set presentation without leaking nonexistent cards or fake progress. DONE factory 061 verify-close: no locked/future set content exists; screen renders exactly the 15 canonical sets with no placeholder rows or fake progress (k16). LOCAL_PASS m43_master_c007_collection 17/17 (k14..k17 added) + m54_collection_set_master_exactly_once PASS, both added to CI validate (55 suites, exact guards, 74b85bab). CLAUDE_PEER_REVIEW PASS (factory 061 round 1: rules + code/tests).
- [x] SB-M43-101 Validate 135-card performance, scrolling, touch targets, localization, duplicate-heavy inventories and completion transitions. DONE factory 061 verify-close: 135-card perf/scroll/touch (k10, warm set detail 89-97 ms isolated vs 150 ms budget), duplicate-heavy (k10, k17), completion transitions (k15), all strings via UiText.t. LOCAL_PASS m43_master_c007_collection 17/17 (k14..k17 added) + m54_collection_set_master_exactly_once PASS, both added to CI validate (55 suites, exact guards, 74b85bab). CLAUDE_PEER_REVIEW PASS (factory 061 round 1: rules + code/tests).
- [x] SB-COL-NAV-001 Owner 2026-10-30: album set rows show a red badge with the count of owned not-yet-viewed cards in that set (hidden at 0, re-read live); set detail has < / > arrows (88 px) that switch set in place in config order, wrapping 15->1 / 1->15, with tiles, card:<id> DETAILS actions and viewed marks for the shown set. DONE factory 068 (658906a1). LOCAL_PASS m43_master_c007_collection 19/19 (k18 badge, k19 pager; CI guard 19/19) + m47_touch_r01_mobile_ux 14/14, m22_026_texture_budget, m44_pending_packs_gate 6/6, m43_master_c005_meta_ceremonies 32/32, m42_home, m44_new_badge 6/6, m51_localization_readiness 4/4, m54_collection_set_master_exactly_once, m43_c005_c008_pack_commit_transaction 27/27, m42_navigation, m50_board_symbols 8/8 PASS.

#### M43-C007R - Collection Fairness / Pity / First Collection Sprint [OWNER APPROVED 2026-09-30]

- [x] SB-M43-R07-001 Add a versioned **earned-pack pity counter**: consecutive eligible Standard/Premium pack openings with no new card increment the counter; obtaining any new card resets it (First Collection Sprint exception, R07-006: while Set 1 is incomplete only a new Set 1 card resets it). Threshold is data-driven and must be balance-simulated before final tuning. **[DONE 2026-10-30, factory 069 (3068dc55 sim+doc, e9f0eeed tuning): shipped `collection.pity` threshold 3 + first_sprint_threshold 1, balance-simulated with tools/sim_pack_pity.gd (real EconomyServices, 200 seeds; docs/COLLECTION_PITY_FIRST_SPRINT_TUNING_V1.md). LOCAL_PASS tests/m43_master_c007r_pity.gd 'M43 master C007R pity evidence: PASS (11/11 cases, 0 fail)' (added to CI validate, 60 suites, exact guard) + m43_master_c007_collection 19/19, m44_pending_packs_gate 6/6, m43_c005_c008_pack_commit_transaction 27/27, m43_master_c005_meta_ceremonies 32/32, m54_collection_set_master_exactly_once PASS. Counter/reset p01, persisted p02, shipped threshold p06.]**
- [x] SB-M43-R07-002 When pity reaches its configured threshold, the next eligible earned pack guarantees at least one currently eligible missing card while still preserving Premium's Rare-or-better guarantee; pack contents commit atomically before reveal. **[DONE 2026-10-30, factory 069 (3068dc55 sim+doc, e9f0eeed tuning): shipped `collection.pity` threshold 3 + first_sprint_threshold 1, balance-simulated with tools/sim_pack_pity.gd (real EconomyServices, 200 seeds; docs/COLLECTION_PITY_FIRST_SPRINT_TUNING_V1.md). LOCAL_PASS tests/m43_master_c007r_pity.gd 'M43 master C007R pity evidence: PASS (11/11 cases, 0 fail)' (added to CI validate, 60 suites, exact guard) + m43_master_c007_collection 19/19, m44_pending_packs_gate 6/6, m43_c005_c008_pack_commit_transaction 27/27, m43_master_c005_meta_ceremonies 32/32, m54_collection_set_master_exactly_once PASS. Guarantee p03/p06/p10, Premium card 0 kept p04, atomic commit/rollback p07.]**
- [x] SB-M43-R07-003 If no eligible missing card exists, pity cannot fabricate a card; show the collection-complete state and use only an explicitly configured fallback. Pity state persists through save/cloud migration and cannot be reset by app restart. **[DONE 2026-10-30, factory 069 (3068dc55 sim+doc, e9f0eeed tuning): shipped `collection.pity` threshold 3 + first_sprint_threshold 1, balance-simulated with tools/sim_pack_pity.gd (real EconomyServices, 200 seeds; docs/COLLECTION_PITY_FIRST_SPRINT_TUNING_V1.md). LOCAL_PASS tests/m43_master_c007r_pity.gd 'M43 master C007R pity evidence: PASS (11/11 cases, 0 fail)' (added to CI validate, 60 suites, exact guard) + m43_master_c007_collection 19/19, m44_pending_packs_gate 6/6, m43_c005_c008_pack_commit_transaction 27/27, m43_master_c005_meta_ceremonies 32/32, m54_collection_set_master_exactly_once PASS. No fabrication p05; persistence/strict import p02.]**
- [x] SB-M43-R07-004 Pity applies only to **earned** card packs under the current V1 policy. It cannot be purchased, rerolled for money/SB, accelerated by watching ads or converted into a paid-random mechanic; M57's no-paid-random-pack rule remains intact. **[DONE 2026-10-30, factory 069 (3068dc55 sim+doc, e9f0eeed tuning): shipped `collection.pity` threshold 3 + first_sprint_threshold 1, balance-simulated with tools/sim_pack_pity.gd (real EconomyServices, 200 seeds; docs/COLLECTION_PITY_FIRST_SPRINT_TUNING_V1.md). LOCAL_PASS tests/m43_master_c007r_pity.gd 'M43 master C007R pity evidence: PASS (11/11 cases, 0 fail)' (added to CI validate, 60 suites, exact guard) + m43_master_c007_collection 19/19, m44_pending_packs_gate 6/6, m43_c005_c008_pack_commit_transaction 27/27, m43_master_c005_meta_ceremonies 32/32, m54_collection_set_master_exactly_once PASS. Earned-only static p08; no shop/ad/facade path reaches pity.]**
- [x] SB-M43-R07-005 Make pity legible rather than covert: when one pack away from guarantee, Collection/pack UI may state **NEW CARD GUARANTEED NEXT PACK**; never use near-miss animation or misleading "almost won" presentation. **[DONE 2026-10-30, factory 069 (3068dc55 sim+doc, e9f0eeed tuning): shipped `collection.pity` threshold 3 + first_sprint_threshold 1, balance-simulated with tools/sim_pack_pity.gd (real EconomyServices, 200 seeds; docs/COLLECTION_PITY_FIRST_SPRINT_TUNING_V1.md). LOCAL_PASS tests/m43_master_c007r_pity.gd 'M43 master C007R pity evidence: PASS (11/11 cases, 0 fail)' (added to CI validate, 60 suites, exact guard) + m43_master_c007_collection 19/19, m44_pending_packs_gate 6/6, m43_c005_c008_pack_commit_transaction 27/27, m43_master_c005_meta_ceremonies 32/32, m54_collection_set_master_exactly_once PASS. NEW CARD GUARANTEED NEXT PACK reads the sprint-aware due state, p11.]**
- [x] SB-M43-R07-006 Tune a **First Collection Sprint** so an ordinarily engaged fresh player can realistically complete Set 1 during the early campaign, target window roughly Levels 20–40, using earned progression/Daily/Gift pack sources rather than purchases; exact source placement remains data-driven and must not alter robot-unlock pacing. **[DONE 2026-10-30, factory 069 (3068dc55 sim+doc, e9f0eeed tuning): shipped `collection.pity` threshold 3 + first_sprint_threshold 1, balance-simulated with tools/sim_pack_pity.gd (real EconomyServices, 200 seeds; docs/COLLECTION_PITY_FIRST_SPRINT_TUNING_V1.md). LOCAL_PASS tests/m43_master_c007r_pity.gd 'M43 master C007R pity evidence: PASS (11/11 cases, 0 fail)' (added to CI validate, 60 suites, exact guard) + m43_master_c007_collection 19/19, m44_pending_packs_gate 6/6, m43_c005_c008_pack_commit_transaction 27/27, m43_master_c005_meta_ceremonies 32/32, m54_collection_set_master_exactly_once PASS. Set 1 completion p50 L38 (p10 L31, p90 L51; 57% by L40) at 4 levels/day + 15% losses, L37 at 3/day, L41 at 5/day (was p50 L93 without the sprint); sprint rules asserted in p10; no pack source, reward table, Bot Part or unlock value changed.]**

#### M43-C008 - Robots Destination

- [x] SB-M43-102 Implement ROBOTS bottom-nav destination for the canonical 10-robot roster. **[DONE 2026-10-30, factory 063 verify-close: already built (scripts/ui/robots/robots_screen.gd, scripts/progression/robot_roster.gd); LOCAL_PASS tests/m43_master_c008_robots.gd 'M43 master C008 Robots evidence: PASS (10/10 cases, 0 fail)'; suite added to CI validate list with exact guard.]**
- [x] SB-M43-103 Produce/owner-approve Robots screen visual master using the existing robot asset family. **[DONE 2026-10-30, factory 063 verify-close: already built (scripts/ui/robots/robots_screen.gd, scripts/progression/robot_roster.gd); LOCAL_PASS tests/m43_master_c008_robots.gd 'M43 master C008 Robots evidence: PASS (10/10 cases, 0 fail)'; suite added to CI validate list with exact guard. Visual master closed on CLAUDE.md 0D.1 owner visual sign-off + existing promoted robot assets; no new art.]**
- [x] SB-M43-104 Show unlocked/locked state, canonical order, Bot Parts N/250 toward next unlock and overflow. **[DONE 2026-10-30, factory 063 verify-close: already built (scripts/ui/robots/robots_screen.gd, scripts/progression/robot_roster.gd); LOCAL_PASS tests/m43_master_c008_robots.gd 'M43 master C008 Robots evidence: PASS (10/10 cases, 0 fail)'; suite added to CI validate list with exact guard.]**
- [x] SB-M43-105 Show each robot's canonical 20% meta perk clearly without implying puzzle-solvability power. **[DONE 2026-10-30, factory 063 verify-close: already built (scripts/ui/robots/robots_screen.gd, scripts/progression/robot_roster.gd); LOCAL_PASS tests/m43_master_c008_robots.gd 'M43 master C008 Robots evidence: PASS (10/10 cases, 0 fail)'; suite added to CI validate list with exact guard.]**
- [x] SB-M43-106 Allow selecting/equipping any unlocked robot and persist active robot. **[DONE 2026-10-30, factory 063 verify-close: already built (scripts/ui/robots/robots_screen.gd, scripts/progression/robot_roster.gd); LOCAL_PASS tests/m43_master_c008_robots.gd 'M43 master C008 Robots evidence: PASS (10/10 cases, 0 fail)'; suite added to CI validate list with exact guard.]**
- [x] SB-M43-107 Locked robot detail shows required Bot Parts and preview/perk; Bot Parts cannot be bought with SB or real money in V1. **[DONE 2026-10-30, factory 063 verify-close: already built (scripts/ui/robots/robots_screen.gd, scripts/progression/robot_roster.gd); LOCAL_PASS tests/m43_master_c008_robots.gd 'M43 master C008 Robots evidence: PASS (10/10 cases, 0 fail)'; suite added to CI validate list with exact guard.]**
- [x] SB-M43-108 Active robot selection updates Home/gameplay/profile/support/victory presentation using the approved per-robot asset family. **[DONE 2026-10-30, factory 063 verify-close: already built (scripts/ui/robots/robots_screen.gd, scripts/progression/robot_roster.gd); LOCAL_PASS tests/m43_master_c008_robots.gd 'M43 master C008 Robots evidence: PASS (10/10 cases, 0 fail)'; suite added to CI validate list with exact guard.]**
- [x] SB-M43-109 Robot selection must never mutate BoardState, TargetSelector, routing, solver or batch legality. **[DONE 2026-10-30, factory 063 verify-close: already built (scripts/ui/robots/robots_screen.gd, scripts/progression/robot_roster.gd); LOCAL_PASS tests/m43_master_c008_robots.gd 'M43 master C008 Robots evidence: PASS (10/10 cases, 0 fail)'; suite added to CI validate list with exact guard.]**
- [x] SB-M43-110 Implement robot unlock history/NEW badge clearing without repeated ceremonies. **[DONE 2026-10-30, factory 063 verify-close: already built (scripts/ui/robots/robots_screen.gd, scripts/progression/robot_roster.gd); LOCAL_PASS tests/m43_master_c008_robots.gd 'M43 master C008 Robots evidence: PASS (10/10 cases, 0 fail)'; suite added to CI validate list with exact guard.]**
- [x] SB-M43-111 Validate all 10 robots at mobile scale and fall back safely if a presentation asset is missing rather than corrupting gameplay. **[DONE 2026-10-30, factory 063 verify-close: already built (scripts/ui/robots/robots_screen.gd, scripts/progression/robot_roster.gd); LOCAL_PASS tests/m43_master_c008_robots.gd 'M43 master C008 Robots evidence: PASS (10/10 cases, 0 fail)'; suite added to CI validate list with exact guard.]**

#### M43-C009 - Tasks / Daily / Gift Bar Destinations

- [x] SB-M43-112 Implement TASKS Home destination showing exactly three daily tasks, progress and individual 75/100/125 SB rewards. **[DONE 2026-10-30, factory 064 verify-close: already built; LOCAL_PASS tests/m43_master_c009_daily.gd 'M43 master C009 Tasks / Daily / Gift evidence: PASS (12/12 cases, 0 fail)' (suite already in CI validate; exact-summary guard added); CI run 41036304214 success, M43-C009 verdict=PASS (12/12); CLAUDE_PEER_REVIEW PASS (factory 064 round 1 rules).]**
- [x] SB-M43-113 Produce/owner-approve Tasks visual master. **[DONE 2026-10-30, factory 064 verify-close: already built; LOCAL_PASS tests/m43_master_c009_daily.gd 'M43 master C009 Tasks / Daily / Gift evidence: PASS (12/12 cases, 0 fail)' (suite already in CI validate; exact-summary guard added); CI run 41036304214 success, M43-C009 verdict=PASS (12/12); CLAUDE_PEER_REVIEW PASS (factory 064 round 1 rules). Visual master closed on CLAUDE.md 0D.1 owner visual sign-off + existing promoted assets; no new art.]**
- [x] SB-M43-114 Claim state is exactly-once and 3/3 completion grants one random Booster Charge exactly once. **[DONE 2026-10-30, factory 064 verify-close: already built; LOCAL_PASS tests/m43_master_c009_daily.gd 'M43 master C009 Tasks / Daily / Gift evidence: PASS (12/12 cases, 0 fail)' (suite already in CI validate; exact-summary guard added); CI run 41036304214 success, M43-C009 verdict=PASS (12/12); CLAUDE_PEER_REVIEW PASS (factory 064 round 1 rules).]**
- [x] SB-M43-115 Implement final DAILY destination/popup with visible consecutive-login count and repeating 5-day reward cycle. **[DONE 2026-10-30, factory 064 verify-close: already built; LOCAL_PASS tests/m43_master_c009_daily.gd 'M43 master C009 Tasks / Daily / Gift evidence: PASS (12/12 cases, 0 fail)' (suite already in CI validate; exact-summary guard added); CI run 41036304214 success, M43-C009 verdict=PASS (12/12); CLAUDE_PEER_REVIEW PASS (factory 064 round 1 rules).]**
- [x] SB-M43-116 Produce/owner-approve final Daily visual master and reward-state variants. **[DONE 2026-10-30, factory 064 verify-close: already built; LOCAL_PASS tests/m43_master_c009_daily.gd 'M43 master C009 Tasks / Daily / Gift evidence: PASS (12/12 cases, 0 fail)' (suite already in CI validate; exact-summary guard added); CI run 41036304214 success, M43-C009 verdict=PASS (12/12); CLAUDE_PEER_REVIEW PASS (factory 064 round 1 rules). Visual master closed on CLAUDE.md 0D.1 owner visual sign-off + existing promoted assets; no new art.]**
- [x] SB-M43-117 Daily shows claimed/today/future-day states, current consecutive days and canonical D1-D5 rewards. **[DONE 2026-10-30, factory 064 verify-close: already built; LOCAL_PASS tests/m43_master_c009_daily.gd 'M43 master C009 Tasks / Daily / Gift evidence: PASS (12/12 cases, 0 fail)' (suite already in CI validate; exact-summary guard added); CI run 41036304214 success, M43-C009 verdict=PASS (12/12); CLAUDE_PEER_REVIEW PASS (factory 064 round 1 rules).]**
- [x] SB-M43-118 Implement Gift Bar claim/history surface for queued Gift Meter milestones. **[DONE 2026-10-30, factory 064 verify-close: already built; LOCAL_PASS tests/m43_master_c009_daily.gd 'M43 master C009 Tasks / Daily / Gift evidence: PASS (12/12 cases, 0 fail)' (suite already in CI validate; exact-summary guard added); CI run 41036304214 success, M43-C009 verdict=PASS (12/12); CLAUDE_PEER_REVIEW PASS (factory 064 round 1 rules).]**
- [x] SB-M43-119 Produce/owner-approve Gift Bar visual master and milestone reward cards. **[DONE 2026-10-30, factory 064 verify-close: already built; LOCAL_PASS tests/m43_master_c009_daily.gd 'M43 master C009 Tasks / Daily / Gift evidence: PASS (12/12 cases, 0 fail)' (suite already in CI validate; exact-summary guard added); CI run 41036304214 success, M43-C009 verdict=PASS (12/12); CLAUDE_PEER_REVIEW PASS (factory 064 round 1 rules). Visual master closed on CLAUDE.md 0D.1 owner visual sign-off + existing promoted assets; no new art.]**
- [x] SB-M43-120 Gift Bar claim/history never feeds Gift Meter recursively and never re-grants claimed milestones. **[DONE 2026-10-30, factory 064 verify-close: already built; LOCAL_PASS tests/m43_master_c009_daily.gd 'M43 master C009 Tasks / Daily / Gift evidence: PASS (12/12 cases, 0 fail)' (suite already in CI validate; exact-summary guard added); CI run 41036304214 success, M43-C009 verdict=PASS (12/12); CLAUDE_PEER_REVIEW PASS (factory 064 round 1 rules).]**
- [x] SB-M43-121 Test local-day rollover, missed-day reset, clock rollback, all-3 Tasks completion, Gift rollover and duplicate taps. **[DONE 2026-10-30, factory 064 verify-close: already built; LOCAL_PASS tests/m43_master_c009_daily.gd 'M43 master C009 Tasks / Daily / Gift evidence: PASS (12/12 cases, 0 fail)' (suite already in CI validate; exact-summary guard added); CI run 41036304214 success, M43-C009 verdict=PASS (12/12); CLAUDE_PEER_REVIEW PASS (factory 064 round 1 rules).]**

#### M43-C009R - Daily Scrub Orders / Earned ScrubBox [OWNER APPROVED 2026-09-30]

This extension **does not change** the canonical consecutive-login reset rule or repeating 5-day Daily reward cycle.

- [x] SB-M43-R09-001 Replace generic task content with a data-driven **Daily Scrub Orders** archetype pool while keeping **exactly three active tasks/day** and the existing 75/100/125 SB reward tiers. **[DONE 2026-10-30, factory 065 verify-close: LOCAL_PASS tests/m43_master_c009_daily.gd 'M43 master C009 Tasks / Daily / Gift evidence: PASS (12/12 cases, 0 fail)' cases t01, t10 (factory 065 code ab035410, suites in CI validate with exact guards); review: factory 065 peer review.]**
- [x] SB-M43-R09-002 Eligible task archetypes should advance through ordinary play: complete progression levels, clear bounded amounts/colors, win a qualifying difficulty, complete a level without a booster, or other already-unlocked normal actions; never require real-money spend, ad viewing or an unavailable feature. **[DONE 2026-10-30, factory 065 verify-close: LOCAL_PASS tests/m43_master_c009_daily.gd 'M43 master C009 Tasks / Daily / Gift evidence: PASS (12/12 cases, 0 fail)' cases t03, t11 (factory 065 code ab035410, suites in CI validate with exact guards); review: factory 065 peer review.]**
- [x] SB-M43-R09-003 Daily generation uses the local-day authority plus deterministic/versioned eligibility rules so tasks cannot silently reroll on relaunch; exclude impossible tasks based on current frontier, unlocked systems and available production content. **[DONE 2026-10-30, factory 065 verify-close: LOCAL_PASS tests/m43_master_c009_daily.gd 'M43 master C009 Tasks / Daily / Gift evidence: PASS (12/12 cases, 0 fail)' cases t02, t09 (factory 065 code ab035410, suites in CI validate with exact guards); review: factory 065 peer review.]**
- [x] SB-M43-R09-004 Keep one easy / one normal / one stretch intent aligned with 75/100/125 SB while bounding grind; a task must be finishable in a normal play session and must not encourage intentionally losing or wasting Hearts. **[DONE 2026-10-30, factory 065 verify-close: LOCAL_PASS tests/m43_master_c009_daily.gd 'M43 master C009 Tasks / Daily / Gift evidence: PASS (12/12 cases, 0 fail)' cases t03 (LOST terminal counts nothing), t11 (grind bound: max 3 wins) (factory 065 code ab035410, suites in CI validate with exact guards); review: factory 065 peer review.]**
- [x] SB-M43-R09-005 Present the existing all-3 completion reward through an **earned ScrubBox** ceremony. Phase A reward floor remains the canonical one random Booster Charge exactly once; the box is never sold and has no paid reroll/open-speed mechanic. **[DONE 2026-10-30, factory 065 verify-close: LOCAL_PASS tests/m43_master_c009_daily.gd 'M43 master C009 Tasks / Daily / Gift evidence: PASS (12/12 cases, 0 fail)' cases t05, t11 (factory 065 code ab035410, suites in CI validate with exact guards); review: factory 065 peer review.]**
- [ ] SB-M43-R09-006 A future small surprise bonus slot (bounded SB/card-pack/approved existing reward types only) may be enabled from versioned tuning **only after M56 economy/retention simulation and owner approval**; no jackpot/near-miss presentation and no new currency. **[OWNER DECISION 2026-10-22, owner via factory dashboard: yes, the earned ScrubBox gets a small surprise bonus slot, enabled after the M56 economy simulation.]**

#### M43-C010 - Bottom Navigation / Profile / Achievements / Events / Ranks

- [x] SB-M43-122 BottomNav destinations are real: EVENTS / ROBOTS / HOME / RANKS / SETTINGS. No shipping dead tab. **[DONE 2026-10-31, factory 074 (code 7f208789): owner decision in chat 2026-10-31 "Kisisel rutbe" -> RANKS opens the personal rank ladder (data/config/personal_ranks_v1.json, metric campaign levels cleared, derived on read; no server, other players or rewards; L40 unlock kept). LOCAL_PASS tests/m43_personal_ranks.gd 'M43 personal ranks evidence: PASS (8/8 cases, 0 fail)' (added to CI validate with exact guard, 62 suites), m43_master_c010_meta 12/12 (m01 RANKS live, m11 personal ladder only), m44_unlock_gate 6/6, m42_home_v04 18/18, m42_navigation PASS. SB-M58-012 is not triggered (no social exposure); it stays for any future real leaderboard. Review: factory 074 peer review.]**
- [x] SB-M43-123 Preserve M41 Settings as the canonical Settings destination and do not duplicate Settings behavior. **[DONE 2026-10-30, factory 065 verify-close: LOCAL_PASS tests/m43_master_c010_meta.gd 'M43 master C010 meta evidence: PASS (12/12 cases, 0 fail)' cases m02 (factory 065 code ab035410, suites in CI validate with exact guards); review: factory 065 peer review.]**
- [x] SB-M43-124 Add player Profile entry from the Home/profile card with active robot, campaign level, key lifetime stats, Collection completion and achievement summary. **[DONE 2026-10-30, factory 065 verify-close: LOCAL_PASS tests/m43_master_c010_meta.gd 'M43 master C010 meta evidence: PASS (12/12 cases, 0 fail)' cases m03 (factory 065 code ab035410, suites in CI validate with exact guards); review: factory 065 peer review.]**
- [x] SB-M43-125 Produce/owner-approve Profile visual master. **[OPEN 2026-10-30, factory 065 audit gap: Profile visual master not produced (manifest MASTER_REQUIRED).]** **[DONE 2026-10-31: master approved by Claude under owner-delegated authority 2026-10-31 (not owner visual review); assets/ui/generated/masters/scrubbots_profile_master_v01.png; factory 075 (bcefca76); screen rebuild tracked as SB-M43-125-REBUILD.]** **[SB-M43-125-REBUILD DONE 2026-10-31, factory 076 (8d8e73bb): open_profile rebuilt as native Controls (ProfileHero, ProfileStats 6 tiles, ProfileBests 3 rows Current/Best), hero bar = Bot Parts toward the next robot (same source as the Home HUD, no XP); 2 icons cropped from the master to assets/ui/final/profile/ (manifest provenance); LOCAL_PASS m43_master_c010_meta 12/12, m43_personal_ranks 8/8, m22_026_texture_budget PASS, m49_responsive_matrix 8/8, META_EVIDENCE CLEAN at 5 sizes; visual match by Claude under owner-delegated authority 2026-10-31, not owner visual review.]**
- [x] SB-M43-126 Implement an Achievements framework and screen with data-driven achievement definitions, progress, completed state and cosmetic/reward policy separated from gameplay truth. **[DONE 2026-10-30, factory 065 verify-close: LOCAL_PASS tests/m43_master_c010_meta.gd 'M43 master C010 meta evidence: PASS (12/12 cases, 0 fail)' cases m04 (factory 065 code ab035410, suites in CI validate with exact guards); review: factory 065 peer review.]**
- [x] SB-M43-127 Produce/owner-approve Achievements visual master before broad achievement-content production. **[OPEN 2026-10-30, factory 065 audit gap: Achievements visual master not produced (manifest MASTER_REQUIRED).]** **[DONE 2026-10-31: master approved by Claude under owner-delegated authority 2026-10-31 (not owner visual review); assets/ui/generated/masters/scrubbots_achievements_master_v01.png; factory 075 (bcefca76); screen rebuild tracked as SB-M43-127-REBUILD.]** **[SB-M43-127-REBUILD DONE 2026-10-31, factory 077 (c3af8b23): open_achievements rebuilt as native Controls (AchSummary, Ach_<id> cards with Badge/Title/Desc and COMPLETED pill or Progress + n/m, Policy, BACK + CLOSE); crown icon cropped from the master to assets/ui/final/profile/ (manifest provenance); LOCAL_PASS m43_master_c010_meta 12/12, m47_touch_r01_mobile_ux 14/14, m22_026_texture_budget PASS, META_EVIDENCE CLEAN at 5 sizes; visual match by Claude under owner-delegated authority 2026-10-31, not owner visual review.]**
- [x] SB-M43-128 Define and implement EVENTS destination without Event Points or a new event currency; use existing SB/Bot Parts/Card Packs/Booster rewards unless a later owner decision adds something. **[DONE 2026-10-30, factory 065 verify-close: LOCAL_PASS tests/m43_master_c010_meta.gd 'M43 master C010 meta evidence: PASS (12/12 cases, 0 fail)' cases m05 (factory 065 code ab035410, suites in CI validate with exact guards); review: factory 065 peer review.]**
- [x] SB-M43-129 Events support event list/home, detail, countdown, participation/progress, reward summary, ended/claimed state and offline/unavailable state. **[DONE 2026-10-30, factory 065 verify-close: LOCAL_PASS tests/m43_master_c010_meta.gd 'M43 master C010 meta evidence: PASS (12/12 cases, 0 fail)' cases m05-m07 (factory 065 code ab035410, suites in CI validate with exact guards); review: factory 065 peer review.]**
- [x] SB-M43-130 Produce/owner-approve Events visual master and at least one reusable event card/detail family. **[OPEN 2026-10-30, factory 065 audit gap: Events visual master + reusable card/detail family not produced.]** **[DONE 2026-10-31: master approved by Claude under owner-delegated authority 2026-10-31 (not owner visual review); assets/ui/generated/masters/scrubbots_events_master_v01.png; factory 075 (bcefca76); screen rebuild tracked as SB-M43-130-REBUILD.]** **[SB-M43-130-REBUILD DONE 2026-10-31, factory 078 (edb198e9): open_events/refresh_events render one UiEventCard per weekly view (active/upcoming/ended) with hero art cropped from the master, live pills, milestone rows and rule strip; FirstTry card unchanged; PLAY omitted, no event scheduled in shipped config; LOCAL_PASS m43_master_c010_meta 12/12, m43_master_c011_c014 28/28, m47_touch_r01_mobile_ux 14/14, m22_026_texture_budget PASS, META_EVIDENCE CLEAN at 5 sizes; visual match by Claude under owner-delegated authority 2026-10-31, not owner visual review.]**
- [ ] SB-M43-131 Define RANKS scoring/ranking policy in an owner decision before implementation; never invent a pay-to-win ranking metric. **[OWNER DECISION 2026-10-22, owner via factory dashboard: two tables. All-time: highest campaign level reached. Weekly: number of levels completed that week; the week resets Monday 00:00 UTC. Nothing purchasable with money or boosters counts toward either table.]**
- [ ] SB-M43-132 Implement RANKS destination with season/window label, player placement, surrounding ranks, top ranks, loading/offline/empty states and privacy-safe display identity.
- [ ] SB-M43-133 Produce/owner-approve Ranks visual master before production binding.
- [x] SB-M43-134 Home/BottomNav badge system supports Tasks ready, Daily ready, Gift claimable, Robot unlock/new, Collection new, Event active/reward and other approved attention states without notification spam. **New owner decision [2026-10-10]: Rewarded Ads Home shortcut MUST show existing red numeric 1 when exactly one currently actionable next sequential reward is claimable; missing on first iPhone IPA and observed Android family testing. Rewarded Ads badge sub-scope CODE TECH PASS on c2b1c3c7; owner accepted the new iPhone UX and Android builds without new Android physical retest; no synthetic provider/grant; broad M43-134 remains OPEN.** **[DONE 2026-10-30, factory 070 (9377dc15): every listed attention state is now asserted. m10 covers Tasks/Daily/Gift/Robots/Collection/Rewarded Ads and clear-when-handled; m06 adds the Event badge: 0 while an active event has nothing claimable (no spam), 1 on HomeBadges + Home NavBadge_events once a milestone is claimable, 0 after the claim. By design the Event badge counts claimable event rewards; a bare active event never pings. LOCAL_PASS tests/m43_master_c010_meta.gd 'M43 master C010 meta evidence: PASS (12/12 cases, 0 fail)'; review: factory 070 peer review.]**

#### M43-C010R - Weekly Mini Event / First-Try Challenge / Personal Best [OWNER APPROVED 2026-09-30]

- [x] SB-M43-R10-001 Ship a reusable **Weekly Cleaning Event** template under EVENTS: seven-day window, normal progression play contributes automatically, no new event currency, and fixed milestone rewards use only approved SB/Card Pack/Booster/Bot Part reward types. **[DONE 2026-10-30, factory 065 verify-close: LOCAL_PASS tests/m43_master_c010_meta.gd 'M43 master C010 meta evidence: PASS (12/12 cases, 0 fail)' cases m06 (factory 065 code ab035410, suites in CI validate with exact guards); review: factory 065 peer review.]**
- [x] SB-M43-R10-002 Weekly progress should primarily count valid first-clear progression wins or another owner-configured normal-play signal; replay farming, ad watching and spending do not become the fastest event path. **[DONE 2026-10-30, factory 065 verify-close: LOCAL_PASS tests/m43_master_c010_meta.gd 'M43 master C010 meta evidence: PASS (12/12 cases, 0 fail)' cases m06 (first clears count, loss adds nothing, replay of cleared level 1 to a committed WON adds nothing, no ad/purchase/spend input in event_service.gd) (factory 065 code ab035410, suites in CI validate with exact guards); review: factory 065 peer review.]**
- [x] SB-M43-R10-003 Missing a day does not reset Weekly Event progress. Event expiry/claim state is explicit, stale events fail safely, and unclaimed-expiry policy must be owner/config-defined before launch. **[DONE 2026-10-30, factory 065 verify-close: LOCAL_PASS tests/m43_master_c010_meta.gd 'M43 master C010 meta evidence: PASS (12/12 cases, 0 fail)' cases m06, m07 (factory 065 code ab035410, suites in CI validate with exact guards); review: factory 065 peer review.]**
- [x] SB-M43-R10-004 Add an opt-in **First-Try Cleanup** challenge: five qualifying progression levels form a run; only the first attempt at each qualifying level can extend the run, and a qualifying loss resets only the event run, never campaign progression. **[DONE 2026-10-30, factory 065 verify-close: LOCAL_PASS tests/m43_master_c010_meta.gd 'M43 master C010 meta evidence: PASS (12/12 cases, 0 fail)' cases m08 (factory 065 code ab035410, suites in CI validate with exact guards); review: factory 065 peer review.]**
- [x] SB-M43-R10-005 First-Try Cleanup cannot charge an extra Heart beyond the normal attempt, sell a paid continue, rewind completed campaign levels or let replay farm the run; rewards are fixed/visible before participation. **[DONE 2026-10-30, factory 065 verify-close: LOCAL_PASS tests/m43_master_c010_meta.gd 'M43 master C010 meta evidence: PASS (12/12 cases, 0 fail)' cases m08 (factory 065 code ab035410, suites in CI validate with exact guards); review: factory 065 peer review.]**
- [x] SB-M43-R10-006 Add **Personal Best** records to Profile/Achievements using self-comparison only: best Win Streak, best first-try run, boosterless first-clear count/run and other fair non-pay-to-win mastery records. No asynchronous social comparison is added by this approval. **[DONE 2026-10-30, factory 065 verify-close: LOCAL_PASS tests/m43_master_c010_meta.gd 'M43 master C010 meta evidence: PASS (12/12 cases, 0 fail)' cases m09 (factory 065 code ab035410, suites in CI validate with exact guards); review: factory 065 peer review.]**
- [x] SB-M43-R10-007 Where useful, show a lightweight **self-ghost** progress marker against the player's own prior best/current record target; it is informational, never changes difficulty/rewards and cannot imply a global/friend opponent. **[DONE 2026-10-30, factory 065 verify-close: LOCAL_PASS tests/m43_master_c010_meta.gd 'M43 master C010 meta evidence: PASS (12/12 cases, 0 fail)' cases m09 (factory 065 code ab035410, suites in CI validate with exact guards); review: factory 065 peer review.]**

#### M43-C011 - World Progression / World Home System

- [ ] SB-M43-135 Preserve World 01 Whispering Park as current default complete 1080x2160 Home background.
- [ ] SB-M43-136 Define owner-approved campaign level ranges / completion conditions for future worlds before any hardcoded range exists. **[OWNER DECISION 2026-10-22, owner via factory dashboard: World 01 Whispering Park 0001-0150; World 02 Bubble District 0151-0300; World 03 Neon Sewers 0301-0450; World 04 Crystal Laundry 0451-0600; World 05 Toxic Docks 0601-0750; World 06 Clockwork Carnival 0751-0900; World 07 Rustwood Railway 0901-1050; World 08 Frostbyte Factory 1051-1200; World 09 Midnight Metro 1201-1350; World 10 Sunken Harbor 1351-1500; World 11 Ember Foundry 1501-1650; World 12 Mosslight Ruins 1651-1800; World 13 Candy Circuit 1801-1950; World 14 Stormglass Heights 1951-2100; World 15 Phantom Museum 2101-2250; World 16 Moonbeam Observatory 2251-2400; World 17 Steamcloud Summit 2401-2550; World 18 Prism Powerplant 2551-2700; World 19 Shadowbyte Citadel 2701-2850; World 20 Grimeheart Core 2851-3000. Total: 20 worlds x 150 levels = 3000 levels. Completion condition (owner in chat 2026-10-22): a world ends at its last campaign level and the next world starts at the following level (e.g. Whispering Park ends at L150, Bubble District starts at L151).]**
- [ ] SB-M43-137 Implement data-driven world registry mapping world ID to background, title/area semantics, unlock condition and optional world reward.
- [ ] SB-M43-138 Produce/owner-approve one complete visual master/background for every shipping world before activation.
- [ ] SB-M43-139 Implement locked/current/completed world states and deterministic transition after qualifying progression.
- [ ] SB-M43-140 Implement world-unlock ceremony via M43-C005.
- [ ] SB-M43-141 Home world selection/automatic current-world presentation must never desynchronize from progression truth.
- [ ] SB-M43-142 Future world art remains decorative/meta presentation and cannot change level solver/difficulty truth.

#### M43-C012 - Comeback / Notifications / Return-to-Game Experience

- [x] SB-M43-143 Implement a non-punitive comeback surface for players returning after a configurable long absence, summarizing ready Hearts/Daily/Event/Gift/Tasks state without fabricating rewards. **[DONE 2026-10-30, factory 070 (9377dc15): c02 now also asserts on the real comeback popup that the Gift/Tasks/Events lines are absent when nothing is ready, show the real counts (2 gifts / 1 task / 1 event reward) when ready, and that opening the summary grants or claims nothing. LOCAL_PASS tests/m43_master_c011_c014.gd 'M43 master C011-C014 evidence: PASS (28/28 cases, 0 fail)'; review: factory 070 peer review.]**
- [x] SB-M43-144 Comeback flow may highlight existing claimable rewards but cannot mint an unapproved "welcome back" reward silently. **[DONE 2026-10-30, factory 065 verify-close: LOCAL_PASS tests/m43_master_c011_c014.gd 'M43 master C011-C014 evidence: PASS (28/28 cases, 0 fail)' cases c02 (factory 065 code ab035410, suites in CI validate with exact guards); review: factory 065 peer review.]**
- [x] SB-M43-145 Design opt-in push-notification categories: Hearts full/ready, Daily available, Event ending, claimable reward and other owner-approved reminders. **[DONE 2026-10-30, factory 065 verify-close: LOCAL_PASS tests/m43_master_c011_c014.gd 'M43 master C011-C014 evidence: PASS (28/28 cases, 0 fail)' cases n01 (factory 065 code ab035410, suites in CI validate with exact guards); review: factory 065 peer review.]**
- [ ] SB-M43-146 Request notification permission contextually, not on first frame, and explain the benefit before the OS prompt where platform policy permits. **[OPEN 2026-10-30, factory 065 audit gap: no contextual OS permission prompt/plugin wired.]**
- [x] SB-M43-147 Implement per-category toggles plus global notification control and quiet-hours/local-time awareness. **[DONE 2026-10-30, factory 065 verify-close: LOCAL_PASS tests/m43_master_c011_c014.gd 'M43 master C011-C014 evidence: PASS (28/28 cases, 0 fail)' cases n01, n02, n05 (factory 065 code ab035410, suites in CI validate with exact guards); review: factory 065 peer review.]**
- [x] SB-M43-148 Notifications deep-link only to valid in-app destinations and fail safely to Home when content is stale. **[DONE 2026-10-30, factory 065 verify-close: LOCAL_PASS tests/m43_master_c011_c014.gd 'M43 master C011-C014 evidence: PASS (28/28 cases, 0 fail)' cases n01, n03 (factory 065 code ab035410, suites in CI validate with exact guards); review: factory 065 peer review.]**
- [x] SB-M43-149 Never send notification spam for every Heart tick, every failed attempt or repeated unclaimed badge. **[DONE 2026-10-30, factory 065 verify-close: LOCAL_PASS tests/m43_master_c011_c014.gd 'M43 master C011-C014 evidence: PASS (28/28 cases, 0 fail)' cases n02, n04 (factory 065 code ab035410, suites in CI validate with exact guards); review: factory 065 peer review.]**
- [ ] SB-M43-150 Produce/approve any comeback/notification-permission illustration needed; keep system permission UI native. **[OPEN 2026-10-30, factory 065 audit gap: comeback/permission illustration not produced.]**
- [x] SB-M43-151 Test timezone changes, missed days, expired events, disabled permissions and stale deep links. **[DONE 2026-10-30, factory 065 verify-close: LOCAL_PASS tests/m43_master_c011_c014.gd 'M43 master C011-C014 evidence: PASS (28/28 cases, 0 fail)' cases n02 (notifications disabled with live candidates -> nothing decided/sent, assertion added), n03 (stale deep links), n04 (clock rollback), n05 (timezone), c01 (missed days); tests/m43_master_c010_meta.gd 'M43 master C010 meta evidence: PASS (12/12 cases, 0 fail)' case m07 (expired still-claimable event never produces event_ending, assertion added) (factory 065 code ab035410, suites in CI validate with exact guards); review: factory 065 peer review.]**

#### M43-C012R - Comeback Catch-Up / Smart Notification Prioritization [OWNER APPROVED 2026-09-30]

- [ ] SB-M43-R12-001 Add a configurable **Comeback Catch-Up Track** for a genuine absence (initial tuning candidate: >=48 hours): three qualifying first-clear progression wins rebuild momentum through a small capped reward/progress sequence using only approved existing reward types. **[OPEN 2026-10-30, factory 065 audit gap: shipped comeback_v1.json has no catch-up steps (reward values need owner).]**
- [x] SB-M43-R12-002 Catch-Up never restores missed Daily login days, never changes the existing consecutive-login reset/cycle rule, never retroactively grants missed event/Daily rewards and never multiplies normal level economy. **[DONE 2026-10-30, factory 065 verify-close: LOCAL_PASS tests/m43_master_c011_c014.gd 'M43 master C011-C014 evidence: PASS (28/28 cases, 0 fail)' cases c02, c04 (factory 065 code ab035410, suites in CI validate with exact guards); review: factory 065 peer review.]**
- [x] SB-M43-R12-003 Catch-Up is offered once per eligible return window, persists across relaunch, completes/expirs deterministically and cannot be farmed by clock rollback, uninstall/reinstall or repeatedly backgrounding the app. **[DONE 2026-10-30, factory 070 (9377dc15): c04 now asserts that expiry is exact at window_ts + catchup_expire_days*86400 (claimable 1 s before; at the boundary it is expired, wins are frozen, the summary is gone, claims are refused, and the state is identical after relaunch). Uninstall/reinstall: with no cloud the reinstall is a fresh profile (absent `return` section), so there is no window, no Catch-Up and no summary, and relaunching opens nothing. Reinstall plus a restored copy keeps the claimed steps claimed, so nothing is re-granted. c01/c04 already cover rollback, relaunch and backgrounding. LOCAL_PASS tests/m43_master_c011_c014.gd 'M43 master C011-C014 evidence: PASS (28/28 cases, 0 fail)'; review: factory 070 peer review.]**
- [x] SB-M43-R12-004 Define a notification **priority/dedup authority** across Hearts ready, Daily available, Gift claimable and Event ending so simultaneous triggers collapse into the single most useful message/deep link instead of multiple pushes. **[DONE 2026-10-30, factory 065 verify-close: LOCAL_PASS tests/m43_master_c011_c014.gd 'M43 master C011-C014 evidence: PASS (28/28 cases, 0 fail)' cases n02 (factory 065 code ab035410, suites in CI validate with exact guards); review: factory 065 peer review.]**
- [x] SB-M43-R12-006 Notification copy must be factual and non-guilt-inducing, must not claim expiring rewards that are not actually expiring, and must suppress stale/already-consumed prompts before send when current state is available. **[DONE 2026-10-30, factory 065 verify-close: LOCAL_PASS tests/m43_master_c011_c014.gd 'M43 master C011-C014 evidence: PASS (28/28 cases, 0 fail)' cases n03 (factory 065 code ab035410, suites in CI validate with exact guards); review: factory 065 peer review.]**

#### M43-C013 - Account / Cloud Save / Cross-Device Recovery

- [ ] SB-M43-152 Keep local save authoritative/offline-capable even when account/cloud features are unavailable.
- [ ] SB-M43-153 Define optional account/sign-in provider strategy in an owner/platform decision before adding SDKs. **[OWNER DECISION 2026-10-22, owner via factory dashboard: Android uses Google Play Games Saved Games; iOS uses Game Center + iCloud. Both are free; no own server needed. No separate account or e-mail login.]**
- [ ] SB-M43-154 Implement cloud-save schema/versioning compatible with M40 and preserve idempotent economy transaction IDs.
- [ ] SB-M43-156 Implement sign-in, signed-out, syncing, synced, conflict, error and offline states.
- [ ] SB-M43-157 Implement restore-on-new-device flow and verify Collection/robots/booster/entitlement/Daily state integrity.
- [ ] SB-M43-158 Platform purchase restore remains tied to M57/store authority and must reconcile with cloud/local save idempotently.
- [ ] SB-M43-159 Produce/owner-approve only the minimal account/cloud screens needed; do not replace platform-native sign-in consent UI.
- [ ] SB-M43-160 Add destructive account/sign-out/reset confirmations and privacy-data entry points as required by M58.

#### M43-C014 - Meta UI Audio / Haptics / Offline / Error Language

- [x] SB-M43-163 Meta UI must obey Master/Music/SFX/Haptics settings immediately. **[DONE 2026-10-30, factory 065 verify-close: LOCAL_PASS tests/m43_master_c011_c014.gd 'M43 master C011-C014 evidence: PASS (28/28 cases, 0 fail)' cases a02 (SFX/Haptics/Reduced live, Master OFF silences at once, Music OFF leaves meta SFX on: meta UI has no music path) (factory 065 code ab035410, suites in CI validate with exact guards); review: factory 065 peer review.]**
- [x] SB-M43-164 No purchase/ad/error sound may falsely imply success before an authoritative callback. **[DONE 2026-10-30, factory 065 verify-close: LOCAL_PASS tests/m43_master_c011_c014.gd 'M43 master C011-C014 evidence: PASS (28/28 cases, 0 fail)' cases a01 (factory 065 code ab035410, suites in CI validate with exact guards); review: factory 065 peer review.]**
- [ ] SB-M43-165 Implement consistent offline/error language and retry affordances for Shop, ads, cloud, Events, Ranks and notifications/deep links. **[OPEN 2026-10-30, factory 070 (9377dc15): a04 now asserts the shared network-error popup's TRY AGAIN control on every surface (store, rewarded_ad, cloud, live_event): it is live on the error state, a failed retry leaves it usable, the second retry recovers and closes, and nothing is granted (LOCAL_PASS tests/m43_master_c011_c014.gd 'M43 master C011-C014 evidence: PASS (28/28 cases, 0 fail)'). Still open because no live caller exists yet: no store IAP, no ad provider (M57), no cloud provider (SB-M43-153), and Ranks is not live. Needs those live services.]**
- [ ] SB-M43-166 Implement graceful empty states for no events, no rankings result, no exchangeable duplicates, no claimable gifts and no tasks ready. **[OPEN 2026-10-30, factory 070 (9377dc15): the no-tasks-ready (claims blocked, no badge, TASK_NONE for an unavailable order) and no-duplicates (Cards Exchange CARDS_EMPTY, exchange-all blocked) states are now asserted on the real popups in a04, with positive controls; no-gifts (a04) and no-events (m05) were already asserted (LOCAL_PASS tests/m43_master_c011_c014.gd 'M43 master C011-C014 evidence: PASS (28/28 cases, 0 fail)'; LOCAL_PASS tests/m43_master_c010_meta.gd 'M43 master C010 meta evidence: PASS (12/12 cases, 0 fail)'). The no-rankings result stays open while Ranks is not live.]**
- [ ] SB-M43-168 Owner acceptance required for the final cross-screen sound/haptic feel. **[OPEN 2026-10-30, factory 065 audit gap: final cross-screen sound/haptic feel acceptance not done.]**

#### M43-C015 - Player-Facing Surface Visual Inventory Gate

Before M43 program closure, the following surfaces must each have a canonical visual master/reference, production scene, responsive validation, independent audit and owner acceptance where visually material:

1. Gameplay V02.
2. Pause.
3. Level Intro.
4. Victory / Results.
5. Fail / Retry.
6. Life / Heart refill.
7. Need a Hand.
8. Booster Acquire.
9. 2x Acquire.
10. Insufficient SB / purchase handoff.
11. Shop.
12. Collection album.
13. Collection set detail.
14. Card detail.
15. Cards Exchange.
16. Standard Pack opening.
17. Premium Pack opening.
18. Collection-set completion.
19. Master Collection completion.
20. Robots main.
21. Robot detail/locked.
22. Robot unlock.
23. Tasks.
24. Daily.
25. Gift Bar.
26. Gift Meter milestone.
27. Profile.
28. Achievements.
29. Events main/list.
30. Event detail/reward.
31. Ranks.
32. Comeback/return summary.
33. Feature unlock/coachmark.
34. World unlock/transition.
35. Account/cloud sync/conflict where custom UI is needed.
36. Generic reward/confirmation.
37. Generic error/offline/loading.
38. Notification education/settings where custom UI is needed.
39. Rewarded Ads daily claim/watch surface.

- [ ] SB-M43-169 Create `assets/ui/PLAYER_EXPERIENCE_ASSET_MANIFEST.json` covering every surface above and all generated illustration components. **[OPEN 2026-10-30, factory 065 audit gap: manifest ids do not cover data/config/ui_surface_registry_v1.json ids (19 missing, e.g. home, results, settings) and it has no Rewarded Ads surface (list item 39).]**
- [ ] SB-M43-170 No M43 program closure while any required surface is missing, visually unreviewed, wired to dummy data or reachable only through debug tooling. **[OPEN 2026-10-30, factory 065 audit gap: closure gate: surfaces still MASTER_REQUIRED, Ranks/Level Intro not live.]**

#### M43-C015R - Owner Runtime Review Remediation [OWNER REQUEST 2026-10-06]

These three rows are the only new work authorized by the 2026-10-06 F5 owner review. The existing four primary Home panels remain SHOP / COLLECTION / TASKS / DAILY; the Rewarded Ads entry is an additional compact auxiliary CTA, not a fifth equal Home panel. Existing Daily consecutive-login authority remains intact and separate.

- [x] **SB-M43-R15-001 — Rewarded Ads daily five-slot surface.** Technical base exists, but owner has now locked **sequential unlock** semantics: Slot 1 is a direct `CLAIM`; only after Slot 1 is durably granted does Slot 2 become available; only after Slot 2 receives a successful verified rewarded-video grant does Slot 3 unlock; then 4; then 5. Future slots stay visibly locked and cannot start an ad early. Cancel/skip/fail/timeout/unverified/provider-unavailable grants nothing **and does not advance the sequence**. Each slot grants exactly once per local day under deterministic tx ids `daily_rewarded:<local_day>:<slot>`. Seeded D1-D5 reward bundles, distinct rewarded-daily authority, rollback/relaunch/idempotency protections, Daily login separation and Daily Scrub Orders remain unchanged. **No Home notification/badge is required. `SB-M43-R15-001-R01` functional sequential-unlock remediation is PASS / CLOSED [2026-10-08] on `f4448d473d2c6bd62be3a83d31299eedea50b6ec`; strict audit: `coordination/sessions/M43-OWNER-R15/CHATGPT_AUDIT_R15_001_R01_SEQUENTIAL_UNLOCK_V01.md`. Remote Content / R2 files were untouched. This parent row remains OPEN only for owner visual acceptance of the Rewarded Ads surface, including LOCKED rows.** **CLOSED [2026-10-22]: R01 `f4448d47` (on origin/main), `tests/m43_r15_001_r01_sequential_unlock.gd` 14/14 + `m43_r15_owner_remediation` 18/18 PASS in green CI run 39828088266; owner visual acceptance GIVEN per CLAUDE.md §0D.1; real ad provider is separate (SB-M57-001); factory 022.**
- [x] **SB-M43-R15-002 — Settings visual-family remediation.** Preserve every closed M41 Settings behavior/state/persistence contract exactly, but replace the generic dark rectangle with the canonical SCRUBBOTS M43 popup language visible in the owner's accepted screens: cyan/white mechanical frame, cream/white content field, royal-blue SETTINGS title treatment, canonical close/X treatment, readable navy labels, themed sliders/toggles and touch targets. Reuse `BasePopup`/`HomeStyle`/`UiTokens`/approved existing assets where practical; do not add a second settings authority or alter Master/Music/SFX/Haptics/Reduced Effects semantics. CLOSED [2026-10-22]: code 24828bb; local suites PASS m43_r15_owner_remediation 18 of 18, m41_settings, m43_master_c009_daily 12 of 12, m39d_daily_collection, m49_responsive_matrix 8 of 8, m43_r15_001_r01_sequential_unlock 14 of 14; technical audit CHATGPT_AUDIT_V01 PASS; owner visual acceptance given under CLAUDE.md §0D.1 (factory 025).
- [x] **SB-M43-R15-003 — Daily Rewards containment remediation.** Keep the current consecutive-login logic, D1-D5 values and claim authority unchanged. Fix the owner-observed composition so Daily Rewards art does not protrude outside the intended popup/table/content bounds: the calendar/hero, flame, five day-card frames, state/check art, rule text and buttons must remain visually contained and readable at 683x1366 and the canonical responsive matrix. No clipping of reward text, no overlap with title/actions, no layout regression to Tasks/Gift Bar, and no change to Daily reward truth. CLOSED [2026-10-22]: code 24828bb; local suites PASS m43_r15_owner_remediation 18 of 18, m41_settings, m43_master_c009_daily 12 of 12, m39d_daily_collection, m49_responsive_matrix 8 of 8, m43_r15_001_r01_sequential_unlock 14 of 14; technical audit CHATGPT_AUDIT_V01 PASS; owner visual acceptance given under CLAUDE.md §0D.1 (factory 025).

**Shared later-screen visual production rules**
- [x] SB-UI-017 Implement reusable `BasePopup` composition. — 2026-10-22 factory 023: base_popup.gd is the single popup component, reused by popups.gd + 14 screens (shop, collection, robots, daily, profile, ceremonies, settings...); covered by suites m43_c003_c001_acquisition, m43_r15_owner_remediation, m50_accessibility_audit, CI 39828088266 PASS.
- [x] SB-UI-018 Keep popup text/rewards/quantities/buttons/state dynamic in Godot. — 2026-10-22 factory 023: titles/bodies/CTAs set at runtime via set_title/add_body_line/add_action(UiText.t(...)); chrome art has no baked text (base_popup.gd header); CI 39828088266.
- [ ] SB-UI-019 For each later screen milestone, identify/generate/approve/bind required illustration assets inside that milestone. — standing per-milestone process rule, not ticked (factory 023, 2026-10-22).
- [ ] SB-UI-020 Do not pre-generate speculative asset libraries for unknown future states.
- [ ] SB-UI-021 Treat final visual polish as consolidation/QA, not first production-art implementation.

### M44 - Tutorial / FTUE / Feature Unlock Pacing [DESIGN + IMPLEMENTATION REQUIRED]

Purpose: teach the real production game progressively and prevent the first session from exposing every meta system at once. Feature unlocks are presentation/access pacing only; they do not rewrite already-earned authoritative state.
**Owner 2026-10-12 FINAL M44 V03 supersession:** SB-M44-001's historical first 10 levels now means coverage/negative regression only: mandatory tutorial Home+L1–L3, NONE L4–L10. First Home DAILY and TASKS separate real READY claims BOTH 100 SB; welcome task replaces day-one easy slot only, no global change to ordinary later days 75/100/125. Starting 2 charges each four canonical boosters. Current owner authority `coordination/sessions/M44-TUTORIAL-FTUE-C001/OWNER_M44_FIRST3_STARTER_AND_CLAIM_DECISION_V03.md`, implementation master and independent audit checklist in same folder. All 24 M44 IDs retained, unchecked until independent GitHub code/CI audit and owner visual acceptance.
**M44 current independent audit [2026-10-15]:** Core FTUE technical PASS on GitHub CI **35/35 suites** (M44 21/21; CP06 16/16), including specialist M39/M41/M43 suites and M44 D1 copy caching fix. Audits: `coordination/sessions/M44-TUTORIAL-FTUE-C001/CHATGPT_INDEPENDENT_AUDIT_V02.md` plus prior V01. **16/24 technically completed** as marked below; **005/006/010/013/018/020/022/023 remain OPEN** because of contextual teaching, unsanctioned future feature unlock order, NEW badge, phone/visual owner sign-off and M43 external gates. A real APK/IPA first-user playthrough is not yet authorized. Review D2 future What's New announcement for newly onboarded players only after owner's product choice. **NEWER owner 2026-10-15 ruling:** the D2 feature announcement product decision is APPROVED but not implemented; see SB-M44-D2-001 and `OWNER_D2_WHATS_NEW_AND_DISK_DIAG_DECISION_V01.md`. Do not close from older run 38707495178. **LATER 2026-10-15 D2 ADDENDUM:** M44-D2 has since passed independent technical audit + CI 38742572367 and 38753823564; technical D2 row below is [x]. The earlier text describes the pre-D2 snapshot; owner visual gates remain unchanged.

- [x] SB-M44-005 Teach WAITING/no-current-target behavior only when the player first encounters it, using contextual coachmark/highlight. **[DONE 2026-10-26, factory 054, 23583381; LOCAL_PASS tests/m44_contextual_coach.gd M44 CONTEXTUAL COACH: PASS (7/7); regressions m44_ftue 23/23, m44_unlock_gate 6/6, m46_rm003_ftue_coach_performance, m46_r07_ui_legality, m51_localization_readiness 4/4, m55_heart_900_authority PASS: contextual `ctx_waiting` (data/config/ftue_onboarding_v1.json `contextual`) on the five-slot strip at the first real `is_slot_waiting`, new profiles only, once; scheduled l3_waiting removed.]**
- [x] SB-M44-006 Teach win/fail/Retry and Heart consequence at first relevant occurrence. **[DONE 2026-10-26, factory 054, 23583381; LOCAL_PASS tests/m44_contextual_coach.gd M44 CONTEXTUAL COACH: PASS (7/7); regressions m44_ftue 23/23, m44_unlock_gate 6/6, m46_rm003_ftue_coach_performance, m46_r07_ui_legality, m51_localization_readiness 4/4, m55_heart_900_authority PASS: `ctx_result_won` / `ctx_result_lost` on the first WON / LOST Results, Heart sentence from the committed receipt, pointer on RETRY, once each; scheduled l3_hearts removed.]**
- [x] SB-M44-010 Define owner-approved feature-unlock order/campaign points for Hearts, booster acquisition, Daily, Tasks, Collection, Card Packs, Robots, Gift Meter/Gift Bar, Shop, Events, Ranks, Achievements and any later system. **[OWNER DECISION 2026-10-22, owner via factory dashboard: Hearts from the start. Boosters unlock in order (owner in chat 2026-10-22): +1 Slot at 6, Random at 11, Selector at 16, Tornado at 21. Daily Rewards 4, Shop 8, Tasks 12, Collection 20, Events 30, RANKS 40. Owner in chat 2026-10-22: Gift Bar 1, Card Packs 20 (with Collection), Robots 25, Achievements screen 35 (stats from L1); full design `coordination/OWNER_META_PROGRESSION_DESIGN_V01.md`, implementation SB-M44-025..030.]** **[DONE 2026-10-23, factory 042, bd5e3de9: table is data (SB-M44-011 data-driven) in `data/config/feature_unlocks_v1.json`, strict fail-open reader `scripts/progression/feature_unlocks.gd`, one gate `AppState.feature_unlocked(id)`; grandfather default = not a new FTUE profile keeps everything. `tests/m44_unlock_gate.gd` LOCAL_PASS 6/6 (record_win level walk L1..L40 with boundary pairs, config == owner table).]**
- [x] SB-M44-013 Newly unlocked Home shortcut/Nav destination may show a NEW badge until first visit; badge clearing persists. **[DONE 2026-10-26, factory 055, b07ca99e; LOCAL_PASS tests/m44_new_badge.gd M44 new badge evidence: PASS (6/6); regressions m44_unlock_gate 6/6, m44_ftue 23/23, m44_contextual_coach 7/7, m42_home, m42_navigation, m40_save_system, m36_v02_migration, m43_master_c010_meta 12/12, m43_r15_001_r01_sequential_unlock 14/14, m47_touch_r01_mobile_ux 14/14, m49_responsive_matrix 8/8, m50_accessibility_audit 4/4, m51_localization_readiness 4/4 PASS: `HomeBadges.new_features` (new FTUE profiles only, unlocked + not visited), "NEW" pill on the existing Shortcut / NavBadge badge (a real count wins), first press marks meta_ui `feature_visited:<feature>` + canonical save; no new save section or schema bump.]**
- [x] SB-M44-018 Produce/owner-approve tutorial coachmark/highlight visual language and any Scrubby/robot teaching poses actually required. **[DONE 2026-10-26, factory 055, b07ca99e: existing CoachmarkLayer language (approved ring / pointer / bubble art, layout, colours, pointer bob, Reduced Effects, reuse rule, NEW pill) documented in docs/16 §1.5; no additional art or Scrubby teaching poses required; owner visual gate given (CLAUDE.md §0D.1).]**
- [x] SB-M44-020 Owner playtest the complete first-session funnel and revise friction before M44 closes. **[VERIFY-CLOSE 2026-10-22, factory job 021: owner playtest gate given (CLAUDE.md §0D.1). Fresh-save funnel suites LOCAL_PASS on Godot 4.7.2 at 91e498f6: m44_ftue 23/23, m42_opening, m42_navigation, m42_home, m46_rm003_ftue_coach_performance (4 groups). Source walk found no blocking friction in the shipped funnel; the friction is the gap to the 2026-10-22 unlock table (L1 Home coachmarks point at Daily (unlock L4) and Tasks (L12); the L2 lesson teaches all four boosters (unlock 6/11/16/21) with starter charges granted at L1; `ftue_onboarding_v1.json` still declares `soft_no_hard_locks`), filed as SB-M44-031.]**

#### M44 Retention Feature-Pacing Additions [OWNER APPROVED 2026-09-30]

- [ ] SB-M44-022 Sequence Collection onboarding so Set 1 / first earned packs establish the First Collection Sprint early, while pity remains invisible until relevant and then explains itself truthfully.
- [ ] SB-M44-023 Unlock Daily Scrub Orders, Weekly Cleaning Event and First-Try Cleanup only after their prerequisite core/meta systems are understood; exact campaign unlock points remain data-driven under SB-M44-010/011.

#### M44 Meta Progression Design [OWNER DECISION 2026-10-22, `coordination/OWNER_META_PROGRESSION_DESIGN_V01.md`]

- [x] SB-M44-025 Pending-pack inventory: Card Packs earned before L20 (Gift Bar or any existing source) are stored, never lost and never converted, and become openable when Card Packs unlock at L20 with Collection; no new rewards created. **[DONE 2026-10-30, factory 066, 9f335a86: grants already enqueue into the durable `economy.pending_packs`; `AppState.open_earned_pack` now returns `{ok:false, reason:"locked"}` and `PackPresenter.drain()` is a silent no-op while `feature_unlocked("card_packs")` is false (fresh profile below L20; grandfathered saves unchanged). Existing Home-arrival drain (`_drain_home_ceremonies`) opens the queue FIFO at L20; no new save field, popup or reward. New `tests/m44_pending_packs_gate.gd` LOCAL_PASS `M44 PENDING PACKS GATE: PASS (6/6 cases, 0 fail)`, added to CI validate (59 suites, exact guard). Regressions LOCAL_PASS: m43_master_c007_collection 17/17, m43_master_c005_meta_ceremonies 32/32, m44_unlock_gate 6/6, m44_ftue 23/23, m40_save_system, m43_c005f_phase2_r01_earned_pack_runtime 22/22, m43_c005f_phase3_meta_rewards_acquisition 15/15, m54_collection_set_master_exactly_once; no fixture changes needed. Full local run_suites 56/59 under load: only timing budgets missed (m46_performance frame/retry, m50_color_symbols 300-rebind time, c007 set-detail build; c007 PASS 17/17 on standalone rerun); GitHub CI is the arbiter.]**
- [ ] SB-M44-026 Featured Card schedule data for all 135 cards (Set 01 special schedule L20..L40; other sets +0/+10/+20/+30/+40/+50/+60/+70/+90 from their featured range start, catalogue order) plus guaranteed Scrubby at L20 and a guaranteed not-yet-owned Set 01 card at the L30 and L40 milestones; packs stay random with existing rarity/duplicate rules.
- [ ] SB-M44-027 Robot 5-stage visual assembly at 50/100/150/200/250 Bot Parts toward the next 250-part unlock (visual only, no per-part inventory or new currency); Robots destination unlocks at L25; robot target levels stay non-binding.
- [ ] SB-M44-028 Expand `data/config/achievements_v1.json` from 8 to the owner's 32 (Level 8, Collection 9, Robot 5, Skill 8, Gift Bar 2), keeping the existing 8; stats tracked from L1 (first-time progression levels only), Gift Meter stats wired in, Achievements screen unlocked at L35.
- [ ] SB-M44-029 Cosmetic achievement rewards (Alternative A): badges / profile frames / Collection showcase decoration, no economy rewards; exact items are an open owner detail in the design doc.
- [ ] SB-M44-030 Verify Gift Bar is visible and progressing from the first Home (L1) with the existing 10/50/250/500/1000 rewards unchanged; add a regression test.
- [x] SB-M44-031 (part 1) Re-sequence the FTUE (`data/config/ftue_onboarding_v1.json`, `scripts/app/ftue_config.gd`, `scripts/app/app_state.gd`, `tests/m44_ftue.gd`) to the 2026-10-22 owner unlock table once SB-M44-010 lands: move the L1 Home Daily/Tasks coachmarks to the first Home after Daily (L4) / Tasks (L12) unlock, replace the L2 four-booster lesson with a per-booster introduction at its unlock level (+1 Slot 6, Random 11, Selector 16, Tornado 21), keep the existing starter charge amounts but surface each with its booster's unlock, align the first-day welcome task with Tasks at L12, and retire the `soft_no_hard_locks` / `available_from_first_home` policy. No new rewards or mechanics. (Filed by SB-M44-020 verify-close, 2026-10-22.) **[PART 1 DONE 2026-10-23, factory 042, bd5e3de9: hard unlock gate per the owner table (`data/config/feature_unlocks_v1.json`, `scripts/progression/feature_unlocks.gd`, `AppState.feature_unlocked`, grandfather = not a new FTUE profile); Home DAILY/TASKS/SHOP/COLLECTION shortcuts and ROBOTS/EVENTS/RANKS tabs disabled with "Unlocks at level N", no badge, no navigation; booster bar `locked` (charges kept, press inert); FTUE skips coachmarks on locked controls (L1 Daily/Tasks tips and both L2 booster steps on a fresh profile; L1-L3 window still closes at L3); `soft_no_hard_locks` / `available_from_first_home` retired. LOCAL_PASS Godot 4.7.2: m44_unlock_gate 6/6, m44_ftue 23/23, m42_home, m42_navigation, m42_opening, m28_c002_c001_gameplay_v02, m39c_boosters, m43_c003_c001_acquisition, m46_rm003_ftue_coach_performance, m46_r07_ui_legality, m46_rm002_adversarial (ea0cc0ad: the three m46 FTUE coach suites open L2 boosters in the in-memory unlock table). Full CI list via tools/run_suites.py: 44/45 PASS; m46_performance fails only `retry() on 59x59 worst` (52-59 ms vs 50.1 ms), which also fails on the pre-change scripts on this machine (60.00 ms), timing noise. Part 2 below.]**
- [ ] SB-M44-031 part 2: per-booster lessons at their unlock levels (+1 Slot 6, Random 11, Selector 16, Tornado 21) reusing the existing L2 lesson copy; move the Daily/Tasks coach marks to the first Home after L4 (Daily) / L12 (Tasks); defer the starter booster grant and the 100 SB welcome task until their feature unlocks (kept pending, never deleted); retire the remaining soft-discovery wording in docs. Resolves the part-1 interim state: a fresh profile holds 8 starter charges and a welcome task it cannot use until the matching feature unlocks (nothing lost; Tasks hides the welcome task until L12). No new rewards or mechanics.

### M45 — Debug Tooling

**M45 independent technical closure [2026-10-15]:** Source, 8 real-headless cases and full **35/35** cloud CI suites independently reviewed by ChatGPT. Developer-only debug HUD/board layer/harness, instant reset, level picker and release gate PASS. All 18 tasks technically closed below. Audit: `coordination/sessions/M45-DEBUG-TOOLING-C001/CHATGPT_INDEPENDENT_AUDIT_V01.md`. No APK export or device manual UI claim; 59×59 performance remains M46.

### M46 — Performance `[PERFORMANCE]`

Maximum board target: 59×59 = 3,481.

**CHATGPT INDEPENDENT M46 SOURCE AUDIT [2026-10-16]:** `coordination/sessions/M46-PERFORMANCE-C001/CHATGPT_INDEPENDENT_AUDIT_V01.md`. Read `tests/m46_performance.gd` at 6da83668, Claude performance log/peer review and Git comparison from 54f40803. p16 is a real ProductionGameplayHost with Level Data v2, 59×59, 456 VOID/3,025 art cells, 12 canonical colours and nested pocket unlocks. It asserts WON, presence of WAITING, P1<P2<P3 first-clear order, 60 paused frames, mean and p99 CPU budgets. Claude reports 16/16 LOCAL_PASS; **not independently executed**. Peak of 5 WAITING slots and 1×/2× effective-speed change are observed/reported but not directly asserted. M46-015, high-load sixth slot/boosters, winding multi-colour routes and phone/GPU remain OPEN. **GitHub Actions freeze still applies.**
**CLAUDE_AUTONOMOUS_REVIEW [2026-10-16] — SB-M46-001..014 LOCAL DESKTOP BASELINES MEASURED (LOCAL_PASS 15/15, CLOUD_CI_DEFERRED_COST_FREEZE, NO DEVICE).** `tests/m46_performance.gd`: a complete 59×59 level (3,481 clears, 114 bots in flight) played to WON through the real ProductionGameplayHost at frame mean 2.36 / p99 8.5 ms desktop CPU. The board-size memory cost is +0.34 MB, and 30 retries leave no leak. Two fixes:
- slot strip no longer rebuilt every frame (`ui_snapshot_sync` 2.0 → 0.3 ms);
- idle board magnifier no longer processes.

Log `coordination/sessions/M46-PERFORMANCE-C001/CLAUDE_LOG_V01.md`; `CLAUDE_PEER_REVIEW` `coordination/sessions/M46-PERFORMANCE-C001/CLAUDE_PEER_REVIEW_V01.md` (not ChatGPT). **[2026-10-16 follow-up] second 59×59 fixture `m46_pockets_59` added (suite LOCAL_PASS 16/16).** It is Level Data v2 with a VOID ring, 12 colours and three 3-deep nested pockets. Played to WON: a pocket batch WAITED in its slot from frame 5, all 5 slots were waiting at peak, P1 < P2 < P3 unlock order held, and pause / 1x-2x mid-level worked. Frame mean 2.10 / p99 9.5 ms desktop.

**[2026-10-16 R02] LOCAL_PASS 19/19, test-only.**
- **p16:** now asserts peak 5 WAITING, WAITING → ACTIVE recovery and no WAITING at terminal. The pause runs with 35 bots in flight and freezes every gameplay truth. Speed authority reads 2 → 1 → 2.
- **p17:** +1 Slot is bought with SB exactly once and a 7th slot is refused. The sixth slot is occupied, shown in the UI and dispatching. An owned Tornado works on the dense 59×59 board. Illegal, paused and terminal attempts mutate nothing, and retry gives 5 slots.
- **p18:** 59×59 maze where real routes turn 7 times through 41 cells along the cleared corridor, with no duplicate reservation; WON.
- **p19:** see SB-M46-015 below.

Rows stay OPEN for: phone/GPU numbers (M47) and a ChatGPT audit.

**[2026-10-16 R03] Random + Selector under 59×59 load: R03_PARTIAL.** Functionally PASS (p20). Full-suite timing is unstable on the owner laptop under contention: a busy Godot process was using about one core. **Corrected R05:** this was not verified as the owner's editor; it may have been an orphaned test process.
- **Random:** legal with 3 free slots (its owner rule), charged once, every batch conserved.
- **Selector:** the chosen batch goes into a slot, charged once.
- **Production fix:** Selector execute 641 → 44 ms, by proving the single chosen batch. Equivalence was checked for all 92 ids, plus a `CLAUDE_PEER_REVIEW`; booster regressions PASS.
- **Open findings:**
  - Selector legality listing takes about 0.6 s (the popup target list; the UX change needs the owner).
  - One Random refusal proof was observed at about 5.1 s (classifier unbounded in time; not reproduced).

Log `coordination/sessions/M46-PERFORMANCE-C001/CLAUDE_LOG_R03_V01.md`.

**[2026-10-16 R04] booster legality in-flight shortcut: LOCAL_PASS.** When bots are in flight, the solver-safety probe skips building the full 59×59 ProofState. That is exact: the classifier answers PROGRESSABLE before reading the state, and every `from_runtime` null condition is mirrored.
- **Selector legality:** about 600 → about 120–150 ms. `eligible_safe_batches` (110 batches) 927 → 160 ms.
- **Random legality:** about 22 → 3 ms.
- **Evidence:** p20 asserts verdict equality for 92 batches plus the null-mirroring refusals. 15 booster / gate / chaos / need-a-hand regressions PASS. `CLAUDE_PEER_REVIEW` found 0 blockers / majors.
- **Still open:** quiet moments with no bots in flight (full proof, about 1 s list at 59×59; the 5.1 s refusal case). Bounding the classifier is an owner-visible tradeoff.

Log `coordination/sessions/M46-PERFORMANCE-C001/CLAUDE_LOG_R04_V01.md`.

**[2026-10-16 R05] owner time budget on booster safety proofs: LOCAL_PASS for the owner rules; the budget value is an OWNER DECISION.** Owner rules (chat, 2026-10-16): target 250 ms or a measured safe limit; on timeout cancel safely; never spend SB or a charge; valid moves never permanently blocked, so the player can retry; test 59×59 moving and still; no Actions.
- **Change:** solver / kernel / classifier take an optional wall-clock deadline, and a timeout is UNKNOWN_BOUND (fail closed). `PROOF_BUDGET_MS = 400`, because a 250 ms limit would refuse a single 59×59 Selector proof (249–361 ms).
- **Refusals:** a refused Random / Selector returns `proof_timeout`, and nothing is reserved. The Selector list / has-any resume after the batch that ran out. The popup shows a retry line and keeps Random tappable.
- **Need-a-Hand prover:** stays unbudgeted (deterministic).
- **Reproduced (unbudgeted, still moment, desktop):**
  - 59×59: Random 3.8–24.5 s, Selector list about 25–30 s.
  - Production L1–L10 level start: Random 0.13–4.6 s, Selector list 0.9–12 s.

  These were real freezes before R05.
- **With 400 ms:**
  - every call took at most 420 ms;
  - moving robots: 0% refused;
  - still 59×59: Random 100% `proof_timeout`;
  - still L1–L10 start: Random OK only on L1 / L3 / L4.
  - A retry after a tap succeeds. Forced 1 ms cases prove no spend on both the SB and charge paths and one-batch rotation.
- **Evidence:** p21 + 17 booster / popup / need-a-hand / chaos / completion suites PASS locally. Test oracles were updated in m39_v04 / m55 / m28 (the no-spend checks are kept). A distinct `CLAUDE_PEER_REVIEW` (not ChatGPT) found 0 blockers; its 4 majors and 4 minors are fixed.
- **Open:**
  - **owner decided (2026-10-16): keep 400 ms for now. Next M46 step is R06, a time-sliced off-frame booster proof with a "Checking…" state.** Plan `coordination/sessions/M46-PERFORMANCE-C001/CLAUDE_M46_R06_OFFFRAME_PROOF_PLAN_V01.md` (not implemented; owner gates O1 spinner, O2 total cap with 5 s proposed, O3 owned-Random HUD hold);
  - completion LOSE proof at still 59×59 freezes 1.1–3.3 s per tick (owner-locked, reported only);
  - phone / GPU, ChatGPT audit, cloud CI.

Log `coordination/sessions/M46-PERFORMANCE-C001/CLAUDE_LOG_R05_V01.md`.

**[2026-10-16 R06] off-frame booster safety proof with a "Checking..." state: LOCAL_PASS; owner F5 visual sign-off OPEN.** Owner chose the defaults: O1 text, O2 5 s cap, O3 HUD hold.
- **Why a thread:** step 1 measured a single proof placement at 87–456 ms, so cooperative slicing was not viable (plan §0 amendment).
- **How it works:** the unchanged proof runs on a WorkerThreadPool task over a detached adapter copy; the shared static mask cache is now Mutex-guarded. The verdict is cached for the exact state (Array key), so legality and execute answer at once.
- **UX:**
  - popups show "Checking..." with Use / SB blocked;
  - an owned Random tapped at a still moment holds, then auto-uses once;
  - a 5 s timeout is cached (no re-freeze; retry after the next move);
  - cancel on close / retry / exit.
- **p22 (59×59 still):**
  - worst frame while proving 0.6–1.4 ms;
  - check start about 1 ms;
  - cancel 2–3 ms;
  - stale result dropped;
  - HUD Random used once with 0 main-thread proofs;
  - detached copy == live verdicts on L1–L4 starts and an L1 mid-play state.
- **Regressions:** 22 suites PASS locally. Oracles updated in m28_c002_c003 / m28_c002_c001 (they wait for the check).
- **Review:** distinct `CLAUDE_PEER_REVIEW` (not ChatGPT) CONDITIONAL; its majors and minors are fixed.
- **Open:**
  - the rewarded-grant / FTUE legality calls still use the 400 ms synchronous path;
  - the 59×59 Selector list is partial at the 5 s cap;
  - phone / GPU, ChatGPT audit, cloud CI.

Log `coordination/sessions/M46-PERFORMANCE-C001/CLAUDE_LOG_R06_V01.md`.

**CHATGPT INDEPENDENT M46 R06 + SLOT FIDELITY SOURCE AUDIT [2026-10-16]:** `coordination/sessions/M46-PERFORMANCE-C001/CHATGPT_INDEPENDENT_R06_SLOT_REBUILD_AUDIT_V01.md`. Reviewed actual `63a0c454` R06 off-frame worker/Checking/timeout/cache code and `007cbaec` scratch-slot fidelity + latent free-slot fix, source tests and Claude logs. SOURCE_ARCHITECTURE_SCOPED_PASS; actual Godot evidence remains `CLAUDE_REPORTED_LOCAL_PASS`, not independently executed. **No established historical unsafe booster verdict:** the old mismatch is a fidelity defect under current first-progress classifier. Owner F5 "Checking..."/HUD Random visual and mobile GPU OPEN; R07 remaining FTUE/rewarded-grant 400ms synchronous pathways queued at `coordination/sessions/M46-PERFORMANCE-C001/CHATGPT_M46_R07_REMAINING_UI_LEGALITY_OFFLINE_PROMPT_V01.md`; Need-a-Hand unbudgeted unchanged. Actions hard-disabled and zero new cloud spend authorized.
**CHATGPT M46 WHOLE-MILESTONE INDEPENDENT AUDIT V04 [2026-10-21]: SOURCE_AND_ADVERSARIAL_TECHNICAL_SCOPE_PASS, OWNER_GATES_OPEN.** coordination/sessions/M46-PERFORMANCE-C001/CHATGPT_M46_WHOLE_MILESTONE_INDEPENDENT_REAUDIT_V04.md. Claude RM005+RM006 on protected source b36d48fa; final master logs at 76eac5ad in main after reviewed FF branch integration (main base 9663c44c, no force). Oracle equivalence 129 states incl DEADLOCK/UNKNOWN/WAITING, 59x59 still proof 1.3–1.7s→24–50ms measured Linux (owner desktop 2.9–3.3s pre-fix), warm Results catalog parse optimized and cold textures ~200ms one-off unchanged; Selector all118 proven in ~2.4s Linux inside 5s with 12 proven-only displayed, fair cursor on changed state; Logger internally handles source-detectable script errors but arbitrary release-template error reporting NOT_VERIFIED. Second +1 refusal reason now plus_one_used with no spend. Full p01..p22 22/22 exit0 and 45/45 suites reported by Claude on Linux cloud headless Godot4.7.2 E1/E2; ChatGPT reaudited source/tests/child+master criteria and sensitivity, DID NOT run Godot independently. 5th/6th capacity and VOID/FX/114-agent checks remain intact. OWNER_REQUIRED F5 Checking/HUD/Booster saved, phone native GPU, original Windows project parity; no CI charge. Do NOT create ad-hoc R08 for cold images or release Logger without an owner decision/new device fact.

**CHATGPT M46 FULL TWO-PASS MILESTONE REAUDIT V03 [2026-10-18; latest tested implementation e26f8205; last Claude log 80cba2a3]:** `coordination/sessions/M46-PERFORMANCE-C001/CHATGPT_M46_WHOLE_MILESTONE_INDEPENDENT_REAUDIT_V03.md`. Strict criteria on SB-M46-001..015/R02..R07/RM001..004, GitHub source + integration and 4/4 RM003,6/6 RM004, full22/22 +16 suite Claude E1/E2 assertions checked against real source; not independently run Godot. RM003 FTUE moving Selector+Tornado fast hint correctness SOURCE_PASS; RM004 4-booster ledger/timeout/partial-chips/lifecycle SOURCE_PASS scoped but deep GDScript error still labels completed refusal and 5s proof fresh worker always cursor0 (29/118,12 chips) functional availability open. Historic R05 plus new p21 source confirms one **~2.9–3.3s main-thread quiescent LOST classifier** stall (owner exact LOST semantics protected), and L1 WON synchronous 193.66ms cold/82.70ms warm terminal tick; p12 worst43.46 vs cap50.1 under local headless. Second +1 refuses without charge but blank structured reason. Frozen group V3-F01..F07. Individual RM005 `coordination/sessions/M46-PERFORMANCE-C001/CHATGPT_M46_RM005_COMPLETION_TERMINAL_FRAME_PROMPT_V01.md` + `coordination/sessions/M46-PERFORMANCE-C001/CHATGPT_M46_RM005_COMPLETION_TERMINAL_FRAME_AUDIT_CRITERIA_V01.md`, RM006 `coordination/sessions/M46-PERFORMANCE-C001/CHATGPT_M46_RM006_PROOF_DIAGNOSTIC_SELECTOR_FAIRNESS_PROMPT_V01.md` + `coordination/sessions/M46-PERFORMANCE-C001/CHATGPT_M46_RM006_PROOF_DIAGNOSTIC_SELECTOR_FAIRNESS_AUDIT_CRITERIA_V01.md`; ONE master `coordination/sessions/M46-PERFORMANCE-C001/CHATGPT_M46_MASTER_REMEDIATION_V03.md` and `coordination/sessions/M46-PERFORMANCE-C001/CHATGPT_M46_MASTER_REMEDIATION_V03_AUDIT_CRITERIA.md`. Owner `project.godot` extra local autoload untouched, F5 and phone/GPU OPEN; GitHub Actions absolutely prohibited. No historical M46 checkbox secretly closed from builder-only tests; Claude cannot edit root TASKS.

**CHATGPT M46 WHOLE-SPRINT REAUDIT V02 [2026-10-17, independent source-only; NOT a new Godot run]:** RM001/RM002 original source `0fa6ee247fe5e5f088975c0713b0386d7c94a851`, Claude final logs `793ea9cc32029a6252a0a10245fe10a49f2339bd`. Full two-pass task-by-task 001..015/R02..R07 + RM001-01..11 / RM002-01..14 criteria reconciliation and frozen sibling/interaction findings: `coordination/sessions/M46-PERFORMANCE-C001/CHATGPT_M46_FULL_SURFACE_REAUDIT_V02.md`. No production code changed in RM001/RM002. Claude E1/E2 reports **22/22 M46 whole cases exit0** (twice, latest final 487 s, 2–4 other project Godot processes), **8/8 new adversarial groups** and 23 local specialist suites, but E3 independently executed runtime NOT_RUN. M46-011 Object creation 600-idle/harness pulse and M46-014 actual 114 agents/floor90 controls are source/evidence scoped PASS; p12 retry 48.51/49.00ms near 50.1 cap remains WATCH. **V2-P1 performance problem:** FTUE L2 Selector coach copy repeatedly does moving-robot full-target scan, 23–28ms main-thread every ~2s (Claude measured, GitHub source confirms the path); **V2-P2** RM002 incomplete 59x59 illegal all-booster ledger, null detached_copy fallback, UI partial Selector keys, LOSE and cold Results profiling. **V2-P3** audit-spec correction `coordination/sessions/M46-PERFORMANCE-C001/CHATGPT_M46_RM002_AUDIT_CRITERIA_CLARIFICATION_V02.md`: timed-out/UNKNOWN fail closed is valid; distinguish worker crash vs timeout internally. **V2-P4** owner-local `project.godot` autoload differs from GitHub-main, preserved untouched, provenance OPEN. **V2-P5** p12 and p16 one-off max spikes report-only; no fabricated defect/phone fps. **V2-P6** TASKS belongs to ChatGPT (Claude correctly did not edit in RM cycle). Child RM003 `coordination/sessions/M46-PERFORMANCE-C001/CHATGPT_M46_RM003_FTUE_MOVING_COACH_PERFORMANCE_PROMPT_V01.md` + `coordination/sessions/M46-PERFORMANCE-C001/CHATGPT_M46_RM003_FTUE_MOVING_COACH_AUDIT_CRITERIA_V01.md`; child RM004 `coordination/sessions/M46-PERFORMANCE-C001/CHATGPT_M46_RM004_WHOLE_EVIDENCE_CLOSURE_PROMPT_V01.md` + `coordination/sessions/M46-PERFORMANCE-C001/CHATGPT_M46_RM004_WHOLE_EVIDENCE_CLOSURE_AUDIT_CRITERIA_V01.md`; **ONE master V02** `coordination/sessions/M46-PERFORMANCE-C001/CHATGPT_M46_MASTER_REMEDIATION_V02.md` + `coordination/sessions/M46-PERFORMANCE-C001/CHATGPT_M46_MASTER_REMEDIATION_V02_AUDIT_CRITERIA.md`. Existing technical rows are not automatically AUDITED_PASS; owner R06/R07 F5 / real device / cloud cost gates OPEN.

**CHATGPT WHOLE M46 INDEPENDENT REAUDIT [2026-10-17] — CHANGES_REQUIRED_FOR_EVIDENCE, no production defect inferred as confirmed from green local tests.** Frozen R07 implementation `76e4aff8`. Full criterion file `coordination/sessions/M46-PERFORMANCE-C001/CHATGPT_M46_FULL_MILESTONE_AUDIT_CRITERIA_V01.md`; full two-pass 001..015 + R02..R07/slot ledger/frozen F01..F08 `coordination/sessions/M46-PERFORMANCE-C001/CHATGPT_M46_FULL_SURFACE_REAUDIT_V01.md`. E3 source inspection only, NO independent Godot runtime. Main missing proofs: p11 net retained Objects ≠ per-frame allocation count, p14 gate 15 far below observed high-agent peak, no final 22/22 R07-SHA full suite (p20..p22 subset intentionally incomplete ledger), and no independent adversarial worker/economy/FTUE tests; R07 local `main.tscn` owner-dirty provenance noted. Claude previously edited TASKS contrary to locked `AUDIT_POLICY.md`; future edits only by ChatGPT. **Grouped remediation children**: RM001 `coordination/sessions/M46-PERFORMANCE-C001/CHATGPT_M46_RM001_PERFORMANCE_EVIDENCE_PROMPT_V01.md` + `CHATGPT_M46_RM001_PERFORMANCE_AUDIT_CRITERIA_V01.md`; RM002 `coordination/sessions/M46-PERFORMANCE-C001/CHATGPT_M46_RM002_BOOSTER_WORKER_UI_ADVERSARIAL_PROMPT_V01.md` + `CHATGPT_M46_RM002_BOOSTER_WORKER_UI_AUDIT_CRITERIA_V01.md`. **ONE master** `coordination/sessions/M46-PERFORMANCE-C001/CHATGPT_M46_MASTER_REMEDIATION_V01.md` and companion `CHATGPT_M46_MASTER_REMEDIATION_AUDIT_CRITERIA_V01.md`. Owner F5, device/GPU and frozen CI remain OPEN. No SB-M46 checkboxes changed based only on E1/E2.

**[2026-10-17 R07] remaining UI booster legality without a main-thread stall: LOCAL_PASS.** Prompt `CHATGPT_M46_R07_REMAINING_UI_LEGALITY_OFFLINE_PROMPT_V01.md`.
- **What changed:** rewarded-grant completion and FTUE coach booster copy now use the shared R06 off-frame seam (exact-state cache, one worker, 5 s cap, sticky cancel). No second worker, no cap or text change.
- **Rewarded grant:** granted exactly once.
  - Proven → used at once.
  - `checking` → "Booster saved!", then a no-target booster is auto-used once if proven.
  - Refusal / timeout / close / scene exit → the charge is kept.
  - Selector / Tornado are never auto-used.
- **FTUE:** `checking` makes no claim, and the copy refreshes on settle.
- **Host guard:** a host that is exiting starts no worker or proof.
- **Evidence:** new `tests/m46_r07_ui_legality.gd` covers complete, immediate, cached-timeout, Selector, cancel / reopen, timeout / retry-after-move, scene exit, L2 refusal, and FTUE checking / settle / stale / modal / exit / skip, all with 0 main-thread proofs. The old synchronous variant gives FAIL (11). 21 suites + m46 p20–p22 PASS locally.
- **Review:** `CLAUDE_PEER_REVIEW_R07_V01.md` (not ChatGPT) PASS_WITH_MINORS, minors fixed.
- **Gates:** R06 / R07 owner F5 OPEN, phone / GPU OPEN, cloud CI DEFERRED_COST_FREEZE.

Log `coordination/sessions/M46-PERFORMANCE-C001/CLAUDE_LOG_R07_V01.md`.

**[2026-10-16] booster-proof scratch slot rebuild fidelity: LOCAL_PASS.** Owner asked for this to be done in this session; it was R06 peer-review MAJOR-2 and is pre-existing since M39.
- **Defect:** `ProductionBoosterAdapter._scratch_slots_from_live` rebuilt slots with the initial count, forced ACTIVE, and restarted the placement sequence at 1.
- **Fix:** it now mirrors ProofKernel's rebuild (remaining, WAITING, live next sequence) and fails closed on a malformed slot.
- **Impact:** a distinct `CLAUDE_PEER_REVIEW` (not ChatGPT) found the old mismatch could not change a verdict under today's first-progress DeadlockClassifier gate. It is a fidelity fix, not an observed unsafe booster.
- **Also fixed:** the latent `FiveSlotBatchEngine.free_slot_if_idle` call to a nonexistent `get_remaining()`.
- **Evidence:** new `tests/m46_slot_rebuild.gd` (L1 still moments at 5 and 6 slots; FAIL before / PASS after) plus 19 booster / popup / chaos / completion suites and m46 p20–p22, all PASS.

- [x] SB-M46-003 Renderer. **[CHATGPT V04: source/headless CPU TECHNICAL_PASS; physical visual/GPU OWNER_GATE remains OPEN.]** **[2026-10-22 factory verify-close 019: technical PASS V04 (coordination/sessions/M46-PERFORMANCE-C001/CHATGPT_M46_WHOLE_MILESTONE_INDEPENDENT_REAUDIT_V04.md) + CI run 39785950814 green on 21c97572 (note: tests/m46_performance.gd is LOCAL_PASS only, not in the CI suite list); physical GPU gate closed by owner §0D.1; no on-device measurement taken in this job.]**
- [x] SB-M46-008 Effects. **[CHATGPT V04: source/headless CPU TECHNICAL_PASS; physical visual/GPU OWNER_GATE remains OPEN.]** **[2026-10-22 factory verify-close 019: technical PASS V04 (coordination/sessions/M46-PERFORMANCE-C001/CHATGPT_M46_WHOLE_MILESTONE_INDEPENDENT_REAUDIT_V04.md) + CI run 39785950814 green on 21c97572 (note: tests/m46_performance.gd is LOCAL_PASS only, not in the CI suite list); physical GPU gate closed by owner §0D.1; no on-device measurement taken in this job.]**

- [x] **SB-M46-015 — GameFeelFlow/Saltmire Spark effect-budget profiling.** **[CLAUDE_AUTONOMOUS_REVIEW 2026-10-16: LOCAL_PASS (desktop CPU, headless) in `tests/m46_performance.gd` p19; OPEN for physical phone/GPU; ChatGPT V04 source/criteria audit PASS.]** **[CHATGPT V04: implementation technical/headless profiling PASS, F5/phone/GPU owner gate OPEN.]** **[2026-10-22 factory verify-close 019: technical PASS V04 (coordination/sessions/M46-PERFORMANCE-C001/CHATGPT_M46_WHOLE_MILESTONE_INDEPENDENT_REAUDIT_V04.md) + CI run 39785950814 green on 21c97572 (note: tests/m46_performance.gd is LOCAL_PASS only, not in the CI suite list); physical GPU gate closed by owner §0D.1; no on-device measurement taken in this job.]**
  - **Setup:** the real FeedbackAdapter and the installed GFF 1.0.0 / Spark 1.0.0 autoloads, on the real Results WON path during a dense 59×59 run at 2×.
  - **FULL:** peak 8–10 owned dispatches and 6–9 Spark emitters, all expired in about 0.7 s.
  - **REDUCED:** 0 dispatches and 0 emitters.
  - **Native board FX:** within cap (24, or 8 when reduced).
  - **GFF punch_scale:** exercised on a Node2D through the same adapter, with scale restored to exactly 1 after expiry, cancel and toggle. The Results targets are Controls, so GFF is not sent there by design.
  - **Never per cell:** structural source scan, and 0 plugin events for clears without a Results event.
  - **Lifecycle:** no replay; toggle, retry and unbind leave nothing owned; settled nodes exact.
  - **Found:** the first Results show is a one-off of about 290 ms (cold asset load).

  Log `coordination/sessions/M46-PERFORMANCE-C001/CLAUDE_LOG_R02_V01.md`.

  Purpose: prove the M43-C005F budgets on worst-case SCRUBBOTS load. **Seam:** M46 Effects profiling + M31 CleaningFxLayer + feedback adapter diagnostics. **Plugin:** both. **Native/existing remains:** BoardRenderer/agents/cleaning pipeline. **Reduced Effects:** profile FULL and REDUCED separately. **Idempotency:** repeated scenes must not accumulate emitters/tweens. **Mobile/perf:** 59×59, 2× gameplay, high agent density, simultaneous Results/ceremony cases; measure frame time, allocations, node peak, memory and Spark self-free lifetime; no per-clear GFF. **Automated:** bounded active counts/lifetime leak tests. **Godot AI:** runtime performance overlay/visual sanity during stress. **Regression/gate:** M46-001..014 baseline preserved; performance audit required, no visual owner gate unless budget reduction changes accepted look.

### M47 — Android Device Testing

- [ ] SB-M47-005 Portrait.
- [ ] SB-M47-006 Safe areas.
- [ ] SB-M47-007 Easy performance.
- [ ] SB-M47-008 Medium performance.
- [ ] SB-M47-009 Hard performance.
- [ ] SB-M47-010 Very Hard/59×59 performance.
- [ ] SB-M47-011 High bot density.
- [ ] SB-M47-012 Background/foreground.
- [ ] SB-M47-013 Heat/battery extended test.
- [ ] SB-M47-014 Record device/results.

- [ ] **SB-M47-015 — Real Android FULL/REDUCED plugin-effects stress.** Purpose: validate the presentation layer on at least one lower-end and one representative Android device. **Seam:** M47 device matrix using real gameplay/Results/ceremonies. **Plugin:** both. **Native/existing remains:** touch/safe-area/portrait/performance authorities. **Reduced Effects:** compare frame pacing, thermal/battery and visual clarity against FULL. **Idempotency:** background/foreground and repeated terminal screens must not duplicate one-shots or orphan emitters. **Mobile/perf:** record FPS/frame-time spikes, memory, heat/battery and peak particles/nodes. **Automated:** device smoke log plus focused call-count diagnostics. **Godot AI:** runtime visual/device evidence where the tool can observe the running build; otherwise retain direct device captures alongside Godot AI desktop validation. **Regression/gate:** M47-001..014 remain green; independent performance audit.

### M48 — iOS Readiness

- [ ] SB-M48-001 Avoid Android-only gameplay architecture.
- [x] SB-M48-002 Document Apple toolchain requirement. `[DOC_DONE / LOCAL_PASS 2026-10-31: docs/IOS_TOOLCHAIN.md; ios-ipa.yml runs 41114924279, 41080595559, 41070827156 success; factory 073]`
- [x] SB-M48-003 Prepare iOS configuration when hardware exists. `[CONFIG_REVIEWED / LOCAL_PASS 2026-10-31: inline preset in .github/workflows/ios-ipa.yml read against Godot 4.7 iOS export options, no defect, workflow unchanged (docs/IOS_TOOLCHAIN.md); runs 41114924279, 41080595559, 41070827156 success; factory 073]`

### M49 — Responsive UI

- [ ] SB-M49-020 Validate minimum touch target. **[PARTIAL: Home/boosters measured; nav, Pause/2x and all supply targets not proven ≥88px.]**
- [ ] SB-M49-022 Confirm text containers survive localization expansion. **[OPEN: pseudo locale exists but stress/clipping/wrap acceptance not established.]**

#### M49 Player-Experience Responsive Expansion
- [ ] SB-M49-026 Validate every M43/M44 screen/popup in the complete Player-Facing Surface Visual Inventory across the full viewport matrix. **[OPEN: entire visual surface inventory has not been tested across matrix.]**
- [ ] SB-M49-027 Validate long prices, timers, event/rank labels, card/robot names and reward bundles without clipping. **[OPEN: long labels/prices/full shop layouts need measurement and visual sign-off.]**
- [ ] SB-M49-028 Validate modal stacks, keyboard/back navigation and scrollable Collection/Shop/Events/Robots screens on compact and tall devices. **V02 mobile finding [2026-10-10]: Collection scroll-down sticks on owner-tested iPhone/Samsung Android devices; Collection swipe sub-scope CODE TECH PASS on c2b1c3c7, narrow Collection swipe issue OWNER_ACCEPTED on new iPhone IPA, Android new-build retests waived by owner; wider M49 matrix remains OPEN.**
- [ ] SB-M49-029 Validate rewarded-ad/store return transitions and platform overlays do not corrupt safe-area layout. **[DEPENDENCY-GATED: provider/store returns not in tested production build.]**
- [ ] SB-M49-030 Validate notification deep links and account/cloud conflict screens enter a safe responsive destination. **[PARTIAL: deep links checked; account/cloud-conflict screen missing.]**
- [ ] SB-M49-031 Validate Next Cleanup preview, 10-node journey, ScrubBox, Weekly/First-Try tracks and Comeback Catch-Up across the full viewport/safe-area matrix without shrinking primary gameplay/results CTAs below touch standards. **[PARTIAL: Results journey baseline checked; expanded tracks/full inventory pending.]**
- [ ] SB-M49-032 Ensure 10-node journey and event tracks degrade gracefully on compact devices through scrolling/compression rules without turning them into a shipping level-select grid. **[PARTIAL: journey visible diagnostic only; compact degradation not fully asserted.]**

### M50 — Accessibility

- [x] SB-M50-002 Alternative visual slot cues if necessary. **[OWNER UPDATE: Supply/Slot-only implementation is NOT sufficient. MANDATORY new board-cell symbols on every ACTIVE coloured actual pixel at all dimensions incl 59x59; same canonical C-ID shape as Supply/Slot, no per-cell Nodes, no false glyph on CLEARED pixel, accessible magnified inspect. USER L7 F5 REAL PLAYTEST 2026-10-15. Board part IMPLEMENTED e8a7e75b (LOCAL_PASS, log `coordination/sessions/M50-BOARD-COLOR-ASSIST-C001/CLAUDE_LOG_V01.md`); OWNER F5 VISUAL APPROVED 2026-10-16 (board symbols + magnifier). Row stays open for ChatGPT independent audit / deferred cloud CI. Priority prompt `coordination/sessions/M50-BOARD-COLOR-ASSIST-C001/CHATGPT_CLAUDE_MASTER_PROMPT_V01.md`. No Actions even for verification, LOCAL_ONLY/CLOUD_CI_DEFERRED_COST_FREEZE.]** **[CLOSED 2026-10-22 (factory 016): CI run 39785950814 https://github.com/Sekiph82/Scrubbots/actions/runs/39785950814 success, head 21c97572, M50S verdict=PASS 10/10 and M50 4/4; tests/m50_color_symbols.gd s05_supply_and_slots_modes (Supply front+preview, 5/6 slots, two palettes) + s06 real L1 supply assert shape==colour; board part e8a7e75b + owner F5 2026-10-16; §0D.2 supersedes deferred CI, §0D.4 peer review.]**
- [ ] SB-M50-004 Contrast. **[SCOPED TECH PASS: Home green PLAY button keeps original body, dark NAVY label contrast 7.35:1 normal / 9.04:1 hover / 5.31:1 pressed verified in CI 38790518157. Owner look/white ▶ approval OPEN; other M50 screens' contrast coverage incomplete. Audit `coordination/sessions/DEV-GODOT-LOCAL-PLAY-C001/CHATGPT_INDEPENDENT_AUDIT_V01.md`.]**
- [ ] SB-M50-005 Reduced effects.
- [ ] SB-M50-006 Touch sizes.
- [ ] SB-M50-007 Text readability.
- [ ] SB-M50-008 Do not encode important state solely in decorative art.
- [ ] SB-M50-009 Keep labels/counts live and contrast-independent from illustration.
- [ ] SB-M50-010 Ensure generated icon families distinguishable at mobile size.
- [ ] SB-M50-011 Ensure essential gameplay understandable without decoration.

#### M50 Player-Experience Accessibility Expansion
- [ ] SB-M50-012 All M43/M44 screens support readable text scale, contrast, focus order and non-color-only state cues.
- [ ] SB-M50-013 Reward/pack/unlock ceremonies have Reduced Effects alternatives without hiding reward truth.
- [ ] SB-M50-014 Video/ad acquisition has an accessible non-video paid/earned path where product policy permits and never traps navigation.
- [ ] SB-M50-015 Event/rank/card rarity/robot-lock states have icon/text cues in addition to color.
- [ ] SB-M50-016 Screen-reader/accessibility-label strategy is defined for interactive controls before release.
- [ ] SB-M50-017 Retention surfaces must expose progress/state in text/icon form as well as animation/color; mystery reveal, pity guarantee, event reset and catch-up eligibility must remain understandable under Reduced Effects and assistive presentation.

- [ ] **SB-M50-018 — Plugin-specific motion/flash accessibility audit.** Purpose: verify GameFeelFlow/Spark never make reward/gameplay truth depend on motion and Reduced Effects is materially calmer. **Seam:** M43-C005F FULL/REDUCED matrix + canonical EffectsSettingsService. **Plugin:** both. **Native/existing remains:** text/icons/layout and current accessibility rules. **Reduced Effects:** no confetti/looping bounce/flash/camera effects; static final state appears immediately. **Idempotency:** accessibility toggle/reopen cannot replay one-shots. **Mobile/perf:** Reduced must show measurable animation/particle reduction. **Automated:** state/readability equality and no hidden-content tests. **Godot AI:** side-by-side FULL/REDUCED visual review, including rapid sequence checks for flashing. **Regression/gate:** M50-005/012/013/017; accessibility audit + owner gate if any effect is borderline.

### M51 — Localization Readiness

- [ ] SB-M51-001 Avoid hard-coded user text. **[PARTIAL: HUD booster `"%d SB"` literal converted to UiText key + UiText.num, verified in 38790518157; other hardcoded user text/full M51 not independently closed.]**
- [ ] SB-M51-003 Longer-string layouts. **[PARTIAL: pseudo-layout scan is report-only; Shop scroll/overflow not proven.]**
- [ ] SB-M51-005 Actual languages decided later. `[DESIGN GATE]` **[OWNER DESIGN GATE: actual languages not chosen.]** **[OWNER DECISION 2026-10-22, owner via factory dashboard: launch languages are English and Turkish.]**

#### M51 Player-Experience Localization Expansion
- [ ] SB-M51-006 Localize every M43/M44 surface including popup titles, booster descriptions, shop products, errors, notifications, event/rank labels and achievement copy.
- [ ] SB-M51-007 Prices supplied by platform stores remain platform-localized and are never hand-formatted as fixed currency strings.
- [ ] SB-M51-008 Validate pluralization for Hearts, Bot Parts, cards, days, attempts, ranks and time remaining. **[OPEN: pluralization not implemented/accepted.]**
- [ ] SB-M51-009 Pseudo-localize the complete Player-Facing Surface Visual Inventory before final visual closure. **[PARTIAL: l04 scan does not prove all surfaces or no clipping.]**
### M52 — Production Content Scale-Up `[CONTENT]`

M52-C001 independent audit: **AUDITED_PASS / 10 OF 10 PRODUCTION ADMITTED / OWNER_PLAYTEST_REQUIRED**.
- Audit: `coordination/sessions/M52-C001/CHATGPT_AUDIT_V01.md`
- Final matrix: `coordination/sessions/M52-C001/evidence/FIRST10_FINAL_MATRIX_V01.md`
- Owner playtest: `coordination/sessions/M52-C001/OWNER_PLAYTEST_CHECKLIST_V01.md`
- Scope note: canonical real-level Challenge / Session Load / Frustration evidence is an explicit M53 carry-forward under the newer owner decision; it was not fabricated in M52-C001.
- `SB-M52-005` remains broader M52 work: the owner-selected First 10 pack contains no rectangular production source, so this row is not falsely closed by C001.

- [ ] SB-M52-005 Validate rectangular production art.
  - 2026-10-22 note (factory 031): NOT ticked, needs rectangular PRODUCTION art which does not exist (all 10 owner images square, docs/LEVEL_ART_TECHNICAL_AUDIT.md). Pipeline rectangular capability evidence, LOCAL_PASS: m35_level_catalog PASS (24x28 rect legal, gated only by S6-C square-shell, not catalog-exposed), m36_v02_migration PASS (59x20 production-legal), m32_c002_board_independent_size PASS (86 checks, rectangles), m25_scale_evidence PASS. Conditional: when rectangular production art is supplied.

#### M52-C001 Owner Playtest Gate

Status: **PAUSED / NOT PASS at Level 2 pending R01 runtime remediation.**
Owner findings: `coordination/sessions/M52-C001/OWNER_PLAYTEST_FINDINGS_V01.md`.

#### M52-C001-R02 Dispatch-Exhausted Physical Slot Release

**M52-C001 FINAL OWNER PASS [2026-09-27]:** `coordination/sessions/M52-C001/FINAL_OWNER_ACCEPTANCE_V01.md`. First 10 production gameplay/content integration, R01 parallel-runtime remediation, R02 early-slot-release remediation and owner replay/spot-check are closed. The sequencing lock now proceeds to M53 then applicable M54 before returning to M43.

### M53 — Level QA `[QA]`

Every production level:

#### M53-C001 First 10 Level QA + Difficulty V1

**M53-C001 audit verdict:** `CHANGES_REQUIRED / DIFFICULTY CALIBRATION REQUIRED`.
Static content QA is accepted 10/10. The Stage-A D classifications are retained as diagnostics but are not yet authority for mutating production content.

#### M53-C002 Difficulty V1 Calibration / Policy Robustness

**M53-C002 audit verdict:** `AUDITED_PASS / OWNER DIFFICULTY CALIBRATION REVIEW REQUIRED`.
V2 remains `CANDIDATE_NOT_PRODUCTION_AUTHORITY`; no production content/target/model adoption is authorized yet.

#### M53-C002 Owner Calibration Review

**Owner Stage-B evidence:** `coordination/sessions/M53-C002/OWNER_DIFFICULTY_RATINGS_V01.md`
**ChatGPT reconciliation:** `coordination/sessions/M53-C002/CHATGPT_STAGE_B_RECONCILIATION_V01.md`

#### M53-C003 V2.1 Stage-B Difficulty Calibration Refinement — RESUMED AS SB-M36-012

The 2026-09-27 deferral is lifted for score-model work by the owner decision of 2026-10-26 (option B). The work is resumed and delivered by SB-M36-012 (factory 046, docs/DIFFICULTY_MODEL_V2_CALIBRATION.md). Superseded prompt kept as an artifact: `coordination/sessions/M53-C003/task_prompts/SB-M53-C003_V21_STAGE_B_CALIBRATION.md`.

**M53 First 10 closure:** static QA 10/10 PASS, owner playtest/acceptance 10/10 PASS, current difficulty-model work deferred by owner. Proceed to applicable M54 current-build regression.

### M54 — Regression Suite `[QA]`

**M54-C001 First 10 gate: CLOSED.** SB-M54-001..021 + 016A are 22/22 AUDITED_PASS after owner ruling A = 900 s / 15 min. Final closure: `coordination/sessions/M54-C001/CHATGPT_AUDIT_V02.md`. SB-M54-022..032 remain later M43+ regression work.

#### M54 Player-Experience / Meta Regression Expansion
- [ ] SB-M54-022 Results/fail/retry/Need-a-Hand third-failure regression.
- [ ] SB-M54-023 Heart/SB/booster/2x popup spend-grant-idempotency regression.
- [ ] SB-M54-024 Rewarded-ad callback success/cancel/fail/duplicate/background regression with provider mocked.
- [ ] SB-M54-025 Shop return-context and insufficient-SB regression.
- [ ] SB-M54-026 Card pack opening, duplicate/new card, Collection completion and Master Collection ceremony regression.
- [ ] SB-M54-027 Robot unlock/equip/perk persistence regression.
- [ ] SB-M54-028 Tasks/Daily/Gift Bar/notification-badge regression.
- [ ] SB-M54-029 BottomNav Events/Robots/Home/Ranks/Settings transition and modal-stack regression.
- [ ] SB-M54-030 Feature-unlock/FTUE migration and once-only coachmark regression.
- [ ] SB-M54-031 Cloud/account sync/conflict/restore regression once provider exists.
- [ ] SB-M54-032 World registry/unlock/transition regression once future world ranges are owner-defined.
- [ ] SB-M54-033 Next Cleanup / 10-Level Journey regression: exact next-content resolution, frontier fallback, no duplicate transition, cycle-boundary correctness and no level-select leakage.
- [ ] SB-M54-034 Collection retention regression: pity increment/reset/guarantee, complete-pool fallback, save/cloud continuity and First Collection Sprint reward-source idempotency.
- [ ] SB-M54-035 Daily/Event retention regression: deterministic three Scrub Orders, ScrubBox exactly-once, Weekly Event anti-replay-farm, First-Try reset semantics and Personal Best persistence.
- [ ] SB-M54-036 Comeback/notification regression: absence qualification, catch-up no-Daily-rule mutation, rollback safety, notification priority/dedup, quiet hours and proactive 24-hour cap.

- [ ] **SB-M54-037 — Presentation-plugin one-shot/fail-open regression.** Purpose: lock the core safety contract. **Seam:** Results `show_model()`/attempt key, reward rows, BasePopup ceremonies/acquisitions, terminal→Results bridge and feedback adapter. **Plugin:** both. **Native/existing remains:** all grants/navigation/save/gameplay truth. **Reduced Effects:** run same matrix in FULL/REDUCED. **Idempotency:** same Results attempt refresh, popup refresh/reopen, duplicate provider callbacks and duplicate terminal signals produce at most one eligible presentation event. **Mobile/perf:** bounded event count, no lingering nodes. **Automated:** plugin missing/disabled/throwing stubs still preserve exact authoritative outcomes. **Godot AI:** smoke real Results/pack/robot flows after automated suite. **Regression/gate:** M54-022..036 plus root suite; independent audit.
- [ ] **SB-M54-038 — GameFeelFlow/Spark runtime visual regression pack.** Purpose: make visual runtime checking reproducible rather than relying on code inspection. **Seam:** M43-C005F representative scenes/evidence harnesses using real shipping nodes/models. **Plugin:** both. **Native/existing remains:** approved art/layout. **Reduced Effects:** capture FULL, REDUCED and plugin-disabled fallback. **Idempotency:** evidence harness must not itself trigger duplicate grants/events. **Mobile/perf:** fixed bounded duration and effect budget. **Automated:** asserts final visual state restoration after effects and no orphan tweens/emitters. **Godot AI:** mandatory inspect/capture of the runtime pack for every future plugin-effect change. **Regression/gate:** visual diff/sanity + independent audit; owner gate only when visible behavior intentionally changes.

### M55 — Chaos / Long-Run QA `[QA]`

**M55 current-build core: CLOSED.** SB-M55-001..017 AUDITED_PASS in C001; timed-2x anti-rollback remediation C002 AUDITED_PASS at `023a0fc`. Audits: `coordination/sessions/M55-C001/CHATGPT_AUDIT_V01.md`, `coordination/sessions/M55-C002/CHATGPT_AUDIT_V01.md`. SB-M55-018..024 remain deferred until their M43+ surfaces exist. Separate M55 QUIESCENCE-QA-R01 is also independently TECH PASS/CLOSED at `c997ca65`, without changing leak thresholds.

#### M55 Player-Experience Chaos Expansion
- [ ] SB-M55-018 Spam open/close/purchase/reward buttons across every popup without double transition/spend/grant.
- [ ] SB-M55-019 Background/foreground during rewarded ad, store purchase, pack reveal, robot unlock and cloud sync.
- [ ] SB-M55-020 Lose three times rapidly with restart/exit mixtures and prove Need a Hand trigger remains correct.
- [ ] SB-M55-021 Repeatedly switch BottomNav destinations while badges/rewards update; prove no orphan UI/signals.
- [ ] SB-M55-022 Open huge duplicate-card inventories and Collection lists repeatedly; monitor memory growth.
- [ ] SB-M55-023 Expire Events/timed 2x/Heart timers while relevant screens are open and prove safe refresh.
- [ ] SB-M55-024 Simulate offline/online flapping during Shop/Events/Ranks/cloud/rewarded-ad surfaces without data corruption.
- [ ] **SB-M55-025 — Presentation-plugin chaos/leak test.** Purpose: stress effect cancellation and lifecycle under hostile UI/gameplay churn. **Seam:** ModalStack, Results/Home route changes, retry, background/foreground, pack/robot ceremonies, CleaningFxLayer and feedback adapter cleanup. **Plugin:** both. **Native/existing remains:** all M55 authority/lifecycle behavior. **Reduced Effects:** toggle repeatedly mid-effect and verify deterministic cleanup/no replay. **Idempotency:** rapid taps/refresh/route churn cannot multiply one-shot celebrations. **Mobile/perf:** monitor orphan Nodes, tweens, Spark emitters, memory growth and signal duplication through long sessions. **Automated:** chaos loop with adapter diagnostics and zero-authority-mutation assertions. **Godot AI:** visually inspect representative long-run route churn. **Regression/gate:** M55-018..024 plus core long-run checks; independent chaos audit.

### M56 - Analytics / Retention Calibration [DESIGN GATE -> REQUIRED BEFORE PRODUCTION TUNING]

No analytics SDK without owner approval. Event contracts may be designed and locally tested before choosing a provider. Analytics must support product calibration, not covert profiling.

- [ ] SB-M56-001 Define privacy-minimized analytics event taxonomy and version it.
- [ ] SB-M56-002 Session events: app/session start/end, foreground/background, session duration bucket.
- [ ] SB-M56-003 Level funnel: level start, first action, win/fail/exit/restart, attempt number, duration, failure progress bucket and difficulty/session-load metadata version.
- [ ] SB-M56-004 Retention calibration: first-attempt clear, attempts-to-clear, retry latency, abandonment after level and recovery-level performance.
- [ ] SB-M56-005 Assistance: Need a Hand shown/declined, recommended booster IDs, acquisition path and later clear outcome.
- [ ] SB-M56-006 Booster: charge/SB/rewarded acquisition path, activation success/fail-closed reason and level context without raw board/player-identifying data.
- [ ] SB-M56-007 Economy: aggregate SB source/sink categories, Heart starvation/refill, 2x product use, Cards Exchange and Gift/Daily reward categories.
- [ ] SB-M56-008 Collection/robots: pack opened, new-vs-duplicate counts, set completion, Master Collection, robot unlock/equip.
- [ ] SB-M56-009 Navigation: Home shortcut/BottomNav destination open, Shop entry reason and major screen completion/error states.
- [ ] SB-M56-010 Ads/store: offer, request, show, complete, skip/cancel, fail and verified reward/purchase fulfillment using provider-safe transaction identifiers.
- [ ] SB-M56-011 Events/Ranks: participation, completion/claim and rank-window engagement once their owner rules exist.
- [ ] SB-M56-012 Notifications: permission state/category opt-in, send/open/deep-link result only after privacy/platform review.
- [ ] SB-M56-013 Define dashboard metrics for D1/D7/D30 retention, level drop-off, fail-progress distribution, help conversion, booster reliance, Heart starvation and session length.
- [ ] SB-M56-014 Analytics events never grant rewards, alter difficulty, change solver truth or become a required dependency for offline gameplay.
- [ ] SB-M56-015 Define consent/age/privacy gating with M58 before production provider activation.
- [ ] SB-M56-016 Add analytics schema tests, duplicate-event guards where important and provider-offline fail-safe behavior.

#### M56 Retention V2 Measurement Additions

- [ ] SB-M56-017 Measure Next Cleanup teaser impression → CLEAN NEXT tap → next-level-start conversion, with frontier/unavailable states separated from player choice.
- [ ] SB-M56-018 Measure 10-Level Cleaning Journey progression/drop-off by cadence slot 1..10 and cycle completion without using the metric to dynamically manipulate difficulty per individual player.
- [ ] SB-M56-019 Measure Collection new-card rate, duplicate streak length, pity-trigger frequency, guarantee fulfillment and Set-1 completion level distribution; use results to tune fairness, not to sell random outcomes.
- [ ] SB-M56-020 Measure Daily Scrub Order archetype completion/time-to-complete, 3/3 completion and ScrubBox claim; reject task archetypes that create disproportionate grind or Heart waste.
- [ ] SB-M56-021 Measure Weekly Event participation/milestone completion and First-Try run depth/reset frequency separately from core campaign retention.
- [ ] SB-M56-022 Measure Comeback Catch-Up offer → return-session → three-win completion → subsequent D1/D7 return, while preserving the current Daily streak rules as a separate metric.
- [ ] SB-M56-023 Measure notification eligible/suppressed/sent/opened/deep-link outcomes with category and dedup reason; do not optimize by increasing push frequency beyond the owner cap or by using guilt/urgency copy.

### M57 - Monetization / Rewarded Ads / Store Products [OWNER-LOCKED SCOPE, IMPLEMENTATION GATED BY PROVIDER DECISION]

Economy V1 soft-currency/Hearts/booster/2x rules are already owner-locked. The owner has additionally required rewarded-video acquisition surfaces for Hearts and boosters. Provider choice, cash prices, ad frequency/cooldowns and regional availability remain tuning/provider decisions and must be data-driven.

- [ ] SB-M57-001 Choose/approve rewarded-ad and IAP provider/platform architecture; no SDK before owner approval. **[OWNER DECISION 2026-10-22, owner via factory dashboard: Ads: Google AdMob (single SDK). 1) A continuously rotating banner at the bottom of every screen (the existing ad band area); it never overlaps the game board. 2) Full-screen interstitial ad: once every 5 plays, between levels, never during gameplay. 3) Rewarded video: only if the player chooses, in exchange for a reward. IAP: Google Play Billing (Android) + Apple StoreKit (iOS). What counts as a play (owner in chat 2026-10-22): any finished level, win or loss.]**
- [ ] SB-M57-002 Define rewarded-ad placement IDs separately for Heart +1, booster acquisition and any later approved placement.
- [ ] SB-M57-003 Rewarded Heart path grants exactly +1 Heart after a verified completed reward callback only.
- [ ] SB-M57-004 Rewarded +1 Slot path grants exactly one canonical charge/use entitlement after verified completion.
- [ ] SB-M57-005 Rewarded Random path grants exactly one canonical charge/use entitlement after verified completion.
- [ ] SB-M57-006 Rewarded Selector path grants exactly one canonical charge/use entitlement after verified completion.
- [ ] SB-M57-007 Rewarded Tornado path grants exactly one canonical charge/use entitlement after verified completion.
- [ ] SB-M57-008 Need a Hand recommendations reuse the same rewarded acquisition authority; they do not create hidden extra reward rules.
- [ ] SB-M57-009 Configure per-placement availability/frequency/cooldown/cap server-side or versioned data after owner tuning; never bury hardcoded ad pressure inside popup code.
- [ ] SB-M57-010 Ad unavailable/loading/fail/skip states grant nothing and always leave a usable non-broken UI.
- [ ] SB-M57-011 App background/kill/relaunch during an ad cannot duplicate a reward.
- [ ] SB-M57-012 Define Scrub Bucks real-money packs, localized store product IDs and value ladder in an owner decision before publishing cash prices. **[OWNER DECISION 2026-10-22, owner via factory dashboard: 5 packs: $0.99 → 100, $4.99 → 550, $9.99 → 1200, $19.99 → 2600, $49.99 → 7000. Product IDs follow the pattern scrubbucks_100, scrubbucks_550, … The amounts may be adjusted after the M56 economy simulation.]**
- [ ] SB-M57-013 Define No Ads product and exactly which ad surfaces it removes; rewarded ads requested voluntarily by the player must follow the owner-approved No Ads policy. **[OWNER DECISION 2026-10-22, owner via factory dashboard: No Ads is a one-time $4.99 purchase; it removes the bottom banner and the interstitial ads shown every 5 plays. Rewarded videos stay.]**
- [ ] SB-M57-014 Implement purchase request, pending, success, cancel, failure, restore and already-owned states.
- [ ] SB-M57-015 Fulfillment is idempotent by platform transaction/receipt identity and persists across relaunch.
- [ ] SB-M57-016 Restore purchases and account/cloud reconciliation cannot duplicate SB/entitlements.
- [ ] SB-M57-017 No paid random card pack/gacha is authorized without a new explicit owner decision and platform/compliance review.
- [ ] SB-M57-018 No second premium currency is authorized.
- [ ] SB-M57-019 Do not dynamically make levels harder because a player purchases, watches ads or refuses ads.
- [ ] SB-M57-020 Do not block basic navigation/Settings/Collection/Robots behind ads.
- [ ] SB-M57-021 All real-money and ad surfaces use the M43 visual/acquisition family and M50 accessibility rules.
- [ ] SB-M57-022 Test sandbox purchases/rewarded ads on real Android and later iOS devices before release.

### M58 - Privacy / Compliance / Consent

Once external services exist:
- [ ] SB-M58-001 Third-party inventory.
- [ ] SB-M58-002 Data inventory.
- [ ] SB-M58-003 Remove unnecessary collection.
- [ ] SB-M58-004 Privacy disclosures.
- [ ] SB-M58-005 Store declarations.
- [ ] SB-M58-006 Age-rating review.
- [ ] SB-M58-007 Child-directed considerations if applicable.
- [ ] SB-M58-008 Analytics consent/legal-basis strategy by region/provider.
- [ ] SB-M58-009 Personalized/non-personalized ad consent flow where required; gameplay remains usable when personalized consent is refused.
- [ ] SB-M58-010 Notification permission/settings and deep-link privacy review.
- [ ] SB-M58-011 Account/cloud data deletion/export/sign-out requirements and recovery policy.
- [ ] SB-M58-012 Leaderboard/profile display-name privacy, reporting/blocking needs and minors policy before Ranks/social exposure. **[NOTE 2026-10-31, factory 074: the shipped RANKS tab is a personal ladder with no social exposure and does not trigger this; it stays open for any future real leaderboard.]**
- [ ] SB-M58-013 Purchase receipt/transaction identifier retention policy and least-data principle.
- [ ] SB-M58-014 Verify all consent/error/privacy screens are localization-ready and accessible.

### M59 — Build Pipeline

- [ ] SB-M59-001 Debug export.
- [ ] SB-M59-002 Release export.
- [ ] SB-M59-003 Output directories.
- [ ] SB-M59-004 Versioning.
- [ ] SB-M59-005 Build numbers.
- [ ] SB-M59-006 Run tests before release build.
- [ ] SB-M59-007 Run content validator.
- [ ] SB-M59-008 Generate Android build.
- [ ] SB-M59-009 Verify clean clone can build.

- [ ] **SB-M59-010 — Third-party presentation-addon clean-clone/release hygiene.** Purpose: ensure GameFeelFlow + Saltmire Spark are reproducible, licensed and non-editor-dependent in shipping builds. **Seam:** canonical `addons/`, `project.godot`, clean clone, debug/release export and third-party notices. **Plugin:** both. **Native/existing remains:** build pipeline and game startup. **Reduced Effects:** startup with saved reduced=true must work before any visual call. **Idempotency:** exactly one `GameFeelFlow` and one `Spark` autoload, no duplicate plugin registration. **Mobile/perf:** exclude non-shipping examples/tests/demo/editor-only baggage where safe; retain required runtime/editor plugin files and MIT license/attribution; no GdUnit runtime dependency; no Pro/Impact paid dependency. **Automated:** clean clone import, headless parse, debug/release export, autoload smoke, license-file/notices check. **Godot AI:** open clean-clone project and run a short Results + Spark/GFF smoke. **Regression/gate:** SB-M59-006/009 + release build; independent build audit, no owner visual gate.

- [ ] **SB-M59-011 — Final repository hygiene / dead-code-and-unused-asset cleanup after feature freeze.** **Execution gate:** DO NOT RUN before M43-M58 V1 feature work is closed or explicitly deferred, SB-M59-001..010 are complete, clean-clone/release export is green, and ChatGPT explicitly authorizes the cleanup cycle. **Phase 1 is DELETE-NOTHING dry-run only:** inventory the repository and classify each cleanup candidate as `KEEP`, `FUTURE-KEEP`, `EVIDENCE-KEEP`, or `DELETE-CANDIDATE`. Cross-check all open/future `TASKS.md` work, especially M43-M61, dynamic `res://` loads, scenes/resources/autoloads, tests/fixtures, validators/binders, localization/accessibility, Android/iOS/build surfaces, plugin runtime/license files, approved visual masters/provenance, remote-content/runtime contracts and release evidence. **Deletion requires a separate ChatGPT-authored prompt and strict audit after owner review of the candidate report.** Never infer unused merely from missing static references. Preserve historical audit/provenance authority unless an explicit retention rule allows removal. After any authorized deletion, require clean-clone import/build, full regression, content validation, Android release export and `git diff --check`. **Do not remove files reserved for post-launch M61/Friends or any other owner-approved future roadmap item unless that roadmap item is explicitly retired first.**

### M60 — Release

Application ID, icon, splash, portrait config, signing, release settings,
debug removal, store screenshots, final QA, tagged source commit, release
artifact validation. **Never commit signing secrets.**

Release readiness additionally requires:
- [ ] SB-M60-001 No dead Home shortcut, HUD `+`, BottomNav destination, gameplay booster, 2x control or required popup route.
- [ ] SB-M60-002 Required V1 M43 Player-Facing Surface Visual Inventory is owner-approved and production-bound.
- [ ] SB-M60-003 FTUE/feature-unlock path is playable from a fresh save without debug intervention.
- [ ] SB-M60-004 Shop/ad/IAP surfaces either function with approved providers or are cleanly feature-disabled with no broken navigation.
- [ ] SB-M60-005 Events/Ranks shipping policy is explicit; if enabled, live backend/content and privacy requirements are proven.
- [ ] SB-M60-006 Release build passes full M49-M58 player-experience, economy, device, compliance and regression gates.

### M61 - Friends / Social Comparison [POST-LAUNCH REQUIRED ROADMAP, NO CHAT/CLANS/BATTLE PASS BY DEFAULT]

This closes the previously identified social gap without expanding V1 into a chat/clan product. It is planned for a later release after account/privacy/ranks foundations are stable.

- [ ] SB-M61-001 Define owner-approved Friends scope and identity model. **[OWNER DECISION 2026-10-22, owner via factory dashboard: After launch. Friend list comes from Play Games / Game Center, no chat. Each friend can be gifted 1 Heart per day. No challenges in V1.]**
- [ ] SB-M61-002 Friend add/invite/discovery policy with privacy-safe identifiers and no unsolicited contact exposure.
- [ ] SB-M61-003 Friends list with online-agnostic progress summary and active robot/avatar presentation.
- [ ] SB-M61-004 Optional friend progress/rank comparison using the same fair Ranks metric; no pay-to-win multiplier.
- [ ] SB-M61-005 Define whether lightweight friend gifts/challenges exist before implementing; do not invent transferable premium value.
- [ ] SB-M61-006 Block/report/remove-friend and minors/privacy rules before production.
- [ ] SB-M61-007 Produce/owner-approve Friends visual master if/when the feature enters implementation.
- [ ] SB-M61-008 No global chat, clan/guild system or battle pass is implied by this milestone; each would require a separate explicit owner decision.

---

## GENERATED ASSET LIFECYCLE / DEFINITION OF DONE

- [ ] SB-UI-022 Use image generation primarily for branded illustrative assets where it adds value.
- [ ] SB-UI-023 Prefer native Godot controls/styles for interactive/dynamic UI.
- [ ] SB-UI-024 Every generated asset has traceable manifest/provenance.
- [ ] SB-UI-025 Raw generation output is never automatically production-final.
- [ ] SB-UI-026 Owner approval required before production promotion for identity/major art.
- [ ] SB-UI-027 Approved assets must be imported/configured/bound before implementation task closes.
- [ ] SB-UI-028 Never silently regenerate/overwrite approved asset.
- [ ] SB-UI-029 Do not bake dynamic text/quantities/timers/prices/state into generated images.
- [ ] SB-UI-030 Keep single-Image/ImageTexture BoardRenderer; no per-cell UI nodes.
- [ ] SB-UI-031 Validate transparency/edges/resolution/filtering/compression/memory/readability.
- [ ] SB-UI-032 Use generation credits consciously; generate by milestone need.

---

## RISK REGISTER

| ID | Risk | Severity | Mitigation |
|---|---|---|---|
| RISK-001 | Routing works technically but looks boring/confusing | CRITICAL | Owner-locked Railroad V1 + replaceable RoutingSystem + owner F6 review |
| RISK-002 | Large number of Scrubbots causes frame drops | HIGH | 59×59 density stress tests and profiling |
| RISK-003 | Legacy difficulty assumptions survive as current truth | HIGH | Difficulty V1 migration + config/doc/regression checks |
| RISK-004 | Production difficulty metadata becomes inconsistent | HIGH | Versioned Difficulty V1 evaluator/calibration |
| RISK-005 | Generic small test fixtures break after production validation | MEDIUM/HIGH | TEST fixture path/context separate from production |
| RISK-006 | Existing artwork gets silently resized/altered | HIGH | Source preservation + explicit compiler/importer + round-trip comparison |
| RISK-007 | AI agent invents missing references | HIGH | Canonical reference library/manifest |
| RISK-008 | External reference game copied too closely | HIGH | Original SCRUBBOTS rail/art/UI language; external references conceptual only |
| RISK-009 | Target race assigns same pixel to multiple Scrubbots/batches | HIGH | ReservationState + Batch Target Claim Engine atomic uniqueness tests |
| RISK-010 | Renderer creates thousands of Nodes | HIGH | Batched renderer requirement |
| RISK-011 | Desktop testing hides mobile performance issues | HIGH | Real Android profiling |
| RISK-012 | Future agent breaks explicit preload/headless compatibility | MEDIUM/HIGH | ADR-009 + regression tests |
| RISK-013 | Target ordering appears wrong because exterior/interior HOW cannot legally reach intended target | HIGH | Railroad V1 legal ingress + orthogonal interior-turn routing + exact Hazard Bot regressions |
| RISK-014 | Hidden/debug input diverges from production supply-front selection and automatic slot placement | HIGH | Front-batch-only player activation; rightmost-empty auto-placement; no hidden keyboard dispatch |
| RISK-015 | Railroad visual and routing geometry drift apart | HIGH | One canonical ScrubRail geometry source consumed by routing, connector and presentation |
| RISK-016 | Generated batch supply is mathematically impossible to finish | CRITICAL | Solvability Engine proof before production acceptance |
| RISK-017 | Scheduler spawns a robot without unique target/reservation/valid route | CRITICAL | No-target/no-reservation/no-route/no-robot transactional invariant |
| RISK-018 | Temporary WAITING is misclassified as deadlock | HIGH | Solver-backed STALLED vs DEADLOCK classification + in-flight/future-progress guards |
| RISK-019 | Multiple same-color batches fight/starve or double-claim targets | HIGH | Oldest-placement-first same-color arbitration + atomic Batch Target Claim ledger |

---

## CRITICAL PATH

```text
FOUNDATION                         DONE
↓
VARIABLE LEVEL DATA                DONE
↓
BOARDSTATE                         DONE
↓
HEADLESS CORE TESTS                DONE
↓
ENGINE/CONTENT ENVELOPE
↓
BOARD RENDERER
↓
VISUAL REFERENCE INGESTION
↓
PIXEL ART IMPORT / SEMANTIC ART PIPELINES
↓
GAMEPLAY SESSION
↓
FIVE SLOTS
↓
COLOR CANDIDATES + REACHABILITY
↓
RESERVATION
↓
TARGETSELECTOR
↓
ROUTING + SCRUBBOT RAILROAD V1             DONE (M22 V07 + OWNER ACCEPTANCE)
↓
SCRUBBOT AGENT
↓
DISPATCHER
↓
COMPLETE CLEANING LOOP
↓
REAL SCRUBBOTS ART VERTICAL SLICE             DONE (M21)
↓
BATCH SUPPLY ENGINE                           NEXT (M23)
↓
FIVE-SLOT BATCH ENGINE                        M24
↓
BATCH TARGET CLAIM ENGINE                     M25
↓
AUTO DISPATCH SCHEDULER                       M26
↓
SOLVABILITY / DEADLOCK ENGINE                 M27
↓
PRODUCTION UI / TOUCH                         M28+
↓
WIN / PROGRESSION / SAVE
↓
MOBILE PERFORMANCE
↓
CONTENT SCALE-UP
↓
RELEASE QA
```

---

## FIRST TRUE PLAYABLE TARGET

M21 achieved the first real gameplay proof using the then-current adjacent exterior ring. The current productionization target now adds the owner-approved Railroad V1 movement language without changing M21's WHAT/reservation/clear invariants:

```text
ONE REAL OWNER-APPROVED SCRUBBOTS LEVEL IMAGE
+ FIVE EMPTY BATCH SLOTS
+ 3/4/5 FIFO BATCH-SUPPLY COLUMNS
+ V1 THREE VISIBLE ROWS; FRONT ROW ONLY SELECTABLE
+ AUTOMATIC RIGHTMOST-EMPTY SLOT PLACEMENT
+ COLOR/COUNT BATCH QUOTAS WITH WAITING/RESUME
+ SAME-COLOR OLDEST-BATCH-FIRST TARGET CLAIM ARBITRATION
+ FRONT-BATCH CLICK/TAP OWNER GAMEPLAY ACTIVATION; FIVE SLOTS AUTO-FILL
+ CORRECT COLOR CANDIDATES + REACHABLE TARGET SELECTION
+ BOTTOM-MOST / LEFT-MOST PRIORITY AMONG CURRENTLY TARGETABLE MATCHING CELLS
+ SCRUBBOT RAILROAD V1 AROUND ALL FOUR SIDES
+ 2-CELL ARTWORK CLEARANCE + 1-CELL RAIL WIDTH
+ VISIBLE SLOT -> BOTTOM-RAIL CONNECTOR
+ RAIL-ONLY EXTERIOR TRAVEL
+ LEGAL RAIL INGRESS INTO OPEN/CLEARED PERIMETER SPACE
+ ORTHOGONAL INTERIOR-CORRIDOR ROUTING WITH 90-DEGREE TURNS
+ NO TARGET / NO RESERVATION / NO VALID ROUTE = NO ROBOT
+ SOLVABILITY-PROVED SUPPLY + RUNTIME DEADLOCK CLASSIFICATION
+ VALID TARGET RESERVATION
+ PIXELS BEING CLEANED TO TRANSPARENCY
+ SCRUBBOTS DISAPPEARING AFTER CLEANING
+ A COMPLETE PLAYABLE LEVEL
```

---

## RECOMMENDED PROMPT SEQUENCE

Guidance, not a hard contract. Split any prompt if scope becomes too large.
Never combine two risky architecture systems merely to save prompt count.

```text
PROMPT 01  Project Foundation                                    [DONE]
PROMPT 02  Godot Installation + Variable LevelData + BoardState
           + Headless Tests                                      [DONE]
PROMPT 03  Official Difficulty Bands + TEST vs Production        [HISTORICAL COMPAT DONE]
PROMPT 04  BoardRenderer + Variable Aspect Board Rendering       [DONE]
PROMPT 05  Visual Reference Library                              [DONE/ONGOING ASSETS]
PROMPT 06  Pixel-Art Importer + Round Trip Validation            [DONE]
PROMPT 07  Gameplay Session Core + Five-Slot Data Model          [DONE]
PROMPT 08  Color Candidates + Reservation + TargetSelector       [DONE]
PROMPT 09  RoutingSystem + Production Routing                    [DONE; exterior geometry superseded by M22 Railroad V1]
PROMPT 10  ScrubbotAgent + Dispatcher                            [DONE]
PROMPT 11  Complete Clearing Vertical Slice                      [DONE]
PROMPT 12  First Real SCRUBBOTS Artwork Playable Level           [DONE — M21 V10]
PROMPT 13  Production Slot UI + Railroad V1                      [DONE — M22 V07 + owner acceptance]
PROMPT 14  Batch Supply Engine                                      [NEXT — M23]
PROMPT 15  Five-Slot Batch Engine                                   [M24]
PROMPT 16  Batch Target Claim Engine                                [M25]
PROMPT 17  Auto Dispatch Scheduler                                  [M26]
PROMPT 18  Solvability / Deadlock Engine                            [M27]
PROMPT 19  Gameplay Screen Layout + Mobile Touch                    [M28–M29]
PROMPT 20  Win/Lose Completion Rules + Results Flow
PROMPT 21  Scrubbot Final Art + Cleaning Effects + Audio/Haptics
PROMPT 22  Level Catalog + Difficulty V1 Content Rules
PROMPT 23  Progression + Win Streak + Save System
PROMPT 24  Home + Settings + Tutorial + Navigation
PROMPT 25  Android Device Performance + Full 59×59 Stress Tests
PROMPT 26  Production Content Scale-Up + Regression + Chaos QA
PROMPT 27  Release Candidate Preparation
```

---

## NEXT IMMEDIATE MILESTONE

**M23-C001 V01 — Batch Supply Engine.** The next implementation cycle builds the real color/count supply queues before any production-screen-layout work. V1 must support owner-locked FIFO columns, three visible rows for the Hazard Bot validation path, front-row-only selection, hidden future batches, deterministic/conserved candidate generation and transactional handoff to the future Five-Slot Batch Engine. It must not weaken or rewrite the accepted M22 Railroad V1/V07 routing, TargetSelector, ReservationState, dispatcher or authenticated-clearing contracts.

M23 is followed strictly by M24 Five-Slot Batch Engine, M25 Batch Target Claim Engine, M26 Auto Dispatch Scheduler and M27 Solvability / Deadlock Engine. The previous Gameplay Screen Layout milestone has moved to M28; production UI work must not jump ahead of these five core-gameplay milestones.

---

## REMOTE CONTENT RUNTIME V01 — ACTIVE STRICT AUDIT / R01

The CP04/M15 + CP05/M16 publisher-client requirements are canonically defined in the separate Content Platform program. Do not duplicate those 26 requirement rows here. This block records only **new game-side strict-audit remediation**.

## MIGRATED LEVEL FACTORY / CONTENT PLATFORM PROGRAM — REFERENCE ONLY

As of 2026-09-14, the 224 Level Factory + Content Platform source requirements are no longer live checklist tasks in this game repository. Their canonical live tracker is:

`Sekiph82/ScrubBots-Level-Factory/TASKS.md`

The migration preserves every source requirement ID and historical meaning while preventing H!veAI from counting the same sidecar work in two repositories.

Canonical families:

- Level Factory: `SB-LF00-001..SB-LF10-008` — 112 source requirements.
- Content Pipeline: `SB-CP00-001..SB-CP09-010` — 112 source requirements.
- Canonical cross-repository mapping: `Sekiph82/ScrubBots-Level-Factory/docs/migration/LF_CP_REQUIREMENT_MAPPING_V01.md`.
- Canonical unification decision: `Sekiph82/ScrubBots-Level-Factory/docs/migration/LEVEL_FACTORY_CONTENT_PLATFORM_UNIFICATION_V01.md`.

Runtime implementation boundary remains explicit. The following requirements are tracked programmatically in the Factory repository but their implementation and audit evidence belong in this game repository when those milestones activate:

- `SB-CP04-001..014` — Godot remote content runtime.
- `SB-CP05-001..012` — offline cache / last-known-good recovery.
- `SB-CP06-004` — disabled-level runtime behavior.
- `SB-CP06-010` — single-level disable runtime test.

These ranges are references here, not live checklist rows. They must not be recreated as a duplicate game-side denominator. When runtime implementation opens, the concrete main-game implementation cycle is tracked in this repository and its accepted audit evidence is mirrored back to the canonical Factory requirement.

Existing game-owned catalog/content QA milestones such as M35, M52 and M53 remain unchanged and continue to gate what the shipping game accepts.

Migration note: removing the 224 duplicate sidecar checklist rows changes the game tracker denominator from 953 to 729 without changing the numerator. This is task-ownership normalization, not newly completed gameplay work.
