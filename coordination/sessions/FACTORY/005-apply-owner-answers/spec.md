# Apply owner answers: ad/IAP provider and No Ads

> Feature: OWNER-ANSWERS — apply the 2 owner answers in the job folder's answers-snapshot.md (genuine owner input via the factory dashboard, Turkish) to root TASKS.md per the "Owner answers first" step of .claude/skills/factory/SKILL.md. Same kind of job as 004; reuse its spec/checker: coordination/sessions/FACTORY/004-apply-owner-answers/spec.md. Entries: (1) SB-M57-001..011, SB-M57-014..016, SB-M43-084, SB-M49-029 ad/IAP provider: Google AdMob single SDK; persistent bottom banner on every screen in the existing ad band area, never over the board; interstitial full-screen ad once every 5 plays, between levels, never during gameplay; rewarded video only if the player chooses, for a reward. IAP: Google Play Billing (Android) + Apple StoreKit (iOS). (2) SB-M57-013, SB-M43-081 No Ads: one-time $4.99, removes the bottom banner and the every-5-plays interstitials; rewarded videos stay. This is an explicit owner decision that authorizes banner + interstitial ads for these items. Record faithfully, add nothing. Owner did not specify what counts as a "play" (any finished level vs wins only) — record that as an open detail in the relevant row/note, do not invent; do NOT add a new Questions line for it unless the item cannot proceed without it (the implementer can escalate later). Now that SB-M57-001 is answered, rows that earlier said "waits on SB-M57-001" (e.g. SB-M43-153..160 restore, SB-M57-012 store wiring) may drop that dependency note; keep §0D.5 live-store-release gate wording. Remove the 2 answered question lines; flip matching OWNER rows to READY after existing READY rows and before remaining OWNER rows. Builder edits only TASKS.md.

## Context

- **Owner input.** `factory/jobs/005-apply-owner-answers/answers-snapshot.md` (main checkout) has exactly two answers, both dated 2026-10-22 and written in Turkish through the factory dashboard. Faithful translations:
  - **SB-M57-001..011, SB-M57-014..016, SB-M43-084, SB-M49-029** (ad/IAP provider): "Ads: Google AdMob (single SDK). 1) A continuously rotating banner at the bottom of every screen (the existing ad band area); it does not overlap the game board. 2) Full-screen interstitial ad: once every 5 plays, between levels, never during gameplay. 3) Rewarded video: only if the player wants it, with a reward in return. IAP: Google Play Billing (Android) + Apple StoreKit (iOS)."
  - **SB-M57-013, SB-M43-081** (No Ads): "No Ads is a one-time $4.99 purchase: it removes the bottom banner and the interstitial ads that appear every 5 plays. Rewarded videos stay."
- **Procedure.** `.claude/skills/factory/SKILL.md` step 2 "Owner answers first": record each decision in the matching TASKS.md items, remove the question line from `## Questions for Şekip`, flip the matching `## Autonomous Queue` OWNER rows to READY with the decision in the row. The orchestrator, not the builder, later edits `factory/answers.md`.
- **Precedent.** Jobs 003 and 004 (`coordination/sessions/FACTORY/004-apply-owner-answers/spec.md`). Their output in root `TASKS.md` sets the style to reuse:
  - inline item note `**[OWNER DECISION 2026-10-22, owner via factory dashboard: ...]**` (see `- [ ] SB-M43-153 ...` and `- [ ] SB-M57-012 ...`);
  - READY rows `SB-M51-005` .. `SB-M57-012` placed after the older READY rows.
  The checker below is job 004's checker adapted to this job.
- **Where things are in root `TASKS.md`** (worktree on `origin/main` 6479a781; line numbers approximate):
  - `## Autonomous Queue` (line 5). Last READY row: `- READY SB-M57-012 — SB packs ...` (about line 99), directly followed by the first OWNER row `- OWNER SB-M43-136..141 — ...`.
  - OWNER rows to flip (about lines 103-108), in current order: `SB-M57-001..011`, `SB-M57-014..016`, `SB-M43-084`, `SB-M49-029`, `SB-M57-013`, `SB-M43-081`.
  - Existing READY rows that name the now-answered provider question and become stale:
    - `- READY SB-M43-153..160 — ... M43-158 restore also waits on SB-M57-001` (about line 96);
    - `- READY SB-M57-012 — ... store wiring waits SB-M57-001; live publish = owner` (about line 99);
    - `- READY SB-M57-022 — sandbox purchases/rewarded ads on real Android (later iOS); escalates if the provider is still undecided` (about line 88).
  - `## Questions for Şekip` (about line 115). The two answered lines: `- SB-M57-001..011, SB-M57-014..016, SB-M43-084, SB-M49-029 — Which rewarded-ad and IAP provider/SDK ...` and `- SB-M57-013, SB-M43-081 — What should the No Ads product remove, and at what price?`.
  - Task items: `- [ ] SB-M57-001 Choose/approve rewarded-ad and IAP provider/platform architecture; no SDK before owner approval.` (about line 2927) and `- [ ] SB-M57-013 Define No Ads product and exactly which ad surfaces it removes; ...` (about line 2939).
