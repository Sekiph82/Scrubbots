# SCRUBBOTS EVENTS MASTER PLAN V02 | Owner Decisions + Visual Production Addendum

**Design basis:** Owner's attached `SCRUBBOTS EVENTS MASTER PLAN V02` supplied 2026-11-13. This file preserves its specific rules, numbers, event types and tutorial concepts. **Not a live task tracker:** only root `TASKS.md` tracks status. Read `CLAUDE.md`, `AGENTS.md`, `TASKS.md` before implementation.

## Non-negotiable gameplay scope
All 24 Events launch in the FIRST game release. The player ONLY plays normal ScrubBots pixel-art CLEANING levels. Event races, tournament brackets, teams, workshops, huge dirty pictures and rescues are PROGRESS VISUALIZATIONS, not new game modes. No separate racing, match, puzzle, workshop, assembly, rescue or collection minigame. Relevant counters come solely from real normal-level gameplay: NEW levels completed; first-attempt wins; active pixels cleaned; color distribution; booster usage/non-usage; consecutive wins. Verify these signals from actual game engine / receipts before implementation.

## Exact 24 owner-approved events and tutorial themes
| Event ID | Event name | Participants | Specific goal/conditions from V02 | Tutorial visual scene from V02 |
|---|---|---|---|---|
| scrub_sprint | Scrub Sprint | 4 virtual rivals | Clear 15 NEW levels before rivals; each qualified clear advances one step | Five robots on cleanup race progress bars |
| first_brush_race | First Brush Race | 4 virtual rivals | Clear 3 or 5 levels on FIRST ATTEMPT; failed levels do not count | First-attempt successes on normal boards |
| scrubbots_royale | ScrubBots Royale | 99 virtual rivals | 100 participant / 5-stage knockout; per-stage first-attempt new-level clearance | Elimination bracket with 100 virtual entries |
| golden_brush_championship | Golden Brush Championship | 7 virtual rivals | 8 players; quarterfinal, semifinal, final; most levels cleared per round wins | 8-entry bracket from quarterfinal to final |
| weekly_scrub_league | Weekly Scrub League | 19 virtual rivals | Weekly ranking by total cleaned pixels in NEW levels | Pixel cleanup leaderboard |
| weekly_cleanup_challenge | Weekly Cleanup Challenge | solo | 3/7/12/20 NEW level milestones | Weekly milestones / rewards |
| perfect_first_clean | Perfect First Clean | solo | 3/5/10 first-attempt level wins | First-attempt count |
| sparkling_streak | Sparkling Streak | solo | 3/5/7/10 consecutive wins; losing returns event streak to last checkpoint, NOT main progression | Streak and checkpoints |
| stain_busters | Stain Busters | solo | Count qualifying active pixels cleaned in normal levels | Active pixel cleanup meter |
| pure_scrub_challenge | Pure Scrub Challenge | solo | 3/5/10 wins WITHOUT boosters | Booster-free normal level wins |
| scrub_squad_tournament | Scrub Squad Tournament | virtual teams of 10 | Team competition based on completed normal levels | Virtual robot teammates and team rankings |
| clean_team_treasure | Clean Team Treasure | virtual team of 10 | Team cleanup points unlock shared chests | Shared chest milestones |
| scrub_relay | Scrub Relay | virtual team of 5 | Sequential team-stage progress from members' normal level clears | Team relay progress visualization |
| mega_stain_cleanup | Mega Stain Cleanup | virtual team of 20 | Shared cumulative stain goal, e.g. 50,000 valid pixels; giant stained artwork is DISPLAY ONLY | Giant stained image cleaning progress |
| scrubbys_cleanup_workshop | Scrubby's Cleanup Workshop | solo | Normal cleanup levels unlock workshop reward milestones (SB, boosters), NO workshop minigame | Workshop reward path |
| robot_parts_recovery | Robot Parts Recovery | solo | Cleanup levels recover Robot Parts via normal rewards, NO assembly minigame | Recovered robot parts |
| lost_card_rescue | Lost Card Rescue | solo | Normal cleanup tasks recover Card Packs, NO card-search minigame | Recovered card packs |
| seasonal_scrub_festival | Seasonal Scrub Festival | seasonal | Halloween / Christmas / Summer Cleanup thematic normal level activity | Seasonal decoration and reward theme |
| master_cleaner_quest | Master Cleaner Quest | solo / cross-event | Complete objectives across multiple events for large reward chest | Cross-event progress overview |
| scrub_season_pass | Scrub Season Pass | seasonal | Normal level clears advance FREE seasonal reward track | Free reward track |
| color_scrub_rush | Color Scrub Rush | solo | Track cleaned pixel counts by color in ordinary gameplay | Color counters |
| scrubbys_rescue_mission | Scrubby's Rescue Mission | solo / narrative | Advance rescue story after qualifying normal level wins, NO rescue minigame | Rescue story progression |
| world_cleanup_cup | World Cleanup Cup | 20 virtual rivals | Global-style virtual ranking using normal new-level cleanup points, NOT live world leaderboard | Virtual worldwide cup rankings |
| mystery_scrubbox_hunt | Mystery ScrubBox Hunt | solo | Reach level-clear thresholds to unlock mystery ScrubBoxes | Mystery boxes unlocked by progress |

