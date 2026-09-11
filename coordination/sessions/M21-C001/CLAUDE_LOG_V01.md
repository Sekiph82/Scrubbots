# M21-C001 V01 — Claude Implementation Log

Cycle: `M21-C001` V01 — first owner-approved real-art vertical slice.
Actor: Claude (implementer/test runner). Auditor: ChatGPT (independent).
Repository: `Sekiph82/Scrubbots`, branch `main`. Handoff state: `AWAITING_AUDIT`.
Engine: Godot `4.7.1.stable.official.a13da4feb`.

This log records pre-commit evidence. Per the owner-locked non-self-referential
final-SHA rule, it does not chase the SHA of the commit that contains itself.

---

## 0. Safe sync + preserved owner/local work

- Starting local `HEAD` and `origin/main`: `cc68a68b83c6ca67f2e6cf3fb926c3093e55b9c0`
  after a fast-forward from `412ed50…`. Local was 0 ahead / 16 behind; the merge
  was a clean `--ff-only` (no owner/local file among the 16 incoming commits).
- Verified before sync that the incoming commits did NOT touch the locally
  modified files, then fast-forwarded.
- Preserved owner/local work (NOT reset, restored, stashed, or overwritten):
  - tracked modifications: `project.godot`, `scenes/debug/routing_prototype_lab.tscn`,
    `scenes/debug/scrubbot_agent_debug.tscn` (left unstaged throughout);
  - many untracked owner files: `assets/art/references/_owner_inbox/**` (`.import`
    sidecars, `Game Screens/*`), `assets/brand/akilta-wordmark.svg.import`,
    `docs/logs/`, numerous `scripts/**/*.uid`, `tests/support/*.uid`, `tools/*.uid`,
    and a stray scratchpad temp file. None were staged, deleted, or modified.
- No `.hiveai` live tracker was recreated. GitHub-only logging; no Desktop phase log.

## 1. Authorized tracker reconciliation (tracker-only, pushed BEFORE implementation)

- Materialized ChatGPT's final closure from
  `coordination/sessions/M20-C001/CHATGPT_AUDIT_V11.md`
  (`AUDITED_PASS / STRICT_V2_FINAL_CLOSURE`): marked `SB-M20-001..014` `[x]`;
  Progress `304 / 719 = 42.28% (main+ui)`, `304 / 943 = 32.24% overall`;
  `lastCompletedTaskId = M20-C001-V11`; transitioned Project Status to
  `M21 / M21-C001 V01 / IN_PROGRESS / CLAUDE`.
- No `SB-M21` or `SB-M08` task closed.
- **Tracker-only start commit (only `TASKS.md` staged): `9fd6b47d1415ec6de7c23bed09b875f0f2d73a08`.**
  Verified present on remote `origin/main` before any implementation/test edit.

## 2. Relevant audit learnings applied

- **AL-001 / ADR-009**: every new script uses explicit `preload()` (no reliance on
  `class_name`).
- **AL-028**: raw color candidate ≠ reachable target — the whole §6 proof rests on
  it; enclosed non-C08 colors have raw candidates yet `NO_REACHABLE_TARGET`.
- **AL-003**: headless CPU/wall timing is never presented as mobile FPS/GPU.
- **AL-004/005/006/009/018**: source immutability, fail-closed path aliasing, no
  destructive overwrite; the bridge fails closed on source/destination aliasing.
- **AL-026/032/033/034/035**: renderer stays single-`Image`/`ImageTexture`
  ACTIVE=opaque source color / CLEARED=alpha0; renderer readback compared with the
  quantization-aware helper, not `is_equal_approx`.
- **AL-041/054/062/063**: reused audited importer/validator seams instead of a
  parallel pipeline; deterministic rebuild proven; no production M19/M20 mutation.

## 3. Owner-approved source integrity

Recomputed from the committed bytes (start and end of work — unchanged):

