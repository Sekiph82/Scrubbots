# M43-C005-C006 — OWNER REVIEW HARNESS V02 — V03 REBASELINE

Status: **READY FOR CLAUDE**  
Date: 2026-10-04  
Repository: `Sekiph82/Scrubbots`  
Branch: `main`  
Canonical task: **SB-M43-064**  
Purpose: **manual OWNER VISUAL REVIEW of technically-audited V03**  
Expected Claude log: `coordination/sessions/M43-C005-C006/owner_review_harness/CLAUDE_LOG_V02.md`

Root `TASKS.md` is **READ ONLY for Claude**. ChatGPT is the sole writer of lifecycle/progress state.

## 0. Context

V03 Standard Pack alpha/cadence remediation is technically accepted in:

`coordination/sessions/M43-C005-C006/CHATGPT_AUDIT_V03.md`

The existing owner-review harness V01 was built earlier against the V02 production hash. Its actual controller already wraps the real production ceremony and should remain functionally reusable, but its smoke test and owner instructions are stale.

This pass must rebaseline the review harness to the **V03 shipping ceremony and clean V03 frame assets** without changing production.

Goal: let the owner open one Godot scene, press F6, and manually judge the exact current V03 motion before granting OWNER VISUAL PASS.

## 1. FIRST ACTION — DESKTOP/GITHUB SYNC

Before reading implementation sources or changing files:

1. Work from exactly `C:\Users\sekip\Desktop\ScrubBots`.
2. Run `git fetch origin main --prune`.
3. Compare local `main` and `origin/main`.
4. Preserve owner-local `project.godot`, `scenes/app/main.tscn`, addons, dirty files and unrelated untracked work.
5. Synchronize Desktop with latest `origin/main` non-destructively.
6. If synchronization cannot be completed safely, STOP and report exact conflicting paths.
7. Only then begin.

No destructive reset, clean, checkout-overwrite, owner-file deletion or force-push.

## 2. READ FIRST

Read:
- `CLAUDE.md`
- root `TASKS.md` read only
- `coordination/README.md`
- `coordination/AUDIT_POLICY.md`
- `coordination/sessions/M43-C005-C006/CHATGPT_PROMPT_V03.md`
- `coordination/sessions/M43-C005-C006/CHATGPT_AUDIT_CRITERIA_V03.md`
- `coordination/sessions/M43-C005-C006/CHATGPT_AUDIT_V03.md`
- `coordination/sessions/M43-C005-C006/STANDARD_FRAME_ALPHA_MANIFEST_V03.json`
- existing owner-review harness V01 prompt/criteria/log/instructions
- `tests/tools/owner_review/standard_pack_owner_review.gd`
- `tests/tools/owner_review/standard_pack_owner_review.tscn`
- `tests/m43_c005_c006_owner_review_harness.gd`
- current production Standard ceremony and frame assets.

## 3. HARD PRODUCTION IMMUTABILITY

Do not modify:
- `scripts/ui/ceremony/standard_pack_ceremony.gd`;
- `scripts/ui/ceremony/standard_pack_model.gd`;
- `scripts/ui/components/reveal_sequencer.gd`;
- any `assets/ui/final/rewards/pack_opening/standard/*.png`;
- any V03 clean candidate PNG;
- Collection card art/catalog;
- economy/reward/Collection/Card Exchange authority;
- root `TASKS.md`;
- `project.godot`;
- `scenes/app/main.tscn`;
- SB-M43-065.

If the review harness cannot work against V03 without production changes, STOP and report the blocker.

## 4. PREFER NO CONTROLLER/SCENE CHANGE

The existing review controller/scene already instantiates the real shipping ceremony through the real ModalStack.

Prefer to leave these byte-identical:
- `tests/tools/owner_review/standard_pack_owner_review.gd`
- `tests/tools/owner_review/standard_pack_owner_review.tscn`

Only change them if an actual V03 incompatibility is found. If changed, explain exactly why.

Expected V02 work is primarily:
- rebaseline smoke-test production hashes to V03;
- add V03 clean-frame asset guards;
- update owner instructions from V02 to V03;
- run the live F6 review scene against current V03.

## 5. UPDATE HARNESS SMOKE TEST

Update:

`tests/m43_c005_c006_owner_review_harness.gd`

Requirements:

### Production baseline

Replace the stale V02 ceremony hash with the current V03 audited production hash.

Continue pinning:
- StandardPackCeremony;
- StandardPackModel;
- RevealSequencer.

### V03 frame asset guard

Add a direct guard proving the review harness is currently loading the V03 shipping frame family:

