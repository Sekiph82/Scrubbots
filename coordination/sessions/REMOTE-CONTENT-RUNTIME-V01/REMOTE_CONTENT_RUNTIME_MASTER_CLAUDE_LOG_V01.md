# CP04/M15 + CP05/M16 — REMOTE CONTENT RUNTIME MASTER — CLAUDE LOG V01

Prompt: `coordination/sessions/REMOTE-CONTENT-RUNTIME-V01/CHATGPT_MASTER_PROMPT_V01.md`
Criteria: `CHATGPT_AUDIT_CRITERIA_V01.md` · Gate acceptance: `CHATGPT_CP03_M14_GATE_ACCEPTANCE_V01.md`

Root `TASKS.md` was read only and never edited. Every status here is Claude's implementation claim, not an audit PASS.

## Start gate / sync

**Environment (truthful).**
- This ran in a Claude Code cloud container on a clean clone of `Sekiph82/Scrubbots`, **not** in the owner-local `C:\Users\sekip\Desktop\ScrubBots`, which this session cannot reach. The prompt asks the builder to work from that path; that was impossible here.
- **Owner-local preservation:** no owner-local `project.godot` edit, `scenes/app/main.tscn` change, `addons/`, `.mcp.json` or editor/plugin file existed in this clone, and none was created, staged or modified. `project.godot` is **not** changed by this work.
- **Editor sidecars:** headless `--import` creates `.import` / `.uid` sidecars. They are never staged; the repo does not track them.

**Sync.**
- Session branch `claude/practical-darwin-ndbmxa`: `git fetch origin main`, then a plain fast-forward from `5200f02` to `origin/main` = **`e36e0238adcf2241af45a3d217eb459e5fc6b83f`** (0 ahead / 12 behind before the fast-forward).
- No reset, clean, force, stash or history rewrite.

**External gate (verified before implementation).**
- **Clone:** I cloned `Sekiph82/ScrubBots-Level-Factory` read-only. HEAD = **`16ee1f3f09694d7663e0aa8a39560e8555d12fb8`**, which equals the verified LF main.
- **Audit files present at that SHA:**
  - `.hiveai/audits/M14_CP03_001_012_CPX002_FINAL_CLOSURE_STRICT_REAUDIT.md` (sha256 `e35a3582…0588`);
  - `.hiveai/audits/SB-CPX-002-C001-R01_TEMP_ONLY_AUTHORITY_EVIDENCE_STRICT_REAUDIT.md` (sha256 `9a3ad7ab…aa5d`).
- **No drift:** `EXTERNAL_GATE_EVIDENCE_DRIFT` does not apply.
- **Authority continuity:**
  - between the gate SHA `2fd60ae` and the implementation base `e36e023`, ScrubBots changed **docs only**: `TASKS.md` and the gate/prompt files of this session;
  - no game code or data changed.
- **Contracts inspected:**
  - `docs/content_platform/REMOTE_CONTENT_MANIFEST_V1.md` and `SCRUBPACK_V1_SPEC.md`;
  - the JSON schemas;
  - `manifest_parser.py`, `manifest_v1.py`, `manifest_validation.py`, `scrubpack_spec.py`, `scrubpack_tools/inspection.py` and `payload_validation.py`;
  - the canonical requirement text for CP04-001..014 and CP05-001..012 (LF `TASKS.md` §CP04/§CP05).
- **No invented protocol:** no temporary publisher protocol was invented, and SB-CPX-004 was not touched.

## Children

| Child | Status | Log |
|---|---|---|
| SB-CP04-001..014 (M15) | READY_FOR_INDEPENDENT_AUDIT; CP04-011 = **READY_FOR_ANDROID_EXPORT_GATE** | [log](SB-CP04-001_014_CLAUDE_LOG_V01.md) |
| SB-CP05-001..012 (M16) | READY_FOR_INDEPENDENT_AUDIT | [log](SB-CP05-001_012_CLAUDE_LOG_V01.md) |

## Files changed

**New:**
- **Runtime** (`scripts/content_runtime/`):
  - `remote_content_manager.gd`
  - `https_content_transport.gd`
  - `content_manifest_v1.gd`
  - `scrubpack_v1.gd`
  - `strict_json.gd`
  - `composite_level_catalog.gd`
- **Config:** `data/config/remote_content_runtime_v1.json`.
- **Tests and tools:**
  - `tests/cp04_remote_content_runtime.gd`
  - `tests/cp05_remote_content_cache.gd`
  - `tests/remote_content_family_fixture.gd`
  - `tests/support/scrubpack_fixture.gd` (test-only)
  - `tests/tools/export_remote_content_fixture.gd`
- **Fixture:** `tests/fixtures/remote_content/content-manifest-minimal.json`, byte-exact from LF.
- **Logs:** the three logs in this directory.

**Modified (narrow):**
- `scripts/app/app_state.gd`: `content`, `playable_catalog()`, composite `orders_context()`, and an optional `content_root` argument;
- `scripts/app/gameplay_launch_resolver.gd`: the default catalog is now the composite;
- `scripts/app/main.gd`: one background refresh when the config is enabled.

**Not modified:**
- builtin `LevelCatalog` / `res://data/levels/catalog/production_catalog_v1.json`;
- `LevelLoader`, `LevelValidator`, `ProductionLevelValidator`, `SupplyPlanLoader`;
- the gameplay host, save, progression and economy code;
- `project.godot`, export presets and every closed test.

