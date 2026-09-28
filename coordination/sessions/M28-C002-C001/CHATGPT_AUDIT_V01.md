# M28-C002-C001 — CHATGPT INDEPENDENT AUDIT V01

Date: 2026-09-28
Auditor: ChatGPT controller
Repository: `Sekiph82/Scrubbots`
Audited HEAD: `202e06cfbfdcb558e4e430afa77af77aa645b6b2`
Prompt: `coordination/sessions/M28-C002-C001/task_prompts/SB-M28-C002-C001_GAMEPLAY_V02_CORE.md`
Criteria: `coordination/sessions/M28-C002-C001/audit_criteria/SB-M28-C002-C001_GAMEPLAY_V02_CORE.md`

Builder evidence:
- `coordination/sessions/M28-C002-C001/CLAUDE_LOG_V01.md`
- `coordination/sessions/M28-C002-C001/GAMEPLAY_V02_CORE_MATRIX_V01.md`
- `coordination/sessions/M28-C002-C001/OWNER_GAMEPLAY_V02_REVIEW_V01.md`
- `coordination/sessions/M28-C002-C001/evidence/**`

## Verdict

**AUDITED_PASS / M28-C002-C001 / GAMEPLAY V02 CORE / OWNER VISUAL REVIEW REQUIRED**

The owner-approved Gameplay V02 composition is now implemented on the real production gameplay surface and passes the core engineering gate.

This does **not** close the full M28-C002 convergence. Visual owner decisions remain open, and popup/modal-dependent rows 012-015, 018(part), 019 and 020 remain intentionally open.

## 1. Production-path implementation

PASS.

The change modifies the real `GameplayScreen` instantiated by `ProductionGameplayHost`; no detached mockup or flattened master screenshot is used as shipping UI.

The canonical master remains reference-only.

Production screen now includes:
- top-left profile chip;
- Pause + 2x top-right;
- dominant real BoardRenderer;
- full Railroad V1 presentation;
- permanent slot connectors;
- slots immediately below board;
- Batch Supply below slots;
- Scrubby / decoration;
- exactly four boosters.

Obsolete bottom Pause/ad/speed composition is removed.

No gameplay Settings, Heart HUD, Goal/Moves/Time or level-lock rail is introduced.

## 2. Board / Railroad V1

PASS.

Independent source inspection confirms:
- BoardRenderer remains the board presentation authority;
- board aspect is fit from logical W/H and not flattened/stretched;
- Railroad V1 centrelines still come from canonical `ScrubRailGeometry`;
- no routing/target/reservation truth was changed;
- production skin uses approved committed rail assets with procedural fallback only for presentation resilience.

The screen remains presentation-only.

## 3. Slot connectors

PASS.

This is a strong part of the implementation.

Connector start and entry are derived from:
- `SlotOriginProvider.origin_for_slot(i)`, the same real slot origin used by runtime movement;
- `ScrubRailGeometry.bottom_entry(origin.x)`, the canonical bottom-rail mapping.

Five baseline connectors are visible even when slots are empty.

The sixth connector appears only when authoritative +1 Slot capacity produces a sixth slot, and Retry reverts the presentation to five.

Focused sensitivity proves connector-origin drift is detected.

## 4. Batch Supply

PASS for core V02.

The production view supports 3/4/5 columns and three visible rows.

Front row remains the interactive supply truth.
Preview rows remain non-interactive and visually dimmed.

Color/count remain live Godot values.

No supply-plan or click-solution authority changed.

## 5. Pause / 2x

PASS for the current dependency boundary.

Pause:
- moved to top-right;
- preserves existing runtime pause toggle;
- final canonical Pause popup is correctly left to M43-C002.

2x:
- top-right beside Pause;
- inactive, current-level, timed-countdown and free-auto presentation states exist;
- timed countdown reads `SpeedEntitlementService.timed_seconds_remaining()`;
- host refresh timer only triggers redraw and does not become time authority;
- anti-rollback high-water behavior remains in the existing entitlement service;
- free auto-2x remains entitlement/payment independent.

Final canonical 2x Acquire visual remains intentionally deferred to M43-C003.

## 6. Boosters

