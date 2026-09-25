# SB-M42 HOME ART PROMOTION — CHATGPT AUDIT CRITERIA V01

Verdict may be PASS only if all criteria below are independently verified.

1. Owner authority exists and covers all 49 unique generation-required ART files.
2. HOME-087 is only a declared reuse of HOME-042's exact path and bytes.
3. Every approved path's current Git blob matches the blob SHA recorded in the owner batch approval artifact before promotion.
4. No approved PNG is modified, regenerated, recompressed, renamed, moved or replaced by the implementation.
5. Manifest contains exactly 49 generation-required ART entries and 50 total ART entries.
6. All 49 unique approved ART entries have `status=APPROVED` and a 64-character lowercase SHA-256 matching actual file bytes.
7. HOME-087 is APPROVED with the same SHA-256 as HOME-042.
8. `HomeAssetManifestValidator.validate(real_manifest)` passes without weakening validator rules.
9. `HomeArtBinder.summary()` reports all 50 ART entries as `APPROVED_BOUND`, with no NOT_APPROVED/HASH_MISMATCH/MANIFEST_INVALID entries.
10. Approved-path overwrite protection remains effective.
11. Hash-mismatch and non-final/generated-path adversarial tests remain effective.
12. `m42_assets`, `m42_home`, `m42_navigation`, and root `run_tests` pass with exit 0 and zero SCRIPT ERROR.
13. `git diff --check` is clean.
14. Root `TASKS.md`, owner approval artifacts, and existing ChatGPT audits are unchanged by Claude.
15. Implementation log accurately records evidence and final commit.
16. This promotion may clear the asset-approval dependency for SB-M42-014/016/018, but SB-M42-017 final composed Home visual review must remain open until the owner sees the bound Home screen in a running build.
