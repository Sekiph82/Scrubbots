# M43-C005F-PHASE4 — Gameplay→Results + Home State-Change Micro Feel — MASTER CLAUDE PROMPT V01

Repository: `Sekiph82/Scrubbots`
Persistent owner checkout: `C:\Users\sekip\Desktop\ScrubBots`
Engine: Godot 4.7.2
Date: 2026-10-09

## Authorized scope

Execute exactly these two open children as one continuous milestone:

1. `SB-M43-C005F-010` — Gameplay-complete → Results presentation bridge
2. `SB-M43-C005F-012` — Home / Results-momentum micro feedback without refresh spam

Do NOT execute F007, F011 or F015 in this milestone.

This is an isolated ScrubBots presentation lane. Remote Level Update / R2 / Family APK remains the primary critical path and must not be modified.

Root `TASKS.md` is READ-ONLY for Claude. ChatGPT is its sole writer.

---

# GATE 0 — PERSISTENT DESKTOP SYNC

Before implementation:

1. Work from `C:\Users\sekip\Desktop\ScrubBots`.
2. Record local HEAD, origin/main, ahead/behind, tracked dirty files, untracked count, stashes/worktrees and SHA-256 of owner-local `project.godot`.
3. `git -C "C:\Users\sekip\Desktop\ScrubBots" fetch --prune origin`.
4. Non-destructively reconcile Desktop to exact latest origin/main while preserving all owner-local work.
5. Implementation does not begin until Desktop HEAD == origin/main and ahead/behind = 0/0.
6. Never run against persistent Desktop:
   - `git checkout -- <file>`
   - `git restore <file>`
   - `git reset --hard`
   - `git clean`
   - force checkout/rebase/push
   - destructive stash/pop
7. TEMP worktree is allowed only after Gate 0 and every TEMP git/Godot command must use an explicit absolute path:
   - `git -C "<TEMP>" ...`
   - `godot --path "<TEMP>" ...`
8. If TEMP worktree creation fails, STOP. Never fall back to modifying Desktop.
9. After final push, sync Desktop again to final origin/main and prove owner `project.godot` hash unchanged.

---

# READ FIRST

- root `TASKS.md`
- `scripts/ui/feel/feedback_adapter.gd`
- `scripts/ui/feel/meta_reward_feel.gd`
- `scripts/app/main.gd`
- `scripts/ui/home/home_screen.gd`
- `scripts/ui/home/home_view_model.gd`
- `scripts/ui/components/journey_strip.gd`
- `scripts/ui/results_screen.gd`
- `scripts/progression/results_momentum.gd`
- `scripts/app/navigation_controller.gd`
- Phase 3 audit/closure:
  - `coordination/sessions/M43-C005F-PHASE3-QA-R01/CHATGPT_INDEPENDENT_REAUDIT_V01.md`
  - `coordination/sessions/M43-C005F-PHASE3/OWNER_VISUAL_ACCEPTANCE_V01.md`

Inspect current APIs before coding.

---

# FOUNDATION CONTRACT

The canonical feedback gateway remains:

`scripts/ui/feel/feedback_adapter.gd`

Do not call GameFeelFlow or Saltmire Spark directly from new production code.

V1 rules remain:

- native Godot presentation is primary for Control UI;
- GameFeelFlow only where the target type/API is actually compatible;
- Spark only through FeedbackAdapter;
- no flash;
- no camera shake;
- no freeze frame;
- no time scale;
- no physics/collider authority;
- no global `Spark.clear()`;
- Reduced = zero plugin work for these two children;
- feedback never owns reward/save/navigation/completion/progression truth.

Do not alter the owner-accepted Results WIN, reward rows, pack, Collection, Gift/Daily/Tasks or acquisition visuals already closed under Phases 2/3.

---

# CHILD 1 — SB-M43-C005F-010
## Gameplay-complete → Results presentation bridge

Current authority seam:

`ProductionGameplayHost.get_completion().terminal_reached`
→ `scripts/app/main.gd::_bind_terminal()`
→ `NavigationController.on_gameplay_terminal()`
→ Results route
→ existing ResultsScreen WIN/LOST presentation

The bridge must be presentation-only.

### Required behavior

For one authoritative terminal event:

