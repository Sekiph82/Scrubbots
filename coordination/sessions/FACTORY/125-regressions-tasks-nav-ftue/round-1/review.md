# Review round 1 (job 125)

Reproduced locally (import once, then -s each suite, exit 0, no SCRIPT ERROR/Parse Error):
- m54_regression_pack_028_036: `M54 regression pack 028-036: PASS (12/12 cases, 0 fail)`
- m43_c002_c001_popup_modal_pause: `M43-C002-C001 popup / modal / Pause foundation evidence: PASS (23/23 cases, 0 fail)`
(Only the usual "resources still in use at exit" noise.) Tracked .import churn restored; untracked import files remain in the throw-away worktree.

Checks:
- No product code changed: diff is tests, CI yml, TASKS.md only.
- New cases assert real properties against the model: badges vs HomeBadges.compute and the Home pill labels (text and visibility), refused re-claims with wallet unchanged, double pressed.emit gives one stack id, Profile->Achievements LIFO, FTUE seen_steps and charges equal after CloudSave.restore with bootstrap replay, pity count and guarantee, same-source regrant refused, event/first-try/bests across day, relaunch and loss, comeback window with prefs equality, rollback cap. Each ends in a case-ledger plus exact summary line.
- c002 seam: test_unlock_all is set at start and cleared at end; the other assertions are untouched. Fair.
- Throw-away saves under user:// with ticks-suffix, cleaned in _cleanup.
- CI: suite appended to the validate list and the exact-line guard matches the printed line byte for byte.
- 033 claim points to existing c001r/m42 suites; those were not re-run here (not in the requested scope), and no new assertions are claimed.

Non-blocking: c002 and 033 suites remain local-only (not in CI); noted by the builder.

VERDICT: PASS
