# M43-C005-C007 — CHATGPT PREMIUM PACK V01 INDEPENDENT AUDIT

Date: 2026-10-04  
Canonical task: **SB-M43-065**  
Audited implementation: `31f8e8f03807cacb00bd7ea0d91a2b727b784f35`  
Baseline: `527d09aace2988bfcd4760d48b9aa7a35f0a2722`  
Prompt: `CHATGPT_PROMPT_V01.md`  
Audit criteria: `CHATGPT_AUDIT_CRITERIA_V01.md`  
Result: **TECHNICAL_AUDIT_PASS / OWNER_VISUAL_GATE_REQUIRED**

## 1. Independent audit scope

Reviewed:
- C007 prompt and audit criteria;
- Claude implementation log;
- Premium production matrix;
- Premium frame manifest;
- actual implementation commit and changed-file boundary;
- Premium presentation model;
- Premium shipping ceremony;
- real CardPackService implementation;
- Premium deterministic fixtures;
- Premium focused suite;
- Premium owner-review harness + smoke test;
- Standard shipping ceremony change;
- Standard shipping frame blobs and Standard owner-review scene/controller;
- Premium decoded-pixel sensitivity JSON;
- checkerboard / gray / black Premium frame sheets;
- actual runtime Premium 01→09 contact sheet;
- five-card emergence / hold / destination / routing evidence;
- 1536×2048 destination hold evidence.

## 2. Governance / scope

PASS.

Claude's implementation commit does not change:
- root `TASKS.md`;
- `project.godot`;
- `scenes/app/main.tscn`;
- CardPackService authority;
- CollectionInventory authority;
- Cards Exchange authority;
- save/navigation/economy authority;
- SB-M43-066 integration work.

The implementation is presentation/evidence/tooling plus Premium frame promotion, with one minimal Standard shared hook.

Claude records a non-destructive Desktop sync before implementation and preservation of owner-local files.

## 3. Premium frame promotion / alpha gate

PASS.

Independent manifest reconciliation shows all nine shipping Premium frames are byte-identical to the previously owner-accepted C002 Premium candidates:

- 01 `29b87a206bae589ce4811641a40d352186a6bf01528cad9279b390c82031034c`
- 02 `44b88fbbc9796edadd13229268978ce7a3c94b22bcebd3bb9906f4d6a2bfe571`
- 03 `cf79d5b85d6227f69b462261e350c8bb1e27d8ad9deab135f5201faf778d9af6`
- 04 `2cbe8a7470e403a68768bb0aa7ada536d1c5e52dbc92ee77d36d0406a9f2493f`
- 05 `072dbc8f4accd17b4eb0c4a679cb47d0fe5bf1083f7576480c926712be8ab564`
- 06 `242a6d8166082f7e13e7f920bbe7249b62ba5626c2ef682cb9b9f1860a0d1b62`
- 07 `f47a7b6ecb8d02f444acf4dd75d25f0276f8a9f2459320a799edee94768d9dfa`
- 08 `72d63957839455a442120a1cfa8c78e2c3e319c3627322d0fb10c5a883afb065`
- 09 `0de24ea3509518b8a358d733925cee30b8bc4087219dceecc39f20bec750977a`

All nine V01 manifest rows report decoded-pixel `clean=true` with no validator failure. No Premium remediation was required.

The pack-art card-back count progression remains:
`0,0,0,0,0,1,1,5,5`.

### Independent visual alpha review

PASS.

I independently reviewed:
- `PREMIUM_V01_checkerboard_01_09.png`;
- `PREMIUM_V01_gray_01_09.png`;
- `PREMIUM_V01_black_01_09.png`;
- actual runtime `PREMIUM_RUNTIME_01_09_V01_CONTACT_SHEET.png`.

No black/dark rectangular matte, semi-transparent box, straight canvas cut or residual rectangular haze is visible. Glow remains intentionally translucent and irregular.

The published validator sensitivity JSON has **32 rows / 0 expectation mismatches**:
- all nine clean Premium frames PASS;
- inserted opaque black rectangle on each Premium frame FAILS;
- inserted semi-transparent dark rectangle on each Premium frame FAILS;
- historical dirty Standard 05..09 controls FAIL.

## 4. Premium presentation model

PASS.

