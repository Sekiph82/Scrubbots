# M43-C001R-C001 — RESULTS MOMENTUM / NEXT CLEANUP / 10-LEVEL JOURNEY

Status: READY FOR CLAUDE
Date: 2026-10-02
Repository: `Sekiph82/Scrubbots`
Branch: `main`
Scope: **SB-M43-R01-001..008**

Do not edit root `TASKS.md`. ChatGPT owns tracker state.

## Mission

Implement the owner-approved retention/momentum block that was added after the original M43 Results plan and is numerically before M43-C005:

- truthful **Next Cleanup** teaser built only from the real next canonical level;
- a stronger Results -> Next momentum corridor;
- one visible, non-tappable **10-Level Cleaning Journey** derived from canonical progression;
- the same journey read authority usable by Results and Home;
- honest frontier/missing-content behavior;
- future M43-C005 ceremony-barrier compatibility without implementing C005;
- focused tests, responsive visual evidence, owner review pack and implementation log.

This is a player-momentum presentation cycle. It must not create fake scarcity, near-miss messaging, hidden difficulty manipulation, invented rewards or a Level Select.

## Read first

1. `CLAUDE.md`
2. root `TASKS.md` READ ONLY
3. `coordination/AUDIT_POLICY.md`
4. `coordination/sessions/M43-C001R-C001/CHATGPT_AUDIT_CRITERIA_V01.md`
5. M43-C001A/C001B implementation + audits + final owner visual acceptance
6. M43-C004 technical audit + final owner acceptance
7. `scripts/ui/results_screen.gd`
8. `scripts/app/main.gd`
9. `scripts/ui/home/home_screen.gd`
10. `scripts/app/gameplay_launch_resolver.gd`
11. `scripts/progression/level_progression_service.gd`
12. `scripts/data/level_catalog.gd` and `level_catalog_entry.gd`
13. `data/levels/catalog/production_catalog_v1.json`
14. representative metadata under `data/levels/metadata/`
15. `docs/MASTER_UI_SYSTEM.md`
16. `data/config/player_experience_plan_v1.json`

## Owner-approved product intent

The active TASKS block M43-C001R is the authority:

- **Next Cleanup** reveals only a controlled portion of the real next level.
- Default visual-information target is roughly **15–25%**.
- Only truthful next-level context may be shown.
- Post-win flow should feel like one corridor:
  reward commit -> compact progress summary -> required ceremonies when they exist -> Next Cleanup -> dominant **CLEAN NEXT**.
- The journey is exactly ten cadence slots.
- Slot 5 is the mini-boss beat.
- Slot 10 is the cycle-boss beat.
- It is informational, not a World Diorama and not Level Select.
- No hidden personalized difficulty or reward manipulation.

## A. One read authority

Create one small read-only Results Momentum / Cleaning Journey authority. Name is implementation-owned but its responsibility must remain narrow.

It reads:
- canonical `LevelProgressionService`;
- canonical production `LevelCatalog`;
- the real level/metadata data already referenced by catalog entries.

It must never:
- grant;
- unlock;
- advance progression;
- mutate level content;
- choose difficulty;
- write save state;
- own UI nodes.

No second progression/campaign state.

## B. Versioned presentation config

Add a narrow versioned config for this feature, for example:

`data/config/results_momentum_v1.json`

Required values:
- schema/version;
- cycle length = 10;
- mini-boss slot = 5;
- cycle-boss slot = 10;
- teaser reveal mode = deterministic cropped detail;
- teaser visible area target = **0.20**.

Validation must fail closed for malformed/out-of-range config.

The visible fraction must remain within the owner-approved 0.15..0.25 envelope.

This is presentation tuning only. It cannot alter progression, rewards or difficulty.

## C. Next Cleanup read model — SB-M43-R01-001..003

Resolve the actual next canonical frontier through the same production catalog/progression truth as gameplay.

For available content expose a detached read model containing only truthful fields needed by UI, such as:
- level number;
- stable catalog id;
- difficulty token/class;
- real preview path;
- optional real color/palette count if it can be read from canonical LevelData/metadata without guessing;
- availability/reason.

Do not derive a fake level name from the filename unless a canonical display-name authority already exists.

### Teaser image

Use the catalog entry's existing real `preview_path`.

Do **not** generate, redraw or fabricate teaser art.

Default V1 technique: a deterministic cropped-detail reveal of the real preview.

Requirements:
- visible crop area approximately 20% of the full preview area;
- crop selection deterministic for a stable level id;
- crop remains within the texture bounds;
- no animation/frame may briefly expose the full preview;
- no hidden full-puzzle overlay behind transparency;
- unavailable/missing preview fails to an honest non-image state rather than using another level's art.

Prefer a runtime crop/subtexture/clip treatment rather than producing duplicate derived image files.

## D. Truthful context

Show only canonical facts:
- `LEVEL N`;
- real difficulty/class token;
- optional real color-count/palette summary if authoritative data is available.

