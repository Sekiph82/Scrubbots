# MAINT-HOME-EXPORT-ASSET-GATE-C001 — CHATGPT PROMPT V01

Repository: `C:\Users\sekip\Desktop\ScrubBots`
GitHub: `Sekiph82/Scrubbots`
Branch: `main`
Implementer: Claude Code

## Goal

Fix the release-blocking Home art gate so exported builds bind all approved Home art and the M42-C003 gesture animation set, while preserving strict approved-source SHA verification in the source tree/build gate.

This task is authorized by:
`coordination/sessions/MAINT-HOME-EXPORT-ASSET-GATE-C001/OWNER_DECISION_V01.md`

## Read first

1. `CLAUDE.md`
2. root `TASKS.md` — READ ONLY, DO NOT EDIT
3. `coordination/AUDIT_POLICY.md`
4. this prompt
5. `coordination/sessions/MAINT-HOME-EXPORT-ASSET-GATE-C001/CHATGPT_AUDIT_CRITERIA_V01.md`
6. `coordination/sessions/M42-C003/CHATGPT_AUDIT_V03.md`
7. `coordination/sessions/M42-C003/OWNER_VISUAL_GATE_V03.md`
8. `scripts/tools/home_asset_manifest_validator.gd`
9. `scripts/ui/home/home_art_binder.gd`
10. `tests/m42_assets.gd`
11. `tests/m42_c003_scrubby_animation.gd`

## Known bug

In exported builds raw `.png` source bytes may not exist at `res://...`; Godot packages imported `.ctex` + remap instead.

Current unconditional calls to `FileAccess.get_sha256(res://...png)` in:
- `HomeAssetManifestValidator.validate()`
- `_validate_animation_sets()`
- `HomeArtBinder.state()`

return `""` and invalidate the complete Home manifest.

The temporary workaround "skip hash if FileAccess.file_exists() is false" is **not** the production design.

## Required design

Implement two explicit integrity modes in `home_asset_manifest_validator.gd`:

- `SOURCE_TREE_STRICT`
- `PACKAGED_RUNTIME`

Keep the existing public validator default strict so source-tree callers/tests do not silently weaken.

### SOURCE_TREE_STRICT

For approved ART and approved animation frames:
- approved pin required;
- source PNG must exist;
- `FileAccess.get_sha256()` must exactly match pin;
- mismatch/missing source is an error.

### PACKAGED_RUNTIME

For approved ART and approved animation frames:
- schema/status/final-path/pin format remain mandatory;
- do not hash raw source PNG bytes;
- require the canonical `res://...` resource path to resolve through `ResourceLoader`;
- missing/unresolvable imported texture is an error.

Do not hash `.ctex` and do not introduce platform-specific imported-byte pins.

## HomeArtBinder

Update `home_art_binder.gd` so it stores/uses an explicit integrity mode.

Requirements:

1. Default runtime policy is automatically selected using an actual Godot feature that distinguishes editor/source execution from an exported template. Verify the feature in Godot 4.7.2.
2. Tests can inject the mode explicitly.
3. In SOURCE_TREE_STRICT, preserve dynamic source hash protection in `state()` so a source file changed after binder construction does not silently bind.
4. In PACKAGED_RUNTIME, `state()` must not call raw PNG SHA. It must require a resolvable/loadable final resource.
5. `texture()` and `animation_set()` return null/{} if packaged resources do not load.
6. Unapproved, generated-path, malformed-manifest, unknown-slug and final-root protections remain unchanged.
7. `can_write()` semantics remain development/tooling protection; do not make packaged runtime a write authority.

Do not weaken the whole-manifest fail-closed behavior for structural errors.

## Test requirements

Preserve all existing M42 tests and add direct coverage for the export case.

At minimum add a focused maintenance suite, for example:
`tests/maint_home_export_asset_gate_c001.gd`

It must directly prove:

1. Real source tree + SOURCE_TREE_STRICT validates.
2. Wrong source pin still fails strict mode.
3. A strict-mode source path that is absent fails.
4. PACKAGED_RUNTIME with a deliberately nonexistent source-tree root still validates the real manifest because canonical imported resources resolve.
5. A binder explicitly constructed in PACKAGED_RUNTIME binds approved normal Home textures.
6. The same binder provides all four animation lists with counts 14/15/17/17.
7. PACKAGED_RUNTIME still rejects:
   - malformed manifest;
   - unapproved ART;
   - path outside `assets/ui/final/`;
   - missing/unresolvable packaged resource;
   - missing/invalid approved pin metadata.
8. SOURCE_TREE_STRICT keeps the existing tampered-approved-file/hash mismatch behavior.
9. Export mode does not create a bypass where `assets/ui/generated/` can bind.
10. The automatic production-mode selector resolves to SOURCE_TREE_STRICT in the local editor/headless development environment and PACKAGED_RUNTIME inside the real Web export. Record actual feature-tag evidence.

Use an injectable mode/project-root seam for deterministic tests. Do not try to fake exported behavior only by deleting owner source files.

## Existing regressions to run

Run individually and record exact outcomes:

- `tests/m42_assets.gd`
- every current `tests/m42_home*.gd`
- `tests/m42_c002_scrubby_scale.gd`
- `tests/m42_c003_scrubby_animation.gd`
- `tests/m42_navigation.gd`
- `tests/m42_opening.gd`
- the new maintenance suite
- root `tests/run_tests.gd`

If a current top-level broader sweep still contains the known unrelated M21 baseline failures, report them exactly and verify no new failures.

## Mandatory real Web export gate

Godot 4.7.2 export templates are expected under:
`%APPDATA%/Godot/export_templates/4.7.2.stable`

A local gitignored `export_presets.cfg` with a `Web` preset is expected.

Do not commit:
- `export_presets.cfg`
- export output
- browser temp files
- `.import` churn
- owner-local `project.godot` changes.

Perform this sequence:

### A. Strict pre-export gate
Immediately before export, run the strict source-tree Home asset tests and record that source pins match.

### B. Real export
Create a Web debug/release export into a temporary directory outside tracked repo output.

### C. Exported runtime proof
Serve the Web output locally and run it in a real headless Chromium/Chrome/Edge browser if available.

Prove from the exported runtime, not the source project, that:
- Home background texture is bound;
- HOME-026 Scrubby texture is bound;
- Home shortcut/icon approved art is bound;
- `HomeScrubbyHero.has_frames()` is true;
- animation set counts are 14/15/17/17;
- no `MANIFEST_INVALID` / hash-empty fallback occurs.

Preferred evidence:
- exported runtime diagnostic log emitted by a narrowly scoped test/debug seam that is inert in normal gameplay;
- headless-browser Home screenshot showing approved Home art;
- browser/runtime console log.

Do not permanently add debug UI to the shipping Home.

If local browser automation is truly unavailable, still produce the real Web export and an exported-runtime diagnostic mechanism, record the exact limitation, and do not claim visual runtime proof you did not execute.

## Documentation

Update code comments that currently say "file on disk must still match" so they accurately distinguish:
- strict source approval/build verification;
- packaged runtime resource binding.

Do not alter the approved hashes or owner art.

## Evidence/log

Write:
`coordination/sessions/MAINT-HOME-EXPORT-ASSET-GATE-C001/CLAUDE_LOG_V01.md`

Also create an evidence folder under that cycle containing:
- strict pre-export gate result;
- mode/feature-tag probe;
- Web export command/result;
- exported runtime proof;
- focused test summary.

## Git safety

- Preserve owner/local dirty files.
- If the canonical checkout is dirty and unsafe for implementation, use an isolated worktree based on current `origin/main`.
- Never reset/clean/stash owner state without explicit permission.
- Do not edit root `TASKS.md`.
- Review `git diff --check`.
- Commit focused changes.
- Push safely to `origin/main`, never force.

## Final handoff

Return:

`AWAITING_GPT_MAINT_HOME_EXPORT_ASSET_GATE_C001_AUDIT`

and the direct GitHub URL to `CLAUDE_LOG_V01.md`.

Do not self-award PASS.
