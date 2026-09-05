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
| AL-007 | Historical DIRTY/CLEAN visual gate — SUPERSEDED | Earlier audits correctly kept final DIRTY treatment owner-controlled. On 2026-09-05 the owner replaced that model entirely. | Preserve as historical evidence only; current canonical gameplay follows AL-027. | M06/M10 design gate; superseded by owner decision META-C004 |
| AL-008 | Metadata provenance | Unknown metadata must not be inferred merely because a related file exists. | Original filename, dimensions, difficulty, approval, provenance, and similar fields require repository/owner evidence; otherwise keep them null/unverified. | https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M07-C001/CHATGPT_AUDIT_V01.md |
| AL-009 | Validation traceability | A green aggregate test total does not prove that every prompt-required validation step ran. | Record every prompt-mandated command/check individually in `CLAUDE_IMPLEMENTATION_LOG.md`, including smoke/status checks and failures. | https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M07-C001/CHATGPT_AUDIT_V01.md |
| AL-010 | Import/export path safety | Source and derived-output paths can alias even when filenames look different syntactically. | Canonicalize path identity before writes; reject source↔destination and destination↔destination aliases. An overwrite flag must never authorize source destruction. | https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M09-C001/CHATGPT_AUDIT_V01.md |
| AL-011 | Negative-test specificity | A negative test must isolate the failure mode it claims to verify. | Use inputs that specifically exercise the claimed failure; do not let an unrelated earlier error make the test green. | https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M09-C001/CHATGPT_AUDIT_V01.md |
| AL-012 | Multi-artifact overwrite safety | Safe overwrite behavior must apply to every generated artifact, not only the primary output. | Test Level JSON, preview, metadata, caches/sidecars individually for existing-file behavior and cross-artifact collisions. | https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M09-C001/CHATGPT_AUDIT_V01.md |
| AL-013 | Filesystem identity normalization | Cosmetic path normalization is not enough for destructive-write safety. Dot segments and relative-vs-absolute equivalents can identify the same physical file. | Before alias comparison, resolve one explicit base, simplify `.`/`..`, normalize separators and platform case rules, then test equivalent syntactic paths directly. Fail closed when identity cannot be safely established. | https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M09-C001/CHATGPT_AUDIT_V02.md |
| AL-014 | Batch preflight fidelity | A dry-run is only a valid whole-batch preflight if it checks deterministic filesystem preconditions that can be known before writing. Test setup must not mask a predictable commit failure. | Validate destination parent existence/type before commit; include a failing-later-item case that proves earlier items remain unwritten. | https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M09-C002/CHATGPT_AUDIT_V01.md |
| AL-015 | Catalog integrity / ownership | Catalog validation must fail closed and protect both directions of ownership: declared ID -> canonical path and canonical path -> declared ID. | Invalid catalog roots, malformed entries and duplicate IDs must invalidate validation; `overwrite=true` must never let a different ID take over an existing catalog path. | https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M09-C002/CHATGPT_AUDIT_V01.md |
| AL-016 | Manifest schema safety | Optional JSON fields are part of the schema and must be type-validated before typed use. | Wrong optional types return actionable validation errors without runtime type faults or writes. | https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M09-C002/CHATGPT_AUDIT_V01.md |\n| AL-017 | Destination object-type preflight | Checking only a destination's parent is insufficient for whole-batch logical preflight. The final target itself can already be an incompatible filesystem object such as a directory. | Resolve every final destination before commit; reject an existing directory target for output/preview/metadata, including overwrite=true, and prove a failing later item leaves earlier outputs unwritten. | https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M09-C002/CHATGPT_AUDIT_V02.md |

| AL-018 | Regression-test observability | A test must directly observe the subsystem/property it claims to verify. Proxy assertions on adjacent state can stay green after the target behavior regresses. | Design negative/regression tests so removing or breaking the target behavior makes the test fail; for presentation bindings, observe real renderer output or another authoritative behavior rather than only session state/geometry. | https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M11-C001/CHATGPT_AUDIT_V01.md |

| AL-019 | Coordination evidence mapping | Prompt-scoped implementation evidence must be version-addressable. | Require `CHATGPT_PROMPT_VNN.md -> CLAUDE_LOG_VNN.md`; verify the matching GitHub log before auditing a prompt version. | https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M11-C001/CHATGPT_AUDIT_V04.md |

| AL-020 | Encapsulation / validated state ownership | Validation at a manager/system boundary is ineffective if public query APIs leak mutable references to internally owned state. | Test the bypass path directly; callers must not be able to mutate validated internal truth outside the owning system's validated mutation path. | https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M12-C001/CHATGPT_AUDIT_V01.md |