Do not display:
- invented reward promises;
- “almost”, “lucky”, “jackpot” or near-miss language;
- fake urgency;
- guessed level names;
- implied guaranteed success.

When frontier content is absent:
- state is explicitly unavailable/coming soon;
- teaser art is not borrowed;
- CLEAN NEXT is disabled;
- Home/back remains usable.

Production catalog currently ends at Level 10, so the Level-10 Results case is an important real missing-content proof.

## E. One 10-Level Cleaning Journey read model — SB-M43-R01-005..007

Derive all journey state from progression + terminal context. Do not persist a second journey counter.

Exactly 10 nodes per cycle.

Node semantics:
- slots 1–10 correspond to the existing canonical ten-level cadence;
- slot 5 gets a distinct mini-boss beat;
- slot 10 gets a distinct cycle-boss beat;
- nodes are presentation-only;
- nodes are **not tappable**;
- no level skip, rewind, unlock or direct navigation from a node.

### Deterministic cycle math

For an anchor level `n >= 1`:
- cycle number = `floor((n - 1) / 10) + 1`;
- cycle slot = `((n - 1) % 10) + 1`.

Use one authority with explicit presentation context:

**Home**
- anchor = current canonical frontier;
- nodes before the frontier slot are complete for that cycle;
- frontier slot is CURRENT/NEXT;
- later nodes are future.

**WON Results**
- anchor = the just-completed progression level;
- nodes through that slot are complete;
- Results at Level 10 therefore shows a completed 10/10 cycle;
- the next canonical frontier remains Level 11 for teaser resolution.

This makes the boundary explicit:
- Results Level 9 -> slot 9 complete, teaser points to Level 10;
- Results Level 10 -> 10/10 complete;
- next Home/frontier Level 11 -> new cycle, slot 1 current.

The read model may also include canonical class tokens for the ten nodes, but must derive them from progression authority rather than hardcode alternate difficulty truth.

## F. Results momentum corridor — SB-M43-R01-004

Extend the accepted WON Results screen without reopening its reward/economy authority.

Required ordering:
1. terminal reward/economy is already committed before Results;
2. accepted ordered reward rows present;
3. compact Cleaning Journey progress appears;
4. if a future mandatory ceremony barrier is active, teaser waits;
5. Next Cleanup teaser appears;
6. dominant green primary CTA reads **CLEAN NEXT** when next content exists;
7. Home remains secondary.

Do not move reward commits into UI.

Do not delay or re-run grants.

### Reveal timing

The existing row-reveal timing may remain.

The momentum section may appear after the reward reveal finishes. Keep the wait short and deterministic.

Reduced Effects:
- no decorative reveal delay;
- final information appears immediately;
- behavior/state remains identical.

### Future C005 ceremony seam

**Do not implement M43-C005 ceremonies in this prompt.**

Add only the smallest explicit presentation barrier/seam needed so a future C005 ceremony can temporarily hold Next Cleanup/CLEAN NEXT until that ceremony is dismissed.

Requirements:
- default now = no barrier;
- barrier never changes rewards/progression;
- tests can activate/release it;
- releasing it shows the same already-resolved teaser;
- do not create a second modal/ceremony framework.

SB-M43-013 remains open for M43-C005.

## G. Home journey presentation

Expose the same journey authority on Home as a compact progress strip.

Use native Godot UI in the accepted Home language.

Requirements:
- exactly ten visible nodes;
- non-tappable;
- completed/current/future visually distinguishable;
- slot 5 mini-boss and slot 10 boss visually distinguishable without implying extra rewards;
- compact enough not to collide with Play, Win Streak track, BottomNav, ad slot, world art or safe areas;
- no World Diorama;
- no new destination.

Choose the least disruptive placement in the existing accepted Home composition and document it in the owner review pack.

Do not replace or rename the existing Win Streak reward track.

## H. CLEAN NEXT behavior

CLEAN NEXT routes through the existing canonical Results Continue path.

Preserve:
- attempt-bound stale protection;
- exactly-once transition;
- Heart attempt gate;
- content resolver;
- no duplicate reward;
- no bypass of navigation authority.

Rapid/double taps result in at most one launch.

When next content is missing, CLEAN NEXT is disabled and cannot create a fake level.

## I. No reward/difficulty manipulation

This cycle is presentation/read-only except for the already-existing Continue launch intent.

It must not:
- alter reward amounts;
- mint a Journey reward;
- change Gift Meter;
- change Hearts;
- alter Win Streak;
- change difficulty/cadence;
- reorder campaign levels;
- add timer/move limits;
- add paid/rewarded CTA;
- implement personalized dynamic difficulty.

## J. Required focused tests — SB-M43-R01-008

Create a focused suite, e.g.
`tests/m43_c001r_c001_results_momentum.gd`.

At minimum prove:

