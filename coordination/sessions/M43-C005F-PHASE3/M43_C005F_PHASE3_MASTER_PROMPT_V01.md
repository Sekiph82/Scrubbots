# M43-C005F-PHASE3 — Meta Rewards + Acquisition Feel — MASTER CLAUDE PROMPT V01

Repository: `Sekiph82/Scrubbots`
Persistent owner checkout: `C:\Users\sekip\Desktop\ScrubBots`
Engine: Godot 4.7.2
Date: 2026-10-09

## Authorized scope

Execute these three already-planned children as one continuous milestone:

1. `SB-M43-C005F-006` — Collection set/master-completion celebration tiers
2. `SB-M43-C005F-008` — Gift Meter / Gift claim / Daily / Tasks / earned ScrubBox feel
3. `SB-M43-C005F-009` — Important acquisition confirmations and selective action feel

Do NOT execute F007, F010, F011, F012 or F015 in this milestone.

This is an owner-authorized parallel lane while Level Factory/Codex works independently. Remote Level Update / Family APK remains the primary critical path.

Root `TASKS.md` is READ-ONLY for Claude. ChatGPT is its sole writer.

---

# GATE 0 — OWNER DESKTOP SYNC IS MANDATORY

This gate is non-negotiable.

Before reading implementation scope or changing product code:

1. Work from the persistent owner checkout:
   `C:\Users\sekip\Desktop\ScrubBots`
2. Record local HEAD, `origin/main`, ahead/behind, dirty tracked files, untracked files, worktrees and stashes.
3. Run `git fetch --prune origin`.
4. Non-destructively reconcile the persistent Desktop checkout so its tracked current-main code is at exact latest `origin/main`.
5. Preserve all owner-local work, including:
   - `project.godot` owner-local integrations;
   - owner-review `.tscn` edits;
   - `.mcp.json`;
   - `addons/godot_ai`;
   - local art/import/uid files;
   - existing stashes/worktrees.
6. Never use `git reset --hard`, `git clean`, force checkout, destructive rebase, force push or silent discard.
7. **Implementation must not begin until persistent Desktop HEAD == current origin/main and ahead/behind is 0/0.**
8. If safe reconciliation cannot be completed, STOP:
   `BLOCKED_OWNER_DESKTOP_SYNC`
9. A TEMP worktree may be used later for isolated test/build work, but it does NOT replace this Desktop sync gate.
10. After implementation is pushed, sync the persistent Desktop checkout again to final `origin/main` while preserving owner-local work, so the owner's F5 launches the implemented code. Final handoff requires Desktop tracked HEAD == origin/main and 0/0.

Do not repeat the earlier failure mode where GitHub advances but the owner Desktop stays on an old commit.

---

# READ FIRST

- root `TASKS.md`
- `scripts/ui/feel/feedback_adapter.gd`
- `scripts/app/main.gd`
- `scripts/ui/ceremony/ceremony_presenter.gd`
- `scripts/ui/ceremony/meta_ceremonies.gd`
- `scripts/ui/feel/meta_feedback.gd`
- `scripts/ui/popup/acquisition_flow.gd`
- `scripts/ui/daily/daily_screens.gd`
- `scripts/economy/production_action_facade.gd`
- Phase 1 audit:
  `coordination/sessions/M43-C005F-PHASE1/CHATGPT_INDEPENDENT_AUDIT_V01.md`
- Phase 2 final pack audit:
  `coordination/sessions/M43-C005F-PHASE2-R02/CHATGPT_INDEPENDENT_REAUDIT_V01.md`
- Phase 2 owner closure:
  `coordination/sessions/M43-C005F-PHASE2/OWNER_PACK_RUNTIME_ACCEPTANCE_V01.md`

Inspect the ACTUAL current APIs before coding.

---

# FOUNDATION CONTRACT — DO NOT BREAK

The canonical visual feedback gateway is:

`scripts/ui/feel/feedback_adapter.gd`

No production caller may access GameFeelFlow or Saltmire Spark directly.

Actual installed contract:

- GameFeelFlow 1.0.0
- Saltmire Spark 1.0.0
- GFF production allow-list: `punch_scale`
- Spark production allow-list: `spark`, `pickup`, `confetti`
- GFF scale targeting works only on Node2D/Node3D, NOT ordinary Control UI
- do not invent Node2D wrappers or reparent UI just to force GFF to work
- Control-based UI may use native Godot tween/scale presentation plus Spark THROUGH FeedbackAdapter
- Reduced Effects means zero plugin work
- no flash
- no camera shake
- no freeze frame
- no time scale
- no physics/collider authority
- no global `Spark.clear()`
- no plugin callback may grant/save/navigate/decide success

Native Godot presentation remains primary when that is the safe tool.

Do not change the Phase 2 Results or Standard/Premium Pack look except unavoidable compile-safe plumbing. They are owner-accepted.

---

