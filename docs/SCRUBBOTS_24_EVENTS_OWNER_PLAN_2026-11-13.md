# SCRUBBOTS | EVENTS V02 IMPLEMENTATION BIBLE

## LATEST OWNER IMAGE-DELIVERY POLICY (2026-11-13)
The *current Codex visual-only assignment* produces 228 independent PNGs (56 base visuals + 172 tutorial walkthroughs) saved exclusively in the LOCAL Windows folder `C:\Users\sekip\Desktop\ScrubBots Events PNG\` (heroes/, icons/, backgrounds/, decorations/, masters/). **No generated image may be written, committed, or pushed to GitHub by Codex.** All older passages of this document about putting Codex-generated art in the repository are superseded for the current art assignment. The repository paths mentioned elsewhere are potential future integration targets, NOT the destination for the current art handoff. This master specification stays on GitHub for future Claude implementation when explicitly requested.


**Owner-approved source:** SCRUBBOTS EVENTS MASTER PLAN V02, shared 2026-11-13; updated with later owner decisions. **This is the single detailed implementation specification for Claude/Codex to read.** It is *not* a live status tracker. Root `TASKS.md` remains the only tracker, per `CLAUDE.md` §0D.

> **OWNER SCOPE CLARIFICATION (2026-11-13):** This is the COMPLETE, persistent **future Claude implementation reference** for the 24 Events. The owner's request to write and commit this specification is DOCUMENTATION ONLY. It does **not** authorize Codex to implement gameplay, event engines, rewards, tutorial code, or other software while working on the separate **visual-production-only** assignment. A future explicit instruction such as "Claude, implement the Events using this master plan" is the trigger for actual implementation. Do not conflate reference-spec authoring, Codex art production, and future Claude code work.

> **Source fidelity:** Confirmed owner V02 requirements include 24 specific event concepts, solo/team/rival participant counts, milestones, one existing pixel-art cleaning mode, 3–5 rotating active events and 72 tutorial UI states. The later owner amendment requires **Level 30** unlock. Values absent from owner V02, including precise reward amounts, some goals, duration selections and rival speeds, are labeled proposals or TBD; never represent them as previously approved numeric decisions.

## Start here: precedence
1. Newest explicit owner decision overrides older design statements. Events unlock at **Level 30**, not the V02 draft's Level 1. `data/config/feature_unlocks_v1.json` controls this, do not duplicate the value in UI code.
2. This implementation bible specifies every event's owner-approved identity, count, rules and tutorial theme. The owner V02 is preserved in `docs/SCRUBBOTS_24_EVENTS_OWNER_PLAN_2026-11-13.md`. If an event detail disagrees, flag the exact disagreement before changing production rules, but continue unrelated tasks.
3. Do not invent owner-approved reward *amounts*, durations, rivals' statistical performance, selection weights, tie breakers, or unresolved thresholds. These fields are **TBD** and require modelled defaults, explicit labeled proposals and objective tests. Propose and simulate safe economy defaults without claiming historic owner authorization.
4. The normal pixel-art cleaning level is the ONLY gameplay. Events are secondary progress/rewards/UI effects, never new gameplay, independent board, race or puzzle.
5. 24 events must be implemented in the first release and rotate: **3 active minimum, 5 active maximum**. Events only visible/accessible after L30. Virtual opponents and teams are explicitly labeled as computer-controlled, never fabricated as human competition.

## Shared engineering contract
- Build event instances from stable `event_id`, `instance_id`, `start_at`, `end_at`, `status`, `schema_version`, difficulty/goal config, reward table, qualification rules, local progress, claimed milestone IDs, deterministic virtual profiles/seeds. Event lifetime cannot be cut short simply because weekday changes. Rotation ensures no permanent fixed trio, at most five, at least three while Events are unlocked and service is available. Upcoming entries can be previewed but never joined/claimed before L30.
- Use only AUTHORITATIVE normal-level completion receipts / proven engine metrics, never a speculative on-screen counter. Derive `first_clear_new_level`, `first_attempt_new_level_win`, `cleaned_active_pixels`, `cleaned_pixels_by_color`, `win_without_booster_usage`, and consecutive wins exactly once per qualifying gameplay event. Distinguish normal replay, retry and victory. Validate event instance period, idempotency and no retroactive awards.
- Virtual rivals: deterministic seeded simulation with reasonable independent activity, no pay-triggered acceleration, no claim of real human participants. Use source-backed virtual avatars via approved robot portraits; 100 entrants may reuse ten portraits with unique display names, badges and frames. Offline progression must be stable on re-open; consider wall-clock tampering, impossible rival movement, and deterministic seeded fixtures.
- Distinguish family categories: competitive, individual, virtual-team, collection/reward, seasonal, special. Streak rollback affects event progress only. Team points are credited from actual player play plus transparently synthetic teammate contributions, not ghost real users. No shared multiplayer claim until server-backed.
- Reward currency/types only existing economy: `scrub_bucks`, `bot_parts`, `standard_card_packs`, `premium_card_packs`, `random_any_booster_charges`, `selected_booster_charges`. Map approved rewards to actual `RewardGrantService.grant(stable_tx_id, rewards)`. Claim is atomic/idempotent, save before acknowledgment, no double-grant on reboot/import/cloud conflict. Simulate worst-case **five simultaneous events** before publishing values. No new event currency unless separately approved. Preserve offline and consent privacy behavior.
- Accessibility: English/Turkish strings via standard localization, timer localization, readably distinct states, no color-only information, voice-over/focus/hit target checks; reduce motion behavior when Reduced Effects is active.
- Visual system: **only original owner-approved robot PNGs** from checked-out repo; do not synthesize new robots. Exactly two arms and two hands, no malformed attachments. 24 independent hero PNGs 1024×1024 and 24 independent emblems, 7 shared decorations/backgrounds, one portrait 1170×2532 Events master. **56 distinct artifacts**, no contact sheet/atlas/grid, no event sequence number drawn onto image. Use `assets/ui/final/events/heroes/<event_id>.png` and `.../icons/<event_id>.png`. Existing two legacy master images are *not final*. See `docs/SCRUBBOTS_EVENTS_VISUAL_REFERENCE_INTAKE_2026-11-13.md` for exact reference paths; missing optional ChatGPT ZIP **must not stop work**. The Godot event card must load art by event id and keep only the current 3–5 card textures active.
- Tutorial system: **one** reusable Godot three-step tutorial with unique data for every event: (1) show event hero/icon, canonical robot and plain goal; (2) actual ScrubBots level board and real metric-to-progress animation, with specific virtual rank or milestone representation; (3) reward path/chest, time remaining and button. 24×3 = **72 playable tutorial UI states**, not 72 painted full-screen images. See per-event scene descriptions below.
- Do not fork canonical solver or update its rules for events. Respect existing Five-Slot gameplay and L30 unlock gate everywhere (Home, shortcut, direct/deep link, calendar, details, tutorial, JOIN, CLAIM, imported saves).

## Event-by-event authoritative definitions

### Scrub Sprint

- **Stable ID:** `scrub_sprint` | **Family:** Rekabetçi | **Participants:** 4 sanal rakip (oyuncuyla 5).
- **Narrative and gameplay:** 15 yeni seviye kazan; her ilk tamamlanan yeni seviye yarış göstergesinde bir adım. Rakipten önce bitir.
- **Engine metric:** `first_clear_new_level`. **Numerical win condition:** 15. Only normal ScrubBots pixel-art cleaning outcomes contribute.
- **Hero visual:** Bitiş çizgisi ve temizlik izi. Every visible robot comes unchanged from canonical repo art; no numbered labels in the PNG.
- **Tutorial 1 (intro):** show the standalone `scrub_sprint.png` hero, emblem, approved robot(s), translated event purpose and participant format.
- **Tutorial 2 (how to play):** display the REAL normal pixel-art cleaning game board and the relevant signal `first_clear_new_level` applied once to the temizlik pistinde 5 robotun ilerleme çubukları. No other gameplay screen.
- **Tutorial 3 (rewards):** data-driven progress/ranking/reward track and claimable rewards via existing economy; time-left and event-entry button. Unknown amounts/schedule = config/balancing TBD, not invented constants.
- **Validation:** assert the described qualification, nonqualifying clears/replays/retries excluded appropriately, progress shown exactly once, restart/claim safe, virtual opponents labeled when present, and both L29 lock / L30 unlock.

### First Brush Race

- **Stable ID:** `first_brush_race` | **Family:** Rekabetçi | **Participants:** 4 sanal rakip (oyuncuyla 5).
- **Narrative and gameplay:** 3 veya 5 seviyeyi ilk denemede temizle; kaybedilen seviyeler etkinliğe puan kazandırmaz.
- **Engine metric:** `first_attempt_new_level_win`. **Numerical win condition:** 3 or 5 configured per instance. Only normal ScrubBots pixel-art cleaning outcomes contribute.
- **Hero visual:** Parıldayan ilk fırça / damalı bayrak. Every visible robot comes unchanged from canonical repo art; no numbered labels in the PNG.
- **Tutorial 1 (intro):** show the standalone `first_brush_race.png` hero, emblem, approved robot(s), translated event purpose and participant format.
- **Tutorial 2 (how to play):** display the REAL normal pixel-art cleaning game board and the relevant signal `first_attempt_new_level_win` applied once to the i̇lk deneme başarılarının sayımı. No other gameplay screen.
- **Tutorial 3 (rewards):** data-driven progress/ranking/reward track and claimable rewards via existing economy; time-left and event-entry button. Unknown amounts/schedule = config/balancing TBD, not invented constants.
- **Validation:** assert the described qualification, nonqualifying clears/replays/retries excluded appropriately, progress shown exactly once, restart/claim safe, virtual opponents labeled when present, and both L29 lock / L30 unlock.

### ScrubBots Royale

- **Stable ID:** `scrubbots_royale` | **Family:** Rekabetçi | **Participants:** 99 sanal rakip (toplam 100).
- **Narrative and gameplay:** 5 aşamalı eleme; her aşamada tanımlanan sayıda yeni seviyeyi ilk denemede tamamlayan ilerler. Aşamaların seviyeleri V02'de sayısal tanımlı değil.
- **Engine metric:** `first_attempt_new_level_win`. **Numerical win condition:** 5 rounds; per-round thresholds TBD. Only normal ScrubBots pixel-art cleaning outcomes contribute.
- **Hero visual:** Temizlik şampiyonası sahnesi. Every visible robot comes unchanged from canonical repo art; no numbered labels in the PNG.
- **Tutorial 1 (intro):** show the standalone `scrubbots_royale.png` hero, emblem, approved robot(s), translated event purpose and participant format.
- **Tutorial 2 (how to play):** display the REAL normal pixel-art cleaning game board and the relevant signal `first_attempt_new_level_win` applied once to the 100 sanal rakipten aşamalı elenme şeması. No other gameplay screen.
- **Tutorial 3 (rewards):** data-driven progress/ranking/reward track and claimable rewards via existing economy; time-left and event-entry button. Unknown amounts/schedule = config/balancing TBD, not invented constants.
- **Validation:** assert the described qualification, nonqualifying clears/replays/retries excluded appropriately, progress shown exactly once, restart/claim safe, virtual opponents labeled when present, and both L29 lock / L30 unlock.

### Golden Brush Championship

- **Stable ID:** `golden_brush_championship` | **Family:** Rekabetçi | **Participants:** 7 sanal rakip (toplam 8).
- **Narrative and gameplay:** Çeyrek final, yarı final, final. Her turda belirlenen süre boyunca daha fazla uygun yeni seviye kazanan ilerler; eşitlik ve tur süresi tasarlanıp test edilir.
- **Engine metric:** `first_clear_new_level`. **Numerical win condition:** 8-player bracket / 3 elimination rounds. Only normal ScrubBots pixel-art cleaning outcomes contribute.
- **Hero visual:** Altın temizlik fırçası kupası. Every visible robot comes unchanged from canonical repo art; no numbered labels in the PNG.
- **Tutorial 1 (intro):** show the standalone `golden_brush_championship.png` hero, emblem, approved robot(s), translated event purpose and participant format.
- **Tutorial 2 (how to play):** display the REAL normal pixel-art cleaning game board and the relevant signal `first_clear_new_level` applied once to the 8 kişilik çeyrek finalden finale turnuva ağacı. No other gameplay screen.
- **Tutorial 3 (rewards):** data-driven progress/ranking/reward track and claimable rewards via existing economy; time-left and event-entry button. Unknown amounts/schedule = config/balancing TBD, not invented constants.
- **Validation:** assert the described qualification, nonqualifying clears/replays/retries excluded appropriately, progress shown exactly once, restart/claim safe, virtual opponents labeled when present, and both L29 lock / L30 unlock.

### Weekly Scrub League

- **Stable ID:** `weekly_scrub_league` | **Family:** Rekabetçi | **Participants:** 19 sanal rakip (toplam 20).
- **Narrative and gameplay:** Haftalık sıralamayı yeni seviyelerde temizlenen gerçek aktif piksel sayısı belirler; replay/tekrar oynama sıralamayı şişiremez.
- **Engine metric:** `cleaned_active_pixels_on_new_levels`. **Numerical win condition:** weekly ranking / 20 entries. Only normal ScrubBots pixel-art cleaning outcomes contribute.
- **Hero visual:** Robotların temizlik kürsüsü. Every visible robot comes unchanged from canonical repo art; no numbered labels in the PNG.
- **Tutorial 1 (intro):** show the standalone `weekly_scrub_league.png` hero, emblem, approved robot(s), translated event purpose and participant format.
- **Tutorial 2 (how to play):** display the REAL normal pixel-art cleaning game board and the relevant signal `cleaned_active_pixels_on_new_levels` applied once to the piksel sayısına göre sıralama tablosu. No other gameplay screen.
- **Tutorial 3 (rewards):** data-driven progress/ranking/reward track and claimable rewards via existing economy; time-left and event-entry button. Unknown amounts/schedule = config/balancing TBD, not invented constants.
- **Validation:** assert the described qualification, nonqualifying clears/replays/retries excluded appropriately, progress shown exactly once, restart/claim safe, virtual opponents labeled when present, and both L29 lock / L30 unlock.

### Weekly Cleanup Challenge

- **Stable ID:** `weekly_cleanup_challenge` | **Family:** Bireysel | **Participants:** Tek oyuncu.
- **Narrative and gameplay:** Hafta boyunca yeni seviye temizleyerek 3/7/12/20 dönüm noktası ödüllerini aç.
- **Engine metric:** `first_clear_new_level`. **Numerical win condition:** 3,7,12,20. Only normal ScrubBots pixel-art cleaning outcomes contribute.
- **Hero visual:** Fıskiyeli temiz park. Every visible robot comes unchanged from canonical repo art; no numbered labels in the PNG.
- **Tutorial 1 (intro):** show the standalone `weekly_cleanup_challenge.png` hero, emblem, approved robot(s), translated event purpose and participant format.
- **Tutorial 2 (how to play):** display the REAL normal pixel-art cleaning game board and the relevant signal `first_clear_new_level` applied once to the haftalık dört ödül basamağı. No other gameplay screen.
- **Tutorial 3 (rewards):** data-driven progress/ranking/reward track and claimable rewards via existing economy; time-left and event-entry button. Unknown amounts/schedule = config/balancing TBD, not invented constants.
- **Validation:** assert the described qualification, nonqualifying clears/replays/retries excluded appropriately, progress shown exactly once, restart/claim safe, virtual opponents labeled when present, and both L29 lock / L30 unlock.

### Perfect First Clean

- **Stable ID:** `perfect_first_clean` | **Family:** Bireysel | **Participants:** Tek oyuncu.
- **Narrative and gameplay:** Yeni seviyelerin ilk denemesinde galibiyet kazanarak 3/5/10 dönüm noktasına ulaş.
- **Engine metric:** `first_attempt_new_level_win`. **Numerical win condition:** 3,5,10. Only normal ScrubBots pixel-art cleaning outcomes contribute.
- **Hero visual:** Parlayan kusursuz fırça rozeti. Every visible robot comes unchanged from canonical repo art; no numbered labels in the PNG.
- **Tutorial 1 (intro):** show the standalone `perfect_first_clean.png` hero, emblem, approved robot(s), translated event purpose and participant format.
- **Tutorial 2 (how to play):** display the REAL normal pixel-art cleaning game board and the relevant signal `first_attempt_new_level_win` applied once to the i̇lk deneme zaferlerinin sayımı. No other gameplay screen.
- **Tutorial 3 (rewards):** data-driven progress/ranking/reward track and claimable rewards via existing economy; time-left and event-entry button. Unknown amounts/schedule = config/balancing TBD, not invented constants.
- **Validation:** assert the described qualification, nonqualifying clears/replays/retries excluded appropriately, progress shown exactly once, restart/claim safe, virtual opponents labeled when present, and both L29 lock / L30 unlock.

### Sparkling Streak

- **Stable ID:** `sparkling_streak` | **Family:** Bireysel | **Participants:** Tek oyuncu.
- **Narrative and gameplay:** Art arda uygun galibiyetlerle 3/5/7/10 kilometre taşlarına ulaş. Kaybedince yalnızca etkinlikteki aktif seri son kontrol noktasına döner; ana seviye ilerlemesi sıfırlanmaz.
- **Engine metric:** `consecutive_qualifying_wins`. **Numerical win condition:** 3,5,7,10 checkpoints. Only normal ScrubBots pixel-art cleaning outcomes contribute.
- **Hero visual:** Yıldızlı temizlik yolu. Every visible robot comes unchanged from canonical repo art; no numbered labels in the PNG.
- **Tutorial 1 (intro):** show the standalone `sparkling_streak.png` hero, emblem, approved robot(s), translated event purpose and participant format.
- **Tutorial 2 (how to play):** display the REAL normal pixel-art cleaning game board and the relevant signal `consecutive_qualifying_wins` applied once to the temiz park yolu ve kontrol noktaları. No other gameplay screen.
- **Tutorial 3 (rewards):** data-driven progress/ranking/reward track and claimable rewards via existing economy; time-left and event-entry button. Unknown amounts/schedule = config/balancing TBD, not invented constants.
- **Validation:** assert the described qualification, nonqualifying clears/replays/retries excluded appropriately, progress shown exactly once, restart/claim safe, virtual opponents labeled when present, and both L29 lock / L30 unlock.

### Stain Busters

- **Stable ID:** `stain_busters` | **Family:** Bireysel | **Participants:** Tek oyuncu.
- **Narrative and gameplay:** Normal seviyelerde gerçekten temizlenen aktif pikselleri say; hedef miktar V02'de belirlenmedi ve config/economy çalışmasıyla netleştirilmeli.
- **Engine metric:** `cleaned_active_pixels`. **Numerical win condition:** TBD after balancing. Only normal ScrubBots pixel-art cleaning outcomes contribute.
- **Hero visual:** Büyük lekeli piksel tablo. Every visible robot comes unchanged from canonical repo art; no numbered labels in the PNG.
- **Tutorial 1 (intro):** show the standalone `stain_busters.png` hero, emblem, approved robot(s), translated event purpose and participant format.
- **Tutorial 2 (how to play):** display the REAL normal pixel-art cleaning game board and the relevant signal `cleaned_active_pixels` applied once to the aktif piksel sayacının artışı. No other gameplay screen.
- **Tutorial 3 (rewards):** data-driven progress/ranking/reward track and claimable rewards via existing economy; time-left and event-entry button. Unknown amounts/schedule = config/balancing TBD, not invented constants.
- **Validation:** assert the described qualification, nonqualifying clears/replays/retries excluded appropriately, progress shown exactly once, restart/claim safe, virtual opponents labeled when present, and both L29 lock / L30 unlock.

### Pure Scrub Challenge

- **Stable ID:** `pure_scrub_challenge` | **Family:** Bireysel | **Participants:** Tek oyuncu.
- **Narrative and gameplay:** Booster kullanmadan kazanılan uygun seviyelerden 3/5/10 ödül hedefi. Booster harcanıp sonra geri alınmışsa kullanım sayılmalıdır; uygulamadaki gerçek kullanım kaydı doğrulanmalı.
- **Engine metric:** `win_without_booster_usage`. **Numerical win condition:** 3,5,10. Only normal ScrubBots pixel-art cleaning outcomes contribute.
- **Hero visual:** Temiz fırça ve booster kullanılmaz simgesi. Every visible robot comes unchanged from canonical repo art; no numbered labels in the PNG.
- **Tutorial 1 (intro):** show the standalone `pure_scrub_challenge.png` hero, emblem, approved robot(s), translated event purpose and participant format.
- **Tutorial 2 (how to play):** display the REAL normal pixel-art cleaning game board and the relevant signal `win_without_booster_usage` applied once to the boostersız galibiyet gösterimi. No other gameplay screen.
- **Tutorial 3 (rewards):** data-driven progress/ranking/reward track and claimable rewards via existing economy; time-left and event-entry button. Unknown amounts/schedule = config/balancing TBD, not invented constants.
- **Validation:** assert the described qualification, nonqualifying clears/replays/retries excluded appropriately, progress shown exactly once, restart/claim safe, virtual opponents labeled when present, and both L29 lock / L30 unlock.

### Scrub Squad Tournament

- **Stable ID:** `scrub_squad_tournament` | **Family:** Takım | **Participants:** 10 kişilik sanal ekip.
- **Narrative and gameplay:** Sanal ekiplerin normal seviyelerdeki kazanımlarına dayalı takım yarışı; diğer ekip sayısı ve karşılaşma biçimi V02'de belirtilmedi.
- **Engine metric:** `virtual_team_qualifying_level_wins`. **Numerical win condition:** team size 10; win threshold TBD. Only normal ScrubBots pixel-art cleaning outcomes contribute.
- **Hero visual:** İki temizlik takımının işbirliği / rekabet afişi. Every visible robot comes unchanged from canonical repo art; no numbered labels in the PNG.
- **Tutorial 1 (intro):** show the standalone `scrub_squad_tournament.png` hero, emblem, approved robot(s), translated event purpose and participant format.
- **Tutorial 2 (how to play):** display the REAL normal pixel-art cleaning game board and the relevant signal `virtual_team_qualifying_level_wins` applied once to the robot takım arkadaşları ve takım puanı. No other gameplay screen.
- **Tutorial 3 (rewards):** data-driven progress/ranking/reward track and claimable rewards via existing economy; time-left and event-entry button. Unknown amounts/schedule = config/balancing TBD, not invented constants.
- **Validation:** assert the described qualification, nonqualifying clears/replays/retries excluded appropriately, progress shown exactly once, restart/claim safe, virtual opponents labeled when present, and both L29 lock / L30 unlock.

### Clean Team Treasure

- **Stable ID:** `clean_team_treasure` | **Family:** Takım | **Participants:** 10 kişilik sanal ekip.
- **Narrative and gameplay:** Takım üyelerinin normal seviye temizliğinden gelen ortak puanla hazine sandığı basamaklarını aç.
- **Engine metric:** `virtual_team_cleaning_points`. **Numerical win condition:** team size 10; milestones TBD. Only normal ScrubBots pixel-art cleaning outcomes contribute.
- **Hero visual:** Robotlar ve altın sandık. Every visible robot comes unchanged from canonical repo art; no numbered labels in the PNG.
- **Tutorial 1 (intro):** show the standalone `clean_team_treasure.png` hero, emblem, approved robot(s), translated event purpose and participant format.
- **Tutorial 2 (how to play):** display the REAL normal pixel-art cleaning game board and the relevant signal `virtual_team_cleaning_points` applied once to the ortak hazinenin basamakları. No other gameplay screen.
- **Tutorial 3 (rewards):** data-driven progress/ranking/reward track and claimable rewards via existing economy; time-left and event-entry button. Unknown amounts/schedule = config/balancing TBD, not invented constants.
- **Validation:** assert the described qualification, nonqualifying clears/replays/retries excluded appropriately, progress shown exactly once, restart/claim safe, virtual opponents labeled when present, and both L29 lock / L30 unlock.

### Scrub Relay

- **Stable ID:** `scrub_relay` | **Family:** Takım | **Participants:** 5 kişilik sanal ekip.
- **Narrative and gameplay:** Takım üyelerinin normal seviye tamamlamalarıyla sıralı etapların ilerlemesi; bayrak yarışı yalnızca görsel ilerleme.
- **Engine metric:** `virtual_team_sequential_clears`. **Numerical win condition:** team size 5; stage thresholds TBD. Only normal ScrubBots pixel-art cleaning outcomes contribute.
- **Hero visual:** Temizlik bayrağı / fırça teslim sahnesi. Every visible robot comes unchanged from canonical repo art; no numbered labels in the PNG.
- **Tutorial 1 (intro):** show the standalone `scrub_relay.png` hero, emblem, approved robot(s), translated event purpose and participant format.
- **Tutorial 2 (how to play):** display the REAL normal pixel-art cleaning game board and the relevant signal `virtual_team_sequential_clears` applied once to the sırayla ilerleyen robot katkı göstergesi. No other gameplay screen.
- **Tutorial 3 (rewards):** data-driven progress/ranking/reward track and claimable rewards via existing economy; time-left and event-entry button. Unknown amounts/schedule = config/balancing TBD, not invented constants.
- **Validation:** assert the described qualification, nonqualifying clears/replays/retries excluded appropriately, progress shown exactly once, restart/claim safe, virtual opponents labeled when present, and both L29 lock / L30 unlock.

### Mega Stain Cleanup

- **Stable ID:** `mega_stain_cleanup` | **Family:** Takım | **Participants:** 20 kişilik sanal ekip.
- **Narrative and gameplay:** Büyük kir hedefini oyuncunun ve sanal takımın normal seviyelerde temizlediği pikseller azaltır. 50.000 piksel V02'de sadece örnektir, kesin hedef değildir; dev kirli görsel mini oyun değildir.
- **Engine metric:** `virtual_team_cleaned_active_pixels`. **Numerical win condition:** team size 20; target TBD (50,000 example only). Only normal ScrubBots pixel-art cleaning outcomes contribute.
- **Hero visual:** Geniş leke temizleme afişi. Every visible robot comes unchanged from canonical repo art; no numbered labels in the PNG.
- **Tutorial 1 (intro):** show the standalone `mega_stain_cleanup.png` hero, emblem, approved robot(s), translated event purpose and participant format.
- **Tutorial 2 (how to play):** display the REAL normal pixel-art cleaning game board and the relevant signal `virtual_team_cleaned_active_pixels` applied once to the dev kirli panonun aşamalı temizlenmesi. No other gameplay screen.
- **Tutorial 3 (rewards):** data-driven progress/ranking/reward track and claimable rewards via existing economy; time-left and event-entry button. Unknown amounts/schedule = config/balancing TBD, not invented constants.
- **Validation:** assert the described qualification, nonqualifying clears/replays/retries excluded appropriately, progress shown exactly once, restart/claim safe, virtual opponents labeled when present, and both L29 lock / L30 unlock.

### Scrubby's Cleanup Workshop

- **Stable ID:** `scrubbys_cleanup_workshop` | **Family:** Koleksiyon / ödül | **Participants:** Tek oyuncu.
- **Narrative and gameplay:** Normal seviyelerle atölye ödül basamakları açılır; ayrı atölye oynanışı veya üretim mini oyunu yok. Ödül kategorisi SB/booster.
- **Engine metric:** `first_clear_new_level`. **Numerical win condition:** milestones TBD. Only normal ScrubBots pixel-art cleaning outcomes contribute.
- **Hero visual:** Scrubby ve orijinal temizlik atölyesi dekoru. Every visible robot comes unchanged from canonical repo art; no numbered labels in the PNG.
- **Tutorial 1 (intro):** show the standalone `scrubbys_cleanup_workshop.png` hero, emblem, approved robot(s), translated event purpose and participant format.
- **Tutorial 2 (how to play):** display the REAL normal pixel-art cleaning game board and the relevant signal `first_clear_new_level` applied once to the atölye ödül yolunun aşamaları. No other gameplay screen.
- **Tutorial 3 (rewards):** data-driven progress/ranking/reward track and claimable rewards via existing economy; time-left and event-entry button. Unknown amounts/schedule = config/balancing TBD, not invented constants.
- **Validation:** assert the described qualification, nonqualifying clears/replays/retries excluded appropriately, progress shown exactly once, restart/claim safe, virtual opponents labeled when present, and both L29 lock / L30 unlock.

### Robot Parts Recovery

- **Stable ID:** `robot_parts_recovery` | **Family:** Koleksiyon / ödül | **Participants:** Tek oyuncu.
- **Narrative and gameplay:** Temizlik ilerlemesiyle Robot Parts kazan; robot parçalarını yerleştirme/montaj mini oyunu yok.
- **Engine metric:** `first_clear_new_level`. **Numerical win condition:** milestones TBD. Only normal ScrubBots pixel-art cleaning outcomes contribute.
- **Hero visual:** Geri kazanılan robot parçaları. Every visible robot comes unchanged from canonical repo art; no numbered labels in the PNG.
- **Tutorial 1 (intro):** show the standalone `robot_parts_recovery.png` hero, emblem, approved robot(s), translated event purpose and participant format.
- **Tutorial 2 (how to play):** display the REAL normal pixel-art cleaning game board and the relevant signal `first_clear_new_level` applied once to the kazandırılan robot parts. No other gameplay screen.
- **Tutorial 3 (rewards):** data-driven progress/ranking/reward track and claimable rewards via existing economy; time-left and event-entry button. Unknown amounts/schedule = config/balancing TBD, not invented constants.
- **Validation:** assert the described qualification, nonqualifying clears/replays/retries excluded appropriately, progress shown exactly once, restart/claim safe, virtual opponents labeled when present, and both L29 lock / L30 unlock.

### Lost Card Rescue

- **Stable ID:** `lost_card_rescue` | **Family:** Koleksiyon / ödül | **Participants:** Tek oyuncu.
- **Narrative and gameplay:** Normal temizleme görevleri ile Card Pack kazan; kart arama mini oyunu yok.
- **Engine metric:** `first_clear_new_level`. **Numerical win condition:** milestones TBD. Only normal ScrubBots pixel-art cleaning outcomes contribute.
- **Hero visual:** Kurtarılan onaylı kart paketleri. Every visible robot comes unchanged from canonical repo art; no numbered labels in the PNG.
- **Tutorial 1 (intro):** show the standalone `lost_card_rescue.png` hero, emblem, approved robot(s), translated event purpose and participant format.
- **Tutorial 2 (how to play):** display the REAL normal pixel-art cleaning game board and the relevant signal `first_clear_new_level` applied once to the temizlik sonunda kart paket ödülü. No other gameplay screen.
- **Tutorial 3 (rewards):** data-driven progress/ranking/reward track and claimable rewards via existing economy; time-left and event-entry button. Unknown amounts/schedule = config/balancing TBD, not invented constants.
- **Validation:** assert the described qualification, nonqualifying clears/replays/retries excluded appropriately, progress shown exactly once, restart/claim safe, virtual opponents labeled when present, and both L29 lock / L30 unlock.

### Seasonal Scrub Festival

- **Stable ID:** `seasonal_scrub_festival` | **Family:** Sezonluk | **Participants:** Tek oyuncu.
- **Narrative and gameplay:** Cadılar Bayramı, Noel, yaz temizliği vb. mevsim görünümüyle normal seviyelerden etkinlik ilerlemesi. Her dönem için isim/takvim/ödül ayarları config ile belirlenir.
- **Engine metric:** `seasonal_qualifying_level_progress`. **Numerical win condition:** seasonal thresholds TBD. Only normal ScrubBots pixel-art cleaning outcomes contribute.
- **Hero visual:** Mevsim dekorlu park. Every visible robot comes unchanged from canonical repo art; no numbered labels in the PNG.
- **Tutorial 1 (intro):** show the standalone `seasonal_scrub_festival.png` hero, emblem, approved robot(s), translated event purpose and participant format.
- **Tutorial 2 (how to play):** display the REAL normal pixel-art cleaning game board and the relevant signal `seasonal_qualifying_level_progress` applied once to the sezonluk görev ve ödüller. No other gameplay screen.
- **Tutorial 3 (rewards):** data-driven progress/ranking/reward track and claimable rewards via existing economy; time-left and event-entry button. Unknown amounts/schedule = config/balancing TBD, not invented constants.
- **Validation:** assert the described qualification, nonqualifying clears/replays/retries excluded appropriately, progress shown exactly once, restart/claim safe, virtual opponents labeled when present, and both L29 lock / L30 unlock.

### Master Cleaner Quest

- **Stable ID:** `master_cleaner_quest` | **Family:** Görev | **Participants:** Tek oyuncu.
- **Narrative and gameplay:** Birden fazla farklı etkinlikteki hedefleri tamamlayarak büyük ödül sandığı aç. Alt hedefler ve çift sayım semantiği açık konfigürasyonda olmalı.
- **Engine metric:** `qualified_cross_event_objectives`. **Numerical win condition:** required objectives TBD. Only normal ScrubBots pixel-art cleaning outcomes contribute.
- **Hero visual:** Temizlik görevi haritası. Every visible robot comes unchanged from canonical repo art; no numbered labels in the PNG.
- **Tutorial 1 (intro):** show the standalone `master_cleaner_quest.png` hero, emblem, approved robot(s), translated event purpose and participant format.
- **Tutorial 2 (how to play):** display the REAL normal pixel-art cleaning game board and the relevant signal `qualified_cross_event_objectives` applied once to the birden fazla etkinliğin ilerleme görselleştirmesi. No other gameplay screen.
- **Tutorial 3 (rewards):** data-driven progress/ranking/reward track and claimable rewards via existing economy; time-left and event-entry button. Unknown amounts/schedule = config/balancing TBD, not invented constants.
- **Validation:** assert the described qualification, nonqualifying clears/replays/retries excluded appropriately, progress shown exactly once, restart/claim safe, virtual opponents labeled when present, and both L29 lock / L30 unlock.

### Scrub Season Pass

- **Stable ID:** `scrub_season_pass` | **Family:** Sezonluk ödül | **Participants:** Tek oyuncu.
- **Narrative and gameplay:** Normal seviyeleri temizledikçe ücretsiz sezon ödül yolunda ilerle; V02 ücretli premium yol tanımlamaz.
- **Engine metric:** `first_clear_new_level`. **Numerical win condition:** free reward-track thresholds TBD. Only normal ScrubBots pixel-art cleaning outcomes contribute.
- **Hero visual:** Sezon kartı ve fırça sembolü. Every visible robot comes unchanged from canonical repo art; no numbered labels in the PNG.
- **Tutorial 1 (intro):** show the standalone `scrub_season_pass.png` hero, emblem, approved robot(s), translated event purpose and participant format.
- **Tutorial 2 (how to play):** display the REAL normal pixel-art cleaning game board and the relevant signal `first_clear_new_level` applied once to the ücretsiz sezon ödül yolu. No other gameplay screen.
- **Tutorial 3 (rewards):** data-driven progress/ranking/reward track and claimable rewards via existing economy; time-left and event-entry button. Unknown amounts/schedule = config/balancing TBD, not invented constants.
- **Validation:** assert the described qualification, nonqualifying clears/replays/retries excluded appropriately, progress shown exactly once, restart/claim safe, virtual opponents labeled when present, and both L29 lock / L30 unlock.

### Color Scrub Rush

- **Stable ID:** `color_scrub_rush` | **Family:** Özel | **Participants:** Tek oyuncu.
- **Narrative and gameplay:** Normal seviyelerde gerçek temizlenen pikselleri renklerine göre sayarak hedef renk sayaçlarını doldur. Yalnızca normal seviyede bulunan renkler sayılabilir.
- **Engine metric:** `cleaned_pixels_by_color`. **Numerical win condition:** target colors and thresholds TBD. Only normal ScrubBots pixel-art cleaning outcomes contribute.
- **Hero visual:** Renkli piksel temizleme panosu. Every visible robot comes unchanged from canonical repo art; no numbered labels in the PNG.
- **Tutorial 1 (intro):** show the standalone `color_scrub_rush.png` hero, emblem, approved robot(s), translated event purpose and participant format.
- **Tutorial 2 (how to play):** display the REAL normal pixel-art cleaning game board and the relevant signal `cleaned_pixels_by_color` applied once to the renk sayaçlarının dolması. No other gameplay screen.
- **Tutorial 3 (rewards):** data-driven progress/ranking/reward track and claimable rewards via existing economy; time-left and event-entry button. Unknown amounts/schedule = config/balancing TBD, not invented constants.
- **Validation:** assert the described qualification, nonqualifying clears/replays/retries excluded appropriately, progress shown exactly once, restart/claim safe, virtual opponents labeled when present, and both L29 lock / L30 unlock.

### Scrubby's Rescue Mission

- **Stable ID:** `scrubbys_rescue_mission` | **Family:** Özel / hikâye | **Participants:** Tek oyuncu.
- **Narrative and gameplay:** Birkaç normal seviye kazanıldığında kayıp ScrubBots kurtarma hikâyesinin yeni basamağı görünür; kurtarma ayrı bir oyun değil.
- **Engine metric:** `first_clear_new_level`. **Numerical win condition:** story milestone thresholds TBD. Only normal ScrubBots pixel-art cleaning outcomes contribute.
- **Hero visual:** Orijinal robotların kurtarılma teması. Every visible robot comes unchanged from canonical repo art; no numbered labels in the PNG.
- **Tutorial 1 (intro):** show the standalone `scrubbys_rescue_mission.png` hero, emblem, approved robot(s), translated event purpose and participant format.
- **Tutorial 2 (how to play):** display the REAL normal pixel-art cleaning game board and the relevant signal `first_clear_new_level` applied once to the seviye galibiyetiyle ilerleyen kurtarma hikâyesi. No other gameplay screen.
- **Tutorial 3 (rewards):** data-driven progress/ranking/reward track and claimable rewards via existing economy; time-left and event-entry button. Unknown amounts/schedule = config/balancing TBD, not invented constants.
- **Validation:** assert the described qualification, nonqualifying clears/replays/retries excluded appropriately, progress shown exactly once, restart/claim safe, virtual opponents labeled when present, and both L29 lock / L30 unlock.

### World Cleanup Cup

- **Stable ID:** `world_cleanup_cup` | **Family:** Rekabetçi | **Participants:** 20 sanal rakip (oyuncuyla 21 giriş).
- **Narrative and gameplay:** Yeni seviyelerde kazanılan temizlik puanlarına göre 20 sanal rakiple dünya kupası sıralaması; gerçek canlı dünya sıralaması gibi sunulamaz.
- **Engine metric:** `first_clear_new_level_cleanup_score`. **Numerical win condition:** 20 virtual rivals; scoring weights TBD. Only normal ScrubBots pixel-art cleaning outcomes contribute.
- **Hero visual:** Dünya temizlik kupası ve onaylı robot avatarları. Every visible robot comes unchanged from canonical repo art; no numbered labels in the PNG.
- **Tutorial 1 (intro):** show the standalone `world_cleanup_cup.png` hero, emblem, approved robot(s), translated event purpose and participant format.
- **Tutorial 2 (how to play):** display the REAL normal pixel-art cleaning game board and the relevant signal `first_clear_new_level_cleanup_score` applied once to the sanal dünya sıralaması. No other gameplay screen.
- **Tutorial 3 (rewards):** data-driven progress/ranking/reward track and claimable rewards via existing economy; time-left and event-entry button. Unknown amounts/schedule = config/balancing TBD, not invented constants.
- **Validation:** assert the described qualification, nonqualifying clears/replays/retries excluded appropriately, progress shown exactly once, restart/claim safe, virtual opponents labeled when present, and both L29 lock / L30 unlock.

### Mystery ScrubBox Hunt

- **Stable ID:** `mystery_scrubbox_hunt` | **Family:** Koleksiyon / ödül | **Participants:** Tek oyuncu.
- **Narrative and gameplay:** Belirlenen sayıda normal seviyeyi temizledikçe sürpriz ScrubBox sandıkları açılır; sandık açma mevcut ödül törenidir, ayrı oynanış değil.
- **Engine metric:** `first_clear_new_level`. **Numerical win condition:** chest thresholds TBD. Only normal ScrubBots pixel-art cleaning outcomes contribute.
- **Hero visual:** Gizemli ScrubBox sandığı. Every visible robot comes unchanged from canonical repo art; no numbered labels in the PNG.
- **Tutorial 1 (intro):** show the standalone `mystery_scrubbox_hunt.png` hero, emblem, approved robot(s), translated event purpose and participant format.
- **Tutorial 2 (how to play):** display the REAL normal pixel-art cleaning game board and the relevant signal `first_clear_new_level` applied once to the temizlik ilerlemesiyle açılan sandıklar. No other gameplay screen.
- **Tutorial 3 (rewards):** data-driven progress/ranking/reward track and claimable rewards via existing economy; time-left and event-entry button. Unknown amounts/schedule = config/balancing TBD, not invented constants.
- **Validation:** assert the described qualification, nonqualifying clears/replays/retries excluded appropriately, progress shown exactly once, restart/claim safe, virtual opponents labeled when present, and both L29 lock / L30 unlock.
## Owner sample rotation (illustrative, not hard date override)
| Day | Count | Examples |
|---|---:|---|
| Mon | 3 | Scrub Sprint, Robot Parts Recovery, Weekly Cleanup Challenge |
| Tue | 4 | Scrub Sprint, Robot Parts Recovery, Weekly Cleanup Challenge, Clean Team Treasure |
| Wed | 4 | Clean Team Treasure, Color Scrub Rush, Sparkling Streak, Weekly Cleanup Challenge |
| Thu | 3 | First Brush Race, Lost Card Rescue, Scrub Season Pass |
| Fri | 5 | Golden Brush Championship, Mega Stain Cleanup, Scrub Season Pass, Mystery ScrubBox Hunt, Color Scrub Rush |
| Sat | 5 | ScrubBots Royale, Master Cleaner Quest, Seasonal Scrub Festival, Scrub Season Pass, Mega Stain Cleanup |
| Sun | 3 | World Cleanup Cup, Perfect First Clean, Scrubby's Rescue Mission |

Actual event windows persist past weekday boundaries until their configured end time. Use UTC instants for scheduling; render locale-dependent times in UI. Changes to config cannot erase valid ongoing instance progress.

## Provider and local reference truth
The optional draft file `scrubbots_events_master_references.zip` was generated in a separate ChatGPT conversation but has **not** been committed to this GitHub repo. DO NOT block implementation asking for it. Existing legacy reference paths and actual production robot paths are in the visual intake document. Code agent must independently discover the approved robots and generate/publish its own QA-passed master and Weekly art; it may treat the optional ZIP as a mood board if the owner voluntarily places it in the checkout. Do not pretend it already exists or substitute noncanonical robot art from it.

## Delivery and testing matrix
- Audit current EventService / UiEventCard and source signals, read actual schema and local tests; create clean V02 config without corrupting `events_v1.json` compatibility. Do not schedule silent payouts while reward tables lack validation.
- For every event, test lifecycle: upcoming -> active -> ended -> claimable -> expired, qualified progress, disqualified progress, loss/retry/replay, app relaunch, save migration, and claim idempotency; 24 unique definition-specific tests plus cross-family integration checks.
- Test rotation at 3/4/5 active, time zone and DST, overlapping windows, L29/L30 unlocking, offline clock changes, virtual opponent stability, safe rewards and zero new gameplay states.
- Show screenshots captured from actual Godot Events and tutorial surfaces at 720×1520 and 1170×2532, scroll to inspect all cards; verify focus/safe areas, long Turkish copy and texture budget.
- Produce standalone PNGs individually and verify by actual pixel dimensions/hash/source robot identity; no collage cropping or fabricated completion. Commit and push verified batches to GitHub, synchronize only root `TASKS.md` status, preserve unrelated local changes. Use factory loop in `CLAUDE.md` §0D and local test guidance.
- Completion only after the 24 events, 72 tutorial states, 56 distinct visual outputs, tests, screenshots and verified remote commits are delivered. Any amount/duration/target still needing economy verification remains open in TASKS.md rather than claimed DONE.

## Explicitly unresolved configuration decisions to implement safely
- Per-event duration, recurrence, tie-break rules, challenger difficulty curves and AI scoring model are not numerically approved by V02; implement deterministic, documented, testable proposals with validation and label assumptions.
- Reward quantities and expiry/unclaimed policy are not numerically approved by V02; do worst-case economy simulations first; gate production grants until valid, instead of inventing numbers or asking for the missing ZIP.
- Where V02 says “3 or 5,” “e.g. 50,000,” or illustrative weekdays, treat as parameter choices/examples, not fixed universal truth.
- World Cleanup Cup has **20 virtual rivals plus player**; do not silently reinterpret it as 20 total.
- The only valid current unlock requirement is **LEVEL 30**; pre-30 players cannot enter Events even though V02's original draft proposed Level 1.

## Comprehensive V02 runtime contracts (implementation requirements)

**Single authority:** This file is the complete event specification for Claude and Codex. Root TASKS.md is the ONLY task tracker. Current `feature_unlocks_v1.json` events=30 overrides the older draft statement Events unlock at level 1. On L1–29 hide/lock all event access, tutorial, claims and deep links; L30+ permits active Events. Every event must be present in first-release type registry.

**Gameplay source:** ONLY the existing pixel-art cleanup game. Canonical result receipt fields/derived adapters: stable completion receipt ID, event instance ID, level ID, campaign first clear, first-ever attempt ordinal, final win/loss, completion UTC, verified active pixels cleaned, verified pixel count by palette color, actually-used booster count, applied reward transaction IDs. Check existing game source for exact field names; do not invent a separate scoring mini-game. Event progress claims must be deduplicated using receipt_id and instance_id. Replays and retry-after-first-loss cannot fabricate first-time wins. Pixel color total must reconcile to active pixel total. VOID/background pixels excluded.

**Scheduling:** persisted event instances with immutable instance_id, start/end UTC, statuses upcoming/active/ended/claimable/expired, time remaining; don't end a running event on weekday change. Rotation selects 3–5 concurrent active instances with varied categories and fair coverage of 24 templates, keeps all live instances until their end; refuses excess launches instead of forcibly canceling active events. Upcoming list separate. Time-zone/DST, clock change and offline resume tested with injected clock and deterministic schedule seeds. Owner V02's seven-day example is a fixture, not a fixed schedule that prematurely terminates multi-day events.

**Suggested duration defaults (CONFIGURABLE IMPLEMENTATION PROPOSALS, not historical owner-approved):** Scrub Sprint 48h; First Brush Race 48h; Royale 72h; Championship 72h; Weekly Scrub League 7d; Weekly Cleanup Challenge 7d; Perfect First Clean 72h; Sparkling Streak 72h; Stain Busters 72h; Pure Scrub Challenge 72h; Scrub Squad Tournament 72h; Clean Team Treasure 72h; Scrub Relay 48h; Mega Stain Cleanup 72h; Scrubby's Cleanup Workshop 7d; Robot Parts Recovery 72h; Lost Card Rescue 72h; Seasonal Scrub Festival 7d; Master Cleaner Quest 7d; Scrub Season Pass 28d; Color Scrub Rush 48h; Scrubby's Rescue Mission 72h; World Cleanup Cup 7d; Mystery ScrubBox Hunt 72h. Every proposed duration may be changed through configuration; no hardcoded date gate. Verify 28-day calendar contains all 24 types, never exceeds 5, never drops below 3 after unlock, and never ends an active instance early.

**Rivals:** deterministic seed based on instance ID, rival ID and profile; bounded casual/average/strong/expert schedules. No rival accelerates because player spends money. Rivals are transparently computer-controlled. Royale has 100 ENTRIES (player+99 virtual), 5 elimination stages; Championship has 8 ENTRIES (player+7 virtual) and brackets 8→4→2→1; Weekly Scrub League has 20 entries (player+19 virtual); World Cleanup Cup has player+20 virtual entries; team events use exactly the team sizes provided in each event section. Ten canonical robot avatars may be reused with varied names, badges/frames, never generated as new identities. Future real friends require separate identity and server-backed verification.

**Reward policy:** use only canonical approved existing reward TYPE keys: scrub_bucks, bot_parts, standard_card_packs, premium_card_packs, random_any_booster_charges, selected_booster_charges. V02 did NOT approve numerical amounts. Concrete reward amounts must be documented as implementation/balancing proposals, simulated for a worst-case player with FIVE simultaneous Events over a 28-day cycle, compared to the existing reward economy and fail closed if excessive. Until validated, use reward preview and dry-run claims; never ship an enabled unbalanced payout. All committed reward grants use the existing RewardGrantService.grant with unique stable transaction ID event:<instance_id>:<milestone_id>:<policy_version>. Duplicated/replayed/loaded saves never yield multiple rewards. Define configured expiration of unclaimed rewards rather than silently burning claims.

**UI:** native Godot Events page, correct L30 lock, safe HUD, 3–5 active cards in portrait scroll and upcoming entries below; card art/title/countdown/progress/claim state chosen by event ID. Current `scripts/ui/components/ui_event_card.gd` has fixed old weekly hero: migrate to per-event path with lazy texture loading, release inactive textures and keep mobile memory caps. English/Turkish localization, long label fit, touch/focus, Reduced Effects and symbols not color-only. Do not bake progress counters into hero art.

**Tutorial:** ONE reusable system across every event with 3 states: introduction uses the unique event hero + canonical robot + objective; how-to uses the REAL normal pixel-art board and event-specific metric/progress diagram (no new gameplay); reward uses authentic milestones/rank/reward path, timer, Start/Join. 24 × 3 = 72 individually testable states, not 72 huge PNG screenshots. Per-event tutorials are detailed below in the 24 event sections.

**Visual QA:** 24 separate 1024×1024 hero PNGs, 24 separate emblem PNGs, 3 race backgrounds + 2 team backgrounds + 2 reward-route decorations, and 1 standalone 1170×2532 portrait Events UI master = 56 approved production assets. No numbered stickers/labels, atlases, grids, collages, or poster crops. Only existing approved robot PNG assets as actual composited subject pixels, no synthetic new robots; each robot has exactly two arms/two hands, no fused props. Old master and Weekly hero art in GitHub are rejected anatomy references, NOT production final. Optional newer ChatGPT ZIP `scrubbots_events_master_references.zip` is NOT in GitHub and is NOT required to begin; exact legacy reference paths and optional ZIP instructions are in `docs/SCRUBBOTS_EVENTS_VISUAL_REFERENCE_INTAKE_2026-11-13.md`. Codex MUST NOT stop asking for optional master ZIP. Actual final art must be generated/QA'd/committed separately; do not misreport it as present.

**Validation and delivery:** verify 24 data definitions, event types, 3–5 rotation, stage counts/team/rivals, per-instance metric counting, first-try state, streak checkpoints, all 72 tutorial states, L29 locked/L30 enabled from fresh/imported/existing profile, idempotent economy claims, timezone/offline, no gameplay changes, all PNGs with real dimensions and canonical identity, real Godot screenshots at 720×1520 and 1170×2532, and verified remote GitHub assets. Run local Godot tests, preserve dirty checkout in separate clean worktree, update root TASKS.md by verifiable batches. No image-reference ZIP blocking, no fabricated test PASS or uploaded PNG.

## Per-event rule refinements (binding unless labeled proposal)
- **`scrub_sprint`:** 15 first-clears on NEW normal levels, one step per qualifying win, 4 simulated rivals; deterministic finish timestamp/tie-break proposal.
- **`first_brush_race`:** 3 or 5 first-ever attempt victories per configured instance against 4 virtual rivals; any first loss makes that level permanently ineligible for this event.
- **`scrubbots_royale`:** 100 contestants (player+99 virtual), five elimination stages; stage-specific first-attempt NEW-level win thresholds must be configured, never invented as owner-set.
- **`golden_brush_championship`:** 8-person bracket 8→4→2→1; player+7 virtual, compare normal new-level wins each round. Tie-break configurable.
- **`weekly_scrub_league`:** Weekly active pixels cleaned in first-cleared NEW levels only, rank against 19 virtual rivals, dedupe pixel receipts.
- **`weekly_cleanup_challenge`:** Milestones exactly 3/7/12/20 NEW normal level first-clear wins each week.
- **`perfect_first_clean`:** Milestones exactly 3/5/10 first-ever attempt normal level wins; never backfill a lost first attempt.
- **`sparkling_streak`:** 3/5/7/10 consecutive qualified wins; a loss only resets this event series to most recent checkpoint, never campaign progress.
- **`stain_busters`:** No stain minigame; count normal-level active pixels, configured numerical target after balancing; giant stain is visual only.
- **`pure_scrub_challenge`:** 3/5/10 WON normal levels with zero actually used boosters; acquiring a booster does not count as using it.
- **`scrub_squad_tournament`:** Ten-player virtual team contest based only on normal level clears, deterministic opponents and honest bot labeling.
- **`clean_team_treasure`:** Ten-player virtual team jointly accumulates normal-cleaning points to unlock existing treasury rewards.
- **`scrub_relay`:** Five-player virtual relay, visual handoff of progress stages based on normal level clears only.
- **`mega_stain_cleanup`:** Twenty-member virtual team, normal cleanup pixel totals reduce progress visualization of giant stain. 50,000 example is not approved fixed target.
- **`scrubbys_cleanup_workshop`:** Reward-path workshop decoration only, normal level clear unlocks existing SB/booster rewards; no crafting gameplay.
- **`robot_parts_recovery`:** Normal cleaned levels unlock Robot Parts via existing reward handler. No assembly minigame.
- **`lost_card_rescue`:** Normal clean levels unlock Card Packs; no scavenger/card-search gameplay.
- **`seasonal_scrub_festival`:** Halloween, Christmas and Summer variants only change theme, reward path and event calendar. No new gameplay.
- **`master_cleaner_quest`:** Requires configured objectives across multiple other Events; cross-event proof references avoid duplicate quest awards.
- **`scrub_season_pass`:** FREE season pass reward path only; regular level clean wins advance tiers. No paid premium pass in approved V02.
- **`color_scrub_rush`:** Actual cleaned pixel counts per canonical palette color; never a new color mini game.
- **`scrubbys_rescue_mission`:** Normal level wins unlock original character rescue narrative stages; no playable rescue level.
- **`world_cleanup_cup`:** 20 COMPUTER-CONTROLLED rivals plus player; global tournament is fictional rankings from legitimate cleaning scores, not a real online leaderboard.
- **`mystery_scrubbox_hunt`:** Normal level progress unlocks ScrubBox reward ceremony; no separate hunt gameplay.

## Ready-to-code decisions versus proposals
Every concrete number/threshold explicitly listed in the per-event sections is from V02. All other targets, recurrence weights, duration, AI speed, reward counts and unclaimed-expiry values are implementation proposals to be placed in explicit testable configuration, tuned through simulations, and NOT mislabeled owner-approved. Claude/Codex can autonomously implement their structure and proposed defaults without stopping; only money distribution is fail-closed until evidence supports it. This document is sufficient for coding the 24 mechanics and art pipeline; final art requires separately produced and validated PNGs, not copied screenshot mockups.


# OWNER VISUAL ADDENDUM: EVENT TUTORIALS MUST BE MULTI-STEP PHONE WALKTHROUGHS (2026-11-13)

**Owner references:** multiple screenshots of a mobile game's tutorial/coachmark sequence (Lav Serüveni and other event examples) supplied in the conversation on 2026-11-13. They establish desired **interaction and composition style**, not a permission to copy another game's game art, lava setting, avatars, screenshots, text, characters, brand, icons or exact UI. Reinterpret as original ScrubBots cleaning-themed visuals using ONLY the exact approved repo robot PNGs.

**The former fixed 3-tutorial-image rule is superseded.** The owner explicitly said 3 images are insufficient and wants multi-step, staged coachmark visuals. The new recommended production storyboard uses **6–10 standalone tutorial images per event, depending on complexity, 172 total tutorial PNGs**, alongside the original 56 heroes/icons/backgrounds/master, yielding **228 standalone PNG files**. These step counts are the visual storyboard production proposal for this owner's request, not retroactive proof that the owner approved every individual step or that any image was produced. Future Claude may reconstruct interactive tutorial screens with reusable Godot layers; **Codex's CURRENT task is ONLY image production, not coding**.

## Reference-derived visual grammar (must be applied to every walkthrough)
1. **Full portrait phone screenshot 1170×2532** for each tutorial step, consistent exact UI layout across that event's consecutive frames. Actual production design uses clean ScrubBots world, NOT lava or copied third-party backgrounds.
2. Dark translucent backdrop dims the inactive parts of the existing event screen. The **current target area remains crisp, bright, or gently highlighted**; use a cutout/spotlight overlay. Progressive focus should move across steps (header -> participants -> goal -> normal board/score -> race/progress -> rewards -> Play). Do not make the entire screen uniformly black/dim.
3. Large high-contrast **cream tutorial speech bubble** with dark navy/blue text, thick blue border and a clear triangular pointer to the targeted UI element. Place without obscuring the focus region. Use safe margins and legible Turkish reference copy; prepare the wording as data so future Claude can localize to EN/TR. Do not flatten unrelated event UI behind the bubble into illegible mock pixels.
4. Keep header, icon, panel, main illustration and next/skip/help/close conventions consistent. Show true event objects: 100 entrants/5 stages in Royale, 8 entrants/bracket in Golden Brush, 3/7/12/20 new levels in Weekly, etc. No invented unsupported goals or reward amounts.
5. Sequence behaves like a real in-game visual lesson: one clear fact per frame, one highlighted location per frame, readable human-size text, polished illustrated scenery, existing ScrubBots characters, rounded polished UI and clear progress/focus.
6. Never copy actual people from third-party example screenshots. Rival portraits must be original approved ScrubBots robots and visibly computer controlled, not real human photos. Do not copy another game's lava scenery, character art, treasure illustrations or brand. Use ScrubBots cleaning/pixel-art/park visuals.
7. Make all pictures separate genuine PNGs, NEVER a collage/atlas/sprite sheet or cutouts from a single contact sheet. Save only to the OWNER'S LOCAL DESKTOP folder, NOT GitHub, and do not edit Godot/gameplay source code.

## Tutorial production inventory

| Event # | Event | Staged tutorial PNG count | Local relative path |
|---:|---|---:|---|
| 01 | Scrub Sprint | 7 | `tutorials/scrub_sprint/` |
| 02 | First Brush Race | 7 | `tutorials/first_brush_race/` |
| 03 | ScrubBots Royale | 10 | `tutorials/scrubbots_royale/` |
| 04 | Golden Brush Championship | 9 | `tutorials/golden_brush_championship/` |
| 05 | Weekly Scrub League | 7 | `tutorials/weekly_scrub_league/` |
| 06 | Weekly Cleanup Challenge | 6 | `tutorials/weekly_cleanup_challenge/` |
| 07 | Perfect First Clean | 6 | `tutorials/perfect_first_clean/` |
| 08 | Sparkling Streak | 7 | `tutorials/sparkling_streak/` |
| 09 | Stain Busters | 6 | `tutorials/stain_busters/` |
| 10 | Pure Scrub Challenge | 6 | `tutorials/pure_scrub_challenge/` |
| 11 | Scrub Squad Tournament | 9 | `tutorials/scrub_squad_tournament/` |
| 12 | Clean Team Treasure | 7 | `tutorials/clean_team_treasure/` |
| 13 | Scrub Relay | 8 | `tutorials/scrub_relay/` |
| 14 | Mega Stain Cleanup | 7 | `tutorials/mega_stain_cleanup/` |
| 15 | Scrubby's Cleanup Workshop | 6 | `tutorials/scrubbys_cleanup_workshop/` |
| 16 | Robot Parts Recovery | 6 | `tutorials/robot_parts_recovery/` |
| 17 | Lost Card Rescue | 6 | `tutorials/lost_card_rescue/` |
| 18 | Seasonal Scrub Festival | 7 | `tutorials/seasonal_scrub_festival/` |
| 19 | Master Cleaner Quest | 8 | `tutorials/master_cleaner_quest/` |
| 20 | Scrub Season Pass | 8 | `tutorials/scrub_season_pass/` |
| 21 | Color Scrub Rush | 6 | `tutorials/color_scrub_rush/` |
| 22 | Scrubby's Rescue Mission | 8 | `tutorials/scrubbys_rescue_mission/` |
| 23 | World Cleanup Cup | 8 | `tutorials/world_cleanup_cup/` |
| 24 | Mystery ScrubBox Hunt | 7 | `tutorials/mystery_scrubbox_hunt/` |
| | **TOTAL TUTORIAL FILES** | **172** | |

Absolute output root: `C:\Users\sekip\Desktop\ScrubBots Events PNG\tutorials\`.
For each event: `tutorials/<event_id>/tutorial_01.png` through `tutorial_NN.png`, sequentially. Do not invent a GitHub output path. Required source files / exact subjects are in the V02 master and catalog. In addition to these 172 tutorial images, the pre-existing art scope remains 56, resulting in **228 individual PNGs** in the complete local art handoff. Every tutorial PNG target: 1170×2532 portrait. Tutorial screens may share background/asset layers conceptually but each must be a standalone composed visual representing an individual focus step.

## Event-by-event tutorial storyboards

### 01. Scrub Sprint (7 tutorial images)
1. `tutorial_01.png`: Yarış pistindeki 5 ScrubBots avatarı ve başlangıç çizgisinin tanıtımı.
2. `tutorial_02.png`: 4 bilgisayar rakibini ve kendi profilini ayrı ayrı vurgula.
3. `tutorial_03.png`: 15 yeni seviye hedefini okla göster.
4. `tutorial_04.png`: Gerçek piksel temizleme seviyesi -> pistte +1 ilerleme göster.
5. `tutorial_05.png`: Rakip ilerleme çubuklarını, öne geçme/geride kalmayı öğret.
6. `tutorial_06.png`: Bitiş çizgisi ve etkinlik sonucu anlatımı.
7. `tutorial_07.png`: Ödüller, etkinlik süresi ve PLAY yönlendirmesi.

### 02. First Brush Race (7 tutorial images)
1. `tutorial_01.png`: İlk fırça yarışı ve 5 katılımcının tanıtımı.
2. `tutorial_02.png`: Gerçek normal seviyede ilk denemenin işaretlenmesi.
3. `tutorial_03.png`: İlk seferde kazanılırsa sayaca +1 eklendiğini göster.
4. `tutorial_04.png`: Başarısız ilk denemenin puan kazandırmadığını açıkla.
5. `tutorial_05.png`: 3 veya 5 galibiyet hedefinin seçilmiş etkinlik örneği.
6. `tutorial_06.png`: Rakip sıralaması, süre ve finiş mantığı.
7. `tutorial_07.png`: Ödül ve PLAY yönlendirmesi.

### 03. ScrubBots Royale (10 tutorial images)
1. `tutorial_01.png`: ScrubBots Royale arena teması, oyuncu + 99 sanal yarışmacı.
2. `tutorial_02.png`: 100 katılımcı kartını ve sanal rakip etiketini vurgula.
3. `tutorial_03.png`: Beş eleme turunun genel şeması.
4. `tutorial_04.png`: 1. elemenin şartı ve tur ilerlemesinin gösterimi.
5. `tutorial_05.png`: Gerçek normal pixel-art tahtasında ilk deneme galibiyeti.
6. `tutorial_06.png`: Birinci tur sonunda kalan/eliminated katılımcı sayısı.
7. `tutorial_07.png`: İkinci-üçüncü tur geçişleri ve eşik göstergeleri.
8. `tutorial_08.png`: Dördüncü tur ve final turu yolu.
9. `tutorial_09.png`: Kalan oyuncular, sıralama/sonuç ve kurallar.
10. `tutorial_10.png`: Ödül dağılımı, zaman sayacı ve başla butonu.

### 04. Golden Brush Championship (9 tutorial images)
1. `tutorial_01.png`: Altın Fırça kupası ve 8 kişilik turnuva tanıtımı.
2. `tutorial_02.png`: Oyuncu ve 7 bilgisayar rakibinin tanıtımı.
3. `tutorial_03.png`: Çeyrek final 8->4 turnuva şeması.
4. `tutorial_04.png`: Gerçek pixel-art temizlemesiyle tur puanı kazanımı.
5. `tutorial_05.png`: Eşitlik/sonuç ve yarı finale geçiş.
6. `tutorial_06.png`: Yarı final 4->2 eşleşmesi.
7. `tutorial_07.png`: Final 2->1 eşleşmesi ve kazanan kupa töreni.
8. `tutorial_08.png`: Ödül tablosu ve süre.
9. `tutorial_09.png`: PLAY/katılma yönlendirmesi.

### 05. Weekly Scrub League (7 tutorial images)
1. `tutorial_01.png`: Haftalık lig ve 20 kişilik sıralama panosu.
2. `tutorial_02.png`: 19 sanal rakip ve oyuncu ayrımı.
3. `tutorial_03.png`: YENİ seviyelerde temizlenen piksel puanı gösterimi.
4. `tutorial_04.png`: Gerçek oynanıştan temizlenen aktif piksel sayısı örneği.
5. `tutorial_05.png`: Ligde sıralama değişiminin vurgulanması.
6. `tutorial_06.png`: Haftalık süre ve dönem sıfırlama açıklaması.
7. `tutorial_07.png`: Ödül ve PLAY yönlendirmesi.

### 06. Weekly Cleanup Challenge (6 tutorial images)
1. `tutorial_01.png`: Haftalık temizlik etkinliği ve dört ödül basamağı.
2. `tutorial_02.png`: Yeni bir normal temizleme seviyesi galibiyetinin sayılması.
3. `tutorial_03.png`: 3/7/12/20 kilometre taşlarının artışı.
4. `tutorial_04.png`: Tamamlanan basamağın işaretlenmesi, kilitli sıradaki basamak.
5. `tutorial_05.png`: Gerçek ödül simgeleri ve hak ediş gösterimi.
6. `tutorial_06.png`: Haftalık süre ve PLAY yönlendirmesi.

### 07. Perfect First Clean (6 tutorial images)
1. `tutorial_01.png`: İlk denemede mükemmel temizlik rozeti.
2. `tutorial_02.png`: Normal seviye başlangıcında ilk deneme işareti.
3. `tutorial_03.png`: İlk galibiyetle 3/5/10 sayaç artışı.
4. `tutorial_04.png`: Başarısız ilk denemede ilerleme olmaması.
5. `tutorial_05.png`: Ödül basamakları ve son tarih.
6. `tutorial_06.png`: PLAY yönlendirmesi.

### 08. Sparkling Streak (7 tutorial images)
1. `tutorial_01.png`: Temizlenen park yolu ve parlak seri aşamaları.
2. `tutorial_02.png`: Normal seviyede kazanılan bir seri yıldızı.
3. `tutorial_03.png`: 3/5/7/10 kontrol noktası yolu.
4. `tutorial_04.png`: Kazanma sonrası ileri hareket ve tamamlanan kontrol noktası.
5. `tutorial_05.png`: Kaybedince SADECE etkinlik serisinin checkpoint'e dönmesi.
6. `tutorial_06.png`: Ana oyun ilerlemesinin etkilenmediğinin açıklanması.
7. `tutorial_07.png`: Ödül yolu ve PLAY.

### 09. Stain Busters (6 tutorial images)
1. `tutorial_01.png`: Büyük kirli piksel resmi ve hedef sayaç.
2. `tutorial_02.png`: Normal oyunda gerçek aktif piksellerin temizlenmesi.
3. `tutorial_03.png`: Etkinlik sayaç dolumunun görüntülenmesi.
4. `tutorial_04.png`: Arka plan/VOID piksellerin sayılmadığı örnek.
5. `tutorial_05.png`: Ödül eşikleri.
6. `tutorial_06.png`: PLAY ve etkinlik saati.

### 10. Pure Scrub Challenge (6 tutorial images)
1. `tutorial_01.png`: Booster kullanmadan temizlik meydan okuması.
2. `tutorial_02.png`: Gerçek normal oyun tahtasında boosterların vurgulanması.
3. `tutorial_03.png`: Booster kullanmadan galibiyet ve +1.
4. `tutorial_04.png`: Booster kullanıldığında seviyenin etkinliğe sayılmaması.
5. `tutorial_05.png`: 3/5/10 hedef ve ödül yolu.
6. `tutorial_06.png`: PLAY ve süre.

### 11. Scrub Squad Tournament (9 tutorial images)
1. `tutorial_01.png`: 10 üyeli sanal temizlik takımı tanıtımı.
2. `tutorial_02.png`: Sanal robot arkadaşların açık etiketlenmesi.
3. `tutorial_03.png`: İki takımın puan karşılaştırması.
4. `tutorial_04.png`: Normal seviye galibiyetinden takım puanına geçiş.
5. `tutorial_05.png`: Oyuncunun bireysel katkısının gösterilmesi.
6. `tutorial_06.png`: Diğer sanal üyelerin bağımsız katkıları.
7. `tutorial_07.png`: Sıralama/karşılaşma turu.
8. `tutorial_08.png`: Ödül ve kazanma koşulu.
9. `tutorial_09.png`: PLAY ve zaman.

### 12. Clean Team Treasure (7 tutorial images)
1. `tutorial_01.png`: 10 kişilik sanal temizleme ekibi ve ortak sandık.
2. `tutorial_02.png`: Gerçek normal seviyenin takım puanı üretmesi.
3. `tutorial_03.png`: Takım üyelerinin ortak katkı gösterimi.
4. `tutorial_04.png`: Toplanan puanla dolan hazine yolu.
5. `tutorial_05.png`: Ödül sandığı kilidinin açılması.
6. `tutorial_06.png`: Zaman ve kurallar.
7. `tutorial_07.png`: PLAY.

### 13. Scrub Relay (8 tutorial images)
1. `tutorial_01.png`: 5 sanal ekip üyesi ve temizlik bayrağı.
2. `tutorial_02.png`: Etap 1 aktif robotun gösterilmesi.
3. `tutorial_03.png`: Normal level WIN sonrası etap artışı.
4. `tutorial_04.png`: Bayrağın sıradaki robota geçmesi: SADECE görsel.
5. `tutorial_05.png`: Takım katkılarının gösterilmesi.
6. `tutorial_06.png`: Son etap ve finiş görselleştirmesi.
7. `tutorial_07.png`: Kazananların sonuç ekranı.
8. `tutorial_08.png`: Ödül / PLAY.

### 14. Mega Stain Cleanup (7 tutorial images)
1. `tutorial_01.png`: 20 kişilik sanal ekip, dev kirli panonun tanıtımı.
2. `tutorial_02.png`: Temizlenmesi gereken büyük kir miktarının gösterimi.
3. `tutorial_03.png`: Gerçek normal seviyede temizlenen aktif pikseller.
4. `tutorial_04.png`: Ekip katkıları ve dev kir göstergesinin azalması.
5. `tutorial_05.png`: Dev kirli resmin ayrı oynanabilir tahta olmadığının açıklaması.
6. `tutorial_06.png`: Hedefe varış ve kazanma anı.
7. `tutorial_07.png`: Ödül ve PLAY.

### 15. Scrubby's Cleanup Workshop (6 tutorial images)
1. `tutorial_01.png`: Scrubby'nin temizlik atölyesi tanıtımı.
2. `tutorial_02.png`: Atölyenin sadece ödül ilerleme ekranı olduğunun gösterimi.
3. `tutorial_03.png`: Normal seviye kazanımıyla basamak artışı.
4. `tutorial_04.png`: Atölyedeki ödül simgelerinin açılması.
5. `tutorial_05.png`: Ödül teslim görselleştirmesi.
6. `tutorial_06.png`: PLAY ve süre.

### 16. Robot Parts Recovery (6 tutorial images)
1. `tutorial_01.png`: Kaybolan robot parçaları teması.
2. `tutorial_02.png`: Normal temizlik seviyesinin tamamlanması.
3. `tutorial_03.png`: Robot Parts sayaç ilerlemesi.
4. `tutorial_04.png`: Parça ödülü kazanma ve koruma.
5. `tutorial_05.png`: Ödül yolu / hedef.
6. `tutorial_06.png`: PLAY.

### 17. Lost Card Rescue (6 tutorial images)
1. `tutorial_01.png`: Kayıp kart paketlerinin tanıtımı.
2. `tutorial_02.png`: Normal level WIN ve etkinlik puanı.
3. `tutorial_03.png`: Kayıp kart paketinin ilerleme çizgisi.
4. `tutorial_04.png`: Kart paketi ödülünün açılması.
5. `tutorial_05.png`: Koleksiyon uyumluluğunun belirtilmesi.
6. `tutorial_06.png`: PLAY.

### 18. Seasonal Scrub Festival (7 tutorial images)
1. `tutorial_01.png`: Mevsim temalı park ve festival etkinliği.
2. `tutorial_02.png`: Mevsim varyantı rozeti (Halloween/Christmas/Summer).
3. `tutorial_03.png`: Normal temizleme seviyesi ile katılım.
4. `tutorial_04.png`: Temalı hedef ve puan yolu.
5. `tutorial_05.png`: Sezonluk etkinlik takvimi.
6. `tutorial_06.png`: Mevsimsel ödül vitrini.
7. `tutorial_07.png`: PLAY.

### 19. Master Cleaner Quest (8 tutorial images)
1. `tutorial_01.png`: Usta Temizlikçi görevi, çoklu etkinlik haritası.
2. `tutorial_02.png`: Bağlı etkinliklerin ayrı hedefleri.
3. `tutorial_03.png`: Birinci etkinlikten doğrulanmış katkı.
4. `tutorial_04.png`: İkinci etkinlik hedefinin ayrı tamamlanması.
5. `tutorial_05.png`: Çoklu hedeflerin birleşerek ana görevi ilerletmesi.
6. `tutorial_06.png`: Tamamlanmamış hedefte ödül kilidinin gösterimi.
7. `tutorial_07.png`: Büyük sandık final ödülü.
8. `tutorial_08.png`: PLAY / ilgili etkinliğe git.

### 20. Scrub Season Pass (8 tutorial images)
1. `tutorial_01.png`: Ücretsiz sezon yolu tanıtımı.
2. `tutorial_02.png`: Sezon süresi ve bölüm dağılımı.
3. `tutorial_03.png`: Normal level WIN ile sezon puanı.
4. `tutorial_04.png`: İlk ödül basamağı açılması.
5. `tutorial_05.png`: İleri basamaklarda kilitli ödüller.
6. `tutorial_06.png`: Sezon yolunda ilerleme animasyonu.
7. `tutorial_07.png`: Ücretsiz olduğu, ücretli yol bulunmadığı bilgisi.
8. `tutorial_08.png`: PLAY.

### 21. Color Scrub Rush (6 tutorial images)
1. `tutorial_01.png`: Renkli pixel-art teması ve renk hedefleri.
2. `tutorial_02.png`: Normal oyundaki renkli pikselleri vurgula.
3. `tutorial_03.png`: Bir renk temizlendiğinde ilgili sayaç doluyor.
4. `tutorial_04.png`: Farklı renklerin bağımsız sayaçları.
5. `tutorial_05.png`: Hedef renk eşikleri / tamamlanan renk.
6. `tutorial_06.png`: Ödül ve PLAY.

### 22. Scrubby's Rescue Mission (8 tutorial images)
1. `tutorial_01.png`: Scrubby kurtarma hikâyesi kapağı.
2. `tutorial_02.png`: Onaylı kayıp robot karakterin gösterimi.
3. `tutorial_03.png`: Normal seviye galibiyetinin hikâye ilerlemesine dönüşmesi.
4. `tutorial_04.png`: İlk hikâye bölümünün açılması.
5. `tutorial_05.png`: Bir sonraki kurtarma kilometre taşı.
6. `tutorial_06.png`: Kurtarma mini oyunu olmadığı, yalnızca hikâye ilerlemesi.
7. `tutorial_07.png`: Kurtarma sonucu ve kanonik karakter görüntüsü.
8. `tutorial_08.png`: Ödül ve PLAY.

### 23. World Cleanup Cup (8 tutorial images)
1. `tutorial_01.png`: Dünya temizlik kupası ve oyuncu +20 sanal rakip.
2. `tutorial_02.png`: Gerçek çevrimiçi liderlik olmadığını açıkça belirt.
3. `tutorial_03.png`: Kıtalar/ülkeler temalı sanal eşleşme panosu.
4. `tutorial_04.png`: Normal seviyede temizlik skorunun üretilmesi.
5. `tutorial_05.png`: Puanın sanal dünya sıralamasına eklenmesi.
6. `tutorial_06.png`: Sıralama yükselişi ve yarışma sonucu.
7. `tutorial_07.png`: Kupa ödül sahnesi.
8. `tutorial_08.png`: PLAY ve süre.

### 24. Mystery ScrubBox Hunt (7 tutorial images)
1. `tutorial_01.png`: Gizemli ScrubBox sandıkları tanıtımı.
2. `tutorial_02.png`: Normal temizlik seviyeleri ile ilerleme.
3. `tutorial_03.png`: Kilidi açılacak ilk sandık sayacı.
4. `tutorial_04.png`: Sandığın ilerlemeyle açılması.
5. `tutorial_05.png`: Büyük/özel sandık aşamalarının gösterimi.
6. `tutorial_06.png`: Ödül dağılımı.
7. `tutorial_07.png`: PLAY ve süre.

## Quality acceptance per tutorial
- Files 1170x2532 PNG, title spelled exactly, no event index printed, 24 event subfolders, count matches table. Explicit check that 172 is count of separate visuals, not just conceptual states.
- Within each event the background, layout, robot identities and progress baseline remain consistent across frames; only spotlight/callout/illustrated game progress changes as directed.
- Every one shows correct target UI emphasis and one coachmark speech bubble readable at phone scale. Text cannot leave bounds or cover target. Minimal repetitive slides; every step explains new information.
- Use the normal pixel-art cleaning board as the gameplay illustration; race tracks/volcano/treasure settings are UI metaphors ONLY. Never depict another playable mechanic.
- Use canonical approved original robot art with correct anatomy. No new robots; no human photos, copied third-party screenshots or copyrighted characters from example imagery.
- These reference screenshots remain **visual art outputs only**. Codex is NOT to code the tutorials, modify the repo, update TASKS.md or upload generated images to GitHub.
