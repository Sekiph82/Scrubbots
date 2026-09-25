# SB-M42 HOME MASTER CONVERGENCE V02 — Claude implementation log

Status: **AWAITING_CHATGPT_AUDIT** (implementer log; no self-audit, no owner visual acceptance claimed)

Prompt: `coordination/sessions/M42-C001/task_prompts/SB-M42-HOME-MASTER-CONVERGENCE_V02.md`
Criteria: `coordination/sessions/M42-C001/audit_criteria/SB-M42-HOME-MASTER-CONVERGENCE_V02.md`
Register: `coordination/sessions/M42-C001/SB-M42-HOME-MASTER_ACTUAL_VISUAL_GAP_REGISTER_V01.md`

## Commits

| Role | SHA |
|---|---|
| Baseline HEAD (synced `origin/main`) | `2592ac7` |
| Owner comparison reference (committed unchanged) | `ca49c28` |
| Implementation + tests + snapshot harness | `7377a2f` |
| Snapshot evidence + 222 ledger (final implementation SHA) | `da0cf81` |
| This log | follow-up commit |

## Reference image

`assets/art/references/_owner_inbox/master - actual differences.png` — 2025x1507, 3,938,538 B,
SHA-256 `307afe800ce1fdf6c67e91613611c7acae0ce7e34db13ace29344fe732ae1b29`, committed byte-identical.
Canonical master: `assets/art/references/_owner_inbox/Game Screens/main screen.png` (887x1774). Neither is loaded by
the shipping Home (asserted by `m42_home` layered_art_regions).

## Vision status

**VISION_INSPECTION_CONFIRMED.** Images were inspected directly (comparison, master, baseline, three post-change
iterations).

Baseline observations (runtime before V02, `home_baseline_before_1080x2160.png`): huge empty sky band; top HUD a
thin text strip; Gift Meter a plain caption line; no arch/area header; Scrubby small, floating, platform ring crossing
the torso; shortcuts thin translucent rows with clipped labels (WIN STR… / COLLECT… / CARDS EXC…); PLAY plain text on
pavement; reward track faint text chips; bottom nav text-only, no dock/icons.

## Snapshot iterations

Harness: `tests/tools/home_snapshot.gd` (windowed rendering; deterministic temp-save state; temp save deleted).

1. `home_iter1_1080x2160.png` — first composition pass. Issues seen: right-column badges clipped by the screen edge,
   reward-track SB icons too small, CARDS EXCHANGE label tight.
2. Iteration 2 (1080x2160 / 1290x2796 / 1080x1920) — badge moved inside card corner, icons 46 px, label 26 px.
   Issue seen: on the tall phone the arch floated above while the platform sat low (hero base disconnected from arch).
3. Iteration 3/4 — arch base anchored to the platform middle on every aspect, arch height grows with stage.
   Final: `home_final_1080x2160.png`, `home_final_1290x2796.png`, `home_final_1080x1920.png`, `home_final_1536x2048.png`.

Remaining visible differences vs master (honest): Scrubby pose is the approved wave pose, not the master's action
pose (item 49, BLOCKED_WITH_PROOF); background is the approved futuristic skyline, not the master's detailed alley
(item 65, BLOCKED_WITH_PROOF); on very tall phones (1290x2796) some sky remains above the arch crown; tablet
(1536x2048) shows more city width around the arch.

## Changed files

- `scripts/ui/home/home_screen.gd` — master composition (HUD profile card + chips + menu, Gift Meter band, WorldStage
  with arch/decor/area banner/platform/Scrubby/props/helpers/idle states, card shortcuts, green CTA + subtitle +
  play icon, reward track panel, nav dock); `get_presentation_accounting()`, `set_idle_state()`; card height computed
  from layout minus other regions (no min-size feedback loop). All existing APIs kept (bind/refresh/popups/
  get_region/get_view_model/get_launch_preview/set_art_binder/open_popup/close_top_popup, `SettingsButton`).
- `scripts/ui/home/home_style.gd` (new) — native StyleBox/Theme visual language.
- `scripts/ui/home/home_presentation_map.gd` (new) — presentation map (below).
- `scripts/ui/components/ui_shortcut_button.gd` — card (top icon, wrapping untrimmed label, corner badge).
- `scripts/ui/components/ui_value_chip.gd` — `set_icon_size/set_panel_style/set_value_size`.
- `scripts/ui/ui_text.gd` — keys `HOME_START_LEVEL`, `HOME_PLAYER_NAME_DEFAULT`, `HOME_AREA_TITLE`, `HOME_AREA_NUMBER`.
- `tests/m42_home_composition.gd` (new, 13 cases); `tests/m42_home.gd` (updated expectations);
  `tests/tools/home_snapshot.gd` (new harness).
- Evidence PNGs under `coordination/sessions/M42-C001/runtime_evidence/home_master_convergence/`.

## Semantic adaptations (not literal master copying)

