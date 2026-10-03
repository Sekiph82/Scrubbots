# M43-C005-C004 — CLAUDE LOG V01 — Owner-Approved Booster-of-Your-Choice Asset Intake

Date: 2026-10-03/04
Implementer: Claude (Opus 5.5)
Parent task: SB-M43-076
Status: **AWAITING_AUDIT** (implementation evidence E1/E2 only; no audit verdict claimed)

## Inputs read

- Prompt: https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M43-C005-C004/CHATGPT_PROMPT_V01.md
- Owner decision: `coordination/sessions/M43-C005-C004/OWNER_BOOSTER_CHOICE_DECISION_V01.md`
- `CLAUDE.md`, root `TASKS.md` (read only, **not edited**), `coordination/AUDIT_POLICY.md`
- Prior audit: https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M43-C005-C003/CHATGPT_AUDIT_V01.md (C004 must represent selection among the four canonical boosters, no fifth booster/economy key)
- C001 history: `CEREMONY_ASSET_INVENTORY_V01.md`, `OWNER_VISUAL_DECISION_V02.md` (temporary native "?" chip not the desired production asset)
- `assets/ui/VISUAL_ASSET_INDEX.md`

Learnings applied: AL "file existence is not evidence" (render + direct row assertions), "never fabricate owner art" (exact bytes only, hash-gated), sensitivity check for the new assertion.

## Sync

- Repo `Sekiph82/Scrubbots`, branch `main`. Local was 9 behind `origin/main` (c6615ff → 17bc0e4).
- `git merge --ff-only origin/main` — clean fast-forward; no conflicts with local work.
- Pre-existing owner/local work preserved and **not committed**: `M project.godot`, untracked `.mcp.json`, `addons/`, `*.import`, `*.uid`, level source PNGs, `assets/ui/final/rewards/reward_chest.png`, `assets/ui/final/common/icons/icon_timer_clock.png`, `assets/ui/final/characters/scrubby/scrubby_master.png.png`, etc.

## 1. Source location and identity

Searched `*choice*.png` under `Desktop\ScrubBots`, `Desktop`, `Downloads`, hashing each hit. Exactly one hit:

```
65CDB2D4F99EB0CD00ADB91CC930F355EC4234F674D4FC2E8E41907326A203AF  670138  C:\Users\sekip\Downloads\booster of your choice.png
```

Matches the owner-approved SHA-256 → no `BLOCKED_OWNER_BOOSTER_CHOICE_ASSET_NOT_FOUND`.

## 2. Promotion (byte-exact)

```
cp "/c/Users/sekip/Downloads/booster of your choice.png" assets/ui/final/rewards/booster_of_choice.png
sha256sum <src> <dst>
cmp <src> <dst> && echo BYTE_IDENTICAL
```

| | SHA-256 | bytes |
|---|---|---|
| source | `65cdb2d4f99eb0cd00adb91cc930f355ec4234f674d4fc2e8e41907326a203af` | 670,138 |
| destination | `65cdb2d4f99eb0cd00adb91cc930f355ec4234f674d4fc2e8e41907326a203af` | 670,138 |

`cmp` → `BYTE_IDENTICAL`. PIL: `(1024, 1024) RGBA`; alpha 0 = 156,093 px, partial = 326,474, 255 = 566,009 → transparency retained. No decode/re-encode, image generation or edit of any kind.

Expected: identical hash, 1024×1024 RGBA, alpha<255 present. Failure condition: any hash/dimension/mode mismatch or no transparent pixels. Result: **CLAUDE_TEST_PASS**.

## 3. Integration changes

| File | Change |
|---|---|
| `assets/ui/final/rewards/booster_of_choice.png` | new, exact owner bytes |
| `tests/tools/ceremony_preview/ceremony_candidates.gd` (preview harness, not shipping) | `ART["booster_choice"]` added; `REWARD_ROWS.selected_booster_charges` icon `""` → `"booster_choice"`; the `"?"` chip fallback branch in `_reward_rows` removed (every row now has final art). Labels/amounts unchanged. |
| `tests/m43_c005_c001_ceremony_visual_masters.gd` | c08: new direct assertion — Gift 500 and 1000, normal + Reduced Effects, `Row_selected_booster_charges/Icon.texture.resource_path == res://assets/ui/final/rewards/booster_of_choice.png` and no `"?"` Label in the row. c16: the old "missing art = selected_booster_charges" expectation replaced by "no reward row lacks art; booster row → booster_of_choice.png". |
| `tests/tools/ceremony_preview/ceremony_snapshot.gd` | adds `gift_500` fixture/shots (REF, Reduced Effects, viewport matrix), Reduced Effects shot for `gift_1000`, optional `key,key` filter arg. |
| `assets/ui/VISUAL_ASSET_INDEX.md` | rewards section 8 → 9 with the new row; integration note on meaning + SHA + "not a fifth booster". |
| `coordination/sessions/M43-C005-C001/CEREMONY_ASSET_INVENTORY_V01.md` | appended "Resolved by M43-C005-C004" note under §5 item 1 (historical C001 table rows left as-is). |
| `coordination/sessions/M43-C005-C004/BOOSTER_CHOICE_ASSET_MANIFEST_V01.json` | new manifest |
| `coordination/sessions/M43-C005-C004/evidence/*` | 12 renders + row zoom + size sheet |

