STATUS: READY

# Build: 171-events-v02 (SB-EV02-002..014)

## Summary
The branch `factory/171-events-v02` ships the 24 V02 events as runtime code. They run only on the normal pixel-art cleaning gameplay and unlock at Level 30.

### Art (stage 1)
- The 56 Codex PNGs from `C:/Users/sekip/Desktop/ScrubBots Events PNG/` (read only) are intake'd and optimized, with a manifest:
  - 24 heroes, 1024 to 768.
  - 24 icons, 512 to 256.
  - 5 backgrounds, 1024 to 768.
  - 2 decorations, unchanged.
  - The 1170x2532 master, full size, in `assets/ui/generated/masters/scrubbots_events_master_v02.png` (export-excluded).
- `assets/ui/final/events/EVENTS_V02_ASSET_MANIFEST.json` holds the event id, source path, source sha256/size and output sha256/size for each asset.
- No decoration is missing. The plan's 7 shared assets are 3 race backgrounds + 2 team backgrounds + 2 reward decorations = 5 + 2.
- The 172 tutorial storyboard PNGs are hashed in the manifest but not shipped (see Decisions).

### Runtime (EV02-002/003/004/005/006/007)
New service: `scripts/economy/events_v02_service.gd`, with config `data/config/events_v02_runtime.json`.
- **Definitions:** cross-checked against `events_v02_catalog.json` (ids, metrics). The whole config fails closed on a metric mismatch, a missing event or an unapproved currency.
- **Schedule:** a deterministic UTC lane plan, instance id `<event_id>:<cycle>`, 28-day cycle.
  - 3..5 events active at every instant (72h at 3, 408h at 4, 192h at 5 per cycle).
  - All 24 types once per cycle.
  - Never ended early. A joined instance's window and progress are saved, so a config change cannot move or erase them.
- **Lifecycle:** upcoming / active / claimable (72h grace) / ended / expired.
- **Clock:** a high-water mark, so a clock moved back never reopens a window or rewinds rivals.
- **Receipts:** `ProductionGameplayHost._event_receipt` builds one at the committed progression terminal:
  - first clear, true first attempt (`PlayerRecords`), boosters actually used;
  - CLEARED artwork pixels by canonical C-id, reconciled to the total, VOID excluded;
  - id `L<level>:a<attempt>`, deduped.
  - The Events gate is captured before the win commits, so the L29 win that unlocks Events is not credited.
  - JOIN is required, so there are no retroactive awards.
- **Per-kind rules:** milestones, streak with event-only checkpoint rollback, color counters, cross-event quest, race place, ranking, Royale stages, 8-entrant bracket (8 to 4 to 2 to 1), team milestones, team vs team.
- **Rivals and teammates:** deterministic and computer-controlled.
  - Seeded by instance + entrant; casual / average / strong / expert profiles.
  - Canonical robot avatars and unique names, always shown with a CPU label.
  - A pure function of time, so they are stable offline and cannot be moved by player play or spending.
- **Rewards:**
  - Only the six existing types, via `RewardGrantService.grant("event:<iid>:<rid>:rp1")`.
  - `ProductionActionFacade.claim_event_reward` saves before acknowledging and rolls back if the save fails.
  - Claims are enabled only while the worst-case cycle total (every event at its best result) fits `cycle_reward_cap`.
- **Wiring:** a new `events_v02` economy save section (absent = fresh, present = strict), and facade `join_event` / `claim_event_reward` / `mark_event_tutorial_seen`, all gated on the `events` unlock.

### UI (EV02-008/009/013)
- `scripts/ui/events/events_v02_ui.gd`:
  - **Events page:** active cards show hero art chosen by event id, countdown, family / participants and progress. Upcoming previews show the icon only, so only the 3..5 live heroes are resident; textures are plain `load()`s released with the popup.
  - **Details:** goal, CPU note, live standings / stages / bracket / team / colors, reward rows with CLAIM, JOIN, HOW IT WORKS.
  - Missing art falls back to an `art_fallback` meta.
