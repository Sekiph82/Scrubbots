# Apply owner answers: cloud-save sign-in and Scrub Bucks packs

> Feature: OWNER-ANSWERS — apply the owner answers in the job folder's answers-snapshot.md (genuine owner input via the factory dashboard, in Turkish) to root TASKS.md per the "Owner answers first" step of .claude/skills/factory/SKILL.md. This is the same kind of job as 003; reuse its spec and checker approach: coordination/sessions/FACTORY/003-apply-owner-answers/spec.md. Two entries this time: (1) SB-M43-153..160, SB-M49-030, SB-M54-031 cloud save sign-in: Android Google Play Games Saved Games, iOS Game Center + iCloud, both free, no own backend, no separate account or e-mail login. (2) SB-M57-012 Scrub Bucks real-money packs: 5 packs $0.99→100, $4.99→550, $9.99→1200, $19.99→2600, $49.99→7000; product IDs scrubbucks_100, scrubbucks_550, ... pattern; amounts may be retuned after the M56 economy simulation. Record each decision (date 2026-10-22, "owner via factory dashboard"), translated faithfully, adding nothing. Remove the two answered question lines, flip the matching OWNER rows to READY after the existing READY rows and before remaining OWNER rows. Note §0D.5: actually publishing products in a production store / live release still needs the owner; deciding the ladder does not. If an item also depends on another still-open question (e.g. the IAP SDK question SB-M57-001..), keep that dependency stated in the row rather than inventing an answer. Builder edits only TASKS.md.

## Context

- **Owner input.** `factory/jobs/004-apply-owner-answers/answers-snapshot.md` in the main checkout holds exactly two answers. Both are dated 2026-10-22, entered by the owner through the factory dashboard, and written in Turkish. Faithful translations:
  - **SB-M43-153..160, SB-M49-030, SB-M54-031** (account/sign-in provider for cloud save): "On Android, Google Play Games Saved Games; on iOS, Game Center + iCloud. Both are free; we don't need our own server. There should be no separate account or e-mail login."
  - **SB-M57-012** (real-money Scrub Bucks packs): "5 packs: $0.99 → 100, $4.99 → 550, $9.99 → 1200, $19.99 → 2600, $49.99 → 7000. Product IDs follow the pattern scrubbucks_100, scrubbucks_550, … The amounts may be adjusted after the M56 economy simulation."
- **Procedure.** `.claude/skills/factory/SKILL.md` step 2, "Owner answers first":
  1. Record each decision in the matching TASKS.md items.
  2. Remove the question's line from `## Questions for Şekip`.
  3. Flip the matching `## Autonomous Queue` OWNER rows to READY, with the decision in the row text.

  After merge, the orchestrator removes the applied entries from `factory/answers.md`. The builder does not.
- **Precedent.** Job 003 did the same kind of edit (`coordination/sessions/FACTORY/003-apply-owner-answers/spec.md`). Its output is visible in root `TASKS.md`:
  - the READY rows `SB-M51-005`, `SB-M43-131..133` and `SB-M56-011`;
  - the inline `**[OWNER DECISION 2026-10-22, owner via factory dashboard: ...]**` note style.

  Reuse both. The checker below is job 003's checker, adapted to this job's IDs.
- **Where things are in root `TASKS.md` today.** These are worktree lines on fresh `origin/main` at f609a5be. Line numbers are approximate.
  - **`## Autonomous Queue`** (line 5).
    - The last READY row is `- READY SB-M56-011 — Events/Ranks analytics ...` (about line 95). It is followed directly by the first OWNER row, `- OWNER SB-M43-136..141 — ...`.
    - The OWNER rows to flip are:
      - `- OWNER SB-M43-153..160 — account/sign-in provider undecided; ...` (about line 99)
      - `- OWNER SB-M49-030 — account/cloud-conflict responsive screen waits on the account provider decision`
      - `- OWNER SB-M54-031 — cloud/account regression waits on the account provider decision`
      - `- OWNER SB-M57-012 — real-money Scrub Bucks packs and value ladder undecided` (about line 106)
  - **`## Questions for Şekip`** (about line 115). The two answered lines are:
    - `- SB-M43-153..160, SB-M49-030, SB-M54-031 — Which account/sign-in provider ...`
    - `- SB-M57-012 — Which real-money Scrub Bucks packs, product IDs and price ladder ...`
  - **Task items.**
    - about line 2255: `- [ ] SB-M43-153 Define optional account/sign-in provider strategy in an owner/platform decision before adding SDKs.` (SB-M43-155 is already `[x]`. The other items in the range are open.)
    - about line 2260: `- [ ] SB-M43-158 Platform purchase restore remains tied to M57/store authority ...`. This depends on the still-open ad/IAP provider question (SB-M57-001..).
    - about line 2604: SB-M49-030.
    - about line 2837: SB-M54-031.
    - about line 2936: `- [ ] SB-M57-012 Define Scrub Bucks real-money packs, localized store product IDs and value ladder in an owner decision before publishing cash prices.`
