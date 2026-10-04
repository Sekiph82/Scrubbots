# M43-C005-C007 — CHATGPT AUDIT CRITERIA V01

Canonical task: **SB-M43-065**  
Target: shipping Premium Card Pack presentation for 5 committed draws with real CardPackService Rare-or-better guarantee truth.

## Governance / sync

- [ ] Claude synchronized `C:\Users\sekip\Desktop\ScrubBots` with latest `origin/main` before implementation.
- [ ] owner-local `project.godot`, `main.tscn`, addons/untracked work preserved.
- [ ] root `TASKS.md` untouched by Claude.
- [ ] SB-M43-066 not started.
- [ ] no parallel tracker/roadmap created.

## Premium asset gate

- [ ] all 9 Premium candidates diagnosed from decoded pixels before promotion.
- [ ] all final Premium frames are 1024×1536 RGBA.
- [ ] no black/dark rectangular matte on any 01..09 final.
- [ ] no dark semi-transparent rectangular wash.
- [ ] no straight matte/alpha cut.
- [ ] checkerboard 3×3 sheet clean.
- [ ] white 3×3 sheet clean.
- [ ] 50% gray 3×3 sheet clean.
- [ ] black 3×3 sheet clean.
- [ ] owner-approved Premium pack identity/geometry/tear/card-back progression preserved.
- [ ] historical C002 Premium candidates preserved.
- [ ] clean frames preserved byte-for-byte where remediation was unnecessary.
- [ ] remediated frames, if any, have reproducible alpha-only tooling + sensitivity proof.
- [ ] final shipping Premium frame manifest exists with hashes/metrics.
- [ ] exactly 0/0/0/0/0/1/1/5/5 pack-art card-back counts remain correct.

Any remaining rectangular matte/background = FAIL.

## Presentation model truth

- [ ] non-empty presentation_id required.
- [ ] Premium kind required.
- [ ] exactly 5 cards required.
- [ ] source/service order preserved.
- [ ] canonical 135-card ids only.
- [ ] canonical art/name/rarity truth enforced.
- [ ] strict bool NEW/DUPLICATE truth.
- [ ] coherent copies_after validation.
- [ ] repeated-card ordering coherent.
- [ ] card 0 is required to be Rare-or-better.
- [ ] card0 COMMON model rejected even if another card is Rare+.
- [ ] duplicates allowed.

## CardPackService guarantee proof

- [ ] production `CardPackService.PREMIUM_DRAWS == 5`.
- [ ] actual `open_premium()` service behavior is test-covered.
- [ ] first service draw is Rare/EPIC/LEGENDARY.
- [ ] remaining four draws remain eligible arbitrary draws.
- [ ] presentation does not call `open_premium()`.
- [ ] presentation does not own RNG or grant authority.

## Owner-locked visual sequence

- [ ] Premium pack alone initially.
- [ ] no cards/destination icons initially.
- [ ] Tap 1 required.
- [ ] no auto-open.
- [ ] FULL uses exact 01→09 Premium order.
- [ ] one current pack-frame node only.
- [ ] no shipping contact sheet/strip.
- [ ] frame 01 hold 0.40 s target.
- [ ] frames 02..08 hold 0.22 s target.
- [ ] each effective 01..08 hold >=0.18 s.
- [ ] frame 09 rests before live cards emerge.
- [ ] no live card face before final opening beat.
- [ ] exactly 5 live cards emerge from opened pack.
- [ ] pack then disappears.
- [ ] exactly 5 card faces remain.

## Five-card hold

- [ ] centered 3+2 layout.
- [ ] order is 0,1,2 top row then 3,4 bottom row.
- [ ] no overlap/clipping.
- [ ] all 5 canonical card arts readable.
- [ ] all 5 rarity labels readable.
- [ ] all 5 NEW/DUPLICATE states readable in text.
- [ ] copies_after presentation truthful.
- [ ] card 0 Rare+ remains readable and is not reordered.
- [ ] no invented GUARANTEED badge unless pre-existing owner-approved UI authority exists.

## Destination / Tap 2 / routing

- [ ] Collection upper-left.
- [ ] Cards Exchange upper-right.
- [ ] both visible before Tap 2.
- [ ] icons clear of all cards.
- [ ] cards wait indefinitely before Tap 2.
- [ ] no auto-route.
- [ ] Tap 2 required.
- [ ] NEW -> Collection only.
- [ ] DUPLICATE -> Cards Exchange only.
- [ ] all 5 cards route exactly once.
- [ ] deterministic arrival order.
- [ ] each card visibly travels.
- [ ] completion only after all 5 arrivals.
- [ ] completion emitted once.

## Authority safety

