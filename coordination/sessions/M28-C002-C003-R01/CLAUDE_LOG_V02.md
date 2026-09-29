# M28-C002-C003-R01 — CLAUDE LOG V02

Date: 2026-09-29
Prompt: `coordination/sessions/M28-C002-C003-R01/CHATGPT_PROMPT_V02.md` (supersedes V01)
Criteria: `coordination/sessions/M28-C002-C003-R01/CHATGPT_AUDIT_CRITERIA_V02.md`
Matrix: `REMEDIATION_MATRIX_V02.md`
Status: **AWAITING_CHATGPT_AUDIT**

## Sync / governance

- Repo `Sekiph82/Scrubbots`, branch `main`.
- **Starting commit:** `77d623a`, fast-forwarded from `7a6a56a` with no conflict.
- **Final commit:** the one that adds this log. Its SHA is in the hand-off, because a file cannot contain its own id.
- Root `TASKS.md` was read only. **It was not edited.**
- **Read:**
  - `CLAUDE.md`, `TASKS.md`;
  - the V02 prompt and criteria;
  - `OWNER_TIMED_2X_CROSS_LEVEL_RUNTIME_V01`;
  - `M28-C002-C003/OWNER_GAMEPLAY_V02_FINAL_GATE_V01` and `CHATGPT_AUDIT_V01`;
  - the host, speed, entitlement, routing, rail geometry, renderer, slot view and Home code.
- **Preserved and not committed:**
  - the local `project.godot` modification;
  - untracked owner media and caches;
  - `tests/_m55_diag_tmp.gd`.
- **Committed owner file:** `assets/ui/final/home/background/home_background.png`. It was untracked, and the prompt requires Home to use it. It is committed byte-for-byte (sha256 `9d5db29513d25ad5c0932840c08027be0198d0cd85dc758a69e09e800c7aabe2`, 940×1672).

## Production changes

| Finding | File | Change |
|---|---|---|
| 1 timed 2x | `scripts/gameplay/runtime/production_gameplay_host.gd` | `_apply_default_speed()` runs in `build()` and on Retry restore; an active timed entitlement makes the attempt start at 2x, with runtime and HUD set together. `_paid_2x` + `_drop_expired_paid_2x()` on the HUD tick: an expired paid 2x drops mid-level, but never while the free M23 auto-2x owns the speed. |
| 1 | `scripts/gameplay/runtime/gameplay_speed_authority.gd` | Header comment only (the host applies the timed default). |
| 2 slot text | `scripts/ui/batch_slot_view.gd` | State label is always empty (no WAITING/ACTIVE words). It reserves the words' measured box so slot origins and anchors are unchanged. WAITING gets a muted thin rim, ACTIVE keeps the cyan border. Adds a `get_state_text()` accessor. |
| 3 railway-first | `scripts/gameplay/routing/production_routing_system.gd` | `INTERIOR_STEP_COST = 1000.0` gives a lexicographic Dijkstra: fewest board steps first, then rail distance, then the unchanged side tie-break. `interior_step_cost` is an instance variable; `TOTAL_TRAVEL_COST = 1.0` keeps the audited equal weight. |
| 3 (truth pinned) | `scripts/gameplay/solver/proof_kernel.gd`, `scripts/difficulty/level_difficulty_analyzer_v1.gd`, `level_difficulty_analyzer_v2_candidate.gd` | Use `TOTAL_TRAVEL_COST`, so solver and difficulty measurements are exactly as audited (see Regression). |
| 4 grid/bevel | `scripts/gameplay/board/board_pixel_grid.gdshader` (new), `scripts/gameplay/board/board_renderer.gd` | One ShaderMaterial on the existing renderer TextureRect. `grid_size` = real dimensions. Strength scales with density over 20..59. CLEARED stays fully transparent. `set_grid_enabled` / `get_grid_material` for tests. |
| 5 Home bg | `assets/ui/HOME_ASSET_MANIFEST.json` | + HOME-121 `home_background_whispering_park` (APPROVED, sha-pinned). |
| 5 | `data/config/home_worlds_v1.json` | `world_01` → the new slug, canvas 940×1672, re-measured anchors and rects. |
| 5 | `scripts/ui/home/home_presentation_map.gd` | HOME-121 STATIC on `WorldBackground`; HOME-120 OWNER_RETIRED (file kept byte-identical). |
| 5 | `scripts/ui/home/home_screen.gd` | `PLATFORM_BOTTOM_Y` / `SIGN_TOP_Y` / `HERO_SHADE_RECT` for the new canvas; default canvas arg. Transform algorithm unchanged. |

