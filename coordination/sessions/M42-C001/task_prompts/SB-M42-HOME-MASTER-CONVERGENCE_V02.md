# SB-M42 HOME MASTER CONVERGENCE — ONE-PASS REMEDIATION PROMPT V02

Status: ACTIVE
Supersedes: `SB-M42-HOME-COMPOSITION-REMEDIATION.md` V01
Scope: SB-M42-011 + SB-M42-017 runtime visual remediation
Repository: `Sekiph82/Scrubbots`
Branch: `main`

## Mission

Bring the production Home screen as close as technically reasonable to the OWNER master visual composition in ONE implementation cycle, while preserving current owner-locked ScrubBots economy/content semantics and the generated-asset lifecycle.

This is not "bind a few missing textures." It is a full Home composition convergence pass.

The complete visual contract is the 222-point register:

`coordination/sessions/M42-C001/SB-M42-HOME-MASTER_ACTUAL_VISUAL_GAP_REGISTER_V01.md`

You MUST process all 222 entries. None may be silently skipped.

## Authority order

Read, in this order:

1. `CLAUDE.md`
2. root `TASKS.md` READ ONLY
3. `coordination/sessions/M42-C001/SB-M42-HOME-MASTER_ACTUAL_VISUAL_GAP_REGISTER_V01.md`
4. `coordination/sessions/M42-C001/audits/SB-M42-HOME-COMPOSED_VISUAL_AUDIT_V01.md`
5. `docs/MASTER_UI_SYSTEM.md`
6. `docs/HOME_UI_ASSET_PLAN.md`
7. `assets/ui/HOME_ASSET_MANIFEST.json`
8. all `coordination/OWNER_M42_HOME_ART_*APPROVAL*.md`
9. canonical owner master reference:
   `assets/art/references/_owner_inbox/Game Screens/main screen.png`
10. OWNER side-by-side comparison:
   `assets/art/references/_owner_inbox/master - actual differences.png`

If any lower document conflicts with a later owner-locked economy/routing/UI decision in CLAUDE.md/TASKS/owner decision artifacts, preserve the later owner decision and record the adaptation.

## OWNER comparison image: first mandatory operation

The owner has already placed this local file inside the working repo:

`C:\Users\sekip\Desktop\ScrubBots\assets\art\references\_owner_inbox\master - actual differences.png`

Before changing Home code:

1. `git pull --ff-only origin main`.
2. Verify the exact local PNG exists.
3. Record:
   - dimensions;
   - file size;
   - SHA-256;
   - Git status.
4. If it is untracked, add it to the repository at the SAME relative path:
   `assets/art/references/_owner_inbox/master - actual differences.png`
5. Commit and push that reference image in a focused reference-only commit before the remediation code commit.
6. Do not resize, recompress, edit, crop or replace the owner's comparison image.

If the local file is missing, STOP with:
`BLOCKED_OWNER_COMPARISON_IMAGE_MISSING`

## Mandatory image inspection

Use the active Claude Code environment's actual image/vision capability to inspect:

- the left side of `master - actual differences.png` as target;
- the right side as baseline actual;
- the canonical standalone `main screen.png`.

Do not claim to have visually inspected an image if the active environment cannot decode/understand it.

### If vision/image reading IS available

Record in the implementation log:
`VISION_INSPECTION_CONFIRMED`

Then write a short baseline visual observation section that is derived from the image itself, not merely copied from the 222-point register. It must mention at least:
- density/empty-space difference;
- top HUD difference;
- Gift Meter difference;
- arch/area-header difference;
- Scrubby/platform relation;
- shortcut-card treatment;
- Play CTA;
- reward track;
- bottom nav.

### If vision/image reading is NOT available

Record:
`VISION_UNAVAILABLE`

Continue implementation using the explicit 222-point register as authoritative. Do NOT pretend visual self-verification was performed. Final owner/ChatGPT visual validation will then remain mandatory.

## Non-negotiable semantic adaptations

The LEFT target controls visual composition but these old semantics MUST NOT be restored:

- coin/star currency -> Scrub Bucks banknote + live SB balance;
- XP -> Bot Parts N/250;
- old event/star meter -> Gift Meter;
- old event timer -> no event timer;
- STAR EXCHANGE -> CARDS EXCHANGE;
- star-road currency -> Win Streak SB +1/+5/+10/+25/+100;
- target's example level/count/timer/badge numbers -> current runtime values;
- all labels/values/timers/counts/state -> live/localizable Godot UI, never baked into generated images.

The target is:
**MASTER VISUAL LANGUAGE + CURRENT SCRUBBOTS SEMANTICS.**

## One-pass requirement

Attempt every applicable requirement in the 222-point register in this single cycle.

Do NOT stop after:
- binding 50 ART entries;
- passing geometry tests;
- making the screen "functional";
- making only the most obvious fixes.

The target is the complete visual system:
profile/HUD + Gift Meter + area arch + world/hero/platform + environment/helper bots + shortcut cards + Play CTA + reward track + bottom nav + typography/contrast/spacing/depth.

## Required architecture correction

The existing implementation demonstrated a conceptual bug: `HomeArtBinder.summary() == {"APPROVED_BOUND": 50}` proves lifecycle availability, not visible presentation.

Create a real presentation map/accounting layer.

For every manifest ART entry, production/tests must identify:
- `STATIC_PRESENTATION`: concrete Home node visible in the normal composition;
- `STATE_PRESENTATION`: concrete node/state/animation destination;
- `REUSE`: HOME-087 -> HOME-042 exact-file reuse.

No approved ART entry may be orphaned with no presentation destination.

The mapping must be testable without relying on screenshots alone.

## Composition requirements

### 1. Overall layout

Rebuild the Home spatial hierarchy to match the master:
- branded top HUD;
- substantial Gift Meter band;
- area arch/header;
- central world with Scrubby/platform/props/helper bots;
- left/right shortcut card columns framing the hero;
- branded Play CTA immediately below the hero/platform region;
- strong Win Streak reward track;
- distinct branded bottom-nav dock.

Reduce huge dead sky/ground bands. The taller viewport must be intentionally composed, not merely stretched.

### 2. Top HUD/profile

Integrate and visibly present:
- HOME-027 scrubby_portrait;
- HOME-034 profile_avatar_frame;
- HOME-035 profile_rank_badge;
- HOME-042 Scrub Bucks;
- HOME-043 Heart.

Use native/live labels for player name, rank/title, level, Bot Parts, SB and Hearts.

If a canonical player-name/rank value does not yet exist, do not invent durable gameplay truth. Use a clearly documented presentational/default localization seam only if existing project architecture already permits one.

Restore a strong top-right menu affordance only if consistent with current navigation architecture. Do not invent a new settings truth path.

### 3. Gift Meter

Integrate HOME-051 and HOME-054 into a strong branded meter.

Keep:
- progress;
- current value;
- next milestone;
- claimable count

live/native.

No Event Points. No event timer.

### 4. Arch / area identity

Integrate:
- HOME-006;
- HOME-007;
- LIVE HOME-008;
- LIVE HOME-009.

Area title/number must remain live/localizable.

Use the arch to frame the central world as the master does.

### 5. Scrubby/platform/world

Create independently positionable layers/nodes for:
- HOME-010 platform main;
- HOME-011 platform top;
- HOME-013..021 environment props;
- HOME-022..024 helper bots;
- HOME-026 Scrubby;
- optional HOME-031/032 state/idle layers.

Required relationship:
- Scrubby is visually grounded;
- feet contact platform;
- platform top is visible beneath him;
- no platform ring/body through torso;
- world props create foreground/midground depth;
- helper bots make the world feel populated;
- hero remains visually dominant.

Use current approved assets first.

### 6. Shortcut cards

Replace thin translucent list-row appearance with substantial branded cards inspired by the master, using native Godot styles plus approved icons.

Both columns:
- strong card body;
- large readable icon;
- full live label;
- visible badges;
- clear disabled treatment;
- enough opacity/contrast over the world.

The following must not clip at reference viewport:
- WIN STREAK;
- COLLECTION;
- CARDS EXCHANGE.

Do not solve clipping by baking labels into images.

### 7. Play CTA

