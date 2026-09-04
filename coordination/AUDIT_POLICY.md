# SCRUBBOTS Audit Policy

Canonical repository: https://github.com/Sekiph82/Scrubbots

This policy defines the separation between Claude implementation/testing and ChatGPT independent auditing.

## Core ownership rule

Claude is the implementer and test runner.

ChatGPT is the auditor.

Claude must **not** create audit files, self-audit files, audit verdicts, or `AUDITED_*` statuses.

Claude's job is to:

1. implement the active ChatGPT prompt;
2. run the required tests/checks while implementing;
3. record exact commands, expected outcomes, failure conditions, actual results, failures/fixes, and relevant comparison notes in `CLAUDE_IMPLEMENTATION_LOG.md`;
4. update task/dashboard/session state truthfully;
5. hand the cycle back as `AWAITING_AUDIT`.

ChatGPT then independently reviews the repository and publishes `CHATGPT_AUDIT_VNN.md`.

## Evidence levels

### E0 - Claim or assumption

Examples:

- a file exists;
- Claude says a feature is done;
- a test was expected to pass but was not run.

E0 cannot establish an audit PASS.

### E1 - Claude-run implementation test

Claude actually ran a command/check and recorded the result in the implementation log.

This is useful implementation evidence, but it is not independent audit proof.

Use implementation-log labels such as:

- `CLAUDE_TEST_PASS`
- `CLAUDE_TEST_FAIL`
- `NOT_RUN`
- `BLOCKED`
- `OWNER_REQUIRED`

These labels describe Claude's test execution only. They are not audit verdicts.

### E2 - Reproducible Claude evidence

Claude records enough detail for ChatGPT to evaluate or reproduce the check:

- exact command/check;
- commit/tree state;
- expected outcome;
- explicit failure condition;
- actual result;
- affected requirement/task;
- relevant GitHub evidence URL.

E2 is strong implementer evidence, but remains non-independent.

### E3 - ChatGPT independent audit evidence

ChatGPT inspects actual GitHub state, diffs, files, tasks, logs, tests, and reproducible evidence. Where accessible, ChatGPT independently reruns or cross-checks relevant checks.

Only ChatGPT audit files may assign:

- `AUDITED_PASS`
- `AUDITED_FAIL`
- `NOT_INDEPENDENTLY_VERIFIED`
- `BLOCKED`
- `OWNER_REQUIRED`

### E4 - Owner approval

Human-controlled product/design gates remain `OWNER_REQUIRED` until the owner explicitly decides them.

AI implementation or testing cannot close an owner gate.

## Claude verification responsibilities

Before implementation/testing, Claude must read:

- the active ChatGPT prompt;
- every prior `CHATGPT_AUDIT_VNN.md` that the prompt identifies as relevant;
- https://github.com/Sekiph82/Scrubbots/blob/main/coordination/AUDIT_INDEX.md
- any cycle-specific `CHATGPT_AUDIT_CRITERIA_VNN.md` published by ChatGPT.

Claude must use prior audit findings as a **test-planning input**. This means:

- previously found failure modes should get explicit regression checks;
- previously missed boundary/negative cases should be added where relevant;
- previously invalid tolerances/assumptions must not be repeated;
- audit learnings (`AL-XXX`) relevant to the touched system must be cited in the implementation log;
- when a prior audit changed what counts as success/failure, Claude must update its test expectations accordingly.

All of this stays inside the implementation log. Claude does not create a second audit document.

## Claude implementation log requirements

Each material implementation pass must append to:

`coordination/sessions/<CYCLE_ID>/CLAUDE_IMPLEMENTATION_LOG.md`

Canonical URL pattern:

`https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/<CYCLE_ID>/CLAUDE_IMPLEMENTATION_LOG.md`

The log must record:

- active prompt URL;
- prior ChatGPT audit URLs read;
- relevant `AL-XXX` learnings applied;
- implementation changes;
- tests/checks run;
- expected outcome and explicit failure condition for material checks;
- actual result;
- negative/boundary/regression coverage when relevant;
- false-positive risks noticed;
- failures and fixes;
- performance evidence only when actually measured;
- task/doc changes;
- commit/push evidence;
- blockers/unverified assumptions.

A prompt-mandated validation command must be individually recorded. An aggregate green test count does not substitute for an omitted required command.

## ChatGPT audit responsibilities

After Claude hands a cycle back as `AWAITING_AUDIT`, ChatGPT creates:

`coordination/sessions/<CYCLE_ID>/CHATGPT_AUDIT_VNN.md`

Each ChatGPT audit must:

1. read the active prompt and any inherited prompt scope;
2. read the Claude implementation log;
3. inspect actual GitHub commits/diffs/files/tasks;
4. compare implementation against prompt requirements and locked project rules;
5. treat Claude-run tests as implementation evidence, not independent proof;
6. independently rerun/cross-check checks where accessible;
7. explicitly state when a claimed result was not independently rerun;
8. inspect test quality and false-positive risk where relevant;
9. publish exact findings and corrections when status is `CHANGES_REQUIRED`;
10. update `AUDIT_INDEX.md` with reusable findings;
11. update `SESSION_INDEX.md` and the H!veAI dashboard.

## Continuous audit learning

`coordination/AUDIT_INDEX.md` is ChatGPT-owned repository audit memory.

The feedback loop is:

`ChatGPT audit finding -> AUDIT_INDEX learning -> next ChatGPT prompt -> Claude implementation/test plan -> Claude implementation log -> next ChatGPT audit`

Claude reads and applies the learnings. ChatGPT owns and updates the audit conclusions.

## Historical Claude self-audit files

`CLAUDE_SELF_AUDIT_*` files created before this policy correction are historical artifacts only.

They are not required inputs for future work and are not independent audit evidence.

Do not create new Claude self-audit files.

## Existing high-value verification lessons

1. Preserve explicit `preload()` behavior for the headless-sensitive core unless a deliberate task proves a replacement.
2. Renderer RGBA8 readback requires tolerant/property-based color checks rather than brittle exact float equality.
3. Headless CPU timing is not rendered GPU/FPS evidence.
4. Variable-size systems require rectangular and relevant maximum-size coverage, not square-only tests.
5. Production maximum is currently 59x59 = 3,481 logical cells.
6. File existence alone is not task-completion evidence.
7. Missing owner artwork remains `AWAITING OWNER ASSET`; never fabricate substitutes.
8. M10 DIRTY/CLEAN final visual choice remains owner-controlled.


## Coordination v4 evidence matching [LOCKED]

The active prompt version determines the expected Claude evidence file:

`CHATGPT_PROMPT_VNN.md -> CLAUDE_LOG_VNN.md`.

ChatGPT must verify that exact log exists and corresponds to that prompt before
assigning an independent audit verdict. Claude-run tests remain E1/E2 evidence.

Historical combined `CLAUDE_IMPLEMENTATION_LOG.md` files remain legacy
evidence only.

H!veAI derived tracking files are ACTIVE_CYCLES.md, ARTIFACT_MAP.md, and
PROGRESS_SNAPSHOT.md under `.hiveai/`; they do not replace `tasks.md`.
