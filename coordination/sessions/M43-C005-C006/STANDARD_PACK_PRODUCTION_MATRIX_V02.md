# M43-C005-C006 — Standard Pack Production Matrix V02 (SB-M43-064, interactive opening)

Date: 2026-10-04 · Implementer: Claude · Status: AWAITING_AUDIT (no verdict claimed) · owner visual gate still open

Supersedes the V01 shipping composition (owner-rejected). V01 asset/model/catalog guarantees are kept unchanged
(promoted frame hashes, fail-closed model, canonical card catalog) — see `STANDARD_PACK_PRODUCTION_MATRIX_V01.md` §1.

## 1. Shipping state machine (`scripts/ui/ceremony/standard_pack_ceremony.gd`)

| Phase | On screen | Leaves on |
|---|---|---|
| `IDLE` | Standard Pack alone (frame 01), centred; title; live hint "Tap to open". No card, no destination, no CTA, no cream frame. | **Tap 1** (real pointer press on the ceremony layer) |
| `OPENING` | One `PackFrame` TextureRect re-bound 01 → 09 (holds 0.40 s then 0.14 s per beat). On frame 09 the 3 committed cards rise from the pack mouth into a centred row (model order, 0.24 s each), the pack fades out (0.25 s), a 0.40 s three-card hold with no pack, then Collection (upper-left) + Cards Exchange (upper-right) fade in (0.25 s). Taps ignored. | sequencer `"<id>:open"` completed |
| `AWAIT_ROUTE` | Pack hidden; 3 cards at their slots; both destinations; live hint "Tap to collect your cards". Nothing moves on its own. | **Tap 2** |
| `ROUTING` | Each card in model order travels (0.45 s, ease-out, shrinking, fading only in the last 20 %) to its destination: NEW → Collection, DUPLICATE → Cards Exchange. Taps ignored. | 3 arrivals + sequencer `"<id>:route"` completed |
| `COMPLETE` | `presentation_completed(id)` once, then `close("complete")` → ModalStack removes/frees the popup. | — |

Back/Escape in every phase: consumed by ModalStack, popup not dismissible → no change. Route clear / close in any phase:
sequencer cancelled, no late completion.

Reduced Effects: same phases, same two taps, same destinations; opening binds frame 09 only (shown 0.15 s), cards fade in at their
slots (0.10 s), pack out 0.10 s, hold 0.15 s, destinations 0.10 s, routes 0.20 s each (straight short move + fade). No auto step.

Authority: presentation only. Consumes one validated `StandardPackModel` (exactly 3 committed cards). No `open_standard/premium`,
grant, Collection add, Cards Exchange call, save or navigation. The routes are a picture of where the committed cards already are.

Assets: promoted Standard frames (unchanged, V01 §1); canonical C003 cards; existing approved destination icons
`assets/ui/final/home/shortcuts/icon_shortcut_collection.png` and `icon_shortcut_cards_exchange.png` (no new art).

## 2. Requirement → test matrix (`tests/m43_c005_c006_standard_pack_presentation.gd`, 19 cases)

Taps in the suite are real `InputEventMouseButton` press/release pushed through `SubViewport.push_input` (GUI path), not direct calls.

