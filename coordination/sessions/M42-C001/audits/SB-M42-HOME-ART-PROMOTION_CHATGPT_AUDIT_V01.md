# M42 HOME ART PROMOTION — ChatGPT Independent Audit V01

Date: 2026-09-25
Auditor: ChatGPT
Baseline SHA: `1cd31e789f6ca638cfbf367606193d1523b7e08d`
Implementation SHA: `317b1e1f3cab834cb4ffe247c5d4c49e16e9c45c`
Claude log SHA: `acffe31beef91590e2d4cae8fb0e9cb63a647627`
Prompt: `coordination/sessions/M42-C001/task_prompts/SB-M42-HOME-ART-PROMOTION.md`
Criteria: `coordination/sessions/M42-C001/audit_criteria/SB-M42-HOME-ART-PROMOTION.md`

## Verdict

**AUDITED_PASS / M42 HOME ART PROMOTION**

No remediation is required.

## Independent evidence

### 1. Owner authority and exact approved blobs

The ten owner approval artifacts contain 49 unique generation-required Home ART rows.

ChatGPT independently parsed those 49 rows and compared each owner-recorded Git blob SHA against the complete Git tree for implementation commit `317b1e1` (tree `819840e7d1e9961b4eaad70ccda8f944c61269be`).

Result:

- approval rows: **49**
- unique approved IDs: **49**
- blob mismatches: **0**
- missing approved paths: **0**

Therefore every promoted unique PNG at the audited implementation commit is the exact owner-approved Git object.

### 2. No approved image was changed by the promotion

GitHub compare `1cd31e7..317b1e1` contains exactly three changed files:

- `assets/ui/HOME_ASSET_MANIFEST.json`
- `tests/m42_assets.gd`
- `tests/m42_home.gd`

There are **zero PNG changes** in the implementation diff. No image generation, replacement, recompression, resize, rename or move occurred.

The validator and production binder are also absent from the diff:

- `scripts/tools/home_asset_manifest_validator.gd` unchanged
- `scripts/ui/home/home_art_binder.gd` unchanged

So the existing SHA-256 lifecycle protection was not weakened to make the promotion pass.

### 3. Manifest state

ChatGPT independently parsed the promoted manifest at current main/log HEAD and verified:

- total manifest entries: **119**
- total ART entries: **50**
- generation-required ART entries: **49**
- ART entries with `status=APPROVED`: **50**
- malformed/non-lowercase/non-64-character approval pins: **0**
- unique ART file paths: **49**
- `HOME-087` is the only reuse relationship for the Scrub Bucks file
- `HOME-042` and `HOME-087` use the same path
- `HOME-042` and `HOME-087` use the same approval SHA-256:
  `a843e21f429b28f2f2c91e9b5015efee7312e96e9112ce616947035dff68a8ef`

The implementation diff changes the promoted entries only from `PLANNED` to `APPROVED` and adds `approved_sha256`; IDs, slugs, paths, providers, notes and reuse semantics are preserved.

### 4. Lifecycle and negative-test coverage

The audited test changes correctly move production expectations from the old unapproved state to the now-approved state while retaining negative coverage.

`tests/m42_assets.gd` verifies, among other things:

- 50 approved ART manifest entries;
- all approval pins are lowercase 64-character hashes and equal the actual checked-out file SHA-256;
- `HOME-087` pin equals `HOME-042`;
- 49 generation-required targets remain present;
- real `HomeArtBinder.summary()` is `{"APPROVED_BOUND": 50}`;
- all approved final paths are write-protected;
- an entry reverted to unapproved stops binding;
- missing approval hash is rejected;
- mismatched hash invalidates the manifest;
- a non-final/generated path cannot bind;
- a manifest error prevents binding.

`tests/m42_home.gd` was legitimately updated because production art now binds. It still explicitly tests fallback behavior by using an in-memory manifest copy with selected assets reverted to unapproved.

This preserves the pre-approval safety behavior without falsely expecting the real production manifest to remain unapproved.

### 5. Test/regression evidence

Claude's implementation log records execution from a clean detached worktree of `317b1e1`:

| Suite | Result |
|---|---|
| `m42_assets` | 4/4 PASS, exit 0, zero SCRIPT ERROR |
| `m42_home` | 19/19 PASS, exit 0, zero SCRIPT ERROR |
| `m42_navigation` | 12/12 PASS, exit 0, zero SCRIPT ERROR |
| root `run_tests` | 5322 checks, ALL PASS, exit 0, zero SCRIPT ERROR |

The root suite's eight engine `ERROR:` lines are the previously documented intentional corrupt/missing-image negative-test output, not a new M42 regression.

`git diff --check` is recorded clean.

### 6. Authority boundaries

The implementation commit does not modify:

- root `TASKS.md`;
- owner approval artifacts;
- existing ChatGPT audit files;
- the validator;
- the production Home art binder.

The separate log commit adds only the Claude implementation log.

## Gate impact

This audited promotion satisfies the previously external asset-approval dependencies for:

- **SB-M42-014 — AUDITED_PASS**
- **SB-M42-016 — AUDITED_PASS**
- **SB-M42-018 — AUDITED_PASS**

For **SB-M42-017**, the asset-approval dependency is cleared and all approved art now binds, but the task remains:

**CODE_AUDIT_PASS / OWNER_VISUAL_REVIEW_REQUIRED**

because headless bounds and asset-by-asset approval do not establish acceptance of the fully composed Home screen in a running build.

SB-M42-011 likewise remains on its existing composed-Home visual-review gate until the owner sees the live composition.

## Final

**AUDITED_PASS / M42 HOME ART PROMOTION**

Next owner action: run/view the Home screen with the now-bound production art and approve or reject the composed Home visual result.
