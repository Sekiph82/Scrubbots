# M51 Localization Readiness — CLAUDE_LOG_V01 (autonomous V02)

Plan: `CLAUDE_M51_MASTER_PLAN_V01.md` · 2026-10-15 · Builder: Claude Code. Not peer-reviewed yet; not independently audited.

## Commits
- `81fa03dc` series:
  - M50 remedial (`fix(M50)`);
  - M51 feature (`feat(M51)`: UiText pseudo-locale, Settings keys, suite, workflow 38 suites);
  - docs.
- `d0dfb8c2`: l01 test expectation fix (remedial).

## CI (shared planned run + one remedial)
| Run | SHA | Result |
|---|---|---|
| [38751712898](https://github.com/Sekiph82/Scrubbots/actions/runs/38751712898) | `81fa03dc` | validate failure / export skipped. **37/38 PASS**: M49 8/8 (the strengthened m06 drawn-rect + hard containment, m07 deep-link routing: all PASS), **M50 4/4** (remedial: CIEDE2000 Sharma pairs + red Lab reference PASS; protan C01 / brown dE00 3.3, tritan L3 3.8 reproduced in CI), CP06 16/16, M44 23/23, M45 8/8. M51 FAIL 1 assertion — l01 test bug: the expectation "Wín" ignored the map's n→ñ (output `[Wíñ 3 lévéls (100%)~~~~~~~]` is correct). l02 / l03 / l04 PASS. |
| [38753823564](https://github.com/Sekiph82/Scrubbots/actions/runs/38753823564) | `d0dfb8c2` | see addendum |

## l04 findings (pseudo-locale scan, run 38751712898)
| Surface | Untranslated visible literals | Off-screen text |
|---|---|---|
| Home | 0 | 0 |
| Tasks | 0 | 0 |
| Daily | 0 | 0 |
| Help & Tips | 0 | 0 |
| Results (WON) | 0 | 0 |
| **Gameplay HUD** | **5**: `ProfileName='Scrubby'` (robot display name) and booster `Price='500 SB' / '350 SB' / '500 SB' / '750 SB'` (hard-coded `"%d SB"` format) | 0 |
| **Shop** | 0 | **8** nodes past the viewport under +35 % copy (sections / product rows below y = 2160; may be inside a scroll area; needs a scroll-aware check) |

- M49 m08 diagnostic (same run): journey strip and Next Cleanup are visible on WON at 720×1280 / 1080×2160 / 1440×3200. This can be asserted next time.

## Row disposition (tracker request for ChatGPT; local TASKS.md write denied)
| Row | Status |
|---|---|
| 001 | Settings fixed; remaining literals: the gameplay HUD price format + profile name → OPEN (small follow-up) |
| 002 | convention asserted |
| 003 / 004 | pseudo-locale implemented + scanned |
| 005 | OWNER |
| 006 / 009 | partial |
| 007 | no real-money prices yet |
| 008 | OPEN |

## Addendum (run 38753823564)
- **validate = success** ([job 116486874153](https://github.com/Sekiph82/Scrubbots/actions/runs/38753823564/job/116486874153)); export = skipped ([job 116492165106](https://github.com/Sekiph82/Scrubbots/actions/runs/38753823564/job/116492165106)).
- Artifact `11983156886`: 40 log files, no apk / pck / ipa. `import script_diag=0`.
- **38/38 suites PASS**: M51 4/4, M50 4/4, M49 8/8, M45 8/8, M44 23/23, CP06 16/16, `aggregate=PASS`.
- M51 budget used (planned + 1 remedial).
