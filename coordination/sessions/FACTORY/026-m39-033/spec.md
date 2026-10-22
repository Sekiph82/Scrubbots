# SB-M39-033 sixth-slot layout and safe-area evidence (verify-close)

> Feature: SB-M39-033 — sixth-slot (+1 Slot) presentation/layout support with mobile safe-area evidence; no 7+ slot state

## Context
This is already implemented and tested on main. The job is verification and tracker closure. It needs no new code.

- Capacity authority: `scripts/economy/slot_capacity_authority.gd`. `MAX := 6`, +1 Slot is allowed once per attempt, and a new attempt resets capacity to 5.
- Engine: `scripts/gameplay/slots/five_slot_batch_engine.gd` has `grow_to_sixth()`.
- Presentation: `scripts/ui/gameplay_screen.gd`.
  - It selects the shell `"<cap>slot_<cols>col"` for capacity 5 or 6 and supply columns 3, 4 or 5.
  - It uses `SafeAreaRoot` and `get_safe_rect()`.
- Existing tests:
  - `tests/m39_v02_capacity.gd` covers 6 slots and refuses a 7th.
  - `tests/m28_c002_c002_static_shell.gd` covers:
    - shell selection for 3/4/5 columns x 5/6 capacity;
    - 6 overlays on 6 baked frames for each column count;
    - the 7-device `MATRIX` aspect-fit inside the safe rect;
    - a synthetic notch (141) and gesture bar (102).
  - `tests/m49_responsive_matrix.gd` has case `m05_sixth_slot_matrix` and `m07_popups_deeplinks_notch`. They run on 8 physical viewports with synthetic `NOTCH [0,132,0,96]`.
  - `tests/m50_color_symbols.gd` s05 checks 5 and 6 slots.
  - `tests/m46_performance.gd` p17 checks that the sixth slot is occupied, shown and dispatching, and that a 7th is refused.
- TASKS.md notes (lines about V04 audit) say only "real-phone sixth-slot safe-area/touch/readability" evidence remains. Under CLAUDE.md §0D.1 all pending owner visual and phone sign-offs are GIVEN. The device gate is therefore ordinary open work, satisfied by the emulated-matrix evidence above.

## Requirements
1. Run the suites below on the job branch. Do not change source unless a suite fails. If one fails, fix the minimal root cause and rerun.
2. Close SB-M39-033 in TASKS.md. Remove or tick the READY queue row at line ~26 and the checkbox at line ~997. Cite the suites and PASS lines as the evidence. Label it `LOCAL_PASS` plus factory peer review. Do not claim a real-phone test.
3. Add one line to the tracker noting that §0D.1 grants the phone sign-off and that safe-area coverage is the synthetic-inset matrix.
4. Change no other files. AGENTS.md needs no update because there is no behaviour change. Check with grep that it has no stale "SB-M39-033 pending" claim, and fix it only if it does.

## Acceptance criteria
Replace `$GODOT` with the Godot 4.7.2 path. Each command must exit 0 and print the line shown.
1. `"$GODOT" --headless --path <worktree> -s res://tests/m39_v02_capacity.gd` prints `M39 V02 capacity evidence: PASS`. Evidence that a 7th slot is refused is the `cannot grow past 6 (never 7+)` check.
2. `"$GODOT" --path <worktree> -s res://tests/m28_c002_c002_static_shell.gd` prints `M28-C002-C002 static master shell evidence: PASS (N/N cases, 0 fail)`. Use a non-headless run if the suite needs rendering.
3. `"$GODOT" --path <worktree> -s res://tests/m49_responsive_matrix.gd` prints `M49 responsive matrix evidence: PASS (8/8 cases, 0 fail)`. This includes `m05_sixth_slot_matrix` and `m07_popups_deeplinks_notch`.
4. `"$GODOT" --path <worktree> -s res://tests/m50_color_symbols.gd` prints a PASS line with 0 failures.
5. `grep -rnE "MAX *:= *6" scripts/economy/slot_capacity_authority.gd` matches. `grep -rnE "slot_count *[=>]+ *7|capacity *[=>]+ *7" scripts` finds no 7+ state.
6. `git diff main --stat` shows only TASKS.md, plus the factory evidence files.
7. TASKS.md no longer lists SB-M39-033 as READY or unchecked, and the closure line cites the suites above.

## Out of scope
- Adding any 7+ slot state or any new booster or mechanic.
- Changing layout, art or shell masters.
- Real-device capture. §0D.1 waives it.
- Editing other tasks' rows.

## Assumptions
- The synthetic-inset matrix (m28 shell, m49 NOTCH) counts as "mobile safe-area evidence". Reason: the code is already audited and §0D gives the phone sign-off.
- If m50 or m46 PASS-line wording differs, the builder accepts the suite's own all-pass line with 0 failures.
- The worktree did not exist when this spec was written. The code was read from the owner checkout at origin/main, so the builder must re-confirm the file paths in the worktree.
