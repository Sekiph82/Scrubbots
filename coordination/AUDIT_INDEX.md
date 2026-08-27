# SCRUBBOTS Audit Index

This file is the repository-wide index of reusable audit findings and verification lessons. It is owned by the ChatGPT audit step. Claude reads it and applies relevant lessons, but does not rewrite historical audit conclusions.

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

## Audit history

| Cycle | Claude self-audit | ChatGPT audit | Final state | Reusable learning added |
| --- | --- | --- | --- | --- |
| META-C001 | N/A | https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/META-C001/CHATGPT_AUDIT_V01.md | AUDITED_PASS | Coordination evidence chain established. |
| M07-C001 | PENDING | PENDING | PLANNED | PENDING |

## Update rules

- ChatGPT updates this index after an independent audit when a finding should affect future prompts/tests.
- Do not delete old learnings merely because a later test passes. Supersede them explicitly with a newer audit reference when project truth changes.
- Claude must cite the IDs it applied in each `CLAUDE_SELF_AUDIT_VNN.md`.
- New prompt versions should reference relevant audit-learning IDs when prior findings materially affect implementation or verification.