1. next teaser resolves the actual canonical frontier entry;
2. teaser uses that entry's exact preview path;
3. teaser crop is deterministic for same stable id;
4. crop rectangle remains in bounds;
5. configured visible area fraction is 0.15..0.25 and V1 = 0.20;
6. no full preview becomes visible during normal or Reduced Effects presentation;
7. difficulty displayed equals canonical authority;
8. optional color count, if shown, equals canonical level/metadata truth;
9. missing frontier shows honest unavailable state;
10. missing preview never borrows another level;
11. Level-10 production result points to missing Level 11 and disables CLEAN NEXT;
12. journey has exactly 10 nodes;
13. slot 5 is mini-boss state;
14. slot 10 is boss state;
15. nodes have no input/navigation action;
16. Home frontier 1 -> slot 1 current, no completed nodes;
17. Home frontier 6 -> slots 1..5 complete, slot 6 current;
18. Results Level 9 -> slots 1..9 complete and teaser Level 10;
19. Results Level 10 -> 10/10 complete;
20. Home frontier 11 -> new cycle slot 1 current;
21. injected/proven content for Level 11 gives correct 10 -> next-cycle transition without hardcoding production content;
22. Results and Home use the same journey/read authority;
23. save/reload of progression reproduces the same journey state with no separate journey save state;
24. reward receipt/economy snapshot is byte/value-identical before/after teaser/journey rendering;
25. reward row order remains the accepted C001B order;
26. CLEAN NEXT uses existing Continue route;
27. rapid CLEAN NEXT taps launch at most once;
28. stale Results attempt cannot launch;
29. zero-Heart CLEAN NEXT still opens Life and launches nothing;
30. active ceremony barrier hides/holds teaser + CLEAN NEXT;
31. releasing barrier reveals the same truthful teaser without grant/state mutation;
32. Reduced Effects shows final momentum content immediately;
33. Home/Results responsive matrix fits required safe areas;
34. repeated show/hide/refresh does not accumulate nodes/signals/timers;
35. malformed momentum config fails closed without blocking ordinary Results/Home navigation.

## K. Regression

Run all directly relevant suites, including:
- M35 catalog;
- M36/M37 difficulty/progression;
- M40 save/AppState;
- M42 Home/navigation/opening;
- M43-C001A;
- M43-C001B;
- M43-C004;
- M55 long-session/economy release where Home/Results lifecycle is exercised;
- root `tests/run_tests.gd`;
- `git diff --check`.

If any historical baseline failure appears, reproduce/attribute it precisely. Do not silently waive a new failure.

## L. Visual evidence / owner review

Create:
`coordination/sessions/M43-C001R-C001/evidence/`

Fresh real-app evidence at minimum:
- WON Results after a normal level with Journey + Next Cleanup;
- a teaser visibly showing only cropped-detail real level art;
- Results Level 4 -> teaser Level 5 (mini-boss next);
- Results Level 9 -> teaser Level 10 (boss next);
- Results Level 10 -> 10/10 journey + honest Level 11 coming-soon/no art;
- Home frontier mid-cycle with 10-node strip;
- Home new-cycle frontier 11 using an isolated/test evidence state if production catalog cannot launch it;
- short phone 1080x1920;
- reference 1080x2160;
- 1170x2532;
- 1290x2796;
- tablet 1536x2048;
- Reduced Effects;
- ceremony-barrier held/released candidate if it can be captured clearly.

Create:
- `MOMENTUM_MATRIX_V01.md`
- `OWNER_VISUAL_REVIEW_V01.md`
- `CLAUDE_LOG_V01.md`

Owner review should explicitly ask about:
- teaser crop composition/amount;
- Journey placement and node hierarchy;
- mini-boss/boss node treatment;
- CLEAN NEXT wording/hierarchy;
- Results density after adding momentum content;
- Home density/placement.

Do not self-approve visuals.

## M. Scope locks

Do not:
- edit root `TASKS.md`;
- close or implement SB-M43-013;
- implement M43-C005 ceremonies;
- implement M43-C005R Gift Meter micro-progress;
- create Level Select;
- make Journey nodes tappable;
- create World Diorama;
- generate fake next-level art;
- expose the full next puzzle in the teaser;
- add new reward thresholds;
- alter canonical cadence/difficulty;
- alter economy/Heart/booster/ad systems;
- change M43-C004 Need a Hand;
- restyle accepted Results/Home outside the minimum momentum additions;
- add external/paid SDKs.

## N. Git / finish

Start from current `origin/main`.

Preserve all pre-existing owner/local work. Never destructive reset/clean/force push.

Commit and push the authorized implementation/evidence/docs only.

Return:
1. final commit SHA;
2. focused + regression test summary;
3. direct GitHub URL to `CLAUDE_LOG_V01.md`;
4. direct GitHub URL to `OWNER_VISUAL_REVIEW_V01.md`;
5. any real blocker/owner visual decision still required.

Finish exactly:

`AWAITING_GPT_M43_C001R_C001_AUDIT`
