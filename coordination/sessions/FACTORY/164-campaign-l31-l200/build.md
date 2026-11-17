STATUS: READY

# Build: 170 Release Pool levels as campaign L31-L200

## Summary
Branch `factory/164-campaign-l31-l200`, one commit **55af903f** (not pushed), rebased onto origin/main 40b38a5f (jobs 160..163, 165, 166).

- `tools/import_release_pool_levels.py` gains `--batch l31-l200`. The pool uses the same `scrubbots-release-pool-entry/v1` schema, but files now have absolute paths and acceptance is `WON_CANONICAL`. For every entry the importer verifies the sha256 of level, supply_plan, artwork and real_play_result. It writes:
  - the level JSON (cells, palette, size and version verbatim);
  - the relabelled supply plan;
  - metadata with the `releasePool` block plus `cellsSha256`;
  - a preview PNG that it asserts equals the artwork.

  It then sets catalog entries 31..200 and runs the real-play gate.
- Real-play gate: `tools/real_play_file.gd --canonical-only` on every imported level and plan, 4 Godot processes in parallel, on game commit 28741ed1 (current main, after jobs 159/163). A level that is not WON goes through `real_play_verify.gd --regen` (the same clicks reordered) and is checked again. Results go to the committed report `tools/real_play_gate_l31_l200.json` and to `data/levels/supply/real_play_provenance_v1.json` (records appended; L1..L30 untouched).
- New suite `tests/campaign_l31_l200.gd` (5 cases: catalog, levels, provenance, gate, frontier). It is in the CI loop with the exact guard `CAMPAIGN L31-L200 evidence: PASS (5/5 cases, 0 fail)`.
- Suites that assumed the builtin catalog ends at L30 now use L200, so remote content starts at 201: cp04, cp06, remote_content_family_fixture, m40_v04_bootstrap, m42_home, m43_c001a, m52 and campaign_l11_l30.
- `real_play_levels` now plays only L1..L30 (`PLAYED_MAX_ORDER`), because the owner rule is no per-level re-play of pool levels in CI. Its provenance case still checks all 200.
- `m55_long_session` still plays 30 levels per lap. It no longer presses PLAY after L30, because L31 now exists. It also waits for the last win's Home reward flight (`reward_flight_finished`) before the quiet rule. Without that wait the roughly 5 s flight used up the 5000 ms deadline: it failed under load and passed only marginally (4990 ms) when run alone.
- Home area label (owner answer 2026-11-17, "Dunya adini yaz"): the title is now the current world's name, from the same source as the world ceremony (TR `UiText.data(WORLD_NAME_n)`, EN worlds_v1 name), upper-cased with Turkish dotted i -> I-dot (`UiText.caps`), routed through the seam key `HOME_AREA_WORLD` ("%s"). The number line keeps HOME_AREA_NUMBER; the background stays the plaza. Files: scripts/ui/home/home_screen.gd, scripts/ui/ui_text.gd, scripts/ui/ui_text_tr.gd, tests/m42_home_v04.gd (world 1 + world 2, EN + TR, fit).
- Files: 680 new (170 x level / plan / metadata / preview), the gate report, the new suite, the importer, the workflow and 10 edited tests. L1..L30 data, plans, rules, economy and art are unchanged; the catalog and provenance diffs are additions only.

## Selection
The pool (`Release Pool/Ready`) has 1759 entries. All are owner uploads (`EXACT_LOGICAL_OWNER_UPLOAD_TO_CANONICAL_CANDIDATE`) and **all are 56x56**. By class: 9 EASY, 1042 MEDIUM, 708 HARD, 0 VERY_HARD. The selection is deterministic (`scratch/select_levels.py` in this job folder):
- **Filters:** at least 800 artwork cells, which drops thin line-art insects and stays far above the 200 floor. Session load at most 35 for EASY/MEDIUM, 45 for HARD and 55 for VERY_HARD.
- **Slots by cadence E E M E H E E M E VH:**

  | Slot | Source entries | Picked scores |
  |---|---|---|
  | EASY | 160 lowest-score EASY/MEDIUM entries (all picks ended up MEDIUM) | 30.8..43.7 |
  | MEDIUM | MEDIUM entries scoring 44 or more | 44.0..49.0 |
  | HARD | HARD entries scoring 49..54.5 | 49.0..54.5 |
  | VERY_HARD | 70 highest-score HARD entries | 54.7..59.7 |

  Within a class, the target score rises across the campaign.
- **Novelty:** no source atlas twice within 10 levels, at most 4 levels per atlas (79 atlases used), and never the same colour set back to back. I checked every pick on contact sheets and named it. The same subject never repeats within 10 levels, and no L1..L30 subject repeats.

