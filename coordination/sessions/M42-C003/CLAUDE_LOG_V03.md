# M42-C003 V03 — CLAUDE LOG — Home Scrubby Runtime Animation (common-canvas remediation)

Date: 2026-10-02
Task: `SB-M42-035`
Prompt: `coordination/sessions/M42-C003/CLAUDE_PROMPT_V03.md`
Criteria: `coordination/sessions/M42-C003/AUDIT_CRITERIA_V03.md`
Owner authority: `coordination/OWNER_M42_HOME_SCRUBBY_ANIMATION_V03.md`, spec `ASSET_PRODUCTION_SPEC_V03.md`
Engine: Godot 4.7.2.stable.official.ed1daf0bf · Python 3.12, Pillow 12.2.0, numpy 2.4.6, scipy 1.17.1
Status: `AWAITING_GPT_M42_C003_V03_AUDIT`

## Sync / safety

- Canonical checkout `C:\Users\sekip\Desktop\ScrubBots`, `main`; fast-forwarded to live `origin/main` `f4ecba8` (incoming: M42-C003 V02 audit, V03 owner decision/spec/criteria/prompt). Accepted MAINT-SUPPLY-COLUMNS work preserved.
- Owner-local state untouched: `project.godot` modification (hash identical before/after every Godot import/run), untracked owner assets/`.import` files, `tests/_m55_diag_tmp.gd`, `stash@{0}`, Codex worktree. No stash/reset/clean.
- Root `TASKS.md` not edited.

## Owner decision taken during this cycle (2026-10-02, in chat)

Turn/Look left arc: the 63 sources contain no ~30° LEFT look that keeps HOME's build and brush hand (Full Turn has right looks 03–05 at ~30° but its only left-facing pose, 10, is ~-23° head with the body turned away and an arm raised). Owner was asked and chose **"Bilateral via Turn/Look family"**. Turn/Look therefore uses the dedicated Turn/Look source family: bilateral, but with a stubbier build than HOME (measured below), and its left-look frames 09/10 hold brush/backpack on the opposite side. This trade-off is owner-accepted and flagged for the visual gate.

## A. Asset normalization (extended `tools/home_scrubby_prepare_assets.py --v03`)

- Re-verified archive SHA-256 `f5c34699…d64458` and all 63 per-file hashes against `OWNER_SOURCE_ASSET_MANIFEST_V02.md`; staged bytes unchanged (`evidence_v03/source_verification.json`, `source_mapping.json`). HOME-026 byte-identical (`fc30b992…3d5c18`). No new art.
- **Identity metric replaced.** The V02 "visor" (dark envelope, 723 px on HOME) also counted dark body pixels. V03 measures the true visor = largest connected near-black component in the upper 60% (HOME 422×287 px), plus character height and a head-yaw estimate.
- **One uniform scale per source family** = median over comparable upright front frames (|yaw| ≤ 15°, height ≥ 93% of family max) of √(visor-width ratio × height ratio) — `evidence_v03/family_scale_report.md`:

| Family | HOME texels / source px | Visor width vs HOME | Height vs HOME |
|---|---:|---|---|
| wave | 3.9189 | 94.7–103.1% | 98.9–102.8% |
| bow | 3.6786 | 97.6–107.2% | 99.2–101.2% |
| turn_look (Turn/Look) | 4.6954 | 99.0–122.4% (mostly ~110%) | 89.5–94.1% |
| full_turn | 4.0517 | 85.5–103.7% | 98.3–100.8% |

  Wave / Bow / Full Turn silhouettes overlay HOME-026 almost exactly at the bookends; Turn/Look is the owner-accepted stubbier build (head ~10% larger, body ~10% shorter).
