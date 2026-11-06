# Review round 1: 121-chaos-tests (single reviewer)

Diff vs origin/main: only tests/m55_player_chaos.gd (new) and TASKS.md (rows flipped DONE/checked). No product file changed. No other test touched, so nothing weakened.

Re-run (my own, `-- <case>`, exit 0, no non-injected SCRIPT ERROR/Parse Error):
- 021_nav_churn: M55 PLAYER CHAOS (31070 ms): PASS
- 018_purchase_reward_spam: M55 PLAYER CHAOS (10992 ms): PASS
- 025_plugin_chaos: M55 PLAYER CHAOS (44848 ms): PASS (3 labelled EXPECTED_FAULT_INJECTION 'explode' errors only; Spark autoload restored assertion present)
- 024_flapping: M55 PLAYER CHAOS (5797 ms): PASS
Not re-run: the full 244 s suite and the other 9 cases (as instructed).

Checks:
- Leak rule (leak_violations / _no_leak): lap 2 must equal lap 1 on nodes and listeners; orphans/tweens must not grow; owned/emitters/decoders must be 0. The built-in self-check bumps each field +1 on the real lap-1 sample and asserts exactly one violation, so it fails on +1 growth. Sound.
- Spam/economy cases assert exact counts (one Heart, one debit, one grant, one provider request), not existence.
- 024 header honestly states there is no network-status seam and flaps only the two real seams (remote content transport, rewarded provider).
- 025 restores the Spark autoload; throw-away saves via boot_save_path_override and injected clock/day only. Import churn from --import was .import files only (reverted in the worktree).
- Suite is local-only (not in CI validate) and documented as such.

Must-fix: none.

VERDICT: PASS
