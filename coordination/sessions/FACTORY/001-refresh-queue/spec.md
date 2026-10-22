# Refresh the TASKS.md Autonomous Queue

> Feature: REFRESH-QUEUE — refresh the `## Autonomous Queue` block at the top of root TASKS.md (builder edits only TASKS.md). Per .claude/skills/factory/SKILL.md "/factory next" step 2: scan the open `- [ ]` items and the Project Status, then fill the queue with one row per item `- READY|OWNER|DONE <TASK-ID> — <one line>`. Order: owner-stated current priority first (M50 board color-blind symbols, SB-M50-BOARD-001, see CLAUDE.md §0C), then unblocked items, smallest dependency first. Per CLAUDE.md §0D (2026-10-22): all owner visual/F5/phone sign-offs are GIVEN and the Actions cost freeze is lifted, so items waiting only on those are READY. An item is OWNER only if it truly needs a §0D.5 owner action (public production store release, new spending, deleting owner-original art or user saves, genuinely undecided product choice); each OWNER row should get one matching line under `## Questions for Şekip`. The REFRESH-QUEUE row itself must become DONE. Each READY row should be a single job-sized item (split big milestones into job-sized rows with clear IDs). Write spec.md with testable acceptance criteria.

## Context

- **Tracker.** Root `TASKS.md` (3110 lines) is the only tracker (CLAUDE.md §0, §0D.4). Its top has three blocks, in this order:
  - `## Autonomous Queue` (line 5), with a header HTML comment and one placeholder row, `- READY REFRESH-QUEUE — ...`.
  - `## Questions for Şekip` (line 9), with a header HTML comment and no rows.
  - `## Project Status` (line 12), followed by `## Tasks` and the milestone sections M00..M61, `GENERATED ASSET LIFECYCLE`, and the rest.
- **How the queue is used.** `.claude/skills/factory/SKILL.md` "/factory next" step 2 reads the queue from `origin/main` (`git show origin/main:TASKS.md | head -80`) and runs the first `READY` row as the next job. That row's `<TASK-ID>` becomes the job's task. "Escalate" turns a row into `OWNER` and adds one line under `## Questions for Şekip`.
- **What is open today.** There are 357 open `- [ ]` checklist items. Every one starts with a unique `SB-...` ID (possibly in bold, for example `- [ ] **SB-M50-BOARD-001 — ...`). No ID is duplicated. Open items fall into four kinds:
  - **Work that is finished except for an owner gate that §0D.1/§0D.2 now gives.** Examples:
    - `SB-M50-BOARD-001` (line 21) and `SB-M50-002` (line 2497): only cloud CI and the ChatGPT audit are left open. Owner F5 was approved 2026-10-16.
    - `SB-DEV-GODOT-001` (line 43): READY_FOR_OWNER_F5_CHECK.
    - `SB-M46-003`, `SB-M46-008`, `SB-M46-015` (lines 2399-2412): only the phone/GPU owner gate is left.
    - `SB-M44-020` (line 2249): owner playtest.
    - `SB-UI-VIS-004` (line 695): source commit `65b26242` is already an ancestor of `main`, so only verify and tick it.
  - **Ordinary open implementation work.** For example M43 destinations, M49/M50/M51 checks, M54/M55 regressions, M47 device runs and M59 build hygiene.
  - **Genuinely undecided product choices.** These are §0D.5 owner items:
    - `SB-M51-005`: actual languages not chosen.
    - `SB-M43-131`: RANKS scoring policy needs an owner decision.
    - `SB-M43-136`: future world level ranges.
    - `SB-M43-153`: account/sign-in provider.
    - `SB-M57-001`: ad/IAP provider; no SDK before owner approval.
    - `SB-M57-012`: real-money Scrub Bucks packs and value ladder.
    - `SB-M57-013`: No Ads product definition.
    - `SB-M61-001`: Friends scope.
    - `SB-M44-010`: feature-unlock pacing table. `SB-M44-011` says "Do not invent exact unlock level numbers until the owner approves the pacing table".
  - **Standing rules phrased as checklist items.** These are not jobs. Examples: `SB-UI-020..032` (generated-asset rules), `SB-M22-016..019`, `SB-M22-021`, and `SB-M57-017..020` ("No paid random card pack...", "No second premium currency...").
