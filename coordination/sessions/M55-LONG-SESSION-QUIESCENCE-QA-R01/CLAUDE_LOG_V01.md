# M55-LONG-SESSION-QUIESCENCE-QA-R01 — CLAUDE_LOG_V01

- Prompt: `coordination/sessions/M55-LONG-SESSION-QUIESCENCE-QA-R01/CHATGPT_PROMPT_V01.md`
- Criteria: `coordination/sessions/M55-LONG-SESSION-QUIESCENCE-QA-R01/CHATGPT_AUDIT_CRITERIA_V01.md`
- Defect source: `coordination/sessions/M47-FAMILY-APK-C001/M47_FAMILY_APK_C001_CLAUDE_LOG_V02.md` §5.2 (independently reviewed in `M47_FAMILY_APK_C001_CHATGPT_INDEPENDENT_AUDIT_V01.md`)
- Engine: Godot 4.7.2.stable.official.ed1daf0bf
- Starting SHA: `17b15598e2fc7a2ab37e8cbe58edf5958261225a` (`origin/main`)
- Final SHA: the commit that adds this log together with the test change. Parity is reported in the hand-off.
- **Changed files: `tests/m55_long_session.gd` (test only) and this log.** No production, feel, Android, R2, `project.godot` or `TASKS.md` change.

Status: **AWAITING_AUDIT** (I am not self-awarding PASS).

## 0. Preflight (owner Desktop)

| Item | Value |
|---|---|
| Branch / upstream | `main` / `origin/main` |
| Desktop HEAD at start | `0692b463` |
| `origin/main` after `git -C "C:\Users\sekip\Desktop\ScrubBots" fetch --prune origin` | `17b15598` |
| Ahead / behind | 0 / 5 |
| Dirty tracked files | `project.godot`, `scenes/app/main.tscn`, `tests/tools/owner_review/premium_pack_owner_review.tscn`, `tests/tools/owner_review/standard_pack_owner_review.tscn` |
| Untracked | 2616 |
| Stashes / worktrees | 2 / 5 (Desktop + 3 Codex + 1 older Claude scratch; all untouched) |
| Owner `project.godot` SHA-256 | `d2546c0bb7d3daccce6c803252a2bf72ddd2359ee1e61abcaa02ca2b98e63574` |

Reconcile:
- The 5 incoming commits were `TASKS.md`, `ios-ipa.yml`, the M47 audit and this prompt / criteria. None overlapped a dirty file.
- `git merge --ff-only origin/main` → `17b15598`, **0/0**, hash unchanged. Nothing was stashed, reset, cleaned or restored.

TEMP worktree:
- **One** bounded worktree under the session scratchpad: `git -C "<Desktop>" worktree add --detach --no-checkout`.
- Sparse (`MSYS_NO_PATHCONV=1`): `/*`, `!/coordination/sessions/`, `!/assets/art/references/`, `!/assets/ui/candidates/`, `!/assets/ui/generated/`. This session folder was added later only to write this log.
- Every command used absolute `git -C "<TEMP>"` / `godot --path "<TEMP>"` paths.
- **One** `--import`. It rewrote the TEMP `project.godot`, which was restored with `git -C "<TEMP>" checkout -- project.godot`; the Desktop was never touched.

## 1. Defect reproduction at the starting SHA (unmodified test)

Fourth independent local reproduction: `godot --headless --path <TEMP> -s res://tests/m55_long_session.gd` at `17b15598`, test unmodified.

| | Lap 1 | Lap 2 |
|---|---|---|
| `feel quiescent at the HOME sample` | **FAIL** (waited 26 ms) | **FAIL** (waited 22 ms) |
| Warm-up Node delta | **+35** `{ "AppRoot": 35 }` | — |
| Steady lap 2 vs lap 1 | — | nodes +0, orphans +0, objects +58, static +462,764 B |
| Result | `M55 LONG SESSION: FAIL (2)` | |

This matches the 2026-10-10 M47 record: 3/3 local FAIL with waits of 15–24 ms and +35 nodes, while GitHub Actions run 38040561355 passed.