Not touched: `data/`, `scripts/` (no shipping code), economy config, save keys, Gift reward truth, booster sources, Collection cards, Standard/Premium pack assets, root `TASKS.md`. No SB-M43-063..075/077 runtime work, no M43-C005F plugin work.

Known documentation note: the index's top "Audit summary" counts (469 production files, etc.) predate C002/C003 additions (current `assets/ui/final` image count is 543 incl. this file and pre-existing untracked owner files). They were not recomputed in this cycle; only the rewards section was updated.

## 4. Validation

All runs Godot 4.7.2.stable.official.ed1daf0bf. `godot --headless --path . --import` run first (rc=0, imported `booster_of_choice.png`).

| # | Command | Expected / failure condition | Result |
|---|---|---|---|
| V1 | hash/cmp/PIL (above) | identical SHA, 1024×1024 RGBA, alpha present | **PASS** |
| V2 | `sha256sum assets/ui/final/boosters/{extra_slot,random,selector,tornado}.png` vs pre-change baseline | no diff | **PASS** `BOOSTERS_UNCHANGED` |
| V3 | `sha256sum` of 135 `collection/cards/set_*/card_*.png` vs baseline; `git diff --quiet f17d28a -- assets/ui/final/collection/cards` | no diff, exit 0 | **PASS** 135/135, identical to f17d28a tree |
| V4 | `python tools/validate_m43_c005_pack_assets.py` | all frozen pack frames unchanged | **PASS** "all 12 frozen frame hashes unchanged" (rc=0; regenerated `PACK_ASSET_MANIFEST_V01.json` byte-identical, no git change) |
| V5 | `git status --porcelain data scripts` (excluding pre-existing untracked `.uid` caches) + diff inspection | no tracked change under `data/`/`scripts/` | **PASS** — no fifth booster/economy/save key; config boosters remain `plus_one_slot, random, selector, tornado` |
| V6 | `godot --headless --path . -s res://tests/m43_c005_c001_ceremony_visual_masters.gd` | 17/17, 0 fail; new Gift 500/1000 icon assertion ok | **PASS 17/17, 0 fail**; `["500:booster_of_choice.png", "500R:booster_of_choice.png", "1000:booster_of_choice.png", "1000R:booster_of_choice.png"]` |
| V7 | Sensitivity: temporarily set `selected_booster_charges` icon to `random_booster`, rerun V6, restore | new assertions must FAIL for the intended reason | **FAIL as intended** (rc=1, 2 fail: Gift row shows `random.png` ×4; c16 mapping check). Harness restored; SHA `11d83886…` equal to pre-mutation backup. |
| V8 | Reduced Effects parity — V6 c14 + pixel diff of evidence renders | labels/actions identical; rows identical | **PASS** c14 ok. Pixel diff normal vs reduced: Gift 500 none; Gift 1000 only bbox (347,653)-(726,1036) = spinning hero glow, above the reward rows |
| V9 | `godot --path . -s res://tests/tools/ceremony_preview/ceremony_snapshot.gd -- coordination/sessions/M43-C005-C004/evidence gift_500,gift_1000` (rendering driver) | 12 snapshots, 0 REJECTED (frame in safe area, text fits) | **PASS** 12 SNAPSHOT, 0 REJECTED; visually inspected 500@1080×1920 and 1000@1080×2160 — icon in row, no "?" chip |
| V10 | Economy/booster invariants: `m39a_economy_core`, `m39c_boosters`, `m55_economy_release_regression` | PASS | **PASS** ×3 |
| V11 | M43 regression: c001a 11/11, c001b 11/11, c001r 40/40, c002 23/23, c003 34/34, c004 40/40, c005 17/17 | all PASS | **PASS** all |
| V12 | Root suite `godot --headless --path . -s res://tests/run_tests.gd` | ALL PASS | **PASS** Total checks 5323, RESULT: ALL PASS |
| V13 | `git diff --check` | clean | **PASS** |

Full 128-file top-level sweep not re-run: the change touches only a preview harness, its test, a snapshot tool, docs and one new PNG (no shipping code), so root suite + economy + all M43 tests were run.

## 5. Evidence

`coordination/sessions/M43-C005-C004/evidence/`:
- `gift_500_*` / `gift_1000_*` at 1080×1920, 1080×2160, 1170×2532, 1290×2796, 1536×2048, plus `_reduced_effects_1080x2160`;
- `gift_1000_booster_choice_row_zoom.png` — row crop (2× nearest);
- `icon_mobile_sizes_contact_sheet.png` — icon at 32/48/64/68/72/88/96/128/192 px on BG01, row cream and white (LANCZOS downsample for evidence only; the asset is untouched). Row icon size in harness: 68 px (Gift rows, row_h 76).

## 6. False-positive risks

- Harness is preview-only; production ceremony runtime (SB-M43-063..075/077) does not exist yet, so "Gift reward preview uses the approved icon" is proven in the harness, not in a shipping screen.
- V6's c08 icon check reads `resource_path`; V9 renders and visual inspection cover actual pixels.

## 7. Blockers

None.

## 8. Commit / push

Recorded in the handoff response (commit SHA after push to `origin/main`).
