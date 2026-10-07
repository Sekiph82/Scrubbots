# SB-CP05-R01-001 | ChatGPT Audit Criteria V01
Date: 2026-10-07

- [ ] Remote runtime commit e866258 and all newer ChatGPT governance changes preserved by safe sync.
- [ ] No destructive owner-local operation. Root TASKS.md untouched by Claude.
- [ ] Transaction-owned candidate pack paths tracked precisely.
- [ ] When later pack B/C fails, earlier unreferenced finalized candidate pack paths are cleaned IMMEDIATELY, not only after next boot.
- [ ] Active/LKG and reused referenced pack directories never deleted.
- [ ] Every pre-commit failure (transport/hash/ZIP/schema/payload/write/verify/registry) cleans txn-owned paths.
- [ ] Candidate registry never activated before full validation; failed registry write/rename preserves LKG.
- [ ] Cleanup idempotent and confined to user://content/.
- [ ] Retry successful, no redundant downloads, no stale ghost dirs.
- [ ] Multi-pack failure-with-active-LKG test passes and asserts exact old registry + file hashes without relaunch.
- [ ] Multi-pack failure-without-active-registry test passes and built-in remains playable.
- [ ] Reused pack + failure test passes; verify/registry activation failure test passes.
- [ ] Interruption/cold-boot recovery test passes.
- [ ] All CP04 + CP05 + family fixture tests PASS.
- [ ] M35/M37/M40/M52/M43, m53_first10 and root tests PASS.
- [ ] Existing pre-existing M53-C002 corpus failure accurately disclosed and not conflated with R01.
- [ ] No existing assertion weakened or removed.
- [ ] diff --check clean and no new unexplained script errors.
- [ ] Developer log published with final SHA, correct scope and end marker AWAITING_GPT_CP05_R01_TRANSACTION_CLEANUP_AUDIT.

Verdict: PASS only when the partial multi-pack failed-transaction leak is eliminated.
