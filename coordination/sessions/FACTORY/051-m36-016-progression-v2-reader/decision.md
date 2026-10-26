APPROVE

## Why
The existing progression reader now accepts the v2 schema, and the analyzer and playtest tool opt in to it. Default behaviour stays on v1. The round-1 code finding (the v2 acceptance window used the v1 tolerance) was fixed in b8f197b9. All four final-round reviews are PASS, the only Note is a nit, and `git merge-tree` reports no conflicts. `git diff origin/main...HEAD -- data/config` is empty.

## Acceptance criteria
1. v2 loads, v3 and missing schema are rejected: met. The new suite passes with 55 cases and 0 fail (build.md, and round-2 review-code reran it).
2. Level 311 target is greater than level 11, under both v1 and v2 readers: met (suite s02, 20.89 > 14.24 for v2).
3. Cadence and slots for the ten listed level numbers, with both readers agreeing: met (suite s03).
4. Recovery guards and tolerances for v1 and v2: met (suite s04).
5. Analyzer provenance and its target line follow the progression it is given: met (suite s05). I did not rerun the suites myself; this rests on the reviews and build.md.
6. Byte identity: met. I confirmed the `data/config` diff is empty. Default-output equality rests on build.md's before/after comparison, which ignores solver wall-clock `ms` fields.
7. `--progression v2` run: met. It printed `DIFFICULTY_PLAYTEST OK`, and the v2 evidence is informational only with no gate added for L1..L10.
8. Regression suites: met, all PASS. The tests reviewer and the round-2 code reviewer both confirmed this.
9. `git diff --check` is clean and the changed files match the spec: met.