## Rotation / examples from V02
- Always show **minimum 3, maximum 5** active Events, drawn from the 24. Do not run the same permanent trio. Some days 4, special days 5.
- Rotate by explicit event start/end timestamps; do NOT terminate events merely because the day changes. Expiring events persist through their actual end time. Show upcoming events on a calendar. Keep goals and reward claims deterministic / idempotent; do not change ongoing event progress unfairly.
- Example Monday (3): Scrub Sprint; Robot Parts Recovery; Weekly Cleanup Challenge.
- Tuesday (4): Scrub Sprint; Robot Parts Recovery; Weekly Cleanup Challenge; Clean Team Treasure.
- Wednesday (4): Clean Team Treasure; Color Scrub Rush; Sparkling Streak; Weekly Cleanup Challenge.
- Thursday (3): First Brush Race; Lost Card Rescue; Scrub Season Pass.
- Friday (5): Golden Brush Championship; Mega Stain Cleanup; Scrub Season Pass; Mystery ScrubBox Hunt; Color Scrub Rush.
- Saturday (5): ScrubBots Royale; Master Cleaner Quest; Seasonal Scrub Festival; Scrub Season Pass; Mega Stain Cleanup.
- Sunday (3): World Cleanup Cup; Perfect First Clean; Scrubby's Rescue Mission.
- **FINAL OWNER DECISION (2026-11-13): EVENTS UNLOCK AT LEVEL 30.** This explicitly supersedes the original attached V02 sentence proposing Level 0001 access. All 24 events must exist in the first release, but the Events feature, entry points, cards, calendar, tutorial launches, JOIN and CLAIM become accessible only when the canonical campaign frontier reaches **Level 30**, consistently across fresh/existing/imported/debug profiles. Maintain the existing authoritative `data/config/feature_unlocks_v1.json` `unlocks.events = 30` and `AGENTS.md` gate; never introduce independent hard-coded unlock values. At Levels 1–29, respect the game's existing locked-feature presentation; no event rewards/claims or deep-link bypass. Level 30 and higher may access the 3–5 active-event rotation. No retrospective pre-unlock progress or rewards unless separately authorized.
- Existing booster gates Level 6 / 11 / 16 / 21 stay; Event objectives before unlock must not require unavailable boosters.

## Competitors and friends
- Start with VIRTUAL RIVALS and virtual team members. Reuse the existing 10 approved robot portraits for avatars; vary names, badges and frames, not robot identities. 99 virtual rivals in Royale does NOT require 99 different robots.
- Label all bots openly as computer-controlled. Do not portray simulated rankings as real users.
- Never accelerate rivals based on spending / purchases. Work offline in the first version. Preserve separate schemas for future real friend records; real cross-device competitions require server verification.

