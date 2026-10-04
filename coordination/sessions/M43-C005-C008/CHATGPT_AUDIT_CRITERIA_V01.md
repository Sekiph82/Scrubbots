# M43-C005-C008 — CHATGPT AUDIT CRITERIA V01

Canonical task: **SB-M43-066**  
Target: atomic/durable pack commit before presentation; reveal reopen never duplicates cards.

## Governance

- [ ] Desktop synced non-destructively before implementation.
- [ ] owner-local project.godot/main.tscn/addons/untracked work preserved.
- [ ] root TASKS.md untouched by Claude.
- [ ] SB-M43-067 not started.
- [ ] no parallel status tracker.

## Accepted visual preservation

- [ ] Standard 9 shipping frame bytes unchanged.
- [ ] Premium 9 shipping frame bytes unchanged.
- [ ] Standard live ceremony behavior unchanged.
- [ ] Premium live ceremony behavior unchanged.
- [ ] Standard focused + harness tests PASS.
- [ ] Premium focused + harness tests PASS.
- [ ] no new visual owner gate required because no visible behavior changed.

## Canonical transaction authority

- [ ] one canonical production pack commit authority exists.
- [ ] stable caller-supplied tx id required.
- [ ] Standard and Premium supported.
- [ ] empty/invalid tx fails closed.
- [ ] same tx same kind resolves same committed receipt.
- [ ] same tx different kind fails closed.
- [ ] reentrant same-tx call cannot draw twice.
- [ ] no UI/popup owns grant authority.

## Receipt truth

- [ ] schema/version present.
- [ ] tx id present.
- [ ] stable presentation id present.
- [ ] kind present.
- [ ] Standard exactly 3 rows.
- [ ] Premium exactly 5 rows.
- [ ] service draw order preserved.
- [ ] canonical card id/art/name/rarity.
- [ ] strict NEW/DUPLICATE.
- [ ] truthful copies_after.
- [ ] repeated same-card rows increment sequentially.
- [ ] Premium card0 Rare-or-better.
- [ ] receipt maps directly to existing Standard/Premium validators.
- [ ] receipt/model is data-only and cannot grant by itself.

## Commit-before-presentation gate

- [ ] new tx draws/applies before presentation is released.
- [ ] durable save succeeds before presentation model is returned.
- [ ] failed save returns no usable presentation.
- [ ] presentation creation never calls CardPackService.
- [ ] ceremony reopen never calls CardPackService.
- [ ] ceremony reopen never mutates Collection/rewards/RNG/save.
- [ ] multiple ceremony recreations from same receipt remain presentation-only.

## Atomic rollback

- [ ] pre-transaction full authority snapshot captured.
- [ ] after-draw fault fully rolls back.
- [ ] after-ledger fault fully rolls back.
- [ ] save failure fully rolls back.
- [ ] Collection restored exactly.
- [ ] wallet/reward state restored exactly.
- [ ] RewardGrant applied ids restored exactly.
- [ ] set/master side effects restored exactly.
- [ ] RNG restored exactly.
- [ ] transaction ledger restored exactly.
- [ ] no partial receipt survives.
- [ ] no successful commit marker survives failed transaction.

## RNG

- [ ] failed commit restores exact pre-RNG state.
- [ ] duplicate tx does not advance RNG.
- [ ] presentation/reopen does not advance RNG.
- [ ] successful continuation is canonical/persisted as designed.
- [ ] production uses no fixed test seed.
- [ ] malformed persisted RNG state fails closed if persisted.

## Durability / save

- [ ] transaction/receipt state lives in canonical save graph.
- [ ] no second save file/cache authority.
- [ ] successful commit survives AppState/SaveService reload.
- [ ] exact same receipt available after reload.
- [ ] same tx after reload does not duplicate cards.
- [ ] old save lacking C008 state still loads with empty/default ledger.
- [ ] malformed C008 state rejects.
- [ ] malformed import is all-or-nothing.
- [ ] failed import preserves previous live valid state.
- [ ] SaveService future-schema behavior not weakened.

