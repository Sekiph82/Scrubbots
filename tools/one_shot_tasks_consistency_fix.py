from pathlib import Path
import re

p = Path('TASKS.md')
s = p.read_text(encoding='utf-8')

new_b = '''### 8.10B — Scrubbot Railroad V1 `[OWNER-LOCKED CURRENT — 2026-09-17]`

The exact adjacent one-cell exterior ring proven in M21 V07–V10 remains historical evidence only. `coordination/OWNER_SCRUBBOT_RAILROAD_DECISION_V01.md` remains authoritative for canonical Railroad V1 geometry, while `coordination/OWNER_SCRUBBOT_RAILROAD_INTERIOR_PATH_DECISION_V01.md` supersedes only the old straight-only post-rail target approach.

Railroad V1 uses one consistent robotic cleaning rail around every level. Geometry is derived from board `W×H`: artwork-to-rail inner-edge clearance `2.0` logical cells, rail width `1.0` logical cell, therefore rail centreline `2.5` logical cells outside each board boundary. Scrubbots start from the exact owning SlotCell anchor, visibly connect to the BOTTOM rail, and remain on canonical rail sides/corners during all exterior travel.

A Scrubbot may leave Railroad V1 only through a legal orthogonal ingress into OPEN/CLEARED perimeter gameplay space. Rail departure does **not** have to be aligned with the final target row/column. After ingress, the route may traverse OPEN/CLEARED board cells by four-neighbour orthogonal movement with one or more 90-degree turns. Non-target ACTIVE cells remain hard blockers; the assigned ACTIVE target is enterable only as the final endpoint. No diagonal, corner-cut, teleport, free-space exterior shortcut, non-target ACTIVE tunnelling or retargeting is legal.

For an already-assigned target, routing evaluates legal ingress/interior-path combinations and chooses the shortest legal total route including slot connector, rail travel, ingress, interior path and final arrival. Equal-distance side priority remains `BOTTOM → LEFT → RIGHT → TOP`; same-side ties must be deterministic. TargetSelector §8.10A remains WHAT-only and RoutingSystem remains HOW-only.

Railroad V1 is routing/presentation infrastructure only: it is not LevelData, BoardState, C01..C16 artwork, difficulty truth, batch-supply truth or reservation ownership. Collision/lane/congestion rules remain design-gated unless later owner decisions explicitly lock them.'''

s, n1 = re.subn(
    r'### 8\.10B — Scrubbot Railroad V1 .*?\n\n.*?(?=\n\n### 8\.10C —)',
    new_b,
    s,
    count=1,
    flags=re.S,
)
if n1 != 1:
    raise SystemExit(f'8.10B replacement count={n1}')

new_c = '''### 8.10C — Supply-front-only owner gameplay activation `[OWNER-LOCKED CURRENT — 2026-09-17]`

The production player interaction is **selectable front batch click/tap**, not direct slot activation. The five batch slots are automatic destinations and Scrubbot origins; they are not player-selectable placement controls.

The player may activate only the current front/top batch of a supply column. A successful selection transaction sends that batch to the rightmost currently EMPTY slot. If all five slots are occupied, the selection is rejected and the supply column does not advance. Once a batch occupies a slot, Auto Dispatch later spawns Scrubbots automatically from that exact SlotCell anchor only after the target-claim/reservation/valid-route transaction succeeds.

The historical M21/M22 direct color-slot click path remains valid evidence for those earlier vertical-slice and Railroad tests, but it is superseded as the production core-loop interaction. Do not retain or add hidden keyboard dispatch shortcuts such as SPACE. Presentation input must feed the real Batch Supply → Five-Slot Batch → Claim → Auto Dispatch → Routing → ScrubbotAgent → authenticated clear chain.'''

s, n2 = re.subn(
    r'### 8\.10C — .*?\n\n.*?(?=\n\n### 8\.11 —)',
    new_c,
    s,
    count=1,
    flags=re.S,
)
if n2 != 1:
    raise SystemExit(f'8.10C replacement count={n2}')

s = s.replace(
    '| RISK-014 | Hidden debug input diverges from production slot-origin behavior | HIGH | Slot-click-only owner gameplay activation; no SPACE dispatch |',
    '| RISK-014 | Hidden/debug input diverges from production supply-front selection and automatic slot placement | HIGH | Front-batch-only player activation; rightmost-empty auto-placement; no hidden keyboard dispatch |',
)
s = s.replace(
    '+ SLOT-CLICK-ONLY OWNER GAMEPLAY ACTIVATION',
    '+ FRONT-BATCH CLICK/TAP OWNER GAMEPLAY ACTIVATION; FIVE SLOTS AUTO-FILL',
)
s = s.replace(
    '- [ ] SB-M29-001 Touch slot activation.',
    '- [ ] SB-M29-001 Touch selectable supply-front batch activation; five batch slots themselves are not player-selectable placement controls.',
)
s = s.replace(
    'Exact slot refill/replacement behavior; whether slots hold quantities;\nhidden/upcoming slot queue; railroad collision/congestion/lane-separation presentation;',
    'railroad collision/congestion/lane-separation presentation;',
)
s = s.replace(
    '**Not design gates**: the global C01..C16 palette, Difficulty V1 progression/challenge architecture, target positional priority, Railroad V1 geometry/travel/aligned-exit law, and visible-slot-click-only owner activation are owner-locked.',
    '**Not design gates**: the global C01..C16 palette, Difficulty V1 progression/challenge architecture, target positional priority, current Railroad V1 geometry/travel/interior-ingress law, five EMPTY batch slots, rightmost-empty automatic placement, 3/4/5 FIFO supply columns, front-row-only selection, same-color oldest-batch-first arbitration, no-ghost-robot transaction law, and solver-backed supply/deadlock contracts are owner-locked.',
)

stale = [
    'may leave the rail only when exactly aligned with the already-assigned target column',
    '### 8.10C — Slot-click-only owner gameplay activation',
    '+ SLOT-CLICK-ONLY OWNER GAMEPLAY ACTIVATION',
    'Railroad V1 geometry/travel/aligned-exit law',
    'visible-slot-click-only owner activation',
]
for text in stale:
    if text in s:
        raise SystemExit(f'Stale current-rule text remains: {text}')

p.write_text(s, encoding='utf-8', newline='\n')
print('TASKS consistency alignment complete')
