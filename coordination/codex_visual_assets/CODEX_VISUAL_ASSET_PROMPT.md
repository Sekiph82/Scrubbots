# SCRUBBOTS — CODEX-ONLY VISUAL ASSET PRODUCTION PROMPT

You are the Codex visual-asset worker for repository `Sekiph82/Scrubbots`.

Your ONLY job is to create/extract/save the visual assets listed in:

1. `coordination/codex_visual_assets/CODEX_VISUAL_ASSET_MASTER_LIST.md`
2. `coordination/codex_visual_assets/CODEX_VISUAL_ASSET_TASKS.md`

Record execution history ONLY in:

`coordination/codex_visual_assets/CODEX_VISUAL_ASSET_LOG.md`

## ABSOLUTE ISOLATION FROM CLAUDE AND PROJECT WORK

This is NOT a Claude task.
Do not read Claude coordination files as instructions.
Do not edit or append to Claude prompts/logs/sessions.
Do not claim Claude work as yours.

You MUST NOT modify:
- `TASKS.md`
- `CLAUDE.md` or any `CLAUDE*.md`
- any existing file in `docs/**`
- any existing file in `coordination/**` outside `coordination/codex_visual_assets/`
- `ASSET_GENERATION_MANIFEST.json`
- `assets/ui/HOME_ASSET_MANIFEST.json`
- any `.gd`, `.tscn`, `.tres`, `.godot`, JSON gameplay/economy/config file, test, workflow, code, project setting, scene, script, or data file
- any non-image project file not explicitly named as your own task/log files

Do not refactor code.
Do not fix bugs.
Do not update documentation.
Do not update manifests.
Do not update the main task system.
Do not alter Godot.
Do not change gameplay.

## ONLY ALLOWED WRITES

You may write:
1. visual image files listed by exact target path in `CODEX_VISUAL_ASSET_MASTER_LIST.md`;
2. raw selected-generation copies under `assets/ui/generated/**`;
3. checkbox status in `coordination/codex_visual_assets/CODEX_VISUAL_ASSET_TASKS.md`;
4. append-only execution notes in `coordination/codex_visual_assets/CODEX_VISUAL_ASSET_LOG.md`.

Nothing else.

Before every commit, run `git status --short`.
If ANY modified path is outside this allowlist, STOP and restore that path before committing.

## IMAGE GENERATION SKILL

Use the shared Codex image-generation skill.

Use built-in `image_gen` by default.
Do NOT use CLI/API fallback, `scripts/image_gen.py`, or `OPENAI_API_KEY` unless built-in image_gen fails AND the owner explicitly approves CLI fallback.

For every DISTINCT image asset:
- issue a separate built-in `image_gen` call;
- do not use one sprite sheet as the only deliverable;
- do not use `n` as a substitute for distinct prompts;
- use transparent output for isolated UI/character/icon assets;
- preserve alpha.

Built-in output may initially land under `$CODEX_HOME/generated_images/**`.
For every project asset:
1. generate;
2. inspect;
3. reject/regenerate weak output;
4. select best valid output;
5. copy/move selected output into the EXACT listed repository path;
6. verify file exists there;
7. mark only that matching task complete;
8. append a short log entry.

Never leave a project-referenced final only under `$CODEX_HOME`.

## VISUAL AUTHORITY

Highest visual references:
- `assets/ui/final/gameplay/master/scrubbots_gameplay_master.png`
- `assets/art/references/_owner_inbox/Game Screens/main screen.png`
- owner Collection-card reference images under `assets/art/references/_owner_inbox/Collection Cards/`

Preserve existing approved production assets. If target file already exists and is owner-approved, DO NOT overwrite it; mark the corresponding task as preserved/existing where applicable.

SCRUBBOTS visual language:
- polished glossy colorful toy-like cartoon 3D mobile game art;
- white/teal cleaning-tech identity;
- cyan/electric lighting accents;
- deep blue/slate technical UI;
- soft cream panel surfaces where present in masters;
- saturated reward colors;
- strong small-screen silhouette/readability;
- no random style drift.

Scrubby invariants:
- white rounded shell;
- glossy black face display;
- cyan expressive eyes;
- teal/cyan accents;
- small green leaf sprout;
- friendly compact canonical proportions.

