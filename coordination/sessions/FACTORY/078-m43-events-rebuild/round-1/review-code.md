VERDICT: CHANGES

## Checks
git diff --check origin/main...HEAD: pass (no output)
Godot suites: not run (reviewer-tests owns them)

## Findings
1. scripts/ui/ui_text.gd:421 and scripts/ui/components/ui_event_card.gd:129: "1 levels" singular bug. `EVENT_MILESTONE_LEVELS` is a fixed "%s levels", and a milestone with target 1 is a normal case. `tests/tools/meta_snapshot.gd:57` and `tests/m43_master_c011_c014.gd:147` both configure `"target": 1`, so the evidence capture will show "1 levels". Fix: add a key such as `EVENT_MILESTONE_LEVEL_ONE` ("1 level") and pick it in `_row` when `target == 1`. The repo already has this pattern in `TASK_WIN_ONE` / `TASK_WIN_N`. Add one assertion for it in `_event_state_matrix`. The old `EVENT_MILESTONE` had the same wording, but the rebuild makes it a large bold label, and the spec asks for "N levels".

## Notes
- Claim-button reuse and parking logic is sound.
  - `refresh_events` reparents every Button in the old cards to `EventStash` before the cards are freed, so none are freed with them.
  - The stash loop then sets every parked button blocked. The `claim` callable unblocks a button only when a row actually reuses it (`blocked = app.is_blocked`).
  - A row renders a claim button only when `claimable` is true and `claimed` is false, so a claimed milestone becomes a Done pill and its button is parked and blocked.
  - The refresh inside the handler is synchronous, so a second tap on the same aid hits a blocked button, and the economy also refuses a re-claim.
  - Stale callbacks: `_button` reuses the existing button via `get_action_button`. It connects no new signals, because the popup's single `action_selected` handler parses the aid.
  - `ft_join` and `ft_claim` are blocked by the stash loop and then set explicitly afterwards, so they behave as before.
  - When First-Try is absent, its parked buttons stay blocked, which is correct.
  - The stash loop calls `get_meta("aid")` on every stash child. This is safe only because every stash child is a button created by `_button`. Keep it that way.
- `refresh_events` sets `scroll.custom_minimum_size.y` to a fixed 1180 (or 160 when empty). On short frames this may push CLOSE or the frame beyond the viewport instead of scrolling. I did not check the evidence captures at the smallest size. Compare the 5-size captures to confirm.
- `UiEventCard._dhm` is private by name but the tests call it. That is acceptable, but the `UiEventCard` code and the tests would read cleaner with it public.
- Hero asset manifest entry, `.import` files and the `TASKS.md` update are present. `events_v1.json` and `event_services.gd` are untouched.
