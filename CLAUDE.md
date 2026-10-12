# SCRUBBOTS — AI Agent Operating Manual

Status: **OWNER-LOCKED operating rules, updated 2026-09-27**

Historical pre-Difficulty-V1 manual is archived at:
`docs/migration/legacy-task-trackers/CLAUDE_PRE_DIFFICULTY_V1_2026-09-12.md`

## 0. Tracking authority

- GitHub `origin/main` is repository/project-state authority.
- Repository-root `TASKS.md` is the **only live project-status tracker**.
- There is no parallel project-status index/dashboard/roadmap. Do not create or maintain `coordination/SESSION_INDEX.md`, `coordination/AUDIT_INDEX.md`, `docs/04_ROADMAP.md`, `.hiveai/PROJECT_DASHBOARD.md`, or any equivalent live tracker.
- Read the root `TASKS.md` Project Status block before material work.
- **Root `TASKS.md` is ChatGPT-write-owned. Claude/Codex must read it but must not edit it during implementation, validation, or handoff. ChatGPT updates it after independent audits, owner-gate decisions, and before handing the next prompt to an implementer.**
- ChatGPT is the independent auditor. Claude/Codex implement and test; they do not self-award `AUDITED_PASS`.

## 0A. Owner execution & storage policy: ONE DESKTOP CHECKOUT + CLOUD-FIRST TEMP [OWNER UPDATE 2026-10-12]

**This is the LATEST owner instruction and supersedes the absolute ZERO-TEMP prohibition dated 2026-10-10 for FUTURE work only.** The owner conditionally permits TEMP if it does not consume meaningful laptop storage or leave files accumulating. This does **not** retroactively excuse earlier zero-TEMP violations. Do not claim a literal zero-byte local footprint: Claude Code and normal developer tools may write tiny transient OS/session files.

**Primary work location:** all authored game source, Git changes, task logs and owner-facing results in the ONE existing checkout:
`C:\Users\sekip\Desktop\ScrubBots`.

- **Cloud-first for all sizeable temporary work**: execute Godot imports, integration tests, content pack generation, builds, heavy regression, large downloads and intermediate output on GitHub-hosted Actions runners whenever suitable and explicitly authorized for that task. Runner `RUNNER_TEMP` and its caches reside on GitHub machines, **not** on the owner's laptop. Use existing workflows, prefer validation-only on existing Android workflow; no new APK/IPA/R2 publication without explicit approval.
- **On-laptop disk budget for incidental TEMP**: minimal unavoidable tool/harness session data may exist locally while running, provided the task-specific incremental local TEMP footprint is **at most 20 MiB at any one time**, kept brief, and owner-safe automatic or exact-path cleanup is performed when no longer needed. This is an upper guardrail, **not a target** or permission to create local test workspaces. If a tool is expected to exceed that amount, ownership/size cannot be checked, cleanup cannot safely be done, or files persist unexpectedly, STOP and disclose the path/size; use an approved GitHub runner instead.
- **Never create local heavy TEMP**: NO task scratchpad, alternate/duplicate clone, Git worktree (including sparse ones), shadow repository, 3D/render fixture cache, local APK/PCK export staging, or large downloaded test packs. Do not run local Godot tests/imports if they would produce significant `user://`, `.godot` or AppData cache; route to remote CI. Do not create hundreds of small artifacts that cumulatively exceed the budget.
- **Cleanup safely, not destructively**: before and after each task, report laptop disk-space delta, NEW TEMP paths and sizes when observable; remove only exact, clearly task-owned, no-longer-active disposable artifacts once safe. Never delete another session's worktree, pre-existing logs, owner files, untracked work, caches needed by an active process or stashes. If safe cleanup is uncertain, ASK the owner; do not brute-force removal. Do not claim that a transient is removed without checking it.
- **Prevent gratuitous generated files**: avoid background tool features that create task-output files if direct foreground execution suffices; avoid heredocs and tools known to create unmanaged local files when a file-free alternative exists. The local Claude harness itself can have unavoidable transient metadata; observe and report, do not guarantee it is physically absent while running.
- **Preserve all owner state**: read current `origin/main`, safely fast-forward Desktop only when no owner edits conflict. Preserve every owner-modified tracked file (including `project.godot`), untracked files, stashes, original art and unrelated session data. No `git reset --hard`, `git clean`, implicit stash, destructive checkout or force push. Stage task files only.
- **Root `TASKS.md` is ChatGPT-write-owned**; Claude reads but never edits it. ChatGPT owns independent audit. Prompts must cover complete milestones as ONE MASTER PROMPT, not a string of independently dispatched small tasks.
- A previous audit's `OWNER_ZERO_TEMP_PROCESS_NONCOMPLIANT` accurately describes conduct under the **prior** 2026-10-10 policy and remains in its historical audit; future owner-approved bounded TEMP is assessed under THIS newer policy.

