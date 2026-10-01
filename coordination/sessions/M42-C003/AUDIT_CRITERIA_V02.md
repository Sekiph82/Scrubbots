# M42-C003 V02 - Independent Audit Criteria

Date: 2026-10-01
Task: SB-M42-035
Audit actor: ChatGPT after Codex handoff

## A. Source authority

- [ ] Codex found `Home_Main_Hero_Assets.zip` without asking the owner to manually prep files.
- [ ] Archive SHA-256 exactly equals `f5c34699f14dabc53a5c8126ad81dabd811711d1acd96fda47e523a18ad64458`.
- [ ] 63 source PNG hashes/dimensions match `OWNER_SOURCE_ASSET_MANIFEST_V02.md`.
- [ ] No external image-generation service was used.
- [ ] HOME-026 source file was not modified.

## B. Production sequence correctness

- [ ] Wave = exactly 14 production frames and reads as one wave.
- [ ] Bow = exactly 15 production frames and contains no late wave contamination.
- [ ] Turn / Look = exactly 17 frames and follows center -> right 25-35 -> center -> left 25-35 -> center.
- [ ] Full Turn = exactly 17 frames and performs a real in-place 360-degree turn.
- [ ] Any source reordering/reuse is documented and uses only owner-approved source frames.

## C. Asset normalization

- [ ] Every promoted frame is 1158x1358 RGBA8 straight-alpha PNG.
- [ ] Background is fully transparent outside art; no number badges/sheet artifacts.
- [ ] One uniform scale per visual family; no per-frame rescale.
- [ ] Soles/root registration is stable and documented.
- [ ] No visible grow/shrink pulse during any gesture.
- [ ] HOME-026 entry/exit transitions do not visibly pop.
- [ ] K1/K2 pass every frame.
- [ ] K3/K4 pass Wave/Bow/Turn-Look per V02.
- [ ] Full Turn K3/K4 warnings are explicitly measured and visible in evidence.
- [ ] Final assets are loaded only from `assets/ui/final/...`, never generated/source paths.
- [ ] HOME manifest SHA pins match promoted bytes.

## D. Runtime component

- [ ] One HomeScrubbyHero component; no one-node-per-frame implementation.
- [ ] Existing M42-C002 1.612 geometry remains authoritative.
- [ ] Art_scrubby compatibility is preserved.
- [ ] Scheduler weights are 35/30/25/10 and immediate repeat is prevented.
- [ ] 6-12 s interval, no stacked gestures.
- [ ] Reduced Effects suppresses large gestures.
- [ ] Hidden route, modal, focus-out, pause lifecycle gates work.
- [ ] No AppState/economy/progression writes.
- [ ] No input interception.

## E. Tests / evidence

- [ ] Full current headless suite passes.
- [ ] New focused M42-C003 V02 tests pass.
- [ ] Deterministic asset tool rerun produces byte-identical outputs.
- [ ] 4 gesture contact sheets exist.
- [ ] 4 gesture 12 fps captures exist.
- [ ] 4 HOME-026 transition strips exist.
- [ ] 1080x2160, 1080x1920, 1290x2796, 1536x2048 captures exist.
- [ ] Reduced Effects capture exists.
- [ ] 20x Home enter/leave leak report passes.
- [ ] Git diff contains no unauthorized TASKS.md edit.
- [ ] Main is pushed and clean.

## Audit result rule

PASS only if all blocking criteria pass and Full Turn warnings are visually acceptable in evidence. Otherwise issue a focused remediation prompt without reopening source-art generation.
