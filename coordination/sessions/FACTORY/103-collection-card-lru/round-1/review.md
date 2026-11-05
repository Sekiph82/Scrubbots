# Review round 1, 103-collection-card-lru (SB-M22-028)

Checks
- git diff --check: clean.
- tests/m22_028_collection_card_lru.gd: PASS (exit 0).
- tests/m43_master_c007_collection.gd: PASS 19/19.
- Godot --import left .import churn in the worktree only (project.godot restored); no effect on the branch.

LRU
- card_texture_lru.gd: the limits (24 full / 96 MiB) count every held texture, pinned ones included. Eviction skips pinned paths and is LRU-ordered. It runs on pin/unpin, and every texture() call in the screen is followed by a pin in the same path (album, set, card), so the steady state is bounded.
- Eviction only drops the cache's own reference. The texture then leaves the ResourceLoader cache once no node draws it, because the default load() uses REUSE and keeps no strong ref. m22_028 asserts has_cached false for evicted, undrawn cards. Previous-set tiles are queue_free'd, so they release at frame end, which is fine.
- Unpin happens on set/card close and on push failure. The cache is freed with the album popup.

Thumbnails and behaviour
- Whole-card 440x660 downscales, no crop or atlas. The tool has a --check mode, and the test compares against a Lanczos downscale. Source art is untouched.
- The collection_screen.gd diff touches only texture sourcing and pinning. NEW/extras, paging, reveal, duplicate/pity and economy code paths are unchanged.
- The c007 k10 adaptation is fair. A bounded LRU cannot hold a scan of all 15 sets' thumbnails, so the warm pass now re-opens the last 5 sets. It keeps the 150 ms budget and adds a stricter assertion of 0 loads. The cold pass is unchanged.
- Repo +29 MB for 135 lossless PNGs is acceptable against the roughly 300 MiB resident saving (400 -> 92 MiB).

Findings: none blocking.

Notes
- open_card with cache == null falls back to a plain load(). Only standalone callers hit this, which is acceptable.

VERDICT: PASS