PASS for rows 010/011 and request-seam readiness.

Exactly four boosters:
- +1 Slot;
- Random;
- Selector;
- Tornado.

Presentation is bound from canonical inventory/config/action services and shows live charge/price/state information.

No-charge tap does not silently debit SB; it emits the acquisition-request seam.

Selector/Tornado do not fake target execution without target UI.

Canonical final BoosterAcquire popup routing remains correctly open under row 012.

## 7. Responsive / safe-area / input

PASS for the core surface.

Evidence/tests cover:
- 1080x2160;
- 1170x2532;
- 1290x2796;
- 1080x2400;
- 1440x3200;
- 1080x1920;
- 1536x2048 tablet;
- notch and gesture-bar synthetic insets.

Focused assertions preserve:
- board aspect;
- board dominance;
- safe-area containment;
- touch target minimums;
- supply-front tappability;
- slot readability;
- board coordinate round-trip.

Final popup-open input suppression remains a dependency item and therefore SB-M28-C002-018 is not marked fully complete yet.

## 8. Approved assets / visual fallback

Engineering PASS, owner visual gate OPEN.

The implementation reuses approved committed gameplay assets where they composite safely.

The builder correctly did **not** edit source PNGs with opaque white backgrounds.

Instead:
- profile chrome uses a native panel while keeping the approved Scrubby portrait;
- slots use native presentation;
- current backdrop uses a native midnight-blue gradient because no approved portrait gameplay backdrop exists;
- speech bubble remains hidden because no canonical tutorial copy is authorized.

These are technically safe choices but remain visual owner decisions, so SB-M28-C002-016 remains open pending owner acceptance.

## 9. Evidence integrity

PASS at generation/source level.

The committed snapshot harness:
- launches the real app root;
- uses real production gameplay;
- uses existing owner `intendedColumnClicks`;
- does not solve or invent new sequences;
- creates the requested core states through real services/controls;
- rejects terminal/non-gameplay states.

Eight evidence PNGs are committed.

This controller independently verified file presence/hashes, harness state generation and production bindings. Final aesthetic judgment is intentionally reserved for OWNER visual review.

## 10. Test migrations

PASS.

Historical tests were migrated only where they asserted the superseded bottom-row composition or outdated owner manifest state.

Safety/behavior assertions remain.

The M52 speed behavior test now uses semantic speed state rather than obsolete button text.

C001B manifest test was updated only because OWNER had already promoted `victory_results` to `MASTER_OWNER_APPROVED`.

## 11. Regression / M21 baseline

Accepted with documented historical baseline failures.

Builder ran all 108 suites:
- 105 exit 0;
- M21 V08 and V09 retain the same historical corridor-model failures;
- builder swapped back the pre-C001 changed production files and reproduced the identical failures;
- this cycle changes no routing authority;
- root `tests/run_tests.gd`: **5323 checks, RESULT: ALL PASS**.

Therefore those M21 failures are not classified as regressions introduced by Gameplay V02.

No new production SCRIPT ERROR class is evidenced.

## 12. Task-row result

Technically complete and audited:
- SB-M28-C002-001
- SB-M28-C002-002
- SB-M28-C002-003
- SB-M28-C002-004
- SB-M28-C002-005
- SB-M28-C002-006
- SB-M28-C002-007
- SB-M28-C002-008
- SB-M28-C002-009
- SB-M28-C002-010
- SB-M28-C002-011
- SB-M28-C002-017

Open / dependency or owner-gated:
- SB-M28-C002-012 BoosterAcquire popup
- SB-M28-C002-013 final 2x Acquire popup
- SB-M28-C002-014 canonical Pause popup
- SB-M28-C002-015 modal-stack input suppression
- SB-M28-C002-016 owner visual acceptance of backdrop/profile-slot/decorative treatment
- SB-M28-C002-018 final popup-open input suppression portion
- SB-M28-C002-019 full review pack with popup states
- SB-M28-C002-020 final independent audit + owner playtest acceptance

## Final

`AUDITED_PASS / M28-C002-C001 / GAMEPLAY V02 CORE / OWNER VISUAL REVIEW REQUIRED`
