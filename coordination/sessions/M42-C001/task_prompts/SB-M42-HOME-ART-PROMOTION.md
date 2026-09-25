# SB-M42 HOME ART PROMOTION — IMPLEMENTATION PROMPT V01

## Role and authority

You are Claude Code implementing the deterministic post-owner-approval promotion step for ScrubBots M42 Home art.

Repository: `Sekiph82/Scrubbots`
Branch: `main`

ChatGPT remains the sole writer of root `TASKS.md`, ChatGPT audit files, and owner decision/approval artifacts. Do not modify them.

## Owner authority

Read and obey:
- `coordination/OWNER_M42_HOME_ART_COMPLETE_APPROVAL_V01.md`
- every batch approval file referenced by that document.

The owner has visually approved all 49 unique generation-required Home ART files. `HOME-087` is a declared reuse of the exact same file as approved `HOME-042`.

## Goal

Promote the approved Home art into the deterministic manifest lifecycle so the existing `HomeArtBinder` can bind it in production.

This is a metadata/test operation only. Do not generate, edit, recompress, resize, rename, move or overwrite any PNG.

## Required implementation

1. Start from current `main`; record baseline HEAD and ensure worktree is clean.
2. Read `assets/ui/HOME_ASSET_MANIFEST.json` and all owner approval artifacts.
3. Before changing anything, verify every approved repository path still has the exact Git blob SHA recorded in its owner approval artifact.
   - Use Git object/blob verification, not image timestamps.
   - If any approved blob differs, STOP. Do not promote anything. Write a blocker log and hand back.
4. Confirm the manifest still contains exactly 49 `kind=ART && generation_required=true` entries and exactly one ART reuse entry `HOME-087` pointing to the same path as `HOME-042`.
5. Compute SHA-256 from the actual bytes of each approved PNG in the checked-out repository.
6. In `assets/ui/HOME_ASSET_MANIFEST.json`:
   - set all 49 owner-approved generation-required ART entries to `"status": "APPROVED"`;
   - add their exact 64-character lowercase `approved_sha256`;
   - set `HOME-087` to `"status": "APPROVED"` using the same `approved_sha256` as HOME-042 because it reuses the identical file;
   - change no slug, ID, path, provider, reuse relationship, notes or semantic authority unless strictly required to preserve schema validity.
7. Update `tests/m42_assets.gd` only as needed to reflect the owner-approved production state:
   - real manifest validates;
   - 49 generation-required ART entries are approved;
   - all 50 ART manifest entries, including HOME-087 reuse, report `APPROVED_BOUND`;
   - no approved asset can be silently overwritten;
   - hash mismatch adversarial coverage remains intact;
   - generated/unapproved-path adversarial coverage remains intact.
8. Do not weaken the validator or binder to make tests pass. The existing SHA-256 protection must remain authoritative.
9. Verify there is zero binary diff for every owner-approved PNG between baseline HEAD and final implementation commit.
10. Run:
   - `godot --headless --path . -s res://tests/m42_assets.gd`
   - `godot --headless --path . -s res://tests/m42_home.gd`
   - `godot --headless --path . -s res://tests/m42_navigation.gd`
   - `godot --headless --path . -s res://tests/run_tests.gd`
   - `git diff --check`
11. Require exit 0, no `SCRIPT ERROR`, and no new regression. Pre-existing known engine error lines from corrupt-image negative tests may be reported separately but must not be hidden.
12. Create implementation log:
   `coordination/sessions/M42-C001/task_logs/SB-M42-HOME-ART-PROMOTION.md`
   Include:
   - baseline and final SHA;
   - exact changed text files;
   - count of promoted entries;
   - proof of 49 unique approved PNGs + HOME-087 reuse;
   - blob-verification result;
   - SHA-256/manifest validation result;
   - binder summary;
   - test results;
   - proof no PNG changed;
   - explicit statement that `TASKS.md`, owner artifacts and ChatGPT audits were untouched.
13. Commit and push to `main`.
14. Stop with:
   `AWAITING_CHATGPT_AUDIT / M42 HOME ART PROMOTION`

## Forbidden

- No image generation.
- No PNG modification of any kind.
- No `TASKS.md` edits.
- No owner approval edits.
- No ChatGPT audit edits.
- No bypassing/removing SHA-256 validation.
- No claiming final M42 visual closure. Final composed Home review remains an owner gate after the approved art is bound in a running build.