- **Stale Project Status text.** Project Status bullets still say "Claude must not alter TASKS" and "NO_GITHUB_ACTIONS_ABSOLUTE_COST_FREEZE". Line 14 already records that CLAUDE.md §0D supersedes them. This job does not rewrite Project Status.
- **No code is involved.** This job changes no game code and no tests. AGENTS.md lists no test runner for tracker-only edits. The acceptance check is the Python script given below, plus git diff checks.

## Requirements

1. Only root `TASKS.md` changes. The only lines added, removed or changed are inside the `## Autonomous Queue` and `## Questions for Şekip` blocks, between the `## Autonomous Queue` heading and the `## Project Status` heading. Keep both headings and both existing header HTML comment lines exactly as they are. No checkbox, Project Status bullet or milestone text is touched anywhere else.
2. **Row format.** Every queue row is exactly `- <STATUS> <TOKEN> — <one line>`:
   - `<STATUS>` is `READY`, `OWNER` or `DONE`.
   - The separator is a space, an em dash `—`, and a space.
   - The whole line is at most 200 characters.
   - `<TOKEN>` is one of:
     - an existing open ID (for example `SB-M43-R15-002`);
     - a range `<ID-with-numeric-suffix>..<NNN>` with the same prefix (for example `SB-M43-078..082`), which covers every open ID with that prefix and a numeric suffix in that range;
     - `REFRESH-QUEUE`.
   - Use the existing TASKS.md IDs and ranges as the "clear IDs" for split milestones. Do not invent new IDs.
3. The queue contains `- DONE REFRESH-QUEUE — <one line>`. It is the only DONE row. Put it first in the block.
4. **Coverage.** Every open `- [ ] SB-...` ID below `## Project Status` is covered exactly once, either by one queue row or by one token in a single exclusion comment line placed in the queue block:
   `<!-- Not queued (standing rules, no job of their own): <ID or range>, <ID or range>, ... -->`
   Put an ID in the exclusion comment only if its TASKS.md text is purely a constraint on how other work is done ("never/do not/keep/preserve/must not..."), with nothing to build or verify on its own. When in doubt, queue it.
5. **First READY row.** The first READY row is `- READY SB-M50-BOARD-001 — ...`, the owner's current priority (CLAUDE.md §0C). Its line says what is left: run the Android `validation_only` workflow (allowed again under §0D.2), record the run, and close the item. Owner F5 was given 2026-10-16. The phone gate is given by §0D.1, and ChatGPT audit is no longer required (§0D.4).
6. **READY rows.** Any item that waits only on owner visual/F5/phone/playtest sign-off, ChatGPT audit or GitHub Actions is READY (§0D.1, §0D.2, §0D.4). If the TASKS.md evidence suggests the work is already done (for example SB-UI-VIS-004, SB-DEV-GODOT-001, SB-M46-003/008/015, SB-M44-020), make it a READY row whose line starts with `verify-close:`. Do not tick its checkbox in this job.
7. **Job size.** A READY row covers at most 6 open IDs, all in one milestone subsection (`###` or `####`). A big milestone becomes several consecutive range rows.
8. **OWNER rows.** An item is OWNER only when it needs a §0D.5 action: a public production store release, new spending, deleting owner-original art or user saves, or a genuinely undecided product choice. At minimum, these are OWNER: `SB-M51-005`, `SB-M43-131`, `SB-M43-136`, `SB-M43-153`, `SB-M57-001`, `SB-M57-012`, `SB-M57-013`, `SB-M61-001`, `SB-M44-010`.
   - An open item that cannot start until one of those decisions is made may be covered by that decision's OWNER range row, when it is in the same subsection.
   - Otherwise it gets its own OWNER row, and that row's token goes on the same question line as the decision it waits on.
   - Physical-device runs (M47, `SB-M34-006`, `SB-M42-032`, `SB-M57-022`) and visual-master production rows are READY, not OWNER (see Assumptions).
9. **Questions.** Every OWNER row's token appears in exactly one line under `## Questions for Şekip`, in the form `- <TOKEN>[, <TOKEN>...] — <one short question>`. Every question line names at least one OWNER token. A line may name several OWNER tokens only when they all wait on the same decision.
10. **Order.** After `SB-M50-BOARD-001`, the READY rows are ordered:
    1. the rest of the M50 board/accessibility follow-up (`SB-M50-002`);
    2. `verify-close:` rows;
    3. unblocked implementation rows, smallest dependency first. A row never comes before a READY row whose work its TASKS.md text says it needs ("after", "once", "when ... opens", a regression row after the feature it regresses). In particular, `SB-UI-VIS-004` comes before `SB-UI-VIS-005`;
    4. then `SB-M59-011`, as its own row (its text gates it after feature freeze);
    5. then any READY `SB-M60-*` rows, as the very last READY rows.

    OWNER rows go after all READY rows.
