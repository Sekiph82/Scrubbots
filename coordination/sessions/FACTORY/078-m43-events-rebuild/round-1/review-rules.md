VERDICT: CHANGES

## Findings
1. scripts/ui/components/ui_event_card.gd:132 and scripts/ui/ui_text.gd:421 — the milestone text always uses "%s levels", so a target of 1 reads "1 levels". This is reachable: evidence/4_events_test_config_1080x1920.png shows "1 levels" on the first row, and any future config with a target-1 milestone would show it too. Fix: add a singular key, for example `EVENT_MILESTONE_LEVEL` = "%s level", and pick it when target == 1 (the repo already has "Win 1 level" in TASK_WIN_ONE). Add one assertion for it in tests/m43_master_c010_meta.gd, then regenerate the evidence screenshots.

## Notes
- Rules check, all fine:
  - data/config/events_v1.json is not in the diff, so no event, reward or currency ships. Production shows the empty state.
  - Reward icons map only to existing bundles, and `UiText.reward_text` supplies the real reward text. There are no new currencies and no Event Points.
  - Presentation only: the card reads the EventService view and mutates nothing. The claim goes through the existing `ev:<id>:<i>` action.
  - The TASKS.md edit is limited to SB-M43-130-REBUILD. It is labelled CLAUDE_PEER_REVIEW pending and visual match by Claude under delegated authority, not owner visual review. That matches the evidence.
  - The hero asset is cropped from the approved master, and the manifest label is honest. No owner-original art was touched.
- 4_events_test_config looks coherent: claimed, claimable and progress rows, the rule strip, and the greyed upcoming card. The FirstTry card is clipped by the scroll area, which is expected scroll behaviour.
- The upcoming card's grey tint is a self_modulate, as the build notes admit. This is acceptable.