| L | Class (pool) | Entry (candidate id prefix) | Name | Size | Colours | Score | Load | Real play | Frames |
|---|---|---|---|---|---|---|---|---|---|
| L31 | EASY (MEDIUM) | a97c905677d60edd | Cricket | 56x56 | 3 | 30.8 | 25.2 | WON_CANONICAL | 6551 |
| L32 | EASY (MEDIUM) | 1133ef53824d5e19 | Longhorn Beetle | 56x56 | 5 | 32.8 | 29.2 | WON_CANONICAL | 10365 |
| L33 | MEDIUM (MEDIUM) | 68d309b8dd0af5ef | Fire Jellyfish | 56x56 | 7 | 44.0 | 33.0 | WON_CANONICAL | 16743 |
| L34 | EASY (MEDIUM) | 593f7e9e7f0d9cfa | Stag Beetle | 56x56 | 3 | 32.8 | 32.2 | WON_CANONICAL | 13783 |
| L35 | HARD (HARD) | e038e72de4708991 | Mop Bucket | 56x56 | 7 | 49.0 | 35.6 | WON_CANONICAL | 26641 |
| L36 | EASY (MEDIUM) | 75378f1608d13a2a | Lobster | 56x56 | 5 | 34.7 | 29.9 | WON_CANONICAL | 10067 |
| L37 | EASY (MEDIUM) | 1d97b0cdd3673c22 | Weevil | 56x56 | 4 | 35.5 | 25.3 | WON_CANONICAL | 8623 |
| L38 | MEDIUM (MEDIUM) | 6f55348b603dafc6 | Scarab | 56x56 | 6 | 44.2 | 29.3 | WON_CANONICAL (regen) | 17729 |
| L39 | EASY (MEDIUM) | 1529c155d8b7c92e | Mantis | 56x56 | 6 | 36.0 | 30.0 | WON_CANONICAL | 6707 |
| L40 | VERY_HARD (HARD) | 11ca24e26a1613d1 | Sweeper Bot | 56x56 | 7 | 54.7 | 40.6 | WON_CANONICAL | 17901 |
| L41 | EASY (MEDIUM) | 991f3e0b0b0a9bc3 | Spirit Stag | 56x56 | 7 | 36.3 | 26.9 | WON_CANONICAL | 13231 |
| L42 | EASY (MEDIUM) | b8635f4e48534058 | Drone | 56x56 | 6 | 36.4 | 25.9 | WON_CANONICAL | 10599 |
| L43 | MEDIUM (MEDIUM) | 72973de0fa2c9f9b | Storm Cloud | 56x56 | 7 | 44.3 | 31.6 | WON_CANONICAL | 29318 |
| L44 | EASY (MEDIUM) | 4de9fa8de52458c8 | Sea Dragon | 56x56 | 4 | 36.8 | 25.6 | WON_CANONICAL | 8406 |
| L45 | HARD (HARD) | 04805b4609e7f898 | Dark Drake | 56x56 | 4 | 49.3 | 39.8 | WON_CANONICAL | 21036 |
| L46 | EASY (MEDIUM) | d509fa9fbcb4f011 | Rose Wasp | 56x56 | 4 | 37.2 | 29.7 | WON_CANONICAL | 10262 |
| L47 | EASY (MEDIUM) | 4ed0b84407eb8785 | Claw Bot | 56x56 | 7 | 37.5 | 30.4 | WON_CANONICAL | 22558 |
| L48 | MEDIUM (MEDIUM) | 5ff86b87f2d8ad12 | Robo Hound | 56x56 | 5 | 44.4 | 33.4 | WON_CANONICAL | 20403 |
| L49 | EASY (MEDIUM) | 7a27413ca497185b | Spider | 56x56 | 5 | 35.6 | 33.5 | WON_CANONICAL | 10035 |
| L50 | VERY_HARD (HARD) | de747fd405034dbb | Jade Knight | 56x56 | 5 | 55.0 | 34.6 | WON_CANONICAL | 22387 |
| L51 | EASY (MEDIUM) | 656c0440228a6814 | Dragonfly | 56x56 | 7 | 37.5 | 25.2 | WON_CANONICAL | 19699 |
| L52 | EASY (MEDIUM) | 46cda5cae5f548ae | Orchid Mantis | 56x56 | 6 | 37.6 | 26.0 | WON_CANONICAL | 15009 |
| L53 | MEDIUM (MEDIUM) | f979758a755b5cf8 | Rhino Beetle | 56x56 | 7 | 44.6 | 31.6 | WON_CANONICAL | 31487 |
| L54 | EASY (MEDIUM) | 6de6ec35f56ca850 | Lava Salamander | 56x56 | 6 | 38.0 | 28.8 | WON_CANONICAL | 13913 |
| L55 | HARD (HARD) | 5f6b2ee803680eb4 | Swamp Slime | 56x56 | 4 | 49.7 | 40.3 | WON_CANONICAL | 14346 |
| L56 | EASY (MEDIUM) | 3b755f245dfd8828 | Moon Jellyfish | 56x56 | 5 | 38.6 | 27.1 | WON_CANONICAL | 13832 |
| L57 | EASY (MEDIUM) | d1c6f65c5d9d4d28 | Shrimp | 56x56 | 5 | 38.7 | 29.1 | WON_CANONICAL | 31025 |
| L58 | MEDIUM (MEDIUM) | 55748795da0b4d6d | Centaur | 56x56 | 7 | 44.8 | 28.3 | WON_CANONICAL | 29750 |
| L59 | EASY (MEDIUM) | ce8f26a85684e5e7 | Fawn | 56x56 | 7 | 38.7 | 25.6 | WON_CANONICAL | 11782 |
| L60 | VERY_HARD (HARD) | 0be1bb8688a96b51 | Roller Bot | 56x56 | 6 | 55.3 | 42.3 | WON_CANONICAL | 20082 |
| L61 | EASY (MEDIUM) | f9c1736d9204de30 | Scorpion | 56x56 | 5 | 38.9 | 25.8 | WON_CANONICAL | 15664 |
| L62 | EASY (MEDIUM) | 4260c8beab3bbacd | Hornet | 56x56 | 7 | 38.2 | 26.9 | WON_CANONICAL | 9016 |
| L63 | MEDIUM (MEDIUM) | b677f870bdd0919f | Sea Serpent | 56x56 | 7 | 44.9 | 34.4 | WON_CANONICAL | 20607 |
| L64 | EASY (MEDIUM) | daaa146666ce4819 | Amber Dragonfly | 56x56 | 7 | 38.8 | 26.7 | WON_CANONICAL | 16767 |
| L65 | HARD (HARD) | 27493c00dfdd0f70 | Robo Piranha | 56x56 | 7 | 50.0 | 35.4 | WON_CANONICAL | 29893 |
| L66 | EASY (MEDIUM) | 57f4334cf4a30668 | Skeleton | 56x56 | 5 | 39.0 | 29.6 | WON_CANONICAL | 15965 |
| L67 | EASY (MEDIUM) | d8ab82ac1bec9c9d | Golden Stag Beetle | 56x56 | 4 | 39.1 | 32.7 | WON_CANONICAL | 15450 |
| L68 | MEDIUM (MEDIUM) | 72273b3a45bbc1f0 | Seahorse | 56x56 | 7 | 45.1 | 30.8 | WON_CANONICAL | 20848 |
| L69 | EASY (MEDIUM) | af099f99b61cdc02 | Fire Spirit | 56x56 | 5 | 39.2 | 30.1 | WON_CANONICAL | 13425 |
| L70 | VERY_HARD (HARD) | c06597c4ef886c2f | Fire Drake | 56x56 | 6 | 55.6 | 41.6 | WON_CANONICAL (regen) | 29371 |
| L71 | EASY (MEDIUM) | 6635f24554cdf5d8 | Speckled Weevil | 56x56 | 4 | 39.4 | 26.8 | WON_CANONICAL | 13106 |
| L72 | EASY (MEDIUM) | e014bbfa2006fb20 | Moth | 56x56 | 5 | 39.0 | 30.7 | WON_CANONICAL | 16810 |
| L73 | MEDIUM (MEDIUM) | 1feb20f646abafd9 | Sentry Eye | 56x56 | 8 | 45.2 | 31.0 | WON_CANONICAL | 21012 |
| L74 | EASY (MEDIUM) | 4d716af31ce92020 | Firefly | 56x56 | 5 | 38.8 | 28.4 | WON_CANONICAL | 6067 |
| L75 | HARD (HARD) | 70968877563e2f9a | Repair Bot | 56x56 | 7 | 50.4 | 31.7 | WON_CANONICAL | 42178 |
| L76 | EASY (MEDIUM) | 8db796861fe1ace3 | Spirit Bird | 56x56 | 5 | 39.4 | 26.4 | WON_CANONICAL | 9215 |
| L77 | EASY (MEDIUM) | dbdef5747af3cc72 | Stick Mantis | 56x56 | 6 | 39.5 | 26.7 | WON_CANONICAL | 19776 |
| L78 | MEDIUM (MEDIUM) | df0d027d3a4ee8cc | Azure Dragonfly | 56x56 | 6 | 45.4 | 29.6 | WON_CANONICAL | 30750 |
| L79 | EASY (MEDIUM) | 89519e20bf6e13ae | Forest Spirit | 56x56 | 8 | 39.5 | 27.4 | WON_CANONICAL | 16743 |
| L80 | VERY_HARD (HARD) | 27f96429be180f8b | Pufferfish | 56x56 | 8 | 56.0 | 42.3 | WON_CANONICAL | 37489 |
| L81 | EASY (MEDIUM) | 05182ce5d56b1dd0 | Jewel Beetle | 56x56 | 6 | 39.8 | 31.7 | WON_CANONICAL | 15790 |
| L82 | EASY (MEDIUM) | 8eabaa5458973cc0 | Anglerfish | 56x56 | 6 | 39.9 | 34.4 | WON_CANONICAL | 9890 |
| L83 | MEDIUM (MEDIUM) | d7852e16b9e5172e | Shadow Wolf | 56x56 | 3 | 45.5 | 31.3 | WON_CANONICAL | 14334 |
| L84 | EASY (MEDIUM) | aa008bebb9100820 | Tiger Bug | 56x56 | 4 | 39.8 | 27.1 | WON_CANONICAL | 15414 |
| L85 | HARD (HARD) | 617ce621856d26e0 | Nautilus | 56x56 | 5 | 50.7 | 37.2 | WON_CANONICAL | 23592 |
| L86 | EASY (MEDIUM) | 3f6922502acca776 | Shadow Wisp | 56x56 | 4 | 39.9 | 33.8 | WON_CANONICAL | 13462 |
| L87 | EASY (MEDIUM) | b92b35ad9864f1eb | Flying Fish | 56x56 | 6 | 39.9 | 29.5 | WON_CANONICAL | 10445 |
| L88 | MEDIUM (MEDIUM) | 1f61e928ca411281 | Lava Spider | 56x56 | 7 | 45.7 | 34.7 | WON_CANONICAL | 37362 |
| L89 | EASY (MEDIUM) | 3c5ddfca65287b28 | Isopod | 56x56 | 7 | 39.5 | 26.7 | WON_CANONICAL | 15584 |
| L90 | VERY_HARD (HARD) | cd5dbc4f232bff62 | Fire Tortoise | 56x56 | 7 | 56.3 | 47.7 | WON_CANONICAL (regen) | 44177 |
| L91 | EASY (MEDIUM) | 44367e52da811273 | Smoky Lobster | 56x56 | 6 | 40.0 | 33.8 | WON_CANONICAL | 14224 |
| L92 | EASY (MEDIUM) | de5db5724373d81b | Tiger Moth | 56x56 | 6 | 40.0 | 33.1 | WON_CANONICAL | 21040 |
| L93 | MEDIUM (MEDIUM) | e115288b3616e939 | Clownfish | 56x56 | 6 | 45.8 | 26.4 | WON_CANONICAL | 24432 |
| L94 | EASY (MEDIUM) | ad8d7059d8894628 | Fire Dragon | 56x56 | 6 | 40.1 | 33.3 | WON_CANONICAL | 14249 |
| L95 | HARD (HARD) | 7ec671530d9cd02f | Bell Mushroom | 56x56 | 7 | 51.1 | 39.0 | WON_CANONICAL | 33733 |
| L96 | EASY (MEDIUM) | a0edce081776adfb | Bronze Beetle | 56x56 | 5 | 40.3 | 31.2 | WON_CANONICAL | 17166 |
| L97 | EASY (MEDIUM) | 443c04c7b15853a0 | Star Spirit | 56x56 | 6 | 40.2 | 31.7 | WON_CANONICAL | 18709 |
| L98 | MEDIUM (MEDIUM) | 1e4d23d55f2bcae2 | Ghost | 56x56 | 5 | 45.9 | 28.6 | WON_CANONICAL | 17742 |
| L99 | EASY (MEDIUM) | 736bedff580b9229 | Goblin | 56x56 | 4 | 40.4 | 27.7 | WON_CANONICAL | 24252 |
| L100 | VERY_HARD (HARD) | 91094b2b5d99bc53 | Larva | 56x56 | 7 | 56.5 | 37.2 | WON_CANONICAL | 25402 |
| L101 | EASY (MEDIUM) | ce1bec9a104525ac | Painted Beetle | 56x56 | 6 | 40.5 | 32.5 | WON_CANONICAL | 14593 |
| L102 | EASY (MEDIUM) | 8d26330698dd0ed8 | Shark | 56x56 | 6 | 40.4 | 30.7 | WON_CANONICAL | 14645 |
| L103 | MEDIUM (MEDIUM) | 5d8fe1c5ec483918 | Fishfolk | 56x56 | 5 | 46.1 | 29.4 | WON_CANONICAL | 33416 |
| L104 | EASY (MEDIUM) | 69502dd7db729758 | Arctic Fox | 56x56 | 4 | 40.5 | 27.7 | WON_CANONICAL | 14341 |
| L105 | HARD (HARD) | cdfd28e35f5473ab | Hover Bot | 56x56 | 6 | 51.4 | 33.3 | WON_CANONICAL | 28003 |
| L106 | EASY (MEDIUM) | 1a7f9cf12622036a | Wasp | 56x56 | 6 | 40.7 | 26.9 | WON_CANONICAL | 11995 |
| L107 | EASY (MEDIUM) | 8f8fd69d23ef5707 | Fire Fairy | 56x56 | 6 | 40.7 | 30.6 | WON_CANONICAL | 10462 |
| L108 | MEDIUM (MEDIUM) | ac5296835fb9b36a | Zombie | 56x56 | 5 | 46.3 | 27.3 | WON_CANONICAL | 32318 |
| L109 | EASY (MEDIUM) | 7d07ad943bcdb323 | Bubble Spirit | 56x56 | 6 | 40.8 | 28.4 | WON_CANONICAL | 6785 |
| L110 | VERY_HARD (HARD) | 8d6cb601d546cccd | Geode Beast | 56x56 | 8 | 56.8 | 50.7 | WON_CANONICAL | 29204 |
| L111 | EASY (MEDIUM) | c3329d7c577371e7 | Mist Spirit | 56x56 | 4 | 40.9 | 30.9 | WON_CANONICAL | 11702 |
| L112 | EASY (MEDIUM) | 8ff24ecc889cf7f6 | Crayfish | 56x56 | 4 | 40.9 | 32.7 | WON_CANONICAL | 20957 |
| L113 | MEDIUM (MEDIUM) | d33705561e4abd3f | Teal Scarab | 56x56 | 5 | 46.3 | 32.0 | WON_CANONICAL | 20679 |
| L114 | EASY (MEDIUM) | 6bb15f61b3b43105 | Starfish | 56x56 | 7 | 41.0 | 28.4 | WON_CANONICAL | 9394 |
| L115 | HARD (HARD) | d274c17bcc93c6ce | Magma Golem | 56x56 | 5 | 51.7 | 38.1 | WON_CANONICAL (regen) | 31755 |
| L116 | EASY (MEDIUM) | 7deb1d370838ee77 | Phoenix | 56x56 | 6 | 41.0 | 33.6 | WON_CANONICAL | 9079 |
| L117 | EASY (MEDIUM) | a6e2216719177b44 | White Wolf | 56x56 | 4 | 41.1 | 33.3 | WON_CANONICAL | 18830 |
| L118 | MEDIUM (MEDIUM) | d16245a2bec4e256 | Water Spirit | 56x56 | 8 | 46.6 | 34.1 | WON_CANONICAL | 23192 |
| L119 | EASY (MEDIUM) | b29273bab0485abb | Ember Stag | 56x56 | 6 | 40.8 | 33.8 | WON_CANONICAL | 20737 |
| L120 | VERY_HARD (HARD) | f8c6b626a471cdca | Drill Bot | 56x56 | 6 | 57.1 | 37.7 | WON_CANONICAL | 31280 |
| L121 | EASY (MEDIUM) | a3fc23ab995ab528 | Fire Imp | 56x56 | 5 | 41.1 | 34.0 | WON_CANONICAL | 21990 |
| L122 | EASY (MEDIUM) | f6a6c4c86405448b | Brazier | 56x56 | 6 | 41.0 | 29.0 | WON_CANONICAL | 10426 |
| L123 | MEDIUM (MEDIUM) | 23c362da129d42f0 | Sky Shark | 56x56 | 7 | 46.7 | 34.8 | WON_CANONICAL | 35421 |
| L124 | EASY (MEDIUM) | a868a570fd5c1990 | Dung Beetle | 56x56 | 8 | 41.2 | 27.9 | WON_CANONICAL | 12983 |
| L125 | HARD (HARD) | 1ec76425bc4438b7 | Blue Slime | 56x56 | 6 | 52.1 | 36.8 | WON_CANONICAL | 20693 |
| L126 | EASY (MEDIUM) | f09066badc48b7df | Sprout | 56x56 | 7 | 41.2 | 25.8 | WON_CANONICAL | 11805 |
| L127 | EASY (MEDIUM) | 753409e78071bf2f | Pine Tree | 56x56 | 3 | 41.3 | 29.5 | WON_CANONICAL | 16222 |
| L128 | MEDIUM (MEDIUM) | 57f317706d5e4c8f | Roadrunner | 56x56 | 8 | 46.9 | 27.7 | WON_CANONICAL | 24592 |
| L129 | EASY (MEDIUM) | 61663a3eca477eb0 | Hoopoe | 56x56 | 6 | 41.3 | 27.0 | WON_CANONICAL | 20675 |
| L130 | VERY_HARD (HARD) | 719deda12b0a44e5 | Moss Monster | 56x56 | 7 | 57.5 | 51.7 | WON_CANONICAL | 32460 |
| L131 | EASY (MEDIUM) | 6361f60c2f84855d | Ember Stump | 56x56 | 7 | 41.3 | 27.3 | WON_CANONICAL | 9460 |
| L132 | EASY (MEDIUM) | 8fbb3b7aeb5a5b4e | Spider Bot | 56x56 | 6 | 41.3 | 26.8 | WON_CANONICAL | 21551 |
| L133 | MEDIUM (MEDIUM) | c6912f53e390e716 | Manta Ray | 56x56 | 5 | 47.0 | 33.9 | WON_CANONICAL | 23998 |
| L134 | EASY (MEDIUM) | 7cf92d9bfcadaede | Leafy Sea Dragon | 56x56 | 6 | 41.4 | 32.8 | WON_CANONICAL | 13396 |
| L135 | HARD (HARD) | c0fb86b389153239 | Grim Reaper | 56x56 | 4 | 52.4 | 39.2 | WON_CANONICAL | 33477 |
| L136 | EASY (MEDIUM) | 80894cc3fa9ff312 | Water Serpent | 56x56 | 5 | 41.4 | 34.7 | WON_CANONICAL | 15582 |
| L137 | EASY (MEDIUM) | 10ed0146d324ec80 | Dryad | 56x56 | 4 | 41.4 | 27.7 | WON_CANONICAL (regen) | 15735 |
| L138 | MEDIUM (MEDIUM) | 970972bd4b8d56af | Scrub Racer | 56x56 | 6 | 47.2 | 30.9 | WON_CANONICAL | 22854 |
| L139 | EASY (MEDIUM) | e72a9fd9dc6ae004 | Glow Firefly | 56x56 | 5 | 41.5 | 24.6 | WON_CANONICAL | 10415 |
| L140 | VERY_HARD (HARD) | 497d078d94f2842c | Tank Bot | 56x56 | 7 | 57.8 | 52.1 | WON_CANONICAL | 31353 |
| L141 | EASY (MEDIUM) | cfa6713d37e310e0 | Diving Beetle | 56x56 | 5 | 41.5 | 26.7 | WON_CANONICAL | 20452 |
| L142 | EASY (MEDIUM) | c3c2c9d2189690bd | Red Wasp | 56x56 | 5 | 41.7 | 28.3 | WON_CANONICAL | 17650 |
| L143 | MEDIUM (MEDIUM) | 2c2b477b7656744d | Frost Stag | 56x56 | 9 | 47.3 | 29.5 | WON_CANONICAL | 13856 |
| L144 | EASY (MEDIUM) | b4352af9cc37b2b0 | Swamp Dragon | 56x56 | 5 | 41.8 | 34.0 | WON_CANONICAL | 14186 |
| L145 | HARD (HARD) | 6e0703797aa011b5 | Mushroom | 56x56 | 8 | 52.8 | 43.8 | WON_CANONICAL | 35030 |
| L146 | EASY (MEDIUM) | 0a30a047025c9a18 | Lantern Ghost | 56x56 | 8 | 41.8 | 25.2 | WON_CANONICAL | 23042 |
| L147 | EASY (MEDIUM) | db94d9c10b5cc278 | Flame Lizard | 56x56 | 6 | 41.9 | 28.1 | WON_CANONICAL | 14590 |
| L148 | MEDIUM (MEDIUM) | 6f66b498837cda9e | Blue Jay | 56x56 | 6 | 47.5 | 25.3 | WON_CANONICAL | 37384 |
| L149 | EASY (MEDIUM) | eba9330ed6d84ec1 | Robo Beetle | 56x56 | 7 | 41.9 | 28.9 | WON_CANONICAL | 23545 |
| L150 | VERY_HARD (HARD) | 406505e5f2ec897d | Mimic | 56x56 | 7 | 58.1 | 50.4 | WON_CANONICAL | 33441 |
| L151 | EASY (MEDIUM) | 595cb4b527247e17 | Sunbird | 56x56 | 6 | 42.0 | 31.0 | WON_CANONICAL | 16005 |
| L152 | EASY (MEDIUM) | 565d118858ad25a4 | Night Beetle | 56x56 | 5 | 42.0 | 26.0 | WON_CANONICAL | 9686 |
| L153 | MEDIUM (MEDIUM) | 9829a3fd580cddcf | Glider Fish | 56x56 | 7 | 47.6 | 32.8 | WON_CANONICAL | 38547 |
| L154 | EASY (MEDIUM) | 49c0036495dcf158 | Stalactite | 56x56 | 5 | 42.0 | 33.4 | WON_CANONICAL | 16924 |
| L155 | HARD (HARD) | 9896ea5e5a8204da | Skull Druid | 56x56 | 7 | 53.1 | 42.1 | WON_CANONICAL | 23577 |
| L156 | EASY (MEDIUM) | 660c74d0718c17ab | Sun Spirit | 56x56 | 6 | 42.1 | 29.6 | WON_CANONICAL | 12894 |
| L157 | EASY (MEDIUM) | 6863c14d49beff0a | TV Bot | 56x56 | 9 | 42.1 | 27.0 | WON_CANONICAL (regen) | 13288 |
| L158 | MEDIUM (MEDIUM) | 6742e2640eb1ab90 | Bog Slime | 56x56 | 7 | 47.8 | 34.2 | WON_CANONICAL | 18540 |
| L159 | EASY (MEDIUM) | f2ad7cd91799490a | Swamp Tree | 56x56 | 6 | 42.1 | 26.6 | WON_CANONICAL (regen) | 14835 |
| L160 | VERY_HARD (HARD) | 59c8bd0e55d2539c | Sphinx | 56x56 | 6 | 58.4 | 52.7 | WON_CANONICAL (regen) | 46391 |
| L161 | EASY (MEDIUM) | 64c28231dedffc5a | Radio Bot | 56x56 | 6 | 42.2 | 29.4 | WON_CANONICAL | 18190 |
| L162 | EASY (MEDIUM) | abc354e427cf08a4 | Shadow Mage | 56x56 | 5 | 42.2 | 32.2 | WON_CANONICAL (regen) | 20757 |
| L163 | MEDIUM (MEDIUM) | d05a0d2937b6276b | Grub | 56x56 | 7 | 47.9 | 30.3 | WON_CANONICAL | 34770 |
| L164 | EASY (MEDIUM) | 0ab772688e820dc4 | Tesla Coil | 56x56 | 5 | 42.2 | 29.1 | WON_CANONICAL | 20713 |
| L165 | HARD (HARD) | f51cd6e6ec9cdb95 | Monitor Bot | 56x56 | 8 | 53.4 | 38.3 | WON_CANONICAL | 29007 |
| L166 | EASY (MEDIUM) | b3da60d2daf1d26a | Moss Wolf | 56x56 | 5 | 42.2 | 27.6 | WON_CANONICAL | 21762 |
| L167 | EASY (MEDIUM) | 7063efbbe4f33ccf | Ice Dragonfly | 56x56 | 5 | 42.3 | 28.2 | WON_CANONICAL | 25537 |
| L168 | MEDIUM (MEDIUM) | b5486f273e6af672 | Fire Golem | 56x56 | 7 | 48.1 | 30.1 | WON_CANONICAL | 18074 |
| L169 | EASY (MEDIUM) | 38449bf67d378b1f | Glue Bottle | 56x56 | 3 | 42.4 | 24.1 | WON_CANONICAL | 10827 |
| L170 | VERY_HARD (HARD) | 81a88c8d68884606 | Lamp Bot | 56x56 | 7 | 58.3 | 44.2 | WON_CANONICAL | 34144 |
| L171 | EASY (MEDIUM) | 525aa0d1182c85de | Parrot | 56x56 | 7 | 42.5 | 29.1 | WON_CANONICAL | 26571 |
| L172 | EASY (MEDIUM) | d84ba2c2c8f10df9 | Teal Ghost | 56x56 | 3 | 42.5 | 34.6 | WON_CANONICAL | 17105 |
| L173 | MEDIUM (MEDIUM) | cd67557da421864b | Unicorn | 56x56 | 7 | 48.3 | 27.9 | WON_CANONICAL | 23227 |
| L174 | EASY (MEDIUM) | cc21235280bfe206 | Emerald Beetle | 56x56 | 7 | 42.5 | 29.8 | WON_CANONICAL | 17016 |
| L175 | HARD (HARD) | a1ef8c5e41369813 | Wave Spirit | 56x56 | 7 | 53.8 | 42.1 | WON_CANONICAL | 43295 |
| L176 | EASY (MEDIUM) | 9d69d2b66e922248 | Mandrake | 56x56 | 5 | 42.5 | 27.0 | WON_CANONICAL | 18305 |
| L177 | EASY (MEDIUM) | 3c8edb97a67c42f7 | Harbor Seal | 56x56 | 4 | 42.6 | 33.3 | WON_CANONICAL | 11720 |
| L178 | MEDIUM (MEDIUM) | 45ec7e73b9c07a18 | Mop Bot | 56x56 | 5 | 48.4 | 33.2 | WON_CANONICAL | 14173 |
| L179 | EASY (MEDIUM) | 48aba83cd6e98f2d | Gremlin | 56x56 | 6 | 42.6 | 31.0 | WON_CANONICAL | 22211 |
| L180 | VERY_HARD (HARD) | 68fe92a68965ade8 | Dome Bot | 56x56 | 8 | 59.5 | 45.0 | WON_CANONICAL (regen) | 35181 |
| L181 | EASY (MEDIUM) | 48cf492b4cd935dc | Lightning Spirit | 56x56 | 8 | 42.6 | 31.7 | WON_CANONICAL | 13336 |
| L182 | EASY (MEDIUM) | 45ee8b21de72d637 | Red Demon | 56x56 | 5 | 42.7 | 34.1 | WON_CANONICAL | 22243 |
| L183 | MEDIUM (MEDIUM) | 5926da03eb32d346 | Flower Spirit | 56x56 | 6 | 48.5 | 30.6 | WON_CANONICAL | 28574 |
| L184 | EASY (MEDIUM) | c85da54ce94c5c80 | Cyclops | 56x56 | 3 | 42.7 | 34.4 | WON_CANONICAL | 13935 |
| L185 | HARD (HARD) | f68bf797fa644103 | Washer Bot | 56x56 | 6 | 54.1 | 41.9 | WON_CANONICAL | 31691 |
| L186 | EASY (MEDIUM) | b8e3952cd301e418 | Cactus | 56x56 | 6 | 42.7 | 30.0 | WON_CANONICAL | 29052 |
| L187 | EASY (MEDIUM) | 325a60b00153601e | Pixie | 56x56 | 6 | 42.8 | 33.9 | WON_CANONICAL | 14393 |
| L188 | MEDIUM (MEDIUM) | 265c09ef2fcb3a6f | Jade Scarab | 56x56 | 7 | 48.7 | 30.5 | WON_CANONICAL | 24067 |
| L189 | EASY (MEDIUM) | f01452df88f03c92 | Rock Monster | 56x56 | 3 | 42.9 | 34.1 | WON_CANONICAL | 18672 |
| L190 | VERY_HARD (HARD) | df909d6b2db90381 | Crawler Bot | 56x56 | 7 | 59.5 | 46.1 | WON_CANONICAL | 27426 |
| L191 | EASY (MEDIUM) | 3a824769b50006f9 | Frost Wraith | 56x56 | 6 | 43.0 | 30.5 | WON_CANONICAL | 14813 |
| L192 | EASY (MEDIUM) | fd986ed2b6a7091f | Merman | 56x56 | 5 | 43.2 | 33.1 | WON_CANONICAL | 11656 |
| L193 | MEDIUM (MEDIUM) | 87130d54e9474937 | Spray Bottle | 56x56 | 3 | 48.8 | 23.8 | WON_CANONICAL | 15271 |
| L194 | EASY (MEDIUM) | 26f9388ac3c40605 | Ent | 56x56 | 5 | 43.3 | 33.4 | WON_CANONICAL | 21077 |
| L195 | HARD (HARD) | ec94c4b46c92a929 | Clay Golem | 56x56 | 5 | 54.4 | 42.8 | WON_CANONICAL | 20088 |
| L196 | EASY (MEDIUM) | e4541879eef90f48 | Sea Star | 56x56 | 5 | 43.4 | 31.4 | WON_CANONICAL | 19723 |
| L197 | EASY (MEDIUM) | fe90a6e88a2d4d3f | Eye Bot | 56x56 | 5 | 43.5 | 30.7 | WON_CANONICAL | 15890 |
| L198 | MEDIUM (MEDIUM) | eecd0137cb388522 | Goo Ghoul | 56x56 | 6 | 49.0 | 32.0 | WON_CANONICAL | 26123 |
| L199 | EASY (MEDIUM) | 4c7dbdc458993da8 | Seal | 56x56 | 4 | 43.7 | 30.7 | WON_CANONICAL | 20653 |
| L200 | VERY_HARD (HARD) | f8b09bed55b75dcb | Sea Wyrm | 56x56 | 6 | 59.7 | 53.2 | WON_CANONICAL | 33071 |

