# Apply owner answers: worlds, Friends, unlock levels, ScrubBox bonus

> Feature: OWNER-ANSWERS — apply the 4 owner answers in the job folder's answers-snapshot.md (genuine owner input via the factory dashboard) to root TASKS.md per the "Owner answers first" step of .claude/skills/factory/SKILL.md. Same kind of job as 005; reuse its spec/checker: coordination/sessions/FACTORY/005-apply-owner-answers/spec.md. Read the 4 answers from the snapshot verbatim: World ranges (20 named worlds × 150 levels = 3000 levels; record the full name/range table faithfully — owner gave ranges and names, NOT explicit completion conditions; if completion conditions are not stated, record only what was given and note the completion-condition detail as open, no new question unless an item cannot proceed), Friends scope, meta-feature unlock levels, ScrubBox surprise bonus = yes (note: owner's original question said "after the M56 economy simulation", keep that dependency). These answers clear all remaining Questions; after this job the `## Questions for Şekip` block should be empty (comment line kept). Flip matching OWNER rows to READY after existing READY rows. Builder edits only TASKS.md. Keep the spec short — this is the 4th job of the same shape.

## Context

- **Owner input:** `factory/jobs/006-apply-owner-answers/answers-snapshot.md` (main checkout), four answers dated 2026-10-22. Faithful translations:
  1. **SB-M43-136..141, SB-M43-073, SB-M54-032 (worlds):** World 01 Whispering Park 0001-0150; 02 Bubble District 0151-0300; 03 Neon Sewers 0301-0450; 04 Crystal Laundry 0451-0600; 05 Toxic Docks 0601-0750; 06 Clockwork Carnival 0751-0900; 07 Rustwood Railway 0901-1050; 08 Frostbyte Factory 1051-1200; 09 Midnight Metro 1201-1350; 10 Sunken Harbor 1351-1500; 11 Ember Foundry 1501-1650; 12 Mosslight Ruins 1651-1800; 13 Candy Circuit 1801-1950; 14 Stormglass Heights 1951-2100; 15 Phantom Museum 2101-2250; 16 Moonbeam Observatory 2251-2400; 17 Steamcloud Summit 2401-2550; 18 Prism Powerplant 2551-2700; 19 Shadowbyte Citadel 2701-2850; 20 Grimeheart Core 2851-3000. "Total: 20 worlds × 150 levels = 3,000 levels." No completion conditions given.
  2. **SB-M61-001..007 (Friends):** "After launch. Friend list from Play Games / Game Center, no chat. 1 Heart gift to each friend per day. No challenges in V1."
  3. **SB-M44-010, SB-M44-022..023 (unlocks):** "Hearts from the start. Boosters 6, 11, 16, 21. Daily Rewards 4, Shop 8, Tasks 12, Collection 20, Events 30, RANKS 40."
  4. **SB-M43-R09-006 (ScrubBox):** "yes" to the question "After the M56 economy simulation, should the earned ScrubBox get a small surprise bonus slot?"
- **Procedure:** `.claude/skills/factory/SKILL.md` step 2 "Owner answers first". Style precedent: job 005 (`coordination/sessions/FACTORY/005-apply-owner-answers/spec.md`). In root `TASKS.md` the decision goes in an inline note, `**[OWNER DECISION 2026-10-22, owner via factory dashboard: ...]**` (see `- [ ] SB-M57-001 ...`), and the queue rows use the style of the `READY SB-M51-005` .. `READY SB-M43-081` rows.
- **Root `TASKS.md` locations** (worktree at `origin/main` 581a7c94):
  - `## Autonomous Queue`: the last READY row is `- READY SB-M43-081 — ...` (line 101). After it come the seven OWNER rows (lines 102-108), in this order: `SB-M43-136..141`, `SB-M43-073`, `SB-M54-032`, `SB-M61-001..007`, `SB-M44-010`, `SB-M44-022..023`, `SB-M43-R09-006`. Then the `<!-- Not queued ... -->` comment.
  - `## Questions for Şekip` (line 111): heading, comment, then the four question lines being answered.
  - Item lines for the notes: `- [ ] SB-M43-136 ...` (~2217), `- [ ] SB-M61-001 ...` (~2996), `- [ ] SB-M44-010 ...` (~2349), `- [ ] SB-M43-R09-006 ...` (~2185).
- Queue rules from job 001 still apply. Row format is `- <STATUS> <TOKEN> — <one line>`, at most 200 characters, and every open `- [ ] SB-...` ID is covered exactly once.

## Requirements

