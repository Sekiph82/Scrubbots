# SB-M53-C002-R01-001 | ChatGPT Audit Criteria V01

- [ ] Untouched e36e023 baseline reproduces exactly one fresh-vs-committed-raw failure.
- [ ] Two fresh runs agree with each other (timing excluded).
- [ ] Deterministic field-level old/fresh raw diff supplied for flow_stripes3_20 and all affected corpus fixtures.
- [ ] First drift commit isolated through git history/bisect and relevant dependency path proven.
- [ ] Cause classified with auditable evidence as unintended regression vs intentional approved behavior change.
- [ ] If regression: narrow code fix proven without undoing other approved gameplay behavior.
- [ ] If intended behavior: artifacts regenerated only via existing tool, all provenance and SHA/freeze/holdout bindings updated coherently, with explicit owner/GPT gate before any candidate authority change.
- [ ] Frozen candidate, calibration chronology and First 10 holdout constraints preserved.
- [ ] No assertion weakened, skipped, relabeled, rounded away or made tolerant.
- [ ] No unapproved production palette/level/supply/progression/score changes.
- [ ] Original m53_c002_difficulty_calibration now PASS with exact determinism check intact.
- [ ] M53-C001/First 10, M52, M54, CP04/CP05, family fixture and root tests PASS.
- [ ] Git diff --check clean and no unexplained script errors.
- [ ] Root TASKS.md untouched by builder.
- [ ] Claude log includes exact SHA, source commit, field-level diff and test evidence.
- [ ] Log ends AWAITING_GPT_M53_C002_R01_STALE_CORPUS_AUDIT.

Task remains OPEN until independent ChatGPT strict PASS.
