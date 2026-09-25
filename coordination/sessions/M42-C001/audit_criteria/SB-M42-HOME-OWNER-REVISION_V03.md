# SB-M42 HOME OWNER REVISION V03 — CHATGPT AUDIT CRITERIA

Verdict may be PASS only if all required owner revisions are independently verified.

## 1. Profile / HUD
- ProfileCard is narrower than V02 without simply shrinking the whole card.
- ProfilePortrait is materially larger.
- Portrait draws in front of ProfileAvatarFrame and may extend above it.
- Portrait is not clipped by avatar/card containers.
- Top MenuButton/Settings hamburger is removed.
- Bottom-nav Settings remains.
- Bot Parts text is numeric ratio only, e.g. 0/250.
- Level remains separate/live.

## 2. Gift Meter
- HOME-051 and HOME-054 remain visible.
- Long Gift Meter/Next Gift caption is gone.
- Meter shows only N/1000.
- Canonical Gift Meter behavior is unchanged.

## 3. City / background
- HOME-002 and HOME-003 visibly contribute city buildings.
- Buildings are visible left/right/around portal.
- Empty sky is materially reduced.
- HOME-004 is raised/recomposed so the street region begins immediately above bottom nav.
- Bottom nav is flush to the screen bottom.
- No extra world strip appears beneath nav.
- City/portal/platform/street share a coherent perspective.
- If a new city candidate was created, it is under assets/ui/generated only and not self-promoted.

## 4. Portal
- Portal is grounded in the city/world plane.
- It does not float in empty sky.
- Live title/area remain live/localizable.
- Title treatment is integrated with the arch.

## 5. Platform
- HOME-011 is not active in runtime composition.
- HOME-011 bytes/history remain unchanged.
- HOME-010 is the single platform supporting Scrubby.
- Scrubby feet sit directly on HOME-010.
- No stacked/two-disc appearance remains.

## 6. Idle overlays
- HOME-031 and HOME-032 are not shown in production Home.
- Idle timer/state loop cannot surface alternate face/arm.
- Files remain unchanged.
- Presentation accounting marks them owner-disabled/retired.

## 7. Lower action row
- Side columns are exactly 3 + 3:
  Left = win streak / gifts / collection.
  Right = no ads / daily / tasks.
- SHOP is left of Play.
- CARDS EXCHANGE is right of Play.
- Shop/Play/Cards form one coherent row.
- Existing enabled/disabled behavior is preserved.

## 8. Play CTA
- Play button is smaller than V02.
- PLAY text is proportionally smaller but still primary.
- Level/continue subtitle is live and secondary.
- Native white triangle is used instead of the blue-square-inside-green-button look.
- If HOME-078 is no longer used, presentation accounting marks it owner-retired rather than fake-visible.

## 9. Reward track
- Panel height is materially reduced.
- Five gift objects remain.
- Visible values are exactly 1 / 5 / 10 / 25 / 100.
- No plus signs.
- No per-step SB icons.
- No per-step WIN labels.
- HOME-087 is retired from active per-step presentation.
- Progress/current state is still understandable.

## 10. Bottom navigation
- Only bottom Settings is visible.
- Five-button nav remains.
- Dock is flush to bottom.
- HOME selected state remains clear.
- RANKS wording remains unchanged for V03.

## 11. Modal / overlay behavior
For Gifts, Daily, Cards Exchange and Settings:
- modal renders above Home background;
- Home action controls disappear while modal is open;
- hidden Home controls cannot receive input;
- no Home card/button visually overlays the modal;
- closing/back restores exact Home controls;
- back closes top modal first;
- no double-modal input leakage.

## 12. Presentation accounting
- Explicit retired/disabled mode exists.
- At minimum HOME-011, HOME-031, HOME-032 and HOME-087 are retired/disabled.
- HOME-078 is also retired if native triangle replaced it.
- Historical approval/hash records remain intact.
- Tests distinguish historical approval from active presentation.

## 13. Responsive / visual evidence
- 1080x2160, 1290x2796, 1080x1920, 1536x2048 evidence exists.
- Modal evidence exists for Gifts, Daily, Cards Exchange and Settings.
- Required viewport/touch constraints still pass.
- If Claude claims vision inspection, evidence/log supports the claim.

## 14. Asset integrity
- No approved production PNG bytes changed.
- No owner-approved final asset silently overwritten.
- Candidate assets, if any, remain under generated/.

## 15. Regression
Required focused and root suites exit 0.
Zero SCRIPT ERROR.
No hidden FAIL.
git diff --check clean.
TASKS.md, owner decision artifacts and ChatGPT audit/criteria files untouched by Claude.

## Verdict options
- AUDITED_PASS / CODE READY FOR OWNER VISUAL REVIEW
- AUDITED_PASS_WITH_CITY_ASSET_OWNER_GATE
- CHANGES_REQUIRED

Final SB-M42-011 / SB-M42-017 closure still requires owner review of the new runtime Home.
