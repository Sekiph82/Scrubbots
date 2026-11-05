STATUS: READY

# Build: SB-M07-014 World10 Sunken Harbor underwater art production manifest

## Summary
This branch adds a declarative production manifest for World 10 Sunken Harbor (L1351-1500, confirmed by the SB-M43-136 owner world table) and a stdlib Python validator for it. It is planning data only. No art was created, and no runtime or game code was touched.
- `data/art_manifests/world10_sunken_harbor_v1.json` (new)
- `tools/validate_world_art_manifest.py` (new; reuses `decode_png`/`audit` from `tools/audit_level_art.py`)
- `docs/LEVEL_ART_INVENTORY.md` (new subsection under "Underwater artwork")
- `TASKS.md` (SB-M07-014 queue row set to DONE, checklist set to [x]; SB-M07-012 left conditional and unchanged)

Commits: 14800abe (manifest + validator + self-test), e69e259e (docs/tasks); round 2: 614da2b8 (supportPngSizeSource field + validator check + import works under `python -I`), 81b31067 (doc note on planning sizes), bd489376 (no `__pycache__` under `-I`).

## Acceptance criteria
1. [x] Manifest has 150 distinct level PNG slots L1351-1500 in 15 batches of 10. Each slot has an expected filename pattern (`level_<NNNN>_<subject>_<W>x<H>.png` plus a regex, in `assets/art/levels/source/world10_sunken_harbor/`), a grid range of 20..59 (preferred 24..40, rectangular allowed), the palette V3 C01..C16 exact-match rule with 3..12 colours, alpha 255 / VOID 0 / no semi-alpha (ADR-030 D2) and no anti-aliasing, status PLANNED, and null file/subject/sha256/provenance/license/signedOffBy. Evidence: the validator passes the committed manifest, and it checks that the levels list is exactly 1351..1500 in order and that batch = (n-1351)//10+1.
2. [x] Support slots: 8 world UI (background, world-select card, emblem, route map, entry poster, completion art, loading art, reward badge), 8 decor (branching coral, sea-fan coral, kelp, reef rock, bubble foreground, shipwreck silhouette, treasure chest, light/caustic overlay), 4 FX (bubble, foam, sparkle, silt) and 3 marketing (store key art, teaser thumbnail, promo poster). Each has a filename, size, aspect, alpha and use. The world background uses the same 940x1672 canvas as World 01 (`home_worlds_v1.json`). The validator enforces the counts {8,8,4,3}. These sizes are builder planning values, not owner-specified: the top-level manifest field `supportPngSizeSource` ("planning_value_claude_2026-11-06 ... the owner may change them when the art is commissioned") covers all support PNG and video sizes, the validator requires that field, and `docs/LEVEL_ART_INVENTORY.md` says the same.
3. [x] 3 OPTIONAL videos: intro 6-8 s and complete 5-7 s (720x1280 Ogg Theora, like the existing in-game `.ogv` files), teaser 10-15 s (1080x1920 mp4, marketing only).
4. [x] The no-collage/atlas/spritesheet/cropping/automatic-slicing rules and the immutability rule after APPROVED are stated in `exportRules`.
5. [x] Validator checks: schema, counts, unique ids/filenames, level range and batching, envelope bounds, 3..12 colour envelope, and status rules (PLANNED keeps the proof fields null; SUPPLIED/APPROVED requires sha256/provenance/license/signedOffBy). For a supplied file it checks that the file exists and its sha256 matches. For level PNGs it also checks the filename against the level, the `audit_level_art` palette/grid/alpha/VOID verdict, that the logical grid matches the filename WxH, and that no two levels have the same sha256. For support PNGs it checks pixel size and the opaque claim. Video durations are not probed, because there is no stdlib decoder; this is stated in the tool docstring.
6. [x] Synthetic fixtures only. `--self-test` writes tiny PNGs into a `tempfile.TemporaryDirectory`: a valid 20x20 3-colour level passes, and 19 invalid cases each fail with the expected message (count, batch, range, envelope, colours, support count, video count, missing supportPngSizeSource, duplicate filename, PLANNED with sha, bad status, missing license, wrong level in filename, sha mismatch, duplicate image, missing video, semi-alpha plus off-palette PNG, 19-wide grid not matching the filename, wrong-size and non-opaque support PNG). No art was committed.
7. [x] Doc section added in `docs/LEVEL_ART_INVENTORY.md`. No new tracker or dashboard.

## Validation
- `python tools/validate_world_art_manifest.py --self-test` and `python -I tools/validate_world_art_manifest.py --self-test`: both print `validate_world_art_manifest self-test: PASS (19 failing cases + valid PNG)` LOCAL_PASS
- `python tools/validate_world_art_manifest.py` and `python -I tools/validate_world_art_manifest.py`: both print `data/art_manifests/world10_sunken_harbor_v1.json: PASS`, exit 0, LOCAL_PASS
- `git status --porcelain` after the `-I` runs: empty (no `__pycache__`)
- `python tools/audit_level_art.py --self-test`: PASS (the reused module is unchanged)
- `git diff --cached --check`: clean on every commit
- No Godot suites were run, because no Godot/runtime file was changed. No CI run and no push, as the job instructed.

## Log
### Round 1
I confirmed World 10 = Sunken Harbor, L1351-1500, from SB-M43-136. I generated the manifest once with a scratch script (not committed) and wrote the validator, reusing the existing stdlib PNG decoder and level-art audit instead of writing a new one. I added the doc subsection and updated TASKS.md (queue row DONE "manifest + validator; art itself not yet supplied", checklist [x], SB-M07-012 untouched). Support PNG sizes are planning values I chose (World 01 canvas for full-screen art); they are not owner-specified.

### Round 2
The review (CHANGES, relayed by the coordinator; there is no review file in round-1/) raised two findings.
- Must-fix, support sizes not marked as planning values: I added a top-level `supportPngSizeSource` field to the manifest. It covers every support PNG and video size and says they are builder planning values the owner may change. The validator now fails when the field is missing (new self-test case), and `docs/LEVEL_ART_INVENTORY.md` gets a matching sentence (81b31067; the 614da2b8 subject also names docs, but that doc edit landed in 81b31067).
- `python -I` ModuleNotFoundError: the validator now puts its own directory on `sys.path` before importing `audit_level_art`. Because `-I` also ignores PYTHONDONTWRITEBYTECODE, the `-I` run left an untracked `tools/__pycache__/`. I deleted it and set `sys.dont_write_bytecode = True` in the validator (bd489376). Self-test and manifest check pass with and without `-I`, and the tree stays clean.
