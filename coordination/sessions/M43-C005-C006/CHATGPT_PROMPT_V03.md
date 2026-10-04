# M43-C005-C006 — STANDARD PACK FRAME ALPHA CLEANUP + 01→09 CADENCE REMEDIATION V03

Status: **READY FOR CLAUDE**  
Date: 2026-10-04  
Repository: `Sekiph82/Scrubbots`  
Branch: `main`  
Canonical task: **SB-M43-064**  
Expected Claude log: `CLAUDE_LOG_V03.md`

Root `TASKS.md` is **READ ONLY for Claude**. ChatGPT is the sole writer of lifecycle/progress state.

## 0. OWNER REJECTION / NEW HARD LOCK

The owner reviewed the V02 runtime evidence and found two visual problems:

1. the FULL opening does not make all previously approved **01→09 frames visibly distinct enough**; some beats appear to be skipped;
2. the Standard opening frame PNGs do not all have clean transparent backgrounds. Some frames visibly contain a dark rectangular matte/background around the pack/effects.

The owner requires:

> **ALL NINE Standard opening frames must have clean transparent backgrounds. No black/dark rectangular matte may remain in any frame. FULL opening must visibly use every frame 01,02,03,04,05,06,07,08,09 in order.**

V02 technical PASS is superseded for this visual/asset surface until V03 passes.

Do not close SB-M43-064.
Do not start SB-M43-065.

The previously issued owner-review-harness V01 is **PAUSED/SUPERSEDED for execution** until this V03 remediation is audited. Do not implement/run that harness in this pass.

## 1. FIRST ACTION — DESKTOP/GITHUB SYNC

Before reading implementation sources or changing files:

1. Work from exactly `C:\Users\sekip\Desktop\ScrubBots`.
2. Run `git fetch origin main --prune`.
3. Compare local `main` and `origin/main`.
4. Preserve owner-local `project.godot`, addons, dirty files and unrelated untracked work.
5. Synchronize Desktop with latest `origin/main` non-destructively.
6. If synchronization cannot be completed safely, STOP and report exact conflicting paths.
7. Only then begin work.

No destructive reset, clean, checkout-overwrite, owner-file deletion or force-push.

## 2. READ FIRST

Read:
- `CLAUDE.md`
- root `TASKS.md` read only
- `coordination/README.md`
- `coordination/AUDIT_POLICY.md`
- `coordination/sessions/M43-C005-C006/CHATGPT_PROMPT_V02.md`
- `coordination/sessions/M43-C005-C006/CHATGPT_AUDIT_CRITERIA_V02.md`
- `coordination/sessions/M43-C005-C006/CHATGPT_AUDIT_V02.md`
- `coordination/sessions/M43-C005-C006/CLAUDE_LOG_V02.md`
- `coordination/sessions/M43-C005-C002/PACK_ASSET_MANIFEST_V01.json`
- `coordination/sessions/M43-C005-C002/FINAL_OWNER_ACCEPTANCE_V01.md`
- current nine shipping Standard frames
- current `scripts/ui/ceremony/standard_pack_ceremony.gd`
- current focused C006 tests/evidence tool.

## 3. CONFIRMED AUDIT FACT TO RECHECK

The historical C002 manifest already exposes suspicious alpha geometry:

- Frame 05: alpha bbox `[48,48,976,1488]`, transparent pixels `236544`
- Frame 07: alpha bbox `[48,48,976,1488]`, transparent pixels `236544`
- Frame 09: alpha bbox `[48,48,976,1488]`, transparent pixels `236544`

Those three values exactly match a large 928×1440 occupied rectangle with only a 48 px outer border, which is consistent with the visible rectangular matte.

Frames 02/03/06/08 must also be independently inspected. Do not assume they are clean merely because their transparent-pixel counts differ.

This section is not permission to hard-code cleanup only for 05/07/09. **All 9 frames are in scope for alpha/background QA.**

## 4. ASSET REMEDIATION PRINCIPLE

This is a **background/alpha cleanup**, not a redesign.

Preserve:
- pack identity;
- pack geometry;
- tear progression;
- card-back counts and positions;
- card-back family;
- glow/light/effect artwork;
- 1024×1536 canvas;
- pack registration;
- visual sequence meaning 01→09.

