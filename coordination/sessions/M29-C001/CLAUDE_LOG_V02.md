# M29-C001 V02 — Implementation Log (Claude)

Milestone: `M29 — Mobile Touch / Production Input Integration`
Cycle: `M29-C001 V02` — narrow remediation of `F-M29-V01-STRICT-001`
Repository: `Sekiph82/Scrubbots` · branch `main`
Status: **AWAITING_AUDIT**

Prior audit: `coordination/sessions/M29-C001/CHATGPT_AUDIT_V01.md` (CHANGES_REQUIRED)
Implementation SHA: `a20ae1cec72b8c090af071962239638759498540`
Log SHA: this commit (separate, log-only)

## 0. Scope

ONE narrow fix: the production `SlotOriginProvider` ignored the visible slot anchors and
synthesized `board_width/5` lanes. It now derives each routing origin from the ACTUAL
laid-out M28 slot top-center. No other V01 behavior changed.

Git: fast-forward-synced to `origin/main` (which had advanced with owner Economy V1
commits), rebased this narrow fix on top cleanly (no conflicts — the fix touches only
`slot_origin_provider.gd`, `production_gameplay_host.gd` and tests; the Economy V1
comment-only edits to the speed/screen files were preserved). No `reset --hard` / force.
Owner-local `project.godot` and untracked owner assets preserved. Root `TASKS.md` not
modified.

## 1. The fix (F-M29-V01-STRICT-001)

`scripts/gameplay/runtime/slot_origin_provider.gd` — `origin_for_slot(i)` now returns:

```
global_anchor      = FiveSlotStrip.get_slot_anchor_global(i)      # visible slot top-center
board_local_origin = BoardPresentation.global_to_board_local(global_anchor)
origin_for_slot(i) = board_local_origin
```

- queries the CURRENT laid-out geometry every call — no cached screen coordinate, so it
  follows responsive relayout;
- NO synthetic `board_width/5` fallback remains as production authority;
- fails closed (returns `Vector2(INF, INF)` → `RouteRequest` fails → no robot) for an
  out-of-range slot, a missing/dead strip or presentation, or a non-finite mapped origin.

`scripts/gameplay/runtime/production_gameplay_host.gd` — a plain `Control` does not size
its `Control` children, so the host now anchors/sizes the `GameplayScreen` to its own
rect on build and on every host/viewport resize (`_fit_screen`), so the visible slot
anchors resolve to real board-local geometry and the origins track layout.

Nothing else changed: input gate, mouse/touch dedup, rapid/multitouch, pause/focus,
cadence, speed authority, auto-2x, and the M23–M27 engines are byte-for-byte the accepted
V01 behavior.

## 2. Direct evidence — exact visible origins

`tests/m29_exact_slot_origin_evidence.gd` (new):
- **§1** all five origins equal `presentation.global_to_board_local(strip.get_slot_anchor_global(i))`
  within `1e-4` at 1080×2160; every origin is finite and below the board bottom; origins
  differ from the old synthetic lanes.
- **§2** after resizing the viewport to 1440×3200 and relaying out, origins still equal
  the recomputed visible mapping AND have moved (no stale cached screen coordinate).
- **§3** fail-closed: out-of-range slot (`-1`, `5`), null presentation+strip, missing
  strip, missing presentation all return non-finite.
- **§4** the route from a visible origin has route point 0 == that exact origin and is
  `RouteValidator`-clean (M22 Railroad V1/V07 — no diagonal/corner-cut/teleport), still
  reaching the canonical BOTTOM rail.

Measured origins (1080×2160, cell 41): x ∈ {−0.62, 4.68, 9.99, 15.29, 20.61}, y = 25.50
— the real visible slots, below the board (h=20) and outer rail (h+3). After 1440×3200:
y = 28.36, x shifted, proving dynamic tracking.

## 3. Real Hazard Bot with the exact visible origins

`tests/m29_hazard_bot_runtime_smoke.gd` re-run with the real laid-out origins and the
deterministic solved column-drain order:
- 400 authenticated clears;
- final ACTIVE = 0;
- no ghost robot (dispatcher active == scheduler live claims every tick);
- no duplicate live target;
- M23 fully exhausted;
- automatic 2x after the final successful transfer;
- 1x vs 2x truth equivalence (identical clears/final board; 2x completes in fewer ticks).

