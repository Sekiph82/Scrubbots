# M43 — MASTER TARGETED REMEDIATION — CLAUDE LOG V03

Prompt: `coordination/sessions/M43-MASTER-V01/M43_MASTER_REMEDIATION_V03.md`
Criteria: `M43_MASTER_REMEDIATION_AUDIT_CRITERIA_V03.md`
Authority: `CHATGPT_MASTER_AUDIT_V01.md`

Repository `Sekiph82/Scrubbots`. Root `TASKS.md` was read only and never edited. Every status below is Claude's implementation claim awaiting ChatGPT's independent V03 re-audit; none is an audit or owner PASS.

## Environment / git

- This pass ran in a Claude Code cloud container: a fresh clone of `origin/main`, not the owner's `C:\Users\sekip\Desktop\ScrubBots` checkout.
- The session's designated branch is `claude/practical-darwin-ndbmxa`. All work is pushed there, and **not to `main`**: this session is not authorized to push to `main`. Merging the branch into `main` is the owner's / ChatGPT's step.
- **Baseline:** `0a7ff02` (= `origin/main` after `git fetch origin main`; clean tree, no local owner work in this clone).
- **Commits:**
  - `1cbe37f` code + tests;
  - `c7faa43` child logs + master status table;
  - this log's own commit follows them.
- **Owner-local work:** none was present in this clone, so nothing was touched. The `.import` / `.uid` files that the headless `--import` generated are editor artefacts. They are untracked and were **not** staged. No `project.godot`, `scenes/app/main.tscn`, `addons/` or owner candidates were changed.
- **Toolchain:** Godot **4.7.2.stable.official.ed1daf0bf** (Linux x86_64, headless).

## Exact production files changed

| File | Change |
|---|---|
| `scripts/save/cloud_save.gd` | SB-M43-155: whole-copy resolver. Validates both envelopes; canonical fingerprint equality; same-history-different-economy conflict; order / history / ancestry (lineage) descendant rules; `envelope(..., previous)` lineage; restore validates the full envelope. |
| `scripts/economy/notification_policy.gd` | R12-005: `capped(now_ts)`. A clock behind the persisted last-sent high-water stays suppressed. |
| `scripts/ui/feel/meta_feedback.gd` | SB-M43-161/162/167: the complete family. Modal-stack seams, refusal warnings, canonical ceremony kinds, read-only pack reveal / Rare+ hook, single-voice priority, deferred UI ticks, HOME gate, haptic gap. |
| `scripts/economy/production_action_facade.gd` | New presentation-only signal `action_refused(action, result)`, emitted for every non-ok `_finish`. No economy behaviour change. |
| `scripts/app/main.gd` | `meta_feedback.bind_stack(_modals)`; `ui_gate` = HOME route. |
| `tests/m43_master_c011_c014.gd` | 18 → **28** cases (new: n04, n05, s04–s07, a05–a08; a01–a03 rewritten; s02 updated for lineage). |

No pack ceremony, Shop, Collection, Robots, Tasks / Daily / Gift, Profile, World, C005, C008 or visual source changed.

## 1. SB-M43-155 — cloud conflict matrix

Every row is a real `AppState` save forked through `CloudSave.restore` and mutated through services. Both directions are tested where marked ⇄.

| Case | Result |
|---|---|
| exact canonical payload equality (also a JSON round-tripped copy) | `keep_local / equal` (the only "equal") |
| only device settings / `meta_ui` differ | `keep_local / same_authority` |
| local strict descendant (rev 6 > 5, later, lineage ∋ base) | `keep_local / local_ahead` |
| remote strict descendant | `take_remote / remote_ahead` |
| same tx + progression, wallet −100 (spend) ⇄ | `conflict / same_history_economy_differs` |
| same tx + progression, wallet +500 ⇄ | `conflict / same_history_economy_differs` |
| same tx + progression, Collection copy ⇄ | `conflict / same_history_economy_differs` |
| same tx + progression, robot unlock ⇄ | `conflict / same_history_economy_differs` |
| same tx + progression, booster inventory ⇄ | `conflict / same_history_economy_differs` |
| same tx + progression, Daily state ⇄ | `conflict / same_history_economy_differs` |
| superset history, revision lower / equal ⇄ | `conflict / order_contradiction` |
| superset history, `saved_at` older ⇄ | `conflict / order_contradiction` |
| same `saved_at`, higher revision | coherent → `take_remote` |
| remote more tx but missing a local robot unlock | `conflict / history_contradiction` |
| local spent 300 SB after the fork vs remote built on the pre-spend state | `conflict / no_ancestry_proof` (no silent refund) |
| tx-only vs progression-only divergence ⇄ | `conflict / diverged` |
| 14 malformed / future envelopes (schema v2, payload v99, revision "2" / 1.5 / −1, missing / NaN `saved_at`, int device, missing / non-hex / oversized lineage, non-object payload, corrupt tx ids, removed economy), plus null / string | `invalid_remote` (and `invalid_local` when on the local side) |
| take_remote restore onto a device holding +777 SB | economy == remote copy exactly (fingerprint); nothing merged |

