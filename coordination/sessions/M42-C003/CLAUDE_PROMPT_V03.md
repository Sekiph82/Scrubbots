# M42-C003 V03 - CLAUDE MASTER PROMPT - RESOLVE V02 CANVAS CONFLICT AND COMPLETE HOME SCRUBBY RUNTIME

Task: `SB-M42-035`
Repository: `Sekiph82/Scrubbots`
Branch: `main`

You are Claude Code. Complete this task end-to-end. The owner does not want to perform any more manual asset preparation.

## Read first

1. `CLAUDE.md`
2. root `TASKS.md` — READ ONLY
3. `coordination/sessions/M42-C003/CHATGPT_AUDIT_V02.md`
4. `coordination/OWNER_M42_HOME_SCRUBBY_ANIMATION_V03.md`
5. `coordination/sessions/M42-C003/ASSET_PRODUCTION_SPEC_V03.md`
6. `coordination/sessions/M42-C003/AUDIT_CRITERIA_V03.md`
7. V02 log/evidence/tool:
   - `CODEX_LOG_V02.md`
   - `evidence_v02/asset_constraint_report.md`
   - `tools/home_scrubby_prepare_assets.py`
8. accepted M42-C002 Home geometry evidence.

## Repository safety

Sync to live `origin/main` first.

Current main may contain unrelated accepted MAINT-SUPPLY-COLUMNS work merged after Codex V02. Preserve it.

If `C:\\Users\\sekip\\Desktop\\ScrubBots` has owner-local dirty files such as `project.godot`, do not stash, reset, clean, or overwrite them. Use an isolated worktree from current `origin/main` if necessary.

Do not edit root `TASKS.md`.

Create/update:
`coordination/sessions/M42-C003/CLAUDE_LOG_V03.md`

## V02 result you must not repeat

Codex correctly proved that forcing the animation into HOME-026's fixed 1158x1358 texture canvas while using legacy texture-space helper keep-outs creates a false representation conflict.

Do not solve that by shrinking Scrubby.

Do not regenerate art.

Do not stop at the same V02 blocker.

V03 explicitly replaces that representation.

## Goal

Use the already verified 63 owner-approved source frames and finish:

1. deterministic V03 normalization;
2. common larger animation canvas;
3. common animation pivot;
4. final asset promotion;
5. HomeScrubbyHero four-gesture runtime;
6. lifecycle/Reduced Effects behavior;
7. screen-space collision validation;
8. complete tests/evidence;
9. commit and push.

## A. Reuse and extend the committed asset tool

Extend `tools/home_scrubby_prepare_assets.py` rather than creating an unrelated second pipeline.

HOME-026 remains byte-identical.

Use the already verified exact source archive/staged bytes. Re-verify hashes.

### Common animation canvas

Normalize the approved source art at HOME-026 character scale using **one scale per source family**.

Then compute the union bounds of all 63 normalized frames around one common soles/root origin.

Create one deterministic larger transparent animation canvas large enough for that union plus safety margin.

All 63 production frames must have:
- same canvas size;
- same pivot coordinates;
- RGBA8 transparent background;
- no crop;
- no badge/text/sheet residue;
- no frame-specific scale.

Document exact canvas dimensions and pivot.

Use a deterministic high-quality resampler for uniform source upscaling.

### Scale selection

Do not fit by raw source-canvas dimensions.

Measure HOME-026 and comparable upright frames using visor/head width, body/limb thickness, and character height.

Choose a family-level scale that preserves perceived HOME physical size.

The V02 "85%" marker is diagnostic only and must not be reused as a blocker.

Turn/Look may still be derived from Full Turn approved frames if that gives better identity continuity.

## B. Production sequence remediation

Keep exact production counts.

### Wave 14
One wave. Return toward HOME raised-hand pose. Reuse/reverse approved source frames if needed.

### Bow 15
Bow only. Remove late wave contamination by rebuilding from the clean Bow subset. Use duplicates/reversal to reach 15.

### Turn/Look 17
Bilateral:
1 center;
2-5 right 25-35 degrees;
6-8 center;
9-12 left 25-35 degrees;
13-17 center.

Use dedicated Turn/Look only if its family scale looks coherent; otherwise use approved Full Turn source frames around the front/right/left arcs.