## 1. Required reading order

Before material implementation:

1. `CLAUDE.md`.
2. root `TASKS.md`.
3. `coordination/AUDIT_POLICY.md`.
4. active cycle prompt/criteria/owner artifacts in version order.
5. latest explicit owner decisions relevant to the subsystem.
6. relevant `docs/` specifications.

For difficulty, progression, level generation, campaign sequencing or level QA, always read:

- `coordination/OWNER_DIFFICULTY_PROGRESSION_DECISION_V01.md`
- `docs/09_DIFFICULTY_PROGRESSION_RETENTION_SYSTEM.md`
- `docs/10_LEVEL_FACTORY_GENERATION_SCORING_ARCHITECTURE.md`
- `docs/11_LEVEL_DIFFICULTY_CALIBRATION_QA.md`
- `data/config/level_progression_v1.json`
- `data/config/difficulty_score_model_v1.json`

The 2026-09-12 owner decision supersedes older class=dimension and class=color-count wording still present in historical trackers/code until migration lands.

## 2. What SCRUBBOTS is

SCRUBBOTS is an original portrait-first mobile puzzle game. Visible canonical-palette pixel artwork starts ACTIVE. The player uses five color/robot slots to dispatch Scrubbots. A Scrubbot receives one exact reachable matching target, travels visibly to it, clears that logical cell to transparent CLEARED state, then disappears.

No hidden clean image exists. The visible artwork itself is progressively removed.

## 3. Core hard rules

1. Preserve owner-locked gameplay rules unless a newer explicit owner decision changes them.
2. Never invent major unresolved mechanics merely to complete a task.
3. Keep gameplay logic separate from presentation.
4. Keep level data declarative and separate from scene/script code.
5. Use Godot **4.7.2** / GDScript by default.
6. Prefer built-in Godot systems; no paid dependency/SDK/service without owner approval.
7. Target stable mobile performance; measure instead of assuming.
8. Never represent the logical board as one heavyweight Node/Control per cell.
9. Preserve `TargetSelector` WHAT vs `RoutingSystem` HOW separation.
10. Validate modified systems in the actual environment; file existence is not evidence.
11. Inspect `git diff` before commit.
12. Never use destructive Git cleanup/reset/force push without explicit owner permission.
13. Preserve unrecognized/pre-existing owner work.
14. Documentation drift is a defect.
15. No secrets in repository/coordination artifacts.
16. Do not edit root `TASKS.md`; tracker state is written by ChatGPT after audit/owner decisions.

## 4. Git synchronization and owner-work preservation

At the start of every implementation prompt:

- confirm repository `Sekiph82/Scrubbots`, branch `main`;
- inspect branch/upstream/remotes and `git status --short`;
- treat every pre-existing tracked modification/deletion and untracked owner file as owner/local work until proven otherwise;
- fetch and safely synchronize with `origin/main`;
- never use `reset --hard`, `clean -fd`, destructive restore or force push merely to make the tree clean;
- if local owner work prevents safe sync, stop as `BLOCKED` rather than erase it.

After implementation, commit/push all authorized work to GitHub.

## 5. GitHub-only coordination

Local/Desktop phase logs are retired.

For every material prompt version:

```text
CHATGPT_PROMPT_VNN.md
CHATGPT_AUDIT_CRITERIA_VNN.md
CLAUDE_LOG_VNN.md
CHATGPT_AUDIT_VNN.md
```

Claude/Codex:

- implement only the active prompt;
- run required tests;
- write the matching `CLAUDE_LOG_VNN.md`;
- push safely;
- **do not edit root `TASKS.md`;**
- hand off `AWAITING_AUDIT` in the requested response;
- return the direct GitHub blob URL requested by the prompt;
- never create an audit verdict/file.

ChatGPT independently inspects the real GitHub state, owns audit closure, and updates root `TASKS.md` to the audited truth/current actor before issuing the next prompt.

## 6. Board and LevelData `[LOCKED]`

- Board engine is variable-size and rectangular-capable.
- Width/height come from LevelData.
- Cell count is always `width * height`.
- Current production-capable envelope is 20..59 per dimension, max 59x59 = 3481 logical cells.
- `TEST` fixtures may exist outside production envelope but never enter production catalog/campaign.
- Logical pixels are data units, not physical device pixels.

### Difficulty V1 board-size semantics `[OWNER-LOCKED 2026-09-12]`

The old mapping `EASY 20..29 / MEDIUM 30..39 / HARD 40..49 / VERY_HARD 50..59` is superseded as player-facing difficulty truth.

Board size is now a Workload/Session-Load input, not the class definition.

Guidance:

- 20..23 compact/intro/engineering/short-session;
- 24..40 preferred standard content;
- 41..48 large, load-gated;
- 49..59 exceptional, load + phone-readability gated.

A 24x24 board may be VERY_HARD. A 38x38 board may be EASY.

Legacy runtime validators may retain old bands temporarily during audited migration. Do not extend or scale production content using the obsolete semantic model.

## 7. Canonical pixel-art palette `[LOCKED]`

Machine source (active authority, palette V3 — Alpix-aligned, owner-locked 2026-09-25):
`data/palettes/scrubbots_palette_v3.json`

Historical only: `data/palettes/scrubbots_palette_v2.json`.

Palette version != Level Data schema version. Palette V3 does not change Level Data:
void-free level files stay `"version": 1` (`LevelData.FORMAT_VERSION`). Level Data version 2
exists only for levels with VOID cells (ADR-030, owner 2026-10-08).

- Production ACTIVE logical cells use only C01..C16.
- ACTIVE alpha is 255.
- A fully transparent source pixel is a VOID cell (`cells` value `-1`, version 2 only): not
  artwork, never a candidate, starts CLEARED/open, renders like CLEARED (D1), never filled
  with a colour. Production needs >= 200 non-VOID cells and >= 25% of W*H (D2).
- Local LevelData palette contains only used canonical colors, ascending global C-ID.
- CLEARED alpha 0 is runtime state, not palette color.
- BG01 Midnight Slate `#202533` is gameplay background, not a logical cell color.

### Difficulty V1 color semantics `[OWNER-LOCKED 2026-09-12]`

Production artwork uses the V3 `usedColorEnvelopeV1` of 3..12 distinct canonical colors.
`difficultyClassDerivedFromColorCount` is false; color count never independently
assigns EASY/MEDIUM/HARD/VERY_HARD.

The old `EASY 3–5 / MEDIUM 6–7 / HARD 8–9 / VERY_HARD 10–12` mapping is superseded as class legality. Count and entropy contribute to Color Complexity, one part of Challenge Score.

## 8. ACTIVE / CLEARED `[LOCKED]`

ACTIVE:

- exact source canonical color;
- opaque;
- candidate for its color;
- blocks access when not the assigned final target.

CLEARED:

- alpha 0;
- removed as color candidate;
- opens access/free space;
- shows BG01 through the transparent hole.

No DIRTY/CLEAN/grime transform exists.

## 9. Reachability / targeting / routing `[LOCKED]`

A color match is only a raw candidate. Dispatch requires a reachable/targetable exact final cell.

Canonical access semantics:

- non-target ACTIVE cells block;
- CLEARED/outside free space is open;
- assigned ACTIVE target is enterable only for final arrival.

A fully enclosed matching cell must not dispatch until clears make it legally reachable.

Responsibilities:

