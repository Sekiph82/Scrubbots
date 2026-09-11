# M21-C001 V01 — First Owner-Approved Real-Art Vertical Slice

You are CLAUDE, the implementer/test runner. ChatGPT is the independent auditor.

This is a **critical milestone** governed by Strict Audit Standard v2. Do not self-audit and do not close M21 tasks. Implement the exact scope below, gather truthful evidence, push it, then stop at `AWAITING_AUDIT`.

Canonical repository: `https://github.com/Sekiph82/Scrubbots`
Canonical branch: `main`
Canonical tracker: repository-root `TASKS.md` only.

Audit criteria, all mandatory:
`https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M21-C001/CHATGPT_AUDIT_CRITERIA_V01.md`

Owner approval:
`https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M21-C001/OWNER_ASSET_APPROVAL_V01.md`

Owner validation metadata:
`https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M21-C001/OWNER_ASSET_VALIDATION_V01.json`

M20 final audit:
`https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M20-C001/CHATGPT_AUDIT_V11.md`

Canonical approved source PNG:
`https://github.com/Sekiph82/Scrubbots/blob/main/assets/art/levels/source/easy/scrubbots_m21_level_001_hazard_bot_20x20.png`

## 0. Safe sync, preserve owner/local work, and read governance

Before changing any file:

1. Confirm you are in `C:\Users\sekip\Desktop\ScrubBots`, repository `Sekiph82/Scrubbots`, branch `main`.
2. Inspect `git status --short`, branch/upstream, and remote URLs.
3. Treat every pre-existing tracked modification/deletion and every untracked owner file as owner/local work. Do **not** reset, restore, stash-and-drop, delete, overwrite, or otherwise erase it merely to get a clean tree.
4. Fetch `origin` and safely synchronize local `main` with `origin/main`. Fast-forward when safe. If owner/local work prevents a safe sync, STOP as `BLOCKED`; do not erase it.
5. Re-check status after sync and record preserved owner/local work in the log.
6. Read, in this order:
   - `CLAUDE.md`
   - root `TASKS.md`
   - `coordination/AUDIT_POLICY.md`
   - `coordination/AUDIT_INDEX.md`
   - `coordination/sessions/M20-C001/CHATGPT_AUDIT_V11.md`
   - `coordination/sessions/M21-C001/OWNER_ASSET_APPROVAL_V01.md`
   - `coordination/sessions/M21-C001/OWNER_ASSET_VALIDATION_V01.json`
   - `coordination/sessions/M21-C001/CHATGPT_AUDIT_CRITERIA_V01.md`
   - this prompt
   - `docs/08_PIXEL_ART_PALETTE_RULES.md`
   - relevant LevelData/importer/gameplay architecture docs and source.
7. Identify and apply relevant audit learnings, especially AL-001, AL-003, AL-004, AL-005, AL-006, AL-009, AL-018, AL-026, AL-028, AL-032, AL-033, AL-034, AL-035, AL-041, AL-054, AL-062, AL-063.

Do not touch another repository. Do not inspect or operate on `H-veAI` or `ScrubBots-Level-Factory` for this task.

## 1. Authorized tracker reconciliation FIRST, in a tracker-only pushed commit

The current root tracker is intentionally stale at the V11 audit handoff. ChatGPT has now final-closed M20 in `CHATGPT_AUDIT_V11.md`.

Before any implementation/test edit, update **only the Project Status block and M20 checkboxes necessary to materialize that authorized audit closure**, then start M21:

- mark `SB-M20-001` through `SB-M20-014` `[x]`;
- set post-M20 progress to `304 / 719 = 42.28% (main+ui)` and `304 / 943 = 32.24% overall`;
- set `lastCompletedTaskId` to `M20-C001-V11`;
- set Current Milestone = `M21`;
- Current Sprint = `M21-C001 V01 — first owner-approved real-art vertical slice`;
- Current Task = `M21-C001-V01`;
- Current Task Status = `IN_PROGRESS`;
- Required Actor = `CLAUDE`;
- Next Task/Action = execute this V01 prompt and hand back for independent audit;
- note M20 `AUDITED_PASS / STRICT_V2_FINAL_CLOSURE` and the exact M21 approved source path.