11. No docs or other files change. AGENTS.md and CLAUDE.md already describe the queue (CLAUDE.md §0D.4, SKILL.md).

## Acceptance criteria

1. **Scope of the diff.** In the worktree, `git diff --name-only origin/main...HEAD` prints exactly `TASKS.md`. Every hunk of `git diff -U0 origin/main...HEAD -- TASKS.md` starts at a line number lower than the line number of `## Project Status` in the new file. `git diff --check origin/main...HEAD` prints nothing.
2. **The queue checker passes.** Save the script below to a scratch file outside the worktree, for example `<scratch>/check_queue.py`. Run `cd <worktree> && python -I <scratch>/check_queue.py TASKS.md`. The last line it prints must be `QUEUE_CHECK PASS`. The script checks requirements 2-5, 7, 9 and the order rules in 10 (first READY row, VIS-004 before VIS-005, SB-M59-011 then SB-M60 last). It also checks the minimum OWNER set from 8 and the READY status of the §0D-cleared items from 6. Run against unchanged `origin/main`, it prints `coverage 0: ...` errors, which proves it detects a missing queue.

   ```python
   import re, sys
   t = open(sys.argv[1], encoding="utf-8").read().splitlines()
   qa = t.index("## Autonomous Queue"); qq = t.index("## Questions for Şekip"); ps = t.index("## Project Status")
   ID = r"SB-[A-Za-z0-9]+(?:-[A-Za-z0-9]+)*"
   open_ids = []
   for l in t[ps:]:
       m = re.match(r"\s*- \[ \] \**(" + ID + ")", l)
       if m: open_ids.append(m.group(1))
   openset = set(open_ids)
   def expand(tok):
       if ".." not in tok: return {tok} & openset
       a, b = tok.split("..")
       m = re.match(r"(.*-)(\d+)$", a); p, lo = m.group(1), int(m.group(2))
       hi = int(re.search(r"(\d+)$", b).group(1))
       return {i for i in openset if i.startswith(p) and re.fullmatch(re.escape(p) + r"\d+", i) and lo <= int(i[len(p):]) <= hi}
   err = []; rows = []; excl = []
   for l in t[qa + 1:qq]:
       if not l.strip(): continue
       if l.startswith("<!--"):
           if l.startswith("<!-- Not queued"): excl += re.findall(ID + r"(?:\.\.[A-Za-z0-9-]+)?", l)
           continue
       m = re.match(r"- (READY|OWNER|DONE) (\S+) — \S.*$", l)
       if not m: err.append("bad row: " + l); continue
       if len(l) > 200: err.append("row over 200 chars: " + m.group(2))
       rows.append((m.group(1), m.group(2)))
   cover = {}
   for st, tok in rows + [("EXCL", x) for x in excl]:
       if tok == "REFRESH-QUEUE": continue
       ids = expand(tok)
       if not ids: err.append("covers no open ID: " + tok)
       if st == "READY" and len(ids) > 6: err.append("READY row too big (%d): %s" % (len(ids), tok))
       for i in ids: cover.setdefault(i, []).append((st, tok))
   for i in open_ids:
       if len(cover.get(i, [])) != 1: err.append("coverage %d: %s" % (len(cover.get(i, [])), i))
   if ("DONE", "REFRESH-QUEUE") not in rows: err.append("REFRESH-QUEUE not DONE")
   ready = [tok for st, tok in rows if st == "READY"]
   if not ready or ready[0] != "SB-M50-BOARD-001": err.append("first READY is not SB-M50-BOARD-001")
   qs = [l for l in t[qq + 1:ps] if l.startswith("- ")]
   for st, tok in rows:
       if st == "OWNER":
           n = sum(1 for q in qs if re.search(re.escape(tok) + r"(?![A-Za-z0-9.-])", q))
           if n != 1: err.append("OWNER %s in %d question lines" % (tok, n))
   for q in qs:
       if not any(st == "OWNER" and tok in q for st, tok in rows): err.append("question names no OWNER row: " + q)
   def status(i): return cover.get(i, [("NONE", "")])[0][0]
   for i in "SB-M51-005 SB-M43-131 SB-M43-136 SB-M43-153 SB-M57-001 SB-M57-012 SB-M57-013 SB-M61-001 SB-M44-010".split():
       if status(i) != "OWNER": err.append("must be OWNER: %s (%s)" % (i, status(i)))
   for i in "SB-M50-BOARD-001 SB-M50-002 SB-DEV-GODOT-001 SB-M46-003 SB-M46-008 SB-M46-015 SB-UI-VIS-004 SB-UI-VIS-005 SB-M39-033 SB-M43-R15-002 SB-M43-R15-003 SB-M47-015 SB-M44-020".split():
       if status(i) != "READY": err.append("must be READY: %s (%s)" % (i, status(i)))
   rr = [expand(tok) for tok in ready]
   def pos(i): return next((k for k, ids in enumerate(rr) if i in ids), -1)
   if not (0 <= pos("SB-UI-VIS-004") < pos("SB-UI-VIS-005")): err.append("SB-UI-VIS-004 row must precede SB-UI-VIS-005 row")
   m60 = [k for k, ids in enumerate(rr) if any(i.startswith("SB-M60-") for i in ids)]
   if m60 and m60 != list(range(len(rr) - len(m60), len(rr))): err.append("READY SB-M60 rows must be the last READY rows")
   tail = m60[0] if m60 else len(rr)
   if pos("SB-M59-011") != tail - 1: err.append("SB-M59-011 row must be the last READY row before any SB-M60 rows")
   print("open IDs:", len(open_ids), "rows:", len(rows), "excluded tokens:", len(excl))
   print("\n".join(err) if err else "QUEUE_CHECK PASS")
   ```

