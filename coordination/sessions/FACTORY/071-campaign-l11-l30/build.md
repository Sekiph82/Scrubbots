STATUS: BLOCKED

# Build: 20 Release Pool levels as campaign L11-L30

## Summary
Branch `factory/071-campaign-l11-l30` (not pushed): 88f7348b (levels), a3ba53ef (tests + CI), 8c96921b (TASKS.md).
20 owner-art release-pool entries (`candidate-owner-*`, `EXACT_LOGICAL_OWNER_UPLOAD_TO_CANONICAL_CANDIDATE`, one per source art,
sha256 of level/supply/artwork verified) imported by `tools/import_release_pool_levels.py` as `level_011_*`..`level_030_*`:
level JSON (cells/palette/size/version copied verbatim; only id/name/difficulty change), supply plan (levelId/batchId
relabelled), metadata with a `releasePool` block (entryDigest, candidateId, owner source/artwork/level/supply sha256,
pool class, challenge score, session load, Studio `SOLVED` + replay `WIN`), and a preview PNG that the importer asserts equals
the pool artwork pixels. Catalog entries 11..30 appended. New suite `tests/campaign_l11_l30.gd` added to the CI validate loop
(61 total, exact 5/5 guard). Suites that assumed the builtin catalog ends at L10 now use L30 (cp04, cp06, remote_content_family_fixture,
m40_v04_bootstrap, m42_home, m43_c001a_results_foundation, m52_owner_supply_plans, m55_long_session).

| L | Name | Size | Colours | Class (pool) | Score | Session load | VOID | candidate_id |
|---|---|---|---|---|---|---|---|---|
| L11 | Duckling | 32x32 | 6 | EASY (MEDIUM) | 37.9 | 14.0 | 528 | candidate-owner-4b8be03dd9f14c7f9f17ca5ae8544b9ef1c1e1a9ec7cce8f |
| L12 | Ladybug | 32x32 | 6 | EASY (MEDIUM) | 38.6 | 15.4 | 490 | candidate-owner-e52e80741f9a937574ecd97b3ce93523f4c07476885e64d2 |
| L13 | Goldfish | 32x32 | 7 | MEDIUM (MEDIUM) | 45.0 | 14.1 | 543 | candidate-owner-72efef1425ad6891884c39bdfc04aef1ef7641bf03bbb953 |
| L14 | Goose | 32x32 | 5 | EASY (MEDIUM) | 39.3 | 11.7 | 612 | candidate-owner-e26b81cc6cc364364e3bb1b5eefbb79b88556c49aabbb5d8 |
| L15 | Octopus | 32x32 | 6 | HARD (HARD) | 50.0 | 20.5 | 322 | candidate-owner-896ddd7df33ad6ffcdbcdb1edaaaece8c3d9b1f116143aeb |
| L16 | Teddy Bear | 32x32 | 6 | EASY (MEDIUM) | 40.4 | 17.5 | 406 | candidate-owner-a8cf6769a3053bac6b224b7d00cfaca28015043ae309ec06 |
| L17 | Ninja | 32x32 | 9 | EASY (MEDIUM) | 42.0 | 16.6 | 461 | candidate-owner-9375e5168ad6f9de7fcf94aaa95d641e0d95006b329c1ef6 |
| L18 | Wizard | 32x32 | 10 | MEDIUM (MEDIUM) | 45.3 | 16.3 | 480 | candidate-owner-6907c866ca9ff627edbf2c1ab2001f96b40587644291c9a2 |
| L19 | Whale | 32x32 | 5 | EASY (MEDIUM) | 41.3 | 12.6 | 595 | candidate-owner-ba551e0efaa6ed9a39c187e76cae9a727b3f042e00140826 |
| L20 | Detective | 40x40 | 10 | VERY_HARD (HARD) | 60.0 | 50.3 | 0 | candidate-owner-ef2362240f3c7350571967d62dd9eaf2aa6e3bf2ff1d1f30 |
| L21 | Bunny | 32x32 | 5 | EASY (MEDIUM) | 42.2 | 13.8 | 554 | candidate-owner-ed46768409271c2327082df3f24ec579d07e58b33fe18e5a |
| L22 | Crab | 32x32 | 5 | EASY (MEDIUM) | 42.6 | 18.8 | 390 | candidate-owner-36ca9b4074ba991b52c6e5b5b89ee2acce581fa009fdf6c7 |
| L23 | Bumblebee | 32x32 | 7 | MEDIUM (MEDIUM) | 46.0 | 15.7 | 489 | candidate-owner-bd3e8a5ad70fdfedf3d306fac0a1c717e8ab9802f79c1a18 |
| L24 | Chef | 32x32 | 9 | EASY (MEDIUM) | 44.3 | 15.3 | 502 | candidate-owner-0351429db11137e3d9932cd903972ec4409b8b020e5751e2 |
| L25 | Knight | 32x32 | 11 | HARD (HARD) | 50.2 | 16.5 | 470 | candidate-owner-d68e000911dd22702458edc828fa817548a28c61df38ffec |
| L26 | Sheep | 32x32 | 5 | EASY (MEDIUM) | 42.6 | 17.2 | 421 | candidate-owner-905e719b10b3a1972dc8e82f9585483f4f361a6bc9711541 |
| L27 | Black Cat | 32x32 | 7 | EASY (MEDIUM) | 42.0 | 16.0 | 478 | candidate-owner-89a8f149b5e5e3aa2b28d7b93b3f57c91ebb046bd48b5b22 |
| L28 | Squirrel | 32x32 | 6 | MEDIUM (MEDIUM) | 46.7 | 18.1 | 400 | candidate-owner-70956566050ab939404dee4390f2006845d29f822804315e |
| L29 | Turtle | 32x32 | 8 | EASY (MEDIUM) | 42.7 | 14.3 | 539 | candidate-owner-9aa5c74f056274ccad4eb61e98dfd3df98bb70f1d4ab9642 |
| L30 | Clown | 40x40 | 12 | VERY_HARD (HARD) | 61.7 | 50.5 | 0 | candidate-owner-df41c344b1980aa18dcfef6ada5b6e9a7cdea8a42d40142c |

