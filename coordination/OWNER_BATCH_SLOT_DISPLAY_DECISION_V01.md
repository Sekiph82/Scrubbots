# OWNER BATCH SLOT DISPLAY DECISION V01

Date: 2026-09-19
Status: OWNER-LOCKED
Repository: `Sekiph82/Scrubbots`
Scope: Production five-slot batch presentation

## 1. Main displayed count means robots still waiting in the slot

The large/main number shown on an occupied five-slot batch card must represent:

`robots_waiting_in_slot = remaining_to_clear - committed = M24 capacity`

It must NOT display raw `remaining_to_clear` as the main player-facing number.

Examples:
- newly placed Blue 50: display `50`;
- one Scrubbot successfully committed/dispatched from that batch: display `49` immediately;
- two Scrubbots in flight: display `48`;
- when one of those agents authenticates its clear, internal `remaining_to_clear` and `committed` both decrease by one, so the displayed waiting count stays `48`;
- when all remaining robots have left the slot but some are still in flight, display `0` until authenticated completion frees the slot.

This is a PRESENTATION rule only.

## 2. Authoritative M24 accounting remains unchanged

Do not change the accepted gameplay invariant:

- `committed` increments when work is successfully claimed/committed for dispatch;
- `remaining_to_clear` decreases only after an authenticated successful clear;
- `capacity = remaining_to_clear - committed`;
- slot completion remains `remaining_to_clear == 0 && committed == 0`.

Therefore this decision changes what the player sees, not when gameplay quota is authoritatively consumed.

## 3. Do not show raw 'remaining (committed)' as the primary count

The current presentation such as:

`50 (2)`

is superseded.

For that state the main slot count must be:

`48`

because two robots have already left the slot as committed in-flight work.

Committed/in-flight truth may remain available to debug/test tooling. A future approved visual indicator may represent in-flight work separately, but it must not make the main count contradict the number of robots physically waiting in the slot.

## 4. ACTIVE / WAITING semantics

Core M24 lifecycle semantics remain:
- ACTIVE = occupied batch currently eligible for scheduling / not marked unavailable;
- WAITING = occupied batch currently has no claimable production target under accepted TargetSelector + routing/access truth.

WAITING is not a loss of the batch and does not consume quota. Board changes wake/reconsider waiting colors automatically.

For player-facing UI, ACTIVE must not be interpreted as 'a robot is definitely moving right now'. It is an eligibility lifecycle state.

## 5. Hazard Bot reference

For the deterministic M29 Hazard Bot supply candidate, column 1 begins:
- Red 15;
- Yellow 1;
- Blue 50;
- Blue 50;
- Brown 3;
- ...

The accepted M27 solved trace records zero clears for the initial Red and Yellow placements and progress once Blue becomes available. Therefore initial Red/Yellow WAITING is valid behavior, not by itself a bug.

## 6. Precedence

This decision supersedes the current `BatchSlotView` presentation that displays raw `remaining_to_clear` and appends committed work in parentheses.

It does not supersede M24/M25/M26 authoritative accounting.
