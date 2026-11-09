# Review round 1: 144-ci-red-m55-m39e

## Checks
- git diff --check 1e9c5bf3..HEAD: pass (clean)
- m55_long_session: PASS (exit 0, 0 SCRIPT ERROR). "ok: freed app root releases AppState / EconomyServices / StoreService". STEADY lap2-vs-lap1 nodes +0, orphans +0, objects +39, static_mem +802756 B.
- m39e_full_matrix: PASS
- m40_save_system: PASS
- m40_v04_bootstrap: PASS
- m57_store_products: PASS 9/9
- m60_release_gates: PASS 6/6 (the "FAIL SB-M60-006" line is a gate verdict, not a test failure)
- Worktree restored (checkout, import files removed, status empty).

## Findings
1. main.gd PREDELETE dispose: safe.
   - It only calls `reward.release_handlers()` -> `_handlers.clear()`. It is idempotent, so a double dispose is harmless.
   - `app_state` is created per root (main.gd:130, `AppState.new`), not an autoload. Disposing it cannot affect a later root.
   - Quit order is fine. WM_CLOSE_REQUEST runs `flush_lifecycle("close_request")` (the save) before the node is freed and PREDELETE fires. PREDELETE only runs on free.
   - The only risk is a grant arriving after the root is freed, which is not a realistic path.
2. The new m55 weakref assert does test the release. It holds weakrefs to AppState, economy and store across `root.free()` plus one frame. A surviving cycle would keep them alive and fail the assert. The builder did not prove that it fails without the fix. This is non-blocking, since the 36/boot -> 0 probe plus the +70 -> +39 drift give indirect evidence.
3. m39e whole-word walk: correct.
   - It recursively walks dict keys and string values and lowercases them.
   - `(^|_)stars?(_|$)` matches top-level `star` and `stars`, `star_currency` and `Gold_Stars`, and it excludes `week_start`, `restart` and `started`.
   - The event_points and profile_xp / xp_bar rules are kept.
   - Positive and negative self-checks are present for all three rules.
   - Not caught: camelCase `starCount` and hyphenated `star-currency`. Neither convention exists in this snapshot. Non-blocking.
4. The lap drift of +39 is under 64. `MAX_OBJECT_DRIFT` is unchanged (64). The +39 shows the leak is only reduced, not zero. The builder attributes it to the harness. Non-blocking.

## Notes
- The m39e test scans only snapshot keys and string values. That is the same coverage as before, but stricter than a plain substring.
- Commit messages are short one-liners. TASKS.md has one queue line. The scope is minimal.

Must-fix list: none.

VERDICT: PASS
