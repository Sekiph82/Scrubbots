VERDICT: PASS

## Findings
None.

## Notes
Reproduced in the worktree with Godot 4.7.2 headless. Every run exited 0 with no SCRIPT ERROR or Parse Error.
- m22_026_texture_budget: `M22-026 TEXTURE BUDGET: PASS`.
- m47_touch_r01_mobile_ux: `M47-FAMILY-APK-TOUCH-R01 mobile UX: PASS (14/14 cases, 0 fail)`.
- m43_master_c007_collection, 3 runs, each ending `M43 master C007 Collection evidence: PASS (13/13 cases, 0 fail)`.
  - Warm set-detail build: 70, 73 and 77 ms, against the 150 ms budget. Cold: 285, 222 and 271 ms (printed only, not asserted).
  - Peak nodes 111.
  - Each run prints an `at: clear (core/io/resource.cpp:822)` trace line. It does not fail the run.

m43 diff vs origin/main: one line only. `_k10` `open_set` now passes `Callable(), album.get_meta("tex_cache")`. The assertion `worst_us < 150000 and max_nodes < 400` is unchanged. This also undoes my round-1 concern, because the 500 ms loosening is gone. The warm pass again measures cache-assisted repeat opens at about 75 ms.

Release check (m22_026_texture_budget `_card_art`): it is a direct assertion.
- It loads `arts[0]` through `CollectionScreen._tex` into a local cache dict.
- It frees the TextureRect and asserts `ResourceLoader.has_cached` is true, so the visit cache alone keeps the texture.
- It then drops the dict (`visit = {}`) and asserts `not ResourceLoader.has_cached`. The log shows `ok: ...card_01.png released once the visit cache is freed`.
- A static or leaked cache would fail this. The `"_tex_cache" in CollectionScreen` check guards the same property.
- Residual: the loop's `tex` variable is overwritten by later cards, so it does not pin `arts[0]`. The pass confirms this.
