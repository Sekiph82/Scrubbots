# M29 Work Package 03 — Cancel, Focus, Pause & Multi-touch Hardening
Tasks: SB-M29-004..009

- Touch cancel consumes nothing.
- Focus loss cancels pending gesture.
- Stale release after focus return consumes nothing.
- Rapid taps cannot duplicate/skip front batches.
- Multi-touch cannot create partial/duplicate placements.
- Separate user pause from system/background suspension.
- While paused/suspended: no input, no scheduler cadence, no in-flight travel.
- Resume preserves 1x/2x and never replays stale input.
- Background/foreground path must be deterministic and regression-tested.
