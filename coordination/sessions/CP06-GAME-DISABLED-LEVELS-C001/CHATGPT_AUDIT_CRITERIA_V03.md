# CP06 C001 V03 — INDEPENDENT AUDIT CRITERIA (ONE MASTER CYCLE)
Date: 2026-10-12. Source of owner approval: "ok" to adapting EXISTING Android workflow for VALIDATION ONLY mode. Scope: existing CP06 B milestone, SB-CP06-004 and SB-CP06-010, not a new APK release.
Auditor ChatGPT alone; Claude implementer and builder log writer.

## Gate W: the ORIGINAL Android workflow, NOT a third workflow
- Compare baseline `.github/workflows/android-family-first10.yml` SHA `ac0da8cd8698c924c4a1961bd0a263cffafe8400` to latest main: ONLY minimal and correct mode-split / validation-suite changes. No new workflow file, no new `push` trigger, iOS YAML intact.
- Dispatch `choice` mode exactly `validation_only` or `build_apk`, default `validation_only`, and existing export job protected by **job-level** guard `if: inputs.mode == 'build_apk'` plus `needs: validate`. Empty/unknown input fails safe (no export); separate build_apk mode preserves original Android export behavior and protections.
- Confirm by inspecting **actual GitHub Actions run** with explicit mode=validation_only: validate job executed, export job **SKIPPED**, and absolutely NO APK/PCK/signature/inspection export artifact created. Validation-log artifact allowed, normal CI runner temp usage is remote only.
- Workflow does not silently trigger old successful Android run 38063215568 or iOS run 38063217668; these are historic SHA `c2b1c3c7`, not CP06 evidence.

## Gate T: test completeness, failure reporting
- Actual CI head SHA includes CP06 implementation `eac4c74d` (descendant) + new YAML. Real Godot 4.7.2 headless command parses changed scripts. No CP06 test is skipped due to syntax or missing assets. Detect relevant `SCRIPT ERROR`, `Parse Error`, `Failed to load script` or nonzero exit. Do not blanket-ignore script diagnostics due to unrelated known legacy image warnings.
- `tests/cp06_disabled_levels.gd` reports exact `CP06 disabled levels evidence: PASS (16/16 cases, 0 fail)` AND exit 0; check 5 pure + 11 integration fixtures. Any fewer cases, silently suppressed tests, or missing summary is FAIL.
- Updated CP04 c24 passes with disabled manifest accepted AND nonempty schedules still rejected. CP05/cache transaction, remote family fixture, M35 catalog, M37 progression, M40 save/bootstrap, M55 long-session, old M42/M43 and root `run_tests` MUST remain PASS. Real logs and exit statuses for each suite, not mere existence of file; if one fails run status must be FAIL, full diagnostics uploaded.
- New source regression fixes, if any, cannot relax Option B: real Level12 disabled -> actual Level13, no fake first clear, no reward/streak/Daily/achievement, durable idempotent skip ledger, v1 save compatibility and v2 future-schema protection, atomic rollback, cold offline LKG, reenable, missing/corrupt pack never auto-skips. Three CI runs maximum if fixes needed, all validation_only.

## Gate D: Windows Desktop zero-TEMP owner rule
- Claude touched ONLY original `C:\Users\sekip\Desktop\ScrubBots`, no new local `%TEMP%`, `/tmp`, AppData Godot user:// fixtures, clones, worktrees, second checkouts, `sed -i`/here-doc transient outputs or copied project. GitHub runner ephemeral workspace is not owner Windows PC.
- Previous four owner tracked edits, 2616 untracked files, two stashes and project.godot original SHA `d2546c0bb7d3daccce6c803252a2bf72ddd2359ee1e61abcaa02ca2b98e63574` must be preserved per Claude's read-only pre/post evidence, acknowledging ChatGPT cannot independently inspect Windows disk.
- No force push or unrelated cleanup. No new APK/IPA, R2 write, LF edit, workflow addition, paid tool or scope growth. No Claude edits to root TASKS.md, ChatGPT audit or owner decisions.

## Gate H: handoff and final disposition
- Exact GitHub final source/log SHAs, CI run IDs, validation & skipped-export job IDs/results, artifact listing and proof no APK/PCK; relevant test excerpts must be accessible; `CLAUDE_LOG_V03.md` on main and URL provided.
- **Audit PASS / CP06 child closure** only after independent GitHub readback plus CI job logs show all mandatory tests PASS (and no unexpected deployment/export). A failure or unverified CI result keeps CP06 open; record **NEEDS_REMEDIATION** or **AWAITING_OWNER_DISPATCH** without claiming closure.
- Only ChatGPT updates root `TASKS.md` after reviewing actual evidence. Do not issue NEXT-milestone master prompt before this cycle is audited.