| Prompt §8 | Case | Direct assertion | Source mutation caught by |
|---|---|---|---|
| 1 pack-only start | v01 | IDLE, frame 01 bound, no card/destination visible, no action/visible button, cream frame hidden, "Tap to open" | M2 |
| 2 no auto-start | v02 | 150 untouched frames: IDLE, no frame bound, sequencer idle, no tween | M2 |
| 3 Tap 1 required / one run | v03 | real tap → OPENING; extra taps refused; exactly one `":open"` run | M2, M7 |
| 4 exact 01→09 | v03 | `frame_history == [1..9]`; beat N binds manifest's Nth name + sha256 | M5 |
| 5 no strip | v03 | never more than one pack-frame TextureRect drawn; no card before frame 09 | — |
| 6 exactly 3 cards | c03, c13 | 0/1/2/4/5 rejected `card_count`; 3 == configured draws | (V01 M3) |
| 7 pack absent in hold | v04 | a hold with pack alpha 0 and cards alpha 1 precedes destinations; at AWAIT_ROUTE stage not visible, 3 cards at slots, ordered, no overlap | M4 |
| 8 corners | v05 | Collection centre x < 25 % / y < 20 % of viewport; Exchange x > 75 % / y < 20 %; visible before Tap 2; approved textures; text labels; no overlap with cards; inside safe area | — |
| 9 Tap 2 required | v06 | 150 untouched frames at AWAIT_ROUTE: no route, cards at slots; real tap → ROUTING; extra taps refused | M3 |
| 10–12 routing | v07 | mixed (NEW, DUP, NEW): route log `[[0,collection],[1,exchange],[2,collection]]`; every card observed mid-route, closer to its own destination, visible; end points = icon centres | M1 |
| 13 repeated duplicates | v08 | NEW + DUP ×2: exactly 3 routes `[[0,c],[1,e],[2,e]]`, arrivals `[0,1,2]`, identical across two runs | M1 |
| 14 no mutation | v09 | full two-tap flow: caller + validated model, economy/Collection/exchange snapshot, pack RNG state, save bytes unchanged; real `open_standard()` detected (sensitivity) | — |
| 15 completion once | v10 | events exactly `[completed(id) with 3 arrivals, closed("complete")]`; popup removed and freed | M3 |
| 16 lifecycle | v11 | Back + ui_cancel at IDLE/OPENING/AWAIT_ROUTE/ROUTING change nothing; 16 clears/closes: no completion, no tween/node/connection left; post-route taps refused, opening never re-run; freed mid-run (second stack) leaves no tween | M7 |
| 17 Reduced | v12 | no auto-open; frame history `[9]`; AWAIT_ROUTE info == FULL (cards, order, rarity, state, counts, destinations, hint); no auto-route; visible short route; completed once | M6 |
| 18 V01 guarantees | c01, c05, c06, c07, c12, c13 | hashes; canonical 135 tree + no overlay frame; rarity/name; NEW/DUP + counts; static guard now also bans `CardsExchange`/`exchange_card`/`exchange_all_extras`; 11 bad models rejected with exact reason | V01 M2–M4, M7 |
| 19 sensitivity | log §3 | M1 wrong destination, M2 auto-start, M3 auto-resolve, M4 stale pack, M5 frame swap, M6 Reduced chain, M7 Tap 1 not one-shot | — |

## 3. Runtime evidence (`evidence/v02/`, rendering driver, `tests/tools/standard_pack_snapshot.gd`)

Real flows with real taps pushed through the SubViewport; each shot is taken the first frame its state predicate holds; the
tool waits 20 frames at IDLE and at AWAIT_ROUTE and rejects any auto-advance (both gates observable). Layout check per shot:
title/hint/destination icons + labels inside the safe layer, label text never wider than its rect, cards inside the safe
layer and never overlapping a destination, pack never visible together with destinations. Result: 0 REJECTED.

| File | State |
|---|---|
| `01_pack_idle_1080x1920.png` | IDLE, pack alone, "Tap to open" (before Tap 1) |
| `02_opening_mid_1080x1920.png` | frame 05 |
| `03_opening_late_cards_emerging_1080x1920.png` | frame 09, card 2 rising out of the pack |
| `04_three_card_hold_1080x1920.png` | pack gone, 3 cards, no destinations yet |
| `05_destinations_visible_1080x1920.png` | AWAIT_ROUTE, repeated-duplicate pack (Mighty Mop NEW 1 / DUP 2, Sludge Beast DUP 5) |
| `06_mixed_pre_route_1080x1920.png` | AWAIT_ROUTE, mixed pack (before Tap 2) |
| `07_new_card_to_collection_1080x1920.png` | Mud Blob (NEW) mid-route to Collection |
| `08_duplicate_card_to_exchange_1080x1920.png` | Greasy Pan (DUPLICATE) mid-route to Cards Exchange |
| `09_complete_1080x1920.png` | after `close("complete")`: popup gone (backdrop only) |
| `10_repeat_duplicate_to_exchange_1080x1920.png` | Sludge Beast (DUPLICATE ×5) mid-route to Cards Exchange |
| `R1..R5_reduced_*_1080x1920.png` | Reduced: idle → frame 09 → destinations → routing → complete |
| `V_destinations_<w>x<h>.png` | AWAIT_ROUTE at 1080×1920, 1080×2160, 1170×2532, 1290×2796, 1536×2048 |
| `V02_evidence_timeline_EVIDENCE_ONLY.png` | ordered timeline of the above (audit evidence only; never shipping UI) |

Flow log (tool stdout): mixed `frames [1..9]`, routes `[[0,collection],[1,exchange],[2,collection]]`, arrivals `[0,1,2]`,
closed `complete`, taps 2; Reduced `frames [9]`, same routes/arrivals, taps 2.

## 4. Owner visual gate

Technical evidence only. Composition, sizes, timings and the reuse of the Home shortcut icons as destinations are an owner
visual decision; SB-M43-064 stays open until owner visual PASS of this V02 ceremony.
