# M43-C005-C006 — CHATGPT V03 FRAME ALPHA + CADENCE INDEPENDENT AUDIT

Date: 2026-10-04  
Canonical task: **SB-M43-064**  
Audited implementation: `ebc7644a95a1637c2c19c0478a36a3e8a56c62ba`  
Baseline: `c108ebc71986b4404fa659e008a6a2d9b4c3272c`  
Prompt: `CHATGPT_PROMPT_V03.md`  
Audit criteria: `CHATGPT_AUDIT_CRITERIA_V03.md`  
Result: **TECHNICAL_AUDIT_PASS / FRESH_OWNER_VISUAL_GATE_REQUIRED**

## 1. Independent audit scope

Reviewed:
- V03 prompt and V03 audit criteria;
- V03 Claude log, frame alpha matrix and V03 manifest;
- actual one-commit diff from baseline to audited SHA;
- current shipping Standard Pack ceremony source;
- V03 alpha cleanup script;
- rendered-pixel validator;
- focused SB-M43-064 V03 suite source;
- current historical C002 manifest;
- current historical candidate, V03 clean candidate and shipping frame trees;
- V03 checkerboard, gray, white and runtime 01→09 evidence sheets.

The audited implementation is exactly one commit ahead of the V03 baseline.

## 2. Diff / scope boundary

PASS.

The V03 commit changes only the expected Standard Pack alpha/cadence remediation surfaces:
- five shipping Standard frame PNGs (05..09);
- nine new V03 clean candidate PNGs;
- ceremony timing constants only;
- focused tests/evidence tooling;
- alpha cleanup/validation/render/manifest tooling;
- V03 evidence, matrix, manifest and log;
- visual-asset index metadata.

No V03 commit change exists in:
- root `TASKS.md`;
- Premium Pack / SB-M43-065;
- pack transaction authority;
- Collection mutation;
- Cards Exchange mutation;
- reward/save/navigation authority;
- owner-review harness files.

## 3. Historical provenance and promotion

PASS.

Independent GitHub tree inspection proves:
- historical C002 Standard candidate files remain present at their original paths;
- V03 clean candidate family exists under `standard_v03_alpha_clean/`;
- each V03 candidate and its shipping final have the **same Git blob SHA** for all 9 frames;
- 01..04 V03 candidate/final blobs are byte-identical to the historical candidate blobs;
- 05..09 V03 candidate/final blobs differ from historical candidates, as required by the alpha remediation.

Independent manifest reconciliation also shows every V03 `sha256_before` equals the matching historical `PACK_ASSET_MANIFEST_V01.json` Standard SHA-256.

## 4. Alpha / matte audit

PASS.

The V03 rendered-pixel validator is materially load-bearing:
- decoded RGBA pixels are inspected directly;
- border transparency is checked;
- large dark connected components are rejected;
- dark semi-transparent wash is rejected;
- rectangular bbox-side fill is rejected;
- long straight alpha-edge cuts are rejected.

The cleanup is not a naive global-black threshold. It derives a solid-object mask, protects dark internal detail and exact C002 card silhouettes, and re-derives only alpha/translucent-light behavior outside protected art.

### Independent V03 manifest check

All 9 shipping rows report:
- `clean = true`;
- no validator failures;
- candidate/final byte identity;
- 1024×1536 RGBA provenance.

Frames 05..09 materially increase true transparency after cleanup, while bright-art centroid drift remains tiny:
- F05: 0.332 px
- F06: 0.238 px
- F07: 0.226 px
- F08: 0.231 px
- F09: 0.193 px

This is consistent with background cleanup rather than geometry redesign.

### Sensitivity

Published `validator_sensitivity_v03.json` contains **32 cases**, all matching expectation:
- 9 clean V03 frames PASS;
- 9 injected opaque-black rectangles FAIL;
- 9 injected semi-transparent dark rectangles FAIL;
- historical 05..09 FAIL.

**NOTE:** `CLAUDE_LOG_V03.md` states “33/33” alpha sensitivity expectations. The actual JSON has 32 rows and 32/32 correct outcomes. This is a reporting/counting discrepancy only; the required sensitivity classes are present and successful.

