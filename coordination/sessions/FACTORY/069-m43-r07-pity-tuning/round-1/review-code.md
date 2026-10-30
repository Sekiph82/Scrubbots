VERDICT: PASS

## Checks
git diff --check origin/main...HEAD: pass (clean)
m43_master_c007r_pity (headless): pass, 11/11 cases, 0 fail (matches the CI exact-summary string)
m43_c005_c008_pack_commit_transaction: pass, 27/27
m39a_economy_core: pass
m43_master_c007_collection: pass, 19/19
Worktree git status after the runs: clean (no import noise to revert)
Sim spot-run: skipped (optional)

## Findings
None.

## Notes
- Sprint mode is derived on every call from `inventory.is_set_complete(1)`, with no stored flag. It switches off permanently once Set 1 is owned, and it is correct after a save import or a legacy save. The counter save/load schema is unchanged (strict `{version, count}`), so there is no save migration.
- `_apply_earned` computes `focus` before the cards are added. The card that completes Set 1 therefore counts as new and resets the counter. No RNG is consumed by the guarantee: it only swaps the last drawn card, and only when it is due and no new card was drawn. The p09 no-drift test still passes.
- The Premium card 0 is preserved: the swap needs `drawn.size() > keep_from`.
- Config: malformed `threshold` or `first_sprint_threshold` values go through `IntDomain.nonneg_int` and fall back to 0, so the guarantee is disabled (fail closed). The extra `tuning` string key is harmless.
- `guaranteed_next` is a plain alias of `guarantee_due`. This is acceptable because the UI copy uses it.
- Atomic commit and rollback are covered by p07 and the C008 transaction suite, both green.