- terminal truth must already be latched by the canonical completion authority;
- the bridge may request at most one `SMALL` presentation event;
- the event must NOT block, await or delay `nav.on_gameplay_terminal(...)`;
- navigation to Results stays immediate;
- Results WIN confetti remains owned by F003. Do NOT add a second WIN/confetti event here.

Preferred target:
- an existing gameplay/HUD presentation node that is safe to pulse briefly;
- if no stable meaningful target exists, use a no-particle adapter event only if it still has an honest presentation target;
- do not create a fake full-screen overlay just to satisfy F010.

### Identity

Use the authoritative attempt/terminal identity.

One terminal attempt = at most one bridge event.

Duplicate terminal signal, route refresh or Results re-show must not create another bridge event.

### Reduced

- zero plugin work;
- no pulse;
- Results transition still immediate.

### Failure safety

Missing/throwing plugin:
- same terminal receipt;
- same save/economy truth;
- exactly one Results transition;
- no stuck gameplay host.

### Hard no-delay rule

No `await`, timer, animation completion callback or plugin completion may sit between terminal authority and:

`nav.on_gameplay_terminal(...)`

The bridge is fire-and-forget decoration only.

---

# CHILD 2 — SB-M43-C005F-012
## Home state-change micro feedback without refresh spam

Home currently refreshes often:

- 1-second Heart timer
- modal close
- route-to-Home
- content refresh
- app/nav/shortcut setup
- owner/system refreshes

Therefore **refresh itself is never an effect trigger**.

### Core rule

Only an ACTUAL meaningful authoritative state change may cause one micro feedback event.

Repeated rendering of the same state produces zero feedback.

### Use a small presentation snapshot

Track only ephemeral presentation state in Home, never durable/save state.

A compact snapshot may include selected already-visible values such as:

- current frontier / JourneyStrip completed count or current beat
- Gift Meter committed progress / claimable-count transition
- Win Streak committed value
- Bot Parts progress crossing to unlockable
- next cleanup/frontier becoming available

Do NOT animate:
- Heart countdown ticking every second
- clock seconds
- Scrub Bucks changing because the user merely opened Home unless the specific change is already represented by a committed action effect elsewhere
- badges appearing because of a refresh that represents an event already celebrated by Phase 3
- static resize/layout change
- modal open/close
- remote-content refresh when displayed gameplay/progression state is unchanged

### Avoid duplicate celebration with existing systems

Already-owned presentation authority:

- Gift milestone / Gift claim → F008
- Daily / Tasks / ScrubBox → F008
- acquisition → F009
- Results rows/WIN → F003/F004
- set/master → F006
- pack → F005

F012 must not replay those major/REWARD effects on Home.

Home feedback is MICRO/SMALL only.

### Suggested high-value targets

Prefer existing nodes:

- `HomeJourneyStrip`
- Gift Meter bar/crate only for a meaningful committed progress state change that is not already a milestone celebration
- Win Streak track current marker
- Bot Parts meter when crossing meaningful threshold/unlockable state
- Play/Continue area when the frontier actually advances

No generic pulse on the whole Home screen.

### First render rule

Initial Home build/bind must establish the baseline snapshot with **zero effect**.

Likewise:
- first render after cold boot = no effect
- first render after screen reconstruction = no effect

Only subsequent authoritative delta may trigger.

### Refresh spam suppression

The following must produce ZERO new effect when state is unchanged:

- 10 repeated `refresh()` calls
- 1-second timer ticks
- viewport resize
- safe-area change
- modal close
- Home hide/show
- route refresh
- remote content refresh with identical effective state

### Delta coalescing

One committed state change causing several Home fields to change in the same refresh should produce at most a small bounded sequence, not a particle storm.

Prefer:
- one dominant MICRO/SMALL target, or
- max two serialized MICRO events.

No Spark is expected on ordinary Home micro updates.

### Reduced

- state updates normally;
- zero plugin work;
- no native decorative pulse.

---

# IMPLEMENTATION SHAPE

Prefer a compact presentation-only coordinator under:

`scripts/ui/feel/`

Example:
`home_terminal_feel.gd`

Responsibilities may include:

- F010 terminal observation helper;
- F012 Home snapshot comparison;
- dispatch through FeedbackAdapter;
- optional short native Control tween for FULL only.

