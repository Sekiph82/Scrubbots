# M43-C005-C006 — OWNER REVIEW HARNESS — CLAUDE LOG V02 (V03 rebaseline)

Date: 2026-10-04
Implementer: Claude (Opus 5.5)
Canonical task: SB-M43-064 (review tooling only)
Status: **AWAITING_AUDIT** (E1/E2 only; no verdict claimed; not owner approval)

## Inputs read

- Prompt: https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M43-C005-C006/owner_review_harness/CHATGPT_PROMPT_V02.md
- Criteria: https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M43-C005-C006/owner_review_harness/CHATGPT_AUDIT_CRITERIA_V02.md
- V03 audit: https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M43-C005-C006/CHATGPT_AUDIT_V03.md (TECHNICAL_AUDIT_PASS / fresh owner visual gate)
- V03 prompt/criteria, `STANDARD_FRAME_ALPHA_MANIFEST_V03.json`, harness V01 prompt/criteria/log/instructions
- `CLAUDE.md`, root `TASKS.md` (read only, not edited), `coordination/README.md`, `coordination/AUDIT_POLICY.md`
- harness controller/scene, smoke test, current ceremony and frames

## Sync

`git fetch origin --prune` → local `main` 0 ahead / 4 behind (ebc7644 → V03 audit + harness V02 prompt/criteria).
`git merge --ff-only origin/main` clean. Owner/local work preserved, not committed: `M project.godot`,
`M scenes/app/main.tscn`, untracked `.mcp.json`, `addons/`, `*.import`, `*.uid`, owner art.

## 1. Changed files (harness-rebaseline paths only)

| File | Change |
|---|---|
| `tests/m43_c005_c006_owner_review_harness.gd` | V02 hash pin → V03; new h13 V03 frame-family guard, h14 FULL V03 cadence; timing constants added to the no-copy list (12 → 14 cases) |
| `coordination/sessions/M43-C005-C006/owner_review_harness/OWNER_REVIEW_INSTRUCTIONS_V02.md` | new (V01 instructions kept as history) |
| this log | new |

Unchanged (byte-identical, `git diff --quiet HEAD`): `tests/tools/owner_review/standard_pack_owner_review.gd`,
`tests/tools/owner_review/standard_pack_owner_review.tscn` — no V03 incompatibility exists; the controller already
wraps the real ceremony and reads frames/timing from production.

## 2. Production immutability proof

`git diff --quiet ebc7644 HEAD -- scripts assets/ui/final assets/ui/candidates` → unchanged since the audited V03 commit,
and unchanged in the working tree after this pass (the temporary sensitivity mutations in §4 were restored and verified with `cmp`).

| File | git blob @HEAD | sha256 (LF-normalised, pinned in h03) |
|---|---|---|
| `scripts/ui/ceremony/standard_pack_ceremony.gd` | `d4766e31…` | `380cec3eb925d6f7181deda32619d4ff7cd749aacc4d3303f5345c36bbb1f322` |
| `scripts/ui/ceremony/standard_pack_model.gd` | `1904e33c…` | `2db015d362fdfa2e5b2040d7e3ebcbaed59986811b2d364980082095a655f481` |
| `scripts/ui/components/reveal_sequencer.gd` | `c3f6e04e…` | `ccfcc426db81da9ce623d262611191c0039a5f4bd21c46aa3d3decdbf9d2a5ca` |

Old V02 pin `f570d9bf…` (raw bytes of the V02 ceremony) replaced. The pin now hashes LF-normalised text because this
Windows checkout stores the ceremony with CRLF while the repo blob is LF; a raw-byte pin would differ between checkouts.
h03 also asserts the normaliser is line-ending independent but content sensitive.

## 3. V03 asset guard (h13)

- 9 shipping frames == `STANDARD_FRAME_ALPHA_MANIFEST_V03.json` `sha256_after` == V03 clean candidates — PASS
- 01..04 == historical bytes; 05..09 differ from the historical dirty bytes (`[true×4, false×5]`) — PASS
- all 9 manifest rows `metrics_after.clean == true` — PASS
- the review ceremony binds exactly the V03 bytes for beats 01..09 (texture file sha per bound beat) — PASS

## 4. Tests

