# SB-CP05-R01-001 | Failed Multi-Pack Transaction Cleanup | Remediation V01
Status: AUTHORIZED FOR CLAUDE
Date: 2026-10-07
Repository: Sekiph82/Scrubbots
Owner-local: C:/Users/sekip/Desktop/ScrubBots
Current implementation: e8662583fe24e9edf17ca595e45d34df778ada75
Source audit: coordination/sessions/REMOTE-CONTENT-RUNTIME-V01/CHATGPT_INDEPENDENT_AUDIT_V01.md

## Scope
Fix exactly one blocker: when a candidate manifest contains multiple new packs, RemoteContentManager._download_and_stage() renames every verified pack into final packs/<id>/<version>-<sha>/ before registry activation. If a later pack fails, refresh() removes staging and .part but leaves earlier unreferenced candidate packs installed until a later boot. Same-transaction cleanup is mandatory.

## Preflight
Inspect branch, git status, HEAD, origin/main, ahead/behind, untracked/owner-local edits. Work directly in C:/Users/sekip/Desktop/ScrubBots when accessible. If your cloud session cannot access it, explicitly say so and preserve a clean clone; never claim to have synced the Windows checkout. Preserve project.godot, scenes/app/main.tscn, addons/, .mcp.json, unrelated untracked/local changes and all owner settings. Never reset --hard, git clean, force checkout/push, drop stashes or overwrite owner files. Preserve BOTH e866258 runtime implementation and newer ChatGPT audit/prompt/TASKS.md changes on main by safe non-destructive merge. Stop and report genuine conflicts. Root TASKS.md is READ ONLY for Claude.

## Product fix
Either track exactly which new/final pack directories belong to this refresh and remove only those unreferenced candidate directories on any pre-activation failure, OR hold all candidates in staging until the full validated set is ready and use an equivalent recoverable finalization boundary. Do not delete a pack referenced by the previous active/LKG registry. Reused exact-identity active pack is never transaction-owned. Rollback must be idempotent and run for download failure, SHA mismatch, schema/ZIP validation failure, install failure, candidate verification failure and registry write/activation failure. Candidate registry must remain unchanged on failure. Never blanket-delete packs/. Constrain all deletion to the content root. On success, activate once, preserve cache reuse/dedup and prune safely.

Keep the existing declarative-only V1 manifests/scrubpacks, SHA validation, HTTPS-only transport, built-in 1-10, append-only remote sequence, gameplay catalog, progression, save and economy contracts unchanged.

## Permanent adversarial tests
1. An active N with verified pack A, candidate N+1 with A plus new B and C. B verifies/installs and C fails hash or malformed ZIP. Immediately after refresh failure WITHOUT REBOOT: byte-identical active registry and A, no installed final B/C, no txn staging/part, and LKG still playable.
2. No active remote registry, two new packs: first verifies, second fails. After failure no candidate pack, registry, staging or .part remains; built-in gameplay works.
3. Exact reused active pack survives cleanup with its hashes and level/supply content unchanged.
4. A valid retry activates once; no redundant download or ghost directories.
5. Candidate verification or registry activation failure preserves previous LKG and immediately cleans candidate final paths.
6. Cold boot after interruption retains LKG and removes orphan work without accepting unverified payloads.

Use injected deterministic FakeTransport and synthetic fixtures. Never touch the user's real user://content/ or a live CDN.

## Regression and governance
Run CP04 suite, CP05 suite, family fixture, M35/M37/M40/M52/M43 and m53_first10, root tests/run_tests.gd, git diff --check; report actual checks and failures. Do not remove/loosen existing tests. The standalone m53_c002_difficulty_calibration failure exists already at untouched e36e023: report it accurately, do not fix it in this R01 and do not claim it passes. It has a separate M53 remediation.

Do not change app artwork, production endpoint configuration, Android export, LF publisher, root TASKS.md or unrelated product code.

## Handoff
Write coordination/sessions/REMOTE-CONTENT-RUNTIME-V01/SB-CP05-R01-001_CLAUDE_LOG_V01.md. Include sync truth, root cause, rollback ownership model, failure-path results, new tests, regressions, exact SHA/ahead-behind and known M53 baseline exception. Push to the authorized branch. Finish with exactly:
AWAITING_GPT_CP05_R01_TRANSACTION_CLEANUP_AUDIT