- [ ] no pack-open call in ceremony/model.
- [ ] no add_card / Collection mutation.
- [ ] no Cards Exchange mutation.
- [ ] no reward grant.
- [ ] no RNG.
- [ ] no save.
- [ ] no navigation.
- [ ] no currency/pack-count consumption.
- [ ] no set/master claim authority.
- [ ] state snapshots prove ceremony changes presentation only.

## Lifecycle

- [ ] extra OPENING taps refused.
- [ ] extra ROUTING taps refused.
- [ ] Back/Escape cannot half-resolve ceremony.
- [ ] close/route-clear/free cancels active sequencing.
- [ ] no late completion after cancellation.
- [ ] no leaked tweens/nodes/connections.
- [ ] single popup instance cannot replay after completion.
- [ ] clean re-entry with a new presentation id/model.

## Reduced Effects

- [ ] starts at pack IDLE.
- [ ] still requires Tap 1.
- [ ] may use frame 09 shortcut only.
- [ ] same 5 cards/order/truth.
- [ ] same 3+2 final hold.
- [ ] same destinations.
- [ ] still requires Tap 2.
- [ ] same five routing destinations.
- [ ] completes once.
- [ ] no truth/grant semantic change.

## Standard Pack non-regression

- [ ] SB-M43-064 shipping frame bytes unchanged.
- [ ] Standard V03 cadence unchanged.
- [ ] Standard two-tap flow unchanged.
- [ ] Standard 3-card layout/routing unchanged.
- [ ] Standard focused suite PASS.
- [ ] Standard owner-review harness smoke PASS.
- [ ] any shared refactor has direct Standard parity proof.

## Sensitivity

Deliberate broken versions must be detected for:
- [ ] card0 COMMON.
- [ ] wrong destination.
- [ ] auto-start.
- [ ] auto-route.
- [ ] skipped Premium frame.
- [ ] repeated/out-of-order Premium frame.
- [ ] FULL hold <0.18 s.
- [ ] pack left visible during final hold.
- [ ] dirty opaque/semi-transparent Premium rectangle.
- [ ] presentation authority call injected.

## Runtime evidence

- [ ] actual Premium runtime frame capture exists for each 01..09.
- [ ] `PREMIUM_RUNTIME_01_09_V01_CONTACT_SHEET.png` exists.
- [ ] five-card emerge capture exists.
- [ ] pack-free 3+2 hold capture exists.
- [ ] destinations capture exists.
- [ ] mixed pre-route capture exists.
- [ ] NEW travel capture exists.
- [ ] DUPLICATE travel capture exists.
- [ ] completion capture exists.
- [ ] Reduced Effects evidence exists.
- [ ] destination hold passes 1080×1920.
- [ ] passes 1080×2160.
- [ ] passes 1170×2532.
- [ ] passes 1290×2796.
- [ ] passes 1536×2048.

## Owner review harness

- [ ] Premium owner-review scene/controller exists under tests/tools/owner_review.
- [ ] F6 runs it directly.
- [ ] real shipping Premium ceremony used.
- [ ] real ModalStack used.
- [ ] default fixture is mixed and card0 Rare+.
- [ ] owner supplies both clicks.
- [ ] no harness auto-tap.
- [ ] R replay works.
- [ ] E FULL/Reduced works.
- [ ] 1 mixed works.
- [ ] 2 all-new works.
- [ ] 3 repeated-duplicate works.
- [ ] all fixtures retain Rare+ card0.
- [ ] no duplicated animation/timing/state machine in harness.
- [ ] no authority in harness.
- [ ] harness not startup/autoload/main scene.

## Automated validation

- [ ] Premium focused suite PASS.
- [ ] Premium harness smoke PASS.
- [ ] Premium alpha/matte validator PASS.
- [ ] RevealSequencer suite PASS.
- [ ] M39 CardPack/Collection regressions PASS.
- [ ] relevant M43 modal/popup/ceremony regressions PASS.
- [ ] Standard presentation + harness regressions PASS.
- [ ] root suite PASS.
- [ ] `git diff --check` clean.
- [ ] no unexplained runtime/script errors.

## Handoff / closure

- [ ] `PREMIUM_PACK_PRODUCTION_MATRIX_V01.md` exists.
- [ ] `PREMIUM_FRAME_MANIFEST_V01.json` exists.
- [ ] `OWNER_REVIEW_INSTRUCTIONS_V01.md` exists.
- [ ] `CLAUDE_LOG_V01.md` exists.
- [ ] final SHA reported.
- [ ] handoff ends `AWAITING_GPT_M43_C005_C007_V01_PREMIUM_PACK_AUDIT`.

Technical PASS alone does not close SB-M43-065.

After independent ChatGPT audit, the task remains open until explicit **OWNER VISUAL PASS** on the live Premium review harness.
