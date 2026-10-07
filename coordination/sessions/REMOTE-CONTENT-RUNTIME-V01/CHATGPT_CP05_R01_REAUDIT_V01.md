# SB-CP05-R01-001 — CHATGPT STRICT RE-AUDIT V01

Date: 2026-10-07
Repository: `Sekiph82/Scrubbots`
Original runtime implementation: `e8662583fe24e9edf17ca595e45d34df778ada75`
R01 implementation: `19618f6e0c2b18e18496328d14c3fa27f065434e`
Final reviewed branch: `b81e4f1902dcf30f43f4e8496679082ba4ef2a87`
Integration PR: #8
Merged main: `09f320044abc0424c6a9916cdbbce4eec047b820`

## VERDICT

**PASS / CLOSED — SB-CP05-R01-001**

The blocking multi-pack failed-candidate leakage identified in `CHATGPT_INDEPENDENT_AUDIT_V01.md` is closed.

## Source review

The final implementation changes the transaction boundary from "verify then immediately move each pack to final storage" to **staging-until-full-candidate-verification**.

- Every missing pack remains under `staging/<tx>/pN/` until the full candidate registry can be verified.
- `_commit()` is now the only path that mutates final `packs/`.
- `placed` tracks final directories created by the current transaction.
- `displaced` tracks pre-existing target directories temporarily moved aside for repair.
- Reused exact-identity active/LKG packs never enter transaction ownership.
- Any install/registry-write/registry-rename/post-activation verification failure invokes a narrow rollback.
- Rollback removes only transaction-owned placed paths, restores displaced paths, removes only newly-empty parent dirs, and leaves active/LKG content untouched.
- Previous registry bytes are retained in memory until successful activation.
- `registry_v1.prev.json` is written only after the new registry has activated and re-verified.
- With no previous active registry, a failed post-activation verification removes the candidate active registry rather than leaving it live.
- No blanket `packs/` deletion exists.
- Content-root confinement remains in `_rm_tree()`.

The earlier R01 blocker, where B could remain installed after later C failed, is therefore eliminated.

## Permanent evidence

New suite:
`tests/cp05_r01_transaction_cleanup.gd`

Builder-reported final results:
- new R01 suite: **6/6 PASS**
- CP04 remote runtime: **28/28 PASS**
- CP05 cache/LKG: **15/15 PASS**
- family end-to-end fixture: **PASS**
- M35/M37/M40/M52/M43 regression: **PASS**
- `m53_first10_difficulty`: **PASS**
- root `tests/run_tests.gd`: **5,329 checks / ALL PASS**
- `git diff --check`: clean
- no new unexplained script errors

The six new R01 cases cover:
1. active A + new B/C, later C hash/ZIP failure => byte-identical tree without reboot;
2. first-install multi-pack failure => no candidate residue, builtin remains playable;
3. reused active pack survives cleanup unchanged;
4. valid retry succeeds once with no redundant download;
5. candidate verification / registry write / registry rename / post-activation failure rollback;
6. cold-boot interruption recovery.

The updated CP05 k09 assertion was retargeted to the new commit boundary and is not weakened.

## Known unrelated regression

`tests/m53_c002_difficulty_calibration.gd` remains one-failure red on Linux. That failure is independently proven to exist on untouched `e36e023` and even at the original M53-C002 freeze code/data on this Linux environment. It is not caused by CP04/CP05. It remains tracked separately as `SB-M53-C002-R01-001`.

This baseline exception does not reopen CP05-R01, but it **must be resolved before the clean Family APK regression gate**.

## Runtime program status

- CP05/M16 offline cache / last-known-good runtime: **TECHNICAL PASS / CLOSED**.
- CP04/M15 remote content runtime core: **TECHNICAL PASS**.
- CP04-011 remains explicitly **READY_FOR_ANDROID_EXPORT_GATE** because Android export preset / INTERNET permission is not yet present.
- production endpoint remains disabled/unconfigured by design.
- CP06 disabled/schedule semantics remain unsupported and fail closed.
- SB-CPX-004 remains a later external Factory integration task.

**FINAL: PASS / CLOSED — SB-CP05-R01-001**
