# M50 owner decisions A/B (+ M51 HUD price) — CLAUDE_PEER_REVIEW V01

**Label: `CLAUDE_PEER_REVIEW`**: a fresh-context Claude subagent, read-only, 2026-10-15. It did not run Godot. This is **not** a ChatGPT independent audit and **not** owner visual approval. Findings are condensed; lines marked **[builder]** give my disposition.

## Round 1 — feature commit `4cbaa556`
**Verdict (reviewer): PASS_WITH_MINOR_DEFECTS.**

Confirmed by the reviewer:
- the hex → C-ID round-trip, including `#RRGGBBAA` level strings;
- 15 shipped identities;
- the magenta fallback and empty tiles show no symbol;
- the polygons are simple (non-self-intersecting);
- Decision B is scoped to `home_screen.gd` only; contrast recomputed as 7.35 / 9.04 / 5.31, disabled 3.61;
- the workflow guard matches exactly;
- no old assertion breaks (prices are 350–750);
- the owner-dirty files are not in the commit.

Defects:
- **D1 Med:** Tornado / Selector booster target chips were still identified by colour only.
  - **[builder]** Fixed in `43d7e2a2`: Tornado chips get an outlined emblem; Selector chips a watermark under a child Count label. Test s10.
- **D2 Med:** no compact-viewport or 6-slot size coverage, and no minimum symbol size.
  - **[builder]** Fixed in `43d7e2a2`. The new matrix **exposed a real defect**: the corner emblem was ~13 px on production 5-column supply faces (93×79). Redesigned as a centred translucent watermark behind the count at 80 % of the face's short side.
  - s05 now runs 720×1280, 1440×3200, 1536×2048 and 1080×2160 and asserts the smallest symbol ≥ 32 px (measured 34.6).
- **D3 Low:** the overlap check reused the implementation's own formula.
  - **[builder]** Moot: the corner-placement code was removed.
- **D4 Low:** the masks are geometric and the threshold is loose.
  - **[builder]** Partly addressed in round 2 (count-masked comparison). Rendered legibility stays an owner visual gate.
- **D5 Low:** stale "white PLAY fill" finding in `m50_accessibility_audit`.
  - **[builder]** Fixed: it now reports navy-on-green 7.35:1.
- **D6 Low:** symbol over the highlight band.
  - **[builder]** Noted for owner visual review.
- **D7 Info:** layout work per rebind.
  - **[builder]** The 300-rebind timing is recorded in s09.

## Round 2 — remedial commit `43d7e2a2`
**Verdict (reviewer): PASS_WITH_MINOR_DEFECTS.**

Confirmed by the reviewer:
- the symbol is drawn before the count;
- moving the Selector chip text breaks no reader or tap path;
- the toggle styleboxes are unchanged;
- the workflow has 43 suites with a 10/10 guard.

Defects:
- **R1 Med:** circle / ring / bullseye differ only at the centre, which the count covers.
  - **[builder]** Fixed in the follow-up commit:
    - ring → **T shape** (C06);
    - bullseye → **arrow** (C15);
    - three horizontal bars → **lightning bolt** (C11; vertical bars also collided with the frame once the count band was hidden).
  - s03 adds a count-masked silhouette comparison (central band hidden): all 120 pairs IoU < 0.7 (max 0.61).
  - **Not CI-validated in this milestone.** The planned + remedial budget is used. Validated locally in headless Godot 4.7.2 (10/10). It rides the next planned run (M46).
- **R2 Low:** the watermark is faint (≥ 1.3:1 rule; weakest 1.53:1).
  - **[builder]** Owner visual gate; not claimed as accessible-complete.
- **R3 Low:** s10 could pass with Tornado chips only.
  - **[builder]** Fixed: each booster must show at least one chip.
- **R4 Low:** fixed 34 px chip count font.
  - **[builder]** Accepted.
- **R5 Info:** `m28_c002_c003_final_gate` is not in CI.
  - **[builder]** Noted for M54 regression consolidation.

## NOT_RUN
- Physical device.
- Owner's Editor F5.
- Owner visual sign-off.
