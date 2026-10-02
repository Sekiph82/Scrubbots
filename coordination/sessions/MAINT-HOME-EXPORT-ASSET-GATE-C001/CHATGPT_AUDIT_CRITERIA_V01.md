# MAINT-HOME-EXPORT-ASSET-GATE-C001 — CHATGPT AUDIT CRITERIA V01

Date: 2026-10-02

## A. Trust model / source integrity

- [ ] Validator has explicit SOURCE_TREE_STRICT and PACKAGED_RUNTIME modes.
- [ ] Default validator behavior remains SOURCE_TREE_STRICT.
- [ ] Strict mode requires raw approved source PNG existence and exact SHA match.
- [ ] Strict mode still detects tampering/mismatch.
- [ ] Packaged mode never treats "missing source PNG" as a generic reason to skip integrity checks; it is a distinct explicit mode.
- [ ] Packaged mode still requires valid pin metadata, APPROVED status, final-root path and manifest schema.
- [ ] Imported `.ctex` bytes are not substituted as the owner approval hash.

## B. Runtime binding

- [ ] HomeArtBinder selects explicit mode and tests can inject it.
- [ ] Automatic mode selection is verified in Godot 4.7.2 editor/source execution and a real Web export.
- [ ] Strict `state()` still rechecks source hash dynamically.
- [ ] Packaged `state()` uses ResourceLoader/resource loadability, not raw PNG SHA.
- [ ] Missing packaged resource fails closed.
- [ ] Normal approved Home texture binds in packaged mode.
- [ ] HomeScrubbyHero animation set binds in packaged mode with exact counts 14/15/17/17.
- [ ] generated/unapproved/unknown/malformed paths remain blocked.
- [ ] Whole-manifest structural failure remains fail-closed.

## C. Test sensitivity

- [ ] New maintenance suite simulates absent source bytes via an explicit seam/nonexistent source root.
- [ ] The same setup fails in strict mode and passes in packaged mode only when exported resources resolve.
- [ ] Wrong strict source pin fails.
- [ ] Missing/invalid pin metadata fails packaged mode.
- [ ] Missing packaged resource fails packaged mode.
- [ ] Generated path cannot bind in packaged mode.
- [ ] Existing M42 tamper tests remain meaningful rather than being rewritten to green.

## D. Regressions

- [ ] `tests/m42_assets.gd` passes.
- [ ] all current `tests/m42_home*.gd` suites pass.
- [ ] `tests/m42_c002_scrubby_scale.gd` passes.
- [ ] `tests/m42_c003_scrubby_animation.gd` passes.
- [ ] `tests/m42_navigation.gd` passes.
- [ ] `tests/m42_opening.gd` passes.
- [ ] new maintenance suite passes.
- [ ] root `tests/run_tests.gd` passes.
- [ ] no new top-level suite failure is introduced.

## E. Real export proof

- [ ] Strict source gate ran immediately before export.
- [ ] Real Godot 4.7.2 Web export succeeded using local template/preset.
- [ ] Exported runtime, not source project, reports packaged validation mode.
- [ ] Exported Home background is bound.
- [ ] Exported HOME-026 is bound.
- [ ] Exported approved icons/shortcuts are bound.
- [ ] Exported gesture set exists with 14/15/17/17.
- [ ] No blank-Home / MANIFEST_INVALID behavior.
- [ ] Browser/runtime screenshot or equally direct exported-runtime evidence exists; any automation limitation is stated without overstating proof.

## F. Governance / hygiene

- [ ] No approved asset bytes or approved SHA pins changed.
- [ ] No `project.godot`, local `export_presets.cfg`, export output, `.import` churn or owner-local files committed unintentionally.
- [ ] Root `TASKS.md` not edited by Claude.
- [ ] Code comments/docs describe source/build vs packaged-runtime trust accurately.
- [ ] `git diff --check` clean.
- [ ] Focused commits pushed safely to main.
- [ ] `CLAUDE_LOG_V01.md` exists and matches this prompt.

Audit result is PASS only when both the strict development gate and actual exported runtime gate are proven.