| AL-021 | Derived progress counting | Task progress must be computed from unique canonical SB task IDs, not approximate task-line counts or stale branch baselines. | Compare canonical ID sets across branches before migration/merge; report branch-specific totals when a feature branch adds tasks. | https://github.com/Sekiph82/Scrubbots/blob/feature/master-ui-magnific-pipeline/coordination/sessions/META-C002/CHATGPT_AUDIT_V01.md |
| AL-022 | Visual reference intake truth | Copying owner references into the repo is not enough if machine-readable inventory/availability still says the categories are missing. | After intake, persist per-file provenance/hash/dimensions/classification and reconcile category availability, manifest state and tasks.md without promoting reference/external art to production-original status. | https://github.com/Sekiph82/Scrubbots/blob/feature/master-ui-magnific-pipeline/coordination/sessions/META-C002/CHATGPT_AUDIT_V01.md |

| AL-023 | PR summary truth | A truthful follow-up PR comment does not fully cure a materially stale PR body when the body still describes completed migration/intake work as pending. | Before merge, refresh the PR body to current implementation, validation, blockers and progress truth. | https://github.com/Sekiph82/Scrubbots/blob/feature/master-ui-magnific-pipeline/coordination/sessions/META-C002/CHATGPT_AUDIT_V02.md |

| AL-024 | Commit/push provenance | Saying “commit pushed” without the actual full commit SHA and final remote-head SHA is insufficient when a prompt explicitly requires version-addressable Git evidence. | Record concrete SHAs only after they exist; if log finalization creates another commit, record the chain and final remote head. | https://github.com/Sekiph82/Scrubbots/blob/feature/master-ui-magnific-pipeline/coordination/sessions/META-C002/CHATGPT_AUDIT_V03.md |

| AL-025 | Self-referential Git evidence | A Git-tracked evidence file cannot stably contain the SHA of the final commit that contains that same file; writing the SHA changes the commit. | Keep pre-commit evidence in CLAUDE_LOG_VNN. Put exact post-push final SHA/remote-head/status in a non-Git-mutating GitHub receipt, then independently verify it. | https://github.com/Sekiph82/Scrubbots/blob/feature/master-ui-magnific-pipeline/coordination/sessions/META-C002/CHATGPT_AUDIT_V04.md |

| AL-026 | Local owner-work preservation | A pre-existing tracked modification/deletion is owner/local work until proven otherwise; restoring it from origin merely to get a clean tree can erase owner intent. | Record and preserve pre-existing tracked/untracked changes; never git-restore/reset them for cleanliness. If they block safe sync/work, fail closed as BLOCKED. | https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M13-C001/CHATGPT_AUDIT_V01.md |

| AL-027 | ACTIVE/CLEARED owner rule | The owner replaced the DIRTY/CLEAN/grime/reveal model: artwork cells start ACTIVE at original palette color; successful cleaning makes them CLEARED alpha-0 so gameplay background shows through. | Current canonical code/docs/tasks must use ACTIVE/CLEARED; no DirtyCleanPresets/A-B-C layer. Historical logs stay unchanged. | META-C004 owner decision, 2026-09-05 |
| AL-028 | Color candidate != reachable target | A matching-color ACTIVE cell can still be blocked by surrounding ACTIVE cells. Raw color membership must not be called final eligibility. | M13 indexes raw color candidates only. Final dispatch requires valid + ACTIVE + matching + unreserved + reachable. ACTIVE non-target cells block access; CLEARED/background space opens it. Preserve TargetSelector/RoutingSystem separation. | META-C004 owner decision, 2026-09-05 |

| AL-029 | Semantic migration completeness | Identifier-only grep can miss contradictory conceptual language and required future task sections. | For gameplay-rule migrations, scan both identifiers and semantic synonyms, and explicitly reconcile every prompt-named task section. | https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/META-C004/CHATGPT_AUDIT_V01.md |
| AL-030 | Evidence reference existence | A log statement such as "receipt below" is not evidence if the referenced artifact is absent. | Independently verify every claimed receipt/comment/file exists. Post-push exact SHA evidence belongs in a real non-Git-mutating receipt per AL-025. | https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/META-C004/CHATGPT_AUDIT_V01.md |

## Audit history