# CHILD 1 — SB-M43-C005F-006
## Collection set/master-completion celebration tiers

Use the EXISTING shipping authority:

- `CeremonyPresenter`
- `MetaCeremonies.set_complete()`
- `MetaCeremonies.master_complete()`
- canonical committed `CeremonyEvents`
- current `MetaUiState` once-only presentation truth

Do not create a second completion ceremony or reward path.

### Required hierarchy

Set completion:
- target intensity: `REWARD`
- restrained Spark accent through FeedbackAdapter
- optional short native Control scale settle on the existing hero/emblem
- never visually compete with Master completion

Master Collection:
- target intensity: `MAJOR_REWARD`
- visibly stronger but capped Spark confetti through FeedbackAdapter
- optional stronger short native Control settle
- still below WIN / MAJOR_UNLOCK budgets

Use the authoritative ceremony event key to build one-shot feel keys.

Required one-shot shape:
`c005f006:<ceremony_event_key>`

Repeated:
- `pending()`
- `drain()`
- popup refresh
- resize
- close/reopen
- route refresh

must never create a second celebration for the same already-presented event.

Reduced:
- same art/text/reward rows
- no plugin particles
- no decorative bounce/spin added by this task
- final state immediately readable

Do NOT change:
- set 9/9 truth
- Master 15-set truth
- set rewards
- Master +2500 SB/+20 Bot Parts
- Collection reward grants
- acknowledgement/save authority

---

# CHILD 2 — SB-M43-C005F-008
## Gift Meter / Gift claim / Daily / Tasks / earned ScrubBox feel

Use only existing committed production seams.

### Gift Meter milestone ceremony

Existing `gift_milestone` ceremony:
- normal milestone = `REWARD`
- cycle-max / 1000 milestone may use `MAJOR_REWARD`
- one-shot key derives from canonical ceremony event key
- do not grant/claim anything from feel code

### Gift claim

A Gift claim effect may occur ONLY after:
`ProductionActionFacade.action_committed("claim_gift", result)`

Never on button press before commit.

Use a stable presentation key tied to the canonical occurrence/transaction identity. If current result does not expose the already-known occurrence id, it is acceptable to enrich the facade result with presentation-only identity copied from the input/canonical transaction. Do not alter grant semantics.

Ordinary Gift claim:
- restrained `REWARD` / pickup accent
- do not stack a second major burst if a pack ceremony immediately follows
- do not change PackPresenter ordering

### Daily login

Effect only after committed:
`claim_daily_login`

Use the already-authoritative local-day/cycle identity for the one-shot key.

Keep:
- local calendar rules
- streak
- D1-D5 values
- pack queue behavior
- save/idempotency

unchanged.

### Individual Tasks

Effect only after committed:
`claim_daily_task`

Keep this deliberately small:
- `SMALL` or low `REWARD`
- no confetti for every task
- no Home refresh spam

### Earned ScrubBox

Existing shipping ScrubBox:
`DailyScreens.open_scrubbox()`

It opens only after successful `claim_daily_all_tasks`.

Give this one clear `MAJOR_REWARD` moment:
- target the existing ScrubBox hero/reward presentation
- capped confetti/pickup through FeedbackAdapter
- native short Control settle allowed
- key tied to canonical local-day all-tasks transaction

Do not mint a second ScrubBox.
Do not alter the one Random Booster Charge reward.
Do not make ScrubBox purchasable.

### Critical no-spam rule

These must produce ZERO new feel work:
- ordinary Home refresh
- reopening Daily/Gift/Tasks after an already committed presentation
- viewport resize
- opening/closing unrelated popup
- a refused duplicate claim
- clock rollback refusal
- pack replay
- owner navigating back

---

# CHILD 3 — SB-M43-C005F-009
## Important acquisition confirmations

Scope this child to the EXISTING acquisition surfaces and committed outcomes. Do not duplicate F003/F005/F007.

Primary surfaces:
- Life / Heart acquisition
- Booster acquisition/use
- rewarded acquisition success
- Need-a-Hand booster BUY / WATCH AD success when the charge is actually committed

Use:
- `AcquisitionFlow`
- `ProductionActionFacade`
- `RewardedGrantService`
- BasePopup pending-token/result seams

### Success-only rule

Decorative success feedback happens ONLY after the authority confirms success.

Examples:
- Heart +1 purchase committed
- full refill committed
- booster charge purchase committed
- verified rewarded grant committed
- legal booster execution committed

No reward/pickup effect for:
- insufficient SB
- illegal booster state
- cancel/back
- provider fail
- provider timeout
- skipped/unverified rewarded ad
- duplicate callback
- duplicate token
- already claimed
- stale popup

### Button rule

Do NOT use GameFeelFlow `ui_button_press` or `ui_notification` combos. They are outside the V1 allow-list.

Keep native button pressed/hover states.

Post-commit:
- use `SMALL` / `REWARD` FeedbackAdapter intent on a meaningful existing target
- native short Control settle allowed
- Spark pickup only after real success