- **Related existing UI.** Home already has a dedicated `AdBannerSlot` below BottomNav (`coordination/OWNER_M42_HOME_REBUILD_V04_SINGLE_WORLD_BACKGROUND.md` item 81-82, sizing in `OWNER_M42_HOME_POLISH_V06.md`/`V07`); that is the "existing ad band area". Gameplay composition docs (`coordination/OWNER_GAMEPLAY_SCREEN_COMPOSITION_V02.md`) show no ad banner in the current reference image. This job only records the decision; reconciling those layouts belongs to the READY SB-M57/SB-M49 jobs.
- **Queue rules from job 001** still apply: row format `- <STATUS> <TOKEN> — <one line>`, at most 200 characters; every open `- [ ] SB-...` ID covered exactly once.

## Requirements

1. Only root `TASKS.md` changes.
2. **SB-M57-001 item line.** Append one inline note; existing text unchanged. The note contains `2026-10-22`, `owner via factory dashboard`, and faithfully: `Google AdMob` (`single SDK`); a banner at the `bottom of every screen` in the existing `ad band` area that never overlaps the game `board`; a full-screen `interstitial` once `every 5 plays`, `between levels`, `never during gameplay`; `rewarded video` only if the `player` chooses, for a `reward`; IAP `Google Play Billing` (`Android`) + Apple `StoreKit` (`iOS`); and an `Open detail:` stating the owner did not specify what `counts as` a "play" (any finished level vs wins only).
   Example: ` **[OWNER DECISION 2026-10-22, owner via factory dashboard: Ads: Google AdMob (single SDK). 1) A continuously rotating banner at the bottom of every screen (the existing ad band area); it never overlaps the game board. 2) Full-screen interstitial ad: once every 5 plays, between levels, never during gameplay. 3) Rewarded video: only if the player chooses, in exchange for a reward. IAP: Google Play Billing (Android) + Apple StoreKit (iOS). Open detail: the owner did not specify what counts as a "play" (any finished level vs wins only).]**`
3. **SB-M57-013 item line.** Append one inline note; existing text unchanged. Contains `2026-10-22`, `owner via factory dashboard`, `one-time`, `$4.99`, removes the `bottom banner` and the `interstitial` ads shown `every 5 plays`, `Rewarded videos stay`.
   Example: ` **[OWNER DECISION 2026-10-22, owner via factory dashboard: No Ads is a one-time $4.99 purchase; it removes the bottom banner and the interstitial ads shown every 5 plays. Rewarded videos stay.]**`
   No other item line below `## Project Status` changes (not SB-M57-002..011/014..016, SB-M43-081/084/158, SB-M49-029).
4. **Questions.** Remove exactly the two answered lines. Heading, header comment and the other 4 lines stay unchanged and in order. No new question line (the "play" definition is recorded as an open detail, not asked).
5. **New READY rows.** Remove the six OWNER rows listed in Context and add six READY rows with the same tokens, in this order: `SB-M57-001..011`, `SB-M57-014..016`, `SB-M43-084`, `SB-M49-029`, `SB-M57-013`, `SB-M43-081`; directly after `- READY SB-M57-012 — ...` and directly before `- OWNER SB-M43-136..141 — ...`. Every row is at most 200 characters and contains `2026-10-22`. Required words per row (case-insensitive):
   - `SB-M57-001..011`: `AdMob`, `banner`, `board`, `interstitial`, `5 plays`, `between levels`, `rewarded`, `counts as a play` (the open detail);
   - `SB-M57-014..016` and `SB-M43-084`: `Play Billing`, `StoreKit`, `owner` (live store release still needs the owner, §0D.5);
   - `SB-M49-029`: `AdMob`;
   - `SB-M57-013`: `one-time`, `$4.99`, `banner`, `interstitial`, `rewarded`;
   - `SB-M43-081`: `$4.99`.
6. **Rewrite three stale READY rows in place** (same token, same position, still READY): `SB-M43-153..160`, `SB-M57-012`, `SB-M57-022`. Each drops its SB-M57-001 / "undecided" dependency (must not contain `SB-M57-001` or `undecided`), names the chosen IAP (`StoreKit`, and for SB-M57-022 also `AdMob` and `Play Billing`), contains `2026-10-22`, and is at most 200 characters. `SB-M43-153..160` keeps `Google Play Games`, `Game Center`, `iCloud`. `SB-M57-012` keeps `$0.99`, `$49.99`, `scrubbucks_`, `M56` and the live-publish `owner` gate.
7. No other queue row or comment changes or moves. No checkbox is ticked. Coverage stays exactly-once.

