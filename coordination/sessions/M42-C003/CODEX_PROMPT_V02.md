# M42-C003 V02 - CODEX MASTER PROMPT - SB-M42-035 HOME SCRUBBY ASSET NORMALIZATION + FOUR-GESTURE RUNTIME

You are Codex operating on the canonical ScrubBots checkout:
`C:\\Users\\sekip\\Desktop\\ScrubBots`

Repository:
`https://github.com/Sekiph82/Scrubbots`
Branch: `main`

## Hard authority

Read first:

1. `CLAUDE.md`
2. root `TASKS.md` (READ ONLY, DO NOT EDIT)
3. `coordination/OWNER_M42_HOME_SCRUBBY_ANIMATION_V02.md`
4. `coordination/sessions/M42-C003/ASSET_PRODUCTION_SPEC_V02.md`
5. `coordination/sessions/M42-C003/OWNER_SOURCE_ASSET_MANIFEST_V02.md`
6. `coordination/sessions/M42-C003/AUDIT_CRITERIA_V02.md`
7. M42-C002 accepted geometry/evidence and the existing M42-C003 V01 prompt/log/audit for history.

Owner instruction for this cycle: do the remaining technical work end-to-end. Do not stop to ask the owner to resize, slice, rename, or manually copy image files unless the exact canonical archive truly cannot be found.

## 0. Locate the exact owner archive without bothering the owner

Find `Home_Main_Hero_Assets.zip`.

Search in this order:

- repository root and repo-adjacent files;
- `C:\\Users\\sekip\\Desktop`
- `C:\\Users\\sekip\\Downloads`
- bounded recursive filename search under `C:\\Users\\sekip` only if the above fail.

Required SHA-256:
`f5c34699f14dabc53a5c8126ad81dabd811711d1acd96fda47e523a18ad64458`

If a same-named file has a different hash, do not use it. Continue searching.

Only if no exact-hash archive exists anywhere in those locations may you stop with `BLOCKED_EXACT_OWNER_ARCHIVE_NOT_FOUND`.

Do not upload HOME-026 or owner art to any external service.

## 1. Baseline and safety

- Verify branch/main/origin parity and clean status.
- Preserve untracked owner files.
- Run the current relevant baseline tests before edits.
- Do not edit root TASKS.md.
- Do not modify canonical HOME-026.
- Do not start M43 work.

## 2. Stage source bytes reproducibly

Extract the exact archive.

Verify all 63 PNGs against `OWNER_SOURCE_ASSET_MANIFEST_V02.md`.

Stage exact source bytes under:
`assets/ui/generated/characters/home_animation/source_v02/{wave,bow,turn_look,full_turn}/`

Use canonical, space-free filenames in staging while preserving a machine-readable map from original archive names to staged names.

No runtime code may load this source_v02 directory.

## 3. Build deterministic preparation tooling

Create a committed deterministic tool, preferably:
`tools/home_scrubby_prepare_assets.py`

It must be fully reproducible and safe to rerun.

Use Pillow or already-available local image tooling. Do not introduce a paid/cloud dependency.

The tool must:

- verify archive/source hashes;
- remove only technical sheet residue/alpha speckle if present;
- never redraw the character;
- construct sequence maps;
- normalize every production frame to 1158x1358 transparent RGBA8;
- use exactly one uniform scale per visual source family;
- register root/soles to the HOME-026 authority;
- write measurements, alpha bounds, safe-zone counts and SHA-256;
- create contact sheets and HOME-026 transition strips;
- prove deterministic rerun byte equality.

### Scale fitting rule

Do not use raw source canvas height as the scaling authority.

Fit a single family scale against HOME-026 identity using measurable character features, prioritizing:

1. visor/head width;
2. limb/body thickness;
3. soles/root registration;
4. safe-area constraints;
5. minimum HOME transition pop.

No frame-by-frame scale values.

If the dedicated Turn / Look source requires a visibly different character scale than HOME-026, do not force it. Derive the final Turn / Look sequence from Full Turn source frames and use the Full Turn family scale.

## 4. Build clean production sequences from approved source only

The owner authorizes reordering/reusing approved source frames. Do not generate new art.

### Wave - 14

Inspect the raw 14 Wave frames.

Build a clean single-wave sequence with a first/last in-between close to HOME-026's raised-hand idle.

If raw late frames lower the hand and would pop into HOME-026, omit/reorder them and reuse/reverse clean approved Wave frames.

Exactly 14 output frames.

### Bow - 15

The raw late Bow frames drift into a wave gesture.

Build Bow-only output from the clean bow subset:

- ease into bow;
- hold deepest bow 2-3 frames;
- return through clean bow poses;
- no wave at the end;
- exactly 15 output frames.

