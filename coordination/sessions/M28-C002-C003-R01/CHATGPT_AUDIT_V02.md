# M28-C002-C003-R01 — CHATGPT INDEPENDENT AUDIT V02

Date: 2026-09-29
Auditor: ChatGPT
Repository: `Sekiph82/Scrubbots`
Audited implementation: `041729c92b57517e2c203306b0666f341c75eee5`
Prompt: `coordination/sessions/M28-C002-C003-R01/CHATGPT_PROMPT_V02.md`
Criteria: `coordination/sessions/M28-C002-C003-R01/CHATGPT_AUDIT_CRITERIA_V02.md`

## Verdict

**AUDITED_PASS / OWNER FINAL REPLAY REQUIRED**

The five requested remediation findings are technically accepted.

SB-M28-C002-020 remains OPEN because the audit criteria explicitly require owner hands-on/visual acceptance before M28-C002 can close.

## Audit method

This is an independent code/evidence audit, not acceptance of Claude's self-report.

Verified directly:
- the exact implementation commit and complete changed-file list;
- production changes in speed lifecycle, slot presentation, routing, BoardRenderer/shader and Home binding;
- the new focused remediation suite;
- the committed regression/evidence matrix and binary evidence presence;
- the prior independent M28 audit for the historical M21 baseline;
- governance: the implementation commit does not edit root `TASKS.md`.

The repository-connected interface does not expose PNG/MP4 pixels to this auditor as model-visible image bytes. Therefore final visual taste/readability remains intentionally in the OWNER gate, exactly as required by criterion G. Code paths, asset binding, hashes, runtime assertions and evidence-file presence are independently inspected.

## A. Timed 2x

**PASS.**

Production lifecycle inspection confirms:

- `ProductionGameplayHost.build()` creates the runtime/economy graph and then calls `_apply_default_speed()`.
- `_apply_default_speed()` reads authoritative `timed_seconds_remaining() > 0` and sets BOTH runtime speed and screen speed state together.
- current-level-only 200 SB entitlement is intentionally not used as a new-attempt default;
- Retry calls `_on_retry_restored()`, which reapplies the timed default after the runtime reset;
- manual 1x while a timed entitlement is active is allowed and does not consume SB;
- the next newly built/restarted attempt reapplies timed 2x;
- mid-level timed expiry drops paid 2x unless authoritative supply exhaustion has already handed speed ownership to free M23 auto-2x;
- level-scoped entitlement remains level-scoped;
- no economy price/duration file changed.

Focused test inspection is substantive rather than HUD-only:
- real level progression 1 -> 2 -> 3;
- timed purchase;
- Results/Continue;
- manual 1x;
- Retry;
- save/relaunch;
- expiry;
- current-level product no-leak;
- free M23 auto-2x independence.

No mismatch found between runtime factor and HUD state at attempt start.

## B. Slot WAITING / ACTIVE text

**PASS.**

`BatchSlotView` retains authoritative `ACTIVE`/`WAITING` internal state but sets the player-facing state label text to an empty string for occupied and empty states.

The former label's measured box is reserved to preserve slot geometry / spawn anchors.

The five-slot and temporary sixth-slot path use the same view component. The focused suite additionally scans the complete gameplay screen for visible WAITING/ACTIVE strings and verifies live counts remain present.

State remains visually distinguishable by border presentation.

No slot/accounting logic changed.

## C. Railway-first routing

**PASS.**

The production default now uses a railway-first weighted Dijkstra:

- connector and rail movement retain low travel cost;
- board-interior movement has a dominant positive cost;
- within the current supported 20..59 board envelope this makes route choice lexicographic: minimise interior-board travel first, then rail/connector distance, then deterministic side/scan tie-break;
- returned routes remain RouteValidator-clean;
- exterior travel remains on the canonical rail;
- no diagonal shortcut post-process is applied to Railroad routes.

The focused suite is not circular-only. It uses:
- an independent aligned-exit oracle on fully open boards;
- left/right/top/bottom/deep target cases from multiple slot origins;
- corner and corner-adjacent cases;
- a blocked aligned-ingress case with an independent BFS oracle for the nearest legal ingress;
- axis-alignment checks;
- legacy-vs-new route comparison;
- a real production-host comparison proving identical first-wave assigned targets;
- full-drain comparison proving identical clear set, exactly-once clearing, WON completion and zero residual reservations.

### Solver / difficulty separation

The solver kernel and difficulty analyzers explicitly pin routing weight to `TOTAL_TRAVEL_COST = 1.0`.

This does **not** create a targetability split because the legal graph/access rules are unchanged and all weights remain positive; only the selected legal path differs. The new focused real-host proof also confirms identical target/claim/clear identity across the two cost models.

