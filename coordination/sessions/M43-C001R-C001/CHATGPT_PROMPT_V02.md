# M43-C001R-C001 — VISUAL REMEDIATION PROMPT V02

Status: READY FOR CLAUDE
Date: 2026-10-02
Repository: `Sekiph82/Scrubbots`
Branch: `main`
Scope: SB-M43-R01-001..008 visual remediation only

Do not edit root `TASKS.md`.

## Read first

1. `CLAUDE.md`
2. root `TASKS.md` READ ONLY
3. `coordination/AUDIT_POLICY.md`
4. `coordination/sessions/M43-C001R-C001/CHATGPT_PROMPT_V01.md`
5. `coordination/sessions/M43-C001R-C001/CHATGPT_AUDIT_CRITERIA_V01.md`
6. `coordination/sessions/M43-C001R-C001/CHATGPT_AUDIT_V01.md`
7. `coordination/sessions/M43-C001R-C001/OWNER_VISUAL_DECISION_V02.md`

## Mission

Preserve the technically-passed C001R architecture and implement only the owner-requested visual remediation.

### A. Journey strip size

Keep the current Journey positions:
- Results: between reward rows and Next Cleanup;
- Home: directly above PLAY.

Increase the Journey strip's visual size/readability.

Requirements:
- Home strip is materially larger than V01, not a token 1–2 px change;
- Results strip may be enlarged proportionally if needed for family consistency;
- ordinary nodes remain readable;
- do not move or resize PLAY/Win Streak/BottomNav/Gift Meter/Ad slot to make room unless strictly required;
- preserve current responsive no-collision contract across all five target viewports.

### B. Mini-boss / boss emphasis

Keep:
- slot 5 orange;
- slot 10 red.

Change size hierarchy:
- ordinary blue/future node = baseline;
- orange mini-boss node = clearly larger than baseline;
- red boss node = clearly larger than mini-boss and baseline.

The current V01 code only scales boss/current strongly enough; update the component so mini-boss also receives explicit size emphasis.

Do not add reward icons or imply extra rewards.

### C. CLEAN NEXT

No change.

`CLEAN NEXT` remains the primary CTA.

### D. Duplicate Coming Soon

On unavailable frontier Results (production L10 -> missing L11):
- keep the Next Cleanup card's Coming Soon state;
- suppress/remove the older duplicate Results note immediately above CLEAN NEXT;
- keep CLEAN NEXT disabled;
- keep Home secondary usable;
- do not change the underlying canonical `CONTENT_MISSING` truth.

Do not globally remove unrelated Results notes. Scope the suppression to the case where the momentum Next Cleanup unavailable card already carries the same frontier message.

### E. Teaser crop

No change in this remediation:
- keep deterministic cropped detail;
- keep target ~20%;
- keep 0.15..0.25 disclosure envelope;
- keep full-preview non-disclosure tests.

The owner asked what “teaser crop” means but did not request a change yet.

## Required tests

Update/add focused assertions proving:

1. Home Journey strip is larger than V01 reference dimensions.
2. Results Journey strip is not smaller than V01.
3. slot 5 mini-boss node rect is larger than ordinary node rect.
4. slot 10 boss node rect is larger than slot 5.
5. orange/red colors remain the accepted mini/boss edge colors.
6. production L10 shows only one Coming Soon message in the Results momentum area/CTA corridor.
7. Next Cleanup card still shows Coming Soon.
8. old duplicate note above CLEAN NEXT is absent/hidden in that case.
9. CLEAN NEXT remains disabled for missing L11.
10. normal available-next Results copy is unchanged.
11. crop fraction/non-disclosure remains unchanged and passes prior tests.
12. five-view responsive matrix still has no Home collisions.
13. Results panel/CTAs remain inside viewport.
14. Reduced Effects logic remains identical.
15. lifecycle accumulation remains clean.

Run:
- focused C001R suite;
- C001A/B Results suites;
- M42 Home/composition/safe-area/navigation;
- root `tests/run_tests.gd`;
- `git diff --check`.

## Evidence

Produce fresh V02 evidence at minimum:
- Home frontier 6 reference showing larger Journey;
- Home frontier 10 showing red boss size hierarchy;
- Results L4 or L5 showing orange mini-boss relative size;
- Results L9/L10 showing red boss relative size;
- Results L10 missing-L11 with only one Coming Soon message;
- short phone 1080x1920;
- reference 1080x2160;
- 1170x2532;
- 1290x2796;
- tablet 1536x2048;
- Reduced Effects.

Write:
- `coordination/sessions/M43-C001R-C001/OWNER_VISUAL_REVIEW_V02.md`
- `coordination/sessions/M43-C001R-C001/CLAUDE_LOG_V02.md`

## Scope locks

Do not:
- edit root TASKS.md;
- change ResultsMomentum authority;
- change progression/catalog/cycle truth;
- change crop algorithm/fraction;
- change CLEAN NEXT wording;
- add art;
- add rewards;
- make nodes tappable;
- implement C005;
- implement C005R;
- alter economy/difficulty/Heart/ad/booster systems;
- restyle unrelated accepted Home/Results surfaces.

## Finish

Commit and push safely to `origin/main`.

Return final SHA, focused/regression results, log URL and V02 owner-review URL.

Finish exactly:

`AWAITING_GPT_M43_C001R_C001_V02_AUDIT`
