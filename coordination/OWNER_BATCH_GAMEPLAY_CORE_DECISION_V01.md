# OWNER BATCH GAMEPLAY CORE DECISION V01

Date: 2026-09-17
Status: OWNER-LOCKED
Repository: `Sekiph82/Scrubbots`
Scope: M23–M27 core gameplay program

This decision records the current production batch-gameplay rules that supersede the historical direct-color-slot interaction used by the M21/M22 vertical-slice demos. Historical slot-click evidence remains valid evidence for those completed milestones, but it is not the future production input model.

## 1. Production player input

The player selects a **front/top supply batch** from one supply column.

The player does **not** choose:
- an individual Scrubbot,
- a target pixel,
- a destination slot.

A successful supply selection is handed to the future Five-Slot Batch Engine, which automatically places the batch into the **rightmost currently EMPTY** slot.

If all five slots are occupied, the selection is rejected atomically and the supply column does not advance.

## 2. Supply columns

Production supply supports exactly **3, 4 or 5 independent FIFO columns**.

V1 gameplay validation uses **three visible rows per column**:
- Row 1: front/top, selectable.
- Row 2: preview only.
- Row 3: preview only.
- Deeper rows: hidden from the player.

The engine may support preview depth 4 as configuration, but the V1/Hazard Bot validation path is three visible rows.

Selecting a front batch advances only that column by one position. Other columns must remain byte-for-byte/logically unchanged.

## 3. Batch identity

Each batch is a gameplay-domain value with at least:
- stable unique `batch_id`,
- runtime color identity,
- positive integer robot/pixel quota.

The runtime color identity must use the same integer LevelData/BoardState palette ID already consumed by ColorCandidateIndex and TargetSelector. Do not create a second gameplay color authority from presentation names, guessed hex values or UI colors.

Production LevelData local palettes are validated against the canonical C01..C16 palette and ordered canonically. Human-readable Cxx labels may be derived for debug/provenance, but runtime matching remains the existing integer palette-ID contract.

## 4. Batch counts and conservation

A batch count represents the number of matching logical pixels that the batch must eventually clear.

For candidate supply generated from a level, the total quota generated for each runtime color must equal that level's total required logical-pixel count for that color.

Generation must neither invent nor lose quota.

Every generated batch count must be a strictly positive integer.

## 5. M23 transactional consumption rule

M23 owns supply data and queue semantics only.

A front batch must **not** be permanently removed from a column merely because a click/request occurred. Column consumption must be transactional so a future downstream Five-Slot Batch Engine can accept or reject placement.

Required behavior:
1. caller requests/selects the current front batch,
2. M23 returns a stable selection/transaction identity or equivalent immutable front reference,
3. downstream acceptance commits the removal/advance,
4. downstream rejection/cancel leaves the column unchanged.

The exact method names are implementation detail, but double-commit, stale-commit and cross-column commit must fail closed.

## 6. Deterministic candidate generation

M23 may generate candidate supply layouts from LevelData color totals.

Generation must be:
- deterministic for identical inputs + seed,
- reproducible from a persisted/reported seed,
- bounded,
- conservation-correct,
- valid for configured 3/4/5 columns,
- free of malformed batches/duplicate batch IDs.

At M23, generated layouts are **candidates**, not yet certified production-solvable.

M27 Solvability / Deadlock Engine is the later authority that accepts or rejects generated supply for production based on real gameplay solvability.

M23 must not fake or pre-implement that proof.

## 7. Five-slot batch behavior reserved for M24

M23 must not implement the Five-Slot Batch Engine.

M24 will own:
- exactly five EMPTY batch slots,
- rightmost-empty automatic placement,
- occupied-slot batch lifecycle,
- remaining/committed counters,
- WAITING/resume,
- slot completion/freeing.

M23 may expose a clean transactional handoff API for M24, but must not mutate SlotSystem or introduce partial slot-batch truth.

## 8. Target claims reserved for M25

M23 must not select, reserve or claim target pixels.

M25 will own batch-level arbitration while preserving existing ReservationState and TargetSelector authorities.

No inaccessible future target is pre-owned by a batch.

## 9. Auto dispatch reserved for M26

M23 must not spawn Scrubbots, call Dispatcher, choose routes or decrement batch work.

M26 will enforce:
`no target + no reservation + no valid route = no robot`.

## 10. Solvability/deadlock reserved for M27

M23 must not declare a supply layout production-solvable merely because quota totals match.

M27 will model the real five-slot, FIFO-column, targetability, claim, routing and batch-lifecycle rules and prove at least one legal completion sequence.

Runtime deadlock classification is also M27 scope.

## 11. Existing audited gameplay systems remain protected

M23 may read LevelData and canonical palette truth as necessary, but it must not weaken or rewrite:
- BoardState ACTIVE/CLEARED truth,
- ColorCandidateIndex,
- ReservationState,
- TargetSelector WHAT policy,
- ProductionTargetAccess,
- ProductionRoutingSystem / Railroad V1,
- Dispatcher,
- ScrubbotAgent,
- CompleteClearingLoop authenticated clear behavior.

M22 V07 routing remains accepted:
- exact slot anchor,
- visible BOTTOM connector,
- canonical Railroad V1 exterior travel,
- legal orthogonal ingress into OPEN/CLEARED perimeter space,
- four-neighbour orthogonal interior paths with turns,
- non-target ACTIVE cells block,
- assigned ACTIVE target is final endpoint only,
- no diagonal/corner-cut/teleport/retarget.

## 12. Reset, snapshots and UI separation

M23 state must support deterministic reset to its initial queue/seed state.

It must expose read-only snapshot/query data suitable for future UI/save/replay consumers without returning mutable internal queue storage.

M23 is gameplay-domain logic. It must not depend on Godot Control/Node presentation classes.

## 13. No image generation

M23–M27 core gameplay engineering requires zero image-generation credits unless the owner separately opens a visual task.

## 14. Precedence

This owner decision and the 2026-09-17 owner-locked batch sections in root `TASKS.md` supersede older direct-slot/"no queue mechanics" wording in historical docs or earlier operating-manual text where they conflict.

Historical evidence remains historical evidence; future production behavior follows this decision.
