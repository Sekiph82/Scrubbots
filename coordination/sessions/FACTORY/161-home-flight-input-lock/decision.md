# 161-home-flight-input-lock decision

APPROVE (2026-11-17). CLAUDE_PEER_REVIEW round 1: PASS (round-1/review.md). Owner requests in chat 2026-11-17: no Home button active until reward flights end; "+N" label and up to 5 icons per reward, counter rises to the exact total.

- Code commit 9cd7974e: RewardFlightLayer blocks input for the whole flight; Back ignored on HOME while flying; safety timer (total + 1 s); +N burst with K = min(N,5) icons, integer per-arrival counter steps landing exactly on the final value.
- Suites LOCAL_PASS: sb_phone_2026_11_12_e_win_home 10/10 (CI guard updated, new lock case fails on base), 13 related Home/ceremony suites; reviewer reran 10/10.
- Non-blocking: no dedicated test for the safety timer.
