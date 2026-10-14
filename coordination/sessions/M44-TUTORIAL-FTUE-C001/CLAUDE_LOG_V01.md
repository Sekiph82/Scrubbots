# M44 FTUE master — CLAUDE_LOG_V01

Prompt: `CHATGPT_M44_MASTER_PROMPT_V01.md` · criteria: `CHATGPT_M44_AUDIT_CRITERIA_V01.md` · owner: `OWNER_M44_FIRST3_STARTER_AND_CLAIM_DECISION_V03.md`
Implementer: Claude Code (Opus 5.5) · Dates: 2026-10-12 start, 2026-10-14 CI + handoff

**Status: `CLAUDE_IMPLEMENTED_CI_PASS_AWAITING_CHATGPT_AUDIT_AND_OWNER_VISUAL_GATE`** (no self-awarded AUDITED_PASS; `OWNER_VISUAL_PLAYTEST_PENDING` for SB-M44-018 / 020).

## 1. Start state / owner-state preservation (G0)

- Repo `Sekiph82/Scrubbots`, branch `main`, single checkout `C:\Users\sekip\Desktop\ScrubBots`. No worktree, clone, scratch workspace or local Godot run.
- Start: local `main` was 17 behind; fast-forwarded to `origin/main` = `aef60a61` (incoming files did not overlap owner-dirty paths).
- Owner state at start AND end (re-checked 2026-10-14): `project.godot` SHA-256 `d2546c0bb7d3daccce6c803252a2bf72ddd2359ee1e61abcaa02ca2b98e63574` (unchanged, never staged); 4 owner tracked modifications (`project.godot`, `scenes/app/main.tscn`, two owner-review `.tscn`) untouched; 2,616 untracked files; 2 stashes. Only task files were staged.
- Root `TASKS.md`, owner decisions and ChatGPT prompt / criteria files: not edited.
- `CLAUDE.md §0A` (2026-10-12 cloud-first, ≤ 20 MiB incidental TEMP) applied: all Godot import / test execution ran on GitHub-hosted runners.

## 2. Commits (all on `main`)

| SHA | Content |
|---|---|
| `8a132edb` | Source: FTUE state, fresh-profile bootstrap, Welcome task, durable first-Home claims, director, coachmark overlay, Help & Tips, What's New, data config, docs/16 implementation note |
| `0c8a7d83` | Permanent `tests/m44_ftue.gd` (21 cases) + existing Android workflow: M44 added to `validate`, exact 21/21 guard |
| `f567947f` | Test-only fix: t17 / t01 established-save fixtures use a real L1 first-clear (see §4 run 1) |
| (this log) | `CLAUDE_LOG_V01.md` |

Files: `scripts/economy/ftue_state.gd` (new), `scripts/app/ftue_config.gd` (new), `scripts/app/ftue_director.gd` (new), `scripts/ui/tutorial/coachmark_layer.gd` (new), `scripts/ui/tutorial/help_tips_screen.gd` (new), `data/config/ftue_onboarding_v1.json` (new), `scripts/app/app_state.gd`, `scripts/app/main.gd`, `scripts/economy/daily_service.gd`, `scripts/economy/economy_services.gd`, `scripts/economy/production_action_facade.gd`, `scripts/save/save_service.gd`, `scripts/ui/daily/daily_screens.gd`, `scripts/ui/settings_panel.gd`, `scripts/ui/ui_text.gd`, `docs/16_FTUE_FEATURE_UNLOCK_AND_RETENTION_SURFACES.md`, `tests/m44_ftue.gd`, `.github/workflows/android-family-first10.yml`.
Not touched: level files / art, SupplyPlans, catalog, routing, solver, difficulty, `economy_rewards_v1.json` (`daily.task_sb` still `[75, 100, 125]`), opening cinematic, Home art / four-panel layout, Level Factory, content pipeline, R2.

## 3. Implementation by functional group