- **Still-open questions this job must not answer.**
  - `SB-M57-001..011, SB-M57-014..016, SB-M43-084, SB-M49-029` (ad/IAP provider/SDK). Wiring the packs into a store and SB-M43-158 restore both depend on it.
  - `SB-M57-013, SB-M43-081` (No Ads).

  Both question lines and their OWNER rows stay unchanged.
- **Queue rules from job 001** still apply:
  - row format `- <STATUS> <TOKEN> — <one line>`, at most 200 characters;
  - every open `- [ ] SB-...` ID is covered exactly once.

## Requirements

1. Only root `TASKS.md` changes. No game code, data, docs, tests or other files.
2. **SB-M43-153 item line.** Append one inline note to the existing line and leave the existing text unchanged. The note must contain:
   - `2026-10-22` and `owner via factory dashboard`;
   - `Google Play Games` `Saved Games` for Android;
   - `Game Center` + `iCloud` for iOS;
   - that both are `free`;
   - that no own `server` is needed;
   - that there is no separate account or `e-mail` login.

   Example: ` **[OWNER DECISION 2026-10-22, owner via factory dashboard: Android uses Google Play Games Saved Games; iOS uses Game Center + iCloud. Both are free; no own server needed. No separate account or e-mail login.]**`
3. **SB-M57-012 item line.** Append one inline note to the existing line and leave the existing text unchanged. The note must contain:
   - `2026-10-22` and `owner via factory dashboard`;
   - all five price → amount pairs: `$0.99` → 100, `$4.99` → `550`, `$9.99` → `1200`, `$19.99` → `2600`, `$49.99` → `7000`;
   - the product-ID pattern, naming `scrubbucks_100` and `scrubbucks_550`;
   - that the amounts may be retuned after the `M56` economy simulation.

   No other item lines change: not SB-M43-154..160, SB-M49-030 or SB-M54-031.
4. **Questions.** Remove exactly the two answered lines from `## Questions for Şekip`. The heading, the header comment and the other 6 question lines stay unchanged and in order.
5. **Queue rows.**
   - **Remove** the four OWNER rows `SB-M43-153..160`, `SB-M49-030`, `SB-M54-031` and `SB-M57-012`.
   - **Add** four READY rows with the same tokens, in exactly this order:
     1. `SB-M43-153..160`
     2. `SB-M49-030`
     3. `SB-M54-031`
     4. `SB-M57-012`
   - **Placement.** Insert the rows directly after `- READY SB-M56-011 — ...`, the last existing READY row, and directly before the first remaining OWNER row (`- OWNER SB-M43-136..141 — ...`).
   - **Every row** is at most 200 characters and contains `2026-10-22`.
   - **The SB-M43-153..160 row** names `Google Play Games`, `Game Center` and `iCloud`. It states that SB-M43-158 restore still waits on the open `M57` IAP provider question.
   - **The SB-M57-012 row:**
     - contains `$0.99`, `$49.99`, `scrubbucks_` and `M56`;
     - states that store wiring waits on `SB-M57-001`;
     - states that live store publishing still needs the `owner` (§0D.5).

   No other queue row or comment changes or moves.

   Example rows (each passes the checker):
   ```
   - READY SB-M43-153..160 — cloud save (owner 2026-10-22): Android Google Play Games Saved Games, iOS Game Center + iCloud; no own server/separate login; M43-158 restore also waits on SB-M57-001
   - READY SB-M49-030 — account/cloud-conflict responsive screen for the 2026-10-22 provider decision (Google Play Games / Game Center + iCloud)
   - READY SB-M54-031 — cloud/account regression for the 2026-10-22 provider decision (Google Play Games Saved Games / Game Center + iCloud)
   - READY SB-M57-012 — SB packs (owner 2026-10-22): $0.99→100 $4.99→550 $9.99→1200 $19.99→2600 $49.99→7000, IDs scrubbucks_<n>; retune after M56; store wiring waits SB-M57-001; live publish = owner
   ```
