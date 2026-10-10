# M47-FAMILY-APK-C001 — OWNER EXPORT HYGIENE DECISION V01

Date: 2026-10-10
Repository: `Sekiph82/Scrubbots`
Authority: OWNER
Status: **LOCKED FOR FAMILY APK EXPORT**

## Objective

The Family APK must contain only shipping/runtime content required by the game. Development evidence, source-reference art, tests, generators, candidate art and raw generated art must not be packaged into the Android APK/PCK.

This is an EXPORT/PACKAGING rule only. It does NOT authorize deleting these folders from Git.

## Mandatory export exclusions

The Android Family export must exclude these complete repository trees:

- `coordination/**`
- `docs/**`
- `tests/**`
- `tools/**`
- `level_factory/**`
- `content_pipeline/**`
- `assets/art/references/**`
- `assets/ui/candidates/**`
- `assets/ui/generated/**`

## Current tracked inventory at decision time

From current GitHub `main` tree:

- `coordination/`: 3,214 files, ~1680.34 MiB
- `docs/`: 28 files, ~0.41 MiB
- `tests/`: 326 files, ~3.83 MiB
- `tools/`: 26 files, ~0.23 MiB
- `level_factory/`: 18 files, ~0.03 MiB
- `content_pipeline/`: 19 files, ~0.02 MiB
- `assets/art/references/`: 61 files, ~29.71 MiB
- `assets/ui/candidates/`: 27 files, ~38.76 MiB
- `assets/ui/generated/`: 222 files, ~63.10 MiB

Total excluded tracked inventory at decision time:
**3,941 files / ~1816.43 MiB.**

Within `coordination/`, the current tracked PNG+WebP evidence count is 999 files, approximately 1.48 GiB of image bytes.

These numbers are evidence only and may drift as the repo grows. The exclusion rule is path-based, not count-based.

## Why candidates/generated are excluded

The root `ASSET_GENERATION_MANIFEST.json` explicitly defines:

- `assets/ui/generated/` = **raw_generated**
- `assets/ui/final/` = **production_final**
- `assets/art/references/` = owner/reference source material

The shipping Standard Pack code loads:
`res://assets/ui/final/rewards/pack_opening/standard/`

The shipping Premium Pack code loads:
`res://assets/ui/final/rewards/pack_opening/premium/`

It does not load `assets/ui/candidates/`.

Repository blob comparison also shows 22/27 current candidate pack PNGs are already byte-identical to files under `assets/ui/final/`; the remaining 5 candidate Standard frames are non-shipping candidate variants.

`assets/ui/generated/` contains raw/source/versioned generation output and is not the production authority.

## Production authority

Do NOT exclude:

- `assets/ui/final/**`
- runtime `scripts/**`
- runtime `scenes/**`
- required `data/**`
- required built-in level art/content
- required `addons/**` used by shipping
- audio/fonts/branding actually referenced by the app

The implementation must verify actual dependencies instead of blindly reducing the project.

## CI/import rule

Do not delete owner-local files.

For GitHub Actions, it is allowed and preferred to keep dev-only trees out of the final export workspace by:
- valid Godot export exclusions; and/or
- a disposable CI staging/sparse checkout specifically for the export job.

Tests may run from a fuller checkout before the final export staging step.

No owner Desktop cleanup/delete is authorized by this decision.

## Acceptance

A Family APK/PCK is not accepted unless an artifact inspection proves **zero packaged paths** under every mandatory excluded prefix above.