### M44-A — fresh profile, starter economy, genuine claims (001, 006, 010, 011, 013, 015, 016, 019 + V03)
- **Conclusive fresh detection**: `SaveService.load()` returns `fresh: true` only on the defaults path when NO primary, `.bak`, `.tmp` or legacy M33 audio cfg exists. Corrupt / unreadable / backup-recovered / future-schema / migrated saves are never fresh (CI t01).
- **`AppState.bootstrap_new_profile()`** (called once per cold launch by the app root): only when fresh and no save file written since; in one transaction marks the FTUE profile `new`, grants `booster_charge_<id>` ×2 for all four boosters through `RewardGrantService` under the single tx `ftue_starter_boosters:v1`, and installs the Welcome task; then saves. Save failure re-imports the exact pre-bootstrap economy and leaves the bootstrap pending; it is retried (inside `request_save`) only while no save file exists, so no later save can persist a starter-less fresh profile. Idempotent replay (t02–t04).
- **Welcome task**: `DailyService.set_first_day_welcome(day, 100)` marks index 0 done on the profile's first local day only; `task_reward_sb(i)` is the single shown == credited value (100 on that day for index 0, else the unchanged `_task_sb` tier). Persisted as the optional strict pair `welcome_day` / `welcome_sb` (absent on every other save). Same tx id family `daily_task:<day>:0`, so the slot can be claimed once; it expires at rollover, never revives on rollback (t06, t07). Still exactly 3 slots; ScrubBox needs 3/3 real completions and pays its one Mystery Booster once (t06).
- **Durable first-Home claims**: `ProductionActionFacade.claim_daily_login` / `claim_daily_task` now commit with their save; a save reporting failure re-imports the pre-claim economy snapshot and refuses (`reason: save_failed`), badges stay (t08). A save callback that returns no result (unbound harness) behaves exactly like before.
- Both orders 1,000 → 1,100 → 1,200, separate ledger txs, no Gift / streak / first-clear effect, repeat / relaunch refused (t05, t09, t14).
- **FTUE state** (`ftue` economy section): `{version, profile ""|"new", skipped, closed, seen[]}`, strict when present; absent (pre-M44 save) = established (t10).

