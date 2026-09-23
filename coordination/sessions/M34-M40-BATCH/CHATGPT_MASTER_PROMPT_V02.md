# M34–M40 REMEDIATION BATCH V02 — Uninterrupted Audit-Driven Repair Master Prompt

Repository: `Sekiph82/Scrubbots`
Branch: `main`

This batch exists because the independent V01 ChatGPT audits found material defects/gaps.
Do not reuse V01 "PASS" claims as closure truth.

## 0. Read first
- `CLAUDE.md`
- root `TASKS.md` read-only
- `coordination/AUDIT_POLICY.md`
- `coordination/VERSIONED_LOG_POLICY.md`
- `coordination/AUDIT_INDEX.md`
- every V01 `CHATGPT_AUDIT_V01.md` for M34..M40
- every V02 prompt + V02 audit criteria before that milestone

M33 owner listening gate remains deferred and open. Do not close M33.

## 1. Continuous execution rule
Proceed without waiting for ChatGPT between remediation milestones.
Sequence is dependency-aware:

1. M34 V02
2. M36 V02
3. M35 V02
4. M37 V02
5. M38 V02
6. M39 V02
7. M40 V02

M36 intentionally precedes the final M35 V02 revalidation because M35's production catalog still depends on the production validator semantics that M36 must migrate.

At each milestone:
- sync safely with origin/main;
- read V01 audit + V02 criteria/prompt;
- implement or validation-test only as instructed;
- run direct tests + regressions;
- create V02 task logs under `task_logs_v02/`;
- create `CLAUDE_LOG_V02.md`;
- commit implementation/tests first if any;
- commit logs/evidence separately;
- push to origin/main;
- verify remote GitHub log exists;
- continue immediately.

Do not edit root `TASKS.md`.
Do not create ChatGPT audit files.
Do not self-assign AUDITED_PASS.

## 2. M34 V02
Tasks affected: SB-M34-002,003,004,005,006

Prompt:
https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M34-C001/CHATGPT_PROMPT_V02.md

Criteria:
https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M34-C001/CHATGPT_AUDIT_CRITERIA_V02.md

Goal: wire the haptics controller into the REAL production event composition.
SB-M34-006 remains DEVICE/OWNER_REQUIRED after code repair.

## 3. M36 V02
Tasks affected: SB-M36-001,002,006 plus regressions around 003/004.

Prompt:
https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M36-C001/CHATGPT_PROMPT_V02.md

Criteria:
https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M36-C001/CHATGPT_AUDIT_CRITERIA_V02.md

Goal: remove obsolete class=dimension legality from the GENERAL production path.
SB-M36-005 remains OWNER_REQUIRED.

## 4. M35 V02
Tasks affected: SB-M35-002,003,005,007,009,010,011.

Prompt:
https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M35-C001/CHATGPT_PROMPT_V02.md

Criteria:
https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M35-C001/CHATGPT_AUDIT_CRITERIA_V02.md

Goal: true immutable catalog reads, exact integer ordering, canonical path identity, and post-M36 Difficulty-V1 catalog acceptance.

## 5. M37 V02
Tasks affected: validation surface across SB-M37-001..008; production source changes only if a pre-fix adversarial test proves a defect.

Prompt:
https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M37-C001/CHATGPT_PROMPT_V02.md

Criteria:
https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M37-C001/CHATGPT_AUDIT_CRITERIA_V02.md

SB-M37-006 remains OWNER_REQUIRED.

## 6. M38 V02
Tasks affected: strict validation across SB-M38-001..016; source changes only after demonstrated defect.

Prompt:
https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M38-C001/CHATGPT_PROMPT_V02.md

Criteria:
https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M38-C001/CHATGPT_AUDIT_CRITERIA_V02.md

## 7. M39 V02
Primary affected tasks:
SB-M39-020,027,028,031,032,033,034,035,036,037,038,039,040,043,045,048,050,052
plus every task whose state/API changes while closing F-M39-001..010.

Prompt:
https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M39-C001/CHATGPT_PROMPT_V02.md

Criteria:
https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M39-C001/CHATGPT_AUDIT_CRITERIA_V02.md

This is a real production-integration repair:
- live M24 capacity 5/6;
- live M27 capacity-aware proof state;
- concrete M23-M27 booster adapter;
- shipping manual 2x entitlement gate;
- runtime economy event wiring;
- atomic import/exchange;
- strict integer schema;
- Daily/Collection persistence hardening.

SB-M39-033 device-safe-area evidence remains OWNER_REQUIRED after implementation.

## 8. M40 V02
Affected tasks:
SB-M40-001,005,006,008,009,010,011,012,013 and any runtime-lifecycle task touched.

Prompt:
https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M40-C001/CHATGPT_PROMPT_V02.md

Criteria:
https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M40-C001/CHATGPT_AUDIT_CRITERIA_V02.md

M40 final validation must use the POST-M39-V02 schema/state graph.

Goal:
- true safe temp/replace/backup handling;
- validated backup rotation;
- explicit future-schema refusal;
- strict integer types;
- Daily task persistence;
- real app/bootstrap SaveService lifecycle;
- full strict adversarial recovery matrix.

## 9. Context-loss recovery
If context is compacted/lost:
1. git fetch origin
2. inspect status/log
3. re-read THIS master prompt from GitHub
4. locate latest remote `CLAUDE_LOG_V02.md` files
5. locate existing `task_logs_v02/`
6. continue from first missing remediation step

Do not use scratchpad as sole durable state.

## 10. Stop rules
Do NOT stop for:
- device/owner gates explicitly listed above;
- awaiting ChatGPT audit after an intermediate V02;
- historical M33 owner F6.

Only stop BLOCKED if proceeding would destroy owner work, require a missing secret/unauthorized service, or create an unresolved canonical-mechanics decision not covered by owner locks.

## 11. Final batch handoff
After M40 V02 is pushed and remote-verified, stop production work and return:
- M34..M40 V02 implementation/log commit SHAs;
- direct GitHub URL for every `CLAUDE_LOG_V02.md`;
- list of remaining OWNER_REQUIRED / DEVICE_REQUIRED gates;
- confirmation root TASKS.md untouched;
- confirmation no M41+ work started.

Final line:
`AWAITING_AUDIT / M34-M40 REMEDIATION BATCH V02 COMPLETE`