All 170 verdicts are WON_CANONICAL on game commit `28741ed18c12e0e4e42523e7af1a0c5b6764453c`.

"(regen)" marks 10 levels: L38, L70, L90, L115, L137, L157, L159, L160, L162 and L180. With the pool's click order they were LOST on current main. `--regen` found a new order of the same clicks (2..235 search nodes of 400), and a fresh `real_play_file` run then gave WON_CANONICAL.

A full re-run of the importer reproduced the same bytes, the same 10 LOST levels, the same search results and the same frame counts.

## Dropped entries
45 picks were rejected, and the next candidate for the slot took their place:

| Reason | Count |
|---|---|
| Failed the real-play gate: L73 Squid was LOST and `--regen` hit SEARCH_BUDGET (400/400). Sentry Eye replaced it and won on the first run. | 1 |
| Looks like a recognisable anime, franchise or real-person character | 17 |
| Stray "Source Error" text in the artwork | 1 |
| Repeats an L1..L30 subject | 4 |
| Same subject within 10 levels | 22 |

| Candidate id prefix | Why dropped |
|---|---|
| 6122508e031af76e | anime character likeness (IP risk) |
| d354b2af19f9b188 | anime character likeness (IP risk) |
| c427d0373b1a4fb9 | real footballer likeness |
| c734914a7d6bcb0a | real footballer likeness |
| 7d496c727cf5b3cf | human sprite resembling a real person |
| 5c78e142644a4ee9 | anime character likeness (IP risk) |
| 9224402d6ebd6614 | anime character likeness (IP risk) |
| f92220a9be17a0a7 | real footballer likeness |
| fd3682abe04a4c3d | resembles a known franchise creature (IP risk) |
| f3a29f9a81534386 | repeats L28 Squirrel |
| 721b92c236afe776 | repeats L12 Ladybug |
| b291317281c7b8a4 | repeats L29 Turtle |
| b99c6d667cc46a88 | beluga repeats L19 Whale |
| 6a8535515c180213 | stag beetle within 10 levels of L34 |
| 8674ed024b8dc621 | crayfish within 10 levels of L37 lobster |
| 478ab08fb70155a4 | stag beetle within 10 levels of L34 |
| 6f2272338967cff5 | deer within 10 levels of L44 |
| 374ed2b7b82da60d | deer within 10 levels of L44 |
| 92271ab434821075 | dragonfly within 10 levels of L57 |
| 2e1df8c52bd8859a | shrimp within 10 levels of L67 |
| b609f0fc7e08839e | jellyfish-like within 10 levels of L66 |
| 9aacb80097f475bf | skeleton back to back with L76 |
| 542c8079737d647e | stag beetle within 10 levels of L84 |
| f070596d2da8b89d | wolf within 10 levels of L83 |
| 12709b4789df441c | dragon back to back with L111 |
| 2f011e189a186c96 | wolf within 10 levels of L139 |
| 2827725ed48192ed | wolf within 10 levels of L139 |
| 26ced78419e4c658 | slime within 10 levels of L158 |
| b4759dc9f34c9c25 | dragon back to back with L166 |
| 5833116c251f83a7 | ghost within 10 levels of L169 |
| bfdfd834d424ae9f | demon back to back with L186 |
| 55a725ec70a72a21 | human sprite resembling a real person |
| 91ea1b03aeb8cdd4 | anime character likeness (IP risk) |
| cc9b629527f6c258 | anime character likeness (IP risk) |
| d602e8d3770d03e4 | anime character likeness (IP risk) |
| 5024a075652dca3f | anime character likeness (IP risk) |
| 2a0a428f91dab23a | franchise character likeness (IP risk) |
| f6bae25acc669413 | resembles a known franchise creature (IP risk) |
| b05d3d45ae562d14 | cricket within 10 levels of L31 |
| cc4719d07bc6c1de | golem within 10 levels of L115 |
| 2d0cdae039696d58 | imp within 10 levels of L122 |
| eef1d9b5df01b248 | phoenix within 10 levels of L152 |
| b4e2d0e3fcaa72e3 | real footballer likeness |
| b403d617272c1ef0 | artwork contains a stray "Source Error" text overlay |
| df723bf978d5f8cf | real-play gate: LOST on current main; --regen search hit the 400-node budget (SEARCH_BUDGET) |

