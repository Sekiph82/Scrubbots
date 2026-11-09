# Review 141-ads-mock-cadence, round 1

## Checks
- git diff --check: clean.
- m57_ads_cadence 6/6, m57_store_products 9/9, m43_c001a_results_foundation 11/11, m43_c003_c001_acquisition 34/34, m60_release_gates 6/6: all exit 0, no SCRIPT ERROR / Parse Error.
- Cleanup: `git checkout -- .` done. Untracked import files (.uid etc.) left in the worktree; I did not run a broad `git clean` (it would also remove files I did not create). Builder/lead should delete the worktree.

## Answers
1. Count once per finished level: yes. `on_play_finished()` sits after the WON/LOST branches and is guarded by `_economy_terminal_done`, which latches (duplicate terminal returns early at the top) and is reset only on retry/new launch. It runs before `request_save()` in the same terminal, so the counter is saved with the terminal save. Mid-level quit is not a finished level and is not counted (fine).
2. Interstitial only in `_continue_from_results` / `retry_from_results`, after the heart gate. Not mid-level, not over the board. Home does not trigger it (ad stays due).
3. All decisions go through `ads.allowed()` -> `store.ads_allowed(kind)`: interstitial_due, update_banner, facade start_rewarded / start_rewarded_daily.
4. Rewarded: grant path unchanged (RewardedGrantService.resolve); the facade only adds a refusal. No double grant, no new rewards.
5. Test edits: m43_c001a erases only the `ads` section from the compared snapshot; every other economy field is still compared. Legitimate (a finished replay is a play). m43_c003 / r15 / m60 now expect the AdProvider subclass; the old assertion was about "null provider", and m60 additionally checks `ads.get_provider() == rewarded provider`. Legitimate.
6. CI: append-only (one validate-list name at the end, one new guard block with exact `-qxF` 6/6 line, comment line). OK.
7. Privacy inventory lists both new save fields. TASKS rows mark 002 and 009 PARTIAL; 001, 003..008, 010, 011 [x] each says provider-independent.

## Findings
None blocking.

## Notes (non-blocking)
- Queue row `DONE SB-M57-001..011` reads stronger than reality: no real banner/interstitial/rewarded exists until SB-M57-022. The row text does say "provider-independent part", and 022 is READY, so acceptable.
- A WON whose `record_win` is rejected still counts as a play; consistent with "any finished level".
- Interstitial is fire-and-forget (builder noted); AdMob work must wait for the close callback.
- The banner is wired only through the Home ad slot callback; the "bottom of every screen" part is for the real provider (022).

VERDICT: PASS

Must-fix list: none.