## 5. Independent visual review

PASS for the technical matte/background gate.

I independently reviewed:
- `STANDARD_V03_CLEAN_checkerboard_01_09.png`;
- `STANDARD_V03_CLEAN_gray_01_09.png`;
- `STANDARD_V03_CLEAN_white_01_09.png`;
- `STANDARD_RUNTIME_01_09_V03_CONTACT_SHEET.png`.

Findings:
- no black/dark rectangular matte remains in any of 01..09;
- no old 48 px rectangular canvas boundary remains;
- 05/07/09 no longer present the former near-black box;
- 06/08 no longer present the former dark rectangular wash;
- intentional yellow/cyan/blue light remains translucent;
- pack, torn flaps and card backs remain visually solid;
- no obvious registration jump is visible across the sequence;
- runtime 01..09 frames render without the prior rectangular background defect.

Frames 06 and 08 retain a tighter, irregular translucent glow envelope than 05/07/09. It is non-rectangular, consistent with the preserved source effect, and is not a matte/background defect.

## 6. FULL 01→09 cadence

PASS.

Production source now defines:
- frame 01 hold: **0.40 s**;
- frames 02..08: **0.22 s each**;
- owner minimum: **0.18 s**;
- frame 09 pre-card hold: **0.30 s**.

The opening still uses the single shipping `PackFrame` texture node and one shared RevealSequencer.

The focused V03 cadence test:
- records actual `step_started` bind timestamps;
- requires exact frame history `[1,2,3,4,5,6,7,8,9]`;
- computes actual 01..08 bind-to-next-bind hold times;
- rejects any hold below 0.18 s;
- verifies one current pack-frame node;
- verifies no live card face before frame 09.

Runtime evidence contains one real shipping capture for each bound frame 01..09. The contact sheet visibly contains nine distinct chronological states.

Claude-recorded measured holds are all above the 0.18 s gate, with the shortest reported final-run hold at 0.206 s.

## 7. V02 flow regression

PASS by source/diff inspection and V03 runtime evidence.

V03 changes the shipping ceremony only in timing constants. The V02 state-machine semantics remain:
- pack-alone IDLE;
- Tap 1 required;
- 01→09 opening;
- live cards emerge at the final beat;
- pack disappears;
- three-card hold;
- Collection upper-left / Cards Exchange upper-right;
- Tap 2 required;
- NEW -> Collection;
- DUPLICATE -> Cards Exchange;
- completion once after three arrivals;
- Reduced Effects keeps both interaction gates and frame-09 shortcut semantics.

No authority mutation was introduced.

## 8. Tests / independent-proof boundary

Claude records on the final bytes:
- focused SB-M43-064 suite: **21/21 PASS**, twice;
- cadence/dirty-asset mutation checks detected;
- runtime evidence driver: **0 REJECTED**;
- RevealSequencer: **12/12 PASS**;
- relevant M43 suites: PASS;
- root suite: **5,323 / 5,323 PASS**;
- `git diff --check`: clean.

These Godot executions were **not independently rerun by ChatGPT in this audit environment**. I independently inspected:
- the production source;
- the exact commit/diff;
- the focused test logic;
- validator source;
- machine-readable manifest/sensitivity evidence;
- Git blob identity across candidate/final assets;
- rendered visual evidence.

No material test-quality or false-positive gap was found for the V03 acceptance criteria.

## 9. Decision

**TECHNICAL_AUDIT_PASS / FRESH_OWNER_VISUAL_GATE_REQUIRED**

The V03 technical remediation is accepted.

SB-M43-064 remains **OPEN**. The owner must now review the live V03 ceremony in Godot before OWNER VISUAL PASS.

The existing owner-review harness was created against V02 and its smoke test pins the old V02 ceremony hash. It therefore requires a small V03 rebaseline/update before it can be treated as the current audited owner-review surface.

Next action:
- issue owner-review-harness V02 rebaseline;
- production V03 ceremony/assets remain immutable;
- after harness audit PASS, return actor to OWNER for live F6 review;
- only explicit OWNER VISUAL PASS closes SB-M43-064 and unlocks SB-M43-065.
