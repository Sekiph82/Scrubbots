# MAINT-HOME-EXPORT-ASSET-GATE-C001 — CLAUDE LOG V01 — Export-safe Home asset gate

Date: 2026-10-02
Prompt: `coordination/sessions/MAINT-HOME-EXPORT-ASSET-GATE-C001/CHATGPT_PROMPT_V01.md`
Criteria: `CHATGPT_AUDIT_CRITERIA_V01.md` · Owner decision: `OWNER_DECISION_V01.md`
Engine: Godot 4.7.2.stable.official.ed1daf0bf (editor) + official 4.7.2.stable Web export templates · Chrome headless (DevTools protocol)
Status: `AWAITING_GPT_MAINT_HOME_EXPORT_ASSET_GATE_C001_AUDIT`

## Sync / safety

- Canonical checkout `C:\Users\sekip\Desktop\ScrubBots`, `main`; fast-forwarded to `origin/main` `836d5d9` (incoming M42-C003 V03 pass/owner gate + this cycle's prompt/criteria/owner decision).
- Owner-local state untouched and not committed: `project.godot` modification (hash identical before/after every export), untracked owner assets/`.import` files, `tests/_m55_diag_tmp.gd`, `stash@{0}`, Codex worktree.
- Not committed: local gitignored `export_presets.cfg`, export output (scratch dir outside the repo), browser profile (temp), `.import` churn.
- Root `TASKS.md` not edited. No approved asset bytes or SHA pins changed.

## Implementation

### `scripts/tools/home_asset_manifest_validator.gd`

- Explicit modes `SOURCE_TREE_STRICT` and `PACKAGED_RUNTIME`; `validate(m, project_root = "res://", mode = SOURCE_TREE_STRICT)` — default stays strict; an unknown mode is rejected (never a silent fallback).
- Shared `is_pin()` (64 lowercase hex, required in both modes) and `integrity_error(path, pin, project_root, mode)`:
  - strict: raw source PNG under `project_root` must exist (`approved source missing`) and its `FileAccess.get_sha256` must equal the pin (`approved asset changed on disk` — existing tamper wording kept);
  - packaged: no raw hashing; the canonical `res://` path must resolve via `ResourceLoader.exists` (`packaged resource does not resolve`). Imported `.ctex` bytes are never hashed or used as pins.
- Applied to approved ART entries and every animation-set frame. Schema, ids/slugs, kinds, provider, final-root `.png` paths, reuse, banned tokens, required slugs and APPROVED animation-set status are unchanged and still fail the whole manifest in both modes.
- Header comment rewritten to describe source/build vs packaged-runtime trust.

### `scripts/ui/home/home_art_binder.gd`

- `_init(manifest = null, mode = "", project_root = "res://")`: injectable mode + strict source root (test seam); `""` → `default_mode()`.
- `default_mode()`: `PACKAGED_RUNTIME if OS.has_feature("template") else SOURCE_TREE_STRICT` — verified in the 4.7.2 editor (template=false, editor=true → strict) and inside the real 4.7.2 Web export (template=true, editor=false → packaged) (`evidence/mode_feature_probe.md`).
- `state()` uses `integrity_error` in the binder's mode on every call: strict keeps the dynamic source re-hash (`HASH_MISMATCH`), packaged requires the resource to resolve (`RESOURCE_MISSING`) and never hashes raw PNGs. `texture()` / `animation_set()` still return null / `{}` when a load fails. Unknown / unapproved / non-final / invalid-manifest behaviour and `can_write()` unchanged.

### `scripts/ui/home/home_screen.gd`

- `get_asset_diagnostics()`: integrity mode, feature tags, manifest validity, bound/unbound mapped nodes, HomeScrubbyHero frame counts, plus two read-only packaging facts (`raw_source_png_present`, `strict_mode_valid_here`).
- Opt-in exported-runtime proof: `_ready()` prints one `HOME_ASSET_DIAG <json>` line only when the app is started with the user argument `--home-asset-diagnostics`; inert otherwise. No debug UI.

### Tools

- `tools/web_export_runtime_probe.py`: runs an exported Web build in real headless Chrome through the DevTools protocol, records the console, the diagnostic JSON and a Home screenshot.

## Tests

New `tests/maint_home_export_asset_gate_c001.gd` — **11/11 cases, 40 checks, 0 failures**. The packaged case is simulated by explicit mode + a nonexistent source root (`res://__maint_no_source_tree__/`), no owner file is touched:

1. real tree validates in default and explicit strict mode; unknown mode rejected;
2. wrong ART pin and wrong animation-frame pin fail strict;
3. the same no-source setup fails strict (`approved source missing`), strict binder binds nothing;
4. that setup validates in PACKAGED_RUNTIME because `res://` resources resolve;
5. packaged binder: all 52 approved ART entries `APPROVED_BOUND` with textures (background, `scrubby_home_pose`, shop shortcut, Scrub Bucks icon checked by name);
6. packaged animation set 14/15/17/17, no null texture;
7. packaged rejections: non-object manifest, wrong schema, unapproved ART, path outside `assets/ui/final/`, missing packaged ART resource (whole manifest fail-closed), missing packaged frame, pin erased/short/uppercase/non-hex, frame without pin, non-APPROVED set;
8. strict tamper (pin ≠ bytes) still invalidates; strict `state()` re-hashes after construction (post-construction divergence → `HASH_MISMATCH`); packaged `state()` binds via ResourceLoader;
9. approved ART or frame pointing into `assets/ui/generated/` invalidates the manifest in packaged mode; generated candidates have no identity;
10. automatic selector in the local editor/headless run → SOURCE_TREE_STRICT (template=false, editor=true); exported side proven below;
11. live Home: strict binder binds every mapped node + 14/15/17/17; injected packaged binder (no source root) binds the same 24 nodes.

Existing M42 tamper tests were left as they were and still pass (they run in the default strict mode).

## Regression (individually) — `evidence/focused_test_summary.md`

`maint_home_export_asset_gate_c001` 11/11 · `m42_assets` PASS · `m42_home` PASS · `m42_home_composition` 9/9 · `m42_home_v04` 18/18 · `m42_home_v05` 13/13 · `m42_home_v06` 13/13 · `m42_home_v07_safe_area` 9/9 · `m42_c002_scrubby_scale` 7/7 · `m42_c003_scrubby_animation` 18/18 · `m42_navigation` PASS · `m42_opening` PASS · root `run_tests.gd` 5323 checks / 0 failures. After the last read-only diagnostic fields: maintenance, m42_home, m42_c003, m42_assets re-run PASS; Home-adjacent m28_c002_c003_r01_remediation 24/24, m28_c002_c003_final_gate 22/22, m43_c002_c001_popup_modal_pause 23/23, m40_v04_bootstrap PASS. The full 123-suite sweep was not re-run this cycle (changes are confined to the Home asset gate + HomeScreen diagnostics; every suite that references the validator/binder/HomeScreen was run); the known baseline M21 corridor failures (`m21_v08`, `m21_v09`) are unrelated to these files.

`git diff --check` clean.

## Real Web export gate

A. **Strict pre-export gate** (`evidence/strict_pre_export_gate.md`): `m42_assets` + the maintenance suite, exit 0, immediately before export — all approved source pins match.
B. **Export** (`evidence/web_export.md`): `godot --headless --path . --export-release "Web" <scratch>/web_export_c001/index.html`, exit 0, official 4.7.2.stable templates, local `Web` preset; pck 398,053,860 B. Output stays in scratch (not committed).
C. **Exported runtime** (`evidence/exported_runtime_proof.md`, `exported_runtime/`): served on `127.0.0.1:8061`, run in real headless Chrome with the diagnostic argument added to the exported page's start args. The exported runtime reports template=true, editor=false, web=true, mode **PACKAGED_RUNTIME**, `raw_source_png_present: false`, `strict_mode_valid_here: false` (the old blank-Home condition), manifest valid, **24/24** mapped Home nodes bound (WorldBackground, Art_scrubby, all four shortcut icons, nav icons, chips, Gift, track, profile), `hero_has_frames: true`, counts **14/15/17/17**. `home_screenshot.png` shows the exported Home with full approved art. No console errors.

## Handoff

`AWAITING_GPT_MAINT_HOME_EXPORT_ASSET_GATE_C001_AUDIT`