Economy icon invariants:
- Scrub Bucks are banknotes/cash, NOT coins;
- no Star currency;
- no Event Points;
- Cards Exchange means duplicate cards → Scrub Bucks.

Gameplay visual invariants:
- normal 5 slots;
- temporary 6th only via +1 Slot booster;
- exactly four boosters: +1 Slot, Random, Selector, Tornado;
- Settings is not normal gameplay HUD;
- Hearts are not normal gameplay HUD;
- Pause + 2x are top-right in master gameplay;
- railway visual skin must not encode routing truth.

## PER-ASSET PROMPT SHAPE

Use this production-oriented prompt scaffold:

Use case: stylized-concept or ui-mockup as appropriate
Asset type: <exact role>
Primary request: <exact asset>
Input images: <relevant master/reference roles>
Subject: <single asset subject>
Style/medium: polished glossy SCRUBBOTS cartoon-3D mobile-game asset
Composition/framing: centered, clean silhouette, appropriate mobile scale
Lighting/mood: canonical cyan/teal SCRUBBOTS lighting
Color palette: match master/reference
Materials/textures: glossy toy-like plastic/metal/soft UI materials as appropriate
Constraints: no watermark; no accidental text; preserve canonical identity; transparent background when isolated
Avoid: style drift, photorealism, extra objects, coins, Star currency, baked dynamic labels/numbers

Do not add creative objects not required by the master list.

## QA AFTER EVERY IMAGE

Validate:
- correct asset identity;
- correct reference/style;
- correct alpha/transparency when required;
- no checkerboard baked into pixels;
- no unwanted black/white background;
- no unintended text;
- no watermark;
- no malformed geometry;
- no accidental extra object;
- no wrong currency symbolism;
- no Scrubby identity drift;
- readable silhouette at approximately 64×64, 96×96 and 128×128 for icons.

If a check fails, regenerate with ONE targeted correction and inspect again.

## COLLECTION CARDS

There are 15 sets × 9 cards = 135 individual visual slots in the master list.

Do NOT invent card names or identities.
Use the matching owner reference image for each set.

Prefer extraction/cropping from the approved 3×3 set image when quality is sufficient.
Only generate/reconstruct when extraction is insufficient.
When reconstructing, preserve the exact character/object identity and concept.

Do NOT edit any manifest to record names. Use only your Codex log if notes are needed.

## GIT / LOGGING

Work in sensible visual batches.

After each batch:
1. `git status --short`
2. verify every changed path is allowed
3. `git add` ONLY allowed generated/final image files plus your task/log file
4. commit with a visual-only message
5. push

Suggested commit style:
- `assets(codex): generate gameplay visual components`
- `assets(codex): generate home visual components`
- `assets(codex): generate popup visual components`
- `assets(codex): extract collection set 01 cards`

Append to `CODEX_VISUAL_ASSET_LOG.md` after each batch:
- timestamp
- task IDs completed
- exact output paths
- generation vs extraction
- reference used
- rejected/regenerated attempts
- commit SHA
- blockers

Do not write logs elsewhere.

## EXECUTION ORDER

1. Read master list and this prompt.
2. Audit which exact target image files already exist.
3. Mark preserved/existing visual targets correctly in your own task file without overwriting them.
4. Produce gameplay missing visual assets.
5. Produce Home missing visual assets.
6. Produce reward/difficulty/popup/Daily/Cards Exchange visual assets.
7. Produce Collection UI chrome.
8. Process Collection sets 1→15, cards 1→9 each.
9. Produce robot/shop/common reusable art that is authorized without inventing new robot identities.
10. Perform final allowlist/path audit.
11. Commit/push remaining visual-only work.
12. Append final completion summary to your Codex log.

## STOP CONDITIONS

Do NOT stop merely to ask for routine approval.

Stop only if:
- a listed visual requires a new character identity not present in owner references;
- built-in image_gen is technically unavailable;
- a target conflicts with an owner-approved existing file;
- satisfying the task would require modifying a forbidden non-image project file.

If blocked, log the task as BLOCKED in your own log/task file and continue with all other independent visual assets.

BEGIN AUTONOMOUS VISUAL PRODUCTION NOW.
