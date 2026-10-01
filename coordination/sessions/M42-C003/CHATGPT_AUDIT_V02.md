# M42-C003 V02 - CHATGPT INDEPENDENT AUDIT

Date: 2026-10-01
Task: SB-M42-035
Input: CODEX_LOG_V02 + evidence_v02
Result: **CORRECT STOP / V02 SPEC CONFLICT CONFIRMED**

## Findings

Codex correctly stopped under the literal V02 rules.

Verified from published evidence:

- exact owner archive was found and hash-matched;
- all 63 source frames were verified;
- deterministic preparation succeeded 63/63 twice;
- all candidates are 1158x1358 RGBA8;
- baseline focused tests passed 112/112;
- runtime/promotion were not falsely claimed;
- HOME-026 remained unchanged.

The blocker is real **under V02's fixed 1158x1358 animation-canvas + texture-space helper keep-out model**:

- canvas-contained Wave visor width reaches about 70.3% of HOME-026;
- Bow about 60.3%;
- Full-Turn-source Turn/Look about 62.9%;
- enforcing V02 hard helper keep-outs forces the first three families smaller still.

Therefore Codex was correct not to promote or integrate.

## Root-cause correction

The V02 blocker is not evidence that the owner-approved art must be regenerated.

The conflict is caused by forcing animated poses with wider limb/brush extents into the **same fixed source texture canvas** as HOME-026, then applying helper exclusions in that texture coordinate system.

That is unnecessarily restrictive for a runtime hero component.

M42-C003 V03 changes the representation while preserving the visual authority:

- HOME-026 remains 1158x1358 and unchanged;
- animation frames may use a larger common transparent canvas;
- all animation frames share one animation-space pivot/root;
- source art is uniformly scaled per family to match HOME-026 character scale;
- runtime positions each animation texture by the common screen-space soles pivot rather than assuming the HOME texture rectangle;
- UI collision/safe-area validation is performed in **actual screen space** at the four required viewports;
- decorative left/right helper overlap is a visual warning, not a reason to shrink the hero;
- Play/HUD/shortcut collision remains blocking.

This preserves the owner's locked 1.612 hero presentation instead of shrinking Scrubby to satisfy an artifact of V02 texture coordinates.

V02 is closed as a correct technical stop. Continue with V03 remediation; do not reopen image generation.