## Size impact
The 170 levels add 4,594,663 bytes raw:

| Part | Size |
|---|---|
| Level JSON | 3.07 MB |
| Supply plans | 1.04 MB |
| Metadata | 0.33 MB |
| Previews | 0.16 MB |

Gzip-compressed per file, which approximates the APK's zip deflate, that is 579,962 bytes.

All of it ships: data/ and previews are exported, while the gate report under tools/ is excluded from export. Previews keep the L11..L30 format: RGBA PNG at the level's logical size, with VOID transparent. Here that size is 56x56, against 32 or 40 for L11..L30. The shipped catalog grows by 1360 lines and the shipped provenance file by 15461 lines.

## Acceptance criteria
1. [x] **Pool schema inspected; every referenced file's sha256 verified.** The importer asserts the sha256 of level, supply_plan, artwork and real_play_result for each entry. Two full imports ran with no assertion failure.
2. [x] **170 distinct entries for L31..L200 follow the cadence.** campaign_l31_l200 `levels` checks class == cadence slot class for every level. EASY and VERY_HARD use a nearest-score fallback. Load stays moderate and neighbours are not near-identical (see Selection).
3. [x] **Real-play gate on current main:** 170/170 WON_CANONICAL. 160 won directly and 10 after a same-click `--regen` reorder; 1 entry was dropped and replaced. Per-level verdict, frames and game commit are in the table and in `tools/real_play_gate_l31_l200.json`.
4. [x] **Imported in the L11..L30 format; the catalog has 200 entries, orders 1..200.** Covered by campaign_l31_l200 `catalog`; m35 passes.
5. [x] **Systems keyed by level number work past L30.**
   - Frontier: L1..L200 resolve in order and 201 is CONTENT_MISSING (campaign_l31_l200 `frontier`, m40, m42_home, m43_c001a).
   - RANKS opens at L40, and worlds_v1 puts L151..L200 in world 2 (campaign_l31_l200).
   - Cadence and the journey strip are computed per level (m37 passes).
   - Feature unlocks (max L40), events (L30), personal ranks (cleared counts) and featured cards are already defined past L30, so no data change was needed.
   - Open owner questions are listed below.
