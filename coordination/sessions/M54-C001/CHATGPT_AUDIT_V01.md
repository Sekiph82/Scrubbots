# M54-C001 — CHATGPT INDEPENDENT AUDIT V01

Date: 2026-09-27
Auditor: ChatGPT controller (independent of the builder)
Repository: `Sekiph82/Scrubbots`, branch `main`
Audited HEAD: `92a603471b484bb5386582ddf17727f8860f4731`
Prompt: `coordination/sessions/M54-C001/task_prompts/SB-M54-C001_FIRST10_FINAL_REGRESSION.md`
Criteria: `coordination/sessions/M54-C001/audit_criteria/SB-M54-C001_FIRST10_FINAL_REGRESSION.md`
Builder evidence: `coordination/sessions/M54-C001/CLAUDE_LOG_V01.md`, `coordination/sessions/M54-C001/FIRST10_M54_REGRESSION_MATRIX_V01.md`

## Verdict

**OWNER_REQUIRED / M54-C001 / SB-M54-017 HEART REGEN INTERVAL**

- SB-M54-001..016, 016A, 018..021 (21 rows): **AUDITED_PASS**.
- SB-M54-017: mechanics verified, but the canonical interval is contested by owner-level documents. It stays **OWNER_REQUIRED** until the owner rules.
- First 10 technical stability: no regression found. No First 10 content, plan or production byte changed.

The First 10 sequencing gate cannot be closed as `AUDITED_PASS` while one of its rows depends on an unresolved product value. The controller does not guess the value.

## 1. Owner decision required (single item)

Which Heart regen interval is canonical?

| Option | Source | Current repo state |
|---|---|---|
| **A. 900 s (1 Heart / 15 min)** | `coordination/OWNER_M42_HOME_POLISH_V06.md` §Hearts (commit `f758295`, 2026-09-26 14:58). It explicitly supersedes `OWNER_ECONOMY_REWARDS_V01.md` §6 for the interval and orders config/tests to 900 s. | `data/config/economy_rewards_v1.json` `hearts.regen_seconds: 900`. `HeartService`, `m39b_hearts_speed` and the Home 15:00 display all use this value. |
| **B. 1800 s (1 Heart / 30 min)** | `coordination/OWNER_FAILURE_RECOVERY_AND_ACQUISITION_V01.md` §4 (commit `f50b8a0`, 22:38 the same day): "Canonical Hearts remain … +1 every 30 real-world minutes". | `data/config/player_experience_plan_v1.json` `regen_minutes_per_heart: 30`; `docs/MASTER_UI_SYSTEM.md:494`; root `TASKS.md` row SB-M54-017 text "Heart 30-minute". |

The later document says "remain", which reads like a restatement of the pre-V06 value. It does not explicitly supersede V06. Both are owner-authority documents, and the repository ships two configs that disagree. This is a product-specification conflict, so the owner must decide it.

After the ruling:
- **If A (900 s):** no builder work is needed for M54. The controller corrects the stale 30-minute text in `TASKS.md` and records the ruling. The planning config/doc drift is tracked as a doc/config reconciliation item, because `player_experience_plan_v1.json` is not read by `HeartService`.
- **If B (1800 s):** this becomes a Claude remediation. It changes the production config, the Home timer display (15:00 → 30:00) and the heart tests, then re-runs SB-M54-017.

## 2. Contract recovery and scope

- The prompt scope is SB-M54-001..021 plus 016A. SB-M54-022..032 were excluded, and the builder did not touch them.
- Owner locks were honored. No difficulty recalibration, no solution/batch-colour work, no First 10 content/art/plan change, and no M43+ implementation.
- `coordination/AUDIT_INDEX.md` is retired by the owner tracking lock (`TASKS.md` header; `CLAUDE.md` §0). The builder correctly did not create it, and this audit does not update it.

## 3. Diff scope (independently verified)

Cycle commits after the prompt commit `7363468`:

| Commit | Author role | Paths |
|---|---|---|
| `b3361d1` | owner merge (Codex visual assets) | `assets/ui/final/**`, `assets/ui/VISUAL_ASSET_INDEX.md`, `coordination/codex_visual_assets/**` |
| `825a58b` | Claude | `tests/m54_collection_set_master_exactly_once.gd` (new), `coordination/sessions/M54-C001/CLAUDE_LOG_V01.md`, `…/FIRST10_M54_REGRESSION_MATRIX_V01.md` |
| `b208060` | Claude, non-destructive merge of `origin/main` | no new content on the Claude side |
| `f3b32b5`, `92a6034` | Claude | `CLAUDE_LOG_V01.md` only |

