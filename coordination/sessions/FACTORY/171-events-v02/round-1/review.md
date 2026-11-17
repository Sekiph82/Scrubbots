VERDICT: PASS

## Checks
- git diff --check origin/main...HEAD: pass
- ev02_events_v02.gd: PASS (10/10 cases, 0 fail)
- ev02_events_ui.gd: PASS (6/6 cases, 0 fail)
- m22_026_texture_budget.gd: PASS (after a one-off --import; before the import the script failed because the assets were not imported, not because of the branch)
- Captures viewed: 01_events_page_tr_720x1520, 03_details_mega_stain_cleanup_en_720x1520. Layout is clean, the TR names render, the CPU note is shown, reward rows are locked correctly.

## Findings
None.

## Notes
- scripts/gameplay: the only change is the terminal economy wiring in production_gameplay_host.gd (Events gate captured before the win, receipt built from board state read-only). No gameplay rules or data/levels changed.
- Rewards: claim goes through RewardGrantService.grant with tx "event:<iid>:<rid>:rp1". Replays are caught by already_applied. The facade uses _finish_durable (save, then roll back on a failed save). claims_enabled and the worst-case cycle cap are checked in the service.
- The L29 unlock win is not counted (ev_unlocked captured pre-commit). Facade join, claim and tutorial writes are all gated on feature_unlocked("events").
- Clock uses a persisted high-water mark. Rivals are a pure function of instance and time, with no wallet or store input. A missing events_v02 section loads fresh, and a present one is strictly validated.
- Non-blocking: "38 resources still in use at exit" warning from the UI test, and a transient "No loader" error before the import.
- Reward amounts and durations are factory proposals, as the config states.
