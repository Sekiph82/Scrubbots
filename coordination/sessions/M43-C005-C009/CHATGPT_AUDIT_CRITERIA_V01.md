# M43-C005-C009 — CHATGPT AUDIT CRITERIA V01

Canonical task: **SB-M43-067**  
Target: first-new-card celebration + clear duplicate-count presentation.

## Governance

- [ ] Desktop synced non-destructively before implementation.
- [ ] owner-local files preserved.
- [ ] root TASKS.md untouched by Claude.
- [ ] SB-M43-068 not started.
- [ ] no parallel tracker.

## Truth source

- [ ] presentation uses committed `is_new`.
- [ ] presentation uses committed `copies_after`.
- [ ] no live Collection query recomputes NEW/DUPLICATE.
- [ ] `extra_copies = copies_after - 1`.
- [ ] repeated rows preserve sequential receipt truth.

## NEW presentation

- [ ] NEW state remains explicit in text.
- [ ] FIRST COPY is explicit.
- [ ] canonical `card_new_glow.png` used if suitable.
- [ ] no replacement/new glow art without owner approval.
- [ ] FULL gets one restrained celebration.
- [ ] celebration settles before routing gate.
- [ ] no loops/spin/strobe/camera shake/confetti storm.
- [ ] multiple NEW Premium cards remain readable.
- [ ] celebration fires at most once per CardView instance.
- [ ] relayout/resize does not retrigger.

## Reduced Effects

- [ ] NEW truth retained.
- [ ] FIRST COPY retained.
- [ ] no bounce/pulse/flash.
- [ ] static/subtle glow allowed.
- [ ] duplicate counts unchanged.
- [ ] two-tap ceremony semantics unchanged.

## Duplicate presentation

- [ ] DUPLICATE state explicit.
- [ ] primary duplicate count = EXTRAS xN.
- [ ] N = copies_after - 1.
- [ ] copies_after 2 => EXTRAS x1.
- [ ] copies_after 3 => EXTRAS x2.
- [ ] NEW never shows EXTRAS x0.
- [ ] optional owned-total text, if present, is secondary and truthful.
- [ ] count readable at all target viewports.

## Layout / accepted surfaces

- [ ] Standard accepted 3-card geometry preserved.
- [ ] Premium accepted 3+2 geometry preserved.
- [ ] card draw order unchanged.
- [ ] destination positions/semantics unchanged.
- [ ] Standard 9 frame bytes unchanged.
- [ ] Premium 9 frame bytes unchanged.
- [ ] canonical 135 card assets unchanged.
- [ ] destination icon assets unchanged.
- [ ] card_new_glow asset bytes unchanged.
- [ ] no overlap/clipping introduced.

## Sequencing

- [ ] Pack IDLE unchanged.
- [ ] Tap 1 unchanged.
- [ ] accepted 01→09 unchanged.
- [ ] cards emerge normally.
- [ ] NEW celebration occurs only after/with settle.
- [ ] readable final hold exists.
- [ ] destinations appear at correct stage.
- [ ] Tap 2 still required.
- [ ] no auto-route.
- [ ] routing destination unchanged.
- [ ] completion unchanged.

## Authority / idempotency

- [ ] no pack draw/open authority added.
- [ ] no Collection mutation.
- [ ] no Cards Exchange mutation.
- [ ] no RNG.
- [ ] no save.
- [ ] no receipt/transaction mutation.
- [ ] reopening same committed model changes no authority.
- [ ] celebration cannot create economic side effects.

## Shared architecture

- [ ] Standard/Premium use one shared card-state presentation path.
- [ ] no duplicated truth logic in Premium.
- [ ] no C008 receipt schema changes.
- [ ] no GameFeelFlow/Saltmire usage in this task.

## Focused tests

- [ ] C009 focused suite PASS.
- [ ] FIRST COPY tests PASS.
- [ ] EXTRAS off-by-one tests PASS.
- [ ] repeated-card sequential count tests PASS.
- [ ] mixed/all-new/all-duplicate Standard PASS.
- [ ] mixed/all-new/duplicate-heavy Premium PASS.
- [ ] relayout no-retrigger PASS.
- [ ] Reduced Effects no-bounce PASS.
- [ ] no-live-Collection-query guard PASS.

## Sensitivity

Detected:
- [ ] extras uses copies_after instead of -1.
- [ ] NEW shows EXTRAS x0.
- [ ] copies_after 2 shown as EXTRAS x2.
- [ ] live Collection recomputation injected.
- [ ] resize retriggers celebration.
- [ ] Reduced Effects animation injected.
- [ ] wrong glow asset.
- [ ] route/destination mutation.
- [ ] pack-frame mutation.

## Runtime evidence

- [ ] Standard NEW celebration capture.
- [ ] Standard FIRST COPY hold.
- [ ] Standard duplicate EXTRAS capture.
- [ ] Standard repeated FIRST COPY / x1 / x2 evidence.
- [ ] Premium mixed 3+2 evidence.
- [ ] Premium duplicate-heavy evidence.
- [ ] Standard Reduced evidence.
- [ ] Premium Reduced evidence.
- [ ] 1080×1920 clean.
- [ ] 1080×2160 clean.
- [ ] 1170×2532 clean.
- [ ] 1290×2796 clean.
- [ ] 1536×2048 clean.

## Owner review harness

- [ ] Standard F6 harness uses current shipping code.
- [ ] Premium F6 harness uses current shipping code.
- [ ] mixed/all-new/duplicate-heavy fixtures available.
- [ ] R replay works.
- [ ] E Reduced Effects works.
- [ ] instructions explain what owner must judge.

## Regression

- [ ] C006 Standard suite PASS.
- [ ] C007 Premium suite PASS.
- [ ] both harness smokes PASS.
- [ ] C008 transaction suite PASS.
- [ ] M39 Collection/CardPack/Exchange PASS.
- [ ] M54 exactly-once PASS.
- [ ] relevant M43 popup/sequencer PASS.
- [ ] root suite PASS.
- [ ] git diff --check clean.
- [ ] no unexplained runtime errors.

## Handoff

- [ ] CARD_STATE_PRESENTATION_MATRIX_V01.md exists.
- [ ] OWNER_REVIEW_INSTRUCTIONS_V01.md exists.
- [ ] CLAUDE_LOG_V01.md exists.
- [ ] final SHA reported.
- [ ] evidence URLs reported.
- [ ] handoff ends `AWAITING_GPT_M43_C005_C009_V01_CARD_STATE_AUDIT`.

## Closure

Technical PASS does not close SB-M43-067.

Because this task intentionally changes visible card presentation, **explicit OWNER VISUAL PASS is required** after the independent audit.
