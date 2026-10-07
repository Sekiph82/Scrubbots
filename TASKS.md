# ScrubBots — Canonical GitHub Task State

This root TASKS.md is the **only** authoritative project-status tracker and the **only project-status file consumed by the H!veAI parser**. GitHub repository metadata and the latest commit are the remaining project-truth inputs. No parallel session index, roadmap, audit index, dashboard, hidden control-plane tracker, or equivalent status mirror is permitted.

## Project Status

- Current Milestone: REMOTE LEVEL UPDATE / CONTENT RUNTIME PRIORITY
- Current Sprint: CP07/M18 — Cloudflare R2 Storage/CDN Integration
- Current Task: CLOUDFLARE R2 — OWNER-LOCKED PROVIDER / PROVISIONING + ENDPOINT BINDING NEXT
- Current Task Status: REMOTE_RUNTIME_PASS / M53_C002_R02_PASS_CLOSED / CLOUDFLARE_R2_OWNER_LOCKED / CP07_SETUP_PENDING
- Next Task/Action: **Provision and bind Cloudflare R2 as the locked storage/CDN provider for Remote Level Update.** First create/confirm the owner R2 account + bucket and one public read endpoint contract for production/family content; keep all write credentials outside Git and outside the APK. Then bind the non-secret manifest/object read URLs into ScrubBots runtime config, bind the Level Factory publisher to the same R2 bucket through server-side/S3-compatible write credentials, prove end-to-end manifest + missing `.scrubpack` download/verify/LKG behavior, and only then open the Android Family APK export gate. No unrelated M43 work.
- Required Actor: OWNER + CHATGPT (R2 provisioning/authority), then CLAUDE/CODEX for integration
- Tracking Repository: Sekiph82/Scrubbots
- Tracking Branch: main
- Owner Priority Decision [2026-10-07]: **Remote Level Update / Family APK continues to supersede new M43 work until the pipeline is usable end-to-end. Cloudflare R2 is now OWNER-LOCKED as the storage/CDN provider.** Closed chain: CP01/M12 `.scrubpack` → CP02/M13 manifest/versioning → CP03/M14 publisher core → CP04/M15 Godot RemoteContentManager → CP05/M16 offline/LKG → M53 clean-regression remediation. Remaining locked order: **Cloudflare R2 CP07/M18 provisioning + read-endpoint contract → Level Factory/Pixel Art Factory `Publish to ScrubBots` handoff onto that same R2 authority → ScrubBots production non-secret manifest/object URL binding → end-to-end remote publish/download verification → Android Family Test APK**. R2 write credentials are publisher-side secrets only and must never enter Git or the APK. Installed family builds must discover Level 11–50, download only missing verified packs, validate SHA-256/schema/LevelData/supply identity, install under `user://content/`, and continue offline from last-known-good. **Remote executable content remains forbidden**.
- Remote Content Runtime V01 preparation [2026-10-06]: ChatGPT published one sync-first CP04/M15 + CP05/M16 master prompt and matching audit criteria under `coordination/sessions/REMOTE-CONTENT-RUNTIME-V01/`. Game-side V1 locks builtin catalog immutability, manifest-declared remote append order, append-only successor safety, `user://content/` confinement, strict declarative `.scrubpack` validation, composite catalog/gameplay resolution, and last-known-good offline recovery. Execution is gated only by final CP03/M14 publisher contract closure; no game code implementation has started yet.
- CP03/M14 external gate ACCEPTED [2026-10-07]: ChatGPT independently verified LF `main` `16ee1f3f09694d7663e0aa8a39560e8555d12fb8`, `SB-CPX-002-C001-R01 = PASS / CLOSED`, and `M14 CP03/CPX-002 PUBLISHER CORE = PASS / CLOSED`. The replayed ScrubBots authority SHA `2fd60ae69055c6c26c1f5f1b9d3869c743093786` was still exact current ScrubBots `main` at acceptance (0 ahead / 0 behind / 0 changed files). Gate record: `coordination/sessions/REMOTE-CONTENT-RUNTIME-V01/CHATGPT_CP03_M14_GATE_ACCEPTANCE_V01.md`. **CP04/M15 + CP05/M16 execution is authorized now.**
- Remote Runtime strict V01 audit [2026-10-07]: `coordination/sessions/REMOTE-CONTENT-RUNTIME-V01/CHATGPT_INDEPENDENT_AUDIT_V01.md` evaluates branch `e8662583fe24e9edf17ca595e45d34df778ada75` (1 ahead/0 behind at audit) and returns **CHANGES_REQUIRED / R01**. While CP04 28/28, CP05 15/15, family fixture and root 5329 ALL PASS were builder-reported, source review found that a failed multi-pack candidate can leave a previously verified but unreferenced candidate pack in final `packs/` until later boot. CP05-R01 must clean candidate-owned final directories immediately while never deleting active/LKG. **Do not merge or mark CP04+CP05 fully CLOSED before R01 re-audit.**
- M53-C002 standalone baseline regression [2026-10-07]: `tests/m53_c002_difficulty_calibration.gd` fails one `fresh run == committed corpus raw (timing excluded)` assertion on untouched `e36e023`, independently of Remote Runtime. This is not a CP04/CP05 product-code regression, but it violates a requested broader regression gate and must not be falsely reported PASS. Queued `SB-M53-C002-R01-001` investigates exact raw-record drift and repairs code or, only with independently audited change authority, regenerates provenance-bound QA evidence. No production Difficulty V2 adoption is implied.
- CP05-R01 strict re-audit PASS [2026-10-07]: source implementation `19618f6e` closes same-transaction candidate-pack leakage via staging-until-commit and narrow rollback; six new adversarial cases, CP04 28/28, CP05 15/15, family fixture and root 5329 ALL PASS are recorded. Integrated with QA-only M53 diagnostic evidence through PR #8; merged main `09f320044abc0424c6a9916cdbbce4eec047b820`. Audit: `coordination/sessions/REMOTE-CONTENT-RUNTIME-V01/CHATGPT_CP05_R01_REAUDIT_V01.md`.
- M53-C002 R01 diagnostic decision [2026-10-07]: ChatGPT accepts the root-cause classification as platform-dependent float-to-text evidence serialization, not gameplay/analyzer regression, and selects **Option A**. A serialization-only platform-independent full-precision re-freeze is authorized under `coordination/sessions/M53-C002/CHATGPT_SERIALIZATION_AUTHORITY_DECISION_V01.md`; any decision-level/owner-facing semantic drift must STOP / GPT_REQUIRED.
- M53-C002 R02 strict audit PASS [2026-10-07]: implementation `f77f087a928eca5ed76c42c20639a7231c657b1c` is accepted and merged through PR #9. The exact determinism assertion remains intact; machine-readable evidence reports `allInvariantsHold=true`, 343/343 old/new derived attributions reproduce, fixture/supply/manifest identities remain unchanged, and no owner-facing decision changed. Audit: `coordination/sessions/M53-C002/CHATGPT_R02_STRICT_REAUDIT_V01.md`. **SB-M53-C002-R01-001 CLOSED.**
- Storage/CDN OWNER LOCK [2026-10-07]: **Cloudflare R2** is the canonical Remote Level Update storage/CDN provider. Provider selection is no longer open. Publisher write credentials stay outside Git/APK; ScrubBots receives only non-secret HTTPS read endpoints. The exact bucket name, public read hostname/custom-domain choice and credentials are provisioning outputs, not hard-coded owner decisions yet.
- Progress: 997 / 1442 = 69.14%. SB-M53-C002-R01-001 is strict PASS/CLOSED and merged; Remote Content Runtime clean-regression gate is clear. Cloudflare R2 is owner-locked as the next Remote Level Update infrastructure authority. M43 R15-001 sequential-unlock change remains parked.
- R15-004 owner-placement follow-up audit PASS [2026-10-06]: `coordination/sessions/M43-OWNER-R15/CHATGPT_AUDIT_R15_004_OWNER_F5_PLACEMENT_V01.md` accepts implementation `5200f024b0fbac449a5ac080748392beb27cf201`, merged with the newer Remote Level Update tracker state through PR #7; merged main integration SHA `15a7c3441c97262d505c4f1d0ed32b3acbbab38b`. Rewarded Ads is now under COLLECTION at exactly 210×156, matching SHOP/COLLECTION, with a one-line code-rendered label; functional Rewarded Ads authority remains unchanged. **SB-M43-R15-004 remains OPEN only for OWNER F5 visual acceptance and stays parked behind the Remote Level Update priority.**
- SB-M43-R15-004 final OWNER VISUAL PASS [2026-10-06]: owner explicitly accepted the latest Home placement (`yerlesim ok`). **SB-M43-R15-004 is CLOSED.**
- Rewarded Ads sequence OWNER LOCK [2026-10-06]: Slot 1 direct CLAIM → Slot 2 WATCH AD → after verified grant unlock Slot 3 → after verified grant unlock Slot 4 → after verified grant unlock Slot 5. Future slots cannot be started early; no-grant outcomes do not advance. No Home badge is required. This updates SB-M43-R15-001 and is intentionally parked behind the active Remote Level Update priority.
- R15-004 independent technical audit PASS [2026-10-06]: `coordination/sessions/M43-OWNER-R15/CHATGPT_AUDIT_R15_004_V01.md` accepts code commit `1de7775` / final Claude branch `f2a6125ea9823d4bf8c0c49d7543087fe7d17917`, merged by fast-forward to `main`. The owner-uploaded Rewarded Ads PNG remains byte-identical at Git blob `8af3efe972c10010ca429c4aca958ecf0c3cd0f6`. The prompt's stale SHA-256 `e25529bd...378f` is superseded by the owner's committed-master decision and canonical pin `ce96e09a...6c8b`. HOME-122/binder/presentation integration, shortcut-family styling, geometry and navigation preservation PASS. **SB-M43-R15-004 remains OPEN only for OWNER F5 visual acceptance.**
- R15 V01 independent technical audit PASS [2026-10-06]: `coordination/sessions/M43-OWNER-R15/CHATGPT_AUDIT_V01.md` accepts implementation `24828bb` / final Claude branch `9fcb18ffe5547477b79f0eba193be65e76b731e3`, merged by fast-forward to `main`. Rewarded Ads authority/idempotency, Settings behavior preservation and Daily containment source/test contracts PASS. **SB-M43-R15-001..003 remain OPEN only for fresh OWNER F5 visual acceptance.** Claude again used a cloud clone rather than the owner-local checkout; this is recorded as a non-blocking process deviation and the next implementation prompt must restore the standing owner-local non-destructive sync rule.
- Owner visual rejection [2026-10-06]: Rewarded Ads Home functionality/placement is present, but the temporary green native CTA is visually rejected because it does not match the approved SHOP / COLLECTION / TASKS / DAILY shortcut language. Owner supplied and approved an exact text-free replacement icon master (Scrubby + video/play + Scrub Bucks + Hearts; no coins, no baked text). R15-004 is presentation-only; Settings/Daily review remains separate.
- Owner runtime review [2026-10-06, F5 main]: owner reviewed the supplied live screens and said **everything shown is OK except two visual defects plus one new requested surface**. Accepted in this review: Collection/list + set detail states, Cards Exchange empty state, Robots, Gift Bar, Profile, Achievements, Notifications, Shop, Life, Events empty state and Tasks. **Not accepted yet:** Daily Rewards layout because art protrudes outside its intended table/popup bounds; Settings because the dark generic panel does not match the SCRUBBOTS visual language. **New owner request:** add a separate REWARDED ADS button/surface with five rewards per local day: reward 1 is immediately claimable, rewards 2-5 each require one successfully completed verified rewarded video. This review does not constitute SB-M43-168 sound/haptic acceptance.
- Owner visual decision [2026-10-04]: SB-M43-064 V01 technical audit PASS is retained, but the shipping composition is OWNER REJECTED. Required V02 flow is pack alone -> Tap 1 -> animated 01→09 -> cards emerge -> pack gone/3-card hold -> Collection upper-left + Card Exchange upper-right -> Tap 2 -> NEW routes to Collection / DUPLICATE routes to Card Exchange -> complete. Remediation prompt/criteria are `coordination/sessions/M43-C005-C006/CHATGPT_PROMPT_V02.md` and `CHATGPT_AUDIT_CRITERIA_V02.md`.
- Note: M43-C005-C005 independent audit PASS is recorded in `coordination/sessions/M43-C005-C005/CHATGPT_AUDIT_V01.md`. The reusable production RevealSequencer is presentation-only and Results now uses it without changing receipt/economy/navigation truth. **SB-M43-063 is CLOSED.** Production M43-C005 advances to SB-M43-064 Standard Pack presentation.
- M43-C005-C006 V02 independent technical audit PASS [2026-10-04]: commit `10144f6e21e3925601b2cc1269835fa2562a1c2f` implements the owner-required two-tap Standard Pack flow and passes source/runtime evidence audit. **SB-M43-064 remains OPEN only for OWNER VISUAL PASS.** Premium SB-M43-065 must not start before that decision.
- V03 owner visual rejection [2026-10-04]: owner observed that the FULL animation does not make all 01→09 beats visibly distinct and that several Standard frame PNGs retain dirty dark rectangular backgrounds. Historical manifest values for 05/07/09 corroborate a 928×1440 opaque matte rectangle. ChatGPT issued `CHATGPT_PROMPT_V03.md` + `CHATGPT_AUDIT_CRITERIA_V03.md`; V02 owner visual approval is not granted.
- V03 independent technical audit PASS [2026-10-04]: `coordination/sessions/M43-C005-C006/CHATGPT_AUDIT_V03.md` accepts commit `ebc7644a95a1637c2c19c0478a36a3e8a56c62ba`. All nine shipping frames pass the clean-alpha/matte gate; V03 candidate/final blobs match 9/9; FULL runtime uses exact 01→09 with >=0.18 s holds for 01..08. **SB-M43-064 remains OPEN for fresh OWNER VISUAL PASS.**
- Owner Review Harness [2026-10-04]: V01 was built against V02 and is historical/stale after V03 timing/asset remediation. ChatGPT has now issued `owner_review_harness/CHATGPT_PROMPT_V02.md` + `CHATGPT_AUDIT_CRITERIA_V02.md` to rebaseline the same review-only F6 harness to the audited V03 ceremony/assets without changing production.
- Owner Review Harness V02 independent audit PASS [2026-10-04]: `coordination/sessions/M43-C005-C006/owner_review_harness/CHATGPT_AUDIT_V02.md` accepts commit `a0e5e46141ef0253be1001394834e035bb43cdc8`. Harness controller/scene and V03 production remain byte-identical; current actor is **OWNER** for live F6 visual approval. Claude's screenshots are not owner acceptance.
- SB-M43-064 final OWNER VISUAL PASS [2026-10-04]: owner reviewed the live V03 Standard Pack ceremony in Godot and explicitly answered **OK**. Acceptance is recorded in `coordination/sessions/M43-C005-C006/OWNER_VISUAL_ACCEPTANCE_V03.md`. **SB-M43-064 is CLOSED.** Frontier advances to SB-M43-065 Premium Card Pack.
- SB-M43-065 V01 independent technical audit PASS [2026-10-04]: `coordination/sessions/M43-C005-C007/CHATGPT_AUDIT_V01.md` accepts commit `31f8e8f03807cacb00bd7ea0d91a2b727b784f35`. Premium ships exactly five committed cards, preserves CardPackService's card-0 Rare-or-better truth, uses clean 01→09 Premium frames, centered 3+2 hold, two-tap destination routing, Reduced Effects parity, and passes Standard non-regression. **SB-M43-065 remains OPEN for OWNER VISUAL PASS.** SB-M43-066 stays blocked.
- SB-M43-065 final OWNER VISUAL PASS [2026-10-04]: owner reviewed the live Premium ceremony in Godot and explicitly answered **OK**. Acceptance is recorded in `coordination/sessions/M43-C005-C007/OWNER_VISUAL_ACCEPTANCE_V01.md`. **SB-M43-065 is CLOSED.** Frontier advances to SB-M43-066 atomic pack commit/presentation transaction.
- SB-M43-066 V01 independent audit FAIL [2026-10-04]: `coordination/sessions/M43-C005-C008/CHATGPT_AUDIT_V01.md` found one blocking fail-closed import defect: missing legacy C008 sections and explicitly present empty/malformed `packs` / `pack_receipts` sections are conflated through default `{}` values. Core transaction/rollback/replay design is retained. Targeted V02 prompt/criteria are `CHATGPT_PROMPT_V02.md` / `CHATGPT_AUDIT_CRITERIA_V02.md`.
- SB-M43-066 V02 independent audit PASS [2026-10-05]: `coordination/sessions/M43-C005-C008/CHATGPT_AUDIT_V02.md` accepts commit `8b3af91614310240f63ad93fc38fc1d05854ae46`. Legacy absent C008 sections remain compatible; explicitly present empty/partial `packs` / `pack_receipts` now fail closed; atomic commit/replay/RNG/set-master guarantees remain intact. **SB-M43-066 is CLOSED.** Frontier advances to SB-M43-067.
- SB-M43-067 V01 independent technical audit PASS [2026-10-05]: `coordination/sessions/M43-C005-C009/CHATGPT_AUDIT_V01.md` accepts commit `bf33ef28072e8ac825783aff3f85389248a985cf`. Card state is derived only from committed `is_new` / `copies_after`; NEW shows FIRST COPY with one restrained canonical glow/pop; DUPLICATE shows EXTRAS x(copies_after-1); Standard/Premium layouts, routing, C008 authority and accepted assets remain intact. **SB-M43-067 remains OPEN for OWNER VISUAL PASS.**
- SB-M43-067 final OWNER VISUAL PASS [2026-10-05]: owner reviewed all live Standard/Premium review modes and said **"hepsi OK"**. Acceptance: `coordination/sessions/M43-C005-C009/OWNER_VISUAL_ACCEPTANCE_V01.md`. **SB-M43-067 is CLOSED.** Owner workflow now issues remaining M43 as one milestone-wide master.
- M43 master partial-run note [2026-10-05]: Claude stopped because of its usage limit after pushing 55 child logs through C007R. Remote `main` at the stop point was `a217122a5336d050b0b99b1389408b0041e82e8d`. M43-C008 Robots remained as uncommitted Desktop WIP and is **not audited/accepted**. ChatGPT issued `coordination/sessions/M43-MASTER-V01/M43_MASTER_RESUME_V02.md`; independent audit remains deferred until the final milestone handoff.
- M43 master V01 independent audit [2026-10-06]: `coordination/sessions/M43-MASTER-V01/CHATGPT_MASTER_AUDIT_V01.md` audits final HEAD `cb8ca9d0659e8edd6ead51c4bfbb23803a7de580`. Master execution/governance and final 5,323/5,323 regression are accepted, but the milestone is **PARTIAL FAIL**. Independent status is 86 technical-pass children, 6 technical failures, 33 blocked authority children, 21 deferred dependencies. Targeted remediation: `M43_MASTER_REMEDIATION_V03.md`. M44 must not start.
- M43 master V04 cross-platform closure issued [2026-10-06]: Claude V03 remediation is pushed on `claude/practical-darwin-ndbmxa` (3 commits ahead of the pre-prompt main baseline). Claude independently reproduced two pre-existing failures on the untouched baseline: M41 whole-economy equality is invalid because fresh AppStates have OS-seeded pack RNG state, and LevelImporter writes a raw dot-segment destination even though its canonical path contract requires `simplify_path()`. ChatGPT chose the narrow contracts: test-only M41 comparison normalization with production RNG unchanged; production LevelImporter I/O through resolved/simplified paths, not a fake test directory. Prompt: `coordination/sessions/M43-MASTER-V01/M43_MASTER_REMEDIATION_V04_CROSS_PLATFORM_CLOSURE.md`.
- M43-C005 sequencing clarification [2026-10-03]: **do not leave M43-C005 after C004.** Once the exact Booster-of-your-choice intake passes independent audit and closes SB-M43-076, continue inside M43-C005 with production ceremony implementation, beginning at **SB-M43-063** and proceeding through the applicable SB-M43-064..075/077 work plus the already-planned C005R/C005F gates as sequenced. M43-C006/M43-C007 are later destinations.
- Plugin-planning note [2026-10-03]: GameFeelFlow + Saltmire Spark integration is fully planned in future M43-C005F plus M46/M47/M50/M54/M55/M59 gates. It does **not** interrupt the current SB-M43-064 owner visual gate. Presentation-only/fail-open is owner-locked; canonical plugin intake/API/license verification remains the first future integration gate.
- MAINT-SUPPLY-COLUMNS-C001 Audit Result: `PASS / CLOSED` by `coordination/sessions/MAINT-SUPPLY-COLUMNS-C001/CHATGPT_AUDIT_V01.md`; shipping supply plans now support exactly 3/4/5 columns with visible preview depth fixed at 3, existing 3-column plans retained, baseline five-slot solve authority retained, and no global robot/batch cap reintroduced. This maintenance closure does not interrupt active M42-C003 V03.
- Retention roadmap expansion [OWNER APPROVED 2026-09-30]: add Next-Level Curiosity, 10-Level Cleaning Journey, Results→Next momentum, Collection pity/first-set sprint, Gift Meter micro-progress, Daily Scrub Orders, earned ScrubBox, Weekly Mini Event, First-Try Challenge, personal-best/self-ghost comparison, Comeback Catch-Up and smarter notification prioritization. Explicit exclusions: **no Daily streak rule change, no Early Robot Unlock pacing change, no World Diorama, no duplicate Robot Personality Loop work, and no Asynchronous Social feature** from this approval.
- Owner sequencing lock: (1) SB-M42-035 Home Scrubby Runtime Animation against the owner-approved 1.612 hero; (2) after technical + owner animation acceptance, resume existing M43/meta roadmap.
- Player-experience roadmap expansion [OWNER REQUEST 2026-09-26]: TASKS now explicitly plans all identified missing player-facing screens, popups, acquisition flows, fail-recovery, FTUE/feature unlocks, Shop/Collection/Robots/Tasks/Daily/Gift surfaces, BottomNav destinations, Events/Ranks/Profile/Achievements, world progression, notifications/comeback, cloud/account recovery, meta audio/haptics, analytics, rewarded ads/IAP and later Friends/social comparison. This planning expansion does **not** interrupt the locked First 10 sequence; implementation sequencing is decided after the First 10 block closes.

## Tasks
# SCRUBBOTS — MASTER TASK PLAN

> **H!veAI tracking [OWNER-LOCKED — updated 2026-09-27]:** repository-root `TASKS.md` is the one and only live project-status tracker and H!veAI parser input. The top `Project Status` block controls current milestone, sprint, task, actor, next action, workflow status, and progress. **Do not recreate `coordination/SESSION_INDEX.md`, `coordination/AUDIT_INDEX.md`, `docs/04_ROADMAP.md`, `.hiveai/PROJECT_DASHBOARD.md`, or any equivalent parallel tracker/status mirror.** Audit/prompt/log files may exist only as cycle evidence, never as project-state authorities. **ChatGPT is the sole writer of root `TASKS.md`; Claude/Codex read it but do not edit it. ChatGPT updates it after each independent audit, owner-gate decision, and before handing off the next implementation prompt.**

Permanent master execution roadmap for the SCRUBBOTS project. This file is
authoritative alongside `CLAUDE.md`. Read both at the start of every
session. ChatGPT updates this file after audit/owner-gate decisions; implementation agents do not mutate it.

Canonical local project: `C:\Users\sekip\Desktop\ScrubBots`
Canonical repository: `https://github.com/Sekiph82/Scrubbots`
Primary branch: `main`

