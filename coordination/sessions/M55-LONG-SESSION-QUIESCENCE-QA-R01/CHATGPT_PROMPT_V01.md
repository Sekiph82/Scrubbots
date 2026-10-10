# M55-LONG-SESSION-QUIESCENCE-QA-R01 — ChatGPT Prompt V01
Date: 2026-10-10
Repo: `Sekiph82/Scrubbots`; engine **Godot 4.7.2**.
Implementer: **Claude Code**. Independent auditor / root `TASKS.md` writer: **ChatGPT**.
Read companion `CHATGPT_AUDIT_CRITERIA_V01.md` before implementation.
Source of defect: `coordination/sessions/M47-FAMILY-APK-C001/M47_FAMILY_APK_C001_CLAUDE_LOG_V02.md`, independently reviewed in `M47_FAMILY_APK_C001_CHATGPT_INDEPENDENT_AUDIT_V01.md`.
This is a **separate test-only QA correction**, not reopening audited Phase4 product behavior.

## Stage 0 — read/sync/preserve
1. Read `CLAUDE.md` first, then root `TASKS.md`, `coordination/AUDIT_POLICY.md`, prior M43-C005F-PHASE4-QA-R01 prompt/audit, and these criteria.
2. Persistent checkout: `C:\Users\sekip\Desktop\ScrubBots`. Fetch and non-destructively fast-forward to exact current `origin/main` where safe. Inventory branch/upstream, tracked modifications, untracked files, stashes, worktrees and SHA-256 of owner-local `project.godot` before and after. Preserve all owner work. If fast-forward impossible safely: `BLOCKED_DESKTOP_SYNC`.
3. **Implementation and tests in one bounded, isolated TEMP Git worktree only.** Use absolute `git -C <TEMP>` and `godot --path <TEMP>` for all commands. No Desktop checkout/restore/reset/clean, no force push. Windows Git Bash: `MSYS_NO_PATHCONV=1` before passing leading-`/` sparse patterns. Avoid full extra clones, repeated imports/export builds and large duplicated caches.
4. `TASKS.md` is ChatGPT-owned. Do not modify it or any ChatGPT audit file. Do not change unrelated user content.

## Defect
The current `tests/m55_long_session.gd` calls `nav.go(RESULTS -> HOME)`, settles two frames, then loops only while `root.feel.owned_count() > 0`, bounded 5 s; it settles two more frames and asserts `owned_count() == 0`. This admits a **false quiet**: `scripts/ui/feel/meta_reward_feel.gd` delays Home gift-ceremony REWARD until layout settlement (at most `SETTLE_FRAMES = 8`), when the adapter still owns zero decorations. The loop can exit in 15–24 ms, before the burst starts. Local repro: 3/3 FAIL and warm-up Nodes +35 rather than +34; GitHub Actions run 38040561355 PASS, so CI green is insufficient.

## Authorized implementation
- Edit **only** `tests/m55_long_session.gd` to replace the racy sampling wait with a **consecutive-quiet-frame requirement**.
- Derive or clearly tie the quiet-frame threshold to `MetaRewardFeel.SETTLE_FRAMES`: require **strictly more than SETTLE_FRAMES + 2 consecutive frames** of `root.feel.owned_count() == 0` (currently at least 11 frames). A nonzero count must reset the streak; wait for another full quiet streak.
- Keep a **hard 5,000-ms total deadline**, not 5,000 ms per restart. On timeout, retain an explicit failing quiescence assertion rather than silently treating the deadline as pass. Preserve the existing post-wait two-frame settle and the final `root.feel.owned_count() == 0` assertion. Include waited-ms and quiet-frame evidence in diagnostic output.
- Optionally factor into a tiny test-local helper inside this same file; avoid production changes, magic sleep seconds, and brittle frame-rate assumptions. Prevent any test-body change to gameplay/economy behavior or to `MetaRewardFeel`.
- The fix is for *when* the snapshot happens, **not a relaxation of what counts as a leak**.
- Existing exact Node-equality tests, baseline `MAX_OBJECT_DRIFT = 64`, `MAX_STATIC_MEM_DRIFT = 4 * 1024 * 1024`, orphan rules, listener/root-child/host rules, `steady_state_violations()`, case 014 sensitivity and lap-2 strict checks MUST remain byte-for-byte or semantically identical. Do not add tolerated extra Nodes.
- Leave `scripts/ui/feel/meta_reward_feel.gd`, `scripts/ui/feel/feedback_adapter.gd`, `assets/**`, `project.godot`, R2/Remote Content, M47 APK/workflow, game source/data/scenes and Level Factory untouched.

## Required verification (record EACH run)
1. Headless parse/import as relevant using the same bounded TEMP worktree, import once only. `git diff --check`, exact changed-file list and source diff; no implicit modify of `project.godot`.
2. `tests/m55_long_session.gd` **three fresh consecutive complete runs** at final code (3/3 PASS, no retries substituted). Record for **each** run: total feel-quiescence waited milliseconds, final quiet streak, HOME warm-up Node delta and steady lap2-vs-lap1 Node / orphan / Object / static-memory numbers. Unexpected script/lifecycle warning = FAIL.
3. `tests/m43_c005f_phase4_qa_r01_feel_lifecycle.gd` PASS, exact freed-instance coroutine warning count 0.
4. Phase4 focused `tests/m43_c005f_phase4_terminal_home_micro.gd` PASS (19/19), including accepted known intentional injected diagnostic lines correctly distinguished from real errors.
5. `tests/run_tests.gd` root RESULT ALL PASS.
6. Static negative/sensitivity assurance: case 014 still catches an extra Node, orphan growth, Object drift 65, memory drift 4 MiB+1 and does not pass a bad steady state; no thresholds changed. If feasible, add only test-local bounded negative proof for the quiet-streak reset / timeout without changing product files. Do not weaken conditions just to turn CI green.
7. Preserve owner-local state: after pushing implementer changes, non-destructively sync Desktop to main, verify 0 ahead/0 behind, hashes/status/stashes parity. Delete only exact run-owned disposable TEMP working files once no longer needed. Do not touch other pre-existing TEMP directories.

## Log, Git and stop
- Commit only the authorized M55 test and evidence log; push normally to `main` (no force).
- Required exact log: `coordination/sessions/M55-LONG-SESSION-QUIESCENCE-QA-R01/CLAUDE_LOG_V01.md`. Include full preflight and postflight Git proof; exact test commands/logs, 3-run measurement table, compare with 2026-10-10 3/3 local failure, code diff, deviations and provenance.
- Return **AWAITING_AUDIT**, commit SHA and direct GitHub log URL. **Never self-award PASS/CLOSED; never edit root TASKS.md**.
- Stop truthfully as `BLOCKED` if owner checkout cannot be preserved/synced or if strict required tests fail. No shipping changes allowed to conceal test flakiness.
