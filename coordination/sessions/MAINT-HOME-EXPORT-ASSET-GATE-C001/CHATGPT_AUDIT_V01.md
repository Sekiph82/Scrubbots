# MAINT-HOME-EXPORT-ASSET-GATE-C001 — CHATGPT AUDIT V01

Date: 2026-10-02
Implementer commit: `02f716173a72f8d18651661bb6ed8785038754f7`
Prompt: `coordination/sessions/MAINT-HOME-EXPORT-ASSET-GATE-C001/CHATGPT_PROMPT_V01.md`
Criteria: `coordination/sessions/MAINT-HOME-EXPORT-ASSET-GATE-C001/CHATGPT_AUDIT_CRITERIA_V01.md`

Result: **AUDITED_PASS / CLOSED**

## Executive result

The exported-build blank-Home defect is fixed without weakening the source approval gate.

The implementation cleanly separates two trust contexts:

- `SOURCE_TREE_STRICT`: raw approved PNG bytes must exist and exactly match the pinned SHA-256.
- `PACKAGED_RUNTIME`: raw PNG bytes are not expected; approved pin metadata, final-path/schema/status rules, and exported resource resolution remain mandatory.

The runtime selector uses Godot's `template` feature. Evidence from a real Godot 4.7.2 Web release export in headless Chrome proves the exported process selected `PACKAGED_RUNTIME` while the raw HOME-026 PNG was absent, yet the manifest remained valid, all 24 mapped Home art nodes bound, and the four gesture sets loaded 14/15/17/17.

No approved art byte or approved SHA pin changed.

## A. Trust model / source integrity

**PASS**

- Validator defines explicit `SOURCE_TREE_STRICT` and `PACKAGED_RUNTIME` modes.
- `validate()` defaults to `SOURCE_TREE_STRICT`.
- Unknown integrity modes fail closed.
- Strict mode requires both source existence and exact SHA match.
- Packaged mode does not call raw-PNG SHA as its integrity condition.
- Packaged mode still requires APPROVED status, valid 64-character lowercase hex source pin metadata, final-root PNG path, and valid manifest structure.
- Animation-set frames use the same explicit integrity model.
- Imported `.ctex` bytes are not promoted to canonical approval hashes.

Static source inspection confirms there is no implicit "missing file => skip hash" shortcut.

## B. Runtime binding

**PASS**

`HomeArtBinder` now owns an explicit mode and injectable source root. Default selection is:

`PACKAGED_RUNTIME if OS.has_feature("template") else SOURCE_TREE_STRICT`

The real execution evidence records:

- source/editor headless: template=false, editor=true -> SOURCE_TREE_STRICT;
- Web release export: template=true, editor=false, web=true -> PACKAGED_RUNTIME.

Strict `state()` calls the integrity function every time, preserving post-construction source-hash protection. Packaged `state()` uses exported resource resolution instead of raw-source hashing. `texture()` still requires a successful Texture2D load and `animation_set()` returns an empty set on any null frame load.

Unapproved, unknown, malformed, non-final/generated and missing-resource cases remain blocked.

## C. Test sensitivity

**PASS**

The maintenance suite has 11/11 cases and directly distinguishes the two modes using an explicit nonexistent source root rather than deleting owner assets.

Covered negative cases include:

- wrong approved ART pin in strict mode;
- wrong animation-frame pin in strict mode;
- missing strict source tree;
- malformed manifest;
- wrong schema;
- unapproved ART;
- path outside `assets/ui/final/`;
- unresolved packaged ART;
- unresolved packaged animation frame;
- erased/short/uppercase/non-hex ART pins;
- animation frame with no pin;
- non-APPROVED animation set;
- generated-path ART/frame bypass attempts;
- unknown integrity mode.

The strict source implementation itself re-reads SHA on each `state()` call. The test's post-construction sensitivity mutation changes the manifest pin rather than mutating an owner asset byte, but source inspection verifies the same per-call path invokes `FileAccess.get_sha256()`; therefore this is sufficient without deliberately altering approved art.

## D. Regressions

**PASS**

Recorded required runs:

- new maintenance suite: 11/11;
- `m42_assets`: PASS;
- `m42_home`: PASS;
- `m42_home_composition`: 9/9;
- `m42_home_v04`: 18/18;
- `m42_home_v05`: 13/13;
- `m42_home_v06`: 13/13;
- `m42_home_v07_safe_area`: 9/9;
- `m42_c002_scrubby_scale`: 7/7;
- `m42_c003_scrubby_animation`: 18/18;
- `m42_navigation`: PASS;
- `m42_opening`: PASS;
- root `tests/run_tests.gd`: 5323 checks, 0 failures.

After the final diagnostic-field edit, the directly touched Home/asset suites were rerun and passed, plus Home-adjacent M28/M40/M43 suites.

The full historical 123 top-level-suite sweep was not rerun. I do not treat this as a blocker here because the production diff is confined to the Home asset validator/binder plus an opt-in read-only Home diagnostic seam, the root aggregate suite is clean, and all identified Home/validator/binder consumers were explicitly exercised. No evidence of a new unrelated suite failure was found.

## E. Real export proof

**PASS**

Strict pre-export source gate ran immediately before export and passed.

Real export evidence:

- Godot 4.7.2 stable official Web templates;
- real `--export-release "Web"`;
- export exit 0;
- PCK produced outside the repo;
- exported runtime served locally;
- real headless Chrome/DevTools execution.

The exported runtime itself reported:

- `template=true`;
- `editor=false`;
- `web=true`;
- `mode=PACKAGED_RUNTIME`;
- raw HOME-026 source PNG absent;
- strict source validation inside the exported package false, reproducing the old failure condition;
- packaged manifest valid;
- 24/24 mapped Home nodes bound, none unbound;
- WorldBackground bound;
- HOME-026 bound;
- all four shortcut icons and other mapped approved Home art bound;
- HomeScrubbyHero frames present;
- Wave 14 / Bow 15 / Turn 17 / Full Turn 17.

The committed probe code genuinely captures browser console output through Chrome DevTools and writes the diagnostic JSON/screenshot only after seeing the exported runtime diagnostic line. The binary screenshot cannot be independently rendered through the GitHub text connector used for this audit, so I do not claim independent visual inspection of its pixels. The exported runtime JSON/console evidence is nevertheless direct and sufficient for the binding defect being audited.

## F. Governance / hygiene

**PASS**

Comparison `836d5d9...02f7161` shows one focused commit. Changed production/test/tool files are limited to:

- Home manifest validator;
- Home art binder;
- HomeScreen opt-in diagnostics;
- focused maintenance test;
- Web runtime probe;
- cycle log/evidence.

No `TASKS.md`, approved asset file, HOME manifest, SHA pin, `project.godot`, `export_presets.cfg`, export output or `.import` file was changed by the implementation commit.

`git diff --check` is recorded clean.

## Audit limitation

I independently inspected the published commit/diff, validator, binder, maintenance test, export probe and text evidence in GitHub. I did not independently execute Godot or Chrome from the user's local machine. Claude's runtime/test commands therefore remain E1/E2 evidence, cross-checked against the implementation and committed exported-runtime diagnostic artifacts.

No material defect was found under the available evidence.

## Closure

**MAINT-HOME-EXPORT-ASSET-GATE-C001 = AUDITED_PASS / CLOSED**

The release-blocking exported Home-art blank-screen defect is closed.

M42-C003 remains closed with its prior 4/4 owner visual PASS. The project may resume the existing M43 Player Experience / Meta UI roadmap.