Remove:
- black/dark rectangular matte;
- opaque or semi-opaque rectangular background fields that are not intentional visible effects;
- residual background contamination around glow/effects;
- hard rectangular edge/halo caused by the matte.

Do **not**:
- redraw the pack;
- invent new frame art;
- change the progression;
- move/resize the pack family;
- recolor the pack;
- add/remove cards;
- replace the existing sequence with generated new art;
- globally threshold all dark pixels, because intentional dark pixels exist inside the pack/card artwork.

Prefer deterministic, pixel-preserving alpha cleanup.

If a frame cannot be cleaned without visibly damaging the pack/effects, STOP for that frame and report it rather than shipping a degraded asset.

## 5. PRESERVE HISTORICAL C002 EVIDENCE

Do not overwrite historical accepted candidate files under:

`assets/ui/candidates/m43_c005/pack_opening/standard/`

Those remain provenance for the old approval.

Create a new V03 clean candidate family, e.g.:

`assets/ui/candidates/m43_c005/pack_opening/standard_v03_alpha_clean/`

with all nine cleaned frames.

After validation, promote the cleaned bytes into the existing shipping paths:

`assets/ui/final/rewards/pack_opening/standard/frame_01_closed.png`  
...  
`frame_09_final_reveal.png`

V03 candidate and final shipping file for each frame must be byte-identical after promotion.

## 6. CLEAN BACKGROUND CONTRACT — ALL NINE

For each frame 01..09:

- PNG RGBA, exactly 1024×1536;
- outside the intended pack / cards / intentional light / intentional particles, alpha must be 0;
- no black/dark rectangular background;
- no near-black opaque rectangle;
- no semi-transparent rectangular wash;
- no straight rectangular matte boundary visible on black, white, gray or checkerboard;
- no dark halo produced solely by matte contamination;
- intentional glow may remain semi-transparent;
- intentional dark artwork inside the pack/card objects must remain intact.

### Do not use a naive global black threshold

Use a method that distinguishes edge-connected/background matte from intentional internal dark art.

Any cleanup script/tool must be versioned under the V03 cycle or an appropriate test/tool path and must record per-frame before/after metrics.

## 7. REQUIRED ALPHA / MATTE VALIDATION

Create a V03 validator that examines **rendered pixels**, not metadata claims.

For every frame record:
- SHA-256 before;
- SHA-256 after;
- dimensions/mode;
- alpha bounding box;
- transparent-pixel count;
- opaque-pixel count;
- low-luminance + nontransparent pixel count;
- connected low-luminance background components;
- whether any large rectangular matte candidate exists;
- edge/corner transparency;
- pack registration comparison to pre-clean frame.

The validator must explicitly detect the old 05/07/09 matte and fail on the historical dirty files.

A useful hard gate:
- no large edge-connected or rectangle-shaped near-black nontransparent component may remain around the visible pack/effects;
- no component may create a near-straight four-sided background box around the art.

Do not treat “has some alpha” as proof of clean transparency.

## 8. VISUAL COMPOSITING QA

For all nine cleaned frames create audit composites on:

1. checkerboard;
2. pure white;
3. 50% gray;
4. pure black.

Required evidence:
- one 3×3 contact sheet per background, showing all 01..09;
- frame labels 01..09 outside the image area for evidence only;
- no rectangular matte visible on any background.

At least the checkerboard and gray sheets must be manually inspected by Claude frame-by-frame.

## 9. FULL RUNTIME 01→09 CADENCE

The shipping FULL-effects ceremony must make all nine beats visually observable.

Required order:

`01 -> 02 -> 03 -> 04 -> 05 -> 06 -> 07 -> 08 -> 09`

No frame may be skipped.

After Tap 1:
- Frame 01 must remain visibly present before Frame 02.
- Frames 02..08 must each remain visibly bound long enough to read as separate animation beats.
- Use a **minimum effective visible hold of 0.18 s per frame in FULL mode** for 01..08.
- Frame 09 may remain longer because live cards emerge from it.
- Do not speed any 01..08 beat below 0.18 s.
- Do not crossfade multiple frame images at once.
- one current pack frame only.

Reduced Effects may still skip directly to 09 as already approved; this requirement is for FULL mode.