Checks:
- `git diff --name-only 7363468 92a6034 -- scripts scenes data tests project.godot TASKS.md level_factory content_pipeline assets/art` returns only `tests/m54_collection_set_master_exactly_once.gd`.
- `git diff --stat 1376be3 92a6034 -- data scripts scenes level_factory content_pipeline assets/art project.godot` is empty. No production, content or config byte changed since the audited M53-C002 baseline.
- `git diff --check 7363468 92a6034` is clean.
- Root `TASKS.md` is untouched by the builder. The owner's local `project.godot` edit and untracked files were not committed.
- The push was plain, with no force and no history rewrite. The merge commit resolved a real non-fast-forward caused by an owner push during the run, and it is recorded truthfully in log §8.

## 4. Independent runtime evidence (E3)

Environment: `git archive 92a6034` extracted to a clean temp directory, so the owner's local `project.godot` edit was excluded. Ran `godot --headless --path . --import`, then Godot `4.7.2.stable.official.ed1daf0bf` headless. False-green rejection used exit code, line-anchored `FAIL`, line-anchored `SCRIPT ERROR`, and the suite summary line.

| Suite | Exit | ok | FAIL | SE | Result |
|---|---|---|---|---|---|
| `run_tests` (root) | 0 | 5323 checks | 0 | 0 | `RESULT: ALL PASS`; 9 engine `ERROR:` lines = documented baseline (corrupt/nonexistent fixtures) |
| `m54_collection_set_master_exactly_once` | 0 | 192 | 0 | 0 | PASS |
| `m53_first10_difficulty` | 0 | 315 | 0 | 0 | PASS (L1–10 LevelData + plan bytes == M52 owner-accepted evidence; L1 trace replay) |
| `m52_r01_parallel_runtime` | 0 | 79 | 0 | 0 | PASS |
| `m52_r02_early_slot_release` | 0 | 65 | 0 | 0 | PASS |
| `m39a_economy_core` / `m39b_hearts_speed` / `m39c_boosters` / `m39d_daily_collection` / `m39e_full_matrix` | 0 | 38/32/45/34/21 | 0 | 0 | PASS |
| `m40_save_system` | 0 | 38 | 0 | 0 | PASS |
| `m30_completion_authority` | 0 | 52 | 0 | 0 | PASS |
| `m35_level_catalog` / `palette_v3_leveldata_contract` / `m26_scale_59_sanity` | 0 | 20/26/14 | 0 | 0 | PASS |
| `m21_v08_corridor_validation` | 1 | 57 | 2 | 0 | Only C/043 and C/047. These are the historical superseded adjacent-ring assertions (M22 `CHATGPT_AUDIT_V02.md`, `V06.md`; ADR-028). No new failure. |
| `m21_v09_direct_evidence_reconciliation` | 1 | 40 | 1 | 0 | Only B. Same historical classification. |

Every count matches the builder log §4 exactly.

**Not independently rerun:** `m52_owner_supply_plans` (about 22 minutes of real time; this controller session could not run it within its foreground limit). The claim that L2–10 production runtime reaches WON rests on:
1. builder E2 evidence: 255 ok, the same as the M52/M53 audited baseline;
2. independent proof that no production script, scene, data, LevelData, plan or config byte changed since the audited M53-C002 baseline `1376be3`, where the same suite was audited PASS;
3. independent rerun of `m53_first10_difficulty`, which binds L1–10 content and plan bytes to the M52 owner-accepted evidence.

Together this is sufficient for a regression-only cycle with no production change. It is recorded here as a disclosed limitation, not hidden.

## 5. Criteria matrix