Do **not** close any M21 or M08 task in this transition.

Commit and push this tracker-only transition **before any implementation/test change**. Record the full commit SHA and verify remote `main` contains it.

If you cannot make this clean tracker-only transition while preserving owner/local work, STOP as `BLOCKED`.

## 2. Lock and verify the exact owner-approved source

Canonical source path:
`assets/art/levels/source/easy/scrubbots_m21_level_001_hazard_bot_20x20.png`

The source is immutable for this milestone. Before implementation verify and log all of the following:

- Git blob SHA: `b565743ba52699899007882b750b7c8e7cdd00f9`
- SHA-256: `ede1e02a9096c4c7ba040b91ed7db2d2c2af3b2e20d5c8774068c8d08ad59899`
- file size: `297` bytes
- dimensions: `20 x 20`
- 400 logical pixels
- alpha 255 for every logical pixel
- canonical used colors exactly: `C01,C03,C08,C11,C16`
- exact counts: `C01=30`, `C03=5`, `C08=298`, `C11=11`, `C16=56`
- all 76 perimeter cells are C08
- no C01/C03/C11/C16 perimeter cell
- off-palette = 0
- semi-transparent = 0

Never regenerate, resize, recolor, smooth, optimize/re-encode, overwrite, or otherwise mutate this PNG. Re-check both hashes at the end.

Create:
`coordination/sessions/M21-C001/M21_SOURCE_AUDIT.md`

It must record the M08-style source audit required by the criteria, using repository/owner evidence only.

## 3. Close the M09-to-current-palette contract gap WITHOUT rewriting historical M09 behavior

This is an important part of M21.

Current truth:

- `scripts/tools/level_importer.gd` is an audited generic exact-pixel importer and intentionally preserves a **first-seen row-major local palette**.
- `docs/08_PIXEL_ART_PALETTE_RULES.md` now requires production local palettes to contain only used C01..C16 colors and be ordered by **ascending global C-ID**.
- For this exact source the raw first-seen order is expected to be:
  `C08, C16, C01, C03, C11`
- The production canonical local order must be:
  `C01, C03, C08, C11, C16`

Do not hand-edit the final JSON and do not silently change the historical generic M09 importer contract.

Implement the smallest reusable, isolated **production-art validation/normalization bridge** that:

1. reuses the audited source/import logic rather than inventing an unrelated import pipeline where practical;
2. reads `data/palettes/scrubbots_palette_v2.json` as the machine-readable palette authority;
3. rejects any off-palette source color, with no nearest-color approximation;
4. rejects any production logical pixel whose alpha is not 255;
5. treats canonical `#RRGGBBFF` as opaque-equivalent to `#RRGGBB` without admitting other alpha values;
6. counts distinct colors actually referenced by logical cells;
7. enforces the difficulty color-count band (EASY 3-5 here);
8. normalizes the local palette into ascending global C-ID order;
9. remaps cell palette indices deterministically so visual pixels are unchanged;
10. validates that only used canonical colors exist in the local palette;
11. is deterministic and source-immutable;
12. has direct negative tests for off-palette, semi-transparent, wrong color count, and bad/noncanonical local palette ordering;
13. preserves all historical M09 generic importer regressions.

You may choose the minimal reusable class/tool names after inspecting the current code, but keep the bridge clearly production-content-specific. Do not turn the generic M09 importer into a new incompatible contract.

If you add new write paths, apply the existing audited path-safety/source-immutability lessons rather than introducing a destructive alias/overwrite path.

## 4. Generate the canonical M21 production artifacts reproducibly

Create through code/tooling, not manual JSON editing:

- Level Data:
  `data/levels/m21_level_001_hazard_bot.json`
- Preview reconstructed from final Level Data:
  `assets/art/levels/previews/m21_level_001_hazard_bot.png`