## Tests

**New:**
- `tests/m28_c002_c003_r01_remediation.gd`: **PASS, 24/24 cases.** Covers all 12 prompt-required items plus extras: mid-level expiry, Retry, blocked exit, corner targets, and a no-node-explosion check.
- `tests/tools/board_grid_probe.gd` (GPU): **PASS on 6 dimensions.**
  - gutters on cell boundaries within ±1 px;
  - cell cores keep the exact palette colour;
  - 0 ghost pixels on cleared cells with the grid ON;
  - grid on/off differ only inside ACTIVE cells.
- Evidence tools: `tests/tools/route_compare_snapshot.gd`, `tests/tools/gameplay_v02_r01_motion_capture.gd`.

**Updated because they froze the old Home world** (asserted properties kept; only the frozen values moved):
- `m42_assets`, `m42_home`, `m42_home_composition`: manifest counts +1, HOME-120 now OWNER_RETIRED.
- `m42_home_v04`: world path, sha, canvas, anchor, slug. The "promoted from owner inbox" check is replaced by "the retired HOME-120 file still exists".
- `m42_home_v05`, `m42_home_v06`, `m42_home_v07_safe_area`: re-baselined world-transform tables (14 viewport × inset rows each) and anchor numbers. The same suites still independently check touch targets, PLAY below the platform, the sign below the Gift Meter, and uniform scale.

## Regression

Final run: Godot 4.7.2 headless, 12-way parallel, all 114 `tests/*.gd` except the untracked `_m55_diag_tmp.gd`.

**Result: 112 exit 0.**

- Root `tests/run_tests.gd`: **Total checks 5323, ALL PASS.**
- **Focused and required suites (all PASS):**
  - R01 V02 24/24;
  - M28:
    - C003 final gate 22/22;
    - C001 14/14;
    - static shell 16/16;
    - R01 10/10;
    - layout smoke.
  - M29: all 7 suites (input, speed authority, presentation identity, slot display sync, ...).
  - M30: completion, retry, manual smoke.
  - M39: A–E, V02–V04, including `m39_v04_integration` (PASS this run; its known clock-boundary flake is described in the M28-C002-C003 log).
  - M40: all.
  - M41, and M42 (all 11 suites).
  - M43: C001A, C001B, C002 23/23, C003 34/34.
  - M52: supply plans, R01, R02.
  - M55: all 5.
  - Routing, clearing and solver: M16–M27 suites, M22 railroad, M25 claims, M26, M27 solve / scale 59, M53 difficulty.

**Non-zero exits:** `m21_v08_corridor_validation` (C/043, C/047) and `m21_v09_direct_evidence_reconciliation` (B). These failures are **identical** to the historical pre-Railroad-V1 baseline reported in the last two cycles.

**Other checks:**
- `SCRIPT ERROR` appears only in the `m20_v04/v05/v07/v08` lifecycle assertion-name baseline.
- `git diff --check` is clean.

**Issues found and fixed during this cycle** (reported for transparency):

1. **Slot label.** My first slot-label change (hiding the label) shifted slot anchors, which broke `m29_presentation_identity_evidence` and `m52_r02_early_slot_release`. I bisected it to that change and fixed it by reserving the words' measured box. Both suites pass.
2. **Difficulty evidence drift.**
   - The first full run showed `m53_first10_difficulty` and `m53_c002_difficulty_calibration` failing "fresh run == committed raw evidence".
   - Cause: the analyzer measures route length through `ProofKernel`'s routing, so `lastWaveMaxRoute` and `routes/*` changed under the railway-first cost.
   - Fix: pin `ProofKernel` and both analyzers to `TOTAL_TRAVEL_COST`. Committed Difficulty V1 evidence is byte-stable again and both suites pass.
   - Reachability and targetability are cost-independent: the same legal graph is searched, and only the choice among legal paths changes. The live-host identity case `r06` proves identical target, claim and clear sets between the two costs.

