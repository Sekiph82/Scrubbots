# M43-C005-C001 — CEREMONY VISUAL MASTER GATE

Status: READY FOR CLAUDE
Date: 2026-10-02
Repository: `Sekiph82/Scrubbots`
Branch: `main`
Primary roadmap row: **SB-M43-076**
Preparation for: SB-M43-063..075, SB-M43-077 and the downstream SB-M43-013 handoff.

Do not edit root `TASKS.md`. ChatGPT owns tracker state.

## Mission

Before production ceremony implementation, satisfy the owner-locked visual-production rule for M43-C005.

Create a coherent, responsive **ceremony visual-master candidate family** using the project's existing approved art and live/native Godot UI. This cycle is for visual masters, asset inventory and screenshot evidence only.

Do **not** wire production reward grants, pack opening, robot unlocking, world unlocking or feature pacing in this cycle.

The owner must visually approve this family before Claude receives the production implementation prompt.

## Read first

1. `CLAUDE.md`
2. root `TASKS.md` READ ONLY
3. `coordination/AUDIT_POLICY.md`
4. `coordination/OWNER_REWARD_CEREMONY_FEATURE_UNLOCK_V01.md`
5. `coordination/OWNER_PLAYER_EXPERIENCE_SURFACE_PROGRAM_V01.md`
6. `coordination/OWNER_ECONOMY_REWARDS_V01.md`
7. `coordination/OWNER_ROBOT_ROSTER_V01.md`
8. `coordination/OWNER_META_NAVIGATION_AND_DESTINATIONS_V01.md`
9. `data/config/economy_rewards_v1.json`
10. `assets/ui/PLAYER_EXPERIENCE_ASSET_MANIFEST.json`
11. accepted M43-C001B Results visual authority and final owner acceptance
12. accepted M43-C002 popup family owner gate
13. accepted M43-C001R V02 final owner acceptance
14. current collection/robot/reward assets and manifests
15. current card/pack/collection/robot/gift services only to understand truthful fields; do not mutate them.

## Current authoritative product facts

### Pack opening
- Standard Pack = exactly 3 draws.
- Premium Pack = exactly 5 draws.
- Premium guarantees at least one Rare-or-better in authoritative pack logic.
- Duplicates are allowed.
- Presentation must show actual rarity and NEW/DUPLICATE truth after contents are already committed.
- Presentation never rerolls.

### Collection completion
- 15 sets × 9 cards.
- Set completion rewards come from the authoritative config and vary by set.
- Master completion reward = +2500 SB +20 Bot Parts exactly once.
- Presentation celebrates committed truth only.

### Robot unlock
- canonical roster has 10 robots;
- Scrubby starts unlocked;
- every later robot costs 250 Bot Parts;
- Robot unlock ceremony shows identity, personality/role, canonical perk and remaining Bot Parts;
- player may equip new robot or keep current robot;
- do not implement equip/unlock action here.

### Gift Meter
- milestones: 10 / 50 / 250 / 500 / 1000;
- milestone reward bundles are authoritative config truth;
- this cycle designs the ceremony only, not claim/grant behavior.

### Feature unlock
- ceremony appears once per feature/version eventually;
- exact campaign unlock levels are still owner-tuning-required;
- do not invent unlock levels.

### World unlock
- future world ranges/unlock conditions are owner-required later;
- no hardcoded ranges;
- no future world artwork may be invented;
- this cycle may design a generic **world-transition shell** with an explicit live world-art slot, but may not imply a real World 02 or its range.

## Visual family direction

Use the accepted SCRUBBOTS UI language rather than inventing a disconnected style:

- cream panel + royal/cyan frame family where suitable;
- strong readable mobile hierarchy;
- native/live labels and quantities;
- green primary CTA where an action exists;
- cream/secondary action where appropriate;
- existing approved reward/card/robot art;
- 60% scrim for modal ceremonies where consistent with existing popup family;
- playful celebratory motion may be proposed, but Reduced Effects must have an immediate/static counterpart;
- no flattened interactive screenshot as shipping UI.

Do not regenerate existing owner-approved art.

If a required illustration genuinely does not exist, first inventory it. Do not fabricate a final asset merely to avoid an owner gate.

## A. Required visual-master candidates

Create all of the following candidates in a dedicated preview/evidence harness. These are **not** production-wired screens.

### 1. Standard Card Pack opening
Required visual truth:
- Standard Pack art;
- exactly 3 revealed cards;
- each card shows actual rarity;
- each card visibly distinguishes NEW vs DUPLICATE;
- no fake rarity odds, no jackpot/near-miss language;
- skip/fast-forward affordance may be shown only if it clearly cannot change contents/grants.

