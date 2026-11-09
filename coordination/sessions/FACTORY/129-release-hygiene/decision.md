APPROVE

Orchestrator decision (one reviewer, owner rule). Round-1 review PASS, no must-fix (versioning check + selftest, yaml, m59_credits 3/3, m51 8/8, validate_content). Reviewer saw m41_settings fail once in its worktree; after rebase onto main the orchestrator re-ran m41_settings: PASS, and main CI 42660560619 (m41 included) is green. Release paths gated on validate + content validator + clean clone; debug paths unchanged; godot_ai excluded; CREDITS screen. First CI run of the new gate jobs pending.
