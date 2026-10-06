# M43-C015R — OWNER RUNTIME REVIEW REMEDIATION V01 — MASTER CLAUDE PROMPT

Status: **READY FOR CLAUDE**
Date: 2026-10-06
Repository: `Sekiph82/Scrubbots`
Owner-local checkout: `C:\Users\sekip\Desktop\ScrubBots`
Canonical tracker: root `TASKS.md` — **READ ONLY FOR CLAUDE**

This is one uninterrupted three-child remediation cycle created from the owner's live F5 review on 2026-10-06.

Children:
1. `SB-M43-R15-001` — Rewarded Ads daily five-slot surface
2. `SB-M43-R15-002` — Settings visual-family remediation
3. `SB-M43-R15-003` — Daily Rewards containment remediation

Do all three in order. Do not stop between children unless a genuine owner/provider authority blocker makes the next child unsafe. Write one Claude log per child plus one master handoff log.

## OWNER DECISION — SOURCE OF TRUTH

The owner reviewed the live F5 screens and said every shown screen is OK except:
- Daily Rewards composition: art protrudes outside the intended table/popup bounds;
- Settings: the generic dark panel is visually unacceptable and must match the SCRUBBOTS UI language.

The owner also adds one new surface:
- a separate **REWARDED ADS** button/surface;
- five rewards every local calendar day;
- reward slot 1 is immediately claimable with no ad;
- reward slots 2, 3, 4 and 5 each require one successfully completed rewarded ad before that slot is granted.

This does **not** replace the existing Daily consecutive-login popup. Daily remains a separate feature and must only receive the containment fix described below.

The owner's supplied screenshots show the accepted visual family: cyan/white mechanical popup frame, cream/white interior, royal-blue title plaque, navy text, green primary CTA, tan secondary CTA, top-right X where applicable, strong touch targets, and consistent robot-world presentation.

# 0. FIRST ACTION — NON-DESTRUCTIVE SYNC

Before implementation:

1. Work from `C:\Users\sekip\Desktop\ScrubBots`.
2. Run `git status --short`.
3. `git fetch origin main --prune`.
4. Inspect local HEAD versus `origin/main`.
5. Preserve all owner-local work, especially:
   - `project.godot`;
   - `scenes/app/main.tscn`;
   - `addons/`;
   - owner-review metadata/evidence;
   - unrelated untracked files.
6. Synchronize with current `origin/main` non-destructively. No reset, clean, force checkout, or owner-file overwrite.
7. Root `TASKS.md` is read-only. ChatGPT is its sole lifecycle writer.

If synchronization cannot be completed without risking owner-local work, STOP and report the exact paths/conflict.

# 1. SB-M43-R15-001 — REWARDED ADS DAILY FIVE-SLOT SURFACE

## 1.1 Home entry

Keep the owner-locked four primary Home panels exactly:
- SHOP
- COLLECTION
- TASKS
- DAILY

Do **not** turn Home into five equal panels.

Add one compact auxiliary `REWARDED ADS` CTA associated visually with the DAILY/right-side area. It should read as an extra reward/ad action, not a fifth primary destination. It must:
- use the existing SCRUBBOTS Home/M43 visual language;
- remain readable/tappable at phone sizes;
- never overlap PLAY, Gift Meter, BottomNav, Daily or the world hero;
- emit an intent only; no economy mutation in Home code.

Use existing/native visual language where possible. Do not generate or introduce a speculative asset library just for this button. A native play/video glyph is acceptable if it matches the current acquisition UI.

## 1.2 Rewarded Ads popup

Create one canonical M43/BasePopup-family surface titled **REWARDED ADS**.

It shows exactly five reward slots for the current LOCAL calendar day:
- Slot 1: `CLAIM`
- Slots 2-5: `WATCH AD`
- After successful grant: `CLAIMED`

All five reward values are config-driven and shown before the user acts.

### V1 reward bundles

Do not invent new reward values.

Seed the new rewarded-daily config from the five already owner-approved/current Daily D1-D5 bundles in `data/config/economy_rewards_v1.json`:

1. 100 SB
2. Standard Card Pack x1
3. Random Booster Charge x1
4. 250 SB + Standard Card Pack x1
5. 300 SB + Selected Booster Charge x1 + Premium Card Pack x1

These become a **distinct Rewarded Ads daily track**. Do not alias their claim state to the existing login streak and do not remove/change the current Daily D1-D5 cycle.

Store the new bundles in a distinct versioned/config section, not hardcoded in UI.

## 1.3 Authority / idempotency

Reuse the existing provider-neutral rewarded-video architecture:
- `RewardedAdProvider`
- `RewardedGrantService`
- canonical `RewardGrantService`

Do **not** create a second raw video-callback→reward authority.

Extend the existing rewarded authority narrowly enough to support the new daily slot offers while preserving all existing Heart/booster behavior.

Required deterministic grant identity:
- `daily_rewarded:<local_day>:1`
- ...
- `daily_rewarded:<local_day>:5`

Slot 1:
- no ad request;
- exactly-once direct grant for that local day.

Slots 2-5:
- one logical placement each, e.g. `rewarded_daily_slot_2` ... `rewarded_daily_slot_5`;
- grant only after provider outcome `completed` AND `verified == true`;
- cancellation, skip, failure, timeout, unverified callback, provider refusal/unavailable, unknown token, duplicate callback: **grant nothing**;
- provider token identity must not be the economy idempotency identity;
- a second callback/request cannot duplicate a previously granted slot.

The production default provider must remain honestly unavailable until M57 selects/maps a real SDK/provider. Do not fake an ad in shipping/F5 production. The UI may show the four `WATCH AD` actions but must disable/degrade cleanly when the provider is unavailable.

For automated/runtime evidence, inject the existing provider double/test seam. Do not wire a fake provider into production.

## 1.4 Local-day safety

The five-slot availability resets once per forward LOCAL calendar day.

Clock/local-day rollback must not reopen prior-day rewards or create farmable days. Persist/reconstruct a safe high-water authority compatible with existing M40 saves. Migration from old saves must be explicit and fail safe.

The new feature must not change:
- Daily login streak/reset/cycle;
- Daily Scrub Orders;
- Gift Meter source rules;
- card-pack RNG;
- Hearts/boosters/2x behavior.

## 1.5 Presentation

Use the approved M43 popup family. Five reward cards must be contained, readable, and responsive.

Each slot visibly distinguishes:
- ready free claim;
- ready rewarded-video action;
- pending/loading;
- claimed;
- ad unavailable;
- failure/cancel without false success.

Do not imply reward success before the verified callback and durable grant/save boundary.

# 2. SB-M43-R15-002 — SETTINGS VISUAL-FAMILY REMEDIATION

Current behavior authority is already closed under M41 and must remain unchanged:
- Master volume
- Music volume
- SFX volume
- Haptics/Vibration
- Reduced Effects
- persistence
- live application

The defect is presentation only: the current generic dark rectangle does not belong beside the accepted M43 screens.

## Required look

Restyle `SettingsPanel` so it reads as the same game:
- cyan/white mechanical outer frame or the canonical equivalent already used by `BasePopup`;
- cream/white inner content;
- royal-blue `SETTINGS` title plaque;
- navy readable labels;
- themed sliders;
- themed ON/OFF controls;
- canonical top-right X and/or accepted close treatment;
- touch targets consistent with the existing popup family.

Prefer reusing:
- `BasePopup`
- `HomeStyle`
- `UiTokens`
- approved existing frame/button assets

over inventing a separate Settings theme.

Architectural rule:
- do not create a second settings authority;
- do not rewrite AudioSettingsService/HapticsSettingsService/EffectsSettingsService semantics;
- no settings value may change merely because the screen was reskinned;
- Settings remains the canonical Settings destination.

Preserve keyboard/back/close behavior and live slider/toggle semantics.

# 3. SB-M43-R15-003 — DAILY REWARDS CONTAINMENT REMEDIATION

The owner accepts the feature and reward truth. Do not redesign the economy.

Preserve:
- consecutive-login count;
- existing repeating D1-D5 cycle;
- D1-D5 configured rewards;
- one claim per eligible local day;
- reset/rollback safety;
- reward celebration;
- current claim authority.

