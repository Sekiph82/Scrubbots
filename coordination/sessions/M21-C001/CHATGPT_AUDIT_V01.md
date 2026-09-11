# M21-C001 — ChatGPT Independent Audit V01

Date: 2026-09-12
Auditor: ChatGPT
Cycle: `M21-C001`
Prompt: `CHATGPT_PROMPT_V01.md`
Criteria: `CHATGPT_AUDIT_CRITERIA_V01.md`
Claude evidence: `CLAUDE_LOG_V01.md`

## Decision

**CHANGES_REQUIRED / FINDING_SET_FROZEN / V02_CORRECTION_AND_ADVERSARIAL_VALIDATION_REQUIRED**

M21 V01 establishes strong evidence for the owner-approved Hazard Bot vertical slice and I found no new M19/M20 gameplay-state defect in the real-art path. Final M21 closure is nevertheless blocked for two independent reasons:

1. the new `ProductionArtLevelBuilder` has fail-closed/public-contract and deterministic multi-artifact preflight defects described below; and
2. M21 is a critical gameplay vertical slice, so Strict Audit Standard v2 / AL-034 / AL-035 requires a second auditor-authored adversarial validation pass because ChatGPT cannot independently execute Godot in this environment.

No `SB-M21-*` or `SB-UI-014..016` checkbox is closed by this audit.

---

## 1. Exact audit basis

The implementation commit audited is exactly:

`328dd838dc0dfde3ece79b090f49f8f6b4e436b8`

Its parent is:

`5d8081758bf787a965bb32fb97a49578518dd3a5`

The audit therefore isolates the M21 V01 implementation from later ChatGPT-authored Difficulty/Art-Intelligence/archive work on `main`.

The tracker-only M20-close / M21-start commit is independently verified as:

`9fd6b47d1415ec6de7c23bed09b875f0f2d73a08`

and its only changed path is `TASKS.md`.

ChatGPT could inspect GitHub source/diffs/artifacts and test code, but could not independently execute Godot. Claude's reported `4407/4407`, M20 lifecycle-smoke passes and M21 400-cell smoke are therefore E1/E2 implementation evidence, not E3 runtime reruns.

---

## 2. High-confidence accepted V01 evidence

### 2.1 Owner source truth

Verified at the audited implementation tree:

- path: `assets/art/levels/source/easy/scrubbots_m21_level_001_hazard_bot_20x20.png`;
- Git blob: `b565743ba52699899007882b750b7c8e7cdd00f9`;
- size: 297 bytes;
- owner-validation contract: 20x20 / 400 opaque cells / C01=30, C03=5, C08=298, C11=11, C16=56;
- owner scope note explicitly preserves this fixture and its `EASY` compatibility label during the separate Difficulty V1 migration.

The V01 source-audit tests independently derive color counts and the 76-cell all-C08 perimeter from image pixels rather than trusting metadata only.

### 2.2 Protected M20 production remains locked

Verified at `328dd838...`:

- `scripts/gameplay/clearing/complete_clearing_loop.gd` blob = `06391839523cbc27e88a4b3ef12b730012cd45fa`;
- `scripts/gameplay/dispatch/scrubbot_dispatcher.gd` blob = `eee10149e4f116af6706beec832042352bf3a6dd`.

No M19/M20 production file is changed by the V01 implementation commit.

### 2.3 Real LevelData / renderer / production-collaborator integration

Source inspection confirms the M21 tests use the real committed LevelData and real production classes: BoardState, BoardRenderer, SlotSystem, ColorCandidateIndex, ReservationState, TargetSelector, ProductionTargetAccess, ProductionAccessQuery, ProductionRoutingSystem, ScrubbotDispatcher, ScrubbotAgent and CompleteClearingLoop.

The V01 reachability test directly checks:

- 400 ACTIVE cells initially;
- exact five candidate counts;
- renderer/source equality at all 400 logical coordinates;
- every perimeter cell C08;
- raw non-C08 candidates exist while real activation returns exactly `NO_REACHABLE_TARGET`;
- real C08 dispatch/reservation/movement/arrival/ACTIVE->CLEARED;
- candidate/reservation/dispatcher updates;
- a previously blocked non-C08 color later dispatches through the real path.

The dedicated frame-aware smoke is designed to prove the full 400-cell completion and final cleanup state. Its runtime PASS remains Claude E1/E2 evidence until V02 validation.

### 2.4 Palette bridge concept is correct for the exact fixture

The bridge correctly preserves historical M09 first-seen semantics while normalizing the production local palette from raw `C08,C16,C01,C03,C11` into `C01,C03,C08,C11,C16`, remapping cells without changing visible pixels. Off-palette, alpha, wrong-count and noncanonical-order negatives exist.

The concurrent Difficulty V1 owner scope note is respected: the old per-class color/dimension behavior is explicitly treated as M21 compatibility truth only and is not promoted back into future design law.

---

## 3. Mandatory two-pass full-surface sweep

### Pass A — implementation/state sweep