## Duplicate / reopen matrix

- [ ] duplicate tx before presentation = no duplicate.
- [ ] duplicate tx while presentation open = no duplicate.
- [ ] duplicate tx after presentation close = no duplicate.
- [ ] duplicate tx after reload = no duplicate.
- [ ] Standard ceremony can open/close/reopen same receipt with no mutation.
- [ ] Premium ceremony can open/close/reopen same receipt with no mutation.
- [ ] same committed receipt content/order returned every time.

## Set / Master side effects

- [ ] successful pack that completes set applies real set reward once.
- [ ] duplicate tx/reopen does not reapply set reward.
- [ ] forced failed commit rolls set reward back.
- [ ] if master edge is exercised, master applies once on success.
- [ ] master side effect rolls back on failure if triggered.
- [ ] M54 exactly-once suite remains PASS.

## Existing pack call graph

- [ ] current standard_card_packs handler behavior audited/documented.
- [ ] current premium_card_packs handler behavior audited/documented.
- [ ] M39 reward semantics not casually changed.
- [ ] SB-M43-098 pack inventory/open-entry work not pulled forward.
- [ ] future presentation callers have one documented C008 canonical API.
- [ ] raw open_standard/open_premium are not used by the new presentation bridge.

## Receipt/import hardening

- [ ] wrong root type rejected.
- [ ] empty/non-string tx rejected.
- [ ] duplicate/colliding tx representation rejected where applicable.
- [ ] unknown kind rejected.
- [ ] wrong 3/5 count rejected.
- [ ] unknown card id rejected.
- [ ] art/name/rarity mismatch rejected.
- [ ] Premium COMMON card0 rejected.
- [ ] invalid NEW/DUPLICATE rejected.
- [ ] invalid copies_after rejected.
- [ ] incoherent repeated-card count rejected.
- [ ] tx/presentation mismatch rejected if schema derives one from the other.
- [ ] malformed committed receipt rejected.
- [ ] no partial import.

## Fault/sensitivity

- [ ] duplicate-apply mutation detected.
- [ ] presentation-before-save mutation detected.
- [ ] RNG-no-rollback mutation detected.
- [ ] dropped-receipt-on-reload mutation detected.
- [ ] changed card order detected.
- [ ] fabricated copies_after detected.
- [ ] Premium COMMON card0 detected.
- [ ] partial ledger import detected.
- [ ] ceremony raw-open call detected.

## Automated validation

- [ ] C008 focused suite PASS.
- [ ] C006 Standard focused suite PASS.
- [ ] C007 Premium focused suite PASS.
- [ ] Standard harness smoke PASS.
- [ ] Premium harness smoke PASS.
- [ ] M39 CardPack/Collection regressions PASS.
- [ ] M40 save/load regressions PASS.
- [ ] M54 exactly-once PASS.
- [ ] RewardGrant / transaction regressions PASS.
- [ ] relevant M43 ceremony/modal regressions PASS.
- [ ] root suite PASS.
- [ ] git diff --check clean.
- [ ] no unexplained runtime/script errors.

## Evidence / handoff

- [ ] PACK_COMMIT_TRANSACTION_MATRIX_V01.md exists.
- [ ] machine-readable receipt/schema artifact exists.
- [ ] CLAUDE_LOG_V01.md exists.
- [ ] final SHA reported.
- [ ] production file list reported.
- [ ] canonical API reported.
- [ ] rollback/RNG proof reported.
- [ ] reload/reopen proof reported.
- [ ] set/master proof reported.
- [ ] handoff ends AWAITING_GPT_M43_C005_C008_V01_PACK_COMMIT_AUDIT.

## Closure rule

If every criterion passes and accepted Standard/Premium visuals are byte/behavior unchanged, **SB-M43-066 may close on independent ChatGPT technical audit without another owner visual gate.**
