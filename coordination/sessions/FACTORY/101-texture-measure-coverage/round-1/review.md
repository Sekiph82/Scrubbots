# Review round 1, job 101 (SB-M22-029)

Checks
- m22_026_texture_budget: PASS (after `--import` in the fresh worktree; without it every texture fails to load, which is not a code issue).
- m22_029_texture_cold_warm: PASS (cold 93 tex / 133.50 MiB, peak 145.91, warm after 2 visits 93 / 133.50).
- project.godot restored; working tree has no non-.import changes.

Caps vs 2x drawn (from the builder's coverage table in docs/M22_029_TEXTURE_COVERAGE.md; I did not re-run the 84-scenario measure tool, whose output json was not left behind)
- icon_lock 512 vs 60 px (2x=120), gift_bar / win_streak 512 vs 94 (188), day frames 1024 vs 304 (608), emblem 1024 vs 261, icon_shortcut_collection 1024 vs 268: all >= 2x with wide margin.
- daily_login_calendar uncapped (954 px drawn, 2x > source): correct. Only `process/size_limit` lines changed in 8 .import files; no PNG added/changed/deleted, no atlas.
- Budget raises: Shop/Collection 41->47, Daily 32->40, Profile 32->35 are tied to re-measured 1170x2532 totals (42.98 / 36.41 incl. newly measured day-card frames / 32.05 MiB, +~10%). They come from the 8% larger phone draw, the three corrected under-2x limits (+7.21 MiB) and newly listed textures; net memory is down 14.12 MiB. Justified.
- Cold/warm test asserts real things: no growth between visits, card art resident while open and zero after close, cold/peak budgets, all 570 final imports lossless/no mipmaps. Budget test also pins the uncapped calendar and the new caps.
- Tool changes use `user://` temp saves with `boot_save_path_override`; no real save touched.

Notes (non-blocking)
- Leftover `m22_026_measure_*.save` files from Nov 5 in the SCRUBBOTS user dir (throw-away saves from interrupted runs); harmless, clean up when convenient.

Must-fix: none.

VERDICT: PASS