| Fact | Value |
| --- | --- |
| Path | `assets/art/levels/source/easy/scrubbots_m21_level_001_hazard_bot_20x20.png` |
| Git blob SHA | `b565743ba52699899007882b750b7c8e7cdd00f9` |
| SHA-256 | `ede1e02a9096c4c7ba040b91ed7db2d2c2af3b2e20d5c8774068c8d08ad59899` |
| Size | 297 bytes |
| Dimensions | 20 × 20 (400 logical pixels) |
| Alpha | all 255; 0 semi-transparent; 0 transparent |
| Off-palette | 0 |
| Colors / counts | C01=30, C03=5, C08=298, C11=11, C16=56 (5 distinct, EASY 3–5) |
| Perimeter | 76 cells, all C08; 0 non-C08 perimeter cells |

Source PNG never regenerated, resized, recolored, smoothed, optimized/re-encoded,
or overwritten. Source audit: `coordination/sessions/M21-C001/M21_SOURCE_AUDIT.md`.

## 3a. Concurrent Difficulty V1 migration — safe sync + scope reconciliation

While M21-C001 V01 was in progress, a project-wide **Difficulty/Progression/
Retention V1** migration landed on `origin/main` (commits `9d75a04…0fefbe0`),
including `coordination/sessions/M21-C001/OWNER_DIFFICULTY_V1_SCOPE_NOTE.md` and a
palette-authority change. My first push was rejected (remote advanced); I fetched,
confirmed no overlap with owner/local work, and **`git rebase --autostash
origin/main`** (autostash reapplied the owner's unstaged `project.godot` +
2 debug `.tscn` — never dropped). New base tip: `0fefbe0`.

Reconciliation per the owner scope note (it explicitly governs M21 during this
migration):
- M21-C001 V01 scope is UNCHANGED; the approved 20×20 Hazard Bot source stays
  valid; legacy `DifficultyRules`/`ProductionLevelValidator` are permitted as the
  M21 compatibility gate; M21 must still satisfy `CHATGPT_PROMPT_V01.md` /
  `CHATGPT_AUDIT_CRITERIA_V01.md`.
- The palette authority `data/palettes/scrubbots_palette_v2.json` removed the
  per-difficulty `difficultyColorCountBands` and added a global
  `usedColorEnvelopeV1` (3–12), with `difficultyClassDerivedFromColorCount:false`.
  Colors/RGB and BG01 are unchanged, so the approved asset's colors, the final
  palette hex, and the reconstruction bytes are all unchanged.
- The production-art bridge was adapted (no Difficulty V1 engine work): it now
  enforces the V1 used-color envelope (3–12) read from the authority AND a
  documented **legacy M21 compatibility color-count band** (EASY 3–5) applied only
  as the M21 gate. The bridge does NOT assert "5 colors ⇒ EASY" or "20×20 ⇒ EASY"
  as design law; the design-vs-compat distinction is recorded here and in
  `M21_SOURCE_AUDIT.md`.
- Explicitly NOT done (per scope note): no redesign of `difficulty_rules.gd` /
  `production_level_validator.gd`, no Difficulty Score engine, no CampaignBuilder,
  no Level Factory generator, no source dimension/color change, no drive-by
  rewrite of the difficulty/LF roadmap.

## 4. Raw first-seen vs. normalized production palette order

- Raw M09 importer first-seen row-major order: `C08, C16, C01, C03, C11`.
- Production canonical local order (ascending global C-ID): `C01, C03, C08, C11, C16`.
- The raw first-seen order is explicitly NOT claimed to satisfy the current
  production palette-order rule; the bridge normalizes it.

## 5. Production-art bridge architecture (M09 gap closed, M09 unchanged)

New: `scripts/tools/production_art_level_builder.gd`
(+ reproducible generator `tools/build_m21_level.gd`).

- Reuses the audited generic `LevelImporter` (dry-run) for exact-pixel extraction;
  the generic first-seen M09 contract is left byte-for-byte unchanged
  (`scripts/tools/level_importer.gd` not modified).
- Reads `data/palettes/scrubbots_palette_v2.json` as the machine-readable palette
  authority (no parallel hardcoded table).
- Rejects: off-palette colors (no nearest-color), any alpha ≠ 255 (canonical
  `#RRGGBBFF` treated as opaque `#RRGGBB`), and out-of-band distinct-color counts
  (EASY 3–5).