6. [x] **Size impact reported** (above).
7. [x] **Tests:** a new suite with an exact CI guard, and every affected suite passes (below). No APK/IPA build; TASKS.md not edited.

## Validation
All results are LOCAL_PASS on the branch with Godot 4.7.2. The pass rule is the CI rule in `tools/run_suites.py`: exit 0, no SCRIPT ERROR or Parse Error, exact summary line.

| Suite | Result line |
|---|---|
| campaign_l31_l200 | `CAMPAIGN L31-L200 evidence: PASS (5/5 cases, 0 fail)` |
| campaign_l11_l30 | `CAMPAIGN L11-L30 evidence: PASS (5/5 cases, 0 fail)` |
| m35_level_catalog | `M35 level catalog evidence: PASS` |
| m37_level_progression | `M37 level progression evidence: PASS` |
| cp04_remote_content_runtime | `CP04 remote content runtime evidence: PASS (28/28 cases, 0 fail)` |
| cp05_remote_content_cache | `CP05 remote content cache evidence: PASS (15/15 cases, 0 fail)` |
| cp05_r01_transaction_cleanup | `CP05-R01 transaction cleanup evidence: PASS (6/6 cases, 0 fail)` |
| cp06_disabled_levels | `CP06 disabled levels evidence: PASS (16/16 cases, 0 fail)` |
| remote_content_family_fixture | `Remote content family fixture evidence: PASS (0 fail)` |
| m40_v04_bootstrap | `M40 V04 bootstrap evidence: PASS` |
| m42_home | `M42 home evidence: PASS` |
| m43_c001a_results_foundation | `M43-C001A results foundation evidence: PASS (11/11 cases, 0 fail)` |
| m43_personal_ranks | `M43 personal ranks evidence: PASS (8/8 cases, 0 fail)` |
| real_play_levels | `REAL PLAY LEVELS: PASS (4/4 cases, 0 fail)` |
| m55_long_session | `M55 LONG SESSION: PASS` (quiet wait: lap 1 977 ms, lap 2 979 ms) |
| m52_owner_supply_plans | `M52 OWNER SUPPLY PLANS: PASS` (run directly; it is not in the CI loop) |