HOME-078 must visibly frame a real native interactive Button.

Target treatment:
- dominant green CTA;
- live PLAY/CONTINUE label;
- visible play triangle;
- live frontier/continue subtitle where canonical launch data supports it;
- strong border/depth;
- button hit region corresponds to visible CTA.

Do not hardcode Level 329.

### 8. Win Streak reward track

Integrate visibly:
- HOME-086;
- HOME-087 reuse;
- HOME-090;
- HOME-091;
- HOME-092;
- HOME-093;
- HOME-094.

Build a coherent track/container with:
- five visible reward objects;
- live +1/+5/+10/+25/+100 SB values;
- clear current/reached/future states;
- readable progression line/fill;
- no Star semantics.

### 9. Bottom navigation

Integrate visibly:
- HOME-101 Events;
- HOME-102 Robots;
- HOME-103 Home;
- HOME-104 Leaderboard;
- HOME-105 Settings.

Use:
- full-width branded dock;
- icon + live label;
- clear tab boundaries;
- obvious selected Home state;
- current HOME/SETTINGS behavior unchanged;
- future destinations remain disabled.

### 10. Typography/contrast

Use available project fonts/styles to approach the target's strong game-UI hierarchy.

Do not add unlicensed external fonts.

Required:
- stronger headings;
- branded button/card typography;
- robust contrast;
- no important text directly lost in busy art;
- disabled state readable;
- no unnecessary ellipsis at reference viewport.

## Approved asset immutability

Before implementation:
- record Git blob SHAs for all 49 unique owner-approved PNG paths.

After implementation:
- prove those 49 blobs are unchanged unless the owner has explicitly replaced approval in a new owner artifact. There is no such replacement authorization in this task.

Therefore:
- no overwrite of approved PNG;
- no recompression;
- no silent regeneration;
- no move/rename.

## When existing approved art itself prevents convergence

The owner now wants the complete master-vs-actual gap addressed, including visual differences not caused by layout.

Examples that may require asset-level change:
- Scrubby pose/silhouette materially differs from master;
- background art direction remains too generic/empty even after approved overlays/props are composed.

Handle those only after exhausting layout/composition solutions.

### If the active environment has an authorized image-generation skill/connector

You MAY create replacement CANDIDATES only.

Rules:
- candidate path must be under `assets/ui/generated/`;
- never overwrite `assets/ui/final/`;
- preserve exact current approved file;
- candidate prompt must use master visual direction and current ScrubBots identity/semantics;
- record generation provenance;
- candidate remains `ASSET_CANDIDATE_OWNER_REVIEW_REQUIRED`;
- do not change manifest APPROVED pin to candidate;
- do not claim item fully closed until owner approval.

### If no authorized image-generation capability exists

Do not fake it.
Record the exact asset IDs that still prevent visual convergence as `BLOCKED_WITH_PROOF`, explain what cannot be solved by layout, and continue every other remediation item.

## Iterative visual loop

Do not implement once and stop.

Create or reuse a deterministic Home visual snapshot harness that can render the production Home composition at 1080x2160 with representative non-destructive app state and save a PNG OUTSIDE approved art paths.

At minimum run this loop:

1. baseline snapshot;
2. implementation pass;
3. render new 1080x2160 snapshot;
4. if vision available, inspect target vs new snapshot;
5. update the 222-item ledger;
6. remediate remaining visual/code issues;
7. render final snapshot.

If vision is available, perform at least TWO post-change visual inspections before handoff unless the first inspection is blocked by an engine failure.

Never use a pixel-similarity score as the sole visual verdict. Dynamic values and adaptive layout make raw pixel equality meaningless.

## 222-item completion ledger

Create:

`coordination/sessions/M42-C001/task_logs/SB-M42-HOME-222-COMPLETION-LEDGER.md`

It must contain one row for EACH item 1..222:

| # | Final status | Evidence/node/file/test | Note |
|---|---|---|---|

Allowed final statuses:
- `FIXED`
- `PRESERVED_V1`
- `ASSET_CANDIDATE_OWNER_REVIEW_REQUIRED`
- `BLOCKED_WITH_PROOF`

There must be exactly 222 numbered rows and no missing/duplicate numbers.

