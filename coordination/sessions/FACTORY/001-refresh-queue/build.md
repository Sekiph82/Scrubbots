STATUS: READY

# Build: Refresh the TASKS.md Autonomous Queue

## Summary
Commit `a8a3d518` on `factory/001-refresh-queue` rewrites the `## Autonomous Queue` and `## Questions for Şekip` blocks at the top of root `TASKS.md` (lines 5-127). Nothing else in the file changed. CRLF line endings are kept.

- **Queue:** 106 rows. 1 DONE (`REFRESH-QUEUE`), 85 READY, 20 OWNER. A `<!-- Not queued ... -->` comment lists 12 standing-rule tokens.
- **Coverage:** every one of the 357 open `- [ ] SB-...` IDs is covered exactly once.
- **First READY row:** `SB-M50-BOARD-001`. The job runs Android `validation_only` CI, records the run and closes the item.
- **Next rows:** `SB-M50-002`, then 7 `verify-close:` rows (SB-UI-VIS-004, SB-DEV-GODOT-001, SB-M46-003..015, SB-M44-020, SB-M43-R15-001, SB-UI-017..019).
- **Rest of READY:** implementation rows ordered dependency-first (features, then responsive/a11y/l10n, analytics, regression/chaos, compliance, build). Then `SB-M59-011`, then `SB-M60-001..006` last.
- **Questions:** 10 lines, one per undecided owner decision. Each OWNER row's token appears on exactly one of them. The decisions are languages, RANKS metric, world ranges, account provider, ad/IAP provider, SB packs, No Ads, Friends, unlock pacing, and the ScrubBox bonus slot. Rows that depend on a decision share that decision's line.
- **Files changed:** `TASKS.md` only.

## Acceptance criteria
1. [x] **Scope of the diff.** Evidence:
   - `git diff --name-only origin/main...HEAD` printed only `TASKS.md`.
   - `git diff --check origin/main...HEAD` printed nothing.
   - The hunks are `@@ -7 +7,107 @@` and `@@ -10,0 +117,10 @@`. Both start before `## Project Status`, which is now at line 128.
2. [x] **The queue checker passes.** `python -I <scratch>/check_queue.py TASKS.md` printed `open IDs: 357 rows: 106 excluded tokens: 12` then `QUEUE_CHECK PASS`. Run against `git show origin/main:TASKS.md`, it printed 357 `coverage 0:` lines, which shows it detects a missing queue.
3. [x] **The factory reads the right row.** In `git show HEAD:TASKS.md | head -80`:
   - line 7 is `- DONE REFRESH-QUEUE`;
   - line 8 is the first `^- READY ` line, `- READY SB-M50-BOARD-001`;
   - there are 0 OWNER rows in the first 80 lines.
4. [x] **The first READY row describes the remaining work.** It reads "run Android `validation_only` CI (allowed again §0D.2), record the run, close the item; owner F5 given 2026-10-16, phone gate §0D.1, no ChatGPT audit §0D.4".
5. [x] **Exclusions are only standing rules.** The comment lists `SB-M08-011..012` ("Preserve original", "Never silently resize") and `SB-M22-016..019`, `SB-M22-021`. It also lists `SB-UI-020..030`, `SB-UI-032`, `SB-M43-135`, `SB-M43-142`, `SB-M43-152`, `SB-M48-001`, `SB-M50-008..009`, `SB-M57-017..021` and `SB-M61-008`.
   - Each is a keep/never/do-not/preserve/use-X constraint.
   - Borderline items were queued instead of excluded: `SB-UI-019` ("generate/approve/bind") inside the SB-UI-017..019 verify-close row, and `SB-UI-031` ("Validate ...") as its own READY row. Constraint-phrased IDs that sit inside a feature range, for example `SB-M43-109` and `SB-M51-007`, stay queued with that range.
6. [x] **OWNER rows are only §0D.5 cases.**
   - The nine required decisions are OWNER.
   - The extra OWNER rows are dependents that cannot start before a decision, and their question lines name it:
     - RANKS: SB-M43-131..133, SB-M56-011;
     - world ranges: SB-M43-136..141, SB-M43-073, SB-M54-032;
     - account provider: SB-M43-153..160, SB-M49-030, SB-M54-031;
     - ad/IAP provider: SB-M57-001..011, SB-M57-014..016, SB-M43-084, SB-M49-029;
     - No Ads: SB-M43-081;
     - Friends: SB-M61-001..007;
     - pacing table: SB-M44-022..023.
   - SB-M43-R09-006 is its own undecided product choice (optional ScrubBox surprise bonus, owner approval required by its text).
   - No OWNER row exists only because of a visual, F5, phone, ChatGPT or Actions gate.
7. [ ] **No owner state is touched.** Partly met. Only `TASKS.md` was staged and committed (commit `a8a3d518`). `git status --short` is **not** clean, because the worktree already held Godot import output when this build started:
   - ` M project.godot`, with mtime 11:07:35 (the same second as the worktree directory): a features line is reordered and the `[audio]` bus-layout entry removed.
   - About 2600 untracked `*.uid` / `*.import` files.
   - `.godot/`, last written 11:10:50.

   I never ran Godot and never touched these files. The `project.godot` diff matches the owner's own uncommitted Godot-editor rewrite in the main checkout. I left them alone rather than delete or restore state I didn't create. The orchestrator should decide whether to discard them when the worktree is removed.

## Validation
- `python -I <scratch>/check_queue.py TASKS.md`: `QUEUE_CHECK PASS`.
- `git diff --check origin/main...HEAD`: clean.
- `git diff --name-only origin/main...HEAD`: `TASKS.md`.
- CRLF check: 0 LF-only lines in TASKS.md.
- Every queue and question row is 200 characters or fewer (checked by the script).
- No Godot or other test suites were run. This is a tracker-only change, and the spec puts suites out of scope.

## Log
### Round 1
- Confirmed the branch is `factory/001-refresh-queue`.
- Extracted all 357 open IDs with their `###`/`####`/`#####` subsections and read the full text of the gated and long items. Confirmed that `65b26242` is an ancestor of HEAD and that `scripts/ui/popup/base_popup.gd` exists.
- Wrote the queue, question and exclusion blocks, spliced them between the headings with CRLF preserved, and iterated the checker to PASS. The first run flagged SB-M08-011/012, which I added to the exclusions.
- Committed `a8a3d518`.
- The root-TASKS.md entry for this task is the `- DONE REFRESH-QUEUE` row itself. The spec forbids other tracker edits, so no SHA is written into the file.