Do not turn every navigation button into an effect source.

### Idempotency

Rewarded success keys must derive from the canonical rewarded token/transaction identity.

Purchase/use feedback must use an authoritative committed action identity where available; enrich result metadata with presentation-only canonical identity if required.

Duplicate callbacks/rapid taps must never create duplicate visual success, and of course never duplicate the grant.

---

# IMPLEMENTATION SHAPE

Prefer one compact presentation-only coordinator under:
`scripts/ui/feel/`

Example responsibility:
- observe `CeremonyPresenter.ceremony_shown`
- observe `ProductionActionFacade.action_committed`
- bind to the current ModalStack/AcquisitionFlow only for presentation targeting
- call the existing `FeedbackAdapter`
- own no durable state

Do not create a second event bus, task tracker, reward service, modal stack or save section.

If a direct small binding into CeremonyPresenter / AcquisitionFlow is cleaner, that is acceptable, but plugin access still stays exclusively through FeedbackAdapter.

---

# REMOTE CONTENT / R2 HARD EXCLUSION

This milestone must not change Remote Level Update behavior.

Do not modify:
- RemoteContentManager
- remote manifest parsing
- remote pack install/cache/LKG
- `data/config/remote_content_runtime_v1.json`
- R2 URLs
- content schemas
- LevelData
- supply
- VOID
- Family APK/export
- Level Factory repository

No Remote Content tests should need semantic updates.

---

# REQUIRED PERMANENT TESTS

Add a focused Phase 3 suite.

Suggested path:
`tests/m43_c005f_phase3_meta_rewards_acquisition.gd`

At minimum prove:

## F006
- set completion triggers exactly one REWARD request
- Master triggers exactly one MAJOR_REWARD request
- same ceremony event key never fires twice
- Reduced consumes presentation key but performs zero plugin work
- grants/rewards/economy snapshots unchanged by feel

## F008
- Gift milestone fires only from committed/shown canonical event
- Gift claim fires only after action_committed
- Daily login fires only after committed claim
- individual Task claim stays low intensity
- ScrubBox fires once after successful all-three claim
- duplicate/refused claims produce zero success feel
- Home refresh/reopen/resize produces zero replay
- pack reward flow remains correct and serial

## F009
- Heart purchase success => one confirmation
- Heart failure => zero reward feel
- booster charge success => one confirmation
- illegal/insufficient booster => zero success feel
- verified rewarded success => one
- duplicate rewarded callback/token => no duplicate feel/grant
- timeout/cancel/fail => zero success feel
- plugin missing/throwing => authority result unchanged

## Boundary
- static scan: no new direct GameFeelFlow/Spark production calls outside FeedbackAdapter
- no new persistent feel state
- no reward/save/navigation call from feel coordinator
- Reduced = zero plugin work

---

# REQUIRED REGRESSION

Run and record:

- Phase 1 foundation suite
- Phase 2 Results + Pack feel suites
- earned-pack R01/R02 suite
- M39 economy/reward suites relevant to Gift/Daily/Collection
- M41 Settings / Reduced Effects
- M43 Collection / ceremony suites
- M43 C003 acquisition suites
- M43 C009/R09 Daily/Tasks/Gift suites
- M43 C014 meta sound/haptic suite
- Rewarded Ads R15 functional suite
- root `tests/run_tests.gd`
- headless project import/boot
- `git diff --check`

Any changed legacy expectation must be explained and must reflect presentation-only behavior, never relaxed authority.

---

# RUNTIME EVIDENCE

Capture real shipping surfaces, not a fabricated preview-only UI:

FULL + REDUCED where applicable:
1. Set Complete
2. Master Collection
3. Gift milestone
4. earned ScrubBox
5. one successful Heart or Booster acquisition
6. one acquisition failure/no-success-feedback case

Use at least:
- 1080×2160
- 1536×2048

Keep captures under:
`coordination/sessions/M43-C005F-PHASE3/evidence/`

Owner visual acceptance is NOT assumed from screenshots. ChatGPT audits first; owner reviews after technical PASS.

---

# SOURCE CONTROL / PUBLICATION

Claude must not edit root `TASKS.md`.

Builder log:
`coordination/sessions/M43-C005F-PHASE3/M43_C005F_PHASE3_CLAUDE_LOG_V01.md`

Implementation and log must be pushed normally to `main`.

Before final response:
1. fetch/prune origin;
2. verify implementation `HEAD == origin/main`;
3. persistent Desktop checkout must also be reconciled to the same final origin/main while preserving owner-local files;
4. report Desktop HEAD, origin/main, ahead/behind and retained owner-local changes.

If GitHub is current but owner Desktop is left behind, the milestone is NOT complete.

Final state:
`AWAITING_GPT_M43_C005F_PHASE3_STRICT_AUDIT_AND_OWNER_VISUAL_REVIEW`