- Appropriate metadata/provenance sidecar under a sensible repository data/metadata location.

Required Level Data truth:

- id: `m21_level_001_hazard_bot`
- name: `Hazard Bot`
- difficulty: `EASY`
- width: 20
- height: 20
- cell count: 400
- local palette: exactly canonical C01,C03,C08,C11,C16 in ascending global C-ID order
- cell-reference counts: C01=30, C03=5, C08=298, C11=11, C16=56

Prove all of the following with executable validation:

- `LevelValidator` PASS;
- `ProductionLevelValidator` PASS;
- the new production-art policy PASS;
- `LevelLoader` loads the committed result;
- reconstruction from final Level Data uses no source shortcut;
- reconstructed 20x20 RGBA8 bytes match the owner-approved source raw RGBA8 bytes for all 400 pixels;
- the committed preview is generated from final Level Data, not copied from the source;
- deterministic rerun yields byte-identical final data/artifact truth and no meaningless diff.

Do not introduce M30 `LevelCatalog` behavior in this milestone.

## 5. Build a REAL production-collaborator M21 vertical slice

The authoritative M21 gameplay evidence must use the committed real Level Data and actual production collaborators, not M20 fault seams.

Use the real current implementations of:

- `LevelLoader` / `LevelData`
- `BoardState`
- `BoardRenderer`
- `SlotSystem`
- `ColorCandidateIndex`
- `ReservationState`
- `TargetSelector`
- the current production targetability/reachability seam required by TargetSelector/Dispatcher; if no production reusable adapter currently exists, add only the narrowest coherent production adapter needed to translate the already-canonical access/routing truth, without duplicating target selection or route generation
- `ProductionAccessQuery`
- `ProductionRoutingSystem`
- `ScrubbotDispatcher`
- `CompleteClearingLoop`

Do not use `M20CandidateSeam`, `M20ReservationSeam`, dispatcher doubles, forced-target seams, or another adversarial test double as a substitute in the authoritative full-real-art run.

Keep the accepted M20 production locked:

- `CompleteClearingLoop` blob must remain `06391839523cbc27e88a4b3ef12b730012cd45fa`
- `ScrubbotDispatcher` blob must remain `eee10149e4f116af6706beec832042352bf3a6dd`

If this first real-art integration exposes a concrete upstream production defect in M19/M20 or another already-closed dependency, **do not opportunistically patch it in this prompt**. Capture exact evidence, set the cycle `BLOCKED`, and hand back to ChatGPT for a scoped correction decision.

Configure exactly five slots against the five final local palette identities. Directly assert that slot identity-to-palette mapping is correct.

## 6. Direct real-art AL-028 reachability proof

This exact artwork gives us a valuable adversarial topology. Use it.

On a fresh real board:

1. Assert all 400 cells start ACTIVE.
2. Assert candidate counts exactly match 30/5/298/11/56 for C01/C03/C08/C11/C16.
3. Assert BoardRenderer initially matches the approved source at **every one of the 400 logical coordinates**, not only sampled points.
4. Assert all 76 perimeter cells are C08 and that no other color is on the perimeter.
5. Before any clear, prove each non-C08 color has raw candidates, then activate its matching slot through the real `CompleteClearingLoop` path.
6. Each non-C08 attempt must fail specifically because no reachable target exists (`NO_REACHABLE_TARGET`), while spawning no agent and creating no reservation. This must not be a fake "no candidate" pass.
7. Activate the C08 slot. It must dispatch a real ScrubbotAgent to a real C08 ACTIVE target through the real production selector + access + routing path.
8. Prove reservation exists before arrival and the agent is actually MOVING.
9. Drive the real agent through its route to authenticated arrival.
10. Prove exactly one target commits ACTIVE -> CLEARED, renderer alpha becomes 0, candidate truth updates, reservation resolves, dispatcher finalizes, and the agent disappears without a return trip.
11. Continue real clears until at least one previously-unreachable non-C08 color becomes genuinely reachable.
12. Prove that same color then dispatches and clears successfully through the production path.

