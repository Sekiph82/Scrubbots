---
coordinationSchema: scrubbots-coordination/v4
artifactType: claude-log
cycleId: M10-C001
version: 8
createdAt: 2026-09-06T20:30:00+03:00
actor: CLAUDE
status: AWAITING_AUDIT
milestone: M10
promptRef: CHATGPT_PROMPT_V08.md
criteriaRef: CHATGPT_AUDIT_CRITERIA_V08.md
---

# M10-C001 — Claude Implementation Log V08

Owner visual-QA layout correction: the BoardRenderer manual-QA area is now a
dedicated **canonical gameplay QA region** derived from the owner phone-screen
reference (887×1774, gameplay region x=13,y=175,w=844,h=942), NOT the whole
residual portrait area. The selected logical board is fitted + centered inside
that QA region. The abandoned 75×75 idea is NOT implemented; production maximum
stays 59×59 and DifficultyRules is untouched.

**This session did NOT touch `tasks.md`, `.hiveai/*`,
`coordination/SESSION_INDEX.md`, `scripts/data/difficulty_rules.gd`, palette
data, or fixture grids.**

## Three/four layers kept distinct

```text
phone/reference viewport (e.g. 1080×2160)
└── canonical gameplay QA region (owner ratios → ≈ x16,y213,w1028,h1147)
    └── selected logical board canvas (30×30 … 59×59)
        └── immutable source artwork matrix (e.g. 007 = 27×24)
```

## Implementation

`scripts/debug/board_renderer_debug.gd`:
- Added canonical QA-region constants as **normalized ratios** of the owner
  reference (`13/887`, `175/1774`, `844/887`, `942/1774`) + a pure, testable
  `qa_region_rect(viewport) -> Rect2` (rounds ratio·viewport). Deriving from
  ratios keeps the same relative region stable at any debug viewport size.
- Added a dedicated `_qa_region` Control (with a faint frame for owner
  visibility) as a direct child of the root; the board background, BoardRenderer
  and grid overlay are now children of `_qa_region`, not the full residual
  VBox area. Controls/info stay in the top strip.
- `_refresh()` positions/sizes `_qa_region` from `qa_region_rect(size)`,
  passes **`_qa_region.size` as the BoardRenderer `available_size`**, and
  centers the resulting board pixel rect inside the QA region. Integer cell
  size + true logical aspect ratio preserved (unchanged BoardRenderer geometry).
- Info line now reports: fixture, source size, canvas size, source offset,
  `QA=<w>x<h>`, `board_px=`, `cell=`, artwork/void, pattern.
- Root `resized` reconnected to `_refresh` so the QA region tracks viewport size.

No change to `board_debug_fixtures.gd` embedding, palette, DifficultyRules or
any production limit. No 75×75 anywhere.

## Tests

`tests/run_tests.gd`:
- Extended the V07 runtime smoke: drives the real deferred fixture-change path
  and now also asserts the canonical QA geometry —
  `qa_region_rect(1080×2160)` ≈ (x16, y213, w1028, h1147); `_qa_region` sized to
  that rect; the info line reports `QA=1028x1147`; the 30×30 and 59×59 boards
  fit inside the QA region (board_px ≤ QA size); zero renderer child Nodes.
- Retained all V05/V06/V07 checks: 007 offsets (1,3)/(16,17) + artwork 542;
  010/013 variable-canvas; VOID never ACTIVE; C01..C16; C16 #000000; BG01
  #202533; too-small rejected; Synthetic Stripes; no per-cell Nodes.

## Verification log

1. **`godot --version`** — `4.7.1.stable.official.a13da4feb`.
2. **Safe sync** — `git fetch`; local behind origin/main by 13 (V07 audit +
   H!ve/V08 issuance). `git merge --ff-only origin/main` →
   `10e141b13cb275b8de4b6e4fd1a07cde3ddca9d4`. No reset/rebase/clean/restore/force.
3. **Owner work preserved (AL-026)** — `project.godot` ` M` before/after; not
   staged. The owner's newly-added reference screenshot
   `assets/art/references/_owner_inbox/Game Screens/oyun oynama ekrani.png`
   is left untracked/preserved and not staged (owner asset).
4. **Canonical QA region** — derived from owner ratios; resolves to
   ≈ x=16,y=213,w=1028,h=1147 at 1080×2160 (asserted ±1 px).
5. **available_size = QA region** — BoardRenderer configured with
   `_qa_region.size`; board centered inside it; 30×30 and 59×59 both fit.
6. **007 unchanged** — source 27×24, offsets (1,3)/(16,17), artwork 542, fully
   visible at both canvases.
7. **010/013 intact**; rectangular boards keep aspect ratio (existing geometry
   tests unchanged).
8. **No 75×75 / no DifficultyRules change** — grep clean; production max 59×59;
   `scripts/data/difficulty_rules.gd` untouched.
9. **Visual contract intact** — C01..C16, C16 #000000, BG01 #202533, VOID never
   ACTIVE, flat cells, no per-cell Nodes.
10. **Full headless suite** — `1031 / 1031 ALL PASS` (was 1023; +8 V08 QA
    checks; no regressions; no SCRIPT ERROR).
11. **Real debug-scene runtime smoke** — `--quit-after 60` processes 60 frames
    (real `_ready`→deferred `_on_fixture_changed`) with zero
    get_item_disabled/SCRIPT/parse/FIXTURE/EMBED/Nil errors.
12. **`tasks.md` unchanged**; SB-M10-005..011 still `[ ]`; no M14+; no new SB
    IDs. Progress 207/943 = 21.95% (unchanged).
13. **`git diff --check`** clean (benign LF/CRLF only). Changed files:
    `scripts/debug/board_renderer_debug.gd`, `tests/run_tests.gd`, this log.
14. **No forbidden-file edits** — `.hiveai/*`, `PROJECT_DASHBOARD.md`,
    `coordination/SESSION_INDEX.md`, `data/*` untouched; no audit file created.

## Handoff

Cycle state: `AWAITING_AUDIT`; next actor CHATGPT. ChatGPT performs the
independent audit and all SESSION_INDEX / H!veAI tracker / dashboard updates.
Claude stops here.
