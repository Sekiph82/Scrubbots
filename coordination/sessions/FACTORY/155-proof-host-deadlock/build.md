STATUS: BLOCKED

# Build: solver-proven orders deadlock in real 60 Hz play (SB-PROOF-HOST-2026-11-12)

## Summary
No code change and no commit. The branch `factory/155-proof-host-deadlock` is still at `5fa3359b` and its tracked tree is clean.

The investigation found no bug on either side:
- The production host is correct. Its deadlock is real.
- The ProofKernel is correct for its documented timing contract: it places the next batch only after everything has stopped moving. Played that way in the real production host, both Factory orders are WON.
- The orders are LOST only under the eager human policy that the real-play gate uses: fill every free slot at once, while bots are still flying. The owner chose that policy on 2026-10-31 (no barrier).

To make the kernel and the host agree, a human has to decide which timing counts as winnable (see `## Blocked`).

Inputs were copied from the Pixel Art Generator folders, which were only read, into `inputs/lf009/` and `inputs/lf037/`. The probe scripts and real-play outputs are in `investigation/`:
- `compare.gd`: scratch probe, not committed.
- `an2.py`: divergence analysis.
- `lf0xx_real_play_head_5fa3359b.json`: `tools/real_play_file.gd` output.

## Blocked
The spec asks for a fix "in one place" so that the kernel and the host give the same outcome. Each possible place either contradicts an owner decision or does not give real parity:

1. **Host.** There is no bug to fix. The kernel was run from the host's stuck state and made 0 clears in both cases, so the host's all-WAITING deadlock is real. Changing host pacing so that it matches the kernel is the wave-barrier plan the owner rejected on 2026-10-31 (factory 080 spec; docs/10 §24).
2. **Kernel.** The kernel is timeless. To reject these orders it would have to simulate the host's timing in full:
   - cadence 1/3 s at 1x and auto-2x after the last placement;
   - one lane serviced per frame, and `queue_lane` on placement;
   - bot travel at host speed over routes with railway-first costs, starting from laid-out SlotOriginProvider origins;
   - early slot release on the last departure;
   - the 96-tick finish hold;
   - frame-quantised arrivals.

   That would rebuild the host inside the kernel, and any mismatch brings the divergence back. The Difficulty V1 analyzer and the campaign solver evidence also use this kernel and must not change. A separate "eager" kernel mode would therefore be a large new subsystem, not a one-place fix.
3. **Real-play gate.** One change makes both sides agree today: play a kernel-proven order with the kernel's timing, placing a click only when the host is quiescent. Both orders are WON that way (evidence below). But it redefines "shippable" from eager play to patient play, which overrides the owner's 2026-10-31 human-policy and no-barrier decision.

**Question for the owner (one line):** Should a level count as winnable when the kernel's click order wins in the real game played patiently (each tap only when nothing is moving), or must it stay winnable when every free slot is refilled at once (today's rule, under which LF-000009 and LF-000037 are correctly LOST)?

Recommendation if no answer comes: keep today's rule. Then nothing in the game needs to change, and the Factory has to stop treating kernel SOLVED as shippable. It could real-play-verify several different kernel solutions per candidate, or the real-play search could get a speed-up task. The 900 s timeout comes from `NODE_BUDGET` 400 × about 11 s per replay.

## Reproduction (step 1)
Command: `tools/real_play_file.gd --canonical-only` on the copied inputs, at 1/60.

| Case | HEAD 5fa3359b (with the factory 153 finish hold) | Pre-hold behaviour (holds cleared every frame = dd54007a/9f1ada33) | Factory report |
|---|---|---|---|
| LF-000009 (93 clicks) | LOST, stuck at click 47, frame 29481, residue 661, five WAITING | LOST, stuck at click 27, frame 8635, residue 941 | click 27, frame 8635 (exact match) |
| LF-000037 (76 clicks) | LOST, stuck at click 26, frame 12492, residue 754, five WAITING | LOST, stuck at click 26, frame 10849, residue 754 | click 26, frame 10849 (exact match) |

So the hold moves where the play gets stuck (LF-000009: click 27 to click 47; LF-000037: same click, later frame), but neither order is won with or without it. Both runs gave no `SCRIPT ERROR`/`Parse Error` after a one-off `--import`.

## Divergence (step 2)
Method: one scratch probe (`investigation/compare.gd`) replays the plan through `ProofKernel.apply_placement`, using an observer to record every claim. It then plays the same plan in a fresh `ProductionGameplayHost`, driven exactly like `RealPlayDriver.play_on_host`. For the host it logs:
- every placement: frame, slot and batch;
- every authenticated clear: frame, cell and colour;
- every change of slot state: batch, colour, remaining, committed, ACTIVE/WAITING and the scheduler's WAITING flag.

