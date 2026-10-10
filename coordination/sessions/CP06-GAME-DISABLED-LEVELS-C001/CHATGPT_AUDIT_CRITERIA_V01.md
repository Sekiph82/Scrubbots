# CP06-GAME-DISABLED-LEVELS-C001 — Strict Independent Audit Criteria V01
Date 2026-10-10. Implementation Claude Code, only ChatGPT may independently audit and update root TASKS.md.

## Gate 0: safety, scope, source of truth
- Published exact LF M17/CP06 contract and game CP04/CP05 inspected; no LF repo modifications, production/staging R2 writes, credentials, fabricated object URLs, manual live manifest creation or APK/IPA builds.
- Owner Desktop retains the four previous tracked modifications, current untracked state and stashes; before/after hashes, 0 ahead/behind after safe fast-forward; only one small task-owned sparse TEMP worktree created and removed after GitHub publication, no repeated huge local import/copies. No root TASKS.md modifications by Claude.
- Source commit and log are on origin/main and cover only clearly needed game-runtime files + synthetic tests. Existing accepted M47 IPA/APK unchanged. M55 quiescence implementation c997ca65 is retained, not redone.

## Gate A: owner authority, blocking rule
- Inspect the forward-only LevelProgressionService.record_win and save snapshot invariants before handling disabled frontier. **A silent auto-win, skipped reward payout, advancing save without clear authority, changing "Level N" presentation to play Level N+1, or using test-only debug_set_current_level in shipping code = FAIL.**
- If no approved game authority permits safe skip, exact verdict **OWNER_DECISION_REQUIRED_FOR_DISABLED_FRONTIER** is acceptable and no code should be pushed that creates new gameplay rules. Provide owner-readable minimum alternative semantics with persistence/compatibility and explicitly stop.

## Gate B: declarative disabled-level ingestion, only if Gate A cleared
- Manifest schema identical to existing ContentManifestV1; disabled_levels subset of declared remote level IDs; malformed/duplicate/unknown/builtin/case-collision rejects without mutating active registry. No new pack/level object paths; stable declared order and SHA identity; unchanged existing pack bytes. Nonempty schedules remain separate explicit unresolved gate and cannot be silently treated as enabled.
- Verified successor content_version required, atomic new active/LKG registry with disabled membership, previous LKG fallback and cold/offline boot. Failed downloads, malformed manifest, bad/stale version and crash injection do not corrupt prior registry or progression. Re-enable is explicitly versioned and previously disabled content becomes playable according to owner-approved semantics, not a silent reset.
- Disabled frontier never launches the wrong level or grants first-clear/WON, SB, Hearts, cards, robot parts, packs, daily/achievement credit. Owner-approved safe skip does not expose a level-select menu or create saved state drift.

## Gate C: test depth and output
- Dedicated synthetic single-disabled-level fixture (e.g. remote Level12) proves neighboring 11 and 13 intact in canonical identity and progression after disable; re-enable successor; cached LKG offline; malformed ids; all affected manifest/save invariants; no live network mutation.
- Focused CP04/CP05, remote_content_family_fixture, M35 catalog, M37 progression, M40 save, M55 and root run_tests PASS after code modifications; diff/parse clean. No weakening old tests or removing fail-closed guards merely to satisfy fixtures.
- Log includes exact pre/post state, contract decisions, first failing reproduction, changed-file list, all focused commands with real results, proof of no additional builds/storage, and correct GitHub/owner desktop parity. If any test fails, report BLOCKED/CHANGES_REQUIRED rather than self-award PASS.

## Gate D: independent verdict
- PASS only when source and evidence satisfy A/B/C and ChatGPT independently verifies GitHub commits/tests. If frontiers require new owner policy, record OWNER_DECISION_REQUIRED, do not mark CP06-004/010 closed.
- LF M17 CP06 final acceptance and real R2 publication remain separate, as do approved limited offline Family builds.
