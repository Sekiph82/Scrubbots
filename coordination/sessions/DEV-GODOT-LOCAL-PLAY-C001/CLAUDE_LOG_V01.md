# SB-DEV-GODOT-001 — Local Godot playable sync + owner M50 decisions A/B — CLAUDE_LOG_V01

Prompt: `coordination/autonomy/SCRUBBOTS_CLAUDE_GODOT_LOCAL_PLAYABLE_SYNC_V01.md` · 2026-10-15 · Builder: Claude Code (autonomous V02).
This is an evidence log, not a tracker. Reviews are `CLAUDE_PEER_REVIEW` (fresh-context Claude subagent), **not** ChatGPT audits.

**Status: `READY_FOR_OWNER_F5_CHECK`.** Technical CI PASS (see CI). Owner visual sign-off for the symbol appearance and the navy PLAY label is still **OPEN**. This is not an OWNER_PLAY_PASS and not a device test.

## Sync / owner state
- `origin/main` at start: `6a26db69`. Desktop was fast-forwarded to it (ff-only; no owner edit was overwritten).
- Task commits:
  - `4cbaa556`: feature.
  - `43d7e2a2`: peer-review remedial (CI-validated).
  - A follow-up commit: round-2 peer-review shape fixes + these logs. It is **not CI-validated yet**; it rides the next planned run.
- Desktop checkout == `origin/main` after each push.
- Owner-dirty state preserved, never staged:
  - `project.godot` (SHA-256 unchanged `d2546c0b…63574`, mtime still 2026-10-09);
  - `scenes/app/main.tscn`;
  - `tests/tools/owner_review/premium_pack_owner_review.tscn` and `standard_pack_owner_review.tscn`;
  - all untracked files;
  - 2 stashes.
- No reset / clean / stash / force-push / worktree / clone.

## Godot on this laptop
- **Godot 4.7.2.stable.official.ed1daf0bf is installed** (winget):
  - `C:\Users\sekip\AppData\Local\Microsoft\WinGet\Links\godot.exe`
  - → `...\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.7.2-stable_win64.exe`
  - **Correction:** earlier logs and peer reviews said "no local Godot". That was wrong: those sessions only checked `PATH`.
- The project-local import cache `.godot/` already existed from the owner's Editor (newest file 2026-10-09). Since then, no production imported asset (png / svg / ttf / wav …) outside `coordination/` has changed. The new symbols are drawn in code, so no re-import is needed.
- **Editor / F5 itself: NOT_RUN.** I did not open the owner's Editor or press F5, because F5 boots with the owner's real save under `user://`.
  - Instead I ran a windowed (real GPU) script, `tests/tools/m50_symbol_capture.gd`. It instantiates the production `scenes/app/main.tscn` with a throw-away save path and drives **Home → PLAY → L1 gameplay**. Both reached the real screens with no script errors.
  - It also renders the real `GameplayScreen` on the L3 / L5 palettes and a 16-colour legend.
  - The JPG captures were viewed and then deleted.
  - Local headless runs of the suites listed below also passed.
- **Owner F5 route:** open `C:\Users\sekip\Desktop\ScrubBots\project.godot` in Godot 4.7.2 → **F5 (Run Project)** → Home → PLAY.

## Decision A — per-colour symbols (SB-M50-002)
- `scripts/ui/color_symbols.gd`: maps the exact colour to its Palette V3 C-ID, then to a shape. It never uses the level-local `color_id` index; for example, brown C11 sits at local index 3, 4 or 7 depending on the level, and the test asserts it.
- **Shipped identities:** 15 (C01–C08, C10–C16). C09 is mapped but not shipped yet.

| C-ID | colour | shape | C-ID | colour | shape |
|---|---|---|---|---|---|
| C01 | Orange Red | triangle | C09 | Periwinkle | cross |
| C02 | Orange | circle | C10 | Pink | heart |
| C03 | Yellow | star | C11 | Brown | lightning bolt |
| C04 | Green | diamond | C12 | Pale Yellow | down-triangle |
| C05 | Light Teal | hollow square | C13 | Light Gray | hourglass |
| C06 | Light Blue | T shape | C14 | Dark Gray | three dots |
| C07 | Blue | plus | C15 | White | arrow |
| C08 | Dark Blue | half-disc | C16 | Black | chevron |

- **Shape distinctness** is measured on rasterised unit masks:
  - all 120 pairs IoU < 0.75 (max 0.71, diamond / half-disc);
  - the M50 CVD-confusable pairs: C01 / C11 0.42, C04 / C05 0.18, C02 / C03 0.45 (all < 0.5);
  - **with the 2-digit count band hidden** (the part a player actually sees around the digits): all pairs IoU < 0.7 (max 0.61).
  - Rejected during development by these tests or by peer review:
    - circle / hexagon 0.93 and circle / square 0.84;
    - ring and bullseye vs circle (they differ only under the count);
    - horizontal or vertical bars vs hollow square (0.92 / 0.76 with the count hidden);
    - teardrop vs triangle 0.78.
- **Presentation** (after peer-review remedial): a translucent watermark at 80 % of the face's short side, centred **behind** the count.
  - Dark ink on light faces, light ink on dark faces; the weakest watermark-vs-face contrast is C10 at 1.53:1.
  - The count label, its centring, the tile size and the hit areas are unchanged. The symbol is input-transparent.
  - **Why not a corner emblem:** the first candidate (top-left corner, sized to clear the digits) measured only **~13 px** on production 5-column supply faces (93×79 at 1080×2160). That is not legible on a phone. The watermark is ≥ 34.6 px on every tested viewport.