- Counts distinct colors from CELLS, not palette-array length.
- Normalizes the local palette to ascending global C-ID order and remaps cell
  indices deterministically so visible pixels are byte-identical.
- Validates the final palette contains only used canonical colors, ascending.
- Fail-closed path-aliasing guard on source/destination; deterministic; never
  mutates the source PNG.
- Direct negative tests: off-palette, semi-transparent, wrong EASY count, and
  noncanonical local order (deterministically normalized, pixels preserved).

## 6. Generated production artifacts

Created reproducibly via `res://tools/build_m21_level.gd` (no hand-edited JSON):

| Artifact | Path |
| --- | --- |
| Level Data | `data/levels/m21_level_001_hazard_bot.json` |
| Preview (from final data) | `assets/art/levels/previews/m21_level_001_hazard_bot.png` |
| Metadata/provenance | `data/levels/metadata/m21_level_001_hazard_bot.metadata.json` |

Final Level Data: id `m21_level_001_hazard_bot`, name `Hazard Bot`, difficulty
`EASY`, 20×20, 400 cells, palette
`["#E94B4BFF","#F2C94CFF","#3451A3FF","#956447FF","#000000FF"]`
(C01,C03,C08,C11,C16), cell-index counts 30/5/298/11/56.
Metadata records builder version, source path + git blob SHA1 + SHA-256, dims,
difficulty, first-seen order, normalized order, used-color count, cell counts,
output/preview paths.

Proven (root suite + generator):
- `LevelValidator` PASS; `ProductionLevelValidator` PASS; production-art policy PASS.
- `LevelLoader` loads the committed result; id/name/difficulty/dims/palette/cells preserved.
- Reconstruction from final Level Data is 20×20 RGBA8 and its raw bytes equal the
  approved source raw bytes for all 400 pixels (no source shortcut).
- Committed preview raw bytes equal the final-data reconstruction (and the source).
- Determinism: rerunning the generator reports `UNCHANGED` for all three artifacts;
  normalizing twice yields byte-identical final data.

## 7. Real production collaborators used in the M21 vertical slice

`LevelLoader`/`LevelData`, `BoardState`, `BoardRenderer`, `SlotSystem`,
`ColorCandidateIndex`, `ReservationState`, `TargetSelector`,
`ProductionAccessQuery`, `ProductionTargetAccess` (the existing production
targetability/reachability seam TargetSelector consumes), `ProductionRoutingSystem`,
`ScrubbotDispatcher`, `ScrubbotAgent`, `CompleteClearingLoop`. No `M20CandidateSeam`,
`M20ReservationSeam`, dispatcher double, or forced-target seam in the authoritative
run. Five slots configured once against local palette identities 0..4; slot i →
palette id i asserted directly.

M20 production kept locked (re-verified after all work):
- `CompleteClearingLoop` blob `06391839523cbc27e88a4b3ef12b730012cd45fa` (unchanged).
- `ScrubbotDispatcher` blob `eee10149e4f116af6706beec832042352bf3a6dd` (unchanged).
No M19/M20 production defect was exposed; no upstream change made.

## 8. Real-art AL-028 reachability proof (root suite, synchronous)

`_run_m21_real_art_reachability_tests` (in `tests/run_tests.gd`):
- 400 cells start ACTIVE; candidate counts exactly 30/5/298/11/56 for C01/C03/C08/C11/C16.
- BoardRenderer initially matches the approved source at every one of the 400 coordinates.
- All 76 perimeter cells proven C08; no other color on the perimeter.
- For each non-C08 color (C01,C03,C11,C16): raw candidates exist, yet activation
  returns exactly `NO_REACHABLE_TARGET`, spawning no agent and creating no
  reservation (not a fake no-candidate pass).
- C08 slot dispatches a real `ScrubbotAgent` to a real ACTIVE C08 target via the
  real selector+access+routing path: reservation exists before arrival, the agent
  is MOVING before arrival; driving to authenticated arrival yields exactly one
  ACTIVE→CLEARED clear; renderer cell → alpha 0; candidate index drops the cell;
  reservation resolved; dispatcher finalized; agent scheduled for destruction
  (no return trip).
