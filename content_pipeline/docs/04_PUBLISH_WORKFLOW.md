# Publish Workflow

Target UX may eventually be one button, but underlying stages must remain
individually testable:

1. validate accepted Factory handoff
2. build scrubpack(s)
3. compute SHA-256
4. build candidate manifest
5. dry-run/preflight remote mutations
6. upload immutable/versioned pack objects
7. verify remote bytes/hash
8. publish STAGING manifest
9. verify staging using real download path
10. explicit owner/operator promotion
11. publish new PRODUCTION manifest version
12. verify production
13. emit publish report

A failure before promotion must not mutate the active production manifest.