Verified at time of writing (end of Phase M06):
- HEAD commit at phase start: `89c7d43` ("feat: enforce Scrubbots
  difficulty board ranges") — see `docs/05_TECH_DECISIONS.md` and
  CHANGELOG for the Phase M06 commit that follows it.
- Working tree: clean, `main` up to date with `origin/main`
- Godot: **4.7.2-stable** is the current owner-confirmed development version. The historical M00 4.7.1 installation evidence below is preserved as history; exact current build hash should be refreshed from local `godot --version` during the next local validation pass.
- Headless test suite (`tests/run_tests.gd`): **774/774 checks PASS**, exit
  code 0 (grown through M09/M11/M12/M13 and the META-C004 ACTIVE/CLEARED
  renderer migration; recomputed from the suite summary, not hardcoded)
- Official production difficulty bands (Easy/Medium/Hard/Very_Hard,
  20..59, max 59×59 = 3,481 cells) implemented and enforced via
  `DifficultyRules` + `ProductionLevelValidator`, kept separate from the
  generic dimension-agnostic `LevelValidator`/`BoardState` core.
- `BoardRenderer` implemented (single Image/ImageTexture, zero per-cell
  Nodes at any board size — ADR-011) with the owner-locked ACTIVE/CLEARED
  model (ADR-019): ACTIVE = source palette color/opaque, CLEARED =
  transparent (background shows through). **Owner manual QA of the
  transparent model is complete** (SB-M10-005..011 owner-approved on 2026-09-06).

## Status tags

```text
[x]  = completed AND validated (evidence exists: ran, passed, inspected)
[ ]  = incomplete / not validated
```

A task is never `[x]` merely because code exists somewhere. It must have
been run/validated. Additional tags used throughout:

```text
[LOCKED]            — owner-specified rule, do not silently change
[DESIGN GATE]       — unresolved, owner must decide, do not invent
[TECH DECISION]     — architecture choice, see docs/05_TECH_DECISIONS.md
[PERFORMANCE]       — has a performance-sanity dimension
[CONTENT]           — real art/level content work
[VISUAL REFERENCE]  — depends on owner-supplied visual assets
[QA]                — verification/testing work
[DEFERRED]          — intentionally postponed, not blocked
```

---

## GLOBAL DEFINITION OF DONE

A milestone is complete only when **all** relevant conditions below are
satisfied. If a required validation could not run, the milestone is **not**
complete — record why instead of marking `[x]`.

- Implementation exists.
- Code parses in the actual installed Godot version (currently **4.7.2-stable**).
- Headless tests pass where applicable.
- Invalid input is tested, not just the happy path.
- Regression tests (everything previously passing) remain passing.
- No fatal Godot errors in headless/editor output.
- Warnings are understood or fixed, not ignored.
- Relevant performance sanity tests are executed and results recorded.
- Any task that integrates **GameFeelFlow** or **Saltmire Spark** must also pass an actual Godot runtime visual check through the project's Godot AI workflow; headless/unit/static inspection alone cannot close a visual-effect task. Runtime evidence must exercise both FULL and Reduced Effects behavior and a plugin-unavailable/fail-open path where practical.
- Third-party presentation addons remain optional presentation dependencies only: their absence/failure must never block terminal completion, reward commits, saves, navigation or gameplay authority; exact addon version/API, license notice, autoload availability and clean-clone parse/export must be verified before the related task closes.
- The 59×59 (3,481-cell) maximum production workload is considered wherever
  cost scales with board size.
- Documentation reflects the actual implementation, not an aspirational one.
- `TASKS.md` is updated by ChatGPT after independent audit/owner-gate review to reflect true status.
- `git diff` is reviewed before commit.
- No cache/build junk (`.godot/`, import cache, build output) is committed.
- A focused, understandable commit exists.
- Push to `origin/main` succeeds when possible (never force-pushed).
- The current phase's Desktop log (see "PHASE LOG WORKFLOW" below) is
  updated to reflect the work.

---

## PERMANENT CLAUDE SESSION WORKFLOW

Every future numbered implementation prompt must:

1. Read `CLAUDE.md`.
2. Read `TASKS.md` (this file) without modifying it.
3. Read relevant `docs/` files for the system being touched.
4. Inspect `git status` / branch / remote.
5. Confirm which milestone is actually current (don't assume from memory).
6. Preserve owner files and artwork — never delete/regenerate without cause.
7. Work only on the requested scope — no drive-by rewrites.
8. Reuse existing systems (`LevelData`, `BoardState`, etc.) where appropriate
   — do not rebuild working systems for stylistic reasons.
9. Run current regression tests before major modification when practical.
10. Implement the requested milestone.
11. Add/update tests.
12. Run headless validation (`godot --headless --path . -s res://tests/run_tests.gd`).
13. Fix regressions.
14. Run relevant performance sanity tests.
15. Update authorized subsystem docs/evidence only.
16. **Do not edit root `TASKS.md`; ChatGPT owns tracker changes after audit/owner-gate review.**
17. Review `git diff` and ensure `TASKS.md` is absent from the implementation diff.
18. Commit (focused, descriptive message).
19. Push safely (`git push origin main`, never force).
20. Never force-push.
21. Write/update the matching GitHub `CLAUDE_LOG_VNN.md` and hand back `AWAITING_AUDIT`; ChatGPT then audits and updates `TASKS.md`.

---

## PHASE LOG WORKFLOW (supersedes the old per-prompt handoff-log convention)

**One development phase = one continuous Desktop log file**, not one log
per prompt. A "phase" is a milestone-level unit of work (e.g. `M03`, `M04`)
that may span multiple Claude prompts/sessions.

- Naming: `C:\Users\sekip\Desktop\SCRUBBOTS_PHASE_MXX_LOG.md` (e.g.
  `SCRUBBOTS_PHASE_M03_LOG.md`). `MXX` matches the `TASKS.md` milestone ID
  the work belongs to.
- **Create the log file at the START of the phase's first prompt**, before
  any inspection or code changes — not at the end.
- If the log file already exists for the current phase, **read it and keep
  updating the same file** — never create a second log for the same phase
  (no `_RETRY`, no `_B`, no `PROMPT_03B` variants). Every prompt working on
  the same phase reuses the same file.
- Update it after every meaningful checkpoint: environment/repo inspection,
  baseline tests, architecture decisions, each implementation step,
  fixtures added, test-suite changes, each significant failure/debugging
  discovery, final tests, before commit, after commit, after push. The log
  must let another agent resume work correctly even if the session stops
  unexpectedly mid-phase.
- Keep the chronological journal/history in the log even after issues are
  fixed — do not erase past failures once resolved.
- When the phase is genuinely complete, set `PHASE STATUS: COMPLETE` and
  fill in the Final Phase Summary section — without deleting the earlier
  chronological content.
- Only start a **new** log file when moving to a genuinely new phase (e.g.
  `M03` complete, `M04` begins).
- The phase log is **never committed** to the Scrubbots Git repository — it
  lives only on the Desktop.

Prompts 01 and 02 predate this convention and used one-log-per-prompt
(`SCRUBBOTS_PROMPT_01_LOG.md`, `SCRUBBOTS_PROMPT_02_LOG.md`) — those are
historical and not retroactively merged. `SCRUBBOTS_MASTER_TASKS_LOG.md`
(the master-plan prompt) also predates this convention. Starting with
Phase M03, use the phase-log format above.

---

## LOCKED GAME RULES

These rules override older documentation where a conflict exists. They are
not open for silent reinterpretation.

### 8.1 — Mobile-first `[LOCKED]`

SCRUBBOTS is mobile-first. Primary orientation: **portrait**. Current
provisional virtual design resolution: **1080×1920** (see ADR-002 in
`docs/05_TECH_DECISIONS.md`). Gameplay code must remain independent of
physical phone resolution — this is a display setting, not gameplay logic.

### 8.2 — Variable-size logical board `[LOCKED]`

The board engine remains **variable-size**. It must never become a fixed
40×40, 50×50, 1600-cell, 2500-cell, or 3481-cell engine. Board dimensions
come from level data. Generic code uses `width`, `height`, `width * height`
— never a hard-coded cell count. See ADR-008.

### 8.3 — Official difficulty / board size bands `[LOCKED HISTORICAL RUNTIME COMPATIBILITY]`

The legacy production validator currently retains these dimension bands while Difficulty V1 migration is still open. They are not current player-facing difficulty truth; see `coordination/OWNER_DIFFICULTY_PROGRESSION_DECISION_V01.md` and `CLAUDE.md`.

| Difficulty | Width range | Height range | Min cells | Max cells |
|---|---|---|---|---|
| EASY | 20–29 | 20–29 | 20×20 = 400 | 29×29 = 841 |
| MEDIUM | 30–39 | 30–39 | 30×30 = 900 | 39×39 = 1521 |
| HARD | 40–49 | 40–49 | 40×40 = 1600 | 49×49 = 2401 |
| VERY_HARD | 50–59 | 50–59 | 50×50 = 2500 | 59×59 = **3481** |

Examples of legacy-validator-valid boards: Easy `20×27`, Medium `34×39`, Hard `48×41`, Very Hard `53×59`.

**Current required production-capable maximum: 59×59 = 3,481 logical cells.**

### 8.4 — Rectangular boards `[LOCKED]`

Boards do **not** have to be square. Width and height are validated
independently. Never assume `width == height` in generic systems.

### 8.5 — Current maximum required workload `[LOCKED]`

`59×59 = 3,481` cells. All systems whose cost scales with board size must
eventually be tested against this workload: LevelData validation,
BoardState, BoardRenderer, color candidate index, reachability/access,
target selection, routing-related board queries, clearing updates, save/load
of level state if used, and production content validation.

### 8.6 — Test/dev fixtures vs. production levels `[LOCKED TECHNICAL RULE]`

The existing `test_3x2.json` fixture (6 cells) is valuable because it
proves the board engine is genuinely generic — it is **not** a production
level and must never be treated as one. Development fixtures may use a
`TEST` difficulty/context. `TEST` must never become a production difficulty
exposed to players, and the future production `LevelCatalog` must reject
accidental `TEST` fixtures (see M03, M35).

### 8.7 — Logical pixels `[LOCKED]`

One logical artwork square = one logical pixel = one board cell. Logical
cells are game data, never physical display pixels, and are never
represented as thousands of heavyweight Godot Nodes (see ADR-004, ADR-008).

### 8.7A — Global 16-color pixel-art palette `[LOCKED OWNER DECISION]`

Canonical machine-readable palette:
`data/palettes/scrubbots_palette_v3.json`

Palette authority version and Level Data schema version are independent. The current Level Data schema remains V1 (`version: 1`); palette v3 does not authorize Level Data V2.

Canonical human-readable rule:
`docs/08_PIXEL_ART_PALETTE_RULES.md`

Production logical artwork cells may use **only C01..C16**. No other logical
pixel color is legal without an explicit owner rule change and palette version
change. CLEARED alpha-0 transparency, gameplay background and
presentation-only grid/border overlays are not logical artwork colors and do
not add palette IDs.

### 8.7B — Production used-color envelope `[OWNER-LOCKED DIFFICULTY V1]`

Production artwork may use **3–12** distinct canonical C01..C16 colors. The older class-specific `3–5 / 6–7 / 8–9 / 10–12` mapping is historical and superseded as difficulty-class legality; color count/distribution are Difficulty V1 score inputs instead.

### 8.8 — Five batch slots `[OWNER-LOCKED 2026-09-17]`

Primary gameplay presentation uses **exactly five batch slots**. They start EMPTY.
The player never chooses a destination slot. Selecting a legal supply batch automatically
places it into the **rightmost currently EMPTY slot**. Existing occupied slots never shift
or reorder. If all five slots are occupied, a supply selection is rejected atomically and
the supply column must not advance.

Duplicate colors across multiple occupied slots are legal and are part of the puzzle.
Each occupied slot owns one immutable batch identity with color, initial robot count,
remaining-to-clear count, committed/in-flight count, placement sequence and lifecycle state.

### 8.8A — Batch supply columns `[OWNER-LOCKED 2026-09-17]`

- Production supply supports 3, 4 or 5 independent FIFO columns.
- V1 gameplay validation uses **three visible rows per column**.
- Only the front/top batch in each column is selectable.
- Row 2 and Row 3 are preview-only future batches.
- Everything deeper than the preview window is hidden from the player.
- Selecting a front batch advances **only that column** by one position.
- The previous Row 2 becomes selectable, Row 3 becomes Row 2, and the next hidden batch
  enters Row 3. Other columns remain unchanged.
- Each batch is `color + positive robot_count`; its identity is stable once generated.
- Supply generation must conserve the level's logical color totals and must ultimately be
  accepted only when the Solvability Engine proves at least one legal completion sequence.

### 8.8B — Batch quota / slot lifecycle `[OWNER-LOCKED 2026-09-17]`

A batch count means the number of matching logical pixels that batch must successfully clear.
A count is **not** spent when a robot is merely spawned. It decreases only after an
authenticated arrival clears the batch's assigned target pixel. A batch with remaining quota
but no currently targetable matching pixel enters WAITING and stays in its slot. It resumes
automatically when later clearing exposes a legal matching target. A slot becomes EMPTY only
when the batch has zero remaining work and zero committed/in-flight assignments.

### 8.8C — Same-color arbitration and target claims `[OWNER-LOCKED 2026-09-17]`

Future inaccessible pixels are never pre-claimed. When a matching pixel becomes currently
targetable, same-color occupied batches compete deterministically by **oldest placement first
(FIFO)**. The oldest batch with uncommitted quota receives priority; if its remaining dispatch
capacity is exhausted, additional targets may flow to the next same-color batch.

A target claim and ReservationState reservation must be atomic. One logical pixel may belong
to at most one live assignment at a time, regardless of how many same-color batches are in
the five slots. Existing TargetSelector bottom-most/left-most ordering remains the target-order
policy among currently targetable, matching, unreserved cells.

### 8.8D — No ghost robots `[OWNER-LOCKED 2026-09-17]`

**No target, no reservation, no valid route, no robot.** A Scrubbot may be instantiated only
after a unique matching target has been selected, atomically reserved/claimed, and a legal
route to that exact target has been produced and validated. A spawned robot never wanders,
never spawns without work, never silently retargets, and never shares a target with another
robot. Route-build failure releases the provisional claim/reservation and consumes no batch
quota.

### 8.8E — Solvability and deadlock `[OWNER-LOCKED 2026-09-17]`

Generated supply is production-valid only if a deterministic solver can prove at least one
legal player-choice sequence that clears the entire level under the real five-slot, FIFO
column, targetability, claim, routing and batch-quota rules. Runtime must distinguish temporary
WAITING/STALLED states from a proven deadlock. In-flight work or any legal future action that
can open progress means the position is **not** deadlocked. A deadlock may be declared only
when no legal future action sequence can produce further authenticated clearing.

### 8.9 — Scrubbot behavior `[LOCKED]`

- Scrubbots leave slots one at a time.
- A Scrubbot does not leave unless a reachable/targetable matching target
  exists (a blocked/unreachable matching-color ACTIVE cell is not enough).
- A Scrubbot has a valid, reachable target *before* being dispatched.
- It visually moves from slot to target.
- On arrival the target logical pixel becomes CLEARED (transparent; the
  gameplay background shows through).
- It then disappears/finishes.
- It does not collect or carry pixel color.
- It does not return to the slot; no return route is needed.

Scrubbot movement across the picture is one of the most important pieces
of the game's visual identity.

### 8.10 — TargetSelector vs. RoutingSystem `[LOCKED ARCHITECTURE]`

`TargetSelector` answers **WHAT** valid cell should be assigned.
`RoutingSystem` answers **HOW** the Scrubbot travels there visually. Never
combine them. `BoardRenderer` never chooses targets. `ScrubbotAgent` never
searches the board and picks its own arbitrary target. The routing
implementation must remain replaceable (see ADR-005).

### 8.10A — Target selection positional priority `[LOCKED OWNER DECISION — 2026-09-13]`

For a requested slot/color, TargetSelector keeps the canonical eligibility
rules: the candidate must be a valid board index, ACTIVE, matching the requested
color, unreserved, and currently targetable/reachable according to authoritative
access truth. **Among candidates that can otherwise proceed under that contract,
selection priority is bottom-most first (largest board-local `y`), then left-most
within that row (smallest board-local `x`).** A blocked/unreachable lower or
leftward raw candidate never wins merely because of position; the selector
continues to the next candidate in deterministic bottom-to-top / left-to-right
priority. This is a WHAT-policy in TargetSelector only. Routing still decides HOW
to travel to the already-selected target and must not retarget based on geometry.

### 8.10B — Scrubbot Railroad V1 `[OWNER-LOCKED CURRENT — 2026-09-17]`

The exact adjacent one-cell exterior ring proven in M21 V07–V10 remains historical evidence only. `coordination/OWNER_SCRUBBOT_RAILROAD_DECISION_V01.md` remains authoritative for canonical Railroad V1 geometry, while `coordination/OWNER_SCRUBBOT_RAILROAD_INTERIOR_PATH_DECISION_V01.md` supersedes only the old straight-only post-rail target approach.

Railroad V1 uses one consistent robotic cleaning rail around every level. Geometry is derived from board `W×H`: artwork-to-rail inner-edge clearance `2.0` logical cells, rail width `1.0` logical cell, therefore rail centreline `2.5` logical cells outside each board boundary. Scrubbots start from the exact owning SlotCell anchor, visibly connect to the BOTTOM rail, and remain on canonical rail sides/corners during all exterior travel.

A Scrubbot may leave Railroad V1 only through a legal orthogonal ingress into OPEN/CLEARED perimeter gameplay space. Rail departure does **not** have to be aligned with the final target row/column. After ingress, the route may traverse OPEN/CLEARED board cells by four-neighbour orthogonal movement with one or more 90-degree turns. Non-target ACTIVE cells remain hard blockers; the assigned ACTIVE target is enterable only as the final endpoint. No diagonal, corner-cut, teleport, free-space exterior shortcut, non-target ACTIVE tunnelling or retargeting is legal.

For an already-assigned target, routing evaluates legal ingress/interior-path combinations and chooses the shortest legal total route including slot connector, rail travel, ingress, interior path and final arrival. Equal-distance side priority remains `BOTTOM → LEFT → RIGHT → TOP`; same-side ties must be deterministic. TargetSelector §8.10A remains WHAT-only and RoutingSystem remains HOW-only.

Railroad V1 is routing/presentation infrastructure only: it is not LevelData, BoardState, C01..C16 artwork, difficulty truth, batch-supply truth or reservation ownership. Collision/lane/congestion rules remain design-gated unless later owner decisions explicitly lock them.

### 8.10C — Supply-front-only owner gameplay activation `[OWNER-LOCKED CURRENT — 2026-09-17]`

The production player interaction is **selectable front batch click/tap**, not direct slot activation. Normal gameplay has five automatic destination/Scrubbot-origin slots; Economy V1 +1 Slot may expand authoritative capacity to exactly six for the current attempt. Slots are not player-selectable placement controls.

The player may normally activate only the current front/top batch of a supply column. A successful selection transaction sends that batch to the rightmost currently EMPTY slot. If every slot in the current authoritative capacity (5 normally, 6 with +1 Slot active) is occupied, the selection is rejected and the supply column does not advance. Economy V1 Selector is the single owner-authorized exception to normal front-only selection and must use its own atomic/solver-safe transaction. Once a batch occupies a slot, Auto Dispatch later spawns Scrubbots automatically from that exact SlotCell anchor only after the target-claim/reservation/valid-route transaction succeeds.

The historical M21/M22 direct color-slot click path remains valid evidence for those earlier vertical-slice and Railroad tests, but it is superseded as the production core-loop interaction. Do not retain or add hidden keyboard dispatch shortcuts such as SPACE. Presentation input must feed the real Batch Supply → Five-Slot Batch → Claim → Auto Dispatch → Routing → ScrubbotAgent → authenticated clear chain.

### 8.10D — Gameplay speed / automatic endgame acceleration `[OWNER-LOCKED CURRENT — 2026-09-18]`

Production gameplay V1 supports exactly **1x** and **2x** temporal speed. A new level/full reset starts at 1x. Shipping manual 2x is no longer always free: Economy V1 requires a valid current-level entitlement (200 SB) or timed entitlement (15m/300 SB, 30m/500 SB, 60m/750 SB). Timed entitlement uses real wall-clock expiry and continues in gameplay, menus, pause, background and while the app is closed.

The game automatically switches to **2x for free** immediately after authoritative **M23 supply exhaustion**: every 3/4/5 FIFO column has zero remaining batches, including all formerly hidden batches, because the final front-batch transaction has been successfully accepted and committed into M24. The trigger is not full-slot occupancy and is not visible-row emptiness while hidden batches remain. A rejected final transfer does not trigger auto-2x.

2x accelerates time-based gameplay execution/presentation only. It must not change M23 FIFO order, M24 placement/accounting, M25 target/claim arbitration, TargetSelector priority, ReservationState ownership, Railroad/routing geometry, M26 no-ghost semantics, authenticated clears or M27 solver/deadlock meaning. GameplaySpeedAuthority owns factor only; Economy V1 SpeedEntitlementService owns paid manual permission/expiry. Canonical decisions: `coordination/OWNER_GAMEPLAY_SPEED_RULE_V01.md` and `coordination/OWNER_ECONOMY_REWARDS_V01.md`.

### 8.10E — Five-slot displayed batch count `[OWNER-LOCKED CURRENT — 2026-09-19]`

The large/main number shown on an occupied production batch slot means **robots still waiting in that slot**, not raw unresolved quota. Canonical display truth is:

`display_count = M24 capacity = remaining_to_clear - committed`

Example: a newly placed Blue 50 displays 50; after one successful robot commit/dispatch it displays 49 immediately; with two in-flight it displays 48. Authenticated arrival later decrements both `remaining_to_clear` and `committed`, so the visible waiting count does not jump back. The current historical presentation `50 (2)` is superseded.

This is presentation only. M24 authoritative accounting remains unchanged: `remaining_to_clear` decreases only after authenticated clear; `committed` tracks in-flight work; completion still requires remaining=0 and committed=0.

ACTIVE/WAITING internal lifecycle semantics are also unchanged. ACTIVE means eligible/not currently marked unavailable; it does not guarantee a robot is presently moving. WAITING means no currently claimable reachable target for that batch/color, and the batch must be automatically reconsidered after relevant board changes. Canonical decision: `coordination/OWNER_BATCH_SLOT_DISPLAY_DECISION_V01.md`.

### 8.10F — Live five-slot presentation synchronization `[OWNER-LOCKED CURRENT — 2026-09-19]`

The production five-slot strip must reflect **current authoritative M24 state**, not merely the snapshot captured after the last player batch placement.

Fresh detached slot snapshots must be pushed after player-visible M24 mutations including dispatch commit, ACTIVE->WAITING, WAITING->ACTIVE wake, rollback, authenticated-clear finalization, slot completion->EMPTY and reset. UI remains presentation-only and must not run target selection/routing to guess lifecycle state.

Hazard Bot reference: after the first two Blue50 batches have cleared the initial 100 reachable blue cells, the early Brown3 batch still has no immediately reachable brown target in the accepted M27 solution trace. Its player-facing slot state must therefore be WAITING until later black/open-corridor progress wakes it. A stale ACTIVE badge after that point is a presentation-sync defect. Canonical decision: `coordination/OWNER_FIVE_SLOT_LIVE_PRESENTATION_SYNC_DECISION_V01.md`.

### 8.11 — Win streak `[LOCKED — Economy V1]`

```text
1 consecutive progression win   -> +1 SB
2 consecutive progression wins  -> +5 SB
3 consecutive progression wins  -> +10 SB
4 consecutive progression wins  -> +25 SB
5+ consecutive progression wins -> +100 SB per win
```

Never reinterpret `1, 5, 10, 25` as win-count thresholds. Only this streak-bonus SB advances Gift Meter. Every multiple-of-5 active streak also grants +1 Bot Part. Progression loss or restart after gameplay begins resets streak; replay cannot advance it.

### 8.12 — Economy & Rewards V1 `[OWNER-LOCKED 2026-09-18]`

Canonical decision: `coordination/OWNER_ECONOMY_REWARDS_V01.md`. Machine tuning: `data/config/economy_rewards_v1.json`.

- Scrub Bucks are the only general spendable soft currency.
- Stars, Star Exchange and Event Points are removed. Star Exchange becomes Cards Exchange.
- Hearts: max 5, +1 every **15 real-world minutes / 900 seconds** [OWNER-LOCKED 2026-09-27].
- Bot Parts: robot-unlock-only resource; every post-Scrubby robot costs 250.
- Gift Meter progress comes ONLY from Win Streak SB and has 10/50/250/500/1000 milestones with rollover.
- Exactly four boosters exist: +1 Slot 500 SB, Random 350 SB, Selector 500 SB, Tornado 750 SB.
- Daily has 3 tasks, consecutive-login count and a repeating 5-day reward cycle; Daily and Gift Bar can grant booster charges.
- Duplicate Collection cards exchange to SB; protected first copies cannot be exchanged.
- Real-money monetization remains a separate M57 gate.

### ADR-009 — Explicit preload() convention `[LOCKED UNTIL EXPLICITLY REVISITED]`

Prompt 02 found bare `class_name` cross-script references unreliable in a
headless environment with no prior editor-built global class cache. The
working solution: `const LevelData = preload("res://scripts/data/level_data.gd")`
instead of relying on global class-name resolution. Future scripts in the
data/gameplay/test core should follow this convention unless a future task
deliberately revisits ADR-009 and proves an alternative equally reliable
via headless tests. Do not casually convert back to bare `class_name` for
stylistic reasons.

### Production gameplay background `[LOCKED]`

- BG01 **Midnight Slate** = `#202533` / RGB(32,37,51).
- CLEARED alpha-0 cells reveal BG01 underneath.
- BG01 is not part of C01..C16 and is never a logical LevelData cell
  color, and never counts toward difficulty distinct-color totals.
- Debug-only transparency backgrounds may differ for visibility.

---

## VISUAL REFERENCE SYSTEM

SCRUBBOTS has (per the owner) prior artwork and visual concepts. The
project must use them rather than defaulting to generic programmer art —
but **only artwork that physically exists in this project or is supplied
during a task counts as available**. A visual discussed in a prior chat is
not automatically a local file.

**Verified at time of writing**: owner references and the approved M21 Hazard Bot are now present in-repo; historical “all empty” statements elsewhere are superseded by current inventory/coordination evidence.

### 9.1 — Visual reference priority `[LOCKED]`

**Priority 1 — Owner-approved original SCRUBBOTS artwork.** Canonical
visual reference: character concepts, gameplay concepts, five-slot layouts,
pixel-art level artwork, themed level artwork, original UI ideas, effects
concepts, screen compositions. If original approved artwork conflicts with a
generic placeholder, the original artwork wins.

**Priority 2 — Owner-supplied SCRUBBOTS reference images.** May guide
composition, proportions, pixel-art density, UI positioning, Scrubbot size,
slot size, board presentation, visual hierarchy.

**Priority 3 — External game references.** Inspiration/reference only —
movement density, clarity, pacing, spatial readability, touch ergonomics,
pixel construction methodology. Must never be copied.

### 9.2 — Colony Flow reference limit `[LOCKED]`

May be referenced only for the broad feeling of many tiny agents moving
across a play area and the abstract idea of perimeter travel. SCRUBBOTS intentionally differs in characters, rail visual language, artwork, UI, composition and exact movement implementation:

```text
Correct SCRUBBOTS flow:
  selectable supply-front batch -> automatic rightmost-empty slot -> unique claim/reservation -> valid route -> exact slot connector -> Scrubbot Railroad -> legal OPEN/CLEARED ingress -> orthogonal interior corridor -> clean -> disappear

NOT:
  travel to resource -> collect resource -> carry resource back -> return home
```

Never copy Colony Flow's characters, art, level composition, UI, icons, exact rail/frame appearance, animations, routing visuals, or source code.

### 9.3 — Pixel art reference rule `[LOCKED]`

Previously supplied game screenshots may be used only as reference for
*pixel construction method*, where explicitly approved — never for
characters, compositions, object placement, or level art. External-reference
colors must never redefine the SCRUBBOTS palette. The exact production palette
is owner-locked in §8.7A / `data/palettes/scrubbots_palette_v2.json`.
The goal is understanding how a readable image is built from a limited
logical grid. SCRUBBOTS level artwork remains original.

### 9.4 — Existing SCRUBBOTS level art `[LOCKED]`

Existing original SCRUBBOTS level artwork is intended to become real playable
content once owner-approved source files are supplied/recorded. Never regenerate
such pieces from memory and present the result as “the original.” The M21 Hazard
Bot source is the first owner-approved production-art fixture and must remain
byte-identical unless the owner explicitly replaces it.

### 9.5 — Reference file availability `[LOCKED]`

Claude only has access to artwork physically present in the project or
supplied during the current task. If an expected visual does not exist
locally: `STATUS = AWAITING OWNER ASSET`. Do not fabricate it, do not mark
its audit complete, do not claim a pixel-accurate comparison was performed
against something that doesn't exist locally.

### 9.6 — Recommended visual directory structure

```text
assets/
└── art/
    ├── references/
    │   ├── gameplay/
    │   ├── ui/
    │   ├── scrubbots/
    │   ├── pixel_method/
    │   └── external_inspiration/
    ├── characters/
    │   └── scrubbots/
    ├── levels/
    │   ├── source/
    │   │   ├── easy/
    │   │   ├── medium/
    │   │   ├── hard/
    │   │   └── very_hard/
    │   └── previews/
    ├── ui/
    └── effects/
```

---

## VISUAL PRODUCTION / MASTER UI WORKFLOW [LOCKED OWNER DECISION]

1. Visual production is an integral part of the **main SCRUBBOTS mobile game project and roadmap**. It must not be split into a Level Factory/Content Pipeline-style sidecar or treated as an unrelated final art pass.
2. ChatGPT image generation is the owner-preferred primary illustration-generation workflow for UI/character visual production. Magnific MCP remains an approved fallback/alternate. PixelLab/native pixel AI work is separately scoped to semantic pixel-art generation and does not own puzzle logic.
3. AI image generation is a **development-time tool only**. The shipping game must never require generation APIs, credentials, or credits at runtime. Owner-approved generated outputs become ordinary versioned Godot assets.
4. Existing owner-created SCRUBBOTS artwork is the first visual authority. Import/copy and classify owner references before generating replacements or variants. Never overwrite or delete the owner's originals.
5. AI-generated full-screen mockups are art-direction/reference material, not shippable UI. Production screens must be composed from responsive Godot Controls/Containers plus approved illustration assets.
6. Prefer native Godot UI for panels, buttons/interaction containers, progress bars, slots, color tiles, currency counters, text, popup bodies, dim layers and responsive layout. Use generation for art that genuinely benefits from illustration generation: characters, character poses/portraits, boosters, rewards, difficulty emblems, decorative props, collection/event art and similar branded artwork.
7. Raw generation candidates and owner-approved production assets are different lifecycle states. Never silently regenerate, replace or overwrite an approved production asset.
8. Every milestone that requires new visual assets owns its own visual-generation/review/import tasks. Do not postpone all visual production to one disconnected end-of-project art phase.
9. `docs/MASTER_UI_SYSTEM.md` is the canonical responsive UI architecture contract. `ASSET_GENERATION_MANIFEST.json` is the machine-readable provider-agnostic generation queue/provenance contract; `assets/ui/HOME_ASSET_MANIFEST.json` is the Home-screen preproduction inventory.
10. `BoardRenderer` remains the existing single-`Image`/`ImageTexture` data-oriented renderer. The Master UI system must not replace logical board rendering with one UI node per cell.
11. Visual milestone completion requires actual owner-approved assets where required, correct Godot import/binding, responsive validation and regression evidence. A generated image existing on disk is not by itself completion.
12. Railroad V1 structural geometry is native/data-driven and shared by routing/presentation; V02 does not require generated railroad art. Future visual skinning may not change railroad gameplay geometry.

Home preproduction note (owner decision 2026-09-18): `assets/ui/HOME_ASSET_MANIFEST.json` is preproduction inventory/scaffolding only. Creating the inventory and folders does not close M42 or authorize jumping ahead of M23–M27 core-gameplay sequencing.

### Visual production order

1. **Reference intake and canonical visual selection first.** Import owner references copy-only into the repository reference inbox, inventory/classify them, and select canonical Scrubby/gameplay/home/popup references before broad generation.
2. **Core gameplay engineering continues without waiting for decorative art.** Target selection, routing, dispatcher/agent behavior, cleaning rules and other gameplay-critical work must not be blocked by decorative asset production when programmer art is sufficient.
3. **First real-art vertical slice.** Validate gameplay with owner-approved real level/pixel artwork before treating production visuals as proven. AI image generation must not invent canonical puzzle truth or replace the level-data/puzzle-validation pipeline.
4. **Production gameplay UI asset generation begins when the relevant gameplay UI milestones open.** Generate only assets required by that milestone, review them, promote approved variants, then bind them to reusable Godot components.
5. **Final Scrubbot visual production happens in the existing Scrubbot visual milestone**, using the canonical Scrubby reference and approved visual language.
6. **Home, Results, Tutorial, Collection, Shop, Events and later screens generate their own required assets inside their existing milestones.** They do not wait for a separate global art project.
7. Final visual polish is a consolidation/QA pass over already-integrated milestone-owned art, not the first time production art is introduced.

---

## VISUAL ASSET PRODUCTION STATUS [CONTENT]

Canonical discovery index for Claude/Godot UI integration:
`assets/ui/VISUAL_ASSET_INDEX.md`

- [x] SB-UI-VIS-001 Phase 1 core visual production completed: 306 / 306 canonical targets produced and published.
- [x] SB-UI-VIS-002 Phase 2 main visual batch P2-001..P2-144 completed and published, including branding/system assets, reusable UI kit, booster states, canonical 10-robot presentation families, and system-state icons.
- [x] SB-UI-VIS-003 Collection extraction completed: all 15 sets × 9 cards = 135 individual canonical card PNGs exist under `assets/ui/final/collection/cards/set_01..set_15/`.
- [ ] SB-UI-VIS-004 Integrate/audit the final visual-closure batch P2-145..P2-157 from `codex/visual-assets-production` into `main`. Source commit: `65b26242f996f210a923b4536c7083f6f2d005cc`. This batch contains 9 robot-perk icons, 3 Collection state assets, and the canonical 10-robot Cleaning Crew group art.
- [ ] SB-UI-VIS-005 After P2-145..P2-157 integration, refresh/verify the `main` copy of `assets/ui/VISUAL_ASSET_INDEX.md` so Claude sees the final 157 / 157 Phase 2 targets and complete production paths.
- [ ] SB-UI-VIS-006 Before UI milestone closure, perform owner/Claude pixel-level QA of production assets actually used on-screen: alpha edges, text/watermark absence, mobile readability, identity consistency, compression/import settings. Path existence alone is not visual acceptance.

Static AI visual generation is considered closed after SB-UI-VIS-004/005 unless a new owner-approved feature creates a specific new requirement. Do not generate speculative World Map, XP, Star-currency, leaderboard, event, or monetization art.

---

## DESIGN GATES

Unresolved. Do not silently invent final decisions for these:

railroad collision/congestion/lane-separation presentation; optional railroad glow/trail polish beyond the locked V1 structure; timer; move limits; blockers; hints; analytics; achievements; leaderboard; social features; cloud save; tutorial wording; audio direction.

**Resolved owner decisions:** M30 WIN/LOSE/Retry semantics are locked in `coordination/OWNER_WIN_LOSE_RETRY_DECISION_V01.md`. Economy V1, Hearts, boosters, currency and related soft-economy rules are separately locked in `coordination/OWNER_ECONOMY_REWARDS_V01.md`; real-money monetization remains M57-gated.

**Not design gates**: the global C01..C16 palette, Difficulty V1 progression/challenge architecture, target positional priority, current Railroad V1 geometry/travel/interior-ingress law, five EMPTY batch slots, rightmost-empty automatic placement, 3/4/5 FIFO supply columns, front-row-only selection, same-color oldest-batch-first arbitration, no-ghost-robot transaction law, and solver-backed supply/deadlock contracts are owner-locked.

---

## MASTER MILESTONES

### M00 — Foundation & Environment

Verified complete via repo inspection + this session's re-run of
`tools/verify_project.ps1` and `godot --version`.

- [x] SB-M00-001 Canonical project directory created.
- [x] SB-M00-002 Git repository connected (`origin` = canonical remote).
- [x] SB-M00-003 `main` branch configured and tracked.
- [x] SB-M00-004 Godot project created (`project.godot` valid).
- [x] SB-M00-005 Directory architecture created.
- [x] SB-M00-006 `.gitignore` created.
- [x] SB-M00-007 `CLAUDE.md` created.
- [x] SB-M00-008 Initial documentation created (`docs/00`–`06`).
- [x] SB-M00-009 Bootstrap scene created (`scenes/app/main.tscn`).
- [x] SB-M00-010 Verification helpers created (`tools/*.ps1`).
- [x] SB-M00-011 Godot 4.7.1-stable installed (winget, `GodotEngine.GodotEngine`).
- [x] SB-M00-012 Godot CLI path verified (`godot --version` → `4.7.1.stable.official.a13da4feb`).

Historical M00 version note: the two completed rows above record the version used when M00 was closed. The current project development version is Godot **4.7.2-stable**; do not reinterpret those historical checkboxes as the current runtime/toolchain declaration.
- [x] SB-M00-013 Headless bootstrap test succeeds (`--headless --path . --quit`, no errors).
- [x] SB-M00-014 Main scene parses (confirmed via headless boot).
- [x] SB-M00-015 Existing GDScript parses (confirmed via headless test run).
- [x] SB-M00-016 Bootstrap committed/pushed (`58caeab`, on `origin/main`).

### M01 — Variable-Size Level Data Core

Complete from Prompt 02. Re-verified this session (files exist, test suite
passes).

- [x] SB-M01-001 Level Data V1 implemented (`scripts/data/level_data.gd`).
- [x] SB-M01-002 Width stored in level data.
- [x] SB-M01-003 Height stored in level data.
- [x] SB-M01-004 Cell count derived (`get_cell_count() = width * height`, never stored).
- [x] SB-M01-005 Palette stored separately (array of hex strings, id = index).
- [x] SB-M01-006 Cell palette IDs compact (`PackedInt32Array`, not per-cell strings).
- [x] SB-M01-007 JSON loader implemented (`level_loader.gd`).
- [x] SB-M01-008 Validator implemented (`level_validator.gd`).
- [x] SB-M01-009 Malformed JSON handled (tested, rejected cleanly).
- [x] SB-M01-010 Unsupported version rejected (tested).
- [x] SB-M01-011 Invalid dimensions rejected (width/height ≤ 0, tested).
- [x] SB-M01-012 Wrong cell count rejected (tested).
- [x] SB-M01-013 Invalid palette ID rejected (tested).
- [x] SB-M01-014 Generic dimension support proven (3×2 fixture).
- [x] SB-M01-015 40×40 loads (1,600 cells, tested).
- [x] SB-M01-016 50×50 loads (2,500 cells, tested).
- [x] SB-M01-017 3×2 loads as generic test fixture (tested).
- [x] SB-M01-018 Explicit preload convention documented (ADR-009).

### M02 — BoardState Core

Complete from Prompt 02, re-verified.

- [x] SB-M02-001 BoardState exists (`scripts/gameplay/board/board_state.gd`).
- [x] SB-M02-002 Runtime state separate from LevelData (BoardState built via `from_level_data`, never mutates source).
- [x] SB-M02-003 Source color data copied safely (`_color_ids = level.cells.duplicate()`).
- [x] SB-M02-004 ACTIVE state implemented (`CellState.ACTIVE = 0`; fresh board all-ACTIVE).
- [x] SB-M02-005 CLEARED state implemented (`CellState.CLEARED = 1`).
- [x] SB-M02-006 Coordinate validation exists (`is_valid_coordinate`).
- [x] SB-M02-007 Index validation exists (`is_valid_index`).
- [x] SB-M02-008 Coordinate→index exists (`get_cell_index`).
- [x] SB-M02-009 Index→coordinate exists (`get_cell_position`).
- [x] SB-M02-010 Cell color lookup exists (`get_color_id`).
- [x] SB-M02-011 Cell state lookup exists (`get_cell_state`).
- [x] SB-M02-012 State mutation exists (`set_cell_state`).
- [x] SB-M02-013 State counting exists (`count_cells_by_state`).
- [x] SB-M02-014 Instance independence tested (two BoardStates from same LevelData don't share state).
- [x] SB-M02-015 LevelData immutability behavior tested.
- [x] SB-M02-016 No one-Node-per-cell architecture exists (flat `PackedInt32Array`/`PackedByteArray`).
- [x] SB-M02-017 Add RESERVED only when reservation architecture is designed (see M14). — resolved by ADR-022: reservation is a separate assignment layer; BoardState remains ACTIVE/CLEARED only.

### M03 — Official Difficulty Bands + 59×59 Envelope

Historical runtime-validator milestone. Difficulty V1 later superseded class=dimension as player-facing truth, but the completed compatibility implementation remains audited evidence until separately migrated.

**Documentation**
- [x] SB-M03-001 Search docs for old claim that 40×40 is "standard."
- [x] SB-M03-002 Search docs for claim 50×50 is the Very Hard requirement without a range.
- [x] SB-M03-003 Search for `2500` used as a maximum.
- [x] SB-M03-004 Update `CLAUDE.md`.
- [x] SB-M03-005 Update project brief.
- [x] SB-M03-006 Update gameplay specification.
- [x] SB-M03-007 Update technical architecture.
- [x] SB-M03-008 Update Level Data spec.
- [x] SB-M03-009 Update roadmap.
- [x] SB-M03-010 Update test strategy.
- [x] SB-M03-011 Add/amend ADR for official difficulty dimension bands (ADR-010).

**Production difficulty representation**
- [x] SB-M03-012 Define canonical legacy runtime production difficulty IDs (`DifficultyRules`).
- [x] SB-M03-013 EASY = dimensions 20..29.
- [x] SB-M03-014 MEDIUM = dimensions 30..39.
- [x] SB-M03-015 HARD = dimensions 40..49.
- [x] SB-M03-016 VERY_HARD = dimensions 50..59.
- [x] SB-M03-017 Keep TEST/dev fixture concept separate.
- [x] SB-M03-018 Production validator rejects TEST.

**Validation**
- [x] SB-M03-019 Add production difficulty/dimension validation.
- [x] SB-M03-020 Accept Easy rectangular boards.
- [x] SB-M03-021 Accept Medium rectangular boards.
- [x] SB-M03-022 Accept Hard rectangular boards.
- [x] SB-M03-023 Accept Very Hard rectangular boards.
- [x] SB-M03-024 Reject cross-band Easy dimensions.
- [x] SB-M03-025 Reject cross-band Medium dimensions.
- [x] SB-M03-026 Reject cross-band Hard dimensions.
- [x] SB-M03-027 Reject cross-band Very Hard dimensions.
- [x] SB-M03-028 Produce explicit errors.

### M04 — Expanded Board Fixtures & Test Matrix

Do not replace existing Prompt 02 fixtures — add to them.

- [x] SB-M04-001 3×2 generic non-square fixture exists.
- [x] SB-M04-002 20×20.
- [x] SB-M04-003 29×29.
- [x] SB-M04-004 20×27.
- [x] SB-M04-005 30×30.
- [x] SB-M04-006 39×39.
- [x] SB-M04-007 34×39.
- [x] SB-M04-008 40×40 generic fixture exists.
- [x] SB-M04-009 49×49.
- [x] SB-M04-010 48×41.
- [x] SB-M04-011 50×50 generic fixture exists.
- [x] SB-M04-012 59×59.
- [x] SB-M04-013 53×59.
- [x] SB-M04-014 Easy 20×30 fails legacy production validation.
- [x] SB-M04-015 Medium 39×40 fails.
- [x] SB-M04-016 Hard 49×50 fails.
- [x] SB-M04-017 Very Hard 49×59 fails.
- [x] SB-M04-018 59×59 loads successfully.
- [x] SB-M04-019 `cell_count == 3481`.
- [x] SB-M04-020 Coordinate/index tests pass at 59×59.
- [x] SB-M04-021 State mutation tests pass at 59×59.
- [x] SB-M04-022 Performance sanity benchmark runs at 3,481 cells.
- [x] SB-M04-023 Record results without arbitrary strict timing threshold.

### M05 — Test Harness Maturity

- [x] SB-M05-001 Headless test script exists.
- [x] SB-M05-002 Test process returns failure exit code.
- [x] SB-M05-003 Current tests print PASS/failure information.
- [x] SB-M05-004 No third-party test framework required.
- [x] SB-M05-005 Current baseline checks pass.
- [ ] SB-M05-006 Organize test sections as suite grows.
- [ ] SB-M05-007 Separate performance benchmark output from assertions.
- [ ] SB-M05-008 Add one-command PowerShell full-test wrapper if useful.
- [ ] SB-M05-009 Add regression test conventions to docs.
- [ ] SB-M05-010 Ensure future milestone completion requires regression pass.

### M06 — Board Renderer

- [x] SB-M06-001 Define BoardRenderer responsibility.
- [x] SB-M06-002 Keep BoardRenderer separate from BoardState.
- [x] SB-M06-003 Evaluate efficient Godot rendering options.
- [x] SB-M06-004 Choose Image/ImageTexture technique.
- [x] SB-M06-005 Record technique in ADR.
- [x] SB-M06-006 Render arbitrary width/height.
- [x] SB-M06-007 Support rectangular board aspect ratio.
- [x] SB-M06-008 Preserve logical pixel boundaries.
- [x] SB-M06-009 Disable unwanted texture filtering.
- [x] SB-M06-010 Render palette colors correctly.
- [x] SB-M06-011 Render 20×20.
- [x] SB-M06-012 Render 29×29.
- [x] SB-M06-013 Render 39×39.
- [x] SB-M06-014 Render 49×49.
- [x] SB-M06-015 Render 50×50.
- [x] SB-M06-016 Render 59×59.
- [x] SB-M06-017 Render representative rectangular boards.
- [x] SB-M06-018 Expose logical-cell center coordinate.
- [x] SB-M06-019 Support efficient individual-cell update.
- [x] SB-M06-020 Support full reset.
- [x] SB-M06-021 Benchmark 3,481-cell display.
- [x] SB-M06-022 Confirm no 3,481-cell Node tree exists.

### M07 — Visual Reference Library `[VISUAL REFERENCE]`

- [x] SB-M07-001 Establish reference directory structure.
- [x] SB-M07-002 Create visual-reference README/guide.
- [x] SB-M07-003 Separate original SCRUBBOTS art from external inspiration.
- [x] SB-M07-004 Define canonical asset naming.
- [x] SB-M07-005 Define asset type metadata.
- [x] SB-M07-006 Define owner-approved status.
- [x] SB-M07-007 Preserve source file originals.
- [x] SB-M07-008 Inventory Scrubbot character visuals supplied by owner.
- [x] SB-M07-009 Inventory gameplay-screen references supplied by owner.
- [x] SB-M07-010 Inventory five-slot visual references.
- [ ] SB-M07-011 Inventory level images beyond current M21 source as they are supplied/approved.
- [ ] SB-M07-012 Inventory underwater level artwork if supplied.
- [ ] SB-M07-013 Inventory other original theme artwork.
- [x] SB-M07-014 Inventory pixel-construction reference screenshots.
- [x] SB-M07-015 Inventory external movement references separately.
- [x] SB-M07-016 Flag unavailable assets as `AWAITING OWNER ASSET`.
- [x] SB-M07-017 Never regenerate missing references and label them originals.

**Master UI / generated visual reference tasks (from UI_TASKS_APPENDIX migration)**
- [x] SB-UI-001 Treat `docs/MASTER_UI_SYSTEM.md` as the UI architecture source of truth.
- [x] SB-UI-002 Treat `ASSET_GENERATION_MANIFEST.json` as the machine-readable generation/provenance queue.
- [x] SB-UI-003 Keep approved provider decisions scoped by asset type and newest owner decisions.
- [x] SB-UI-004 Do not add unapproved generation providers as project runtime dependencies.
- [x] SB-UI-005 Import owner visual references copy-only.
- [x] SB-UI-006 Preserve originals/copies byte-for-byte and inventory before promotion.
- [x] SB-UI-007 Classify owner references.
- [ ] SB-UI-008 Select and record canonical Scrubby master reference before final Scrubby production generation.
- [x] SB-UI-009 Select canonical gameplay-screen art-direction reference.
- [x] SB-UI-010 Select canonical Home-screen art-direction reference.
- [x] SB-UI-011 Select canonical popup/level-intro references.
- [x] SB-UI-012 Identify conflicting/outdated references and retain as non-canonical history.
- [ ] SB-UI-013 Validate manifest reference paths/IDs after canonical references are selected.

### M08 — Level Art Technical Audit `[CONTENT] [VISUAL REFERENCE]`

Per candidate production pixel-art level:

- [ ] SB-M08-001 Record filename.
- [ ] SB-M08-002 Record original dimensions.
- [ ] SB-M08-003 Record alpha/transparency.
- [ ] SB-M08-004 Count colors.
- [ ] SB-M08-005 Detect anti-aliasing.
- [ ] SB-M08-006 Detect interpolation.
- [ ] SB-M08-007 Determine logical-pixel grid.
- [ ] SB-M08-008 Determine legal production envelope/context.
- [ ] SB-M08-009 Confirm width in legal engine envelope.
- [ ] SB-M08-010 Confirm height in legal engine envelope.
- [ ] SB-M08-011 Preserve original.
- [ ] SB-M08-012 Never silently resize.
- [ ] SB-M08-013 Explicitly map/reject source colors against locked C01..C16; never invent C17+; record deterministic mapping/rejection evidence.
- [ ] SB-M08-014 Produce audit report.

### M09 — Pixel Art → Level Data Pipeline `[CONTENT]`

- [x] SB-M09-001 Create importer tool.
- [x] SB-M09-002 Read source pixels exactly.
- [x] SB-M09-003 Determine width.
- [x] SB-M09-004 Determine height.
- [x] SB-M09-005 Determine/validate legacy compatibility difficulty where required.
- [x] SB-M09-006 Extract unique palette.
- [x] SB-M09-007 Produce stable palette ordering.
- [x] SB-M09-008 Convert pixels to palette IDs.
- [x] SB-M09-009 Flatten using canonical row-major mapping.
- [x] SB-M09-010 Produce Level Data V1.
- [x] SB-M09-011 Store source-asset metadata where useful.
- [x] SB-M09-012 Deterministic output.
- [x] SB-M09-013 Re-running importer produces no meaningless diff.
- [x] SB-M09-014 Reconstruct image from generated data.
- [x] SB-M09-015 Pixel-compare reconstruction.
- [x] SB-M09-016 Generate preview.
- [x] SB-M09-017 Reject unsupported/broken art with useful reason.
- [x] SB-M09-018 Batch import.
- [x] SB-M09-019 Batch validation.
- [x] SB-M09-020 Duplicate level ID protection.

**M09 palette-lock note:** M09's completed exact-source-pixel importer remains valid historical/generic tooling evidence, but production acceptance additionally obeys current canonical palette/art/difficulty systems. Historical completion is not rewritten.

### M10 — ACTIVE/CLEARED Board Visual Model `[OWNER DECISION LOCKED]`

- [x] SB-M10-001 ACTIVE appearance locked to original source palette color, opaque.
- [x] SB-M10-002 CLEARED appearance locked to alpha 0/background visible.
- [x] SB-M10-003 Define artwork-clearing relationship.
- [x] SB-M10-004 Implement visual mapping.
- [x] SB-M10-005 Owner-confirm clearing readability.
- [x] SB-M10-006 Owner-confirm ACTIVE artwork recognition.
- [x] SB-M10-007 Owner test Easy density.
- [x] SB-M10-008 Owner test Medium density.
- [x] SB-M10-009 Owner test Hard density.
- [x] SB-M10-010 Owner test Very Hard density.
- [x] SB-M10-011 Owner test 59×59 transparent-model readability.
- [x] SB-M10-012 Development debug tool migrated/proven.

### M11 — Gameplay Session Core

- [x] SB-M11-001 Define session states.
- [x] SB-M11-002 Initialize level.
- [x] SB-M11-003 Load LevelData.
- [x] SB-M11-004 Create BoardState.
- [x] SB-M11-005 Connect renderer.
- [x] SB-M11-006 Define ready state.
- [x] SB-M11-007 Define active state.
- [x] SB-M11-008 Define pause.
- [x] SB-M11-009 Define reset.
- [x] SB-M11-010 Define completion transition.
- [x] SB-M11-011 Keep UI separate from gameplay truth.
- [x] SB-M11-012 Headless lifecycle tests.

### M12 — Five-Slot Logic

- [x] SB-M12-001 Create SlotState.
- [x] SB-M12-002 Create SlotSystem.
- [x] SB-M12-003 Configure five gameplay slots.
- [x] SB-M12-004 Slot identity.
- [x] SB-M12-005 Slot palette/color.
- [x] SB-M12-006 Slot availability.
- [x] SB-M12-007 Slot activity state.
- [x] SB-M12-008 Keep model separate from UI.
- [x] SB-M12-009 Query API.
- [x] SB-M12-010 Five-slot tests.
- [x] SB-M12-011 Invalid slot tests.

Remaining slot mechanics are `[DESIGN GATE]` except where newer owner decisions explicitly lock behavior.

### M13 — Color Candidate Index `[PERFORMANCE]`

- [x] SB-M13-001 Define color candidate.
- [x] SB-M13-002 Group/query by color.
- [x] SB-M13-003 Implement efficient index/cache if measured useful.
- [x] SB-M13-004 Synchronize with BoardState.
- [x] SB-M13-005 Remove CLEARED cells from the index.
- [x] SB-M13-006 Handle caller exclusions/reservations seam.
- [x] SB-M13-007 No-candidate query.
- [x] SB-M13-008 Exhausted-color test.
- [x] SB-M13-009 Last-candidate test.
- [x] SB-M13-010 3,481-cell benchmark.

### M14 — Reservation State

- [x] SB-M14-001 Define reservation ownership.
- [x] SB-M14-002 Decide RESERVED placement.
- [x] SB-M14-003 Record decision.
- [x] SB-M14-004 Reserve target atomically.
- [x] SB-M14-005 Prevent double reservation.
- [x] SB-M14-006 Release on dispatch failure.
- [x] SB-M14-007 Release on reset.
- [x] SB-M14-008 Resolve arrival.
- [x] SB-M14-009 Concurrency tests.

### M15 — TargetSelector

M15 strict closure remains accepted. V04 later superseded only its target ordering policy while preserving strict safety contracts.

- [x] SB-M15-001 Create TargetSelector.
- [x] SB-M15-002 Keep BoardState access narrow.
- [x] SB-M15-003 Deterministic strategy. **Current production ordering is owner rule §8.10A: bottom-most then left-most among targetable candidates.**
- [x] SB-M15-004 Match Scrubbot color.
- [x] SB-M15-005 Never target CLEARED.
- [x] SB-M15-006 Never target invalid or blocked/unreachable ACTIVE cells.
- [x] SB-M15-007 Respect reservations.
- [x] SB-M15-008 Return no-target cleanly.
- [x] SB-M15-009 No route generation inside selector.
- [x] SB-M15-010 Determinism tests.
- [x] SB-M15-011 Simultaneous assignment tests.
- [x] SB-M15-012 3,481-cell benchmark.

### M16 — RoutingSystem Interface

- [x] SB-M16-001 Define RoutingSystem contract.
- [x] SB-M16-002 Define route input.
- [x] SB-M16-003 Define route output.
- [x] SB-M16-004 Define coordinate space.
- [x] SB-M16-005 Slot origin.
- [x] SB-M16-006 Cell destination.
- [x] SB-M16-007 Keep independent from TargetSelector.
- [x] SB-M16-008 Swappable implementations.
- [x] SB-M16-009 Debug route visualization.
- [x] SB-M16-010 Route validity checks.
- [x] SB-M16-011 Failure behavior/no silent retarget.

### M17 — Routing Prototype Lab / Production Routing

M17-C002 V03 strict full-surface audit remains accepted as the pre-V07 production-routing baseline. V07 added the adjacent one-cell exterior ring and remains valid historical M21 evidence. The 2026-09-14 owner decision in `OWNER_SCRUBBOT_RAILROAD_DECISION_V01.md` supersedes that exact exterior geometry for future production once M22 V02 passes audit; the M17 safety contracts remain mandatory.

- [x] SB-M17-001 Direct route baseline.
- [x] SB-M17-002 Grid-aware route prototype.
- [x] SB-M17-003 Organized polyline/curved prototype.
- [x] SB-M17-004 Compare visual clarity.
- [x] SB-M17-005 Compare path crossings.
- [x] SB-M17-006 Compare congestion.
- [x] SB-M17-007 Compare CPU cost.
- [x] SB-M17-008 Compare route distance.
- [x] SB-M17-009 Compare determinism.
- [x] SB-M17-010 Owner-selected organized/curved production movement language.
- [x] SB-M17-011 Test 5 bots.
- [x] SB-M17-012 Test 10 bots.
- [x] SB-M17-013 Test 25 bots.
- [x] SB-M17-014 Stress-test higher density.
- [x] SB-M17-015 Test 59×59.
- [x] SB-M17-016 Test rectangular board.

**Historical V07 amendment:** the one-cell exterior ring proved exterior reachability and is preserved as audit history. **Current owner target:** Railroad V1 must preserve route validation, no-retarget, ACTIVE-blocker/CLEARED-open semantics, rectangular support and 59×59 behavior while replacing the exact adjacent-ring movement geometry.

### M18 — Scrubbot Agent

- [x] SB-M18-001 Lightweight agent core.
- [x] SB-M18-002 Assigned color.
- [x] SB-M18-003 Assigned target.
- [x] SB-M18-004 Assigned route.
- [x] SB-M18-005 Spawn origin.
- [x] SB-M18-006 Route movement.
- [x] SB-M18-007 Arrival detection.
- [x] SB-M18-008 Completion event.
- [x] SB-M18-009 Despawn.
- [x] SB-M18-010 No return-to-slot.
- [x] SB-M18-011 No resource carrying.
- [x] SB-M18-012 Reset cancellation.
- [x] SB-M18-013 No orphan nodes.
- [x] SB-M18-014 Performance stress test.
- [x] SB-M18-015 Pool only if profiling justifies it.

### M19 — Scrubbot Dispatcher

**Strict-v2 final closure:** M19-C001 V06 `AUDITED_PASS / STRICT_V2_FINAL_CLOSURE`.

- [x] SB-M19-001 Receive slot request.
- [x] SB-M19-002 Check reachable work before spawn.
- [x] SB-M19-003 Ask TargetSelector.
- [x] SB-M19-004 Refuse spawn without reachable target.
- [x] SB-M19-005 Reserve target.
- [x] SB-M19-006 Spawn exactly one bot per dispatch.
- [x] SB-M19-007 Enforce one-by-one flow.
- [x] SB-M19-008 Prevent duplicate assignments.
- [x] SB-M19-009 Handle dispatch failure.
- [x] SB-M19-010 Handle rapid input.
- [x] SB-M19-011 Concurrent slot tests.
- [x] SB-M19-012 Reset during dispatch.

### M20 — Complete Clearing Vertical Slice

- [x] SB-M20-001 Wire complete sequence.
- [x] SB-M20-002 No target means no bot.
- [x] SB-M20-003 No return behavior.
- [x] SB-M20-004 One-cell test.
- [x] SB-M20-005 One-color test.
- [x] SB-M20-006 Multi-color test.
- [x] SB-M20-007 Five-slot test.
- [x] SB-M20-008 Easy board test.
- [x] SB-M20-009 Medium board test.
- [x] SB-M20-010 Hard board test.
- [x] SB-M20-011 Very Hard board test.
- [x] SB-M20-012 59×59 stress test.
- [x] SB-M20-013 Rectangular board test.
- [x] SB-M20-014 State-desynchronization check.

### M21 — First Real-Art Vertical Slice `[CONTENT] [VISUAL REFERENCE]`

**Strict-v2 final closure:** M21-C001 V10 `AUDITED_PASS / STRICT_V2_FINAL_CLOSURE` (`coordination/sessions/M21-C001/CHATGPT_AUDIT_V10.md`). Owner manual V07 Godot gate PASS remains part of the closure basis. V08–V10 were production-immutable validation passes.

The owner-approved real Hazard Bot source is:
`assets/art/levels/source/easy/scrubbots_m21_level_001_hazard_bot_20x20.png`.

Locked runtime outcomes carried forward:
- visible slot-click-only gameplay activation; no SPACE/hidden keyboard dispatch;
- historical-at-M21-close adjacent one-logical-cell exterior routing ring on all four sides, now superseded as future production geometry by Railroad V1 while its safety evidence remains valid;
- TargetSelector bottom-most then left-most among currently targetable matching cells;
- fresh Hazard Bot C08 first target index `380`, coordinate `(0,19)`;
- real clicked-slot spawn anchor -> routing -> authenticated arrival -> ACTIVE→CLEARED transparency;
- exact ReservationState/dispatcher/agent lifecycle under rapid input and reset;
- full 400-cell real-art clear across all five colors;
- reference composite and generated LevelData/preview/metadata reproducible/unchanged.

- [x] SB-M21-001 Ingest original source artwork.
- [x] SB-M21-002 Audit source dimensions.
- [x] SB-M21-003 Determine legal compatibility context.
- [x] SB-M21-004 Generate level data.
- [x] SB-M21-005 Reconstruct and compare.
- [x] SB-M21-006 Render in gameplay.
- [x] SB-M21-007 Populate and visibly present exactly five functional slots bound to the real SlotSystem.
- [x] SB-M21-008 Dispatch a visibly moving real ScrubbotAgent from the clicked visible slot through board-aligned presentation and exterior corridor.
- [x] SB-M21-009 Clear actual artwork pixels (ACTIVE→CLEARED; transparent background reveal).
- [x] SB-M21-010 Run full level.
- [x] SB-M21-011 Profile performance.
- [x] SB-M21-012 Capture reference gameplay output.

**First real-art vertical slice additions**
- [x] SB-UI-014 Run at least one gameplay vertical slice using owner-approved real pixel/level artwork.
- [x] SB-UI-015 Prove logical renderer/ACTIVE-CLEARED treatment/responsive presentation remain data-driven.
- [x] SB-UI-016 Record visual gaps requiring later illustration generation.

### M22 — Production Slot UI `[VISUAL REFERENCE]`

**V01 audit:** `AUDITED_PASS / PRODUCTION_SLOT_FOUNDATION_ACCEPTED` (`coordination/sessions/M22-C001/CHATGPT_AUDIT_V01.md`). V01 created the reusable native-Godot production SlotCell/ColorSelectionPanel foundation, corrected the active manifest palette/difficulty contract, validated real reference authority, touch size, responsive/safe-area behavior, active-state lifecycle and real slot-click integration while spending zero Magnific credits.

**Railroad V1 closure — V07 + owner acceptance (2026-09-17):** the accepted production movement contract is now exact clicked-slot anchor → visible BOTTOM connector → canonical Railroad V1 exterior travel → legal rail ingress → four-neighbour orthogonal OPEN/CLEARED interior corridor with one or more 90-degree turns → assigned ACTIVE target. Non-target ACTIVE cells remain blockers; no diagonal/corner-cut/teleport/free-space shortcut and no retargeting are allowed. V07 implementation evidence recorded 4,823 checks / 0 failures and preserved the fresh Hazard Bot C08 first target `380/(0,19)`. Owner manual review confirmed the routing correction. The earlier straight-only final target approach is superseded.

- [x] SB-M22-001 Audit slot references.
- [x] SB-M22-002 Create SlotView.
- [x] SB-M22-003 Five-slot layout.
- [x] SB-M22-004 Bind SlotState through safe scalar/query presentation binding.
- [x] SB-M22-005 Color presentation.
- [x] SB-M22-006 Touch target.
- [x] SB-M22-007 Active state.
- [ ] SB-M22-008 No-work state if approved.
- [x] SB-M22-009 Scrubbot spawn point / final slot→rail connector geometry.
- [x] SB-M22-010 Aspect-ratio tests.
- [x] SB-M22-011 Safe-area tests.
- [x] SB-M22-012 Rapid-tap tests.
- [x] SB-M22-013 Confirm canonical gameplay UI references before final asset generation.
- [x] SB-M22-014 Validate M22 manifest entries before spending generation credits.
- [ ] SB-M22-015 Generate the four owner-locked gameplay booster assets (+1 Slot, Random, Selector, Tornado) when Economy V1 implementation scope opens.
- [ ] SB-M22-016 Generate only milestone-required decorative assets.
- [ ] SB-M22-017 Keep raw candidates separate from production-final assets/provenance.
- [ ] SB-M22-018 Require owner selection/approval before production promotion.
- [ ] SB-M22-019 Never silently regenerate/overwrite approved production art.
- [x] SB-M22-020 Build slot visuals as reusable Godot components.
- [ ] SB-M22-021 Keep quantities/text/state badges live in Godot.
- [ ] SB-M22-022 Implement reusable BoosterButton states for CHARGE_AVAILABLE / PURCHASABLE_SB / SELECTED / UNAVAILABLE / LOCKED when Economy V1 booster scope opens.
- [ ] SB-M22-023 Bind approved booster/decorative art to reusable components.
- [x] SB-M22-024 Preserve five visible slots at required responsive sizes.
- [ ] SB-M22-025 Validate import/transparency/filtering/mobile memory before visual closure.

**Railroad V1 additions [OWNER-LOCKED 2026-09-14]**
- [x] SB-M22-026 Implement one canonical/single-source ScrubRail geometry contract from board W/H.
- [x] SB-M22-027 Implement reusable four-side robotic cleaning railroad presentation with rounded corners and restrained cyan/electric accents.
- [x] SB-M22-028 Enforce 2.0 logical-cell artwork clearance, 1.0 rail width and 2.5-cell rail centerline offset across variable board sizes.
- [x] SB-M22-029 Connect each real clicked SlotCell visibly to the BOTTOM rail from its exact laid-out spawn anchor.
- [x] SB-M22-030 Constrain exterior Scrubbot travel to railroad sides/corners; prohibit free-space diagonal/early-exit shortcuts.
- [x] SB-M22-031 Leave Railroad V1 only through a legal rail ingress into OPEN/CLEARED perimeter space; permit four-neighbour orthogonal interior-corridor routing with one or more 90-degree turns; never retarget.
- [x] SB-M22-032 Use one consistent Railroad V1 visual language across all levels; no per-level themed rail in V1.
- [x] SB-M22-033 Validate Railroad V1 on rectangular boards, 59×59 and the required responsive viewport matrix.
- [x] SB-M22-034 Preserve rapid-dispatch reservations/active visuals and reset cleanup while multiple Scrubbots are on connector/rail travel.
- [x] SB-M22-035 Owner F6 visual/game-feel acceptance of the production Railroad V1 demo after strict audit.

### M23 — Batch Supply Engine `[OWNER-LOCKED CORE GAMEPLAY]`

Purpose: create the player-facing color/count supply queues that drive the real ScrubBots puzzle. This milestone owns batch data, queue/preview semantics and candidate generation, but does not own five-slot execution, target claims, robot dispatch or solvability proof.

- [x] SB-M23-001 Define immutable `ColorBatch` value contract.
- [x] SB-M23-002 Give every batch a stable unique `batch_id` for the lifetime of a session.
- [x] SB-M23-003 Store canonical palette/color ID, never presentation-only color guesses.
- [x] SB-M23-004 Store strictly positive integer `robot_count`; reject zero, negative, float, string or overflow values.
- [x] SB-M23-005 Preserve per-color conservation: total generated batch quota for each color must equal that level's required ACTIVE logical-pixel count for that color unless a later explicit owner rule changes the economy.
- [x] SB-M23-006 Reject supply containing palette IDs absent from the loaded level/palette contract.
- [x] SB-M23-007 Support exactly 3, 4 or 5 independent supply columns as configuration; do not hard-code one layout into gameplay truth.
- [x] SB-M23-008 Support configurable visible preview depth 3 or 4, with V1/Hazard Bot validation locked to exactly 3 visible rows.
- [x] SB-M23-009 Make only the front/top batch of each column selectable.
- [x] SB-M23-010 Make visible Row 2 and Row 3 preview-only in V1; they must reject gameplay activation.
- [x] SB-M23-011 Keep every batch deeper than the visible preview window hidden from player-facing query/UI APIs.
- [x] SB-M23-012 Implement each supply column as an independent FIFO queue.
- [x] SB-M23-013 Selecting a legal front batch removes exactly that one front item from exactly that one column.
- [x] SB-M23-014 After selection, advance that column by one: old Row 2→front, old Row 3→Row 2, next hidden→Row 3.
- [x] SB-M23-015 Prove selecting one column does not mutate ordering/content of any other column.
- [x] SB-M23-016 Expose read-only front-batch queries for gameplay selection.
- [x] SB-M23-017 Expose read-only preview queries that cannot reveal hidden queue contents.
- [x] SB-M23-018 Make supply consumption transactional so a rejected downstream slot placement cannot accidentally pop/advance the column.
- [x] SB-M23-019 Define deterministic seedable candidate generation for reproducible tests/replays.
- [x] SB-M23-020 Persist/report the generation seed with the session fixture/evidence.
- [x] SB-M23-021 Partition each level color total into legal positive batch sizes without losing or inventing quota.
- [x] SB-M23-022 Distribute generated batches across configured columns without changing per-color conservation.
- [x] SB-M23-023 Avoid malformed queues: no null batch, duplicate `batch_id`, negative count, invalid color or impossible index.
- [x] SB-M23-024 Define clean end-of-column behavior when fewer than the normal preview rows remain.
- [x] SB-M23-025 Define clean end-of-supply behavior when every column is exhausted.
- [x] SB-M23-026 Provide deterministic reset to the exact initial queue/seed state.
- [x] SB-M23-027 Provide snapshot/query data needed later by save/replay systems without coupling to UI Nodes.
- [x] SB-M23-028 Build Hazard Bot candidate supply fixtures from the real 20×20 level color totals.
- [x] SB-M23-029 Validate rectangular-board and 59×59 quota/conservation behavior.
- [x] SB-M23-030 Add invalid-input, deterministic-generation, FIFO, hidden-preview and conservation regression tests.

### M24 — Five-Slot Batch Engine `[OWNER-LOCKED CORE GAMEPLAY]`

Purpose: replace the temporary directly-colored slot interaction with the real five EMPTY baseline batch slots. Player chooses a supply batch; the engine chooses the slot automatically.

**Economy V1 amendment:** the accepted M24 implementation remains the five-slot baseline. M39 must add an explicit runtime-capacity extension 5→6 for the +1 Slot booster without falsifying historical M24 audit evidence.

- [x] SB-M24-001 Preserve the production invariant of exactly five gameplay batch slots.
- [x] SB-M24-002 Initialize all five batch slots EMPTY at level/session start.
- [x] SB-M24-003 Define `SlotBatchState` independent of Godot presentation controls.
- [x] SB-M24-004 Store `batch_id`, color ID, initial count, remaining-to-clear count, committed/in-flight count and placement sequence per occupied slot.
- [x] SB-M24-005 Define explicit slot lifecycle states at minimum `EMPTY`, `ACTIVE` and `WAITING` without duplicating BoardState truth.
- [x] SB-M24-006 On accepted supply selection, place the batch automatically into the rightmost currently EMPTY slot.
- [x] SB-M24-007 Do not expose any production mechanic that asks the player to choose a destination slot.
- [x] SB-M24-008 Never shift, reorder or compact already-occupied slots merely because another slot becomes empty.
- [x] SB-M24-009 If holes exist, choose the rightmost available hole deterministically.
- [x] SB-M24-010 If all five slots are occupied, reject the new batch atomically.
- [x] SB-M24-011 On full-slot rejection, prove the originating supply column does not advance and the batch remains selectable.
- [x] SB-M24-012 Allow multiple occupied slots to contain the same color simultaneously.
- [x] SB-M24-013 Preserve stable batch identity after placement; never merge same-color batches silently.
- [x] SB-M24-014 Enforce `0 <= committed <= remaining_to_clear <= initial_count` at all times.
- [x] SB-M24-015 Define dispatch capacity as `remaining_to_clear - committed`.
- [x] SB-M24-016 Do not reduce `remaining_to_clear` on player selection, claim, route calculation or spawn.
- [x] SB-M24-017 Reduce `remaining_to_clear` only after authenticated successful clearing of one batch-owned target.
- [x] SB-M24-018 Reduce `committed` when the corresponding live assignment resolves or is safely rolled back.
- [x] SB-M24-019 A batch is complete only when `remaining_to_clear == 0` and `committed == 0`.
- [x] SB-M24-020 Return the slot to EMPTY immediately and deterministically after true batch completion.
- [x] SB-M24-021 If remaining quota exists but no matching target is currently claimable, enter WAITING without discarding the batch.
- [x] SB-M24-022 Resume a WAITING batch automatically when later BoardState changes expose claimable matching work.
- [x] SB-M24-023 Ensure a newly freed slot can accept the next player-selected supply batch using the same rightmost-empty rule.
- [x] SB-M24-024 Expose read-only slot occupancy/count/state queries for presentation without leaking mutable internal state.
- [x] SB-M24-025 Preserve exact slot/batch state across pause/resume.
- [x] SB-M24-026 Reset clears all batch occupancy, counters, placement sequence and transient state deterministically.
- [x] SB-M24-027 Make rapid repeated supply selections transactional; no duplicate batch insertion or double column advance.
- [x] SB-M24-028 Add the canonical three-same-color example (`BLUE 8`, `BLUE 14`, `BLUE 12`) as a regression fixture.
- [x] SB-M24-029 Test five-full-slot rejection followed by a completion/free-slot/new-selection cycle.
- [x] SB-M24-030 Add headless invariant tests for every state transition and invalid slot/batch mutation.

### M25 — Batch Target Claim Engine `[OWNER-LOCKED CORE GAMEPLAY]`

Purpose: arbitrate currently targetable pixels among multiple live batches, especially duplicate colors, while preserving ReservationState and TargetSelector as the existing low-level safety authorities.

- [x] SB-M25-001 Define a session-scoped Batch Target Claim service/ledger with narrow APIs.
- [x] SB-M25-002 Keep existing `ReservationState` as the authoritative live target-reservation mechanism; do not create contradictory duplicate reservation truth.
- [x] SB-M25-003 Represent each live claim with batch ID, slot ID, target index/coordinate, color and reservation/assignment identity.
- [x] SB-M25-004 Permit claims only for currently ACTIVE, matching-color, valid, unreserved and production-targetable pixels.
- [x] SB-M25-005 Never pre-claim a future pixel that is currently blocked/unreachable merely because it may become reachable later.
- [x] SB-M25-006 Support multiple simultaneous occupied batches of the same color.
- [x] SB-M25-007 Arbitrate same-color batches by oldest placement sequence first (FIFO).
- [x] SB-M25-008 Make placement-sequence arbitration deterministic across reset/replay fixtures.
- [x] SB-M25-009 Keep giving newly claimable work to the oldest same-color batch while it has uncommitted dispatch capacity.
- [x] SB-M25-010 When the oldest batch has no remaining dispatch capacity, allow additional matching targets to flow to the next same-color batch.
- [x] SB-M25-011 Keep different colors independent except for shared global ReservationState uniqueness.
- [x] SB-M25-012 Preserve TargetSelector's bottom-most then left-most order among currently targetable matching unreserved candidates.
- [x] SB-M25-013 Make target selection + batch ownership claim + ReservationState reservation one atomic logical transaction.
- [x] SB-M25-014 Prove one target index can never belong to two live batches/robots at once.
- [x] SB-M25-015 Prove one batch can never create duplicate live claims to the same target.
- [x] SB-M25-016 Refuse claim when the batch has zero dispatch capacity.
- [x] SB-M25-017 Increment `committed` exactly once when a claim becomes an accepted live assignment.
- [x] SB-M25-018 Do not change `remaining_to_clear` merely because a claim exists.
- [x] SB-M25-019 If route construction/validation fails before spawn, atomically release claim and reservation, decrement committed appropriately, consume zero batch quota and spawn no robot.
- [x] SB-M25-020 On authenticated arrival/clear, resolve exactly the claim associated with that robot/assignment.
- [x] SB-M25-021 Never allow a robot to clear any target other than its immutable claimed target.
- [x] SB-M25-022 On successful authenticated clear, decrement batch remaining and committed exactly once.
- [x] SB-M25-023 Fail closed on stale/already-cleared/invalid claim state; no duplicate clear, no quota loss and no ghost spawn.
- [x] SB-M25-024 Release every live claim/reservation safely on reset/session teardown.
- [x] SB-M25-025 Prevent slot completion while any claim/assignment for that batch remains committed.
- [x] SB-M25-026 Mark a batch WAITING when it has remaining quota but no claimable matching target.
- [x] SB-M25-027 Re-evaluate waiting colors after authoritative BoardState clear events rather than polling mutable UI state.
- [x] SB-M25-028 Add simultaneous same-color claim race tests under rapid scheduler activity.
- [x] SB-M25-029 Prove `BLUE 8`, `BLUE 14`, `BLUE 12` cannot target the same pixel and obey oldest-batch-first ownership when new blue pixels open.
- [x] SB-M25-030 Prove newly opened targets are assigned at opening time, not pre-owned while inaccessible.
- [x] SB-M25-031 Stress five occupied slots with duplicate colors on rectangular and 59×59 boards.
- [x] SB-M25-032 Add claim/reservation leak, reset, stale-target and deterministic-order regression tests.
- [x] SB-M25-033 Bound 59x59 target-selection scan cost investigation: reproduced the M29 multi-second spike and proved it was caused by UNLAID board-internal slot origins; real laid-out 59x59 uses <=1 route probe/lane with 0 failed probes but still has a real O(candidates) WHAT-side scan and separate winning-route Dijkstra cost. Findings: `coordination/sessions/M25-C002/M25_59X59_TARGET_SELECTION_FINDINGS_V01.md`; audit: `coordination/sessions/M25-C002/CHATGPT_AUDIT_V01.md`. `[INVESTIGATION_AUDITED_PASS / CLOSED 2026-09-29]`
- [x] SB-M25-034 Implement S0+S1 exact-safe target-selection optimization: corrected the 59x59 performance harness to real laid-out exterior slot origins; materialized the existing exact-safe touchability condition as an O(1) per-revision ProductionTargetAccess mask; added an optional conservative prefilter so TargetSelector skips only provably impossible candidates while preserving exact bottom-most/left-most winner, WHAT/HOW separation, reservation/coherence/rollback truth and fallback behavior. Implementation `aadc57253d45dcd6b71ca8cc1b00b7a7684e0574`; audit `coordination/sessions/M25-C003/CHATGPT_AUDIT_V01.md`. `[AUDITED_PASS / CLOSED 2026-09-29]`
- [x] SB-M25-035 S2 exact-equivalent Railroad / Dijkstra acceleration: optimized HOW-side production Railroad routing while preserving the frozen pre-S2 `aadc5725...` RouteResult point-for-point. Differential: 48,202 comparisons, 0 diffs; equal-weight/noncanonical/near-tie fallbacks preserved. Clean laid-out 59x59: route Dijkstra p99 ~0.25 ms, frame p99 ~4–5 ms, ~99% route-time reduction, S1 scan <=3 ms, <=1 route probe/lane. Implementation `eb16c2f1e082f9c2449e4ac98840a6f68f483126`; audit `coordination/sessions/M25-C004/CHATGPT_AUDIT_V01.md`. `[AUDITED_PASS / CLOSED 2026-09-29]`

### M26 — Auto Dispatch Scheduler `[OWNER-LOCKED CORE GAMEPLAY]`

Purpose: turn an occupied color/count batch into autonomous Scrubbot work. The player selects batches, not individual robots and not individual target pixels.

- [x] SB-M26-001 Define a gameplay-domain Auto Dispatch Scheduler independent of presentation/UI animation.
- [x] SB-M26-002 Automatically attempt work for every occupied batch without requiring repeated player taps on the five slots.
- [x] SB-M26-003 Begin scheduling a newly accepted batch immediately after transactional placement.
- [x] SB-M26-004 Enforce the hard invariant: no currently valid target means no robot spawn.
- [x] SB-M26-005 Enforce the hard invariant: no successful atomic reservation/claim means no robot spawn.
- [x] SB-M26-006 Enforce the hard invariant: no valid RouteValidator-clean route to the exact claimed target means no robot spawn.
- [x] SB-M26-007 Enforce transaction order `claim/reserve → build route → validate route → spawn exact assignment`.
- [x] SB-M26-008 Never retarget after route/assignment acceptance; a failed assignment is rolled back rather than redirected silently.
- [x] SB-M26-009 Spawn from the exact owning SlotCell anchor and preserve the accepted slot→BOTTOM connector + Railroad V1 route semantics.
- [x] SB-M26-010 Spawn exactly one Scrubbot per successful assignment transaction.
- [x] SB-M26-011 Pace sequential dispatch from a given batch/slot; do not materialize its entire count as an uncontrolled one-frame robot burst.
- [x] SB-M26-012 Permit safe concurrent work from different occupied slots when each assignment has a unique reservation/route.
- [x] SB-M26-013 Define deterministic scheduler fairness across different-color ACTIVE batches so one busy color cannot starve all others.
- [x] SB-M26-014 For same-color batches, defer ownership ordering to the Batch Target Claim Engine's oldest-placement-first rule.
- [x] SB-M26-015 Prove a `BLUE 15` batch can autonomously complete exactly 15 authenticated blue-pixel clears when the board makes them legally available.
- [x] SB-M26-016 Track committed/in-flight capacity so a batch never dispatches more robots than its remaining quota permits.
- [x] SB-M26-017 Decrement quota only from successful authenticated clearing callbacks, never from scheduler intent or spawn count.
- [x] SB-M26-018 When no claimable work exists, transition to WAITING without busy-looping, phantom agents or repeated reservation churn.
- [x] SB-M26-019 Wake/reconsider relevant WAITING colors when BoardState clearing changes reachability.
- [x] SB-M26-020 When one new blue pixel opens and several blue batches wait, request arbitration and dispatch only the batch selected by the same-color FIFO rule.
- [x] SB-M26-021 If the oldest same-color batch has only N dispatch-capacity units left and more than N targets open, allow only N claims to it and spill additional claims to the next batch deterministically.
- [x] SB-M26-022 Auto-finish a batch after its final authenticated clear/assignment resolves and return the slot to EMPTY.
- [x] SB-M26-023 Ensure freeing a slot does not reorder other occupied slots or mutate supply queues.
- [x] SB-M26-024 Pause prevents new dispatches while preserving valid in-memory batch/claim state according to session rules.
- [x] SB-M26-025 Resume safely restarts scheduling without duplicate claims/spawns.
- [x] SB-M26-026 Reset/session teardown cancels in-flight scheduling, releases reservations/claims and leaves no orphan Scrubbot Nodes.
- [x] SB-M26-027 Rapid input / simultaneous column selections cannot double-spawn, over-commit quota or duplicate target reservations.
- [x] SB-M26-028 Validate scheduler behavior with multiple duplicate-color batches plus different-color batches concurrently.
- [x] SB-M26-029 Run 59×59/high-agent-density performance sanity and allocation checks.
- [x] SB-M26-030 Add a full Hazard Bot auto-dispatch integration smoke proving no ghost robots, no duplicate targets and exact quota conservation.

### M27 — Solvability / Deadlock Engine `[OWNER-LOCKED CORE GAMEPLAY]`

Purpose: prove generated supply is actually playable under the real baseline mechanics and distinguish temporary waiting from a true no-solution state. This milestone is the final gameplay-engine closure gate before production screen/layout work.

**Economy V1 amendment:** accepted M27 evidence proves the five-slot baseline. M39 must extend solver state/fixtures for temporary six-slot capacity and for Random/Selector/Tornado transactions; do not retroactively claim the completed baseline already proves those booster states.

- [x] SB-M27-001 Define a deterministic solver operating on gameplay-domain state, not rendered UI Nodes.
- [x] SB-M27-002 Consume the real level BoardState/access/routing semantics rather than a contradictory simplified notion of reachability.
- [x] SB-M27-003 Model configured 3/4/5 independent FIFO supply columns.
- [x] SB-M27-004 Model the visible-front rule: only each column's front batch is a legal player choice.
- [x] SB-M27-005 Model preview/hidden queue ordering without allowing the solver to illegally select Row 2/Row 3/hidden batches early.
- [x] SB-M27-006 Model automatic rightmost-empty placement into exactly five slots.
- [x] SB-M27-007 Model full-slot rejection without consuming the selected supply front.
- [x] SB-M27-008 Model batch remaining/committed/WAITING lifecycle exactly as the runtime engine does.
- [x] SB-M27-009 Model same-color oldest-placement-first claim arbitration.
- [x] SB-M27-010 Model targetability using authoritative ProductionTargetAccess/ProductionRoutingSystem semantics, including Railroad V1 legal ingress and post-rail orthogonal turns.
- [x] SB-M27-011 Model dynamic ACTIVE→CLEARED board evolution after authenticated work.
- [x] SB-M27-012 Model WAITING batches becoming runnable when new corridors/targets open.
- [x] SB-M27-013 Search legal player front-batch choices rather than assuming one fixed greedy order.
- [x] SB-M27-014 Find at least one complete sequence that clears every required logical pixel and consumes all required batch quota.
- [x] SB-M27-015 Emit a deterministic solution trace for QA/debug evidence; never expose it to normal player UI.
- [x] SB-M27-016 Accept a generated Batch Supply layout for production only after the solver proves at least one legal completion sequence.
- [x] SB-M27-017 Feed unsolvable candidate layouts back to Batch Supply generation for deterministic retry/regeneration rather than shipping impossible levels.
- [x] SB-M27-018 Preserve generation seed + solver outcome so an accepted/rejected supply can be reproduced exactly.
- [x] SB-M27-019 Canonicalize/memoize equivalent search states to prevent needless combinatorial re-exploration.
- [x] SB-M27-020 Add explicit search/time/state-count bounds and fail closed when proof cannot be completed within policy limits.
- [x] SB-M27-021 Prove the real 20×20 Hazard Bot level has at least one solvable generated batch/column layout under the new five-slot rules.
- [x] SB-M27-022 Persist the Hazard Bot solution trace as regression evidence while keeping player-hidden future batches hidden at runtime.
- [x] SB-M27-023 Add rectangular-board solvability fixtures.
- [x] SB-M27-024 Add 59×59 solver/performance sanity fixtures with bounded evidence appropriate to the search design.
- [x] SB-M27-025 Define `STALLED/WAITING` separately from `DEADLOCK`.
- [x] SB-M27-026 Never call a state deadlocked while any valid in-flight robot can still produce an authenticated clear.
- [x] SB-M27-027 Never call a state deadlocked while an EMPTY slot plus at least one selectable front batch can lead to legal future progress.
- [x] SB-M27-028 Never call a state deadlocked merely because current batches are waiting if already-scheduled/legal clearing can open their targets.
- [x] SB-M27-029 Declare deadlock only when search proves there is no legal future action sequence that can produce further authenticated progress/completion.
- [x] SB-M27-030 Add the canonical true-deadlock fixture: five occupied WAITING batches, no in-flight progress and no legal unlock sequence.
- [x] SB-M27-031 Add false-positive guards where a newly opened same-color target correctly revives the oldest waiting batch.
- [x] SB-M27-032 Expose deterministic deadlock reason codes/debug evidence without coupling lose-screen UI to solver internals.
- [x] SB-M27-033 Reset/replay must reproduce identical solver classification from identical state/seed.
- [x] SB-M27-034 Run performance/memory profiling and regression tests before declaring the core gameplay engine complete.

### M28 — Gameplay Screen Layout `[VISUAL REFERENCE]`

- [x] SB-M28-001 Audit original gameplay reference images.
- [x] SB-M28-002 Board region.
- [x] SB-M28-003 Five-slot region.
- [x] SB-M28-004 HUD region.
- [x] SB-M28-005 Safe areas.
- [x] SB-M28-006 Easy dimensions.
- [x] SB-M28-007 Medium dimensions.
- [x] SB-M28-008 Hard dimensions.
- [x] SB-M28-009 Very Hard dimensions.
- [x] SB-M28-010 Rectangular boards.
- [x] SB-M28-011 59×59.
- [x] SB-M28-012 Narrow phone.
- [x] SB-M28-013 Tall phone.
- [x] SB-M28-014 Tablet portrait.
- [x] SB-M28-015 Input coordinate accuracy.
- [x] SB-M28-016 Use `docs/MASTER_UI_SYSTEM.md` as canonical gameplay layout contract.
- [x] SB-M28-017 Remove Goal/Moves panel from approved production gameplay composition.
- [x] SB-M28-018 Make board dominant gameplay-screen region.
- [x] SB-M28-019 Keep color-selection panel protected/usable.
- [x] SB-M28-020 Place Scrubby low at left of color-selection region.
- [x] SB-M28-021 Place speech bubble above Scrubby.
- [x] SB-M28-022 Preserve right-side cleaning props as lower-priority decoration.
- [x] SB-M28-023 Put four booster controls in compact horizontal row above bottom/ad row.
- [x] SB-M28-024 Historical M28 baseline completed. Superseded placement: Gameplay Composition V02 moves Pause + 2x side by side to top-right; current playtest/reference has no ad banner and no Settings.
- [x] SB-M28-025 Do not restore removed Level/lock rail.
- [x] SB-M28-026 Bind owner-approved illustrations while keeping screen responsive/native.
- [x] SB-M28-027 Prove BoardRenderer coordinate mapping after responsive scaling.
- [x] SB-M28-028 Capture viewport validation evidence.

**Gameplay Composition V02 owner amendment [2026-09-19]:** `coordination/OWNER_GAMEPLAY_SCREEN_COMPOSITION_V02.md` is now canonical for gameplay layout. Preserve the owner-supplied baseline screen, integrate full Railroad V1 around the board, show five permanent slot-to-bottom-rail connectors, retain the five-slot + Batch Supply panel, place Pause + 2x side by side top-right, remove gameplay Settings/Heart HUD, and omit the ad banner from the current owner playtest/reference mockup. This is a presentation amendment; accepted historical M28/M29 evidence remains historical and later responsive/polish work must converge to V02.

#### M28-C002 - Gameplay Screen V02 Production Convergence [PLANNED / REQUIRED BEFORE FINAL META-UI INTEGRATION]

**M28-C002-C002/R01 static-shell status:** technical PASS and FINAL OWNER VISUAL PASS. Six-master matrix (5/6 slots × 3/4/5 supply columns), 2.4-cell mini Scrubbots, live bubble copy, responsive/touch choices and S1-S6 are owner-accepted. Row 016 is closed. Rows 012-015/018(part)/019/020 remain dependency/final-gate work.

**M28-C002-C003-R01 V02 closure:** independent `AUDITED_PASS` followed by OWNER FINAL REPLAY PASS. Audit: `coordination/sessions/M28-C002-C003-R01/CHATGPT_AUDIT_V02.md`. Owner gate: `coordination/sessions/M28-C002-C003/OWNER_GAMEPLAY_V02_FINAL_GATE_V01.md`. SB-M28-C002-020 is closed.

Purpose: turn the owner-approved Gameplay Composition V02 and gameplay master visual into the actual shipping gameplay screen. Historical M28 closure remains historical; this sprint closes the later V02 delta without falsifying earlier evidence.

- [x] SB-M28-C002-001 Build the production Gameplay V02 scene from responsive Godot Controls/Containers plus the approved visual assets; do not ship a flattened screenshot.
- [x] SB-M28-C002-002 Bind the real BoardRenderer as the dominant board region with exact aspect preservation for rectangular boards.
- [x] SB-M28-C002-003 Render the full four-sided Railroad V1 using the canonical geometry contract and approved production skin.
- [x] SB-M28-C002-004 Keep all five slot-to-bottom-rail connectors permanently visible and aligned to exact slot spawn anchors.
- [x] SB-M28-C002-005 Render exactly five normal execution slots and support the temporary authoritative sixth slot when +1 Slot is active.
- [x] SB-M28-C002-006 Render the current owner-selected Batch Supply presentation with five columns x three visible rows when configured for five columns; preserve support for 3/4/5 columns and hidden deeper queue truth.
- [x] SB-M28-C002-007 Keep only supply-front batches interactive; preview rows remain non-interactive and visually distinct.
- [x] SB-M28-C002-008 Bind Pause and 2x side by side at top-right with inactive/current-level/timed-countdown states.
- [x] SB-M28-C002-009 Bind the selected robot/player profile presentation without reintroducing a gameplay Heart HUD or Settings button.
- [x] SB-M28-C002-010 Bind the four canonical booster buttons: +1 Slot / Random / Selector / Tornado.
- [x] SB-M28-C002-011 Booster quantity, price, locked/unavailable and selected states remain live Godot UI overlays and are never baked into art.
- [x] SB-M28-C002-012 Tapping a booster with no charge routes into the canonical Booster Acquire popup defined by M43-C003 rather than silently failing. — AUDITED_PASS M28-C002-C003.
- [x] SB-M28-C002-013 Tapping locked/manual 2x without entitlement routes into the canonical 2x Acquire popup defined by M43-C003. — AUDITED_PASS M28-C002-C003.
- [x] SB-M28-C002-014 Implement the canonical Pause popup entry and deterministic modal stacking rules from M43-C002.
- [x] SB-M28-C002-015 Preserve gameplay input isolation while any popup/modal is open; board, supply and booster controls behind it receive no input.
- [x] SB-M28-C002-016 Preserve the approved gameplay background, Scrubby/selected-robot support presentation and lower decorative hierarchy without shrinking gameplay-critical controls first. — R01 technical PASS + FINAL OWNER VISUAL PASS.
- [x] SB-M28-C002-017 Validate 1080x2160, 1170x2532, 1290x2796, 1080x2400, 1440x3200, short 16:9 portrait and tablet portrait.
- [x] SB-M28-C002-018 Validate mouse/touch mapping, rapid taps, popup-open input suppression and temporary sixth-slot readability.
- [x] SB-M28-C002-019 Capture owner-review screenshots/video for fresh level, active cleaning, full five-slot state, sixth-slot state, booster popup open, Pause open and timed 2x state. — AUDITED_PASS: fresh screenshots + real runtime Movie Maker video.
- [x] SB-M28-C002-020 Independent ChatGPT audit plus owner visual/playtest acceptance required before this V02 convergence is closed. `[AUDITED_PASS + OWNER FINAL REPLAY PASS / CLOSED 2026-09-29]`

#### M28-C002-C004 - Color / Batch Tile Visual Polish [AUDITED_PASS / OWNER FINAL VISUAL RECHECK]

This is intentionally NOT part of the active `M28-C002-C003-R01 V02` remediation. Owner visual authority: `coordination/OWNER_M28_COLOR_BATCH_TILE_VISUAL_V01.md`.

- [x] SB-M28-C002-021 Replace occupied 5/6-slot and Batch Supply/color-selection rectangles with one reusable rounded 3D `ColorBatchTile` presentation: exact Palette v3 Face + same-color lower Base body, subtle top highlight, compact shadow, large centered white count with strong dark outline, visual-only ACTIVE emphasis, no WAITING/ACTIVE text, neutral EMPTY state and lower-emphasis non-interactive preview state. Count is geometrically centered in the COLORED TOP FACE on both axes; lower base and hidden state-line spacer do not shift it; 1/2/3-digit counts remain centered responsively. V02 implementation `3a219105327eb778260cb6dbd83b6dba5f9cec3a`; audit `coordination/sessions/M28-C002-C004/CHATGPT_AUDIT_V02.md`; owner gate `coordination/sessions/M28-C002-C004/OWNER_VISUAL_GATE_V02.md`. `[AUDITED_PASS + OWNER FINAL VISUAL PASS / CLOSED 2026-09-29]`

### M29 — Mobile Touch

- [x] SB-M29-001 Touch selectable supply-front batch activation; five batch slots themselves are not player-selectable placement controls.
- [x] SB-M29-002 Desktop mouse development support.
- [x] SB-M29-003 Prevent mouse/touch double-fire.
- [x] SB-M29-004 Touch cancel.
- [x] SB-M29-005 Focus loss.
- [x] SB-M29-006 Rapid tapping.
- [x] SB-M29-007 Multi-touch.
- [x] SB-M29-008 Pause during touch.
- [x] SB-M29-009 Background/foreground.
- [x] SB-M29-010 Gameplay Tempo Retune: canonical baseline retuned to 9 cells/s + 1/3 s cadence at 1x and 18 cells/s + 1/6 s cadence at 2x. Implementation `8787d38dba65a084e6169ea8e8ccc623ab63e0ae`; functional audit `coordination/sessions/M29-C002/CHATGPT_AUDIT_V01.md`; performance blockers independently cleared by M25-C003 + M25-C004; owner gate `coordination/sessions/M29-C002/OWNER_TEMPO_PLAYTEST_GATE_V01.md`: 1x OK, 2x OK, dense 5/6-slot smoothness OK. `[AUDITED_PASS + OWNER PLAYTEST PASS / CLOSED 2026-09-29]`

**Owner-locked speed integration for M29/runtime:** M29 proves the explicit 1x/2x temporal authority and may keep a direct debug/headless toggle seam. That seam is not authorization for free shipping manual 2x. M39 must gate production manual 2x through the paid entitlement service in `coordination/OWNER_ECONOMY_REWARDS_V01.md`. Authoritative M23-exhausted automatic 2x remains free. Do not infer exhaustion from UI rows or slot occupancy.

### M30 — Win/Lose Rules `[OWNER-LOCKED 2026-09-19] [CLOSED]`

- [x] SB-M30-001 Document win condition.
- [x] SB-M30-002 Document lose condition.
- [x] SB-M30-003 Completion evaluator.
- [x] SB-M30-004 Emit completion once.
- [x] SB-M30-005 Stop inappropriate new dispatch.
- [x] SB-M30-006 Resolve in-flight bots.
- [x] SB-M30-007 Retry.
- [x] SB-M30-008 Completion regression tests.

### M31 — Cleaning Effects `[VISUAL REFERENCE] [PERFORMANCE] [CLOSED 2026-09-20]`

- [x] SB-M31-001 Use original visual references where available.
- [x] SB-M31-002 Define cleaning event.
- [x] SB-M31-003 Prototype lightweight effect.
- [x] SB-M31-004 Separate from BoardState.
- [x] SB-M31-005 Toggle effects.
- [x] SB-M31-006 Concurrency limit.
- [x] SB-M31-007 Pool only after profiling.
- [x] SB-M31-008 Stress 59×59.
- [x] SB-M31-009 Measure frame cost.
- [x] SB-M31-010 Reduced-effects option if required.

Closure evidence: `coordination/sessions/M31-C001/CHATGPT_AUDIT_V01.md` + `coordination/sessions/M31-C001/OWNER_F6_ACCEPTANCE_V01.md`. Final verdict: `AUDITED_PASS / M31-C001 CLOSED`.

### M32 — Scrubbot Final Visuals `[VISUAL REFERENCE] [CLOSED 2026-09-20]`

Closure evidence: `coordination/sessions/M32-C001/CHATGPT_AUDIT_V03.md` + `coordination/sessions/M32-C001/OWNER_F6_ACCEPTANCE_V01.md`. Final verdict: `AUDITED_PASS / M32-C001 CLOSED`.

- [x] SB-M32-001 Audit original Scrubbot art.
- [x] SB-M32-002 Select owner-approved canonical design.
- [x] SB-M32-003 Preserve original source.
- [x] SB-M32-004 Configure crisp import.
- [x] SB-M32-005 Visual component.
- [x] SB-M32-006 Travel animation.
- [x] SB-M32-007 Arrival animation.
- [x] SB-M32-008 Disappearance.
- [x] SB-M32-009 Direction/orientation if approved.
- [x] SB-M32-010 Density performance test.
- [x] SB-M32-UI-001 Use owner-approved canonical Scrubby reference for character generation.
- [x] SB-M32-UI-002 Validate pose/state manifest entries before generation.
- [x] SB-M32-UI-003 Generate only poses required by implemented behavior.
- [x] SB-M32-UI-004 Generate required portrait/profile variants.
- [x] SB-M32-UI-005 Generate emotion/state variants only when implemented flow needs them.
- [x] SB-M32-UI-006 Preserve raw candidates/provenance separately.
- [x] SB-M32-UI-007 Require owner visual approval before promotion.
- [x] SB-M32-UI-008 Lock approved character assets against silent overwrite.
- [x] SB-M32-UI-009 Configure Godot import settings.
- [x] SB-M32-UI-010 Integrate approved art without coupling animation to TargetSelector logic.
- [x] SB-M32-UI-011 Validate readability/scale on phone viewport matrix.
- [x] SB-M32-UI-012 Board-resolution-independent Scrubbot apparent size: presentation-scale compensation derives from actual rendered BoardPresentation geometry using the accepted 32x32 / 2.4-cell reference; live visuals and retire echo follow responsive relayout without gameplay-truth mutation. Implementation `649cf6290752e298b888eac6e080fb65bb2be9ed`; audit `coordination/sessions/M32-C002/CHATGPT_AUDIT_V01.md`; owner gate `coordination/sessions/M32-C002/OWNER_VISUAL_GATE_V01.md`: V1/V2/V3/V4 all OK. `[AUDITED_PASS + OWNER VISUAL PASS / CLOSED 2026-09-30]`

### M33 — Audio `[OWNER-LOCKED AUDIO SELECTION V02 2026-09-24]`

**FINAL STATUS: `AUDITED_PASS / OWNER_F6_PASS / M33 AUDIO CLOSED`.**

Owner accepted the integrated Pixel Polish Parade gameplay loop in `res://scenes/debug/m33_audio_playtest.tscn`: no audible loop seam, comfortable music-vs-cleaning balance, cleaning remains readable, Music/SFX/Master isolation is correct, Retry/2x/cleaning do not restart music, and repeated listening is not fatiguing.

Final owner acceptance:
`coordination/OWNER_M33_FINAL_AUDIO_ACCEPTANCE_V01.md`

Owner audio law remains: no dispatch SFX; cleaning uses bounded `dispatch.wav`; completion is WON-only; no movement audio. `ScrubBots Workshop` remains separately owner-approved for a future Workshop screen.

- [x] SB-M33-001 Audio buses.
- [x] SB-M33-002 Master volume.
- [x] SB-M33-003 Music volume.
- [x] SB-M33-004 SFX volume.
- [x] SB-M33-005 Dispatch SFX decision resolved: **NONE in production V1**. `assets/audio/sfx/dispatch.wav` is preserved and repurposed as the cleaning sonic source.
- [x] SB-M33-006 Cleaning SFX. Owner-approved V02 source: `assets/audio/sfx/dispatch.wav`; legacy `cleaning.wav` is preserved but not used by production cleaning playback.
- [x] SB-M33-007 Completion SFX. Owner-approved canonical asset: `assets/audio/sfx/completion.wav`.
- [x] SB-M33-008 Movement audio only if pleasant at high density. Owner decision: no movement audio in V1.
- [x] SB-M33-009 Concurrency management.
- [x] SB-M33-010 Persist settings.

### M34 — Haptics

V02 independent code audit: `CODE_AUDIT_PASS`. SB-M34-001..005 closed. SB-M34-006 remains `DEVICE/OWNER_REQUIRED` for real handset haptic feel.

Pre-authored batch bundle: `coordination/sessions/M34-C001/CHATGPT_PROMPT_V01.md` + `CHATGPT_AUDIT_CRITERIA_V01.md`. Per-task logs required under `task_logs/`. Owner/device gate does not stop the batch.

- [x] SB-M34-001 Platform API research.
- [x] SB-M34-002 Cleaning haptic if approved.
- [x] SB-M34-003 Completion haptic.
- [x] SB-M34-004 Toggle.
- [x] SB-M34-005 Prevent vibration spam.
- [ ] SB-M34-006 Real-device test.

### M35 — Level Catalog

V02 independent audit: `AUDITED_PASS / M35 LEVEL CATALOG CLOSED`. All M35 tasks closed.

Pre-authored batch bundle: `coordination/sessions/M35-C001/CHATGPT_PROMPT_V01.md` + `CHATGPT_AUDIT_CRITERIA_V01.md`. Per-task logs required under `task_logs/`.

- [x] SB-M35-001 Production LevelCatalog.
- [x] SB-M35-002 Stable IDs.
- [x] SB-M35-003 Stable ordering.
- [x] SB-M35-004 Difficulty.
- [x] SB-M35-005 Dimensions.
- [x] SB-M35-006 Preview.
- [x] SB-M35-007 Duplicate detection.
- [x] SB-M35-008 Missing-file detection.
- [x] SB-M35-009 Production/test separation.
- [x] SB-M35-010 Reject TEST fixture in production catalog.
- [x] SB-M35-011 Batch validation.

### M36 — Difficulty System

V02 independent code audit: `CODE_AUDIT_PASS`. SB-M36-001..004/006 closed. SB-M36-005 remains `OWNER_REQUIRED` until representative production levels exist for human difficulty calibration.

Pre-authored batch bundle: `coordination/sessions/M36-C001/CHATGPT_PROMPT_V01.md` + `CHATGPT_AUDIT_CRITERIA_V01.md`. Per-task logs required under `task_logs/`. Human playtest gate does not stop the batch.

**Difficulty V1 owner decision now governs future work.** Board dimensions remain an engine/content envelope and Session Load input, not the definition of EASY/MEDIUM/HARD/VERY_HARD.

- [x] SB-M36-001 Migrate legacy runtime class=dimension configuration to Difficulty V1 without breaking board envelope validation.
- [x] SB-M36-002 Validate production catalog against current Difficulty V1 + compatibility requirements.
- [x] SB-M36-003 Implement/version Challenge components and owner-approved additional factors.
- [x] SB-M36-004 Create Difficulty V1 matrix/calibration fixtures.
- [ ] SB-M36-005 Playtest difficulty.
- [x] SB-M36-006 Prove board size alone cannot determine difficulty class.

### M37 — Level Progression

V03 independent audit: `AUDITED_PASS / M37 LEVEL PROGRESSION CLOSED`. Forward-only progression and contiguous persisted history accepted; owner decision remains no shipping Level Select, debug seam only.

V03 remediation authority: `coordination/sessions/M37-C001/CHATGPT_PROMPT_V03.md` + `CHATGPT_AUDIT_CRITERIA_V03.md`. Frozen F-M37-V02-001..002. Owner lock remains: forward-only progression, no shipping Level Select; debug seam only.

V02 remediation authority: `coordination/sessions/M37-C001/CHATGPT_PROMPT_V02.md` + `CHATGPT_AUDIT_CRITERIA_V02.md`. Owner decision is locked in `coordination/OWNER_M37_LEVEL_SELECT_DECISION_V01.md`: no shipping Level Select in V1; forward-only progression, debug/test seam only. Per-task V02 logs required under `task_logs_v02/`.

- [x] SB-M37-001 Implement owner-locked repeating 10-level class cadence.
- [x] SB-M37-002 Current level.
- [x] SB-M37-003 Completion tracking.
- [x] SB-M37-004 Replay.
- [x] SB-M37-005 Implement progression target curve/micro modifiers from Difficulty V1.
- [x] SB-M37-006 Level select if approved.
- [x] SB-M37-007 Service implementation.
- [x] SB-M37-008 Tests.

### M38 — Win Streak `[OWNER-LOCKED ECONOMY V1]`

V03 independent final audit: `AUDITED_PASS / M38 WIN STREAK CLOSED / STRICT EVIDENCE REPAIRED`. SB-M38-016 is reclosed. The reward-failure strict case now runs through a true RewardGrantService subclass, and the suite fails if any named sub-test aborts.

Prior V02 final closure is temporarily suspended by `coordination/sessions/M38-C001/CHATGPT_FULL_SURFACE_REAUDIT_V02.md`: the reward-failure strict sub-test aborted on a typed fake yet the suite printed PASS. Only SB-M38-016 is reopened. V03 prompt/criteria repair evidence only; production changes are forbidden unless the repaired test exposes a real defect.

V02 strict independent audit: `AUDITED_PASS / M38 WIN STREAK CLOSED`. All M38 tasks closed.

Pre-authored batch bundle: `coordination/sessions/M38-C001/CHATGPT_PROMPT_V01.md` + `CHATGPT_AUDIT_CRITERIA_V01.md`. Per-task logs required under `task_logs/`. Durable central persistence is finalized by M40.

- [x] SB-M38-001 Streak state.
- [x] SB-M38-002 Increment only on valid first-clear progression wins.
- [x] SB-M38-003 Reset on progression loss and restart-after-gameplay; pre-action exit does not reset.
- [x] SB-M38-004 Grant exact SB mapping through RewardGrantService.
- [x] SB-M38-005 Test 1→1 SB.
- [x] SB-M38-006 Test 2→5 SB.
- [x] SB-M38-007 Test 3→10 SB.
- [x] SB-M38-008 Test 4→25 SB.
- [x] SB-M38-009 Test 5→100 SB.
- [x] SB-M38-010 Test 6+→100 SB.
- [x] SB-M38-011 No duplicate grant.
- [x] SB-M38-012 Persistence.
- [x] SB-M38-013 Emit only streak-bonus SB amount to GiftMeterService; base/Daily/exchange SB never feeds it.
- [x] SB-M38-014 Grant +1 Bot Part exactly at active streak multiples of 5.
- [x] SB-M38-015 Replay does not advance streak, Gift Meter or streak Bot Parts.
- [x] SB-M38-016 Add reset/replay/idempotency integration tests.

### M39 — Economy & Rewards V1 `[OWNER-LOCKED]`

V04 final independent audit: `AUDITED_PASS / M39 ECONOMY CODE CLOSED / SB-M39-033 DEVICE_OWNER_REQUIRED`. The repaired M38 strict regression closes SB-M39-052. All M39 code tasks are audited; only real-phone sixth-slot safe-area/touch/readability evidence remains.

V04 independent audit: `CODE_AUDIT_PASS / REGRESSION_GATE_OPEN / DEVICE_OWNER_GATE_OPEN`. F-M39-V03-001..005 are source/direct-test accepted. SB-M39-052 waits for repaired M38 strict regression; SB-M39-033 remains real-device safe-area/touch/readability.

V04 remediation authority: `coordination/sessions/M39-C001/CHATGPT_PROMPT_V04.md` + `CHATGPT_AUDIT_CRITERIA_V04.md`. Frozen F-M39-V03-001..005. Remaining code work is targeted Tornado cancellation, production local-day wiring, exact +1 rollback, atomic first-clear transaction and canonical action seams. SB-M39-033 also retains the later device safe-area/touch gate.

V03 remediation authority: `coordination/sessions/M39-C001/CHATGPT_PROMPT_V03.md` + `CHATGPT_AUDIT_CRITERIA_V03.md`. Frozen F-M39-V02-001..016. Proven unrelated M39 tasks are closed individually; SB-M39-033 also retains a later real-device safe-area/touch gate after code remediation.

Pre-authored batch bundle: `coordination/sessions/M39-C001/CHATGPT_PROMPT_V01.md` + `CHATGPT_AUDIT_CRITERIA_V01.md`. All 55 task IDs require separate GitHub task logs; M39 remains subject to later strict full-surface ChatGPT audit.

Canonical decision: `coordination/OWNER_ECONOMY_REWARDS_V01.md`.
Machine tuning: `data/config/economy_rewards_v1.json`.

- [x] SB-M39-001 Load/version/validate Economy V1 tuning config and fail closed on malformed values.
- [x] SB-M39-002 Implement `scripts/economy/economy_wallet.gd` as authoritative Scrub Bucks balance.
- [x] SB-M39-003 Implement atomic SB grant/spend with stable transaction IDs and insufficient-funds failure.
- [x] SB-M39-004 Initialize new players at 1000 SB without double-initialization.
- [x] SB-M39-005 Grant first-clear SB by difficulty: EASY 50 / MEDIUM 75 / HARD 100 / VERY_HARD 150.
- [x] SB-M39-006 Grant +1 Bot Part per first-clear progression level and prohibit replay farming.
- [x] SB-M39-007 Implement `reward_grant_service.gd` idempotent reward bundles and duplicate-callback protection.
- [x] SB-M39-008 Implement `gift_meter_service.gd`; ONLY Win Streak SB may advance it.
- [x] SB-M39-009 Implement Gift Meter thresholds 10/50/250/500/1000 and exactly-once milestone crossing.
- [x] SB-M39-010 Support one reward crossing multiple thresholds plus 1000-cycle rollover/overflow.
- [x] SB-M39-011 Queue Gift Bar milestone rewards instead of silently auto-consuming them.
- [x] SB-M39-012 Implement exact Gift rewards from Economy V1, totaling 10 Bot Parts per complete 0→1000 cycle.
- [x] SB-M39-013 Implement 1000 guaranteed-new-card rule with 500 SB fallback when no eligible missing card exists.
- [x] SB-M39-014 Prove base level/Daily/Tasks/Gift/Cards Exchange SB cannot recursively advance Gift Meter.
- [x] SB-M39-015 Implement `robot_unlock_service.gd`: Scrubby initially unlocked; every later robot costs 250 Bot Parts; preserve overflow.
- [x] SB-M39-016 Grant owner-locked per-set SB/Bot Parts rewards on first 9/9 completion and wire next-robot notification/read model.
- [x] SB-M39-017 Add pacing simulation/evidence targeting approximately one robot unlock per 150 progression levels for average engaged play.
- [x] SB-M39-018 Enforce robot perks as meta/economy convenience only; never alter solver/BoardState/TargetSelector/routing legality.
- [x] SB-M39-019 Implement `heart_service.gd`: max 5, one Heart per **900 real-world seconds / 15 minutes**, offline/menu/background regen. [Interval superseded by OWNER_HEART_REGEN_INTERVAL_V01]
- [x] SB-M39-020 Consume one Heart on progression loss or restart-after-gameplay; pre-action exit consumes none.
- [x] SB-M39-021 Implement +1 Heart = 500 SB and full refill = 400 SB per missing Heart.
- [x] SB-M39-022 Implement `speed_entitlement_service.gd` separate from GameplaySpeedAuthority.
- [x] SB-M39-023 Implement current-level 2x entitlement = 200 SB, surviving retries of same level until completion.
- [x] SB-M39-024 Implement timed 2x products 15m/300 SB, 30m/500 SB, 60m/750 SB.
- [x] SB-M39-025 Timed 2x uses absolute wall-clock expiry and continues in gameplay, Home/menus, pause, background and closed-app time.
- [x] SB-M39-026 Allow timed purchases to extend expiry deterministically; never use gameplay delta/Engine.time_scale for entitlement time.
- [x] SB-M39-027 Gate shipping manual 2x requests behind a valid level/timed entitlement or purchase flow.
- [x] SB-M39-028 Preserve free entitlement-independent authoritative M23-exhausted automatic 2x.
- [x] SB-M39-029 Implement `booster_inventory.gd` with exactly four charge counters and charge-before-SB consumption.
- [x] SB-M39-030 +1 Slot booster: 500 SB, max once/attempt, authoritative slot capacity 5→6 only for current attempt.
- [x] SB-M39-031 Extend M24 placement/full-slot queries from fixed five to authoritative capacity 5/6 without breaking five-slot baseline tests.
- [x] SB-M39-032 Extend M27 solver/deadlock state/canonicalization/fixtures to capacity 5/6.
- [ ] SB-M39-033 Add sixth-slot presentation/layout support and mobile safe-area evidence; no 7+ slot state.
- [x] SB-M39-034 Random booster: 350 SB, reorder only remaining unselected M23 batches without changing identities/counts/conservation.
- [x] SB-M39-035 Random commit requires solver proof of at least three consecutive legal non-deadlocking front selections; failed search consumes nothing.
- [x] SB-M39-036 Selector booster: 500 SB; present solver-safe eligible remaining batches/colors only.
- [x] SB-M39-037 Selector performs one atomic arbitrary-remaining extraction + standard rightmost-EMPTY placement; full capacity/unsafe choice consumes nothing.
- [x] SB-M39-038 Tornado booster: 750 SB; choose exactly one present color.
- [x] SB-M39-039 Tornado atomically clears all remaining ACTIVE cells of chosen color and reconciles M23 supply, M24 slots, M25 claims/reservations, M26 in-flight agents/quotas and M27 state.
- [x] SB-M39-040 Prove Tornado rollback/failure consumes no charge/SB and leaves no ghost batch/agent/double-clear.
- [x] SB-M39-041 Implement `daily_service.gd`: visible consecutive-login count plus repeating 5-day reward cycle.
- [x] SB-M39-042 Daily login rewards: D1 100 SB; D2 Standard Pack; D3 random booster; D4 250 SB + Standard Pack; D5 300 SB + selected booster + Premium Pack.
- [x] SB-M39-043 Daily has exactly three tasks with 75/100/125 SB individual rewards and one random booster for completing all three.
- [x] SB-M39-044 Missing a local calendar day resets login streak/cycle; clock rollback can never create duplicate claims.
- [x] SB-M39-045 Implement `collection_inventory.gd` for 15 sets × 9 cards, protected first copy and completion state.
- [x] SB-M39-046 Standard Pack = 3 eligible draws; Premium Pack = 5 eligible draws with >=1 Rare-or-better; duplicates allowed.
- [x] SB-M39-047 Implement exact per-set 9/9 rewards from Economy V1: S1 350/5, S2 400/5, S3 450/6, S4 500/7, S5 550/7, S6 600/8, S7 700/9, S8 750/9, S9 800/10, S10 900/10, S11 1000/11, S12 1100/12, S13 1250/13, S14 1500/15, S15 2500/20 (SB/Bot Parts), each exactly once.
- [x] SB-M39-047A Grant Master Collection exactly once when all 15 sets first reach 9/9: +2500 SB +20 Bot Parts, additional to Set 15.
- [x] SB-M39-047B Prove total 15-set completion milestones = 13,350 SB +147 Bot Parts; including Master Collection = 15,850 SB +167 Bot Parts.
- [x] SB-M39-047C Persist per-set completion-grant transaction IDs and Master Collection transaction ID so sync/relaunch cannot double-grant.
- [x] SB-M39-048 Implement `cards_exchange_service.gd`; only copies above protected first copy are exchangeable.
- [x] SB-M39-049 Exchange values: Common 25 / Rare 75 / Epic 200 / Legendary 500 SB.
- [x] SB-M39-050 Implement per-card and EXCHANGE ALL EXTRAS atomic exchange; never reduce collected owned count below 1.
- [x] SB-M39-051 Prove Stars, Star Exchange, Event Points and profile-XP economic state do not exist in production save/runtime APIs.
- [x] SB-M39-052 Add full Economy V1 headless regression matrix for grants/spends/rollover/offline clocks/boosters/exchange/idempotency.
- [x] SB-M39-053 Test stability follow-up: real-wall-clock boundary flake removed from `tests/m39_v04_integration.gd` `_phase_c_plus_one()` by injecting deterministic fixed clock/local-day through the existing AppState/economy test seam. Exact whole-economy `econ.snapshot() == pre_econ` assertion remains intact; production code unchanged; 10/10 isolated runs PASS plus root/M39/M40/M43/M55 clock/economy regressions PASS. Implementation `1cd735a623785a8115315d4b26dca14e97076726`; audit `coordination/sessions/M39-C002/CHATGPT_AUDIT_V01.md`. `[AUDITED_PASS / CLOSED 2026-09-30]`

### M40 — Save System

V04 final independent audit: `AUDITED_PASS / M40 SAVE SYSTEM CLOSED`. The repaired M38 strict regression and rerun of M40 V04 bootstrap/root suite close the final external gate.

V04 independent audit: `CODE_AUDIT_PASS / M38 STRICT REGRESSION REQUIRED`. All M40 task rows are code/evidence-proven; final milestone `AUDITED_PASS` waits for M38 V03 repaired strict regression plus rerun of M40 V04 bootstrap/root suite.

V04 remediation authority: `coordination/sessions/M40-C001/CHATGPT_PROMPT_V04.md` + `CHATGPT_AUDIT_CRITERIA_V04.md`. Frozen F-M40-V03-001..004. Remaining work is actual app bootstrap, frontier-to-catalog content resolution, app-owned durable action/save boundaries and local-day end-to-end persistence.

V03 remediation authority: `coordination/sessions/M40-C001/CHATGPT_PROMPT_V03.md` + `CHATGPT_AUDIT_CRITERIA_V03.md`. Frozen F-M40-V02-001..009. SB-M40-004/006/007 are independently accepted; remaining rows await V03/dependency closure.

Pre-authored batch bundle: `coordination/sessions/M40-C001/CHATGPT_PROMPT_V01.md` + `CHATGPT_AUDIT_CRITERIA_V01.md`. All 13 task IDs require separate GitHub task logs; M40 is the batch endpoint and remains subject to later strict full-surface ChatGPT audit.

- [x] SB-M40-001 Versioned schema.
- [x] SB-M40-002 Settings.
- [x] SB-M40-003 Progression.
- [x] SB-M40-004 Win streak.
- [x] SB-M40-005 Persist Economy V1 wallet, Hearts/regen anchor, Bot Parts/robots, cards, booster charges, Gift Meter, Daily and 2x entitlements.
- [x] SB-M40-006 Safe write strategy.
- [x] SB-M40-007 Missing-save behavior.
- [x] SB-M40-008 Corruption recovery.
- [x] SB-M40-009 Migration strategy.
- [x] SB-M40-010 Round-trip tests.
- [x] SB-M40-011 Corrupt-file tests.
- [x] SB-M40-012 Migrate old saves with missing Economy V1 fields to safe defaults; never invent Star/Event balances.
- [x] SB-M40-013 Persist wall-clock timestamps/expiry defensively against duplicate reward/refill claims.

### M41 — Settings `[CLOSED 2026-09-25]`

Final status: **`AUDITED_PASS / OWNER_F6_PASS / M41 SETTINGS CLOSED`**.

M41-C001 closed Master/Music/SFX/Haptics/Persistence/UI/Relaunch with independent code audit plus owner 9/9 manual acceptance.

M41-C002 closed the final row, `SB-M41-005 Reduced Effects`, with independent code audit plus owner 5/5 manual acceptance. The setting is canonical/persistent, strict-validated, live-bound to the accepted M31 reduced cleaning presentation, gameplay-invariant and owner-accepted.

Evidence:
- `coordination/sessions/M41-C001/CHATGPT_AUDIT_V01.md`
- `coordination/OWNER_M41_SETTINGS_ACCEPTANCE_V01.md`
- `coordination/sessions/M41-C002/CHATGPT_AUDIT_V01.md`
- `coordination/OWNER_M41_C002_REDUCED_EFFECTS_ACCEPTANCE_V01.md`

- [x] SB-M41-001 Master volume.
- [x] SB-M41-002 Music.
- [x] SB-M41-003 SFX.
- [x] SB-M41-004 Haptics.
- [x] SB-M41-005 Reduced effects.
- [x] SB-M41-006 Persistence.
- [x] SB-M41-007 Settings UI.
- [x] SB-M41-008 Relaunch tests.

### M42 — Home / Navigation

M42-C001 V01 independent batch audit:
`coordination/sessions/M42-C001/CHATGPT_BATCH_AUDIT_V01.md`

Batch result: **25 AUDITED_PASS / 8 CODE_AUDIT_PASS WITH EXTERNAL GATES / 0 CHANGES_REQUIRED**.

Individual audit files:
`coordination/sessions/M42-C001/audits/SB-M42-001_CHATGPT_AUDIT_V01.md` .. `SB-M42-033_CHATGPT_AUDIT_V01.md`.

Post-audit owner decision closed SB-M42-030 as mandatory NO SKIP. The Home then went through owner-approved asset promotion, V02 master convergence and V03 visual/modal remediation. After V03 runtime review, the owner changed the Home architecture again: World 01 will use one complete baked 1080x2160 world background while Scrubby remains a separate runtime hero, and Home shortcuts are reduced to four. Current closure state is **31 closed / 2 open rows**. Final Home V07 visuals are owner-accepted; only 032/033 external device gates remain.

Opening policy: `coordination/OWNER_M42_OPENING_CINEMATIC_POLICY_DECISION_V02.md`
SB-M42-030 audit closure: `coordination/sessions/M42-C001/audits/SB-M42-030_CHATGPT_AUDIT_V02.md`.
Home art complete approval: `coordination/OWNER_M42_HOME_ART_COMPLETE_APPROVAL_V01.md`
Home art promotion audit: `coordination/sessions/M42-C001/audits/SB-M42-HOME-ART-PROMOTION_CHATGPT_AUDIT_V01.md`.
Home master convergence V02 audit: `coordination/sessions/M42-C001/audits/SB-M42-HOME-MASTER-CONVERGENCE_V02_CHATGPT_AUDIT_V01.md`.
Home owner visual revision V03: `coordination/OWNER_M42_HOME_VISUAL_REVISION_V03.md`
V03 implementation prompt: `coordination/sessions/M42-C001/task_prompts/SB-M42-HOME-OWNER-REVISION_V03.md`.
V03 independent audit: `coordination/sessions/M42-C001/audits/SB-M42-HOME-OWNER-REVISION_V03_CHATGPT_AUDIT_V01.md`.
Home rebuild V04 owner decision: `coordination/OWNER_M42_HOME_REBUILD_V04_SINGLE_WORLD_BACKGROUND.md`
V04 implementation prompt: `coordination/sessions/M42-C001/task_prompts/SB-M42-HOME-REBUILD_V04.md`.

- [x] SB-M42-001 Navigation architecture.
- [x] SB-M42-002 Home.
- [x] SB-M42-003 Play/Continue.
- [x] SB-M42-004 Settings.
- [x] SB-M42-005 Level select if approved. `[OWNER-LOCKED: NO SHIPPING LEVEL SELECT]`
- [x] SB-M42-006 Gameplay transition.
- [x] SB-M42-007 Results transition.
- [x] SB-M42-008 Prevent duplicate transitions.
- [x] SB-M42-009 Back navigation.
- [x] SB-M42-010 Build Home as responsive Godot containers/components.
- [x] SB-M42-011 Recreate owner-approved Home art direction with canonical regions. `[AUDITED_PASS / V07 / OWNER_VISUAL_PASS]`
- [x] SB-M42-012 Keep shortcut columns responsive around central area.
- [x] SB-M42-013 Validate Home-specific manifest entries in `assets/ui/HOME_ASSET_MANIFEST.json` before generation.
- [x] SB-M42-014 Generate only Home-specific required illustrative assets using approved provider order (ChatGPT primary, Magnific fallback). `[AUDITED_PASS / V02]`
- [x] SB-M42-015 Keep dynamic values/timers/counts/labels live in Godot UI.
- [x] SB-M42-016 Require owner approval before production promotion. `[AUDITED_PASS / V02]`
- [x] SB-M42-017 Bind approved art and validate viewport matrix. `[AUDITED_PASS / V07 / OWNER_VISUAL_PASS]`
- [x] SB-M42-018 Replace coin HUD semantics with Scrub Bucks banknote icon + live SB amount. `[AUDITED_PASS / V02]`
- [x] SB-M42-019 Replace profile XP bar with live Bot Parts next-robot progress (normally N/250).
- [x] SB-M42-020 Replace top event bar/timer with Gift Meter progress/next milestone; no Event Points/timer.
- [x] SB-M42-021 Bind Gift Bar to queued Gift Meter milestone claims and live claimable count.
- [x] SB-M42-022 Replace Star Exchange shortcut with Cards Exchange and duplicate-card count/state.
- [x] SB-M42-023 Render lower road as Win Streak SB reward track 1/5/10/25/100; no Star balance.
- [x] SB-M42-024 Implement Daily consecutive-login count / 5-day cycle / booster reward presentation.
- [x] SB-M42-025 Keep all SB prices, Bot Parts values, Gift Meter values and Daily states live/localizable.

**Owner runtime validation [2026-09-27 / OWNER_RUNTIME_PASS / VISUAL_POLISH_OPEN]:**
`coordination/OWNER_ECONOMY_PROGRESSION_RUNTIME_VALIDATION_V01.md`.
During the First 10 owner replay, 2x purchase + correct SB debit, live Scrub Bucks balance, Gift Meter, Bot Parts/next-robot progress and Home progression bars were manually confirmed to update correctly. Treat these mechanics/data bindings as working runtime truth; later tasks remain responsible for improving their visual quality and reward/presentation polish without rewriting the validated backend unnecessarily.

**Opening cinematic / boot flow [OWNER ASSET — 2026-09-19]**

- [x] SB-M42-026 Opening cinematic source: preserve the owner-supplied 15-second source video at `assets/brand/opening/final_15_seconds_opening_video.mp4`.
- [x] SB-M42-027 Preserve the MP4 as source/reference, but create a Godot-runtime Ogg Theora + Vorbis version at `assets/brand/opening/scrubbots_opening_720p30.ogv`; do not rely on H.264/MP4 playback in core Godot.
- [x] SB-M42-028 Implement a dedicated opening-video scene using `VideoStreamPlayer`, with aspect-ratio-safe presentation for the portrait app and no image distortion.
- [x] SB-M42-029 On successful video completion, transition exactly once into the normal Home/bootstrap flow; failure to decode/play must fail safely into Home rather than blocking startup.
- [x] SB-M42-030 Opening cinematic skip behavior. `[OWNER-LOCKED: NO SKIP / AUDITED_PASS]`
- [x] SB-M42-031 Playback frequency `[OWNER-LOCKED]`: cinematic plays on every cold/native app launch; no replay for internal navigation/retry/background resume.
- [ ] SB-M42-032 Validate opening cinematic on Android real device for smooth 720p/30 playback, audio sync, startup latency, orientation, background/foreground behavior and memory cleanup. `[CODE_AUDIT_PASS / DEVICE_OWNER_REQUIRED]`
- [ ] SB-M42-033 Validate iOS readiness later with the same boot-flow fallback and aspect rules. `[CODE_AUDIT_PASS / IOS_DEVICE_LATER]`
- [x] SB-M42-034 Home Scrubby Hero Scale + Placement Lock: Home hero is exactly +30% from production 1.24 to canonical `SCRUBBY_SCALE = 1.612`, preserving the separate runtime hero layer, visible-sole/platform anchor, Home input/UI hierarchy and responsive safe-area behavior. Implementation `72a78620de42da6aa1b9f2ba00b6d15da9acfc7b`; audit `coordination/sessions/M42-C002/CHATGPT_AUDIT_V01.md`; owner gate `coordination/sessions/M42-C002/OWNER_VISUAL_GATE_V01.md`: V1/V2/V3/V4 all OK. The owner-noticed 1536x2048 mirrored edge continuation is pre-existing and explicitly accepted. `[AUDITED_PASS + OWNER VISUAL PASS / CLOSED 2026-10-01]`
- [x] SB-M42-035 Home Scrubby Runtime Animation: V03 implementation accepted against the owner-approved 1.612 Home hero. Wave 14 / Bow 15 / bilateral Turn-Look 17 / Full Turn 17 are promoted and SHA-pinned on one deterministic common animation canvas/pivot; HomeScrubbyHero runtime, 6–12 s scheduler, 35/30/25/10 weights, no-repeat/no-stack, Reduced Effects, lifecycle/modal/focus gating, screen-space collision validation and responsive evidence are implemented. Focused V03 test 18/18 and root suite 5323/5323 pass; two unrelated M21 top-level failures reproduce identically on untouched baseline. Technical audit: `coordination/sessions/M42-C003/CHATGPT_AUDIT_V03.md`; owner visual gate: `coordination/sessions/M42-C003/OWNER_VISUAL_GATE_V03.md` = Wave/Bow/Turn-Look/Full Turn 4/4 PASS. `[AUDITED PASS + OWNER VISUAL PASS / CLOSED 2026-10-02]`

### M43 - Results / Player Experience / Meta UI Surface Program [PLANNED / REQUIRED]

**Owner completeness rule:** every player-facing button, HUD `+`, Home shortcut, bottom-navigation destination, gameplay purchase/acquisition action, fail/win state, reward event and feature unlock must terminate in a real implemented screen/popup or an explicitly disabled state. No shipping dead buttons, placeholder pages, invisible economic transactions or "coming later" holes are allowed for V1-required surfaces.

**Canonical visual references already selected:**
- Life popup: `assets/art/references/_owner_inbox/Additionals/life screens.png`
- Need a Hand popup: `assets/art/references/_owner_inbox/Additionals/need a hand.png`
- Level intro popup: `assets/art/references/_owner_inbox/Game Screens/level ekran acilisi.png`
- Gameplay master: `assets/ui/final/gameplay/master/scrubbots_gameplay_master.png`
- Home master/World 01 authority remains M42 V07 + owner decisions.

**Visual production rule for every surface below:** create/identify a visual master or canonical reference, inventory required illustration assets, generate only the needed component art, obtain owner visual approval, build the production screen in responsive Godot UI with live text/data, run independent audit, then run owner playtest/visual acceptance. A screen is not complete merely because a service exists.

#### M43-C001 - Results Screen

**C001B status: FINAL OWNER PASS.** Technical audit PASS at `4d198e9`; owner visual acceptance recorded in `coordination/sessions/M43-C001B/FINAL_OWNER_VISUAL_ACCEPTANCE_V01.md`. `victory_results` is `MASTER_OWNER_APPROVED`. Only SB-M43-013 remains open because downstream ceremonies belong to M43-C005.

- [x] SB-M43-001 Result model.
- [x] SB-M43-002 Completion UI.
- [x] SB-M43-003 Streak presentation.
- [x] SB-M43-004 Show/apply first-clear difficulty SB + streak SB + Bot Part/Collection rewards through RewardGrantService.
- [x] SB-M43-005 Continue.
- [x] SB-M43-006 Replay if approved; replay never farms progression economy. **[OWNER: NO SHIPPING REPLAY IN V1 RESULTS]**
- [x] SB-M43-007 No double reward.
- [x] SB-M43-008 Rapid-tap protection.
- [x] SB-M43-009 Produce and owner-approve a canonical Victory/Results visual master consistent with the Life/Help popup family.
- [x] SB-M43-010 Reveal first-clear SB, Win Streak bonus, Bot Parts, Gift Meter progress and Collection/Card rewards in a short ordered celebration sequence rather than dumping all rewards silently.
- [x] SB-M43-011 Support a compact replay result path that clearly communicates zero progression reward on replay. **[RESOLVED BY OWNER: NO SHIPPING REPLAY, so no replay result path is built.]**
- [x] SB-M43-012 If a win crosses a Gift Meter milestone, queue/show the milestone celebration without double granting.
- [ ] SB-M43-013 If the win unlocks a robot, collection set, Master Collection, feature or world, hand off to the corresponding ceremony in M43-C005 after the core Results reward commit succeeds.
- [x] SB-M43-014 Results Continue advances exactly once to the next canonical progression level and cannot be double-tapped into duplicate transitions.


#### M43-C001R - Results Momentum / Next-Level Curiosity / 10-Level Cleaning Journey [OWNER APPROVED 2026-09-30]

These tasks extend the already owner-approved Results surface without changing its reward authority. The goal is a strong "one more level" continuation loop built from truthful next-content information, not fake scarcity, near-miss messaging or hidden reward manipulation.

- [x] SB-M43-R01-001 Add a deterministic **Next Cleanup** teaser after authoritative Results rewards/required ceremonies: resolve the actual next canonical progression level first, then reveal only a controlled preview of its real artwork/metadata.
- [x] SB-M43-R01-002 Default teaser language is silhouette / cropped-detail / limited-palette reveal, targeting roughly 15–25% visual information; never fabricate an unreleased level, fake a reward, or expose the full puzzle artwork before play.
- [x] SB-M43-R01-003 Teaser displays truthful next-level context only: level number, approved class/difficulty label and optional palette/color-count summary when available; unavailable frontier content shows an honest disabled/coming-soon state.
- [x] SB-M43-R01-004 Recompose the post-win flow as one momentum corridor: reward commit → compact secondary progress summary → any mandatory ceremony handoff → Next Cleanup teaser → one dominant **CLEAN NEXT** action; Home/back remains secondary and never traps the player.
- [x] SB-M43-R01-005 Implement a visible **10-Level Cleaning Journey** using the existing canonical cadence only: ten nodes per cycle, slot 5 presented as the mini-boss beat and slot 10 as the cycle-boss beat; this is meta progress UI, **not a World Diorama and not a level-select surface**.
- [x] SB-M43-R01-006 Journey state derives from ProgressionService/canonical cadence and survives cycle boundaries correctly (1→10 then next cycle 1); it never unlocks, skips or rewinds levels and never changes difficulty truth.
- [x] SB-M43-R01-007 Results and Home may show the same journey read model, but there is one authority for cycle position and completion; nodes are informational and non-tappable unless a later owner decision explicitly changes the no-shipping-Level-Select rule.
- [x] SB-M43-R01-008 Add focused tests for next-level resolution, frontier/missing-content fallback, double-tap protection, ceremony chaining, cycle 9→10→next-1 transitions, Reduced Effects and save/relaunch continuity.

#### M43-C002 - Reusable Popup / Modal / Pause Foundation

- [x] SB-M43-015 Implement reusable `BasePopup` with dim background, responsive frame, header/content/footer slots and canonical close behavior.
- [x] SB-M43-016 Implement modal stack authority so exactly one top modal owns input; background Home/gameplay controls are hidden or input-disabled as appropriate.
- [x] SB-M43-017 Implement reusable confirm popup for destructive/costly actions.
- [x] SB-M43-018 Implement reusable reward/confirmation popup.
- [x] SB-M43-019 Implement canonical Pause popup with Resume / Restart / Home and current level context.
- [x] SB-M43-020 Restart confirmation must state Heart/streak consequence when gameplay has begun and must use M30/M39 truth rather than UI guesses.
- [x] SB-M43-021 Home/exit confirmation must distinguish pre-first-action no-cost exit from post-action loss semantics.
- [x] SB-M43-022 Implement generic insufficient-SB route that can open Shop without losing the pending acquisition context.
- [x] SB-M43-023 Implement generic network-required/error state for rewarded ad, store, cloud and live-event surfaces.
- [x] SB-M43-024 Implement loading/busy state and disable duplicate taps while an external transaction is unresolved.
- [x] SB-M43-025 Implement canonical success/failure feedback for purchases, rewarded grants, exchanges and claims.
- [x] SB-M43-026 Back/Escape closes the top modal first and never leaks an action into the screen behind it.
- [x] SB-M43-027 Modal open/close state survives focus loss/background safely without duplicate callback execution.
- [x] SB-M43-028 Produce/approve the popup chrome visual kit and keep normal labels, values, timers and prices live in Godot. — OWNER VISUAL PASS 2026-09-28.
- [x] SB-M43-029 Add focused automated tests for modal priority, background input suppression, duplicate callbacks and deterministic close/back behavior.

#### M43-C003 - Life / Hearts / Scrub Bucks / Booster / 2x Acquisition Surfaces

- [x] SB-M43-030 Implement the canonical Life popup from the selected Life master reference.
- [x] SB-M43-031 Life popup shows live Hearts current/max and the real next-Heart wall-clock countdown; at 5/5 use the canonical static **15:00 ready state** rather than a separate authoritative timer.
- [x] SB-M43-032 Heart `+` on Home opens Life popup; zero-Heart attempt gate opens the same canonical surface instead of a separate inconsistent dialog.
- [x] SB-M43-033 Life popup supports +1 Heart for 500 SB and full refill at 400 SB per missing Heart using HeartService/EconomyWallet atomically.
- [x] SB-M43-034 Life popup includes the canonical rewarded-video path for +1 Heart when a rewarded placement is available and policy permits it; ad-unavailable state must degrade cleanly.
- [x] SB-M43-035 Rewarded Heart grant is exactly-once per completed verified reward callback; closing/skipping/failing an ad grants nothing.
- [x] SB-M43-036 Scrub Bucks `+` on Home opens the canonical Shop / SB acquisition destination and preserves return context.
- [x] SB-M43-037 Implement one reusable `BoosterAcquirePopup` driven by booster definition data rather than four duplicated scenes.
- [x] SB-M43-038 Booster Acquire popup shows selected booster icon/name, concise effect explanation, owned charges and live SB price.
- [x] SB-M43-039 If a booster charge exists, gameplay uses the charge-first Economy V1 rule and does not unnecessarily open purchase UI.
- [x] SB-M43-040 With zero charge, +1 Slot offers one-use acquisition at 500 SB or one rewarded-video charge/use when available.
- [x] SB-M43-041 With zero charge, Random offers one-use acquisition at 350 SB or one rewarded-video charge/use when available.
- [x] SB-M43-042 With zero charge, Selector offers one-use acquisition at 500 SB or one rewarded-video charge/use when available.
- [x] SB-M43-043 With zero charge, Tornado offers one-use acquisition at 750 SB or one rewarded-video charge/use when available.
- [x] SB-M43-044 A rewarded booster grant must never bypass solver-safety/availability checks; if the booster cannot legally execute, do not consume the newly granted use until the player can use it.
- [x] SB-M43-045 Implement canonical 2x Acquire popup for current level 200 SB / 15m 300 SB / 30m 500 SB / 60m 750 SB.
- [x] SB-M43-046 2x popup shows existing entitlement/time remaining and never charges again for switching 1x/2x while entitlement is active.
- [x] SB-M43-047 Free M23-supply-exhausted auto-2x never opens purchase UI and never consumes/extends paid entitlement.
- [x] SB-M43-048 All acquisition surfaces survive insufficient balance, rapid taps, background/resume, ad unavailable and transaction retry without double spend/grant.
- [x] SB-M43-049 Produce/owner-approve visual masters for Booster Acquire, 2x Acquire and insufficient-SB/Shop handoff states in the canonical popup family. — OWNER VISUAL/UX PASS 2026-09-28.

#### M43-C004 - Fail / Retry / Need a Hand Recovery

- [x] SB-M43-050 Produce/owner-approve a canonical Fail/Retry popup visual master.
- [x] SB-M43-051 Track consecutive failed attempts per current progression level separately from lifetime stats; replay failures do not pollute progression assistance.
- [x] SB-M43-052 Winning the level or changing progression level resets the same-level assistance counter.
- [x] SB-M43-053 After the third consecutive failed attempt on the same progression level, show the canonical Need a Hand? popup after failure resolution and Heart/streak accounting.
- [x] SB-M43-054 Need a Hand? uses the owner-selected `need a hand.png` as art-direction authority but is implemented with live Godot text/buttons/data.
- [x] SB-M43-055 Need a Hand? presents exactly two helpful booster recommendations, not an arbitrary storefront.
- [x] SB-M43-056 Recommendation engine must prefer boosters that are legal/useful for the level/current canonical start-state and must never recommend an unavailable/meaningless action.
- [x] SB-M43-057 Where solver/context evidence cannot distinguish a best pair safely, use a deterministic owner-configured fallback pair rather than fake intelligence.
- [x] SB-M43-058 Each recommended booster can be acquired with its canonical SB cost or a rewarded-video grant when available.
- [x] SB-M43-059 Closing Need a Hand? never spends currency, consumes a Heart, grants a booster or changes puzzle truth.
- [x] SB-M43-060 Assistance popup frequency after the initial third failure is configurable and must avoid appearing after every tap/instant retry in an annoying loop.
- [x] SB-M43-061 Record assistance shown/acquired/declined locally and later expose analytics events under M56 without changing gameplay difficulty behind the player's back.
- [x] SB-M43-062 Test third-failure trigger, reset-on-win, reset-on-level-change, ad/SB acquisition, no-double-grant and unavailable-booster fallback.

#### M43-C005 - Reward, Pack, Collection, Robot, Feature and World Ceremonies

- [x] SB-M43-063 Implement reusable short reward-reveal sequencing with skip/fast-forward only where it cannot skip authoritative grant commits. CLOSED by `coordination/sessions/M43-C005-C005/CHATGPT_AUDIT_V01.md`.
- [x] SB-M43-064 Implement Standard Card Pack opening presentation for 3 draws with rarity reveal and duplicate/new distinction. CLOSED by `coordination/sessions/M43-C005-C006/CHATGPT_AUDIT_V03.md`, `coordination/sessions/M43-C005-C006/owner_review_harness/CHATGPT_AUDIT_V02.md` and final owner acceptance `coordination/sessions/M43-C005-C006/OWNER_VISUAL_ACCEPTANCE_V03.md`.
- [x] SB-M43-065 Implement Premium Card Pack opening presentation for 5 draws including guaranteed Rare-or-better truth from the pack service. CLOSED by `coordination/sessions/M43-C005-C007/CHATGPT_AUDIT_V01.md` and final owner acceptance `coordination/sessions/M43-C005-C007/OWNER_VISUAL_ACCEPTANCE_V01.md`.
- [x] SB-M43-066 Pack contents are committed before/atomically with presentation and reopening the reveal never duplicates cards. CLOSED by `coordination/sessions/M43-C005-C008/CHATGPT_AUDIT_V02.md`.
- [x] SB-M43-067 Implement first-new-card celebration and clear duplicate-count presentation. CLOSED by `coordination/sessions/M43-C005-C009/CHATGPT_AUDIT_V01.md` + `coordination/sessions/M43-C005-C009/OWNER_VISUAL_ACCEPTANCE_V01.md`.
- [ ] SB-M43-068 Implement Collection set 9/9 completion ceremony with the exact per-set SB/Bot Part reward.
- [ ] SB-M43-069 Implement Master Collection completion ceremony for +2500 SB +20 Bot Parts exactly once.
- [ ] SB-M43-070 Implement Robot Unlock ceremony with canonical robot art, name, personality/perk summary and remaining Bot Parts carryover.
- [ ] SB-M43-071 Robot unlock ceremony allows selecting/equipping the unlocked robot or continuing with the current robot.
- [ ] SB-M43-072 Implement feature-unlock ceremony/coachmark used when a new meta system becomes available through M44 feature-unlock pacing.
- [ ] SB-M43-073 Implement World unlock/transition ceremony once world-range rules are owner-defined; never invent ranges in UI.
- [ ] SB-M43-074 Implement Gift Meter milestone celebration for 10/50/250/500/1000 with exact queued reward truth.
- [ ] SB-M43-075 Implement Daily cycle reward celebration and 3/3 Tasks booster-completion celebration.
- [x] SB-M43-076 Produce/owner-approve visual masters for pack opening, robot unlock, set completion, Master Collection, Gift milestone and generic feature/world unlock. CLOSED: C001 ceremony masters owner-accepted; C002 Standard/Premium pack assets final owner pass; C003 135 individually generated Collection cards independent audit PASS; C004 Booster-of-your-choice owner visual PASS + exact canonical intake audit PASS.
- [ ] SB-M43-077 Meta reward ceremonies respect Reduced Effects and can collapse to concise accessible presentation without changing grants.


##### M43-C005R - Gift Meter Micro-Progress Feedback [OWNER APPROVED 2026-09-30]

- [ ] SB-M43-R05-001 Add purely presentational micro-progress/tick feedback between canonical Gift Meter milestones 10/50/250/500/1000 so long gaps visibly advance; micro-ticks mint no reward, create no new economic threshold and cannot be claimed.
- [ ] SB-M43-R05-002 Use one GiftMeterService-derived normalized progress model across Home/Results/Gift Bar; milestone crossing keeps the existing authoritative reward bundle and celebration while intermediate animation remains skippable/Reduced-Effects-safe.

##### M43-C005F - Game Feel Presentation Layer — GameFeelFlow + Saltmire Spark [PLANNED; DOES NOT INTERRUP CURRENT C005 ASSET/OWNER GATES]

Planning basis / API lock: the owner has GameFeelFlow and Saltmire Spark installed and enabled locally. At this planning commit, canonical `origin/main` still has no tracked `addons/` directory and its tracked `project.godot` has no plugin/autoload entries, so no implementation may assume the local install has already been canonicalized. Before integration, verify the exact installed local addon versions/APIs from their checked-in `plugin.cfg`/source. The expected installed API family is: GameFeelFlow autoload `GameFeelFlow` with `play()`, `play_combo()`, `stop_all()`, `get_effect_names()`, `get_combo_names()`; useful registered effects include `punch_scale`, `spring_scale`, `squash_stretch`, element-local `flash`, and built-in UI combos `ui_button_press` / `ui_notification`. Saltmire Spark autoload `Spark` exposes `burst(global_position, opts)`, `at(node, opts)`, `clear()` and presets including `spark`, `pickup`, `confetti`. All usage below is presentation-only and fail-open.

Effect-intensity vocabulary for this program: **MICRO → SMALL → REWARD → MAJOR_REWARD → WIN → MAJOR_UNLOCK**. It is a presentation budget/hierarchy only, never gameplay/economy importance truth. Initial FULL-mode particle ceilings are deliberately conservative and must be profiled before owner acceptance: MICRO 0 Spark particles; SMALL 0–4; REWARD 4–8; MAJOR_REWARD 8–14; WIN 12–18; MAJOR_UNLOCK 16–24. Reduced Effects uses static/native truth first, removes screen/camera effects entirely, disables looping motion, and either removes Spark or caps it to a tiny nonessential burst only where accessibility review approves.

- [ ] **SB-M43-C005F-001 — Canonical plugin intake/API/license gate.** Purpose: reconcile the already-working local GameFeelFlow + Saltmire Spark installation with canonical GitHub before any shipping call site is added. **Seam:** `project.godot`, local `addons/game_feel_flow/`, local `addons/saltmire_spark/`, each addon `plugin.cfg`/autoload registration. **Plugin:** both; verify exact installed names/methods/effects rather than trusting planning assumptions. **Native/existing remains:** Godot project boot, all SCRUBBOTS services/scenes and current M43 sequencing. **Reduced Effects:** N/A except prove the setting service boots with addons present/absent. **Idempotency:** plugin enable/reload must not create duplicate autoloads/signals. **Mobile/perf:** remove/keep removed non-shipping GameFeelFlow examples/tests and Saltmire demo material only after verifying runtime independence; no editor/demo/test dependency in release. **Automated:** headless parse/startup, exact autoload presence, no GdUnit/demo dependency, clean clone. **Godot AI:** open the real project and verify both autoloads answer a harmless capability query without parse/runtime errors. **Regression/gate:** preserve current active M43 work; retain MIT LICENSE/required attribution files; no GameFeelFlow Pro or paid Saltmire Impact dependency; audit required, no owner visual gate because this is intake only.
- [ ] **SB-M43-C005F-002 — One fail-open SCRUBBOTS feedback adapter + intensity policy.** Purpose: prevent plugin calls from being scattered through economy/gameplay code and encode MICRO/SMALL/REWARD/MAJOR_REWARD/WIN/MAJOR_UNLOCK in one presentation-only coordinator. **Seam:** ephemeral app/presentation layer created from `scripts/app/main.gd::_ready()`, reading/subscribing to canonical `EffectsSettingsService.changed`; inject/reference only from Results/Home/popup/ceremony/presentation controllers, never from durable `AppState` authority. **Plugin:** `GameFeelFlow.play()/play_combo()/stop_all()` and `Spark.burst()/at()/clear()`. **Native/existing remains:** `EffectsSettingsService`, AudioSettingsService, HapticsSettingsService, NavigationController, ModalStack, BasePopup lifecycle and all authoritative services. **Reduced Effects:** adapter maps each intent to FULL/REDUCED behavior and can immediately cancel decorative plugin work on a live Reduced toggle. **Idempotency:** API accepts an optional presentation event key and refuses duplicate one-shot keys. **Mobile/perf:** hard per-tier duration/particle ceilings; no unbounded loops or scene-long effect ownership. **Automated:** adapter spies prove intent→plugin mapping, duplicate suppression, missing-autoload/no-op behavior, Reduced mapping and cleanup. **Godot AI:** runtime trigger matrix for each tier. **Regression/gate:** plugin exception/missing node must never stop caller control flow; independent audit required; owner visual gate required only after tier look is bound to real surfaces.
- [ ] **SB-M43-C005F-003 — WON Results one-shot celebration and CLEAN NEXT emphasis.** Purpose: add restrained celebratory feel to an already-committed win. **Seam:** `scripts/app/main.gd::_on_route_changed()` → `ResultsScreen.show_model()`, using `model.status`, `model.attempt`, `ResultsScreen.get_robot()`, Victory emblem/header, existing `set_ceremony_barrier()` and CLEAN NEXT button. **Plugin:** GameFeelFlow `punch_scale`/spring-style scale emphasis plus at most one element-local non-strobing flash; Spark custom `confetti` burst(s) within WIN budget. **Native/existing remains:** Results layout/art, native reward-row tween, receipt truth, Continue latch, ceremony barrier, navigation. **Reduced Effects:** no confetti, no flash, no entrance bounce; preserve static approved Results and immediate reward truth, with at most a single tiny non-repeating CTA emphasis if accessibility review accepts it. **Idempotency:** celebration key must include terminal attempt/status and fire once only; repeated `show_model()`, resize/refresh or Continue re-arm must not replay WIN. **Mobile/perf:** max WIN budget, short self-cleaning lifetime, no camera shake/freeze/time-scale. **Automated:** call-count test across repeated same-attempt `show_model()`, new attempt, LOST/ERROR, barrier hold/release. **Godot AI:** capture FULL/REDUCED WON at required phone/tablet sizes and verify Scrubby/emblem/CTA hierarchy. **Regression/gate:** reward/navigation tests stay green; independent audit + owner visual gate.
- [ ] **SB-M43-C005F-004 — Results reward-row feedback by committed reward kind.** Purpose: make SB, Bot Parts, Gift Meter, card-pack/Collection, first-clear and Win Streak rows feel responsive without changing their order/truth. **Seam:** `ResultsScreen.reward_rows()`, `_row()`, `_start_reveal()` and each row's existing `kind` metadata; effects fire only when the native reveal step actually exposes that already-created committed row. **Plugin:** GameFeelFlow `punch_scale` or `ui_notification` on the row/icon; Spark `pickup`/small custom spark only for REWARD-or-higher rows. **Native/existing remains:** current receipt `reveal_queue`, row creation, native tween sequencing and Continue/Home availability. **Reduced Effects:** preserve current contract that rows are immediately visible; no sequential plugin motion and normally zero particles. **Idempotency:** one row-kind/index event once per Results attempt; refresh must not mint a second celebration. **Mobile/perf:** only one short row effect at a time; particle amount within REWARD ceiling. **Automated:** exact row order/content unchanged, one effect call per eligible row, zero grant/service calls from feedback. **Godot AI:** verify readable amounts during/after effects and no overlap/clipping. **Regression/gate:** M43-C001A/B/R Results tests + receipt idempotency; visual audit required, owner gate may be folded into overall Results feel gate.
- [ ] **SB-M43-C005F-005 — Standard/Premium pack + individual card reveal feel.** Purpose: layer feel onto the owner-approved pack-opening frame sequence and committed card reveals without replacing the art/animation or rerolling contents. **Seam:** future shipping M43-C005 pack ceremony controller built from the approved Standard/Premium frame sets and BasePopup/ModalStack; preview harness is evidence only, never runtime authority. **Plugin:** GameFeelFlow scale punch/squash on pack/card reveal nodes and restrained element-local flash for Rare-or-better only when non-strobing; Spark `pickup`/spark accents within REWARD/MAJOR_REWARD budgets. **Native/existing remains:** approved 9-frame pack art, exact 3/5 committed draws, rarity/new/duplicate truth, grant-before-presentation/idempotency. **Reduced Effects:** jump/crossfade quickly to committed cards; no foil bounce, no flash, particles zero or minimal; all names/rarities/counts remain fully readable. **Idempotency:** opening/reopen/resume can never reroll or replay committed grants; feedback event key derives from committed pack reveal transaction/presentation id. **Mobile/perf:** never animate all 5 Premium cards with high-cost effects simultaneously; stagger/limit within budget. **Automated:** card counts/order/hashes/truth unchanged, no service mutation, duplicate presentation event suppressed. **Godot AI:** visually validate Standard/Premium FULL/REDUCED and frame-to-plugin layering. **Regression/gate:** M39 pack tests + M43 ceremony tests; independent audit + owner visual gate.
- [ ] **SB-M43-C005F-006 — Collection set/master-completion celebration tiers.** Purpose: distinguish 9/9 set completion from all-15 Master Collection without inventing reward value. **Seam:** M43-C005 set/master ceremony BasePopup and committed reward rows, backed by existing Collection completion result. **Plugin:** set completion = GameFeelFlow REWARD/MAJOR_REWARD emblem/hero punch + modest Spark; Master Collection = MAJOR_REWARD with larger but capped confetti. **Native/existing remains:** exact per-set rewards and Master +2500 SB/+20 Bot Parts, once-only transaction truth, approved emblems/art. **Reduced Effects:** static emblem/reward rows, no spin/flash/confetti; optional single tiny scale settle only if accessible. **Idempotency:** one visual completion key per claimed set/master transaction. **Mobile/perf:** no stacking multiple set/master emitters if rewards queue together; serialize presentation only, never grants. **Automated:** exactly-once Collection reward regressions plus effect-call keys. **Godot AI:** compare ordinary set vs Master intensity and text legibility. **Regression/gate:** M54 016A/026 stay authoritative; independent audit + owner visual gate.
- [ ] **SB-M43-C005F-007 — Robot / feature / world unlock feel, with MAJOR_UNLOCK ceiling.** Purpose: give genuinely major unlocks stronger but coherent presentation. **Seam:** M43-C005 Robot Unlock, feature-unlock coachmark and world-transition ceremony surfaces built on BasePopup/ModalStack; World remains gated by owner-defined ranges. **Plugin:** GameFeelFlow spring/punch on hero/emblem and one non-strobing element flash; Spark capped confetti/sparkle at MAJOR_UNLOCK. **Native/existing remains:** `RobotUnlockService`, equip/keep-current choice, M44 feature-unlock authority, NavigationController/world registry/transition logic, approved robot/world art. **Reduced Effects:** static hero/emblem + readable unlock copy; no confetti/flash/loop/spin. **Idempotency:** keyed to authoritative unlock id; refresh/equip choice/world navigation cannot retrigger the unlock ceremony. **Mobile/perf:** one major-unlock particle group at a time, short lifetime, no camera manipulation. **Automated:** unlock/equip/world truth unchanged and effect duplicates refused. **Godot AI:** Robot FULL/REDUCED mandatory; feature/world once those surfaces exist. **Regression/gate:** M43-070..073 and M54-027/030/032; independent audit + owner visual gate.
- [ ] **SB-M43-C005F-008 — Gift Meter, Gift claim, Daily/Tasks and earned-ScrubBox celebration feel.** Purpose: emphasize actual milestone/claim commits while keeping ordinary progress quiet. **Seam:** existing/future Gift Meter milestone ceremony, Gift Bar claim result, M43-C005R normalized progress, Daily claim and 3/3 Tasks/ScrubBox committed outcome. **Plugin:** GameFeelFlow `ui_notification`/punch; Spark `pickup` for ordinary committed claim and capped confetti for real milestone/ScrubBox completion. **Native/existing remains:** GiftMeterService thresholds 10/50/250/500/1000, Daily/Tasks reward authority, Home/Gift Bar progress rendering. **Reduced Effects:** static progress jump + claim confirmation, particles off/minimal; no repeated pulse on ordinary refresh. **Idempotency:** only changed committed milestone/claim ids fire; Home refresh/reopen never retriggers. **Mobile/perf:** no particle burst for every micro-progress tick; milestone-only Spark. **Automated:** threshold/claim exactly-once plus refresh-no-repeat tests. **Godot AI:** Gift milestone and 3/3 Tasks/ScrubBox FULL/REDUCED captures. **Regression/gate:** M43-R05, M43-C009/R09 and M54-028/035; audit + owner gate for milestone intensity.
- [ ] **SB-M43-C005F-009 — Important acquisition confirmations and selective button feel.** Purpose: make committed booster/Heart/important actions responsive without coating every button in effects. **Seam:** `AcquisitionFlow._apply_reward_outcome()`, `BasePopup.pending_resolved`, successful canonical booster use/charge acquisition, and high-value CTAs such as CLEAN NEXT / claim / open pack / equip; generic navigation/back/settings buttons stay native. **Plugin:** GameFeelFlow `ui_button_press` for selected primary actions and `ui_notification`/small punch after an authoritative success; Spark `pickup` only after a real grant/use commit. **Native/existing remains:** ProductionActionFacade, RewardedGrantService, popup pending tokens/latches, HomeStyle button states, audio/haptics. **Reduced Effects:** no particle burst; press state stays native, optional minimal scale feedback only. **Idempotency:** no effect before success callback; duplicate provider callbacks/rapid taps cannot duplicate feedback or grants. **Mobile/perf:** MICRO/SMALL/REWARD ceilings only. **Automated:** success/fail/cancel/timeout/duplicate callback matrix proves effects occur only after committed success. **Godot AI:** booster acquisition success/failure and primary CTA comparison. **Regression/gate:** M43-C003/M54-023/024; audit required, owner gate only for any visually prominent acquisition burst.
- [ ] **SB-M43-C005F-010 — Gameplay-complete → Results presentation bridge.** Purpose: smooth the transition from authoritative terminal completion into Results without delaying or owning the transition. **Seam:** `ProductionGameplayHost.get_completion().terminal_reached` observed by `scripts/app/main.gd::_bind_terminal()` and `NavigationController.on_gameplay_terminal()`; any plugin effect begins only after terminal truth is latched and must not await before navigation. **Plugin:** at most SMALL GameFeelFlow completion pulse/settle on presentation/HUD; Results-side Spark belongs to SB-M43-C005F-003, preventing duplicate confetti. **Native/existing remains:** completion signal, economy/save commit order, nav transition and host lifetime. **Reduced Effects:** no completion pulse; transition remains immediate. **Idempotency:** one presentation event per attempt terminal; no second event from duplicate signal/route refresh. **Mobile/perf:** sub-250 ms decorative work, no screen freeze/camera shake/time-scale. **Automated:** deliberate plugin throw/missing-autoload still reaches Results once with same receipt/save; duplicate-terminal guards unchanged. **Godot AI:** real level WIN transition with plugin FULL/REDUCED/disabled. **Regression/gate:** M30/M40/M42/M43 terminal/navigation tests; independent audit, no separate owner gate if visually subordinate to Results gate.
- [ ] **SB-M43-C005F-011 — Existing CleaningEffectsController Spark comparison/augmentation gate.** Purpose: test whether Saltmire Spark genuinely improves committed-cell cleaning feedback without replacing the accepted M31 pipeline. **Seam:** `CleaningEffectsController._on_authenticated_clear() -> request_effect() -> _spawn()`, existing identity-stable CleaningFxLayer, `MAX_ACTIVE_EFFECTS=24` / `REDUCED_MAX_ACTIVE=8`, approved puff/sparkle textures. **Plugin:** Saltmire Spark only; **do not use GameFeelFlow per cleared cell**. **Native/existing remains:** current puff + sparkle sprites, lifetimes, layer, cell placement, caps, reset/retry hygiene and authenticated-clear observer. **Reduced Effects:** keep current one-shorter-puff behavior and no Spark. **Idempotency:** one committed authenticated clear may request at most one bounded Spark accent; rolled-back/rejected/non-clear events produce none. **Mobile/perf:** compare A/B at 59×59 and 2×; if procedural Spark adds no clear visual benefit or exceeds budget, close this row as explicit **DO NOT USE Spark for per-cell cleaning** rather than forcing it in; no unlimited emitter creation. **Automated:** existing M31 tests plus plugin-call cap/lifetime/suppression tests; never alter clear count/timing. **Godot AI:** side-by-side native-only vs augmented real gameplay. **Regression/gate:** M31/M46 performance and gameplay truth; independent audit + owner visual gate before enabling augmentation.
- [ ] **SB-M43-C005F-012 — Home / Results-momentum micro feedback without refresh spam.** Purpose: add tiny state-change emphasis only where Home already exposes meaningful progression. **Seam:** Home's existing live `refresh()`/Gift Meter presentation and shared `JourneyStrip` state updates; Results momentum remains under its existing reveal/barrier contract. **Plugin:** GameFeelFlow MICRO/SMALL pulse on an actually changed progress/milestone/next-cleanup state; Spark normally **not used** on Home refresh. **Native/existing remains:** Home layout, Home Scrubby frame animation, JourneyStrip, safe-area logic, live values, modal hiding and Results teaser. **Reduced Effects:** static state update only. **Idempotency:** compare previous presentation state so repeated `refresh()`, viewport resize or modal close does not refire. **Mobile/perf:** zero idle loops and zero permanent per-widget feedback nodes. **Automated:** unchanged refresh produces zero plugin calls; changed authoritative state produces one. **Godot AI:** Home normal/modal/reduced snapshots with no visual collision. **Regression/gate:** M42/M43-R01/R05 Home tests; audit required; owner gate only if the change is visually noticeable enough to alter approved Home hierarchy.
- [ ] **SB-M43-C005F-013 — Canonical FULL/REDUCED effects matrix and live cancellation.** Purpose: make Reduced Effects one coherent accessibility contract across native + plugin effects. **Seam:** canonical `EffectsSettingsService.is_reduced()/changed`, existing Results `model["reduced_effects"]`, CleaningEffectsController `set_reduced_effects()`, future ceremony/popup feedback adapter. **Plugin:** both; on Reduced toggle cancel/settle decorative GFF work with targeted `GameFeelFlow.stop_all(presentation_root)` and clear active Spark through adapter-owned lifecycle, without touching native state. **Native/existing remains:** existing reduced row-reveal behavior, cleaning reduced cap/lifetime and all content/state. **Reduced Effects:** explicitly disables confetti, looping spin/wiggle, element flash and any camera/screen manipulation; major rewards/unlocks remain understandable via static art/text/order. **Idempotency:** toggle itself never replays a celebration when returning to FULL. **Mobile/perf:** Reduced is materially cheaper than FULL in node count/particles/animation. **Automated:** per-intent FULL/REDUCED table and live-toggle cleanup tests. **Godot AI:** every representative tier in both modes. **Regression/gate:** M41 settings persistence and M50 accessibility; independent audit + owner accessibility visual gate.
- [ ] **SB-M43-C005F-014 — Explicit DO-NOT-USE plugin boundary.** Purpose: prevent presentation addons from colonizing systems that already have safe authorities. **Seam:** architecture-wide guard enforced by code review/tests. **Plugin:** both, but prohibited from SafeAreaRoot/safe-area math; NavigationController/route truth; ModalStack/BasePopup lifecycle/pending-token authority; gameplay BoardState/candidate/reservation/TargetSelector/routing/supply/slot/solver/collision/terminal truth; economy/reward/save/progression/Heart/timers; existing Home Scrubby frame-animation authority; existing audio/haptics services; any ad/IAP callback authority. GameFeelFlow effects `camera_shake`, `camera_flash`, `freeze_frame`, `time_scale`, `pause`, physics/collider/velocity/rigidbody effects, scene/destroy/spawn authority and looping flicker are **DO NOT USE** for V1; screen-wide/strobing flash is forbidden. Saltmire Spark never determines hit/clear/reward success. **Native/existing remains:** all named systems. **Reduced Effects:** prohibited categories stay prohibited in FULL and REDUCED. **Idempotency:** no plugin callback may be an authority callback. **Mobile/perf:** avoids hidden global work. **Automated:** static dependency/import scan plus fault injection showing plugin removal leaves authority paths operational. **Godot AI:** run core Home/gameplay/Results with plugins disabled and verify functionality. **Regression/gate:** full authoritative subsystem regression; independent architectural audit, no owner visual gate.
- [ ] **SB-M43-C005F-015 — End-to-end feel validation + owner visual gate.** Purpose: close the plugin program only after runtime evidence proves coherent hierarchy, safety and restraint. **Seam:** representative real shipping paths: WON Results, reward rows, Standard/Premium pack, set/master completion, Robot Unlock, Gift milestone, acquisition confirmation, gameplay completion, Home state change and cleaning comparison. **Plugin:** both through the single adapter only. **Native/existing remains:** all authoritative/native presentation systems listed above. **Reduced Effects:** every representative path captured in FULL + REDUCED; plugin-disabled fallback also exercised. **Idempotency:** repeated Results model refresh, popup reopen, resize, background/foreground and duplicate callbacks produce no extra one-shot celebration. **Mobile/perf:** use approved budgets and no orphan emitters/tweens after scene change. **Automated:** focused suite + root regression + call-count/fault-injection checks. **Godot AI:** mandatory real-runtime visual validation at 1080×1920, 1080×2160, 1290×2796 and 1536×2048 where applicable, plus gameplay at production load; inspect actual frames, not metadata-only. **Regression/gate:** independent ChatGPT audit and owner final visual acceptance required before any plugin feel work is marked complete.

#### M43-C006 - Shop / Store / Currency Destination

- [ ] SB-M43-078 Implement a real Shop destination opened by the Home SHOP shortcut and Scrub Bucks `+`.
- [ ] SB-M43-079 Produce/owner-approve a Shop visual master before final production binding.
- [ ] SB-M43-080 Shop V1 surface groups Hearts, boosters, 2x products and later real-money/SB acquisition without inventing a second premium currency.
- [ ] SB-M43-081 No Ads entry belongs to Shop, not Home, and remains gated by M57 product definition.
- [ ] SB-M43-082 Shop shows live wallet/Heart/booster/entitlement state and never displays baked prices or stale quantities.
- [ ] SB-M43-083 Soft-currency purchases route through existing authoritative services; UI never mutates balances directly.
- [ ] SB-M43-084 Real-money product cards, localized cash prices, restore purchases and receipt state are bound only after M57 authorizes products/provider.
- [ ] SB-M43-085 Implement purchase confirmation where platform policy/product risk requires it and clear pending state on failure/cancel.
- [ ] SB-M43-086 Preserve exact return context when Shop was opened because a player lacked SB for a booster/Heart/2x action.
- [ ] SB-M43-087 Implement sold/unavailable/offline/loading/error states without dead buttons.
- [ ] SB-M43-088 Test rapid taps, insufficient SB, provider cancel/failure, restore, background/resume and idempotent fulfillment.
- [ ] SB-M43-089 Shop visual/audio feedback must not imitate guaranteed rewards for uncompleted purchases.

#### M43-C007 - Collection / Cards Exchange Destination

- [ ] SB-M43-090 Implement Collection main screen for all 15 canonical sets x 9 cards = 135 cards.
- [ ] SB-M43-091 Produce/owner-approve Collection album visual master using existing canonical card art.
- [ ] SB-M43-092 Show set progress N/9, completed state and exact set-completion reward without hiding rarity burden.
- [ ] SB-M43-093 Implement set detail page with 9 card slots, rarity, owned/new/duplicate state and protected first-copy semantics.
- [ ] SB-M43-094 Implement card detail popup with full art, name/rarity, owned count and exchangeable extra count.
- [ ] SB-M43-095 Cards Exchange is a Collection-owned flow, not a Home shortcut.
- [ ] SB-M43-096 Implement per-card duplicate exchange and EXCHANGE ALL EXTRAS with atomic confirmation and protected-copy floor of 1.
- [ ] SB-M43-097 Show live exchange SB values Common 25 / Rare 75 / Epic 200 / Legendary 500.
- [ ] SB-M43-098 Add Standard/Premium pack inventory/open entry and route opening to M43-C005.
- [ ] SB-M43-099 Completed-set and Master Collection reward history/status must be visible enough to prevent confusion without enabling duplicate grants.
- [ ] SB-M43-100 Collection supports locked/future set presentation without leaking nonexistent cards or fake progress.
- [ ] SB-M43-101 Validate 135-card performance, scrolling, touch targets, localization, duplicate-heavy inventories and completion transitions.


#### M43-C007R - Collection Fairness / Pity / First Collection Sprint [OWNER APPROVED 2026-09-30]

- [ ] SB-M43-R07-001 Add a versioned **earned-pack pity counter**: consecutive eligible Standard/Premium pack openings with no new card increment the counter; obtaining any new card resets it. Threshold is data-driven and must be balance-simulated before final tuning.
- [ ] SB-M43-R07-002 When pity reaches its configured threshold, the next eligible earned pack guarantees at least one currently eligible missing card while still preserving Premium's Rare-or-better guarantee; pack contents commit atomically before reveal.
- [ ] SB-M43-R07-003 If no eligible missing card exists, pity cannot fabricate a card; show the collection-complete state and use only an explicitly configured fallback. Pity state persists through save/cloud migration and cannot be reset by app restart.
- [ ] SB-M43-R07-004 Pity applies only to **earned** card packs under the current V1 policy. It cannot be purchased, rerolled for money/SB, accelerated by watching ads or converted into a paid-random mechanic; M57's no-paid-random-pack rule remains intact.
- [ ] SB-M43-R07-005 Make pity legible rather than covert: when one pack away from guarantee, Collection/pack UI may state **NEW CARD GUARANTEED NEXT PACK**; never use near-miss animation or misleading "almost won" presentation.
- [ ] SB-M43-R07-006 Tune a **First Collection Sprint** so an ordinarily engaged fresh player can realistically complete Set 1 during the early campaign, target window roughly Levels 20–40, using earned progression/Daily/Gift pack sources rather than purchases; exact source placement remains data-driven and must not alter robot-unlock pacing.

#### M43-C008 - Robots Destination

- [ ] SB-M43-102 Implement ROBOTS bottom-nav destination for the canonical 10-robot roster.
- [ ] SB-M43-103 Produce/owner-approve Robots screen visual master using the existing robot asset family.
- [ ] SB-M43-104 Show unlocked/locked state, canonical order, Bot Parts N/250 toward next unlock and overflow.
- [ ] SB-M43-105 Show each robot's canonical 20% meta perk clearly without implying puzzle-solvability power.
- [ ] SB-M43-106 Allow selecting/equipping any unlocked robot and persist active robot.
- [ ] SB-M43-107 Locked robot detail shows required Bot Parts and preview/perk; Bot Parts cannot be bought with SB or real money in V1.
- [ ] SB-M43-108 Active robot selection updates Home/gameplay/profile/support/victory presentation using the approved per-robot asset family.
- [ ] SB-M43-109 Robot selection must never mutate BoardState, TargetSelector, routing, solver or batch legality.
- [ ] SB-M43-110 Implement robot unlock history/NEW badge clearing without repeated ceremonies.
- [ ] SB-M43-111 Validate all 10 robots at mobile scale and fall back safely if a presentation asset is missing rather than corrupting gameplay.

#### M43-C009 - Tasks / Daily / Gift Bar Destinations

- [ ] SB-M43-112 Implement TASKS Home destination showing exactly three daily tasks, progress and individual 75/100/125 SB rewards.
- [ ] SB-M43-113 Produce/owner-approve Tasks visual master.
- [ ] SB-M43-114 Claim state is exactly-once and 3/3 completion grants one random Booster Charge exactly once.
- [ ] SB-M43-115 Implement final DAILY destination/popup with visible consecutive-login count and repeating 5-day reward cycle.
- [ ] SB-M43-116 Produce/owner-approve final Daily visual master and reward-state variants.
- [ ] SB-M43-117 Daily shows claimed/today/future-day states, current consecutive days and canonical D1-D5 rewards.
- [ ] SB-M43-118 Implement Gift Bar claim/history surface for queued Gift Meter milestones.
- [ ] SB-M43-119 Produce/owner-approve Gift Bar visual master and milestone reward cards.
- [ ] SB-M43-120 Gift Bar claim/history never feeds Gift Meter recursively and never re-grants claimed milestones.
- [ ] SB-M43-121 Test local-day rollover, missed-day reset, clock rollback, all-3 Tasks completion, Gift rollover and duplicate taps.


#### M43-C009R - Daily Scrub Orders / Earned ScrubBox [OWNER APPROVED 2026-09-30]

This extension **does not change** the canonical consecutive-login reset rule or repeating 5-day Daily reward cycle.

- [ ] SB-M43-R09-001 Replace generic task content with a data-driven **Daily Scrub Orders** archetype pool while keeping **exactly three active tasks/day** and the existing 75/100/125 SB reward tiers.
- [ ] SB-M43-R09-002 Eligible task archetypes should advance through ordinary play: complete progression levels, clear bounded amounts/colors, win a qualifying difficulty, complete a level without a booster, or other already-unlocked normal actions; never require real-money spend, ad viewing or an unavailable feature.
- [ ] SB-M43-R09-003 Daily generation uses the local-day authority plus deterministic/versioned eligibility rules so tasks cannot silently reroll on relaunch; exclude impossible tasks based on current frontier, unlocked systems and available production content.
- [ ] SB-M43-R09-004 Keep one easy / one normal / one stretch intent aligned with 75/100/125 SB while bounding grind; a task must be finishable in a normal play session and must not encourage intentionally losing or wasting Hearts.
- [ ] SB-M43-R09-005 Present the existing all-3 completion reward through an **earned ScrubBox** ceremony. Phase A reward floor remains the canonical one random Booster Charge exactly once; the box is never sold and has no paid reroll/open-speed mechanic.
- [ ] SB-M43-R09-006 A future small surprise bonus slot (bounded SB/card-pack/approved existing reward types only) may be enabled from versioned tuning **only after M56 economy/retention simulation and owner approval**; no jackpot/near-miss presentation and no new currency.

#### M43-C010 - Bottom Navigation / Profile / Achievements / Events / Ranks

- [ ] SB-M43-122 BottomNav destinations are real: EVENTS / ROBOTS / HOME / RANKS / SETTINGS. No shipping dead tab.
- [ ] SB-M43-123 Preserve M41 Settings as the canonical Settings destination and do not duplicate Settings behavior.
- [ ] SB-M43-124 Add player Profile entry from the Home/profile card with active robot, campaign level, key lifetime stats, Collection completion and achievement summary.
- [ ] SB-M43-125 Produce/owner-approve Profile visual master.
- [ ] SB-M43-126 Implement an Achievements framework and screen with data-driven achievement definitions, progress, completed state and cosmetic/reward policy separated from gameplay truth.
- [ ] SB-M43-127 Produce/owner-approve Achievements visual master before broad achievement-content production.
- [ ] SB-M43-128 Define and implement EVENTS destination without Event Points or a new event currency; use existing SB/Bot Parts/Card Packs/Booster rewards unless a later owner decision adds something.
- [ ] SB-M43-129 Events support event list/home, detail, countdown, participation/progress, reward summary, ended/claimed state and offline/unavailable state.
- [ ] SB-M43-130 Produce/owner-approve Events visual master and at least one reusable event card/detail family.
- [ ] SB-M43-131 Define RANKS scoring/ranking policy in an owner decision before implementation; never invent a pay-to-win ranking metric.
- [ ] SB-M43-132 Implement RANKS destination with season/window label, player placement, surrounding ranks, top ranks, loading/offline/empty states and privacy-safe display identity.
- [ ] SB-M43-133 Produce/owner-approve Ranks visual master before production binding.
- [ ] SB-M43-134 Home/BottomNav badge system supports Tasks ready, Daily ready, Gift claimable, Robot unlock/new, Collection new, Event active/reward and other approved attention states without notification spam.


#### M43-C010R - Weekly Mini Event / First-Try Challenge / Personal Best [OWNER APPROVED 2026-09-30]

- [ ] SB-M43-R10-001 Ship a reusable **Weekly Cleaning Event** template under EVENTS: seven-day window, normal progression play contributes automatically, no new event currency, and fixed milestone rewards use only approved SB/Card Pack/Booster/Bot Part reward types.
- [ ] SB-M43-R10-002 Weekly progress should primarily count valid first-clear progression wins or another owner-configured normal-play signal; replay farming, ad watching and spending do not become the fastest event path.
- [ ] SB-M43-R10-003 Missing a day does not reset Weekly Event progress. Event expiry/claim state is explicit, stale events fail safely, and unclaimed-expiry policy must be owner/config-defined before launch.
- [ ] SB-M43-R10-004 Add an opt-in **First-Try Cleanup** challenge: five qualifying progression levels form a run; only the first attempt at each qualifying level can extend the run, and a qualifying loss resets only the event run, never campaign progression.
- [ ] SB-M43-R10-005 First-Try Cleanup cannot charge an extra Heart beyond the normal attempt, sell a paid continue, rewind completed campaign levels or let replay farm the run; rewards are fixed/visible before participation.
- [ ] SB-M43-R10-006 Add **Personal Best** records to Profile/Achievements using self-comparison only: best Win Streak, best first-try run, boosterless first-clear count/run and other fair non-pay-to-win mastery records. No asynchronous social comparison is added by this approval.
- [ ] SB-M43-R10-007 Where useful, show a lightweight **self-ghost** progress marker against the player's own prior best/current record target; it is informational, never changes difficulty/rewards and cannot imply a global/friend opponent.

#### M43-C011 - World Progression / World Home System

- [ ] SB-M43-135 Preserve World 01 Whispering Park as current default complete 1080x2160 Home background.
- [ ] SB-M43-136 Define owner-approved campaign level ranges / completion conditions for future worlds before any hardcoded range exists.
- [ ] SB-M43-137 Implement data-driven world registry mapping world ID to background, title/area semantics, unlock condition and optional world reward.
- [ ] SB-M43-138 Produce/owner-approve one complete visual master/background for every shipping world before activation.
- [ ] SB-M43-139 Implement locked/current/completed world states and deterministic transition after qualifying progression.
- [ ] SB-M43-140 Implement world-unlock ceremony via M43-C005.
- [ ] SB-M43-141 Home world selection/automatic current-world presentation must never desynchronize from progression truth.
- [ ] SB-M43-142 Future world art remains decorative/meta presentation and cannot change level solver/difficulty truth.

#### M43-C012 - Comeback / Notifications / Return-to-Game Experience

- [ ] SB-M43-143 Implement a non-punitive comeback surface for players returning after a configurable long absence, summarizing ready Hearts/Daily/Event/Gift/Tasks state without fabricating rewards.
- [ ] SB-M43-144 Comeback flow may highlight existing claimable rewards but cannot mint an unapproved "welcome back" reward silently.
- [ ] SB-M43-145 Design opt-in push-notification categories: Hearts full/ready, Daily available, Event ending, claimable reward and other owner-approved reminders.
- [ ] SB-M43-146 Request notification permission contextually, not on first frame, and explain the benefit before the OS prompt where platform policy permits.
- [ ] SB-M43-147 Implement per-category toggles plus global notification control and quiet-hours/local-time awareness.
- [ ] SB-M43-148 Notifications deep-link only to valid in-app destinations and fail safely to Home when content is stale.
- [ ] SB-M43-149 Never send notification spam for every Heart tick, every failed attempt or repeated unclaimed badge.
- [ ] SB-M43-150 Produce/approve any comeback/notification-permission illustration needed; keep system permission UI native.
- [ ] SB-M43-151 Test timezone changes, missed days, expired events, disabled permissions and stale deep links.


#### M43-C012R - Comeback Catch-Up / Smart Notification Prioritization [OWNER APPROVED 2026-09-30]

- [ ] SB-M43-R12-001 Add a configurable **Comeback Catch-Up Track** for a genuine absence (initial tuning candidate: >=48 hours): three qualifying first-clear progression wins rebuild momentum through a small capped reward/progress sequence using only approved existing reward types.
- [ ] SB-M43-R12-002 Catch-Up never restores missed Daily login days, never changes the existing consecutive-login reset/cycle rule, never retroactively grants missed event/Daily rewards and never multiplies normal level economy.
- [ ] SB-M43-R12-003 Catch-Up is offered once per eligible return window, persists across relaunch, completes/expirs deterministically and cannot be farmed by clock rollback, uninstall/reinstall or repeatedly backgrounding the app.
- [ ] SB-M43-R12-004 Define a notification **priority/dedup authority** across Hearts ready, Daily available, Gift claimable and Event ending so simultaneous triggers collapse into the single most useful message/deep link instead of multiple pushes.
- [x] SB-M43-R12-005 Default retention-notification cap: at most one non-transactional proactive push per local 24-hour period, respecting opt-in, per-category toggles and quiet hours; user-requested/platform-transactional notifications remain separately governed.
- [ ] SB-M43-R12-006 Notification copy must be factual and non-guilt-inducing, must not claim expiring rewards that are not actually expiring, and must suppress stale/already-consumed prompts before send when current state is available.
- [x] SB-M43-R12-007 Add tests for absence qualification, catch-up idempotency, Daily-rule non-interference, priority collapse, 24-hour cap, quiet hours, stale-state suppression and deep-link fallback.

#### M43-C013 - Account / Cloud Save / Cross-Device Recovery

- [ ] SB-M43-152 Keep local save authoritative/offline-capable even when account/cloud features are unavailable.
- [ ] SB-M43-153 Define optional account/sign-in provider strategy in an owner/platform decision before adding SDKs.
- [ ] SB-M43-154 Implement cloud-save schema/versioning compatible with M40 and preserve idempotent economy transaction IDs.
- [x] SB-M43-155 Implement explicit cloud conflict resolution using revision/timestamp/progression/economy safety rules; never silently duplicate currency/rewards.
- [ ] SB-M43-156 Implement sign-in, signed-out, syncing, synced, conflict, error and offline states.
- [ ] SB-M43-157 Implement restore-on-new-device flow and verify Collection/robots/booster/entitlement/Daily state integrity.
- [ ] SB-M43-158 Platform purchase restore remains tied to M57/store authority and must reconcile with cloud/local save idempotently.
- [ ] SB-M43-159 Produce/owner-approve only the minimal account/cloud screens needed; do not replace platform-native sign-in consent UI.
- [ ] SB-M43-160 Add destructive account/sign-out/reset confirmations and privacy-data entry points as required by M58.

#### M43-C014 - Meta UI Audio / Haptics / Offline / Error Language

- [x] SB-M43-161 Define a compact meta-UI audio family for button confirm/back, popup open/close, reward reveal, pack reveal, robot unlock and error; reuse where pleasant rather than create noisy per-screen sounds.
- [x] SB-M43-162 Define haptic moments for success, warning, pack rare reveal and unlock while respecting Haptics OFF and Reduced Effects.
- [ ] SB-M43-163 Meta UI must obey Master/Music/SFX/Haptics settings immediately.
- [ ] SB-M43-164 No purchase/ad/error sound may falsely imply success before an authoritative callback.
- [ ] SB-M43-165 Implement consistent offline/error language and retry affordances for Shop, ads, cloud, Events, Ranks and notifications/deep links.
- [ ] SB-M43-166 Implement graceful empty states for no events, no rankings result, no exchangeable duplicates, no claimable gifts and no tasks ready.
- [x] SB-M43-167 Validate meta audio/haptic fatigue in repeated menu/claim/open/close loops.
- [ ] SB-M43-168 Owner acceptance required for the final cross-screen sound/haptic feel.

#### M43-C015 - Player-Facing Surface Visual Inventory Gate

Before M43 program closure, the following surfaces must each have a canonical visual master/reference, production scene, responsive validation, independent audit and owner acceptance where visually material:

1. Gameplay V02.
2. Pause.
3. Level Intro.
4. Victory / Results.
5. Fail / Retry.
6. Life / Heart refill.
7. Need a Hand.
8. Booster Acquire.
9. 2x Acquire.
10. Insufficient SB / purchase handoff.
11. Shop.
12. Collection album.
13. Collection set detail.
14. Card detail.
15. Cards Exchange.
16. Standard Pack opening.
17. Premium Pack opening.
18. Collection-set completion.
19. Master Collection completion.
20. Robots main.
21. Robot detail/locked.
22. Robot unlock.
23. Tasks.
24. Daily.
25. Gift Bar.
26. Gift Meter milestone.
27. Profile.
28. Achievements.
29. Events main/list.
30. Event detail/reward.
31. Ranks.
32. Comeback/return summary.
33. Feature unlock/coachmark.
34. World unlock/transition.
35. Account/cloud sync/conflict where custom UI is needed.
36. Generic reward/confirmation.
37. Generic error/offline/loading.
38. Notification education/settings where custom UI is needed.
39. Rewarded Ads daily claim/watch surface.

- [ ] SB-M43-169 Create `assets/ui/PLAYER_EXPERIENCE_ASSET_MANIFEST.json` covering every surface above and all generated illustration components.
- [ ] SB-M43-170 No M43 program closure while any required surface is missing, visually unreviewed, wired to dummy data or reachable only through debug tooling.

#### M43-C015R - Owner Runtime Review Remediation [OWNER REQUEST 2026-10-06]

These three rows are the only new work authorized by the 2026-10-06 F5 owner review. The existing four primary Home panels remain SHOP / COLLECTION / TASKS / DAILY; the Rewarded Ads entry is an additional compact auxiliary CTA, not a fifth equal Home panel. Existing Daily consecutive-login authority remains intact and separate.

- [ ] **SB-M43-R15-001 — Rewarded Ads daily five-slot surface.** Technical base exists, but owner has now locked **sequential unlock** semantics: Slot 1 is a direct `CLAIM`; only after Slot 1 is durably granted does Slot 2 become available; only after Slot 2 receives a successful verified rewarded-video grant does Slot 3 unlock; then 4; then 5. Future slots stay visibly locked and cannot start an ad early. Cancel/skip/fail/timeout/unverified/provider-unavailable grants nothing **and does not advance the sequence**. Each slot grants exactly once per local day under deterministic tx ids `daily_rewarded:<local_day>:<slot>`. Seeded D1-D5 reward bundles, distinct rewarded-daily authority, rollback/relaunch/idempotency protections, Daily login separation and Daily Scrub Orders remain unchanged. **No Home notification/badge is required. Parked behind Remote Level Update priority until implementation resumes.**
- [ ] **SB-M43-R15-002 — Settings visual-family remediation.** Preserve every closed M41 Settings behavior/state/persistence contract exactly, but replace the generic dark rectangle with the canonical SCRUBBOTS M43 popup language visible in the owner's accepted screens: cyan/white mechanical frame, cream/white content field, royal-blue SETTINGS title treatment, canonical close/X treatment, readable navy labels, themed sliders/toggles and touch targets. Reuse `BasePopup`/`HomeStyle`/`UiTokens`/approved existing assets where practical; do not add a second settings authority or alter Master/Music/SFX/Haptics/Reduced Effects semantics.
- [ ] **SB-M43-R15-003 — Daily Rewards containment remediation.** Keep the current consecutive-login logic, D1-D5 values and claim authority unchanged. Fix the owner-observed composition so Daily Rewards art does not protrude outside the intended popup/table/content bounds: the calendar/hero, flame, five day-card frames, state/check art, rule text and buttons must remain visually contained and readable at 683x1366 and the canonical responsive matrix. No clipping of reward text, no overlap with title/actions, no layout regression to Tasks/Gift Bar, and no change to Daily reward truth.
- [x] **SB-M43-R15-004 — Rewarded Ads Home icon visual remediation. OWNER VISUAL PASS [2026-10-06].** Canonical owner master is the committed text-free Scrubby/video/Scrub-Bucks/Hearts PNG pinned at SHA-256 `ce96e09aaf97db5ed171c7da15e2c8afccc46d4408a1cc64bc0521db89a96c8b`; no baked label. Final accepted placement: Rewarded Ads under COLLECTION, exactly `210×156` like SHOP/COLLECTION, standard shortcut glass panel, one-line code-rendered `REWARDED ADS` label. Four primary shortcut columns and Rewarded Ads functionality remain unchanged.

**Shared later-screen visual production rules**
- [ ] SB-UI-017 Implement reusable `BasePopup` composition.
- [ ] SB-UI-018 Keep popup text/rewards/quantities/buttons/state dynamic in Godot.
- [ ] SB-UI-019 For each later screen milestone, identify/generate/approve/bind required illustration assets inside that milestone.
- [ ] SB-UI-020 Do not pre-generate speculative asset libraries for unknown future states.
- [ ] SB-UI-021 Treat final visual polish as consolidation/QA, not first production-art implementation.

### M44 - Tutorial / FTUE / Feature Unlock Pacing [DESIGN + IMPLEMENTATION REQUIRED]

Purpose: teach the real production game progressively and prevent the first session from exposing every meta system at once. Feature unlocks are presentation/access pacing only; they do not rewrite already-earned authoritative state.

- [ ] SB-M44-001 Define the complete first-time user experience from cold launch through the first 10 progression levels.
- [ ] SB-M44-002 Level 1 teaches only the minimum real core loop needed to make a legal supply-front selection and observe Scrubbot cleaning.
- [ ] SB-M44-003 Teach five execution slots and automatic rightmost-empty placement through play, not a detached rules wall.
- [ ] SB-M44-004 Teach preview rows/front-only interaction at the first point the distinction matters.
- [ ] SB-M44-005 Teach WAITING/no-current-target behavior only when the player first encounters it, using contextual coachmark/highlight.
- [ ] SB-M44-006 Teach win/fail/Retry and Heart consequence at first relevant occurrence.
- [ ] SB-M44-007 Introduce the four boosters progressively; do not unlock/show all acquisition prompts in the opening minute.
- [ ] SB-M44-008 Teach +1 Slot, Random, Selector and Tornado using real mechanics and solver-safe tutorial fixtures/states.
- [ ] SB-M44-009 Introduce 2x only after the player understands normal-speed cleaning; explain paid manual entitlement vs free automatic endgame 2x without clutter.
- [ ] SB-M44-010 Define owner-approved feature-unlock order/campaign points for Hearts, booster acquisition, Daily, Tasks, Collection, Card Packs, Robots, Gift Meter/Gift Bar, Shop, Events, Ranks, Achievements and any later system.
- [ ] SB-M44-011 Do not invent exact unlock level numbers until the owner approves the pacing table; store unlocks data-driven once approved.
- [ ] SB-M44-012 Feature-unlock ceremony uses M43-C005 and is shown at most once per feature/version.
- [ ] SB-M44-013 Newly unlocked Home shortcut/Nav destination may show a NEW badge until first visit; badge clearing persists.
- [ ] SB-M44-014 Tutorial can be skipped/replayed only according to an owner decision and must never duplicate rewards or economy grants.
- [ ] SB-M44-015 Returning existing users after a version adds a feature receive a concise "What's New / feature unlocked" path rather than being forced through beginner tutorial.
- [ ] SB-M44-016 Tutorial overlays pause or gate only presentation/input needed for the lesson; they never inject illegal board/supply state.
- [ ] SB-M44-017 All tutorial copy is localization-ready and essential cues are not color-only.
- [ ] SB-M44-018 Produce/owner-approve tutorial coachmark/highlight visual language and any Scrubby/robot teaching poses actually required.
- [ ] SB-M44-019 Validate tutorial on fresh-save, interrupted/resumed, app-backgrounded, skipped/replayed and migrated-save paths.
- [ ] SB-M44-020 Owner playtest the complete first-session funnel and revise friction before M44 closes.


#### M44 Retention Feature-Pacing Additions [OWNER APPROVED 2026-09-30]

- [ ] SB-M44-021 Introduce Next Cleanup teaser + 10-Level Cleaning Journey during the first-session Results flow only after the player understands win/continue; do not add another blocking tutorial wall.
- [ ] SB-M44-022 Sequence Collection onboarding so Set 1 / first earned packs establish the First Collection Sprint early, while pity remains invisible until relevant and then explains itself truthfully.
- [ ] SB-M44-023 Unlock Daily Scrub Orders, Weekly Cleaning Event and First-Try Cleanup only after their prerequisite core/meta systems are understood; exact campaign unlock points remain data-driven under SB-M44-010/011.
- [ ] SB-M44-024 Comeback Catch-Up is never part of fresh-user FTUE; it activates only after a previously established player meets the configured absence rule.

### M45 — Debug Tooling

- [ ] SB-M45-001 Debug overlay.
- [ ] SB-M45-002 Level ID.
- [ ] SB-M45-003 Difficulty.
- [ ] SB-M45-004 Dimensions.
- [ ] SB-M45-005 Cell count.
- [ ] SB-M45-006 ACTIVE count.
- [ ] SB-M45-007 CLEARED count.
- [ ] SB-M45-008 Reserved count if implemented.
- [ ] SB-M45-009 Active bots.
- [ ] SB-M45-010 FPS.
- [ ] SB-M45-011 Frame time.
- [ ] SB-M45-012 Target markers.
- [ ] SB-M45-013 Route visualization.
- [ ] SB-M45-014 Cell grid.
- [ ] SB-M45-015 Effect toggle.
- [ ] SB-M45-016 Instant reset.
- [ ] SB-M45-017 Level switcher.
- [ ] SB-M45-018 Disable release-facing debug UI.

### M46 — Performance `[PERFORMANCE]`

Maximum board target: 59×59 = 3,481.

- [ ] SB-M46-001 Level parsing.
- [ ] SB-M46-002 BoardState.
- [ ] SB-M46-003 Renderer.
- [ ] SB-M46-004 Color candidate index + reachability/access.
- [ ] SB-M46-005 TargetSelector.
- [ ] SB-M46-006 Routing.
- [ ] SB-M46-007 Scrubbot agents.
- [ ] SB-M46-008 Effects.
- [ ] SB-M46-009 Memory baseline.
- [ ] SB-M46-010 59×59 memory.
- [ ] SB-M46-011 Per-frame allocation detection.
- [ ] SB-M46-012 Repeated restart.
- [ ] SB-M46-013 Long session.
- [ ] SB-M46-014 High agent density.

- [ ] **SB-M46-015 — GameFeelFlow/Saltmire Spark effect-budget profiling.** Purpose: prove the M43-C005F budgets on worst-case SCRUBBOTS load. **Seam:** M46 Effects profiling + M31 CleaningFxLayer + feedback adapter diagnostics. **Plugin:** both. **Native/existing remains:** BoardRenderer/agents/cleaning pipeline. **Reduced Effects:** profile FULL and REDUCED separately. **Idempotency:** repeated scenes must not accumulate emitters/tweens. **Mobile/perf:** 59×59, 2× gameplay, high agent density, simultaneous Results/ceremony cases; measure frame time, allocations, node peak, memory and Spark self-free lifetime; no per-clear GFF. **Automated:** bounded active counts/lifetime leak tests. **Godot AI:** runtime performance overlay/visual sanity during stress. **Regression/gate:** M46-001..014 baseline preserved; performance audit required, no visual owner gate unless budget reduction changes accepted look.

### M47 — Android Device Testing

- [ ] SB-M47-001 Android export setup.
- [ ] SB-M47-002 Development APK.
- [ ] SB-M47-003 Real device install.
- [ ] SB-M47-004 Touch.
- [ ] SB-M47-005 Portrait.
- [ ] SB-M47-006 Safe areas.
- [ ] SB-M47-007 Easy performance.
- [ ] SB-M47-008 Medium performance.
- [ ] SB-M47-009 Hard performance.
- [ ] SB-M47-010 Very Hard/59×59 performance.
- [ ] SB-M47-011 High bot density.
- [ ] SB-M47-012 Background/foreground.
- [ ] SB-M47-013 Heat/battery extended test.
- [ ] SB-M47-014 Record device/results.

- [ ] **SB-M47-015 — Real Android FULL/REDUCED plugin-effects stress.** Purpose: validate the presentation layer on at least one lower-end and one representative Android device. **Seam:** M47 device matrix using real gameplay/Results/ceremonies. **Plugin:** both. **Native/existing remains:** touch/safe-area/portrait/performance authorities. **Reduced Effects:** compare frame pacing, thermal/battery and visual clarity against FULL. **Idempotency:** background/foreground and repeated terminal screens must not duplicate one-shots or orphan emitters. **Mobile/perf:** record FPS/frame-time spikes, memory, heat/battery and peak particles/nodes. **Automated:** device smoke log plus focused call-count diagnostics. **Godot AI:** runtime visual/device evidence where the tool can observe the running build; otherwise retain direct device captures alongside Godot AI desktop validation. **Regression/gate:** M47-001..014 remain green; independent performance audit.

### M48 — iOS Readiness

- [ ] SB-M48-001 Avoid Android-only gameplay architecture.
- [ ] SB-M48-002 Document Apple toolchain requirement.
- [ ] SB-M48-003 Prepare iOS configuration when hardware exists.
- [ ] SB-M48-004 Real-device iOS testing later.

### M49 — Responsive UI

- [ ] SB-M49-001 16:9 portrait.
- [ ] SB-M49-002 19.5:9.
- [ ] SB-M49-003 20:9.
- [ ] SB-M49-004 Tall phone.
- [ ] SB-M49-005 Tablet.
- [ ] SB-M49-006 Notch/cutout.
- [ ] SB-M49-007 Five slots stay usable.
- [ ] SB-M49-008 Board stays visible.
- [ ] SB-M49-009 Rectangular boards remain correctly scaled.
- [ ] SB-M49-010 Touch mapping remains accurate.
- [ ] SB-M49-011 Adopt 1080×2160 reference design viewport and stretch policy.
- [ ] SB-M49-012 Implement reusable SafeAreaRoot.
- [ ] SB-M49-013 Implement centralized UI tokens.
- [ ] SB-M49-014 Implement COMPACT/NORMAL/TALL classification.
- [ ] SB-M49-015 Validate 1080×2160.
- [ ] SB-M49-016 Validate 1170×2532.
- [ ] SB-M49-017 Validate 1290×2796.
- [ ] SB-M49-018 Validate 1080×2400.
- [ ] SB-M49-019 Validate 1440×3200.
- [ ] SB-M49-020 Validate minimum touch target.
- [ ] SB-M49-021 Confirm popups fit safe area.
- [ ] SB-M49-022 Confirm text containers survive localization expansion.
- [ ] SB-M49-023 Confirm top-right Pause + 2x controls, five fixed connector rails, slots, Batch Supply and booster row remain usable on compact devices.
- [ ] SB-M49-024 Add automated/manual responsive validation evidence.
- [ ] SB-M49-025 Validate temporary sixth-slot (+1 booster) layout/touch/readability across the full viewport matrix.

#### M49 Player-Experience Responsive Expansion
- [ ] SB-M49-026 Validate every M43/M44 screen/popup in the complete Player-Facing Surface Visual Inventory across the full viewport matrix.
- [ ] SB-M49-027 Validate long prices, timers, event/rank labels, card/robot names and reward bundles without clipping.
- [ ] SB-M49-028 Validate modal stacks, keyboard/back navigation and scrollable Collection/Shop/Events/Robots screens on compact and tall devices.
- [ ] SB-M49-029 Validate rewarded-ad/store return transitions and platform overlays do not corrupt safe-area layout.
- [ ] SB-M49-030 Validate notification deep links and account/cloud conflict screens enter a safe responsive destination.
- [ ] SB-M49-031 Validate Next Cleanup preview, 10-node journey, ScrubBox, Weekly/First-Try tracks and Comeback Catch-Up across the full viewport/safe-area matrix without shrinking primary gameplay/results CTAs below touch standards.
- [ ] SB-M49-032 Ensure 10-node journey and event tracks degrade gracefully on compact devices through scrolling/compression rules without turning them into a shipping level-select grid.

### M50 — Accessibility

- [ ] SB-M50-001 Review color-only information.
- [ ] SB-M50-002 Alternative visual slot cues if necessary.
- [ ] SB-M50-003 Color vision tests.
- [ ] SB-M50-004 Contrast.
- [ ] SB-M50-005 Reduced effects.
- [ ] SB-M50-006 Touch sizes.
- [ ] SB-M50-007 Text readability.
- [ ] SB-M50-008 Do not encode important state solely in decorative art.
- [ ] SB-M50-009 Keep labels/counts live and contrast-independent from illustration.
- [ ] SB-M50-010 Ensure generated icon families distinguishable at mobile size.
- [ ] SB-M50-011 Ensure essential gameplay understandable without decoration.

#### M50 Player-Experience Accessibility Expansion
- [ ] SB-M50-012 All M43/M44 screens support readable text scale, contrast, focus order and non-color-only state cues.
- [ ] SB-M50-013 Reward/pack/unlock ceremonies have Reduced Effects alternatives without hiding reward truth.
- [ ] SB-M50-014 Video/ad acquisition has an accessible non-video paid/earned path where product policy permits and never traps navigation.
- [ ] SB-M50-015 Event/rank/card rarity/robot-lock states have icon/text cues in addition to color.
- [ ] SB-M50-016 Screen-reader/accessibility-label strategy is defined for interactive controls before release.
- [ ] SB-M50-017 Retention surfaces must expose progress/state in text/icon form as well as animation/color; mystery reveal, pity guarantee, event reset and catch-up eligibility must remain understandable under Reduced Effects and assistive presentation.

- [ ] **SB-M50-018 — Plugin-specific motion/flash accessibility audit.** Purpose: verify GameFeelFlow/Spark never make reward/gameplay truth depend on motion and Reduced Effects is materially calmer. **Seam:** M43-C005F FULL/REDUCED matrix + canonical EffectsSettingsService. **Plugin:** both. **Native/existing remains:** text/icons/layout and current accessibility rules. **Reduced Effects:** no confetti/looping bounce/flash/camera effects; static final state appears immediately. **Idempotency:** accessibility toggle/reopen cannot replay one-shots. **Mobile/perf:** Reduced must show measurable animation/particle reduction. **Automated:** state/readability equality and no hidden-content tests. **Godot AI:** side-by-side FULL/REDUCED visual review, including rapid sequence checks for flashing. **Regression/gate:** M50-005/012/013/017; accessibility audit + owner gate if any effect is borderline.

### M51 — Localization Readiness

- [ ] SB-M51-001 Avoid hard-coded user text.
- [ ] SB-M51-002 Translation-key convention.
- [ ] SB-M51-003 Longer-string layouts.
- [ ] SB-M51-004 Pseudo-localization.
- [ ] SB-M51-005 Actual languages decided later. `[DESIGN GATE]`

#### M51 Player-Experience Localization Expansion
- [ ] SB-M51-006 Localize every M43/M44 surface including popup titles, booster descriptions, shop products, errors, notifications, event/rank labels and achievement copy.
- [ ] SB-M51-007 Prices supplied by platform stores remain platform-localized and are never hand-formatted as fixed currency strings.
- [ ] SB-M51-008 Validate pluralization for Hearts, Bot Parts, cards, days, attempts, ranks and time remaining.
- [ ] SB-M51-009 Pseudo-localize the complete Player-Facing Surface Visual Inventory before final visual closure.
### M52 — Production Content Scale-Up `[CONTENT]`

M52-C001 independent audit: **AUDITED_PASS / 10 OF 10 PRODUCTION ADMITTED / OWNER_PLAYTEST_REQUIRED**.
- Audit: `coordination/sessions/M52-C001/CHATGPT_AUDIT_V01.md`
- Final matrix: `coordination/sessions/M52-C001/evidence/FIRST10_FINAL_MATRIX_V01.md`
- Owner playtest: `coordination/sessions/M52-C001/OWNER_PLAYTEST_CHECKLIST_V01.md`
- Scope note: canonical real-level Challenge / Session Load / Frustration evidence is an explicit M53 carry-forward under the newer owner decision; it was not fabricated in M52-C001.
- `SB-M52-005` remains broader M52 work: the owner-selected First 10 pack contains no rectangular production source, so this row is not falsely closed by C001.

- [x] SB-M52-001 Import first Easy art.
- [x] SB-M52-002 Import first Medium art.
- [x] SB-M52-003 Import first Hard art.
- [x] SB-M52-004 Import first Very Hard art.
- [ ] SB-M52-005 Validate rectangular production art.
- [x] SB-M52-006 Batch convert.
- [x] SB-M52-007 Batch validate.
- [x] SB-M52-008 Generate previews.
- [x] SB-M52-009 Populate catalog.
- [x] SB-M52-010 Verify every source image preserved.
- [x] SB-M52-011 Verify generated level reproduces source.

#### M52-C001 Owner Playtest Gate

Status: **PAUSED / NOT PASS at Level 2 pending R01 runtime remediation.**
Owner findings: `coordination/sessions/M52-C001/OWNER_PLAYTEST_FINDINGS_V01.md`.

- [x] SB-M52-C001-O01 Owner plays Levels 2–10 through the real Home/AppState production path and accepts correct artwork/order, supply behavior, intended sequence legality and WON completion.
- [x] SB-M52-C001-O02 Owner confirms progression transitions 2→3→...→10 correctly with no Hazard Bot/wrong-level fallback.
- [x] SB-M52-C001-O03 Owner confirms Level 10 completion advances to frontier 11 and Home honestly shows disabled Level 11 / coming-soon content rather than replaying existing content.

#### M52-C001-R01 Parallel Runtime Remediation

- [x] SB-M52-R01-001 Replace production same-color oldest-batch monopolization with independent per-slot claim lanes.
- [x] SB-M52-R01-002 Implement deterministic dispatch waves: max one new Scrubby per eligible slot per cadence, up to 5 baseline / 6 boosted.
- [x] SB-M52-R01-003 Prove five 30-count same-color batches launch five concurrent agents in the first eligible wave.
- [x] SB-M52-R01-004 Make waiting lane-specific so one blocked same-color slot does not block siblings.
- [x] SB-M52-R01-005 Preserve exact target/reservation/route/no-ghost identity under parallel assignments.
- [x] SB-M52-R01-006 Preserve authoritative M24 remaining-on-clear accounting while player count decrements at successful departure/commit.
- [x] SB-M52-R01-007 Add departure-time and rollback counter tests.
- [x] SB-M52-R01-008 Replace silent no-entitlement 2x press with functional 2x acquisition flow using canonical products/prices.
- [x] SB-M52-R01-009 Successful 2x purchase activates immediately; cancel/fail/insufficient funds are no-spend/no-speed-change.
- [x] SB-M52-R01-010 Preserve free supply-exhausted automatic 2x.
- [x] SB-M52-R01-011 Profile owner-observed Level 2 micro-stutter and identify the dominant main-thread cause.
- [x] SB-M52-R01-012 Remove the stutter cause without disabling terminal/deadlock/routing correctness.
- [x] SB-M52-R01-013 Review/update M27 ProofKernel/solver equivalence for slot-parallel dispatch.
- [x] SB-M52-R01-014 Re-prove/replay Levels 1–10 and re-run Levels 2–10 through production runtime.
- [x] SB-M52-R01-015 Full focused + historical + root regression and diff hygiene pass.
- [x] SB-M52-R01-016 Independent ChatGPT audit required.
- [x] SB-M52-R01-017 Owner replay of Levels 2–10 required after audit before M53. — PASS except R02 early-slot-release spot-check remains.

#### M52-C001-R02 Dispatch-Exhausted Physical Slot Release

- [x] SB-M52-R02-001 Separate physical slot occupancy from retired/draining in-flight batch accounting.
- [x] SB-M52-R02-002 Release the physical slot only after the final zero-capacity work unit has successfully established a real dispatched agent.
- [x] SB-M52-R02-003 Make the released slot immediately reusable through normal rightmost-empty placement.
- [x] SB-M52-R02-004 Bind old in-flight work to immutable batch identity so a reused physical slot cannot receive old clears.
- [x] SB-M52-R02-005 Prove Batch A can retire, Batch B reuse the same slot, then A clear without mutating/freeing B.
- [x] SB-M52-R02-006 Preserve exact rollback/pre-spawn failure behavior: failed dispatch never releases the slot.
- [x] SB-M52-R02-007 Preserve Retry/reset with active + draining batches and zero ghosts.
- [x] SB-M52-R02-008 Preserve Tornado transactional behavior with draining selected-color work.
- [x] SB-M52-R02-009 Prevent stale frame-budgeted wave lanes from acting on a replacement batch in a reused slot.
- [x] SB-M52-R02-010 Make UI show EMPTY immediately on the same departure/retirement sync, with no zero-count linger.
- [x] SB-M52-R02-011 Preserve completion cardinalities and prevent early WON.
- [x] SB-M52-R02-012 Review/document M27 proof consistency under early physical-slot reuse.
- [x] SB-M52-R02-013 Re-run First 10 proof/replay/production runtime.
- [x] SB-M52-R02-014 Run R02 + R01 + historical + root regression and diff hygiene.
- [x] SB-M52-R02-015 Independent ChatGPT audit.
- [x] SB-M52-R02-016 Owner zero-count slot-reuse spot-check; on PASS close M52 owner replay and advance to M53.

**M52-C001 FINAL OWNER PASS [2026-09-27]:** `coordination/sessions/M52-C001/FINAL_OWNER_ACCEPTANCE_V01.md`. First 10 production gameplay/content integration, R01 parallel-runtime remediation, R02 early-slot-release remediation and owner replay/spot-check are closed. The sequencing lock now proceeds to M53 then applicable M54 before returning to M43.

### M53 — Level QA `[QA]`

Every production level:
- [x] SB-M53-001 Legal dimensions/envelope.
- [x] SB-M53-002 Correct Difficulty V1 metadata/score context.
- [x] SB-M53-003 Valid locked C01..C16 palette and current 3–12 used-color envelope; old class-specific color bands are not difficulty truth.
- [x] SB-M53-004 Correct cell count.
- [x] SB-M53-005 No invalid palette IDs.
- [x] SB-M53-006 Recognizable ACTIVE source artwork.
- [x] SB-M53-007 No unintended interpolation.
- [x] SB-M53-008 Correct CLEARED transparency.
- [x] SB-M53-009 Solvable under canonical routing/access semantics, including Railroad V1 where applicable.
- [x] SB-M53-010 No routing pathology; fully enclosed matching ACTIVE target remains untargetable until a legal Railroad ingress plus OPEN/CLEARED orthogonal interior path exists.
- [x] SB-M53-011 Good performance.
- [x] SB-M53-012 Correct preview.
- [x] SB-M53-013 Unique ID.

#### M53-C001 First 10 Level QA + Difficulty V1

- [x] SB-M53-C001-001 Implement/version a canonical deterministic real-level Difficulty V1 analyzer if one does not yet exist.
- [x] SB-M53-C001-002 Compute raw + normalized W/C/A/U/B/R/S evidence for each production Level 1–10 using production semantics.
- [x] SB-M53-C001-003 Compute exact Challenge Score D, TargetChallenge and delta for Levels 1–10; never force-label an out-of-window level.
- [x] SB-M53-C001-004 Produce versioned Stage-A Session Load evidence and explicit normalization provenance.
- [x] SB-M53-C001-005 Produce honest Frustration Risk evidence; mark unsupported/human-policy components provisional rather than fabricating values.
- [x] SB-M53-C001-006 Verify every M53 static QA gate for each Level 1–10 with machine-readable provenance.
- [x] SB-M53-C001-007 Check actual recovery cadence L3→4, L5→6, L8→9 and Level 10 boss relationship using analyzed scores.
- [x] SB-M53-C001-008 Produce measurable novelty/profile evidence without inventing missing taxonomy.
- [x] SB-M53-C001-009 Preserve owner source art, owner supply plans, Level 1 history and R01/R02 gameplay behavior unchanged.
- [x] SB-M53-C001-010 Re-run First 10 canonical proof/replay and production runtime after analyzer work.
- [x] SB-M53-C001-011 Add focused analyzer/QA determinism/formula/schema tests.
- [x] SB-M53-C001-012 Run M53 + M52/R01/R02 + relevant progression + root regression and diff hygiene.
- [x] SB-M53-C001-013 Write First 10 M53 matrix/evidence/log and hand off for independent ChatGPT audit.
- [x] SB-M53-C001-014 Independent ChatGPT audit; only all-ten PASS may advance directly to M54, otherwise exact TUNING_REQUIRED remediation is opened.

**M53-C001 audit verdict:** `CHANGES_REQUIRED / DIFFICULTY CALIBRATION REQUIRED`.
Static content QA is accepted 10/10. The Stage-A D classifications are retained as diagnostics but are not yet authority for mutating production content.

#### M53-C002 Difficulty V1 Calibration / Policy Robustness

- [x] SB-M53-C002-001 Build an independent QA-only calibration corpus covering controlled W/C/A/U/B/R/S changes.
- [x] SB-M53-C002-002 Define expected ordinal relationships for calibration pairs without assigning arbitrary production class labels.
- [x] SB-M53-C002-003 Remove arbitrary oracle-trace dependence from primary B/S/A scoring.
- [x] SB-M53-C002-004 Implement a deterministic non-adversarial reference-policy family and robust primary aggregate; keep stress policy separate.
- [x] SB-M53-C002-005 Derive/version candidate normalization anchors from the independent corpus/envelope, never from First 10 target fitting.
- [x] SB-M53-C002-006 Create versioned V2-candidate analyzer/config without overwriting V1 evidence.
- [x] SB-M53-C002-007 Prove candidate determinism, bounded metrics and solver-search-order robustness.
- [x] SB-M53-C002-008 Prove board size alone and color count alone do not dictate class-like Challenge behavior.
- [x] SB-M53-C002-009 Prove controlled route/access/unlock/bottleneck/slot-pressure pairs move intended axes in the expected direction.
- [x] SB-M53-C002-010 Freeze candidate calibration before scoring First 10 as a holdout.
- [x] SB-M53-C002-011 Produce First 10 V1-vs-V2 candidate matrix, policy spread and recovery evidence with no post-hoc retuning.
- [x] SB-M53-C002-012 Produce owner difficulty/fairness/engagement rating sheet with no fabricated responses.
- [x] SB-M53-C002-013 Run focused + M53-C001 + M52/R01/R02 + historical + root regression; no production gameplay changes.
- [x] SB-M53-C002-014 Write evidence/log and hand off for independent ChatGPT audit.
- [x] SB-M53-C002-015 Independent ChatGPT audit; on PASS request owner calibration review before adopting any new production difficulty authority.

**M53-C002 audit verdict:** `AUDITED_PASS / OWNER DIFFICULTY CALIBRATION REVIEW REQUIRED`.
V2 remains `CANDIDATE_NOT_PRODUCTION_AUTHORITY`; no production content/target/model adoption is authorized yet.

#### M53-C002 Owner Calibration Review

- [x] SB-M53-C002-O01 Owner rates perceived difficulty 1..7 for Levels 1–10 under consistent 1x/no-booster conditions.
- [x] SB-M53-C002-O02 Owner rates fairness and engagement 1..7 and class feel for Levels 1–10.
- [x] SB-M53-C002-O03 Owner evaluates recovery cadence L3→4, L5→6, L8→9 and whether L10 feels like the cycle boss.
- [x] SB-M53-C002-O04 Owner explicitly reviews L1 neutral-policy deadlock/fairness and L7 relative difficulty/robustness concern.
- [x] SB-M53-C002-O05 ChatGPT compares owner Stage-B ratings with V2/V1/targets and opens the exact adoption, calibration-refinement or content-tuning next task.

**Owner Stage-B evidence:** `coordination/sessions/M53-C002/OWNER_DIFFICULTY_RATINGS_V01.md`
**ChatGPT reconciliation:** `coordination/sessions/M53-C002/CHATGPT_STAGE_B_RECONCILIATION_V01.md`

#### M53-C002-R01 Stale Calibration Corpus Determinism — QUEUED MAINTENANCE

- [x] **SB-M53-C002-R01-001 — Remove platform-dependent calibration-evidence serialization and re-freeze V2 candidate QA artifacts without semantic drift. PASS / CLOSED [2026-10-07].** Implementation `f77f087a928eca5ed76c42c20639a7231c657b1c` adds one QA-only full-precision canonical serializer, regenerates corpus/frozen-config/holdout evidence through the existing workflow, preserves all fixture/supply identities and all ordinal/family/robustness/First Ten/recovery/L10/owner-facing decisions, and restores the exact fresh==committed determinism assertion on Linux/cloud. Golden serializer suite 30/30 PASS; root 5,329 ALL PASS. Strict audit: `coordination/sessions/M53-C002/CHATGPT_R02_STRICT_REAUDIT_V01.md`. Integrated through PR #9; production Difficulty V2 remains deferred/not authority.

#### M53-C003 V2.1 Stage-B Difficulty Calibration Refinement — DEFERRED BY OWNER

Owner decision 2026-09-27: do not run C003 now. Difficulty-score recalibration, final class criteria review, automatic solution generation and batch/color-choice solution optimization are intentionally deferred until the broader game systems are built.

The former C003 prompt is retained only as a superseded artifact:
`coordination/sessions/M53-C003/task_prompts/SB-M53-C003_V21_STAGE_B_CALIBRATION.md`

No open C003 checklist rows remain in the active tracker. This is a scope deferral, not a claim that the proposed V2.1 work was completed.

**M53 First 10 closure:** static QA 10/10 PASS, owner playtest/acceptance 10/10 PASS, current difficulty-model work deferred by owner. Proceed to applicable M54 current-build regression.

### M54 — Regression Suite `[QA]`

**M54-C001 First 10 gate: CLOSED.** SB-M54-001..021 + 016A are 22/22 AUDITED_PASS after owner ruling A = 900 s / 15 min. Final closure: `coordination/sessions/M54-C001/CHATGPT_AUDIT_V02.md`. SB-M54-022..032 remain later M43+ regression work.

- [x] SB-M54-001 Difficulty/progression tests.
- [x] SB-M54-002 Level parser tests.
- [x] SB-M54-003 BoardState tests.
- [x] SB-M54-004 Renderer tests.
- [x] SB-M54-005 Slot tests.
- [x] SB-M54-006 Color-candidate/reachability tests.
- [x] SB-M54-007 Reservation tests.
- [x] SB-M54-008 TargetSelector tests.
- [x] SB-M54-009 Routing tests including Railroad V1 geometry, connectors, legal ingresses and post-rail orthogonal interior turns.
- [x] SB-M54-010 Dispatcher tests.
- [x] SB-M54-011 Completion tests.
- [x] SB-M54-012 Save tests.
- [x] SB-M54-013 Reward tests.
- [x] SB-M54-014 Content validation tests.
- [x] SB-M54-015 59×59 regression test.
- [x] SB-M54-016 Economy Wallet/Gift Meter/Daily/Cards Exchange/Collection-completion idempotency regression.
- [x] SB-M54-016A Test every set-specific 9/9 reward plus all-15 Master Collection +2500 SB/+20 Bot Parts exactly-once grant.
- [x] SB-M54-017 Heart **900-second / 15-minute** offline/background/menu regen and clock-rollback regression. [OWNER ruling A; `OWNER_HEART_REGEN_INTERVAL_V01.md`; M54-C001 V02 CLOSED]
- [x] SB-M54-018 2x level/timed entitlement wall-clock expiry + free M23-exhausted auto-2x regression.
- [x] SB-M54-019 +1 Slot 5/6-capacity runtime + solver regression.
- [x] SB-M54-020 Random/Selector solver-safety and no-consume-on-failure regression.
- [x] SB-M54-021 Tornado cross-engine conservation/rollback/no-ghost regression.

#### M54 Player-Experience / Meta Regression Expansion
- [ ] SB-M54-022 Results/fail/retry/Need-a-Hand third-failure regression.
- [ ] SB-M54-023 Heart/SB/booster/2x popup spend-grant-idempotency regression.
- [ ] SB-M54-024 Rewarded-ad callback success/cancel/fail/duplicate/background regression with provider mocked.
- [ ] SB-M54-025 Shop return-context and insufficient-SB regression.
- [ ] SB-M54-026 Card pack opening, duplicate/new card, Collection completion and Master Collection ceremony regression.
- [ ] SB-M54-027 Robot unlock/equip/perk persistence regression.
- [ ] SB-M54-028 Tasks/Daily/Gift Bar/notification-badge regression.
- [ ] SB-M54-029 BottomNav Events/Robots/Home/Ranks/Settings transition and modal-stack regression.
- [ ] SB-M54-030 Feature-unlock/FTUE migration and once-only coachmark regression.
- [ ] SB-M54-031 Cloud/account sync/conflict/restore regression once provider exists.
- [ ] SB-M54-032 World registry/unlock/transition regression once future world ranges are owner-defined.
- [ ] SB-M54-033 Next Cleanup / 10-Level Journey regression: exact next-content resolution, frontier fallback, no duplicate transition, cycle-boundary correctness and no level-select leakage.
- [ ] SB-M54-034 Collection retention regression: pity increment/reset/guarantee, complete-pool fallback, save/cloud continuity and First Collection Sprint reward-source idempotency.
- [ ] SB-M54-035 Daily/Event retention regression: deterministic three Scrub Orders, ScrubBox exactly-once, Weekly Event anti-replay-farm, First-Try reset semantics and Personal Best persistence.
- [ ] SB-M54-036 Comeback/notification regression: absence qualification, catch-up no-Daily-rule mutation, rollback safety, notification priority/dedup, quiet hours and proactive 24-hour cap.

- [ ] **SB-M54-037 — Presentation-plugin one-shot/fail-open regression.** Purpose: lock the core safety contract. **Seam:** Results `show_model()`/attempt key, reward rows, BasePopup ceremonies/acquisitions, terminal→Results bridge and feedback adapter. **Plugin:** both. **Native/existing remains:** all grants/navigation/save/gameplay truth. **Reduced Effects:** run same matrix in FULL/REDUCED. **Idempotency:** same Results attempt refresh, popup refresh/reopen, duplicate provider callbacks and duplicate terminal signals produce at most one eligible presentation event. **Mobile/perf:** bounded event count, no lingering nodes. **Automated:** plugin missing/disabled/throwing stubs still preserve exact authoritative outcomes. **Godot AI:** smoke real Results/pack/robot flows after automated suite. **Regression/gate:** M54-022..036 plus root suite; independent audit.
- [ ] **SB-M54-038 — GameFeelFlow/Spark runtime visual regression pack.** Purpose: make visual runtime checking reproducible rather than relying on code inspection. **Seam:** M43-C005F representative scenes/evidence harnesses using real shipping nodes/models. **Plugin:** both. **Native/existing remains:** approved art/layout. **Reduced Effects:** capture FULL, REDUCED and plugin-disabled fallback. **Idempotency:** evidence harness must not itself trigger duplicate grants/events. **Mobile/perf:** fixed bounded duration and effect budget. **Automated:** asserts final visual state restoration after effects and no orphan tweens/emitters. **Godot AI:** mandatory inspect/capture of the runtime pack for every future plugin-effect change. **Regression/gate:** visual diff/sanity + independent audit; owner gate only when visible behavior intentionally changes.

### M55 — Chaos / Long-Run QA `[QA]`

**M55 current-build core: CLOSED.** SB-M55-001..017 AUDITED_PASS in C001; timed-2x anti-rollback remediation C002 AUDITED_PASS at `023a0fc`. Audits: `coordination/sessions/M55-C001/CHATGPT_AUDIT_V01.md`, `coordination/sessions/M55-C002/CHATGPT_AUDIT_V01.md`. SB-M55-018..024 remain deferred until their M43+ surfaces exist.

- [x] SB-M55-001 Spam all five slots.
- [x] SB-M55-002 Restart while bots travel.
- [x] SB-M55-003 Pause while bots travel.
- [x] SB-M55-004 Background while bots travel.
- [x] SB-M55-005 Complete with bots in flight.
- [x] SB-M55-006 Exhaust color.
- [x] SB-M55-007 Exhaust slot work.
- [x] SB-M55-008 Repeated scene transitions.
- [x] SB-M55-009 Long high-load session.
- [x] SB-M55-010 Memory growth monitoring.
- [x] SB-M55-011 Duplicate signal monitoring.
- [x] SB-M55-012 Orphan Node monitoring.
- [x] SB-M55-013 Duplicate reward monitoring.
- [x] SB-M55-014 Spam booster use/purchase/charge buttons; prove no double spend/use.
- [x] SB-M55-015 Background/foreground across Heart regen and timed 2x expiry.
- [x] SB-M55-016 Tornado while matching-color agents are in flight; prove atomic reconciliation.
- [x] SB-M55-017 Cards Exchange-all under repeated taps; prove protected first copies and no duplicate SB grant.

#### M55-C002 Timed 2x Anti-Rollback Remediation

- [x] SB-M55-C002-001 Add persistent non-decreasing effective/high-water wall-clock authority for timed 2x.
- [x] SB-M55-C002-002 Ensure remaining timed-2x seconds cannot increase and an expired entitlement cannot revive after backward clock movement.
- [x] SB-M55-C002-003 Preserve normal forward expiry, current-level 2x and free M23 auto-2x semantics.
- [x] SB-M55-C002-004 Add backward-compatible legacy snapshot migration without wiping legitimately active legacy timed entitlements.
- [x] SB-M55-C002-005 Persist/strictly validate the new anti-rollback state across save/relaunch; malformed present values fail closed.
- [x] SB-M55-C002-006 Prove explicit new timed purchase can extend from the canonical effective base and charges exactly once.
- [x] SB-M55-C002-007 Add focused rollback/migration/persistence sensitivity regression plus relevant M39/M40/M55/root regressions.
- [x] SB-M55-C002-008 Write evidence/log and hand off for independent ChatGPT audit.

#### M55 Player-Experience Chaos Expansion
- [ ] SB-M55-018 Spam open/close/purchase/reward buttons across every popup without double transition/spend/grant.
- [ ] SB-M55-019 Background/foreground during rewarded ad, store purchase, pack reveal, robot unlock and cloud sync.
- [ ] SB-M55-020 Lose three times rapidly with restart/exit mixtures and prove Need a Hand trigger remains correct.
- [ ] SB-M55-021 Repeatedly switch BottomNav destinations while badges/rewards update; prove no orphan UI/signals.
- [ ] SB-M55-022 Open huge duplicate-card inventories and Collection lists repeatedly; monitor memory growth.
- [ ] SB-M55-023 Expire Events/timed 2x/Heart timers while relevant screens are open and prove safe refresh.
- [ ] SB-M55-024 Simulate offline/online flapping during Shop/Events/Ranks/cloud/rewarded-ad surfaces without data corruption.
- [ ] **SB-M55-025 — Presentation-plugin chaos/leak test.** Purpose: stress effect cancellation and lifecycle under hostile UI/gameplay churn. **Seam:** ModalStack, Results/Home route changes, retry, background/foreground, pack/robot ceremonies, CleaningFxLayer and feedback adapter cleanup. **Plugin:** both. **Native/existing remains:** all M55 authority/lifecycle behavior. **Reduced Effects:** toggle repeatedly mid-effect and verify deterministic cleanup/no replay. **Idempotency:** rapid taps/refresh/route churn cannot multiply one-shot celebrations. **Mobile/perf:** monitor orphan Nodes, tweens, Spark emitters, memory growth and signal duplication through long sessions. **Automated:** chaos loop with adapter diagnostics and zero-authority-mutation assertions. **Godot AI:** visually inspect representative long-run route churn. **Regression/gate:** M55-018..024 plus core long-run checks; independent chaos audit.

### M56 - Analytics / Retention Calibration [DESIGN GATE -> REQUIRED BEFORE PRODUCTION TUNING]

No analytics SDK without owner approval. Event contracts may be designed and locally tested before choosing a provider. Analytics must support product calibration, not covert profiling.

- [ ] SB-M56-001 Define privacy-minimized analytics event taxonomy and version it.
- [ ] SB-M56-002 Session events: app/session start/end, foreground/background, session duration bucket.
- [ ] SB-M56-003 Level funnel: level start, first action, win/fail/exit/restart, attempt number, duration, failure progress bucket and difficulty/session-load metadata version.
- [ ] SB-M56-004 Retention calibration: first-attempt clear, attempts-to-clear, retry latency, abandonment after level and recovery-level performance.
- [ ] SB-M56-005 Assistance: Need a Hand shown/declined, recommended booster IDs, acquisition path and later clear outcome.
- [ ] SB-M56-006 Booster: charge/SB/rewarded acquisition path, activation success/fail-closed reason and level context without raw board/player-identifying data.
- [ ] SB-M56-007 Economy: aggregate SB source/sink categories, Heart starvation/refill, 2x product use, Cards Exchange and Gift/Daily reward categories.
- [ ] SB-M56-008 Collection/robots: pack opened, new-vs-duplicate counts, set completion, Master Collection, robot unlock/equip.
- [ ] SB-M56-009 Navigation: Home shortcut/BottomNav destination open, Shop entry reason and major screen completion/error states.
- [ ] SB-M56-010 Ads/store: offer, request, show, complete, skip/cancel, fail and verified reward/purchase fulfillment using provider-safe transaction identifiers.
- [ ] SB-M56-011 Events/Ranks: participation, completion/claim and rank-window engagement once their owner rules exist.
- [ ] SB-M56-012 Notifications: permission state/category opt-in, send/open/deep-link result only after privacy/platform review.
- [ ] SB-M56-013 Define dashboard metrics for D1/D7/D30 retention, level drop-off, fail-progress distribution, help conversion, booster reliance, Heart starvation and session length.
- [ ] SB-M56-014 Analytics events never grant rewards, alter difficulty, change solver truth or become a required dependency for offline gameplay.
- [ ] SB-M56-015 Define consent/age/privacy gating with M58 before production provider activation.
- [ ] SB-M56-016 Add analytics schema tests, duplicate-event guards where important and provider-offline fail-safe behavior.

#### M56 Retention V2 Measurement Additions

- [ ] SB-M56-017 Measure Next Cleanup teaser impression → CLEAN NEXT tap → next-level-start conversion, with frontier/unavailable states separated from player choice.
- [ ] SB-M56-018 Measure 10-Level Cleaning Journey progression/drop-off by cadence slot 1..10 and cycle completion without using the metric to dynamically manipulate difficulty per individual player.
- [ ] SB-M56-019 Measure Collection new-card rate, duplicate streak length, pity-trigger frequency, guarantee fulfillment and Set-1 completion level distribution; use results to tune fairness, not to sell random outcomes.
- [ ] SB-M56-020 Measure Daily Scrub Order archetype completion/time-to-complete, 3/3 completion and ScrubBox claim; reject task archetypes that create disproportionate grind or Heart waste.
- [ ] SB-M56-021 Measure Weekly Event participation/milestone completion and First-Try run depth/reset frequency separately from core campaign retention.
- [ ] SB-M56-022 Measure Comeback Catch-Up offer → return-session → three-win completion → subsequent D1/D7 return, while preserving the current Daily streak rules as a separate metric.
- [ ] SB-M56-023 Measure notification eligible/suppressed/sent/opened/deep-link outcomes with category and dedup reason; do not optimize by increasing push frequency beyond the owner cap or by using guilt/urgency copy.

### M57 - Monetization / Rewarded Ads / Store Products [OWNER-LOCKED SCOPE, IMPLEMENTATION GATED BY PROVIDER DECISION]

Economy V1 soft-currency/Hearts/booster/2x rules are already owner-locked. The owner has additionally required rewarded-video acquisition surfaces for Hearts and boosters. Provider choice, cash prices, ad frequency/cooldowns and regional availability remain tuning/provider decisions and must be data-driven.

- [ ] SB-M57-001 Choose/approve rewarded-ad and IAP provider/platform architecture; no SDK before owner approval.
- [ ] SB-M57-002 Define rewarded-ad placement IDs separately for Heart +1, booster acquisition and any later approved placement.
- [ ] SB-M57-003 Rewarded Heart path grants exactly +1 Heart after a verified completed reward callback only.
- [ ] SB-M57-004 Rewarded +1 Slot path grants exactly one canonical charge/use entitlement after verified completion.
- [ ] SB-M57-005 Rewarded Random path grants exactly one canonical charge/use entitlement after verified completion.
- [ ] SB-M57-006 Rewarded Selector path grants exactly one canonical charge/use entitlement after verified completion.
- [ ] SB-M57-007 Rewarded Tornado path grants exactly one canonical charge/use entitlement after verified completion.
- [ ] SB-M57-008 Need a Hand recommendations reuse the same rewarded acquisition authority; they do not create hidden extra reward rules.
- [ ] SB-M57-009 Configure per-placement availability/frequency/cooldown/cap server-side or versioned data after owner tuning; never bury hardcoded ad pressure inside popup code.
- [ ] SB-M57-010 Ad unavailable/loading/fail/skip states grant nothing and always leave a usable non-broken UI.
- [ ] SB-M57-011 App background/kill/relaunch during an ad cannot duplicate a reward.
- [ ] SB-M57-012 Define Scrub Bucks real-money packs, localized store product IDs and value ladder in an owner decision before publishing cash prices.
- [ ] SB-M57-013 Define No Ads product and exactly which ad surfaces it removes; rewarded ads requested voluntarily by the player must follow the owner-approved No Ads policy.
- [ ] SB-M57-014 Implement purchase request, pending, success, cancel, failure, restore and already-owned states.
- [ ] SB-M57-015 Fulfillment is idempotent by platform transaction/receipt identity and persists across relaunch.
- [ ] SB-M57-016 Restore purchases and account/cloud reconciliation cannot duplicate SB/entitlements.
- [ ] SB-M57-017 No paid random card pack/gacha is authorized without a new explicit owner decision and platform/compliance review.
- [ ] SB-M57-018 No second premium currency is authorized.
- [ ] SB-M57-019 Do not dynamically make levels harder because a player purchases, watches ads or refuses ads.
- [ ] SB-M57-020 Do not block basic navigation/Settings/Collection/Robots behind ads.
- [ ] SB-M57-021 All real-money and ad surfaces use the M43 visual/acquisition family and M50 accessibility rules.
- [ ] SB-M57-022 Test sandbox purchases/rewarded ads on real Android and later iOS devices before release.

### M58 - Privacy / Compliance / Consent

Once external services exist:
- [ ] SB-M58-001 Third-party inventory.
- [ ] SB-M58-002 Data inventory.
- [ ] SB-M58-003 Remove unnecessary collection.
- [ ] SB-M58-004 Privacy disclosures.
- [ ] SB-M58-005 Store declarations.
- [ ] SB-M58-006 Age-rating review.
- [ ] SB-M58-007 Child-directed considerations if applicable.
- [ ] SB-M58-008 Analytics consent/legal-basis strategy by region/provider.
- [ ] SB-M58-009 Personalized/non-personalized ad consent flow where required; gameplay remains usable when personalized consent is refused.
- [ ] SB-M58-010 Notification permission/settings and deep-link privacy review.
- [ ] SB-M58-011 Account/cloud data deletion/export/sign-out requirements and recovery policy.
- [ ] SB-M58-012 Leaderboard/profile display-name privacy, reporting/blocking needs and minors policy before Ranks/social exposure.
- [ ] SB-M58-013 Purchase receipt/transaction identifier retention policy and least-data principle.
- [ ] SB-M58-014 Verify all consent/error/privacy screens are localization-ready and accessible.

### M59 — Build Pipeline

- [ ] SB-M59-001 Debug export.
- [ ] SB-M59-002 Release export.
- [ ] SB-M59-003 Output directories.
- [ ] SB-M59-004 Versioning.
- [ ] SB-M59-005 Build numbers.
- [ ] SB-M59-006 Run tests before release build.
- [ ] SB-M59-007 Run content validator.
- [ ] SB-M59-008 Generate Android build.
- [ ] SB-M59-009 Verify clean clone can build.

- [ ] **SB-M59-010 — Third-party presentation-addon clean-clone/release hygiene.** Purpose: ensure GameFeelFlow + Saltmire Spark are reproducible, licensed and non-editor-dependent in shipping builds. **Seam:** canonical `addons/`, `project.godot`, clean clone, debug/release export and third-party notices. **Plugin:** both. **Native/existing remains:** build pipeline and game startup. **Reduced Effects:** startup with saved reduced=true must work before any visual call. **Idempotency:** exactly one `GameFeelFlow` and one `Spark` autoload, no duplicate plugin registration. **Mobile/perf:** exclude non-shipping examples/tests/demo/editor-only baggage where safe; retain required runtime/editor plugin files and MIT license/attribution; no GdUnit runtime dependency; no Pro/Impact paid dependency. **Automated:** clean clone import, headless parse, debug/release export, autoload smoke, license-file/notices check. **Godot AI:** open clean-clone project and run a short Results + Spark/GFF smoke. **Regression/gate:** SB-M59-006/009 + release build; independent build audit, no owner visual gate.

### M60 — Release

Application ID, icon, splash, portrait config, signing, release settings,
debug removal, store screenshots, final QA, tagged source commit, release
artifact validation. **Never commit signing secrets.**

Release readiness additionally requires:
- [ ] SB-M60-001 No dead Home shortcut, HUD `+`, BottomNav destination, gameplay booster, 2x control or required popup route.
- [ ] SB-M60-002 Required V1 M43 Player-Facing Surface Visual Inventory is owner-approved and production-bound.
- [ ] SB-M60-003 FTUE/feature-unlock path is playable from a fresh save without debug intervention.
- [ ] SB-M60-004 Shop/ad/IAP surfaces either function with approved providers or are cleanly feature-disabled with no broken navigation.
- [ ] SB-M60-005 Events/Ranks shipping policy is explicit; if enabled, live backend/content and privacy requirements are proven.
- [ ] SB-M60-006 Release build passes full M49-M58 player-experience, economy, device, compliance and regression gates.

### M61 - Friends / Social Comparison [POST-LAUNCH REQUIRED ROADMAP, NO CHAT/CLANS/BATTLE PASS BY DEFAULT]

This closes the previously identified social gap without expanding V1 into a chat/clan product. It is planned for a later release after account/privacy/ranks foundations are stable.

- [ ] SB-M61-001 Define owner-approved Friends scope and identity model.
- [ ] SB-M61-002 Friend add/invite/discovery policy with privacy-safe identifiers and no unsolicited contact exposure.
- [ ] SB-M61-003 Friends list with online-agnostic progress summary and active robot/avatar presentation.
- [ ] SB-M61-004 Optional friend progress/rank comparison using the same fair Ranks metric; no pay-to-win multiplier.
- [ ] SB-M61-005 Define whether lightweight friend gifts/challenges exist before implementing; do not invent transferable premium value.
- [ ] SB-M61-006 Block/report/remove-friend and minors/privacy rules before production.
- [ ] SB-M61-007 Produce/owner-approve Friends visual master if/when the feature enters implementation.
- [ ] SB-M61-008 No global chat, clan/guild system or battle pass is implied by this milestone; each would require a separate explicit owner decision.

---

## GENERATED ASSET LIFECYCLE / DEFINITION OF DONE

- [ ] SB-UI-022 Use image generation primarily for branded illustrative assets where it adds value.
- [ ] SB-UI-023 Prefer native Godot controls/styles for interactive/dynamic UI.
- [ ] SB-UI-024 Every generated asset has traceable manifest/provenance.
- [ ] SB-UI-025 Raw generation output is never automatically production-final.
- [ ] SB-UI-026 Owner approval required before production promotion for identity/major art.
- [ ] SB-UI-027 Approved assets must be imported/configured/bound before implementation task closes.
- [ ] SB-UI-028 Never silently regenerate/overwrite approved asset.
- [ ] SB-UI-029 Do not bake dynamic text/quantities/timers/prices/state into generated images.
- [ ] SB-UI-030 Keep single-Image/ImageTexture BoardRenderer; no per-cell UI nodes.
- [ ] SB-UI-031 Validate transparency/edges/resolution/filtering/compression/memory/readability.
- [ ] SB-UI-032 Use generation credits consciously; generate by milestone need.

---

## RISK REGISTER

| ID | Risk | Severity | Mitigation |
|---|---|---|---|
| RISK-001 | Routing works technically but looks boring/confusing | CRITICAL | Owner-locked Railroad V1 + replaceable RoutingSystem + owner F6 review |
| RISK-002 | Large number of Scrubbots causes frame drops | HIGH | 59×59 density stress tests and profiling |
| RISK-003 | Legacy difficulty assumptions survive as current truth | HIGH | Difficulty V1 migration + config/doc/regression checks |
| RISK-004 | Production difficulty metadata becomes inconsistent | HIGH | Versioned Difficulty V1 evaluator/calibration |
| RISK-005 | Generic small test fixtures break after production validation | MEDIUM/HIGH | TEST fixture path/context separate from production |
| RISK-006 | Existing artwork gets silently resized/altered | HIGH | Source preservation + explicit compiler/importer + round-trip comparison |
| RISK-007 | AI agent invents missing references | HIGH | Canonical reference library/manifest |
| RISK-008 | External reference game copied too closely | HIGH | Original SCRUBBOTS rail/art/UI language; external references conceptual only |
| RISK-009 | Target race assigns same pixel to multiple Scrubbots/batches | HIGH | ReservationState + Batch Target Claim Engine atomic uniqueness tests |
| RISK-010 | Renderer creates thousands of Nodes | HIGH | Batched renderer requirement |
| RISK-011 | Desktop testing hides mobile performance issues | HIGH | Real Android profiling |
| RISK-012 | Future agent breaks explicit preload/headless compatibility | MEDIUM/HIGH | ADR-009 + regression tests |
| RISK-013 | Target ordering appears wrong because exterior/interior HOW cannot legally reach intended target | HIGH | Railroad V1 legal ingress + orthogonal interior-turn routing + exact Hazard Bot regressions |
| RISK-014 | Hidden/debug input diverges from production supply-front selection and automatic slot placement | HIGH | Front-batch-only player activation; rightmost-empty auto-placement; no hidden keyboard dispatch |
| RISK-015 | Railroad visual and routing geometry drift apart | HIGH | One canonical ScrubRail geometry source consumed by routing, connector and presentation |
| RISK-016 | Generated batch supply is mathematically impossible to finish | CRITICAL | Solvability Engine proof before production acceptance |
| RISK-017 | Scheduler spawns a robot without unique target/reservation/valid route | CRITICAL | No-target/no-reservation/no-route/no-robot transactional invariant |
| RISK-018 | Temporary WAITING is misclassified as deadlock | HIGH | Solver-backed STALLED vs DEADLOCK classification + in-flight/future-progress guards |
| RISK-019 | Multiple same-color batches fight/starve or double-claim targets | HIGH | Oldest-placement-first same-color arbitration + atomic Batch Target Claim ledger |

---

## CRITICAL PATH

```text
FOUNDATION                         DONE
↓
VARIABLE LEVEL DATA                DONE
↓
BOARDSTATE                         DONE
↓
HEADLESS CORE TESTS                DONE
↓
ENGINE/CONTENT ENVELOPE
↓
BOARD RENDERER
↓
VISUAL REFERENCE INGESTION
↓
PIXEL ART IMPORT / SEMANTIC ART PIPELINES
↓
GAMEPLAY SESSION
↓
FIVE SLOTS
↓
COLOR CANDIDATES + REACHABILITY
↓
RESERVATION
↓
TARGETSELECTOR
↓
ROUTING + SCRUBBOT RAILROAD V1             DONE (M22 V07 + OWNER ACCEPTANCE)
↓
SCRUBBOT AGENT
↓
DISPATCHER
↓
COMPLETE CLEANING LOOP
↓
REAL SCRUBBOTS ART VERTICAL SLICE             DONE (M21)
↓
BATCH SUPPLY ENGINE                           NEXT (M23)
↓
FIVE-SLOT BATCH ENGINE                        M24
↓
BATCH TARGET CLAIM ENGINE                     M25
↓
AUTO DISPATCH SCHEDULER                       M26
↓
SOLVABILITY / DEADLOCK ENGINE                 M27
↓
PRODUCTION UI / TOUCH                         M28+
↓
WIN / PROGRESSION / SAVE
↓
MOBILE PERFORMANCE
↓
CONTENT SCALE-UP
↓
RELEASE QA
```

---

## FIRST TRUE PLAYABLE TARGET

M21 achieved the first real gameplay proof using the then-current adjacent exterior ring. The current productionization target now adds the owner-approved Railroad V1 movement language without changing M21's WHAT/reservation/clear invariants:

```text
ONE REAL OWNER-APPROVED SCRUBBOTS LEVEL IMAGE
+ FIVE EMPTY BATCH SLOTS
+ 3/4/5 FIFO BATCH-SUPPLY COLUMNS
+ V1 THREE VISIBLE ROWS; FRONT ROW ONLY SELECTABLE
+ AUTOMATIC RIGHTMOST-EMPTY SLOT PLACEMENT
+ COLOR/COUNT BATCH QUOTAS WITH WAITING/RESUME
+ SAME-COLOR OLDEST-BATCH-FIRST TARGET CLAIM ARBITRATION
+ FRONT-BATCH CLICK/TAP OWNER GAMEPLAY ACTIVATION; FIVE SLOTS AUTO-FILL
+ CORRECT COLOR CANDIDATES + REACHABLE TARGET SELECTION
+ BOTTOM-MOST / LEFT-MOST PRIORITY AMONG CURRENTLY TARGETABLE MATCHING CELLS
+ SCRUBBOT RAILROAD V1 AROUND ALL FOUR SIDES
+ 2-CELL ARTWORK CLEARANCE + 1-CELL RAIL WIDTH
+ VISIBLE SLOT -> BOTTOM-RAIL CONNECTOR
+ RAIL-ONLY EXTERIOR TRAVEL
+ LEGAL RAIL INGRESS INTO OPEN/CLEARED PERIMETER SPACE
+ ORTHOGONAL INTERIOR-CORRIDOR ROUTING WITH 90-DEGREE TURNS
+ NO TARGET / NO RESERVATION / NO VALID ROUTE = NO ROBOT
+ SOLVABILITY-PROVED SUPPLY + RUNTIME DEADLOCK CLASSIFICATION
+ VALID TARGET RESERVATION
+ PIXELS BEING CLEANED TO TRANSPARENCY
+ SCRUBBOTS DISAPPEARING AFTER CLEANING
+ A COMPLETE PLAYABLE LEVEL
```

---

## RECOMMENDED PROMPT SEQUENCE

Guidance, not a hard contract. Split any prompt if scope becomes too large.
Never combine two risky architecture systems merely to save prompt count.

```text
PROMPT 01  Project Foundation                                    [DONE]
PROMPT 02  Godot Installation + Variable LevelData + BoardState
           + Headless Tests                                      [DONE]
PROMPT 03  Official Difficulty Bands + TEST vs Production        [HISTORICAL COMPAT DONE]
PROMPT 04  BoardRenderer + Variable Aspect Board Rendering       [DONE]
PROMPT 05  Visual Reference Library                              [DONE/ONGOING ASSETS]
PROMPT 06  Pixel-Art Importer + Round Trip Validation            [DONE]
PROMPT 07  Gameplay Session Core + Five-Slot Data Model          [DONE]
PROMPT 08  Color Candidates + Reservation + TargetSelector       [DONE]
PROMPT 09  RoutingSystem + Production Routing                    [DONE; exterior geometry superseded by M22 Railroad V1]
PROMPT 10  ScrubbotAgent + Dispatcher                            [DONE]
PROMPT 11  Complete Clearing Vertical Slice                      [DONE]
PROMPT 12  First Real SCRUBBOTS Artwork Playable Level           [DONE — M21 V10]
PROMPT 13  Production Slot UI + Railroad V1                      [DONE — M22 V07 + owner acceptance]
PROMPT 14  Batch Supply Engine                                      [NEXT — M23]
PROMPT 15  Five-Slot Batch Engine                                   [M24]
PROMPT 16  Batch Target Claim Engine                                [M25]
PROMPT 17  Auto Dispatch Scheduler                                  [M26]
PROMPT 18  Solvability / Deadlock Engine                            [M27]
PROMPT 19  Gameplay Screen Layout + Mobile Touch                    [M28–M29]
PROMPT 20  Win/Lose Completion Rules + Results Flow
PROMPT 21  Scrubbot Final Art + Cleaning Effects + Audio/Haptics
PROMPT 22  Level Catalog + Difficulty V1 Content Rules
PROMPT 23  Progression + Win Streak + Save System
PROMPT 24  Home + Settings + Tutorial + Navigation
PROMPT 25  Android Device Performance + Full 59×59 Stress Tests
PROMPT 26  Production Content Scale-Up + Regression + Chaos QA
PROMPT 27  Release Candidate Preparation
```

---

## NEXT IMMEDIATE MILESTONE

**M23-C001 V01 — Batch Supply Engine.** The next implementation cycle builds the real color/count supply queues before any production-screen-layout work. V1 must support owner-locked FIFO columns, three visible rows for the Hazard Bot validation path, front-row-only selection, hidden future batches, deterministic/conserved candidate generation and transactional handoff to the future Five-Slot Batch Engine. It must not weaken or rewrite the accepted M22 Railroad V1/V07 routing, TargetSelector, ReservationState, dispatcher or authenticated-clearing contracts.

M23 is followed strictly by M24 Five-Slot Batch Engine, M25 Batch Target Claim Engine, M26 Auto Dispatch Scheduler and M27 Solvability / Deadlock Engine. The previous Gameplay Screen Layout milestone has moved to M28; production UI work must not jump ahead of these five core-gameplay milestones.

---

## REMOTE CONTENT RUNTIME V01 — ACTIVE STRICT AUDIT / R01

The CP04/M15 + CP05/M16 publisher-client requirements are canonically defined in the separate Content Platform program. Do not duplicate those 26 requirement rows here. This block records only **new game-side strict-audit remediation**.

- [x] **SB-CP05-R01-001 — Clean candidate-installed pack directories after failed multi-pack refresh. PASS / CLOSED [2026-10-07].** Staging-until-full-candidate-verification plus exact transaction-owned rollback closes the multi-pack leak; active/LKG/reused packs are preserved, failed registry transitions restore exact prior bytes, and six permanent adversarial cases PASS. Strict re-audit: `coordination/sessions/REMOTE-CONTENT-RUNTIME-V01/CHATGPT_CP05_R01_REAUDIT_V01.md`. Integrated through PR #8; merged runtime main `09f320044abc0424c6a9916cdbbce4eec047b820`. CP05/M16 is TECHNICAL PASS/CLOSED; CP04/M15 runtime core TECHNICAL PASS with CP04-011 still reserved for Android export/INTERNET-permission gate.

## MIGRATED LEVEL FACTORY / CONTENT PLATFORM PROGRAM — REFERENCE ONLY

As of 2026-09-14, the 224 Level Factory + Content Platform source requirements are no longer live checklist tasks in this game repository. Their canonical live tracker is:

`Sekiph82/ScrubBots-Level-Factory/TASKS.md`

The migration preserves every source requirement ID and historical meaning while preventing H!veAI from counting the same sidecar work in two repositories.

Canonical families:

- Level Factory: `SB-LF00-001..SB-LF10-008` — 112 source requirements.
- Content Pipeline: `SB-CP00-001..SB-CP09-010` — 112 source requirements.
- Canonical cross-repository mapping: `Sekiph82/ScrubBots-Level-Factory/docs/migration/LF_CP_REQUIREMENT_MAPPING_V01.md`.
- Canonical unification decision: `Sekiph82/ScrubBots-Level-Factory/docs/migration/LEVEL_FACTORY_CONTENT_PLATFORM_UNIFICATION_V01.md`.

Runtime implementation boundary remains explicit. The following requirements are tracked programmatically in the Factory repository but their implementation and audit evidence belong in this game repository when those milestones activate:

- `SB-CP04-001..014` — Godot remote content runtime.
- `SB-CP05-001..012` — offline cache / last-known-good recovery.
- `SB-CP06-004` — disabled-level runtime behavior.
- `SB-CP06-010` — single-level disable runtime test.

These ranges are references here, not live checklist rows. They must not be recreated as a duplicate game-side denominator. When runtime implementation opens, the concrete main-game implementation cycle is tracked in this repository and its accepted audit evidence is mirrored back to the canonical Factory requirement.

Existing game-owned catalog/content QA milestones such as M35, M52 and M53 remain unchanged and continue to gate what the shipping game accepts.

Migration note: removing the 224 duplicate sidecar checklist rows changes the game tracker denominator from 953 to 729 without changing the numerator. This is task-ownership normalization, not newly completed gameplay work.
