---
coordinationSchema: scrubbots-coordination/v2
artifactType: chatgpt-audit-criteria
cycleId: M07-C001
version: 1
createdAt: 2026-08-27T12:03:00+03:00
actor: CHATGPT
status: ACTIVE
milestone: M07
taskRefs:
  - SB-M07-001
  - SB-M07-002
  - SB-M07-003
  - SB-M07-004
  - SB-M07-005
  - SB-M07-006
  - SB-M07-007
  - SB-M07-008
  - SB-M07-009
  - SB-M07-010
  - SB-M07-011
  - SB-M07-012
  - SB-M07-013
  - SB-M07-014
  - SB-M07-015
  - SB-M07-016
  - SB-M07-017
---

# M07-C001 - ChatGPT Independent Audit Criteria V01

This file defines the comparison criteria ChatGPT will use when auditing Claude's M07-C001 implementation. Claude must read these criteria before implementation and again before self-audit.

Audit policy:
https://github.com/Sekiph82/Scrubbots/blob/main/coordination/AUDIT_POLICY.md

Audit learning index:
https://github.com/Sekiph82/Scrubbots/blob/main/coordination/AUDIT_INDEX.md

Active prompt authority:
https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M07-C001/CHATGPT_PROMPT_V03.md

## Independence rule

Claude's own successful tests will be treated as provisional `SELF_PASS` evidence only. ChatGPT will independently inspect repository state, diffs, manifests, task truth, test design, and reproducible evidence before assigning `AUDITED_PASS`.

A green aggregate test count alone cannot satisfy a requirement if the underlying requirement-specific evidence is missing or contradictory.

## Audit learning baseline

Claude must apply at least these relevant learnings from `AUDIT_INDEX.md`:

- `AL-005`: file existence is not task-completion evidence.
- `AL-006`: missing owner artwork cannot be fabricated or guessed into existence.
- `AL-007`: the M10 DIRTY/CLEAN final choice remains owner-controlled.

Also apply any other `AL-XXX` learning that becomes relevant to files/systems touched during implementation.

## Requirement comparison matrix

### AC-M07-001 - Repository-only asset availability audit

`AUDITED_PASS` when:

- the implementation inventories only verifiable repository assets or explicitly documented missing categories;
- arbitrary Desktop/external images are not ingested;
- ambiguous files are marked unverified rather than owner-approved;
- Akilta branding is not classified as SCRUBBOTS gameplay/reference art.

`AUDITED_FAIL` when any unverified/ambiguous/external asset is silently classified as canonical SCRUBBOTS art or an absent owner asset is represented as physically present.

### AC-M07-002 - Reference directory structure

`AUDITED_PASS` when the intended reference/production-source directory structure exists coherently and no verified source original was destructively moved or renamed merely for style.

`AUDITED_FAIL` when the structure conflates original SCRUBBOTS assets with external inspiration or modifies source originals destructively.

### AC-M07-003 - Human-readable reference guide

`AUDITED_PASS` when the guide clearly defines:

- authority hierarchy;
- source classes;
- approval and availability semantics;
- stable naming/ID rules;
- source-original preservation;
- intake process;
- external-inspiration limits;
- M08 technical-audit boundary;
- M10 owner design gate.

`AUDITED_FAIL` if any of these core semantics are missing or if the guide allows generated/guessed assets to masquerade as originals.

### AC-M07-004 - Machine-readable inventory integrity

`AUDITED_PASS` when the manifest/inventory is syntactically valid, deterministic enough for future tooling, and distinguishes:

- verified physical assets;
- expected-but-missing owner assets;
- external inspiration;
- non-gameplay branding.

Missing assets must use null/explicit missing paths rather than fake paths. Unknown dimensions/difficulty must remain unknown rather than invented.

`AUDITED_FAIL` when the file is invalid, contradictory, fabricates missing metadata, or conflates source classes.

Independent check should include parsing the manifest with an available built-in tool/runtime, not just visually inspecting the file.

### AC-M07-005 - Owner-asset preservation

`AUDITED_PASS` when the documented policy makes owner originals immutable source artifacts and future derived outputs separate files.

`AUDITED_FAIL` when resizing, palette conversion, preview generation, or gameplay conversion is permitted to overwrite the original source in place.

### AC-M07-006 - External inspiration isolation