This preserves previously accepted solver/difficulty evidence while changing only live Scrubbot travel-path preference.

### Coordination correction required

The older owner Railroad document and `CLAUDE.md` still describe "shortest total legal route" as the runtime route-choice rule. That wording is superseded by this owner-requested V02 railway-first rule and is corrected by ChatGPT in the post-audit coordination update.

## D. Dynamic logical-pixel grid / bevel

**PASS.**

Implementation uses:
- one `ShaderMaterial` on the existing single `BoardRenderer` TextureRect;
- real board width/height passed as `grid_size`;
- no fixed mask texture;
- no per-cell Nodes;
- density-adaptive gutter/bevel strength;
- renderer logical pixels remain unchanged;
- renderer cell geometry / centers remain unchanged;
- shader alpha-gates each logical cell so a CLEARED alpha-0 cell outputs fully transparent.

Focused test inspection verifies:
- 20x20, 32x32, 38x38, 59x59 and rectangular densities;
- real dimensions are bound to the shader;
- style weakens as density increases;
- palette texels and coordinates are identical with grid enabled/disabled;
- cleared texel remains alpha 0;
- 59x59 still has zero child-cell nodes.

The separate GPU evidence probe covers six dimensions and reports rendered boundary/palette/ghost checks.

Final visual strength/readability remains an owner replay item.

## E. Owner-selected Home background

**PASS technically / OWNER VISUAL REVIEW REQUIRED.**

Runtime authority now points World 01 to:

`assets/ui/final/home/background/home_background.png`

Verified:
- HOME-121 points to that exact final path and pins SHA-256 `9d5db29513d25ad5c0932840c08027be0198d0cd85dc758a69e09e800c7aabe2`;
- `HomeArtBinder` binds only approved final assets whose runtime file hash matches the manifest;
- `home_worlds_v1.json` uses the HOME-121 slug and the image's 940x1672 canvas;
- HOME-120 is marked `OWNER_RETIRED` with no active node;
- the runtime test asserts the WorldBackground texture's exact resource path, dimensions and SHA;
- the focused test scans visible TextureRects and asserts exactly one selected Home background and no visible old World/layered background texture;
- PLAY, shortcuts, nav, Gift Meter, currency and Scrubby remain separate live native nodes.

Independent limitation: because the selected file was previously untracked local owner content, Git history cannot reconstruct its pre-commit bytes for an external before/after comparison. The committed runtime path/hash is internally pinned and no regeneration code was introduced. Owner visual replay is the final identity/taste gate.

## F. Scope / regressions / governance

**PASS.**

Implementation commit changed no root `TASKS.md`.

No Economy V1 price/duration config, Heart rules, booster rules or entitlement product definitions were changed.

No TargetSelector, claim engine, ReservationState, BoardState or completion authority was changed.

Submitted regression evidence:
- focused R01 V02: 24/24 PASS;
- M28 final gate: PASS;
- required M29/M30/M39/M40/M42/M43/M52/M55 suites: PASS;
- routing/clearing/solver and M53 difficulty suites: PASS;
- root suite: 5323/5323 PASS;
- `git diff --check`: clean.

### Historical M21 non-zero suites

The reported:
- `m21_v08_corridor_validation`: C/043, C/047;
- `m21_v09_direct_evidence_reconciliation`: B

match the prior independent M28 audit baseline, which already records the same exact historical findings before this remediation. They are not introduced by this commit and are non-blocking here.

### Existing M39 clock-boundary test flake

`m39_v04_integration` passed in this submitted run. Its known real-clock snapshot nondeterminism remains a separately queued task, SB-M39-053, and is not reclassified as fixed by this cycle.

## G. Owner final replay

**REQUIRED.**

Technical PASS does not close SB-M28-C002-020.

Owner must verify in the actual Godot runtime:

1. Buy timed 2x, finish a level, Continue: the next level starts live 2x; also verify app close/relaunch while time remains.
2. Five-slot and six-slot states show no WAITING / ACTIVE words.
3. Scrubbots visibly stay on the railway and leave near the assigned target rather than cutting across the board.
4. Grid/bevel is visually readable on small, medium and dense boards and does not feel over-strong.
5. Home uses the selected new background; review Scrubby placement and the known mirrored side-band seam on short/wide/tablet layouts.

Only owner acceptance closes SB-M28-C002-020.

## Non-blocking notes

- `scripts/ui/home/home_screen.gd` header comments still mention the historical HOME-120 / 1080x2160 authority in places. Runtime data is HOME-121 / 940x1672. This is documentation drift only and does not affect the technical verdict.
- Railway authority wording required a coordination update because the old "minimum total route" policy is no longer the owner's runtime preference.

## Final

**AUDITED_PASS / OWNER FINAL REPLAY REQUIRED**
