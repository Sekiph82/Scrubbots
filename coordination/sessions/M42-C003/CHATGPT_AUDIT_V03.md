# M42-C003 V03 — CHATGPT INDEPENDENT AUDIT

Date: 2026-10-02
Task: `SB-M42-035`
Implementation handoff: `AWAITING_GPT_M42_C003_V03_AUDIT`
Audited commit: `105401e8f549807014234c7c8e9ec250b322034c`
Result: **TECHNICAL_PASS / OWNER_VISUAL_GATE_REQUIRED**

## Executive result

M42-C003 V03 resolves the V02 representation conflict correctly. The fixed HOME-026 texture canvas is no longer used as an artificial animation boundary; the 63 approved source frames are normalized onto one deterministic larger animation canvas and mapped back to the accepted HOME screen-space soles pivot. Runtime integration, manifest pinning, lifecycle behavior, Reduced Effects behavior, screen-space collision checks, determinism, and M42-focused regressions all have sufficient evidence for a technical pass.

No further Claude/Codex remediation prompt is required at this stage.

SB-M42-035 is **not closed yet** because the canonical task text still requires owner visual acceptance of the runtime gestures. The remaining gate is visual only.

## Source / scope

PASS:
- HOME-026 SHA remains `fc30b992787c644822a6cd02510e481fab9010cd89ab75fc4a9909ca713d5c18`.
- No new character art was generated.
- Exact production counts are Wave 14 / Bow 15 / Turn-Look 17 / Full Turn 17.
- Claude did not edit root `TASKS.md`.
- The owner-selected Turn/Look decision, dedicated bilateral Turn/Look family, is recorded in the V03 log.

## Canvas / normalization

PASS:
- All 63 promoted frames use one common 464×512 RGBA8 animation canvas.
- All 63 frames use one common animation pivot: (219, 477).
- One uniform scale is used per source family; there is no per-frame scaling.
- No non-uniform stretch, skew, or crop is reported.
- Deterministic resampler is documented: premultiplied-alpha Pillow affine BICUBIC.
- Independent second build is 63/63 byte-identical.
- Family scale evidence is coherent for Wave, Bow and Full Turn.
- Turn/Look remains visibly stubbier than HOME-026, but that exact source-family trade-off was presented to and selected by the owner during the cycle.

## Runtime mapping

PASS:
- Accepted M42-C002 HOME-026 geometry and `SCRUBBY_SCALE = 1.612` remain authoritative.
- HOME texture rect remains unchanged.
- Larger animation canvas is placed by a common screen-space soles pivot.
- Gesture frame swaps change texture only, not animation rect geometry.
- `Art_scrubby` compatibility is preserved.
- Idle deformation is render-only and does not mutate the accepted HOME rect.

## Screen-space safety

PASS across 1080×2160, 1080×1920, 1290×2796 and 1536×2048:
- zero opaque gesture texels in TopCurrencyHUD;
- zero in GiftMeter;
- zero in PlayButton;
- zero in BottomNav;
- zero in SHOP / COLLECTION / TASKS / DAILY functional panels;
- zero required-art clipping.

Helper overlap is correctly warning-only under OWNER V03. Scrubby renders in front of baked helpers, so no scale reduction or helper lifecycle hack was introduced.

## Gesture behavior

PASS:
- Wave production sequence is one wave and returns toward HOME.
- Bow uses the clean bow subset and removes late wave contamination.
- Turn/Look is bilateral: center → right → center → left → center.
- Full Turn is a real 360-degree pose sequence.
- Scheduler weights are Wave 35 / Turn 30 / Bow 25 / Full Turn 10.
- No immediate repeat and no stacking are covered by focused tests.

## Reduced Effects / lifecycle

PASS:
- Reduced Effects produces one static rendered state and refuses gesture starts.
- Hidden Home / focus-out / app-pause return to static HOME and suppress new gesture starts.
- Modal suppresses new starts while allowing a short current gesture to finish.
- Resume receives a fresh 6–12 s delay with no catch-up burst.
- 20× hide/show keeps nodes 131→131 and effects connections 1→1.
- 20× instantiate/free leaves effects connections 0→0 and object delta 0.
- Component remains presentation-only.

## Tests

PASS for M42-C003 and regression scope:
- `tests/m42_c003_scrubby_animation.gd`: 18/18 cases, 158 checks, 0 failures.
- Root `tests/run_tests.gd`: 5323 checks, 0 failures, ALL PASS.
- All relevant M42 Home / composition / scale / navigation / opening suites pass.
- Full top-level sweep: 121/123 suites exit 0.

Two top-level M21 suites remain non-zero:
- `m21_v08_corridor_validation`
- `m21_v09_direct_evidence_reconciliation`

Claude reproduced both failures identically on untouched pre-V03 `origin/main f4ecba8`. They are unrelated routing-corridor baseline debt and are not introduced by M42-C003. Therefore they do not block this task's technical non-regression gate. This is an explicit audit exception to the literal "complete current suite passes" wording in V03 criteria; no M42 regression is present.

## Evidence completeness

PASS:
- 4 contact sheets;
- 4 true-scale HOME→gesture→HOME transition strips;
- 4 frame-accurate 24 fps runtime WebPs;
- 4 required viewport captures;
- screen-space collision report;
- helper-overlap report;
- Reduced Effects evidence;
- lifecycle stability evidence;
- deterministic rerun evidence;
- final manifest pins and final-only runtime binding.

## Remaining owner visual gate

The implementation is technically accepted. The only remaining gate is the existing SB-M42-035 owner visual requirement.

The owner should visually confirm only these three presentation points:
1. Wave reads clearly enough as a friendly single-hand wave.
2. Bow reads cleanly as a bow and does not feel like a wave at the end.
3. The already owner-selected Turn/Look trade-off remains acceptable in motion: stubbier body and brush/backpack side change on left-look frames.

Full Turn has no separate technical blocker.

If those runtime captures are accepted, SB-M42-035 can be marked CLOSED without another implementation cycle.