- **Coverage:**
  - every occupied Batch Supply front + preview tile and every 5/6 slot tile (the shared `ColorBatchTile`);
  - Tornado colour chips (outlined emblem, no number);
  - Selector chips (watermark under a count Label).
  - Empty / WAITING-empty / non-canonical tiles show nothing.
- **Board:** no per-cell symbols, to protect 59×59 performance (3,481 cells) and because they would be illegible at that size. Board colour identity is recorded as an open owner-design constraint; a possible keyed cue would be "highlight matching cells while a tile is held". It is not built, so no mechanic is invented here.
- **Owner visual sign-off: OPEN.** Specific points to look at:
  - 3-digit counts cover more of the watermark;
  - symbols sit over the top highlight band;
  - the ▶ triangle on the PLAY button stays white.

## Decision B — navy PLAY label (SB-M50-004)
- `HomeStyle.style_play_label_navy`, applied only to the Home `PlayButton`:
  - NAVY text on the unchanged green body;
  - a thin pale-green rim (6 px) replaces the dark 12 px outline.
- Popup and Results green buttons keep white labels (tested).
- **Measured WCAG contrast:**
  - normal **7.35:1**;
  - hover **9.04:1**;
  - pressed **5.31:1**;
  - disabled 3.61:1 (reported; WCAG exempts inactive controls).
- A real-GPU render of the Home screen was viewed. Owner visual sign-off is OPEN.

## M51 row 001 follow-up
- `gameplay_screen.gd` booster price now uses `UiText.t("BOOSTER_PRICE_SB", [UiText.num(price)])`.
- English is unchanged for the current prices (350–750 → "350 SB"). Prices ≥ 1,000 are grouped ("1,500 SB"). The label follows the pseudo-locale.

## Tests
- `tests/m50_color_symbols.gd`: **10 cases**
  - s01: table == palette file;
  - s02: every shipped level palette;
  - s03: silhouettes;
  - s04: tile placement / draw order / centred count / empty / non-canonical / contrast;
  - s05: 3/4/5 columns × 5/6 slots at 1080×2160 (two palette orders), 720×1280, 1440×3200 and 1536×2048, minimum symbol ≥ 32 px;
  - s06: real L1 via `main.tscn` + hit rects ≥ 88;
  - s07: PLAY states;
  - s08: HUD price;
  - s09: cost + no board symbols;
  - s10: Tornado / Selector chips.
- `tests/m50_accessibility_audit.gd` a02 now reports the navy label instead of the white-fill finding.
- Workflow `.github/workflows/android-family-first10.yml`: 43 suites, exact `M50S` 10/10 guard. Added suites:
  - `m50_color_symbols`;
  - tile regression `m28_c002_c004_tile_visual`;
  - HUD regression `m28_c002_c001_gameplay_v02`;
  - touch regression `m47_touch_r01_mobile_ux`;
  - chips regression `m43_c003_c001_acquisition`.
- 59×59: symbols exist only on the ≤ 21 tiles and ≤ 12 chips. The board renderer is untouched, and s09 asserts no symbol node outside the tiles.

## CI (1 planned + 1 remedial; budget used)
| Run | SHA | Result |
|---|---|---|
| [38788244223](https://github.com/Sekiph82/Scrubbots/actions/runs/38788244223) | `4cbaa556` | **42/42 PASS**. validate job 116605749763 = success; export job 116611892668 = skipped. Artifact `11998897765`: 44 log files, no apk / pck / ipa. `import script_diag=0`. M50S 9/9, M28 tile 17/17, M28 gameplay 14/14, M47 touch 14/14, M44 23/23, CP06 16/16, M49 8/8, M50 4/4, M51 4/4. |
| [38790518157](https://github.com/Sekiph82/Scrubbots/actions/runs/38790518157) | `43d7e2a2` | **REMEDIAL, 43/43 PASS**. validate job 116613562196 = success; export job 116620435917 = skipped. Artifact `11999284614`: 45 log files, no apk / pck / ipa. `import script_diag=0`. M50S 10/10 (smallest symbol 34.6 px, 17 chips), acquisition 34/34, all exact guards PASS. |
| next planned run | follow-up | The C06 / C11 / C15 shape swap + count-masked s03 check. Local headless 10/10 only; **not CI-validated in this milestone** (budget used). |

## Peer review
`coordination/sessions/M50-ACCESSIBILITY-C001/CLAUDE_PEER_REVIEW_M50_DECISIONS_V01.md`: two rounds, both PASS_WITH_MINOR_DEFECTS.
- Round 1: 2 Med fixed (chips without symbols; the compact-size gap, which exposed the 13 px emblem).
- Round 2: 1 Med fixed (circle-like outlines hidden by the count) in the follow-up commit.

## Process notes (disclosed)
- Two python-in-bash edits wrote a literal `\n` into the workflow loop; I caught and fixed both before any commit.
- One heredoc and two `sed -i` edits were used; their `.m50bak` backups were deleted at once.
- Local GPU / headless Godot runs wrote only:
  - throw-away `user://m50*` saves and JPGs (≤ 0.9 MB in total), deleted and checked;
  - no new `.godot` import.

## Next
1. Owner: F5 check and visual sign-off for the symbols and the navy PLAY label.
2. Autonomous V02 next milestone: **M46 Performance** (SB-M46-001..015), consolidating the existing 59×59 evidence (M25 / M26 / M27 / M31 / M32 / M55) into budgeted per-subsystem measurements.
