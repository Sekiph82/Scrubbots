# M22-C001 V01 — Production Five-Slot UI Foundation

Repository: `https://github.com/Sekiph82/Scrubbots`
Branch: `main`
Actor: Claude (implementer/test runner)
Auditor/tracker owner: ChatGPT

M21 is closed `AUDITED_PASS / STRICT_V2_FINAL_CLOSURE`. This prompt begins M22 — Production Slot UI.

Your task is to build the reusable production five-slot/color-selection UI foundation while preserving accepted M21 gameplay authority. The M21 debug owner-playtest harness proved the gameplay chain and supplied a minimal SlotView, but it is **not** the final production UI architecture. M23 will own the full gameplay-screen composition.

The strict audit contract is:

`coordination/sessions/M22-C001/CHATGPT_AUDIT_CRITERIA_V01.md`

Every numbered criterion is mandatory unless this prompt explicitly marks it design-gated/deferred.

## 1. Safe sync / repository scope

Work only in `Sekiph82/Scrubbots` on `main`.

Before edits:

1. inspect branch, remote and `git status`;
2. safely synchronize with current `origin/main` while preserving every owner/local tracked and untracked change;
3. no force push, `reset --hard`, destructive clean/restore, stash loss or owner-file deletion;
4. never touch `Sekiph82/ScrubBots-Level-Factory`, `Sekiph82/H-veAI` or any other repository.

Preserve owner-local modifications such as `project.godot`, debug scenes, inbox/import sidecars and any other pre-existing work unless they are explicitly part of this prompt. Do not stage them accidentally.

## 2. Tracker ownership

Read root `TASKS.md` but **do not modify it**.

ChatGPT is the sole writer of root `TASKS.md`. Do not change milestone/sprint/status/progress/check boxes before or after implementation.

## 3. Required reading

Read at minimum:

- `CLAUDE.md`
- root `TASKS.md`
- `coordination/AUDIT_POLICY.md`
- `coordination/sessions/M21-C001/CHATGPT_AUDIT_V10.md`
- `docs/MASTER_UI_SYSTEM.md`
- `ASSET_GENERATION_MANIFEST.json`
- relevant owner-reference inventory/readme files
- canonical gameplay-screen reference metadata
- `scripts/ui/slot_view.gd`
- M12 SlotState/SlotSystem source/tests
- M21 BoardPresentation / owner scene/controller source needed to preserve the accepted spawn-anchor and click path
- M21 V07–V10 tests needed to understand locked behavior.

## 4. M22 V01 product boundary

V01 builds **production reusable components**, not the final full gameplay screen.

Required production component direction:

```text
scenes/components/ui/gameplay/
  slot_cell.tscn
  color_selection_panel.tscn
```

Equivalent names are allowed only if clearly documented and aligned with `docs/MASTER_UI_SYSTEM.md`.

The production slot layer must:

- present exactly five real slot identities;
- present their real bound colors;
- provide touch/mouse activation;
- expose actual laid-out spawn anchors;
- present active/in-flight state;
- remain presentation-only;
- plug into the accepted M21 gameplay chain through a narrow adapter/controller;
- remain reusable when M23 constructs the final gameplay screen.

Do not simply rename the M21 debug scene and call it production.

## 5. Reference audit before implementation

Use the owner-reference authority already in the repository.

Confirm the canonical gameplay art-direction reference from the manifest:

`assets/art/references/_owner_inbox/Game Screens/deneme 3 OK.png`

Audit/inventory any existing owner references relevant to five slots/color selection. Record the exact paths in `CLAUDE_LOG_V01.md`.

Rules:

- references are read-only owner source;
- preserve bytes/names;
- no flattened screenshot becomes interactive production UI;
- slot frame/color tile should remain native Godot UI unless an already-approved production asset explicitly requires otherwise.

## 6. IMPORTANT: zero AI generation in V01

Do **not** call Magnific or any other image-generation provider in this run.

Spend **zero generation credits**.

