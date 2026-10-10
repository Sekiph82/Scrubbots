# CP06-GAME-DISABLED-LEVELS-C001 — ChatGPT Strict Audit Criteria V02 (Owner Option B)
Date: 2026-10-10. Auditor / root TASKS.md: ChatGPT. Implementer: Claude Code.
Owner B record: `OWNER_DISABLED_FRONTIER_DECISION_V02.md`.
Builder source: `CHATGPT_PROMPT_V02.md`. Expected log: `CLAUDE_LOG_V02.md`.

## G0 Owner policy and local-safety hard gate
- Confirm owner chose B nonrewarding SKIP, no A wait/C content replacement and NO fake first-clear.
- ONLY local checkout `C:\Users\sekip\Desktop\ScrubBots`. **Absolutely zero local TEMP files or folders of any size, zero new worktrees/clone/scratch/staging copies, no local tests writing under user:// outside Desktop**. Source diff/log should identify each executed command, created file and absence of any task-generated TEMP. Preserve owner-dirty tracked/untracked/stashes; safe ff sync, normal non-force push, ChatGPT owns root TASKS.md.
- No new APK/IPA, real R2 mutation, LF source edits, production data/art edits, provider SDK or paid service. No repeat of already-audited M55.
- Any test run absent due TEMP prohibition must be explicitly marked **NOT_RUN**, never PASS. Old CI cp04 c24 28/28 is baseline against pre-B runtime, not proof of new code.

## A Canonical option B game mechanics
- Exact active validated remote `disabled_levels` ID triggers an explicit skip at its correct numeric frontier. Level12 → Level13 (actual display ID stays 13); no catalog filtering or order compaction, no debug frontier seam, no `record_win` for skip.
- Skip **neither win nor loss**: zero WON/Results, zero economy/Hearts/SB/Card/Robot/Booster/Daily/achievement/score/streak-reward grants; existing win-streak unchanged (neither increment/reset). User-facing status truthful/no false win or fake content.
- Multiple consecutive disabled remote levels advance monotonically only while each actual frontier is explicitly disabled by same validated active version; deterministic bound at number of declared remote levels. Missing or corrupt packs, offline without usable cached registry, unknown/disabled builtin, unreconciled content do NOT permit automatic skip.
- Re-enable successor respects immutable history: prior skipped player continues forward without rewinding or retrospective payouts; yet-unreached player can play reenabled ID. No level select or replay feature invented.

## B Save migration, idempotency and authority
- Versioned canonical save/progression contract and migration: existing V1 snapshots load exactly with `skipped=[]`, preserving original `completed`, frontier, all economy/settings. New history has disjoint first-clear `completed` and documented `skipped`; union exactly fills 1..current_level-1; strict exact ints/no duplicates/no gaps/future entries.
- Skipped record binds exact stable level ID, numeric order, active manifest content_version and manifest SHA/provenance; must not allow user-forged or manifest-inconsistent skip records. Future-schema/corrupt saves fail closed, backup restore path still atomic and no default account wipes or economy re-grants. Eventual offline import of already recorded, legitimate skips remains possible without needing a live network call.
- A skipped frontier is persisted durably and *only* then exposed as successful advancement. Save failure rolls back in-memory state and retained previous save. Crash between cached manifest activation and skip-save is recoverable/idempotent without reward or duplicate skips. Duplicate dispatch or restart after save does not skip further unless next frontier independently disabled.
- No second progression authority. `completed_count()` remains win count, not completed+skipped total. Win streak and any reward/achievement task counters count real wins only. Current save backup and future schema guards retained.

## C Remote-content contract / offline LKG
- Only disabled IDs from declared remote manifest levels are accepted, exact IDs with case collision/builtin/unknown failure, appending/reordering order law preserved. `schedules != []` remains fail-closed, independent from B.
- Registry schema evolves compatibly: old LKG registry V1 parsed with empty disabled set, successor stores versioned exact disabled set atomically. No partial / corrupted new registry activation, no release version decrease/equal-version mutation, no pack/hash/content change, no fake manifest URL/key.
- Reenable version N+2 supports fresh player and old skip ledger; cold offline boot retrieves verified N+1 disabled state and does not lose progression. Failed write, network, malformed manifest, hash mismatch or incompatible version leaves prior content and save untouched. Builtin Levels 1–10 unaffected.
- Remote release remains declarative, no executable content.

## D Tests and evidence
- Required negative tests **in source**: disabled remote 12 and adjacent 11/13, two consecutive disabled IDs, no win/economy/streak mutation; V1→V2 migration; duplicate invalid skips/gaps/overlap/case, future-schema, corrupt/missing save and explicit simulated save failure rollback; cold offline LKG/re-enable; missing pack must block not skip; schedule remains blocked. Pure in-memory tests run locally only if file-write-free can be established.
- Full executable CP04+CP05, M35/M37/M40/M55, new CP06 suite and root `run_tests.gd` **must run before independent final FULL_PASS**. However owner prohibits `user://` writing test fixtures to AppData, extra TMP, new copies and unapproved CI runs; when they cannot run, accept only **IMPLEMENTED_BUT_UNVERIFIED / BLOCKED_TEST_EXECUTION** status. Claude must name exact test commands pending; do not self-certify code based on tests written or old CI.
- `git diff --check`, exact permitted changes, owner Desktop safe parity, source SHA and log. Any crash, reward grant, silent WIN skip, schema regression or inopportune local TEMP usage = CHANGES_REQUIRED / policy violation.

## Final verdict authority
- `FULL_PASS` only after owner-compliant actual runtime tests and independent source/result review; not achievable by GitHub source review alone when disk tests are not executed.
- `IMPLEMENTED_PENDING_VALIDATION` if code is scoped and source-auditable but necessary on-disk tests not run due the owner TEMP restriction. Still keep CP06-004/010 OPEN and no new online release.
- `BLOCKED` if safe code cannot be created without violating Desktop-only rule; no forced release.
- Audit and TASKS.md ONLY by ChatGPT.