1. Only root `TASKS.md` changes.
2. **Append one inline note to each of four item lines**, leaving the existing text unchanged. Each note contains `2026-10-22` and `owner via factory dashboard`.
   - `SB-M43-136`: the full 20-row table, with each world as `World NN <Name> <first>-<last>` (zero-padding optional; `-`, `–`, `/` or `..` allowed as the separator), plus the total (`20` worlds × `150` levels = `3000`). It must also include an `Open detail:` saying the owner gave names and ranges only, not `completion` conditions.
   - `SB-M61-001`: `after launch`, friend list from `Play Games` / `Game Center`, `no chat`, `1 Heart` gift to each friend `per day`, no `challenges` in `V1`.
   - `SB-M44-010`: `Hearts` from the `start`, `Boosters` at `6, 11, 16, 21`, `Daily Rewards 4`, `Shop 8`, `Tasks 12`, `Collection 20`, `Events 30`, `RANKS 40`. It must also include an `Open detail:` saying the owner did not give which booster unlocks at which level, or unlock points for `Card Packs`, `Robots`, `Gift Meter`/Gift Bar and `Achievements`.
   - `SB-M43-R09-006`: `yes`, a small `surprise bonus` slot, enabled after the `M56` economy simulation.
   No other line below `## Project Status` changes. Do not change SB-M43-137..141, SB-M43-073, SB-M54-032, SB-M61-002..007, SB-M44-011/022/023, and do not tick any checkbox.
3. **Questions:** remove all four question lines. The heading and the `<!-- One line per question ... -->` comment stay, and the block holds no question lines. Add no new question.
4. **Queue:** replace the seven OWNER rows with seven READY rows that use the same tokens in the same order, directly after `- READY SB-M43-081 — ...`. No OWNER row remains. Every row is at most 200 characters and contains `2026-10-22`. Required words per row (case-insensitive):
   - `SB-M43-136..141`: `20`, `150`, `3000`, `completion` (still open)
   - `SB-M43-073`, `SB-M54-032`: `20`, `150`
   - `SB-M61-001..007`: `post-launch`, `Play Games`, `Game Center`, `no chat`, `1 Heart`, `no challenges`
   - `SB-M44-010`: `Hearts`, `6/11/16/21`, `Daily Rewards 4`, `Shop 8`, `Tasks 12`, `Collection 20`, `Events 30`, `RANKS 40`
   - `SB-M44-022..023`: `Collection 20`, `Tasks 12`, `Events 30`
   - `SB-M43-R09-006`: `yes`, `M56`
5. No other queue row or comment changes or moves. Coverage stays exactly-once.

Example notes and rows (a simulated edit built from these passes the checker):
```
SB-M43-136 note: **[OWNER DECISION 2026-10-22, owner via factory dashboard: World 01 Whispering Park 0001-0150; World 02 Bubble District 0151-0300; ... ; World 20 Grimeheart Core 2851-3000. Total: 20 worlds x 150 levels = 3000 levels. Open detail: the owner gave names and level ranges only, not completion conditions.]**
SB-M61-001 note: **[OWNER DECISION 2026-10-22, owner via factory dashboard: After launch. Friend list comes from Play Games / Game Center, no chat. Each friend can be gifted 1 Heart per day. No challenges in V1.]**
SB-M44-010 note: **[OWNER DECISION 2026-10-22, owner via factory dashboard: Hearts from the start. Boosters at levels 6, 11, 16, 21. Daily Rewards 4, Shop 8, Tasks 12, Collection 20, Events 30, RANKS 40. Open detail: which booster unlocks at which of 6/11/16/21, and unlock points for Card Packs, Robots, Gift Meter/Gift Bar and Achievements, were not given.]**
SB-M43-R09-006 note: **[OWNER DECISION 2026-10-22, owner via factory dashboard: yes, the earned ScrubBox gets a small surprise bonus slot, enabled after the M56 economy simulation.]**
- READY SB-M43-136..141 — worlds (owner 2026-10-22): 20 named worlds x 150 levels = 3000, full table on SB-M43-136; completion conditions still open
- READY SB-M43-073 — world unlock ceremony for the 2026-10-22 owner world table (20 worlds x 150 levels)
- READY SB-M54-032 — world regression for the 2026-10-22 owner world table (20 worlds x 150 levels, 1-3000)
- READY SB-M61-001..007 — Friends (owner 2026-10-22): post-launch; list from Play Games / Game Center; no chat; 1 Heart gift per friend per day; no challenges in V1
- READY SB-M44-010 — unlocks (owner 2026-10-22): Hearts from start, boosters 6/11/16/21, Daily Rewards 4, Shop 8, Tasks 12, Collection 20, Events 30, RANKS 40
- READY SB-M44-022..023 — Collection onboarding and retention unlocks per the 2026-10-22 owner table (Collection 20, Tasks 12, Events 30)
- READY SB-M43-R09-006 — ScrubBox surprise bonus slot: owner said yes (2026-10-22); enable only after the M56 economy simulation
```

