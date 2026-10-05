# M43-C005-C009 — CHATGPT CARD-STATE PRESENTATION V01 INDEPENDENT AUDIT

Date: 2026-10-05  
Canonical task: **SB-M43-067**  
Audited implementation: `bf33ef28072e8ac825783aff3f85389248a985cf`  
Baseline: `3dda95721f064993c1d0677f5390b6668c5e29a6`  
Prompt: `CHATGPT_PROMPT_V01.md`  
Audit criteria: `CHATGPT_AUDIT_CRITERIA_V01.md`  
Result: **TECHNICAL_AUDIT_PASS / OWNER_VISUAL_GATE_REQUIRED**

## 1. Independent audit scope

Reviewed:
- C009 prompt and audit criteria;
- Claude V01 log and card-state matrix;
- actual implementation commit/diff;
- shared Standard/Premium CardView implementation;
- UiText changes;
- Standard/Premium fixture and owner-review harness changes;
- focused C009 test source;
- accepted C006/C007 pack architecture;
- C008 committed receipt boundary;
- runtime evidence captures for Standard/Premium FULL and Reduced states, repeated-card truth, duplicate-heavy truth and representative wide viewport.

## 2. Scope / governance

PASS.

The audited implementation changes:
- shared Standard pack ceremony / CardView presentation code;
- UiText state/count copy;
- focused tests/evidence;
- owner-review fixture/harness tooling;
- coordination evidence.

It does not change:
- Premium ceremony implementation;
- Standard/Premium models;
- RevealSequencer;
- C008 pack transaction / receipt schema;
- economy / Collection / save authority;
- Standard/Premium opening frame PNGs;
- canonical 135 card PNGs;
- destination icon PNGs;
- canonical `card_new_glow.png`;
- root `TASKS.md`;
- SB-M43-068.

No GameFeelFlow or Saltmire Spark integration was introduced.

## 3. Card-state truth source

PASS.

The shared CardView consumes only the already-committed card row supplied by C008.

NEW/DUPLICATE rendering uses:
- `bool(card["is_new"])`
- `int(card["copies_after"])`

Duplicate count is:

`extra_copies = copies_after - 1`

No live Collection/economy/transaction/save/RNG query exists in the shipping ceremony/CardView path to recompute card-state truth.

This is important for receipt replay: a ceremony recreated later continues to show the truth of the original committed pack rather than current Collection state.

## 4. FIRST COPY / EXTRAS truth

PASS.

The shipping card count line is now:
- NEW -> **FIRST COPY**
- DUPLICATE -> **EXTRAS xN**, where N = `copies_after - 1`.

Verified in source and focused tests:
- copies_after 2 -> EXTRAS x1;
- copies_after 3 -> EXTRAS x2;
- copies_after 8 -> EXTRAS x7;
- NEW never renders EXTRAS x0.

Repeated same-card Standard evidence correctly shows, in receipt order:

**FIRST COPY -> EXTRAS x1 -> EXTRAS x2**

The focused suite also exercises committed C008 repeated-card truth, not only hand-authored UI rows.

## 5. NEW-card celebration

PASS technically.

The shared CardView uses the existing canonical:

`res://assets/ui/final/collection/states/card_new_glow.png`

No replacement art was introduced.

FULL:
- NEW cards receive one bounded native pulse;
- maximum intended scale is 1.04;
- glow rises to a peak and settles to a static 0.5-alpha halo;
- multiple NEW cards celebrate in deterministic model order;
- celebration event fires at most once per CardView instance;
- resizing / relayout / model reads / destination reveal / Tap 2 do not retrigger it.

The glow lives in a dedicated layer below cards and destinations, so it does not cover card art or text.

No looping, spin, screen flash, camera shake, confetti or strobe mechanism was added.

## 6. Reduced Effects

PASS.

Reduced Effects:
- contains no celebration sequencer step;
- card scale does not bounce above 1.0;
- glow remains a static restrained halo;
- NEW / FIRST COPY text remains explicit;
- DUPLICATE / EXTRAS truth remains identical;
- both pack interaction gates remain intact.

## 7. Sequencing / owner-visible pacing note

PASS technically, with an owner-visible note.

The final shipping order is:

frames 01→09  
-> cards emerge  
-> accepted pack fade  
-> NEW celebration  
-> existing hold  
-> destinations  
-> Tap 2 routing.

The initial C009 prompt listed celebration before the pack-gone hold. Claude first implemented that order, then moved the celebration immediately **after the unchanged pack fade** because Premium all-NEW evidence showed pack/logo interference with top-row labels.

This does not change:
- frame cadence;
- emergence;
- pack fade duration;
- Tap 1;
- destination timing relative to the completed celebration;
- Tap 2;
- routing;
- completion;
- authority.