Do not force a target to manufacture this transition.

## 7. Run the full 400-cell real-art level through production gameplay

Add deterministic test/debug automation that repeatedly attempts the five slots and advances successful real agents to arrival until the board is fully cleared.

The driver is **test/debug orchestration only**. Do not add automatic follow-up dispatch, autoplay, slot refill, queue, cooldown, scoring, win/lose, or progression behavior to production gameplay.

The driver must:

- use a finite guard;
- detect and fail on no-progress/deadlock rather than loop forever;
- count each real successful clear once;
- follow real movement/authenticated arrival;
- eventually produce exactly 400 successful clears;
- clear every original color at least once.

Final exact assertions:

- M20 loop cleared_count = 400;
- BoardState CLEARED = 400;
- BoardState ACTIVE = 0;
- all five candidate buckets empty;
- ReservationState count = 0;
- dispatcher active count = 0;
- after required frame/queue-free cleanup, agent-parent child count = 0;
- no orphan ScrubbotAgent;
- all 400 BoardRenderer logical pixels have alpha 0;
- BG01 remains presentation background, never a LevelData palette/cell color.

If frame cleanup cannot be truthfully proven in the synchronous root suite, add a dedicated `tests/m21_real_art_smoke.gd` and run it separately.

## 8. Add a debug-only real-art scene, not production UI

Create a focused debug scene, preferably:
`scenes/debug/m21_real_art_vertical_slice.tscn`
with an appropriately scoped debug script under `scripts/debug/`.

It must:

- load the same committed `m21_level_001_hazard_bot.json`;
- display it through `BoardRenderer`;
- put owner-locked BG01 `#202533` behind the board;
- use the same real production gameplay collaborators for dispatch/clear behavior;
- show the existing debug Scrubbot movement marker or equivalent current M18 presentation without pretending it is final Scrubbot art;
- remain a developer/debug demonstration, not M22 production slot UI;
- not implement touch controls, home UI, win screen, rewards, economy, final VFX, or future visual systems.

Headless-boot/parse this scene as part of validation.

## 9. Capture truthful reference and performance evidence

Create a reproducible M21 reference output from authoritative renderer/scene state. If generated headlessly, label it clearly as a **headless evidence composite**, not as a real-device screenshot or mobile rendering proof.

Create:
`coordination/sessions/M21-C001/M21_VISUAL_GAPS.md`

Record only real remaining gaps, for example the current debug Scrubbot marker versus future owner-approved final character visuals. Do not pre-authorize or bulk-generate Magnific assets, and do not start M22/M27 work.

Record:

- full real-art run clear count;
- elapsed CPU/headless time for the full run;
- any directly measured node/memory observations if you actually measure them.

Never call headless CPU timing mobile FPS/GPU performance. AL-003 applies.

## 10. Tests and regression

Add the smallest clean M21 test surface needed to prove the criteria. Prefer direct authoritative assertions over proxy state.

At minimum run and log individually:

1. `godot --version`
2. project/bootstrap verification currently required by repository policy
3. full root suite: `godot --headless --path . -s res://tests/run_tests.gd`
4. existing M20 queue-free smoke
5. M20 V04 lifecycle smoke
6. M20 V05 lifecycle smoke
7. M20 V07 lifecycle smoke
8. M20 V08 lifecycle smoke
9. M20 V09 lifecycle smoke
10. M20 V10 lifecycle smoke
11. any new M21 smoke
12. headless parse/boot of the M21 debug scene
13. deterministic production-art rebuild/rerun check
14. exact source hash/blob recheck
15. final M20 loop/dispatcher blob recheck
16. `git diff --check`
17. literal inspection for `SCRIPT ERROR` and `Parse Error`

Preserve all prior M19 and M20 V01-V11 root-suite groups. Do not disable a prior regression to make M21 green.

## 11. Claude log and truthful evidence mapping