### M44-B — ≤ 3-level onboarding on real mechanics (001–009, 016–018)
- `data/config/ftue_onboarding_v1.json` + strict `FtueConfig` (whole file rejected on any defect; `max_tutorial_level` ≤ 3 enforced; lesson levels > max rejected): Home (DAILY / TASKS / PLAY tips with truthful `when` conditions), L1 `m21_level_001_hazard_bot` (front tap → completes only on a REAL accepted placement; rightmost-empty slots; front vs preview; cleaning), L2 `level_002_apple` (two phases: +1 Slot + Selector, Random + Tornado, real names / effects / live owned counts; "Not usable right now." appended from the host's real `booster_legality`), L3 `level_003_palm_tree` (no-path waiting info, Hearts / Retry / Need a Hand info, paid 2x vs free automatic endgame 2x info).
- `FtueDirector`: one step at a time; only on the PROGRESSION attempt of that exact catalog id; the window closes on Home / Results once the frontier passes L3 (settles even with unacknowledged optional steps); L4–L10 have no step even with the window forced open (t13, t15).
- No booster / 2x / Heart / win / loss is ever triggered by a tip (t15, t16, t21 source guard).

### M44-C — presentation, durability, feature state, 010–024
- `CoachmarkLayer` (CanvasLayer 40, below ModalStack 64): approved `tutorial_highlight_ring.png`, `tutorial_pointer.png`, `speech_bubble.png` only; everything `MOUSE_FILTER_IGNORE` except GOT IT / SKIP TIPS (88 px); bubble placed on the free side and shrunk so it never covers the target; text auto-fit; hidden under any popup / Settings / Results / Opening; Reduced Effects = no pointer motion; tweens killed on hide / exit (t18, t19).
- **Skip Tips** = tips only (never the cinematic, rewards or inventory), persisted once (t16). **Help & Tips**: Settings header "?" (replaces the invisible balance spacer, same 88 px, panel height unchanged) → read-only popup with rules + four boosters (live counts), single CLOSE action, writes nothing (t16).
- **What's New**: established profiles see the M43-C005 Feature Unlock ceremony for `help_tips` v1 once on a quiet Home (key `feature:help_tips:1` in MetaUiState, acknowledged only by its CTA) (t17). New profiles get tips instead.
- Soft discovery: all four Home panels live from first Home; no hard lock; numeric claim badges are the existing HomeBadges truth (t14).

### M44-D — tests, CI, source freeze
- `tests/m44_ftue.gd`: 21 cases / 153 assertions against real services and the real app root. Test seam `main.boot_ftue_override` (-1 auto = ON for the canonical shipping save path, OFF for injected test paths so the legacy suites keep their exact fresh fixtures; 1 = on). Production passes nothing → always ON. The M44 suite runs with it ON.

## 4. CI evidence (existing workflow, `mode=validation_only` only; 2 of max 3 runs)

| Run | SHA | validate | export | Result |
|---|---|---|---|---|
| [38625474342](https://github.com/Sekiph82/Scrubbots/actions/runs/38625474342) | `0c8a7d83` | failure | **skipped** | 16/16 prior suites PASS, import `script_diag=0`; `m44_ftue` 20/21: only t17 failed — its fixture used `debug_set_current_level(2)` without history, which the canonical progression import rejects, so the "established" save was never written and the boot was fresh (+1 script error from the test dereferencing a null top popup). Test-only fix in `f567947f`. |
| [38626611950](https://github.com/Sekiph82/Scrubbots/actions/runs/38626611950) | `f567947f` | **success** ([job 116067261731](https://github.com/Sekiph82/Scrubbots/actions/runs/38626611950/job/116067261731)) | **skipped** ([job 116071089038](https://github.com/Sekiph82/Scrubbots/actions/runs/38626611950/job/116071089038)) | **aggregate=PASS** |

Run 38626611950 summary (verbatim):
```
mode=validation_only sha=f567947f0f20e9b2af677ba1f479171361a60a4c (validation_only => no APK/PCK built)
import script_diag=0
m35_level_catalog ... PASS | m37_level_progression ... PASS | m55_long_session ... PASS
m43_c005f_phase4_terminal_home_micro ... PASS (19/19 cases, 0 fail)
m43_c001a_results_foundation ... PASS (11/11 cases, 0 fail)
m42_navigation PASS | m42_home PASS | m40_save_system PASS | m40_v04_bootstrap PASS
cp04_remote_content_runtime PASS (28/28) | cp05_remote_content_cache PASS (15/15)
m55_economy_release_regression PASS | run_tests RESULT: ALL PASS
cp05_r01_transaction_cleanup PASS (6/6) | remote_content_family_fixture PASS | cp06_disabled_levels PASS (16/16)
m44_ftue exit=0 script_diag=0 status=PASS | M44 FTUE evidence: PASS (21/21 cases, 0 fail)
CP06 verdict=PASS (16/16)
M44 verdict=PASS (21/21)
aggregate=PASS
```
- Artifact `11925065328` (52,451 bytes): 19 files = 17 suite logs + `summary.txt` + `import.log`; **no `.apk` / `.pck` / `.ipa`**. `export` job skipped at job level (no keystore, templates or build). Logs were read in memory (`gh api … | python -B`), nothing downloaded to disk.
- Workflow readback from GitHub before dispatch: `default: validation_only`, export `if: ${{ inputs.mode == 'build_apk' }}`, M44 in loop. 16 prior suites, CP06 exact 16/16 guard, manual trigger, export guard unchanged.

## 5. SB-M44-001..024 status (implementer view; ChatGPT decides)

| ID | Status | Evidence / note |
|---|---|---|
| 001 | IMPLEMENTED | cold launch → Home → L1–L3 per owner V03 (supersedes the "first 10" row wording) — t02, t14, t15 |
| 002 | IMPLEMENTED | L1 real front tap tip completes only on a real placement — t12, t15 |
| 003 | IMPLEMENTED | rightmost EMPTY slot asserted against the engine — t15 |
| 004 | IMPLEMENTED | front-only vs preview rows tip on the real preview rows — t15 |
| 005 | IMPLEMENTED (truthful info) | L3 one-line no-path explanation; NOT triggered by observing a stall (no forced wait). Observation-triggered variant not built. |
| 006 | IMPLEMENTED (info) | L3 Hearts / Retry / Need a Hand info; real first-fail / Need a Hand flows unchanged |
| 007 | IMPLEMENTED per V03 | all four at L2 in two compact phases; starter 2 each |
| 008 | IMPLEMENTED per V03 | real controls, real counts, real legality text; optional real use only; NO tutorial fixtures / injected states (owner V03 forbids staging) |
| 009 | IMPLEMENTED (info) | L3 paid manual/timed 2x vs free automatic endgame 2x; no product granted / started — t15 |
| 010 | PARTIAL — owner-gated | data `feature_discovery` = soft, no locks, all implemented destinations from first Home; exact future unlock levels (Events / Ranks / Achievements) remain OWNER_TUNING_REQUIRED |
| 011 | IMPLEMENTED | versioned data, no invented unlock levels — t11 |
| 012 | IMPLEMENTED | M43-C005 Feature Unlock once per feature/version (Help & Tips) — t12, t17 |
| 013 | NOT EXERCISED / DEPENDENCY_GATED | no newly unlocked Home destination exists in this build (all four panels from first Home), so no NEW chip was added; nothing hides a claim badge |
| 014 | IMPLEMENTED (owner presentation default) | Skip Tips + read-only Help; never duplicates rewards — t16 |
| 015 | IMPLEMENTED | What's New for established saves, no beginner overlay — t17 |
| 016 | IMPLEMENTED | non-blocking overlay, no pause, no state injection — t15, t18, t21 |
| 017 | IMPLEMENTED | UiText keys (English table only; no new translations shipped); ring + arrow + text cue |
| 018 | OWNER_VISUAL_PLAYTEST_PENDING | only approved existing art reused; no new art generated |
| 019 | IMPLEMENTED in CI | fresh / migrated / corrupt / backup / future / skipped / relaunch / lifecycle flush / popup — t01, t03, t04, t16, t17, t19; real-device background still part of the owner playtest |
| 020 | OWNER_VISUAL_PLAYTEST_PENDING | no build authorized by this master |
| 021 | EXISTING AUTHORITY, verified | M43-C001R journey / Next Cleanup unchanged, canonical resolver, no tutorial wall — t20 |
| 022 | DEPENDENCY_GATED (M43) | Set 1 / earned-pack presentation unchanged; nothing added or fabricated |
| 023 | PARTIAL | Daily Scrub Orders live day one (t20); Weekly / First-Try remain at existing EventService authority, no fabricated activation |
| 024 | IMPLEMENTED / verified | Comeback never on a fresh profile (existing ReturnService rule) — t20 |

## 6. Concerns / not run / owner gates

- **Not run in CI** (outside the existing 17-suite loop): M39 specialized booster / Daily / economy suites, `m41_settings`, `m43_r15_owner_remediation` (Settings layout matrix), `m43_master_c009_daily`, other M43 master suites. Static review found no assertion they should break (FTUE is off for injected test paths; the Settings "?" occupies the existing 88 px header spacer; claim results only gain keys), but they are unverified on CI — flag for the auditor.
- `boot_ftue_override` auto rule (canonical path only) is a test seam; production behaviour is unconditional.
- What's New is also shown to saves written by current builds that never bootstrapped (profile ""), i.e. any existing player — intended.
- Coachmark visual language, copy and placement are a presentation default awaiting owner phone review; layout was verified headless at 1080×2160 / 1080×1920 / 1080×2400 / 1536×2048 / 720×1280 only.
- Headless exit noise lines (`at: clear (core/io/resource.cpp:822)`) appear in the M44 log as in other suites; not script diagnostics (`script_diag=0`).

## 7. Disk / TEMP accounting (§0A)

- No local Godot import / test, no `user://` fixtures, no clone / worktree / scratch workspace, no artifact download, no heredoc.
- Deviation (disclosed): on 2026-10-12 a slow foreground status command (`du` over `%LOCALAPPDATA%\Temp`) exceeded 120 s and the harness auto-backgrounded it, writing `…\Temp\claude\C--Users-sekip-Desktop-ScrubBots\4895cd12-…\tasks\btq9fpv55.output` (232 bytes). It was stopped, measured, and that exact file deleted.
- End state of this session's harness folder `…\Temp\claude\C--Users-sekip-Desktop-ScrubBots\4895cd12-1162-4b6c-a984-4c78a461de56`: ~1 KiB (an empty harness-created `scratchpad` dir and the currently running command's 0-byte output file). Far below 20 MiB; left for the harness to manage (active session).
- `C:` free space: 146,635,844 KiB (2026-10-12 start) → 84,476,480 KiB (2026-10-14). That ~59 GiB drop is NOT from this task (its observable footprint is ~1 KiB plus ~0.1 MiB of committed source); it happened between sessions from other processes. Not investigated or cleaned (not task-owned) — flagged for the owner.

## 8. Handoff

`CLAUDE_IMPLEMENTED_CI_PASS_AWAITING_CHATGPT_AUDIT_AND_OWNER_VISUAL_GATE` · `OWNER_VISUAL_PLAYTEST_PENDING` (SB-M44-018 / 020). No APK / IPA built. Root `TASKS.md` untouched.
