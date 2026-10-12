# M44 — Tutorial / FTUE / Feature Unlock Pacing — Owner Proposal V01

Date: 2026-10-12 | Prepared by: ChatGPT | **DRAFT — OWNER APPROVAL REQUIRED**
Authority: root `TASKS.md` SB-M44-001..024; `docs/16_FTUE_FEATURE_UNLOCK_AND_RETENTION_SURFACES.md`; `coordination/OWNER_REWARD_CEREMONY_FEATURE_UNLOCK_V01.md`; locked opening cinematic, difficulty rhythm and current first-10 catalog.
**This proposal is NOT a product decision and is NOT Claude implementation authorization.** Owner approves/revises the table and the skip/replay/unlock presentation gates first; then ChatGPT will publish one M44 MASTER implementation prompt and its complete independent audit criteria. All 24 M44 tasks remain OPEN.

## A. Constraints confirmed in current repository
- Built-in production levels currently exactly: 1 Hazard Bot, 2 Apple, 3 Palm Tree, 4 Orange Cat, 5 Party Toucan, 6 Chicken, 7 Pigeon, 8 Butterfly, 9 Frog, 10 Ice Cube. Immutable stable level IDs, catalog ordering and content/supply plans must NOT be edited for tutorial.
- Owner 10-slot difficulty rhythm: EASY, EASY, MEDIUM, EASY, HARD, EASY, EASY, MEDIUM, EASY, VERY_HARD. No major new teaching wall on 5 HARD and 10 VERY_HARD.
- Opening cinematic is MANDATORY on every true cold launch and NOT skippable (M42 owner policy). Skip of **tutorial tips** is separate from cinematic and requires explicit owner approval.
- Home currently has four fixed primary panels SHOP/COLLECTION/TASKS/DAILY and existing BottomNav. Owner-approved Home composition cannot be rearranged. Feature unlocks are **presentation and access pacing**, NEVER retroactive revision of earned rewards/saves.
- Already available tutorial art can be reused: `assets/ui/final/gameplay/tutorial/tutorial_pointer.png`, `tutorial_highlight_ring.png`, `speech_bubble.png`. Existing Home Scrubby hero and M43 feature unlock ceremony are authoritative; do not create a new speculative asset set.
- Historical WAITING/ACTIVE words were removed from slot UI by owner. Teach temporary no-target behavior visually/contextually, **do not bring these labels back**.
- 2x: distinguish player-owned timed/manual entitlement from the existing free, automatic endgame acceleration; do not grant entitlement or change default speed.
- Need a Hand: third failure at same frontier only, canonical 2-card choice; no synthetic losses or auto-used boosters.
- R2 level 11+ is not published/verified; do not presume L11 accessible; no remote content change, APK/IPA build or R2 publication under this design task.

## B. First 10 levels: proposed tutorial sequence
This table means **earliest tutorial opportunity**, NOT a guarantee that the player's real board state/booster/reward eligibility will satisfy the trigger. If not, the tip waits for the first legal context; never force a loss, booster, purchase, or fabricated reward.

| Actual campaign level | Real art & difficulty | ONE primary teaching focus (proposed) | Player-visible presentation |
|---|---|---|---|
| L1 | Hazard Bot, EASY | Tap only a real FRONT supply batch. Observe automatic placement into rightmost empty execution slot and real Scrubbot cleaning. | Single finger pointer/highlight on the actual selectable batch; acknowledge first legal action; brief cleaning follow-up. Do not pause while bots clean. |
| L2 | Apple, EASY | Five slots and automatic FIFO use; preview supply rows are informational and cannot be tapped. | Highlight front vs preview only after the player sees the queue; no detached tutorial wall. |
| L3 | Palm Tree, MEDIUM | Contextual reachability/no-current-target observation, only if an actual legal WAIT occurs. | Subtle outline + short explanation, NO “WAITING”/“ACTIVE” text on slot. If no real event, defer. |
| L4 | Orange Cat, EASY recovery | First fail / Retry / Heart consequence **when a real fail first happens**. Introduce +1 Slot only when booster is present and legal. | No scripted failure, no free charge, no economy changes. At most one tip visible. |
| L5 | Party Toucan, HARD | Apply learned skills, no mandatory new mechanic. Existing third-fail Need a Hand may activate naturally. | No forced booster buy/ad prompt or artificial loss. |
| L6 | Chicken, EASY recovery | Selector booster when actually owned/eligible. First earned Pack → Collection entry when legitimately earned. | No synthetic card grant/opening; use existing real pack/Collection authority. Prefer one event per visit. |
| L7 | Pigeon, EASY | Introduce Daily, then Tasks as already-operational, ordinary-play destinations. | Brief guidance after qualifying result or on Home; cannot suppress earned/claimable state. |
| L8 | Butterfly, MEDIUM | Random booster when legitimately available and safe; observe it affects waiting supply, not an illegal mutation. | Only contextually; no new mechanic overlay while the player handles difficulty unless requested. |
| L9 | Frog, EASY recovery | Tornado booster when legal. Then explain existing 2x control after normal-speed familiarity, in a separate moment. | No auto-spend, forced 2x purchase, extra entitlement or fabricated clean. |
| L10 | Ice Cube, VERY_HARD | Consolidation, first ten-level journey and genuine next-cleanup status. NO new required tutorials. | Reuse existing Results, journey and Next Cleanup teaser. After win, L11 only if verified content exists; otherwise honest coming-soon/unavailable status. |

