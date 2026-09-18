# M28-C001 V01 — ChatGPT Final Strict Audit

Date: 2026-09-18
Repository: `Sekiph82/Scrubbots`
Milestone: `M28 — Gameplay Screen Layout`
Cycle: `M28-C001 V01`
Auditor: ChatGPT
Owner baseline before implementation: `48522dbada25b11ed7fc4dd71a3b8d8820591906`
Implementation SHA: `4fd03587a9a19d38104834b51ec418f68e5af7d9`
Claude log SHA: `a503fd0035cb1c331b45d2bc01194b9f3f5e39b6`
Criteria: `coordination/sessions/M28-C001/CHATGPT_MASTER_AUDIT_CRITERIA_V01.md`

## Verdict

**AUDITED_PASS / M28 GAMEPLAY SCREEN LAYOUT CLOSED**

All `SB-M28-001..028` are eligible for closure.

The implementation establishes a real responsive Godot gameplay-screen composition rather than a flattened screenshot. It preserves the accepted M23–M27 gameplay authorities and intentionally leaves production touch activation to M29.

## Governance / diff integrity

Verified implementation range:
- base: `48522dbada25b11ed7fc4dd71a3b8d8820591906`
- implementation: `4fd03587a9a19d38104834b51ec418f68e5af7d9`

Exactly one implementation commit adds the M28 production scene/controller, read-only slot/supply presentation, responsive/safe-area support, tests and evidence. Root `TASKS.md` is absent from Claude's implementation commit.

Implementation -> log is exactly one separate commit that adds only:
- `coordination/sessions/M28-C001/CLAUDE_LOG_V01.md`.

M29 input mechanics, M30+ gameplay rules and AI image generation are absent from the implementation.

## Canonical reference / asset gate

The implementation correctly treats:
`assets/art/references/_owner_inbox/Game Screens/deneme 3 OK.png`

as a **layout/composition reference**, not a production background.

Verified:
- no flattened screenshot use;
- no crop/promotion of Scrubby, props or icons;
- no reference image overwrite;
- zero explicitly-approved gameplay illustration was silently inferred from repository presence;
- neutral native anchors are used where approved illustration is unavailable;
- zero AI image-generation credits.

## Production layout architecture

The production scene:
- uses `SafeAreaRoot`;
- reuses `BoardPresentation` / single-image `BoardRenderer`;
- reuses `ScrubRailView` / canonical Railroad geometry;
- contains exactly five read-only batch-slot views;
- contains M23 supply presentation for 3/4/5 columns and exactly three visible rows;
- keeps preview rows secondary and hidden queue depth unrendered;
- includes four horizontal booster placeholders;
- uses bottom order `Pause | Ad placeholder | Speed control`;
- exposes distinct 1x/2x presentation states;
- contains no Goal/Moves panel;
- contains no Level/lock rail;
- does not revive destination-slot clicking.

The five slot views are not Buttons and expose no `slot_activated` signal.

## Responsive / geometry evidence

Claude reports:
- full root suite: **5346 / 0**;
- dedicated M28 viewport smoke: **239 / 0**;
- all required M22–M27 regression commands PASS;
- `git diff --check`: clean.

Dedicated viewport evidence covers:
- 1080×2160;
- 1170×2532;
- 1290×2796;
- 1080×2400;
- 1440×3200;
- 1080×1920 short portrait;
- 1536×2048 tablet portrait.

Board-size evidence includes small, large/59×59 and two rectangular boards. Board aspect remains exact under responsive scaling and the coordinate round trip is reported within approximately `5e-6`.

Synthetic nonzero safe-area insets keep board, five-slot/supply region, boosters, pause and speed control inside the inner safe rectangle.

Headless GPU capture could not produce PNG screenshots. This is explicitly recorded rather than falsely claimed; deterministic metrics remain valid closure evidence for M28. Manual visual review remains appropriate later on a graphical Godot run.

## Owner speed-control change

The mid-cycle owner rule was correctly incorporated:
- bottom-right is Speed, not Settings;
- new-session presentation defaults to 1x;
- 1x and 2x are visually distinct;
- M28 does not implement timing/toggle behavior early;
- future automatic `M23 supply exhausted -> 2x` is explicitly deferred to production runtime/input integration.

This matches `coordination/OWNER_GAMEPLAY_SPEED_RULE_V01.md`.

## Non-blocking observations

### O-M28-001 — stale word in evidence prose

`evidence/reference_audit.md` ends one layout-contract sentence with `BottomActionRow(pause|ad|settings)`, while the same artifact, production code, tests, owner decision and all current canonical docs correctly use Speed.

This is an evidence-text typo only and does not affect production behavior or authority.

### O-M28-002 — malformed supply-column count is clamped

`BatchSupplyPanel.bind_player_snapshot()` clamps a malformed 2/6-column presentation input to 3/5 instead of rejecting it.

Canonical M23 production truth itself only supports 3/4/5 columns, so this does not violate a legal production state. M29 production binding must nevertheless assert that the authoritative M23 source has exactly 3/4/5 columns rather than relying on UI clamping to sanitize engine truth.

Neither observation warrants an M28 remediation cycle.

## Closure mapping

The actual root M28 tasks are covered even though Claude's log labels some task numbers using implementation-theme descriptions rather than the exact root wording:

- reference audit and MASTER_UI contract;
- board / five-slot / HUD / safe-area regions;
- representative size, rectangular, 59×59, narrow/tall/tablet layouts;
- coordinate accuracy;
- removed Goal/Moves and Level/lock rail;
- board dominance and protected supply width;
- Scrubby/speech/props anchors;
- four boosters;
- Pause/Ad/Speed bottom row;
- approved-asset gate;
- responsive BoardRenderer mapping;
- viewport evidence.

## Closure

Close all `SB-M28-001..028`.

Advance to **M29 — Mobile Touch / production input integration**.

M29 must turn the M28 presentation into a manually playable production path without changing M23–M27 authorities. It must also implement the owner-locked 1x/2x runtime rule and provide a direct Godot manual-playtest scene.
