STATUS: READY

# Build: SB-POLISH-010 card pack opening redesign to the new storyboard master

No spec-writer for this job; the acceptance criteria below come from the launch prompt.

## Acceptance criteria (written by the builder)
1. The new master `assets/ui/generated/masters/scrubbots_pack_opening_master_v01.png` is committed, with a provenance entry in ASSET_GENERATION_MANIFEST.json. The entry says it was approved by Claude under owner-delegated authority, not by owner visual review.
2. Stage 1, DROP: the closed pack drops in from the top with a slight tilt over the blurred, darkened Home background with a radial spotlight. It has a rim glow and a "Tap to open" prompt.
3. Stage 2, CHARGE: the pack shakes, light rays brighten and sparkles appear.
4. Stage 3, BURST: the pack tears with a light burst and confetti. The real committed cards fly up face-down (canonical card back) into a fanned arc.
5. Stage 4, REVEAL: the cards flip face-up into a row. Each card has a rarity glow (Legendary gold rays and halo, Epic purple, Rare blue, Common soft grey). NEW cards get a ribbon, and a green COLLECT button appears.
6. Premium uses the same flow, a bit grander: gold rim and rays, more confetti, five cards.
7. A tap during the opening skips forward one stage. Without skips the opening (Tap 1 to settled hold) takes 2.5 to 4 s.
8. Reduced Effects gets a short version with no drop, shake, particles, burst, flip or spin.
9. Pack contents, pity, economy, card truth and routing are unchanged. No fake cards are shown.
10. Nothing leaks: ambient motion runs in `_process` (no extra tweens), and the particle nodes are fixed and freed with the popup.
11. Evidence stills at 1080x2160 of each stage, plus a premium reveal, are in the job's `evidence/` folder.

## Summary
The Standard and Premium pack ceremonies now follow the four-panel storyboard as native Godot Controls. They reuse only existing approved art: the Home background, the nine Standard and Premium frames, `card_back.png`, `fx_clean_sparkle.png`, the real card art and the existing NEW glow. The two-tap state machine is unchanged (IDLE, OPENING, AWAIT_ROUTE, ROUTING, COMPLETE), and so are the committed models and routing.

`RevealSequencer` has a new `skip_to(i)`. It uses Tween.custom_step to fast-forward through the earlier steps in order, and it powers tap-to-skip. During OPENING a tap jumps to the next stage (frame 04, then pack-out, then the settled hold). It is never Tap 2.

Changes in the ceremony:
- **Backdrop:** a Home background downscaled once as a cheap blur, plus a gradient spotlight, both on the scrim.
- **Rays:** drawn behind the pack and turning slowly.
- **Rim glow:** a child of the pack frame.
- **Particles:** an additive burst at the mouth, plus two fixed CPUParticles2D (sparkles, and one-shot confetti fired on frame 04).
- **Cards (CardView):** new `settle` and `set_arc`; the card back is drawn while face-down; the rarity glow and Legendary rays are drawn under the face. The NEW/DUPLICATE chip is now a ribbon on the top-right corner, red for NEW.
- **COLLECT:** a green button using HomeStyle.style_play_button with the text POPUP_COLLECT. It replaces the "Tap to collect" caption, and a tap anywhere still routes.

Feel adapter bursts now fire when each card lands face-up, keyed and serialised as before. Timing: FRAME_HOLD is [0, 0.24, 0.20 x7], so every beat is still at least 0.18 s. Emerge and settle totals are split per card, so Premium stays at or under 4 s.

Files changed (commit ec7150a3, TASKS.md commit c2cdb6fd):
- assets/ui/generated/masters/scrubbots_pack_opening_master_v01.png (new)
- ASSET_GENERATION_MANIFEST.json (`pack_opening_master_v01`, sha256 f58edad1...)
- scripts/ui/ceremony/standard_pack_ceremony.gd
- scripts/ui/ceremony/premium_pack_ceremony.gd
- scripts/ui/components/reveal_sequencer.gd (`skip_to`)
- tests/m43_c005_c006_standard_pack_presentation.gd: new v15 tap-skips, v16 length, v17 dressing. The v03 "extra taps refused" check is replaced by v15, and v06 now checks COLLECT.
- tests/m43_c005_c007_premium_pack_presentation.gd: the p08 "extra taps refused" clause is dropped (skipping is covered in v15).
- tests/m43_c005_c009_card_state_celebration.gd:
  - k05: the "no rotation/shake/flash/confetti in source" ban is narrowed to "no set_loops/strobe", because the storyboard explicitly asks for shake, burst and confetti. The NEW pulse limits on scale and glow are unchanged.
  - k21: a tap during the celebration now skips to the hold and is never Tap 2.
- tests/m43_c005_c006_owner_review_harness.gd: re-pinned the LF-normalised sha256 of the ceremony and sequencer.
- tests/tools/pack_opening_v04_snapshot.gd (new evidence capture tool, needs a rendering driver).
- TASKS.md: SB-POLISH-010 marked DONE in both the queue row and the checklist.