- **Registration:** every frame's planted root = midpoint of the dark unsaturated rubber soles in the lowest 8% band (bright cyan bristles excluded); HOME-026 root by the same rule = (638.5, 1324.0).
- **Common canvas / pivot:** union of all 63 registered frames + 16 px margin, rounded to 16 → **464×512** RGBA8, pivot **(219, 477)** for every frame (`canvas_pivot_report.md`).
- **Storage density:** 3 HOME texels per animation pixel. All family scales exceed 3 (stored 1.23–1.57 anim px per source px), so no source detail is lost; texture memory 57 MiB instead of 514 MiB at 1:1. Runtime size = canvas × 3 × k, which keeps the exact 1.612 physical scale.
- **Resampler:** Pillow `Image.transform(AFFINE, BICUBIC)` on premultiplied RGBa with exact sub-pixel root→pivot registration; alpha ≤ 2 removed before/after (V02 rule). No crop/warp/skew/per-frame scale.
- **Determinism:** independent second build into a scratch dir: **63/63 byte-identical** (`deterministic_rerun.md`).

## B. Production sequences (`sequence_mapping.json`)

- Wave 14: wave 1–8 then 7→2 (one wave, back toward the HOME raised-hand pose).
- Bow 15: clean subset only — 1–7, hold 7,7, 8–11, 1,1 (late wave-contaminated 12–15 unused).
- Turn/Look 17: 1 centre · 2,6,5,6 right (+24…+35°) · 7,8,8 centre · 9,10,10,9 left (−26…−34°) · 8,15,16,17,1 centre.
- Full Turn 17: full_turn 1–17 (real 360°).
- Durations @12 fps: Wave 1.167 s, Bow 1.250 s, Turn/Look 1.417 s, Full Turn 1.417 s.

## I. Promotion

63 frames copied byte-identical to `assets/ui/final/characters/scrubby/home_animation/{wave,bow,turn,full_turn}/` (raw candidates kept in `assets/ui/generated/characters/home_animation/v03/`). HOME manifest schema extended with `animation_sets.home_scrubby_gestures_v03` (canvas, pivot, home root, density, fps, resampler, family scales, source archive SHA, idle texture SHA, per-frame path + sha256 + source + source sha256). `HomeAssetManifestValidator` validates the section (final .png paths, pins = bytes); `HomeArtBinder.animation_set()` serves textures only from a valid manifest; promoted frames are write-protected. Existing `assets` entries/counts unchanged.

## C/E/F. Runtime — `scripts/ui/home/home_scrubby_hero.gd`

One `HomeScrubbyHero` Control under `Background/Layer_characters` (after `Art_scrubby`, which keeps its name, node, texture, parent and accepted M42-C002 rect). It owns idle, scheduler, frame swapping, gates and the Reduced Effects response; HomeScreen only passes layout (`set_base`), frames (`set_frames` from the binder), effects (`bind_effects(app.effects)`) and modal state (`set_modal` from `_sync_modal`).

- **Placement:** `k` = Art_scrubby width / 1158; HOME soles screen point = Art_scrubby position + (638.5, 1324)·k; gesture TextureRect size = 464×512·3·k, position = soles − (219, 477)·3·k. One rect for every frame (swaps change only the texture). HOME-026 is faded (`self_modulate.a = 0`) during a gesture, never moved.
- **Idle:** ±0.6% squash/stretch about the soles via a render-only canvas_item vertex shader (`IDLE_SHADER`), so Art_scrubby's node rect/transform never changes (existing M42 geometry suites unaffected); exact identity at phase 0, after every gesture, under Reduced Effects and when inert.
- **Scheduler:** uniform 6–12 s idle interval (RNG seam), weights Wave 35 / Turn 30 / Bow 25 / Full Turn 10 excluding the previous gesture, never stacked; the next interval starts only after the return to HOME-026. No Timer/Tween/per-cycle signal.
- **Reduced Effects:** canonical `AppState.effects` + live `changed(reduced)`; ON ends a running gesture at once, refuses new ones, idle = identity (static HOME-026); OFF resumes with a fresh interval. Single connection, released in `_exit_tree`.
- **Lifecycle:** Home hidden (`is_visible_in_tree`), focus out / application paused (own `_notification`) → inert static HOME-026; modal (popups / settings via `set_modal_active`) → no new gesture, a running one finishes; every reopen → fresh 6–12 s interval, no catch-up.
- **Helpers:** baked into the background, so Scrubby always draws in front; no helper fade/hide needed or implemented (warning-only per owner V03).

## D. Screen-space safety (`screen_space_collision_report.md`, `helper_overlap_report.md`)