## Acceptance criteria

1. **Diff scope:** in the worktree, `git diff --name-only origin/main...HEAD` prints exactly `TASKS.md`, `git diff --check origin/main...HEAD` prints nothing, and `git status --short` is clean after the commit.
2. **Checker passes:** save the script below outside the worktree (e.g. `<scratch>/check_answers.py`; do not commit it), then run `cd <worktree> && git show origin/main:TASKS.md > <scratch>/old.md && python -I <scratch>/check_answers.py <scratch>/old.md TASKS.md`. The last line printed must be `ANSWERS_CHECK PASS`. The spec author checked both directions. With unchanged `origin/main` (581a7c94) as both files it prints 10 errors. On the simulated edit from the examples it prints `open IDs: 357 queue lines: 108`, then `ANSWERS_CHECK PASS`.

   ```python
   import re, sys
   old = open(sys.argv[1], encoding="utf-8").read().splitlines()
   new = open(sys.argv[2], encoding="utf-8").read().splitlines()
   err = []
   def blocks(t):
       return t.index("## Autonomous Queue"), t.index("## Questions for Şekip"), t.index("## Project Status")
   oqa, oqq, ops = blocks(old); nqa, nqq, nps = blocks(new)
   ID = r"SB-[A-Za-z0-9]+(?:-[A-Za-z0-9]+)*"
   WORLDS = ["Whispering Park", "Bubble District", "Neon Sewers", "Crystal Laundry", "Toxic Docks", "Clockwork Carnival",
             "Rustwood Railway", "Frostbyte Factory", "Midnight Metro", "Sunken Harbor", "Ember Foundry", "Mosslight Ruins",
             "Candy Circuit", "Stormglass Heights", "Phantom Museum", "Moonbeam Observatory", "Steamcloud Summit",
             "Prism Powerplant", "Shadowbyte Citadel", "Grimeheart Core"]
   # A. nothing outside the two blocks changes, except notes appended to four item lines
   if old[:oqa + 2] != new[:nqa + 2]: err.append("text before the queue rows changed")
   if old[oqq:oqq + 2] != new[nqq:nqq + 2]: err.append("Questions heading/comment changed")
   ot, nt = old[ops:], new[nps:]
   if len(ot) != len(nt): err.append("line count below Project Status changed")
   DEC = {"- [ ] SB-M43-136 ": WORLDS + ["20", "150", "3000", "Open detail", "completion"],
          "- [ ] SB-M61-001 ": ["after launch", "Play Games", "Game Center", "no chat", "1 Heart", "per day", "challenges", "V1"],
          "- [ ] SB-M44-010 ": ["Hearts", "start", "Boosters", "6, 11, 16, 21", "Daily Rewards 4", "Shop 8", "Tasks 12",
                                "Collection 20", "Events 30", "RANKS 40", "Open detail", "Card Packs", "Robots",
                                "Gift Meter", "Achievements"],
          "- [ ] SB-M43-R09-006 ": ["yes", "surprise bonus", "M56"]}
   seen = set()
   for a, b in zip(ot, nt):
       if a == b: continue
       k = next((p for p in DEC if a.startswith(p)), None)
       if not k or not b.startswith(a): err.append("unexpected change below Project Status: " + a[:80]); continue
       seen.add(k); note = b[len(a):]
       for w in DEC[k] + ["2026-10-22", "owner via factory dashboard"]:
           if w.lower() not in note.lower(): err.append("%s note lacks %r" % (k.strip(), w))
       if k == "- [ ] SB-M43-136 ":
           for n in range(20):
               lo, hi = n * 150 + 1, n * 150 + 150
               if not re.search(r"World 0?%d\b" % (n + 1), note): err.append("world note lacks World %02d" % (n + 1))
               if not re.search(r"\b0*%d\s*(?:-|–|/|\.\.)\s*0*%d\b" % (lo, hi), note): err.append("world note lacks range %d-%d" % (lo, hi))
   for k in DEC:
       if k not in seen: err.append("no decision note on " + k.strip())
   # B. Questions block now holds no question lines (blank lines only)
   oq, nq = old[oqq + 2:ops], new[nqq + 2:nps]
   if len([l for l in oq if l.startswith("- SB-")]) != 4: err.append("old Questions did not have the 4 answered lines")
   if nq != [l for l in oq if not l.startswith("- ")]: err.append("Questions must be empty (heading + comment kept)")
   # C. queue: seven OWNER rows become READY right after the last READY row; nothing else changes
   def tok(l):
       m = re.match(r"- (READY|OWNER|DONE) (\S+) — \S", l); return m.groups() if m else (None, None)
   FLIP = ["SB-M43-136..141", "SB-M43-073", "SB-M54-032", "SB-M61-001..007", "SB-M44-010", "SB-M44-022..023", "SB-M43-R09-006"]
   orows, nrows = old[oqa + 2:oqq], new[nqa + 2:nqq]
   kept = [l for l in orows if tok(l) not in [("OWNER", f) for f in FLIP]]
   if len(kept) != len(orows) - len(FLIP): err.append("the seven OWNER rows were not in the old queue")
   flipped = [l for l in nrows if tok(l) in [("READY", f) for f in FLIP]]
   if len(flipped) != len(FLIP): err.append("expected %d new READY rows, got %d" % (len(FLIP), len(flipped)))
   rest = [l for l in nrows if l not in flipped]
   if rest != kept: err.append("other queue lines changed, added, removed or moved")
   if any(tok(l)[0] == "OWNER" for l in nrows): err.append("an OWNER row remains")
   last_ready = max(i for i, l in enumerate(kept) if tok(l)[0] == "READY")
   got = sorted(nrows.index(l) for l in flipped)
   if got != list(range(last_ready + 1, last_ready + 1 + len(FLIP))): err.append("new READY rows not right after the last old READY row")
   if [tok(nrows[i])[1] for i in got] != FLIP: err.append("new READY rows must be in order " + ", ".join(FLIP))
   NEED = {"SB-M43-136..141": ["20", "150", "3000", "completion"],
           "SB-M43-073": ["20", "150"],
           "SB-M54-032": ["20", "150"],
           "SB-M61-001..007": ["post-launch", "Play Games", "Game Center", "no chat", "1 Heart", "no challenges"],
           "SB-M44-010": ["Hearts", "6/11/16/21", "Daily Rewards 4", "Shop 8", "Tasks 12", "Collection 20", "Events 30", "RANKS 40"],
           "SB-M44-022..023": ["Collection 20", "Tasks 12", "Events 30"],
           "SB-M43-R09-006": ["yes", "M56"]}
   for l in flipped:
       t = tok(l)[1]
       if len(l) > 200: err.append("row over 200 chars (%d): %s" % (len(l), t))
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
3. **Faithfulness:** the reviewer compares the four notes and seven rows against answers-snapshot.md. All 20 world names and ranges must match exactly. Friends must say post-launch, Play Games/Game Center list, no chat, 1 Heart per friend per day, and no challenges in V1. The unlock levels must match exactly. The ScrubBox answer must be yes, keeping the M56 dependency. Nothing may be invented: no completion conditions, no booster-to-level mapping, no unlock levels for unnamed features, no friend-gift caps, rewards or cross-platform rules, and no ScrubBox bonus odds or contents.
4. **Factory still reads the queue:** in `git -C <worktree> show HEAD:TASKS.md | head -80`, the first line matching `^- READY ` is still `- READY SB-M50-BOARD-001 — ...`.

## Out of scope

- Any code, data (`data/config/`, world registry, unlock tables), tests, art or docs. The READY jobs do that.
- Changing CLAUDE.md, `coordination/OWNER_ECONOMY_REWARDS_V01.md` or `coordination/OWNER_DIFFICULTY_PROGRESSION_DECISION_V01.md`.
- Touching other READY rows, ticking checkboxes, or editing the Project Status block or progress counter.
- Editing `factory/answers.md` (the orchestrator does it after merge) or committing the checker.

## Assumptions

- **Notes go only on the decision items (SB-M43-136, SB-M61-001, SB-M44-010, SB-M43-R09-006).** The other items depend on them, which is the same pattern as jobs 003-005.
- **The world completion condition and the booster-to-level / unnamed-feature unlocks are recorded as `Open detail`, with no Questions line.** The task says so. The rows can still proceed using level ranges and the named levels, and the implementer can escalate.
- **SB-M44-023's features (Daily Scrub Orders, Weekly Cleaning Event, First-Try Cleanup) are not mapped to the owner's "Tasks"/"Events" in TASKS.md.** That mapping is an implementation decision for the SB-M44 job, which must keep it data-driven (SB-M44-011).
- **SB-M43-R09-006 becomes READY even though M56 has not run.** The owner's "yes" answers the question, and the row keeps "only after the M56 economy simulation" as the gate.
- **Row order follows the old OWNER row order.** This keeps the diff minimal.