- Continuing real C08 clears, an initially-unreachable non-C08 color becomes
  genuinely reachable and then dispatches+clears through the production path (no
  forced target).

## 9. Full 400-cell real-art run (dedicated smoke)

`tests/m21_real_art_smoke.gd` (frame-aware; run separately). Deterministic
test/debug driver only — no autoplay/refill/queue/cooldown/scoring/progression
added to production. Finite guard (6000) with deadlock detection; exactly one
counted clear per successful arrival.

Final exact state (asserted): loop `cleared_count = 400`; BoardState CLEARED = 400;
ACTIVE = 0; all five candidate buckets empty; ReservationState count = 0;
dispatcher active = 0; after `await process_frame` ×2 the agent-parent (dispatcher)
child count = 0 and 0 orphan `ScrubbotAgent`; all 400 renderer logical pixels
alpha 0; BG01 never present in the LevelData palette. All five source colors
cleared at least once.

Result: `PASS — full 400-cell real-art run cleared` (guard_iters=400, colors_cleared=5).

## 10. Debug scene

`scenes/debug/m21_real_art_vertical_slice.tscn` +
`scripts/debug/m21_real_art_vertical_slice.gd`: loads the committed level, displays
it through `BoardRenderer` over owner-locked BG01 `#202533`, wires the same real
production collaborators, exposes a manual one-step debug clear (no autoplay), and
shows the existing M18 debug agent marker (not final Scrubbot art). No production
slot UI / touch / win-lose / rewards / economy / VFX. Headless-boots and parses
cleanly (root-suite smoke + standalone `--quit-after 5`, 0 SCRIPT/Parse errors).

## 11. Reference + performance evidence

- Headless evidence composite: `coordination/sessions/M21-C001/M21_REFERENCE_COMPOSITE.png`
  (initial art → mid-clear → fully cleared, each composited over BG01; ACTIVE
  artwork and CLEARED transparency are visually distinguishable against BG01). It
  is a headless evidence composite, NOT a real-device screenshot or mobile
  rendering/FPS proof (AL-003).
- Full-run clear count: 400. Elapsed CPU/headless wall time for the full run:
  ~136–176 s across runs (varies with concurrent machine load) — CPU/headless
  timing only, never an FPS/GPU/mobile-frame claim.
- Node/memory: not separately measured beyond the exact final node/child-count
  and candidate/reservation/dispatcher counts asserted above (reported as
  measured, not inferred).
- Visual gaps: `coordination/sessions/M21-C001/M21_VISUAL_GAPS.md`. No manual owner
  visual approval is claimed in this cycle.

## 12. Commands run and actual results

