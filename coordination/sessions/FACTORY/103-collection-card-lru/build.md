STATUS: READY

# Build: SB-M22-028 Collection card texture LRU + single-card thumbnails

## Summary
The album popup's texture cache is now a bounded LRU instead of an unbounded per-visit Dictionary. It holds at most 24 full cards and 96 MiB RGBA8. Visible textures are pinned per popup (album / set / card): they are never evicted but they count toward both limits. The cache is still freed with the album. Each of the 135 cards has its own lossless 440x660 thumbnail: the whole card is scaled down, with no crop and no atlas, and the source art is only read. Album set rows and the 9-card set grid draw the thumbnails. The full art (size_limit 1080, unchanged) loads only in the card detail. Economy, pack reveal, NEW/EXTRAS, duplicate/pity and 15-set paging code paths are unchanged.

Commits (branch factory/103-collection-card-lru, not pushed):
- 030e3294 tools/m22_028_card_thumbnails.py (+ `--check`), 135 PNGs + .import under assets/ui/final/collection/card_thumbs/ (29 MB on disk)
- 4c5165f2 scripts/ui/collection/card_texture_lru.gd (new), scripts/ui/collection/collection_screen.gd, tests/m22_028_collection_card_lru.gd (new), tests/m22_026_texture_budget.gd, tests/m22_029_texture_cold_warm.gd, tests/m43_master_c007_collection.gd, tests/tools/collection_snapshot.gd
- d1cc473d TASKS.md (queue line DONE + checklist [x]), docs/07_UI_ASSET_PIPELINE_DECISIONS.md (UI-ADR-008 step 6), docs/M22_029_TEXTURE_COVERAGE.md

## Acceptance criteria
1. [x] Bounded LRU, <= 24 full cards / <= 96 MiB card-art steady usage: m22_028 sweep (all 135 owned, every card detail opened, 15 sets forward and 15 back, 1080x2400). LRU peak was 24 full / 95.85 MiB, ResourceLoader card-art peak 91.85 MiB, steady 91.95 MiB. Before: 400.45 MiB (UI-ADR-008 step 3, all 135 full arts held by the visit cache).
2. [x] Pinned visible textures exempt from eviction but counted and tested: in the m22_028 LRU rules, a pinned card survives 40 requests and is counted in the 24; every set tile and every open card detail is pinned.
3. [x] Separate per-card low-res thumbnails, build-time tool, lossless PNG, no atlas/collage/crop, source unchanged: m22_028 checks 135 thumbnails at 440x660 RGBA8 (lossless, no mipmaps, no size_limit). One card per set is compared with a fresh Lanczos downscale of the whole source (worst mean diff 0.0091). `python tools/m22_028_card_thumbnails.py --check` printed "135 cards, ok". Source PNGs are untouched.
4. [x] Thumbnails in the 9-card grid, full res on demand in the detail view: every page shows 9 thumbnails and every detail shows the full art (m22_028). With the album open, 0 full arts are loaded.
5. [x] Evicted invisible textures leave the ResourceLoader: m22_028 checks `ResourceLoader.has_cached` is false for evicted, undrawn cards, that the first viewed full art is released after the sweep, and that every resident card texture is held by the LRU (0 outside).
6. [x] Sweep all 135 and back, reopen/close, fast paging, no double loading: m22_028 sweep. 30 pages without a frame reuse the same 9 texture instances. Reopen/close x3 holds exactly 1 full card + the 9 drawn thumbnails (12.94 MiB), 0 after close, no growth ([10, 10, 10]).
7. [x] 9-card view, 15-set paging, NEW/extras, reveal/unlock, duplicate/pity, pack reveal preserved: m43_master_c007_collection 19/19, m54, m43_master_c007r_pity 11/11, m43_c005_c006 28/28, m43_c005_c007 20/20, m44_pending_packs_gate 6/6 all PASS.
8. [x] Phone + tablet stills: factory/jobs/103-collection-card-lru/evidence/ has the album at 1080x1920, 1080x2160, 1170x2532, 1290x2796 and 1536x2048, plus set detail, card detail and exchange at 1080x2160, 1170x2532 and 1536x2048. Captured with tests/tools/collection_snapshot.gd (opengl3, throw-away save); result "COLLECTION_EVIDENCE CLEAN (0 rejected)". I checked them visually: the thumbnails are sharp and none are missing.

## Validation
All runs are LOCAL_PASS: exit 0, no SCRIPT ERROR / Parse Error, last line PASS.
- m22_028_collection_card_lru PASS (new)
- m22_029_texture_cold_warm PASS: cold 133.50 / peak 145.91 / warm 133.50 MiB, unchanged
- m22_026_texture_budget PASS
- m22_025_booster_texture_budget PASS
- `python tools/run_suites.py` for m43_master_c007_collection, m54_collection_set_master_exactly_once, m43_master_c007r_pity, m39d_daily_collection, m43_master_c011_c014, m44_pending_packs_gate and m47_touch_r01_mobile_ux: all PASS. c007 was re-run after the k10 change and passed twice: cold 134 / 326 ms, warm 59 / 71 ms, 0 loads.
- m43_c005_c006_standard_pack_presentation 28/28 and m43_c005_c007_premium_pack_presentation 20/20 PASS
- `git diff --check` clean. project.godot and Godot .import / .uid churn were restored or removed, and the tree is clean.

## Log
### Round 1
- Judgement call on thumbnail size: 440x660, about 2x the 325 px grid draw at 1170x2532 (2:3 like the source). That is 1.11 MiB resident and ~215 KB on disk each.
- Judgement call on scope: one LRU accounts for both thumbnails and full cards, so the 96 MiB covers all card art. After a long sweep, thumbnails fill most of it.
- Judgement call on the c007 k10 test: it measured a "warm" pass that re-scans all 15 sets. With the bounded LRU that pass would re-decode (an LRU can't hold a scan of 150 MiB of thumbnails). The warm pass now re-opens the 5 most recent sets and must load nothing (`lru.loads` unchanged), with the 150 ms budget kept. The first run of the old test failed on timing while other factory jobs were running Godot (timings on this machine ranged from 92 to 452 ms under load).
- Test-side find: set-complete ceremonies draw 9 full arts each. m22_028 marks them seen after granting all cards, because that memory belongs to ceremonies, not to the album.
- m22_029 now counts thumbnails as card art for its "nothing after close" check.
- tests/tools/collection_snapshot.gd now also captures set and card detail at 1170x2532 and 1536x2048.
