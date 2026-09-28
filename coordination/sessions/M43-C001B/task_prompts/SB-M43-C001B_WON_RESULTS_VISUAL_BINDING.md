# SB-M43-C001B — WON RESULTS VISUAL / PRODUCTION BINDING

Status: READY FOR CLAUDE
Date: 2026-09-28
Repository: `Sekiph82/Scrubbots`
Branch: `main`

## Read first

1. `CLAUDE.md`
2. root `TASKS.md` READ ONLY
3. `coordination/OWNER_RESULTS_VISUAL_REPLAY_V01.md`
4. `coordination/sessions/M43-C001A/CHATGPT_AUDIT_V01.md`
5. `coordination/sessions/M43-C001A/RESULTS_VISUAL_MASTER_READINESS_V01.md`
6. `coordination/sessions/M43-C001A/RESULTS_FOUNDATION_MATRIX_V01.md`
7. `coordination/OWNER_PLAYER_EXPERIENCE_SURFACE_PROGRAM_V01.md`
8. Life / Help references:
   - `assets/art/references/_owner_inbox/Additionals/life screens.png`
   - `assets/art/references/_owner_inbox/Additionals/need a hand.png`
9. existing victory assets under `assets/ui/final/popups/victory/**`
10. existing reward/common button/frame assets
11. current `scripts/ui/results_screen.gd`, app root and M43-C001A tests

Do NOT edit root `TASKS.md`.

## Owner-locked decisions

### Replay
**NO shipping Replay button in V1 Results.**

Do not implement replay UI, replay launch, replay economy or a Level Select.

### WON Results visual
Use:
- celebrating robot above / overlapping the popup frame;
- **small Victory emblem in the header**;
- Scrubby as the safe runtime robot until equipped-robot authority exists;
- green/yellow Life/Help-family Continue CTA;
- live Godot text/data for title, level, reward amounts, streak, Gift progress and CTA labels.

### LOST
LOST does **not** use the Victory visual master.

Keep existing LOST/Retry functionality operational as a technical fallback, but do not decorate it with Victory art. Dedicated final LOST UI belongs to M43-C004.

## Mission

Promote the technically accepted C001A WON Results foundation into an owner-decision-compliant production visual candidate using existing approved assets and native responsive Godot UI.

Do not create a second Results authority.

Do not change reward/economy/progression behavior.

## Visual composition

For WON Results:

1. dim gameplay behind the modal;
2. warm/light popup composition consistent with Life/Help family;
3. Scrubby victory pose overlaps/peeks above the frame;
4. small `victory_emblem.png` in the header region;
5. live title and Level N;
6. reward rows driven only from the existing committed `reveal_queue`;
7. reward icons may use existing approved assets:
   - Scrub Bucks;
   - Win Streak badge;
   - Bot Parts;
   - Gift Meter / gift-ready;
   - cards only when actually committed;
8. primary Continue uses the green/yellow Life/Help-family style;
9. Home remains secondary and visually subordinate;
10. no Replay control exists.

If the repo has no exact one-piece Life/Help chrome PNG, construct the frame using existing native Godot containers/styles and existing approved UI assets rather than generating speculative art. Do not overwrite or regenerate approved images.

The result should be visually coherent with Life/Help, but should not falsely claim an owner-approved master before the owner sees it.

## Reveal presentation

Use the locked data order:
1. first-clear SB;
2. Win Streak SB;
3. Bot Parts;
4. Gift Meter;
5. cards if committed.

Implement a short deterministic presentation sequence only if it can satisfy all of:
- grant already committed before Results;
- skipping/fast-forwarding cannot change grants;
- rapid taps cannot skip Continue safety;
- Reduced Effects can show all committed rewards immediately;
- no animation owns economic truth.

Do not invent a new reward.

If choreography cannot be safely finalized without owner timing/audio approval, implement the production-safe static/Reduced-Effects path and document the exact remaining visual-only gate instead of fabricating a policy.

## Existing foundation invariants

Preserve:
- committed terminal receipt;
- Results never grants;
- Continue exactly once;
- stale attempt rejection;
- WON-only Continue;
- Level 10 / CONTENT_MISSING safe state;
- LOST Retry M30 behavior;
- hidden Results releases transient reward nodes.

## Replay closure

Remove/avoid any accidental Replay affordance.

Add a regression/source assertion that production Results has no Replay button/action/route.

SB-M43-006 / 011 are owner-resolved as **NO SHIPPING REPLAY**, not as an invitation to build a hidden replay route.

## LOST separation

Prove:
- WON receives Victory composition;
- LOST receives no Victory emblem/robot/reward celebration;
- LOST Retry still works;
- the later dedicated M43-C004 popup can replace the technical fallback cleanly.

Do not implement C004 here.

## Visual evidence

Create deterministic visual evidence for owner review at representative portrait sizes, at minimum:
- 1080×1920 WON Results with typical rewards;
- 1080×2160 WON Results;
- no-next-content Level 10 WON state;
- Reduced Effects/static reward state;
- LOST technical fallback showing no Victory art.

Use repository-safe evidence paths under the M43-C001B session or an existing approved evidence convention. Do not write extra files to the user's Desktop beyond the existing phase-log workflow.

Do not mark `victory_results` as MASTER_OWNER_APPROVED. At most move it to an implementation-candidate state only if the manifest schema already supports such a non-owner-approved status; otherwise leave the manifest unchanged and document readiness.

## Tests

Add/extend focused tests for:
- WON visual nodes/assets bound from live model;
- no Replay control;
- reward rows match receipt and order;
- no duplicate grants on reveal/refresh;
- Continue exactly once;
- Level 10 unavailable state;
- LOST has no Victory art and Retry still works;
- hide/show does not leak nodes/signals;
- representative responsive layouts stay within viewport and touch targets remain valid.

Run relevant:
- M30;
- M39;
- M40;
- M42;
- M43-C001A;
- M52 First 10;
- M55 current-build;
- root suite;
- `git diff --check`.

## Outputs

Create:
- `coordination/sessions/M43-C001B/RESULTS_VISUAL_BINDING_MATRIX_V01.md`
- `coordination/sessions/M43-C001B/OWNER_VISUAL_REVIEW_V01.md`
- `coordination/sessions/M43-C001B/CLAUDE_LOG_V01.md`

`OWNER_VISUAL_REVIEW_V01.md` must point the owner to the exact runtime/evidence views to inspect and list only genuinely unresolved visual-only items.

## Scope locks

Do not:
- implement Replay;
- implement M43-C004;
- implement M43-C002+ other than dependencies already present in the current Results screen;
- generate/overwrite approved art;
- modify First 10 content/supply/difficulty;
- alter Heart/2x/economy rules;
- edit TASKS.md.

## Handoff

Commit and push.

Finish with:

`AWAITING_CHATGPT_AUDIT / M43-C001B WON RESULTS VISUAL BINDING`