`PremiumPackModel` fails closed and enforces:
- non-empty presentation_id;
- `kind == "premium"`;
- exactly 5 cards;
- canonical card ID;
- canonical art/name/rarity;
- strict bool `is_new`;
- integer/coherent `copies_after`;
- repeated-card copies increment in input order;
- duplicate cards allowed;
- card 0 rarity must be RARE, EPIC or LEGENDARY.

The validated model appends rows in source order and performs no sort/reorder.

A COMMON card 0 is rejected even if later cards are Rare+.

## 5. CardPackService guarantee truth

PASS.

Production `CardPackService.open_premium()` explicitly:
1. draws one Rare-or-better;
2. appends that guaranteed card first;
3. adds four arbitrary eligible draws after it.

Production constant:
`PREMIUM_DRAWS == 5`.

Therefore the C007 model's card-0 Rare+ contract exactly matches current service order.

The focused suite additionally exercises 200 deterministic real-service Premium openings and records:
- five draws every time;
- first returned card always Rare/EPIC/LEGENDARY;
- COMMON cards appear in later slots;
- every returned service-order result maps to a valid Premium presentation model.

The shipping ceremony/model themselves contain no CardPackService call or RNG authority.

## 6. Shipping ceremony architecture

PASS.

`PremiumPackCeremony` specializes the accepted Standard ceremony rather than introducing a competing state machine.

Premium-specific differences are limited to:
- Premium frame directory;
- Premium model validation;
- Premium title;
- five-card 3+2 hold geometry;
- frame-09 five-card-back emergence origins.

Shared Standard behavior remains:
- BasePopup / ModalStack lifecycle;
- RevealSequencer;
- two deliberate tap gates;
- 01→09 sequencing;
- destination semantics;
- serialized routing;
- completion semantics;
- Reduced Effects behavior.

## 7. Standard non-regression

PASS.

The only production change to `standard_pack_ceremony.gd` is a frame-path hook:
- constructor now loads returned paths from `_frame_paths()`;
- Standard's default `_frame_paths()` returns the same canonical Standard frame directory + the same nine filenames.

Independent Git blob comparison confirms all nine owner-accepted Standard shipping PNGs are unchanged.

Independent Git blob comparison also confirms:
- `tests/tools/owner_review/standard_pack_owner_review.gd` unchanged;
- `tests/tools/owner_review/standard_pack_owner_review.tscn` unchanged.

Claude records:
- Standard focused suite **21/21 PASS**;
- Standard owner-review harness smoke **14/14 PASS**.

The Standard harness source pin was correctly rebaselined because the source hook changes bytes while preserving behavior.

## 8. FULL Premium cadence

PASS.

Premium inherits the owner-accepted Standard cadence:
- frame 01 configured 0.40 s;
- frames 02..08 configured 0.22 s;
- frame 09 configured 0.30 s before live-card emergence.

The Premium focused suite measures actual bind-to-bind runtime timing and requires exact history:
`[1,2,3,4,5,6,7,8,9]`.

Claude records four stable focused runs:
- frame 01 approximately 0.384–0.399 s;
- frames 02..08 approximately 0.204–0.236 s;
- shortest measured hold 0.204 s > required 0.18 s.

Runtime contact-sheet evidence visibly contains nine chronological Premium states, one pack frame at a time.

## 9. Five-card emergence / hold

PASS technically and visually.

Premium uses the accepted C002 frame-09 five-card-back geometry as five distinct emergence origins.

Independent review of runtime evidence confirms:
- five live cards emerge on frame 09;
- the pack disappears;
- the final hold contains exactly five cards;
- layout is centered 3+2;
- order is 0,1,2 on the first row and 3,4 on the second;
- all card faces, names, rarity, NEW/DUPLICATE and copies-after text remain readable.

The 1080×1920 hold is clear, and the 1536×2048 destination state remains non-overlapping and comfortably within the safe area.

## 10. Destinations / Tap 2 / routing

PASS.

Before Tap 2:
- Collection is upper-left;
- Cards Exchange is upper-right;
- both are clear of all five cards;
- the five cards wait;
- no automatic route begins.

After Tap 2:
- NEW -> Collection;
- DUPLICATE -> Cards Exchange;
- all five route exactly once;
- routing is serialized;
- arrival order is deterministic 0..4;
- completion occurs after the fifth arrival.

Independent runtime evidence visibly shows both a NEW card travelling to Collection and a DUPLICATE travelling to Cards Exchange.

## 11. Card truth / Rare+ visibility

PASS.

Five-card UI renders canonical card art and text truth:
- name;
- rarity;
- NEW or DUPLICATE;
- copies-after.