| # | Command | Result |
| --- | --- | --- |
| 1 | `godot --version` | `4.7.1.stable.official.a13da4feb` |
| 2 | source hash/blob recheck | blob `b565743…`, sha256 `ede1e02…`, 297 bytes — MATCH |
| 3 | `godot --headless --path . -s res://tests/run_tests.gd` | **4407 checks, 0 failures, ALL PASS** (baseline 4294 + 113 M21) |
| 4 | `res://tests/m20_queue_free_smoke.gd` | PASS |
| 5 | `res://tests/m20_v04_lifecycle_smoke.gd` | PASS |
| 6 | `res://tests/m20_v05_lifecycle_smoke.gd` | PASS |
| 7 | `res://tests/m20_v07_lifecycle_smoke.gd` | PASS |
| 8 | `res://tests/m20_v08_lifecycle_smoke.gd` | PASS |
| 9 | `res://tests/m20_v09_lifecycle_smoke.gd` | PASS |
| 10 | `res://tests/m20_v10_lifecycle_smoke.gd` | PASS |
| 11 | `res://tests/m21_real_art_smoke.gd` | PASS (400 clears, 5 colors) |
| 12 | headless boot `res://scenes/debug/m21_real_art_vertical_slice.tscn --quit-after 5` | boots, 0 SCRIPT/Parse errors |
| 13 | `res://tools/build_m21_level.gd` rerun | LEVEL/PREVIEW/METADATA all UNCHANGED (deterministic) |
| 14 | source blob + sha256 recheck (end) | unchanged |
| 15 | M20 loop/dispatcher blob recheck (end) | loop `06391839…`, dispatcher `eee10149…` — unchanged |
| 16 | `git diff --check` | clean (only a benign LF→CRLF advisory on owner's pre-existing `project.godot`; no M21 file) |
| 17 | scan outputs for `SCRIPT ERROR` / `Parse Error` | 0 in root suite, M20 smokes, and debug boot |

Note: the root suite reports pre-existing at-exit warnings (1 CanvasItem RID / 60
ObjectDB leaked / 9 resources still in use). Confirmed identical with M21 disabled
(4294 baseline), so M21 introduces zero new leaks. No prior M19/M20 V01–V11
regression was disabled; all prior groups remain enabled.

## 13. Exact changed/added files (authorized M21 work)

Added:
- `scripts/tools/production_art_level_builder.gd`
- `tools/build_m21_level.gd`
- `data/levels/m21_level_001_hazard_bot.json`
- `data/levels/metadata/m21_level_001_hazard_bot.metadata.json`
- `assets/art/levels/previews/m21_level_001_hazard_bot.png`
- `tests/m21_real_art_smoke.gd`
- `scenes/debug/m21_real_art_vertical_slice.tscn`
- `scripts/debug/m21_real_art_vertical_slice.gd`
- `coordination/sessions/M21-C001/M21_SOURCE_AUDIT.md`
- `coordination/sessions/M21-C001/M21_VISUAL_GAPS.md`
- `coordination/sessions/M21-C001/M21_REFERENCE_COMPOSITE.png`
- `coordination/sessions/M21-C001/CLAUDE_LOG_V01.md` (this file)

Modified:
- `tests/run_tests.gd` (M21 test registration + `_run_m21_*` functions)
- `TASKS.md` (tracker-only start `9fd6b47`, then the AWAITING_AUDIT handoff)

`.uid` sidecars for new scripts are NOT committed (repo convention: 0 tracked
`.uid`). No production M19/M20 script changed. Owner pre-existing local work was
never staged.

## 14. Criteria → evidence map (major groups)

| Criteria group | Evidence |
| --- | --- |
| A governance / handoff (1–25) | §0/§1; tracker-start `9fd6b47`; final handoff §15 |
| B source integrity (26–45) | §3; `_run_m21_source_audit_tests`; recheck cmd 14 |
| C M08-style source audit (46–60) | `M21_SOURCE_AUDIT.md` (§3) |
| D production palette bridge (61–85) | §4/§5; `_run_m21_production_art_bridge_tests` (incl. 4 negatives) |
| E final artifact (86–108) | §6; `_run_m21_artifact_roundtrip_tests`; generator determinism cmd 13 |
| F real gameplay bundle (109–129) | §7; reachability + smoke; blob locks cmd 15 |
| G initial reachability/AL-028 (130–151) | §8; `_run_m21_real_art_reachability_tests` |
| H full-level run (152–168) | §9; `tests/m21_real_art_smoke.gd` |
| I reference/perf truth (169–179) | §11; `M21_REFERENCE_COMPOSITE.png`; `M21_VISUAL_GAPS.md` |
| J regression/log/handoff (180–201) | §12 (all commands); this log; §15 |

Evidence categories: root-suite = cmd 3; smoke/frame = cmds 4–11; static/source =
cmds 2/14/15; generated-artifact = cmd 13 + §6; manual/unavailable = owner visual
approval (NOT claimed, deferred to owner after handoff).

## 15. Final handoff

- No `SB-M21` or `SB-M08` checkbox closed by Claude. No audit file authored. No
  self-audit verdict assigned.
- Root `TASKS.md` Project Status set to `M21 / M21-C001 V01 / AWAITING_AUDIT /
  CHATGPT`; Progress stays `304/719` and `304/943`; `lastCompletedTaskId` stays
  `M20-C001-V11`.
- All authorized work pushed to `origin/main` without force.
- Handoff state: **AWAITING_AUDIT**.