Update only the timing necessary to meet this owner requirement. Do not redesign the state machine.

## 10. CADENCE EVIDENCE

The focused test must prove:
- frame history is exactly `[1,2,3,4,5,6,7,8,9]`;
- each FULL frame 01..08 is the active bound texture for >=0.18 s;
- frame 09 is reached once;
- no second frame TextureRect exists;
- no contact sheet/strip is shipping UI;
- no card face appears before the final opening beat;
- Reduced Effects semantics remain unchanged.

Create a timing log with per-frame:
- bind timestamp;
- next-frame timestamp;
- effective hold duration.

Also produce a real Godot runtime evidence sequence with one capture for **every frame 01..09**, captured from the actual shipping ceremony after Tap 1.

Create:
`STANDARD_RUNTIME_01_09_V03_CONTACT_SHEET.png`

This is evidence only.

## 11. V02 FLOW MUST REMAIN

Apart from clean frames + visible FULL cadence, preserve the owner V02 flow:

pack alone  
-> Tap 1  
-> clean visible 01→09  
-> 3 cards emerge  
-> pack disappears  
-> three-card hold  
-> Collection upper-left / Cards Exchange upper-right  
-> wait for Tap 2  
-> NEW to Collection / DUPLICATE to Cards Exchange  
-> complete once.

Do not change:
- destination logic;
- card truth;
- authority boundary;
- second-tap gate;
- lifecycle semantics;
- Reduced Effects two-gate semantics.

## 12. TESTS / SENSITIVITY

Add/extend focused validation to prove at minimum:

1. all nine final shipping frames are V03-clean promoted bytes;
2. historical dirty matte examples fail the new matte detector;
3. each cleaned frame passes checkerboard/white/gray/black compositing QA;
4. no large dark rectangular matte remains in any 01..09 final;
5. frame registration has not drifted materially;
6. exact FULL order 01..09;
7. FULL 01..08 effective hold >=0.18 s;
8. no skipped/repeated frame;
9. one current pack frame only;
10. V02 card emergence/hold/destinations/routing still pass;
11. Reduced Effects still uses frame 09 semantic shortcut with both tap gates;
12. no authority mutation;
13. lifecycle/re-entry remains safe.

Sensitivity mutations must include:
- reinsert an opaque black rectangle into a cleaned frame -> validator FAIL;
- make a semi-transparent dark rectangle -> validator FAIL;
- shorten one FULL frame to <0.18 s -> cadence test FAIL;
- skip one frame -> order test FAIL;
- repeat one frame -> order/timing test FAIL.

## 13. REGRESSION

Run:
- updated SB-M43-064 focused suite;
- new V03 alpha/matte validator;
- SB-M43-063 RevealSequencer suite;
- relevant M43 popup/modal/ceremony regressions;
- `git diff --check`.

Because this pass changes nine shipping PNGs and ceremony timing, also run the root suite `tests/run_tests.gd`.

No unexplained new warning/error.

## 14. EVIDENCE / LOG

Create:

- `coordination/sessions/M43-C005-C006/STANDARD_FRAME_ALPHA_MATRIX_V03.md`
- `coordination/sessions/M43-C005-C006/STANDARD_FRAME_ALPHA_MANIFEST_V03.json`
- `coordination/sessions/M43-C005-C006/CLAUDE_LOG_V03.md`
- evidence under `coordination/sessions/M43-C005-C006/evidence/v03/`

Evidence must include:
- checkerboard 01..09 sheet;
- white 01..09 sheet;
- gray 01..09 sheet;
- black 01..09 sheet;
- actual runtime 01..09 contact sheet;
- final pack-idle / three-card-hold / destination / route evidence after cleanup.

## 15. GOVERNANCE

Claude must:
- not edit root `TASKS.md`;
- not implement owner-review harness in this pass;
- not start SB-M43-065;
- not create self-audit;
- commit/push authorized V03 remediation/evidence only.

## 16. HANDOFF

Return:
- final SHA;
- all nine before/after hashes;
- alpha/matte validator result;
- runtime 01→09 timing table;
- focused/regression/root results;
- evidence URLs;
- blockers.

Finish exactly:

`AWAITING_GPT_M43_C005_C006_V03_ALPHA_AND_CADENCE_AUDIT`