Card 0 is not reordered and its Rare+ rarity remains visible.

No invented "GUARANTEED RARE+" badge is added.

No second decorative rarity frame is layered over the canonical already-framed card art.

## 12. Authority safety

PASS.

Independent source inspection confirms Premium presentation code does not:
- open a pack;
- draw RNG;
- add/mutate Collection cards;
- mutate Cards Exchange;
- grant rewards;
- save;
- navigate;
- consume pack/currency state;
- claim set/master completion.

The focused state-mutation test snapshots economy, Collection, RNG and save bytes and requires them to remain unchanged after a complete Premium presentation.

The test then performs a real `open_premium()` as a sensitivity control and detects the state/RNG change.

## 13. Lifecycle

PASS.

Focused coverage includes:
- extra OPENING taps refused;
- extra ROUTING taps refused;
- Back/Escape consumed without leaving the ceremony half-resolved;
- clear/close across IDLE/OPENING/AWAIT_ROUTE/ROUTING;
- no late completion;
- no retained tween/node leak;
- completed instance cannot replay;
- clean re-entry with a new committed model;
- completion exactly once after 5 arrivals.

## 14. Reduced Effects

PASS.

Reduced Effects preserves:
- Premium pack IDLE;
- Tap 1;
- same five cards/order/truth;
- frame-09 semantic shortcut;
- same 3+2 hold;
- destinations;
- Tap 2;
- same routing destinations;
- one completion.

No content or grant semantic changes.

## 15. Owner-review harness

PASS technically.

The Premium review scene/controller:
- instantiates the real shipping Premium ceremony;
- uses the real ModalStack;
- defaults to five-card mixed fixture with Rare+ card 0;
- never auto-taps;
- contains no duplicate frame/timing/layout/state-machine logic;
- contains no authority;
- supports R / E / 1 / 2 / 3;
- all fixtures retain Rare+ card 0;
- is not startup/autoload/main scene.

Claude records Premium harness smoke **11/11 PASS**.

## 16. Sensitivity evidence

PASS with one audit note.

Claude executed source mutations that detect:
- COMMON card 0;
- wrong destination;
- auto-start;
- auto-route;
- skipped frame;
- FULL hold below 0.18 s;
- stale pack visible;
- dirty Premium frame.

The focused suite also contains explicit static sensitivity injection for forbidden `open_premium()` / sorting authority.

**NOTE:** a separate source-mutation run for a repeated/out-of-order Premium frame was not recorded in the Claude mutation batch. However the load-bearing runtime assertion is exact equality to `[1,2,3,4,5,6,7,8,9]`, so a repeated or out-of-order history necessarily fails the same check; the executed skipped-frame mutation already proves that exact-history assertion is active. I record this as a sensitivity-evidence completeness note, not a production defect.

## 17. Automated validation boundary

Claude records:
- Premium focused suite: **19/19 PASS**, four runs;
- Premium owner-review harness: **11/11 PASS**;
- Standard focused suite: **21/21 PASS**;
- Standard owner-review harness: **14/14 PASS**;
- Premium background validator: **9/9 CLEAN**;
- Standard background validator: **9/9 CLEAN**;
- RevealSequencer: **12/12 PASS**;
- relevant M43 suites: PASS;
- relevant M39/M54 Collection/CardPack suites: PASS;
- root suite: **5,323 / 5,323 PASS**;
- `git diff --check`: clean;
- no final script errors.

These Godot command executions were **not independently rerun by ChatGPT in this audit environment**. I independently inspected production source, focused-test logic, manifest/sensitivity evidence, Git blob identity and runtime visual evidence.

No material false-positive or untested production gap was found.

## 18. Decision

**TECHNICAL_AUDIT_PASS / OWNER_VISUAL_GATE_REQUIRED**

No technical remediation prompt is required.

**SB-M43-065 remains OPEN.**

Next actor: **OWNER**.

Owner should run:
`res://tests/tools/owner_review/premium_pack_owner_review.tscn`

with **F6** and judge the live Premium ceremony, especially:
- all 9 gold Premium opening beats;
- no rectangular/dark matte;
- the five cards emerging from the five frame-09 card backs;
- 3+2 final composition;
- card readability;
- Collection / Cards Exchange placement;
- NEW / DUPLICATE routing feel;
- overall Premium pacing.

Only explicit **OWNER VISUAL PASS** closes SB-M43-065 and unlocks SB-M43-066.