| # | Criterion | Evidence class | Result |
|---|---|---|---|
| 1 | No First 10 content/art/supply/owner-solution mutation | SOURCE_PROOF + DIRECT_TEST | PASS (§3 empty production diff; `m53_first10_difficulty` byte binding rerun) |
| 2 | No difficulty recalibration / automated solution / batch-colour work | SOURCE_PROOF | PASS |
| 3 | Every applicable row has exact evidence | DIRECT_TEST | PASS for 21 rows. Row 017 evidence is exact for the configured value, but that value is contested (§1). |
| 4 | Unavailable subsystems labelled NOT_APPLICABLE_CURRENT_BUILD, never fake-PASSed | LOG/GOVERNANCE | PASS. There are 0 N/A rows, and every 001–021 owner system exists. The 016A gap was closed with a real test, not claimed. |
| 5 | Owner First 10 sequences replay | DIRECT_TEST | PASS (L1 replay rerun; L2–10 per §4 limitation) |
| 6 | Production L2–10 reach WON | DIRECT_TEST (E2) + SOURCE_PROOF (no-change since audited baseline) | PASS with disclosed limitation |
| 7 | L1 accepted/playable | DIRECT_TEST | PASS (`m30_completion_authority`, `m53_first10_difficulty` rerun) |
| 8 | M52/R01/R02 regressions pass | DIRECT_TEST | PASS (R01/R02 rerun; M52 per §4) |
| 9 | Root suite: no new unexplained FAIL/SCRIPT ERROR/runtime errors | DIRECT_TEST | PASS (5323 ALL PASS rerun; engine errors = baseline) |
| 10 | Diff hygiene clean | SOURCE_PROOF | PASS |
| 11 | No M43+ scope implementation | SOURCE_PROOF | PASS |

## 6. New test quality (SB-M54-016A)

- `tests/m54_collection_set_master_exactly_once.gd` (131 lines) reads expected rewards from the raw `economy_rewards_v1.json`, not through `EconomyConfig`, so it does not share the implementation's config parsing.
- It covers:
  - each set in isolation;
  - ascending and descending full runs, with the 15th delta = set + master;
  - totals 15850 SB / 167 BP;
  - duplicate cards, `claim_pending_rewards()`, and remove/rebuild of set 7 re-granting nothing.
- The guarded production symbols exist: `_master_claimed` and tx `"collection_master"` in `scripts/collection/collection_inventory.gd`.
- The builder's sensitivity mutation is plausible and targets the right invariant. This audit did not re-execute it, so it remains E2. Production restoration is independently confirmed by the empty production diff.

## 7. Claims versus truth

- "22 rows PASS": 21 rows accepted. Row 017's "PASS — interval spec conflict flagged" is correctly self-flagged, and the builder did not hide it. The conflict is real and verified above.
- "No content bytes changed": confirmed independently.
- "Historical M21 V08/V09 failures only": confirmed; failure lines are identical.
- "Root 5323 ALL PASS": confirmed.
- Log truthfulness: the merge and non-fast-forward are recorded honestly. The log states that criteria were initially uncited and were reconciled later.

## 8. Findings

| ID | Severity | Finding | Owner |
|---|---|---|---|
| M54-C001-F01 | Owner gate | Heart regen interval conflict: V06 900 s vs FAILURE_RECOVERY V01, `player_experience_plan_v1.json`, `MASTER_UI_SYSTEM.md` and `TASKS.md` row 017 (1800 s). | OWNER |
| M54-C001-F02 | Low (doc/config drift) | Two configs disagree on the Heart interval (`economy_rewards_v1.json` 900 s, `player_experience_plan_v1.json` 30 min). Whichever loses the ruling must be reconciled. | ChatGPT (tracker/docs) or CLAUDE (config), per the ruling |

No production defect, regression, SCRIPT ERROR, or false-green suite was found.

## 9. Sequencing note

The `TASKS.md` header says the roadmap resumes at M43 after the First 10 block closes. The owner's controller directive of 2026-09-27 orders an M54 → M55 (Chaos / Long-Run QA) transition once M54 passes. The controller will follow the owner directive at transition and reconcile the tracker text then. No M55 or M43 package is issued while M54 is owner-gated.

## 10. Confidence / regression risk

- Confidence: high for the 21 accepted rows. Regression risk from this cycle is nil: the only code-side change is one additive test file.
- Unverified in this audit: a rerun of `m52_owner_supply_plans` and a rerun of the builder's sensitivity mutation (both E2; see §4 and §6).

## Final verdict

`OWNER_REQUIRED / M54-C001 / SB-M54-017 HEART REGEN INTERVAL` — 21/22 rows `AUDITED_PASS`. Awaiting the owner's ruling on 900 s versus 1800 s.
