# M28-C002-C003 — CHATGPT INDEPENDENT AUDIT V01

Date: 2026-09-29
Auditor: ChatGPT
Repository: `Sekiph82/Scrubbots`
Audited implementation: `7a6a56a2fdba8bd29c76ba72a303511e4398489c`
Criteria: `coordination/sessions/M28-C002-C003/CHATGPT_AUDIT_CRITERIA_V01.md`

## Verdict

**AUDITED_PASS / OWNER FINAL GAMEPLAY V02 PLAYTEST REQUIRED**

SB-M28-C002-012, SB-M28-C002-013 and SB-M28-C002-019 are technically accepted.

SB-M28-C002-020 remains open for final owner visual / hands-on playtest acceptance.

## 1. Governance / scope

PASS.

Verified against the handed-off base `c931f63464bf1d2f99770a83732428e90af9c9fd`:

- audited commit is exactly one commit ahead;
- root `TASKS.md` was not changed by Claude;
- shipping behavior was not changed;
- the only production edit is documentation drift correction in `ProductionGameplayHost.request_booster()`;
- no Gameplay V02 redesign;
- no M43 popup visual/UX drift;
- no booster/2x/Heart price or rule drift;
- no solver/routing behavior change;
- no unrelated meta implementation.

## 2. SB-M28-C002-012 — Booster Acquire routing

PASS.

The new focused suite drives the **visible Gameplay V02 booster buttons** through routed mouse/touch input using `SubViewport.push_input`.

Verified proof includes:

- exactly four canonical visible boosters;
- zero-charge +1 Slot tap opens `booster_plus_one_slot` on the shared app ModalStack;
- the open action itself changes no economy/gameplay truth and spends no SB;
- Selector/Tornado visible taps open the matching popup with the owner-approved picker;
- picker keys are constrained to the adapter legality proof;
- cancel/X/Back/Escape with no commit leaves state unchanged;
- owned-charge flow remains charge-first;
- +1 Slot and Tornado SB commits still route through canonical production authority;
- popup-open supply, board, booster, 2x and Pause interactions are blocked;
- no click-through after close.

This closes SB-M28-C002-012 technically.

## 3. SB-M28-C002-013 — 2x Acquire routing

PASS.

The visible 2x Gameplay V02 control is tested directly.

Verified:

- unentitled 1x tap opens canonical `speed_acquire`;
- opening does not grant free 2x;
- opening does not debit SB;
- exact products remain current level 200 / 15m 300 / 30m 500 / 60m 750 SB;
- canonical purchase debits once and enables 2x;
- entitled 1x/2x switching adds no charge;
- timed countdown redraws from authoritative service truth;
- M55 rollback high-water remains effective;
- free M23 auto-2x remains entitlement/acquisition independent.

This closes SB-M28-C002-013 technically.

## 4. Popup/input integration

PASS.

Focused proof covers:

- only top modal receiving actions;
- gameplay input gate + runtime hold while popup is open;
- Pause using the same ModalStack;
- no click-through after close;
- temporary sixth-slot capacity, slot truth and view rects unchanged under popup;
- geometry unchanged through popup cycles;
- 40 repeated routed open/close cycles with stable node/timer/signal counts.

No modal/input blocker found.

## 5. SB-M28-C002-019 — fresh evidence

PASS.

Repository contains the required fresh real-runtime evidence pack, including:

- fresh level;
- active cleaning;
- five occupied slots;
- sixth slot;
- Booster Acquire;
- Selector/Tornado picker;
- Pause;
- 2x Acquire;
- timed 2x;
- short phone;
- tall phone;
- tablet;
- popup-inclusive responsive matrix examples.

The commit also contains:

- `motion_gameplay_v02_popup_flow_720x1440.mp4`;
- `motion_contact_sheet_1fps.png`;
- `motion_timeline.txt`.

The MP4 is present in GitHub as a real binary asset (6,689,098 bytes). The contact sheet and all required screenshots are also present as repository binary assets.

The submitted capture tooling uses Godot Movie Maker; ffmpeg is described only as a local transcode/contact-sheet helper, not a shipping dependency.

This closes SB-M28-C002-019.

## 6. Responsive / touch

PASS technically.

The focused matrix covers:

- 1080×2160;
- 1170×2532;
- 1290×2796;
- 1080×2400;
- 1440×3200;
- 1080×1920;
- 1536×2048.

It checks base gameplay plus Booster Acquire, Selector picker, Pause, 2x Acquire and sixth-slot popup composition, including text fit, viewport containment and >=88 px touch targets.

## 7. Regression evidence

PASS with one non-blocking pre-existing test-determinism note.

Submitted results:

- new M28 final gate focused suite: 22/22 PASS;
- root suite: 5323/5323 PASS;
- requested M28/M29/M30/M39/M40/M43-C002/M43-C003/M52/M55 relevant suites pass;
- `git diff --check` clean;
- historical M21 C/043, C/047 and B findings remain identical to the accepted baseline.

### NB-001 — m39_v04_integration clock-boundary flake

One standalone `m39_v04_integration` run can fail its exact full-economy snapshot equality across a one-second real-clock boundary.

Independent code inspection confirms the claimed mechanism:

- `HeartService` defaults to `Time.get_unix_time_from_system()`;
- when Hearts are full, `_accrue()` sets the anchor to the current clock;
- `HeartService.snapshot()` calls `_accrue()`;
- `SpeedEntitlementService.snapshot()` calls `_effective_now()`, which advances persisted `clock_high_water` from the real clock;
- `m39_v04_integration` compares complete `econ.snapshot()` dictionaries before and after a forced rollback using strict equality.

Therefore crossing a one-second boundary can change only clock-derived fields while wallet/charge rollback remains correct.

This cycle does not change economy code or the M39 test. The failure is treated as a **non-blocking pre-existing test-determinism defect**, not an M28 production regression.

Recommended later follow-up: make the M39 V04 rollback comparison use an injected deterministic clock or compare the intended mutation domains instead of real-time snapshot fields.

## 8. Documentation / owner gate

PASS.

Required files exist:

- `GAMEPLAY_V02_FINAL_MATRIX_V01.md`;
- `OWNER_GAMEPLAY_V02_FINAL_REVIEW_V01.md`;
- `CLAUDE_LOG_V01.md`;
- fresh evidence directory.

The owner review checklist correctly leaves every owner item unapproved.

## 9. Closure mapping

Technically accepted now:

- SB-M28-C002-012;
- SB-M28-C002-013;
- SB-M28-C002-019.

Still open:

- SB-M28-C002-020 — final owner visual / hands-on playtest acceptance.

## Final

**AUDITED_PASS / OWNER FINAL GAMEPLAY V02 PLAYTEST REQUIRED**