```text
ColorCandidateIndex -> raw ACTIVE matching candidates
Access/reachability -> targetability/traversal truth
TargetSelector      -> WHAT target
RoutingSystem       -> HOW to travel to that already-assigned target
ScrubbotAgent       -> movement only
CompleteClearingLoop-> authenticated arrival + ACTIVE→CLEARED transaction
```

Do not collapse boundaries.

## 10. Five-slot / Scrubbot behavior `[LOCKED]`

- five visible slots;
- Scrubbots leave one at a time;
- no reachable target means no spawn;
- one assignment = one exact target/reservation;
- bot travels, clears, disappears;
- no color carrying;
- no return-to-slot behavior.

Do not invent queue/cooldown/stack mechanics to manipulate difficulty.

## 11. Difficulty / Progression / Retention V1 `[OWNER-LOCKED 2026-09-12]`

### 11.1 Exact repeating cadence

Every ten levels:

```text
1 EASY
2 EASY
3 MEDIUM
4 EASY
5 HARD
6 EASY
7 EASY
8 MEDIUM
9 EASY
10 VERY_HARD
```

This repeats indefinitely.

### 11.2 Same class becomes harder over campaign age

For `n >= 1`:

```text
slot = ((n-1) mod 10)+1
k    = floor((n-1)/10)
P(k) = 1-exp(-k/20)
```

Lane targets:

```text
EASY       20 + 14P
MEDIUM     40 + 13P
HARD       58 + 13P
VERY_HARD  76 + 12P
```

Micro modifiers:

```text
1:+0, 2:+2, 3:+0, 4:-1, 5:+0,
6:-2, 7:+1, 8:+2, 9:-1, 10:+0
```

Level 311 EASY must therefore be harder/richer than level 11 EASY without ceasing to be a recovery/flow lane relative to local peaks.

### 11.3 Challenge Score

V1 normalized components:

```text
W Workload                    10%
C Color Complexity            15%
A Accessibility Scarcity      20%
U Unlock Depth                20%
B Bottleneck Pressure         15%
R Route Complexity            10%
S Slot/Color Pressure         10%
```

`D = 100*(0.10W+0.15C+0.20A+0.20U+0.15B+0.10R+0.10S)`

All coefficients and normalizations are versioned. Never silently edit them under the same model version.

### 11.4 Separate Session Load and Frustration Risk

Challenge, duration/load and frustration are different axes.

Large cell count mainly raises Session Load; it does not automatically make a puzzle cognitively hard.

A level may be short/hard or long/easy.

### 11.5 Retention principles

Campaign generation/sequencing must explicitly consider:

- recovery after tension peaks;
- novelty;
- recent-level similarity;
- challenge-vector diversity;
- Session Load caps;
- Frustration Risk caps;
- avoiding repeated long/high-friction levels.

Difficulty escalation alone is not a retention system.

No hidden individualized dynamic difficulty is authorized by V1.

## 12. Level Factory `[LOCKED boundary]`

`level_factory/` is an independently openable sidecar project. Main game never preloads/imports Factory scripts.

Factory V1 architecture:

```text
GenerationRequest
→ candidate generator
→ legality validator
→ canonical solver/simulator
→ W/C/A/U/B/R/S + load/risk/novelty analysis
→ accept/mutate/reject
→ accepted candidate pool
→ CampaignBuilder
→ declarative production data
```

Generator must be evaluator-guided, deterministic where possible, bounded and fully provenance-traceable.

Owner-original artwork is immutable. Generated candidates may be safely mutated only with lineage and full revalidation.

CampaignBuilder sequences accepted levels. It does not modify their logical cell data.

## 13. Level Factory / Content Pipeline sidecar boundaries

- `level_factory/`: offline generation, solving, difficulty analysis, review, QA.
- `content_pipeline/`: declarative pack/manifest publishing, staging/production, rollback/disable/scheduling.
- shipping runtime contains neither Factory nor publisher implementation.
- remote content is declarative only; no scripts/native code/plugins.
- remote installed content lives under `user://`, never mutates `res://`.

## 14. M21 compatibility

M21 uses the owner-approved 20x20 Hazard Bot as an engineering vertical slice.

The active M21 cycle is not expanded into a full Difficulty V1 migration. Existing legacy dimension/color validator behavior may be used only as the compatibility gate required by that active prompt.