The first divergence is the placement timing at click 2, frame 0:
- **Kernel.** Click 1 is placed. Its cascade then runs to quiescence before click 2 is placed.
  - LF-000037: click 1 (colour 6, 23 bots) makes 23 clears (ACTIVE 1076 to 1053) and slot 4 empties, so click 2 goes to slot 4.
  - LF-000009: click 1 (colour 4, 24 bots) goes WAITING. Click 2 (colour 6, 22 bots) makes 44 clears before click 3 is placed.
- **Host.** Clicks 1 to 5 are all placed at frame 0, into slots 4, 3, 2, 1, 0, with 0 clears so far:
  - LF-000037: (1,s4,c6,23) (2,s3,c5,20) (3,s2,c1,15) (4,s1,c6,22) (5,s0,c3,20)
  - LF-000009: (1,s4,c4,24) (2,s3,c6,22) (3,s2,c5,19) (4,s1,c4,23) (5,s0,c6,9)

  Two batches of the same colour (LF-000037 clicks 1 and 4; LF-000009 clicks 2 and 5) then dispatch in parallel. Later cadence waves claim while earlier targets are still ACTIVE.
- **Result: different cells of the same colour get cleared.** The first host clear that falls outside the kernel's corresponding batch:
  - LF-000009: frame 482, colour 6, cell (20,49). The kernel clears that colour run in click 2 and this cell only in click 5. By host frame 1346 the first 22 colour-4 clears differ: the kernel clears (11..12, 43..46) and the host clears (28..29, 46..48).
  - LF-000037: frame 426, colour 6, cell (13,47). The kernel clears that run in click 1 and this cell in click 4.
- **This compounds.** In LF-000009 under pre-hold play, the host's click-26 colour-5 batch clears other cells than the kernel's click 26. The kernel's click 26 makes 26 clears (10 c5 plus 16 c4, which completes K1-13). In the host, K1-13 c4 is left with r14 and K1-10 c4 with r2. Click 27 (K1-15 c3) fills the last free slot, and at frame 8584 all five slots are WAITING: K1-13 c4 r14, K1-07 c3 r13, K1-10 c4 r2, K1-15 c3 r18, K1-12 c1 r8. The kernel at the same click has only three occupied slots (K1-15, K1-12, K1-07), two free, and continues with click 28.
- **Soundness check.** `ProofState.from_runtime(host state at the stop)` followed by `ProofKernel.quiesce` gives ok=true, clears=0 for both cases (hold and no hold). The host's WAITING verdict is a true deadlock and not a host bug. Claims and reachability agree; only the timing differs.
- **Kernel timing in the real host.** The same probe ran with one change: a click is placed only when `RealPlayDriver._quiescent(host)` (nothing moving, no live claim, every occupied slot WAITING). Both orders were WON in the production host:
  - LF-000009: 93/93 clicks, 134531 frames, with or without the hold;
  - LF-000037: 76/76 clicks, 104632 frames, with the hold.

  Picks inside a batch still differ a little (claims fire before earlier clears land), but they never decide the outcome here.

## Acceptance criteria
1. [x] Reproduce both cases: see the table above (HEAD and pre-hold).
2. [x] Click-by-click comparison and first divergence: click 2 placement at frame 0 (kernel places at quiescence, host places eagerly). The first divergent clear is at frame 482 (LF-000009) and frame 426 (LF-000037). The host deadlock is real (kernel quiesce from the host state gives 0 clears).
3. [ ] Root cause plus a fix in one place: root cause found (timing contract, not a bug). Fix BLOCKED on the owner question above.
4. [ ] Regression test: not written. Its assertion (same outcome) depends on the decision. The probe in `investigation/compare.gd` is the starting point. Note that a quiescent-timing host play takes about 2 to 3 minutes per level, above the CI target of about 60 s.
5. [ ] Affected suites: not run, because nothing changed.
6. [x] Factory cases after a fix: not applicable. With today's rule both stay LOST, and that is the correct verdict.

## Validation
- `godot --headless --path <wt> --import`: one-off, so that the GFF addon resolves. The tracked `.import`/`project.godot` churn was restored afterwards; untracked `.uid` files were left in place.
- `tools/real_play_file.gd --canonical-only`, both cases at HEAD: LOST (table above).
- `investigation/compare.gd`, 7 runs: LF-000009 eager without hold, eager with hold, patient without hold, patient with hold; LF-000037 eager without hold, eager with hold, patient with hold. Results are as reported.
- `git -C <wt> status --porcelain`: no tracked changes. HEAD is still `5fa3359b`.

## Log
### Round 1
Reproduced both Factory cases on HEAD and with the hold disabled (exact match to the Factory's click and frame without the hold). Built a scratch kernel-vs-host probe and found the first divergence: kernel placement at quiescence versus eager placement in the host, starting at click 2 on frame 0. This leads to different picks among same-colour cells and then a real deadlock. Proved the host deadlock sound (kernel from the host state makes 0 clears) and showed that the host wins both orders under the kernel's timing. No host bug, and no one-place fix that respects the 2026-10-31 owner decision and the analyzer and campaign freezes. Stopped as BLOCKED with one owner question and a recommendation. No commit.