| # | Command | Expected | Actual |
|---|---|---|---|
| 1 | `godot --headless --path . -s res://tests/m43_c005_c006_owner_review_harness.gd` | 14/14 | **PASS 14/14**, 0 script errors |
| 2 | `godot --headless --path . -s res://tests/m43_c005_c006_standard_pack_presentation.gd` | 21/21 | **PASS 21/21**; measured holds 0.401 / 0.218 / 0.222 / 0.221 / 0.220 / 0.221 / 0.222 / 0.223 s |
| 3 | `python tools/validate_m43_c005_standard_frame_alpha_v03.py assets/ui/final/rewards/pack_opening/standard` | 9 CLEAN | **9/9 CLEAN**, rc 0 |
| 4 | `godot --headless --path . -s res://tests/m43_c005_c005_reward_reveal_sequencer.gd` | 12/12 | **PASS 12/12** |
| 5 | `git diff --check` | clean | **clean** |
| S | harness-smoke sensitivity (temporary; restored; `cmp` RESTORED) | each fails | HS1 historical dirty frame 07 put into shipping → 3 FAIL (h13); HS2 ceremony source changed by one comment line → 1 FAIL (h03); HS3 a `0.22` beat constant added to the harness controller → 2 FAIL (h11, h14). **All detected** |

h14 (test-driven Tap 1; the harness never taps): frame history exactly `[1..9]`; configured FULL holds
`[0.4, 0.22×7]` all ≥ 0.18 s; harness source carries no beat timing. Root suite not rerun (only harness test /
instructions / log changed; production already root-audited in V03).

## 5. Manual Run-Current-Scene (F6) check

Godot editor opened on the review scene; run with the editor's Run Current Scene (`project_run(mode="current",
autosave=false)` via the godot-ai bridge); mouse clicks and keys delivered to the running game; state read with
screenshots and UI-tree queries.

| Check | Result |
|---|---|
| launches | live, no errors |
| initial pack waits | ~15 s / 886 frames untouched: pack alone, "Tap to open" |
| click 1 starts FULL V03 | live samples (≈0.22 s apart) showed the closed pack, then the pressure, first-tear, tear-widens and card-emergence beats, and in a second run the open pack with three card backs (09); no black box or dark haze around any sampled beat on the ceremony stage |
| 3-card hold + destinations | three cards, Collection upper-left, Cards Exchange upper-right, "Tap to collect your cards"; **stayed there 6 s** after a single click (no auto-route) |
| click 2 routing | cards fly; completion note "Review complete (mixed · FULL)" |
| E | Reduced: all-NEW (key 2) went straight to the hold; completion "Review complete (all_new · REDUCED)" |
| 1 / 2 / 3 | 2 → Scrubby / Turbo Wheels / Storm Cleaner (all NEW); 3 → Mighty Mop NEW / Mighty Mop DUPLICATE / Sludge Beast DUPLICATE; 1 → back to the closed pack (mixed) |
| R | fresh closed pack each time |
| errors | game log: none; editor: the 4 pre-existing warnings in `home_style.gd` / `base_popup.gd` only |

Limits and incidents (truthful record):
- **All nine beats in one live run were not captured.** Bridge screenshots are too slow for that: they took 0.2 s to
  2.5 s each, and one stalled for 30 min while the window was resized to 683×1366, apparently by someone at the
  machine. Proof that every beat 01..09 is bound in order comes from h14 / focused v13 (frame history + timing) and
  the V03 rendering-driver capture `evidence/v03/STANDARD_RUNTIME_01_09_V03_CONTACT_SHEET.png`. Judging the live
  cadence by eye is exactly the owner's step 6.
- **Stray route.** I tried single-stepping frames under the debugger suspend; a click sent while suspended was not
  processed. In the next live run the cards routed after my single live click. That was most likely a late delivery
  of the press/release I had sent while suspended. A clean repeat (R, one click, 6 s wait) stayed at the hold, and
  h05/v06 confirm there is no auto-tap or auto-route path.
- **Out-of-window click.** After the window was resized to 683×1366, one click at (341, 1520) fell outside the window
  and did nothing. Clicks inside the window worked.
- The editor is left open. If it re-saves the review `.tscn` with machine-local uid lines on close, that is editor
  metadata (`.uid` files are untracked); the committed scene stays path-only.

This is implementation evidence, not owner approval. No V03 production defect was observed.

## 6. Blockers

None. Next: owner live review with `OWNER_REVIEW_INSTRUCTIONS_V02.md`; only the owner can grant OWNER VISUAL PASS.

`AWAITING_GPT_M43_C005_C006_OWNER_REVIEW_HARNESS_V02_AUDIT`
