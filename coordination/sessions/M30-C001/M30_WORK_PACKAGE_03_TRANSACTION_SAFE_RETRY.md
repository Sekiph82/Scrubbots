# M30 Work Package 03 - Transaction-Safe Same-Puzzle Retry

Task: SB-M30-007

- Harden ProductionGameplayHost reset/retry.
- M26 scheduler reset success is the first destructive teardown gate.
- If it fails/defer/pends, abort Retry with no M23/M24/board/speed/terminal false reset.
- On success restore full original board, candidate index, same exact M23 initial candidate, empty slots, zero claims/reservations/agents/assignments/committed work.
- Reset runtime and UI to 1x and PLAYING.
- Compare full initial supply snapshot before play vs after Retry.
- Prove stale pre-retry callbacks cannot mutate the new attempt.