Audited surfaces:

- source asset and owner validation artifacts;
- `scripts/tools/production_art_level_builder.gd` public normalization/build paths;
- generic M09 importer boundary immediately upstream;
- generated LevelData / preview / metadata;
- debug vertical-slice scene/script;
- real collaborator wiring used by root tests and dedicated smoke;
- protected M20 loop/dispatcher identities;
- filesystem alias/preflight/write ordering;
- canonical source immutability and derived-artifact ownership.

### Pass B — evidence/test/policy sweep

Reconciled:

- V01 prompt against V01 implementation;
- 201 criteria against source/direct test/log evidence;
- aggregate-root-suite claims against actual M21 test registrations;
- AL-003 performance-claim isolation;
- AL-010/012/013/014/017 file-safety lessons;
- AL-018 direct observability;
- AL-034/035 mandatory two-stage closure;
- AL-053 arbitrary-Variant boundaries;
- Difficulty V1 scope note against legacy M21 compatibility criteria.

The old V01 criteria mentioning EASY dimension/color bands are not treated as current global design law; the owner scope note explicitly retains them only as this M21 fixture's compatibility gate. This is not blamed on Claude.

---

## 4. Sprint task coverage ledger

| Task | Production owner / state | Current evidence | Adversarial classes / false-positive risk | Status |
| --- | --- | --- | --- | --- |
| SB-M21-001 ingest original source | owner-approved source PNG | exact path/blob + source-audit tests | source replacement / aliasing | PROVEN |
| SB-M21-002 audit dimensions | source PNG | direct 20x20 / 400-pixel assertions | metadata-only false positive avoided | PROVEN |
| SB-M21-003 legal difficulty | owner scope note + legacy compatibility validator | exact M21 EASY compatibility PASS; Difficulty V1 explicitly deferred | stale design-law wording | PROVEN |
| SB-M21-004 generate level data | ProductionArtLevelBuilder + generator | committed deterministic artifact | builder public-contract + filesystem findings F-001..003 | DEFECT |
| SB-M21-005 reconstruct/compare | LevelImporter reconstruction | all 400 RGBA bytes compared | source-shortcut false positive directly avoided | PROVEN |
| SB-M21-006 render gameplay | BoardRenderer | all 400 initial pixels + cleared alpha tests | renderer/backend runtime not E3 rerun | PROVEN |
| SB-M21-007 five slots | SlotSystem | direct 1:1 palette-id assertion | misbinding | PROVEN |
| SB-M21-008 dispatch Scrubbots | real dispatcher/selector/access/routing | real-agent root test + full smoke | implementation/test correlation requires V02 | PROVEN |
| SB-M21-009 clear artwork pixels | CompleteClearingLoop + BoardState + renderer | ACTIVE->CLEARED, alpha 0, candidate/reservation updates | duplicate/re-entry covered upstream; fresh integration validation still required | PROVEN |
| SB-M21-010 full level | real production bundle | dedicated 400-cell smoke | E1/E2 only; V02 fresh runtime required | PROVEN |
| SB-M21-011 profile performance | end-to-end headless diagnostic only | 400-clear wall-time reported separately from FPS | mixed timing cannot support subsystem/mobile claim; no such claim made | PROVEN |
| SB-M21-012 reference output | evidence composite | committed PNG + descriptive log | generation command/script not reproducibly recorded, F-004 | GAP |
| SB-UI-014 real-art vertical slice | M21 real LevelData path | exact real artwork fixture | synthetic/concept substitution avoided | PROVEN |
| SB-UI-015 data-driven ACTIVE/CLEARED renderer | BoardRenderer/BG01 | real source and alpha-clear evidence | flattened screenshot substitution avoided | PROVEN |
| SB-UI-016 record genuine visual gaps | `M21_VISUAL_GAPS.md` | explicit gaps + no Magnific preauthorization | owner visual approval not falsely claimed | PROVEN |

No dependent M22 task is allowed to start before the V02 audit closes M21.

---

## 5. Frozen finding set

This is the complete V01 pre-correction finding set after the sprint-wide sibling sweep.

### F-M21-STRICT-001 — difficulty identity can diverge inside `normalize_from_level_data`

**Severity: material fail-closed contract defect**

`normalize_from_level_data(raw, difficulty)` checks the legacy compatibility color band using the independent `difficulty` parameter, but constructs its normalized output using `raw.difficulty`.

Therefore the value being validated can differ from the value being emitted. The method also runs `ProductionLevelValidator` only when `raw.difficulty` happens to be recognized as production difficulty. A caller can therefore present a mismatched `difficulty` argument and a different/TEST/unknown `raw.difficulty`, defeating the stated meaning of the production-art normalization boundary.

Required correction:

- there must be one coherent difficulty identity at this M21 compatibility boundary;
- either derive compatibility exclusively from the LevelData difficulty or require exact equality between any explicit difficulty parameter and `raw.difficulty` before further work;
- normalized production output must reject TEST/unknown difficulty rather than skipping production validation;
- add isolated mismatch negatives that would otherwise pass all unrelated checks.