Rules for all 10: only the real production supply-front, rightmost EMPTY slot, correct robot routing, legally reachable target, real boosters and economic source can mutate game state. Overlays only highlight/temporarily gate unrelated input if proven safe; avoid dismissing important timer/control modal. One teaching item at a time, concise localized copy, Reduced Effects alternative and screen-size-safe coachmarks.

## C. Candidate feature-discovery/unlock pacing table — OWNER MUST APPROVE EXACT NUMBERS
**Conservative proposed policy:** guided discovery and NEW badges are milestone-paced for first-time profiles; **existing functional/claimable features remain accessible** until the owner separately approves hard access locks. Never silently take away pre-existing access or already-earned entitlements.

| Feature group | Proposed first INTRO opportunity | Gate condition / safeguard |
|---|---|---|
| Play and core gameplay | L1 | Immediately after mandatory cinematic. |
| Five slots and preview rule | L1–L2 | Trigger follows actual player action. |
| Hearts / Retry | First real failure, not fixed level | Real economy result only; do not consume extra Heart. |
| Gift Meter / Gift Bar | Earliest after L3 win | Show only real earned progress, not invented grant. |
| Shop | Earliest after L4 or genuine earlier need | Access to existing offers must not be revoked; NO payment required for FTUE. |
| +1 Slot | Earliest L4 | Tip only if owned/legally applicable; no free grant. |
| Collection / Card Packs | Earliest after L6; or first legitimately awarded pack | If first earned pack is earlier, follow real reward immediately. No duplicate drawing/grant. |
| Selector | Earliest L6 | When owned/legal. |
| Daily | Earliest after L7, or when already claimable | Never hide/block an earned Daily claim. |
| Tasks / Daily Scrub Orders | Earliest after L7, staggered from Daily | Only existing operable tasks; do not offer impossible level 11+ progression. |
| Random | Earliest L8 | If owned/legal, cannot mutate level generation. |
| Tornado | Earliest L9 | If owned/legal; no invented target color. |
| 2x speed | Earliest L9 (separate tutorial moment) | Normal speed already understood; distinguish timed paid entitlement vs free endgame auto-2x. |
| Robots | First actual valid robot unlock/equip | Never fake robot parts or unlock; may be after L10. |
| Achievements | After L10 AND destination implemented | Until real destination exists, no fake unlock or dead tab. |
| Events / Weekly Cleaning Event / First-Try | Only after implemented/eligible and separately owner-approved level | Existing M43 feature rules remain binding; not auto-enabled by this proposal. |
| Ranks | **Not unlocked in first ten**; awaiting owner scoring/privacy policy and implementation | NO invented ranks or empty functional claim. |
| Comeback Catch-Up | Established returning player with configured absence, NEVER FTUE | No Day streak change or unearned payout. |

Ceremonies: use the existing M43 Feature Unlock presentation ONCE per `feature_id + feature_version`, no direct grant. `NEW` badge persists until first meaningful visit; badge means **new** not claimable. If service already has an actionable reward, a real claim badge takes precedence over tutorial styling. Unlock metadata data-driven, never inferred from immutable level artwork.

## D. Two M44 owner decisions required before implementation
1. **Teaching controls (proposal):** FTUE tips may be individually skipped (small “Skip tips” action) and later reviewed in a **read-only Tips/How to Play** screen without replaying/rewinding a real campaign level. Mandatory M42 opening cinematic remains NON-skippable. Interruption/resume/restart must not replay completed coachmarks.
2. **Unlock enforcement (proposal):** **soft paced discovery**, not blocking already-operational Home shortcuts, rewarded entitlements or purchases. Keep four owner-approved Home panels. For unimplemented destinations (Ranks/Events/Achievements submodules) do not claim a functional feature is unlocked. No hard gating without a separate explicit owner policy.

Owner may accept this full proposal or revise any table cells. Until owner response, **DESIGN_PENDING_OWNER_APPROVAL** and M44 001–024 stay open.

## E. Implementation milestone once decisions are approved
ONE MASTER Claude implementation prompt covering SB-M44-001..024, working only in existing original Desktop checkout. Batch CI verification via existing Android `validation_only` (no APK/IPA), no LF dependency, no R2 writes. New scripts/scenes/data under canonical project only, minimal art reuse, versioned nonrewarding tutorial state with strict older-save migration and safe remaining-step recovery; never alter level art or solve-plan. CI tests including headless first-run, 10-level progression, fail/retry, all 4 legal boosters, 2x, newly unlocked/returning, NEW cleared, interruption, resume, background, save migration and hostile repeated callbacks. End with owner visual/mobile acceptance gate; no self-awarded AUDITED_PASS. 20 MiB bounded incidental laptop TEMP and cloud-first large work per `CLAUDE.md §0A`. ChatGPT alone edits `TASKS.md`.
