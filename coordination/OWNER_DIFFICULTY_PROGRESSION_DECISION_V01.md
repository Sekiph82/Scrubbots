# OWNER DIFFICULTY / PROGRESSION / RETENTION DECISION V01

Status: **OWNER-LOCKED — 2026-09-12**
Owner: Şekip
Scope: SCRUBBOTS main game, Level Factory, campaign sequencing, production content QA.

This decision is effective immediately at the design/governance level. It supersedes any older statement that equates player-facing difficulty directly with board dimensions or with a fixed distinct-color band.

## 1. Locked ten-level rhythm

Every ten-level block uses this exact class rhythm and repeats indefinitely:

1. EASY
2. EASY
3. MEDIUM
4. EASY
5. HARD
6. EASY
7. EASY
8. MEDIUM
9. EASY
10. VERY_HARD

For level number `n >= 1`:

- cycle slot: `s = ((n - 1) mod 10) + 1`
- completed-cycle index: `k = floor((n - 1) / 10)`

The class rhythm is a retention rhythm, not a board-size schedule.

## 2. Global progression inside each class

An EASY at level 311 must be meaningfully harder and richer than an EASY at level 11 while remaining unmistakably easier than neighboring HARD / VERY_HARD peaks.

V1 progression factor:

`P(k) = 1 - exp(-k / 20)`

V1 lane targets before slot modifiers:

- EASY: `20 + 14 * P(k)`
- MEDIUM: `40 + 13 * P(k)`
- HARD: `58 + 13 * P(k)`
- VERY_HARD: `76 + 12 * P(k)`

Ten-slot micro-modifiers:

- slot 1: `+0`
- slot 2: `+2`
- slot 3: `+0`
- slot 4: `-1`
- slot 5: `+0`
- slot 6: `-2`
- slot 7: `+1`
- slot 8: `+2`
- slot 9: `-1`
- slot 10: `+0`

Target challenge:

`TargetChallenge(n) = lane_base + lane_growth * P(k) + slot_modifier`

Examples under V1:

- Level 11 EASY ≈ 20.68
- Level 111 EASY ≈ 25.92
- Level 311 EASY ≈ 31.03
- Level 310 VERY_HARD ≈ 85.32
- Level 1001 EASY ≈ 33.91

The saturating curve is deliberate: campaign difficulty grows strongly enough to reward mastery without becoming mathematically impossible at very high level numbers.

## 3. Difficulty class is no longer dimension class

The engine stays variable-size.

The current supported production envelope remains width/height `20..59`, rectangular boards allowed, maximum `59x59 = 3481` logical cells. This is an engine/content-capacity envelope, not a player-facing difficulty mapping.

Guidance:

- 20..23: compact / intro / engineering / short-session boards; production-legal when all other gates pass.
- 24..40: preferred standard mobile-content sweet spot.
- 41..48: large-content range; Session Load gate required.
- 49..59: exceptional / challenge / showcase range; never selected merely because a level is HARD or VERY_HARD; strict Session Load and real-device readability gates required.

A 24x24 level may be VERY_HARD. A 38x38 level may be EASY. Board dimensions contribute to Workload / Session Load but do not dictate the class.

The owner-approved 20x20 M21 Hazard Bot remains valid as the first engineering real-art vertical slice. Its current `EASY` label is accepted for the legacy M21 compatibility pipeline; it does not re-lock the old dimension=difficulty policy.

## 4. Distinct color count is no longer a class gate

Production logical artwork still uses only canonical C01..C16.

The old class-specific rule `EASY 3-5 / MEDIUM 6-7 / HARD 8-9 / VERY_HARD 10-12` is superseded as a difficulty-class legality rule.

V1 production artwork may use 3..12 distinct canonical logical colors unless a later audited content rule narrows a specific content family. Color count and color distribution are Difficulty Score inputs, not class identity by themselves.

Local LevelData palette must still:

- contain only colors actually used by logical cells;
- contain only C01..C16;
- be ordered by ascending global C-ID;
- exclude CLEARED transparency, BG01 and presentation-only colors.

## 5. Three separate level-quality axes

Every production candidate must be evaluated on at least these separate axes:

1. **Challenge Score** — cognitive / structural puzzle difficulty, 0..100.
2. **Session Load** — time/action/route burden, 0..100 plus an estimated attempt-duration proxy.
3. **Frustration Risk** — retry/lockup/overlong-attempt risk, 0..100.

A level may be long but easy, or short but very hard. These states must not be collapsed into one number.

## 6. V1 Challenge Score vector

The V1 structural score uses a versioned normalized vector:

- W Workload: 10%
- C Color Complexity: 15%
- A Accessibility Scarcity: 20%
- U Unlock Depth: 20%
- B Bottleneck Pressure: 15%
- R Route Complexity: 10%
- S Slot/Color Pressure: 10%