| Cycle | ChatGPT audit | Final/current state | Reusable learning |
| --- | --- | --- | --- |
| META-C001 | https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/META-C001/CHATGPT_AUDIT_V01.md | `AUDITED_PASS` | Coordination evidence chain established. |
| M07-C001 | V01: https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M07-C001/CHATGPT_AUDIT_V01.md; V02: https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M07-C001/CHATGPT_AUDIT_V02.md | `AUDITED_PASS` | V01 added AL-008/009; V02 closed the findings. |
| M09-C001 | V01: https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M09-C001/CHATGPT_AUDIT_V01.md; V02: https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M09-C001/CHATGPT_AUDIT_V02.md; V03: https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M09-C001/CHATGPT_AUDIT_V03.md | `AUDITED_PASS` | V01 added AL-010..012; V02 added AL-013; V03 closed filesystem-identity correction. |
| M09-C002 | V01: https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M09-C002/CHATGPT_AUDIT_V01.md; V02: https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M09-C002/CHATGPT_AUDIT_V02.md; V03: https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M09-C002/CHATGPT_AUDIT_V03.md | `AUDITED_PASS` | V01 added AL-014..016; V02 added AL-017; V03 independently verified destination-object-type preflight and closed M09-C002. |

| M11-C001 | V01: https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M11-C001/CHATGPT_AUDIT_V01.md; V02: https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M11-C001/CHATGPT_AUDIT_V02.md; V03: https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M11-C001/CHATGPT_AUDIT_V03.md; V04: https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M11-C001/CHATGPT_AUDIT_V04.md | `AUDITED_PASS` | V03 closed F-M11-001 with direct renderer observability. V04 normalized versioned evidence and added AL-019. |

| M12-C001 | V01: https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M12-C001/CHATGPT_AUDIT_V01.md; V02: https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M12-C001/CHATGPT_AUDIT_V02.md | `AUDITED_PASS` | V01 added AL-020; V02 verified encapsulation correction and closed M12. |

| META-C002 | V01: https://github.com/Sekiph82/Scrubbots/blob/feature/master-ui-magnific-pipeline/coordination/sessions/META-C002/CHATGPT_AUDIT_V01.md; V02: https://github.com/Sekiph82/Scrubbots/blob/feature/master-ui-magnific-pipeline/coordination/sessions/META-C002/CHATGPT_AUDIT_V02.md; V03: https://github.com/Sekiph82/Scrubbots/blob/feature/master-ui-magnific-pipeline/coordination/sessions/META-C002/CHATGPT_AUDIT_V03.md; V04: https://github.com/Sekiph82/Scrubbots/blob/feature/master-ui-magnific-pipeline/coordination/sessions/META-C002/CHATGPT_AUDIT_V04.md; V05: https://github.com/Sekiph82/Scrubbots/blob/feature/master-ui-magnific-pipeline/coordination/sessions/META-C002/CHATGPT_AUDIT_V05.md | `AUDITED_PASS` | Final V05 verified AL-025 external receipt; PR #3 authorized for controlled merge cycle META-C003. |

| META-C003 | V01: https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/META-C003/CHATGPT_AUDIT_V01.md | `AUDITED_PASS` | Controlled merge + canonical-main reconciliation accepted; AL-025 receipt pattern validated for merge cycles. |

| M13-C001 | V01: https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M13-C001/CHATGPT_AUDIT_V01.md; V02: https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M13-C001/CHATGPT_AUDIT_V02.md | `AUDITED_PASS` | V01 added AL-026 and reopened scan observability/remaining formal scope; V02 closes findings and completes M13. |

| META-C004 | V01: https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/META-C004/CHATGPT_AUDIT_V01.md; V02: https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/META-C004/CHATGPT_AUDIT_V02.md | `AUDITED_PASS` | V01 accepted core migration and added AL-029/030; V02 closes M48/Project Brief/receipt findings. ACTIVE/CLEARED final canonical truth. |

## Claude usage rule

Before implementing/testing a new prompt, Claude must:

1. read the prior ChatGPT audit URL(s) explicitly listed by the active prompt;
2. read this index;
3. identify relevant `AL-XXX` items;
4. record in the matching `CLAUDE_LOG_VNN.md` how those findings changed implementation or testing;
5. run and log the checks required by the active prompt;
6. stop at `AWAITING_AUDIT` when ready for ChatGPT review.

Claude does not create a self-audit file and does not assign audit verdicts.

## Update rules

- ChatGPT updates this index after an independent audit when a finding should affect future prompts/tests.
- Do not delete old learnings simply because a later test passes. Supersede them explicitly with a newer audit reference if project truth changes.
- New ChatGPT prompt versions should reference relevant `AL-XXX` items when prior findings materially affect implementation or verification.
- Historical Claude self-audit artifacts, if any, are not audit sources and are not listed here as proof.
