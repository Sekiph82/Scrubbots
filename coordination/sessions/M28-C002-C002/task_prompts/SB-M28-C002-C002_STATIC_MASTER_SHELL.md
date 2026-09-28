# SB-M28-C002-C002 — 3/4/5 STATIC MASTER SHELL PRODUCTION BINDING

Status: READY FOR CLAUDE
Date: 2026-09-28
Repository: `Sekiph82/Scrubbots`
Branch: `main`

## Mission

Replace the C001 native-redrawn gameplay chrome with the owner-locked **three full-screen static gameplay masters**, while preserving all authoritative live gameplay overlays and systems.

Canonical owner decision:
`coordination/OWNER_GAMEPLAY_345_STATIC_MASTER_SHELL_V01.md`

Do NOT edit root `TASKS.md`.

## Read first

1. `CLAUDE.md`
2. root `TASKS.md` READ ONLY
3. `coordination/OWNER_GAMEPLAY_345_STATIC_MASTER_SHELL_V01.md`
4. `coordination/sessions/M28-C002-C001/CHATGPT_AUDIT_V01.md`
5. `coordination/sessions/M28-C002-C001/GAMEPLAY_V02_CORE_MATRIX_V01.md`
6. current GameplayScreen / ProductionGameplayHost / BoardPresentation / rail / slot / supply implementation
7. existing owner click plans and snapshot harness

## Step 0 — exact owner asset intake

Find the exact three owner files in the already-authorized local project/reference locations:

- `3 lu renk secim alani.png`
- `4lu renk secim alani.png`
- `5li renk secim alani.png`

Likely owner source includes the established visual-reference library / project owner inbox.

Copy bytes, do not regenerate.

Canonical repo destinations:

- `assets/ui/final/gameplay/master/gameplay_v02_shell_3col.png`
- `assets/ui/final/gameplay/master/gameplay_v02_shell_4col.png`
- `assets/ui/final/gameplay/master/gameplay_v02_shell_5col.png`

Record source filename, dimensions and SHA-256.

Preserve historical `scrubbots_gameplay_master.png`.

If any exact master is missing:
- do not substitute;
- do not synthesize;
- stop with `OWNER_ASSET_REQUIRED / M28-C002-C002 / <missing file>`.

## Runtime shell selection

Choose shell from authoritative Batch Supply column count:

- 3 -> 3col shell
- 4 -> 4col shell
- 5 -> 5col shell

Fail closed for unsupported count.

Use a single shell-reference coordinate system and uniform transform for:
- image;
- BoardRenderer aperture;
- agent movement overlay;
- slot live overlays/hitboxes;
- supply overlays/hitboxes;
- profile overlays;
- Pause/2x overlays;
- booster/ad anchors.

No independent layout drift.

## Static master shell

The shell already provides:
- environment;
- visible rail;
- board frame/field;
- five connector graphics;
- five slot frames;
- supply-frame cells;
- profile frame;
- Pause/2x frames;
- Scrubby;
- speech bubble;
- cleaning props.

Do NOT render duplicate visible versions of those elements.

Specifically:
- disable/remove C001's second visible rail skin;
- disable/remove native normal slot-frame chrome;
- disable/remove native profile-panel chrome;
- do not redraw five connector graphics;
- do not redraw supply-frame chrome.

Keep only the live overlays required below.

## Board / movement

Keep real BoardRenderer.

Fit the logical board into the shell's board/rail reference coordinates so the canonical runtime Railroad geometry lands on the baked visible rail.

The shell rail is visual only.
Runtime Railroad geometry remains HOW authority.

Scrubbot agents must visibly travel over the baked rail and through the board/open corridor using existing runtime path truth.

No second rail is drawn.

## Slot overlays

Five baked slot frames remain visible.

Overlay:
- current batch color;
- count;
- runtime state needed for readability.

Input law unchanged: slots are not destination buttons.

### Temporary sixth slot

Keep +1 Slot functional.

When capacity becomes six:
- create only the sixth slot + sixth connector as a dynamic overlay;
- match master visual language;
- use real sixth SlotOriginProvider / bottom_entry geometry;
- do not redraw the other five;
- remove it on retry/reset.

Capture dedicated owner evidence.