The summary must report exact counts by status.

A vague group-level claim such as "all UI fixed" is not acceptable.

## Runtime visual evidence

Create final evidence images from the actual production Home composition at least for:
- 1080x2160;
- one tall-phone viewport;
- one compact/16:9 portrait viewport.

Store evidence under:
`coordination/sessions/M42-C001/runtime_evidence/home_master_convergence/`

These are audit evidence, not production art.

If vision is available, inspect the 1080x2160 final evidence image before handoff and record the residual differences.

## Responsive validation

Validate at minimum:
- 1080x2160
- 1170x2532
- 1290x2796
- 1080x2400
- 1440x3200
- existing 16:9 portrait case
- existing tablet portrait case

At every viewport:
- no critical label clipping;
- no control outside safe area;
- >=88 px touch target;
- no art intercepts interaction;
- Scrubby/platform relationship coherent;
- shortcut cards frame rather than obscure hero;
- Play visible/usable;
- reward track visible/readable;
- bottom nav visible/usable;
- top HUD/Gift Meter readable;
- dynamic labels remain live.

## Tests

Update/add tests to validate PRESENTATION, not only binder lifecycle.

Required test categories:
- every approved ART has a presentation-accounting entry;
- every static default asset resolves to a concrete node;
- state/idle layers resolve to a concrete state node;
- HOME-087 exact reuse;
- full labels fit reference layout;
- Play frame is present on a native Button control;
- bottom-nav icons are present;
- reward gift art is present;
- arch/area live text nodes exist;
- Scrubby/platform vertical ordering/contact invariant;
- decorative nodes are MOUSE_FILTER_IGNORE;
- approved assets remain write-protected;
- unapproved/mismatched candidate still cannot bind;
- responsive matrix geometry/touch tests.

Required commands:
- `godot --headless --path . -s res://tests/m42_assets.gd`
- `godot --headless --path . -s res://tests/m42_home.gd`
- `godot --headless --path . -s res://tests/m42_navigation.gd`
- any new focused visual-composition test
- `godot --headless --path . -s res://tests/run_tests.gd`
- `git diff --check`

Require exit 0, zero SCRIPT ERROR and no hidden FAIL.
Known intentional corrupt-image engine ERROR lines may remain only if they exactly match baseline behavior.

## Forbidden

- Do not edit root `TASKS.md`.
- Do not edit ChatGPT audit files.
- Do not edit owner approval/decision files.
- Do not silently rewrite economy semantics toward the old master.
- Do not bake live text/values into art.
- Do not flatten the master screenshot into the shipping UI.
- Do not weaken manifest/hash validation.
- Do not claim owner visual acceptance.
- Do not call a hash-valid asset "visibly integrated" unless a concrete presentation node/state uses it.

## Implementation log

Create:
`coordination/sessions/M42-C001/task_logs/SB-M42-HOME-MASTER-CONVERGENCE-V02.md`

Include:
- baseline HEAD;
- owner comparison-image commit SHA;
- comparison image SHA-256/dimensions;
- vision status;
- baseline visual observations;
- changed files;
- architecture/presentation map;
- before/after approved blob proof;
- 222-ledger summary;
- any asset candidates/blockers;
- snapshot paths and visual iterations;
- viewport matrix;
- all tests;
- final implementation SHA;
- explicit confirmation that TASKS/owner/ChatGPT artifacts were untouched.

## Commit structure

Prefer:
1. reference-only commit for owner's comparison PNG;
2. focused Home implementation/test/evidence commit(s);
3. final log commit.

Push all to `main`; never force-push.

## Final handoff

Only when implementation/tests/evidence are complete, stop with:

`AWAITING_CHATGPT_AUDIT / M42 HOME MASTER CONVERGENCE V02`

Also report:
- `222 ledger: X FIXED / Y PRESERVED_V1 / Z ASSET_CANDIDATE_OWNER_REVIEW_REQUIRED / W BLOCKED_WITH_PROOF`
- vision status;
- final implementation SHA;
- final log path.

SB-M42-011 and SB-M42-017 remain open until ChatGPT audit AND owner review of the new runtime Home.
