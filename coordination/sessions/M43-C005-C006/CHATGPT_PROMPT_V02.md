# M43-C005-C006 — STANDARD PACK INTERACTIVE OPENING REMEDIATION V02

Status: **READY FOR CLAUDE**
Date: 2026-10-04
Repository: `Sekiph82/Scrubbots`
Branch: `main`
Canonical task: **SB-M43-064**
Expected Claude log: `CLAUDE_LOG_V02.md`

Root `TASKS.md` is **READ ONLY for Claude**. ChatGPT is the sole writer of lifecycle/progress state.

## 0. OWNER DECISION

V01 technical audit passed, but the owner **REJECTED the shipping visual composition**.

Do not close SB-M43-064.
Do not start SB-M43-065.

Owner-required shipping flow:

**Standard Pack alone -> player tap -> animated 01→09 opening -> 3 cards emerge in the final beats -> pack disappears -> only the 3 cards remain -> Collection icon upper-left + Card Exchange icon upper-right -> wait for player tap -> NEW cards fly to Collection / DUPLICATE cards fly to Card Exchange -> ceremony completes.**

This exact sequence supersedes the V01 shipping composition.

## 1. FIRST ACTION — DESKTOP/GITHUB SYNC

Before reading implementation sources or changing files:

1. Work from exactly `C:\Users\sekip\Desktop\ScrubBots`.
2. Run `git fetch origin main --prune`.
3. Compare local `main` and `origin/main`.
4. Preserve owner-local `project.godot`, addons, dirty files and unrelated untracked work.
5. Synchronize the Desktop checkout with the latest `origin/main` non-destructively.
6. If the Desktop checkout cannot be synchronized safely without overwriting owner work, STOP and report the exact conflicting paths.
7. Only after local Desktop + latest GitHub state are synchronized may implementation begin.

No destructive reset, clean, checkout-overwrite, owner-file deletion or force-push.

## 2. READ FIRST

Read before edits:
- `CLAUDE.md`
- root `TASKS.md` read only
- `coordination/AUDIT_POLICY.md`
- `coordination/README.md`
- `coordination/sessions/M43-C005-C006/CHATGPT_PROMPT_V01.md`
- `coordination/sessions/M43-C005-C006/CHATGPT_AUDIT_V01.md`
- `coordination/sessions/M43-C005-C006/STANDARD_PACK_PRODUCTION_MATRIX_V01.md`
- `coordination/sessions/M43-C005-C005/CHATGPT_AUDIT_V01.md`
- current shipping Standard Pack ceremony
- shared `RevealSequencer`
- current BasePopup/ModalStack lifecycle
- canonical Collection and Card Exchange icon/destination assets already present in the repo.

## 3. SCOPE

This is **SB-M43-064 only**.

Preserve all V01 technical PASS behavior unless this prompt explicitly changes presentation/timing.

Do NOT implement:
- SB-M43-065 Premium Card Pack;
- SB-M43-066 transaction/commit authority;
- SB-M43-067 as a separate new feature;
- actual Card Exchange mutation/conversion;
- Collection mutation;
- reward/grant/save/progression authority;
- unrelated ceremony/plugin work.

The ceremony consumes exactly 3 precommitted read-only results.

## 4. REQUIRED SHIPPING STATE FLOW

### A. PACK_IDLE
- Standard Pack alone, centered and dominant.
- No opening strip/contact sheet.
- No revealed cards.
- No Collection icon.
- No Card Exchange icon.
- No Continue CTA.
- Must wait for deliberate player tap/click.
- Must not auto-open.

### B. OPENING_01_TO_09
On first player tap:
- play exact approved frames 01→09 in order;
- use the shared production `RevealSequencer`;
- only one current opening beat is visible at a time;
- never show all nine frames as shipping UI;
- ignore/reject extra taps so a second run cannot start.

### C. CARDS_EMERGE
In the final opening beats:
- the three live committed cards visually emerge from the opened pack;
- transition must read as a continuation of the pack opening;
- exactly 3 cards;
- preserve committed order, rarity, NEW/DUPLICATE and duplicate post-commit count truth.

### D. THREE_CARD_HOLD
After the reveal:
- pack/opening art disappears completely;
- exactly 3 revealed cards remain centered/readable;
- NEW/DUPLICATE remains explicit and non-color-only;
- rarity remains readable;
- duplicate owned count remains truthful;
- no card routes automatically.

### E. DESTINATIONS_VISIBLE
Before resolution:
- **Collection icon = upper-left**;
- **Card Exchange icon = upper-right**;
- both appear while the 3 cards remain visible;
- they are destination indicators, not competing panels;
- ceremony waits for a deliberate second player tap/click.