The audit criteria require celebration after/with card settle and before the routing gate, which the implementation satisfies.

Because this is an intentional visible pacing choice, final acceptance belongs to the OWNER VISUAL GATE.

## 8. Standard / Premium layout and visual evidence

PASS for technical layout/readability.

I independently reviewed representative real-runtime evidence including:
- Standard mixed celebration;
- Standard mixed final hold;
- Standard same-card triple;
- Premium mixed 3+2 hold;
- Premium duplicate-heavy 3+2 hold;
- Premium Reduced hold;
- 1536×2048 Premium mixed hold.

Findings:
- Standard 3-card geometry remains intact;
- Premium 3+2 geometry remains intact;
- no card-card overlap is visible;
- no destination/card collision is visible;
- NEW/DUPLICATE badges remain readable;
- FIRST COPY is readable;
- EXTRAS xN is readable;
- repeated-card x1/x2 progression is visually clear;
- Premium duplicate-heavy counts including x10 remain readable;
- static glow stays behind the card content;
- Reduced state remains readable and restrained.

The evidence driver reports 31 captures and zero rejected layout states across the five target viewport sizes.

## 9. Routing / authority / idempotency

PASS.

Routing remains derived from committed `is_new`:
- NEW -> Collection;
- DUPLICATE -> Cards Exchange.

Focused tests verify destination points and route logs across mixed, repeated and duplicate-heavy fixtures.

The ceremony/CardView still contains no pack-open, grant, Collection mutation, exchange mutation, RNG, save or receipt mutation authority.

The C009 suite recreates Standard and Premium ceremonies from C008 committed models and proves four full presentations leave economy, Collection, rewards, RNG, ledger and save bytes unchanged.

A new ceremony instance may replay the visual celebration, which is presentation-only and explicitly permitted.

## 10. Asset preservation

PASS.

The focused suite hashes:
- all 9 Standard shipping frames against the accepted V03 manifest;
- all 9 Premium shipping frames against the accepted Premium manifest;
- Collection / Cards Exchange destination icons;
- `card_new_glow.png`.

The implementation commit itself contains no changes to those assets.

Canonical card PNGs and C008 receipt truth are unchanged.

## 11. Focused test / sensitivity quality

PASS.

Claude records:
- C009 focused suite: **25/25 PASS**;
- 12/12 deliberate mutations detected;
- Standard suite: 21/21;
- Premium suite: 19/19;
- Standard harness: 14/14;
- Premium harness: 11/11;
- C008 transaction suite: 27/27;
- relevant M39 / M43 / M54 suites: PASS;
- root: **5,323 / 5,323 PASS**;
- `git diff --check`: clean.

The sensitivity set materially targets the C009 contract, including:
- extras off-by-one;
- NEW -> EXTRAS x0;
- wrong duplicate count;
- live Collection truth recomputation;
- celebration retrigger;
- Reduced pulse;
- wrong glow asset;
- routing mutation;
- pack-frame mutation;
- oversized pop.

The oversized-pop check was corrected to use an independent fixed ceiling rather than the production constant itself, which makes that guard load-bearing.

These Godot runs were not independently rerun by ChatGPT in this audit environment. I independently inspected the production code, test logic, commit boundary and real runtime evidence. No material technical criteria gap remains.

## 12. Owner-review surface

PASS technically.

Existing Standard/Premium owner-review harnesses now expose suitable fixtures without duplicating shipping animation logic.

Standard:
- 1 mixed;
- 2 all NEW;
- 3 repeat;
- 4 same-card triple: FIRST COPY / EXTRAS x1 / EXTRAS x2;
- 5 all duplicate.

Premium:
- 1 mixed;
- 2 all NEW;
- 3 repeat;
- 4 duplicate-heavy.

R = replay.  
E = FULL / Reduced Effects.

## 13. Decision

**TECHNICAL_AUDIT_PASS / OWNER_VISUAL_GATE_REQUIRED**

SB-M43-067 remains OPEN.

No technical remediation is required at this point.

Owner must judge live in Godot:
- NEW glow strength;
- 4% pop feel;
- sequential multiple-NEW pacing;
- the choice to celebrate after the pack fade;
- FIRST COPY clarity;
- EXTRAS xN clarity;
- Premium 3+2 readability;
- Reduced Effects restraint.

On explicit OWNER VISUAL PASS:
- ChatGPT records final owner acceptance;
- ChatGPT closes SB-M43-067;
- frontier advances to SB-M43-068.

On owner rejection:
- ChatGPT records the rejection in root TASKS;
- targeted C009 remediation is issued in the same cycle.