Additional guarantees:
- A conflict carries only the two recomputed summaries; no merged payload.
- The resolver / restore source has no `.credit(` / `.debit(` / `.grant(` / `.merge(`.
- **Design note: the ancestry rule.** Superset checks alone could not prove that a descendant was built on the other side's exact state. The new s07 test showed a local spend being silently refunded by a remote copy with more history. The envelope therefore now records `lineage`: the authority fingerprints of the copies it was built on (bounded to 64). A descendant auto-wins only when the other side's current authority fingerprint is in its lineage. Without that proof the result is `conflict`.

## 2. Notification rollback proof (R12-005 / R12-007; timezone for 151)

n04 runs on the real app root with a real save reload.

| Step | Result |
|---|---|
| T | eligible; `mark_sent(T)` |
| T − 1 h | none |
| T − 10 d | none (cap never forgiven) |
| stale `mark_sent(T − 1h)` | high-water stays T |
| relaunch from save with the clock at T − 1 h | persisted `last_sent` = T; decide → none |
| T + 23 h | none |
| T + 24 h − 1 s | none |
| T + 24 h | eligible |
| after catch-up | quiet hours still apply; category toggle → next priority (Hearts) |

- **Reproduced:** with the pre-fix expression restored, n04 failed 3 checks (T − 1 h, T − 10 d, reload at T − 1 h). It passes with the fix.
- **n05** (policy-level timezone, SB-M43-151): at the same UTC timestamp, UTC+0 / +9 / −5 local hours each follow their own quiet hours. Local 23:00 is quiet and local 12:00 is eligible. Quiet-hours decisions never move the cap. After a send, no local hour reopens the 24 h cap.

## 3. Audio / haptic mapping (SB-M43-161 / 162)

Only the two approved M33 files are reused: `dispatch.wav` as a hard-bounded 0.12 s tick, `completion.wav` as the chime.

| Moment | Shipping seam | Sound | Haptic | Prio / gap |
|---|---|---|---|---|
| confirm | `BasePopup.action_selected` (app ModalStack) | tick, pitch 1.25, −14 dB | – | 1 / 90 ms |
| back | popup closed `back` (Back / Escape / X) | tick 0.95, −15 dB | – | 1 / 90 ms |
| popup_open | new popup becomes top (`ModalStack.top_changed`) | tick 1.12, −16 dB | – | 1 / 90 ms |
| popup_close | programmatic close (`close`, `complete`, …) | tick 0.88, −17 dB | – | 1 / 90 ms |
| error | `action_refused` (non-idempotent reason) / failed `pending_resolved` | tick 0.62, −12 dB (never the chime) | warning 40 ms | 2 / 400 ms |
| success | committed purchase / equip | – | success 25 ms | 3 / 600 ms |
| reward | committed claim / `gift_milestone` ceremony | chime 1.0, −8 dB | success 25 ms | 4 / 600 ms |
| pack_reveal | first committed card `emerge` step | chime 1.12, −9 dB | – | 4 / 600 ms |
| pack_rare | first Rare / Epic / Legendary committed card `emerge` | – (rides the reveal) | pack Rare+ 60 ms | 5 / 600 ms |
| unlock | `unlock_robot` commit; `robot_unlock` / `set_complete` / `master_complete` ceremonies | chime 0.94, −6 dB | unlock 80 ms | 6 / 600 ms |

Behaviour rules:
- **Silent closes and refusals:**
  - route-change closes (`clear`, `deep_link`, `host_released`, `restart`, `home`) are silent and stop the voice;
  - `action:*` closes are silent, because confirm covers them;
  - idempotent refusals (`already_claimed`, `duplicate`, `replay`, `in_flight`, `pending`, …) are silent.