But keep responsibilities clear.

Alternative:
- a tiny F010 binding in `main.gd`;
- a tiny F012 presentation snapshot inside `HomeScreen`.

Either is acceptable if simpler.

Do NOT create:
- a second event bus;
- a second NavigationController;
- a second Home state model;
- a second Results authority;
- persisted feel state.

---

# REMOTE CONTENT / R2 HARD EXCLUSION

Do not change semantics or config under:

- `scripts/content_runtime/**`
- RemoteContentManager
- remote manifest parsing
- remote pack download/install/cache/LKG
- `data/config/remote_content_runtime_v1.json`
- R2 URLs
- LevelData
- supply
- VOID
- Family APK/export
- Level Factory repo

The existing content_changed → Home refresh seam may be observed only to prove “same effective state = zero effect”.

---

# REQUIRED PERMANENT TESTS

Create focused Phase 4 tests, e.g.:

`tests/m43_c005f_phase4_terminal_home_micro.gd`

At minimum prove:

## F010

1. real terminal WON produces:
   - same committed receipt/save/economy truth;
   - exactly one navigation to Results;
   - at most one SMALL bridge feedback.
2. LOST follows same authority rule without WIN confetti duplication.
3. duplicate/stale terminal signal produces zero duplicate bridge.
4. plugin missing => Results reached once.
5. plugin throws => Results reached once.
6. Reduced => zero plugin work; Results reached once.
7. static/source guard proves no await/delay inserted before terminal navigation.
8. ResultsScreen F003 WIN event count remains unchanged: no duplicate WIN/confetti from F010.

## F012

1. first Home render establishes baseline: zero feedback.
2. unchanged `refresh()` x10: zero feedback.
3. timer-only Heart second changes: zero feedback.
4. resize/safe-area/modal close/hide-show: zero feedback if state unchanged.
5. one real Journey/frontier advance: exactly one bounded MICRO/SMALL event on the intended existing target.
6. one real Win Streak or Bot Parts meaningful change: at most one bounded event.
7. Gift milestone already owned by F008: Home refresh after that commit does not add a duplicate REWARD/major effect.
8. same state rendered again: no replay.
9. Reduced: delta visible, zero plugin work.
10. plugin missing/throwing: Home values remain correct and navigation unaffected.

## Boundary

- no direct plugin access outside FeedbackAdapter;
- no durable feel snapshot saved;
- no reward/save/navigation call from Home feel code;
- no change to Results/receipt/economy authority;
- Remote Content semantic diff = zero.

---

# REQUIRED REGRESSION

Run and record:

- Phase 1 foundation
- Phase 2 Results/Pack
- Phase 3 focused suite
- QA-R01 Standard/Premium tests
- M30 terminal/completion
- M40 save
- M41 Reduced Effects
- M42 Home + navigation + relevant Home composition/safe-area suites
- M43 Results suites
- M43 Phase 3 meta feel suite
- M55 release regression
- CP04/CP05 Remote Content
- root `tests/run_tests.gd`
- headless import/boot
- `git diff --check`

Any first-run failure must be disclosed.

---

# RUNTIME EVIDENCE

Use real shipping paths, not fabricated preview-only surfaces.

Capture FULL + REDUCED for:

1. real WON terminal → Results transition
2. real LOST terminal → Results transition
3. Home before meaningful progression state change
4. Home immediately after real progression/frontier change
5. same Home state after repeated refresh showing no replay
6. representative Home Reduced state

Required sizes where useful:
- 1080×2160
- 1536×2048

F010 has no separate owner visual gate if clearly subordinate to accepted Results.
F012 requires owner review only if the new micro emphasis is visibly noticeable enough to change the approved Home hierarchy.

---

# SOURCE CONTROL / PUBLICATION

Claude must not edit root `TASKS.md`.

Builder log:

`coordination/sessions/M43-C005F-PHASE4/M43_C005F_PHASE4_CLAUDE_LOG_V01.md`

Push implementation + tests + evidence + log normally to `main`.

After push:
- sync persistent Desktop non-destructively to final origin/main;
- prove Desktop HEAD == origin/main, 0/0;
- prove owner `project.godot` hash unchanged.

Final state:

`AWAITING_GPT_M43_C005F_PHASE4_STRICT_AUDIT`
