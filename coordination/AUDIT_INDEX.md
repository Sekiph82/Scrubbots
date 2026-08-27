# SCRUBBOTS Audit Index

This file is ChatGPT-owned repository audit memory. Claude reads and applies relevant learnings while implementing/testing, but Claude does not edit audit conclusions or create audit files.

Canonical policy:
https://github.com/Sekiph82/Scrubbots/blob/main/coordination/AUDIT_POLICY.md

## Active audit learnings

| ID | Applies to | Learning | Required future check | Source |
| --- | --- | --- | --- | --- |
| AL-001 | Core/data scripts | Bare global `class_name` references were unreliable in the headless environment. | Preserve explicit `preload()` unless a deliberate task proves an alternative under headless Godot. | ADR-009 / prior phase evidence |
| AL-002 | BoardRenderer/color tests | 8-bit RGBA image readback can make exact float comparisons fail spuriously. | Use tolerant color comparison or meaningful HSV/property checks instead of brittle exact-float equality. | M06 renderer test failure/fix / docs/06 |
| AL-003 | Performance claims | Headless CPU timing is not on-screen GPU/FPS evidence. | Never claim rendered FPS/GPU performance without an actual measurement method that supports it. | M06 audit baseline |
| AL-004 | Variable board systems | Square-only fixtures can hide fixed-size assumptions. | Test rectangular boards plus difficulty boundaries and 59x59 where scale is relevant. | M03/M06 evidence |
| AL-005 | Task completion | File existence is not completion evidence. | A `tasks.md` item requires validation evidence appropriate to the item. | CLAUDE.md / master task rules |
| AL-006 | Visual references | Missing owner artwork cannot be replaced by generated/guessed files. | Keep missing categories `AWAITING OWNER ASSET`; verify provenance before classifying as owner/canonical art. | M07 locked rule |
| AL-007 | DIRTY/CLEAN visual gate | AI implementation/tests cannot choose final visual treatment. | Preserve M10 as `OWNER_REQUIRED`; test infrastructure/readability only. | M06/M10 design gate |
| AL-008 | Metadata provenance | Unknown metadata must not be inferred merely because a related file exists. | Original filename, dimensions, difficulty, approval, provenance, and similar fields require repository/owner evidence; otherwise keep them null/unverified. | https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M07-C001/CHATGPT_AUDIT_V01.md |
| AL-009 | Validation traceability | A green aggregate test total does not prove that every prompt-required validation step ran. | Record every prompt-mandated command/check individually in `CLAUDE_IMPLEMENTATION_LOG.md`, including smoke/status checks and failures. | https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M07-C001/CHATGPT_AUDIT_V01.md |

## Audit history

| Cycle | ChatGPT audit | Final/current state | Reusable learning |
| --- | --- | --- | --- |
| META-C001 | https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/META-C001/CHATGPT_AUDIT_V01.md | `AUDITED_PASS` | Coordination evidence chain established. |
| M07-C001 | https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M07-C001/CHATGPT_AUDIT_V01.md | `CHANGES_REQUIRED` | Added AL-008 metadata provenance and AL-009 validation traceability. |

## Claude usage rule

Before implementing/testing a new prompt, Claude must:

1. read the prior ChatGPT audit URL(s) explicitly listed by the active prompt;
2. read this index;
3. identify relevant `AL-XXX` items;
4. record in `CLAUDE_IMPLEMENTATION_LOG.md` how those findings changed implementation or testing;
5. run and log the checks required by the active prompt;
6. stop at `AWAITING_AUDIT` when ready for ChatGPT review.

Claude does not create a self-audit file and does not assign audit verdicts.

## Update rules

- ChatGPT updates this index after an independent audit when a finding should affect future prompts/tests.
- Do not delete old learnings simply because a later test passes. Supersede them explicitly with a newer audit reference if project truth changes.
- New ChatGPT prompt versions should reference relevant `AL-XXX` items when prior findings materially affect implementation or verification.
- Historical Claude self-audit artifacts, if any, are not audit sources and are not listed here as proof.