**Mechanism:**
1. `nav.go(RESULTS → HOME)` triggers `request_home_ceremonies()`, which is deferred.
2. The Gift-10 ceremony is shown, and MetaRewardFeel starts its **static layout-settle coroutine** (up to `SETTLE_FRAMES = 8` frames) **before** it asks the FeedbackAdapter for the REWARD burst.
3. While that coroutine is pending, `feel.owned_count()` is 0.
4. The old loop (`while owned_count() > 0`) therefore exited at once ("waited ≈ 20 ms" = the two settle frames).
5. The burst became owned right after, so the final assertion failed and its emitter was counted as the 35th Node.

## 2. Code change (only `tests/m55_long_session.gd`)

`git diff --stat`: 1 file, +85 / −6.

1. **Header** explains the race: the pending coroutine runs before adapter ownership, so quiescence is a streak, not a single reading.
2. Added `const MetaRewardFeel = preload("res://scripts/ui/feel/meta_reward_feel.gd")` and `const QUIET_DEADLINE_MS := 5000`.
3. **`quiet_frames_required()`** returns `MetaRewardFeel.SETTLE_FRAMES + 3`, i.e. **strictly more than SETTLE_FRAMES + 2** (currently 11). It is tied to the production constant: no magic sleep, no frame-rate or millisecond assumption.
4. **`quiet_streak_step(streak, owned)`** is the pure rule: `streak + 1` if `owned == 0`, otherwise `0`. Any owned decoration resets the streak.
5. **`quiet_release_frame(trace)`** replays an owned-count trace through the same rule and returns the release frame, or −1.
6. **`_await_feel_quiet(root)`**:
   - **one** `t0` and one monotonic `QUIET_DEADLINE_MS` deadline for the whole wait; a reset never extends it;
   - each frame applies `quiet_streak_step`;
   - returns `{quiet, ms, frames, streak, resets}`.
7. **Lap-end sampling:**
   - `q := await _await_feel_quiet(root)`;
   - diagnostic `QUIET lap N: waited … ms, … frames, final quiet streak …, streak resets …`;
   - **new explicit FAIL on timeout**: `_ok(q["quiet"], "feel quiet streak … reached inside the 5000 ms deadline")`;
   - then the **original** `await _settle()` (2 frames);
   - then the **original** final assertion `_ok(root.feel.owned_count() == 0, "feel quiescent at the HOME sample …")`.
8. **New case `015_quiet_rule_sensitivity`** (added to `EXPECTED_CASES`, run after case 014). It feeds traces through the real rule:
   - required streak is `SETTLE_FRAMES + 3` and strictly more than `SETTLE_FRAMES + 2`;
   - **early-quiet gap**: `SETTLE_FRAMES + 2` zero frames, then 6 owned frames, then a full streak. It releases only at the last frame (frame 26); the gap can never release the snapshot;
   - `quiet_streak_step(req-1, 1) == 0`: any owned frame resets the streak;
   - two zero runs each one frame short, split by an owned frame → −1 (no release → deadline FAIL);
   - 400 owned frames → −1 (never quiet → FAIL);
   - boundary: `req − 1` zero frames → −1; `req` zero frames → release.

**Unchanged** (no changed diff line mentions any of these):
- `MAX_OBJECT_DRIFT = 64`, `MAX_STATIC_MEM_DRIFT = 4 * 1024 * 1024`;
- the transition-churn checks;
- the lap-1 warm-up recording;
- `steady_state_violations()`;
- case 014;
- the lap-2 strict check and the final steady-state assertions;
- the orphan, listener, root-child and host rules.

No tolerated extra Node was added. No production file was touched: `meta_reward_feel.gd`, `feedback_adapter.gd`, assets, `project.godot`, R2, the M47 workflow, game source / data / scenes and Level Factory are all unchanged.

## 3. Verification (final code, TEMP worktree, same machine that exposed the race)

`git diff --check`: clean. The changed-file set is exactly `tests/m55_long_session.gd` (+ this log). The script parses in Godot 4.7.2: every run reports `Parse Error` 0.

### 3.1 `tests/m55_long_session.gd`: three fresh consecutive complete runs

Command: `godot --headless --path <TEMP> -s res://tests/m55_long_session.gd`. No retries, nothing substituted.

