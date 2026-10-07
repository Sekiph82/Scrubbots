# CP04/M15 + CP05/M16 — CHATGPT INDEPENDENT STRICT AUDIT V01

Date: 2026-10-07
Repository: `Sekiph82/Scrubbots`
Audited branch: `claude/practical-darwin-ndbmxa`
Audited implementation: `e8662583fe24e9edf17ca595e45d34df778ada75`
Audited base `main`: `e36e0238adcf2241af45a3d217eb459e5fc6b83f`
Branch ahead/behind at audit: 1/0

## VERDICT

**CHANGES_REQUIRED / R01 — CP05 failed-candidate cleanup containment.**

Do **not** merge `e866258` to main as a closed milestone yet. The published builder implementation/test work is mostly aligned with the game-side contract, but one newly identified transactional cleanup scenario does not satisfy the explicit CP05 failure-recovery criteria.

This is a source/diff/log audit. ChatGPT did not independently execute Godot in this environment. Godot test outcomes below are builder-reported and supported by the permanent suites checked in the branch. Root `TASKS.md` was not changed by Claude.

### Accepted implementation boundaries (subject to R01 re-audit)

- LF CP03/M14 gate evidence is present, with exact current-main authority continuity at the start.
- One `RemoteContentManager` under `scripts/content_runtime/`; provider-neutral injected transport and HTTPS-only production transport.
- Strict Manifest V1, strict JSON, ZIP metadata / member contract / hash and current-game validator gates.
- Builtin 1–10 remains `res://`; remote append order follows the declared manifest order; no replace/reorder existing remote prefix.
- Download is bounded and staged under `user://content/`; application boot does not await network.
- Game integration remains narrow: `AppState`, `GameplayLaunchResolver`, `main.gd`; production gameplay host/economy/save/owner art untouched.
- Valid cached remote levels survive offline relaunch; corrupt successor is rejected without advancing active registry.

Builder-reported results:
- CP04: 28/28 PASS
- CP05: 15/15 PASS
- family fixture PASS
- root `tests/run_tests.gd`: 5,329 checks ALL PASS
- M35/M37/M40/M52/M43 and `m53_first10_difficulty` PASS
- `git diff --check`: clean

### Blocking finding: RC-R01-F001 / CP05 failure after partial pack installation

Exact source flow:

1. `RemoteContentManager._refresh_tx(tx)` iterates all packs in `to_install`.
2. For each successful pack, `_download_and_stage()` writes JSON to `staging/<tx>/pack`, then **renames the pack into its final `packs/<pack_id>/<version>-<sha256>/` path before the candidate registry is activated**.
3. If a later pack in the same manifest fails download/hash/schema/validation, `_refresh_tx` returns an error.
4. `refresh()` cleans `staging/<tx>/` and `downloads/<tx>.part`, but does not remove already-finalized **unreferenced candidate packs** from `packs/`.
5. A later boot/prune can eventually remove the orphans, but the failed transaction leaves candidate-installed files immediately after failure.

This violates the R01-covered strict requirement in the master prompt/criteria:
- partial/corrupt candidate cleaned/quarantined on failure;
- failed multi-pack transaction must not leave unreferenced pack artifacts installed;
- only active/LKG may remain installed after failed refresh.

Required correction:
- track which candidate pack directories this refresh installed/changed; **after every failure before activation**, remove only transaction-owned, unreferenced candidate pack directories;
- never delete any directory referenced by the previously verified active/LKG registry;
- retain correct success path, cache reuse/deduplication, and confirmed atomic activation;
- add permanent multi-pack failure tests proving immediate cleanup **without requiring a reboot**.

A design with true staging-until-commit is also acceptable if it preserves the same interface and passes every test. Do not use blanket `packs/` deletion, reset or clean.

### Baseline exception: RC-R01-F002 / M53-C002 corpus determinism

`tests/m53_c002_difficulty_calibration.gd` reports exactly one failure:
`fresh run == committed corpus raw (timing excluded)`.

Claude reproduced the identical failure on untouched base `e36e023`, before CP04/CP05 files existed. The remote branch's diff does not touch M53 analyzer/tool/corpus files; this is a **pre-existing standalone regression**, not proof of CP04/CP05 gameplay drift.

Nonetheless, the master audit criteria requested M53 content/difficulty regression PASS. Treat this as an **explicitly tracked baseline exception**, not a fictitious PASS. The separate `SB-M53-C002-R01-001` task is opened for exact source diagnosis and repair without weakening the assertion. It must be closed before the final regression-clean release/family APK gate.

### Deferred production dependencies (correctly not claimed closed)

- CP04-011: Android INTERNET permission requires an export preset; `READY_FOR_ANDROID_EXPORT_GATE`.
- `application/config/version` absent, so production remote runtime fails closed.
- Runtime config is disabled with no HTTPS manifest/object endpoints.
- CP06 disabled-level and schedule semantics are still unsupported and candidates using them are rejected.
- SB-CPX-004 owner-facing Factory publisher handoff remains future/independent.

### Process deviation

Claude ran in a cloud clone, not the requested Windows owner-local checkout. The deviation is truthfully logged; there is no evidence that owner-local files were modified. R01 must preserve the owner-local checkout non-destructively when accessible and never assert local sync otherwise.

## NEXT

Issue and execute only:
`coordination/sessions/REMOTE-CONTENT-RUNTIME-V01/CHATGPT_REMEDIATION_PROMPT_R01.md`

Matching audit criteria:
`coordination/sessions/REMOTE-CONTENT-RUNTIME-V01/CHATGPT_REMEDIATION_AUDIT_CRITERIA_R01.md`

After R01 implementation and its logs arrive, perform a fresh independent re-audit. Only after CP04/CP05 runtime gets PASS may it be promoted into main. M53 corpus fix is a separately queued maintenance task.

**FINAL: CHANGES_REQUIRED / R01**
