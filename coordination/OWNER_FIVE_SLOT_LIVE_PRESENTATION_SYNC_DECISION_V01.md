# OWNER FIVE-SLOT LIVE PRESENTATION SYNC DECISION V01

Date: 2026-09-19
Status: OWNER-LOCKED
Repository: `Sekiph82/Scrubbots`
Scope: Production M24 five-slot player-facing presentation

## 1. Slot UI must reflect live authoritative M24 state

The five-slot strip must not refresh only when the player places a new supply batch.

Every player-visible M24 mutation must eventually refresh the detached UI snapshot immediately in the same logical transaction/frame boundary where practical.

Relevant mutations include:
- successful batch placement;
- successful committed work / robot dispatch;
- ACTIVE -> WAITING because no currently claimable reachable target exists;
- WAITING -> ACTIVE after authoritative wake/reconsideration finds claimable work;
- committed rollback after failed route/spawn;
- authenticated clear finalization;
- slot completion -> EMPTY;
- reset.

The UI remains presentation-only and receives detached scalar snapshots. It must not own or mutate M24 truth.

## 2. Player-facing count

Main count remains owner-locked by:
`coordination/OWNER_BATCH_SLOT_DISPLAY_DECISION_V01.md`

`display_count = remaining_to_clear - committed`.

Therefore:
- Blue 50 with one in-flight robot displays 49;
- with two in-flight robots displays 48;
- never stale `50 (2)`.

## 3. ACTIVE / WAITING display must not be stale

If M25/M26 has authoritatively determined that a batch currently has no claimable reachable target, its slot UI must show WAITING without requiring another player batch placement to refresh the screen.

If a later clear/wake makes work reachable and the batch resumes, UI must update to ACTIVE automatically.

## 4. Hazard Bot reference

For the deterministic M29 Hazard Bot candidate:
- initial Red 15 has no immediate clear;
- initial Yellow 1 has no immediate clear;
- first Blue 50 clears 50;
- second Blue 50 clears another 50;
- first Brown 3 still produces 0 immediate clear at that state.

Therefore after the first two Blue 50 batches have done their available work, the early Brown batch is still not currently claimable/reachable and must present WAITING until later black/open-corridor progress wakes it.

The accepted M27 solution trace is the authority for this reference behavior.

## 5. Implementation boundary

Do not poll UI guesses from visual geometry.

Use an authoritative M24/M25/M26 state-change notification or an equally exact runtime synchronization seam, then push a fresh detached `FiveSlotBatchEngine.snapshot()` into the M28 screen.

Do not make the UI call target selection or routing to decide ACTIVE/WAITING.