## Acceptance criteria evidence
1. [x] Master committed in ec7150a3; manifest entry `pack_opening_master_v01` has status MASTER_APPROVED_BY_CLAUDE_DELEGATED and an explicit "not owner visual review" note. JSON parses.
2. [x] `evidence/standard_1_drop_1080x2160.png` shows the tilted pack over the blurred park, with rays and "Tap to open". c006 v17 checks this: "blurred (downscaled) Home background on the scrim" and "IDLE: pack tilted, ambient drop/bob running without a run". v02 still passes: 150 frames in IDLE start no run and no tween.
3. [x] `evidence/standard_2_shake_charge_1080x2160.png` (frame 03 with rays and sparkles). v17 checks "CHARGE shakes the pack; the tear fires the confetti".
4. [x] `evidence/standard_3_tear_burst_1080x2160.png` shows three card backs fanned above the torn pack. v17 checks "cards fly out face-down (card back drawn, face hidden)". v03 and v13 still check: no card before frame 09, and frames 01..09 each bound in order.
5. [x] `evidence/standard_4_reveal_1080x2160.png` shows Common, Rare and Legendary with their glows, NEW and DUPLICATE ribbons, and COLLECT. v17 checks the rarity glow colours, the Legendary-only spin, and the red NEW ribbon at top-right. v06 checks that COLLECT is the only visible button and that pressing it is Tap 2.
6. [x] `evidence/premium_4_reveal_1080x2160.png` (five cards in a 3+2 layout, gold rays) and `evidence/premium_3_tear_burst_1080x2160.png`. c007 passes 19/19.
7. [x] v15 checks each tap jump: CHARGE, then BURST (frames [1,2,3,4]), then REVEAL (all cards emerged, face-down), then AWAIT_ROUTE (all cards at their slots). Routes are unchanged, and Reduced jumps to the hold. v16 measured: Standard all-new 3.78 s, all-duplicate 3.18 s; Premium all-new 3.98 s, all-duplicate 3.18 s; Reduced 0.80 s.
8. [x] v17 Reduced: no `_process`, no particles emitting, cards face-up, no flip, tilt or spin (`evidence/reduced_4_reveal_1080x2160.png`). c009 k06 Reduced passes, and c006 v12 shows Reduced info equals FULL info.
9. [x] c006 v09 passes (economy, RNG and save bytes unchanged), c008 passes 27/27, c007r pity passes 11/11, and c006 c12 passes (no authority identifiers in the source). The cards still come from the validated committed model (c05 and c06 canonical art and names).
10. [x] c006 v11 passes: 16 clears/closes across all phases leave no tween, node or connection behind, and a run freed mid-way leaves no tween. The leak warnings at exit (61 ObjectDB / 30 resources) are identical to the baseline run before this change.
11. [x] Seven stills in `C:/Users/sekip/Desktop/ScrubBots/factory/jobs/090-polish-pack-opening/evidence/`. They were captured with the rendering driver via `tests/tools/pack_opening_v04_snapshot.gd`, a SubViewport + ModalStack harness that never boots main.tscn.

## Validation
Only the pack ceremony suites were run, as instructed. Every suite was run headless and exited 0.

| Suite | Result | Script diagnostics |
|---|---|---|
| m43_c005_c006_standard_pack_presentation | PASS 24/24 | none |
| m43_c005_c007_premium_pack_presentation | PASS 19/19 | none |
| m43_c005_c009_card_state_celebration | PASS 25/25 | none |
| m43_c005f_phase2_results_pack_feel | PASS 22/22 | only the suite's documented EXPECTED_FAULT_INJECTION 'explode' lines |
| m43_c005f_phase2_r01_earned_pack_runtime | PASS 22/22 | same documented injected lines |
| m43_c005_c006_owner_review_harness | PASS 14/14 | none |
| m43_c005_c007_premium_owner_review_harness | PASS 11/11 | none |
| m43_c005_c008_pack_commit_transaction | PASS 27/27 | none |
| m43_c005f_phase3_meta_rewards_acquisition | PASS 15/15 | same documented injected lines |
| m43_c005_c001_ceremony_visual_masters | PASS 17/17 | none |
| m43_master_c007r_pity | PASS 11/11 | none |
| m43_master_c007_collection | PASS 19/19 | none |
| m43_master_c011_c014 | PASS 28/28 | none |
| m43_r15_owner_remediation | PASS 18/18 | none |

All results are LOCAL_PASS. No CI run and no phone build.

Hygiene:
- `git diff --check` is clean on the changed files.
- project.godot was restored after every Godot run.
- `git status --porcelain` is not empty, but none of it is from this job. Before the job started, the worktree already had about 249 tracked `.import` files rewritten by Godot (line endings only; `git diff --ignore-cr-at-eol` shows no content change) and untracked Godot `.uid`/`.import` artifacts. I left them alone rather than run a destructive clean. They go away when the worktree is deleted.

## Log
### Round 1
- Read CLAUDE.md, AGENTS.md, the ceremony and sequencer code, and the pack tests. The baseline c006, c007 and c009 all passed before any change.
- Implemented the V04 storyboard in the Standard ceremony and its CardView, added the Premium gold accent and extra confetti, and added `RevealSequencer.skip_to`.
- Updated the old-semantics test clauses: extra taps refused, the restraint ban on shake/confetti, and the sha pins. Added c006 v15, v16 and v17.
- First run results and fixes:
  - Beat holds at 0.18 s measured 0.173 s because of frame jitter, so holds were raised to 0.20 s.
  - `set_process` in `_init` was overridden on entering the tree, so it moved to `_ready`.
- Captured the evidence stills, then made two visual tweaks: ray alpha 0.40 to 0.30 and rarity glow grow 0.32 to 0.45. The final suite run and the evidence came after these tweaks.
- Not done:
  - The frame-09 art has baked card backs that peek from behind the real face-down cards during the burst. This is intentional; the frames are owner-locked and byte-identical.
  - The storyboard's "TAP TO OPEN" yellow burst lines are approximated by a pulsing yellow caption.