- **One voice:** a single `AudioStreamPlayer` serves every moment. Inside a voice's hold window, only a strictly higher priority may replace it.
- **No same-frame double fire:** UI ticks are deferred to the end of the frame and dropped when a stronger moment owns that frame.
- **Haptic gap:** at most one buzz per 250 ms.
- **HOME gate:** UI ticks play only on HOME (`ui_gate`). Gameplay keeps its M33 / M34 feedback, so the two do not double-fire.
- **Live settings:** Haptics OFF and Reduced Effects suppress every buzz and are read live per request. SFX / Master are read live per request. Reduced Effects keeps sound.
- **No false success (SB-M43-164):** success, reward and unlock come only from `action_committed` or a shown ceremony.

## 4. Pack Rare+ and unlock mapping proof

- **Ceremony kinds (a07):** the kinds parsed from `scripts/economy/ceremony_events.gd` are exactly `gift_milestone, set_complete, master_complete, robot_unlock`. They map to reward / unlock / unlock / unlock. A real `robot_unlock` ceremony on the app root gives an unlock chime + 80 ms buzz, where V01 wrongly gave `reward`.
- **Pack hook (a08):** real `AppState.commit_pack` receipts, presented by the shipping `PremiumPackCeremony` / `StandardPackCeremony` on the app ModalStack and opened with `tap()`.
  - **Premium:** card 0 is the guaranteed Rare+. Result: one `pack_reveal` + one `pack_rare` (60 ms).
  - **Read-only proof:** receipt and presentation model are byte-identical before / after, and the economy snapshot is identical before / after the presentation.
  - **Reopen:** the same `presentation_id` (a replayed commit) gives no second reveal and no second Rare+.
  - **Standard:** one reveal; the Rare+ buzz fires only when a committed card is Rare+.
  - **Mechanism:** the hook reads the ceremony's own `RevealSequencer.step_started` and the committed model row of the emerging CardView. No pack ceremony source changed.
- **Unlock (a03):** the `unlock_robot` commit and its `robot_unlock` ceremony together give ONE unlock chime and ONE buzz.

## 5. Fatigue loop results (SB-M43-167, a03)

a03 runs on the real app root with an injected UI clock.

| Loop | Result |
|---|---|
| 20 rapid Daily open → X loops, 40 ms apart | 10 opens / 10 backs (rate-limited); one voice node; ticks never buzz |
| pause 2 s, open again | heard (`popup_open`): the rate limit is never a permanent mute |
| CLAIM tap on the real Daily popup | exactly `[reward]` + one success buzz; the confirm tick and the reward popup's open tick do not double-fire |
| 5 more claim attempts (blocked button + already-claimed facade) | no second reward, no second buzz, no error |
| COLLECT on the reward popup | one confirm tick |
| stack cleared, Daily reopened | nothing replays |
| route change (`deep_link`) with a chime + queued tick | voice stopped; ownership cleared; queued tick dropped; `_process` off; no new entries over later frames |
| robot unlock commit + ceremony | ONE unlock chime + ONE unlock buzz |
| Premium pack | one reveal chime + one Rare+ buzz |
| after all loops | still exactly one voice node |
| Reduced Effects + Haptics OFF, open / close / claim / pack loops | zero buzz |

## 6. Corrected child statuses (no authority fabricated)

| Child | V01 | V03 | Reason |
|---|---|---|---|
| SB-M43-R10-004 | READY | **BLOCKED_AWAITING_AUTHORITY** | shipping `first_try_cleanup: null`; a fixed / visible reward needs owner authority; mechanism + tests kept |
| SB-M43-151 | READY | **DEFERRED_DEPENDENCY** (SB-M43-146) | real disabled-permission testing needs platform notification authority; policy tests kept + n05 timezone test added |
| SB-M43-165 | READY | **DEFERRED_DEPENDENCY** (SB-M43-153 / 131) | cloud and RANKS retry surfaces don't exist; none faked |
| SB-M43-166 | READY | **DEFERRED_DEPENDENCY** (SB-M43-131 / 132) | the no-rankings empty state needs RANKS; no ranking data fabricated |

- **Child logs:** each of the four logs, and the six remediated logs (155, R12-005, R12-007, 161, 162, 167), carries a `MASTER REMEDIATION V03` section and its final status line. 163 and 164 carry accuracy notes, because a refusal now gives a warning tick instead of silence; their status is unchanged.
- **Master table** (`M43_MASTER_CLAUDE_LOG_V01.md`): **92 READY · 33 BLOCKED · 21 DEFERRED · 0 NOT_REACHED (146)**. This matches the audit's independent 33 / 21, and the table row counts were verified.

