# M51 Localization Readiness — CLAUDE_PEER_REVIEW V01

**Label: `CLAUDE_PEER_REVIEW`** (fresh-context Claude subagent, read-only, 2026-10-15). Not a ChatGPT independent audit. Findings condensed; **[builder]** = disposition.

## Verdict (reviewer): PASS_WITH_MINOR_DEFECTS
- All 11 `SETTINGS_*` English values are byte-identical to the old literals; `"%d%%" % [pct]` gives the same output. No translations are registered.
- `pseudo` defaults to false and is set only by the M51 test.
- `t()` is unchanged when pseudo is off (one static bool check).
- l02 is sound; l03 genuinely catches a visible hard-coded Label / Button with letters; the glyph allowlist is minimal; l04 is correctly report-only.
- CI 38751712898 (l01 test bug only) and 38753823564 (38/38) verified.
- No regressions: `m41_settings` / `m43_r15` check the English strings and pass.
- TASKS.md untouched.

## Defects → disposition
- **D1 Low.**
  - Finding: the plan's claim "SB amounts use `UiText.num`" is false for the HUD booster price `gameplay_screen.gd:814` (`"%d SB" % price`, no key, no grouping).
  - **[builder]** Plan text corrected. The code fix (a key + `UiText.num`) is a small follow-up deferred because the M51 CI budget is used; row 001 stays OPEN for it.
- **D2 Low.**
  - Finding: 'Scrubby' is a data-driven robot name (`data/config/robot_roster_v1.json`), not a missing UiText key.
  - **[builder]** Reworded in the log: whether to localize roster names is an owner / data decision.
- **D3 Low.**
  - Finding: the Shop "off-screen" items are likely content just below the fold of the Shop `ScrollContainer` (`shop_screen.gd:85`); there is no English baseline.
  - **[builder]** Reworded as unconfirmed. A scroll-aware / English-baseline comparison is a follow-up.
- **D4 Low.**
  - Finding: the scan ignores RichTextLabel / LineEdit, accepts keyed + literal concatenations, and l03 checks only the frame rect at one size. The Shop `Title` 133×165 px suggests bad wrapping under pseudo text.
  - **[builder]** Row 003 → PARTIAL; follow-ups recorded.
- Info: `pseudo_text` would mangle BBCode (dev-only mode).

## NOT_RUN
- No local Godot.
- No visual inspection of pseudo screens.
- No English-vs-pseudo Shop comparison.
- `RESULTS_*_SB` grouping not checked.
