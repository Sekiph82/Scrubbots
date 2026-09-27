# M52-C001-R01 — CHATGPT INDEPENDENT AUDIT V01

Date: 2026-09-27
Auditor: ChatGPT
Repository: `Sekiph82/Scrubbots`
Audited HEAD: `25ad8eb4358d278534adcf687ebf94e519188bb8`
Implementation commit: `914f182bca8e8c51890eba07e8807aedaf315f77`

## Verdict

**AUDITED_PASS / M52-C001-R01 / OWNER REPLAY REQUIRED**

R01 passes the code/evidence/regression gate. It does **not** close the owner-feel gate. The owner must replay Level 2 first, specifically judging simultaneous-lane feel, counter timing, 2x behavior and stutter, then continue Levels 3–10 only if Level 2 feels correct.

## 1. Owner-rule implementation — PASS

Production scheduling now uses `BatchTargetClaimEngine.claim_for_slot(slot, access)`.

The exact slot:
- provides its own M24 color/batch identity;
- provides its own production origin/access;
- receives one unique TargetSelector reservation;
- owns one exact M24 committed-work identity;
- retains exact rollback/finalize semantics.

The old `claim_for_color` path remains only for legacy API/evidence compatibility and is not the production scheduler path.

## 2. Independent per-slot lanes — PASS

`AutoDispatchScheduler` now builds an eligible-slot list ordered by placement sequence with physical slot as tie-break.

Each cadence wave:
- visits each eligible occupied slot at most once;
- may create at most one assignment from that slot;
- supports five baseline lanes / six with +1 Slot;
- stores WAITING per slot/batch rather than globally per color;
- does not allow one blocked same-color lane to block healthy siblings.

## 3. Five BLUE x30 acceptance fixture — PASS

Committed after-evidence proves:

- five occupied C08/BLUE x30 batches;
- one logical cadence wave;
- five live assignments;
- assignment distribution `{0:1,1:1,2:1,3:1,4:1}`;
- board clears = 0 at that checkpoint;
- every slot has `remaining=30`, `committed=1`, displayed `29`.

The same fixture before R01 showed only the oldest same-color slot producing work.

### Runtime-budget nuance

The production runtime intentionally services one lane per rendered frame to avoid putting five route searches into one expensive frame. Thus a five-lane wave completes in five frames (~83 ms at 60 Hz), not literally one CPU frame.

This satisfies the R01 engineering rule because the lane set belongs to one fixed cadence wave and all resulting agents overlap in travel. Whether that visually feels sufficiently "simultaneous" is explicitly reserved for owner replay.

## 4. No-ghost/accounting — PASS

The accepted architecture preserves:
- scheduler assignment;
- dispatcher agent;
- M25 claim;
- ReservationState entry;
- M24 committed work

as equal-cardinality transaction sets.

R01 tests cover N=5 concurrent cardinality, Retry teardown, Tornado with multiple same-color in-flight assignments, pause/focus and unique identities.

M24 authoritative `remaining_to_clear` still changes only on authenticated clear.

## 5. Departure-time visible count — PASS

No fake UI counter was introduced.

The existing player-facing formula remains:
`display = remaining_to_clear - committed`.

R01 proves:
- before clear: 30 remaining / 1 committed / display 29;
- after clear: 29 remaining / 0 committed / display 29;
- rollback before clear restores the prior visible capacity.

Therefore the visible number drops when a real dispatch has been established, before target clear.

## 6. 2x acquisition — PASS

The previous silent no-entitlement return is removed.

No entitlement:
- opens `SpeedAcquisitionPopup`;
- exposes current-level 200 SB;
- 15m 300 SB;
- 30m 500 SB;
- 60m 750 SB;
- Cancel.

Purchase executes through `ProductionActionFacade`, therefore the existing durable save boundary remains authoritative.

Successful purchase immediately enables 2x and updates the control.

Cancel / insufficient SB / failed purchase leave speed and entitlement unchanged.

Existing entitlement continues to toggle 1x/2x directly.

Free M23-supply-exhausted automatic 2x remains separate and free.

The popup is functional production UI only; final visual design remains in the later Player Experience / M43 program.

## 7. Temporal behavior — PASS

`GameplaySpeedAuthority` remains the explicit gameplay-time authority.

2x still:
- halves scheduler cadence interval;
- doubles agent travel delta;
- does not use global `Engine.time_scale`;
- does not change accounting/target/routing policy.

R01 focused evidence covers cadence/travel behavior.

## 8. Stutter root cause / remediation — ENGINEERING PASS, OWNER FEEL REPLAY REQUIRED

The committed baseline instrumentation identifies target selection / route calculation as the dominant Level 2 hitch source, not M27 completion proof.

Baseline 1x:
- worst frame ~1840 ms;
- 516 frames >100 ms;
- 837 frames >33 ms;
- M25 claim mean ~177 ms, max ~1550 ms.

After R01 1x:
- worst frame ~30.5 ms;
- 0 frames >100 ms;
- 0 frames >50 ms;
- 0 frames >33 ms;
- M25 claim mean ~7.3 ms, max ~27.4 ms.

The optimization uses:
- an exact-safe reachability prefilter;
- board revision-bound cache;
- faster route/Dijkstra internals;
- exact keyed candidate ordering;
- one lane of a wave per rendered frame.

Focused equivalence tests compare prefilter verdicts, fast-route results and candidate ordering against reference behavior.

Important: the after-run still records frames above 16.7 ms, so 60-FPS perfection is **not** claimed. The prior multi-hundred-ms/second-scale freezes are removed in headless desktop evidence. Owner interactive play remains the final feel gate.

## 9. M27 / solver consistency — PASS WITH EXPLICIT MODEL NOTE

`ProofKernel` was updated from color-serialized clearing to per-slot wave claims.

The kernel:
- uses exact-slot claims;
- uses each slot's own origin;
- makes one claim per eligible lane per wave;
- reserves all targets before applying that wave's clears;
- uses per-slot WAITING.

Production runtime services those same fixed-wave lanes across consecutive frames. The runtime may have temporal agent overlap; the proof kernel remains the quiescent transition model.

All First 10 content was re-proven after the policy change and all owner sequences also reached WON through the real production runtime.

Four trace hashes legitimately changed because the canonical scheduling order changed; solver status did not.

## 10. First 10 carry-forward — PASS

Re-generated Level 2–10 evidence:
- 9/9 SOLVED;
- trace replay PASS;
- owner click replay PASS;
- production runtime 9/9 WON;
- 0 ACTIVE at completion;
- supply exhausted;
- slots empty.

Level 1 remains on its unchanged historical path.
Frontier 11 remains `CONTENT_MISSING`.

## 11. Regression — PASS

Claude's committed final-state log records:
- new R01 focused suite: 79 checks, PASS;
- M52 owner-plan suite: 255 checks, 9 runtime wins;
- 75 relevant M23–M42/M52 suites: all exit 0, no FAIL, no SCRIPT ERROR;
- root suite: 5323 checks, ALL PASS;
- same nine known engine ERROR lines as baseline;
- diff hygiene clean.

Code review confirms `TASKS.md`, owner source art, owner plans and Level 1 content were not part of the implementation diff.

## 12. Owner replay gate

Use:
`coordination/sessions/M52-C001/remediation/R01/OWNER_REPLAY_CHECKLIST_V01.md`.

Owner must first test Level 2 interactively.

If Level 2 fails the visual simultaneity/stutter/2x/count feel gate, stop and report NOT PASS.

If Level 2 passes, continue the existing First 10 functional owner test through Levels 3–10 and frontier 11.

M53 remains blocked until that owner replay passes.
