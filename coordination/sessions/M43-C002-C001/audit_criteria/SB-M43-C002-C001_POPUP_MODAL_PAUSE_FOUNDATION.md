# SB-M43-C002-C001 — CHATGPT AUDIT CRITERIA

Technical PASS requires:

1. One reusable BasePopup family using existing promoted popup frames and live Godot data.
2. One modal-stack authority; exactly one top modal owns input.
3. Background gameplay/Home input is fully suppressed while a modal is open.
4. Back/Escape closes top modal first with no click/action leakage.
5. Confirm callbacks are exactly-once; cancellation has no side effect.
6. Reward/confirmation popup only displays committed truth.
7. Real Gameplay V02 Pause control opens canonical Pause popup.
8. Resume is deterministic.
9. Restart pre/post-first-action behavior is derived from M30/M39 truth, not UI guesses.
10. Home/exit pre/post-first-action behavior uses accepted attempt/economy truth.
11. Insufficient-SB generic route preserves pending acquisition context without spending/granting.
12. Generic network/error/busy/success-failure states are deterministic and reusable.
13. Busy state blocks duplicate transaction action.
14. Focus/background/resume does not duplicate callbacks.
15. +1 Slot six-shell state survives popup open/close without corruption.
16. Responsive phone/tablet evidence has no clipping and meets safe areas/touch targets.
17. No node/signal/timer accumulation.
18. No popup frame regeneration; dynamic text remains live.
19. Relevant M28/M29/M30/M39/M40/M42/M43/M52/M55/root regressions remain green except documented unchanged historical baseline.
20. TASKS.md untouched by implementer.

Technical verdict if all pass:

`AUDITED_PASS / M43-C002-C001 / OWNER POPUP-PAUSE VISUAL REVIEW REQUIRED`

Owner visual acceptance is separately required before SB-M43-028 and the final visual closure of the Pause family are considered complete.

Otherwise:

`CHANGES_REQUIRED / M43-C002-C001 / <finding>`