6. Do not tick any checkbox. All affected items stay `- [ ]`.
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
   - the four rows are flipped, placed and ordered as required, with the required words, and every other queue line is identical and in place;
   - every open ID is covered exactly once.

   The spec author has checked the script both ways:
   - with unchanged `origin/main` (f609a5be) as both files, it prints 7 errors;
   - against a simulated edit built from the requirement examples, it prints `open IDs: 357 queue lines: 108` and `ANSWERS_CHECK PASS`.

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
   DEC = {"- [ ] SB-M43-153 ": ["Google Play Games", "Saved Games", "Game Center", "iCloud", "free", "server", "e-mail"],
          "- [ ] SB-M57-012 ": ["$0.99", "$4.99", "$9.99", "$19.99", "$49.99", "550", "1200", "2600", "7000",
                                "scrubbucks_100", "scrubbucks_550", "M56"]}
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
   gone = [l for l in oq if l.startswith("- SB-M43-153..160, SB-M49-030, SB-M54-031 ") or l.startswith("- SB-M57-012 ")]
   if len(gone) != 2 or nq != [l for l in oq if l not in gone]: err.append("Questions must equal old minus the two answered lines")
   # C. queue: four OWNER rows become READY, placed after the last old READY row, before OWNER rows
   def tok(l):
       m = re.match(r"- (READY|OWNER|DONE) (\S+) — \S", l); return m.groups() if m else (None, None)
   FLIP = ["SB-M43-153..160", "SB-M49-030", "SB-M54-031", "SB-M57-012"]
   orows, nrows = old[oqa + 2:oqq], new[nqa + 2:nqq]
   kept = [l for l in orows if tok(l) not in [("OWNER", f) for f in FLIP]]
   if len(kept) != len(orows) - 4: err.append("the four OWNER rows were not in the old queue")
   flipped = [l for l in nrows if tok(l) in [("READY", f) for f in FLIP]]
   if len(flipped) != 4: err.append("expected 4 new READY rows, got %d" % len(flipped))
   if [l for l in nrows if l not in flipped] != kept: err.append("other queue lines changed or moved")
   last_ready = max(i for i, l in enumerate(kept) if tok(l)[0] == "READY")
   want_at = last_ready + 1
   got = sorted(nrows.index(l) for l in flipped)
   if got != list(range(want_at, want_at + 4)): err.append("new READY rows not right after the last old READY row")
   if [tok(nrows[i])[1] for i in got] != FLIP: err.append("new READY rows must be in order " + ", ".join(FLIP))
   if want_at + 4 >= len(nrows) or tok(nrows[want_at + 4])[0] != "OWNER": err.append("first OWNER row must directly follow the new READY rows")
   NEED = {"SB-M43-153..160": ["Google Play Games", "Game Center", "iCloud", "M57"],
           "SB-M49-030": [], "SB-M54-031": [],
           "SB-M57-012": ["$0.99", "$49.99", "scrubbucks_", "M56", "SB-M57-001", "owner"]}
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

3. **The decisions are faithful.** The reviewer compares the two notes and the four rows with answers-snapshot.md.
   - **Sign-in:**
     - Android = Google Play Games Saved Games;
     - iOS = Game Center + iCloud;
     - both free;
     - no own server;
     - no separate account or e-mail login.

     Nothing else is added, for example no conflict-policy, sync-frequency, Firebase or any other provider detail.
   - **Packs:**
     - exactly the five pairs ($0.99→100, $4.99→550, $9.99→1200, $19.99→2600, $49.99→7000);
     - the scrubbucks_<amount> ID pattern;
     - amounts retunable after the M56 simulation.

     Nothing else is added: no bonus labels, "best value" tags, regional prices or an ad/IAP SDK choice.
   - The still-open ad/IAP and No Ads questions are not answered anywhere.
4. **The factory still reads the queue.** In `git -C <worktree> show HEAD:TASKS.md | head -80`, the first line matching `^- READY ` is still `- READY SB-M50-BOARD-001 — ...`.

## Out of scope

- Implementing cloud save, Play Games/Game Center/iCloud plugins, store products, Shop cards or any game code, data or tests.
- Writing the pack ladder into `data/config/` or an economy doc. The SB-M57-012 READY job does that.
- Answering or touching the ad/IAP provider (SB-M57-001..), No Ads (SB-M57-013), world ranges, Friends, unlock pacing or ScrubBox questions, or their OWNER rows.
- Ticking checkboxes, or editing Project Status, the Progress counter or other task items.
- Editing `factory/answers.md`. The orchestrator does that after merge.
- Committing the checker script.

## Assumptions

- **Notes go on SB-M43-153 and SB-M57-012 only.** Those are the items that ask for the decision. SB-M43-154..160, SB-M49-030 and SB-M54-031 depend on SB-M43-153. This matches job 003, which noted only SB-M43-131.
- **"kendi sunucumuz gerekmez" is translated as "no own server needed".** It is the literal meaning. The task's "no own backend" says the same thing.
- **SB-M43-158 restore depends on the still-open IAP provider question.** The item text ties it to M57/store authority, so the SB-M43-153..160 row names that dependency and does not invent a provider.
- **The SB-M57-012 row says store wiring waits on SB-M57-001 and live publishing needs the owner.** The task asks for this, following the §0D.5 note that deciding the ladder does not authorize a production release.
- **Rows go in the order SB-M43-153..160, SB-M49-030, SB-M54-031, SB-M57-012.** This is question order. The account screen and regression rows follow the provider row they depend on.
- **Coordinator correction applied.** A mid-task message briefly added ad/IAP and No Ads answers and then withdrew them. The snapshot has exactly 2 entries (re-checked), so this spec covers only those two.