The pool has no EASY or VERY_HARD entries: EASY slots use the lowest-score MEDIUM entries, VERY_HARD slots the highest-score
40x40 HARD entries. Subjects already in L1..L10 (butterfly) were skipped. Size impact: 80 new files, 250,284 bytes raw
(about 52 KB gzip-compressed per file), plus about 6 KB of catalog. All of it ships (data/ and previews are exported).

## Acceptance criteria
1. [x] Catalog 30 entries, orders 1..30, all validators: campaign_l11_l30 `catalog` + `levels` cases PASS; m35_level_catalog PASS.
2. [x] Cells/palette verbatim, previews == artwork: the importer asserts it per level; campaign_l11_l30 `provenance` checks preview == cells.
3. [x] Winnability: Studio pipeline evidence (solver SOLVED + replay WIN, recorded in metadata, NOT re-run here). Also a fast
   intended-click replay through the real ProofKernel: WIN for all 20 (campaign_l11_l30 `win`).
4. [x] Unlocks/end of catalog: campaign_l11_l30 `frontier` (L1..L30 resolve in order, frontier 31 CONTENT_MISSING,
   collection/card_packs at 20, robots 25, events 30, achievements still locked); cp04/cp06/family fixture: remote levels at 31+.
5. [ ] CI wiring done (61 suites, exact guard, run_suites lists it), but m55_long_session FAILS (see Blocked).
6. [ ] Not every suite passes (m55); m52_owner_supply_plans was edited but its re-run was stopped.
7. [x] TASKS.md row added (CRLF kept), with the m55 failure marked OPEN.

## Validation
LOCAL_PASS (tools/run_suites.py rule): campaign_l11_l30 5/5, m35, m37, cp04 28/28, cp05, cp05_r01, cp06 16/16,
remote_content_family_fixture, m40_save_system, m40_v04_bootstrap, m42_navigation, m42_home, m43_c001a 11/11, m44_ftue 23/23,
run_tests, m55_economy_release_regression, all m39*, m41, m43_* masters (c005, c005r, c006, c007, c007r, c008, c009, c010,
c011_c014), m54, m45, m46 22/22, m49, m50 x2, m51, m28 x2, m47, m43_c003, m44 unlock/coach/badge/pending_packs, m43_c005f phase4/6, m43_c005 c072/c074.
FAIL: m55_long_session. Not re-run after edit: m52_owner_supply_plans (run stopped on owner instruction).

## Blocked
m55_long_session plays every builtin level twice through the real app. With LEVELS = 30 it fails on two things:
1. L20 Detective ends LOST under the suite's real-runtime driver, which presses the plan's intended clicks whenever a slot is free
   (ProofKernel replay and the Studio pipeline both WIN). It is not yet known whether the driver's timing or the level is at fault.
2. Its "one clear event per cell" check compares clears with width*height, so it fails on the VOID levels L11..L19. It should
   compare with the artwork cell count. This is a test assumption, not a game bug.
CI validate will be red until both are fixed. The owner stopped further tests, so neither was fixed.

## Log
### Round 0
Wrote spec.md, picked 20 entries, built the importer and levels, added the suite and CI wiring, and updated suites that assumed
the catalog ends at L10. Per the owner's instruction, stopped the remaining suite runs. Reverted project.godot and the
.import/.uid noise from `--import`. About 240 tracked `assets/ui/**/*.import` files still show as ` M` in git status, but they
have no content diff (a CRLF stat quirk that the main checkout shows too). Committed without pushing.
