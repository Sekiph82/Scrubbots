# M22-C001 V01 — Production Five-Slot UI Foundation Strict Audit Criteria

Date: 2026-09-14
Repository: `Sekiph82/Scrubbots`
Branch: `main`
Milestone: M22 — Production Slot UI
Actor: Claude (implementer/test runner)
Auditor/tracker owner: ChatGPT

M21 is closed `AUDITED_PASS / STRICT_V2_FINAL_CLOSURE`. V01 must build the reusable production slot UI layer without reopening M21 gameplay authority or treating the M21 debug owner harness as the production screen.

## A. Governance and scope

- **M22-V01-001** Work only in `Sekiph82/Scrubbots` on `main`.
- **M22-V01-002** Safely sync with current `origin/main` while preserving all owner/local tracked and untracked work.
- **M22-V01-003** Read `CLAUDE.md`, root `TASKS.md`, `coordination/AUDIT_POLICY.md`, `CHATGPT_AUDIT_V10.md`, `docs/MASTER_UI_SYSTEM.md`, `ASSET_GENERATION_MANIFEST.json`, current reference inventory, M21 SlotView/presentation source and relevant M12 slot-model source.
- **M22-V01-004** Do not modify root `TASKS.md`; ChatGPT is sole tracker writer.
- **M22-V01-005** Do not modify M21 accepted routing/targeting/dispatcher/clearing/agent/board truth merely for UI convenience.
- **M22-V01-006** Preserve owner Hazard Bot source and all accepted M21 generated artifacts byte-for-byte.
- **M22-V01-007** No force push, destructive reset/clean/restore or owner-work loss.
- **M22-V01-008** No unrelated gameplay feature, economy, booster mechanic, win/lose or M23 full-screen layout implementation.
- **M22-V01-009** Do not generate AI images or spend Magnific credits in V01.
- **M22-V01-010** Do not silently promote raw/reference art to production-final assets.

## B. Visual/reference authority audit

- **M22-V01-011** Confirm `docs/MASTER_UI_SYSTEM.md` remains the UI architecture source of truth.
- **M22-V01-012** Confirm canonical gameplay reference is the manifest-selected owner reference `assets/art/references/_owner_inbox/Game Screens/deneme 3 OK.png` unless newer owner evidence explicitly supersedes it.
- **M22-V01-013** Inventory/audit the existing five-slot visual references already ingested under owner references; record exact paths/status in M22 evidence.
- **M22-V01-014** Preserve owner reference files byte-for-byte; reference audit is read-only except metadata/inventory corrections explicitly authorized by V01.
- **M22-V01-015** Distinguish reference/art direction from production UI implementation: no flattened screenshot is used as an interactive screen.
- **M22-V01-016** Production slot frame/color tile remain Godot-native by default per Master UI System and manifest.

## C. Manifest validation / migration debt

- **M22-V01-017** Validate M22-relevant manifest entries before any generation credits can be spent.
- **M22-V01-018** Correct stale manifest palette source from `scrubbots_palette_v1.json` to current canonical `data/palettes/scrubbots_palette_v2.json`.
- **M22-V01-019** Correct stale `C01..C15` allowed palette list to canonical `C01..C16`.
- **M22-V01-020** Remove/supersede manifest use of old class-specific `3–5 / 6–7 / 8–9 / 10–12` color-count bands as current difficulty truth.
- **M22-V01-021** Represent current production used-color envelope as `3..12` canonical colors and record that difficulty class is not derived from color count.
- **M22-V01-022** Do not alter provider policy: Magnific remains the sole approved UI image-generation provider unless owner changes it.
- **M22-V01-023** Do not generate booster/Scrubby/decorative assets in V01; statuses remain truthful.
- **M22-V01-024** Manifest remains valid JSON after edits and contains no contradictory old palette/difficulty truth in the active contract.

## D. Reusable production component architecture

- **M22-V01-025** Production slot UI is implemented as reusable Godot Control scene/component(s), not only constructed ad hoc in the M21 debug controller.
- **M22-V01-026** Create/standardize a reusable production slot cell under the Master UI component structure (`scenes/components/ui/gameplay/slot_cell.tscn` or an explicitly documented equivalent).
- **M22-V01-027** Create/standardize a reusable five-slot/color-selection panel component (`color_selection_panel.tscn` or documented equivalent).
- **M22-V01-028** Existing `scripts/ui/slot_view.gd` may be migrated/reused, but production API compatibility with M21 behavior must be preserved or deliberately adapted with regression tests.
- **M22-V01-029** Slot component owns presentation only and never mutates SlotState, BoardState, CandidateIndex, ReservationState, TargetSelector, routing or clearing truth.
- **M22-V01-030** UI does not retain mutable SlotState or SlotSystem references by accidental reference leakage when scalar/query snapshots suffice.
- **M22-V01-031** Exactly five visible slot cells are created for production gameplay presentation.
- **M22-V01-032** Slot IDs are stable and map one-to-one to the five real slot identities.
- **M22-V01-033** Slot color presentation is derived from the real bound LevelData/SlotSystem color mapping, not hard-coded decorative order.
- **M22-V01-034** All five palette colors render exactly without filtering/interpolation-induced color mutation.
- **M22-V01-035** Text is not baked into slot art; normal labels/quantities remain live Godot UI if present.