Scrub Bucks banknote chip (no coin/star); Bot Parts N/250 profile bar (not XP); Gift Meter with live progress/next
milestone (no Event Points, no event timer); CARDS EXCHANGE (not STAR EXCHANGE); Win Streak track +1/+5/+10/+25/+100
SB from WinStreakService; PLAY subtitle from the canonical frontier (LEVEL N / CONTINUE · LEVEL N, no hardcoded 329);
all labels/values live Godot text through UiText; no text baked into art; master screenshot never shipped.
Area title/number and default player name are localizable presentation defaults (no canonical area/profile-name
state exists); rank/title node stays hidden (item 11, PRESERVED_V1).

## Presentation map (50 APPROVED entries → nodes)

47 STATIC, 2 STATE, 1 REUSE (asserted by `m42_home_composition` accounting_covers_manifest / static_nodes_presented).

- Background: HOME-001..004 → `Layer_background.sky/city_far/city_mid/street_foreground`.
- World: HOME-006 `Art_arch`, 007 `Art_arch_decor`, 010 `Art_platform_main`, 011 `Art_platform_top`, 013 `Art_bucket`,
  014 `Art_hose`, 015 `Art_foam`, 016 `Art_puddles`, 018 `Art_wet_floor_sign`, 019 `Art_keep_clean_sign`,
  020 `Art_cleaning_equipment`, 021 `Art_neon`.
- Characters: HOME-022 `Art_helper_floor`, 023 `Art_helper_cart`, 024 `Art_helper_alt`, 026 `Art_scrubby`;
  STATE: 031 `ScrubbyBlink` (idle_blink), 032 `ScrubbyBrushArm` (idle_scrub).
- Profile: 027 `ProfilePortrait`, 034 `ProfileAvatarFrame`, 035 `ProfileRankBadge`.
- HUD: 042 `ScrubBucksChip` icon, 043 `HeartsChip` icon.
- Gift Meter: 051 `GiftEmblem`, 054 `GiftCrate`.
- Shortcuts: 062..069 → `Shortcut_*` button icons.
- CTA: 078 `PlayIcon` (child of native `PlayButton`).
- Track: 086 `TrackBadge`, 090..094 `TrackGift1..5`, REUSE 087 (= HOME-042 file) → `TrackStep1..5` chip icons.
- Nav: 101..105 → `NavIcon_events/robots/home/leaderboard/settings`.

## Approved blob proof

`promote.py verify` against the V02 baseline `blobs_before.json`: **verified rows: 49 errors: 0** (all 49 unique
approved PNGs byte-identical, sha pins match). `git diff --stat -- '*.png'` for approved paths: empty. No approved
PNG overwritten/recompressed/moved; manifest untouched; validator untouched. No candidate generated
(no authorized generator used) → nothing under `assets/ui/generated/` added by this pass.

## 222 ledger

`coordination/sessions/M42-C001/task_logs/SB-M42-HOME-222-COMPLETION-LEDGER.md` — 222 rows.

**219 FIXED / 1 PRESERVED_V1 / 0 ASSET_CANDIDATE_OWNER_REVIEW_REQUIRED / 2 BLOCKED_WITH_PROOF**

- PRESERVED_V1: 11 (rank/title — no canonical source; node hidden).
- BLOCKED_WITH_PROOF: 49 (master action pose ≠ approved HOME-026 wave pose; needs new owner-approved art),
  65 (master alley density ≠ approved skyline background layers; needs new owner-approved background art).

## Viewport matrix

`m42_home_composition` responsive_matrix: 1080x2160, 1170x2532, 1290x2796, 1080x2400, 1440x3200, 1080x1920,
1536x2048 — key regions inside viewport, ≥88 px, no card/CTA overlap, hero inside world. `m42_home`
components_viewport_matrix additionally covers each size with synthetic safe-area insets (0,132,0,96).

## Tests (headless, current tree = `7377a2f` code)

| Suite | Result | SCRIPT ERROR | engine ERROR (excl. exit-leak notice) |
|---|---|---|---|
| `tests/m42_home_composition.gd` | 13/13 cases, 0 failures, exit 0 | 0 | 0 |
| `tests/m42_home.gd` | 19/19 PASS, exit 0 | 0 | 0 |
| `tests/m42_assets.gd` | 4/4 PASS, exit 0 | 0 | 0 |
| `tests/m42_navigation.gd` | 12/12 PASS, exit 0 | 0 | 0 |
| `tests/m42_opening.gd` | 8/8 PASS, exit 0 | 0 | 0 |
| `tests/run_tests.gd` (root) | Total checks 5322, RESULT: ALL PASS, exit 0 | 0 | 8 (pre-existing intentional corrupt-PNG importer fixtures, = baseline) |

Exit-time "resources still in use" notices are pre-existing harness teardown noise (excluded as in prior logs).
`git diff --check`: clean (only LF→CRLF notices). Headless `project.godot` churn: none present at commit.

## Untouched

Root `TASKS.md`, owner approval/decision files, ChatGPT prompt/criteria/audit files, `HOME_ASSET_MANIFEST.json`,
all approved art, audio. No force push.

Final handoff: `AWAITING_CHATGPT_AUDIT / M42 HOME MASTER CONVERGENCE V02`
