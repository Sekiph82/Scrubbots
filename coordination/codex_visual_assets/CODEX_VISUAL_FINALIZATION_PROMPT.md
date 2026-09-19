# SCRUBBOTS — CODEX VISUAL FINALIZATION PROMPT

Status: FINAL STATIC VISUAL PRODUCTION BATCH
Repository: `Sekiph82/Scrubbots`
Branch: `codex/visual-assets-production`

This prompt closes the current Codex visual-production program.

## 1. Read first

Read and obey, in this order:

1. `coordination/codex_visual_assets/CODEX_VISUAL_PUBLISH_AND_LOG_POLICY.md`
2. `coordination/OWNER_ROBOT_ROSTER_V01.md`
3. `coordination/codex_visual_assets/CODEX_PROJECT_VISUALS_PHASE2_MASTER_LIST.md`
4. `coordination/codex_visual_assets/CODEX_PROJECT_VISUALS_PHASE2_TASKS.md`
5. `assets/ui/VISUAL_ASSET_INDEX.md`

Do not regenerate already completed P2-001..P2-144 assets.

Your only new image-production scope is P2-145..P2-157.

## 2. Produce exactly these 13 new canonical visuals

### Robot perk icons

- P2-145 `assets/ui/final/robots/perks/perk_first_clear_sb_bonus.png`
- P2-146 `assets/ui/final/robots/perks/perk_gift_bar_sb_bonus.png`
- P2-147 `assets/ui/final/robots/perks/perk_speed_2x_discount.png`
- P2-148 `assets/ui/final/robots/perks/perk_cards_exchange_bonus.png`
- P2-149 `assets/ui/final/robots/perks/perk_booster_discount.png`
- P2-150 `assets/ui/final/robots/perks/perk_heart_refill_discount.png`
- P2-151 `assets/ui/final/robots/perks/perk_win_streak_bonus.png`
- P2-152 `assets/ui/final/robots/perks/perk_daily_task_bonus.png`
- P2-153 `assets/ui/final/robots/perks/perk_master_cleaner.png`

### Collection state art

- P2-154 `assets/ui/final/collection/states/card_back.png`
- P2-155 `assets/ui/final/collection/states/card_unknown_silhouette.png`
- P2-156 `assets/ui/final/collection/states/card_new_glow.png`

### Cleaning Crew group art

- P2-157 `assets/ui/final/characters/robots/cleaning_crew_group.png`

The group art must contain exactly these 10 canonical robots:

Scrubby, Moppy, Bubbles, Spark, Squeegee, Dusty, Rinse, Polly, Clippy, Atlas.

Preserve the owner-approved robot identities from `OWNER_ROBOT_ROSTER_V01.md`. Scrubby remains the visual anchor.

## 3. Visual requirements

Use the established SCRUBBOTS glossy casual 3D style.

For perk icons:
- transparent PNG;
- isolated, centered;
- strong silhouette at mobile scale;
- no text;
- no percentage;
- no numeric price;
- no fake currency;
- no new booster identity;
- visually compatible with `assets/ui/final/robots/robot_perk_emblem_frame.png`.

For Collection state art:
- preserve Collection card visual language;
- generic card back must not belong to a specific set;
- unknown silhouette must not invent an unreleased card;
- new-card glow must have true transparent background.

For Cleaning Crew group:
- transparent background;
- wide reusable composition;
- all 10 robots visible and individually recognizable;
- no extra robot;
- no missing robot;
- no names/text/logo baked into the group image;
- useful for Robot Collection header, marketing, and celebration layouts.

## 4. Image-generation workflow

Use built-in image generation by default.

Use a separate generation/edit operation for each distinct asset.

Do not use CLI/API fallback unless the built-in workflow fails and the owner has explicitly authorized fallback.

Do not leave production images only under a local generated-images folder.

Every final selected output must be copied/moved to the exact canonical target path above.

## 5. Update the canonical visual index

After all 13 images exist, update:

`assets/ui/VISUAL_ASSET_INDEX.md`

Requirements:
- re-scan the visual branch;
- include every new P2-145..P2-157 path;
- identify them as Phase 2 canonical assets;
- update production/canonical counts;
- remove P2-145..P2-157 from the "Recommended future visual backlog" because they are no longer future work;
- retain legacy-path warnings;
- do not remove existing assets from the index.

The index is Claude's visual lookup authority for future UI integration.

## 6. Update GitHub logs

Update the repository copy of:

`coordination/codex_visual_assets/CODEX_PROJECT_VISUALS_PHASE2_LOG.md`

Append, do not erase useful existing history.

Also append a finalization summary to:

`coordination/codex_visual_assets/CODEX_VISUAL_PRODUCTION_MASTER_LOG.md`

The log entry must include:
- P2-145..P2-157;
- exact output paths;
- generation/derivation actions;
- QA performed;
- commit SHA(s);
- remote branch HEAD;
- final canonical target count;
- any blockers;
- confirmation that main was untouched.

Do not treat a local Windows log file as authoritative. The GitHub repository log is authoritative.

## 7. Update Phase 2 task tracker

Update:

`coordination/codex_visual_assets/CODEX_PROJECT_VISUALS_PHASE2_TASKS.md`

Mark P2-145..P2-157 complete only after the files exist at exact target paths and are committed.

Do not touch root `TASKS.md`.

## 8. Git rules

Work only on:

`codex/visual-assets-production`

Do not touch `main`.
Do not touch Claude/M30 work.
Do not rebase or force-push.
Do not use `git add .`.
Do not use `git add -A`.

Stage exact authorized paths only.

Commit the new images, updated index, Phase 2 task tracker, Phase 2 log, and master visual production log.

Push only:

`origin/codex/visual-assets-production`

## 9. Mandatory remote verification

After push:

1. fetch `origin/codex/visual-assets-production`;
2. verify P2-145..P2-157 exist remotely at exact paths;
3. verify complete Phase 2 scope is **157 / 157**;
4. verify the updated visual index exists remotely;
5. verify both GitHub log files exist remotely;
6. verify `origin/main` was not changed by this work.

Do not claim completion before remote verification.

## 10. Final response to owner

Return:
- new asset count: 13 / 13;
- Phase 2 canonical total: 157 / 157;
- commit SHA(s);
- remote branch HEAD SHA;
- missing canonical targets: none, or exact list;
- confirmation that `assets/ui/VISUAL_ASSET_INDEX.md` was updated;
- confirmation that GitHub logs were updated;
- confirmation that main was untouched.

Finally provide the FULL LONG GitHub browser URL to the authoritative Phase 2 log, exactly in this form:

`https://github.com/Sekiph82/Scrubbots/blob/codex/visual-assets-production/coordination/codex_visual_assets/CODEX_PROJECT_VISUALS_PHASE2_LOG.md`

Also provide the FULL LONG GitHub browser URL to the complete visual index:

`https://github.com/Sekiph82/Scrubbots/blob/codex/visual-assets-production/assets/ui/VISUAL_ASSET_INDEX.md`

After successful completion and remote verification, consider the current static visual-generation program FINALIZED. Future visual generation requires a new owner-approved scope.

BEGIN FINALIZATION NOW.
