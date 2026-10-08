# SB-M43-C005F-005 — Standard / Premium pack + individual-card reveal feel — CLAUDE_LOG_V01

- Milestone: M43-C005F-PHASE2 (child 3 of 3)
- Start SHA: `a6842fd274665a871d9921052768d3dd9a67e0e3`
- Final SHA: the Phase 2 implementation commit (see master log)
- Child state: **TECHNICALLY COMPLETE — AWAITING GPT AUDIT + OWNER VISUAL REVIEW**

## Exact files changed

- `scripts/ui/ceremony/standard_pack_ceremony.gd` (Premium inherits it unchanged):
  - `bind_feedback()` / `feel_log()`;
  - `_card_feel_on_step()` is called from the existing `_on_step`;
  - `CardView.get_face()` / `get_badge()`.

  No frame, timing, layout, routing, model or state code changed.
- `scripts/ui/feel/feedback_adapter.gd`: the shared placement change (see the F003 log). This is what makes bursts render **above** the popup scrim: ModalStack is CanvasLayer 64, and Spark's pool sits in the root canvas below it.
- Tests: `tests/m43_c005f_phase2_results_pack_feel.gd` (p01–p06, g03).

## Authority seam

- The ceremony takes the optional app adapter through `bind_feedback(adapter)`. Null means exactly the native ceremony.
- There is still no production pack call site in `scripts/`: today the ceremonies are opened only by owner-review harnesses and tests. Any future presenter binds `main.feel` through this setter.
- Nothing reaches AppState, PackCommitTransaction, the pack models, Collection or the save. The k24/k25 static scan of the C009 ceremony source is unchanged and PASS.

## Event-key / idempotency contract

- Trigger: an open-run step starting means the previous card has **landed** in its hold slot (the next emerge step, or the pack-out step after the last card).
- Eligible cards are NEW or Rare-or-better (RARE/EPIC/LEGENDARY). A COMMON duplicate gets nothing.
- Each eligible card gets one adapter **REWARD** burst at its NEW/DUPLICATE badge (the face's top edge), keyed `<presentation_id>:card<i>:reveal`. `presentation_id` is the committed pack `tx_id` (PackCommitTransaction).
- Bursts are serialized: cards land one emerge step (0.24 s) apart, so Premium never fires all five at once (p02: 5 bursts on 5 different frames).
- Intents: only REWARD is used, never WIN or MAJOR_*; no Premium group burst was added. There is no flash and no GFF on these Controls.
- Reopening the same committed presentation with a new ceremony instance gives zero new feel events (keys consumed) and the same model, so nothing is rerolled (p04). The native NEW pulse keeps its existing per-instance behaviour, which the C009 k23 test covers.

## FULL / REDUCED behaviour

- **FULL:** native frames 01→09, card emergence, the NEW pulse/glow and pack-out are all unchanged. The only additions are serialized REWARD `pickup` bursts at the badges of eligible cards (8 particles, ≤0.7 s).
- **REDUCED:** the ceremony never calls the adapter at all, so there is zero plugin work (p05). The existing reduced grammar, the static NEW glow at rest alpha 0.5, and the NEW/DUPLICATE/copies truth are unchanged.

## Tests

| Case | What it checks |
|---|---|
| p01 | Standard: 3 cards; frames `[1..9]`; pack gone; destinations shown; REWARD only for eligible cards, in model order, with exact keys; each fired only after its card's emerge reached 1.0; burst at the badge centre; no GFF call; Tap 2 routes and completes |
| p02 | Premium: exactly 5 cards in draw order; card 0 Rare-or-better; 3+2 hold layout unchanged; 5 bursts on 5 distinct frames; REWARD only |
| p03 | card id, rarity, NEW, copies, badge and count text identical with and without feel |
| p04 | reopen: 0 new events; same committed model |
| p05 | Reduced: zero adapter or plugin calls; static glow |
| p06 | plugins absent or throwing (deliberate, labelled faults): Tap 1 → hold → Tap 2 → complete |
| g03 | **real plugins:** bursts are reparented into the ModalStack CanvasLayer and freed within the REWARD ceiling; the Results-in-SubViewport case renders inside the SubViewport |

Existing regressions, all PASS:
- `m43_c005_c006_standard_pack_presentation` 21/21;
- `m43_c005_c007_premium_pack_presentation` 19/19;
- owner-review harness suites;
- `m43_c005_c009_card_state_celebration` 25/25;
- `m43_c005_c008_pack_commit_transaction`.

## Runtime evidence

Real `AppState.commit_pack()` models, shipping ceremonies on the app's ModalStack, the app adapter and real taps:
- `standard_full_*_reveal_feel(.png|_rising.png)` and `premium_full_*_reveal_feel(...)`: mid-reveal with bursts;
- `*_full_*_hold.png`;
- `*_reduced_*_hold.png`.

Each at 1080×2160 and 1536×2048.

## Blockers / deviations

- **Owner-tuning item (important, honest):** on screen the Spark `pickup` accent is **very subtle**. It is a few light-cyan dots at the NEW badge, short-lived, and easy to miss against the bright card art. Two things were changed after evidence review to make it render at all:
  - placement moved from the card centre (invisible on the cyan/white art) to the badge;
  - particle radius ×2.5.

  The preset and intensity mapping is the Phase 1 audited contract (REWARD → pickup ×8) and was deliberately not changed. If the owner wants a stronger accent, a follow-up should pick a contrasting colour or preset within the same budgets.
- No Premium final-group MAJOR_REWARD burst was added. It was optional ("at most"), and leaving it out avoids particle pile-up.
