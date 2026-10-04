# M43-C005-C006 — CHATGPT AUDIT CRITERIA V03

Canonical task: **SB-M43-064**  
Target: Standard Pack 01→09 alpha cleanup + FULL cadence remediation.

## Owner hard gate

- [ ] all 9 Standard shipping frames have clean transparent backgrounds;
- [ ] no frame contains a black/dark rectangular matte;
- [ ] no frame contains a semi-transparent rectangular background wash;
- [ ] all 9 FULL frames are visibly used in exact order 01→09;
- [ ] FULL frames 01..08 each have effective visible hold >=0.18 s;
- [ ] frame 09 remains the final opening beat used for card emergence.

Any remaining rectangular matte or any skipped FULL frame is FAIL.

## Asset preservation

- [ ] historical C002 candidate files remain unchanged;
- [ ] new V03 clean candidate family exists;
- [ ] V03 candidate and promoted final are byte-identical per frame;
- [ ] 1024×1536 RGBA retained;
- [ ] pack identity/geometry/registration preserved;
- [ ] tear progression unchanged;
- [ ] card counts/positions unchanged;
- [ ] intentional glow/effects preserved;
- [ ] no redraw/regeneration of pack identity.

## Alpha / matte proof

- [ ] per-frame before/after hashes recorded;
- [ ] per-frame alpha bbox/transparency metrics recorded;
- [ ] validator detects historical dirty 05/07/09 matte;
- [ ] validator detects inserted opaque-black rectangle sensitivity;
- [ ] validator detects inserted semi-transparent dark rectangle sensitivity;
- [ ] no large edge-connected / rectangle-shaped near-black nontransparent matte remains in final 01..09;
- [ ] edge/corner alpha and registration checks pass.

## Visual compositing

- [ ] checkerboard 3×3 01..09 sheet exists and is clean;
- [ ] white 3×3 01..09 sheet exists and is clean;
- [ ] 50% gray 3×3 01..09 sheet exists and is clean;
- [ ] black 3×3 01..09 sheet exists and is clean;
- [ ] no rectangular boundary/halo is visible on any sheet;
- [ ] Claude manually inspected checkerboard and gray frame-by-frame.

## Runtime cadence

- [ ] actual production frame history = [1,2,3,4,5,6,7,8,9];
- [ ] one current pack-frame TextureRect only;
- [ ] no shipping contact sheet/strip;
- [ ] each FULL 01..08 hold >=0.18 s;
- [ ] no skip sensitivity survives;
- [ ] no repeat sensitivity survives;
- [ ] short-hold (<0.18 s) sensitivity fails;
- [ ] actual Godot runtime capture exists for each frame 01..09;
- [ ] runtime 01..09 evidence contact sheet exists.

## V02 flow regression

- [ ] pack-alone IDLE retained;
- [ ] Tap 1 required;
- [ ] cards emerge only in final opening beat;
- [ ] pack disappears after reveal;
- [ ] exactly 3 cards hold;
- [ ] Collection upper-left / Cards Exchange upper-right;
- [ ] Tap 2 required;
- [ ] NEW -> Collection;
- [ ] DUPLICATE -> Cards Exchange;
- [ ] completion once after 3 arrivals;
- [ ] no authority mutation;
- [ ] lifecycle/re-entry safe;
- [ ] Reduced Effects retains two gates and frame-09 shortcut semantics.

## Tests / governance

- [ ] updated focused SB-M43-064 suite PASS;
- [ ] V03 alpha/matte validator PASS;
- [ ] SB-M43-063 RevealSequencer PASS;
- [ ] relevant M43 regressions PASS;
- [ ] root suite PASS;
- [ ] git diff --check clean;
- [ ] Claude did not edit root TASKS.md;
- [ ] owner-review harness V01 not implemented in this pass;
- [ ] SB-M43-065 not started;
- [ ] Desktop sync completed non-destructively before work.

## Closure

Even on technical PASS, SB-M43-064 remains open for a fresh OWNER VISUAL PASS using a new owner-review harness built against the cleaned V03 production state.