Use only approved Bow source frames, including duplication/reversal where necessary.

### Turn / Look - 17

Contract:
center -> right 25-35 degrees -> center -> left 25-35 degrees -> center.

Exact timing shape:
- 1 center
- 2-5 right
- 6-8 center
- 9-12 left
- 13-17 center

Use dedicated Turn / Look raw frames only if identity/scale continuity passes. Otherwise derive from front-adjacent right/left Full Turn frames. Reuse/hold frames as needed.

Exactly 17 output frames.

### Full Turn - 17

Use the approved Full Turn family to make a real in-place 360-degree turn and return to front.

Exactly 17 output frames.

## 5. Candidate validation and promotion

Candidate dirs:
`assets/ui/generated/characters/home_animation/{wave,bow,turn,full_turn}/`

Run all V02 automated checks.

Promote only passing deterministic bytes to:
`assets/ui/final/characters/scrubby/home_animation/{wave,bow,turn,full_turn}/`

Promotion is authorized by OWNER V02 and does not require another manual file-prep step.

Update the existing HOME asset manifest in its current schema with exact SHA-256 and provenance.

Never make the game load `generated` or `source_v02`.

## 6. Implement four-gesture HomeScrubbyHero runtime

Implement the V02 runtime plan.

Preserve M42-C002 canonical scale/placement.

One presentation component:
`scripts/ui/home/home_scrubby_hero.gd`

Keep a child named `Art_scrubby` for compatibility.

Preload/cache textures. Reuse one TextureRect.

Gesture scheduler:
- Wave 35
- Turn / Look 30
- Bow 25
- Full Turn 10
- interval uniform 6-12 seconds
- never immediate-repeat the previous gesture
- never overlap/stack gestures

Runtime bookends every gesture with canonical HOME-026.

Reduced Effects:
- no Wave/Bow/Turn/Full Turn;
- static HOME-026 unless a separately approved blink already exists.

Lifecycle:
- no new gesture when Home hidden;
- no new gesture while modal active;
- inert on focus out / app pause;
- fresh 6-12 second interval on resume;
- no timer/signal accumulation.

Presentation only:
- mouse_filter IGNORE;
- no AppState/economy/progression mutation.

## 7. Full Turn helper-zone handling

Full Turn was added after V01.

Do not silently shrink frames per-frame to satisfy helper zones.

Report K3/K4 overlap per frame.

K1/K2 and canvas containment remain hard blockers.

For K3/K4 Full Turn overlaps, preserve identity/scale and make the runtime evidence explicit. Do not hide the evidence.

Wave/Bow/Turn-Look keep K1-K4 blocking.

## 8. Tests

Add/update focused M42-C003 V02 tests for:

- exact production frame counts 14/15/17/17;
- exact canvas dimensions;
- final-only runtime paths;
- manifest SHA parity;
- stable canonical rect through frame swaps;
- scheduler weights/no repeat/no stack;
- deterministic RNG seam;
- all lifecycle gates;
- live Reduced Effects switching;
- 20x enter/leave timer/signal/node stability;
- asset safe-zone validation;
- HOME bookend behavior;
- Full Turn warning reporting.

Run the complete current test suite.

Do not hardcode stale suite totals; report actual totals.

## 9. Evidence

Create/update:
`coordination/sessions/M42-C003/evidence_v02/`

Must contain:

- source hash verification report;
- production sequence mapping report;
- normalization measurement JSON/MD;
- four contact sheets;
- four HOME-026 -> gesture -> HOME-026 transition strips;
- four 12 fps runtime captures if the current repo evidence tooling supports animation/video capture;
- four required viewport screenshots:
  - 1080x2160
  - 1080x1920
  - 1290x2796
  - 1536x2048
- Reduced Effects static capture;
- 20x lifecycle stability report;
- Full Turn K3/K4 overlap report.

Do not fake video evidence if capture tooling is unavailable. In that case produce deterministic frame strips and state the exact capture limitation.

## 10. Documentation/log/push

Write:
`coordination/sessions/M42-C003/CODEX_LOG_V02.md`

Document:

- exact archive path found;
- archive SHA;
- source verification;
- sequence maps;
- family scales and why;
- registration method;
- validation results;
- test results;
- evidence paths;
- changed files;
- commits;
- any warnings.

Do not edit root TASKS.md.

Review git diff.

Commit focused changes and push safely to `origin/main`. Never force push.

Final handoff status must be exactly one of:

- `AWAITING_GPT_M42_C003_V02_AUDIT`
- `BLOCKED_EXACT_OWNER_ARCHIVE_NOT_FOUND`
- `BLOCKED_V02_ASSET_CONSTRAINT_CONFLICT`

Do not claim PASS yourself. ChatGPT performs the independent audit.