3. **The factory reads the right row.** `git -C <worktree> show HEAD:TASKS.md | head -80` contains the `- DONE REFRESH-QUEUE` row and the `- READY SB-M50-BOARD-001` row. The first line matching `^- READY ` in that output is the SB-M50-BOARD-001 row. SKILL.md step 2 reads only the first 80 lines, so DONE and READY rows must come before OWNER rows, and the first READY row must be within line 80.
4. **The first READY row describes the remaining work.** The `SB-M50-BOARD-001` row's text mentions `validation_only` CI and closing the item.
5. **Exclusions are only standing rules.** The reviewer reads the TASKS.md text of every ID listed in the `<!-- Not queued ... -->` comment. Each one is a pure constraint (requirement 4). Any ID that names something to build, generate, validate, test or measure is a CHANGES finding.
6. **OWNER rows are only §0D.5 cases.** For each OWNER row other than the nine required ones, its question line names a concrete §0D.5 reason: an undecided product choice, new spending, a public store release, or deleting owner art or user saves. An OWNER row whose only blocker is visual/F5/phone/ChatGPT/Actions is a CHANGES finding.
7. **No owner state is touched.** `git -C <worktree> status --short` is clean after the commit. No file outside `TASKS.md` is staged or committed.

## Out of scope

- Ticking any `- [ ]` checkbox, closing any task, or editing Project Status, milestone text, the Progress counter or stale freeze wording.
- Running GitHub Actions, Godot suites or builds. That work belongs to the queued jobs themselves (for example the SB-M50-BOARD-001 job runs `validation_only`).
- Creating new task IDs, new milestones, a second tracker, or any file besides `TASKS.md`. Do not commit the checker script.
- Re-deciding owner-locked rules, or writing more than one question per decision.
- Editing CLAUDE.md, AGENTS.md or SKILL.md.

## Assumptions

- **"One row per item" allows range rows.** Range rows over consecutive existing IDs in one subsection, at most 6 per READY row, count as one row per job-sized item. This is because 357 single-ID rows would make the queue unreadable, and the request also asks for job-sized splits.
- **Standing-rule checklist items get no row.** They go in one exclusion comment because they are constraints on other jobs, not jobs. The comment keeps coverage provable.
- **Done-looking items become `verify-close:` READY rows, not DONE.** Closing a task needs evidence and peer review (§0D.4), which a tracker-only refresh cannot provide.
- **Physical-device test items are READY.** §0D.1 gives the phone sign-offs, and §0D.5 makes internal and debug builds autonomous. If a job truly cannot get a device, it escalates through the normal loop.
- **"Produce/owner-approve visual master" items are READY.** §0D.4 says not to ask the owner to approve normal work, and the approved Magnific/ChatGPT generation paths are not new spending. If a job would need new paid credits, it escalates.
- **SB-M44-010 is OWNER.** SB-M44-011 explicitly forbids inventing unlock level numbers until the owner approves the pacing table.
- **SB-M59-011 stays a READY row near the end.** Its Phase 1 deletes nothing, and the deletion phase escalates on its own if it would touch owner-original art.
