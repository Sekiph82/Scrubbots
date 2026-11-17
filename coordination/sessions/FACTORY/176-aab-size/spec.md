# 176-aab-size (SB-AAB-SIZE-2026-11-17)
The signed release AAB (job 168, run 44105591683) is ~396 MB; Google Play rejects a base module over 200 MB
compressed (download size), and the iOS IPA is ~370 MB. Owner wants the store release and a small game ("oyun
dosyasini sisirmesinler"). Free tools only.
## Goal
Release AAB base module comfortably under 200 MB (target <= 150 MB) without visible quality loss on phones.
## Do
1. Measure: export the PCK (or read CI artifact) and list the biggest contributors by imported size (textures,
   videos, audio, fonts, level previews, card art, events art). Write the table to build.md.
2. Shrink, in this order of preference:
   - textures: per-folder import presets suitable for mobile (lossy WebP/Basis-UASTC or VRAM-compressed ETC2/ASTC
     where appropriate; keep lossless for pixel-art/level previews and anything pixel-exact; mipmaps off for UI),
     limit oversized sources (no 2048+ UI art drawn at <= 1080 px);
   - videos (.ogv): re-encode at the resolution they are actually shown at, with quality that keeps the magenta
     chroma key clean (verify key on frames; no magenta fringe);
   - audio: ogg vorbis at a sensible bitrate;
   - remove anything still exported but never loaded.
3. Visual check: GPU captures of Home, gameplay (L11), a win video frame, Collection, Robots, Events page before vs
   after at 1080x2340; side-by-side sheet. No visible degradation of pixel art or text.
4. Prove the size: run the aab_release mode (exists on factory/168-release-signing; if not yet on main, measure the
   apk_only/universal APK and the exported PCK instead and estimate) and report before/after MB for AAB, APK and IPA.
5. Suites: texture budget, Home/gameplay/visual suites + full CI list via tools/run_suites.py; exact PASS lines.
## Must not
No change to pixel-art level data, gameplay, economy. No new paid tools. Do not delete owner art sources outside
what job 165 already did; prefer import-setting changes over deleting.