Create:
`coordination/sessions/M21-C001/CLAUDE_LOG_V01.md`

The log must include:

- starting remote/local SHAs and safe-sync result;
- preserved owner/local work;
- tracker-only start commit full SHA;
- relevant AL-XXX learnings applied;
- exact source Git blob SHA + SHA-256 + source facts;
- source audit summary;
- raw first-seen palette order versus normalized production order;
- exact implementation file list;
- production-art normalization architecture and why M09 generic behavior remains compatible;
- exact generated artifact paths and hashes where useful;
- reconstruction raw-byte result;
- real production collaborator list used in M21;
- initial non-C08 raw-candidate-but-unreachable proof;
- C08 first clear proof;
- previously-unreachable non-C08 later-reachable proof;
- full 400-clear result and final exact state;
- renderer initial 400/400 equality and final 400/400 alpha-0 evidence;
- queue-free/no-orphan evidence;
- reference-output description;
- CPU/headless performance evidence with no FPS overclaim;
- every required command and actual exit/result individually;
- exact changed files;
- final source and M20 production hashes;
- a criteria/evidence table mapping the major criteria groups to exact tests/assertions/commands.

Do not claim manual visual approval in this cycle unless the owner actually performs it after your handoff.

## 12. Final tracker handoff

After implementation and validation, do **not** mark M21 or M08 checkboxes complete. Independent closure belongs to ChatGPT.

Set root `TASKS.md` Project Status to:

- Current Milestone: M21
- Current Sprint: M21-C001 V01 — first owner-approved real-art vertical slice
- Current Task: M21-C001-V01
- Current Task Status: `AWAITING_AUDIT`
- Required Actor: `CHATGPT`
- Next Task/Action: independent V01 audit against `CLAUDE_LOG_V01.md` and `CHATGPT_AUDIT_CRITERIA_V01.md`
- Progress: still `304 / 719 = 42.28% (main+ui)` and `304 / 943 = 32.24% overall`
- `lastCompletedTaskId`: still `M20-C001-V11`

Push all authorized work to `origin/main` without force. Verify remote state and verify the direct GitHub blob URL resolves:

`https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M21-C001/CLAUDE_LOG_V01.md`

## 13. Scope prohibitions

Do NOT:

- alter the approved source PNG;
- regenerate the source;
- use the earlier transparent sprite as production source;
- silently broaden C01..C16;
- nearest-color-map illegal colors;
- silently rewrite historical M09 generic importer semantics;
- hand-edit final LevelData as a substitute for a reproducible pipeline;
- start Level Factory or Content Pipeline sidecar work;
- start M22/M23/M24 UI/touch production;
- implement M25+ win/lose/progression/economy/save;
- add slot refill/queue/cooldown/consumption rules;
- add production autoplay/auto-follow-up dispatch;
- replace real production collaborators with M20 fault seams in authoritative M21 evidence;
- modify accepted M19/M20 production to make this prompt pass;
- close M21 tasks yourself;
- create a ChatGPT audit file;
- assign `AUDITED_PASS` or any self-audit verdict;
- force-push.

## 14. Stop conditions

STOP and hand back `BLOCKED` with exact evidence if:

- owner/local work cannot be safely preserved while syncing;
- approved PNG hash/blob does not match;
- approved source would need modification to proceed;
- a current production rule conflicts with the owner-approved facts in a way that cannot be satisfied without owner decision;
- real-art integration exposes a concrete defect in already-closed M19/M20 production requiring a production change;
- authoritative production gameplay cannot make progress under current canonical rules;
- required validation cannot execute truthfully.

Do not paper over a blocker with a test seam or a manual artifact.

## 15. Final response to the user

If ready for audit, your final user-facing response must be **exactly two lines** and nothing else:

```text
AWAITING_AUDIT
https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M21-C001/CLAUDE_LOG_V01.md
```

If blocked, use `BLOCKED` on the first line and the direct GitHub blob URL of `CLAUDE_LOG_V01.md` on the second line after pushing the truthful blocker log.
