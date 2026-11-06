STATUS: READY

# Build: SB-M22-026 texture budget closeout

## Summary
The lossless capping work is finished and no new safe cap was left to apply. I re-ran the measure tool after SB-M22-028. apply_caps proposes only `fx_clean_sparkle`, which stays uncapped because particles and clean sprites also draw it. The only limits under 2x are the 13 viewed card arts, kept on purpose. No `.import` changed. The no-alpha PNGs are opaque by design and their art is unchanged. VRAM compression was NOT applied: there is a measured estimate per folder for a future owner visual decision. No atlas.

Files changed:
- `docs/07_UI_ASSET_PIPELINE_DECISIONS.md`: UI-ADR-008 step 7 (closeout, no-alpha list, VRAM estimate table) (5fbc83da)
- `TASKS.md`: queue row SB-M22-026 set to DONE, checklist row set to [x] with evidence (419d419c)

## Acceptance criteria
1. [x] Re-run the measure tool with throw-away saves and apply the remaining safe lossless caps: ran `godot --headless --path . -s res://tests/tools/m22_026_texture_measure.gd -- --out=<scratch>/measure.json`. Result: `M22-026 MEASURE: DONE (84 scenarios, 188 textures)`, exit 0, 0 SCRIPT ERROR. Running `python -I tools/m22_026_apply_caps.py measure.json` printed "would cap 1 texture(s); 13 existing limit(s) under 2 x drawn side". The 1 is `gameplay/effects/fx_clean_sparkle.png`, skipped by the spec rule (code/particle drawn). The 13 are viewed card arts at 1080 / 585 px, a decision kept from step 5 / SB-M22-028. 73 textures were "source <= limit" (this includes the 440x660 thumbnails at 325 px) and 115 have an existing limit. So no cap was applied, and no tracked file changed during import or measurement.
2. [x] The 7 no-alpha PNGs were reviewed: a stdlib PNG header scan found 14 without alpha (color type 2/3, no tRNS). These are the 7 the row names plus the event hero, the boot splash and 5 video first-frame stills. All are full-bleed or opaque by design. `bot_parts_bar_frame` has no runtime reference and is noted in the doc. No art was changed.
3. [x] No VRAM or lossy switch: every import is still `compress/mode=0` (m22_029 checks this). UI-ADR-008 step 7 has the per-folder estimate: library 2276.8 -> ~561.3 MiB, cold Home ~133.5 -> ~33 MiB, packs 235.11 -> ~59 MiB. It is left as an owner visual decision after raw before/after captures.
4. [x] Budget test and suites: there are no new caps, so `tests/m22_026_texture_budget.gd` is unchanged. It still asserts every existing cap. Suites (LOCAL_PASS, each exit 0 with 0 SCRIPT ERROR/Parse Error):
   - m22_026_texture_budget: PASS (Home 111.02/117, Ceremonies 219.90/230 MiB, all screens under budget)
   - m22_029_texture_cold_warm: PASS (cold 133.50/147, peak 145.91/161 MiB)
   - m22_028_collection_card_lru: PASS
   - m21_real_art_smoke: PASS
   - m42_home: PASS

## Validation
- `godot --headless --path . --import`: exit 0. The import rewrote project.godot (dropped `boot_splash/*` and `[audio]`) and gave `.import` files EOL-only changes. I restored all of it with `git checkout -- .` and deleted the generated untracked `.uid`/`.import` files. `git status --porcelain` is empty.
- The measure tool and the 5 suites above: PASS.
- I did not run CI or build for a phone, as instructed. Nothing was pushed.

## Log
### Round 1
I re-measured, then reviewed the apply_caps output and found no safe cap. I checked the no-alpha PNGs, wrote the VRAM estimate note and ran the 5 suites. Commits: 5fbc83da (docs), 419d419c (tasks). Review label: CLAUDE_SELF_REVIEW until the factory peer review.