- **Negative check:** with one gate row's verdict changed to LOST, campaign_l31_l200 printed `FAIL (5/5 cases, 1 fail)`. The file was restored afterwards.
- **Clean tree:** `git diff --cached --check` reported nothing. I reverted project.godot and the .import line-ending churn, and deleted the generated .uid/.import/.translation files by explicit path list (no git stash or git clean). The worktree is clean.

## Owner answers (2026-11-17)
1. 56x56 is OK for L31+; no change.
2. Home area title follows the world name: done (see Summary).
3. IP-like sprites: the pool stays as it is; they are kept out of the game (already skipped).

## Log
### Round 1
- Inspected the new pool layout: the same v1 schema, absolute paths, WON_CANONICAL acceptance and a real_play_result file.
- Built the selection with contact-sheet review. Extended the importer with an l31-l200 batch and a parallel real_play_file gate with a `--regen` fallback.
- Gate runs:
  - Run 1 was cut off by the session restart, and its buffered output was lost.
  - Run 2 found 11 LOST levels. 10 regenerated to WON; L73 Squid hit SEARCH_BUDGET and was replaced by Sentry Eye.
  - Run 3 (with the `cellsSha256` metadata) reproduced everything: 170/170 WON.
- Added the suite and its CI guard, and moved the suites' builtin end from L30 to L200.
- m55 first failed the quiet deadline, because the Home reward flight now plays on Home after L30. Fixed by waiting for the flight to finish.
- Ran the affected suites (all pass) and committed 2418976e.

