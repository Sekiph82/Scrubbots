# M52-C001 — FIRST 10 FINAL MATRIX V01

Status: AUDIT-BOUND EVIDENCE MATRIX
Date: 2026-09-26
Current audited implementation: `2b3d29f550dd985ac0e94ff7ec3f8b7310ad7244`
Pre-audit log HEAD: `288107393ab755f8e67b66207abe10c0d4466fbb`

Difficulty note: per the newer owner decision `coordination/OWNER_M52_C001_FIRST_10_LEVEL_PACK_DECISION_V01.md`, canonical real-level Challenge / Session Load / Frustration values are not fabricated in M52-C001 and are explicitly deferred to M53. Therefore the Actual D / Delta columns below are `M53_REQUIRED`, not invented values.

| Order | ID | Subject | Dim | Colors | Class | Target D | Actual D / Delta | Solver | Source SHA-256 | LevelData SHA-256 | Mutation | Catalog |
|---:|---|---|---|---:|---|---:|---|---|---|---|---:|---|
| 1 | `m21_level_001_hazard_bot` | Hazard Bot | 20x20 | 5 | EASY | 20 | M53_REQUIRED | SOLVED / replay PASS | `34dfa3548b6c73b7ca3bfaaadb67388c0073595b049ca32466af4b12d6d71530` | `ae725a9c86839dcffb6444f3208416b553679878be7999ef8814de51241e8c1c` | 0 | order 1, unchanged |
| 2 | `level_002_apple` | Apple | 32x32 | 5 | EASY | 22 | M53_REQUIRED | SOLVED / replay PASS | `b1dd3b414738cf0557cf9baabb5d3a12208df3c3a57d3ab3184e990df1dcf580` | `f0cf2a00898582979e9078a00ce2d0935030bc67ba7d7295360cea40ca889486` | 0 | order 2, owner plan |
| 3 | `level_003_palm_tree` | Palm Tree | 38x38 | 6 | MEDIUM | 40 | M53_REQUIRED | SOLVED / replay PASS | `84960199759b1c3a1e130a24149c14fff9a5ee6ffb53db4ec6f138e34c6116cc` | `0aceddb060f9770fda64ad55c3d3121530d3dc9d6b18f7901a382b2fb2d1d2aa` | 0 | order 3, owner plan |
| 4 | `level_004_orange_cat` | Orange Cat | 32x32 | 7 | EASY | 19 | M53_REQUIRED | SOLVED / replay PASS | `0b8cbc068d1d070cc5c68ee439ccb908a09cc99180f6a068ba4475339f41c926` | `070ec1f61ebf8c2b824a62bdcd0a9e1f1b51a8588c59dc0e86a36f440f93066e` | 0 | order 4, owner plan |
| 5 | `level_005_party_toucan` | Party Toucan | 33x33 | 10 | HARD | 58 | M53_REQUIRED | SOLVED / replay PASS | `c95c0fd4021bb90eacd78dbc2279809f26fe0ed435cca260881ee6961eb9874f` | `b2c61546e75c4a203d902889e8bf41f0c82827bfdc01d9aea9a8c58ba1c5be36` | 0 | order 5, owner plan |
| 6 | `level_006_chicken` | Chicken | 32x32 | 8 | EASY | 18 | M53_REQUIRED | SOLVED / replay PASS | `9e15e570a7b8d5a31f4cd0eb37e4f6e48e18e71f66b7c56e08510738412ff790` | `22aa7df9e837e1403f672fea0efc988ce8222840f9a9c24a3f943685525ca762` | 0 | order 6, owner plan |
| 7 | `level_007_pigeon` | Pigeon | 32x32 | 8 | EASY | 21 | M53_REQUIRED | SOLVED / replay PASS | `ca6004936d2ab9f4a8faef3215f9887157a407a7b63743ec07cc0a922530158a` | `7b2884005a7685e3bfe6d47e99f197e56a395a5e914c3479f830fd1dcb200272` | 0 | order 7, owner plan |
| 8 | `level_008_butterfly` | Butterfly | 32x32 | 8 | MEDIUM | 42 | M53_REQUIRED | SOLVED / replay PASS | `9a623fece67690862ba73b737e5e52d9acfbe1e46b160c411eee5714ea01b2fc` | `672053fc43ec1d5f50cc5f27ed98e7e0d022c62524b47b831a8addf32343f339` | 0 | order 8, owner plan |
| 9 | `level_009_frog` | Frog | 32x32 | 7 | EASY | 19 | M53_REQUIRED | SOLVED / replay PASS | `b0bd1638961cd69e64f2bd174df117d3c75520be0804a114362efc96663d036f` | `b5989964a4dd1e909e169c0b796919e34165ff9fe1f4d10679f6cffc17a4604f` | 0 | order 9, owner plan |
| 10 | `level_010_ice_cube` | Ice Cube | 32x32 | 10 | VERY_HARD | 76 | M53_REQUIRED | SOLVED / replay PASS | `a39b54c0adc05ca4778536cd9f0b5bccaa7cfde786fb8c72efa4be91029d3d61` | `ab7a93178852441d1750c66fed3e24b30b906d145383f7df5113eda7b8dff8ed` | 0 | order 10, owner plan |

## Owner-plan/runtime evidence

Levels 2–10 additionally bind:
- exact owner-input markdown SHA-256;
- exact Cxx -> local palette map;
- complete hidden FIFO queue layout;
- per-color/grand conservation;
- intended owner click trace;
- canonical solver trace + hash + replay;
- production runtime AppState -> catalog -> resolver -> host verification.

Per-level JSON authority:
`coordination/sessions/M52-C001/evidence/owner_plans/<level_id>_verification.json`.