## Evidence

All under `coordination/sessions/M28-C002-C003-R01/evidence/`.

**Timed 2x on a new level:**
- `motion_r01_v02_timed2x_rail_flow_720x1440.mp4`: **real video**, Godot Movie Maker, 32.5 s. Flow: Home (new background) → PLAY → L1 at 1x → buy 15 min → L1 fast-forwarded to WON (labelled in the caption) → Results → Continue → **L2 starts live 2x with the countdown running** → free 1x → back to 2x.
  - The caption shows the live factor and the timed remaining time.
  - L1 was fast-forwarded to WON for the recording, and this is stated in the caption.
- `motion_r01_v02_contact_sheet_1fps.png`, `motion_r01_v02_timeline.txt`
- `r01_timed_2x_new_level_L2_frame_1080x2160.png`

**Slot row without words:**
- `r01_gameplay_L1_20x20_grid_slots_no_labels_1080x2160.png`
- `r01_gameplay_L2_32x32_grid_slots_no_labels_1080x2160.png`
- `r01_gameplay_L3_38x38_grid_slots_no_labels_1080x2160.png`
- `r01_gameplay_sixth_slot_no_labels_1080x2160.png`

**Railway-first:**
- `route_compare_open_40x40_slot_left.png` / `_slot_right.png`: board travel 37 vs 300 cells (left slot) and 37 vs 182 cells (right slot).
- `route_compare_blocked_exit_30x30.png`
- `motion_r01_v02_rail_frames_L2.png`
- the video

**Grid / bevel:**
- `grid_{20x20_cs30,24x32_cs24,38x38_cs16,59x59_cs12,20x59_cs14,59x20_cs14}.png`, each with a `_zoom.png`.
- The gameplay stills above.
- `r01_gameplay_L3_short_phone_1080x1920.png`, `r01_gameplay_L1_tablet_1536x2048.png`.

**Home:** `r01_home_{1080x2160,1170x2532,1290x2796,1080x1920,1536x2048}.png`

## Notes / deviations

1. **Home anchors re-measured by me.** The new image has a different composition from the retired 1080×2160 world. I re-measured the Scrubby feet and safe box, the sign, the platform row, the two baked helper bots, and the hero-shade rect from the image itself. These are presentation numbers only; the owner should confirm Scrubby's size and position in the replay.
2. **Wide / short screens.** The existing V04 mirrored side-band mechanism still fills the extra width. The new image's outermost columns are dark, so the mirror seam reads as a thin line (visible in the tablet and short-phone shots). I did not change the mechanism; it is an owner review item.
3. **Railway rule wording.** `OWNER_SCRUBBOT_RAILROAD_INTERIOR_PATH_DECISION_V01` describes "minimum total legal cost". The runtime now uses railway-first lexicographic cost per owner finding 3. I did not edit the decision file; ChatGPT or the owner may want to record the superseding rule.
4. **No owner item is self-approved.**

## Owner replay required

1. **Timed 2x across a level transition, and after an app relaunch.**
2. **Slot row without WAITING / ACTIVE** (five and six slots).
3. **Railway-first motion.**
4. **Grid / bevel readability** on small, medium and large levels.
5. **Home with `home_background.png`**, including Scrubby placement and the side bands on tablet / short phone.

## Reproduce

Focused suite:

```bash
godot --headless --path . -s res://tests/m28_c002_c003_r01_remediation.gd
```

Grid probe (GPU):

```bash
godot --path . -s res://tests/tools/board_grid_probe.gd -- <out>
```

Route comparison images:

```bash
godot --headless --path . -s res://tests/tools/route_compare_snapshot.gd -- <out>
```

Motion capture:

```bash
godot --path . --write-movie out.avi --fixed-fps 30 --resolution 720x1440 -s res://tests/tools/gameplay_v02_r01_motion_capture.gd
```

`AWAITING_CHATGPT_AUDIT / M28-C002-C003-R01 FIVE-FINDING REMEDIATION V02`
