# ScrubBots | 24 Events Owner-Approved Production Plan

Status: APPROVED SCOPE / IMPLEMENTATION AND ASSETS NOT YET VERIFIED. Date: 2026-11-13.

## Authority and scope
This is a design specification, **not** an alternative project-status tracker. Only root TASKS.md records implementation state. Follow CLAUDE.md / AGENTS.md and project feature unlocks. Owner approved all 24 event concepts. ScrubBots has ONE gameplay mechanic: cleaning pixel-art images in the existing levels. Events are only metadata, objectives, progress, rewards, competition, and UI layered on normal gameplay. Never introduce separate race/arena/fighting/minigame mechanics. No event may alter the canonical real-play rules, five slots, or progression integrity.

## Rotation and availability
- Maintain 3 active events at all times. Allow 4 or 5 simultaneously on selected periods, with intentional variety and no permanent fixed trio.
- Events rotate based on configured start/end times and eligibility; avoid overlapping duplicate reward exploits. Persist claim and score ledgers idempotently; deterministic time-zone-safe scheduling, offline/resume handling, server-authoritative mechanics if competitive connected play is implemented.
- If no live multiplayer backend exists, label computer-controlled opponents honestly; don't simulate people as live players. Never fabricate a live shared global leaderboard.
- Existing feature unlock gate: Events unlock at campaign level 30; preserve feature_unlocks_v1.json policy.

## Canonical character art: strict
ALL depicted robots must be existing, owner-approved, canonical ScrubBots robot PNGs from this repository. Search and verify the canonical sources before any render. Compose existing original robot layers onto separately created environments whenever possible; text-only character recreation is not acceptable. Never invent or restyle robot identities. Exactly two arms and two hands per robot, no extra limbs, merged tools, or distortions. Character design consistency takes priority over dramatic poses.

## Visual masters and QA
- Existing repo design references (legacy, with owner-reported anatomy defects): assets/ui/generated/masters/scrubbots_events_master_v01.png and assets/ui/final/events/event_weekly_hero.png. These are **NOT APPROVED FINAL ART** and must be replaced only after QA and owner review. The newly generated ChatGPT conversation mockups are **NOT YET IN THIS REPO**, do not falsely claim availability.
- Events UI master target: portrait 1170x2532; mobile safe areas and real device verification.
- Event hero target: standalone 1024x1024 PNG, one event only. No sprite atlas, collage, grid, or printed sequence number; use proper event name as text where applicable. A production event card may use runtime-cropped art, not destructive stretching.
- 24 heroes + 24 distinct event icons + 3 race backgrounds + 2 team backgrounds + 2 reward decorations = 55 individually delivered PNG files, PLUS 1 portrait Events UI master = 56. Reuse existing art only after its visual QA passes; don't count unapproved drafts as delivered.
- Asset loading: load only art for 3–5 active event cards plus their required details; release unused textures and limit mobile memory usage.
- Every event has a 3-step tutorial: introduction (hero), gameplay linkage (actual pixel-art cleaning UI and progress illustration), and rewards (existing reward UI). 24 x 3 = 72 interactive screen STATES, not 72 newly painted full-screen PNGs. Use one shared Godot tutorial component with per-event data.
- Validation: inspect standalone PNG at native size, canonical robot identity/anatomy, actual alpha/format/dimensions, readable spelling, safe areas, event-specific identity. Real Godot UI screenshot review at 720x1520 and 1170x2532, portrait. Do not claim done for a collage crop or a synthetic robot repaint.

## 24 approved event records
| Key | Event | Family | Only permitted gameplay linkage |
|---|---|---|---|
| scrub_sprint | Scrub Sprint | competitive | Finish normal pixel-cleaning levels for race progress |
| first_brush_race | First Brush Race | competitive | First-attempt clears give race points |
| scrubbots_royale | ScrubBots Royale | competitive | Asynchronous 100-entry leaderboard from normal clears; simulated opponents explicitly labeled |
| golden_brush_championship | Golden Brush Championship | competitive | Ranked season of level-clear points |
| weekly_scrub_league | Weekly Scrub League | competitive | Weekly ranked leaderboard from normal clears |
| weekly_cleanup_challenge | Weekly Cleanup Challenge | milestone | Weekly first-clear milestones |
| perfect_first_clean | Perfect First Clean | skill | First-try clears tracked |
| sparkling_streak | Sparkling Streak | streak | Consecutive qualifying pixel-art level clears; no separate gameplay |
| stain_busters | Stain Busters | milestone | Clean cumulative pixel cells in ordinary levels |
| pure_scrub_challenge | Pure Scrub Challenge | skill | Finish qualifying levels without boosters |
| scrub_squad_tournament | Scrub Squad Tournament | team | Aggregate normal level-clear points for an opt-in team |
| clean_team_treasure | Clean Team Treasure | team | Cooperative milestones from normal clears |
| scrub_relay | Scrub Relay | team | Consecutive contribution stages from normal clears |
| mega_stain_cleanup | Mega Stain Cleanup | community | Community aggregate of pixel cells cleaned |
| scrubbys_cleanup_workshop | Scrubby's Cleanup Workshop | collection | Normal clears yield workshop tokens and rewards |
| robot_parts_recovery | Robot Parts Recovery | collection | Regular clears yield parts milestones |
| lost_card_rescue | Lost Card Rescue | collection | Normal clears collect missing-card progress |
| seasonal_scrub_festival | Seasonal Scrub Festival | seasonal | Seasonal normal-clear milestones, themed art |
| master_cleaner_quest | Master Cleaner Quest | quest | Multi-step normal-clear missions |
| scrub_season_pass | Scrub Season Pass | season | Normal clear activity unlocks reward track |
| color_scrub_rush | Color Scrub Rush | skill | Count colors/pixels cleared in ordinary stages |
| scrubbys_rescue_mission | Scrubby's Rescue Mission | quest | Clear normal stages to advance rescue story |
| world_cleanup_cup | World Cleanup Cup | competitive | Asynchronous regional cup based on normal clears |
| mystery_scrubbox_hunt | Mystery ScrubBox Hunt | collection | Normal clear milestones reveal boxes |

## Outputs and required implementation
1. A canonical character reference manifest listing approved robot PNG paths and hashes.
2. 24 individual hero files at assets/ui/final/events/heroes/<key>.png and 24 icons at assets/ui/final/events/icons/<key>.png; backgrounds and decorations as separate named PNG files.
3. Portrait Events master under assets/ui/generated/masters/ with versioned filename. Keep the legacy file until the replacement is validated; don't overwrite source references blindly.
4. Configuration-driven event definitions, rotation engine, scoring adapters to real level-completion receipts, rewards ledger, time handling, event cards, tutorial system, localization and accessibility. UI event cards must select imagery by event ID rather than a fixed weekly hero.
5. Tests for 3-5 concurrent events, weekly rotation, timezone changes, clean replay idempotency, disconnect/offline recovery, localization, unlock policy, memory ceiling and no extra gameplay modes. Exercise the actual Godot UI, show screenshots.
6. Commit/push in batches, verify remote files and update root TASKS.md; preserve unrelated work and obey repository CI policy.

## Delivery state on 2026-11-13
- Owner has approved conceptual scope and anatomy/format policy.
- No 24-event implementation, individual artworks, tutorials, or new master files are certified in this document.
- This design plan alone does not indicate TASKS.md implementation completion.
