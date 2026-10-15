# M51 Localization Readiness — CLAUDE milestone master plan V01 (autonomous V02)

2026-10-15 · Claude-authored. Rows `SB-M51-001..009`. No language is chosen here (005 = owner design gate).

## Built
- `scripts/ui/ui_text.gd`:
  - developer pseudo-locale (`UiText.pseudo`, default false, never set by the shipping app);
  - `pseudo_text()` brackets the result, accents letters, keeps digits / symbols / formatted values, and adds ~35 % length;
  - `t()` formats before pseudo-localizing.
- `scripts/ui/settings_panel.gd`: the remaining hard-coded copy (SETTINGS, MASTER / MUSIC / SOUND FX, VIBRATION, REDUCED EFFECTS, CLOSE, OFF, %, status lines) moved to `SETTINGS_*` keys. **English output is byte-identical.**
- `tests/m51_localization_readiness.gd` (4 cases, exact guard):
  - l01: pseudo properties;
  - l02: key convention (UPPER_SNAKE; `REWARD_<resource id>` keeps the canonical lowercase id);
  - l03: Settings fully keyed + frame contained under pseudo (asserted);
  - l04: Home / Tasks / Daily / Shop / Help / gameplay HUD / Results scan for untranslated visible literals and off-screen text under pseudo (REPORTED findings, feeding 001 / 009 and M49-022 / 027).

## Row plan
| Rows | Disposition |
|---|---|
| 001 | Settings fixed; other surfaces measured by l04 |
| 002 | convention asserted |
| 003 / 004 | pseudo-locale + scan |
| 005 | OWNER (languages) |
| 006 | partial (scan coverage) |
| 007 | no real-money prices exist yet (M57); SB amounts use `UiText.num` |
| 008 | pluralization OPEN (copy such as "task reward(s)" needs per-language plural rules) |
| 009 | partial (scan of 7 surfaces) |

## CI
This milestone's planned run is shared with the M50 peer-review remedial and the M49 strengthened m06 / m07 test. All three are logged separately.
