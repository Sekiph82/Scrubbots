STATUS: READY

# Build: TASKS-SLIM, archive completed items and slim root TASKS.md

## Spec (light path)
Owner request, chat 2026-10-22 ("hepsini yap"). Root TASKS.md is 382 KB / 3217 lines, with 1092 `- [x]` and 357 `- [ ]` items. Shrink it without losing information:
1. Copy TASKS.md byte for byte to `docs/migration/legacy-task-trackers/TASKS_ARCHIVE_2026-10-22.md`.
2. Remove every `- [x]` item and its indented continuation lines. Keep every `- [ ]` line byte-identical and in its original heading section. Drop headings that are left with no open item and no text.
3. Cut `## Project Status` down to the newest ~15 bullets, with the 2026-10-22 §0D bullet first, and replace the older bullets with one line pointing to the archive.
4. Leave untouched: header lines 1-3, `## Autonomous Queue`, `## Questions for Şekip`, and the LOCKED GAME RULES / rule sections.
5. Add one line under the header that points to the archive.
Checks: (a) the open-item lines are identical (357), (b) every task ID in the queue still exists, (c) the archive is byte-identical to origin/main:TASKS.md, plus the size, `git diff --check`, the changed-file set and CRLF.

## Summary
Commit `7b8ea378` on `factory/009-tasks-archive`:
- `docs/migration/legacy-task-trackers/TASKS_ARCHIVE_2026-10-22.md` (new) is the frozen full snapshot. Its git blob is the same as the origin/main TASKS.md blob.
- `TASKS.md` drops from 391,153 to 196,528 bytes (382.0 KB to 191.9 KB) and from 3217 to 1949 lines. All 1092 done items are gone, 16 headings that ended up empty are dropped, and Project Status keeps its first 15 bullets plus the 2 open items (SB-M50-BOARD-001 and SB-DEV-GODOT-001) that sit in that section, followed by the archive pointer line. The header pointer line was added after line 3.

The transform was a one-off python script (`python -I`). It only removes `- [x]` lines (no `[x]` item in the file has indented continuations), old Project Status bullets with their continuations, blank lines left doubled by those removals, and headings emptied by the removals. Prose and plain bullets everywhere else are kept unchanged.

**Size target missed: 191.9 KB against "well under 150 KB".** Under the constraints the target can't be reached. The 357 open lines that must stay byte-identical take 62.9 KB, the untouched Autonomous Queue 14.4 KB, and the rule sections about 30 KB. The rest is non-item prose inside `## MASTER MILESTONES` (about 41 KB of text paragraphs: Purpose notes, owner amendments, audit records), which point 2 says to keep. Even dropping the 40 milestone sections that have no open items left would only save about 19 KB (to about 173 KB). Getting under 150 KB would mean deciding to archive audit-history paragraphs inside open milestone sections. That is a separate judgment call and was not done.

## Acceptance criteria
1. [x] Archive is a byte-for-byte copy: check (c) prints `archive bytes == origin/main:TASKS.md checkout: True 391153 bytes`, and the blob hashes are equal (`5b45c164...` / `5b45c164...`).
2. [x] Done items removed, open items kept byte-identical in their sections: check (a) prints `open items before/after: 357 357 | same lines, order and heading section: True` and `done items before/after: 1092 0`. Check (d), a difflib pass over all dropped lines, finds no dropped line other than a done item, an old status bullet, a blank or a heading: `[]`. 16 headings dropped.
3. [x] Project Status shortened: the first 15 bullets are kept (the 2026-10-22 §0D bullet first), plus the 2 open items later in the section. Then comes `- Older status bullets and all completed items: \`docs/migration/legacy-task-trackers/TASKS_ARCHIVE_2026-10-22.md\`.`
4. [x] Untouched sections: `header lines 1-3 untouched: True`, `untouched ## Autonomous Queue True`, `untouched ## Questions for Şekip True`, `rule sections (LOCKED GAME RULES .. VISUAL PRODUCTION WORKFLOW) untouched: True`.
5. [x] Header line added as line 5: `Completed items and older status history: docs/migration/legacy-task-trackers/TASKS_ARCHIVE_2026-10-22.md (1092 done items as of 2026-10-22).`
6. [x] Queue IDs: check (b) finds 117 task IDs in the queue and prints `missing from rest of new TASKS.md: []`.
7. [ ] Size well under 150 KB: NOT met. The file is 191.9 KB (196,528 bytes); the reason is under Summary.
8. [x] `git diff --cached --check`: clean. `git diff --name-only origin/main..HEAD` lists only `TASKS.md` and the archive. `CRLF only (no bare LF/CR): True` (core.autocrlf=true, so blobs are LF and the checkout is CRLF, the same as before).

## Validation
- `python -I check.py <worktree>` (scratchpad script, output quoted above): all checks True except the size target.
- `git diff --cached --check`: clean.
- `git status --porcelain`: empty after the commit.
- No Godot suites: no code changed.
- TASKS.md entry for TASKS-SLIM: there is no TASKS-SLIM row, and the queue had to stay byte-untouched in this commit, so the orchestrator should update the queue row.

## Log
### Round 1
Built the archive and the slimmed TASKS.md with a scripted transform and verified it with checks (a)-(d). The rule-section check covers LOCKED GAME RULES through the VISUAL PRODUCTION / MASTER UI WORKFLOW section, because `## VISUAL ASSET PRODUCTION STATUS` is a status section that held `[x]` items. The size target was missed at 191.9 KB; the explanation is under Summary.
