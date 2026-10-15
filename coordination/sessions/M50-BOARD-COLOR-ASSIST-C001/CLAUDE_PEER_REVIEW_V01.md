# SB-M50-BOARD-001 — CLAUDE_PEER_REVIEW V01

**Type:** `CLAUDE_PEER_REVIEW`. The reviewer was a distinct, fresh-context Claude subagent (`feature-dev:code-reviewer`). It read the source and tests itself, did not use the implementer's narrative, and ran nothing. This is **NOT** a `CHATGPT_INDEPENDENT_AUDIT`, and it is not owner acceptance.

**Scope:** the uncommitted M50-BOARD diff on base `39fd3819`. The reviewer checked it against `CHATGPT_CLAUDE_MASTER_PROMPT_V01.md`.

**Verdict:** no BLOCKER, no MAJOR.

| # | Severity | Finding | Action |
|---|----------|---------|--------|
| 1 | MINOR | `dFdx` / `dFdy` were evaluated inside non-uniform control flow. This can pick the wrong mip on a 1 px ring at glyph-box and clear borders. | **Fixed.** The derivatives are hoisted next to `fwidth(g)` (`dgx` / `dgy`). |
| 2 | MINOR | The glyph atlas was built synchronously on the first gameplay entry, which could cause a hitch on low-end phones. | **Mitigated.** It is now pre-warmed once at app boot (`main.gd`). The measured desktop build time is 33–114 ms. Phone cost is unmeasured and recorded as open. |
| 3 | MINOR | The GPU test proved that ink is present, not *which* glyph is drawn. | **Fixed.** b08 now compares each rendered cell's ink mask with its own C-ID shape (mean 1.00, worst cell 0.98). On 4,300 points where it differs from the next C-ID's shape, 99% follow its own shape. Real GPU, windowed. |
| 4 | NIT | The shader variable `m` was shadowed in a nested scope. | **Fixed.** Renamed to `gl`. |
| 5 | NIT | At about 4 px glyph size, neighbouring atlas tiles could bleed in at high mip levels. | Not changed. Cosmetic only. |
| 6 | NIT | `get_tree()` was used in the `main.gd` signal lambda while out of the tree. | **Fixed.** The lambda now passes `null` when `main` is not inside the tree. |

**Checked OK by the reviewer:**
- **Shader logic.** The texel and atlas math, gradient scaling, CLEARED/VOID gating order, and ink parity between the CPU and the shader are correct.
- **Identity map.** It is keyed on board instance plus palette, so there are no stale identities.
- **Save handling.** Old saves stay compatible, the validation is strict, and the failure-restore path is correct.
- **Static flag.** Its lifetime is sound.
- **Magnifier input.** It covers only the board rect, all loupe nodes ignore input, release is captured, and it does not block Supply, slots, boosters, Pause or 2x.
- **Owner rules.** There are no per-cell nodes, no gameplay mutation, and the source art RGB and alpha are unchanged.

All tests were re-run after the fixes and pass locally (see `CLAUDE_LOG_V01.md`). GitHub Actions was not used.