## 4. Exact Godot manual run instructions (F6)

1. Open the project in Godot **4.7.2** (graphical): project path `C:\Users\sekip\Desktop\ScrubBots`
   (the folder containing `project.godot`).
2. FileSystem dock → open `res://scenes/debug/m29_hazard_bot_playtest.tscn`.
3. Press **F6** (Run Current Scene). Not F5 — the project main scene is unchanged.
4. You see the production M28 gameplay screen: the 20×20 Hazard Bot board + rail, the five
   read-only slots, three supply columns (front + two preview rows), boosters, and the
   bottom row `Pause | Ad | 1x`.
5. Click a **front (top) supply tile** of a column (mouse or touch). Only the front row is
   clickable. Each placed batch drops into the rightmost EMPTY slot and a Scrubbot travels
   from directly under that visible slot, along the rail, to a matching cell, clears it,
   and disappears. Robots keep dispatching automatically.
6. Bottom-right control toggles **1x ⇄ 2x** (cadence + travel). Bottom-left **Pause**
   freezes cadence + in-flight robots; the selected speed is preserved on resume.
7. **To fully clear the board and see automatic 2x**, transfer the fronts in this
   deterministic solved order (owner-facing, 1-based columns left→right):

   `1,1,1,1,1,1,1,2,2,2,2,2,2,3,3,3,3,3,3`

   (Column 1 seven times, then column 2 six times, then column 3 six times — placing the
   next as a slot frees up.) When the final batch is transferred, gameplay auto-switches
   to `2x`; the board finishes clearing to empty (BG01).

   Engineering/zero-based equivalent (as used in the smoke): `0,0,0,0,0,0,0,1,1,1,1,1,1,2,2,2,2,2,2`.

8. **M30 limitation:** there is intentionally NO win/lose/result screen yet — the board
   simply becomes empty when cleared.

Headless reproduction of the same fully-cleared production run:
```
godot --headless --path . -s res://tests/m29_hazard_bot_runtime_smoke.gd
```

## 5. Regression evidence (Godot 4.7.2, headless unless noted)

```
godot --headless --path . -s res://tests/run_tests.gd                              -> exit 0 (full root suite PASS)
godot --headless --path . -s res://tests/m29_input_gate_evidence.gd                -> PASS
godot --headless --path . -s res://tests/m29_speed_authority_evidence.gd           -> PASS
godot --headless --path . -s res://tests/m29_exact_slot_origin_evidence.gd         -> PASS (new)
godot --headless --path . -s res://tests/m29_hazard_bot_runtime_smoke.gd           -> PASS (400 clears, final 0, auto-2x, no ghost/dup)
godot --headless --path . -s res://tests/m28_gameplay_layout_smoke.gd              -> PASS
godot --headless --path . -s res://tests/m27_hazard_bot_solve.gd                   -> PASS
godot --headless --path . -s res://tests/m27_scale_59.gd                           -> PASS
godot --headless --path . -s res://tests/m27_generation_retry.gd                   -> PASS
godot --headless --path . -s res://tests/m26_hazard_bot_integration.gd             -> PASS
godot --headless --path . -s res://tests/m26_scale_59_sanity.gd                    -> PASS
godot --headless --path . -s res://tests/m25_v03_exact_work_binding_evidence.gd    -> PASS
godot --headless --path . -s res://tests/m24_v02_transaction_hardening_evidence.gd -> PASS
godot --headless --path . -s res://tests/m23_v03_transaction_identity_evidence.gd  -> PASS
godot --headless --path . -s res://tests/m22_railroad_responsive_smoke.gd          -> PASS
godot --headless --path . -s res://tests/m22_v03_connector_evidence.gd             -> PASS
godot --headless --path . -s res://tests/m22_v06_real_demo_state_evidence.gd       -> PASS
godot --headless --path . -s res://tests/m20_v10_lifecycle_smoke.gd                -> PASS
git diff --check                                                                   -> clean
```
M19 dispatcher / M18 agent regressions are covered inside the full root suite.

## 6. Governance

- Root `TASKS.md` unchanged by Claude.
- No M30 implemented; no synthetic origin fallback reintroduced.
- Accepted V01 input/pause/cadence/1x-2x/auto-2x behavior and M23–M27 engines preserved.
- Zero AI image-generation credits.
- Implementation commit precedes this separate log commit.