### Full Turn 17
Real in-place 360-degree turn.

No new painted art.

## C. Runtime component

Implement one:
`scripts/ui/home/home_scrubby_hero.gd`

Preserve child name `Art_scrubby`.

### Critical V03 placement model

HOME-026 keeps its existing accepted texture rect.

Animation textures may be larger.

Compute/use the existing M42-C002 screen soles pivot.

For animation frames:
- apply the same screen-pixels-per-HOME-texture-pixel scale as accepted HOME;
- place the larger animation TextureRect so its common animation pivot lands exactly on the HOME screen soles pivot;
- frame swaps never alter that pivot;
- returning HOME restores canonical HOME-026 geometry.

Do not use the animation canvas dimensions as a reason to shrink the character.

## D. Screen-space safety, not legacy texture K zones

Validate actual rendered opaque bounds against the live Home UI at:

- 1080x2160
- 1080x1920
- 1290x2796
- 1536x2048

Hard blockers:
- Play CTA;
- top HUD/currency;
- functional shortcuts/panels;
- viewport clipping.

Decorative helper overlap is warning-only for all gestures.

If helper overlap is visually poor, you may implement a minimal presentation-only solution:
- ensure Scrubby draws in front of helper, or
- temporarily fade/hide the decorative helper only for the conflicting gesture and restore it reliably afterward.

Do not move functional controls.
Do not alter gameplay state.
Do not shrink individual animation frames.

Legacy K1-K4 may remain as informational diagnostics only.

## E. Gesture scheduler

- Wave 35
- Turn/Look 30
- Bow 25
- Full Turn 10
- 6-12 sec idle interval
- no immediate repeat
- no stacking

Full Turn should remain rare because of its 10 weight.

## F. Reduced Effects / lifecycle

Reduced Effects ON:
- no Wave/Bow/Turn/Full Turn;
- static HOME-026 unless an already-approved blink exists.

No new gesture:
- Home hidden;
- modal active;
- focus out;
- application pause.

Resume:
- clean state;
- fresh 6-12 sec interval;
- no catch-up burst.

20x Home enter/leave:
- no timers/signals/nodes accumulate.

## G. Tests

Update/add focused M42-C003 V03 tests for:

- exact frame counts;
- common canvas dimensions across 63 frames;
- common pivot;
- one scale per source family;
- deterministic output;
- final-only runtime asset paths;
- pivot mapping across HOME vs animation texture dimensions;
- no layout jitter on swaps;
- screen-space hard collision gates at 4 viewports;
- helper warning behavior;
- scheduler weights/no repeat/no stack;
- Reduced Effects;
- lifecycle;
- 20x stability;
- manifest SHA parity.

Run the complete current regression suite and report actual totals.

## H. Evidence

Create:
`coordination/sessions/M42-C003/evidence_v03/`

Required:
- source/hash verification;
- family-scale report;
- common-canvas/pivot report;
- sequence mapping;
- normalization measurements;
- deterministic rerun proof;
- 4 contact sheets;
- 4 HOME->gesture->HOME transition strips at true runtime scale;
- runtime captures/videos if supported;
- 4 required viewport captures;
- live-node screen-space collision report;
- helper overlap/z-order/fade report;
- Reduced Effects capture;
- 20x lifecycle stability report.

Do not fake unavailable video. Frame-strip evidence is acceptable only if the capture mechanism truly cannot record motion, and that limitation must be explicit.

## I. Promotion

When V03 deterministic + hard screen-space gates pass:

promote to:
`assets/ui/final/characters/scrubby/home_animation/{wave,bow,turn,full_turn}/`

Update the current HOME asset manifest schema with exact hashes/provenance.

Runtime must load only final paths.

## J. Finish

Review diff.
Confirm root TASKS.md absent from diff.
Commit focused implementation/evidence.
Push safely to `origin/main`, never force.

Final handoff:

- `AWAITING_GPT_M42_C003_V03_AUDIT` if complete, or
- `BLOCKED_V03_HARD_UI_COLLISION` only if full HOME-authority scale genuinely collides with functional UI even under the larger-canvas model.

Do not return the old V02 canvas/K3 blocker.