Reason: the Master UI System and manifest already classify slot frames/color tiles as native Godot components. Scrubby/booster/decorative generation is a different owner/approval lifecycle and is not needed to establish the slot component architecture.

Do not generate booster icons, Scrubby, slot frames, color tiles or decorative props in V01.

## 7. Fix the active manifest debt before future generation

`ASSET_GENERATION_MANIFEST.json` contains stale active pixel-art truth. Correct it surgically while preserving unrelated asset entries/provider policy.

Required corrections:

1. canonical palette source must be:
   `data/palettes/scrubbots_palette_v2.json`
2. allowed IDs must be `C01..C16`, including C16;
3. old class-specific `3–5 / 6–7 / 8–9 / 10–12` color-count bands must no longer be represented as current difficulty-class law;
4. current production used-color envelope is `3..12` canonical colors;
5. manifest must state that difficulty class is **not derived from color count**;
6. preserve Magnific-only UI generation policy;
7. do not change asset statuses to pretend owner approval/generation happened.

Validate JSON after editing.

## 8. Reusable SlotCell / SlotView

Use/migrate the existing `scripts/ui/slot_view.gd` behavior rather than rebuilding working logic gratuitously.

Production component requirements:

- one stable slot ID;
- one scalar color presentation;
- real Button/Control activation surface;
- minimum touch target >= 88 reference px;
- no baked text;
- no mutable SlotState/SlotSystem reference leakage;
- no direct BoardState/TargetSelector/routing/clearing call;
- one activation emits exactly one slot ID;
- presentation-only active state;
- actual laid-out global spawn anchor;
- reusable scene, not only runtime construction inside M21 debug code.

If `scripts/ui/slot_view.gd` is moved/refactored, preserve compatibility deliberately and update all references/tests. Avoid unnecessary path churn if a scene wrapper can reuse it safely.

## 9. Five-slot ColorSelectionPanel

Create a reusable production panel that owns/layouts exactly five SlotCells.

Requirements:

- exactly five visible slots;
- deterministic left-to-right order;
- binds scalar/query presentation from real SlotSystem + level palette mapping;
- container/responsive layout, not five absolute screen positions;
- each cell meets minimum touch size;
- no overlap;
- panel does not become gameplay authority;
- component can be instantiated independently more than once without shared mutable state;
- presentation binding can refresh without silently mutating gameplay model.

Do not invent quantity/refill/upcoming-queue mechanics.

## 10. Interaction adapter to accepted M21 gameplay

Provide a narrow production-compatible integration/demo adapter or harness proving the production panel can trigger the accepted M21 chain.

The chain remains:

`visible slot click -> CompleteClearingLoop -> TargetSelector -> ProductionRoutingSystem -> ScrubbotDispatcher -> ScrubbotAgent -> authenticated arrival -> clear`

Preserve:

- no SPACE gameplay fallback;
- clicked slot's actual spawn anchor;
- bottom-most then left-most target policy;
- one-cell four-side exterior routing corridor;
- no reachable work => no bot;
- exact ReservationState authority;
- M20 clearing authority.

Do not put gameplay truth inside ColorSelectionPanel.

## 11. Active/in-flight visual behavior

Presentation must correctly represent the accepted concurrency model.

Directly prove:

- one in-flight assignment => slot active;
- same slot with 3 assignments stays active through 3→2→1;
- returns idle only at 0;
- two different slots track independently;
- reset clears active presentation without altering M21 reset semantics.

Do **not** invent a final special no-work visual skin in V01. `SB-M22-008` remains open/design-gated unless explicit owner approval exists. Correct no-work behavior is still mandatory.

## 12. Spawn anchor contract

For every production slot:

- anchor comes from actual laid-out slot geometry, preferably top-center consistent with accepted M21 behavior;
- anchor is global/canvas presentation data;
- BoardPresentation maps it into board/AgentLayer route space;
- real route start matches the mapped clicked-slot anchor;
- do not cache a stale pre-layout anchor;
- responsive layout changes must update anchor geometry naturally.

## 13. Responsive / touch matrix

Exercise the reusable production slot panel at all of:

```text
1080x2160
1170x2532
1290x2796
1080x2400
1440x3200
```

Also test:

- one shorter 16:9 portrait viewport;
- one tablet portrait viewport;
- at least one non-zero safe-area inset harness.

For every case record/assert:

- five slots visible;
- no overlap;
- deterministic order;
- each interactive rect >= 88x88 reference px;
- essential slot rects inside safe bounds;
- spawn anchor attached to the correct visible cell;
- no BoardRenderer aspect distortion caused by slot component layout.

Do not claim device-safe support based only on a large comparison rectangle. Execute real Control layout in the test viewport/subviewport before measuring geometry.

## 14. Testing requirements

Add dedicated M22 tests rather than hiding all assertions in the debug harness.

At minimum cover:

- exactly five slot components/stable IDs;
- all five real palette bindings;
- touch size;
- one click -> one event/correct ID;
- rapid input signal behavior;
- active state 3→2→1→0;
- different-slot active independence;
- reset presentation cleanup;
- actual post-layout spawn anchors;
- required responsive matrix + non-zero safe-area insets;
- two independent panel instances do not share mutable presentation state;
- owner source/LevelData remains immutable;
- integration with accepted M21 real-art path.

Tests must be load-bearing, not tautological self-comparisons.

## 15. Mandatory regressions

Run and record exact results:

1. `godot --version`
2. dedicated M22 component/unit test(s)
3. dedicated M22 responsive/safe-area smoke
4. M21 V10 final reservation evidence
5. M21 V09 direct evidence
6. M21 V08 corridor validation
7. M21 V07 corridor smoke
8. M21 V06 tall-layout smoke
9. M21 V05 playtest smoke
10. M21 real-art full 400-clear smoke
11. required M20 queue-free/lifecycle regressions
12. full root `tests/run_tests.gd` with exact check count and zero failures
13. headless boot of the new M22 component/demo harness with zero SCRIPT/Parse errors
14. JSON parse validation of `ASSET_GENERATION_MANIFEST.json`
15. `git diff --check`

Do not install/upgrade/downgrade Godot. Report actual version.

## 16. Protected M21 production behavior

If any M22 UI work appears to require rewriting accepted M21 TargetSelector/routing/dispatcher/clearing/ReservationState behavior, stop and reassess. UI must adapt to gameplay, not silently redefine it.

A genuine M21 regression is `BLOCKED` territory for this prompt. Do not opportunistically patch M21 critical systems inside M22 V01.

## 17. Authorized file surface

Expected/allowed V01 files include only what is necessary for:

- reusable gameplay UI component scenes/scripts;
- a narrow M22 integration/demo harness if required;
- dedicated M22 tests;
- surgical manifest migration;
- reference inventory/metadata evidence if genuinely required;
- `coordination/sessions/M22-C001/CLAUDE_LOG_V01.md`.

Do not modify root `TASKS.md`.

Before commit, inspect `git status` and complete diff. Keep all unrelated owner/local work unstaged.

## 18. Claude log

Create:

`coordination/sessions/M22-C001/CLAUDE_LOG_V01.md`

Include:

- starting/sync state;
- exact changed files;
- owner reference paths audited;
- component architecture/tree;
- scalar/query binding model;
- interaction chain;
- active-state lifecycle evidence;
- spawn-anchor evidence;
- responsive matrix table with measured slot/touch geometry;
- manifest before/after corrections;
- explicit statement: **Magnific credits spent = 0**;
- exact Godot/test command results;
- root check count;
- M21 regression results;
- any deferred/design-gated items;
- statement that root `TASKS.md` was not modified.

Do not author an audit verdict/file.

## 19. Handoff

Commit focused V01 work and push safely to canonical `origin/main`, never force.

Final response exactly two lines:

`AWAITING_AUDIT`

`https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M22-C001/CLAUDE_LOG_V01.md`

If a genuine accepted-M21 production regression is exposed and cannot be resolved strictly within UI adaptation, return `BLOCKED` instead and do not rewrite M21 authority.
