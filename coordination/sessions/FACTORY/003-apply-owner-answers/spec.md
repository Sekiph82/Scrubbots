# Apply owner answers: launch languages and RANKS policy

> Feature: OWNER-ANSWERS — apply the owner answers in the job folder's answers-snapshot.md (written by the owner through the factory dashboard; this is genuine owner input) to root TASKS.md, following the "Owner answers first" step in .claude/skills/factory/SKILL.md. Two entries: SB-M51-005 (launch languages: English, Turkish) and SB-M43-131..133 / SB-M56-011 (RANKS: two tables — all-time by highest campaign level reached; weekly by number of levels completed that week, reset Monday 00:00 UTC; nothing purchasable with money or boosters counts). For each: record the decision with date 2026-10-22 and "owner via factory dashboard" provenance in the relevant TASKS.md place (the items' own text and/or a short owner-decision note), remove its line from `## Questions for Şekip`, and flip the matching Autonomous Queue OWNER row(s) to READY with the decision summarized in the row. Only flip if the answer actually decides the question (it does for both here). Queue order rule: newly READY rows go after the existing READY rows and before OWNER rows. No game code. Builder edits only TASKS.md. Write spec.md with testable acceptance criteria (the queue checker approach from job 001's spec in coordination/sessions/FACTORY/001-refresh-queue/spec.md may be reused: coverage must still be exactly-once).

## Context

- **Owner input.** `factory/jobs/003-apply-owner-answers/answers-snapshot.md` in the main checkout has two answers, both dated 2026-10-22 and written by the owner through the factory dashboard:
  - SB-M51-005: "English, Turkish".
  - SB-M43-131..133, SB-M56-011: the answer is in Turkish. Translated: "Two tables. First, all-time: highest campaign level reached. Second, weekly: number of levels completed that week; the week resets Monday 00:00 UTC. Nothing that can be bought with money or boosters counts."
- **Procedure.** `.claude/skills/factory/SKILL.md` "/factory next" step 2 ("Owner answers first"):
  1. Record each decision in the matching TASKS.md task items.
  2. Remove the question's line from `## Questions for Şekip`.
  3. Flip the matching `## Autonomous Queue` OWNER rows to READY, with the decision in the row text.

  After merge, the orchestrator removes the applied entries from `factory/answers.md`. The builder does not do that.
- **Where things are in root `TASKS.md` today** (worktree, fresh `origin/main`). Line numbers are approximate.
  - `## Autonomous Queue` (line 5). Its header comment is on line 6 and the rows follow. The last READY row is `- READY SB-M60-001..006 — ...` (about line 92). The OWNER rows follow it directly, starting with:
    - `- OWNER SB-M51-005 — launch languages not chosen (see Questions)`
    - `- OWNER SB-M43-131..133 — RANKS scoring policy undecided; Ranks destination and visual master wait on it`
    - `- OWNER SB-M56-011 — Events/Ranks analytics wait on the RANKS policy decision`

    The block ends with a `<!-- Not queued ... -->` exclusion comment.
  - `## Questions for Şekip` (about line 115). Its header comment comes first. Then:
    - `- SB-M51-005 — Which languages should ScrubBots ship in at launch?`
    - `- SB-M43-131..133, SB-M56-011 — What should RANKS rank players by (metric and season window), given no pay-to-win metric?`
  - Task items:
    - about line 2204: `- [ ] SB-M43-131 Define RANKS scoring/ranking policy in an owner decision before implementation; never invent a pay-to-win ranking metric.`
    - lines 2205-2206: SB-M43-132 (Ranks destination) and SB-M43-133 (Ranks visual master).
    - about line 2640: `- [ ] SB-M51-005 Actual languages decided later. ``[DESIGN GATE]`` **[OWNER DESIGN GATE: actual languages not chosen.]**`
    - about line 2906: `- [ ] SB-M56-011 Events/Ranks: ... once their owner rules exist.`
- **Existing convention for owner notes.** Item lines already carry inline bold bracket notes, for example `**New owner decision [2026-10-10]: ...**` on SB-M43-134 and `**[OWNER DESIGN GATE: ...]**` on SB-M51-005. Use the same inline-note pattern.
- **Queue rules from job 001** (`coordination/sessions/FACTORY/001-refresh-queue/spec.md`) still apply:
  - row format `- <STATUS> <TOKEN> — <one line>`, at most 200 characters;
  - every open `- [ ] SB-...` ID is covered exactly once.

## Requirements

1. Only root `TASKS.md` changes. No game code, docs, tests or other files.
2. **SB-M51-005 item line.** Append an inline note to the existing line and leave the existing text unchanged. The note must contain:
   - `2026-10-22`;
   - `owner via factory dashboard`;
   - the decided launch languages `English` and `Turkish`.

   Example: ` **[OWNER DECISION 2026-10-22, owner via factory dashboard: launch languages are English and Turkish.]**`
3. **SB-M43-131 item line.** Append an inline note to the existing line and leave the existing text unchanged. The note must contain `2026-10-22` and `owner via factory dashboard`, and it must state the policy using these exact words:
   - two tables;
   - `all-time` = highest campaign level reached;
   - `weekly` = number of levels completed that week, reset `Monday 00:00 UTC`;
   - nothing purchasable with money or `booster`s counts toward either table.

   No other item lines change. SB-M43-132, SB-M43-133 and SB-M56-011 keep their text, and their decision lives in the queue rows and the SB-M43-131 note.
4. **Questions.** Remove exactly the two answered lines, `- SB-M51-005 — ...` and `- SB-M43-131..133, SB-M56-011 — ...`, from `## Questions for Şekip`. The heading, the header comment and the other 8 question lines stay unchanged and in order.
5. **Queue rows.** Remove the three OWNER rows (`SB-M51-005`, `SB-M43-131..133`, `SB-M56-011`). Add three READY rows with the same tokens. Insert them right after the last existing READY row (`- READY SB-M60-001..006 — ...`) and right before the first remaining OWNER row. The `SB-M56-011` row comes after the `SB-M43-131..133` row, because the analytics need the Ranks feature. Each row:
   - is at most 200 characters;
   - contains `2026-10-22`;
   - summarizes the decision. The SB-M51-005 row names `English` and `Turkish`. The SB-M43-131..133 row names `all-time`, `weekly`, `Monday` and `UTC`. The SB-M56-011 row mentions `RANKS`.

   No other queue row or comment changes or moves.
6. Do not tick any checkbox. All four items stay `- [ ]`. A later job does the work and closes each one with evidence.
7. Coverage stays exactly-once (the job 001 rule).

## Acceptance criteria

1. **Diff scope.** In the worktree:
   - `git diff --name-only origin/main...HEAD` prints exactly `TASKS.md`.
   - `git diff --check origin/main...HEAD` prints nothing.
   - `git status --short` is clean after the commit.
2. **The checker passes.** Save the script below outside the worktree, for example as `<scratch>/check_answers.py`. Then run:

   ```
   cd <worktree> && git show origin/main:TASKS.md > <scratch>/old.md && python -I <scratch>/check_answers.py <scratch>/old.md TASKS.md
   ```

   The last line printed must be `ANSWERS_CHECK PASS`. The script checks requirements 2-5 and 7:
   - only the two item lines change below `## Project Status`, and only by an appended note with the required words;
   - Questions equals the old block minus the two answered lines;
   - the three rows are flipped and placed as required, with the required words, and every other queue line is identical and in place;
   - every open ID is covered exactly once.

   The spec author has checked the script both ways. Run with unchanged `origin/main` as both files, it prints errors. Run against a simulated correct edit, it prints `ANSWERS_CHECK PASS`.

   ```python
   import re, sys
   old = open(sys.argv[1], encoding="utf-8").read().splitlines()
   new = open(sys.argv[2], encoding="utf-8").read().splitlines()
   err = []
   def blocks(t):
       return t.index("## Autonomous Queue"), t.index("## Questions for Şekip"), t.index("## Project Status")
   oqa, oqq, ops = blocks(old); nqa, nqq, nps = blocks(new)
   ID = r"SB-[A-Za-z0-9]+(?:-[A-Za-z0-9]+)*"
   # A. nothing outside the two blocks changes, except notes appended to two item lines
   if old[:oqa + 2] != new[:nqa + 2]: err.append("text before the queue rows changed")
   if old[oqq:oqq + 2] != new[nqq:nqq + 2]: err.append("Questions heading/comment changed")
   ot, nt = old[ops:], new[nps:]
   if len(ot) != len(nt): err.append("line count below Project Status changed")
   DEC = {"- [ ] SB-M51-005 ": ["English", "Turkish"],
          "- [ ] SB-M43-131 ": ["all-time", "weekly", "Monday 00:00 UTC", "booster"]}
   seen = set()
   for a, b in zip(ot, nt):
       if a == b: continue
       k = next((p for p in DEC if a.startswith(p)), None)
       if not k or not b.startswith(a): err.append("unexpected change below Project Status: " + a[:80]); continue
       seen.add(k)
       for w in DEC[k] + ["2026-10-22", "owner via factory dashboard"]:
           if w.lower() not in b[len(a):].lower(): err.append("%s note lacks %r" % (k.strip(), w))
   for k in DEC:
       if k not in seen: err.append("no decision note on " + k.strip())
   # B. Questions = old minus exactly the two answered lines
   oq, nq = old[oqq + 2:ops], new[nqq + 2:nps]
   gone = [l for l in oq if l.startswith("- SB-M51-005 ") or l.startswith("- SB-M43-131..133, SB-M56-011 ")]
   if len(gone) != 2 or nq != [l for l in oq if l not in gone]: err.append("Questions must equal old minus the two answered lines")
   # C. queue: three OWNER rows become READY, placed after the last old READY row, before OWNER rows
   def tok(l):
       m = re.match(r"- (READY|OWNER|DONE) (\S+) — \S", l); return m.groups() if m else (None, None)
   FLIP = ["SB-M51-005", "SB-M43-131..133", "SB-M56-011"]
   orows, nrows = old[oqa + 2:oqq], new[nqa + 2:nqq]
   kept = [l for l in orows if tok(l) not in [("OWNER", f) for f in FLIP]]
   if len(kept) != len(orows) - 3: err.append("the three OWNER rows were not in the old queue")
   flipped = [l for l in nrows if tok(l) in [("READY", f) for f in FLIP]]
   if len(flipped) != 3: err.append("expected 3 new READY rows, got %d" % len(flipped))
   if [l for l in nrows if l not in flipped] != kept: err.append("other queue lines changed or moved")
   last_ready = max(i for i, l in enumerate(kept) if tok(l)[0] == "READY")
   want_at = last_ready + 1
   got = [nrows.index(l) for l in flipped]
   if sorted(got) != [want_at, want_at + 1, want_at + 2]: err.append("new READY rows not right after the last old READY row")
   order = [tok(nrows[i])[1] for i in sorted(got)]
   if "SB-M43-131..133" in order and "SB-M56-011" in order and order.index("SB-M43-131..133") > order.index("SB-M56-011"):
       err.append("SB-M56-011 row must follow SB-M43-131..133 row")
   if want_at + 3 >= len(nrows) or tok(nrows[want_at + 3])[0] != "OWNER": err.append("first OWNER row must directly follow the new READY rows")
   NEED = {"SB-M51-005": ["English", "Turkish"], "SB-M43-131..133": ["all-time", "weekly", "Monday", "UTC"], "SB-M56-011": ["RANKS"]}
   for l in flipped:
       t = tok(l)[1]
       if len(l) > 200: err.append("row over 200 chars: " + t)
       for w in NEED[t] + ["2026-10-22"]:
           if w.lower() not in l.lower(): err.append("%s row lacks %r" % (t, w))
   # D. job 001 coverage rule: every open ID covered exactly once
   open_ids = [m.group(1) for l in new[nps:] for m in [re.match(r"\s*- \[ \] \**(" + ID + ")", l)] if m]
   openset = set(open_ids)
   def expand(tk):
       if ".." not in tk: return {tk} & openset
       a, b = tk.split(".."); m = re.match(r"(.*-)(\d+)$", a); p, lo = m.group(1), int(m.group(2))
       hi = int(re.search(r"(\d+)$", b).group(1))
       return {i for i in openset if re.fullmatch(re.escape(p) + r"\d+", i) and lo <= int(i[len(p):]) <= hi}
   cover = {}
   for l in nrows:
       toks = re.findall(ID + r"(?:\.\.[A-Za-z0-9-]+)?", l) if l.startswith("<!-- Not queued") else [tok(l)[1]] if tok(l)[0] else []
       for tk in toks:
           if tk == "REFRESH-QUEUE": continue
           for i in expand(tk): cover[i] = cover.get(i, 0) + 1
   for i in open_ids:
       if cover.get(i, 0) != 1: err.append("coverage %d: %s" % (cover.get(i, 0), i))
   print("open IDs:", len(open_ids), "queue lines:", len(nrows))
   print("\n".join(err) if err else "ANSWERS_CHECK PASS")
   ```

3. **The decisions are faithful.** The reviewer compares the SB-M43-131 note and the SB-M43-131..133 row with answers-snapshot.md. Both must say the following, and must add no metric, reward, season length, tie-break or backend detail that the owner did not state:
   - two tables;
   - all-time = highest campaign level reached;
   - weekly = levels completed that week, reset Monday 00:00 UTC;
   - nothing purchasable with money or boosters counts.

   The SB-M51-005 note and row name exactly English and Turkish, with no other language.
4. **The factory still reads the queue.** In `git -C <worktree> show HEAD:TASKS.md | head -80`, the first line matching `^- READY ` is still `- READY SB-M50-BOARD-001 — ...`.

## Out of scope

- Implementing Turkish localization, a Ranks screen, leaderboards, analytics, or any game code, data or tests.
- Ticking checkboxes, or editing Project Status, the Progress counter, other task items, other OWNER rows or the other 8 questions.
- Choosing a leaderboard backend or sign-in provider. That is a separate open question, SB-M43-153..160.
- Editing `factory/answers.md`. The orchestrator does that after merge.
- Writing a separate owner-decision doc, or editing CLAUDE.md, AGENTS.md, SKILL.md or docs. The policy text needed later is in the SB-M43-131 note.
- Committing the checker script.

## Assumptions

- **Record the decision as inline notes on SB-M51-005 and SB-M43-131 only.** SB-M43-131 is the RANKS policy item, and SB-M43-132/133/SB-M56-011 point to it. This is the smallest edit that keeps provenance on the item lines.
- **Keep the items unticked.** Recording a decision does not finish the work: Turkish locale, Ranks destination, visual master and analytics. Each READY job closes its item with evidence.
- **Put the new rows after `SB-M60-001..006`.** The task explicitly says new READY rows go after the existing READY rows. This overrides job 001's rule that M60 rows are the last READY rows, which is why the job 001 checker is not reused unchanged.
- **Put the SB-M56-011 row after SB-M43-131..133.** Rank-window analytics need the Ranks feature to exist.
- **Translate the owner's Turkish answer to English in TASKS.md.** The tracker is English. The meaning is taken from the task statement, which matches the original text.
- **Flag a possible later escalation.** A real online weekly or all-time leaderboard may need a backend or account provider (open question SB-M43-153..160), or new spending. If it does, the SB-M43-131..133 job escalates through the normal loop. This job does not decide it.
