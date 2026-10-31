APPROVE

## Why
All three round-2 reviews are PASS with no problem notes, and the branch merges into origin/main without conflicts. The change adds the reusable UiEventCard with active, upcoming and ended states, wires it into the Events screen, and adds the hero art, tests and evidence captures. It leaves the event config and event service untouched.

## Acceptance criteria
1. m43_master_c010_meta passes with the new assertions: met. build.md reports 12/12 and 0 fail in round 2. I did not re-run it.
2. m43_master_c011_c014 and m47_touch_r01_mobile_ux pass: met per build.md (28/28 and 14/14). c011_c014 was re-run in round 2.
3. Texture budget passes: met per build.md.
4. UiEventCard exists, is used by refresh_events, and handles phase: met. I confirmed the phase handling and the phase meta in ui_event_card.gd.
5. No hardcoded illustrative text, and events_v1.json unchanged: met. My grep found only an unrelated comment in profile_screens.gd, and the diff shows no change under data/config or scripts/economy.
6. Rendered captures at 5 sizes, CLEAN: met. The evidence PNGs are in the job folder and build.md reports META_EVIDENCE CLEAN. The master comparison was by eye, and build.md says so.
7. Hero asset, import and manifest entry: met. The diff stat lists the final and raw PNGs with their .import files, and the manifest is changed.
8. diff --check and parse check clean: met per build.md.
9. TASKS.md marks SB-M43-130-REBUILD DONE: met. The diff stat shows TASKS.md changed.
10. Other event suites run: met per build.md.