Fix only layout/presentation.

## Owner-observed defect

In the live F5 Daily Rewards popup, Daily-specific art extends outside the intended table/popup composition. In particular, the popup must no longer use a hero treatment that visibly floats outside the accepted Daily frame/table if that is what causes the overflow.

Required:
- calendar/reward hero is contained inside the popup's intended content/frame;
- streak flame is contained;
- all five day-card frames remain contained;
- check/state art remains inside its card;
- reward text never clips;
- rule text and CLAIM/CLOSE actions never overlap the card grid;
- nothing protrudes beyond the Daily popup/frame at the owner's observed embedded runtime size **683x1366**.

Also validate:
- 720x1280 portrait;
- 1080x1920;
- 1080x2160;
- 1170x2532;
- 1290x2796;
- 1536x2048 tablet.

Do not "fix" this by scaling the whole application down into a tiny panel. Keep touch/readability standards.

Tasks and Gift Bar must not regress.

# 4. TEST / EVIDENCE MATRIX

Use Godot 4.7.2.

At minimum add focused coverage for:

### Rewarded Ads
- exactly five slots;
- slot 1 free claim once/day;
- slots 2-5 require verified completed ad;
- each slot exactly once/day;
- provider unavailable grants nothing;
- cancel/skip/fail/timeout/unverified grant nothing;
- duplicate/late callback grants nothing;
- local-day forward reset;
- rollback does not reopen rewards;
- relaunch persistence/idempotency;
- slot reward text equals config;
- existing Heart/booster rewarded tests unchanged;
- existing Daily login and Daily Scrub Orders unchanged.

### Settings
- all five existing settings still bind canonical state;
- live audio/haptics/reduced behavior unchanged;
- persistence/relaunch tests remain PASS;
- new themed nodes exist and raw generic dark-panel presentation is gone;
- responsive geometry stays inside safe area.

### Daily containment
- geometry assertion that every Daily-specific art/control rect is contained in its intended popup/content frame at the required size matrix;
- no overlap between card grid and action area;
- existing Daily claim/state tests remain PASS.

Run:
1. new focused R15 suite(s);
2. `tests/m41_settings.gd`;
3. `tests/m39d_daily_collection.gd`;
4. `tests/m43_master_c009_daily.gd`;
5. existing M43 acquisition/rewarded suite(s);
6. `tests/run_tests.gd`;
7. `git diff --check`.

No unexplained `SCRIPT ERROR`.

# 5. OWNER EVIDENCE

Produce fresh runtime captures from the final tree for:
- Home showing the new compact REWARDED ADS CTA;
- Rewarded Ads fresh day, slot 1 ready;
- Rewarded Ads after slot 1 claimed;
- Rewarded Ads with injected test provider showing slots 2-5 WATCH AD;
- one verified ad slot claimed;
- provider-unavailable production state;
- Settings at 683x1366 and 1080x2160;
- Daily Rewards fixed at 683x1366 and 1080x2160.

The test-provider capture must be clearly labeled test/evidence only and must not imply a production ad SDK exists.

# 6. LOGGING / PUSH

Write:
- `coordination/sessions/M43-OWNER-R15/SB-M43-R15-001_CLAUDE_LOG_V01.md`
- `coordination/sessions/M43-OWNER-R15/SB-M43-R15-002_CLAUDE_LOG_V01.md`
- `coordination/sessions/M43-OWNER-R15/SB-M43-R15-003_CLAUDE_LOG_V01.md`
- `coordination/sessions/M43-OWNER-R15/M43_OWNER_R15_MASTER_CLAUDE_LOG_V01.md`

Each child log must record:
- files changed;
- architecture/authority preserved;
- focused tests;
- evidence paths;
- exact commit SHA;
- remaining owner/provider gates.

Push to `main` if permitted. If not permitted, push one branch and report exact branch/SHA/ahead-behind plus one clean fast-forward/cherry-pick instruction.

Root `TASKS.md` remains untouched by Claude.

Finish the master log exactly:

`AWAITING_GPT_M43_OWNER_R15_V01_AUDIT`
