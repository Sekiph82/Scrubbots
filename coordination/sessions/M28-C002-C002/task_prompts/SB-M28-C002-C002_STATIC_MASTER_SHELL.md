# SB-M28-C002-C002 — 3/4/5 STATIC MASTER SHELL PRODUCTION BINDING

Status: READY FOR CLAUDE
Date: 2026-09-28
Repository: `Sekiph82/Scrubbots`
Branch: `main`

## Mission

Replace the C001 native-redrawn gameplay chrome with the owner-locked **six full-screen static gameplay masters**: 3/4/5-column normal five-slot shells plus matching 3/4/5-column six-slot shells for +1 Slot.

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

Find and copy byte-preserving all six exact owner files.

They may exist under either the original owner filenames OR the canonical filenames.

### Five-slot normal masters
Original owner names:
- `3 lu renk secim alani.png`
- `4lu renk secim alani.png`
- `5li renk secim alani.png`

Canonical names:
- `gameplay_v02_shell_5slot_3col.png`
- `gameplay_v02_shell_5slot_4col.png`
- `gameplay_v02_shell_5slot_5col.png`

### Six-slot +1 Slot masters
Original owner names:
- `6 li slot 3 renk-batch sistemi.png`
- `6 li slot 4 renk-batch sistemi.png`
- `6 li slot 5 renk-batch sistemi.png`

Canonical names:
- `gameplay_v02_shell_6slot_3col.png`
- `gameplay_v02_shell_6slot_4col.png`
- `gameplay_v02_shell_6slot_5col.png`

**Do not reject a canonical-named file merely because its original owner filename is absent.**
The locked SHA-256 + dimensions + mapping are the authority.

Expected dimensions: 887×1774 RGBA for all six.

Expected SHA-256 values are locked in:
`coordination/OWNER_GAMEPLAY_345_STATIC_MASTER_SHELL_V01.md`

Canonical repo destinations:

- `assets/ui/final/gameplay/master/gameplay_v02_shell_5slot_3col.png`
- `assets/ui/final/gameplay/master/gameplay_v02_shell_5slot_4col.png`
- `assets/ui/final/gameplay/master/gameplay_v02_shell_5slot_5col.png`
- `assets/ui/final/gameplay/master/gameplay_v02_shell_6slot_3col.png`
- `assets/ui/final/gameplay/master/gameplay_v02_shell_6slot_4col.png`
- `assets/ui/final/gameplay/master/gameplay_v02_shell_6slot_5col.png`

Record source filename, dimensions and SHA-256 and verify exact match before binding.

Preserve historical `scrubbots_gameplay_master.png`.

If the owner has extracted `ScrubBots_Gameplay_V02_Canonical_Masters.zip` into an authorized reference folder, accept those canonical-named PNGs after hash verification.

If any exact master is missing or hash-mismatched:
- do not substitute;
- do not synthesize;
- stop with `OWNER_ASSET_REQUIRED / M28-C002-C002 / <missing-or-mismatched file>`.

## Runtime shell selection

Choose shell from authoritative **Batch Supply column count AND current slot capacity**:

| Supply columns | Capacity 5 | Capacity 6 |
|---|---|---|
| 3 | 5slot_3col | 6slot_3col |
| 4 | 5slot_4col | 6slot_4col |
| 5 | 5slot_5col | 6slot_5col |

Capacity 6 occurs only through authoritative +1 Slot.

Switch shell immediately when capacity changes 5 <-> 6, without changing gameplay state.

Fail closed for unsupported column count or capacity.

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

### +1 Slot / six-slot shell

Do NOT dynamically draw a sixth slot or sixth connector.

When authoritative capacity becomes six:
- switch to the matching 6-slot master for the current 3/4/5 supply column count;
- bind all six live slot contents/counts into the six baked frames;
- keep the real sixth slot runtime authority and routing unchanged;
- keep live agent motion aligned with the six baked connectors.

On retry/reset back to capacity five:
- switch to the matching five-slot shell;
- bind five live slot overlays.

Prove repeated 5 -> 6 -> 5 transitions do not leak nodes/signals and do not mutate unrelated gameplay state.

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
7. matching six-slot master selected only on authoritative capacity 6, and five-slot master restored on reset/retry;
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
- +1 Slot active using the matching six-slot master;
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
- regenerate or substitute any of the six masters;
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
