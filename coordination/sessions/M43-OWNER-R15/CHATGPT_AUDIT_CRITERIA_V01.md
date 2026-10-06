# M43-C015R — OWNER RUNTIME REVIEW REMEDIATION V01 — CHATGPT AUDIT CRITERIA

Date: 2026-10-06
Tasks: `SB-M43-R15-001..003`

## Governance / sync
- [ ] Claude began from the owner-local ScrubBots checkout and synchronized non-destructively with current `origin/main`.
- [ ] Owner-local `project.godot`, `main.tscn`, `addons/` and unrelated files were preserved.
- [ ] Root `TASKS.md` was not edited by Claude.
- [ ] No reset/clean/force history rewrite.

## SB-M43-R15-001 — Rewarded Ads
- [ ] Existing four primary Home panels remain SHOP/COLLECTION/TASKS/DAILY.
- [ ] A separate compact `REWARDED ADS` CTA exists and does not collide with Home layout.
- [ ] Rewarded Ads popup uses the canonical M43 visual family.
- [ ] Exactly five slots are shown per local day.
- [ ] Slot 1 is a no-ad CLAIM.
- [ ] Slots 2-5 require verified completed rewarded video.
- [ ] Reward bundles are config-driven and seeded from the existing five canonical Daily D1-D5 bundles; no invented values.
- [ ] Rewarded Ads claim state is separate from Daily login claim/streak state.
- [ ] Existing Daily login and Daily Scrub Orders behavior remain unchanged.
- [ ] Rewarded video→grant still uses the canonical rewarded authority; no second raw callback grant path.
- [ ] Deterministic economy ids are `daily_rewarded:<local_day>:<slot>` or an exactly equivalent documented deterministic contract.
- [ ] Provider token is not the grant idempotency identity.
- [ ] Unavailable/cancelled/skipped/failed/timeout/unverified outcomes grant nothing.
- [ ] Duplicate/late callbacks grant nothing.
- [ ] Local-day forward reset works.
- [ ] Clock/local-day rollback cannot reopen/farm rewards.
- [ ] Relaunch cannot duplicate already granted slots.
- [ ] Production default provider remains honestly unavailable until M57.
- [ ] Test/evidence provider is injected only in test/review seams.
- [ ] Heart/booster rewarded acquisition remains regression-safe.

## SB-M43-R15-002 — Settings visual remediation
- [ ] Settings now visibly matches the accepted SCRUBBOTS M43 cyan/white/cream/royal-blue popup family.
- [ ] Generic dark rectangular panel presentation is removed.
- [ ] Master/Music/SFX controls remain functionally identical.
- [ ] Haptics remains functionally identical.
- [ ] Reduced Effects remains functionally identical.
- [ ] Live apply behavior remains.
- [ ] Persistence/relaunch behavior remains.
- [ ] No second Settings state/authority introduced.
- [ ] Close/back behavior remains valid.
- [ ] Touch/readability/safe-area constraints pass.

## SB-M43-R15-003 — Daily containment
- [ ] Daily consecutive-login and D1-D5 economy/state authority is unchanged.
- [ ] Calendar/hero stays visually inside the intended Daily popup/frame.
- [ ] Flame stays contained.
- [ ] Five day cards stay contained.
- [ ] Check/state art stays within each card.
- [ ] Reward text does not clip.
- [ ] Rule text and actions do not overlap the grid.
- [ ] 683x1366 owner-observed runtime passes.
- [ ] 720x1280, 1080x1920, 1080x2160, 1170x2532, 1290x2796 and 1536x2048 pass.
- [ ] Tasks and Gift Bar do not regress.

## Regression / tests
- [ ] New focused R15 tests PASS.
- [ ] `tests/m41_settings.gd` PASS.
- [ ] `tests/m39d_daily_collection.gd` PASS.
- [ ] `tests/m43_master_c009_daily.gd` PASS.
- [ ] Existing rewarded acquisition tests PASS.
- [ ] Root `tests/run_tests.gd` ALL PASS.
- [ ] `git diff --check` clean.
- [ ] No unexplained `SCRIPT ERROR`.

## Evidence
- [ ] Home with Rewarded Ads CTA capture exists.
- [ ] Rewarded Ads free-ready capture exists.
- [ ] Rewarded Ads slot-1-claimed capture exists.
- [ ] Test-provider WATCH AD capture exists and is labeled non-production.
- [ ] One verified-ad claimed capture exists.
- [ ] Production provider-unavailable capture exists.
- [ ] Settings 683x1366 + 1080x2160 captures exist.
- [ ] Daily fixed 683x1366 + 1080x2160 captures exist.

## Handoff
- [ ] Three child Claude logs exist.
- [ ] Master Claude log exists.
- [ ] Exact final SHA and branch/main state are reported.
- [ ] Master log ends `AWAITING_GPT_M43_OWNER_R15_V01_AUDIT`.
