VERDICT: PASS

## Checks
git diff --check origin/main...HEAD: pass
Godot suites: not run (reviewer-tests owns them)

## Findings
None.

## Notes
- Reviewed against the spec: once-only marking goes through FtueDirector.acknowledge into the existing seen ledger, and a new profile that has not skipped is the only one that can see an entry (contextual_active), with no dependence on the L1-L3 window. A scheduled step wins (current_step is tried first in _coach_want). The Results reveal and ceremony barrier, modals and Settings suppress display. l3_waiting/l3_hearts are fully removed (only docs/TASKS mention them).
- Poll cost is fine. _coach_trigger returns at once unless the profile is new and not skipped, and otherwise checks 5 slots through is_slot_waiting. It is computed once per tick and passed into _coach_want. Established profiles pay nothing beyond one bool check.
- Situation-end acknowledge: _coach_ctx_id is set only when an entry is really returned for display, so an entry never shown is never marked seen. Acknowledgement happens when the trigger changes (WAITING resolves, Results left or status changes). Because a modal does not change the trigger, a suppressed entry is not consumed. A scheduled step replacing a shown ctx entry still acks it when the situation ends, which is acceptable.
- Style, non-blocking: scripts/app/ftue_config.gd validate() has one ~400-char contextual condition line with tab runs where a line continuation or a small helper (_valid_ctx) would read better. The class header comment line also grew past the neighbouring width. Consider wrapping.
- A WAITING that is transient and lasts less than one 0.2 s tick is never shown, and one that lasts a tick or two shows briefly then acks as seen. This is inherent to a poll-based trigger and is acceptable for a first-encounter hint.