### F. CARD_ROUTING
On second player tap:
- every NEW card visibly animates toward Collection upper-left;
- every DUPLICATE card visibly animates toward Card Exchange upper-right;
- mixed results split correctly;
- repeated duplicates still produce exactly 3 deterministic route animations;
- cards must travel visibly, not vanish instantly;
- routing is presentation-only.

No inventory, exchange, reward, save or pack-opening mutation is allowed here.

### G. COMPLETE
Only after all 3 route animations finish:
- complete once through the existing ceremony/modal lifecycle;
- no stale timer/tween/signal;
- no duplicate completion callback.

## 5. TWO INTERACTION GATES ARE MANDATORY

1. Tap 1: PACK_IDLE -> start opening.
2. Tap 2: THREE_CARD_HOLD / DESTINATIONS_VISIBLE -> start routing.

A debug harness that automatically crosses both gates is not sufficient shipping proof.

Back/Escape must not leave a half-resolved state.

## 6. REDUCED EFFECTS

Preserve the same semantics and both taps.

Allowed:
- shorten animation;
- step quickly to final accepted open-pack state;
- reveal cards without flip/bounce/glow;
- use simple short translation/fade routing.

Not allowed:
- auto-open;
- auto-route;
- skip destination icons;
- change any card truth.

## 7. VISUAL LOCKS

- Initial screen = pack alone.
- Opening = one animated current frame, never 01→09 strip.
- Final hold = no pack visible.
- Collection icon upper-left.
- Card Exchange icon upper-right.
- Icons appear before Tap 2.
- NEW card visibly travels to Collection.
- DUPLICATE card visibly travels to Card Exchange.
- No clipping/safe-area collision on required aspect ratios.
- Canonical card art is not modified.
- No fake rarity frame is drawn over canonical cards.

## 8. TESTS

Focused SB-M43-064 coverage must prove at minimum:

1. initial pack-only state;
2. no auto-start;
3. Tap 1 required;
4. exact 01→09 order;
5. no shipping strip/contact-sheet node;
6. exactly 3 committed cards required;
7. pack absent in final three-card hold;
8. Collection upper-left / Card Exchange upper-right;
9. Tap 2 required;
10. NEW routes only to Collection;
11. DUPLICATE routes only to Card Exchange;
12. mixed fixture splits correctly;
13. repeated-duplicate fixture resolves exactly 3 routes;
14. routing performs no pack/grant/inventory/exchange/save mutation;
15. completion fires exactly once after 3 arrivals;
16. repeated taps/re-entry/cancel/free leak nothing;
17. Reduced Effects preserves both gates and routing truth;
18. previous hash/card/rarity/NEW-DUPLICATE guarantees remain green;
19. sensitivity mutations catch wrong destination, auto-start, auto-resolve and stale pack visibility.

## 9. RUNTIME EVIDENCE

Capture real shipping runtime states:

- `01_pack_idle_1080x1920.png`
- `02_opening_mid_1080x1920.png`
- `03_opening_late_cards_emerging_1080x1920.png`
- `04_three_card_hold_1080x1920.png`
- `05_destinations_visible_1080x1920.png`
- `06_mixed_pre_route_1080x1920.png`
- `07_new_card_to_collection_1080x1920.png`
- `08_duplicate_card_to_exchange_1080x1920.png`
- `09_complete_1080x1920.png`
- one Reduced Effects evidence sequence.

Also create an ordered evidence contact sheet/timeline. It is audit evidence only, never shipping UI.

The evidence/log must make both player-tap gates observable.

## 10. REGRESSION

Run:
- updated SB-M43-064 focused suite;
- SB-M43-063 RevealSequencer suite;
- relevant M43 popup/modal/Results/ceremony suites;
- relevant M39 Collection/CardPack suites;
- root `tests/run_tests.gd`;
- `git diff --check`.

No unexplained new warnings/errors.

## 11. LOG / PUBLISH / HANDOFF

Create:
- `coordination/sessions/M43-C005-C006/CLAUDE_LOG_V02.md`;
- `coordination/sessions/M43-C005-C006/STANDARD_PACK_PRODUCTION_MATRIX_V02.md`;
- V02 runtime evidence under `coordination/sessions/M43-C005-C006/evidence/`.

The V02 log must cite this prompt, V01 prompt, V01 independent audit, exact files changed, every required test command/result, both interaction gates, blockers and unverified assumptions.

Claude must:
- not edit root `TASKS.md`;
- not create a Claude audit/self-audit;
- not self-assign PASS;
- commit and push authorized implementation/evidence to `origin/main`.

Return final SHA, implementation paths, test summary, V02 matrix/log/evidence URLs and blockers if any.

Finish exactly:

`AWAITING_GPT_M43_C005_C006_V02_STANDARD_PACK_REMEDIATION_AUDIT`