Use real existing card frame/card art wherever available.

### 2. Premium Card Pack opening
Required visual truth:
- Premium Pack art;
- exactly 5 revealed cards;
- rarity visible per card;
- at least one sample Rare-or-better in the visual fixture so hierarchy is reviewable;
- NEW/DUPLICATE distinction;
- do not show “guaranteed rare” as a fake extra reward after the fact;
- no reroll button.

### 3. Collection Set Complete
Required:
- Collection complete emblem;
- set name/number;
- 9/9 complete truth;
- live reward rows for that set's configured SB + Bot Parts;
- one Continue/Collect-equivalent presentation action only if it does not imply the grant happens on tap;
- clearly state reward is already secured/committed if needed to avoid ambiguity.

Use a representative real set fixture from config.

### 4. Master Collection Complete
Required:
- Master Collection emblem;
- strong one-time completion hierarchy;
- exact +2500 SB +20 Bot Parts;
- no invented bonus/reward.

### 5. Robot Unlock
Use **Moppy** as the visual fixture unless a stronger reason from existing asset availability requires another canonical robot.

Required:
- canonical robot art;
- robot name;
- role/personality;
- canonical perk text;
- remaining Bot Parts;
- two clear actions in the candidate:
  - EQUIP
  - KEEP CURRENT / CONTINUE
- no gameplay-solvability implication.

Do not actually unlock/equip in the preview harness.

### 6. Gift Meter Milestone
Create at least two states:
- a smaller milestone, preferably 50 or 250;
- the 1000 milestone.

Required:
- milestone identity;
- exact configured reward bundle;
- Gift/Reward art from existing final assets;
- no new reward threshold or jackpot framing.

### 7. Generic Feature Unlock
Required:
- feature icon/art slot;
- feature name;
- concise explanation;
- clear CTA such as GOT IT / TRY IT only as a visual candidate;
- optional NEW badge semantics;
- **no campaign level number** because exact pacing remains owner-blocked.

Use an existing shipping feature as a fixture label if useful, but clearly mark fixture/test data and do not alter its real unlock policy.

### 8. Generic World Unlock / Transition shell
Design only a reusable shell:
- live world title slot;
- live world art/background slot;
- transition/Continue CTA;
- optional area subtitle slot;
- no hardcoded level range;
- no invented World 02 name;
- no fabricated future world background.

For evidence, the art slot may use the existing World 01 image clearly labeled as **PREVIEW HARNESS / SHELL TEST ONLY**, or a neutral framed placeholder. It must not claim World 01 is newly unlocked in production.

### 9. Generic short reward ceremony
Create a compact reusable reward-confirmation candidate usable later by:
- Daily reward;
- Tasks 3/3 completion;
- small generic reward events.

Required:
- title;
- 1–4 reward rows/chips;
- native amounts;
- single Continue;
- visually subordinate to the major pack/robot/master ceremonies.

This is visual preparation for SB-M43-063/075, not production implementation.

## B. Visual-master harness constraints

Create an isolated preview/test harness under tests/tools or coordination-supported tooling.

It must:
- instantiate real native Godot Controls;
- bind only fixture/read-only dictionaries;
- mutate no AppState/economy/progression/save state;
- never call pack opening, collection add_card, robot unlock, Gift claim, Daily claim or RewardGrantService;
- never edit production save;
- be removable/isolated from shipping runtime.

Use real existing textures.

No production route/navigation entry is added in this cycle.

## C. Asset inventory

Create:
`coordination/sessions/M43-C005-C001/CEREMONY_ASSET_INVENTORY_V01.md`

For each candidate list:
- required existing art;
- exact paths;
- whether present;
- whether owner-approved/final;
- any missing component art;
- whether the candidate can be constructed entirely from native chrome + existing final art.

Specifically inspect:
- `assets/ui/final/rewards/`
- `assets/ui/final/collection/`
- `assets/ui/final/collection/cards/`
- `assets/ui/final/robots/`
- `assets/ui/final/characters/robots/`
- popup/family art already accepted.

Do not silently create replacement art for missing pieces.

## D. Player Experience manifest

Do not mark any ceremony `MASTER_OWNER_APPROVED` yourself.

You may update only objective inventory/reference fields if the manifest structure safely supports it.

If doing so would conflate candidate and owner approval, leave the manifest unchanged and document proposed status transitions in the review file.

## E. Responsive evidence

Render fresh evidence for the candidate family.