`Challenge = 100 * (0.10W + 0.15C + 0.20A + 0.20U + 0.15B + 0.10R + 0.10S)`

All components are normalized to 0..1 and versioned. Their exact measurement contracts live in `docs/09_DIFFICULTY_PROGRESSION_RETENTION_SYSTEM.md`.

No coefficient is eternal. Coefficients may be recalibrated only through an explicit version change with regression evidence. Published levels retain score-model provenance.

## 7. Recovery and tension rules

The ten-level rhythm must create a wave, not a staircase.

- slot 3 MEDIUM introduces the first tension peak;
- slot 4 EASY is recovery;
- slot 5 HARD is the mid-cycle mini-boss;
- slot 6 EASY is strong recovery;
- slot 8 MEDIUM is the second tension peak;
- slot 9 EASY restores confidence before the finale;
- slot 10 VERY_HARD is the cycle boss;
- the next slot 1 EASY must be a large relief step even though its absolute EASY target grows over campaign age.

The campaign builder must validate these drops explicitly rather than assuming that class labels guarantee them.

## 8. Retention is a first-class generation objective

The generator/campaign builder must optimize for continued enjoyable play, not maximum difficulty.

Required retention controls:

- challenge waves and recovery slots;
- Session Load caps;
- Frustration Risk caps;
- novelty targets;
- recent-level similarity rejection;
- challenge-vector diversity so successive levels do not all feel difficult for the same reason;
- no new mechanic/art-direction overload on the hardest peak by default;
- no repeated long/high-friction levels without a recovery buffer.

Difficulty escalation alone is not a retention strategy.

## 9. Generator acceptance model

Level generation is evaluator-guided, not blind random generation.

A candidate may be accepted only after:

- legality validation;
- deterministic solvability / canonical simulation when available;
- metric extraction;
- Challenge Score fit to the requested target window;
- Session Load fit;
- Frustration Risk fit;
- novelty/similarity gates;
- visual/readability gates;
- source/provenance preservation;
- owner review where required.

The Factory may regenerate or mutate generated candidates within audited rules. It must never silently mutate owner-original artwork.

## 10. Campaign sequencing

The Level Factory produces accepted candidates with metrics. A separate CampaignBuilder chooses the ordered campaign.

This separation is locked:

- generator creates candidates;
- solver/evaluator measures candidates;
- QA accepts/rejects candidates;
- CampaignBuilder sequences accepted candidates against `TargetChallenge(n)` and retention constraints;
- mobile runtime consumes the resulting declarative campaign/level data.

Campaign reordering must not require level regeneration.

## 11. Calibration and telemetry boundary

V1 can be built without an external analytics SDK.

Initial weights and clear-rate targets are design hypotheses validated by automated simulation + internal playtests. Later, if the owner approves analytics/data collection, anonymized aggregate player outcomes may calibrate model V2+.

No analytics SDK, ad SDK or player-data collection is authorized by this decision.

Initial playtest tuning targets, explicitly calibratable rather than immutable truth:

- EASY first-attempt clear target: 85..95%
- MEDIUM: 70..85%
- HARD: 55..70%
- VERY_HARD: 40..60%

A VERY_HARD level with extremely low clear rate is not automatically "good difficulty"; it is a likely frustration defect until playtest evidence says otherwise.

## 12. Superseded statements

This decision supersedes the difficulty meaning of older statements in:

- root `TASKS.md` §8.3 and §8.7B;
- `CLAUDE.md` rules 30 / 31B and the matching Known-Locked Parameters text;
- `docs/00_PROJECT_BRIEF.md` dimension=difficulty wording;
- `docs/01_GAMEPLAY_SPEC.md` old board-dimension and distinct-color class tables;
- `docs/03_LEVEL_DATA_SPEC.md` wherever production class legality is derived solely from dimensions/colors;
- `docs/05_TECH_DECISIONS.md` ADR-010 only insofar as it equates class with dimension band;
- `docs/08_PIXEL_ART_PALETTE_RULES.md` only insofar as distinct-color bands are treated as class legality;
- old LF04/LF05/LF07/LF08/LF10 task wording that assumes dimension bands define difficulty.

The variable-size engine, 59x59 capability, C01..C16 palette, ACTIVE/CLEARED model, five slots, target/reachability laws, routing separation and all unrelated audited gameplay contracts remain intact.

## 13. Migration rule

Design truth changes now. Runtime validators and legacy docs/tasks must migrate in controlled audited work, without destabilizing the active M21 real-art vertical slice.

Until migration code lands:

- M21 may use the existing legacy validator solely as a compatibility gate for the approved 20x20 asset;
- no new large production campaign should be generated under the superseded dimension=color-class model;
- future ChatGPT implementation prompts must cite this owner decision and the new difficulty/generator specs.