## 7. Focused / regression / root results

Every suite was run at code commit `1cbe37f` with Godot 4.7.2 headless; each line shows exit code and script errors.

**Focused:** `m43_master_c011_c014` **PASS 28/28**, exit 0, 0 script errors.

**M43 master lanes:**

| Suite | Result |
|---|---|
| c005 | 32/32 |
| c005f | 10/10 |
| c005r | 8/8 |
| c006 | 11/11 |
| c007 | 13/13 |
| c007r | 9/9 |
| c008 | 10/10 |
| c009 | 12/12 |
| c010 | 12/12 |

**C005 pack / presentation:**

| Suite | Result |
|---|---|
| c005_c005 reveal sequencer | 12/12 |
| c005_c006 standard pack | 21/21 |
| c005_c007 premium pack | 19/19 |
| c005_c008 commit transaction | 27/27 |
| c005_c009 card state | 25/25 |
| c005_c001 ceremony visual masters | 17/17 |
| **Standard owner-review harness smoke** | 14/14 |
| **Premium owner-review harness smoke** | 11/11 |

**M43 C001–C004, M42:**

| Suite | Result |
|---|---|
| c002 popup / modal | 23/23 |
| c003 acquisition | 34/34 |
| c004 fail / need-a-hand | 40/40 |
| c001a | 11/11 |
| c001b | 11/11 |
| c001r | 40/40 |
| m42_home | PASS |
| m42_navigation | PASS |

**Audio / haptics:** m33_audio_runtime, m34_haptics_production and m34_haptics_runtime PASS.

**M39 / M40 / M54 / M55 save + economy:** all PASS — m39a–e, m39_v02_atomicity / capacity / integration, m39_v03_full_surface / integration, m39_v04_integration / tornado_inflight, m40_save_system, m40_v02_safety, m40_v03_canonical, m40_v04_bootstrap, m54_collection_set_master_exactly_once, m55_economy_release_regression, m55_c002_timed_2x_anti_rollback, m55_heart_900_authority.

**Root `tests/run_tests.gd`:** 5,323 checks, **2 FAIL, 0 script errors**. Both failures are pre-existing and caused by this Linux environment, not by this pass:
- `distinct dot-segment output path (not aliasing anything) still succeeds`;
- `distinct dot-segment output written at its simplified location` (`tests/run_tests.gd:1481-1482`, LevelImporter).

The test writes to `<test_dir>/subdir/../legit_distinct.json`, where `subdir` does not exist. Linux resolves `..` against the real filesystem, so the open fails; the owner's Windows checkout normalizes it lexically, which is presumably why V01 reported 5,323 / 5,323. No importer file was touched here.

**Baseline proof:** the same root suite at baseline `0a7ff02`, in a clean worktree in this container, gives **5,323 checks, the same 2 FAIL**, so the failures exist before this pass. Excluding those two environment-caused checks, the root suite at `1cbe37f` passes every other check (5,321 / 5,323), with 0 script errors.

**Known pre-existing failure outside this scope:** `tests/m41_settings.gd` reduced-effects invariance, 2 checks: `on` and `live_toggle` "identical progression/economy result to OFF".
- It fails **identically at baseline `0a7ff02`**.
- **Cause:** each fresh `AppState` gets an OS-seeded pack RNG state (`economy.packs.rng`, persisted since M43-C005-C008), and the test compares whole economy snapshots across three fresh AppStates. Gameplay, terminal, cell and supply truth are identical in all three runs.
- `m41_settings` is not part of `tests/run_tests.gd`.
- **Not changed:** this is a closed test and outside the V03 scope. It is reported for a separate fix, either a deterministic pack seed in the test or excluding `packs.rng` from that comparison.

**`git diff --check`:** clean.

**Unexplained runtime / script errors:** none. Every suite ended with Godot's usual exit-time "ObjectDB instances leaked / resources still in use" warnings, which are also present at baseline.

## Not done / not decided (unchanged gates)

No canonical plugin intake; no M44 / M56 / M57 / M58, world, ranks, provider or owner-gate decision. No reward, rank, provider or schedule value was invented. The final cross-screen sound / haptic feel remains owner gate SB-M43-168.

AWAITING_GPT_M43_MASTER_REMEDIATION_V03_AUDIT
