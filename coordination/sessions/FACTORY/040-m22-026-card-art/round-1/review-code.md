VERDICT: CHANGES

## Checks
git diff --check origin/main...HEAD: pass
Godot suites: not run (reviewer-tests owns them). Builder reports all PASS.

## Findings
1. scripts/ui/collection/collection_screen.gd:41-47 and tests/m43_master_c007_collection.gd:~222-240. Removing the cache outright makes every set-detail open reload its 9 card arts. The builder measured 205-265 ms per open, up to 420 ms on a noisy run. That is about 3x the old 85 ms warm cost, and the builder weakened the existing 150 ms gate to 500 ms to hide it. Phones will be slower still. A per-visit cache keeps repeat opens fast and still bounds memory: it is freed with the Collection screen, not held for the whole app run. Of the existing cache's two jobs, only this one is wanted. The unbounded static lifetime is not.

   Fix:
   - Replace `static var _tex_cache` with a `Dictionary` owned by the album popup, freed with it. Create it in `open_album` and store it with `p.set_meta("tex_cache", {})`.
   - Change `_tex(path)` to `_tex(path, cache: Dictionary)`. It does `if not cache.has(path): cache[path] = load(path)` and returns `cache[path]`.
   - Pass the cache through `_refresh_album` (thumbs, line 165) and `open_set`/`_tile` (line 248). `_on_album_action` (line 189) already holds the album `p`, so it passes `p.get_meta("tex_cache")` to `open_set`. Add `cache: Dictionary = {}` as a last, defaulted parameter of `open_set`, so a standalone call (the existing tests, `collection_snapshot.gd`, `m22_026_texture_measure.gd`) gets a throwaway per-call dictionary, which is freed with that call's tiles.
   - In `_k10` of the m43 test, pass `album.get_meta("tex_cache")` to `open_set`, and restore the original budget: `worst_us = worst[1]` (warm pass) `< 150000`, with the original cold/warm message text. Drop the new 500 ms wording.
   - Memory is then bounded to textures viewed since the album opened. At the 1080 cap that is at most 135 x 2.97 MiB, only if every set is browsed in one visit, and it is released when the album closes. The budget test's `ResourceLoader.has_cached` release check should free the album (or its cache) first, and it asserts no static member remains.
   - Update the ADR step 3 wording and the "cache removal" TASKS evidence line accordingly. The spec said "cache simply removed", but the spec's own reasoning (bounded, no cross-visit retention) is met by this.

   If the orchestrator holds the spec's "remove the cache, accept the reload cost" literally, this finding is the only objection. The rest is fine.

## Notes
- Card-art budget test logic is sound. `"_tex_cache" in CollectionScreen` is the right probe for static vars. The 135 count, alpha, 1080 cap, and 440 MiB sum are consistent with the measured 400.45. The has_cached release check after `tr.free()` is valid because no other holder remains. If the finding above is adopted, keep the static-member assertion (still absent) and the release check (the dictionary must be freed first).
- The 135 `.import` files are newly tracked. The orchestrator must move the untracked copies aside before merging, as the builder noted.
- No PNG, save, or secret changes in the diff.