## E. Interaction contract

- **M22-V01-036** Each slot has one real interactive Button/Control activation surface.
- **M22-V01-037** Minimum production touch target is at least 88 reference pixels in both dimensions.
- **M22-V01-038** Desktop mouse activation remains supported for development.
- **M22-V01-039** One click/tap emits exactly one slot activation event with the correct slot ID.
- **M22-V01-040** Slot component itself does not directly call target selection, routing, BoardState mutation or clearing.
- **M22-V01-041** Production gameplay adapter/controller routes slot activation into the already-accepted M21 `CompleteClearingLoop` path, without a second hidden keyboard dispatch path.
- **M22-V01-042** SPACE or any replacement hidden gameplay keyboard shortcut remains absent.
- **M22-V01-043** Rapid Button presses do not collapse different slot IDs, duplicate a single input event, or corrupt presentation bookkeeping.
- **M22-V01-044** Rapid same-slot interaction remains compatible with accepted M21 reservation/dispatch concurrency (`380,381,382` style behavior on the Hazard Bot fixture).
- **M22-V01-045** Production UI does not invent slot cooldown/refill/quantity rules that remain design-gated.

## F. Active / in-flight presentation

- **M22-V01-046** Active visual is presentation-only and driven from accepted in-flight assignment truth or an equally narrow presentation adapter.
- **M22-V01-047** Slot remains visually active while one or more assignments for that slot remain in flight.
- **M22-V01-048** With three same-slot assignments, active state remains through 3→2→1 and returns idle only at zero.
- **M22-V01-049** Different slots track active presentation independently.
- **M22-V01-050** Reset clears presentation bookkeeping and active visuals without changing accepted M21 reset gameplay semantics.
- **M22-V01-051** No-work final visual styling is NOT invented in V01 if still owner/design-gated; behavior remains correct even without a special no-work skin.

## G. Scrubbot spawn anchor

- **M22-V01-052** Every production slot exposes a presentation-only spawn anchor derived from actual laid-out slot geometry.
- **M22-V01-053** Spawn anchor is not a hard-coded board coordinate.
- **M22-V01-054** Mapping from visible slot anchor into board/AgentLayer route space uses the accepted BoardPresentation transform contract.
- **M22-V01-055** Real agent route start matches mapped clicked slot anchor within a strict tolerance.
- **M22-V01-056** Five slot anchors remain distinguishable and ordered with their actual visible cells.
- **M22-V01-057** Responsive re-layout updates anchor geometry correctly; stale pre-layout coordinates are not cached as gameplay truth.

## H. Production five-slot layout

- **M22-V01-058** Exactly five slots remain simultaneously visible in required portrait layouts.
- **M22-V01-059** Layout is container/responsive-driven, not five absolute screen coordinates tied to one resolution.
- **M22-V01-060** Slot order remains deterministic left-to-right.
- **M22-V01-061** Color-selection panel preserves a usable minimum width per Master UI System.
- **M22-V01-062** Slots do not overlap at required viewport matrix.
- **M22-V01-063** Essential slot controls stay inside the supplied safe rectangle/harness at every required viewport.
- **M22-V01-064** Board/slot presentation relationship does not distort BoardRenderer aspect ratio.
- **M22-V01-065** Component architecture does not create one UI node per board cell.

## I. Required responsive matrix

Exercise production slot component/panel at minimum:

- **M22-V01-066** `1080×2160` baseline.
- **M22-V01-067** `1170×2532`.
- **M22-V01-068** `1290×2796`.
- **M22-V01-069** `1080×2400`.
- **M22-V01-070** `1440×3200`.
- **M22-V01-071** one shorter 16:9 portrait case.
- **M22-V01-072** one tablet portrait case.
- **M22-V01-073** For every case, all five slots remain visible/non-overlapping and touch size >= 88 reference px.
- **M22-V01-074** Safe-area harness includes non-zero top/bottom/side insets in at least one phone case.
- **M22-V01-075** Actual spawn anchors after layout remain inside/adjacent to their corresponding slot geometry and map correctly to AgentLayer space.