For all 9 Standard frame paths:
- shipping SHA-256 equals `STANDARD_FRAME_ALPHA_MANIFEST_V03.json` `sha256_after`;
- V03 clean candidate SHA-256 equals shipping SHA-256;
- 01..04 equal historical SHA-256;
- 05..09 differ from historical SHA-256;
- all 9 V03 manifest rows are `clean=true`.

Do not duplicate the full matte validator inside the harness test. The V03 manifest + existing V03 technical audit are authority here.

### Current live behavior

Retain/prove:
- scene loads;
- real StandardPackCeremony used;
- real ModalStack used;
- default mixed fixture NEW/DUPLICATE/NEW;
- waits in IDLE indefinitely;
- harness has no auto tap;
- R replays;
- E toggles FULL/Reduced and restarts;
- 1/2/3 fixture switching;
- no authority;
- no duplicated opening/timing logic in harness;
- project main scene untouched.

Add a FULL-mode check that, after a test-driven Tap 1:
- shipping frame history reaches exactly `[1,2,3,4,5,6,7,8,9]`;
- every 01..08 configured FULL hold is >=0.18 s;
- the harness itself contains no timing values for those beats.

The test may call the ceremony directly; the harness controller itself must never auto-tap.

## 6. OWNER INSTRUCTIONS V02

Create:

`coordination/sessions/M43-C005-C006/owner_review_harness/OWNER_REVIEW_INSTRUCTIONS_V02.md`

Do not overwrite V01 historical instructions.

Instructions must be short and explicit:

1. Open:
   `C:\Users\sekip\Desktop\ScrubBots\project.godot`
2. In FileSystem open:
   `res://tests/tools/owner_review/standard_pack_owner_review.tscn`
3. Press **F6 — Run Current Scene**.
4. First screen must show Standard Pack alone.
5. Click once.
6. Judge whether all **9 distinct opening beats** are visibly readable in sequence and whether there is **no rectangular/dark background matte** around any frame/glow.
7. Wait for the three cards and destination icons.
8. Click again and judge NEW/DUPLICATE routing.
9. Press **R** to replay.
10. Press **E** for Reduced Effects.
11. Press **1 / 2 / 3** for mixed / all-new / repeat fixtures.

State clearly:
- this is the exact current **V03 shipping ceremony**;
- V03 FULL timing is 01 = 0.40 s, 02..08 = 0.22 s each, 09 = 0.30 s before cards emerge;
- the owner should specifically watch for any skipped-looking frame or remaining rectangular matte;
- F5 is not required;
- review scene mutates no save/economy/Collection/Card Exchange;
- only owner can grant OWNER VISUAL PASS.

## 7. MANUAL F6 V03 CHECK

Run Current Scene in Godot and manually verify:

- F6 launches;
- initial pack waits;
- Click 1 starts FULL V03;
- all nine beats are visibly presented;
- no rectangular matte is visible around any beat;
- frame 05/07/09 former black boxes are gone;
- frame 06/08 former dark haze/box is gone;
- 3-card hold and destination layout still works;
- Click 2 routing still works;
- R works;
- E works;
- 1/2/3 works;
- no runtime/script error.

This is implementation evidence, not owner approval.

If visual inspection reveals a V03 production defect, STOP. Do not fix production in this harness pass.

## 8. VALIDATION

Run:

1. `godot --headless --path . -s res://tests/m43_c005_c006_owner_review_harness.gd`
2. `godot --headless --path . -s res://tests/m43_c005_c006_standard_pack_presentation.gd`
3. `python tools/validate_m43_c005_standard_frame_alpha_v03.py assets/ui/final/rewards/pack_opening/standard`
4. `godot --headless --path . -s res://tests/m43_c005_c005_reward_reveal_sequencer.gd`
5. `git diff --check`

No root-suite rerun is required if only harness test/instructions/log paths change. Production was already root-regression-audited in V03.

## 9. LOG / PUBLISH

Create:

`coordination/sessions/M43-C005-C006/owner_review_harness/CLAUDE_LOG_V02.md`

Record:
- sync;
- exact changed files;
- proof production V03 files/assets were untouched;
- old V02 hash pin replaced by V03;
- V03 asset guard result;
- all test results;
- manual F6 V03 review result;
- blockers.

Do not edit root `TASKS.md`.

Do not start SB-M43-065.

Commit and push authorized harness-rebaseline files only.

Finish exactly:

`AWAITING_GPT_M43_C005_C006_OWNER_REVIEW_HARNESS_V02_AUDIT`
