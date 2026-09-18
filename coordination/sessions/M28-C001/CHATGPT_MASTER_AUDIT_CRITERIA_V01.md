# M28-C001 V01 — MASTER STRICT AUDIT CRITERIA

Milestone: `M28 — Gameplay Screen Layout`
Tasks: `SB-M28-001..028`
Verdict: all sections blocking unless explicitly evidence-only.

## A. Governance
- root TASKS unchanged by Claude;
- no M29 touch implementation;
- no M30+ gameplay/economy implementation;
- zero AI image generation;
- references preserved byte-for-byte;
- implementation first, separate log commit last.

## B. Reference audit
Must explicitly audit canonical gameplay reference:
`assets/art/references/_owner_inbox/Game Screens/deneme 3 OK.png`.

Evidence must distinguish:
- adopted composition/layout ideas;
- superseded historical direct-slot interaction;
- excluded Goal/Moves;
- excluded Level/lock rail;
- reference-only illustrations that are NOT production-approved.

Flattened screenshot use is a FAIL.

## C. Production scene architecture
Dedicated gameplay production scene exists and uses:
- SafeAreaRoot;
- container/responsive layout;
- existing BoardRenderer/BoardPresentation;
- ScrubRailView;
- five read-only batch slots;
- batch supply presentation;
- booster row;
- bottom actions.

No UI component may own BoardState/M23/M24/M25/M26/M27 mutable truth.

## D. Batch gameplay presentation
- exactly five read-only slot positions;
- 3/4/5 supply columns supported;
- V1 exactly 3 visible rows;
- front visually primary;
- rows 2/3 preview-only presentation;
- deeper batches never rendered/exposed;
- all bindings are detached scalar snapshots;
- no production destination-slot click mechanic.

## E. Board dominance/aspect
At every required viewport:
- board is primary/largest central gameplay region;
- board aspect preserved;
- non-square board not stretched to square;
- 59x59 fits without collapsing protected batch region;
- no per-cell Control/Node renderer introduced.

## F. Railroad presentation
Responsive screen must preserve:
- canonical ScrubRailView/ScrubRailGeometry;
- 2 logical-cell artwork clearance;
- 1 logical-cell rail width;
- bottom connector space;
- no layout-dependent mutation of routing truth.

## G. Safe areas
Test synthetic/nonzero safe insets.
Essential regions remain inside safe rect:
- board;
- batch slots/supply;
- boosters;
- pause/speed-up control.

No notch/gesture overlap in evidence.

## H. Composition contract
Directly prove:
- Goal/Moves absent;
- Level/lock rail absent;
- Scrubby anchor low-left of batch region;
- speech anchor above Scrubby;
- cleaning props anchor right;
- 4 boosters horizontal;
- pause left / ad placeholder center / speed-up control right.

Decoration may shrink before supply/slots.

## I. Asset approval gate
- no owner reference automatically becomes production art;
- no crop from canonical screenshot;
- only explicit APPROVED/owner-original production assets may be bound;
- if no approved gameplay illustration exists, neutral native anchors/placeholders are acceptable and must be reported honestly;
- no generated art.

## J. Viewport matrix
Required:
- 1080×2160;
- 1170×2532;
- 1290×2796;
- 1080×2400;
- 1440×3200;
- short 16:9 portrait;
- tablet portrait.

For each capture/metrics record:
- mode COMPACT/NORMAL/TALL;
- safe rect;
- board rect;
- board logical W×H;
- slot/supply rect;
- booster rect;
- bottom row rect;
- clipping flags;
- minimum touch/display size flags.

## K. Board-size matrix
At least:
- small;
- medium;
- hard-size;
- 59×59;
- two rectangular boards.

Difficulty labels here are layout fixtures only.

## L. Coordinate mapping
Independent evidence after responsive layout:
- logical cell center -> global/screen -> logical local round-trip;
- at least corners + center + random fixed cells;
- rectangular boards included;
- error bounded to a documented subpixel/logical epsilon;
- resize/re-layout invalidates no mapping;
- slot/supply resize cannot shift mapping incorrectly.

## M. Protected width/touch ergonomics
- supply region does not collapse below approved usable minimum;
- visible controls use UiTokens;
- essential button/control target >= TOUCH_MIN where applicable;
- five slot views remain readable.

## N. Regression floor
Run:
- root suite;
- M27 Hazard/generation/59;
- M26 Hazard/scale;
- M25 V03;
- M24 V02;
- M23 V03;
- M22 connector/real-demo/Railroad evidence;
- BoardRenderer layout/tall/rectangular tests;
- new M28 viewport tests;
- `git diff --check`.

No new failures outside already-recorded environment baseline.

## O. Evidence
Commit:
- reference audit;
- viewport metrics;
- screen captures where possible;
- asset-gate report;
- task mapping.

Do not claim manual visual inspection that was not performed.

## P. Closure
PASS only if every `SB-M28-001..028` has direct implementation/evidence mapping without violating asset approval or M29 input boundaries.