Do not infer from M21 that future EASY levels must be 20x20/five-color.

## 15. Win/Lose, economy and monetization gates

Exact win/lose rules beyond the established clearing concept remain owner-gated until decided.

Difficulty V1 does not authorize:

- a timer;
- move limits;
- paid retries;
- energy systems;
- ads;
- IAP/subscriptions;
- failure manipulation.

Do not invent them.

Locked win-streak reward mapping remains:

```text
1 win  -> 1
2 wins -> 5
3 wins -> 10
4 wins -> 25
5+     -> 100
```

## 16. UI / visual system `[OWNER-LOCKED]`

For UI/visual work also read:

- `docs/MASTER_UI_SYSTEM.md`
- `docs/07_UI_ASSET_PIPELINE_DECISIONS.md`
- `docs/HOME_UI_ASSET_PLAN.md` when working on Home
- `ASSET_GENERATION_MANIFEST.json`
- `assets/ui/HOME_ASSET_MANIFEST.json` when working on Home

Key rules:

- responsive native Godot Controls/containers, not flattened interactive screenshots;
- board remains dominant gameplay region;
- preserve single Image/ImageTexture BoardRenderer;
- normal five-slot baseline remains usable across required viewport matrix, and Economy V1 +1 Slot must later prove temporary sixth-slot usability;
- dynamic text/state stays native UI;
- ChatGPT image generation is primary for new illustrative UI/character art;
- Magnific MCP remains an approved fallback/alternate;
- image generation is development-time only and never a shipping runtime dependency;
- raw generated candidates live under `assets/ui/generated/`;
- only owner-approved production art is promoted to `assets/ui/final/`;
- never silently regenerate/overwrite owner-approved art;
- approved asset provenance is preserved.

Difficulty class must not be used as a proxy for expected board physical size in responsive UI.

## 17. Testing discipline

Every prompt must run the exact validation required by its audit criteria.

General expectations:

- baseline/regression tests;
- invalid/adversarial inputs;
- headless parse/runtime checks;
- performance tests when cost scales with board/candidate/search size;
- `git diff --check` where applicable;
- inspect final changed-file set;
- log failures and fixes truthfully;
- no implementer-written test is sufficient evidence merely because it passes; critical milestones require direct assertions against the claimed property.

## 18. Difficulty V1 testing additions

Future relevant tests include:

- exact cadence for arbitrary level numbers;
- level 311 EASY target > level 11 EASY target;
- boss→recovery score drops;
- compact hard and larger easy fixtures;
- challenge score always finite and 0..100;
- separate Session Load and Challenge behavior;
- solver UNSOLVABLE vs INCONCLUSIVE;
- score/model provenance;
- no owner-source mutation;
- challenge-vector diversity/campaign similarity checks;
- levels 1/10/11, 111, 300/310/311, 1000/1001/1010 progression regression.

## 19. Source-of-truth precedence

When documents conflict:

1. newest explicit owner instruction;
2. newest owner-locked coordination decision;
3. current root `TASKS.md` lifecycle state for what work is active;
4. versioned machine configs for their exact model values;
5. current subsystem docs;
6. historical docs/trackers/audits as evidence only.

For Difficulty V1 specifically, the 2026-09-12 owner decision supersedes old class=dimension/color wording until every legacy file/runtime validator has been migrated through audit.

## 20. Working style

Inspect before modifying. Keep work scoped, reversible, testable and evidence-driven. Reuse audited systems rather than rebuilding them for style. Stop only when proceeding would destroy owner work, expose secrets, require an unauthorized paid/external dependency, or contradict an unresolved owner decision. Do not edit root `TASKS.md`; leave tracker updates to ChatGPT after independent audit/owner-gate review.


## Economy & Rewards V1 owner lock

Before implementing economy/reward/Heart/booster/2x/Collection-exchange/robot-unlock work, read:
- `coordination/OWNER_ECONOMY_REWARDS_V01.md`
- `data/config/economy_rewards_v1.json`

Do not invent Star/Event currencies or a fifth booster. Do not expose shipping free manual 2x. Do not mutate economy from UI Controls. M39 owns the service implementation and cross-engine booster extensions.