## J. Production integration / M21 non-regression

- **M22-V01-076** Do not convert the M21 debug scene into the final production gameplay screen; M23 owns full gameplay-screen layout.
- **M22-V01-077** Provide a narrow production/demo integration harness for M22 components if needed, clearly distinguished from final M23 screen.
- **M22-V01-078** Accepted M21 first real C08 click still naturally selects target `380/(0,19)`.
- **M22-V01-079** Accepted bottom-most/left-most target policy remains unchanged.
- **M22-V01-080** Accepted one-cell exterior routing corridor remains unchanged.
- **M22-V01-081** Accepted slot-click-only activation remains unchanged.
- **M22-V01-082** Accepted exact ReservationState lifecycle and M20 clearing authority remain unchanged.
- **M22-V01-083** M21 full 400-cell real-art smoke remains PASS.
- **M22-V01-084** V10/V09/V08/V07 relevant M21 smokes remain PASS.

## K. Tests / evidence

- **M22-V01-085** Add dedicated production SlotView/selection-panel unit tests.
- **M22-V01-086** Test exactly five cells and stable IDs.
- **M22-V01-087** Test real palette/color binding for all five cells.
- **M22-V01-088** Test minimum touch size.
- **M22-V01-089** Test click signal exactly once with correct ID.
- **M22-V01-090** Test active state 3→2→1→0 and cross-slot independence.
- **M22-V01-091** Test reset presentation cleanup.
- **M22-V01-092** Test spawn-anchor geometry after actual layout.
- **M22-V01-093** Test the full required viewport matrix.
- **M22-V01-094** Test non-zero safe-area inset harness.
- **M22-V01-095** Test rapid clicks and verify no duplicate UI emission per input.
- **M22-V01-096** Test component can be instantiated more than once without shared mutable presentation state.
- **M22-V01-097** Test no reference/presentation path mutates owner source assets or LevelData.
- **M22-V01-098** No tautological self-comparisons are accepted as responsive/spawn evidence.

## L. Runtime / regression commands

- **M22-V01-099** Record exact `godot --version` without changing engine installation.
- **M22-V01-100** Run dedicated M22 component/unit tests PASS.
- **M22-V01-101** Run dedicated M22 responsive/safe-area smoke PASS.
- **M22-V01-102** Run M21 V10 final reservation evidence PASS.
- **M22-V01-103** Run M21 V09/V08/V07/V06/V05 relevant smokes PASS.
- **M22-V01-104** Run M21 real-art 400-clear smoke PASS.
- **M22-V01-105** Run required M20 regressions PASS.
- **M22-V01-106** Run full root suite and log exact check count, zero failures and exit 0.
- **M22-V01-107** Production/demo M22 scene/component boots headlessly with zero SCRIPT/Parse errors.
- **M22-V01-108** Manifest JSON parses after migration.
- **M22-V01-109** `git diff --check` clean.

## M. Documentation / evidence

- **M22-V01-110** Create `coordination/sessions/M22-C001/CLAUDE_LOG_V01.md`.
- **M22-V01-111** Log exact changed files and explain production-vs-debug component boundary.
- **M22-V01-112** Log audited owner reference paths used for slot art direction.
- **M22-V01-113** Log manifest corrections and explicitly state zero generation credits spent.
- **M22-V01-114** Log responsive viewport result matrix with slot geometry/touch-size evidence.
- **M22-V01-115** Log spawn-anchor mapping evidence.
- **M22-V01-116** Log M21 locked gameplay identities or exact commit/diff proof sufficient to show they did not move.
- **M22-V01-117** Do not author an audit verdict; ChatGPT owns audit.
- **M22-V01-118** Do not modify root `TASKS.md`; ChatGPT owns tracker.

## N. Closure law

- **M22-V01-119** V01 does not automatically close design-gated `SB-M22-008` no-work visual styling.
- **M22-V01-120** V01 does not automatically close booster/decorative generation rows `SB-M22-015..019` unless owner explicitly expands scope later.
- **M22-V01-121** V01 may satisfy engineering rows `SB-M22-001..007`, `009..014`, `020..021`, `024..025` only after independent ChatGPT audit and any required owner visual gate.
- **M22-V01-122** If a genuine M21 gameplay regression is discovered, stop `BLOCKED` rather than opportunistically rewriting accepted gameplay.
- **M22-V01-123** Push safely to canonical `origin/main`, no force.
- **M22-V01-124** Final Claude handoff is exactly `AWAITING_AUDIT` plus direct GitHub blob URL to `CLAUDE_LOG_V01.md`.
