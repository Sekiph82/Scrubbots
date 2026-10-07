# M53-C002-R01 — CHATGPT SERIALIZATION AUTHORITY DECISION V01

Date: 2026-10-07
Repository: `Sekiph82/Scrubbots`
Diagnostic implementation/evidence: `b81e4f1902dcf30f43f4e8496679082ba4ef2a87`

## DECISION

**OPTION A APPROVED — platform-independent serialization-only re-freeze.**

Option B (Windows-only canonical evidence platform with a permanent Linux/CI exception) is rejected.

## Basis

The M53-C002 diagnostic established:
- the single determinism failure reproduces on untouched `e36e023`;
- the same Linux environment fails even when checked at the original freeze commit `4bea41e`;
- there is no first behavior-changing commit to bisect;
- 27 corpus fixtures were remeasured;
- 25 are text-identical;
- only 2 fixtures contain differences;
- there are exactly 3 differing numeric leaves;
- no schema, key, array, policy-run, completion or vector structure differs;
- the three differences are decimal-format rounding boundaries, not a detected gameplay/analyzer algorithm change.

This is classified as a **latent platform-dependent evidence serialization defect**, not a production gameplay regression.

## Authorized remediation

Replace the QA calibration evidence writer's platform-dependent float text path with one explicit canonical, platform-independent full-precision JSON serialization authority. The test must use that same canonical authority for exact determinism comparison.

The remediation may regenerate and re-freeze the M53-C002 **V2 candidate QA artifacts only**:
- corpus raw;
- corpus evidence;
- frozen V2 candidate config if its serialized/derived anchor bytes necessarily change;
- First 10 holdout raw/evidence;
- generated calibration matrix/provenance outputs that are cryptographically bound to those artifacts.

The re-freeze is authorized because V2 remains **CANDIDATE_NOT_PRODUCTION_AUTHORITY** and because this decision is serialization/platform portability maintenance, not production difficulty tuning.

## Hard semantic invariants

The re-freeze is valid only if all of the following are proved:

1. No production LevelData, owner-approved supply plan, production catalog, palette, Difficulty V1 weights, progression targets or gameplay system changes.
2. No V2 formula, policy family, fixture, coefficient, threshold, target, tolerance or model rule changes.
3. Every corpus fixture remains SOLVED with the same level/supply content hashes.
4. All declared ordinal-pair outcomes remain identical.
5. All family-check PASS/FAIL outcomes remain identical.
6. All robustness PASS/FAIL outcomes remain identical.
7. First Ten holdout ordering, recovery verdicts, boss relation, window/class-like decisions and any owner-reviewed qualitative conclusions remain unchanged.
8. Numeric differences introduced by recovering full precision are explainable solely by the old lossy/platform-dependent serialization boundary. Produce a machine-readable before/after delta report.
9. No meaningful displayed score/metric changes: require exact equality where values were unaffected, and explicitly report max absolute/relative difference for all affected numeric derived outputs. Any change that crosses a decision threshold, changes a rounded product-facing score, or alters an owner-reviewed conclusion is **STOP / GPT_REQUIRED**.
10. Existing determinism assertion remains exact. No epsilon/tolerance, skip, platform exception, field deletion or canonical-Windows emulation.
11. The canonical serializer itself gets permanent golden tests including the three known boundary values.
12. Evidence provenance must state that this is a serialization-only re-freeze and record old/new frozen-config/evidence SHA bindings.

A one-time optional owner Windows run is useful corroboration but is **not required** to proceed with Option A, because the defect and chosen remedy are cross-platform portability issues and the new authority must not depend on Windows.

## Owner calibration status

No new owner difficulty rating session is required **if and only if** the hard semantic invariants above prove no decision-level or owner-facing difficulty result changed. If any owner-reviewed score/category/conclusion changes, stop and request owner review before closing M53-C002-R01.

## Next

Execute:
`coordination/sessions/M53-C002/CHATGPT_PLATFORM_INDEPENDENT_REFREEZE_PROMPT_R02.md`

Audit against:
`coordination/sessions/M53-C002/CHATGPT_PLATFORM_INDEPENDENT_REFREEZE_AUDIT_CRITERIA_R02.md`

**DECISION: A / AUTHORIZED**