| Run | Exit | Result | Lap 1 quiet wait (ms / frames / streak / resets) | Lap 2 quiet wait | Warm-up Node delta | Steady lap 2 vs lap 1: nodes / orphans / objects / static | SCRIPT ERROR / Parse / freed-instance warning |
|---|---|---|---|---|---|---|---|
| 1 | 0 | **PASS** | 782 / 93 / 11 / 0 | 785 / 92 / 11 / 0 | **+34** `{AppRoot: 34}` | +0 / +0 / +58 / +461,612 B | 0 / 0 / 0 |
| 2 | 0 | **PASS** | 788 / 93 / 11 / 0 | 778 / 112 / 11 / 0 | **+34** `{AppRoot: 34}` | +0 / +0 / +58 / +462,764 B | 0 / 0 / 0 |
| 3 | 0 | **PASS** | 775 / 93 / 11 / 0 | 783 / 93 / 11 / 0 | **+34** `{AppRoot: 34}` | +0 / +0 / +58 / +462,764 B | 0 / 0 / 0 |

**3/3 PASS.** Every run printed `ok` for:
- case 014: nodes ±1, orphans +1, objects ±65, static +4,194,305 B, host +1 and listener +1 each fail; the boundary holds;
- case 015 (all five assertions);
- the lap-2 strict rule;
- the ledger.

Reading the numbers:
- Each wait now spans ~80 frames during which the REWARD burst is **owned**, followed by the required 11 quiet frames. It ends at ≈ 780 ms, the burst's ownership ceiling plus the streak, instead of ≈ 20 ms.
- The burst is no longer counted: warm-up nodes are **+34** (the open Gift-10 ceremony popup only), not +35.
- `resets 0` means no quiet streak had started before the burst was owned inside the loop. The old false-quiet window sat entirely within the 2 pre-loop settle frames, which is exactly what the old one-reading rule sampled.

### 3.2 Before / after on this machine

| | Before (unmodified, 2026-10-10: 3 runs in M47 + 1 here) | After (final code) |
|---|---|---|
| `m55_long_session` local | **0/4 PASS** (waits 15–26 ms, +35 nodes) | **3/3 PASS** (waits 775–788 ms, streak 11, +34 nodes) |
| CI (GitHub Actions run 38040561355, old code) | PASS: faster runner timing happened to sample after ownership | not re-run in CI. The rule no longer depends on timing: it needs a frame-counted quiet streak longer than the production settle window. |

### 3.3 Other required suites (same TEMP worktree)

| Suite | Exit | Result | Notes |
|---|---|---|---|
| `tests/m43_c005f_phase4_qa_r01_feel_lifecycle.gd` | 0 | **PASS (4/4 cases, 0 fail)** | `Resumed function '_play()' after await, but class instance is gone`: **0** occurrences; SCRIPT ERROR 0 |
| `tests/m43_c005f_phase4_terminal_home_micro.gd` | 0 | **PASS (19/19 cases, 0 fail)** | 6 lines contain `SCRIPT ERROR`: 1 is the announcing case title `(expected injected SCRIPT ERRORs: one per Spark burst)`, and 5 are `Invalid call … 'explode' in base 'Nil'` raised in the test's own `FaultySpark.burst` (t05). The injected-burst count in that window varies between 4 and 5 by timing, as disclosed in earlier logs. No other error. Freed-instance warning 0. |
| `tests/run_tests.gd` (root) | 0 | **RESULT: ALL PASS** | SCRIPT ERROR 0 |

## 4. Deviations / provenance

- **No deviation from the authorized scope.** One test file plus this log.
- **The timeout path cannot pass:**
  - `_await_feel_quiet` returns `quiet = false` when the deadline expires without a full streak;
  - that is an explicit `_ok(false…)`;
  - the original final `owned_count() == 0` assertion still follows;
  - case 015 proves that no trace without a full streak releases.
- **Not exercised in a full real run:** a real 5 s timeout. That would need a never-ending decoration, which only a product change could create. It is covered by the pure-rule case 015 instead.
- The burst's own lifetime is unchanged. No unconditional delay was added: the wait ends as soon as 11 quiet frames are observed.

## 5. Postflight

- Committed (test + log only) and pushed normally to `main`.
- The Desktop is then synced with `fetch` + `merge --ff-only`.
- The single TEMP worktree created for this task is removed. Other pre-existing worktrees are untouched.
- HEAD == `origin/main`, 0/0, owner file / stash parity and the unchanged `project.godot` hash are reported in the hand-off, because this log cannot contain its own commit.

Final state: **AWAITING_AUDIT**
