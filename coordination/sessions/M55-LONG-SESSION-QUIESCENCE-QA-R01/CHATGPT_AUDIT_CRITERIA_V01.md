# M55-LONG-SESSION-QUIESCENCE-QA-R01 — Strict ChatGPT Audit Criteria V01
Date: 2026-10-10. Repo: `Sekiph82/Scrubbots`.
Current state: **AUTHORIZED / AWAITING_CLAUDE_IMPLEMENTATION**. Audit authority: ChatGPT only.

## G0. Owner data and scope
- `CLAUDE.md`, `TASKS.md`, prior QA-R01 record and new prompt read.
- Persistent Desktop safe fast-forward at start/end, `HEAD == origin/main`, 0/0, owner tracked/untracked/stashes preserved, `project.godot` hash unchanged.
- Exact isolated TEMP worktree with absolute paths; no Desktop destructive Git commands; no large unmanaged disk duplication.
- Allowed changed product file ONLY `tests/m55_long_session.gd`; plus matching `CLAUDE_LOG_V01.md`. Root `TASKS.md` not implementer-edited. No source/game/economy/feel-renderer/Android/R2 changes.

## A. Race corrected, not hidden
- Static source confirms quiet sampling checks zero owned decorations for **> `MetaRewardFeel.SETTLE_FRAMES + 2` consecutive process frames** before sampling. Any owned decoration resets streak. Single monotonic 5,000-ms deadline, no unbounded wait and no per-reset fresh deadline.
- The original final quiescence assertion survives. Timeouts cause explicit test FAIL, not silent retry, tolerance or fabricated quiescence; the original final two-frame settle survives.
- Code comments/diagnostics explain the actual pending coroutine before adapter ownership, and report waited ms and quiet streak.
- No arbitrary unconditional delay, no reduction of burst duration, and no production behavior changes.
- False-positive adversarial review: show an early-quiet gap shorter than pending settle cannot release snapshot; zero streak after any nonzero frame; a timeout/failing count cannot pass.

## B. Leak tests remain strong
- Exact warm-up and post-warm-up Node equality unchanged, same lap1 evidence and lap2 strict comparison.
- `MAX_OBJECT_DRIFT = 64`, `MAX_STATIC_MEM_DRIFT = 4 * 1024 * 1024`, orphan non-growth, listener/root-child/host rules unchanged.
- `steady_state_violations()` function and case 014 sensitivity intact: each of Node +1, orphan +1, Object +/-65, memory +4MiB+1 fails, exact boundary still passes.
- Do not accept an extra +1 stable Node merely to remove flakiness.

## C. Runtime evidence
- `m55_long_session` final 3 consecutive complete local runs: **3/3 PASS**, no hidden rerun substitutions or script errors; per-run measured quiet wait ms, consecutive frames, lap1 warm-up Nodes, lap2 exact Node/orphan/Object/static-memory drift.
- `m43_c005f_phase4_qa_r01_feel_lifecycle`: PASS (historical expected 4/4), zero `Resumed function '_play()' after await, but class instance is gone`.
- `m43_c005f_phase4_terminal_home_micro`: PASS (historical expected 19/19).
- `tests/run_tests.gd`: RESULT ALL PASS.
- `git diff --check` clean, exact changed file set, script parses in Godot 4.7.2, documented CI/local difference.
- Check regressions against prior **3/3 local M55 FAIL** and previous **CI PASS** to prove the fix is robust on the machine that exposed it.

## D. Verdict
- **PASS** only after ChatGPT independently reviews the exact diff/source and all required evidence; rerun checks directly where accessible.
- **CHANGES_REQUIRED** if any listed threshold or lifecycle check weakened, any final required run fails, unauthorized file changed, or 5-second bounded quiescence remains racy.
- **NOT_INDEPENDENTLY_VERIFIED** when test-only log claims cannot be cross-checked. No Phase4 product gate reopened by this test-only QA cycle.
- No retroactive change to M47 limited offline APK verdict; device/online-R2 gates remain separate.