### Round 2 (rebase + owner answers)
- `git pull --rebase origin main`: no conflicts. The diff on scripts/gameplay between the old base 28741ed1 and the new base 40b38a5f is empty, so the real-play gate was not rerun.
- Added the world-name area title (owner answer 2). The first try used `UiText.data()` directly, and m42_home's localization-seam check failed ("WHISPERING PARK" not routed through the seam). Fixed by passing the name as an argument of the new `HOME_AREA_WORLD` key.
- Reran the suites after the rebase. All are LOCAL_PASS with the exact lines:
  - `CAMPAIGN L31-L200 evidence: PASS (5/5 cases, 0 fail)`
  - `CAMPAIGN L11-L30 evidence: PASS (5/5 cases, 0 fail)`
  - `M35 level catalog evidence: PASS`
  - `M37 level progression evidence: PASS`
  - `CP04 remote content runtime evidence: PASS (28/28 cases, 0 fail)`
  - `CP05 remote content cache evidence: PASS (15/15 cases, 0 fail)`
  - `CP05-R01 transaction cleanup evidence: PASS (6/6 cases, 0 fail)`
  - `CP06 disabled levels evidence: PASS (16/16 cases, 0 fail)`
  - `Remote content family fixture evidence: PASS (0 fail)`
  - `M40 V04 bootstrap evidence: PASS`
  - `M42 home evidence: PASS`
  - `M43-C001A results foundation evidence: PASS (11/11 cases, 0 fail)`
  - `M43 personal ranks evidence: PASS (8/8 cases, 0 fail)`
  - `REAL PLAY LEVELS: PASS (4/4 cases, 0 fail)`
  - `M55 LONG SESSION: PASS`
  - `SB-PHONE-2026-11-12-E win home evidence: PASS (10/10 cases, 0 fail)`
  - `M51 localization readiness evidence: PASS (8/8 cases, 0 fail)`
  - `M60 release gates evidence: PASS (6/6 cases, 0 fail)`
  - m42_home_v04 (not in the CI loop, run directly): exit 0, no SCRIPT ERROR, `m42_home_v04: 18/18 cases, 0 failures`. It includes the new world 1/2 EN/TR label checks and the fit check across the viewport matrix.
- Exceptions: M52 OWNER SUPPLY PLANS was not rerun after the rebase. M43-C001A and the non-Home suites ran after the rebase but before the area-title edit. M42 home, M42 home V04, SB-PHONE-E, M51 and M60 ran on the final code.
- Reverted project.godot and the import churn, removed the generated files by explicit list, and amended to a single commit, 55af903f. The tree is clean.