Do **not** implement Difficulty V1 scoring in this correction.

### F-M21-STRICT-002 — untyped `raw` is dereferenced before contract validation

**Severity: material fail-closed boundary defect**

The public static normalization entry point accepts an untyped `raw`, checks only `raw == null`, then immediately dereferences `raw.palette`, `raw.cells`, `raw.difficulty`, etc.

Arbitrary scalar Variants or object-shaped partial dependencies can therefore fault rather than returning a normal `NormalizeResult` error. This is the exact class covered by AL-052/AL-053.

Required correction:

- validate the exact/narrow LevelData contract before dereference;
- null, int, string, vector and malformed/partial object cases must fail closed without `SCRIPT ERROR`, `Parse Error`, write, or mutation;
- keep the valid real LevelData path unchanged.

### F-M21-STRICT-003 — new multi-artifact build path does not preflight deterministic destination failures completely

**Severity: material filesystem/content consistency defect**

The builder plans existing-file content conflicts before writing, but `_plan_text` / `_plan_image` treat a nonexistent final file as immediately writable without first validating the resolved parent and final destination object type.

A predictable later-artifact failure such as a missing/non-directory parent or a destination that is already a directory can therefore occur **after an earlier Level JSON write has succeeded**, leaving a partial artifact set. This regresses AL-012/014/017 lessons on the new write path.

Required correction:

- preflight every enabled final destination before any final artifact write;
- resolve/check parent existence and directory type;
- reject an existing directory at the final output/preview/metadata path, including `overwrite=true`;
- preserve source/destination and destination/destination alias rejection;
- direct tests must prove a deliberately failing later preview/metadata destination leaves earlier final outputs untouched;
- direct tests must cover existing-different output/preview/metadata behavior and equivalent-path aliases on this **new builder**, rather than relying only on historical M09 importer tests.

The correction need not promise impossible cross-filesystem atomicity for unforeseeable OS/hardware failure; it must close deterministic failures knowable during preflight and avoid known partial commits.

### F-M21-STRICT-004 — reference composite lacks a durable reproducible generation path/evidence command

**Severity: evidence/traceability blocker**

`M21_REFERENCE_COMPOSITE.png` is committed and described as initial -> mid -> fully-cleared evidence, but the V01 command table does not record an exact command or committed generator that reproduces it from authoritative LevelData/renderer state. Criteria 169 and 193 require reproducible output and exact command/result traceability.

Required correction:

- add a minimal committed deterministic debug/test tool or otherwise durable reproducible command path that regenerates the composite from committed M21 truth;
- prove the generated evidence is labeled headless evidence, not a device screenshot;
- assert deterministic dimensions/state panels and unchanged output on rerun;
- do not turn this into production UI work.

---

## 6. Sibling-failure sweep result

After finding F-001/F-002, I checked the same normalization boundary for null, wrong Variant class, partial object shape, cell/palette use, difficulty gating and downstream production validation. No additional independent root class was found beyond F-001/F-002.

After finding F-003, I checked all three generated destinations, source/destination aliases, destination/destination aliases, existing-content comparison, `overwrite` behavior, parent/destination object assumptions and write ordering. Existing-content conflict planning is present; the remaining frozen defect is deterministic filesystem-object/parent preflight plus missing direct tests on the new builder.

The real gameplay bundle, reachability transition, full clear and protected M20 ownership were swept separately. No new M21-owned gameplay-state defect was found in source inspection.

The finding set is now **FROZEN** under AL-054. V02 must address this complete set in one pass.

---

## 7. V02 adversarial validation requirements

Even after F-001..004 are corrected, M21 still requires the AL-035 second-stage validation because ChatGPT cannot run Godot directly.

V02 must therefore include fresh auditor-authored arrangements that at minimum prove:

1. normalization mismatch/TEST/unknown difficulty fail closed;
2. arbitrary Variant / malformed raw inputs fail closed without runtime errors;
3. new builder alias/conflict/parent/directory failures cause no source mutation and no earlier-final partial write;
4. valid M21 build remains byte/pixel deterministic and source immutable;
5. blocked non-C08 activation on a fresh real board has exact zero gameplay side effects beyond the returned failure;
6. real C08 clear opens real progression and a previously blocked non-C08 color later succeeds;
7. a fresh full 400-cell run still ends with exact clean final state and no orphan agent;
8. protected M20 blobs remain exact;
9. the reference composite regenerates reproducibly;
10. root suite and required lifecycle smokes remain green.

---

## 8. Closure state

- M21 production/gameplay implementation: **provisionally source-accepted, not final-closed**.
- Frozen builder/evidence findings: **F-M21-STRICT-001..004 OPEN**.
- M21 tasks: **remain open**.
- Next required actor: **CLAUDE**, under `CHATGPT_PROMPT_V02.md`.
- Next audit: ChatGPT V02 post-correction whole-sprint audit.
