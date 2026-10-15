# M46 Performance — CLAUDE_PEER_REVIEW V01

**Type:** `CLAUDE_PEER_REVIEW`. The reviewer was a distinct, fresh-context Claude subagent (`feature-dev:code-reviewer`). It read the working tree only and did not run Godot or Actions. This is **NOT** a `CHATGPT_INDEPENDENT_AUDIT`.

**Scope:**
- `tests/m46_performance.gd` (new)
- `scripts/ui/batch_slot_view.gd` (identical-rebind skip)
- `scripts/ui/board_magnifier.gd` (idle processing off)

**Verdict:**
- **Production changes:** both are correct and safe. The reviewer traced everything `_refresh()` reads (shell mode, reserve, tile size, symbols, Dictionary value `==`) and found no caller that relies on a rebind to reset visuals.
- **Suite:** a sound local CPU baseline, with the labels tightened.
- **Findings:** no BLOCKER.

| # | Sev | Finding | Action |
|---|-----|---------|--------|
| 1 | MAJOR | The fixes had no regression test. p11 checked net Object growth, which cannot see refcounted churn. | **Fixed.** New p15: 100 identical rebinds keep the same stylebox, a changed snapshot refreshes, and the magnifier is idle, processes while inspecting, then is idle again. p11 relabelled "no net growth". |
| 2 | MINOR | FX ages on real time, so it saturates at its cap; the "≥ 5" density gate was weak. | Density floor raised to **≥ 15** (measured 114). FX saturation **documented** in the log (conservative for the frame cost). |
| 3 | MINOR | Retry leak bounds were too loose (64 objects / 4 MB). | **Fixed.** Now ≤ 8 objects / 256 KB over 30 retries. |
| 4 | MINOR | The header promised "any single frame ≤ 16.7 ms", but only p99 was gated. No GPU cost. | **Fixed.** Header reworded: p99 gated, max reported, CPU only, not device evidence. |
| 5 | MINOR | Single-sample max gates could flake. | **Fixed.** The micro cases now gate on p95. |
| 6 | MINOR | `got > 0` selection check was too weak. | **Fixed.** All 96/96 must reserve. |
| 7 | MINOR | The stripe fixture's coverage is narrow. | **Documented** as open in the log; a second fixture is a follow-up. |
| 8 | NIT | The static-memory monitor could be 0 in some builds. | **Fixed.** Live check added. |
| 9 | NIT | The empty-frame time was printed but not asserted. | **Fixed.** Now asserts < 2 ms. |
| 10 | NIT | Temp names were unique per run, so a crash leaves files behind. | **Fixed.** Fixed names per tag; earlier leftovers deleted. |
| 11 | NIT | The test read a private `_origin_provider`. | **Fixed.** Uses `get_origin_provider()`. |
| — | NIT | A first bind of exactly `{}` with the default colour now skips its first refresh. | Not changed. Unreachable today: the strip always passes a non-empty EMPTY snapshot. |

After the fixes, the suite passed **15/15** locally, and the regression list in the log passed.