At minimum:
- 1080x1920
- 1080x2160
- 1170x2532
- 1290x2796
- 1536x2048

You do not need every surface at every size if the shared frame/layout family is proven across the matrix, but:
- Standard Pack
- Premium Pack
- Robot Unlock
- Set Complete
- Master Complete
- Gift 1000
must each have at least one reference 1080x2160 evidence image.

Also capture:
- Reduced Effects versions for Premium Pack and Robot Unlock;
- generic feature unlock;
- generic world shell;
- compact generic reward ceremony.

## F. Owner-review questions

Create:
`coordination/sessions/M43-C005-C001/OWNER_VISUAL_REVIEW_V01.md`

Keep the owner questions concrete and grouped, not dozens of micro-decisions.

Ask the owner to approve/adjust:

1. **Overall ceremony family**
   - cream/royal family continuity vs Results/Popup family;
   - amount of celebration/glow/confetti.

2. **Pack opening**
   - 3-card Standard layout;
   - 5-card Premium layout;
   - card reveal size;
   - rarity and NEW/DUPLICATE hierarchy.

3. **Collection completion**
   - Set Complete composition;
   - Master Collection composition and stronger hierarchy.

4. **Robot Unlock**
   - hero size;
   - role/perk presentation;
   - EQUIP vs KEEP CURRENT hierarchy.

5. **Gift milestone**
   - small milestone vs 1000 milestone hierarchy.

6. **Feature/World shell**
   - generic shell composition;
   - whether to reuse this family later after real world registry/art exists.

7. **Generic small reward**
   - compactness and whether it is suitable for Daily / Tasks 3/3.

Do not self-approve.

## G. Technical visual checks

Add a focused visual-master test suite that proves at minimum:

1. Standard fixture has exactly 3 card slots.
2. Premium fixture has exactly 5 card slots.
3. every card fixture has rarity + NEW/DUPLICATE label state.
4. no reroll CTA exists.
5. Set Complete fixture shows exact configured set reward.
6. Master fixture shows exactly +2500 SB +20 Bot Parts.
7. Robot fixture uses canonical roster text/perk and offers EQUIP + KEEP CURRENT.
8. Gift fixtures show exact configured reward dictionaries.
9. Feature fixture contains no hardcoded unlock level.
10. World shell contains no hardcoded level range / invented future world id.
11. generic reward supports 1–4 rows.
12. no preview action mutates economy/progression/save.
13. shared visual family fits all required viewport sizes.
14. Reduced Effects candidate states contain identical information.
15. no candidate uses hidden/fake reward, near-miss, jackpot or urgency copy.
16. asset paths referenced by candidates exist or are explicitly recorded missing.
17. repeated preview open/close does not accumulate nodes/timers/connections.

Run:
- focused visual-master suite;
- relevant M39 economy/collection/robot tests as baseline truth checks;
- M43-C001B/C001R visual regressions if shared UI helpers are touched;
- root `tests/run_tests.gd`;
- `git diff --check`.

## H. Scope locks

Do not:
- edit root TASKS.md;
- implement production ceremony queue/sequencer yet;
- call authoritative grant/open/unlock/claim actions from the preview harness;
- close SB-M43-063..075 or 077;
- close SB-M43-013;
- implement SB-M43-073 world unlock runtime;
- invent feature unlock levels;
- invent world ranges;
- invent World 02 art/name;
- change economy values;
- change card pack draw counts/rarity guarantee;
- change robot roster/perks/cost;
- change Gift Meter milestones;
- implement C005R micro-progress;
- add ad/IAP behavior;
- regenerate existing final art.

## I. Deliverables

Create:
- `coordination/sessions/M43-C005-C001/CEREMONY_ASSET_INVENTORY_V01.md`
- `coordination/sessions/M43-C005-C001/CEREMONY_VISUAL_MATRIX_V01.md`
- `coordination/sessions/M43-C005-C001/OWNER_VISUAL_REVIEW_V01.md`
- `coordination/sessions/M43-C005-C001/CLAUDE_LOG_V01.md`
- `coordination/sessions/M43-C005-C001/evidence/`

## J. Finish

Commit and push focused candidate/harness/evidence/docs safely to `origin/main`.

Return:
- final SHA;
- focused test summary;
- root regression summary;
- direct GitHub URL to CLAUDE_LOG_V01.md;
- direct GitHub URL to OWNER_VISUAL_REVIEW_V01.md;
- any genuinely missing art blocker.

Finish exactly:

`AWAITING_GPT_M43_C005_C001_VISUAL_AUDIT`