## End-to-end family fixture (`tests/remote_content_family_fixture.gd` → PASS, 0 fail)

Local synthetic data only (not the owner's real 11–50):

1. **Builtin.** Levels 1–10, orders 1..10, all `res://`.
2. **N = 1.** Pack `fam-a` = remote 11–12 is downloaded, verified and activated. Frontier 10 resolves builtin, 11 resolves `family_level_011` under the content root, and 12 resolves `family_level_012`.
3. **Real gameplay host.** The real `ProductionGameplayHost` builds level 11 from the remote LevelData. It loads the registry-verified level and supply-plan bytes, and its live supply equals the exact remote plan engine.
4. **Offline relaunch.** A new `AppState` boots offline: frontier 11 still resolves from the cached LKG, and an offline refresh keeps it playable.
5. **N + 1.** Level 13 is appended in pack `fam-b`. **Only `fam-b` is downloaded.** 11 is unchanged and 13 resolves.
6. **N + 2, two hostile candidates:**
   - a tampered pack → `PACK_SHA256_MISMATCH`;
   - a correctly hashed pack carrying `levels/…/run.gd` → `INVALID_MEMBER_LAYOUT`.

   In both cases the N + 1 registry stays byte-identical and active, 13 stays playable, 14 is truthfully `CONTENT_MISSING`, nothing is installed, and a relaunch reconstructs N + 1.

**Cross-implementation evidence (LF main `16ee1f3`, local, reproducible):**
- **Game fixture → LF tools:** LF `parse_content_manifest_v1` accepts the game fixture manifest. LF `inspect_scrubpack` returns `VALID` for both fixture packs, with matching SHA-256 and length.
- **LF tools → game runtime:** a pack built by **LF's own `build_scrubpack`**, plus a manifest from LF `to_json_bytes`, is accepted unchanged by this runtime (`ACTIVATED`).

## Tests (Godot 4.7.2 headless, final tree; each exit 0, 0 `SCRIPT ERROR`)

| Suite | Result |
|---|---|
| `cp04_remote_content_runtime` | **PASS 28/28** |
| `cp05_remote_content_cache` | **PASS 15/15** |
| `remote_content_family_fixture` | **PASS** |
| m35_level_catalog · m35_v02_hardening | PASS · PASS |
| m37_level_progression · m37_v02_strict · m37_v03_forward_only | PASS ×3 |
| M40: m40_save_system · m40_v02_safety · m40_v03_canonical · m40_v04_bootstrap | PASS ×4 |
| M52: m52_owner_supply_plans · m52_r01_parallel_runtime · m52_r02_early_slot_release | PASS ×3 |
| M53: m53_first10_difficulty | PASS |
| M53: m53_c002_difficulty_calibration | **FAIL (1), pre-existing.** The one failing check is "fresh run == committed corpus raw". It fails identically on an untouched `e36e023` worktree. It does not use AppState, the resolver or `content_runtime`. A follow-up task was suggested; it was not fixed here (out of scope). |
| M43 order context: m43_master_c009_daily 12/12 · m39d_daily_collection | PASS · PASS |
| Also: m43_c004_c001_fail_need_a_hand 40/40 · m42_home · m42_navigation · m43_r15_owner_remediation 18/18 · m55_economy_release_regression | all PASS |
| **Root `tests/run_tests.gd`** | **RESULT: ALL PASS — Total checks 5329**, 0 script errors |

**Not used:** no public internet. All transport in the tests is the injected `FakeTransport`.

**`git diff --check`:** clean.

**Expected engine warning:** CP04 c05 deliberately feeds `1e999`, so Godot prints one "Exponent too high" warning before the reader rejects the value as non-finite. There are no other unexplained ERROR or WARNING lines, beyond Godot's usual exit-time leak lines, which also appear at baseline.

## Remaining gates (truthful; not closed by this run)

**Android Family APK (CP04-011 → `READY_FOR_ANDROID_EXPORT_GATE`).** The repo tracks no Android export preset (`export_presets.cfg` is gitignored; an owner-local one, if any, is not visible here). That later task must:
- create and validate the Godot 4.7.2 preset with the INTERNET permission;
- keep signing secrets out of Git;
- set `application/config/version` (strict `MAJOR.MINOR.PATCH`).

Until the version exists, the runtime fails closed by design: builtin play only.

**CDN / production endpoint.** `manifest_url` / `object_base_url` are empty and `enabled` is false. Enabling remote content means filling in two HTTPS URLs in `data/config/remote_content_runtime_v1.json`; no code change is needed.

**CP06.** Non-empty `disabled_levels` / `schedules` are refused (`UNSUPPORTED_RUNTIME_SEMANTICS`, LKG kept) until CP06 runtime semantics are accepted.

**SB-CPX-004** remains deferred after M15/M16, as the gate record states.

## Branch / main state

This session may push only its designated branch, so `main` was not pushed. The branch is `claude/practical-darwin-ndbmxa`, based on `origin/main` `e36e023`. The final SHA and ahead/behind are in the handoff message. `main` can take it as a plain fast-forward.

AWAITING_GPT_REMOTE_CONTENT_RUNTIME_V01_AUDIT