- `scripts/ui/events/event_tutorial.gd`: ONE reusable 3-step coachmark component, 24 x 3 = 72 data-driven states, auto-shown on the first visit.
  - Step 1: hero + emblem + canonical host robot + goal.
  - Step 2: a REAL campaign level board (BoardRenderer on Level 4's data, half cleaned, BG01 behind), plus "+gain", the event's live diagram and its own target track.
  - Step 3: reward path + time left + JOIN.
  - The lit block has a gold frame and the others dim; the bubble is cream with a blue border and a pointer.
  - Reduced Effects: the meter jumps instead of animating.
- EN + TR strings: 121 `EV2_*` keys each, with Turkish event names (round 0b).
- The Home EVENTS badge counts V02 claimables. Wired in `profile_screens.gd` and `home_badges.gd`.

### Files
- New: `data/config/events_v02_runtime.json`, `scripts/economy/events_v02_service.gd`, `scripts/ui/events/events_v02_ui.gd`, `scripts/ui/events/event_tutorial.gd`, `tests/ev02_events_v02.gd`, `tests/ev02_events_ui.gd`, `tests/tools/ev02_events_capture.gd`, `assets/ui/final/events/{heroes,icons,backgrounds,decorations}/*` + `.import` + manifest, `assets/ui/generated/masters/scrubbots_events_master_v02.png`.
- Changed: `scripts/economy/economy_services.gd`, `scripts/economy/production_action_facade.gd`, `scripts/gameplay/runtime/production_gameplay_host.gd`, `scripts/ui/profile/profile_screens.gd`, `scripts/ui/home/home_badges.gd`, `scripts/ui/ui_text.gd`, `scripts/ui/ui_text_tr.gd`, `docs/ACCESSIBILITY.md`.
- Tests adjusted for V02: `tests/m43_master_c010_meta.gd` (the V1 config still schedules nothing; V02 now lists), `tests/m55_player_chaos.gd` (V1 fixture isolated from V02), `tests/m50_accessibility_audit.gd` (ledger row), `tests/m43_c005f_phase6_unlock_feel.gd` (ignores the wall-clock `hw`, as it already does for `speed`).

## Acceptance criteria
1. [x] **Art intake with manifest, mobile size, missing-asset handling.** `bbc2b06e`: 56 assets, manifest with sha256 + source path + event id, 172 storyboard hashes. `ev02_events_v02` e01 checks hero + icon for all 24 ids. `ev02_events_ui` u03 checks no `art_fallback` on live cards. `m22_026_texture_budget` PASS.
2. [x] **EV02-002: 24 definitions + instance ids, 3..5 rotation with fairness, never early, upcoming/ended continuity.** `ev02_events_v02`:
   - e01: catalog ids, metrics, durations, participants and owner numbers 15 / 3 or 5 / 3,7,12,20 / 3,5,10 / 3,5,7,10 / 3,5,10.
   - e02: every hour (and :37) of 3 cycles, min 3 / max 5, distribution {3, 4, 5}; each cycle has all 24 exactly once; at least 2 families at every instant.
   - e03: upcoming / active / claimable / ended / expired; a config change keeps the joined window and progress.
3. [x] **EV02-004: Level 30 everywhere.**
   - `ev02_events_ui` u01, frontiers 1 / 29 / 30: feature gate, deep link, details, tutorial, join, claim and tutorial-seen write all refused below 30 and allowed at 30.
   - A pre-V02 save (section stripped) loads fresh and unlocked at 30.
   - The L29 win sends no receipt.
   - `m60_release_gates` g005 PASS; `m44_unlock_gate` PASS.
4. [x] **EV02-003/006: receipt telemetry, eligibility and milestone semantics, dedupe, save/restart/migration.**
   - `ev02_events_v02` e06, the 24-event matrix: first-try boosterless win / retry win / booster win / loss give exact per-metric increments; a replayed receipt, locked Events and an unreconciled receipt add nothing; nothing counts before JOIN.
   - e07: streak 6 wins + loss = 5 (best 6); color targets; quest dedupe; race place; Royale 100 entrants / 5 stages, survivors [99, 93, 68, 43, 24]; bracket; ranking sizes; team sizes.
   - e10: JSON round trip; receipt ids survive a reload; strict import.
   - `ev02_events_ui` u02, real host: a fully cleaned L30 gives artwork pixels == the sum by palette C-id; exactly one receipt `L30:a1`; a duplicate terminal and a replay add nothing.
5. [x] **EV02-005: deterministic transparent rivals and teams.** `ev02_events_v02` e05 (offline / reload give identical standings; monotonic rival scores; clock rollback ignored) and e08 (identical across services; 99 unique names; canonical robots; per-instance seeds; player wins and booster use never move rivals; no store / wallet input). UI rows end with "CPU", and the CPU note is shown on rival/team events (u04).
6. [x] **EV02-007: existing currencies only, idempotent RewardGrantService, stacking cap.** `ev02_events_v02` e09:
   - Worst case per cycle: SB 6275/7000, Bot Parts 6/8, Standard packs 16/18, Premium 4/4, random boosters 10/12, selected boosters 4/5.
   - Simulated players at 2 / 10 / 40 levels per day joining everything stay under the cap (casual 2450 SB, high volume 6275 SB).
   - A real `RewardGrantService` pays once; a save that lost its claim mark never pays twice.
   - An over-cap table switches claims off.
   - `ev02_events_ui` u04: CLAIM pays 50 SB once.
7. [x] **EV02-008/009/013: native page, cards, details per id, one tutorial with 72 states on a real board, EN/TR, safe areas, Reduced Effects, art fallbacks.** `ev02_events_ui`:
   - u03: 4 and 5 active cards == the service count; upcoming icon-only; the first visit opens the tutorial once.
   - u04: details for all 24.
   - u05: 72/72 EN and 72/72 TR states (BoardRenderer on the real level, half cleaned, gain, meter, reward path, JOIN); 72 distinct EN states; 72/72 TR differ; Reduced meter not animated.
   - `m51_localization_readiness`, `m50_accessibility_audit`, `m49_responsive_matrix` PASS.
8. [x] **EV02-014: tests in place; no extra gameplay.** `ev02_events_ui` u06: the event scripts reference no dispatch / targeting / routing / solver / level catalog; the tutorial clears cells only on its own BoardState copy; the host receipt only reads the board. Level data is unchanged (no `data/levels` diff).
9. [x] **GPU captures EN/TR: Events page, 3 details, 3 tutorials.** 56 PNGs in `C:/Users/sekip/Desktop/ScrubBots Events Captures/171-events-v02/`, at 720x1520 and 1170x2532, EN + TR, `EV02_CAPTURES CLEAN (0 rejected)` (frame in the viewport and `text_fits`):
   - Events page top + scrolled.
   - Details for the first three live events by family: Mega Stain Cleanup, Scrub Season Pass, Weekly Cleanup Challenge.
   - All 3 steps of Golden Brush Championship, Color Scrub Rush and Sparkling Streak.

## Validation
All LOCAL_PASS with Godot 4.7.2 (`Godot_v4.7.2-stable_win64_console.exe`). One-off `--import`; its line-ending churn was re-checked out and its sidecars deleted.
- `tests/ev02_events_v02.gd`: `EV02 events service evidence: PASS (10/10 cases, 0 fail)`, exit 0, diag 0, 204 assertions.
- `tests/ev02_events_ui.gd`: `EV02 events UI evidence: PASS (6/6 cases, 0 fail)`, exit 0, diag 0.
- `python tools/run_suites.py`, the full workflow list of 96 suites (before the rebase): 95/96 PASS. The one failure, `m43_c005f_phase6_unlock_feel` (the authority snapshot saw the new wall-clock `events_v02.hw`), is fixed in `c75e94ea` and its rerun PASSes (8/8). Effective 96/96.
- After `git pull --rebase origin main` (no conflicts; main had jobs 169/172/173), all PASS with exit 0 and diag 0: `ev02_events_v02` 10/10, `ev02_events_ui` 6/6, `m42_home`, `m43_c005f_phase6_unlock_feel` 8/8, `m51_localization_readiness` 8/8. TR captures retaken: CLEAN, 0 rejected.
- Not in the workflow list, run directly: `m22_026_texture_budget` PASS; `m55_player_chaos` PASS (its 3 diag lines are that suite's own injected FaultySpark `explode` throws).
- `git diff --check` clean. `git status --porcelain` is empty at the end.

## Decisions (open points in the plan, conservative choices; owner pre-approves factory recommendations)
- **Claims enabled** behind the cap validator, rather than preview only. It is one switch, `claims_enabled` in the runtime config; setting it to false gives preview-only.
- **Reward amounts, durations (the catalog proposals), rotation lanes, goals marked TBD, rival rates, tie-breaks, 72h claim grace then forfeit** are all labelled factory proposals in the config `proposal_status`.
- **JOIN required:** progress counts only after joining, inside the window.
- **Pixel metrics** count only won first clears of new levels, so retries cannot farm pixels.
- **Royale** uses cumulative first-try-win stage thresholds 2/5/9/14/20, with survivors shown per stage.
- **Bracket:** three equal rounds; a tie goes to whoever reached the score first; the player never wins 0-0.
- **Ranking ties:** the rival who reached the score first ranks ahead.
- **Master Cleaner Quest:** an objective is another joined event earning a reward step (rank-only events: scoring in it). Objectives 2 and 4.
- **Seasonal variant** by start month: Sep-Nov Halloween, Dec-Feb Christmas, Mar-Aug Summer.
- **Color Scrub Rush:** 3 target colors drawn from all 16, 300 px each.
- **Team events** need the player's own contribution (1 or 2) before any team reward.
- **Clock:** high-water. If a device clock once jumps far forward, events stay ahead until real time catches up (anti-tamper over convenience).
- **Storyboards:** the 172 tutorial PNGs are NOT in the APK (227 MB; the plan asks for 72 native states). The native tutorial uses their coachmark grammar.
- **Heroes** are 768 px lossless: about 22 MB of sources, the largest new APK contributor. Further shrinking is possible if the APK budget needs it.
- **Workflow not edited:** the coordinator asked for it in round 0b, but the edit to `.github/workflows/android-family-first10.yml` was refused by the session's permission classifier and was not worked around. Still to do at merge: add `ev02_events_v02` (guard `EV02 events service evidence: PASS (10/10 cases, 0 fail)`) and `ev02_events_ui` (guard `EV02 events UI evidence: PASS (6/6 cases, 0 fail)`) to the validate loop in `.github/workflows/android-family-first10.yml`, and close the SB-EV02-002..009/013/014 rows in TASKS.md (not edited, as instructed).

## Known limits
- At the capture instant no competitive event was live, so the competitive standings rows were not GPU-captured. They are test-covered (u04), and the row wrap fix (place/score labels no longer autowrap) was made after the first capture.
- Rivals use uniform random gaps (no day/night rhythm), marked `ponytail:` in code.

## Log
### Round 0
Five commits on `factory/171-events-v02`:
1. `bd989de1` art intake + manifest.
2. `0b25c385` runtime service, config, host receipts, facade, economy section, service suite.
3. `5db61be1` Events page, details, tutorial, EN/TR, UI suite, capture tool, two legacy tests adjusted.
4. `a48165f0` Reduced Effects ledger row.
5. `c75e94ea` phase6 authority snapshot ignores the `hw` wall clock.

Hashes are after the rebase onto origin/main `b11a54fe`.
Visual review of the captures led to three fixes before the final capture: standings rows wrapping character by character, cleared board cells showing cream instead of BG01, and TR dotted-I casing of the English event names.

### Round 0b (coordinator requests)
- **Workflow suites + guards:** attempted; the edit was refused by the permission classifier. Left for the coordinator / merge (see Decisions).
- **Rebase:** `git pull --rebase origin main` applied cleanly; suites rerun as listed in Validation.
- **TR capture fix:** `76f632b2`.
  - The HUD showed "1,000" / "FULL" because the capture set `UiText.locale` after boot. The tool now saves the language choice (`set_language`) in its fixture save, so the whole app boots in TR ("1.000" / "DOLU").
  - The event names now have Turkish UiText copy. The plan and catalog give only English names, so these are factory proposals:

    | Event | Turkish name |
    |---|---|
    | Scrub Sprint | Temizlik Sprinti |
    | First Brush Race | İlk Fırça Yarışı |
    | ScrubBots Royale | ScrubBots Eleme Turnuvası |
    | Golden Brush Championship | Altın Fırça Şampiyonası |
    | Weekly Scrub League | Haftalık Temizlik Ligi |
    | Weekly Cleanup Challenge | Haftalık Temizlik Meydan Okuması |
    | Perfect First Clean | Kusursuz İlk Temizlik |
    | Sparkling Streak | Parıltılı Seri |
    | Stain Busters | Leke Avcıları |
    | Pure Scrub Challenge | Saf Temizlik Meydan Okuması |
    | Scrub Squad Tournament | Temizlik Takımı Turnuvası |
    | Clean Team Treasure | Temiz Takım Hazinesi |
    | Scrub Relay | Temizlik Bayrak Yarışı |
    | Mega Stain Cleanup | Dev Leke Temizliği |
    | Scrubby's Cleanup Workshop | Scrubby'nin Temizlik Atölyesi |
    | Robot Parts Recovery | Robot Parçası Kurtarma |
    | Lost Card Rescue | Kayıp Kart Kurtarma |
    | Seasonal Scrub Festival | Sezonluk Temizlik Festivali |
    | Master Cleaner Quest | Usta Temizlikçi Görevi |
    | Scrub Season Pass | Temizlik Sezon Kartı |
    | Color Scrub Rush | Renkli Temizlik Hücumu |
    | Scrubby's Rescue Mission | Scrubby'nin Kurtarma Görevi |
    | World Cleanup Cup | Dünya Temizlik Kupası |
    | Mystery ScrubBox Hunt | Gizemli ScrubBox Avı |
  - The 16 palette color names are now UiText keys `EV2_COLOR_C01..C16`, EN = palette names, TR: Turuncu Kırmızı, Turuncu, Sarı, Yeşil, Açık Turkuaz, Açık Mavi, Mavi, Lacivert, Lavanta Mavisi, Pembe, Kahverengi, Açık Sarı, Açık Gri, Koyu Gri, Beyaz, Siyah.
  - Titles use `UiText.caps` again, correct for Turkish now that the names are Turkish.
  - Remaining English in TR, by design: the brand words "ScrubBots" / "ScrubBox", robot names, and "SB".

Not pushed. No `git stash` or `git clean` used.
