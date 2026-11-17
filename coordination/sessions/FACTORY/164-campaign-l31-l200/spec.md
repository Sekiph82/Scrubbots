# 164-campaign-l31-l200 (SB-CAMPAIGN-L31-L200-2026-11-17)

Owner 2026-11-17 (chat): "170 tane daha level yuklemek istiyorum. suanda 30 vardi. simdi 200 olsun." Source:
"release pooldan bak" — the Release Pool Ready folder (owner says 1400+ ready; 1495 LF-*.png counted).

## Source (READ ONLY, never write there)
`C:/Users/sekip/Desktop/Scrubbots - Pixel Art Generator/data/Release Pool/Ready/` — LF-xxxxxx.png plus
`candidate-owner-*-ready.json` entries (and their pipeline files). Inspect the entry schema first; it may
differ from the 2026-10-30 `scrubbots-release-pool-entry/v1` used by job 071 (tools/import_release_pool_levels.py).
Verify every referenced file's sha256 against the entry.

## Build
1. Reuse/extend tools/import_release_pool_levels.py (job 071) for the current pool layout. Reproducible.
2. Select 170 distinct entries for L31..L200 following the locked 10-level cadence
   (E E M E H E E M E VH) by the entry's Difficulty V1 class/score; fall back like job 071 when a class is
   short (nearest score). Prefer moderate session load, avoid near-identical neighbours (same subject/
   name/colour set back to back) and repeats of L1..L30 subjects. Difficulty is low priority for the owner:
   reasonable cadence is enough, no new calibration work.
3. REAL-PLAY GATE ON CURRENT MAIN (mandatory): the gameplay shell geometry changed on 2026-11-17 (jobs 159/163),
   which shortened bot travel and broke the old L30 order. Pool entries were verified on older game commits.
   For every chosen level run tools/real_play_file.gd (canonical 1/60, --canonical-only) with its plan on this
   branch. If it does not WIN, try tools/real_play_verify.gd --regen style reordering of the SAME clicks; if
   still not WON, drop that entry and take the next candidate for the slot. Record per level: verdict, frames,
   game commit. Run in parallel (<= 4 Godot processes).
4. Import in this repo's format exactly like L11..L30 (level JSON, supply plan, metadata with release-pool
   provenance, preview PNG); cells/palette/width/height/version verbatim. Append to
   data/levels/catalog/production_catalog_v1.json (200 entries, orders 1..200).
5. Check everything keyed by level number still works past L30: worlds_v1.json level->world mapping (20 worlds,
   Home area label), feature unlocks, end-of-content at L200 (frontier 201), progression/Difficulty V1 cadence
   tables, Home journey strip, Ranks, events. Extend data only where it is defined per level range; do not
   invent new mechanics. Report anything that needs an owner decision instead of guessing.
6. Size: report APK size impact (level JSON + previews); keep previews in the same format/size as L11..L30.

## Tests
- New permanent suite tests/campaign_l31_l200.gd (fast): 200 catalog entries in order, all load, validator
  rules (palette V3, 3..12 colours, envelope, VOID v2, >= 200 non-VOID), cells/plan digests equal recorded
  provenance, cadence class per slot as recorded. No per-level kernel/real-play in CI (owner: no re-validation
  of pool levels in CI); the real-play gate results above are the evidence, committed as a JSON report.
- Add it to the CI list with an exact grep -qxF guard. Run the affected suites (campaign_l11_l30, m35 catalog,
  m37 progression, cp04/cp05/cp06, m43 end-of-content, m42_home, real_play_levels) with exact PASS lines.

## Must not change
L1..L30 data/plans, game rules, economy, art. No APK/IPA build.
