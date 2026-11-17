# 165-unused-asset-purge (SB-ASSET-PURGE-2026-11-17)

Owner 2026-11-17 (chat): "eski videolari, kullanilmayan resimleri arsivleme. sil. oyun dosyasini sisirmesinler."
Delete (git rm, no archive copy in the repo) old videos and unused images so the shipped game stays small.
This is the owner's explicit permission for deleting owner-original art that is no longer used.

## Scope
1. Known retired assets (delete if truly unreferenced at runtime):
   - assets/ui/final/home/videos/home_scrubby_{wave,bow,turn,full_turn}.ogv and home_scrubby_still.png (old park-baked)
   - assets/ui/final/home/background/home_background.png (old Home bg, retired by job 158)
   - assets/ui/final/gameplay/master/gameplay_v02_shell_*.png (6) and scrubbots_gameplay_master.png (retired by 159)
   - other OWNER_RETIRED / RETIRED manifest entries whose files no runtime code loads.
2. Then a systematic scan of res:// image/video/audio files (png, jpg, webp, ogv, ogg, wav, mp3, ...) that nothing
   loads: not referenced by any .gd/.tscn/.tres/.json config/manifest that the RUNTIME reads (including path
   strings built from patterns, e.g. "%s" formats, dirs scanned at runtime, card/robot/collection art indexed
   by id). Be conservative: when a file might be loaded dynamically, keep it and list it. Never delete:
   level previews/data, anything bound in an APPROVED/STATIC manifest entry, the World Transition fallback_art,
   the keyed Home videos, the plaza shells, fonts, app icons/splash, store/export assets.
3. assets/ui/generated/ raw candidates are dev-only; if they are exported into the APK, either delete them
   (owner said delete) or exclude them via export filters — prefer deletion of truly unused raw candidates.
4. Also check export_presets.cfg include/exclude filters so non-runtime folders (coordination, docs, factory,
   flow_videos, tests/tools captures, etc.) are not packed into the APK/IPA; add exclude filters where missing
   (no behaviour change).
5. Update manifests/tests that pinned the deleted files (sha256 "unchanged" checks, counts) to the new truth;
   remove or rewrite the entries for deleted files (manifest status RETIRED_DELETED or removal, consistent with
   the validators). Do not weaken unrelated checks.

## Evidence
- build.md: table of deleted files with sizes, total MiB removed from res://; list of "kept, possibly dynamic"
  files; export filter changes; estimated APK size impact (sum of exported bytes before/after; a real
  apk_only build is not required).
- Affected suites PASS with exact lines (Home, gameplay shell, texture budget, asset manifest validators,
  m42_assets, collection/robots art suites, export-related suites).

## Must not change
Gameplay, visuals on screen (nothing that is displayed may disappear), level data, job 164's files
(data/levels, previews, catalog, tools/import_release_pool_levels.py).