Example rows (all pass the checker):
```
- READY SB-M57-001..011 — ads (owner 2026-10-22): AdMob only; bottom banner in ad band, never over board; interstitial every 5 plays between levels; opt-in rewarded; what counts as a play is open
- READY SB-M57-014..016 — purchase/receipt/restore (owner 2026-10-22): Google Play Billing (Android) + Apple StoreKit (iOS); live store release = owner (§0D.5)
- READY SB-M43-084 — Shop real-money cards/prices/restore via Google Play Billing + StoreKit (owner 2026-10-22); live store release = owner
- READY SB-M49-029 — ad/store return-transition layout check for AdMob + Play Billing/StoreKit (owner 2026-10-22)
- READY SB-M57-013 — No Ads (owner 2026-10-22): one-time $4.99, removes bottom banner + every-5-plays interstitials; rewarded videos stay
- READY SB-M43-081 — Shop No Ads entry for the 2026-10-22 No Ads product ($4.99 one-time; rewarded videos stay)
- READY SB-M43-153..160 — cloud save (owner 2026-10-22): Android Google Play Games Saved Games, iOS Game Center + iCloud; no own server/separate login; M43-158 restore via Play Billing/StoreKit
- READY SB-M57-012 — SB packs (owner 2026-10-22): $0.99→100 $4.99→550 $9.99→1200 $19.99→2600 $49.99→7000, IDs scrubbucks_<n>; retune after M56; Play Billing/StoreKit; live publish = owner
- READY SB-M57-022 — sandbox purchases/rewarded ads on real Android (later iOS) with AdMob + Play Billing/StoreKit (owner 2026-10-22)
```

## Acceptance criteria