## Batch Supply overlays

Use the matching 3/4/5 shell.

Place live colors/counts into the baked cells.

Hitboxes align to those exact master cell interiors.

Only first/front row is interactive.
Rows 2–3 preview only.

Do not draw duplicate panel/tile frames over the master except minimal state indication that cannot otherwise be communicated.

## Profile

Use the baked profile frame.

Overlay only:
- approved/current robot portrait where required;
- live Level;
- live Bot Parts.

No invented title, XP or unsupported number.

## Pause / 2x

Place live controls exactly into the two baked top-right boxes.

Keep:
- existing pause behavior;
- existing speed acquisition behavior until final M43 popup;
- live timed countdown;
- anti-rollback;
- free auto-2x.

Do not add new outer button chrome over the baked boxes; overlay icon/state/text only.

## Speech bubble

The master contains a bubble with obsolete baked instruction.

Do not ship that wrong sentence.

For this cycle:
- preserve the bubble graphic/composition;
- cover/mask only the obsolete text area in a visually clean way;
- leave it blank;
- no tutorial sentence invented.

M44 later owns localized live tutorial text.

If the source files already exist in a blank-bubble variant, prefer the exact owner-approved blank variant only if it is demonstrably the same master composition.

## Bottom ad + boosters

Add/retain a reserved bottom ad region.

Do not integrate a real ad network in M28.

Place exactly four live booster controls above/over the lower ad region:
+1 Slot / Random / Selector / Tornado.

Use live icon/count/price/state overlays.
No fifth booster.

## Responsive transform

The masters are 887×1774 (1:2).

Never non-uniformly stretch them.

For:
- 1080×2160
- 1170×2532
- 1290×2796
- 1080×2400
- 1440×3200
- 1080×1920
- representative tablet portrait

use safe-area-aware uniform aspect-fit of the shell.

Fill unused surrounding space unobtrusively without changing master geometry.

Every live overlay/hitbox must use the same transform.

Prove coordinate alignment at all tested sizes.

## Tests

Add focused tests proving:

1. correct 3/4/5 master selected from authoritative supply column count;
2. no duplicate visible rail skin;
3. no duplicate normal slot frames/connectors;
4. BoardRenderer aligned to shell board/rail aperture;
5. runtime agent rail/path overlay aligns to baked rail;
6. five slot overlays align to baked slots;
7. temporary sixth slot/connector only on capacity 6;
8. supply overlay/hitbox alignment for 3/4/5 masters;
9. front-only input law unchanged;
10. profile dynamic data only;
11. Pause/2x live state alignment;
12. timed countdown / anti-rollback unchanged;
13. exactly four boosters and reserved ad region;
14. obsolete speech text not visible;
15. responsive reference-transform invariants;
16. no node/signal accumulation on retry/rebuild.

Retain all C001 safety/gameplay regressions.

Run relevant M22..M30, M39/M40/M42, M52, M55 and root suite.
Document historical M21 baseline failures without attributing them to this cycle if unchanged.

## Evidence

Produce at minimum:

- 3-column fresh state;
- 4-column fresh state;
- 5-column fresh state;
- active cleaning with Scrubbots visibly following baked rail;
- five occupied slots;
- temporary sixth slot;
- timed 2x countdown;
- tall phone;
- short phone;
- tablet.

Owner must be able to compare these directly to the three masters.

## Outputs

Create:
- `coordination/sessions/M28-C002-C002/GAMEPLAY_STATIC_SHELL_MATRIX_V01.md`
- `coordination/sessions/M28-C002-C002/OWNER_GAMEPLAY_STATIC_SHELL_REVIEW_V01.md`
- `coordination/sessions/M28-C002-C002/CLAUDE_LOG_V01.md`
- evidence screenshots under that session.

## Scope locks

Do not:
- regenerate or substitute the three masters;
- rewrite routing/gameplay truth;
- change level content/supply plans;
- change economy prices/Heart/2x rules;
- implement final M43 Pause/Booster/2x popup families;
- invent tutorial copy;
- edit TASKS.md.

## Finish

Commit and push.

Finish with:

`AWAITING_CHATGPT_AUDIT / M28-C002-C002 3-4-5 STATIC MASTER SHELL`