All 63 frames through the live layout at 1080×2160, 1080×1920, 1290×2796, 1536×2048: **0 opaque gesture texels** in TopCurrencyHUD, GiftMeter, PlayButton, BottomNav, SHOP, COLLECTION, TASKS, DAILY; **0 frames clipped**. Helper warnings (non-blocking): left helper touched by Wave 14/14, Bow 15/15, Turn 13/17, Full Turn 4/17 frames (≤ 696 texels); right helper by Turn 4/17 and Full Turn 10/17 (≤ 4509 texels). Legacy K1–K4 are not used as gates.

## G. Tests

New `tests/m42_c003_scrubby_animation.gd`: 18/18 cases, 158 checks, 0 failures — assets/manifest (counts 14/15/17/17, one canvas, one pivot, one scale per family, HOME-026 SHA, determinism evidence), final-only + SHA parity + tamper → no animation, static fallback, base geometry (1.612 rect unchanged, idle never moves it), pivot mapping (< 0.01 px, 4 viewports) + one rect per gesture (no jitter), frame feet registration (63/63 sole midpoint on pivot ≤ 2 anim px), idle identity/periodicity, durations, scheduler (1 h run: 0 immediate repeats, intervals 6–12 s, conditional weights, Full Turn rare), no stacking + exact restoration, screen-space hard gates (63 frames × 4 viewports), Reduced Effects live, modal, route visibility, focus/pause, 20× stability, presentation-only snapshots, buttons immediately usable mid-gesture (top hit + real clicks).

Existing suites left unchanged and passing with the hero integrated.

## H. Evidence (`coordination/sessions/M42-C003/evidence_v03/`)

- source/hash verification, family-scale report, canvas/pivot report, sequence mapping, normalization measurements (all 63 frames + SHA), deterministic rerun;
- `contact_sheets/{wave,bow,turn,full_turn}.png`;
- `transition_strips/{wave,bow,turn,full_turn}.jpg`: true runtime scale (1:1 viewport px at 1080×2160) HOME-026 → every gesture frame → HOME-026, rendered by the live Home;
- `runtime_captures/*_runtime_24fps.webp`: frame-accurate runtime renders (24 fps, idle → gesture → idle) driven through the deterministic step seam and assembled to animated WebP (half size). Not a screen recording: headless/offscreen capture has no screen recorder, so frames are rendered by the real Home SubViewport at exact animation times;
- `viewports/home_v03_idle_*.png` (4 required viewports) + `home_v03_wave_mid_*.jpg`;
- `screen_space_collision_report.md`, `helper_overlap_report.md`;
- `reduced_effects_report.md` + `reduced_effects_static_1080x2160.jpg` (1 distinct frame over 12 forced attempts);
- `lifecycle_stability_report.md` (20× hide/show: nodes 131 → 131, effects connections 1 → 1; 20× Home create/free: connections 0 → 0, object delta 0).

Tools: `tools/home_scrubby_prepare_assets.py --v03 [--promote]`, `--v03-animate <frames>`; `tests/tools/m42_c003_animation_evidence.gd`.

## Regression

Complete current suite (every top-level `tests/*.gd` except the owner-local `_m55_diag_tmp.gd`): **123 suites, 121 exit 0** (`evidence_v03/regression_summary.txt`).

- The 2 non-zero suites are `m21_v08_corridor_validation` (C/043, C/047) and `m21_v09_direct_evidence_reconciliation` (G-V08-02 B). Both load the M21 debug vertical-slice scene; none of this cycle's files are on their path. They fail **identically on untouched `origin/main` `f4ecba8`** (verified in a temporary detached worktree, removed afterwards), so they are pre-existing and outside SB-M42-035.
- Root `tests/run_tests.gd`: 5323 checks, 0 failures, ALL PASS.
- Includes the new `m42_c003_scrubby_animation` (18/18), M42 Home/v04/v05/v06/v07/composition/C002/assets/navigation/opening, M41 settings, M40 ×4, M43 ×4.
- `git diff --check` clean.

## Handoff

`AWAITING_GPT_M42_C003_V03_AUDIT` — owner visual acceptance of the four gestures (especially the owner-chosen Turn/Look family build/brush trade-off) remains required.