1. **Diff scope.** In the worktree: `git diff --name-only origin/main...HEAD` prints exactly `TASKS.md`; `git diff --check origin/main...HEAD` prints nothing; `git status --short` is clean after the commit.
2. **Checker passes.** Save the script below outside the worktree (e.g. `<scratch>/check_answers.py`; do not commit it) and run:
   ```
   cd <worktree> && git show origin/main:TASKS.md > <scratch>/old.md && python -I <scratch>/check_answers.py <scratch>/old.md TASKS.md
   ```
   The last line printed must be `ANSWERS_CHECK PASS`. Spec author verified both ways: unchanged `origin/main` (6479a781) as both files prints 16 errors; a simulated edit built from the examples above prints `open IDs: 357 queue lines: 108` then `ANSWERS_CHECK PASS`.

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
   DEC = {"- [ ] SB-M57-001 ": ["Google AdMob", "single SDK", "banner", "bottom of every screen", "ad band", "board",
                               "interstitial", "every 5 plays", "between levels", "never during gameplay",
                               "rewarded video", "player", "reward", "Google Play Billing", "Android", "StoreKit", "iOS",
                               "Open detail", "counts as"],
          "- [ ] SB-M57-013 ": ["one-time", "$4.99", "bottom banner", "interstitial", "every 5 plays", "rewarded videos stay"]}
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
   gone = [l for l in oq if l.startswith("- SB-M57-001..011, SB-M57-014..016, SB-M43-084, SB-M49-029 ") or l.startswith("- SB-M57-013, SB-M43-081 ")]
   if len(gone) != 2 or nq != [l for l in oq if l not in gone]: err.append("Questions must equal old minus the two answered lines")
   # C. queue: six OWNER rows become READY after the last old READY row; three READY rows rewritten in place
   def tok(l):
       m = re.match(r"- (READY|OWNER|DONE) (\S+) — \S", l); return m.groups() if m else (None, None)
   FLIP = ["SB-M57-001..011", "SB-M57-014..016", "SB-M43-084", "SB-M49-029", "SB-M57-013", "SB-M43-081"]
   REWRITE = ["SB-M43-153..160", "SB-M57-012", "SB-M57-022"]
   orows, nrows = old[oqa + 2:oqq], new[nqa + 2:nqq]
   kept = [l for l in orows if tok(l) not in [("OWNER", f) for f in FLIP]]
   if len(kept) != len(orows) - len(FLIP): err.append("the six OWNER rows were not in the old queue")
   flipped = [l for l in nrows if tok(l) in [("READY", f) for f in FLIP]]
   if len(flipped) != len(FLIP): err.append("expected %d new READY rows, got %d" % (len(FLIP), len(flipped)))
   rest = [l for l in nrows if l not in flipped]
   if len(rest) != len(kept): err.append("other queue lines added or removed")
   else:
       for a, b in zip(kept, rest):
           if a == b: continue
           if tok(a) == tok(b) and tok(a)[0] == "READY" and tok(a)[1] in REWRITE: continue
           err.append("queue line changed or moved: " + a[:70])
   rewritten = {tok(l)[1]: l for l in rest if tok(l)[0] == "READY" and tok(l)[1] in REWRITE}
   last_ready = max(i for i, l in enumerate(kept) if tok(l)[0] == "READY")
   want_at = last_ready + 1
   got = sorted(nrows.index(l) for l in flipped)
   if got != list(range(want_at, want_at + len(FLIP))): err.append("new READY rows not right after the last old READY row")
   if [tok(nrows[i])[1] for i in got] != FLIP: err.append("new READY rows must be in order " + ", ".join(FLIP))
   if want_at + len(FLIP) >= len(nrows) or tok(nrows[want_at + len(FLIP)])[0] != "OWNER": err.append("first OWNER row must directly follow the new READY rows")
   NEED = {"SB-M57-001..011": ["AdMob", "banner", "board", "interstitial", "5 plays", "between levels", "rewarded", "counts as a play"],
           "SB-M57-014..016": ["Play Billing", "StoreKit", "owner"],
           "SB-M43-084": ["Play Billing", "StoreKit", "owner"],
           "SB-M49-029": ["AdMob"],
           "SB-M57-013": ["one-time", "$4.99", "banner", "interstitial", "rewarded"],
           "SB-M43-081": ["$4.99"],
           "SB-M43-153..160": ["Google Play Games", "Game Center", "iCloud", "StoreKit"],
           "SB-M57-012": ["$0.99", "$49.99", "scrubbucks_", "M56", "StoreKit", "owner"],
           "SB-M57-022": ["AdMob", "Play Billing", "StoreKit"]}
   for t in REWRITE:
       if t not in rewritten: err.append("rewritten row missing: " + t)
       elif "SB-M57-001" in rewritten[t] or "undecided" in rewritten[t]: err.append(t + " row still waits on the provider question")
   for l in flipped + list(rewritten.values()):
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
3. **Faithfulness.** The reviewer compares the two notes and the nine rows with answers-snapshot.md: AdMob single SDK; bottom banner on every screen in the existing ad band, never over the board; interstitial once every 5 plays, between levels, never during gameplay; rewarded video opt-in for a reward; IAP Google Play Billing + Apple StoreKit; No Ads one-time $4.99 removing banner + interstitials, rewarded videos stay; "play" left undefined as an open detail. Nothing invented: no ad unit IDs, frequency caps beyond "every 5 plays", mediation networks, consent SDK, No Ads product ID, regional prices, or a definition of "play". No new Questions line.
4. **Factory still reads the queue.** In `git -C <worktree> show HEAD:TASKS.md | head -80`, the first line matching `^- READY ` is still `- READY SB-M50-BOARD-001 — ...`.

## Out of scope

- Any SDK/plugin integration, ad placements, store products, Shop/No Ads UI, game code, data, tests or docs.
- Editing CLAUDE.md §15, `coordination/OWNER_ECONOMY_REWARDS_V01.md`, gameplay composition docs or `data/config/` to reflect the ad decision; the READY SB-M57/SB-M49 jobs do that.
- Answering or touching the world-range, Friends, unlock-pacing or ScrubBox questions or their OWNER rows.
- Changing other READY rows beyond the three named in requirement 6, ticking checkboxes, or editing Project Status / Progress counter.
- Editing `factory/answers.md` (orchestrator does it after merge) or committing the checker.

## Assumptions

- **Notes go on SB-M57-001 and SB-M57-013 only.** Those items ask for the decision; the other items in the ranges depend on them. Same pattern as jobs 003/004.
- **"sürekli dönen banner" is translated "continuously rotating banner", "her 5 oynamada bir" as "once every 5 plays".** Literal meaning; matches the task's wording.
- **The "play" ambiguity is recorded as an `Open detail` in the SB-M57-001 note and the SB-M57-001..011 row, with no Questions line.** The task says so; the implementer can escalate.
- **SB-M57-022's "escalates if the provider is still undecided" is also stale and is rewritten.** The task's "e.g." list is not exhaustive and that clause now points at an answered question.
- **SB-M57-014..016 and SB-M43-084 rows carry the live-store-release owner gate.** They wire real purchases; §0D.5 still reserves a public production release for the owner.
- **The banner-on-every-screen vs gameplay-composition V02 (no banner in current reference) difference is left to the implementing jobs.** This job records decisions only; the owner's "never over the board" constraint is recorded verbatim.
- **Row order follows the old OWNER row order.** Keeps the diff minimal and matches the question order.