`AUDITED_PASS` when external inspiration is kept separate and Colony Flow is described only as broad movement-flow inspiration with no copied asset adoption.

`AUDITED_FAIL` when external art/UI/characters/compositions are treated as SCRUBBOTS production references or downloaded/committed as part of this cycle without explicit owner authorization.

### AC-M07-007 - Missing owner assets remain missing

`AUDITED_PASS` when missing categories are explicitly represented as `AWAITING OWNER ASSET` or the exact established equivalent.

At minimum compare character, gameplay-screen, five-slot, level, underwater level, other theme, and pixel-construction reference categories.

`AUDITED_FAIL` when placeholders or generated descriptions are used to complete owner-asset inventory tasks.

### AC-M07-008 - tasks.md truth

`AUDITED_PASS` when only actually implemented/validated M07 infrastructure tasks are checked off.

If required owner files remain absent, SB-M07-008 through SB-M07-014 must remain open with truthful waiting notes unless actual verified repository evidence proves otherwise.

`AUDITED_FAIL` when task state overstates completion or unfinished tasks are deleted/hidden.

### AC-M07-009 - DIRTY/CLEAN gate integrity

`AUDITED_PASS` when the reference guide preserves the current visual rule and M10 remains owner-controlled.

`AUDITED_FAIL` when Claude chooses a final A/B/C preset or marks M10 complete/approved without owner action.

### AC-M07-010 - Scope integrity

`AUDITED_PASS` when the cycle stays within M07 reference-library infrastructure and availability audit.

`AUDITED_FAIL` for unrequested M08 full pixel audit, M09 importer work, source resampling, gameplay/routing/slots/agent implementation, or unrelated redesign.

### AC-M07-011 - Regression verification

Claude must run and record, when available:

- `godot --version`
- `powershell -File tools\verify_project.ps1`
- `godot --headless --path . --quit-after 5`
- `godot --headless --path . -s res://tests/run_tests.gd`
- `git diff --check`
- `git status --short`

Claude classifications remain `SELF_PASS`/`SELF_FAIL` etc.

ChatGPT will compare claimed results with repository/test evidence and independently rerun or cross-check what accessible tooling permits.

`AUDITED_FAIL` if Claude claims commands ran when logs/evidence contradict that, suppresses failures, or alters tests merely to hide a regression.

`NOT_INDEPENDENTLY_VERIFIED` may be used when independent execution is unavailable but reproducible Claude evidence exists.

### AC-M07-012 - Self-audit quality

`AUDITED_PASS` when Claude creates:

https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M07-C001/CLAUDE_SELF_AUDIT_V01.md

and the self-audit:

- cites applied `AL-XXX` learnings;
- maps every material requirement to expected result and explicit failure condition;
- includes negative/boundary/integrity checks where applicable;
- analyzes false-positive risk;
- lists untested assumptions;
- compares current observations against prior audited baseline/learned rules;
- never calls its own result `AUDITED_PASS`.

`AUDITED_FAIL` when self-audit is merely a restatement of implementation prose or treats the implementer's own tests as independent proof.

### AC-M07-013 - Coordination/H!veAI synchronization

`AUDITED_PASS` when Claude updates:

- implementation log;
- Claude self-audit;
- `coordination/SESSION_INDEX.md`;
- `.hiveai/PROJECT_DASHBOARD.md`;

and uses absolute GitHub URLs for GitHub-tracked evidence.

`AUDITED_FAIL` when the cycle is handed back without durable evidence/synchronization or historical ChatGPT prompt/audit files are rewritten.

### AC-M07-014 - Git integrity

`AUDITED_PASS` when no Desktop phase log, secrets, `.godot/`, arbitrary Desktop images, generated build output, or unverified external art is committed.

`AUDITED_FAIL` if such files are committed or destructive Git operations were used without owner authorization.

## Final cycle decision rule

`AUDITED_PASS` requires all critical M07-C001 requirements above to be either:

- `AUDITED_PASS`; or
- intentionally `OWNER_REQUIRED` / outside this cycle's completion scope, as explicitly allowed by the prompt.

Any critical `AUDITED_FAIL` produces `CHANGES_REQUIRED` unless the issue is externally blocked.

Claude-only `SELF_PASS` is never sufficient by itself for the final cycle decision.