## Tutorials: exact common system
- 24 events x 3 steps = **72 distinct SCREEN STATES**, implemented via one shared Godot tutorial component, NOT 72 full-screen raster images.
- Screen 1: event emblem, original Scrubby or another approved robot, event hero and event objective.
- Screen 2: actual normal ScrubBots pixel-art board, how real cleared levels affect event progress, event's special qualification rule, progress/rival indicator.
- Screen 3: event milestones / reward path, earned reward types, timer and START button.
- All 24 tutorial visual topics are listed in the event table. Do not copy other games' copyrighted character designs or visual assets.

## Visual production after owner's later corrections
- The old repo `assets/ui/generated/masters/scrubbots_events_master_v01.png` and `assets/ui/final/events/event_weekly_hero.png` are legacy references with owner-reported incorrect hands/arms; not final or quality-approved.
- Use ONLY canonical, OWNER-APPROVED robot images from this repository as source pixels. Create a named SHA-256 manifest of originals. Composite canonical character PNGs directly into separately rendered scenes when feasible. Never synthesize substitute robots. Exactly two arms and two hands per robot; no fused props, extra limbs or anatomy drift.
- Each event Hero is ONE **standalone** 1024x1024 PNG (including a new Weekly Cleanup Challenge Hero). No printed event numbers, no collage/grid/atlas, no cropping one big AI poster into fake individual assets. A card may display the art at a responsive crop without permanently damaging the original.
- Add 24 separate event emblem/icon PNGs, 3 racing backgrounds, 2 team backgrounds, 2 reward-road decorations: **24+24+7=55 PNGs**. Add ONE portrait 1170x2532 Events UI master: total **56** distinct approved production files. Treat 56 as target budget, not proof of existing deliverables; use existing approved visuals only after real inspection. ZIP / ChatGPT mockups outside repo must never be claimed as committed.
- Production directories: `assets/ui/final/events/heroes/<event_id>.png`, `assets/ui/final/events/icons/<event_id>.png`, new `backgrounds/` and `decorations/` as appropriate; final portrait master under `assets/ui/generated/masters/`.
- `ui_event_card.gd` currently has a legacy fixed weekly hero; audit and change to event-key-driven art with only active 3–5 cards/textures loaded; resource-release tests for mobile.
- QA each file as one independent PNG: resolution / signature / name / title / zero event numbering / robot source identity / limbs / clean readable text / actual phone layouts / screenshots. Do not call unapproved designs FINAL.

## Rewards and implementation obligations
- Event rewards must use existing SB / Robot Parts / Card Packs / boosters and current RewardGrantService. Define exact quantities only AFTER simulating maximum simultaneous 5 events, to avoid inflation / exploits.
- Implement 24 data definitions + explicit event duration / rotation frequency / goals / bot behavior / win-loss / reward table / localized tutorial text, and verify against existing economy; V02 did NOT specify all these values, so don't manufacture owner-approved amounts.
- Tests: 3–5 concurrency, expiry without day-cutover, persisted progress, no level double-counting, first-attempt semantics, verified pixel/color counts, booster-free wins, virtual rival ethics, offline operation, event payouts idempotency, unlock conflict gated, tutorials and every unique event visual.
- Open real Godot app at 720x1520 and 1170x2532, capture human-reviewable screenshots; don't label ready from tests alone.
- Commit / push / verify GitHub assets and code in manageable batches. Preserve unrelated work. Keep root TASKS.md authoritative; other docs are specifications only.

## Final owner resolution (2026-11-13)
Events unlock at **Level 30**, not Level 1. This is an explicit post-V02 owner amendment and is authoritative over any contrary V02 statement, earlier summary, tutorial proposal or generated mockup. Regression coverage must check level 29 blocked, level 30 unlocked, direct entry, card/calendar/tutorial/deep link, JOIN/CLAIM, and migrated or imported saves. Do not change feature gates for any other feature.

## Delivery truth
As of 2026-11-13 the original V02 plan is now incorporated in this spec, but this document DOES NOT certify that 24 events, image assets, replacement masters, tutorials or implementation have been delivered.
