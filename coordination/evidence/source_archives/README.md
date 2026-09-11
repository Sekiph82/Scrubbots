# Source Evidence Archives

This directory preserves the two user-supplied source packages discussed during the 2026-09-12 Level Factory / pixel-art design work so they can be found again from the canonical SCRUBBOTS repository.

## 1. M10 Pixel Art Generator review corpus

Archived file:

`M10_PIXEL_ART_GENERATOR_REVIEW_CORE.zip`

Purpose: preserves the review material needed to reconstruct and inspect the 100 procedural M10 candidates, including the review HTML, logical-grid review manifest, review/metrics reports, and owner review decisions.

Original user-uploaded archive:

- original filename: `m10.zip`
- original size: 839,699 bytes
- original SHA-256: `50b0985fa5b57b4ce6c80e6e979104df313e77c6b1e6dfc75a997412bc973088`

Repository archive:

- derived filename: `M10_PIXEL_ART_GENERATOR_REVIEW_CORE.zip`
- size: 199,829 bytes
- SHA-256: `95664f9f1b8d30e0d65be38b21680761c668c606b62bfc76c8abd9adee459587`
- derivation: deterministic review-core archive containing the files needed for visual/semantic review; large property/performance execution corpus files that are not required to recover the 100 review images were omitted from this convenience archive.

This is therefore not claimed to be byte-identical to the original `m10.zip`. The original archive hash is retained above for provenance.

## 2. ScrubBots Sprite Factory v0.4.0

Archived file:

`ScrubBots_Sprite_Factory_v0.4.0_SOURCE_ONLY.zip`

Purpose: preserves the actual hand-authored PixelLab sprite-factory source, palette/config, launch/build scripts, changelogs, sample manifests and documentation.

Original user-uploaded archive:

- original filename: `ScrubBots_Sprite_Factory_v0.4.0(1).zip`
- original size: 68,295,528 bytes
- original SHA-256: `0f1718d4f0b635a4dba85c0020931106bc7e534bc42bff75b83d654397301086`
- original contained 4,993 ZIP entries and approximately 96 MB uncompressed.

Repository archive:

- derived filename: `ScrubBots_Sprite_Factory_v0.4.0_SOURCE_ONLY.zip`
- size: 13,716 bytes
- SHA-256: `d99e473d90bb64566cd199b17889a1d6fabeefd9951416d77b4397342184962d`
- 16 meaningful project/source files retained.
- deliberately excluded: `.venv/`, `build/`, `dist/`, `__pycache__/` and their third-party/compiled/reproducible artifacts.

The original 66 MB package is intentionally not stored byte-for-byte in the Git source repository because most of its size is virtual-environment packages, PyInstaller build output and the generated executable. The source-only archive is the canonical convenience archive for future engineering reference; the original hash above preserves its provenance.

## Related analysis

- `coordination/ART_INTELLIGENCE_NEGATIVE_CORPUS_FINDINGS_V01.md`
- `coordination/PIXELLAB_SPRITE_FACTORY_ENGINEERING_FINDINGS_V01.md`
- `docs/13_ART_INTELLIGENCE_SEMANTIC_LEVEL_ART_PIPELINE.md`
- `docs/14_NATIVE_PIXEL_AI_AND_BOARD_COMPOSER_ARCHITECTURE.md`

These archives are evidence/reference material only. They do not alter active M21 scope or runtime gameplay truth.
